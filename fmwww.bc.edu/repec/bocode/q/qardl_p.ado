*! qardl_p v1.2.0 - predict after qardl
*! Translates predictQARDL from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*!   predict newvar [if] [in], {xb | residuals} tau(#)
*!   predict stub*  [if] [in], {xb | residuals}
*!
*! A QARDL fit has one conditional-quantile function per tau, so predict
*! either takes tau() to pick one, or a stub to generate all of them.

program define qardl_p
    version 14.0

    capture mata which _qardl_ic_design()
    if _rc {
        capture program drop _qardl_icmean
        qui findfile _qardl_icmean.ado
        qui run "`r(fn)'"
    }

    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        exit 301
    }

    * The scalar levels design is assumed below; a per-regressor lag
    * vector needs the generalised design and is not supported here.
    capture confirm matrix e(qvec)
    if _rc == 0 {
        di as error "not supported after qvec(); re-estimate with a scalar q()"
        exit 198
    }

    * Detect a stub request before syntax parsing consumes it
    gettoken first rest : 0
    local isstub = 0
    if strpos("`first'", "*") > 0 {
        local isstub = 1
        local stub = subinstr("`first'", "*", "", .)
        local 0 "`rest'"
        syntax [if] [in] [, XB RESiduals TAU(real 0)]
    }
    else {
        syntax newvarname [if] [in] [, XB RESiduals TAU(real 0)]
        local newvar "`varlist'"
    }

    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)

    if "`xb'" != "" & "`residuals'" != "" {
        di as error "specify only one of xb or residuals"
        exit 198
    }
    if "`xb'" == "" & "`residuals'" == "" local xb "xb"

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"

    tempname bt tau_vec
    mat `bt' = e(bt_raw)
    mat `tau_vec' = e(tau)

    * Which quantile column
    if `isstub' == 0 {
        if `tau' == 0 {
            di as error "specify tau() to choose a quantile, or use a stub such as {bf:predict fit*}"
            di as error "estimated quantiles: " _c
            forvalues i = 1/`ntau' {
                di as error %5.2f `tau_vec'[`i',1] " " _c
            }
            di ""
            exit 198
        }
        local col = 0
        forvalues i = 1/`ntau' {
            if abs(`tau_vec'[`i',1] - `tau') < 1e-8 local col = `i'
        }
        if `col' == 0 {
            di as error "tau(`tau') was not estimated"
            exit 198
        }
    }

    * Rebuild the levels design over the estimation sample
    tempvar esample
    qui gen byte `esample' = e(sample)

    qui putmata _pr_y = `depvar' if `esample', replace
    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `esample'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _pr_X = (`mxvars') if `esample', replace

    * Row numbers of the estimation sample, so results land on the right obs
    tempvar obsn
    qui gen long `obsn' = _n if `esample'

    mata: _qardl_predict_run(_pr_y, _pr_X, `p', `q', "`bt'", ///
        "`= cond("`residuals'" != "", "resid", "xb")'")

    tempname PM
    mat `PM' = _qardl_pr_out
    local nfit = rowsof(`PM')

    * The design drops the first max(p,q) observations
    qui count if `esample'
    local nsamp = r(N)
    local skip = `nsamp' - `nfit'

    qui sum `obsn' if `esample', meanonly
    local first_obs = r(min)

    if `isstub' {
        forvalues j = 1/`ntau' {
            local tv = `tau_vec'[`j', 1]
            local suffix : di %02.0f 100*`tv'
            local vn "`stub'`suffix'"
            capture confirm new variable `vn'
            if _rc {
                di as error "variable `vn' already exists"
                exit 110
            }
            qui gen double `vn' = .
            forvalues i = 1/`nfit' {
                local r = `first_obs' + `skip' + `i' - 1
                qui replace `vn' = `PM'[`i', `j'] in `r'
            }
            qui replace `vn' = . if !`touse'
            label var `vn' "`= cond("`residuals'" != "", "Residual", "Fitted")' at tau = `: di %4.2f `tv''"
        }
        di as txt "  Created " as res `ntau' as txt " variables: " _c
        forvalues j = 1/`ntau' {
            local tv = `tau_vec'[`j', 1]
            local suffix : di %02.0f 100*`tv'
            di as res "`stub'`suffix' " _c
        }
        di ""
    }
    else {
        qui gen double `newvar' = .
        forvalues i = 1/`nfit' {
            local r = `first_obs' + `skip' + `i' - 1
            qui replace `newvar' = `PM'[`i', `col'] in `r'
        }
        qui replace `newvar' = . if !`touse'
        label var `newvar' "`= cond("`residuals'" != "", "Residual", "Fitted")' at tau = `: di %4.2f `tau''"
    }
end

capture mata: mata drop _qardl_predict_run()

mata:
mata set matastrict off

// Fitted values or residuals of the levels-form QARDL, for every tau.
void _qardl_predict_run(real colvector yy, real matrix xx, real scalar ppp,
    real scalar qqq, string scalar bt_name, string scalar what)
{
    real colvector Y
    real matrix ONEX, bt, fitted

    ONEX = _qardl_ic_design(yy, xx, ppp, qqq, Y)
    bt = st_matrix(bt_name)
    fitted = ONEX * bt

    if (what == "resid") {
        st_matrix("_qardl_pr_out", Y * J(1, cols(bt), 1) - fitted)
    }
    else {
        st_matrix("_qardl_pr_out", fitted)
    }
}

end
