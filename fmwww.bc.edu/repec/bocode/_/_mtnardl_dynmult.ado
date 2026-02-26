*! _mtnardl_dynmult — Dynamic Multipliers per Quantile Regime for MTNARDL
*! Version 1.0.1 — 2026-02-24
*! Computes and graphs dynamic/cumulative multipliers for each regime

capture program drop _mtnardl_dynmult
program define _mtnardl_dynmult
    version 17

    syntax, depvar(string) decomp_vars(string) orig_vars(string) ///
            nq(integer) p(integer) horizon(integer) ///
            partition_label(string)

    // =========================================================================
    // TABLE: DYNAMIC MULTIPLIERS PER REGIME
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Dynamic Multipliers — `partition_label'"
    di as txt "{hline 78}"

    // Get auto-regressive coefficients
    local phi_list ""
    forvalues j = 1/`p' {
        capture local phi_`j' = _b[L`j'.D.`depvar']
        if _rc != 0 local phi_`j' = 0
        local phi_list "`phi_list' `phi_`j''"
    }

    // Get ECM coefficient
    local alpha = _b[L.`depvar']

    // Professional color palette for regime graphs
    local colors `""33 150 243" "76 175 80" "255 152 0" "244 67 54" "156 39 176" "0 188 212" "255 235 59" "121 85 72" "63 81 181" "233 30 99" "0 150 136" "255 87 34" "103 58 183" "205 220 57" "96 125 139" "183 28 28" "27 94 32" "230 81 0" "49 27 146" "0 96 100""'

    // Process each original variable
    foreach xvar of local orig_vars {
        local cname = subinstr("`xvar'", ".", "_", .)

        di as txt ""
        di as txt "  {bf:Variable: `xvar'}"

        // =====================================================================
        // COMPUTE MULTIPLIERS FOR EACH REGIME
        // =====================================================================
        forvalues q = 1/`nq' {
            local psvar "_mt_`cname'_q`q'"

            di as txt ""
            di as txt "    {it:Regime Q`q'}"
            di as txt "    {hline 55}"
            di as txt _col(7) "Horizon" _col(20) "Dynamic Mult." _col(37) "Cumulative Mult."
            di as txt "    {hline 55}"

            // Get short-run coefficients for this regime
            capture local theta_0 = _b[D.`psvar']
            if _rc != 0 local theta_0 = 0

            local max_sr = 0
            forvalues j = 1/12 {
                capture local theta_`j' = _b[L`j'.D.`psvar']
                if _rc != 0 {
                    local theta_`j' = 0
                }
                else {
                    local max_sr = `j'
                }
            }

            // Level coefficient
            capture local beta_x = _b[L.`psvar']
            if _rc != 0 local beta_x = 0

            // Long-run multiplier
            if abs(`alpha') > 1e-10 {
                local LR = -`beta_x' / `alpha'
            }
            else {
                local LR = 0
            }

            // Compute multipliers in Mata
            local mata_horizon = `horizon'
            local mata_max_sr = `max_sr'
            local mata_p = `p'
            local mata_alpha = `alpha'
            local mata_beta_x = `beta_x'
            local mata_theta_0 = `theta_0'

            mata: _mtnardl_calc_mult(`mata_horizon', `mata_max_sr', `mata_p', ///
                `mata_alpha', `mata_beta_x', `mata_theta_0', `q')

            // Display multiplier table
            forvalues h = 0/`horizon' {
                local hidx = `h' + 1
                local dm_val = el(__mtnardl_dm_q`q', `hidx', 1)
                local cm_val = el(__mtnardl_cm_q`q', `hidx', 1)
                if `h' <= 5 | `h' == 10 | `h' == 15 | `h' == `horizon' {
                    di as txt _col(9) %4.0f `h' _col(19) as res %12.6f `dm_val' ///
                       _col(36) %12.6f `cm_val'
                }
            }
            di as txt "    {hline 55}"
            di as txt _col(7) "Long-run multiplier (analytical):" ///
               _col(47) as res %12.6f `LR'
        }

        // =====================================================================
        // COMBINED DYNAMIC MULTIPLIER GRAPH (overlay all regimes)
        // =====================================================================
        capture noisily {
            tempfile _dynm_data
            qui save `_dynm_data', replace

            qui clear
            local HH = `horizon' + 1
            qui set obs `HH'
            qui gen int horizon = _n - 1
            qui gen double zero = 0

            // Create columns for each regime
            forvalues q = 1/`nq' {
                qui gen double cm_q`q' = .
                forvalues h = 0/`horizon' {
                    local hidx = `h' + 1
                    qui replace cm_q`q' = el(__mtnardl_cm_q`q', `hidx', 1) in `hidx'
                }
            }

            // Build overlay twoway command
            local tw_cmd ""
            local legend_order ""
            forvalues q = 1/`nq' {
                local cidx = mod(`q' - 1, 20) + 1
                local this_color : word `cidx' of `colors'
                local tw_cmd `"`tw_cmd' (line cm_q`q' horizon, lcolor("`this_color'") lwidth(medthick))"'
                local legend_order `"`legend_order' `q' "Q`q'""'
            }

            twoway `tw_cmd' ///
                (line zero horizon, lcolor(gs8) lpattern(solid) lwidth(vthin)), ///
                title("{bf:Cumulative Multipliers — `xvar'}", ///
                    size(medlarge) color("24 54 104")) ///
                subtitle("`partition_label' — regime comparison", ///
                    size(small) color(gs6)) ///
                xtitle("Horizon", size(medsmall)) ///
                ytitle("Cumulative Multiplier", size(medsmall)) ///
                legend(order(`legend_order') size(vsmall) cols(5) ///
                    ring(0) pos(1) region(fcolor(white%80) lcolor(gs12))) ///
                graphregion(fcolor(white) lcolor(white)) ///
                plotregion(fcolor(white) lcolor(gs14)) ///
                ylabel(, format(%8.4f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                note("Pal & Mitra (2016) — Cumulative dynamic multipliers", ///
                    size(vsmall) color(gs8)) ///
                scheme(s2color) name(cummult_`cname', replace)

            qui graph export "mtnardl_cummult_`cname'.png", replace width(1600)
            di as txt _col(5) "Graph saved: mtnardl_cummult_`cname'.png"

            // =====================================================================
            // ASYMMETRIC DYNAMIC MULTIPLIER GRAPH (Q1 vs Q_nq)
            // =====================================================================
            if `nq' >= 2 {
                qui gen double asym_diff = cm_q`nq' - cm_q1

                twoway (area asym_diff horizon, color("244 67 54%30") lcolor("244 67 54") ///
                           lwidth(medthick)) ///
                       (line zero horizon, lcolor(gs8) lpattern(solid) lwidth(vthin)), ///
                       title("{bf:Asymmetric Dynamic Multiplier — `xvar'}", ///
                           size(medlarge) color("24 54 104")) ///
                       subtitle("Difference: Q`nq' (largest increases) minus Q1 (largest decreases)", ///
                           size(small) color(gs6)) ///
                       xtitle("Horizon", size(medsmall)) ///
                       ytitle("Multiplier Difference", size(medsmall)) ///
                       legend(off) ///
                       graphregion(fcolor(white) lcolor(white)) ///
                       plotregion(fcolor(white) lcolor(gs14)) ///
                       ylabel(, format(%8.4f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                       xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                       note("Positive values indicate Rockets & Feathers asymmetry", ///
                           size(vsmall) color(gs8)) ///
                       scheme(s2color) name(asym_`cname', replace)

                qui graph export "mtnardl_asym_`cname'.png", replace width(1600)
                di as txt _col(5) "Graph saved: mtnardl_asym_`cname'.png"
            }

            qui use `_dynm_data', clear
        }

        // Clean up matrices
        forvalues q = 1/`nq' {
            capture mat drop __mtnardl_dm_q`q' __mtnardl_cm_q`q'
        }
    }
    di as txt ""
end

// =============================================================================
// Mata helper function for multiplier calculation
// =============================================================================
mata
void _mtnardl_calc_mult(real scalar horizon, real scalar max_sr,
                         real scalar p, real scalar alpha,
                         real scalar beta_x, real scalar theta_0,
                         real scalar q)
{
    real scalar H, h, j, val
    real colvector dm, cm

    H = horizon + 1
    dm = J(H, 1, 0)
    cm = J(H, 1, 0)

    dm[1] = theta_0
    cm[1] = dm[1]

    for (h = 1; h < H; h++) {
        val = 0
        if (h <= max_sr) {
            val = strtoreal(st_local("theta_" + strofreal(h)))
        }
        for (j = 1; j <= min((h, p)); j++) {
            val = val + strtoreal(st_local("phi_" + strofreal(j))) * dm[h - j + 1]
        }
        val = val + alpha * cm[h]
        val = val + beta_x
        dm[h+1] = val
        cm[h+1] = cm[h] + dm[h+1]
    }

    st_matrix("__mtnardl_dm_q" + strofreal(q), dm)
    st_matrix("__mtnardl_cm_q" + strofreal(q), cm)
}
end
