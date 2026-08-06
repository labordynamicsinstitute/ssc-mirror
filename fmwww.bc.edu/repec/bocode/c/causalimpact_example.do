*! causalimpact_example.do  1.0.0  05aug2026
*! Self-test / validation harness for the causalimpact package
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! GitHub: https://github.com/merwanroudane
*
*  Every example below has a KNOWN TRUTH, so the log can be refereed.
*  Sections:
*     0  environment
*     1  R-vignette DGP            (truth: absolute effect = 10 per period)
*     2  dated series              (same numbers, dates on the x-axis)
*     3  many covariates           (spike-and-slab must drop the irrelevant ones)
*     4  seasonal component        (truth: effect = 10, weekly seasonality)
*     5  dynamic regression        (paper Sec. 3 DGP, truth: +10% lift)
*     6  no covariates             (level-only counterfactual)
*     7  PLACEBO / specificity     (truth: NO effect -> must be insignificant)
*     8  options, generate(), predict, report, plots
*     9  Monte Carlo: coverage, specificity and power (paper Fig. 3b-3c)
*
*  Run with:   do causalimpact_example.do
* ---------------------------------------------------------------------------

clear
set more off
capture log close _all
log using causalimpact_example.log, replace text

di as txt _n(2) "{hline 79}"
di as txt "causalimpact -- self test"
di as txt "Stata version: " c(stata_version) "   flavour: " c(flavor)
di as txt "{hline 79}"

which causalimpact


* ===========================================================================
* 1.  R-vignette DGP.  TRUTH: y is lifted by exactly 10 units from t = 71.
*     Expected: absolute effect ~ 10, relative ~ +11%, p < 0.05.
*     These are the numbers printed by the R vignette (average effect 11,
*     95% interval [9.8, 11]) up to Monte Carlo error.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "1. Basic analysis -- TRUE pointwise effect = 10, TRUE cumulative = 300"
di as txt "{hline 79}"

clear
set seed 1
set obs 100
gen int t = _n
tsset t

gen double x1 = 0
replace     x1 = 0.999*x1[_n-1] + rnormal() in 2/l
replace     x1 = x1 + 100

gen double y = 1.2*x1 + rnormal()
replace     y = y + 10 if t >= 71

causalimpact y x1, pre(1 70) post(71 100) niter(1000) seed(12345)

di as txt _n "TRUTH  : pointwise effect = 10 , cumulative effect = 300"
di as txt "ESTIMATE: pointwise = " as res %8.3f e(abseffect)     ///
   as txt " , cumulative = " as res %9.3f e(abseffect_cum)
di as txt "Recovery error (cumulative, %) = "                    ///
   as res %6.2f 100*(e(abseffect_cum)-300)/300

matrix list e(summary), format(%9.4f)


* ===========================================================================
* 2.  Same data, but with real dates.  Numbers must be identical.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "2. Dated series -- same DGP, dates on the axis"
di as txt "{hline 79}"

clear
set seed 1
set obs 100
gen double x1 = 0
replace     x1 = 0.999*x1[_n-1] + rnormal() in 2/l
replace     x1 = x1 + 100
gen double y = 1.2*x1 + rnormal()
gen t = td(01jan2014) + _n - 1
format t %td
tsset t
replace y = y + 10 if t >= td(12mar2014)

