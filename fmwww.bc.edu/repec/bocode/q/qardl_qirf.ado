*! qardl_qirf v1.2.0 - Quantile impulse response functions for QARDL
*! Translates qirf, blockBootstrapQIRF and plotQIRF from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Postestimation after qardl:
*!   qardl_qirf [, horizon(#) shock(varname) temporary bootstrap reps(#)
*!                 blocklength(#) level(#) seed(#) method(name) graph ]
*!
*! The QIRF traces the response of y to a unit shock in one regressor,
*! from zero initial conditions and with the intercept suppressed, so it
*! measures the pure dynamic response.  For a permanent shock and a
*! stationary AR polynomial the response converges to beta(tau).

program define qardl_qirf, rclass
    version 14.0

    capture mata which _qardl_core_estimate()
    if _rc {
        capture program drop _qardl_estimate
        qui findfile _qardl_estimate.ado
        qui run "`r(fn)'"
    }
    capture mata which _qardl_block_index()
    if _rc {
        capture program drop qardl_boot
        qui findfile qardl_boot.ado
        qui run "`r(fn)'"
    }

    syntax [, HORizon(integer 20) SHOCK(string) TEMPorary ///
        BOOTstrap REPS(integer 999) BLocklength(integer 0) ///
        LEVel(cilevel) SEED(integer 0) METHod(string) GRAPH NOTABle]

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

    if "`method'" == "" local method "moving"
    local method = lower("`method'")
    if !inlist("`method'", "moving", "circular", "stationary") {
        di as error "method() must be moving, circular, or stationary"
        exit 198
    }

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"

    * Which regressor is shocked
    if "`shock'" == "" {
        local kx = 1
        local shockvar : word 1 of `indepvars'
    }
    else {
        local kx = 0
        local ii = 0
        foreach v of local indepvars {
            local ++ii
            if "`v'" == "`shock'" local kx = `ii'
        }
        if `kx' == 0 {
            * allow a numeric index too
            capture confirm integer number `shock'
            if _rc == 0 & `shock' >= 1 & `shock' <= `k' {
                local kx = `shock'
            }
            else {
                di as error "shock() must name one of: `indepvars'"
                exit 198
            }
        }
        local shockvar : word `kx' of `indepvars'
    }

    local perm = cond("`temporary'" != "", 0, 1)
    local shocklab = cond(`perm', "Permanent", "Temporary")

    tempname bt tau_vec irf
    mat `bt' = e(bt_raw)
    mat `tau_vec' = e(tau)

    * ---------------- Point estimates ----------------
    mata: _qardl_qirf_compute("`bt'", `p', `q', `k', `ntau', `horizon', ///
        `kx', `perm')
    mat `irf' = _qardl_qirf_mat

    * ---------------- Bootstrap bands ----------------
    tempname irf_lo irf_hi bdiag
    local haveband = 0

    if "`bootstrap'" != "" {
        local alpha = (100 - `level') / 100

        tempvar touse
        qui gen byte `touse' = e(sample)

        qui putmata _qi_y = `depvar' if `touse', replace
        local vi = 0
        local mxvars ""
        foreach v of local indepvars {
            local ++vi
            tempvar xv`vi'
            qui gen double `xv`vi'' = `v' if `touse'
            local mxvars `mxvars' `xv`vi''
        }
        qui putmata _qi_X = (`mxvars') if `touse', replace
        mata: _qi_tau = st_matrix("`tau_vec'")

        di as txt _n "  Bootstrapping QIRF bands: `reps' replications, `method' blocks ..."

        mata: _qardl_qirf_boot(_qi_y, _qi_X, `p', `q', _qi_tau, `horizon', ///
            `kx', `perm', `reps', `blocklength', `alpha', "`method'", `seed')

        mat `irf_lo' = _qardl_qirf_lo
        mat `irf_hi' = _qardl_qirf_hi
        mat `bdiag' = _qardl_qirf_diag
        local haveband = 1
    }

    * ---------------- Display ----------------
    if "`notable'" == "" {
        di as txt _n "{hline 70}"
        di as res "  Quantile Impulse Response Functions"
        di as txt "{hline 70}"
        di as txt "  Response of    : " as res "`depvar'"
        di as txt "  Shock to       : " as res "`shockvar'" as txt " (unit shock)"
        di as txt "  Shock type     : " as res "`shocklab'"
        di as txt "  Horizon        : " as res "0 to `horizon'"
        di as txt "  Model          : " as res "QARDL(`p',`q')"
        if `haveband' {
            di as txt "  Bands          : " as res "`level'% percentile bootstrap" ///
                as txt " (`method', " as res `bdiag'[1,2] as txt " reps)"
        }
        di as txt "{hline 70}"
        di as txt "  Note: initial conditions are zero and the intercept is"
        di as txt "  suppressed, so the QIRF is the pure dynamic response."
        di as txt "{hline 70}"

        _qardl_qirf_table `irf' `tau_vec' `horizon' `haveband' ///
            `= cond(`haveband', "`irf_lo'", "`irf'")' ///
            `= cond(`haveband', "`irf_hi'", "`irf'")'

        * long-run convergence check against beta(tau)
        if `perm' {
            di as txt _n "  {bf:Long-run convergence check}"
            di as txt "  For a permanent shock the QIRF converges to beta(tau)."
            di as txt "  {hline 56}"
            di as txt "  {ralign 10:Quantile}" _c
            di as txt "  {ralign 16:QIRF at H=`horizon'}" _c
            di as txt "  {ralign 14:beta(tau)}" _c
            di as txt "  {ralign 12:Gap}"
            di as txt "  {hline 56}"
            tempname bmat
            mat `bmat' = e(beta)
            forvalues t = 1/`ntau' {
                local tv = `tau_vec'[`t', 1]
                local last = `irf'[`= `horizon' + 1', `t']
                local bidx = (`t' - 1) * `k' + `kx'
                local bv = `bmat'[`bidx', 1]
                di as txt "  {ralign 10:" %5.2f `tv' "}" _c
                di as res "  {ralign 16:" %12.4f `last' "}" _c
                di as txt "  {ralign 14:" %12.4f `bv' "}" _c
                di as txt "  {ralign 12:" %10.4f `= `last' - `bv'' "}"
            }
            di as txt "  {hline 56}"
            di as txt "  A large gap means the horizon is too short or the AR"
            di as txt "  polynomial is close to a unit root at that quantile."
        }
        di as txt "{hline 70}"
    }

    * ---------------- Graph ----------------
    if "`graph'" != "" {
        _qardl_qirf_graph `irf' `tau_vec' `horizon' `haveband' ///
            `= cond(`haveband', "`irf_lo'", "`irf'")' ///
            `= cond(`haveband', "`irf_hi'", "`irf'")' ///
            "`depvar'" "`shockvar'" "`shocklab'" `level'
    }

    return matrix irf = `irf'
    if `haveband' {
        return matrix irf_lb = `irf_lo'
        return matrix irf_ub = `irf_hi'
        return matrix boot_diag = `bdiag'
    }
    return scalar horizon = `horizon'
    return scalar k_x = `kx'
    return scalar permanent = `perm'
    return local shockvar "`shockvar'"
end

* ============================================================
* QIRF table
* ============================================================
capture program drop _qardl_qirf_table
program define _qardl_qirf_table
    args irf tau_vec H haveband lo hi

    local ntau = rowsof(`tau_vec')

    di as txt _n "  {ralign 8:Horizon}" _c
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        if `haveband' {
            di as txt "  {ralign 30:tau = " %4.2f `tv' "}" _c
        }
        else {
            di as txt "  {ralign 12:tau = " %4.2f `tv' "}" _c
        }
    }
    di ""
    if `haveband' {
        di as txt "  {ralign 8: }" _c
        forvalues t = 1/`ntau' {
            di as txt "  {ralign 10:lower}{ralign 10:IRF}{ralign 10:upper}" _c
        }
        di ""
    }
    di as txt "  {hline 66}"

    forvalues h = 0/`H' {
        local r = `h' + 1
        di as txt "  {ralign 8:`h'}" _c
        forvalues t = 1/`ntau' {
            if `haveband' {
                di as txt "  {ralign 10:" %8.4f `lo'[`r', `t'] "}" _c
                di as res "{ralign 10:" %8.4f `irf'[`r', `t'] "}" _c
                di as txt "{ralign 10:" %8.4f `hi'[`r', `t'] "}" _c
            }
            else {
                di as res "  {ralign 12:" %10.4f `irf'[`r', `t'] "}" _c
            }
        }
        di ""
    }
    di as txt "  {hline 66}"
