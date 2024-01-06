// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 6 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 19 November 2018
// Last updated: 23 May 2023
// Uses onesided 'swich on/off' option for one/two-sided

clear all
set more off
prog drop _all


* first test as set type double, then set type float
foreach type in float double {

set type `type'

log using artbin_testing_6_`type', replace text nomsg

which artbin
which art2bin

* checking the results are the same using -onesided- as obtained using -onesided(1)- in artbin_testing_4.do

* All of the below is tested against Julious 2011, Table 4, where p0 = (1-pie_C) and p1 = (1-pie_T), margin=d.  Alpha is one-sided (2.5%). 

* p0 = 0.7, p1 = 0.9, d=0.2, α = 2.5%, β = 10%
artbin, pr(0.3 0.1) margin(0.2) alpha(0.025) onesided power(0.9) nvm(1)  // 40
local samplesize14 = r(n)/2

if `samplesize14'!=20 { 
	di as err "Margins calculations: Sample size 14 is incorrect, Should be n = 20"
	exit 198
}

* p0 = 0.75, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.25 0.15) margin(0.1) alpha(0.025) onesided power(0.9) nvm(1) // 166       
local samplesize15 = r(n)/2

if `samplesize15'!=83 { 
	di as err "Margins calculations: Sample size 15 is incorrect, Should be n = 83"
	exit 198
}

* p0 = 0.8, p1 = 0.7, d=0.15, α = 2.5%, β = 10%
artbin, pr(0.2 0.3) margin(0.15) alpha(0.025) onesided power(0.9) nvm(1) // 3112
local samplesize16 = r(n)/2

if `samplesize16'!=1556 { 
	di as err "Margins calculations: Sample size 16 is incorrect, Should be n = 1556"
	exit 198
}

* p0 = 0.85, p1 = 0.8, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.15 0.2) margin(0.1) alpha(0.025) onesided power(0.9) nvm(1) // 2418
local samplesize17 = r(n)/2

if `samplesize17'!=1209 { 
	di as err "Margins calculations: Sample size 17 is incorrect, Should be n = 1209"
	exit 198
}


* p0 = 0.9, p1 = 0.9, d=0.05, α = 2.5%, β = 10%
artbin, pr(0.1 0.1) margin(0.05) alpha(0.025) onesided power(0.9) nvm(1) // 1514
local samplesize18 = r(n)/2

if `samplesize18'!=757 { 
	di as err "Margins calculations: Sample size 18 is incorrect, Should be n = 757"
	exit 198
}


* p0 = 0.7, p1 = 0.75, d=0.15, α = 2.5%, β = 10%
artbin, pr(0.3 0.25) margin(0.15) alpha(0.025) onesided power(0.9) nvm(1) // 210
local samplesize19 = r(n)/2

if `samplesize19'!=105 { 
	di as err "Margins calculations: Sample size 19 is incorrect, Should be n = 105"
	exit 198
}

* p0 = 0.75, p1 = 0.75, d=0.2, α = 2.5%, β = 10%
artbin, pr(0.25 0.25) margin(0.2) alpha(0.025) onesided power(0.9) nvm(1)
local samplesize20 = r(n)/2

if `samplesize20'!=99 { 
	di as err "Margins calculations: Sample size 20 is incorrect, Should be n = 99"
	exit 198
}

* p0 = 0.8, p1 = 0.9, d=0.05, α = 2.5%, β = 10%
artbin, pr(0.2 0.1) margin(0.05) alpha(0.025) onesided power(0.9) nvm(1)
local samplesize21 = r(n)/2

if `samplesize21'!=117 { 
	di as err "Margins calculations: Sample size 21 is incorrect, Should be n = 117"
	exit 198
}

* p0 = 0.85, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.15 0.15) margin(0.1) alpha(0.025) onesided power(0.9) nvm(1)
local samplesize22 = r(n)/2

if `samplesize22'!=268 { 
	di as err "Margins calculations: Sample size 22 is incorrect, Should be n = 268"
	exit 198
}


* p0 = 0.9, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
artbin, pr(0.1 0.15) margin(0.1) alpha(0.025) onesided power(0.9) nvm(1)
local samplesize23 = r(n)/2

if `samplesize23'!=915  { 
	di as err "Margins calculations: Sample size 23 is incorrect, Should be n = 915"
	exit 198
}



*************************************************
* Testing onesided switch on-off options
*************************************************
* Note ni is no longer used, nvm(1) is now wald

** onesided switch on or off

artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) power(0.8) wald
// onesided() is blank, TWO-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided(0) power(0.8) wald
// onesided(0), TWO-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided(1) power(0.8) wald
// onesided(1), ONE-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided(2) power(0.8) wald
// onesided(2), ONE-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided power(0.8) wald
// onesided exists, ONE-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided onesided(1) power(0.8) wald
// onesided exists, onesided(1), ONE-SIDED as required
artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided onesided(2) power(0.8) wald
// onesided exists, onesided(2), ONE-SIDED as required


* Error codes for incorrect specifications
cap noi artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided onesided(0) power(0.8) wald
// error code as required (Can not select both one-sided and two-sided)
cap noi artbin, pr(0.3 0.4) ngroups(2) alpha(0.05) onesided(0) onesided power(0.8) wald
// error code as required (Can not select both one-sided and two-sided)


* Checking ccorrect 
**********************

artbin, pr(0.1 0.3) ccorrect

artbin, pr(0.1 0.3) nchi ccorrect

artbin, pr(0.1 0.3) ccorrect(1)

artbin, pr(0.1 0.3) nchi ccorrect(1)

artbin, pr(0.1 0.3) ccorrect ccorrect(1)

cap noi artbin, pr(0.1 0.3) ccorrect ccorrect(0)
* gives error message as required

cap noi artbin, pr(0.1 0.3) condit ccorrect
* gives error message as required

cap noi artbin, pr(0.1 0.3) margin(0) condit ccorrect
* gives error message as required



// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 6 **********" ///
	_n "*************************************************************"


log close

}
