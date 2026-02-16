* Comprehensive test do-file for QARDL package
* Tests ALL features: estimation, BIC, ECM, Wald, rolling, simulation
* Dr Merwan Roudane

clear all
set more off
set trace off

* Force drop cached programs
capture program drop qardl
capture program drop _qardl_estimate
capture program drop _qardl_ecm
capture program drop _qardl_rolling
capture program drop _qardl_simulate
capture program drop _qardl_waldtest
capture program drop _qardl_icmean
capture program drop qardl_graph
capture program drop qardl_makedata
capture program drop _qardl_display_results
capture program drop _qardl_display_ecm_results
capture program drop _qardl_default_wald
capture program drop _qardl_default_ecm_wald
capture program drop _qardl_parse_waldtest

adopath ++ "c:\Users\HP\Documents\xtpmg\qardl stata"

* Generate example data
qardl_makedata, n(500) seed(12345)

* =============================================
* TEST 1: Basic QARDL(1,2) with 3 quantiles
* =============================================
di as txt _n "========================================="
di as txt "TEST 1: Basic QARDL(1,2) with Wald tests"
di as txt "========================================="
qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(2)

* =============================================
* TEST 2: BIC lag order selection
* =============================================
di as txt _n "========================================="
di as txt "TEST 2: BIC lag order selection"
di as txt "========================================="
qardl y x1 x2, tau(0.5) pmax(4) qmax(4) notable

* =============================================
* TEST 3: QARDL-ECM with Wald tests
* =============================================
di as txt _n "========================================="
di as txt "TEST 3: QARDL-ECM(2,1) with ECM Wald tests"
di as txt "========================================="
qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ecm

* =============================================
* TEST 4: Rolling QARDL
* =============================================
di as txt _n "========================================="
di as txt "TEST 4: Rolling QARDL (window=200)"
di as txt "========================================="

* Regenerate data with enough obs for rolling
qardl_makedata, n(500) seed(12345)
qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(1) rolling(200)

* =============================================
* TEST 5: Monte Carlo Simulation (small)
* =============================================
di as txt _n "========================================="
di as txt "TEST 5: Monte Carlo Simulation (10 reps)"
di as txt "========================================="
qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(1) simulate(10 200) notable

* =============================================
* TEST 6: Stored results check
* =============================================
di as txt _n "========================================="
di as txt "TEST 6: Stored results check"
di as txt "========================================="
qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(2) notable
ereturn list

di as txt _n "==========================================="
di as txt "ALL TESTS COMPLETED"
di as txt "==========================================="
