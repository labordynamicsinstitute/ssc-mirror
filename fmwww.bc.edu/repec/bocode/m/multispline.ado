*! multispline.ado  v0.2.0  Subir Hait  Michigan State University
*! Spline-Based Nonlinear Modeling for Multilevel and Longitudinal Data
*! Stata 14.1 compatible - single file - all bugs fixed
version 14.0

program define multispline, eclass
    version 14.0

    syntax varlist(min=2 fv ts) [if] [in] , ///
        [                                    ///
        CLuster(varlist)                     ///
        NESTED                               ///
        DF(string)                           ///
        DF_Range(string)                     ///
        CRiterion(string)                    ///
        Method(string)                       ///
        BS_Degree(integer 3)                 ///
        Time(varname)                        ///
        NKNOT_Plot                           ///
        COMPare                              ///
        POLy_degrees(string)                 ///
        PRedict_grid(integer 100)            ///
        LEvel(integer 95)                    ///
        DERivatives                          ///
        TUrning_points                       ///
        R2                                   ///
        ICC                                  ///
        SAving(string)                       ///
        PLOT(string)                         ///
        FAMily(string)                       ///
        RANDslope                            ///
        HET                                  ///
        NHet(integer 30)                     ///
        ]

    marksample touse

    tokenize `varlist'
    local yvar `1'
    macro shift
    local xvar `1'
    macro shift
    local controls `*'

    if "`criterion'"    == "" local criterion    "aic"
    if "`method'"       == "" local method       "ns"
    if "`df_range'"     == "" local df_range     "2 3 4 5 6"
    if "`poly_degrees'" == "" local poly_degrees "2 3"
    if "`df'"           == "" local df           "auto"
    if "`family'"       == "" local family       "gaussian"

    * Validate family
    if !inlist("`family'","gaussian","logit","probit") {
        di as error "family() must be: gaussian  logit  probit"
        exit 198
    }
    local is_binary = ("`family'" != "gaussian")

    * turning_points requires derivatives
    if "`turning_points'" != "" local derivatives "yes"
    * het/cluster validation done after cl1 is set

    local crit_upper = upper("`criterion'")
    local n_cluster : word count `cluster'
    local cl1 : word 1 of `cluster'
    local cl2 : word 2 of `cluster'
    local is_ols = ("`cl1'" == "")

    * Now validate het (needs cl1 to be set first)
    if "`het'" != "" & "`cl1'" == "" {
        di as error "het requires cluster() to be specified"
        exit 198
    }

    * Header
    di _newline as text "{hline 65}"
    di as text " MultiSpline v0.2.0  -  Nonlinear Multilevel Spline Model"
    di as text "{hline 65}"
    di as text " Outcome  : " as result "`yvar'"
    di as text " Predictor: " as result "`xvar'"
    if "`controls'" != "" di as text " Controls : " as result "`controls'"
    if "`cl1'"      != "" di as text " Cluster  : " as result "`cluster'"
    di as text " Method   : " as result "`method'"
    if `is_binary'       di as text " Family   : " as result "`family'"
    if "`randslope'" != "" di as text " Slopes    : " as result "random (spline basis)"
    di as text "{hline 65}"

    * ============================================================
    * Helper: compute AIC or BIC after any model type
    * For regress: compute ll from RSS (regress does NOT store e(ll))
    * For mixed:   use e(ll) directly
    * ============================================================
    * (used inline below as a local macro pattern)

    * ============================================================
    * STEP 1: Automatic df selection
    * nknots = df + 1 (Stata range: nknots 3-7, so df 2-6)
    * mkspline cubic nknots(k) creates exactly k-1 variables
    * ============================================================
    if "`df'" == "auto" {
        di _newline as text "--- Automatic df selection (criterion: `crit_upper') ---"

        local best_df   = .
        local best_crit = .
        local crit_list ""          // store df cv df cv ...

        foreach df_try of local df_range {

            local nk = `df_try' + 1
            if `nk' < 3 local nk = 3
            if `nk' > 7 local nk = 7
            local nb = `nk' - 1

            capture drop _ms_b_*
            quietly capture mkspline _ms_b_ = `xvar' if `touse', ///
                cubic nknots(`nk')
            if _rc continue

            local bvars ""
            forvalues j = 1/`nb' {
                capture confirm variable _ms_b_`j'
                if !_rc local bvars `bvars' _ms_b_`j'
            }
            if "`bvars'" == "" continue

            quietly {
                if `is_ols' & !`is_binary' {
                    capture regress `yvar' `bvars' `controls' if `touse'
                }
                else if `is_binary' {
                    if "`cl1'" == "" {
                        if "`family'" == "logit" {
                            capture logit `yvar' `bvars' `controls' if `touse'
                        }
                        else {
                            capture probit `yvar' `bvars' `controls' if `touse'
                        }
                    }
                    else if `n_cluster' == 1 {
                        if "`family'" == "logit" {
                            capture melogit `yvar' `bvars' `controls' ///
                                if `touse' || `cl1':
                        }
                        else {
                            capture meprobit `yvar' `bvars' `controls' ///
                                if `touse' || `cl1':
                        }
                    }
                    else {
                        if "`family'" == "logit" {
                            capture melogit `yvar' `bvars' `controls' ///
                                if `touse' || `cl1': || `cl2':
                        }
                        else {
                            capture meprobit `yvar' `bvars' `controls' ///
                                if `touse' || `cl1': || `cl2':
                        }
                    }
                }
                else if `n_cluster' == 1 {
                    capture mixed `yvar' `bvars' `controls' ///
                        if `touse' || `cl1':
                }
                else {
                    if "`nested'" != "" {
                        capture mixed `yvar' `bvars' `controls' ///
                            if `touse' || `cl1': || `cl2':
                    }
                    else {
                        capture mixed `yvar' `bvars' `controls' ///
                            if `touse' || _all: R.`cl1' || `cl2':
                    }
                }
            }
            if _rc continue

            * Compute log-likelihood and criterion
            local n_t = e(N)
            local k_t = e(df_m) + 1
            if `is_ols' & !`is_binary' {
                local rss = e(rss)
                if `rss' <= 0 | missing(`rss') continue
                local ll_t = -`n_t'/2 * (1 + ln(2*_pi) + ln(`rss'/`n_t'))
            }
            else {
                local ll_t = e(ll)
                if "`cl1'" != "" | `is_binary' local k_t = e(k)
                if missing(`ll_t') continue
            }

            if "`criterion'" == "aic" local cv = -2*`ll_t' + 2*`k_t'
            else                      local cv = -2*`ll_t' + ln(`n_t')*`k_t'

            local crit_list `crit_list' `df_try' `cv'

            if `cv' < `best_crit' | `best_crit' == . {
                local best_crit = `cv'
                local best_df   = `df_try'
            }
            capture drop _ms_b_*
        }

        if `best_df' == . {
            di as error "df selection failed for all candidates in df_range."
            di as error "Check that `yvar' and `xvar' have no missing values."
            capture drop _ms_b_*
            exit 198
        }

        * Display table with best marked
        di as text "  df  |  `crit_upper'"
        di as text "  {hline 24}"
        local nw : word count `crit_list'
        local idx = 1
        while `idx' <= `nw' {
            local dv : word `idx'       of `crit_list'
            local cv : word `=`idx'+1'  of `crit_list'
            if `dv' == `best_df' {
                di as result "  " %2.0f `dv' "  |  " %10.3f `cv' ///
                    "  <-- best"
            }
            else {
                di as text   "  " %2.0f `dv' "  |  " %10.3f `cv'
            }
            local idx = `idx' + 2
        }

        local df_selected = `best_df'
        di as text " Best df = " as result `df_selected' ///
           as text "  (`crit_upper' = " as result %10.3f `best_crit' ")"
    }
    else {
        local df_selected = `df'
    }

    * ============================================================
    * STEP 2: Generate final spline basis
    * ============================================================
    local nk_f = `df_selected' + 1
    if `nk_f' < 3 local nk_f = 3
    if `nk_f' > 7 local nk_f = 7
    local nb_f = `nk_f' - 1

    capture drop _ms_b_*
    quietly mkspline _ms_b_ = `xvar' if `touse', cubic nknots(`nk_f')
    local basis_vars ""
    forvalues j = 1/`nb_f' {
        capture confirm variable _ms_b_`j'
        if !_rc local basis_vars `basis_vars' _ms_b_`j'
    }
    if "`basis_vars'" == "" {
        di as error "Basis generation failed. Check df(`df_selected')."
        exit 498
    }

    * ============================================================
    * STEP 3: Fit main model
    * Supports: OLS, LMM (single/nested/cross-classified),
    *           GLMM (binary: melogit/meprobit),
    *           random spline slopes
    * ============================================================
    di _newline as text "--- Fitting model (df=`df_selected', nknots=`nk_f') ---"

    if `is_ols' & !`is_binary' {
        * Single-level Gaussian
        regress `yvar' `basis_vars' `controls' if `touse'
        local model_type "OLS"
    }
    else if `is_binary' {
        * Binary outcome: melogit or meprobit
        if "`cl1'" == "" {
            * Single-level binary
            if "`family'" == "logit" {
                logit `yvar' `basis_vars' `controls' if `touse'
            }
            else {
                probit `yvar' `basis_vars' `controls' if `touse'
            }
            local model_type "Logit"
        }
        else if `n_cluster' == 1 {
            if "`family'" == "logit" {
                melogit `yvar' `basis_vars' `controls' if `touse' || `cl1':
            }
            else {
                meprobit `yvar' `basis_vars' `controls' if `touse' || `cl1':
            }
            if "`family'"=="logit" local model_type "GLMM-Logit"
            else local model_type "GLMM-Probit"
        }
        else {
            if "`nested'" != "" {
                if "`family'" == "logit" {
                    melogit `yvar' `basis_vars' `controls' if `touse' ///
                        || `cl1': || `cl2':
                }
                else {
                    meprobit `yvar' `basis_vars' `controls' if `touse' ///
                        || `cl1': || `cl2':
                }
                if "`family'" == "logit" local model_type "GLMM-Nested-Logit"
                local model_type "GLMM-Nested-Probit"
            }
            else {
                if "`family'" == "logit" {
                    melogit `yvar' `basis_vars' `controls' if `touse' ///
                        || `cl1': || `cl2':
                }
                else {
                    meprobit `yvar' `basis_vars' `controls' if `touse' ///
                        || `cl1': || `cl2':
                }
                if "`family'" == "logit" local model_type "GLMM-Cross-Logit"
                else local model_type "GLMM-Cross-Probit"
            }
        }
    }
    else if `n_cluster' == 1 {
        * Gaussian multilevel - with or without random spline slopes
        if "`randslope'" != "" {
            di as text " (fitting random spline slopes - may be slow)"
            mixed `yvar' `basis_vars' `controls' if `touse' ///
                || `cl1': `basis_vars', covariance(independent)
            local model_type "LMM-rslope"
        }
        else {
            mixed `yvar' `basis_vars' `controls' if `touse' || `cl1':
            local model_type "LMM"
        }
    }
    else {
        * Two-cluster Gaussian
        if "`nested'" != "" {
            if "`randslope'" != "" {
                mixed `yvar' `basis_vars' `controls' if `touse' ///
                    || `cl1': `basis_vars', covariance(independent) ///
                    || `cl2':
                local model_type "LMM-nested-rslope"
            }
            else {
                mixed `yvar' `basis_vars' `controls' if `touse' ///
                    || `cl1': || `cl2':
                local model_type "LMM-nested"
            }
        }
        else {
            mixed `yvar' `basis_vars' `controls' if `touse' ///
                || _all: R.`cl1' || `cl2':
            local model_type "LMM-cross"
        }
    }

    estimates store _ms_spline
    local n_obs = e(N)

    * AIC/BIC: regress uses RSS; mixed/melogit/meprobit use e(ll)
    if `is_ols' & !`is_binary' {
        local rss_f  = e(rss)
        local k_f    = e(df_m) + 1
        local ll_sp  = -`n_obs'/2*(1 + ln(2*_pi) + ln(`rss_f'/`n_obs'))
    }
    else {
        local ll_sp = e(ll)
        if `is_binary' & "`cl1'" == "" {
            local k_f = e(df_m) + 1
        }
        else {
            local k_f = e(k)
        }
    }
    local aic_sp = -2*`ll_sp' + 2*`k_f'
    local bic_sp = -2*`ll_sp' + ln(`n_obs')*`k_f'

    di as text " Model: " as result "`model_type'" ///
       as text "  N="    as result `n_obs' ///
       as text "  df="   as result `df_selected' ///
       as text "  AIC="  as result %9.2f `aic_sp'

    *        Model summary block                                                                                                                   
    di _newline as text "{hline 65}"
    di as text " Model Summary"
    di as text "{hline 65}"
    di as text "  Model type   : " as result "`model_type'"
    if "`df'" == "auto" {
        di as text "  Spline df    : " as result `df_selected' ///
           as text " (auto-selected by `crit_upper')"
    }
    else {
        di as text "  Spline df    : " as result `df_selected' ///
           as text " (user-specified)"
    }
    di as text "  Spline basis : " as result "`method'"
    di as text "  Observations : " as result `n_obs'
    if "`cl1'" != "" {
        quietly levelsof `cl1' if `touse', local(_ms_cls)
        local _n_cl : word count `_ms_cls'
        di as text "  Clusters     : " as result `_n_cl' ///
           as text " (`cl1')"
        if `n_cluster' == 2 {
            quietly levelsof `cl2' if `touse', local(_ms_cls2)
            local _n_cl2 : word count `_ms_cls2'
            di as text "  Level 2      : " as result `_n_cl2' ///
               as text " (`cl2')"
        }
    }
    di as text "  AIC          : " as result %9.3f `aic_sp'
    di as text "  BIC          : " as result %9.3f `bic_sp'
    if `is_ols' & !`is_binary' {
        di as text "  Tip          : use compare() to test spline vs linear"
    }
    * Warn about near-zero random intercept variance
    if !`is_ols' & !`is_binary' {
        capture {
            local _var_ri = exp(2*[lns1_1_1]_cons)^2
            if `_var_ri' < 0.001 {
                di as text "  Note         : Random intercept variance ~0 -- cluster"
                di as text "                 structure adds negligible variation here."
                di as text "                 Single-level model may be sufficient."
            }
        }
    }
    if `is_binary' & "`cl1'" != "" {
        capture {
            local _var_ri = [student_id]_cons
            if missing(`_var_ri') {
                * melogit stores differently - check via LR test p
            }
        }
        * Check if random intercept variance is negligible in GLMM
        * (Stata's LR p > 0.10 is a reasonable signal)
        capture {
            local _lr_p = e(chi2_c)
            if `_lr_p' > 0.10 | missing(`_lr_p') {
                di as text "  Note         : LR test (cluster vs no cluster) not significant."
                di as text "                 Single-level logit may be sufficient."
            }
        }
    }
    di as text "{hline 65}" _newline

    * ============================================================
    * STEP 4: Model comparison
    * ============================================================
    if "`compare'" != "" {
        di _newline as text "{hline 65}"
        di as text " Model Comparison"
        di as text "{hline 65}"
        di as text "  LRT p-values are vs the linear baseline"
        di as text "  Model              AIC        BIC      LogLik   LRT_p"
        di as text "  {hline 60}"

        * --- Linear baseline ---
        quietly {
            if `is_ols' & !`is_binary' {
                regress `yvar' `xvar' `controls' if `touse'
            }
            else if `is_binary' {
                if "`cl1'" == "" {
                    if "`family'" == "logit" capture logit `yvar' `xvar' `controls' if `touse'
                    else                     capture probit `yvar' `xvar' `controls' if `touse'
                }
                else if `n_cluster' == 1 {
                    if "`family'" == "logit" capture melogit `yvar' `xvar' `controls' if `touse' || `cl1':
                    else                     capture meprobit `yvar' `xvar' `controls' if `touse' || `cl1':
                }
                else {
                    if "`family'" == "logit" capture melogit `yvar' `xvar' `controls' if `touse' || `cl1': || `cl2':
                    else                     capture meprobit `yvar' `xvar' `controls' if `touse' || `cl1': || `cl2':
                }
            }
            else if `n_cluster' == 1 {
                mixed `yvar' `xvar' `controls' if `touse' || `cl1':
            }
            else {
                if "`nested'" != "" {
                    mixed `yvar' `xvar' `controls' if `touse' ///
                        || `cl1': || `cl2':
                }
                else {
                    mixed `yvar' `xvar' `controls' if `touse' ///
                        || _all: R.`cl1' || `cl2':
                }
            }
        }
        if `is_ols' & !`is_binary' {
            local k_lin   = e(df_m) + 1
            local ll_lin  = -e(N)/2*(1+ln(2*_pi)+ln(e(rss)/e(N)))
        }
        else if `is_binary' & "`cl1'" == "" {
            local k_lin  = e(df_m) + 1
            local ll_lin = e(ll)
        }
        else {
            local k_lin  = e(k)
            local ll_lin = e(ll)
        }
        local aic_lin = -2*`ll_lin' + 2*`k_lin'
        local bic_lin = -2*`ll_lin' + ln(`n_obs')*`k_lin'
        di as text "  " as result "Linear         " ///
           as result %9.2f `aic_lin' "  " %9.2f `bic_lin' ///
           "  " %9.2f `ll_lin' "     --"

        * --- Polynomial comparators ---
        foreach deg of local poly_degrees {
            capture drop _ms_p_*
            local pvars "`xvar'"
            forvalues p = 2/`deg' {
                quietly generate double _ms_p_`p' = `xvar'^`p' if `touse'
                local pvars "`pvars' _ms_p_`p'"
            }
            quietly {
                if `is_ols' & !`is_binary' {
                    capture regress `yvar' `pvars' `controls' if `touse'
                }
                else if `is_binary' {
                    if "`cl1'" == "" {
                        if "`family'" == "logit" capture logit `yvar' `pvars' `controls' if `touse'
                        else                     capture probit `yvar' `pvars' `controls' if `touse'
                    }
                    else if `n_cluster' == 1 {
                        if "`family'" == "logit" capture melogit `yvar' `pvars' `controls' if `touse' || `cl1':
                        else                     capture meprobit `yvar' `pvars' `controls' if `touse' || `cl1':
                    }
                    else {
                        if "`family'" == "logit" capture melogit `yvar' `pvars' `controls' if `touse' || `cl1': || `cl2':
                        else                     capture meprobit `yvar' `pvars' `controls' if `touse' || `cl1': || `cl2':
                    }
                }
                else if `n_cluster' == 1 {
                    capture mixed `yvar' `pvars' `controls' ///
                        if `touse' || `cl1':
                }
                else {
                    if "`nested'" != "" {
                        capture mixed `yvar' `pvars' `controls' ///
                            if `touse' || `cl1': || `cl2':
                    }
                    else {
                        capture mixed `yvar' `pvars' `controls' ///
                            if `touse' || _all: R.`cl1' || `cl2':
                    }
                }
            }
            if _rc == 0 {
                if `is_ols' & !`is_binary' {
                    local k_p  = e(df_m) + 1
                    local ll_p = -e(N)/2*(1+ln(2*_pi)+ln(e(rss)/e(N)))
                }
                else if `is_binary' & "`cl1'" == "" {
                    local k_p  = e(df_m) + 1
                    local ll_p = e(ll)
                }
                else {
                    local k_p  = e(k)
                    local ll_p = e(ll)
                }
                if !missing(`ll_p') {
                    local aic_p = -2*`ll_p' + 2*`k_p'
                    local bic_p = -2*`ll_p' + ln(`n_obs')*`k_p'
                    local lrt   = 2*(`ll_p' - `ll_lin')
                    local ldf   = `k_p' - `k_lin'
                    if `ldf' > 0 {
                        local lrtp = string(chi2tail(`ldf',`lrt'),"%6.4f")
                        if chi2tail(`ldf',`lrt') < 0.001 local lrtp "<0.001"
                    }
                    else local lrtp "n/a"
                    di as text "  " as result "Poly(`deg')        " ///
                       as result %9.2f `aic_p' "  " %9.2f `bic_p' ///
                       "  " %9.2f `ll_p' "  " as result "`lrtp'"
                }
            }
            capture drop _ms_p_*
        }

        * --- Spline row ---
        local lrt_s = 2*(`ll_sp' - `ll_lin')
        local ldf_s = `k_f' - `k_lin'
        if `ldf_s' > 0 {
            local lrtp_s = string(chi2tail(`ldf_s',`lrt_s'),"%6.4f")
            if chi2tail(`ldf_s',`lrt_s') < 0.001 local lrtp_s "<0.001"
        }
        else local lrtp_s "n/a"
        di as text "  " as result "Spline(df=`df_selected')  " ///
           as result %9.2f `aic_sp' "  " %9.2f `bic_sp' ///
           "  " %9.2f `ll_sp' "  " as result "`lrtp_s'"
        di as text "  {hline 60}"
        di as text "{hline 65}" _newline
        quietly estimates restore _ms_spline
    }

    * ============================================================
    * STEP 5: R-squared
    * ============================================================
    if "`r2'" != "" {
        di _newline as text "{hline 50}"
        di as text " R-squared Decomposition"
        di as text "{hline 50}"
        if `is_ols' & !`is_binary' {
            di as text "  R-squared     = " as result %6.4f e(r2)
            di as text "  Adj R-squared = " as result %6.4f e(r2_a)
        }
        else {
            * Nakagawa-Schielzeth R2m/R2c
            * For GLMM: add distribution-specific variance to denominator
            * logit: pi^2/3;  probit: 1;  gaussian: 0
            if `is_binary' {
                if "`family'" == "logit"  local var_dist = (_pi^2)/3
                else                       local var_dist = 1
                * For GLMM, predict the linear predictor on original data
                capture {
                    tempvar xb_fe2
                    * melogit/meprobit store estimates differently
                    * use manual coefficient approach
                    quietly generate double `xb_fe2' = _b[_cons] if e(sample)
                    forvalues j = 1/`nb_f' {
                        quietly replace `xb_fe2' = `xb_fe2' + ///
                            _b[_ms_b_`j'] * _ms_b_`j' if e(sample)
                    }
                    foreach cv of local controls {
                        quietly capture replace `xb_fe2' = `xb_fe2' + ///
                            _b[`cv'] * `cv' if e(sample)
                    }
                    quietly summarize `xb_fe2' if e(sample)
                    local var_fe = r(Var)
                }
                if _rc local var_fe = 0
            }
            else {
                tempvar xb_fe
                capture quietly predict double `xb_fe' if e(sample), xb
                if _rc {
                    quietly generate double `xb_fe' = _b[_cons] if e(sample)
                    forvalues j = 1/`nb_f' {
                        quietly replace `xb_fe' = `xb_fe' + ///
                            _b[_ms_b_`j'] * _ms_b_`j' if e(sample)
                    }
                }
                quietly summarize `xb_fe' if e(sample)
                local var_fe = r(Var)
                local var_dist = 0
            }
            capture local var_re = exp(2*[lns1_1_1]_cons)^2
            if _rc local var_re = 0
            if !`is_binary' {
                capture local var_res = exp(2*[lnsig_e]_cons)^2
                if _rc {
                    quietly summarize `yvar' if e(sample)
                    local var_res = r(Var) - `var_fe' - `var_re'
                }
            }
            else {
                local var_res = 0
            }
            if `var_res' < 0 local var_res = 0
            local tv = `var_fe' + `var_re' + `var_res' + `var_dist'
            if `tv' > 0 {
                di as text "  Marginal  R2m  = " ///
                   as result %6.4f `var_fe'/`tv' ///
                   as text "  (fixed effects)"
                di as text "  Conditional R2c = " ///
                   as result %6.4f (`var_fe'+`var_re')/`tv' ///
                   as text "  (fixed + random)"
                if `is_binary' {
                    di as text "  (Distribution variance = " ///
                       as result %6.4f `var_dist' ///
                       as text " included in denominator)"
                }
            }
        }
        di as text "{hline 50}" _newline
    }

    * ============================================================
    * STEP 6: ICC
    * ============================================================
    if "`icc'" != "" & !`is_ols' {
        di _newline as text "{hline 40}"
        di as text " Intraclass Correlation (ICC)"
        di as text "{hline 40}"
        capture {
            local var_re  = exp(2*[lns1_1_1]_cons)^2
            local var_res = exp(2*[lnsig_e]_cons)^2
            local tot     = `var_re' + `var_res'
            if `tot' > 0 {
                local icc_val = `var_re' / `tot'
                di as text "  ICC(`cl1')  = " ///
                   as result %6.4f `icc_val' ///
                   as text "  (between-cluster variance fraction)"
                di as text "  Residual    = " ///
                   as result %6.4f 1 - `icc_val' ///
                   as text "  (within-cluster variance fraction)"
                * Interpret ICC
                if `icc_val' >= 0.10 {
                    di as text "  Multilevel structure is important (ICC >= 0.10)"
                }
                else {
                    di as text "  Weak clustering effect (ICC < 0.10)"
                }
            }
        }
        if _rc {
            di as text "  ICC: variance components not extractable for"
            di as text "       this model type (GLMM or complex RE structure)"
        }
        di as text "{hline 40}" _newline
    }

    * ============================================================
    * STEP 6b: Cluster heterogeneity (nl_het equivalent)
    * - Fits random-slope model if not already fitted with random_slope
    * - LRT: random slopes vs random intercepts
    * - Plots BLUP-based individual trajectories vs population mean
    * ============================================================
    if "`het'" != "" & !`is_ols' & !`is_binary' & `n_cluster' == 1 {
        di _newline as text "{hline 65}"
        di as text " Cluster Heterogeneity in Nonlinear Effect"
        di as text "{hline 65}"

        * Step A: Fit random-slope model for LRT
        di as text " Fitting random-slope model for LRT..."
        quietly estimates restore _ms_spline
        quietly capture mixed `yvar' `basis_vars' `controls' if `touse' ///
            || `cl1': `basis_vars', covariance(independent)

        if _rc == 0 {
            estimates store _ms_rs

            * LRT: random slopes vs random intercepts
            di _newline as text " LRT: random slopes vs random intercepts"
            di as text " {hline 50}"
            quietly estimates restore _ms_spline
            local ll_ri = e(ll)
            local k_ri  = e(k)
            quietly estimates restore _ms_rs
            local ll_rs = e(ll)
            local k_rs  = e(k)
            local lrt_het   = 2*(`ll_rs' - `ll_ri')
            local lrt_df_h  = `k_rs' - `k_ri'
            * Handle boundary case: LRT stat can be negative due to
            * numerical precision when random slope variances -> 0
            if `lrt_het' < 0 local lrt_het = 0
            if `lrt_df_h' > 0 {
                local lrt_p_h = chi2tail(`lrt_df_h', `lrt_het')
                if `lrt_p_h' < 0.001      local pval_h "<0.001"
                else if `lrt_p_h' < 0.05  local pval_h = string(`lrt_p_h', "%6.4f")
                else                       local pval_h = string(`lrt_p_h', "%6.4f")
            }
            else {
                local lrt_p_h = 1
                local pval_h  = "n/a"
            }
            * Flag boundary case
            local boundary_note ""
            if `lrt_het' == 0 {
                local boundary_note " (boundary: random slope variances ~0)"
            }
            di as text "  LRT chi2(`lrt_df_h') = " ///
               as result %5.2f `lrt_het' ///
               as text ",  p = " as result "`pval_h'"
            if "`boundary_note'" != "" {
                di as text "  Note: `boundary_note'"
                di as text "        The nonlinear trajectory is stable across clusters."
            }
            else if `lrt_p_h' < 0.05 {
                di as result ///
                    "  Conclusion: Trajectory shape varies significantly across clusters"
                di as text ///
                    "             (consider random spline slopes: add randslope option)"
            }
            else {
                di as text ///
                    "  Conclusion: No significant variation in trajectory shape across clusters"
            }
            capture estimates drop _ms_rs
        }
        else {
            di as text "  (Random-slope model did not converge - LRT skipped)"
        }

        * Step B: BLUP trajectories plot
        * Strategy: single preserve block, all in memory, no file saves
        di _newline as text " Plotting BLUP trajectories (`nhet' clusters)..."
        quietly estimates restore _ms_spline

        preserve
        quietly keep if `touse'

        * Get BLUP fitted values on original data
        quietly {
            tempvar blup_fit
            estimates restore _ms_spline
            predict double `blup_fit', fitted

            * Get x range and select cluster sample
            summarize `xvar'
            local xmn = r(min)
            local xmx = r(max)

            quietly levelsof `cl1', local(all_cls)
            local n_all : word count `all_cls'
        }

        * Select nhet clusters evenly spaced
        if `n_all' > `nhet' {
            local step = max(1, floor(`n_all' / `nhet'))
            local sel_cls ""
            local cnt = 0
            foreach c of local all_cls {
                local ++cnt
                if mod(`cnt', `step') == 1 {
                    local sel_cls `sel_cls' `c'
                    if `: word count `sel_cls'' >= `nhet' continue, break
                }
            }
        }
        else {
            local sel_cls `all_cls'
        }

        * Create named variables for each cluster (avoid tempvar in loop)
        local het_plots ""
        local cnum = 0
        foreach c of local sel_cls {
            local ++cnum
            capture drop _ms_hc_`cnum'
            quietly generate double _ms_hc_`cnum' = `blup_fit' if `cl1' == `c'
            local het_plots `het_plots' ///
                (line _ms_hc_`cnum' `xvar' if `cl1'==`c', ///
                    lcolor(gs12) lwidth(thin) sort)
        }

        * Population mean on same data using fixed effects only
        * Use manual computation to avoid fixedonly issues
        quietly {
            capture drop _ms_pop_fit _ms_pop_lwr _ms_pop_upr
            generate double _ms_pop_fit = _b[_cons]
            forvalues j = 1/`nb_f' {
                replace _ms_pop_fit = _ms_pop_fit + _b[_ms_b_`j'] * _ms_b_`j'
            }
            foreach cv of local controls {
                capture replace _ms_pop_fit = _ms_pop_fit + _b[`cv'] * `cv'
            }
            * Approximate CI using delta method SE if available
            capture predict double _ms_pop_se, stdp
            if _rc generate double _ms_pop_se = 0
            local z2 = invnormal(1-(100-`level')/200)
            generate double _ms_pop_lwr = _ms_pop_fit - `z2'*_ms_pop_se
            generate double _ms_pop_upr = _ms_pop_fit + `z2'*_ms_pop_se
        }

        * Draw the combined plot
        twoway ///
            `het_plots' ///
            (rarea _ms_pop_lwr _ms_pop_upr `xvar', ///
                color(navy) fintensity(15)) ///
            (line _ms_pop_fit `xvar', ///
                lcolor(navy) lwidth(thick) sort), ///
            legend(order(`=`cnum'+2' "Population mean" ///
                         `=`cnum'+1' "`level'% CI") ///
                   ring(0) position(1) cols(1)) ///
            xtitle("`xvar'") ytitle("`yvar'") ///
            title("Cluster heterogeneity (`nhet' clusters)") ///
            note("Blue = population mean | Grey lines = cluster BLUPs")

        capture drop _ms_hc_* _ms_pop_*
        restore

        di as text "{hline 65}" _newline
    }


    if `predict_grid' > 1 {
        local z = invnormal(1 - (100-`level')/200)
        quietly summarize `xvar' if `touse'
        local xmin  = r(min)
        local xmax  = r(max)
        local xstep = (`xmax' - `xmin') / (`predict_grid' - 1)

        di _newline as text ///
           "--- Prediction grid (`predict_grid' points, `level'% CI) ---"

        preserve

        quietly {
            keep if `touse'
            foreach cv of local controls {
                summarize `cv'
                local cmean_`cv' = r(mean)
            }
            clear
            set obs `predict_grid'
            generate double `xvar' = `xmin' + (_n-1)*`xstep'
            foreach cv of local controls {
                generate double `cv' = `cmean_`cv''
            }

            capture drop _ms_b_*
            mkspline _ms_b_ = `xvar', cubic nknots(`nk_f')

            estimates restore _ms_spline
            if `is_ols' & !`is_binary' {
                * OLS: standard prediction
                predict double fit,    xb
                predict double se_fit, stdp
            }
            else if `is_binary' {
                * Binary: compute linear predictor manually from coefficients
                * (predict,xb fails for melogit/meprobit on cleared dataset
                *  because it looks for the outcome variable)
                generate double fit_link = _b[_cons]
                forvalues j = 1/`nb_f' {
                    replace fit_link = fit_link + _b[_ms_b_`j'] * _ms_b_`j'
                }
                foreach cv of local controls {
                    capture replace fit_link = fit_link + _b[`cv'] * `cv'
                }
                * SE: try stdp, fall back to zero (wide CI)
                capture predict double se_fit, stdp
                if _rc generate double se_fit = 0
                * Transform to probability scale with delta-method CI
                if "`family'" == "logit" {
                    generate double fit = invlogit(fit_link)
                    generate double lwr = invlogit(fit_link - `z'*se_fit)
                    generate double upr = invlogit(fit_link + `z'*se_fit)
                }
                else {
                    generate double fit = normal(fit_link)
                    generate double lwr = normal(fit_link - `z'*se_fit)
                    generate double upr = normal(fit_link + `z'*se_fit)
                }
                drop fit_link se_fit
            }
            else {
                * LMM (including random slopes): prediction grid is new data
                * (created with clear + set obs), so no cluster variable exists.
                * predict,xb on out-of-sample obs = fixed effects only.
                * Do NOT use fixedonly as it fails for some random-slope specs.
                capture predict double fit, xb fixedonly
                if _rc {
                    * Fallback: compute fixed-effects prediction from coefficients
                    generate double fit = _b[_cons]
                    forvalues j = 1/`nb_f' {
                        replace fit = fit + _b[_ms_b_`j'] * _ms_b_`j'
                    }
                    foreach cv of local controls {
                        capture replace fit = fit + _b[`cv'] * `cv'
                    }
                }
                capture predict double se_fit, stdp
                if _rc generate double se_fit = .
            }
            if !`is_binary' {
                generate double lwr = fit - `z'*se_fit
                generate double upr = fit + `z'*se_fit
            }

            * Derivatives
            if "`derivatives'" != "" {
                sort `xvar'
                local np = _N
                generate double d1    = .
                generate double d1_se = .
                generate double d2    = .
                forvalues i = 2/`=`np'-1' {
                    local dx = `xvar'[`i'+1] - `xvar'[`i'-1]
                    if `dx' > 0 {
                        replace d1 = (fit[`i'+1]-fit[`i'-1])/`dx' in `i'
                        replace d1_se = sqrt(se_fit[`i'+1]^2 + ///
                            se_fit[`i'-1]^2)/`dx' in `i'
                    }
                }
                local dxf = `xvar'[2]     - `xvar'[1]
                local dxb = `xvar'[`np']  - `xvar'[`np'-1]
                if `dxf' > 0 replace d1 = (fit[2]-fit[1])/`dxf' in 1
                if `dxb' > 0 ///
                    replace d1 = (fit[`np']-fit[`np'-1])/`dxb' in `np'
                forvalues i = 2/`=`np'-1' {
                    local dx = `xvar'[`i'+1] - `xvar'[`i'-1]
                    if `dx' > 0 {
                        replace d2 = (d1[`i'+1]-d1[`i'-1])/`dx' in `i'
                    }
                }
                generate double d1_lwr = d1 - `z'*d1_se
                generate double d1_upr = d1 + `z'*d1_se
            }
            capture drop _ms_b_*
        }

        * Display prediction head - auto-scale format
        quietly summarize fit
        local fit_max = abs(r(max))
        if `fit_max' >= 1000      local pfmt "%10.2f"
        else if `fit_max' >= 10   local pfmt "%9.3f"
        else if `fit_max' >= 0.1  local pfmt "%9.4f"
        else                      local pfmt "%10.5f"

        di as text "  " %8s "`xvar'" ///
           "         fit          lwr          upr"
        di as text "  {hline 55}"
        forvalues i = 1/5 {
            di as text "  " as result %8.3f `xvar'[`i'] ///
               "  " `pfmt' fit[`i'] ///
               "  " `pfmt' lwr[`i'] ///
               "  " `pfmt' upr[`i']
        }
        di as text "  ... (`predict_grid' rows, `level'% CI)"

        if "`derivatives'" != "" {
            di _newline as text "--- Derivatives (first 5 rows) ---"
            di as text "  " %8s "`xvar'" ///
               "        d1     d1_lwr     d1_upr         d2"
            di as text "  {hline 58}"
            forvalues i = 1/5 {
                di as text "  " as result %8.3f `xvar'[`i'] ///
                   "  " %9.4f d1[`i'] ///
                   "  " %9.4f d1_lwr[`i'] ///
                   "  " %9.4f d1_upr[`i'] ///
                   "  " %9.4f d2[`i']
            }
            di as text "  Note: d2 CIs may be wide (numerical differentiation)"
        }

        if "`turning_points'" != "" {
            di _newline as text "--- Turning points ---"
            local np   = _N
            local tp_n = 0
            forvalues i = 2/`np' {
                if !missing(d1[`i'-1]) & !missing(d1[`i']) {
                    if sign(d1[`i'-1]) != sign(d1[`i']) {
                        local ++tp_n
                        local den = d1[`i'] - d1[`i'-1]
                        if abs(`den') > 1e-12 {
                            local xcr = `xvar'[`i'-1] - d1[`i'-1] * ///
                                (`xvar'[`i']-`xvar'[`i'-1])/`den'
                        }
                        else {
                            local xcr = (`xvar'[`i'-1]+`xvar'[`i'])/2
                        }
                        if !missing(d2[`i'-1]) & d2[`i'-1] < 0 ///
                            local ttype "maximum"
                        else local ttype "minimum"
                        di as text "  TP `tp_n': " as result ///
                           "`xvar' = " %7.3f `xcr' ///
                           as text "  (" as result "`ttype'" as text ")"
                    }
                }
            }
            if `tp_n' == 0 di as text "  No turning points detected"
        }

        * ---- Inline plots (generated before restore - no file needed) ----
        if "`plot'" != "" {
            if !inlist("`plot'","trajectory","slope","curvature","combo") {
                di as error "plot() must be: trajectory  slope  curvature  combo"
            }
            else {
                local cilabel "`level'% CI"

                * Build trajectory graph
                if inlist("`plot'","trajectory","combo") {
                    tempfile traj_g
                    quietly twoway ///
                        (rarea lwr upr `xvar', color(navy) fintensity(20)) ///
                        (line fit `xvar', lcolor(navy) lwidth(medthick)), ///
                        legend(off) ///
                        xtitle("`xvar'") ytitle("Predicted `yvar'") ///
                        title("Trajectory: `yvar' ~ `xvar'") ///
                        note("`cilabel'") ///
                        saving(`"`traj_g'"', replace) nodraw
                }

                * Build slope graph
                if inlist("`plot'","slope","combo") {
                    capture confirm variable d1
                    if _rc == 0 {
                        tempfile slope_g
                        quietly twoway ///
                            (rarea d1_lwr d1_upr `xvar', ///
                                color(maroon) fintensity(20)) ///
                            (line d1 `xvar', ///
                                lcolor(maroon) lwidth(medthick)) ///
                            (function y=0, range(`xvar') ///
                                lcolor(gs8) lpattern(dash)), ///
                            legend(off) ///
                            xtitle("`xvar'") ytitle("dy/d(`xvar')") ///
                            title("Marginal effect of `xvar'") ///
                            note("`cilabel' | dashed = zero") ///
                            saving(`"`slope_g'"', replace) nodraw
                    }
                    else {
                        di as error " plot(slope/combo): add -derivatives- option"
                    }
                }

                * Display
                if "`plot'" == "trajectory" {
                    graph use `"`traj_g'"'
                }
                else if "`plot'" == "slope" {
                    capture graph use `"`slope_g'"'
                }
                else if "`plot'" == "curvature" {
                    capture confirm variable d2
                    if _rc == 0 {
                        twoway ///
                            (line d2 `xvar', ///
                                lcolor(forest_green) lwidth(medthick)) ///
                            (function y=0, range(`xvar') ///
                                lcolor(gs8) lpattern(dash)), ///
                            legend(off) ///
                            xtitle("`xvar'") ytitle("d2y/d(`xvar')^2") ///
                            title("Curvature (second derivative)") ///
                            note("Wide CIs expected with numerical differentiation")
                    }
                    else {
                        di as error " plot(curvature): add -derivatives- option"
                    }
                }
                else if "`plot'" == "combo" {
                    capture confirm variable d1
                    if _rc == 0 {
                        graph combine `"`traj_g'"' `"`slope_g'"', ///
                            cols(2) xsize(14) ///
                            title("MultiSpline: `yvar' ~ `xvar'")
                    }
                    else {
                        graph use `"`traj_g'"'
                    }
                }
            }
        }

        * ---- Optional save to disk ----
        if "`saving'" != "" {
            capture drop _ms_b_*
            capture save `"`saving'"', replace
            if _rc == 0 {
                di _newline as text " Saved: `saving'.dta"
            }
            else {
                di as error " Save failed - machine may restrict file writes."
                di as error " Use plot() option instead to see graphs directly:"
                di as error "   multispline `yvar' `xvar', plot(trajectory)"
                di as error "   multispline `yvar' `xvar', plot(combo)"
            }
        }

        restore
    }

    * ============================================================
    * Return values
    * ============================================================
    capture drop _ms_b_* _ms_p_*
    ereturn local  cmd        "multispline"
    ereturn local  yvar       "`yvar'"
    ereturn local  xvar       "`xvar'"
    ereturn local  method     "`method'"
    ereturn local  model_type "`model_type'"
    ereturn scalar df         = `df_selected'
    ereturn scalar aic        = `aic_sp'
    ereturn scalar bic        = `bic_sp'

    di _newline as text "{hline 65}"
    di as text " Plots:  multispline ... , plot(trajectory)"
    di as text "         multispline ... , plot(slope)"
    di as text "         multispline ... , plot(combo)"
    if "`saving'" != "" {
        di as text " Or:     multispline_plot, using(`saving') type(trajectory) xvar(`xvar')"
    }
    di as text "{hline 65}" _newline

end
