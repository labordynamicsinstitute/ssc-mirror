*! _aardl_ndynmult — Asymmetric (NARDL) dynamic multipliers for aardl
*! Version 1.0.0
*!
*! Computes and displays asymmetric cumulative dynamic multipliers
*! following Shin, Yu & Greenwood-Nimmo (2014).

capture program drop _aardl_ndynmult
program define _aardl_ndynmult
    version 17

    syntax varname(ts), ///
        DECNames(string) ///
        BEStp(integer) ///
        HORizon(integer) ///
        [NOGraph]

    local depvar "`varlist'"

    di as txt "{hline 78}"
    di as res _col(5) "Table 5: Asymmetric Dynamic Multipliers"
    di as txt _col(5) "{it:Shin, Yu & Greenwood-Nimmo (2014)}"
    di as txt "{hline 78}"
    di as txt ""

    local alpha = _b[L.`depvar']

    foreach cname of local decnames {
        // Long-run multipliers
        capture local lr_pos = -_b[L.`cname'_pos] / _b[L.`depvar']
        if _rc != 0 local lr_pos = 0
        capture local lr_neg = -_b[L.`cname'_neg] / _b[L.`depvar']
        if _rc != 0 local lr_neg = 0

        // Impact multipliers
        capture local theta0_pos = _b[D.`cname'_pos]
        if _rc != 0 local theta0_pos = 0
        capture local theta0_neg = _b[D.`cname'_neg]
        if _rc != 0 local theta0_neg = 0

        di as txt _col(5) "Variable: `cname'"
        di as txt _col(7) "Positive LR multiplier = " as res %10.6f `lr_pos'
        di as txt _col(7) "Negative LR multiplier = " as res %10.6f `lr_neg'

        // Compute asymmetric multiplier paths
        tempname dm_pos dm_neg
        mat `dm_pos' = J(`horizon' + 1, 3, .)
        mat `dm_neg' = J(`horizon' + 1, 3, .)

        // Positive path
        mat `dm_pos'[1, 1] = 0
        mat `dm_pos'[1, 2] = `theta0_pos'
        mat `dm_pos'[1, 3] = `theta0_pos'

        // Negative path
        mat `dm_neg'[1, 1] = 0
        mat `dm_neg'[1, 2] = `theta0_neg'
        mat `dm_neg'[1, 3] = `theta0_neg'

        forvalues h = 1/`horizon' {
            // Positive
            local prev_cum_p = el(`dm_pos', `h', 3)
            local this_dm_p = `alpha' * (`prev_cum_p' - `lr_pos')
            local this_cum_p = `prev_cum_p' + `this_dm_p'
            mat `dm_pos'[`h' + 1, 1] = `h'
            mat `dm_pos'[`h' + 1, 2] = `this_dm_p'
            mat `dm_pos'[`h' + 1, 3] = `this_cum_p'

            // Negative
            local prev_cum_n = el(`dm_neg', `h', 3)
            local this_dm_n = `alpha' * (`prev_cum_n' - `lr_neg')
            local this_cum_n = `prev_cum_n' + `this_dm_n'
            mat `dm_neg'[`h' + 1, 1] = `h'
            mat `dm_neg'[`h' + 1, 2] = `this_dm_n'
            mat `dm_neg'[`h' + 1, 3] = `this_cum_n'
        }

        // Display
        di as txt ""
        di as txt _col(7) "h" _col(15) "Cum (+)" _col(30) "Cum (-)" _col(45) "Difference"
        di as txt _col(7) "{hline 45}"
        forvalues h = 0/`horizon' {
            if `h' <= 5 | `h' == `horizon' {
                local cp = el(`dm_pos', `h' + 1, 3)
                local cn = el(`dm_neg', `h' + 1, 3)
                local diff = `cp' - `cn'
                di as txt _col(7) %3.0f `h' ///
                   _col(13) as res %12.6f `cp' ///
                   _col(28) %12.6f `cn' ///
                   _col(43) %12.6f `diff'
            }
            else if `h' == 6 {
                di as txt _col(7) "..."
            }
        }
        di as txt ""

        // Graph
        if "`nograph'" == "" {
            mat _aardl_dmp_`cname' = `dm_pos'
            mat _aardl_dmn_`cname' = `dm_neg'

            tempfile _ndm_tmpdata
            qui save `_ndm_tmpdata', replace

            capture noisily {
                qui clear
                local nrows = `horizon' + 1
                qui set obs `nrows'
                qui gen h = .
                qui gen cum_pos = .
                qui gen cum_neg = .
                qui gen lr_pos_line = `lr_pos'
                qui gen lr_neg_line = `lr_neg'

                forvalues i = 1/`nrows' {
                    qui replace h = el(_aardl_dmp_`cname', `i', 1) in `i'
                    qui replace cum_pos = el(_aardl_dmp_`cname', `i', 3) in `i'
                    qui replace cum_neg = el(_aardl_dmn_`cname', `i', 3) in `i'
                }

                twoway (connected cum_pos h, lcolor("31 119 180") mcolor("31 119 180") ///
                        msize(small) lwidth(medthick)) ///
                       (connected cum_neg h, lcolor("214 39 40") mcolor("214 39 40") ///
                        msize(small) lwidth(medthick)) ///
                       (line lr_pos_line h, lcolor("31 119 180") lpattern(dash) lwidth(thin)) ///
                       (line lr_neg_line h, lcolor("214 39 40") lpattern(dash) lwidth(thin)), ///
                       title("Asymmetric Dynamic Multipliers: `cname'", size(medium)) ///
                       subtitle("Shin, Yu & Greenwood-Nimmo (2014)", size(small)) ///
                       ytitle("Cumulative Effect", size(small)) ///
                       xtitle("Horizon", size(small)) ///
                       legend(order(1 "Positive shock" 2 "Negative shock" ///
                              3 "LR (+)" 4 "LR (-)") size(small) rows(1)) ///
                       scheme(s2color) name(aardl_asym_`cname', replace)
            }

            qui use `_ndm_tmpdata', clear
            capture mat drop _aardl_dmp_`cname'
            capture mat drop _aardl_dmn_`cname'
        }
    }

end
