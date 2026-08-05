*! test_qardl_suite.do - validation suite for the qardl v1.2.0 companion commands
*! Dr Merwan Roudane
*!
*! Run test_qardl_v120.do first (it covers the qardl command itself), then
*! this file, which covers qardl_qirf, qardl_boot, qardl_diag,
*! predict, qardl_forecast, qvec(), criterion(gets), qardl_export,
*! qardl_full and the rolling ECM.
*!
*!   do test_qardl_suite.do
*!
*! Paste the log back if anything fails.

clear all
set more off
version 14.0

adopath ++ "`c(pwd)'"
capture program drop _all
discard
mata: mata clear          // start from a clean Mata workspace

di as res _n "{hline 70}"
di as res "  qardl v1.2.0 companion-command validation suite"
di as res "{hline 70}"

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
drop if _n <= 20
qui count
di as txt "Observations: " as res r(N)

local nfail = 0

* ============================================================
* TEST 2 - QIRF
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 2: qardl_qirf"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable
qardl_qirf, horizon(40) shock(x1)

matrix IRF = r(irf)
matrix BB = e(beta)
local maxgap = 0
forvalues tt = 1/3 {
    local last = IRF[41, `tt']
    local bidx = (`tt' - 1) * 2 + 1
    local g = abs(`last' - BB[`bidx', 1])
    if `g' > `maxgap' local maxgap = `g'
}
di as txt _n "  max |QIRF(H=40) - beta(tau)| = " as res %12.6f `maxgap'
if `maxgap' < 0.01 {
    di as res "  PASS  permanent QIRF converges to the long-run coefficient"
}
else {
    di as err "  FAIL  QIRF did not converge to beta (gap `maxgap')"
    local ++nfail
}

qui qardl_qirf, horizon(40) shock(x1) temporary notable
matrix IRFT = r(irf)
local tail = abs(IRFT[41, 2])
di as txt "  |temporary QIRF at H=40| = " as res %12.6f `tail'
if `tail' < 0.01 {
    di as res "  PASS  temporary shock dies out"
}
else {
    di as err "  FAIL  temporary shock did not decay (`tail')"
    local ++nfail
}

capture qardl_qirf, horizon(10) shock(nosuchvar)
if _rc == 198 di as res "  PASS  unknown shock() variable rejected"
else {
    di as err "  FAIL  bad shock() not rejected"
    local ++nfail
}

qui qardl_qirf, horizon(12) shock(x1) bootstrap reps(60) seed(7) notable
capture confirm matrix r(irf_lb)
if _rc == 0 {
    matrix LB = r(irf_lb)
    matrix UB = r(irf_ub)
    matrix PT = r(irf)
    local contained = 1
    forvalues h = 2/13 {
        forvalues tt = 1/3 {
            if PT[`h',`tt'] < LB[`h',`tt'] - 1e-8 local contained = 0
            if PT[`h',`tt'] > UB[`h',`tt'] + 1e-8 local contained = 0
        }
    }
    if `contained' {
        di as res "  PASS  bootstrap bands bracket the point estimates"
    }
    else {
        di as err "  FAIL  point estimate outside the bootstrap band"
        local ++nfail
    }
}
else {
    di as err "  FAIL  bootstrap bands not returned"
    local ++nfail
}

* ============================================================
* TEST 3 - block bootstrap intervals
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 3: qardl_boot"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable

foreach m in moving circular stationary {
    capture qui qardl_boot, reps(60) method(`m') seed(11) notable
    if _rc {
        di as err "  FAIL  method(`m') returned rc = " _rc
        local ++nfail
    }
    else {
        matrix CIB = r(ci_beta)
        local ok = (rowsof(CIB) == 6 & colsof(CIB) == 2)
        forvalues i = 1/6 {
            if CIB[`i',1] > CIB[`i',2] local ok = 0
        }
        if `ok' {
            di as res "  PASS  method(`m'): 6 x 2 intervals, lower <= upper"
        }
        else {
            di as err "  FAIL  method(`m') produced a malformed interval"
            local ++nfail
        }
    }
}

* ============================================================
* TEST 4 - residual diagnostics
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 4: qardl_diag"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable
qardl_diag

matrix DG = r(diag)
local okdim = (rowsof(DG) == 24 & colsof(DG) == 5)
local okpv = 1
forvalues i = 1/24 {
    local pv = DG[`i', 5]
    if `pv' < . {
        if `pv' < 0 | `pv' > 1 local okpv = 0
    }
}
if `okdim' & `okpv' {
    di as res "  PASS  8 tests x 3 quantiles, all p-values in [0,1]"
}
else {
    di as err "  FAIL  dim ok = `okdim', p-values ok = `okpv'"
    local ++nfail
}

