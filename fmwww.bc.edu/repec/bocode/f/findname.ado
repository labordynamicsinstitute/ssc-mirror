*! 1.1.2 NJC 30 October 2025
*! 1.1.1 NJC 5 September 2023 
*! 1.1.0 NJC 21 January 2020 
* 1.0.4 NJC 24 March 2014 
* 1.0.3 NJC 27 February 2012 
* 1.0.2 NJC 22 November 2010 
* 1.0.1 NJC 28 April 2010 
* 1.0.0 NJC 30 March 2010 
program findname, rclass   
	version 9 

	syntax [varlist] [if] [in]                                  ///
	[, INSEnsitive LOCal(str) CSLOCal(str) NOT PLACEholder(str) /// 
	Alpha Detail INDENT(int 0) Skip(int 2) Varwidth(int 12)     ///
	Type(str) all(str asis) any(str asis) Format(str)           ///
	COLumns(numlist int)                                        ///
	VARLabel VARLabeltext(str asis)                             ///
	VALLabel VALLabelname(str)                                  ///
	VALLABELText(str asis)                                      /// 
	VALLABELTEXTDef(str asis)                                   /// 
	VALLABELTEXTUse(str asis)                                   /// 
    VALLABELCOUNTDef(numlist min=1 max=2 int >-1 missingok sort) ///
    VALLABELCOUNTUse(numlist min=1 max=2 int >-1 missingok sort) ///
	Char Charname(str) CHARText(str asis) ]

	// -if- and -in- affect 
	// 	-any()- 
	// 	-all()- 
	// 	-vallabeltext()        [undocumented as from 1.1.0] 
	// 	-vallabeltextuse()     [introduced in 1.1.0] 
	// 	-vallabelcountuse()    [introduced in 1.1.0] 

	local useopts = ///
	`"`vallabeltext'`vallabeltextuse'`vallabellcountuse'"' != ""  

	quietly if `"`if'`in'"' != "" | `useopts' { 
		marksample touse, novarlist 
		count if `touse' 
		if r(N) == 0 error 2000 
		local if if `touse' 
		local andif & `touse' 
	}

	// check presentation options
	if !inrange(`varwidth',5,32) {
		di as err "varwidth() should be in the range 5..32"
		exit 198
	}

	if !inrange(`skip',1,10) {
		di as err "skip() should be in the range 1..10"
		exit 198
	}

	// columns 
	if "`columns'" != "" {
		unab varlist : * 
		local nvars : word count `varlist' 
		local vlist 
		foreach col of local columns { 
			if `col' < 0 local col = `nvars' + (`col') + 1 
			if `col' > 0 local v : word `col' of `varlist' 
			local vlist `vlist' `v'
		} 
				
		local varlist `vlist'           
	} 

	// check -type()-
	// We remove allowed type names from the argument. 
	// Whatever remains should be the elements of a numlist. 
	// Note that a numlist may include embedded spaces. 
	// A side-effect is to allow e.g. "1 byte / 80".
	//
	// New over -ds-: indulge e.g. str18, str1-str2 
	if "`type'" != "" {  
		if c(stata_version) >= 13 local strL "strL" 
		local words "byte int long float double string `strL' numeric"
		local numbers : list type - words 
		local numbers : subinstr local numbers "str" "", all 
		local numbers : subinstr local numbers "-" "/", all 
	     
		if `"`numbers'"' != "" {  
			capture numlist `"`numbers'"', integer range(>=1 <=`c(maxstrvarlen)') 
			if _rc { 
				di as err "invalid variable type(s)" 
				exit 198 
			}  
		} 
		
		local type : list type - numbers 
		local type `type' `r(numlist)'
	}  

	// check -any()- or -all()-
	// if condition doesn't work with either a numeric or a string 
	// test variable as input, it is rejected 
	quietly if `"`any'"' != "" { 
		tempvar ntest stest 
		local At = cond("`placeholder'" != "","`placeholder'","@") 
		gen `ntest' = 42 
		local cond : subinstr local any "`At'" "`ntest'", all 
		capture local test = `cond' 
		local iserr = _rc 
		gen `stest' = "42" 
		local cond : subinstr local any "`At'" "`stest'", all 
		capture local test = `cond' 
		drop `ntest' `stest' 

		if min(`iserr', _rc) { 
			di as err `"`any' incorrect?"' 
			exit 198
		} 
	}

	quietly if `"`all'"' != "" { 
		tempvar ntest stest 
		local At = cond("`placeholder'" != "","`placeholder'","@") 
		gen `ntest' = 42 
		local cond : subinstr local all "`At'" "`ntest'", all 
		capture local test = `cond' 
		local iserr = _rc 
		gen `stest' = "42" 
		local cond : subinstr local all "`At'" "`stest'", all 
		capture local test = `cond' 
		drop `ntest' `stest' 

		if min(`iserr', _rc) { 
			di as err `"`all' incorrect?"' 
			exit 198
		} 
	}

	// preparation 
	local inse = "`insensitive'" != "" 

	// variable types 
	if "`type'" != "" { 
		local vlist 
		foreach v of local varlist {
        	foreach w of local type {
               	if `"`w'"' == "string" | `"`w'"' == "numeric" { 
                	capture confirm `w' variable `v'
   	                if _rc == 0 { 
           	    		local vlist `vlist' `v' 
						continue, break 
                   	}    
                }
                else {
       	        	local t : type `v' 
               		if "`t'" == `"str`w'"' | "`t'" == `"`w'"' { 
               			local vlist `vlist' `v'
						continue, break 
                    } 
                }     
            } 
       	}
		local varlist `vlist' 
	}

	// variable formats 
	if "`format'" != "" {
		local vlist 
       	foreach v of local varlist { 
           	local fmt : format `v' 
			mata : find_match("`fmt'", "`format'", `inse') 
			if `found' { 
   	        	local vlist `vlist' `v' 
	      	} 
        }
		local varlist `vlist'
	} 

	// condition satisfied by any values? 
	quietly if `"`any'"' != "" { 
		local vlist 
		foreach v of local varlist { 
			local cond : subinstr local any "`At'" "`v'", all 
			capture count if `cond' `andif' 
			if _rc == 0 & r(N) > 0 { 
				local vlist `vlist' `v' 
			} 
		}
		local varlist `vlist' 
	}

	// condition satisfied by all values? 
	quietly if `"`all'"' != "" { 
		count `if' 
		local N = r(N) 
		local vlist 
		foreach v of local varlist { 
			local cond : subinstr local all "@" "`v'", all 
			capture count if `cond' `andif' 
			if _rc == 0 & r(N) == `N' { 
				local vlist `vlist' `v' 
			} 
		}
		local varlist `vlist' 
	} 

	// variable labels assigned? 
	if "`varlabel'" != "" {
		local vlist 
        foreach v of local varlist { 
           	local lbl : var label `v' 
	        if `"`lbl'"' != "" { 
               	local vlist `vlist' `v' 
           	} 
        }
		local varlist `vlist' 
 	} 

	// variable labels matching patterns? 
	if `"`varlabeltext'"' != "" {
		local vlist 
        foreach v of local varlist { 
           	local lbl : var label `v' 
			mata : find_match(`"`lbl'"', `"`varlabeltext'"', `inse') 
           	if `found' { 
           		local vlist `vlist' `v' 
           	} 
       	}
		local varlist `vlist' 
    } 

	// value labels assigned? 
	if "`vallabel'" != "" {
		local vlist 
       	foreach v of local varlist { 
           	local lbl : val label `v' 
            if `"`lbl'"' != "" { 
               	local vlist `vlist' `v'
           	} 
       	}
		local varlist `vlist' 
 	} 	

	// value label names matching patterns? 
	if "`vallabelname'" != "" {
		local vlist 
       	foreach v of local varlist { 
           	local lbl : val label `v' 
			mata : find_match("`lbl'", "`vallabelname'", `inse') 
           	if `found' { 
           		local vlist `vlist' `v' 
           	} 
       	}
		local varlist `vlist' 
    } 

	// value label text defined matching patterns? 
	quietly if `"`vallabeltextdef'"' != "" {
		local vlist 

       	foreach v of local varlist { 
           	local lbl : val label `v' 
			if "`lbl'" != "" { 
				mata : ///
				find_label_text_def("`lbl'", `"`vallabeltextdef'"', `inse') 
				if `found' { 
               		local vlist `vlist' `v'
               	}
            } 
		} 
		local varlist `vlist' 
 	} 

	/// value label text used matching patterns? 
	quietly if "`vallabeltextuse'" != "" {
		local vlist 

		foreach v of local varlist { 
			local lbl : val label `v' 
			if "`lbl'" != "" { 
				mata : ///
				find_label_text_use("`lbl'", "`v'", "`touse'", "`vallabeltextuse'", `inse') 

				if `found' { 
					local vlist `vlist' `v' 
				}
			}
		}
		 
		local varlist `vlist' 
	} 

	// value label text matching patterns? 
    // left undocumented from 1.1.0 
	quietly if `"`vallabeltext'"' != "" {
		local vlist 
       	foreach v of local varlist { 
           	local lbl : val label `v' 
			if "`lbl'" != "" { 
				levelsof `v' `if', local(levels) 
				foreach l of local levels { 
					local txt : label `lbl' `l', strict 
					mata : find_match(`"`txt'"', `"`vallabeltext'"', `inse') 
					if `found' { 
                   		local vlist `vlist' `v'
	                	continue, break 
       	        	} 
				} 
            }
	    }
		local varlist `vlist' 
 	} 

	/// count value labels defined 
	if "`vallabelcountdef'" != "" {
		local args `vallabelcountdef' 
		if `: word count `args'' == 1 local args `args' `args' 
		tokenize `args'
		args min max 

		local vlist 

		foreach v of local varlist { 
			local lbl : val label `v' 
			if "`lbl'" != "" { 
				quietly capture label list `lbl'

				if _rc { 
					if inrange(0, `min', `max') {
						local vlist `vlist' `v' 
					} 
				}
				else if inrange(r(k), `min', `max') { 
					local vlist `vlist' `v' 
				}
			}
		}
		 
		local varlist `vlist' 
	} 

	/// count value labels used 
	if "`vallabelcountuse'" != "" {
		local args `vallabelcountuse' 
		if `: word count `args'' == 1 local args `args' `args' 
		tokenize `args'
		args min max 

		local vlist 

		foreach v of local varlist { 
			local lbl : val label `v' 
			if "`lbl'" != "" { 
				mata : ///
				count_labels_used("`lbl'", "`v'", "`touse'") 

				if inrange(`count', `min', `max') { 
					local vlist `vlist' `v' 
				}
			}
		}
		 
		local varlist `vlist' 
	} 

	// characteristics assigned?
	if "`char'" != "" {
		local vlist 
        foreach v of local varlist { 
           	local chr : char `v'[] 
            if `"`chr'"' != "" { 
               	local vlist  `vlist' `v'
           	} 
        }
		local varlist `vlist' 
	}

	// characteristic names match patterns?
	if "`charname'" != "" {
		local vlist 
        foreach v of local varlist { 
           	local chr : char `v'[] 
           	foreach c of local chr { 
				mata : find_match("`c'", "`charname'", `inse') 
				if `found' { 
	            	local vlist `vlist' `v' 
       		        continue, break 
				} 
            }    
		}    
		local varlist `vlist'
    } 

	// characteristic text matches patterns? 
	if `"`chartext'"' != "" {
		local vlist
        foreach v of local varlist { 
           	local chr : char `v'[] 
           	foreach c of local chr { 
				local txt : char `v'[`c'] 
				mata : find_match(`"`txt'"', `"`chartext'"', `inse') 
                if `found' { 
					local vlist `vlist' `v' 
       		        continue, break 
				} 
			} 
		}    
		local varlist `vlist'
 	} 

	if "`not'" != "" {   
		unab all : *  
		local varlist : list all - varlist 
	}

	if "`varlist'" == "" { 
		exit 
	}   
	 
	// presentation
	if "`alpha'" != "" {
		local varlist : list sort varlist 
	}

	if "`detail'" != "" { 
		describe `varlist' 
	}
	else {
		local vlist 
		foreach v of local varlist {
			local vlist `vlist' `= abbrev("`v'",`varwidth')'
		}
		
		DisplayInCols txt `indent' `skip' 0 `vlist'
	}    

	return local varlist `varlist'
	
	if "`local'" != "" c_local `local' `varlist' 
	
	if "`cslocal'" != "" {
		if "`cslocal'" == "`local'" {
			noisily di _n "note: cslocal() result overwrites local() result"
		}
		local varlist : subinstr local varlist " " ",", all 
		c_local `cslocal' `varlist'
	}
