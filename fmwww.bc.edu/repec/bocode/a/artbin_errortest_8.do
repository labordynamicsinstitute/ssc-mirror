
******************************
* Testing Artbin Error Codes
*******************************
// artbin v 2.0.2
// Corresponds to Item 8 in the artbin Stata Journal Software Testing Section
// Last updated 23 May 2023

clear all
set more off
prog drop _all

log using artbin_errortest_8,  replace text nomsg

which artbin 
which art2bin

* Trying incorrect/missing values of p() 
********************************************

* No value for pr()
cap noi artbin, pr() alpha(0.05) power(0.90) 
* gives "option pr() required" as expected

* One value of pr()
cap noi artbin, pr(.05) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has too few elements" as expected

* One value of pr(), but ngroups(2)
cap noi artbin, pr(.05) ngroups(2) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has too few elements" as expected

* One value of pr() which is out of range
cap noi artbin, pr(1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* Control probability out of range
cap noi artbin, pr(1.1 0.5) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* Treatment probability out of range
cap noi artbin, pr(0.5 1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* similarly, really high treatment probability
cap noi artbin, pr(0.5 100) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, NI design, ngroups(2)
cap noi artbin, pr(0.5 0.8 0.3) margin(0.1) ngroups(2) alpha(0.05) power(0.90) 
* gives "Can not have margin with >2 groups" (as expected) 

* 3 groups of probability, NI design, ngroups(3)
cap noi artbin, pr(0.5 0.8 0.3) margin(0.1) ngroups(3) alpha(0.05) power(0.90) 
* gives "Can not have margin with >2 groups" (as expected) 

* 3 groups of probability, Superiority design, ngroups(2)
artbin, pr(0.5 0.8 0.3) ngroups(2) alpha(0.05) power(0.90) 
* gives a WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored (as expected). 

* 3 groups of probability, NI design, one probability out of range
cap noi artbin, pr(0.5 0.8 1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 1 out of range
cap noi artbin, pr(1.1 0.8 0.5) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 2 out of range
cap noi artbin, pr(0.8 1.1 0.5) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 3 out of range
cap noi artbin, pr(0.5 0.8 1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 1 and 2 out of range
cap noi artbin, pr(1.1 1.1 0.5) alpha(0.05) power(0.90)
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 1 and 3 out of range
cap noi artbin, pr(1.1 0.5 1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, probability 2 and 3 out of range
cap noi artbin, pr(0.5 1.1 1.1) alpha(0.05) power(0.90)  
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* 3 groups of probability, no specified design, all probabilities out of range
cap noi artbin, pr(1.1 1.1 1.1) alpha(0.05) power(0.90) 
* gives "pr() invalid -- invalid numlist has elements outside of allowed range" as expected

* Same control and treatment proportions
cap noi artbin, pr(0.1 0.1) alpha(0.05) power(0.9) 
* gives "Event probabilities can not be equal with 2 groups" (as expected)


* Trying incorrect/missing values of alpha 
********************************************

* Missing alpha
cap noi artbin, pr(0.05 0.1) alpha() power(0.90) 
* gives "option alpha() incorrectly specified" (as expected)

* Alpha in superiority trial
artbin, pr(0.1 0.2) alpha(0.1) power(0.8) 
* output says alpha is 2-sided, can be for superiority trial (Ian confirmed)

* Alpha out of range: 0
cap noi artbin, pr(0.1 0.2) alpha(0) power(0.8) 
* gives error message "alpha() out of range" as expected

* Alpha out of range: 1
cap noi artbin, pr(0.1 0.2) alpha(1) power(0.8) 
* gives error message "alpha() out of range" as expected

* Alpha out of range: 100
cap noi artbin, pr(0.1 0.2) alpha(100) power(0.8) 
* gives error message "alpha() out of range" as expected

* Alpha out of range: -0.05
cap noi artbin, pr(0.1 0.2) alpha(-0.05) power(0.8) 
* gives error message "alpha() out of range" as expected


* Trying incorrect/missing values of power 
********************************************

* Missing power
cap noi artbin, pr(0.05 0.1) alpha(0.05) power() 
* gives the error message "option power() incorrectly specified" as required

* Power out of range: 0
cap noi artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) power(0) 
* gives the error message "power() out of range" as required

* Power out of range: 1
cap noi artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) power(1) 
* gives the error message "power() out of range" as required

* Power out of range: 100
cap noi artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) power(100) 
* gives the error message "power() out of range" as required

* Power out of range: -0.8
cap noi artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) power(-0.8) 
* gives the error message "power() out of range" as required


* Trying incorrect/missing values of n (if power is being calculated instead) 
******************************************************************************

* Missing n
cap noi artbin, pr(0.05 0.1) alpha(0.05) n() 
* gives the error message "option n() incorrectly specified" as required

* n out of range: 0
artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) n(0) 
* gives a result with a calculated sample size and a designed power of 0.8 as expected (by specifying n(0) / n() missing, sample size will be calculated by artbin)

