*! qnardl_cgraph v1.0.1  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Plot CUSUM and CUSUM-square recursive-residual stability paths.
*!
*! Reads the variables _qnct_* that _qnardl_cusum left in memory.
*! Default: CUSUM panel; option {cmd:cusumsq}: CUSUMSQ; option {cmd:both}: both.

program define qnardl_cgraph
    version 14.0

    syntax , [ CUSUMsq BOTH SAVing(string) XSize(real 7) YSize(real 4) SCheme(string) ]

    capture confirm variable _qnct_t
    if _rc {
        di as error "qnardl_cgraph: CUSUM data not found in dataset."
        di as error "  Re-run qnardl with the {bf:cusum} option."
        exit 198
    }
    if "`scheme'" == "" local scheme "s2color"

    // Keep all qnardl graphs visible as tabs
    capture set autotabgraphs on

    if "`both'" != ""           local types "c cs"
    else if "`cusumsq'" != ""   local types "cs"
    else                        local types "c"

    local mygraphs ""
    foreach typ of local types {
        local gn "_qncg_`typ'"

        if "`typ'" == "c" {
            qui twoway (rarea _qnct_uc _qnct_lc _qnct_t, color(gs14) fintensity(70)) (line _qnct_cuc _qnct_t, lcolor(navy) lwidth(medthick)) (line _qnct_uc _qnct_t, lcolor(cranberry) lpattern(dash)) (line _qnct_lc _qnct_t, lcolor(cranberry) lpattern(dash)), yline(0, lcolor(gs10) lpattern(dot)) title("CUSUM", size(medium)) subtitle("5% bands (Brown-Durbin-Evans 1975)", size(small)) ytitle("CUSUM", size(small)) xtitle("Observation t", size(small)) legend(order(2 "CUSUM" 3 "5% bound") rows(1) size(small) region(lwidth(none))) scheme(`scheme') name(`gn', replace) nodraw
        }
        else {
            qui twoway (rarea _qnct_ucs _qnct_lcs _qnct_t, color(gs14) fintensity(70)) (line _qnct_cucsq _qnct_t, lcolor(navy) lwidth(medthick)) (line _qnct_ucs _qnct_t, lcolor(cranberry) lpattern(dash)) (line _qnct_lcs _qnct_t, lcolor(cranberry) lpattern(dash)), title("CUSUM-Square", size(medium)) subtitle("5% bands (BDE 1975 approx.)", size(small)) ytitle("CUSUMSQ", size(small)) xtitle("Observation t", size(small)) legend(order(2 "CUSUMSQ" 3 "5% bound") rows(1) size(small) region(lwidth(none))) scheme(`scheme') name(`gn', replace) nodraw
        }
        local mygraphs `mygraphs' `gn'
    }

    if "`both'" != "" {
        graph combine `mygraphs', title("QNARDL stability diagnostics", size(medium)) cols(2) xsize(`xsize') ysize(`ysize') name(qnardl_cusum_both, replace)
        if "`saving'" != "" graph export "`saving'_cusum.png", replace
    }
    else {
        local solo : word 1 of `mygraphs'
        graph display `solo', xsize(`xsize') ysize(`ysize')
        if "`saving'" != "" {
            local label = cond("`cusumsq'"=="", "cusum", "cusumsq")
            graph export "`saving'_`label'.png", replace
        }
    }
    // Clean up intermediate single-panel graphs when both panels were combined
    if "`both'" != "" {
        capture graph drop _qncg_c _qncg_cs
        di as txt _n "qnardl_cgraph: plot complete.  Named graph: " ///
                  as res "qnardl_cusum_both"
    }
    else {
        local label = cond("`cusumsq'"=="", "_qncg_c", "_qncg_cs")
        di as txt _n "qnardl_cgraph: plot complete.  Named graph: " ///
                  as res "`label'"
    }
    di as txt "  View later with: {bf:graph display <name>}"
end
