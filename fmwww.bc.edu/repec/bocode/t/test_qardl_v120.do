*! test_qardl_v120.do - validation suite for qardl v1.2.0
*! Dr Merwan Roudane
*!
*! HOW TO RUN
*!   1. Put every .ado and .sthlp from this folder somewhere on the adopath,
*!      or just run this do-file from inside the folder: it adds the current
*!      directory to the adopath itself.
*!   2. do test_qardl_v120.do
*!   3. Paste the log back if anything fails.

clear all
set more off
version 14.0

* Make the local build visible to Stata
adopath ++ "`c(pwd)'"
capture program drop _all
discard
mata: mata clear          // start from a clean Mata workspace

di as res _n "{hline 70}"
di as res "  qardl v1.2.0 validation suite"
di as res "{hline 70}"

* ============================================================
* Test data: Cho-Kim-Shin style DGP with I(1) regressors
* ============================================================
set seed 12345
set obs 320
gen t = _n
tsset t

gen e1 = rnormal()
gen e2 = rnormal()
gen x1 = sum(e1)
gen x2 = sum(e2)
gen u  = rnormal()
gen y  = 0
replace y = 1 + 0.5*L.y + 0.2*L2.y + 0.4*x1 + 0.2*L.x1 ///
              + 0.3*x2 + 0.1*L.x2 + u if _n > 2
drop if _n <= 20          // burn-in
qui count
di as txt "Observations: " as res r(N)

local nfail = 0

* ============================================================
* TEST 1 - the exact quantile-regression solver
*          Frisch-Newton must match Stata's own qreg.
*          This is the single most important check: it is what
*          makes qardl reproduce GAUSS quantileFit / MATLAB linprog.
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 1: Frisch-Newton solver vs Stata qreg"
di as res "{hline 70}"

* Load the Mata solver
qui _qardl_estimate y x1 x2, p(2) q(1) tau(0.5)

gen dx1 = D.x1
gen dx2 = D.x2
gen Ly  = L.y
gen L2y = L2.y

qui putmata YY = y  if !missing(y, dx1, dx2, Ly, L2y), replace
qui putmata XX = (dx1, dx2, x1, x2, Ly, L2y) ///
    if !missing(y, dx1, dx2, Ly, L2y), replace
mata: XX = (J(rows(XX), 1, 1), XX)

local maxdiff = 0
foreach tt in 0.10 0.25 0.50 0.75 0.90 {
    qui qreg y dx1 dx2 x1 x2 L.y L2.y, quantile(`tt')
    matrix bq = e(b)'
    mata: b_st = st_matrix("bq")
    mata: b_st = b_st[7] \ b_st[1..6]          // move _cons to front
    mata: b_fn = _qardl_qreg(YY, XX, `tt')
    mata: st_local("d", strofreal(max(abs(b_fn - b_st))))
    di as txt "  tau = `tt'   max|Frisch-Newton - qreg| = " as res %12.3e `d'
    if `d' > `maxdiff' local maxdiff = `d'
}

if `maxdiff' < 1e-6 {
    di as res "  PASS  (max discrepancy " %9.2e `maxdiff' " < 1e-6)"
}
else {
    di as err "  FAIL  (max discrepancy " %9.2e `maxdiff' ")"
    local ++nfail
}

* ============================================================
* TEST 2 - baseline estimation runs and stores what it claims
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 2: baseline QARDL(2,1), iid covariance"
di as res "{hline 70}"

qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1)

di as txt _n "  e(covariance)  = " as res "`e(covariance)'"
di as txt "  e(scale_beta)  = " as res e(scale_beta)
di as txt "  e(scale_short) = " as res e(scale_short)
di as txt "  e(N_eff)       = " as res e(N_eff)

* scale_beta must be (n-1)^2 and scale_short (n-1) under iid with q>0
local want_sb = (e(N) - 1)^2
local want_ss = e(N) - 1
if abs(e(scale_beta) - `want_sb') < 1e-6 & abs(e(scale_short) - `want_ss') < 1e-6 {
    di as res "  PASS  Cho-Kim-Shin normalisation matches _qardlLevelsSE()"
}
else {
    di as err "  FAIL  expected scale_beta=`want_sb', scale_short=`want_ss'"
    local ++nfail
}

