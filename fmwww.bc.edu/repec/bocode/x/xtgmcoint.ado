*! xtgmcoint v1.0 - Group-Mean Panel Cointegration FMOLS and DOLS Estimators (Pedroni 2000, 2001)
*!
*! Single-file Stata package providing two estimators:
*!   - method(dols)  : Group-Mean Panel Dynamic OLS (Pedroni 2001)
*!                     Replicates RATS @paneldols (paneldols.src, SSC: RTS00150)
*!   - method(fmols) : Group-Mean Panel Fully Modified OLS (Pedroni 2000)
*!                     Replicates RATS @panelfm (panelfm.src, SSC: RTS00151)
*!
*! Verified to match Pedroni's original RATS routines to 4 decimal places
*! across multiple specifications: univariate, multivariate, balanced,
*! unbalanced, with/without time dummies, with/without trend, all averaging
*! methods (simple, sqrt, precision).
*!
*! Usage:
*!   xtgmcoint depvar indepvars [if] [in] , method(dols|fmols) [options]
*!
*! See: help xtgmcoint
*!
*! Author: H. Ozan Eruygur (Eruygur Akademi ve Danismanlik, Ankara)
*! License: GPL-3

program define xtgmcoint, eclass
    version 15.0
    syntax anything [if] [in] , METHOD(string) [ * ]

    local method = lower("`method'")
    if !inlist("`method'", "dols", "fmols") {
        di as err "method() must be dols or fmols."
        exit 198
    }

    if "`method'" == "dols" {
        _xtgmcoint_dols `anything' `if' `in', `options'
    }
    else {
        _xtgmcoint_fmols `anything' `if' `in', `options'
    }

    ereturn local cmd "xtgmcoint"
    ereturn local method "`method'"
end


* ==================================================================
* DOLS estimator (Pedroni 2001)
* ==================================================================

