program def plotrpys
*! plotrpys LutzBornmann September 2025
version 13

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
gen nc_median5_v = year if median5_p >= `out3' & median5_p ~= .
gen median5_v = string(nc_median5_v)
replace median5_v = "" if missing(nc_median5_v)
gen nc_median5_l = year if median5_p >= `out1' & median5_p <= `out3' & median5_p ~= .
gen median5_l = string(nc_median5_l)
replace median5_l = "" if missing(nc_median5_l)
gen null = 0

gen low = invchi2(2*`ncr', 0.975)/2
gen high = invchi2(2*(`ncr'+1), 0.025)/2

tsset year
radf ncr, maxlag(1) prefix(_t)
lab var _tBSADF "tBSADF"
lab var _tBSADF_95 "tBSADF 95%"
lab var _tBSADF_90 "tBSADF 90%"

set scheme white_tableau

if "`color'" == "mono" & "`curve'" == "both" {
twoway /*
*/ (rcap low high `year', yaxis(1) msize(small) mfcolor(black%40) mlcolor(black%40) lcolor(black%40)) /*
*/ (bar `ncr' `year', yaxis(1) fcolor(black%20) lcolor(black%20)) /*
*/ (scatter `devmed' `year', yaxis(2) connect(l .) msize(small) mfcolor(black) mlcolor(black) lcolor(black)),  /*
*/ ytitle("Cited references counts with confidence interval (grey bars)", axis(1)) ytitle("Deviation from median (black line)", axis(2)) /*
*/ xtitle("Reference publication year") /*
*/ legend(off) `twoptions'
}

if "`color'" == "col" & "`curve'" == "both" {
twoway /*
*/ (rcap low high `year', yaxis(1) msize(small) mfcolor(orange%40) mlcolor(orange%40) lcolor(orange%40)) /*
*/ (bar `ncr' `year', yaxis(1) fcolor(orange%20) lcolor(orange%20)) /*
*/ (scatter `devmed' `year', yaxis(2) lcolor(green%40) mfcolor(green%40) mlcolor(green%40) connect(l .) msize(small)),  /*
*/ ytitle("Cited references counts with confidence interval (orange line)", axis(1)) ytitle("Deviation from median (green line)", axis(2)) /*
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

if "`color'" == "mono" & "`curve'" == "exp" {
twoway connected _tBSADF _tBSADF_95 _tBSADF_90 year if _tBSADF ~= . , /*
*/ mcolor(black gs10 gs10) msymbol(i i i) lcolor(black gs10 gs10) lpattern(solid longdash dash) /*
*/ ytitle({it:t} statistics) xtitle(Reference publication year) legend(ring(1) position(6) cols(3)) /*
*/ legend(ring(1) position(6) cols(3)) `twoptions'
}

if "`color'" == "col" & "`curve'" == "exp" {
twoway connected _tBSADF _tBSADF_95 _tBSADF_90 year if _tBSADF ~= . , /*
*/ mcolor(blue gs10 gs10) msymbol(i i i) lcolor(blue gs10 gs10) lpattern(solid longdash dash) /*
*/ ytitle({it:t} statistics) xtitle(Reference publication year) legend(ring(1) position(6) cols(3)) /*
*/ legend(ring(1) position(6) cols(3)) `twoptions'
}

if ("`color'" ~= "col") & ("`color'" ~= "mono") {
display "The color option must be 'col' or 'mono'"
}

if ("`curve'" ~= "median") & ("`curve'" ~= "both") & ("`curve'" ~= "exp") {
display "The curve option must be 'both' or 'median' or 'exp'"
}

restore

end