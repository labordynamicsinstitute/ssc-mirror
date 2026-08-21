*! xttvpivmg_example.do  1.0.0  19aug2026
*! Self-testing demonstration of xttvpivmg
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Reproduces the Monte Carlo design of section 3 of
*!   Bai, Marcellino & Kapetanios (2026), Econometrics and Statistics 37, 26-41
*! and checks that xttvpivmg recovers the TRUE time-varying mean coefficient
*! paths, that accuracy improves in both N and T, and that cross-validation
*! beats the rule-of-thumb bandwidth -- the paper's three central findings.
*!
*! Run with:   do xttvpivmg_example.do
*! Runtime:    a few minutes (Part 3 is the slow one; comment it out to skip)

version 14.0
clear
set more off

* ====================================================================== *
* PART 0.  Helper programs for the DGP                                    *
* ====================================================================== *

capture program drop _cmn_rw
program define _cmn_rw
    * COMMON scaled random walk  X_t = xi_t/sqrt(t),  xi a N(0,1)-innovation RW.
    * Drawn ONCE and shared by every unit -- these are the b0(t) paths, the
    * estimand.  Redrawing them per unit would make them idiosyncratic and the
    * estimator would have nothing common to recover.
    args nm
    tempvar e r
    qui gen double `e' = rnormal() if id==1
    qui bysort id (t): gen double `r' = sum(`e') if id==1
    qui gen double `nm' = `r'/sqrt(t) if id==1
    qui bysort t (id): replace `nm' = `nm'[1]
end

capture program drop _idi_rw
program define _idi_rw
    * UNIT-SPECIFIC scaled random walk: the e_it / Upsilon_it / iota_it
    * deviations.  Drawn separately for each unit.
    args nm
    tempvar e r
    qui gen double `e' = rnormal()
    qui bysort id (t): gen double `r' = sum(`e')
    qui gen double `nm' = `r'/sqrt(t)
end

capture program drop _cmn_rho
program define _cmn_rho
    * COMMON rho0(t) = scale * a_t / max_t|a_t|,  a_t a standard random walk.
    args nm scale
    tempvar e r a
    qui gen double `e' = rnormal() if id==1
    qui bysort id (t): gen double `r' = sum(`e') if id==1
    qui gen double `a' = abs(`r') if id==1
    qui su `a' if id==1, meanonly
    qui gen double `nm' = `scale'*`r'/r(max) if id==1
    qui bysort t (id): replace `nm' = `nm'[1]
end

