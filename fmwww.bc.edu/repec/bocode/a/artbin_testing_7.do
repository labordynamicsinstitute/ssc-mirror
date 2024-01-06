// Verification code for the STATA program artbin v2.0.2
// Corresponds to Item 7 in the artbin Stata Journal Software Testing Section
// Created by Ella Marley-Zagar, 04 February 2021
// Last updated: 23 May 2023

clear all
set more off
prog drop _all

set level 95 // since art2bin defaults to c(level), unlike artbin

log using artbin_testing_7, replace text nomsg


which artbin
which art2bin


* Test where different permuations go (trial type/num arms/nchi/local)
*************************************************************************

* Superiority >2 local.  Goes to k-arm local as required.
artbin, pr(0.1 0.2 0.3) local alg

* Check if user puts undocumented nchi option in too that the above example is the same:

* Superiority >2 nchi local.  Goes to k-arm local as required.
artbin, pr(0.1 0.2 0.3) nchi local alg


* Superiority >2 nolocal.  Goes to k-arm distant as required.
artbin, pr(0.1 0.2 0.3) alg

* Check if user happens to put in nchi option too that the above example is the same:

* Superiority >2 nchi nolocal.  Goes to k-arm distant as required.  
artbin, pr(0.1 0.2 0.3) nchi alg


* Superiority =2 nonchi local. Goes to art2bin local as required.                  
artbin, pr(0.1 0.2) local alg
	
* Superiority =2 nonchi nolocal. Should go to art2bin distant.                      
artbin, pr(0.1 0.2) alg
	
* NI nonchi nolocal. Should go to art2bin distant.	
artbin, pr(0.2 0.1) margin(0.01) alg

* Substantial-superiority	nonchi nolocal. Should go to art2bin distant.
artbin, pr(0.3 0.1) margin(-0.1) alg

* NI nolocal nchi. Should go to art2bin distant with warning message that it is not nchi.
artbin, pr(0.2 0.1) margin(0.01) nchi alg

* Substantial-superiority	nolocal nchi. Should go to art2bin distant with warning message that it is not nchi.
artbin, pr(0.3 0.1) margin(-0.1) nchi alg

* This is the undocumented case so we can compare to other software:
* Superiority, =2, nchi, local/nolocal. 
artbin, pr(0.1 0.2) nchi alg        /* Currently goes to k-arm not art2bin, as nchi. */
artbin, pr(0.1 0.2) nchi local alg /* Currently goes to k-arm  not art2bin, as nchi. */



* NI, nonchi, local
cap noi artbin, pr(0.1 0.2) margin(0.01) ni local    
* Error message as required
artbin, pr(0.1 0.2) margin(0.01) local
* ok as required

* NI, nchi, local
artbin, pr(0.1 0.2) margin(0.01) nchi local 
* Now Ok according to Ab

* Super-superiority, nonchi, local.  Ab says margin!=0 and local now allowed
artbin, pr(0.1 0.2) margin(-0.05) local
* Now Ok according to Ab

* Super-superiority, nchi, local.  Ab says margin!=0 and local now allowed
artbin, pr(0.1 0.2) nchi margin(-0.05) local
* Now Ok according to Ab

* Check non-zero margin and local gives error message. .  Ab says margin!=0 and local now allowed
artbin, pr(0.1 0.3) margin(-0.1) local  
artbin, pr(0.1 0.3) margin(0.1) local 
* Now Ok according to Ab  
* Check ok:
artbin, pr(0.1 0.3) margin(0) local		  /* ok */


* Additional checking that Ab/Ian requested:                                      
* double check that nchi is now redundant i.e. for two groups art2bin with local option gives same results as artbin with local and nchi. 
* As Ian also put it: check that nchi doesn’t change the answer with 2 groups, superiority, local.
artbin, pr(0.1 0.2) local
artbin, pr(0.1 0.2) local nchi
* gives same result 

artbin, pr(0.7 0.85) local                                                   
artbin, pr(0.7 0.85) local nchi
* gives same result 


* Testing non-inferiority and superiority combinations in artbin
*****************************************************************

artbin, pr(0.1 0.3)
/*
SUPERIORITY
as required
*/


artbin, pr(0.1 0.3) 
/*
SUPERIORITY
as required
*/


