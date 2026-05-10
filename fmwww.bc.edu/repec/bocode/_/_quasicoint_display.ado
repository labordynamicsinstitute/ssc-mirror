*! _quasicoint_display.ado — Beautiful table output for quasicoint
*! Version 1.0.2 — 2026-05-09 (fix: show ALL roots, correct L_LU classification, warning)
*! Author: Dr. Merwan Roudane

capture program drop _quasicoint_display
program define _quasicoint_display
    version 14
    syntax , level(real) p(integer) q(integer) k(integer) ///
            rho(real) nobs(integer) vars(string) [NOIsily]

    local r = `p' - `q'
    local halflife = -log(2)/log(`rho')
    local alpha = 1 - `level'/100
    local z_crit = invnormal(1 - `alpha'/2)

    // =====================================================================
    //  TABLE 1: CHARACTERISTIC ROOTS  (show ALL kp roots)
    // =====================================================================
    di ""
    di as text "  {hline 72}"
    di as text "  {bf:Table 1: Characteristic Roots of the VAR(`k')}"
    di as text "  {hline 72}"
    di as text "  {ralign 6:Root}" ///
       as text "  {ralign 12:Real Part}" ///
       as text "  {ralign 12:Imag Part}" ///
       as text "  {ralign 12:Modulus}" ///
       as text "  {ralign 12:Half-life}" ///
       as text "  {ralign 8:Region}"
    di as text "  {hline 72}"

    tempname evals
    capture matrix `evals' = _qc_eigenvalues
    local dom_root = 0
    local n_in_LU = 0
    if _rc == 0 {
        local nroots = rowsof(`evals')
        // Show all roots (up to 2*p for readability)
        local show = min(`nroots', 2*`p')
        forvalues i = 1/`show' {
            local re = `evals'[`i', 1]
            local im = `evals'[`i', 2]
            local mo = `evals'[`i', 3]
            local hl = .
            if `mo' > 0 & `mo' < 1 {
                local hl = -log(2)/log(`mo')
            }

            // CORRECT L_LU classification:
            // L_LU = {z: |z| <= 1 AND |z-1| <= 1-rho}
            // |z-1| = sqrt((re-1)^2 + im^2)
            local dist_from_1 = sqrt((`re' - 1)^2 + `im'^2)
            local region "L_ST"
            if `mo' <= 1 & `dist_from_1' <= (1 - `rho') {
                local region "{bf:L_LU}"
                local n_in_LU = `n_in_LU' + 1
            }

            if `i' == 1 local dom_root = `mo'

            if `hl' == . | `hl' > 9999 {
                di as text "  {ralign 6:`i'}" ///
                   as result "  {ralign 12:" %10.5f `re' "}" ///
                   as result "  {ralign 12:" %10.5f `im' "}" ///
                   as result "  {ralign 12:" %10.5f `mo' "}" ///
                   as result "  {ralign 12:Inf}" ///
                   as text   "  {ralign 8:`region'}"
            }
            else {
                di as text "  {ralign 6:`i'}" ///
                   as result "  {ralign 12:" %10.5f `re' "}" ///
                   as result "  {ralign 12:" %10.5f `im' "}" ///
                   as result "  {ralign 12:" %10.5f `mo' "}" ///
                   as result "  {ralign 12:" %10.1f `hl' "}" ///
                   as text   "  {ralign 8:`region'}"
            }
        }
    }
    di as text "  {hline 72}"
    di as text "  L_LU: near-unit root region {|z| <= 1 and |z-1| <= " %5.3f (1-`rho') "}"
    di as text "  L_ST: stationary/other roots"

    // WARNING: if no roots fall in L_LU
    if `n_in_LU' == 0 {
        di ""
        di as error "  {bf:WARNING}: No characteristic root falls in the L_LU region."
        di as error "  The dominant root (" %5.3f `dom_root' ") is far from unity."
        di as error "  The data may already be stationary. Consider using {bf:levels}"
        di as error "  instead of differences, or adjusting rho()."
        di ""
    }
    else if `n_in_LU' < `q' {
        di ""
        di as text "  {it:Note: Only `n_in_LU' of `q' requested near-unit roots fall in L_LU.}"
        di ""
    }

    // =====================================================================
    //  TABLE 2: QUASI-COINTEGRATING VECTORS
    // =====================================================================
    di ""
    di as text "  {hline 72}"
    di as text "  {bf:Table 2: Quasi-Cointegrating Vectors (QCS)}"
    di as text "  {hline 72}"

    tempname beta_qc beta_joh
    capture matrix `beta_qc' = _qc_beta
    capture matrix `beta_joh' = _qc_beta_joh

    // Header
    di as text "  {ralign 14:Variable}" ///
       as text "  {ralign 14:QCS (beta)}" ///
       as text "  {ralign 14:Johansen}" ///
       as text "  {ralign 14:Difference}"
    di as text "  {hline 72}"

    local vnames `vars'
    if _rc == 0 {
        forvalues i = 1/`p' {
            local vn : word `i' of `vnames'
            local bq = `beta_qc'[`i', 1]
            local bj = 0
            capture local bj = `beta_joh'[`i', 1]
            local df = `bq' - `bj'

            if `i' <= `r' {
                // Normalised to 1
                di as text "  {ralign 14:`vn'}" ///
                   as result "  {ralign 14:" %12.6f `bq' "}" ///
                   as result "  {ralign 14:" %12.6f `bj' "}" ///
                   as result "  {ralign 14:---}"
            }
            else {
                di as text "  {ralign 14:`vn'}" ///
                   as result "  {ralign 14:" %12.6f `bq' "}" ///
                   as result "  {ralign 14:" %12.6f `bj' "}" ///
                   as result "  {ralign 14:" %12.6f `df' "}"
            }
        }
    }
    di as text "  {hline 72}"

    // =====================================================================
    //  TABLE 3: PROFILE LIKELIHOOD SUMMARY
    // =====================================================================
    di ""
    di as text "  {hline 72}"
    di as text "  {bf:Table 3: Profile Likelihood over Dominant Root}"
    di as text "  {hline 72}"

    local lambda_hat = _qc_lambda_hat
    local LR_lambda  = _qc_LR_lambda

    di as text "  Estimated dominant root (lambda_hat): " as result %10.5f `lambda_hat'
    di as text "  Lower bound (rho):                    " as result %10.5f `rho'
    di as text "  Half-life at rho:                     " as result %10.1f `halflife' as text " periods"
    if `lambda_hat' < `rho' {
        di as text "  {it:Note: lambda_hat < rho; profile computed over [rho, 1].}"
    }
    di as text "  LR statistic (H0: lambda = 1):        " as result %10.3f `LR_lambda'

    local lr_pval = 1 - chi2(1, `LR_lambda')
    di as text "  LR chi2(1) p-value (approx):          " as result %10.4f `lr_pval'
    if `lr_pval' > 0.05 {
        di as text "  {it:=> Cannot reject unit root at `level'% level}"
    }
    else {
        di as text "  {it:=> Reject unit root at `level'% level}"
    }
    di ""

    // =====================================================================
    //  TABLE 4: CONDITIONAL CONFIDENCE INTERVALS
    // =====================================================================
    di as text "  {hline 72}"
    di as text "  {bf:Table 4: Conditional `level'% CIs for beta (given lambda)}"
    di as text "  {hline 72}"
    di as text "  {ralign 10:lambda}" ///
       as text "  {ralign 10:half-life}" ///
       as text "  {ralign 12:beta_hat}" ///
       as text "  {ralign 12:SE}" ///
       as text "  {ralign 22:[`level'% CI]}"
    di as text "  {hline 72}"

    tempname cci
    capture matrix `cci' = _qc_cond_ci
    if _rc == 0 {
        local ncci = rowsof(`cci')
        // Show subset: ~10 representative values
        local step = max(1, floor(`ncci'/10))
        forvalues idx = 1(`step')`ncci' {
            local lam = `cci'[`idx', 1]
            local bh  = `cci'[`idx', 2]
            local seh = `cci'[`idx', 3]
            local lo  = `bh' - `z_crit' * `seh'
            local hi  = `bh' + `z_crit' * `seh'
            local hl_i = .
            if `lam' > 0 & `lam' < 1 {
                local hl_i = -log(2)/log(`lam')
            }

            if `hl_i' == . | `hl_i' > 9999 {
                di as text "  {ralign 10:" %8.4f `lam' "}" ///
                   as text "  {ralign 10:Inf}" ///
                   as result "  {ralign 12:" %10.5f `bh' "}" ///
                   as result "  {ralign 12:" %10.5f `seh' "}" ///
                   as result "  {ralign 22:[" %8.4f `lo' ", " %8.4f `hi' "]}"
            }
            else {
                di as text "  {ralign 10:" %8.4f `lam' "}" ///
                   as text "  {ralign 10:" %8.1f `hl_i' "}" ///
                   as result "  {ralign 12:" %10.5f `bh' "}" ///
                   as result "  {ralign 12:" %10.5f `seh' "}" ///
                   as result "  {ralign 22:[" %8.4f `lo' ", " %8.4f `hi' "]}"
            }
        }
    }
    di as text "  {hline 72}"

    // =====================================================================
    //  TABLE 5: ROBUST CI SUMMARY
    // =====================================================================
    di ""
    di as text "  {hline 72}"
    di as text "  {bf:Table 5: Robust `level'% Confidence Intervals}"
    di as text "  {hline 72}"

    tempname np_ci_mat
    capture matrix `np_ci_mat' = _qc_np_ci
    if _rc == 0 {
        local np_lo = `np_ci_mat'[1, 1]
        local np_hi = `np_ci_mat'[1, 2]
        di as text "  Nearly Optimal (EMW):    " ///
           as result "[" %8.4f `np_lo' ", " %8.4f `np_hi' "]"
    }

    // Conditional at unit root
    capture {
        local cci_n = rowsof(`cci')
        local b_ur = `cci'[`cci_n', 2]
        local se_ur = `cci'[`cci_n', 3]
        local lo_ur = `b_ur' - `z_crit' * `se_ur'
        local hi_ur = `b_ur' + `z_crit' * `se_ur'
        di as text "  Conditional (lambda=1): " ///
           as result "[" %8.4f `lo_ur' ", " %8.4f `hi_ur' "]"
    }

    // At best lambda
    capture {
        local cci_best_idx = 1
        tempname pll
        matrix `pll' = _qc_profile_ll
        local npl = rowsof(`pll')
        local best_ll = .
        forvalues ii = 1/`npl' {
            if `pll'[`ii', 2] != . & (`best_ll' == . | `pll'[`ii', 2] > `best_ll') {
                local best_ll = `pll'[`ii', 2]
                local cci_best_idx = `ii'
            }
        }
        local b_best = `cci'[`cci_best_idx', 2]
        local se_best = `cci'[`cci_best_idx', 3]
        local lo_best = `b_best' - `z_crit' * `se_best'
        local hi_best = `b_best' + `z_crit' * `se_best'
        local lam_best = `cci'[`cci_best_idx', 1]
        di as text "  Conditional (lambda=" %5.3f `lam_best' "): " ///
           as result "[" %8.4f `lo_best' ", " %8.4f `hi_best' "]"
    }

    di as text "  {hline 72}"
    di ""
end
