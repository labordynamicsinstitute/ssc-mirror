/* ************************************************************************************
                             Sample size for comparison of two proportions
-	Sample size and power are based on tests for difference (d=p1-p0) between
	two proportions of failure.
-	Null hypothesis H0: d >= mrg (a pre-assigned margin), against the alternative
	hypothesis H1: d < mrg.
-	Covers three designs: 
		1) Classical superiority (mrg=0);
		2) Non-inferiority (mrg>0) and
		3) Substantial superiority (mrg<0).
-	Optional: 3 methods for estimating the variance V0 of the estimated difference
	Dhat under the null hypothesis H0. V0 = P0*(1-P0)/n0+P1*(1-P1)/n1 and the 3 methods
	differ in the way P0 and P1 are estimated as follows:
		1) Sample estimates of the proportions of failures in the group 0 (control)
		and group 1 (experimental): P0 = p0hat and P1 = p1hat 
		2) Fixed marginal totals: P1 = (n0*p0hat+n1*p1hat+n0*mrg)/(n0+n1) and
		P0 = (n0*p0hat+n1*p1hat-n0*mrg)/(n0+n1). [Dunnett & Gent, Biometrics 1977].
		3) Constrained ML with constraints: P1-P0=mrg; 0<P0<1 and 0<P1<1. This is based
		approximately on the score test [Farrington & Manning, Stat in Med 1990)].
-	Optional: continuity correction.
************************************************************************************ */

