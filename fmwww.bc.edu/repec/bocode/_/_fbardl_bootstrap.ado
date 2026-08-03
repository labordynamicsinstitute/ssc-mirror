*! _fbardl_bootstrap — Bootstrap Cointegration Tests for FBARDL
*! Implements McNown, Sam & Goh (2018) and Bertelli, Vacca & Zoia (2022)
*! Version 1.2.0 — 2026-08-02
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! The bootstrap data-generating process follows the source papers exactly:
*!
*!   - Recursive cumulation of the bootstrap series
*!         y*_t = y*_{t-1} + Dy*_t ,   x*_t = x*_{t-1} + Dx*_t
*!     McNown et al. (2018) Eqs. (7)-(8) and Step 4; Bertelli et al. (2022)
*!     Eq. (23). The fitted part of Dy*_t and Dx*_t is evaluated on the
*!     BOOTSTRAP history, not on the observed data.
*!
*!   - Residual recentring before/after resampling
*!     McNown et al. (2018) Eq. (13); Bertelli et al. (2022) Eqs. (21)-(22),
*!     both following Davidson & MacKinnon (2005).
*!
*!   - McNown et al. impose a single restricted null (the F_ov null) and read
*!     all three statistics from it (p. 6, Step 1). Bertelli et al. impose a
*!     SEPARATE null per statistic, Eqs. (16), (17) and (18), and generate a
*!     distinct bootstrap sample for each.
*!
*!   - Paired resampling of (v_yt, e_xt) preserves the contemporaneous
*!     correlation between the ARDL and marginal equations.
*!
*! Initial conditions are held at the observed values (t < t0). Bertelli et
*! al. instead draw a block of p observations at random; conditioning on the
*! observed start is the more common convention and is documented in the help
*! file.

