*! multispline_plot.ado  v0.2.0  Subir Hait  Michigan State University
*! Post-estimation plots for multispline: trajectory, slope, curvature, combo
version 14.0

program define multispline_plot
    version 14.0

    syntax , Using(string) ///
        [ TYPE(string) Xvar(string) YLab(string) ///
          Title(string) NOCI LEvel(integer 95) ]

    if "`type'" == "" local type "trajectory"
    if "`xvar'" == "" local xvar "mpg"

    if !inlist("`type'","trajectory","slope","curvature","combo") {
        di as error "type() must be: trajectory  slope  curvature  combo"
        exit 198
    }

    * FIX BUG 7: use local not strltrim inside note()
    local cilabel "`level'% confidence band"

    preserve
    quietly use `"`using'"', clear

    * ----------------------------------------------------------
    * Trajectory
    * ----------------------------------------------------------
    if "`type'" == "trajectory" {
        if "`title'" == "" local title "Estimated nonlinear trajectory"
        if "`ylab'"  == "" local ylab  "Predicted outcome"

        if "`noci'" == "" {
            twoway ///
                (rarea lwr upr `xvar', color(navy) fintensity(20)) ///
                (line fit `xvar', lcolor(navy) lwidth(medthick)), ///
                legend(off) ///
                xtitle("`xvar'") ytitle("`ylab'") ///
                title("`title'") ///
                note("`cilabel'")
        }
        else {
            twoway line fit `xvar', ///
                lcolor(navy) lwidth(medthick) ///
                xtitle("`xvar'") ytitle("`ylab'") ///
                title("`title'")
        }
    }

    * ----------------------------------------------------------
    * Slope (first derivative)
    * ----------------------------------------------------------
    else if "`type'" == "slope" {
        capture confirm variable d1
        if _rc {
            di as error "Variable d1 not found in `using'.dta"
            di as error "Re-run multispline with the -derivatives- option"
            restore
            exit 111
        }
        if "`title'" == "" local title "Marginal effect (first derivative)"
        if "`ylab'"  == "" local ylab  "dy / d(`xvar')"

        if "`noci'" == "" {
            capture confirm variable d1_lwr
            if !_rc {
                twoway ///
                    (rarea d1_lwr d1_upr `xvar', ///
                        color(maroon) fintensity(20)) ///
                    (line d1 `xvar', lcolor(maroon) lwidth(medthick)) ///
                    (function y=0, range(`xvar') ///
                        lcolor(gs8) lpattern(dash)), ///
                    legend(off) ///
                    xtitle("`xvar'") ytitle("`ylab'") ///
                    title("`title'") ///
                    note("`cilabel' | dashed = zero")
            }
            else {
                twoway ///
                    (line d1 `xvar', lcolor(maroon) lwidth(medthick)) ///
                    (function y=0, range(`xvar') ///
                        lcolor(gs8) lpattern(dash)), ///
                    legend(off) ///
                    xtitle("`xvar'") ytitle("`ylab'") ///
                    title("`title'")
            }
        }
        else {
            twoway ///
                (line d1 `xvar', lcolor(maroon) lwidth(medthick)) ///
                (function y=0, range(`xvar') ///
                    lcolor(gs8) lpattern(dash)), ///
                legend(off) ///
                xtitle("`xvar'") ytitle("`ylab'") ///
                title("`title'")
        }
    }

    * ----------------------------------------------------------
    * Curvature (second derivative)
    * ----------------------------------------------------------
    else if "`type'" == "curvature" {
        capture confirm variable d2
        if _rc {
            di as error "Variable d2 not found in `using'.dta"
            di as error "Re-run multispline with the -derivatives- option"
            restore
            exit 111
        }
        if "`title'" == "" local title "Curvature (second derivative)"
        if "`ylab'"  == "" local ylab  "d2y / d(`xvar')^2"
        twoway ///
            (line d2 `xvar', lcolor(forest_green) lwidth(medthick)) ///
            (function y=0, range(`xvar') lcolor(gs8) lpattern(dash)), ///
            legend(off) ///
            xtitle("`xvar'") ytitle("`ylab'") ///
            title("`title'") ///
            note("Note: wide CIs expected due to numerical differentiation")
    }

    * ----------------------------------------------------------
    * Combo: trajectory + slope side by side
    * ----------------------------------------------------------
    else if "`type'" == "combo" {
        capture confirm variable d1
        if _rc {
            di as error "Variable d1 not found in `using'.dta"
            di as error "Re-run multispline with the -derivatives- option"
            restore
            exit 111
        }
        if "`title'" == "" local title "Trajectory and marginal effect"

        tempfile traj_g slope_g

        if "`noci'" == "" {
            quietly twoway ///
                (rarea lwr upr `xvar', color(navy) fintensity(20)) ///
                (line fit `xvar', lcolor(navy) lwidth(medthick)), ///
                legend(off) ///
                xtitle("`xvar'") ytitle("Predicted outcome") ///
                title("A: Trajectory") ///
                saving(`"`traj_g'"', replace) nodraw
        }
        else {
            quietly twoway ///
                line fit `xvar', lcolor(navy) lwidth(medthick) ///
                xtitle("`xvar'") ytitle("Predicted outcome") ///
                title("A: Trajectory") ///
                saving(`"`traj_g'"', replace) nodraw
        }

        quietly twoway ///
            (line d1 `xvar', lcolor(maroon) lwidth(medthick)) ///
            (function y=0, range(`xvar') lcolor(gs8) lpattern(dash)), ///
            legend(off) ///
            xtitle("`xvar'") ytitle("dy / d(`xvar')") ///
            title("B: Marginal effect") ///
            saving(`"`slope_g'"', replace) nodraw

        graph combine `"`traj_g'"' `"`slope_g'"', ///
            cols(2) title("`title'")
    }

    restore
end
