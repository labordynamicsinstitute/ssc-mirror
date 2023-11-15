**************************************************
*												 *
*  PROGRAM TO CALCULATE SAMPLE SIZE FOR MODEL    * 
*	VALIDATION BASED ON PRECISION OF PERFORMANCE *
*  31/01/22 									 *
*  												 *
*	Updated: 10/11/23							 *
*	- added net benefit as an optional criteria  *	
*												 *
*  1.0.1 J. Ensor								 *
**************************************************

*! 1.0.1 J.Ensor 10Nov2023

program define pmvalsampsize, rclass

version 12.1

/* Syntax
	CONTINUOUS = use pmvalsampsize for continuous outcome model sample size
	SURVIVAL = use pmvalsampsize for survival outcome model sample size
	BINARY = use pmvalsampsize for binary outcome model sample size
	RSQUARED = anticipated value of the (Cox-Snell) R-squared in the validation sample, based on R-sq adjusted value from model development study
	VAROBS = anticipated variance of observed values in the validation sample 
	RSQCIwidth = target precision in terms of CI width for Rsq
	CSlope = assumed C-slope performance in validation sample
	CSCIwidth = target precision in terms of CI width for C-slope
	CITL = assumed CITL performance in validation sample
	CITLCIwidth = target precision in terms of CI width for CITL
	MMOE = set MMOE threshold for acceptable precision of residual variance of CITL & C-slope
	PREVALENCE = prevalence of outcome
	SEED = set seed for simulation based calclulations 	
	NOPRINT = Suppress criteria descriptions in output 
	TRACE = Output a trace of iteration procedure for obtaining non-event mean under lpcstat option
*/

syntax ,   TYPE(string) ///
			[RSQuared(real 0) RSQCIwidth(real 0.1) /// 
			CSlope(real 1) CSCIwidth(real 0.2) /// 
			CITL(real 0) CITLCIwidth(real 0) VAROBS(real 0) /// 
			PREValence(real 0) SIMOBS(int 1000000) /// 
			CSTATistic(real 0) CSTATCIwidth(real 0.1) ///
			OE(real 1) OECIwidth(real 0.2) ///
			LPNORMal(numlist max=2) LPSKEWednormal(numlist max=4) ///
			LPBETA(numlist max=2) LPCSTAT(numlist max=1) /// 
			TOLerance(real 0.0005) INCrement(real 0.1) OESEINCrement(real 0.0001) ///
			SEED(int 123456) MMOE(real 1.1) TRACE GRAPH CALCURves noPRINT ///
			SENSitivity(real 0) SPECificity(real 0) THRESHold(real 0) ///
			NBCIwidth(real 0.2) NBSEINCrement(real 0.0001)]


***********************************************

