*! version 2.0 10oct2025 G. Califano and R. Fabbricatore

program step3, eclass
version 15.1

if replay() {
	if "`e(cmd)'" != "step3" {
		error 301
	}
	if _by() {
		error 190
	}
	syntax [, rrr level(integer 95)]
       
	local oddsr ""
    if "`rrr'" != "" {
		local oddsr "eform(RRR)"
    }
	di _newline as text "STEP3: `e(analysis)' analysis" _newline _skip(53) as text "Number of obs = " as result %9.0gc `e(N)'
    ereturn display, `oddsr' level(`level')
	exit
}

syntax varlist(numeric fv) [if] [in], pr(string) LClass(string) [OUTcome bch id(varname) eqvar Base(integer 1) rrr level(integer 95) Detail]
marksample touse

if "`pr'" == "`lclass'" {
	di as err "{bf:pr} names = {bf:lclass} name; select a different name for {bf:lclass}"
	exit 110
}

local n_var = `:word count `varlist''
local n_var2 = `:word count `varlist''
if `n_var' > 1 &  "`bch'" != "" & "`outcome'" != "" {
	di as err "one outcome at a time with option {bf:bch}"
	exit 103
}

local varlist2 = "`varlist'"

if "`s(fvops)'" == "true" {
	local n_var = 0
	fvrevar `varlist'
	local varlist2 = "`r(varlist)'"
	foreach var of varlist `varlist2' {
		local ++n_var
	}
	if "`outcome'" != "" {
		fvrevar `varlist', list
		local depfv = "`r(varlist)'"
	}
}

if "`depfv'" != "" & `n_var2' > 1 & "`outcome'" != "" {
	di as err "one categorical outcome at a time"
	exit 103
}

local k = 0
foreach var of varlist `pr'* {
	local ++k
}

capture if `pr'0
if _rc == 100 {
	di as err "ensure that your first posterior variable is named {bf:`pr'1}"
	exit 103
}

if `base' > `k'| `base' < 1 {
	local base = 1
}

capture if `pr'`k'
if _rc == 111 {
	di as err "ensure {bf:`pr'*} only returns posterior probabilities"
	exit 103
}

local unequal = ""
local vareport = "Equal variance across classes assumed."
if "`eqvar'" == "" {
	local unequal = "lcinvariant(none)"
	local vareport = "Unequal variance across classes assumed."
}

local oddsr = ""
if "`rrr'" != "" {
    local oddsr = "eform(RRR)"
}

local cmd = "step3"

local vce = "robust"
if "`id'" != "" {
	local vce = "cluster `id'"
}

if "`id'" == "" {
	tempname id
	qui gen `id' = _n
}

tempvar max max2 class _step3_class_
tempname tabchange diagtab tabtot tchange coltot rowtot error dist_x D logit_modal invD change1 change2 change b V valab proportions chi2 df p

qui egen `max' = rowmax(`pr'*)

capture if `lclass'
if _rc == 111 {
	qui gen `lclass' = .
	label variable `lclass' "STEP3: Most likely membership class"
}
else {
	local lbl : variable label `lclass'
	if "`lbl'" == "STEP3: Most likely membership class" {
		qui replace `lclass' = .
		label variable `lclass' "STEP3: Most likely membership class"
	}
	else {
		di as err "variable {bf:`lclass'} already exists and was not created by {bf:step3}; cannot replace"
		exit 110
	}
}

forvalues c = 1/`k' {
	qui replace `lclass' = `c' if `max'==`pr'`c'
}

preserve

cap qui drop _merge

*** MATRIX D ***

local first = "1"
local second = ""
forvalues i = 1/`k' {
	if `i' > 1 {
		local second = "`second' \ `first'"
	}
	else {
		local second = "`first'"
	}
}
 
matrix `dist_x' = [`second']
forvalues t = 1/`k' {
	qui total `pr'`t'
	matrix `dist_x'[`t', 1] = e(b)
}

forvalues class = 1/`k' {
	tempvar prob_w_is`class'_given_y prob_x_is`class'_given_y
	qui gen `prob_w_is`class'_given_y' = cond(`lclass'==`class',1,0)
	qui gen `prob_x_is`class'_given_y' = `pr'`class'
}

