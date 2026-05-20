*! _mc_est_imols v1.0.1  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Integrated Modified OLS (Vogelsang-Wagner 2014) for multicointegration.

program define _mc_est_imols, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in], TRend(string) ///
        [NOConstant RESid(name)]
    marksample touse
    gettoken yv xv : varlist

    qui tsset, noquery
    qui sort `r(timevar)'

    tempvar tt
    qui gen long `tt' = sum(`touse') if `touse'

    * Partial sums
    tempvar SY
    qui gen double `SY' = sum(`yv') if `touse'

    local SXlist
    local i = 0
    foreach v of local xv {
        local ++i
        tempvar S_v`i'
        qui gen double `S_v`i'' = sum(`v') if `touse'
        local SXlist `SXlist' `S_v`i''
    }

    tempvar pt1 pt2 pt3
    qui gen double `pt1' = `tt'                              if `touse'
    qui gen double `pt2' = `tt'*(`tt'+1)/2                   if `touse'
    qui gen double `pt3' = `tt'*(`tt'+1)*(2*`tt'+1)/6        if `touse'

    local detlist
    if "`noconstant'" == "" local detlist `pt1'
    if "`trend'" == "ct"  | "`trend'" == "ctt"  local detlist `detlist' `pt2'
    if "`trend'" == "ctt"                       local detlist `detlist' `pt3'

    qui regress `SY' `SXlist' `detlist' if `touse', noconstant

    tempname b V
    mat `b' = e(b)
    mat `V' = e(V)
    return matrix b   = `b'
    return matrix V   = `V'
    return scalar rss = e(rss)
    return scalar r2  = e(r2)
    return scalar N   = e(N)

    if "`resid'" != "" {
        * Residual of the ORIGINAL regression at the IM-OLS coefficient.
        tempvar tt2
        qui gen double `tt2' = `tt'^2 if `touse'
        local detorig
        if "`trend'" == "ct"  local detorig `tt'
        if "`trend'" == "ctt" local detorig `tt' `tt2'
        qui regress `yv' `xv' `detorig' if `touse', `noconstant'
        qui predict double `resid' if e(sample), resid
    }
end
