*! statplot 1.3.0 -- package test 
*  Eric A. Booth and Nicholas J. Cox

clear all
set more off

*----------------------------------------------------------------------*
* 0.  Where to write the example graphs (edit if you like)
*----------------------------------------------------------------------*
local out "."          // current working directory
capture mkdir "`out'/statplot_examples"
local g "`out'/statplot_examples"

* small assert helper (relative difference)
capture program drop _spchk
program _spchk
    args got want tag
    if reldif(`got',`want') > 1e-6 {
        di as err "CHECK FAILED [`tag']: got `got', want `want'"
        exit 9
    }
    di as txt "  ok  [`tag']"
end


*======================================================================*
di as txt _n "{hline 70}"
di as res    "PART 1 -- the new features, one graph each"
di as txt    "{hline 70}"
*======================================================================*

*--- 1a. Confidence intervals on group means (the headline addition) --*
sysuse nlsw88, clear
statplot wage, over(race) ci ///
    title("Mean hourly wage by race, with 95% CI")
graph export "`g'/01_ci_hbar.png", replace width(900)

* several variables -> small multiples, one panel per variable.
* Each panel is titled with its variable label (via graph -by()-), so leave the
* overall title off here; a user title() would repeat once per panel.
statplot wage ttl_exp tenure, over(race) ci
graph export "`g'/02_ci_panels.png", replace width(1000)

* recast as vertical bars or as a dot/interval plot.
* baropts() styles the CI bars; ciopts() styles the whiskers.
statplot wage, over(race) ci recast(bar) ///
    baropts(fcolor(navy) lcolor(navy)) ciopts(lcolor(gs6))
graph export "`g'/03_ci_bar.png", replace width(900)
statplot wage, over(race) ci recast(dot) level(90) ciopts(lcolor(gs6))
graph export "`g'/04_ci_dot.png", replace width(900)

*--- 1b. Percentages of a 0/1 indicator, with a % sign on each bar -----*
* (blabel suffix() needs Stata 19+; drop it on earlier Stata)
statplot union, over(race) percent ///
    blabel(bar, format(%2.0f) suffix(%)) ///
    title("Union membership rate by race")
graph export "`g'/05_percent.png", replace width(900)

*--- 1c. Shares of a total -------------------------------------------*
sysuse census, clear
statplot marriage divorce, over(region) s(sum) share base(var) ///
    title(`"Marriages and divorces: "' `"share across regions (each var = 100%)"')
graph export "`g'/06_share.png", replace width(900)

*--- 1d. Wrapping long labels ----------------------------------------*
* wrap() breaks labels longer than # characters onto several lines. With a
* handful of bars the lines have room; a chart with many tall over() categories
* will also want a larger ysize() and/or a smaller label size.
sysuse nlsw88, clear
statplot ttl_exp tenure grade hours, wrap(18) ///
    title("Wrapped variable labels")
graph export "`g'/07_wrap.png", replace width(900)

*--- 1e. Ordering: rank by value, pin a category last ----------------*
sysuse citytemp, clear
statplot tempjan tempjuly heatdd cooldd, sort descending ///
    title("Variables ordered high-to-low by mean")
graph export "`g'/08_sort.png", replace width(900)

*--- 1e2. Headings and groups among the bars (coefplot-style) ---------*
* headings() = section-title rows (bars shift down); groups() = side brackets.
sysuse auto, clear
statplot price mpg weight length headroom trunk, ///
    headings(price = "{bf:Cost}" mpg = "{bf:Efficiency}" weight = "{bf:Size}") ///
    title("headings(): section titles among the bars")
graph export "`g'/10_headings.png", replace width(900)

statplot price mpg weight length headroom trunk, ci ///
    groups(price mpg = "{bf:Performance}" weight length headroom trunk = "{bf:Dimensions}") ///
    title("groups(): bracket labels beside spans")
graph export "`g'/11_groups.png", replace width(900)

*--- 1f. Keep / view the numbers behind the bars ---------------------*
sysuse citytemp, clear
statplot heatdd cooldd, over(region) listdata          // to the screen
statplot heatdd cooldd, over(region) savedata("`g'/09_results", replace)
statplot heatdd cooldd, over(region) frame(sp_results) // Stata 16+
capture frame dir


*======================================================================*
di as txt _n "{hline 70}"
di as res    "PART 2 -- checks: new options do not change the calculation"
di as txt    "{hline 70}"
*======================================================================*

* (A) default path still equals collapse -----------------------------*
sysuse citytemp, clear
tempfile sd
qui statplot heatdd cooldd, over(region) savedata("`sd'", replace)
preserve
    collapse (mean) heatdd, by(region)
    qui su heatdd if region==1, meanonly
    local truth = r(mean)
restore
preserve
    use "`sd'", clear
    qui su heatdd if region==1, meanonly
    _spchk `r(mean)' `truth' "default path == collapse"
restore

* (B) percent == 100 x mean ------------------------------------------*
sysuse nlsw88, clear
qui statplot union, over(race) percent savedata("`sd'", replace)
qui su union if race==2, meanonly
local want = r(mean)*100
preserve
    use "`sd'", clear
    qui su union if race==2, meanonly
    _spchk `r(mean)' `want' "percent == 100*mean"
restore

* (C) ci bounds == ci means ------------------------------------------*
sysuse nlsw88, clear
qui statplot wage, over(race) ci savedata("`sd'", replace)
qui ci means wage if race==2
local lb = r(lb)
preserve
    use "`sd'", clear
    qui su lo if race==2, meanonly
    _spchk `r(mean)' `lb' "ci lower bound == ci means"
restore

* (D) wrap and sort leave the values untouched -----------------------*
sysuse citytemp, clear
qui statplot heatdd cooldd, over(region) wrap(6) sort savedata("`sd'", replace)
preserve
    collapse (mean) heatdd, by(region)
    qui su heatdd if region==3, meanonly
    local truth = r(mean)
restore
preserve
    use "`sd'", clear
    qui su heatdd if region==3, meanonly
    _spchk `r(mean)' `truth' "wrap+sort keep values"
restore

di as res _n "ALL statplot 1.3.0 CHECKS PASSED"
di as txt "Example graphs written to: `g'"
