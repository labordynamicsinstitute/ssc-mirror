// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 1 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 19 November 2018
// Last updated: 23 May 2023


clear all
set more off
prog drop _all


* first test as set type double, then set type float
foreach type in float double {

set type `type'

log using artbin_testing_1_`type', replace text nomsg

which artbin
which art2bin

******************************************
******************************************
* Testing 1: Sample size calculations
******************************************
******************************************


* Non-inferiority Binary Outcome
**********************************

// 1 //
* Blackwelder 1982; p = 90%, d = 20%, α = 5%, β = 10%
artbin, pr(0.1 0.1) margin(0.2) ngroups(2) alpha(0.1) power(0.9) wald
local samplesize1 = r(n)/2

if `samplesize1'!=39 { 
	di as err "Sample size 1 is incorrect (Blackwelder, p = 90%, d = 20%, α = 5%, β = 10%).  Should be n = 39"
	exit 198
}


// 2 //
* Julious 2011, Table 4; p = 70%, d = 5%, α = 2.5%, β = 10%
artbin, pr(0.3 0.3) margin(0.05) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize2 = r(n)/2

if `samplesize2'!=1766 { 
	di as err "Sample size 2 is incorrect (Julious 2011, Table 4; p = 70%, d = 5%, α = 2.5%, β = 10%).  Should be n = 1766"
	exit 198
}


// 3 //
* Pocock 2003; p = 85%, d = 15%, α* = 5%, β = 10%
artbin, pr(0.15 0.15) margin(0.15) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize3 = r(n)/2

if `samplesize3'!=120 { 
	di as err "Sample size 3 is incorrect (Pocock 2003; p = 85%, d = 15%, α* = 5%, β = 10%).  Should be n = 120"
	exit 198
}


// 4 //             
* Sealed envelope calculator; p = 80%, d = 10%, α = 10%, β = 20%
artbin, pr(0.2 0.2) margin(0.1) alpha(0.2) power(0.8) wald
local samplesize4 = r(n)/2

if `samplesize4'!=145 { 
	di as err "Sample size 4 is incorrect (Sealed envelope calculator; p = 80%, d = 10%, α = 10%, β = 20%).  Should be n = 145"
	exit 198
}

// 5 //
* Julious 2011, Table 4; p = 90%, d = 5%, α = 2.5%, β = 10%
artbin, pr(0.1 0.1) margin(0.05) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize5 = r(n)/2

if `samplesize5'!=757 { 
	di as err "Sample size 5 is incorrect (Julious 2011, Table 4; p = 90%, d = 5%, α = 2.5%, β = 10%).  Should be n = 757"
	exit 198
}


// 6 //
* Julious 2011, Table 4; p = 75%, d = 20%, α = 2.5%, β = 10%
artbin, pr(0.25 0.25) margin(0.2) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize6 = r(n)/2

if `samplesize6'!=99 { 
	di as err "Sample size 6 is incorrect (Julious 2011, Table 4; p = 75%, d = 20%, α = 2.5%, β = 10%).  Should be n = 99"
	exit 198
}


// 7 //
* Julious 2011, Table 4; p = 80%, d = 15%, α = 2.5%, β = 10%
artbin, pr(0.2 0.2) margin(0.15) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize7 = r(n)/2

if `samplesize7'!=150 { 
	di as err "Sample size 7 is incorrect (Julious 2011, Table 4; p = 80%, d = 15%, α = 2.5%, β = 10%).  Should be n = 150"
	exit 198
}

// 8 //
* Julious 2011, Table 4; p = 85%, d = 5%, α = 2.5%, β = 10%
artbin, pr(0.15 0.15) margin(0.05) ngroups(2) alpha(0.05) power(0.9) wald
local samplesize8 = r(n)/2

if `samplesize8'!=1072 { 
	di as err "Sample size 8 is incorrect (Julious 2011, Table 4; p = 85%, d = 5%, α = 2.5%, β = 10%).  Should be n = 1072"
	exit 198
}


* Testing against other programmes: ssi
*****************************************

* Note samsi is no longer supported in Stata, and is not for non-inferiority trials (just compares proportions or means)
* similarily power is not for NI studies

