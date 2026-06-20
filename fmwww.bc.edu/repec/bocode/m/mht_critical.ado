*! version 1.0.0 18may2026 Viviano, Wuthrich, Niehaus & Rosas Lopez
*! Compute optimal MHT critical values
*! Based on Viviano, Wuthrich, and Niehaus (2026)
*! "A Model of Multiple Hypothesis Testing"

/*
    mht_critical - Compute optimal critical values for multiple hypothesis testing

    Implements Proposition 4.1 from the paper. Given a cost function and the number
    of hypotheses, computes the optimal per-test significance level:

        alpha(J, n) = C(J, n) / (b * omega_bar(J))

    Supports two cost models:
        1. Linear model: C(J,n) = c_f + c_v * |J| * n_bar
           => alpha(|J|, n/m) = alpha_bar * [(1 + ratio/|J|)/(1 + ratio)
                                             + (n/m - 1)/(1 + ratio)]
           where ratio = cf_share * J_bar / (1 - cf_share)     [Eq. 27, v10]
        2. Cobb-Douglas model: C(J,n) = k * |J|^beta * n^iota
           => alpha(|J|, n/m) = alpha_bar * |J|^(beta-1) * (n/m)^iota

    Also returns the Sidak benchmark: alpha_sidak = 1 - (1 - alpha_bar)^(1/J)

    Note: pass jhypotheses(999999) to approximate the J -> Inf limiting values.
*/

program define mht_critical, rclass
    version 15.0
    syntax , Jhypotheses(integer)      /// Number of hypotheses |J|
            ALPHAbar(real)             /// Benchmark single-hypothesis size
            [                          ///
            MODel(string)              /// Cost model: "linear" or "cobbdouglas" (default: linear)
            CFshare(real 0.46)         /// Fixed cost share (Linear model, default: 0.46)
            Jbar(real 3)              /// Average number of subgroups (Linear model, default: 3)
            NMratio(real 1.0)          /// Ratio n_bar / m_bar (default: 1.0)
            BETA(real 0.13)            /// Elasticity wrt |J| (Cobb-Douglas, default: 0.13)
            IOTA(real 0.075)           /// Elasticity wrt n (Cobb-Douglas, default: 0.075)
            ]

    // Input validation
    if `jhypotheses' < 1 {
        display as error "Number of hypotheses must be >= 1"
        exit 198
    }
    if `alphabar' <= 0 | `alphabar' >= 1 {
        display as error "Benchmark alpha must be in (0, 1)"
        exit 198
    }
    if `nmratio' <= 0 {
        display as error "Sample size ratio n_bar/m_bar must be > 0"
        exit 198
    }

    // Default model
    if "`model'" == "" {
        local model "linear"
    }

    // Compute optimal critical value
    local J = `jhypotheses'

    if "`model'" == "linear" {
        // Linear cost model (Equation 27 in v10)
        local ratio = `cfshare' * `jbar' / (1 - `cfshare')
        local multiplicity_adj = (1 + `ratio' / `J') / (1 + `ratio')
        local sample_adj = (`nmratio' - 1) / (1 + `ratio')
        local alpha_opt = `alphabar' * (`multiplicity_adj' + `sample_adj')
    }
    else if "`model'" == "cobbdouglas" {
        // Cobb-Douglas cost model (Appendix A / J-PAL calibration)
        local alpha_opt = `alphabar' * `J'^(`beta' - 1) * `nmratio'^`iota'
    }
    else {
        display as error `"Model must be "linear" or "cobbdouglas""'
        exit 198
    }

    // Ensure alpha is in valid range
    if `alpha_opt' > 1 local alpha_opt = 1
    if `alpha_opt' < 0 local alpha_opt = 0

    // Compute z-score for one-sided test
    local t_star = invnormal(1 - `alpha_opt')

    // Bonferroni comparison
    local alpha_bonf = `alphabar' / `J'
    local t_bonf = invnormal(1 - `alpha_bonf')

    // Sidak correction: 1 - (1 - alpha_bar)^(1/J)
    local alpha_sidak = 1 - (1 - `alphabar')^(1 / `J')
    local t_sidak = invnormal(1 - `alpha_sidak')

    // Display results
    display ""
    display as text "{hline 60}"
    display as result "  Optimal MHT Critical Values"
    display as text "  Viviano, Wuthrich, and Niehaus (2026)"
    display as text "{hline 60}"
    display ""

    if "`model'" == "linear" {
        display as text "  Cost model:          " as result "Linear (Eq. 26)"
        display as text "  Fixed cost share:    " as result %6.3f `cfshare'
        display as text "  Avg subgroups (J):   " as result %6.1f `jbar'
    }
    else {
        display as text "  Cost model:          " as result "Cobb-Douglas (App. A)"
        display as text "  Beta (arms elast.):  " as result %6.3f `beta'
        display as text "  Iota (size elast.):  " as result %6.3f `iota'
    }

    display as text "  Number of hypotheses:" as result %6.0f `J'
    display as text "  Benchmark alpha:     " as result %6.4f `alphabar'
    display as text "  Sample size ratio:   " as result %6.2f `nmratio'
    display ""
    display as text "{hline 60}"
    display as text "  Optimal test size:   " as result %9.6f `alpha_opt'
    display as text "  Optimal z-threshold: " as result %9.4f `t_star'
    display ""
    display as text "  Bonferroni size:     " as result %9.6f `alpha_bonf'
    display as text "  Bonferroni z-thresh: " as result %9.4f `t_bonf'
    display as text "  Sidak size:          " as result %9.6f `alpha_sidak'
    display as text "  Sidak z-threshold:   " as result %9.4f `t_sidak'
    display as text "  Unadjusted size:     " as result %9.6f `alphabar'
    display as text "{hline 60}"
    display ""

    // Return results
    return scalar alpha_opt   = `alpha_opt'
    return scalar t_star      = `t_star'
    return scalar alpha_bonf  = `alpha_bonf'
    return scalar t_bonf      = `t_bonf'
    return scalar alpha_sidak = `alpha_sidak'
    return scalar t_sidak     = `t_sidak'
    return scalar alpha_bar   = `alphabar'
    return scalar J           = `J'
    return scalar nm_ratio    = `nmratio'
    return local  model       = "`model'"

end
