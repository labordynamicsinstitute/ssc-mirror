*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_estcot 
program define _mpitb_estcot 
syntax , FRame(name) TVar(varname) Year(varname) 		/// 
		Measure(name) SPec(name) 					/// required by _mpitb_estres (passthrough)
		[INSEQuence TOTal SUBgvar(varname) noAnn noRaw Verbose *]	// optional for _mpitb_estres (passthrough) 
	
	// *Loa(passthru) 
	
	* check: inseq or total
	if "`insequence'`total'" == "" {
		di as err "At least one of -insequence- or -total- is required."
		e 197 
	}

	* check: ann or raw
	if "`ann'" == "noann" & "`raw'" == "noraw" {
		di as err "Please choose at least one of -ann- and -raw-!"
		exit 197 
	}

	* check: last estimates existing?
	if "`e(cmd)'" == "" {
		e 301
	}
	
	* check: estimated by mean? 
	if "`e(cmd)'" != "mean" {
		di as err "Last estimates not obtained by {bf:mean}."
		exit 197
	}
	
	* check: single variable 
	if `: word count `e(varlist)'' > 1 {
		di as err "Estimation command has more than one variable in varlist."
		exit 197 
	}
	
	loc ovar `e(over)'			// only for tests
	* check: tvar in over?
	if !`: list tvar in ovar' {
		di as err "time variable {bf:`tvar'} not found in over() option of estimation command."
		exit 111 
	}
	* check: subgvar in over?
	if !`: list subgvar in ovar' {
		di as err "subgroup variable {bf:`subgvar'} not found in over() option of estimation command."
		exit 111 
	}

	* verbose option
	if "`verbose'" == "" {
		loc qui qui
	}

	* update local options
	loc options `options' measure(`measure') spec(`spec') 
	
	tempname cr 
	est sto `cr'

	* get est info
	loc v `e(varlist)'
	if "`e(subpop)'" != "" {
		loc subpop & `e(subpop)'		// improve: condition may stated differently
	}
	qui levelsof `tvar' if e(sample) `subpop' , loc(tlist)
	
	* lists 
	qui sum `tvar' if e(sample) `subpop' , mean
	loc tmin = r(min)
	loc tmax = r(max)

	if "`insequence'" != "" {
		loc t1list : list tlist - tmin 
		loc t0list : list tlist - tmax 
	}
	if "`total'" != "" {
		loc t1list "`t1list' `tmax'"
		loc t0list "`t0list' `tmin'"
	}
	
	loc Nch : list sizeof t0list 	
	forval c = 1/`Nch' {
		local t0 : word `c' of `t0list'
		local t1 : word `c' of `t1list'
		
		* calc duration
		sum `year' if `tvar' == `t0' , mean
		loc yt0 = r(mean)
		sum `year' if `tvar' == `t1' , mean
		loc yt1 = r(mean)
		loc dy = `yt1' - `yt0' 
		
		loc yandt yt0(`yt0') yt1(`yt1') t0(`t0') t1(`t1')		// added to all
		if "`subgvar'" == "" {
			
			* raw 
			if "`raw'" != "noraw" {
				* abs
				`qui' lincom (`v'@`t1'.`tvar' - `v'@`t0'.`tvar') 			
				_mpitb_stores  , fr(`frame') l(nat) ct(1) ann(0) `yandt' `options'
				
				* rel
				if _b[`v'@`t0'.`tvar'] != 0 {								// store mv rather than skipping?
					`qui' nlcom ((_b[`v'@`t1'.`tvar'] - _b[`v'@`t0'.`tvar']) / _b[`v'@`t0'.`tvar']) * 100 , post 
					_mpitb_stores  , fr(`frame') l(nat) ct(2) ann(0) `yandt' `options'
					qui est res `cr' 
				}
			}
			* ann
			if "`ann'" != "noann" {
				* abs
				`qui' lincom (`v'@`t1'.`tvar' - `v'@`t0'.`tvar')/`dy'
				_mpitb_stores  , fr(`frame') l(nat) ct(1) ann(1) `yandt' `options'
				
				* rel
				if _b[`v'@`t0'.`tvar'] != 0 {								
					`qui' nlcom ((`=_b[`v'@`t1'.`tvar']' / _b[`v'@`t0'.`tvar'])^(1/`dy')-1) * 100 , post  			
					_mpitb_stores  , fr(`frame') l(nat) ct(2) ann(1) `yandt' `options'
					qui est res `cr' 
				}
			}
		}
		else if "`subgvar'" != "" {
			qui levelsof `subgvar' if e(sample) `subpop' , loc(slist)
			foreach s of loc slist {
				* raw
				if "`raw'" != "noraw" {
					* abs 
					`qui' lincom (`v'@`s'.`subgvar'#`t1'.`tvar' - `v'@`s'.`subgvar'#`t0'.`tvar') 		
					_mpitb_stores  , fr(`frame') l(`subgvar') ctype(1) ann(0) subg(`s') `yandt' `options'

					* rel
					if _b[`v'@`s'.`subgvar'#`t0'.`tvar'] != 0 {								
						`qui' nlcom ((_b[`v'@`s'.`subgvar'#`t1'.`tvar'] - _b[`v'@`s'.`subgvar'#`t0'.`tvar']) / _b[`v'@`s'.`subgvar'#`t0'.`tvar']) * 100, post 
						_mpitb_stores  , fr(`frame') l(`subgvar') ctype(2) ann(0) subg(`s') `yandt' `options'
						qui est res `cr'
					}
				}
				* ann 
				if "`ann'" != "noann" {
					* abs
					`qui' lincom (`v'@`s'.`subgvar'#`t1'.`tvar' - `v'@`s'.`subgvar'#`t0'.`tvar')/`dy' 	
					_mpitb_stores  , fr(`frame') l(`subgvar') ctype(1) ann(1) subg(`s') `yandt' `options'

					* rel
					if _b[`v'@`s'.`subgvar'#`t0'.`tvar'] != 0 {								
						`qui' nlcom ((`=_b[`v'@`s'.`subgvar'#`t1'.`tvar']' / _b[`v'@`s'.`subgvar'#`t0'.`tvar'])^(1/`dy')-1) * 100 , post 
						_mpitb_stores  , fr(`frame') l(`subgvar') ctype(2) ann(1) subg(`s') `yandt' `options'
						qui est res `cr'
					}
				}
			}
		}
	}
end
