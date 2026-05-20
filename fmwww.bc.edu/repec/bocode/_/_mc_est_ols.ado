*! _mc_est_ols v1.0.1  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Internal helper: OLS estimation of the multicoint regression.

program define _mc_est_ols, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in], TRend(string) ///
        [NOConstant RESid(name)]
    marksample touse
    gettoken yv xv : varlist
    tempvar tt tt2
    qui gen long `tt' = sum(`touse') if `touse'
    qui gen double `tt2' = `tt'^2 if `touse'

    local detlist
    if "`trend'" == "ct"  local detlist `tt'
    if "`trend'" == "ctt" local detlist `tt' `tt2'

    qui regress `yv' `xv' `detlist' if `touse', `noconstant'

    tempname b V
    mat `b' = e(b)
    mat `V' = e(V)
    return matrix b   = `b'
    return matrix V   = `V'
    return scalar rss = e(rss)
    return scalar r2  = e(r2)
    return scalar N   = e(N)

    if "`resid'" != "" {
        qui predict double `resid' if e(sample), resid
    }
end
