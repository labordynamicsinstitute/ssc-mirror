*! coefconv v1.0.0 — April 2026
*! Dr Noman Arshed, Sunway Business School, Sunway University
*! Comprehensive Marginal Effects from Regression Slope Coefficients
*! ─────────────────────────────────────────────────────────────────
*! Computes 23+ effect types: raw slopes, standardized slopes,
*! elasticities, semi-elasticities, basis-point effects, proportional
*! effects, Pratt importance, and discrete-change effects.
*!
*! Syntax:
*!   coefconv [, GRate(#) QUANtiles(numlist) DELTA(numlist)
*!             SAVing(filename[, replace]) noTABle FORmat(fmt)]
*!
*! Options:
*!   grate(#)       Growth rate for default ΔX = grate × X̄  (default 0.01)
*!   quantiles(…)   Extra percentiles beyond default {10 25 50 75 90}
*!   delta(…)       Custom ΔX list applied to every predictor
*!   saving(…)      Save wide results dataset (one row per predictor)
*!   notable        Suppress all display output
*!   format(fmt)    Stata number format (default %12.6f)
*!
*! Requires: prior OLS/IV/FE estimation with e(b), e(depvar), e(sample)
*! ─────────────────────────────────────────────────────────────────

capture program drop coefconv
program define coefconv, rclass
    version 14.0

    syntax [, ///
        GRate(real 0.01)                    ///
        QUANtiles(numlist >=1 <=99 integer) ///
        DELTA(numlist)                      ///
        SAVing(string asis)                 ///
        noTABle                             ///
        FORmat(string)                      ///
    ]

    // =========================================================================
    // 0. DEFAULTS & CONSTANTS
    // =========================================================================
    if "`format'" == "" local fmt "%12.6f"
    else                 local fmt "`format'"
    local lw  = 80   // display line width
    local c1  =  7   // label column
    local c2  = 55   // value column

    // =========================================================================
    // 1. VERIFY PRIOR ESTIMATION EXISTS
    // =========================================================================
    if "`e(cmd)'" == "" {
        di as error "coefconv: No estimation results found."
        di as error "        Please run a regression first (e.g., regress, ivregress, areg, xtreg)."
        exit 301
    }

    local ecmd    "`e(cmd)'"
    local depvar  "`e(depvar)'"
    local N       = e(N)
    local r2      = e(r2)
    local r2_a    = e(r2_a)
    local rmse    = e(rmse)

    // Warn if non-linear model (slopes ≠ marginal effects)
    local nl_cmds "logit probit xtlogit xtprobit tobit ologit oprobit"
    local is_nl = 0
    foreach c of local nl_cmds {
        if "`ecmd'" == "`c'" local is_nl = 1
    }
    if `is_nl' {
        di as text "(Warning: {bf:`ecmd'} is non-linear. " ///
                   "Slopes are linear approximations of marginal effects only.)"
    }

    // =========================================================================
    // 2. EXTRACT COEFFICIENT VECTOR & VARIABLE NAMES
    // =========================================================================
    tempname B
    matrix `B' = e(b)
    local allvars : colnames `B'

    // Build clean indepvars list: drop _cons and factor/base variables
    local indepvars ""
    foreach v of local allvars {
        if "`v'" == "_cons"                          continue
        if substr("`v'", 1, 2) == "o."               continue   // omitted
        if substr("`v'", 1, 2) == "b."               continue   // base
        local indepvars "`indepvars' `v'"
    }
    local k : word count `indepvars'
    if `k' == 0 {
        di as error "coefconv: No valid slope coefficients found in e(b)."
        exit 198
    }

    // =========================================================================
    // 3. DESCRIPTIVES FOR Y  (estimation sample only)
    // =========================================================================
    quietly summarize `depvar' if e(sample)
    local ymean = r(mean)
    local ysd   = r(sd)
    local ymin  = r(min)
    local ymax  = r(max)

    if `ymean' == 0 {
        di as text "(Warning: Mean of {bf:`depvar'} = 0. " ///
                   "Elasticity and proportional effects will be missing.)"
    }

    // =========================================================================
    // 4. ZERO-ORDER CORRELATIONS  r(Y, Xj)
    //    Build a clean list of actual dataset variables (skip factor notation)
    // =========================================================================
    local corr_vars ""
    foreach v of local indepvars {
        capture confirm variable `v'
        if !_rc local corr_vars "`corr_vars' `v'"
    }

    tempname CORR
    quietly correlate `depvar' `corr_vars' if e(sample)
    matrix `CORR' = r(C)
    // CORR[1, j+1] = r(depvar, Xj) for j in corr_vars

    // =========================================================================
    // 5. BUILD QUANTILE LIST  (default + user additions, always sorted)
    // =========================================================================
    local base_q "10 25 50 75 90"
    if "`quantiles'" != "" {
        local all_q : list base_q | quantiles
    }
    else {
        local all_q "`base_q'"
    }
    numlist "`all_q'", sort
    local all_q `r(numlist)'
    local nq : word count `all_q'

    // =========================================================================
    // 6. HEADER
    // =========================================================================
    if "`table'" == "" {
        di ""
        di as text "{hline `lw'}"
        di as text "  {bf:Marginal Effects Analysis  —  coefconv v1.0}"
        di as text "{hline `lw'}"
        di as text "  Model          : " as result "`ecmd'"
        di as text "  Dep. Variable  : " as result "`depvar'"
        di as text "  Observations   : " as result "`N'"
        if !missing(`r2') {
            di as text "  R² / Adj-R²    : " as result %8.6f `r2' ///
                       as text " / " as result %8.6f `r2_a'
        }
        if !missing(`rmse') {
            di as text "  RMSE           : " as result %12.6f `rmse'
        }
        di as text "  Ȳ  /  σ(Y)     : " as result %12.6f `ymean' ///
                   as text " / " as result %12.6f `ysd'
        di as text "  Growth rate ΔX : " as result "`=`grate'*100'%" ///
                   as text " of X̄   (override with {bf:delta()} option)"
        di as text "{hline `lw'}"
    }

    // =========================================================================
    // 7. MAIN LOOP — one block per predictor
    // =========================================================================
    local pratt_denom = 0    // accumulate for Pratt denominator
    local j       = 0        // index in e(b) columns
    local corr_j  = 0        // index in CORR matrix

    foreach v of local indepvars {
        local j = `j' + 1

        // --- Beta for this variable ---
        local beta = `B'[1, `j']

        // --- Check variable actually exists in dataset ---
        capture confirm variable `v'
        if _rc {
            if "`table'" == "" {
                di ""
                di as text "  [{it:Skipping factor/interaction term: {bf:`v'}" ///
                           " — β = " `fmt' `beta' "}]"
            }
            // Mark as factor/non-real for saving section
            local sv_ok_`j' = 0
            return scalar b_`v' = `beta'
            continue
        }

        local corr_j = `corr_j' + 1    // advance correlation index

        // --- X descriptives ---
        quietly summarize `v' if e(sample)
        local xmean  = r(mean)
        local xsd    = r(sd)
        local xmin   = r(min)
        local xmax   = r(max)
        local xrange = `xmax' - `xmin'

        if `xsd' == 0 | missing(`xsd') {
            if "`table'" == "" {
                di as text "  (Warning: SD of {bf:`v'} = 0. " ///
                           "SD-based effects set to missing.)"
            }
            local xsd = .
        }

        // --- Quantiles for X ---
        quietly _pctile `v' if e(sample), percentiles(`all_q')
        local qi = 0
        foreach q of local all_q {
            local qi = `qi' + 1
            local xpct_`q' = r(r`qi')
        }
        // Core quantile shortcuts (always present from base_q)
        local xp10  = `xpct_10'
        local xp25  = `xpct_25'
        local xmed  = `xpct_50'
        local xp75  = `xpct_75'
        local xp90  = `xpct_90'
        local xiqr  = `xp75' - `xp25'

        // --- Zero-order correlation ---
        local r_xy = `CORR'[1, `corr_j' + 1]

        // --- Default ΔX: growth rate × X̄ ---
        local dx_gr = `xmean' * `grate'

        // --- Store indexed locals for saving section (runs after clear) ---
        local sv_ok_`j'  = 1
        local sv_xm_`j'  = `xmean'
        local sv_xs_`j'  = `xsd'
        local sv_xmn_`j' = `xmin'
        local sv_xmx_`j' = `xmax'
        local sv_iqr_`j' = `xiqr'
        local sv_rxy_`j' = `r_xy'

        // =================================================================
        // COMPUTE ALL EFFECT FAMILIES
        // =================================================================

        // ── FAMILY 1: Raw & Standardized Slopes ──────────────────────────
        local f1_raw   = `beta'
        local f1_fstd  = cond(!missing(`xsd') & `ysd' > 0,  `beta' * `xsd' / `ysd',  .)
        local f1_xstd  = cond(!missing(`xsd'),               `beta' * `xsd',           .)
        local f1_ystd  = cond(`ysd' > 0,                     `beta' / `ysd',           .)

        // ── FAMILY 2: Elasticity & Semi-Elasticity ────────────────────────
        local f2_elas   = cond(`ymean' != 0,  `beta' * `xmean' / `ymean',         .)
        local f2_xsemi  = `beta' * `xmean'                            // ΔY per 1%ΔX × X̄/100
        local f2_ysemi  = cond(`ymean' != 0,  (`beta' / `ymean') * 100,           .)

        // ── FAMILY 3: Basis-Point & Percentage-Point Effects ──────────────
        local f3_bp    = `beta' / 10000
        local f3_pp    = `beta' / 100
        local f3_pct1  = `beta' * `xmean' / 100        // ΔY for 1% increase in X

        // ── FAMILY 4: Relative & Proportional Effects ─────────────────────
        local f4_prop  = cond(`ymean' != 0,  `beta' / `ymean',         .)
        local f4_pctY  = cond(`ymean' != 0, (`beta' / `ymean') * 100,  .)

        // ── FAMILY 5: Variance & Importance Measures ──────────────────────
        local f5_bsq    = cond(!missing(`f1_fstd'),  `f1_fstd'^2,           .)
        local f5_bxr    = `beta' * `r_xy'
        local f5_pratt  = cond(!missing(`f1_fstd'),  `f1_fstd' * `r_xy',   .)

        // Accumulate Pratt denominator
        if !missing(`f5_pratt') local pratt_denom = `pratt_denom' + `f5_pratt'

        // Save per-var Pratt numerator, β*, r for summary table
        local pratt_n_`j'  = `f5_pratt'
        local bstd_`j'     = `f1_fstd'
        local rxy_`j'      = `r_xy'
        local varname_`j'  = "`v'"

        // ── FAMILY 7: Discrete Change Effects ────────────────────────────
        local f7_growth = `beta' * `dx_gr'
        local f7_iqr    = `beta' * `xiqr'
        local f7_range  = `beta' * `xrange'
        local f7_1sd    = cond(!missing(`xsd'), `beta' * `xsd',      .)
        local f7_2sd    = cond(!missing(`xsd'), `beta' * 2 * `xsd',  .)

        // =================================================================
        // DISPLAY THIS VARIABLE'S BLOCK
        // =================================================================
        if "`table'" == "" {

            di ""
            di as result "  ┌─ Variable: {bf:`v'}" ///
               as text " ────────────────────────────────────────────────"
            di as text "  │  {bf:β}" as result " = " `fmt' `beta'
            di as text "  │  " ///
               "X̄ = "      as result %12.5f `xmean'  as text ///
               "   σX = "   as result %12.5f `xsd'   as text ///
               "   r(Y,X) = " as result %9.5f `r_xy'
            di as text "  │  " ///
               "Min = "  as result %10.4f `xmin'  as text ///
               "  Max = " as result %10.4f `xmax'  as text ///
               "  IQR = " as result %10.4f `xiqr'
            di as text "  ├" "{hline 72}"

            // Column headers
            di as text _col(`c1') "{bf:Effect Type}" ///
                       _col(`c2') "{bf:Estimate}"
            di as text "  ├" "{hline 72}"

            // ─ Family 1 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 1 ]  Raw & Standardized Slopes}"
            di as text _col(`c1') "Raw Slope  (β)" ///
                       _col(`c2') as result `fmt' `f1_raw'
            di as text _col(`c1') "Fully Standardized  (β* = β·σX/σY)" ///
                       _col(`c2') as result `fmt' `f1_fstd'
            di as text _col(`c1') "X-Standardized      (β·σX)" ///
                       _col(`c2') as result `fmt' `f1_xstd'
            di as text _col(`c1') "Y-Standardized      (β/σY)" ///
                       _col(`c2') as result `fmt' `f1_ystd'

            // ─ Family 2 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 2 ]  Elasticity & Semi-Elasticity}"
            di as text _col(`c1') "Point Elasticity at Means  (β·X̄/Ȳ)" ///
                       _col(`c2') as result `fmt' `f2_elas'
            di as text _col(`c1') "X-Semi-Elasticity  (β·X̄  → ΔY per 1%ΔX)" ///
                       _col(`c2') as result `fmt' `f2_xsemi'
            di as text _col(`c1') "Y-Semi-Elasticity  (β/Ȳ·100 → %ΔY per ΔX)" ///
                       _col(`c2') as result `fmt' `f2_ysemi'

            // ─ Family 3 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 3 ]  Basis-Point & Percentage-Point Effects}"
            di as text _col(`c1') "Basis-Point Effect      (β ÷ 10,000)" ///
                       _col(`c2') as result `fmt' `f3_bp'
            di as text _col(`c1') "Percentage-Point Effect (β ÷ 100)" ///
                       _col(`c2') as result `fmt' `f3_pp'
            di as text _col(`c1') "Per-1%-of-X Effect      (β·X̄÷100)" ///
                       _col(`c2') as result `fmt' `f3_pct1'

            // ─ Family 4 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 4 ]  Relative & Proportional Effects}"
            di as text _col(`c1') "Proportional ME      (β / Ȳ)" ///
                       _col(`c2') as result `fmt' `f4_prop'
            di as text _col(`c1') "% of Mean-Y ME       (β/Ȳ · 100)" ///
                       _col(`c2') as result `fmt' `f4_pctY'

            // ─ Family 5 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 5 ]  Variance & Importance Measures}"
            di as text _col(`c1') "Squared Std. Coef.   (β*²)" ///
                       _col(`c2') as result `fmt' `f5_bsq'
            di as text _col(`c1') "Product Measure      (β · r_XY)" ///
                       _col(`c2') as result `fmt' `f5_bxr'
            di as text _col(`c1') "Pratt Numerator      (β* · r_XY)" ///
                       _col(`c2') as result `fmt' `f5_pratt'
            di as text _col(`c1') "{it:Pratt % of R² shown in summary table below}"

            // ─ Family 6 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 6 ]  Discrete ΔY: Median → Each Quantile}"
            foreach q of local all_q {
                local dX_q  = `xpct_`q'' - `xmed'
                local dY_q  = `beta' * `dX_q'
                // Build sign string manually (Stata di has no %+f flag)
                local sgn = cond(`dX_q' >= 0, "+", "")
                di as text _col(`c1') "p50 → p`q'" ///
                    "  (X_p`q' = " as result %8.4f `xpct_`q'' ///
                    as text ",  ΔX = `sgn'" as result %9.4f `dX_q' ///
                    as text ")" _col(`c2') as result `fmt' `dY_q'
            }

            // ─ Family 7 ──────────────────────────────────────────────────
            di as text _col(`c1') "{bf:[ 7 ]  Discrete Change Effects}"
            di as text _col(`c1') "Growth-Rate ΔX  (`=`grate'*100'% x Xbar = " ///
                       as result %8.5f `dx_gr' as text ")" ///
                       _col(`c2') as result `fmt' `f7_growth'
            di as text _col(`c1') "IQR Effect      (Q75 - Q25 = " ///
                       as result %8.5f `xiqr' as text ")" ///
                       _col(`c2') as result `fmt' `f7_iqr'
            di as text _col(`c1') "Full-Range      (Max - Min  = " ///
                       as result %8.5f `xrange' as text ")" ///
                       _col(`c2') as result `fmt' `f7_range'
            di as text _col(`c1') "+/-1 SD         (sigmaX = " ///
                       as result %8.5f `xsd' as text ")" ///
                       _col(`c2') as result `fmt' `f7_1sd'
            di as text _col(`c1') "+/-2 SD         (2*sigmaX = " ///
                       as result %8.5f 2*`xsd' as text ")" ///
                       _col(`c2') as result `fmt' `f7_2sd'

            // Custom ΔX values
            if "`delta'" != "" {
                di as text _col(`c1') "{bf:[ + ]  Custom ΔX Values}"
                local nd = 0
                foreach d of local delta {
                    local nd = `nd' + 1
                    di as text _col(`c1') "Custom ΔX = `d'" ///
                               _col(`c2') as result `fmt' `beta' * `d'
                }
            }

            di as text "  └" "{hline 72}"

        } // end "`table'" == ""

        // Store return scalars for this variable
        return scalar b_`v'       = `f1_raw'
        return scalar bstd_`v'    = `f1_fstd'
        return scalar elas_`v'    = `f2_elas'
        return scalar ysemi_`v'   = `f2_ysemi'
        return scalar pratt_n_`v' = `f5_pratt'

    } // end foreach v (main loop)

    // =========================================================================
    // 8. PRATT'S RELATIVE IMPORTANCE SUMMARY TABLE
    // =========================================================================
    if "`table'" == "" {
        di ""
        di as text "{hline `lw'}"
        di as text "  {bf:Pratt's Relative Importance  —  Decomposition of R²}"
        di as text "{hline `lw'}"
        di as text _col(5)  "{bf:Variable}" ///
                   _col(22) "{bf:β* (Std. Coef.)}" ///
                   _col(40) "{bf:r(Y, X)}" ///
                   _col(54) "{bf:Pratt Raw}" ///
                   _col(68) "{bf:% of R²}"
        di as text "  {hline 76}"

        forvalues jj = 1/`j' {
            local vn  = "`varname_`jj''"
            local bs  = `bstd_`jj''
            local rx  = `rxy_`jj''
            local pn  = `pratt_n_`jj''

            local pp = cond(!missing(`pn') & `pratt_denom' != 0, ///
                           `pn' / `pratt_denom' * 100, .)

            di as text _col(5) "`vn'" ///
               as result _col(22) %14.6f `bs' ///
                         _col(40) %10.6f `rx' ///
                         _col(54) %10.6f `pn' ///
                         _col(68) %8.3f  `pp'  as text "%"

            return scalar pratt_pct_`vn' = `pp'
        }

        di as text "  {hline 76}"
        di as text _col(5) "Total" ///
           as result _col(54) %10.6f `pratt_denom' ///
                     _col(68) "100.000%"
        di as text "{hline `lw'}"
    }

    // =========================================================================
    // 9. SAVE WIDE RESULTS DATASET
    // =========================================================================
    if `"`saving'"' != "" {

        // Parse "filename [, replace]"
        local savefile ""
        local saverep  ""
        tokenize `"`saving'"', parse(",")
        local savefile = trim("`1'")
        if trim("`3'") == "replace" local saverep "replace"

        preserve
            clear
            quietly set obs `j'

            // Variable identifier
            gen str40  varname     = ""
            label var  varname     "Variable name"

            // Family 1
            gen double beta        = .
            label var  beta        "Raw slope coefficient (beta)"
            gen double beta_fstd   = .
            label var  beta_fstd   "Fully standardized slope (beta*)"
            gen double beta_xstd   = .
            label var  beta_xstd   "X-standardized slope (beta x sdX)"
            gen double beta_ystd   = .
            label var  beta_ystd   "Y-standardized slope (beta / sdY)"

            // Family 2
            gen double elasticity  = .
            label var  elasticity  "Point elasticity at means"
            gen double xsemi_elas  = .
            label var  xsemi_elas  "X-semi-elasticity (beta x Xbar)"
            gen double ysemi_elas  = .
            label var  ysemi_elas  "Y-semi-elasticity pct (beta/Ybar x 100)"

            // Family 3
            gen double bp_effect   = .
            label var  bp_effect   "Basis-point effect (beta / 10000)"
            gen double pp_effect   = .
            label var  pp_effect   "Pct-point effect (beta / 100)"
            gen double pct1_effect = .
            label var  pct1_effect "Per-1%-of-X effect (beta x Xbar / 100)"

            // Family 4
            gen double prop_me     = .
            label var  prop_me     "Proportional ME (beta / Ybar)"
            gen double pctY_me     = .
            label var  pctY_me     "Pct of mean-Y ME (beta/Ybar x 100)"

            // Family 5
            gen double betasq      = .
            label var  betasq      "Squared std. coef. (beta*^2)"
            gen double prod_br     = .
            label var  prod_br     "Product measure (beta x r_XY)"
            gen double pratt_raw   = .
            label var  pratt_raw   "Pratt numerator (beta* x r_XY)"
            gen double pratt_pct   = .
            label var  pratt_pct   "Pratt pct of R-squared"

            // Family 7
            gen double disc_growth = .
            label var  disc_growth "Discrete: growth-rate delta-X"
            gen double disc_iqr    = .
            label var  disc_iqr    "Discrete: IQR change"
            gen double disc_range  = .
            label var  disc_range  "Discrete: full range"
            gen double disc_1sd    = .
            label var  disc_1sd    "Discrete: +/- 1 SD"
            gen double disc_2sd    = .
            label var  disc_2sd    "Discrete: +/- 2 SD"

            // Descriptives
            gen double r_xy        = .
            label var  r_xy        "Zero-order correlation r(Y,X)"
            gen double xmean       = .
            label var  xmean       "Mean of X"
            gen double xsd         = .
            label var  xsd         "SD of X"
            gen double xmin_v      = .
            label var  xmin_v      "Min of X"
            gen double xmax_v      = .
            label var  xmax_v      "Max of X"
            gen double xiqr_v      = .
            label var  xiqr_v      "IQR of X"

            // Populate rows using indexed locals computed in main loop
            // (avoids capture confirm variable / summarize inside cleared dataset)
            local jj = 0

            foreach v of local indepvars {
                local jj = `jj' + 1
                local bj = `B'[1, `jj']

                // Factor/interaction variable: store name + beta only
                if `sv_ok_`jj'' == 0 {
                    quietly replace varname = "`v'" in `jj'
                    quietly replace beta    = `bj'  in `jj'
                    continue
                }

                // Retrieve pre-computed stats
                local xm  = `sv_xm_`jj''
                local xs  = `sv_xs_`jj''
                local xmn = `sv_xmn_`jj''
                local xmx = `sv_xmx_`jj''
                local iq  = `sv_iqr_`jj''
                local rxv = `sv_rxy_`jj''
                local xrg = `xmx' - `xmn'

                local fs  = cond(!missing(`xs') & `ysd'>0, `bj'*`xs'/`ysd', .)
                local pn  = cond(!missing(`fs'), `fs'*`rxv', .)
                local pp  = cond(!missing(`pn') & `pratt_denom'!=0, `pn'/`pratt_denom'*100, .)

                quietly {
                    replace varname     = "`v'"                                   in `jj'
                    replace beta        = `bj'                                    in `jj'
                    replace beta_fstd   = `fs'                                    in `jj'
                    replace beta_xstd   = cond(!missing(`xs'), `bj'*`xs', .)     in `jj'
                    replace beta_ystd   = cond(`ysd'>0, `bj'/`ysd', .)           in `jj'
                    replace elasticity  = cond(`ymean'!=0, `bj'*`xm'/`ymean', .) in `jj'
                    replace xsemi_elas  = `bj'*`xm'                               in `jj'
                    replace ysemi_elas  = cond(`ymean'!=0, `bj'/`ymean'*100, .)  in `jj'
                    replace bp_effect   = `bj'/10000                              in `jj'
                    replace pp_effect   = `bj'/100                                in `jj'
                    replace pct1_effect = `bj'*`xm'/100                           in `jj'
                    replace prop_me     = cond(`ymean'!=0, `bj'/`ymean', .)      in `jj'
                    replace pctY_me     = cond(`ymean'!=0, `bj'/`ymean'*100, .)  in `jj'
                    replace betasq      = cond(!missing(`fs'), `fs'^2, .)        in `jj'
                    replace prod_br     = `bj'*`rxv'                              in `jj'
                    replace pratt_raw   = `pn'                                    in `jj'
                    replace pratt_pct   = `pp'                                    in `jj'
                    replace disc_growth = `bj'*`xm'*`grate'                       in `jj'
                    replace disc_iqr    = `bj'*`iq'                               in `jj'
                    replace disc_range  = `bj'*`xrg'                              in `jj'
                    replace disc_1sd    = cond(!missing(`xs'), `bj'*`xs', .)     in `jj'
                    replace disc_2sd    = cond(!missing(`xs'), `bj'*2*`xs', .)   in `jj'
                    replace r_xy        = `rxv'                                    in `jj'
                    replace xmean       = `xm'                                     in `jj'
                    replace xsd         = `xs'                                     in `jj'
                    replace xmin_v      = `xmn'                                    in `jj'
                    replace xmax_v      = `xmx'                                    in `jj'
                    replace xiqr_v      = `iq'                                     in `jj'
                }
            }

            label var varname "Variable name"
            note: coefconv results — model: `ecmd', dep. var.: `depvar', N=`N'

            save `"`savefile'"', `saverep'
            di as text "(coefconv: Wide results saved to {bf:`savefile'})"
        restore
    }

    // =========================================================================
    // 10. RETURN SCALARS
    // =========================================================================
    return scalar N          = `N'
    return scalar r2         = `r2'
    return scalar ymean      = `ymean'
    return scalar ysd        = `ysd'
    return scalar pratt_tot  = `pratt_denom'
    return local  depvar       "`depvar'"
    return local  indepvars    "`indepvars'"

end
