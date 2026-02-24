*! aardl — Augmented ARDL Cointegration Analysis (8 Models)
*! Version 1.1.0 — 2026-02-23
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Models:
*!   type(aardl)    — Augmented ARDL (Sam, McNown & Goh, 2019)
*!   type(baardl)   — Bootstrap Augmented ARDL
*!   type(faardl)   — Fourier Augmented ARDL
*!   type(fbaardl)  — Fourier Bootstrap Augmented ARDL
*!   type(nardl)    — Augmented NARDL (asymptotic)
*!   type(fanardl)  — Fourier Augmented NARDL
*!   type(banardl)  — Bootstrap Augmented NARDL
*!   type(fbanardl) — Fourier Bootstrap Augmented NARDL
*!
*! References:
*!   Sam, McNown & Goh (2019)          — Augmented ARDL bounds test
*!   McNown, Sam & Goh (2018)          — Bootstrap ARDL (unconditional)
*!   Bertelli, Vacca & Zoia (2022)     — Bootstrap ARDL (conditional)
*!   Yilanci, Bozoklu & Gorus (2020)   — Fourier ARDL approach
*!   Shin, Yu & Greenwood-Nimmo (2014) — Nonlinear ARDL
*!   Kripfganz & Schneider (2020)      — ARDL bounds critical values
*!   Pesaran, Shin & Smith (2001)      — ARDL bounds testing

