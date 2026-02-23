*! _fbardl_dynmult — Dynamic Multipliers for FBARDL
*! Version 1.0.0 — 2026-02-21
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbardl_dynmult
program define _fbardl_dynmult
    version 17

    syntax, depvar(string) indepvars(string) p(integer) horizon(integer)

    // =========================================================================
    // TABLE: DYNAMIC MULTIPLIERS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 5: Dynamic Multipliers"
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

    foreach xvar of local indepvars {
        di as txt ""
        di as txt "  {bf:Variable: `xvar'}"
        di as txt "  {hline 55}"
        di as txt _col(5) "Horizon" _col(18) "Dynamic Mult." _col(35) "Cumulative Mult."
        di as txt "  {hline 55}"

        // Get short-run coefficients for this variable
        // Contemporaneous: D.xvar
        capture local theta_0 = _b[D.`xvar']
        if _rc != 0 local theta_0 = 0

        // Lagged short-run coefficients
        local max_q = 0
        forvalues j = 1/12 {
            capture local theta_`j' = _b[L`j'.D.`xvar']
            if _rc != 0 {
                local theta_`j' = 0
            }
            else {
                local max_q = `j'
            }
        }

        // Level coefficient
        capture local beta_x = _b[L.`xvar']
        if _rc != 0 local beta_x = 0

        // Long-run multiplier
        if abs(`alpha') > 1e-10 {
            local LR = -`beta_x' / `alpha'
        }
        else {
            local LR = 0
        }

        // Compute dynamic multipliers recursively
        // m_h = theta_h + SUM(j=1..min(h,p)) phi_j * m_{h-j}
        // Also: m_h = dΔy_{t+h}/dx_t (for h>=1) includes EC channel
        mata {
            H = `horizon' + 1
            dm = J(H, 1, 0)  // dynamic multiplier
            cm = J(H, 1, 0)  // cumulative multiplier

            // h=0: impact multiplier
            dm[1] = `theta_0'
            cm[1] = dm[1]

            // h=1,2,...,H-1
            for (h = 1; h < H; h++) {
                val = 0
                // Short-run theta
                if (h <= `max_q') {
                    val = strtoreal(st_local("theta_" + strofreal(h)))
                }
                // AR feedback
                for (j = 1; j <= min((h, `p')); j++) {
                    val = val + strtoreal(st_local("phi_" + strofreal(j))) * dm[h - j + 1]
                }
                // EC adjustment for h >= 1
                val = val + `alpha' * cm[h]
                // level effect
                val = val + `beta_x'

                dm[h+1] = val
                cm[h+1] = cm[h] + dm[h+1]
            }

            // Store for graph
            st_matrix("__fbardl_dm", dm)
            st_matrix("__fbardl_cm", cm)
        }

        // Display multiplier table
        forvalues h = 0/`horizon' {
            local hidx = `h' + 1
            local dm_val = el(__fbardl_dm, `hidx', 1)
            local cm_val = el(__fbardl_cm, `hidx', 1)
            if `h' <= 5 | `h' == 10 | `h' == 15 | `h' == `horizon' {
                di as txt _col(7) %4.0f `h' _col(17) as res %12.6f `dm_val' ///
                   _col(34) %12.6f `cm_val'
            }
        }
        di as txt "  {hline 55}"
        di as txt _col(5) "Long-run multiplier (analytical):" ///
           _col(45) as res %12.6f `LR'

        // =====================================================================
        // DYNAMIC MULTIPLIER GRAPH (publication quality)
        // =====================================================================
        capture noisily {
            tempfile _dynm_data
            qui save `_dynm_data', replace

            qui clear
            local HH = `horizon' + 1
            qui set obs `HH'
            qui gen int horizon = _n - 1
            qui gen double dyn_mult = .
            qui gen double cum_mult = .
            qui gen double lr_target = `LR'
            qui gen double zero = 0

            forvalues h = 0/`horizon' {
                local hidx = `h' + 1
                qui replace dyn_mult = el(__fbardl_dm, `hidx', 1) in `hidx'
                qui replace cum_mult = el(__fbardl_cm, `hidx', 1) in `hidx'
            }

            // Dynamic multiplier graph
            twoway (area dyn_mult horizon, color("66 133 244%40") lcolor("66 133 244") ///
                       lwidth(medthick)) ///
                   (line zero horizon, lcolor(gs8) lpattern(solid) lwidth(vthin)), ///
                   title("{bf:Dynamic Multiplier — `xvar'}", size(medlarge) color("24 54 104")) ///
                   subtitle("Period-by-period effect of unit shock", size(small) color(gs6)) ///
                   xtitle("Horizon", size(medsmall)) ///
                   ytitle("Multiplier", size(medsmall)) ///
                   legend(off) ///
                   graphregion(fcolor(white) lcolor(white)) ///
                   plotregion(fcolor(white) lcolor(gs14)) ///
                   ylabel(, format(%8.4f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                   xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                   note("Dynamic multiplier path", size(vsmall) color(gs8)) ///
                   scheme(s2color) name(dynmult_`xvar', replace)

            qui graph export "dynmult_`xvar'.png", replace width(1400)

            // Cumulative multiplier graph
            twoway (area cum_mult horizon, color("52 168 83%40") lcolor("52 168 83") ///
                       lwidth(medthick)) ///
                   (line lr_target horizon, lcolor("220 50 47") lpattern(dash) ///
                       lwidth(medium)) ///
                   (line zero horizon, lcolor(gs8) lpattern(solid) lwidth(vthin)), ///
                   title("{bf:Cumulative Multiplier — `xvar'}", size(medlarge) color("24 54 104")) ///
                   subtitle("Running sum of dynamic multipliers", size(small) color(gs6)) ///
                   xtitle("Horizon", size(medsmall)) ///
                   ytitle("Cumulative Multiplier", size(medsmall)) ///
                   legend(order(1 "Cumulative effect" 2 "LR target = `: di %8.4f `LR''") ///
                       size(small) cols(2) ring(0) pos(1) ///
                       region(fcolor(white%80) lcolor(gs12))) ///
                   graphregion(fcolor(white) lcolor(white)) ///
                   plotregion(fcolor(white) lcolor(gs14)) ///
                   ylabel(, format(%8.4f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                   xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                   note("Cumulative multiplier path", size(vsmall) color(gs8)) ///
                   scheme(s2color) name(cummult_`xvar', replace)

            qui graph export "cummult_`xvar'.png", replace width(1400)

            di as txt _col(5) "Graphs saved: dynmult_`xvar'.png, cummult_`xvar'.png"

            qui use `_dynm_data', clear
        }

        capture mat drop __fbardl_dm __fbardl_cm
    }
    di as txt ""
end