* long-run beta must be near the true values 0.4+0.2 = 0.6 and 0.3+0.1 = 0.4
* divided by (1 - 0.5 - 0.2) = 0.3  ->  2.0 and 1.3333
matrix bb = e(beta)
di as txt _n "  beta_x1(0.50) = " as res %8.4f bb[3,1] as txt "   (true 2.0000)"
di as txt "  beta_x2(0.50) = " as res %8.4f bb[4,1] as txt "   (true 1.3333)"

* ============================================================
* TEST 3 - robust and HAC covariance paths
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 3: covariance(robust) and covariance(hac)"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) covariance(robust) notable
di as txt "  robust : scale_beta = " as res e(scale_beta) ///
    as txt ", scale_short = " as res e(scale_short)
local ok_r = (e(scale_beta) == 1 & e(scale_short) == 1)

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) covariance(hac) notable
di as txt "  hac    : auto bandwidth = " as res e(haclags)
local n_eff = e(N_eff)
local want_L = trunc(4 * (`n_eff'/100)^(2/9))
if `want_L' < 1 local want_L = 1
local ok_h = (e(haclags) == `want_L')
di as txt "           expected trunc(4*(N/100)^(2/9)) = " as res `want_L'

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) covariance(hac) haclags(4) notable
local ok_h4 = (e(haclags) == 4)

if `ok_r' & `ok_h' & `ok_h4' {
    di as res "  PASS  sandwich paths behave as in GAUSS 3.1.1"
}
else {
    di as err "  FAIL  robust=`ok_r' hac_auto=`ok_h' hac_fixed=`ok_h4'"
    local ++nfail
}

* covariance() must reject nonsense, and haclags() must require hac
capture noisily qardl y x1 x2, tau(0.5) p(2) q(1) covariance(nonsense)
if _rc == 198 di as res "  PASS  covariance(nonsense) rejected"
else {
    di as err "  FAIL  bad covariance() not rejected"
    local ++nfail
}

capture qardl y x1 x2, tau(0.5) p(2) q(1) haclags(4)
if _rc == 198 di as res "  PASS  haclags() without covariance(hac) rejected"
else {
    di as err "  FAIL  haclags() outside hac not rejected"
    local ++nfail
}

* ============================================================
* TEST 4 - q = 0 support (new in 1.2.0, matches GAUSS)
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 4: q(0) support"
di as res "{hline 70}"

capture noisily qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(0) notable
if _rc == 0 {
    di as res "  PASS  q(0) estimates"
    di as txt "        e(q) = " as res e(q) as txt ", scale_beta = " as res e(scale_beta)
    if e(scale_beta) != 1 {
        di as err "  FAIL  q=0 must use the sandwich path (scale 1)"
        local ++nfail
    }
}
else {
    di as err "  FAIL  q(0) returned rc = " _rc
    local ++nfail
}

* ============================================================
* TEST 5 - lag selection criteria
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 5: criterion(aic|bic|hq|hqc)"
di as res "{hline 70}"

foreach c in aic bic hq hqc {
    qui qardl y x1 x2, tau(0.5) criterion(`c') pmax(4) qmax(3) notable
    di as txt "  `c' : p = " as res e(p) as txt ", q = " as res e(q) ///
        as txt ", e(criterion) = " as res "`e(criterion)'"
}
capture qardl y x1 x2, tau(0.5) criterion(sic) notable
if _rc == 198 di as res "  PASS  unknown criterion rejected"
else {
    di as err "  FAIL  unknown criterion not rejected"
    local ++nfail
}

* fixing p must leave only q free
qui qardl y x1 x2, tau(0.5) p(3) pmax(6) qmax(4) notable
if e(p) == 3 di as res "  PASS  fixed p respected during q search"
else {
    di as err "  FAIL  fixed p was overridden (e(p) = " e(p) ")"
    local ++nfail
}

* ============================================================
* TEST 6 - symmetry Wald test
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 6: symmetry Wald tests"
di as res "{hline 70}"

qardl y x1 x2, tau(0.1 0.25 0.5 0.75 0.9) p(2) q(1) symmetry notable

* a grid with no symmetric pair must report unavailable, not error
capture noisily qardl y x1 x2, tau(0.2 0.3 0.4) p(2) q(1) symmetry notable
if _rc == 0 di as res "  PASS  asymmetric grid handled gracefully"
else {
    di as err "  FAIL  asymmetric tau grid returned rc = " _rc
    local ++nfail
}

* ============================================================
* TEST 7 - waldtest() actually does something now
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 7: waldtest()"
di as res "{hline 70}"

qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) waldtest(beta gamma) notable

* custom restriction: beta_x1(0.25) = beta_x1(0.75), k=2, s=3 -> 6 columns
matrix R = (1,0,0,0,-1,0)
capture noisily qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ///
    waldtest(beta, r(R)) notable
if _rc == 0 di as res "  PASS  custom R accepted"
else {
    di as err "  FAIL  custom R returned rc = " _rc
    local ++nfail
}

* a wrongly sized R must be an error, not a silently trimmed answer
matrix Rbad = (1,0,-1)
capture qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) waldtest(beta, r(Rbad)) notable
if _rc != 0 di as res "  PASS  malformed R rejected (rc = " _rc ")"
else {
    di as err "  FAIL  malformed R silently accepted"
    local ++nfail
}

* postestimation
qui qardl y x1 x2, tau(0.1 0.25 0.5 0.75 0.9) p(2) q(1) notable
_qardl_waldtest, type(beta)
_qardl_waldtest, type(gamma) null(symmetry)

* ============================================================
* TEST 8 - both ECM parameterisations
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 8: ecmtype(cho|twostep|both)"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ecm notable
local ok_cho = (e(ecmtype) == "cho")

qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ecmtype(twostep)
local ok_two = (e(ecmtype) == "twostep")
di as txt _n "  e(rho_ols) = " as res e(rho_ols)
di as txt "  e(N_ecm)   = " as res e(N_ecm)

* rho(tau) should be negative for a stationary adjustment process
matrix rr = e(ecm_rho)
local allneg = 1
forvalues i = 1/3 {
    if rr[`i',1] >= 0 local allneg = 0
}
if `allneg' di as res "  PASS  rho(tau) < 0 at every quantile (convergent)"
else di as txt "  NOTE  rho(tau) >= 0 at some quantile - inspect the output"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ecmtype(both) notable
local ok_both = (e(ecmtype) == "both")

if `ok_cho' & `ok_two' & `ok_both' {
    di as res "  PASS  all three ECM modes run and tag e(ecmtype)"
}
else {
    di as err "  FAIL  cho=`ok_cho' twostep=`ok_two' both=`ok_both'"
    local ++nfail
}

* ecmtype(cho) needs q >= 1
capture qardl y x1 x2, tau(0.5) p(2) q(0) ecm notable
if _rc == 198 di as res "  PASS  ecmtype(cho) with q(0) rejected"
else {
    di as err "  FAIL  ecmtype(cho) with q(0) not rejected"
    local ++nfail
}

* ============================================================
* TEST 9 - rolling Wald statistics are no longer zeros
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 9: rolling window Wald statistics"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) rolling(120) notable

matrix W = e(rolling_wald_beta)
di as txt "  e(rolling_wald_beta) is " as res rowsof(W) " x " colsof(W)

mata: st_local("nz", strofreal(sum(st_matrix("W")[.,1] :!= 0 :& ///
                                  st_matrix("W")[.,1] :< .)))
di as txt "  nonzero, nonmissing Wald statistics: " as res `nz'

if `nz' > 0 & colsof(W) == 3 {
    di as res "  PASS  rolling Wald matrices are populated (3 columns)"
    di as txt "        window 1: W = " as res %10.3f W[1,1] ///
        as txt ", p = " as res %6.4f W[1,2] as txt ", df = " as res W[1,3]
}
else {
    di as err "  FAIL  rolling Wald still empty or wrong shape"
    local ++nfail
}

capture confirm matrix e(rolling_beta_se)
if _rc == 0 di as res "  PASS  rolling standard errors are stored"
else {
    di as err "  FAIL  e(rolling_beta_se) missing"
    local ++nfail
}

* ============================================================
* TEST 10 - companion commands still work
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 10: companion commands"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable
capture noisily qardl_analysis, nograph
if _rc == 0 di as res "  PASS  qardl_analysis"
else {
    di as err "  FAIL  qardl_analysis rc = " _rc
    local ++nfail
}

* analysis must also survive a sandwich-covariance fit
qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) covariance(hac) notable
capture noisily qardl_analysis, nograph
if _rc == 0 di as res "  PASS  qardl_analysis after covariance(hac)"
else {
    di as err "  FAIL  qardl_analysis after hac rc = " _rc
    local ++nfail
}

* ============================================================
di as res _n "{hline 70}"
if `nfail' == 0 {
    di as res "  ALL TESTS PASSED"
}
else {
    di as err "  `nfail' TEST(S) FAILED - see above"
}
di as res "{hline 70}"
