*! 2.0.0 Ariel Linden 16aug2026 - added analytic std errs
*! 1.3.0 Ariel Linden 07mar2013 - added figure option
*! 1.2.0 Ariel Linden 16feb2013 - added %RTM to program
*! 1.1.0 Ariel Linden 14feb2013 - had corr2data generate posttest. Have rtmcii call rtm_calc.
*! 1.0.0 Ariel Linden 07feb2013

capture program drop rtmcii
program define rtmcii, eclass
	version 11.0
	syntax anything(id="argument numlist") [, PERiod(int 1) N(int 1000) VCE(string) BOOTstrap ///
		SEED(integer 1234) REPS(integer 1000) SIZE(string) LEVel(real 95) SAVING(string) Format(str) FIGure]

	preserve

	if "`format'" != "" {
		confirm numeric format `format'
	}
	else local format %05.3f

	local variable_tally : word count `anything'
	if (`variable_tally' > 4) {
		di as error "too many arguments"
		exit 103
	}
	if (`variable_tally' < 4) {
		di as error "too few arguments"
		exit 102
	}

	gettoken mu1 0 : 0 				// mean of "pre" period
	confirm number `mu1'
	gettoken sd1 0 : 0, parse(" ,") // sd of "pre" period
	confirm number `sd1'
	gettoken k 0 : 0, parse(" ,")  // cutoff on baseline period variable
	confirm number `k'
	gettoken rho 0 : 0, parse(" ,")  // corr between "pre and "post" periods
	confirm number `rho'

	local m = `period'

	if "`level'" != "" {
		set level `level'
		local level `level'
	}

	local vce = lower("`vce'")
	if "`vce'" != "" {
		local nmatch = 0
		local vcematch ""
		// vce(normal) requires >=3 characters
		if strlen("`vce'") >= 3 & substr("normal",1,strlen("`vce'")) == "`vce'" {
			local ++nmatch
			local vcematch "normal"
		}
		if substr("bootstrap",1,strlen("`vce'")) == "`vce'" {
			local ++nmatch
			local vcematch "bootstrap"
		}
		if `nmatch' == 0 {
			di as error "vce(`vce') not allowed; vce() must be either normal (abbreviate as nor or longer) or bootstrap"
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
	if "`vce'" == "" local vce "normal"

	if "`vce'" == "normal" {
		local Nn = `n'

		tempname b V
		matrix `b' = (`mu1', `sd1', `rho')
		matrix colnames `b' = mu sd rho

		tempname Vmu Vsd Vrho Csdrho
		scalar `Vmu'    = (`sd1')^2 / `Nn'
		scalar `Vsd'    = (`sd1')^2 / (2*`Nn')
		scalar `Vrho'   = (1 - (`rho')^2)^2 / `Nn'
		scalar `Csdrho' = (`sd1') * (`rho') * (1 - (`rho')^2) / (2*`Nn')

		matrix `V' = (`Vmu', 0, 0 \ 0, `Vsd', `Csdrho' \ 0, `Csdrho', `Vrho')
		matrix colnames `V' = mu sd rho
		matrix rownames `V' = mu sd rho

		ereturn post `b' `V', obs(`Nn')

		local bmu  "_b[mu]"
		local bsd  "_b[sd]"
		local brho "_b[rho]"
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

		ereturn local cmd "rtmcii"
		ereturn local vce "normal"
		ereturn local vcetype "Normal"
		ereturn scalar k = `k'
		ereturn scalar rho = `rho'
		ereturn scalar m = `m'
		ereturn scalar N = `Nn'
		di as txt ""
		di as txt %67s "Number of obs" as txt " = " as res %9.0fc `Nn'
		ereturn display
	}
	else {
		clear

		if "`seed'" != "" {
			`version' set seed `seed'
		}

		matrix means = (`mu1',`mu1')
		matrix sds = (`sd1',`sd1')
		matrix C = (1, `rho' \ `rho', 1)
		corr2data pretest posttest, n(`n') corr(C) means(means) sds(sds)

		bootstrap mu = r(mu) sd = r(sd) rho = r(rho) firstval_high = r(firstval_high) secondval_high = r(secondval_high) rtm_high = r(rtm_high) pct_rtm_high = r(pct_rtm_high) ///
		firstval_low = r(firstval_low) secondval_low=r(secondval_low) rtm_low = r(rtm_low) pct_rtm_low = r(pct_rtm_low), seed(`seed') reps(`reps') size(`size') level(`level') saving(`saving'): ///
		rtm_calc pretest posttest , k(`k') m(`m') seed(`seed') reps(`reps') size(`size') level(`level') saving(`saving')

		ereturn local cmd "rtmcii"
		ereturn local vce "bootstrap"
		ereturn scalar k = `k'
		ereturn scalar rho = `rho'
		ereturn scalar m = `m'
	}

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