* p0 = 0.95, p1 = 0.9, α = 5%, β = 10%
ssi .05 .05, alpha(.05) power(.9) non  //652
local ss1 = r(ss)
artbin, pr(.05 .05) margin(0.05) ngroups(2) alpha(0.1) power(0.9) wald //652
local a1 = r(n)
if `ss1' != `a1' {
di as err "ssi and artbin output do not match"
	exit 198
}


* p0 = 0.8, p1 = 0.7, α = 5%, β = 20%
ssi 0.2 0.1, alpha(.05) power(.8) non   //396
local ss2 = r(ss)
artbin, pr(0.2 0.2) margin(0.1) ngroups(2) alpha(0.1) power(0.8) wald   //396
local a2 = r(n)
if `ss2' != `a2' {
di as err "ssi and artbin output do not match"
	exit 198
}

* p0 = 0.7, p1 = 0.6, α = 2.5%, β = 30%
ssi 0.3 0.1, alpha(.025) power(.7) non   //520
local ss3 = r(ss)
artbin, pr(0.3 0.3) margin(0.1) ngroups(2) alpha(0.05) power(0.7) wald  // 520
local a3 = r(n)
if `ss3' != `a3' {
di as err "ssi and artbin output do not match"
	exit 198
}


* p0 = 0.5, p1 = 0.2, α = 2.5%, β = 10%
ssi 0.5 0.3, alpha(.025) power(.9) non   //118
local ss4 = r(ss)
artbin, pr(0.5 0.5) margin(0.3) ngroups(2) alpha(0.05) power(0.9) wald  //118
local a4 = r(n)
if `ss4' != `a4' {
di as err "ssi and artbin output do not match"
	exit 198
}


* p0 = 0.4, p1 = 0.35, α = 5%, β = 20%
ssi 0.6 0.05, alpha(.05) power(.8) non   //2376
local ss5 = r(ss)
artbin, pr(0.6 0.6) margin(0.05) ngroups(2) alpha(0.1) power(0.8) wald  //2376
local a5 = r(n)
if `ss5' != `a5' {
di as err "ssi and artbin output do not match"
	exit 198
}

* p0 = 0.2, p1 = 0.1, α = 2.5%, β = 30%
ssi 0.8 0.1, alpha(.025) power(.7) non  //396
local ss6 = r(ss)
artbin, pr(0.8 0.8) margin(0.1) ngroups(2) alpha(0.05) power(0.7) wald  //396
local a6 = r(n)
if `ss6' != `a6' {
di as err "ssi and artbin output do not match"
	exit 198
}



******************************************
******************************************
* Testing 2: Power calculations
******************************************
******************************************


* Non-inferiority Binary Outcome
**********************************

clear all
set more off


// 1 //
* Blackwelder 1982; p = 90%, d = 20%, α = 5%, 2n = 78
artbin, pr(0.1 0.1) margin(0.2) ngroups(2) alpha(0.1) n(78) wald
local power1 = round(r(power),0.1)

if `power1'!=0.9 { 
	di as err "Power 1 is incorrect (Blackwelder, p = 90%, d = 20%, α = 5%, 2n = 78).  Should be 0.9"
	exit 198
}


// 2 //
* Julious 2011, Table 4; p = 70%, d = 5%, α = 2.5%, 2n = 3532
artbin, pr(0.3 0.3) margin(0.05) ngroups(2) alpha(0.05) n(3532) wald
local power2 = round(r(power),0.1)

if `power2'!=0.9 { 
	di as err "Power 2 is incorrect (Julious 2011, Table 4; p = 70%, d = 5%, α = 2.5%, 2n = 3532).  Should be 0.9"
	exit 198
}


// 3 //
* Pocock 2003; p = 85%, d = 15%, α* = 5%, 2n = 240
artbin, pr(0.15 0.15) margin(0.15) ngroups(2) alpha(0.05) n(240) wald
local power3 = round(r(power),0.1)

if `power3'!=0.9 { 
	di as err "Power 3 is incorrect (Pocock 2003; p = 85%, d = 15%, α* = 5%, 2n = 240).  Should be 0.9"
	exit 198
}


// 4 //
* Sealed envelope calculator; p = 80%, d = 10%, α = 10%, 2n = 290
artbin, pr(0.2 0.2) margin(0.1) ngroups(2) alpha(0.2) n(290) wald
local power4 = round(r(power),0.1)

if `power4'!=0.8 { 
	di as err "Power 4 is incorrect (Sealed envelope calculator; p = 80%, d = 10%, α = 10%, 2n = 290).  Should be 0.8"
	exit 198
}

