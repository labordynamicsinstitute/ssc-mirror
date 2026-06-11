*! _qnardl_multipliers v1.0.1  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Dynamic multipliers per quantile for QNARDL.
*!
*! For each tau and each asymmetric regressor j:
*!   m+_jh(tau) = cumulative response of y to a +1 shock in x+_j at horizon h
*!   m-_jh(tau) = cumulative response of y to a +1 shock in x-_j at horizon h
*!   asym_jh(tau) = m+_jh(tau) - m-_jh(tau)
*!
*! Asymptotes:  m+_jH -> beta+_j(tau), m-_jH -> beta-_j(tau)
*!
*! Algorithm: Forward-simulate the URECM with unit shock at t=0, baseline=0.

program define _qnardl_multipliers, rclass
    version 14.0

    syntax , [ depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
               linear_vars(string) exog(string) tau(numlist) ///
               p(integer 1) q(integer 1) r(integer 1) ///
               case(integer 3) trendvar(string) ///
               touse(varname) HORizon(integer 12) ]

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'
    local kexog : word count `exog'
    local ntau  : word count `tau'

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)

    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }

    // Build URECM regressor list
    local urecm "L.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L.`lv'"
        }
    }
    if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
        }
    }
    if "`exog'" != ""                       local urecm "`urecm' `exog'"
    if `has_trend' & "`trendvar'" != ""     local urecm "`urecm' `trendvar'"
    if `has_quad' & "`trendvar'" != ""      local urecm "`urecm' `t2var'"

    local consopt = cond(`has_const', "", "noconstant")
    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    // Coefficient indices into _b[]
    local idx_phi_y      = 1
    local idx_phi_pos    = 2
    local idx_phi_neg    = 2 + `kasym'
    local idx_phi_lin    = 2 + 2*`kasym'
    local idx_dyn_y      = 1 + 2*`kasym' + `klin' + 1
    local idx_dyn_pos    = `idx_dyn_y' + (`p' - 1)
    local idx_dyn_neg    = `idx_dyn_pos' + `kasym' * `q'

    // Storage matrices
    tempname mult_pos mult_neg
    local Hp1 = `horizon' + 1
    local ncols = `kasym' * `Hp1'
    matrix `mult_pos' = J(`ntau', `ncols', .)
    matrix `mult_neg' = J(`ntau', `ncols', .)

    // ---- Per-tau qreg + Mata simulation ------------------------------------
    local itau = 0
    foreach t of numlist `tau' {
        local ++itau
        capture noisily qui qreg `dydepvar' `urecm_temps' if `touse', ///
            quantile(`t') `consopt'
        if _rc continue

        // Pull the coefficient row vector e(b)
        tempname b_vec
        matrix `b_vec' = e(b)
        // b_vec is 1 × n_coefs

        // Per asym variable j: simulate positive and negative shocks
        forvalues j = 1/`kasym' {
            local pj_idx = `idx_phi_pos' + (`j' - 1)
            local nj_idx = `idx_phi_neg' + (`j' - 1)
            local phi_y_v  = `b_vec'[1, `idx_phi_y']
            local phi_pj_v = `b_vec'[1, `pj_idx']
            local phi_nj_v = `b_vec'[1, `nj_idx']

            // Build AR and DL coefficient vectors as Stata matrices for Mata
            tempname ar_mat dl_p_mat dl_n_mat mp_path mn_path
            if `p' > 1 {
                matrix `ar_mat' = J(`=`p'-1', 1, 0)
                forvalues kk = 1/`=`p'-1' {
                    matrix `ar_mat'[`kk', 1] = `b_vec'[1, `=`idx_dyn_y' + `kk' - 1']
                }
            }
            else {
                matrix `ar_mat' = J(1, 1, 0)
            }
            matrix `dl_p_mat' = J(`q', 1, 0)
            matrix `dl_n_mat' = J(`q', 1, 0)
            local pos_start_j = `idx_dyn_pos' + (`j' - 1) * `q'
            local neg_start_j = `idx_dyn_neg' + (`j' - 1) * `q'
            forvalues kk = 1/`q' {
                matrix `dl_p_mat'[`kk', 1] = `b_vec'[1, `=`pos_start_j' + `kk' - 1']
                matrix `dl_n_mat'[`kk', 1] = `b_vec'[1, `=`neg_start_j' + `kk' - 1']
            }

            // Positive shock (x+_j)
            mata: _qnardl_simulate_mult( ///
                `phi_y_v', `phi_pj_v',                          ///
                st_matrix("`ar_mat'"), st_matrix("`dl_p_mat'"), ///
                `horizon', `p'-1, `q', "`mp_path'")

            // Negative shock (x-_j) — also +1 magnitude shock to the partial sum
            mata: _qnardl_simulate_mult( ///
                `phi_y_v', `phi_nj_v',                          ///
                st_matrix("`ar_mat'"), st_matrix("`dl_n_mat'"), ///
                `horizon', `p'-1, `q', "`mn_path'")

            // Store path into result matrices
            forvalues h = 0/`horizon' {
                local col = (`j' - 1) * `Hp1' + `h' + 1
                matrix `mult_pos'[`itau', `col'] = `mp_path'[`=`h'+1', 1]
                matrix `mult_neg'[`itau', `col'] = `mn_path'[`=`h'+1', 1]
            }
        }
    }

    matrix rownames `mult_pos' = `tau'
    matrix rownames `mult_neg' = `tau'

    // ---- Display headline summary at median ---------------------------------
    di as txt _n "{hline 78}"
    di as res "[E] DYNAMIC MULTIPLIERS  (horizon = " `horizon' ")"
    di as txt _col(3) "Cumulative response of " as res "`depvar'" as txt ///
              " to a unit shock in x+_j (m+) and x-_j (m-)"
    di as txt _col(3) "Asymptote of m+_jH = beta+_j(tau);  asymptote of m-_jH = beta-_j(tau)"
    di as txt "{hline 78}"

    local pickrow = 1
    local mindist = .
    local taus    : rownames `mult_pos'
    forvalues i = 1/`ntau' {
        local tv : word `i' of `taus'
        local d = abs(`tv' - 0.5)
        if `d' < `mindist' {
            local mindist = `d'
            local pickrow = `i'
        }
    }
    local tau_show : word `pickrow' of `taus'

    di as txt _col(3) "Median quantile shown (tau = " `tau_show' ")"
    di as txt _col(3) "{hline 75}"
    di as txt _col(3) %-15s "Variable" _col(20) %10s "h=0" _col(32) %10s "h=4" ///
              _col(44) %10s "h=8" _col(56) %10s "h=`horizon'" _col(68) %10s "asym(H)"
    di as txt _col(3) "{hline 75}"

    forvalues j = 1/`kasym' {
        local vn : word `j' of `pos_vars'
        local vn : subinstr local vn "_qnardl_" "", all
        local vn : subinstr local vn "_pos" "", all

        local c_h0 = (`j' - 1) * `Hp1' + 1
        local c_h4 = (`j' - 1) * `Hp1' + min(5, `Hp1')
        local c_h8 = (`j' - 1) * `Hp1' + min(9, `Hp1')
        local c_hH = (`j' - 1) * `Hp1' + `Hp1'

        local mp_h0 = `mult_pos'[`pickrow', `c_h0']
        local mp_h4 = `mult_pos'[`pickrow', `c_h4']
        local mp_h8 = `mult_pos'[`pickrow', `c_h8']
        local mp_hH = `mult_pos'[`pickrow', `c_hH']

        local mn_hH = `mult_neg'[`pickrow', `c_hH']
        local asym_H = `mp_hH' - `mn_hH'

        di as txt _col(3) %-15s "`vn' (m+)" ///
                  as res _col(20) %10.4f `mp_h0' ///
                  _col(32) %10.4f `mp_h4' ///
                  _col(44) %10.4f `mp_h8' ///
                  _col(56) %10.4f `mp_hH' ///
                  _col(68) %10.4f `asym_H'
        local mn_h0 = `mult_neg'[`pickrow', `c_h0']
        local mn_h4 = `mult_neg'[`pickrow', `c_h4']
        local mn_h8 = `mult_neg'[`pickrow', `c_h8']
        di as txt _col(3) %-15s "`vn' (m-)" ///
                  as res _col(20) %10.4f `mn_h0' ///
                  _col(32) %10.4f `mn_h4' ///
                  _col(44) %10.4f `mn_h8' ///
                  _col(56) %10.4f `mn_hH'
    }
    di as txt _col(3) "{hline 75}"
    di as txt _col(3) "Plot the full multiplier paths:  " ///
              "{stata qnardl_mgraph:qnardl_mgraph}"

    return matrix mult_pos = `mult_pos'
    return matrix mult_neg = `mult_neg'
    return scalar horizon = `horizon'
    return scalar kasym = `kasym'
