*! xtbestcce_plot 1.0.1 - 2026-05-12
*! Author : Dr. Merwan Roudane
*! Email  : merwanroudane920@gmail.com
*!
*! Post-estimation visualisation companion for -xtbestcce-.
*!
*!   kind(coef)   coefficient plot with CIs (eq 2.8 if bootstrap was run)
*!   kind(bdist)  bootstrap distribution density per coefficient
*!   kind(ic)     IC selector summary

program define xtbestcce_plot
        version 15.1
        if ("`e(cmd)'" != "xtbestcce") {
                di as err "xtbestcce_plot requires a previous -xtbestcce- estimation"
                exit 301
        }
        syntax , [Kind(string) Level(cilevel) Save(string)]
        if ("`kind'" == "") local kind "coef"
        if !inlist("`kind'", "coef", "bdist", "ic") {
                di as err "kind() must be one of: coef bdist ic"
                exit 198
        }
        if ("`level'" == "") local level = e(level)
        if ("`level'" == "") local level 95

        if      ("`kind'" == "coef")  CoefPlot, level(`level') save(`save')
        else if ("`kind'" == "bdist") BootDens, level(`level') save(`save')
        else if ("`kind'" == "ic")    ICinfo
end


// =================================================================
// Coefficient plot
// =================================================================
program define CoefPlot
        syntax , [level(cilevel) save(string)]
        local critz = invnormal(1 - (1-`level'/100)/2)
        local alpha_lo = (100-`level')/2
        local alpha_hi = 100 - `alpha_lo'

        local cols : colnames e(b)
        local p = colsof(e(b))

        // Detect whether bootstrap CIs are available
        local hasBoot = (e(bootstrap) == 1)

        preserve
        clear
        set obs `p'
        quietly {
                gen str20  varname = ""
                gen double coef    = .
                gen double se      = .
                gen double lo      = .
                gen double hi      = .
                gen int    yidx    = _n
        }

        // If bootstrap available, fetch its draws into separate variables
        if `hasBoot' {
                tempname BS
                matrix `BS' = e(bsamples)
                quietly svmat `BS', names(xbcoef)
        }

        forvalues j = 1/`p' {
                local nm : word `j' of `cols'
                quietly replace varname = "`nm'" in `j'
                local cf = el(matrix(e(b)), 1, `j')
                local sd = sqrt(el(matrix(e(V)), `j', `j'))
                quietly replace coef = `cf' in `j'
                quietly replace se   = `sd' in `j'
                if `hasBoot' {
                        quietly _pctile xbcoef`j', p(`alpha_lo' `alpha_hi')
                        local q_lo = r(r1)
                        local q_hi = r(r2)
                        quietly replace lo = 2*`cf' - `q_hi' in `j'
                        quietly replace hi = 2*`cf' - `q_lo' in `j'
                }
                else {
                        quietly replace lo = `cf' - `critz'*`sd' in `j'
                        quietly replace hi = `cf' + `critz'*`sd' in `j'
                }
        }

        // Build a value label for the y axis (no labutil dependency)
        capture label drop _xbvar
        quietly {
                forvalues j = 1/`p' {
                        local lbl : word `j' of `cols'
                        label define _xbvar `j' "`lbl'", modify
                }
                label values yidx _xbvar
        }

        local title  "xtbestcce: `=e(estimator)' coefficients with `level'% CI"
        local subti  = cond(`hasBoot', "Cross-section bootstrap CIs", "Analytical CIs")

        twoway                                                            ///
                (rcap lo hi yidx, horizontal lcolor(navy) lwidth(medium))  ///
                (scatter yidx coef,                                        ///
                        msymbol(O) mcolor(maroon) msize(medlarge)          ///
                        mlcolor(white)),                                   ///
                xline(0, lcolor(gs10) lpattern(dash))                      ///
                ylabel(1/`p', valuelabel angle(0) labsize(small) nogrid)   ///
                ytitle("")                                                 ///
                xtitle("Coefficient", size(small))                         ///
                title("`title'", size(medium) color(navy))                 ///
                subtitle("`subti'", size(small) color(gs6))                ///
                legend(off)                                                ///
                scheme(s1color)                                            ///
                graphregion(color(white)) plotregion(color(white))

        if ("`save'" != "") graph export "`save'", replace
        capture label drop _xbvar
        restore
end


// =================================================================
// Bootstrap distribution density plot
// =================================================================
program define BootDens
        syntax , [level(cilevel) save(string)]
        if e(bootstrap) != 1 {
                di as err "no bootstrap samples available — rerun xtbestcce with bootstrap option"
                exit 198
        }
        local alpha_lo = (100-`level')/2
        local alpha_hi = 100 - `alpha_lo'

        local cols : colnames e(b)
        local p = colsof(e(b))

        preserve
        clear
        tempname BS
        matrix `BS' = e(bsamples)
        local nrep = rowsof(`BS')
        quietly svmat `BS', names(xbcoef)

        local glist ""
        forvalues j = 1/`p' {
                local nm : word `j' of `cols'
                local cf = el(matrix(e(b)), 1, `j')
                quietly _pctile xbcoef`j', p(`alpha_lo' `alpha_hi')
                local q_lo = r(r1)
                local q_hi = r(r2)
                tempname g`j'
                kdensity xbcoef`j',                                            ///
                        kernel(gaussian)                                       ///
                        lcolor(navy) lwidth(medthick)                          ///
                        title("`nm'", size(medsmall) color(navy))              ///
                        xtitle("")                                             ///
                        ytitle("density", size(vsmall))                        ///
                        xlabel(, labsize(vsmall))                              ///
                        ylabel(, labsize(vsmall))                              ///
                        xline(`cf', lcolor(maroon) lpattern(dash))             ///
                        xline(`q_lo' `q_hi', lcolor(gs7) lpattern(shortdash))  ///
                        note("")                                               ///
                        scheme(s1color)                                        ///
                        graphregion(color(white))                              ///
                        plotregion(color(white))                               ///
                        name(`g`j'', replace)
                local glist `glist' `g`j''
        }

        graph combine `glist',                                                ///
                title("xtbestcce: bootstrap distributions (B = `nrep')",      ///
                        size(medium) color(navy))                             ///
                subtitle("Dashed: point estimate. Shortdash: `level'% percentile bounds.", ///
                        size(vsmall) color(gs6))                              ///
                scheme(s1color)                                               ///
                graphregion(color(white))                                     ///
                imargin(small)

        if ("`save'" != "") graph export "`save'", replace
        forvalues j = 1/`p' {
                capture graph drop `g`j''
        }
        restore
end


// =================================================================
// IC selection info
// =================================================================
program define ICinfo
        if e(ic_used) != 1 {
                di as err "no IC selection was performed (rerun xtbestcce with ic option)"
                exit 198
        }
        di
        di as txt "{bf:Information Criterion selection (eq. 3.1)}"
        di as txt "{hline 55}"
        di as txt "Penalty kind   : " as res "`e(ic_pen)'"
        di as txt "g (CAs picked) : " as res e(g_ca)
        di as txt "Selected CAs   : " as res "`e(Fxnames)'"
        di
end