capture program drop _idi_rho
program define _idi_rho
    * UNIT-SPECIFIC eps_it = scale * a_it / max_t|a_it|.
    args nm scale
    tempvar e r a m
    qui gen double `e' = rnormal()
    qui bysort id (t): gen double `r' = sum(`e')
    qui gen double `a' = abs(`r')
    qui bysort id: egen double `m' = max(`a')
    qui gen double `nm' = `scale'*`r'/`m'
end

capture program drop _ar1
program define _ar1
    * AR(1) regressor/instrument: x_it = rho x_i,t-1 + s_it, rho ~ U[-0.99,0.99]
    args nm
    tempvar s rho
    qui gen double `s' = rnormal()
    qui bysort id (t): gen double `rho' = runiform(-0.99,0.99) if _n==1
    qui bysort id (t): replace `rho' = `rho'[1]
    qui bysort id (t): gen double `nm' = `s'
    qui bysort id (t): replace `nm' = `rho'*`nm'[_n-1] + `s' if _n>1
end


* ====================================================================== *
* PART 1.  The BMK section-3 data generating process                      *
* ====================================================================== *
*
*   y_it   = a_it + rho_it y_i,t-1 + b1_it x1_it + b2_it x2_it + u_it
*   x2_it  = Psi1_it z1_it + Psi2_it z2_it + a2_it e2_it + v_it        (18)
*
*   u_it = a1_it q1_it + q2_it        )  time-varying correlation
*   v_it = a1_it q1_it + q3_it        )  between u and v
*
*   All time-varying parameters are scaled random walks (gamma = 1/2).
*   The a2_it*e2_it term in x2 induces CORRELATED RANDOM COEFFICIENTS:
*   the deviation e2_it of b2_it enters the endogenous regressor itself.
*   BMK's Theorem 1 survives this; a standard MG estimator would not.

capture program drop _bmk_dgp
program define _bmk_dgp
    syntax , n(integer) t(integer) [seed(integer 0)]

    clear
    if (`seed' > 0) set seed `seed'
    qui set obs `=`n'*`t''
    qui gen int id = ceil(_n/`t')
    qui bysort id: gen int t = _n
    xtset id t

    * ---- common (cross-sectionally shared) mean paths: THE ESTIMAND ---- *
    _cmn_rw  b0_1                     // b0,1(t)  -> coefficient on x1
    _cmn_rw  b0_2                     // b0,2(t)  -> coefficient on x2
    _cmn_rw  psi0_1                   // Psi0,1(t)
    _cmn_rw  psi0_2                   // Psi0,2(t)
    _cmn_rw  a0                       // alpha0(t) -> intercept
    _cmn_rw  a0_1                     // alpha0,1(t) -> endogeneity strength
    _cmn_rw  a0_2                     // alpha0,2(t) -> CRC loading
    _cmn_rho rho0 0.5                 // rho0(t), scaled to 0.5

    * ---- unit-specific deviations ------------------------------------- *
    _idi_rw  e_1                      // e_1,it
    _idi_rw  e_2                      // e_2,it   (also enters x2: CRC)
    _idi_rw  ups_1
    _idi_rw  ups_2
    _idi_rw  iot
    _idi_rw  iot_1
    _idi_rw  iot_2
    _idi_rho eps 0.49                 // eps_it, scaled to 0.49

    * ---- unit-level time-varying coefficients -------------------------- *
    qui gen double b1_it   = b0_1  + e_1
    qui gen double b2_it   = b0_2  + e_2
    qui gen double psi1_it = psi0_1 + ups_1
    qui gen double psi2_it = psi0_2 + ups_2
    qui gen double a_it    = a0    + iot
    qui gen double a1_it   = a0_1  + iot_1
    qui gen double a2_it   = a0_2  + iot_2
    qui gen double rho_it  = rho0  + eps

    * ---- exogenous regressor and instruments: AR(1) -------------------- *
    _ar1 x1
    _ar1 z1
    _ar1 z2

    * ---- errors with time-varying correlation -------------------------- *
    qui gen double q1 = rnormal()
    qui gen double q2 = rnormal()
    qui gen double q3 = rnormal()
    qui gen double u  = a1_it*q1 + q2
    qui gen double v  = a1_it*q1 + q3

    * ---- endogenous regressor (18) ------------------------------------- *
    qui gen double x2 = psi1_it*z1 + psi2_it*z2 + a2_it*e_2 + v

    * ---- dynamic dependent variable ------------------------------------ *
    qui bysort id (t): gen double y = a_it + b1_it*x1 + b2_it*x2 + u
    qui bysort id (t): replace y = a_it + rho_it*y[_n-1] ///
                                 + b1_it*x1 + b2_it*x2 + u if _n>1

    label var y    "dependent variable"
    label var x1   "exogenous regressor"
    label var x2   "endogenous regressor"
    label var z1   "instrument 1"
    label var z2   "instrument 2"
    label var b0_1 "TRUE b0,1(t)"
    label var b0_2 "TRUE b0,2(t)"
    label var rho0 "TRUE rho0(t)"
    label var a0   "TRUE alpha0(t)"
end


* ====================================================================== *
* PART 2.  Baseline run: does it recover the truth?                       *
* ====================================================================== *

di as txt _n "{hline 78}"
di as txt "PART 2  Baseline: N = 20, T = 200, rule-of-thumb bandwidth"
di as txt "{hline 78}"

_bmk_dgp, n(20) t(200) seed(20260819)

* x = (L.y, x1, x2, _cons)  k = 4
* z = (L.y, x1, z1, z2, _cons)  p = 5     -> overidentified, p > k
xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) graph summary name(base)

* ---------------------------------------------------------------- *
* Truth-versus-estimate check                                       *
* ---------------------------------------------------------------- *
* Column order of e(bmg) follows e(xnames): L.y, x1, x2, _cons
*   col 1 <-> rho0(t)   col 2 <-> b0,1(t)   col 3 <-> b0,2(t)   col 4 <-> alpha0(t)

tempname B S D
matrix `B' = e(bmg)
matrix `S' = e(semg)
matrix `D' = e(tlist)
local nrep = e(nrep)
di as txt _n "e(xnames) = " as res "`e(xnames)'"

preserve
    qui keep if id==1
    qui keep t rho0 b0_1 b0_2 a0
    tempfile truth
    qui save `truth'
restore

preserve
    clear
    qui svmat double `D', name(tt)
    qui svmat double `B', name(bb)
    qui svmat double `S', name(ss)
    qui rename tt1 t
    qui merge 1:1 t using `truth', keep(match) nogenerate

    di as txt _n "{hline 78}"
    di as txt "Recovery of the true paths  (median |estimate - truth| and coverage)"
    di as txt "{hline 78}"
    di as txt %-14s "parameter" _col(20) "MAD" _col(34) "95% cover" _col(50) "mean truth"
    di as txt "{hline 78}"

    local j = 0
    foreach pr in rho0 b0_1 b0_2 a0 {
        local ++j
        qui gen double ad = abs(bb`j' - `pr')
        qui gen byte cv = abs(bb`j' - `pr') <= 1.96*ss`j'
        qui su ad, detail
        local mad = r(p50)
        qui su cv, meanonly
        local cov = r(mean)
        qui su `pr', meanonly
        local tru = r(mean)
        di as txt %-14s "`pr'" as res _col(18) %8.4f `mad'    ///
           _col(34) %8.3f `cov' _col(50) %8.4f `tru'
        drop ad cv
    }
    di as txt "{hline 78}"
    di as txt "MAD should be small relative to the variation in the true path;"
    di as txt "coverage should be near 0.95 (BMK report 0.83-0.91 at this (N,T))."

    * ---- truth vs estimate, the key visual check ------------------- *
    qui gen lo3 = bb3 - 1.96*ss3
    qui gen hi3 = bb3 + 1.96*ss3
    twoway (rarea lo3 hi3 t, color(navy%20) lwidth(none))                 ///
           (line bb3 t, lcolor(navy) lwidth(medthick))                    ///
           (line b0_2 t, lcolor(cranberry) lpattern(dash) lwidth(medium)), ///
        title("Recovery of b0,2(t): the endogenous-regressor coefficient",  ///
              size(medium) color(black))                                    ///
        subtitle("solid = estimate, dashed = truth, band = 95% pointwise",   ///
              size(small) color(gs6))                                       ///
        ytitle("") xtitle("t") legend(off)                                 ///
        graphregion(color(white)) plotregion(color(white))                 ///
        ylabel(, angle(horizontal) grid glcolor(gs14))                     ///
        name(recovery, replace)
