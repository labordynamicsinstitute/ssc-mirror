/* ************************************************************************************************************************************************
* PLEASE NOTE: FOR 2 GROUPS THE NOTATION AND CODE BELOW IS P0 AND P1, HOWEVER IN ARTBIN.ADO, THE TABLE OUTPUT AND THE HELPFILE IT IS P1 AND P2

                            Sample size for noninferiority of proportions

The below text assumes that the trial aim is to demonstrate that the intervention decreases the outcome 
probability relative to {control probability + margin}.  If the aim is to increase then reverse the
greater/less than signs below.

Let p0 and p1 be the anticipated proportions in the control and treatment group respectively.
Null hypothesis H0: d=p1-p0>=mrg; Alternative hypothesis H1: d<mrg; 
where mrg is the hypothesised margin for the difference in anticipated proportions
For the non-inferiority design, mrg > 0 is the noninferiority margin.
For the classical superiority design, mrg = 0 and for a substantial superiority design mrg < 0
Although the hypotheses are stated as one-sided, the recommended analysis is to use two sided tests
since the direction of the difference is almost always unknown apriori and one would normally use a two-sided CI for the difference.

Design			Margin		Outcome
------			------		-----------
Non-ineriority		> 0		Favourable
Non-ineriority		< 0		Unfavourable
Classical Superiority	= 0		Favourable/Unfavourable
Substantial Superiority	< 0		Unfavourable
Substantial Superiority	> 0		Favourable

The sample size is the solution of

 {[za*Sqrt(var(Dhat|H0))+zb*Sqrt(var(Dhat|H1))]^2}/[(d-mrg)^2] = 1 --------------[1]

var(Dhat|H1) is estimated using the unconstrained sample estimates p0hat and p1hat of p0 and p1,
 the observed proportions in the two treatment groups, which converge to p0*(1-p0)/n0+p1*(1-p1)/n1
There are several methods for estimating Var(Dhat|H0) based on P0*(1-P0)/n0+P1*(1-P1)/n1
Method 1 sets P0=p0 and P1=p1, ie uses same sample estimates as in var(Dhat|H1).
Other methods use limits of constrained estimates P0 and P1 such that P1-P0 = mrg. Two of these are

Method 2: P1 = (n0*p0hat+n1*p1hat+n0*mrg)/(n0+n1) = (p0hat+r*p1hat+mrg)/(1+r), and
          P0 = (n0*p0hat+n1*p1hat-n0*mrg)/(n0+n1) = (p0hat+r*p1hat-r*mrg)/(1+r), 
where r=n1/n0 is the allocation ratio These estimates are under fixed marginal totals 
(see Dunnett & Gent, Biometrics 1977). In the limit p0hat and p1hat are replaced by p0 and p1. 
For these estimates to lie between 0 and 1, we must have
max(-mrg, r*mrg) < p0+r*p1 < 1+r+min(-mrg, r*mrg).

3)Uses constrained ML to estimate p0 and p1, with constraints: P1-P0=mrg; 0<P0<1 and 0<P1<1. This is based approximately on the
  score test (see Farrington & Manning, Stat in Med 1990)

Continuity corrected sample size is estimated by inflating the uncorrected sample size n0 obtained from [1]
by cif (the continuity-corrected inflation factor) given by
  (1 + sqrt(1+2*(1+r)/(N*r*abs(d-mrg))^2)/4
See Fleiss, Levin, and M. C. Paik (2003): Statistical Methods for Rates and Proportions.

For given sample size N, the programme estimates power. For continuity corrected power, the designed sample size n is first deflated by a factor of
 [1 - (a/n)*(1-a/(4*n))], provided that n > a/(4*n), where a = (1+r)/(r*abs(d-mrg)).

Syntax art2bin p0 p1 [, margin(#) n0(#) n1(#) ar(#) alpha(#) power(#) nvmethod(#) onesided]
******************************************************************************************************************************** */
*!version 1.01  09june2022
* version 1.01  09june2022 EMZ   Changed p to pi in hypothesis tests.  Removed warning if p1 + m lies outside (0,1) as per 	
*					             Ab's suggestion.
* version 1.00  08oct2021  EMZ   Release
* version 0.16  21oct2021  EMZ   Changed some wording of the error messages.
* version 0.15  07oct2021  EMZ   Changed version date
* version 0.14  16sep2021  EMZ   From PR testing: put version statements in to program and all subroutines. Changed comments to refer to 
*                                favourable/unfavourable instead of failure/success. 
* version 0.13  17june2021 EMZ   Removed code checking consrained ML soln for event probabilities under the null hypothesis and replaced with an error msg,
* version 0.12  20may2021  EMZ   As a result of IW testing: Added fav/unfav options to 2-arm superiority case.  Issue a warning when p1+margin is not in 
*								 (0,1). If user specifies n (to calculate power) turn noround on so that the specified n is maintained.
* version 0.11  19apr2021 EMZ    Removed -noround- option for D, so D is not rounded.
* version 0.10  01mar2021 EMZ    From IW testing results: Put all output options in sentence case.   Applied -noround- to D as well.
* 								  Removed the warning message so that if the user selects wald the default will go to nvm(1) *without* a 
*        	   					  warning message.  Changed the returned values so that the following are available: total SS, SS per group, number of 
*                                 events and power.
* version 0.09  08feb2021 AB/EMZ Changed default in syntax to NVMethod(numlist max=1) (instead of NVMethod(int 0)).  This is because we need to 		
*  								  distinugush cases where the user has actually specified nvm (as opposed to leaving it blank, e.g. when nvm() is not 
*                                 specified and wald is selected, the code defaults to nvm(1)). Otherwise the default nvm is set to 3 later in the code. *								   (These were the changes made by AGB to art2bin_v007ab/suggested by Ab, put in to this version by EMZ).  Removed 
*                                 eventtype(string) option.  Put in favourable/unfavourable trial outcome options (user can specify fav/unfav, if specified 
*                                 then sense checked, if not specified then inferred).  Changed super-superiority terminology to be				
*								  substantial-superiority.							  
* version 0.08  26oct2020 EMZ    Tidied unused code and typos.  Changed so that wald without nvm() goes to nvm(1) (instead of an error message) with 	
* 								  warning that the default nmv(3) has been changed to nvm(1).  Applied -ceil- to the calculations of D.
* version 0.07  17sep2020 EMZ    Change rounding option so rounds n UP to the nearest integer if -noround- is not specified                         
* version 0.06  24aug2020 EMZ    Added in error message to not allow Wald and Local at the same time, to not allow local & nvmethod ~=3, to not allow local 
*                                & nvmethod ~=3 with nvmethod=3 as the default.  Add in error message so do not allow Wald & nvmethod ~=1.  Taken out the 
*                                error message that does not allow non-integer allocation ratios.  Change rounding option so rounds n to the nearest  
*                                integer if -noround- (new option) is not specified
* version 0.05  10aug2020 AGB    Added (1) local alt option (default distant); (2) test option: wald (default is score)
*								 
* version 0.04  20jul2020 AGB    Fixed bug: solution of consrained ML equation for event probabilities under the null hypothesis (a cubic equation)
*								  can involve 0/0 when (p0+p1)=1 and margin=0.
* version 0.03  30may2019 EMZ    Removed the error message "By specifying n(0) / n() missing, sample size will be calculated by artbin" and added a   
*                                 clarification instead in the helpfile. Added in an error message if power is not between 0 and 1. 
* version 0.02  11mar2019 EMZ    Added returned results to feed back in to artbin output. Put in warning message to clarify that if a sample size of 0 is 
*                                 specified (n(0)) then sample size will actually be calculated.
*                                 Changed version date
* version 0.01  14Sep2012

