*===================================================================================*
* Ado-file: 	OneClick Version 6
* Author: 		Shutter Zor(左祥太)
* Affiliation: 	Accounting Department, Xiamen University
* E-mail: 		Shutter_Z@outlook.com 
* Date: 		2024/11/21
* Update: 		Optimise output, add options                            
*===================================================================================*

*- Decimal-to-Binary function
capture program drop bin_transfer
program define bin_transfer, rclass
	version 14
	args dec_num
	local bin_num ""
	local remainder 0
	while `dec_num' > 0 {
		local remainder = mod(`dec_num', 2)
		local bin_num "`remainder'`bin_num'"
		local dec_num = floor(`dec_num'/2)
	}
	return local binary "`bin_num'"
end

*- Main function - oneclick 6 complete edition
capture program drop oneclick
program define oneclick
	version 14
	
	syntax  varlist(min=3 fv ts),			    	///
			Method(string)							///
			Pvalue(real)							///
			FIXvar(varlist fv ts)					///
			[										///
				Options(string)						///
				Zvalue								///
				Threshold(numlist integer>0)		///
				Saveplace(string)					///
				BEST								///
				FULL								///
			]


	gettoken y ctrlvar : varlist
	gettoken x otherx : fixvar
	tokenize "`ctrlvar'"
	
	preserve
		qui gen subset = ""
		qui gen direction = .
		qui gen coef = .
		qui gen p = ""
		qui gen r2 = .
		
		* computer combination
		local CtrlLen = wordcount("`ctrlvar'")
		local temp = ustrregexra("`ctrlvar'"," ","")
		local Lenth = 2^`CtrlLen'
		forvalues i = 1/`Lenth' {
			local Combo ""
			bin_transfer `i'
			forvalues j = 1/`CtrlLen' {
				if substr(r(binary),-`j',1) == "1" {
					local addword "``j''"
					local Combo "`Combo' `addword'"
				}
			}
			local Combo`i' = "`Combo'"
		}
		
		*- set obs num
		local n = _N
		if `Lenth' > `n' {
			qui set obs `Lenth'
		}
		if `Lenth' <= `n' {
			qui set obs `n'
		}
		
		dis as text ""
		display as text  _dup(54) "_"
		dis as text "{bf:#1 oneclick abstract:}"
		display as text  _dup(54) "-"
		dis as text _skip(3) "Number of control variables: " _c
		dis as result "`CtrlLen' "
		dis as text _skip(3) "Number of regressions: " _c
		local regNum = 0
		if "`threshold'" == "" {
			local regNum = `regNum' + `Lenth' - 1
		}
		if "`threshold'" != "" {
			forvalues i = 1/`Lenth' {
				if wordcount("`Combo`i''") >= `threshold' {
					local regNum = `regNum' + 1
				}
			}
		}
		dis as result "`regNum'"
		dis as text _skip(3) "Command: " _c
		if "`options'" == "" {
			dis as result "`method' `y' `fixvar' ctrls"
		}
		if "`options'" != "" {
			dis as result "`method' `y' `fixvar' ctrls, `options'"
		}
		display as text _n _dup(54) "_"
		dis as text "{bf:#2 oneclick progress bar:}"
		display as text  _dup(54) "-"
		
		* select
		timer clear 1
		timer on 1
		
		if "`threshold'" == "" {
			forvalues i = 1/`Lenth' {
				_dots `dotDisplay' 0
				quietly {
					capture `method' `y' `fixvar' `Combo`i'', `options'
					if _rc == 0 {
						local distribution_v = _b[`x']/_se[`x']
						if "`zvalue'" == "" & !missing(e(df_r)){
							local pv = 2 * ttail(e(df_r),abs(`distribution_v'))
						}
						if "`zvalue'" != ""{
							local pv = 2 * (1-normal(abs(`distribution_v')))
						}
						local ifsignificant = cond(`pv'<`pvalue',1,0)		
						replace subset = "`Combo`i''" in `i' if `ifsignificant'
						replace direction = 1 in `i' if `ifsignificant' & `distribution_v'>0
						replace direction = 0 in `i' if `ifsignificant' & `distribution_v'<0
						replace coef = _b[`x'] in `i' if `ifsignificant'
						replace p = "*" in `i' if `ifsignificant' & `pv' < 0.1 & `pv' > 0.05
						replace p = "**" in `i' if `ifsignificant' & `pv' < 0.05 & `pv' > 0.01
						replace p = "***" in `i' if `ifsignificant' & `pv' < 0.01
						replace r2 = e(r2) in `i' if `ifsignificant'
					}
					if _rc != 0 {
						replace subset = "(Error) `Combo`i''" in `i'
					}
				}
				local dotDisplay = `dotDisplay' + 1
			}			
		}
		if "`threshold'" != "" {
			forvalues i = 1/`Lenth' {
				_dots `dotDisplay' 0
				if wordcount("`Combo`i''") >= `threshold' {
					quietly {
						capture `method' `y' `fixvar' `Combo`i'', `options'
						if _rc == 0 {
							local distribution_v = _b[`x']/_se[`x']
							if "`zvalue'" == "" & !missing(e(df_r)){
								local pv = 2 * ttail(e(df_r),abs(`distribution_v'))
							}
							if "`zvalue'" != ""{
								local pv = 2 * (1-normal(abs(`distribution_v')))
							}
							local ifsignificant = cond(`pv'<`pvalue',1,0)			
							replace subset = "`Combo`i''" in `i' if `ifsignificant'
							replace direction = 1 in `i' if `ifsignificant' & `distribution_v'>0
							replace direction = 0 in `i' if `ifsignificant' & `distribution_v'<0
							replace coef = _b[`x'] in `i' if `ifsignificant'
							replace p = "*" in `i' if `ifsignificant' & `pv' < 0.1 & `pv' > 0.05
							replace p = "**" in `i' if `ifsignificant' & `pv' < 0.05 & `pv' > 0.01
							replace p = "***" in `i' if `ifsignificant' & `pv' < 0.01
							replace r2 = e(r2) in `i' if `ifsignificant'						
						}
						if _rc != 0 {
							replace subset = "(Error) `Combo`i''" in `i'
						}
					}				
				}
				local dotDisplay = `dotDisplay' + 1
			}
		}
		
		timer off 1
		qui timer list 1
		dis _newline "Time= " r(t1) " S"
		
		* drop
		display as text _n _dup(54) "_"
		dis as text "{bf:#3 oneclick result description:}"
		display as text  _dup(54) "-"
		quietly {
			drop if subset == ""
			keep subset direction coef p r2
			
			count if !strmatch(subset, "*Error*")
			local sigNum = r(N)
			drop if strmatch(subset, "*Error*")
			sum direction if direction == 1
			local positiveNum = r(N)
			sum direction if direction == 0
			local negativeNum = r(N)
			
			noisily dis as text _skip(3) "Significant groups: " _c
			noisily dis as result "`sigNum'"
			if `sigNum' == 0 {
				noisily dis as error "oneclick REALLY tried its best, but... (T_T)"
				error 1
			}
			noisily dis as text _skip(6) "Positive: " _c
			noisily dis as result "`positiveNum'"
			noisily dis as text _skip(6) "Negative: " _c
			noisily dis as result "`negativeNum'"
			
			noisily display as text _n _dup(54) "_"
			noisily dis as text "{bf:#4 oneclick storage path:}"
			noisily dis as text _dup(54) "-"
			
			*- best option
			if "`best'" != "" {
				sort r2
				local bestctrls = subset[`=_N']
			}
			
			*- full option
			if "`full'" != "" & "`options'" != "" {
				gen command = "`method' " + "`y' " + "`fixvar'" + subset + ", `options'"
				keep command direction coef p r2
				order command direction coef p r2
				label var command "regression command"
			}	
			if "`full'" != "" & "`options'" == "" {
				gen command = "`method' " + "`y' " + "`fixvar'" + subset
				keep command direction coef p r2
				order command direction coef p r2
				label var command "regression command"
			}
			if "`full'" == "" {
				keep subset direction coef p r2
				order subset direction coef p r2
				label var subset "subset of control variables"
			}
			
			label var direction "1=postive, 0=negative"
			label var coef "coefficient of independent variable"
			label var p "mysterious stars of significance"
			label var r2 "r-squared"
			
			if "`saveplace'" != "" {
				noisily dis as result "`c(pwd)'/`saveplace'"
				save "`saveplace'", replace
			}
			if "`saveplace'" == "" {
				noisily dis as result "`c(pwd)'/oneclick_subset.dta"
				save oneclick_subset.dta, replace
			}
			noisily display as text  _dup(54) "_"
		}

	restore
	
	if wordcount("`bestctrls'") != 0 {
		display as text _n _dup(54) "_"
		dis as text "{bf:#5 oneclick best regression:}"
		dis as text _dup(54) "-"
		if "`options'" == "" {
			dis as result "`method' `y' `fixvar'`bestctrls'"
		}
		if "`options'" != "" {
			dis as result "`method' `y' `fixvar'`bestctrls', `options'"
		}
		`method' `y' `fixvar' `bestctrls', `options'
	}
end



************************************************************************
*- Main function (old)
/*
	Although oneclick has undergone a major update, 
	it is still possible to use oneclick5 to reproduce 
	the functionality of previous versions.
*/
capture program drop oneclick5
program define oneclick5
	version 14
	
	syntax varlist(min=3 fv ts),			    ///
			Method(string)						///
			Pvalue(real)						///
			FIXvar(varlist fv ts)				///
			[									///
				Options(string)					///
				Zvalue							///
			]


	gettoken y ctrlvar : varlist
	gettoken x otherx : fixvar
	tokenize "`ctrlvar'"
	
	preserve
		qui gen subset = ""
		qui gen positive = .
		
		* computer combination
		local CtrlLen = wordcount("`ctrlvar'")
		local temp = ustrregexra("`ctrlvar'"," ","")
		local Lenth = 2^`CtrlLen'
		forvalues i = 1/`Lenth' {
			local Combo ""
			bin_transfer `i'
			forvalues j = 1/`CtrlLen' {
				if substr(r(binary),-`j',1) == "1" {
					local addword "``j''"
					local Combo "`Combo' `addword'"
				}
			}
			local Combo`i' = "`Combo'"
		}
		
		*- set obs num
		local n = _N
		if `Lenth' > `n' {
			qui set obs `Lenth'
		}
		if `Lenth' <= `n' {
			qui set obs `n'
		}
		
		local minutes = int(`Lenth'/300) + 1
		dis "This will probably take you up to `minutes' minutes"
		dis _newline(1) "The program is working:"
		
		* select
		timer clear 1
		timer on 1
		forvalues i = 1/`Lenth' {
			_dots `dotDisplay' 0

			quietly {
			
				`method' `y' `fixvar' `Combo`i'', `options'
			
				local distribution_v = _b[`x']/_se[`x']
				if "`zvalue'" == "" & !missing(e(df_r)){
					local pv = 2 * ttail(e(df_r),abs(`distribution_v'))
				}
				if "`zvalue'" != ""{
					local pv = 2 * (1-normal(abs(`distribution_v')))
				}

				local ifsignificant = cond(`pv'<`pvalue',1,0)
				
				replace subset = "`Combo`i''" in `i' if `ifsignificant'
				replace positive = 1 in `i' if `ifsignificant' & `distribution_v'>0
				replace positive = 0 in `i' if `ifsignificant' & `distribution_v'<0
			}
			
			local dotDisplay = `dotDisplay' + 1
		}
		timer off 1
		qui timer list 1
		dis _newline "Time=" r(t1) "S"
		
		* drop 
		quietly {
			drop if subset == ""
			keep subset positive
			save subset.dta, replace
			
			local totalNum = _N 
			sum positive if positive == 1
			local positiveNum = r(N)
			sum positive if positive == 0
			local negativeNum = r(N)
		}
			
		dis _newline(1) "A total of `totalNum' significant groups: `positiveNum' positive, `negativeNum' negative"
	restore
end


