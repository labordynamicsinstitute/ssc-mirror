*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_ipw
program define _teffects2_ipw, byable(onecall)
	version 17
	
	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	_teffects2_parse_canonicalize ipw : `0'
	
	if `s(eqn_n)'==1 {
		_teffects2_error_msg, cmd(ipw) case(1)
	}
	if `s(eqn_n)'>2 {
		_teffects2_error_msg, cmd(ipw) case(2)
	}
	
	local omodel `"`s(eqn_1)'"'
	local tmodel `"`s(eqn_2)'"'
	
	local if `"`s(if)'"'
	local in `"`s(in)'"'
	local wt `"`s(wt)'"'
	local options `"`s(options)'"'
	
	`BY' Estimate_ipw `if' `in' `wt', omodel(`omodel') tmodel(`tmodel') `options'
end

capture program drop Estimate_ipw
program define Estimate_ipw, eclass byable(recall)
	version 17
	
	syntax [if] [in] [pw], [ ///
	omodel(string) ///
	tmodel(string) ///
	ate atet ///
	nrm unnrm ///
	PSTOLerance(numlist max=1) ///
	OSample(name) ///
	* ]
	
	quietly {
		_get_diopts diopts rest, `options'
		local diopts `diopts'
		
		_teffects2_gmmopts, `rest'
		
		local gmmopts `s(gmmopts)'
		local rest `s(rest)'
		local vce `s(vce)'
		local vcetype `s(vcetype)'
		local clustvar `s(clustvar)'
		local iteropt `s(iteropt)'
		local iteroptml `s(iteroptml)'
		
		_teffects_options ipw : `rest'
		local teopts `s(teopts)'
		local rest `s(rest)'
		
		if "`rest'"!="" {
			local wc: word count `rest'
			di as err `"{p} `=plural(`wc',"option")' {bf:`rest'} "' ///
			`"`=plural(`wc',"is","are")' not allowed{p_end}"'
			exit 198
		}
		
		if "`vce'"=="cluster" {
			local `vce' "cluster `clustvar'"
		}
		
		if "`pstolerance'"=="" {
			local pstolerance 1E-5
		}
		
		if "`pstolerance'"!="" {
			if `pstolerance'<0 | `pstolerance'>=1 {
				di as err "{p}{bf:pstolerance()} must be greater " ///
				"than or equal to 0 and less than 1{p_end}"
				exit 198
			}
		}
		
		if "`osample'"!="" {
			cap confirm variable `osample'
			if !c(rc) {
				di as err "{p}invalid option " ///
				"{bf:osample({it:newvarname})}; variable " ///
				"{bf:`osample'} already exists{p_end}"
				exit 110
			}
		}
		
		_teffects2_getstatsipw, `ate' `atet' `nrm' `unnrm'
		local stat1 "`s(stat1)'"
		local stat `stat1'
		if "`stat'"=="atet" local stat att
		
		local stat2 "`s(stat2)'"
		local statnorm `stat2'
		
		ParseDepvar `omodel'
		local depvar `s(depvar)'
		
		marksample touse
		markout `touse' `depvar'
		
		_teffects2_count_obs `touse'
		
		if "`weight'"!="" {
			tempvar samplew
			gen double `samplew' `exp' if `touse'
		}
		
		else if "`pw'"=="" {
			tempvar samplew
			gen double `samplew' = 1 if `touse'==1
		}
		
		ExtractVarlist `tmodel'
		local tvarlist `s(varlist)'
		local tops `s(options)'
		
		_teffects2_parse_tvarlist `tvarlist', `tops' touse(`touse') stat(`stat') cmd(ipw) binary
		
		local tvar `s(tvar)'
		local tvarlist `s(tvarlist)'
		local fvtvarlist `s(fvtvarlist)'
		local ktvar = `s(k)'
		local kfvtvar = `s(kfv)'
		local tmodel `s(tmodel)'
		local control = `s(control)'
		
		if "`tops'"=="" {
			local tmodel ipt
		}
		
		if "`tmodel'"=="cbps" & "`stat'"=="att" {
			noi display as error "CBPS not allowed for ATT"
			exit 198
		}
		
		// Expand the factor variable list
		fvexpand `fvtvarlist'
		
		// Store expanded variable list
		local xvarst "`r(varlist)'"
		
		// Start with original xvars
		local cleanedvarst ""
		local tempmapt ""
		
		// Step 1: standardize all c.var inside interactions or plain c.var
		local testline "`xvarst'"
		while regexm("`testline'", "c\.([a-zA-Z0-9_]+)") {
			local match = regexm("`testline'", "c\.([a-zA-Z0-9_]+)")
			local vart = regexs(1)
			local testline = subinstr("`testline'", "c.`vart'", "", 1)
			
			tempvar stdvart
			sum `vart' if `touse'==1 [iw = `samplew']
			gen double `stdvart' = (`vart' - r(mean))/r(sd) if `touse'==1
			
			// Replace in xvars (c.var --> c.stdvar)
			local xvarst : subinstr local xvarst "c.`vart'" "c.`stdvart'", all
			local tempmapt `tempmapt' `stdvart'
		}
		
		// Step 2: tokenize updated xvars and rebuild cleaned varlist safely
		tokenize "`xvarst'"
		while "`1'"!="" {
			local token "`1'"
			macro shift
			
			// Default: keep token unchanged
			local newtokent "`token'"
			
			// Skip interactions, i., c., dummies, etc.
			if !strpos("`token'", "#") & !regexm("`token'", "^[0-9]+[a-z]?\.") & !regexm("`token'", "[\.]") & substr("`token'", 1, 2)!="i." & substr("`token'", 1, 2)!="c." {
				capture confirm variable `token'
				if _rc==0 {
					capture tab `token' if `touse'==1
					if _rc==0 & r(r)>2 {
						// Not binary --> standardize
						tempvar stdvart
						sum `token' if `touse'==1 [iw = `samplew']
						gen double `stdvart' = (`token' - r(mean))/r(sd) if `touse'==1
						
						local newtokent "`stdvart'"
						local tempmapt `tempmapt' `stdvart'
					}
				}
			}
			
			// Add newtoken to cleaned varlist
			local cleanedvarst "`cleanedvarst' `newtokent'"
		}
		
		// Final cleaned varlist
		local xvarst "`cleanedvarst'"
		
		tempvar ps psxb1 psxb2 ps_1 psxb1_1 psxb2_1 ps_0 psxb1_0 psxb2_0 y1hatw y0hatw wt1 wt0
		tempname bps bps1 bps_1 bps_0 bps1_1 bps1_0 bps2_1 bps2_0 bps2 starting initial I nums by1w by0w num1ws num0ws ateipwras bd1 bd0 num1s num0s num_norms
		
		tempname ate_ipw vc_ate_ipw r_ate_ipw var_ate_ipw
		tempname ate_ipwra vc_ate_ipwra r_ate_ipwra var_ate_ipwra
		tempname ate_nipw vc_ate_nipw r_ate_nipw var_ate_nipw
		tempname ate_aipw vc_ate_aipw r_ate_aipw var_ate_aipw
		tempname ate_naipw vc_ate_naipw r_ate_naipw var_ate_naipw nob
		
		tempname att_ipw vc_att_ipw r_att_ipw var_att_ipw
		tempname att_ipwra vc_att_ipwra r_att_ipwra var_att_ipwra
		tempname att_nipw vc_att_nipw r_att_nipw var_att_nipw
		tempname att_aipw vc_att_aipw r_att_aipw var_att_aipw
		tempname att_naipw vc_att_naipw r_att_naipw var_att_naipw
		
		// If estimating ATE
		if "`stat'"=="ate" {
			// Estimation of the propensity score
			if "`tmodel'"=="logit" {
				capture `tmodel' `tvar' `xvarst' [pw = `samplew'] if `touse'==1, asis `iteroptml'
				
				if e(converged)==0 {
					// Check perfect predictions, if >0 exit similar to teffects
					local ncd = 0
					if e(N_cds) & !missing(e(N_cds)) local ncd = e(N_cds)
					if e(N_cdf) & !missing(e(N_cdf)) local ncd = `ncd' + e(N_cdf)
					
					if `ncd'!=0 {
						local obs = plural(`ncd', "observation")
						noi di as error "{p}Treatment model has {bf:`ncd'} `obs' " ///
						"completely determined; the model, as specified, is not identified{p_end}"
						exit 322
					}
				}
				
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for `tmodel' estimation"
					exit 430
				}
				
				matrix `bps' = e(b)
				predict double `ps' if `touse'==1
				gen double `wt1' = `tvar'/`ps' if `touse'==1
				gen double `wt0' = (1-`tvar')/(1-`ps') if `touse'==1
				
				local eqps (eqps:`tvar' - exp({that:`xvarst'} + {b0})/(1+exp({that:}+ {b0})))
				local eqps_inst instruments(eqps: `xvarst')
			}
			else if "`tmodel'"=="cbps" {
				// Determine starting values from logit
				capture logit `tvar' `xvarst' [pw = `samplew'] if `touse'==1
				local rc_init = _rc
				if `rc_init'==0 {
					matrix `initial' = e(b)
					local k = colsof(`initial')
					matrix `I' = I(`k')
				}
				
				local eqps (eqps: (`tvar'/(exp({that:`xvarst'} + {b0})/(1+exp({that:}+ {b0})))-(1-`tvar')/(1/(1+exp({that:}+{b0})))))
				local eqps_inst instruments(eqps: `xvarst')
				
				// GMM estimation of the propensity score using CBPS moments
				if `rc_init'==0 capture gmm `eqps' if `touse' [pw = `samplew'], `eqps_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' `iteropt'
				else capture gmm `eqps' if `touse' [pw = `samplew'], `eqps_inst' onestep quickderivatives `gmmopts' `iteropt'
				
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for CBPS estimation"
					exit 430
				}
				
				matrix `bps1' = e(b)
				predict double `psxb1' if `touse'==1
				gen double `ps' = exp(`psxb1'+_b[b0:_cons])/(1+exp(`psxb1'+_b[b0:_cons])) if `touse'==1
				
				matrix `bps' = `bps1'
				gen double `wt1' = `tvar'/`ps' if `touse'==1
				gen double `wt0' = (1-`tvar')/(1-`ps') if `touse'==1
			}
			else if "`tmodel'"=="ipt" {
				// Determine starting values from logit
				capture logit `tvar' `xvarst' [pw = `samplew'] if `touse'==1
				local rc_init = _rc
				if `rc_init'==0 {
					matrix `initial' = e(b)
					local k = colsof(`initial')
					matrix `I' = I(`k')
				}
				
				// Moment function
				local eqps1 (eqps1: (`tvar'*(1+exp({that1: `xvarst'} + {b1}))/(exp({that1:}+ {b1})) - 1))
				local eqps1_inst instruments(eqps1: `xvarst')
				
				// GMM estimation
				if `rc_init'==0 capture gmm `eqps1' if `touse' [pw = `samplew'], `eqps1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' `iteropt'
				else capture gmm `eqps1' if `touse' [pw = `samplew'], `eqps1_inst' onestep quickderivatives `gmmopts' `iteropt'
				
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for IPT estimation"
					exit 430
				}
				
				predict double `psxb1_1' if `touse'==1
				gen double `ps_1' = exp(`psxb1_1'+_b[b1:_cons])/(1+exp(`psxb1_1'+_b[b1:_cons])) if `touse'==1
				gen double `wt1' = `tvar'/`ps_1' if `touse'==1
				matrix `bps_1' = e(b)
				
				// Moment function
				local eqps0 (eqps0: ((1-`tvar')*(1+exp({that0: `xvarst'} + {b0})) - 1))
				local eqps0_inst instruments(eqps0: `xvarst')
				
				// GMM estimation
				if `rc_init'==0 capture gmm `eqps0' if `touse' [pw = `samplew'], `eqps0_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' `iteropt'
				else capture gmm `eqps0' if `touse' [pw = `samplew'], `eqps0_inst' onestep quickderivatives `gmmopts' `iteropt'
								
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for IPT estimation"
					exit 430
				}
				
				predict double `psxb1_0' if `touse'==1
				gen double `ps_0' = exp(`psxb1_0'+_b[b0:_cons])/(1+exp(`psxb1_0'+_b[b0:_cons])) if `touse'==1
				
				gen double `wt0' = (1-`tvar')/(1-`ps_0') if `touse'==1
				matrix `bps_0' = e(b)
				
				gen double `ps' = . if `touse'==1
				replace `ps' = `ps_1' if `tvar'==1 & `touse'==1
				replace `ps' = `ps_0' if `tvar'==0 & `touse'==1
			}
			
			// Check for overlap violations
			tempvar violators
			gen byte `violators' = (`ps' < `pstolerance' | `ps' > (1 - `pstolerance')) if `touse'==1
			count if `violators'==1
			local fail = r(N)
			
			if "`osample'"!="" {
				gen byte `osample' = `violators' if `touse'==1
				label variable `osample' "overlap violation indicator"
			}
			
			if `fail' {
				di as err "{p}" r(N) " observation" cond(r(N)>1, "s", "") ///
				" violate" cond(r(N)==1, "s", "") " the overlap assumption with " ///
				"a propensity score outside the range [" ///
				trim(strofreal(`pstolerance', "%9.3e")) ///
				", 1 - " ///
				trim(strofreal(`pstolerance', "%9.3e")) "]{p_end}"
				
				di as err "{p}treatment overlap assumption has been violated" _c
				local link teffects2_ipw##osample:osample
				if "`osample'"!="" {
					di as err " by observations identified in variable " ///
					"{helpb `link'}{bf:(`osample')}{p_end}"
				}
				else {
					di as err "; use option {helpb `link'}" ///
					"{bf:()} to identify the overlap violators{p_end}"
				}
				
				exit 498
			}
			
			// Estimation of ATE with estimated propensity score
			if "`statnorm'"=="unnrm" {
				tempvar y1ipw y0ipw
				tempname num1ipws num0ipws ateipws
				
				gen double `y1ipw' = `wt1'*`depvar' if `touse'==1
				gen double `y0ipw' = `wt0'*`depvar' if `touse'==1
				
				sum `y1ipw' if `touse'==1 [iw = `samplew']
				matrix `num1ipws' = r(mean)
				
				sum `y0ipw' if `touse'==1 [iw = `samplew']
				matrix `num0ipws' = r(mean)
				
				matrix `ateipws' = `num1ipws'-`num0ipws'
			}
			else if "`statnorm'"=="nrm" {
				tempvar y1nipw y0nipw
				tempname by1nipw by0nipw num1nipws num0nipws atenipws
				
				regress `depvar' if `tvar'==1 & `touse'==1 [pw = `samplew'/`ps']
				matrix `by1nipw' = e(b)
				predict double `y1nipw' if `touse'==1
				
				regress `depvar' if `tvar'==0 & `touse'==1 [pw = `samplew'/(1-`ps')]
				matrix `by0nipw' = e(b)
				predict double `y0nipw' if `touse'==1
				
				sum `y1nipw' if `touse'==1 [iw = `samplew']
				matrix `num1nipws' = r(mean)
				sum `y0nipw' if `touse'==1 [iw = `samplew']
				matrix `num0nipws' = r(mean)
				
				matrix `atenipws' = `num1nipws'-`num0nipws'
			}
			
			// Plug everything in GMM
			if "`tmodel'"=="ipt" {
				if "`statnorm'"=="unnrm" {
					local eqy0ipw (eqy0ipw: (((1-`tvar')/(1-(exp({that0:}+ {b0})/(1+exp({that0:}+ {b0})))))*`depvar')-({y0}))
					local eqy0ipw_inst instruments(eqy0ipw: )
					local eqy1ipw (eqy1ipw: ((`tvar'/(exp({that1:}+ {b1})/(1+exp({that1:}+ {b1}))))*`depvar')-({y1}))
					local eqy1ipw_inst instruments(eqy1ipw: )
					local ipw (ipw: {ipw}-(({y1})-({y0})))
					
					matrix `initial' = (`bps_0', `bps_1', `num0ipws', `num1ipws', `ateipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps0' `eqps1' `eqy0ipw' `eqy1ipw' `ipw' if `touse' [pw = `samplew'], `eqps0_inst' `eqps1_inst' `eqy0ipw_inst' `eqy1ipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `ate_ipw' = _b[ipw:_cons]
					matrix `vc_ate_ipw' = e(V)
					scalar `r_ate_ipw' = rownumb(`vc_ate_ipw', "ipw:_cons")
					scalar `var_ate_ipw' = `vc_ate_ipw'[`r_ate_ipw', `r_ate_ipw']
					
					tempname muhat0_ipw r_muhat0_ipw var_muhat0_ipw
					scalar `muhat0_ipw' = _b[y0:_cons]
					scalar `r_muhat0_ipw' = rownumb(`vc_ate_ipw', "y0:_cons")
					scalar `var_muhat0_ipw' = `vc_ate_ipw'[`r_muhat0_ipw', `r_muhat0_ipw']
				}
				else if "`statnorm'"=="nrm" {
					local eqy0nipw (eqy0nipw: ((0.`tvar'/(1-(exp({that0:} + {b0})/(1+exp({that0:} + {b0})))))*(`depvar'-({y0}))))
					local eqy0nipw_inst instruments(eqy0nipw: )
					local eqy1nipw (eqy1nipw: ((1.`tvar'/(exp({that1:}+ {b1})/(1+exp({that1:}+ {b1}))))*(`depvar'-({y1}))))
					local eqy1nipw_inst instruments(eqy1nipw: )
					local nipw (nipw: {nipw}-(({y1})-({y0})))
					
					matrix `initial' = (`bps_0', `bps_1', `num0nipws', `num1nipws', `atenipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps0' `eqps1' `eqy0nipw' `eqy1nipw' `nipw' if `touse' [pw = `samplew'], `eqps0_inst' `eqps1_inst' `eqy0nipw_inst' `eqy1nipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `ate_nipw' = _b[nipw:_cons]
					matrix `vc_ate_nipw' = e(V)
					scalar `r_ate_nipw' = rownumb(`vc_ate_nipw', "nipw:_cons")
					scalar `var_ate_nipw' = `vc_ate_nipw'[`r_ate_nipw', `r_ate_nipw']
					
					tempname muhat0_nipw r_muhat0_nipw var_muhat0_nipw
					scalar `muhat0_nipw' = _b[y0:_cons]
					scalar `r_muhat0_nipw' = rownumb(`vc_ate_nipw', "y0:_cons")
					scalar `var_muhat0_nipw' = `vc_ate_nipw'[`r_muhat0_nipw', `r_muhat0_nipw']
				}
			}
			else if "`tmodel'"!="ipt" {
				if "`statnorm'"=="unnrm" {
					local eqy0ipw (eqy0ipw: (((1-`tvar')/(1/(1+exp({that:}+ {b0}))))*`depvar')-({y0}))
					local eqy0ipw_inst instruments(eqy0ipw: )
					local eqy1ipw (eqy1ipw: ((`tvar'/(exp({that:}+ {b0})/(1+exp({that:}+ {b0}))))*`depvar')-({y1}))
					local eqy1ipw_inst instruments(eqy1ipw: )
					local ipw (ipw: {ipw}-(((`tvar'/(exp({that:}+ {b0})/(1+exp({that:}+ {b0}))))*`depvar')-(((1-`tvar')/(1/(1+exp({that:}+ {b0}))))*`depvar')))
					
					matrix `initial' = (`bps', `num0ipws', `ateipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy0ipw' `ipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0ipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `ate_ipw' = _b[ipw:_cons]
					matrix `vc_ate_ipw' = e(V)
					scalar `r_ate_ipw' = rownumb(`vc_ate_ipw', "ipw:_cons")
					scalar `var_ate_ipw' = `vc_ate_ipw'[`r_ate_ipw', `r_ate_ipw']
					
					tempname muhat0_ipw r_muhat0_ipw var_muhat0_ipw
					scalar `muhat0_ipw' = _b[y0:_cons]
					scalar `r_muhat0_ipw' = rownumb(`vc_ate_ipw', "y0:_cons")
					scalar `var_muhat0_ipw' = `vc_ate_ipw'[`r_muhat0_ipw', `r_muhat0_ipw']
				}
				else if "`statnorm'"=="nrm" {
					local eqy0nipw (eqy0nipw: ((0.`tvar'/(1-(exp({that:}+ {b0})/(1+exp({that:}+ {b0})))))*(`depvar'-({y0}))))
					local eqy0nipw_inst instruments(eqy0nipw: )
					local eqy1nipw (eqy1nipw: ((1.`tvar'/(exp({that:}+ {b0})/(1+exp({that:}+ {b0}))))*(`depvar'-({y1}))))
					local eqy1nipw_inst instruments(eqy1nipw: )
					local nipw (nipw: {nipw}-(({y1})-({y0})))
					
					matrix `initial' = (`bps', `num0nipws', `num1nipws', `atenipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy0nipw' `eqy1nipw' `nipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0nipw_inst' `eqy1nipw_inst' onestep winitial(`I') from(`initial') quickderivatives iterate(0) `gmmopts'
					
					scalar `ate_nipw' = _b[nipw:_cons]
					matrix `vc_ate_nipw' = e(V)
					scalar `r_ate_nipw' = rownumb(`vc_ate_nipw', "nipw:_cons")
					scalar `var_ate_nipw' = `vc_ate_nipw'[`r_ate_nipw', `r_ate_nipw']
					
					tempname muhat0_nipw r_muhat0_nipw var_muhat0_nipw
					scalar `muhat0_nipw' = _b[y0:_cons]
					scalar `r_muhat0_nipw' = rownumb(`vc_ate_nipw', "y0:_cons")
					scalar `var_muhat0_nipw' = `vc_ate_nipw'[`r_muhat0_nipw', `r_muhat0_nipw']
				}
			}
		}
		
		// If estimating ATT
		if "`stat'"=="att" {
			// Estimation of the propensity score
			if "`tmodel'"=="logit" {
				capture `tmodel' `tvar' `xvarst' if `touse'==1 [pw = `samplew'], asis `iteroptml'
				
				if e(converged)==0 {
					// Check perfect predictions, if >0 exit similar to teffects
					local ncd = 0
					if e(N_cds) & !missing(e(N_cds)) local ncd = e(N_cds)
					if e(N_cdf) & !missing(e(N_cdf)) local ncd = `ncd' + e(N_cdf)
					
					if `ncd'!=0 {
						local obs = plural(`ncd', "observation")
						noi di as error "{p}Treatment model has {bf:`ncd'} `obs' " ///
						"completely determined; the model, as specified, is not identified{p_end}"
						exit 322
					}
				}
				
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for `tmodel' estimation"
					exit 430
				}
				
				matrix `bps' = e(b)
				predict double `ps' if `touse'==1
				
				local eqps (eqps:`tvar' - exp({that:`xvarst'} + {b0})/(1+exp({that:}+ {b0})))
				local eqps_inst instruments(eqps: `xvarst')
			}
			else if "`tmodel'"=="ipt" {
				// Determine starting values from logit
				capture logit `tvar' `xvarst' if `touse'==1 [pw = `samplew']
				local rc_init = _rc
				if `rc_init'==0 {
					matrix `initial' = e(b)
					local k = colsof(`initial')
					matrix `I' = I(`k')
				}
				
				local eqps (eqps: (`tvar' - ((exp({that: `xvarst'} + {b0}))*(1-`tvar'))))
				local eqps_inst instruments(eqps: `xvarst')
				
				// GMM estimation
				if `rc_init'==0 capture gmm `eqps' if `touse' [pw = `samplew'], `eqps_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' `iteropt'
				else capture gmm `eqps' if `touse' [pw = `samplew'], `eqps_inst' onestep quickderivatives `gmmopts' `iteropt'
				
				if _rc!=0 | e(converged)==0 {
					noi di as error "convergence not achieved for IPT estimation"
					exit 430
				}
				
				matrix `bps1_0' = e(b)
				predict double `psxb1_0' if `touse'==1
				gen double `wt0' = exp(`psxb1_0'+_b[b0:_cons]) if `touse'==1
				
				matrix `bps' = e(b)
				gen double `ps' = `wt0'/(1+`wt0') if `touse'==1
			}
			
			// Check for overlap violations
			tempvar violators
			gen byte `violators' = `ps' > 1-`pstolerance' if `touse'==1
			count if `violators'==1
			local fail = r(N)
			
			if "`osample'"!="" {
				gen byte `osample' = `violators' if `touse'==1
				label variable `osample' "overlap violation indicator"
			}
			
			if `fail' {
				di as err "{p}" r(N) " observation" cond(r(N)>1, "s", "") ///
				" violate" cond(r(N)==1, "s", "") " the overlap assumption with " ///
				"a propensity score greater than 1 - " %9.3e `pstolerance' "{p_end}"
				
				di as err "{p}treatment overlap assumption has been violated" _c
				local link teffects2_ipw##osample:osample
				if "`osample'"!="" {
					di as err " by observations identified in variable " ///
					"{helpb `link'}{bf:(`osample')}{p_end}"
				}
				else {
					di as err "; use option {helpb `link'}" ///
					"{bf:()} to identify the overlap violators{p_end}"
				}
				
				exit 498
			}
			
			// Estimation of ATT with estimated propensity score
			if "`tmodel'"=="logit" {
				if "`statnorm'"=="unnrm" {
					tempvar omega1 omega0 y1hatipw y0hatipw
					tempname w1s w1 num0ipws num1ipws attipws
					
					sum `tvar' if `touse'==1 [iw = `samplew']
					matrix `w1s' = r(mean)
					sum `tvar' if `touse'==1 [iw = `samplew']
					scalar `w1' = r(mean)
					
					gen double `omega1' = (`tvar')/`w1' if `touse'==1
					gen double `omega0' = (((1-`tvar')*`ps')/(1-`ps'))/`w1' if `touse'==1
					
					gen double `y1hatipw' = `omega1'*`depvar' if `touse'==1
					gen double `y0hatipw' = `omega0'*`depvar' if `touse'==1
					
					sum `y1hatipw' if `touse'==1 [iw = `samplew']
					matrix `num1ipws' = r(mean)
					sum `y0hatipw' if `touse'==1 [iw = `samplew']
					matrix `num0ipws' = r(mean)
					matrix `attipws' = `num1ipws'-`num0ipws'
				}
				else if "`statnorm'"=="nrm" {
					tempvar y0hatnipw
					tempname by0nipw num1nipws num0nipws attnipws
					
					regress `depvar' if `tvar'==1 & `touse'==1 [pw = `samplew']
					matrix `by1w' = e(b)
					predict double `y1hatw' if `touse'==1

					regress `depvar' if `tvar'==0 & `touse'==1 [pw = `samplew'*(`ps'/(1-`ps'))]
					matrix `by0nipw' = e(b)
					predict double `y0hatnipw' if `touse'==1
					
					sum `y1hatw' if `tvar'==1 & `touse'==1 [iw = `samplew']
					matrix `num1nipws' = r(mean)
					sum `y0hatnipw' if `tvar'==1 & `touse'==1 [iw = `samplew']
					matrix `num0nipws' = r(mean)
					matrix `attnipws' = `num1nipws'-`num0nipws'
				}
			}
			else if "`tmodel'"=="ipt" {
				tempvar y0hatnipw
				tempname by0nipw num1nipws num0nipws attnipws
				
				regress `depvar' if `tvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1w' = e(b)
				predict double `y1hatw' if `touse'==1
				
				regress `depvar' if `tvar'==0 & `touse'==1 [pw = `samplew'*(`wt0')]
				matrix `by0nipw' = e(b)
				predict double `y0hatnipw' if `touse'==1
				
				sum `y1hatw' if `tvar'==1 & `touse'==1 [iw = `samplew']
				matrix `num1nipws' = r(mean)
				sum `y0hatnipw' if `tvar'==1 & `touse'==1 [iw = `samplew']
				matrix `num0nipws' = r(mean)
				matrix `attnipws' = `num1nipws'-`num0nipws'
			}
			
			// GMM estimation
			if "`tmodel'"=="logit" {
				if "`statnorm'"=="unnrm" {
					local eqw1ipw (eqw1ipw: (`tvar' - {w1}))
					local eqw1ipw_inst instruments(eqw1ipw: )
					local eqy1ipw (eqy1ipw: (`tvar'*(`depvar'/{w1})-({y1})))
					local eqy1ipw_inst instruments(eqy1ipw: )
					local eqy0ipw (eqy0ipw: (((1-`tvar')*(exp({that:}+ {b0}))*`depvar'/{w1})-({y0})))
					local eqy0ipw_inst instruments(eqy0ipw: )
					local ipw (ipw: ({ipw}-({y1}-{y0})))
					
					matrix `initial' = (`w1s', `bps',`num0ipws', `num1ipws', `attipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqw1ipw' `eqps' `eqy0ipw' `eqy1ipw' `ipw' if `touse' [pw = `samplew'], `eqw1ipw_inst' `eqps_inst' `eqy0ipw_inst' `eqy1ipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `att_ipw' = _b[ipw:_cons]
					matrix `vc_att_ipw' = e(V)
					scalar `r_att_ipw' = rownumb(`vc_att_ipw', "ipw:_cons")
					scalar `var_att_ipw' = `vc_att_ipw'[`r_att_ipw', `r_att_ipw']
					
					tempname muhat01_ipw r_muhat01_ipw var_muhat01_ipw
					scalar `muhat01_ipw' = _b[y0:_cons]
					scalar `r_muhat01_ipw' = rownumb(`vc_att_ipw', "y0:_cons")
					scalar `var_muhat01_ipw' = `vc_att_ipw'[`r_muhat01_ipw', `r_muhat01_ipw']
				}
				else if "`statnorm'"=="nrm" {
					local eqy0nipw (eqy0nipw: ((0.`tvar'*((exp({that:}+ {b0}))))*(`depvar'-({y0}))))
					local eqy0nipw_inst instruments(eqy0nipw: )
					local eqy1nipw (eqy1nipw: (1.`tvar'*(`depvar'-({y1}))))
					local eqy1nipw_inst instruments(eqy1nipw: )
					local nipw (nipw: (1.`tvar'*({nipw}-(({y1})-({y0})))))
					
					matrix `initial' = (`bps', `by0nipw', `num1nipws', `attnipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy0nipw' `eqy1nipw' `nipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0nipw_inst' `eqy1nipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `att_nipw' = _b[nipw:_cons]
					matrix `vc_att_nipw' = e(V)
					scalar `r_att_nipw' = rownumb(`vc_att_nipw', "nipw:_cons")
					scalar `var_att_nipw' = `vc_att_nipw'[`r_att_nipw', `r_att_nipw']
					
					tempname muhat01_nipw r_muhat01_nipw var_muhat01_nipw
					scalar `muhat01_nipw' = _b[y0:_cons]
					scalar `r_muhat01_nipw' = rownumb(`vc_att_nipw', "y0:_cons")
					scalar `var_muhat01_nipw' = `vc_att_nipw'[`r_muhat01_nipw', `r_muhat01_nipw']
				}
			}
			else if "`tmodel'"=="ipt" {
				local eqy0nipw (eqy0nipw: ((0.`tvar'*((exp({that:}+ {b0}))))*(`depvar'-({y0}))))
				local eqy0nipw_inst instruments(eqy0nipw: )
				local eqy1nipw (eqy1nipw: (1.`tvar'*(`depvar'-({y1}))))
				local eqy1nipw_inst instruments(eqy1nipw: )
				local nipw (nipw: (1.`tvar'*({nipw}-(({y1})-({y0})))))
				
				matrix `initial' = (`bps', `by0nipw', `num1nipws', `attnipws')
				local k = colsof(`initial' )
				matrix `I' = I(`k')
				
				gmm `eqps' `eqy0nipw' `eqy1nipw' `nipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0nipw_inst' `eqy1nipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				scalar `att_nipw' = _b[nipw:_cons]
				matrix `vc_att_nipw' = e(V)
				scalar `r_att_nipw' = rownumb(`vc_att_nipw', "nipw:_cons")
				scalar `var_att_nipw' = `vc_att_nipw'[`r_att_nipw', `r_att_nipw']
				
				tempname muhat01_nipw r_muhat01_nipw var_muhat01_nipw
				scalar `muhat01_nipw' = _b[y0:_cons]
				scalar `r_muhat01_nipw' = rownumb(`vc_att_nipw', "y0:_cons")
				scalar `var_muhat01_nipw' = `vc_att_nipw'[`r_muhat01_nipw', `r_muhat01_nipw']
			}
		}
		
		scalar `nob' = e(N)
		local N = `nob'
		
		local N_clust = e(N_clust)
	}
	
	if "`stat'"=="ate" {
		tempname b V
		
		if "`statnorm'"=="unnrm" {
			matrix `b' = (`ate_ipw', `muhat0_ipw')
			matrix `V' = (`var_ate_ipw', 0 \ 0, `var_muhat0_ipw')
		}
		else if "`statnorm'"=="nrm" {
			matrix `b' = (`ate_nipw', `muhat0_nipw')
			matrix `V' = (`var_ate_nipw', 0 \ 0, `var_muhat0_nipw')
		}
		
		matrix rownames `b' = " "
		matrix colnames `b' = "ATE" "POmean"
		matrix rownames `V' = "ATE" "POmean"
		matrix colnames `V' = "ATE" "POmean"
		
		ereturn post `b' `V', obs(`N') esample(`touse')
	}
	else if "`stat'"=="att" {
		tempname b V
		
		if "`statnorm'"=="unnrm" {
			if "`tmodel'"!="ipt" {
				matrix `b' = (`att_ipw', `muhat01_ipw')
				matrix `V' = (`var_att_ipw', 0 \ 0, `var_muhat01_ipw')
			}
			else if "`tmodel'"=="ipt" {
				matrix `b' = (`att_nipw', `muhat01_nipw')
				matrix `V' = (`var_att_nipw', 0 \ 0, `var_muhat01_nipw')
			}
		}
		else if "`statnorm'"=="nrm" {
			matrix `b' = (`att_nipw', `muhat01_nipw')
			matrix `V' = (`var_att_nipw', 0 \ 0, `var_muhat01_nipw')
		}
		
		matrix rownames `b' = " "
		matrix colnames `b' = "ATT" "POmean"
		matrix rownames `V' = "ATT" "POmean"
		matrix colnames `V' = "ATT" "POmean"
		
		ereturn post `b' `V', obs(`N') esample(`touse')
	}
	
	ereturn local enseparator `r(enseparator)'
	ereturn local title "Treatment effect estimation"
	if "`weight'"!="" {
		ereturn local wexp "`exp'"
		ereturn local wtype "`weight'"
	}
	ereturn local stat `stat1'
	ereturn local statnorm `statnorm'
	ereturn local tmodel `tmodel'
	ereturn local cmd teffects2
	ereturn local subcmd ipw
	ereturn local tvar `tvar'
	ereturn local depvar `depvar'
	ereturn local tmodel `tmodel'
	ereturn hidden local fvtvarlist `fvtvarlist'
	ereturn local vce `vce'
	ereturn local vcetype `vcetype'
	ereturn local clustvar `clustvar'
	if `N_clust'!=. ereturn scalar N_clust = `N_clust'
	
	_teffects2_replay, `diopts'
end

capture program drop ParseDepvar
program define ParseDepvar, sclass
	version 17
	
	cap noi syntax varname(numeric)
	
	local rc = c(rc)
	if `rc' {
		if `rc'==103 {
			_teffects2_error_msg, cmd(ipw) case(4) rc(`rc')
		}
		else {
			di as txt "{phang}The outcome model is " ///
			"misspecified.{p_end}"
			exit `rc'
		}
	}
	
	sreturn local depvar `varlist'
end

capture program drop ExtractVarlist
program define ExtractVarlist, sclass
	version 17
	
	cap noi syntax varlist(numeric fv), [ * ]
	
	local rc = c(rc)
	if `rc' {
		_teffects2_error_msg, cmd(ipw) case(5) rc(`rc')
	}
	
	sreturn local varlist `"`varlist'"'
	sreturn local options `"`options'"'
end

exit
