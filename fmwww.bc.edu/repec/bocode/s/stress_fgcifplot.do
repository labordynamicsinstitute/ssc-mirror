version 14.2
clear all
set more off

* Load the release-candidate source from this directory.
quietly run "fgcifplot.ado"
set seed 16092026

* =====================================================================
* fgcifplot graphical/layout stress test
* Four labeled groups, unequal sizes, substantial competing events and
* censoring, and seven displayed risk times.
* =====================================================================

set obs 800
gen long id = _n

gen byte grp = cond(_n<=120,0,cond(_n<=300,1,cond(_n<=520,2,3)))
label define grp_lbl ///
    0 "Regional center" ///
    1 "Early transfer" ///
    2 "Intermediate transfer" ///
    3 "Later transfer"
label values grp grp_lbl

* Group-specific event-time distributions purely for layout testing.
gen double base = -ln(runiform())
gen double dftime = .05 + base * (2.0 + .35*grp)
replace dftime = min(dftime, 12)

* Event type probabilities vary modestly by group.
gen double u = runiform()
gen byte status = 0
replace status = 1 if u < (.34 - .02*grp)
replace status = 2 if u >= (.34 - .02*grp) & u < (.58 + .01*grp)

* Administrative censoring at 12 remains status 0.
replace status = 0 if dftime >= 12

stset dftime, failure(status==1)
stcrreg i.grp, compete(status==2) nolog

fgcifplot grp, values(0 1 2 3) ///
    risktimes(0 2 4 6 8 10 12) ///
    risktable(all) ///
    name(fgcifplot_stress)

di as result "fgcifplot graphical stress test completed"
