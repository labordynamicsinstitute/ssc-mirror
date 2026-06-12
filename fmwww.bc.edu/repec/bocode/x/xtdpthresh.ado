*! version 0.7.5  11jun2026  (consolidated release since 0.6.0. AUDIT FIXES: e(sample) set via esample(); r()->e() handoff moved before -restore-; method(system) estimates a level-equation constant (cons_lvl) and adds the moment E[eta+eps]=0, matching xtabond2; unified fixed-weight 2-stage grid search for fod/system so the GMM objective is comparable across the gamma grid; add-one (Davidson-MacKinnon) bootstrap p-values; empty/disconnected CI acceptance regions flagged via e(ci_empty)/e(ci_nseg); zero-instrument rows dropped in the transformed equation too; iv() sub-option maxlag() now errors (was a silent override of the global lag depth), iv() collapse now collapses only the user-IV block; new rseed() option; e(cmdline) stored; per-gamma caches built once and shared across grid search, CI, linearity, and continuity tests; coefficient-name de-duplication; Mata conformability fix in xdpt2_stack_at_gamma for method(system). B1 (AR FORMULA): AR(1)/AR(2) now use the FULL Arellano-Bond (1991, eq. 8) m-statistic m_k = b0/sqrt(T1+T2+T3), including the estimated-parameter variance terms (-2g'(G'AG)^{-1}G'A*s and g'Vg), with a principled fallback to the simplified b0/sqrt(T1) when the variance pieces are unavailable or non-positive. B1 VERIFIED by two decisive checks: (1) an independent external AB(1991, eq.8) re-implementation fed the package's A/Z_f/X_f/V/residuals reproduces e(ar1)/e(ar2)/e(ar*_b0)/e(ar*_T1)/e(ar*_TT) to machine precision and matches Roodman's -abar- bit-for-bit on identical FD residuals; (2) Monte Carlo size of AR(2) under an H0 DGP (no 2nd-order autocorrelation) is on target near 5%. PREDICT: new xtdpthresh_p returns -residuals- (estimation-equation residual), -arresiduals- (the FD AR-test series, xtabond2 convention), -xb-, and -regime-; residuals are merged from persisted estimation rows by (panelvar,timevar) key, identical by construction across all methods and panel patterns, guarded by e(p_serial) against stale Mata state. NEW e(): ar*_b0/ar*_T1/ar*_TT decomposition and ar*_np full/fallback path-flag debug scalars. NEW OPTION -exportgmm- exposes the GMM weight A, instruments Z_f, and FD-transformed regressors X_f via Mata externals for external verification.)
*! version 0.6.1  26apr2026  (doc fixes: replace endogenous(L.roa) example that collided with auto-added L.y; correct Seo-Kim-Kim 2019 author order in references; disambiguate Hansen 1999 by listing both JoE panel-threshold paper and RES grid-bootstrap paper; add e(boundary_warn) to Stored results section of help)
*! version 0.6.0  25apr2026  (xthenreg-compatible strict sample restored after tsrevar; tsrevar expansion of ts operators in regressors and iv(); predetermined() option for weakly-exogenous regressors; robust syntax-based iv() parser supporting multi-var iv(z1 z2, collapse); maxlag validation requires >=2 for dynamic/endogenous; xdpt2_rangen replaces rangen for portability; valid-bootstrap p-values; xdpt2_quantile replaces mm_quantile; IV-empty level-eq rows dropped; cluster-robust V + Hansen J at best theta; unrestricted-bootstrap 2-step fallback)
*! Dynamic Panel Threshold Model with Endogeneity, Unbalanced Support
*! API matches xthenreg (Seo, Kim, and Kim 2019 SJ) extended with:
*!   - method(fod|fd|system) for unbalanced panels (Arellano-Bover 1995)
*!   - Grid bootstrap inference for threshold CI (Gong-Seo 2026 JoE)
*!
*! Authors:
*!   Duy Chinh Nguyen   <ndchinh@hcmiu.edu.vn>  (ORCID 0000-0002-9157-9358)
*!     School of Business, International University - VNU-HCM, Vietnam
*!   Nhat Duy Lai       <lnduy@sgu.edu.vn>      (ORCID 0009-0008-5365-2893)
*!     Faculty of Finance & Accounting, Saigon University, Ho Chi Minh City
*!   Corresponding author: Nhat Duy Lai
*!
*! Model (Seo-Shin 2016, Gong-Seo 2026):
*!   y_it = β1·y_{i,t-1} + x_it'β2 + (1, y_{i,t-1}, x_it')δ · 1{q_it > γ}
*!          + η_i + ε_it
*!
*! Syntax:
*!   xtdpthresh depvar [indepvars] [if] [in], qx(varname)
*!       [ endogenous(varlist) predetermined(varlist) exogenous(varlist)
*!         iv(varlist[, collapse]) ]
*!       [ kink static td ]
*!       [ method(fd|fod|system) ]
*!       [ collapse maxlag(# [#]) levmaxlag(# [#]) ]
*!       [ grid(#) gridci(#) trim(#) boot(#) rseed(#) ]
*!       [ nosearch nowarn citype(grid|none) level(#) verbose ]
*!
*! Positional args:
*!   depvar    — dependent variable y
*!   indepvars — other regressors x (exogenous by default)
*!   qx()      — threshold variable q (required option, not positional)
*!
*! Options:
*!   endogenous(varlist)    — contemporaneously endogenous regressors.
*!                            Instrumented in Δ/FOD eq by lags t-2, t-3, ....
*!   predetermined(varlist) — weakly exogenous (predetermined) regressors.
*!                            Instrumented in Δ/FOD eq by lags t-1, t-2, ....
*!   exogenous(varlist)     — extra exogenous regressors (treated like indepvars)
*!   iv(varlist[, collapse])
*!                       — user-supplied external IVs. The collapse sub-option
*!                         collapses ONLY the user-IV instrument block (one
*!                         shared column per IV instead of one per time block).
*!                         NOTE: the maxlag() sub-option is no longer
*!                         accepted — user IVs always enter as their period-t
*!                         value, so it never had any effect on them, while it
*!                         silently overrode the top-level maxlag() for
*!                         GMM-style instruments (L.y, endogenous(),
*!                         predetermined()). Use the top-level maxlag() instead.
*!   td                  — time-demean y and regressors within each t (q untouched)
*!   kink                — enforce continuity at threshold
*!   static              — do NOT auto-add L.y as regressor
*!   method(fd|fod|system) — transformation: fd (Seo-Shin default),
*!                           fod (unbalanced-friendly), system (+ level eqs)
*!   collapse            — collapse block-diagonal instruments across time
*!   maxlag(a [b])       — lag range for transformed-eq instruments
*!   levmaxlag(a [b])    — lag range for level-eq instruments (system)
*!   grid(#)             — # grid points for γ search; default 30
*!   gridci(#)           — # grid points for CI construction; default 25
*!   trim(#)             — trim fraction for γ grid; default 0.10
*!   boot(#)             — bootstrap replications; default 299
*!   rseed(#)            — set the RNG seed before any bootstrap draw, for
*!                         exact reproducibility of CI and test p-values
*!   citype(grid|none)   — CI method; default grid
*!   nosearch            — point estimate only, skip bootstrap CI
*!   nowarn              — suppress advisory warnings (boundary pin,
*!                         disconnected CI, method(system) bootstrap note)
*!   level(#)            — confidence level; default 95
*!   verbose             — print per-γ bootstrap progress
*!
*! Hard requirements: at least 5 usable units (>= 4
*! observations each) and at least 20 usable transformed observations per γ
*! for any GMM solve; γ points failing this are skipped in the grid search.
*!
*! Statistical notes:
*!   - method(system) estimates a level-equation constant ("cons_lvl", last
*!     element of e(b) when level rows exist) and adds the moment
*!     E[η+ε] = 0, following xtabond2.
*!   - AR(1)/AR(2) implement the full Arellano-Bond (1991, eq. 8) m-statistic
*!     including the estimated-parameter variance correction. For
*!     method(fod|system) the test is computed on FD-restacked residuals with
*!     the actual estimator's influence pieces — a faithful extension of the
*!     xtabond2 convention. Decomposition pieces (b0, T1, T2+T3) are exposed
*!     as e(ar*_b0), e(ar*_T1), e(ar*_TT) for external verification, and
*!     -predict, residuals- returns the underlying FD residuals (see D5).
*!   - Grid-bootstrap inference under method(system) resamples stacked
*!     transformed + level residuals jointly; this extension of Gong-Seo
*!     (2026) Algorithm 1 is heuristic.

program define xtdpthresh, eclass
    version 15.0

    // Capture the full command line BEFORE any parsing (the iv() sub-parser
    // below reuses local 0) so that e(cmdline) can be stored (v0.7.0).
    local cmdline `"`0'"'

    syntax varlist(min=1 numeric ts) [if] [in] ,   ///
        QX(varname numeric)                         ///
        [                                           ///
        IV(string)                                  ///
        ENDOgenous(varlist numeric ts)              ///
        PREDetermined(varlist numeric ts)           ///
        EXOgenous(varlist numeric ts)               ///
        KINK                                        ///
        STATIC                                      ///
        TD                                          ///
        COLLAPSE                                    ///
        MAXLAG(numlist max=2 min=1 integer >0)      ///
        LEVMAXLAG(numlist max=2 min=1 integer >0)   ///
        METHOD(string)                              ///
        GRID(integer 30)                            ///
        GRIDCI(integer 25)                          ///
        TRIM(real 0.10)                             ///
        BOOT(integer 299)                           ///
        RSEED(string)                               ///
        CITYPE(string)                              ///
        Level(cilevel)                              ///
        NOSEARCH                                    ///
        NOWARN                                      ///
        VERBOSE                                     ///
        EXPORTGmm                                   ///
        ]
    local flag_verbose   = cond("`verbose'"   != "", 1, 0)
    local flag_exportgmm = cond("`exportgmm'" != "", 1, 0)

    // === Parse iv() with sub-options: iv(varlist [, collapse]) ===
    // v0.7.0 semantics fix: the collapse sub-option no longer overrides the
    // top-level collapse; it collapses ONLY the user-IV block. The maxlag()
    // sub-option is rejected with an explanation — it never affected user IVs
    // (they always enter as the period-t value) but silently overrode the
    // top-level maxlag() for GMM-style instruments, a serious silent trap.
    local flag_ivcol_sub 0
    if "`iv'" != "" {
        // Save outer locals — the inner `syntax' call below clobbers `varlist',
        // `if', `in', and option locals such as `maxlag' / `collapse'.
        local _save_varlist    `"`varlist'"'
        local _save_if         `"`if'"'
        local _save_in         `"`in'"'
        local _outer_maxlag    `"`maxlag'"'
        local _outer_collapse  `"`collapse'"'

        // Robust parser for iv(z1 z2 [, collapse]).
        local 0 `"`iv'"'
        cap syntax varlist(numeric ts) [, MAXLAG(numlist max=2 min=1 integer >0) COLLAPSE]
        if _rc {
            di as err "invalid iv(...) syntax — use iv(varlist [, collapse])"
            exit 198
        }
        local iv_vars `"`varlist'"'
        if "`maxlag'" != "" {
            di as err "iv() sub-option maxlag() is not supported:"
            di as err "user-supplied IVs always enter as their period-t value, so"
            di as err "maxlag() never affected them — it only (silently) overrode the"
            di as err "top-level maxlag() controlling GMM-style instruments. Use the"
            di as err "top-level maxlag() option instead."
            exit 198
        }
        local flag_ivcol_sub = cond("`collapse'" != "", 1, 0)

        // Restore outer positional/if/in and option locals clobbered by the
        // inner syntax call. Top-level maxlag()/collapse are authoritative.
        local varlist  `"`_save_varlist'"'
        local if       `"`_save_if'"'
        local in       `"`_save_in'"'
        local maxlag   `"`_outer_maxlag'"'
        local collapse `"`_outer_collapse'"'

        local iv `iv_vars'
    }

    marksample touse, novarlist

    // === Option normalization & validation ===
    if "`method'" == "" local method "fd"
    if !inlist("`method'", "fd", "fod", "system") {
        di as err "option method() must be fd, fod, or system"
        exit 198
    }
    if "`citype'" == "" local citype "grid"
    if !inlist("`citype'", "grid", "none") {
        di as err "option citype() must be grid or none"
        exit 198
    }

    if `grid' < 10 | `gridci' < 10 {
        di as err "grid and gridci must be at least 10"
        exit 198
    }
    if `trim' < 0.01 | `trim' > 0.45 {
        di as err "trim must be in [0.01, 0.45]"
        exit 198
    }
    if `boot' < 10 {
        di as err "boot should be at least 10 (99+ recommended for production)"
        exit 198
    }
    // v0.7.0: rseed() for reproducible bootstrap inference (Mata's runiform()
    // shares the Stata RNG state, so -set seed- here pins every draw below).
    if "`rseed'" != "" {
        cap set seed `rseed'
        if _rc {
            di as err "rseed() invalid: could not execute -set seed `rseed'-"
            exit 198
        }
    }

    local flag_kink = cond("`kink'" != "", 1, 0)
    local flag_static = cond("`static'" != "", 1, 0)
    local flag_collapse = cond("`collapse'" != "", 1, 0)
    // v0.7.0: user-IV collapse flag — set by the iv(, collapse) sub-option;
    // top-level collapse implies it (collapsing everything includes user IVs).
    local flag_iv_collapse = cond(`flag_ivcol_sub' | `flag_collapse', 1, 0)

    // Parse maxlag(# [#]): interval form a..b; default unlimited
    local n_ml : word count `maxlag'
    if `n_ml' == 0 {
        local maxlag_lo = 1
        local maxlag_hi = 9999
    }
    else if `n_ml' == 1 {
        local maxlag_lo = 1
        local maxlag_hi : word 1 of `maxlag'
    }
    else {
        local maxlag_lo : word 1 of `maxlag'
        local maxlag_hi : word 2 of `maxlag'
    }
    if `maxlag_lo' > `maxlag_hi' {
        di as err "maxlag(# #) requires min <= max"
        exit 198
    }

    // Parse levmaxlag(# [#]): level-equation lag range; default (1 1)
    local n_ll : word count `levmaxlag'
    if `n_ll' == 0 {
        local levmaxlag_lo = 1
        local levmaxlag_hi = 1
    }
    else if `n_ll' == 1 {
        local levmaxlag_lo = 1
        local levmaxlag_hi : word 1 of `levmaxlag'
    }
    else {
        local levmaxlag_lo : word 1 of `levmaxlag'
        local levmaxlag_hi : word 2 of `levmaxlag'
    }
    if `levmaxlag_lo' > `levmaxlag_hi' {
        di as err "levmaxlag(# #) requires min <= max"
        exit 198
    }

    // === Parse varlist (xthreg2-style self-documenting syntax) ===
    // Syntax: xtdpthresh depvar [indepvars], qx(threshold_var) [options]
    // q_var is ALWAYS via qx() — explicit and required.
    gettoken depvar indepvars : varlist
    local indepvars = trim("`indepvars'")
    local q_var "`qx'"

    // Dependent variable must be a plain variable name. Time-series operators
    // are allowed for regressors/options only and are expanded below via tsrevar.
    if strpos("`depvar'", ".") {
        di as err "dependent variable may not contain time-series operators; create the lag/difference as a separate variable if needed"
        exit 198
    }

    // Save user-facing lists before tsrevar expansion. Expanded temporary
    // variable names are used internally; these labels are used for display,
    // ereturn metadata, and coefficient names.
    local indepvars_lab `"`indepvars'"'

    // Note: Seo-Shin (2016) permits q_var to appear as a regressor (in indepvars
    // or endogenous()). In that case the slope on q changes at γ — a natural
    // specification (e.g. "does the marginal effect of debt on invest shift
    // above some debt threshold?"). No overlap check needed.

    // === Collect all regressors ===
    // Exog regressors (default: all indepvars are exogenous unless endogenous()
    //                  or predetermined() is specified)
    // Endog regressors     (option endogenous())    : instruments from t-2
    // Predet regressors    (option predetermined()) : instruments from t-1
    // None of these three groups may overlap with each other or with indepvars.
    local exog_extra : list clean exogenous
    local endog      : list clean endogenous
    local predet     : list clean predetermined
    local inst_extra : list clean iv

    // User-facing copies after option macros are normalized.
    local exog_extra_lab `"`exog_extra'"'
    local endog_lab      `"`endog'"'
    local predet_lab     `"`predet'"'
    local inst_extra_lab `"`inst_extra'"'

    // Check no overlap between endogenous and indepvars
    local overlap : list endog & indepvars
    if "`overlap'" != "" {
        di as err "endogenous() vars must not appear in indepvars: `overlap'"
        exit 198
    }
    // Check no overlap between endogenous and exogenous
    local overlap2 : list endog & exog_extra
    if "`overlap2'" != "" {
        di as err "endogenous() and exogenous() vars must not overlap: `overlap2'"
        exit 198
    }
    // Check no overlap between indepvars and exogenous (would duplicate in X)
    local overlap3 : list indepvars & exog_extra
    if "`overlap3'" != "" {
        di as err "indepvars and exogenous() vars must not overlap: `overlap3'"
        exit 198
    }
    // Check no overlap between predetermined and (indepvars / exog / endog)
    local overlap4 : list predet & indepvars
    if "`overlap4'" != "" {
        di as err "predetermined() vars must not appear in indepvars: `overlap4'"
        exit 198
    }
    local overlap5 : list predet & exog_extra
    if "`overlap5'" != "" {
        di as err "predetermined() and exogenous() vars must not overlap: `overlap5'"
        exit 198
    }
    local overlap6 : list predet & endog
    if "`overlap6'" != "" {
        di as err "predetermined() and endogenous() vars must not overlap: `overlap6'"
        exit 198
    }

    local k_exog   : word count `indepvars' `exog_extra'
    local k_endog  : word count `endog'
    local k_predet : word count `predet'
    local k_inst   : word count `inst_extra'

    // Validate maxlag against model structure: dynamic L.y or endogenous regressors
    // require lag >= 2 in the transformed (Δ/FOD) equation, since x_{t-1} can
    // correlate with the differenced error term. Predetermined regressors only
    // need lag >= 1, which is already enforced by numlist constraints.
    if `maxlag_hi' < 2 & (!`flag_static' | `k_endog' > 0) {
        di as err "maxlag() upper bound must be at least 2 for dynamic or endogenous transformed-equation instruments"
        exit 198
    }

    // === xtset check ===
    capture xtset
    if _rc {
        di as err "must xtset panelid timevar before using xtdpthresh"
        exit 459
    }
    local panelvar = r(panelvar)
    local timevar  = r(timevar)
    local is_balanced = ("`r(balanced)'" == "strongly balanced")

    // === Expand time-series operators for Mata st_data() =======================
    // Stata's parser can accept numeric ts varlists, but Mata's st_data() cannot
    // reliably read expressions such as L.x, D.x, or L(1/2).x directly. tsrevar
    // materializes them as temporary variables. All downstream data handling uses
    // the expanded names, while *_lab locals preserve the user's original syntax.
    if `"`indepvars'"' != "" {
        cap tsrevar `indepvars'
        if _rc {
            di as err "could not expand indepvars with time-series operators"
            exit _rc
        }
        local _expanded `"`r(varlist)'"'
        local _n_user : word count `indepvars_lab'
        local _n_exp  : word count `_expanded'
        if `_n_user' != `_n_exp' {
            di as err "range time-series operators such as L(1/2).x are not supported here; spell them out as separate terms"
            exit 198
        }
        local indepvars `"`_expanded'"'
    }
    if `"`exog_extra'"' != "" {
        cap tsrevar `exog_extra'
        if _rc {
            di as err "could not expand exogenous() with time-series operators"
            exit _rc
        }
        local _expanded `"`r(varlist)'"'
        local _n_user : word count `exog_extra_lab'
        local _n_exp  : word count `_expanded'
        if `_n_user' != `_n_exp' {
            di as err "range time-series operators such as L(1/2).x are not supported here; spell them out as separate terms"
            exit 198
        }
        local exog_extra `"`_expanded'"'
    }
    if `"`endog'"' != "" {
        cap tsrevar `endog'
        if _rc {
            di as err "could not expand endogenous() with time-series operators"
            exit _rc
        }
        local _expanded `"`r(varlist)'"'
        local _n_user : word count `endog_lab'
        local _n_exp  : word count `_expanded'
        if `_n_user' != `_n_exp' {
            di as err "range time-series operators such as L(1/2).x are not supported here; spell them out as separate terms"
            exit 198
        }
        local endog `"`_expanded'"'
    }
    if `"`predet'"' != "" {
        cap tsrevar `predet'
        if _rc {
            di as err "could not expand predetermined() with time-series operators"
            exit _rc
        }
        local _expanded `"`r(varlist)'"'
        local _n_user : word count `predet_lab'
        local _n_exp  : word count `_expanded'
        if `_n_user' != `_n_exp' {
            di as err "range time-series operators such as L(1/2).x are not supported here; spell them out as separate terms"
            exit 198
        }
        local predet `"`_expanded'"'
    }
    if `"`inst_extra'"' != "" {
        cap tsrevar `inst_extra'
        if _rc {
            di as err "could not expand iv() variables with time-series operators"
            exit _rc
        }
        local _expanded `"`r(varlist)'"'
        local _n_user : word count `inst_extra_lab'
        local _n_exp  : word count `_expanded'
        if `_n_user' != `_n_exp' {
            di as err "range time-series operators such as L(1/2).x are not supported here; spell them out as separate terms"
            exit 198
        }
        local inst_extra `"`_expanded'"'
    }

    // === Time-effect purging (td option) =======================================
    // Equivalent to including year dummies in both regimes but enforcing equal
    // coefficients across regimes: subtract cross-sectional mean at each t from
    // every regressor / dependent variable. Leaves q untouched so γ retains its
    // interpretation. Demeaning is applied after preserve below, so user data
    // is not modified permanently. See "td" in {help xtdpthresh} for details.
    local flag_td = cond("`td'" != "", 1, 0)

    // === Auto-add L.y as first regressor if dynamic (non-static) ===
    // This matches xthenreg: dynamic model automatically includes L.y
    tempvar Ly
    if !`flag_static' {
        qui gen `Ly' = L.`depvar'
    }

    // === Sample handling ===
    // xthenreg-compatible strict sample. The marksample, novarlist call earlier
    // avoided Stata trying to mark out time-series operators before tsrevar
    // expansion. Now that tsrevar has materialized L.x/D.x into temporary
    // variables, explicitly mark out all observed user-supplied model variables
    // so that the effective sample matches the v0.5.4 / xthenreg convention
    // (drops rows where any user-supplied regressor is missing).
    //
    // For the dynamic specification, the auto-generated L.depvar is also
    // marked out to restore the xthenreg-compatible strict complete-case
    // sample. This intentionally excludes the first usable lag boundary row
    // from the estimation sample, matching the benchmark convention.
    markout `touse' `depvar' `q_var' `indepvars' `endog' `predet' `exog_extra' `inst_extra'
    if !`flag_static' {
        markout `touse' `Ly'
    }

    // === Display header ===
    local method_lab "`method'"
    if "`method'" == "fod" local method_lab "FOD (Arellano-Bover 1995)"
    if "`method'" == "fd"  local method_lab "FD (Arellano-Bond 1991)"
    if "`method'" == "system" local method_lab "System (Blundell-Bond 1998)"

    di ""
    di as text "{hline 78}"
    di as text "Dynamic Panel Threshold Model (Seo-Shin 2016, Gong-Seo 2026)"
    di as text "{hline 78}"
    di as text "Transformation: " as res "`method_lab'" ///
       as text "   Panel: " as res "`panelvar'" ///
       as text "   Time: " as res "`timevar'"
    local restr_lab = cond(`flag_kink', "   Restriction: kink", "")
    di as text "Dep. var: " as res "`depvar'" ///
       as text "   Threshold (q): " as res "`q_var'" ///
       as text "`restr_lab'"
    local reglist "`indepvars_lab' `exog_extra_lab'"
    local reglist : list clean reglist
    if !`flag_static' local reglist "L.`depvar' (auto) `reglist'"
    if `flag_td' local reglist "`reglist' (time-demeaned)"
    di as text "Regressors: " as res "`reglist'"
    if `k_endog'  > 0 di as text "Endogenous:    " as res "`endog_lab'"
    if `k_predet' > 0 di as text "Predetermined: " as res "`predet_lab'"
    if `k_inst'   > 0 di as text "Extra IVs:     " as res "`inst_extra_lab'"
    di ""

    // === Build regressor list for Mata: order matters ===
    // Column layout in X_mat:
    //   [L.y (if dynamic), exog_regressors, endog_regressors, predet_regressors]
    // Lagged y is column 1 when dynamic (handled via var_type).
    local all_exog "`indepvars' `exog_extra'"
    local all_exog : list clean all_exog
    local all_exog_lab "`indepvars_lab' `exog_extra_lab'"
    local all_exog_lab : list clean all_exog_lab

    // === Compute trim range for γ grid from q_var distribution ===
    // Match xthenreg convention: trim(0.2) = trim 0.1 each tail → p10 to p90
    tempname q_lo q_hi
    local trim_lo = (`trim' / 2) * 100
    local trim_hi = 100 - `trim_lo'
    qui _pctile `q_var' if `touse', percentiles(`trim_lo' `trim_hi')
    scalar `q_lo' = r(r1)
    scalar `q_hi' = r(r2)
    if missing(`q_lo') | missing(`q_hi') | (`q_lo' >= `q_hi') {
        di as err "qx() has insufficient variation after trim(`trim'); threshold grid is empty"
        exit 498
    }

    // === Dispatch to Mata ===
    local do_grid_ci = cond("`citype'" == "grid" & "`nosearch'" == "", 1, 0)

    // v0.7.0 advisory (B5): the wild-bootstrap theory of Gong-Seo (2026)
    // Alg. 1 covers the transformed equation; resampling stacked transformed
    // + level residuals jointly under method(system) is a heuristic extension.
    if "`method'" == "system" & `do_grid_ci' & "`nowarn'" == "" {
        di as text "Note: grid-bootstrap CI and tests under " as res "method(system)" ///
           as text " resample stacked"
        di as text "transformed + level residuals jointly — a heuristic extension of the"
        di as text "Gong-Seo (2026) Algorithm 1 theory. Interpret with caution (nowarn hides this)."
        di ""
    }

    preserve
    qui keep if `touse'
    sort `panelvar' `timevar'

    // Time-effect purging (td): subtract cross-sectional mean at each t from
    // y, every indepvar/endog/exogenous/inst variable, and L.y (if dynamic).
    // The threshold variable q is left untouched so γ keeps its original scale.
    // Applied after preserve so user data is not permanently modified.
    if `flag_td' {
        local _td_vars "`depvar' `indepvars' `endog' `predet' `exog_extra' `inst_extra'"
        if !`flag_static' local _td_vars "`_td_vars' `Ly'"
        local _td_vars : list clean _td_vars
        local _td_vars : list uniq _td_vars
        foreach _tv of local _td_vars {
            tempvar _m
            qui bysort `timevar': egen double `_m' = mean(`_tv')
            qui replace `_tv' = `_tv' - `_m'
            qui drop `_m'
        }
    }

    tempname b V gam obj nused gam_lo gam_hi pval_lin pval_cont
    tempname n_raw n_trans n_level n_iv n_units
    tempname hansen hansen_df hansen_p ar1 ar1_p ar2 ar2_p
    tempname ci_empty ci_nseg
    mata: xtdpthresh_run("`depvar'", "`Ly'", "`all_exog'", "`endog'",    ///
                          "`predet'", "`inst_extra'", "`q_var'",           ///
                          "`panelvar'", "`timevar'",                       ///
                          "`method'", `flag_static', `flag_kink',           ///
                          `flag_collapse', `maxlag_lo', `maxlag_hi',         ///
                          `levmaxlag_lo', `levmaxlag_hi',                   ///
                          `grid', `gridci', `trim', `=`q_lo'', `=`q_hi'',   ///
                          `do_grid_ci', `boot', `=(100-`level')/100',       ///
                          `flag_iv_collapse')

    // === Retrieve results from r() ===
    // v0.7.0 (A2 fix): retrieval moved BEFORE -restore-. Stata does not
    // guarantee that r() survives -restore-, so reading r() afterwards was
    // version-fragile.
    matrix `b'       = r(xdpt2_theta)
    matrix `V'       = r(xdpt2_V)
    scalar `gam'     = r(xdpt2_gamma)
    scalar `obj'     = r(xdpt2_obj)
    scalar `nused'   = r(xdpt2_nused)
    scalar `gam_lo'  = r(xdpt2_gam_lo)
    scalar `gam_hi'  = r(xdpt2_gam_hi)
    scalar `pval_lin' = r(xdpt2_pval_lin)
    scalar `pval_cont' = r(xdpt2_pval_cont)
    scalar `ci_empty' = r(xdpt2_ci_empty)
    scalar `ci_nseg'  = r(xdpt2_ci_nseg)
    scalar `n_raw'    = r(xdpt2_n_raw)
    scalar `n_trans'  = r(xdpt2_n_trans)
    scalar `n_level'  = r(xdpt2_n_level)
    scalar `n_iv'     = r(xdpt2_n_iv)
    scalar `n_units'  = r(xdpt2_n_units)
    scalar `hansen'    = r(xdpt2_hansen)
    scalar `hansen_df' = r(xdpt2_hansen_df)
    scalar `hansen_p'  = r(xdpt2_hansen_p)
    scalar `ar1'       = r(xdpt2_ar1)
    scalar `ar1_p'     = r(xdpt2_ar1_p)
    scalar `ar2'       = r(xdpt2_ar2)
    scalar `ar2_p'     = r(xdpt2_ar2_p)
    tempname ar1_b0 ar1_T1 ar1_TT ar2_b0 ar2_T1 ar2_TT ar1_np ar2_np
    scalar `ar1_b0' = r(xdpt2_ar1_b0)
    scalar `ar1_T1' = r(xdpt2_ar1_T1)
    scalar `ar1_TT' = r(xdpt2_ar1_TT)
    scalar `ar2_b0' = r(xdpt2_ar2_b0)
    scalar `ar2_T1' = r(xdpt2_ar2_T1)
    scalar `ar2_TT' = r(xdpt2_ar2_TT)
    scalar `ar1_np' = r(xdpt2_ar1_np)
    scalar `ar2_np' = r(xdpt2_ar2_np)
    tempname p_serial
    scalar `p_serial' = r(xdpt2_p_serial)

    restore

    // === Coefficient labels (match xthenreg convention) ===
    local cnames ""
    if !`flag_static' local cnames "Lag_y_b"
    foreach v of local all_exog_lab {
        local _cv = subinstr("`v'", ".", "_", .)
        local _cv = subinstr("`_cv'", "/", "_", .)
        local _cv = subinstr("`_cv'", "(", "", .)
        local _cv = subinstr("`_cv'", ")", "", .)
        local cnames "`cnames' `_cv'_b"
    }
    foreach v of local endog_lab {
        local _cv = subinstr("`v'", ".", "_", .)
        local _cv = subinstr("`_cv'", "/", "_", .)
        local _cv = subinstr("`_cv'", "(", "", .)
        local _cv = subinstr("`_cv'", ")", "", .)
        local cnames "`cnames' `_cv'_b"
    }
    foreach v of local predet_lab {
        local _cv = subinstr("`v'", ".", "_", .)
        local _cv = subinstr("`_cv'", "/", "_", .)
        local _cv = subinstr("`_cv'", "(", "", .)
        local _cv = subinstr("`_cv'", ")", "", .)
        local cnames "`cnames' `_cv'_b"
    }
    if !`flag_kink' {
        local cnames "`cnames' cons_d"
        if !`flag_static' local cnames "`cnames' Lag_y_d"
        foreach v of local all_exog_lab {
            local _cv = subinstr("`v'", ".", "_", .)
            local _cv = subinstr("`_cv'", "/", "_", .)
            local _cv = subinstr("`_cv'", "(", "", .)
            local _cv = subinstr("`_cv'", ")", "", .)
            local cnames "`cnames' `_cv'_d"
        }
        foreach v of local endog_lab {
            local _cv = subinstr("`v'", ".", "_", .)
            local _cv = subinstr("`_cv'", "/", "_", .)
            local _cv = subinstr("`_cv'", "(", "", .)
            local _cv = subinstr("`_cv'", ")", "", .)
            local cnames "`cnames' `_cv'_d"
        }
        foreach v of local predet_lab {
            local _cv = subinstr("`v'", ".", "_", .)
            local _cv = subinstr("`_cv'", "/", "_", .)
            local _cv = subinstr("`_cv'", "(", "", .)
            local _cv = subinstr("`_cv'", ")", "", .)
            local cnames "`cnames' `_cv'_d"
        }
    }
    else {
        local cnames "`cnames' kink_slope"
    }
    // v0.7.0 (A3 fix): method(system) carries a level-equation constant as
    // the LAST parameter whenever level rows exist (n_level > 0).
    if "`method'" == "system" & `=`n_level'' > 0 {
        local cnames "`cnames' cons_lvl"
    }

    // v0.7.0 (D3 fix): de-duplicate sanitized names — e.g. L.x and a variable
    // literally named L_x both map to "L_x_b"; append "_" until unique.
    local _cn_out ""
    foreach _c of local cnames {
        local _c2 "`_c'"
        while `: list _c2 in _cn_out' {
            local _c2 "`_c2'_"
        }
        local _cn_out "`_cn_out' `_c2'"
    }
    local cnames : list clean _cn_out

    matrix colnames `b' = `cnames'
    matrix rownames `b' = y1
    matrix colnames `V' = `cnames'
    matrix rownames `V' = `cnames'

    // === Compact final report (xthreg2-style) ===
    di as text "{hline 78}"
    // Compute boundary-pin flag (used both for display and e(boundary_warn))
    //   0 = neither bound pins  |  1 = lower pins  |  2 = upper pins  |  3 = both pin
    local _bwarn = 0
    if `do_grid_ci' {
        local _range_bnd = (`=`q_hi'') - (`=`q_lo'')
        if `_range_bnd' > 0 & !missing(`=`gam_lo'') & !missing(`=`gam_hi'') {
            local _eps_bnd = 1e-4 * `_range_bnd'
            local _lo_pin = (abs((`=`gam_lo'') - (`=`q_lo'')) < `_eps_bnd')
            local _hi_pin = (abs((`=`gam_hi'') - (`=`q_hi'')) < `_eps_bnd')
            if `_lo_pin' & `_hi_pin' local _bwarn = 3
            else if `_lo_pin'        local _bwarn = 1
            else if `_hi_pin'        local _bwarn = 2
        }
    }

    if `do_grid_ci' & `=`ci_empty'' == 1 {
        // v0.7.0 (B3 fix): an empty acceptance set is reported, not hidden
        // behind a degenerate point CI.
        di as text "Threshold estimate:"
        di as text "   γ̂ = " as res %7.4f `gam' ///
           as text "   GMM obj = " as res %7.3f `obj'
        di ""
        di as text "   " as err "Warning:" as text " grid bootstrap rejected ALL candidate γ at the " ///
           as res "`level'%" as text " level."
        di as text "   No confidence interval is reported: e(gamma_lo)/e(gamma_hi) are missing"
        di as text "   and e(ci_empty) = 1. This usually signals weak identification of γ or"
        di as text "   an unsuitable grid; re-run with different trim()/gridci() to check."
    }
    else if `do_grid_ci' {
        di as text "Threshold estimate (" as res "`level'% grid bootstrap CI" as text "):"
        di as text "   γ̂ = " as res %7.4f `gam' ///
           as text "   CI = [" as res %7.4f `gam_lo' ", " %7.4f `gam_hi' "]" ///
           as text "   GMM obj = " as res %7.3f `obj'

        // v0.7.0 (B3 fix): disconnected acceptance regions are flagged; the
        // hull is still reported for continuity with earlier versions.
        if !missing(`=`ci_nseg'') & `=`ci_nseg'' > 1 & "`nowarn'" == "" {
            di ""
            di as text "   " as err "Note:" as text " bootstrap acceptance region is disconnected (" ///
               as res `=`ci_nseg'' as text " segments);"
            di as text "   the CI shown is its convex hull. e(ci_nseg) stores the segment count."
        }

        // Display warning unless nowarn set. e(boundary_warn) flag is always
        // ereturn'd below regardless of display suppression.
        if `_bwarn' > 0 & "`nowarn'" == "" {
            di ""
            di as text "   " as err "Warning:" as text " CI " _c
            if `_bwarn' == 3 {
                di as text "BOTH bounds pin to trim boundaries [" ///
                   as res %7.4f `=`q_lo'' as text ", " ///
                   as res %7.4f `=`q_hi'' as text "]"
            }
            else if `_bwarn' == 1 {
                di as text "lower bound pins to trim floor (" ///
                   as res %7.4f `=`q_lo'' as text ")"
            }
            else {
                di as text "upper bound pins to trim ceiling (" ///
                   as res %7.4f `=`q_hi'' as text ")"
            }
            di as text "   Possible causes: weak identification in the affected regime,"
            di as text "   or grid edge at trim(" as res %4.2f `trim' as text ") cuts close to γ̂."
            di as text "   Re-run with a different trim to check γ̂ / CI stability."
            di as text "   Alternatives: trim(0.10) widens the grid (default in xthreg2);"
            di as text "   trim(0.15) is the Gong-Seo (2026) convention; trim(0.40) is the"
            di as text "   xthenreg / Seo-Shin (2016) convention. Suppress this warning with"
            di as text "   the " as res "nowarn" as text " option."
        }
    }
    else {
        di as text "Threshold estimate:"
        di as text "   γ̂ = " as res %7.4f `gam' ///
           as text "   GMM obj = " as res %7.3f `obj'
    }
    di ""
    di as text "Specification tests:"
    if `do_grid_ci' {
        di as text "   Linearity (H0: δ=0)      p = " as res %6.4f `pval_lin'
        if !`flag_kink' {
            di as text "   Continuity (H0: kink)    p = " as res %6.4f `pval_cont'
        }
    }
    di as text "   Hansen J = " as res %6.3f `hansen' ///
       as text "  (df=" as res %2.0f `hansen_df' ///
       as text ")  p = " as res %6.4f `hansen_p'
    di as text "   AR(1): m = " as res %6.3f `ar1' ///
       as text "  p = " as res %6.4f `ar1_p' ///
       as text "    AR(2): m = " as res %6.3f `ar2' ///
       as text "  p = " as res %6.4f `ar2_p'
    di ""
    local level_lab ""
    if `=`n_level'' > 0 local level_lab = "  level = " + string(`=`n_level'', "%5.0f")
    di as text "Sample: " ///
       as text "N obs = "  as res %5.0f `n_raw'  ///
       as text "  units = " as res %3.0f `n_units' ///
       as text "  trans = " as res %5.0f `n_trans' ///
       as res "`level_lab'" ///
       as text "  #IV = "   as res %4.0f `n_iv'
    di as text "{hline 78}"

    // v0.7.0 (A1 fix): esample() marks the estimation sample so that
    // post-estimation commands relying on e(sample) work correctly.
    ereturn post `b' `V', obs(`=`nused'') esample(`touse') depname("`depvar'")
    ereturn local cmd        "xtdpthresh"
    ereturn local predict    "xtdpthresh_p"
    ereturn local cmdline    `"xtdpthresh `cmdline'"'
    ereturn local depvar     "`depvar'"
    ereturn local q_var      "`q_var'"
    ereturn local indepvars  "`indepvars_lab'"
    ereturn local endog      "`endog_lab'"
    ereturn local predet     "`predet_lab'"
    ereturn local exog_extra "`exog_extra_lab'"
    ereturn local inst       "`inst_extra_lab'"
    ereturn local method     "`method'"
    ereturn local panelvar   "`panelvar'"
    ereturn local timevar    "`timevar'"
    ereturn scalar gamma     = `gam'
    ereturn scalar obj       = `obj'
    ereturn scalar gamma_lo  = `gam_lo'
    ereturn scalar gamma_hi  = `gam_hi'
    ereturn scalar pval_lin  = `pval_lin'
    ereturn scalar pval_cont = `pval_cont'
    ereturn scalar ci_empty  = `ci_empty'
    ereturn scalar ci_nseg   = `ci_nseg'
    ereturn scalar N_raw     = `n_raw'
    ereturn scalar N_trans   = `n_trans'
    ereturn scalar N_level   = `n_level'
    ereturn scalar N_iv      = `n_iv'
    ereturn scalar N_units   = `n_units'
    ereturn scalar hansen    = `hansen'
    ereturn scalar hansen_df = `hansen_df'
    ereturn scalar hansen_p  = `hansen_p'
    ereturn scalar ar1       = `ar1'
    ereturn scalar ar1_p     = `ar1_p'
    ereturn scalar ar2       = `ar2'
    ereturn scalar ar2_p     = `ar2_p'
    ereturn scalar ar1_b0    = `ar1_b0'
    ereturn scalar ar1_T1    = `ar1_T1'
    ereturn scalar ar1_TT    = `ar1_TT'
    ereturn scalar ar2_b0    = `ar2_b0'
    ereturn scalar ar2_T1    = `ar2_T1'
    ereturn scalar ar2_TT    = `ar2_TT'
    ereturn scalar ar1_np    = `ar1_np'
    ereturn scalar ar2_np    = `ar2_np'
    ereturn scalar p_serial  = `p_serial'
    ereturn scalar k_exog    = `k_exog'
    ereturn scalar k_endog   = `k_endog'
    ereturn scalar k_predet  = `k_predet'
    ereturn scalar k_inst    = `k_inst'
    ereturn scalar flag_kink = `flag_kink'
    ereturn scalar flag_static = `flag_static'
    ereturn scalar balanced  = `is_balanced'
    ereturn scalar flag_td   = `flag_td'
    ereturn scalar boundary_warn = `_bwarn'

    ereturn display, level(`level')
end


// ==================================================================
// MATA BACKEND — point estimation (Stage B.1)
// ==================================================================
mata:
mata set matastrict off

// Package-level Mata scalars (xdpt_collapse, xdpt_lag_lo, xdpt_lag_hi,
// xdpt_lev_lo, xdpt_lev_hi, xdpt_verbose) are declared "external" inside
// each function that uses them (Mata does not allow file-scope declarations
// at the top of a mata: block). xtdpthresh_run() assigns the values once
// per invocation; helpers read them via "external real scalar ..." locals.

// Built-in-safe replacement for rangen(): n equally spaced points from a to b.
// This avoids relying on version-specific Mata helpers.
real colvector xdpt2_rangen(real scalar a, real scalar b, real scalar n)
{
    real scalar i
    real colvector out
    if (n <= 1) return(J(1, 1, a))
    out = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        out[i] = a + (b - a) * (i - 1) / (n - 1)
    }
    return(out)
}

// Per-unit data structure (unbalanced-aware)
struct xdpt2_unit {
    real scalar    id
    real scalar    t0       // first observed time (v0.7.0: O(1) lookup anchor)
    real colvector tpos     // tpos[t - t0 + 1] = row index in u.t; 0 = absent
                            // (empty => xdpt2_find_t falls back to linear scan)
    real colvector t        // observed times, sorted
    real colvector y        // y at observed times
    real matrix    X        // regressors at observed times (n_i × K)
                            // col 1: L.y (if dynamic); then exog; then endog;
                            //        then predetermined
    real colvector q        // q at observed times
    real rowvector var_type // per col: 1=lag_y, 2=exog, 3=endog, 4=predet
    real scalar    k_endog_start  // col index where endog starts (0 if none)
    real matrix    X_inst   // user-supplied instrument values (n_i × k_inst)
}

// Build per-unit structs from long-form data
struct xdpt2_unit rowvector xdpt2_build_units(
    real colvector y, real matrix Ly, real matrix X_exog,
    real matrix X_endog, real matrix X_predet,
    real matrix X_inst, real colvector q,
    real colvector pid, real colvector tid,
    real scalar flag_static)
{
    struct xdpt2_unit rowvector U
    struct xdpt2_unit scalar u
    real colvector ids, idx, ord, var_type
    real scalar n_units, i, K, k_ex, k_en, k_pd, k_in

    ids = uniqrows(pid)
    n_units = rows(ids)
    U = xdpt2_unit(0)

    k_ex = cols(X_exog)
    k_en = cols(X_endog)
    k_pd = cols(X_predet)
    k_in = cols(X_inst)
    real scalar lag_y_present
    lag_y_present = (flag_static ? 0 : 1)
    K = lag_y_present + k_ex + k_en + k_pd

    var_type = J(1, 0, 0)
    if (!flag_static) var_type = var_type, 1
    if (k_ex > 0)     var_type = var_type, J(1, k_ex, 2)
    if (k_en > 0)     var_type = var_type, J(1, k_en, 3)
    if (k_pd > 0)     var_type = var_type, J(1, k_pd, 4)

    for (i = 1; i <= n_units; i++) {
        idx = selectindex(pid :== ids[i])
        if (rows(idx) < 4) continue

        u.id = ids[i]
        u.t = tid[idx]
        u.y = y[idx]
        u.q = q[idx]

        ord = order(u.t, 1)
        u.t = u.t[ord]
        u.y = u.y[ord]
        u.q = u.q[ord]

        u.X = J(rows(idx), 0, 0)
        if (!flag_static) u.X = u.X, Ly[idx][ord]
        if (k_ex > 0)     u.X = u.X, X_exog[idx, .][ord, .]
        if (k_en > 0)     u.X = u.X, X_endog[idx, .][ord, .]
        if (k_pd > 0)     u.X = u.X, X_predet[idx, .][ord, .]

        u.X_inst = J(rows(idx), 0, 0)
        if (k_in > 0) u.X_inst = X_inst[idx, .][ord, .]

        u.var_type = var_type
        u.k_endog_start = (k_en + k_pd > 0 ? K - (k_en + k_pd) + 1 : 0)

        // v0.7.0 (D7): O(1) time-position lookup table. Guarded: only built
        // when times are integers and the span is sane; otherwise find_t
        // falls back to the original linear scan.
        real scalar _span, _jj
        u.t0 = u.t[1]
        _span = u.t[rows(u.t)] - u.t0 + 1
        if (_span >= rows(u.t) & _span <= 100000 & min(u.t :== floor(u.t)) == 1) {
            u.tpos = J(_span, 1, 0)
            for (_jj = 1; _jj <= rows(u.t); _jj++) {
                u.tpos[u.t[_jj] - u.t0 + 1] = _jj
            }
        }
        else u.tpos = J(0, 1, 0)

        U = U, u
    }
    return(U)
}

// Helper: find index in u.t where u.t[j] == target; 0 if not found.
// v0.7.0 (D7): O(1) via the per-unit tpos table when available; the original
// O(n_i) linear scan is kept as a fallback for non-integer time grids.
real scalar xdpt2_find_t(struct xdpt2_unit scalar u, real scalar target)
{
    real scalar j, off
    if (rows(u.tpos) > 0) {
        off = target - u.t0 + 1
        if (off != trunc(off)) return(0)
        if (off < 1 | off > rows(u.tpos)) return(0)
        return(u.tpos[off])
    }
    for (j = 1; j <= rows(u.t); j++) {
        if (u.t[j] == target) return(j)
    }
    return(0)
}

// Helper: true if any element of a row vector / matrix block is missing.
real scalar xdpt2_hasmiss(real matrix A)
{
    if (rows(A) == 0 | cols(A) == 0) return(0)
    return(sum(A :>= .) > 0)
}

// Transform one unit: FD or FOD for both y and X.
// Returns (dy, dW(γ), Z, retained_times) for this unit.
// W includes regime regressors: W = [X_trans, r, r·y_lag, r·X_exog, r·X_endog, r·X_predet]
// For non-kink model. For kink, W has fewer cols (see separate function).
void xdpt2_transform_unit(struct xdpt2_unit scalar u,
                           real scalar gamma, string scalar method,
                           real scalar flag_static, real scalar flag_kink,
                           real scalar t_min_global, real scalar t_max_global,
                           real matrix dy_out, real matrix dW_out,
                           real matrix Z_out, real colvector times_out)
{
    real scalar n, K, j, t, Tf, c, lag_max, b, base_col, block_K, n_blocks
    real scalar y_lag_t, x_lag_t, v, lag_needed, n_iv_cols
    real colvector r, dy_list, times_list, iv_row
    real matrix W_lvl, dW_list, w_row, Z_list
    real rowvector fut_mean_w

    n = rows(u.y)
    K = cols(u.X)

    // Build level regressors w_it(γ):
    //   Jump (non-kink): [X_it, r_it, r_it·X_it]  → 2K+1 cols
    //   Kink:            [X_it, (q_it-γ)·r_it]    → K+1 cols
    //                     where the kink term has coefficient δ_3 (slope change)
    real scalar k_W_cols
    real colvector kink_var
    r = (u.q :> gamma)
    if (flag_kink) {
        kink_var = (u.q :- gamma) :* r
        W_lvl = u.X, kink_var       // (n × (K+1))
        k_W_cols = K + 1
    }
    else {
        W_lvl = u.X, r, u.X :* r    // (n × (2K+1))
        k_W_cols = 2*K + 1
    }

    // Per-unit transformation loop
    dy_list = J(0, 1, 0)
    dW_list = J(0, k_W_cols, 0)
    times_list = J(0, 1, 0)

    if (method == "fd") {
        for (j = 2; j <= n; j++) {
            if (u.t[j] - u.t[j-1] != 1) continue  // not consecutive
            // Check we have at least 2 years of history for IV
            if (xdpt2_find_t(u, u.t[j] - 2) == 0) continue
            // Skip candidate rows whose transformed regressor would contain missing values
            if (u.y[j] >= . | u.y[j-1] >= . | u.q[j] >= . | u.q[j-1] >= .) continue
            if (xdpt2_hasmiss(W_lvl[j, .]) | xdpt2_hasmiss(W_lvl[j-1, .])) continue
            dy_list = dy_list \ (u.y[j] - u.y[j-1])
            dW_list = dW_list \ (W_lvl[j, .] - W_lvl[j-1, .])
            times_list = times_list \ u.t[j]
        }
    }
    else {  // fod
        for (j = 1; j <= n - 1; j++) {
            // FOD: need at least 2 years history for IV + future obs for mean
            if (xdpt2_find_t(u, u.t[j] - 2) == 0) continue
            Tf = n - j
            if (Tf < 1) continue
            // Skip candidate rows whose FOD-transformed regressor would contain missing values
            if (u.y[j] >= . | u.q[j] >= . | xdpt2_hasmiss(u.y[|j+1 \ n|]) | xdpt2_hasmiss(u.q[|j+1 \ n|])) continue
            if (xdpt2_hasmiss(W_lvl[j, .]) | xdpt2_hasmiss(W_lvl[|j+1, 1 \ n, k_W_cols|])) continue
            c = sqrt(Tf / (Tf + 1))
            dy_list = dy_list \ (c * (u.y[j] - mean(u.y[|j+1 \ n|])))
            fut_mean_w = mean(W_lvl[|j+1, 1 \ n, k_W_cols|])
            dW_list = dW_list \ (c * (W_lvl[j, .] - fut_mean_w))
            times_list = times_list \ u.t[j]
        }
    }

    // === Build block-diagonal Z matrix per xthenreg moment structure ===
    // Per time block t ∈ [t_min+2, t_max]:
    //   col 1:        constant (1)
    //   cols 2..:     y lags (y_{t-2}, y_{t-3}, ..., up to lag_max = t-t_min)
    //   next cols:    for each exog x: Δx_t (1 IV per t)
    //   next cols:    for each endog x: x_lags (x_{t-2}, x_{t-3}, ...)
    //   next cols:    for each predet x: x_lags (x_{t-1}, x_{t-2}, ...)
    //   next cols:    user-supplied external IVs (1 per var per block)
    // Block-diagonal across t: row at time t has nonzero only in block b(t).

    // Determine per-block IV width (use t_max_global for max lag depth)
    lag_max = t_max_global - t_min_global  // max possible lag count at t=t_max
    // Per block at time t: width = 1(const) + #lag_y + #exog + (#endog + #predet)·(lags)
    //                    + #inst (user-supplied IVs, 1 per inst var per block)
    // Endog vars use lags t-2..t-(lag_max+1); predet vars use lags t-1..t-lag_max;
    // both get lag_max columns per var, so total column count is the same.
    real scalar k_exog, k_endog, k_predet, k_ep, k_inst, iv_width
    real scalar core_cols, inst_cols, inst_base
    external real scalar xdpt_collapse, xdpt_iv_collapse
    k_exog   = sum(u.var_type :== 2)
    k_endog  = sum(u.var_type :== 3)
    k_predet = sum(u.var_type :== 4)
    k_ep     = k_endog + k_predet
    k_inst = cols(u.X_inst)
    // v0.7.0 (C1): user IVs moved OUT of the per-block core into a tail
    // region, so iv(..., collapse) can collapse ONLY the user-IV block.
    // GMM estimates are invariant to this column permutation.
    iv_width = 1                     // constant
    if (!flag_static) iv_width = iv_width + lag_max   // lag y
    iv_width = iv_width + k_exog                      // Δx per exog
    iv_width = iv_width + lag_max * k_ep              // lags per endog/predet

    n_blocks = t_max_global - t_min_global - 1  // blocks for t ∈ [t_min+2, t_max]
    if (n_blocks < 1) n_blocks = 1
    block_K = iv_width
    // Collapsed: single shared block across all t; else block-diagonal by t
    if (xdpt_collapse) core_cols = block_K
    else               core_cols = n_blocks * block_K
    if (k_inst > 0)    inst_cols = (xdpt_iv_collapse ? k_inst : n_blocks * k_inst)
    else               inst_cols = 0
    n_iv_cols = core_cols + inst_cols

    Z_list = J(rows(times_list), n_iv_cols, 0)

    real scalar i, col_off, lag_idx
    for (i = 1; i <= rows(times_list); i++) {
        t = times_list[i]
        b = t - (t_min_global + 2) + 1
        if (b < 1 | b > n_blocks) continue
        if (xdpt_collapse) base_col = 0
        else               base_col = (b - 1) * block_K

        // Col 1: constant
        Z_list[i, base_col + 1] = 1
        col_off = 1

        // Lagged y (if dynamic): y_{t-2}, y_{t-3}, ...
        // User maxlag(lo hi) filters: include only lags with lo ≤ lag ≤ hi
        external real scalar xdpt_lag_lo, xdpt_lag_hi
        if (!flag_static) {
            for (lag_idx = 2; lag_idx <= lag_max + 1; lag_idx++) {
                if (lag_idx < xdpt_lag_lo | lag_idx > xdpt_lag_hi) continue
                real scalar pos
                pos = xdpt2_find_t(u, t - lag_idx)
                if (pos > 0) {
                    if (u.y[pos] < .) {
                        Z_list[i, base_col + col_off + lag_idx - 1] = u.y[pos]
                    }
                }
            }
            col_off = col_off + lag_max
        }

        // Exog x: Δx at period t (1 IV per exog var)
        real scalar vt, vi, pos_t, pos_tm1
        pos_t = xdpt2_find_t(u, t)
        pos_tm1 = xdpt2_find_t(u, t - 1)
        vi = 0
        for (vt = 1; vt <= cols(u.X); vt++) {
            if (u.var_type[vt] == 2) {
                vi = vi + 1
                if (pos_t > 0 & pos_tm1 > 0) {
                    if (u.X[pos_t, vt] < . & u.X[pos_tm1, vt] < .) {
                        Z_list[i, base_col + col_off + vi] = u.X[pos_t, vt] - u.X[pos_tm1, vt]
                    }
                }
            }
        }
        col_off = col_off + k_exog

        // Endog / predetermined regressors: lagged levels as instruments in Δ/FOD.
        //   Endog  (var_type==3): lags t-2, t-3, ..., t-(lag_max+1)
        //     — x_{t-1} is invalid because it can correlate with Δε_t
        //   Predet (var_type==4): lags t-1, t-2, ..., t-lag_max
        //     — weakly exogenous; x_{t-1} is valid (Blundell-Bond convention)
        // Each variable receives lag_max consecutive columns in the IV block,
        // iterating over the combined list in the same order as u.X.
        vi = 0
        for (vt = 1; vt <= cols(u.X); vt++) {
            if (u.var_type[vt] == 3 | u.var_type[vt] == 4) {
                real scalar lag_start, lag_stop, col_shift
                if (u.var_type[vt] == 3) {
                    lag_start = 2
                    lag_stop  = lag_max + 1
                    col_shift = 1    // column offset = lag_idx - 1
                }
                else {
                    lag_start = 1
                    lag_stop  = lag_max
                    col_shift = 0    // column offset = lag_idx
                }
                for (lag_idx = lag_start; lag_idx <= lag_stop; lag_idx++) {
                    if (lag_idx < xdpt_lag_lo | lag_idx > xdpt_lag_hi) continue
                    pos = xdpt2_find_t(u, t - lag_idx)
                    if (pos > 0) {
                        if (u.X[pos, vt] < .) {
                            Z_list[i, base_col + col_off + vi*lag_max + lag_idx - col_shift] = u.X[pos, vt]
                        }
                    }
                }
                vi = vi + 1
            }
        }
        col_off = col_off + lag_max * k_ep

        // User-supplied instruments (inst): value at time t, one IV per inst
        // var, in the tail region (v0.7.0: collapsible independently of the
        // GMM-style core via iv(..., collapse)).
        if (k_inst > 0 & pos_t > 0) {
            real scalar ii
            inst_base = core_cols + (xdpt_iv_collapse ? 0 : (b - 1) * k_inst)
            for (ii = 1; ii <= k_inst; ii++) {
                if (u.X_inst[pos_t, ii] < .) {
                    Z_list[i, inst_base + ii] = u.X_inst[pos_t, ii]
                }
            }
        }
    }

    // v0.7.0 (B4): drop rows whose instrument row is entirely zero — parity
    // with the level-equation BUG 4a fix. Such rows contribute null moments
    // but their residuals pollute the wild-bootstrap pool and AR tests.
    // The filter depends only on Z, which is γ-invariant, so per-γ row counts
    // stay matched across the bootstrap caches.
    if (rows(times_list) > 0) {
        real colvector _keep
        _keep = selectindex(rowsum(abs(Z_list)) :> 1e-12)
        if (length(_keep) == 0) {
            dy_list    = J(0, 1, 0)
            dW_list    = J(0, k_W_cols, 0)
            Z_list     = J(0, n_iv_cols, 0)
            times_list = J(0, 1, 0)
        }
        else if (length(_keep) < rows(times_list)) {
            dy_list    = dy_list[_keep]
            dW_list    = dW_list[_keep, .]
            Z_list     = Z_list[_keep, .]
            times_list = times_list[_keep]
        }
    }

    dy_out = dy_list
    dW_out = dW_list
    Z_out = Z_list
    times_out = times_list
}

// Helper: stack (dY, dW, Z, times, unit_id) across all units at given γ
// Helper: build LEVEL equation for one unit (for System GMM).
// y_it = x_it'β + (1, x_it')δ·r_it + η_i + ε_it
// IVs (Blundell-Bond 1998): lagged differences
//   - For L.y (endog): Δy_{i,t-1}
//   - For exog x_k: Δx_{k,i,t}  (exog → contemporaneous diff valid)
//   - For endog x_k: Δx_{k,i,t-1}
// Block-diagonal across t: 1 IV per (var-type, time block).
void xdpt2_level_unit(struct xdpt2_unit scalar u,
                       real scalar gamma, real scalar flag_static,
                       real scalar flag_kink,
                       real scalar t_min_global, real scalar t_max_global,
                       real matrix y_out, real matrix W_out,
                       real matrix Z_out, real colvector times_out)
{
    real scalar n, K, j, t, b, base_col, n_blocks, iv_width, k_W_cols
    real scalar vi, vt, pos_t, pos_tm1, pos_tm2
    real scalar iv_per_t
    real scalar t_min_valid
    real colvector r, kink_var
    real matrix W_lvl, Z_list
    real colvector y_list, times_list
    real matrix W_list

    n = rows(u.y)
    K = cols(u.X)

    r = (u.q :> gamma)
    if (flag_kink) {
        kink_var = (u.q :- gamma) :* r
        W_lvl = u.X, kink_var
        k_W_cols = K + 1
    }
    else {
        W_lvl = u.X, r, u.X :* r
        k_W_cols = 2*K + 1
    }

    // Per-block IV count for level equation:
    //   For L.y (dynamic): lagged differences Δy_{t-l} for l in [lev_lo, lev_hi]
    //   For exog x:   Δx_{t-l+1} for l in [lev_lo, lev_hi]
    //   For predet x: Δx_{t-l+1} for l in [lev_lo, lev_hi]   (weakly exog ⇒ Δx_t valid)
    //   For endog x:  Δx_{t-l}   for l in [lev_lo, lev_hi]
    //   For user inst: inst_t (single, no lag sweep — inst assumed exog in levels)
    external real scalar xdpt_lev_lo, xdpt_lev_hi
    real scalar n_lev_lags, k_inst_lev
    n_lev_lags = xdpt_lev_hi - xdpt_lev_lo + 1
    if (n_lev_lags < 1) n_lev_lags = 1
    k_inst_lev = cols(u.X_inst)
    // v0.7.0 (C1): core width EXCLUDES user IVs — they live in a tail region
    // (collapsible independently). The level constant is a separate shared
    // final column (see below).
    iv_per_t = 0
    if (!flag_static) iv_per_t = iv_per_t + n_lev_lags
    iv_per_t = iv_per_t + sum(u.var_type :== 2) * n_lev_lags
    iv_per_t = iv_per_t + sum(u.var_type :== 3) * n_lev_lags
    iv_per_t = iv_per_t + sum(u.var_type :== 4) * n_lev_lags

    // Valid t for level equation: t where lagged differences are constructible
    //   Need t-1 and t-2 in u.t (for Δy_{t-1} = y_{t-1} - y_{t-2})
    external real scalar xdpt_collapse
    t_min_valid = t_min_global + 2
    n_blocks = t_max_global - t_min_valid + 1
    if (n_blocks < 1) n_blocks = 1

    // v0.7.0 (A3): the level equation carries a constant — as a regressor
    // (absorbing E[η]) and as the moment E[(η+ε)] = 0 — matching xtabond2.
    // Without it, the level moments E[Δz·(η+ε)] = 0 require E[Δz] = 0, which
    // fails for trending instruments even under Blundell-Bond mean
    // stationarity, contaminating Hansen J and biasing level-loaded
    // coefficients. W gains one final column of ones; Z gains one shared
    // final constant column.
    y_list = J(0, 1, 0)
    W_list = J(0, k_W_cols + 1, 0)
    times_list = J(0, 1, 0)
    real scalar n_cols_Z_lev, core_cols_lev, inst_cols_lev, inst_base_lev
    external real scalar xdpt_iv_collapse
    if (xdpt_collapse) core_cols_lev = iv_per_t
    else               core_cols_lev = n_blocks * iv_per_t
    if (k_inst_lev > 0) inst_cols_lev = (xdpt_iv_collapse ? k_inst_lev : n_blocks * k_inst_lev)
    else                inst_cols_lev = 0
    n_cols_Z_lev = core_cols_lev + inst_cols_lev + 1   // +1 = level constant
    Z_list = J(0, n_cols_Z_lev, 0)

    for (j = 1; j <= n; j++) {
        t = u.t[j]
        if (t < t_min_valid) continue
        b = t - t_min_valid + 1
        if (b < 1 | b > n_blocks) continue

        // Need t and nonmissing level equation variables
        pos_t   = xdpt2_find_t(u, t)
        if (pos_t == 0) continue
        if (u.y[pos_t] >= . | u.q[pos_t] >= . | xdpt2_hasmiss(W_lvl[pos_t, .])) continue

        // BUG 4a FIX: build IV row FIRST, add y/W/Z only if IV row is informative.
        // Previously, y/W were appended unconditionally while Z could be all-zero
        // for observations near the boundary (t-lev_lag not available). This
        // polluted the GMM sum with zero-moment rows.

        // Build IV row: block-diag or collapsed (shared cols across t)
        real rowvector z_row
        z_row = J(1, n_cols_Z_lev, 0)
        if (xdpt_collapse) base_col = 0
        else               base_col = (b - 1) * iv_per_t
        real scalar col_off, lev_lag, pos_a, pos_b
        col_off = 0

        // L.y IVs: Δy_{t-l} = y_{t-l} - y_{t-l-1} for l in [lev_lo, lev_hi]
        if (!flag_static) {
            for (lev_lag = xdpt_lev_lo; lev_lag <= xdpt_lev_hi; lev_lag++) {
                pos_a = xdpt2_find_t(u, t - lev_lag)
                pos_b = xdpt2_find_t(u, t - lev_lag - 1)
                if (pos_a > 0 & pos_b > 0) {
                    if (u.y[pos_a] < . & u.y[pos_b] < .) {
                        z_row[base_col + col_off + (lev_lag - xdpt_lev_lo + 1)] ///
                            = u.y[pos_a] - u.y[pos_b]
                    }
                }
            }
            col_off = col_off + n_lev_lags
        }

        // Exog IVs: Δx_{t-l+1} = x_{t-l+1} - x_{t-l} for l in [lev_lo, lev_hi]
        vi = 0
        for (vt = 1; vt <= cols(u.X); vt++) {
            if (u.var_type[vt] == 2) {
                for (lev_lag = xdpt_lev_lo; lev_lag <= xdpt_lev_hi; lev_lag++) {
                    pos_a = xdpt2_find_t(u, t - lev_lag + 1)
                    pos_b = xdpt2_find_t(u, t - lev_lag)
                    if (pos_a > 0 & pos_b > 0) {
                        if (u.X[pos_a, vt] < . & u.X[pos_b, vt] < .) {
                            z_row[base_col + col_off + vi*n_lev_lags + (lev_lag - xdpt_lev_lo + 1)] ///
                                = u.X[pos_a, vt] - u.X[pos_b, vt]
                        }
                    }
                }
                vi = vi + 1
            }
        }
        col_off = col_off + sum(u.var_type :== 2) * n_lev_lags

        // Endog IVs: Δx_{t-l} = x_{t-l} - x_{t-l-1} for l in [lev_lo, lev_hi]
        vi = 0
        for (vt = 1; vt <= cols(u.X); vt++) {
            if (u.var_type[vt] == 3) {
                for (lev_lag = xdpt_lev_lo; lev_lag <= xdpt_lev_hi; lev_lag++) {
                    pos_a = xdpt2_find_t(u, t - lev_lag)
                    pos_b = xdpt2_find_t(u, t - lev_lag - 1)
                    if (pos_a > 0 & pos_b > 0) {
                        if (u.X[pos_a, vt] < . & u.X[pos_b, vt] < .) {
                            z_row[base_col + col_off + vi*n_lev_lags + (lev_lag - xdpt_lev_lo + 1)] ///
                                = u.X[pos_a, vt] - u.X[pos_b, vt]
                        }
                    }
                }
                vi = vi + 1
            }
        }
        col_off = col_off + sum(u.var_type :== 3) * n_lev_lags

        // Predet IVs: Δx_{t-l+1} = x_{t-l+1} - x_{t-l}, same formula as exog
        //   (predetermined regressors are uncorrelated with current ε, so
        //    Δx_t can serve as an instrument in the level equation)
        vi = 0
        for (vt = 1; vt <= cols(u.X); vt++) {
            if (u.var_type[vt] == 4) {
                for (lev_lag = xdpt_lev_lo; lev_lag <= xdpt_lev_hi; lev_lag++) {
                    pos_a = xdpt2_find_t(u, t - lev_lag + 1)
                    pos_b = xdpt2_find_t(u, t - lev_lag)
                    if (pos_a > 0 & pos_b > 0) {
                        if (u.X[pos_a, vt] < . & u.X[pos_b, vt] < .) {
                            z_row[base_col + col_off + vi*n_lev_lags + (lev_lag - xdpt_lev_lo + 1)] ///
                                = u.X[pos_a, vt] - u.X[pos_b, vt]
                        }
                    }
                }
                vi = vi + 1
            }
        }
        col_off = col_off + sum(u.var_type :== 4) * n_lev_lags

        // User-supplied instruments (inst): value at time t, one IV per inst
        // var, in the tail region (v0.7.0) — valid under exogeneity of user IVs.
        if (k_inst_lev > 0) {
            real scalar ii_lev
            inst_base_lev = core_cols_lev + (xdpt_iv_collapse ? 0 : (b - 1) * k_inst_lev)
            for (ii_lev = 1; ii_lev <= k_inst_lev; ii_lev++) {
                if (u.X_inst[pos_t, ii_lev] < .) {
                    z_row[inst_base_lev + ii_lev] = u.X_inst[pos_t, ii_lev]
                }
            }
        }

        // BUG 4a FIX: only append observation if IV row has at least one
        // non-zero entry. Otherwise the moment z_row·(y-x'θ) = 0 trivially
        // and adds a useless row that can corrupt the variance estimate.
        if (sum(abs(z_row)) < 1e-12) continue
        // v0.7.0 (A3): constant set AFTER the BUG 4a filter, so the keep/drop
        // sample is identical to v0.6.1; the row then also carries the level
        // constant moment.
        z_row[n_cols_Z_lev] = 1

        y_list    = y_list \ u.y[pos_t]
        W_list    = W_list \ (W_lvl[pos_t, .], 1)   // level-eq constant regressor
        times_list = times_list \ t
        Z_list = Z_list \ z_row
    }

    y_out = y_list
    W_out = W_list
    Z_out = Z_list
    times_out = times_list
}

void xdpt2_stack_at_gamma(struct xdpt2_unit rowvector units,
                           real scalar gamma, string scalar method,
                           real scalar flag_static, real scalar flag_kink,
                           real scalar t_min, real scalar t_max,
                           real matrix dY_out, real matrix dW_out,
                           real matrix Z_out, real colvector times_out,
                           real colvector unit_id_out)
{
    real scalar i, K, n_units, n_rows_i, k_W_cols
    real colvector dy_i, time_i
    real matrix dW_i, Z_i

    n_units = length(units)
    K = cols(units[1].X)
    k_W_cols = (flag_kink ? K + 1 : 2*K + 1)

    // === FOD/FD equation rows ===
    dY_out = J(0, 1, 0)
    dW_out = J(0, k_W_cols, 0)
    Z_out = J(0, 0, 0)
    times_out = J(0, 1, 0)
    unit_id_out = J(0, 1, 0)

    // For system, use FOD under the hood for transformed equation
    string scalar trans_method
    trans_method = (method == "system" ? "fod" : method)

    for (i = 1; i <= n_units; i++) {
        xdpt2_transform_unit(units[i], gamma, trans_method,
                              flag_static, flag_kink,
                              t_min, t_max,
                              dy_i, dW_i, Z_i, time_i)
        n_rows_i = rows(dy_i)
        if (n_rows_i == 0) continue
        dY_out = dY_out \ dy_i
        dW_out = dW_out \ dW_i
        if (cols(Z_out) == 0) Z_out = J(0, cols(Z_i), 0)
        Z_out = Z_out \ Z_i
        times_out = times_out \ time_i
        unit_id_out = unit_id_out \ J(n_rows_i, 1, i)
    }

    // Drop all-zero columns of transformed Z
    if (rows(Z_out) > 0) {
        real rowvector col_sum, keep_idx
        col_sum = colsum(abs(Z_out))
        keep_idx = selectindex(col_sum :> 1e-12)
        if (length(keep_idx) > 0 & length(keep_idx) < cols(Z_out)) {
            Z_out = Z_out[., keep_idx]
        }
    }

    if (method != "system") return

    // === System GMM: also add LEVEL equation rows ===
    real colvector y_l, time_l
    real matrix W_l, Z_l
    real matrix Y_lev_all, W_lev_all, Z_lev_all
    real colvector times_lev_all, uid_lev_all

    Y_lev_all = J(0, 1, 0)
    // v0.7.0.1 hotfix: level W carries the constant column (A3), so the
    // accumulator must be k_W_cols + 1 wide — mismatch here caused a 3200
    // conformability error for method(system).
    W_lev_all = J(0, k_W_cols + 1, 0)
    Z_lev_all = J(0, 0, 0)
    times_lev_all = J(0, 1, 0)
    uid_lev_all = J(0, 1, 0)

    for (i = 1; i <= n_units; i++) {
        xdpt2_level_unit(units[i], gamma, flag_static, flag_kink,
                          t_min, t_max,
                          y_l, W_l, Z_l, time_l)
        n_rows_i = rows(y_l)
        if (n_rows_i == 0) continue
        Y_lev_all = Y_lev_all \ y_l
        W_lev_all = W_lev_all \ W_l
        if (cols(Z_lev_all) == 0) Z_lev_all = J(0, cols(Z_l), 0)
        Z_lev_all = Z_lev_all \ Z_l
        times_lev_all = times_lev_all \ time_l
        uid_lev_all = uid_lev_all \ J(n_rows_i, 1, i)
    }

    // Drop all-zero columns of level Z
    if (rows(Z_lev_all) > 0) {
        real rowvector col_sum_l, keep_idx_l
        col_sum_l = colsum(abs(Z_lev_all))
        keep_idx_l = selectindex(col_sum_l :> 1e-12)
        if (length(keep_idx_l) > 0 & length(keep_idx_l) < cols(Z_lev_all)) {
            Z_lev_all = Z_lev_all[., keep_idx_l]
        }
    }

    if (rows(Y_lev_all) == 0) return

    // v0.7.0 (A3): level-equation constant column for the stacked W — zero in
    // transformed rows (FD/FOD of a constant is zero), one in level rows
    // (already present in W_lev_all). Level-row availability is γ-invariant,
    // so parameter dimensions are consistent across the γ grid.
    dW_out = dW_out, J(rows(dY_out), 1, 0)

    // === Stack FOD + level into combined system ===
    // Z_combined: block-diagonal. FOD moments on top-left, level on bottom-right.
    real scalar n_fod, n_lev, k_fod, k_lev
    n_fod = rows(dY_out)
    n_lev = rows(Y_lev_all)
    k_fod = cols(Z_out)
    k_lev = cols(Z_lev_all)

    real matrix Z_comb
    Z_comb = J(n_fod + n_lev, k_fod + k_lev, 0)
    if (n_fod > 0 & k_fod > 0) Z_comb[|1, 1 \ n_fod, k_fod|] = Z_out
    if (n_lev > 0 & k_lev > 0) Z_comb[|n_fod+1, k_fod+1 \ n_fod+n_lev, k_fod+k_lev|] = Z_lev_all

    dY_out = dY_out \ Y_lev_all
    dW_out = dW_out \ W_lev_all
    Z_out = Z_comb
    times_out = times_out \ times_lev_all
    unit_id_out = unit_id_out \ uid_lev_all
}

// Helper: build MA(1)-aware first-stage weight matrix for FD GMM.
// Based on xthenreg's GMM_W_n_con (Seo-Shin 2016).
// Under iid ε with σ²=1: Var(Δε_t) = 2, Cov(Δε_t, Δε_{t-1}) = -1.
// Weight W_n = [Var(g)]^{-1} ∝ (2·W2 - W1 - W1')^{-1}
// where W2 has diagonal blocks (Σ_t Z_t' Z_t / N) and W1 has off-diagonal
// blocks (Σ_t Z_{t-1}' Z_t / N) for consecutive time pairs.
real matrix xdpt2_build_W_ma1(real matrix Z, real colvector times,
                                real colvector unit_id)
{
    real scalar k_iv, n_u, i, j, n_rows
    real matrix W2, W1, W_mat, ma1_struct
    real colvector rows_i, times_i
    real matrix Z_i

    k_iv = cols(Z)
    n_u = max(unit_id)
    n_rows = rows(Z)

    // W2: diagonal blocks (sum across all rows with block structure preserved
    // by Z's block-diagonal IV layout; thanks to that, Z'Z already has proper
    // block-diagonal form with nonzero diag blocks)
    W2 = Z' * Z / n_u

    // W1: within-unit consecutive-time cross products
    W1 = J(k_iv, k_iv, 0)
    for (i = 1; i <= n_u; i++) {
        rows_i = selectindex(unit_id :== i)
        if (rows(rows_i) < 2) continue
        times_i = times[rows_i]
        Z_i = Z[rows_i, .]
        for (j = 2; j <= rows(rows_i); j++) {
            if (times_i[j] - times_i[j-1] == 1) {
                // Consecutive pair: add z_{t-1}' z_t
                W1 = W1 + Z_i[j-1, .]' * Z_i[j, .]
            }
        }
    }
    W1 = W1 / n_u

    // MA(1) structure: 2·W2 - W1 - W1'
    ma1_struct = 2 * W2 - W1 - W1'
    if (cond(ma1_struct) > 1e12) {
        // v0.7.0 (D6): fallback chain. invsym() on a singular W2 would
        // silently zero out rows/columns; use the identity weight (valid,
        // merely inefficient) when even Z'Z is ill-conditioned.
        if (cond(W2) <= 1e12) return(invsym(W2))
        return(I(k_iv))
    }
    W_mat = invsym(ma1_struct)
    return(W_mat)
}

// Helper: solve 2-step GMM with cluster-robust Ω (unit-level clustering).
// Uses MA(1)-aware first-stage weight when method=="fd" (Seo-Shin 2016).
// Returns ok=0 if numerical failure.
void xdpt2_solve_gmm(real colvector Y, real matrix W, real matrix Z,
                      real colvector unit_id, real colvector times,
                      string scalar method,
                      real scalar ok, real colvector theta,
                      real scalar obj, real matrix V)
{
    real scalar n_rows, n_units, i, u
    real matrix ZW, ZZ, ZZ_inv, W_first, A1, Omega, Omega_inv, A2, Ze
    real matrix g_per_unit
    real colvector ZY, theta1, r1, g_bar

    ok = 0
    if (rows(Y) < 20) return
    n_rows = rows(Y)

    ZW = Z' * W / n_rows
    ZY = Z' * Y / n_rows
    ZZ = Z' * Z / n_rows

    if (cond(ZZ) > 1e12) return
    ZZ_inv = invsym(ZZ)

    // First-stage weight: MA(1)-aware for FD, ZZ_inv for FOD/system
    if (method == "fd") {
        W_first = xdpt2_build_W_ma1(Z, times, unit_id)
    }
    else {
        W_first = ZZ_inv
    }

    A1 = ZW' * W_first * ZW
    if (cond(A1) > 1e12) return
    theta1 = invsym(A1) * ZW' * W_first * ZY
    r1 = Y - W * theta1

    // Cluster-robust Ω for 2nd stage: Ω = (1/n_rows) Σ_i (Σ_{t∈i} Z_it·r_it)(...)'
    Ze = Z :* r1
    n_units = max(unit_id)
    g_per_unit = J(n_units, cols(Z), 0)
    for (i = 1; i <= n_rows; i++) {
        u = unit_id[i]
        g_per_unit[u, .] = g_per_unit[u, .] + Ze[i, .]
    }
    Omega = g_per_unit' * g_per_unit / n_rows

    if (cond(Omega) > 1e12) {
        theta = theta1
        g_bar = Z' * r1 / n_rows
        obj = n_rows * (g_bar' * W_first * g_bar)
        V = invsym(A1) / n_rows
        ok = 1
        return
    }

    Omega_inv = invsym(Omega)
    A2 = ZW' * Omega_inv * ZW
    if (cond(A2) > 1e12) return
    theta = invsym(A2) * ZW' * Omega_inv * ZY
    real colvector r2
    r2 = Y - W * theta
    g_bar = Z' * r2 / n_rows
    obj = n_rows * (g_bar' * Omega_inv * g_bar)
    V = invsym(A2) / n_rows
    ok = 1
}

// Helper: 1-step GMM with fixed weight matrix. Returns obj and theta only.
void xdpt2_solve_gmm_1step(real colvector Y, real matrix W_reg, real matrix Z,
                            real matrix W_wt,
                            real scalar ok, real colvector theta,
                            real scalar obj, real matrix V)
{
    real scalar n_rows
    real matrix ZW, A
    real colvector ZY, r, g_bar

    ok = 0
    if (rows(Y) < 20) return
    n_rows = rows(Y)

    ZW = Z' * W_reg / n_rows
    ZY = Z' * Y / n_rows

    A = ZW' * W_wt * ZW
    if (cond(A) > 1e12) return
    theta = invsym(A) * ZW' * W_wt * ZY
    r = Y - W_reg * theta
    g_bar = Z' * r / n_rows
    obj = n_rows * (g_bar' * W_wt * g_bar)
    V = invsym(A) / n_rows
    ok = 1
}

// Helper: compute cluster-robust Ω from residuals (unit-level clustering)
real matrix xdpt2_build_cluster_omega(real matrix Z, real colvector r,
                                        real colvector unit_id)
{
    real scalar n_rows, n_units, i, u
    real matrix Ze, g_per_unit, Omega

    n_rows = rows(Z)
    n_units = max(unit_id)
    Ze = Z :* r
    g_per_unit = J(n_units, cols(Z), 0)
    for (i = 1; i <= n_rows; i++) {
        u = unit_id[i]
        g_per_unit[u, .] = g_per_unit[u, .] + Ze[i, .]
    }
    Omega = g_per_unit' * g_per_unit / n_rows
    return(Omega)
}

// Per-gamma cache: avoid repeated xdpt2_stack_at_gamma calls.
// Used by both main grid search and bootstrap loops.
struct xdpt2_gamma_cache {
    real scalar    ok
    real scalar    gamma
    real colvector dY
    real matrix    dW
    real matrix    Z
    real colvector times
    real colvector uid
    real matrix    W_first  // first-stage GMM weight (MA(1) for FD, ZZ_inv else)
    // NEW: precomputed for fast 1-step bootstrap GMM (Gong-Seo 2026 Alg. 1)
    //   C_g = invsym(ZW' W_first ZW) * ZW' * W_first    // (k_W × n_iv)
    //   Given Y_boot, θ̂ = C_g · (Z'Y_boot/n); single matmul, no cluster-Ω loop.
    real matrix    C_g
    real scalar    n_rows     // cached rows(dY)
    real scalar    fast_ok    // 1 if C_g valid (non-singular A)
}

struct xdpt2_gamma_cache rowvector xdpt2_build_gamma_cache(
    struct xdpt2_unit rowvector units,
    real colvector gamma_grid,
    string scalar method,
    real scalar flag_static,
    real scalar flag_kink,
    real scalar t_min,
    real scalar t_max)
{
    real scalar g, G, n_rows
    struct xdpt2_gamma_cache rowvector cache
    real colvector dY_cur, times_cur, uid_cur
    real matrix dW_cur, Z_cur, ZZ, ZZ_inv, W_first
    real matrix ZW_cur, A_cur

    G = rows(gamma_grid)
    cache = xdpt2_gamma_cache(1, G)

    for (g = 1; g <= G; g++) {
        cache[g].ok = 0
        cache[g].fast_ok = 0
        cache[g].gamma = gamma_grid[g]

        xdpt2_stack_at_gamma(units, gamma_grid[g], method,
                              flag_static, flag_kink, t_min, t_max,
                              dY_cur, dW_cur, Z_cur, times_cur, uid_cur)

        if (rows(dY_cur) == 0) continue
        n_rows = rows(dY_cur)
        ZZ = Z_cur' * Z_cur / n_rows
        if (cond(ZZ) > 1e12) continue
        ZZ_inv = invsym(ZZ)
        if (method == "fd") {
            W_first = xdpt2_build_W_ma1(Z_cur, times_cur, uid_cur)
        }
        else {
            W_first = ZZ_inv
        }

        cache[g].dY      = dY_cur
        cache[g].dW      = dW_cur
        cache[g].Z       = Z_cur
        cache[g].times   = times_cur
        cache[g].uid     = uid_cur
        cache[g].W_first = W_first
        cache[g].n_rows  = n_rows
        cache[g].ok      = 1

        // Precompute C_g for fast bootstrap (1-step GMM with fixed W_first)
        //   θ(Y) = invsym(ZW' W_first ZW) · ZW' · W_first · (Z'Y/n)
        //        = C_g · (Z'Y/n)
        ZW_cur = Z_cur' * dW_cur / n_rows
        A_cur = ZW_cur' * W_first * ZW_cur
        if (cond(A_cur) <= 1e12) {
            cache[g].C_g = invsym(A_cur) * ZW_cur' * W_first
            cache[g].fast_ok = 1
        }
    }
    return(cache)
}

// Fast bootstrap 1-step GMM: uses precomputed C_g from cache entry.
// O(n_rows·n_iv + n_iv²) per call vs O(n_rows·n_iv² + n_iv³ + k_W³) for
// xdpt2_solve_gmm. Drops cluster-Ω loop (bootstrap doesn't need 2-step).
// Matches Gong-Seo 2026 Algorithm 1: bootstrap uses same W_first as sample.
void xdpt2_fast_gmm_boot(real colvector Y_boot,
                          struct xdpt2_gamma_cache scalar gc,
                          real scalar ok, real colvector theta,
                          real scalar obj)
{
    real colvector ZY, r, g
    ok = 0
    if (gc.ok == 0 | gc.fast_ok == 0) return
    if (rows(Y_boot) != gc.n_rows) return

    ZY = gc.Z' * Y_boot / gc.n_rows
    theta = gc.C_g * ZY
    r = Y_boot - gc.dW * theta
    g = gc.Z' * r / gc.n_rows
    obj = gc.n_rows * (g' * gc.W_first * g)
    ok = 1
}

// Vectorized Mammen 2-point draws for n_u units.
// P[η = -φ]   = (√5+1)/(2√5)   where φ = (√5-1)/2
// P[η = 1/φ]  = (√5-1)/(2√5)   where 1/φ = (√5+1)/2
real colvector xdpt2_mammen_draw(real scalar n_u)
{
    real scalar phi_mam, prob_mam
    real colvector d
    phi_mam = (sqrt(5) - 1) / 2
    prob_mam = (sqrt(5) + 1) / (2 * sqrt(5))
    d = (runiform(n_u, 1) :< prob_mam)
    return(-phi_mam :* d :+ (1/phi_mam) :* (1 :- d))
}

// Quantile helper that avoids dependency on moremata's mm_quantile().
// Uses Hyndman-Fan type 7 interpolation and ignores missing values.
real scalar xdpt2_quantile(real colvector x, real scalar p)
{
    real colvector xs
    real scalar n, h, j, g

    xs = select(x, x :< .)
    n = rows(xs)
    if (n == 0) return(.)
    xs = sort(xs, 1)
    if (p <= 0) return(xs[1])
    if (p >= 1) return(xs[n])

    h = 1 + (n - 1) * p
    j = floor(h)
    g = h - j
    if (j >= n) return(xs[n])
    return((1 - g) * xs[j] + g * xs[j + 1])
}

// 2-stage grid search (xthenreg-style):
//   Stage 1: grid search with W_first (MA(1) for FD, ZZ_inv for FOD/system)
//   Stage 2: compute W_n_2 from Stage-1 residuals, grid search again with W_n_2 fixed
// v0.7.0 (A4): the 2-stage fixed-weight path now applies to ALL methods.
// Previously FOD/system called 2-step solve_gmm per grid point, re-estimating
// Ω(γ) at every γ — objective values were then not comparable across the grid
// and the argmin could be distorted. W_first (MA(1) for FD; Z'Z-inverse for
// FOD/system) is γ-invariant because Z does not depend on γ, so Stage 1 is a
// proper fixed-weight search; Stage 2 fixes the cluster Ω from the Stage-1
// optimum across the whole grid, exactly as xthenreg does.
// v0.7.0 (D1): the per-γ cache is built once by the caller and passed in.
void xdpt2_grid_search(struct xdpt2_unit rowvector units,
                        real colvector gamma_grid,
                        struct xdpt2_gamma_cache rowvector cache,
                        string scalar method, real scalar flag_static,
                        real scalar flag_kink, real scalar t_min, real scalar t_max,
                        real scalar best_gamma, real scalar best_obj,
                        real colvector best_theta, real matrix best_V,
                        real matrix best_A)
{
    real scalar gl, ok, obj_cur, best_obj_1, best_gamma_1
    real scalar n_rows, k_W
    real matrix dY_cur, dW_cur, Z_cur, V_cur, W_first, ZZ_inv, ZZ
    real matrix Omega, W_n_2, best_V_1
    real colvector times_cur, theta_cur, uid_cur, best_theta_1, r_1
    real matrix dY_1, dW_1, Z_1
    real colvector times_1, uid_1

    // Initialize outputs to safe values.
    // v0.7.0 (A3): parameter count read off the first valid cache entry — it
    // covers the system level-constant column; formula fallback if none ok.
    best_gamma = .
    best_obj = .
    k_W = .
    real scalar _g0
    for (_g0 = 1; _g0 <= cols(cache); _g0++) {
        if (cache[_g0].ok) {
            k_W = cols(cache[_g0].dW)
            break
        }
    }
    if (k_W == .) k_W = (flag_kink ? cols(units[1].X) + 1 : 2 * cols(units[1].X) + 1)
    best_theta = J(k_W, 1, 0)
    best_V = J(k_W, k_W, 0)
    // v0.7.2: best_A = moment weight actually paired with the reported θ̂/V̂,
    // exported for the full Arellano-Bond AR test (its Term 2 needs the
    // estimator's influence function (G'AG)^{-1}G'A).
    best_A = J(0, 0, 0)

    // ==== Unified 2-stage grid search for ALL methods (v0.7.0, A4) ====

    // ======== STAGE 1: grid search with cached W_first ========
    best_obj_1 = .
    best_gamma_1 = .
    best_theta_1 = J(k_W, 1, 0)
    best_V_1 = J(k_W, k_W, 0)

    for (gl = 1; gl <= rows(gamma_grid); gl++) {
        if (!cache[gl].ok) continue
        if (rows(cache[gl].dY) < 20) continue
        xdpt2_solve_gmm_1step(cache[gl].dY, cache[gl].dW, cache[gl].Z,
                                cache[gl].W_first,
                                ok, theta_cur, obj_cur, V_cur)
        if (!ok) continue
        if (obj_cur < best_obj_1) {
            best_obj_1 = obj_cur
            best_gamma_1 = gamma_grid[gl]
            best_theta_1 = theta_cur
            best_V_1 = V_cur
        }
    }

    if (best_gamma_1 == .) return  // Stage 1 failed entirely

    // ======== STAGE 2: compute W_n_2 from stage-1 residuals ========
    // Find cache index for best_gamma_1
    real scalar idx_1
    idx_1 = 0
    for (gl = 1; gl <= rows(gamma_grid); gl++) {
        if (gamma_grid[gl] == best_gamma_1) {
            idx_1 = gl
            gl = rows(gamma_grid) + 1
        }
    }
    if (idx_1 == 0 | !cache[idx_1].ok) {
        best_gamma = best_gamma_1
        best_obj = best_obj_1
        best_theta = best_theta_1
        best_V = best_V_1
        return
    }
    r_1 = cache[idx_1].dY - cache[idx_1].dW * best_theta_1
    Omega = xdpt2_build_cluster_omega(cache[idx_1].Z, r_1, cache[idx_1].uid)
    if (cond(Omega) > 1e12) {
        best_gamma = best_gamma_1
        best_obj = best_obj_1
        best_theta = best_theta_1
        best_V = best_V_1
        return
    }
    W_n_2 = invsym(Omega)

    // ======== STAGE 2 GRID: solve with W_n_2 fixed (cached) ========
    real scalar best_obj_2, best_gamma_2
    real colvector best_theta_2
    real matrix best_V_2
    best_obj_2 = .
    best_gamma_2 = .
    best_theta_2 = J(k_W, 1, 0)
    best_V_2 = J(k_W, k_W, 0)

    for (gl = 1; gl <= rows(gamma_grid); gl++) {
        if (!cache[gl].ok) continue
        if (rows(cache[gl].dY) < 20) continue
        if (cols(cache[gl].Z) != cols(W_n_2)) continue
        xdpt2_solve_gmm_1step(cache[gl].dY, cache[gl].dW, cache[gl].Z, W_n_2,
                                ok, theta_cur, obj_cur, V_cur)
        if (!ok) continue
        if (obj_cur < best_obj_2) {
            best_obj_2 = obj_cur
            best_gamma_2 = gamma_grid[gl]
            best_theta_2 = theta_cur
            best_V_2 = V_cur
        }
    }

    if (best_gamma_2 == .) {
        // Fallback to stage-1. BUG 8 FIX: recompute cluster-robust V at
        // best_theta_1 using W_n_2 = invsym(Omega) already computed above.
        // best_V_1 comes from xdpt2_solve_gmm_1step which returns naive
        // (A^-1)/n that is correct only when W_wt = Omega^-1; here W_wt
        // was W_first (MA(1) weight), so naive V is not cluster-robust.
        // With W_n_2 available, we can build the proper cluster-robust V:
        //   V = (ZW' · W_n_2 · ZW)^-1 / n  at best_theta_1
        // Falls back to best_V_1 only if A_1_cr is ill-conditioned.
        best_gamma = best_gamma_1
        best_obj = best_obj_1
        best_theta = best_theta_1
        real matrix ZW_1_cr, A_1_cr
        real scalar ok_v1
        ok_v1 = 0
        ZW_1_cr = cache[idx_1].Z' * cache[idx_1].dW / cache[idx_1].n_rows
        A_1_cr = ZW_1_cr' * W_n_2 * ZW_1_cr
        if (cond(A_1_cr) <= 1e12) {
            best_V = invsym(A_1_cr) / cache[idx_1].n_rows
            ok_v1 = 1
        }
        if (!ok_v1) best_V = best_V_1
        best_A = W_n_2
    }
    else {
        best_gamma = best_gamma_2
        best_obj = best_obj_2
        best_theta = best_theta_2
        // BUG 2 FIX: recompute V with cluster-robust Omega at best_gamma_2
        // instead of using 1-step V from xdpt2_solve_gmm_1step. This matches
        // FOD/system path which returns cluster-robust V via xdpt2_solve_gmm.
        real scalar idx_2, ok_v2
        real colvector r_2_final
        real matrix Omega_2, ZW_2, A_2_final, best_V_cr
        idx_2 = 0
        for (gl = 1; gl <= rows(gamma_grid); gl++) {
            if (gamma_grid[gl] == best_gamma_2) {
                idx_2 = gl
                gl = rows(gamma_grid) + 1
            }
        }
        ok_v2 = 0
        if (idx_2 > 0 & cache[idx_2].ok) {
            r_2_final = cache[idx_2].dY - cache[idx_2].dW * best_theta_2
            Omega_2 = xdpt2_build_cluster_omega(cache[idx_2].Z, r_2_final,
                                                 cache[idx_2].uid)
            if (cond(Omega_2) <= 1e12) {
                ZW_2 = cache[idx_2].Z' * cache[idx_2].dW / cache[idx_2].n_rows
                A_2_final = ZW_2' * invsym(Omega_2) * ZW_2
                if (cond(A_2_final) <= 1e12) {
                    best_V_cr = invsym(A_2_final) / cache[idx_2].n_rows
                    best_V = best_V_cr
                    ok_v2 = 1
                    // Weight paired with the reported two-step V (xtabond2
                    // convention: treat the converged Ω as the weight).
                    best_A = invsym(Omega_2)
                }
            }
        }
        if (!ok_v2) {
            // Fallback to 1-step V if cluster-robust computation fails
            best_V = best_V_2
            best_A = W_n_2
        }
    }
}

// Grid bootstrap CI (Gong-Seo 2026 Algorithm 1 + §4.1)
// Returns [gam_lo, gam_hi] confidence interval.
void xdpt2_grid_bootstrap(struct xdpt2_unit rowvector units,
                           struct xdpt2_gamma_cache rowvector gamma_cache,
                           real colvector gamma_grid,
                           real colvector gamma_ci_grid,
                           real scalar best_obj, real scalar best_gamma,
                           string scalar method, real scalar flag_static,
                           real scalar flag_kink,
                           real scalar t_min, real scalar t_max,
                           real scalar n_boot, real scalar alpha,
                           real scalar gam_lo, real scalar gam_hi,
                           real scalar ci_empty, real scalar ci_nseg)
{
    real scalar n_ci, l, b, ok_r, obj_r, D_sample, D_boot, crit, min_obj_b
    real scalar ok_b_r, obj_b_r, ok_b_u, obj_b_u, gb
    real matrix dY_r, dW_r, Z_r, V_r, V_dummy
    real colvector times_r, theta_r, resid_r, Y_boot, theta_b
    real colvector D_vec, accept, uid_r, uid_b
    real colvector eta_unit, eta
    real scalar n_u, i, u
    real matrix dY_b, dW_b, Z_b
    real colvector times_b, theta_b_r, theta_b_u
    // Declarations for 1-step sample D (Gong-Seo Alg. 1 consistency fix)
    real scalar obj_r_1s, best_obj_1s, ok_1s, gb_s, obj_u_1s
    real colvector theta_s_dummy
    theta_s_dummy = J(0, 1, 0)

    n_ci = rows(gamma_ci_grid)
    accept = J(n_ci, 1, 0)
    n_u = length(units)

    // === Per-gamma caches: the estimation-grid cache is passed in (built
    // once in xtdpthresh_run, v0.7.0 D1); only the CI-grid cache is built here ===
    struct xdpt2_gamma_cache rowvector gamma_ci_cache
    gamma_ci_cache = xdpt2_build_gamma_cache(units, gamma_ci_grid, method,
                                              flag_static, flag_kink, t_min, t_max)

    external real scalar xdpt_verbose
    if (xdpt_verbose) printf("  Grid bootstrap (B=%g, gridci=%g, unit-level Mammen; cached)...\n", n_boot, n_ci)
    else {
        printf("  Grid bootstrap CI  (. per γ point, %g total)\n", n_ci)
        printf("  ")
        displayflush()
    }

    for (l = 1; l <= n_ci; l++) {
        if (!xdpt_verbose) {
            printf(".")
            displayflush()
        }
        // Sample: restricted at γ_ℓ — pull from cache
        if (!gamma_ci_cache[l].ok) {
            accept[l] = 0
            continue
        }
        dY_r    = gamma_ci_cache[l].dY
        dW_r    = gamma_ci_cache[l].dW
        Z_r     = gamma_ci_cache[l].Z
        times_r = gamma_ci_cache[l].times
        uid_r   = gamma_ci_cache[l].uid

        if (rows(dY_r) < 20) {
            accept[l] = 0
            continue
        }
        // Sample D_sample: use 1-step W_first (consistent with bootstrap)
        // per Gong-Seo 2026 Alg. 1. 2-step Omega-weighted obj is for point
        // estimation only; for bootstrap test inversion, use 1-step throughout.
        xdpt2_fast_gmm_boot(dY_r, gamma_ci_cache[l],
                             ok_r, theta_r, obj_r_1s)
        if (!ok_r) {
            accept[l] = 0
            continue
        }
        // Sample unrestricted: min 1-step obj over γ_grid using dY_r
        best_obj_1s = obj_r_1s
        for (gb_s = 1; gb_s <= cols(gamma_cache); gb_s++) {
            if (!gamma_cache[gb_s].ok) continue
            if (gamma_cache[gb_s].n_rows != rows(dY_r)) continue
            xdpt2_fast_gmm_boot(dY_r, gamma_cache[gb_s],
                                 ok_1s, theta_s_dummy, obj_u_1s)
            if (!ok_1s) continue
            if (obj_u_1s < best_obj_1s) best_obj_1s = obj_u_1s
        }
        D_sample = obj_r_1s - best_obj_1s
        if (D_sample < 0) D_sample = 0
        if (D_sample < 1e-6) {
            accept[l] = 1
            continue
        }

        // Residuals under restricted DGP
        resid_r = dY_r - dW_r * theta_r

        // Bootstrap loop  [FAST PATH: uses precomputed C_g, no cluster-Ω]
        D_vec = J(n_boot, 1, .)
        for (b = 1; b <= n_boot; b++) {
            // UNIT-LEVEL Mammen weights (vectorized)
            eta_unit = xdpt2_mammen_draw(n_u)
            eta = eta_unit[uid_r]
            Y_boot = dW_r * theta_r + resid_r :* eta

            // Bootstrap restricted at γ_ℓ — fast 1-step GMM
            xdpt2_fast_gmm_boot(Y_boot, gamma_ci_cache[l],
                                 ok_b_r, theta_b_r, obj_b_r)
            if (!ok_b_r) {
                // Fallback: full 2-step if fast path failed (rare)
                xdpt2_solve_gmm(Y_boot, dW_r, Z_r, uid_r, times_r, method,
                                 ok_b_r, theta_b_r, obj_b_r, V_dummy)
                if (!ok_b_r) {
                    continue
                }
            }

            // Bootstrap unrestricted: grid search (fast 1-step per γ)
            min_obj_b = obj_b_r
            for (gb = 1; gb <= cols(gamma_cache); gb++) {
                if (!gamma_cache[gb].ok) continue
                if (gamma_cache[gb].n_rows != rows(Y_boot)) continue
                xdpt2_fast_gmm_boot(Y_boot, gamma_cache[gb],
                                     ok_b_u, theta_b_u, obj_b_u)
                if (!ok_b_u) {
                    // BUG 7 FIX: fallback to full 2-step GMM if fast path fails.
                    // Previously we silently skipped, biasing min_obj_b upward.
                    xdpt2_solve_gmm(Y_boot, gamma_cache[gb].dW,
                                     gamma_cache[gb].Z, gamma_cache[gb].uid,
                                     gamma_cache[gb].times, method,
                                     ok_b_u, theta_b_u, obj_b_u, V_dummy)
                    if (!ok_b_u) continue
                }
                if (obj_b_u < min_obj_b) min_obj_b = obj_b_u
            }

            D_boot = obj_b_r - min_obj_b
            if (D_boot < 0) D_boot = 0
            D_vec[b] = D_boot
        }

        crit = xdpt2_quantile(D_vec, 1 - alpha)
        if (crit == .) {
            accept[l] = 0
            continue
        }
        accept[l] = (D_sample <= crit)

        if (xdpt_verbose) {
            printf("    γ_ℓ=%6.4f  D_n=%7.3f  crit=%7.3f  %s\n",
                   gamma_ci_grid[l], D_sample, crit,
                   (accept[l] ? "accept" : "reject"))
        }
    }
    if (!xdpt_verbose) {
        printf(" done\n")
        displayflush()
    }

    // Convex hull of accepted γ.
    // v0.7.0 (B3): an empty acceptance set is REPORTED (ci_empty = 1, bounds
    // left missing) instead of being silently collapsed to the degenerate
    // point CI {γ̂}, which looked like ultra-precise inference when the test
    // inversion in fact rejected everywhere. A disconnected acceptance set is
    // flagged via ci_nseg > 1 (the hull is still returned for continuity).
    gam_lo = .
    gam_hi = .
    ci_nseg = 0
    real scalar prev_acc
    prev_acc = 0
    for (l = 1; l <= n_ci; l++) {
        if (accept[l] == 1) {
            if (gam_lo == .) gam_lo = gamma_ci_grid[l]
            gam_hi = gamma_ci_grid[l]
            if (!prev_acc) ci_nseg = ci_nseg + 1
            prev_acc = 1
        }
        else prev_acc = 0
    }
    ci_empty = (gam_lo == .)
}

// Continuity test (Gong-Seo 2026, §4.3 and Theorem 7):
//   H0: model is continuous (kink) vs H1: discontinuous (jump)
//   Test stat T_n = n·(Q̂_kink(θ̃) - Q̂_jump(θ̂)) on sample
//   Bootstrap p-value under kink DGP.
real scalar xdpt2_continuity_test(struct xdpt2_unit rowvector units,
                                    real colvector gamma_grid,
                                    struct xdpt2_gamma_cache rowvector cache_jump,
                                    real scalar best_obj_jump,
                                    string scalar method,
                                    real scalar flag_static,
                                    real scalar t_min, real scalar t_max,
                                    real scalar n_boot)
{
    real scalar g_kink, obj_kink, T_sample, T_boot_b, count_exceed, valid_boot
    real scalar b, gl, ok, obj_cur, n_u, u, i, ok_b, obj_kink_b, obj_jump_b
    real scalar gl_j, min_obj_kink_b, min_obj_jump_b
    real scalar K
    real colvector theta_kink_sample, r_kink, Y_boot, eta, eta_unit
    real matrix dY_k, dW_k, Z_k, V_dummy
    real colvector times_k, uid_k, theta_cur, times_cur, uid_cur
    real matrix dY_cur, dW_cur, Z_cur, V_cur
    real matrix W_first
    // 1-step T_sample (Gong-Seo Alg. 1 consistency)
    real scalar best_k_1s, best_j_1s, ok_1s, gl_1s
    real colvector theta_1s_dummy
    theta_1s_dummy = J(0, 1, 0)

    // Step 1: compute sample T_n = obj_kink - obj_jump
    // v0.7.0 (D1): the kink cache is built ONCE here and reused by the kink
    // grid search, the sample statistic, and the bootstrap. The jump cache is
    // the main estimation cache passed in by the caller (the continuity test
    // only runs when the estimated model is the jump model, flag_kink = 0).
    struct xdpt2_gamma_cache rowvector cache_kink
    cache_kink = xdpt2_build_gamma_cache(units, gamma_grid, method,
                                          flag_static, 1, t_min, t_max)

    real scalar best_gamma_k, best_obj_k
    real colvector best_theta_k
    real matrix best_V_k
    real matrix A_k_unused
    xdpt2_grid_search(units, gamma_grid, cache_kink, method, flag_static, 1,
                       t_min, t_max,
                       best_gamma_k, best_obj_k, best_theta_k, best_V_k,
                       A_k_unused)
    if (best_gamma_k == .) return(.)

    // Step 2: bootstrap under H0 (kink DGP at γ̂_kink, θ̂_kink). γ̂_kink lies
    // on gamma_grid, so the stacked data is normally already in the cache.
    real scalar idx_k
    idx_k = 0
    for (gl = 1; gl <= cols(cache_kink); gl++) {
        if (cache_kink[gl].ok & cache_kink[gl].gamma == best_gamma_k) {
            idx_k = gl
            break
        }
    }
    if (idx_k > 0) {
        dY_k    = cache_kink[idx_k].dY
        dW_k    = cache_kink[idx_k].dW
        Z_k     = cache_kink[idx_k].Z
        times_k = cache_kink[idx_k].times
        uid_k   = cache_kink[idx_k].uid
    }
    else {
        xdpt2_stack_at_gamma(units, best_gamma_k, method,
                              flag_static, 1, t_min, t_max,
                              dY_k, dW_k, Z_k, times_k, uid_k)
    }
    r_kink = dY_k - dW_k * best_theta_k

    n_u = length(units)
    count_exceed = 0
    valid_boot = 0

    // T_sample with 1-step W_first (consistent with bootstrap per GS 2026 Alg. 1)
    best_k_1s = .
    for (gl_1s = 1; gl_1s <= cols(cache_kink); gl_1s++) {
        if (!cache_kink[gl_1s].ok) continue
        if (cache_kink[gl_1s].n_rows != rows(dY_k)) continue
        xdpt2_fast_gmm_boot(dY_k, cache_kink[gl_1s],
                             ok_1s, theta_1s_dummy, obj_cur)
        if (!ok_1s) continue
        if (best_k_1s == . | obj_cur < best_k_1s) best_k_1s = obj_cur
    }
    best_j_1s = .
    for (gl_1s = 1; gl_1s <= cols(cache_jump); gl_1s++) {
        if (!cache_jump[gl_1s].ok) continue
        if (cache_jump[gl_1s].n_rows != rows(dY_k)) continue
        xdpt2_fast_gmm_boot(dY_k, cache_jump[gl_1s],
                             ok_1s, theta_1s_dummy, obj_cur)
        if (!ok_1s) continue
        if (best_j_1s == . | obj_cur < best_j_1s) best_j_1s = obj_cur
    }
    if (best_k_1s == . | best_j_1s == .) return(.)
    T_sample = best_k_1s - best_j_1s
    if (T_sample < 0) T_sample = 0

    external real scalar xdpt_verbose
    if (xdpt_verbose) printf("  Continuity test (H0: kink, B=%g, unit-level Mammen; cached)...\n", n_boot)
    else {
        printf("  Continuity test  (. per bootstrap, %g total)\n  ", n_boot)
        displayflush()
    }

    for (b = 1; b <= n_boot; b++) {
        if (!xdpt_verbose) {
            if (mod(b, 50) == 0) printf("+ %g\n  ", b)
            else                 printf(".")
            displayflush()
        }
        eta_unit = xdpt2_mammen_draw(n_u)
        eta = eta_unit[uid_k]
        Y_boot = dW_k * best_theta_k + r_kink :* eta

        // Compute min obj under KINK on bootstrap (fast 1-step, cached C_g)
        min_obj_kink_b = .
        for (gl = 1; gl <= cols(cache_kink); gl++) {
            if (!cache_kink[gl].ok) continue
            if (cache_kink[gl].n_rows != rows(Y_boot)) continue
            xdpt2_fast_gmm_boot(Y_boot, cache_kink[gl],
                                 ok_b, theta_cur, obj_cur)
            if (!ok_b) continue
            if (obj_cur < min_obj_kink_b) min_obj_kink_b = obj_cur
        }

        // Compute min obj under JUMP on bootstrap (fast 1-step, cached C_g)
        min_obj_jump_b = .
        for (gl_j = 1; gl_j <= cols(cache_jump); gl_j++) {
            if (!cache_jump[gl_j].ok) continue
            if (cache_jump[gl_j].n_rows != rows(Y_boot)) continue
            xdpt2_fast_gmm_boot(Y_boot, cache_jump[gl_j],
                                 ok_b, theta_cur, obj_cur)
            if (!ok_b) continue
            if (obj_cur < min_obj_jump_b) min_obj_jump_b = obj_cur
        }

        if (min_obj_kink_b == . | min_obj_jump_b == .) continue
        valid_boot = valid_boot + 1
        T_boot_b = min_obj_kink_b - min_obj_jump_b
        if (T_boot_b < 0) T_boot_b = 0
        if (T_boot_b >= T_sample) count_exceed = count_exceed + 1
    }
    if (!xdpt_verbose) {
        printf(" done\n")
        displayflush()
    }

    if (valid_boot == 0) return(.)
    // v0.7.0 (B2): add-one correction (Davidson-MacKinnon 2000) — a valid
    // bootstrap p-value is never exactly zero.
    return((1 + count_exceed) / (1 + valid_boot))
}

// Linearity test (H0: no regime, δ=0). Wild bootstrap.
real scalar xdpt2_linearity_test(struct xdpt2_unit rowvector units,
                                  real colvector gamma_grid,
                                  struct xdpt2_gamma_cache rowvector gamma_cache,
                                  real scalar best_obj,
                                  string scalar method, real scalar flag_static,
                                  real scalar flag_kink,
                                  real scalar t_min, real scalar t_max,
                                  real scalar n_boot)
{
    // Restricted: no regime — W has only K (β) cols; γ irrelevant
    real scalar K, ok, obj_r, n_rows, b, ok_b_r, obj_b_r, ok_b_u, obj_b_u
    real scalar gl_b, min_obj_b_u, supW_sample, count_exceed, valid_boot
    real scalar n_u, u
    real matrix dY_s, dW_s, Z_s, W_beta_s, V_r, V_dummy
    real colvector times_s, theta_r, resid_r, Y_boot, theta_b_r, theta_b_u
    real colvector eta_unit, eta, uid_s, uid_b
    real matrix dY_b, dW_b, Z_b
    real colvector times_b
    // 1-step sample obj (Gong-Seo Alg. 1 consistency)
    real matrix W_first_lin
    real scalar obj_r_1s, gl_s, obj_u_1s, ok_1s, min_obj_u_1s
    real colvector theta_1s_dummy
    theta_1s_dummy = J(0, 1, 0)

    K = cols(units[1].X)
    if (K == 0) return(.)
    n_u = length(units)

    // v0.7.0 (D1): the per-γ cache is passed in (built once in
    // xtdpthresh_run). The restricted (no-regime) model uses only the
    // γ-invariant β columns, so any valid cache entry supplies the stacked
    // sample — no fresh stack_at_gamma / cache build needed here.
    real scalar idx_base
    idx_base = 0
    for (gl_s = 1; gl_s <= cols(gamma_cache); gl_s++) {
        if (gamma_cache[gl_s].ok) {
            idx_base = gl_s
            gl_s = cols(gamma_cache) + 1
        }
    }
    if (idx_base == 0) return(.)

    dY_s    = gamma_cache[idx_base].dY
    dW_s    = gamma_cache[idx_base].dW
    Z_s     = gamma_cache[idx_base].Z
    times_s = gamma_cache[idx_base].times
    uid_s   = gamma_cache[idx_base].uid
    if (rows(dY_s) < 20) return(.)

    // Restricted regressors: the base β columns. v0.7.0 (A3): under
    // method(system) the stacked W carries the level-equation constant as its
    // LAST column — a base parameter, not a regime parameter — so the null
    // (linear) model must include it too; omitting it would make the
    // restricted model artificially bad and bias the test toward rejection.
    real scalar has_lvl_cons
    has_lvl_cons = (cols(dW_s) > (flag_kink ? K + 1 : 2*K + 1))
    W_beta_s = dW_s[., 1..K]
    if (has_lvl_cons) W_beta_s = W_beta_s, dW_s[., cols(dW_s)]

    // BUG 4b FIX: use 1-step theta_r with W_first (consistent with bootstrap).
    // Previously theta_r came from 2-step solve_gmm while supW uses 1-step obj,
    // creating a scale inconsistency between sample and bootstrap statistics.
    // Both sample and bootstrap now use 1-step with the same W_first weight.
    W_first_lin = gamma_cache[idx_base].W_first
    xdpt2_solve_gmm_1step(dY_s, W_beta_s, Z_s, W_first_lin,
                           ok, theta_r, obj_r_1s, V_r)
    if (!ok) return(.)

    // Bootstrap under H0 (unit-level Mammen) — uses 1-step theta_r
    resid_r = dY_s - W_beta_s * theta_r
    count_exceed = 0
    valid_boot = 0

    min_obj_u_1s = .
    for (gl_s = 1; gl_s <= cols(gamma_cache); gl_s++) {
        if (!gamma_cache[gl_s].ok) continue
        if (gamma_cache[gl_s].n_rows != rows(dY_s)) continue
        xdpt2_fast_gmm_boot(dY_s, gamma_cache[gl_s],
                             ok_1s, theta_1s_dummy, obj_u_1s)
        if (!ok_1s) continue
        if (min_obj_u_1s == . | obj_u_1s < min_obj_u_1s) min_obj_u_1s = obj_u_1s
    }
    if (min_obj_u_1s == .) return(.)
    supW_sample = obj_r_1s - min_obj_u_1s
    if (supW_sample < 0) supW_sample = 0

    // Precompute C_beta for fast restricted bootstrap
    // (dY_s/Z_s/times_s/uid_s come from gamma_cache[idx_base]; Z and the row
    //  sample are γ-invariant, so any valid entry is equivalent)
    real matrix W_first_s, ZW_beta, A_beta, C_beta
    real scalar fast_r_ok, n_rows_s
    n_rows_s = rows(dY_s)
    W_first_s = gamma_cache[idx_base].W_first
    ZW_beta = Z_s' * W_beta_s / n_rows_s
    A_beta = ZW_beta' * W_first_s * ZW_beta
    fast_r_ok = (cond(A_beta) <= 1e12)
    if (fast_r_ok) {
        C_beta = invsym(A_beta) * ZW_beta' * W_first_s
    }

    external real scalar xdpt_verbose
    if (xdpt_verbose) printf("  Linearity test (H0: δ=0, B=%g, unit-level Mammen; cached)...\n", n_boot)
    else {
        printf("  Linearity test   (. per bootstrap, %g total)\n  ", n_boot)
        displayflush()
    }

    real colvector ZY_b, r_b, g_b
    for (b = 1; b <= n_boot; b++) {
        if (!xdpt_verbose) {
            if (mod(b, 50) == 0) printf("+ %g\n  ", b)
            else                 printf(".")
            displayflush()
        }
        eta_unit = xdpt2_mammen_draw(n_u)
        eta = eta_unit[uid_s]
        Y_boot = W_beta_s * theta_r + resid_r :* eta

        // Bootstrap restricted — fast inline if C_beta valid
        if (fast_r_ok) {
            ZY_b = Z_s' * Y_boot / n_rows_s
            theta_b_r = C_beta * ZY_b
            r_b = Y_boot - W_beta_s * theta_b_r
            g_b = Z_s' * r_b / n_rows_s
            obj_b_r = n_rows_s * (g_b' * W_first_s * g_b)
            ok_b_r = 1
        }
        else {
            xdpt2_solve_gmm(Y_boot, W_beta_s, Z_s, uid_s, times_s, method,
                             ok_b_r, theta_b_r, obj_b_r, V_dummy)
            if (!ok_b_r) continue
        }

        // Bootstrap unrestricted: grid search (fast 1-step)
        min_obj_b_u = obj_b_r
        for (gl_b = 1; gl_b <= cols(gamma_cache); gl_b++) {
            if (!gamma_cache[gl_b].ok) continue
            if (gamma_cache[gl_b].n_rows != rows(Y_boot)) continue
            xdpt2_fast_gmm_boot(Y_boot, gamma_cache[gl_b],
                                 ok_b_u, theta_b_u, obj_b_u)
            if (!ok_b_u) continue
            if (obj_b_u < min_obj_b_u) min_obj_b_u = obj_b_u
        }

        real scalar supW_b
        supW_b = obj_b_r - min_obj_b_u
        valid_boot = valid_boot + 1
        if (supW_b >= supW_sample) count_exceed = count_exceed + 1
    }
    if (!xdpt_verbose) {
        printf(" done\n")
        displayflush()
    }

    if (valid_boot == 0) return(.)
    // v0.7.0 (B2): add-one correction (Davidson-MacKinnon 2000).
    return((1 + count_exceed) / (1 + valid_boot))
}

// Hansen J over-identification test.
// Under 2-step GMM with efficient weight Ω̂⁻¹: J = n·g'Ω̂⁻¹g ~ χ²(df)
// df = # instruments - # parameters. Stored obj IS J under 2-step.
real rowvector xdpt2_hansen_j(real scalar obj, real scalar n_iv, real scalar k_W)
{
    real scalar df, pval
    real rowvector out_miss
    out_miss = (., ., .)
    df = n_iv - k_W
    if (df <= 0) return(out_miss)
    pval = 1 - chi2(df, obj)
    return((obj, df, pval))
}

// BUG 1 FIX: recompute Hansen J cluster-robust at best theta, independent
// of whether optimization used 1-step or 2-step GMM. The stored best_obj
// can be a 1-step criterion (FD stage-2 path, or 2-step fallback when
// cluster Omega is singular); passing that value into a chi^2 p-value is
// invalid. Recomputing J = n * g(theta)' * Omega^{-1} * g(theta) with the
// cluster-robust Omega at best_theta gives a proper 2-step statistic.
// Returns missing if Omega is singular (Hansen J is then not well-defined
// and the caller displays Hansen as unavailable).
real scalar xdpt2_recompute_cluster_j(real colvector Y, real matrix W,
                                       real matrix Z, real colvector unit_id,
                                       real colvector theta)
{
    real scalar n_rows, n_units, i, u
    real matrix Omega, g_per_unit, Ze
    real colvector r, g_bar

    n_rows = rows(Y)
    if (n_rows < 20) return(.)
    if (cols(Z) <= cols(W)) return(.)

    r = Y - W * theta
    Ze = Z :* r
    n_units = max(unit_id)
    g_per_unit = J(n_units, cols(Z), 0)
    for (i = 1; i <= n_rows; i++) {
        u = unit_id[i]
        g_per_unit[u, .] = g_per_unit[u, .] + Ze[i, .]
    }
    Omega = g_per_unit' * g_per_unit / n_rows
    if (cond(Omega) > 1e12) return(.)
    g_bar = Z' * r / n_rows
    return(n_rows * (g_bar' * invsym(Omega) * g_bar))
}

// Arellano-Bond AR(k) test for serial correlation in transformed residuals.
// m_k = Σ_i e_i / sqrt(Σ_i e_i^2), where e_i = Σ_t r_{it} · r_{i,t-k}
// Under H0 (no k-th order autocorrelation): m_k ~ N(0, 1)
// For FD: expect reject at k=1 (Δε has MA(1)); fail to reject at k=2 is GOOD.
// Full Arellano-Bond (1991, eq. 8) m_k statistic — v0.7.2 (B1 fix).
//   m_k = b0 / sqrt(T1 + T2 + T3)
//   b0 = ẽ_{-k}' ê          (lag-aligned residual cross product, raw sum)
//   T1 = Σ_i (ẽ_{i,-k}' ê_i)²
//   T2 = -2 g' (G A G')^{-1} G A s   — covariance with θ̂ estimation error
//   T3 = g' V̂(θ̂) g                   — direct θ̂-variance contribution
// where g = X_t' ẽ_{-k}  (∂ê_test/∂θ direction, zero-padded to dim(θ̂)),
//       G = X_s' Z_s  (raw sums, estimation equation),
//       s = Σ_i (Z_{s,i}' ê_{s,i}) · c_i  with c_i = ẽ_{i,-k}' ê_i,
//       A = the moment weight actually paired with θ̂ (exported by
//           xdpt2_grid_search), V̂ = the reported variance of θ̂.
// ẽ_{-k} is zero where the lag-k residual is unobserved — the AB trimming
// convention. T2/T3 use the ESTIMATION-equation pieces (which for
// method(fod|system) differ from the FD test residuals; the c_i scalars link
// the two within unit). The simplified pre-v0.7.2 statistic is exactly the
// T2 = T3 = 0 special case, retained as a principled fallback whenever the
// estimator pieces are unavailable or ill-conditioned (out[2] then flags
// fallback via the pair count sign convention below: n_pairs is returned
// negative when the fallback was used).
real rowvector xdpt2_ar_full(real scalar k,
                              real colvector e_t, real matrix X_t,
                              real colvector times_t, real colvector uid_t,
                              real colvector e_s, real matrix Z_s,
                              real colvector uid_s, real matrix X_s,
                              real matrix A, real matrix V)
{
    real scalar i, j, jj, t_jk, found, n_pairs, n_units_t
    real scalar b0, T1, T2, T3, c_u, mk, pval, denom2, full_ok, k_par
    real colvector rows_i, times_i, r_i, elk, uniq_t, g, g_pad, s, c_row
    real matrix G_s, GAG, B_map
    real rowvector out_miss
    transmorphic cmap

    out_miss = (., ., .)
    if (rows(e_t) < 2) return(out_miss)

    // --- Pass 1 (test equation): lag-aligned ẽ_{-k}, per-unit c_i, b0, T1 ---
    elk = J(rows(e_t), 1, 0)
    uniq_t = uniqrows(uid_t)
    n_units_t = rows(uniq_t)
    cmap = asarray_create("real", 1)
    asarray_notfound(cmap, 0)
    b0 = 0
    T1 = 0
    n_pairs = 0
    for (i = 1; i <= n_units_t; i++) {
        rows_i = selectindex(uid_t :== uniq_t[i])
        if (rows(rows_i) < 1) continue
        times_i = times_t[rows_i]
        r_i = e_t[rows_i]
        c_u = 0
        for (j = 1; j <= rows(rows_i); j++) {
            t_jk = times_i[j] - k
            found = 0
            for (jj = 1; jj <= rows(rows_i); jj++) {
                if (times_i[jj] == t_jk) {
                    found = jj
                    break
                }
            }
            if (found > 0) {
                elk[rows_i[j]] = r_i[found]
                c_u = c_u + r_i[j] * r_i[found]
                n_pairs = n_pairs + 1
            }
        }
        b0 = b0 + c_u
        T1 = T1 + c_u^2
        asarray(cmap, uniq_t[i], c_u)
    }
    if (T1 <= 0 | n_pairs < 5) return(out_miss)

    // --- Estimator-dependent variance pieces (T2, T3) ---
    // Requires: X_t aligned to e_t rows; estimation-equation residuals e_s,
    // instruments Z_s, regressors X_s; weight A; variance V.
    T2 = 0
    T3 = 0
    full_ok = 0
    k_par = rows(V)
    if (rows(X_t) == rows(e_t) & rows(e_s) > 0 &
        rows(Z_s) == rows(e_s) & rows(X_s) == rows(e_s) &
        rows(A) == cols(Z_s) & cols(A) == cols(Z_s) &
        k_par == cols(X_s) & cols(X_t) <= k_par) {

        // g = X_t' ẽ_{-k}, zero-padded to dim(θ̂) (e.g. the system level
        // constant has no FD-residual derivative, so its entry is 0)
        g = X_t' * elk
        if (rows(g) < k_par) g_pad = g \ J(k_par - rows(g), 1, 0)
        else                 g_pad = g

        // s = Σ_rows Z_s[r,.]' ê_s[r] · c(uid_s[r])  — units absent from the
        // test stack contribute c = 0 (asarray notfound default)
        s = J(cols(Z_s), 1, 0)
        c_row = J(rows(e_s), 1, 0)
        for (j = 1; j <= rows(e_s); j++) {
            c_row[j] = asarray(cmap, uid_s[j])
        }
        s = Z_s' * (e_s :* c_row)

        G_s = X_s' * Z_s                       // k_par × k_iv (raw sums)
        GAG = G_s * A * G_s'
        if (cond(GAG) <= 1e12) {
            B_map = invsym(GAG) * G_s * A      // k_par × k_iv
            T2 = -2 * (g_pad' * B_map * s)
            T3 = g_pad' * V * g_pad
            full_ok = 1
        }
    }

    denom2 = T1 + T2 + T3
    if (denom2 <= 0) {
        // Estimated-parameter terms can (rarely) push the variance estimate
        // non-positive in small samples; fall back to the T2=T3=0 statistic.
        denom2 = T1
        full_ok = 0
    }
    mk = b0 / sqrt(denom2)
    pval = 2 * (1 - normal(abs(mk)))
    // v0.7.2-d5: expose b0, T1, T2+T3 for external verification
    return((mk, (full_ok ? n_pairs : -n_pairs), pval, b0, T1, T2 + T3))
}

// xdpt2_p_fill (the predict merge helper) lives canonically in
// xtdpthresh_p.ado — Stata 17 makes ado-internal mata functions private to
// the defining ado, so the helper has to be visible from xtdpthresh_p.ado,
// not here. The externals it reads (xdpt_p_resid / xdpt_p_est /
// xdpt_p_serial_m) are populated in the orchestrator below and persist
// across the predict call.

// Main orchestrator
void xtdpthresh_run(string scalar depvar_name,
                      string scalar Ly_name,
                      string scalar exog_names,
                      string scalar endog_names,
                      string scalar predet_names,
                      string scalar inst_names,
                      string scalar q_name,
                      string scalar panelvar_name,
                      string scalar timevar_name,
                      string scalar method,
                      real scalar flag_static,
                      real scalar flag_kink,
                      real scalar flag_collapse,
                      real scalar maxlag_lo, real scalar maxlag_hi,
                      real scalar levmaxlag_lo, real scalar levmaxlag_hi,
                      real scalar n_grid,
                      real scalar n_gridci,
                      real scalar trim_rate,
                      real scalar q_lo,
                      real scalar q_hi,
                      real scalar do_grid_ci,
                      real scalar n_boot,
                      real scalar alpha,
                      real scalar flag_iv_collapse)
{
    external real scalar xdpt_collapse, xdpt_iv_collapse, xdpt_lag_lo, xdpt_lag_hi
    external real scalar xdpt_lev_lo, xdpt_lev_hi, xdpt_verbose, xdpt_export_gmm
    xdpt_collapse = flag_collapse
    xdpt_iv_collapse = flag_iv_collapse
    xdpt_lag_lo = maxlag_lo
    xdpt_lag_hi = maxlag_hi
    xdpt_lev_lo = levmaxlag_lo
    xdpt_lev_hi = levmaxlag_hi
    xdpt_verbose = strtoreal(st_local("flag_verbose"))
    xdpt_export_gmm = strtoreal(st_local("flag_exportgmm"))
    real colvector y, q, pid, tid, gamma_grid
    real matrix Ly
    real matrix X_exog, X_endog, X_predet, X_inst
    struct xdpt2_unit rowvector units
    real scalar t_min, t_max, i, n_units

    y   = st_data(., depvar_name)
    q   = st_data(., q_name)
    pid = st_data(., panelvar_name)
    tid = st_data(., timevar_name)
    Ly  = J(rows(y), 0, 0)
    if (!flag_static & Ly_name != "") Ly = st_data(., Ly_name)

    X_exog   = J(rows(y), 0, 0)
    X_endog  = J(rows(y), 0, 0)
    X_predet = J(rows(y), 0, 0)
    X_inst   = J(rows(y), 0, 0)
    if (exog_names   != "") X_exog   = st_data(., exog_names)
    if (endog_names  != "") X_endog  = st_data(., endog_names)
    if (predet_names != "") X_predet = st_data(., predet_names)
    if (inst_names   != "") X_inst   = st_data(., inst_names)

    t_min = min(tid)
    t_max = max(tid)

    units = xdpt2_build_units(y, Ly, X_exog, X_endog, X_predet, X_inst,
                               q, pid, tid, flag_static)
    n_units = length(units)
    if (n_units < 5) {
        errprintf("xtdpthresh: need >= 5 units (got %g)\n", n_units)
        exit(498)
    }
    printf("  %g units built (n_obs=%g, T range [%g, %g])\n",
           n_units, rows(y), t_min, t_max)

    // Grid search over γ
    gamma_grid = xdpt2_rangen(q_lo, q_hi, n_grid)

    real scalar best_obj, best_gamma
    real colvector best_theta
    real matrix best_V

    printf("  Grid search over %g γ points in [%8.4f, %8.4f]...\n",
           n_grid, q_lo, q_hi)
    // v0.7.0 (D1): build the estimation-grid cache ONCE; it is shared by the
    // grid search, the grid-bootstrap CI, the linearity test, and (as the
    // jump cache) the continuity test below.
    struct xdpt2_gamma_cache rowvector cache_main
    cache_main = xdpt2_build_gamma_cache(units, gamma_grid, method,
                                          flag_static, flag_kink, t_min, t_max)
    real matrix best_A
    xdpt2_grid_search(units, gamma_grid, cache_main, method, flag_static,
                       flag_kink, t_min, t_max,
                       best_gamma, best_obj, best_theta, best_V, best_A)

    if (best_gamma == .) {
        errprintf("xtdpthresh: point estimation failed (no γ admitted a valid GMM solve)\n")
        errprintf("  Hard requirements: >= 20 usable transformed observations per γ and a\n")
        errprintf("  non-singular Z'Z. Possible causes: too few units/periods, too many\n")
        errprintf("  instruments relative to N, or no variation in q within the trim grid.\n")
        errprintf("  Remedies: collapse, tighter maxlag(), larger trim(), or method(fod).\n")
        exit(498)
    }
    if (xdpt_verbose) printf("  γ̂ = %8.4f, obj = %8.4f\n", best_gamma, best_obj)

    // Grid bootstrap CI + linearity test + continuity test
    real scalar gam_lo, gam_hi, pval_lin, pval_cont, ci_empty, ci_nseg
    real colvector gamma_ci_grid
    // Initialize CI bounds to missing; overwritten below only when CI computed.
    // This allows downstream users to detect "no CI" via missing(e(gamma_lo)).
    gam_lo = .
    gam_hi = .
    pval_lin = .
    pval_cont = .
    ci_empty = .
    ci_nseg = .

    if (do_grid_ci) {
        gamma_ci_grid = xdpt2_rangen(q_lo, q_hi, n_gridci)
        xdpt2_grid_bootstrap(units, cache_main, gamma_grid, gamma_ci_grid,
                              best_obj, best_gamma,
                              method, flag_static, flag_kink,
                              t_min, t_max, n_boot, alpha,
                              gam_lo, gam_hi, ci_empty, ci_nseg)
        if (xdpt_verbose) printf("  Grid CI = [%8.4f, %8.4f]\n", gam_lo, gam_hi)

        pval_lin = xdpt2_linearity_test(units, gamma_grid, cache_main,
                                         best_obj,
                                         method, flag_static, flag_kink,
                                         t_min, t_max, n_boot)
        if (xdpt_verbose) printf("  Linearity p-value = %6.4f\n", pval_lin)

        // Continuity test only when unrestricted (jump) model is estimated;
        // cache_main is then exactly the jump cache it needs.
        if (!flag_kink) {
            pval_cont = xdpt2_continuity_test(units, gamma_grid, cache_main,
                                                best_obj,
                                                method, flag_static,
                                                t_min, t_max, n_boot)
            if (xdpt_verbose) printf("  Continuity p-value = %6.4f\n", pval_cont)
        }
    }

    // === Count sample sizes and instruments at best γ ===
    real matrix dY_f, dW_f, Z_f
    real colvector times_f, uid_f
    xdpt2_stack_at_gamma(units, best_gamma, method, flag_static, flag_kink,
                          t_min, t_max,
                          dY_f, dW_f, Z_f, times_f, uid_f)

    real scalar n_raw, n_trans, n_usable, n_iv, n_level
    n_raw    = rows(y)
    n_usable = rows(dY_f)
    n_iv     = cols(Z_f)

    real matrix dY_fod, dW_fod, Z_fod
    real colvector times_fod, uid_fod
    if (method == "system") {
        // Re-stack with FOD only to isolate transformed rows
        xdpt2_stack_at_gamma(units, best_gamma, "fod", flag_static, flag_kink,
                              t_min, t_max,
                              dY_fod, dW_fod, Z_fod, times_fod, uid_fod)
        n_trans = rows(dY_fod)
        n_level = n_usable - n_trans
    }
    else {
        n_trans = n_usable
        n_level = 0
    }

    // === Hansen J over-identification test ===
    // BUG 1 FIX: recompute J cluster-robust at best theta, independent of the
    // optimization path. When solve_gmm falls back to 1-step (Omega singular)
    // or when FD stage-2 loop stores 1-step criterion, best_obj is not chi^2
    // distributed. Recomputing here ensures chi^2 validity.
    real rowvector hj
    real scalar k_W_final, hansen_stat, hansen_df, hansen_p, J_cluster
    k_W_final = cols(dW_f)
    J_cluster = xdpt2_recompute_cluster_j(dY_f, dW_f, Z_f, uid_f, best_theta)
    if (J_cluster != .) {
        hj = xdpt2_hansen_j(J_cluster, n_iv, k_W_final)
    }
    else {
        hj = (., ., .)
    }
    hansen_stat = hj[1]
    hansen_df = hj[2]
    hansen_p = hj[3]

    // === Arellano-Bond AR(1) and AR(2) tests on FD residuals ===
    // xtabond2 (Roodman 2009) convention: AR test is ALWAYS computed on
    // first-difference residuals, regardless of the transformation used for
    // estimation. This makes AR(1)/AR(2) interpretation consistent across
    // FD, FOD, and System GMM.
    // v0.7.2 (B1 FIX): full Arellano-Bond (1991, eq. 8) statistic including
    // the estimated-parameter variance terms (see xdpt2_ar_full). The
    // estimation-equation pieces (residuals/instruments/regressors at γ̂, the
    // weight A actually paired with θ̂, and V̂) feed Terms 2-3; for
    // method(fod|system) the test residuals are the FD restack while the
    // estimator pieces remain those of the FOD/system stack, linked within
    // unit via the c_i scalars. VERIFY against xtabond2 / abar before release.
    real matrix dY_fd_ar, dW_fd_ar, Z_fd_ar, X_ar
    real colvector times_fd_ar, uid_fd_ar, resid_trans, times_trans, uid_trans
    real colvector resid_est, dy_test
    resid_est = dY_f - dW_f * best_theta
    if (method == "fd") {
        resid_trans = resid_est
        times_trans = times_f
        uid_trans = uid_f
        X_ar = dW_f
        dy_test = dY_f
    }
    else {
        // FOD or System: re-stack with FD to get proper AR-test residuals
        xdpt2_stack_at_gamma(units, best_gamma, "fd", flag_static, flag_kink,
                              t_min, t_max,
                              dY_fd_ar, dW_fd_ar, Z_fd_ar, times_fd_ar, uid_fd_ar)
        // v0.7.0 (A3): under method(system) best_theta carries the level-eq
        // constant as its LAST element; the FD restack has no constant column
        // (FD of a constant is zero), so slice it off before forming residuals.
        real colvector theta_ar
        if (cols(dW_fd_ar) < rows(best_theta)) {
            theta_ar = best_theta[|1 \ cols(dW_fd_ar)|]
        }
        else theta_ar = best_theta
        resid_trans = dY_fd_ar - dW_fd_ar * theta_ar
        times_trans = times_fd_ar
        uid_trans = uid_fd_ar
        X_ar = dW_fd_ar
        dy_test = dY_fd_ar
    }

    real rowvector ar1, ar2
    real scalar ar1_stat, ar1_p, ar2_stat, ar2_p
    ar1 = xdpt2_ar_full(1, resid_trans, X_ar, times_trans, uid_trans,
                         resid_est, Z_f, uid_f, dW_f, best_A, best_V)
    ar2 = xdpt2_ar_full(2, resid_trans, X_ar, times_trans, uid_trans,
                         resid_est, Z_f, uid_f, dW_f, best_A, best_V)

    // v0.7.3 (D5 rework): persist the EXACT AR-test row set for -predict-.
    // Mata globals survive -restore-, so xtdpthresh_p can merge residuals
    // back by actual (panelvar, timevar) keys instead of re-deriving the
    // transformation/trim/zero-Z filters in ado (which cannot be done
    // exactly: the t-2 membership and B4 zero-instrument filters depend on
    // the estimation-time unit structs). uid in the stacked vectors is the
    // unit INDEX, so map through units[.].id to recover panelvar values.
    external real matrix xdpt_p_resid, xdpt_p_est, xdpt_p_serial_m
    real colvector p_id_map, p_id_est
    real scalar pr, pe
    // AR-test (FD) series: keyed (id, time) -> (Δy_FD, ê_FD)
    p_id_map = J(rows(uid_trans), 1, .)
    for (pr = 1; pr <= rows(uid_trans); pr++) {
        p_id_map[pr] = units[uid_trans[pr]].id
    }
    // Estimation-equation series: y/resid on the ACTUAL estimation rows
    // (FOD rows under method(fod); identical to the FD series under fd). For
    // method(system) these stack transformed + level rows and are not used by
    // -predict- (system routes to the FD series, since level residuals are
    // not exposed and the mixed (id,time) keys are non-unique).
    p_id_est = J(rows(uid_f), 1, .)
    for (pe = 1; pe <= rows(uid_f); pe++) {
        p_id_est[pe] = units[uid_f[pe]].id
    }
    if (rows(xdpt_p_serial_m) == 0) xdpt_p_serial_m = 0
    xdpt_p_serial_m = xdpt_p_serial_m[1, 1] + 1
    xdpt_p_resid = p_id_map, times_trans, dy_test, resid_trans
    xdpt_p_est   = p_id_est,  times_f,     dY_f,     resid_est
    st_numscalar("r(xdpt2_p_serial)", xdpt_p_serial_m[1, 1])

    // exportgmm option (debug/verification): expose GMM weight A, instrument
    // matrix Z_f, and FD-transformed regressors X_f for external Roodman
    // certification. Guarded by xdpt_export_gmm to avoid memory cost on
    // production runs (Z_f can be n_trans × k_iv, 4MB+ on Hansen).
    external real matrix xdpt_best_A, xdpt_best_Z_f, xdpt_best_X_f
    external real scalar xdpt_export_gmm
    if (xdpt_export_gmm == 1) {
        xdpt_best_A   = best_A
        xdpt_best_Z_f = Z_f
        xdpt_best_X_f = dW_f
    }
    else {
        // Leave empty so test code can detect "no export requested"
        xdpt_best_A   = J(0, 0, 0)
        xdpt_best_Z_f = J(0, 0, 0)
        xdpt_best_X_f = J(0, 0, 0)
    }
    ar1_stat = ar1[1]
    ar1_p = ar1[3]
    ar2_stat = ar2[1]
    ar2_p = ar2[3]
    real scalar ar1_b0, ar1_T1, ar1_TT, ar2_b0, ar2_T1, ar2_TT, ar1_np, ar2_np
    ar1_b0 = ar1[4]; ar1_T1 = ar1[5]; ar1_TT = ar1[6]
    ar2_b0 = ar2[4]; ar2_T1 = ar2[5]; ar2_TT = ar2[6]
    // out[2] = signed pair count: positive when the full AB(1991, eq.8) path
    // was used, negative when the T2=T3=0 fallback fired (ill-conditioned or
    // non-positive variance). |np| is the number of lag-k residual pairs.
    ar1_np = ar1[2]; ar2_np = ar2[2]

    if (xdpt_verbose) {
        printf("  Hansen J=%6.3f (df=%g) p=%6.4f\n", hansen_stat, hansen_df, hansen_p)
        printf("  AR(1): m=%6.3f p=%6.4f   AR(2): m=%6.3f p=%6.4f\n",
               ar1_stat, ar1_p, ar2_stat, ar2_p)
    }

    // Return results
    st_rclear()
    st_matrix("r(xdpt2_theta)", best_theta')
    st_matrix("r(xdpt2_V)",     best_V)
    st_numscalar("r(xdpt2_gamma)", best_gamma)
    st_numscalar("r(xdpt2_obj)",   best_obj)
    st_numscalar("r(xdpt2_nused)",     n_usable)
    st_numscalar("r(xdpt2_n_raw)",     n_raw)
    st_numscalar("r(xdpt2_n_trans)",   n_trans)
    st_numscalar("r(xdpt2_n_level)",   n_level)
    st_numscalar("r(xdpt2_n_iv)",      n_iv)
    st_numscalar("r(xdpt2_n_units)",   length(units))
    st_numscalar("r(xdpt2_gam_lo)", gam_lo)
    st_numscalar("r(xdpt2_gam_hi)", gam_hi)
    st_numscalar("r(xdpt2_ci_empty)", ci_empty)
    st_numscalar("r(xdpt2_ci_nseg)",  ci_nseg)
    st_numscalar("r(xdpt2_pval_lin)", pval_lin)
    st_numscalar("r(xdpt2_pval_cont)", pval_cont)
    st_numscalar("r(xdpt2_hansen)",    hansen_stat)
    st_numscalar("r(xdpt2_hansen_df)", hansen_df)
    st_numscalar("r(xdpt2_hansen_p)",  hansen_p)
    st_numscalar("r(xdpt2_ar1)",       ar1_stat)
    st_numscalar("r(xdpt2_ar1_p)",     ar1_p)
    st_numscalar("r(xdpt2_ar2)",       ar2_stat)
    st_numscalar("r(xdpt2_ar2_p)",     ar2_p)
    st_numscalar("r(xdpt2_ar1_b0)",    ar1_b0)
    st_numscalar("r(xdpt2_ar1_T1)",    ar1_T1)
    st_numscalar("r(xdpt2_ar1_TT)",    ar1_TT)
    st_numscalar("r(xdpt2_ar2_b0)",    ar2_b0)
    st_numscalar("r(xdpt2_ar2_T1)",    ar2_T1)
    st_numscalar("r(xdpt2_ar2_TT)",    ar2_TT)
    st_numscalar("r(xdpt2_ar1_np)",    ar1_np)
    st_numscalar("r(xdpt2_ar2_np)",    ar2_np)
    // hotfix: persist serial AFTER st_rclear so e(p_serial) survives
    st_numscalar("r(xdpt2_p_serial)", xdpt_p_serial_m[1, 1])
}

end
// End of xtdpthresh.ado