end

program DisplayInCols /* sty #indent #pad #wid <list>*/
	gettoken sty    0 : 0
	gettoken indent 0 : 0
	gettoken pad    0 : 0
	gettoken wid	0 : 0

	local indent = cond(`indent'==. | `indent'<0, 0, `indent')
	local pad    = cond(`pad'==. | `pad'<1, 2, `pad')
	local wid    = cond(`wid'==. | `wid'<0, 0, `wid')
	
	local n : list sizeof 0
	if `n' == 0 { 
		exit
	}

	foreach x of local 0 {
		local wid = max(`wid', length(`"`x'"'))
	}

	local wid = `wid' + `pad'
	local cols = int((`c(linesize)'+1-`indent')/`wid')

	if `cols' < 2 { 
		if `indent' {
			local col "_column(`=`indent'+1')"
		}
		foreach x of local 0 {
			di as `sty' `col' `"`x'"'
		}
		exit
	}
	local lines = `n'/`cols'
	local lines = int(cond(`lines'>int(`lines'), `lines'+1, `lines'))

	/* 
	     1        lines+1      2*lines+1     ...  cols*lines+1
             2        lines+2      2*lines+2     ...  cols*lines+2
             3        lines+3      2*lines+3     ...  cols*lines+3
             ...      ...          ...           ...               ...
             lines    lines+lines  2*lines+lines ...  cols*lines+lines

             1        wid
	*/

	* di "n=`n' cols=`cols' lines=`lines'"
	forvalues i=1(1)`lines' {
		local top = min((`cols')*`lines'+`i', `n')
		local col = `indent' + 1 
		* di "`i'(`lines')`top'"
		forvalues j=`i'(`lines')`top' {
			local x : word `j' of `0'
			di as `sty' _column(`col') "`x'" _c
			local col = `col' + `wid'
		}
		di as `sty'
	}
end

mata: 

void find_match(
	string scalar mystring, 
	string scalar mypatternlist, 
	numeric scalar inse)
{
	real scalar found, i 
	string rowvector mypatterns 

	mypatterns = tokens(mypatternlist) 
	found = 0 

	if (inse) { 
		for(i = 1; i <= length(mypatterns); i++) { 
			if (strmatch(strlower(mystring), strlower(mypatterns[i]))) { 
				found = 1 
				break 
			}
		}
	}
	else { 
		for(i = 1; i <= length(mypatterns); i++) { 
			if (strmatch(mystring, mypatterns[i])) { 
				found = 1 
				break 
			}
		}	 
	}
	st_local("found", strofreal(found)) 
}

void count_labels_used(
	string scalar lblname, 
	string scalar varname, 
	string scalar tousename) 
{ 
   // get the labels 	
   real vector values 
   string vector text   
   st_vlload(lblname, values = ., text = "") 

   // which labels are used 	
   real vector X 	
   real scalar i, count  
   st_view(X, ., varname, tousename) 
   count = 0 	
   for(i = 1; i <= length(values); i++) { 
        count = count + (sum(X :== values[i]) > 0)
   }
 	
   st_local("count", strofreal(count))  
} 

void find_label_text_def(
	string scalar lblname, 
	string scalar mytext, 
	real scalar inse) 
{ 
   // get the labels 	
   real vector values 
   string vector text   
   st_vlload(lblname, values = ., text = "") 

   real scalar found, i 
   string rowvector mypatterns 

   mypatterns = tokens(mytext) 
   found = 0 

   if (inse) { 
        for(i = 1; i <= length(text); i++) { 
	        for(j = 1; j <= length(mypatterns); j++) { 
				if (strmatch(strlower(text[i]), strlower(mypatterns[j]))) { 
			    	found = 1 
		    		break 
				}
	    	}
            if (found) break 
        }
   }
   else { 
        for(i = 1; i <= length(text); i++) { 
	    	for(j = 1; j <= length(mypatterns); j++) { 
	        	if (strmatch(text[i], mypatterns[j])) { 
				    found = 1 
				    break 
				}
	    	}
            if (found) break 
        }
    }
	
   st_local("found", strofreal(found)) 
}

void find_label_text_use(
	string scalar lblname, 
	string scalar varname, 
	string scalar tousename, 
	string scalar mytext, 
	real scalar inse) 
{ 
   // get the labels 	
   real vector values 
   string vector text   
   st_vlload(lblname, values = ., text = "") 

   // get the data 	
   real vector X 	
   st_view(X, ., varname, tousename) 

   // patterns to look for 	
   string rowvector mypatterns 
   mypatterns = tokens(mytext) 
   
   // does the value occur in the data? 
   // does the text occur in the label? 	
   real scalar i, j, n, count  
   found = 0 
   for(i = 1; i <= length(values); i++) { 
        n = sum(X :== values[i]) 
        
        if (n > 0 & inse) {   
	        for(j = 1; j <= length(mypatterns); j++) { 
				if (strmatch(strlower(text[i]), strlower(mypatterns[j]))) { 
			    	found = 1 
		    		break 
				}
	    	}
        }
   		else if (n > 0) { 
	    	for(j = 1; j <= length(mypatterns); j++) { 
	        	if (strmatch(text[i], mypatterns[j])) { 
				    found = 1 
				    break 
				}
	    	}
        }
    }

	st_local("found", strofreal(found)) 
}

end 

