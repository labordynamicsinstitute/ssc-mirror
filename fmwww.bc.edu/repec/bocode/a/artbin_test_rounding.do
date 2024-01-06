// new testing file for rounding procedure in artbin
// artbin_test_rounding.do
// IW 5/12/2023

prog drop _all

cap log close
log using artbin_test_rounding, replace text nomsg

which artbin
which art2bin


foreach opts in ///
	"pr(.02 .02) margin(.02) aratio(1 2)" ///
	"pr(.02 .04) aratio(1 2)" ///
	"pr(.2 .3) aratio(10 17)" ///
	"pr(.02 .04 .06) aratio(3 2 1) convcrit(1E-8)" ///
	"pr(.02 .04 .06) trend convcrit(1E-8)" {
	artbin, `opts' noround
	local narms = 2 + !mi(r(n3))
	forvalues i=1/`narms' {
		local n`i' = r(n`i')
		local d`i' = r(D`i')
	}
	artbin, `opts' 
	* check arm-specific results
	forvalues i=1/`narms' {
		* check rounding of n's
		assert r(n`i') == ceil(`n`i'')
		* check D's match rounded n's
		assert reldif( r(D`i')/r(n`i') , `d`i''/`n`i'' ) < 1E-9
	}
	* check overall results
	if `narms'==2 {
		assert r(D)==r(D1)+r(D2)
		assert r(n)==r(n1)+r(n2)
	}
	else if `narms'==3 {
		assert r(D)==r(D1)+r(D2)+r(D3)
		assert r(n)==r(n1)+r(n2)+r(n3)
	}
}

// REPORT SUCCESS
di as result _n "*************************************************************" ///
	_n "*** ARTBIN HAS PASSED SOFTWARE TESTING OF ROUNDING  *********" ///
	_n "*************************************************************"

log close