// 5 //
* Julious 2011, Table 4; p = 90%, d = 5%, α = 2.5%, 2n = 1514
artbin, pr(0.1 0.1) margin(0.05) ngroups(2) alpha(0.05) n(1514) wald
local power5 = round(r(power),0.1)

if `power5'!=0.9 { 
	di as err "Power 5 is incorrect (Julious 2011, Table 4; p = 90%, d = 5%, α = 2.5%, 2n = 1514).  Should be 0.9"
	exit 198
}


// 6 //
* Julious 2011, Table 4; p = 75%, d = 20%, α = 2.5%, 2n = 198
artbin, pr(0.25 0.25) margin(0.2) ngroups(2) alpha(0.05) n(198) wald
local power6 = round(r(power),0.1)

if `power6'!=0.9 { 
	di as err "Power 6 is incorrect (Julious 2011, Table 4; p = 75%, d = 20%, α = 2.5%, 2n = 198).  Should be 0.9"
	exit 198
}


// 7 //
* Julious 2011, Table 4; p = 80%, d = 15%, α = 2.5%, 2n = 300
artbin, pr(0.2 0.2) margin(0.15) ngroups(2) alpha(0.05) n(300) wald
local power7 = round(r(power),0.1)

if `power7'!=0.9 { 
	di as err "Power 7 is incorrect (Julious 2011, Table 4; p = 80%, d = 15%, α = 2.5%, 2n = 300).  Should be 0.9"
	exit 198
}

// 8 //
* Julious 2011, Table 4; p = 85%, d = 5%, α = 2.5%, 2n = 2144
artbin, pr(0.15 0.15) margin(0.05) ngroups(2) alpha(0.05) n(2144) wald
local power8 = round(r(power),0.1)

if `power8'!=0.9 { 
	di as err "Power 8 is incorrect (Julious 2011, Table 4; p = 85%, d = 5%, α = 2.5%, 2n = 2144).  Should be 0.9"
	exit 198
}




******************************************
* Substantial-Superiority Binary Outcome
******************************************

//11//
* The Palisade Group of Clinical Investigators 2018, super-superiority trial
artbin, pr(.2 .5) margin(.15) aratio(1 3)
local samplesize11 = r(n)

if `samplesize11'!=391 { 
	di as err "Sample size 11 is incorrect (The Palisade Group of Clinical Investigators 2018, super-superiority trial.  Should be n = 391"
	exit 198
}




* Testing artbin compared to niss
*************************************
* Note: niss needs a margin specified (can not be set to 0, as then makes it a superiority trial).  

* p0 = 0.7, p1 = 0.9, d=0.2, α = 2.5%, β = 10%
niss 0.7 0.9 0.2, alpha(0.025) power(0.9) aratio(1) // 40
local niss1 = r(N_obs)
artbin, pr(0.3 0.1) margin(0.2) alpha(0.025) onesided power(0.9) wald alg // 40
local art1 = r(n)
if `niss1' != `art1' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.75, p1 = 0.85, d=0.1, α = 2.5%, β = 10%
niss 0.75 0.85 0.1, alpha(0.025) power(0.9) aratio(1) // 166
local niss2 = r(N_obs)
artbin, pr(0.25 0.15) margin(0.1) alpha(0.025) onesided power(0.9) wald alg // 166
local art2 = r(n)
if `niss2' != `art2' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.8, p1 = 0.7, d=0.15, α = 5%, β = 10%
niss 0.8 0.7 0.15, alpha(0.05) power(0.9) aratio(1) // 2536
local niss3 = r(N_obs)
artbin, pr(0.2 0.3) margin(0.15) alpha(0.05) onesided power(0.9) wald alg // 2536
local art3 = r(n)
if `niss3' != `art3' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.85, p1 = 0.8, d=0.1, α = 2.5%, β = 10%
niss 0.85 0.8 0.1, alpha(0.025) power(0.9) aratio(1) // 2418
local niss4 = r(N_obs)
artbin, pr(0.15 0.2) margin(0.1) alpha(0.025) onesided power(0.9) wald alg // 2418
local art4 = r(n)
if `niss4' != `art4' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.9, p1 = 0.9, d=0.05, α = 5%, β = 10%
niss 0.9 0.9 0.05, alpha(0.05) power(0.9) aratio(1) // 1234
local niss5 = r(N_obs)
artbin, pr(0.1 0.1) margin(0.05) alpha(0.05) onesided power(0.9) wald alg // 1234
local art5 = r(n)
if `niss5' != `art5' {
di as err "niss and artbin output do not match"
	exit 198
}


