*! version 1.0.1  04dec2023  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

** changes: 
** tau_t,norm --> tau_u
** output: CBPS --> logit CB
** output: logit --> logit ML
** output: probit --> probit ML

capture program drop kappalate
program define kappalate, eclass
	version 17
	syntax anything [if] [in] [, zmodel(string) vce(string) std(string) which(string)]
	
	// parse
	_iv_parse `0'
	local cmd `cmd'
	local yvar `s(lhs)'
	local tvar `s(endog)'
	local xvarsips `s(exog)'
	local zvar `s(inst)'
	local zero `s(zero)'
	
	sreturn clear
	
	// mark sample
	marksample touse
	markout `touse' `yvar' `zvar' `tvar' `xvarsips', strok
	
	// assign default values to options that were not set
	if "`zmodel'"=="" {
		local zmodel cbps
	}
	
	if "`vce'"=="" {
		local vce robust
	}
	
	if "`std'"=="" {
		local std on
	}
	
	if "`which'"=="" {
		local which norm
	}
	
	// check some conditions on the inputs
	if "`zmodel'"!="cbps" & "`zmodel'"!="logit" & "`zmodel'"!="probit" {
		noi di as error "zmodel(`zmodel') not allowed"
		error 198
		exit
	}
	
	if "`std'"!="on" & "`std'"!="off" {
		noi di as error "std(`std') not allowed"
		error 198
		exit
	}
	
	if "`which'"!="norm" & "`which'"!="all" {
		noi di as error "which(`which') not allowed"
		error 198
		exit
	}
	
	qui tab `tvar' if `touse'
	if r(r)!=2 {
		noi di as error "treatment must be binary"
		error 450
		exit
	}
	
	qui sum `tvar' if `touse'
	if r(min)!=0 | r(max)!=1 {
		noi di as error "treatment must only take on values zero or one"
		error 450
		exit
	}
	
	qui tab `zvar' if `touse'
	if r(r)!=2 {
		noi di as error "instrument must be binary"
		error 450
		exit
	}
	
	qui sum `zvar' if `touse'
	if r(min)!=0 | r(max)!=1 {
		noi di as error "instrument must only take on values zero or one"
		error 450
		exit
	}
	
	// standardize the non-binary variables
	if "`std'"=="on" {
		foreach x in `xvarsips' {
			tempvar `x'_ips_st
			qui tab `x' if `touse'
			if r(r)!=2 {
				egen double ``x'_ips_st' = std(`x')
			}
			else {
				gen double ``x'_ips_st' = `x'
			}
		}
		
		local xvarsips_STD
		foreach item in `xvarsips' {
			local xvarsips_STD `xvarsips_STD' ``item'_ips_st'
		}
		
		local xvarsips "`xvarsips_STD'"
	}
	
	// declare tempvars and tempnames
	tempvar ips ipsxb1 ipsxb2 numhat kappaw kappa_0 kappa_1 num1hat num0hat y1hat y0hat d1hat d0hat
	tempname dmeanz1 dmeanz0 bips bips1 bips2 starting initial I nums kappa_1s kappa_0s kappas late_a late_a1 late_a0 num1hats num0hats late_a10 by1 by0 bd1 bd0 denom1s denom0s num1s num0s num_norms denom_norms late_norm
	
	// examine compliance with the instrument
	qui sum `tvar' if `zvar'==1 & `touse'==1
	scalar `dmeanz1' = r(mean)
	qui sum `tvar' if `zvar'==0 & `touse'==1
	scalar `dmeanz0' = r(mean)
	
	if `dmeanz0'==`dmeanz1' {
		noi di as error "zero denominator: LATE not defined"
		error 459
		exit
	}
	
	else if `dmeanz1'==1 & `dmeanz0'==0 {
		noi di as error "instrument identical to treatment"
		error 459
		exit
	}
	
	else if `dmeanz1'==0 & `dmeanz0'==1 {
		noi di as error "instrument identical to treatment"
		error 459
		exit
	}
	
	// main estimation procedure
	quietly {
		// estimation of the instrument propensity score
		if "`zmodel'"!="cbps" {
			`zmodel' `zvar' `xvarsips' if `touse'==1
			matrix `bips' = e(b)
			predict double `ips'
		}
		else {
			// determine starting values from logit
			logit `zvar' `xvarsips' if `touse'==1
			matrix `starting' = e(b)
			
			// moment function
			local eqips (eqips: (`zvar' - exp({zhat: `xvarsips' _cons})/(1+exp({zhat:})))/((exp({zhat:})/(1+exp({zhat:})))*(1/(1+exp({zhat:})))))
			local eqips_inst instruments(eqips: `xvarsips')
			matrix `initial' = `starting'
			local k = colsof(`initial')
			matrix `I' = I(`k')
			
			// GMM estimation
			capture gmm `eqips' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce')
			matrix `bips1' = e(b)
			predict double `ipsxb1'
			
			if e(converged)==1 {
				matrix `bips' = `bips1'
				gen double `ips' = logistic(`ipsxb1')
			}
			else {
				capture gmm `eqips' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') technique(nr)
				matrix `bips2' = e(b)
				predict double `ipsxb2'
				
				if e(converged)==1 {
					matrix `bips' = `bips2'
					gen double `ips' = logistic(`ipsxb2')
				}
				else {
					matrix `bips' = `bips1'
					gen double `ips' = logistic(`ipsxb1')
					noi di as error "convergence not achieved for CBPS estimation"
				}
			}
		}
		
		// estimation of the LATE
		gen double `numhat' = ((`zvar')/`ips')*`yvar'-(((1-`zvar'))/(1-`ips'))*`yvar' if `touse'==1
		gen double `kappa_1' = ((`zvar')/`ips')*`tvar'-(((1-`zvar'))/(1-`ips'))*`tvar' if `touse'==1
		gen double `kappa_0' = (1-`tvar')*((1-`zvar')-(1-`ips'))/(`ips'*(1-`ips')) if `touse'==1
		gen double `kappaw' = 1-(`tvar'*(1-`zvar'))/(1-`ips')-((1-`tvar')*`zvar')/`ips' if `touse'==1
		gen double `num1hat' = `kappa_1'*`yvar' if `touse'==1
		gen double `num0hat' = `kappa_0'*`yvar' if `touse'==1
		
		sum `numhat' if `touse'==1
		matrix `nums' = r(mean)
		
		sum `kappa_1' if `touse'==1
		matrix `kappa_1s' = r(mean)
		
		sum `kappa_0' if `touse'==1
		matrix `kappa_0s' = r(mean)
		
		sum `kappaw' if `touse'==1
		matrix `kappas' = r(mean)
		
		sum `num1hat' if `touse'==1
		matrix `num1hats' = r(mean)
		
		sum `num0hat' if `touse'==1
		matrix `num0hats' = r(mean)
		
		matrix `late_a' = `nums'*inv(`kappas')
		matrix `late_a1' = `nums'*inv(`kappa_1s')
		matrix `late_a0' = `nums'*inv(`kappa_0s')
		matrix `late_a10' = `num1hats'*inv(`kappa_1s')-`num0hats'*inv(`kappa_0s')
		
		matrix list `late_a'
		matrix list `late_a1'
		matrix list `late_a0'
		matrix list `late_a10'
		
		regress `yvar' if `zvar'==1 & `touse'==1 [pw = 1/`ips']
		matrix `by1' = e(b)
		predict double `y1hat'
		
		regress `yvar' if `zvar'==0 & `touse'==1 [pw = 1/(1-`ips')]
		matrix `by0' = e(b)
		predict double `y0hat'
		
		if `dmeanz1'==1 {
			gen double `d1hat' = 1
		}
		else if `dmeanz1'==0 {
			gen double `d1hat' = 0
		}
		else {
			regress `tvar' if `zvar'==1 & `touse'==1 [pw = 1/`ips']
			matrix `bd1' = e(b)
			predict double `d1hat'
		}
		
		if `dmeanz0'==0 {
			gen double `d0hat' = 0
		}
		else if `dmeanz0'==1 {
			gen double `d0hat' = 1
		}
		else {
			regress `tvar' if `zvar'==0 & `touse'==1 [pw = 1/(1-`ips')]
			matrix `bd0' = e(b)
			predict double `d0hat'
		}
		
		sum `d1hat' if `touse'==1
		matrix `denom1s' = r(mean)
		
		sum `d0hat' if `touse'==1
		matrix `denom0s' = r(mean)
		
		sum `y1hat' if `touse'==1
		matrix `num1s' = r(mean)
		
		sum `y0hat' if `touse'==1
		matrix `num0s' = r(mean)
		
		matrix `num_norms' = `num1s'-`num0s'
		matrix `denom_norms' = `denom1s'-`denom0s'
		matrix `late_norm' = `num_norms'*inv(`denom_norms')
		matrix list `late_norm'
		
		// moment conditions
		if "`zmodel'"=="logit" {
			local eqips (eqips: `zvar' - exp({zhat: `xvarsips' _cons})/(1+exp({zhat:})))
			local eqips_inst instruments(eqips: `xvarsips')
		}
		else if "`zmodel'"=="probit" {
			local eqips (eqips: ((`zvar' - normal({zhat: `xvarsips' _cons}))/(normal({zhat:})*(1-normal({zhat:}))))*normalden({zhat:}))
			local eqips_inst instruments(eqips: `xvarsips')
		}
		else if "`zmodel'"=="cbps" {
			local eqips (eqips: (`zvar' - exp({zhat: `xvarsips' _cons})/(1+exp({zhat:})))/((exp({zhat:})/(1+exp({zhat:})))*(1/(1+exp({zhat:})))))
			local eqips_inst instruments(eqips: `xvarsips')
		}
		
		// other moments
		// psi_delta
		local eq_delta (eq_delta: ((`zvar'*`yvar')/(exp({zhat:})/(1+exp({zhat:})))-((1-`zvar')*`yvar')/(1-(exp({zhat:})/(1+exp({zhat:}))))-{deltap}))
		local eq_delta_inst instruments(eq_delta: )
		// psi_gamma
		local eq_gamma (eq_gamma: (1-((1-`zvar')*`tvar')/(1-(exp({zhat:})/(1+exp({zhat:}))))-(`zvar'*(1-`tvar'))/(exp({zhat:})/(1+exp({zhat:})))-{gammap}))
		local eq_gamma_inst instruments(eq_gamma: )
		// psi_gamma1
		local eq_gamma1 (eq_gamma1: ((`zvar'*`tvar')/(exp({zhat:})/(1+exp({zhat:})))-((1-`zvar')*`tvar')/(1-(exp({zhat:})/(1+exp({zhat:}))))-{gamma1}))
		local eq_gamma1_inst instruments(eq_gamma1: )
		// psi_gamma0
		local eq_gamma0 (eq_gamma0: ((`zvar'*(`tvar'-1))/(exp({zhat:})/(1+exp({zhat:})))-((1-`zvar')*(`tvar'-1))/(1-(exp({zhat:})/(1+exp({zhat:}))))-{gamma0}))
		local eq_gamma0_inst instruments(eq_gamma0: )
		// psi_delta1
		local eq_delta1 (eq_delta1: (`tvar'*((`zvar'-(exp({zhat:})/(1+exp({zhat:}))))/((exp({zhat:})/(1+exp({zhat:})))*(1-(exp({zhat:})/(1+exp({zhat:}))))))*`yvar'-{delta1}))
		local eq_delta1_inst instruments(eq_delta1: )
		// psi_delta0
		local eq_delta0 (eq_delta0: ((1-`tvar')*(((1-`zvar')-(1-(exp({zhat:})/(1+exp({zhat:})))))/((exp({zhat:})/(1+exp({zhat:})))*(1-(exp({zhat:})/(1+exp({zhat:}))))))*`yvar'-{delta0}))
		local eq_delta0_inst instruments(eq_delta0: )
		// psi_mu1
		local eq_mu1 (eq_mu1: ((`zvar'*(`yvar'-{mu1}))/(exp({zhat:})/(1+exp({zhat:})))))
		local eq_mu1_inst instruments(eq_mu1: )
		// psi_mu0
		local eq_mu0 (eq_mu0: (((1-`zvar')*(`yvar'-{mu0}))/(1-(exp({zhat:})/(1+exp({zhat:}))))))
		local eq_mu0_inst instruments(eq_mu0: )
		// psi_m1
		local eq_m1 (eq_m1: ((`zvar'*(`tvar'-{m1}))/(exp({zhat:})/(1+exp({zhat:})))))
		local eq_m1_inst instruments(eq_m1: )
		// psi_m0
		local eq_m0 (eq_m0: (((1-`zvar')*(`tvar'-{m0}))/(1-(exp({zhat:})/(1+exp({zhat:}))))))
		local eq_m0_inst instruments(eq_m0: )
		// psi_taua
		local eq_tau_a (eq_tau_a: ({tau_a} - {deltap}/{gammap}))
		// psi_taua1
		local eq_tau_a1 (eq_tau_a1: ({tau_a1} - {deltap}/{gamma1}))
		// psi_taua0
		local eq_tau_a0 (eq_tau_a0: ({tau_a0} - {deltap}/{gamma0}))
		// psi_taua10
		local eq_tau_a10 (eq_tau_a10: ({tau_a10} - ({delta1}/{gamma1}-{delta0}/{gamma0})))
		// psi_taunorm
		if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
			local eq_tau_norm (eq_tau_norm: ({tau_norm} - (({mu1}-{mu0})/({m1}-{m0}))))
		}
		else if `dmeanz0'==0 & `dmeanz1'!=0 & `dmeanz1'!=1 {
			local eq_tau_norm (eq_tau_norm: ({tau_norm} - (({mu1}-{mu0})/({m1}))))
		}
		else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'==1 {
			local eq_tau_norm (eq_tau_norm: ({tau_norm} - (({mu1}-{mu0})/(1-{m0}))))
		}
		else if `dmeanz0'==1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
			local eq_tau_norm (eq_tau_norm: ({tau_norm} - (({mu1}-{mu0})/({m1}-1))))
		}
		else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'==0 {
			local eq_tau_norm (eq_tau_norm: ({tau_norm} - (({mu1}-{mu0})/(-{m0}))))
		}
		
		// declare further tempnames
		tempname N tau_a vc_tau_a r_tau_a var_tau_a tau_a1 vc_tau_a1 r_tau_a1 var_tau_a1 tau_a0 vc_tau_a0 r_tau_a0 var_tau_a0
		tempname tau_norm vc_tau_norm r_tau_norm var_tau_norm tau_a10 vc_tau_a10 r_tau_a10 var_tau_a10
		
		// estimation of the LATE
		// tau_a
		matrix `initial' = (`bips', `nums', `kappas', `late_a')
		local k = colsof(`initial')
		matrix `I' = I(`k')
		gmm `eqips' `eq_delta' `eq_gamma' `eq_tau_a' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		scalar `tau_a' = _b[tau_a:_cons]
		matrix `vc_tau_a' = e(V)
		scalar `r_tau_a' = rownumb(`vc_tau_a', "tau_a:_cons")
		scalar `var_tau_a' = `vc_tau_a'[`r_tau_a', `r_tau_a']

		// tau_a1
		matrix `initial' = (`bips', `nums', `kappa_1s', `late_a1')
		local k = colsof(`initial')
		matrix `I' = I(`k')
		gmm `eqips' `eq_delta' `eq_gamma1' `eq_tau_a1' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		scalar `tau_a1' = _b[tau_a1:_cons]
		matrix `vc_tau_a1' = e(V)
		scalar `r_tau_a1' = rownumb(`vc_tau_a1', "tau_a1:_cons")
		scalar `var_tau_a1' = `vc_tau_a1'[`r_tau_a1', `r_tau_a1']
		
		// tau_a0
		matrix `initial' = (`bips', `nums', `kappa_0s', `late_a0')
		local k = colsof(`initial')
		matrix `I' = I(`k')
		gmm `eqips' `eq_delta' `eq_gamma0' `eq_tau_a0' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		scalar `tau_a0' = _b[tau_a0:_cons]
		matrix `vc_tau_a0' = e(V)
		scalar `r_tau_a0' = rownumb(`vc_tau_a0', "tau_a0:_cons")
		scalar `var_tau_a0' = `vc_tau_a0'[`r_tau_a0', `r_tau_a0']

		// tau_a10
		matrix `initial' = (`bips', `num1hats', `kappa_1s', `num0hats', `kappa_0s', `late_a10')
		local k = colsof(`initial')
		matrix `I' = I(`k')
		gmm `eqips' `eq_delta1' `eq_gamma1' `eq_delta0' `eq_gamma0' `eq_tau_a10' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		scalar `tau_a10' = _b[tau_a10:_cons]
		matrix `vc_tau_a10' = e(V)
		scalar `r_tau_a10' = rownumb(`vc_tau_a10', "tau_a10:_cons")
		scalar `var_tau_a10' = `vc_tau_a10'[`r_tau_a10', `r_tau_a10']
		
		// tau_norm
		if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
			matrix `initial' = (`bips', `num1s', `num0s', `denom1s', `denom0s', `late_norm')
			local k = colsof(`initial')
			matrix `I' = I(`k')
			gmm `eqips' `eq_mu1' `eq_mu0' `eq_m1' `eq_m0' `eq_tau_norm' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		}
		else if `dmeanz0'==0 | `dmeanz0'==1 {
			matrix `initial' = (`bips', `num1s', `num0s', `denom1s', `late_norm')
			local k = colsof(`initial')
			matrix `I' = I(`k')
			gmm `eqips' `eq_mu1' `eq_mu0' `eq_m1' `eq_tau_norm' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		}
		else if `dmeanz1'==0 | `dmeanz1'==1 {
			matrix `initial' = (`bips', `num1s', `num0s', `denom0s', `late_norm')
			local k = colsof(`initial')
			matrix `I' = I(`k')
			gmm `eqips' `eq_mu1' `eq_mu0' `eq_m0' `eq_tau_norm' if `touse', `eqips_inst' onestep winitial(`I') from(`initial') quickderivatives vce(`vce') iterate(0)
		}
		
		scalar `tau_norm' = _b[tau_norm:_cons]
		matrix `vc_tau_norm' = e(V)
		scalar `r_tau_norm' = rownumb(`vc_tau_norm', "tau_norm:_cons")
		scalar `var_tau_norm' = `vc_tau_norm'[`r_tau_norm', `r_tau_norm']
		
		scalar `N' = e(N)
	}
	
	// display results
	if "`which'"=="all" {
		if "`zmodel'"!="cbps" {
			tempname b V
			matrix `b' = (`tau_a', `tau_a1', `tau_a0', `tau_a10', `tau_norm')
			matrix `V' = (`var_tau_a', 0, 0, 0, 0 \ 0, `var_tau_a1', 0, 0, 0 \ 0, 0,`var_tau_a0', 0, 0 \ 0, 0, 0, `var_tau_a10', 0 \ 0, 0, 0, 0, `var_tau_norm')
			matrix rownames `b' = " "
			matrix colnames `b' = "tau_a" "tau_a,1" "tau_a,0" "tau_a,10" "tau_u"
			matrix rownames `V' = "tau_a" "tau_a,1" "tau_a,0" "tau_a,10" "tau_u"
			matrix colnames `V' = "tau_a" "tau_a,1" "tau_a,0" "tau_a,10" "tau_u"
		}
		else if "`zmodel'"=="cbps" {
			tempname b V
			matrix `b' = (`tau_a', `tau_norm')
			matrix `V' = (`var_tau_a', 0 \ 0, `var_tau_norm')
			matrix rownames `b' = " "
			matrix colnames `b' = "tau_a" "tau_u"
			matrix rownames `V' = "tau_a" "tau_u"
			matrix colnames `V' = "tau_a" "tau_u"
		}
	}
	
	else if "`which'"=="norm" {
		if "`zmodel'"!="cbps" {
			tempname b V
			matrix `b' = (`tau_a10', `tau_norm')
			matrix `V' = (`var_tau_a10', 0 \ 0, `var_tau_norm')
			matrix rownames `b' = " "
			matrix colnames `b' = "tau_a,10" "tau_u"
			matrix rownames `V' = "tau_a,10" "tau_u"
			matrix colnames `V' = "tau_a,10" "tau_u"
		}
		else if "`zmodel'"=="cbps" {
			tempname b V
			matrix `b' = (`tau_norm')
			matrix `V' = (`var_tau_norm')
			matrix rownames `b' = " "
			matrix colnames `b' = "tau_u"
			matrix rownames `V' = "tau_u"
			matrix colnames `V' = "tau_u"
		}
	}
	
	di as text _newline "Weighting estimation of the LATE"
	di
	di as text "Outcome     :   "  "`yvar'"
	di as text "Treatment   :   "  "`tvar'"
	di as text "Instrument  :   "  "`zvar'"
	if "`zmodel'"=="logit" {
		di as text "IPS         :   logit ML"
	}
	else if "`zmodel'"=="probit" {
		di as text "IPS         :   probit ML"
	}
	else if "`zmodel'"=="cbps" {
		di as text "IPS         :   logit CB"
	}
	di
	di as text "Number of obs   =   " as result `N'
	di
	
	ereturn post `b' `V', esample(`touse')
	ereturn scalar N = `N'
	
	ereturn local title "LATE estimation"
	ereturn local depvar `yvar'
	ereturn local tvar `tvar'
	ereturn local zvar `zvar'
	ereturn local zmodel `zmodel'
	ereturn local vce `vce'
	ereturn local cmd "kappalate"
	ereturn local cmdline `"kappalate `0'"'
	
	ereturn display
end