cap prog drop art2bin
program define art2bin, rclass
version 8
	gettoken p0 0 : 0, parse(" ,")
	gettoken p1 0    : 0, parse(" ,")

	confirm number `p0'
	confirm number `p1'

	local dalpha = 1 - $S_level/100
	local dpower 0.8
	local ss 0

	syntax [, MARgin(real 0) n(int 0) n0(int 0) n1(int 0) ARatio(string)		           ///
                  Alpha(real `dalpha')  Power(real `dpower') NVMethod(numlist max=1)	  ///
				  ONESided CCorrect VERsion(string)			                             ///
				  UNFavourable FAVourable UNFavorable FAVorable                         /// Added in unfavourable/favourable options
				  LOcal WAld NOROUND] 												   /// Added  options incl. noround
				  

********************************************************************************
	if "`version'"=="" local version "binary version 2.0.2 23may2023"
********************************************************************************

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
		
	if max(`power',1-`power')>=1 {
	di as err "power() out of range"
	exit 198 
    }
	
	local nar 0
	local ar0 0
	local ar1 0
	tokenize "`aratio'", parse(" :,")
	while "`1'" ~= "" {
		if ("`1'"~=":")&("`1'"~=",") {

			if `1'<=0 {
				di as err  "Allocation ratio <=0 not alllowed"
				exit 198
			}
			local ar`nar' `1'
			local ++nar
		}
		macro shift
	}
	if (`nar'==0)|(`nar'==1 & `ar0'==1)|(`nar'==2 & `ar0'==1 & `ar1'==1) {
		local allocr "equal group sizes"
		local ar10 1
	}
	else if `nar'==1 {
		local allocr "1:`ar0'"
		local ar10 `ar0'
	}
	else if `nar'==2 {
		local allocr "`ar0':`ar1'"
		local ar10 = `ar1'/`ar0'
	}
	else {
		di as err  "Invalid allocation ratio"
		exit 198
	}
	

