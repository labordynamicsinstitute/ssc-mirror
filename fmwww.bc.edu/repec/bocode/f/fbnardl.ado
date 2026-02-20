*! fbnardl — Fourier Bootstrap Nonlinear ARDL
*! Version 1.0.0 — 2026-02-18
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Implements:
*!   type(fnardl)  — Fourier NARDL with Kripfganz & Schneider (2020) critical values
*!   type(fbnardl) — Fourier Bootstrap NARDL with Bertelli, Vacca & Zoia (2022) bootstrap
*!
*! References:
*!   Shin, Yu & Greenwood-Nimmo (2014) — NARDL framework
*!   Yilanci, Bozoklu & Gorus (2020) — Fourier ARDL
*!   McNown, Sam & Goh (2018) — Bootstrap ARDL
*!   Bertelli, Vacca & Zoia (2022) — Bootstrap cointegration tests in ARDL
*!   Kripfganz & Schneider (2020) — ARDL bounds test critical values
*!   Pesaran, Shin & Smith (2001) — ARDL bounds testing

capture program drop fbnardl
program define fbnardl, eclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=1 ts fv) [if] [in], ///
        Decompose(varlist ts min=1)         /// variable(s) to decompose into pos/neg
        [                                   ///
        Type(string)                        /// fnardl or fbnardl (default: fnardl)
        MAXLag(integer 4)                   /// maximum lag to search (default: 4)
        MAXk(real 3)                        /// maximum Fourier frequency (default: 3)
        IC(string)                          /// information criterion: aic or bic (default: aic)
        REPS(integer 999)                   /// bootstrap replications (default: 999)
        Level(cilevel)                      /// confidence level (default: 95)
        NODIag                              /// suppress diagnostics
        NODYNmult                           /// suppress dynamic multipliers
        NOADVanced                          /// suppress advanced analyses
        HORizon(integer 20)                 /// multiplier horizon (default: 20)
        NOFourier                           /// no Fourier terms (pure NARDL)
        NOTable                             /// suppress main regression table
        ]

    // Mark estimation sample
    marksample touse
    markout `touse' `decompose'

    // Validate type option
    if "`type'" == "" local type "fnardl"
    local type = lower("`type'")
    if !inlist("`type'", "fnardl", "fbnardl") {
        di as err "type() must be {bf:fnardl} or {bf:fbnardl}"
        exit 198
    }

    // Validate IC
    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }

    // Validate maxlag
    if `maxlag' < 1 {
        di as err "maxlag() must be >= 1"
        exit 198
    }

    // Validate maxk
    if `maxk' < 0.1 & "`nofourier'" == "" {
        di as err "maxk() must be >= 0.1"
        exit 198
    }

    // =========================================================================
    // 2. PARSE VARIABLE LISTS
    // =========================================================================
    // depvar = first variable in varlist
    // controls = remaining variables in varlist (non-decomposed regressors)
    gettoken depvar controls : varlist

    // Count decompose variables
    local ndec : word count `decompose'
    // Count control variables
    local nctrl : word count `controls'
    // Total independent variables
    local nindep = `ndec' + `nctrl'

    // Confirm time series
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "fbnardl is designed for time-series data only, not panel data"
        exit 198
    }

    // =========================================================================
    // 3. PRESERVE & PREPARE DATA
    // =========================================================================
    preserve

    // Keep estimation sample
    qui keep if `touse'
    qui count
    local nobs = r(N)
    if `nobs' < 30 {
        di as err "Too few observations (`nobs'). Need at least 30."
        exit 2001
    }

    // Generate time index
    tempvar tindex
    qui gen `tindex' = _n

    // =========================================================================
    // 4. DECOMPOSE VARIABLES INTO POSITIVE / NEGATIVE PARTIAL SUMS
    // =========================================================================
    local dec_pos_vars ""
    local dec_neg_vars ""
    local dec_names ""

    foreach xvar of local decompose {
        // Get clean variable name
        local cname = subinstr("`xvar'", ".", "_", .)

        tempvar dx_`cname' xpos_`cname' xneg_`cname'

        // First difference
        qui gen double `dx_`cname'' = D.`xvar'

        // Positive partial sum: cumsum of max(dx, 0)
        qui gen double `xpos_`cname'' = 0
        qui replace `xpos_`cname'' = max(`dx_`cname'', 0) if `dx_`cname'' != .
        // Cumulative sum
        qui replace `xpos_`cname'' = sum(`xpos_`cname'')

        // Negative partial sum: cumsum of min(dx, 0)
        qui gen double `xneg_`cname'' = 0
        qui replace `xneg_`cname'' = min(`dx_`cname'', 0) if `dx_`cname'' != .
        qui replace `xneg_`cname'' = sum(`xneg_`cname'')

        // Rename for clarity in output
        local pname "`cname'_pos"
        local nname "`cname'_neg"
        qui rename `xpos_`cname'' `pname'
        qui rename `xneg_`cname'' `nname'

        local dec_pos_vars "`dec_pos_vars' `pname'"
        local dec_neg_vars "`dec_neg_vars' `nname'"
        local dec_names "`dec_names' `cname'"
    }

    // =========================================================================
    // 5. GRID SEARCH OVER (p, q, r, k*) TO FIND OPTIMAL MODEL
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    if "`type'" == "fbnardl" {
        di as res "  Fourier Bootstrap NARDL (FBNARDL) Estimation"
    }
    else {
        di as res "  Fourier NARDL (FNARDL) Estimation"
    }
    di as txt "{hline 70}"
    di as txt "  Dependent variable : " as res "`depvar'"
    di as txt "  Decomposed var(s)  : " as res "`decompose'"
    if `nctrl' > 0 {
        di as txt "  Control var(s)     : " as res "`controls'"
    }
    di as txt "  Max lag (p,q,r)    : " as res "`maxlag'"
    if "`nofourier'" == "" {
        di as txt "  Max Fourier freq   : " as res "`maxk'"
    }
    di as txt "  Info criterion     : " as res upper("`ic'")
    di as txt "  Observations       : " as res "`nobs'"
    if "`type'" == "fbnardl" {
        di as txt "  Bootstrap reps     : " as res "`reps'"
    }
    di as txt "{hline 70}"
    di as txt ""
    di as txt "  Searching for optimal model..."

    // Build Fourier frequency grid
    if "`nofourier'" != "" {
        // No Fourier — single element grid with 0
        local nkgrid = 1
        tempname kgrid
        mat `kgrid' = J(1, 1, 0)
    }
    else {
        // k* from 0.1 to maxk in steps of 0.1
        local nkgrid = floor(`maxk' / 0.1)
        tempname kgrid
        mat `kgrid' = J(1, `nkgrid', 0)
        forvalues j = 1/`nkgrid' {
            mat `kgrid'[1, `j'] = `j' * 0.1
        }
    }

    // Initialize best model tracking
    // Following PSS (2001) ARDL(p, q1, ..., qk) notation:
    //   p  = lag order for dependent variable
    //   qi = lag order for each decomposed variable i (same for pos/neg pair)
    //   rj = lag order for each control variable j
    // Selection: exhaustive grid search minimizing AIC/BIC
    //   (Kripfganz & Schneider, 2020; Pesaran, Shin & Smith, 2001)
    tempname best_ic_val
    scalar `best_ic_val' = .

    local best_p = 1
    local best_kstar = 0
    local best_formula ""
    local total_models = 0

    // Variable-specific lag orders for decomposed variables
    forvalues i = 1/`ndec' {
        local best_q_`i' = 0
    }

    // Variable-specific lag orders for control variables
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local best_r_`i' = 0
        }
    }

    // ---- TWO-STEP SELECTION (Yilanci et al. 2020) ----
    // =========================================================================
    // STEP 1: Select optimal Fourier frequency k* by minimum SSR
    //   Following Yilanci, Bozoklu & Gorus (2020):
    //   For each candidate k*, estimate a maximal ARDL(p_max, q_max, r_max)
    //   and record the SSR. The k* with the smallest SSR is selected.
    // =========================================================================

    di as txt "  Step 1: Selecting k* by minimum SSR (Yilanci et al. 2020)..."

    tempname best_ssr_k ssr_matrix
    scalar `best_ssr_k' = .
    mat `ssr_matrix' = J(`nkgrid', 2, .)

    forvalues kidx = 1/`nkgrid' {
        local kval = `kgrid'[1, `kidx']

        // Store k* value
        mat `ssr_matrix'[`kidx', 1] = `kval'

        // Generate Fourier terms for this k*
        if `kval' > 0 {
            capture drop _fbnardl_sin _fbnardl_cos
            qui gen double _fbnardl_sin = sin(2 * c(pi) * `kval' * `tindex' / `nobs')
            qui gen double _fbnardl_cos = cos(2 * c(pi) * `kval' * `tindex' / `nobs')
        }

        // Build maximal model: p=maxlag, all q=maxlag, all r=maxlag
        local regvars_max ""

        // (a) Lags of dependent variable
        forvalues j = 1/`maxlag' {
            local regvars_max "`regvars_max' L`j'.D.`depvar'"
        }

        // (b) Decomposed variables at maxlag
        foreach cname of local dec_names {
            forvalues j = 0/`maxlag' {
                if `j' == 0 {
                    local regvars_max "`regvars_max' D.`cname'_pos D.`cname'_neg"
                }
                else {
                    local regvars_max "`regvars_max' L`j'.D.`cname'_pos L`j'.D.`cname'_neg"
                }
            }
        }

        // (c) Control variables at maxlag
        if `nctrl' > 0 {
            foreach cvar of local controls {
                forvalues j = 0/`maxlag' {
                    if `j' == 0 {
                        local regvars_max "`regvars_max' D.`cvar'"
                    }
                    else {
                        local regvars_max "`regvars_max' L`j'.D.`cvar'"
                    }
                }
            }
        }

        // (d) Lagged levels (ECM terms)
        local regvars_max "`regvars_max' L.`depvar'"
        foreach cname of local dec_names {
            local regvars_max "`regvars_max' L.`cname'_pos L.`cname'_neg"
        }
        foreach cvar of local controls {
            local regvars_max "`regvars_max' L.`cvar'"
        }

        // (e) Fourier terms
        if `kval' > 0 {
            local regvars_max "`regvars_max' _fbnardl_sin _fbnardl_cos"
        }

        // Run maximal regression
        capture qui regress D.`depvar' `regvars_max'
        if _rc != 0 {
            mat `ssr_matrix'[`kidx', 2] = .
            continue
        }

        local this_ssr_k = e(rss)
        mat `ssr_matrix'[`kidx', 2] = `this_ssr_k'

        // Update best k* by minimum SSR
        if `this_ssr_k' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
            scalar `best_ssr_k' = `this_ssr_k'
            local best_kstar = `kval'
        }
    }

    di as txt "  Optimal k* = " as res "`best_kstar'" as txt " (min SSR = " as res %10.4f scalar(`best_ssr_k') as txt ")"

    // =========================================================================
    // GRAPH: SSR vs k* (Fourier frequency selection)
    // =========================================================================
    if `nkgrid' > 1 {
        mat _fbnardl_ssr_k = `ssr_matrix'

        // Save current data to tempfile, graph in fresh space, then reload
        tempfile _fbnardl_tmpdata
        qui save `_fbnardl_tmpdata', replace

        capture noisily {
            qui clear
            qui set obs `nkgrid'
            qui gen double kstar = .
            qui gen double ssr = .

            forvalues kidx = 1/`nkgrid' {
                qui replace kstar = el(_fbnardl_ssr_k, `kidx', 1) in `kidx'
                qui replace ssr   = el(_fbnardl_ssr_k, `kidx', 2) in `kidx'
            }

            // Mark the optimal k*
            qui gen double ssr_opt = ssr if abs(kstar - `best_kstar') < 0.001

            twoway (connected ssr kstar, lcolor(navy) mcolor(navy) ///
                    msize(small) msymbol(circle) lwidth(medthick)) ///
                   (scatter ssr_opt kstar, mcolor(cranberry) msize(large) ///
                    msymbol(diamond)), ///
                   title("Fourier Frequency Selection", size(medium)) ///
                   subtitle("SSR by k* {&mdash} Yilanci et al. (2020)", size(small)) ///
                   ytitle("Sum of Squared Residuals (SSR)", size(small)) ///
                   xtitle("Fourier Frequency (k*)", size(small)) ///
                   xline(`best_kstar', lcolor(cranberry) lpattern(dash) lwidth(thin)) ///
                   legend(order(1 "SSR" 2 "Optimal k* = `best_kstar'") ///
                          size(small) rows(1)) ///
                   note("fbnardl — Step 1: k* selected by min SSR", size(vsmall)) ///
                   scheme(s2color) name(kstar_selection, replace)

            qui graph export "kstar_selection.png", replace width(1200)
            di as txt "  Graph saved: kstar_selection.png"
        }

        // Reload working data
        qui use `_fbnardl_tmpdata', clear
        capture mat drop _fbnardl_ssr_k
    }

    // =========================================================================
    // STEP 2: Select optimal lags (p, q, r) by AIC/BIC with fixed k*
    //   Following Pesaran, Shin & Smith (2001) and Kripfganz & Schneider (2020):
    //   - Full grid search over all lag combinations
    //   - Each variable has its own lag order
    //   - k* is fixed from Step 1
    // =========================================================================

    di as txt "  Step 2: Selecting (p, q, r) by " upper("`ic'") " with fixed k*..."

    // Regenerate Fourier terms for best k*
    if `best_kstar' > 0 {
        capture drop _fbnardl_sin _fbnardl_cos
        qui gen double _fbnardl_sin = sin(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
        qui gen double _fbnardl_cos = cos(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
    }

    // Loop over p (lags of dependent variable: 1 to maxlag)
    forvalues p = 1/`maxlag' {

        // ── Build all combinations of (q1,...,q_ndec, r1,...,r_nctrl) ──
        local n_indep = `ndec' + `nctrl'
        local n_combos = 1
        forvalues vi = 1/`n_indep' {
            local n_combos = `n_combos' * (`maxlag' + 1)
        }

        // Enumerate all lag combinations using counter
        local combo_max = `n_combos' - 1
        forvalues combo = 0/`combo_max' {

            local total_models = `total_models' + 1

            // Decode combo index into variable-specific lags
            local remainder = `combo'
            // First ndec entries are q_i (decomposed lags)
            forvalues di = 1/`ndec' {
                local divisor = 1
                local remaining_vars = `n_indep' - `di'
                if `remaining_vars' > 0 {
                    forvalues rv = 1/`remaining_vars' {
                        local divisor = `divisor' * (`maxlag' + 1)
                    }
                }
                local cur_q_`di' = floor(`remainder' / `divisor')
                local remainder = `remainder' - `cur_q_`di'' * `divisor'
            }
            // Remaining entries are r_j (control lags)
            if `nctrl' > 0 {
                forvalues ci = 1/`nctrl' {
                    local di2 = `ndec' + `ci'
                    local divisor = 1
                    local remaining_vars = `n_indep' - `di2'
                    if `remaining_vars' > 0 {
                        forvalues rv = 1/`remaining_vars' {
                            local divisor = `divisor' * (`maxlag' + 1)
                        }
                    }
                    local cur_r_`ci' = floor(`remainder' / `divisor')
                    local remainder = `remainder' - `cur_r_`ci'' * `divisor'
                }
            }

            // Build regression formula
            local regvars ""

            // (a) Lags of dependent variable: L(1/p).D.depvar
            forvalues j = 1/`p' {
                local regvars "`regvars' L`j'.D.`depvar'"
            }

            // (b) Decomposed variables: each with its own q_i
            local dec_i = 0
            foreach cname of local dec_names {
                local dec_i = `dec_i' + 1
                local qi = `cur_q_`dec_i''
                forvalues j = 0/`qi' {
                    if `j' == 0 {
                        local regvars "`regvars' D.`cname'_pos D.`cname'_neg"
                    }
                    else {
                        local regvars "`regvars' L`j'.D.`cname'_pos L`j'.D.`cname'_neg"
                    }
                }
            }

            // (c) Control variables: each with its own r_j
            if `nctrl' > 0 {
                local ctrl_i = 0
                foreach cvar of local controls {
                    local ctrl_i = `ctrl_i' + 1
                    local rj = `cur_r_`ctrl_i''
                    forvalues j = 0/`rj' {
                        if `j' == 0 {
                            local regvars "`regvars' D.`cvar'"
                        }
                        else {
                            local regvars "`regvars' L`j'.D.`cvar'"
                        }
                    }
                }
            }

            // (d) Lagged levels (ECM terms)
            local regvars "`regvars' L.`depvar'"
            foreach cname of local dec_names {
                local regvars "`regvars' L.`cname'_pos L.`cname'_neg"
            }
            foreach cvar of local controls {
                local regvars "`regvars' L.`cvar'"
            }

            // (e) Fourier terms (fixed k* from Step 1)
            if `best_kstar' > 0 {
                local regvars "`regvars' _fbnardl_sin _fbnardl_cos"
            }

            // Run regression
            capture qui regress D.`depvar' `regvars'
            if _rc != 0 continue

            // Check minimum observations
            if e(N) < e(df_m) + 10 continue

            // Compute IC
            local this_n = e(N)
            local this_k = e(df_m) + 1
            local this_ssr = e(rss)

            if "`ic'" == "aic" {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + 2 * `this_k'
            }
            else {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + `this_k' * ln(`this_n')
            }

            // Update best model
            if `this_ic' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                scalar `best_ic_val' = `this_ic'
                local best_p = `p'
                local best_formula "`regvars'"
                // Store variable-specific q's
                forvalues di = 1/`ndec' {
                    local best_q_`di' = `cur_q_`di''
                }
                // Store variable-specific r's
                if `nctrl' > 0 {
                    forvalues ci = 1/`nctrl' {
                        local best_r_`ci' = `cur_r_`ci''
                    }
                }
            }

        } // end combo loop
    } // end p loop

    di as txt "  Models evaluated   : " as res "`total_models'"
    di as txt "  Best " upper("`ic'") "          : " as res %10.4f scalar(`best_ic_val')
    di as txt ""

    // =========================================================================
    // 6. RE-ESTIMATE BEST MODEL & STORE RESULTS
    // =========================================================================
    // Regenerate Fourier terms for best k*
    if `best_kstar' > 0 {
        capture drop _fbnardl_sin _fbnardl_cos
        qui gen double _fbnardl_sin = sin(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
        qui gen double _fbnardl_cos = cos(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
    }

    // Fit best model
    qui regress D.`depvar' `best_formula'

    local nobs_used = e(N)
    local nparams = e(df_m) + 1
    local r2 = e(r2)
    local r2_adj = e(r2_a)
    local fstat = e(F)
    local fstat_p = Ftail(e(df_m), e(df_r), e(F))
    local ssr = e(rss)
    local sig2 = e(rss) / e(df_r)
    local loglik = e(ll)
    local aic_val = `nobs_used' * ln(`ssr'/`nobs_used') + 2 * `nparams'
    local bic_val = `nobs_used' * ln(`ssr'/`nobs_used') + `nparams' * ln(`nobs_used')

    // Store coefficient names & values
    tempname b_full V_full
    mat `b_full' = e(b)
    mat `V_full' = e(V)

    // Store residuals
    tempvar resid yhat
    qui predict double `resid', residuals
    qui predict double `yhat', xb

    // =========================================================================
    // 7. DISPLAY — TABLE 1: MODEL SELECTION
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 1: Model Selection"
    di as txt "{hline 70}"
    di as txt "  Selected lag p (depvar lags)       : " as res `best_p'
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        di as txt "  Selected lag q (`cname' lags)" _col(40) ": " as res `best_q_`dec_i''
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local cvar : word `i' of `controls'
            di as txt "  Selected lag r (`cvar' lags)"  _col(40) ": " as res `best_r_`i''
        }
    }
    if "`nofourier'" == "" {
        di as txt "  Selected Fourier frequency (k*)    : " as res %6.2f `best_kstar'
    }
    di as txt "  Information criterion (" upper("`ic'") ")     : " as res %12.4f scalar(`best_ic_val')
    di as txt "  AIC                               : " as res %12.4f `aic_val'
    di as txt "  BIC                               : " as res %12.4f `bic_val'
    di as txt "  Log-likelihood                     : " as res %12.4f `loglik'
    di as txt "  Observations (used)                : " as res `nobs_used'
    di as txt "  R-squared                          : " as res %8.4f `r2'
    di as txt "  Adjusted R-squared                 : " as res %8.4f `r2_adj'
    di as txt "  F-statistic                        : " as res %8.4f `fstat' " (p=" %6.4f `fstat_p' ")"
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 8. DISPLAY — TABLE 2: STRUCTURED ESTIMATION RESULTS
    // =========================================================================
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as res "  Table 2: Estimation Results (Dependent Variable: D.`depvar')"
        di as txt "{hline 78}"
        di as txt _col(3) "Variable" _col(25) "Coef." _col(38) "Std.Err." _col(51) "t-stat" _col(63) "p-value"
        di as txt "{hline 78}"

        // ─────────────────────────────────────────────────────────────────
        // Panel A: Short-Run Dynamics (D. notation)
        // ─────────────────────────────────────────────────────────────────
        di as res "  Panel A: Short-Run Dynamics"
        di as txt "{hline 78}"

        // A1. Lagged differences of dependent variable: L1.D.y, L2.D.y, ...
        di as txt _col(3) "{it:Lagged D.`depvar'}"
        forvalues j = 1/`best_p' {
            local vname "L`j'.D.`depvar'"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "L`j'.D.`depvar'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
        }

        // A2. Decomposed variables: D.xpos, L1.D.xpos, ..., D.xneg, L1.D.xneg, ...
        local dec_i = 0
        foreach cname of local dec_names {
            di as txt ""
            local dec_i = `dec_i' + 1
            local this_q = `best_q_`dec_i''
            di as txt _col(3) "{it:D.`cname' (decomposed, lag q=`this_q')}"
            forvalues j = 0/`this_q' {
                // Positive component
                if `j' == 0 {
                    local vname_p "D.`cname'_pos"
                    local label_p "D.`cname'_pos"
                }
                else {
                    local vname_p "L`j'.D.`cname'_pos"
                    local label_p "L`j'.D.`cname'_pos"
                }
                capture local coef_val = _b[`vname_p']
                if _rc == 0 {
                    local se_val = _se[`vname_p']
                    local t_val = `coef_val' / `se_val'
                    local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                    di as txt _col(5) "`label_p'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                    _fbnardl_stars `p_val'
                }
                // Negative component
                if `j' == 0 {
                    local vname_n "D.`cname'_neg"
                    local label_n "D.`cname'_neg"
                }
                else {
                    local vname_n "L`j'.D.`cname'_neg"
                    local label_n "L`j'.D.`cname'_neg"
                }
                capture local coef_val = _b[`vname_n']
                if _rc == 0 {
                    local se_val = _se[`vname_n']
                    local t_val = `coef_val' / `se_val'
                    local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                    di as txt _col(5) "`label_n'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                    _fbnardl_stars `p_val'
                }
            }
        }

        // A3. Control variables: D.z, L1.D.z, ...
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt ""
                di as txt _col(3) "{it:D.`cvar' (control, lag r=`this_r')}"
                forvalues j = 0/`this_r' {
                    if `j' == 0 {
                        local vname "D.`cvar'"
                        local label "D.`cvar'"
                    }
                    else {
                        local vname "L`j'.D.`cvar'"
                        local label "L`j'.D.`cvar'"
                    }
                    capture local coef_val = _b[`vname']
                    if _rc == 0 {
                        local se_val = _se[`vname']
                        local t_val = `coef_val' / `se_val'
                        local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                        di as txt _col(5) "`label'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                        _fbnardl_stars `p_val'
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // Panel B: Long-Run / ECM Level Coefficients (L. notation)
        // ─────────────────────────────────────────────────────────────────
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Panel B: Long-Run (ECM Level) Coefficients"
        di as txt "{hline 78}"

        // B1. ECM speed-of-adjustment: L.depvar
        local vname "L.`depvar'"
        capture local coef_val = _b[`vname']
        if _rc == 0 {
            local se_val = _se[`vname']
            local t_val = `coef_val' / `se_val'
            local p_val = 2 * ttail(e(df_r), abs(`t_val'))
            di as txt _col(5) "L.`depvar'" _col(20) "(ECM/alpha)" _col(33) as res %10.4f `coef_val' _col(46) %10.4f `se_val' _col(59) %8.3f `t_val' _col(71) %8.4f `p_val' _c
            _fbnardl_stars `p_val'
        }

        // B2. Lagged levels of decomposed: L.xpos, L.xneg
        foreach cname of local dec_names {
            local vname "L.`cname'_pos"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "L.`cname'_pos" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
            local vname "L.`cname'_neg"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "L.`cname'_neg" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
        }

        // B3. Lagged levels of controls: L.z
        foreach cvar of local controls {
            local vname "L.`cvar'"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "L.`cvar'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // Panel C: Fourier Terms & Constant
        // ─────────────────────────────────────────────────────────────────
        if "`nofourier'" == "" & `best_kstar' > 0 {
            di as txt ""
            di as txt "{hline 78}"
            di as res "  Panel C: Fourier Terms (k* = " %4.1f `best_kstar' ")"
            di as txt "{hline 78}"

            local vname "_fbnardl_sin"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "sin(2*pi*k*t/T)" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
            local vname "_fbnardl_cos"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "cos(2*pi*k*t/T)" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _fbnardl_stars `p_val'
            }
        }

        // Constant
        capture local coef_val = _b[_cons]
        if _rc == 0 {
            local se_val = _se[_cons]
            local t_val = `coef_val' / `se_val'
            local p_val = 2 * ttail(e(df_r), abs(`t_val'))
            di as txt _col(5) "_cons" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
            _fbnardl_stars `p_val'
        }

        di as txt "{hline 78}"

        // ─────────────────────────────────────────────────────────────────
        // Lag Selection Summary & Model Specification
        // ─────────────────────────────────────────────────────────────────
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Lag Selection Summary"
        di as txt "{hline 78}"

        // Build lag order vector string for notation: ARDL(p, q1, ..., r1, ...)
        local lag_vec ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local lag_vec "`lag_vec', `best_q_`dec_i''"
        }
        if `nctrl' > 0 {
            forvalues i = 1/`nctrl' {
                local lag_vec "`lag_vec', `best_r_`i''"
            }
        }

        // Model specification: FNARDL(p, q1, ..., r1, ...) with k* outside
        if "`nofourier'" == "" {
            di as res _col(5) "Model: FNARDL(`best_p'`lag_vec')    k* = " %4.1f `best_kstar'
        }
        else {
            di as res _col(5) "Model: NARDL(`best_p'`lag_vec')"
        }
        di as txt ""

        // Detailed lag info
        di as txt _col(5) "p = " as res `best_p' as txt "  (dep. var lags)     L1.D.`depvar'" _c
        if `best_p' > 1 {
            di as txt " ... L`best_p'.D.`depvar'"
        }
        else {
            di as txt ""
        }
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local qi = `best_q_`dec_i''
            di as txt _col(5) "q`dec_i'= " as res `qi' as txt "  (`cname' lags)   D.`cname'+/-" _c
            if `qi' > 0 {
                di as txt " ... L`qi'.D.`cname'+/-"
            }
            else {
                di as txt ""
            }
        }
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt _col(5) "r = " as res `this_r' as txt "  (`cvar' lags)   D.`cvar'" _c
                if `this_r' > 0 {
                    di as txt " ... L`this_r'.D.`cvar'"
                }
                else {
                    di as txt ""
                }
            }
        }
        if "`nofourier'" == "" {
            di as txt _col(5) "k*= " as res %4.1f `best_kstar' as txt "  (Fourier freq)      sin(2*pi*k*t/T), cos(2*pi*k*t/T)"
        }

        // ─────────────────────────────────────────────────────────────────
        // Explicit Equation Display
        // ─────────────────────────────────────────────────────────────────
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Estimated Equation"
        di as txt "{hline 78}"
        di as txt ""

        // Line 1: D.y = ...
        di as txt _col(5) "D.`depvar' =" _c

        // Short-run: lagged differences of depvar
        local first_term = 1
        forvalues j = 1/`best_p' {
            if `first_term' {
                di as txt " " as res "L`j'.D.`depvar'" _c
                local first_term = 0
            }
            else {
                di as txt " + " as res "L`j'.D.`depvar'" _c
            }
        }
        di as txt ""

        // Short-run: decomposed pos/neg (variable-specific lags)
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local qi = `best_q_`dec_i''
            forvalues j = 0/`qi' {
                if `j' == 0 {
                    di as txt _col(16) "+ " as res "D.`cname'_pos" as txt " + " as res "D.`cname'_neg" _c
                }
                else {
                    di as txt " + " as res "L`j'.D.`cname'_pos" as txt " + " as res "L`j'.D.`cname'_neg" _c
                }
            }
            di as txt ""
        }

        // Short-run: controls
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt _col(16) "+ " _c
                forvalues j = 0/`this_r' {
                    if `j' == 0 {
                        di as res "D.`cvar'" _c
                    }
                    else {
                        di as txt " + " as res "L`j'.D.`cvar'" _c
                    }
                }
                di as txt ""
            }
        }

        // Long-run ECM terms
        di as txt _col(16) "+ " as res "L.`depvar'" as txt " (ECM)" _c
        foreach cname of local dec_names {
            di as txt " + " as res "L.`cname'_pos" as txt " + " as res "L.`cname'_neg" _c
        }
        foreach cvar of local controls {
            di as txt " + " as res "L.`cvar'" _c
        }
        di as txt ""

        // Fourier terms
        if "`nofourier'" == "" & `best_kstar' > 0 {
            di as txt _col(16) "+ " as res "sin(2*pi*`best_kstar'*t/T)" as txt " + " as res "cos(2*pi*`best_kstar'*t/T)"
        }

        // Constant
        di as txt _col(16) "+ " as res "constant"
        di as txt ""
        di as txt "{hline 78}"

        di as txt ""
        di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
        di as txt "{hline 78}"
        di as txt ""
    }

    // =========================================================================
    // 9. SHORT-RUN & LONG-RUN MULTIPLIERS
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 3: Short-Run & Long-Run Multipliers"
    di as txt "{hline 70}"

    // Get coefficient on L.depvar (the ECM speed of adjustment)
    local ecm_coef_name "L.`depvar'"
    // Coefficients on lagged levels of decomposed
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local this_q = `best_q_`dec_i''
        local lpos_name "L.`cname'_pos"
        local lneg_name "L.`cname'_neg"

        // Compute short-run multipliers FIRST (before nlcom post destroys e())
        // SR(+/-) = sum of all D.x coefficients across lags j=0..qi
        local sr_pos = 0
        local sr_neg = 0
        forvalues j = 0/`this_q' {
            if `j' == 0 {
                capture local tmp_p = _b[D.`cname'_pos]
                if _rc == 0 local sr_pos = `sr_pos' + `tmp_p'
                capture local tmp_n = _b[D.`cname'_neg]
                if _rc == 0 local sr_neg = `sr_neg' + `tmp_n'
            }
            else {
                capture local tmp_p = _b[L`j'.D.`cname'_pos]
                if _rc == 0 local sr_pos = `sr_pos' + `tmp_p'
                capture local tmp_n = _b[L`j'.D.`cname'_neg]
                if _rc == 0 local sr_neg = `sr_neg' + `tmp_n'
            }
        }

        // LR_pos = -beta(L.xpos) / beta(L.depvar)
        // LR_neg = -beta(L.xneg) / beta(L.depvar)
        local saved_df_r = e(df_r)
        capture qui nlcom ///
            (LR_pos: -_b[`lpos_name'] / _b[`ecm_coef_name']) ///
            (LR_neg: -_b[`lneg_name'] / _b[`ecm_coef_name']), ///
            level(`level') post

        if _rc == 0 {
            tempname lr_b lr_V
            mat `lr_b' = e(b)
            mat `lr_V' = e(V)
            local lr_pos = `lr_b'[1,1]
            local lr_neg = `lr_b'[1,2]
            local lr_pos_se = sqrt(`lr_V'[1,1])
            local lr_neg_se = sqrt(`lr_V'[2,2])
            local lr_pos_t = `lr_pos' / `lr_pos_se'
            local lr_neg_t = `lr_neg' / `lr_neg_se'
            local lr_pos_p = 2 * ttail(`saved_df_r', abs(`lr_pos_t'))
            local lr_neg_p = 2 * ttail(`saved_df_r', abs(`lr_neg_t'))

            di as txt ""
            di as txt "  Variable: `cname' (decomposed)"
            di as txt "  {hline 68}"
            di as txt "  " _col(5) "Component" _col(20) "Estimate" _col(32) "Std.Err." _col(44) "t-stat" _col(54) "p-value"
            di as txt "  {hline 68}"
            di as res "  " _col(5) "Short-Run (+)" _col(18) %10.4f `sr_pos'
            di as res "  " _col(5) "Short-Run (-)" _col(18) %10.4f `sr_neg'
            di as txt "  " _col(5) "{hline 58}"
            di as txt "  " _col(5) "Long-Run  (+)" _col(18) %10.4f `lr_pos' _col(30) %10.4f `lr_pos_se' _col(42) %8.3f `lr_pos_t' _col(52) %8.4f `lr_pos_p' _c
            _fbnardl_stars `lr_pos_p'
            di as txt "  " _col(5) "Long-Run  (-)" _col(18) %10.4f `lr_neg' _col(30) %10.4f `lr_neg_se' _col(42) %8.3f `lr_neg_t' _col(52) %8.4f `lr_neg_p' _c
            _fbnardl_stars `lr_neg_p'
            di as txt "  {hline 68}"
            if `sr_neg' != 0 {
                local sr_ratio = abs(`sr_pos' / `sr_neg')
                di as txt "  " _col(5) "SR Asymmetry |SR(+)/SR(-)|" _col(38) "= " as res %6.3f `sr_ratio'
            }
            if `lr_neg' != 0 {
                local lr_ratio = abs(`lr_pos' / `lr_neg')
                di as txt "  " _col(5) "LR Asymmetry |LR(+)/LR(-)|" _col(38) "= " as res %6.3f `lr_ratio'
            }

            // Store for ereturn
            local lr_pos_`cname' = `lr_pos'
            local lr_neg_`cname' = `lr_neg'
            local lr_pos_se_`cname' = `lr_pos_se'
            local lr_neg_se_`cname' = `lr_neg_se'
        }
        else {
            di as err "  Warning: Could not compute long-run multipliers for `cname'"
        }

        // Restore full model estimates
        qui regress D.`depvar' `best_formula'
    }

    // Short-run & long-run multipliers for non-decomposed controls
    if `nctrl' > 0 {
        local ctrl_i = 0
        foreach cvar of local controls {
            local ctrl_i = `ctrl_i' + 1
            local this_r = `best_r_`ctrl_i''
            local lcvar_name "L.`cvar'"
            local saved_df_r_sr = e(df_r)

            // Short-Run: SR = sum of all D.cvar coefficients (j=0..r)
            local sr_ctrl = 0
            local sr_ctrl_se = .
            local sr_ctrl_t = .
            local sr_ctrl_p = .

            if `this_r' == 0 {
                // Simple case: only contemporaneous D.cvar
                capture local sr_ctrl = _b[D.`cvar']
                if _rc == 0 {
                    local sr_ctrl_se = _se[D.`cvar']
                    local sr_ctrl_t = `sr_ctrl' / `sr_ctrl_se'
                    local sr_ctrl_p = 2 * ttail(`saved_df_r_sr', abs(`sr_ctrl_t'))
                }
            }
            else {
                // Sum of lagged coefficients: use lincom
                local lincom_expr "D.`cvar'"
                forvalues j = 1/`this_r' {
                    local lincom_expr "`lincom_expr' + L`j'.D.`cvar'"
                }
                capture qui lincom `lincom_expr'
                if _rc == 0 {
                    local sr_ctrl = r(estimate)
                    local sr_ctrl_se = r(se)
                    local sr_ctrl_t = `sr_ctrl' / `sr_ctrl_se'
                    local sr_ctrl_p = 2 * ttail(`saved_df_r_sr', abs(`sr_ctrl_t'))
                }
            }

            // Long-Run (delta method)
            local saved_df_r = e(df_r)
            capture qui nlcom ///
                (LR: -_b[`lcvar_name'] / _b[`ecm_coef_name']), ///
                level(`level') post

            if _rc == 0 {
                tempname lr_ctrl_b lr_ctrl_V
                mat `lr_ctrl_b' = e(b)
                mat `lr_ctrl_V' = e(V)
                local lr_ctrl = `lr_ctrl_b'[1,1]
                local lr_ctrl_se = sqrt(`lr_ctrl_V'[1,1])
                local lr_ctrl_t = `lr_ctrl' / `lr_ctrl_se'
                local lr_ctrl_p = 2 * ttail(`saved_df_r', abs(`lr_ctrl_t'))

                di as txt ""
                di as txt "  Variable: `cvar' (non-decomposed)"
                di as txt "  {hline 68}"
                di as txt "  " _col(5) "Component" _col(20) "Estimate" _col(32) "Std.Err." _col(44) "t-stat" _col(54) "p-value"
                di as txt "  {hline 68}"
                if `sr_ctrl_se' < . {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl' _col(30) %10.4f `sr_ctrl_se' _col(42) %8.3f `sr_ctrl_t' _col(52) %8.4f `sr_ctrl_p' _c
                    _fbnardl_stars `sr_ctrl_p'
                }
                else {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl'
                }
                di as txt "  " _col(5) "{hline 58}"
                di as txt "  " _col(5) "Long-Run" _col(18) %10.4f `lr_ctrl' _col(30) %10.4f `lr_ctrl_se' _col(42) %8.3f `lr_ctrl_t' _col(52) %8.4f `lr_ctrl_p' _c
                _fbnardl_stars `lr_ctrl_p'
                di as txt "  {hline 68}"
            }
            qui regress D.`depvar' `best_formula'
        }
    }

    di as txt ""
    di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 10. WALD TESTS FOR ASYMMETRY
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 4: Wald Tests for Asymmetry"
    di as txt "{hline 70}"

    foreach cname of local dec_names {
        di as txt ""
        di as txt "  Variable: `cname'"
        di as txt "  {hline 60}"

        // Short-run asymmetry: test D.xpos = D.xneg (contemporaneous)
        capture qui test D.`cname'_pos = D.`cname'_neg
        if _rc == 0 {
            local wald_sr_f = r(F)
            local wald_sr_p = r(p)
            di as txt "  Short-run asymmetry: F = " %8.4f `wald_sr_f' "  p-value = " %6.4f `wald_sr_p' _c
            _fbnardl_stars `wald_sr_p'
        }
        else {
            di as txt "  Short-run asymmetry: not estimable"
            local wald_sr_f = .
            local wald_sr_p = .
        }

        // Long-run asymmetry: test LR_pos = LR_neg via testnl
        local lpos_name "L.`cname'_pos"
        local lneg_name "L.`cname'_neg"
        capture qui testnl _b[`lpos_name']/_b[`ecm_coef_name'] = _b[`lneg_name']/_b[`ecm_coef_name']
        if _rc == 0 {
            local wald_lr_chi2 = r(chi2)
            local wald_lr_p = r(p)
            di as txt "  Long-run asymmetry:  Chi2 = " %8.4f `wald_lr_chi2' "  p-value = " %6.4f `wald_lr_p' _c
            _fbnardl_stars `wald_lr_p'
        }
        else {
            di as txt "  Long-run asymmetry:  not estimable"
        }
        di as txt "  {hline 60}"
    }
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 11. BOUNDS / BOOTSTRAP COINTEGRATION TEST
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 5: Cointegration Test"
    di as txt "{hline 70}"

    // Compute F-test for joint significance of lagged levels (Fov)
    // H0: a_yy = 0 AND a_y.x = 0 for all decomposed and controls
    local levels_test "`ecm_coef_name'"
    foreach cname of local dec_names {
        local levels_test "`levels_test' L.`cname'_pos L.`cname'_neg"
    }
    foreach cvar of local controls {
        local levels_test "`levels_test' L.`cvar'"
    }

    // Overall F-test (Fov)
    capture qui test `levels_test'
    local Fov = r(F)
    local Fov_df1 = r(df)
    local Fov_df2 = r(df_r)
    local Fov_p = r(p)

    // t-test on lagged dependent (for degenerate case #1)
    local t_dep = _b[`ecm_coef_name'] / _se[`ecm_coef_name']
    local t_dep_p = 2 * ttail(e(df_r), abs(`t_dep'))

    // F-test on lagged independent variables (Find) — for degenerate case #2
    local indep_levels_test ""
    foreach cname of local dec_names {
        local indep_levels_test "`indep_levels_test' L.`cname'_pos L.`cname'_neg"
    }
    foreach cvar of local controls {
        local indep_levels_test "`indep_levels_test' L.`cvar'"
    }
    capture qui test `indep_levels_test'
    local Find = r(F)
    local Find_df1 = r(df)
    local Find_p = r(p)

    if "`type'" == "fnardl" {
        // ----- Kripfganz & Schneider Critical Values -----
        di as txt ""
        di as txt "  Method: PSS Bounds Testing (Pesaran, Shin & Smith, 2001)"
        di as txt "  Critical Values: Kripfganz & Schneider (2020)"
        di as txt "  Ref: Kripfganz, S. & Schneider, D.C. (2020). Response surface"
        di as txt "       regressions for critical value bounds and approximate"
        di as txt "       p-values in equilibrium correction models. Oxford"
        di as txt "       Bulletin of Economics and Statistics, 82(6), 1456-1481."
        di as txt ""
        di as txt "  {hline 60}"
        di as txt "  " _col(5) "Test" _col(25) "Statistic" _col(39) "p-value"
        di as txt "  {hline 60}"
        di as txt "  " _col(5) "F_overall (Fov)" _col(23) %10.4f `Fov' _col(37) %8.4f `Fov_p'
        di as txt "  " _col(5) "t_dependent" _col(23) %10.4f `t_dep' _col(37) %8.4f `t_dep_p'
        di as txt "  " _col(5) "F_independent (Find)" _col(23) %10.4f `Find' _col(37) %8.4f `Find_p'
        di as txt "  {hline 60}"
        di as txt ""

        // Count number of long-run forcing variables for ardl bounds test
        // = number of lagged level regressors excluding y_{t-1}
        local n_lr_vars = 2 * `ndec' + `nctrl'

        // Try ardl bounds test for proper critical values
        di as txt "  PSS Bounds Test Critical Values (case III):"
        di as txt "  Number of long-run forcing variables (k) = `n_lr_vars'"
        di as txt ""

        // Approximate critical values from PSS (2001) Table CI(iii)
        // For 10%, 5%, 1% significance levels
        // We provide approximate values; exact values depend on k
        di as txt "  {hline 60}"
        di as txt "  " _col(5) "Signif." _col(18) "I(0) Bound" _col(35) "I(1) Bound" _col(50) "Decision"
        di as txt "  {hline 60}"

        // Use approximate PSS critical values for common k values
        _fbnardl_pss_cv `n_lr_vars' `Fov' `nobs_used'

        di as txt "  {hline 60}"
        di as txt ""
        di as txt "  Note: For exact critical values, use -ardl- package with"
        di as txt "        -estat ectest- (Kripfganz & Schneider 2020)"
        di as txt ""
        di as txt "  {it:For bootstrap critical values (Bertelli, Vacca & Zoia, 2022),}"
        di as txt "  {it:use option: type(fbnardl)}"
    }
    else {
        // ----- Bootstrap Critical Values (Bertelli et al. 2022) -----
        di as txt ""
        di as txt "  Method: Bootstrap Cointegration Test"
        di as txt "  Ref: Bertelli, S., Vacca, G. & Zoia, M.G. (2022). Bootstrap"
        di as txt "       cointegration tests in ARDL models. Statistical Methods"
        di as txt "       & Applications, 31, 1231-1268."
        di as txt "  See also: McNown, R., Sam, C.Y. & Goh, S.K. (2018). Bootstrapping"
        di as txt "       the autoregressive distributed lag test for cointegration."
        di as txt "       Applied Economics, 50(13), 1509-1521."
        di as txt "  Bootstrap replications: `reps'"
        di as txt ""
        di as txt "  Computing bootstrap distributions..."

        // Call bootstrap subroutine
        // Mata's st_data/st_store don't support TS operators (D., L.),
        // so pre-generate all TS-operator variables as plain named vars
        capture drop _fbnardl_dy
        qui gen double _fbnardl_dy = D.`depvar'

        // Build plain-name formula from best_formula
        // Replace each TS-operator token with a generated plain variable
        local plain_formula ""
        local plain_levels ""
        local plain_indep ""
        local vnum = 0
        foreach v of local best_formula {
            local vnum = `vnum' + 1
            // Generate plain variable from TS expression
            capture drop _fbnardl_v`vnum'
            qui gen double _fbnardl_v`vnum' = `v'
            local plain_formula "`plain_formula' _fbnardl_v`vnum'"

            // Map levels_test vars to plain names
            foreach lv of local levels_test {
                if "`v'" == "`lv'" {
                    local plain_levels "`plain_levels' _fbnardl_v`vnum'"
                }
            }
            // Map indep_levels_test vars to plain names
            foreach iv of local indep_levels_test {
                if "`v'" == "`iv'" {
                    local plain_indep "`plain_indep' _fbnardl_v`vnum'"
                }
            }
        }

        // Find plain name for ECM coefficient (L.depvar)
        local plain_ecm ""
        local vnum2 = 0
        foreach v of local best_formula {
            local vnum2 = `vnum2' + 1
            if "`v'" == "`ecm_coef_name'" {
                local plain_ecm "_fbnardl_v`vnum2'"
            }
        }

        _fbnardl_bootstrap _fbnardl_dy `plain_formula', ///
            depvar(`depvar') ///
            decnames(`dec_names')  ///
            ecmcoef(`plain_ecm') ///
            levelsvars(`plain_levels') ///
            indepvars(`plain_indep') ///
            reps(`reps') ///
            nobs(`nobs_used') ///
            `= cond(`nctrl' > 0, "controls(`controls')", "")'

        local bs_Fov_cv10 = r(Fov_cv10)
        local bs_Fov_cv05 = r(Fov_cv05)
        local bs_Fov_cv01 = r(Fov_cv01)
        local bs_t_cv10 = r(t_cv10)
        local bs_t_cv05 = r(t_cv05)
        local bs_t_cv01 = r(t_cv01)
        local bs_Find_cv10 = r(Find_cv10)
        local bs_Find_cv05 = r(Find_cv05)
        local bs_Find_cv01 = r(Find_cv01)
        local bs_Fov_pval = r(Fov_pval)
        local bs_t_pval = r(t_pval)
        local bs_Find_pval = r(Find_pval)

        // Clean up temporary bootstrap variables
        capture drop _fbnardl_dy
        capture drop _fbnardl_v*

        // Restore full model estimation
        qui regress D.`depvar' `best_formula'

        di as txt ""
        di as txt "  {hline 65}"
        di as txt "  " _col(3) "Test" _col(22) "Stat" _col(33) "CV(10%)" _col(43) "CV(5%)" _col(53) "CV(1%)" _col(62) "p-val"
        di as txt "  {hline 65}"
        di as txt "  " _col(3) "F_overall" _col(20) %8.3f `Fov' _col(31) %8.3f `bs_Fov_cv10' _col(41) %8.3f `bs_Fov_cv05' _col(51) %8.3f `bs_Fov_cv01' _col(60) %6.4f `bs_Fov_pval' _c
        _fbnardl_stars `bs_Fov_pval'
        di as txt "  " _col(3) "t_dependent" _col(20) %8.3f `t_dep' _col(31) %8.3f `bs_t_cv10' _col(41) %8.3f `bs_t_cv05' _col(51) %8.3f `bs_t_cv01' _col(60) %6.4f `bs_t_pval' _c
        _fbnardl_stars `bs_t_pval'
        di as txt "  " _col(3) "F_independent" _col(20) %8.3f `Find' _col(31) %8.3f `bs_Find_cv10' _col(41) %8.3f `bs_Find_cv05' _col(51) %8.3f `bs_Find_cv01' _col(60) %6.4f `bs_Find_pval' _c
        _fbnardl_stars `bs_Find_pval'
        di as txt "  {hline 65}"
        di as txt ""

        // Decision
        di as txt "  Decision at 5% level:"
        if `bs_Fov_pval' < 0.05 {
            di as res "    Fov: Reject H0 => Evidence of a long-run relationship"
        }
        else {
            di as res "    Fov: Fail to reject H0 => No evidence of long-run relationship"
        }
        if `bs_t_pval' < 0.05 {
            di as res "    t:   Reject H0 => Dependent variable participates in ECM"
            di as res "         (rules out degenerate case #1)"
        }
        else {
            di as res "    t:   Fail to reject H0 => Possible degenerate case #1"
        }
        if `bs_Find_pval' < 0.05 {
            di as res "    Find: Reject H0 => Independent variables enter long-run"
            di as res "          (rules out degenerate case #2)"
        }
        else {
            di as res "    Find: Fail to reject H0 => Possible degenerate case #2"
        }
    }

    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 12. DIAGNOSTIC TESTS
    // =========================================================================
    if "`nodiag'" == "" {
        // Restore best model
        qui regress D.`depvar' `best_formula'

        di as txt "{hline 70}"
        di as res "  Table 6: Diagnostic Tests"
        di as txt "{hline 70}"

        _fbnardl_diagtest `resid' `nobs_used' `nparams'
    }

    // =========================================================================
    // 13. DYNAMIC MULTIPLIERS
    // =========================================================================
    if "`nodynmult'" == "" {
        qui regress D.`depvar' `best_formula'

        // Pass max q across decomposed vars (dynmult uses capture for missing lags)
        local max_q = 0
        forvalues di = 1/`ndec' {
            if `best_q_`di'' > `max_q' local max_q = `best_q_`di''
        }
        // Pass max r across control vars
        local max_r = 0
        if `nctrl' > 0 {
            forvalues ci = 1/`nctrl' {
                if `best_r_`ci'' > `max_r' local max_r = `best_r_`ci''
            }
        }
        _fbnardl_dynmult, depvar(`depvar') decnames(`dec_names') ///
            ecmcoef(`ecm_coef_name') p(`best_p') q(`max_q') ///
            horizon(`horizon') ///
            `= cond(`nctrl' > 0, "controls(`controls') r(`max_r')", "")'
    }

    // =========================================================================
    // 14. ADVANCED POST-ESTIMATION ANALYSES
    // =========================================================================
    if "`noadvanced'" == "" {
        qui regress D.`depvar' `best_formula'

        // Pass max q across decomposed vars
        local max_q = 0
        forvalues di = 1/`ndec' {
            if `best_q_`di'' > `max_q' local max_q = `best_q_`di''
        }
        _fbnardl_advanced, depvar(`depvar') decnames(`dec_names') ///
            ecmcoef(`ecm_coef_name') p(`best_p') q(`max_q') ///
            horizon(`horizon') best_kstar(`best_kstar') ///
            `= cond("`nofourier'" != "", "nofourier", "")' ///
            `= cond(`nctrl' > 0, "controls(`controls')", "")'
    }

    // =========================================================================
    // 15. STORE e() RESULTS
    // =========================================================================
    // Re-estimate to capture b and V matrices before restore destroys data
    qui regress D.`depvar' `best_formula'

    tempname b_post V_post
    mat `b_post' = e(b)
    mat `V_post' = e(V)
    local nobs_post = e(N)
    local df_r_post = e(df_r)
    local rmse_post = e(rmse)

    // Restore original data FIRST, then post results
    restore

    // Post e(b) and e(V) to ereturn (this survives restore)
    ereturn post `b_post' `V_post', obs(`nobs_post') depname(D.`depvar')

    // Augment ereturn with additional scalars
    ereturn scalar best_p = `best_p'
    // Store variable-specific lag orders (PSS notation)
    forvalues di = 1/`ndec' {
        local cname : word `di' of `dec_names'
        ereturn scalar best_q_`cname' = `best_q_`di''
    }
    ereturn scalar best_kstar = `best_kstar'
    ereturn scalar ic_val = scalar(`best_ic_val')
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar Fov = `Fov'
    ereturn scalar t_dep = `t_dep'
    ereturn scalar Find = `Find'
    ereturn scalar N = `nobs_post'
    ereturn scalar df_r = `df_r_post'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_adj'
    ereturn scalar F_model = `fstat'
    ereturn scalar rmse = `rmse_post'

    foreach cname of local dec_names {
        capture ereturn scalar lr_pos_`cname' = `lr_pos_`cname''
        capture ereturn scalar lr_neg_`cname' = `lr_neg_`cname''
    }

    if "`type'" == "fbnardl" {
        ereturn scalar bs_Fov_cv05 = `bs_Fov_cv05'
        ereturn scalar bs_t_cv05 = `bs_t_cv05'
        ereturn scalar bs_Find_cv05 = `bs_Find_cv05'
        ereturn scalar bs_Fov_pval = `bs_Fov_pval'
        ereturn scalar bs_t_pval = `bs_t_pval'
        ereturn scalar bs_Find_pval = `bs_Find_pval'
    }

    // Macros
    ereturn local cmd "fbnardl"
    ereturn local cmdline "fbnardl `0'"
    ereturn local type "`type'"
    ereturn local depvar "`depvar'"
    ereturn local decompose "`decompose'"
    ereturn local controls "`controls'"
    ereturn local ic "`ic'"
    ereturn local dec_names "`dec_names'"
    di as txt "{hline 70}"
    di as res "  References"
    di as txt "{hline 70}"
    di as txt "  Shin, Yu & Greenwood-Nimmo (2014). Modelling asymmetric cointegration"
    di as txt "    and dynamic multipliers in a nonlinear ARDL framework."
    di as txt "  Pesaran, Shin & Smith (2001). Bounds testing approaches to the"
    di as txt "    analysis of level relationships. JASA, 16(3), 289-326."
    if "`type'" == "fnardl" {
        di as txt "  Kripfganz & Schneider (2020). Response surface regressions for"
        di as txt "    critical value bounds. Oxford Bull. Econ. Stat., 82(6)."
    }
    else {
        di as txt "  Bertelli, Vacca & Zoia (2022). Bootstrap cointegration tests"
        di as txt "    in ARDL models. Stat. Methods & Applications, 31, 1231-1268."
        di as txt "  McNown, Sam & Goh (2018). Bootstrapping the ARDL test for"
        di as txt "    cointegration. Applied Economics, 50(13), 1509-1521."
    }
    if "`nofourier'" == "" {
        di as txt "  Yilanci, Bozoklu & Gorus (2020). Fourier ARDL approach."
        di as txt "    Evaluation Review, 44(5-6), 431-450."
    }
    di as txt "{hline 70}"

    // Final message
    di as txt "{hline 70}"
    di as res "  Estimation complete. Results stored in e()."
    di as txt "  Type {cmd:ereturn list} to view stored results."
    di as txt "{hline 70}"

end


// =============================================================================
// HELPER: Display significance stars
// =============================================================================
capture program drop _fbnardl_stars
program define _fbnardl_stars
    version 17
    args pval
    if `pval' < 0.001 {
        di as res " ***"
    }
    else if `pval' < 0.01 {
        di as res " **"
    }
    else if `pval' < 0.05 {
        di as res " *"
    }
    else if `pval' < 0.1 {
        di as res " ."
    }
    else {
        di as txt ""
    }
end


// =============================================================================
// HELPER: Approximate PSS Critical Values
// =============================================================================
capture program drop _fbnardl_pss_cv
program define _fbnardl_pss_cv
    version 17
    args k Fstat nobs

    // Approximate PSS (2001) Table CI(iii) — Case III (unrestricted intercept, no trend)
    // Critical values for F-test depend on k (number of long-run forcing variables)
    // These are approximate; for exact values use ardl + estat ectest

    // I(0) bounds (lower)
    if `k' == 1 {
        local lb10 = 4.04
        local lb05 = 4.94
        local lb01 = 6.84
    }
    else if `k' == 2 {
        local lb10 = 3.17
        local lb05 = 3.79
        local lb01 = 5.15
    }
    else if `k' == 3 {
        local lb10 = 2.72
        local lb05 = 3.23
        local lb01 = 4.29
    }
    else if `k' == 4 {
        local lb10 = 2.45
        local lb05 = 2.86
        local lb01 = 3.74
    }
    else if `k' == 5 {
        local lb10 = 2.26
        local lb05 = 2.62
        local lb01 = 3.41
    }
    else if `k' == 6 {
        local lb10 = 2.12
        local lb05 = 2.45
        local lb01 = 3.15
    }
    else if `k' == 7 {
        local lb10 = 2.03
        local lb05 = 2.32
        local lb01 = 2.96
    }
    else {
        local lb10 = 1.95
        local lb05 = 2.22
        local lb01 = 2.79
    }

    // I(1) bounds (upper)
    if `k' == 1 {
        local ub10 = 4.78
        local ub05 = 5.73
        local ub01 = 7.84
    }
    else if `k' == 2 {
        local ub10 = 4.14
        local ub05 = 4.85
        local ub01 = 6.36
    }
    else if `k' == 3 {
        local ub10 = 3.77
        local ub05 = 4.35
        local ub01 = 5.61
    }
    else if `k' == 4 {
        local ub10 = 3.52
        local ub05 = 4.01
        local ub01 = 5.06
    }
    else if `k' == 5 {
        local ub10 = 3.35
        local ub05 = 3.79
        local ub01 = 4.68
    }
    else if `k' == 6 {
        local ub10 = 3.22
        local ub05 = 3.61
        local ub01 = 4.43
    }
    else if `k' == 7 {
        local ub10 = 3.13
        local ub05 = 3.50
        local ub01 = 4.26
    }
    else {
        local ub10 = 3.06
        local ub05 = 3.39
        local ub01 = 4.10
    }

    // Display
    foreach slev in 10 05 01 {
        if "`slev'" == "10" local slabel "10%"
        if "`slev'" == "05" local slabel " 5%"
        if "`slev'" == "01" local slabel " 1%"

        local lb = `lb`slev''
        local ub = `ub`slev''

        if `Fstat' > `ub' {
            local decision "Reject H0"
        }
        else if `Fstat' < `lb' {
            local decision "Fail to Reject"
        }
        else {
            local decision "Inconclusive"
        }

        di as txt "  " _col(5) "`slabel'" _col(18) %8.3f `lb' _col(35) %8.3f `ub' _col(50) "`decision'"
    }
end
