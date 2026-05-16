*! rdstagger_plot v1.0.3 Subir Hait 2026
*! Event-study plot for rdstagger aggregation results
*! Stata 14 compatible

program define rdstagger_plot
    version 14
    syntax [,                     ///
        title(string)             ///
        name(passthru)            ///
        saving(passthru)          ///
        ]

    if "`e(cmd)'" != "rdstagger" {
        di as error "Must run rdstagger before rdstagger_plot"
        exit 301
    }

    cap confirm matrix e(agg)
    if _rc {
        di as error "Run rdstagger_agg first to generate aggregated estimates"
        exit 301
    }

    local agg_type = e(agg_type)
    if "`agg_type'" == "" {
        di as error "e(agg_type) not found; re-run rdstagger_agg"
        exit 301
    }

    tempname AGG
    matrix `AGG' = e(agg)
    local nrows = rowsof(`AGG')

    preserve
    clear
    qui set obs `nrows'

    qui gen double _xvar    = .
    qui gen double _att     = .
    qui gen double _ci_lo   = .
    qui gen double _ci_hi   = .
    qui gen byte   _prepost = .

    forvalues r = 1/`nrows' {
        qui replace _xvar   = `AGG'[`r',1] in `r'
        qui replace _att    = `AGG'[`r',2] in `r'
        qui replace _ci_lo  = `AGG'[`r',4] in `r'
        qui replace _ci_hi  = `AGG'[`r',5] in `r'
        if "`agg_type'" == "dynamic" {
            qui replace _prepost = `AGG'[`r',7] in `r'
        }
        else {
            qui replace _prepost = 1 in `r'
        }
    }

    drop if _att == .

    if      "`agg_type'" == "dynamic"   local xlab "Event time (periods relative to treatment)"
    else if "`agg_type'" == "group"     local xlab "Cohort (first treated period)"
    else if "`agg_type'" == "calendar"  local xlab "Calendar period"
    else {                               
        local xlab "Period"
    }

    if `"`title'"' == "" {
        if      "`agg_type'" == "dynamic"  local title "Event Study: Staggered RD ATT(g,t)"
        else if "`agg_type'" == "group"    local title "ATT by Treatment Cohort"
        else if "`agg_type'" == "calendar" local title "ATT by Calendar Period"
        else {
            local title "Aggregated ATT"
        }
    }

    if `"`name'"' == "" local name "name(rdstagger_plot, replace)"

    local refline ""
    if "`agg_type'" == "dynamic" {
        local refline `"xline(-0.5, lpattern(dot) lcolor(gs8) lwidth(thin))"'
    }

    twoway                                                           ///
        (rcap _ci_lo _ci_hi _xvar if _prepost == 0,                 ///
            lcolor(cranberry) lwidth(medium))                        ///
        (rcap _ci_lo _ci_hi _xvar if _prepost == 1,                 ///
            lcolor(navy) lwidth(medium))                             ///
        (scatter _att _xvar if _prepost == 0,                        ///
            msymbol(O) mcolor(cranberry) msize(medsmall))            ///
        (scatter _att _xvar if _prepost == 1,                        ///
            msymbol(O) mcolor(navy) msize(medsmall)),                ///
        yline(0, lpattern(dash) lcolor(gs10) lwidth(thin))          ///
        `refline'                                                     ///
        title(`"`title'"')                                            ///
        xtitle("`xlab'")                                             ///
        ytitle("ATT estimate (95% CI)")                              ///
        legend(order(3 "Pre-treatment" 4 "Post-treatment")           ///
               position(6) rows(1) size(small))                      ///
        `name'                                                          ///
        `saving'

    restore
end
