*! wavenardl 1.0.1  02jul2026
*! Wavelet-based Nonlinear ARDL (W-NARDL)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*!
*! Implements the wavelet-based NARDL of:
*!   Jammazi, Lahiani & Nguyen (2015), J. Int. Fin. Markets, Inst. & Money 34, 173-187.
*! combined with the NARDL framework of:
*!   Shin, Yu & Greenwood-Nimmo (2014) and the bounds test of
*!   Pesaran, Shin & Smith (2001).
*! Denoising: Haar "a trous" wavelet transform (Murtagh, Starck & Renaud 2004)
*! with the Donoho (1995) universal threshold.

capture program drop wavenardl
program define wavenardl, eclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX
    // =========================================================================
    syntax varlist(min=1 numeric) [if] [in], ///
        Decompose(varlist numeric min=1)     /// variable(s) split into pos/neg partial sums
        [                                    ///
        MAXLag(integer 4)                    /// maximum lag in the grid search
        IC(string)                           /// aic or bic (default: bic)
        LEVels(integer 0)                    /// wavelet levels J (0 = floor(log2(N)))
        THReshold(string)                    /// soft or hard (default: soft)
        DENoise(string)                      /// all, dep, indep or none (default: all)
        TREND                                /// include linear trend (PSS case V)
        NOCOMPare                            /// skip the raw-data NARDL comparison
        HORizon(integer 20)                  /// dynamic multiplier horizon
        Level(cilevel)                       /// confidence level
        GENerate(string)                     /// stub: save denoised series as stub_var
        NODIag NODYNmult NOTable NOGraph     ///
        ]

    marksample touse
    markout `touse' `decompose'

    // ---- validate options ----
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }
    if "`threshold'" == "" local threshold "soft"
    local threshold = lower("`threshold'")
    if !inlist("`threshold'", "soft", "hard") {
        di as err "threshold() must be {bf:soft} or {bf:hard}"
        exit 198
    }
    if "`denoise'" == "" local denoise "all"
    local denoise = lower("`denoise'")
    if !inlist("`denoise'", "all", "dep", "indep", "none") {
        di as err "denoise() must be {bf:all}, {bf:dep}, {bf:indep} or {bf:none}"
        exit 198
    }
    if `maxlag' < 1 {
        di as err "maxlag() must be >= 1"
        exit 198
    }
    if `levels' < 0 {
        di as err "levels() must be >= 0"
        exit 198
    }
    if "`denoise'" == "none" & "`nocompare'" == "" {
        // nothing to compare against
        local nocompare "nocompare"
    }
    local case = 3
    if "`trend'" != "" local case = 5

    // depvar = first variable, remaining = non-decomposed controls
    gettoken depvar controls : varlist

    // decomposed variables must not repeat the dependent variable
    foreach xvar of local decompose {
        if "`xvar'" == "`depvar'" {
            di as err "the dependent variable cannot appear in decompose()"
            exit 198
        }
    }
    // drop decompose vars from controls if the user listed them twice
    local controls : list controls - decompose

    local ndec  : word count `decompose'
    local nctrl : word count `controls'

    // time-series check
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "wavenardl is designed for time-series data only, not panel data"
        exit 198
    }

    // generate() target names must not exist
    if "`generate'" != "" {
        foreach v in `depvar' `controls' `decompose' {
            capture confirm new variable `generate'_`v'
            if _rc {
                di as err "variable `generate'_`v' already exists"
                exit 110
            }
        }
    }

    // =========================================================================
    // 2. PRESERVE & PREPARE
    // =========================================================================
    preserve

    qui keep if `touse'
    qui count
    local nobs = r(N)
    if `nobs' < 30 {
        di as err "Too few observations (`nobs'). Need at least 30."
        exit 2001
    }

    tempvar tindex
    qui gen `tindex' = _n

    // marker for the Mata routines (all kept rows are usable)
    tempvar wnall
    qui gen byte `wnall' = 1

    // =========================================================================
    // 3. WAVELET DENOISING (Haar a trous + Donoho threshold)
    // =========================================================================
    // Which variables get denoised
    local dnvars ""
    if "`denoise'" == "all"   local dnvars "`depvar' `decompose' `controls'"
    if "`denoise'" == "dep"   local dnvars "`depvar'"
    if "`denoise'" == "indep" local dnvars "`decompose' `controls'"

    local softflag = cond("`threshold'" == "soft", 1, 0)
    local ndn : word count `dnvars'

    di as txt ""
    di as txt "{hline 70}"
    di as res "  Wavelet-Based Nonlinear ARDL (W-NARDL)"
    di as txt "{hline 70}"
    di as txt "  Dependent variable : " as res "`depvar'"
    di as txt "  Decomposed var(s)  : " as res "`decompose'"
    if `nctrl' > 0 {
        di as txt "  Control var(s)     : " as res "`controls'"
    }
    di as txt "  Max lag            : " as res "`maxlag'"
    di as txt "  Info criterion     : " as res upper("`ic'")
    di as txt "  PSS case           : " as res cond(`case'==5, "V (unrestricted trend)", "III (unrestricted intercept)")
    di as txt "  Wavelet            : " as res "Haar a trous (HTW)"
    di as txt "  Threshold          : " as res "`threshold'" as txt " (Donoho universal)"
    di as txt "  Denoised series    : " as res cond("`denoise'"=="none", "none (plain NARDL)", "`dnvars'")
    di as txt "  Observations       : " as res "`nobs'"
    di as txt "{hline 70}"

    if `ndn' > 0 {
        di as txt ""
        di as txt "{hline 70}"
        di as res "  Table 1: Wavelet Denoising Summary"
        di as txt "{hline 70}"
        di as txt _col(3) "Variable" _col(20) "Levels J" _col(32) "sigma(noise)" _col(48) "lambda" _col(60) "SD reduction"
        di as txt "{hline 70}"
    }

    local dncount = 0
    foreach v of local dnvars {
        local dncount = `dncount' + 1

        // raw copy (for the comparison model and the final swap-back)
        qui gen double __wnr_`dncount' = `v'

        qui sum `v'
        local sd_before = r(sd)

        // denoise in place
        mata: _wnardl_htw("`v'", "`v'", "`wnall'", `levels', `softflag')

        local sig_`dncount' = scalar(__wn_sigma)
        local lam_`dncount' = scalar(__wn_lambda)
        local Jl_`dncount'  = scalar(__wn_J)
        scalar drop __wn_sigma __wn_lambda __wn_J

        // denoised copy
        qui gen double __wnd_`dncount' = `v'

        qui sum `v'
        local sd_after = r(sd)
        local sd_red = 100 * (1 - `sd_after' / `sd_before')

        di as txt _col(3) "`v'" _col(20) as res %6.0f `Jl_`dncount'' ///
            _col(32) %10.4f `sig_`dncount'' _col(46) %10.4f `lam_`dncount'' ///
            _col(60) %8.2f `sd_red' "%"

        // before/after plot
        if "`nograph'" == "" {
            capture {
                twoway (line __wnr_`dncount' `tindex', lcolor(gs10) lwidth(thin)) ///
                       (line `v' `tindex', lcolor(navy) lwidth(medthick)), ///
                       title("Wavelet Denoising: `v'", size(medium)) ///
                       subtitle("Haar a trous, `threshold' threshold", size(small)) ///
                       ytitle("`v'", size(small)) xtitle("Observation", size(small)) ///
                       legend(order(1 "Original" 2 "Denoised") size(small) rows(1)) ///
                       note("wavenardl package", size(vsmall)) ///
                       name(wden_`v', replace)
            }
            capture qui graph export "wden_`v'.png", replace width(1200)
        }
    }
    if `ndn' > 0 {
        di as txt "{hline 70}"
        di as txt "  sigma estimated by MAD of level-1 details; lambda = sigma*sqrt(2*ln(N))"
        di as txt "  Ref: Donoho (1995); Murtagh, Starck & Renaud (2004)"
        di as txt "{hline 70}"
    }

    // trend variable if requested
    local trendopt ""
    if "`trend'" != "" {
        qui gen double __wn_trend = `tindex'
        local trendopt "trendvar(__wn_trend)"
    }

    // =========================================================================
    // 4. FIT W-NARDL ON THE (DENOISED) SERIES
    // =========================================================================
    di as txt ""
    di as txt "  Searching for the optimal NARDL specification on the " ///
        as res cond("`denoise'"=="none", "raw", "denoised") as txt " series..."

    _wavenardl_engine, depvar(`depvar') decompose(`decompose') ///
        controls(`controls') maxlag(`maxlag') ic(`ic') `trendopt'

    local best_p = r(best_p)
    local dec_names "`r(dec_names)'"
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local best_q_`dec_i' = r(best_q_`dec_i')
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local best_r_`i' = r(best_r_`i')
        }
    }
    local best_formula "`r(formula)'"
    local total_models = r(models)
    local best_ic_w = r(icval)
    local aic_w  = r(aic)
    local bic_w  = r(bic)
    local ll_w   = r(ll)
    local r2_w   = r(r2)
    local r2a_w  = r(r2_a)
    local dw_w   = r(dw)
    local N_w    = r(N)
    local k_w    = r(k)

    local nobs_used = `N_w'
    local nparams   = `k_w'

    // residuals of the active best model
    tempvar resid
    qui predict double `resid', residuals

    // =========================================================================
    // 5. TABLE 2: MODEL SELECTION
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    di as res "  Table 2: Model Selection (W-NARDL)"
    di as txt "{hline 70}"
    di as txt "  Models evaluated                   : " as res "`total_models'"
    di as txt "  Selected lag p (depvar lags)       : " as res `best_p'
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        di as txt "  Selected lag q (`cname' lags)" _col(40) ": " as res `best_q_`dec_i''
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local cvar : word `i' of `controls'
            di as txt "  Selected lag r (`cvar' lags)" _col(40) ": " as res `best_r_`i''
        }
    }
    di as txt "  Information criterion (" upper("`ic'") ")      : " as res %12.4f `best_ic_w'
    di as txt "  AIC                                : " as res %12.4f `aic_w'
    di as txt "  BIC                                : " as res %12.4f `bic_w'
    di as txt "  Log-likelihood                     : " as res %12.4f `ll_w'
    di as txt "  Observations (used)                : " as res `nobs_used'
    di as txt "  R-squared                          : " as res %8.4f `r2_w'
    di as txt "  Adjusted R-squared                 : " as res %8.4f `r2a_w'
    di as txt "  Durbin-Watson                      : " as res %8.4f `dw_w'
    di as txt "{hline 70}"

    // build the lag vector string:  WNARDL(p, q1, ..., r1, ...)
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
    di as res _col(5) "Model: W-NARDL(`best_p'`lag_vec')"
    di as txt ""

    // =========================================================================
    // 6. TABLE 3: ESTIMATION RESULTS
    // =========================================================================
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as res "  Table 3: Estimation Results (Dependent Variable: D.`depvar', denoised)"
        di as txt "{hline 78}"
        di as txt _col(3) "Variable" _col(25) "Coef." _col(38) "Std.Err." _col(51) "t-stat" _col(63) "p-value"
        di as txt "{hline 78}"

        di as res "  Panel A: Short-Run Dynamics"
        di as txt "{hline 78}"

        di as txt _col(3) "{it:Lagged D.`depvar'}"
        forvalues j = 1/`best_p' {
            local vname "L`j'.D.`depvar'"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "`vname'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _wavenardl_stars `p_val'
            }
        }

        local dec_i = 0
        foreach cname of local dec_names {
            di as txt ""
            local dec_i = `dec_i' + 1
            local this_q = `best_q_`dec_i''
            di as txt _col(3) "{it:D.`cname' (decomposed, lag q=`this_q')}"
            forvalues j = 0/`this_q' {
                foreach sgn in pos neg {
                    if `j' == 0 {
                        local vname "D.`cname'_`sgn'"
                    }
                    else {
                        local vname "L`j'.D.`cname'_`sgn'"
                    }
                    capture local coef_val = _b[`vname']
                    if _rc == 0 {
                        local se_val = _se[`vname']
                        local t_val = `coef_val' / `se_val'
                        local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                        di as txt _col(5) "`vname'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                        _wavenardl_stars `p_val'
                    }
                }
            }
        }

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
                    }
                    else {
                        local vname "L`j'.D.`cvar'"
                    }
                    capture local coef_val = _b[`vname']
                    if _rc == 0 {
                        local se_val = _se[`vname']
                        local t_val = `coef_val' / `se_val'
                        local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                        di as txt _col(5) "`vname'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                        _wavenardl_stars `p_val'
                    }
                }
            }
        }

        di as txt ""
        di as txt "{hline 78}"
        di as res "  Panel B: Long-Run (ECM Level) Coefficients"
        di as txt "{hline 78}"

        local vname "L.`depvar'"
        capture local coef_val = _b[`vname']
        if _rc == 0 {
            local se_val = _se[`vname']
            local t_val = `coef_val' / `se_val'
            local p_val = 2 * ttail(e(df_r), abs(`t_val'))
            di as txt _col(5) "L.`depvar'" _col(20) "(ECM/rho)" _col(33) as res %10.4f `coef_val' _col(46) %10.4f `se_val' _col(59) %8.3f `t_val' _col(71) %8.4f `p_val' _c
            _wavenardl_stars `p_val'
        }

        foreach cname of local dec_names {
            foreach sgn in pos neg {
                local vname "L.`cname'_`sgn'"
                capture local coef_val = _b[`vname']
                if _rc == 0 {
                    local se_val = _se[`vname']
                    local t_val = `coef_val' / `se_val'
                    local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                    di as txt _col(5) "`vname'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                    _wavenardl_stars `p_val'
                }
            }
        }

        foreach cvar of local controls {
            local vname "L.`cvar'"
            capture local coef_val = _b[`vname']
            if _rc == 0 {
                local se_val = _se[`vname']
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "`vname'" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _wavenardl_stars `p_val'
            }
        }

        if "`trend'" != "" {
            capture local coef_val = _b[__wn_trend]
            if _rc == 0 {
                local se_val = _se[__wn_trend]
                local t_val = `coef_val' / `se_val'
                local p_val = 2 * ttail(e(df_r), abs(`t_val'))
                di as txt _col(5) "trend" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
                _wavenardl_stars `p_val'
            }
        }

        capture local coef_val = _b[_cons]
        if _rc == 0 {
            local se_val = _se[_cons]
            local t_val = `coef_val' / `se_val'
            local p_val = 2 * ttail(e(df_r), abs(`t_val'))
            di as txt _col(5) "_cons" _col(23) as res %10.4f `coef_val' _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
            _wavenardl_stars `p_val'
        }

        di as txt "{hline 78}"
        di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
        di as txt "{hline 78}"
    }

    // =========================================================================
    // 7. TABLE 4: SHORT-RUN & LONG-RUN MULTIPLIERS
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    di as res "  Table 4: Short-Run & Long-Run Multipliers"
    di as txt "{hline 70}"

    local ecm_coef_name "L.`depvar'"

    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local this_q = `best_q_`dec_i''
        local lpos_name "L.`cname'_pos"
        local lneg_name "L.`cname'_neg"

        // short-run multipliers (sum of D coefficients) with lincom SEs
        local saved_df_sr = e(df_r)
        foreach sgn in pos neg {
            local sr_`sgn' = .
            local sr_`sgn'_se = .
            local sr_`sgn'_t = .
            local sr_`sgn'_p = .
            local lc_expr "D.`cname'_`sgn'"
            forvalues j = 1/`this_q' {
                local lc_expr "`lc_expr' + L`j'.D.`cname'_`sgn'"
            }
            capture qui lincom `lc_expr'
            if _rc == 0 {
                local sr_`sgn' = r(estimate)
                local sr_`sgn'_se = r(se)
                local sr_`sgn'_t = `sr_`sgn'' / `sr_`sgn'_se'
                local sr_`sgn'_p = 2 * ttail(`saved_df_sr', abs(`sr_`sgn'_t'))
            }
        }

        // long-run multipliers by the delta method
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
            if `sr_pos_se' < . {
                di as txt "  " _col(5) "Short-Run (+)" _col(18) as res %10.4f `sr_pos' _col(30) %10.4f `sr_pos_se' _col(42) %8.3f `sr_pos_t' _col(52) %8.4f `sr_pos_p' _c
                _wavenardl_stars `sr_pos_p'
            }
            else {
                di as res "  " _col(5) "Short-Run (+)" _col(18) %10.4f `sr_pos'
            }
            if `sr_neg_se' < . {
                di as txt "  " _col(5) "Short-Run (-)" _col(18) as res %10.4f `sr_neg' _col(30) %10.4f `sr_neg_se' _col(42) %8.3f `sr_neg_t' _col(52) %8.4f `sr_neg_p' _c
                _wavenardl_stars `sr_neg_p'
            }
            else {
                di as res "  " _col(5) "Short-Run (-)" _col(18) %10.4f `sr_neg'
            }
            di as txt "  " _col(5) "{hline 58}"
            di as txt "  " _col(5) "Long-Run  (+)" _col(18) %10.4f `lr_pos' _col(30) %10.4f `lr_pos_se' _col(42) %8.3f `lr_pos_t' _col(52) %8.4f `lr_pos_p' _c
            _wavenardl_stars `lr_pos_p'
            di as txt "  " _col(5) "Long-Run  (-)" _col(18) %10.4f `lr_neg' _col(30) %10.4f `lr_neg_se' _col(42) %8.3f `lr_neg_t' _col(52) %8.4f `lr_neg_p' _c
            _wavenardl_stars `lr_neg_p'
            di as txt "  {hline 68}"
            if `lr_neg' != 0 {
                local lr_ratio = abs(`lr_pos' / `lr_neg')
                di as txt "  " _col(5) "LR Asymmetry |LR(+)/LR(-)|" _col(38) "= " as res %6.3f `lr_ratio'
            }

            local lr_pos_`cname' = `lr_pos'
            local lr_neg_`cname' = `lr_neg'
            local lr_pos_se_`cname' = `lr_pos_se'
            local lr_neg_se_`cname' = `lr_neg_se'
            local sr_pos_`cname' = `sr_pos'
            local sr_neg_`cname' = `sr_neg'
        }
        else {
            di as err "  Warning: could not compute long-run multipliers for `cname'"
        }

        // restore the full-model estimates
        qui regress D.`depvar' `best_formula'
    }

    if `nctrl' > 0 {
        local ctrl_i = 0
        foreach cvar of local controls {
            local ctrl_i = `ctrl_i' + 1
            local this_r = `best_r_`ctrl_i''
            local saved_df_r_sr = e(df_r)

            local sr_ctrl = 0
            local sr_ctrl_se = .
            local sr_ctrl_t = .
            local sr_ctrl_p = .
            if `this_r' == 0 {
                capture local sr_ctrl = _b[D.`cvar']
                if _rc == 0 {
                    local sr_ctrl_se = _se[D.`cvar']
                    local sr_ctrl_t = `sr_ctrl' / `sr_ctrl_se'
                    local sr_ctrl_p = 2 * ttail(`saved_df_r_sr', abs(`sr_ctrl_t'))
                }
            }
            else {
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

            local saved_df_r = e(df_r)
            capture qui nlcom (LR: -_b[L.`cvar'] / _b[`ecm_coef_name']), level(`level') post
            if _rc == 0 {
                tempname lrc_b lrc_V
                mat `lrc_b' = e(b)
                mat `lrc_V' = e(V)
                local lr_ctrl = `lrc_b'[1,1]
                local lr_ctrl_se = sqrt(`lrc_V'[1,1])
                local lr_ctrl_t = `lr_ctrl' / `lr_ctrl_se'
                local lr_ctrl_p = 2 * ttail(`saved_df_r', abs(`lr_ctrl_t'))

                di as txt ""
                di as txt "  Variable: `cvar' (non-decomposed)"
                di as txt "  {hline 68}"
                di as txt "  " _col(5) "Component" _col(20) "Estimate" _col(32) "Std.Err." _col(44) "t-stat" _col(54) "p-value"
                di as txt "  {hline 68}"
                if `sr_ctrl_se' < . {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl' _col(30) %10.4f `sr_ctrl_se' _col(42) %8.3f `sr_ctrl_t' _col(52) %8.4f `sr_ctrl_p' _c
                    _wavenardl_stars `sr_ctrl_p'
                }
                else {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl'
                }
                di as txt "  " _col(5) "{hline 58}"
                di as txt "  " _col(5) "Long-Run" _col(18) %10.4f `lr_ctrl' _col(30) %10.4f `lr_ctrl_se' _col(42) %8.3f `lr_ctrl_t' _col(52) %8.4f `lr_ctrl_p' _c
                _wavenardl_stars `lr_ctrl_p'
                di as txt "  {hline 68}"
            }
            qui regress D.`depvar' `best_formula'
        }
    }

    di as txt ""
    di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
    di as txt "{hline 70}"

    // =========================================================================
    // 8. TABLE 5: WALD TESTS FOR ASYMMETRY
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    di as res "  Table 5: Wald Tests for Asymmetry"
    di as txt "{hline 70}"

    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local this_q = `best_q_`dec_i''
        di as txt ""
        di as txt "  Variable: `cname'"
        di as txt "  {hline 60}"

        // short-run additive symmetry: sum of D.pos coefs = sum of D.neg coefs
        local expr_pos "D.`cname'_pos"
        local expr_neg "D.`cname'_neg"
        forvalues j = 1/`this_q' {
            local expr_pos "`expr_pos' + L`j'.D.`cname'_pos"
            local expr_neg "`expr_neg' + L`j'.D.`cname'_neg"
        }
        capture qui test (`expr_pos' = `expr_neg')
        if _rc == 0 {
            local wald_sr_f = r(F)
            local wald_sr_p = r(p)
            di as txt "  Short-run asymmetry (sum): F = " %8.4f `wald_sr_f' "  p-value = " %6.4f `wald_sr_p' _c
            _wavenardl_stars `wald_sr_p'
        }
        else {
            di as txt "  Short-run asymmetry: not estimable"
            local wald_sr_f = .
            local wald_sr_p = .
        }
        local wald_sr_`cname' = `wald_sr_f'
        local wald_sr_p_`cname' = `wald_sr_p'

        // long-run symmetry: -theta+/rho = -theta-/rho
        capture qui testnl _b[L.`cname'_pos]/_b[`ecm_coef_name'] = _b[L.`cname'_neg]/_b[`ecm_coef_name']
        if _rc == 0 {
            local wald_lr_chi2 = r(chi2)
            local wald_lr_p = r(p)
            di as txt "  Long-run asymmetry:  Chi2 = " %8.4f `wald_lr_chi2' "  p-value = " %6.4f `wald_lr_p' _c
            _wavenardl_stars `wald_lr_p'
        }
        else {
            di as txt "  Long-run asymmetry:  not estimable"
            local wald_lr_chi2 = .
            local wald_lr_p = .
        }
        local wald_lr_`cname' = `wald_lr_chi2'
        local wald_lr_p_`cname' = `wald_lr_p'
        di as txt "  {hline 60}"
    }
    di as txt "{hline 70}"

    // =========================================================================
    // 9. TABLE 6: PSS BOUNDS COINTEGRATION TEST
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    di as res "  Table 6: PSS Bounds Cointegration Test (W-NARDL)"
    di as txt "{hline 70}"

    local levels_test "`ecm_coef_name'"
    foreach cname of local dec_names {
        local levels_test "`levels_test' L.`cname'_pos L.`cname'_neg"
    }
    foreach cvar of local controls {
        local levels_test "`levels_test' L.`cvar'"
    }

    capture qui test `levels_test'
    local Fov = r(F)
    local Fov_p = r(p)

    local t_dep = _b[`ecm_coef_name'] / _se[`ecm_coef_name']
    local t_dep_p = 2 * ttail(e(df_r), abs(`t_dep'))

    local indep_levels_test ""
    foreach cname of local dec_names {
        local indep_levels_test "`indep_levels_test' L.`cname'_pos L.`cname'_neg"
    }
    foreach cvar of local controls {
        local indep_levels_test "`indep_levels_test' L.`cvar'"
    }
    capture qui test `indep_levels_test'
    local Find = r(F)
    local Find_p = r(p)

    local n_lr_vars = 2 * `ndec' + `nctrl'

    di as txt ""
    di as txt "  H0: no long-run level relationship (rho = theta+ = theta- = 0)"
    di as txt ""
    di as txt "  {hline 60}"
    di as txt "  " _col(5) "Test" _col(28) "Statistic" _col(42) "p-value (F/t dist)"
    di as txt "  {hline 60}"
    di as txt "  " _col(5) "F_overall (F_PSS)" _col(26) %10.4f `Fov' _col(44) %8.4f `Fov_p'
    di as txt "  " _col(5) "t_dependent (t_BDM)" _col(26) %10.4f `t_dep' _col(44) %8.4f `t_dep_p'
    di as txt "  " _col(5) "F_independent" _col(26) %10.4f `Find' _col(44) %8.4f `Find_p'
    di as txt "  {hline 60}"
    di as txt ""
    di as txt "  Asymptotic critical value bounds, PSS (2001), case " ///
        as res cond(`case'==5, "V", "III") as txt ", k = " as res "`n_lr_vars'"
    di as txt ""
    di as txt "  {hline 62}"
    di as txt "  " _col(5) "Signif." _col(16) "I(0) Bound" _col(30) "I(1) Bound" _col(45) "Decision"
    di as txt "  {hline 62}"
    _wavenardl_pss_cv `case' `n_lr_vars' `Fov'
    local pss_dec5 "`r(decision5)'"
    di as txt "  {hline 62}"
    di as txt ""
    di as txt "  Decision at 5%: " as res "`pss_dec5'"
    di as txt "{hline 70}"

    // =========================================================================
    // 10. DIAGNOSTICS
    // =========================================================================
    if "`nodiag'" == "" {
        qui regress D.`depvar' `best_formula'
        di as txt ""
        di as txt "{hline 70}"
        di as res "  Table 7: Diagnostic Tests (W-NARDL residuals)"
        di as txt "{hline 70}"
        _wavenardl_diag `resid' `nobs_used' `nparams' "`nograph'"
    }

    // =========================================================================
    // 11. DYNAMIC MULTIPLIERS
    // =========================================================================
    if "`nodynmult'" == "" {
        qui regress D.`depvar' `best_formula'
        local max_q = 0
        forvalues di = 1/`ndec' {
            if `best_q_`di'' > `max_q' local max_q = `best_q_`di''
        }
        local max_r = 0
        if `nctrl' > 0 {
            forvalues ci = 1/`nctrl' {
                if `best_r_`ci'' > `max_r' local max_r = `best_r_`ci''
            }
        }
        _wavenardl_dynmult, depvar(`depvar') decnames(`dec_names') ///
            ecmcoef(`ecm_coef_name') p(`best_p') q(`max_q') ///
            horizon(`horizon') `nograph' ///
            `= cond(`nctrl' > 0, "controls(`controls') r(`max_r')", "")'
    }

    // =========================================================================
    // 12. COMPARISON: W-NARDL vs NARDL ON THE RAW SERIES
    // =========================================================================
    if "`nocompare'" == "" {
        di as txt ""
        di as txt "  Estimating the benchmark NARDL on the raw series..."

        // swap the raw values back into the model variables
        local dncount2 = 0
        foreach v of local dnvars {
            local dncount2 = `dncount2' + 1
            qui replace `v' = __wnr_`dncount2'
        }

        qui _wavenardl_engine, depvar(`depvar') decompose(`decompose') ///
            controls(`controls') maxlag(`maxlag') ic(`ic') `trendopt'

        local best_p_o = r(best_p)
        local lag_vec_o ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local lag_vec_o "`lag_vec_o', `r(best_q_`dec_i')'"
        }
        if `nctrl' > 0 {
            forvalues i = 1/`nctrl' {
                local lag_vec_o "`lag_vec_o', `r(best_r_`i')'"
            }
        }
        local aic_o = r(aic)
        local bic_o = r(bic)
        local ll_o  = r(ll)
        local r2_o  = r(r2)
        local r2a_o = r(r2_a)
        local dw_o  = r(dw)
        local N_o   = r(N)

        capture qui test `levels_test'
        local Fov_o = r(F)

        di as txt ""
        di as txt "{hline 74}"
        di as res "  Table 8: W-NARDL vs Standard NARDL Comparison"
        di as txt "{hline 74}"
        di as txt _col(3) "Metric" _col(28) "NARDL (raw)" _col(44) "W-NARDL" _col(60) "Better"
        di as txt "{hline 74}"

        local better = cond(`r2_w' > `r2_o', "W-NARDL", "NARDL")
        di as txt _col(3) "R-squared" _col(26) as res %12.4f `r2_o' _col(42) %12.4f `r2_w' _col(60) "`better'"
        local better = cond(`r2a_w' > `r2a_o', "W-NARDL", "NARDL")
        di as txt _col(3) "Adjusted R-squared" _col(26) as res %12.4f `r2a_o' _col(42) %12.4f `r2a_w' _col(60) "`better'"
        local better = cond(`aic_w' < `aic_o', "W-NARDL", "NARDL")
        di as txt _col(3) "AIC" _col(26) as res %12.4f `aic_o' _col(42) %12.4f `aic_w' _col(60) "`better'"
        local better = cond(`bic_w' < `bic_o', "W-NARDL", "NARDL")
        di as txt _col(3) "BIC" _col(26) as res %12.4f `bic_o' _col(42) %12.4f `bic_w' _col(60) "`better'"
        local better = cond(`ll_w' > `ll_o', "W-NARDL", "NARDL")
        di as txt _col(3) "Log-likelihood" _col(26) as res %12.4f `ll_o' _col(42) %12.4f `ll_w' _col(60) "`better'"
        di as txt _col(3) "Durbin-Watson" _col(26) as res %12.4f `dw_o' _col(42) %12.4f `dw_w'
        di as txt _col(3) "F_PSS (bounds)" _col(26) as res %12.4f `Fov_o' _col(42) %12.4f `Fov'
        di as txt _col(3) "Selected lags" _col(28) as res "(`best_p_o'`lag_vec_o')" _col(44) "(`best_p'`lag_vec')"
        di as txt "{hline 74}"

        if `bic_w' < `bic_o' {
            di as res "  Wavelet denoising improves the model fit (lower BIC),"
            di as res "  consistent with Jammazi, Lahiani & Nguyen (2015)."
        }
        else {
            di as res "  The raw-series NARDL attains a lower BIC; wavelet denoising"
            di as res "  may not be necessary for these variables."
        }
        di as txt "{hline 74}"

        // swap the denoised values back and refit the W-NARDL model
        local dncount2 = 0
        foreach v of local dnvars {
            local dncount2 = `dncount2' + 1
            qui replace `v' = __wnd_`dncount2'
        }
        // recompute the partial sums on the denoised series
        qui _wavenardl_engine, depvar(`depvar') decompose(`decompose') ///
            controls(`controls') maxlag(`maxlag') ic(`ic') `trendopt' ///
            fixformula(`best_formula') fixp(`best_p')
    }

    // =========================================================================
    // 13. SAVE DENOISED SERIES IF REQUESTED
    // =========================================================================
    if "`generate'" != "" & `ndn' > 0 {
        tempfile dnfile
        local dncount2 = 0
        local keepdn ""
        foreach v of local dnvars {
            local dncount2 = `dncount2' + 1
            qui gen double `generate'_`v' = __wnd_`dncount2'
            local keepdn "`keepdn' `generate'_`v'"
        }
        qui keep `timevar' `keepdn'
        qui save `dnfile'
        restore
        qui merge 1:1 `timevar' using `dnfile', nogenerate
        di as txt ""
        di as txt "  Denoised series saved:" as res "`keepdn'"
        local restored = 1
    }
    else {
        local restored = 0
    }

    // =========================================================================
    // 14. STORE e() RESULTS
    // =========================================================================
    tempname b_post V_post
    mat `b_post' = e(b)
    mat `V_post' = e(V)
    local df_r_post = e(df_r)
    local rmse_post = e(rmse)

    if `restored' == 0 restore

    ereturn post `b_post' `V_post', obs(`nobs_used') depname(D.`depvar')

    ereturn scalar N        = `nobs_used'
    ereturn scalar df_r     = `df_r_post'
    ereturn scalar best_p   = `best_p'
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        ereturn scalar best_q_`cname' = `best_q_`dec_i''
    }
    ereturn scalar aic      = `aic_w'
    ereturn scalar bic      = `bic_w'
    ereturn scalar ll       = `ll_w'
    ereturn scalar r2       = `r2_w'
    ereturn scalar r2_a     = `r2a_w'
    ereturn scalar dw       = `dw_w'
    ereturn scalar F_pss    = `Fov'
    ereturn scalar t_bdm    = `t_dep'
    ereturn scalar F_indep  = `Find'
    ereturn scalar k_lr     = `n_lr_vars'
    ereturn scalar rmse     = `rmse_post'

    // wavelet parameters per denoised variable
    local dncount2 = 0
    foreach v of local dnvars {
        local dncount2 = `dncount2' + 1
        ereturn scalar J_`v'      = `Jl_`dncount2''
        ereturn scalar sigma_`v'  = `sig_`dncount2''
        ereturn scalar lambda_`v' = `lam_`dncount2''
    }

    foreach cname of local dec_names {
        capture ereturn scalar lr_pos_`cname' = `lr_pos_`cname''
        capture ereturn scalar lr_neg_`cname' = `lr_neg_`cname''
        capture ereturn scalar sr_pos_`cname' = `sr_pos_`cname''
        capture ereturn scalar sr_neg_`cname' = `sr_neg_`cname''
        capture ereturn scalar wald_sr_`cname'   = `wald_sr_`cname''
        capture ereturn scalar wald_sr_p_`cname' = `wald_sr_p_`cname''
        capture ereturn scalar wald_lr_`cname'   = `wald_lr_`cname''
        capture ereturn scalar wald_lr_p_`cname' = `wald_lr_p_`cname''
    }

    if "`nocompare'" == "" {
        ereturn scalar aic_raw  = `aic_o'
        ereturn scalar bic_raw  = `bic_o'
        ereturn scalar ll_raw   = `ll_o'
        ereturn scalar r2_raw   = `r2_o'
        ereturn scalar r2_a_raw = `r2a_o'
        ereturn scalar dw_raw   = `dw_o'
        ereturn scalar F_pss_raw = `Fov_o'
    }

    ereturn local cmd        "wavenardl"
    ereturn local cmdline    "wavenardl `0'"
    ereturn local depvar     "`depvar'"
    ereturn local decompose  "`decompose'"
    ereturn local controls   "`controls'"
    ereturn local dec_names  "`dec_names'"
    ereturn local ic         "`ic'"
    ereturn local threshold  "`threshold'"
    ereturn local denoise    "`denoise'"
    ereturn local case       "`case'"
    ereturn local wavelet    "haar-a-trous"

    // =========================================================================
    // 15. REFERENCES
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    di as res "  References"
    di as txt "{hline 70}"
    di as txt "  Jammazi, Lahiani & Nguyen (2015). A wavelet-based nonlinear ARDL"
    di as txt "    model for assessing the exchange rate pass-through to crude oil"
    di as txt "    prices. J. Int. Fin. Markets, Inst. & Money, 34, 173-187."
    di as txt "  Shin, Yu & Greenwood-Nimmo (2014). Modelling asymmetric cointegration"
    di as txt "    and dynamic multipliers in a nonlinear ARDL framework."
    di as txt "  Pesaran, Shin & Smith (2001). Bounds testing approaches to the"
    di as txt "    analysis of level relationships. J. Applied Econometrics 16, 289-326."
    di as txt "  Murtagh, Starck & Renaud (2004). On neuro-wavelet modeling."
    di as txt "    Decision Support Systems, 37, 475-484."
    di as txt "  Donoho (1995). De-noising by soft-thresholding. IEEE Trans."
    di as txt "    Information Theory, 41, 613-627."
    di as txt "{hline 70}"
    di as res "  Estimation complete. Results stored in e()."
    di as txt "  Type {cmd:ereturn list} to view stored results."
    di as txt "{hline 70}"

