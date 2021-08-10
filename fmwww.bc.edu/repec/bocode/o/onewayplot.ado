program onewayplot, sort  
*! 2.1.3 NJC 27 October 2004
* 2.1.2 NJC 11 August 2004
* 2.1.1 NJC 21 July 2004
* 2.1.0 NJC 13 February 2004
* 2.0.3 NJC 17 July 2003 
* 2.0.2 NJC 7 July 2003 
* 2.0.1 NJC 6 July 2003 
* 2.0.0 NJC 3 July 2003 
* 1.2.1 NJC 18 October 1999 
* 1.1.0 NJC 27 April 1999 
* 1.0.0 NJC 23 April 1999 
	version 8.0
	syntax varlist(min=1 numeric) [if] [in]          ///
	[, CEnter CEntre Height(real 0.8) Fraction(str) STack by(varname) VERTical  ///
	Width(numlist max=1 >0) PLOT(str asis) variablelabels * ] 

	if "`fraction'" != "" {
		di as inp "fraction()" as txt ": please use " as inp "height()"
		capture confirm num `fraction' 
		if _rc { 
			di as err "fraction() invalid -- invalid number"
			exit 198 
		}
		local height = `fraction' 
	} 	

	marksample touse, novarlist 
	local noby = "`by'" == ""
	tokenize `varlist' 
	local nvars : word count `varlist' 
	
	// variables for plot 
	qui if `nvars' > 1 { 
		if "`by'" != "" { 
			di as err ///
			"by() may not be combined with more than one variable"
			exit 198
		}	
		else {
			// several variables are stacked into one
			// x axis shows `data' 
			// y axis shows _stack 
			preserve
			if "`variablelabels'" != "" { 
				forval i = 1/`nvars' { 
					local l : variable label ``i''
					local labels `"`labels' `i' `"`l'"'"'
				}
			} 	
			else forval i = 1/`nvars' {
                		local labels "`labels'`i' ``i'' "
		        }
			tempvar data 
			stack `varlist' if `touse', into(`data') clear
			drop if missing(`data') 
			if "`width'" != "" { 
				replace `data' = `width' * floor(`data'/`width')
			} 	
			label var `data' "`varlist'"
			label var _stack `" "' 
			tempname stlbl
			label def `stlbl' `labels' 
		        label val _stack `stlbl'
			su _stack, meanonly 
			local range "`r(min)'/`r(max)'" 
			if "`stack'" != "" { 
				tempvar count
				sort _stack `data', stable 
				by _stack `data' : gen `count' = _n - 1  
				su `count', meanonly
				if "`centre'`center'" != "" { 
					by _stack `data' : ///
					replace `count' = _n - (_N + 1)/2
				} 
				if r(max) > 0 { 
					replace _stack = /// 
					_stack + `height' * `count' / r(max) 
				} 	
			}	
		}
	}	
	else {
		qui if "`by'" == "" {
			// a single variable, no by()
			// x axis shows `varlist' 
			// y axis shows `by' = 0  
			tempvar by
			gen byte `by' = 0 if `touse'
			tempname bylbl 
			label def `bylbl' 0 "`varlist'"
			label val `by' `bylbl' 
		}
		else qui {
			// a single variable with by()
			// x axis shows `varlist' 
			// y axis shows `by' (or `bycount' if stack option)
			tempvar by2
			capture confirm numeric variable `by'
			if _rc == 7 { 
				encode `by' if `touse', gen(`by2')
			}	
			else { 
				gen `by2' = `by' if `touse'
				label val `by2' `: value label `by'' 
			} 	
			_crcslbl `by2' `by' 
			local by "`by2'"

			capture levels `by' 
			if _rc { 
				su `by', meanonly 
				local range "`r(min)'/`r(max)'" 
			} 
			else local range "`r(levels)'" 
		}	
		
		qui if "`width'" != "" { 
			tempvar rounded 
			gen `rounded' = `width' * floor(`varlist' / `width')
			_crcslbl `rounded' `varlist' 
			local varlist "`rounded'" 
		} 	
	
		qui if "`stack'" != "" { 
			tempvar count bycount 
			sort `touse' `by' `varlist', stable 
			by `touse' `by' `varlist': gen `count' = _n - 1 
			su `count' if `touse', meanonly
			if "`centre'`center'" != "" { 
				by `touse' `by' `varlist' : ///
				replace `count' = _n - (_N + 1)/2 
			} 
			gen `bycount' = `by' if `touse' 
			if r(max) > 0 { 
				replace `bycount' = /// 
				`bycount' + `height' * `count' / r(max) 
			} 	
			_crcslbl `bycount' `by'
			label val `bycount' `: value label `by'' 
		} 
		
		local gif "if `touse'" 
	}	

	// plot details 
	if `noby' & `nvars' == 1 local axlabel ", nolabels noticks nogrid" 
	else local axlabel "`range', ang(h) valuelabel" 
	
	if `noby' local axtitle `" "' 
	else { 
		local axtitle : variable label `by' 
		if `"`axtitle'"' == "" local axtitle "`by'" 
	} 	

	if "`by'" != "" { 
		if "`stack'" != "" { 
			local yshow "`bycount'" 
			local xshow "`varlist'" 
		} 	
		else { 
			local yshow "`by'" 
			local xshow "`varlist'" 
		} 	
	}
	else {
		local yshow "_stack" 
		local xshow "`data'" 
	}

	su `yshow', meanonly
	local margin = cond(r(max) == r(min), 0.1, 0.05 * (r(max) - r(min)))
	local stretch "r(`= r(min) - `margin'' `= r(max) + `margin'')" 
	if "`vertical'" != "" local stretch "xsc(`stretch')" 
	else local stretch "ysc(`stretch')" 

	if "`vertical'" != "" { 
		scatter `xshow' `yshow' `gif',     ///
		ms(Oh) xti(`"`axtitle'"')               /// 
		xla(`axlabel') `stretch' `options'      ///
		|| `plot' 
		// blank 
	} 	
	else { 
		scatter `yshow' `xshow' `gif',    ///
		ms(Oh) yti(`"`axtitle'"')              /// 
		yla(`axlabel') `stretch' `options'     /// 
		|| `plot' 
		// blank 
	} 	
end 	

/* 

	2.1.3 The -sort-s were all made -, stable-. This is important  
	when you want to add -mlabel()- and -mlabel()- contains 
	order-sensitive information e.g. on time of observation. 

*/ 

