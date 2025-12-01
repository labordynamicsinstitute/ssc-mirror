*! version 1.0.0  20aug2025  I I Bolotov
program def cconv
	version 15
	/*
		By default, this small program converts country names (in English) to   
		ISO 3166-1 codes (alpha-2, alpha-3, and numeric) and to full names      
		in English and French using regular expressions with Unicode support.   
		The from() option allows the user to import an external JSON file as    
		a dictionary to replace the default classification.                     
		The JSON file can be created from data in memory, provided they include 
		headings "Data", "Metadata", and "Sources" in the first variable,       
		immediately followed by content. The template JSON file structure is    
		the following ("regex" is a compulsory key and the file is saved using  
		Mata's libjson):                                                        
		[                                                                       
			{                                                                   
				"regex":"^(.*afgh.*|\\s*AFG\\s*|\\s*AF\\s*|\\s*4\\s*)$",        
				"name_en":"Afghanistan",        # classification A              
				"name_fr":"Afghanistan (l')",   # classification B              
				"iso3":"AFG",                   # ...                           
				"iso2":"AF",                                                    
				"isoN":"4"                                                      
			},                                                                  
			...                                                                 
		]                                                                       

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	syntax 																	///
	name(name=name) [, to(string) Generate(string) replace print]			///
	[from(string) *]
	// check for third-party packages from SSC                                  
	cap which libjson.mlib
	if _rc {
		di as err "installing {helpb libjson} (dependency)"
		ssc install libjson
	}
	// import classification                                                    
	if trim(`"`from'"') == "" {
		qui findfile `"cconv_classification.json"'
		local from `"`r(fn)'"'
	}
	// convert the variable to classification                                   
	cap confirm variable `name'
	if ! _rc {
		/* check options for errors                                           */
		if trim(`"`to'"') == "" {			// check for missing options
			di as err "option to() required"
			exit 198
		}
		if trim(`"`replace'`generate'`print'"') == "" {
			di as err "must specify either generate, replace, or print option"
			exit 198
		}
		/* ado + mata                                                         */
		if trim(`"`print'"') == "" {		// store the converted variable
			if trim(`"`generate'"') != "" {
				qui g  strL `generate' =    ""
				replace     `generate' =   `name'
			}
			loc varname      =  cond(`"`generate'"'  == "", `"`name'"',		///
															`"`generate'"')
			cap mata: _cconv(`"`from'"', 0, 0, 0, `"`to'"', `"`varname'"' )
			if _rc {
				di as err "JSON file does not contain valid entry/dictionary"
				exit 7102
			}
			cap compress    `generate'
		}
		else {								// print only
				mata: _cconv(`"`from'"', 0, 0, 1, `"`to'"', `"`name'"')
		}
		exit 0
	}
	// save classification to a variable                                        
	if trim(`"`name'"') == "__classification" {
		/* check options for errors                                           */
		if trim(`"`to'"') == "" {
			di as err "option to() required"
			exit 198
		}
		if trim(`"`generate'`print'"') == "" {
			di as err "must specify either generate or print option"
			exit 198
		}
		/* ado + mata                                                       */
		if trim(`"`print'"') == "" {		// store the converted variable
			qui g  strL    `generate' = ""
			cap mata: _cconv(`"`from'"', 0, 1, 0, `"`to'"', `"`generate'"')
			if _rc {
				di as err "JSON file does not contain valid entry/dictionary"
				exit 7102
			}
			cap compress   `generate'
		}
		else {								// print only
				mata: _cconv(`"`from'"', 0, 1, 1, `"`to'"')
		}
		exit 0
	}
	// print metadata and sources                                               
	if trim(`"`name'"') == "__info" {
		mata: _cconv(`"`from'"', 1, 0, 1)
		exit 0
	}
	// dump classification from data to a json file                             
	if trim(`"`name'"') == "__dump" {
		mata: _cconv(`"`from'"', 0, 1, 1)
		exit 0
	}
	// or display error                                                         
	di as err 																///
	"must specify either a variable, __classification, __info, or __dump"
	exit 198