restore


* ====================================================================== *
* PART 3.  Consistency: accuracy must improve in BOTH N and T             *
* ====================================================================== *
* BMK Tables 1-3.  Small replication counts keep this quick; the pattern
* (MAD falling in N and in T) is already visible.  Comment out to skip.

di as txt _n "{hline 78}"
di as txt "PART 3  Consistency check over (N,T)   [this part is slow]"
di as txt "{hline 78}"

local reps 10
tempname RES
matrix `RES' = J(6, 3, .)
local row = 0

foreach nn in 10 20 {
    foreach tt in 100 200 {
        local ++row
        if (`row' > 6) continue
        local acc = 0
        local nok = 0
        forvalues r = 1/`reps' {
            * vary the seed every replication
            qui _bmk_dgp, n(`nn') t(`tt') seed(`=70000 + 137*`row' + `r'')
            capture qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5)
            if (_rc == 0) {
                tempname BB DD
                matrix `BB' = e(bmg)
                matrix `DD' = e(tlist)
                local nr = e(nrep)
                preserve
                    qui keep if id==1
                    qui keep t b0_2
                    tempfile tr2
                    qui save `tr2'
                restore
                preserve
                    clear
                    qui svmat double `DD', name(d)
                    qui svmat double `BB', name(b)
                    qui rename d1 t
                    qui merge 1:1 t using `tr2', keep(match) nogenerate
                    qui gen double ad = abs(b3 - b0_2)
                    qui su ad, detail
                    local acc = `acc' + r(p50)
                    local nok = `nok' + 1
                restore
            }
        }
        if (`nok' > 0) {
            matrix `RES'[`row',1] = `nn'
            matrix `RES'[`row',2] = `tt'
            matrix `RES'[`row',3] = `acc'/`nok'
        }
    }
}

