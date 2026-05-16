*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop drlate_estimate_late
program define drlate_estimate_late, eclass
	version 17
	
	syntax, yvar(name) tvar(name) zvar(name) ///
		omodel(string) tmodel(string) zmodel(string) ///
		method(string) statnorm(string) ///
		touse(name) samplew(name) ips(name) ///
		wt1(name) wt0(name) ///
		dmeanz1(name) dmeanz0(name) ///
		bips(name) bips1(name) bips0(name) ///
		vce(string) ///
		[ ymodelvars(string) tmodelvars(string) zmodelvars(string) ///
		gmmopts(string) iteropt(string) ]

	// -----------------------------------------------
	// Rebuild eqips strings locally
	// -----------------------------------------------
	if "`zmodel'" == "logit" {
		local eqips (eqips: `zvar' - exp({zhat:`zmodelvars' _cons})/(1+exp({zhat:})))
		local eqips_inst instruments(eqips: `zmodelvars')
	}
	else if "`zmodel'" == "cbps" {
		local eqips (eqips: (`zvar'/(exp({zhat:`zmodelvars' _cons})/(1+exp({zhat:})))-(1-`zvar')/(1/(1+exp({zhat:})))))
		local eqips_inst instruments(eqips: `zmodelvars')
	}
	else if "`zmodel'" == "ipt" {
		local eqips1 (eqips1: (`zvar'*(1+exp({zhat1:`zmodelvars' _cons}))/(exp({zhat1:})) - 1))
		local eqips1_inst instruments(eqips1: `zmodelvars')
		local eqips0 (eqips0: ((1-`zvar')*(1+exp({zhat0:`zmodelvars' _cons})) - 1))
		local eqips0_inst instruments(eqips0: `zmodelvars')
	}
	
	quietly {
		// -----------------------------------------------
		// Shared tempnames and tempvars
		// -----------------------------------------------
		tempname by1 by0 bd1 bd0 denom02s denom01s denom12s denom11s
		tempname denom1s denom0s num1s num0s nums num02s num01s num12s num11s denoms lates late_scalar
		tempname initial I wr1 wr0 w1s w0s
		tempvar y1hat y0hat d1hat d0hat omega1 omega0 num02 num01 num11 num12 num1 num0
		tempvar invw1 invw0 denom02 denom01 denom11 denom12 denom1 denom0
		
		// -----------------------------------------------
		// METHOD: IPWRA
		// -----------------------------------------------
		if "`method'" == "ipwra" {
			if "`statnorm'" == "unnrm" {
				local `statnorm' nrm
			}
			
			`omodel' `yvar' `ymodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew'/`ips']
			matrix `by1' = e(b)
			predict double `y1hat'
			
			`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew'/(1-`ips')]
			matrix `by0' = e(b)
			predict double `y0hat'
			
			if `dmeanz1'==1 {
				gen double `d1hat' = 1
			}
			else if `dmeanz1'==0 {
				gen double `d1hat' = 0
			}
			else {
				`tmodel' `tvar' `tmodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew'/`ips']
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
				`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew'/(1-`ips')]
				matrix `bd0' = e(b)
				predict double `d0hat'
			}
			
			sum `d1hat' if `touse'==1 [iw = `samplew']
			scalar `denom1s' = r(mean)
			sum `d0hat' if `touse'==1 [iw = `samplew']
			scalar `denom0s' = r(mean)
			sum `y1hat' if `touse'==1 [iw = `samplew']
			scalar `num1s' = r(mean)
			sum `y0hat' if `touse'==1 [iw = `samplew']
			scalar `num0s' = r(mean)
			
			scalar `nums' = `num1s' - `num0s'
			scalar `denoms' = `denom1s' - `denom0s'
			scalar `late_scalar' = `nums' / `denoms'
			matrix `denoms' = `denoms'
			matrix `lates' = `late_scalar'
			
			// --- zmodel != ipt ---
			if "`zmodel'" != "ipt" {
				if "`omodel'" == "regress" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat:})))*(`yvar'-({y0:`ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat:})))*(`yvar'-({y1:`ymodelvars' _cons}))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-(({y1:})-({y0:})))
				}
				else if "`omodel'" == "logit" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat:})))*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:})))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat:})))*(`yvar'-exp({y1:`ymodelvars' _cons})/(1+exp({y1:})))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-(((exp({y1:})/(1+exp({y1:}))))-((exp({y0:})/(1+exp({y0:}))))))
				}
				else if "`omodel'" == "poisson" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat:})))*(`yvar'-exp({y0:`ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat:})))*(`yvar'-exp({y1:`ymodelvars' _cons}))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-((exp({y1:}))-(exp({y0:}))))
				}
				
				if "`tmodel'" == "logit" {
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat:})))*(`tvar'-exp({d1:`tmodelvars' _cons})/(1+exp({d1:})))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat:})))*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:})))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-(((exp({d1:})/(1+exp({d1:}))))-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-((exp({d0:})/(1+exp({d0:}))))))
					}
					else if (`dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1) {
						local denom (denom: {denom}-(((exp({d1:})/(1+exp({d1:}))))-((exp({d0:})/(1+exp({d0:}))))))
					}
				}
				else if "`tmodel'" == "poisson" {
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat:})))*(`tvar'-exp({d1:`tmodelvars' _cons}))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat:})))*(`tvar'-exp({d0:`tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-((exp({d1:}))-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-(exp({d0:}))))
					}
					else if (`dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1) {
						local denom (denom: {denom}-((exp({d1:}))-(exp({d0:}))))
					}
				}
				else if "`tmodel'" == "regress" {
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat:})))*(`tvar'-({d0:`tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat:})))*(`tvar'-({d1:`tmodelvars' _cons}))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-(({d1:})-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-({d0:})))
					}
					else if (`dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1) {
						local denom (denom: {denom}-(({d1:})-({d0:})))
					}
				}
				
				local late (late: ({late} - {num}/{denom}))
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					matrix `initial' = (`bips', `by0', `by1', `nums', `bd1', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if `dmeanz1'==0 | `dmeanz1'==1 {
					matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
					matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `bd1', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
			}
			
			// --- zmodel == ipt ---
			else if "`zmodel'" == "ipt" {
				if "`omodel'" == "regress" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat0:})))*(`yvar'-({y0:`ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`yvar'-({y1:`ymodelvars' _cons}))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-(({y1:})-({y0:})))
				}
				else if "`omodel'" == "logit" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat0:})))*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:})))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`yvar'-exp({y1:`ymodelvars' _cons})/(1+exp({y1:})))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-(((exp({y1:})/(1+exp({y1:}))))-((exp({y0:})/(1+exp({y0:}))))))
				}
				else if "`omodel'" == "poisson" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat0:})))*(`yvar'-exp({y0:`ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars')
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`yvar'-exp({y1:`ymodelvars' _cons}))))
					local eqy1_inst instruments(eqy1: `ymodelvars')
					local num (num: {num}-((exp({y1:}))-(exp({y0:}))))
				}
				
				if "`tmodel'" == "logit" {
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`tvar'-exp({d1:`tmodelvars' _cons})/(1+exp({d1:})))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat0:})))*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:})))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-(((exp({d1:})/(1+exp({d1:}))))-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-((exp({d0:})/(1+exp({d0:}))))))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-(((exp({d1:})/(1+exp({d1:}))))-((exp({d0:})/(1+exp({d0:}))))))
					}
				}
				else if "`tmodel'" == "poisson" {
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`tvar'-exp({d1:`tmodelvars' _cons}))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat0:})))*(`tvar'-exp({d0:`tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-((exp({d1:}))-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-(exp({d0:}))))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-((exp({d1:}))-(exp({d0:}))))
					}
				}
				else if "`tmodel'" == "regress" {
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat0:})))*(`tvar'-({d0:`tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars')
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`tvar'-({d1:`tmodelvars' _cons}))))
					local eqd1_inst instruments(eqd1: `tmodelvars')
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-(({d1:})-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-({d0:})))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-(({d1:})-({d0:})))
					}
				}
				
				local late (late: ({late} - {num}/{denom}))
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd1', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if `dmeanz1'==0 | `dmeanz1'==1 {
					matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd0', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
					matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd0', `bd1', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
			}
		}
		
		// -----------------------------------------------
		// METHOD: IPW
		// -----------------------------------------------
		else if "`method'" == "ipw" {
			if "`statnorm'" == "nrm" {
				regress `yvar' if `zvar'==1 & `touse'==1 [pw = `samplew'/`ips']
				matrix `by1' = e(b)
				predict double `y1hat'
				
				regress `yvar' if `zvar'==0 & `touse'==1 [pw = `samplew'/(1-`ips')]
				matrix `by0' = e(b)
				predict double `y0hat'
				
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
				}
				else {
					regress `tvar' if `zvar'==1 & `touse'==1 [pw = `samplew'/`ips']
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
					regress `tvar' if `zvar'==0 & `touse'==1 [pw = `samplew'/(1-`ips')]
					matrix `bd0' = e(b)
					predict double `d0hat'
				}
				
				sum `d1hat' if `touse'==1 [iw = `samplew']
				scalar `denom1s' = r(mean)
				sum `d0hat' if `touse'==1 [iw = `samplew']
				scalar `denom0s' = r(mean)
				sum `y1hat' if `touse'==1 [iw = `samplew']
				scalar `num1s' = r(mean)
				sum `y0hat' if `touse'==1 [iw = `samplew']
				scalar `num0s' = r(mean)
				
				scalar `nums' = `num1s' - `num0s'
				scalar `denoms' = `denom1s' - `denom0s'
				scalar `late_scalar' = `nums' / `denoms'
				matrix `denoms' = `denoms'
				matrix `lates' = `late_scalar'
				
				if "`zmodel'" != "ipt" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat:})))*(`yvar'-({y0: _cons}))))
					local eqy0_inst instruments(eqy0: )
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat:})))*(`yvar'-({y1: _cons}))))
					local eqy1_inst instruments(eqy1: )
					local num (num: {num}-(({y1:})-({y0:})))
					
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat:})))*(`tvar'-({d0: _cons}))))
					local eqd0_inst instruments(eqd0: )
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat:})))*(`tvar'-({d1: _cons}))))
					local eqd1_inst instruments(eqd1: )
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-{d0:}))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-{d0:}))
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips', `by0', `by1', `nums', `bd1', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `bd1', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
				else if "`zmodel'" == "ipt" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat0:})))*(`yvar'-({y0: _cons}))))
					local eqy0_inst instruments(eqy0:)
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`yvar'-({y1: _cons}))))
					local eqy1_inst instruments(eqy1:)
					local num (num: {num}-(({y1:})-({y0:})))
					
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat0:})))*(`tvar'-({d0: _cons}))))
					local eqd0_inst instruments(eqd0:)
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`tvar'-({d1: _cons}))))
					local eqd1_inst instruments(eqd1:)
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-{d0:}))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-{d0:}))
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd1', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd0', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `nums', `bd0', `bd1', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
			}
			else if "`statnorm'" == "unnrm" {
				tempvar y1ipw y0ipw d1ipw d0ipw
				tempname num1ipws num0ipws numipws
				
				gen double `y1ipw' = `wt1'*`yvar' if `touse'==1
				gen double `y0ipw' = `wt0'*`yvar' if `touse'==1
				
				sum `y1ipw' if `touse'==1 [iw = `samplew']
				matrix `num1ipws' = r(mean)
				
				sum `y0ipw' if `touse'==1 [iw = `samplew']
				matrix `num0ipws' = r(mean)
				matrix `numipws' = `num1ipws' - `num0ipws'
				
				if `dmeanz1'==1 {
					gen double `d1ipw' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1ipw' = 0
				}
				else {
					gen double `d1ipw' = `wt1'*`tvar' if `touse'==1
				}
				
				if `dmeanz0'==0 {
					gen double `d0ipw' = 0
				}
				else if `dmeanz0'==1 {
					gen double `d0ipw' = 1
				}
				else {
					gen double `d0ipw' = `wt0'*`tvar' if `touse'==1
				}
				
				sum `d1ipw' if `touse'==1 [iw = `samplew']
				scalar `denom1s' = r(mean)
				sum `d0ipw' if `touse'==1 [iw = `samplew']
				scalar `denom0s' = r(mean)
				scalar `denoms' = `denom1s' - `denom0s'
				matrix `denoms' = `denoms'
				matrix `lates' = `numipws' * inv(`denoms')
				
				if "`zmodel'" != "ipt" {
					local eqy0ipw (eqy0ipw: (((1-`zvar')*((1+exp({zhat:}))))*`yvar')-({y0}))
					local eqy0ipw_inst instruments(eqy0ipw: )
					local num (num: {num}-(((`zvar'*((1+exp(-{zhat:}))))*`yvar')-(((1-`zvar')*((1+exp({zhat:}))))*`yvar')))
					
					local eqd0ipw (eqd0ipw: (((1-`zvar')*((1+exp({zhat:}))))*`tvar')-({d0}))
					local eqd0ipw_inst instruments(eqd0ipw: )
					local eqd1ipw (eqd1ipw: ((`zvar'*((1+exp(-{zhat:}))))*`tvar')-({d1}))
					local eqd1ipw_inst instruments(eqd1ipw: )
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-(((`zvar'*((1+exp(-{zhat:}))))*`tvar')-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-(((1-`zvar')*((1+exp({zhat:}))))*`tvar')))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-(((`zvar'*((1+exp(-{zhat:}))))*`tvar')-(((1-`zvar')*((1+exp({zhat:}))))*`tvar')))
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips', `num0ipws', `numipws', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0ipw' `num' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0ipw_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips', `num0ipws', `numipws', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0ipw' `num' `eqd0ipw' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0ipw_inst' `eqd0ipw_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips', `num0ipws', `numipws', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0ipw' `num' `eqd0ipw' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0ipw_inst' `eqd0ipw_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
				else if "`zmodel'" == "ipt" {
					local eqy0 (eqy0: ((0.`zvar'*(1+exp({zhat0:})))*(`yvar'-({y0: _cons}))))
					local eqy0_inst instruments(eqy0:)
					local eqy1 (eqy1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`yvar'-({y1: _cons}))))
					local eqy1_inst instruments(eqy1:)
					local num (num: {num}-(({y1:})-({y0:})))
					
					local eqd0 (eqd0: ((0.`zvar'*(1+exp({zhat0:})))*(`tvar'-({d0: _cons}))))
					local eqd0_inst instruments(eqd0:)
					local eqd1 (eqd1: ((1.`zvar'*(1+exp(-{zhat1:})))*(`tvar'-({d1: _cons}))))
					local eqd1_inst instruments(eqd1:)
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						local denom (denom: {denom}-(`dmeanz1'-{d0:}))
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-{d0:}))
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips1', `bips0', `num0ipws', `num1ipws', `numipws', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips1', `bips0', `num0ipws', `num1ipws', `numipws', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips1', `bips0', `num0ipws', `num1ipws', `numipws', `denom0s', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
			}
		}
		
		// -----------------------------------------------
		// METHOD: AIPW
		// -----------------------------------------------
		else if "`method'" == "aipw" {
			if "`zmodel'" == "ipt" & "`statnorm'" == "nrm" {
				noi di as txt "IPT weights are ex-ante normalized; switching to unnormalized moments."
				local statnorm unnrm
			}
			if "`statnorm'" == "unnrm" {
				`omodel' `yvar' `ymodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1' = e(b)
				predict double `y1hat'
				
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0' = e(b)
				predict double `y0hat'
				
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
				}
				else {
					`tmodel' `tvar' `tmodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
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
					`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
					matrix `bd0' = e(b)
					predict double `d0hat'
				}
				
				tempvar term1 term2 term1d term2d
				gen double `term1' = ((`zvar'*`yvar')-((`zvar'-`ips')*`y1hat'))/`ips'
				gen double `term2' = (((1-`zvar')*`yvar')+((`zvar'-`ips')*`y0hat'))/(1-`ips')
				sum `term1' if `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				sum `term2' if `touse'==1 [iw = `samplew']
				matrix `num0s' = r(mean)
				matrix `nums' = `num1s'-`num0s'
				
				gen double `term1d' = ((`zvar'*`tvar')-((`zvar'-`ips')*`d1hat'))/`ips'
				gen double `term2d' = (((1-`zvar')*`tvar')+((`zvar'-`ips')*`d0hat'))/(1-`ips')
				sum `term1d' if `touse'==1 [iw = `samplew']
				matrix `denom1s' = r(mean)
				sum `term2d' if `touse'==1 [iw = `samplew']
				matrix `denom0s' = r(mean)
				
				matrix `denoms' = `denom1s'-`denom0s'
				matrix `lates' = `nums'*inv(`denoms')
				
				if "`zmodel'" != "ipt" {
					if "`omodel'" == "regress" {
						local eqy0 (eqy0: ((0.`zvar'*(`yvar'-({y0:`ymodelvars' _cons})))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: ((1.`zvar'*(`yvar'-({y1:`ymodelvars' _cons})))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat:})))))*(`yvar'-({y1:})))-({y1:}))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat:}))))*(`yvar'-({y0:})))-({y0:}))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "logit" {
						local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:}))))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})/(1+exp({y1:}))))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat:})))))*(`yvar'-((exp({y1:})/(1+exp({y1:}))))))-(exp({y1:})/(1+exp({y1:}))))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat:}))))*(`yvar'-((exp({y0:})/(1+exp({y0:}))))))-(exp({y0:})/(1+exp({y0:}))))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "poisson" {
						local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat:})))))*(`yvar'-(exp({y1:}))))-(exp({y1:})))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat:}))))*(`yvar'-(exp({y0:}))))-(exp({y0:})))
						local num (num: {num}-({num1}-{num0}))
					}
					
					if "`tmodel'" == "logit" {
						local eqd1 (eqd1: ((1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons})/(1+exp({d1:}))))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:}))))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-((exp({d1:})/(1+exp({d1:}))))))-(exp({d1:})/(1+exp({d1:}))))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-(exp({d0:})/(1+exp({d0:}))))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-((exp({d1:})/(1+exp({d1:}))))))-(exp({d1:})/(1+exp({d1:}))))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-(exp({d0:})/(1+exp({d0:}))))
							local denom (denom: {denom}-((((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-((exp({d1:})/(1+exp({d1:}))))))+(exp({d1:})/(1+exp({d1:})))) - ((((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-((exp({d0:})/(1+exp({d0:})))))) + (exp({d0:})/(1+exp({d0:}))))))
						}
					}
					else if "`tmodel'" == "poisson" {
						local eqd1 (eqd1: ((1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons})))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-((((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-(exp({d1:})))) + (exp({d1:}))) - ((((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-(exp({d0:})))) + (exp({d0:})))))
						}
					}
					else if "`tmodel'" == "regress" {
						local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1:`tmodelvars' _cons})))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: ((0.`zvar'*(`tvar'-({d0:`tmodelvars' _cons})))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*(1+exp(-({zhat:}))))*(`tvar'-({d1:})))-(({d1:})))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-({d0:})))-(({d0:})))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-({d1:})))-(({d1:})))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-({d0:})))-(({d0:})))
							local denom (denom: {denom}-((((`zvar'*((1+exp(-({zhat:})))))*(`tvar'-({d1:}))) + ({d1:})) - ((((1-`zvar')*((1+exp({zhat:}))))*(`tvar'-({d0:}))) + ({d0:}))))
						}
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips', `by0', `by1', `num0s', `num1s', `nums', `bd1', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num0' `num1' `num' `eqd1' `denom1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips', `by0', `by1', `num0s', `num1s', `nums', `bd0', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `denom0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips', `by0', `by1', `num0s', `num1s', `nums', `bd0', `bd1', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `eqd1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
				else if "`zmodel'" == "ipt" {
					if "`omodel'" == "regress" {
						local eqy0 (eqy0: (0.`zvar'*(`yvar'-({y0:`ymodelvars' _cons}))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: (1.`zvar'*(`yvar'-({y1:`ymodelvars' _cons}))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat1:})))))*(`yvar'-({y1:})))-({y1:}))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`yvar'-({y0:})))-({y0:}))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "logit" {
						local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:}))))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})/(1+exp({y1:}))))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat1:})))))*(`yvar'-((exp({y1:})/(1+exp({y1:}))))))-(exp({y1:})/(1+exp({y1:}))))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`yvar'-((exp({y0:})/(1+exp({y0:}))))))-(exp({y0:})/(1+exp({y0:}))))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "poisson" {
						local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})))))
						local eqy0_inst instruments(eqy0: `ymodelvars')
						local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})))))
						local eqy1_inst instruments(eqy1: `ymodelvars')
						local num1 (num1: {num1}-((`zvar'*((1+exp(-({zhat1:})))))*(`yvar'-(exp({y1:}))))-(exp({y1:})))
						local num0 (num0: {num0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`yvar'-(exp({y0:}))))-(exp({y0:})))
						local num (num: {num}-({num1}-{num0}))
					}
					
					if "`tmodel'" == "logit" {
						local eqd1 (eqd1: (1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons})/(1+exp({d1:})))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: (0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:})))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-((exp({d1:})/(1+exp({d1:}))))))-(exp({d1:})/(1+exp({d1:}))))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-(exp({d0:})/(1+exp({d0:}))))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-((exp({d1:})/(1+exp({d1:}))))))-(exp({d1:})/(1+exp({d1:}))))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-(exp({d0:})/(1+exp({d0:}))))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					else if "`tmodel'" == "poisson" {
						local eqd1 (eqd1: (1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons}))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: (0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons}))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					else if "`tmodel'" == "regress" {
						local eqd1 (eqd1: (1.`zvar'*(`tvar'-({d1:`tmodelvars' _cons}))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						local eqd0 (eqd0: (0.`zvar'*(`tvar'-({d0:`tmodelvars' _cons}))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-({d1:})))-(({d1:})))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-({d0:})))-(({d0:})))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}-((`zvar'*((1+exp(-({zhat1:})))))*(`tvar'-({d1:})))-(({d1:})))
							local denom0 (denom0: {denom0}-(((1-`zvar')*((1+exp({zhat0:}))))*(`tvar'-({d0:})))-(({d0:})))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					if `dmeanz0'==0 | `dmeanz0'==1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `num0s', `num1s', `nums', `bd1', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num0' `num1' `num' `eqd1' `denom1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz1'==0 | `dmeanz1'==1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `num0s', `num1s', `nums', `bd0', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `denom0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips1', `bips0', `by0', `by1', `num0s', `num1s', `nums', `bd0', `bd1', `denom0s', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips1' `eqips0' `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `eqd1' `denom0' `denom1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips1_inst' `eqips0_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
			}
			else if "`statnorm'" == "nrm" {
				// Outcome regressions
				// Z=1
				`omodel' `yvar' `ymodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1' = e(b)
				predict double `y1hat' if `touse'==1
				
				// Z=0
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0' = e(b)
				predict double `y0hat' if `touse'==1
				
				gen double `invw1' = `zvar'/`ips' if `touse'==1
				gen double `invw0' = (1-`zvar')/(1-`ips') if `touse'==1
				sum `invw1' if `touse'==1 [iw = `samplew']
				scalar `wr1' = r(mean)
				sum `invw0' if `touse'==1 [iw = `samplew']
				scalar `wr0' = r(mean)
				sum `invw1' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `invw0' if `touse'==1 [iw = `samplew']
				matrix `w0s' = r(mean)
				
				// Generate normalized weights
				gen double `omega1' = (`zvar'/`ips')/`wr1' if `touse'==1
				gen double `omega0' = ((1-`zvar')/(1-`ips'))/`wr0' if `touse'==1
				
				// Z=1, weighted residuals
				gen double `num11' = `omega1'*(`yvar' -`y1hat') if `touse'==1
				sum `num11' if `touse'==1 [iw = `samplew']
				matrix `num11s' = r(mean)
				
				// Z=1, augmentation with outcome predictions
				gen double `num12' = `y1hat' if `touse'==1
				sum `num12' if `touse'==1 [iw = `samplew']
				matrix `num12s' = r(mean)
				
				// Z=0, weighted residuals
				gen double `num01' = `omega0'*(`yvar' -`y0hat') if `touse'==1
				sum `num01' if `touse'==1 [iw = `samplew']
				matrix `num01s' = r(mean)
				
				// Z=0, augmentation with outcome predictions
				gen double `num02' = `y0hat' if `touse'==1
				sum `num02' if `touse'==1 [iw = `samplew']
				matrix `num02s' = r(mean)
				
				gen double `num1' = `omega1'*(`yvar' -`y1hat')+`y1hat' if `touse'==1
				sum `num1' if `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				
				gen double `num0' = `omega0'*(`yvar' -`y0hat')+`y0hat' if `touse'==1
				sum `num0' if `touse'==1 [iw = `samplew']
				matrix `num0s' = r(mean)
				
				matrix `nums' = `num1s'-`num0s'
				
				// Treatment regressions
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
				}
				else {
					`tmodel' `tvar' `tmodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
					matrix `bd1' = e(b)
					predict double `d1hat' if `touse'==1
				}
				
				if `dmeanz0'==0 {
					gen double `d0hat' = 0
				}
				else if `dmeanz0'==1 {
					gen double `d0hat' = 1
				}
				else {
					`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
					matrix `bd0' = e(b)
					predict double `d0hat' if `touse'==1
				}
				
				// Z=1, weighted residuals
				gen double `denom11' = `omega1'*(`tvar' -`d1hat') if `touse'==1
				sum `denom11' if `touse'==1 [iw = `samplew']
				matrix `denom11s' = r(mean)
				
				// Z=1, augmentation with outcome predictions
				gen double `denom12' = `d1hat' if `touse'==1
				sum `denom12' if `touse'==1 [iw = `samplew']
				matrix `denom12s' = r(mean)
				
				// Z=0, weighted residuals
				gen double `denom01' = `omega0'*(`tvar' -`d0hat') if `touse'==1
				sum `denom01' if `touse'==1 [iw = `samplew']
				matrix `denom01s' = r(mean)
				
				// Z=0, augmentation with outcome predictions
				gen double `denom02' = `d0hat' if `touse'==1
				sum `denom02' if `touse'==1 [iw = `samplew']
				matrix `denom02s' = r(mean)
				
				gen double `denom1' = `omega1'*(`tvar' -`d1hat')+`d1hat' if `touse'==1
				sum `denom1' if `touse'==1 [iw = `samplew']
				matrix `denom1s' = r(mean)
				
				gen double `denom0' = `omega0'*(`tvar' -`d0hat')+`d0hat' if `touse'==1
				sum `denom0' if `touse'==1 [iw = `samplew']
				matrix `denom0s' = r(mean)
				
				matrix `denoms' = `denom1s'-`denom0s'
				
				matrix `lates' = `nums'*inv(`denoms')
				
				// --- zmodel != ipt ---
				if "`zmodel'" != "ipt" {
					local eqw1 (eqw1: (((`zvar'*(1+exp(-({zhat:}))) - {w1}))))
					local eqw1_inst instruments(eqw1: )
					local eqw0 (eqw0: ((((1-`zvar')*((1+exp({zhat:})))) - {w0})))
					local eqw0_inst instruments(eqw0: )
					
					if "`omodel'" == "regress" {
						local eqy0 (eqy0: ((0.`zvar')*(`yvar'-({y0: `ymodelvars' _cons}))))
						local eqy0_inst instruments(eqy0: `ymodelvars' )
						
						local eqy1 (eqy1: ((1.`zvar')*(`yvar'-({y1: `ymodelvars' _cons}))))
						local eqy1_inst instruments(eqy1: `ymodelvars' )
						
						local num11 (num11: {num11}- ((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-({y1:})))
						local num12 (num12: {num12}- ({y1:}))
						local num1 (num1: {num1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-({y1:})))-({y1:}))
						
						local num01 (num01: {num01}- (((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-({y0:})))
						local num02 (num02: {num02}- ({y0:}))
						local num0 (num0: {num0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-({y0:})))-({y0:}))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "logit" {
						local eqy0 (eqy0: ((0.`zvar')*(`yvar'-exp({y0: `ymodelvars' _cons})/(1+exp({y0:})))))
						local eqy0_inst instruments(eqy0: `ymodelvars' )
						
						local eqy1 (eqy1: ((1.`zvar')*(`yvar'-exp({y1: `ymodelvars' _cons})/(1+exp({y1:})))))
						local eqy1_inst instruments(eqy1: `ymodelvars' )
						
						local num11 (num11: {num11}- ((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-exp({y1:})/(1+exp({y1:}))))
						local num12 (num12: {num12}- (exp({y1:})/(1+exp({y1:}))))
						local num1 (num1: {num1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-(exp({y1:})/(1+exp({y1:})))))-(exp({y1:})/(1+exp({y1:}))))
						
						local num01 (num01: {num01}- (((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-((exp({y0:})/(1+exp({y0:}))))))
						local num02 (num02: {num02}- ((exp({y0:})/(1+exp({y0:})))))
						local num0 (num0: {num0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-((exp({y0:})/(1+exp({y0:}))))))-((exp({y0:})/(1+exp({y0:})))))
						local num (num: {num}-({num1}-{num0}))
					}
					else if "`omodel'" == "poisson" {
						local eqy0 (eqy0: ((0.`zvar')*(`yvar'-exp({y0: `ymodelvars' _cons}))))
						local eqy0_inst instruments(eqy0: `ymodelvars' )
						
						local eqy1 (eqy1: ((1.`zvar')*(`yvar'-exp({y1: `ymodelvars' _cons}))))
						local eqy1_inst instruments(eqy1: `ymodelvars' )
						
						local num11 (num11: {num11}- ((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-exp({y1:})))
						local num12 (num12: {num12}- (exp({y1:})))
						local num1 (num1: {num1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`yvar'-(exp({y1:}))))-(exp({y1:})))
						
						local num01 (num01: {num01}- (((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-((exp({y0:})))))
						local num02 (num02: {num02}- ((exp({y0:}))))
						local num0 (num0: {num0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`yvar'-((exp({y0:})))))-((exp({y0:}))))
						local num (num: {num}-({num1}-{num0}))
					}
					
					matrix `initial' = (`bips', `by0', `by1', `w1s', `w0s', `num1s', `num0s', `nums')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqy0' `eqy1' `eqw1' `eqw0' `num1' `num0' `num' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
					
					if "`tmodel'" == "logit" {
						local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons})/(1+exp({d0:})))))
						local eqd0_inst instruments(eqd0: `tmodelvars' )
						
						local eqd1 (eqd1: ((1.`zvar')*(`tvar'-exp({d1: `tmodelvars' _cons})/(1+exp({d1:})))))
						local eqd1_inst instruments(eqd1: `tmodelvars' )
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-(exp({d1:})/(1+exp({d1:})))))-(exp({d1:})/(1+exp({d1:}))))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-((exp({d0:})/(1+exp({d0:})))))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-(exp({d1:})/(1+exp({d1:})))))-(exp({d1:})/(1+exp({d1:}))))
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-((exp({d0:})/(1+exp({d0:}))))))-((exp({d0:})/(1+exp({d0:})))))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					else if "`tmodel'" == "poisson" {
						local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons}))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						local eqd1 (eqd1: ((1.`zvar')*(`tvar'-exp({d1: `tmodelvars' _cons}))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-(exp({d1:}))))-(exp({d1:})))
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-(exp({d0:}))))-(exp({d0:})))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					else if "`tmodel'" == "regress" {
						local eqd0 (eqd0: ((0.`zvar')*(`tvar'-({d0: `tmodelvars' _cons}))))
						local eqd0_inst instruments(eqd0: `tmodelvars')
						
						local eqd1 (eqd1: ((1.`zvar')*(`tvar'-({d1: `tmodelvars' _cons}))))
						local eqd1_inst instruments(eqd1: `tmodelvars')
						
						if `dmeanz0'==0 | `dmeanz0'==1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-({d1:})))-({d1:}))
							local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
						}
						else if `dmeanz1'==0 | `dmeanz1'==1 {
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-({d0:})))-({d0:}))
							local denom (denom: {denom}-(`dmeanz1'-{denom0}))
						}
						else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
							local denom1 (denom1: {denom1}- (((`zvar'*(1+exp(-({zhat:}))))/{w1})*(`tvar'-({d1:})))-({d1:}))
							local denom0 (denom0: {denom0}- ((((1-`zvar')*(1+exp({zhat:})))/{w0})*(`tvar'-({d0:})))-({d0:}))
							local denom (denom: {denom}-({denom1}-{denom0}))
						}
					}
					
					local late (late: ({late} - {num}/{denom}))
					
					// Joint estimation GMM/AIPW norm
					// Case 1: dmeanz0 degenerate
					if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
						matrix `initial' = (`bips', `by0', `by1', `w1s', `w0s', `num1s', `num0s', `nums', `bd1', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `eqw1' `eqw0' `num1' `num0' `num' `eqd1' `denom1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					
					// Case 2: dmeanz1 degenerate
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & (`dmeanz1'==0 | `dmeanz1'==1) {
						matrix `initial' = (`bips', `by0', `by1', `w1s', `w0s', `num1s', `num0s', `nums', `bd0', `denom0s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `eqw1' `eqw0' `num1' `num0' `num' `eqd0' `denom0' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
					
					// Case 3: general - both interior
					else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
						matrix `initial' = (`bips', `by0', `by1', `w1s', `w0s', `num1s', `num0s', `nums', `bd0', `bd1', `denom0s', `denom1s', `denoms', `lates')
						local k = colsof(`initial')
						matrix `I' = I(`k')
						
						gmm `eqips' `eqy0' `eqy1' `eqw1' `eqw0' `num1' `num0' `num' `eqd0' `eqd1' `denom0' `denom1' `denom' `late' ///
							if `touse' [pw = `samplew'], ///
							`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
							onestep winitial(`I') from(`initial') ///
							quickderivatives vce(`vce') iterate(0)
					}
				}
			}
		}
				
		// -----------------------------------------------
		// METHOD: RA
		// -----------------------------------------------
		else if "`method'" == "ra" {
			`omodel' `yvar' `ymodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
			matrix `by1' = e(b)
			predict double `y1hat'
			
			`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
			matrix `by0' = e(b)
			predict double `y0hat'
			
			if `dmeanz1'==1 {
				gen double `d1hat' = 1
			}
			else if `dmeanz1'==0 {
				gen double `d1hat' = 0
			}
			else {
				`tmodel' `tvar' `tmodelvars' if `zvar'==1 & `touse'==1 [pw = `samplew']
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
				`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
				matrix `bd0' = e(b)
				predict double `d0hat'
			}
			
			sum `y1hat' if `touse'==1 [iw = `samplew']
			matrix `num1s' = r(mean)
			sum `y0hat' if `touse'==1 [iw = `samplew']
			matrix `num0s' = r(mean)
			matrix `nums' = `num1s' - `num0s'
			
			sum `d1hat' if `touse'==1 [iw = `samplew']
			matrix `denom1s' = r(mean)
			sum `d0hat' if `touse'==1 [iw = `samplew']
			matrix `denom0s' = r(mean)
			matrix `denoms' = `denom1s' - `denom0s'
			
			matrix `lates' = `nums' * inv(`denoms')
			
			if "`omodel'" == "regress" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local eqy1 (eqy1: ((1.`zvar'*(`yvar'-({y1:`ymodelvars' _cons})))))
				local eqy1_inst instruments(eqy1: `ymodelvars')
				local num1 (num1: {num1}-({y1:}))
				local num0 (num0: {num0}-({y0:}))
				local num (num: {num}-({num1}-{num0}))
			}
			else if "`omodel'" == "logit" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:}))))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})/(1+exp({y1:}))))))
				local eqy1_inst instruments(eqy1: `ymodelvars')
				local num1 (num1: {num1}-(exp({y1:})/(1+exp({y1:}))))
				local num0 (num0: {num0}-(exp({y0:})/(1+exp({y0:}))))
				local num (num: {num}-({num1}-{num0}))
			}
			else if "`omodel'" == "poisson" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local eqy1 (eqy1: ((1.`zvar'*(`yvar'-exp({y1:`ymodelvars' _cons})))))
				local eqy1_inst instruments(eqy1: `ymodelvars')
				local num1 (num1: {num1}-(exp({y1:})))
				local num0 (num0: {num0}-(exp({y0:})))
				local num (num: {num}-({num1}-{num0}))
			}
			
			if "`tmodel'" == "logit" {
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons})/(1+exp({d1:}))))))
				local eqd1_inst instruments(eqd1: `tmodelvars')
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:}))))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					local denom1 (denom1: {denom1}-(exp({d1:})/(1+exp({d1:}))))
					local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
				}
				else if `dmeanz1'==0 | `dmeanz1'==1 {
					local denom0 (denom0: {denom0}-(exp({d0:})/(1+exp({d0:}))))
					local denom (denom: {denom}-(`dmeanz1'-{denom0}))
				}
				else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
					local denom1 (denom1: {denom1}-(exp({d1:})/(1+exp({d1:}))))
					local denom0 (denom0: {denom0}-(exp({d0:})/(1+exp({d0:}))))
					local denom (denom: {denom}-({denom1}-{denom0}))
				}
			}
			else if "`tmodel'" == "poisson" {
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-exp({d1:`tmodelvars' _cons})))))
				local eqd1_inst instruments(eqd1: `tmodelvars')
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					local denom1 (denom1: {denom1}-(exp({d1:})))
					local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
				}
				else if `dmeanz1'==0 | `dmeanz1'==1 {
					local denom0 (denom0: {denom0}-(exp({d0:})))
					local denom (denom: {denom}-(`dmeanz1'-{denom0}))
				}
				else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
					local denom1 (denom1: {denom1}-(exp({d1:})))
					local denom0 (denom0: {denom0}-(exp({d0:})))
					local denom (denom: {denom}-({denom1}-{denom0}))
				}
			}
			else if "`tmodel'" == "regress" {
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1:`tmodelvars' _cons})))))
				local eqd1_inst instruments(eqd1: `tmodelvars')
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					local denom1 (denom1: {denom1}-({d1:}))
					local denom (denom: {denom}-(({denom1})-(`dmeanz0')))
				}
				else if `dmeanz1'==0 | `dmeanz1'==1 {
					local denom0 (denom0: {denom0}-({d0:}))
					local denom (denom: {denom}-(`dmeanz1'-{denom0}))
				}
				else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
					local denom1 (denom1: {denom1}-({d1:}))
					local denom0 (denom0: {denom0}-({d0:}))
					local denom (denom: {denom}-({denom1}-{denom0}))
				}
			}
			
			local late (late: ({late} - {num}/{denom}))
			
			if `dmeanz0'==0 | `dmeanz0'==1 {
				matrix `initial' = (`by0', `by1', `num0s', `num1s', `nums', `bd1', `denom1s', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqy0' `eqy1' `num0' `num1' `num' `eqd1' `denom1' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd1_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
			else if `dmeanz1'==0 | `dmeanz1'==1 {
				matrix `initial' = (`by0', `by1', `num0s', `num1s', `nums', `bd0', `denom0s', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `denom0' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd0_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
			else if `dmeanz0'!=0 & `dmeanz0'!=1 & `dmeanz1'!=0 & `dmeanz1'!=1 {
				matrix `initial' = (`by0', `by1', `num0s', `num1s', `nums', `bd0', `bd1', `denom0s', `denom1s', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqy0' `eqy1' `num0' `num1' `num' `eqd0' `eqd1' `denom0' `denom1' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
		}
	}
end
