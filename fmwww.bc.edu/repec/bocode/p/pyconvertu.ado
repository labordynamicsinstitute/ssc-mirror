*! version 1.3.0  20nov2025  I I Bolotov
program def pyconvertu
	version 16.0
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
		Python's json.dump()):                                                  
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
		Date: 20 July 2021                                                      
	*/
	syntax 																	///
	name(name=name) [, to(string) Generate(string) replace print]			///
	[from(string) *]
	tempname json sections_n vars
	tempvar converted
	// import classification                                                    
	if trim(`"`from'"') == "" {
		qui findfile `"pyconvertu_classification.json"'
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
		/* ado + python                                                       */
		cap python: l = _cconv(json_file=r'`from'', to='`to'',              ///
		                       text=Data.get('`name''))
		if _rc {
			di as err "JSON file does not contain valid entry/dictionary"
			exit 7102
		}
		if trim(`"`print'"') == "" {		// store the converted variable
			g `converted' = ""
			python: Data.store('`converted'', None, l)
			if trim(`"`generate'"') != "" {	// generate a new variable
				g `generate' = `converted'
			}
			if trim(`"`replace'"')  != "" {	// replace the existing one
				replace `name' = `converted'
			}
		}
		else {								// print only
			python: print('`"' + '""'.join(l).replace('""', '"\', `"') + '"\'')
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
		/* ado + python                                                       */
		cap python: l = [str(x)            for x                            ///
		                 in [d.get('`to'') for d                            ///
		                 in _cconv(json_file=r'`from'', to='`to'',          ///
		                           dump=True) if isinstance(d, dict)        ///
		                 and '`to'' in d]     if x      is not None]
		cap python: l.sort()
		if _rc {
			di as err "JSON file does not contain valid entry/dictionary"
			exit 7102
		}
		python: n = len(l) - Data.getObsTotal()
		if trim(`"`print'"') == "" {		// store the classification
			g `converted' = ""
			python: Data.addObs((lambda n: n if n > 0 else 0)(n))
			python: Data.store('`converted'', [i for i in range(0, len(l))], l)
			if trim(`"`generate'"') != "" {	// generate a new variable
				g `generate' = `converted'
			}
		}
		else {								// print only
			python: print('\`"' + '"\' \`"'.join(l) + '"\'')
		}
		exit 0
	}
	// print metadata and sources                                               
	if trim(`"`name'"') == "__info" {
		cap python: l = [str(x) for x in _cconv(json_file=r'`from'',        ///
		                                        to='`to'', info=True)       ///
		                 if x   is not None]
		if _rc {
			di as err "JSON file does not contain valid entry/dictionary"
			exit 7102
		}
		python: print(f'\n'.join(l))
		exit 0
	}
	// dump classification from data to a json file                             
	if trim(`"`name'"') == "__dump" {
		qui ds
		local `vars' = r(varlist)
		/* find _n of the json sections                                       */
		forvalues n = 1/`=_N' {
			if regexm(`=word("``vars''", 1)'[`n'], "^\s*(Data|Meta|Sources)") {
				local `sections_n' "``sections_n'' `n'"
			}
		}
		/* ado + python                                                       */
		scalar `json' = ""
		cap preserve
		forvalues i = 1/`=wordcount("``sections_n''")' {
			local n = word("``sections_n''", `i')
			restore, preserve
			qui {
				drop if _n < `n'			// isolate each json section
				cap drop if _n > `=real(word("``sections_n''", `i' + 1)) - `n''
				drop if mi(`=word("``vars''", 1)')
				if regexm(`=word("``vars''", 1)'[1], "^\s*Data") {
					foreach var in ``vars'' {
						tostring `var', replace force
						replace `var' = `""`=`var'[2]'": ""' + `var' + `"""'
					}
					drop if _n <= 2			// Data (the classification)
					egen `converted' = concat(``vars''), punct(", ")
					replace `converted' = "{" + `converted' + "}"
					levelsof `converted', clean s(", ")
					scalar `json' = `json' + r(levels) + ", "
				}
				if regexm(`=word("``vars''", 1)'[1], "^\s*Meta") {
					drop if _n <= 2			// Metadata
					g `converted' = `"""' + `=word("``vars''", 1)' + 		///
					`"": ""' + `=word("``vars''", 2)' + `"""'
					levelsof `converted', clean s(", ")
					scalar `json' = `json' + `"{"metadata": {"' + 			///
					r(levels) + "}}, "
				}
				if regexm(`=word("``vars''", 1)'[1], "^\s*Sources") {
					drop if _n <= 2			// Sources
					g `converted' = `""["' + `=word("``vars''", 2)' + 		///
					"](" + `=word("``vars''", 1)' + `")""'
					levelsof `converted', clean s(", ")
					scalar `json' = `json' + `"{"sources": ["' + 			///
					r(levels) + "]}, "
				}
			}
		}
		python: _cconv(data=Scalar.getString('`json''), json_file=r'`from'')
		exit 0
	}
	// or display error                                                         
	di as err 																///
	"must specify either a variable, __classification, __info, or __dump"
	exit 198
end

* Python 3 code ***********                                                     
version 16.0
python:
# Stata Function Interface
from sfi import Data, Scalar
# Python Modules
from   os        import path
from   re        import sub, compile, Pattern, I, M, error as RegexError
from   typing    import Any
from   json      import loads, load, dump as save, JSONDecodeError

class ConvertuError(Exception):
    """
    Exception class for ConvertU-related errors.
    """
    def __init__(self, message="An error occurred in _cconv", code=None):
        self.message = message
        self.code    = code
        if code is not None:
            full_message = "{} (Code: {})".format(message, code)
        else:
            full_message = message
        Exception.__init__(self, full_message)

def _cconv(
    data=None, json_file=None, info=False, dump=False, to='', text=None,
    *args, **kwargs
):
    """
    Convert text into a target classification using a JSON mapping, or
    return mapping/metadata (info/dump modes).
    """
    # retrieve the metadata/sources and classification
    json_file = path.expanduser(json_file)
    if data is not None:                               # read from the argument
        try:
            with open(json_file, "w", encoding="utf-8") as f:
                save(loads(sub(r'\\(?!["\\/bfnrtu])', r'\\\\',
                         '[' + data.rstrip(', ') + ']')),  f,
                     ensure_ascii=False, indent=2)
        except OSError as e:
            raise ConvertuError(f"Unable to write to {json_file}: {e}")
        return json_file
    else:                                              # read from the file
        try:
            with open(json_file, encoding="utf-8") as f:
                data = load(f)
        except JSONDecodeError as e:
            raise ConvertuError(f"Invalid JSON in {json_file}: {e}")
        except OSError as e:
            raise ConvertuError(f"Unable to read {json_file}: {e}")
        if  not isinstance(data, list):
            raise ConvertuError("Mapping JSON must be a list of objects")
    metadata                             = [
        d for d in data
        if isinstance(d, dict) and ('metadata'     in d or
                                    'sources'      in d)
    ]
    classification: list[dict[str, Any]] = [
        d for d in data
        if isinstance(d, dict) and ('metadata' not in d and
                                    'sources'  not in d)
    ]

    # return metadata/sources or classification
    if  info:
        return metadata                                # return metadata
    if  dump:
        return classification                          # return classification

    # process arguments
    if   text is None:
        items: list[str] = []
        single_input = False
    elif isinstance(text, str):
        items = [text]
        single_input = True
    elif isinstance(text, list) and all(isinstance(s, str) for s in text):
        items = text
        single_input = False
    else:
        raise ConvertuError("text must be str, list[str], or None")

    # precompile regex patterns once
    compiled: list[tuple[Pattern[str], dict[str, Any]]] = []
    for r in classification:
        p = r.get('regex')
        if  to in r and isinstance(p, str) and p:
            try:
                compiled.append((compile(p, I | M), r))
            except RegexError:
                continue
    if  items and not compiled:
        return text if single_input else items

    # convert compiled
    def convert_one(s: str) -> str:
        s = str(s)
        for p, r in compiled:
            if  p.search(s):
                val = r.get(to)
                return s if val is None else val       # return converted text
        return s                                       # return original  text

    result = [convert_one(s) for s in items]
    return result[0] if single_input else result
end
