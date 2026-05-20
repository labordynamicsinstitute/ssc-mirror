*! _mc_test_egh v1.1.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Engsted-Gonzalo-Haldrup (1997) one-step ADF test for multicointegration.

program define _mc_test_egh, rclass
    version 14.0
    syntax varname(numeric) [if] [in],          ///
        TRend(string)                           ///
        [LAGS(integer 0)  AUTOlag(string)  MAXLag(integer 8) ///
         M1(integer 1)    M2(integer 1)]
    marksample touse

    qui capture mata: __mc_loaded()
    if _rc qui _mc_mata

    if "`autolag'" == "" local autolag fixed
    local autolag = lower("`autolag'")

    qui count if `touse'
    local T = r(N)

    if "`autolag'" != "fixed" {
        _mc_pick_adf_lag `varlist' if `touse', maxlag(`maxlag') ic(`autolag')
        local plag = r(plag)
    }
    else local plag = `lags'

    qui tsset, noquery
    qui sort `r(timevar)'
    tempvar du Lu
    qui gen double `du' = `varlist' - `varlist'[_n-1] if `touse'
    qui gen double `Lu' = `varlist'[_n-1] if `touse'
    local lagdiffs
    if `plag' > 0 {
        forvalues j=1/`plag' {
            tempvar du_`j'
            qui gen double `du_`j'' = `du'[_n-`j'] if `touse'
            local lagdiffs `lagdiffs' `du_`j''
        }
    }

    qui regress `du' `Lu' `lagdiffs' if `touse', noconstant
    local t_stat = _b[`Lu']/_se[`Lu']
    local Tuse   = e(N)

    tempname cv01 cv025 cv05 cv10
    mata: _mc_egh_cv("`trend'", `m1', `m2', `Tuse', ///
                     "`cv01'", "`cv025'", "`cv05'", "`cv10'")

    return scalar stat  = `t_stat'
    return scalar lags  = `plag'
    return scalar cv01  = `cv01'
    return scalar cv025 = `cv025'
    return scalar cv05  = `cv05'
    return scalar cv10  = `cv10'
    return scalar T     = `Tuse'
end
