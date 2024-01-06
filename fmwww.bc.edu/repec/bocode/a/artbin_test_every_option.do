/* 
artbin_test_every_option.do
explore every option in v118 help file 
IW 26feb2021
options untested here
	n(#)
	ap2
	eventtype(#)
	force
updated for v126 4may2021, still not testing n, ap2, force
*/
local name artbin_test_every_option
*local ver _v126
cap log close
log using `name', text replace
which artbin`ver'
local returns 1

// UTILITIES
cap prog drop dicmd
prog def dicmd
noi di as input `"`0'"'
`0'
end


// 2 arms
local command artbin`ver', pr(.4 .2)
dicmd `command'
local n=r(n)
* options expected to increase SS
foreach opt in "margin(-.1)" "alpha(0.01)" "aratios(1 2)" "local" "ccorrect(1)"  "ccorrect" "power(.9)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) > `n'
}
* options expected to decrease SS
foreach opt in "margin(.1)" "alpha(0.1)" "condit" "onesided(1)" "onesided" "wald"  "noround" "power(.7)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) < `n'
}
* options expected not to change SS 
foreach opt in "power(.8)" "unfavourable" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) == `n'
}
* options expected to cause error
foreach opt in "trend" /* "favourable" */ {
	di _n
	dicmd cap noi `command' `opt'
	assert _rc
}




// 2 arms, NI
local command artbin`ver', pr(.2 .2) margin(.1)
dicmd `command'
local n=r(n)
* options expected to increase SS
foreach opt in "alpha(0.01)" "aratios(1 2)" "local" "ccorrect(1)"  "ccorrect" "power(.9)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) > `n'
}
* options expected to decrease SS
foreach opt in "alpha(0.1)" "onesided(1)" "onesided" "wald"  "noround" "power(.7)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) < `n'
}
/*
* options expected to change SS
foreach opt in {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) != `n'
}
*/
* options expected not to change SS 
foreach opt in "power(.8)" "unfavourable" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) == `n'
}
* options expected to cause error
foreach opt in "favourable" "trend" {
	di _n
	dicmd cap noi `command' `opt'
	assert _rc
	di as input "Note: the above error message was expected"
}




// 3 arms
local command artbin`ver', pr(.4 .3 .2)
dicmd `command'
local n=r(n)
* options expected to increase SS
foreach opt in "alpha(0.01)" "aratios(3 2 1)" "local" "power(.9)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) > `n'
}
* options expected to decrease SS
foreach opt in "alpha(0.1)" "condit" "wald" "noround" "trend" "doses(1 2 3)" "power(.7)" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) < `n'
}
* options expected not to change SS 
foreach opt in "power(.8)" "unfavourable" {
	di _n
	dicmd `command' `opt'
	if `returns' return list
	assert !mi(r(n))
	assert r(n) == `n'
}
* options expected to cause error
foreach opt in "margin(.1)" "ccorrect" /* "favourable" */ "onesided" {
	di _n
	dicmd cap noi `command' `opt'
	assert _rc
	di as input "Note: an error message was expected above"
}



// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED TESTING OF EVERY OPTION ***************" ///
	_n "*************************************************************"


log close
