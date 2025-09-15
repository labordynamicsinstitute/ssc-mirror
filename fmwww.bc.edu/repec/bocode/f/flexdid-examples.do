clear all

webuse hhabits

// manually create the cohort variable - not needed but useful to check things
// and to use as the treatment group if desired
egen chrt = min(year/hhabit), by(schools)
replace chrt = 0 if chrt==.

preserve
bysort schools: keep if _n==1
tab chrt
restore


// basic setup and post-estimation aggregation options
flexdid bmi, tx(hhabit) group(schools) time(year)
estat atet, overall(0 3)
estat atet, byexposure
estat atet, byexposure nograph
estat atet, byexposure graph(name(ex, replace))
estat atet, byexposure(0(1)3) graph(name(exc, replace))
estat atet, bycalendar graph(name(ca, replace))
estat atet, bycalendar(2035 2038) graph(name(cac, replace))
estat atet, bycohort graph(name(co, replace))
estat atet, bycohort(2034 2036 2038) graph(name(coc, replace))
estat atet, bygroup(1 31 33 34) graph(name(grc, replace))


// how to use margins to compute effects not included in estat atet
margins r._Tx, subpop(if _Tx==1) over(_Chrt year) contrast(effects nowald) vce(unconditional) noestimcheck noomit


// how to use sampling weights
flexdid bmi [pw=parksd], tx(hhabit) group(schools) time(year)


// use vce(robust)
flexdid bmi, tx(hhabit) group(schools) time(year) vce(robust)


// lags and leads specifications with post-estimation aggregation options
flexdid bmi, tx(hhabit) gr(schools) ti(year) specification(lagsandleads)
estat atet, byexposure graph(name(llex, replace))
estat atet, byexposure(-3(1)3) graph(name(llexc, replace))
estat atet, bycohort graph(name(llco, replace))
estat atet, bycalendar graph(name(llca, replace))
estat atet, overall(-6(1)-2)


// confirm that flex gives same (c,t) estimates as cs
flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools) specification(lagsandleads) verbose

hdidregress ra (bmi) (hhabit), group(schools) time(year) basetime(common)
estat aggregation


// but can be more flexible by estimating treatment at cohortXyear level and fixed effects at the group level
flexdid bmi, tx(hhabit) gr(schools) txgr(chrt) ti(year) vce(cluster schools) specification(lagsandleads) verbose


// include covariates with options to include no interactions or only some interactions
flexdid bmi medu, tx(hhabit) gr(schools) ti(year) verbose
flexdid bmi medu sports girl, tx(hhabit) gr(schools) ti(year) verbose noxinteract
flexdid bmi medu sports girl, tx(hhabit) group(schools) time(year) xinteract(medu) verbose

// what if some years of data are missing - especially cohort years
preserve
drop if inlist(year,2036,2039)

*** flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools) specification(lagsandleads) verbose
*** will lead to an error message. equivalent "naive" specifications in 
*** hdidregress and csdid produce estimates that are minimally mislabeled 
*** and often "wrong" because cohorts get incorrectly defined.

*** define the cohort variable and use usercohort() to get it right

flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools) usercohort(chrt) specification(lagsandleads) verbose
estat atet, byexposure graph(name(exwmiss, replace))

restore


// what if treatment is not always 0 or always 1 in some groups and/or in some years
preserve
set seed 123456
replace hhabit = 0 if runiform()<.3 & hhabit==1

flexdid bmi, tx(hhabit) group(schools) usercohort(chrt) ti(year) specification(lagsandleads)

restore

exit