local nrej = 0
forvalues i = 1/24 {
    if DG[`i', 5] < 0.05 & DG[`i', 5] < . local ++nrej
}
di as txt "  Rejections at 5% out of 24 tests: " as res `nrej' ///
    as txt "   (a well-specified fit should reject few)"

* ============================================================
* TEST 5 - predict and forecast
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 5: predict and qardl_forecast"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable

capture drop fit*
capture drop res*
predict fit*, xb
predict res*, residuals

qui count if !missing(fit50)
di as txt "  Non-missing fitted values at tau = 0.50: " as res r(N)

qui gen double _chk = fit50 + res50 - y if !missing(fit50)
qui sum _chk
local maxdev = max(abs(r(min)), abs(r(max)))
di as txt "  max |fitted + residual - y| = " as res %12.3e `maxdev'
if `maxdev' < 1e-8 {
    di as res "  PASS  predict xb and residuals are consistent"
}
else {
    di as err "  FAIL  predict inconsistency `maxdev'"
    local ++nfail
}
qui drop _chk

capture predict onefit, xb
if _rc == 198 {
    di as res "  PASS  predict without tau() or a stub is rejected"
}
else {
    di as err "  FAIL  ambiguous predict accepted"
    local ++nfail
    capture drop onefit
}

capture drop onefit
predict onefit, xb tau(0.5)
qui corr onefit fit50
if abs(r(rho) - 1) < 1e-10 {
    di as res "  PASS  predict, tau(0.5) matches the stub column"
}
else {
    di as err "  FAIL  tau() column mismatch"
    local ++nfail
}

qardl_forecast, horizon(6)
matrix FC = r(forecast)
if rowsof(FC) == 6 & colsof(FC) == 3 {
    di as res "  PASS  forecast returns 6 x 3"
}
else {
    di as err "  FAIL  forecast dimensions " rowsof(FC) " x " colsof(FC)
    local ++nfail
}

matrix FX = J(6, 2, 0)
forvalues h = 1/6 {
    matrix FX[`h', 1] = 5
    matrix FX[`h', 2] = 3
}
capture qui qardl_forecast, horizon(6) futurex(FX) notable
if _rc == 0 di as res "  PASS  futurex() path accepted"
else {
    di as err "  FAIL  futurex() rc = " _rc
    local ++nfail
}

matrix FXbad = J(3, 2, 0)
capture qardl_forecast, horizon(6) futurex(FXbad) notable
if _rc == 198 di as res "  PASS  wrongly sized futurex() rejected"
else {
    di as err "  FAIL  bad futurex() accepted"
    local ++nfail
}

* ============================================================
* TEST 6 - per-regressor lag orders and GETS
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 6: qvec() and criterion(gets)"
di as res "{hline 70}"

capture noisily qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) qvec(2 1) notable
if _rc == 0 {
    di as res "  PASS  qvec(2 1) estimates"
    di as txt "        e(covariance) = " as res "`e(covariance)'"
    if "`e(covariance)'" == "iid" {
        di as err "  FAIL  qvec must not use the iid covariance"
        local ++nfail
    }
}
else {
    di as err "  FAIL  qvec() rc = " _rc
    local ++nfail
}

qui qardl y x1 x2, tau(0.5) p(2) qvec(1 1) covariance(robust) notable
matrix B1 = e(beta)
qui qardl y x1 x2, tau(0.5) p(2) q(1) covariance(robust) notable
matrix B2 = e(beta)
local d = max(abs(B1[1,1] - B2[1,1]), abs(B1[2,1] - B2[2,1]))
di as txt "  max |beta(qvec 1 1) - beta(q 1)| = " as res %12.3e `d'
if `d' < 1e-8 {
    di as res "  PASS  constant qvec reproduces the scalar path exactly"
}
else {
    di as err "  FAIL  constant qvec differs by `d'"
    local ++nfail
}