end

* Mata code ***********                                                         
version 15

loc CC        class
loc PP        pointer
loc RS        real scalar
loc S         scalar
loc SC        string colvector
loc SS        string scalar
loc VV        void

mata:
mata set matastrict on

`VV' _cconv(`SS' json_file, `RS' info, `RS' dump, `RS' print,  |            ///
            `SS' to, `SS' varname)
{
    `PP'(`CC' libjson `S') `S' json, metadata, classification, dummy, element
    `RS' fh,   n,  i, j, f
    `SC' re,   v
    `SS' tmpf, s

    // general configuration
    info  = info  != . ? info  : 0                     /* flag: print info   */
    dump  = dump  != . ? dump  : 0                     /* flag: dump  data   */
    print = print != . ? print : 0                     /* flag: print data   */
    f     = 1                                          /* flag: print line   */

    // retrieve the metadata/sources and classification
    tmpf = st_tempfilename()
    fh   = fopen(tmpf, "w")                            /* an empty JSON file */
    fput(fh, "[]")
    fclose(fh)
    json           = libjson::webcall(json_file, J(0,2,""))
    metadata       = libjson::webcall(tmpf,      J(0,2,""))
    classification = libjson::webcall(tmpf,      J(0,2,""))
    if (json == NULL) {
        errprintf("Invalid JSON in %s\n", json_file)
        exit(7102)
    }
    if (! json->isArray()) {
        errprintf("Mapping JSON must be a list of objects\n")
        exit(7102)
    }
    for (i = 1; i <= json->arrayLength(); i++) {
        element = json->getArrayValue(i)
        if (element == NULL | ! element->isObject()) continue
        if (element->getAttributeScalar("regex", "") == "") {
            metadata->addArrayValue(element)
        } else {
            classification->addArrayValue(element)
        }
    }

    // return metadata/sources or classification
    if (info & print) {
        if (metadata->arrayLength() > 0) {
            metadata->prettyPrint()
            return
        } else {
            errprintf("JSON file does not contain valid entry/dictionary\n")
            exit(error(7102))
        }
    }
    if (dump & print) {
        if (classification->arrayLength() > 0) {
            if (to != "") {
                dummy = libjson::webcall(tmpf, J(0,2,""))
                for (i = 1; i <= classification->arrayLength(); i++) {
                    element = classification->getArrayValue(i)
                    s       = ustrunescape(element->getAttributeScalar(to, ""))
                    if (s == "") {
                        errprintf("Missing attribute '%s' in JSON\n", to)
                        exit(error(7102))
                    }
                    dummy->addAttributeScalar(to, s)
                }
                classification = dummy
            }
            classification->prettyPrint()
            return
        } else {
            errprintf("JSON file does not contain valid entry/dictionary\n")
            exit(error(7102))
        }
    }

    // convert to classification or print
    n  = classification->arrayLength()
    re = J(n, 1, "")
    v  = J(n, 1, "")
    if (dump & (n > st_nobs())) st_addobs(n - st_nobs())
    for (i = 1; i <= classification->arrayLength(); i++) {
        element = classification->getArrayValue(i)
        re[i]   = ustrunescape(element->getAttributeScalar("regex", ""))
        v[i]    = ustrunescape(element->getAttributeScalar(to,      ""))
        if (v[i] == "") {
            errprintf("Missing attribute '%s' in JSON\n", to)
            exit(error(7102))
        }
    }
    if (dump) {
        for (i = 1; i <= n; i++) st_sstore(i, varname, v[i])
    } else {
        for (i = 1; i <= st_nobs(); i++) {
            s = st_sdata(i, varname)
            f = 1
            for (j = 1; j <= n; j++) {
                if (ustrregexm(s,re[j], 1)) {
                    if (print) {
                        printf("%s\n", v[j])
                        f = 0
                    } else {
                        st_sstore(i, varname, v[j])
                    }
                    break
                }
            }
            if (print & f) printf("%s\n", s)
        }
    }
}
end
