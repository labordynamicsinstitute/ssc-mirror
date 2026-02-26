*! _mtnardl_advanced — Advanced Post-Estimation Analysis for MTNARDL
*! Version 1.0.0 — 2026-02-24
*! Includes: Wald tests, asymmetric ratios, persistence profile,
*!           LR equilibrium, speed of adjustment, pass-through analysis

capture program drop _mtnardl_advanced
program define _mtnardl_advanced
    version 17

    syntax, depvar(string) decomp_vars(string) orig_vars(string) ///
            nq(integer) p(integer) horizon(integer) ///
            ecmcoef(real) partition_label(string)

    local alpha = `ecmcoef'

    // =========================================================================
    // TABLE A: SPEED OF ADJUSTMENT ANALYSIS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Speed of Adjustment Analysis"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 55}"
    di as txt _col(5) "ECM coefficient (alpha)" _col(40) as res %12.6f `alpha'

    if `alpha' < 0 & `alpha' > -2 {
        local halflife = -ln(2) / ln(1 + `alpha')
        di as txt _col(5) "Half-life (periods)" _col(40) as res %12.4f `halflife'

        local adj50 = `halflife'
        local adj90 = -ln(10) / ln(1 + `alpha')
        local adj99 = -ln(100) / ln(1 + `alpha')
        di as txt _col(5) "50% adjustment time" _col(40) as res %12.4f `adj50'
        di as txt _col(5) "90% adjustment time" _col(40) as res %12.4f `adj90'
        di as txt _col(5) "99% adjustment time" _col(40) as res %12.4f `adj99'
    }
    else if `alpha' >= 0 {
        di as err _col(5) "WARNING: ECM coefficient is non-negative — no stable equilibrium"
        local halflife = .
    }
    else {
        di as err _col(5) "WARNING: ECM coefficient < -2 — explosive dynamics"
        local halflife = .
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // TABLE B: PERSISTENCE PROFILE (Pesaran & Shin, 1996)
    // =========================================================================
    di as txt ""
    di as txt "  {bf:Persistence Profile} (Pesaran & Shin, 1996)"
    di as txt "  {hline 55}"
    di as txt _col(5) "Horizon" _col(20) "Persistence" _col(38) "Cumul. adj."
    di as txt "  {hline 55}"

    if `alpha' < 0 & `alpha' > -2 {
        forvalues j = 1/`p' {
            capture local phi_`j' = _b[L`j'.D.`depvar']
            if _rc != 0 local phi_`j' = 0
        }

        mata: _mtnardl_calc_persist(`horizon', `p', `alpha')

        local pp_halflife = 0
        forvalues h = 0/`horizon' {
            local hidx = `h' + 1
            local pp_val = el(__mtnardl_pp, `hidx', 1)
            local ca_val = el(__mtnardl_ca, `hidx', 1)
            if `h' <= 5 | `h' == 10 | `h' == 15 | `h' == `horizon' {
                di as txt _col(7) %4.0f `h' _col(19) as res %12.6f `pp_val' ///
                   _col(37) %12.6f `ca_val'
            }
            if `pp_val' < 0.5 & `pp_halflife' == 0 {
                local pp_halflife = `h'
            }
        }

        di as txt "  {hline 55}"
        di as txt _col(5) "Profile half-life:" _col(30) as res "`pp_halflife' periods"
        di as txt ""

        // Persistence Profile Graph
        capture noisily {
            tempfile _pp_data
            qui save `_pp_data', replace

            qui clear
            local HH = `horizon' + 1
            qui set obs `HH'
            qui gen int horizon = _n - 1
            qui gen double persistence = .
            qui gen double halfline = 0.5

            forvalues h = 0/`horizon' {
                local hidx = `h' + 1
                qui replace persistence = el(__mtnardl_pp, `hidx', 1) in `hidx'
            }

            twoway (area persistence horizon, color("156 39 176%30") ///
                       lcolor("156 39 176") lwidth(medthick)) ///
                   (line halfline horizon, lcolor("255 152 0") ///
                       lpattern(dash) lwidth(medium)), ///
                   title("{bf:Persistence Profile}", size(medlarge) color("24 54 104")) ///
                   subtitle("Pesaran & Shin (1996)", size(small) color(gs6)) ///
                   xtitle("Horizon", size(medsmall)) ///
                   ytitle("Persistence", size(medsmall)) ///
                   legend(order(1 "Persistence" 2 "Half-life threshold") ///
                       size(small) cols(2) ring(0) pos(1) ///
                       region(fcolor(white%80) lcolor(gs12))) ///
                   graphregion(fcolor(white) lcolor(white)) ///
                   plotregion(fcolor(white) lcolor(gs14)) ///
                   ylabel(0(0.1)1, format(%4.2f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                   xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                   scheme(s2color) name(persistence_profile, replace)

            qui graph export "mtnardl_persistence.png", replace width(1400)
            di as txt _col(5) "Graph saved: mtnardl_persistence.png"

            qui use `_pp_data', clear
        }

        capture mat drop __mtnardl_pp __mtnardl_ca
    }
    else {
        di as txt _col(5) "(Persistence profile not computed — ECM coefficient invalid)"
    }

    // =========================================================================
    // TABLE C: LONG-RUN EQUILIBRIUM RELATIONSHIP (per regime)
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Long-Run Equilibrium per Regime"
    di as txt "{hline 78}"
    di as txt ""

    if `alpha' < 0 {
        foreach xvar of local orig_vars {
            local cname = subinstr("`xvar'", ".", "_", .)

            di as txt "  {bf:Variable: `xvar'}"
            di as txt "  {hline 68}"
            di as txt _col(5) "Regime" _col(18) "LR Coef." _col(32) "Std.Err." ///
               _col(44) "z-stat" _col(54) "p-value"
            di as txt "  {hline 68}"

            forvalues q = 1/`nq' {
                local psvar "_mt_`cname'_q`q'"

                capture qui nlcom (LR_Q`q': -_b[L.`psvar'] / _b[L.`depvar']), level(95)
                if _rc == 0 {
                    mat _nlcom_b = r(b)
                    mat _nlcom_V = r(V)
                    local lr_b = _nlcom_b[1,1]
                    local lr_se = sqrt(_nlcom_V[1,1])
                    local lr_z = `lr_b' / `lr_se'
                    local lr_p = 2 * (1 - normal(abs(`lr_z')))

                    di as txt _col(5) "Q`q'" _col(16) as res %10.6f `lr_b' ///
                       _col(30) %10.6f `lr_se' _col(42) %8.4f `lr_z' ///
                       _col(52) %8.4f `lr_p' _c
                    _mtnardl_stars `lr_p'
                    mat drop _nlcom_b _nlcom_V
                }
                else {
                    di as txt _col(5) "Q`q'" _col(16) as err "could not compute"
                }
            }
            di as txt "  {hline 68}"
        }
    }
    else {
        di as txt _col(5) "(LR coefficients not computed — ECM coefficient invalid)"
    }

    // =========================================================================
    // TABLE D: WALD TESTS FOR ASYMMETRY
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Wald Tests for Asymmetry"
    di as txt "{hline 78}"

    foreach xvar of local orig_vars {
        local cname = subinstr("`xvar'", ".", "_", .)

        di as txt ""
        di as txt "  {bf:Variable: `xvar'}"

        // -----------------------------------------------------------------
        // D1: LONG-RUN SYMMETRY — H0: All LR multipliers are equal
        // -----------------------------------------------------------------
        di as txt ""
        di as txt "    {it:D1. Long-Run Symmetry}"
        di as txt "    {hline 55}"

        if `nq' >= 2 & `alpha' < 0 {
            // Overall joint test: all LR multipliers equal
            // Build nlcom expression for pairwise differences
            local nlcom_expr ""
            local ndiffs = 0
            forvalues q = 2/`nq' {
                local psvar1 "_mt_`cname'_q1"
                local psvarq "_mt_`cname'_q`q'"
                local ndiffs = `ndiffs' + 1
                local nlcom_expr "`nlcom_expr' (diff_`q': -_b[L.`psvarq']/_b[L.`depvar'] - (-_b[L.`psvar1']/_b[L.`depvar']))"
            }

            capture qui nlcom `nlcom_expr'
            if _rc == 0 {
                // Save nlcom results immediately (before anything clobbers r())
                mat _nlcom_b_w = r(b)
                mat _nlcom_V_w = r(V)
                local k_w = colsof(_nlcom_b_w)

                // Wald = b' * V^(-1) * b
                local wald_lr = .
                local wald_lr_p = .
                capture {
                    mat _wald_stat = _nlcom_b_w * invsym(_nlcom_V_w) * _nlcom_b_w'
                    local wald_lr = _wald_stat[1,1]
                    local wald_lr_p = chi2tail(`k_w', `wald_lr')
                }
                if _rc == 0 & `wald_lr' < . {
                    di as txt _col(7) "H0: LR_Q1 = LR_Q2 = ... = LR_Q`nq'"
                    di as txt _col(7) "Wald chi2(" as res "`k_w'" as txt ")" ///
                       _col(38) "= " as res %10.4f `wald_lr' ///
                       _col(55) "p = " as res %8.4f `wald_lr_p' _c
                    _mtnardl_stars `wald_lr_p'
                }
                capture mat drop _nlcom_b_w _nlcom_V_w _wald_stat
            }
            else {
                di as txt _col(7) "(could not compute joint LR symmetry test)"
            }

            // Pairwise: Q1 vs Q_nq (extreme regimes)
            // Restore estimation results (nlcom clobbers e())
            capture estimates restore _mtnardl_main
            local psvar1 "_mt_`cname'_q1"
            local psvarN "_mt_`cname'_q`nq'"
            capture qui nlcom (extreme: -_b[L.`psvarN']/_b[L.`depvar'] - (-_b[L.`psvar1']/_b[L.`depvar']))
            if _rc == 0 {
                mat _pw_b = r(b)
                mat _pw_V = r(V)
                local pw_diff = _pw_b[1,1]
                local pw_se = sqrt(_pw_V[1,1])
                local pw_z = `pw_diff' / `pw_se'
                local pw_p = 2 * (1 - normal(abs(`pw_z')))
                di as txt _col(7) "Q1 vs Q`nq': diff = " as res %8.4f `pw_diff' ///
                   as txt "  z = " as res %6.3f `pw_z' ///
                   as txt "  p = " as res %6.4f `pw_p' _c
                _mtnardl_stars `pw_p'
                mat drop _pw_b _pw_V
            }
        }
        else {
            di as txt _col(7) "(not computed — insufficient regimes or invalid ECM)"
        }
        di as txt "    {hline 55}"

        // -----------------------------------------------------------------
        // D2: SHORT-RUN SYMMETRY — H0: All SR coefficients equal
        // -----------------------------------------------------------------
        di as txt ""
        di as txt "    {it:D2. Short-Run Symmetry}"
        di as txt "    {hline 55}"

        if `nq' >= 2 {
            // Restore estimation results (nlcom clobbers e())
            capture estimates restore _mtnardl_main

            // Test: contemporaneous effects equal across regimes
            local test_sr ""
            local first_sr = 1
            local sr_base "_mt_`cname'_q1"
            forvalues q = 2/`nq' {
                local psvarq "_mt_`cname'_q`q'"
                capture local b_base = _b[D.`sr_base']
                capture local b_q = _b[D.`psvarq']
                if _rc == 0 {
                    if `first_sr' == 1 {
                        local test_sr "D.`psvarq' = D.`sr_base'"
                        local first_sr = 0
                    }
                    else {
                        local test_sr "`test_sr', D.`psvarq' = D.`sr_base'"
                    }
                }
            }

            if "`test_sr'" != "" {
                capture qui test `test_sr'
                if _rc == 0 {
                    local wald_sr = r(F) * r(df)
                    local wald_sr_df = r(df)
                    local wald_sr_p = r(p)
                    di as txt _col(7) "H0: SR_Q1 = SR_Q2 = ... = SR_Q`nq' (contemporaneous)"
                    di as txt _col(7) "F(" as res "`wald_sr_df'" as txt "," as res "`=e(df_r)'" as txt ")" ///
                       _col(38) "= " as res %10.4f r(F) ///
                       _col(55) "p = " as res %8.4f `wald_sr_p' _c
                    _mtnardl_stars `wald_sr_p'
                }
            }
            else {
                di as txt _col(7) "(no testable short-run coefficients)"
            }

            // Pairwise: Q1 vs Q_nq short-run
            local sr_pw_p = .
            local sr_pw_F = .
            capture {
                qui test D._mt_`cname'_q`nq' = D._mt_`cname'_q1
                local sr_pw_F = r(F)
                local sr_pw_p = r(p)
            }
            if _rc == 0 & `sr_pw_p' < . {
                di as txt _col(7) "Q1 vs Q`nq' (SR): F = " as res %8.4f `sr_pw_F' ///
                   as txt "  p = " as res %6.4f `sr_pw_p' _c
                _mtnardl_stars `sr_pw_p'
            }
        }
        di as txt "    {hline 55}"
    }

    // =========================================================================
    // TABLE E: ASYMMETRIC RATIOS & PASS-THROUGH ANALYSIS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Asymmetric Analysis by Regime"
    di as txt "{hline 78}"

    foreach xvar of local orig_vars {
        local cname = subinstr("`xvar'", ".", "_", .)

        if `alpha' < 0 & `nq' >= 2 {
            // Restore estimation
            capture estimates restore _mtnardl_main

            // Collect all LR coefficients
            local lr_min = .
            local lr_max = .
            local lr_min_q = 1
            local lr_max_q = 1
            forvalues q = 1/`nq' {
                local psvar "_mt_`cname'_q`q'"
                capture local bq = _b[L.`psvar']
                if _rc == 0 {
                    local lr_q`q' = -`bq' / `alpha'
                    if `lr_q`q'' < `lr_min' | `lr_min' == . {
                        local lr_min = `lr_q`q''
                        local lr_min_q = `q'
                    }
                    if `lr_q`q'' > `lr_max' | `lr_max' == . {
                        local lr_max = `lr_q`q''
                        local lr_max_q = `q'
                    }
                }
                else {
                    local lr_q`q' = .
                }
            }

            // -----------------------------------------------------------------
            // E1: ASYMMETRIC RATIOS TABLE
            // -----------------------------------------------------------------
            di as txt ""
            di as txt "  Variable: `xvar'"
            di as txt ""
            di as txt "    {it:E1. Asymmetric Ratios}"
            di as txt "    {hline 60}"
            di as txt _col(7) "Comparison" _col(30) "Ratio" ///
               _col(42) "Interpretation"
            di as txt "    {hline 60}"

            // Max/Min ratio (overall asymmetry)
            if abs(`lr_min') > 1e-10 {
                local asym_ratio = abs(`lr_max' / `lr_min')
                local asym_str : di %8.4f `asym_ratio'
                if `asym_ratio' > 2 {
                    local interp "Strong asymmetry"
                }
                else if `asym_ratio' > 1.5 {
                    local interp "Moderate asymmetry"
                }
                else if `asym_ratio' > 1.1 {
                    local interp "Mild asymmetry"
                }
                else {
                    local interp "Near symmetric"
                }
                di as txt _col(7) "Max(Q`lr_max_q')/Min(Q`lr_min_q')" ///
                   _col(28) as res "`asym_str'" ///
                   _col(42) as txt "`interp'"
            }

            // Adjacent regime ratios
            forvalues q = 2/`nq' {
                local qm1 = `q' - 1
                if abs(`lr_q`qm1'') > 1e-10 {
                    local adj_ratio = abs(`lr_q`q'' / `lr_q`qm1'')
                    local adj_str : di %8.4f `adj_ratio'
                    if `adj_ratio' > 1.05 {
                        local adj_interp "Q`q' > Q`qm1'"
                    }
                    else if `adj_ratio' < 0.95 {
                        local adj_interp "Q`q' < Q`qm1'"
                    }
                    else {
                        local adj_interp "Q`q' ~ Q`qm1'"
                    }
                    di as txt _col(7) "|LR(Q`q')/LR(Q`qm1')|" ///
                       _col(28) as res "`adj_str'" ///
                       _col(42) as txt "`adj_interp'"
                }
            }

            // Overall spread
            local lr_spread = `lr_max' - `lr_min'
            di as txt "    {hline 60}"
            di as txt _col(7) "LR range: [" as res %8.4f `lr_min' ///
               as txt ", " as res %8.4f `lr_max' as txt "]  " ///
               "Spread = " as res %8.4f `lr_spread'
            di as txt "    {hline 60}"

            // -----------------------------------------------------------------
            // E2: PAIRWISE LR DIFFERENCES TABLE
            // -----------------------------------------------------------------
            di as txt ""
            di as txt "    {it:E2. Pairwise Long-Run Differences}"
            di as txt "    {hline 60}"
            di as txt _col(7) "Regime Pair" _col(22) "LR Diff." ///
               _col(35) "Std.Err." _col(48) "z-stat" _col(58) "p-value"
            di as txt "    {hline 60}"

            // Restore for nlcom
            capture estimates restore _mtnardl_main

            forvalues q1 = 1/`nq' {
                local q1p1 = `q1' + 1
                forvalues q2 = `q1p1'/`nq' {
                    local psv1 "_mt_`cname'_q`q1'"
                    local psv2 "_mt_`cname'_q`q2'"

                    // Restore before each nlcom
                    capture estimates restore _mtnardl_main

                    capture qui nlcom (d: -_b[L.`psv2']/_b[L.`depvar'] - (-_b[L.`psv1']/_b[L.`depvar']))
                    if _rc == 0 {
                        mat _pw_b2 = r(b)
                        mat _pw_V2 = r(V)
                        local pw_d = _pw_b2[1,1]
                        local pw_se2 = sqrt(_pw_V2[1,1])
                        local pw_z2 = `pw_d' / `pw_se2'
                        local pw_p2 = 2 * (1 - normal(abs(`pw_z2')))
                        di as txt _col(7) "Q`q1' vs Q`q2'" ///
                           _col(20) as res %9.4f `pw_d' ///
                           _col(33) %9.4f `pw_se2' ///
                           _col(46) %7.3f `pw_z2' ///
                           _col(56) %8.4f `pw_p2' _c
                        _mtnardl_stars `pw_p2'
                        capture mat drop _pw_b2 _pw_V2
                    }
                }
            }
            di as txt "    {hline 60}"

            // -----------------------------------------------------------------
            // E3: LR COEFFICIENT BAR CHART
            // -----------------------------------------------------------------
            // Restore for graph
            capture estimates restore _mtnardl_main

            // Create temporary dataset for the graph
            preserve
            qui {
                clear
                set obs `nq'
                gen regime = _n
                gen double lr_coef = .
                gen str20 regime_label = ""
                forvalues q = 1/`nq' {
                    replace lr_coef = `lr_q`q'' in `q'
                    replace regime_label = "Q`q'" in `q'
                }
                // Color by sign: positive vs negative
                gen positive = (lr_coef >= 0) if lr_coef < .

                // Create bar chart
                local graph_title "Long-Run Coefficients by Regime"
                local graph_subtitle "Variable: `xvar' — `partition_label'"

                twoway (bar lr_coef regime if positive == 1, ///
                           barw(0.7) color("59 130 246") lcolor(black) lwidth(thin)) ///
                       (bar lr_coef regime if positive == 0, ///
                           barw(0.7) color("239 68 68") lcolor(black) lwidth(thin)), ///
                    title("`graph_title'", size(medium)) ///
                    subtitle("`graph_subtitle'", size(small)) ///
                    xlabel(1/`nq', valuelabel) ///
                    ylabel(, format(%9.3f) grid) ///
                    ytitle("Long-Run Multiplier") ///
                    xtitle("Regime") ///
                    legend(order(1 "Positive LR" 2 "Negative LR") ///
                        position(6) rows(1) size(small)) ///
                    yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
                    graphregion(color(white)) plotregion(margin(b=0)) ///
                    note("MTNARDL — Asymmetric LR multipliers across regimes", size(vsmall)) ///
                    scheme(s2color) ///
                    name(lr_asym_`cname', replace)
                qui graph export "mtnardl_lr_asym_`cname'.png", replace width(1200) height(800)
            }
            restore

            di as txt ""
            di as txt _col(5) "Graph saved: mtnardl_lr_asym_`cname'.png"

            // -----------------------------------------------------------------
            // E4: REGIME SUMMARY TABLE
            // -----------------------------------------------------------------
            di as txt ""
            di as txt "    {it:E4. Regime Summary}"
            di as txt "    {hline 60}"
            di as txt _col(5) "Regime" _col(15) "LR Coef." ///
               _col(29) "|Ratio vs Q1|" _col(45) "Magnitude" _col(58) "Sign"
            di as txt "    {hline 60}"

            forvalues q = 1/`nq' {
                // Ratio vs Q1
                local ratio_str = "baseline"
                local mag_str = ""
                if `q' > 1 & abs(`lr_q1') > 1e-10 {
                    local ratio_val = abs(`lr_q`q'' / `lr_q1')
                    local ratio_str : di %8.4f `ratio_val'
                    if `ratio_val' > 2.0 {
                        local mag_str "Much stronger"
                    }
                    else if `ratio_val' > 1.2 {
                        local mag_str "Stronger"
                    }
                    else if `ratio_val' > 0.8 {
                        local mag_str "Similar"
                    }
                    else if `ratio_val' > 0.5 {
                        local mag_str "Weaker"
                    }
                    else {
                        local mag_str "Much weaker"
                    }
                }
                else if `q' == 1 {
                    local mag_str "Reference"
                }

                // Sign
                local sign_str = "+"
                if `lr_q`q'' < 0 {
                    local sign_str = "-"
                }

                di as txt _col(5) "Q`q'" ///
                   _col(13) as res %10.6f `lr_q`q'' ///
                   _col(29) "`ratio_str'" ///
                   _col(45) as txt "`mag_str'" ///
                   _col(58) "`sign_str'"
            }
            di as txt "    {hline 60}"
        }
    }
    di as txt ""

end

// =============================================================================
// Mata helper function for persistence profile
// =============================================================================
mata
void _mtnardl_calc_persist(real scalar horizon, real scalar p, real scalar alpha)
{
    real scalar H, h, j, val
    real colvector pp, ca

    H = horizon + 1
    pp = J(H, 1, 0)
    pp[1] = 1

    for (h = 1; h < H; h++) {
        val = 0
        for (j = 1; j <= min((h, p)); j++) {
            val = val + strtoreal(st_local("phi_" + strofreal(j))) * pp[h - j + 1]
        }
        val = val + alpha * pp[h]
        pp[h+1] = val
    }

    ca = J(H, 1, 0)
    for (h = 0; h < H; h++) {
        ca[h+1] = 1 - pp[h+1]
    }

    st_matrix("__mtnardl_pp", pp)
    st_matrix("__mtnardl_ca", ca)
}
end
