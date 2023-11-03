// Validation code for the STATA program artcat
// Created by Ella Marley-Zagar, 11 June 2020
// Last updated: 06 Jan 2021
// 1jun2022: extracted Whitehead code and created master.do
//   renamed compare_with_Whitehead.do

clear all
set more off

which artcat


* Example 1 Whitehead Paper (listed under example 2 pg 2266)
artcat, pc(0.2 0.5 0.2 0.1) or(exp(0.887)) power(.9) whitehead noround
local samplesizewex1 = ceil(r(n))

if `samplesizewex1'!=187 { 
	di as err "Sample size is incorrect (Whitehead example 1, pc = (0.2 0.5 0.2 0.1), log odds = 0.887, α = 5%, β = 10%).  Should be n = 187"
	exit 198
}

* Example 2 Whitehead Paper (pg 2266)
artcat, pc(0.26 0.38 0.24 0.12) or(exp(0.678)) power(.9) whitehead noround
local samplesizewex2 = ceil(r(n))

if `samplesizewex2'!=305 { 
	di as err "Sample size is incorrect (Whitehead example 2, pc = ((0.26 0.38 0.24 0.12), log odds = 0.678, α = 5%, β = 10%).  Should be n = 305"
	exit 198
}

* Example 3a Whitehead Paper pg 2267   // Artcat gives ss = 245 instead of 244
artcat, pc(0.5) or(exp(0.847)) power(.9) whitehead noround
local samplesizewex3a = ceil(r(n))

if ("`samplesizewex3a'"!= "244" & "`samplesizewex3a'"!= "245") { 
	di as err "Sample size is incorrect (Whitehead example 3a, pc = 0.5, log odds = 0.847, α = 5%, β = 10%).  Should be n = 244"
	exit 198
}

* Example 3b Whitehead Paper pg 2267   
artcat, pc(0.2 0.3 0.3 0.2) or(exp(0.847)) power(.9) whitehead noround
local samplesizewex3b = ceil(r(n))

if `samplesizewex3b'!= 190 { 
	di as err "Sample size is incorrect (Whitehead example 3b, pc = (0.2 0.3 0.3 0.2), log odds = 0.847, α = 5%, β = 10%).  Should be n = 190"
	exit 198
}

* Example 3c Whitehead Paper pg 2268  
artcat, pc(0.22 0.28 0.28 0.22) or(exp(0.769)) power(.9) whitehead noround
local samplesizewex3c = ceil(r(n))

if `samplesizewex3c'!= 230 { 
	di as err "Sample size is incorrect (Whitehead example 3c, pc = (0.22 0.28 0.28 0.22), log odds = 0.769, α = 5%, β = 10%).  Should be n = 230"
	exit 198
}



