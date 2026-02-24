*! _aardl_dynmult — Linear dynamic multipliers for aardl
*! Version 1.0.0

capture program drop _aardl_dynmult
program define _aardl_dynmult
    version 17

    syntax varname(ts), ///
        INDEPvars(string) ///
        BEStp(integer) ///
        HORizon(integer) ///
        [NOGraph]

    local depvar "`varlist'"

    di as txt "{hline 78}"
    di as res _col(5) "Table 5: Dynamic Multipliers"
    di as txt "{hline 78}"
    di as txt ""

    // ECM coefficient (speed of adjustment)
    local alpha = _b[L.`depvar']

    // For each independent variable, compute its dynamic multiplier
    foreach xvar of local indepvars {
        // Impact multiplier: coefficient on D.xvar
        capture local theta0 = _b[D.`xvar']
        if _rc != 0 local theta0 = 0

        // Long-run multiplier: -b[L.xvar] / b[L.depvar]
        capture local lr_mult = -_b[L.`xvar'] / _b[L.`depvar']
        if _rc != 0 local lr_mult = 0

        di as txt _col(5) "Variable: `xvar'"
        di as txt _col(7) "Impact multiplier   = " as res %10.6f `theta0'
        di as txt _col(7) "Long-run multiplier = " as res %10.6f `lr_mult'

        // Compute dynamic multiplier path
        // m(0) = theta0
        // m(h) = alpha * m(h-1) + (lagged diff coefficients)
        // Cumulative: M(h) = Σ_{j=0}^{h} m(j)

        tempname dm_mat
        mat `dm_mat' = J(`horizon' + 1, 3, .)
        // col 1 = horizon, col 2 = dynamic mult, col 3 = cumulative

        mat `dm_mat'[1, 1] = 0
        mat `dm_mat'[1, 2] = `theta0'
        mat `dm_mat'[1, 3] = `theta0'

        forvalues h = 1/`horizon' {
            // Simple recursive: m(h) = m(h-1) + alpha * (M(h-1) - LR)
            // This is a simplified version based on ECM dynamics
            local prev_cum = el(`dm_mat', `h', 3)
            local this_dm = `alpha' * (`prev_cum' - `lr_mult')
            local this_cum = `prev_cum' + `this_dm'

            mat `dm_mat'[`h' + 1, 1] = `h'
            mat `dm_mat'[`h' + 1, 2] = `this_dm'
            mat `dm_mat'[`h' + 1, 3] = `this_cum'
        }

        // Display first few periods
        di as txt ""
        di as txt _col(7) "h" _col(15) "Dynamic" _col(30) "Cumulative"
        di as txt _col(7) "{hline 35}"
        forvalues h = 0/`horizon' {
            if `h' <= 5 | `h' == `horizon' {
                di as txt _col(7) %3.0f el(`dm_mat', `h' + 1, 1) ///
                   _col(13) as res %12.6f el(`dm_mat', `h' + 1, 2) ///
                   _col(28) %12.6f el(`dm_mat', `h' + 1, 3)
            }
            else if `h' == 6 {
                di as txt _col(7) "..."
            }
        }
        di as txt ""

        // Graph
        if "`nograph'" == "" {
            local cname = subinstr("`xvar'", ".", "_", .)
            mat _aardl_dm_`cname' = `dm_mat'

            tempfile _dm_tmpdata
            qui save `_dm_tmpdata', replace

            capture noisily {
                qui clear
                local nrows = `horizon' + 1
                qui set obs `nrows'
                qui gen h = .
                qui gen dm = .
                qui gen cumm = .
                qui gen lr = `lr_mult'

                forvalues i = 1/`nrows' {
                    qui replace h = el(_aardl_dm_`cname', `i', 1) in `i'
                    qui replace dm = el(_aardl_dm_`cname', `i', 2) in `i'
                    qui replace cumm = el(_aardl_dm_`cname', `i', 3) in `i'
                }

                twoway (connected cumm h, lcolor("31 119 180") mcolor("31 119 180") ///
                        msize(small) lwidth(medthick)) ///
                       (line lr h, lcolor("214 39 40") lpattern(dash) lwidth(medium)), ///
                       title("Cumulative Dynamic Multiplier: `xvar'", size(medium)) ///
                       ytitle("Cumulative Effect", size(small)) ///
                       xtitle("Horizon", size(small)) ///
                       legend(order(1 "Cumulative Multiplier" 2 "Long-run Equilibrium") ///
                              size(small) rows(1)) ///
                       scheme(s2color) name(aardl_dm_`cname', replace)
            }

            qui use `_dm_tmpdata', clear
            capture mat drop _aardl_dm_`cname'
        }
    }

end
