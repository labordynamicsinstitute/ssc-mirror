// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 2 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 19 November 2018
// Last updated: 23 May 2023


clear all
set more off
prog drop _all


* first test as set type double, then set type float
foreach type in float double {

set type `type'

log using artbin_testing_2_`type', replace text nomsg

which artbin
which art2bin

******************************************
******************************************
* Testing 1: Sample size calculations
******************************************
******************************************

**********************************
* Superiority Binary Outcome
**********************************

// 9 //
* Pocock 1983; p 1 = 90%, p 2 = 95%, α* = 5%, β = 10%
artbin, pr(0.05 0.1) alpha(0.05) power(0.9) wald
local samplesize9 = r(n)/2

if `samplesize9'!=578 { 
	di as err "Sample size 9 is incorrect (Pocock 1983; p 1 = 90%, p 2 = 95%, α* = 5%, β = 10%).  Should be n = 578"
	exit 198
}


// 10 //
* Sealed envelope calculator; p 1 = 90%, p 2 = 80%, α = 10%, β = 20%
artbin, pr(0.1 0.2) alpha(0.1) power(0.8) wald
local samplesize10 = r(n)/2

if (`samplesize10'!=155) { 
	di as err "Sample size 10 is incorrect (Sealed envelope calculator; p 1 = 90%, p 2 = 80%, α = 10%, β = 20%).  Should be n = 155"
	exit 198
}



******************************************
******************************************
* Testing 2: Power calculations
******************************************
******************************************

clear all
set more off


**********************************
* Superiority Binary Outcome
**********************************

// 9 //
* Pocock 1983; p 1 = 90%, p 2 = 95%, α* = 5%, 2n = 1156
artbin, pr(0.05 0.1) ngroups(2) alpha(0.05) n(1156) wald
local power9 = round(r(power),0.1)

if `power9'!=0.9 { 
	di as err "Power 9 is incorrect (Pocock 1983; p 1 = 90%, p 2 = 95%, α* = 5%, 2n = 1156).  Should be 0.9"
	exit 198
}

// 10 //
* Sealed envelope calculator; p 1 = 90%, p 2 = 80%, α = 10%, 2n = 310
artbin, pr(0.1 0.2) alpha(0.1) n(310) wald
local power10 = round(r(power),0.1)

if `power10'!=0.8 { 
	di as err "Power 10 is incorrect (Sealed envelope calculator; p 1 = 90%, p 2 = 80%, α = 10%, 2n = 310).  Should be 0.8"
	exit 198
}


// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 2 **********" ///
	_n "*************************************************************"


log close

}
