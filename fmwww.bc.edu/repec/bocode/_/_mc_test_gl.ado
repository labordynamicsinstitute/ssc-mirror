*! _mc_test_gl v1.1.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Granger & Lee (1989, 1990) two-step test for multicointegration.

program define _mc_test_gl, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in],          ///
        TRend(string)                                 ///
        [LAGS(integer 0)  AUTOlag(string)  MAXLag(integer 8)]
    marksample touse

    qui capture mata: __mc_loaded()
    if _rc qui _mc_mata

    gettoken yv xv : varlist
    local nx : word count `xv'

    if "`autolag'" == "" local autolag fixed
    local autolag = lower("`autolag'")

    qui tsset, noquery
    qui sort `r(timevar)'
    tempvar tt tt2
    qui gen long `tt' = sum(`touse') if `touse'
    qui gen double `tt2' = `tt'^2 if `touse'

    local detlist
    if "`trend'" == "ct"  local detlist `tt'
    if "`trend'" == "ctt" local detlist `tt' `tt2'

    qui regress `yv' `xv' `detlist' if `touse'
    tempvar Z
    qui predict double `Z' if `touse', resid

    tempvar S
    qui gen double `S' = sum(`Z') if `touse'

    qui regress `S' `xv' `detlist' if `touse'
    tempvar U
    qui predict double `U' if `touse', resid

    if "`autolag'" != "fixed" {
        _mc_pick_adf_lag `U' if `touse', maxlag(`maxlag') ic(`autolag')
        local plag = r(plag)
    }
    else local plag = `lags'

    tempvar dU LU
    qui gen double `dU' = `U' - `U'[_n-1] if `touse'
    qui gen double `LU' = `U'[_n-1] if `touse'
    local lagdiffs
    if `plag' > 0 {
        forvalues j=1/`plag' {
            tempvar dU_`j'
            qui gen double `dU_`j'' = `dU'[_n-`j'] if `touse'
            local lagdiffs `lagdiffs' `dU_`j''
        }
    }
    qui regress `dU' `LU' `lagdiffs' if `touse', noconstant
    local t_stat = _b[`LU']/_se[`LU']
    local Tuse   = e(N)

    tempname pv c05
    mata: _mc_gl_pval(`t_stat', "`trend'", `nx', `Tuse', "`pv'", "`c05'")

    return scalar stat = `t_stat'
    return scalar lags = `plag'
    return scalar pval = `pv'
    return scalar cv05 = `c05'
    return scalar T    = `Tuse'
end
