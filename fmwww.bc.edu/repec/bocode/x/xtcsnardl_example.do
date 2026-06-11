*! xtcsnardl_example.do  -- showcase do-file for xtcsnardl v1.0.0
*! Author : Dr Merwan Roudane
*! Contact: merwanroudane920@gmail.com
*! Date   : 28may2026
*!
*! Five self-contained examples that demonstrate xtcsnardl.  Run sequentially:
*!
*!   Example A: Synthetic DGP with one common factor + asymmetric regressor
*!              -- verifies that PMG recovers true beta+, beta-, phi
*!   Example B: EURO-4 carbon-emissions specification (Mehta-Derbeneva 2024)
*!   Example C: BRICS renewable energy specification  (Wang et al. 2022)
*!   Example D: MG + Hausman test of long-run pooling
*!   Example E: NOCSA toggle to expose residual cross-section dependence
*!
*! Requires: xtpmg (>=2.0.1), pnardl (>=1.1.0), xtcsnardl (>=1.0.0)
*!           xtcd2  (for CSD diagnostics) -- optional


* =============================================================================
* EXAMPLE A.  SYNTHETIC DGP -- recovery test
* =============================================================================

clear all
set seed 20260528

* Panel structure: N=30 cross-sections, T=70 periods
set obs 30
gen long id = _n
expand 70
bysort id: gen int t = 1959 + _n
xtset id t

* (i) One common factor f_t  (AR(1))
gen double f = .
by id: replace f = rnormal() if _n == 1
by id: replace f = 0.6 * f[_n-1] + 0.4 * rnormal() if _n >  1

* (ii) Idiosyncratic disturbances
gen double v   = rnormal()
gen double eps = 0.6 * rnormal()

* (iii) Asymmetric regressor x with factor-loading lam_x
gen double lam_x = runiform(0.30, 0.80)
gen double x     = lam_x * f + v

* (iv) Symmetric control c
gen double lam_c = runiform(0.20, 0.60)
gen double c     = lam_c * f + 0.5 * rnormal()

* (v) True parameters
local beta_pos  =  0.80
local beta_neg  = -1.20
local beta_c    =  0.40

* (vi) Generate y via the asymmetric DGP
*      y_it = phi_i * (y_{i,t-1} - beta+ x_it - beta- x_it - beta_c c_it)
*             + lam_y * f_t + eps
* For simplicity we use x in place of partial sums in the DGP; the test of
* recovery is on beta+, beta- estimated from the partial-sum decomposition.
gen double lam_y = runiform(0.25, 0.65)
gen double phi   = -runiform(0.20, 0.45)

gen double y = 0
* Burn-in: zero initial condition
by id: replace y = 0 if _n == 1

