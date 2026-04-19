*! chse_welfare — Compute the three CHSE welfare distortions
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! Distortion 1 (over-investment in reframing):
*!   Excess_1 = eta_eq * beta_R * Gamma / (1 - Gamma)
*!   eta_SO   = eta_eq / (1 + beta_R * Gamma / (1 - Gamma))
*!
*! Distortion 2 (over-investment in commitment resistance):
*!   Excess_2 = kappa_eq * avg_spillover
*!   (avg_spillover is supplied by the user as a network-level scalar)
*!
*! Distortion 3 (under-investment in hierarchy clarity):
*!   Deficit_3 = zeta_II * avg_degree * avg_ambiguity
*!   avg_ambiguity = mean( 1 - |2*h - 1| ) over edges
*!
*! Welfare loss (monetised):
*!   Loss = Excess_1 * c_mu * n_edges
*!          + Excess_2 * c_kappa * n_edges
*!          + Deficit_3
*!
*! Syntax (all scalars):
*!   chse_welfare, eta(#) kappa(#) gamma(#)
*!                 [beta_r(#) zeta_ii(#) c_mu(#) c_kappa(#)
*!                  avg_ambiguity(#) avg_degree(#) avg_spillover(#)
*!                  n_edges(integer)]
*!
*! Syntax (h is a variable, one obs per edge):
*!   chse_welfare varname [if] [in],
*!                eta(#) kappa(#) gamma(#) [options above]

program define chse_welfare, rclass
    version 14.0
    
    // Allow optional varname
    capture syntax varname(numeric) [if] [in], ///
        ETA(real) KAPpa(real) GAMma(real) ///
        [BETA_R(real 0.1) ZETA_II(real 0.3) ///
         C_MU(real 0.5) C_KAPpa2(real 0.5) ///
         AVG_SPILLover(real 0.5) N_Edges(integer 1)]
    
    if _rc != 0 {
        // No varname path
        syntax , ETA(real) KAPpa(real) GAMma(real) ///
            [BETA_R(real 0.1) ZETA_II(real 0.3) ///
             C_MU(real 0.5) C_KAPpa2(real 0.5) ///
             AVG_SPILLover(real 0.5) N_Edges(integer 1) ///
             AVG_AMBiguity(real 0.5) AVG_DEGree(real 2.0)]
        local has_var 0
    }
    else {
        local has_var 1
        marksample touse
    }
    
    // Validate Gamma
    if `gamma' < 0 | `gamma' >= 1 {
        di as error "gamma() must be in [0, 1)"
        exit 198
    }
    
    // ----------------------------------------------------------------
    // Compute avg_ambiguity from h variable if supplied
    // ----------------------------------------------------------------
    if `has_var' {
        quietly {
            tempvar ambig
            gen double `ambig' = 1 - abs(2 * `varlist' - 1) if `touse'
            summarize `ambig' if `touse', meanonly
            local avg_ambiguity = r(mean)
            count if `touse'
            local n_edges = r(N)
        }
    }
    else {
        if "`avg_ambiguity'" == "" local avg_ambiguity = 0.5
        if "`avg_degree'" == "" local avg_degree = 2.0
    }
    
    // ----------------------------------------------------------------
    // Distortion 1: over-investment in reframing
    // ----------------------------------------------------------------
    local excess_factor = `beta_r' * `gamma' / (1 - `gamma')
    local excess_1 = `eta' * `excess_factor'
    local eta_SO   = `eta' / (1 + `excess_factor')
    
    // ----------------------------------------------------------------
    // Distortion 2: over-investment in commitment resistance
    // ----------------------------------------------------------------
    local excess_2 = `kappa' * `avg_spillover'
    local kappa_SO_adjust = `excess_2' / max(`c_kappa2', 1e-6)
    
    // ----------------------------------------------------------------
    // Distortion 3: under-investment in hierarchy clarity
    // ----------------------------------------------------------------
    if `has_var' {
        local deficit_3 = `zeta_ii' * `avg_ambiguity' * `n_edges'
    }
    else {
        local deficit_3 = `zeta_ii' * `avg_ambiguity' * `avg_degree'
    }
    
    // ----------------------------------------------------------------
    // Total welfare loss (monetised)
    // ----------------------------------------------------------------
    local loss = `excess_1' * `c_mu' * `n_edges' + ///
                 `excess_2' * `c_kappa2' * `n_edges' + ///
                 `deficit_3'
    
    // ----------------------------------------------------------------
    // Display
    // ----------------------------------------------------------------
    di as text _newline "CHSE Welfare Distortions"
    di as text "{hline 52}"
    di as text "  Parameters:"
    di as text "    eta_eq   = " as result `eta'   as text ///
               "    kappa_eq = " as result `kappa'
    di as text "    Gamma    = " as result `gamma' as text ///
               "    beta_R   = " as result `beta_r'
    di as text "    zeta_II  = " as result `zeta_ii' as text ///
               "    n_edges  = " as result `n_edges'
    di as text "{hline 52}"
    di as text "  Distortion 1: over-investment in reframing"
    di as text "    Excess eta          : " as result %8.4f `excess_1'
    di as text "    Social optimum eta  : " as result %8.4f `eta_SO'
    di as text "    (excess factor = beta_R*Gamma/(1-Gamma) = " ///
               as result %6.4f `excess_factor' as text ")"
    di as text _newline "  Distortion 2: over-investment in commitment resistance"
    di as text "    Excess kappa        : " as result %8.4f `excess_2'
    di as text "    (avg_spillover used = " as result %6.4f `avg_spillover' as text ")"
    di as text _newline "  Distortion 3: under-investment in hierarchy clarity"
    di as text "    Clarity deficit     : " as result %8.4f `deficit_3'
    di as text "    (avg_ambiguity = 1-|2h-1| = " ///
               as result %6.4f `avg_ambiguity' as text ")"
    di as text "{hline 52}"
    di as text "  Total welfare loss    : " as result %8.4f `loss'
    di as text "{hline 52}"
    di as text "  Policy:"
    di as text "    D1: legal estoppel, institutional precedent"
    di as text "    D2: legibility subsidies, transparent announcements"
    di as text "    D3: public commitment requirements, mandates"
    
    // ----------------------------------------------------------------
    // Return
    // ----------------------------------------------------------------
    return scalar excess_1      = `excess_1'
    return scalar eta_SO        = `eta_SO'
    return scalar excess_2      = `excess_2'
    return scalar deficit_3     = `deficit_3'
    return scalar welfare_loss  = `loss'
    return scalar excess_factor = `excess_factor'
    return scalar avg_ambiguity = `avg_ambiguity'
    return scalar Gamma         = `gamma'
    return scalar n_edges       = `n_edges'
    
end
