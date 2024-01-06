// new testing file for ltfu option in artbin
// artbin_test_ltfu.do
// IW 22/11/2023

prog drop _all

log using artbin_testltfu, replace text nomsg

which artbin
which art2bin


* evaluate ltfu() for power->n
artbin, pr(.02 .02) margin(.02) noround
local n=r(n)
local D=r(D)
artbin, pr(.02 .02) margin(.02) noround ltfu(.1)
di "Results to compare: ", r(n),`n'/0.9
assert reldif(r(n),`n'/0.9) < 1E-7 // total sample size required is greater with LTFU
di "Results to compare: ", r(D),`D'
assert reldif(r(D),`D') < 1E-7 // actual events are the same each way


* evaluate ltfu() for n->power
artbin, pr(.02 .02) margin(.02) noround n(1000) ltfu(.1)
local power=r(power)
artbin, pr(.02 .02) margin(.02) noround n(900)
di "Results to compare: ", r(power),`power'
assert reldif(r(power),`power') < 1E-7


* check ltfu() option by converting power to n and back
local norig 1000
foreach opts in "pr(.02 .02) margin(.02) aratio(1 2)" ///
	"pr(.02 .04) aratio(1 2)" ///
	"pr(.02 .04 .06) aratio(3 2 1) convcrit(1E-8)" ///
	"pr(.02 .04 .06) trend convcrit(1E-8)" {
	artbin, `opts' n(`norig') ltfu(0.1) 
	local power = r(power)
	artbin, `opts' power(`power') ltfu(0.1) noround
	di "Results to compare: ", r(n), `norig'
	assert reldif(r(n), `norig') < 1E-7
}


* check it works with non-integer ltfu*n
artbin, pr(.02 .02) margin(.02) ltfu(.05) n(1836)
assert r(n)==1836

// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED SOFTWARE TESTING OF LTFU()    *********" ///
	_n "*************************************************************"

log close
