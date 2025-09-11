*! 1.2.0 NJC 4 September 2025
*! 1.1.0 NJC 24 August 2020 
* 1.0.1 NJC 29 January 2018 
* 1.0.0 NJC 25 October 2017 
program niceloglabels  
	version 11 
        /// fudge() undocumented 

	gettoken first 0 : 0, parse(" ,")  

	capture confirm numeric variable `first' 

	if _rc == 0 {
		// syntax varname(numeric), Local(str) Style(str) [ Powers Fudge(real 1) UNITfraction ] 

		capture syntax [if] [in] , Local(str) Style(str) [ Powers Fudge(real 1) UNITfraction] 
		
		if _rc { 
			Explain 
			exit 198 
		}
		
		local varlist `first'  

		marksample touse 
		quietly count if `touse' 	
		if r(N) == 0 exit 2000 
	} 
	else { 
		// syntax #1 #2 , Local(str) Style(str) [ Powers Fudge(real 1) UNITfraction ] 

		capture confirm number `first' 
		
		if _rc { 
			Explain 
			exit 198 
		}
		
		gettoken second 0 : 0, parse(" ,") 
		capture syntax , Local(str) Style(str) [ Powers Fudge(real 1) UNITfraction ]
		
		if _rc { 
			Explain 
			exit 198 
		}
 
		if _N < 2 { 
			preserve 
			quietly set obs 2 
		}
	
		tempvar varlist touse 
		gen `varlist' = cond(_n == 1, `first', `second') 
		gen byte `touse' = _n <= 2 
	}	

	local style = trim(subinstr("`style'", " ", "", .)) 
	* style 3 is undocumented 
	if !inlist("`style'", "1", "13", "15", "125", "147", "2", "3") { 
		di as err "invalid style: choices are 1 13 15 125 147 2" 
		exit 498 
	} 
	
	tempname dmin dmax 
	su `varlist' if `touse', meanonly 
	scalar `dmin' = r(min) 
	scalar `dmax' = r(max) 

	if `dmin' == 0 { 
		di as err "zero values present" 
		exit 498 
	}
	else if `dmin' < 0 { 
		di as err "negative values present" 
		exit 498 
	} 
	else if (`dmax' - `dmin') == 0 { 
		di as err "minimum and maximum equal?" 
		exit 498 
	} 
	
	tempvar logx 
	quietly {
		if "`style'" == "2" {
			gen double `logx' = log10(`varlist')/log10(2) if `touse'
		}
		else if "`style'" == "3" { 
			gen double `logx' = log10(`varlist')/log10(3) if `touse'
		}
		else gen double `logx' = log10(`varlist') if `touse' 
	}

	su `logx', meanonly 
	// default is to bump (minimum, maximum) (down, up) by 1%
	// otherwise we can be trapped by precision problems, 
	// e.g. floor(log10(1000)) is returned as 2 not 3
	// fix in 1.1.0 for negative powers 
	local lmin = ceil(r(min) * (100 - sign(r(min)) * `fudge')/100) 
	local lmax = floor(r(max) * (100 + sign(r(max)) * `fudge')/100) 

	local p = "`powers'" != "" 
	local u = "`unitfraction'" != ""
	local pu = `p' & `u' 

        if `u' & inlist("`style'", "15", "125", "13", "147") { 
		noisily di "note: unitfraction option not supported for style `s'"
	}

	if "`style'" == "2" { 
		forval n = `lmin'/`lmax' { 
			local this = 2^`n'

			if `pu' { 
				if `n' < 0 { 
					local N = -`n' 
					local this `" `this' "1/2{sup:`N'}" "' 
				}
				else if `n' == 0 local this "1" 
				else local this `"`this' "2{sup:`n'}" "' 
			}  
			else { 
				if `p' local this `" `this' "2{sup:`n'}" "'  
				else if `u' & (`n' < 0) { 
					local denom = 2^(-`n')  
					local this `" `this' "1/`denom'" "' 
				} 
				else if `u' & (`n' == 0) local this "1"
			} 

			local all `all' `this' 
		} 

	}
	else if "`style'" == "3" { 
		forval n = `lmin'/`lmax' { 
			local this = 3^`n'

			if `pu' { 
				if `n' < 0 { 
					local N = -`n' 
					local this `" `this' "1/3{sup:`N'}" "' 
				} 
				else if `n' == 0 local this "1" 
				else local this `"`this' "3{sup:`n'}" "' 
			}  
			else { 
				if `p' local this `" `this' "3{sup:`n'}" "'  
				else if `u' & (`n' < 0) { 
					local denom = 3^(-`n')  
					local this `" `this' "1/`denom'" "' 
				} 
				else if `u' & (`n' == 0) local this "1" 
			} 
 
			local all `all' `this' 
		} 

	}
	else if "`style'" == "1" { 
		forval n = `lmin'/`lmax' { 
			local this = 10^`n'

 			if `pu' { 
				if `n' < 0 { 
					local N = -`n' 
					local this `" `this' "1/10{sup:`N'}" "' 
				} 
				else if `n' == 0 local this "1" 
				else local this `"`this' "10{sup:`n'}" "' 
			}  
			else { 
				if `p' local this `" `this' "10{sup:`n'}" "'  
				else if `u' & (`n' < 0) { 
					local denom = 10^(-`n')  
					local this `" `this' "1/`denom'" "' 
				} 
				else if `u' & (`n' == 0) local this "1" 
			} 

			local all `all' `this' 
		} 
	}
	else if "`style'" == "13" { 
		local nm1 = `lmin' - 1 
		if `dmin' <= 3 * 10^`nm1' & `dmax' >= 3 * 10^`nm1' { 
			local this = 3 * 10^`nm1' 
			if `p' local this `" `this' "3x10{sup:`nm1'}" "' 
			local all `this' 
		} 

		forval n = `lmin'/`lmax' { 
			local this = 10^`n' 
			if `p' local this `" `this' "10{sup:`n'}" "' 
	
			if `dmax' >= 3 * 10^`n' { 		 
				local that = 3 * 10^`n' 
				if `p' local that `" `that' "3x10{sup:`n'}" "' 
			} 
			else local that 
	 
			local all `all' `this' `that' 
		} 
	} 
	else if "`style'" == "15" { 
		local nm1 = `lmin' - 1 
		if `dmin' <= 5 * 10^`nm1' & `dmax' >= 5 * 10^`nm1' { 
			local this = 5 * 10^`nm1' 
			if `p' local this `" `this' "5x10{sup:`nm1'}" "'  
			
			local all `this' 
		} 

		forval n = `lmin'/`lmax' { 
			local this = 10^`n' 
			if `p' local this `" `this' "10{sup:`n'}" "' 
	
			if `dmax' >= 5 * 10^`n' { 		 
				local that = 5 * 10^`n' 
				if `p' local that `" `that' "`s'x10{sup:`n'}" "' 
			} 
			else local that 
	 
			local all `all' `this' `that' 
		} 
	} 

	else if "`style'" == "125" { 
		local nm1 = `lmin' - 1 
		if `dmin' <= 2 * 10^`nm1' & `dmax' >= 2 * 10^`nm1' { 
			local this = 2 * 10^`nm1' 
			if `p' local this `" `this' "2x10{sup:`nm1'}" "' 
			local all `this' 
		}

		if `dmin' <= 5 * 10^`nm1' & `dmax' >= 5 * 10^`nm1' { 
			local this = 5 * 10^`nm1' 
			if `p' local this `" `this' "5x10{sup:`nm1'}" "' 
			local all `all' `this' 
		} 

		forval n = `lmin'/`lmax' { 
			local this = 10^`n' 
			if `p' local this `" `this' "10{sup:`n'}" "' 

			if `dmax' >= 2 * 10^`n' { 
				local that = 2 * 10^`n' 
				if `p' local that `" `that' "2x10{sup:`n'}" "' 
			}
			else local that 

 			if `dmax' >= 5 * 10^`n' { 
				local tother = 5 * 10^`n' 
				if `p' local tother `" `tother' "5x10{sup:`n'}" "' 			
			}
			else local tother 
			 
			local all `all' `this' `that' `tother'
		}
	} 
	else if "`style'" == "147" { 
		if `u' noisily di "note: unitfraction option not supported for style 147"

		local nm1 = `lmin' - 1 
		if `dmin' <= 4 * 10^`nm1' & `dmax' >= 4 * 10^`nm1' { 
			local this = 4 * 10^`nm1' 
			if `p' local this `" `this' "4x10{sup:`nm1'}" "' 
			local all `this' 
		}

		if `dmin' <= 7 * 10^`nm1' & `dmax' >= 7 * 10^`nm1'  { 
			local this = 7 * 10^`nm1' 
			if `p' local this `" `this' "7x10{sup:`nm1'}" "' 
			local all `all' `this' 
		} 

		forval n = `lmin'/`lmax' { 
			local this = 10^`n' 
			if `p' local this `" `this' "10{sup:`n'}" "' 

			if `dmax' >= 4 * 10^`n' { 
				local that = 4 * 10^`n' 
				if `p' local that `" `that' "4x10{sup:`n'}" "' 
			}
			else local that 

 			if `dmax' >= 7 * 10^`n' { 
				local tother = 7 * 10^`n' 
				if `p' local tother `" `tother' "7x10{sup:`n'}" "' 
			}
			else local tother 
		 
			local all `all' `this' `that' `tother'
		}
	} 

	di `"`all'"'  
	c_local `local' `"`all'"'  
end 
		
program Explain 
	di _n "invalid syntax?"
	di "{p}There are two syntaxes, most simply:{p_end}"
	di "{p 4 4 2}{cmd:niceloglabels} {it:varname}{cmd:, local(}{it:macname}{cmd:) style(}{it:style}{cmd:)}{p_end}"
	di "{p 4 4 2}{cmd:niceloglabels} {it:#1 #2}{cmd:, local(}{it:macname}{cmd:) style(}{it:style}{cmd:)}{p_end}"
	di "{p}For more information, see help on {help niceloglabels}{p_end}"
end 
