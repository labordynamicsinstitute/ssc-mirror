*! _qardl_icmean v1.2.0 - Information-criterion lag order selection for QARDL
*! Translates icmean.src / pqSelect (GAUSS QARDL 3.1.1) and pqorder.m (MATLAB)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_icmean, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], PMAX(integer) QMAX(integer) ///
        [PMIN(integer 1) QMIN(integer 0) CRITerion(string) ///
         GETSPval(real 0.1)]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if "`criterion'" == "" local criterion "bic"
    local criterion = lower("`criterion'")
    if !inlist("`criterion'", "aic", "bic", "hq", "hqc", "gets") {
        di as error "criterion() must be aic, bic, hq, hqc, or gets"
        exit 198
    }
    if `getspval' <= 0 | `getspval' >= 1 {
        di as error "getspval() must be strictly between 0 and 1"
        exit 198
    }

    if `pmin' < 1 {
        di as error "pmin() must be at least 1"
        exit 198
    }
    if `qmin' < 0 {
        di as error "qmin() must be non-negative"
        exit 198
    }
    if `pmax' < `pmin' | `qmax' < `qmin' {
        di as error "maximum lag order below minimum lag order"
        exit 198
    }

    qui count if `touse'
    local nobs = r(N)

    * Put data into Mata
    qui putmata _ic_y = `depvar' if `touse', replace

    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _ic_X = (`mxvars') if `touse', replace

    * Run the search in Mata
    if "`criterion'" == "gets" {
        mata: _qardl_gets_search(_ic_y, _ic_X, `pmin', `pmax', `qmin', ///
            `qmax', `getspval')
    }
    else {
        mata: _qardl_ic_search(_ic_y, _ic_X, `pmin', `pmax', `qmin', `qmax', ///
            "`criterion'")
    }

    return scalar p_opt = _qardl_popt
    return scalar q_opt = _qardl_qopt
    * "return matrix name = matname" MOVES matname, so the first of these
    * two must copy or the second finds nothing.  bic_grid is the legacy
    * name kept for code written against qardl 1.1.0.
    return matrix ic_grid = _qardl_ic_grid, copy
    return matrix bic_grid = _qardl_ic_grid
    return scalar pmin = `pmin'
    return scalar qmin = `qmin'
    return scalar pmax = `pmax'
    return scalar qmax = `qmax'
    return local criterion "`criterion'"
end

capture mata: mata drop _qardl_bic()
capture mata: mata drop _qardl_bic_search()
capture mata: mata drop _qardl_ic_value()
capture mata: mata drop _qardl_ic_design()
capture mata: mata drop _qardl_ic_search()
capture mata: mata drop _qardl_gets_pvalue()
capture mata: mata drop _qardl_gets_search()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Build the levels-form QARDL(p,q) design, identical to the one used
// by _qardl_core_estimate().  Y is returned by reference.
// ------------------------------------------------------------------
real matrix _qardl_ic_design(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector Y)
{
    real scalar nn, k0, jj, ii
    real matrix ee, eei, xxi, yyi, X_mat

    nn = rows(yy)
    k0 = cols(xx)

    ee = xx[2..nn, .] - xx[1..nn-1, .]
    ee = J(1, k0, 0) \ ee

    if (qqq > 0) {
        eei = J(nn-qqq, qqq*k0, 0)
        xxi = xx[qqq+1..nn, .]
        for (jj = 1; jj <= k0; jj++) {
            for (ii = 0; ii <= qqq-1; ii++) {
                eei[., ii+1+(jj-1)*qqq] = ee[qqq+1-ii..nn-ii, jj]
            }
        }
    }
    else {
        xxi = xx
    }

    yyi = J(nn-ppp, ppp, 0)
    for (ii = 1; ii <= ppp; ii++) {
        yyi[., ii] = yy[1+ppp-ii..nn-ii]
    }

    if (qqq == 0) {
        X_mat = (xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .], yyi)
    }
    else if (ppp > qqq) {
        X_mat = (eei[rows(eei)+1-rows(yyi)..rows(eei), .],
                 xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .],
                 yyi)
    }
    else {
        X_mat = (eei,
                 xxi,
                 yyi[rows(yyi)+1-rows(xxi)..rows(yyi), .])
    }

    Y = yy[nn-rows(X_mat)+1..nn]

    return((J(rows(X_mat), 1, 1), X_mat))
}

// ------------------------------------------------------------------
// Information criterion for a given (p,q).  Translates icmean() plus
// _qardlInformationCriterion() from GAUSS 3.1.1:
//     aic      : n*ln(s2) + 2*np
//     hq / hqc : n*ln(s2) + 2*np*ln(ln(n))
//     bic      : n*ln(s2) + np*ln(n)
// ------------------------------------------------------------------
real scalar _qardl_ic_value(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, string scalar criterion)
{
    real scalar nobs, nparam, sigma2
    real colvector Y, bt, uu
    real matrix ONEX

    ONEX = _qardl_ic_design(yy, xx, ppp, qqq, Y)

    nobs   = rows(Y)
    nparam = cols(ONEX)

    if (nobs <= nparam) return(.)

    bt = lusolve(cross(ONEX, ONEX), cross(ONEX, Y))
    if (hasmissing(bt)) return(.)

    uu     = Y - ONEX * bt
    sigma2 = mean(uu :^ 2)

    if (sigma2 <= 0) return(.)

    if (criterion == "aic") {
        return(nobs * ln(sigma2) + 2 * nparam)
    }
    if (criterion == "hq" | criterion == "hqc") {
        return(nobs * ln(sigma2) + 2 * nparam * ln(ln(nobs)))
    }

    return(nobs * ln(sigma2) + nparam * ln(nobs))
}

// ------------------------------------------------------------------
// Grid search over p in [pmin,pmax] and q in [qmin,qmax].
// Row i of the grid is p = pmin+i-1; column j is q = qmin+j-1.
// ------------------------------------------------------------------
void _qardl_ic_search(real colvector yy, real matrix xx,
    real scalar pmin, real scalar pmax,
    real scalar qmin, real scalar qmax, string scalar criterion)
{
    real matrix icb
    real scalar jj1, jj2, best_ic, best_p, best_q, ic_val, nr, nc

    nr = pmax - pmin + 1
    nc = qmax - qmin + 1

    icb     = J(nr, nc, .)
    best_ic = .
    best_p  = pmin
    best_q  = max((qmin, 1))

    for (jj1 = pmin; jj1 <= pmax; jj1++) {
        for (jj2 = qmin; jj2 <= qmax; jj2++) {
            ic_val = _qardl_ic_value(yy, xx, jj1, jj2, criterion)
            icb[jj1 - pmin + 1, jj2 - qmin + 1] = ic_val

            if (ic_val < .) {
                if (best_ic == . | ic_val < best_ic) {
                    best_ic = ic_val
                    best_p  = jj1
                    best_q  = jj2
                }
            }
        }
    }

    st_numscalar("_qardl_popt", best_p)
    st_numscalar("_qardl_qopt", best_q)
    st_matrix("_qardl_ic_grid", icb)
}

// ------------------------------------------------------------------
// Significance of the highest lag currently in the model, from an OLS
// fit of the levels design.  Translates _qardlGETSBoundaryPValue() and
// _qardlGETSWaldPValue() from GAUSS QARDL 3.1.1.
//
// is_p_lag = 1 tests the last AR lag; is_p_lag = 0 jointly tests the
// last distributed-lag term of every regressor.
// ------------------------------------------------------------------
real scalar _qardl_gets_pvalue(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real scalar is_p_lag)
{
    real scalar k0, nobs, nparam, sigma2, df, wald, ii
    real scalar theta_start, phi_start
    real colvector Y, bt, resid, b, test_cols
    real matrix ONEX, XtX_inv, coef_cov, sub_cov

    k0 = cols(xx)

    ONEX = _qardl_ic_design(yy, xx, ppp, qqq, Y)
    nobs = rows(Y)
    nparam = cols(ONEX)
    if (nobs <= nparam + 1) return(1)

    theta_start = 2 + qqq * k0
    phi_start   = theta_start + k0

    if (is_p_lag) {
        test_cols = J(1, 1, phi_start + ppp - 1)
    }
    else {
        if (qqq < 1) return(1)
        test_cols = J(k0, 1, 0)
        for (ii = 1; ii <= k0; ii++) {
            test_cols[ii] = 2 + (ii - 1) * qqq + qqq - 1
        }
    }

    XtX_inv = luinv(cross(ONEX, ONEX))
    if (hasmissing(XtX_inv)) return(1)

    bt = XtX_inv * cross(ONEX, Y)
    resid = Y - ONEX * bt
    sigma2 = (resid' * resid) / (nobs - nparam)
    coef_cov = sigma2 * XtX_inv

    b = bt[test_cols]
    sub_cov = coef_cov[test_cols, test_cols]
    df = rows(test_cols)

    wald = b' * invsym(sub_cov) * b
    if (wald >= . | wald < 0) return(1)

    return(chi2tail(df, wald))
}

// ------------------------------------------------------------------
// Hierarchical general-to-specific lag selection.  Starts at the
// largest admissible (p,q) and repeatedly drops whichever boundary lag
// is least significant until both are significant at gets_pval.
// Translates _qardlGETSLagOrderSearch().
// ------------------------------------------------------------------
void _qardl_gets_search(real colvector yy, real matrix xx,
    real scalar pmin, real scalar pmax,
    real scalar qmin, real scalar qmax, real scalar gets_pval)
{
    real scalar pst, qst, p_pv, q_pv, guard
    real matrix grid

    pst = pmax
    qst = qmax
    guard = 0

    while (1) {
        guard++
        if (guard > (pmax - pmin) + (qmax - qmin) + 2) break

        p_pv = -1
        q_pv = -1

        if (pst > pmin) p_pv = _qardl_gets_pvalue(yy, xx, pst, qst, 1)
        if (qst > qmin) q_pv = _qardl_gets_pvalue(yy, xx, pst, qst, 0)

        if (p_pv <= gets_pval & q_pv <= gets_pval) break

        if (p_pv >= q_pv & p_pv > gets_pval) {
            pst = pst - 1
        }
        else if (q_pv > gets_pval) {
            qst = qst - 1
        }
        else {
            break
        }
    }

    // The grid is not defined for GETS; report the retained orders only.
    grid = J(1, 1, .)

    st_numscalar("_qardl_popt", pst)
    st_numscalar("_qardl_qopt", qst)
    st_matrix("_qardl_ic_grid", grid)
}

end
