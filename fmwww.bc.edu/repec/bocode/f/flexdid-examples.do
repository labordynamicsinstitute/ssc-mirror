clear all

webuse hhabits

// manually create the cohort variable - to use as the treatment group if desired
egen chrt = min(year/hhabit), by(schools)
replace chrt = 0 if chrt==.

preserve
bysort schools: keep if _n==1
tab chrt
restore

// basic setup
flexdid bmi, tx(hhabit) group(schools) time(year)

// post-estimation aggregation
estat atet, byexposure
estat atet, bycalendar
estat atet, bycohort
estat atet, bygroup

// Adding tests, options and refining aggregation
estat atet, overall(0/3)
estat atet, byexposure test(zero)
estat atet, byexposure test(equal) nograph


// how to use sampling weights
flexdid bmi [pw=parksd], tx(hhabit) group(schools) time(year)


// lags and leads specification using chrt as the group
flexdid bmi, tx(hhabit) gr(chrt) ti(year) specification(lagsandleads) vce(cluster schools)

// this is a parallel pre-trend test
estat atet, byget(-6/-2) test(zero)

// is there heterogeneity of group-time effects?
estat atet, byget(0/6) test(equal)

// this is a parallel pre-trend test aligned with the event-study plot
estat atet, byexposure(-6/-2) test(zero)

// are effects zero/equal at the exposure time level
estat atet, byexposure(0/6) test(zero) nograph
estat atet, byexposure(0/6) test(equal) nograph


// FLEX allows estimating treatment at cohortXyear level and fixed effects at the group level
flexdid bmi, tx(hhabit) gr(schools) txgr(chrt) ti(year) vce(cluster schools) specification(lagsandleads) verbose


// include covariates
flexdid bmi medu, tx(hhabit) group(chrt) time(year) vce(cluster schools)

// aggregation can be stratified by covariate levels
estat atet, byexposure for(girl==0) nograph
estat atet, bycohort for(medu<10) nograph


// include covariates with options to include no interactions or only some interactions
flexdid bmi medu sports i.girl, tx(hhabit) gr(schools) ti(year) noxinteract
flexdid bmi medu sports i.girl, tx(hhabit) group(schools) time(year) xinteract(medu)

// what if some years of data are missing - especially cohort years
preserve
drop if inlist(year,2036,2039)

*** flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools) specification(lagsandleads)
*** will lead to an error message. 
*** define the cohort variable and use usercohort() to get it right

flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools) usercohort(chrt) specification(lagsandleads) verbose
estat atet, byexposure graph(name(exwmiss, replace))

restore


// what if treatment is not always 0 or always 1 in some groups and/or in some years
preserve
set seed 123456
replace hhabit = 0 if runiform()<.3 & hhabit==1

flexdid bmi, tx(hhabit) group(chrt) ti(year) specification(lagsandleads)

restore

exit
