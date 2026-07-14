* ============================================================================
* xtmixedroot_example.do
* Validation of xtmixedroot against the Monte Carlo designs in
*   Ng (2008, JBES 26:113-127)        -- Models 1a, 2a, 3b
*   Westerlund (2016, JSPI 173:1-30)  -- fixed-T size and power, Tables 1-2
*
* Author: Merwan Roudane (merwanroudane920@gmail.com)
*
* Run AFTER installing xtmixedroot (ssc install xtmixedroot, or
* net install xtmixedroot, from(<folder>)). Runtime: a few minutes.
* ============================================================================
clear
set more off
capture which xtmixedroot
if _rc {
    di as err "xtmixedroot is not installed; install it first"
    exit 111
}
set seed 20260712

* ----------------------------------------------------------------------------
* Helper DGP notes
* Ng Model 1a: y_it = lam_i + u_it,
*   u_it = (a1+a2) u_it-1 - a2 u_it-2 + e_it,  e_it ~ N(0, sig_i^2)
*   I(1) units: a1 = 1;  I(0) units: a1 ~ U(.5,.99);  a2 ~ U(0,.2)
*   lam_i ~ U(-1,1), sig_i ~ U(.5,2)
* ----------------------------------------------------------------------------

* ============================================================================
* PART 1 -- Single sample, Ng Model 1a, theta = 0.5 (N=60, T=200)
* Expect: theta-hat close to 0.5; two-sided test of theta0(.5) not rejected;
* H0: theta=.01 and H0: theta=1 both rejected.
* ============================================================================
di as res _n "PART 1: Ng Model 1a, truth theta = 0.50, N=60, T=200" _n
quietly {
    clear
    set obs 60
    gen id = _n
    gen a1 = cond(_n <= 30, 1, .5 + .49*runiform())
    gen a2 = .2*runiform()
    gen sig = .5 + 1.5*runiform()
    gen lam = -1 + 2*runiform()
    expand 250
    bysort id: gen t = _n
    gen e = sig*rnormal()
    gen double u = e
    bysort id (t): replace u = (a1+a2)*u[_n-1] + e if _n == 2
    bysort id (t): replace u = (a1+a2)*u[_n-1] - a2*u[_n-2] + e if _n > 2
    bysort id (t): gen double u0 = u[50]
    replace u = u - u0 if a1 == 1
    drop if t <= 50
    replace t = t - 50
    gen y = lam + u
    xtset id t
}
xtmixedroot y, estimator(a) theta0(.5) classify list(10)
local th1 = r(theta)
di as txt _n "CHECK 1: |theta-hat - 0.5| = " as res %6.4f abs(`th1' - .5) ///
    as txt "  (expect < 0.15)"

* ============================================================================
* PART 2 -- Cross-sectional correlation: Ng Model 2-type, theta = 0.5
* y_it = lam_i F_t + u_it, F_t = .5 F_t-1 + w_t (common!), lam_i ~ N(0,1)
* Small MC (50 reps, N=60, T=100). Expect mean of Estimator A biased
* downward, Estimator B closer to 0.5 (Ng Tables 2-3: .459 vs .481)
* ============================================================================
di as res _n "PART 2: common-factor DGP, truth theta = 0.50, N=60, T=100, 50 reps" _n
local R = 50
local sA = 0
local sB = 0
forvalues r = 1/`R' {
    quietly {
        set seed `=20000 + `r''
        * the factor must be generated ONCE and shared by all units
        clear
        set obs 150
        gen t = _n
        gen w = rnormal()
        gen double F = w
        replace F = .5*F[_n-1] + w if _n > 1
        keep t F
        tempfile fac
        save `fac', replace

        clear
        set obs 60
        gen id = _n
        gen a1 = cond(_n <= 30, 1, .5 + .49*runiform())
        gen a2 = .2*runiform()
        gen sig = .5 + 1.5*runiform()
        gen lam = rnormal()
        expand 150
        bysort id: gen t = _n
        merge m:1 t using `fac', nogenerate
        sort id t
        gen e = sig*rnormal()
        gen double u = e
        bysort id (t): replace u = (a1+a2)*u[_n-1] + e if _n == 2
        bysort id (t): replace u = (a1+a2)*u[_n-1] - a2*u[_n-2] + e if _n > 2
        bysort id (t): gen double u0 = u[50]
        replace u = u - u0 if a1 == 1
        drop if t <= 50
        replace t = t - 50
        gen y = lam*F + u
        xtset id t
        xtmixedroot y, estimator(a) lags(2)
        local sA = `sA' + r(theta)
        xtmixedroot y, estimator(b) lags(2)
        local sB = `sB' + r(theta)
    }
}
di as txt _n "CHECK 2: MC mean est A = " as res %6.4f `sA'/`R' as txt ///
    ", est B = " as res %6.4f `sB'/`R' as txt ///
    "  (Ng Tables 3/2: .459 / .481; A below B, both near .5)"

