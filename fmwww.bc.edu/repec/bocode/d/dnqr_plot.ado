*! dnqr_plot.ado  version 1.0.1  27may2026
*! Quantile coefficient plot (post-estimation) for nqar and dnqr.
*! Produces a publication-quality figure with point estimates and
*! shaded confidence bands across the quantile grid, one panel per
*! selected variable.  Inspired by the rqs-style plots in Koenker
*! (2005) and the DNQR paper figures.
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Help    : help dnqr_plot

program define dnqr_plot
        version 13.0

        if !inlist("`e(cmd)'", "nqar", "dnqr") {
                di as err "{bf:dnqr_plot} only works after {bf:nqar} or {bf:dnqr}"
                exit 301
        }

        syntax [namelist] [, Level(cilevel) NCols(integer 3) ///
                COLor(string) BCOLor(string) Title(string) ///
                Saving(string) SCHeme(string) NAme(string) Combine(string) ///
                NODraw NOTes ]

        if ("`scheme'"=="")  local scheme s2color
        if ("`color'"=="")   local color  navy
        if ("`bcolor'"=="")  local bcolor ltblue%40
        if ("`level'"=="")   local level  = e(level)
        if "`name'" == ""    local name   dnqrplot

        tempname Q B SE LO HI
        matrix `Q'  = e(quantile)
        matrix `B'  = e(b_q)
        matrix `SE' = e(se_q)
        matrix `LO' = e(lo_q)
        matrix `HI' = e(hi_q)
        local rows : rowfullnames `B'

        // resolve which variables to plot
        if ("`namelist'"=="") {
                if ("`e(cmd)'"=="dnqr") local namelist "WY WY_L1 Y_L1"
                else                    local namelist "WY_L1 Y_L1"
                if ("`e(zvars)'"!="")   local namelist "`namelist' `e(zvars)'"
        }

        preserve
        quietly drop _all
        local nq = colsof(`Q')
        quietly set obs `nq'
        quietly gen double tau = .
        forvalues j = 1/`nq' {
                quietly replace tau = `Q'[1,`j'] in `j'
        }

        local plots ""
        foreach v of local namelist {
                // find row index
                local idx 0
                local r 0
                foreach nm of local rows {
                        local ++r
                        if ("`nm'"=="`v'") {
                                local idx = `r'
                                continue, break
                        }
                }
                if (`idx'==0) {
                        di as err "variable {bf:`v'} not in stored coefficients; skipping"
                        continue
                }
                local vs = subinstr("`v'", ".", "_", .)
                local vs = subinstr("`vs'", "_", "X", .)
                tempname B`vs' L`vs' H`vs'
                quietly gen double b_`vs' = .
                quietly gen double l_`vs' = .
                quietly gen double h_`vs' = .
                forvalues j = 1/`nq' {
                        quietly replace b_`vs' = `B'[`idx',`j'] in `j'
                        quietly replace l_`vs' = `LO'[`idx',`j'] in `j'
                        quietly replace h_`vs' = `HI'[`idx',`j'] in `j'
                }

                local subt "`v'"
                local gname _gplot_`vs'
                local cmd twoway                                       ///
                    (rarea l_`vs' h_`vs' tau,                          ///
                       fcolor("`bcolor'") lcolor("`bcolor'") lwidth(none)) ///
                    (line b_`vs' tau, lcolor("`color'") lwidth(medium))    ///
                    (function y=0, range(tau) lpattern(dash)               ///
                       lcolor(gs10) lwidth(thin)),                         ///
                    title("`subt'", size(medsmall))                        ///
                    xtitle("Quantile {it:{&tau}}", size(small))            ///
                    ytitle("")                                             ///
                    legend(off)                                            ///
                    yline(0, lpattern(dash) lcolor(gs10))                  ///
                    scheme(`scheme')                                       ///
                    nodraw name(`gname', replace)
                quietly `cmd'
                local plots `plots' `gname'
        }

        if ("`title'"=="") local title "Quantile coefficient process (`level'% CI)"

        if ("`combine'"=="combine" | "`combine'"=="") {
                graph combine `plots',                                    ///
                        cols(`ncols')                                     ///
                        title("`title'", size(medsmall))                  ///
                        note("Method: `e(cmd)'.", size(vsmall))             ///
                        scheme(`scheme')                                  ///
                        name(`name', replace)
                if ("`saving'" != "") graph save `name' "`saving'", replace
                if ("`nodraw'" != "") graph drop `name'
        }
        restore
end