* p0 = 0.7, p1 = 0.75, d=0.15, α = 2.5%, β = 10%
niss 0.7 0.75 0.15, alpha(0.025) power(0.9) aratio(1)  // 210
local niss6 = r(N_obs)
artbin, pr(0.3 0.25) margin(0.15) alpha(0.025) onesided power(0.9) wald alg  //210
local art6 = r(n)
if `niss6' != `art6' {
di as err "niss and artbin output do not match"
	exit 198
}


* using different allocation ratios


* p0 = 0.7, p1 = 0.9, d=0.2, α = 2.5%, β = 10%, allocation ratio 1:2
niss 0.7 0.9 0.2, alpha(0.025) power(0.9) aratio(2) // 51
local niss7 = r(N_obs)
artbin, pr(0.3 0.1) margin(0.2) alpha(0.025) onesided power(0.9) aratio(2) wald alg // 51
local art7 = r(n)
if `niss7' != `art7' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.75, p1 = 0.85, d=0.1, α = 2.5%, β = 10%, allocation ratio 1:3
niss 0.75 0.85 0.1, alpha(0.025) power(0.9) aratio(3) // 243
local niss8 = r(N_obs)
artbin, pr(0.25 0.15) margin(0.1) alpha(0.025) onesided power(0.9) aratio(3) wald alg // 243
local art8 = r(n)
if (`niss8' != `art8') &  (`niss8' + 1 != `art8') {  // rounding difference
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.8, p1 = 0.7, d=0.15, α = 5%, β = 10%, allocation ratio 1:4
niss 0.8 0.7 0.15, alpha(0.05) power(0.9) aratio(4) // 3640
local niss9 = r(N_obs)
artbin, pr(0.2 0.3) margin(0.15) alpha(0.05) onesided power(0.9) aratio(4) wald alg // 3640
local art9 = r(n)
if `niss9' != `art9' {
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.85, p1 = 0.8, d=0.1, α = 2.5%, β = 10%, allocation ratio 1:2
niss 0.85 0.8 0.1, alpha(0.025) power(0.9) aratio(2) // 2618
local niss10 = r(N_obs)
artbin, pr(0.15 0.2) margin(0.1) alpha(0.025) onesided power(0.9) aratio(2) wald alg // 2618
local art10 = r(n)
if (`niss10' != `art10') &  (`niss10' + 1 != `art10') {  // rounding difference
di as err "niss and artbin output do not match"
	exit 198
}

* p0 = 0.9, p1 = 0.9, d=0.05, α = 5%, β = 10%, allocation ratio 1:4
niss 0.9 0.9 0.05, alpha(0.05) power(0.9) aratio(4) // 1928
local niss11 = r(N_obs)
artbin, pr(0.1 0.1) margin(0.05) alpha(0.05) onesided power(0.9) aratio(4) wald alg // 1928
local art11 = r(n)
if (`niss11' != `art11') &  (`niss11' + 2 != `art11') {  // rounding difference
di as err "niss and artbin output do not match"
	exit 198
}


* p0 = 0.7, p1 = 0.75, d=0.15, α = 2.5%, β = 10%, allocation ratio 1:3
niss 0.7 0.75 0.15, alpha(0.025) power(0.9) aratio(3)  // 287
local niss12 = r(N_obs)
artbin, pr(0.3 0.25) margin(0.15) alpha(0.025) onesided power(0.9) aratio(3) wald alg //287
local art12 = r(n)
if (`niss12' != `art12') &  (`niss12' + 1 != `art12') {  // rounding difference
di as err "niss and artbin output do not match"
	exit 198
}


* Test ltfu() option against STREAM trial.  Main trial ss =398 (ltfu = 0.2) but ar(1 2) so artbin with rounding will make 399 (133 and 266):
artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(0.2)
local stream = r(n)
if `stream' != 398 {
	di as err " STREAM trial ltfu() calculation error"
	exit 198
}


// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 1  *********" ///
	_n "*************************************************************"


log close

}