if "`type'"=="b" {
	if "`graph'"=="graph" {
			local graph_ind "graph"
	}
	else {
	    local graph_ind ""
	}
	
	if "`trace'"=="trace" {
			local trace_ind "trace"
	}
	else {
	    local trace_ind ""
	}
	
	if "`lpnormal'"!="" {
		
		if "`lpskewednormal'"!="" | "`lpbeta'"!="" | "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
		binary_val_samp_size, prev(`prevalence') cstat(`cstatistic') ///
				oe(`oe') oeci(`oeciwidth') oeseinc(`oeseincrement') ///
				cs(`cslope') csciwidth(`csciwidth') ///
				cstatci(`cstatciwidth') simobs(`simobs') ///
				sens(`sensitivity') spec(`specificity') thresh(`threshold') ///
				nbciwidth(`nbciwidth') nbseincrement(`nbseincrement') ///
				tol(`tolerance') inc(`increment') seed(`seed') lpnormal(`lpnormal') `graph_ind' `trace_ind'
		
	}
	else if "`lpskewednormal'"!="" {
	    
		if "`lpbeta'"!="" | "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
		binary_val_samp_size, prev(`prevalence') cstat(`cstatistic') ///
				oe(`oe') oeci(`oeciwidth') oeseinc(`oeseincrement') ///
				cs(`cslope') csciwidth(`csciwidth') ///
				cstatci(`cstatciwidth') simobs(`simobs') ///
				sens(`sensitivity') spec(`specificity') thresh(`threshold') ///
				nbciwidth(`nbciwidth') nbseincrement(`nbseincrement') ///
				tol(`tolerance') inc(`increment') seed(`seed') lpskewednormal(`lpskewednormal') `graph_ind' `trace_ind'
		
	}
	else if "`lpbeta'"!="" {
	    
		if "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
		binary_val_samp_size, prev(`prevalence') cstat(`cstatistic') ///
				oe(`oe') oeci(`oeciwidth') oeseinc(`oeseincrement') ///
				cs(`cslope') csciwidth(`csciwidth') ///
				cstatci(`cstatciwidth') simobs(`simobs') ///
				sens(`sensitivity') spec(`specificity') thresh(`threshold') ///
				nbciwidth(`nbciwidth') nbseincrement(`nbseincrement') ///
				tol(`tolerance') inc(`increment') seed(`seed') lpbeta(`lpbeta') `graph_ind' `trace_ind'
		
	}
	else if "`lpnormal'"=="" & "`lpskewednormal'"=="" & "`lpbeta'"=="" & "`lpcstat'"=="" {

			di as err "An LP distribution must be specified"
			error 102

	}
	else {
		binary_val_samp_size, prev(`prevalence') cstat(`cstatistic') ///
				oe(`oe') oeci(`oeciwidth') oeseinc(`oeseincrement') ///
				cs(`cslope') csciwidth(`csciwidth') ///
				cstatci(`cstatciwidth') simobs(`simobs') ///
				sens(`sensitivity') spec(`specificity') thresh(`threshold') ///
				nbciwidth(`nbciwidth') nbseincrement(`nbseincrement') ///
				tol(`tolerance') inc(`increment') seed(`seed') lpcstat(`lpcstat') `graph_ind' `trace_ind'
				
		ret sca non_event_mean = r(non_event_mean)
		ret sca event_mean = r(event_mean)
		ret sca common_variance = r(common_variance)
		ret sca tolerance = r(tolerance)
		ret sca increment = r(increment)
		ret sca simulated_data_cstat = r(simulated_data_cstat)
	}
		
	// return list
	return scalar sample_size = r(sample_size)
	return scalar events = r(events)
	return scalar prevalence = r(prevalence)
	local retlist oe se_oe lb_oe ub_oe width_oe cslope se_cslope csciwidth cstatistic se_cstat cstatciwidth sensitivity specificity threshold nb standardised_nb
		foreach s of local retlist {
		ret sca `s' = r(`s')
		}
		
	mat def binary_val_samp_size_results = r(results)
	return mat results = binary_val_samp_size_results
	
	if "`print'"!="noprint" {
		criteria_print, type("`type'") sens(`sensitivity') spec(`specificity') thresh(`threshold')
	}
	}
	else if "`type'"=="c" {
		
***********************************************
	if `rsquared'==0 {
				di as err "rsquared() must be specified"
				error 103
			}

	continuous_val_samp_size , rsq(`rsquared') varobs(`varobs') rsqci(`rsqciwidth') ///
		cs(`cslope') csci(`csciwidth') ///
		citl(`citl') citlci(`citlciwidth') mmoe(`mmoe')
	
	return scalar sample_size = r(sample_size)
	
	local retlist citl se_citl lb_citl ub_citl citlciwidth cslope se_cslope lb_cslope ub_cslope csciwidth rsquared se_rsq lb_rsq ub_rsq rsqciwidth
	foreach s of local retlist {
		ret sca `s' = r(`s')
		}
	
	mat def continuous_val_samp_size_results = r(results)
	return mat results = continuous_val_samp_size_results
	
	if "`print'"!="noprint" {
		criteria_print, type("`type'") 
	}
	}
	else {
		di as err "Model type must be either b or c (binary/continuous)"
		error 499
		}
	
	
***********************************************
		
end

******* start of binary
program define binary_val_samp_size, rclass

version 12.1

/* Syntax
	PREVALENCE = prevalence of outcome 
	CSTATistic = anticipated c statistic at validation
	OE = observed/expected ratio
	OECIwidth = target CI width for OE performance
	CSlope = anticipated calibration slope at validation
	CSCIwidth = target CI width for calibration slope performance
	CSTATCIwidth = target CI width for c statistic performance
	SIMOBS = sets the number of observations to use for simulated LP calculations
	LPNORMal = defines parameters to simulate LP from normal distribution
	LPSKEWednormal = defines parameters to simulate LP from a skewed normal distribution
	LPBETA  = defines parameters to simulate LP from beta distribution
	LPCSTAT = defines starting value for non-events mean  
	TOLerance = sets tolerance for observed event prop. during iterative procedure for non-events mean 
	INCrement = sets increment by which to iterate when identifying mean for non-events for lpcstat()
	OESEINCrement = sets increment by which to iterate when identifying the SE(ln(OE)) to meet the target CI width for OE 
	SEED = sets seed for calculations based on simulated data
	GRAPH = produces histogram of LP dist for checking
	TRACE = Output a trace of iteration procedure for obtaining non-event mean under lpcstat option
	SENSitivity = sensitivity for net benefit 
	SPECificity = specificity for net benefit
	THRESHold = risk threshold for net benefit 
*/

syntax , PREValence(real) CSTATistic(real) ///
			[OE(real 1) OECIwidth(real 0.2) ///
			 CSlope(real 1) CSCIwidth(real 0.2) ///
			 CSTATCIwidth(real 0.1) SIMOBS(int 1000000) ///
			 LPNORMal(numlist max=2) LPSKEWednormal(numlist max=4) ///
			 LPBETA(numlist max=2) LPCSTAT(numlist max=1) /// 
			 TOLerance(real 0.0005) INCrement(real 0.1) OESEINCrement(real 0.0001) ///
			 SEED(int 123456) GRAPH CALCURves TRACE SENSitivity(real 0) ///
			 SPECificity(real 0) THRESHold(real 0) NBCIwidth(real 0.2) NBSEINCrement(real 0.0001)] 

// CHECK INPUTS

if `prevalence'>=0 & `prevalence'<=1 { 
		}
		else {
			di as err "Prevalence must lie in the interval [0,1]"
			error 459
			}
			
if `cstatistic'>=0 & `cstatistic'<=1 { 
		}
		else {
			di as err "C statistic must lie in the interval [0,1]"
			error 459
			}
			
if "`lpnormal'"!="" {
		
		if "`lpskewednormal'"!="" | "`lpbeta'"!="" | "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
	}
	else if "`lpskewednormal'"!="" {
	    
		if "`lpbeta'"!="" | "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
	}
	else if "`lpbeta'"!="" {
	    
		if "`lpcstat'"!="" {
			di as err "Only one LP distribution option can be specified"
			error 103
		}
		
	}
	else if "`lpnormal'"=="" & "`lpskewednormal'"=="" & "`lpbeta'"=="" & "`lpcstat'"=="" {

			di as err "An LP distribution must be specified"
			error 102

	}
			
// SET SEED 
set seed `seed'
 
// CALCULATE N FOR EACH PERFORMANCE STAT CRITERIA 

 // CRITERIA 1 - O/E 
 local width_oe = 0 
 local se_oe = 0
 while `width_oe'<`oeciwidth' {
 	local se_oe = `se_oe'+`oeseincrement'
	local ub_oe = exp(ln(`oe') + (1.96*`se_oe'))
	local lb_oe = exp(ln(`oe') - (1.96*`se_oe'))
	local width_oe = `ub_oe'-`lb_oe'
	//nois di "width=`width_oe' -----lb=`lb_oe'-----ub=`ub_oe'-------se=`se_oe'"
 }

	local n1 = ceil((1-`prevalence')/(`prevalence'*`se_oe'^2))

	local E1 = `n1'*`prevalence'
	
// CRITERIA 2 - CSLOPE
	preserve
	qui drop _all  
	qui set obs `simobs'
	
// parse distribution parameters & generate LP values 
if "`lpskewednormal'"!="" {
		local lpdist "skewednormal"
		tokenize `lpskewednormal' , parse(" ", ",")
		local mean = `1'
		local var = `2'
		local skew = `3'
		local kurtosis = `4'
		
		di as txt "Skewed normal LP distribution with parameters - mean=`mean', variance=`var', skew=`skew', kurtosis=`kurtosis'" _n "Working ..."
		
		qui sknor `simobs' `seed' `lpskewednormal'
		
		qui gen LP = skewnormal
		}
		else if "`lpnormal'"!="" {
		    local lpdist "normal"
			tokenize `lpnormal' , parse(" ", ",")
			local mean = `1'
			local sd = `2'
						
			di as txt "Normal LP distribution with parameters - mean=`mean', standard deviation=`sd'" _n
			
			qui gen LP = rnormal(`mean',`sd')
		}
		else if "`lpbeta'"!="" {
		    local lpdist "beta"
			tokenize `lpbeta' , parse(" ", ",")
			local a = `1'
			local b = `2'
						
			di as txt "Beta P distribution with parameters - alpha=`a', beta=`b'" _n
			
			qui gen P = rbeta(`a',`b')
			qui gen LP = logit(P)
		}
		else if "`lpcstat'"!="" {
		 
			local lpdist "cstat"
			local m2 = `lpcstat'
			local var = 2*(invnorm(`cstatistic')^2)
				
			qui gen outcome = rbinomial(1,`prevalence')
			* non-events group
			qui gen LP = rnormal(`m2', sqrt(`var'))
			* events group mean is non-events group mean + S2 
			qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1

			qui gen P = exp(LP)/(1+exp(LP)) 
			qui gen outcome_test = rbinomial(1,P)
			qui summ outcome_test
						
			local diff = abs(`prevalence' - r(mean))
			
			if "`trace'"=="trace" {
			if `diff'>`tolerance' {
			    di as txt "Proportion of observed outcome events does not match input prevalence" _n "Beginning iterative approach ..." _n
				
				di as txt "-------------------- TRACE ON ---------------------" _n
				
				local n=1
				local diff`n' = `diff'
				local m2 = `m2'+`increment'
																											
				qui replace outcome = rbinomial(1,`prevalence')
				* non-events group
				qui replace LP = rnormal(`m2', sqrt(`var'))
				* events group mean is non-events group mean + S2 
				qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
	
				qui replace P = exp(LP)/(1+exp(LP)) 
				qui replace outcome_test = rbinomial(1,P)
				qui summ outcome_test
								
				local n = `n'+1
				local diff`n' = abs(`prevalence' - r(mean))
	
				if `diff`n''<`diff' {
					
					while `diff`n''>`tolerance' {
					    local m2 = `m2'+`increment'
						//di as txt _c "." _c 
				
						qui replace outcome = rbinomial(1,`prevalence')
						* non-events group
						qui replace LP = rnormal(`m2', sqrt(`var'))
						* events group mean is non-events group mean + S2 
						qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
			
						qui replace P = exp(LP)/(1+exp(LP)) 
						qui replace outcome_test = rbinomial(1,P)
						qui summ outcome_test
												
						local n = `n'+1
						local diff`n' = abs(`prevalence' - r(mean))
						
						di as txt "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence' + Mean in non-event group=`m2'" _n
				
					}
					
				}
				else {
					
					while `diff`n''>`tolerance' {
					    local m2 = `m2'-`increment'
						//di as txt _c "." _c 
				
						qui replace outcome = rbinomial(1,`prevalence')
						* non-events group
						qui replace LP = rnormal(`m2', sqrt(`var'))
						* events group mean is non-events group mean + S2 
						qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
			
						qui replace P = exp(LP)/(1+exp(LP)) 
						qui replace outcome_test = rbinomial(1,P)
						qui summ outcome_test
											
						local n = `n'+1
						local diff`n' = abs(`prevalence' - r(mean))
						
						di as txt "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence' + Mean in non-event group=`m2'" _n
					}
					
				}
				
				di as txt "-------------------- TRACE END ---------------------" _n
				di as txt _n "Proportion of observed outcome events is within tolerance" _n "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence'" _n "Mean in non-event group=`m2'"
				local m2 = `m2'
				}
				else {
				    di as txt "Proportion of observed outcome events is within tolerance" _n "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence'" _n "Mean in non-event group=`m2'" 
					local m2 = `m2'
				}
			}
			else {
				if `diff'>`tolerance' {
			    di as txt "Proportion of observed outcome events does not match input prevalence" _n "Beginning iterative approach ..." _c
				
				local n=1
				local diff`n' = `diff'
				local m2 = `m2'+`increment'
																											
				qui replace outcome = rbinomial(1,`prevalence')
				* non-events group
				qui replace LP = rnormal(`m2', sqrt(`var'))
				* events group mean is non-events group mean + S2 
				qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
	
				qui replace P = exp(LP)/(1+exp(LP)) 
				qui replace outcome_test = rbinomial(1,P)
				qui summ outcome_test
								
				local n = `n'+1
				local diff`n' = abs(`prevalence' - r(mean))
	
				if `diff`n''<`diff' {
					
					while `diff`n''>`tolerance' {
					    local m2 = `m2'+`increment'
						di as txt _c "." _c 
				
						qui replace outcome = rbinomial(1,`prevalence')
						* non-events group
						qui replace LP = rnormal(`m2', sqrt(`var'))
						* events group mean is non-events group mean + S2 
						qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
			
						qui replace P = exp(LP)/(1+exp(LP)) 
						qui replace outcome_test = rbinomial(1,P)
						qui summ outcome_test
												
						local n = `n'+1
						local diff`n' = abs(`prevalence' - r(mean))
					}
					
				}
				else {
					
					while `diff`n''>`tolerance' {
					    local m2 = `m2'-`increment'
						di as txt _c "." _c 
				
						qui replace outcome = rbinomial(1,`prevalence')
						* non-events group
						qui replace LP = rnormal(`m2', sqrt(`var'))
						* events group mean is non-events group mean + S2 
						qui replace LP = rnormal(`m2' + `var', sqrt(`var')) if outcome == 1
			
						qui replace P = exp(LP)/(1+exp(LP)) 
						qui replace outcome_test = rbinomial(1,P)
						qui summ outcome_test
											
						local n = `n'+1
						local diff`n' = abs(`prevalence' - r(mean))
					}
					
				}
				di as txt _n "Proportion of observed outcome events is within tolerance" _n "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence'" _n "Mean in non-event group=`m2'"
				local m2 = `m2'
				}
				else {
				    di as txt "Proportion of observed outcome events is within tolerance" _n "Proportion of outcome events under simulation = `r(mean)' + Target prevalence = `prevalence'" _n "Mean in non-event group=`m2'" 
					local m2 = `m2'
				}
			}
			
			// check C-statistic is correct
			qui pmcstat LP outcome_test
			local simulated_data_cstat = r(cstat)
			
			ret sca non_event_mean = `m2'
			ret sca event_mean = `m2' + `var'
			ret sca common_variance = `var'
			ret sca tolerance = `tolerance'
			ret sca increment = `increment'
			ret sca simulated_data_cstat = `simulated_data_cstat'
			}
		
	// graph option to output a histogram of the LP distribution for checking
	if "`graph'"=="graph" {
		qui su LP, det
		local stats mean sd min max p50 p25 p75 skewness kurtosis 
		foreach r of local stats {
			local `r' : di %4.3f r(`r')
		}
		
		qui hist LP , text(0.01 `min' "Mean = `mean'" "SD = `sd'" "Median = `p50'" "LQ = `p25'" "UQ = `p75'" "Min = `min'" "Max = `max'" "Skewness = `skewness'" "Kurtosis = `kurtosis'", size(small) place(ne) just(left)) name(pmvalss_lp_dist_`lpdist', replace)
	}
	
	* input assumed parameters of calibration model (in future vr these could be options)
	local beta0 = 0
	local beta1 = 1
	
	* caclulate elements of I matrix
	qui gen Borenstein_00 = exp(`beta0' + (`beta1'*LP))/((1+ exp(`beta0' + (`beta1'*LP)))^2)
	qui gen Borenstein_01 = LP*exp(`beta0' + (`beta1'*LP))/((1+ exp(`beta0' + (`beta1'*LP)))^2)
	qui gen Borenstein_11 = LP*LP*exp(`beta0' + (`beta1'*LP))/((1+ exp(`beta0' + (`beta1'*LP)))^2)
	
	qui summ Borenstein_00
	local I_00 = r(mean)

	qui summ Borenstein_01
	local I_01 = r(mean)

	qui summ Borenstein_11
	local I_11 = r(mean)

	
	* calculate SE from input target CI width
	local se_cslope = round(`csciwidth'/(2*1.96),.00001) // SS very sensitive to rounding 
	
	* calculate sample size
	local n2 = ceil(`I_00'/(`se_cslope'*`se_cslope'*((`I_00'*`I_11')-(`I_01'*`I_01'))))
	
	local E2 = `n2'*`prevalence'
	
// CRITERIA 4 - NET BENEFIT
local estimate_nb = `sensitivity'+`specificity'

if `sensitivity'!=0 & `specificity'!=0 & `threshold'!=0 {
	local nb = (`sensitivity'*`prevalence') - ((1-`specificity')*(1-`prevalence')*(`threshold'/(1-`threshold')))
	local standardised_nb = `nb'/`prevalence'

	local w = ((1-`prevalence')/`prevalence')*(`threshold'/(1-`threshold'))
	* target CI width for sNB of 0.2, which corresponds to SE of 0.051

	local width_nb = 0 
	 local se_nb = 0
	 while `width_nb'<`nbciwidth' {
		local se_nb = `se_nb'+`nbseincrement'
		local ub_nb = (`standardised_nb') + (1.96*`se_nb')
		local lb_nb = (`standardised_nb') - (1.96*`se_nb')
		local width_nb = `ub_nb'-`lb_nb'
	// 	nois di "width=`width_nb' -----lb=`lb_nb'-----ub=`ub_nb'-------se=`se_nb'"
	 }
	 
	 local se_nb = round(`se_nb',0.001)

	 * calculate sample size
	local n4 = ceil((1/(`se_nb'^2))*(((`sensitivity'*(1-`sensitivity'))/`prevalence')+(`w'*`w'*`specificity'*(1-`specificity')/(1-`prevalence'))+(`w'*`w'*(1-`specificity')*(1-`specificity')/(`prevalence'*(1-`prevalence')))))

	local no_nb = 0
}
else if `threshold'!=0 {
			qui gen nb_p = exp(LP)/(1+exp(LP)) 
			qui gen nb_outcome = rbinomial(1,nb_p)
			qui gen classification = 0 if nb_p<`threshold'
			qui replace classification = 1 if classification==.
			qui count if classification==1 & nb_outcome==1
			local pos = r(N)
			qui count if classification==0 & nb_outcome==0
			local neg = r(N)
			qui count if nb_outcome==1
			local e = r(N)
			qui count if nb_outcome==0
			local ne = r(N)
			local sensitivity = round(`pos'/`e',0.01)
			local specificity = round(`neg'/`ne',0.01)
			
			local nb = (`sensitivity'*`prevalence') - ((1-`specificity')*(1-`prevalence')*(`threshold'/(1-`threshold')))
	local standardised_nb = `nb'/`prevalence'

	local w = ((1-`prevalence')/`prevalence')*(`threshold'/(1-`threshold'))
	* target CI width for sNB of 0.2, which corresponds to SE of 0.051

	local width_nb = 0 
	 local se_nb = 0
	 while `width_nb'<`nbciwidth' {
		local se_nb = `se_nb'+`nbseincrement'
		local ub_nb = (`standardised_nb') + (1.96*`se_nb')
		local lb_nb = (`standardised_nb') - (1.96*`se_nb')
		local width_nb = `ub_nb'-`lb_nb'
	// 	nois di "width=`width_nb' -----lb=`lb_nb'-----ub=`ub_nb'-------se=`se_nb'"
	 }
	 
	 local se_nb = round(`se_nb',0.001)

	 * calculate sample size
	local n4 = ceil((1/(`se_nb'^2))*(((`sensitivity'*(1-`sensitivity'))/`prevalence')+(`w'*`w'*`specificity'*(1-`specificity')/(1-`prevalence'))+(`w'*`w'*(1-`specificity')*(1-`specificity')/(`prevalence'*(1-`prevalence')))))

	local no_nb = 0
}
else {
	local no_nb = 1
	local nb = 0
	local standardised_nb = 0
	}

** end of criteria 4

// restore following simulation for criteria 2 - c-slope
	
	restore

// CRITERIA 3 - CSTATISTIC
	preserve
	
	qui drop _all  
	qui set obs 1000000
	
	qui gen size = _n
	qui gen se_cstatsq = `cstatistic'*(1-`cstatistic')*(1+(((size/2)-1)*((1-`cstatistic')/(2-`cstatistic'))) +((((size/2)-1)*`cstatistic')/(1+`cstatistic')))/(size*size*`prevalence'*(1-`prevalence'))
	qui gen se_cstat = sqrt(se_cstatsq)
	qui gen CIwidth = 2*1.96*se_cstat 
	* Now identify the sample sizes that give a CIwidth no wider than the desired value
	qui drop if CIwidth>`cstatciwidth'
	* Finally identify the minimum of all these sample sizes
	qui su size
	local n3 = r(min)
	local se_cstat = sqrt(`cstatistic'*(1-`cstatistic')*(1+(((`n3'/2)-1)*((1-`cstatistic')/(2-`cstatistic'))) +((((`n3'/2)-1)*`cstatistic')/(1+`cstatistic')))/(`n3'*`n3'*`prevalence'*(1-`prevalence')))

	local E3 = `n3'*`prevalence'

	restore 
	

 
	
****************************************************** REPORTING

if `no_nb'==1 {
	// MINIMUM N 
local nfinal = max(`n1',`n2',`n3')
local di_perf_1 : di %4.3f `oe'
local di_perf_2 : di %4.3f `cslope'
local di_perf_3 : di %4.3f `cstatistic'
// local di_perf_4 : di %4.3f `standardised_nb'

local di_se_1 : di %4.3f `se_oe'
local di_se_2 : di %4.3f `se_cslope'
local di_se_3 : di %4.3f `se_cstat'
// local di_se_4 : di %4.3f `se_nb'

local di_ci_1 : di %4.3f  `width_oe' //`oeciwidth'
local di_ci_2 : di %4.3f `csciwidth'
local di_ci_3 : di %4.3f `cstatciwidth'
// local di_ci_4 : di %4.3f `nbciwidth'

local di_lb_1 : di %4.3f `lb_oe'
//local di_lb_2 : di %4.3f `lb_cslope'
//local di_lb_3 : di %4.3f `lb_cstat'
local di_ub_1 : di %4.3f `ub_oe'
//local di_ub_2 : di %4.3f `ub_cslope'
//local di_ub_3 : di %4.3f `ub_cstat'


local E_final = `nfinal'*`prevalence'

// RETURN LIST
return scalar sample_size = `nfinal'
return scalar events = `E_final'
return scalar prevalence = `prevalence'
local retlist oe se_oe lb_oe ub_oe width_oe cslope se_cslope csciwidth cstatistic se_cstat cstatciwidth sensitivity specificity threshold standardised_nb nb
foreach s of local retlist {
ret sca `s' = ``s''
}

// OUTPUT TABLE & ASSUMPTIONS
*di as txt _n "NB: Assuming E/O=`di_perf_1' & c-slope=`di_perf_2'"

local res 1 2 3   
matrix Results = J(4,4,.)
local i=0
foreach r of local res {
	local ++i
	matrix Results[`i',1] = `n`r''
	matrix Results[`i',2] = `di_perf_`r''
	matrix Results[`i',3] = `di_se_`r''
	matrix Results[`i',4] = `di_ci_`r''
	}
	mat colnames Results = "Samp_size" "Perf" "SE" "CI width" 
	mat rownames Results = "Criteria 1 - O/E" "Criteria 2 - C-slope" "Criteria 3 - C statistic" "Final SS"
	// alternative more informative criteria names for output table 
// 	mat rownames Results = "1.O/E" "2.C-slope" "3.C statistic" "Final SS"

preserve
clear
qui svmat Results, names(col)
sort Samp_size
local i = 4
matrix Results[`i',1] = Samp_size[3]
matrix Results[`i',2] = Perf[3]
matrix Results[`i',3] = SE[3]
matrix Results[`i',4] = CI[3]
restore

matlist Results,  aligncolnames(r) twidth(30) lines(rowtotal)

return mat results = Results

local di_E_final = ceil(`E_final')
di _n "Minimum sample size required for model validation based on user inputs = `nfinal',"
di "with `di_E_final' events (assuming an outcome prevalence = `prevalence')"

}
else {
	// MINIMUM N 
	local nfinal = max(`n1',`n2',`n3',`n4')
	local di_perf_1 : di %4.3f `oe'
	local di_perf_2 : di %4.3f `cslope'
	local di_perf_3 : di %4.3f `cstatistic'
	local di_perf_4 : di %4.3f `standardised_nb'

	local di_se_1 : di %4.3f `se_oe'
	local di_se_2 : di %4.3f `se_cslope'
	local di_se_3 : di %4.3f `se_cstat'
	local di_se_4 : di %4.3f `se_nb'

	local di_ci_1 : di %4.3f  `width_oe' //`oeciwidth'
	local di_ci_2 : di %4.3f `csciwidth'
	local di_ci_3 : di %4.3f `cstatciwidth'
	local di_ci_4 : di %4.3f `nbciwidth'

	local di_lb_1 : di %4.3f `lb_oe'
	//local di_lb_2 : di %4.3f `lb_cslope'
	//local di_lb_3 : di %4.3f `lb_cstat'
	local di_ub_1 : di %4.3f `ub_oe'
	//local di_ub_2 : di %4.3f `ub_cslope'
	//local di_ub_3 : di %4.3f `ub_cstat'


	local E_final = `nfinal'*`prevalence'

	// RETURN LIST
	return scalar sample_size = `nfinal'
	return scalar events = `E_final'
	return scalar prevalence = `prevalence'
	local retlist oe se_oe lb_oe ub_oe width_oe cslope se_cslope csciwidth cstatistic se_cstat cstatciwidth sensitivity specificity threshold standardised_nb nb
	foreach s of local retlist {
	ret sca `s' = ``s''
	}

	// OUTPUT TABLE & ASSUMPTIONS
	*di as txt _n "NB: Assuming E/O=`di_perf_1' & c-slope=`di_perf_2'"

	local res 1 2 3 4  
	matrix Results = J(5,4,.)
	local i=0
	foreach r of local res {
		local ++i
		matrix Results[`i',1] = `n`r''
		matrix Results[`i',2] = `di_perf_`r''
		matrix Results[`i',3] = `di_se_`r''
		matrix Results[`i',4] = `di_ci_`r''
		}
		mat colnames Results = "Samp_size" "Perf" "SE" "CI width" 
		mat rownames Results = "Criteria 1 - O/E" "Criteria 2 - C-slope" "Criteria 3 - C statistic" "Criteria 4 - St Net Benefit" "Final SS"
		// alternative more informative criteria names for output table 
	// 	mat rownames Results = "1.O/E" "2.C-slope" "3.C statistic" "Final SS"

	preserve
	clear
	qui svmat Results, names(col)
	sort Samp_size
	local i = 5
	matrix Results[`i',1] = Samp_size[4]
	matrix Results[`i',2] = Perf[4]
	matrix Results[`i',3] = SE[4]
	matrix Results[`i',4] = CI[4]
	restore

	matlist Results,  aligncolnames(r) twidth(30) lines(rowtotal)

	return mat results = Results

	local di_E_final = ceil(`E_final')
	di _n "Minimum sample size required for model validation based on user inputs = `nfinal',"
	di "with `di_E_final' events (assuming an outcome prevalence = `prevalence')"
}

end 	

******* end of binary

******* start of continuous
program define continuous_val_samp_size, rclass

version 12.1

/* Syntax
	RSQuared = assumed Rsq performance in validation sample [use adjusted Rsq from previous model development study - must be adjusted]
	VAROBS = anticipated variance of observed values in the validation sample 
	RSQCIwidth = target precision in terms of CI width for Rsq
	CSlope = assumed C-slope performance in validation sample
	CSCIwidth = target precision in terms of CI width for C-slope
	CITL = assumed CITL performance in validation sample
	CITLCIwidth = target precision in terms of CI width for CITL
	MMOE = set MMOE threshold for acceptable precision of residual variance of CITL & C-slope
*/

syntax , RSQuared(real) VAROBS(real) ///
			[RSQCIwidth(real 0.1) /// RSQSE(real 0.0255) /// 
			CSlope(real 1) CSCIwidth(real 0.2) /// CSSE(real 0.051) ///
			CITL(real 0) CITLCIwidth(real 0) /// CITLSE(real 0) ///
			MMOE(real 1.1)]
			
			// RSQVAL(real 0) RSQCAL(real 0) RSQCITL(real 0)] 
// these rsq's would allow users to enter different rsq for each criteria but this should not be the case 

// CHECK INPUTS
	if `rsquared'>=0 & `rsquared'<=1 { 
		}
		else {
			di as err "R-sq must lie in the interval [0,1]"
			error 459
			}
			


	// CRITERIA 1 - PRECISE ESTIMATION OF R2 VALIDATION
	local r2val = `rsquared' 
	local DIr2val : di %4.3f `r2val'
	
	local lb_rsq = `r2val'-(`rsqciwidth'/2)
	local ub_rsq = `r2val'+(`rsqciwidth'/2)
	local se_rsq = round(((`ub_rsq'-`lb_rsq')/3.92),.0001)
		
	local n1 = ceil((4*`r2val'*(1-`r2val')^2)/`se_rsq'^2)

	
	// CRITERIA 2 - PRECISE ESTIMATION OF CITL
	local r2citl = `rsquared'
	
	local lb_citl = `citl'-(`citlciwidth'/2)
	local ub_citl = `citl'+(`citlciwidth'/2)
	local se_citl = round(((`ub_citl'-`lb_citl')/3.92),.0001)
	
	local n2 = ceil((`varobs'*(1-`r2citl'))/`se_citl'^2)

		
	// CRITERIA 3 - PRECISE ESTIMATE OF CALIBRATION SLOPE 
	local r2cal = `rsquared'
	
	local lb_cslope = `cslope'-(`csciwidth'/2)
	local ub_cslope = `cslope'+(`csciwidth'/2)
	local se_cslope = round(((`ub_cslope'-`lb_cslope')/3.92),.0001)
	
	local n3 = ceil(((`cslope'^2*(1-`r2cal'))/(`r2cal'*`se_cslope'^2))+1)

	
	// CRITERIA 4 - PRECISE ESTIMATION OF RESIDUAL VARIANCES
	local n4 = 235
	// delete after here? as N=235 is the necessary N for mmoe=1.1 
	local df = `n4'-1
	local chilow = `df'/(invchi2(`df',0.025))
	local chiupp = (invchi2(`df',0.975))/`df'
	local max = max(`chilow',`chiupp')
	local resvar_mmoe = `max'^.5
	if `resvar_mmoe'>`mmoe' {
		while `resvar_mmoe'>`mmoe' {
			local ++n4
			local df = `n4'-1
			local chilow = `df'/(invchi2(`df',0.025))
			local chiupp = (invchi2(`df',0.975))/`df'
			local max = max(`chilow',`chiupp')
			local resvar_mmoe = `max'^.5
			
				if `resvar_mmoe'<=`mmoe' { 
					local n4 = `n4'
					continue, break
					}
			}
		}
		else {
			local n4 = `n4'
			}
			
// MINIMUM N 
local nfinal = max(`n1',`n2',`n3',`n4')	
local di_perf_1 : di %4.3f `rsquared'
local di_perf_2 : di %4.3f `citl'
local di_perf_3 : di %4.3f `cslope'
local di_perf_4 = .
local di_se_1 : di %4.3f `se_rsq'
local di_se_2 : di %4.3f `se_citl'
local di_se_3 : di %4.3f `se_cslope'
local di_se_4  = .
local di_ci_1 : di %4.3f `rsqciwidth'
local di_ci_2 : di %4.3f `citlciwidth'
local di_ci_3 : di %4.3f `csciwidth'
local di_ci_4  = .
		
// RETURN LIST
return scalar sample_size = `nfinal'
local retlist citl se_citl lb_citl ub_citl citlciwidth cslope se_cslope lb_cslope ub_cslope csciwidth rsquared se_rsq lb_rsq ub_rsq rsqciwidth
foreach s of local retlist {
ret sca `s' = ``s''
}


// OUTPUT TABLE & ASSUMPTIONS
* add lb & ub to output? 
di as txt "NB: Assuming MMOE<=`mmoe' in estimation of residual variances (Criteria 4)"

local res 1 2 3 4 //final 
matrix Results = J(5,4,.)
local i=0
foreach r of local res {
	local ++i
	matrix Results[`i',1] = `n`r''
	matrix Results[`i',2] = `di_perf_`r''
	matrix Results[`i',3] = `di_se_`r''
	matrix Results[`i',4] = `di_ci_`r''
	}
	mat colnames Results = "Samp_size" "Perf" "SE" "CI width" 
	mat rownames Results = "Criteria 1 - Rsq" "Criteria 2 - CITL" "Criteria 3 - C-slope" "Criteria 4 - Residual var" "Final SS"

preserve
clear
qui svmat Results, names(col)
sort Samp_size
local i = 5
matrix Results[`i',1] = Samp_size[4]
matrix Results[`i',2] = Perf[4]
matrix Results[`i',3] = SE[4]
matrix Results[`i',4] = CI[4]
restore

matlist Results,  aligncolnames(r) twidth(30) lines(rowtotal)

return mat results = Results

di _n "Minimum sample size required for model validation based on user inputs = `nfinal'"

end 	

******* end of continuous

******* start of survival

******* end of survival


******* start of program to print criteria info 
program define criteria_print, rclass

version 12.1

/* Syntax
	TYPE = model type 
*/

syntax ,  TYPE(string) [SENSitivity(real 0) SPECificity(real 0) THRESHold(real 0)]

if "`type'"!="c" {
	
	
	if `sensitivity'!=0 & `specificity'!=0 & `threshold'!=0 {
		di _n "Criteria 1 - precise estimation of O/E performance in the validation sample"
			di "Criteria 2 - precise estimation of the calibration slope in the validation sample"
			di "Criteria 3 - precise estimation of the C statistic in the validation sample"
			di "Criteria 4 - precise estimation of the standardised net-benefit in the validation sample"
	}
	else if `threshold'!=0 {
		di _n "Criteria 1 - precise estimation of O/E performance in the validation sample"
			di "Criteria 2 - precise estimation of the calibration slope in the validation sample"
			di "Criteria 3 - precise estimation of the C statistic in the validation sample"
			di "Criteria 4 - precise estimation of the standardised net-benefit in the validation sample"
	}
	else {
		di _n "Criteria 1 - precise estimation of O/E performance in the validation sample"
		di "Criteria 2 - precise estimation of the calibration slope in the validation sample"
		di "Criteria 3 - precise estimation of the C statistic in the validation sample"
	}
			
}
	else {
		di _n "Criteria 1 - precise estimation of R-squared performance in the validation sample"
		di "Criteria 2 - precise estimation of CITL performance in the validation sample"
		di "Criteria 3 - precise estimation of the calibration slope in the validation sample"
		di "Criteria 4 - precise estimation of the residual variances in the validation sample"
	}

end

******* end of criteria_print program



program define pmcstat, rclass

/* Syntax
	VARLIST = A list of two variables, the linear predictor for the model,
			and the event indicator (observed outcome)
	NOPRINT = suppress the onscreen output of performance stats
	MATRIX = specify the name of a matrix storing the performance stats 
*/

syntax varlist(min=1 max=2 numeric) [if] [in], [noPRINT  ///
				MATrix(name local) HANley FASTER]

*********************************************** SETUP/CHECKS
*SET UP TEMPs
tempvar p rank_disc rank2_disc diff_disc inv_outcome rank_cord rank2_cord diff_cord

// check on the if/in statement 
marksample touse
qui count if `touse'
local samp=r(N)
if `r(N)'==0 { 
	di as err "if statement identifies subgroup with no data?"
	error 2000
	}
	
// parse varlist
tokenize `varlist' , parse(" ", ",")
local lp = `"`1'"'
local outcome = `"`2'"'

// generate probabilities
qui gen `p' = exp(`lp')/(1+exp(`lp'))

// run checks on user input variables in varlist
// check if user has input both LP and obs (for binary outcome)
local varcountcheck: word count `varlist'

if `varcountcheck'!=2 {
	di as err "Varlist must contain two variables. Linear predictor values, followed by observed outcomes (binary variable) are required"
	error 102
	}

// check outcome is binary
cap assert `outcome'==0 | `outcome'==1 if `touse'
        if _rc~=0 {
                noi di as err "Event indicator `outcome' must be coded 0 or 1"
                error 450
        }


*********************************************** C-STAT

if "`faster'"=="faster" {
	// check for packages 
	local packs gtools
	foreach pkg of local packs {
		capture which `pkg'
		if _rc==111 {	
			ssc install `pkg'
			}
		}
		
	// discordant pairs
	hashsort `p' `outcome' 		
	qui gen `rank_disc' = _n if `touse'

	hashsort `outcome' `p' `rank_disc'
	qui gen `rank2_disc' = _n if `touse'

	qui gen `diff_disc' = (`rank_disc' - `rank2_disc') if (`outcome'==0) & (`touse')

	// concordant pairs
	qui gen `inv_outcome' = (`outcome'==0)
	hashsort `p' `inv_outcome'
	qui gen `rank_cord' = _n if `touse'

	hashsort `inv_outcome' `p' `rank_cord'
	qui gen `rank2_cord' = _n if `touse'

	qui gen `diff_cord' = (`rank_cord' - `rank2_cord') if `inv_outcome'==0

	// total possible pairs
	qui gstats sum `outcome' if (`outcome'!=.) & (`touse'), meanonly
	local obs = r(N)
	local prev = r(mean)
	local events = r(sum)
	local nonevents = r(N) - r(sum)
	local pairs = `events'*`nonevents'  

	// compute c-stat (allowing for ties)
	qui gstats sum `diff_disc' if `touse'
	local disc = r(sum)
	qui gstats sum `diff_cord' if `touse'
	local cord = r(sum)

	local ties = `pairs'-`disc'-`cord'

	local cstat = (`cord'+(0.5*`ties'))/(`pairs')
	}
	else {
		// discordant pairs
		sort `p' `outcome' 		
		qui gen `rank_disc' = _n if `touse'

		sort `outcome' `p' `rank_disc' 
		qui gen `rank2_disc' = _n if `touse'

		qui gen `diff_disc' = (`rank_disc' - `rank2_disc') if (`outcome'==0) & (`touse')

		// concordant pairs
		qui gen `inv_outcome' = (`outcome'==0)
		sort `p' `inv_outcome' 
		qui gen `rank_cord' = _n if `touse'

		sort `inv_outcome' `p' `rank_cord' 
		qui gen `rank2_cord' = _n if `touse'

		qui gen `diff_cord' = (`rank_cord' - `rank2_cord') if `inv_outcome'==0

		// total possible pairs
		qui su `outcome' if (`outcome'!=.) & (`touse'), meanonly
		local obs = r(N)
		local prev = r(mean)
		local events = r(sum)
		local nonevents = r(N) - r(sum)
		local pairs = `events'*`nonevents'  

		// compute c-stat (allowing for ties)
		qui su `diff_disc' if `touse'
		local disc = r(sum)
		qui su `diff_cord' if `touse'
		local cord = r(sum)

		local ties = `pairs'-`disc'-`cord'

		local cstat = (`cord'+(0.5*`ties'))/(`pairs')
	}
	
***************************************** CI


if "`hanley'"=="" {
	// default use necombe SE formula
	local newcombe_c = `cstat'
	local cstat_se = ((`cstat'*(1-`cstat'))*(1+(((`obs'/2)-1)*((1-`cstat')/(2-`cstat'))) ///
	+((((`obs'/2)-1)*`cstat')/(1+`cstat')))/((`obs'^2)*`prev'*(1-`prev')))^.5
	local cstat_lb = `cstat' - (1.96*`cstat_se')
	local cstat_ub = `cstat' + (1.96*`cstat_se')
}
else {
	// if hanley option set then use hanley SE formula 
	local Q1 = `cstat' / (2 - `cstat')
	local Q2 = 2 * `cstat'^2 / (1 + `cstat')
	local hanley_c = `cstat'
	local cstat_se = sqrt((`cstat' * (1 - `cstat') + (`nonevents' - 1) * (`Q1' - `cstat'^2) + (`events' - 1) * (`Q2' - `cstat'^2)) / (`nonevents' * `events'))
	local cstat_lb = `cstat' - (1.96*`cstat_se')
	local cstat_ub = `cstat' + (1.96*`cstat_se')
}


***************************************** OUTPUT

// Creating matrix of results
local res cstat 

	tempname rmat
	matrix `rmat' = J(1,5,.)
	local i=0
	foreach r of local res {
		local ++i
		matrix `rmat'[`i',1] = `obs'
		matrix `rmat'[`i',2] = ``r''
		matrix `rmat'[`i',3] = ``r'_se'
		matrix `rmat'[`i',4] = ``r'_lb'
		matrix `rmat'[`i',5] = ``r'_ub'

		//local rown "`rown' `r'"
		}
		mat colnames `rmat' = Obs Estimate SE Lower_CI Upper_CI
		mat rownames `rmat' = "C-Statistic" //`rown'

		
// print matrix 
if "`matrix'"!="" {
			matrix `matrix' = `rmat'
			
			//return matrix `matrix' = `rmat' 
			if "`print'"!="noprint" {
				//di as res _n "Discrimination statistics ..."
				matlist `matrix', border(all) //format(%9.3f)
							
				}
				*return matrix `matrix' = `rmat'
			}
			else { 
				if "`print'"!="noprint" {
					//di as res _n "Discrimination statistics ..."
					matlist `rmat', border(all) //format(%9.3f)
							
					}
				*return matrix rmat = `rmat'
				}
				
// Return scalars
local res cstat cord disc ties  obs
 
		foreach r of local res {
			return scalar `r' = ``r''
			}
			
		if "`matrix'"!="" {
		    matrix `matrix' = `rmat'
			return matrix `matrix' = `rmat'
		}
		else {
		    return matrix rmat = `rmat'
		}
		

end

********************************************

