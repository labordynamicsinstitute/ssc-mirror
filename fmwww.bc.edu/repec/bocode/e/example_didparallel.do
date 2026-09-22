** Example 1: the effect of police presence on car thefts (Di Tella and Schargrodsky, 2004)

use DS2004.dta, clear
xtset block month

* Generate the treatment indicator for blocks with a protected Jewish institution
* Such blocks receive police protection from July 1994 (month 7) onwards
gen treatvar = sameblock*(month>=7)

* Construct the difference-in-differences estimation and store the result
xtreg thefts treatvar i.month, fe r
estimates store police_crime

* Implement the parallel trends test
didparallel police_crime, treatvar(treatvar) calendar trend

** Example 2: the impact of the Grand Canal's abandonment on rebellions (Cao and Chen, 2022)

use cao_chen.dta, clear
xtset county year

* Construct the difference-in-differences estimation and store the result
reghdfe rebel canal_post, absorb(i.county i.year) vce(cluster county)
estimates store did_cao_chen

* Implement the parallel trends test over a window of 10 periods before and after treatment
didparallel did_cao_chen, treatvar(canal_post) range(-10 10) trend

** Example 3: the impact of minimum wage increases on county-level teen employment (Callaway and Sant'Anna, 2021)

use mpdta, clear
xtset countyreal year

* Generate the treatment indicator
gen treat_post = (first_treat <= year) & (first_treat > 0)
* Construct the difference-in-differences estimation and store the result
reghdfe lemp treat_post, absorb(i.countyreal i.year) vce(cluster countyreal)
estimates store mpdta_example

* Implement the parallel trends test
didparallel mpdta_example, treatvar(treat_post)

** Example 4: the impact of no-fault divorce reforms on suicide mortality (Stevenson and Wolfers, 2006)

use bacon_example.dta, clear
xtset stfips year

* Construct the difference-in-differences estimation and store the result
regress asmrs post pcinc asmrh cases i.stfips i.year, vce(cluster stfips)
estimates store bacon_example

* Implement the parallel trends test over a window of 10 periods before and after treatment
didparallel bacon_example, treatvar(post) range(-10 10)