end

* ============================================================
* QIRF graph: one panel per quantile
* ============================================================
capture program drop _qardl_qirf_graph
program define _qardl_qirf_graph
    args irf tau_vec H haveband lo hi depvar shockvar shocklab level

    local ntau = rowsof(`tau_vec')

    preserve
    clear
    qui set obs `= `H' + 1'
    qui gen int horizon = _n - 1

    local plots ""
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        local tlab : di %4.2f `tv'

        qui gen double irf`t' = .
        qui gen double lo`t' = .
        qui gen double hi`t' = .
        forvalues h = 1/`= `H' + 1' {
            qui replace irf`t' = `irf'[`h', `t'] in `h'
            if `haveband' {
                qui replace lo`t' = `lo'[`h', `t'] in `h'
                qui replace hi`t' = `hi'[`h', `t'] in `h'
            }
        }

        if `haveband' {
            local g (rarea hi`t' lo`t' horizon, color("173 216 230%45") lwidth(none)) ///
                    (line irf`t' horizon, lcolor("0 51 102") lwidth(medthick)) ///
                    (function y = 0, range(0 `H') lcolor(gs8) lpattern(dash) lwidth(thin))
        }
        else {
            local g (line irf`t' horizon, lcolor("0 51 102") lwidth(medthick)) ///
                    (function y = 0, range(0 `H') lcolor(gs8) lpattern(dash) lwidth(thin))
        }

        twoway `g', ///
            title("{bf:tau = `tlab'}", size(medium) color("0 51 102")) ///
            xtitle("Horizon", size(small)) ///
            ytitle("Response", size(small)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            name(qardl_qirf`t', replace) nodraw

        local plots "`plots' qardl_qirf`t'"
    }

    graph combine `plots', ///
        title("{bf:`shocklab' QIRF: response of `depvar' to a unit shock in `shockvar'}", ///
            size(medsmall) color("0 51 102")) ///
        `= cond(`haveband', `"subtitle("`level'% bootstrap bands", size(vsmall))"', "")' ///
        graphregion(color(white)) ///
        name(qardl_qirf, replace)

    di as txt _n "  Graph created: " as res "qardl_qirf" ///
        as txt " (panels: " as res "`plots'" as txt ")"

    restore
end

* ============================================================
* Mata
* ============================================================
capture mata: mata drop _qardl_qirf_path()
capture mata: mata drop _qardl_qirf_compute()
capture mata: mata drop _qardl_qirf_boot()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// QIRF recursion.  Translates qirf() from GAUSS QARDL 3.1.1.
//
// bt row layout (1-based):
//   1                        intercept alpha(tau)
//   2 .. 1+q*k               Dx coefficients, variable-major, lag-minor
//   2+q*k .. 1+(q+1)*k       x-level coefficients theta
//   2+(q+1)*k .. +p          AR coefficients phi
//
// Row h+1 of the result is the response at horizon h; row 1 (h = 0) is
// the pre-shock baseline and is zero by construction.
// ------------------------------------------------------------------
real matrix _qardl_qirf_path(real matrix bt, real scalar ppp, real scalar qqq,
    real scalar k0, real scalar ss, real scalar H, real scalar k_x,
    real scalar permanent)
{
    real scalar jj, hh, ll, h_lag, theta_row, phi_start, phi_last
    real scalar gamma_first, gamma_last, theta, x_h, dx_lagged, y_h
    real colvector gamma_col, phi_vec, y_hist
    real matrix irf_mat

    theta_row   = 1 + qqq * k0 + k_x
    phi_start   = 2 + (qqq + 1) * k0
    phi_last    = phi_start + ppp - 1
    gamma_first = 2 + (k_x - 1) * qqq
    gamma_last  = 2 + k_x * qqq - 1

    irf_mat = J(H + 1, ss, 0)

    for (jj = 1; jj <= ss; jj++) {
        theta = bt[theta_row, jj]

        if (qqq > 0) gamma_col = bt[gamma_first..gamma_last, jj]
        else         gamma_col = J(1, 1, 0)

        phi_vec = bt[phi_start..phi_last, jj]
        y_hist  = J(ppp, 1, 0)

        for (hh = 1; hh <= H; hh++) {

            // Path of the shocked regressor.
            // Permanent: x jumps to 1 at h = 1 and stays; Dx = 1 only at h = 1.
            // Temporary: x is 1 only at h = 1; Dx = +1 at h = 1, -1 at h = 2.
            if (permanent) x_h = 1
            else           x_h = (hh == 1)

            y_h = theta * x_h

            for (ll = 0; ll <= qqq - 1; ll++) {
                h_lag = hh - ll
                if (h_lag >= 1) {
                    if (permanent) dx_lagged = (h_lag == 1)
                    else           dx_lagged = (h_lag == 1) - (h_lag == 2)
                }
                else {
                    dx_lagged = 0
                }
                y_h = y_h + gamma_col[ll + 1] * dx_lagged
            }

            y_h = y_h + colsum(phi_vec :* y_hist)

            irf_mat[hh + 1, jj] = y_h

            if (ppp > 1) y_hist = y_h \ y_hist[1..ppp-1]
            else         y_hist[1] = y_h
        }
    }

    return(irf_mat)
}

void _qardl_qirf_compute(string scalar bt_name, real scalar ppp,
    real scalar qqq, real scalar k0, real scalar ss, real scalar H,
    real scalar k_x, real scalar permanent)
{
    st_matrix("_qardl_qirf_mat",
        _qardl_qirf_path(st_matrix(bt_name), ppp, qqq, k0, ss, H, k_x, permanent))
}

// ------------------------------------------------------------------
// Block bootstrap percentile bands for the QIRF.
// Translates blockBootstrapQIRF().
// ------------------------------------------------------------------
void _qardl_qirf_boot(real colvector yy, real matrix xx, real scalar ppp,
    real scalar qqq, real colvector tau, real scalar H, real scalar k_x,
    real scalar permanent, real scalar B, real scalar blk_len,
    real scalar alpha, string scalar method, real scalar seed)
{
    real scalar T, k0, ss, done, failed, attempts, max_attempts, L, jj
    real scalar dim_irf, band_start, band_end
    real colvector idx, yb
    real matrix xb, boot_irf, ci, lo, hi

    T  = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)
    L  = _qardl_block_length(T, blk_len)
    dim_irf = (H + 1) * ss

    if (seed > 0) rseed(seed)

    boot_irf = J(B, dim_irf, .)

    done = 0
    failed = 0
    attempts = 0
    max_attempts = 5 * B

    while (done < B & attempts < max_attempts) {
        attempts++
        idx = _qardl_block_index(T, L, method)
        yb  = yy[idx]
        xb  = xx[idx, .]

        if (_qardl_design_ok(yb, xb, ppp, qqq)) {
            _qardl_core_estimate(yb, xb, ppp, qqq, tau, "iid", 0)
            done++
            boot_irf[done, .] = vec(_qardl_qirf_path(st_matrix("_qardl_bt_raw"),
                ppp, qqq, k0, ss, H, k_x, permanent))'
        }
        else {
            failed++
        }
    }

    if (done < 1) {
        errprintf("qardl_qirf: no valid bootstrap replication completed\n")
        exit(498)
    }

    if (done < B) boot_irf = boot_irf[1..done, .]

    ci = _qardl_pctile_ci(boot_irf, alpha)

    lo = J(H + 1, ss, 0)
    hi = J(H + 1, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        band_start = (jj - 1) * (H + 1) + 1
        band_end   = jj * (H + 1)
        lo[., jj] = ci[band_start..band_end, 1]
        hi[., jj] = ci[band_start..band_end, 2]
    }

    st_matrix("_qardl_qirf_lo", lo)
    st_matrix("_qardl_qirf_hi", hi)
    st_matrix("_qardl_qirf_diag", (B, done, failed, L, seed))
}

end
