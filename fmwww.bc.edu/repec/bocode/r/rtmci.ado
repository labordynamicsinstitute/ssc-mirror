*! 2.0.0 Ariel Linden 16aug2026 - added analytic std errs
*! 1.2.0 Ariel Linden 07mar2013 - added figure option
*! 1.1.0 Ariel Linden 16feb2013 - added %RTM
*! 1.0.0 Ariel Linden 09feb2013

capture program drop rtmci
program define rtmci, eclass byable(recall)
	version 11.0
	syntax varlist(min=2 max=2) [if] [in] , CUToff(string) ///
		[PERiod(int 1) VCE(string) BOOTstrap SEED(integer 1234) REPS(integer 1000) ///
		SIZE(string) LEVel(real 95) SAVING(string) Format(str) FIGure]

	preserve

	tokenize `varlist'
	local pretest `1'
	local posttest `2'

	marksample touse
	quietly count if `touse'
	if r(N) == 0 error 2000
	local N = r(N)

	if "`format'" != "" {
		confirm numeric format `format'
	}
	else local format %05.3f

	local m = `period'
	local k = `cutoff'

	if `"`size'"' == "_N" {
		local size
	}

	if "`level'" != "" {
		set level `level'
		local level `level'
	}

	local vce = lower("`vce'")
	if "`vce'" != "" {
		local vcelist "robust bootstrap"
		local nmatch = 0
		local vcematch ""
		foreach c of local vcelist {
			if substr("`c'",1,strlen("`vce'")) == "`vce'" {
				local ++nmatch
				local vcematch "`c'"
			}
		}
		if `nmatch' == 0 {
			di as error "vce(`vce') not allowed; vce() must be either robust or bootstrap"
			exit 198
		}
		if `nmatch' > 1 {
			di as error "vce(`vce') is ambiguous"
			exit 198
		}
		local vce "`vcematch'"
	}
	if "`bootstrap'" == "bootstrap" {
		if "`vce'" != "" & "`vce'" != "bootstrap" {
			di as error "specify either the bootstrap option or vce(), not conflicting values of both"
			exit 198
		}
		local vce "bootstrap"
	}
	if "`vce'" == "" local vce "robust"

	if "`vce'" == "robust" {
		// point estimates from the unchanged computational engine
		quietly rtm_calc `varlist' if `touse', k(`k') m(`m')
		local mu  = r(mu)
		local sd  = r(sd)
		local rho = r(rho)

		if `N' < 50 & abs(`rho') > 0.8 {
			di as txt "Note: small N with high |rho| -- robust SE can be unstable; consider vce(bootstrap)."
		}

		// empirical ("sandwich"/influence-function) covariance
		quietly sum `posttest' if `touse'
		local mu1 = r(mean)
		local sd1 = r(sd)

		tempvar e0 e1 psi1 psi2 psi3 psi4
		quietly gen double `e0' = `pretest' - `mu' if `touse'
		quietly gen double `e1' = `posttest' - `mu1' if `touse'

		tempname S00 S01 S11
		scalar `S00' = (`sd')^2
		scalar `S11' = (`sd1')^2
		scalar `S01' = (`rho')*(`sd')*(`sd1')

		quietly gen double `psi1' = `e0' if `touse'
		quietly gen double `psi2' = (`e0')^2 - `S00' if `touse'
		quietly gen double `psi3' = (`e0')*(`e1') - `S01' if `touse'
		quietly gen double `psi4' = (`e1')^2 - `S11' if `touse'

		tempname OMEGA b V
		quietly matrix accum `OMEGA' = `psi1' `psi2' `psi3' `psi4' if `touse', noconstant
		// small-sample correction
		if `N' <= 4 {
			di as error "rtmci: vce(robust) requires N > 4 for the small-sample covariance correction; use vce(bootstrap) instead"
			exit 2001
		}
		matrix `V' = `OMEGA' / (`N' * (`N'-4))
		matrix colnames `V' = m0 S00 S01 S11
		matrix rownames `V' = m0 S00 S01 S11

		matrix `b' = (`mu', `S00', `S01', `S11')
		matrix colnames `b' = m0 S00 S01 S11

		ereturn post `b' `V', obs(`N') esample(`touse')

		// build nlcom expressions for the 8 derived quantities
		local bmu  "_b[m0]"
		local bsd  "sqrt(_b[S00])"
		local brho "(_b[S01]/sqrt(_b[S00]*_b[S11]))"
		local vw   "((1-`brho')*(`bsd')^2)"
		local vb   "(`brho'*(`bsd')^2)"
		local psd  "sqrt(`vb'+`vw'/`m')"
		local zh   "((`k'-`bmu')/`psd')"
		local zl   "((`bmu'-`k')/`psd')"
		local ch   "(normalden(`zh')/(1-normal(`zh')))"
		local cl   "(normalden(`zl')/(1-normal(`zl')))"
		local rtmh "((`vw'/`m')/`psd'*`ch')"
		local rtml "((`vw'/`m')/`psd'*`cl')"
		local fvh  "(`bmu'+`ch'*`psd')"
		local svh  "(`bmu'+(`ch'*`vb')/`psd')"
		local fvl  "(`bmu'-`cl'*`psd')"
		local svl  "(`bmu'-(`cl'*`vb')/`psd')"
		local prh  "(`rtmh'/`fvh')"
		local prl  "(`rtml'/`fvl')"

		quietly nlcom (mu: `bmu') (sd: `bsd') (rho: `brho') ///
			(firstval_high: `fvh') (secondval_high: `svh') (rtm_high: `rtmh') (pct_rtm_high: `prh') ///
			(firstval_low: `fvl') (secondval_low: `svl') (rtm_low: `rtml') (pct_rtm_low: `prl'), ///
			post level(`level')

		ereturn local cmd "rtmci"
		ereturn local vce "robust"
		ereturn local vcetype "Robust"
		ereturn scalar k = `k'
		ereturn scalar m = `m'
		ereturn scalar N = `N'
		di as txt ""
		di as txt %67s "Number of obs" as txt " = " as res %9.0fc `N'
		ereturn display
	}
	else {
		// bootstrap
		if "`seed'" != "" {
			`version' set seed `seed'
		}

		bootstrap mu = r(mu) sd = r(sd) rho = r(rho) firstval_high = r(firstval_high) secondval_high = r(secondval_high) rtm_high = r(rtm_high) pct_rtm_high = r(pct_rtm_high) ///
		firstval_low = r(firstval_low) secondval_low=r(secondval_low) rtm_low = r(rtm_low) pct_rtm_low = r(pct_rtm_low), seed(`seed') reps(`reps') size(`size') level(`level') saving(`saving'): ///
		rtm_calc `varlist' if `touse', k(`k') m(`m') seed(`seed') reps(`reps') size(`size') level(`level') saving(`saving')

		ereturn local cmd "rtmci"
		ereturn local vce "bootstrap"
		ereturn scalar k = `k'
		ereturn scalar m = `m'
	}

	/// figure
	if "`figure'" == "figure" {
		local zcrit = invnormal(1 - (100-`level')/200)

		tempname est1 se1 est2 se2 est3 se3 est4 se4
		scalar `est1' = _b[firstval_high]
		scalar `se1'  = _se[firstval_high]
		scalar `est2' = _b[secondval_high]
		scalar `se2'  = _se[secondval_high]
		scalar `est3' = _b[firstval_low]
		scalar `se3'  = _se[firstval_low]
		scalar `est4' = _b[secondval_low]
		scalar `se4'  = _se[secondval_low]

		quietly {
			clear
			set obs 4
			gen double estimate = .
			gen double lcl = .
			gen double ucl = .
			gen period = .
			gen highlow = .
			forvalues i = 1/4 {
				replace estimate = `est`i'' in `i'
				replace lcl = `est`i'' - `zcrit'*`se`i'' in `i'
				replace ucl = `est`i'' + `zcrit'*`se`i'' in `i'
			}
			replace period  = cond(inlist(_n,1,3), 1, 2) // 1=Pre-test 2=Post-test
			replace highlow = cond(inlist(_n,1,2), 1, 2) // 1=Above cutoff 2=Below cutoff
		}

		twoway ///
			(rcap ucl lcl period if highlow==1, lcolor(black)) ///
			(connected estimate period if highlow==1, msymbol(O) mcolor(black) lcolor(black) lpattern(solid)) ///
			(rcap ucl lcl period if highlow==2, lcolor(black)) ///
			(connected estimate period if highlow==2, msymbol(S) mcolor(black) lcolor(black) lpattern(dash)), ///
			xlabel(1 "Pre-test" 2 "Post-test") xscale(range(0.7 2.3)) xtitle("") ///
			ylabel(, angle(horizontal)) ytitle("Expected Y variable range") ///
			legend(order(2 "Above cutoff" 4 "Below cutoff") position(6) rows(1)) ///
			// scheme(s1manual)
	}
	restore
end
