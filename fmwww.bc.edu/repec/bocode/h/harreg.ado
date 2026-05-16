program define harreg, eclass sortpreserve byable(recall)
    version 15.0

    /*
        HARREG: OLS with heteroskedasticity- and autocorrelation-robust
        (fixed-b) inference using the procedures recommended in
        Lazarus, Lewis, Stock, and Watson (2018) and Lazarus, Lewis,
        and Stock (2021).

        Default estimator: EWC with ν = floor(0.41*T^(2/3)).
        Other estimators: EWP, Newey-West (Bartlett), Quadratic Spectral.
        Truncation parameter (NW/QS) and degrees of freedom (EWC/EWP)
        can be overridden by the user.
    */

    if replay() {
        if "`e(cmd)'" != "harreg" {
            error 301
        }
        /* Replay supports only header/table suppression. `level()'
           cannot be honored without recomputing per-coefficient CIs
           (analytic from t-quantiles for EWC/EWP; from the stored
           NW/QS simulator otherwise) and the F-test critical value;
           rather than recompute partially or silently ignore the
           option, refuse it. Any other display options (`noci',
           `coeflegend', ...) are likewise refused so users get an
           explicit error instead of unchanged output. */
        syntax [, Level(string) noHEader noTABle *]
        if `"`level'"' != "" {
            di as err "level() not supported on replay; re-run harreg with level() to change CIs"
            exit 198
        }
        if `"`options'"' != "" {
            di as err "display option not supported on replay: `options'"
            exit 198
        }
        Display_har, `header' `table'
        exit
    }

    local cmdline : copy local 0

    syntax varlist(ts fv) [if] [in], ///
        [ ESTimator(string) LAGs(string) DF(string) ///
          Level(cilevel) NOCONStant ///
          CRITDRAWS(integer 5000) SEED(integer 88741997) ///
          noHEader noTABle * ]
    /* Refuse unsupported display options consistently with the
       replay branch above. Only `noheader' and `notable' are
       implemented; standard regress display options not in that
       set (noci, coeflegend, cformat, pformat, sformat, ...) are
       refused upfront rather than silently absorbed. */
    if `"`options'"' != "" {
        di as err "display option not supported: `options'"
        exit 198
    }

    marksample touse

    * Require tsset so that time-order is known
    capture tsset, noquery
    if "`r(timevar)'" == "" {
        di as err "data must be tsset before running harreg"
        exit 111
    }
    local timevar "`r(timevar)'"
    /* Gap check: HAR fixed-b inference assumes regularly spaced time. */
    quietly replace `touse' = . if `touse'==0
    quietly summarize `touse', meanonly
    if r(N)==0 {
        di as err "no observations"
        exit 2000
    }
    tempname __har_tsdelta
    scalar `__har_tsdelta' = 1
    if "`: char _dta[_TSdelta]'" != "" {
        scalar `__har_tsdelta' = real("`: char _dta[_TSdelta]'")
    }
    tempvar __har_tt
    quietly sort `touse' `timevar'
    quietly gen double `__har_tt' = (`timevar' - `timevar'[_n-1]) / `__har_tsdelta' if `touse'<.
    quietly summarize `__har_tt', meanonly
    /* Gate the gap check on r(N) >= 2: with a single in-sample row,
       `__har_tt' has no defined value (no _n-1 to subtract from), so
       both r(min) and r(max) are missing. Under Stata's missing-is-
       largest rule that would trip the "not unit-spaced" branch
       below; the T<10 refusal further down is the correct diagnostic
       for that input. */
    if r(N) >= 2 {
        if r(min)!=r(max) {
            di as err "`timevar' is not regularly spaced"
            exit 198
        }
        if r(mean)>1 & r(min)==r(max) {
            di as err "`timevar' is regularly spaced, but does not have intervals of 1"
            exit 198
        }
    }
    quietly replace `touse' = cond(missing(`touse'),0,`touse')
    quietly sort `timevar'

    if "`weight'" != "" {
        di as err "weights are not supported"
        exit 198
    }

    local est = lower(trim("`estimator'"))
    if "`est'" == "" local est "ewc"
    if !inlist("`est'","ewc","ewp","nw","qs") {
        di as err "estimator(`estimator') must be ewc, ewp, nw, or qs"
        exit 198
    }

    /* Validate lags() and df(). Both are declared on the syntax line
       as strings so that "unspecified" (empty after syntax parses) is
       distinguishable from any user-typed value, including -1. An
       unspecified option is mapped to the internal -1 sentinel
       consumed by har_build_hac; any user-typed nonpositive value is
       refused so it cannot silently land in the auto-bandwidth /
       auto-df branch of har_utils.mata. */
    if "`lags'" == "" {
        local lags = -1
    }
    else {
        capture confirm integer number `lags'
        local _lags_num = real("`lags'")
        if _rc | missing(`_lags_num') | `_lags_num' <= 0 {
            di as err "lags() must be a positive integer (got `lags'); omit lags() to use the default truncation parameter, or use regress, vce(robust) for HC-style (zero-lag) standard errors"
            exit 198
        }
        local lags = `_lags_num'
    }
    if "`df'" == "" {
        local df = -1
    }
    else {
        capture confirm number `df'
        local _df_num = real("`df'")
        if _rc | missing(`_df_num') | `_df_num' <= 0 {
            di as err "df() must be a positive value (got `df'); omit df() for the auto-df default"
            exit 198
        }
        local df = `_df_num'
    }

    /* Note when lags() is passed to an estimator that does not use a
       truncation bandwidth: silently ignored at the Mata level, but a
       runtime note prevents the user from thinking their bandwidth
       took effect. */
    if `lags' != -1 & inlist("`est'","ewc","ewp") {
        di as txt "note: lags() ignored for estimator(ewc/ewp)"
    }

    quietly count if `touse'
    local T = r(N)
    if `T' < 10 {
        di as err "insufficient observations after sample restrictions"
        exit 2001
    }

    /* Note when a user-explicit lags(L) hits the S clamp at T-1.
       Mata-level clamps in har_utils.mata silently reset S to T-1
       when S >= T; emit a visible note here. Only fires for
       user-typed lags(); the auto-bandwidth default and the QS
       df()-to-S derivation (both with lags = -1 internally) do
       not trip this. */
    if `lags' != -1 & `lags' >= `T' {
        di as txt "note: lags(`lags') exceeds T-1; clamping to T-1"
    }

    if (`critdraws' < 1000) local critdraws = 1000

    /* The seed is consumed only by the NW/QS Monte-Carlo simulators;
       EWC/EWP use analytic t/F distributions. Reseed only when a
       simulator will run, so a deterministic `harreg y x` (or any
       EWC/EWP call) leaves the user's RNG state untouched. */
    if (`seed' != 0 & inlist("`est'","nw","qs")) {
        quietly set seed `seed'
    }

    * Parse depvar and RHS
    gettoken dep rhs : varlist

    /* Refuse k > T before regress. `fvexpand` resolves factor groups
       to per-level tokens (no-op for plain varlists); the count plus
       1 (for the constant unless `noconstant`) is the effective k.
       Without this guard, regress silently column-drops to <= T
       surviving columns and harreg posts a sub-rank model with no
       diagnostic. */
    quietly fvexpand `rhs' if `touse'
    local k_input : word count `r(varlist)'
    if "`noconstant'" == "" {
        local k_input = `k_input' + 1
    }
    if `k_input' > `T' {
        di as err "k = `k_input' regressors exceeds T = `T' observations; " ///
            "design matrix would be rank-deficient"
        exit 2001
    }

    * Drop collinear regressors. `_rmcoll` accepts both ts and fv
    * tokens, returning a varlist with `o.`/`o<ts>.`-prefixed omitted
    * markers for non-fv columns and base-level markers (`Nb.var`)
    * for factor terms. Pass the result to `regress` as-is — regress
    * handles fv natively and produces `e(b)` colnames with the
    * canonical base-level marker; we adopt those downstream as the
    * coefficient-name truth and rebuild the design matrix from them
    * via `fvrevar`.
    quietly _rmcoll `rhs' if `touse'
    local rhs `r(varlist)'

    * Strip _rmcoll's ts-omitted markers. For ts operators `_rmcoll`
    * writes `o.x` / `oL.x` / etc. for omitted columns; left
    * unstripped, a downstream `generate ... = oL.x` evaluates to
    * zero and produces a rank-deficient X. Factor-variable base
    * levels (`Nb.var`) are intentionally retained — regress needs
    * the full set of factor tokens to derive its own omission
    * pattern (otherwise it picks a different base than _rmcoll did).
    local rhs_clean ""
    foreach v of local rhs {
        if !regexm("`v'", "^o([LFDS][0-9]*)*\.") {
            local rhs_clean "`rhs_clean' `v'"
        }
    }
    local rhs `rhs_clean'

    * Fit OLS using regress. `regress` accepts fv/ts directly and
    * produces `e(b)` with the canonical colnames we want to expose
    * downstream.
    quietly regress `dep' `rhs' if `touse', `noconstant'

    /* Refuse saturated models: k == T (after _rmcoll) leaves zero
       residual df. The HAR sandwich Omega = H'H collapses and SEs
       are degenerate. */
    if e(df_r) <= 0 {
        di as err "insufficient observations: zero residual degrees of " ///
            "freedom for HAR inference (k = " colsof(e(b)) ", T = " e(N) ")"
        exit 2001
    }

    quietly replace `touse' = e(sample)
    local T = e(N)

    tempname b_ols rmse_t
    matrix `b_ols' = e(b)
    scalar `rmse_t' = e(rmse)
    local depvar "`e(depvar)'"
    local df_r_orig = e(df_r)

    * Residuals
    tempvar __har_resid
    quietly predict double `__har_resid' if `touse', resid

    * Active-column names from regress's e(b) colnames. Drop
    * `Nb.var` (factor base level) and `o.var`-style omitted markers;
    * the surviving names index the columns whose coefficients are
    * estimated (not structurally zero). The full colnames
    * (`bnames_full`) are preserved for `ereturn post` so harwald
    * lookups against base-level names (e.g., `1.rep78`) resolve to
    * a zero-coefficient column the way regress would.
    local bnames_full : colfullnames `b_ols'
    local bnames_active ""
    local active_idx ""
    local pos = 0
    foreach name of local bnames_full {
        local ++pos
        if regexm("`name'", "^o([LFDS][0-9]*)*\.") continue
        if regexm("`name'", "[0-9]+b[no]?\.") continue
        local bnames_active "`bnames_active' `name'"
        local active_idx "`active_idx' `pos'"
    }
    local k_active : word count `bnames_active'

    * Materialize the active columns via `fvrevar` (handles fv/ts/c.
    * tokens uniformly: pass-through for plain vars, indicator column
    * for `2.rep78`, product column for `c.x#c.y`). Generate as
    * double, gated on `touse` so out-of-sample rows do not feed
    * `mkmat`.
    local rhs_concrete ""
    foreach name of local bnames_active {
        if "`name'" == "_cons" {
            tempvar tmpc
            quietly generate double `tmpc' = 1 if `touse'
            local rhs_concrete "`rhs_concrete' `tmpc'"
        }
        else {
            tempvar tmp
            fvrevar `name' if `touse'
            local fvrtmp `r(varlist)'
            quietly generate double `tmp' = `fvrtmp' if `touse'
            local rhs_concrete "`rhs_concrete' `tmp'"
        }
    }
    tempname Xmat
    mkmat `rhs_concrete' if `touse', matrix(`Xmat')

    * Build a coefficient sub-vector for Mata (only active columns).
    tempname b_active
    matrix `b_active' = J(1, `k_active', 0)
    local jj = 0
    foreach p of local active_idx {
        local ++jj
        matrix `b_active'[1, `jj'] = `b_ols'[1, `p']
    }
    matrix colnames `b_active' = `bnames_active'

    * All harreg-internal state lives in tempnames so nothing leaks
    * into the user's namespace.
    tempname b_har_a V_har_a p_har_a t_har_a ci_lo_a ci_hi_a se_har_a
    tempname cv_t bw_t df_t lvl_t r2_t rss_t mss_t r2_a_t ll_t tss_t rank_t

    * Capture regress's standard scalars now (still in scope before
    * the HAR sandwich replaces e()): downstream post-estimation
    * tools (estat ic, estimates table, esttab) read e(rss), e(mss),
    * e(r2_a), e(ll)
    scalar `rss_t'  = e(rss)
    scalar `mss_t'  = e(mss)
    scalar `r2_a_t' = e(r2_a)
    scalar `ll_t'   = e(ll)
    scalar `tss_t'  = e(tss)
    scalar `rank_t' = e(rank)

    * Build HAC covariance in Mata on the active sub-matrix.
    mata: har_build_hac("`est'", `T', `lags', `df', `critdraws', ///
        "`bnames_active'", "`__har_resid'", "`touse'", "`b_active'", "`Xmat'", `level'/100, ///
        "`b_har_a'", "`V_har_a'", "`p_har_a'", "`t_har_a'", "`se_har_a'", ///
        "`ci_lo_a'", "`ci_hi_a'", "`cv_t'", "`bw_t'", "`df_t'", "`lvl_t'")

    local   est_used    = "`har_est'"
    scalar  `r2_t'      = e(r2)
    local   bw          = `bw_t'
    local   df_fb       = `df_t'
    local   levelnum    = `lvl_t'

    * Re-inflate the active outputs to the full k columns of e(b),
    * placing zeros (b/se/t/ci) at base/omitted positions. Mirrors
    * regress's convention: base levels appear as zero entries in
    * e(b), have zero SE, and are recognized by downstream
    * test/lincom/harwald lookups.
    local k_full : word count `bnames_full'
    tempname b_har V_har p_har t_har ci_lo ci_hi se_har
    matrix `b_har'  = J(1, `k_full', 0)
    matrix `V_har'  = J(`k_full', `k_full', 0)
    matrix `p_har'  = J(1, `k_full', .)
    matrix `t_har'  = J(1, `k_full', .)
    matrix `ci_lo'  = J(1, `k_full', 0)
    matrix `ci_hi'  = J(1, `k_full', 0)
    matrix `se_har' = J(1, `k_full', 0)
    local jj = 0
    foreach p of local active_idx {
        local ++jj
        matrix `b_har'[1, `p']  = `b_har_a'[1, `jj']
        matrix `p_har'[1, `p']  = `p_har_a'[1, `jj']
        matrix `t_har'[1, `p']  = `t_har_a'[1, `jj']
        matrix `ci_lo'[1, `p']  = `ci_lo_a'[1, `jj']
        matrix `ci_hi'[1, `p']  = `ci_hi_a'[1, `jj']
        matrix `se_har'[1, `p'] = `se_har_a'[1, `jj']
        local kk = 0
        foreach pp of local active_idx {
            local ++kk
            matrix `V_har'[`p', `pp'] = `V_har_a'[`jj', `kk']
        }
    }

    /* Apply coefficient names to matrices to satisfy ereturn post */
    matrix colnames `b_har'  = `bnames_full'
    matrix colnames `V_har'  = `bnames_full'
    matrix rownames `V_har'  = `bnames_full'
    matrix colnames `p_har'  = `bnames_full'
    matrix colnames `t_har'  = `bnames_full'
    matrix colnames `ci_lo'  = `bnames_full'
    matrix colnames `ci_hi'  = `bnames_full'
    matrix colnames `se_har' = `bnames_full'
    local bnames "`bnames_full'"

    * Post results
    eret clear
    ereturn post `b_har' `V_har', depname("`depvar'") obs(`T') esample(`touse')
    ereturn local cmdline "harreg `cmdline'"
    ereturn local title   "Regression with HAR standard errors"
    ereturn local cmd     "harreg"
    ereturn local vce     "har `est_used'"
    ereturn local vcetype "HAR"
    ereturn local estimator "`est_used'"
    ereturn local predict "harreg_p"
    ereturn local properties "b V"
    ereturn scalar bw    = `bw_t'
    ereturn scalar df_fb = `df_t'
    ereturn scalar cv_fb = `cv_t'
    ereturn scalar level = `lvl_t'
    ereturn scalar rmse  = `rmse_t'
    ereturn scalar r2    = `r2_t'
    if !missing(`rss_t')  ereturn scalar rss  = `rss_t'
    if !missing(`mss_t')  ereturn scalar mss  = `mss_t'
    if !missing(`r2_a_t') ereturn scalar r2_a = `r2_a_t'
    if !missing(`ll_t')   ereturn scalar ll   = `ll_t'
    if !missing(`tss_t')  ereturn scalar tss  = `tss_t'
    if !missing(`rank_t') ereturn scalar rank = `rank_t'

    ereturn matrix p = `p_har'
    ereturn matrix t = `t_har'
    ereturn matrix ci_lo = `ci_lo'
    ereturn matrix ci_hi = `ci_hi'
    ereturn matrix se = `se_har'

    * Capture posted e() matrices into tempnames so later matrix-
    * function calls work under a `version 15.0` caller context
    * (`colsof(e(b))` etc. raise rc=509 if invoked directly there).
    tempname e_b e_V e_se e_t e_p e_ci_lo e_ci_hi
    matrix `e_b'     = e(b)
    matrix `e_V'     = e(V)
    matrix `e_se'    = e(se)
    matrix `e_t'     = e(t)
    matrix `e_p'     = e(p)
    matrix `e_ci_lo' = e(ci_lo)
    matrix `e_ci_hi' = e(ci_hi)

    tempname dfm_t dfr_t
    local k = colsof(`e_b')
    /* df_m / df_r count only estimated parameters. Posted `e(b)' has
       width k_full (k_active estimated columns reinflated with zero
       entries at factor base levels and `_rmcoll' omitted markers);
       the structural-zero columns are not free parameters, so they
       must not enter the df counts. Standard `regress' on the same
       input reports df_m = k_active - 1 (or k_active under
       noconstant) and df_r = T - k_active. */
    scalar `dfm_t' = `k_active' - ("`noconstant'"=="" ? 1 : 0)
    scalar `dfr_t' = `T' - `k_active'
    ereturn scalar df_m = `dfm_t'
    ereturn scalar df_r = `dfr_t'

    /* Model Wald F slope positions: walk the posted `e(b)' colnames
       and pick out every estimated slope. Skip `_cons' (unless
       noconstant), and skip factor base levels (`Nb.var', `Nbn.var',
       `Nbo.var') and `_rmcoll' omitted markers (`o.x', `oL.x', etc.)
       — they sit at structurally-zero columns of `e(b)' / `e(V)' and
       would make the corresponding row/col of VR_t all zero, so
       syminv(VR_t) silently returns a g-inverse that hides the
       degeneracy and inflates q. */
    local q = 0
    local slopepos ""
    local j = 1
    local rn_full : colnames `e_b'
    foreach r of local rn_full {
        local skip = 0
        if ("`r'" == "_cons" & "`noconstant'"=="") local skip = 1
        if regexm("`r'", "^o([LFDS][0-9]*)*\.") local skip = 1
        if regexm("`r'", "[0-9]+b[no]?\.") local skip = 1
        if !`skip' {
            local slopepos "`slopepos' `j'"
        }
        local ++j
    }
    local q : word count `slopepos'
    tempname F_t pF_t df2_t cvF_t W_t factor_t
    scalar `F_t'   = .
    scalar `pF_t'  = .
    scalar `df2_t' = .
    scalar `cvF_t' = .
    if (`q'>0) {
        tempname Rmat bR_t VR_t mtmp pF_sim_t cvF_sim_t
        matrix `Rmat' = J(`q', `k', 0)
        local idx 1
        foreach pos of local slopepos {
            matrix `Rmat'[`idx', `pos'] = 1
            local ++idx
        }
        matrix `bR_t' = `Rmat'*`e_b''
        matrix `VR_t' = `Rmat'*`e_V'*`Rmat''
        matrix `mtmp' = `bR_t''*syminv(`VR_t')*`bR_t'
        scalar `W_t' = `mtmp'[1,1]
        scalar `factor_t' = 1
        if inlist("`est_used'","ewc","ewp") & !missing(`df_fb') {
            scalar `df2_t'    = `df_fb' - `q' + 1
            /* Fixed-b denominator df guard: if df_fb - q + 1 <= 0
               the model-F reference distribution is undefined. Warn
               and leave F/p/crit missing rather than exit — harreg
               should still post b, V, and the per-coefficient SE
               even when the joint model F is not well-defined.
               harwald.ado uses rc=498 in the analogous path because
               there the test IS the call. */
            if missing(`df2_t') | `df2_t' <= 0 {
                di as txt "note: model F undefined " ///
                    "(fixed-b df_fb=" `df_fb' " < q=" `q' "); " ///
                    "F, p, crit. value left missing"
                scalar `F_t'   = .
                scalar `pF_t'  = .
                scalar `cvF_t' = .
            }
            else {
                scalar `factor_t' = (`df_fb' - `q' + 1)/`df_fb'
                scalar `F_t'      = `factor_t'*`W_t'/`q'
                scalar `pF_t'     = Ftail(`q', `df2_t', `F_t')
                scalar `cvF_t'    = invFtail(`q', `df2_t', 1 - `lvl_t')
            }
        }
        else if inlist("`est_used'","nw","qs") {
            scalar `F_t'   = `W_t'/`q'
            scalar `df2_t' = `dfr_t'   // use regression df_r for display
            mata: harwald_sim("`est_used'", `bw', `T', `critdraws', `q', ///
                st_numscalar("`F_t'"), `levelnum', "`cvF_sim_t'", "`pF_sim_t'")
            scalar `pF_t'  = `pF_sim_t'
            scalar `cvF_t' = `cvF_sim_t'
        }
    }
    ereturn scalar F_fb   = `F_t'
    ereturn scalar p_fb   = `pF_t'
    ereturn scalar cvF_fb = cond(missing(`cvF_t'), ., `cvF_t')

    * Standard e() alias for the model F-statistic (matches regress).
    * The model p-value stays on e(p_fb): we do NOT alias e(p) to
    * e(p_fb) because `ereturn matrix p` (per-coefficient p-values)
    * is posted above and a scalar of the same name would clobber
    * it (Stata e() namespace conflict). Downstream tools that want
    * the model F-test p-value should read e(p_fb); per-coefficient
    * p-values are in e(p) (matrix) and the r(table) from Display_har.
    if !missing(`F_t') {
        ereturn scalar F = `F_t'
    }

    * Render the header + coefficient table from posted e() results.
    * Display_har is r-class and sets r(table) for estout/esttab/
    * lincom consumers.
    Display_har, `header' `table'

    * Clean up temp vars
    capture drop `__har_resid' `__har_tt'
end


program define Display_har, rclass
    * Render the harreg header + coefficient table from posted e()
    * results and set r(table) to the 9 x k coefficient-results
    * matrix consumed by estout/esttab/lincom. Used by both the
    * estimation path and the replay branch; reads everything from
    * e(), no caller-side locals required. Honors `noheader' and
    * `notable' only; both callers refuse any other display option
    * upstream
    version 15.0

    syntax [, NOHEader NOTABle]

    * Capture e() matrices into tempnames so colsof/colnames calls
    * below work under a `version 15.0` caller context (rc=509 if
    * invoked directly on e() there).
    tempname e_b e_se e_t e_p e_ci_lo e_ci_hi
    matrix `e_b'     = e(b)
    matrix `e_se'    = e(se)
    matrix `e_t'     = e(t)
    matrix `e_p'     = e(p)
    matrix `e_ci_lo' = e(ci_lo)
    matrix `e_ci_hi' = e(ci_hi)

    local est_used "`e(estimator)'"
    local depvar   "`e(depvar)'"
    local T      = e(N)
    local bw_t   = e(bw)
    local rmse_t = e(rmse)
    local r2_t   = e(r2)
    local r2_a_t = e(r2_a)
    local cv_t   = e(cv_fb)
    local lvl_t  = e(level)
    local F_t    = e(F_fb)
    local pF_t   = e(p_fb)
    local df_fb  = e(df_fb)
    local dfr_t  = e(df_r)

    * `e(df_m)' carries the slope count excluding factor base levels
    * and `_rmcoll' omitted markers (set at the estimation site as
    * `k_active - (1 if constant else 0)'). `namelist' is retained
    * for the coefficient-table walk below.
    local namelist : colnames `e_b'
    local q = e(df_m)
    if missing(`q') local q = 0

    local df2_int = .
    if (`q' > 0) {
        if inlist("`est_used'","ewc","ewp") & !missing(`df_fb') {
            local df2_int = floor(`df_fb' - `q' + 1)
        }
        else if inlist("`est_used'","nw","qs") & !missing(`bw_t') & `bw_t' > 0 {
            /* Tukey kernel-equivalent df nu = T / (S * integral_k_squared)
               integral_k_squared = 2/3 (Bartlett) -> nu = (3/2)*T/S
               integral_k_squared = 6/5 (QS)      -> nu = (5/6)*T/S
               The fixed-b reference distribution for NW/QS is nonstandard
               (not F); the Prob > F line carries a `(sim)' qualifier in
               the header below so a reader does not interpret
               F(q, df2_int) as an analytic F-tail */
            local _kernel_constant = cond("`est_used'"=="nw", 3/2, 5/6)
            local df2_int = ceil(`_kernel_constant' * `T' / `bw_t')
        }
    }

    if "`noheader'" == "" {
        /* Header packs the right column to avoid an internal gap when
           the F line is suppressed (q = 0 or missing F_t). The 5 left
           lines are fixed (title, estimator, df/lags, Root MSE,
           fixed-b crit. val.); the right column lists the standard
           fit stats in the same order Stata `regress' uses, omitting
           F and Prob > F when the model F is not defined. */
        local _F_present = (`q' > 0 & !missing(`F_t'))
        local _r2a_present = !missing(`r2_a_t')
        local _pf_label = cond(inlist("`est_used'","nw","qs"), "Prob > F (sim)", "Prob > F")
        local _bw_label = cond(inlist("`est_used'","ewc","ewp"), "Deg. of freedom (nu)", "Truncation (lags)")

        di _n as txt "Regression with HAR standard errors" ///
            _col(49) as txt "Number of obs" _col(68) "=" _col(70) as res %9.0f `T'
        if `_F_present' {
            di as txt "Estimator: " as res upper("`est_used'") ///
                _col(49) as txt "F(" as res `q' as txt "," as res `df2_int' as txt ")" ///
                _col(68) "=" _col(70) as res %9.2f `F_t'
        }
        else {
            di as txt "Estimator: " as res upper("`est_used'") ///
                _col(49) as txt "R-squared" _col(68) "=" _col(70) as res %9.4f `r2_t'
        }
        if `_F_present' {
            di as txt "`_bw_label'" _col(22) "=" _col(24) as res %5.0f `bw_t' ///
                _col(49) as txt "`_pf_label'" _col(68) "=" _col(70) as res %9.4f `pF_t'
        }
        else if `_r2a_present' {
            di as txt "`_bw_label'" _col(22) "=" _col(24) as res %5.0f `bw_t' ///
                _col(49) as txt "Adj R-squared" _col(68) "=" _col(70) as res %9.4f `r2_a_t'
        }
        else {
            di as txt "`_bw_label'" _col(22) "=" _col(24) as res %5.0f `bw_t'
        }
        if `_F_present' {
            di as txt "Root MSE" _col(22) "=" _col(24) as res %9.4f `rmse_t' ///
                _col(49) as txt "R-squared" _col(68) "=" _col(70) as res %9.4f `r2_t'
        }
        else {
            di as txt "Root MSE" _col(22) "=" _col(24) as res %9.4f `rmse_t'
        }
        if `_F_present' & `_r2a_present' {
            di as txt "Fixed-b crit. val. (" %4.1f (`lvl_t'*100) "%)" ///
                _col(29) "=" _col(31) as res %8.4f `cv_t' ///
                _col(49) as txt "Adj R-squared" _col(68) "=" _col(70) as res %9.4f `r2_a_t'
        }
        else {
            di as txt "Fixed-b crit. val. (" %4.1f (`lvl_t'*100) "%)" ///
                _col(29) "=" _col(31) as res %8.4f `cv_t'
        }
    }

    if "`notable'" == "" {
        tempname mytab
        .`mytab' = ._tab.new, col(7) lmargin(0)
        .`mytab'.width    13   |12    12     8     8     12    12
        .`mytab'.titlefmt  .     .     .   %6s     .     %24s  .
        .`mytab'.pad       .     2     1     0     2     3     3
        .`mytab'.numfmt    . %9.0g %9.0g %7.2f  %5.3f %9.0g %9.0g

        local k : word count `namelist'
        local levelp = trim(string(`lvl_t'*100, "%4.1f"))

        .`mytab'.sep, top
        .`mytab'.titles "" "" "   HAR   " "" "" "" ""
        .`mytab'.titles "`depvar'" "Coef." "Std. Err." "t" "P>|t|" ///
            "[`levelp'% Conf. Interval]" ""
        .`mytab'.sep

        tempname dispb dispse dispt dispp displl dispul
        forvalues i = 1/`k' {
            local name : word `i' of `namelist'
            scalar `dispb'  = `e_b'[1, `i']
            scalar `dispse' = `e_se'[1, `i']
            scalar `dispt'  = `e_t'[1, `i']
            scalar `dispp'  = `e_p'[1, `i']
            scalar `displl' = `e_ci_lo'[1, `i']
            scalar `dispul' = `e_ci_hi'[1, `i']
            .`mytab'.row "`name'" `dispb' `dispse' `dispt' `dispp' `displl' `dispul'
        }
        .`mytab'.sep, bottom
    }

    * Build r(table) — 9 rows x k columns, matching the layout
    * produced by regress: b, se, t, pvalue, ll, ul, df, crit, eform.
    * The `df` row carries e(df_fb) for EWC/EWP and missing for
    * NW/QS (no closed-form fixed-b df; the simulated quantiles do
    * the inferential work for those estimators). `crit` is the
    * per-coefficient t critical value e(cv_fb). `eform` is 0
    * (harreg does not exponentiate).
    local kcols : word count `namelist'
    tempname r_table_har
    matrix `r_table_har' = J(9, `kcols', .)
    forvalues i = 1/`kcols' {
        matrix `r_table_har'[1, `i'] = `e_b'[1, `i']
        matrix `r_table_har'[2, `i'] = `e_se'[1, `i']
        matrix `r_table_har'[3, `i'] = `e_t'[1, `i']
        matrix `r_table_har'[4, `i'] = `e_p'[1, `i']
        matrix `r_table_har'[5, `i'] = `e_ci_lo'[1, `i']
        matrix `r_table_har'[6, `i'] = `e_ci_hi'[1, `i']
        matrix `r_table_har'[7, `i'] = cond(missing(`df_fb'), ., `df_fb')
        matrix `r_table_har'[8, `i'] = `cv_t'
        matrix `r_table_har'[9, `i'] = 0
    }
    matrix rownames `r_table_har' = b se t pvalue ll ul df crit eform
    matrix colnames `r_table_har' = `namelist'
    return matrix table = `r_table_har'
end
