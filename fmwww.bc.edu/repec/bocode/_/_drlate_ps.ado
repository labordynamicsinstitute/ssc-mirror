*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _drlate_ps
program define _drlate_ps, sclass
	// Handles PS estimation for logit / cbps / ipt
	// Fills ips/wt1/wt0 tempvars and bips/bips1/bips0 matrices
	// eqips strings are NOT built here - rebuilt locally in calling program
	
	version 17
	
	syntax, touse(name) zvar(name) zmodelvars(string) ///
		zmodel(string) samplew(name) ///
		pstolerance(real) ///
		ips(name) wt1(name) wt0(name) ///
		bips(name) bips1(name) bips0(name) ///
		[ iteropt(string) iteroptml(string) gmmopts(string) ///
		stat(string) osample(name) ]
	
	// Temporary objects local to this program
	tempvar ipsxb psxb1_1 psxb1_0 ips_1 ips_0
	tempname initial I
	
	quietly {
		// -----------------------------------------------
		// LOGIT
		// -----------------------------------------------
		if "`zmodel'" == "logit" {
			capture logit `zvar' `zmodelvars' [pw = `samplew'] if `touse'==1, asis `iteroptml'
			
			if e(converged)==0 {
				local ncd = 0
				if e(N_cds) & !missing(e(N_cds)) local ncd = e(N_cds)
				if e(N_cdf) & !missing(e(N_cdf)) local ncd = `ncd' + e(N_cdf)
				if `ncd' != 0 {
					noi di as error "{p}PS model has {bf:`ncd'} " ///
						"observations completely determined{p_end}"
					exit 322
				}
			}
			if _rc!=0 | e(converged)==0 {
				noi di as error "convergence not achieved for logit PS estimation"
				exit 430
			}
			
			matrix `bips' = e(b)
			predict double `ips' if `touse'==1
			gen double `wt1' = `zvar' / `ips' if `touse'==1
			gen double `wt0' = (1-`zvar') / (1-`ips') if `touse'==1
		}
		
		// -----------------------------------------------
		// CBPS
		// -----------------------------------------------
		else if "`zmodel'" == "cbps" {
			capture logit `zvar' `zmodelvars' if `touse'==1 [pw = `samplew']
			local rc_init = _rc
			if `rc_init'==0 {
				matrix `initial' = e(b)
				local kk = colsof(`initial')
				matrix `I' = I(`kk')
			}
			
			// Build eqips locally just for this GMM call
			local eqips_cbps (eqips: (`zvar'/(exp({zhat:`zmodelvars' _cons})/(1+exp({zhat:})))-(1-`zvar')/(1/(1+exp({zhat:})))))
			local eqips_cbps_inst instruments(eqips: `zmodelvars')
			
			if `rc_init'==0 {
				capture gmm `eqips_cbps' if `touse' [pw = `samplew'], ///
					`eqips_cbps_inst' onestep winitial(`I') from(`initial') ///
					quickderivatives `gmmopts' `iteropt'
			}
			else {
				capture gmm `eqips_cbps' if `touse' [pw = `samplew'], ///
					`eqips_cbps_inst' onestep quickderivatives `gmmopts' `iteropt'
			}
			
			if _rc!=0 | e(converged)==0 {
				noi di as error "convergence not achieved for CBPS estimation"
				exit 430
			}
			
			matrix `bips' = e(b)
			predict double `ipsxb'
			gen double `ips' = logistic(`ipsxb')
			gen double `wt1' = `zvar' / `ips' if `touse'==1
			gen double `wt0' = (1-`zvar') / (1-`ips') if `touse'==1
		}
		
		// -----------------------------------------------
		// IPT
		// -----------------------------------------------
		else if "`zmodel'" == "ipt" {		
			capture logit `zvar' `zmodelvars' if `touse'==1 [pw = `samplew']
			local rc_init = _rc
			if `rc_init'==0 {
				matrix `initial' = e(b)
				local kk = colsof(`initial')
				matrix `I' = I(`kk')
			}
			
			// --- Z=1 moment (built locally for this GMM only) ---
			local eqips1_loc (eqips1: (`zvar'*(1+exp({zhat1:`zmodelvars' _cons}))/(exp({zhat1:})) - 1))
			local eqips1_loc_inst instruments(eqips1: `zmodelvars')
			
			if `rc_init'==0 {
				capture gmm `eqips1_loc' if `touse' [pw = `samplew'], ///
					`eqips1_loc_inst' onestep winitial(`I') from(`initial') ///
					quickderivatives `gmmopts' `iteropt'
			}
			else {
				capture gmm `eqips1_loc' if `touse' [pw = `samplew'], ///
					`eqips1_loc_inst' onestep quickderivatives `gmmopts' `iteropt'
			}
			
			if _rc!=0 | e(converged)==0 {
				noi di as error "convergence not achieved for IPT estimation (Z=1)"
				exit 430
			}
			
			matrix `bips1' = e(b)
			predict double `psxb1_1'
			gen double `ips_1' = logistic(`psxb1_1')
			gen double `wt1' = `zvar' / `ips_1' if `touse'==1
			
			// --- Z=0 moment (built locally for this GMM only) ---
			local eqips0_loc (eqips0: ((1-`zvar')*(1+exp({zhat0:`zmodelvars' _cons})) - 1))
			local eqips0_loc_inst instruments(eqips0: `zmodelvars')
			
			if `rc_init'==0 {
				capture gmm `eqips0_loc' if `touse' [pw = `samplew'], ///
					`eqips0_loc_inst' onestep winitial(`I') from(`initial') ///
					quickderivatives `gmmopts' `iteropt'
			}
			else {
				capture gmm `eqips0_loc' if `touse' [pw = `samplew'], ///
					`eqips0_loc_inst' onestep quickderivatives `gmmopts' `iteropt'
			}
			
			if _rc!=0 | e(converged)==0 {
				noi di as error "convergence not achieved for IPT estimation (Z=0)"
				exit 430
			}
			
			matrix `bips0' = e(b)
			predict double `psxb1_0'
			gen double `ips_0' = logistic(`psxb1_0')
			gen double `wt0' = (1-`zvar') / (1-`ips_0') if `touse'==1
			
			// Combined ips for overlap check
			gen double `ips' = .
			replace `ips' = `ips_1' if `zvar'==1
			replace `ips' = `ips_0' if `zvar'==0
		}
		
		// -----------------------------------------------
		// Overlap check
		// -----------------------------------------------
		tempvar violators
		qui gen byte `violators' = (`ips' < `pstolerance' | `ips' > (1-`pstolerance')) if `touse'==1
		
		if "`osample'" != "" {
			qui gen byte `osample' = `violators'
			label variable `osample' "overlap violation indicator"
		}
		
		count if `violators'==1
		local fail = r(N)
		
		if `fail' {
			di as err "{p}" `fail' " observation" ///
				cond(`fail'>1,"s","") ///
				" violate the overlap assumption (ps outside [" ///
				trim(strofreal(`pstolerance',"%9.3e")) ///
				", 1-" trim(strofreal(`pstolerance',"%9.3e")) "]){p_end}"
			
			di as err "{p}instrument overlap assumption violated" _c
			local link drlate##osample:osample
			if "`osample'" != "" {
				di as err " -- see variable " ///
					"{helpb `link'}{bf:(`osample')}{p_end}"
			}
			else {
				di as err "; use {helpb `link'}{bf:()} to identify violators{p_end}"
			}
			exit 498
		}
	}
end
