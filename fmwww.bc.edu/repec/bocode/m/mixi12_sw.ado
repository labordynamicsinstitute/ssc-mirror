*! mixi12_sw 1.0.1  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Stock-Watson (1993) triangular estimator for cointegration regressions
*  containing both I(1) and I(2) regressors.  Augments the cointegrating
*  regression with leads and lags of differences of all regressors to
*  neutralise long-run endogeneity.  Mixed-Gaussian limit theory => standard
*  t/F inference applies asymptotically.

program define mixi12_sw, eclass
    version 14
    syntax varname(ts) [if] [in] [, I1(string) I2(string) ///
        LEAds(integer 2) LAGSdiff(integer 2) ///
        TREND(string) HAC BW(integer 0) LEVel(cilevel)]

    if "`i2'" == "" {
        di as err "mixi12_sw: at least one I(2) regressor must be supplied via i2()"
        exit 198
    }
    if "`trend'" == "" local trend "c"

    marksample touse, novarlist
    qui count if `touse'
    local p1 : word count `i1'
    local p2 : word count `i2'

    // generate leads/lags of differences for every regressor
    local difflist ""
    foreach v of varlist `i1' `i2' {
        tempvar d_`v'
        qui gen double `d_`v'' = D.`v' if `touse'
        local difflist `difflist' `d_`v''
        forvalues j = 1/`leads' {
            tempvar f`j'_`v'
            qui gen double `f`j'_`v'' = F`j'.D.`v' if `touse'
            local difflist `difflist' `f`j'_`v''
        }
        forvalues j = 1/`lagsdiff' {
            tempvar l`j'_`v'
            qui gen double `l`j'_`v'' = L`j'.D.`v' if `touse'
            local difflist `difflist' `l`j'_`v''
        }
    }

    // trend regressor if requested
    local detopt ""
    if "`trend'" == "ct" {
        tempvar tline
        qui gen double `tline' = _n if `touse'
        local detopt `tline'
    }

    // mark rows where every regressor is non-missing
    tempvar mark
    qui gen byte `mark' = `touse'
    foreach v of varlist `varlist' `i1' `i2' `difflist' `detopt' {
        qui replace `mark' = 0 if missing(`v')
    }
    qui count if `mark'
    local Nused = r(N)

    if "`hac'" != "" {
        if `bw' <= 0 local bw = floor(4*(`Nused'/100)^(2/9))
        qui newey `varlist' `i1' `i2' `difflist' `detopt' if `mark', lag(`bw')
    }
    else {
        qui regress `varlist' `i1' `i2' `difflist' `detopt' if `mark'
    }

    local hacinfo "OLS / mixed-Gaussian"
    if "`hac'" != "" local hacinfo "HAC (bw=`bw')"

    di
    di as text "{hline 78}"
    di as text "{bf:Triangular estimator for mixed I(1)/I(2) cointegration}"
    di as text "{hline 78}"
    di as text _col(2) "Dependent variable:" _col(28) "`varlist'"
    di as text _col(2) "I(1) regressors:"     _col(28) "`i1'"
    di as text _col(2) "I(2) regressors:"     _col(28) "`i2'"
    di as text _col(2) "Leads / lags of Δ:"    _col(28) "`leads' / `lagsdiff'"
    di as text _col(2) "Trend:"                _col(28) "`trend'"
    di as text _col(2) "Inference:"            _col(28) "`hacinfo'"
    di as text _col(2) "N effective:"          _col(28) "`Nused'"
    di as text "{hline 78}"
    di as text "Long-run coefficients (β):"
    di as text "{hline 78}"
    di as text _col(2) "Variable" _col(20) "Coef." _col(34) "Std. Err." ///
              _col(48) "t" _col(58) "P>|t|"
    di as text "{hline 78}"
    foreach v of varlist `i1' `i2' {
        local b  = _b[`v']
        local se = _se[`v']
        local t  = `b'/`se'
        local pv = 2*ttail(e(df_r), abs(`t'))
        di as result _col(2) "`v'" _col(20) %10.5f `b' _col(34) %10.5f `se' ///
            _col(48) %7.3f `t' _col(58) %7.3f `pv'
    }
    if "`trend'" == "ct" {
        local b  = _b[`tline']
        local se = _se[`tline']
        local t  = `b'/`se'
        local pv = 2*ttail(e(df_r), abs(`t'))
        di as result _col(2) "trend" _col(20) %10.5f `b' _col(34) %10.5f `se' ///
            _col(48) %7.3f `t' _col(58) %7.3f `pv'
    }
    di as text "{hline 78}"

    ereturn local cmd "mixi12_sw"
    ereturn local depvar "`varlist'"
    ereturn local i1 "`i1'"
    ereturn local i2 "`i2'"
end