* very low n: 1
artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) n(1) 
* calculates power, as expected

* very high n: 1,000,000
artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) n(1000000) 
* gives a power of 1 as expected (Ian confirmed)

* n out of range: -500
cap noi artbin, pr(0.05 0.1) margin(0.1) alpha(0.05) n(-500) 
* Gives the error message "Sample size n() out of range" as required


* Testing error code: if margin & ((`npr'>2)|(`ngroups'>2)) di as err "Only two groups allowed for non-inferiority/substantial superiority designs" Can not have margin with >2 groups/"
*************************************************************************************************************************************************

* npr>2, sample size calculated, NI
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) power(0.8) 
* gives the error code "Can not have margin with >2 groups" as required


* ngroups>2, sample size calculated, NI
artbin, pr(0.05 0.1) margin(0.1) ngroups(3) alpha(0.05) power(0.8) 
* gives the a result and a warning message as expected: WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.

* npr>2 and ngroups>2, sample size calculated, NI
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) power(0.8) 
* gives the error code "Can not have margin with >2 groups" as required

* npr>2, ngroups<npr, sample size calculated, superiority
artbin, pr(0.05 0.1 0.2) ngroups(2) alpha(0.05) power(0.8) 
* gives the message WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.


* ngroups>2, ngroups>npr, sample size calculated, superiority
artbin, pr(0.05 0.1) ngroups(3) alpha(0.05) power(0.8) 
* gives the message WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.

* npr>2, power calculated, NI
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) ngroups(2) alpha(0.05) n(500) 
* gives the error code "Can not have margin with >2 groups" as required


* ngroups>2, power calculated, NI
artbin, pr(0.05 0.1) margin(0.1) ngroups(3) alpha(0.05) n(500) 
* gives the a result and a warning message as expected: WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.

* npr>2 and ngroups>2, power calculated, NI
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) n(500) 
* gives the error code "Can not have margin with >2 groups" as required

* npr>2, power calculated, superiority
artbin, pr(0.05 0.1 0.2) ngroups(2) alpha(0.05) n(500) 
* gives the a result and a warning message as expected: WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.

* ngroups>2, power calculated, superiority
artbin, pr(0.05 0.1) ngroups(3) alpha(0.05) n(500) 
* gives the a result and a warning message as expected: WARNING: Mismatch between the number of proportions and the number of groups specified - ngroups value will be ignored.


* Testing the error code if `ccorrect' & (`ngroups'>2) di as err "Correction for contituity not allowed in comparison of > 2 groups"
*************************************************************************************************************************************

* superiority, power to be calculated
cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) n(500) ccorrect(1)
* gives error code "Correction for contituity not allowed in comparison of > 2 groups" as required

* superiority, sample size to be calculated
cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) ccorrect(1)
* gives error code "Correction for contituity not allowed in comparison of > 2 groups" as required

* non-inferiority, power to be calculated
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) n(500) ccorrect(1)
* gives the error code "Can not have margin with >2 groups" as required

* non-inferiority, sample size to be calculated
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) ccorrect(1)
* gives the error code "Can not have margin with >2 groups" as required


* Testing the error code if `onesided' & (`ngroups'>2) di as err "One-sided not allowed in comparison of > 2 groups"
*********************************************************************************************************************

* superiority, power to be calculated
cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) onesided(1) n(100) 
* get the error code "One-sided not allowed in comparison of > 2 groups" as required

cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) onesided n(100) 
* get the error code "One-sided not allowed in comparison of > 2 groups" as required

* superiority, sample size to be calculated
cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) onesided(1) power(0.8) 
* get the error code "One-sided not allowed in comparison of > 2 groups" as required

cap noi artbin, pr(0.05 0.1 0.2) alpha(0.05) onesided power(0.8) 
* get the error code "One-sided not allowed in comparison of > 2 groups" as required

* non-inferiority, power to be calculated
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) onesided(1) n(500) 
* get the error code "Can not have margin with >2 groups" which has superseeded the one-sided error code.

cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) onesided n(500) 
* get the error code "Can not have margin with >2 groups" which has superseeded the one-sided error code.

* non-inferiority, sample size to be calculated
cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) onesided(1) power(0.8) 
* get the error code "Can not have margin with >2 groups" which has superseeded the one-sided error code.

cap noi artbin, pr(0.05 0.1 0.2) margin(0.1) alpha(0.05) onesided power(0.8) 
* get the error code "Can not have margin with >2 groups" which has superseeded the one-sided error code.


* Testing the error code if `ap2'<0 | `ap2'>1 di as err  "Group 2 event probability under the alternative hypothesis must be >0 & <1" (only for NI trials)
*************************************************************************************************************************************************************

* sample size to be calculated, ap2<0
cap noi artbin, pr(0.2 0.2) margin(0.1) alpha(0.05) power(0.8) ap2(-0.1) 
* get the error code "Group 2 event probability under the alternative hypothesis must be >0 & <1" as required.