*version 0.01  14Sep2012
cap prog drop art2bin
program define art2bin, rclass
	gettoken p0 0 : 0, parse(" ,")
	gettoken p1 0    : 0, parse(" ,")

	confirm number `p0'
	confirm number `p1'

	local dalpha = 1 - $S_level/100
	local dpower 0.8
	local ss 0
	syntax [, MARgin(real 0) DESign(string) n0(int 0) n1(int 0) ARatio(real 1) ///
                  Alpha(real `dalpha')  Power(real `dpower') NVMethod(int 0) ONESided CCorrect(real 0)]

	cap assert `aratio'>0
	if _rc {
		di in red "Allocation ratio must be > 0"
		exit 198
	}

	if `alpha'<=0 | `alpha'>=1 { 
		di in red "alpha() out of range"
		exit 198
	}

	if `p0'<=0 | `p0'>=1 {
		di in red "Control event probability out of range"
		exit 198
	}
	if `p1'<=0 | `p1'>=1 {
		di in red "Intervention event probability out of range"
		exit 198
	}

	if `n0'<0 | `n1'<0 { 
		di in red "Sample size n() out of range"
		exit 198
	}
	if `n0' == 0 & `n1' == 0 {
		local ss 1		// Calculate sample size
	}
	else if `n1' == 0 {
		local n1 = `n0'*`aratio'
	}
	else if `n0' == 0 {
		local n0 = `n1'/`aratio'
	}
	else {
		local aratio = `n1'/`n0'
	}

	local mrg = `margin'

	// Estimating event probabilities and variance of the test stat under the null hypothesis //
	local nvm = `nvmethod'     // Method for estimating event probabilities under null hypothesis
	if `nvm'>2 | `nvm'<0 {
		local nvm 0
	}
	if `nvm' == 0 {
		local p0null = `p0'
		local p1null = `p1'
	}
	if `nvm' == 1 {								// Fixed marginal totals
		local p0null = (`p0'+`aratio'*`p1'-`aratio'*`mrg')/(1+`aratio')
		local p1null = (`p0'+`aratio'*`p1'+`mrg')/(1+`aratio')
		cap assert (`p0null'>0) & (`p0null'<1) & (`p1null'>0) & (`p1null'<1)
		if _rc {
		  di in red "Event probabilities and/or non-inferiority margin in compatible with the requested mrthod"
		  exit 198
		}
	}
	else if `nvm' == 2 {							// Constrained ML
		local a = 1+`aratio'
		local b = `mrg'*(`aratio'+2)-1-`aratio'-`p0'-`aratio'*`p1'
		local c = (`mrg'-1-`aratio'-2*`p0')*`mrg'+`p0'+`aratio'*`p1'
		local d = `p0'*`mrg'*(1-`mrg')
		local v = (`b'/(3*`a'))^3-(`b'*`c')/(6*`a'^2)+`d'/(2*`a')
		local u = sign(`v')*sqrt((`b'/(3*`a'))^2-`c'/(3*`a'))
		local w = (_pi+acos(`v'/`u'^3))/3
		local p0null = 2*`u'*cos(`w')-`b'/(3*`a')
		local p1null = `p0null' + `mrg'

		// Check that MLE solution makes sense - may not be necessary  //
		_inrange01 `p0null' `p1null'
		if r(res)==0 {
		  cubic, c3(`a') c2(`b') c1(`c') c0(`d')
		  local nr = r(nroots)
		  foreach i of numlist 1/`nr' {
		    local x`i'0 = r(X`i')
		    local x`i'1 = `x0'+`mrg'
		  }
		  local r 0
		  foreach i of numlist 1/`nr' {
		    _inrange01 `x`i'0' `x`i'1'
		    if r(res)>0 {
		      local j = `i'
		      local r = `r'+1
		    }
		  }
		  if `r' == 0 {
		    di in red "Consrained ML equation for event probabilities under the null hypothesis has no solution"
		    exit 198
		  }
		  else if `r'>1 {
		    di in red "Consrained ML equation for event probabilities under the null hypothesis has more than one solution"
		    exit 198
		  }
		  else {
		    local p0null = `x`j'0'
		    local p1null = `p0null+`mrg'
		  }
		}
	}

	local D = abs(`p1'-`p0'-`mrg')
	local za = invnormal(1-`alpha'/2)
	local Alpha = 1 - `alpha'/2
	local sided two
	if "`onesided'" ~= "" { 
		local za = invnormal(1-`alpha')
		local sided one
	}
	local zb = invnormal(`power')
	local snull = sqrt(`p0null'*(1-`p0null')+`p1null'*(1-`p1null')/`aratio')
	local salt  = sqrt(`p0'*(1-`p0')+`p1'*(1-`p1')/`aratio')

	if `ss' {
		local m = ((`za'*`snull'+`zb'*`salt')/`D')^2
		if `ccorrect' {
		  _cc, n(`m') ad(`D') r(`aratio')
		  local m = r(n)
		}
		local n0 = ceil(`m')
		local n1 = ceil(`aratio'*`m')
		local N = `n0'+`n1'
		dis as txt "Total sample size = " as res `N'                                                                           
		return scalar n = `N'
		return scalar n0 = `n0'
		return scalar n1 = `n1'
	}
	else {
		if `ccorrect' {
		  _cc, n(`n0') ad(`D') r(`aratio') deflate(1)
		  local n0 = r(n)
		}
		local Power = normal(((`D'*sqrt(`n0') - `za'*`snull'))/`salt')
		dis as txt "Power = " as res `Power'
		return scalar power = `Power'
	}

end
***********************************************************************************************************************************

cap prog drop _inrange01
program define _inrange01, rclass
	local x 1
	while "`1'"~="" {
		local x = `x'*(`1'>0)*(`1'<1)
		macro shift
	}
	return scalar res = `x'
end
***********************************************************************************************************************************
cap prog drop _cc
program _cc, rclass
  syntax , n(real) ADiff(real) [Ratio(real 1) DEFlate(real 0)]
  local a = (`ratio'+1)/(`adiff'*`ratio')
  if `deflate' {
    local n = ((2*`n'-`a')^2)/(4*`n')
  }
  else {
    local cf=((1+sqrt(1+2*`a'/`n'))^2)/4
    local n=`n'*(`cf')
  }
  return scalar n=`n'
end