di as txt _n "Average MAD for b0,2(t) over `reps' replications"
di as txt "{hline 40}"
di as txt %8s "N" %8s "T" _col(22) "avg MAD"
di as txt "{hline 40}"
forvalues r = 1/6 {
    if (`RES'[`r',1] < .) {
        di as res %8.0f `RES'[`r',1] %8.0f `RES'[`r',2] _col(20) %10.4f `RES'[`r',3]
    }
}
di as txt "{hline 40}"
di as txt "Expected: MAD falls as N rises and as T rises (BMK Table 1)."


* ====================================================================== *
* PART 4.  Cross-validation versus the rule of thumb                      *
* ====================================================================== *
* BMK's headline Monte Carlo result: CV delivers lower MAD and higher
* coverage than H = L = T^0.5, especially for the AR coefficient.

di as txt _n "{hline 78}"
di as txt "PART 4  CV versus rule-of-thumb bandwidth"
di as txt "{hline 78}"

_bmk_dgp, n(20) t(200) seed(4041)

di as txt _n "--- rule of thumb: H = L = T^0.5 ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5)
tempname BR SR DR
matrix `BR' = e(bmg)
matrix `SR' = e(semg)
matrix `DR' = e(tlist)
di as txt "H = " as res %6.2f e(H) as txt "   L = " as res %6.2f e(L)

di as txt _n "--- leave-one-unit-out cross-validation (coarse grid) ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), cv hgrid(0.3 0.5 0.7) lgrid(0.3 0.5 0.7) ///
     cvplot name(cvdemo)
tempname BC SC DC
matrix `BC' = e(bmg)
matrix `SC' = e(semg)
matrix `DC' = e(tlist)
di as txt "selected h = " as res %5.3f e(hexp) as txt "  l = " as res %5.3f e(lexp)
di as txt "H = " as res %6.2f e(H) as txt "   L = " as res %6.2f e(L)
di as txt "CV objective = " as res %12.2f e(cvmin)

preserve
    qui keep if id==1
    qui keep t rho0 b0_2
    tempfile tr3
    qui save `tr3'
restore

foreach which in R C {
    preserve
        clear
        qui svmat double `B`which'', name(b)
        qui svmat double `S`which'', name(s)
        qui svmat double `D`which'', name(d)
        qui rename d1 t
        qui merge 1:1 t using `tr3', keep(match) nogenerate
        qui gen double ad = abs(b1 - rho0)
        qui gen byte  cc = abs(b1 - rho0) <= 1.96*s1
        qui su ad, detail
        local m = r(p50)
        qui su cc, meanonly
        local c = r(mean)
        local lab "rule of thumb"
        if ("`which'"=="C") local lab "cross-validation"
        di as txt %-20s "`lab'" as txt " rho0(t):  MAD = " as res %7.4f `m'  ///
           as txt "   coverage = " as res %5.3f `c'
    restore
}
di as txt "Expected: cross-validation gives the lower MAD and higher coverage."


* ====================================================================== *
* PART 5.  Every kernel                                                   *
* ====================================================================== *

di as txt _n "{hline 78}"
di as txt "PART 5  Kernel comparison"
di as txt "{hline 78}"

_bmk_dgp, n(20) t(200) seed(5051)

foreach kk in gaussian epanechnikov rectangle exponential {
    qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) kernel(`kk')
    di as txt %-16s "`kk'" as txt "  H = " as res %6.2f e(H)  ///
       as txt "  dates reported = " as res %4.0f e(nrep)      ///
       as txt "  singular = " as res %3.0f e(nsing)
}
di as txt "BMK find the Gaussian kernel gives the lowest MAD (Tables 1-3)."


* ====================================================================== *
* PART 6.  Exercise every remaining code path                             *
* ====================================================================== *

di as txt _n "{hline 78}"
di as txt "PART 6  Option coverage"
di as txt "{hline 78}"

_bmk_dgp, n(15) t(120) seed(6061)

di as txt _n "--- 6.1 conservative Pesaran-Smith variance divisor N(N-1) ---"
xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) vce(mg)