end


// =============================================================================
// ENGINE: partial-sum decomposition + lag grid search + best-model estimation
// Leaves the best regression active in e(); returns fit statistics in r().
// With fixformula()/fixp(): only rebuilds the partial sums and refits.
// =============================================================================
capture program drop _wavenardl_engine
program define _wavenardl_engine, rclass
    version 17
    syntax, depvar(string) decompose(string) maxlag(integer) ic(string) ///
        [controls(string) trendvar(string) fixformula(string) fixp(integer 1)]

    local ndec  : word count `decompose'
    local nctrl : word count `controls'

    // ---- partial-sum decomposition ----
    local dec_names ""
    foreach xvar of local decompose {
        local cname = subinstr("`xvar'", ".", "_", .)

        capture drop `cname'_pos
        capture drop `cname'_neg

        tempvar dx
        qui gen double `dx' = D.`xvar'

        qui gen double `cname'_pos = 0
        qui replace `cname'_pos = max(`dx', 0) if `dx' != .
        qui replace `cname'_pos = sum(`cname'_pos)

        qui gen double `cname'_neg = 0
        qui replace `cname'_neg = min(`dx', 0) if `dx' != .
        qui replace `cname'_neg = sum(`cname'_neg)

        local dec_names "`dec_names' `cname'"
    }
    return local dec_names "`dec_names'"

    // ---- fixed-formula refit (used after the comparison pass) ----
    if "`fixformula'" != "" {
        qui regress D.`depvar' `fixformula'
        return local formula "`fixformula'"
        return scalar best_p = `fixp'
        exit
    }

    // ---- grid search ----
    tempname best_ic_val
    scalar `best_ic_val' = .
    local best_p = 1
    local best_formula ""
    local total_models = 0

    forvalues i = 1/`ndec' {
        local best_q_`i' = 0
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local best_r_`i' = 0
        }
    }

    forvalues p = 1/`maxlag' {

        local n_indep = `ndec' + `nctrl'
        local n_combos = 1
        forvalues vi = 1/`n_indep' {
            local n_combos = `n_combos' * (`maxlag' + 1)
        }

        local combo_max = `n_combos' - 1
        forvalues combo = 0/`combo_max' {

            local total_models = `total_models' + 1

            // decode combo index into variable-specific lags
            local remainder = `combo'
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

            // build the regressor list
            local regvars ""
            forvalues j = 1/`p' {
                local regvars "`regvars' L`j'.D.`depvar'"
            }
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
            // lagged levels (ECM terms)
            local regvars "`regvars' L.`depvar'"
            foreach cname of local dec_names {
                local regvars "`regvars' L.`cname'_pos L.`cname'_neg"
            }
            foreach cvar of local controls {
                local regvars "`regvars' L.`cvar'"
            }
            // trend
            if "`trendvar'" != "" {
                local regvars "`regvars' `trendvar'"
            }

            capture qui regress D.`depvar' `regvars'
            if _rc != 0 continue
            if e(N) < e(df_m) + 10 continue

            local this_n = e(N)
            local this_k = e(df_m) + 1
            local this_ssr = e(rss)

            if "`ic'" == "aic" {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + 2 * `this_k'
            }
            else {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + `this_k' * ln(`this_n')
            }

            if `this_ic' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                scalar `best_ic_val' = `this_ic'
                local best_p = `p'
                local best_formula "`regvars'"
                forvalues di = 1/`ndec' {
                    local best_q_`di' = `cur_q_`di''
                }
                if `nctrl' > 0 {
                    forvalues ci = 1/`nctrl' {
                        local best_r_`ci' = `cur_r_`ci''
                    }
                }
            }
        }
    }

    if "`best_formula'" == "" {
        di as err "no NARDL specification could be estimated; check your data"
        exit 2000
    }

    // ---- final estimation ----
    qui regress D.`depvar' `best_formula'

    local nobs_used = e(N)
    local nparams = e(df_m) + 1
    local ssr = e(rss)
    local aic_val = `nobs_used' * ln(`ssr'/`nobs_used') + 2 * `nparams'
    local bic_val = `nobs_used' * ln(`ssr'/`nobs_used') + `nparams' * ln(`nobs_used')

    return scalar best_p = `best_p'
    forvalues di = 1/`ndec' {
        return scalar best_q_`di' = `best_q_`di''
    }
    if `nctrl' > 0 {
        forvalues ci = 1/`nctrl' {
            return scalar best_r_`ci' = `best_r_`ci''
        }
    }
    return local formula "`best_formula'"
    return scalar models = `total_models'
    return scalar icval = scalar(`best_ic_val')
    return scalar aic  = `aic_val'
    return scalar bic  = `bic_val'
    return scalar ll   = e(ll)
    return scalar r2   = e(r2)
    return scalar r2_a = e(r2_a)
    return scalar N    = `nobs_used'
    return scalar k    = `nparams'

    // Durbin-Watson computed directly from the residuals (estat dwatson
    // is not available for every tsset configuration)
    tempvar _eres _eu2 _ed2
    qui predict double `_eres', residuals
    qui gen double `_eu2' = `_eres'^2 if e(sample)
    qui gen double `_ed2' = (`_eres' - L.`_eres')^2 if e(sample) & !missing(L.`_eres')
    qui sum `_eu2'
    local _ssq = r(sum)
    qui sum `_ed2'
    local _sdq = r(sum)
    if `_ssq' > 0 {
        return scalar dw = `_sdq' / `_ssq'
    }
    else {
        return scalar dw = .
    }

    // the best regression stays active in e()
