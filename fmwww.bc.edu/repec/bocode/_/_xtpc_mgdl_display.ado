*! _xtpc_mgdl_display v1.1.0 — MGDL-specific display
*! Author: Dr. Merwan Roudane

program define _xtpc_mgdl_display
    di
    di as txt "{hline 78}"
    di as txt "{bf:xtpanelcoint -- `e(estimator)'}"
    di as txt "{hline 78}"
    di as txt "  Dep. variable : " as res "`e(depvar)'"
    di as txt "  Shock variable: " as res "`e(indepvar)'"
    di as txt "  Products (M)  : " as res %6.0f e(M_products)
    di as txt "  Locations (N) : " as res %6.0f e(N_locations)
    di as txt "  Time periods  : " as res %6.0f e(T)
    di as txt "  IRF horizon   : " as res %6.0f e(horizon)
    di as txt "{hline 78}"

    // ─── Product-level cumulative multipliers ────────────────────────────
    if "`e(cum_mult)'" != "" {
        tempname cm cl ch sg
        mat `cm' = e(cum_mult)
        mat `cl' = e(cum_ci_lo)
        mat `ch' = e(cum_ci_hi)
        mat `sg' = e(significant)
        local M = rowsof(`cm')

        di
        di as txt "  {bf:Product-Level Cumulative Multipliers}"
        di
        di as txt "{ralign 6:#}{ralign 14:delta_hat}" ///
           as txt "{ralign 14:CI_lower}" ///
           as txt "{ralign 14:CI_upper}" ///
           as txt "{ralign 8:Sig.}"
        di as txt "{hline 56}"

        forvalues i = 1/`M' {
            local sig_star ""
            if `sg'[`i', 1] == 1 local sig_star "***"
            di as txt %6.0f `i' ///
               as res %14.4f `cm'[`i', 1] ///
               as res %14.4f `cl'[`i', 1] ///
               as res %14.4f `ch'[`i', 1] ///
               as txt "  `sig_star'"
        }
        di as txt "{hline 56}"
    }

    // ─── Location effects c_j (if available) ─────────────────────────────
    if "`e(location_irfs)'" != "" {
        tempname cj
        mat `cj' = e(location_irfs)
        local N_loc = rowsof(`cj')
        local h1 = colsof(`cj')

        di
        di as txt "  {bf:Location Effects (c_j) — Cumulative}"
        di
        di as txt "{ralign 6:Loc.}{ralign 14:cum(c_j)}"
        di as txt "{hline 20}"

        forvalues j = 1/`N_loc' {
            local cum_cj = 0
            forvalues l = 1/`h1' {
                local cum_cj = `cum_cj' + `cj'[`j', `l']
            }
            di as txt %6.0f `j' ///
               as res %14.4f `cum_cj'
        }
        di as txt "{hline 20}"
    }
end
