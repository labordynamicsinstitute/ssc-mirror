* ============================================================================
* factsheetplot example: Convert and export an existing Stata graph
*
* Author: Samuel Sturm
* Input:  Stata's built-in auto dataset
* Output: factsheetplot_example.png in the current working directory
* ============================================================================

version 17
clear all
set more off
set varabbrev off

sysuse auto, clear

// The graph can come from any command that leaves a Stata graph open.
set scheme s2color
twoway ///
    (scatter price mpg) ///
    (lfit price mpg), ///
    title("Vehicle price and fuel economy") ///
    xtitle("Fuel economy (miles per gallon)") ///
    ytitle("Price (US dollars)")

factsheetplot using "factsheetplot_example.png", replace
