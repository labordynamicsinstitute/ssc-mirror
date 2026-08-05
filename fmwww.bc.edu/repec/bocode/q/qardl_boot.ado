*! qardl_boot v1.2.0 - Block bootstrap confidence intervals for QARDL
*! Translates blockBootstrapQARDL{,Method,Diag} and blockBootstrapQARDLECM*
*! from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Postestimation after qardl:
*!   qardl_boot [, reps(#) blocklength(#) level(#) seed(#) method(name) ecm]
*!
*! method() is moving (default), circular, or stationary.

program define qardl_boot, rclass
    version 14.0

    * Ensure the shared Mata routines are loaded
    capture mata which _qardl_core_estimate()
    if _rc {
        capture program drop _qardl_estimate
        qui findfile _qardl_estimate.ado
        qui run "`r(fn)'"
    }
    capture mata which _qardl_ic_design()
    if _rc {
        capture program drop _qardl_icmean
        qui findfile _qardl_icmean.ado
        qui run "`r(fn)'"
    }

    syntax [, REPS(integer 999) BLocklength(integer 0) LEVel(cilevel) ///
        SEED(integer 0) METHod(string) ECM NOTABle]

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

    if "`method'" == "" local method "moving"
    local method = lower("`method'")
    if !inlist("`method'", "moving", "circular", "stationary") {
        di as error "method() must be moving, circular, or stationary"
        exit 198
    }

    if `reps' < 1 {
        di as error "reps() must be a positive integer"
        exit 198
    }
    if `blocklength' < 0 {
        di as error "blocklength() must be non-negative"
        exit 198
    }

    local alpha = (100 - `level') / 100

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"
    local covariance "`e(covariance)'"

    tempname tau_vec
    mat `tau_vec' = e(tau)

    * Rebuild the estimation sample in Mata
    tempvar touse
    qui gen byte `touse' = e(sample)

    qui putmata _bs_y = `depvar' if `touse', replace
    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _bs_X = (`mxvars') if `touse', replace
    mata: _bs_tau = st_matrix("`tau_vec'")

    di as txt _n "  Block bootstrap: `reps' replications, `method' blocks ..."

    if "`ecm'" == "" {
        mata: _qardl_boot_levels(_bs_y, _bs_X, `p', `q', _bs_tau, ///
            `reps', `blocklength', `alpha', "`method'", `seed', "`covariance'")

        tempname ci_beta ci_gamma ci_phi bdiag
        mat `ci_beta' = _qardl_bs_ci_beta
        mat `ci_gamma' = _qardl_bs_ci_gamma
        mat `ci_phi' = _qardl_bs_ci_phi
        mat `bdiag' = _qardl_bs_diag

        if "`notable'" == "" {
            _qardl_boot_print `ci_beta' `tau_vec' `k' "`indepvars'" ///
                "Long-Run Parameters: beta(tau)" `level' e(beta)
            _qardl_boot_print `ci_gamma' `tau_vec' `k' "`indepvars'" ///
                "Short-Run Impact Parameters: gamma(tau)" `level' e(gamma)

            local phinames ""
            forvalues j = 1/`p' {
                local phinames "`phinames' L`j'.`depvar'"
            }
            _qardl_boot_print `ci_phi' `tau_vec' `p' "`phinames'" ///
                "Short-Run AR Parameters: phi(tau)" `level' e(phi)

            _qardl_boot_diag `bdiag' "`method'"
        }

        return matrix ci_beta = `ci_beta'
        return matrix ci_gamma = `ci_gamma'
        return matrix ci_phi = `ci_phi'
        return matrix boot_diag = `bdiag'
    }
    else {
        if !inlist("`e(ecmtype)'", "twostep", "both") {
            di as error "qardl_boot with ecm requires ecmtype(twostep) or ecmtype(both)"
            exit 198
        }

        capture mata which _qardl_ecm2_estimate()
        if _rc {
            capture program drop _qardl_ecm2
            qui findfile _qardl_ecm2.ado
            qui run "`r(fn)'"
        }

        mata: _qardl_boot_ecm(_bs_y, _bs_X, `p', `q', _bs_tau, ///
            `reps', `blocklength', `alpha', "`method'", `seed')

        tempname ci_alpha ci_rho bdiag
        mat `ci_alpha' = _qardl_bs_ci_alpha
        mat `ci_rho' = _qardl_bs_ci_rho
        mat `bdiag' = _qardl_bs_diag

        if "`notable'" == "" {
            _qardl_boot_print `ci_alpha' `tau_vec' 1 "alpha" ///
                "ECM Intercept: alpha(tau)" `level' e(ecm_alpha)
            _qardl_boot_print `ci_rho' `tau_vec' 1 "rho" ///
                "Speed of Adjustment: rho(tau)" `level' e(ecm_rho)
            _qardl_boot_diag `bdiag' "`method'"
        }

        return matrix ci_alpha = `ci_alpha'
        return matrix ci_rho = `ci_rho'
        return matrix boot_diag = `bdiag'
    }

    return scalar reps = `reps'
    return scalar level = `level'
    return local method "`method'"
end

* ============================================================
* Print one bootstrap interval table
* ============================================================
capture program drop _qardl_boot_print
program define _qardl_boot_print
    args ci tau_vec dim rownames title level est

    local ntau = rowsof(`tau_vec')

    di as txt _n "{hline 70}"
    di as res "  `title'"
    di as txt "  `level'% percentile block-bootstrap intervals"
    di as txt "{hline 70}"
    di as txt "  {ralign 14:Parameter}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 12:Lower}" _c
    di as txt "  {ralign 12:Upper}" _c
    di as txt "  {ralign 4:Sig}"
    di as txt "{hline 70}"

    local idx = 1
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        foreach v of local rownames {
            if `idx' <= rowsof(`ci') {
                local lo = `ci'[`idx', 1]
                local hi = `ci'[`idx', 2]
                local pe = `est'[`idx', 1]

                * an interval excluding zero is significant at 100-level
                if `lo' > 0 | `hi' < 0 local sg "*"
                else local sg " "

                di as txt "  {ralign 14:`v'}" _c
                di as txt "  {ralign 8:" %5.2f `tv' "}" _c
                di as res "  {ralign 12:" %10.4f `pe' "}" _c
                di as txt "  {ralign 12:" %10.4f `lo' "}" _c
                di as txt "  {ralign 12:" %10.4f `hi' "}" _c
                if "`sg'" == "*" {
                    di as res "  {ralign 4:*}"
                }
                else {
                    di as txt "  {ralign 4: }"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
    di as txt "  * interval excludes zero"
end

capture program drop _qardl_boot_diag
program define _qardl_boot_diag
    args bdiag method

    di as txt _n "{hline 70}"
    di as res "  Bootstrap diagnostics"
    di as txt "{hline 70}"
    di as txt "  Method             : " as res "`method'"
    di as txt "  Replications asked : " as res `bdiag'[1,1]
    di as txt "  Replications used  : " as res `bdiag'[1,2]
    di as txt "  Resamples rejected : " as res `bdiag'[1,3]
    di as txt "  Block length       : " as res `bdiag'[1,4]
    di as txt "  Seed               : " as res `bdiag'[1,5]
    if `bdiag'[1,2] < `bdiag'[1,1] {
        di as res "  Warning: fewer replications completed than requested."
        di as res "  Rank-deficient resamples were skipped; intervals use the"
        di as res "  completed draws only."
    }
    di as txt "{hline 70}"
end

* ============================================================
* Mata
* ============================================================
capture mata: mata drop _qardl_empquantile()
capture mata: mata drop _qardl_block_index()
capture mata: mata drop _qardl_block_length()
capture mata: mata drop _qardl_design_ok()
capture mata: mata drop _qardl_boot_levels()
capture mata: mata drop _qardl_boot_ecm()
capture mata: mata drop _qardl_pctile_ci()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Empirical quantile with linear interpolation between order
// statistics (the definition GAUSS quantile() converges to).
// ------------------------------------------------------------------
real scalar _qardl_empquantile(real colvector x, real scalar p)
{
    real colvector v
    real scalar n, h, lo

    v = sort(x, 1)
    n = rows(v)

    if (n == 1) return(v[1])

    h  = (n - 1) * p + 1
    lo = floor(h)
    if (lo < 1) lo = 1
    if (lo >= n) return(v[n])

    return(v[lo] + (h - lo) * (v[lo + 1] - v[lo]))
}

// ------------------------------------------------------------------
// Automatic block length, matching _qardlResolvedBlockLength().
// ------------------------------------------------------------------
real scalar _qardl_block_length(real scalar T, real scalar blk_len)
{
    real scalar L

    if (blk_len > 0) return(blk_len)

    L = trunc(T^(1/3))
    if (L < 2) L = 2

    return(L)
}

// ------------------------------------------------------------------
// Bootstrap row index.  Translates _qardlBootstrapIndex():
//   moving     - non-overlapping draws of overlapping blocks
//   circular   - blocks wrap around the end of the sample
//   stationary - geometric block lengths (Politis-Romano)
// ------------------------------------------------------------------
real colvector _qardl_block_index(real scalar T, real scalar blk_len,
    string scalar method)
{
    real scalar n_blks, jj, kk, pos, new_start_prob, first, last
    real colvector idx, starts

    if (method == "stationary") {
        idx = J(T, 1, 0)
        new_start_prob = 1 / blk_len
        pos = ceil(runiform(1, 1) * T)
        if (pos < 1) pos = 1
        for (jj = 1; jj <= T; jj++) {
            idx[jj] = pos
            if (runiform(1, 1) < new_start_prob) {
                pos = ceil(runiform(1, 1) * T)
                if (pos < 1) pos = 1
            }
            else {
                pos = pos + 1
                if (pos > T) pos = 1
            }
        }
        return(idx)
    }

    n_blks = ceil(T / blk_len)
    idx = J(n_blks * blk_len, 1, 0)

    if (method == "moving") {
        starts = ceil(runiform(n_blks, 1) * (T - blk_len + 1))
        for (jj = 1; jj <= n_blks; jj++) {
            if (starts[jj] < 1) starts[jj] = 1
            first = (jj - 1) * blk_len + 1
            last  = jj * blk_len
            idx[first..last] = starts[jj] :+ (0::(blk_len - 1))
        }
    }
    else {
        starts = ceil(runiform(n_blks, 1) * T)
        for (jj = 1; jj <= n_blks; jj++) {
            if (starts[jj] < 1) starts[jj] = 1
            for (kk = 1; kk <= blk_len; kk++) {
                pos = starts[jj] + kk - 1
                while (pos > T) pos = pos - T
                idx[(jj - 1) * blk_len + kk] = pos
            }
        }
    }

    return(idx[1..T])
}

// ------------------------------------------------------------------
// Is the levels design of a resample estimable?  Mirrors
// _qardlLevelsDesignOK(): full column rank and enough observations.
// ------------------------------------------------------------------
real scalar _qardl_design_ok(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq)
{
    real scalar nn, k0, ncols
    real colvector Y
    real matrix ONEX

    nn = rows(yy)
    k0 = cols(xx)
    ncols = 1 + qqq * k0 + k0 + ppp

    if (nn - max((ppp, qqq)) <= ncols + 1) return(0)

    ONEX = _qardl_ic_design(yy, xx, ppp, qqq, Y)
    if (rank(ONEX) < cols(ONEX)) return(0)

    return(1)
}

// ------------------------------------------------------------------
// Percentile interval for every row of a (B x dim) draw matrix.
// ------------------------------------------------------------------
real matrix _qardl_pctile_ci(real matrix draws, real scalar alpha)
{
    real scalar dim, jj
    real matrix ci

    dim = cols(draws)
    ci = J(dim, 2, .)

    for (jj = 1; jj <= dim; jj++) {
        ci[jj, 1] = _qardl_empquantile(draws[., jj], alpha / 2)
        ci[jj, 2] = _qardl_empquantile(draws[., jj], 1 - alpha / 2)
    }

    return(ci)
}

// ------------------------------------------------------------------
// Block bootstrap intervals for the levels-form parameters.
// Translates blockBootstrapQARDLMethod / ...Diag.
// ------------------------------------------------------------------
void _qardl_boot_levels(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    real scalar B, real scalar blk_len, real scalar alpha,
    string scalar method, real scalar seed, string scalar cov_type)
{
    real scalar T, k0, ss, done, failed, attempts, max_attempts, L
    real colvector idx, yb
    real matrix xb, boot_beta, boot_gamma, boot_phi

    T  = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)
    L  = _qardl_block_length(T, blk_len)

    if (seed > 0) rseed(seed)

    boot_beta  = J(B, k0 * ss, .)
    boot_gamma = J(B, k0 * ss, .)
    boot_phi   = J(B, ppp * ss, .)

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
            _qardl_core_estimate(yb, xb, ppp, qqq, tau, cov_type, 0)
            done++
            boot_beta[done, .]  = st_matrix("_qardl_beta")'
            boot_gamma[done, .] = st_matrix("_qardl_gamma")'
            boot_phi[done, .]   = st_matrix("_qardl_phi")'
        }
        else {
            failed++
        }
    }

    if (done < 1) {
        errprintf("qardl_boot: no valid bootstrap replication completed\n")
        exit(498)
    }

    if (done < B) {
        boot_beta  = boot_beta[1..done, .]
        boot_gamma = boot_gamma[1..done, .]
        boot_phi   = boot_phi[1..done, .]
    }

    st_matrix("_qardl_bs_ci_beta",  _qardl_pctile_ci(boot_beta, alpha))
    st_matrix("_qardl_bs_ci_gamma", _qardl_pctile_ci(boot_gamma, alpha))
    st_matrix("_qardl_bs_ci_phi",   _qardl_pctile_ci(boot_phi, alpha))
    st_matrix("_qardl_bs_diag", (B, done, failed, L, seed))
}

// ------------------------------------------------------------------
// Block bootstrap intervals for the two-step ECM parameters.
// Translates blockBootstrapQARDLECMMethod / ...Diag.
// ------------------------------------------------------------------
void _qardl_boot_ecm(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    real scalar B, real scalar blk_len, real scalar alpha,
    string scalar method, real scalar seed)
{
    real scalar T, ss, done, failed, attempts, max_attempts, L
    real colvector idx, yb
    real matrix xb, boot_alpha, boot_rho

    T  = rows(yy)
    ss = rows(tau)
    L  = _qardl_block_length(T, blk_len)

    if (seed > 0) rseed(seed)

    boot_alpha = J(B, ss, .)
    boot_rho   = J(B, ss, .)

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
            _qardl_ecm2_estimate(yb, xb, ppp, qqq, tau, "iid", 0)
            done++
            boot_alpha[done, .] = st_matrix("_qardl_e2_alpha")'
            boot_rho[done, .]   = st_matrix("_qardl_e2_rho")'
        }
        else {
            failed++
        }
    }

    if (done < 1) {
        errprintf("qardl_boot: no valid bootstrap replication completed\n")
        exit(498)
    }

    if (done < B) {
        boot_alpha = boot_alpha[1..done, .]
        boot_rho   = boot_rho[1..done, .]
    }

    st_matrix("_qardl_bs_ci_alpha", _qardl_pctile_ci(boot_alpha, alpha))
    st_matrix("_qardl_bs_ci_rho",   _qardl_pctile_ci(boot_rho, alpha))
    st_matrix("_qardl_bs_diag", (B, done, failed, L, seed))
}

end
