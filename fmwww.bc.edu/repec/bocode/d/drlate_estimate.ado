*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop drlate_estimate
program define drlate_estimate, eclass
	version 17
	
	syntax [if] [in] [pw], ///
		yvar(string) tvar(string) zvar(string) ///
		omodel(string) tmodel(string) zmodel(string) ///
		[ ymodelvars(string) tmodelvars(string) zmodelvars(string) ///
		late latt nrm unnrm test(string) ///
		PSTOLerance(real 1e-5) OSample(name) STATNorm(string) METHOD(string) * ]
	
	// --- 1. Parse options ---
	_get_diopts diopts rest, `options'
	_drlate_gmmopts, `rest'
	local gmmopts `s(gmmopts)'
	local rest `s(rest)'
	local vce `s(vce)'
	local vcetype `s(vcetype)'
	local clustvar `s(clustvar)'
	local iteropt `s(iteropt)'
	local iteroptml `s(iteroptml)'
	
	_drlate_options, `rest'
	local drlateopts `s(drlateopts)'
	local rest `s(rest)'
	
	if "`rest'" != "" {
		local wc: word count `rest'
		di as err `"{p}`=plural(`wc',"option")' {bf:`rest'} "' ///
		`"`=plural(`wc',"is","are")' not allowed{p_end}"'
		exit 198
	}
	
	// --- 2. Option validation ---
	if "`vce'" == "cluster" {
		local vce "cluster `clustvar'"
	}
	
	if "`pstolerance'" == "" local pstolerance 1E-5
	if `pstolerance'<0 | `pstolerance'>=1 {
		di as err "{p}{bf:pstolerance()} must be >=0 and <1{p_end}"
		exit 198
	}
	
	if "`osample'" != "" {
		cap confirm variable `osample'
		if !c(rc) {
			di as err "{p}variable {bf:`osample'} already exists{p_end}"
			exit 110
		}
	}
	
	_drlate_getstats, `late' `latt' `nrm' `unnrm'
	local stat "`s(stat1)'"
	local statnorm "`s(stat2)'"
	
	if "`omodel'" == "linear" local omodel "regress"
	if "`tmodel'" == "linear" local tmodel "regress"
	
	if "`method'" == "" local method ipwra
	else if !inlist("`method'", "ipwra", "ipw", "aipw", "ra") {
		di as error "Invalid method {bf:`method'}"
		exit 198
	}

	if "`method'" == "ipw" {
		if "`ymodelvars'" != "" {
			di as error "outcome model not allowed with method(ipw)"
			exit 198
		}
		if "`tmodelvars'" != "" {
			di as error "treatment model not allowed with method(ipw)"
			exit 198
		}
	}
	
	if "`method'" == "ra" & "`zmodelvars'" != "" {
		di as error "instrument model not allowed with method(ra)"
		exit 198
	}
	
	if "`zmodel'" == "cbps" & "`stat'" == "latt" {
		di as error "CBPS not possible for LATT"
		exit 198
	}
	
	// --- 3. Sample and weight setup ---
	marksample touse
	markout `touse' `yvar'
	
	tempvar samplew
	if "`weight'" != "" qui gen double `samplew'`exp' if `touse'
	else qui gen double `samplew' = 1 if `touse'
	
	// --- 4. Input validation ---
	tempvar troot zroot
	tempname valuest valuesz
	
	qui tab `zvar' if `touse', gen(`zroot') matrow(`valuesz')
	if rowsof(`valuesz') != 2 {
		di as error "instrument {bf:`zvar'} must have exactly 2 values"
		exit 450
	}
	
	qui summarize `zvar' if `touse', meanonly
	if r(min)!=0 | r(max)!=1 {
		di as error "instrument {bf:`zvar'} must be 0/1"
		exit 450
	}
	
	if "`omodel'" == "logit" {
		tempvar yroot
		tempname valuesy
		qui tab `yvar' if `touse', gen(`yroot') matrow(`valuesy')
		if rowsof(`valuesy') != 2 {
			di as error "outcome must have exactly 2 values for logit"
			exit 450
		}
		qui summarize `yvar' if `touse'
		if r(min)!=0 | r(max)!=1 {
			di as error "outcome must be 0/1 for logit"
			exit 450
		}
	}
	
	if "`omodel'" == "poisson" {
		qui summarize `yvar' if `touse'
		if r(min) < 0 {
			di as error "outcome must be non-negative for poisson"
			exit 450
		}
	}
	
	if "`tmodel'" == "logit" {
		tempvar troot
		tempname valuest
		qui tab `tvar' if `touse', gen(`troot') matrow(`valuest')
		if rowsof(`valuest') != 2 {
			di as error "treatment must have exactly 2 values for logit"
			exit 450
		}
		qui summarize `tvar' if `touse'
		if r(min)!=0 | r(max)!=1 {
			di as error "treatment must be 0/1 for logit"
			exit 450
		}
	}
	
	if "`tmodel'" == "poisson" {
		qui summarize `tvar' if `touse'
		if r(min) < 0 {
			di as error "treatment must be non-negative for poisson"
			exit 450
		}
	}
	
	// --- 4b. Standardize continuous covariates ---
	// Tempvars are declared here so they stay in scope for all
	// subsequent calls (_drlate_ps, drlate_estimate_late/latt).
	// Logic follows kappalate / teffects2:
	// Pass 1: standardize c.var inside interactions
	// Pass 2: tokenize, skip factor tokens, standardize
	// plain continuous vars (r(r)>2)
	foreach __vl in y t z {
	if "``__vl'modelvars'" != "" {
		local __xvars `"``__vl'modelvars'"'
		
		// Pass 1: c.var in interactions
		local __testline `"`__xvars'"'
		while regexm(`"`__testline'"', "c\.([a-zA-Z0-9_]+)") {
			local __var = regexs(1)
			local __testline = subinstr(`"`__testline'"', "c.`__var'", "", 1)
			capture confirm variable `__var'
			if _rc == 0 {
				tempvar __stdvar
				qui sum `__var' if `touse'==1 [iw = `samplew']
				qui gen double `__stdvar' = (`__var' - r(mean)) / r(sd) if `touse'==1
				local __xvars : subinstr local __xvars "c.`__var'" "c.`__stdvar'", all
			}
		}
		
		// Pass 2: plain continuous vars
		local __cleanedvars ""
		tokenize `"`__xvars'"'
		while "`1'" != "" {
			local __token "`1'"
			macro shift
			local __newtoken "`__token'"
			local __skip 0
			if strpos("`__token'", "#") local __skip 1
			if regexm("`__token'", "^[0-9]+[a-z]?\.") local __skip 1
			if regexm("`__token'", "\.") local __skip 1
			if substr("`__token'", 1, 2) == "i." local __skip 1
			if substr("`__token'", 1, 2) == "c." local __skip 1
			if `__skip' == 0 {
				capture confirm variable `__token'
				if _rc == 0 {
					quietly capture tab `__token' if `touse'==1
					if _rc == 0 & r(r) > 2 {
						tempvar __stdvar
						qui sum `__token' if `touse'==1 [iw = `samplew']
						qui gen double `__stdvar' = (`__token' - r(mean)) / r(sd) if `touse'==1
						local __newtoken "`__stdvar'"
					}
				}
			}
			local __cleanedvars "`__cleanedvars' `__newtoken'"
		}
		
		// Use strtrim not list retokenize -- preserves ## operators
		local __cleanedvars = strtrim(`"`__cleanedvars'"')
		if `"`__cleanedvars'"' != "" local `__vl'modelvars `"`__cleanedvars'"'
		}
	}
	
	// --- 5. Compliance check ---
	tempname dmeanz1 dmeanz0
	qui summarize `tvar' if `zvar'==1 & `touse'==1
	scalar `dmeanz1' = r(mean)
	qui summarize `tvar' if `zvar'==0 & `touse'==1
	scalar `dmeanz0' = r(mean)
	
	// --- 6. PS estimation + overlap check ---
	tempvar ips wt1 wt0
	tempname bips bips_1 bips_0
	
	if "`method'" != "ra" {
		_drlate_ps, ///
			touse(`touse') zvar(`zvar') zmodelvars(`zmodelvars') ///
			zmodel(`zmodel') samplew(`samplew') ///
			pstolerance(`pstolerance') osample(`osample') ///
			ips(`ips') wt1(`wt1') wt0(`wt0') ///
			bips(`bips') bips1(`bips_1') bips0(`bips_0') ///
			iteropt(`iteropt') iteroptml(`iteroptml') ///
			gmmopts(`gmmopts') stat(`stat')
	}
	
	// --- 7. Normalize check ---
	tempname wt1m wt0m
	if "`method'" != "ra" {
		qui sum `wt1' if `touse'==1
		scalar `wt1m' = round(r(mean), 1e-6)
		qui sum `wt0' if `touse'==1
		scalar `wt0m' = round(r(mean), 1e-6)
		
		if "`statnorm'"=="nrm" & "`method'"!="ra" & `wt0m'==1 & `wt1m'==1 {
			local statnorm unnrm
		}
	}
	
	// --- 8. Dispatch to stat-specific estimator ---
	if "`stat'" == "late" {
		drlate_estimate_late, ///
			yvar(`yvar') tvar(`tvar') zvar(`zvar') ///
			omodel(`omodel') tmodel(`tmodel') zmodel(`zmodel') ///
			ymodelvars(`ymodelvars') tmodelvars(`tmodelvars') ///
			zmodelvars(`zmodelvars') ///
			method(`method') statnorm(`statnorm') ///
			touse(`touse') samplew(`samplew') ips(`ips') ///
			wt1(`wt1') wt0(`wt0') ///
			dmeanz1(`dmeanz1') dmeanz0(`dmeanz0') ///
			bips(`bips') bips1(`bips_1') bips0(`bips_0') ///
			vce(`vce') gmmopts(`gmmopts')
	}
	else if "`stat'" == "latt" {
		drlate_estimate_latt, ///
			yvar(`yvar') tvar(`tvar') zvar(`zvar') ///
			omodel(`omodel') tmodel(`tmodel') zmodel(`zmodel') ///
			ymodelvars(`ymodelvars') tmodelvars(`tmodelvars') ///
			zmodelvars(`zmodelvars') ///
			method(`method') statnorm(`statnorm') ///
			touse(`touse') samplew(`samplew') ips(`ips') ///
			wt1(`wt1') wt0(`wt0') ///
			dmeanz1(`dmeanz1') dmeanz0(`dmeanz0') ///
			bips(`bips') bips1(`bips_1') bips0(`bips_0') ///
			vce(`vce') gmmopts(`gmmopts')
	}
	
	// --- 9. Collect results from e() left by sub-program ---
	// (GMM e() results are still active after sub-program returns)
	local N = e(N)
	local N_clust = e(N_clust)
	
	tempname late_sc vc_late r_late var_late
	tempname ate_num r_ate_num var_ate_num
	tempname ate_denom r_ate_denom var_ate_denom
	
	scalar `late_sc' = _b[late:_cons]
	matrix `vc_late' = e(V)
	scalar `r_late' = rownumb(`vc_late', "late:_cons")
	scalar `var_late' = `vc_late'[`r_late', `r_late']
	
	scalar `ate_num' = _b[num:_cons]
	scalar `r_ate_num' = rownumb(`vc_late', "num:_cons")
	scalar `var_ate_num' = `vc_late'[`r_ate_num', `r_ate_num']
	
	scalar `ate_denom' = _b[denom:_cons]
	scalar `r_ate_denom' = rownumb(`vc_late', "denom:_cons")
	scalar `var_ate_denom' = `vc_late'[`r_ate_denom', `r_ate_denom']
	
	// --- 10. Post results ---
	if "`stat'" == "latt" {
		tempname b V
		matrix `b' = (`late_sc', `ate_num', `ate_denom')
		matrix `V' = (`var_late', 0, 0 \ 0, `var_ate_num', 0 \ 0, 0, `var_ate_denom')
		matrix rownames `b' = " "
		matrix colnames `b' = "LATT: D on Y" "ATT: Z on Y" "ATT: Z on D"
		matrix rownames `V' = "LATT: D on Y" "ATT: Z on Y" "ATT: Z on D"
		matrix colnames `V' = "LATT: D on Y" "ATT: Z on Y" "ATT: Z on D"
		ereturn post `b' `V', esample(`touse')
		ereturn local method "`method'"
		ereturn local statnorm "`statnorm'"
		ereturn local stat "`stat'"
		ereturn scalar dmeanz0 = `dmeanz0'
		ereturn scalar dmeanz1 = `dmeanz1'
	}
	else if "`stat'" == "late" {
		tempname b V
		matrix `b' = (`late_sc', `ate_num', `ate_denom')
		matrix `V' = (`var_late', 0, 0 \ 0, `var_ate_num', 0 \ 0, 0, `var_ate_denom')
		matrix rownames `b' = " "
		matrix colnames `b' = "LATE: D on Y" "ATE: Z on Y" "ATE: Z on D"
		matrix rownames `V' = "LATE: D on Y" "ATE: Z on Y" "ATE: Z on D"
		matrix colnames `V' = "LATE: D on Y" "ATE: Z on Y" "ATE: Z on D"
		ereturn post `b' `V', esample(`touse')
		ereturn local method "`method'"
		ereturn local statnorm "`statnorm'"
		ereturn local stat "`stat'"
		ereturn scalar dmeanz0 = `dmeanz0'
		ereturn scalar dmeanz1 = `dmeanz1'
	}
	
	// --- 11. Display ---
	if "`method'" == "ipw" local methodd "IPW"
	else if "`method'" == "aipw" local methodd "AIPW"
	else if "`method'" == "ipwra" local methodd "IPWRA"
	else if "`method'" == "ra" local methodd "RA"
	
	if "`zmodel'" == "ipt" local statnormd "normalized"
	else if "`statnorm'" == "nrm" local statnormd "normalized"
	else local statnormd "unnormalized"
	
	if "`omodel'" == "regress" local omodeld "linear"
	else if "`omodel'" == "poisson" local omodeld "Poisson"
	else local omodeld "`omodel'"
	
	if "`tmodel'" == "regress" local tmodeld "linear"
	else if "`tmodel'" == "poisson" local tmodeld "Poisson"
	else local tmodeld "`tmodel'"
	
	if "`method'" == "ipw" {
		local omodeld "weighted mean"
		local tmodeld "weighted mean"
	}
	
	if "`zmodel'" == "logit" local zmodeld "logit (MLE)"
	else if "`zmodel'" == "cbps" local zmodeld "logit (CBPS)"
	else if "`zmodel'" == "ipt" local zmodeld "logit (IPT)"
	
	if "`stat'" == "late" di as txt _n "Local average treatment effect" ///
		"{col 51}Number of obs {col 67}= " as res %10.0fc `N'
	else di as txt _n "Local average treatment effect on the treated" ///
		"{col 51}Number of obs {col 67}= " as res %10.0fc `N'
	if "`method'" == "ra" | "`method'" == "ipwra" di "{txt:Estimator}{col 18}:{res: `methodd'}"
	else di "{txt:Estimator}{col 18}:{res: `methodd' (`statnormd')}"
	di "{txt:Outcome model}{col 18}:{res: `omodeld'}"
	di "{txt:Treatment model}{col 18}:{res: `tmodeld'}"
	di "{txt:Instrument model}{col 18}:{res: `zmodeld'}"
end