di as txt _n "--- 6.2 no trimming (boundary points included) ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) notrimming
di as txt "dates reported = " as res e(nrep) as txt "  (should equal T = "  ///
   as res e(T) as txt ", which is 119 not 120 because L.y costs one period)"

di as txt _n "--- 6.3 explicit trim(), separate bandwidths ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.65) l(0.30) trim(20)
di as txt "H = " as res %6.2f e(H) as txt "  L = " as res %6.2f e(L)   ///
   as txt "  trim = " as res e(trim) as txt "  dates = " as res e(nrep)

di as txt _n "--- 6.4 bandwidths given directly in periods ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), bw(15) bwfirst(6)
di as txt "H = " as res %6.2f e(H) as txt " (h = " as res %5.3f e(hexp) as txt ")"

di as txt _n "--- 6.5 time-invariant fixed effects (Remark 1(b)) ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) demean(fixed)
di as txt "k = " as res e(k_x) as txt " (constant removed by demeaning)"

di as txt _n "--- 6.6 time-varying fixed effects (Remark 1(b), smoothed) ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) demean(tv)
di as txt "k = " as res e(k_x)

di as txt _n "--- 6.7 CV with the nminus1 leave-one-out divisor ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), cv hgrid(0.4 0.6) lgrid(0.4 0.6) ///
     cvdivisor(nminus1)
di as txt "selected h = " as res %5.3f e(hexp) as txt "  l = " as res %5.3f e(lexp)

di as txt _n "--- 6.8 untrimmed CV objective ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), cv hgrid(0.4 0.6) lgrid(0.4 0.6) nocvtrim
di as txt "selected h = " as res %5.3f e(hexp) as txt "  l = " as res %5.3f e(lexp)

di as txt _n "--- 6.9 per-unit paths in e(bi) ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) full
tempname BIchk
matrix `BIchk' = e(bi)
di as txt "e(bi) is " as res rowsof(`BIchk') as txt " x " as res colsof(`BIchk') ///
   as txt "  (N x nrep = " as res `=e(N_g)*e(nrep)' as txt " rows expected)"

di as txt _n "--- 6.10 tabulate at chosen dates, post that date to e(b) ---"
xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5) at(40 60 80) tref(60)
di as txt _n "test of the x1 coefficient at t = 60:"
test x1

di as txt _n "--- 6.11 replay at other dates and another level ---"
xttvpivmg, at(50 70) level(90)

di as txt _n "--- 6.12 predict ---"
qui xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5)
capture drop yhat uhat
predict double yhat, xb
predict double uhat, residuals
qui su yhat
di as txt "yhat: N = " as res r(N) as txt "  mean = " as res %8.4f r(mean)
qui corr y yhat
di as txt "corr(y, yhat) = " as res %6.4f r(rho)
qui su uhat
di as txt "residual mean = " as res %8.4f r(mean) as txt "  sd = " as res %8.4f r(sd)

di as txt _n "--- 6.13 error handling ---"
di as txt "(each of the following SHOULD fail with a clear message)"

capture noisily xttvpivmg y x1 x2, h(0.5)
di as txt "   -> rc = " as res _rc as txt " (missing (endog = insts) block)"

capture noisily xttvpivmg y (x1 x2 = z1), h(0.5)
di as txt "   -> rc = " as res _rc as txt " (underidentified: p = 2 < k = 3)"

preserve
    qui drop if id==1 & t<=5
    capture noisily xttvpivmg y L.y x1 (x2 = z1 z2), h(0.5)
    di as txt "   -> rc = " as res _rc as txt " (unbalanced panel)"
restore

capture noisily xttvpivmg y L.y x1 (x2 = z1 z2), h(0.99)
di as txt "   -> rc = " as res _rc as txt " (bandwidth trims away the whole sample)"


di as txt _n "{hline 78}"
di as txt "xttvpivmg_example.do complete."
di as txt ""
di as txt "What to check in this log:"
di as txt "  Part 2  MAD small, coverage near 0.95, 'recovery' graph tracks the truth"
di as txt "  Part 3  average MAD falls as N rises AND as T rises"
di as txt "  Part 4  cross-validation beats the rule of thumb on MAD and coverage"
di as txt "  Part 5  all four kernels run; Gaussian preferred"
di as txt "  Part 6  every option runs; the four error cases fail cleanly"
di as txt "{hline 78}"
