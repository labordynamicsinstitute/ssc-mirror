*! ardldml_mcheck.do  1.0.1  24aug2026
*! Monte Carlo size and power check for ardldml
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  ardldml is a resampling test, and a resampling test can compute a perfectly
*  correct statistic and still return badly wrong p-values. Matching a
*  reference implementation does not catch that; only a size study does. This
*  file is that study, kept separate from ardldml_example.do because it takes
*  roughly half an hour.
*
*  Design: the paper's Appendix B setup. Y = D + u with D a driftless random
*  walk and u an AR(1). rho = 1 is the no-cointegration null, rho = 0.5 the
*  alternative. The nuisance block is half I(1) random walks and half
*  stationary AR(1), 100 observations burnt in.
*
*  What to look for:
*    size  -- rejection rate at or below nominal. A conservative resampling
*             test is acceptable and safe; an over-rejecting one is not.
*             Anything near 0.20+ at a nominal 0.05 means the bootstrap is
*             not reproducing the null and must be fixed, not tuned.
*    power -- well above nominal, otherwise the test cannot find a relation
*             that is genuinely there.
*
*  Cost is roughly linear in REPS * BREPS. At d = 20 controls and B = 99 a
*  replication runs about fifteen seconds, so the defaults below take on the
*  order of 25 minutes. 50 replications cannot separate 0.05 from 0.10, but it
*  separates 0.05 from 0.25 comfortably, which is the failure this guards
*  against. Raise REPS for a publishable number.
*
*  Result on record (23 Aug 2026, 40 replications per arm, B = 99, T = 120,
*  d = 20 controls of which 10 are I(1), Stata 19.5):
*
*      SIZE  (rho = 1, no cointegration)
*        rejection rate at nominal 5%   = 0.075   (3 of 40)
*        rejection rate at nominal 10%  = 0.150   (6 of 40)
*
*      POWER (rho = 0.5, cointegrated)
*        rejection rate at nominal 5%   = 0.575   (23 of 40)
*        rejection rate at nominal 10%  = 0.725   (29 of 40)
*
*      failed replications, both arms   = 0
*
*  Size is controlled. Both figures sit within Monte Carlo error of nominal
*  at this many replications -- the standard error on a true 0.05 is 0.035,
*  so 0.075 is well under one standard error away (exact binomial p = 0.32).
*  40 replications cannot separate 0.05 from 0.10 and are not meant to; what
*  they rule out is gross over-rejection, and there is none. For contrast,
*  the paper reports a rejection rate of 0.737 under an integrated-nuisance
*  null when the statistic is read against the borrowed 5.73 bound instead
*  of a bootstrap critical value.
*
*  Power is ample. For scale, the paper's own Monte Carlo reports 0.667 and
*  0.917 for its two main designs, both at T = 200; this runs at T = 120, so
*  a lower figure is expected. A single fit under the alternative at T = 200
*  rejects at p = 0.003 and returns a long-run coefficient of 0.956 with a
*  95% interval covering the true 1.

version 14.0
clear
set more off

local REPS  = 50
local BREPS = 99

local wl ""
forvalues j = 1/20 {
	local wl "`wl' w`j'"
}
local i1 ""
forvalues j = 1/10 {
	local i1 "`i1' w`j'"
}

capture program drop _ardldml_dgp
* The paper's Appendix B design. Y = D + u with D a driftless random walk
* and u an AR(1); rho = 1 is the no-cointegration null, rho = 0.5 the
* alternative. The nuisance block is half I(1) random walks and half
* stationary AR(1) with coefficient 0.5, and 100 observations are burnt in.
capture program drop _ardldml_dgp
program define _ardldml_dgp
	syntax , NOBS(integer) DIM(integer) RHO(real) [FRACI1(real 0.5)]
	local burn = 100
	local TT = `nobs' + `burn'
	clear
	set obs `TT'
	gen int t = _n
	tsset t

	local nI1 = round(`dim' * `fraci1')
	forvalues j = 1/`dim' {
		tempvar e`j'
		qui gen double `e`j'' = rnormal()
		qui gen double w`j' = 0
		if (`j' <= `nI1') {
			qui replace w`j' = L.w`j' + `e`j'' if t > 1
		}
		else {
			qui replace w`j' = 0.5*L.w`j' + `e`j'' if t > 1
		}
	}

	qui gen double ed = rnormal()
	qui gen double eu = rnormal()
	qui gen double d = 0
	qui replace d = L.d + ed if t > 1
	qui gen double u = 0
	qui replace u = `rho'*L.u + eu if t > 1
	qui gen double y = d + u

	qui drop if t <= `burn'
	qui replace t = t - `burn'
	tsset t
end


di _n(2) as text "{hline 78}"
di as text "Monte Carlo: size and power"
di as text "{hline 78}"
di as text "`REPS' replications, B = `BREPS', T = 120, d = 20 controls (half I(1))."
di as text "This takes roughly 25 minutes at these settings."
di as text "A resampling test that merely runs can still return wrong p-values;"
di as text "only this check can tell. Note the seed is varied on EVERY replication:"
di as text "a fixed seed would reset the wild-weight stream and make size degenerate."
di ""

foreach spec in "1 size" "0.5 power" {
	local rho : word 1 of `spec'
	local lab : word 2 of `spec'
	local nrej05 = 0
	local nrej10 = 0
	local ngood  = 0

	forvalues r = 1/`REPS' {
		set seed `=70000 + `r''
		qui _ardldml_dgp, nobs(120) dim(20) rho(`rho')
		capture qui ardldml y d, controls(`wl') integrated(`i1')	///
			lags(2) blocks(5) buffer(3) breps(`BREPS')				///
			seed(`=90000 + `r'')
		if (_rc == 0 & e(p) < .) {
			local ++ngood
			local nrej05 = `nrej05' + (e(p) < 0.05)
			local nrej10 = `nrej10' + (e(p) < 0.10)
		}
		if (mod(`r', 20) == 0) di as text "    `lab': `r'/`REPS' done"
	}

	di ""
	di as text "  `lab' (rho = `rho'), `ngood' usable replications:"
	di as text "    rejection rate at 5%  = " as res %6.3f `=`nrej05'/`ngood''
	di as text "    rejection rate at 10% = " as res %6.3f `=`nrej10'/`ngood''
	if ("`lab'" == "size") {
		di as text "    (should be near or below nominal; a conservative"
		di as text "     resampling test is acceptable and safe)"
	}
	else {
		di as text "    (should be well above nominal)"
	}
}


capture program drop _ardldml_dgp

di _n(2) as text "{hline 78}"
di as result "Monte Carlo check complete."
di as text "{hline 78}"
