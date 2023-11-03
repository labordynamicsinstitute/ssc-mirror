/* 
Validation code for the STATA program artcat
Created by Ella Marley-Zagar, 11 June 2020
Last updated: 06 Jan 2021
1jun2022: 
	extracted artbin comparison and created master.do
	renamed compare_with_artbin.do
	updated for artbin v2
*/

******************************************
******************************************
* Testing: Sample size calculations
******************************************
******************************************


**********************************
* Superiority Binary Outcome
**********************************

/* from draft artcat paper:
artbin reports method NN, unless the  option is used, in which case it reports method NA.
Power is assessed by artbin, using the default method which assumes local alternatives (variance type NN) and the alternative method
assuming distant alternatives (variance type NA).
**** in artbin superiority, the default is distant ****
local: NN
distant: NA
*/


* p = 90%, d = 20%, α = 10%, β = 10%
* Distant / NA
artbin, pr(0.1 0.3) alpha(0.1) power(0.9)  // 133
local n0 = r(n)
artcat, pc(.1) pe(.3) alpha(0.1) power(.9) probtable ologit(NA) fav // 131
local absdif1dist = abs(r(n_ologit_NA) - `n0')
di `absdif1dist'
assert `absdif1dist' < 10

* Local / NN
artbin, pr(0.1 0.3) alpha(0.1) power(0.9) local // 138
local n1 = r(n)
artcat, pc(.1) pe(.3)  alpha(0.1) power(.9) probtable ologit(NN) fav // 118
local absdif1loc = abs(r(n_ologit_NN) - `n1')
di `absdif1loc'
assert `absdif1loc' < 10                                                         /***********  ASSERTION FALSE, DIFFERENCE OF 20 ***********/


* p1 = 90%, p2 = 95%, α = 5%, β = 10%
* Distant / NA
artbin, pr(0.05 0.1) alpha(0.05) power(0.9)  // 1162
local n2 = r(n)
artcat, pc(.05) pe(.1) alpha(0.05) power(.9) probtable ologit(NA) // 1134
local absdif2dist = abs(r(n_ologit_NA) - `n2')                                   
di `absdif2dist'
assert `absdif2dist' < 10                                                        /***********  ASSERTION FALSE, DIFFERENCE OF 28 ***********/

* Local / NN
artbin, pr(0.05 0.1) alpha(0.05) power(0.9) local // 1167
local n3 = r(n)
artcat, pc(.05) pe(.1) alpha(0.05) power(.9) probtable ologit(NN) fav // 1086
local absdif2loc = abs(r(n_ologit_NN) - `n3')  
di `absdif2loc'                                                                   
assert `absdif2loc' < 10                                                         /***********  ASSERTION FALSE, DIFFERENCE OF 81 ***********/


* p1 = 90%, p2 = 80%, α = 10%, β = 20%
* Distant / NA
artbin, pr(0.1 0.2) alpha(0.1) power(0.8)  // 313
local n4 = r(n)
artcat, pc(.1) pe(.2) alpha(0.1) power(.8) probtable ologit(NA) fav // 306
local absdif3dist = abs(r(n_ologit_NA) - `n4') 
di `absdif3dist'                                  
assert `absdif3dist' < 10

* Local / NN
artbin, pr(0.1 0.2) alpha(0.1) power(0.8) local // 316
local n5 = r(n)
artcat, pc(.1) pe(.2) alpha(0.1) power(.8) probtable ologit(NN) fav // 295
local absdif3loc = abs(r(n_ologit_NN) - `n5')  
di `absdif3loc'                                
assert `absdif3loc' < 10                                                         /***********  ASSERTION FALSE, DIFFERENCE OF 21 ***********/
                                                      

* Substantial-superiority
artcat, pc(.4 .2) margin(0.1) or(0.05) power(.8) probtable ologit unfavourable

* Testing onesided
*********************

* p = 90%, d = 20%, α = 5% onesided, β = 10%
* Distant / NA
artbin, pr(0.1 0.3) alpha(0.05) power(0.9)  onesided(1) // 133
local n12 = r(n)
artcat, pc(.1) pe(.3) alpha(0.05) power(.9) probtable ologit(NA) onesided fav // 131
local absdif12dist = abs(r(n_ologit_NA) - `n12')
di `absdif12dist'
assert `absdif12dist' < 10


* p1 = 90%, p2 = 80%, α = 5% onesided, β = 20%
* Distant / NA
artbin, pr(0.1 0.2) alpha(0.05) power(0.8)  onesided(1) // 313
local n13 = r(n)
artcat, pc(.1) pe(.2) alpha(0.05) power(.8) probtable ologit(NA) onesided fav // 306
local absdif13dist = abs(r(n_ologit_NA) - `n13') 
di `absdif13dist'                                  
assert `absdif13dist' < 10


* Testing aratios
********************* 

* p = 90%, d = 20%, α = 5%, β = 10%
* Distant / NA
artbin, pr(0.1 0.3) alpha(0.05) power(0.9) aratios(1 2)   // 188
local n14 = r(n)
artcat, pc(.1) pe(.3) alpha(0.05) power(.9) probtable ologit(NA) aratio(1 2) fav  // 178
local absdif14dist = abs(r(n_ologit_NA) - `n14')
di `absdif14dist'
assert `absdif14dist' < 10                                                       /***********  ASSERTION FALSE, DIFFERENCE OF 10 ***********/


* p1 = 90%, p2 = 80%, α = 5%, β = 20%
* Distant / NA
artbin, pr(0.1 0.2) alpha(0.05) power(0.8) aratios(1 3)  // 555
local n15 = r(n)
artcat, pc(.1) pe(.2) alpha(0.05) power(.8) probtable ologit(NA) aratio(1 3) fav // 495
local absdif15dist = abs(r(n_ologit_NA) - `n15') 
di `absdif15dist'                                  
assert `absdif15dist' < 10                                                       /***********  ASSERTION FALSE, DIFFERENCE OF 60 ***********/


******************************************
******************************************
* Testing 2: Power calculations
******************************************
******************************************



**********************************
* Superiority Binary Outcome
**********************************



* p1 = 95%, p2 = 83%, α = 5%, n=515
* Distant / NA
artbin, pr(0.05 0.17) alpha(0.05) n(515)  // 0.993
local n6 = r(power)
artcat, pc(0.05) pe(0.17) alpha(0.05) n(515) probtable ologit(NA) fav // 0.993
local absdif4dist = abs(r(power) - `n6')
di `absdif4dist'
assert `absdif4dist' < 0.01

* Local / NN
artbin, pr(0.05 0.17) alpha(0.05) n(515) local // 0.992
local n7 = r(power)
artcat, pc(0.05) pe(0.17) alpha(0.05) n(515) probtable ologit(NN) fav // 0.998
local absdif5dist = abs(r(power) - `n7')
di `absdif5dist'
assert `absdif5dist' < 0.01

                                                  
* p1 = 90%, p2 = 80%, α = 10%, n=310
* Distant / NA
artbin, pr(0.1 0.2) alpha(0.1) n(310)  // 0.796
local n8 = r(power)
artcat, pc(0.1) pe(0.2) alpha(0.1) n(310) probtable ologit(NA) fav // 0.805
local absdif6dist = abs(r(power) - `n8')
di `absdif6dist'
assert `absdif6dist' < 0.01

* Local / NN
artbin, pr(0.1 0.2) alpha(0.1) n(310) local // 0.794
local n9 = r(power)
artcat, pc(0.1) pe(0.2) alpha(0.1) n(310) probtable ologit(NN) fav // 0.817
local absdif7dist = abs(r(power) - `n9')
di `absdif7dist'
assert `absdif7dist' < 0.01                                                      /***********  ASSERTION FALSE, DIFFERENCE OF 0.023 ***********/


* p1 = 92%, p2 = 89%, α = 5%, n=5000
* Distant / NA
artbin, pr(0.08 0.11) alpha(0.05) n(5000)  // 0.951
local n10 = r(power)
artcat, pc(0.08) pe(0.11) alpha(0.05) n(5000) probtable ologit(NA) fav // 0.952
local absdif8dist = abs(r(power) - `n10')
di `absdif8dist'
assert `absdif8dist' < 0.01

* Local / NN
artbin, pr(0.08 0.11) alpha(0.05) n(5000) local // 0.951
local n11 = r(power)
artcat, pc(0.08) pe(0.11) alpha(0.05) n(5000) probtable ologit(NN) fav // 0.954
local absdif9dist = abs(r(power) - `n11')
di `absdif9dist'
assert `absdif9dist' < 0.01    




