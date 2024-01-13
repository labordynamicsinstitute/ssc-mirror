*! 3.0.0 NJC 5 December 2023 
*! 2.0.0 NJC 11 December 2022
*! 1.0.0 NJC 9 March 2011
* qqplot 3.3.3  07mar2005
program qqplotg, sort
	version 8.2      
	
	local opts flip dvm dvp DIFFvsmean GENerate(str) TRANSform(str) 
	local opts `opts' by(str asis) a(str) MISSing lpolyopts(str asis)
	
	// support 2022 syntax group() diffvsmean 
	capture syntax varname(numeric) [if] [in], group(varname) [`opts' *] 

	if _rc capture syntax varname(numeric) [if] [in], over(varname) [`opts' *] 

	if _rc {
		syntax varlist(min=2 max=2 numeric) [if] [in] [, `opts' *]
	} 
		
	// a() expects a string to support input such as 1/3, but the result must be numeric 
	if "`a'" == "" local a = 0.5 
	else { 
		capture local A = `a'
		capture confirm number `A'
		if _rc { 
			di as err "a(`a') should define a number"
			exit 109 
		}
	}

	// supporting 2022 syntax 
	if "`group'" != "" local over `group'
	if "`diffvsmean'" != "" local dvm dvm
	
	if "`dvm'" != "" & "`dvp'" != "" {
		di as error "choose between difference vs mean and difference vs plotting position" 
		exit 198 
	}  

	tempvar touse 
	mark `touse' `if' `in'		/* but do not markout varlist */
	
	if "`by'" != "" { 
		gettoken byvar byopts : by, parse(,)
		Parsebyopts `byopts'
		local byby by(`byvar', `byopts')
			
		if "`missing'" == "" markout `touse' `byvar', strok 
	}
	else { 
		tempvar byvar 
		gen byte `byvar' = 1 
	}

	qui if "`over'" != "" { 
		tempname stub 
		separate `varlist' if `touse', by(`over') veryshortlabel ///
		gen(`stub')
		local varlist `r(varlist)' 

		local nvars : word count `varlist' 
		if `nvars' != 2 { 
			di as err "`nvars' categories in `over': should be 2"
			exit 498
		}
	} 
	
	if "`flip'" != "" { 
		tokenize "`varlist'" 
		local varlist "`2' `1'" 
	} 

	_get_gropts , graphopts(`options') getallowed(RLOPts plot addplot)
	local options `"`s(graphopts)'"'
	local rlopts `"`s(rlopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
	_check4gropts rlopts, opt(`rlopts')

	tokenize `varlist'
	tempvar VARY VARX CNT NEWX2 BYGROUP X  thisuse 
	quietly {
		gen `VARY' = `1' if `touse'
		gen `VARX' = `2' if `touse'
		
		if "`transform'" != "" { 
			Trans "`transform'" "`VARY'" "`touse'" "`1'" "`over'"
			Trans "`transform'" "`VARX'" "`touse'" "`2'" "`over'"
		}
		
		egen `BYGROUP' = group(`byvar') if `touse'
		su `BYGROUP', meanonly 
		gen byte `thisuse' = 0 
		gen `X' = . 
		
		forval g = 1/`r(max)' { 
			replace `thisuse' = `BYGROUP' == `g'
			bysort `thisuse' : gen long `CNT' = sum(`VARY'<.) if `thisuse'
			local cnty = `CNT'[_N]
			replace `CNT' = sum(`VARX'<.) if `thisuse'
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
			replace `X' = `NEWX2' if `thisuse'
			drop `NEWX2'
		}

		_crcslbl `VARY' `1'
		_crcslbl `X' `2'
	}
	
	local yttl : var label `VARY'
	local xttl : var label `X'
	if `"`plot'`addplot'`by'"' == "" {
		local legend legend(nodraw)
	}

	if "`dvm'" != "" { 

	quietly { 
		tempvar diff mean 
		gen `diff' = `VARY' - `X' 
		gen `mean' = (`VARY' + `X') / 2
		local YTTL `"`yttl'"'  
		local yttl `"`yttl' - `xttl'"'
		local xttl `"(`YTTL' + `xttl') / 2"'
	} 
	

	version 8: graph twoway		///
	(scatter `diff' `mean',		///
		sort					///
		ytitle(`"`yttl'"')		///
		xtitle(`"`xttl'"')		///
		ms(Oh) mc(blue)         ///
		yla(, ang(h)) 			/// 
		`legend'				///
		`byby'                  ///
		`options'				///
	)							///
	(function 0,				///
		range(`mean')			///
		lstyle(refline)			///
		yvarlabel("Reference")	///
		`rlopts'				///
	)							///
	(lpoly `diff' `mean', `lpolyopts') ///
	|| `plot' || `addplot'		///
	// blank

	} 
	
	else if "`dvp'" != "" {
		
	quietly {
		tempvar N pp diff 
		
		gen `diff' = `VARY' - `X' 
		bysort `BYGROUP' (`X' `VARY') : gen `N' = sum(`X' < .)
		by `BYGROUP' : replace `N' = `N'[_N]
		by `BYGROUP' : gen `pp' = (_n - `a') / (`N' + 1 - 2 * (`a')) if `X' < . 
	
	    local YTTL `"`yttl'"'  
		local yttl `"`yttl' - `xttl'"'
		local xttl "Fraction of the data"
	} 
	
	
	version 8: graph twoway		///
	(scatter `diff' `pp',		///
		sort					///
		ytitle(`"`yttl'"')		///
		xtitle(`"`xttl'"')		///
		ms(Oh) mc(blue)         ///
		yla(, ang(h)) 			/// 
		xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1)  /// 
		`legend'				///
		`byby'                  ///
		`options'				///
	)							///
	(function 0,				///
		range(`mean')			///
		lstyle(refline)			///
		yvarlabel("Reference")	///
		`rlopts'				///
	)							///
	(lpoly `diff' `pp', `lpolyopts') /// 
	|| `plot' || `addplot'		///
	// blank

			
	}

	else { 

	version 8: graph twoway		///
	(scatter `VARY' `X',	    ///
		sort					///
		ytitle(`"`yttl'"')		///
		xtitle(`"`xttl'"')		///
		ms(Oh) mc(blue)         ///
		yla(, ang(h)) 			/// 
		`legend'				///
		`byby'                  /// 
		`options'				///
	)							///
	(function y=x,				///
		range(`X')  			///
		lstyle(refline)			///
		yvarlabel("Reference")	///
		`rlopts'				///
	)							///
	|| `plot' || `addplot'		///
	// blank
	} 

	if "`generate'" != "" { 
		if "`dvm'" != "" { 
			confirm new variable `generate'd `generate'm  
			gen `generate'd = `diff'  
			label var `generate'd `"`yttl'"' 
			gen `generate'm = `mean' 
			label var `generate'm `"`xttl'"' 
		} 
		
		else if "`dvp'" != "" {
			confirm new variable `generate'd `generate'p 
			gen `generate'd = `diff'  
			label var `generate'd `"`yttl'"' 
			gen `generate'p = `pp' 
			label var `generate'p `"`xttl'"' 
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

program Trans 
	args transform varname touse which over

	if strpos("`transform'", "@") {
		local recipe = subinstr("`transform'", "@", "`varname'", .)
	}
	else local recipe `transform'(`varname') 
		
	count if missing(`varname') & `touse'
	local bad = r(N)
	replace `varname' = `recipe' if `touse'
	count if missing(`varname') & `touse'
	local BAD = r(N)
			
	if `BAD' > `bad' {
		if "`over'" != "" { 
			su `over' if `varname' < ., meanonly 
			local where "for `over' == `r(min)'"
		}
		else local where "for `which'"
				
		local nbad = `BAD' - `bad'
		di as err "warning: `transform' leads to `nbad' missing " plural(`nbad', "value") " `where'"
	}
end 

program Parsebyopts 
	syntax , [ LEGend(str asis) note(str asis) * ]
	if `"`legend'"' == "" local legend off 
	c_local byopts legend(`legend') note(`"`note'"') `options'
end 
