*! fbardl — Fourier Bootstrap ARDL Cointegration Test
*! Version 1.2.0 — 2026-08-02
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Implements:
*!   Pesaran, Shin & Smith (2001) — ARDL bounds testing
*!   McNown, Sam & Goh (2018) — Bootstrap ARDL (unconditional)
*!   Bertelli, Vacca & Zoia (2022) — Bootstrap ARDL (conditional)
*!   Yilanci, Bozoklu & Gorus (2020) — Fourier ARDL approach
*!   Kripfganz & Schneider (2020) — ARDL bounds test critical values
*!   White (1980) — heteroskedasticity-consistent covariance matrix
*!   Newey & West (1987) — heteroskedasticity- and autocorrelation-consistent
*!                         (HAC) covariance matrix

capture program drop fbardl
program define fbardl, eclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=2 ts fv) [if] [in], ///
        [                                   ///
        TYpe(string)                        /// fardl, fbardl_mcnown, fbardl_bvz
        MAXLag(integer 4)                   /// max lag order for grid search
        MAXK(real 5)                        /// max Fourier frequency
        IC(string)                          /// aic or bic
        REPS(integer 999)                   /// bootstrap replications
        NOFourier                           /// no Fourier terms
        Level(cilevel)                      /// confidence level
        HORizon(integer 20)                 /// multiplier/persistence horizon
        NODiag                              /// suppress diagnostics
        NODYNmult                           /// suppress dynamic multipliers
        NOADVanced                          /// suppress advanced analyses
        NOTable                             /// suppress main regression table
        case(integer 3)                     /// PSS case (2=restricted, 3=unrestricted intercept)
        HAC(string)                         /// robust VCE: hetero | auto | both | none
        HACLAGS(integer -1)                 /// Newey-West truncation lag (-1 = automatic)
        EXOg(varlist ts fv)                 /// fixed (exogenous) regressors, e.g. dummies
        FIXed(varlist ts fv)                /// synonym for exog()
        UNCONDitional                       /// drop contemporaneous D.x (Yilanci/McNown form)
        DGPcheck                            /// verify the bootstrap recursion (developer aid)
        ]

    // Mark estimation sample
    marksample touse

    // Validate type option
    if "`type'" == "" local type "fardl"
    local type = lower("`type'")
    if !inlist("`type'", "fardl", "fbardl_mcnown", "fbardl_bvz") {
        di as err "type() must be {bf:fardl}, {bf:fbardl_mcnown}, or {bf:fbardl_bvz}"
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
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }

    // -------------------------------------------------------------------------
    // Validate case — PSS (2001) deterministic specification
    // -------------------------------------------------------------------------
    //   2 : restricted intercept,   no trend   -> intercept joins the F_ov null
    //   3 : unrestricted intercept, no trend   -> levels only in the F_ov null
    //   4 : unrestricted intercept, restricted trend -> trend joins the F_ov null
    //   5 : unrestricted intercept, unrestricted trend
    // Cases 4 and 5 add a linear trend to the estimated equation.
    // -------------------------------------------------------------------------
    if !inlist(`case', 2, 3, 4, 5) {
        di as err "case() must be 2, 3, 4, or 5"
        exit 198
    }

    local hastrend = 0
    if inlist(`case', 4, 5) local hastrend = 1

    // Case 2 restricts the intercept under H0, so the restricted model that
    // generates the bootstrap data must be estimated without a constant
    local fovnocons ""
    if `case' == 2 local fovnocons "noconstant"

    // -------------------------------------------------------------------------
    // Conditional vs unconditional ARDL
    // -------------------------------------------------------------------------
    // Default (conditional, Pesaran-Shin-Smith Eq. 4 / Bertelli-Vacca-Zoia):
    //   short-run x terms run j = 0, 1, ..., q  (contemporaneous D.x included)
    // unconditional (Yilanci et al. Eq. 8 / McNown et al. Eq. 10):
    //   short-run x terms run j = 1, ..., q     (no contemporaneous D.x)
    // -------------------------------------------------------------------------
    local j0 = 0
    if "`unconditional'" != "" local j0 = 1

    // -------------------------------------------------------------------------
    // Validate hac() — covariance matrix estimator for inference
    // -------------------------------------------------------------------------
    //   hetero : White (1980) HC1  — heteroskedasticity only
    //   auto   : Newey-West HAC    — autocorrelation (also robust to hetero)
    //   both   : Newey-West HAC    — heteroskedasticity AND autocorrelation
    // -------------------------------------------------------------------------
    local hac = lower(strtrim("`hac'"))
    if inlist("`hac'", "", "none", "no", "ols", "iid") {
        local vcetype "ols"
    }
    else if inlist("`hac'", "het", "hetero", "heteroskedastic", "heteroskedasticity", "robust", "white", "hc1") {
        local vcetype "robust"
    }
    else if inlist("`hac'", "auto", "ac", "autocorr", "autocorrelation", "serial") {
        local vcetype "hac"
    }
    else if inlist("`hac'", "both", "hac", "nw", "newey", "neweywest", "newey-west") {
        local vcetype "hac"
    }
    else {
        di as err "hac() must be {bf:hetero}, {bf:auto}, {bf:both}, or {bf:none}"
        di as err "  hetero : heteroskedasticity-robust (White 1980, HC1)"
        di as err "  auto   : autocorrelation-robust (Newey-West 1987 HAC)"
        di as err "  both   : heteroskedasticity- and autocorrelation-robust (HAC)"
        exit 198
    }

    if `haclags' < -1 {
        di as err "haclags() must be a non-negative integer (or omitted for automatic)"
        exit 198
    }
    if `haclags' >= 0 & "`vcetype'" != "hac" {
        di as err "haclags() requires hac(auto) or hac(both)"
        exit 198
    }

    // -------------------------------------------------------------------------
    // Fixed (exogenous) regressors — fixed() is a synonym for exog()
    // -------------------------------------------------------------------------
    if "`fixed'" != "" {
        local exog "`exog' `fixed'"
    }
    local exog = stritrim(strtrim("`exog'"))

    // Restrict the estimation sample to observations where the fixed
    // regressors are also non-missing (fvrevar strips ts/fv operators
    // so markout sees plain variable names)
    if "`exog'" != "" {
        qui fvrevar `exog', list
        markout `touse' `r(varlist)'
    }

    // Confirm time series
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "fbardl is designed for time-series data only, not panel data"
        exit 198
    }

    // =========================================================================
    // 2. PARSE DEPENDENT AND INDEPENDENT VARIABLES
    // =========================================================================
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'

    if `nindep' < 1 {
        di as err "at least one independent variable required"
        exit 198
    }

    // =========================================================================
    // 3. PRESERVE & PREPARE DATA
    // =========================================================================
    preserve

    // Keep estimation sample
    qui keep if `touse'
    qui count
    local T = r(N)

    if `T' < 20 {
        di as err "sample size too small (N = `T'): need at least 20 obs"
        exit 198
    }

    // =========================================================================
    // 3b. FIXED REGRESSORS — expand factor/ts operators to coefficient names
    // =========================================================================
    local exogexp ""
    if "`exog'" != "" {
        capture fvexpand `exog'
        if _rc == 0 {
            local exogexp "`r(varlist)'"
        }
        else {
            local exogexp "`exog'"
        }
    }

    // =========================================================================
    // 3c. COVARIANCE MATRIX ESTIMATOR
    // =========================================================================
    // Point estimates are identical under all three; only the standard errors,
    // t/z statistics, p-values and Wald (F) statistics change.
    if "`vcetype'" == "robust" {
        local estcmd   "regress"
        local estopt   "vce(robust)"
        local vcelabel "Heteroskedasticity-robust (White 1980, HC1)"
        local vceshort "HC1 robust"
    }
    else if "`vcetype'" == "hac" {
        // Newey & West (1987) Bartlett kernel.
        // Automatic bandwidth: floor(4*(T/100)^(2/9))  (Newey & West 1994)
        if `haclags' < 0 {
            local nwlag = floor(4 * (`T' / 100)^(2/9))
            if `nwlag' < 1 local nwlag = 1
            local nwrule "automatic: floor(4*(T/100)^(2/9))"
        }
        else {
            local nwlag = `haclags'
            local nwrule "user-specified"
        }
        local estcmd   "newey"
        local estopt   "lag(`nwlag')"
        local vcelabel "HAC Newey-West (1987), Bartlett kernel, lag = `nwlag'"
        local vceshort "HAC (NW, lag `nwlag')"
    }
    else {
        local estcmd   "regress"
        local estopt   ""
        local vcelabel "Conventional OLS (i.i.d. errors)"
        local vceshort "OLS"
    }

    local vceclause ""
    if "`estopt'" != "" local vceclause ", `estopt'"

    // =========================================================================
    //   HEADER
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    if "`type'" == "fardl" {
        di as res _col(5) "Fourier ARDL (FARDL) Cointegration Analysis"
    }
    else if "`type'" == "fbardl_mcnown" {
        di as res _col(5) "Fourier Bootstrap ARDL — McNown, Sam & Goh (2018)"
    }
    else {
        di as res _col(5) "Fourier Bootstrap ARDL — Bertelli, Vacca & Zoia (2022)"
    }
    di as txt "{hline 78}"
    di as txt _col(5) "Dependent variable  : " as res "`depvar'"
    di as txt _col(5) "Independent var(s)  : " as res "`indepvars'"
    if "`exog'" != "" {
        di as txt _col(5) "Fixed regressor(s)  : " as res "`exog'"
    }
    di as txt _col(5) "Sample size (T)     : " as res "`T'"
    di as txt _col(5) "Max lag order       : " as res "`maxlag'"
    if "`nofourier'" == "" {
        di as txt _col(5) "Max Fourier freq.   : " as res "`maxk'"
    }
    else {
        di as txt _col(5) "Fourier terms       : " as res "excluded"
    }
    di as txt _col(5) "Information crit.   : " as res upper("`ic'")
    if `case' == 2 {
        di as txt _col(5) "PSS Case            : " as res "Case 2 (restricted intercept, no trend)"
    }
    else if `case' == 3 {
        di as txt _col(5) "PSS Case            : " as res "Case 3 (unrestricted intercept, no trend)"
    }
    else if `case' == 4 {
        di as txt _col(5) "PSS Case            : " as res "Case 4 (unrestricted intercept, restricted trend)"
    }
    else {
        di as txt _col(5) "PSS Case            : " as res "Case 5 (unrestricted intercept and trend)"
    }
    if "`unconditional'" != "" {
        di as txt _col(5) "ARDL form           : " as res "unconditional (no contemporaneous D.x)"
    }
    else {
        di as txt _col(5) "ARDL form           : " as res "conditional (contemporaneous D.x included)"
    }
    di as txt _col(5) "Std. errors         : " as res "`vcelabel'"
    if inlist("`type'", "fbardl_mcnown", "fbardl_bvz") {
        di as txt _col(5) "Bootstrap reps      : " as res "`reps'"
    }
    di as txt "{hline 78}"
    di as txt ""

    // =========================================================================
    // 4. GENERATE FOURIER TERMS
    // =========================================================================
    // Build frequency grid: 0.1, 0.2, ..., maxk
    if "`nofourier'" == "" {
        local nkgrid = round(`maxk' / 0.1)
        tempname kgrid
        mat `kgrid' = J(1, `nkgrid', .)
        forvalues i = 1/`nkgrid' {
            mat `kgrid'[1, `i'] = `i' * 0.1
        }
    }
    else {
        local nkgrid = 1
        tempname kgrid
        mat `kgrid' = J(1, 1, 0)
    }

    // Generate time trend for Fourier
    tempvar ttrend
    qui gen `ttrend' = _n

    // Deterministic linear trend for PSS cases 4 and 5
    capture drop _fbardl_trend
    local trendvar ""
    if `hastrend' {
        qui gen double _fbardl_trend = `ttrend'
        local trendvar "_fbardl_trend"
    }

    // =========================================================================
    // 5. STEP 1: SELECT k* BY MINIMUM SSR (Yilanci et al. 2020)
    // =========================================================================
    di as txt _col(3) "Step 1: Selecting Fourier frequency k* by minimum SSR..."

    tempname best_ssr_k ssr_matrix
    scalar `best_ssr_k' = .
    mat `ssr_matrix' = J(`nkgrid', 2, .)
    local best_kstar = 0

    forvalues kidx = 1/`nkgrid' {
        local kval = `kgrid'[1, `kidx']
        mat `ssr_matrix'[`kidx', 1] = `kval'

        // Generate Fourier terms for this k
        capture drop _fbardl_sin _fbardl_cos
        if `kval' > 0 {
            qui gen double _fbardl_sin = sin(2 * c(pi) * `kval' * `ttrend' / `T')
            qui gen double _fbardl_cos = cos(2 * c(pi) * `kval' * `ttrend' / `T')
        }

        // Build maximal regression for SSR evaluation
        local regvars_max ""

        // Lagged levels
        local regvars_max "L.`depvar'"
        foreach xvar of local indepvars {
            local regvars_max "`regvars_max' L.`xvar'"
        }

        // Lagged differences of depvar
        forvalues j = 1/`maxlag' {
            local regvars_max "`regvars_max' L`j'.D.`depvar'"
        }

        // Contemporaneous (unless unconditional) & lagged differences of indepvars
        foreach xvar of local indepvars {
            forvalues j = `j0'/`maxlag' {
                if `j' == 0 {
                    local regvars_max "`regvars_max' D.`xvar'"
                }
                else {
                    local regvars_max "`regvars_max' L`j'.D.`xvar'"
                }
            }
        }

        // Fourier terms
        if `kval' > 0 {
            local regvars_max "`regvars_max' _fbardl_sin _fbardl_cos"
        }

        // Deterministic trend (PSS cases 4 and 5)
        if `hastrend' {
            local regvars_max "`regvars_max' _fbardl_trend"
        }

        // Fixed (exogenous) regressors — enter every candidate model
        if "`exog'" != "" {
            local regvars_max "`regvars_max' `exog'"
        }

        // Estimate and record SSR
        // Plain OLS: the SSR does not depend on the covariance estimator
        capture qui regress D.`depvar' `regvars_max'
        if _rc == 0 {
            local this_ssr = e(rss)
        }
        else {
            local this_ssr = .
        }
        mat `ssr_matrix'[`kidx', 2] = `this_ssr'

        if `this_ssr' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
            scalar `best_ssr_k' = `this_ssr'
            local best_kstar = `kval'
        }
    }

    if "`nofourier'" != "" {
        local best_kstar = 0
    }

    di as txt _col(5) "Optimal k* = " as res "`best_kstar'" ///
       as txt " (min SSR = " as res %12.4f scalar(`best_ssr_k') as txt ")"
    // Christopoulos & Leon-Ledesma (2011), cited by Yilanci et al. (2020):
    // an integer frequency approximates temporary breaks, a fractional one
    // approximates permanent breaks
    if `best_kstar' > 0 {
        if abs(`best_kstar' - round(`best_kstar')) < 1e-8 {
            di as txt _col(5) "{it:k* is an integer frequency: temporary breaks}"
            local kstar_type "integer (temporary breaks)"
        }
        else {
            di as txt _col(5) "{it:k* is a fractional frequency: permanent breaks}"
            local kstar_type "fractional (permanent breaks)"
        }
    }
    else {
        local kstar_type "none"
    }
    di as txt ""

    // =========================================================================
    // SSR vs k* GRAPH (publication quality)
    // =========================================================================
    if `nkgrid' > 1 & "`nofourier'" == "" {
        mat _fbardl_ssr_k = `ssr_matrix'
        tempfile _fbardl_tmpdata
        qui save `_fbardl_tmpdata', replace

        capture noisily {
            qui clear
            qui set obs `nkgrid'
            qui gen double kstar = .
            qui gen double ssr = .

            forvalues kidx = 1/`nkgrid' {
                qui replace kstar = el(_fbardl_ssr_k, `kidx', 1) in `kidx'
                qui replace ssr = el(_fbardl_ssr_k, `kidx', 2) in `kidx'
            }

            // Mark optimal k*
            qui gen byte is_opt = abs(kstar - `best_kstar') < 0.001

            twoway (connected ssr kstar, lcolor("24 54 104") mcolor("24 54 104") ///
                       lwidth(medthick) msymbol(circle) msize(small)) ///
                   (scatter ssr kstar if is_opt, mcolor("220 50 47") ///
                       msymbol(diamond) msize(vlarge)), ///
                   title("{bf:Fourier Frequency Selection}", size(medlarge) color("24 54 104")) ///
                   subtitle("Min SSR criterion (Yilanci, Bozoklu & Gorus, 2020)", ///
                       size(small) color(gs6)) ///
                   xtitle("Fourier frequency (k)", size(medsmall)) ///
                   ytitle("Sum of Squared Residuals", size(medsmall)) ///
                   xline(`best_kstar', lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
                   legend(order(1 "SSR" 2 "Optimal k* = `best_kstar'") ///
                       size(small) cols(2) ring(0) pos(1) ///
                       region(fcolor(white%80) lcolor(gs12))) ///
                   graphregion(fcolor(white) lcolor(white)) ///
                   plotregion(fcolor(white) lcolor(gs14)) ///
                   ylabel(, format(%12.2f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                   xlabel(, labsize(small) grid glcolor(gs14%50)) ///
                   note("Step 1: k* selected by minimum SSR", ///
                       size(vsmall) color(gs8)) ///
                   scheme(s2color) name(kstar_selection, replace)

            qui graph export "kstar_selection.png", replace width(1400)
            di as txt _col(5) "Graph saved: kstar_selection.png"
        }

        qui use `_fbardl_tmpdata', clear
        capture mat drop _fbardl_ssr_k
    }

    // =========================================================================
    // 6. FIX FOURIER TERMS AT OPTIMAL k*
    // =========================================================================
    capture drop _fbardl_sin _fbardl_cos
    if `best_kstar' > 0 {
        qui gen double _fbardl_sin = sin(2 * c(pi) * `best_kstar' * `ttrend' / `T')
        qui gen double _fbardl_cos = cos(2 * c(pi) * `best_kstar' * `ttrend' / `T')
    }

    // =========================================================================
    // 7. STEP 2: SELECT LAG ORDERS (p, q) BY AIC/BIC
    // =========================================================================
    di as txt _col(3) "Step 2: Selecting lag orders (p, q) by " upper("`ic'") "..."

    tempname best_ic_val
    scalar `best_ic_val' = .
    local best_p = 1
    // Store best q for each indepvar
    local nindep : word count `indepvars'
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        local best_q_`cname' = 0
    }
    local total_specs = 0

    // Number of q levels per variable: 0, 1, ..., maxlag
    local nq = `maxlag' + 1

    // Total q combinations = nq^nindep
    local nq_combos = 1
    forvalues i = 1/`nindep' {
        local nq_combos = `nq_combos' * `nq'
    }

    forvalues p = 1/`maxlag' {
        // Iterate over all combinations of (q1, q2, ..., qk)
        forvalues qidx = 0/`=`nq_combos' - 1' {
            local total_specs = `total_specs' + 1

            // Decode qidx into individual q values for each variable
            local qidx_tmp = `qidx'
            foreach xvar of local indepvars {
                local cname = subinstr("`xvar'", ".", "_", .)
                local q_`cname' = mod(`qidx_tmp', `nq')
                local qidx_tmp = floor(`qidx_tmp' / `nq')
            }

            // Build regressor list
            local regvars ""

            // Lagged levels (ECM terms)
            local regvars "L.`depvar'"
            foreach xvar of local indepvars {
                local regvars "`regvars' L.`xvar'"
            }

            // Lagged differences of depvar
            forvalues j = 1/`p' {
                local regvars "`regvars' L`j'.D.`depvar'"
            }

            // Contemporaneous & lagged differences of indepvars
            // Each variable uses its own q_i
            foreach xvar of local indepvars {
                local cname = subinstr("`xvar'", ".", "_", .)
                local qi = `q_`cname''
                forvalues j = `j0'/`qi' {
                    if `j' == 0 {
                        local regvars "`regvars' D.`xvar'"
                    }
                    else {
                        local regvars "`regvars' L`j'.D.`xvar'"
                    }
                }
            }

            // Fourier terms
            if `best_kstar' > 0 {
                local regvars "`regvars' _fbardl_sin _fbardl_cos"
            }

            // Deterministic trend (PSS cases 4 and 5)
            if `hastrend' {
                local regvars "`regvars' _fbardl_trend"
            }

            // Fixed (exogenous) regressors — enter every candidate model
            if "`exog'" != "" {
                local regvars "`regvars' `exog'"
            }

            // Estimate
            // Plain OLS: the log-likelihood (hence AIC/BIC) does not depend
            // on the covariance estimator
            capture qui regress D.`depvar' `regvars'
            if _rc == 0 {
                local nobs_tmp = e(N)
                local k_tmp = e(df_m) + 1
                local ll_tmp = e(ll)

                if "`ic'" == "aic" {
                    local ic_tmp = -2 * `ll_tmp' + 2 * `k_tmp'
                }
                else {
                    local ic_tmp = -2 * `ll_tmp' + `k_tmp' * ln(`nobs_tmp')
                }

                if `ic_tmp' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                    scalar `best_ic_val' = `ic_tmp'
                    local best_p = `p'
                    foreach xvar of local indepvars {
                        local cname = subinstr("`xvar'", ".", "_", .)
                        local best_q_`cname' = `q_`cname''
                    }
                }
            }
        }
    }

    di as txt _col(5) "Optimal p = " as res "`best_p'" as txt ", q = " _c
    local first = 1
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        if `first' == 0 di as txt ", " _c
        di as res "`best_q_`cname''" _c
        local first = 0
    }
    di as txt _col(3) " (" as res "`total_specs'" as txt " models evaluated)"
    di as txt ""

    // =========================================================================
    // 8. FINAL ESTIMATION
    // =========================================================================
    di as txt _col(3) "Step 3: Estimating final ARDL(`best_p'," _c
    local qfirst = 1
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        if `qfirst' == 0 di as txt "," _c
        di as txt "`best_q_`cname''" _c
        local qfirst = 0
    }
    di as txt ") model with k* = `best_kstar'..."
    di as txt ""

    // Build final regressor list
    local regvars ""
    local levelvars ""    // for cointegration tests
    local ecmvar "L.`depvar'"
    local indeplev ""     // lagged levels of indepvars only

    // Lagged levels (ECM terms)
    local regvars "L.`depvar'"
    local levelvars "L.`depvar'"
    foreach xvar of local indepvars {
        local regvars "`regvars' L.`xvar'"
        local levelvars "`levelvars' L.`xvar'"
        local indeplev "`indeplev' L.`xvar'"
    }

    // Short-run: lagged differences of depvar
    local sr_depvars ""
    forvalues j = 1/`best_p' {
        local regvars "`regvars' L`j'.D.`depvar'"
        local sr_depvars "`sr_depvars' L`j'.D.`depvar'"
    }

    // Short-run: contemporaneous & lagged differences of indepvars
    local sr_indepvars ""
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        local q_this = `best_q_`cname''
        forvalues j = `j0'/`q_this' {
            if `j' == 0 {
                local regvars "`regvars' D.`xvar'"
                local sr_indepvars "`sr_indepvars' D.`xvar'"
            }
            else {
                local regvars "`regvars' L`j'.D.`xvar'"
                local sr_indepvars "`sr_indepvars' L`j'.D.`xvar'"
            }
        }
    }

    // Fourier terms
    if `best_kstar' > 0 {
        local regvars "`regvars' _fbardl_sin _fbardl_cos"
    }

    // Deterministic trend (PSS cases 4 and 5)
    if `hastrend' {
        local regvars "`regvars' _fbardl_trend"
    }

    // Fixed (exogenous) regressors — part of the estimated equation but NOT
    // part of the long-run relationship, so they are excluded from
    // `levelvars' and `indeplev' and hence from the cointegration tests
    if "`exog'" != "" {
        local regvars "`regvars' `exog'"
    }

    // Selected q for each indepvar, in indepvars order (for the bootstrap DGP)
    local bestq_list ""
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        local bestq_list "`bestq_list' `best_q_`cname''"
    }
    local bestq_list = strtrim("`bestq_list'")

    // -------------------------------------------------------------------------
    // Final estimation, stage 1: plain OLS
    // -------------------------------------------------------------------------
    // The covariance estimator does not change the point estimates, so all
    // goodness-of-fit quantities (R2, log-likelihood, AIC/BIC, RSS, RMSE) and
    // the residuals are taken from the OLS fit. This estimate set is also what
    // Ramsey's RESET (estat ovtest) needs in Table 4.
    qui regress D.`depvar' `regvars'
    estimates store _fbardl_ols

    local nobs = e(N)
    local nparams = e(df_m) + 1
    local r2 = e(r2)
    local r2_a = e(r2_a)
    local ll = e(ll)
    local rss = e(rss)
    local mss = e(mss)
    local df_m = e(df_m)
    local df_r = e(df_r)
    local rmse = e(rmse)

    // Compute AIC, BIC
    local aic_val = -2 * `ll' + 2 * `nparams'
    local bic_val = -2 * `ll' + `nparams' * ln(`nobs')

    // Save residuals to a named variable (survives bootstrap data cycles)
    capture drop _fbardl_resid
    qui predict double _fbardl_resid, residuals

    // Save residuals
    tempvar residvar
    qui predict double `residvar', residuals

    // -------------------------------------------------------------------------
    // Final estimation, stage 2: apply the requested covariance estimator
    // -------------------------------------------------------------------------
    // Everything downstream that reports standard errors, t/z statistics,
    // p-values, confidence intervals or Wald tests (Tables 2, 3, 7 and 8, and
    // the bootstrap test statistics) uses this estimate set.
    if "`vcetype'" != "ols" {
        capture qui `estcmd' D.`depvar' `regvars' `vceclause'
        if _rc != 0 {
            di as err _col(5) "Warning: `estcmd' `estopt' failed (rc = " _rc ")."
            if "`vcetype'" == "hac" {
                di as err _col(5) "  Newey-West requires equally spaced observations with no gaps."
                di as err _col(5) "  Falling back to heteroskedasticity-robust (HC1) standard errors."
                qui regress D.`depvar' `regvars', vce(robust)
                local vcetype  "robust"
                local estcmd   "regress"
                local estopt   "vce(robust)"
                local vceclause ", vce(robust)"
                local vcelabel "Heteroskedasticity-robust (White 1980, HC1) [HAC fallback]"
                local vceshort "HC1 robust"
            }
            else {
                di as err _col(5) "  Falling back to conventional OLS standard errors."
                qui regress D.`depvar' `regvars'
                local vcetype  "ols"
                local estcmd   "regress"
                local estopt   ""
                local vceclause ""
                local vcelabel "Conventional OLS (i.i.d. errors)"
                local vceshort "OLS"
            }
        }
    }

    // Store estimation for later restoration after bootstrap
    estimates store _fbardl_main

    // Model F-statistic from the active (possibly robust/HAC) estimation
    local F_model = e(F)
    local F_model_p = Ftail(`df_m', `df_r', `F_model')

    // Count the fixed regressors that were actually estimated (base and
    // omitted factor levels carry a zero standard error and are skipped)
    local nexog_est = 0
    local exogkeep ""
    foreach v of local exogexp {
        capture local ese = _se[`v']
        if _rc == 0 {
            if `ese' > 0 & `ese' < . {
                local nexog_est = `nexog_est' + 1
                local exogkeep "`exogkeep' `v'"
            }
        }
    }

    // Get ECM coefficient
    local ecm_coef = _b[L.`depvar']
    local ecm_se = _se[L.`depvar']
    local ecm_t = `ecm_coef' / `ecm_se'
    local ecm_p = 2 * ttail(`df_r', abs(`ecm_t'))

    // =========================================================================
    // TABLE 1: MODEL SELECTION SUMMARY (publication quality)
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 1: Model Selection Summary"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 68}"
    di as txt _col(5) "ARDL Specification" _col(45) "ARDL(`best_p'" _c
    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        di as txt ",`best_q_`cname''" _c
    }
    di as txt ")"
    di as txt _col(5) "Fourier Frequency (k*)" _col(45) "`best_kstar'"
    di as txt _col(5) "PSS Case" _col(45) "Case `case'"
    if "`exog'" != "" {
        di as txt _col(5) "Fixed regressors" _col(45) "`nexog_est'"
    }
    di as txt _col(5) "Std. errors" _col(45) "`vceshort'"
    di as txt "  {hline 68}"
    di as txt _col(5) "Observations" _col(45) as res %8.0f `nobs'
    di as txt _col(5) "R-squared" _col(45) as res %8.6f `r2'
    di as txt _col(5) "Adjusted R-squared" _col(45) as res %8.6f `r2_a'
    di as txt _col(5) "Log-Likelihood" _col(45) as res %12.4f `ll'
    di as txt _col(5) "AIC" _col(45) as res %12.4f `aic_val'
    di as txt _col(5) "BIC" _col(45) as res %12.4f `bic_val'
    if "`vcetype'" == "ols" {
        di as txt _col(5) "F-statistic" _col(45) as res %8.4f `F_model' ///
           as txt " (p = " as res %6.4f `F_model_p' as txt ")"
    }
    else {
        di as txt _col(5) "F-statistic (`vceshort')" _col(45) as res %8.4f `F_model' ///
           as txt " (p = " as res %6.4f `F_model_p' as txt ")"
    }
    di as txt _col(5) "RMSE" _col(45) as res %12.6f `rmse'
    di as txt _col(5) "Models evaluated" _col(45) as res %8.0f `total_specs'
    if "`nofourier'" == "" {
        di as txt _col(5) "Frequencies tested" _col(45) as res %8.0f `nkgrid'
    }
    di as txt "  {hline 68}"
    di as txt ""

    // =========================================================================
    // TABLE 2: ARDL ESTIMATION — EC REPRESENTATION (like ardl package)
    // =========================================================================
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as res _col(5) "Table 2: ARDL(`best_p'" _c
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            di as res ",`best_q_`cname''" _c
        }
        di as res ") regression, EC representation"
        di as txt "{hline 78}"
        if "`vcetype'" != "ols" {
            di as txt _col(5) "Standard errors: " as res "`vcelabel'"
        }
        di as txt ""

        // ----- ADJ: Speed of Adjustment -----
        di as txt "  {bf:ADJ — Speed of Adjustment}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(28) "Coef." _col(40) "Std.Err." ///
           _col(52) "t-stat" _col(62) "p-value"
        di as txt "  {hline 68}"

        di as txt _col(5) "L.`depvar'" _col(25) as res %10.6f `ecm_coef' ///
           _col(37) %10.6f `ecm_se' _col(49) %8.4f `ecm_t' _col(59) %8.4f `ecm_p' _c
        _fbardl_stars `ecm_p'
        di as txt "  {hline 68}"

        // ----- LR: Long-Run Coefficients (delta method via nlcom) -----
        di as txt ""
        di as txt "  {bf:LR — Long-Run Coefficients}  {it:(-beta_x / alpha, delta method)}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(22) "LR Coef." _col(34) "Std.Err." ///
           _col(46) "z-stat" _col(56) "p-value" _col(66) "[`level'% CI]"
        di as txt "  {hline 68}"

        foreach xvar of local indepvars {
            capture qui nlcom (LR_`xvar': -_b[L.`xvar'] / _b[L.`depvar']), level(`level')
            if _rc == 0 {
                mat _nlcom_b = r(b)
                mat _nlcom_V = r(V)
                local lr_b = _nlcom_b[1,1]
                local lr_se = sqrt(_nlcom_V[1,1])
                local lr_z = `lr_b' / `lr_se'
                local lr_p = 2 * (1 - normal(abs(`lr_z')))
                local lr_lo = `lr_b' - invnormal(1 - (100-`level')/200) * `lr_se'
                local lr_hi = `lr_b' + invnormal(1 - (100-`level')/200) * `lr_se'

                di as txt _col(5) "`xvar'" _col(20) as res %10.6f `lr_b' ///
                   _col(32) %10.6f `lr_se' _col(44) %8.4f `lr_z' _col(54) %8.4f `lr_p' ///
                   _col(63) "[" %7.4f `lr_lo' "," %7.4f `lr_hi' "]" _c
                _fbardl_stars `lr_p'
                mat drop _nlcom_b _nlcom_V
            }
            else {
                di as txt _col(5) "`xvar'" _col(20) as err "could not compute"
            }
        }
        di as txt "  {hline 68}"

        // ----- SR: Short-Run Coefficients (individual) -----
        di as txt ""
        di as txt "  {bf:SR — Short-Run Coefficients}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(28) "Coef." _col(40) "Std.Err." ///
           _col(52) "t-stat" _col(62) "p-value"
        di as txt "  {hline 68}"

        // Lagged dep diffs
        forvalues j = 1/`best_p' {
            local b = _b[L`j'.D.`depvar']
            local se = _se[L`j'.D.`depvar']
            local t = `b' / `se'
            local p = 2 * ttail(`df_r', abs(`t'))
            di as txt _col(5) "L`j'.D.`depvar'" _col(25) as res %10.6f `b' ///
               _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
            _fbardl_stars `p'
        }

        // Indepvar diffs (individual coefficients)
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            local q_this = `best_q_`cname''
            forvalues j = `j0'/`q_this' {
                if `j' == 0 {
                    local vname "D.`xvar'"
                }
                else {
                    local vname "L`j'.D.`xvar'"
                }
                local b = _b[`vname']
                local se = _se[`vname']
                local t = `b' / `se'
                local p = 2 * ttail(`df_r', abs(`t'))
                di as txt _col(5) "`vname'" _col(25) as res %10.6f `b' ///
                   _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
                _fbardl_stars `p'
            }
        }
        di as txt "  {hline 68}"

        // Joint significance of the whole short-run block
        local srall "`sr_depvars' `sr_indepvars'"
        if "`srall'" != "" {
            capture qui test `srall'
            if _rc == 0 {
                di as txt _col(5) "Joint test: all short-run coefficients = 0" ///
                   _col(49) as res %8.4f r(F) as txt " (p = " as res %6.4f r(p) as txt ")"
                di as txt "  {hline 68}"
            }
        }

        // ----- Fixed (exogenous) regressors -----
        if "`exogkeep'" != "" {
            di as txt ""
            di as txt "  {bf:FIXED — Fixed (Exogenous) Regressors}  " ///
               "{it:(excluded from the long-run relationship)}"
            di as txt "  {hline 68}"
            di as txt _col(5) "Variable" _col(28) "Coef." _col(40) "Std.Err." ///
               _col(52) "t-stat" _col(62) "p-value"
            di as txt "  {hline 68}"

            foreach v of local exogkeep {
                local b = _b[`v']
                local se = _se[`v']
                local t = `b' / `se'
                local p = 2 * ttail(`df_r', abs(`t'))
                di as txt _col(5) abbrev("`v'", 18) _col(25) as res %10.6f `b' ///
                   _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
                _fbardl_stars `p'
            }
            di as txt "  {hline 68}"
        }

        // ----- Deterministics: Fourier Terms & Constant -----
        di as txt ""
        di as txt "  {bf:Fourier Terms & Deterministics}"
        di as txt "  {hline 68}"

        if `best_kstar' > 0 {
            local b = _b[_fbardl_sin]
            local se = _se[_fbardl_sin]
            local t = `b' / `se'
            local p = 2 * ttail(`df_r', abs(`t'))
            di as txt _col(5) "sin(2pi*k*/T)" _col(25) as res %10.6f `b' ///
               _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
            _fbardl_stars `p'

            local b = _b[_fbardl_cos]
            local se = _se[_fbardl_cos]
            local t = `b' / `se'
            local p = 2 * ttail(`df_r', abs(`t'))
            di as txt _col(5) "cos(2pi*k*/T)" _col(25) as res %10.6f `b' ///
               _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
            _fbardl_stars `p'
        }

        if `hastrend' {
            local b = _b[_fbardl_trend]
            local se = _se[_fbardl_trend]
            local t = `b' / `se'
            local p = 2 * ttail(`df_r', abs(`t'))
            di as txt _col(5) "Trend (Case `case')" _col(25) as res %10.6f `b' ///
               _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
            _fbardl_stars `p'
        }

        local b = _b[_cons]
        local se = _se[_cons]
        local t = `b' / `se'
        local p = 2 * ttail(`df_r', abs(`t'))
        di as txt _col(5) "Constant" _col(25) as res %10.6f `b' ///
           _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
        _fbardl_stars `p'

        di as txt "  {hline 68}"
        di as txt _col(5) "{it:Stars: *** p<0.01, ** p<0.05, * p<0.10}"
        di as txt ""
    }

    // =========================================================================
    // TABLE 3: COINTEGRATION TESTS
    // =========================================================================
    // The F_ov restriction depends on the PSS case:
    //   Case 2: lagged levels AND the intercept
    //   Case 3: lagged levels only
    //   Case 4: lagged levels AND the trend coefficient
    //   Case 5: lagged levels only (trend is unrestricted)
    local fovterms "`levelvars'"
    if `case' == 2 local fovterms "`fovterms' _cons"
    if `case' == 4 local fovterms "`fovterms' _fbardl_trend"

    // Fov: joint test on the restricted deterministic/level terms
    qui test `fovterms'
    local Fov_stat = r(F)

    // t: t-statistic on lagged dependent variable
    local t_stat = `ecm_t'

    // Find: joint test on lagged independent levels only
    qui test `indeplev'
    local Find_stat = r(F)

    di as txt "{hline 78}"
    di as res _col(5) "Table 3: Cointegration Test Results"
    di as txt "{hline 78}"
    if "`vcetype'" != "ols" {
        di as txt _col(5) "Test statistics computed with " as res "`vcelabel'"
    }
    di as txt ""

    if "`type'" == "fardl" {
        // =====================================================================
        // PSS Bounds Test with Kripfganz & Schneider (2020) critical values
        // =====================================================================
        di as txt _col(5) "{bf:PSS Bounds Test} (Pesaran, Shin & Smith, 2001)"
        di as txt _col(5) "Critical values: Kripfganz & Schneider (2020)"
        di as txt ""

        // The tabulated bounds are derived under i.i.d. errors. With a robust
        // or HAC covariance matrix the statistics no longer follow the
        // distributions those bounds were simulated from, so the comparison is
        // an approximation. The bootstrap types re-derive their own critical
        // values under the same covariance estimator and are exact in that
        // sense; recommend them here.
        if "`vcetype'" != "ols" {
            di as err _col(5) "Warning: PSS / Kripfganz-Schneider bounds assume i.i.d. errors."
            di as err _col(5) "  With `vceshort' standard errors the tabulated bounds are only"
            di as err _col(5) "  approximate. For inference that is consistent with the chosen"
            di as err _col(5) "  covariance estimator use type(fbardl_mcnown) or type(fbardl_bvz),"
            di as err _col(5) "  which bootstrap the critical values under the same estimator."
            di as txt ""
        }

        // Compute the number of short-run coefficients (sr) for ardlbounds
        // sr = #lagged dep diffs + #lagged/contemp indep diffs
        //      + #Fourier terms + #fixed regressors
        local sr_count = `best_p'
        foreach xvar of local indepvars {
            local cname = subinstr("`xvar'", ".", "_", .)
            local sr_count = `sr_count' + `best_q_`cname'' + 1 - `j0'
        }
        if `best_kstar' > 0 {
            local sr_count = `sr_count' + 2
        }
        local sr_count = `sr_count' + `nexog_est'

        local k_pss = `nindep'
        local has_ardlbounds = 0

        // Try to use ardlbounds (Kripfganz & Schneider 2020 response surface)
        capture which ardlbounds
        if _rc == 0 {
            local has_ardlbounds = 1

            // --- F-statistic: finite-sample CVs and p-value ---
            capture noisily {
                qui ardlbounds, case(`case') stat(F) n(`nobs') k(`k_pss') ///
                    sr(`sr_count') siglevels(10 5 1) pvalue(`Fov_stat')
                tempname Fcvmat
                mat `Fcvmat' = r(cvmat)
                // cvmat is a single row; sig levels run across the columns
                // as consecutive I(0) I(1) pairs in the requested order
                // (siglevels(10 5 1)): cols 1-2 = 10%, cols 3-4 = 5%,
                // cols 5-6 = 1%. For F the last 2 cols are p-value(I0) p-value(I1).
                local F_I0_10 = `Fcvmat'[1, 1]
                local F_I1_10 = `Fcvmat'[1, 2]
                local F_I0_05 = `Fcvmat'[1, 3]
                local F_I1_05 = `Fcvmat'[1, 4]
                local F_I0_01 = `Fcvmat'[1, 5]
                local F_I1_01 = `Fcvmat'[1, 6]
                // p-values from last row
                local ncol_F = colsof(`Fcvmat')
                if `ncol_F' >= 8 {
                    local F_pv_I0 = `Fcvmat'[1, `ncol_F' - 1]
                    local F_pv_I1 = `Fcvmat'[1, `ncol_F']
                }
                else {
                    local F_pv_I0 = .
                    local F_pv_I1 = .
                }
            }
            if _rc != 0 local has_ardlbounds = 0

            // --- t-statistic: finite-sample CVs and p-value ---
            if `has_ardlbounds' == 1 {
                capture noisily {
                    qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') siglevels(10 5 1) pvalue(`t_stat')
                    tempname tcvmat
                    mat `tcvmat' = r(cvmat)
                    // single row; cols 1-2 = 10%, 3-4 = 5%, 5-6 = 1%
                    local t_I0_10 = `tcvmat'[1, 1]
                    local t_I1_10 = `tcvmat'[1, 2]
                    local t_I0_05 = `tcvmat'[1, 3]
                    local t_I1_05 = `tcvmat'[1, 4]
                    local t_I0_01 = `tcvmat'[1, 5]
                    local t_I1_01 = `tcvmat'[1, 6]
                    // p-values
                    local ncol_t = colsof(`tcvmat')
                    if `ncol_t' >= 8 {
                        local t_pv_I0 = `tcvmat'[1, `ncol_t' - 1]
                        local t_pv_I1 = `tcvmat'[1, `ncol_t']
                    }
                    else {
                        local t_pv_I0 = .
                        local t_pv_I1 = .
                    }
                }
                if _rc != 0 local has_ardlbounds = 0
            }
        }

        // Fallback: use PSS (2001) asymptotic critical values if ardlbounds unavailable
        if `has_ardlbounds' == 0 {
            di as txt _col(5) "{it:Note: ardlbounds not installed. Using PSS (2001) asymptotic CVs.}"
            di as txt _col(5) "{it:Install via: net install ardl, from(http://www.kripfganz.de/stata/)}"
            di as txt ""

            if `k_pss' == 1 {
                local F_I0_10 = 4.04
                local F_I1_10 = 4.78
                local F_I0_05 = 4.94
                local F_I1_05 = 5.73
                local F_I0_01 = 6.84
                local F_I1_01 = 7.84
                local t_I0_10 = -2.57
                local t_I1_10 = -2.91
                local t_I0_05 = -2.86
                local t_I1_05 = -3.22
                local t_I0_01 = -3.43
                local t_I1_01 = -3.82
            }
            else if `k_pss' == 2 {
                local F_I0_10 = 3.17
                local F_I1_10 = 4.14
                local F_I0_05 = 3.79
                local F_I1_05 = 4.85
                local F_I0_01 = 5.15
                local F_I1_01 = 6.36
                local t_I0_10 = -2.57
                local t_I1_10 = -3.21
                local t_I0_05 = -2.86
                local t_I1_05 = -3.53
                local t_I0_01 = -3.43
                local t_I1_01 = -4.10
            }
            else if `k_pss' == 3 {
                local F_I0_10 = 2.72
                local F_I1_10 = 3.77
                local F_I0_05 = 3.23
                local F_I1_05 = 4.35
                local F_I0_01 = 4.29
                local F_I1_01 = 5.61
                local t_I0_10 = -2.57
                local t_I1_10 = -3.46
                local t_I0_05 = -2.86
                local t_I1_05 = -3.78
                local t_I0_01 = -3.43
                local t_I1_01 = -4.37
            }
            else {
                local F_I0_10 = 2.45
                local F_I1_10 = 3.52
                local F_I0_05 = 2.86
                local F_I1_05 = 4.01
                local F_I0_01 = 3.74
                local F_I1_01 = 5.06
                local t_I0_10 = -2.57
                local t_I1_10 = -3.66
                local t_I0_05 = -2.86
                local t_I1_05 = -3.99
                local t_I0_01 = -3.43
                local t_I1_01 = -4.60
            }
            local F_pv_I0 = .
            local F_pv_I1 = .
            local t_pv_I0 = .
            local t_pv_I1 = .
        }

        // Display source info
        if `has_ardlbounds' == 1 {
            di as txt _col(5) "Finite-sample critical values" ///
               as txt " (k = " as res "`k_pss'" as txt ///
               ", N = " as res "`nobs'" as txt ///
               ", sr = " as res "`sr_count'" as txt ")"
        }
        di as txt ""

        // Table header
        di as txt "  {hline 76}"
        di as txt _col(5) "Test" _col(18) "Stat" ///
           _col(27) "  10% cv" _col(41) "   5% cv" _col(55) "   1% cv" ///
           _col(68) "p-value"
        di as txt _col(27) " I(0)  I(1)" _col(41) " I(0)  I(1)" ///
           _col(55) " I(0)  I(1)" _col(67) "I(0)  I(1)"
        di as txt "  {hline 76}"

        // F_overall row
        // Decision based on 5% critical values
        if `Fov_stat' > `F_I1_05' {
            local Fov_dec "Reject H0"
        }
        else if `Fov_stat' < `F_I0_05' {
            local Fov_dec "Fail to reject"
        }
        else {
            local Fov_dec "Inconclusive"
        }

        di as txt _col(3) "F_ov" _col(15) as res %7.3f `Fov_stat' ///
           _col(25) %6.3f `F_I0_10' " " %6.3f `F_I1_10' ///
           _col(39) %6.3f `F_I0_05' " " %6.3f `F_I1_05' ///
           _col(53) %6.3f `F_I0_01' " " %6.3f `F_I1_01' _c
        if `F_pv_I0' < . & `F_pv_I1' < . {
           di as res _col(67) %5.3f `F_pv_I0' " " %5.3f `F_pv_I1'
        }
        else {
           di as txt ""
        }

        // t_dependent row
        if `t_stat' < `t_I1_05' {
            local t_dec "Reject H0"
        }
        else if `t_stat' > `t_I0_05' {
            local t_dec "Fail to reject"
        }
        else {
            local t_dec "Inconclusive"
        }

        di as txt _col(3) "t_DV" _col(15) as res %7.3f `t_stat' ///
           _col(25) %6.3f `t_I0_10' " " %6.3f `t_I1_10' ///
           _col(39) %6.3f `t_I0_05' " " %6.3f `t_I1_05' ///
           _col(53) %6.3f `t_I0_01' " " %6.3f `t_I1_01' _c
        if `t_pv_I0' < . & `t_pv_I1' < . {
           di as res _col(67) %5.3f `t_pv_I0' " " %5.3f `t_pv_I1'
        }
        else {
           di as txt ""
        }

        // F_independent row
        di as txt _col(3) "F_ind" _col(15) as res %7.3f `Find_stat' ///
           _col(25) as txt "(standard PSS CVs not available; use bootstrap)"

        di as txt "  {hline 76}"

        // Decision summary
        di as txt ""
        di as txt _col(5) "{bf:Decision at 5% level:}"
        di as txt _col(7) "F_overall  : " _c
        if "`Fov_dec'" == "Reject H0" {
            di as res "`Fov_dec'"
        }
        else if "`Fov_dec'" == "Inconclusive" {
            di as err "`Fov_dec'"
        }
        else {
            di as txt "`Fov_dec'"
        }

        di as txt _col(7) "t_dependent: " _c
        if "`t_dec'" == "Reject H0" {
            di as res "`t_dec'"
        }
        else if "`t_dec'" == "Inconclusive" {
            di as err "`t_dec'"
        }
        else {
            di as txt "`t_dec'"
        }

        di as txt ""
        if "`Fov_dec'" == "Reject H0" & "`t_dec'" == "Reject H0" {
            di as res _col(5) "=> COINTEGRATION detected (Fov and t both reject at 5%)"
        }
        else if "`Fov_dec'" == "Reject H0" & "`t_dec'" != "Reject H0" {
            di as err _col(5) "=> POSSIBLE DEGENERATE CASE #2"
            di as err _col(5) "   (Fov significant but t not — `depvar' does not error-correct.)"
            di as err _col(5) "   F_ind has no tabulated PSS bounds; use type(fbardl_mcnown) or"
            di as err _col(5) "   type(fbardl_bvz) to test it and separate the degenerate cases."
        }
        else if "`Fov_dec'" == "Inconclusive" | "`t_dec'" == "Inconclusive" {
            di as err _col(5) "=> INCONCLUSIVE (consider bootstrap: type(fbardl_mcnown) or type(fbardl_bvz))"
        }
        else {
            di as txt _col(5) "=> NO COINTEGRATION detected at 5% level"
        }

        // Store PSS results for e()
        local Fov_pval = `F_pv_I1'
        local t_pval = `t_pv_I1'
        local Find_pval = .

        di as txt ""
    }
    else {
        // =====================================================================
        // BOOTSTRAP COINTEGRATION TEST
        // =====================================================================
        if "`type'" == "fbardl_mcnown" {
            di as txt _col(5) "{bf:Bootstrap ARDL Test} (McNown, Sam & Goh, 2018)"
            di as txt _col(5) "Unconditional bootstrap, `reps' replications"
        }
        else {
            di as txt _col(5) "{bf:Bootstrap ARDL Test} (Bertelli, Vacca & Zoia, 2022)"
            di as txt _col(5) "Conditional bootstrap, `reps' replications"
        }
        di as txt ""

        if "`vcetype'" != "ols" {
            di as txt _col(5) "Statistics and bootstrap distributions use " ///
               as res "`vcelabel'"
            di as txt ""
        }

        // Call bootstrap module
        // `regvars' already contains the fixed regressors; `exog' is passed
        // separately so the auxiliary/marginal DGP equations include them too.
        _fbardl_bootstrap D.`depvar' `regvars', ///
            depvar(`depvar') ///
            indepvars(`indepvars') ///
            levelvars(`levelvars') ///
            indeplev(`indeplev') ///
            ecmvar(`ecmvar') ///
            bootstrap_type(`type') ///
            reps(`reps') ///
            nobs(`nobs') ///
            best_p(`best_p') ///
            best_kstar(`best_kstar') ///
            timevar(`timevar') ///
            estcmd(`estcmd') ///
            estopt(`estopt') ///
            exog(`exog') ///
            fovterms(`fovterms') ///
            fovnocons(`fovnocons') ///
            trendvar(`trendvar') ///
            j0(`j0') ///
            bestq(`bestq_list') ///
            `dgpcheck'

        // Display bootstrap results
        local Fov_cv01 = r(Fov_cv01)
        local Fov_cv025 = r(Fov_cv025)
        local Fov_cv05 = r(Fov_cv05)
        local Fov_cv10 = r(Fov_cv10)
        local t_cv01 = r(t_cv01)
        local t_cv025 = r(t_cv025)
        local t_cv05 = r(t_cv05)
        local t_cv10 = r(t_cv10)
        local Find_cv01 = r(Find_cv01)
        local Find_cv025 = r(Find_cv025)
        local Find_cv05 = r(Find_cv05)
        local Find_cv10 = r(Find_cv10)
        local Fov_pval = r(Fov_pval)
        local t_pval = r(t_pval)
        local Find_pval = r(Find_pval)
        local nvalid_Fov  = r(nvalid_Fov)
        local nvalid_t    = r(nvalid_t)
        local nvalid_Find = r(nvalid_Find)

        // A replication that fails leaves its statistic missing. Missing
        // p-values must never be silently read as "fail to reject": in Stata
        // (. < 0.05) is false, which would report no cointegration whenever
        // the bootstrap itself broke down. Flag that case explicitly.
        local boot_ok = 1
        local minvalid = min(`nvalid_Fov', `nvalid_t', `nvalid_Find')
        if `minvalid' < ceil(0.5 * `reps') {
            local boot_ok = 0
            di as err _col(5) "Warning: only `minvalid' of `reps' bootstrap replications produced"
            di as err _col(5) "  a usable test statistic (Fov: `nvalid_Fov', t: `nvalid_t', Find: `nvalid_Find')."
            di as err _col(5) "  Bootstrap critical values and p-values are unreliable; no decision"
            di as err _col(5) "  is reported below. Check for collinearity in the bootstrap DGP,"
            di as err _col(5) "  reduce maxlag(), or drop fixed regressors that are near-constant"
            di as err _col(5) "  within the resampled series."
            di as txt ""
        }

        di as txt "  {hline 68}"
        di as txt _col(5) "Test" _col(20) "Statistic" _col(32) "p-value" ///
           _col(42) "1% cv" _col(50) "5% cv" _col(58) "10% cv" _col(66) "Decision"
        di as txt "  {hline 68}"

        // Fov
        if missing(`Fov_pval') {
            local Fov_dec "n/a"
        }
        else if `Fov_pval' < 0.05 {
            local Fov_dec "Reject H0"
        }
        else {
            local Fov_dec "Fail to reject"
        }
        di as txt _col(5) "F_overall" _col(18) as res %8.4f `Fov_stat' ///
           _col(30) %8.4f `Fov_pval' ///
           _col(40) %7.3f `Fov_cv01' _col(48) %7.3f `Fov_cv05' ///
           _col(56) %7.3f `Fov_cv10' _col(64) as txt "`Fov_dec'" _c
        _fbardl_stars `Fov_pval'

        // t
        if missing(`t_pval') {
            local t_dec "n/a"
        }
        else if `t_pval' < 0.05 {
            local t_dec "Reject H0"
        }
        else {
            local t_dec "Fail to reject"
        }
        di as txt _col(5) "t_dependent" _col(18) as res %8.4f `t_stat' ///
           _col(30) %8.4f `t_pval' ///
           _col(40) %7.3f `t_cv01' _col(48) %7.3f `t_cv05' ///
           _col(56) %7.3f `t_cv10' _col(64) as txt "`t_dec'" _c
        _fbardl_stars `t_pval'

        // Find
        if missing(`Find_pval') {
            local Find_dec "n/a"
        }
        else if `Find_pval' < 0.05 {
            local Find_dec "Reject H0"
        }
        else {
            local Find_dec "Fail to reject"
        }
        di as txt _col(5) "F_independent" _col(18) as res %8.4f `Find_stat' ///
           _col(30) %8.4f `Find_pval' ///
           _col(40) %7.3f `Find_cv01' _col(48) %7.3f `Find_cv05' ///
           _col(56) %7.3f `Find_cv10' _col(64) as txt "`Find_dec'" _c
        _fbardl_stars `Find_pval'

        di as txt "  {hline 68}"
        di as txt ""

        // Cointegration conclusion with degenerate case detection
        if `boot_ok' == 0 {
            di as err _col(5) "=> NO CONCLUSION: the bootstrap did not produce a usable"
            di as err _col(5) "   distribution (see the warning above). Do not interpret the"
            di as err _col(5) "   table as evidence for or against cointegration."
        }
        else if "`Fov_dec'" == "Reject H0" & "`t_dec'" == "Reject H0" & "`Find_dec'" == "Reject H0" {
            di as res _col(5) "=> COINTEGRATION detected"
            di as res _col(5) "   (Fov, t, and Find all significant — McNown et al. 2018 Case 1)"
        }
        else if "`Fov_dec'" != "Reject H0" & "`t_dec'" != "Reject H0" & "`Find_dec'" != "Reject H0" {
            di as txt _col(5) "=> NO COINTEGRATION"
            di as txt _col(5) "   (None of the test statistics are significant — Case 2)"
        }
        else if "`Fov_dec'" == "Reject H0" & "`t_dec'" == "Reject H0" & "`Find_dec'" != "Reject H0" {
            // McNown, Sam & Goh (2018, p.4): pi_yy != 0, pi_yx.x = 0.
            // The joint significance comes solely from the lagged dependent
            // variable, so the equation collapses to a generalised
            // Dickey-Fuller regression and y_t is in fact I(0).
            di as err _col(5) "=> DEGENERATE CASE #1 (degenerate lagged dependent variable)"
            di as err _col(5) "   (Fov & t significant but Find not — the level relationship comes"
            di as err _col(5) "    solely from L.`depvar'; the equation reduces to a generalised"
            di as err _col(5) "    Dickey-Fuller test, so `depvar' is likely I(0), not cointegrated)"
        }
        else if "`Fov_dec'" == "Reject H0" & "`Find_dec'" == "Reject H0" & "`t_dec'" != "Reject H0" {
            // McNown, Sam & Goh (2018, p.4): pi_yy = 0, pi_yx.x != 0.
            di as err _col(5) "=> DEGENERATE CASE #2 (degenerate lagged independent variable)"
            di as err _col(5) "   (Fov & Find significant but t not — `depvar' does not error-correct"
            di as err _col(5) "    towards the level relationship, so no cointegration)"
        }
        else {
            di as txt _col(5) "=> PARTIAL EVIDENCE: see individual test results above"
        }
        di as txt ""
    }

    // =========================================================================
    // RESTORE ESTIMATION (after bootstrap or ardlbounds)
    // =========================================================================
    // The bootstrap and ardlbounds calls overwrite e().
    // Restore the saved ARDL estimation.
    capture estimates restore _fbardl_main

    // =========================================================================
    // TABLE 4: DIAGNOSTIC TESTS
    // =========================================================================
    if "`nodiag'" == "" {
        di as txt "{hline 78}"
        di as res _col(5) "Table 4: Diagnostic Tests"
        di as txt "{hline 78}"
        if "`vcetype'" != "ols" {
            di as txt _col(5) "{it:Note: standard errors already correct for }" _c
            if "`vcetype'" == "robust" {
                di as txt "{it:heteroskedasticity (HC1).}"
            }
            else {
                di as txt "{it:heteroskedasticity and}"
                di as txt _col(5) "{it:autocorrelation (Newey-West, lag `nwlag').}"
            }
            di as txt _col(5) "{it:The tests below remain informative about the error process.}"
        }
        // The estat-based tests (Breusch-Godfrey, Durbin alternative,
        // Breusch-Pagan, White, ARCH LM, Ramsey RESET) need the OLS estimate
        // set: none of them is supported after newey / vce(robust)
        capture estimates restore _fbardl_ols
        _fbardl_diagtest, residvar(_fbardl_resid) nobs(`nobs') ///
            nparams(`nparams') lhs(D.`depvar') rhs(`regvars')
    }

    // Restore estimation again (diagnostics may have clobbered e())
    capture estimates restore _fbardl_main

    // =========================================================================
    // TABLE 5: DYNAMIC MULTIPLIERS
    // =========================================================================
    if "`nodynmult'" == "" {
        _fbardl_dynmult, depvar(`depvar') indepvars(`indepvars') ///
            p(`best_p') horizon(`horizon')
    }

    // =========================================================================
    // TABLE 6: ADVANCED ANALYSIS
    // =========================================================================
    if "`noadvanced'" == "" {
        // Restore estimation (dynamic multipliers may have clobbered e())
        capture estimates restore _fbardl_main

        local nofourier_opt ""
        if "`nofourier'" != "" | `best_kstar' == 0 {
            local nofourier_opt "nofourier"
        }
        _fbardl_advanced, depvar(`depvar') indepvars(`indepvars') ///
            ecmcoef(`ecm_coef') p(`best_p') horizon(`horizon') ///
            best_kstar(`best_kstar') `nofourier_opt'
    }

    // Clean up stored estimates
    capture estimates drop _fbardl_main
    capture estimates drop _fbardl_ols

    // =========================================================================
    // STORE e() RESULTS
    // =========================================================================
    ereturn clear
    ereturn post, obs(`nobs') esample(`touse')

    ereturn scalar N = `nobs'
    ereturn scalar best_p = `best_p'
    ereturn scalar best_kstar = `best_kstar'
    ereturn scalar ic_val = scalar(`best_ic_val')
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar ll = `ll'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_a'
    ereturn scalar F = `F_model'
    ereturn scalar df_m = `df_m'
    ereturn scalar df_r = `df_r'
    ereturn scalar rmse = `rmse'
    ereturn scalar Fov = `Fov_stat'
    ereturn scalar t_dep = `t_stat'
    ereturn scalar Find = `Find_stat'
    ereturn scalar ecm_coef = `ecm_coef'

    if inlist("`type'", "fbardl_mcnown", "fbardl_bvz") {
        ereturn scalar Fov_pval = `Fov_pval'
        ereturn scalar t_pval = `t_pval'
        ereturn scalar Find_pval = `Find_pval'
        ereturn scalar Fov_cv05 = `Fov_cv05'
        ereturn scalar t_cv05 = `t_cv05'
        ereturn scalar Find_cv05 = `Find_cv05'
        ereturn scalar reps = `reps'
    }
    else if "`type'" == "fardl" {
        // Store PSS p-values from ardlbounds (Kripfganz & Schneider 2020)
        capture {
            ereturn scalar Fov_pval_I0 = `F_pv_I0'
            ereturn scalar Fov_pval_I1 = `F_pv_I1'
            ereturn scalar t_pval_I0 = `t_pv_I0'
            ereturn scalar t_pval_I1 = `t_pv_I1'
        }
        // Store critical values
        capture {
            ereturn scalar F_I0_05 = `F_I0_05'
            ereturn scalar F_I1_05 = `F_I1_05'
            ereturn scalar t_I0_05 = `t_I0_05'
            ereturn scalar t_I1_05 = `t_I1_05'
        }
    }

    foreach xvar of local indepvars {
        local cname = subinstr("`xvar'", ".", "_", .)
        ereturn scalar best_q_`cname' = `best_q_`cname''
    }

    ereturn scalar n_exog = `nexog_est'
    if "`vcetype'" == "hac" {
        ereturn scalar haclags = `nwlag'
    }

    ereturn local cmd "fbardl"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local exog "`exog'"
    ereturn local type "`type'"
    ereturn local ic "`ic'"
    ereturn local vcetype "`vcetype'"
    ereturn local vce "`vcelabel'"
    ereturn scalar case = `case'
    if "`unconditional'" != "" {
        ereturn local ardlform "unconditional"
    }
    else {
        ereturn local ardlform "conditional"
    }
    ereturn local kstar_type "`kstar_type'"

    // =========================================================================
    // FINAL SUMMARY FOOTER
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "fbardl v1.2.0"
    di as txt "{hline 78}"

    // Clean up
    capture drop _fbardl_sin _fbardl_cos _fbardl_resid _fbardl_trend
    restore
end
