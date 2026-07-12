*! xtbfkbreak_example.do  -- self-test / demonstration
*! Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Simulates the Baltagi-Feng-Kao data-generating processes and exercises
*! every code path of xtbfkbreak.  Designed so the printed output and graphs
*! can be inspected directly (no Stata MCP needed).
*!
*! DGPs follow BFK (2016) Model 2 and BFK (2019):
*!   y_it   = a_i + b_i(k0)*x_it + e_it
*!   e_it   = g1_i*f_t + rho*v_it + sqrt(1-rho^2)*eps_it      (endogeneity)
*!   x_it   = a_i + g2_i*f_t + v_it
*! with a common slope break at k0 = 0.5T.

clear                 // NB: 'clear' not 'clear all' -- 'clear all' would drop
set more off          //     the xtbfkbreak program from memory before we use it
set seed 20260711

*---------------------------------------------------------------------*
* 0.  Program to simulate a BFK panel
*     rho controls Cov(eps,v): 0 = exogenous (2016), !=0 = endogenous (2019)
*---------------------------------------------------------------------*
capture program drop _sim_bfk
program define _sim_bfk
    syntax , n(integer) t(integer) [ rho(real 0) k1(integer 0) nofac ]
    clear
    local NT = `n'*`t'
    set obs `NT'
    gen int id   = ceil(_n/`t')
    bysort id: gen int t = _n
    local k0 = floor(0.5*`t')
    if (`k1'==0) local k1 = `k0'      // no loading break unless requested

    * ---- individual heterogeneous parameters ----
    bysort id: gen double a_i   = rnormal(1,1)      if _n==1
    bysort id: gen double b1_i  = rnormal(1,0.2)    if _n==1   // regime-1 slope
    bysort id: gen double del_i = rnormal(0.6,0.2)  if _n==1   // slope jump
    bysort id: gen double g1_i  = rnormal(1,0.2)    if _n==1   // error loading
    bysort id: gen double g2_i  = rnormal(0.5,0.5)  if _n==1   // regressor loading
    bysort id: gen double dg_i  = rnormal(0.5,0.5)  if _n==1   // loading jump (k1)
    bysort id: gen double g3_i  = rnormal(1,0.5)    if _n==1   // instrument loading
    bysort id: gen double sig_i = runiform(0.5,1.5) if _n==1
    foreach v in a_i b1_i del_i g1_i g2_i dg_i g3_i sig_i {
        bysort id (t): replace `v' = `v'[1]
    }

    * ---- one COMMON factor: a single stationary AR(1) path shared by every
    *      panel (same f_t for all i -- this is what CCE partials out).  Using
    *      a scalar recursion guarantees the value is common across panels. ----
    tempname Fp Fc
    gen double f = .
    quietly {
        scalar `Fp' = 0
        forval tt = 1/`t' {
            scalar `Fc' = 0.5*`Fp' + rnormal(0, sqrt(1-0.25))
            if (`tt'==1) scalar `Fc' = rnormal(0,1)
            replace f = `Fc' if t==`tt'
            scalar `Fp' = `Fc'
        }
    }
    if ("`nofac'"!="") replace f = 0      // Model 1: no common factor

    * ---- disturbances (v is the ENDOGENOUS idiosyncratic error) ----
    gen double v   = rnormal(0, sqrt(1-0.25))
    gen double eps = rnormal(0, sig_i)

    * ---- external instrument z: exogenous, loads on the common factor and
    *      carries its own idiosyncratic variation (independent of v, eps) ----
    gen double z = 2*a_i + g3_i*f + rnormal(0,1)

    * ---- regressor: driven by the instrument (strong first stage), the common
    *      factor, and the endogenous idiosyncratic v.  z enters x through a term
    *      that SURVIVES the CCE + fixed-effect transformation, so z is a valid
    *      strong instrument (as in BFK 2019, Fig. 2: x = 0.5 z + v). ----
    gen double x = a_i + g2_i*f + 0.7*z + v

    * ---- error: common factor (loading may break at k1) + endogeneity rho*v ----
    gen double load = g1_i
    replace     load = g1_i + dg_i if t> `k1'          // break in loadings at k1
    gen double e = load*f + `rho'*v + sqrt(1-`rho'^2)*eps

    * ---- outcome with common slope break at k0 ----
    gen double b_it = b1_i
    replace     b_it = b1_i + del_i if t> `k0'
    gen double y = a_i + b_it*x + e

    label var y "outcome"
    label var x "regressor (endogenous when rho!=0)"
    label var z "instrument"
    char _dta[k0] `k0'
    char _dta[k1] `k1'
end

*=====================================================================*
* 1.  EXOGENOUS model, one break  (Baltagi-Feng-Kao 2016)
*=====================================================================*
_sim_bfk , n(50) t(40) rho(0)
xtset id t
local truek0 : char _dta[k0]
di as txt _n "True break k0 = " as res "`truek0'"  as txt "  (should be recovered below)"

xtbfkbreak y x, breaks(1) graph
di as txt _n ">>> estimated break e(breaks) = " as res "`e(breaks)'"

*=====================================================================*
* 2.  ENDOGENOUS regressor, one break  (Baltagi-Feng-Kao 2019)
*     Cov(eps,v) induced via rho=0.5; instrument z used for x.
*=====================================================================*
_sim_bfk , n(50) t(40) rho(0.5)
xtset id t

* naive: ignore endogeneity (CCE-MG, biased slopes)
xtbfkbreak y (x = z), breaks(1)      // parentheses -> IV slopes (2019)
di as txt _n ">>> estimated break e(breaks) = " as res "`e(breaks)'"

*=====================================================================*
* 3.  OLS vs IV break search  (BFK 2019, Figure 2)
*=====================================================================*
xtbfkbreak y (x = z), breaks(1)               // OLS search (default)
local kOLS "`e(breaks)'"
xtbfkbreak y (x = z), breaks(1) ivbreak       // IV search
local kIV  "`e(breaks)'"
di as txt _n "Break: OLS-search = " as res "`kOLS'" as txt "   IV-search = " as res "`kIV'"

*=====================================================================*
* 4.  NO factor structure (Model 1) + endogeneity  -- factor-free DGP
*     (larger N,T: per-panel MG-IV is an asymptotic estimator)
*=====================================================================*
_sim_bfk , n(200) t(60) rho(0.5) nofac
xtset id t
xtbfkbreak y (x = z), breaks(1) nocce

*=====================================================================*
* 5.  TWO common breaks
*=====================================================================*
_sim_bfk , n(60) t(60) rho(0)
xtset id t
xtbfkbreak y x, breaks(2) trim(0.15) graph

*=====================================================================*
* 6.  Consistency check: does k-hat collapse to k0 as N grows?  (Theorem 1)
*=====================================================================*
di as txt _n "{hline 60}"
di as txt "Theorem 1 check: P(k-hat = k0) should rise with N"
di as txt "{hline 60}"
foreach nn in 10 50 200 {
    _sim_bfk , n(`nn') t(40) rho(0.5)
    xtset id t
    local k0 : char _dta[k0]
    qui xtbfkbreak y (x = z), breaks(1)
    di as txt "N = " as res %4.0f `nn' as txt "   k0 = " as res "`k0'" ///
       as txt "   k-hat = " as res "`e(breaks)'"
}

di as txt _n "Example finished.  Graphs: xtbfk_ssr, xtbfk_coef."
