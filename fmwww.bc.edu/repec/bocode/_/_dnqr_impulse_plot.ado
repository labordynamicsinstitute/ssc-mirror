*! _dnqr_impulse_plot.ado  version 1.0.1  27may2026
*! Private graph helper for dnqr_impulse; do not call directly.
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>

program define _dnqr_impulse_plot
        version 13.0
        syntax , IRF(name) Horizon(integer) Top(integer) ///
                 Title(string) [ SCHeme(string) NAme(string) Saving(string) ]
        if ("`scheme'"=="") local scheme s2color
        if ("`name'"=="")   local name dnqrimpulse

        preserve
        quietly drop _all
        local H1 = `horizon' + 1
        quietly set obs `H1'
        quietly gen int h = _n - 1
        // pick top nodes by max abs IRF
        local N = rowsof(`irf')
        tempname AB
        matrix `AB' = J(`N', 2, .)
        forvalues i = 1/`N' {
                matrix `AB'[`i', 1] = `i'
                local mx = 0
                forvalues h = 1/`H1' {
                        local v = abs(`irf'[`i', `h'])
                        if (`v' > `mx') local mx = `v'
                }
                matrix `AB'[`i', 2] = `mx'
        }
        // sort by col2 desc and take first `top'
        mata: st_matrix("`AB'", sort(st_matrix("`AB'"), -2))
        local plots ""
        forvalues k = 1/`top' {
                if (`k' > `N') continue
                local nd = `AB'[`k', 1]
                quietly gen double n`k' = .
                forvalues h = 1/`H1' {
                        quietly replace n`k' = `irf'[`nd', `h'] if h == `h'-1
                }
                local plots `plots' (line n`k' h, lwidth(medium))
        }
        twoway `plots',                                                  ///
                yline(0, lpattern(dash) lcolor(gs10))                    ///
                title("`title'", size(medsmall))                         ///
                xtitle("Horizon {it:h}", size(small))                    ///
                ytitle("Response", size(small))                          ///
                note("Top `top' nodes by peak |IRF|.", size(vsmall))     ///
                scheme(`scheme')                                         ///
                legend(off)                                              ///
                name(`name', replace)
        if ("`saving'" != "") graph save `name' "`saving'", replace
        restore
end