end

// =============================================================================
// MATA: forward-simulate the URECM with a unit shock
// =============================================================================
capture mata: mata drop _qnardl_simulate_mult()
mata:
mata set matastrict off

void _qnardl_simulate_mult(
    real scalar phi_y,
    real scalar phi_j,
    real matrix ar_mat,         /* (p-1) x 1, may be padded zero if p=1 */
    real matrix dl_mat,         /*  q    x 1 */
    real scalar H,              /* horizon */
    real scalar p_minus_1,
    real scalar q,
    string scalar outname)      /* name of OUTPUT Stata matrix */
{
    real scalar t, h, x_lev, y_lev, dy, ar_sum, dl_sum, y_lag, x_lag
    real colvector dy_lags, dx_lags, y_path, ar_v, dl_v

    ar_v = ar_mat[, 1]
    dl_v = dl_mat[, 1]

    dy_lags = J(max((p_minus_1, 1)), 1, 0)
    dx_lags = J(q, 1, 0)
    x_lev   = 0
    y_lev   = 0
    y_path  = J(H+1, 1, 0)

    for (h = 0; h <= H; h++) {
        if (h == 0)  dx_lags[1] = 1
        else         dx_lags[1] = 0
        x_lev = x_lev + dx_lags[1]

        y_lag = y_lev
        x_lag = x_lev - dx_lags[1]

        ar_sum = 0
        if (p_minus_1 > 0) {
            for (t = 1; t <= p_minus_1; t++) {
                ar_sum = ar_sum + ar_v[t] * dy_lags[t]
            }
        }
        dl_sum = 0
        for (t = 1; t <= q; t++) {
            dl_sum = dl_sum + dl_v[t] * dx_lags[t]
        }

        dy = phi_y * y_lag + phi_j * x_lag + ar_sum + dl_sum
        y_lev = y_lev + dy
        y_path[h+1] = y_lev

        if (p_minus_1 > 0) {
            for (t = p_minus_1; t >= 2; t--) {
                dy_lags[t] = dy_lags[t-1]
            }
            dy_lags[1] = dy
        }
        if (q > 1) {
            for (t = q; t >= 2; t--) {
                dx_lags[t] = dx_lags[t-1]
            }
        }
    }

    st_matrix(outname, y_path)
}

end