forvalues t = 1/`k' {
	forvalues s = 1/`k' {
		tempvar temp_w`s'_x`t'
		qui gen `temp_w`s'_x`t'' = (`prob_x_is`t'_given_y')*(`prob_w_is`s'_given_y')
	}
}

local string = ""
forval i = 1/`k' {
	local string "`string'`i'"
	if `i' < `k' {
		local string "`string',"
    }
}

local result = ""
forval i = 1/`k' {
	local result "`result'`string'"
	if `i' < `k' {
		local result "`result'\\"
    }
}
 
matrix `D' = [`result']
forvalues t = 1/`k' {
	forvalues s = 1/`k' {
		qui total `temp_w`s'_x`t''
		matrix `D'[`t',`s'] = e(b)/`dist_x'[`t',1]
	}
}

matrix `logit_modal' = [`result']
forvalues x = 1/`k' {
	forvalues y = 1/`k' {
		matrix `logit_modal'[`y',`x'] = `D'[`y',`x']/`D'[`y',`base']
		matrix `logit_modal'[`y',`x'] = ln(`logit_modal'[`y',`x'])
		if `logit_modal'[`y',`x'] == . {
			matrix `logit_modal'[`y',`x'] = 0
		}
	}
}

*** ML ***

local constraints = ""
forvalues i = 1/`k' {
	forvalues j = 1/`k' {
		if inlist(`j',`base') continue
		local L_`i'`j' = `logit_modal'[`i',`j']
		local C_`i'`j'= "(`i': `j'.`lclass'<-_cons@`L_`i'`j'')"
		local constraints = "`constraints' `C_`i'`j''"
	}
}
 
mat `invD' = inv(`D')

if "`bch'" == "" {
	if "`outcome'" == "" {
		
		*** ML COVARIATE ANALYSIS ***
		
		di _newline as text "Performing ML estimation..."
		cap gsem `constraints' (Class <- `varlist') if `touse', lclass(Class `k', base(`base')) nocapslatent vce(`vce') startvalues(classpr `pr'*)
		if e(converged) != 1 {
			di as err "convergence not achieved" _newline "-try with option {bf:bch}"
			restore
			exit 430
		}
		qui estimates store __step3__ML
		local s3_obs = e(N)
		local s3_clust = e(N_clust)
		forval i = 1/`k' {
			tempvar CPP_2_`i'
			qui predict `CPP_2_`i'', classpost class(`i')
		}
		qui mean `pr'* 
		matrix `change1' = e(b)'
		qui mean `CPP_2_1'-`CPP_2_`k''
		mat `change2' = e(b)'
		mat `change'  = `change1'*100,`change2'*100,(`change2'-`change1')*100
		forval i = 1/`k' {
			local rown = "`rown' `i'"
		}
		mat rownames `change' = `rown'
		mat colnames `change' = "Step 1" "Step 3" "Change"
		qui egen `max2' = rowmax(`CPP_2_1'-`CPP_2_`k'')
		qui gen `_step3_class_' = .
		forvalues c = 1/`k' {
			qui replace `_step3_class_' = `c' if `max2' == `CPP_2_`c''
		}
		qui tab `lclass' `_step3_class_', matcell(`tabchange')
		mat `diagtab' = diag(vecdiag(`tabchange'))
		mat `tabtot' = `tabchange'-`diagtab'
		mat `tabtot' = `tabtot'*J(colsof(`tabtot'),1,1)
		mata : st_matrix("`tabtot'", colsum(st_matrix("`tabtot'")))
		mat `tchange' = (`tabtot',(`tabtot'[1,1]/r(N))*100)
		mat colnames `tchange' = n %
		local percent = `tchange'[1,2]
		scalar `error' = 0
		if `percent' > 20 {
			scalar `error'  = 1
		 }
		local coef = `k'*(`n_var'+1)
		ereturn clear
		qui est restore __step3__ML 
		mat `b' = e(b)
		mat `b' = `b'[1,1..`coef']
		mat `V' = e(V)
		mat `V' = `V'[1..`coef',1..`coef']
		local namesres = ""
		
		forval i = 1/`k' {
			foreach var of varlist `varlist2' {
				if `i' != `base' {
					local namesres = "`namesres' `i'.`lclass'"
				}
				else {
					local namesres = "`namesres' `i'b.`lclass'"
				}
			}
			if `i' != `base' {
				local namesres = "`namesres' `i'.`lclass'"
			}
			else {
				local namesres = "`namesres' `i'b.`lclass'"
			}
		}
		
		mat cole `b' = ""
		mat rowe `V' = ""
		mat cole `V' = ""	
		mat cole `b' = `namesres'
		mat rowe `V' = `namesres'
		mat cole `V' = `namesres'
		ereturn post `b' `V', e(`touse') prop(b V) obs(`s3_obs')
		local analysis = "ML covariate"
		local marginsnotok = "_ALL"
		ereturn local analysis `analysis'
		ereturn local marginsnotok `marginsnotok'
		ereturn matrix invD = `invD'
		ereturn matrix D = `D'
		ereturn scalar changed = `error'
		ereturn local cmd `cmd'
		
		di _newline as text "STEP3: Covariate analysis" _newline _newline as text "ML Multinomial logistic regression"_skip(19) as text "Number of obs = " as result %9.0gc `s3_obs'
		ereturn display, `oddsr' level(`level') noemptycells
		if `s3_obs' == `s3_clust' | `s3_clust' == . {
			di as text "Note: Robust std. err."
		}
		else {
			di as text "Note: Std. err. adjusted for " as result `s3_clust' as text " clusters in " as result "`id'" as text "."
		}
	}
	
	else {
		
		*** ML DISTAL OUTCOME ANALYSIS ***
		di _newline as text "Performing ML estimation..."
		if "`depfv'" == "" {
			cap gsem `constraints' (`varlist' <- ) if `touse', lclass(Class `k', base(`base')) nocapslatent vce(`vce')  startvalues(classpr `pr'*) `unequal'
			if e(converged) != 1 {
				di as err "convergence not achieved" _newline "-try with option {bf:bch}"
				restore
				exit 430
			}
			qui estimates store __step3__ML
			local s3_obs = e(N)
			local s3_clust = e(N_clust)
			forval i = 1/`k' {
				tempvar CPP_2_`i'
				qui predict `CPP_2_`i'', classpost class(`i')
			}
			
			qui mean `pr'* 
			matrix `change1' = e(b)'
			qui mean `CPP_2_1'-`CPP_2_`k''
			mat `change2' = e(b)'
			mat `change'  = `change1'*100,`change2'*100,(`change2'-`change1')*100
			forval i = 1/`k' {
				local rown = "`rown' `i'"
			}
			mat rownames `change' = `rown'
			mat colnames `change' = "Step 1" "Step 3" "Change"
			qui egen `max2' = rowmax(`CPP_2_1'-`CPP_2_`k'')
			qui gen `_step3_class_' = .
			forvalues c = 1/`k' {
				qui replace `_step3_class_' = `c' if `max2' == `CPP_2_`c''
			}
			qui tab `lclass' `_step3_class_', matcell(`tabchange')
			mat `diagtab' = diag(vecdiag(`tabchange'))
			mat `tabtot' = `tabchange'-`diagtab'
			mat `tabtot' = `tabtot'*J(colsof(`tabtot'),1,1)
			mata : st_matrix("`tabtot'", colsum(st_matrix("`tabtot'")))
			mat `tchange' = (`tabtot',(`tabtot'[1,1]/r(N))*100)
			mat colnames `tchange' = n %
			local percent = `tchange'[1,2]
			scalar `error' = 0
			if `percent' > 20 {
				scalar `error'  = 1
			 }
			 
			qui est restore __step3__ML
			
			local namesres = ""
			foreach var of varlist `varlist' {
				forval i = 1/`k' {
					local namesres = "`namesres' `var':`i'.`lclass'"
					local namesresvar = "`namesresvar' sigma2:`var'#`i'.`lclass'"
				}	
			}
		
			local coefs = `k'^2+`k'+1
			ereturn clear
			qui est restore __step3__ML
			mat `b' = e(b)
			mat `b' = `b'[1,`coefs'...]
			mat `V' = e(V)
			mat `V' = `V'[`coefs'...,`coefs'...]
			mat cole `b' = ""
			mat rowe `V' = ""
			mat cole `V' = ""
			mat coln `b' = `namesres' `namesresvar'
			mat rown `V' = `namesres' `namesresvar'
			mat coln `V' = `namesres' `namesresvar'
			
			ereturn post `b' `V', buildfv e(`touse') prop(b V) obs(`s3_obs')
			if "`eqvar'" == "" {
				local variance = "Unequal across classes"
				ereturn local variance `variance'
			}
			else {
				local variance = "Equal across classes"
				ereturn local variance `variance'
			}
			local analysis = "ML distal outcome"
			ereturn local analysis `analysis'
			ereturn matrix invD = `invD'
			ereturn matrix D = `D'
			ereturn scalar changed = `error'
			ereturn local cmd `cmd'
			
			di _newline as text "STEP3: Distal outcome analysis" _newline _newline as text "ML Mean estimation"_skip(19) as text "Number of obs = " as result %9.0gc `s3_obs'
			ereturn display, nopv level(`level')
			
			if `s3_obs' == `s3_clust' | `s3_clust' == . {
				di as text "Note: Robust std. err." _newline _skip(6) "`vareport'"
			}
			else {
				di as text "Note: Std. err. adjusted for " as result `s3_clust' as text " clusters in " as result "`id'" as text "." _newline _skip(6) "`vareport'"
			}
		}

		if "`depfv'" != "" {
			cap gsem `constraints' (ib`base'.`depfv' <- ) if `touse', lclass(Class `k') nocapslatent vce(`vce')  startvalues(classpr `pr'*) `unequal'
			if e(converged) != 1 {
				di as err "convergence not achieved" _newline "-try with option {bf:bch}"
				restore
				exit 430
			}
			qui estimates store __step3__ML
			local s3_obs = e(N)
			local s3_clust = e(N_clust)
			forval i = 1/`k' {
				tempvar CPP_2_`i'
				qui predict `CPP_2_`i'', classpost class(`i')
			}
			qui mean `pr'* 
			matrix `change1' = e(b)'
			qui mean `CPP_2_1'-`CPP_2_`k''
			mat `change2' = e(b)'
			mat `change'  = `change1'*100,`change2'*100,(`change2'-`change1')*100
			forval i = 1/`k' {
				local rown = "`rown' `i'"
			}
			mat rownames `change' = `rown'
			mat colnames `change' = "Step 1" "Step 3" "Change"
			qui egen `max2' = rowmax(`CPP_2_1'-`CPP_2_`k'')
			qui gen `_step3_class_' = .
			forvalues c = 1/`k' {
				qui replace `_step3_class_' = `c' if `max2' == `CPP_2_`c''
			}
			qui tab `lclass' `_step3_class_', matcell(`tabchange')
			mat `diagtab' = diag(vecdiag(`tabchange'))
			mat `tabtot' = `tabchange'-`diagtab'
			mat `tabtot' = `tabtot'*J(colsof(`tabtot'),1,1)
			mata : st_matrix("`tabtot'", colsum(st_matrix("`tabtot'")))
			mat `tchange' = (`tabtot',(`tabtot'[1,1]/r(N))*100)
			mat colnames `tchange' = n %
			local percent = `tchange'[1,2]
			scalar `error' = 0
			if `percent' > 20 {
				scalar `error'  = 1
			 }
			 
			local coefs = `k'^2+`k'+1
			qui est restore __step3__ML
			mat `b' = e(b)
			mat `b' = `b'[1,`coefs'...]
			mat `V' = e(V)
			mat `V' = `V'[`coefs'...,`coefs'...]
			
			local nameres = ""
			forval i = 1/`n_var' {
				forval j = 1/`k' {
					if `i' != `base' {
						local namesres = "`namesres' `j'.`lclass'"
					}
					else {
						local namesres = "`namesres' `i'o.`lclass'"
					}
				}
			}	
			
			mat coln `b' = `namesres'
			mat rown `V' = `namesres'
			mat coln `V' = `namesres'
			ereturn post `b' `V', buildfv e(`touse') prop(b V) obs(`s3_obs')
			local analysis = "ML distal outcome"
			ereturn local analysis `analysis'
			ereturn matrix invD = `invD'
			ereturn matrix D = `D'
			ereturn scalar changed = `error'
			ereturn local cmd `cmd'
			
			di _newline as text "STEP3: Distal outcome analysis" _newline _newline as text "ML Multinomial logistic regression"_skip(19) as text "Number of obs = " as result %9.0gc `s3_obs'
			ereturn display, `oddsr' level(`level') noemptycells
			
			if `s3_obs' == `s3_clust' | `s3_clust' == . {
				di as text "Note: Robust std. err."
			}
			else {
				di as text "Note: Std. err. adjusted for " as result `s3_clust' as text " clusters in " as result "`id'" as text "."
			}
			qui contrast `lclass', ateq overall noestimcheck
			local target = `n_var'+1
			mat `chi2' = r(chi2)
			mat `df' = r(df)
			mat `p' = r(p)
			local cchi2 : di %6.3f `chi2'[1,`target']
			local cdf = `df'[1,`target']
			local cp : di %6.3f `p'[1,`target']
			di _newline as text "Wald test: chi2(" as result "`cdf'" as text ") = " as result "`cchi2'" as text "; {it:p} = " as result "`cp'"	
		}
	}
}
*** BCH ***

