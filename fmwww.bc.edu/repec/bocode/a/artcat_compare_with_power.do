// Validation code for the STATA program artcat: testing artcat vs Stata's -power-
// Created by Ella Marley-Zagar, 6 July 2020
// Last updated 07 Jan 2021
// 1jun2022: renamed compare_with_power.do



clear all
set more off

which artcat


****************
* Sample size
*****************


artcat, pc(0.2) pe(0.5) power(.9) fav // 103
local n1artcat = r(n)
power twoproportions 0.2 0.5, alpha(0.05) power(0.9) // 104
local n1power = r(N)
local absdif1 = abs(`n1artcat' - `n1power')
di `absdif1'
assert `absdif1' < 10


artcat, pc(0.24) pe(0.38) power(.8) fav // 338
local n2artcat = r(n)
power twoproportions 0.24 0.38, alpha(0.05) power(0.8) // 342
local n2power = r(N)
local absdif2 = abs(`n2artcat' - `n2power')
di `absdif2'
assert `absdif2' < 10

artcat, pc(0.05) pe(0.07) alpha(0.1) power(.8) fav // 3458
local n3artcat = r(n)
power twoproportions 0.05 0.07, alpha(0.1) power(0.8) // 3486
local n3power = r(N)
local absdif3 = abs(`n3artcat' - `n3power')
di `absdif3'
assert `absdif3' < 10                                                            /***********  ASSERTION FALSE, DIFFERENCE OF 28 ***********/

artcat, pc(0.5) pe(0.8) alpha(0.05) power(.75) fav // 67
local n4artcat = r(n)
power twoproportions 0.5 0.8, alpha(0.05) power(0.75) // 70
local n4power = r(N)
local absdif4 = abs(`n4artcat' - `n4power')
di `absdif4'
assert `absdif4' < 10 

artcat, pc(0.01) pe(0.03) alpha(0.05) power(.8) fav // 1399
local n5artcat = r(n)
power twoproportions 0.01 0.03, alpha(0.05) power(0.8) // 1538
local n5power = r(N)
local absdif5 = abs(`n5artcat' - `n5power')
di `absdif5'
assert `absdif5' < 10                                                           /***********  ASSERTION FALSE, DIFFERENCE OF 139 ***********/

* NB:
artbin, pr(0.01 0.03) alpha(0.05) power(0.8) distant(1) // 1539

***********
* Power
***********


artcat, pc(0.04) pe(0.05) alpha(0.05) n(520) fav // 0.081
local power1artcat = r(power)
power twoproportions 0.04 0.05, alpha(0.05) n(520) // 0.0852
local power1power = r(power)
local absdifpower1 = abs(`power1artcat' - `power1power')
di `absdifpower1'
assert `absdifpower1' < 0.01 



artcat, pc(0.06) pe(0.23) alpha(0.05) n(250) fav // 0.974
local power2artcat = r(power)
power twoproportions 0.06 0.23, alpha(0.05) n(250) // 0.9722
local power2power = r(power)
local absdifpower2 = abs(`power2artcat' - `power2power')
di `absdifpower2'
assert `absdifpower2' < 0.01 

artcat, pc(0.2) pe(0.3) alpha(0.1) n(380) fav // 0.732
local power3artcat = r(power)
power twoproportions 0.2 0.3, alpha(0.1) n(380) //  0.7292
local power3power = r(power)
local absdifpower3 = abs(`power3artcat' - `power3power')
di `absdifpower3'
assert `absdifpower3' < 0.01 


artcat, pc(0.01) pe(0.03) alpha(0.05) n(2000) fav // 0.910
local power4artcat = r(power)
power twoproportions 0.01 0.03, alpha(0.05) n(2000) //  0.8921
local power4power = r(power)
local absdifpower4 = abs(`power4artcat' - `power4power')
di `absdifpower4'
assert `absdifpower4' < 0.01                                                    /***********  ASSERTION FALSE, DIFFERENCE OF 0.018 ***********/


artcat, pc(0.06) pe(0.08) alpha(0.1) n(3030) fav //  0.699
local power5artcat = r(power)
power twoproportions 0.06 0.08, alpha(0.1) n(3030) //  0.6961
local power5power = r(power)
local absdifpower5 = abs(`power5artcat' - `power5power')
di `absdifpower5'
assert `absdifpower5' < 0.01 

