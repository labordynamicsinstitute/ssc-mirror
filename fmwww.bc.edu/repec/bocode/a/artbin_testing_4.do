// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 4 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 19 November 2018
// Last updated: 23 May 2023

clear all
set more off
prog drop _all


* first test as set type double, then set type float
foreach type in float double {

set type `type'

log using artbin_testing_4_`type', replace text nomsg

which artbin
which art2bin

****************************************************************************************************************************************************
****************************************************************************************************************************************************
* Testing margin option in artbin
****************************************************************************************************************************************************
****************************************************************************************************************************************************

clear all

* All of the below is tested against Julious 2011, Table 4, where p0 = (1-pie_C) and p1 = (1-pie_T), margin=d.  Alpha is one-sided (2.5%). 

* p0 = 0.7, p1 = 0.9, d=0.2, α = 2.5%, β = 10%
artbin, pr(0.3 0.1) margin(0.2) alpha(0.025) onesided(1) power(0.9) wald alg // 40
local samplesize12 = r(n)/2

if `samplesize12'!=20 { 
	di as err "Margins calculations: Sample size 12 is incorrect, Should be n = 20"
	exit 198
}

* p0 = 0.75, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.25 0.15) margin(0.1) alpha(0.025) onesided(1) power(0.9) wald alg // 166       
local samplesize13 = r(n)/2

if `samplesize13'!=83 { 
	di as err "Margins calculations: Sample size 13 is incorrect, Should be n = 83"
	exit 198
}

* p0 = 0.8, p1 = 0.7, d=0.15, α = 2.5%, β = 10%
artbin, pr(0.2 0.3) margin(0.15) alpha(0.025) onesided(1) power(0.9) wald alg // 3112
local samplesize14 = r(n)/2

if `samplesize14'!=1556 { 
	di as err "Margins calculations: Sample size 14 is incorrect, Should be n = 1556"
	exit 198
}

* p0 = 0.85, p1 = 0.8, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.15 0.2) margin(0.1) alpha(0.025) onesided(1) power(0.9) wald alg // 2418
local samplesize15 = r(n)/2

if `samplesize15'!=1209 { 
	di as err "Margins calculations: Sample size 15 is incorrect, Should be n = 1209"
	exit 198
}


* p0 = 0.9, p1 = 0.9, d=0.05, α = 2.5%, β = 10%
artbin, pr(0.1 0.1) margin(0.05) alpha(0.025) onesided(1) power(0.9) wald alg // 1514
local samplesize16 = r(n)/2

if `samplesize16'!=757 { 
	di as err "Margins calculations: Sample size 16 is incorrect, Should be n = 757"
	exit 198
}


* p0 = 0.7, p1 = 0.75, d=0.15, α = 2.5%, β = 10%
artbin, pr(0.3 0.25) margin(0.15) alpha(0.025) onesided(1) power(0.9) wald alg // 210
local samplesize17 = r(n)/2

if `samplesize17'!=105 { 
	di as err "Margins calculations: Sample size 17 is incorrect, Should be n = 105"
	exit 198
}

* p0 = 0.75, p1 = 0.75, d=0.2, α = 2.5%, β = 10%
artbin, pr(0.25 0.25) margin(0.2) alpha(0.025) onesided(1) power(0.9) wald alg // 198
local samplesize18 = r(n)/2

if `samplesize18'!=99 { 
	di as err "Margins calculations: Sample size 18 is incorrect, Should be n = 99"
	exit 198
}

* p0 = 0.8, p1 = 0.9, d=0.05, α = 2.5%, β = 10%
artbin, pr(0.2 0.1) margin(0.05) alpha(0.025) onesided(1) power(0.9) wald alg // 234
local samplesize19 = r(n)/2

if `samplesize19'!=117 { 
	di as err "Margins calculations: Sample size 19 is incorrect, Should be n = 117"
	exit 198
}

* p0 = 0.85, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.15 0.15) margin(0.1) alpha(0.025) onesided(1) power(0.9) wald alg // 536
local samplesize20 = r(n)/2

if `samplesize20'!=268 { 
	di as err "Margins calculations: Sample size 20 is incorrect, Should be n = 268"
	exit 198
}


* p0 = 0.9, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.1 0.15) margin(0.1) alpha(0.025) onesided(1) power(0.9) wald alg // 1830
local samplesize21 = r(n)/2

if `samplesize21'!=915 { 
	di as err "Margins calculations: Sample size 21 is incorrect, Should be n = 915"
	exit 198
}



// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 4 **********" ///
	_n "*************************************************************"


log close

}
