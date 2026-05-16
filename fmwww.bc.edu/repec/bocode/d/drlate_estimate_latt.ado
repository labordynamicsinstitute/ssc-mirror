*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop drlate_estimate_latt
program define drlate_estimate_latt, eclass
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
		gmmopts(string) iteropt(string) iteroptml(string) ]
	
	// -----------------------------------------------
	// Rebuild eqips string locally
	// -----------------------------------------------
	if "`zmodel'" == "logit" {
		local eqips (eqips: `zvar' - exp({zhat:`zmodelvars' _cons})/(1+exp({zhat:})))
		local eqips_inst instruments(eqips: `zmodelvars')
	}
	else if "`zmodel'" == "ipt" {
		local eqips (eqips: ((1-`zvar')*(1+exp({zhat:`zmodelvars' _cons})) - 1))
		local eqips_inst instruments(eqips: `zmodelvars')
		matrix `bips' = `bips0'
	}
	
	quietly {
		// -----------------------------------------------
		// Shared tempnames and tempvars
		// -----------------------------------------------
		tempname by1 by0 bd1 bd0
		tempname denom1s denom0s num1s num0s nums denoms lates
		tempname initial I
		tempvar y1hat y0hat d1hat d0hat
		
		// -----------------------------------------------
		// METHOD: IPWRA
		// -----------------------------------------------
		if "`method'" == "ipwra" {
			// Outcome regression (Z=1)
			regress `yvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
			matrix `by1' = e(b)
			predict double `y1hat'
			
			// Outcome regression (Z=0)
			if "`zmodel'" == "logit" {
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew'*(`ips'/(1-`ips'))]
			}
			else if "`zmodel'" == "ipt" {
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew'*(`ips'/(1-`ips'))]
			}
			matrix `by0' = e(b)
			predict double `y0hat'
			
			if `dmeanz1'==1 {
				gen double `d1hat' = 1
			}
			else if `dmeanz1'==0 {
				gen double `d1hat' = 0
			}
			else {
				regress `tvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
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
				`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew'*(`ips'/(1-`ips'))]
				matrix `bd0' = e(b)
				predict double `d0hat'
			}
			
			sum `d1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `denom1s' = r(mean)
			sum `d0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `denom0s' = r(mean)
			sum `y1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `num1s' = r(mean)
			sum `y0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `num0s' = r(mean)
			matrix `nums' = `num1s' - `num0s'
			matrix `denoms' = `denom1s' - `denom0s'
			matrix `lates' = `nums'*invsym(`denoms')
			
			// Treatment moment (Z=1)
			local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1: _cons})))))
			local eqd1_inst instruments(eqd1: )
			
			// Treatment moment (Z=0)
			if "`tmodel'" == "logit" {
				local eqd0 (eqd0: ((0.`zvar'*(exp({zhat:}))*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:}))))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			else if "`tmodel'" == "poisson" {
				local eqd0 (eqd0: ((0.`zvar'*(exp({zhat:}))*(`tvar'-exp({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			else if "`tmodel'" == "regress" {
				local eqd0 (eqd0: ((0.`zvar'*(exp({zhat:}))*(`tvar'-({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			
			// Denominator moment
			if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
				local denom (denom: (1.`zvar'*({denom}-({d1:}-(`dmeanz0')))))
			}
			else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
				if "`tmodel'" == "logit" {
					local denom (denom: (1.`zvar'*({denom}-(`dmeanz1'-(exp({d0:})/(1+exp({d0:})))))))
				}
				else if "`tmodel'" == "poisson" {
					local denom (denom: (1.`zvar'*({denom}-(`dmeanz1'-exp({d0:})))))
				}
				else if "`tmodel'" == "regress" {
					local denom (denom: (1.`zvar'*({denom}-(`dmeanz1'-({d0:})))))
				}
			}
			else {
				if "`tmodel'" == "logit" {
					local denom (denom: (1.`zvar'*({denom}-(({d1:})-(exp({d0:})/(1+exp({d0:})))))))
				}
				else if "`tmodel'" == "poisson" {
					local denom (denom: (1.`zvar'*({denom}-(({d1:})-exp({d0:})))))
				}
				else if "`tmodel'" == "regress" {
					local denom (denom: (1.`zvar'*({denom}-(({d1:})-({d0:})))))
				}
			}
			
			// Outcome moment (Z=1)
			local eqy1 (eqy1: (1.`zvar'*(`yvar'-({y1: _cons}))))
			local eqy1_inst instruments(eqy1: )
			
			// Outcome moment (Z=0)
			if "`omodel'" == "regress" {
				local eqy0 (eqy0: ((0.`zvar'*(exp({zhat:}))*(`yvar'-({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-({y0:})))))
			}
			else if "`omodel'" == "logit" {
				local eqy0 (eqy0: ((0.`zvar'*(exp({zhat:}))*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:}))))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-(exp({y0:})/(1+exp({y0:})))))))
			}
			else if "`omodel'" == "poisson" {
				local eqy0 (eqy0: ((0.`zvar'*(exp({zhat:}))*(`yvar'-exp({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-(exp({y0:}))))))
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
			else if `dmeanz1'==1 | `dmeanz1'==0 {
				matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
			else {
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
		
		// -----------------------------------------------
		// METHOD: IPW
		// -----------------------------------------------
		else if "`method'" == "ipw" {
			if "`statnorm'" == "nrm" {
				// Outcome regression (Z=1)
				regress `yvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
				matrix `by1' = e(b)
				predict double `y1hat'
				
				// Outcome regression (Z=0)
				`omodel' `yvar' if `zvar'==0 & `touse'==1 [pw = `samplew'*(`ips'/(1-`ips'))]
				matrix `by0' = e(b)
				predict double `y0hat'
				
				// Treatment regression (Z=1)
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
				}
				else {
					regress `tvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
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
					regress `tvar' if `zvar'==0 & `touse'==1 [pw = `samplew'*(`ips'/(1-`ips'))]
					matrix `bd0' = e(b)
					predict double `d0hat'
				}
				
				sum `d1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
				matrix `denom1s' = r(mean)
				sum `d0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
				matrix `denom0s' = r(mean)
				sum `y1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				sum `y0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
				matrix `num0s' = r(mean)
				matrix `nums' = `num1s' - `num0s'
				matrix `denoms' = `denom1s' - `denom0s'
				matrix `lates' = `nums'*invsym(`denoms')
				
				// Treatment moments (no covariates for IPW)
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1: _cons})))))
				local eqd1_inst instruments(eqd1: )
				local eqd0 (eqd0: ((0.`zvar'*(exp({zhat:}))*(`tvar'-({d0: _cons})))))
				local eqd0_inst instruments(eqd0: )
				
				// Denominator moment
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					local denom (denom: {denom}-({d1:}-(`dmeanz0')))
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					local denom (denom: {denom}-(`dmeanz1'-({d0:})))
				}
				else {
					local denom (denom: {denom}-(({d1:})-({d0:})))
				}
				
				// Outcome moments (no covariates for IPW)
				local eqy1 (eqy1: (1.`zvar'*(`yvar'-({y1: _cons}))))
				local eqy1_inst instruments(eqy1: )
				local eqy0 (eqy0: ((0.`zvar'*(exp({zhat:}))*(`yvar'-({y0: _cons})))))
				local eqy0_inst instruments(eqy0: )
				local num (num: (1.`zvar'*({num}-(({y1:})-({y0:})))))
				
				local late (late: ({late} - {num}/{denom}))
				
				if (`dmeanz0'==0 | `dmeanz0'==1) {
					matrix `initial' = (`bips', `by0', `by1', `nums', `bd1', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if (`dmeanz1'==1 | `dmeanz1'==0) {
					matrix `initial' = (`bips', `by0', `by1', `nums', `bd0', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else {
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
			else if "`statnorm'" == "unnrm" {
				tempvar omega1 omega0
				tempname w1 w1s
				sum `zvar' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `zvar' if `touse'==1 [iw = `samplew']
				scalar `w1' = r(mean)
				gen double `omega1' = (`zvar')/`w1' if `touse'==1
				gen double `omega0' = (((1-`zvar')*`ips')/(1-`ips'))/`w1' if `touse'==1
				
				// Outcome regression (Z=1)
				gen double `y1hat' = `omega1'*`yvar' if `touse'==1
				
				// Outcome regression (Z=0)
				gen double `y0hat' = `omega0'*`yvar' if `touse'==1
				matrix `by0' = e(b)
		
				// Treatment regression (Z=1)
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
				}
				else {
					gen double `d1hat' = `omega1'*`tvar' if `touse'==1
				}
				
				if `dmeanz0'==0 {
					gen double `d0hat' = 0
				}
				else if `dmeanz0'==1 {
					gen double `d0hat' = 1
				}
				else {
					gen double `d0hat' = `omega0'*`tvar' if `touse'==1
				}
				
				sum `d1hat' if `touse'==1 [iw = `samplew']
				matrix `denom1s' = r(mean)
				sum `d0hat' if `touse'==1 [iw = `samplew']
				matrix `denom0s' = r(mean)
				sum `y1hat' if `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				sum `y0hat' if `touse'==1 [iw = `samplew']
				matrix `num0s' = r(mean)
				matrix `nums' = `num1s' - `num0s'
				matrix `denoms' = `denom1s' - `denom0s'
				matrix `lates' = `nums'*invsym(`denoms')
				
				// Moment for sample size for Z=1
				local eqw1 (eqw1: (`zvar' - {w1}))
				local eqw1_inst instruments(eqw1: )
				
				// Treatment moments (no covariates for IPW)
				local eqd1 (eqd1: (`zvar'*(`tvar'/{w1})-({d1})))
				local eqd1_inst instruments(eqd1: )
				local eqd0 (eqd0: (((1-`zvar')*(exp({zhat:}))*`tvar'/{w1})-({d0})))
				local eqd0_inst instruments(eqd0: )
				
				// Denominator moment
				if (`dmeanz0'==0 | `dmeanz0'==1) {
					local denom (denom: {denom}-({d1}-(`dmeanz0')))
				}
				else if (`dmeanz1'==1 | `dmeanz1'==0) {
					local denom (denom: {denom}-(`dmeanz1'-({d0})))
				}
				else {
					local denom (denom: {denom}-(({d1})-({d0})))
				}
				
				// Outcome moments (no covariates for IPW)
				local eqy1 (eqy1: (`zvar'*(`yvar'/{w1})-({y1})))
				local eqy1_inst instruments(eqy1: )
				local eqy0 (eqy0: (((1-`zvar')*(exp({zhat:}))*`yvar'/{w1})-({y0})))
				local eqy0_inst instruments(eqy0: )
				local num (num: (({num}-(({y1})-({y0})))))
				
				local late (late: ({late} - {num}/{denom}))
				
				if `dmeanz0'==0 | `dmeanz0'==1 {
					matrix `initial' = (`bips', `w1s', `num0s', `num1s', `nums', `denom1s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else if `dmeanz1'==1 | `dmeanz1'==0 {
					matrix `initial' = (`bips', `w1s', `num0s', `num1s', `nums', `denom0s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
				else {
					matrix `initial' = (`bips', `w1s', `num0s', `num1s', `nums', `denom0s', `denom1s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
						if `touse' [pw = `samplew'], ///
						`eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
						onestep winitial(`I') from(`initial') ///
						quickderivatives vce(`vce') iterate(0)
				}
			}
		}
		
		// -----------------------------------------------
		// METHOD: AIPW
		// -----------------------------------------------
		else if "`method'" == "aipw" {
			tempvar y0hatr d0hatr
			tempvar num01 num01_we num02
			tempvar denom01 denom01_we denom02
			tempname w1 w1s nums num01s num02s denom01s denom02s
			
			if "`statnorm'" == "unnrm" {
				sum `zvar' if `touse'==1
				scalar `w1' = r(mean)
				matrix `w1s' = r(mean)
				
				// Numerator
				// Z=1
				tempvar y1hatipw
				gen double `y1hatipw' = (`zvar'/`w1')*`yvar' if `touse'==1
				sum `y1hatipw' if `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				
				// Z=0
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0' = e(b)
				predict double `y0hatr'
				
				gen double `num01' = ((1-`zvar')*`ips'/(1-`ips'))*(`yvar'-`y0hatr') if `touse'==1
				gen double `num01_we' = `num01'/`w1' if `touse'==1
				sum `num01_we' if `touse'==1 [iw = `samplew']
				matrix `num01s' = r(mean)
				
				gen double `num02' = `zvar'*`y0hatr'/`w1' if `touse'==1
				sum `num02' if `touse'==1 [iw = `samplew']
				matrix `num02s' = r(mean)
				
				matrix `num0s' = `num01s' + `num02s'
				matrix `nums' = `num1s' - `num0s'
				
				// Denominator
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
					matrix `denom1s' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
					matrix `denom1s' = 0
				}
				else {
					tempvar d1hatipw
					gen double `d1hatipw' = (`zvar'/`w1')*`tvar' if `touse'==1
					sum `d1hatipw' if `touse'==1 [iw = `samplew']
					matrix `denom1s' = r(mean)
				}
				
				if `dmeanz0'==0 {
					gen double `d0hatr' = 0
					matrix `denom0s' = 0
				}
				else if `dmeanz0'==1 {
					gen double `d0hatr' = 1
					matrix `denom0s' = 1
				}
				else {
					`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
					matrix `bd0' = e(b)
					predict double `d0hatr'
					sum `d0hatr'
					gen double `denom01' = ((1-`zvar')*`ips'/(1-`ips'))*(`tvar'-`d0hatr') if `touse'==1
					
					gen double `denom01_we' = `denom01'/`w1' if `touse'==1
					sum `denom01_we' if `touse'==1 [iw = `samplew']
					matrix `denom01s' = r(mean)
					
					gen double `denom02' = `zvar'*`d0hatr'/`w1' if `touse'==1
					sum `denom02' if `touse'==1 [iw = `samplew']
					matrix `denom02s' = r(mean)
					
					matrix `denom0s' = `denom01s' + `denom02s'
				}
				
				matrix `denoms' = `denom1s' - `denom0s'
				matrix `lates' = `nums'*invsym(`denoms')
				
				// GMM moments
				local eqy1 (eqy1: (1.`zvar'*(`yvar'-({y1: _cons}))))
				local eqy1_inst instruments(eqy1: )
				
				if "`omodel'" == "regress" {
					local eqw1 (eqw1: (`zvar' - {w1}))
					local eqw1_inst instruments(eqw1: )
					
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-({y0: `ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					
					local eqnum01 (eqnum01: ((exp({zhat:})*(1-`zvar')*(`yvar'-{y0:}))/{w1}-{num01}))
					local eqnum02 (eqnum02: `zvar'*({y0: })/{w1}-{num02})
					
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-{y0:}))/{w1})+(`zvar'*({y0: })/{w1})))
					local eqnum (eqnum: ({num}-({y1:}-({num0}))))
				}
				else if "`omodel'" == "logit" {
					local eqw1 (eqw1: (`zvar' - {w1}))
					local eqw1_inst instruments(eqw1: )
					
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-exp({y0: `ymodelvars' _cons})/(1+exp({y0:})))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					
					local eqnum01 (eqnum01: ((exp({zhat:})*(1-`zvar')*(`yvar'-exp({y0:})/(1+exp({y0:}))))/{w1}-{num01}))
					local eqnum02 (eqnum02: `zvar'*(exp({y0:})/(1+exp({y0:})))/{w1}-{num02})
					
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-exp({y0:})/(1+exp({y0:}))))/{w1})+(`zvar'*(exp({y0: })/(1+exp({y0:})))/{w1})))
					local eqnum (eqnum: ({num}-({y1:}-({num0}))))
				}
				else if "`omodel'" == "poisson" {
					local eqw1 (eqw1: (`zvar' - {w1}))
					local eqw1_inst instruments(eqw1: )
					
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-exp({y0: `ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					
					local eqnum01 (eqnum01: ((exp({zhat:})*(1-`zvar')*(`yvar'-exp({y0:})))/{w1}-{num01}))
					local eqnum02 (eqnum02: `zvar'*(exp({y0:}))/{w1}-{num02})
					
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-exp({y0:})))/{w1})+(`zvar'*(exp({y0: }))/{w1})))
					local eqnum (eqnum: ({num}-({y1:}-({num0}))))
				}
				
				matrix `initial' = (`bips', `w1s', `by0', `num1s', `num0s', `nums')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqips' `eqw1' `eqy0' `eqy1' `eqnum0' `eqnum' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				// Denominator
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1: _cons})))))
				local eqd1_inst instruments(eqd1: )
				
				local eqw1 (eqw1: (`zvar' - {w1}))
				local eqw1_inst instruments(eqw1: )
				
				if "`tmodel'" == "logit" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons})/(1+exp({d0:})))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})/(1+exp({d0:}))))/{w1}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(exp({d0:})/(1+exp({d0:})))/{w1}-{denom02})
					
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})/(1+exp({d0:}))))/{w1})+(`zvar'*(exp({d0: })/(1+exp({d0:})))/{w1})))
					
					if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
						local eqdenom (eqdenom: ({denom}-({d1:}-(`dmeanz0'))))
					}
					else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
						local eqdenom (eqdenom: ({denom}-(`dmeanz1'-({denom0}))))
					}
					else {
						local eqdenom (eqdenom: ({denom}-({d1:}-({denom0}))))
					}
				}
				else if "`tmodel'" == "poisson" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})))/{w1}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(exp({d0:}))/{w1}-{denom02})
					
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})))/{w1})+(`zvar'*(exp({d0: }))/{w1})))
					
					if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
						local eqdenom (eqdenom: ({denom}-({d1:}-(`dmeanz0'))))
					}
					else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
						local eqdenom (eqdenom: ({denom}-(`dmeanz1'-({denom0}))))
					}
					else {
						local eqdenom (eqdenom: ({denom}-({d1:}-({denom0}))))
					}
				}
				else if "`tmodel'" == "regress" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-({d0: `tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-({d0:})))/{w1}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(({d0:}))/{w1}-{denom02})
					
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-({d0:})))/{w1})+(`zvar'*(({d0: }))/{w1})))
					
					if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
						local denom (denom: {denom}-({d1:}-(`dmeanz0')))
						local eqdenom (eqdenom: ({denom}-({d1:}-(`dmeanz0'))))
					}
					else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
						local eqdenom (eqdenom: ({denom}-(`dmeanz1'-({denom0}))))
					}
					else {
						local eqdenom (eqdenom: ({denom}-({d1:}-({denom0}))))
					}
				}
				
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					matrix `initial' = (`bips', `w1s', `denom1s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqd1' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					matrix `initial' = (`bips', `w1s', `bd0', `denom0s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqd0'`eqdenom0' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd0_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else {
					matrix `initial' = (`bips', `w1s', `bd0', `denom1s', `denom0s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqd0' `eqd1' `eqdenom0' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd0_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				
				local late (late: ({late} - {num}/{denom}))
				
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					matrix `initial' = (`bips', `w1s', `by0', `num1s', `num0s', `nums', `denom1s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd1' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					matrix `initial' = (`bips', `w1s', `by0', `num1s', `num0s', `nums', `bd0', `denom0s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd0' `eqdenom0' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else {
					matrix `initial' = (`bips', `w1s', `by0', `num1s', `num0s', `nums', `bd0', `denom1s', `denom0s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					gmm `eqips' `eqw1' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd0' `eqd1' `eqdenom0' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
			}
			else if "`statnorm'" == "nrm" {
				tempvar omega1 omega0 y0hatr num02
				tempname w1 w1s num02s num0s nums denom02s denom0s denoms
				sum `zvar' if `touse'==1 [iw = `samplew']
				matrix `w1s' = r(mean)
				sum `zvar' if `touse'==1 [iw = `samplew']
				scalar `w1' = r(mean)
				gen double `omega1' = (`zvar')/`w1' if `touse'==1
				gen double `omega0' = (((1-`zvar')*`ips')/(1-`ips'))/`w1' if `touse'==1
				
				// Numerator
				// Z=1
				gen double `y1hat' = `omega1'*`yvar' if `touse'==1
				sum `y1hat' if `touse'==1 [iw = `samplew']
				matrix `num1s' = r(mean)
				
				// Z=0
				`omodel' `yvar' `ymodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
				matrix `by0' = e(b)
				predict double `y0hatr' if `touse'==1
				
				tempvar attweight num01_we num01
				tempname wnorms wnorms_s num01s
				gen double `attweight' = (((1-`zvar')*`ips')/(1-`ips')) if `touse'==1
				sum `attweight' if `touse'==1 [iw = `samplew']
				matrix `wnorms' = r(mean)
				sum `attweight' if `touse'==1 [iw = `samplew']
				scalar `wnorms_s' = r(mean)
				
				gen double `num01' = (((1-`zvar')*`ips')/(1-`ips'))*(`yvar'-`y0hatr') if `touse'==1
				
				gen double `num01_we' = `num01'/`wnorms_s' if `touse'==1
				
				sum `num01_we' if `touse'==1 [iw = `samplew']
				matrix `num01s' = r(mean)
				
				gen double `num02' = `zvar'*`y0hatr'/`w1' if `touse'==1
				sum `num02' if `touse'==1 [iw = `samplew']
				matrix `num02s' = r(mean)
				
				matrix `num0s' = `num01s' + `num02s'
				matrix `nums' = `num1s' - `num0s'
				
				// Denominator
				if `dmeanz1'==1 {
					gen double `d1hat' = 1
					matrix `denom1s' = 1
				}
				else if `dmeanz1'==0 {
					gen double `d1hat' = 0
					matrix `denom1s' = 0
				}
				else {
					gen double `d1hat' = `omega1'*`tvar' if `touse'==1
					sum `d1hat' if `touse'==1 [iw = `samplew']
					matrix `denom1s' = r(mean)
				}
				
				if `dmeanz0'==0 {
					gen double `d0hatr' = 0
					matrix `denom0s' = 0
				}
				else if `dmeanz0'==1 {
					gen double `d0hatr' = 1
					matrix `denom0s' = 1
				}
				else {
					`tmodel' `tvar' `tmodelvars' if `zvar'==0 & `touse'==1 [pw = `samplew']
					matrix `bd0' = e(b)
					predict double `d0hatr' if `touse'==1
					
					gen double `denom01' = (((1-`zvar')*`ips')/(1-`ips'))*(`tvar'-`d0hatr') if `touse'==1
					
					gen double `denom01_we' = `denom01'/`wnorms_s' if `touse'==1
					
					sum `denom01_we' if `touse'==1 [iw = `samplew']
					matrix `denom01s' = r(mean)
					
					gen double `denom02' = `zvar'*`d0hatr'/`w1' if `touse'==1
					sum `denom02' if `touse'==1 [iw = `samplew']
					matrix `denom02s' = r(mean)
					
					matrix `denom0s' = `denom01s' + `denom02s'
				}
				
				matrix `denoms' = `denom1s' - `denom0s'
				matrix `lates' = `nums'*invsym(`denoms')
				
				// GMM moments
				local eqw1 (eqw1: (`zvar' - {w1}))
				local eqw1_inst instruments(eqw1: )
				
				local eqwnorm (eqwnorm: ((1-`zvar')*exp({zhat:}) - {wnorm}))
				local eqwnorm_inst instruments(eqwnorm: )
				
				local eqy1 (eqy1: (1.`zvar')*(`yvar'- ({y1m})))
				local eqy1_inst instruments(eqy1: )
				
				if "`omodel'" == "regress" {
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-({y0: `ymodelvars' _cons}))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-({y0:})))/{wnorm})+`zvar'*({y0:})/{w1}))
					local eqnum (eqnum: ({num}-({y1m}-{num0})))
				}
				else if "`omodel'" == "logit" {
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-(exp({y0: `ymodelvars' _cons})/(1+exp({y0:}))))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-(exp({y0: })/(1+exp({y0:})))))/{wnorm})+`zvar'*(exp({y0:})/(1+exp({y0:})))/{w1}))
					local eqnum (eqnum: ({num}-({y1m}-{num0})))
				}
				else if "`omodel'" == "poisson" {
					local eqy0 (eqy0: ((0.`zvar')*(`yvar'-(exp({y0: `ymodelvars' _cons})))))
					local eqy0_inst instruments(eqy0: `ymodelvars' )
					local eqnum0 (eqnum0: {num0}-(((exp({zhat:})*(1-`zvar')*(`yvar'-(exp({y0: }))))/{wnorm})+`zvar'*(exp({y0:}))/{w1}))
					local eqnum (eqnum: ({num}-({y1m}-{num0})))
				}
				matrix `initial' = (`bips', `w1s', `wnorms', `by0', `num1s', `num0s', `nums')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				
				gmm `eqips' `eqw1' `eqwnorm' `eqy0' `eqy1' `eqnum0' `eqnum' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				
				// Denominator
				local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1: _cons})))))
				local eqd1_inst instruments(eqd1: )
				
				if "`tmodel'" == "logit" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons})/(1+exp({d0:})))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})/(1+exp({d0:}))))/{wnorm}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(exp({d0:})/(1+exp({d0:})))/{w1}-{denom02})
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})/(1+exp({d0:}))))/{wnorm})+(`zvar'*(exp({d0: })/(1+exp({d0:})))/{w1})))
				}
				else if "`tmodel'" == "poisson" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-exp({d0: `tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})))/{wnorm}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(exp({d0:}))/{w1}-{denom02})
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-exp({d0:})))/{wnorm})+(`zvar'*(exp({d0: }))/{w1})))
				}
				else if "`tmodel'" == "regress" {
					local eqd0 (eqd0: ((0.`zvar')*(`tvar'-({d0: `tmodelvars' _cons}))))
					local eqd0_inst instruments(eqd0: `tmodelvars' )
					local eqdenom01 (eqdenom01: ((exp({zhat:})*(1-`zvar')*(`tvar'-({d0:})))/{wnorm}-{denom01}))
					local eqdenom02 (eqdenom02: `zvar'*(({d0:}))/{w1}-{denom02})
					local eqdenom0 (eqdenom0: {denom0}-(((exp({zhat:})*(1-`zvar')*(`tvar'-({d0:})))/{wnorm})+(`zvar'*(({d0: }))/{w1})))
				}
				
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					local denom (denom: {denom}-({d1:}-(`dmeanz0')))
					local eqdenom (eqdenom: ({denom}-({d1:}-(`dmeanz0'))))
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					local eqdenom (eqdenom: ({denom}-(`dmeanz1'-({denom0}))))
				}
				else {
					local eqdenom (eqdenom: ({denom}-({d1:}-({denom0}))))
				}
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					matrix `initial' = (`bips', `w1s', `wnorms', `denom1s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqd1' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					matrix `initial' = (`bips', `w1s', `wnorms', `bd0', `denom0s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqd0' `eqdenom0' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd0_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else {
					matrix `initial' = (`bips', `w1s', `wnorms', `bd0', `denom1s', `denom0s', `denoms')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqd0' `eqd1' `eqdenom0' `eqdenom' if `touse' [pw = `samplew'], `eqips_inst' `eqd0_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				
				local late (late: ({late} - {num}/{denom}))
				
				if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
					matrix `initial' = (`bips', `w1s', `wnorms', `by0', `num1s', `num0s', `nums', `denom1s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd1' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
					matrix `initial' = (`bips', `w1s', `wnorms', `by0', `num1s', `num0s', `nums', `bd0', `denom0s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd0' `eqdenom0' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
				else {
					matrix `initial' = (`bips', `w1s', `wnorms', `by0', `num1s', `num0s', `nums', `bd0', `denom1s', `denom0s', `denoms', `lates')
					local k = colsof(`initial')
					matrix `I' = I(`k')
					
					gmm `eqips' `eqw1' `eqwnorm' `eqy0' `eqy1' `eqnum0' `eqnum' `eqd0' `eqd1' `eqdenom0' `eqdenom' `late' if `touse' [pw = `samplew'], `eqips_inst' `eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' onestep winitial(`I') from(`initial') quickderivatives `gmmopts' iterate(0)
				}
			}
		}
		
		// -----------------------------------------------
		// METHOD: RA
		// -----------------------------------------------
		else if "`method'" == "ra" {
			// Outcome regression (Z=1)
			regress `yvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
			matrix `by1' = e(b)
			predict double `y1hat'
			
			// Outcome regression (Z=0)
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
				regress `tvar' if `zvar'==1 & `touse'==1 [pw = `samplew']
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
			
			sum `d1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `denom1s' = r(mean)
			sum `d0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `denom0s' = r(mean)
			sum `y1hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `num1s' = r(mean)
			sum `y0hat' if `zvar'==1 & `touse'==1 [iw = `samplew']
			matrix `num0s' = r(mean)
			matrix `nums' = `num1s' - `num0s'
			matrix `denoms' = `denom1s' - `denom0s'
			matrix `lates' = `nums'*invsym(`denoms')
			
			// Treatment moment (Z=1)
			local eqd1 (eqd1: ((1.`zvar'*(`tvar'-({d1: _cons})))))
			local eqd1_inst instruments(eqd1: )
			
			// Treatment moment (Z=0)
			if "`tmodel'" == "logit" {
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})/(1+exp({d0:}))))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			else if "`tmodel'" == "poisson" {
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-exp({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			else if "`tmodel'" == "regress" {
				local eqd0 (eqd0: ((0.`zvar'*(`tvar'-({d0:`tmodelvars' _cons})))))
				local eqd0_inst instruments(eqd0: `tmodelvars')
			}
			
			// Denominator moment
			if (`dmeanz0'==0 | `dmeanz0'==1) & `dmeanz1'!=1 {
				local denom (denom: {denom}-({d1:}-(`dmeanz0')))
			}
			else if `dmeanz0'!=0 & (`dmeanz1'==1 | `dmeanz1'==0) {
				if "`tmodel'" == "logit" {
					local denom (denom: {denom}-(`dmeanz1'-(exp({d0:})/(1+exp({d0:})))))
				}
				else if "`tmodel'" == "poisson" {
					local denom (denom: {denom}-(`dmeanz1'-exp({d0:})))
				}
				else if "`tmodel'" == "regress" {
					local denom (denom: {denom}-(`dmeanz1'-({d0:})))
				}
			}
			else {
				if "`tmodel'" == "logit" {
					local denom (denom: {denom}-(({d1:})-(exp({d0:})/(1+exp({d0:})))))
				}
				else if "`tmodel'" == "poisson" {
					local denom (denom: {denom}-(({d1:})-exp({d0:})))
				}
				else if "`tmodel'" == "regress" {
					local denom (denom: {denom}-(({d1:})-({d0:})))
				}
			}
			
			// Outcome moment (Z=1)
			local eqy1 (eqy1: (1.`zvar'*(`yvar'-({y1: _cons}))))
			local eqy1_inst instruments(eqy1: )
			
			// Outcome moment (Z=0)
			if "`omodel'" == "regress" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-({y0:})))))
			}
			else if "`omodel'" == "logit" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})/(1+exp({y0:}))))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-(exp({y0:})/(1+exp({y0:})))))))
			}
			else if "`omodel'" == "poisson" {
				local eqy0 (eqy0: ((0.`zvar'*(`yvar'-exp({y0:`ymodelvars' _cons})))))
				local eqy0_inst instruments(eqy0: `ymodelvars')
				local num (num: (1.`zvar'*({num}-(({y1:})-(exp({y0:}))))))
			}
			
			local late (late: ({late} - {num}/{denom}))
			
			if `dmeanz0'==0 | `dmeanz0'==1 {
				matrix `initial' = (`by0', `by1', `nums', `bd1', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				gmm `eqy0' `eqy1' `num' `eqd1' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd1_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
			else if `dmeanz1'==1 | `dmeanz1'==0 {
				matrix `initial' = (`by0', `by1', `nums', `bd0', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				gmm `eqy0' `eqy1' `num' `eqd0' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd0_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
			else {
				matrix `initial' = ( `by0', `by1', `nums', `bd0', `bd1', `denoms', `lates')
				local k = colsof(`initial')
				matrix `I' = I(`k')
				gmm `eqy0' `eqy1' `num' `eqd0' `eqd1' `denom' `late' ///
					if `touse' [pw = `samplew'], ///
					`eqy0_inst' `eqy1_inst' `eqd0_inst' `eqd1_inst' ///
					onestep winitial(`I') from(`initial') ///
					quickderivatives vce(`vce') iterate(0)
			}
		}
	}
end