capture program drop _fbardl_bootstrap
program define _fbardl_bootstrap, rclass
    version 17

    syntax varlist(ts fv) [if] [in], ///
        depvar(string)               ///
        indepvars(string)            ///
        levelvars(string)            ///
        indeplev(string)             ///
        ecmvar(string)               ///
        bootstrap_type(string)       ///
        reps(integer)                ///
        nobs(integer)                ///
        best_p(integer)              ///
        best_kstar(real)             ///
        timevar(string)              ///
        [                            ///
        estcmd(string)               /// regress | newey
        estopt(string)               /// vce(robust) | lag(#) | (empty)
        exog(string)                 /// fixed (exogenous) regressors
        fovterms(string)             /// restriction tested by F_ov (case dependent)
        fovnocons(string)            /// "noconstant" for PSS case 2
        trendvar(string)             /// _fbardl_trend for PSS cases 4 and 5
        j0(integer 0)                /// 0 = conditional, 1 = unconditional
        bestq(string)                /// selected q per indepvar, in order
        DGPcheck                     /// self-test the recursion (developer aid)
        ]

    gettoken lhs rhsvars : varlist

    if "`estcmd'" == "" local estcmd "regress"
    local vceclause ""
    if "`estopt'" != "" local vceclause ", `estopt'"
    if "`fovterms'" == "" local fovterms "`levelvars'"

    local nindep : word count `indepvars'
    local K = `nindep'

    // Default q list if the caller did not supply one
    if "`bestq'" == "" {
        forvalues m = 1/`K' {
            local bestq "`bestq' `best_p'"
        }
        local bestq = strtrim("`bestq'")
    }
    local qmax = 0
    foreach q of local bestq {
        if `q' > `qmax' local qmax = `q'
    }
    tempname QS
    mat `QS' = J(1, `K', 0)
    local m = 0
    foreach q of local bestq {
        local ++m
        mat `QS'[1, `m'] = `q'
    }

    // Work in double precision: the recursion writes generated levels back
    // into these variables
    capture recast double `depvar' `indepvars'

    // =========================================================================
    // OBSERVED TEST STATISTICS
    // =========================================================================
    qui `estcmd' `lhs' `rhsvars' `vceclause'
    local t_orig = _b[`ecmvar'] / _se[`ecmvar']
    qui test `fovterms'
    local Fov_orig = r(F)
    qui test `indeplev'
    local Find_orig = r(F)

    di as txt _col(5) "Running bootstrap (`reps' replications)..."
    di as txt ""

    // =========================================================================
    // RESTRICTED MODELS FOR THE y EQUATION (one per null)
    // =========================================================================
    // Null 1 : F_ov   — drop every term in the F_ov restriction
    // Null 2 : t      — drop L.depvar only          (Bertelli et al. Eq. 17)
    // Null 3 : F_ind  — drop the lagged x levels    (Bertelli et al. Eq. 18)
    if "`bootstrap_type'" == "fbardl_mcnown" {
        di as txt _col(5) "{it:Method: McNown, Sam & Goh (2018) — Unconditional}"
        di as txt _col(5) "{it:Single restricted null (F_ov), recursive DGP}"
        local nnull = 1
        local nulluse "1 1 1"
    }
    else {
        di as txt _col(5) "{it:Method: Bertelli, Vacca & Zoia (2022) — Conditional}"
        di as txt _col(5) "{it:Separate restricted null per statistic, recursive DGP}"
        local nnull = 3
        local nulluse "1 2 3"
    }
    di as txt ""

    // ---- build the restricted regressor lists ----
    // Null 1: everything named in `fovterms' is restricted to zero. _cons is
    // handled by the noconstant option, the rest are dropped from the list.
    local restr1 ""
    foreach v of local rhsvars {
        local drop = 0
        foreach lv of local fovterms {
            if "`v'" == "`lv'" local drop = 1
        }
        if `drop' == 0 local restr1 "`restr1' `v'"
    }
    // PSS case 2 restricts the intercept as well, so the restricted model
    // that generates the bootstrap data must have no constant
    local ropt1 ""
    if "`fovnocons'" != "" local ropt1 ", noconstant"
    local ropt2 ""
    local ropt3 ""

    // Null 2: drop the lagged dependent level only
    local restr2 ""
    foreach v of local rhsvars {
        if "`v'" != "`ecmvar'" local restr2 "`restr2' `v'"
    }

    // Null 3: drop the lagged independent levels only
    local restr3 ""
    foreach v of local rhsvars {
        local drop = 0
        foreach il of local indeplev {
            if "`v'" == "`il'" local drop = 1
        }
        if `drop' == 0 local restr3 "`restr3' `v'"
    }

    // =========================================================================
    // RESTRICTED y EQUATIONS: residuals, xb, and structural coefficients
    // =========================================================================
    tempvar bok
    qui gen byte `bok' = 1

    tempname AYY AYX PHI TH
    mat `AYY' = J(`nnull', 1, 0)
    mat `AYX' = J(`nnull', `K', 0)
    mat `PHI' = J(`nnull', `best_p', 0)
    local thw = `K' * (`qmax' + 1)
    mat `TH'  = J(`nnull', `thw', 0)

    forvalues h = 1/`nnull' {
        qui regress `lhs' `restr`h'' `ropt`h''
        tempvar rY`h' xbY`h'
        qui predict double `rY`h'', residuals
        qui predict double `xbY`h'', xb
        qui replace `bok' = 0 if missing(`rY`h'')

        // A term restricted out of the model has no _b[], so the capture
        // leaves the entry at zero — exactly the restriction the null imposes
        capture mat `AYY'[`h', 1] = _b[`ecmvar']
        local m = 0
        foreach xvar of local indepvars {
            local ++m
            capture mat `AYX'[`h', `m'] = _b[L.`xvar']
        }
        forvalues j = 1/`best_p' {
            capture mat `PHI'[`h', `j'] = _b[L`j'.D.`depvar']
        }
        local m = 0
        foreach xvar of local indepvars {
            local ++m
            local qm : word `m' of `bestq'
            forvalues j = `j0'/`qm' {
                local col = (`m' - 1) * (`qmax' + 1) + `j' + 1
                if `j' == 0 {
                    capture mat `TH'[`h', `col'] = _b[D.`xvar']
                }
                else {
                    capture mat `TH'[`h', `col'] = _b[L`j'.D.`xvar']
                }
            }
        }
    }

    // ---- marginal / auxiliary equations for the x variables ----
    // McNown: unrestricted Dx equation, lagged levels of y AND x (feedback
    //         allowed) — Eq. (12), second line.
    // BVZ   : marginal VECM, lagged levels of x only (weak exogeneity) —
    //         Eqs. (19)-(20).
    tempname BXY BXX PX TX
    mat `BXY' = J(`K', 1, 0)
    mat `BXX' = J(`K', `K', 0)
    mat `PX'  = J(`K', `best_p', 0)
    mat `TX'  = J(`K', `=`K' * `best_p'', 0)

    local m = 0
    foreach xvar of local indepvars {
        local ++m
        local xreg ""
        if "`bootstrap_type'" == "fbardl_mcnown" {
            // Unrestricted Dx equation: feedback from the level of y is
            // allowed (McNown et al. Eq. 12, second line)
            local xreg "`levelvars'"
        }
        else {
            // Marginal VECM: x levels only, weak exogeneity imposed
            // (Bertelli et al. Eqs. 19-20)
            foreach xv2 of local indepvars {
                local xreg "`xreg' L.`xv2'"
            }
        }
        forvalues j = 1/`best_p' {
            local xreg "`xreg' L`j'.D.`depvar'"
            foreach xv2 of local indepvars {
                local xreg "`xreg' L`j'.D.`xv2'"
            }
        }
        if `best_kstar' > 0 local xreg "`xreg' _fbardl_sin _fbardl_cos"
        if "`trendvar'" != "" local xreg "`xreg' `trendvar'"
        if "`exog'" != ""    local xreg "`xreg' `exog'"

        qui regress D.`xvar' `xreg'
        tempvar rX`m' xbX`m'
        qui predict double `rX`m'', residuals
        qui predict double `xbX`m'', xb
        qui replace `bok' = 0 if missing(`rX`m'')

        capture mat `BXY'[`m', 1] = _b[`ecmvar']
        local mm = 0
        foreach xv2 of local indepvars {
            local ++mm
            capture mat `BXX'[`m', `mm'] = _b[L.`xv2']
        }
        forvalues j = 1/`best_p' {
            capture mat `PX'[`m', `j'] = _b[L`j'.D.`depvar']
        }
        local mm = 0
        foreach xv2 of local indepvars {
            local ++mm
            forvalues j = 1/`best_p' {
                local col = (`mm' - 1) * `best_p' + `j'
                capture mat `TX'[`m', `col'] = _b[L`j'.D.`xv2']
            }
        }
    }

    qui count if `bok'
    local npool = r(N)
    if `npool' < 10 {
        di as err "  too few complete residual rows (`npool') to bootstrap"
        exit 2001
    }

    // The recursion needs an unbroken run of usable rows
    tempvar rowid
    qui gen long `rowid' = _n
    qui sum `rowid' if `bok', meanonly
    local t0 = r(min)
    local tN = r(max)
    qui count if !`bok' & `rowid' >= `t0' & `rowid' <= `tN'
    if r(N) > 0 {
        di as err "  the estimation sample has interior gaps; cannot generate a"
        di as err "  recursive bootstrap series. Check for missing values."
        exit 2001
    }
    qui count if `rowid' > `tN'
    if r(N) > 0 {
        di as err "  trailing observations lie outside the estimation sample"
        exit 2001
    }

    // =========================================================================
    // RESIDUAL RECENTRING
    // =========================================================================
    // McNown et al. Eq. (13): recentre the residual series once, BEFORE
    // resampling, with divisor (n - q - 1).
    // Bertelli et al. Eqs. (21)-(22): recentre each RESAMPLED set, inside the
    // replication. That is handled in Mata below.
    // dgpcheck needs the untouched residuals: with them the recursion must
    // reproduce the observed series exactly, which is what the check verifies.
    if "`bootstrap_type'" == "fbardl_mcnown" & "`dgpcheck'" == "" {
        local mcdiv = `npool' - `best_p' - 1
        if `mcdiv' < 1 local mcdiv = `npool'
        forvalues h = 1/`nnull' {
            qui sum `rY`h'' if `bok', meanonly
            qui replace `rY`h'' = `rY`h'' - r(sum) / `mcdiv' if `bok'
        }
        forvalues m = 1/`K' {
            qui sum `rX`m'' if `bok', meanonly
            qui replace `rX`m'' = `rX`m'' - r(sum) / `mcdiv' if `bok'
        }
        local recmode = 1
    }
    else if "`bootstrap_type'" != "fbardl_mcnown" & "`dgpcheck'" == "" {
        local recmode = 2
    }
    else {
        local recmode = 0
    }

    local dgpflag = 0
    if "`dgpcheck'" != "" local dgpflag = 1

    // =========================================================================
    // ASSEMBLE THE MATA INPUTS AND RUN THE BOOTSTRAP
    // =========================================================================
    local xbYlist ""
    local rYlist ""
    forvalues h = 1/`nnull' {
        local xbYlist "`xbYlist' `xbY`h''"
        local rYlist  "`rYlist' `rY`h''"
    }
    local xbXlist ""
    local rXlist ""
    forvalues m = 1/`K' {
        local xbXlist "`xbXlist' `xbX`m''"
        local rXlist  "`rXlist' `rX`m''"
    }

    local estfull "`estcmd' `lhs' `rhsvars' `vceclause'"

    tempname BOOTMAT
    mata: _fbardl_boot_engine(                                    ///
        "`depvar'", "`indepvars'",                                ///
        `t0', `tN', `best_p', `j0',                               ///
        st_matrix("`QS'"),                                        ///
        `reps', `nnull', "`nulluse'",                             ///
        "`estfull'", "`fovterms'", "`indeplev'", "`ecmvar'",      ///
        st_matrix("`AYY'"), st_matrix("`AYX'"), st_matrix("`PHI'"), st_matrix("`TH'"), ///
        "`xbYlist'", "`rYlist'",                                  ///
        st_matrix("`BXY'"), st_matrix("`BXX'"), st_matrix("`PX'"), st_matrix("`TX'"), ///
        "`xbXlist'", "`rXlist'",                                  ///
        `qmax', `recmode', `dgpflag', "`BOOTMAT'")

    di as txt ""
    di as txt ""

    // =========================================================================
    // CRITICAL VALUES AND P-VALUES
    // =========================================================================
    mata {
        BM = st_matrix("`BOOTMAT'")
        boot_Fov  = BM[., 1]
        boot_t    = BM[., 2]
        boot_Find = BM[., 3]

        boot_Fov_c  = select(boot_Fov,  boot_Fov  :< .)
        boot_t_c    = select(boot_t,    boot_t    :< .)
        boot_Find_c = select(boot_Find, boot_Find :< .)

        B_Fov  = rows(boot_Fov_c)
        B_t    = rows(boot_t_c)
        B_Find = rows(boot_Find_c)

        // F tests: upper tail  (McNown Eq. 15, Bertelli Eq. 24)
        if (B_Fov > 2) {
            s = sort(boot_Fov_c, 1)
            Fov_cv01  = s[min((ceil(0.99  * B_Fov), B_Fov))]
            Fov_cv025 = s[min((ceil(0.975 * B_Fov), B_Fov))]
            Fov_cv05  = s[min((ceil(0.95  * B_Fov), B_Fov))]
            Fov_cv10  = s[min((ceil(0.90  * B_Fov), B_Fov))]
            Fov_pval  = mean(boot_Fov_c :>= `Fov_orig')
        }
        else {
            Fov_cv01 = .; Fov_cv025 = .; Fov_cv05 = .; Fov_cv10 = .; Fov_pval = .
        }

        if (B_Find > 2) {
            s = sort(boot_Find_c, 1)
            Find_cv01  = s[min((ceil(0.99  * B_Find), B_Find))]
            Find_cv025 = s[min((ceil(0.975 * B_Find), B_Find))]
            Find_cv05  = s[min((ceil(0.95  * B_Find), B_Find))]
            Find_cv10  = s[min((ceil(0.90  * B_Find), B_Find))]
            Find_pval  = mean(boot_Find_c :>= `Find_orig')
        }
        else {
            Find_cv01 = .; Find_cv025 = .; Find_cv05 = .; Find_cv10 = .; Find_pval = .
        }

        // t test: lower tail  (McNown Eq. 16, Bertelli Eq. 25)
        if (B_t > 2) {
            s = sort(boot_t_c, 1)
            t_cv01  = s[max((floor(0.01  * B_t), 1))]
            t_cv025 = s[max((floor(0.025 * B_t), 1))]
            t_cv05  = s[max((floor(0.05  * B_t), 1))]
            t_cv10  = s[max((floor(0.10  * B_t), 1))]
            t_pval  = mean(boot_t_c :<= `t_orig')
        }
        else {
            t_cv01 = .; t_cv025 = .; t_cv05 = .; t_cv10 = .; t_pval = .
        }

        st_numscalar("r(Fov_cv01)",  Fov_cv01)
        st_numscalar("r(Fov_cv025)", Fov_cv025)
        st_numscalar("r(Fov_cv05)",  Fov_cv05)
        st_numscalar("r(Fov_cv10)",  Fov_cv10)
        st_numscalar("r(Fov_pval)",  Fov_pval)
        st_numscalar("r(t_cv01)",    t_cv01)
        st_numscalar("r(t_cv025)",   t_cv025)
        st_numscalar("r(t_cv05)",    t_cv05)
        st_numscalar("r(t_cv10)",    t_cv10)
        st_numscalar("r(t_pval)",    t_pval)
        st_numscalar("r(Find_cv01)",  Find_cv01)
        st_numscalar("r(Find_cv025)", Find_cv025)
        st_numscalar("r(Find_cv05)",  Find_cv05)
        st_numscalar("r(Find_cv10)",  Find_cv10)
        st_numscalar("r(Find_pval)",  Find_pval)
        st_numscalar("r(nvalid_Fov)",  B_Fov)
        st_numscalar("r(nvalid_t)",    B_t)
        st_numscalar("r(nvalid_Find)", B_Find)

        printf("{txt}  Bootstrap complete: %g valid Fov, %g t, %g Find replications\n", ///
            B_Fov, B_t, B_Find)
    }

    return scalar Fov_cv01  = r(Fov_cv01)
    return scalar Fov_cv025 = r(Fov_cv025)
    return scalar Fov_cv05  = r(Fov_cv05)
    return scalar Fov_cv10  = r(Fov_cv10)
    return scalar Fov_pval  = r(Fov_pval)
    return scalar t_cv01  = r(t_cv01)
    return scalar t_cv025 = r(t_cv025)
    return scalar t_cv05  = r(t_cv05)
    return scalar t_cv10  = r(t_cv10)
    return scalar t_pval  = r(t_pval)
    return scalar Find_cv01  = r(Find_cv01)
    return scalar Find_cv025 = r(Find_cv025)
    return scalar Find_cv05  = r(Find_cv05)
    return scalar Find_cv10  = r(Find_cv10)
    return scalar Find_pval  = r(Find_pval)
    return scalar nvalid_Fov  = r(nvalid_Fov)
    return scalar nvalid_t    = r(nvalid_t)
    return scalar nvalid_Find = r(nvalid_Find)
    return scalar reps = `reps'
end


// =============================================================================
// MATA ENGINE
// =============================================================================
version 17
mata:
mata set matastrict off

// Evaluate the y-equation fitted value that depends on the y/x history, for
// every t. Used both to strip the deterministic part out of predict's xb and
// inside the recursion.
real scalar _fbardl_fity(real colvector Yv, real matrix Xv,
                         real colvector dYv, real matrix dXv,
                         real scalar t,
                         real scalar ayy, real rowvector ayx,
                         real rowvector phi, real rowvector th,
                         real scalar p, real scalar j0,
                         real rowvector qs, real scalar qmax)
{
    real scalar v, m, j, K, col
    K = cols(Xv)
    v = 0
    if (t >= 2) {
        v = v + ayy * Yv[t-1]
        for (m = 1; m <= K; m++) v = v + ayx[m] * Xv[t-1, m]
    }
    for (j = 1; j <= p; j++) {
        if (t - j >= 1) v = v + phi[j] * dYv[t-j]
    }
    for (m = 1; m <= K; m++) {
        for (j = j0; j <= qs[m]; j++) {
            if (t - j >= 1) {
                col = (m - 1) * (qmax + 1) + j + 1
                v = v + th[col] * dXv[t-j, m]
            }
        }
    }
    return(v)
}

// Same for the marginal / auxiliary equation of x_i
real scalar _fbardl_fitx(real colvector Yv, real matrix Xv,
                         real colvector dYv, real matrix dXv,
                         real scalar t, real scalar i,
                         real colvector bxy, real matrix bxx,
                         real matrix px, real matrix tx,
                         real scalar p)
{
    real scalar v, m, j, K, col
    K = cols(Xv)
    v = 0
    if (t >= 2) {
        v = v + bxy[i] * Yv[t-1]
        for (m = 1; m <= K; m++) v = v + bxx[i, m] * Xv[t-1, m]
    }
    for (j = 1; j <= p; j++) {
        if (t - j >= 1) {
            v = v + px[i, j] * dYv[t-j]
            for (m = 1; m <= K; m++) {
                col = (m - 1) * p + j
                v = v + tx[i, col] * dXv[t-j, m]
            }
        }
    }
    return(v)
}

// One recursive bootstrap sample. Returns [y* , x*] as a T x (1+K) matrix.
//   x*_t is generated before y*_t within each period so that the conditional
//   ARDL equation can use the contemporaneous Dx*_t.
//   y*_t = y*_{t-1} + Dy*_t  and  x*_t = x*_{t-1} + Dx*_t
//   (McNown et al. Eqs. 7-8 and Step 4; Bertelli et al. Eq. 23)
real matrix _fbardl_recurse(real colvector Y0, real matrix X0,
                            real colvector dY0, real matrix dX0,
                            real colvector eY, real matrix eX,
                            real scalar t0, real scalar tN, real scalar h,
                            real matrix AYY, real matrix AYX,
                            real matrix PHI, real matrix TH,
                            real colvector BXY, real matrix BXX,
                            real matrix PX, real matrix TX,
                            real matrix detY, real matrix detX,
                            real scalar p, real scalar j0,
                            real rowvector qs, real scalar qmax)
{
    real scalar t, i, K, dxi, dy
    real colvector Ys, dYs
    real matrix Xs, dXs

    K = cols(X0)
    Ys = Y0; Xs = X0; dYs = dY0; dXs = dX0

    for (t = t0; t <= tN; t++) {
        for (i = 1; i <= K; i++) {
            dxi = detX[t, i] + eX[t, i] +
                  _fbardl_fitx(Ys, Xs, dYs, dXs, t, i, BXY, BXX, PX, TX, p)
            dXs[t, i] = dxi
            Xs[t, i]  = Xs[t-1, i] + dxi
        }
        dy = detY[t, h] + eY[t] +
             _fbardl_fity(Ys, Xs, dYs, dXs, t,
                          AYY[h, 1], AYX[h, .], PHI[h, .], TH[h, .],
                          p, j0, qs, qmax)
        dYs[t] = dy
        Ys[t]  = Ys[t-1] + dy
    }
    return((Ys, Xs))
}

void _fbardl_boot_engine(string scalar ynm, string scalar xnms,
                         real scalar t0, real scalar tN,
                         real scalar p, real scalar j0,
                         real rowvector qs,
                         real scalar reps, real scalar nnull,
                         string scalar nulluse,
                         string scalar estfull, string scalar fovlist,
                         string scalar indlist, string scalar ecmname,
                         real matrix AYY, real matrix AYX,
                         real matrix PHI, real matrix TH,
                         string scalar xbYlist, string scalar rYlist,
                         real colvector BXY, real matrix BXX,
                         real matrix PX, real matrix TX,
                         string scalar xbXlist, string scalar rXlist,
                         real scalar qmax, real scalar recmode,
                         real scalar dgpchk, string scalar outname)
{
    real scalar T, K, b, h, s, t, i, npool, lastnull, rc, dotstep
    real colvector Y0, dY0, idx, eY, poolrows
    real rowvector hs
    real matrix X0, dX0, YX, eX, stats
    real matrix detY, detX, poolY, poolX
    string rowvector xv

    xv = tokens(xnms)
    Y0 = st_data(., ynm)
    X0 = st_data(., xv)
    T  = rows(Y0)
    K  = cols(X0)

    // First differences of the observed series (row 1 set to zero; it is
    // never used for t >= t0)
    dY0 = J(T, 1, 0)
    dX0 = J(T, K, 0)
    for (t = 2; t <= T; t++) {
        dY0[t]   = Y0[t] - Y0[t-1]
        dX0[t, .] = X0[t, .] - X0[t-1, .]
    }

    // Deterministic + exogenous offset of each equation: the part of the
    // linear predictor that does not depend on the y/x history. Recovered as
    // xb minus the history part evaluated on the OBSERVED data, so it needs
    // no knowledge of the coefficient ordering.
    poolY = st_data(., tokens(rYlist))
    poolX = st_data(., tokens(rXlist))
    detY  = st_data(., tokens(xbYlist))
    detX  = st_data(., tokens(xbXlist))

    for (h = 1; h <= nnull; h++) {
        for (t = 1; t <= T; t++) {
            detY[t, h] = detY[t, h] - _fbardl_fity(Y0, X0, dY0, dX0, t,
                            AYY[h, 1], AYX[h, .], PHI[h, .], TH[h, .],
                            p, j0, qs, qmax)
        }
    }
    for (i = 1; i <= K; i++) {
        for (t = 1; t <= T; t++) {
            detX[t, i] = detX[t, i] - _fbardl_fitx(Y0, X0, dY0, dX0, t, i,
                            BXY, BXX, PX, TX, p)
        }
    }

    poolrows = (t0 :: tN)
    npool    = rows(poolrows)
    hs       = strtoreal(tokens(nulluse))

    // ---- DGP self-check -------------------------------------------------
    // Feed the recursion the observed residuals in their original order. The
    // restricted fitted value plus its own residual is the observed Dy_t, so
    // y*_t = y*_{t-1} + Dy_t must reproduce the observed series exactly. Any
    // error in the coefficient extraction, the deterministic decomposition or
    // a lag index shows up here as a non-zero deviation.
    if (dgpchk) {
        printf("\n{txt}  DGP self-check (recursion must reproduce the data):\n")
        for (h = 1; h <= nnull; h++) {
            eY = J(T, 1, 0)
            eX = J(T, K, 0)
            eY[t0::tN]    = poolY[poolrows, h]
            eX[t0::tN, .] = poolX[poolrows, .]
            YX = _fbardl_recurse(Y0, X0, dY0, dX0, eY, eX, t0, tN, h,
                                 AYY, AYX, PHI, TH, BXY, BXX, PX, TX,
                                 detY, detX, p, j0, qs, qmax)
            printf("{txt}    null %g:  max|y*-y| = %10.3e   max|x*-x| = %10.3e\n",
                   h, max(abs(YX[., 1] - Y0)),
                   max(abs(vec(YX[., 2..(K+1)] - X0))))
        }
        printf("\n")
    }

    stats = J(reps, 3, .)
    dotstep = max((floor(reps / 20), 1))
    printf("{txt}  Bootstrap progress: ")

    for (b = 1; b <= reps; b++) {
        if (mod(b, dotstep) == 0) printf("{txt}.")

        lastnull = 0
        for (s = 1; s <= 3; s++) {
            h = hs[s]

            if (h != lastnull) {
                // ---- paired resampling of (v_y, e_x) with replacement ----
                idx = poolrows[ceil(runiform(npool, 1) :* npool)]
                eY  = J(T, 1, 0)
                eX  = J(T, K, 0)
                eY[t0::tN]    = poolY[idx, h]
                eX[t0::tN, .] = poolX[idx, .]

                // Bertelli et al. Eqs. (21)-(22): recentre the resampled set
                if (recmode == 2) {
                    eY[t0::tN] = eY[t0::tN] :- mean(eY[t0::tN])
                    for (i = 1; i <= K; i++) {
                        eX[t0::tN, i] = eX[t0::tN, i] :- mean(eX[t0::tN, i])
                    }
                }

                // ---- recursive generation ----
                YX = _fbardl_recurse(Y0, X0, dY0, dX0, eY, eX, t0, tN, h,
                                     AYY, AYX, PHI, TH, BXY, BXX, PX, TX,
                                     detY, detX, p, j0, qs, qmax)

                st_store(., ynm, YX[., 1])
                st_store(., xv, YX[., 2..(K+1)])

                rc = _stata("quietly " + estfull)
                lastnull = (rc == 0 ? h : 0)
                if (rc != 0) continue
            }

            if (lastnull == 0) continue

            if (s == 1) {
                if (_stata("quietly test " + fovlist) == 0)
                    stats[b, 1] = st_numscalar("r(F)")
            }
            else if (s == 2) {
                if (_stata("quietly scalar __fb_t = _b[" + ecmname +
                           "]/_se[" + ecmname + "]") == 0)
                    stats[b, 2] = st_numscalar("__fb_t")
            }
            else {
                if (_stata("quietly test " + indlist) == 0)
                    stats[b, 3] = st_numscalar("r(F)")
            }
        }
    }

    // Put the observed data back
    st_store(., ynm, Y0)
    st_store(., xv, X0)

    st_matrix(outname, stats)
}

end