end


// =============================================================================
// HELPER: PSS (2001) asymptotic critical value bounds, cases III and V
// Displays one row per significance level and returns the 5% decision.
// =============================================================================
capture program drop _wavenardl_pss_cv
program define _wavenardl_pss_cv, rclass
    version 17
    args case k Fstat

    if `k' > 10 local k = 10
    if `k' < 1  local k = 1

    // Case III: unrestricted intercept, no trend  (PSS 2001, Table CI(iii))
    // rows: k = 1..10 ; columns: 10%L 10%U 5%L 5%U 2.5%L 2.5%U 1%L 1%U
    tempname cv3 cv5
    mat `cv3' = ( ///
        4.04, 4.78, 4.94, 5.73, 5.77, 6.68, 6.84, 7.84 \ ///
        3.17, 4.14, 3.79, 4.85, 4.41, 5.52, 5.15, 6.36 \ ///
        2.72, 3.77, 3.23, 4.35, 3.69, 4.89, 4.29, 5.61 \ ///
        2.45, 3.52, 2.86, 4.01, 3.25, 4.49, 3.74, 5.06 \ ///
        2.26, 3.35, 2.62, 3.79, 2.96, 4.18, 3.41, 4.68 \ ///
        2.12, 3.23, 2.45, 3.61, 2.75, 3.99, 3.15, 4.43 \ ///
        2.03, 3.13, 2.32, 3.50, 2.60, 3.84, 2.96, 4.26 \ ///
        1.95, 3.06, 2.22, 3.39, 2.48, 3.70, 2.79, 4.10 \ ///
        1.88, 2.99, 2.14, 3.30, 2.37, 3.60, 2.65, 3.97 \ ///
        1.83, 2.94, 2.06, 3.24, 2.28, 3.50, 2.54, 3.86 )

    // Case V: unrestricted intercept, unrestricted trend  (Table CI(v))
    mat `cv5' = ( ///
        5.59, 6.26, 6.56, 7.30, 7.46, 8.27, 8.74, 9.63 \ ///
        4.19, 5.06, 4.87, 5.85, 5.49, 6.59, 6.34, 7.52 \ ///
        3.47, 4.45, 4.01, 5.07, 4.52, 5.62, 5.17, 6.36 \ ///
        3.03, 4.06, 3.47, 4.57, 3.89, 5.07, 4.40, 5.72 \ ///
        2.75, 3.79, 3.12, 4.25, 3.47, 4.67, 3.93, 5.23 \ ///
        2.53, 3.59, 2.87, 4.00, 3.19, 4.38, 3.60, 4.90 \ ///
        2.38, 3.45, 2.69, 3.83, 2.98, 4.16, 3.34, 4.63 \ ///
        2.26, 3.34, 2.55, 3.68, 2.82, 4.02, 3.15, 4.43 \ ///
        2.16, 3.24, 2.43, 3.56, 2.67, 3.87, 2.97, 4.24 \ ///
        2.07, 3.16, 2.33, 3.46, 2.56, 3.76, 2.84, 4.10 )

    tempname cvm
    if `case' == 5 {
        mat `cvm' = `cv5'
    }
    else {
        mat `cvm' = `cv3'
    }

    local siglist "10% 5% 2.5% 1%"
    local decision5 ""
    forvalues s = 1/4 {
        local sig : word `s' of `siglist'
        local lb = `cvm'[`k', 2*`s' - 1]
        local ub = `cvm'[`k', 2*`s']

        if `Fstat' > `ub' {
            local dec "Cointegration"
        }
        else if `Fstat' >= `lb' {
            local dec "Inconclusive"
        }
        else {
            local dec "No cointegration"
        }
        di as txt "  " _col(5) "`sig'" _col(14) as res %10.2f `lb' _col(28) %10.2f `ub' _col(45) "`dec'"

        if `s' == 2 {
            local decision5 "`dec'"
        }
    }
    return local decision5 "`decision5'"
