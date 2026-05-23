*! mixi12_haldrup 1.0.1  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Haldrup (1994 JoE) single-equation residual-based ADF I(2) cointegration
*  test.  This is a thin wrapper that delegates the regression and the
*  critical-value lookup to the user's {bf:dptest} package (sub-test
*  {bf:coint}) and presents the result inside the mixi12 visual style.
*
*  Syntax:
*     mixi12_haldrup depvar [if] [in] ,
*         I1(I1varlist) I2(I2varlist) [ DET(string) LEvel(integer 5)
*         MAXLag(integer -1) CRIT(string) ]

program define mixi12_haldrup, rclass
    version 14
    syntax varname(ts) [if] [in],          ///
        I2(varlist ts numeric)             ///
        [                                  ///
        I1(varlist ts numeric)             ///
        DET(string)                        ///
        LEvel(integer 5)                   ///
        MAXLag(integer -1)                 ///
        CRIT(string)                       ///
        ]

    if "`det'"  == "" local det  "const"
    if "`crit'" == "" local crit "bic"

    capture which dptest
    if _rc {
        di as err "mixi12_haldrup requires the {bf:dptest} package."
        di as err `"Run "ssc install dptest" (or place dptest.ado on the adopath)."'
        exit 199
    }

    marksample touse, novarlist
    local m1 : word count `i1'
    local m2 : word count `i2'
    if `m2' < 1 {
        di as err "mixi12_haldrup needs at least one I(2) regressor in i2()."
        exit 198
    }

    local optstr ""
    if `maxlag' >= 0 local optstr "`optstr' maxlag(`maxlag')"

    // delegate
    quietly dptest `varlist' `i1' `i2' if `touse', ///
        test(coint) i2vars(`i2') det(`det') level(`level') ///
        crit(`crit') `optstr' notable

    local tstat   = r(coint_adf)
    local reject  = r(coint_reject)
    local Tn      = r(N)
    local lags    = .

    // dptest only forwards r(coint_adf), r(coint_cv) and r(coint_reject)
    // from its sub-program, so fetch the full 1/5/10% CV row from our own
    // Mata table to populate the printed critical-value line.
    _mixi12_mata
    local cv1 .
    local cv5 .
    local cv10 .
    capture noisily mata: _mixi12_haldrup_cv_runner(`m1', `m2', `Tn')
    if _rc == 0 {
        if "`r(cv01)'" != "" local cv1  = r(cv01)
        if "`r(cv05)'" != "" local cv5  = r(cv05)
        if "`r(cv10)'" != "" local cv10 = r(cv10)
    }

    local verdict = cond(`reject', "Reject H0 — cointegration found at `level'% level", ///
                                    "Do not reject — no cointegration at `level'% level")

    di
    di as text "{hline 78}"
    di as text "{bf:Single-equation residual-based I(2) cointegration test}"
    di as text "{hline 78}"
    di as text _col(2) "Dependent variable:" _col(28) "`varlist'"
    di as text _col(2) "I(1) regressors  (m1 = `m1'):"  _col(34) "`i1'"
    di as text _col(2) "I(2) regressors  (m2 = `m2'):"  _col(34) "`i2'"
    di as text _col(2) "Deterministics:"  _col(28) "`det'"
    di as text _col(2) "Sample:"           _col(28) "`Tn' obs"
    di as text _col(2) "ADF lag length:"   _col(28) "`lags'"
    di as text "{hline 78}"
    di as text _col(2) "ADF t-statistic"   _col(34) %10.4f `tstat'
    di as text "{hline 78}"
    di as text _col(2) "Critical values"   _col(34) "  1%" ///
              _col(46) "  5%" _col(58) " 10%"
    di as result _col(34) %8.3f `cv1' _col(46) %8.3f `cv5' _col(58) %8.3f `cv10'
    di as text "{hline 78}"
    di as text _col(2) "Conclusion:" as result _col(20) "`verdict'"
    di as text "{hline 78}"

    return scalar t      = `tstat'
    return scalar cv01   = `cv1'
    return scalar cv05   = `cv5'
    return scalar cv10   = `cv10'
    return scalar lags   = `lags'
    return scalar N      = `Tn'
    return scalar m1     = `m1'
    return scalar m2     = `m2'
    return scalar reject = `reject'
    return local verdict "`verdict'"
    return local det     "`det'"
end
