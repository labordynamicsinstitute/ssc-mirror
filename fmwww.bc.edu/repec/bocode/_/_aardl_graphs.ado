*! _aardl_graphs - visualisation suite for aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Produces, with the prefix given in graphprefix():
*!   <p>fit        actual vs fitted first difference of the dependent variable
*!   <p>resid      residuals over time with +/- 2 sigma bands
*!   <p>hist       residual histogram with a fitted normal density
*!   <p>qq         normal quantile-quantile plot of the residuals
*!   <p>ac         residual autocorrelation function
*!   <p>pac        residual partial autocorrelation function
*!   <p>ect        the error-correction term over time
*!   <p>bounds     the three bounds statistics against their critical values
*!   <p>bootFov    bootstrap null distribution of F_overall
*!   <p>boottDV    bootstrap null distribution of t_DV
*!   <p>bootFind   bootstrap null distribution of F_ind
*!   <p>dash       a combined dashboard of the six residual panels

capture program drop _aardl_graphs
program define _aardl_graphs
    version 17

    syntax , RESid(varname) FItted(varname) DY(varname) ESample(varname) ///
        TIMevar(varname) [ ECT(varname) GRAPHPrefix(string)              ///
        BOUNDSmat(string) BOOTmat(string) BOOTStats(string)              ///
        DEPvar(string) NODASHboard ]

    local p "`graphprefix'"

    // ---- 1. actual vs fitted --------------------------------------------
    capture noisily {
        twoway (line `dy' `timevar' if `esample', lcolor("31 119 180") lwidth(medium)) ///
               (line `fitted' `timevar' if `esample', lcolor("214 39 40")             ///
                lpattern(shortdash) lwidth(medium)),                                   ///
               title("Actual vs fitted", size(medium))                                 ///
               subtitle("First difference of `depvar'", size(small))                    ///
               ytitle("D.`depvar'", size(small)) xtitle("`timevar'", size(small))        ///
               legend(order(1 "Actual" 2 "Fitted") size(small) rows(1))                 ///
               scheme(s2color) name(`p'fit, replace) nodraw
    }

    // ---- 2. residuals with +/- 2 sigma ----------------------------------
    qui summarize `resid' if `esample'
    local sd = r(sd)
    capture noisily {
        twoway (line `resid' `timevar' if `esample', lcolor("31 119 180") lwidth(medium)), ///
               yline(0, lcolor(gs10))                                                   ///
               yline(`=2*`sd'', lcolor("214 39 40") lpattern(dash))                      ///
               yline(`=-2*`sd'', lcolor("214 39 40") lpattern(dash))                     ///
               title("Residuals", size(medium))                                          ///
               subtitle("with +/- 2 standard-deviation bands", size(small))              ///
               ytitle("Residual", size(small)) xtitle("`timevar'", size(small))           ///
               legend(off) scheme(s2color) name(`p'resid, replace) nodraw
    }

    // ---- 3. histogram + normal ------------------------------------------
    capture noisily {
        histogram `resid' if `esample', normal fcolor("31 119 180*.55")   ///
            lcolor("31 119 180") normopts(lcolor("214 39 40") lwidth(medthick)) ///
            title("Residual distribution", size(medium))                   ///
            subtitle("with fitted normal density", size(small))            ///
            xtitle("Residual", size(small))                                ///
            scheme(s2color) name(`p'hist, replace) nodraw
    }

    // ---- 4. normal Q-Q ----------------------------------------------------
    capture noisily {
        qnorm `resid' if `esample',                                        ///
            mcolor("31 119 180") msize(small)                              ///
            rlopts(lcolor("214 39 40") lpattern(dash))                     ///
            title("Normal Q-Q plot of residuals", size(medium))            ///
            scheme(s2color) name(`p'qq, replace) nodraw
    }

    // ---- 5-6. residual ACF and PACF --------------------------------------
    capture noisily {
        ac `resid' if `esample', lags(16)                                   ///
            title("Residual autocorrelation", size(medium))                 ///
            scheme(s2color) name(`p'ac, replace) nodraw
    }
    capture noisily {
        pac `resid' if `esample', lags(16)                                  ///
            title("Residual partial autocorrelation", size(medium))         ///
            scheme(s2color) name(`p'pac, replace) nodraw
    }

    // ---- 7. error-correction term ----------------------------------------
    if "`ect'" != "" {
        capture noisily {
            twoway (line `ect' `timevar' if `esample', lcolor("44 160 44")   ///
                    lwidth(medthick)),                                       ///
                   yline(0, lcolor("214 39 40") lpattern(dash))              ///
                   title("Error-correction term", size(medium))              ///
                   subtitle("Deviation from the long-run relationship", size(small)) ///
                   ytitle("ECT", size(small)) xtitle("`timevar'", size(small)) ///
                   legend(off) scheme(s2color) name(`p'ect, replace) nodraw
        }
    }

    // ---- 8. bounds-test summary ------------------------------------------
    // boundsmat rows: F_overall, t_DV, F_ind ; cols: statistic, lower, upper
    if "`boundsmat'" != "" {
        capture noisily {
            mat _aardl_bnd = `boundsmat'
            preserve
            qui clear
            qui set obs 3
            qui gen byte   id  = _n
            qui gen double st  = .
            qui gen double lb  = .
            qui gen double ub  = .
            forvalues i = 1/3 {
                qui replace st = el(_aardl_bnd,`i',1) in `i'
                qui replace lb = el(_aardl_bnd,`i',2) in `i'
                qui replace ub = el(_aardl_bnd,`i',3) in `i'
            }
            label define _aardlb 1 "F_overall" 2 "t_DV" 3 "F_ind", replace
            label values id _aardlb
            twoway (rbar lb ub id, barwidth(.45) color("128 128 128*.35"))       ///
                   (scatter st id, mcolor("214 39 40") msymbol(diamond)          ///
                    msize(large)),                                               ///
                   xlabel(1 2 3, valuelabel) xscale(range(0.5 3.5))              ///
                   title("Bounds tests vs critical values", size(medium))        ///
                   subtitle("Bar = I(0)-I(1) band or bootstrap 5% level", size(small)) ///
                   ytitle("Statistic", size(small)) xtitle("")                    ///
                   legend(order(2 "Test statistic" 1 "Critical band") size(small) rows(1)) ///
                   scheme(s2color) name(`p'bounds, replace) nodraw
            restore
            capture mat drop _aardl_bnd
        }
    }

    // ---- 9. bootstrap null distributions ---------------------------------
    if "`bootmat'" != "" {
        capture confirm matrix `bootmat'
        if _rc == 0 {
            local nms "Fov tDV Find"
            local ttl1 "F_overall"
            local ttl2 "t_DV"
            local ttl3 "F_ind"
            forvalues j = 1/3 {
                local nm : word `j' of `nms'
                local ob : word `j' of `bootstats'
                capture noisily {
                    mat _aardl_bd = `bootmat'
                    preserve
                    qui clear
                    qui svmat double _aardl_bd, names(bs)
                    qui keep if bs`j' < .
                    qui count
                    if r(N) > 10 {
                        local ttl "`ttl`j''"
                        twoway (histogram bs`j', fcolor("31 119 180*.45")            ///
                                lcolor("31 119 180") bin(40)),                       ///
                               xline(`ob', lcolor("214 39 40") lwidth(medthick))     ///
                               title("Bootstrap null distribution: `ttl'", size(medium)) ///
                               subtitle("Red line = observed statistic", size(small)) ///
                               xtitle("`ttl' under H0", size(small))                  ///
                               legend(off) scheme(s2color)                            ///
                               name(`p'boot`nm', replace) nodraw
                    }
                    restore
                    capture mat drop _aardl_bd
                }
            }
        }
    }

    // ---- 10. dashboard ----------------------------------------------------
    if "`nodashboard'" == "" {
        capture noisily {
            graph combine `p'fit `p'resid `p'hist `p'qq `p'ac `p'pac, ///
                cols(2) iscale(.55) imargin(small)                     ///
                title("aardl residual diagnostics", size(medsmall))     ///
                scheme(s2color) name(`p'dash, replace) nodraw
        }
    }

    // draw everything that was built
    foreach g in fit resid hist qq ac pac ect bounds bootFov boottDV bootFind dash {
        capture graph display `p'`g'
    }
end
