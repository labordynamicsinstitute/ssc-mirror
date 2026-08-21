*------------------------------------------------------------------------------
* xtflucbreak_example.do
* Self-test / validation harness for xtflucbreak 1.0.0
*
* Reproduces the two Monte Carlo designs of
*   Li F, Xiao Y & Chen Z (2024) "A Fluctuation Test for Structural Change
*   Detection in Heterogeneous Panel Data Models", J. Syst. Sci. Complex.
*   37(3), 1184-1208.  <doi:10.1007/s11424-024-2064-0>
* Model 1 = section 5.1 (no common correlated effects)
* Model 2 = section 5.2 (common correlated effects)
*
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*         https://github.com/merwanroudane
*
* HOW TO RUN
*   cd  "<this folder>"
*   do  xtflucbreak.ado          // compiles the Mata block, shows any error line
*   do  xtflucbreak_example.do
*
* RELOADING AFTER AN EDIT -- read this, it bites every time.
*   -discard- only unloads programs that Stata loaded AUTOMATICALLY from the
*   adopath.  A program you defined by -do-ing this .ado is not one of those,
*   so -discard- leaves it in memory and the next -do xtflucbreak.ado- aborts
*   with "program xtflucbreak already defined", r(110) -- BEFORE defining
*   anything.  Your next call then silently runs the STALE code.
*   Always drop explicitly first:
*
*       capture program drop xtflucbreak
*       capture program drop _xtfb_efetch
*       capture program drop _xtfb_display
*       capture program drop _xtfb_graphs
*       discard
*       do xtflucbreak.ado
*
*   Or, better, reinstall so the adopath copy is the fresh one:
*
*       capture ado uninstall xtflucbreak
*       net install xtflucbreak, from("<this folder>") replace
*       discard
*
* NOTE: -clear-, never -clear all- : the latter would drop the just-loaded
*       program.
*------------------------------------------------------------------------------

version 14.0
set more off
capture log close _all
log using "xtflucbreak_selftest.smcl", replace name(xtfb)

di as text _n(2) "{hline 79}"
di as text "xtflucbreak 1.0.0 -- self test"
di as text "{hline 79}"


