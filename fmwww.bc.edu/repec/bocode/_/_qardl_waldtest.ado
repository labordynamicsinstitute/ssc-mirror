*! _qardl_waldtest v1.2.0 - Wald tests for QARDL parameters
*! Translates wtestlrb, wtestsrp, wtestsrg, wtestconst, wtestsym (GAUSS 3.1.1)
*! and wtestphi, wtesttheta (MATLAB qardl-ecm)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Postestimation:  qardl ... ;  _qardl_waldtest, type(beta)
*!
*!   type(beta|phi|gamma|phi_ecm|theta)   parameter block to test
*!   null(constancy|symmetry)             built-in restriction set
*!   r(matname) rr(matname)               custom R and r for H0: R*b = r

program define _qardl_waldtest, rclass
    version 14.0

    syntax, TYpe(string) [TAU(numlist >0 <1 sort) ///
        NULL(string) R(string) RR(string)]

    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        exit 301
    }

    local type = lower("`type'")
    if !inlist("`type'", "beta", "phi", "gamma", "phi_ecm", "theta") {
        di as error "invalid test type: `type'"
        di as error "valid types: beta, phi, gamma, phi_ecm, theta"
        exit 198
    }

    if "`null'" == "" local null "constancy"
    local null = lower("`null'")
    if !inlist("`null'", "constancy", "symmetry") {
        di as error "null() must be constancy or symmetry"
        exit 198
    }

    local nobs = e(N)
    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)

    * ------------------------------------------------------------
    * Select parameter block, its covariance, dimension and scaling
    * ------------------------------------------------------------
    tempname param cov
    if "`type'" == "beta" {
        mat `param' = e(beta)
        mat `cov' = e(beta_cov)
        local dim = `k'
        local scale = e(scale_beta)
        local label "Long-Run Parameter beta"
    }
    else if "`type'" == "phi" {
        mat `param' = e(phi)
        mat `cov' = e(phi_cov)
        local dim = `p'
        local scale = e(scale_short)
        local label "Short-Run Parameter phi"
    }
    else if "`type'" == "gamma" {
        mat `param' = e(gamma)
        mat `cov' = e(gamma_cov)
        local dim = `k'
        local scale = e(scale_short)
        local label "Short-Run Parameter gamma"
    }
    else if "`type'" == "phi_ecm" {
        if "`e(model)'" != "qardl-ecm" | !inlist("`e(ecmtype)'", "cho", "both") {
            di as error "phi* results not available; use ecm with ecmtype(cho) or ecmtype(both)"
            exit 198
        }
        mat `param' = e(phi_ecm)
        mat `cov' = e(phi_ecm_cov)
        local dim = max(`p' - 1, 1)
        local scale = `nobs' - 1
        local label "ECM Parameter phi*"
    }
    else {
        if "`e(model)'" != "qardl-ecm" | !inlist("`e(ecmtype)'", "cho", "both") {
            di as error "theta results not available; use ecm with ecmtype(cho) or ecmtype(both)"
            exit 198
        }
        mat `param' = e(theta)
        mat `cov' = e(theta_cov)
        local dim = `q' * `k'
        local scale = `nobs' - 2
        local label "ECM Parameter theta"
    }

    * ------------------------------------------------------------
    * Build the restriction matrices
    * ------------------------------------------------------------
    tempname Rmat rvec W
    if "`r'" != "" {
        capture confirm matrix `r'
        if _rc {
            di as error "matrix `r' not found"
            exit 198
        }
        mat `Rmat' = `r'
        if "`rr'" != "" {
            capture confirm matrix `rr'
            if _rc {
                di as error "matrix `rr' not found"
                exit 198
            }
            mat `rvec' = `rr'
        }
        else {
            mat `rvec' = J(rowsof(`Rmat'), 1, 0)
        }
        local nulltext "R*b = r (user supplied)"
    }
    else if "`null'" == "symmetry" {
        tempname tau_vec
        mat `tau_vec' = e(tau)
        mata: _qardl_build_symmetry_R(`dim', "`tau_vec'", "`Rmat'", "`rvec'")
        if rowsof(`Rmat') == 0 {
            di as error "no symmetric quantile pairs (tau_i + tau_j = 1) in e(tau)"
            exit 198
        }
        local nulltext "b(tau) = b(1-tau)"
    }
    else {
        mata: _qardl_build_constancy_R(`dim', `ntau', "`Rmat'", "`rvec'")
        local nulltext "b(tau_i) = b(tau_{i+1}) for all i"
    }

    * ------------------------------------------------------------
    * Wald statistic
    * ------------------------------------------------------------
    mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", "`rvec'", ///
        `scale', "`W'")

    local wstat = `W'[1,1]
    local df = `W'[2,1]

    if `df' < 1 | `wstat' >= . {
        di as error "Wald statistic could not be computed (rank-deficient restriction covariance)"
        exit 498
    }

    local pval = chi2tail(`df', `wstat')

    di as txt _n
    di as txt "{hline 56}"
    di as res "  Wald Test: `label'"
    di as txt "  H0: `nulltext'"
    di as txt "{hline 56}"
    di as txt "  W         = " as res %12.4f `wstat'
    di as txt "  df        = " as res `df'
    di as txt "  p-value   = " _c
    if `pval' < 0.05 {
        di as res %12.4f `pval'
    }
    else {
        di as res %12.4f `pval'
    }
    di as txt "{hline 56}"

    return scalar wald = `wstat'
    return scalar df = `df'
    return scalar pval = `pval'
    return local type "`type'"
    return local null "`null'"
    return matrix R = `Rmat'
    return matrix r = `rvec'
end

* ============================================================
* Mata functions for Wald tests
* ============================================================
capture mata: mata drop _qardl_build_constancy_R()
capture mata: mata drop _qardl_build_symmetry_R()
capture mata: mata drop _qardl_count_sym_pairs()
capture mata: mata drop _qardl_wald_stat()
capture mata: mata drop _qardl_pairwise_R()

mata:
mata set matastrict off

// Restriction matrix for H0: theta(tau_j) = theta(tau_{j+1}), j = 1..s-1.
// Mirrors the R construction inside wtestconst() in GAUSS QARDL 3.1.1.
void _qardl_build_constancy_R(real scalar dim, real scalar ntau,
    string scalar Rname, string scalar rname)
{
    real scalar nrestr, i, j, row
    real matrix R, r

    nrestr = (ntau - 1) * dim
    R = J(nrestr, ntau * dim, 0)
    r = J(nrestr, 1, 0)

    row = 1
    for (i = 1; i <= ntau - 1; i++) {
        for (j = 1; j <= dim; j++) {
            R[row, (i-1)*dim + j] =  1
            R[row,  i   *dim + j] = -1
            row++
        }
    }

    st_matrix(Rname, R)
    st_matrix(rname, r)
}

// Number of symmetric quantile pairs (tau_i + tau_j = 1, i < j).
real scalar _qardl_count_sym_pairs(string scalar tau_name)
{
    real scalar ss, jj, mm, n_pairs, tol
    real colvector tau

    tau = st_matrix(tau_name)
    ss  = rows(tau)
    tol = 1e-10
    n_pairs = 0

    for (jj = 1; jj <= ss; jj++) {
        for (mm = jj + 1; mm <= ss; mm++) {
            if (abs(tau[jj] + tau[mm] - 1) < tol) n_pairs++
        }
    }

    return(n_pairs)
}

// Restriction matrix for H0: theta(tau) = theta(1-tau) over every
// symmetric pair present in the tau grid.  Mirrors wtestsym().
void _qardl_build_symmetry_R(real scalar dim, string scalar tau_name,
    string scalar Rname, string scalar rname)
{
    real scalar ss, jj, mm, idx, tol, n_pairs
    real colvector tau, pair_j, pair_m
    real matrix R, r

    tau = st_matrix(tau_name)
    ss  = rows(tau)
    tol = 1e-10

    pair_j = J(ss*ss + 1, 1, 0)
    pair_m = J(ss*ss + 1, 1, 0)
    n_pairs = 0

    for (jj = 1; jj <= ss; jj++) {
        for (mm = jj + 1; mm <= ss; mm++) {
            if (abs(tau[jj] + tau[mm] - 1) < tol) {
                n_pairs++
                pair_j[n_pairs] = jj
                pair_m[n_pairs] = mm
            }
        }
    }

    if (n_pairs == 0) {
        st_matrix(Rname, J(0, dim*ss, 0))
        st_matrix(rname, J(0, 1, 0))
        return
    }

    R = J(n_pairs * dim, dim * ss, 0)
    r = J(n_pairs * dim, 1, 0)

    idx = 1
    for (jj = 1; jj <= n_pairs; jj++) {
        for (mm = 1; mm <= dim; mm++) {
            R[idx, (pair_j[jj]-1)*dim + mm] =  1
            R[idx, (pair_m[jj]-1)*dim + mm] = -1
            idx++
        }
    }

    st_matrix(Rname, R)
    st_matrix(rname, r)
}

// Wald statistic  W = scale * (R*b - r)' * ginv(R*V*R') * (R*b - r).
//
// Degrees of freedom are rank(R*V*R'), matching _qardlWaldInvAndRank()
// in GAUSS QARDL 3.1.1 rather than rows(R): the two differ whenever the
// restrictions are redundant or the restricted covariance is singular.
// Dimension mismatches are an error rather than being silently trimmed.
//
// Result is returned as the 2 x 1 matrix (W \ df).
void _qardl_wald_stat(string scalar beta_name, string scalar cov_name,
    string scalar R_name, string scalar r_name,
    real scalar scale, string scalar result_name)
{
    real matrix beta, cov, R, r, diff, RCR, RCR_inv
    real scalar wstat, rnk

    beta = st_matrix(beta_name)
    cov  = st_matrix(cov_name)
    R    = st_matrix(R_name)
    r    = st_matrix(r_name)

    if (rows(R) == 0) {
        st_matrix(result_name, (. \ 0))
        return
    }

    if (cols(R) != rows(beta)) {
        errprintf("qardl: restriction matrix has %g columns but the parameter vector has %g rows\n",
                  cols(R), rows(beta))
        exit(503)
    }
    if (rows(cov) != rows(beta) | cols(cov) != rows(beta)) {
        errprintf("qardl: covariance matrix is %g x %g but the parameter vector has %g rows\n",
                  rows(cov), cols(cov), rows(beta))
        exit(503)
    }
    if (rows(r) != rows(R)) {
        errprintf("qardl: restriction vector has %g rows but R has %g rows\n",
                  rows(r), rows(R))
        exit(503)
    }

    diff = R * beta - r
    RCR  = R * cov * R'
    RCR  = (RCR + RCR') / 2       // enforce exact symmetry

    rnk = rank(RCR)
    if (rnk == 0) {
        st_matrix(result_name, (. \ 0))
        return
    }

    // invsym() supplies a generalized inverse when RCR is singular,
    // which is what the rank-aware GAUSS path does.
    RCR_inv = invsym(RCR)

    wstat = scale * (diff' * RCR_inv * diff)

    st_matrix(result_name, (wstat \ rnk))
}

real matrix _qardl_pairwise_R(real scalar dim, real scalar ntau,
    real scalar qi, real scalar qj)
{
    real matrix R
    real scalar d

    R = J(dim, ntau * dim, 0)
    for (d = 1; d <= dim; d++) {
        R[d, (qi-1)*dim + d] =  1
        R[d, (qj-1)*dim + d] = -1
    }

    return(R)
}

end