* ============================================================================
* PART 3 -- Westerlund fixed-T statistics, single samples
* (a) theta = 1 (pure random walks, u_i0 = 0), T = 4, N = 200:
*     tau*_1,T should NOT reject H0: theta = 1
* (b) strongly stationary alternative (alpha = .5) for half the units, T = 4:
*     tau*_1,T should reject
* ============================================================================
di as res _n "PART 3: Westerlund fixed-T (T = 4, N = 200)" _n
quietly {
    clear
    set obs 200
    gen id = _n
    gen lam = 1
    expand 4
    bysort id: gen t = _n
    gen e = rnormal()
    gen double u = e
    bysort id (t): replace u = u[_n-1] + e if _n > 1
    gen y = lam + u
    xtset id t
}
xtmixedroot y
local ta = r(tau1T)
quietly {
    clear
    set obs 200
    gen id = _n
    gen a1 = cond(_n <= 100, 1, .5)
    gen lam = 1
    expand 4
    bysort id: gen t = _n
    gen e = rnormal()
    gen double u = e
    bysort id (t): replace u = a1*u[_n-1] + e if _n > 1
    gen y = lam + u
    xtset id t
}
xtmixedroot y
local tb = r(tau1T)
di as txt _n "CHECK 3: tau*_1,T under H0 = " as res %6.3f `ta' ///
    as txt " (expect > -1.645); under H1 = " as res %6.3f `tb' ///
    as txt " (expect < -1.645)"

* ============================================================================
* PART 4 -- MONTE CARLO
* (4a) Size of tau*_1,T at T = 4, N = 160 under theta = 1 (500 reps).
*      Westerlund Table 1 reports 3.7% at the 5% level; expect ~3-6%.
*      This check is decisive for the s2_eps denominator (N(T-1), not NT).
* (4b) Sampling behavior of the Ng estimator: Model 1a, N=30, T=100, p=2,
*      theta = .5, 200 reps. Ng Table 1 reports mean .517, N var/theta 2.996,
*      5% two-sided rejection .114. Expect mean in [.45,.58],
*      N var/theta in [1.5, 4.5], rejection in [.05, .20].
* ============================================================================
di as res _n "PART 4a: MC size of tau*_1,T (theta=1, T=4, N=160, 500 reps)" _n
local R = 500
local rej = 0
forvalues r = 1/`R' {
    quietly {
        set seed `=40000 + `r''
        clear
        set obs 160
        gen id = _n
        gen lam = 1
        expand 4
        bysort id: gen t = _n
        gen e = rnormal()
        gen double u = e
        bysort id (t): replace u = u[_n-1] + e if _n > 1
        gen y = lam + u
        xtset id t
        xtmixedroot y
        if (r(tau1T) < -1.645) local rej = `rej' + 1
    }
}
di as txt "CHECK 4a: empirical size of tau*_1,T = " as res %6.3f `rej'/`R' ///
    as txt "  (nominal .05; Westerlund Table 1: .035)"