end


// =============================================================================
// Mata: Haar "a trous" wavelet denoising (Jammazi et al. 2015 procedure)
//   s_{j+1}(t) = 0.5 * (s_j(t - 2^j) + s_j(t))
//   d_{j+1}(t) = s_j(t) - s_{j+1}(t)
//   threshold the d_j with lambda = sigma * sqrt(2 ln N), sigma = MAD(d_1)/0.6745
//   reconstruct: x_dn = s_J + sum_j d_j(thresholded)
// =============================================================================
capture mata mata drop _wnardl_htw()
capture mata mata drop _wnardl_med()

mata:

real scalar _wnardl_med(real colvector v)
{
    real colvector a
    real scalar n2, m

    a = sort(v, 1)
    n2 = rows(a)
    m = a[floor((n2 + 1) / 2)]
    if (mod(n2, 2) == 0) m = 0.5 * (a[n2/2] + a[n2/2 + 1])
    return(m)
}

void _wnardl_htw(string scalar invar, string scalar outvar,
                 string scalar tousevar, real scalar Jin, real scalar soft)
{
    real colvector x, sp, sc, dj, thr, dsum
    real matrix D
    real scalar n, Jlev, Jmax, jj, t, tshift, shift, sigma, lambda, medd

    x = st_data(., invar, tousevar)
    n = rows(x)
    if (n < 8) {
        errprintf("wavenardl: too few observations for wavelet denoising\n")
        exit(2001)
    }

    Jmax = floor(ln(n) / ln(2))
    Jlev = Jin
    if (Jlev <= 0) Jlev = Jmax
    if (Jlev > Jmax) Jlev = Jmax

    // decomposition
    D = J(n, Jlev, 0)
    sp = x
    shift = 1
    for (jj = 1; jj <= Jlev; jj++) {
        sc = J(n, 1, 0)
        for (t = 1; t <= n; t++) {
            tshift = t - shift
            if (tshift < 1) tshift = 1
            sc[t] = 0.5 * (sp[tshift] + sp[t])
        }
        D[., jj] = sp - sc
        sp = sc
        shift = shift * 2
    }

    // noise scale from the level-1 details (MAD estimator)
    dj = D[., 1]
    medd = _wnardl_med(dj)
    sigma = _wnardl_med(abs(dj :- medd)) / 0.6745
    lambda = sigma * sqrt(2 * ln(n))

    // threshold every detail level and reconstruct
    dsum = J(n, 1, 0)
    for (jj = 1; jj <= Jlev; jj++) {
        dj = D[., jj]
        thr = dj :* (abs(dj) :>= lambda)
        if (soft == 1) thr = sign(dj) :* rowmax((abs(dj) :- lambda, J(n, 1, 0)))
        dsum = dsum + thr
    }
    x = sp + dsum

    st_store(., outvar, tousevar, x)
    st_numscalar("__wn_sigma", sigma)
    st_numscalar("__wn_lambda", lambda)
    st_numscalar("__wn_J", Jlev)
}

end
