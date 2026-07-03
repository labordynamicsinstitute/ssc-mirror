*! _wavenardl_dynmult 1.0.1  02jul2026 - dynamic multipliers for wavenardl
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Cumulative dynamic multipliers m_h from the levels-ARDL representation
*! of the estimated ECM (Shin, Yu & Greenwood-Nimmo 2014). With
*!   D.y = rho*L.y + sum gamma_i*Li.D.y + theta*L.x + sum beta_j*Lj.D.x
*! the levels form y_t = sum a_i*y_{t-i} + sum b_j*x_{t-j} has
*!   a_1 = 1 + rho + gamma_1,  a_i = gamma_i - gamma_{i-1},  a_{p+1} = -gamma_p
*!   b_0 = beta_0,  b_1 = theta + beta_1 - beta_0,
*!   b_j = beta_j - beta_{j-1},  b_{q+1} = -beta_q
*! and the response to a permanent unit step in x is
*!   m_h = sum_{j<=min(h,q+1)} b_j + sum_{i<=min(h,p+1)} a_i * m_{h-i}
*! which converges to the long-run multiplier -theta/rho as h grows.

capture program drop _wavenardl_dynmult
program define _wavenardl_dynmult
    version 17

    syntax, depvar(string) decnames(string) ecmcoef(string) ///
        p(integer) q(integer) horizon(integer) ///
        [controls(string) r(integer 0) NOGraph]

    di as txt ""
    di as txt "{hline 70}"
    di as res "  Dynamic Multipliers (Shin, Yu & Greenwood-Nimmo 2014)"
    di as txt "{hline 70}"
    di as txt "  m(h) = response of `depvar' to a permanent unit change in the"
    di as txt "  regressor; m(h) converges to the long-run multiplier."

    // ---- shared levels-AR coefficients a_1 .. a_{p+1} ----
    local rho = _b[`ecmcoef']

    forvalues j = 1/`p' {
        capture local gam_`j' = _b[L`j'.D.`depvar']
        if _rc != 0 local gam_`j' = 0
    }

    local pA = `p' + 1
    if `p' == 0 {
        local a_1 = 1 + `rho'
    }
    else {
        local a_1 = 1 + `rho' + `gam_1'
        forvalues i = 2/`p' {
            local im1 = `i' - 1
            local a_`i' = `gam_`i'' - `gam_`im1''
        }
        local a_`pA' = -`gam_`p''
    }

    // =====================================================================
    // A. DECOMPOSED VARIABLES (positive / negative components)
    // =====================================================================
    foreach cname of local decnames {

        foreach sgn in pos neg {
            // theta and beta_j for this component
            capture local th_`sgn' = _b[L.`cname'_`sgn']
            if _rc != 0 local th_`sgn' = 0
            capture local be_`sgn'_0 = _b[D.`cname'_`sgn']
            if _rc != 0 local be_`sgn'_0 = 0
            forvalues j = 1/`q' {
                capture local be_`sgn'_`j' = _b[L`j'.D.`cname'_`sgn']
                if _rc != 0 local be_`sgn'_`j' = 0
            }

            // levels-x coefficients b_0 .. b_{q+1}
            local qB = `q' + 1
            local b_`sgn'_0 = `be_`sgn'_0'
            if `q' == 0 {
                local b_`sgn'_1 = `th_`sgn'' - `be_`sgn'_0'
            }
            else {
                local b_`sgn'_1 = `th_`sgn'' + `be_`sgn'_1' - `be_`sgn'_0'
                forvalues j = 2/`q' {
                    local jm1 = `j' - 1
                    local b_`sgn'_`j' = `be_`sgn'_`j'' - `be_`sgn'_`jm1''
                }
                local b_`sgn'_`qB' = -`be_`sgn'_`q''
            }
        }

        // long-run multipliers
        local lr_pos = -`th_pos' / `rho'
        local lr_neg = -`th_neg' / `rho'

        // ---- step-response recursion ----
        tempname m_pos m_neg
        mat `m_pos' = J(`horizon' + 1, 1, 0)
        mat `m_neg' = J(`horizon' + 1, 1, 0)
        local qB = `q' + 1

        forvalues h = 0/`horizon' {
            local idx = `h' + 1

            foreach sgn in pos neg {
                // step effect: sum of b_j for j = 0..min(h, q+1)
                local xs = 0
                local jtop = min(`h', `qB')
                forvalues j = 0/`jtop' {
                    local xs = `xs' + `b_`sgn'_`j''
                }
                // AR feedback: sum of a_i * m_{h-i} for i = 1..min(h, p+1)
                local ar = 0
                local itop = min(`h', `pA')
                forvalues i = 1/`itop' {
                    local prev_idx = `h' - `i' + 1
                    local ar = `ar' + `a_`i'' * el(`m_`sgn'', `prev_idx', 1)
                }
                mat `m_`sgn''[`idx', 1] = `xs' + `ar'
            }
        }

        di as txt ""
        di as txt "  Variable: `cname' (decomposed)"
        di as txt "  Long-Run Multiplier (Positive): " as res %8.4f `lr_pos'
        di as txt "  Long-Run Multiplier (Negative): " as res %8.4f `lr_neg'
        di as txt ""
        di as txt "  {hline 55}"
        di as txt "  " _col(3) "Horizon" _col(14) "m(+)" _col(26) "m(-)" _col(36) "Asymmetry"
        di as txt "  {hline 55}"

        forvalues h = 0/`horizon' {
            local idx = `h' + 1
            local mp = el(`m_pos', `idx', 1)
            local mn = el(`m_neg', `idx', 1)
            local as_h = `mp' - `mn'
            di as txt "  " _col(5) %3.0f `h' _col(12) %8.4f `mp' _col(24) %8.4f `mn' _col(37) %8.4f `as_h'
        }
        di as txt "  {hline 55}"
        di as txt "  " _col(5) "LR" _col(12) %8.4f `lr_pos' _col(24) %8.4f `lr_neg' _col(37) %8.4f `= `lr_pos' - `lr_neg''
        di as txt "  {hline 55}"

        if "`nograph'" == "" {
            mat _wnardl_gm_pos = `m_pos'
            mat _wnardl_gm_neg = `m_neg'

            preserve
            capture noisily {
                qui clear
                qui set obs `= `horizon' + 1'
                qui gen horizon = _n - 1
                qui gen double m_pos = .
                qui gen double m_neg = .

                forvalues h = 0/`horizon' {
                    local idx = `h' + 1
                    qui replace m_pos = el(_wnardl_gm_pos, `idx', 1) in `idx'
                    qui replace m_neg = el(_wnardl_gm_neg, `idx', 1) in `idx'
                }

                qui gen double asym = m_pos - m_neg
                qui gen double lr_pos_line = `lr_pos'
                qui gen double lr_neg_line = `lr_neg'

                twoway (line m_pos horizon, lcolor(blue) lwidth(medthick)) ///
                       (line m_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                       (line lr_pos_line horizon, lcolor(blue) lwidth(thin) lpattern(longdash)) ///
                       (line lr_neg_line horizon, lcolor(cranberry) lwidth(thin) lpattern(longdash)), ///
                       title("Dynamic Multipliers - `cname'", size(medium)) ///
                       subtitle("W-NARDL Model", size(small)) ///
                       ytitle("Multiplier", size(small)) xtitle("Horizon", size(small)) ///
                       legend(order(1 "m(+)" 2 "m(-)" 3 "LR(+)" 4 "LR(-)") size(small) rows(1)) ///
                       yline(0, lcolor(gs10) lpattern(shortdash)) ///
                       note("wavenardl package", size(vsmall)) ///
                       name(dynmult_`cname', replace)

                twoway (line asym horizon, lcolor(dkgreen) lwidth(medthick)), ///
                       title("Multiplier Asymmetry - `cname'", size(medium)) ///
                       subtitle("m(+) minus m(-)", size(small)) ///
                       ytitle("Asymmetry", size(small)) xtitle("Horizon", size(small)) ///
                       legend(off) ///
                       yline(0, lcolor(gs10) lpattern(shortdash)) ///
                       note("wavenardl package", size(vsmall)) ///
                       name(asym_`cname', replace)
            }
            capture qui graph export "dynmult_`cname'.png", replace width(1200)
            local rc1 = _rc
            capture qui graph export "asym_`cname'.png", replace width(1200)
            if `rc1' == 0 & _rc == 0 {
                di as txt "  Graphs saved: dynmult_`cname'.png, asym_`cname'.png"
            }
            else {
                di as txt "  (graphs displayed; export skipped - cannot write to the current directory)"
            }
            restore
            capture mat drop _wnardl_gm_pos
            capture mat drop _wnardl_gm_neg
        }
    }

    // =====================================================================
    // B. CONTROL (NON-DECOMPOSED) VARIABLES
    // =====================================================================
    if "`controls'" != "" {
        foreach cvar of local controls {

            capture local th_c = _b[L.`cvar']
            if _rc != 0 local th_c = 0
            capture local be_c_0 = _b[D.`cvar']
            if _rc != 0 local be_c_0 = 0
            forvalues j = 1/`r' {
                capture local be_c_`j' = _b[L`j'.D.`cvar']
                if _rc != 0 local be_c_`j' = 0
            }

            local rB = `r' + 1
            local b_c_0 = `be_c_0'
            if `r' == 0 {
                local b_c_1 = `th_c' - `be_c_0'
            }
            else {
                local b_c_1 = `th_c' + `be_c_1' - `be_c_0'
                forvalues j = 2/`r' {
                    local jm1 = `j' - 1
                    local b_c_`j' = `be_c_`j'' - `be_c_`jm1''
                }
                local b_c_`rB' = -`be_c_`r''
            }

            local lr_ctrl = -`th_c' / `rho'

            tempname m_ctrl
            mat `m_ctrl' = J(`horizon' + 1, 1, 0)

            forvalues h = 0/`horizon' {
                local idx = `h' + 1

                local xs = 0
                local jtop = min(`h', `rB')
                forvalues j = 0/`jtop' {
                    local xs = `xs' + `b_c_`j''
                }
                local ar = 0
                local itop = min(`h', `pA')
                forvalues i = 1/`itop' {
                    local prev_idx = `h' - `i' + 1
                    local ar = `ar' + `a_`i'' * el(`m_ctrl', `prev_idx', 1)
                }
                mat `m_ctrl'[`idx', 1] = `xs' + `ar'
            }

            di as txt ""
            di as txt "  Variable: `cvar' (non-decomposed)"
            di as txt "  Long-Run Multiplier: " as res %8.4f `lr_ctrl'
            di as txt ""
            di as txt "  {hline 40}"
            di as txt "  " _col(3) "Horizon" _col(18) "m(h)"
            di as txt "  {hline 40}"

            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                local md = el(`m_ctrl', `idx', 1)
                di as txt "  " _col(5) %3.0f `h' _col(15) %8.4f `md'
            }
            di as txt "  {hline 40}"
            di as txt "  " _col(5) "LR" _col(15) %8.4f `lr_ctrl'
            di as txt "  {hline 40}"

            if "`nograph'" == "" {
                mat _wnardl_gm_ctrl = `m_ctrl'

                preserve
                capture noisily {
                    qui clear
                    qui set obs `= `horizon' + 1'
                    qui gen horizon = _n - 1
                    qui gen double m_ctrl = .

                    forvalues h = 0/`horizon' {
                        local idx = `h' + 1
                        qui replace m_ctrl = el(_wnardl_gm_ctrl, `idx', 1) in `idx'
                    }

                    qui gen double lr_line = `lr_ctrl'

                    twoway (line m_ctrl horizon, lcolor(navy) lwidth(medthick)) ///
                           (line lr_line horizon, lcolor(green) lwidth(thin) lpattern(longdash)), ///
                           title("Dynamic Multipliers - `cvar'", size(medium)) ///
                           subtitle("W-NARDL Model (non-decomposed)", size(small)) ///
                           ytitle("Multiplier", size(small)) xtitle("Horizon", size(small)) ///
                           legend(order(1 "m(h)" 2 "Long-Run") size(small) rows(1)) ///
                           yline(0, lcolor(gs10) lpattern(shortdash)) ///
                           note("wavenardl package", size(vsmall)) ///
                           name(dynmult_`cvar', replace)
                }
                capture qui graph export "dynmult_`cvar'.png", replace width(1200)
                if _rc == 0 {
                    di as txt "  Graphs saved: dynmult_`cvar'.png"
                }
                else {
                    di as txt "  (graph displayed; export skipped - cannot write to the current directory)"
                }
                restore
                capture mat drop _wnardl_gm_ctrl
            }
        }
    }

    di as txt "{hline 70}"
end
