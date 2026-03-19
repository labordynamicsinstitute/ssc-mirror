*! cs_plot.ado  v1.0.2  2026-03-18  Stata 14.1 compatible ASCII only
program define cs_plot
    version 14.0

    syntax [, SAVing(string) TItle(string) ]

    if "$CSCMD" != "causalspline" {
        di as error "cs_plot requires causalspline to be run first"
        exit 301
    }

    local method = upper("$CSMETHOD")
    local tvar   = "$CSTREATMENT"
    local yvar   = "$CSOUTCOME"

    if "`title'" == "" {
        local title "Causal Dose-Response [`method']"
    }

    local ng = $CSNGRID

    preserve
        qui drop _all
        qui set obs `ng'
        qui gen double t   = .
        qui gen double mu  = .
        qui gen double lo  = .
        qui gen double hi  = .
        forval j = 1/`ng' {
            qui replace t  = CSCT[`j',1]  in `j'
            qui replace mu = CSCE[`j',1]  in `j'
            qui replace lo = CSCLO[`j',1] in `j'
            qui replace hi = CSCHI[`j',1] in `j'
        }

        qui sum mu
        local ymean = r(mean)

        twoway (rarea lo hi t, lwidth(none) color(ltblue))  ///
               (line mu t, lcolor(navy) lwidth(medthick))   ///
               (line mu t, lcolor(gs10) lpattern(dash)),    ///
            xtitle("Treatment (`tvar')")                     ///
            ytitle("E[Y(t)]")                                ///
            title("`title'")                                 ///
            note("95% CI shaded | Dashed = marginal mean")   ///
            legend(off)                                      ///
            scheme(s2color)

        if "`saving'" != "" {
            graph save "`saving'", replace
            di as text "  Plot saved: " as result "`saving'"
        }
    restore
end
