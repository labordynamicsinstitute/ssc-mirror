*! _mc_resid_from_b v1.0.2  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Compute residual u_t = y - X*b - det*b_det  given a coefficient row vector.
*! Assumed column order of `bmat':
*!     [x_1 ... x_nx,  _trend (if ct/ctt),  _trend2 (if ctt),  _cons (if not nocons)]
*! This matches both reg's e(b) and cointreg's e(b).

program define _mc_resid_from_b
    version 14.0
    syntax varlist(min=2 numeric) [if] [in], BMAT(name) TRend(string)  ///
        RESid(name) [NOConstant]
    marksample touse
    gettoken yv xv : varlist

    qui tsset, noquery
    qui sort `r(timevar)'
    tempvar tt tt2 uhat
    qui gen long   `tt'  = sum(`touse') if `touse'
    qui gen double `tt2' = `tt'^2       if `touse'

    qui gen double `uhat' = `yv' if `touse'

    * 1) Subtract beta'X (positions 1..nx)
    local nx : word count `xv'
    local pos = 0
    foreach v of local xv {
        local ++pos
        local bi = el(`bmat', 1, `pos')
        if missing(`bi') continue
        qui replace `uhat' = `uhat' - `bi'*`v' if `touse'
    }

    * 2) Subtract linear trend coefficient (if present)
    if "`trend'" == "ct" | "`trend'" == "ctt" {
        local ++pos
        local b_t = el(`bmat',1,`pos')
        if !missing(`b_t') qui replace `uhat' = `uhat' - `b_t'*`tt' if `touse'
    }
    * 3) Subtract quadratic trend coefficient (if present)
    if "`trend'" == "ctt" {
        local ++pos
        local b_t2 = el(`bmat',1,`pos')
        if !missing(`b_t2') qui replace `uhat' = `uhat' - `b_t2'*`tt2' if `touse'
    }
    * 4) Subtract constant (if present)
    if "`noconstant'" == "" {
        local ++pos
        local b_c = el(`bmat',1,`pos')
        if !missing(`b_c') qui replace `uhat' = `uhat' - `b_c' if `touse'
    }

    qui gen double `resid' = `uhat' if `touse'
end