causalimpact y x1, pre(`=td(01jan2014)' `=td(11mar2014)')       ///
                   post(`=td(12mar2014)' `=td(10apr2014)')      ///
                   niter(1000) seed(12345) graph name(ci_dated)

di as txt _n "TRUTH  : cumulative effect = 300"
di as txt "ESTIMATE: " as res %9.3f e(abseffect_cum)


* ===========================================================================
* 3.  Ten candidate covariates, only two of which matter.
*     TRUTH: x1 and x2 belong in the model; x3..x10 are pure noise and their
*     posterior inclusion probabilities should be LOW.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "3. Variable selection -- TRUE predictors are x1 and x2 only"
di as txt "{hline 79}"

clear
set seed 777
set obs 120
gen int t = _n
tsset t

forvalues k = 1/10 {
    gen double x`k' = 0
    replace     x`k' = 0.98*x`k'[_n-1] + rnormal() in 2/l
    replace     x`k' = x`k' + 50
}
gen double y = 0.8*x1 + 0.5*x2 + rnormal()
replace     y = y + 6 if t >= 91

causalimpact y x1-x10, pre(1 90) post(91 120) niter(1000) seed(999) ///
    modelsize(3) coefplot name(ci_sel)

di as txt _n "TRUTH  : cumulative effect = " as res %8.1f 6*30
di as txt "ESTIMATE: " as res %9.3f e(abseffect_cum)
di as txt _n "Inclusion probabilities (x1, x2 should be high; x3-x10 low):"
matrix list e(inclusion), format(%9.4f)


* ===========================================================================
* 4.  Weekly seasonality.  TRUTH: effect = 10, day-of-week pattern present.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "4. Seasonal component -- nseasons(7)"
di as txt "{hline 79}"

clear
set seed 424
set obs 140
gen int t = _n
tsset t
gen double x1 = 0
replace     x1 = 0.99*x1[_n-1] + rnormal() in 2/l
replace     x1 = x1 + 80

gen byte dow = mod(t-1, 7)
gen double seas = 4*cos(2*_pi*dow/7) - 2*sin(2*_pi*dow/7)
gen double y = 1.1*x1 + seas + rnormal()
replace     y = y + 10 if t >= 111

causalimpact y x1, pre(1 110) post(111 140) nseasons(7) seasonduration(1) ///
    niter(1000) seed(5150)

di as txt _n "TRUTH  : cumulative effect = 300"
di as txt "ESTIMATE: " as res %9.3f e(abseffect_cum)


* ===========================================================================
* 5.  Paper Sec. 3 simulation DGP (dynamic regression).
*     y_t = b1t*z1t + b2t*z2t + mu_t + eps_t
*       b_jt ~ N(b_j,t-1, 0.01^2), b_j0 = 1
*       z1, z2 sinusoids of wavelength 90 and 360 days
*       mu_t ~ N(mu_t-1, 0.1^2), mu_0 = 0 ;  eps_t ~ N(0, 0.1^2)
*     Post-intervention block multiplied by (1 + e), e = 0.10.
*     TRUTH: relative effect = +10%.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "5. Paper Sec. 3 DGP -- TRUE relative effect = +10%"
di as txt "{hline 79}"

clear
set seed 20140101
set obs 546                       // 1jan2013 .. 30jun2014
gen int t = _n
tsset t

gen double z1 = sin(2*_pi*t/90)
gen double z2 = sin(2*_pi*t/360)

gen double b1 = 1
replace     b1 = b1[_n-1] + rnormal(0, 0.01) in 2/l
gen double b2 = 1
replace     b2 = b2[_n-1] + rnormal(0, 0.01) in 2/l
* The paper starts the level at mu_0 = 0.  A MULTIPLICATIVE lift on a
* zero-mean series makes the relative effect sum(y)/sum(cf)-1 numerically
* meaningless (the paper measures detection rate, not relative effect, for
* this design).  We start the level at 10 so that +10% is well posed;
* everything else is exactly the paper's DGP.
gen double mu = 10
replace     mu = mu[_n-1] + rnormal(0, 0.1)  in 2/l

gen double y = b1*z1 + b2*z2 + mu + rnormal(0, 0.1)
replace     y = y*1.10 if t >= 366          // intervention on 1 January 2014

causalimpact y z1 z2, pre(1 365) post(366 546) dynamicregression ///
    niter(1000) seed(31415)

di as txt _n "TRUTH  : relative effect = +10.00%"
di as txt "ESTIMATE: " as res %8.3f 100*e(releffect) "%"
di as txt "{p 0 2}NOTE: this design has LOW POWER over a 181-period horizon."
di as txt "R itself returns roughly +3% with a 95% interval near [-11%, +21%]"
di as txt "and p about 0.37 -- the truth is inside the interval but the effect"
di as txt "is not detected. The target here is AGREEMENT WITH R, not exact"
di as txt "recovery of +10%. See paper Fig. 4(a).{p_end}"


* ===========================================================================
* 6.  No covariates at all -- the counterfactual is a pure local level.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "6. Level-only model (no covariates)"
di as txt "{hline 79}"

clear
set seed 606
set obs 100
gen int t = _n
tsset t
gen double y = 20
replace     y = y[_n-1] + rnormal(0, 0.3) in 2/l
replace     y = y + 5 if t >= 71

causalimpact y, pre(1 70) post(71 100) niter(1000) seed(606) priorlevelsd(0.1)

di as txt _n "TRUTH  : pointwise effect = 5"
di as txt "ESTIMATE: " as res %8.3f e(abseffect)


* ===========================================================================
* 7.  PLACEBO.  TRUTH: there is NO intervention.  The command must NOT find
*     a significant effect (paper Sec. 4, Analysis 3: specificity check).
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "7. PLACEBO -- TRUE effect = 0, expect an INSIGNIFICANT result"
di as txt "{hline 79}"

clear
set seed 31337
set obs 100
gen int t = _n
tsset t
gen double x1 = 0
replace     x1 = 0.99*x1[_n-1] + rnormal() in 2/l
replace     x1 = x1 + 100
gen double y = 1.2*x1 + rnormal()          // NO lift anywhere

causalimpact y x1, pre(1 70) post(71 100) niter(1000) seed(31337)

di as txt _n "TRUTH  : effect = 0 ; p should be > 0.05 and the CI should cover 0"
di as txt "p = " as res %7.4f e(p) as txt "   -> " ///
   as res cond(e(p) > 0.05, "PASS (insignificant)", "FAIL (spurious effect)")


* ===========================================================================
* 8.  Remaining code paths: options, generate(), predict, report, plots.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "8. Option / postestimation coverage"
di as txt "{hline 79}"

clear
set seed 1
set obs 100
gen int t = _n
tsset t
gen double x1 = 0
replace     x1 = 0.999*x1[_n-1] + rnormal() in 2/l
replace     x1 = x1 + 100
gen double x2 = 0
replace     x2 = 0.95*x2[_n-1] + rnormal() in 2/l
replace     x2 = x2 + 30
gen double y = 1.2*x1 + 0.3*x2 + rnormal()
replace     y = y + 10 if t >= 71

di as txt _n "8a. 90% intervals via level()"
causalimpact y x1 x2, pre(1 70) post(71 100) niter(500) seed(1) level(90) nodots

di as txt _n "8b. alpha() -- the R spelling of the same thing"
causalimpact y x1 x2, pre(1 70) post(71 100) niter(500) seed(1) alpha(0.10) ///
    nodots notable
di as txt "alpha = " as res e(alpha) as txt "  level = " as res e(level)

di as txt _n "8c. nostandardize"
causalimpact y x1 x2, pre(1 70) post(71 100) niter(500) seed(1) ///
    nostandardize nodots notable
di as txt "standardised: " as res "`e(standardize)'"

di as txt _n "8d. maxflips() and noconstant"
causalimpact y x1 x2, pre(1 70) post(71 100) niter(500) seed(1) ///
    maxflips(1) noconstant nodots notable
di as txt "maxflips = " as res e(maxflips)

di as txt _n "8e. generate(), graph, coefplot, report"
causalimpact y x1 x2, pre(1 70) post(71 100) niter(1000) seed(1) ///
    generate(ci) replace graph coefplot report name(ci_full)

di as txt _n "Generated variables:"
describe ci_*
summarize ci_pred ci_lower ci_upper ci_effect ci_cum_effect ci_avg_effect

di as txt _n "Cumulative effect must be EXACTLY zero before the post-period:"
list t ci_cum_effect in 68/73, noobs

di as txt _n "8f. predict"
predict cf_hat,   counterfactual
predict cf_lo,    lower
predict cf_up,    upper
predict eff_hat,  effect
predict ceff_hat, cumeffect
predict xbhat,    xb
summarize cf_hat cf_lo cf_up eff_hat ceff_hat xbhat

di as txt _n "predict must reproduce generate() exactly:"
gen double _chk1 = reldif(cf_hat, ci_pred)
gen double _chk2 = reldif(ceff_hat, ci_cum_effect)
summarize _chk1 _chk2

di as txt _n "8g. replay"
causalimpact

di as txt _n "8h. stored results"
ereturn list


* ===========================================================================
* 9.  Monte Carlo: interval coverage, specificity and power.
*     Paper Fig. 3(b) power curve and Fig. 3(c) coverage.
*     NOTE: seed() is varied every replication -- with a fixed seed the
*     internal RNG resets and the rejection rate is degenerate.
* ===========================================================================
di as txt _n "{hline 79}"
di as txt "9. Monte Carlo (this section is the slow one)"
di as txt "{hline 79}"

local R    = 20        // replications per cell; raise to 100+ for tight bars
local NIT  = 400       // MCMC draws per replication

foreach e of numlist 0 0.05 0.25 {

    local rej   = 0
    local cover = 0
    local bias  = 0

    forvalues r = 1/`R' {
        quietly {
            clear
            set seed `=5000 + 137*`r''
            set obs 100
            gen int t = _n
            tsset t
            gen double x1 = 0
            replace     x1 = 0.99*x1[_n-1] + rnormal() in 2/l
            replace     x1 = x1 + 100
            gen double y0 = 1.2*x1 + rnormal()
            gen double y  = y0
            replace     y = y0*(1 + `e') if t >= 71

            * true cumulative effect for this replication
            gen double truth = (y - y0) if t >= 71
            summarize truth, meanonly
            local trueeff = r(sum)

            capture noisily causalimpact y x1, pre(1 70) post(71 100) ///
                niter(`NIT') seed(`=90000 + 7*`r'') nodots notable

            if (_rc == 0) {
                local lo = e(summary)[2,7]
                local hi = e(summary)[2,8]
                if (`lo' > 0 | `hi' < 0)                 local rej   = `rej' + 1
                if (`lo' <= `trueeff' & `hi' >= `trueeff') local cover = `cover' + 1
                local bias = `bias' + (e(abseffect_cum) - `trueeff')
            }
        }
    }

    di as txt "true lift = " as res %5.2f 100*`e' "%" ///
       as txt "   rejection rate = " as res %5.3f `rej'/`R'   ///
       as txt "   95% coverage = "   as res %5.3f `cover'/`R' ///
       as txt "   mean bias = "      as res %9.3f `bias'/`R'
}

di as txt _n "{hline 79}"
di as txt "EXPECTED, if the command is correct:"
di as txt "  lift =  0%  -> rejection rate near or below 0.05 (specificity)"
di as txt "  lift =  5%  -> rejection rate moderate"
di as txt "  lift = 25%  -> rejection rate high (paper Fig. 3b: most cases)"
di as txt "  coverage near 0.95 at every lift (paper Fig. 3c)"
di as txt "  mean bias near zero at every lift"
di as txt "{hline 79}"

di as txt _n "causalimpact self-test complete."
log close
