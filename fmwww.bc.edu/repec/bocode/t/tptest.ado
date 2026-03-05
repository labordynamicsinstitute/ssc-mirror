*! tptest v1.0.1  04mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Universal Turning Point & Inflection Point Test
*! Post-estimation command for U-shape / inverse U-shape testing
*! with Delta-method SEs, Fieller CIs, and publication-quality graphs
*!
*! Extends Lind & Mehlum (2010) to:
*!   - Quadratic, Cubic, Log-quadratic, Inverse, Polynomial forms
*!   - Inflection point calculation (cubic, polynomial)
*!   - Delta-method standard errors & confidence intervals
*!   - Auto-detection of 20+ Stata estimators
*!   - Multi-quantile turning point trajectories
*!   - Beautiful publication-quality visualizations
*!
*! Supported estimators:
*!   Cross-section: regress, ardl, aardl, fbardl, fbnardl, mtnardl,
*!                  tnardl, qardl, fqardl, qreg, ivregress
*!   Panel:         xtreg, xtpmg, pnardl, xtpqardl, xtdcce2, xtcce,
*!                  xtcspqardl, xtqreg, xtqsh, xtmdqr
*!   Quantile:      qreg, sqreg, bsqreg, mmqreg, rifhdreg
*!
*! References:
*!   Lind & Mehlum (2010), Oxford Bulletin of Economics and Statistics
*!   Fieller (1954), JRSS Series B
*!   Sasabuchi (1980), Annals of Statistics

