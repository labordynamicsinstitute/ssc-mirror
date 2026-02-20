*! _fbnardl_advanced — Advanced Post-Estimation Analyses for FBNARDL
*! Version 1.0.0 — 2026-02-18
*! Author: fbnardl (merwanroudane920@gmail.com)
*!
*! Implements:
*!   1. Half-Life of Adjustment (ECM)
*!   2. Persistence Profile (Pesaran & Shin 1996) with Graph
*!   3. Fourier Terms Joint Significance F-test
*!   4. Asymmetric Adjustment Speed (pos/neg half-lives) with Graph

capture program drop _fbnardl_advanced
program define _fbnardl_advanced
    version 17

    syntax, depvar(string) decnames(string) ecmcoef(string) ///
        p(integer) q(integer) horizon(integer) ///
        best_kstar(real) [nofourier controls(string)]

    // =========================================================================
    // Restore model if needed
    // =========================================================================
    local alpha = _b[`ecmcoef']

    // AR coefficients
    forvalues j = 1/`p' {
        capture local phi_`j' = _b[L`j'.D.`depvar']
        if _rc != 0 local phi_`j' = 0
    }

    // =========================================================================
    // TABLE 7: HALF-LIFE & PERSISTENCE ANALYSIS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res "  Table 7: Half-Life & Persistence Analysis"
    di as txt "{hline 78}"

    // ----- A. ECM Half-Life -----
    di as txt ""
    di as res "  A. Half-Life of Adjustment (ECM)"
    di as txt "  {hline 65}"
    di as txt ""

    // ECM speed of adjustment
    local ecm_se = _se[`ecmcoef']
    local ecm_t = `alpha' / `ecm_se'
    local ecm_p = 2 * ttail(e(df_r), abs(`ecm_t'))

    di as txt _col(5) "ECM coefficient (alpha)  = " as res %10.6f `alpha'
    di as txt _col(5) "Std. Error               = " as res %10.6f `ecm_se'
    di as txt _col(5) "t-statistic              = " as res %10.4f `ecm_t' _c
    _fbnardl_stars `ecm_p'

    // Stability check
    if `alpha' >= 0 {
        di as err ""
        di as err _col(5) "WARNING: ECM coefficient is non-negative (alpha >= 0)."
        di as err _col(5) "The error correction mechanism is NOT convergent."
        di as err _col(5) "Half-life cannot be computed."
        di as txt "  {hline 65}"
    }
    else if `alpha' <= -1 {
        // Oscillatory convergence
        local half_life = -ln(2) / ln(abs(1 + `alpha'))
        di as txt ""
        di as txt _col(5) "Half-Life                = " as res %8.2f `half_life' as txt " periods"
        di as err _col(5) "Note: alpha < -1 implies oscillatory convergence."
        di as txt "  {hline 65}"
    }
    else {
        // Standard monotonic convergence: -1 < alpha < 0
        local half_life = -ln(2) / ln(1 + `alpha')
        di as txt ""
        di as txt _col(5) "Half-Life                = " as res %8.2f `half_life' as txt " periods"

        // Mean Adjustment Lag (MAL) = (1-alpha)/alpha for ECM
        local mal = -(1 + `alpha') / `alpha'
        di as txt _col(5) "Mean Adjustment Lag      = " as res %8.2f `mal' as txt " periods"

        // Full adjustment (99%) time
        local full_adj = ln(0.01) / ln(1 + `alpha')
        di as txt _col(5) "99% Adjustment Time      = " as res %8.2f `full_adj' as txt " periods"
        di as txt ""
        di as txt _col(5) "Interpretation: After a disequilibrium shock,"
        di as txt _col(5) "50% of the adjustment is completed in " as res %3.1f `half_life' as txt " periods."
        di as txt "  {hline 65}"
    }

    // ----- B. Persistence Profile -----
    di as txt ""
    di as res "  B. Persistence Profile (Pesaran & Shin, 1996)"
    di as txt "  {hline 65}"
    di as txt ""

    // Compute AR coefficients in levels from ECM
    // ECM: D.y = alpha*L.y + phi_1*L1.D.y + phi_2*L2.D.y + ...
    // Levels: y = (1+alpha+phi_1)*y_{t-1} + (phi_2-phi_1)*y_{t-2} + ...
    local nlevels = `p' + 1
    forvalues j = 1/`nlevels' {
        local a_`j' = 0
    }

    // a_1 = 1 + alpha + phi_1
    local a_1 = 1 + `alpha' + `phi_1'

    // a_j = phi_j - phi_{j-1} for j=2..p
    if `p' >= 2 {
        forvalues j = 2/`p' {
            local jm1 = `j' - 1
            local a_`j' = `phi_`j'' - `phi_`jm1''
        }
    }
    // a_{p+1} = -phi_p
    local a_`nlevels' = -`phi_`p''

    // Persistence profile: PP(0) = 1, PP(h) = sum_{j=1}^{min(h,p+1)} a_j * PP(h-j)
    tempname pp_mat
    local pp_horizon = `horizon'
    mat `pp_mat' = J(`pp_horizon' + 1, 1, 0)
    mat `pp_mat'[1, 1] = 1  // PP(0) = 1

    forvalues h = 1/`pp_horizon' {
        local idx = `h' + 1
        local pp_h = 0
        local jmax = min(`h', `nlevels')
        forvalues j = 1/`jmax' {
            local prev_idx = `h' - `j' + 1
            local pp_h = `pp_h' + `a_`j'' * el(`pp_mat', `prev_idx', 1)
        }
        mat `pp_mat'[`idx', 1] = `pp_h'
    }

    // Find half-life from persistence profile (first h where PP(h) < 0.5)
    local pp_halflife = `pp_horizon'
    forvalues h = 1/`pp_horizon' {
        local idx = `h' + 1
        local pp_val = el(`pp_mat', `idx', 1)
        if abs(`pp_val') < 0.5 {
            local pp_halflife = `h'
            continue, break
        }
    }

    // Display persistence profile table (first 15 horizons + every 5th after)
    di as txt _col(5) "Horizon" _col(18) "PP(h)" _col(32) "% Remaining"
    di as txt "  {hline 50}"

    forvalues h = 0/`pp_horizon' {
        local idx = `h' + 1
        local pp_val = el(`pp_mat', `idx', 1)
        local pct = `pp_val' * 100

        // Show first 10, then every 5th
        if `h' <= 10 | mod(`h', 5) == 0 | `h' == `pp_horizon' | `h' == `pp_halflife' {
            if `h' == `pp_halflife' {
                di as res _col(5) %4.0f `h' _col(16) %10.6f `pp_val' _col(30) %8.2f `pct' "%  <-- Half-life"
            }
            else {
                di as txt _col(5) %4.0f `h' _col(16) %10.6f `pp_val' _col(30) %8.2f `pct' "%"
            }
        }
    }
    di as txt "  {hline 50}"
    di as txt _col(5) "Persistence Profile Half-Life = " as res `pp_halflife' as txt " periods"
    di as txt ""

    // ----- Plot Persistence Profile -----
    mat _fbnardl_pp = `pp_mat'
    preserve
    capture noisily {
        qui clear
        qui set obs `= `pp_horizon' + 1'
        qui gen horizon = _n - 1
        qui gen double pp = .
        qui gen double half_line = 0.5
        qui gen double zero_line = 0

        forvalues h = 0/`pp_horizon' {
            local idx = `h' + 1
            qui replace pp = el(_fbnardl_pp, `idx', 1) in `idx'
        }

        twoway (area pp horizon, color(navy%30) lcolor(navy) lwidth(medthick)) ///
               (line half_line horizon, lcolor(cranberry) lwidth(thin) lpattern(dash)) ///
               (line zero_line horizon, lcolor(gs8) lwidth(vthin)), ///
               title("Persistence Profile", size(medium)) ///
               subtitle("Convergence to Long-Run Equilibrium", size(small)) ///
               ytitle("PP(h) — Fraction of Disequilibrium", size(small)) ///
               xtitle("Horizon (h)", size(small)) ///
               ylabel(0(0.25)1, format(%4.2f) labsize(small)) ///
               xline(`pp_halflife', lcolor(cranberry) lwidth(thin) lpattern(shortdash)) ///
               legend(order(1 "Persistence Profile" 2 "50% Line (Half-Life = `pp_halflife')") ///
                   size(vsmall) rows(1) position(6)) ///
               note("fbnardl — fbnardl package" ///
                    "Pesaran & Shin (1996) methodology", size(vsmall)) ///
               scheme(s2color) name(persist_fbnardl, replace)

        qui graph export "persistence_profile.png", replace width(1200)
        di as txt _col(5) "Graph saved: persistence_profile.png"
    }
    restore
    capture mat drop _fbnardl_pp

    // =========================================================================
    // TABLE 8: FOURIER TERMS SIGNIFICANCE
    // =========================================================================
    if "`nofourier'" == "" & `best_kstar' > 0 {
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Table 8: Fourier Terms Joint Significance"
        di as txt "{hline 78}"
        di as txt ""
        di as txt _col(5) "H0: gamma_1 = gamma_2 = 0 (no structural break)"
        di as txt _col(5) "H1: At least one Fourier term is significant"
        di as txt ""

        // Joint F-test for sin and cos terms
        capture qui test _fbnardl_sin _fbnardl_cos
        if _rc == 0 {
            local fourier_F = r(F)
            local fourier_df1 = r(df)
            local fourier_df2 = r(df_r)
            local fourier_p = r(p)

            di as txt "  {hline 60}"
            di as txt _col(5) "Test" _col(30) "Value"
            di as txt "  {hline 60}"
            di as txt _col(5) "F-statistic" _col(28) as res %10.4f `fourier_F'
            di as txt _col(5) "Degrees of freedom" _col(28) as res "(" `fourier_df1' ", " `fourier_df2' ")"
            di as txt _col(5) "p-value" _col(28) as res %10.4f `fourier_p' _c
            _fbnardl_stars `fourier_p'
            di as txt ""

            // Individual coefficients
            local sin_b = _b[_fbnardl_sin]
            local sin_se = _se[_fbnardl_sin]
            local cos_b = _b[_fbnardl_cos]
            local cos_se = _se[_fbnardl_cos]

            di as txt _col(5) "Selected frequency k*" _col(28) as res %10.2f `best_kstar'
            di as txt _col(5) "sin(2*pi*k*t/T) coef." _col(28) as res %10.4f `sin_b' as txt " (SE=" as res %6.4f `sin_se' as txt ")"
            di as txt _col(5) "cos(2*pi*k*t/T) coef." _col(28) as res %10.4f `cos_b' as txt " (SE=" as res %6.4f `cos_se' as txt ")"
            di as txt "  {hline 60}"

            if `fourier_p' < 0.05 {
                di as res _col(5) "=> Fourier terms are jointly significant at 5%."
                di as res _col(5) "   Evidence of smooth structural break (Yilanci et al. 2020)."
            }
            else {
                di as txt _col(5) "=> Fourier terms are NOT jointly significant at 5%."
                di as txt _col(5) "   Standard NARDL without structural break may suffice."
            }
        }
        else {
            di as err _col(5) "Could not perform Fourier joint significance test."
        }
        di as txt ""
    }

    // =========================================================================
    // TABLE 9: ASYMMETRIC ADJUSTMENT SPEED
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res "  Table 9: Asymmetric Adjustment Speed"
    di as txt "{hline 78}"
    di as txt ""

    foreach cname of local decnames {

        // Get short-run coefficients for pos/neg
        capture local theta_pos_0 = _b[D.`cname'_pos]
        if _rc != 0 local theta_pos_0 = 0
        capture local theta_neg_0 = _b[D.`cname'_neg]
        if _rc != 0 local theta_neg_0 = 0

        forvalues j = 1/`q' {
            capture local theta_pos_`j' = _b[L`j'.D.`cname'_pos]
            if _rc != 0 local theta_pos_`j' = 0
            capture local theta_neg_`j' = _b[L`j'.D.`cname'_neg]
            if _rc != 0 local theta_neg_`j' = 0
        }

        // Long-run multipliers
        capture local lr_pos = -_b[L.`cname'_pos] / `alpha'
        if _rc != 0 local lr_pos = 0
        capture local lr_neg = -_b[L.`cname'_neg] / `alpha'
        if _rc != 0 local lr_neg = 0

        // Compute cumulative dynamic multipliers for pos/neg separately
        tempname adj_pos adj_neg
        mat `adj_pos' = J(`horizon' + 1, 1, 0)
        mat `adj_neg' = J(`horizon' + 1, 1, 0)

        // Dynamic multiplier recursive computation
        tempname dyn_pos dyn_neg
        mat `dyn_pos' = J(`horizon' + 1, 1, 0)
        mat `dyn_neg' = J(`horizon' + 1, 1, 0)

        forvalues h = 0/`horizon' {
            local idx = `h' + 1

            // Direct effect
            if `h' <= `q' {
                local d_pos = `theta_pos_`h''
                local d_neg = `theta_neg_`h''
            }
            else {
                local d_pos = 0
                local d_neg = 0
            }

            // AR feedback
            local ar_p = 0
            local ar_n = 0
            local jmax = min(`h', `p')
            forvalues j = 1/`jmax' {
                local prev_idx = `h' - `j' + 1
                local ar_p = `ar_p' + `phi_`j'' * el(`dyn_pos', `prev_idx', 1)
                local ar_n = `ar_n' + `phi_`j'' * el(`dyn_neg', `prev_idx', 1)
            }

            mat `dyn_pos'[`idx', 1] = `d_pos' + `ar_p'
            mat `dyn_neg'[`idx', 1] = `d_neg' + `ar_n'

            // Cumulative
            if `h' == 0 {
                mat `adj_pos'[`idx', 1] = el(`dyn_pos', `idx', 1)
                mat `adj_neg'[`idx', 1] = el(`dyn_neg', `idx', 1)
            }
            else {
                mat `adj_pos'[`idx', 1] = el(`adj_pos', `idx' - 1, 1) + el(`dyn_pos', `idx', 1)
                mat `adj_neg'[`idx', 1] = el(`adj_neg', `idx' - 1, 1) + el(`dyn_neg', `idx', 1)
            }
        }

        // Use effective LR = cumulative at max horizon (what path actually converges to)
        local last_idx = `horizon' + 1
        local eff_lr_pos = el(`adj_pos', `last_idx', 1)
        local eff_lr_neg = el(`adj_neg', `last_idx', 1)

        // Find half-life for positive adjustment
        // Half-life = first h where cum(h) >= 0.5 * effective_LR
        local hl_pos = `horizon'
        if `eff_lr_pos' != 0 {
            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local cum_val = el(`adj_pos', `idx', 1)
                if abs(`cum_val') >= abs(0.5 * `eff_lr_pos') {
                    local hl_pos = `h'
                    continue, break
                }
            }
        }

        // Find half-life for negative adjustment
        local hl_neg = `horizon'
        if `eff_lr_neg' != 0 {
            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local cum_val = el(`adj_neg', `idx', 1)
                if abs(`cum_val') >= abs(0.5 * `eff_lr_neg') {
                    local hl_neg = `h'
                    continue, break
                }
            }
        }

        // Find 90% adjustment time
        local adj90_pos = `horizon'
        if `eff_lr_pos' != 0 {
            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local cum_val = el(`adj_pos', `idx', 1)
                if abs(`cum_val') >= abs(0.9 * `eff_lr_pos') {
                    local adj90_pos = `h'
                    continue, break
                }
            }
        }
        local adj90_neg = `horizon'
        if `eff_lr_neg' != 0 {
            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local cum_val = el(`adj_neg', `idx', 1)
                if abs(`cum_val') >= abs(0.9 * `eff_lr_neg') {
                    local adj90_neg = `h'
                    continue, break
                }
            }
        }

        // Compute % of LR achieved at impact
        local pct_pos_0 = 0
        local pct_neg_0 = 0
        if `eff_lr_pos' != 0 local pct_pos_0 = (`theta_pos_0' / `eff_lr_pos') * 100
        if `eff_lr_neg' != 0 local pct_neg_0 = (`theta_neg_0' / `eff_lr_neg') * 100

        // Detect overshooting: |impact| > |effective LR|
        local overshoot_pos = (abs(`pct_pos_0') > 100 & `eff_lr_pos' != 0)
        local overshoot_neg = (abs(`pct_neg_0') > 100 & `eff_lr_neg' != 0)

        // Display
        di as res _col(5) "Variable: `cname'"
        di as txt "  {hline 65}"
        di as txt ""
        di as txt _col(5) "" _col(30) "Positive (+)" _col(50) "Negative (-)"
        di as txt "  {hline 65}"
        di as txt _col(5) "Analytical LR Multiplier" _col(28) as res %10.4f `lr_pos' _col(48) %10.4f `lr_neg'
        di as txt _col(5) "Effective LR (converged)" _col(28) as res %10.4f `eff_lr_pos' _col(48) %10.4f `eff_lr_neg'
        di as txt _col(5) "Impact Multiplier (h=0)" _col(28) as res %10.4f `theta_pos_0' _col(48) %10.4f `theta_neg_0'
        di as txt _col(5) "Impact as % of Eff. LR" _col(28) as res %9.1f `pct_pos_0' "%" _col(48) %9.1f `pct_neg_0' "%"

        // Half-life display with overshooting handling
        if `overshoot_pos' {
            di as txt _col(5) "Half-Life (+)" _col(28) as res "  Overshoot" _c
        }
        else {
            di as txt _col(5) "Half-Life (+)" _col(28) as res %10.0f `hl_pos' _c
        }
        di as txt ""
        if `overshoot_neg' {
            di as txt _col(5) "Half-Life (-)" _col(48) as res "  Overshoot"
        }
        else {
            di as txt _col(5) "Half-Life (-)" _col(48) as res %10.0f `hl_neg'
        }
        di as txt _col(5) "90% Adjustment (periods)" _col(28) as res %10.0f `adj90_pos' _col(48) %10.0f `adj90_neg'
        di as txt "  {hline 65}"

        // Interpretation notes
        if `overshoot_pos' | `overshoot_neg' {
            di as txt _col(5) "Note: 'Overshoot' = impact exceeds long-run; initial"
            di as txt _col(5) "over-reaction followed by partial reversal to equilibrium."
        }

        // Speed comparison (only meaningful without overshooting)
        if !`overshoot_pos' & !`overshoot_neg' {
            if `hl_pos' < `hl_neg' {
                di as res _col(5) "=> Positive shocks are absorbed FASTER than negative shocks."
            }
            else if `hl_pos' > `hl_neg' {
                di as res _col(5) "=> Negative shocks are absorbed FASTER than positive shocks."
            }
            else {
                di as txt _col(5) "=> Symmetric adjustment speed for positive and negative shocks."
            }
        }
        di as txt ""

        // ----- Plot: Asymmetric Adjustment Paths -----
        // Save matrices to named matrices (tempnames lost after preserve)
        mat _fbnardl_ap = `adj_pos'
        mat _fbnardl_an = `adj_neg'

        preserve
        capture noisily {
            qui clear
            qui set obs `= `horizon' + 1'
            qui gen horizon = _n - 1
            qui gen double cum_pos = .
            qui gen double cum_neg = .
            qui gen double lr_pos_line = `eff_lr_pos'
            qui gen double lr_neg_line = `eff_lr_neg'
            qui gen double hl_pos_pct = `eff_lr_pos' * 0.5
            qui gen double hl_neg_pct = `eff_lr_neg' * 0.5

            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                qui replace cum_pos = el(_fbnardl_ap, `idx', 1) in `idx'
                qui replace cum_neg = el(_fbnardl_an, `idx', 1) in `idx'
            }

            // Asymmetric adjustment path plot
            twoway (line cum_pos horizon, lcolor(navy) lwidth(medthick)) ///
                   (line cum_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                   (line lr_pos_line horizon, lcolor(navy%40) lwidth(thin) lpattern(longdash)) ///
                   (line lr_neg_line horizon, lcolor(cranberry%40) lwidth(thin) lpattern(longdash)) ///
                   (line hl_pos_pct horizon, lcolor(navy%20) lwidth(vthin) lpattern(shortdash)) ///
                   (line hl_neg_pct horizon, lcolor(cranberry%20) lwidth(vthin) lpattern(shortdash)), ///
                   title("Asymmetric Adjustment Paths — `cname'", size(medium)) ///
                   subtitle("Positive vs. Negative Shock Absorption", size(small)) ///
                   ytitle("Cumulative Multiplier", size(small)) ///
                   xtitle("Horizon", size(small)) ///
                   xline(`hl_pos', lcolor(navy%40) lwidth(vthin) lpattern(dot)) ///
                   xline(`hl_neg', lcolor(cranberry%40) lwidth(vthin) lpattern(dot)) ///
                   legend(order(1 "Positive (HL=`hl_pos')" ///
                                2 "Negative (HL=`hl_neg')" ///
                                3 "LR+ target" 4 "LR- target") ///
                       size(vsmall) rows(2) position(5) ring(0)) ///
                   yline(0, lcolor(gs12) lwidth(vthin)) ///
                   note("fbnardl — fbnardl package" ///
                        "Half-life markers shown as vertical dotted lines", size(vsmall)) ///
                   scheme(s2color) name(asymadj_`cname', replace)

            qui graph export "asymmetric_adjustment_`cname'.png", replace width(1200)
            di as txt _col(5) "Graph saved: asymmetric_adjustment_`cname'.png"

            // ----- Plot: Half-Life Bar Comparison -----
            // Only generate bar chart if at least one half-life is meaningful
            if !`overshoot_pos' | !`overshoot_neg' {
                qui clear
                qui set obs 4
                qui gen str20 category = ""
                qui gen double value = .
                qui gen byte group = .

                qui replace category = "HL(+)" in 1
                qui replace value = `= cond(`overshoot_pos', 0, `hl_pos')' in 1
                qui replace group = 1 in 1

                qui replace category = "HL(-)" in 2
                qui replace value = `= cond(`overshoot_neg', 0, `hl_neg')' in 2
                qui replace group = 2 in 2

                qui replace category = "90%(+)" in 3
                qui replace value = `adj90_pos' in 3
                qui replace group = 1 in 3

                qui replace category = "90%(-)" in 4
                qui replace value = `adj90_neg' in 4
                qui replace group = 2 in 4

                // Encode for graphing
                qui encode category, gen(cat_n)

                graph bar (asis) value, over(cat_n, label(labsize(small))) ///
                    asyvars ///
                    bar(1, color(navy%70)) bar(2, color(cranberry%70)) ///
                    bar(3, color(navy%40)) bar(4, color(cranberry%40)) ///
                    title("Adjustment Speed Comparison — `cname'", size(medium)) ///
                    subtitle("Half-Life & 90% Adjustment (periods)", size(small)) ///
                    ytitle("Periods", size(small)) ///
                    blabel(bar, format(%3.0f) size(small)) ///
                    legend(off) ///
                    note("fbnardl — fbnardl package", size(vsmall)) ///
                    scheme(s2color) name(hl_compare_`cname', replace)

                qui graph export "halflife_comparison_`cname'.png", replace width(1200)
                di as txt _col(5) "Graph saved: halflife_comparison_`cname'.png"
            }
            else {
                di as txt _col(5) "Half-life bar chart skipped (both components overshoot)."
            }
        }
        restore
        capture mat drop _fbnardl_ap
        capture mat drop _fbnardl_an
        di as txt ""
    }

    di as txt "{hline 78}"
end