* Do not allow wald & nvmethod ~=1 (if nvm is specified)
	  if "`wald'"!="" & "`nvmethod'"!="" & "`nvmethod'"!="1" {
	  	di as error "Need nvm(1) if Wald specified"
        exit 198
	  }
	  
* If nvm() is not specified and wald is selected, default to nvm(1) 
	if "`wald'"!="" & "`nvmethod'"=="" {
		local nvmethod = 1
*	  	di "{it: WARNING: the default nvm(3) has been changed to nvm(1) as Wald has been selected}"
	  }
	
* Add in error messages to not allow local and wald at the same time
    if "`local'" != "" & "`wald'" != "" {
		di as error "Local and Wald not allowed together"
                exit 198
	}

* Make nvmethod=3 the default if not specified	
	 if "`nvmethod'"!="" {
		if `nvmethod'>3 | `nvmethod'<1  {
		local nvmethod 3
		}
	 }
	 else if "`nvmethod'"=="" local nvmethod 3


* Do not allow local & nvmethod ~=3
	  if "`local'"!="" & `nvmethod'!=3 {
	  	di as error "Need nvm(3) if local specified"
        exit 198
	  }	
	  
* If the user specifies n, turn noround on
if ("`n'"!="0") local noround = "noround"


	if `n'<0 | `n0'<0 | `n1'<0 { 
		di in red "Sample size n() out of range"
		exit 198
	}
	if `n'==0 {
		if `n0' == 0 & `n1' == 0 {
			local ss 1		// Calculate sample size
		}
		else if `n1' == 0 {
			local n1 = `n0'*`ar10'
		}
		else if `n0' == 0 {
			local n0 = `n1'/`ar10'
		}
		else {
			local allocr "`n0':`n1'"
			local ar10 = `n1'/`n0'
		}
	}
	else {
		if `n0' == 0 & `n1' == 0 {
			local n0 = `n'/(1+`ar10')
			local n1 = `n'-`n0'
		}
		else if `n1' == 0 {
			local n1 = `n'-`n0'
			local allocr "`n0':`n1'"
			local ar10 = `n1'/`n0'
		}
		else if `n0' == 0 {
			local n0= `n'-`n1'
			local allocr "`n0':`n1'"
			local ar10 = `n1'/`n0'
		}
		else {
			cap assert `n0'+`n1' == `n'
			if _rc {
				di as err  "Invalid sample size"
				exit 198
			}
			local allocr "`n0':`n1'"
			local ar10 = `n1'/`n0'
		}
	}

