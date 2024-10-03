*! 1.0.1 NJC 2 Oct 2024 
*! 1.0.0 NJC 23 Sept 2024 
program framed_bar 
	version 12 
	
	// two syntaxes: 
	// 1. numeric outcome with -over()-
	// 2. several numeric outcomes 
	// wherecount() undocumented 
	// list() undocumented 
	capture syntax varname(numeric)  [fweight aweight pweight iweight] [if] [in], over(varname) ///
	[ STATistic(str) CALCulator(str) ALLobs cw sort DESCending subset(passthru) ///
	frame(real 1) frameopts(str asis) base(real 0) BARWidth(real 0.8) HORIzontal ///
    barlabel(str asis) COUNTlabel COUNTlabel2(str asis) countlabelprefix(str asis) ///
	countlabelsuffix(str) wherecount(numlist max=1) by(str asis) ///
	format(str) list LIST2(str asis) *]
	
	if _rc syntax varlist(numeric) [fweight aweight pweight iweight] [if] [in] ,  ///
	[ STATistic(str) CALCulator(str) ALLobs cw sort DESCending subset(passthru) ///
	frame(real 1) frameopts(str asis) base(real 0) BARWidth(real 0.8) HORIzontal ///
	barlabel(str asis) COUNTlabel COUNTlabel2(str asis) countlabelprefix(str asis) ///
	countlabelsuffix(str) wherecount(numlist max=1) by(str asis) ///
	format(str) list LIST2(str asis) * ] 
	
	// by() option? 
	if `"`by'"' != "" { 
		gettoken byvar byopts : by, parse(,)
		gettoken comma byopts : byopts, parse(,)
		
		local found 0 
		foreach opt in leg(off) lege(off) legen(off) legend(off) { 
			local found = max(`found', strpos(`"`byopts'"', "`opt'")) 
		}
		if `found' == 0 local byopts `byopts' legend(off)
		
		* comment out in 1.0.1 
		* if strpos(`"`byopts'"', `"note("")"') == 0 local byopts `byopts' note("")
		
		local bybyvar by(`byvar')
		local byby by(`byvar', `byopts')
	}
	
	// data to use? 
	if "`cw'" != "" local allobs "allobs" 
	if "`allobs'" != "" marksample touse, novarlist 
	else marksample touse 
	
	markout `touse' `over' `byvar', strok 
	quietly count if `touse'
	if r(N) == 0 error 2000 
	
	// good to go?  
	preserve 
	
	if "`statistic'" == "" local statistic "mean"
	local ylah yla(, ang(h))
	
	if "`countlabelprefix'" == "" local countlabelprefix "{it:n } = "
	else if "`countlabelprefix'" == "none" local countlabelprefix 
	
	// support first syntax 
	quietly if "`over'" != "" { 
		// the categorical axis title comes from the -over()- variable 
		// the other title comes from the outcome 
		local xtitle `"`: var label `over''"'
		if `"`xtitle'"' == "" local xtitle "`over'"
		
		local ytitle "`: var label `varlist''"
		if `"`ytitle'"' == "" local ytitle "`varlist'"
		
		// if counts of non-missing values, they come from the -collapse- and go in a new variable 
		if "`countlabel'`countlabel2'" != "" { 
			tempvar count showcount 
			collapse (count) `count'=`varlist' (`statistic') `varlist' if `touse' [`weight' `exp'], by(`over' `byvar')
			gen `showcount' = "`countlabelprefix'" + strofreal(`count') + "`countlabelsuffix'"
		}
		// else we -collapse- on the chosen statistic
		else collapse (`statistic') `varlist' if `touse' [`weight' `exp'], by(`over' `byvar')
			
		// the top of the frame is a variable, even though constant 
		// the categorical axis comes from -egen-'s -group()-, so has integer values 1 up
		tempvar framebar xvar where 
		gen `framebar' = `frame'
		egen `xvar' = group(`over'), label 
		su `xvar', meanonly 
		local X = r(max)
		
		// want to push results through further calculations? 
		if "`calculator'" != "" { 
			local calculator : subinstr local calculator "@" "`varlist'", all 
			replace `varlist' = `calculator'
		}
				
		// want to sort, ascending default? 
		// myaxis from Stata Journal included here 
		if "`sort'" != "" { 
			tempvar newxvar 
			myaxis `newxvar'=`xvar', sort(mean `varlist') `descending' `subset'
			local xvar `newxvar'
		}

		if "`format'" != "" { 
			local fmt mlabformat(`format')
			format `varlist' `format'
		}  
		
		// horizontal bars 
		if "`horizontal'" != "" {
			if "`wherecount'" != "" gen `where' = `wherecount'
			else if missing(`frame') | `frame' == 0 { 
				su `varlist', meanonly 
				gen `where' = -0.01 * r(max)
			}
			else gen `where' = -0.01 * `frame'
			
			if "`countlabel'`countlabel2'" != "" {
				local countcode scatter `xvar' `where', ms(none) mla(`showcount') mlabpos(9) mlabc(black) `countlabel2' 
			}
			if "`barlabel'" != "none" { 
				local barlabelcode  scatter `xvar' `varlist', ms(none) `fmt' mla(`varlist') mlabpos(3) mlabc(black) `barlabel'
			}
			
			noisily twoway bar `framebar' `xvar', `byby' ///
			fcolor(none) pstyle(p2) barw(`barwidth') horizontal `frameopts' ///
			|| bar `varlist' `xvar', base(`base') pstyle(p1) barw(`barwidth') horizontal ///
			legend(off) ytitle("`xtitle'") xtitle("`ytitle'") `ylah' yla(1/`X', valuelabel tlc(none)) `options' ///
			|| `barlabelcode' || `countcode'
		}
			
		// vertical bars (the default)
		else { 
			if "`wherecount'" != "" gen `where' = `wherecount'
			else if missing(`frame') | `frame' == 0 { 
				su `varlist', meanonly 
				gen `where' = -0.05 * r(max)
			}
			else gen `where' = -0.05 * `frame'
			
			if "`countlabel'`countlabel2'" != "" {
				local countcode scatter `where' `xvar', ms(none) mla(`showcount') mlabc(black) mlabpos(0) `countlabel2'
			}
			if "`barlabel'"  != "none" {
				local barlabelcode scatter `varlist' `xvar',  ms(none) `fmt' mla(`varlist') mlabpos(12) mlabc(black) `barlabel'
			}
			
			noisily twoway bar `framebar' `xvar',  `byby' fcolor(none) pstyle(p2) barw(`barwidth') `frameopts' ///
			|| bar `varlist' `xvar', base(`base') pstyle(p1) barw(`barwidth') ///
			legend(off) xtitle("`xtitle'") ytitle("`ytitle'") xla(1/`X', valuelabel tlc(none)) `ylah' `options' ///
			||  `barlabelcode' 	|| `countcode'
		}

		// list wanted? 
		if "`list'`list2'" != "" {
			if "`count'" != "" char `count'[varname] "count" 
			char `varlist'[varname] "`statistic'" 
			char `xvar'[varname] "`over'"  
			noisily list `xvar' `byvar' `count' `varlist', subvarname noobs sep(0) `1ist2'
		}
	}
	
	// support for second syntax 
	else quietly { 
		
		// need to save variable labels if they exist, as they don't get passed by -collapse- 
		// easier to get counts of non-missing values as a set of scalars -- or a single scalar 
		local x = 0 
			
		foreach v of local varlist { 
			local ++x 
			local text_`x' : var label `v'
			if `"`text_`x''"' == "" local text_`x' "`v'"
			
			if "`countlabel'`countlabel2'" != "" & "`allobs'" != "" { 
				count if `v' < . & `touse'
				local count_`x' = r(N)
			}
		}	
		
		if "`countlabel'`countlabel2'" != "" & "`allobs'" == "" {
			count if `touse'
			local count_N = r(N)
		}
		
		local X = `x'
		
		// -collapse- yields possibly just one observation, so we need to -reshape- shortly
		collapse (`statistic') `varlist' if `touse' [`weight' `exp'], `bybyvar'
			
		tempvar id xvar framebar  
		
		gen `id' = 1
	
		// -rename- before -reshape-  
		tempname y 
		rename (`varlist') `y'#, addnumber 
		 
		reshape long `y', i(`id' `byvar') j(`xvar')
		
		// if the count is a single value, it goes in a -note()-
		// otherwise it goes in a variable 
		if "`countlabel'`countlabel2'" != "" { 
			tempvar listcount 
			if "`allobs'" == "" {
				local countshow note("`countlabelprefix'`count_N'`countlabelsuffix'", `countlabel2')  
				gen `listcount' = `count_N'
			}				
			else {
				tempvar showcount where 
				gen `showcount' = "`countlabelprefix'"
				forval x = 1/`X' {
					replace `showcount' = `showcount' + "`count_`x''`countlabelsuffix'" in `x'
				}

				gen `listcount' = real(word(`showcount', 3))
					
				if "`horizontal'" != "" { 
					if "`wherecount'" != "" gen `where' = `wherecount' 
					else if missing(`frame') | `frame' == 0 {
						su `y', meanonly 
						gen `where' = -0.01 * r(max)
					}
					else gen `where' = -0.01 * `frame'
					local countcode scatter `xvar' `where', ms(none) mlabpos(9) mla(`showcount') mlabc(black) `countlabel2'
				}
				else { 
					if "`wherecount'" != "" gen `where' = `wherecount'
					else if missing(`frame') | `frame' == 0 {
						su `y', meanonly 
						gen `where' = -0.05 * r(max)
					}
					else gen `where' = -0.05 * `frame'
					local countcode scatter `where' `xvar', ms(none) mla(`showcount') mlabpos(0) mlabc(black) `countlabel2'
				}
			}
		}
		
		// want to push results through further calculations? 
		if "`calculator'" != "" { 
			local calculator : subinstr local calculator "@" "`y'", all 
			replace `y' = `calculator'
		}
	
		// put the variable labels or names back as value labels 
		forval x = 1/`X' {
			label define `xvar' `x' `"`text_`x''"', add 
		}
		label val `xvar' `xvar'
		
		// the top of the frame is a variable, even though constant 
		gen `framebar' = `frame'
		
		// want to sort, ascending default? 
		// myaxis from Stata Journal included here 
		if "`sort'" != "" { 
			tempvar newxvar 
			myaxis `newxvar'=`xvar', sort(mean `y') `descending' `subset'
			local xvar `newxvar'
		}
	
		if "`format'" != "" { 
			local fmt mlabformat(`format')
			format `y' `format'
		}  
	
		// horizontal bars 
		if "`horizontal'" != "" {
			if "`barlabel'" != "none" {
				local barlabelcode scatter `xvar' `y', ms(none) `fmt' mla(`y') mlabpos(3) mlabc(black) `barlabel' 
			}
			
			twoway bar `framebar' `xvar', `byby' ///
			fcolor(none) pstyle(p2) barw(`barwidth') horizontal `frameopts' ///
			|| bar `y' `xvar', base(`base') pstyle(p1) barw(`barwidth') horizontal ///
			legend(off) ytitle("") xtitle(`statistic') `ylah' yla(1/`X', valuelabel tlc(none)) `countshow' `options' ///
			|| `barlabelcode' || `countcode' 
		}

		// vertical bars (the default)
		else { 
			if "`barlabel'" != "none" {
				local barlabelcode scatter `y' `xvar', ms(none) `fmt'mla(`y') mlabpos(12) mlabc(black) `barlabel' 
			}
			
			twoway bar `framebar' `xvar', `byby' fcolor(none) pstyle(p2) barw(`barwidth') `frameopts' ///
			|| bar `y' `xvar', base(`base') pstyle(p1) barw(`barwidth') ///
			legend(off) xtitle("") ytitle(`statistic') `ylah' xla(1/`X', valuelabel tlc(none)) `countshow' `options' ///
			|| `barlabelcode'  || `countcode' 
		} 

		// list wanted? 
		if "`list'`list2'" != "" {
 			if "`listcount'" != "" char `listcount'[varname] "count" 
			char `y'[varname] "`statistic'" 
			char `xvar'[varname] " "  
			noisily list `xvar' `byvar' `listcount' `y', subvarname noobs sep(0) `list2' 
		}
	}
end 

*! 1.0.0 NJC 18 March 2021 
program myaxis, sortpreserve 
        version 8.2 

        // syntax parsing 

        // starts: myaxis newvar = varname 
        gettoken newvar 0 : 0, parse(" =") 
        gettoken eqsign 0 : 0, parse("=") 
        syntax varname [if] [in], sort(str asis) ///
        [subset(str asis) DESCending varlabel(str asis) valuelabelname(passthru) MISSing] 

        capture confirm new var `newvar' 
        if "`eqsign'" != "=" exit 198 

        // data to use 
        if "`missing'" != "" marksample touse, novarlist 
        else marksample touse, strok 
        quietly count if `touse' 
        if r(N) == 0 error 2000

        if "`valuelabelname'" != "" { 
                capture label list `valuelabelname' 
                if _rc == 0 { 
                        di as err "value labels `valuelabelname' already exist; specify new name?" 
                        exit 498 
                } 
        }
        else { 
                capture label list `newvar' 
                if _rc == 0 { 
                        di as err "value labels `newvar' already exist; specify new name?"
                        exit 498 
                }
        } 

        // sort() option is key 
        // either like (count) meaning (count varname)  
        // or like (mean mpg)

        if "`subset'" != "" { 
                // does it make sense? are there are any such observations? 
                capture count if `touse' & `subset' 
                if _rc { 
                        di as err "subset(`subset') not true or false condition?" 
                        exit 498 
                } 
                if r(N) == 0 { 
                        di as err "subset(`subset') not satisfied in data?"
                        exit 2000 
                }
                local subset "& (`subset')" 
        } 

        tokenize `sort' 
        if "`1'" == "" | "`3'" != "" PROBLEM 
        
        tempvar work 

        if "`2'" != "" {
                capture confirm var `2' 
                if _rc { 
                        di as err "`2' not an existing variable" 
                        exit 111 
                }
        } 
        else local 2 "`varlist'" 

        // nub of the matter 
        quietly { 
 
                capture egen `work' = `1'(`2') if `touse' `subset', by(`varlist') 
                if _rc PROBLEM 
        
                if "`descending'" != "" replace `work' = -`work'  

                if "`subset'" != "" { 
                        bysort `varlist' (`work') : replace `work' = `work'[1] 
                }  

                egen `newvar' = group(`work' `varlist') if `touse', missing 

        }

        // fix variable label: as supplied, or otherwise as on original variable, 
        // otherwise the original variable name 
        if `"`varlabel'"' == "" {
                local varlabel : variable label `varlist' 
                if `"`varlabel'"' == "" local varlabel "`varlist'" 
        }
        label variable `newvar' `"`varlabel'"' 

        // fix value labels: value labels of original, otherwise values of original
        local vallabel : value label `varlist' 
        if "`vallabel'" != "" { 
                _labmask `newvar' if `touse', values(`varlist') decode `valuelabelname' 
        }  
        else _labmask `newvar' if `touse', values(`varlist') `valuelabelname' 
end 

program PROBLEM 
        di as err "sort() invalid; see {help myaxis}" 
        exit 198 
end 

program _labmask, sortpreserve  
        // based on labmask 1.0.0 NJC 20 August 2002
        // values of -values-, or its value labels, to be labels of -varname-
        version 8.2 
        syntax varname(numeric) [if] [in], VALues(varname) [ valuelabelname(str) decode ]

        marksample touse, novarlist

        tempvar diff decoded group example 
        
        // do putative labels differ? 
        bysort `touse' `varlist' (`values'): /// 
                gen byte `diff' = (`values'[1] != `values'[_N]) * `touse' 
        su `diff', meanonly 
        if r(max) == 1 { 
                di as err "`values' not constant within groups of `varlist'" 
                exit 198 
        } 

        // decode? i.e. use value labels (will exit if value labels not assigned) 
        if "`decode'" != "" { 
                decode `values', gen(`decoded') 
                local values "`decoded'" 
        }       

        // we're in business 
        if "`valuelabelname'" == ""  local valuelabelname "`varlist'" 
        
        // groups of values of -varlist-; assign labels 
        
        by `touse' `varlist' : gen byte `group' = (_n == 1) & `touse' 
        qui replace `group' = sum(`group') 

        gen long `example' = _n 
        local max = `group'[_N]  
        
        forval i = 1 / `max' { 
                su `example' if `group' == `i', meanonly 
                local label = `values'[`r(min)'] 
                local value = `varlist'[`r(min)'] 
                label def `valuelabelname' `value' `"`label'"', modify  
        } 

        label val `varlist' `valuelabelname' 
end 

