*! _fqardl_waldtest v1.2.0 — Wald Tests for Parameter Constancy Across Quantiles
*! Tests H0: parameter(tau_i) = parameter(tau_j) for all i != j
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fqardl_waldtest
program define _fqardl_waldtest, rclass
    version 14.0

    syntax, BMAT(name) BVCOV(name) PMAT(name) PVCOV(name) ///
        GMAT(name) GVCOV(name) TVEC(name) ///
        PP(integer) QQ(integer) KK(integer) NNOBS(integer) ///
        INDEPVARS(string)

    local ntau = rowsof(`tvec')

    if `ntau' < 2 {
        exit
    }

    di as txt _n
    di as txt "{hline 78}"
    di as res _col(3) "Wald Tests for Parameter Constancy Across Quantiles"
    di as txt _col(3) "H0: parameter(tau_i) = parameter(tau_j) for all i,j"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 74}"
    di as txt _col(5) "{ralign 24:Test}" ///
       _col(33) "{ralign 12:Wald chi2}" ///
       _col(47) "{ralign 6:df}" ///
       _col(55) "{ralign 10:p-value}" ///
       _col(67) "{ralign 10:Decision}"
    di as txt "  {hline 74}"

    * Beta constancy test (LR)
    local beta_rows = rowsof(`bmat')
    local beta_cov_rows = rowsof(`bvcov')

    if `beta_rows' >= `ntau' * `kk' & `beta_cov_rows' >= `ntau' * `kk' {
        mata: _fqardl_wald_constancy("`bmat'", "`bvcov'", `kk', `ntau', `nnobs')
        local wstat = r(wald_stat)
        local df = r(wald_df)
        if `wstat' != . & `df' > 0 {
            local wpv = chi2tail(`df', max(0, `wstat'))
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                 local decision "Fail to reject"

            di as txt _col(5) "{ralign 24:Long-run (beta)}" _c
            di as res _col(33) "{ralign 12:" %10.4f `wstat' "}" _c
            di as txt _col(47) "{ralign 6:`df'}" _c
            if `wpv' < 0.05 {
                di as err _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as err _col(67) "{ralign 10:`decision'}"
            }
            else {
                di as txt _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as txt _col(67) "{ralign 10:`decision'}"
            }
            return scalar wald_beta = `wstat'
            return scalar wald_beta_pv = `wpv'
        }
    }

    * Phi constancy test (SR-AR)
    local phi_rows = rowsof(`pmat')
    local phi_cov_rows = rowsof(`pvcov')

    if `phi_rows' >= `ntau' * `pp' & `phi_cov_rows' >= `ntau' * `pp' {
        mata: _fqardl_wald_constancy("`pmat'", "`pvcov'", `pp', `ntau', `nnobs')
        local wstat = r(wald_stat)
        local df = r(wald_df)
        if `wstat' != . & `df' > 0 {
            local wpv = chi2tail(`df', max(0, `wstat'))
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                 local decision "Fail to reject"

            di as txt _col(5) "{ralign 24:Short-run AR (phi)}" _c
            di as res _col(33) "{ralign 12:" %10.4f `wstat' "}" _c
            di as txt _col(47) "{ralign 6:`df'}" _c
            if `wpv' < 0.05 {
                di as err _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as err _col(67) "{ralign 10:`decision'}"
            }
            else {
                di as txt _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as txt _col(67) "{ralign 10:`decision'}"
            }
            return scalar wald_phi = `wstat'
            return scalar wald_phi_pv = `wpv'
        }
    }

    * Gamma constancy test (SR-impact)
    local gam_rows = rowsof(`gmat')
    local gam_cov_rows = rowsof(`gvcov')

    if `gam_rows' >= `ntau' * `kk' & `gam_cov_rows' >= `ntau' * `kk' {
        mata: _fqardl_wald_constancy("`gmat'", "`gvcov'", `kk', `ntau', `nnobs')
        local wstat = r(wald_stat)
        local df = r(wald_df)
        if `wstat' != . & `df' > 0 {
            local wpv = chi2tail(`df', max(0, `wstat'))
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                 local decision "Fail to reject"

            di as txt _col(5) "{ralign 24:Short-run impact (gamma)}" _c
            di as res _col(33) "{ralign 12:" %10.4f `wstat' "}" _c
            di as txt _col(47) "{ralign 6:`df'}" _c
            if `wpv' < 0.05 {
                di as err _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as err _col(67) "{ralign 10:`decision'}"
            }
            else {
                di as txt _col(55) "{ralign 10:" %8.4f `wpv' "}" _c
                di as txt _col(67) "{ralign 10:`decision'}"
            }
            return scalar wald_gamma = `wstat'
            return scalar wald_gamma_pv = `wpv'
        }
    }

    di as txt "  {hline 74}"
    di as txt _col(5) "{it:*** p<0.01, ** p<0.05, * p<0.10}"
    di as txt ""
end

* ============================================================
* Mata: Wald constancy test
* ============================================================
capture mata: mata drop _fqardl_wald_constancy()

mata:
mata set matastrict off

void _fqardl_wald_constancy(string scalar bname, string scalar Vname,
    real scalar dim, real scalar ntau, real scalar nobs)
{
    real matrix b, V, R, Rb, RVR, Vinv_bb
    real scalar nrestr, i, j, row, w

    b = st_matrix(bname)
    V = st_matrix(Vname)

    // Trim to actual dimension needed
    real scalar expected_len
    expected_len = ntau * dim
    if (rows(b) > expected_len) b = b[1..expected_len, .]
    if (rows(V) > expected_len) V = V[1..expected_len, 1..expected_len]
    if (cols(V) > expected_len) V = V[., 1..expected_len]

    // Build restriction matrix: R * beta = 0 tests tau_i = tau_{i+1}
    nrestr = (ntau - 1) * dim
    R = J(nrestr, expected_len, 0)
    row = 0
    for (i = 1; i <= ntau - 1; i++) {
        for (j = 1; j <= dim; j++) {
            row++
            R[row, (i-1)*dim + j] = 1
            R[row, i*dim + j] = -1
        }
    }

    Rb = R * b
    RVR = R * V * R'

    // Scale the covariance by sample size (correction for asymptotic theory)
    // The stored covariance is the asymptotic variance; W = n * Rb' * inv(R*V*R') * Rb
    RVR = RVR * nobs

    // Regularize if near-singular
    if (abs(det(RVR)) < 1e-15) {
        RVR = RVR + 1e-8 * I(rows(RVR))
    }

    w = (Rb' * luinv(RVR) * Rb)[1,1]

    // Scale: W ~ chi2(nrestr) under H0
    w = w * nobs

    st_numscalar("r(wald_stat)", w)
    st_numscalar("r(wald_df)", nrestr)
}

end