capture program drop tptest
program define tptest, rclass sortpreserve
    version 14.0

    // =====================================================================
    // 1. SYNTAX PARSING
    // =====================================================================
    syntax varlist(min=2 max=3 numeric) [, ///
        MINimum(real -9999.12345)         /// lower bound of interval
        MAXimum(real  9999.12345)         /// upper bound of interval
        Quadratic                         /// force quadratic specification
        Cubic                             /// force cubic specification
        Inverse                           /// force inverse specification
        LOGQuadratic                      /// force log-quadratic
        Polynomial                        /// general polynomial detection
        INFlection                        /// compute inflection point (cubic/poly)
        FIELler                           /// include Fieller interval
        DELTA                             /// delta-method SE and CI
        TWOlines                          /// Simonsohn (2018) two-lines test
        BOOTstrap                         /// parametric bootstrap CI
        BREPS(integer 1000)               /// bootstrap replications
        Level(cilevel)                    /// confidence level
        PREfix(string)                    /// equation prefix for multi-eq models
        EQ(string)                        /// equation name: LR, SR, ECT
        TAU(numlist >0 <1 sort)           /// quantile(s) for quantile estimators
        GRaph                             /// produce visualization
        GRAPHOpt(string asis)             /// pass-through graph options
        NOGRaph                           /// suppress auto-graph
        SAVing(string)                    /// save graph to file
        TItle(string asis)                /// custom graph title
        ]

    // =====================================================================
    // 2. PARSE VARIABLES
    // =====================================================================
    tokenize `varlist'
    local nvar : word count `varlist'
    local var1 "`1'"       // x (linear term)
    local var2 "`2'"       // x^2  or  1/x  or  [ln(x)]^2

    if `nvar' == 3 {
        local var3 "`3'"   // x^3 (cubic term)
    }

    // =====================================================================
    // 3. AUTO-DETECT ESTIMATOR & SET EQUATION PREFIX
    // =====================================================================
    local cmd = "`e(cmd)'"
    if "`cmd'" == "" {
        di as err "no estimation results found — run an estimation command first"
        exit 301
    }

    // Auto-detect prefix for multi-equation models
    if "`prefix'" == "" & "`eq'" == "" {
        _tptest_autoprefix "`cmd'"
        local prefix "`r(prefix)'"
        local est_type "`r(est_type)'"
        local is_quantile = r(is_quantile)
    }
    else if "`eq'" != "" {
        // User specified equation name
        local prefix "`eq':"
        local est_type "user"
        local is_quantile = 0
    }
    else {
        if "`prefix'" != "" & substr("`prefix'", -1, .) != ":" {
            local prefix "`prefix':"
        }
        local est_type "user"
        local is_quantile = 0
    }

    // =====================================================================
    // 4. AUTO-DETECT FUNCTIONAL FORM
    // =====================================================================
    local nforms = ("`quadratic'" != "") + ("`cubic'" != "") + ///
                   ("`inverse'" != "") + ("`logquadratic'" != "") + ///
                   ("`polynomial'" != "")

    if `nforms' > 1 {
        di as err "specify at most one of: quadratic, cubic, inverse, logquadratic, polynomial"
        exit 198
    }

    if `nforms' == 0 {
        // Auto-detect
        if `nvar' == 3 {
            local model "cubic"
        }
        else {
            // Same logic as utest: check correlation with x^2 vs 1/x
            preserve
            tempvar xsq xinv
            qui gen double `xsq' = (`var1')^2
            qui gen double `xinv' = 1/(`var1') if `var1' != 0
            qui corr `xsq' `var2'
            local quad_corr = abs(r(rho))
            qui corr `xinv' `var2'
            local inv_corr = abs(r(rho))
            restore

            if `quad_corr' > `inv_corr' {
                local model "quad"
            }
            else {
                local model "inv"
            }
        }
    }
    else {
        if "`quadratic'" != ""    local model "quad"
        if "`cubic'" != ""        local model "cubic"
        if "`inverse'" != ""      local model "inv"
        if "`logquadratic'" != "" local model "logquad"
        if "`polynomial'" != ""   local model "poly"
    }

    // For cubic, need 3 variables
    if "`model'" == "cubic" & `nvar' != 3 {
        di as err "cubic specification requires 3 variables: x x² x³"
        exit 198
    }

    // =====================================================================
    // 5. HANDLE QUANTILE ESTIMATORS — LOOP OVER TAU
    // =====================================================================
    if "`tau'" != "" {
        // Multi-quantile mode: loop and collect results
        local _qlopts "tau(`tau') model(`model') cmd(`cmd')"
        if "`prefix'" != "" {
            local _qlopts "`_qlopts' prefix(`prefix')"
        }
        local _qlopts "`_qlopts' min(`minimum') max(`maximum')"
        if "`fieller'" != "" local _qlopts "`_qlopts' fieller"
        if "`delta'" != ""  local _qlopts "`_qlopts' delta"
        local _qlopts "`_qlopts' level(`level')"
        if "`graph'" != ""  local _qlopts "`_qlopts' graph"
        if "`nograph'" != "" local _qlopts "`_qlopts' nograph"
        _tptest_quantile_loop `varlist', `_qlopts'
        // Copy returns
        return add
        exit
    }

    // =====================================================================
    // 6. EXTRACT COEFFICIENTS & VARIANCE-COVARIANCE
    // =====================================================================
    local df = e(df_r)
    if `df' == . {
        local df = e(N)
        local use_normal = 1
    }
    else {
        local use_normal = 0
    }

    tempname beta covar
    mat `beta' = e(b)
    mat `covar' = e(V)

    // Extract coefficients with prefix handling
    local v1name "`prefix'`var1'"
    local v2name "`prefix'`var2'"

    capture mat _tpb1 = `beta'[1, "`v1name'"]
    if _rc != 0 {
        // Try without prefix
        capture mat _tpb1 = `beta'[1, "`var1'"]
        if _rc != 0 {
            di as err "coefficient for `v1name' not found in e(b)"
            di as err "  Tip: use prefix() or eq() to specify the equation name"
            di as err "  Variables in e(b): " _c
            mat list `beta', noheader
            exit 111
        }
        local v1name "`var1'"
        local v2name "`var2'"
        if `nvar' == 3 local v3name "`var3'"
    }

    local b1 = _tpb1[1,1]
    mat _tpb2 = `beta'[1, "`v2name'"]
    local b2 = _tpb2[1,1]

    // Variance-covariance elements
    local s11 = `covar'["`v1name'", "`v1name'"]
    local s12 = `covar'["`v1name'", "`v2name'"]
    local s22 = `covar'["`v2name'", "`v2name'"]

    if `nvar' == 3 {
        if "`v3name'" == "" local v3name "`prefix'`var3'"
        capture mat _tpb3 = `beta'[1, "`v3name'"]
        if _rc != 0 {
            local v3name "`var3'"
            mat _tpb3 = `beta'[1, "`v3name'"]
        }
        local b3 = _tpb3[1,1]
        local s13 = `covar'["`v1name'", "`v3name'"]
        local s23 = `covar'["`v2name'", "`v3name'"]
        local s33 = `covar'["`v3name'", "`v3name'"]
    }

    // Clean up temp matrices
    capture mat drop _tpb1
    capture mat drop _tpb2
    capture mat drop _tpb3

    // =====================================================================
    // 7. DATA RANGE (for interval bounds)
    // =====================================================================
    qui su `var1'
    if `minimum' == -9999.12345 {
        local x_min = r(min)
    }
    else {
        local x_min = `minimum'
    }
    if `maximum' == 9999.12345 {
        local x_max = r(max)
    }
    else {
        local x_max = `maximum'
    }

    // =====================================================================
    // 8. COMPUTE TURNING POINT, SLOPES, AND TEST STATISTICS
    // =====================================================================

    // --- QUADRATIC: y = b1*x + b2*x^2 ---
    if "`model'" == "quad" {
        // Turning point: dy/dx = b1 + 2*b2*x = 0  =>  x* = -b1/(2*b2)
        local tp = -(`b1') / (2*(`b2'))

        // Slopes at interval bounds
        local sl_min = `b1' + 2*`b2'*`x_min'
        local sl_max = `b1' + 2*`b2'*`x_max'

        // t-statistics at bounds (Sasabuchi test)
        local t_min = (`b1' + 2*`b2'*`x_min') / ///
            sqrt(`s11' + 4*(`x_min')^2*`s22' + 4*`x_min'*`s12')
        local t_max = (`b1' + 2*`b2'*`x_max') / ///
            sqrt(`s11' + 4*(`x_max')^2*`s22' + 4*`x_max'*`s12')

        // Delta-method SE: x* = -b1/(2*b2)
        // G = (dx*/db1, dx*/db2) = (-1/(2*b2), b1/(2*b2^2))
        local g1 = -1 / (2*`b2')
        local g2 = `b1' / (2*(`b2')^2)
        local tp_var = (`g1')^2*`s11' + 2*`g1'*`g2'*`s12' + (`g2')^2*`s22'
        local tp_se = sqrt(`tp_var')

        local spec_label "y = β₁·x + β₂·x²"
        local spec_short "Quadratic"
    }

    // --- CUBIC: y = b1*x + b2*x^2 + b3*x^3 ---
    else if "`model'" == "cubic" {
        // Turning points: dy/dx = b1 + 2*b2*x + 3*b3*x^2 = 0
        // Solutions via quadratic formula:
        local discrim = 4*(`b2')^2 - 12*`b1'*`b3'

        if `discrim' < 0 {
            di as err "no real turning points exist (discriminant < 0)"
            di as err "  The cubic has no local extrema in the real domain"
            local tp = .
            local tp2 = .
        }
        else {
            local tp  = (-2*`b2' + sqrt(`discrim')) / (6*`b3')
            local tp2 = (-2*`b2' - sqrt(`discrim')) / (6*`b3')

            // Keep the one inside the data range, or the one closer to midpoint
            local xmid = (`x_min' + `x_max') / 2
            if abs(`tp' - `xmid') > abs(`tp2' - `xmid') {
                local tp_swap = `tp'
                local tp = `tp2'
                local tp2 = `tp_swap'
            }
        }

        // Inflection point: d²y/dx² = 2*b2 + 6*b3*x = 0  =>  x_ip = -b2/(3*b3)
        local ip = -`b2' / (3*`b3')

        // Slopes at interval bounds
        local sl_min = `b1' + 2*`b2'*`x_min' + 3*`b3'*(`x_min')^2
        local sl_max = `b1' + 2*`b2'*`x_max' + 3*`b3'*(`x_max')^2

        // t-statistics at bounds
        // Var(slope at x0) = Var(b1) + 4*x0^2*Var(b2) + 9*x0^4*Var(b3)
        //                   + 4*x0*Cov(b1,b2) + 6*x0^2*Cov(b1,b3) + 12*x0^3*Cov(b2,b3)
        local var_sl_min = `s11' + 4*(`x_min')^2*`s22' + 9*(`x_min')^4*`s33' ///
            + 4*`x_min'*`s12' + 6*(`x_min')^2*`s13' + 12*(`x_min')^3*`s23'
        local var_sl_max = `s11' + 4*(`x_max')^2*`s22' + 9*(`x_max')^4*`s33' ///
            + 4*`x_max'*`s12' + 6*(`x_max')^2*`s13' + 12*(`x_max')^3*`s23'

        local t_min = `sl_min' / sqrt(`var_sl_min')
        local t_max = `sl_max' / sqrt(`var_sl_max')

        // Delta-method for primary turning point (using implicit function theorem)
        // For turning point, need numerical gradient
        if `tp' != . {
            local denom = 2*`b2' + 6*`b3'*`tp'
            if abs(`denom') > 1e-10 {
                // dx*/db1 = -1/denom, dx*/db2 = -2*tp/denom, dx*/db3 = -3*tp^2/denom
                local g1 = -1 / `denom'
                local g2 = -2*`tp' / `denom'
                local g3 = -3*(`tp')^2 / `denom'
                local tp_var = (`g1')^2*`s11' + (`g2')^2*`s22' + (`g3')^2*`s33' ///
                    + 2*`g1'*`g2'*`s12' + 2*`g1'*`g3'*`s13' + 2*`g2'*`g3'*`s23'
                local tp_se = sqrt(`tp_var')
            }
            else {
                local tp_se = .
            }
        }
        else {
            local tp_se = .
        }

        // Delta-method for inflection point: ip = -b2/(3*b3)
        local ip_g2 = -1 / (3*`b3')
        local ip_g3 = `b2' / (3*(`b3')^2)
        local ip_var = (`ip_g2')^2*`s22' + 2*`ip_g2'*`ip_g3'*`s23' + (`ip_g3')^2*`s33'
        local ip_se = sqrt(`ip_var')

        local spec_label "y = β₁·x + β₂·x² + β₃·x³"
        local spec_short "Cubic"
    }

    // --- LOG-QUADRATIC: ln(y) = b1*ln(x) + b2*[ln(x)]^2 ---
    else if "`model'" == "logquad" {
        // Turning point in log-space: -b1/(2*b2), then exponentiate
        local tp_log = -(`b1') / (2*(`b2'))
        local tp = exp(`tp_log')

        // Slopes at bounds (in log-space)
        local lx_min = ln(`x_min')
        local lx_max = ln(`x_max')
        local sl_min = `b1' + 2*`b2'*`lx_min'
        local sl_max = `b1' + 2*`b2'*`lx_max'

        // t-statistics at bounds (in log-space)
        local t_min = (`b1' + 2*`b2'*`lx_min') / ///
            sqrt(`s11' + 4*(`lx_min')^2*`s22' + 4*`lx_min'*`s12')
        local t_max = (`b1' + 2*`b2'*`lx_max') / ///
            sqrt(`s11' + 4*(`lx_max')^2*`s22' + 4*`lx_max'*`s12')

        // Delta-method for exp(-b1/(2*b2))
        // dx*/db1 = x* * (-1/(2*b2))
        // dx*/db2 = x* * (b1/(2*b2^2))
        local g1 = `tp' * (-1/(2*`b2'))
        local g2 = `tp' * (`b1'/(2*(`b2')^2))
        local tp_var = (`g1')^2*`s11' + 2*`g1'*`g2'*`s12' + (`g2')^2*`s22'
        local tp_se = sqrt(`tp_var')

        local spec_label "ln(y) = β₁·ln(x) + β₂·[ln(x)]²"
        local spec_short "Log-Quadratic"
    }

    // --- INVERSE: y = b1*x + b2*(1/x) ---
    else if "`model'" == "inv" {
        // Turning point: dy/dx = b1 - b2/x^2 = 0  =>  x* = sqrt(b2/b1)
        if `b2'/`b1' < 0 {
            di as err "no real turning point (b2/b1 < 0 for inverse specification)"
            local tp = .
        }
        else {
            local tp = sqrt(`b2'/`b1')
        }

        // Slopes at bounds
        local sl_min = `b1' - `b2'/((`x_min')^2)
        local sl_max = `b1' - `b2'/((`x_max')^2)

        // t-statistics at bounds
        local t_min = (`b1' - `b2'/((`x_min')^2)) / ///
            sqrt(`s11' + `s22'/((`x_min')^4) - 2*`s12'/((`x_min')^2))
        local t_max = (`b1' - `b2'/((`x_max')^2)) / ///
            sqrt(`s11' + `s22'/((`x_max')^4) - 2*`s12'/((`x_max')^2))

        // Delta-method: x* = sqrt(b2/b1)
        // dx*/db1 = -0.5 * sqrt(b2) / b1^(3/2)
        // dx*/db2 =  0.5 / sqrt(b1*b2)
        if `tp' != . {
            local g1 = -0.5 * sqrt(`b2') / (`b1'^(3/2))
            local g2 =  0.5 / sqrt(`b1'*`b2')
            local tp_var = (`g1')^2*`s11' + 2*`g1'*`g2'*`s12' + (`g2')^2*`s22'
            local tp_se = sqrt(`tp_var')
        }
        else {
            local tp_se = .
        }

        local spec_label "y = β₁·x + β₂·(1/x)"
        local spec_short "Inverse"
    }

    // =====================================================================
    // 9. DETERMINE SHAPE
    // =====================================================================
    local shape "U shape"
    local h0shape "Inverse U shape"
    if `t_min' > `t_max' {
        local shape "Inverse U shape"
        local h0shape "U shape"
    }

    // =====================================================================
    // 10. OVERALL SASABUCHI (1980) TEST
    // =====================================================================
    local t_sac = min(abs(`t_min'), abs(`t_max'))

    if `use_normal' {
        local p_min = 1 - normal(abs(`t_min'))
        local p_max = 1 - normal(abs(`t_max'))
        local p_sac = 1 - normal(`t_sac')
    }
    else {
        local p_min = ttail(`df', abs(`t_min'))
        local p_max = ttail(`df', abs(`t_max'))
        local p_sac = ttail(`df', `t_sac')
    }

    // =====================================================================
    // 11. DELTA-METHOD CONFIDENCE INTERVAL
    // =====================================================================
    if "`delta'" != "" | `tp_se' != . {
        if `use_normal' {
            local crit = invnormal(1 - (1 - `level'/100)/2)
        }
        else {
            local crit = invttail(`df', (1 - `level'/100)/2)
        }
        local tp_ci_lo = `tp' - `crit'*`tp_se'
        local tp_ci_hi = `tp' + `crit'*`tp_se'
    }

    // =====================================================================
    // 12. FIELLER CONFIDENCE INTERVAL (quadratic & inverse)
    // =====================================================================
    local fieller_lo = .
    local fieller_hi = .
    local fieller_type ""

    if "`fieller'" != "" & inlist("`model'", "quad", "inv") {
        local alpha = 1 - `level'/100
        if `use_normal' {
            local T_fi = invnormal(1 - `alpha'/2)
        }
        else {
            local T_fi = invttail(`df', `alpha'/2)
        }

        if "`model'" == "quad" {
            // Fieller for ratio -b1/(2*b2)
            local d_fi = (`s12')^2 - `s11'*`s22'
            local d_fi = `d_fi'*(`T_fi')^2 + (`b2')^2*`s11' + (`b1')^2*`s22' - 2*`b1'*`b2'*`s12'

            if `d_fi' > 0 & ((`b2')^2 - `s22'*(`T_fi')^2) > 0 {
                local theta_l = (-`s12'*(`T_fi')^2 + `b1'*`b2' - `T_fi'*sqrt(`d_fi')) / ///
                    ((`b2')^2 - `s22'*(`T_fi')^2)
                local theta_h = (-`s12'*(`T_fi')^2 + `b1'*`b2' + `T_fi'*sqrt(`d_fi')) / ///
                    ((`b2')^2 - `s22'*(`T_fi')^2)
                local fieller_lo = -0.5*`theta_h'
                local fieller_hi = -0.5*`theta_l'
                local fieller_type "bounded"
            }
            else if `d_fi' > 0 & ((`b2')^2 - `s22'*(`T_fi')^2) < 0 {
                local theta_l = (-`s12'*(`T_fi')^2 + `b1'*`b2' - `T_fi'*sqrt(`d_fi')) / ///
                    ((`b2')^2 - `s22'*(`T_fi')^2)
                local theta_h = (-`s12'*(`T_fi')^2 + `b1'*`b2' + `T_fi'*sqrt(`d_fi')) / ///
                    ((`b2')^2 - `s22'*(`T_fi')^2)
                local fieller_type "unbounded"
            }
            else {
                local fieller_type "entire_real_line"
            }
        }

        if "`model'" == "inv" {
            // Fieller for ratio b2/b1 (then sqrt)
            local d_fi = (`s12')^2 - `s11'*`s22'
            local d_fi = `d_fi'*(`T_fi')^2 + (`b1')^2*`s22' + (`b2')^2*`s11' - 2*`b1'*`b2'*`s12'

            if `d_fi' > 0 & ((`b1')^2 - `s11'*(`T_fi')^2) > 0 {
                local theta_l = (`s12'*(`T_fi')^2 + `b1'*`b2' - `T_fi'*sqrt(`d_fi')) / ///
                    ((`b1')^2 - `s11'*(`T_fi')^2)
                local theta_h = (`s12'*(`T_fi')^2 + `b1'*`b2' + `T_fi'*sqrt(`d_fi')) / ///
                    ((`b1')^2 - `s11'*(`T_fi')^2)
                if `theta_l'*`theta_h' > 0 & `theta_l' > 0 {
                    local fieller_lo = sqrt(`theta_l')
                    local fieller_hi = sqrt(`theta_h')
                    local fieller_type "bounded"
                }
                else {
                    local fieller_type "invalid_negative_ratio"
                }
            }
            else {
                local fieller_type "unbounded"
            }
        }
    }

    // =====================================================================
    // 12b. SIMONSOHN (2018) TWO-LINES TEST
    // =====================================================================
    local tl_slope_l = .
    local tl_t_l = .
    local tl_p_l = .
    local tl_slope_r = .
    local tl_t_r = .
    local tl_p_r = .
    local tl_reject = 0

    if "`twolines'" != "" & `tp' != . & inlist("`model'", "quad", "inv", "logquad") {
        // Simonsohn (2018): split data at turning point, test slopes
        preserve
        // Get dependent variable from the last estimation
        local depvar "`e(depvar)'"

        // For log-quadratic, split at log-space turning point
        // (tp is exponentiated, but var1 is in log scale)
        if "`model'" == "logquad" {
            local tl_split = `tp_log'
        }
        else {
            local tl_split = `tp'
        }

        // Determine the right estimator for each segment
        // Match the original estimation approach
        local tl_est "reg"
        local tl_opts ""
        if inlist("`cmd'", "xtreg") {
            local tl_est "xtreg"
            // Detect FE vs RE
            if "`e(model)'" == "fe" {
                local tl_opts ", fe"
            }
            else if "`e(model)'" == "re" {
                local tl_opts ", re"
            }
            else {
                local tl_opts ", fe"
            }
        }
        else if inlist("`cmd'", "areg") {
            local tl_est "areg"
            local tl_absvar "`e(absvar)'"
            local tl_opts ", absorb(`tl_absvar')"
        }

        // Left segment: x <= x*
        qui `tl_est' `depvar' `var1' if `var1' <= `tl_split' `tl_opts'
        local tl_slope_l = _b[`var1']
        local tl_se_l = _se[`var1']
        local tl_t_l = `tl_slope_l' / `tl_se_l'
        local tl_n_l = e(N)
        local tl_df_l = e(df_r)
        local tl_p_l = 2 * ttail(`tl_df_l', abs(`tl_t_l'))

        // Right segment: x > x*
        qui `tl_est' `depvar' `var1' if `var1' > `tl_split' `tl_opts'
        local tl_slope_r = _b[`var1']
        local tl_se_r = _se[`var1']
        local tl_t_r = `tl_slope_r' / `tl_se_r'
        local tl_n_r = e(N)
        local tl_df_r = e(df_r)
        local tl_p_r = 2 * ttail(`tl_df_r', abs(`tl_t_r'))

        // Test: for U-shape, left slope < 0 AND right slope > 0
        //        for inv-U, left slope > 0 AND right slope < 0
        if (`tl_slope_l' < 0 & `tl_slope_r' > 0) | ///
           (`tl_slope_l' > 0 & `tl_slope_r' < 0) {
            // Both slopes have correct signs
            // Joint p-value = max of individual one-sided p-values
            local tl_p1 = ttail(`tl_df_l', abs(`tl_t_l'))
            local tl_p2 = ttail(`tl_df_r', abs(`tl_t_r'))
            local tl_p_joint = max(`tl_p1', `tl_p2')
            local tl_reject = (`tl_p_joint' < (1 - `level'/100))
        }
        else {
            local tl_p_joint = 1
            local tl_reject = 0
        }

        restore
    }

    // =====================================================================
    // 12c. PARAMETRIC BOOTSTRAP CI
    // =====================================================================
    local bs_se = .
    local bs_ci_lo = .
    local bs_ci_hi = .
    local bs_bias = .

    if "`bootstrap'" != "" & `tp' != . & inlist("`model'", "quad", "inv", "logquad") {
        local B = `breps'
        local alpha_bs = 1 - `level'/100

        // Draw from N(b_hat, V_hat)
        tempname bs_draws bs_tps
        mat `bs_tps' = J(`B', 1, .)

        // Set up VCE matrix for Cholesky
        tempname bvec vmat chol_v
        mat `vmat' = J(2, 2, 0)
        mat `vmat'[1,1] = `s11'
        mat `vmat'[1,2] = `s12'
        mat `vmat'[2,1] = `s12'
        mat `vmat'[2,2] = `s22'

        // Cholesky decomposition
        mat `chol_v' = cholesky(`vmat')

        forvalues r = 1/`B' {
            // Draw z ~ N(0,I)
            tempname z1 z2
            scalar `z1' = rnormal()
            scalar `z2' = rnormal()

            // b_star = b_hat + L*z  (L = Cholesky factor)
            local bs_b1 = `b1' + `chol_v'[1,1]*`z1'
            local bs_b2 = `b2' + `chol_v'[2,1]*`z1' + `chol_v'[2,2]*`z2'

            // Compute turning point from bootstrap draw
            if "`model'" == "quad" {
                local bs_tp = -`bs_b1' / (2*`bs_b2')
            }
            else if "`model'" == "logquad" {
                local bs_tp = exp(-`bs_b1' / (2*`bs_b2'))
            }
            else if "`model'" == "inv" {
                if `bs_b2'/`bs_b1' >= 0 {
                    local bs_tp = sqrt(`bs_b2'/`bs_b1')
                }
                else {
                    local bs_tp = .
                }
            }

            mat `bs_tps'[`r', 1] = `bs_tp'
        }

        // Compute bootstrap statistics
        preserve
        qui drop _all
        qui svmat `bs_tps', names(_bs_tp)
        qui drop if _bs_tp1 == .

        qui su _bs_tp1, detail
        local bs_se = r(sd)
        local bs_mean = r(mean)
        local bs_bias = `bs_mean' - `tp'
        local bs_median = r(p50)

        // Percentile CI
        local lo_pct = `alpha_bs'/2 * 100
        local hi_pct = (1 - `alpha_bs'/2) * 100
        qui _pctile _bs_tp1, p(`lo_pct' `hi_pct')
        local bs_ci_lo = r(r1)
        local bs_ci_hi = r(r2)

        restore
    }

    // =====================================================================
    // 13. DISPLAY RESULTS
    // =====================================================================
    di
    di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
    di in smcl in gr "  {bf:║}" _col(5) in ye ///
        "  tptest: Universal Turning Point & Inflection Point Test" ///
        _col(72) in gr "{bf:║}"
    di in smcl in gr "  {bf:║}" _col(5) in ye ///
        "  Lind & Mehlum (2010) with Extensions" ///
        _col(72) in gr "{bf:║}"
    di in smcl in gr "  {bf:║}" _col(5) in ye ///
        "  Version 1.0.1" ///
        _col(72) in gr "{bf:║}"
    di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
    di

    // Estimator info
    di in gr "  Preceding estimator : " in ye "`cmd'"
    if "`prefix'" != "" {
        di in gr "  Equation prefix     : " in ye "`prefix'"
    }
    di in gr "  Specification       : " in ye "`spec_label'"
    di in gr "  Variables           : " in ye "`varlist'"
    if `use_normal' {
        di in gr "  Inference           : " in ye "Normal (N = `=e(N)')"
    }
    else {
        di in gr "  Inference           : " in ye "t-distribution (df = `df')"
    }
    di

    // Shape & turning point
    di in smcl in gr "  {hline 68}"
    di in gr "  Detected shape      : " _c
    if "`shape'" == "U shape" {
        di in ye "{bf:`shape'}"
    }
    else {
        di in ye "{bf:`shape'}"
    }

    if `tp' != . {
        di in gr "  Turning point (x*)  : " in ye %12.6g `tp'
    }
    else {
        di in gr "  Turning point (x*)  : " in re "  not found"
    }

    // Delta-method SE
    if "`delta'" != "" & `tp_se' != . {
        di in gr "  Delta-method SE     : " in ye %12.6g `tp_se'
        di in gr "  `level'% CI (delta)     : " in ye ///
            "[" %12.6g `tp_ci_lo' ", " %12.6g `tp_ci_hi' "]"
    }

    // Cubic extras
    if "`model'" == "cubic" {
        if `tp2' != . {
            di in gr "  Second turning pt.  : " in ye %12.6g `tp2'
        }
        di in gr "  Inflection point    : " in ye %12.6g `ip'
        if `ip_se' != . {
            di in gr "  Inflection pt. SE   : " in ye %12.6g `ip_se'
            local ip_ci_lo = `ip' - `crit'*`ip_se'
            local ip_ci_hi = `ip' + `crit'*`ip_se'
            di in gr "  `level'% CI (inflection): " in ye ///
                "[" %12.6g `ip_ci_lo' ", " %12.6g `ip_ci_hi' "]"
        }
    }

    di in smcl in gr "  {hline 68}"
    di

    // Sasabuchi test table
    di in gr "  {bf:Sasabuchi (1980) Test for `shape'}"
    di in gr "       H1: `shape'"
    di in gr "  vs.  H0: Monotone or `h0shape'"
    di

    di in text "  {hline 19}{c TT}{hline 42}"
    di in text %-21s "                   " "{c |}   " ///
        %-14s "Lower bound" "     " %-14s "Upper bound"
    di in text "  {hline 19}{c +}{hline 42}"
    di as text "  " %-17s "Interval"     "{c |}   " ///
        in result %12.6g `x_min' "     " %12.6g `x_max'
    di as text "  " %-17s "Slope"        "{c |}   " ///
        in result %12.6g `sl_min' "     " %12.6g `sl_max'

    if (`t_min')*(`t_max') > 0 {
        di in text "  {hline 19}{c BT}{hline 42}"
        di
        di as text "  Extremum outside interval — trivial failure to reject H0"
        local p_overall = .
        local t_overall = .
    }
    else {
        di as text "  " %-17s "t-value"  "{c |}   " ///
            in result %12.4f `t_min' "     " %12.4f `t_max'
        di as text "  " %-17s "P>|t|"    "{c |}   " ///
            in result %12.4f `p_min' "     " %12.4f `p_max'
        di in text "  {hline 19}{c BT}{hline 42}"

        di
        di as text "  {bf:Overall test of `shape':}"

        // Significance stars
        local stars ""
        if `p_sac' < 0.01       local stars "***"
        else if `p_sac' < 0.05  local stars "**"
        else if `p_sac' < 0.10  local stars "*"

        di as text "       t-value = " in result %9.4f `t_sac' in ye " `stars'"
        di as text "       P>|t|   = " in result %9.6f `p_sac'

        if `p_sac' < 0.01 {
            di in ye "  → {bf:Strong evidence} of `shape' (p < 0.01)"
        }
        else if `p_sac' < 0.05 {
            di in ye "  → {bf:Evidence} of `shape' (p < 0.05)"
        }
        else if `p_sac' < 0.10 {
            di in ye "  → {bf:Weak evidence} of `shape' (p < 0.10)"
        }
        else {
            di in gr "  → Cannot reject H0: Monotone or `h0shape'"
        }

        local p_overall = `p_sac'
        local t_overall = `t_sac'
    }

    // Fieller interval display
    if "`fieller'" != "" {
        di
        if "`fieller_type'" == "bounded" {
            di as text "  `level'% Fieller interval for extreme point: " ///
                in result "[" %12.6g `fieller_lo' "; " %12.6g `fieller_hi' "]"
        }
        else if "`fieller_type'" == "unbounded" {
            di as text "  `level'% Fieller interval: " in result "(-∞, +∞) — unbounded"
        }
        else if "`fieller_type'" == "entire_real_line" {
            di as text "  `level'% Fieller interval: " in result "(-∞, +∞) — entire real line"
        }
        else if "`fieller_type'" == "invalid_negative_ratio" {
            di as err "  Fieller interval: cannot be computed (negative ratio for inverse model)"
        }
    }

    // Two-lines test display
    if "`twolines'" != "" & `tp' != . {
        di
        di as text "  {bf:Simonsohn (2018) Two-Lines Test}"
        di as text "  Split at x* = " in result %9.4f `tp'
        di
        di in text "  {hline 19}{c TT}{hline 42}"
        di in text %-21s "                   " "{c |}   " ///
            %-20s "Left (x ≤ x*)" "   " %-20s "Right (x > x*)"
        di in text "  {hline 19}{c +}{hline 42}"
        di as text "  " %-17s "N"     "{c |}   " ///
            in result %12.0f `tl_n_l' "     " %12.0f `tl_n_r'
        di as text "  " %-17s "Slope" "{c |}   " ///
            in result %12.6g `tl_slope_l' "     " %12.6g `tl_slope_r'
        di as text "  " %-17s "t-value" "{c |}   " ///
            in result %12.4f `tl_t_l' "     " %12.4f `tl_t_r'
        di as text "  " %-17s "P>|t| (two-sided)" "{c |}   " ///
            in result %12.4f `tl_p_l' "     " %12.4f `tl_p_r'
        di in text "  {hline 19}{c BT}{hline 42}"
        di
        local tl_stars ""
        if `tl_p_joint' < 0.01       local tl_stars "***"
        else if `tl_p_joint' < 0.05  local tl_stars "**"
        else if `tl_p_joint' < 0.10  local tl_stars "*"
        di as text "  {bf:Joint p-value = }" in result %9.6f `tl_p_joint' in ye " `tl_stars'"
        if `tl_reject' {
            di in ye "  → {bf:Two-lines test confirms} `shape'"
        }
        else {
            di in gr "  → Two-lines test does not confirm `shape'"
        }
    }

    // Bootstrap CI display
    if "`bootstrap'" != "" & `bs_se' != . {
        di
        di as text "  {bf:Parametric Bootstrap (`breps' replications)}"
        di as text "  Bootstrap SE        : " in result %12.6g `bs_se'
        di as text "  Bootstrap bias      : " in result %12.6g `bs_bias'
        di as text "  `level'% CI (percentile): " in result ///
            "[" %12.6g `bs_ci_lo' ", " %12.6g `bs_ci_hi' "]"
    }

    di
    di in smcl in gr "  {hline 68}"
    di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
    di

    // =====================================================================
    // 14. STORED RESULTS
    // =====================================================================
    return scalar tp       = `tp'
    return scalar tp_se    = `tp_se'
    if "`delta'" != "" & `tp_se' != . {
        return scalar tp_ci_lo = `tp_ci_lo'
        return scalar tp_ci_hi = `tp_ci_hi'
    }
    return scalar t        = `t_overall'
    return scalar p        = `p_overall'
    return scalar x_l      = `x_min'
    return scalar x_u      = `x_max'
    return scalar s_l      = `sl_min'
    return scalar s_u      = `sl_max'
    return scalar t_l      = `t_min'
    return scalar t_u      = `t_max'
    return scalar extr     = `tp'
    return local  shape      "`shape'"
    return local  model      "`model'"
    return local  spec       "`spec_short'"
    return local  cmd_used   "`cmd'"

    if "`model'" == "cubic" {
        return scalar tp2    = `tp2'
        return scalar ip     = `ip'
        return scalar ip_se  = `ip_se'
        if `ip_se' != . {
            return scalar ip_ci_lo = `ip_ci_lo'
            return scalar ip_ci_hi = `ip_ci_hi'
        }
    }

    if "`fieller'" != "" {
        return scalar fieller_lo = `fieller_lo'
        return scalar fieller_hi = `fieller_hi'
        return local  fieller_type "`fieller_type'"
    }

    if "`twolines'" != "" & `tl_slope_l' != . {
        return scalar tl_slope_l  = `tl_slope_l'
        return scalar tl_slope_r  = `tl_slope_r'
        return scalar tl_t_l      = `tl_t_l'
        return scalar tl_t_r      = `tl_t_r'
        return scalar tl_p_l      = `tl_p_l'
        return scalar tl_p_r      = `tl_p_r'
        return scalar tl_p_joint  = `tl_p_joint'
        return scalar tl_reject   = `tl_reject'
    }

    if "`bootstrap'" != "" & `bs_se' != . {
        return scalar bs_se       = `bs_se'
        return scalar bs_bias     = `bs_bias'
        return scalar bs_ci_lo    = `bs_ci_lo'
        return scalar bs_ci_hi    = `bs_ci_hi'
        return scalar bs_reps     = `breps'
    }

    // =====================================================================
    // 15. GRAPH
    // =====================================================================
    if "`graph'" != "" & "`nograph'" == "" {
        // Build graph options incrementally
        local gcmd "_tptest_graph `varlist', model(`model') tp(`tp')"
        local gcmd "`gcmd' xmin(`x_min') xmax(`x_max')"
        local gcmd "`gcmd' b1(`b1') b2(`b2')"
        if `nvar' == 3 {
            local gcmd "`gcmd' b3(`b3')"
        }
        local gcmd `"`gcmd' shape("`shape'") spec("`spec_short'")"'
        local gcmd "`gcmd' tsac(`t_sac') psac(`p_sac')"
        if `tp_se' != . {
            local gcmd "`gcmd' tpse(`tp_se')"
        }
        if "`delta'" != "" & `tp_se' != . {
            local gcmd "`gcmd' tpcilo(`tp_ci_lo') tpcihi(`tp_ci_hi')"
        }
        if "`model'" == "cubic" {
            local gcmd "`gcmd' ip(`ip')"
        }
        if "`saving'" != "" {
            local gcmd `"`gcmd' saving(`saving')"'
        }
        if `"`title'"' != "" {
            local gcmd `"`gcmd' title(`title')"'
        }
        if `"`graphopt'"' != "" {
            local gcmd `"`gcmd' graphopt(`graphopt')"'
        }
        `gcmd'
    }

end


// =========================================================================
// AUTO-PREFIX DETECTION SUBROUTINE
// =========================================================================
capture program drop _tptest_autoprefix
program define _tptest_autoprefix, rclass
    args cmd

    local prefix ""
    local est_type "generic"
    local is_quantile = 0

    // Panel ARDL with equation prefixes
    if inlist("`cmd'", "xtpmg") {
        // xtpmg uses "ECT:" for LR, "SR:" for SR
        // Default to LR (long-run) for turning point
        local prefix "ECT:"
        local est_type "panel_ardl"
    }
    else if inlist("`cmd'", "pnardl") {
        local prefix "ECT:"
        local est_type "panel_nardl"
    }

    // Quantile estimators
    else if inlist("`cmd'", "mmqreg") {
        local est_type "quantile_mm"
        local is_quantile = 1
    }
    else if inlist("`cmd'", "qreg", "bsqreg", "sqreg") {
        local est_type "quantile"
    }
    else if inlist("`cmd'", "xtqreg", "xtqsh", "xtmdqr") {
        local est_type "panel_quantile"
    }

    // Panel quantile ARDL
    else if inlist("`cmd'", "xtpqardl") {
        local est_type "panel_qardl"
        local is_quantile = 1
    }
    else if inlist("`cmd'", "xtcspqardl") {
        local est_type "cs_panel_qardl"
        local is_quantile = 1
    }
    else if inlist("`cmd'", "fqardl", "qardl") {
        local est_type "ts_qardl"
        local is_quantile = 1
    }

    // Cross-sectional dependence
    else if inlist("`cmd'", "xtdcce2", "xtdcce2fast") {
        local est_type "cs_dep"
    }
    else if inlist("`cmd'", "xtcce") {
        local est_type "cs_dep"
    }

    // Standard panel
    else if inlist("`cmd'", "xtreg", "xtregfe", "xtregar") {
        local est_type "panel"
    }

    // ARDL family (time series)
    else if inlist("`cmd'", "ardl", "aardl", "fbardl", "fbnardl") {
        local est_type "ts_ardl"
    }
    else if inlist("`cmd'", "mtnardl", "tnardl") {
        local est_type "ts_nardl"
    }

    // Standard regression
    else if inlist("`cmd'", "regress", "reg", "ivregress", "ivreg2") {
        local est_type "ols"
    }
    else if inlist("`cmd'", "logit", "probit", "poisson", "nbreg") {
        local est_type "glm"
    }

    return local prefix "`prefix'"
    return local est_type "`est_type'"
    return scalar is_quantile = `is_quantile'
end


// =========================================================================
// MULTI-QUANTILE LOOP SUBROUTINE
// =========================================================================
capture program drop _tptest_quantile_loop
program define _tptest_quantile_loop, rclass
    syntax varlist(min=2 max=3 numeric), TAU(numlist) MODEL(string) ///
        CMD(string) MIN(real) MAX(real) ///
        [PREFIX(string) FIELler DELTA Level(cilevel) ///
         GRaph NOGRaph GRAPHOpt(string asis) ///
         SAVing(string) TItle(string asis)]

    local ntau : word count `tau'
    local nvar : word count `varlist'

    tokenize `varlist'
    local var1 "`1'"
    local var2 "`2'"
    if `nvar' == 3 local var3 "`3'"

    // Header
    di
    di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
    di in smcl in gr "  {bf:║}" _col(5) in ye ///
        "  tptest: Quantile Turning Point Trajectory" ///
        _col(72) in gr "{bf:║}"
    di in smcl in gr "  {bf:║}" _col(5) in ye ///
        "  Turning points across `ntau' quantiles" ///
        _col(72) in gr "{bf:║}"
    di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
    di
    di in gr "  Estimator: " in ye "`cmd'"
    di in gr "  Model:     " in ye "`model'"
    di

    // Table header
    di in text "  {hline 72}"
    di in text "  " %-8s "Quantile" ///
        %-14s "Turn. Point" ///
        %-12s "SE(delta)" ///
        %-10s "t-stat" ///
        %-10s "p-value" ///
        %-10s "Shape"
    di in text "  {hline 72}"

    // Compute actual data range (sentinel defaults = no user override)
    qui su `var1'
    if `min' == -9999.12345 {
        local min = r(min)
    }
    if `max' == 9999.12345 {
        local max = r(max)
    }

    // Store results in matrices
    tempname tp_mat

    local i = 0
    foreach tauval of local tau {
        local ++i

        // For mmqreg with multi-quantile equations
        if "`cmd'" == "mmqreg" {
            // mmqreg stores equations as "qtile__25:", "qtile__5:", etc.
            // (double underscore, trailing zeros stripped from percentage)
            local qpct = round(`tauval' * 100)
            // Strip trailing zeros: 50 -> 5, 25 -> 25, 75 -> 75
            local qpct_str "`qpct'"
            while substr("`qpct_str'", -1, 1) == "0" & length("`qpct_str'") > 1 {
                local qpct_str = substr("`qpct_str'", 1, length("`qpct_str'") - 1)
            }
            local qprefix "qtile__`qpct_str':"
        }
        else {
            local qprefix "`prefix'"
        }

        // Extract coefficients for this quantile
        tempname beta covar
        mat `beta' = e(b)
        mat `covar' = e(V)

        local v1name "`qprefix'`var1'"
        local v2name "`qprefix'`var2'"

        // Try primary name pattern
        local _col1 = colnumb(`beta', "`v1name'")
        if `_col1' == . {
            // Try single-underscore variant (qtile_25:)
            local qprefix2 = subinstr("`qprefix'", "qtile__", "qtile_", 1)
            local v1name "`qprefix2'`var1'"
            local v2name "`qprefix2'`var2'"
            local _col1 = colnumb(`beta', "`v1name'")
        }
        if `_col1' == . {
            // Try without prefix
            local v1name "`var1'"
            local v2name "`var2'"
            local _col1 = colnumb(`beta', "`v1name'")
        }
        if `_col1' == . {
            // Scan column names for a match containing the variable name
            local _ncols = colsof(`beta')
            local _colnames : colnames `beta'
            local _colfull : colfullnames `beta'
            local _found = 0
            forvalues _ci = 1/`_ncols' {
                local _cfull : word `_ci' of `_colfull'
                if strpos("`_cfull'", "`var1'") > 0 & strpos(lower("`_cfull'"), "qtile") > 0 {
                    // Check if this matches our tau value
                    if strpos("`_cfull'", "`qpct_str'") > 0 | strpos("`_cfull'", "`qpct'") > 0 {
                        // Extract the equation prefix from this column name
                        local _eqpfx = substr("`_cfull'", 1, strpos("`_cfull'", "`var1'") - 1)
                        local v1name "`_cfull'"
                        local v2name "`_eqpfx'`var2'"
                        local _found = 1
                        continue, break
                    }
                }
            }
            if !`_found' {
                di as text "  " %-8s %5.2f `tauval' in re "  (coefficients not found)"
                continue
            }
        }
        local qb1 = `beta'[1, colnumb(`beta', "`v1name'")]
        local qb2 = `beta'[1, colnumb(`beta', "`v2name'")]

        // Use string subscripting for V — robust with equation prefixes
        local qs11 = `covar'["`v1name'", "`v1name'"]
        local qs12 = `covar'["`v1name'", "`v2name'"]
        local qs22 = `covar'["`v2name'", "`v2name'"]

        // Compute turning point and SE
        if "`model'" == "quad" {
            local qtp = -`qb1' / (2*`qb2')
            local qg1 = -1/(2*`qb2')
            local qg2 = `qb1'/(2*(`qb2')^2)
            local qtp_var = (`qg1')^2*`qs11' + 2*`qg1'*`qg2'*`qs12' + (`qg2')^2*`qs22'
            local qtp_se = sqrt(`qtp_var')
        }
        else if "`model'" == "inv" {
            if `qb2'/`qb1' >= 0 {
                local qtp = sqrt(`qb2'/`qb1')
                local qg1 = -0.5*sqrt(`qb2')/((`qb1')^(3/2))
                local qg2 = 0.5/sqrt(`qb1'*`qb2')
                local qtp_var = (`qg1')^2*`qs11' + 2*`qg1'*`qg2'*`qs12' + (`qg2')^2*`qs22'
                local qtp_se = sqrt(`qtp_var')
            }
            else {
                local qtp = .
                local qtp_se = .
            }
        }
        else if "`model'" == "logquad" {
            local qtp_log = -`qb1'/(2*`qb2')
            local qtp = exp(`qtp_log')
            local qg1 = `qtp' * (-1/(2*`qb2'))
            local qg2 = `qtp' * (`qb1'/(2*(`qb2')^2))
            local qtp_var = (`qg1')^2*`qs11' + 2*`qg1'*`qg2'*`qs12' + (`qg2')^2*`qs22'
            local qtp_se = sqrt(`qtp_var')
        }
        else {
            local qtp = .
            local qtp_se = .
        }

        // Sasabuchi test at this quantile
        if "`model'" == "quad" {
            local qt_min = (`qb1' + 2*`qb2'*`min') / ///
                sqrt(`qs11' + 4*(`min')^2*`qs22' + 4*`min'*`qs12')
            local qt_max = (`qb1' + 2*`qb2'*`max') / ///
                sqrt(`qs11' + 4*(`max')^2*`qs22' + 4*`max'*`qs12')
        }
        else if "`model'" == "inv" {
            local qt_min = (`qb1' - `qb2'/((`min')^2)) / ///
                sqrt(`qs11' + `qs22'/((`min')^4) - 2*`qs12'/((`min')^2))
            local qt_max = (`qb1' - `qb2'/((`max')^2)) / ///
                sqrt(`qs11' + `qs22'/((`max')^4) - 2*`qs12'/((`max')^2))
        }
        else {
            local qt_min = .
            local qt_max = .
        }

        local qt_sac = min(abs(`qt_min'), abs(`qt_max'))

        // Use normal for quantum estimators (typically no df_r)
        local qp_sac = 1 - normal(`qt_sac')

        // Shape
        local qshape "U"
        if `qt_min' > `qt_max' local qshape "Inv-U"

        // Stars
        local qstars ""
        if `qp_sac' < 0.01       local qstars "***"
        else if `qp_sac' < 0.05  local qstars "**"
        else if `qp_sac' < 0.10  local qstars "*"

        // Display row
        if `qtp' != . {
            di as text "  " %-8s %5.2f `tauval' ///
                in result %12.4f `qtp' "  " ///
                %10.4f `qtp_se' "  " ///
                %8.4f `qt_sac' "  " ///
                %8.4f `qp_sac' "  " _c
            di in ye "  `qshape' `qstars'"
        }
        else {
            di as text "  " %-8s %5.2f `tauval' ///
                in re "       .           .          .          . " _c
            di in gr "  n/a"
        }

        // Build return matrices
        if `i' == 1 {
            mat `tp_mat' = (`tauval', `qtp', `qtp_se', `qt_sac', `qp_sac')
        }
        else {
            mat `tp_mat' = `tp_mat' \ (`tauval', `qtp', `qtp_se', `qt_sac', `qp_sac')
        }
    }

    di in text "  {hline 72}"
    di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
    di

    // Name the matrix columns
    mat colnames `tp_mat' = "tau" "turning_point" "se_delta" "t_stat" "p_value"

    // Graph BEFORE return (return matrix moves/consumes the matrix)
    if "`graph'" != "" & "`nograph'" == "" {
        _tptest_qgraph `tp_mat', ntau(`ntau') ///
            model(`model') cmd(`cmd') ///
            `=cond("`saving'"!="", `"saving(`saving')"', "")' ///
            `=cond(`"`title'"'!="", `"title(`title')"', "")'
    }

    // Return
    return matrix tp_trajectory = `tp_mat'
    return scalar n_tau = `ntau'
    return local  model "`model'"
end
