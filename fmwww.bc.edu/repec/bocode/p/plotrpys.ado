program def plotrpys, rclass
* plotrpys v1.0.0 LutzBornmann 18July2017
version 11

quietly summarize year, detail
syntax varlist(min=3 max=3 numeric) , color(string) /*
*/ [startyr(integer `r(min)') incre(integer 50) endyr(integer `r(max)')]
local year: word 1 of `varlist'
local ncr: word 2 of `varlist'
local devmed: word 3 of `varlist'
tabstat `year', stat(min max range)

if "`color'" == "mono" {
twoway (scatter `ncr' `year', yaxis(1 2) mfcolor(white) /*
*/ connect(l .) lcolor(black) mlcolor(black) msize(small))/*
*/ (scatter `devmed' `year', mfcolor(black) mlcolor(black) /*
*/ connect(l .)  lcolor(black) msize(small)), /*
*/ ytitle("Cited references counts", axis(1)) ytitle("Deviation from median", axis(2)) /*
*/ xtitle("Reference publication year") /*
*/ legend(order(1 "Cited references counts" 2 "Deviation from median")) /*
*/ xlabel(`startyr'(`incre')`endyr')
}

if "`color'" == "col" {
twoway (scatter `ncr' `year', yaxis(1 2) mfcolor(red) /*
*/ connect(l .) lcolor(red) mlcolor(red) msize(small))/*
*/ (scatter `devmed' `year', mfcolor(blue) mlcolor(blue) /*
*/ connect(l .)  lcolor(blue) msize(small)), /*
*/ ytitle("Cited references counts", axis(1)) ytitle("Deviation from median", axis(2)) /*
*/ xtitle("Reference publication year") /*
*/ legend(order(1 "Cited references counts" 2 "Deviation from median")) /*
*/ xlabel(`startyr'(`incre')`endyr')
}

end