capture qardl y x1 x2, tau(0.5) p(2) qvec(1 1 1) notable
if _rc == 198 di as res "  PASS  wrong-length qvec rejected"
else {
    di as err "  FAIL  wrong-length qvec accepted"
    local ++nfail
}

capture qardl y x1 x2, tau(0.5) p(2) qvec(2 1) ecm notable
if _rc == 198 di as res "  PASS  qvec with ecm rejected"
else {
    di as err "  FAIL  qvec + ecm accepted"
    local ++nfail
}

qardl y x1 x2, tau(0.25 0.5 0.75) criterion(gets) pmax(5) qmax(4) notable
di as txt "  GETS retained: p = " as res e(p) as txt ", q = " as res e(q)
if e(p) >= 1 & e(q) >= 0 & e(p) <= 5 & e(q) <= 4 {
    di as res "  PASS  GETS returned orders inside the search range"
}
else {
    di as err "  FAIL  GETS returned p = " e(p) ", q = " e(q)
    local ++nfail
}

* ============================================================
* TEST 7 - export
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 7: qardl_export"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) notable

foreach f in csv latex markdown {
    if "`f'" == "csv"        local ext "csv"
    else if "`f'" == "latex" local ext "tex"
    else                     local ext "md"

    capture erase "_qardl_test.`ext'"
    capture qardl_export using "_qardl_test.`ext'", format(`f') ci replace
    if _rc {
        di as err "  FAIL  format(`f') rc = " _rc
        local ++nfail
    }
    else {
        capture confirm file "_qardl_test.`ext'"
        if _rc == 0 {
            di as res "  PASS  format(`f') wrote _qardl_test.`ext'"
        }
        else {
            di as err "  FAIL  format(`f') produced no file"
            local ++nfail
        }
    }
}

* ============================================================
* TEST 8 - integrated workflow
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 8: qardl_full"
di as res "{hline 70}"

capture noisily qardl_full y x1 x2, tau(0.25 0.5 0.75) pmax(4) qmax(3) ///
    nodiagnostics
if _rc == 0 {
    di as res "  PASS  qardl_full completed"
    di as txt "        selected p = " as res e(p) as txt ", q = " as res e(q)
    di as txt "        bounds F  = " as res %8.4f e(bounds_F)
    if e(bounds_F) < . {
        di as res "  PASS  bounds results carried into e()"
    }
    else {
        di as err "  FAIL  e(bounds_F) missing"
        local ++nfail
    }
}
else {
    di as err "  FAIL  qardl_full rc = " _rc
    local ++nfail
}

* ============================================================
* TEST 9 - rolling two-step ECM
* ============================================================
di as res _n "{hline 70}"
di as res "  TEST 9: rolling two-step ECM"
di as res "{hline 70}"

qui qardl y x1 x2, tau(0.25 0.5 0.75) p(2) q(1) ///
    ecmtype(twostep) rolling(150) notable

capture confirm matrix e(rolling_ecm_rho)
if _rc == 0 {
    matrix RR = e(rolling_ecm_rho)
    di as txt "  e(rolling_ecm_rho) is " as res rowsof(RR) " x " colsof(RR)
    mata: st_local("nz", strofreal(sum(st_matrix("RR") :< .)))
    di as txt "  non-missing rolling rho values: " as res `nz'
    if `nz' > 0 {
        di as res "  PASS  rolling ECM populated"
    }
    else {
        di as err "  FAIL  rolling ECM all missing"
        local ++nfail
    }
}
else {
    di as err "  FAIL  e(rolling_ecm_rho) not stored"
    local ++nfail
}

* ============================================================
di as res _n "{hline 70}"
if `nfail' == 0 {
    di as res "  ALL COMPANION TESTS PASSED"
}
else {
    di as err "  `nfail' COMPANION TEST(S) FAILED - see above"
}
di as res "{hline 70}"
