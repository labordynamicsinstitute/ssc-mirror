*! version 1.0.0 08aug2022 


cap program drop rrp
program define rrp, eclass                                                                                    
version 8

syntax varlist(numeric ts fv) [if] [in] [aweight pweight fweight iweight] ///
       [, IMPUTE(string) PROXIES(varlist numeric ts fv) FIRST(string) PARTIALRSQ(string) Robust CLuster(varlist)]
marksample touse

tempname sigma1 Rsq1 sigma2 Rsq2 n1 n2 Z1X XX ZX XZ ZZ beta gamma Vb Vg V F Fdf1 Fdf2 Fp coef vars varcols ProxyMat ProxyNames VarMat VarNames

qui matrix accum `VarMat' =  `varlist'  if `touse' , nocons
local VarNames : colfullnames `VarMat'

qui matrix accum `ProxyMat' =  `proxies'  if `touse' , nocons
local ProxyNames : colfullnames `ProxyMat'


foreach var in `ProxyNames' {
	if strpos("`VarNames'","`var'") {
		dis as error "Variable `var' cannot be included as proxy and as second-stage covariate."
		exit 498
	}
}



scalar `Rsq1'   = `partialrsq'
qui est restore `first'
scalar `sigma1' = e(rmse)
scalar `n1'     = e(N)
mat `coef'      = e(b)
mat `vars'      = e(V)

foreach var in `ProxyNames' {
	if colnumb(`coef',"`var'")==. {
		dis as error "Proxy `var' not found in first-stage model."
		dis as error "Check that all proxy variables have the same name at both stages."
		exit
	}
}

foreach var in `ProxyNames' {
	mat `gamma'   = nullmat(`gamma'),`coef'[1,"`var'"]
	mat `varcols' = nullmat(`varcols'),`vars'[.,"`var'"]
}
foreach var in `ProxyNames' {
	mat `Vg'    = nullmat(`Vg')\ `varcols'["`var'",.]
}

matrix score double `impute' = `coef' if `touse'
qui replace `impute'         = `impute'/`Rsq1'


if "`robust'" != "" {
	qui reg `impute' `varlist'  if `touse', robust
	mat `Vb'   = e(V)
	local vce                   "robust"
	local vcetype               "Robust"
}
else if "`cluster'" != "" {
	qui reg `impute' `varlist'  if `touse', cluster(`cluster')
	mat `Vb'       = e(V)
	local vce       "cluster"
	local vcetype   "Robust"
	local clustvar  "`cluster'"
	local n2_clust = e(N_clust)
}
else {
	qui reg `impute' `varlist'  if `touse'
	mat `Vb'   = e(V)
}


mat    `beta'   = e(b)
scalar `sigma2' = e(rmse)
scalar `n2'     = e(N)
scalar `Rsq2'   = e(r2)

qui testparm `varlist' 
scalar `F'    = r(F)
scalar `Fdf1' = r(df)
scalar `Fdf2' = r(df_r)
scalar `Fp'   = r(p)

qui matrix accum `Z1X' =  `proxies'  `varlist'  if `touse'
local p  = colsof(`gamma')
local v  = colsof(`Z1X')-`p'
local p1 = `p'+1
local pv = `p'+`v'


mat `ZZ' = `Z1X'[1..`p', 1..`p']
mat `XX' = `Z1X'[`p1'..`pv', `p1'..`pv']
mat `XZ' = `Z1X'[`p1'..`pv',1.. `p']
mat `ZX' = `XZ''
mat `V'  = `Vb' + (`n2'/`n1')*syminv(`XX')*`XZ'*`Vg'*`ZX'*syminv(`XX')/`Rsq1'/`Rsq1'


cap drop _est_*
ereturn post `beta' `V' , esample(`touse') buildfvinfo
ereturn local vce        "`vce'"
ereturn local vcetype    "`vcetype'"
ereturn local clustvar   "`clustvar'"
ereturn local title      "Rescaled regression prediction"
ereturn local cmdline    `"rrp `0'"'
ereturn local depvar     "`impute'"
ereturn local cmd        "rrp"
if ("`cluster'" != "") ereturn scalar N_clust = `n2_clust'
ereturn scalar N    = `n2'
ereturn scalar df_m = `Fdf1'
ereturn scalar df_r = `Fdf2'
ereturn scalar F    = `F'
ereturn scalar r2   = `Rsq2'
ereturn scalar rmse = `sigma2'
ereturn scalar rank = `v'


dis ""
dis "Rescaled regression prediction"
di in gr _col(55) "Number of obs = " in ye %8.0fc `n2' 
di in gr _col(55) "F(" `Fdf1' ", " `Fdf2' ")     = " in ye %8.2f `F' 
di in gr _col(55) "Prob > F      = " in ye %8.4f `Fp'
di in gr _col(55) "R2            = " in ye %8.4f `Rsq2'
di in gr _col(55) "Root MSE      = " in ye %8.4f `sigma2'
ereturn display, level(95)
end



