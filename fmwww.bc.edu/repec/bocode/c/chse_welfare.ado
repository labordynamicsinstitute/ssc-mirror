*! chse_welfare v1.0.2  18apr2025  Nityahapani
*! Compute the three CHSE welfare distortions
*!
*! Options (no underscores -- Stata syntax requirement):
*!   eta(#)        equilibrium reframing investment
*!   kappa(#)      equilibrium credibility investment
*!   gamma(#)      propagation factor in [0,1)
*!   betar(#)      reframing network spillover (default 0.1)
*!   zetaii(#)     ambiguity spillover rate (default 0.3)
*!   cmu(#)        cost of reframing (default 0.5)
*!   ckappa(#)     cost of credibility (default 0.5)
*!   spillover(#)  avg network spillover for D2 (default 0.5)
*!   nedges(#)     number of edges (default 1)
*!   ambiguity(#)  avg 1-|2h-1| over edges if no varname (default 0.5)
*!   degree(#)     avg node degree if no varname (default 2.0)

program define chse_welfare, rclass
    version 14.0

    // Try varname syntax first; fall back to scalar-only syntax
    capture syntax varname(numeric) [if] [in] , ///
        ETA(real) KAPpa(real) GAMma(real) ///
        [BETAr(real 0.1) ZETAii(real 0.3) ///
         CMU(real 0.5) CKAPpa(real 0.5) ///
         SPILLover(real 0.5) NEDges(integer 1) ///
         AMBiguity(real 0.5) DEGree(real 2.0)]

    if _rc != 0 {
        syntax , ETA(real) KAPpa(real) GAMma(real) ///
            [BETAr(real 0.1) ZETAii(real 0.3) ///
             CMU(real 0.5) CKAPpa(real 0.5) ///
             SPILLover(real 0.5) NEDges(integer 1) ///
             AMBiguity(real 0.5) DEGree(real 2.0)]
        local has_var 0
    }
    else {
        local has_var 1
        marksample touse
    }

    if `gamma' < 0 | `gamma' >= 1 {
        di as error "gamma() must be in [0, 1)"
        exit 198
    }

    // --- avg ambiguity from data if varname supplied ---
    if `has_var' {
        quietly {
            tempvar amb
            gen double `amb' = 1 - abs(2*`varlist' - 1) if `touse'
            summarize `amb' if `touse', meanonly
            local avg_amb = r(mean)
            count if `touse'
            local n_e = r(N)
        }
    }
    else {
        local avg_amb = `ambiguity'
        local n_e     = `nedges'
    }

    // --- Distortion 1: over-investment in reframing ---
    local ef      = `betar' * `gamma' / (1 - `gamma')
    local excess1 = `eta' * `ef'
    local eta_SO  = `eta' / (1 + `ef')

    // --- Distortion 2: over-investment in commitment resistance ---
    local excess2 = `kappa' * `spillover'

    // --- Distortion 3: under-investment in hierarchy clarity ---
    if `has_var' {
        local deficit3 = `zetaii' * `avg_amb' * `n_e'
    }
    else {
        local deficit3 = `zetaii' * `avg_amb' * `degree'
    }

    // --- Total welfare loss ---
    local loss = `excess1' * `cmu' * `n_e' + ///
                 `excess2' * `ckappa' * `n_e' + ///
                 `deficit3'

    di as text _newline "CHSE Welfare Distortions"
    di as text "{hline 52}"
    di as text "  eta=" as result `eta' as text "  kappa=" as result `kappa' ///
        as text "  gamma=" as result `gamma' as text "  n_edges=" as result `n_e'
    di as text "{hline 52}"
    di as text "  D1 excess reframing  : " as result %8.4f `excess1'
    di as text "     eta_SO            : " as result %8.4f `eta_SO'
    di as text "  D2 excess resistance : " as result %8.4f `excess2'
    di as text "  D3 clarity deficit   : " as result %8.4f `deficit3'
    di as text "{hline 52}"
    di as text "  Total welfare loss   : " as result %8.4f `loss'
    di as text "{hline 52}"

    return scalar excess_1      = `excess1'
    return scalar eta_SO        = `eta_SO'
    return scalar excess_2      = `excess2'
    return scalar deficit_3     = `deficit3'
    return scalar welfare_loss  = `loss'
    return scalar excess_factor = `ef'
    return scalar avg_ambiguity = `avg_amb'
    return scalar Gamma         = `gamma'
    return scalar n_edges       = `n_e'
end
