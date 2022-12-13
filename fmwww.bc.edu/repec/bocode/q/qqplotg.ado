*! 2.0.0 NJC 11 December 2022
*! 1.0.0 NJC 9 March 2011
* qqplot 3.3.3  07mar2005
program qqplotg, sort
	version 8.2       

	capture syntax varname(numeric) [if] [in], group(varname) ///
	[flip DIFFvsmean GENerate(str) * ] 

	if _rc {
		syntax varlist(min=2 max=2 numeric) [if] [in] ///
		[, flip diffvsmean Generate(str) *]
	} 

	tempvar touse 
	mark `touse' `if' `in'		/* but do not markout varlist */

	qui if "`group'" != "" { 
		tempname stub 
		separate `varlist' if `touse', by(`group') veryshortlabel ///
		gen(`stub')
		local varlist `r(varlist)' 

		local nvars : word count `varlist' 
		if `nvars' != 2 { 
			di as err "`nvars' categories in `group': should be 2"
			exit 498
		} 
		if "`flip'" != "" { 
			tokenize "`varlist'" 
			local varlist "`2' `1'" 
		} 
	} 

	_get_gropts , graphopts(`options') getallowed(RLOPts plot addplot)
	local options `"`s(graphopts)'"'
	local rlopts `"`s(rlopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
	_check4gropts rlopts, opt(`rlopts')

	tokenize `varlist'
	tempvar VARY VARX CNT NEWX2
	quietly {
		gen `VARY' = `1' if `touse'
		gen `VARX' = `2' if `touse'
		gen long `CNT' = sum(`VARY'<.)
		local cnty = `CNT'[_N]
		replace `CNT' = sum(`VARX'<.)
		local cntx = `CNT'[_N]
		drop `CNT'
		if `cntx' == 0 | `cnty' == 0 error 2000 
		if `cnty' > `cntx' {
			QQp2 `VARY' `cnty' `cntx'
		}
		if `cnty' < `cntx' {
			QQp2 `VARX' `cntx' `cnty'  
		}

		QQp1 `VARY' `VARX' `NEWX2'
		_crcslbl `VARY' `1'
		_crcslbl `NEWX2' `2'
	}

	local yttl : var label `VARY'
	local xttl : var label `NEWX2'
	if `"`plot'`addplot'"' == "" {
		local legend legend(nodraw)
	}

	if "`diffvsmean'" != "" { 

	quietly { 
		tempvar diff mean 
		gen `diff' = `VARY' - `NEWX2' 
		gen `mean' = (`VARY' + `NEWX2') / 2
		local YTTL `"`yttl'"'  
		local yttl `"`yttl' - `xttl'"'
		local xttl `"(`YTTL' + `xttl') / 2"'
	} 

	version 8: graph twoway				///
	(scatter `diff' `mean',		        	///
		sort					///
		ytitle(`"`yttl'"')			///
		xtitle(`"`xttl'"')			///
		ms(Oh) mc(blue)           yla(, ang(h)) /// 
		`legend'				///
		`options'				///
	)						///
	(function 0,					///
		range(`mean')				///
		lstyle(refline)				///
		yvarlabel("Reference")			///
		`rlopts'				///
	)						///
	|| `plot' || `addplot'				///
	// blank

	} 

	else { 

	version 8: graph twoway				///
	(scatter `VARY' `NEWX2',			///
		sort					///
		ytitle(`"`yttl'"')			///
		xtitle(`"`xttl'"')			///
		ms(Oh) mc(blue)           yla(, ang(h)) /// 
		`legend'				///
		`options'				///
	)						///
	(function y=x,					///
		range(`NEWX2')				///
		lstyle(refline)				///
		yvarlabel("Reference")			///
		`rlopts'				///
	)						///
	|| `plot' || `addplot'				///
	// blank
	} 

	if "`generate'" != "" { 
		if "`diffvsmean'" != "" { 
			confirm new variable `generate'd `generate'm  
			gen `generate'd = `diff'  
			label var `generate'd `"`yttl'"' 
			gen `generate'm = `mean' 
			label var `generate'm `"`xttl'"' 
		} 

		else {
		confirm new variable `generate'y `generate'x 
		
		gen `generate'y = `DQ' 
		label var `generate'y `"`yttl'"' 
		gen `generate'x = `NEWX2' 
		label var `generate'x `"`xttl'"'
		} 
	} 
end

program QQp1 
	version 8.2
	tempvar YORDER
	quietly {
		sort `1'
		gen long `YORDER' = _n
		sort `2'
		gen `3' =`2'[`YORDER']
	}
end

program QQp2 /* varname old# new# */	
	version 8.2
	tempvar INT FRAC TEMP
	quietly {
		sort `1'
		gen long `INT' = (_n-0.5) * `2'/`3' + 0.5
		gen `FRAC' = 0.5 + (_n-0.5) * `2'/`3' - `INT'
		gen `TEMP' = (1-`FRAC') * `1'[`INT'] + `FRAC' * `1'[`INT'+1]
		replace `1' = `TEMP' 
	}
end

