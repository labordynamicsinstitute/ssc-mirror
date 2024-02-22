*! Version:	1.0.0
*! Author: Gregorio Impavido, International Monetry Fund, Email: gimpavido@imf.org

program define mvfilter, rclass 
	
	version 16.0
	
	syntax varlist(min=1 ts) [if] [in], 									///
	[Trend(string) Cycle(string) TYpe(string) Smooth(numlist max=1 >0)  	///
	OPTimal DETails AR(numlist max=1 integer >=0 <=2) ADJust Loop BETAcap]
	
	tempvar 			///
		cy_hp			/// cycle from static HP filter (needed for estimating beta(s)) 
		tr_hp 			/// trend from static HP filter (needed for estimating beta(s)) 
		cy_ss			/// cycle from SS before labeling
		tr_ss 				// trend from SS before labeling 
		
	tempname 			///
		lambda 			/// smoothing parameter 
		filtertype 		/// one-sided or two-sided
		p 				/// dimension of the AR(p) process in the cycle
		b				/// OLS estimates from AR regression in the cyc
		beta1			/// AR parameter imposed in the SS when AR(1) or AR(2) 
		beta2 			/// AR parameter imposed in the SS when AR(2) 
		var1_hp 		/// sample variance of the cycle from the static filter
		var0_hp 		/// sample variance of the slope in the trend in the static filter
		vratio_smpl_hp 	/// sample variance ratio in the static filter
		factor			/// adjustment factor for AR(1) (1-beta1^2) or AR(2) (1-beta1^2-beta2^2)
		hi lo av adjustor	/// parmeters for the sample variance adjustment loop
		var1_ss 		/// sample variance of the cycle from the SS 
		var0_ss 		/// sample variance of the slope in the trend from the SS
		vratio_smpl_ss 	///	sample variance ratio in the SS
		vratio_ss			// variance ratio in the SS

********************************************************************************
********************************* start checks *********************************
********************************************************************************
	quietly tsset
	*local timevar "`r(timevar)'"
	local unit "`r(unit)'"
	*local time_max_string "`r(tmaxs)'"
	local panel "`r(panelvar)'"
	if ("`panel'" != "") {
		display as error "Panel data not supported"
		error 198
	}
		
	// check that options have been formulated correctly
	* check that either trend or cycle have been formulated
	if ("`trend'"!="" | "`cycle'"!="") 	confirm new variable `trend' `cycle'
	else {
		display as error "At least one of {bf:trend()} and {bf:cycle()} options must be specified"
		error 198
	}

	* check if the filter is one-sided or two-sided
	if ("`type'"=="" | "`type'"=="twosided")	scalar `filtertype' = "twosided"  // this is the default option unless you specify -type(onesided)-
	else if ("`type'"=="onesided") 				scalar `filtertype' = "onesided"  
	else {
		display as error "The type of filter can only be only specified as: either {bf:type(onesided)} or {bf:type(twosided)}"
		error 198
		}
	
	* check what lambda to use (4 cases: 4th = endogenous lambda when "`optimal'"!="")
	if ("`smooth'"!="" & "`optimal'"!="") { // case 1: inconsistent options
		display as error "You cannot specify both {bf:smooth()} and {bf:optimal} options"
		error 198
	}
	else if ("`smooth'"=="" & "`optimal'"=="") { 
	// case 2: set lambda following Ravn-Uhlig (l=1600p^4, where p is the number of periods per quarter)
		if ("`unit'"=="daily") 		scalar `lambda' = 1600*(365/4)^4
		if ("`unit'"=="weekly") 	scalar `lambda' = 1600*(12)^4
		if ("`unit'"=="monthly") 	scalar `lambda' = 1600*(3)^4
		if ("`unit'"=="quarterly") 	scalar `lambda' = 1600
		if ("`unit'"=="halfyearly") scalar `lambda' = 1600*(1/2)^4
		if ("`unit'"=="yearly") 	scalar `lambda' = 1600*(1/4)^4
	}
	else if ("`smooth'"!="" & "`optimal'"=="") { // case 3: user-specified smoothing parameter
			scalar `lambda' = `smooth'
		}
	
	* check AR()
	if ("`ar'"=="") scalar `p' = 0
	else 			scalar `p' = `: di `ar''
	
	if (("`ar'"=="0" | "`ar'"=="") & "`adjust'"!="") {
			display as error "There is nothing to adjust if you are not running the dynamic filter. Please drop the option {bf:adjust}"
			error 198
		}
		

	if ("`ar'">="1" & "`optimal'"!="") { // case 1: inconsistent options
		display as error "The AR parameter(s) are estimated ex-ante for a given lambda. Hence, you cannot specify both {bf:AR(p)} with p>=1 and {bf:optimal}"
		error 198
	}
	
	if ("`ar'">="1" & "`type'"=="onsided") { // case 1: inconsistent options
		display as error "Since the autoregressive parameters will be estimated from the cycle stemming from a two-sided filter, you cannot specify both {bf:AR(p)} with p>=1 and {bf:type(onesided}"
		error 198
	}

	if ("`adjust'"=="" & "`loop'"!="") {
		display as error "There is nothing to loop as you have not spefied {bf:adjust}. Please drop {bf:loop}"
		error 198
	}
	
