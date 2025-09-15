*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_aipw
program define _teffects2_aipw, byable(onecall)
	version 17
	
	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	_teffects2_parse_canonicalize aipw : `0'
	if `s(eqn_n)'==1 {
		_teffects2_error_msg, cmd(aipw) case(1)
	}
	if `s(eqn_n)'>2 {
		_teffects2_error_msg, cmd(aipw) case(2)
	}
	
	local omodel `"`s(eqn_1)'"'
	local tmodel `"`s(eqn_2)'"'
	local if `"`s(if)'"'
	local in `"`s(in)'"'
	local wt `"`s(wt)'"'
	local options `"`s(options)'"'
	
	`BY' Estimate_aipw `if' `in' `wt', omodel(`omodel') tmodel(`tmodel') `options'
end

capture program drop Estimate_aipw
program define Estimate_aipw, eclass byable(recall)
	version 17
	
	syntax [if] [in] [pw] [, ///
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
		
		_teffects_options aipw : `rest'
		local teopts `s(teopts)'
		local rest `s(rest)'
		if "`rest'"!="" {
			local wc: word count `rest'
			di as err `"{p} `=plural(`wc',"option")' {bf:`rest'} "' ///
			`"`=plural(`wc',"is","are")' not allowed{p_end}"'
			exit 198
		}
		
		_teffects2_getstatsaipw, `ate' `atet' `nrm' `unnrm'
		local stat1 "`s(stat1)'"
		local stat `stat1'
		if "`stat'"=="atet" local stat att
		
		local stat2 "`s(stat2)'"
		local statnorm `stat2'
		
		marksample touse
		_teffects2_count_obs `touse'
		
		if "`weight'"!="" {
			tempvar samplew
			gen double `samplew' `exp' if `touse'
		}
		else if "`pw'"=="" {
			tempvar samplew
			gen double `samplew' = 1 if `touse'==1
		}
		
		ExtractVarlistt `tmodel'
		local tvarlist `s(varlist)'
		local tops `s(options)'
		
		_teffects2_parse_tvarlist `tvarlist', `tops' touse(`touse') stat(`stat') cmd(aipw) binary
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
		
		// Handle IPT-specific normalization
		if "`tmodel'"=="ipt" {
			local statnorm unnrm
		}
		
		// Disallow CBPS for ATT
		if "`tmodel'"=="cbps" & "`stat'"=="att" {
			noi di as error "CBPS not allowed for ATT"
			exit 198
		}
		
		ExtractVarlistd `omodel'
		local dvarlist `s(varlist)'
		local dopts `s(options)'
		
		_teffects2_parse_dvarlist `dvarlist', touse(`touse') wtype(`weight') wvar(`samplew') `dopts'
		
		local depvar `s(depvar)'
		local dvarlist `s(dvarlist)'
		local fvdvarlist `s(fvdvarlist)'
		local kdvar = `s(k)'
		local kfvdvar = `s(kfv)'
		local omodel `s(omodel)'
		local dconstant = "`s(constant)'"==""
		local omodel regress
		
		tempvar ps psxb1 psxb2 ps_1 psxb1_1 psxb2_1 ps_0 psxb1_0 psxb2_0 y1hatw y0hatw wt1 wt0
		tempname bps bps1 bps_1 bps_0 bps1_1 bps1_0 bps2_1 bps2_0 bps2 starting initial I nums num1hats num0hats by1w by0w num1ws num0ws ateipwras bd1 bd0 num1s num0s
		
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
		
		// Expand the factor variable list
		fvexpand `fvtvarlist'
		
		// Store expanded variable list
		local xvarst "`r(varlist)'"
		
		// Start with original xvars
		local cleanedvarst ""
		local tempmapt ""
		
		// Standardize all c.var inside interactions or plain c.var
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
		
		// Tokenize updated xvars and rebuild cleaned varlist safely
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
		
		// Expand the factor variable list
		fvexpand `fvdvarlist'
		
		// Store expanded variable list
		local xvarsy "`r(varlist)'"
		
		// Start with original xvars
		local cleanedvarsy ""
		local tempmapy ""
		
		// Standardize all c.var inside interactions or plain c.var
		local testline "`xvarsy'"
		while regexm("`testline'", "c\.([a-zA-Z0-9_]+)") {
			local match = regexm("`testline'", "c\.([a-zA-Z0-9_]+)")
			local vary = regexs(1)
			local testline = subinstr("`testline'", "c.`vary'", "", 1)
			
			tempvar stdvary
			sum `vary' if `touse'==1 [iw = `samplew']
			gen double `stdvary' = (`vary' - r(mean))/r(sd) if `touse'==1
			
			// Replace in xvars (c.var --> c.stdvar)
			local xvarsy : subinstr local xvarsy "c.`vary'" "c.`stdvary'", all
			local tempmapy `tempmapy' `stdvary'
		}
		
		// Tokenize updated xvars and rebuild cleaned varlist safely
		tokenize "`xvarsy'"
		while "`1'"!="" {
			local token "`1'"
			macro shift
			
			// Default: keep token unchanged
			local newtokeny "`token'"
			
			// Skip interactions, i., c., dummies, etc.
			if !strpos("`token'", "#") & !regexm("`token'", "^[0-9]+[a-z]?\.") & !regexm("`token'", "[\.]") & substr("`token'", 1, 2)!="i." & substr("`token'", 1, 2)!="c." {
				capture confirm variable `token'
				if _rc==0 {
					capture tab `token' if `touse'==1
					if _rc==0 & r(r)>2 {
						// Not binary --> standardize
						tempvar stdvary
						sum `token' if `touse'==1 [iw = `samplew']
						gen double `stdvary' = (`token' - r(mean))/r(sd) if `touse'==1
						
						local newtokeny "`stdvary'"
						local tempmapy `tempmapy' `stdvary'
					}
				}
			}
			
			// Add newtoken to cleaned varlist
			local cleanedvarsy "`cleanedvarsy' `newtokeny'"
		}
		
		// Final cleaned varlist
		local xvarsy "`cleanedvarsy'"
		
		// If estimating ATE
		if "`stat'"=="ate" {
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
				gen double `wt1' = `tvar'/`ps' if `touse'==1
				gen double `wt0' = (1-`tvar')/(1-`ps') if `touse'==1
				
				local eqps (eqps:`tvar' - exp({that:`xvarst'} + {b0})/(1+exp({that:}+ {b0})))
				local eqps_inst instruments(eqps: `xvarst')
			}
			else if "`tmodel'"=="cbps" {
				// Determine starting values from logit
				capture logit `tvar' `xvarst' if `touse'==1 [pw = `samplew']
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
				capture logit `tvar' `xvarst' if `touse'==1 [pw = `samplew']
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
				local link teffects2_aipw##osample:osample
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
			
			// Check whether the weights are ex ante normalized
			tempname wt1m wt0m
			
			sum `wt1' if `touse'==1 [iw = `samplew']
			scalar `wt1m' = round(r(mean), 1e-6)
			sum `wt0' if `touse'==1 [iw = `samplew']
			scalar `wt0m' = round(r(mean), 1e-6)
			
			if "`statnorm'"=="nrm" & `wt1m'==1 & `wt0m'==1 {
				local statnorm unnrm
			}
			
			// Estimation of ATE with estimated propensity score
			if "`statnorm'"=="unnrm" {
				tempvar y1hatr y0hatr term1 term2
				tempname by1r by0r num1aipws num0aipws ateaipws
				
				regress `depvar' `xvarsy' if `tvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1r' = e(b)
				predict double `y1hatr' if `touse'==1
				
				regress `depvar' `xvarsy' if `tvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0r' = e(b)
				predict double `y0hatr' if `touse'==1
				
				tempvar temp11 temp12 temp01 temp02
				tempname temp11s temp12s temp01s temp02s
				
				gen double `temp11' = `tvar'*(`depvar' -`y1hatr')/`ps' if `touse'==1
				sum `temp11' if `touse'==1 [iw = `samplew']
				matrix `temp11s' = r(mean)
				
				gen double `temp12' = `y1hatr' if `touse'==1
				sum `temp12' if `touse'==1 [iw = `samplew']
				matrix `temp12s' = r(mean)
				
				gen double `temp01' = (1-`tvar')*(`depvar' -`y0hatr')/(1-`ps') if `touse'==1
				sum `temp01' if `touse'==1 [iw = `samplew']
				matrix `temp01s' = r(mean)
				
				gen double `temp02' = `y0hatr' if `touse'==1
				sum `temp02' if `touse'==1 [iw = `samplew']
				matrix `temp02s' = r(mean)
				
				gen double `term1' = ((`tvar'*`depvar')-((`tvar'-`ps')*`y1hatr'))/`ps' if `touse'==1
				gen double `term2' = (((1-`tvar')*`depvar')+((`tvar'-`ps')*`y0hatr'))/(1-`ps') if `touse'==1
				
				sum `term1' if `touse'==1 [iw = `samplew']
				matrix `num1aipws' = r(mean)
				sum `term2' if `touse'==1 [iw = `samplew']
				matrix `num0aipws' = r(mean)
				
				matrix `ateaipws' = `num1aipws'-`num0aipws'
			}
			else if "`statnorm'"=="nrm" {
				tempvar y1hatr y0hatr term1 term2
				tempname by1r by0r num1aipws num0aipws ateaipws
				
				regress `depvar' `xvarsy' if `tvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1r' = e(b)
				predict double `y1hatr' if `touse'==1
				
				regress `depvar' `xvarsy' if `tvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0r' = e(b)
				predict double `y0hatr' if `touse'==1
				
				tempvar invw1 invw0 omega1 omega0 term1n term2n
				tempname wr1 wr0 w1s w0s num1naipws num0naipws atenaipws
				
				gen double `invw1' = `tvar'/`ps' if `touse'==1
				gen double `invw0' = (1-`tvar')/(1-`ps') if `touse'==1
				
				sum `invw1' if `touse'==1 [iw = `samplew']
				scalar `wr1' = r(mean)
				sum `invw0' if `touse'==1 [iw = `samplew']
				scalar `wr0' = r(mean)
				sum `invw1' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `invw0' if `touse'==1 [iw = `samplew']
				matrix `w0s' = r(mean)
				
				gen double `omega1' = (`tvar'/`ps')/`wr1' if `touse'==1
				gen double `omega0' = ((1-`tvar')/(1-`ps'))/`wr0' if `touse'==1
				
				tempvar temp11n temp12n temp01n temp02n
				tempname temp11ns temp12ns temp01ns temp02ns
				
				gen double `temp11n' = `omega1'*(`depvar' -`y1hatr') if `touse'==1
				sum `temp11n' if `touse'==1 [iw = `samplew']
				matrix `temp11ns' = r(mean)
				gen double `temp12n' = `y1hatr' if `touse'==1
				sum `temp12n' if `touse'==1 [iw = `samplew']
				matrix `temp12ns' = r(mean)
				
				gen double `temp01n' = `omega0'*(`depvar' -`y0hatr') if `touse'==1
				sum `temp01n' if `touse'==1 [iw = `samplew']
				matrix `temp01ns' = r(mean)
				gen double `temp02n' = `y0hatr' if `touse'==1
				sum `temp02n' if `touse'==1 [iw = `samplew']
				matrix `temp02ns' = r(mean)
				
				gen double `term1n' = `omega1'*(`depvar' -`y1hatr')+`y1hatr' if `touse'==1
				sum `term1n' if `touse'==1 [iw = `samplew']
				matrix `num1naipws' = r(mean)
				
				gen double `term2n' = `omega0'*(`depvar' -`y0hatr')+`y0hatr' if `touse'==1
				sum `term2n' if `touse'==1 [iw = `samplew']
				matrix `num0naipws' = r(mean)
				
				matrix `atenaipws' = `num1naipws'-`num0naipws'
			}
			
			// GMM estimation
			if "`tmodel'"=="ipt" {
				local eqy0aipw (eqy0aipw: ((0.`tvar')*(`depvar'-({y0: `xvarsy'}+{by0}))))
				local eqy0aipw_inst instruments(eqy0aipw: `xvarsy' )
				local eqy1aipw (eqy1aipw: ((1.`tvar')*(`depvar'-({y1: `xvarsy'}+{by1}))))
				local eqy1aipw_inst instruments(eqy1aipw: `xvarsy' )
				
				local num11 (num11: {num11}- ((`tvar'*((1+exp(-({that1:}+ {b1})))))*(`depvar'-({y1:}+{by1}))))
				local num12 (num12: {num12}- ({y1:}+{by1}))
				local num1 (num1: {num1}-((`tvar'*((1+exp(-({that1:}+ {b1})))))*(`depvar'-({y1:}+{by1})))-({y1:}+{by1}))
				
				local num01 (num01: {num01}- (((1-`tvar')/(1/(1+exp({that0:}+ {b0}))))*(`depvar'-({y0:}+{by0}))))
				local num02 (num02: {num02}- ({y0:}+{by0}))
				local num0 (num0: {num0}-(((1-`tvar')*((1+exp({that0:}+ {b0}))))*(`depvar'-({y0:}+{by0})))-({y0:}+{by0}))
				
				local aipw (aipw: {aipw}-({num1}-{num0}))
				
				matrix `initial' = (`bps_0', `bps_1', `by1r', `by0r', `num1aipws', `num0aipws', `ateaipws')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqps0' `eqps1' `eqy1aipw' `eqy0aipw' `num1' `num0' `aipw' if `touse' [pw = `samplew'], `eqps0_inst' `eqps1_inst' `eqy1aipw_inst' `eqy0aipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				scalar `ate_aipw' = _b[aipw:_cons]
				matrix `vc_ate_aipw' = e(V)
				scalar `r_ate_aipw' = rownumb(`vc_ate_aipw', "aipw:_cons")
				scalar `var_ate_aipw' = `vc_ate_aipw'[`r_ate_aipw', `r_ate_aipw']
				
				tempname muhat0_aipw r_muhat0_aipw var_muhat0_aipw
				
				scalar `muhat0_aipw' = _b[num0:_cons]
				scalar `r_muhat0_aipw' = rownumb(`vc_ate_aipw', "num0:_cons")
				scalar `var_muhat0_aipw' = `vc_ate_aipw'[`r_muhat0_aipw', `r_muhat0_aipw']
			}
			else if "`tmodel'"!="ipt" {
				if "`statnorm'"=="unnrm" {
					local eqy0aipw (eqy0aipw: ((0.`tvar')*(`depvar'-({y0: `xvarsy'}+{by0}))))
					local eqy0aipw_inst instruments(eqy0aipw: `xvarsy' )
					local eqy1aipw (eqy1aipw: ((1.`tvar')*(`depvar'-({y1: `xvarsy'}+{by1}))))
					local eqy1aipw_inst instruments(eqy1aipw: `xvarsy' )
					local num1 (num1: {num1}- ((`tvar'*((1+exp(-({that:}+ {b0})))))*(`depvar'-({y1:}+{by1})))-({y1:}+{by1}))
					local num0 (num0: {num0}-(((1-`tvar')*((1+exp({that:}+ {b0}))))*(`depvar'-({y0:}+{by0})))-({y0:}+{by0}))
					local aipw (aipw: {aipw}-({num1}-{num0}) )
					
					matrix `num0s' = `temp01s'+`temp02s'
					matrix `num1s' = `temp11s'+`temp12s'
					
					matrix `initial' = (`bps')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' if `touse'==1 [pw = `samplew'], `eqps_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					matrix `num0s' = `temp01s'+`temp02s'
					matrix `num1s' = `temp11s'+`temp12s'
					
					matrix `initial' = (`bps', `by1r', `by0r', `num0s', `num1s',`ateaipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy1aipw' `eqy0aipw' `num0' `num1' `aipw' if `touse'==1 [pw = `samplew'], `eqps_inst' `eqy1aipw_inst' `eqy0aipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `ate_aipw' = _b[aipw:_cons]
					matrix `vc_ate_aipw' = e(V)
					scalar `r_ate_aipw' = rownumb(`vc_ate_aipw', "aipw:_cons")
					scalar `var_ate_aipw' = `vc_ate_aipw'[`r_ate_aipw', `r_ate_aipw']
					
					tempname muhat0_aipw r_muhat0_aipw var_muhat0_aipw
					
					scalar `muhat0_aipw' = _b[num0:_cons]
					scalar `r_muhat0_aipw' = rownumb(`vc_ate_aipw', "num0:_cons")
					scalar `var_muhat0_aipw' = `vc_ate_aipw'[`r_muhat0_aipw', `r_muhat0_aipw']
				}
				else if "`statnorm'"=="nrm" {
					local eqw1 (eqw1: (((`tvar'*(1+exp(-({that:}+ {b0}))) - {w1}))))
					local eqw1_inst instruments(eqw1: )
					local eqw0 (eqw0: ((((1-`tvar')*((1+exp({that:}+ {b0})))) - {w0})))
					local eqw0_inst instruments(eqw0: )
					
					local eqy0naipw (eqy0naipw: ((0.`tvar')*(`depvar'-({y0: `xvarsy'}+{by0}))))
					local eqy0naipw_inst instruments(eqy0naipw: `xvarsy' )
					
					local eqy1naipw (eqy1naipw: ((1.`tvar')*(`depvar'-({y1: `xvarsy'}+{by1}))))
					local eqy1naipw_inst instruments(eqy1naipw: `xvarsy' )
					
					local num11naipw (num11naipw: {num11naipw}- ((`tvar'*(1+exp(-({that:}+ {b0}))))/{w1})*(`depvar'-({y1:}+{by1})))
					local num12naipw (num12naipw: {num12naipw}- ({y1:}+{by1}))
					local num1naipw (num1naipw: {num1naipw}- (((`tvar'*(1+exp(-({that:}+ {b0}))))/{w1})*(`depvar'-({y1:}+{by1})))-({y1:}+{by1}))
					
					local num01naipw (num01naipw: {num01naipw}- (((1-`tvar')*(1+exp({that:}+ {b0})))/{w0})*(`depvar'-({y0:}+{by0})))
					local num02naipw (num02naipw: {num02naipw}- ({y0:}+{by0}))
					local num0naipw (num0naipw: {num0naipw}- ((((1-`tvar')*(1+exp({that:}+ {b0})))/{w0})*(`depvar'-({y0:}+{by0})))-({y0:}+{by0}))
					local naipw (naipw: {naipw}-({num1naipw}-{num0naipw}))
					
					matrix `initial' = (`bps', `by0r', `by1r', `w1s', `w0s', `num1naipws', `num0naipws', `atenaipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy0naipw' `eqy1naipw' `eqw1' `eqw0' `num1naipw' `num0naipw' `naipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0naipw_inst' `eqy1naipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					matrix `initial' = (`bps', `by0r', `by1r', `w1s', `w0s', `temp11ns', `temp12ns', `num1naipws', `temp01ns', `temp02ns', `num0naipws', `atenaipws')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqps' `eqy0naipw' `eqy1naipw' `eqw1' `eqw0' `num11naipw' `num12naipw' `num1naipw' `num01naipw' `num02naipw' `num0naipw' `naipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0naipw_inst' `eqy1naipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					scalar `ate_naipw' = _b[naipw:_cons]
					matrix `vc_ate_naipw' = e(V)
					scalar `r_ate_naipw' = rownumb(`vc_ate_naipw', "naipw:_cons")
					scalar `var_ate_naipw' = `vc_ate_naipw'[`r_ate_naipw', `r_ate_naipw']
					tempname muhat0_naipw r_muhat0_naipw var_muhat0_naipw
					
					scalar `muhat0_naipw' = _b[num0naipw:_cons]
					scalar `r_muhat0_naipw' = rownumb(`vc_ate_naipw', "num0naipw:_cons")
					scalar `var_muhat0_naipw' = `vc_ate_naipw'[`r_muhat0_naipw', `r_muhat0_naipw']
				}
			}
		}
		else if "`stat'"=="att" {
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
				local link teffects2_aipw##osample:osample
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
			
			// Check whether the weights are ex ante normalized
			tempvar omega1 omega0
			tempname wt1m wt0m w1s w1
			
			sum `tvar' if `touse'==1 [iw = `samplew']
			matrix `w1s' = r(mean)
			sum `tvar' if `touse'==1 [iw = `samplew']
			scalar `w1' = r(mean)
			
			gen double `omega1' = (`tvar')/`w1' if `touse'==1
			gen double `omega0' = (((1-`tvar')*`ps')/(1-`ps'))/`w1' if `touse'==1
			
			sum `omega0' if `touse'==1 [iw = `samplew']
			scalar `wt1m' = round(r(mean), 1e-6)
			
			if "`statnorm'"=="nrm" & `wt1m'==1 {
				local statnorm unnrm
			}
			
			// Estimation of ATT with estimated propensity score
			if "`statnorm'"=="unnrm" {
				tempvar omega1 omega0 y1hatipw y0hatipw
				tempvar y0hatr term2aipw term3aipw term4aipw term31aipw term32aipw atempsvar atempsvar_we num02aipw num01aipw num01aipw_we
				tempname by0r num1aipws num0aipws attaipws w1s w1 num01aipws num02aipws num03aipws num022aipws num021aipws num012aipws atemp_wes
				
				sum `tvar' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `tvar' if `touse'==1 [iw = `samplew']
				scalar `w1' = r(mean)
				
				gen double `omega1' = (`tvar')/`w1' if `touse'==1
				gen double `omega0' = (((1-`tvar')*`ps')/(1-`ps'))/`w1' if `touse'==1
				
				gen double `y1hatipw' = `omega1'*`depvar' if `touse'==1
				sum `y1hatipw' if `touse'==1 [iw = `samplew']
				matrix `num1aipws' = r(mean)
				
				regress `depvar' `xvarsy' if `tvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0r' = e(b)
				predict double `y0hatr' if `touse'==1
				
				gen double `num01aipw' = (((1-`tvar')*`ps')/(1-`ps'))*(`depvar'-`y0hatr') if `touse'==1
				
				gen double `num01aipw_we' = `num01aipw'/`w1' if `touse'==1
				sum `num01aipw_we' [iw = `samplew']
				matrix `num01aipws' = r(mean)
				
				gen double `num02aipw' = `tvar'*`y0hatr'/`w1' if `touse'==1
				sum `num02aipw' if `touse'==1 [iw = `samplew']
				matrix `num02aipws' = r(mean)
				
				matrix `attaipws' = `num1aipws'-(`num01aipws'+`num02aipws')
			}
			else if "`statnorm'"=="nrm" {
				tempvar omega1 omega0 y1hatipw y0hatr term2naipw term21naipw term22naipw attweight num02aipw num01naipw num01naipw_we
				tempname w1s w1 w1naipw w1snaipw w0naipw w0snaipw by0r num1aipws num02aipw num02aipws attnaipws num01naipws num02naipws wnorms wnorms_s num01naipws
				
				sum `tvar' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `tvar' if `touse'==1 [iw = `samplew']
				scalar `w1' = r(mean)
				
				gen double `omega1' = (`tvar')/`w1' if `touse'==1
				gen double `omega0' = (((1-`tvar')*`ps')/(1-`ps'))/`w1' if `touse'==1
				gen double `y1hatipw' = `omega1'*`depvar' if `touse'==1
				
				sum `y1hatipw' if `touse'==1 [iw = `samplew']
				matrix `num1aipws' = r(mean)
				
				regress `depvar' `xvarsy' if `tvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0r' = e(b)
				predict double `y0hatr' if `touse'==1
				
				gen double `num02aipw' = `tvar'*`y0hatr'/`w1' if `touse'==1
				sum `num02aipw' if `touse'==1 [iw = `samplew']
				matrix `num02aipws' = r(mean)
				
				gen double `attweight' = (((1-`tvar')*`ps')/(1-`ps')) if `touse'==1
				
				sum `attweight' if `touse'==1 [iw = `samplew']
				matrix `wnorms' = r(mean)
				sum `attweight' if `touse'==1 [iw = `samplew']
				scalar `wnorms_s' = r(mean)
				gen double `num01naipw' = (((1-`tvar')*`ps')/(1-`ps'))*(`depvar'-`y0hatr') if `touse'==1
				
				gen double `num01naipw_we' = `num01naipw'/`wnorms_s' if `touse'==1
				
				sum `num01naipw_we' if `touse'==1 [iw = `samplew']
				matrix `num01naipws' = r(mean)
				
				matrix `attnaipws' = `num1aipws'-(`num01naipws'+`num02aipws')
			}
			
			// GMM estimation
			if "`statnorm'"=="unnrm" {
				local eqw1aipw (eqw1aipw: (`tvar' - {w1}))
				local eqw1aipw_inst instruments(eqw1aipw: )
				
				local eqy1aipw (eqy1aipw: (1.`tvar')*(`depvar'- ({y1m})))
				local eqy1aipw_inst instruments(eqy1aipw: )
				
				local eqy0aipw (eqy0aipw: ((0.`tvar')*(`depvar'-({y0:`xvarsy'}+{by0}))))
				local eqy0aipw_inst instruments(eqy0aipw: `xvarsy' )
				
				local eqatempw (eqatempw: ((exp({that:}+{b0})*(1-`tvar')*(`depvar'-({y0:}+{by0})))/{w1}-{atempw}))
				local eqbtempw (eqbtempw: `tvar'*({y0:}+{by0})/{w1}-{btempw})
				
				local eqden (eqden: {secondt}-(((exp({that:}+{b0})*(1-`tvar')*(`depvar'-({y0:}+{by0})))/{w1})+(`tvar'*({y0:}+{by0})/{w1})))
				local aipw (aipw: ({aipw}-({y1m}-({secondt}))))
				
				tempname secondts
				matrix `secondts' = `num01aipws' + `num02aipws'
				
				matrix `initial' = (`bps', `w1s', `by0r', `num1aipws', `secondts', `attaipws')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqps' `eqw1aipw' `eqy0aipw' `eqy1aipw' `eqden' `aipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0aipw_inst' `eqy1aipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				scalar `att_aipw' = _b[aipw:_cons]
				matrix `vc_att_aipw' = e(V)
				scalar `r_att_aipw' = rownumb(`vc_att_aipw', "aipw:_cons")
				scalar `var_att_aipw' = `vc_att_aipw'[`r_att_aipw', `r_att_aipw']
				
				tempname muhat01_aipw r_muhat01_aipw var_muhat01_aipw
				scalar `muhat01_aipw' = _b[secondt:_cons]
				scalar `r_muhat01_aipw' = rownumb(`vc_att_aipw', "secondt:_cons")
				scalar `var_muhat01_aipw' = `vc_att_aipw'[`r_muhat01_aipw', `r_muhat01_aipw']
			}
			else if "`statnorm'"=="nrm" {
				local eqw1aipw (eqw1aipw: (`tvar' - {w1}))
				local eqw1aipw_inst instruments(eqw1aipw: )
				
				local eqwnormaipw (eqwnormaipw: ((1-`tvar')*exp({that:}+{b0}) - {wnorm}))
				local eqwnormaipw_inst instruments(eqwnormaipw: )
				
				local eqy1aipw (eqy1aipw: (1.`tvar')*(`depvar'- ({y1m})))
				local eqy1aipw_inst instruments(eqy1aipw: )
				
				local eqy0aipw (eqy0aipw: ((0.`tvar')*(`depvar'-({y0: `xvarsy'}+{by0}))))
				local eqy0aipw_inst instruments(eqy0aipw: `xvarsy' )
				
				local eqdenw (eqdenw: {secondtw}-(((exp({that:}+{b0})*(1-`tvar')*(`depvar'-({y0:}+{by0})))/{wnorm})+`tvar'*({y0:}+{by0})/{w1}))
				
				local naipw (naipw: ({naipw}-({y1m}-{secondtw})))
				
				tempname secondtws
				matrix `secondtws' = `num01naipws' + `num02aipws'
				
				matrix `initial' = (`bps', `w1s', `wnorms', `by0r', `num1aipws', `secondtws', `attnaipws')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqps' `eqw1aipw' `eqwnormaipw' `eqy0aipw' `eqy1aipw' `eqdenw' `naipw' if `touse' [pw = `samplew'], `eqps_inst' `eqy0aipw_inst' `eqy1aipw_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				scalar `att_naipw' = _b[naipw:_cons]
				matrix `vc_att_naipw' = e(V)
				scalar `r_att_naipw' = rownumb(`vc_att_naipw', "naipw:_cons")
				scalar `var_att_naipw' = `vc_att_naipw'[`r_att_naipw', `r_att_naipw']
				
				tempname muhat01_naipw r_muhat01_naipw var_muhat01_naipw
				scalar `muhat01_naipw' = _b[secondtw:_cons]
				scalar `r_muhat01_naipw' = rownumb(`vc_att_naipw', "secondtw:_cons")
				scalar `var_muhat01_naipw' = `vc_att_naipw'[`r_muhat01_naipw', `r_muhat01_naipw']
			}
		}
		
		scalar `nob' = e(N)
		local N = `nob'
		
		local N_clust = e(N_clust)
	}
	
	if "`stat'"=="ate" {
		tempname b V
		
		if "`statnorm'"=="unnrm" {
			matrix `b' = (`ate_aipw', `muhat0_aipw')
			matrix `V' = (`var_ate_aipw', 0 \ 0, `var_muhat0_aipw')
		}
		else if "`statnorm'"=="nrm" {
			matrix `b' = (`ate_naipw', `muhat0_naipw')
			matrix `V' = (`var_ate_naipw', 0 \ 0, `var_muhat0_naipw')
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
			matrix `b' = (`att_aipw', `muhat01_aipw')
			matrix `V' = (`var_att_aipw', 0 \ 0, `var_muhat01_aipw')
		}
		else if "`statnorm'"=="nrm" {
			matrix `b' = (`att_naipw', `muhat01_naipw')
			matrix `V' = (`var_att_naipw', 0 \ 0, `var_muhat01_naipw')
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
	ereturn local subcmd aipw
	ereturn local tvar `tvar'
	ereturn local depvar `depvar'
	ereturn local tmodel `tmodel'
	ereturn local omodel linear
	ereturn hidden local fvtvarlist `fvtvarlist'
	ereturn hidden local fvdvarlist `fvdvarlist'
	ereturn local vce `vce'
	ereturn local vcetype `vcetype'
	ereturn local clustvar `clustvar'
	if `N_clust'!=. ereturn scalar N_clust = `N_clust'
	
	_teffects2_replay, `diopts'
end

capture program drop ExtractVarlistt
program define ExtractVarlistt, sclass
	version 17
	
	cap noi syntax varlist(numeric fv), [ * ]
	local rc = c(rc)
	if `rc' {
		_teffects2_error_msg, cmd(ipw) case(5) rc(`rc')
	}
	
	sreturn local varlist `"`varlist'"'
	sreturn local options `"`options'"'
end

capture program drop ExtractVarlistd
program define ExtractVarlistd, sclass
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