* From artcat: accommodate American spellings
if !mi("`favorable'") local favourable favourable
if !mi("`unfavorable'") local unfavourable unfavourable

if !mi("`unfavourable'") & !mi("`favourable'") {
	di as err "Can not specify both unfavourable and favourable"
	exit 198
}

* if margin is not specified set it as the default 0
		if "`margin'" == "" local margin = 0
		if `margin' == 0 local trialtype = "Superiority"

		local w1 `p0'
		local w2 `p1'
		
		local threshold = `w1' + `margin'
				
	if mi("`favourable'`unfavourable'") { // infer outcome direction if not specified
	
		if `w2' < `threshold' local trialoutcome = "Unfavourable"
		if `w2' > `threshold' local trialoutcome = "Favourable"
	}
	else {
		
		if !mi("`unfavourable'") local trialoutcome = "Unfavourable"
		if !mi("`favourable'") local trialoutcome = "Favourable"	
	}
	
		if `w2' == `threshold' {
			di as err "p2 can not equal p1 + margin"
			exit 198
		}
		
		* Stop program with error if wrong option is used, unless 'force' is specified
		if "`trialoutcome'" == "Unfavourable" & `threshold' < `w2' & "`force'" == "" {
			di as err "artbin thinks your outcome is favourable. Please check your command. If your command is correct then consider using the -force- option."
			exit 198
		}
		else if "`trialoutcome'" == "Unfavourable" & `threshold' < `w2' & "`force'" == "force" {
			di "{it: WARNING: artbin thinks your outcome should be favourable.}"
		}
		if "`trialoutcome'" == "Favourable" & `threshold' > `w2' & "`force'" == "" {
			di as err "artbin thinks your outcome is unfavourable. Please check your command. If your command is correct then consider using the -force- option."
			exit 198
		}
		else if "`trialoutcome'" == "Favourable" & `threshold' > `w2' & "`force'" == "force" {
			di "{it: WARNING: artbin thinks your outcome should be unfavourable.}"
		}
		
		* Define NI and substantial-superiority
		if ("`trialoutcome'" == "Unfavourable" & `margin' > 0 | "`trialoutcome'" == "Favourable" & `margin' < 0) {
			local trialtype "Non-inferiority"
		}
		else if ("`trialoutcome'" == "Unfavourable" & `margin' < 0 | "`trialoutcome'" == "Favourable" & `margin' > 0) {
			local trialtype "Substantial-superiority"
		}
		if "`trialoutcome'" == "Unfavourable" {
			local H0 = "H0: pi2-pi1 >= `margin'"
			local H1 = "H1: pi2-pi1 < `margin'"
		}
		else if "`trialoutcome'" == "Favourable" {
			local H0 = "H0: pi2-pi1 <= `margin'"
			local H1 = "H1: pi2-pi1 > `margin'"
		}


	local mrg = `margin'

	// Method for estimating event probabilities under null hypothesis //
	local method1 Sample estimate
	local method2 Fixed marginal totals
	local method3 Constrained maximum likelihood

	// Estimating event probabilities and variance of the test stat //
	// under the null hypothesis //
	local nvm = `nvmethod'
	if `nvm'>3 | `nvm'<1 {
		local nvm 3
	}
	if `nvm' == 1 {
		local p0null = `p0'
		local p1null = `p1'
	}
	if `nvm' == 2 {								// Fixed marginal totals
		local p0null = (`p0'+`ar10'*`p1'-`ar10'*`mrg')/(1+`ar10')
		local p1null = (`p0'+`ar10'*`p1'+`mrg')/(1+`ar10')
		cap assert (`p0null'>0) & (`p0null'<1) & (`p1null'>0) & (`p1null'<1)
		if _rc {
		  local erm Event probabilities and/or non-inferiority/superiority margin are
		  local erm `erm' incompatible with the requested fixed marginal totals method
		  di in red "`erm'"
		  exit 198
		}
	}
	else if `nvm' == 3 {							// Constrained ML
		local a = 1+`ar10'
		local b = `mrg'*(`ar10'+2)-1-`ar10'-`p0'-`ar10'*`p1'
		local c = (`mrg'-1-`ar10'-2*`p0')*`mrg'+`p0'+`ar10'*`p1'
		local d = `p0'*`mrg'*(1-`mrg')
		local v = (`b'/(3*`a'))^3-(`b'*`c')/(6*`a'^2)+`d'/(2*`a')
		local u = sign(`v')*sqrt((`b'/(3*`a'))^2-`c'/(3*`a'))