artbin, pr(0.1 0.3) margin(-0.05) 
/*
NON-INFERIORITY
as required
*/

artbin, pr(0.1 0.3) margin(-0.05) 
/*
NON-INFERIORITY
as required
*/


artbin, pr(0.1 0.3) margin(-0.05) 
/*
NON-INFERIORITY
as required
*/


artbin, pr(0.1 0.3) margin(-0.05) 
/*
NON-INFERIORITY
as required
*/

artbin, pr(0.1 0.3) margin(-0.05) 
/*
NON-INFERIORITY
as required
*/


* Examples of defining the trial outcome is favourable or unfavourable
****************************************************************************

* superiority trial - favourable, because p2>p1
artbin, pr(.2 .3)
* Further sanity checks
artbin, pr(.2 .3) fav
cap noi artbin, pr(.2 .3) unfav
art2bin .2 .3
art2bin .2 .3, fav
cap noi art2bin .2 .3, unfav

* conversely, if p1>p2 should say unfavourable
artbin, pr(.3 .2)
* Further sanity checks
artbin, pr(.3 .2) unfav
cap noi artbin, pr(.3 .2) fav
art2bin .3 .2
art2bin .3 .2, unfav
cap noi art2bin .3 .2, fav

* standard NI trial - unfavourable, because margin>0
artbin, pr(.2 .2) margin(.1)
* Further sanity checks
artbin, pr(.2 .2) margin(.1) unfav
cap noi artbin, pr(.2 .2) margin(.1) fav
* error message as required
art2bin .2 .2, margin(.1)
art2bin .2 .2, margin(.1) unfav
cap noi art2bin .2 .2, margin(.1) fav
* error message as required

* standard NI trial - favourable, because margin<0
artbin, pr(.2 .2) margin(-.1)
* Further sanity checks
artbin, pr(.2 .2) margin(-.1) fav
cap noi artbin, pr(.2 .2) margin(-.1) unfav
* error message as required
art2bin .2 .2, margin(-.1)
art2bin .2 .2, margin(-.1) fav
cap noi art2bin .2 .2, margin(-.1) unfav
* error message as required

* non-standard NI trial with p2-p1 opposite to margin
* - unfavourable, because margin>0
artbin, pr(.2 .18) margin(.1)
* Further sanity checks
artbin, pr(.2 .18) margin(.1) unfav
cap noi artbin, pr(.2 .18) margin(.1) fav
* error message as required
art2bin .2 .18, margin(.1)
art2bin .2 .18, margin(.1) unfav
cap noi art2bin .2 .18, margin(.1) fav
* error message as required

* non-standard trials with p2-p1 in same direction as margin 
* SS trial & favourable, because p2-p1>margin>0
artbin, pr(.2 .4) margin(.1)
* Further sanity checks
artbin, pr(.2 .4) margin(.1) fav
cap noi artbin, pr(.2 .4) margin(.1) unfav
* error message as required
art2bin .2 .4, margin(.1)
art2bin .2 .4, margin(.1) fav
cap noi art2bin .2 .4, margin(.1) unfav
* error message as required

* NI trial & unfavourable, because p2-p1<margin>0
artbin, pr(.2 .25) margin(.1)
* Further sanity checks
artbin, pr(.2 .25) margin(.1) unfav
cap noi artbin, pr(.2 .25) margin(.1) fav
* error message as required
art2bin .2 .25, margin(.1)
art2bin .2 .25, margin(.1) unfav
cap noi art2bin .2 .25, margin(.1) fav
* error message as required

* SS trial & unfavourable, because p2-p1<margin<0
artbin, pr(.4 .2) margin(-.1)
* Further sanity checks
artbin, pr(.4 .2) margin(-.1) unfav
cap noi artbin, pr(.4 .2) margin(-.1) fav
* error message as required
art2bin .4 .2, margin(-.1)
art2bin .4 .2, margin(-.1) unfav
cap noi art2bin .4 .2, margin(-.1) fav
* error message as required

* NI trial & favourable, because p2-p1>margin<0
artbin, pr(.2 .25) margin(-.1)
* Further sanity checks
artbin, pr(.2 .25) margin(-.1) fav
cap noi artbin, pr(.2 .25) margin(-.1) unfav
* error message as required
art2bin .2 .25, margin(-.1)
art2bin .2 .25, margin(-.1) fav
cap noi art2bin .2 .25, margin(-.1) unfav
* error message as required


