// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 3 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 19 November 2018
// Last updated: 23 May 2023

clear all
set more off
prog drop _all


* first test as set type double, then set type float
foreach type in float double {

set type `type'

log using artbin_testing_3_`type', replace text nomsg

which artbin
which art2bin

* Testing against other programmes: -POWER-
***********************************************************************************
* Testing artbin NI trials with continuity correction against the output of power
***********************************************************************************

* p0 = 0.95, p1 = 0.9, α = 5%, β = 10%
power twoproportions 0.05 0.1, alpha(0.05) power(0.9) continuity // 621*2 = 1242
local sp1 = r(N1)
artbin, pr(0.05 0.1) margin(0) alpha(0.05) power(0.9) ccorrect alg // 1242
local ac1 = r(n)/2
if `sp1' != `ac1' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}


* p0 = 0.97, p1 = 0.93, α = 5%, β = 5%
power twoproportions 0.03 0.07, alpha(0.05) power(0.95) continuity  // 818*2 = 1636
local sp2 = r(N1)
artbin, pr(0.03 0.07) margin(0) alpha(0.05) power(0.95) ccorrect alg // 1636
local ac2 = r(n)/2
if `sp2' != `ac2' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}


* p0 = 0.9, p1 = 0.8, α = 5%, β = 15%
power twoproportions 0.1 0.2, alpha(0.05) power(0.85) continuity // 247*2 = 494
local sp3 = r(N1)
artbin, pr(0.1 0.2) margin(0) alpha(0.05) power(0.85) ccorrect alg // 494
local ac3 = r(n)/2
if `sp3' != `ac3' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}


* p0 = 0.9, p1 = 0.99, α = 2.5%, β = 20%
power twoproportions 0.1 0.01, alpha(0.025) power(0.80) continuity // 143*2 = 286
local sp4 = r(N1)
artbin, pr(0.1 0.01) margin(0) alpha(0.025) power(0.8) ccorrect alg // 286
local ac4 = r(n)/2
if `sp4' != `ac4' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}



* p0 = 0.85, p1 = 0.8, α = 10%, β = 10%
power twoproportions 0.15 0.2, alpha(0.1) power(0.90) continuity // 1027*2 = 2054
local sp5 = r(N1)
artbin, pr(0.15 0.2) margin(0) alpha(0.1) power(0.90) ccorrect alg // 2054
local ac5 = r(n)/2
if `sp5' != `ac5' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}


* p0 = 0.7, p1 = 0.9, α = 5%, β = 10%
power twoproportions 0.3 0.1, alpha(0.05) power(0.90) continuity // 92*2 = 184
local sp6 = r(N1)
artbin, pr(0.3 0.1) margin(0) alpha(0.05) power(0.90) ccorrect  // 184
local ac6 = r(n)/2
if `sp6' != `ac6' {
di as err "power and artbin continuity correction output do not match"
	exit 198
}



// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 3 **********" ///
	_n "*************************************************************"


log close

}
