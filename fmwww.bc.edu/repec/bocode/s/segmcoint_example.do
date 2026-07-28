*! segmcoint_example.do  -- self-test / demonstration for the segmcoint suite
*! Dr Merwan Roudane  (merwanroudane920@gmail.com)
*
* Run with:   do segmcoint_example.do
* Simulates the papers' own Monte Carlo DGPs (known truth) and exercises every
* subcommand and option path.  Truth-vs-estimate is printed so results can be
* checked against Kim (2003), Davidson-Monticini (2010), Martins-Rodrigues (2021).

clear all
set more off

*==============================================================================
* 1. KIM (2003) -- weighted-LS segmented-cointegration tests
*    DGP eq (4.1): cointegration everywhere except N_T=(0.4T,0.6T]; rho=0.5.
*==============================================================================
set seed 90210
set obs 200
gen int t = _n
tsset t
gen double x2 = sum(rnormal(0,1))
gen double x3 = sum(rnormal(0,1))
gen double nu = rnormal(0, sqrt(0.1))
gen byte inN  = (t>80 & t<=120)
gen double rho_t = cond(inN, 1, 0.5)
gen double eps = nu in 1
forvalues i=2/200 {
    qui replace eps = rho_t[`i']*eps[`i'-1] + nu[`i'] in `i'
}
gen double x1 = x2 + x3 + eps

di _n as txt "{hline 78}"
di as txt "KIM (2003): true noncointegration interval N_T = (0.40, 0.60]"
di as txt "{hline 78}"
segmcoint kim x1 x2 x3, deterministic(const) trimbar(0.3) grid(2) graph
di as res "  --> inf-Zt* dating tau0=" r(tau0) " tau1=" r(tau1) " (truth .40-.60)"

* baseline full-sample residual test (typically FAILS to reject) for contrast
qui reg x1 x2 x3
predict double ehat, resid
dfuller ehat, lags(0)

*==============================================================================
* 2. DAVIDSON & MONTICINI (2010) -- subsample extremum tests
*==============================================================================
di _n as txt "{hline 78}"
di as txt "DAVIDSON-MONTICINI (2010): PP subsample tests, lambda0=0.35"
di as txt "{hline 78}"
segmcoint dm x1 x2, deterministic(const) lambda0(0.35) statistic(pp) graph
segmcoint dm x1 x2, deterministic(const) lambda0(0.5)  statistic(df)

*==============================================================================
* 3. MARTINS & RODRIGUES (2021) -- residual sup-Wald tests
*    DGP: cointegration in first 70%, unit-root error thereafter (one break ~0.7)
*==============================================================================
clear
set seed 7007
set obs 200
gen int t = _n
tsset t
gen double x = sum(rnormal(0,1))
gen double v1 = rnormal(0,1)
gen double phi = cond(t>140, 1, 0.4)
gen double z = v1 in 1
forvalues i=2/200 {
    qui replace z = phi[`i']*z[`i'-1] + v1[`i'] in `i'
}
gen double y = x + z

di _n as txt "{hline 78}"
di as txt "MARTINS-RODRIGUES (2021): true break at fraction ~0.70"
di as txt "{hline 78}"
segmcoint mr y x, deterministic(const) maxbreaks(4) trim(0.15) adflags(0) graph
di as res "  --> Wmax-selected m*=" r(mstar) " (expect a break near 0.70)"

* intercept + trend variant
segmcoint mr y x, deterministic(trend) maxbreaks(3)

di _n as txt "{hline 78}"
di as res "segmcoint self-test completed."
di as txt "{hline 78}"