/*==============================================================================
  DGP 1 : Li-Xiao-Chen section 5.1  (no common correlated effects)

    y_it = x_it'(beta_i + delta_i 1{t > k0}) + e_it
    x_it = (1, x1_it)',  x1_it ~ iid N(1,1),  independent of e_it
    beta_1i ~ N(1, 0.04)   [variance]   -> sd 0.2
    beta_2i ~ N(2, 0.04)                -> sd 0.2
    errors:  iid      e_it ~ N(0,1)
             unequal  e_it ~ N(0, sig2_i),  sig2_i ~ U(0.5,1.5)
             garch    e_it = sqrt(h_it) eps_it,  h_it = .2 + .3 h_i,t-1 + .3 e2_i,t-1
==============================================================================*/
capture program drop xtfb_dgp1
program define xtfb_dgp1
    syntax , N(integer) T(integer) K0(integer) D1(real) D2(real) ///
             [ ERRors(string) FRACtion(real 1) ]

    if ("`errors'"=="") local errors "iid"

    clear
    qui set obs `=`n'*`t''
    qui gen long id = ceil(_n/`t')
    qui bysort id: gen int t = _n
    xtset id t

    * heterogeneous slopes: ONE draw per panel (not per observation)
    qui by id: gen double b1i = rnormal(1, 0.2) if _n==1
    qui by id: replace b1i = b1i[1]
    qui by id: gen double b2i = rnormal(2, 0.2) if _n==1
    qui by id: replace b2i = b2i[1]

    * only a fraction of the panels break (LXC Table 5 / Table 9)
    qui by id: gen byte brk = (runiform() <= `fraction') if _n==1
    qui by id: replace brk = brk[1]

    qui gen double x1 = rnormal(1, 1)

    * ---- errors -------------------------------------------------------------
    if ("`errors'"=="iid") {
        qui gen double e = rnormal(0, 1)
    }
    else if ("`errors'"=="unequal") {
        qui by id: gen double s2i = runiform(0.5, 1.5) if _n==1
        qui by id: replace s2i = s2i[1]
        qui gen double e = rnormal(0, sqrt(s2i))
    }
    else if ("`errors'"=="garch") {
        * LXC write   e_it = sqrt(h_it) eps_it,  h_it = .2 + .3 h_i,t-1 + .3 e^2_i,t-1
        * i.e. h is the conditional VARIANCE; unconditional level .2/(1-.6) = .5.
        * h_t and e_t are mutually recursive, so they must be filled period by
        * period -- a single -by id: replace- would read an e[_n-1] that has not
        * been computed yet from t = 3 onwards.
        qui gen double eps = rnormal(0, 1)
        qui gen double h   = .
        qui gen double e   = .
        sort id t
        qui replace h = 0.2/(1-0.3-0.3) if t==1
        qui replace e = sqrt(h)*eps     if t==1
        forvalues s = 2/`t' {
            qui replace h = 0.2 + 0.3*h[_n-1] + 0.3*(e[_n-1])^2 if t==`s'
            qui replace e = sqrt(h)*eps                          if t==`s'
        }
    }
    else {
        di as error "errors() must be iid, unequal or garch"
        exit 198
    }

    * ---- the regression ----------------------------------------------------
    qui gen byte post = (t > `k0')
    qui gen double y = (b1i + `d1'*post*brk) + (b2i + `d2'*post*brk)*x1 + e
    qui keep id t y x1 brk
    label var y  "y"
    label var x1 "x1"
end


/*==============================================================================
  DGP 2 : Li-Xiao-Chen section 5.2  (common correlated effects)

    y_it   = alpha_i + x_it'(beta_i + delta_i 1{t > k0}) + e_it
    x_it   = Gamma_i' f_t + v_it        (K = 2, no constant column)
    e_it   = gamma_i f_t + eps_it
    alpha_i ~ N(1,1) ; Gamma_1i ~ N(0,0.5) ; Gamma_2i ~ N(0.5,0.5)
    v_it ~ N(0, diag(0.75, 0.5)) ; gamma_i ~ N(0.2,0.5)
    f_t = 0.5 f_{t-1} + vf_t , vf_t ~ N(0,0.75)   -- ONE common series
    eps_it ~ N(0, sig2_i) , sig2_i ~ U(0.5,1.5)
    (all second arguments above are VARIANCES, as in beta ~ N(1,0.04))
==============================================================================*/
capture program drop xtfb_dgp2
program define xtfb_dgp2
    syntax , N(integer) T(integer) K0(integer) D1(real) D2(real) ///
             [ FRACtion(real 1) ]

    clear
    qui set obs `=`n'*`t''
    qui gen long id = ceil(_n/`t')
    qui bysort id: gen int t = _n
    xtset id t

    * ---- the COMMON factor: drawn once, shared by every panel ---------------
    * (a per-observation rnormal() here would make it idiosyncratic and the
    *  CCE filter would have nothing common left to remove)
    qui gen double vf = rnormal(0, sqrt(0.75)) if id==1
    qui bysort t (id): replace vf = vf[1]
    sort id t
    qui by id: gen double f = vf     if _n==1
    qui by id: replace f = 0.5*f[_n-1] + vf if _n>1

    * ---- panel-specific parameters: ONE draw per panel ----------------------
    foreach v in a_i G1i G2i b1i b2i g_i s2i {
        qui by id: gen double `v' = . if _n==1
    }
    qui by id: replace a_i = rnormal(1, 1)              if _n==1
    qui by id: replace G1i = rnormal(0, sqrt(0.5))      if _n==1
    qui by id: replace G2i = rnormal(0.5, sqrt(0.5))    if _n==1
    qui by id: replace b1i = rnormal(1, 0.2)            if _n==1
    qui by id: replace b2i = rnormal(2, 0.2)            if _n==1
    qui by id: replace g_i = rnormal(0.2, sqrt(0.5))    if _n==1
    qui by id: replace s2i = runiform(0.5, 1.5)         if _n==1
    foreach v in a_i G1i G2i b1i b2i g_i s2i {
        qui by id: replace `v' = `v'[1]
    }

    qui by id: gen byte brk = (runiform() <= `fraction') if _n==1
    qui by id: replace brk = brk[1]

    * ---- regressors correlated with the factor ------------------------------
    qui gen double x1 = G1i*f + rnormal(0, sqrt(0.75))
    qui gen double x2 = G2i*f + rnormal(0, sqrt(0.50))

    * ---- errors with the factor loading -------------------------------------
    qui gen double e = g_i*f + rnormal(0, sqrt(s2i))

    qui gen byte post = (t > `k0')
    qui gen double y = a_i + (b1i + `d1'*post*brk)*x1 + (b2i + `d2'*post*brk)*x2 + e
    qui keep id t y x1 x2 f brk
    label var y  "y"
    label var x1 "x1"
    label var x2 "x2"
end


/*==============================================================================
  PART A -- Model 1, break present.  The command must (i) reject and
            (ii) put khat on/near k0 = T/2.
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART A  Model 1 (no CCE), N=50 T=100, break at k0=50, delta=(0.1,0.1)"
di as text "        EXPECT: H0 rejected;  khat close to 50"
di as text "{hline 79}"

set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)
xtflucbreak y x1, graph showunits listunits(8)

di as text _n " CHECK  khat = " as result r(khat) as text "   (true k0 = 50)"
di as text " CHECK  reject = " as result r(reject) as text "   (want 1)"
di as text " CHECK  stat   = " as result %8.4f r(stat) as text "  cv = " as result %8.4f r(cv)
di as text " CHECK  literal LXC stat = " as result %8.4f r(stat_lxc)
di as text " CHECK  cv must be 1.4781 for K=2 at 5% (LXC Rem. 3.5 prints 1.4782)"
di as text " CHECK  grid must start at " as result r(kmin) as text " = ceil(0.10*100) = 10, not 2"


/*==============================================================================
  PART B -- Model 1 under H0.  The command must NOT reject.
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART B  Model 1 under H0 (delta = 0).  EXPECT: H0 not rejected"
di as text "{hline 79}"

set seed 424242
xtfb_dgp1, n(50) t(100) k0(50) d1(0) d2(0) errors(iid)
xtflucbreak y x1

di as text _n " CHECK  reject = " as result r(reject) as text "   (want 0 in ~95% of draws)"
di as text " CHECK  p      = " as result %6.4f r(p)


/*==============================================================================
  PART C -- robustness of the error process (LXC section 5.1, three cases)
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART C  Error-process robustness: unequal variances, then GARCH(1,1)"
di as text "        EXPECT: H0 rejected in both (LXC Tables 2-3: power ~ 1)"
di as text "{hline 79}"

set seed 777001
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(unequal)
xtflucbreak y x1
di as text " unequal variances:  khat = " as result r(khat) as text "  reject = " as result r(reject)

set seed 777002
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(garch)
xtflucbreak y x1
di as text " GARCH(1,1)       :  khat = " as result r(khat) as text "  reject = " as result r(reject)


/*==============================================================================
  PART D -- only half the panels break (LXC Table 5)
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART D  Only 50% of panels break, delta = (0, 0.2).  EXPECT: still rejects"
di as text "{hline 79}"

set seed 555001
xtfb_dgp1, n(100) t(100) k0(50) d1(0) d2(0.2) errors(iid) fraction(0.5)
xtflucbreak y x1, showunits listunits(6)
di as text " CHECK  khat = " as result r(khat) as text "   reject = " as result r(reject)


/*==============================================================================
  PART E -- Model 2 (CCE branch).  Without -cce- the test is applied to data
            whose regressors and errors share a factor; with -cce- the factor
            is filtered out.  Both are shown.

  These single-draw DEMONSTRATIONS use LXC's delta = (0.2, 0)' design, whose
  power at N = T = 100 is ~1.00 (LXC Table 7), so one draw is a reliable
  illustration.  The weaker delta = (0.1, 0.1)' design has power ~0.98 there --
  fine on average but it fails on roughly one draw in fifty, which makes a
  useless demonstration.  The harder designs are measured properly, over many
  replications, in PART K.
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART E  Model 2 (common factors), N=100 T=100, break at k0=50, delta=(0.2,0)"
di as text "{hline 79}"

set seed 90210
xtfb_dgp2, n(100) t(100) k0(50) d1(0.2) d2(0)

di as text _n " E1. section-3 branch on factor-contaminated data (misspecified)"
xtflucbreak y x1 x2

di as text _n " E2. section-4 branch: -cce- (EXPECT: reject, khat near 50)"
xtflucbreak y x1 x2, cce graph
di as text " CHECK  khat = " as result r(khat) as text "   (true k0 = 50)"
di as text " CHECK  reject = " as result r(reject) as text "   (want 1)"

di as text _n " E3. -cce- under H0 (EXPECT: no rejection)"
set seed 90211
xtfb_dgp2, n(100) t(100) k0(50) d1(0) d2(0)
xtflucbreak y x1 x2, cce
di as text " CHECK  reject = " as result r(reject) as text "   p = " as result %6.4f r(p)

di as text _n " E4. infeasible benchmark: the TRUE factor f as a regressor control"
di as text "     (only to show the CCE filter is doing the right job)"
set seed 90210
xtfb_dgp2, n(100) t(100) k0(50) d1(0.2) d2(0)
xtflucbreak y x1 x2 f
di as text " CHECK  khat = " as result r(khat)


/*==============================================================================
  PART F -- benchmark tests (Antoch et al. 2018) via -compare-
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART F  compare: Wald 1, Wald 2 and CUSUM with the wild bootstrap"
di as text "        EXPECT (LXC Tables 2-3): fluctuation rejects; Wald tests reject"
di as text "        with lower power; CUSUM is the weakest"
di as text "{hline 79}"

set seed 31415
xtfb_dgp1, n(50) t(50) k0(25) d1(0.1) d2(0.1) errors(iid)
xtflucbreak y x1, compare reps(299) seed(31415) graph

di as text _n " CHECK  fluctuation p = " as result %6.4f r(p)
di as text " CHECK  Wald 1 p      = " as result %6.4f r(wald1_p)
di as text " CHECK  Wald 2 p      = " as result %6.4f r(wald2_p)
di as text " CHECK  CUSUM  p      = " as result %6.4f r(cusum_p)


/*==============================================================================
  PART G -- every remaining option, exercised once
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART G  Option coverage"
di as text "{hline 79}"

set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)

di as text _n " G1. trimming(0.15)"
xtflucbreak y x1, trimming(0.15)
di as text "     grid = " as result r(kmin) as text " ... " as result r(kmax)

di as text _n " G2. cholesky root (component 1 is then a pure x1 contrast)"
xtflucbreak y x1, cholesky

di as text _n " G3. noconstant (drops the intercept from x_it)"
xtflucbreak y x1, noconstant
di as text "     K = " as result r(K) as text "   (want 1)"

di as text _n " G4. level(1)"
xtflucbreak y x1, level(1)
di as text "     cv = " as result %8.4f r(cv) as text "  (must exceed the 5% value 1.4781)"

di as text _n " G5. nowarnings"
xtflucbreak y x1, nowarnings

di as text _n " G5b. asymptotic (literal LXC statistic drives the decision)"
xtflucbreak y x1, asymptotic
di as text "      stat = " as result %8.4f r(stat) as text "   must equal r(stat_lxc) from G0 = " as result %8.4f r(stat_lxc)

di as text _n " G5c. trimming(0) + asymptotic -- the configuration that over-rejects."
di as text "      The k=K end has ~1e6 times the bridge variance, but that is driven by"
di as text "      RARE near-collinear early pairs, so most single draws look normal."
di as text "      The damage is only visible in the size loop (PART J): 0.72 vs 0.05."
xtflucbreak y x1, asymptotic trimming(0)
di as text "      grid started at k = " as result r(kmin) as text " (= K), stat = " as result %10.2f r(stat)

set seed 90210
xtfb_dgp2, n(100) t(100) k0(50) d1(0.2) d2(0)

di as text _n " G6. cce nocceconstant  (literal LXC p.1190 M_w, no constant column)"
xtflucbreak y x1 x2, cce nocceconstant

di as text _n " G7. cce ccalags(1)  (augment W with one lag of the averages)"
xtflucbreak y x1 x2, cce ccalags(1)
di as text "     T effective = " as result r(T) as text "  (want 99)"

di as text _n " G8. cce nosigmascale  (literal LXC section-4 display, no 1/sigma_i)"
xtflucbreak y x1 x2, cce nosigmascale

di as text _n " G9. stored results"
set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)
qui xtflucbreak y x1
return list


/*==============================================================================
  PART H -- postestimation
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART H  Postestimation: reuse the model in memory"
di as text "{hline 79}"

set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)

di as text _n " H1. after xtreg, fe"
xtreg y x1, fe
xtflucbreak
di as text "     khat = " as result r(khat)

di as text _n " H2. after regress"
regress y x1
xtflucbreak
di as text "     khat = " as result r(khat)

di as text _n " H3. after xtmg (if installed) -- must NOT auto-select the CCE branch"
capture which xtmg
if (_rc==0) {
    capture noisily xtmg y x1
    if (_rc==0) {
        capture noisily xtflucbreak
    }
}
else di as text "     xtmg not installed -- skipped"

di as text _n " H4. after xtmg, cce -- must auto-select the CCE branch"
set seed 90210
xtfb_dgp2, n(100) t(100) k0(50) d1(0.2) d2(0)
capture which xtmg
if (_rc==0) {
    capture noisily xtmg y x1 x2, cce
    if (_rc==0) {
        di as text "      e(title2) = " as result "`e(title2)'" as text "   (xtmg flags the variant here, NOT in e(cmdline))"
        capture noisily xtflucbreak
        di as text "      transform = " as result "`r(transform)'"
        di as text "      K = " as result r(K) as text "   (want 2: the CCE branch absorbs the intercept)"
    }
}
else di as text "     xtmg not installed -- skipped"

di as text _n " H4b. after xtmg, augment (AMG) -- also a factor-controlling estimator"
capture which xtmg
if (_rc==0) {
    capture noisily xtmg y x1 x2, augment
    if (_rc==0) {
        di as text "      e(title2) = " as result "`e(title2)'"
        capture noisily xtflucbreak
        di as text "      transform = " as result "`r(transform)'"
    }
}
else di as text "     xtmg not installed -- skipped"

di as text _n " H5. after xtbfkbreak (if installed)"
capture which xtbfkbreak
if (_rc==0) {
    capture noisily xtbfkbreak y x1 x2, breaks(1)
    if (_rc==0) {
        capture noisily xtflucbreak
    }
}
else di as text "     xtbfkbreak not installed -- skipped"

di as text _n " H6. no estimation results in memory -- must error cleanly with r(301)"
set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)
ereturn clear
capture noisily xtflucbreak
di as text "     _rc = " as result _rc as text "   (want 301)"

di as text _n " H7. unsupported estimator (mean) -- must error cleanly with r(301)"
qui mean y
capture noisily xtflucbreak
di as text "     _rc = " as result _rc as text "   (want 301)"


/*==============================================================================
  PART I -- error handling
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART I  Error handling"
di as text "{hline 79}"

set seed 20260807
xtfb_dgp1, n(50) t(100) k0(50) d1(0.1) d2(0.1) errors(iid)

di as text _n " I1. unbalanced panel -> must refuse with r(459)"
preserve
    qui drop if id==3 & t>60
    capture noisily xtflucbreak y x1
    di as text "     _rc = " as result _rc as text "   (want 459)"
restore

di as text _n " I2. not xtset -> must refuse"
preserve
    qui xtset, clear
    capture noisily xtflucbreak y x1
    di as text "     _rc = " as result _rc
restore
xtset id t

di as text _n " I3. trimming out of range -> r(198)"
capture noisily xtflucbreak y x1, trimming(0.6)
di as text "     _rc = " as result _rc as text "   (want 198)"

di as text _n " I4. ccalags without cce -> r(198)"
capture noisily xtflucbreak y x1, ccalags(2)
di as text "     _rc = " as result _rc as text "   (want 198)"


/*==============================================================================
  PART J -- Monte Carlo: empirical SIZE and POWER
            This is the block that actually proves the test is calibrated.
            LXC Table 1 (iid, N=50, T=50): size ~ 0.050
            LXC Table 2 (delta = (0.1,0.1)', k0 = T/2): power ~ 1
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART J  Monte Carlo size and power (Model 1, iid errors, N=50, T=50)"
di as text "        200 replications.  This takes a minute or two."
di as text ""
di as text "        Reference values from an independent NumPy reimplementation (500 reps):"
di as text "          default (standardised, trimming .10):  size .038 / power .970"
di as text "          asymptotic + trimming(.10)          :  size .050 / power .988"
di as text "          asymptotic + trimming(0)            :  size .674"
di as text "        LXC Table 1/2 published               :  size .050 / power 1.000"
di as text "{hline 79}"

local R = 200

* ---- SIZE ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=100000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0) d2(0) errors(iid)
    qui xtflucbreak y x1
    local rej = `rej' + r(reject)
}
di as text _n " SIZE  (nominal 0.05) = " as result %5.3f `=`rej'/`R'' ///
    as text "     target ~0.038 (default);  LXC Table 1: 0.050"

* ---- SIZE on the literal LXC statistic, for comparison ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=100000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0) d2(0) errors(iid)
    qui xtflucbreak y x1, asymptotic
    local rej = `rej' + r(reject)
}
di as text " SIZE  (asymptotic)   = " as result %5.3f `=`rej'/`R'' ///
    as text "     target ~0.050;  LXC Table 1: 0.050"

* ---- SIZE with no trimming: the configuration that fails ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=100000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0) d2(0) errors(iid)
    qui xtflucbreak y x1, asymptotic trimming(0)
    local rej = `rej' + r(reject)
}
di as text " SIZE  (asy, trim 0)  = " as result %5.3f `=`rej'/`R'' ///
    as text "     target ~0.674 -- the literal max over 1<k<T"

* ---- POWER, break in the middle ----
local rej = 0
local hit = 0
forvalues r = 1/`R' {
    set seed `=200000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0.1) d2(0.1) errors(iid)
    qui xtflucbreak y x1
    local rej = `rej' + r(reject)
    if (abs(r(khat)-25)<=3) local hit = `hit' + 1
}
di as text " POWER (k0 = T/2)     = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 2, N=T=50, iid: 1.000"
di as text " khat within +/-3 of k0 = " as result %5.3f `=`hit'/`R'' ///
    as text "   (LXC Figure 4: concentration improves with N)"

* ---- POWER, break near the start (LXC Table 4: lower power at k0 = T/4) ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=300000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(13) d1(0.1) d2(0.1) errors(iid)
    qui xtflucbreak y x1
    local rej = `rej' + r(reject)
}
di as text " POWER (k0 = T/4)     = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 4, N=T=50: 0.760"

* ---- SIZE, unequal variances ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=400000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0) d2(0) errors(unequal)
    qui xtflucbreak y x1
    local rej = `rej' + r(reject)
}
di as text " SIZE  (unequal var)  = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 1, N=T=50: 0.081"

* ---- SIZE, GARCH ----
local rej = 0
forvalues r = 1/`R' {
    set seed `=500000+`r''
    qui xtfb_dgp1, n(50) t(50) k0(25) d1(0) d2(0) errors(garch)
    qui xtflucbreak y x1
    local rej = `rej' + r(reject)
}
di as text " SIZE  (GARCH(1,1))   = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 1, N=T=50: 0.069"


/*==============================================================================
  PART K -- Monte Carlo for the CCE branch (Model 2)
            LXC Table 6, N=50, T=50: size 0.059
            LXC Table 7, N=50, T=50, delta=(0.1,0.1)': power 0.38
==============================================================================*/
di as text _n(2) "{hline 79}"
di as text "PART K  Monte Carlo, CCE branch (Model 2, N=50, T=50), 200 replications"
di as text "{hline 79}"

local R = 200

local rej = 0
forvalues r = 1/`R' {
    set seed `=600000+`r''
    qui xtfb_dgp2, n(50) t(50) k0(25) d1(0) d2(0)
    qui xtflucbreak y x1 x2, cce
    local rej = `rej' + r(reject)
}
di as text _n " SIZE  (cce)  = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 6, N=50 T=50: 0.059"

local rej = 0
forvalues r = 1/`R' {
    set seed `=700000+`r''
    qui xtfb_dgp2, n(50) t(50) k0(25) d1(0.1) d2(0.1)
    qui xtflucbreak y x1 x2, cce
    local rej = `rej' + r(reject)
}
di as text " POWER (cce)  = " as result %5.3f `=`rej'/`R'' ///
    as text "     LXC Table 7, N=50 T=50, delta=(.1,.1): 0.380"

local rej = 0
forvalues r = 1/`R' {
    set seed `=800000+`r''
    qui xtfb_dgp2, n(50) t(50) k0(25) d1(0.2) d2(0)
    qui xtflucbreak y x1 x2, cce
    local rej = `rej' + r(reject)
}
di as text " POWER (cce, delta=(.2,0)) = " as result %5.3f `=`rej'/`R'' ///
    as text "  LXC Table 7: 0.870"


di as text _n(2) "{hline 79}"
di as text "Self test finished.  Paste xtflucbreak_selftest.smcl back for review."
di as text "{hline 79}"

log close xtfb