else {
	forval col = 1/`k' {
		qui gen __bch_weight`col' = .
		forval row = 1/`k' {
			qui replace __bch_weight`col' = `invD'[`row',`col'] if `lclass' == `row'
		}
	}
	qui keep if `touse'
	tempvar id2
	qui gen `id2' = _n
	cap qui reshape long __bch_weight, i(`id2') j(__lclass_bch)
	qui svyset `id' [iw=__bch_weight], strata(`lclass')
	
	if "`outcome'" == "" {
		
		*** BCH COVARIATE ANALYSIS ***
		
		qui svy: mlogit __lclass_bch `varlist', base(`base')
		qui estimates store __step3__BCH
		
		local obs = e(N)/`k'
		local clus = e(N_psu)
		local namesres = ""
		
		mat `b' = e(b)
		mat `V' = e(V)
		
		forval i = 1/`k' {		
			foreach var of varlist `varlist2' {
				if `i' != `base' {
					local namesres = "`namesres' `i'.`lclass'"
				}
				else {
					local namesres = "`namesres' `i'b.`lclass'"
				}
			}
			if `i' != `base' {
				local namesres = "`namesres' `i'.`lclass'"
			}
			else {
				local namesres = "`namesres' `i'b.`lclass'"
			}
		}
		
		mat cole `b' = ""
		mat rowe `V' = ""
		mat cole `V' = ""	
		mat cole `b' = `namesres'
		mat rowe `V' = `namesres'
		mat cole `V' = `namesres'
		ereturn post `b' `V', e(`touse') prop(b V) obs(`obs')
		local analysis = "BCH covariate"
		local marginsnotok = "_ALL"
		ereturn local analysis `analysis'
		ereturn local marginsnotok `marginsnotok'
		ereturn matrix invD = `invD'
		ereturn matrix D = `D'
		ereturn local cmd `cmd'
		
		di _newline as text "STEP3: Covariate analysis" _newline _newline as text "BCH Multinomial logistic regression"_skip(18) as text "Number of obs = " as result %9.0gc `obs'
		ereturn display, `oddsr' level(`level') noemptycells
		if `obs' == `clus' {
			di as text "Note: Linearized std. err."
		}
		else {
			di as text "Note: Linearized std. err. adjusted for " as result `clus' as text " clusters in " as result "`id'" as text "."
		}
	}	
	else {
		
		*** BCH DISTAL OUTCOME ANALYSIS ***
		
		if "`depfv'" != "" {
			qui svy: mlogit `depfv' ibn.__lclass_bch, noconstant base(`base')
			qui est store __step3__BCH
			local obs = e(N)/`k'
			local clus = e(N_psu)
			mat `b' = e(b)
			mat `V' = e(V)
			
			local nameres = ""
			local nameq = ""
			forval i = 1/`n_var' {
				forval j = 1/`k' {
					if `i' != `base' {
						local nameq = "`nameq' `i'.`depfv':"
						local namesres = "`namesres' `j'.`lclass'"
					}
					else {
						local nameq = "`nameq' `i'b.`depfv':"
						local namesres = "`namesres' `i'o.`lclass'"
					}
				}
			}	
			
			mat coleq `b' = `nameq'
			mat coln `b' = `namesres'
			mat roweq `V' = `nameq'
			mat coleq `V' = `nameq'
			mat rown `V' = `namesres'
			mat coln `V' = `namesres'
			ereturn post `b' `V', buildfv e(`touse') prop(b V) obs(`obs')
			local analysis = "BCH distal outcome"
			ereturn local analysis `analysis'
			ereturn matrix invD = `invD'
			ereturn matrix D = `D'
			ereturn local cmd `cmd'
			
			di _newline as text "STEP3: Distal outcome analysis" _newline _newline as text "BCH Multinomial logistic regression" _skip(18) as text "Number of obs = " as result %9.0gc `obs'
			ereturn display, `oddsr' level(`level') noemptycells
			if `obs' == `clus' {
				di as text "Note: Linearized std. err."
			}
			else {
				di as text "Note: Linearized std. err. adjusted for " as result `clus' as text " clusters in " as result "`id'" as text "."
			}
			qui contrast `lclass', ateq overall noestimcheck
			local target = `n_var'+1
			mat `chi2' = r(chi2)
			mat `df' = r(df)
			mat `p' = r(p)
			local cchi2 : di %6.3f `chi2'[1,`target']
			local cdf = `df'[1,`target']
			local cp : di %6.3f `p'[1,`target']
			di _newline as text "Wald test: chi2(" as result "`cdf'" as text ") = " as result "`cchi2'" as text "; {it:p} = " as result "`cp'"	
		}
		else {
			qui svy: reg `varlist' ibn.__lclass_bch, nocons
			qui est store __step3__BCH
			local obs = e(N)/`k'
			local clus = e(N_psu)
			local namesres = ""
			forval i = 1/`k' {
				local namesres = "`namesres' `varlist':`i'.`lclass'"
			}	
			
			mat `b' = e(b)
			mat `V' = e(V)
			mat cole `b' = ""
			mat rowe `V' = ""
			mat cole `V' = ""	
			mat coln `b' = `namesres'
			mat rown `V' = `namesres'
			mat coln `V' = `namesres'
			ereturn post `b' `V', buildfv e(`touse') prop(b V) obs(`obs')
			local analysis = "BCH distal outcome"
			ereturn local analysis `analysis'
			ereturn matrix invD = `invD'
			ereturn matrix D = `D'
			ereturn local cmd `cmd'
			
			di _newline as text "STEP3: Distal outcome analysis" _newline _newline as text "BCH Mean estimation" _skip(18) as text "Number of obs = " as result %9.0gc `obs'

			ereturn display, nopv level(`level')
			if `obs' == `clus' {
				di as text "Note: Linearized std. err."
			}
			else {
				di as text "Note: Linearized std. err. adjusted for " as result `clus' as text " clusters in " as result "`id'" as text "."
			}
		}
	}
}
	
*** CHANGE MATRIX ***

if "`detail'" != "" | e(changed) == 1 {
	if "`bch'" == "" {
		matlist `change', noheader title("Class composition (%) before and after Step 3") rowtitle("Class") format(%10.2f) border(t b) lines(coltotal)
		matlist `tchange', noheader title("Observations in Step 1 class moved to a different class in Step 3") format(%10.0f) border name(c)
		di as text "Note: results might be inconsistent for % > 20"
		if e(changed) == 1 {
			di _newline as err "warning: the latent class composition has likely changed" _newline as err "-results might be inconsistent; try with option {bf:bch}"
		}
	}
}

restore
end
