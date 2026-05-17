*! _rals_graph_fadf 1.0.1  16may2026  Dr Merwan Roudane
*! Shared Fourier-plot helper for ralsfadf and ralsfkss.
program define _rals_graph_fadf
    args y timevar touse stat cv5 kfreq T
    tempvar fseries idx
    qui gen `idx' = _n if `touse'
    qui gen `fseries' = .
    local pi = _pi
    qui replace `fseries' = sin(2*`pi'*`idx'*`kfreq'/`T') + cos(2*`pi'*`idx'*`kfreq'/`T') if `touse'
    local sf : di %6.3f `stat'
    local cf : di %6.3f `cv5'
    twoway (line `y' `timevar' if `touse', lcolor("32 119 180") lwidth(medthick)         ///
            yaxis(1))                                                                     ///
           (line `fseries' `timevar' if `touse', lcolor("220 50 50") lpattern(dash)      ///
            yaxis(2)),                                                                    ///
        title("RALS-Fourier test", size(medium))                                          ///
        subtitle("Fourier frequency k=`kfreq'  |  RALS stat = `sf'  |  5% CV = `cf'",     ///
                 size(small))                                                             ///
        ytitle("`y'", axis(1))                                                            ///
        ytitle("sin(2*pi*k*t/T)+cos(2*pi*k*t/T)", axis(2))                                ///
        xtitle("`timevar'")                                                               ///
        legend(order(1 "series" 2 "Fourier component") size(small) row(1))                ///
        scheme(s2color) graphregion(color(white)) name(rals_fourier_`y', replace)
end
