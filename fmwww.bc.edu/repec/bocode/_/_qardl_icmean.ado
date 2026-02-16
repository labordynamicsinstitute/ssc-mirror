*! _qardl_icmean v1.0.0 - BIC-based lag order selection for QARDL
*! Translates icmean.src (GAUSS) and pqorder.m (MATLAB)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_icmean, rclass
    version 14.0
    
    syntax varlist(min=2 numeric ts) [if] [in], PMAX(integer) QMAX(integer)
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    
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
    
    * Run BIC search in Mata
    mata: _qardl_bic_search(_ic_y, _ic_X, `pmax', `qmax')
    
    return scalar p_opt = _qardl_popt
    return scalar q_opt = _qardl_qopt
    return matrix bic_grid = _qardl_bic_grid
end

capture mata: mata drop _qardl_bic()
capture mata: mata drop _qardl_bic_search()

mata:
mata set matastrict off

// Compute BIC for a given (p,q) order
real scalar _qardl_bic(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq)
{
    real scalar nn, k0, jj, ii
    real matrix ee, eei, xxi, yyi, X_mat, ONEX
    real colvector Y_vec, bt, uu, rh
    real scalar bic_val
    
    nn = rows(yy)
    k0 = cols(xx)
    
    ee = xx[2..nn, .] - xx[1..nn-1, .]
    ee = J(1, k0, 0) \ ee
    
    eei = J(nn-qqq, qqq*k0, 0)
    xxi = xx[qqq+1..nn, .]
    yyi = J(nn-ppp, ppp, 0)
    
    for (jj = 1; jj <= k0; jj++) {
        for (ii = 0; ii <= qqq-1; ii++) {
            eei[., ii+1+(jj-1)*qqq] = ee[qqq+1-ii..nn-ii, jj]
        }
    }
    for (ii = 1; ii <= ppp; ii++) {
        yyi[., ii] = yy[1+ppp-ii..nn-ii]
    }
    
    if (ppp > qqq) {
        X_mat = (eei[rows(eei)+1-rows(yyi)..rows(eei), .],
                 xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .],
                 yyi)
    }
    else {
        X_mat = (eei,
                 xxi,
                 yyi[rows(yyi)+1-rows(xxi)..rows(yyi), .])
    }
    
    ONEX = (J(rows(X_mat), 1, 1), X_mat)
    Y_vec = yy[nn-rows(X_mat)+1..nn]
    
    // OLS regression
    bt = lusolve(cross(ONEX, ONEX), cross(ONEX, Y_vec))
    uu = Y_vec - ONEX * bt
    rh = uu :^ 2
    
    bic_val = rows(Y_vec) * ln(mean(rh)) + cols(ONEX) * ln(rows(Y_vec))
    
    return(bic_val)
}

// Search over grid of (p,q) values
void _qardl_bic_search(real colvector yy, real matrix xx,
    real scalar pmax, real scalar qmax)
{
    real matrix icb
    real scalar jj1, jj2, best_bic, best_p, best_q, bic_val
    
    icb = J(pmax, qmax, .)
    best_bic = .
    best_p = 1
    best_q = 1
    
    for (jj1 = 1; jj1 <= pmax; jj1++) {
        for (jj2 = 1; jj2 <= qmax; jj2++) {
            bic_val = _qardl_bic(yy, xx, jj1, jj2)
            icb[jj1, jj2] = bic_val
            
            if (best_bic == . | bic_val < best_bic) {
                best_bic = bic_val
                best_p = jj1
                best_q = jj2
            }
        }
    }
    
    st_numscalar("_qardl_popt", best_p)
    st_numscalar("_qardl_qopt", best_q)
    st_matrix("_qardl_bic_grid", icb)
}

end