********************************************************************************
********************************** end checks **********************************
********************************************************************************

********************************************************************************
********************************* start model **********************************
********************************************************************************	
	**** get observed variable and exogenous variable(s) for the observed equation
	tokenize `varlist'
	local lhsvar "`1'" // this is the observed variable
	macro shift 1
	local rhsvars "`*'" // this is the exogenous variable(s) for the observed equation
	marksample touse 
	markout `touse' `lhsvar' `rhsvar'  // further trim the sample to match what SS will do
	
	**** case p==0.
	if (`p'==0) {
		*** set constraints 
		constraint drop _all

		* State transition matrix A 
		constraint define 1 [st1]l.st1 = 2
		constraint define 2 [st1]l.st2 = -1
		constraint define 4 [st2]l.st1 = 1
	
		* State exogenous variables matrix B
	
		* State errors matrix C
		constraint define 10 [st1]e.st1 = 1 

		* Observation matrix D
		constraint define 13 [`lhsvar']st1 = 1
	
		* Observation exogenous variables matrix F

		* Observation errors matrix G
		constraint define 18 [`lhsvar']e.`lhsvar' = 1

		* Constraint on the variance ratio of state and observed error variances
		if ("`optimal'"=="") { // with optimal you don't restrict the variance ratio and let the Kalman filter estimate lambda
			constraint define 19 `lambda'*[/state]state_sigma2=([/observable]obser_sigma2)
		}
		
		quietly sspace 													///
		(st1 l.st1 l.st2       e.st1, state noconstant) 				///
		(st2 l.st1                  , state noconstant) 				///
		(`lhsvar' st1 `rhsvars' e.`lhsvar', noconstant) if `touse', ///
		constraints(1/19) covstate(dscalar) covobserved(dscalar)
		scalar `vratio_ss' = [/observable]obser_sigma2/[/state]state_sigma2  // lambda splits the weights in front of the 2 error terms
				
		if (`filtertype'=="onesided") {
			quietly predict `tr_ss' if `touse', smethod(filter) equation(st1) states
			quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
		}
		if (`filtertype'=="twosided") {
			quietly predict `tr_ss' if `touse', smethod(smooth) equation(st1) states
			quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
		}
	}

	**** case p==1.
	if (`p'==1) {
		**** estimation of the autoregressive parameter
		qui tsfilter hp `cy_hp' = `lhsvar' if `touse', smooth(`: di `lambda'')
		qui gen `tr_hp' = `lhsvar' - `cy_hp' if `touse'
		qui arima `cy_hp' if `touse', ar(1)
		mat `b' = e(b)
		scalar `beta1' = `b'[1,2]
		if ("`betacap'"!="") scalar `beta1' = min(`b'[1,2], 0.85)  // Borio's prior (?)
		qui summ `cy_hp' if `touse'
		scalar `var1_hp' = r(sd)^2
		qui summ D2.`tr_hp' if `touse'
		scalar `var0_hp' = r(sd)^2
		scalar `vratio_smpl_hp' = `var1_hp'/`var0_hp'
	
		*** set constraints 
		constraint drop _all
		
		* State transition matrix A 
		constraint define 1 [st1]l.st1 = 2
		constraint define 2 [st1]l.st2 = -1
		constraint define 4 [st2]l.st1 = 1
	
		* State exogenous variables matrix B
	
		* State errors matrix C
		constraint define 10 [st1]e.st1 = 1 

		* Observation matrix D
		constraint define 13 [`lhsvar']st1 = 1
		constraint define 14 [`lhsvar']st2 = -`beta1'

		* Observation exogenous variables matrix F
		constraint define 16 [`lhsvar']l.`lhsvar' = `beta1' 
			
		* Observation errors matrix G
		constraint define 18 [`lhsvar']e.`lhsvar' = 1

		* Constraint on the variance ratio of state and observed error variances
		scalar `adjustor' = 1 // needed for the loop
		scalar `factor' = (1-`beta1'^2)
		constraint define 19 (`lambda'*`factor'*`adjustor')*[/state]state_sigma2=([/observable]obser_sigma2)
				
		if ("`adjust'"=="") {
			quietly sspace 													///
			(st1 l.st1 l.st2       e.st1, state noconstant) 				///
			(st2 l.st1                  , state noconstant) 				///
			(`lhsvar' st1 st2 l.`lhsvar' `rhsvars' e.`lhsvar', noconstant) if `touse', ///
			constraints(1/19) covstate(dscalar) covobserved(dscalar)
			scalar `vratio_ss' = [/observable]obser_sigma2/[/state]state_sigma2  
			
			quietly predict `tr_ss' if `touse', smethod(smooth) equation(st1) states
			quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
		}
		
		if ("`adjust'"!="") {
			* initialize the loop
			scalar `hi' = 2 //we need to endogenize the max
			scalar `lo' = 0
			scalar `av' = (`hi'+`lo')/2
			noisily di " "
			if ("`loop'"=="") noisily _dots 0, title(Adjusting the SS variance ratio for small sample problem) 
			local rep 1 // this is just a counter

			while (`hi'-`lo') > 0.00001 {
				capture drop `cy_ss' `tr_ss'
				scalar `adjustor' = `av'
				*constraint define 19 (`lambda'*`factor'*`adjustor')*[/state]state_sigma2=([/observable]obser_sigma2)

				quietly sspace 													///
				(st1 l.st1 l.st2       e.st1, state noconstant) 				///
				(st2 l.st1                  , state noconstant) 				///
				(`lhsvar' st1 st2 l.`lhsvar' `rhsvars' e.`lhsvar', noconstant) if `touse', ///
				constraints(1/19) covstate(dscalar) covobserved(dscalar)
				scalar `vratio_ss' = [/observable]obser_sigma2/[/state]state_sigma2  
							
				predict `tr_ss' if `touse', smethod(smooth) equation(st1) states
				quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
			
				quietly summ `cy_ss' if `touse'
				scalar `var1_ss'=r(sd)^2 
				quietly summ D2.`tr_ss' if `touse'
				scalar `var0_ss'=r(sd)^2
				scalar `vratio_smpl_ss' = `var1_ss'/`var0_ss'

				if (`vratio_smpl_ss'>=`vratio_smpl_hp')	scalar `hi'=`av'
				else 									scalar `lo'=`av'
				scalar `av' = (`hi'+`lo')/2
		
				if ("`loop'"!="") {
					noisily di as text "Rep. No: " `rep' 
					noisily di as text "AR(1) Var ratio = " `vratio_ss' "
					noisily di as text "AR(1) Var ratio adjustor = " `adjustor'
					noisily di as text "AR(1) smpl Var ratio = " `vratio_smpl_ss'
					noisily di as text "AR(0) smpl Var ratio = " `vratio_smpl_hp'
					noisily di as text " "
					}
				local ++rep
				if ("`loop'"=="") noisily _dots `rep' 0
			} // end of while
		}  // end of if
	} // end of p=1	

	**** case p==2.
	if (`p'==2) {
		**** estimation of the autoregressive parameter
		qui tsfilter hp `cy_hp' = `lhsvar' if `touse', smooth(`: di `lambda'')
		qui gen `tr_hp' = `lhsvar' - `cy_hp' if `touse'
		qui arima `cy_hp' if `touse', ar(1/2)
		mat `b' = e(b)
		scalar `beta1' = `b'[1,2]
		scalar `beta2' = `b'[1,3]
		qui summ `cy_hp' if `touse'
		scalar `var1_hp' = r(sd)^2
		qui summ D2.`tr_hp' if `touse'
		scalar `var0_hp' = r(sd)^2
		scalar `vratio_smpl_hp' = `var1_hp'/`var0_hp'
	
		*** set constraints 
		constraint drop _all
		
		* State transition matrix A 
		constraint define 1 [st1]l.st1 = 2
		constraint define 2 [st1]l.st2 = -1
		constraint define 4 [st2]l.st1 = 1
		constraint define 8 [st3]l.st2 = 1	
		
		* State exogenous variables matrix B
	
		* State errors matrix C
		constraint define 10 [st1]e.st1 = 1 

		* Observation matrix D
		constraint define 13 [`lhsvar']st1 = 1
		constraint define 14 [`lhsvar']st2 = -`beta1'
		constraint define 15 [`lhsvar']st3 = -`beta2'

		* Observation exogenous variables matrix F
		constraint define 16 [`lhsvar']l.`lhsvar' = `beta1' 
		constraint define 17 [`lhsvar']l2.`lhsvar' = `beta2'
		
		* Observation errors matrix G
		constraint define 18 [`lhsvar']e.`lhsvar' = 1

		* Constraint on the variance ratio of state and observed error variances
		scalar `adjustor' = 1 // needed for the loop
		scalar `factor' = (1-`beta1'^2-`beta2'^2)
		constraint define 19 (`lambda'*`factor'*`adjustor')*[/state]state_sigma2=([/observable]obser_sigma2)
						
		if ("`adjust'"=="") {
			quietly sspace 													///
			(st1 l.st1 l.st2       e.st1, state noconstant) 				///
			(st2 l.st1                  , state noconstant) 				///
			(st3 l.st2                  , state noconstant) 				///
			(`lhsvar' st1 st2 st3 l.`lhsvar' l2.`lhsvar' `rhsvars' e.`lhsvar', noconstant) if `touse', ///
			constraints(1/19) covstate(dscalar) covobserved(dscalar)
			scalar `vratio_ss' = [/observable]obser_sigma2/[/state]state_sigma2
			
			quietly predict `tr_ss' if `touse', smethod(smooth) equation(st1) states
			quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
		}
		if ("`adjust'"!="") {
			* initialize the loop
			scalar `hi' = 2 //we need to endogenize the max
			scalar `lo' = 0
			scalar `av' = (`hi'+`lo')/2
			noisily di " "
			if ("`loop'"=="") noisily _dots 0, title(Adjusting the SS variance ratio for small sample problem) 
			local rep 1 // this is just a counter

			while (`hi'-`lo') > 0.00001 {
				capture drop `cy_ss' `tr_ss'
				scalar `adjustor' = `av'
				*constraint define 19 (`lambda'*`factor'*`adjustor')*[/state]state_sigma2=([/observable]obser_sigma2)

				quietly sspace 													///
				(st1 l.st1 l.st2       e.st1, state noconstant) 				///
				(st2 l.st1                  , state noconstant) 				///
				(st3 l.st2                  , state noconstant) 				///
				(`lhsvar' st1 st2 st3 l.`lhsvar' l2.`lhsvar' `rhsvars' e.`lhsvar', noconstant) if `touse', ///
				constraints(1/19) covstate(dscalar) covobserved(dscalar)
				scalar `vratio_ss' = [/observable]obser_sigma2/[/state]state_sigma2
							
				predict `tr_ss' if `touse', smethod(smooth) equation(st1) states
				quietly gen `cy_ss' = `lhsvar' - `tr_ss' if `touse'
			
				quietly summ `cy_ss' if `touse'
				scalar `var1_ss'=r(sd)^2 
				quietly summ D2.`tr_ss' if `touse'
				scalar `var0_ss'=r(sd)^2
				scalar `vratio_smpl_ss' = `var1_ss'/`var0_ss'

				if (`vratio_smpl_ss'>=`vratio_smpl_hp')	scalar `hi'=`av'
				else 									scalar `lo'=`av'
				scalar `av' = (`hi'+`lo')/2
		
				if ("`loop'"!="") {
					noisily di as text "Rep. No: " `rep' 
					noisily di as text "AR(2) Var ratio = " `vratio_ss' "
					noisily di as text "AR(2) Var ratio adjustor = " `adjustor'
					noisily di as text "AR(2) smpl Var ratio = " `vratio_smpl_ss'
					noisily di as text "AR(0) smpl Var ratio = " `vratio_smpl_hp'
					noisily di as text " "
					}
				local ++rep
				if ("`loop'"=="") noisily _dots `rep' 0
			} // end of while
		}  // end of if
	} // end of p=2	

********************************************************************************
*********************************** end model **********************************	
********************************************************************************

********************************************************************************
****************************** label the estimates *****************************
********************************************************************************
	if ("`details'"!="") sspace, noomitted

	if (`filtertype'=="onesided") {
		if ("`trend'"!="") {
			quietly generate `trend' = `tr_ss' if `touse'
			label var `trend' "`lhsvar' trend component from SS (one-sided, Var ratio = `: di `vratio_ss'', AR(`: di `p'')"
		}
		if ("`cycle'"!="") {
			quietly generate `cycle' = `cy_ss' if `touse'
			label var `cycle' "`lhsvar' cyclical component from SS (one-sided, Var ratio = `: di `vratio_ss'', AR(`: di `p''))"
		}
	}
	if (`filtertype'=="twosided") {  // this is the default option unless you specify -type(onesided)-
		if ("`trend'"!="") {
			quietly generate `trend' = `tr_ss' if `touse'
			label var `trend' "`lhsvar' trend component from SS (two-sided, Var ratio = `: di `vratio_ss'', AR(`: di `p'')"
		}
		if ("`cycle'"!="") {
			quietly generate `cycle' = `cy_ss' if `touse'
			label var `cycle' "`lhsvar' cyclical component from SS (two-sided, Var ratio = `: di `vratio_ss'', AR(`: di `p''))"
		}
	}
********************************************************************************
******************************** end estimations *******************************
********************************************************************************
di as text "Trend and cycle estimated"

********************************************************************************
********************************** start return ********************************
********************************************************************************
	
	return scalar lambda = `lambda'
	return scalar var_ratio = `vratio_ss'
	return scalar ar_p = `p'
	
	if (`filtertype'=="onesided")  {
		return local type = `"MV filter (one-sided)"'	
	}
	if (`filtertype'=="twosided") {
		return local type = `"MV filter (two-sided)"'
	}
	return local unit = "`unit'"
	return local observed = "`lhsvar'"
	return local exogenous = "`rhsvars'"
	return local cycle = "`cycle'"
	return local trend = "`trend'"	
		
********************************************************************************
*********************************** end return *********************************
********************************************************************************

end