* Testing Ian's conditional/unconditional/trend options etc
**************************************************************

* Conditional/unconditional
****************************

artbin, pr(0.1 0.3) alg
* goes to art2bin as required
artbin, pr(0.1 0.3) condit
* uses local instead with a warning message as required
cap noi artbin, pr(0.1 0.3) trend
* Error message as required: Can not select trend option for a 2-arm trial


* check both go to error messages as required:
cap noi artbin, pr(.1 .2) margin(.05) condit
cap noi artbin, pr(.1 .2) margin(-.05) condit
* ok

artbin, pr(0.1 0.3) margin(0)
artbin, pr(0.1 0.3) margin(0) condit
* uses local instead with a warning message as required
cap noi artbin, pr(0.1 0.3) margin(0) trend
* Error message as required: Can not select trend option for a 2-arm trial

artbin, pr(0.1 0.3 0.4)
* Says unconditional as required
artbin, pr(0.1 0.3 0.4) condit local
* Says conditional as required
artbin, pr(0.1 0.3 0.4) trend
* Has trend test on output as required
artbin, pr(0.1 0.3 0.4) condit local
* ok
artbin, pr(0.1 0.3 0.4) local
* gives a different answer to unconditional and distant as required
artbin, pr(0.1 0.3 0.4) trend
* Has trend test on output as required


artbin, pr(0.1 0.3) nchi
* Says unconditional as required
artbin, pr(0.1 0.3) nchi condit
* uses local instead with a warning message as required
cap noi artbin, pr(0.1 0.3) nchi trend
* Error message: Can not select trend option for a 2-arm trial
cap noi artbin, pr(0.1 0.3) nchi condit local
* Error message: Can not select conditional AND local options for 2-arm nchi trial
artbin, pr(0.1 0.3) nchi local
* gives a different answer to distant option above
cap noi artbin, pr(0.1 0.3) nchi trend
* Error message: Can not select trend option for a 2-arm trial

* checking the below are the same, as allowing onesided to be used when trend/doses specified for >2 groups
artbin, pr(0.1 0.2 0.3) trend alpha(0.05) onesided
local artbinos1 = r(n)
artbin, pr(0.1 0.2 0.3) trend alpha(0.1) 
local artbinos2 = r(n)
assert `artbinos1'==`artbinos2'

artbin, pr(0.1 0.2 0.3) doses(2 4 6) alpha(0.05) onesided
local artbinos3 = r(n)
artbin, pr(0.1 0.2 0.3) doses(2 4 6) alpha(0.1) 
local artbinos4 = r(n)
assert `artbinos3'==`artbinos4'


* Additional sanity checks
*****************************
*****************************
						
* Test whether aratios displayed for all combinations
******************************************************

* Superiority >2 nchi local
cap noi artbin, pr(0.1 0.2 0.3) nchi local aratio(1 2)
* error message as required

* Superiority >2 nchi nolocal
artbin, pr(0.1 0.2 0.3) nchi aratio(1 2 3)

* Superiority =2 nchi local
artbin, pr(0.1 0.2) nchi local aratio(1 2)

* Superiority =2 nchi nolocal
artbin, pr(0.1 0.2) nchi aratio(1 2)

* Superiority =2 nonchi local. 
artbin, pr(0.1 0.2) local aratio(1 2)
	
* Superiority =2 nonchi nolocal
artbin, pr(0.1 0.2) aratio(1 2)
	
* NI nonchi nolocal	
artbin, pr(0.1 0.2) margin(-0.1) aratio(1 2)

* Super-superiority	nonchi nolocal	
artbin, pr(0.3 0.1) margin(-0.1) aratio(1 2)

* margin(0) local
artbin, pr(0.1 0.3) margin(0) local aratio(1 2)