program define _xtgmcoint_dols, eclass
    version 15.0
    syntax anything [if] [in] , ///
        [ ID(varname) TIME(varname) ///
          DLAGS(integer 2) LAGS(integer -1) ///
          TDUM TREND PEDroni2001 ///
          B(numlist) AVERAGE(string) FULL TTest ///
          RESid(name) FIT(name) ]

    * ---- Deterministic: constant (default) or constant + trend (if `trend' option)
    if "`trend'" != "" local det "trend"
    else               local det "constant"

    * ---- Panel vars
    if "`id'" == "" | "`time'" == "" {
        qui xtset
        if "`id'"   == "" local id   "`r(panelvar)'"
        if "`time'" == "" local time "`r(timevar)'"
    }
    if "`id'" == "" | "`time'" == "" {
        di as err "id() and time() or xtset required."
        exit 198
    }
    sort `id' `time'
    qui xtset `id' `time'

    * ---- Averaging
    if "`average'" == "" local average "simple"
    local average = lower("`average'")
    if !inlist("`average'","simple","sqrt","precision") {
        di as err "average() must be simple, sqrt, or precision."
        exit 198
    }

    * ---- Parse varlist
    tokenize `anything'
    local depvar "`1'"
    macro shift
    local xvars "`*'"
    local K_x : word count `xvars'

    * Parse b() option as a numlist (one null per RHS or single value applied to all)
    if "`b'" == "" {
        local b_vec ""
        forvalues k = 1/`K_x' {
            local b_vec "`b_vec' 0"
        }
    }
    else {
        local b_n : word count `b'
        if `b_n' == 1 {
            local b_vec ""
            forvalues k = 1/`K_x' {
                local b_vec "`b_vec' `b'"
            }
        }
        else if `b_n' == `K_x' {
            local b_vec "`b'"
        }
        else {
            di as err "b() must be either a single value or `K_x' values (one per RHS)."
            exit 198
        }
    }
    local b_vec = trim("`b_vec'")
    * Scalar `b' = first element (for single-coef display contexts)
    local b : word 1 of `b_vec'

    marksample touse
    markout `touse' `depvar' `xvars'

    * =================================================================
    * STEP 1: Optional time-demeaning (tdum option)
    *   paneldols.src logic: if tdum, subtract common time means
    *   else: use raw data (unit constant absorbs individual means)
    * =================================================================
    local do_tdemean = 0
    if "`tdum'" != "" local do_tdemean = 1

    if `do_tdemean' {
        * Time-demean: subtract common time means (paneldols.src tdum=1 branch)
        tempvar y_reg
        qui bysort `time': egen double _tmean_y = mean(`depvar') if `touse'
        qui gen double `y_reg' = `depvar' - _tmean_y if `touse'
        qui drop _tmean_y

        local x_reg ""
        foreach xv of local xvars {
            tempvar xtd
            qui bysort `time': egen double _tmean_x = mean(`xv') if `touse'
            qui gen double `xtd' = `xv' - _tmean_x if `touse'
            qui drop _tmean_x
            local x_reg "`x_reg' `xtd'"
        }
    }
    else {
        * Default: raw data (unit constant absorbs individual means via regression)
        local y_reg "`depvar'"
        local x_reg "`xvars'"
    }

    sort `id' `time'
    qui xtset `id' `time'

    * =================================================================
    * STEP 2: First-differences of x + symmetric leads/lags
    *   Follows Neal's xtpedroni sequence (lines 63-85):
    *     1. gen D.x (no 'if' restriction - use full dataset)
    *     2. unit-demean: D.x - bysort id: mean(D.x)
    *     3. leads/lags applied as TS operators in regression call
    * =================================================================
    local dx_tvs  ""
    local dx_lbls ""
    local xi = 0
    foreach xv of local xvars {
        local ++xi
        * Base for D. operator: if time-demeaned, use x_reg; else raw xv
        if `do_tdemean' {
            local base_x : word `xi' of `x_reg'
        }
        else {
            local base_x "`xv'"
        }
        * Generate Dx (Neal: no 'if') and unit-demean
        tempvar _Dx _Dxd
        qui gen double `_Dx' = D.`base_x'
        qui bysort `id': egen double _umean_dx = mean(`_Dx')
        qui gen double `_Dxd' = `_Dx' - _umean_dx
        qui drop _umean_dx `_Dx'
        * Lags (oldest first) - applied as TS operators (no if)
        forvalues l = `dlags'(-1)1 {
            tempvar _DL
            qui gen double `_DL' = L`l'.`_Dxd'
            local dx_tvs  "`dx_tvs' `_DL'"
            local dx_lbls "`dx_lbls' L`l'D.`xv'"
        }
        * Current
        local dx_tvs  "`dx_tvs' `_Dxd'"
        local dx_lbls "`dx_lbls' D.`xv'"
        * Leads
        forvalues l = 1/`dlags' {
            tempvar _DF
            qui gen double `_DF' = F`l'.`_Dxd'
            local dx_tvs  "`dx_tvs' `_DF'"
            local dx_lbls "`dx_lbls' F`l'D.`xv'"
        }
    }

    * =================================================================
    * Display header
    * =================================================================
    di _newline as text "xtgmcoint (method=dols): Group-Mean Panel DOLS (Pedroni 2001)"
    if `do_tdemean' {
        di as text "  Time dummies: ON (common time means subtracted)"
    }
    else {
        di as text "  Time dummies: OFF"
    }
    if "`det'" == "trend" {
        di as text "  Deterministic: constant + trend"
    }
    else {
        di as text "  Deterministic: constant"
    }
    di as text "  LHS : `depvar'"
    _xtgmcoint_wraplist "  LR  :" "`xvars'"
    _xtgmcoint_wraplist "  DOLS:" "`dx_lbls' (symmetric lags/leads = `dlags')"
    di as text "  Averaging: `average'"
    if "`pedroni2001'" != "" {
        di as text "  HAC denominator: T + 2*lags (pedroni2001 / Neal 2014 mode)"
    }
    di ""

    * =================================================================
    * STEP 3: Unit loop
    * =================================================================
    qui levelsof `id' if `touse', local(uid_list)
    local _id_str = 0
    cap confirm string variable `id'
    if _rc == 0 local _id_str = 1

    tempvar resid_tv
    qui gen double `resid_tv' = .

    local K_dx : word count `dx_tvs'
    local K_rhs = `K_x' + `K_dx'
    local minN = `K_rhs' + 2
    local K_det = cond("`trend'"!="", 2, 1)

    * Trend variable (if det=trend)
    local trend_var ""
    if "`trend'" != "" {
        tempvar _trend
        qui bysort `id' (`time'): gen double `_trend' = _n if `touse'
        local trend_var "`_trend'"
        local K_rhs = `K_rhs' + 1
        local minN = `minN' + 1
    }

    mata: _gd_beta = J(0, `K_x' + `K_det', .)
    mata: _gd_alpha = J(0, 1, .)
    mata: _gd_LRV  = asarray_create("string", 1)

    local nvalid = 0
    local ntotal = 0

    foreach uid of local uid_list {
        local ++ntotal
        if `_id_str' local _ucond `id' == "`uid'"
        else         local _ucond `id' == `uid'

        * Unit sample: truncate to rows where all RHS non-missing (unbalanced)
        tempvar _utouse _valid_row
        qui gen byte `_valid_row' = !missing(`y_reg')
        foreach xv of local x_reg {
            qui replace `_valid_row' = 0 if missing(`xv')
        }
        foreach dxv of local dx_tvs {
            qui replace `_valid_row' = 0 if missing(`dxv')
        }
        qui gen byte `_utouse' = `_ucond' & `touse' & `_valid_row'
        qui drop `_valid_row'
        qui count if `_utouse'
        local _T = r(N)
        if `_T' < `minN' {
            qui drop `_utouse'
            continue
        }

        * Unit DOLS regression
        cap qui regress `y_reg' `x_reg' `dx_tvs' `trend_var' if `_utouse'
        local _ols_ok = (_rc == 0)
        if `_ols_ok' {
            local _bad = 0
            foreach v of local x_reg {
                cap local _bv = _b[`v']
                if _rc | missing(`_bv') local _bad = 1
            }
            if `_bad' local _ols_ok = 0
        }
        if !`_ols_ok' {
            qui drop `_utouse'
            continue
        }

        * Extract beta_i (first K_x coefficients)
        tempname b_unit
        matrix `b_unit' = e(b)
        mata: _tmp_b = J(1, `K_x', .)
        forvalues k = 1/`K_x' {
            mata: _tmp_b[1, `k'] = st_matrix("`b_unit'")[1, `k']
        }

        * Residuals
        tempvar _ehat _esmp
        qui gen byte `_esmp' = e(sample)
        qui predict double `_ehat' if `_esmp', resid
        qui replace `resid_tv' = `_ehat' if `_ucond' & `_esmp' & `_ehat' < .

        qui count if `_esmp'
        local _Teff = r(N)

        * =========================================================
        * Newey-West long-run variance of DOLS residuals
        * Default (RATS @paneldols compatible): %nobs = e(N)
        * pedroni2001 option: Neal (2014) uses T + 2*lags
        *   This is a small-sample adjustment that yields slightly
        *   higher t-statistics. RATS code does not include it.
        * =========================================================
        if "`pedroni2001'" != "" {
            local _Tden = `_Teff' + 2 * `dlags'
        }
        else {
            local _Tden = `_Teff'
        }

        if `lags' < 0 {
            local _L = round(4 * (`_Tden'/100)^(2/9))
            if `_L' < 1 local _L = 1
        }
        else {
            local _L = `lags'
        }

        tempvar _uu
        qui gen double `_uu' = `_ehat' * `_ehat' if `_esmp'
        qui sum `_uu' if `_esmp', meanonly
        local _gam0 = r(sum) / `_Tden'
        local _lam = `_gam0'

        forvalues l = 1/`_L' {
            qui replace `_uu' = `_ehat' * L`l'.`_ehat' if `_esmp'
            qui sum `_uu' if `_esmp', meanonly
            local _gam_l = r(sum) / `_Tden'
            local _w = 2 * (1 - `l'/(`_L'+1))
            local _lam = `_lam' + `_w' * `_gam_l'
        }
        qui drop `_uu'

        * =========================================================
        * LRV_i = idlrvar * (X'X)^-1 [slope + det blocks combined]
        * paneldols.src (line 296):
        *    vdols = idlrvar * %xsubmat(%xx, 1, baseregs, 1, baseregs)
        *    baseregs = m + K_det
        * %xx in RATS after linreg = (X'X)^-1 (raw, not scaled by sigma^2).
        * In Stata: e(V) = sigma^2_OLS * (X'X)^-1
        * so: (X'X)^-1 = e(V) / e(rmse)^2.
        * RATS regressor order: x (slope), det (constant, trend) -- contiguous
        *   block 1..baseregs.
        * Stata regress order: x (slope), dx_tvs, [trend,] cons -- we extract
        *   slope rows/cols + det rows/cols and build K_eff x K_eff.
        * Also save full unit beta vector b_full = [slope ; det].
        * =========================================================
        tempname _V _invXX _LRV _bfull
        matrix `_V' = e(V)
        local _rmse = e(rmse)
        matrix `_invXX' = `_V' / (`_rmse' * `_rmse')

        local _K_eff = `K_x' + `K_det'
        local _K_dx : word count `dx_tvs'
        local _ncols = colsof(`_invXX')

        * Det column indices in e(V):
        local _det_cols ""
        if `K_det' > 0 {
            if "`trend'" != "" {
                local _det_cols "`= `_ncols' - 1' `_ncols'"
            }
            else {
                local _det_cols "`_ncols'"
            }
        }

        * Build LRV (K_eff x K_eff): slope-slope, slope-det, det-slope, det-det
        matrix `_LRV' = J(`_K_eff', `_K_eff', 0)
        forvalues _i = 1/`K_x' {
            forvalues _j = 1/`K_x' {
                matrix `_LRV'[`_i', `_j'] = `_lam' * `_invXX'[`_i', `_j']
            }
        }
        if `K_det' > 0 {
            local _di = `K_x'
            foreach _dc of local _det_cols {
                local ++_di
                forvalues _i = 1/`K_x' {
                    matrix `_LRV'[`_i', `_di'] = `_lam' * `_invXX'[`_i', `_dc']
                    matrix `_LRV'[`_di', `_i'] = `_lam' * `_invXX'[`_dc', `_i']
                }
                local _dj = `K_x'
                foreach _dc2 of local _det_cols {
                    local ++_dj
                    matrix `_LRV'[`_di', `_dj'] = `_lam' * `_invXX'[`_dc', `_dc2']
                }
            }
        }

        * Build bfull: slope coefs + det coefs (in same order as LRV)
        matrix `_bfull' = J(1, `_K_eff', 0)
        forvalues _i = 1/`K_x' {
            matrix `_bfull'[1, `_i'] = `b_unit'[1, `_i']
        }
        if `K_det' > 0 {
            local _bi = `K_x'
            foreach _dc of local _det_cols {
                local ++_bi
                matrix `_bfull'[1, `_bi'] = `b_unit'[1, `_dc']
            }
        }

        * Push to Mata
        mata: _gd_beta = _gd_beta \ st_matrix("`_bfull'")
        mata: asarray(_gd_LRV, strofreal(`nvalid'+1), st_matrix("`_LRV'"))
        * Append unit DOLS regression constant (last element of bfull)
        if "`det'" != "none" {
            local _ncols_b = colsof(`_bfull')
            local _alpha_i = `_bfull'[1, `_ncols_b']
            mata: _gd_alpha = _gd_alpha \ `_alpha_i'
        }
        else {
            mata: _gd_alpha = _gd_alpha \ 0
        }

        if "`full'" != "" {
            if `nvalid' == 0 {
                _xtgmcoint_helper_full_hdr "`ttest'" "DOLS"
            }
            local _b1 = _b[`: word 1 of `x_reg'']
            tempname _V_e
            matrix `_V_e' = e(V)
            local _rmse_u = e(rmse)
            local _xxinv11 = `_V_e'[1,1] / (`_rmse_u' * `_rmse_u')
            local _lrv11 = `_lam' * `_xxinv11'
            local _se1 = sqrt(`_lrv11')
            local _df_arg = cond("`ttest'" != "", "`=e(df_r)'", "")
            _xtgmcoint_helper_full_r "`uid'" `_b1' `_se1' `b' `_df_arg'
        }

        cap drop `_ehat' `_esmp' `_utouse'
        local ++nvalid
    }

    * =================================================================
    * No valid units
    * =================================================================
    if `nvalid' == 0 {
        _xtgmcoint_illposed_open "xtgmcoint (method=dols)"
        di as text "  Long-run regressors (x):                    `K_x'"
        di as text "  DOLS correction (D.x leads+lags):           `K_dx'"
        di as text "  Minimum obs per unit for identified OLS:    `minN'"
        _xtgmcoint_illposed_close
        cap mata: mata drop _gd_beta _gd_LRV _tmp_b
    * (_gd_alpha kept for residual calculation; dropped at end)
        exit 0
    }

    * =================================================================
    * STEP 4: Group-Mean averaging + Pedroni t-stat
    * =================================================================
    tempname LR_MEAN LR_SE LR_V T_STAT

    mata {
        N_units = rows(_gd_beta)
        K = cols(_gd_beta)                  // K_eff = K_x + K_det
        K_x_only = `K_x'
        b0_slope = strtoreal(tokens("`b_vec'"))  // 1 x K_x
        // Extend to K_eff: append zeros for det part
        b0 = b0_slope, J(1, K - K_x_only, 0)

        // ---------------------------------------------------------
        // t-statistic only for slope coefficients (RATS reports same)
        //   tdols_i[k] = (b_i[k] - b0[k]) / sqrt(LRV_i[k,k])
        //   t_panel[k] = (1/sqrt(N)) * sum_i tdols_i[k]
        // Pedroni only reports t for slope; det t-stats are not reported.
        // ---------------------------------------------------------
        t_sum_full = J(1, K, 0)
        for (i = 1; i <= N_units; i++) {
            LRV_i = asarray(_gd_LRV, strofreal(i))
            for (k = 1; k <= K; k++) {
                t_i_k = (_gd_beta[i, k] - b0[1, k]) / sqrt(LRV_i[k, k])
                t_sum_full[1, k] = t_sum_full[1, k] + t_i_k
            }
        }
        t_bar_full = t_sum_full / sqrt(N_units)

        // ---------------------------------------------------------
        // Beta averaging on FULL coef vector (slope + det)
        // Matches RATS pdlbsum1/pdlbsum2/pdlbsum3 + averaging
        // ---------------------------------------------------------
        if ("`average'" == "simple") {
            beta_bar_full = mean(_gd_beta)
            V_bar_full = J(K, K, 0)
            for (i = 1; i <= N_units; i++) {
                V_bar_full = V_bar_full + asarray(_gd_LRV, strofreal(i))
            }
            V_bar_full = V_bar_full / (N_units^2)
        }
        else if ("`average'" == "sqrt") {
            H2 = J(K, K, 0)
            bsum = J(K, 1, 0)
            Vsum = J(K, K, 0)
            for (i = 1; i <= N_units; i++) {
                LRV_i = asarray(_gd_LRV, strofreal(i))
                diagLRV = J(K, K, 0)
                for (k = 1; k <= K; k++) {
                    diagLRV[k, k] = LRV_i[k, k]
                }
                dd_i = invsym(cholesky(diagLRV))
                H2 = H2 + dd_i
                bsum = bsum + dd_i * _gd_beta[i, .]'
                Vsum = Vsum + dd_i * LRV_i * dd_i
            }
            H2inv = invsym(H2)
            beta_bar_full = (H2inv * bsum)'
            V_bar_full = H2inv * Vsum * H2inv
        }
        else {  // precision
            H3 = J(K, K, 0)
            bsum = J(K, 1, 0)
            for (i = 1; i <= N_units; i++) {
                LRV_i = asarray(_gd_LRV, strofreal(i))
                Vinv_i = invsym(LRV_i)
                H3 = H3 + Vinv_i
                bsum = bsum + Vinv_i * _gd_beta[i, .]'
            }
            H3inv = invsym(H3)
            beta_bar_full = (H3inv * bsum)'
            V_bar_full = H3inv
        }

        // Slice slope-only for output
        beta_bar = beta_bar_full[1, 1..K_x_only]
        V_bar = V_bar_full[|1, 1 \ K_x_only, K_x_only|]
        t_bar = t_bar_full[1, 1..K_x_only]
        se_bar = J(1, K_x_only, .)
        for (k = 1; k <= K_x_only; k++) {
            se_bar[1, k] = sqrt(V_bar[k, k])
        }

        st_matrix("`LR_MEAN'", beta_bar)
        st_matrix("`LR_SE'",   se_bar)
        st_matrix("`LR_V'",    V_bar)
        st_matrix("`T_STAT'",  t_bar)
    }

    * Individual unit-level matrices (matching RATS @paneldols output)
    tempname IBETAS ISTDERR ITSTATS
    mata {
        N_units = rows(_gd_beta)
        K_x_only = `K_x'
        b0_slope = strtoreal(tokens("`b_vec'"))
        ISTDERR_m = J(N_units, K_x_only, .)
        ITSTATS_m = J(N_units, K_x_only, .)
        IBETAS_m  = J(N_units, K_x_only, .)
        for (i = 1; i <= N_units; i++) {
            LRV_i = asarray(_gd_LRV, strofreal(i))
            for (k = 1; k <= K_x_only; k++) {
                IBETAS_m[i, k]  = _gd_beta[i, k]
                ISTDERR_m[i, k] = sqrt(LRV_i[k, k])
                ITSTATS_m[i, k] = (_gd_beta[i, k] - b0_slope[1, k]) / ISTDERR_m[i, k]
            }
        }
        st_matrix("`IBETAS'",  IBETAS_m)
        st_matrix("`ISTDERR'", ISTDERR_m)
        st_matrix("`ITSTATS'", ITSTATS_m)
    }

    mata: mata drop _gd_beta _gd_LRV _tmp_b
    * (_gd_alpha kept for residual calculation; dropped at end)

    qui count if !missing(`resid_tv')
    local n_obs = r(N)
    local n_g   = `nvalid'

    * =================================================================
    * Display results
    * =================================================================
    if "`full'" != "" & `nvalid' > 0 {
        di as text "{hline 80}"
    }
    _xtgmcoint_helper_hdr "Long Run Est. (Group-Mean Panel DOLS)"
    forvalues xi = 1/`K_x' {
        local xn : word `xi' of `xvars'
        local xn_clean = subinstr("`xn'", ".", "_", .)
        local est = `LR_MEAN'[1, `xi']
        local tst = `T_STAT'[1, `xi']
        _xtgmcoint_helper_r "lr_`xn_clean'" `est' `tst'
    }
    _xtgmcoint_helper_ftr

    di _newline
    di as text "xtgmcoint (method=dols): Group-Mean Panel DOLS (Pedroni 2001)"
    di as text "N obs: `n_obs', N units: `n_g'"
    di as text "DOLS leads/lags: `dlags'"
    di as text "Averaging: `average'"
    if `do_tdemean' {
        di as text "Time dummies: yes"
    }
    else {
        di as text "Time dummies: no"
    }
    if `n_g' < `ntotal' {
        local _dropped = `ntotal' - `n_g'
        di as text "Note: `_dropped' of `ntotal' units dropped (insufficient obs)"
    }
    di "Signif: *** 0.01  ** 0.05  * 0.1 (H0 vector: `b_vec')"

    ereturn local cmd    "xtgmcoint"
    ereturn local method "dols"
    ereturn local engine "native Group-Mean Panel DOLS"
    ereturn local depvar "`depvar'"
    ereturn local xvars  "`xvars'"
    ereturn local tdum   = cond(`do_tdemean', "yes", "no")
    ereturn local average "`average'"
    ereturn scalar N       = `n_obs'
    ereturn scalar N_g     = `n_g'
    ereturn scalar K_x     = `K_x'
    ereturn scalar dlags   = `dlags'
    ereturn scalar lags    = `lags'

    * Null hypothesis vector b0 stored as a matrix (1 x K_x)
    tempname BVEC
    matrix `BVEC' = J(1, `K_x', .)
    local _bi = 0
    foreach _bv of local b_vec {
        local ++_bi
        matrix `BVEC'[1, `_bi'] = `_bv'
    }
    ereturn matrix b0     = `BVEC'

    ereturn matrix b_lr    = `LR_MEAN'
    ereturn matrix se_lr   = `LR_SE'
    ereturn matrix V_lr    = `LR_V'
    ereturn matrix t_lr    = `T_STAT'
    ereturn matrix ibetas  = `IBETAS'
    ereturn matrix istderr = `ISTDERR'
    ereturn matrix itstats = `ITSTATS'

    * Residuals (RATS @paneldols %RESIDS):
    *   resid_it = y_it - alpha_GM - X_it'*beta_panel
    *   where alpha_GM is the simple mean of unit-level DOLS constants
    *   (matches RATS pdlbsum1 averaging, paneldols.src line 295/314).
    *   This replicates RATS' %resids series exactly.
    if "`resid'" != "" | "`fit'" != "" {
        tempvar _residtmp
        qui gen double `_residtmp' = `depvar' if `touse'
        tempname _b_lr_local
        matrix `_b_lr_local' = e(b_lr)
        local _xi = 0
        foreach _xv of local xvars {
            local ++_xi
            qui replace `_residtmp' = `_residtmp' - el(`_b_lr_local', 1, `_xi') * `_xv' if `touse'
        }
        local _alpha_p = 0
        cap mata: st_local("_alpha_p", strofreal(mean(_gd_alpha)))
        qui replace `_residtmp' = `_residtmp' - `_alpha_p' if `touse'

        if "`resid'" != "" {
            cap drop `resid'
            qui gen double `resid' = `_residtmp'
            label var `resid' "xtgmcoint DOLS residuals (matches RATS %resids)"
        }
        if "`fit'" != "" {
            cap drop `fit'
            qui gen double `fit' = `depvar' - `_residtmp' if `touse'
            label var `fit' "xtgmcoint DOLS fitted values (y - resid)"
        }
        cap drop `_residtmp'
    }
    cap mata: mata drop _gd_alpha
end

* ==================================================================
* Internal helpers (used by both DOLS and FMOLS subroutines)
* ==================================================================

capture program drop _xtgmcoint_wraplist
program define _xtgmcoint_wraplist
    args label items
    local indent = "         "
    local maxw = 78
    local line "`label' "
    local first = 1
    foreach it of local items {
        if `first' {
            local line "`line'`it'"
            local first = 0
        }
        else {
            local newlen : length local line
            local addlen : length local it
            if `newlen' + `addlen' + 1 > `maxw' {
                di as text "`line'"
                local line "`indent'`it'"
            }
            else {
                local line "`line' `it'"
            }
        }
    }
    if "`line'" != "" di as text "`line'"
end

capture program drop _xtgmcoint_illposed_open
program define _xtgmcoint_illposed_open
    args cmd
    di _newline as text "`cmd': no units produced valid estimates -- model is ill-posed."
    di as text "{hline 80}"
end

capture program drop _xtgmcoint_illposed_close
program define _xtgmcoint_illposed_close
    di as text "  No unit met the minimum-obs threshold, or every unit's regressor"
    di as text "  matrix was rank deficient (perfect collinearity among lags/CSA)."
    di as text "{hline 80}"
    di as text "Suggestions:"
    di as text "  - Reduce the number of lag / CSA terms in the specification"
    di as text "  - Check panel length T: each unit needs T > 2K_total observations"
    di as text "    to be safely identified"
    di as text "{hline 80}"
end

* ==================================================================
* FMOLS estimator (Pedroni 2000)
* ==================================================================

program define _xtgmcoint_fmols, eclass
    version 15.0
    syntax anything [if] [in] , ///
        [ ID(varname) TIME(varname) ///
          LAGS(integer -1) ///
          TDUM TREND ///
          B(numlist) AVERAGE(string) FULL TTest ///
          RESid(name) FIT(name) ]

    * ---- Deterministic: constant (default) or constant + trend (if `trend' option)
    if "`trend'" != "" local det "trend"
    else               local det "constant"

    * ---- Panel vars
    if "`id'" == "" | "`time'" == "" {
        qui xtset
        if "`id'"   == "" local id   "`r(panelvar)'"
        if "`time'" == "" local time "`r(timevar)'"
    }
    if "`id'" == "" | "`time'" == "" {
        di as err "id() and time() or xtset required."
        exit 198
    }
    sort `id' `time'
    qui xtset `id' `time'

    * ---- Averaging
    if "`average'" == "" local average "simple"
    local average = lower("`average'")
    if !inlist("`average'","simple","sqrt","precision") {
        di as err "average() must be simple, sqrt, or precision."
        exit 198
    }

    * ---- Parse varlist
    tokenize `anything'
    local depvar "`1'"
    macro shift
    local xvars "`*'"
    local K_x : word count `xvars'

    * Parse b() option as a numlist (one null per RHS or single value applied to all)
    if "`b'" == "" {
        local b_vec ""
        forvalues k = 1/`K_x' {
            local b_vec "`b_vec' 0"
        }
    }
    else {
        local b_n : word count `b'
        if `b_n' == 1 {
            local b_vec ""
            forvalues k = 1/`K_x' {
                local b_vec "`b_vec' `b'"
            }
        }
        else if `b_n' == `K_x' {
            local b_vec "`b'"
        }
        else {
            di as err "b() must be either a single value or `K_x' values (one per RHS)."
            exit 198
        }
    }
    local b_vec = trim("`b_vec'")
    * Scalar `b' = first element (for single-coef display contexts)
    local b : word 1 of `b_vec'

    marksample touse
    markout `touse' `depvar' `xvars'

    * =================================================================
    * STEP 1: Optional time-demean (panelfm.src satir 232-237)
    * =================================================================
    local do_tdemean = 0
    if "`tdum'" != "" local do_tdemean = 1

    if `do_tdemean' {
        tempvar y_reg
        qui bysort `time': egen double _tmean_y = mean(`depvar') if `touse'
        qui gen double `y_reg' = `depvar' - _tmean_y if `touse'
        qui drop _tmean_y

        local x_reg ""
        foreach xv of local xvars {
            tempvar xtd
            qui bysort `time': egen double _tmean_x = mean(`xv') if `touse'
            qui gen double `xtd' = `xv' - _tmean_x if `touse'
            qui drop _tmean_x
            local x_reg "`x_reg' `xtd'"
        }
    }
    else {
        local y_reg "`depvar'"
        local x_reg "`xvars'"
    }

    sort `id' `time'
    qui xtset `id' `time'

    * =================================================================
    * STEP 1.5: Apply "valid regression sample" mask (panelfm.src satir 234-237)
    *   dvec(k) = ytilde(k) if %valid(u) else NA
    *   Effect: rows with ANY missing on RHS are marked NA for all vars
    *   This matters for D.x at start-of-unit boundary in unbalanced panels
    * =================================================================
    local _x_reg_orig "`x_reg'"
    tempvar _reg_valid
    qui gen byte `_reg_valid' = !missing(`y_reg') if `touse'
    foreach xv of local _x_reg_orig {
        qui replace `_reg_valid' = 0 if missing(`xv') & `touse'
    }

    * Overwrite y_reg and x_reg to be NA outside _reg_valid
    tempvar _y_masked
    qui gen double `_y_masked' = cond(`_reg_valid'==1, `y_reg', .)
    local y_reg "`_y_masked'"

    local x_reg ""
    foreach xv of local _x_reg_orig {
        tempvar _xm
        qui gen double `_xm' = cond(`_reg_valid'==1, `xv', .)
        local x_reg "`x_reg' `_xm'"
    }

    * =================================================================
    * STEP 2: Create unit-demeaned Dx series (panelfm.src satir 274-278)
    *   diff(center): difference and remove unit mean
    *   Now using masked x_reg, D.x inherits NA at sample boundaries
    * =================================================================
    local dx_tvs ""
    local xi = 0
    foreach xv of local xvars {
        local ++xi
        * base_x: always from masked x_reg (reg_valid applied)
        local base_x : word `xi' of `x_reg'
        tempvar _Dx _Dxd
        qui gen double `_Dx' = D.`base_x'
        qui bysort `id': egen double _umean_dx = mean(`_Dx')
        qui gen double `_Dxd' = `_Dx' - _umean_dx
        qui drop _umean_dx `_Dx'
        local dx_tvs "`dx_tvs' `_Dxd'"
    }

    * =================================================================
    * Trend variable (if requested)
    * =================================================================
    local trend_var ""
    if "`trend'" != "" {
        tempvar _trend
        qui bysort `id' (`time'): gen double `_trend' = _n if `touse'
        local trend_var "`_trend'"
    }

    * =================================================================
    * Display header
    * =================================================================
    di _newline as text "xtgmcoint (method=fmols): Group-Mean Panel FMOLS (Pedroni 2000)"
    if `do_tdemean' {
        di as text "  Time dummies: ON (common time means subtracted)"
    }
    else {
        di as text "  Time dummies: OFF"
    }
    if "`trend'" != "" {
        di as text "  Deterministic: constant + trend"
    }
    else {
        di as text "  Deterministic: constant"
    }
    di as text "  LHS : `depvar'"
    _xtgmcoint_wraplist "  RHS :" "`xvars'"
    di as text "  Averaging: `average'"
    di ""

    * =================================================================
    * STEP 3: Unit loop
    * =================================================================
    qui levelsof `id' if `touse', local(uid_list)
    local _id_str = 0
    cap confirm string variable `id'
    if _rc == 0 local _id_str = 1

    tempvar resid_tv
    qui gen double `resid_tv' = .

    * Determine bandwidth (panelfm.src satir 253-258):
    *   auto = round(4*(tmax/100)^(2/9)) where tmax = max unit time obs
    qui bysort `id': gen long _unit_obs = _N if `touse'
    qui sum _unit_obs, meanonly
    local tmax = r(max)
    qui drop _unit_obs
    if `lags' < 0 {
        local _L = round(4 * (`tmax'/100)^(2/9))
        if `_L' < 1 local _L = 1
    }
    else {
        local _L = `lags'
    }

    local K_det = cond("`trend'"!="", 2, 1)

    * Mata accumulators
    mata: _gf_beta = J(0, `K_x' + `K_det', .)
    mata: _gf_alpha = J(0, 1, .)
    mata: _gf_LRV  = asarray_create("string", 1)

    local nvalid = 0
    local ntotal = 0

    foreach uid of local uid_list {
        local ++ntotal
        if `_id_str' local _ucond `id' == "`uid'"
        else         local _ucond `id' == `uid'

        * =================================================================
        * Step A: Preliminary OLS: y on x + det (panelfm.src satir 290-291)
        *   Sample = j//2 to j//tend (skip first obs of each unit)
        *   Because diff requires at least one prior obs
        * =================================================================
        * Unit sample (panelfm.src: j//2 to j//tend, with unbalanced handling)
        *   Start from first obs where all RHS non-missing, skip first obs
        *   If any intermediate missing, truncate at first gap
        * =================================================================
        tempvar _first_in_unit _all_valid
        qui bysort `id' (`time'): gen byte `_first_in_unit' = (_n == 1)
        qui gen byte `_all_valid' = !missing(`y_reg')
        foreach xv of local x_reg {
            qui replace `_all_valid' = 0 if missing(`xv')
        }
        if "`trend_var'" != "" qui replace `_all_valid' = 0 if missing(`trend_var')
                cap qui regress `y_reg' `x_reg' `trend_var' if `_ucond' & `touse' & !`_first_in_unit' & `_all_valid'
        qui drop `_first_in_unit'
        if _rc {
            qui drop `_all_valid'
            continue
        }

        tempvar _ehat _esmp
        qui gen byte `_esmp' = e(sample)
        qui predict double `_ehat' if `_esmp', resid

        * Min obs check
        qui count if `_esmp'
        local _T = r(N)
        if `_T' < (`K_x' + `K_det' + 2) {
            cap drop `_ehat' `_esmp'
            continue
        }

        * =================================================================
        * Step B: Long-run covariance Omega of (ehat, Dx_1, ..., Dx_K_x)
        *   panelfm.src satir 300-302: mcov Bartlett + %cmom/%nobs
        *   group-fm.prg: %cmom / (T-1)  -- NORMALIZE FARKLI
        * =================================================================
        * Collect series into Mata matrix (T x (K_x+1))
        mata: _gf_Z = _gf_get_panel_data("`_ehat' `dx_tvs'", "`_esmp'", `_T')

        * ============================================================
        * panelfm.src implementation (Tom Doan / Pedroni, RATS @panelfm)
        *   - T (e(N)) normalization
        *   - g (asymmetric only) bias correction
        *   - cmom-based sweep
        *   - t = (b-b0) / sqrt(sigma_1.2 * (X'X)^-1[k,k])
        * ============================================================
        mata: _gf_Omega = _gf_lrvar_bartlett(_gf_Z, `_L', 1)

        * Sweep
        mata: _gf_sweep_result = _gf_sweep_for_fmols(_gf_Omega, `K_x')
        mata: st_local("_gf_sigma1", strofreal(_gf_sweep_result.sigma1))
        mata: _gf_prjcoe = _gf_sweep_result.prjcoe

        * ydagger
        tempvar _ydagger
        qui gen double `_ydagger' = `y_reg' if `_esmp'
        local di_ix = 0
        foreach _dxv of local dx_tvs {
            local ++di_ix
            mata: st_local("_prj_coef", strofreal(_gf_prjcoe[`di_ix', 1]))
            qui replace `_ydagger' = `_ydagger' - `_prj_coef' * cond(missing(`_dxv'), 0, `_dxv') if `_esmp'
        }

        * Asymmetric g
        mata: _gf_g = _gf_lrvar_asymm(_gf_Z, `_L', 0)

        * Cross-product correction
        mata: _gf_alepht = _gf_g[|2,1 \ `K_x'+1, 1|] - _gf_g[|2,2 \ `K_x'+1, `K_x'+1|] * _gf_prjcoe

        * cmom + adjust + sweep
        tempname _cmom _cmomx
        qui matrix accum `_cmom' = `_ydagger' `x_reg' `trend_var' if `_esmp'
        forvalues k = 1/`K_x' {
            mata: st_local("_alk", strofreal(_gf_alepht[`k', 1]))
            matrix `_cmom'[1, `=`k'+1'] = `_cmom'[1, `=`k'+1'] - `_alk'
            matrix `_cmom'[`=`k'+1', 1] = `_cmom'[1, `=`k'+1']
        }

        local ncmom = `K_x' + `K_det' + 1
        mata: _gf_cmomx = _gf_sweep_all(st_matrix("`_cmom'"), `K_x' + `K_det')

        mata: _gf_bfm = _gf_cmomx[|2, 1 \ `ncmom', 1|]
        mata: _gf_vfm = `_gf_sigma1' * _gf_cmomx[|2, 2 \ `ncmom', `ncmom'|]

        mata: _tmp_b = _gf_bfm'              // 1 x (K_x + K_det) full coefs
        mata: _tmp_LRV = _gf_vfm             // (K_x+K_det) x (K_x+K_det)

        * =========================================================
        * FMOLS residual and fitted values (default mode)
        * =========================================================
        tempvar _yhat_fm
        qui gen double `_yhat_fm' = 0 if `_esmp'
        local k_idx = 0
        foreach _xv of local x_reg {
            local ++k_idx
            mata: st_local("_b_k", strofreal(_gf_bfm[`k_idx', 1]))
            qui replace `_yhat_fm' = `_yhat_fm' + `_b_k' * `_xv' if `_esmp'
        }
        if "`trend_var'" != "" {
            local ++k_idx
            mata: st_local("_b_k", strofreal(_gf_bfm[`k_idx', 1]))
            qui replace `_yhat_fm' = `_yhat_fm' + `_b_k' * `trend_var' if `_esmp'
        }
        if "`det'" != "none" {
            local k_idx = `K_x' + cond("`trend'"!="", 1, 0) + 1
            mata: st_local("_b_const", strofreal(_gf_bfm[`k_idx', 1]))
            qui replace `_yhat_fm' = `_yhat_fm' + `_b_const' if `_esmp'
        }
        qui replace `resid_tv' = `y_reg' - `_yhat_fm' if `_ucond' & `_esmp'
        cap drop `_yhat_fm'

        * For 'full' display
        mata: st_local("_b1", strofreal(_gf_bfm[1, 1]))
        mata: st_local("_vfm11", strofreal(_gf_vfm[1, 1]))
        local _se1 = sqrt(`_vfm11')

        * =========================================================
        * Push unit results to Mata accumulators (shared across both modes)
        * =========================================================
        mata: _gf_beta = _gf_beta \ _tmp_b
        mata: asarray(_gf_LRV, strofreal(`nvalid'+1), _tmp_LRV)
        * Append unit FMOLS constant (last element of bfm, panelfm.src line 355)
        if "`det'" != "none" {
            mata: _gf_alpha = _gf_alpha \ _gf_bfm[rows(_gf_bfm), 1]
        }
        else {
            mata: _gf_alpha = _gf_alpha \ 0
        }

        if "`full'" != "" {
            if `nvalid' == 0 {
                _xtgmcoint_helper_full_hdr "`ttest'" "FMOLS"
            }
            local _df_unit = `_T' - `K_x' - `K_det'
            local _df_arg = cond("`ttest'" != "", "`_df_unit'", "")
            _xtgmcoint_helper_full_r "`uid'" `_b1' `_se1' `b' `_df_arg'
        }

        cap drop `_ehat' `_esmp' `_ydagger' `_all_valid'
        local ++nvalid
    }

    * =================================================================
    * No valid units
    * =================================================================
    if `nvalid' == 0 {
        _xtgmcoint_illposed_open "xtgmcoint (method=fmols)"
        di as text "  RHS variables:       `K_x'"
        di as text "  Deterministic terms: `K_det'"
        di as text "  Bandwidth L:         `_L'"
        _xtgmcoint_illposed_close
        cap mata: mata drop _gf_beta _gf_LRV _tmp_b _tmp_LRV _gf_Z _gf_Omega _gf_sweep_result _gf_prjcoe _gf_g _gf_alepht _gf_cmomx _gf_bfm _gf_vfm
        exit 0
    }

    * =================================================================
    * STEP 4: Group-Mean averaging + Pedroni t-stat (same as DOLS)
    * =================================================================
    tempname LR_MEAN LR_SE LR_V T_STAT

    mata {
        N_units = rows(_gf_beta)
        K = cols(_gf_beta)                     // K_eff = K_x + K_det
        K_x_only = `K_x'
        b0_slope = strtoreal(tokens("`b_vec'"))
        b0 = b0_slope, J(1, K - K_x_only, 0)   // pad with zeros for det

        // t-statistic over full coefs
        t_sum_full = J(1, K, 0)
        for (i = 1; i <= N_units; i++) {
            LRV_i = asarray(_gf_LRV, strofreal(i))
            for (k = 1; k <= K; k++) {
                t_i_k = (_gf_beta[i, k] - b0[1, k]) / sqrt(LRV_i[k, k])
                t_sum_full[1, k] = t_sum_full[1, k] + t_i_k
            }
        }
        t_bar_full = t_sum_full / sqrt(N_units)

        // Beta averaging on FULL coef vector
        if ("`average'" == "simple") {
            beta_bar_full = mean(_gf_beta)
            V_bar_full = J(K, K, 0)
            for (i = 1; i <= N_units; i++) {
                V_bar_full = V_bar_full + asarray(_gf_LRV, strofreal(i))
            }
            V_bar_full = V_bar_full / (N_units^2)
        }
        else if ("`average'" == "sqrt") {
            H2 = J(K, K, 0)
            bsum = J(K, 1, 0)
            Vsum = J(K, K, 0)
            for (i = 1; i <= N_units; i++) {
                LRV_i = asarray(_gf_LRV, strofreal(i))
                diagLRV = J(K, K, 0)
                for (k = 1; k <= K; k++) {
                    diagLRV[k, k] = LRV_i[k, k]
                }
                dd_i = invsym(cholesky(diagLRV))
                H2 = H2 + dd_i
                bsum = bsum + dd_i * _gf_beta[i, .]'
                Vsum = Vsum + dd_i * LRV_i * dd_i
            }
            H2inv = invsym(H2)
            beta_bar_full = (H2inv * bsum)'
            V_bar_full = H2inv * Vsum * H2inv
        }
        else {  // precision
            H3 = J(K, K, 0)
            bsum = J(K, 1, 0)
            for (i = 1; i <= N_units; i++) {
                LRV_i = asarray(_gf_LRV, strofreal(i))
                Vinv_i = invsym(LRV_i)
                H3 = H3 + Vinv_i
                bsum = bsum + Vinv_i * _gf_beta[i, .]'
            }
            H3inv = invsym(H3)
            beta_bar_full = (H3inv * bsum)'
            V_bar_full = H3inv
        }

        // Slice slope-only for output
        beta_bar = beta_bar_full[1, 1..K_x_only]
        V_bar = V_bar_full[|1, 1 \ K_x_only, K_x_only|]
        t_bar = t_bar_full[1, 1..K_x_only]
        se_bar = J(1, K_x_only, .)
        for (k = 1; k <= K_x_only; k++) {
            se_bar[1, k] = sqrt(V_bar[k, k])
        }

        st_matrix("`LR_MEAN'", beta_bar)
        st_matrix("`LR_SE'",   se_bar)
        st_matrix("`LR_V'",    V_bar)
        st_matrix("`T_STAT'",  t_bar)
    }

    cap mata: mata drop _tmp_b _tmp_LRV _gf_Z _gf_Omega _gf_sweep_result _gf_prjcoe _gf_g _gf_alepht _gf_cmomx _gf_bfm _gf_vfm

    qui count if !missing(`resid_tv')
    local n_obs = r(N)
    local n_g   = `nvalid'

    * =================================================================
    * Display results
    * =================================================================
    if "`full'" != "" & `nvalid' > 0 {
        di as text "{hline 80}"
    }
    _xtgmcoint_helper_hdr "Long Run Est. (Group-Mean Panel FMOLS)"
    forvalues xi = 1/`K_x' {
        local xn : word `xi' of `xvars'
        local xn_clean = subinstr("`xn'", ".", "_", .)
        local est = `LR_MEAN'[1, `xi']
        local tst = `T_STAT'[1, `xi']
        _xtgmcoint_helper_r "lr_`xn_clean'" `est' `tst'
    }
    _xtgmcoint_helper_ftr

    di _newline
    di as text "xtgmcoint (method=fmols): Group-Mean Panel FMOLS (Pedroni 2000)"
    di as text "N obs: `n_obs', N units: `n_g'"
    di as text "Bandwidth (Bartlett lags): `_L'"
    di as text "Averaging: `average'"
    if `do_tdemean' di as text "Time dummies: yes"
    else            di as text "Time dummies: no"
    if "`trend'" != "" di as text "Deterministic: constant + trend"
    else                      di as text "Deterministic: constant"
    if `n_g' < `ntotal' {
        local _dropped = `ntotal' - `n_g'
        di as text "Note: `_dropped' of `ntotal' units dropped (insufficient obs)"
    }
    di "Signif: *** 0.01  ** 0.05  * 0.1 (H0 vector: `b_vec')"

    ereturn local cmd    "xtgmcoint"
    ereturn local method "fmols"
    ereturn local engine "native Group-Mean Panel FMOLS"
    ereturn local depvar "`depvar'"
    ereturn local xvars  "`xvars'"
    ereturn local tdum   = cond(`do_tdemean', "yes", "no")
    ereturn local average "`average'"
    ereturn scalar N       = `n_obs'
    ereturn scalar N_g     = `n_g'
    ereturn scalar K_x     = `K_x'
    ereturn scalar lags    = `_L'

    * Null hypothesis vector b0 stored as a matrix (1 x K_x)
    tempname BVEC
    matrix `BVEC' = J(1, `K_x', .)
    local _bi = 0
    foreach _bv of local b_vec {
        local ++_bi
        matrix `BVEC'[1, `_bi'] = `_bv'
    }
    ereturn matrix b0      = `BVEC'

    ereturn matrix b_lr    = `LR_MEAN'
    ereturn matrix se_lr   = `LR_SE'
    ereturn matrix V_lr    = `LR_V'
    ereturn matrix t_lr    = `T_STAT'

    * Individual unit-level matrices (matching RATS @panelfm output)
    tempname IBETAS ISTDERR ITSTATS
    mata {
        N_units = rows(_gf_beta)
        K_x_only = `K_x'
        b0_slope = strtoreal(tokens("`b_vec'"))
        IBETAS_m  = J(N_units, K_x_only, .)
        ISTDERR_m = J(N_units, K_x_only, .)
        ITSTATS_m = J(N_units, K_x_only, .)
        for (i = 1; i <= N_units; i++) {
            LRV_i = asarray(_gf_LRV, strofreal(i))
            for (k = 1; k <= K_x_only; k++) {
                IBETAS_m[i, k]  = _gf_beta[i, k]
                ISTDERR_m[i, k] = sqrt(LRV_i[k, k])
                ITSTATS_m[i, k] = (_gf_beta[i, k] - b0_slope[1, k]) / ISTDERR_m[i, k]
            }
        }
        st_matrix("`IBETAS'",  IBETAS_m)
        st_matrix("`ISTDERR'", ISTDERR_m)
        st_matrix("`ITSTATS'", ITSTATS_m)
    }
    ereturn matrix ibetas  = `IBETAS'
    ereturn matrix istderr = `ISTDERR'
    ereturn matrix itstats = `ITSTATS'

    cap mata: mata drop _gf_beta _gf_LRV

    * Residuals (RATS @panelfm %RESIDS):
    *   resid_it = y_it - alpha_GM - X_it'*beta_panel
    *   where alpha_GM is the simple mean of unit-level FMOLS constants
    *   (matches RATS pfmbsum1 averaging, panelfm.src line 355/374).
    *   This replicates RATS' %resids series exactly.
    if "`resid'" != "" | "`fit'" != "" {
        tempvar _residtmp
        qui gen double `_residtmp' = `y_reg' if `touse'
        tempname _b_lr_local
        matrix `_b_lr_local' = e(b_lr)
        local _xi = 0
        foreach _xv of local xvars {
            local ++_xi
            qui replace `_residtmp' = `_residtmp' - el(`_b_lr_local', 1, `_xi') * `_xv' if `touse'
        }
        local _alpha_p = 0
        cap mata: st_local("_alpha_p", strofreal(mean(_gf_alpha)))
        qui replace `_residtmp' = `_residtmp' - `_alpha_p' if `touse'

        if "`resid'" != "" {
            cap drop `resid'
            qui gen double `resid' = `_residtmp'
            label var `resid' "xtgmcoint FMOLS residuals (matches RATS %resids)"
        }
        if "`fit'" != "" {
            cap drop `fit'
            qui gen double `fit' = `y_reg' - `_residtmp' if `touse'
            label var `fit' "xtgmcoint FMOLS fitted values (y - resid)"
        }
        cap drop `_residtmp'
    }
    cap mata: mata drop _gf_alpha
end

* ==================================================================
* Display helpers (used by both DOLS and FMOLS subroutines)
* ==================================================================
program define _xtgmcoint_helper_r
    args label est tst
    local p_  = 2 * (1 - normal(abs(`tst')))
    local stars "   "
    if      `p_' < 0.01 local stars "***"
    else if `p_' < 0.05  local stars "** "
    else if `p_' < 0.1  local stars "*  "
    di as text %16s "`label'" as result %12.4f `est' %12.4f `tst' %10.4f `p_' as text %6s " `stars'"
end

program define _xtgmcoint_helper_hdr
    args title
    di _newline as text "`title'"
    di as text "{hline 62}"
    di as text %16s "" %12s "Beta" %12s "t-stat" %10s "P>|t|" %6s ""
    di as text "{hline 62}"
end

program define _xtgmcoint_helper_ftr
    di as text "{hline 62}"
end

program define _xtgmcoint_helper_full_hdr
    args use_t method_label
    di _newline as text "Unit-by-unit `method_label' estimates"
    di as text "{hline 80}"
    if "`use_t'" != "" {
        di as text %16s "Unit" %10s "Coef." %10s "Std.Err." %8s "t-stat" %8s "P>|t|" %6s "" %10s "CI 2.5%" %10s "CI 97.5%"
    }
    else {
        di as text %16s "Unit" %10s "Coef." %10s "Std.Err." %8s "z" %8s "P>|z|" %6s "" %10s "CI 2.5%" %10s "CI 97.5%"
    }
    di as text "{hline 80}"
end

program define _xtgmcoint_helper_full_r
    args unit est se b0 df
    local z_  = (`est' - `b0') / `se'
    if "`df'" != "" & `df' > 0 {
        local p_  = 2 * ttail(`df', abs(`z_'))
        local crit = invttail(`df', 0.025)
    }
    else {
        local p_  = 2 * (1 - normal(abs(`z_')))
        local crit = 1.96
    }
    local cil = `est' - `crit' * `se'
    local ciu = `est' + `crit' * `se'
    local stars "   "
    if      `p_' < 0.01 local stars "***"
    else if `p_' < 0.05  local stars "** "
    else if `p_' < 0.1  local stars "*  "
    di as text %16s "`unit'" as result %10.4f `est' %10.4f `se' %8.2f `z_' %8.4f `p_' as text %6s " `stars'" as result %10.4f `cil' %10.4f `ciu'
end

* ==================================================================
* Mata library for FMOLS computations
* ==================================================================
mata:

// Fetch panel data as Mata matrix (T x K)
real matrix _gf_get_panel_data(string scalar varlist, string scalar touse, real scalar T)
{
    real matrix Z
    string rowvector vars
    vars = tokens(varlist)
    Z = J(T, length(vars), .)
    st_view(Z, ., vars, touse)
    return(Z)
}

// Symmetric long-run covariance (two-sided Bartlett kernel)
// Z: T x K data matrix (residuals or stationary variables, already demeaned)
// L: bandwidth
// divn: 1 -> divide by T (panelfm.src does %cmom/%nobs), 0 -> no normalization
real matrix _gf_lrvar_bartlett(real matrix Z, real scalar L, real scalar divn)
{
    real scalar T, K, l, w
    real matrix Omega, G_l
    T = rows(Z)
    K = cols(Z)
    // Remove missings
    Z = select(Z, !rowmissing(Z))
    T = rows(Z)

    // Omega_0 (contemporaneous)
    Omega = Z' * Z
    // Add l = 1..L autocovariances with Bartlett weight 1 - l/(L+1)
    for (l = 1; l <= L; l++) {
        if (T - l < 1) break
        G_l = Z[|1, 1 \ T-l, K|]' * Z[|1+l, 1 \ T, K|]
        w = 1 - l/(L+1)
        Omega = Omega + w * (G_l + G_l')
    }
    if (divn) {
        Omega = Omega / T
    }
    return(Omega)
}

// Asymmetric long-run covariance (one-sided: current + leads)
// panelfm.src lw(i) = 2*(L+1-i)/(L+1) for i >= L+1, else 0
// In the mcov lwform sense, lw has 2L+1 entries, indexed such that lag 0 is at position L+1
// lw(L+1) = 2, lw(L+2) = 2*L/(L+1), ..., lw(2L+1) = 2/(L+1)
// lw(1..L) = 0
// This is equivalent to: contemporaneous term weighted 2, plus leads l=1..L with weight 2*(L+1-l)/(L+1)/... wait
// Actually panelfm formula: lw(i) = 2*(L+1-i)/(L+1) when i>=L+1 means weight decreases for larger leads
// Interpretation: the mcov output g = sum_{l=-L}^{L} lw(L+1+l) * Z_t Z_{t+l}'
// But lw(i)=0 for i<L+1 means lags < 0 not used, only lag 0 and positive leads.
// Lag 0: lw(L+1) = 2*(L+1-(L+1))/(L+1) ... no, i=L+1 gives 2*0/(L+1)=0. Hmm.
// Let me re-read: lw(i)=%if(i>=mlag+1, float(2*(mlag+1)-i)/(mlag+1), 0.0)
// i=1..2mlag+1 (so 2*L+1 weights)
// For i=L+1 (center): 2*(L+1)-i = 2L+2-L-1 = L+1, so lw = (L+1)/(L+1) = 1.0
// For i=L+2: 2L+2 - (L+2) = L, lw = L/(L+1)
// For i=L+3: L-1, lw = (L-1)/(L+1)
// ...
// For i=2L+1: 2L+2-2L-1 = 1, lw = 1/(L+1)
// For i<L+1: lw=0
// 
// So center weight = 1.0, leads l=1..L weights = (L+1-l)/(L+1)
// (Note: no factor 2, the formula without the '2' gives Newey-West positive-semi-def form)
// Wait re-check: "2*(mlag+1)-i" at i=L+1 = 2L+2-L-1 = L+1, divided by (L+1) = 1.0. OK center = 1.
// At i=L+2: 2L+2-L-2 = L, /(L+1)
// So weights: [0, 0, ..., 0, 1, L/(L+1), (L-1)/(L+1), ..., 1/(L+1)]
//              (1..L)           L+1, L+2, L+3, ..., 2L+1
//              lags -L..-1       lag 0, lead 1, lead 2, ..., lead L
// Yes: one-sided, center weight 1, then decreasing triangular for leads.

real matrix _gf_lrvar_asymm(real matrix Z, real scalar L, real scalar divn)
{
    real scalar T, K, l, w
    real matrix g, G_l
    T = rows(Z)
    K = cols(Z)
    Z = select(Z, !rowmissing(Z))
    T = rows(Z)

    // Center (lag 0): weight 1
    g = Z' * Z
    // Leads l = 1..L: weight (L+1-l)/(L+1), use Z_t Z_{t+l}'
    for (l = 1; l <= L; l++) {
        if (T - l < 1) break
        G_l = Z[|1, 1 \ T-l, K|]' * Z[|1+l, 1 \ T, K|]
        w = (L+1-l) / (L+1)
        g = g + w * G_l
    }
    if (divn) {
        g = g / T
    }
    return(g)
}

// Sweep struct for FMOLS
struct _gf_sweep_res {
    real scalar sigma1
    real colvector prjcoe
}

// Sweep Omega matrix to extract prjcoe and sigma1
// Omega: (1+K_x) x (1+K_x) matrix, row/col 1 = residual, 2..K_x+1 = Dx
// After sweeping out rows/cols 2..K_x+1:
//   cmomx[2..K_x+1, 1] = inv(Omega_{xx}) * Omega_{x,eps}  (projection coefs)
//   cmomx[1, 1]        = Omega_{ee} - Omega_{ex}*inv(Omega_{xx})*Omega_{xe}  (conditional var)
struct _gf_sweep_res scalar _gf_sweep_for_fmols(real matrix Omega, real scalar K_x)
{
    struct _gf_sweep_res scalar r
    real matrix Oxx, Oxe, Oee
    Oee = Omega[1, 1]
    Oxe = Omega[|2, 1 \ K_x+1, 1|]        // K_x x 1
    Oxx = Omega[|2, 2 \ K_x+1, K_x+1|]    // K_x x K_x
    r.prjcoe = invsym(Oxx) * Oxe                   // K_x x 1
    r.sigma1 = Oee - Oxe' * r.prjcoe
    return(r)
}

// Sweep out cols [2..K+1] of (K+1)x(K+1) cross-moment matrix to get coefs in col 1
// cmom: (1+K) x (1+K), where K = K_x + K_det
// After sweep: cmomx[2..K+1, 1] are the regression coefs
//              cmomx[2..K+1, 2..K+1] = (X'X)^-1
//              cmomx[1, 1] = RSS
real matrix _gf_sweep_all(real matrix cmom, real scalar K)
{
    real matrix cmomx, Ainv, Cxy, Cyy, Cxx, beta
    Cyy = cmom[1, 1]
    Cxy = cmom[|2, 1 \ K+1, 1|]        // K x 1
    Cxx = cmom[|2, 2 \ K+1, K+1|]      // K x K
    // Use luinv() for numerical stability (matches RATS %sweeplist better)
    Ainv = luinv(Cxx)
    beta = Ainv * Cxy
    cmomx = J(K+1, K+1, 0)
    cmomx[1, 1] = Cyy - Cxy' * beta                // RSS
    cmomx[|2, 1 \ K+1, 1|] = beta                  // beta
    cmomx[|1, 2 \ 1, K+1|] = beta'                 // symmetric
    cmomx[|2, 2 \ K+1, K+1|] = Ainv                // (X'X)^-1
    return(cmomx)
}


end