capture program drop aardl
program define aardl, eclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=2 ts fv) [if] [in], ///
        [                                   ///
        TYpe(string)                        /// model type (default: aardl)
        DECompose(varlist ts)               /// NARDL decompose variables
        MAXLag(integer 4)                   /// max lag order (default: 4)
        MAXk(real 3)                        /// max Fourier frequency (default: 3)
        IC(string)                          /// aic or bic (default: bic)
        REPS(integer 999)                   /// bootstrap replications
        Level(cilevel)                      /// confidence level (default: 95)
        HORizon(integer 20)                 /// multiplier horizon
        NOFourier                           /// suppress Fourier terms
        NODIag                              /// suppress diagnostics
        NODYNmult                           /// suppress dynamic multipliers
        NOADVanced                          /// suppress advanced analyses
        NOTable                             /// suppress coefficient table
        NOHEader                            /// suppress header
        NOGraph                             /// suppress graphs
        case(integer 3)                     /// PSS case (1,2,3,4,5)
        Bootstrap(string)                   /// mcnown or bvz (default: bvz)
        ]

    // Mark estimation sample
    marksample touse
    if "`decompose'" != "" {
        markout `touse' `decompose'
    }

    // ─── Default type ───
    if "`type'" == "" local type "aardl"
    local type = lower("`type'")
    if !inlist("`type'", "aardl", "baardl", "faardl", "fbaardl", "nardl", "fanardl", "banardl", "fbanardl") {
        di as err "type() must be one of: aardl, baardl, faardl, fbaardl, nardl, fanardl, banardl, fbanardl"
        exit 198
    }

    // ─── Determine model features ───
    local is_nardl = inlist("`type'", "nardl", "fanardl", "banardl", "fbanardl")
    local has_bootstrap = inlist("`type'", "baardl", "fbaardl", "banardl", "fbanardl")
    local has_fourier = inlist("`type'", "faardl", "fbaardl", "fanardl", "fbanardl")

    // Override nofourier for non-Fourier types
    if !`has_fourier' {
        local nofourier "nofourier"
    }

    // Validate NARDL requires decompose()
    if `is_nardl' & "`decompose'" == "" {
        di as err "NARDL models (nardl, fanardl, banardl, fbanardl) require decompose() option"
        exit 198
    }
    if !`is_nardl' & "`decompose'" != "" {
        di as err "decompose() is only for NARDL models (nardl, fanardl, banardl, fbanardl)"
        exit 198
    }

    // Validate IC — BIC is default (same as ardl package)
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }

    // Validate bootstrap method
    if "`bootstrap'" == "" local bootstrap "bvz"
    local bootstrap = lower("`bootstrap'")
    if !inlist("`bootstrap'", "mcnown", "bvz") {
        di as err "bootstrap() must be {bf:mcnown} or {bf:bvz}"
        exit 198
    }

    // Validate maxlag & case
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }
    if !inlist(`case', 1, 2, 3, 4, 5) {
        di as err "case() must be 1, 2, 3, 4, or 5"
        exit 198
    }

    // =========================================================================
    // 2. PARSE VARIABLE LISTS
    // =========================================================================
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'

    if `nindep' < 1 {
        di as err "at least one independent variable required"
        exit 198
    }

    // Confirm time series
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "aardl is designed for time-series data only, not panel data"
        exit 198
    }

    // =========================================================================
    // 3. PRESERVE & PREPARE DATA
    // =========================================================================
    preserve

    qui keep if `touse'
    qui count
    local T = r(N)

    if `T' < 30 {
        di as err "Too few observations (`T'). Need at least 30."
        exit 2001
    }

    // Time index
    tempvar tindex
    qui gen `tindex' = _n

    // =========================================================================
    // 4. NARDL DECOMPOSITION (if applicable)
    //    Shin, Yu & Greenwood-Nimmo (2014):
    //    x+ = cumsum(max(Δx, 0));  x- = cumsum(min(Δx, 0))
    // =========================================================================
    local dec_pos_vars ""
    local dec_neg_vars ""
    local dec_names ""
    local all_indepvars ""   // final list of regressors (may include pos/neg)
    local ctrl_vars ""

    if `is_nardl' {
        foreach xvar of local decompose {
            local cname = subinstr("`xvar'", ".", "_", .)
            tempvar dx_`cname' xpos_`cname' xneg_`cname'

            qui gen double `dx_`cname'' = D.`xvar'

            // Positive partial sum: Σ max(Δx, 0)
            qui gen double `xpos_`cname'' = 0
            qui replace `xpos_`cname'' = max(`dx_`cname'', 0) if `dx_`cname'' != .
            qui replace `xpos_`cname'' = sum(`xpos_`cname'')

            // Negative partial sum: Σ min(Δx, 0)
            qui gen double `xneg_`cname'' = 0
            qui replace `xneg_`cname'' = min(`dx_`cname'', 0) if `dx_`cname'' != .
            qui replace `xneg_`cname'' = sum(`xneg_`cname'')

            local pname "`cname'_pos"
            local nname "`cname'_neg"
            qui rename `xpos_`cname'' `pname'
            qui rename `xneg_`cname'' `nname'

            local dec_pos_vars "`dec_pos_vars' `pname'"
            local dec_neg_vars "`dec_neg_vars' `nname'"
            local dec_names "`dec_names' `cname'"
            local all_indepvars "`all_indepvars' `pname' `nname'"
        }

        // Non-decomposed independent variables are controls
        foreach xvar of local indepvars {
            local is_dec = 0
            foreach dvar of local decompose {
                if "`xvar'" == "`dvar'" local is_dec = 1
            }
            if !`is_dec' {
                local ctrl_vars "`ctrl_vars' `xvar'"
                local all_indepvars "`all_indepvars' `xvar'"
            }
        }
    }
    else {
        local all_indepvars "`indepvars'"
    }

    local nall : word count `all_indepvars'
    local nctrl : word count `ctrl_vars'

    // For ardlbounds: k = number of long-run independent variables
    local k_cv = `nall'

    // =========================================================================
    // 5. MODEL HEADER
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    if "`type'" == "aardl" {
        di as res _col(3) "  Augmented ARDL (A-ARDL) — Sam, McNown & Goh (2019)"
    }
    else if "`type'" == "baardl" {
        di as res _col(3) "  Bootstrap Augmented ARDL (BA-ARDL)"
    }
    else if "`type'" == "faardl" {
        di as res _col(3) "  Fourier Augmented ARDL (FA-ARDL)"
    }
    else if "`type'" == "fbaardl" {
        di as res _col(3) "  Fourier Bootstrap Augmented ARDL (FBA-ARDL)"
    }
    else if "`type'" == "nardl" {
        di as res _col(3) "  Augmented NARDL (A-NARDL) — Shin, Yu & Greenwood-Nimmo (2014)"
    }
    else if "`type'" == "fanardl" {
        di as res _col(3) "  Fourier Augmented NARDL (FA-NARDL)"
    }
    else if "`type'" == "banardl" {
        di as res _col(3) "  Bootstrap Augmented NARDL (BA-NARDL)"
    }
    else if "`type'" == "fbanardl" {
        di as res _col(3) "  Fourier Bootstrap Augmented NARDL (FBA-NARDL)"
    }
    di as txt "{hline 78}"
    di as txt _col(5) "Dependent variable  : " as res "`depvar'"
    if `is_nardl' {
        di as txt _col(5) "Decomposed var(s)   : " as res "`decompose'"
        if `nctrl' > 0 {
            di as txt _col(5) "Control var(s)      : " as res "`ctrl_vars'"
        }
    }
    else {
        di as txt _col(5) "Independent var(s)  : " as res "`indepvars'"
    }
    di as txt _col(5) "Sample size (T)     : " as res "`T'"
    di as txt _col(5) "Max lag order       : " as res "`maxlag'"
    if `has_fourier' {
        di as txt _col(5) "Max Fourier freq.   : " as res "`maxk'"
    }
    di as txt _col(5) "Info criterion      : " as res upper("`ic'")
    di as txt _col(5) "PSS Case            : " as res "Case `case'"
    if `has_bootstrap' {
        local bmethod "Bertelli, Vacca & Zoia (2022)"
        if "`bootstrap'" == "mcnown" local bmethod "McNown, Sam & Goh (2018)"
        di as txt _col(5) "Bootstrap method    : " as res "`bmethod'"
        di as txt _col(5) "Bootstrap reps      : " as res "`reps'"
    }
    di as txt "{hline 78}"
    di as txt ""

    // =========================================================================
    // 6. FOURIER FREQUENCY SELECTION (Step 1)
    //    Yilanci, Bozoklu & Gorus (2020):
    //    k* in {0.1, 0.2, ..., maxk}, selected by minimum SSR from maximal model
    // =========================================================================
    local best_kstar = 0

    if `has_fourier' {
        di as txt _col(3) "Step 1: Selecting Fourier frequency k* by minimum SSR..."

        local nkgrid = round(`maxk' / 0.1)
        tempname kgrid ssr_matrix best_ssr_k
        mat `kgrid' = J(1, `nkgrid', .)
        forvalues i = 1/`nkgrid' {
            mat `kgrid'[1, `i'] = `i' * 0.1
        }
        scalar `best_ssr_k' = .
        mat `ssr_matrix' = J(`nkgrid', 2, .)

        forvalues kidx = 1/`nkgrid' {
            local kval = `kgrid'[1, `kidx']
            mat `ssr_matrix'[`kidx', 1] = `kval'

            capture drop _aardl_sin _aardl_cos
            qui gen double _aardl_sin = sin(2 * c(pi) * `kval' * `tindex' / `T')
            qui gen double _aardl_cos = cos(2 * c(pi) * `kval' * `tindex' / `T')

            // Build maximal regression
            local regvars_max ""

            // Lagged levels (ECM terms)
            local regvars_max "L.`depvar'"
            foreach xvar of local all_indepvars {
                local regvars_max "`regvars_max' L.`xvar'"
            }

            // Lagged diffs of depvar
            forvalues j = 1/`maxlag' {
                local regvars_max "`regvars_max' L`j'.D.`depvar'"
            }

            // Contemp & lagged diffs of all indepvars
            foreach xvar of local all_indepvars {
                forvalues j = 0/`maxlag' {
                    if `j' == 0 {
                        local regvars_max "`regvars_max' D.`xvar'"
                    }
                    else {
                        local regvars_max "`regvars_max' L`j'.D.`xvar'"
                    }
                }
            }

            // Fourier terms
            local regvars_max "`regvars_max' _aardl_sin _aardl_cos"

            capture qui regress D.`depvar' `regvars_max'
            if _rc != 0 {
                mat `ssr_matrix'[`kidx', 2] = .
                continue
            }

            local this_ssr = e(rss)
            mat `ssr_matrix'[`kidx', 2] = `this_ssr'

            if `this_ssr' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
                scalar `best_ssr_k' = `this_ssr'
                local best_kstar = `kval'
            }
        }

        di as txt _col(5) "Optimal k* = " as res "`best_kstar'" ///
           as txt " (min SSR = " as res %10.4f scalar(`best_ssr_k') as txt ")"

        // SSR vs k* Graph
        if "`nograph'" == "" & `nkgrid' > 1 {
            mat _aardl_ssr_k = `ssr_matrix'
            tempfile _aardl_tmpdata
            qui save `_aardl_tmpdata', replace

            capture noisily {
                qui clear
                qui set obs `nkgrid'
                qui gen double kstar = .
                qui gen double ssr = .

                forvalues kidx = 1/`nkgrid' {
                    qui replace kstar = el(_aardl_ssr_k, `kidx', 1) in `kidx'
                    qui replace ssr   = el(_aardl_ssr_k, `kidx', 2) in `kidx'
                }

                qui gen double ssr_opt = ssr if abs(kstar - `best_kstar') < 0.001

                twoway (connected ssr kstar, lcolor("31 119 180") mcolor("31 119 180") ///
                        msize(small) msymbol(circle) lwidth(medthick)) ///
                       (scatter ssr_opt kstar, mcolor("214 39 40") msize(large) ///
                        msymbol(diamond)), ///
                       title("Fourier Frequency Selection", size(medium)) ///
                       subtitle("SSR by k* {&mdash} Yilanci et al. (2020)", size(small)) ///
                       ytitle("Sum of Squared Residuals", size(small)) ///
                       xtitle("Fourier Frequency (k*)", size(small)) ///
                       xline(`best_kstar', lcolor("214 39 40") lpattern(dash)) ///
                       legend(order(1 "SSR" 2 "Optimal k* = `best_kstar'") ///
                              size(small) rows(1)) ///
                       scheme(s2color) name(aardl_kstar, replace)
            }

            qui use `_aardl_tmpdata', clear
            capture mat drop _aardl_ssr_k
        }
    }

    // Regenerate Fourier terms for best k*
    if `has_fourier' & `best_kstar' > 0 {
        capture drop _aardl_sin _aardl_cos
        qui gen double _aardl_sin = sin(2 * c(pi) * `best_kstar' * `tindex' / `T')
        qui gen double _aardl_cos = cos(2 * c(pi) * `best_kstar' * `tindex' / `T')
    }

    // =========================================================================
    // 7. LAG SELECTION (Step 2)
    //    Optimal ARDL(p, q1, ..., qk) by IC with variable-specific lags
    //    Following Kripfganz & Schneider (2020) / Pesaran, Shin & Smith (2001)
    // =========================================================================
    if `has_fourier' {
        di as txt _col(3) "Step 2: Selecting lag orders by " upper("`ic'") " with fixed k*..."
    }
    else {
        di as txt _col(3) "Selecting optimal lag orders by " upper("`ic'") "..."
    }

    tempname best_ic_val
    scalar `best_ic_val' = .

    local best_p = 1
    local best_formula ""
    local total_models = 0

    // Initialize best lags for each independent variable
    forvalues i = 1/`nall' {
        local best_q_`i' = 0
    }

    // Grid search over p and (q1, ..., q_nall)
    forvalues p = 1/`maxlag' {

        // Build all combinations of (q1,...,q_nall)
        local n_combos = 1
        forvalues vi = 1/`nall' {
            local n_combos = `n_combos' * (`maxlag' + 1)
        }

        local combo_max = `n_combos' - 1
        forvalues combo = 0/`combo_max' {

            local total_models = `total_models' + 1

            // Decode combo index into variable-specific lags
            local remainder = `combo'
            forvalues vi = 1/`nall' {
                local divisor = 1
                local remaining_vars = `nall' - `vi'
                if `remaining_vars' > 0 {
                    forvalues rv = 1/`remaining_vars' {
                        local divisor = `divisor' * (`maxlag' + 1)
                    }
                }
                local cur_q_`vi' = floor(`remainder' / `divisor')
                local remainder = `remainder' - `cur_q_`vi'' * `divisor'
            }

            // Build EC-form regression: D.y = ADJ(L.y) + LR(L.x_i) + SR(L.D.y, D.x_i) + Fourier
            local regvars ""
            local lrvars ""
            local srvars ""

            // (a) Long-run: Lagged levels (ECM terms)
            //     ADJ: L.depvar
            //     LR:  L.x1, L.x2, ...
            local regvars "L.`depvar'"
            local lrvars "L.`depvar'"
            local lrxvars ""

            foreach xvar of local all_indepvars {
                local regvars "`regvars' L.`xvar'"
                local lrvars "`lrvars' L.`xvar'"
                local lrxvars "`lrxvars' L.`xvar'"
            }

            // (b) Short-run: Lagged diffs of depvar: L1.D.y, L2.D.y, ...
            forvalues j = 1/`p' {
                local regvars "`regvars' L`j'.D.`depvar'"
                local srvars "`srvars' L`j'.D.`depvar'"
            }

            // (c) Short-run: Contemp & lagged diffs of each indepvar with its own q
            local vidx = 0
            foreach xvar of local all_indepvars {
                local vidx = `vidx' + 1
                local qi = `cur_q_`vidx''
                forvalues j = 0/`qi' {
                    if `j' == 0 {
                        local regvars "`regvars' D.`xvar'"
                        local srvars "`srvars' D.`xvar'"
                    }
                    else {
                        local regvars "`regvars' L`j'.D.`xvar'"
                        local srvars "`srvars' L`j'.D.`xvar'"
                    }
                }
            }

            // (d) Fourier terms
            if `has_fourier' & `best_kstar' > 0 {
                local regvars "`regvars' _aardl_sin _aardl_cos"
            }

            // Run regression
            capture qui regress D.`depvar' `regvars'
            if _rc != 0 continue
            if e(N) < e(df_m) + 10 continue

            // Compute IC (same formulas as ardl.ado)
            local this_n = e(N)
            local this_k = e(df_m) + 1
            local this_ll = e(ll)

            if "`ic'" == "aic" {
                local this_ic = -2 * `this_ll' + 2 * `this_k'
            }
            else {
                local this_ic = -2 * `this_ll' + `this_k' * ln(`this_n')
            }

            // Update best model
            if `this_ic' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                scalar `best_ic_val' = `this_ic'
                local best_p = `p'
                local best_formula "`regvars'"
                local best_srvars "`srvars'"
                forvalues vi = 1/`nall' {
                    local best_q_`vi' = `cur_q_`vi''
                }
            }

        } // end combo loop
    } // end p loop

    di as txt _col(5) "Models evaluated: " as res "`total_models'"
    di as txt _col(5) "Best " upper("`ic'") ": " as res %10.4f scalar(`best_ic_val')
    di as txt ""

    // =========================================================================
    // 8. FINAL ESTIMATION
    // =========================================================================
    qui regress D.`depvar' `best_formula'

    // Store for later
    estimates store _aardl_main

    local nobs = e(N)
    local df_m = e(df_m)
    local df_r = e(df_r)
    local r2 = e(r2)
    local r2_a = e(r2_a)
    local ll = e(ll)
    local mss = e(mss)
    local rss = e(rss)
    local rmse = e(rmse)
    local F_model = e(F)
    local F_model_p = Ftail(e(df_m), e(df_r), e(F))
    local nparams = e(df_m) + 1

    if "`ic'" == "aic" {
        local aic_val = -2 * `ll' + 2 * `nparams'
        local bic_val = -2 * `ll' + `nparams' * ln(`nobs')
    }
    else {
        local aic_val = -2 * `ll' + 2 * `nparams'
        local bic_val = -2 * `ll' + `nparams' * ln(`nobs')
    }

    // Store residuals
    tempvar resid yhat
    qui predict double `resid', residuals
    qui predict double `yhat', xb

    // ─── Reconstruct variable lists for the final model ───
    local lrvars "L.`depvar'"
    local lrxvars ""
    foreach xvar of local all_indepvars {
        local lrvars "`lrvars' L.`xvar'"
        local lrxvars "`lrxvars' L.`xvar'"
    }

    local srvars ""
    forvalues j = 1/`best_p' {
        local srvars "`srvars' L`j'.D.`depvar'"
    }
    local vidx = 0
    foreach xvar of local all_indepvars {
        local vidx = `vidx' + 1
        local q_this = `best_q_`vidx''
        forvalues j = 0/`q_this' {
            if `j' == 0 {
                local srvars "`srvars' D.`xvar'"
            }
            else {
                local srvars "`srvars' L`j'.D.`xvar'"
            }
        }
    }

    // =========================================================================
    // 9. COINTEGRATION TESTS — AUGMENTED 3-TEST FRAMEWORK
    //    Sam, McNown & Goh (2019)
    //    Test 1: F_overall — joint significance of all lagged levels
    //    Test 2: t_DV — significance of L.depvar
    //    Test 3: F_ind — significance of lagged independent levels
    // =========================================================================

    // F_overall: H0: pi_yy = 0, pi_yx = 0
    qui test `lrvars'
    local Fov = r(F)
    local Fov_p = r(p)

    // t_DV: t-statistic on L.depvar
    local t_DV = _b[L.`depvar'] / _se[L.`depvar']
    local ecm_coef = _b[L.`depvar']

    // F_ind: H0: pi_yx = 0 (independent levels only — THE AUGMENTATION)
    qui test `lrxvars'
    local Find = r(F)
    local Find_p = r(p)

    // =========================================================================
    // 10. BUILD EC FORM — ADJ/LR/SR EQUATION LABELS (like ardl.ado)
    //     Following Kripfganz & Schneider (2020):
    //     Long-run coefficients: beta_i = -b[L.x_i] / b[L.depvar]
    //     Computed via nlcom (delta method) for correct SE
    // =========================================================================

    // Build nlcom expression: ADJ + LR + SR
    local nlcom_exp ""
    local eqnames ""

    // ADJ: speed of adjustment (L.depvar coefficient as-is)
    local nlcom_exp "(L_`depvar': _b[L.`depvar'])"
    local eqnames "ADJ"

    // LR: long-run coefficients = -b[L.xvar] / b[L.depvar]
    foreach xvar of local all_indepvars {
        local cxvar = subinstr("`xvar'", ".", "_", .)
        local nlcom_exp "`nlcom_exp' (L_`cxvar': -_b[L.`xvar'] / _b[L.`depvar'])"
        local eqnames "`eqnames' LR"
    }

    // SR: short-run coefficients (pass through)
    forvalues j = 1/`best_p' {
        local nlcom_exp "`nlcom_exp' (L`j'D_`depvar': _b[L`j'.D.`depvar'])"
        local eqnames "`eqnames' SR"
    }

    local vidx = 0
    foreach xvar of local all_indepvars {
        local vidx = `vidx' + 1
        local q_this = `best_q_`vidx''
        local cxvar = subinstr("`xvar'", ".", "_", .)
        forvalues j = 0/`q_this' {
            if `j' == 0 {
                local nlcom_exp "`nlcom_exp' (D_`cxvar': _b[D.`xvar'])"
            }
            else {
                local nlcom_exp "`nlcom_exp' (L`j'D_`cxvar': _b[L`j'.D.`xvar'])"
            }
            local eqnames "`eqnames' SR"
        }
    }

    // Fourier terms in SR
    if `has_fourier' & `best_kstar' > 0 {
        local nlcom_exp "`nlcom_exp' (_aardl_sin: _b[_aardl_sin])"
        local nlcom_exp "`nlcom_exp' (_aardl_cos: _b[_aardl_cos])"
        local eqnames "`eqnames' SR SR"
    }

    // Constant in SR
    capture local _cons_b = _b[_cons]
    if _rc == 0 {
        local nlcom_exp "`nlcom_exp' (_cons: _b[_cons])"
        local eqnames "`eqnames' SR"
    }

    // Execute nlcom
    capture qui nlcom `nlcom_exp', level(`level') noheader iterate(1000)
    if _rc != 0 {
        di as err "nlcom failed. Long-run coefficients could not be computed."
        di as err "Consider rescaling variables if they are on very different scales."
        exit _rc
    }

    tempname b_ec V_ec
    mat `b_ec' = r(b)
    mat `V_ec' = r(V)

    // Fix column names: translate underscores back to dots
    local cnames : colnames `b_ec'
    local cnames2 ""
    foreach cn of local cnames {
        // Translate first underscore that separates TS operator
        local cn2 : subinstr local cn "_" "."
        // Special cases
        if "`cn'" == "_cons" local cn2 "_cons"
        if "`cn'" == "_aardl_sin" local cn2 "_aardl_sin"
        if "`cn'" == "_aardl_cos" local cn2 "_aardl_cos"
        local cnames2 "`cnames2' `cn2'"
    }

    mat colnames `b_ec' = `cnames2'
    mat colnames `V_ec' = `cnames2'
    mat rownames `V_ec' = `cnames2'
    mat coleq `b_ec' = `eqnames'
    mat coleq `V_ec' = `eqnames'
    mat roweq `V_ec' = `eqnames'

    // =========================================================================
    // 11. POST RESULTS & DISPLAY
    // =========================================================================
    tempvar esample
    qui gen byte `esample' = e(sample)

    // Save backup copies of b_ec and V_ec (ereturn post consumes the originals)
    tempname b_ec_save V_ec_save
    mat `b_ec_save' = `b_ec'
    mat `V_ec_save' = `V_ec'

    local dof = `df_r'
    ereturn post `b_ec' `V_ec', esample(`esample') depname(D.`depvar') dof(`dof')

    // Scalars
    ereturn scalar N = `nobs'
    ereturn scalar df_m = `df_m'
    ereturn scalar df_r = `df_r'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_a'
    ereturn scalar ll = `ll'
    ereturn scalar mss = `mss'
    ereturn scalar rss = `rss'
    ereturn scalar rmse = `rmse'
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar F = `F_model'

    // PSS test statistics (like ardl.ado)
    ereturn scalar F_pss = `Fov'
    ereturn scalar t_pss = `t_DV'
    ereturn scalar F_ind = `Find'
    ereturn scalar case = `case'

    ereturn scalar p = `best_p'
    ereturn scalar kstar = `best_kstar'
    ereturn scalar total_models = `total_models'

    forvalues vi = 1/`nall' {
        local xvar : word `vi' of `all_indepvars'
        local cname = subinstr("`xvar'", ".", "_", .)
        ereturn scalar q_`cname' = `best_q_`vi''
    }

    // Locals
    ereturn local cmd "aardl"
    ereturn local cmdline "aardl `0'"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local lrxvars "`lrxvars'"
    ereturn local srvars "`srvars'"
    ereturn local type "`type'"
    ereturn local ic "`ic'"
    ereturn local model "ec"
    ereturn local predict "regres_p"
    if `is_nardl' {
        ereturn local decompose "`decompose'"
    }
    if `has_bootstrap' {
        ereturn local bootstrap "`bootstrap'"
        ereturn scalar reps = `reps'
    }

    // Build title with lag specification (like ardl.ado)
    local lagstr "`best_p'"
    forvalues vi = 1/`nall' {
        local lagstr "`lagstr',`best_q_`vi''"
    }
    ereturn local title "ARDL(`lagstr') regression, EC representation"

    // ─── Model selection display ──
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "`e(title)'"
    di as txt "{hline 78}"

    // Variable-specific lag orders
    di as txt _col(5) "Dependent lag (p)" _col(45) as res "`best_p'"
    local vidx = 0
    foreach xvar of local all_indepvars {
        local vidx = `vidx' + 1
        di as txt _col(5) "`xvar' lag (q)" _col(45) as res "`best_q_`vidx''"
    }
    if `has_fourier' {
        di as txt _col(5) "Fourier frequency (k*)" _col(45) as res %6.2f `best_kstar'
    }
    di as txt _col(5) "Observations" _col(45) as res %8.0f `nobs'
    di as txt _col(5) "R-squared" _col(45) as res %8.6f `r2'
    di as txt _col(5) "Adj. R-squared" _col(45) as res %8.6f `r2_a'
    di as txt _col(5) "Log-Likelihood" _col(45) as res %12.4f `ll'
    di as txt _col(5) "AIC" _col(45) as res %12.4f `aic_val'
    di as txt _col(5) "BIC" _col(45) as res %12.4f `bic_val'
    di as txt _col(5) "RMSE" _col(45) as res %12.6f `rmse'
    di as txt _col(5) "Models evaluated" _col(45) as res %8.0f `total_models'
    di as txt "{hline 78}"

    // ─── Standard Stata coefficient table (ADJ/LR/SR) ──
    if "`notable'" == "" {
        di as txt ""
        _coef_table_header
        di as txt ""
        _coef_table, level(`level')
    }

    // =========================================================================
    // 12. COINTEGRATION TEST TABLE
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Augmented ARDL Cointegration Tests"
    di as txt _col(5) "{it:Sam, McNown & Goh (2019) — 3-Test Framework}"
    di as txt "{hline 78}"
    di as txt ""

    if `has_bootstrap' {
        // ── Bootstrap critical values ──
        di as txt _col(5) "Computing bootstrap critical values (`reps' replications)..."

        // Restore main estimation for bootstrap
        qui estimates restore _aardl_main

        _aardl_bootstrap `depvar', ///
            indepvars(`all_indepvars') ///
            formula(`best_formula') ///
            reps(`reps') ///
            bmethod(`bootstrap') ///
            caseval(`case') ///
            kstar(`best_kstar') ///
            nobs(`T')

        local Fov_bp = r(Fov_bp)
        local tDV_bp = r(tDV_bp)
        local Find_bp = r(Find_bp)
        local Fov_cv5 = r(Fov_cv5)
        local tDV_cv5 = r(tDV_cv5)
        local Find_cv5 = r(Find_cv5)

        ereturn scalar Fov_bp = `Fov_bp'
        ereturn scalar tDV_bp = `tDV_bp'
        ereturn scalar Find_bp = `Find_bp'

        di as txt ""
        di as txt "  {hline 68}"
        di as txt _col(5) "Test" _col(20) "Statistic" _col(35) "Boot. p-val" ///
           _col(50) "Boot. CV(5%)" _col(65) "Signif."
        di as txt "  {hline 68}"

        // F_overall
        di as txt _col(5) "F_overall" _col(18) as res %10.4f `Fov' ///
           _col(33) %10.4f `Fov_bp' _col(48) %10.4f `Fov_cv5' _c
        _aardl_stars `Fov_bp'

        // t_DV
        di as txt _col(5) "t_DV" _col(18) as res %10.4f `t_DV' ///
           _col(33) %10.4f `tDV_bp' _col(48) %10.4f `tDV_cv5' _c
        _aardl_stars `tDV_bp'

        // F_ind (THE AUGMENTATION)
        di as txt _col(5) "F_ind" _col(18) as res %10.4f `Find' ///
           _col(33) %10.4f `Find_bp' _col(48) %10.4f `Find_cv5' _c
        _aardl_stars `Find_bp'

        di as txt "  {hline 68}"

        local sig_fov = (`Fov_bp' < 0.05)
        local sig_tdv = (`tDV_bp' < 0.05)
        local sig_find = (`Find_bp' < 0.05)
    }
    else {
        // ── Asymptotic bounds tests ──
        // Use ardlbounds for Kripfganz & Schneider (2020) critical values
        di as txt "  {hline 68}"
        di as txt _col(5) "Test" _col(22) "Statistic" _col(38) "p-value" _col(55) "Signif."
        di as txt "  {hline 68}"

        di as txt _col(5) "F_overall (PSS)" _col(20) as res %10.4f `Fov' ///
           _col(36) %8.4f `Fov_p' _c
        _aardl_stars `Fov_p'

        local t_DV_p2 = 2 * ttail(`df_r', abs(`t_DV'))
        di as txt _col(5) "t_DV (PSS)" _col(20) as res %10.4f `t_DV' ///
           _col(36) %8.4f `t_DV_p2' _c
        _aardl_stars `t_DV_p2'

        di as txt _col(5) "F_ind (Sam 2019)" _col(20) as res %10.4f `Find' ///
           _col(36) %8.4f `Find_p' _c
        _aardl_stars `Find_p'

        di as txt "  {hline 68}"

        // Try ardlbounds for Kripfganz & Schneider critical values
        if `k_cv' <= 10 {
            di as txt ""
            di as txt _col(5) "{it:Kripfganz & Schneider (2020) critical values:}"

            capture qui ardlbounds, case(`case') stat(f) n(`nobs') k(`k_cv')
            if _rc == 0 {
                tempname F_cv
                mat `F_cv' = r(cvmat)
                di as txt _col(7) "F-bounds:" _col(20) ///
                   "I(0)" _col(35) "I(1)" _col(55) "F_ov = " as res %8.4f `Fov'
                di as txt _col(7) "10%:" _col(18) as res %8.4f el(`F_cv', 1, 1) ///
                   _col(33) %8.4f el(`F_cv', 1, 2)
                di as txt _col(7) "5%:" _col(18) as res %8.4f el(`F_cv', 1, 3) ///
                   _col(33) %8.4f el(`F_cv', 1, 4)
                di as txt _col(7) "1%:" _col(18) as res %8.4f el(`F_cv', 1, 5) ///
                   _col(33) %8.4f el(`F_cv', 1, 6)
            }

            capture qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_cv')
            if _rc == 0 {
                tempname t_cv
                mat `t_cv' = r(cvmat)
                di as txt ""
                di as txt _col(7) "t-bounds:" _col(20) ///
                   "I(0)" _col(35) "I(1)" _col(55) "t_DV = " as res %8.4f `t_DV'
                di as txt _col(7) "10%:" _col(18) as res %8.4f el(`t_cv', 1, 1) ///
                   _col(33) %8.4f el(`t_cv', 1, 2)
                di as txt _col(7) "5%:" _col(18) as res %8.4f el(`t_cv', 1, 3) ///
                   _col(33) %8.4f el(`t_cv', 1, 4)
                di as txt _col(7) "1%:" _col(18) as res %8.4f el(`t_cv', 1, 5) ///
                   _col(33) %8.4f el(`t_cv', 1, 6)
            }
        }

        local sig_fov = (`Fov_p' < 0.05)
        local sig_tdv = (`t_DV_p2' < 0.05)
        local sig_find = (`Find_p' < 0.05)
    }

    // ── COINTEGRATION CONCLUSION ──
    di as txt ""
    if `sig_fov' & `sig_tdv' & `sig_find' {
        di as res _col(5) ">>> CONCLUSION: Cointegration exists (all 3 tests significant)"
        local coint_status "cointegrated"
    }
    else if `sig_fov' & `sig_tdv' & !`sig_find' {
        di as res _col(5) ">>> Degenerate case #2 (F_ov sig, t_DV sig, F_ind not sig)"
        di as txt _col(5) "    Dependent variable may be I(0). No cointegration."
        local coint_status "degenerate_2"
    }
    else if `sig_fov' & !`sig_tdv' & `sig_find' {
        di as res _col(5) ">>> Degenerate case #1 (F_ov sig, t_DV not sig, F_ind sig)"
        di as txt _col(5) "    No cointegration."
        local coint_status "degenerate_1"
    }
    else {
        di as res _col(5) ">>> CONCLUSION: No cointegration"
        local coint_status "no_cointegration"
    }

    ereturn local coint_status "`coint_status'"
    di as txt "{hline 78}"
    di as txt ""

    // =========================================================================
    // 13. NARDL ASYMMETRY TESTS
    // =========================================================================
    if `is_nardl' {
        // Restore main estimation for Wald tests
        qui estimates restore _aardl_main

        di as txt "{hline 78}"
        di as res _col(5) "Asymmetry Tests (Wald)"
        di as txt "{hline 78}"
        di as txt _col(5) "Variable" _col(22) "Type" _col(38) "Wald F" _col(52) "p-value" _col(63) "Signif."
        di as txt "  {hline 68}"

        foreach cname of local dec_names {
            // Long-run asymmetry: H0: b[L.pos] = b[L.neg]
            capture qui test L.`cname'_pos = L.`cname'_neg
            if _rc == 0 {
                local w_lr = r(F)
                local p_lr = r(p)
                di as txt _col(5) "`cname'" _col(22) "Long-run" ///
                   _col(36) as res %10.4f `w_lr' _col(50) %8.4f `p_lr' _c
                _aardl_stars `p_lr'
            }

            // Short-run asymmetry: H0: b[D.pos] = b[D.neg]
            capture qui test D.`cname'_pos = D.`cname'_neg
            if _rc == 0 {
                local w_sr = r(F)
                local p_sr = r(p)
                di as txt _col(5) "`cname'" _col(22) "Short-run" ///
                   _col(36) as res %10.4f `w_sr' _col(50) %8.4f `p_sr' _c
                _aardl_stars `p_sr'
            }
        }
        di as txt "  {hline 68}"
        di as txt ""
    }

    // =========================================================================
    // 14. DIAGNOSTIC TESTS
    // =========================================================================
    if "`nodiag'" == "" {
        qui estimates restore _aardl_main
        _aardl_diagtest `resid', df_r(`df_r') nobs(`nobs')
    }

    // =========================================================================
    // 15. DYNAMIC MULTIPLIERS
    // =========================================================================
    if "`nodynmult'" == "" & "`coint_status'" == "cointegrated" {
        qui estimates restore _aardl_main
        if `is_nardl' {
            _aardl_ndynmult `depvar', ///
                decnames(`dec_names') ///
                bestp(`best_p') ///
                horizon(`horizon') ///
                `nograph'
        }
        else {
            _aardl_dynmult `depvar', ///
                indepvars(`all_indepvars') ///
                bestp(`best_p') ///
                horizon(`horizon') ///
                `nograph'
        }
    }

    // =========================================================================
    // 16. ADVANCED ANALYSIS
    // =========================================================================
    if "`noadvanced'" == "" & "`coint_status'" == "cointegrated" {
        qui estimates restore _aardl_main
        _aardl_advanced `depvar', ///
            indepvars(`all_indepvars') ///
            ecmcoef(`ecm_coef') ///
            level(`level') ///
            kstar(`best_kstar') ///
            horizon(`horizon') ///
            `nograph'
    }

    // =========================================================================
    // 17. RE-POST EC FORM RESULTS (so ereturn list shows ADJ/LR/SR)
    // =========================================================================
    // The helper modules used `estimates restore _aardl_main` which
    // overwrote the EC-posted results. Re-post them now.
    capture estimates drop _aardl_main
    capture drop _aardl_sin _aardl_cos

    // Re-do the ereturn post with our saved b_ec / V_ec matrices
    tempvar esample2
    qui gen byte `esample2' = 1
    ereturn post `b_ec_save' `V_ec_save', esample(`esample2') depname(D.`depvar') dof(`dof')

    // Re-store all scalars and locals
    ereturn scalar N = `nobs'
    ereturn scalar df_m = `df_m'
    ereturn scalar df_r = `df_r'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_a'
    ereturn scalar ll = `ll'
    ereturn scalar mss = `mss'
    ereturn scalar rss = `rss'
    ereturn scalar rmse = `rmse'
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar F = `F_model'
    ereturn scalar F_pss = `Fov'
    ereturn scalar t_pss = `t_DV'
    ereturn scalar F_ind = `Find'
    ereturn scalar case = `case'
    ereturn scalar p = `best_p'
    ereturn scalar kstar = `best_kstar'
    ereturn scalar total_models = `total_models'
    forvalues vi = 1/`nall' {
        local xvar : word `vi' of `all_indepvars'
        local cname = subinstr("`xvar'", ".", "_", .)
        ereturn scalar q_`cname' = `best_q_`vi''
    }
    ereturn local cmd "aardl"
    ereturn local cmdline "aardl `0'"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local lrxvars "`lrxvars'"
    ereturn local srvars "`srvars'"
    ereturn local type "`type'"
    ereturn local ic "`ic'"
    ereturn local model "ec"
    ereturn local predict "regres_p"
    ereturn local title "ARDL(`lagstr') regression, EC representation"
    ereturn local coint_status "`coint_status'"
    if `is_nardl' ereturn local decompose "`decompose'"
    if `has_bootstrap' {
        ereturn local bootstrap "`bootstrap'"
        ereturn scalar reps = `reps'
        ereturn scalar Fov_bp = `Fov_bp'
        ereturn scalar tDV_bp = `tDV_bp'
        ereturn scalar Find_bp = `Find_bp'
    }

    restore

    di as txt "{hline 78}"
    di as res _col(5) "aardl estimation complete."
    di as txt "{hline 78}"

end
