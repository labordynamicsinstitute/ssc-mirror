*! _fbnardl_dynmult — Dynamic Multipliers for FBNARDL
*! Author: fbnardl (merwanroudane920@gmail.com)

capture program drop _fbnardl_dynmult
program define _fbnardl_dynmult
    version 17

    syntax, depvar(string) decnames(string) ecmcoef(string) ///
        p(integer) q(integer) horizon(integer) ///
        [controls(string) r(integer 0)]

    di as txt ""
    di as txt "{hline 70}"
    di as res "  Dynamic Multipliers"
    di as txt "{hline 70}"

    // Get ECM coefficient (speed of adjustment)
    local alpha = _b[`ecmcoef']

    // AR coefficients (lags of D.depvar) — shared across all variables
    forvalues j = 1/`p' {
        capture local phi_`j' = _b[L`j'.D.`depvar']
        if _rc != 0 local phi_`j' = 0
    }

    // =====================================================================
    // A. DECOMPOSED VARIABLES (pos/neg split)
    // =====================================================================
    foreach cname of local decnames {

        // Get coefficients for pos and neg components
        // Contemporaneous (D.xpos, D.xneg)
        capture local theta_pos_0 = _b[D.`cname'_pos]
        if _rc != 0 local theta_pos_0 = 0
        capture local theta_neg_0 = _b[D.`cname'_neg]
        if _rc != 0 local theta_neg_0 = 0

        // Lagged differences
        forvalues j = 1/`q' {
            capture local theta_pos_`j' = _b[L`j'.D.`cname'_pos]
            if _rc != 0 local theta_pos_`j' = 0
            capture local theta_neg_`j' = _b[L`j'.D.`cname'_neg]
            if _rc != 0 local theta_neg_`j' = 0
        }

        // Long-run coefficients
        capture local lr_pos = -_b[L.`cname'_pos] / `alpha'
        if _rc != 0 local lr_pos = 0
        capture local lr_neg = -_b[L.`cname'_neg] / `alpha'
        if _rc != 0 local lr_neg = 0

        // Compute dynamic multipliers via recursive formula
        // m_h = theta_h + sum_{j=1}^{min(h,p)} phi_j * m_{h-j}
        tempname mult_pos cum_pos mult_neg cum_neg horizons
        mat `mult_pos' = J(`horizon' + 1, 1, 0)
        mat `cum_pos'  = J(`horizon' + 1, 1, 0)
        mat `mult_neg' = J(`horizon' + 1, 1, 0)
        mat `cum_neg'  = J(`horizon' + 1, 1, 0)
        mat `horizons' = J(`horizon' + 1, 1, 0)

        forvalues h = 0/`horizon' {
            local idx = `h' + 1
            mat `horizons'[`idx', 1] = `h'

            // Direct effect at horizon h
            if `h' <= `q' {
                local direct_pos = `theta_pos_`h''
                local direct_neg = `theta_neg_`h''
            }
            else {
                local direct_pos = 0
                local direct_neg = 0
            }

            // Add AR feedback
            local ar_pos = 0
            local ar_neg = 0
            local jmax = min(`h', `p')
            forvalues j = 1/`jmax' {
                local prev_idx = `h' - `j' + 1
                local ar_pos = `ar_pos' + `phi_`j'' * el(`mult_pos', `prev_idx', 1)
                local ar_neg = `ar_neg' + `phi_`j'' * el(`mult_neg', `prev_idx', 1)
            }

            mat `mult_pos'[`idx', 1] = `direct_pos' + `ar_pos'
            mat `mult_neg'[`idx', 1] = `direct_neg' + `ar_neg'

            // Cumulative
            if `h' == 0 {
                mat `cum_pos'[`idx', 1] = el(`mult_pos', `idx', 1)
                mat `cum_neg'[`idx', 1] = el(`mult_neg', `idx', 1)
            }
            else {
                mat `cum_pos'[`idx', 1] = el(`cum_pos', `idx' - 1, 1) + el(`mult_pos', `idx', 1)
                mat `cum_neg'[`idx', 1] = el(`cum_neg', `idx' - 1, 1) + el(`mult_neg', `idx', 1)
            }
        }

        // Display table
        di as txt ""
        di as txt "  Variable: `cname' (decomposed)"
        di as txt "  Long-Run Multiplier (Positive): " as res %8.4f `lr_pos'
        di as txt "  Long-Run Multiplier (Negative): " as res %8.4f `lr_neg'
        di as txt ""
        di as txt "  {hline 55}"
        di as txt "  " _col(3) "Horizon" _col(13) "Dyn(+)" _col(24) "Cum(+)" _col(35) "Dyn(-)" _col(46) "Cum(-)"
        di as txt "  {hline 55}"

        forvalues h = 0/`horizon' {
            local idx = `h' + 1
            local mp = el(`mult_pos', `idx', 1)
            local cp = el(`cum_pos', `idx', 1)
            local mn = el(`mult_neg', `idx', 1)
            local cn = el(`cum_neg', `idx', 1)

            di as txt "  " _col(5) %3.0f `h' _col(13) %8.4f `mp' _col(24) %8.4f `cp' _col(35) %8.4f `mn' _col(46) %8.4f `cn'
        }
        di as txt "  {hline 55}"

        // =====================================================================
        // Plot dynamic multipliers (decomposed)
        // =====================================================================
        mat _fbnardl_gm_pos = `mult_pos'
        mat _fbnardl_gc_pos = `cum_pos'
        mat _fbnardl_gm_neg = `mult_neg'
        mat _fbnardl_gc_neg = `cum_neg'

        preserve
        capture noisily {
            qui clear
            qui set obs `= `horizon' + 1'
            qui gen horizon = _n - 1
            qui gen double dyn_pos = .
            qui gen double cum_pos = .
            qui gen double dyn_neg = .
            qui gen double cum_neg = .

            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                qui replace dyn_pos = el(_fbnardl_gm_pos, `idx', 1) in `idx'
                qui replace cum_pos = el(_fbnardl_gc_pos, `idx', 1) in `idx'
                qui replace dyn_neg = el(_fbnardl_gm_neg, `idx', 1) in `idx'
                qui replace cum_neg = el(_fbnardl_gc_neg, `idx', 1) in `idx'
            }

            qui gen double lr_pos_line = `lr_pos'
            qui gen double lr_neg_line = `lr_neg'

            // Dynamic multiplier plot
            twoway (line dyn_pos horizon, lcolor(blue) lwidth(medthick)) ///
                   (line dyn_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)), ///
                   title("Dynamic Multipliers — `cname'", size(medium)) ///
                   subtitle("FBNARDL Model", size(small)) ///
                   ytitle("Multiplier", size(small)) xtitle("Horizon", size(small)) ///
                   legend(order(1 "Positive" 2 "Negative") size(small) rows(1)) ///
                   yline(0, lcolor(gs10) lpattern(shortdash)) ///
                   note("fbnardl — fbnardl package", size(vsmall)) ///
                   scheme(s2color) name(dynmult_`cname', replace)

            qui graph export "dynmult_`cname'.png", replace width(1200)

            // Cumulative multiplier plot
            twoway (line cum_pos horizon, lcolor(blue) lwidth(medthick)) ///
                   (line cum_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                   (line lr_pos_line horizon, lcolor(green) lwidth(thin) lpattern(longdash)) ///
                   (line lr_neg_line horizon, lcolor(orange) lwidth(thin) lpattern(longdash)), ///
                   title("Cumulative Multipliers — `cname'", size(medium)) ///
                   subtitle("FBNARDL Model", size(small)) ///
                   ytitle("Cumulative Effect", size(small)) xtitle("Horizon", size(small)) ///
                   legend(order(1 "Cumul. Pos" 2 "Cumul. Neg" 3 "LR Pos" 4 "LR Neg") size(small) rows(1)) ///
                   yline(0, lcolor(gs10) lpattern(shortdash)) ///
                   note("fbnardl — fbnardl package", size(vsmall)) ///
                   scheme(s2color) name(cummult_`cname', replace)

            qui graph export "cummult_`cname'.png", replace width(1200)

            di as txt "  Graphs saved: dynmult_`cname'.png, cummult_`cname'.png"
        }
        restore
        capture mat drop _fbnardl_gm_pos
        capture mat drop _fbnardl_gc_pos
        capture mat drop _fbnardl_gm_neg
        capture mat drop _fbnardl_gc_neg
    }

    // =====================================================================
    // B. CONTROL (NON-DECOMPOSED) VARIABLES — single multiplier path
    // =====================================================================
    if "`controls'" != "" {
        foreach cvar of local controls {

            // Contemporaneous and lagged short-run coefficients
            capture local theta_0 = _b[D.`cvar']
            if _rc != 0 local theta_0 = 0

            forvalues j = 1/`r' {
                capture local theta_`j' = _b[L`j'.D.`cvar']
                if _rc != 0 local theta_`j' = 0
            }

            // Long-run coefficient
            capture local lr_ctrl = -_b[L.`cvar'] / `alpha'
            if _rc != 0 local lr_ctrl = 0

            // Compute dynamic multipliers
            tempname mult_ctrl cum_ctrl
            mat `mult_ctrl' = J(`horizon' + 1, 1, 0)
            mat `cum_ctrl'  = J(`horizon' + 1, 1, 0)

            forvalues h = 0/`horizon' {
                local idx = `h' + 1

                // Direct effect at horizon h
                if `h' <= `r' {
                    local direct = `theta_`h''
                }
                else {
                    local direct = 0
                }

                // AR feedback
                local ar_val = 0
                local jmax = min(`h', `p')
                forvalues j = 1/`jmax' {
                    local prev_idx = `h' - `j' + 1
                    local ar_val = `ar_val' + `phi_`j'' * el(`mult_ctrl', `prev_idx', 1)
                }

                mat `mult_ctrl'[`idx', 1] = `direct' + `ar_val'

                // Cumulative
                if `h' == 0 {
                    mat `cum_ctrl'[`idx', 1] = el(`mult_ctrl', `idx', 1)
                }
                else {
                    mat `cum_ctrl'[`idx', 1] = el(`cum_ctrl', `idx' - 1, 1) + el(`mult_ctrl', `idx', 1)
                }
            }

            // Display table
            di as txt ""
            di as txt "  Variable: `cvar' (non-decomposed)"
            di as txt "  Long-Run Multiplier: " as res %8.4f `lr_ctrl'
            di as txt ""
            di as txt "  {hline 40}"
            di as txt "  " _col(3) "Horizon" _col(15) "Dynamic" _col(28) "Cumulative"
            di as txt "  {hline 40}"

            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local md = el(`mult_ctrl', `idx', 1)
                local cd = el(`cum_ctrl', `idx', 1)

                di as txt "  " _col(5) %3.0f `h' _col(15) %8.4f `md' _col(28) %8.4f `cd'
            }
            di as txt "  {hline 40}"

            // =====================================================================
            // Plot dynamic multipliers (control)
            // =====================================================================
            mat _fbnardl_gm_ctrl = `mult_ctrl'
            mat _fbnardl_gc_ctrl = `cum_ctrl'

            preserve
            capture noisily {
                qui clear
                qui set obs `= `horizon' + 1'
                qui gen horizon = _n - 1
                qui gen double dyn_ctrl = .
                qui gen double cum_ctrl = .

                forvalues h = 0/`horizon' {
                    local idx = `h' + 1
                    qui replace dyn_ctrl = el(_fbnardl_gm_ctrl, `idx', 1) in `idx'
                    qui replace cum_ctrl = el(_fbnardl_gc_ctrl, `idx', 1) in `idx'
                }

                qui gen double lr_line = `lr_ctrl'

                // Dynamic multiplier plot
                twoway (line dyn_ctrl horizon, lcolor(navy) lwidth(medthick)), ///
                       title("Dynamic Multipliers — `cvar'", size(medium)) ///
                       subtitle("FBNARDL Model (non-decomposed)", size(small)) ///
                       ytitle("Multiplier", size(small)) xtitle("Horizon", size(small)) ///
                       legend(off) ///
                       yline(0, lcolor(gs10) lpattern(shortdash)) ///
                       note("fbnardl — fbnardl package", size(vsmall)) ///
                       scheme(s2color) name(dynmult_`cvar', replace)

                qui graph export "dynmult_`cvar'.png", replace width(1200)

                // Cumulative multiplier plot with LR target
                twoway (line cum_ctrl horizon, lcolor(navy) lwidth(medthick)) ///
                       (line lr_line horizon, lcolor(green) lwidth(thin) lpattern(longdash)), ///
                       title("Cumulative Multipliers — `cvar'", size(medium)) ///
                       subtitle("FBNARDL Model (non-decomposed)", size(small)) ///
                       ytitle("Cumulative Effect", size(small)) xtitle("Horizon", size(small)) ///
                       legend(order(1 "Cumulative" 2 "Long-Run") size(small) rows(1)) ///
                       yline(0, lcolor(gs10) lpattern(shortdash)) ///
                       note("fbnardl — fbnardl package", size(vsmall)) ///
                       scheme(s2color) name(cummult_`cvar', replace)

                qui graph export "cummult_`cvar'.png", replace width(1200)

                di as txt "  Graphs saved: dynmult_`cvar'.png, cummult_`cvar'.png"
            }
            restore
            capture mat drop _fbnardl_gm_ctrl
            capture mat drop _fbnardl_gc_ctrl
        }
    }

    di as txt "{hline 70}"
end
