/*============================================================================
   xtpqcs - Demonstration do-file
   Panel Quantile Regression with Common Shocks (Chiang, Galvao & Wei 2026)
   Stata implementation: Dr. Merwan Roudane <merwanroudane920@gmail.com>
============================================================================*/

clear all
set more off
set seed 20260220

* ----------------------------------------------------------------------------
* 0. Make sure xtpqcs is on the adopath
* ----------------------------------------------------------------------------
*  If you've copied the package files to your PERSONAL ado directory, this
*  step is not needed. Otherwise, add the folder containing xtpqcs.ado:
*
*  adopath ++ "C:/path/to/xtpqcs"

* ----------------------------------------------------------------------------
* 1. Generate a panel from the paper's Section 5 DGP
*    Yit  = alpha_i + beta*Xit + (1 + gamma*Xit)*Uit
*    Uit  = (eps_it + eta_t)/sqrt(2)
*    Xit  = chi2(3) + 0.3*alpha_i,   alpha_i ~ U(0,1)
*    eta_t is the common shock that induces cross-sectional dependence.
* ----------------------------------------------------------------------------
local N = 500
local T = 30
local beta = 1
local gamma = 0.2

clear
set obs `N'
gen long id      = _n
gen double alpha = runiform()
expand `T'
bys id: gen int t = _n
gen double X     = rchi2(3) + 0.3*alpha
sort t
by t: gen double eta = rnormal() if _n==1
by t: replace eta    = eta[1]
gen double eps   = rnormal()
gen double U     = (eps + eta)/sqrt(2)
gen double y     = alpha + `beta'*X + (1 + `gamma'*X)*U

xtset id t

label variable X "X (regressor)"
label variable y "y (outcome)"

* ----------------------------------------------------------------------------
* 2. Estimate FEQR with the robust common-shock-aware SEs (paper default)
* ----------------------------------------------------------------------------
xtpqcs y X, id(id) time(t) quantile(0.50)

* ----------------------------------------------------------------------------
* 3. Compare with the classical Kato et al. (2012) sandwich SEs
* ----------------------------------------------------------------------------
xtpqcs y X, id(id) time(t) quantile(0.50) compare

di as txt _n "Note that the classical SEs are noticeably smaller than the"
di as txt    "robust SEs - this is exactly the size distortion documented in"
di as txt    "Petersen (2008) and analysed formally in the paper (Theorem 1)."

* ----------------------------------------------------------------------------
* 4. Estimate at several quantiles
* ----------------------------------------------------------------------------
foreach q in 0.10 0.25 0.50 0.75 0.90 {
    xtpqcs y X, id(id) time(t) quantile(`q') noheader
}

* ----------------------------------------------------------------------------
* 5. Beautiful quantile process plot with both confidence bands
* ----------------------------------------------------------------------------
xtpqcsplot y X, id(id) time(t) quantiles(0.05(0.05)0.95)

* ----------------------------------------------------------------------------
* 6. Monte Carlo replication of Section 5 (small reps for speed)
* ----------------------------------------------------------------------------
xtpqcsmc, n(250) tperiods(25) reps(200) quantile(0.50)
xtpqcsmc, n(500) tperiods(25) reps(200) quantile(0.25)
xtpqcsmc, n(500) tperiods(50) reps(200) quantile(0.75)

* ----------------------------------------------------------------------------
* 7. Inspect stored matrices
* ----------------------------------------------------------------------------
xtpqcs y X, id(id) time(t) quantile(0.50) noheader
matrix list e(V_robust)
matrix list e(V_classical)
matrix list e(Gamma_hat)
matrix list e(Sigma_hat)
matrix list e(Omega_hat)

di as res _n "End of demo."
