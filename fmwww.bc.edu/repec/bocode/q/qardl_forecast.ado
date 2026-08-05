*! qardl_forecast v1.2.0 - Dynamic out-of-sample forecasts after qardl
*! Translates forecastQARDL / _forecastQARDLLevels from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*!   qardl_forecast [, horizon(#) futurex(matname) gen(stub) notable]
*!
*! Forecasts are recursive: each step feeds its own prediction back in as
*! the lagged dependent variable.  Regressors are held at their last
*! observed value unless futurex() supplies a (horizon x k) path.

program define qardl_forecast, rclass
    version 14.0

    capture mata which _qardl_ic_design()
    if _rc {
        capture program drop _qardl_icmean
        qui findfile _qardl_icmean.ado
        qui run "`r(fn)'"
    }

    syntax [, HORizon(integer 1) FUTUREX(string) GEN(string) NOTABle]

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

    if `horizon' < 1 {
        di as error "horizon() must be a positive integer"
        exit 198
    }

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"

    tempname bt tau_vec fx
    mat `bt' = e(bt_raw)
    mat `tau_vec' = e(tau)

    * Future regressor path
    local havefx = 0
    if "`futurex'" != "" {
        capture confirm matrix `futurex'
        if _rc {
            di as error "matrix `futurex' not found"
            exit 198
        }
        mat `fx' = `futurex'
        if rowsof(`fx') != `horizon' | colsof(`fx') != `k' {
            di as error "futurex() must be `horizon' x `k'; it is " ///
                rowsof(`fx') " x " colsof(`fx')
            exit 198
        }
        local havefx = 1
    }
    else {
        mat `fx' = J(1, 1, 0)
    }

    * Estimation sample into Mata
    tempvar esample
    qui gen byte `esample' = e(sample)

    qui putmata _fc_y = `depvar' if `esample', replace
    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `esample'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _fc_X = (`mxvars') if `esample', replace

    mata: _qardl_forecast_run(_fc_y, _fc_X, `p', `q', "`bt'", `horizon', ///
        "`fx'", `havefx')

    tempname F
    mat `F' = _qardl_fc_out

    if "`notable'" == "" {
        di as txt _n "{hline 70}"
        di as res "  QARDL Dynamic Forecasts"
        di as txt "{hline 70}"
        di as txt "  Dependent variable : " as res "`depvar'"
        di as txt "  Horizon            : " as res `horizon'
        if `havefx' {
            di as txt "  Regressor path     : " as res "supplied in `futurex'"
        }
        else {
            di as txt "  Regressor path     : " as res "held at last observed values"
        }
        di as txt "{hline 70}"
        di as txt "  {ralign 8:Step}" _c
        forvalues t = 1/`ntau' {
            di as txt "  {ralign 14:tau = " %4.2f `tau_vec'[`t',1] "}" _c
        }
        di ""
        di as txt "  {hline 62}"
        forvalues h = 1/`horizon' {
            di as txt "  {ralign 8:`h'}" _c
            forvalues t = 1/`ntau' {
                di as res "  {ralign 14:" %12.4f `F'[`h', `t'] "}" _c
            }
            di ""
        }
        di as txt "  {hline 62}"
        if `havefx' == 0 & `q' > 0 {
            di as txt "  Note: with regressors held constant, all differenced"
            di as txt "  terms are zero after the first step, so the path"
            di as txt "  reflects only the autoregressive dynamics."
        }
        di as txt "{hline 70}"
    }

    * Optionally store as variables (appending observations)
    if "`gen'" != "" {
        qui count
        local n0 = r(N)
        qui set obs `= `n0' + `horizon''
        forvalues t = 1/`ntau' {
            local tv = `tau_vec'[`t', 1]
            local suffix : di %02.0f 100*`tv'
            local vn "`gen'`suffix'"
            capture confirm new variable `vn'
            if _rc {
                di as error "variable `vn' already exists"
                exit 110
            }
            qui gen double `vn' = .
            forvalues h = 1/`horizon' {
                qui replace `vn' = `F'[`h', `t'] in `= `n0' + `h''
            }
            label var `vn' "Forecast of `depvar' at tau = `: di %4.2f `tv''"
        }
        di as txt "  Created " as res `ntau' as txt " forecast variables with stub " ///
            as res "`gen'"
    }

    return matrix forecast = `F'
    return scalar horizon = `horizon'
end

capture mata: mata drop _qardl_forecast_run()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Recursive multi-step forecast.  Translates _forecastQARDLLevels().
//
// Each row of the design is [1, dx terms, x levels, y lags], matching
// the estimation design, and the predicted y is fed back as the lag for
// the next step.
// ------------------------------------------------------------------
void _qardl_forecast_run(real colvector yy, real matrix xx, real scalar ppp,
    real scalar qqq, string scalar bt_name, real scalar h,
    string scalar fx_name, real scalar havefx)
{
    real scalar nn, k0, ss, jj, kk, ll, ii, col_idx, row_idx, dx_count, yhat
    real colvector yall, y_lags
    real matrix bt, xfuture, xall, dxall, out, xrow, dx_terms

    nn = rows(yy)
    k0 = cols(xx)
    bt = st_matrix(bt_name)
    ss = cols(bt)
    dx_count = qqq * k0

    // Future regressor path: supplied, or the last observed row repeated
    if (havefx) xfuture = st_matrix(fx_name)
    else        xfuture = J(h, 1, 1) * xx[nn, .]

    xall = xx \ xfuture

    dxall = J(rows(xall), k0, 0)
    dxall[2..rows(xall), .] = xall[2..rows(xall), .] - xall[1..rows(xall)-1, .]

    out = J(h, ss, .)

    for (jj = 1; jj <= ss; jj++) {
        yall = yy \ J(h, 1, 0)

        for (ii = 1; ii <= h; ii++) {
            row_idx = nn + ii
            xrow = J(1, 1, 1)

            if (dx_count > 0) {
                dx_terms = J(1, dx_count, 0)
                col_idx = 1
                for (kk = 1; kk <= k0; kk++) {
                    for (ll = 0; ll <= qqq - 1; ll++) {
                        dx_terms[1, col_idx] = dxall[row_idx - ll, kk]
                        col_idx++
                    }
                }
                xrow = (xrow, dx_terms)
            }

            y_lags = J(1, ppp, 0)
            for (kk = 1; kk <= ppp; kk++) {
                y_lags[1, kk] = yall[row_idx - kk]
            }

            xrow = (xrow, xall[row_idx, .], y_lags)
            yhat = xrow * bt[., jj]

            out[ii, jj] = yhat
            yall[row_idx] = yhat
        }
    }

    st_matrix("_qardl_fc_out", out)
}

end