* Trinh's example from BALANCE trial
* Original code for artbin v 1.1.2:  artbin, pr(0.05 0.08) alpha(0.05) power(0.8) ni(1) ar(1 2)
*artbin_v$version, pr(0.05 0.08) alpha(0.05) power(0.8) ni(1) ar(1 2)
artbin, pr(0.05 0.05) margin(0.03) alpha(0.05) power(0.8) ar(1 2)
* description table now displays allocation ratio correctly as 1:2 (and the sample size is still 1716 
artbin, pr(0.05 0.05) margin(0.03) alpha(0.05) power(0.8) ar(1 2) noround
* noround works as required


* Checking non-integer allocation ratios allowed
artbin, pr(.15 .15) margin(.1) aratio(1 1.5)
* this is the same as:
artbin, pr(.15 .15) margin(.1) aratio(2 3)
* as required


* Testing that nothing silly is allowed in pr()
****************************************************

artbin, pr(.2(.01).3 .5)                                                   
* expands as expected

artbin, pr(.2(.05).3)                                                       
* expands as expected

* Checking a variety of formats of p are accepted:
artbin, pr(0.1 .2 0.3 .4)

* Check long pr's
artbin, pr(0.000001 0.000002)    //***** Anticipated event probabilities in table to 3 dp ****//

 
* checking if wald is specified and nvm is left blank then automatically defaults to nvm(1)

artbin, pr(.2 .25) wald
artbin, pr(.2 .25) wald nvm(1)
* same as above as required
cap noi artbin, pr(.2 .25) wald nvm(3)
* error message as required
artbin, pr(.1 .2 .3) wald
* ok as required


* Checking that D is now given up to 2d.p. (before in v122, sometimes it was an integer, sometimes 1 d.p., sometimes 2 d.p.)
* was 1 dp:
artbin, pr(0.3 0.1) margin(0) alpha(0.05) power(0.90) 
* was 2 dp:
artbin, pr(0.15 0.2) margin(0) alpha(0.1) power(0.90) ccorrect(1)
* was 0 dp:
artbin, pr(0.2 0.3) margin(0.15) alpha(0.05) onesided(1) power(0.9) nvm(1)

* testing notable
artbin, pr(0.1 0.2) notable
artbin, pr(0.1 0.2)
artbin, pr(0.1 0.2) n(1000) notable
artbin, pr(0.1 0.2) n(1000)
* as required

* checks artbin v art2bin
artbin, pr(.1 .1) margin(.05)  // 1162
local artbinss1 = r(n)
art2bin 0.1 0.1, margin(.05)  // same as this, 1162
local art2binss1 = r(n)
assert `artbinss1'==`art2binss1'

artbin, pr(0.3 0.3) margin(0.05) ngroups(2) alpha(0.05) power(0.9) 
local artbinss2 = r(n)
art2bin 0.3 0.3, margin(0.05) alpha(0.05) power(0.9)
local art2binss2 = r(n)
assert `artbinss2'==`art2binss2'


* Testing that the original artbin and new artbin give the same results
* original artbin: artbin_orig binary version 1.1.2 17apr2018

artbin, pr(.6 .7)
local newartbinSS = r(n)
artbin_orig, pr(.6 .7) distant(1)
local origartbinSS = r(n)
if `newartbinSS' != `origartbinSS' {
	di as err " new and original artbin give different SS"
	exit 198
}

artbin, pr(.2 .25) local
local newartbinSS = r(n)
artbin_orig, pr(.2 .25) distant(0)
local origartbinSS = r(n)
if `newartbinSS' != `origartbinSS' {
	di as err " new and original artbin give different SS"
	exit 198
}


* Testing number of events
artbin, pr(0.25 0.35) margin(0.2) noround
assert `r(D)' == (0.25 * `r(n1)') + (0.35 * `r(n2)')

artbin, pr(0.3 0.5) margin(0.1) noround
assert `r(D)' == (0.3 * `r(n1)') + (0.5 * `r(n2)')

artbin, pr(0.4 0.6) margin(0.05) noround
assert `r(D)' == (0.4 * `r(n1)') + (0.6 * `r(n2)')

artbin, pr(0.3 0.5) margin(-0.1) noround
assert `r(D)' == (0.3 * `r(n1)') + (0.5 * `r(n2)')

artbin, pr(0.2 0.3 0.4) noround
assert `r(D)' == ((0.2 + 0.3 + 0.4)/3) * `r(n)'

artbin, pr(0.4 0.6) ar(1 2) noround
assert `r(D)' == `r(n)'*(0.4 + 0.6*2)/(1+2)


// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED ALL SOFTWARE TESTING POINT 7  *********" ///
	_n "*************************************************************"




log close