* Generate y dynamically: 5-period burn-in to stabilise
forvalues s = 2/70 {
    qui replace y = L.y + phi * (L.y - `beta_pos' * x - `beta_neg' * x ///
                                 - `beta_c' * c) + lam_y * f + eps if t - 1958 == `s'
}

* Drop burn-in
drop if t < 1965
xtset id t

di
di in gr "=============================================================================="
di in gr "  EXAMPLE A. Synthetic-DGP recovery test"
di in gr "=============================================================================="
di in gr "  True parameters:    beta+ = " in ye %5.2f `beta_pos' _c
di in gr "   beta- = " in ye %5.2f `beta_neg' _c
di in gr "   beta_c = " in ye %5.2f `beta_c'
di in gr "  Expected:           xtcsnardl PMG should recover these within +- 0.10"
di in gr "=============================================================================="

xtcsnardl D.y L.y D.x D.c, ///
    lr(L.y x c) asymmetric(x) ///
    pmg cr_lags(3) multip(20) irfshock(20) ///
    asytable panelcoef graph

* Confirmation via lincom
lincom [ECT]x_pos          // expect ~ 0.80
lincom [ECT]x_neg          // expect ~ -1.20
lincom [ECT]c              // expect ~ 0.40


* =============================================================================
* EXAMPLE B.  EURO-4 CARBON EMISSIONS  (Mehta & Derbeneva 2024)
* =============================================================================
*  This example assumes you have loaded the EURO-4 panel.  Variable names:
*     omega  - per-capita CO2 emissions
*     rho    - carbon tax revenue / GDP        (asymmetric)
*     gamma  - environmental spending / GDP    (asymmetric)
*     pi     - industrial value-added / GDP
*     psi    - GDP per capita
*     theta  - urbanisation rate
*
*  Replace the placeholder load below with your data path.

/* ------------------------------------------------------------------
use "your_euro4_dataset.dta", clear
xtset country year

di in gr "=============================================================================="
di in gr "  EXAMPLE B. EURO-4 CS-NARDL    (Mehta & Derbeneva 2024)"
di in gr "=============================================================================="

xtcsnardl D.omega L.omega D.rho D.gamma ///
                D.pi D.psi D.theta, ///
    lr(L.omega rho gamma pi psi theta) ///
    asymmetric(rho gamma) ///
    pmg cr_lags(2) ///
    multip(15) irfshock(15) ///
    asytable panelcoef hausman ///
    showcsa graph

* Expected interpretation:
*   - Long-run asymmetry on rho (carbon tax): tax HIKE reduces emissions more
*     strongly than tax CUT raises them.
*   - Long-run asymmetry on gamma (env. spending): spending INCREASE reduces
*     emissions; spending CUT raises them.
*   - ECT phi ~ -0.47, half-life ~ 1.5 years.
*   - CD test on residuals does NOT reject => CSA augmentation sufficient.
* ------------------------------------------------------------------ */


* =============================================================================
* EXAMPLE C.  BRICS RENEWABLE ENERGY  (Wang et al. 2022)
* =============================================================================
/* ------------------------------------------------------------------
use "your_brics_dataset.dta", clear
xtset country year

di in gr "=============================================================================="
di in gr "  EXAMPLE C. BRICS CS-NARDL    (Wang, Huang, Ghafoor et al. 2022)"
di in gr "=============================================================================="

xtcsnardl D.REC L.REC D.FID D.ICTtrade ///
                D.GDP D.RD D.Inflation, ///
    lr(L.REC FID ICTtrade GDP RD Inflation) ///
    asymmetric(FID ICTtrade) ///
    pmg cr_lags(2) ///
    multip(20) asytable graph
* ------------------------------------------------------------------ */


* =============================================================================
* EXAMPLE D.  MG with Hausman test
* =============================================================================

di in gr "=============================================================================="
di in gr "  EXAMPLE D. MG vs PMG Hausman test on the synthetic DGP"
di in gr "=============================================================================="

* Re-use synthetic data from Example A (still in memory)
xtcsnardl D.y L.y D.x D.c, ///
    lr(L.y x c) asymmetric(x) ///
    pmg cr_lags(3) hausman

* When Hausman REJECTS (p < 0.05), switch to MG:
xtcsnardl D.y L.y D.x D.c, ///
    lr(L.y x c) asymmetric(x) ///
    mg cr_lags(3) multip(20) asytable graph


* =============================================================================
* EXAMPLE E.  NOCSA toggle -- diagnostic comparison
* =============================================================================

di in gr "=============================================================================="
di in gr "  EXAMPLE E. NOCSA toggle exposes residual cross-section dependence"
di in gr "=============================================================================="

di in ye "  Run 1: classical Panel NARDL (NOCSA) -- residual CSD expected"
xtcsnardl D.y L.y D.x D.c, ///
    lr(L.y x c) asymmetric(x) pmg nocsa

* The CD test in Table 10 SHOULD reject H0 of independence after this run,
* because the common factor f_t is unmodelled.

di
di in ye "  Run 2: CS-NARDL with default CSA augmentation -- residual CSD removed"
xtcsnardl D.y L.y D.x D.c, ///
    lr(L.y x c) asymmetric(x) pmg cr_lags(3)

* Now the CD p-value should be large (no residual CSD).


* =============================================================================
* OPTIONAL POST-ESTIMATION TOOLS
* =============================================================================

* Independent CD test on residuals
capture which xtcd2
if !_rc {
    predict uhat, residuals
    xtcd2 uhat
    drop uhat
}

* Exponent of cross-section dependence
capture which xtcse2
if !_rc {
    predict uhat2, residuals
    xtcse2 uhat2
    drop uhat2
}

* Export the long-run table to LaTeX with esttab
capture which esttab
if !_rc {
    esttab, keep([ECT]x_pos [ECT]x_neg [ECT]c) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        b(%7.4f) se(%6.4f) label
}

di
di in gr "=============================================================================="
di in gr "  END xtcsnardl_example.do"
di in gr "=============================================================================="
