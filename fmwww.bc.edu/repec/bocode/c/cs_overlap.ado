*! cs_overlap.ado  v1.0.2  2026-03-18  Stata 14.1 compatible ASCII only
*! Overlap / positivity diagnostics

program define cs_overlap, rclass
    version 14.0

    syntax [, NOPlot SAVing(string) ]

    if "$CSCMD" != "causalspline" {
        di as error "cs_overlap requires causalspline to be run first"
        exit 301
    }
    if !inlist("$CSMETHOD", "ipw", "dr") {
        di as error "cs_overlap only available for method ipw or dr"
        exit 198
    }

    local n       = $CSN
    local ess     = $CSESS
    local ess_pct = $CSESPCT
    local t_min   = $CSTMIN
    local t_max   = $CSTMAX

    di as text " "
    di as text "{hline 55}"
    di as text " Overlap / Positivity Diagnostic"
    di as text "{hline 55}"
    di as text "  n             : " as result `n'
    di as text "  ESS           : " as result %6.1f `ess'
    di as text "  ESS / n       : " as result `ess_pct' as text "%"
    di as text "  Treatment range: [" ///
        as result %6.3f `t_min' as text ", " ///
        as result %6.3f `t_max' as text "]"
    di as text "{hline 55}"

    if `ess_pct' >= 70 {
        di as text "  Assessment: " as result "Good overlap (ESS >= 70%)"
    }
    else if `ess_pct' >= 50 {
        di as text "  Assessment: " as text "Moderate overlap - check weight distribution"
    }
    else {
        di as text "  Assessment: " as error "Poor overlap (ESS < 50%) - results may be unreliable"
    }
    di as text "{hline 55}"

    if "`noplot'" == "" {
        local tvar  = "$CSTREATMENT"
        local ess_r = round(`ess', 0.1)
        local epct  = `ess_pct'

        twoway (histogram `tvar', bin(30) color(navy) fcolor(navy)), ///
            title("Weighted treatment distribution (overlap diagnostic)") ///
            subtitle("ESS = `ess_r' / n = `n' (`epct'%)") ///
            xtitle("Treatment `tvar'") ///
            ytitle("Count") ///
            scheme(s2color)

        if "`saving'" != "" {
            graph save "`saving'", replace
            di as text "  Plot saved: " as result "`saving'"
        }
    }

    return scalar ess     = `ess'
    return scalar ess_pct = `ess_pct'
    return scalar n       = `n'
end