di as res _n "PART 4b: MC for Ng estimator (Model 1a, theta=.5, N=30, T=100, 200 reps)" _n
local R = 200
local sum = 0
local ssq = 0
local rej = 0
forvalues r = 1/`R' {
    quietly {
        set seed `=50000 + `r''
        clear
        set obs 30
        gen id = _n
        gen a1 = cond(_n <= 15, 1, .5 + .49*runiform())
        gen a2 = .2*runiform()
        gen sig = .5 + 1.5*runiform()
        gen lam = -1 + 2*runiform()
        expand 150
        bysort id: gen t = _n
        gen e = sig*rnormal()
        gen double u = e
        bysort id (t): replace u = (a1+a2)*u[_n-1] + e if _n == 2
        bysort id (t): replace u = (a1+a2)*u[_n-1] - a2*u[_n-2] + e if _n > 2
        bysort id (t): gen double u0 = u[50]
        replace u = u - u0 if a1 == 1
        drop if t <= 50
        replace t = t - 50
        gen y = lam + u
        xtset id t
        xtmixedroot y, lags(2) theta0(.5)
        local sum = `sum' + r(theta)
        local ssq = `ssq' + r(theta)^2
        if (r(p) < .05) local rej = `rej' + 1
    }
}
local mth = `sum'/`R'
local vth = `ssq'/`R' - `mth'^2
di as txt "CHECK 4b: mean theta-hat = " as res %6.4f `mth' ///
    as txt " (Ng Table 1: .517)"
di as txt "          N x var(theta-hat)/theta = " as res %6.3f 30*`vth'/.5 ///
    as txt " (Ng Table 1: 2.996; theory: 2)"
di as txt "          5% two-sided rejection of true H0 = " as res %6.3f `rej'/`R' ///
    as txt " (Ng Table 1: .114)"

* ============================================================================
* PART 5 -- Estimator C: incidental trends (Ng Model 3b), theta = .5
* y_it = lam_i t + u_it, lam_i ~ U(-.1,.1), u_it as Model 1a with sig_i = 1.
* N = 200, T = 300 (the paper itself needs samples this large for C).
* Expect theta-hat within ~.15 of .5 (Ng Table 4: mean .499 at these sizes).
* ============================================================================
di as res _n "PART 5: Estimator C, incidental trends, theta = .5, N=200, T=300" _n
quietly {
    clear
    set obs 200
    gen id = _n
    gen a1 = cond(_n <= 100, 1, .5 + .49*runiform())
    gen a2 = .2*runiform()
    gen lam = -.1 + .2*runiform()
    expand 350
    bysort id: gen t = _n
    gen e = rnormal()
    gen double u = e
    bysort id (t): replace u = (a1+a2)*u[_n-1] + e if _n == 2
    bysort id (t): replace u = (a1+a2)*u[_n-1] - a2*u[_n-2] + e if _n > 2
    bysort id (t): gen double u0 = u[50]
    replace u = u - u0 if a1 == 1
    drop if t <= 50
    replace t = t - 50
    gen y = lam*t + u
    xtset id t
}
xtmixedroot y, estimator(c) theta0(.5)
local thC = r(theta)
di as txt _n "CHECK 5: Estimator C theta-hat = " as res %6.4f `thC' ///
    as txt "  (truth .5; large variance is expected, Ng Sec. 5)"

* ============================================================================
* PART 6 -- tau*_theta0 at theta0 = .5 with true theta = .5
* (eta = 0 alternative: stationary units have alpha = .5), T = 80, N = 320.
* Westerlund Table 6 shows this test is conservative; expect |tau| < 1.96.
* ============================================================================
di as res _n "PART 6: tau*_theta0, theta0 = truth = .5, T=80, N=320" _n
quietly {
    clear
    set obs 320
    gen id = _n
    gen a1 = cond(_n <= 160, 1, .5)
    gen lam = rnormal()
    expand 80
    bysort id: gen t = _n
    gen e = rnormal()
    gen double u = e
    bysort id (t): replace u = a1*u[_n-1] + e if _n > 1
    gen y = lam + u
    xtset id t
}
xtmixedroot y, theta0(.5)
local t6 = r(tautheta0)
di as txt _n "CHECK 6: tau*_theta0 = " as res %6.3f `t6' ///
    as txt "  (expect |tau| < 1.96, test is conservative)"

di as res _n "ALL PARTS COMPLETE -- compare each CHECK line with its expectation." _n