*		local w = (_pi+acos(`v'/`u'^3))/3
		local toosmall = 1e-12
		local cos = cond((abs(`v')<=`toosmall' & abs(`u'^3)<=`toosmall'), 0, `v'/`u'^3)
		local w = (_pi+acos(`cos'))/3

		local p0null = 2*`u'*cos(`w')-`b'/(3*`a')
		local p1null = `p0null' + `mrg'

		_inrange01 `p0null' `p1null'
		if r(res)==0 {
           di as error "You have found a case that we have never encountered before!  Please contact the artbin authors to let us know, many thanks."
		}
	}
	local D = abs(`p1'-`p0'-`mrg')
	local za = invnormal(1-`alpha'/2)
*	local Alpha = 1 - `alpha'/2
	local sided two
	if "`onesided'" ~= "" { 
		local za = invnormal(1-`alpha')
		local sided one
	}
	local zb = invnormal(`power')
	local snull = sqrt(`p0null'*(1-`p0null')+`p1null'*(1-`p1null')/`ar10')
	local salt  = sqrt(`p0'*(1-`p0')+`p1'*(1-`p1')/`ar10')

	local cc = "`ccorrect'"~=""
	if `ss' {
		local m = ((`za'*`snull'+`zb'*`salt')/`D')^2

		if "`local'"~="" local m = ((`za'*`snull'+`zb'*`snull')/`D')^2
		if "`wald'"~=""  local m = ((`za'*`salt'+`zb'*`salt')/`D')^2

		if `cc' {
		  _cc, n(`m') ad(`D') r(`ar10')
		  local m = r(n)
		}

* Change rounding option so rounds n/D UP to the nearest integer if noround is not specified
if "`noround'"=="" {
    local n0 = ceil(`m')
	local n1 = ceil(`ar10'*`m') 
*	local D = ceil(`D')
*   calculate D on rounded n
	local D = (`n0'*`p0') + (`n1'*`p1') 
}
else {
	local n0 = `m'
	local n1 = `ar10'*`m'
	local D = `D'
}	
                  
		local n = `n0'+`n1'
		local Power `power'
		dis as txt "Total sample size = " as res `n'                                                                           
		return scalar n = `n'
		return scalar n0 = `n0'
		return scalar n1 = `n1'
		return scalar power = `Power'
	}
	else {
		if `cc' {
		  _cc, n(`n0') ad(`D') r(`ar10') deflate(1)
		  local n0 = r(n)
		}
		local Power = normal(((`D'*sqrt(`n0') - `za'*`snull'))/`salt')

		if "`local'"~="" local Power = normal(((`D'*sqrt(`n0') - `za'*`snull'))/`snull')
		if "`wald'"~=""  local Power = normal(((`D'*sqrt(`n0') - `za'*`salt'))/`salt')

		dis as txt "Power = " as res `Power'
		return scalar power = `Power'
	}
return scalar alpha = `alpha'	
return local allocr "`allocr'"
return local power =  `Power'
local Dart = (`n0'*`p0') + (`n1'*`p1')   
*if "`noround'"=="" local Dart =ceil(`Dart')
*else local Dart = `Dart'
return scalar Dart = `Dart'
frac_ddp `p1'-`p0' 3


end

cap prog drop _inrange01
version 8
program define _inrange01, rclass
	local x 1
	while "`1'"~="" {
		local x = `x'*(`1'>0)*(`1'<1)
		macro shift
	}
	return scalar res = `x'
end

cap prog drop _cc
version 8
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
