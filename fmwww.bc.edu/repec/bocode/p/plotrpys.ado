program def plotrpys
*! plotrpys LutzBornmann September 2025
version 12

syntax varlist(min=3 max=3) [if] [in] , color(string) curve(string) [TWOptions(string asis)]
local year: word 1 of `varlist'
local ncr: word 2 of `varlist'
local devmed: word 3 of `varlist'

preserve
tempvar touse
mark `touse' `if' `in'
keep if `touse'

tabstat `year' `ncr' `devmed', stat(min max range)

gen median5_p=median5 if median5>=0
quietly sum median5_p, detail
local out3 = r(p75) + 3 * (r(p75) - r(p25))
local out1 = r(p75) + 1.5 * (r(p75) - r(p25))
gen median5_v = year if median5_p > `out3' & median5_p ~= .
gen median5_l = year if median5_p > `out1' & median5_p < `out3' & median5_p ~= .
gen null = 0

gen low = invchi2(2*`ncr', 0.975)/2
gen high = invchi2(2*(`ncr'+1), 0.025)/2

set scheme white_tableau

if "`color'" == "mono" & "`curve'" == "both" {
twoway /*
*/ (rcap low high `year', yaxis(1) msize(small) mfcolor(black) mlcolor(black) lcolor(black)) /*
*/ (scatter `ncr' `year', yaxis(1) connect(l .) msize(small) mfcolor(black) mlcolor(black) lcolor(black)) /*
*/ (scatter `devmed' `year', yaxis(2) connect(l .) msize(small) mfcolor(gs11) mlcolor(gs11) lcolor(gs11)),  /*
*/ ytitle("Cited references counts with confidence interval (black line)", axis(1)) ytitle("Deviation from median (grey line)", axis(2)) /*
*/ xtitle("Reference publication year") /*
*/ legend(off) `twoptions'
}

if "`color'" == "col" & "`curve'" == "both" {
twoway /*
*/ (rcap low high `year', yaxis(1) msize(small) mfcolor(orange) mlcolor(orange) lcolor(orange)) /*
*/ (scatter `ncr' `year', yaxis(1) connect(l .) msize(small) mfcolor(orange) mlcolor(orange) lcolor(orange)) /*
*/ (scatter `devmed' `year', yaxis(2) lcolor(green%40) mfcolor(green%40) mlcolor(green%40) connect(l .) msize(small)),  /*
*/ ytitle("Cited references counts (orange line)", axis(1)) ytitle("Deviation from median (green line)", axis(2)) /*
*/ xtitle("Reference publication year") /*
*/ legend(off) `twoptions'
}

if "`color'" == "mono" & "`curve'" == "median" {
twoway (rspike median5_p null `year', lcolor(black)) /*
*/ (rspike median5_p null `year', lcolor(black)) /*
*/ (scatter median5_p `year', mfcolor(black) mlcolor(black) /*
*/ lcolor(black) msize(small) /*
*/ ytitle("Deviation from median (only positive)") /*
*/ xtitle("Reference publication year") /*
*/ mlabel(median5_v) mlabposition(1) mlabsize(5.5pt) mlabangle(90) mlabcolor(black))/*
*/ (scatter median5_p `year', mfcolor(black) mlcolor(black) /*
*/ lcolor(black) msize(small) /*
*/ ytitle("Deviation from median (only positive)") /*
*/ xtitle("Reference publication year") /*
*/ mlabel(median5_l) mlabposition(1) mlabsize(5.5pt) mlabangle(90) mlabcolor(black%60)),/*
*/ yline(`out3', lcolor(black) lwidth(thick) lpattern(dot)) /*
*/ yline(`out1', lcolor(black) lwidth(thick) lpattern(dot)) /*
*/ legend(off) `twoptions'
}

if "`color'" == "col" & "`curve'" == "median" {
twoway (rspike median5_p null `year', lcolor(blue)) /*
*/ (rspike median5_p null `year', lcolor(blue)) /*
*/ (scatter median5_p `year', mfcolor(blue) mlcolor(blue) /*
*/ lcolor(blue) msize(small) /*
*/ ytitle("Deviation from median (only positive)") /*
*/ xtitle("Reference publication year") /*
*/ mlabel(median5_v) mlabposition(1) mlabsize(5.5pt) mlabangle(90) mlabcolor(black))/*
*/ (scatter median5_p `year', mfcolor(blue) mlcolor(blue) /*
*/ lcolor(blue) msize(small) /*
*/ ytitle("Deviation from median (only positive)") /*
*/ xtitle("Reference publication year") /*
*/ mlabel(median5_l) mlabposition(1) mlabsize(5.5pt) mlabangle(90) mlabcolor(black%60)),/*
*/ yline(`out3', lcolor(black) lwidth(thick) lpattern(dot)) /*
*/ yline(`out1', lcolor(black) lwidth(thick) lpattern(dot)) /*
*/ legend(off) `twoptions'
}

if ("`color'" ~= "col") & ("`color'" ~= "mono") {
display "The color option must be 'col' or 'mono'"
}

if ("`curve'" ~= "median") & ("`curve'" ~= "both") {
display "The curve option must be 'both' or 'median'"
}

restore

end