* power to be calculated, ap2<0
cap noi artbin, pr(0.2 0.2) margin(0.1) alpha(0.05) n(500) ap2(-0.1)
* get the error code "Group 2 event probability under the alternative hypothesis must be >0 & <1" as required.

* sample size to be calculated, ap2>1
cap noi artbin, pr(0.2 0.2) margin(0.1) alpha(0.05) power(0.8) ap2(1.5) 
* get the error code "Group 2 event probability under the alternative hypothesis must be >0 & <1" as required.

* power to be calculated, ap2>1
cap noi artbin, pr(0.2 0.2) margin(0.1) alpha(0.05) n(500) ap2(1.5)
* get the error code "Group 2 event probability under the alternative hypothesis must be >0 & <1" as required.


* test error code for aratios
**********************************
cap noi artbin, pr(.1 .2 .3) ar(2)	
* gives error code as required.


* Check that local and wald not allowed together
*************************************************
cap noi artbin, pr(0.1 0.2) local wald
* error message as required: Local and Wald not allowed together


* Check that local and nvm!=3 not allowed together
*****************************************************
cap noi artbin, pr(0.1 0.2) local nvm(1)
* error message as required: Need nvm(3) if local specified
cap noi artbin, pr(0.1 0.2 0.3) local nvm(1)
* error message as required: Need nvm(3) if local specified
cap noi artbin, pr(0.1 0.2) local nvm(2)
* error message as required: Need nvm(3) if local specified
cap noi artbin, pr(0.1 0.2 0.3) local nvm(2)
* error message as required: Need nvm(3) if local specified


* Check that wald and nvm!=1 not allowed together
***************************************************
cap noi artbin, pr(0.1 0.2) wald nvm(2)
* error message as required: Need nvm(1) if Wald specified
cap noi artbin, pr(0.1 0.2 0.3) wald nvm(2)
* error message as required: Need nvm(1) if Wald specified
cap noi artbin, pr(0.1 0.2) wald nvm(3)
* error message as required: Need nvm(1) if Wald specified
cap noi artbin, pr(0.1 0.2 0.3) wald nvm(3)
* error message as required: Need nvm(1) if Wald specified
	

* Test incorrect ltfu() inputs
**********************************
cap noi artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(2)
cap noi artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(-1)	
cap noi artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(0)
cap noi artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(1)
* Error messages as required


******************************************************************************************************
* Testing when there is a mismatch between number of groups (ngroups) and number of proportions (npr)
*******************************************************************************************************

*Number of groups less than number of proportions:
*******************************************************

artbin, pr(0.1 0.2 0.3) ngroups(2)
local samplesize1 = r(n)/2
* check the same as
artbin, pr(0.1 0.2 0.3) ngroups(3)
local samplesize2 = r(n)/2

if `samplesize1'!=`samplesize2' { 
	di as err "result is not as expected"
	exit 198
}

artbin, pr(0.1 0.2 0.3 0.4) ngroups(3)
local samplesize3 = r(n)/2
* check the same as
artbin, pr(0.1 0.2 0.3 0.4) ngroups(4)
local samplesize4 = r(n)/2

if `samplesize3'!=`samplesize4' { 
	di as err "result is not as expected"
	exit 198
}

artbin, pr(0.1 0.2 0.3 0.4 0.5) ngroups(3)
local samplesize5 = r(n)/2
* check the same as
artbin, pr(0.1 0.2 0.3 0.4 0.5) ngroups(5)
local samplesize6 = r(n)/2

if `samplesize5'!=`samplesize6' { 
	di as err "result is not as expected"
	exit 198
}

*Number of groups more than number of proportions:
******************************************************

artbin, pr(0.1 0.2) ngroups(3)
local samplesize7 = r(n)/2
* check the same as
artbin, pr(0.1 0.2) ngroups(2)
local samplesize8 = r(n)/2

if `samplesize7'!=`samplesize8' { 
	di as err "result is not as expected"
	exit 198
}

artbin, pr(0.1 0.2 0.3) ngroups(4)
local samplesize9 = r(n)/2
* check the same as
artbin, pr(0.1 0.2 0.3) ngroups(3) 
local samplesize10 = r(n)/2
* used to be the same as: artbin_EMZ, pr(0.1 0.2 0.3 0.2) ngroups(4) because created p4 as average of p1,p2,p3

if `samplesize9'!=`samplesize10' { 
	di as err "result is not as expected"
	exit 198
}

artbin, pr(0.1 0.2 0.3) ngroups(5)
local samplesize11 = r(n)/2
* check the same as
artbin, pr(0.1 0.2 0.3) ngroups(3) 
local samplesize12 = r(n)/2

if `samplesize11'!=`samplesize12' { 
	di as err "result is not as expected"
	exit 198
}

	
// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINTS 8 *********" ///
	_n "*************************************************************"
	
	
log close
