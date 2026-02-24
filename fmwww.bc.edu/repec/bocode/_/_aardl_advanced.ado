*! _aardl_advanced — Advanced post-estimation analysis for aardl
*! Version 1.0.0
*!
*! Includes: half-life, persistence profile, Fourier significance test,
*!           long-run equilibrium table

capture program drop _aardl_advanced
program define _aardl_advanced
    version 17

    syntax varname(ts), ///
        INDEPvars(string) ///
        ECMcoef(real) ///
        Level(cilevel) ///
        KSTAR(real) ///
        HORizon(integer) ///
        [NOGraph]

    local depvar "`varlist'"

    di as txt "{hline 78}"
    di as res _col(5) "Table 6: Advanced Analysis"
    di as txt "{hline 78}"
    di as txt ""

    // ─── Half-Life ───
    // Based on ECM coefficient: t_{1/2} = -ln(2) / ln(1 + alpha)
    local alpha = `ecmcoef'
    if `alpha' < 0 & `alpha' > -1 {
        local halflife = -ln(2) / ln(1 + `alpha')
        di as txt _col(5) "{bf:Half-Life Analysis}"
        di as txt _col(7) "ECM coefficient (alpha)  = " as res %10.6f `alpha'
        di as txt _col(7) "Half-life (periods)      = " as res %10.4f `halflife'
        di as txt ""
    }
    else {
        di as txt _col(5) "{bf:Half-Life Analysis}"
        di as txt _col(7) "ECM coefficient (alpha) = " as res %10.6f `alpha'
        di as txt _col(7) "Half-life: " as err "not computable (alpha not in (-1, 0))"
        di as txt ""
    }

    // ─── Persistence Profile ───
    di as txt _col(5) "{bf:Persistence Profile}"
    di as txt ""

    if `alpha' < 0 & `alpha' > -2 {
        tempname pp_mat
        mat `pp_mat' = J(`horizon' + 1, 2, .)

        forvalues h = 0/`horizon' {
            local pp = (1 + `alpha')^`h'
            mat `pp_mat'[`h' + 1, 1] = `h'
            mat `pp_mat'[`h' + 1, 2] = `pp'
        }

        di as txt _col(7) "h" _col(20) "Persistence"
        di as txt _col(7) "{hline 25}"
        forvalues h = 0/`horizon' {
            if `h' <= 5 | `h' == 10 | `h' == `horizon' {
                di as txt _col(7) %3.0f `h' _col(18) as res %10.6f el(`pp_mat', `h' + 1, 2)
            }
            else if `h' == 6 {
                di as txt _col(7) "..."
            }
        }
        di as txt ""

        // Graph
        if "`nograph'" == "" {
            mat _aardl_pp = `pp_mat'
            tempfile _pp_tmpdata
            qui save `_pp_tmpdata', replace

            capture noisily {
                qui clear
                local nrows = `horizon' + 1
                qui set obs `nrows'
                qui gen h = .
                qui gen pp = .

                forvalues i = 1/`nrows' {
                    qui replace h = el(_aardl_pp, `i', 1) in `i'
                    qui replace pp = el(_aardl_pp, `i', 2) in `i'
                }

                twoway (connected pp h, lcolor("44 160 44") mcolor("44 160 44") ///
                        msize(small) lwidth(medthick)) ///
                       (scatteri 0.5 0 0.5 `horizon', recast(line) lcolor("128 128 128") ///
                        lpattern(dash) lwidth(thin)), ///
                       title("Persistence Profile", size(medium)) ///
                       ytitle("Persistence", size(small)) ///
                       xtitle("Horizon", size(small)) ///
                       legend(order(1 "Persistence" 2 "Half-life") ///
                              size(small) rows(1)) ///
                       scheme(s2color) name(aardl_persistence, replace)
            }

            qui use `_pp_tmpdata', clear
            capture mat drop _aardl_pp
        }
    }

    // ─── Fourier Terms Significance Test ───
    if `kstar' > 0 {
        di as txt _col(5) "{bf:Fourier Terms Joint Significance}"
        di as txt ""

        capture qui test _aardl_sin _aardl_cos
        if _rc == 0 {
            local fourier_F = r(F)
            local fourier_p = r(p)
            di as txt _col(7) "F-statistic (sin + cos)  = " as res %10.4f `fourier_F'
            di as txt _col(7) "p-value                  = " as res %10.4f `fourier_p'
            if `fourier_p' < 0.05 {
                di as txt _col(7) "Fourier terms are " as res "jointly significant"
            }
            else {
                di as txt _col(7) "Fourier terms are " as err "not jointly significant"
            }
        }
        else {
            di as txt _col(7) "Could not test Fourier terms"
        }
        di as txt ""
    }

    // ─── Long-Run Equilibrium (via nlcom) ───
    di as txt _col(5) "{bf:Long-Run Equilibrium Relationship}"
    di as txt _col(5) "y = " _c
    local first = 1
    foreach xvar of local indepvars {
        capture qui nlcom (LR_`xvar': -_b[L.`xvar'] / _b[L.`depvar']), level(`level')
        if _rc == 0 {
            mat _nlcom_b = r(b)
            local lr = _nlcom_b[1,1]
            if `first' {
                di as res %8.4f `lr' " * `xvar'" _c
                local first = 0
            }
            else {
                if `lr' >= 0 {
                    di as res " + " %8.4f `lr' " * `xvar'" _c
                }
                else {
                    di as res " - " %8.4f abs(`lr') " * `xvar'" _c
                }
            }
            mat drop _nlcom_b
        }
    }
    di as txt ""
    di as txt ""

    di as txt "{hline 78}"

end
