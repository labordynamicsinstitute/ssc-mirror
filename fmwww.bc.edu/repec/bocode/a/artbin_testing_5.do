// Verification code for the STATA program artbin artbin v2.0.2: comparing to Cytel's EAST software
// Corresponds to Item 5 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 21 June 2021
// Last updated: 23 May 2023

clear all
set more off
prog drop _all

log using artbin_testing_5, replace text nomsg

which artbin
which art2bin

*********************************************
*********************************************
* Testing: Comparing to Cytel's East package
********************************************
*********************************************

// 1 //
artbin, pr(0.1 0.1) margin(0.2) alpha(0.1) power(0.9) wald
local samplesize1 = r(n)

if `samplesize1'!=78 { 
	di as err "Sample size does not match with EAST.  Should be n = 78"
	exit 198
}

// 2 //
artbin, pr(0.3 0.3) margin(0.1) alpha(0.05) power(0.8) wald
local samplesize2 = r(n)

if `samplesize2'!=660 { 
	di as err "Sample size does not match with EAST.  Should be n = 660"
	exit 198
}

// 3 //
artbin, pr(0.3 0.3) margin(0.05) alpha(0.05) power(0.9) wald
local samplesize3 = r(n)

if `samplesize3'!=3532 { 
	di as err "Sample size does not match with EAST.  Should be n = 3532"
	exit 198
}

// 4 //
artbin, pr(0.15 0.15) margin(0.15) alpha(0.05) power(0.9) wald
local samplesize4 = r(n)

if `samplesize4'!=240 { 
	di as err "Sample size does not match with EAST.  Should be n = 240"
	exit 198
}

// 5 //
artbin, pr(0.2 0.2) margin(0.1) alpha(0.2) power(0.8) wald
local samplesize5 = r(n)

if `samplesize5'!=290 { 
	di as err "Sample size does not match with EAST.  Should be n = 290"
	exit 198
}

// 6 //
artbin, pr(0.1 0.1) margin(0.05) alpha(0.05) power(0.9) wald
local samplesize6 = r(n)

if `samplesize6'!=1514 { 
	di as err "Sample size does not match with EAST.  Should be n = 1514"
	exit 198
}

// 7 //
artbin, pr(0.25 0.25) margin(0.2) alpha(0.05) power(0.9) wald
local samplesize7 = r(n)

if `samplesize7'!=198 { 
	di as err "Sample size does not match with EAST.  Should be n = 198"
	exit 198
}

// 8 //
artbin, pr(0.2 0.2) margin(0.15) alpha(0.05) power(0.9) wald
local samplesize8 = r(n)

if `samplesize8'!=300 { 
	di as err "Sample size does not match with EAST.  Should be n = 300"
	exit 198
}

// 9 //
artbin, pr(0.15 0.15) margin(0.05) alpha(0.05) power(0.9) wald
local samplesize9 = r(n)

if `samplesize9'!=2144 { 
	di as err "Sample size does not match with EAST.  Should be n = 2144"
	exit 198
}

// 10 //
artbin, pr(0.9 0.9) margin(-0.023) alpha(0.05) power(0.9) wald ar(1 2)
local samplesize10 = r(n)

if `samplesize10'!=8045 { 
	di as err "Sample size does not match with EAST.  Should be n = 8045"
	exit 198
}

// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 5 **********" ///
	_n "*************************************************************"


log close