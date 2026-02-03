*!   attcic v1.0.1  31Jan2026

*Section A defines globals and sets warnings
*Section B reads and prepares the data
*Section C computes the CiC, IPW, Manski, and Lee corrections for continuous outcomes
*Section D computes the CiC, IPW, Manski, and Lee corrections for binary outcomes

program attcic, rclass 
	version    14
	syntax     varlist(min=4 max=4) [if], rct(string) ytype(string)   ///
				[breps(integer 200) clustervar(varlist numeric max=1) stratavar(varlist numeric max=1) ipwcov(varlist numeric) yname(string) qreport(string)] 

	display "Let's go!"
	
	marksample touse, novarlist
	local logdate : di %tdCYND daily("$S_DATE", "DMY")
	
*	__________________________________________________________

*#		A) DEFINE GLOBLAS, SET WARNINGS
*	__________________________________________________________

	*  	===============================================
	*		A.1 Defaults Strings and Initial Warnings
	*  ===============================================

	*Store variables in varlist in unique locals: outcome, treatment , id, followup
	gettoken    y rest1: varlist
	gettoken	treatvar rest2: rest1		
	gettoken	idvar postvar : rest2		
	
	*Store the values of the treatment variable in local "treatlevels"
	qui:	   levelsof  `treatvar', local(treatlevels)

	*Store the number of treatment groups (including the control group) in local "ngroups"
	local      ngroups: word count `treatlevels'
	
	
	* Default string for argument yname
	if "`yname'" == "" local yname "Outcome"
	
	
	* Warnings:

	if  wordcount("`varlist'")  != 4 {
		display in red "Error: varlist should include four variables."
		exit
	}
	
			
	qui: count if missing(`idvar') & `touse'==1
	if 	`r(N)'>0 {
		display in red "Error: unit ID cannot have missing values."
		exit
	}

	qui: count if missing(`postvar') & `touse'==1
	if 	`r(N)'>0 {
		display in red "Error: post variable cannot have missing values."
		exit
	}

	qui: count if missing(`treatvar') & `touse'==1
	if 	`r(N)'>0 {
		display in red "Error: treatment variable cannot have missing values."
		exit
	}

	qui: count if `treatvar'==0 & `touse'==1
	if `r(N)'==0 {
		display in red "Error: treatment variable must take the value of zero for the control group."
		exit
	}
	
	if `ngroups' != 2 {
		display in red "Error: treatment variable should only have two values."
		exit		
	}

	qui: count if `postvar'==0 & `touse'==1
	if `r(N)'==0 {
		display in red "Error: post variable must take the value of zero for the baseline."
		exit
	}

	qui: count if `postvar'==1 & `touse'==1
	if `r(N)'==0 {
		display in red "Error: post variable must take the value of one for the follow-up."
		exit
	}
	
	qui: count if  `touse'==1 & (`postvar'!=1 & `postvar'!=0 & `postvar'!=.) 
	if `r(N)'>0 {
		display in red "Error: post variable should take the value of one for the follow-up and zero for the baseline."
		exit
	}

	if  "`clustervar'" != "" {
		qui: count if missing(`clustervar') & `touse'==1
		if 	`r(N)'>0 {
			display in red "Error: cluster variable cannot have missing values."
			exit
		}
	}


	if  "`stratavar'" != "" {
		qui: count if missing(`stratavar') & `touse'==1
		if 	`r(N)'>0 {
			display in red "Error: strata variable cannot have missing values."
			exit
		}
	}

	if "`rct'" == "" | ("`rct'" != "no" & "`rct'" != "yes") {
		display in red "Error: rct option should be either yes or no."
		exit
	}

	if "`ytype'" == "" | ("`ytype'" != "continuous" & "`ytype'" != "binary") {
		display in red "Error: ytype option should be either continuous or binary."
		exit
	}

	qui: duplicates tag `idvar' `postvar',  gen(tag) 
	qui: sum tag
	if `r(mean)' > 0{
		display in red "Warning: the dataset has duplicates based on the variables `idvar' `postvar'."
	}
	drop tag

	

	* ================================================================
	*  		A.2 Define globals with variable names & other parameters
	* ================================================================

	global Y = "`y'"
	/** Specify outcome variable, should be continuous & should not have missing at baseline **/
	global Yname = "`yname'"
	/** Specify the outcome variable name that you want displayed on graphs **/
	global T = "`treatvar'"
	/** Specify treatment variable, must be (T=1) (C=0) variable **/	
	global POST = "`postvar'"
	/** Specify pre/post treatment variable, must be (POST=1) (PRE=0) variable **/	
	global C = "`clustervar'"
	/** Specify variable defining clusters, if data has clustered structure. **/		
	global S = "`stratavar'"
	/** Specify variable defining strata, if data has stratified structure. **/		
	global G = "G"
	/** Specify variable defining 4 groups: TR, CR, TA, CA **/
	global G_TR = "G_TR"
	/** Specify variable defining groups to find counterfactual for treatment-respondent, must have values 11, 10, 1, 0. **/
	global G_CR = "G_CR"
	/** Specify variable defining groups to find counterfactual for control-respondent, must have values 11, 10, 1, 0. **/	
	global G_TA = "G_TA"
	/** Specify variable defining groups to find counterfactual for treatment-attritor, must have values 11, 10, 1, 0. **/
	global G_CA = "G_CA"
	/** Specify variable defining groups to find counterfactual for control-attritor, must have values 11, 10, 1, 0. **/
	global Y_b = "y0"
	/** Specify variable with baseline outcome **/
	global R = "R1"
	/** Specify response at follow-up variable, must be 1/0 variable **/
	global X0  = "`ipwcov'"
	/** Specify additional baseline covariates for ipw corrections **/
	global CiC_output ="`c(pwd)'\corrections_`y'/"	
	/** Specify directory where correction output will be saved**/
	global CiC_output_quantile ="$CiC_output/quantile_analysis/"	
	/** Specify directory where correction output will be saved**/

	
	* =============================================================
	* A.3 Customize file output:
	* - how many bootstrap replications
	* - which quantiles to estimate
	* - new folder where the figures and datasets will be stored
	*==============================================================

	global pct_min = 0.5
	/** Set the minimum quantile to be estimated **/
	global pct_step = 0.5
	/** Set the step between estimated quantiles **/
	global pct_max = 99.5
	/** Set the maximum quantile to the estimated **/
	global pct_nmbr = 1 + ( $pct_max - $pct_min ) / $pct_step
	/** Set number of quantiles **/
	global format = "png"
	/** Define format in which to save graphs. **/

	
	
	*Create new folder in pwd
	capture mkdir  corrections_`y'


	*Create new folder in $CiC_output
	if "`qreport'" == "yes" {
		capture mkdir  "$CiC_output/quantile_analysis"
	}

	

	* ==================================================================
	*	A.4 Pre-define Matrices with Results per Bootstrap Replication
	* ==================================================================

		* Define globals with matrices names
		global dmo                	"Ybar_TR Ybar_CR DMOR CONTROL_MEAN DART"
		global observed         	"TR CR"
		global counterfactual   	"TR CR TA_I TA_II CA_I CA_II"
		global q_effects        	"QTT_R QTU_R QTT_A QTU_A"
		global avg_effects_cic  	"ATE_P4 ATE_P5 ATE_R ATE_A_P4 ATE_A_P5 ATT ATT_R ATT_A ATU ATU_R ATU_A" // Note: ATE_P4= ATE Proposition 4
		global prop_total       	"PROP_T PROP_C PROP_R PROP_A PROP_TR PROP_CR PROP_TA PROP_CA"
		global prop_groups       	"PROP_TR_R PROP_CR_R PROP_TR_T PROP_TA_T PROP_CR_C PROP_CA_C"

		* -----------------
		* Attrition Rates 
		* -----------------
		
		matrix define AttRate_T = J(`breps',1,.) // treatment group
		matrix define AttRate_C = J(`breps',1,.) // control group

		
		* --------------------------------------------------------------	 
		* Proportions for Treatment Effects   
		* Shares that I will use to calculate treatment effects, for each bootstrap replication
		* first bootstrap is original data
		* --------------------------------------------------------------
		
		foreach p in $prop_total $prop_groups {
			matrix define `p' = J(`breps',1,.)
		}
	
	
		* -----------------------------------------
		*  Difference in Mean Outcomes at Follow-Up
		* ------------------------------------------
		
		foreach e in $dmo {
			matrix define `e' = J(`breps',1,.)
		}
		
		
		
		* -----------------------------------------
		*	    CiC Corrections
		* ------------------------------------------
		
		 // Observed outcomes for each quantile (row) & bootstrap (col)
		foreach o in $observed {
			matrix define obsdout_`o' = J($pct_nmbr,`breps'+1,.)
				local counter = 1
				forvalues q = $pct_min($pct_step)$pct_max {
					matrix obsdout_`o'[`counter',1] = `q'
					local counter = `counter' + 1
				}
		}


		// Counterfactual outcomes for each quantile (row) & bootstrap (col)
		foreach c in $counterfactual {
			matrix define cfacout_`c' = J($pct_nmbr,`breps'+1,.)
				local counter = 1
				forvalues q = $pct_min($pct_step)$pct_max {
					matrix cfacout_`c'[`counter',1] = `q'
					local counter = `counter' + 1
				}
		}
	
		//percentage of quantiles on each bootstrap
			//replication that are outside the support of the data
		foreach c in $counterfactual {	
			matrix define pctg_cfacout_`c'=J(`breps',1,0)
		}
		
		
		//Quantile treatment effects for each quantile (row) & bootstrap (col)
		foreach e in $q_effects {
			matrix define `e' = J($pct_nmbr,`breps'+1,.)
				local counter = 1
				forvalues q = $pct_min($pct_step)$pct_max {
					matrix `e'[`counter',1] = `q'
					local counter = `counter' + 1
				}
		}

	
		// Mean observed outcomes for each bootstrap replication
			//first bootstrap is original data
		foreach o in $observed {
			matrix define mean_obsdout_`o' = J(`breps',1,.)
		}
		
		
		// Mean counterfactual outcomes for each bootstrap replication
			//first bootstrap is original data
		foreach c in $counterfactual {
			matrix define mean_cfacout_`c' = J(`breps',1,.)
		}
		
		
		/*Average treatment effects for each bootstrap replication
			first bootstrap is original data*/	
		foreach e in $avg_effects_cic {
			matrix define `e' = J(`breps',1,.)
		}
		

		//Testable Implication
		matrix define TestImp = J(`breps',1,.)
			
			
			
		* -----------------------------------------
		*	    IPW Corrections
		* -----------------------------------------
		
		matrix define ATE_R_IPW = J(`breps',1,.)
		matrix define ATE_IPW = J(`breps',1,.)

*	__________________________________________________________

*#		B)    READ & MANIPULATE DATA 
*	__________________________________________________________
	
	* Generate baseline outcome
	qui gen y_0 		    = $Y if `touse' & $POST==0
	qui bys `idvar': egen y0	= total(y_0), missing
	qui drop y_0


	* Keep sample of obs in "if condition from syntax" holds
		 *& with nonmissing outcome at baseline
	qui keep if `touse' ==1 & $Y_b!=.

	* Generate outcome's response at follow-up
	qui gen R_1 				= cond(($Y!=. & $POST==1),1,0)
	qui bys `idvar': egen R1	    = total(R_1), missing
	qui drop R_1



	* Generate variable that identifies T/R subgroups by period (to be used in CiC corrections)
	
	qui gen 	G_TR=.
	qui replace G_TR= 11 if $T==1 & $R==1 & $POST==1
	qui replace G_TR= 10 if $T==1 & $R==1 & $POST==0
	qui replace G_TR= 1  if $T==0 & $R==1 & $POST==1
	qui replace G_TR= 0  if $T==0 & $R==1 & $POST==0
	
	qui gen 	G_CR=.
	qui replace G_CR= 11 if $T==0 & $R==1 & $POST==1
	qui replace G_CR= 10 if $T==0 & $R==1 & $POST==0
	qui replace G_CR= 1  if $T==1 & $R==1 & $POST==1
	qui replace G_CR= 0  if $T==1 & $R==1 & $POST==0
	
	qui gen 	G_TA=.
	qui replace G_TA= 11 if $T==1 & $R==0 & $POST==1
	qui replace G_TA= 10 if $T==1 & $R==0 & $POST==0
	qui replace G_TA= 1  if $T==1 & $R==1 & $POST==1
	qui replace G_TA= 0  if $T==1 & $R==1 & $POST==0
	
	qui gen 	G_CA=.
	qui replace G_CA= 11 if $T==0 & $R==0 & $POST==1
	qui replace G_CA= 10 if $T==0 & $R==0 & $POST==0
	qui replace G_CA= 1  if $T==0 & $R==1 & $POST==1
	qui replace G_CA= 0  if $T==0 & $R==1 & $POST==0
	
	
	qui gen 	G=.
	qui replace G= 1 if $T==1 & $R==1
	qui replace G= 2 if $T==0 & $R==1
	qui replace G= 3 if $T==1 & $R==0
	qui replace G= 4 if $T==0 & $R==0

	qui compress

* _______________________________________________________________________

*#	 C. ATTRITION CORRECTIONS FOR CONTINUOUS OUTCOME 
* _______________________________________________________________________


if ("`ytype'" == "continuous") {

	forvalues b = 1(1)`breps' {
		
		preserve

		/** Create bootstrap sample, stratifying by group & clustering as needed. **/
		if (`b' > 1) & ("`clustervar'" == "") & ("`stratavar'" == "")  {
				bsample
		}

		if (`b' > 1) & ("`clustervar'" != "") & ("`stratavar'" == "")  {
				bsample, cluster($C)
		}

		if (`b' > 1) & ("`clustervar'" == "") & ("`stratavar'" != "")  {
				bsample, strata($S)
		}

		if (`b' > 1) & ("`clustervar'" != "") & ("`stratavar'" != "")  {
				bsample, strata($S) cluster($C)
		}


	* ================================================================
	*	C.0   COUNTS, ATT RATES, DIFFERENCE MEAN OUTCOMES FOLLOW-UP
	* =================================================================

		* ---------------------------------------------
		*	C.0.1 Record proportions & Attrition Rates
		* ----------------------------------------------

		*Calculate counts
		qui count if $POST==0
		local total = r(N)
		qui count if $T==1 & $POST==0
		local T = r(N)
		qui count if $T==0 & $POST==0
		local C = r(N)
		qui count if $R==1 & $POST==0 
		local R = r(N)
		qui count if $R==0 & $POST==0 
		local A = r(N)
		qui count if $T==0 & $R==1 & $POST==0
		local CR = r(N)
		qui count if $T==1 & $R==1 & $POST==0
		local TR = r(N)
		qui count if $T==0 & $R==0 & $POST==0
		local CA = r(N)
		qui count if $T==1 & $R==0 & $POST==0
		local TA = r(N)
		
		* Proportions from total
		matrix PROP_T[`b',1]  =  `T'/`total'
		matrix PROP_C[`b',1]  =  `C'/`total'
		matrix PROP_R[`b',1]  =  `R'/`total'
		matrix PROP_A[`b',1]  =  `A'/`total'
		matrix PROP_TR[`b',1] =  `TR'/`total'
		matrix PROP_CR[`b',1] =  `CR'/`total'
		matrix PROP_TA[`b',1] =  `TA'/`total'
		matrix PROP_CA[`b',1] =  `CA'/`total'
		

		* Proportions by group
		matrix PROP_TR_R[`b',1] = `TR'/`R'
		matrix PROP_CR_R[`b',1] = `CR'/`R'
		matrix PROP_TR_T[`b',1] = `TR'/`T'
		matrix PROP_TA_T[`b',1] = `TA'/`T'
		matrix PROP_CR_C[`b',1] = `CR'/`C'
		matrix PROP_CA_C[`b',1] = `CA'/`C'

		* Attrition rate treatment group
		qui sum $R if $T==1 & $POST==1
		matrix AttRate_T[`b',1] = 1-r(mean)
			
		* Attrition rate control group
		qui sum $R if $T==0 & $POST==1
		matrix AttRate_C[`b',1] = 1-r(mean)
		
	
		* --------------------------------------------------
		*	C.0.2 Record average follow-up outcome TR and CR
		* --------------------------------------------------
			
		* Follow-up outcome treatment respondents
		qui sum $Y if $T==1 & $R==1 & $POST==1
		matrix Ybar_TR[`b',1] = r(mean)
		
		* Follow-up outcome control respondents
		qui sum $Y if $T==0 & $R==1 & $POST==1
		matrix Ybar_CR[`b',1] = r(mean)
		
		* Difference in mean outcomes at follow-up
		if ("`rct'"=="yes" & "`stratavar'"=="") {
			matrix DMOR[`b',1] = Ybar_TR[`b',1]- Ybar_CR[`b',1]
		}
		
		if ("`rct'"=="yes" & "`stratavar'"!="") {
			qui xi: reg $Y $T i.$S if $POST==1 
			matrix DMOR[`b',1] = _b[$T]
		}
				

		* Control mean at follow-up
		matrix CONTROL_MEAN[`b',1] = Ybar_CR[`b',1]

		* Differential attrition rate
		matrix DART[`b',1] = AttRate_T[`b',1]- AttRate_C[`b',1]


	* ================================================================
	*	C.1   IPW CORRECTIONS FOR EACH BOOTS SAMPLE
	* =================================================================


		* ==============================================
		*	   			Corrected ATE - R
		*	Weighted difference in mean outcomes
		*   Weight = 1/(treat prop score among resp)
		* ==============================================
		
			tempvar treat_pscore 
			tempvar sample_ts
			tempvar ipw_ts
			
		if ("`rct'"=="yes") {
			
		*	A) Estimate treatment propensity score & predict probabilities
			if ( "`stratavar'"=="") {
				qui probit  $T $Y_b $X0 if $R==1 & $POST==1 
				qui predict `treat_pscore' if $POST==1, pr
				qui assert !missing(`treat_pscore') if $POST==1
			}

			if ("`stratavar'"!="") {
				qui xi: probit $T $Y_b  $X0 i.$S if $R==1 & $POST==1 
				qui predict `treat_pscore' if $POST==1, pr
				qui assert !missing(`treat_pscore') if $POST==1
			}
				
	  
		*	B) Flag obs that are in sample for IPW correction
			* Assump: probability is bounded away from 0 and away from 1
			* Following Huber(2012): trim if score <= 5% or >=95%
			qui gen     `sample_ts' = cond(`treat_pscore'> 0.05 & `treat_pscore'<0.95,1,0)
			qui replace `sample_ts' = . if $POST==0
					
			
		*	C) Estimate corrected ATE-R 
			qui generate double `ipw_ts' =  1/`treat_pscore'   if $POST==1 & $T==1    // generate weight based on treat score for treated
			qui replace         `ipw_ts' = 1/(1-`treat_pscore') if $POST==1 & $T==0  // generate weight based on treat score for untreated
			qui reg $Y $T [pw=`ipw_ts'] if `sample_ts' ==1 & $POST==1  // this estimate is consistent but the SE are not

		
		*   D) Save estimator
			matrix ATE_R_IPW[`b',1]  = _b[$T]
			
			
		*	==================================================================
		*						Corrected ATE 
		*	Weighted difference in mean outcomes
		*   Weight = (1/(treat prop score among resp)) * (1/resp prop score)
		*	==================================================================
		
			tempvar resp_pscore
			tempvar sample_rs
			tempvar sample_ipw
			tempvar ipw_all
			
		* 	A) Estimate response propensity score & predict probabilities
			if ( "`stratavar'"=="") {
				qui probit  $R $Y_b $X0 if $POST==1
				qui predict `resp_pscore' if $POST==1, pr
				qui assert !missing(`resp_pscore') if $POST==1
			}

			if ( "`stratavar'"!="") {
				qui xi: probit  $R $Y_b $X0 i.$S if $POST==1
				qui predict `resp_pscore' if $POST==1, pr
				qui assert !missing(`resp_pscore') if $POST==1
			}
		
		*	B) Flag obs that are in sample for IPW correction
			* Ass: probability is bounded away from 0
			* Following Huber(2012): trim if score <= 5%
			qui gen     `sample_rs' = cond(`resp_pscore' > 0.05 & `resp_pscore'<. , 1,0)
			qui replace `sample_rs' = . if $POST==0
			
			
		*	C) Sample: individuals that satisfy both bounding conditions
			qui gen     `sample_ipw' = cond(`sample_ts' == 1 & `sample_rs' ==1,1,0)
			qui replace `sample_ipw' = . if $POST==0
			
			
		*	D) Estimate corrected ATE
			qui gen `ipw_all' = (1 / `resp_pscore')*`ipw_ts'   if $POST==1         // generate final weight for ATEP
			qui reg $Y $T [pw=`ipw_all'] if `sample_ipw'==1 &  $POST==1           // this estimate is consistent but the SE are not

			
		*   E) Save estimator 
			matrix ATE_IPW[`b',1]  = _b[$T]
			

		}

	* ================================================================
	*	C.2   CiC CORRECTED QTEs - ESTIMATION FOR EACH BOOTS SAMPLE
	* =================================================================
	

		* ===============================================
		*	C.2.1     ESTIMATE QTEs
		* ===============================================
		
			
			* ============================================
			*	Record sample size for later normalization
			* ============================================

			** Record size of CR at baseline, used for later normalization**
			qui count if $T==0 & $R==1 & $POST==0
			local tempsize_CR = r(N)
			
			** Record size of TR at baseline, used for later normalization**
			qui count if $T==1 & $R==1 & $POST==0
			local tempsize_TR = r(N)
					
			* ================================================
			*	Obtain observed and counterfactual outcomes
			*             for each quantile
			* ================================================

			/* Open for loop over quantiles */
			local counter = 1
			forvalues q = $pct_min($pct_step)$pct_max {


				* -------------------------------------------
				*	Observed outcomes post-treatment
				* -------------------------------------------
			
				/*Record follow-up outcome value at quantile `q' for TR 
					This is a point on the observed outcome CDF for treatment-respondents*/
				_pctile $Y if $G_TR==11, percentiles(`q')
				matrix obsdout_TR[`counter',`b'+1] = r(r1)
					
					
				/*Record follow-up outcome value at quantile `q' for CR 
					This is a point on the observed outcome CDF for control-respondents*/
				_pctile $Y if $G_CR==11, percentiles(`q')
				matrix obsdout_CR[`counter',`b'+1] = r(r1)

			
				* ------------------------------------------------------
				*	Counterfactual for treatment respondents (TR)
				* ------------------------------------------------------

				/*Record baseline outcome value at quantile `q' for TR*/
				_pctile $Y if $G_TR==10, percentiles(`q')
				local yprime = r(r1)
				
				/* Record baseline outcome quantile at `yprime' for CR*/
				qui count if $Y<=`yprime' & $G_TR==0
					local qprime = 100*r(N)/`tempsize_CR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							CR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.
							This would be a percentage from 0 to 100*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_TR[`b',1] = pctg_cfacout_TR[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for CR. 
								This is a point on the the counterfactual outcome CDF for control-respondents.*/
				else {
					_pctile $Y if $G_TR==1, percentiles(`qprime')
						matrix cfacout_TR[`counter',`b'+1] = r(r1)
				}
		
						
				* -----------------------------------------------------
				*	Counterfactual for control respondents (CR)
				* -----------------------------------------------------

				/*Record baseline outcome value at quantile `q' for CR*/
				_pctile $Y if $G_CR==10, percentiles(`q')
				local yprime = r(r1)
				
				/* Record baseline outcome quantile at `yprime' for TR*/
				qui count if $Y<=`yprime' & $G_CR==0
					local qprime = 100*r(N)/`tempsize_TR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							TR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_CR[`b',1] = pctg_cfacout_CR[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for TR. 
								This is a point on the the counterfactual outcome CDF for treatment-respondents.*/
				else {
					_pctile $Y if $G_CR==1, percentiles(`qprime')
						matrix cfacout_CR[`counter',`b'+1] = r(r1)
				}

				
				* ----------------------------------------------------------------
				*	Counterfactual I for treatment attritors (TA)
				* ----------------------------------------------------------------

		
				/*Record baseline outcome value at quantile `q' for TA*/
				_pctile $Y if $G_TA==10, percentiles(`q')
				local yprime = r(r1)
				
				/* Record baseline outcome quantile at `yprime' for TR*/
				qui count if $Y<=`yprime' & $G_TA==0
					local qprime = 100*r(N)/`tempsize_TR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							TR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_TA_I[`b',1] = pctg_cfacout_TA_I[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for TR. 
								This is a point on the the counterfactual outcome CDF for treatment-respondents.*/
				else {
					_pctile $Y if $G_TA==1, percentiles(`qprime')
						matrix cfacout_TA_I[`counter',`b'+1] = r(r1)
				}
					
				
				* -----------------------------------------------------------------
				*	Counterfactual II for treatment attritors (TA)
				* -----------------------------------------------------------------

		
				/*Record baseline outcome value at quantile `q' for TA*/
				_pctile $Y if $G_TA==10, percentiles(`q')
				local yprime = r(r1)
				
				/* Record baseline outcome quantile at `yprime' for CR*/
				qui count if $Y<=`yprime' & $G_CA==0
					local qprime = 100*r(N)/`tempsize_CR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							CR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_TA_II[`b',1] = pctg_cfacout_TA_II[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for CR. 
								This is a point on the the counterfactual outcome CDF for control-respondents.*/
				else {
					_pctile $Y if $G_CA==1, percentiles(`qprime')
						matrix cfacout_TA_II[`counter',`b'+1] = r(r1)
				}

				* ---------------------------------------------------------------------
				*	Counterfactual I for control attritors (CA)
				* ---------------------------------------------------------------------

				/*Record baseline outcome value at quantile `q' for CA*/
				_pctile $Y if $G_CA==10, percentiles(`q')
				local yprime = r(r1)
				
				
				/* Record baseline outcome quantile at `yprime' for TR*/
				qui count if $Y<=`yprime' & $G_TA==0
					local qprime = 100*r(N)/`tempsize_TR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							TR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_CA_I[`b',1] = pctg_cfacout_CA_I[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for TR. 
								This is a point on the the counterfactual outcome CDF for treatment-respondents.*/
				else {
					_pctile $Y if $G_TA==1, percentiles(`qprime')
						matrix cfacout_CA_I[`counter',`b'+1] = r(r1)
				}

		
				* --------------------------------------------------------------------
				*	Counterfactual II for control attritors (CA)
				* --------------------------------------------------------------------

				/*Record baseline outcome value at quantile `q' for CA*/
				_pctile $Y if $G_CA==10, percentiles(`q')
				local yprime = r(r1)
				
				/* Record baseline outcome quantile at `yprime' for CR*/
				qui count if $Y<=`yprime' & $G_CA==0
					local qprime = 100*r(N)/`tempsize_CR'
				
				/* Display warning message if the baseline outcome quantile at `yprime' for 
							CR is outside the support of the original data,
							as the quantile treatment effect is then not defined at that 
							quantile. Also count the percentage of quantiles on each bootstrap
							replication that are outside the support of the data.*/
				if (`qprime'<=0 | `qprime'>=100) {
					if `b' == 1 {
						display   ///
						"Quantile `q' outside original data support"
					}
					matrix pctg_cfacout_CA_II[`b',1] = pctg_cfacout_CA_II[`b',1] + 100/$pct_nmbr
				}
				
				/*Else: Record follow-up outcome value at quantile `qprime' for CR. 
								This is a point on the the counterfactual outcome CDF for control-respondents.*/
				else {
					_pctile $Y if $G_CA==1, percentiles(`qprime')
						matrix cfacout_CA_II[`counter',`b'+1] = r(r1)
				}
		

			* ================================================
			*	 QTT-R, QTU-R, QTT-Q, QTU-A
			* ================================================		
					
				*----------------------------------------------------------------
				* QTT-R defined as difference between observed CDF for the TR 
				*		in period 1 and counterfactual CDF, which is the observed
				*		CDF for the TR group in period 0 adjusted by the trend
				*		for the CR group between periods 0 and 1. 
				*-----------------------------------------------------------------
				matrix QTT_R[`counter',`b'+1] = obsdout_TR[`counter',`b'+1] - cfacout_TR[`counter',`b'+1]
				
				*----------------------------------------------------------------
				* QTU-R defined as difference between observed CDF for the CR 
				*		in period 1 and counterfactual CDF, which is the observed
				*		CDF for the CR group in period 0 adjusted by the trend
				*		for the TR group between periods 0 and 1. 
				*----------------------------------------------------------------
				matrix QTU_R[`counter',`b'+1] = cfacout_CR[`counter',`b'+1] - obsdout_CR[`counter',`b'+1]  

				*----------------------------------------------------------------------------------
				* QTT-A defined as difference between counterfactual CDF I for the TA 
				*		in period 1 --which is the observed CDF for the TA group in 
				*		period 0 adjusted by the trend for the TR group between periods 0 and 1--
				*		and the counterfactual CDF II for the TA in period 1 --which is the 
				*		observed CDF for the TA group in period 0 adjusted by the trend for
				*		the CR group between periods 0 and 1 
				*------------------------------------------------------------------------------------		
				matrix QTT_A[`counter',`b'+1] = cfacout_TA_I[`counter',`b'+1] - cfacout_TA_II[`counter',`b'+1]

				*---------------------------------------------------------------------------------
				* QTU-A defined as difference between counterfactual CDF I for the CA 
				*		in period 1 --which is the observed CDF for the CA group in 
				*		period 0 adjusted by the trend for the TR group between periods 0 and 1--
				*		and the counterfactual CDF II for the CA in period 1 --which is the 
				*		observed CDF for the CA group in period 0 adjusted by the trend for
				*		the CR group between periods 0 and 1 *
				*----------------------------------------------------------------------------------
				matrix QTU_A[`counter',`b'+1] = cfacout_CA_I[`counter',`b'+1] - cfacout_CA_II[`counter',`b'+1]
			
				local counter = `counter' + 1
			}
			
			
			/** Close for loop over quantiles. **/
		
		* ===============================================================
		*	C.2.2    SAVE REPORT OF ANALYSIS AT QUANTILE LEVEL:
		*		- Observed and coutnerfactual CDFs per group (4 figs)
		*       - Corrected QTEs by group (1 dataset)
		*		- Corrected QTEs across bootstrap samples (4 datasets)
		*       - Corrected QTEs with 95% confidence intervals (4 figs)
		* ===============================================================

		if "`qreport'" == "yes"{


			* --------------------------------------------------------
			*	C.2.2.1  
			*			1) Observed and counterfactual CDFs per group
			*			2) Corrected QTEs by group (1 dataset)		
			* ---------------------------------------------------------

			/** Figures and dataset using original data (first bootstrap loop) **/

			if `b'==1 {

				**Figures: CDFs TR and CR **
				foreach e in $observed {
					clear
					qui set obs $pct_nmbr
					qui svmat double obsdout_`e'
						rename obsdout_`e'1 quantile
						rename obsdout_`e'2 obsdout
					qui svmat double cfacout_`e'
						rename cfacout_`e'2 cfacout
					capture drop obsdout_`e'*
					capture drop cfacout_`e'*

					if "`e'"=="TR" {
						local efull = "Treatment Respondents"
						local ename = "cdfs treatresp"
						
						#delimit ;
						qui graph twoway line quantile obsdout, lcolor(blue) lpattern(solid)
						|| line quantile cfacout, lcolor(red) lpattern(longdash)
						ytitle("Quantiles") xtitle("${Yname}") title("`efull'")
						plotregion(style(none)) graphregion(fcolor(white) lcolor(white))
						yscale(range(0 100)) ylabel(0(20)100) legend(on)
						legend(order(1 "Treated Outcome" 2 "Counterfactual Outcome"));
						qui graph export "${CiC_output_quantile}`ename'.$format", replace;
						#delimit cr
					}
					
					else if "`e'"=="CR" {
						local efull = "Control Respondents"
						local ename = "cdfs controlresp"
						
						#delimit ;
						qui graph twoway line quantile obsdout, lcolor(blue) lpattern(solid)
						|| line quantile cfacout, lcolor(red) lpattern(longdash)
						ytitle("Quantiles") xtitle("${Yname}") title("`efull'")
						plotregion(style(none)) graphregion(fcolor(white) lcolor(white))
						yscale(range(0 100)) ylabel(0(20)100) legend(on)
						legend(order(1 "Untreated outcome" 2 "Counterfactual outcome"));
						qui graph export "${CiC_output_quantile}`ename'.$format", replace;
						#delimit cr
					}

					
				}
				


				** Figures: CDFs TA and CA **
				foreach e in TA CA{
					clear
					qui set obs $pct_nmbr
					qui svmat double cfacout_`e'_I
						rename cfacout_`e'_I1 quantile
						rename cfacout_`e'_I2 cfacout_treated
					qui svmat double cfacout_`e'_II
						rename cfacout_`e'_II2 cfacout_untreated
					capture drop cfacout_`e'_I*
					capture drop cfacout_`e'_II*

					if "`e'"=="TA" {
						local efull = "Treatment Attritors"
						local ename = "cdfs treatatt"
					}
					else if "`e'"=="CA" {
						local efull = "Control Attritors"
						local ename = "cdfs controlatt"
					}

					#delimit ;
					qui graph twoway line quantile cfacout_treated, lcolor(blue) lpattern(solid)
						|| line quantile cfacout_untreated, lcolor(red) lpattern(longdash)
						ytitle("Quantiles") xtitle("${Yname}") title("`efull'")
						plotregion(style(none)) graphregion(fcolor(white) lcolor(white))
						yscale(range(0 100)) ylabel(0(20)100) legend(on)
						legend(order(1 "Counterfac with treatment" 2 "Counterfac w/o treatment"));
					qui graph export "${CiC_output_quantile}`ename'.$format", replace;
					#delimit cr
				}
				

				** Dataset: QTE estimators**
				
				clear
				qui set obs $pct_nmbr
				qui svmat double QTT_R
					rename QTT_R1 quantile
					rename QTT_R2 qtt_r

				qui svmat double QTU_R
					rename QTU_R2 qtu_r

				qui svmat double QTT_A
					rename QTT_A2 qtt_a

				qui svmat double QTU_A
					rename QTU_A2 qtu_a	

				capture drop QT*

				label var qtt_r "quantile treatment effect for treatment respondents"
				label var qtu_r "quantile treatment effect for control respondents"
				label var qtt_a "quantile treatment effect for treatment attritors"
				label var qtu_a "quantile treatment effect for control attritors"


				qui: save "${CiC_output_quantile}qte estimators", replace
				
			}
		}	

	restore
	}
	/** Close loop over bootstrap iterations. **/

			* -------------------------------------------------------------------------------------------
			*	C.2.2.2   
			* 				i) Corrected QTEs across bootstrap samples (4 datasets)
			*       		ii) Corrected QTEs with 95% confidence intervals (4 figs)
			* -------------------------------------------------------------------------------------------
		
	preserve
	
		if "`qreport'" =="yes" {

			*i)
			foreach e in $q_effects {

				if "`e'" == "QTT_R" {
					local efull = "Quantile Treatment Effects for Treatment Respondents"
					local ename = "qtt-r"
				}
				else if "`e'" == "QTU_R" {
					local efull = "Quantile Treatment Effects for Control Respondents"
					local ename = "qtu-r"
				}
				else if "`e'" == "QTT_A" {
					local efull = "Quantile Treatment Effects for Treatment Attritors"
					local ename = "qtt-a"
				}
				else if "`e'" == "QTU_A" {
					local efull = "Quantile Treatment Effects for Control Attritors"
					local ename = "qtu-a"
				}


				/** For each QTE, create a dataset with quantiles as columns and 
						quantile treatment effect estimates for each bootstrap iteration as
						rows. Use this dataset to calculate 95% confidence intervals by taking
						percentiles within each quantile/column. **/
				clear
				/** Generate dataset from matrix of point estimates. **/
				matrix q = `e''
				qui svmat double q
				/** Compute 95% CI over the bootstrap estimates for each quantile. **/	
				matrix sdev = J($pct_nmbr,1,.)
				matrix cilb = J($pct_nmbr,1,.)
				matrix ciub = J($pct_nmbr,1,.)
				forvalues i = 1(1)$pct_nmbr {
					qui summ q`i'
					matrix sdev[`i',1] = r(sd)
					qui _pctile q`i' if _n>2, p(2.5 97.5)
					matrix cilb[`i',1] = r(r1)
					matrix ciub[`i',1] = r(r2)
				}

				/** Save dataset with each QTE across bootstrap samples **/	
				qui save "${CiC_output_quantile}`ename' bootsrap samples", replace
				
				
				**ii)
				/**	Create figure with point estimates and 95% confidence intervals  **/
				clear
				qui svmat double `e'
					rename `e'1 quantile
					rename `e'2 level
					keep quantile level
				qui svmat double cilb
				qui svmat double ciub

				#delimit ;
				qui graph twoway line level quantile, lcolor(blue) lpattern(solid)
						|| line cilb1 quantile, lcolor(blue) lpattern(dot)
						|| line ciub1 quantile, lcolor(blue) lpattern(dot)
					plotregion(style(none)) graphregion(fcolor(white) lcolor(white)) yline(0)
					xtitle("Quantiles") ytitle("${Yname}") title("`efull'") legend(on) legend( 
					order(1 2) lab(1 "Treatment Effect") lab(2 "Bootstrap 95% CI") );
				qui graph export "${CiC_output_quantile}`ename'.$format", replace;
				#delimit cr

			}
		}
			
			
		* ===============================================================
		*	C.2.3    CiC CORRECTED QTEs - SAVE DIAGNOSTIC DATASET 
		*	Note: this dataset contains the percentage of counterfactual outcome 
		* 		quantiles for each model & each replication that fall outside the data support
		* ===============================================================
	
			clear
			qui set obs `breps'
			qui gen boots = _n
			label var boots "Bootstrap sample (boots = 1 is the original data)"

			/** Open loop over counterfactual groups: TR, CR, TA, CA **/
			foreach e in $counterfactual {
				qui svmat double pctg_cfacout_`e'
				rename pctg_cfacout_`e'1 pctg_cfacout_`e'

				if "`e'" == "TR" {
					label var pctg_cfacout_`e' "percentage missing cfactual treatment respondents"
				}
				if "`e'" == "CR" {
					label var pctg_cfacout_`e' "percentage missing cfactual control respondents"
				}
				if "`e'" == "TA_I" {
					label var pctg_cfacout_`e' "percentage missing cfactual treatment attritors with treatment"
				}
				if "`e'" == "TA_II" {
					label var pctg_cfacout_`e' "percentage missing cfactual treatment attritors without treatment"
				}
				if "`e'" == "CA_I" {
					label var pctg_cfacout_`e' "percentage missing cfactual control attritors with treatment"
				}
				if "`e'" == "CA_II" {
					label var pctg_cfacout_`e' "percentage missing cfactual control attritors without treatment"
				}

			}
			/** Close loop over counterfactual groups. **/
			
			qui save "${CiC_output}diagnostic missing quantiles.dta", replace

		


	* ======================================================================
	*	C.3   CiC CORRECTED ATEs - ESTIMATION FOR EACH BOOTSTRAP REPLICATION
	*	Note: Calculate average treatment effects from vector 
	*			of quantile treatment effects
	* =======================================================================
		
		clear
		qui set obs `breps'
		qui gen rep = _n

		* -------------------------------------------------------------
		* Calculate the average observed outcomes for each bootstrap
		* --------------------------------------------------------------

		/** Open loop over groups: TR, CR **/
		foreach o in $observed {

			/** Create dataset with 2Q rows and B columns. Each row corresponds to a
					quantile of the observed outcome CDF (rows 1->Q) or a quantile of the
					counterfactual outcome CDF (rows Q+1->2Q). Each column corresponds to
					a bootstrap replication. So element (q,b) contains the qth quantile of 
					the observed/counterfactual outcome CDF from the bth bootstrap rep. **/

			local lim1 = 1
			local lim2 = $pct_nmbr

			clear
			matrix rep = J($pct_nmbr,`breps',.)
			matrix rep[`lim1', 1] = obsdout_`o'[`lim1'..., 2...]
			qui svmat double rep


			/** Calculate the average outcome from the CDF using disrete Riemann
					integration, again using the fact that the gaps between quantiles
					are all identical. **/
			forvalues b = 1(1)`breps' {

				qui summ rep`b' if _n<=`lim2'
				matrix mean_obsdout_`o'[`b',1] = (r(mean)*r(N)/($pct_nmbr-1)) -   ///
											((r(max)+r(min))/(2*$pct_nmbr-2))
			}
			
		}
		/** Close loop over groups**/
			
				
		* -------------------------------------------------------------------
		* Calculate the average counterfactual outcomes  for each bootstrap
		* --------------------------------------------------------------------

		/** Open loop over groups: TR, CR, TA_I, TA_II, CA_I, CA_II **/
		foreach c in $counterfactual {


			/** Create dataset with 2Q rows and B columns. Each row corresponds to a
					quantile of the observed outcome CDF (rows 1->Q) or a quantile of the
					counterfactual outcome CDF (rows Q+1->2Q). Each column corresponds to
					a bootstrap replication. So element (q,b) contains the qth quantile of 
					the observed/counterfactual outcome CDF from the bth bootstrap rep. **/

			local lim1 = 1
			local lim2 = $pct_nmbr

			clear
			matrix rep = J($pct_nmbr,`breps',.)
			matrix rep[`lim1', 1] = cfacout_`c'[`lim1'..., 2...]
			qui svmat double rep


			/** Calculate the average outcome from the CDF using disrete Riemann
					integration, again using the fact that the gaps between quantiles
					are all identical. **/
			forvalues b = 1(1)`breps' {

				qui summ rep`b' if _n<=`lim2'
				matrix mean_cfacout_`c'[`b',1] = (r(mean)*r(N)/($pct_nmbr-1)) -   ///
											((r(max)+r(min))/(2*$pct_nmbr-2))
			}
			
		}
		/** Close loop over groups**/
				
		
		* ---------------------------------------------------------------
		* Calculate all average treatment effects for each bootstrap
		* ----------------------------------------------------------------
			
		forvalues b = 1(1)`breps' {
			
			// Average treatment effect for treated respondents
			matrix ATT_R[`b',1] =  mean_obsdout_TR[`b',1] - mean_cfacout_TR[`b',1]
			
			// Average treatment effect for untreated respondents
			matrix ATU_R[`b',1] =  mean_cfacout_CR[`b',1] - mean_obsdout_CR[`b',1] 

			// Average treatment effect for treated  attritors
			matrix ATT_A[`b',1] =  mean_cfacout_TA_I[`b',1] - mean_cfacout_TA_II[`b',1]

			// Average treatment effect for untreated attritors
			matrix ATU_A[`b',1] =  mean_cfacout_CA_I[`b',1] - mean_cfacout_CA_II[`b',1]

			// Average treatment effect for treated
			matrix ATT[`b',1] = (ATT_R[`b',1]*PROP_TR_T[`b',1]) + (ATT_A[`b',1]*PROP_TA_T[`b',1])

			// Average treatment effect for untreated
			matrix ATU[`b',1] = (ATU_R[`b',1]*PROP_CR_C[`b',1]) + (ATU_A[`b',1]*PROP_CA_C[`b',1])

			// Average treatment effect for respondents
			matrix ATE_R[`b',1]  = (PROP_TR_R[`b',1]*ATT_R[`b',1])+ (PROP_CR_R[`b',1]*ATU_R[`b',1])

			// Average treatment effect for study population - w/o random treatment assignment (Proposition 4 in paper)
			matrix ATE_P4[`b',1] = (PROP_TR[`b',1]*ATT_R[`b',1]) + (PROP_TA[`b',1]*ATT_A[`b',1]) + (PROP_CR[`b',1]*ATU_R[`b',1]) ///
									+ (PROP_CA[`b',1]*ATU_A[`b',1])

			// Average treatment effect for study population - under random treatment assignment (Proposition 5 in paper)
			matrix ATE_P5[`b',1]  = (PROP_TR_T[`b',1]*mean_obsdout_TR[`b',1]) + (PROP_TA_T[`b',1]*mean_cfacout_TA_I[`b',1]) ///
												- (PROP_CR_C[`b',1]*mean_obsdout_CR[`b',1]) - (PROP_CA_C[`b',1]*mean_cfacout_CA_II[`b',1]) 
									
			// Average treatment effect for attritors (using proposition P4 to find ATE)
			matrix ATE_A_P4[`b',1]  =  (ATE_P4[`b',1] - (PROP_R[`b',1]*ATE_R[`b',1]))/PROP_A[`b',1]
			
			// Average treatment effect for attritors (using proposition P5 to find ATE)
			matrix ATE_A_P5[`b',1]  =  (ATE_P5[`b',1] - (PROP_R[`b',1]*ATE_R[`b',1]))/PROP_A[`b',1]

		}
	

	* =========================================================================
	*	C.4   CiC CORRECTED ATEs - TESTABLE IMPLICATION UNDER RANDOM ASSIGNMENT
	*	Note: ATT = ATU (remark 2 in the paper)
	* ===========================================================================
	
	forvalues b = 1(1)`breps' {
		matrix TestImp[`b',1] = ATT[`b',1] - ATU[`b',1]
	}
	

	* ===============================================================================
	*	C.5   CORRECTED ATEs - SAVE DATASET WITH ATEs FOR EACH BOOTS REPLICATION
	* ===============================================================================	
					
		clear
		qui set obs `breps'
		qui gen boots = _n
		label var boots "Bootstrap sample (boots = 1 is the original data)"

		
		* If Full or Cluster RCT --> report ATE - Prop 5 (using R.A.)
		if ("`rct'"=="yes" & "`stratavar'"=="") {
			matrix ESTIMATORS = ATE_P5, ATE_R,  ///
								ATT, ATT_R, ///
								ATU, ATU_R, ///
								TestImp, ///
								PROP_TR, PROP_TA,  PROP_CR, PROP_CA, ///
								PROP_TR_T, PROP_TA_T,  PROP_CR_C, PROP_CA_C, ///
								DMOR,  ///
								ATE_R_IPW, ATE_IPW , PROP_TR_R, PROP_CR_R
								
								
								
			svmat  double ESTIMATORS
			rename ESTIMATORS1   cic_ate
			rename ESTIMATORS2   cic_ate_r
			rename ESTIMATORS3   cic_att
			rename ESTIMATORS4   cic_att_r
			rename ESTIMATORS5   cic_atu
			rename ESTIMATORS6   cic_atu_r
			rename ESTIMATORS7   cic_testimp
			rename ESTIMATORS8   prop_tr
			rename ESTIMATORS9   prop_ta
			rename ESTIMATORS10  prop_cr
			rename ESTIMATORS11  prop_ca
			rename ESTIMATORS12  prop_tr_t
			rename ESTIMATORS13  prop_ta_t
			rename ESTIMATORS14  prop_cr_c
			rename ESTIMATORS15  prop_ca_c
			rename ESTIMATORS16  naive
			rename ESTIMATORS17  ipw_ate_r
			rename ESTIMATORS18  ipw_ate
			rename ESTIMATORS19  prop_tr_r
			rename ESTIMATORS20  prop_cr_r
		}	

		* If Stratified RCT --> report ATE - Prop 4 (w/o using R.A.)
		if ("`rct'"=="yes" & "`stratavar'"!="" ) {
			matrix ESTIMATORS = ATE_P4, ATE_R,  ///
								ATT, ATT_R, ///
								ATU, ATU_R, ///
								PROP_TR, PROP_TA,  PROP_CR, PROP_CA, ///
								PROP_TR_T, PROP_TA_T,  PROP_CR_C, PROP_CA_C, ///
								DMOR, ///
								ATE_R_IPW, ATE_IPW, PROP_TR_R, PROP_CR_R
								
			svmat  double ESTIMATORS
			rename ESTIMATORS1   cic_ate
			rename ESTIMATORS2   cic_ate_r
			rename ESTIMATORS3   cic_att
			rename ESTIMATORS4   cic_att_r
			rename ESTIMATORS5   cic_atu
			rename ESTIMATORS6   cic_atu_r			
			rename ESTIMATORS7   prop_tr
			rename ESTIMATORS8   prop_ta
			rename ESTIMATORS9   prop_cr
			rename ESTIMATORS10  prop_ca
			rename ESTIMATORS11  prop_tr_t
			rename ESTIMATORS12  prop_ta_t
			rename ESTIMATORS13  prop_cr_c
			rename ESTIMATORS14  prop_ca_c
			rename ESTIMATORS15  naive
			rename ESTIMATORS16  ipw_ate_r
			rename ESTIMATORS17  ipw_ate
			rename ESTIMATORS18  prop_tr_r
			rename ESTIMATORS19  prop_cr_r

		}	


		* If No RCT --> report ATE - Prop 4 (w/o using R.A.)
		if ("`rct'"=="no") {
			
			display "ACAAAAAA"
			matrix ESTIMATORS = ATE_P4, ATE_R,  ///
								ATT, ATT_R, ///
								ATU, ATU_R,  ///
								PROP_TR, PROP_TA,  PROP_CR, PROP_CA, ///
								PROP_TR_T, PROP_TA_T,  PROP_CR_C, PROP_CA_C 
								
			svmat  double ESTIMATORS
			rename ESTIMATORS1   cic_ate
			rename ESTIMATORS2   cic_ate_r
			rename ESTIMATORS3   cic_att
			rename ESTIMATORS4   cic_att_r
			rename ESTIMATORS5   cic_atu
			rename ESTIMATORS6   cic_atu_r			
			rename ESTIMATORS7   prop_tr
			rename ESTIMATORS8   prop_ta
			rename ESTIMATORS9   prop_cr
			rename ESTIMATORS10  prop_ca
			rename ESTIMATORS11  prop_tr_t
			rename ESTIMATORS12  prop_ta_t
			rename ESTIMATORS13  prop_cr_c
			rename ESTIMATORS14  prop_ca_c
		}	

		label var  cic_ate			"CiC corrected ATE"
		label var  cic_ate_r		"CiC corrected ATE-R"
		label var  cic_att          "CiC corrected ATT"
		label var  cic_att_r        "CiC corrected ATT-R"
		label var  cic_atu          "CiC corrected ATU"
		label var  cic_atu_r        "CiC corrected ATU-R"
		label var  prop_tr      	"proportion treatment respondents"
		label var  prop_ta      	"proportion treatment attritors"
		label var  prop_cr      	"proportion control respondents"
		label var  prop_ca      	"proportion control attritors"
		label var  prop_tr_t    	"proportion respondents among treated"
		label var  prop_ta_t   		"proportion attritors among treated"
		label var  prop_cr_c    	"proportion respondents among control"
		label var  prop_ca_c    	"proportion attritors among control"
		cap: label var  prop_tr_r    	"proportion treated among respondents"
		cap: label var  prop_cr_r    	"proportion control among respondents"
		cap: label var  cic_testimp "testable implication (remark 2)"
		cap: label var naive     	"difference in mean outcomes among respondents"
		cap: label var ipw_ate_r    "IPW corrected ATE-R"
		cap: label var ipw_ate      "IPW corrected ATE"

		
		
		qui save "${CiC_output}ate estimators bootstrap samples.dta", replace
	restore
	
	
	
	* ================================================
	*	C.6   MANSKI BOUNDS FOR ORIGINAL SAMPLE
	*
	*   Note: These bounds identify the ATE-R and ATE
	* =================================================
	
		* --------------------------
		* Mean Outcome at Follow-Up
		* --------------------------

		// E[Y1| TR]
		qui sum 	$Y if $T==1 & $R==1 & $POST==1
		local  mu_tr = r(mean)
				
		// E[Y1| CR]
		qui sum 	$Y if $T==0 & $R==1 & $POST==1
		local  mu_cr = r(mean)
		
		
		
		* -------------------------
		* 	BOUNDS FOR ATE-R
		* -------------------------
		
		// Highest and lowest outcome in sample at follow-up
		qui sum $Y if $POST==1 & $R==1, detail
		local high = r(max)
		local low  = r(min)
		
		// Upper Bound: best case scenario (impute highest value)
		local ATE_R_MANSKI_UB = (`mu_tr'*PROP_TR_R[1,1] ) + (`high'*PROP_CR_R[1,1] )   ///
							- (`low'*PROP_TR_R[1,1] ) - (`mu_cr'*PROP_CR_R[1,1] ) 
							

		
								
		// Lower Bound: worst case scenario (impute lowest value)
		local ATE_R_MANSKI_LB = (`mu_tr'*PROP_TR_R[1,1] ) + (`low'*PROP_CR_R[1,1] )   ///
							- (`high'*PROP_TR_R[1,1] ) - (`mu_cr'*PROP_CR_R[1,1] ) 
							
					
							
		* -------------------------
		* 	BOUNDS FOR ATE 
		* -------------------------
		
		// Highest and lowest outcome in sample
		qui sum $Y if $POST==1, detail
		local high = r(max)
		local low  = r(min)
			
		
		* If Full or Cluster RCT --> use random assignment to simplify identification:
		
		if ("`rct'"=="yes" & "`stratavar'"=="") {

			// best case scenario  ( upper bound)
			local ATE_MANSKI_UB = (`mu_tr'*PROP_TR_T[1,1] ) + (`high'*PROP_TA_T[1,1] ) ///
								- (`mu_cr'*PROP_CR_C[1,1] ) - (`low'*PROP_CA_C[1,1] )
									
			

			// worst case scenario ( lower bound)
			local ATE_MANSKI_LB = (`mu_tr'*PROP_TR_T[1,1] ) + (`low'*PROP_TA_T[1,1] ) ///
								- (`mu_cr'*PROP_CR_C[1,1] ) - (`high'*PROP_CA_C[1,1] )
								
			}
								

		
		* If Stratified RCT or No RCT --> use full identification equation 
		
		if ("`rct'"=="yes" & "`stratavar'"!="") | ("`rct'"=="no") {

			// best case scenario ( upper bound)
			local ATE_MANSKI_UB = (`mu_tr'*PROP_TR[1,1] ) + (`high'*PROP_CR[1,1] ) + (`high'*PROP_TA[1,1] ) + (`high'*PROP_CA[1,1] )  ///
							- (`low'*PROP_TR[1,1] ) - (`mu_cr'*PROP_CR[1,1] ) - (`low'*PROP_TA[1,1] ) - (`low'*PROP_CA[1,1])
								
			local ATE_MANSKI_UB: display %4.3f `ATE_MANSKI_UB'
				
			// worst case scenario  ( lower bound)
			local ATE_MANSKI_LB  = (`mu_tr'*PROP_TR[1,1] ) + (`low'*PROP_CR[1,1] ) + (`low'*PROP_TA[1,1] ) + (`low'*PROP_CA[1,1] )  ///
							- (`high'*PROP_TR[1,1] ) - (`mu_cr'*PROP_CR[1,1] ) - (`high'*PROP_TA[1,1] ) - (`high'*PROP_CA[1,1] )
		
			local ATE_MANSKI_LB: display %4.3f `ATE_MANSKI_LB'

		}

	
	
	
	* =============================================
	*	C.7   LEE BOUNDS FOR ORIGINAL SAMPLE
	*
	*   Note: These bounds identify the ATE 
	*		for Always Responders, a subset of the
	*		subpopulation of respondents.
	*      No baseline variables included
	* ==============================================
	
		qui leebounds $Y $T if $POST==1 , select($R)
		qui ereturn list
		qui mat leebounds = e(b)
		local LEE_LB = leebounds[1,1]
		local LEE_UB = leebounds[1,2]

	
	
	* =====================================================
	*	C.8   DISPLAYING  AND EXPORTING CORRECTION OUTPUT
	* =====================================================

			
		if ("`rct'"=="yes") & "`stratavar'"=="" { // FULLY OR CLUSTER RANDOMIZATION 
			
			* -------------------------
			* 	MATRIX 1: CORRECTIONS
			* -------------------------
			
			qui clear
			qui use "${CiC_output}ate estimators bootstrap samples.dta", clear
			
			matrix corrections = J(10,4,.)
			
			* Naive estimators
			qui summ  naive if _n==1
			matrix corrections[1,1]= r(mean)  // ATE (coeff)
			qui summ  naive if _n>1
			matrix corrections[2,1]= r(sd)  // ATE  (boots SE)
			
			qui summ  naive if _n==1
			matrix corrections[1,2]= r(mean)  // ATE-R (coeff)
			qui summ  naive if _n>1
			matrix corrections[2,2]= r(sd)  // ATE-R (boots SE)
			
			
			* CiC estimators
			qui summ  cic_ate if _n==1
			matrix corrections[3,1]= r(mean)  // ATE (coeff)
			qui summ  cic_ate  if _n>1
			matrix corrections[4,1]= r(sd)  // ATE   (boots SE)
			
			qui summ  cic_ate_r if _n==1
			matrix corrections[3,2]= r(mean)  // ATE-R  (coeff)
			qui summ  cic_ate_r if _n>1
			matrix corrections[4,2]= r(sd)  // ATE-R   (boots SE)
			
			qui summ  cic_att_r if _n==1
			matrix corrections[3,3]= r(mean)  // ATT-R (coeff)
			qui summ  cic_att_r if _n>1
			matrix corrections[4,3]= r(sd)  // ATT-R  (boots SE)
			
			* IPW estimators
			qui summ  ipw_ate if _n==1
			matrix corrections[5,1]= r(mean)  // ATE  (coeff)
			qui summ  ipw_ate if _n>1
			matrix corrections[6,1]= r(sd)  // ATE   (boots SE)
			
			qui summ  ipw_ate_r if _n==1
			matrix corrections[5,2]= r(mean)  // ATE-R (coeff)
			qui summ  ipw_ate_r if _n>1
			matrix corrections[6,2]= r(sd)  // ATE-R (boots SE)
			
			*Manski bounds
						
			matrix corrections[7,1]= `ATE_MANSKI_LB' // ATE  
			matrix corrections[8,1]= `ATE_MANSKI_UB'
			
			matrix corrections[7,2]= `ATE_R_MANSKI_LB'  // ATE-R 
			matrix corrections[8,2]= `ATE_R_MANSKI_UB'
			
			
			*Lee bounds
			matrix corrections[9,4]= `LEE_LB'  // ATE-AR 
			matrix corrections[10,4]= `LEE_UB'
			

	
			* ---------------------------------
			* 	MATRIX 2: TESTABLE IMPLICATION
			*	  (REMARK 2 in PAPER)
			* ----------------------------------
			matrix testable = J(2,3,.)
			
			
			qui summ  cic_att if _n==1
			matrix  testable[1,1]= r(mean)  //ATT (coeff)
			qui summ  cic_att if _n>1
			matrix  testable[2,1]= r(sd)  //ATT  (boots SE)
			
			qui summ  cic_atu if _n==1
			matrix  testable[1,2]= r(mean)  //ATU (coeff)
			qui summ  cic_atu if _n>1
			matrix  testable[2,2]= r(sd)  //ATU (boots SE)
			
			
			qui summ  cic_testimp if _n==1
			matrix  testable[1,3]= r(mean)  //ATT-ATU (coeff)
			qui summ  cic_testimp  if _n>1
			matrix  testable[2,3]= r(sd)  //ATT-ATU  (boots SE)
			
			
			* -----------------------------------------
			* 	MATRIX 3: DIAGNOSTIC MISSING QUANTILES 
			* -----------------------------------------
			
			matrix diagnostics = J(6,1,.)
			
			qui use "${CiC_output}diagnostic missing quantiles.dta",clear
			qui sum pctg_cfacout_TR if _n==1
			matrix diagnostics[1,1]=r(mean)
			
			qui sum pctg_cfacout_CR if _n==1
			matrix diagnostics[2,1]=r(mean)
			
			qui sum pctg_cfacout_TA_I if _n==1
			matrix diagnostics[3,1]=r(mean)

			qui sum pctg_cfacout_TA_II if _n==1
			matrix diagnostics[4,1]=r(mean)
			
			qui sum pctg_cfacout_CA_I if _n==1
			matrix diagnostics[5,1]=r(mean)	

			qui sum pctg_cfacout_CA_II if _n==1
			matrix diagnostics[6,1]=r(mean)	
			
			
			* -------------------------------------			
			*	 DISPLAY AND EXPORT TO LATEX
			* -------------------------------------
		
			
			* Table 1: text/tab format
			esttab matrix(corrections) using "${CiC_output}correction_results.tab" , replace nomtitles ///
			type ///
			title("Table 1. Attrition Corrections") ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE" r3 "   Coefficient" r4 "   Boots SE" r5 "   Coefficient" r6 "   Boots SE" ///
			r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
			collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
			refcat(r1 "Naive Estimator" r3 "CiC Corrections" r5 "IPW Corrections" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
			"The CiC-corrected ATE is computed using Proposition 5 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See the help file for more details." ///
			"")	

			* Table 2: text/tab format
			esttab matrix(testable) using "${CiC_output}correction_results.tab" , append nomtitles ///
			type ///
			title("Table 2. Testing CiC Assumptions under Random Assignment") ///
			varlabels(r1 "Coefficient" r2 "Boots SE") ///
			collabels("CiC ATT"  "CiC ATU"  "CiC ATT- CiC ATU") ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the results of the testable implication (Remark 2) in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See help file for more details." ///
			"")		
			

			* Table 3: text/tab format
			esttab matrix(diagnostics) using "${CiC_output}correction_results.tab" , append nomtitles ///
			type ///
			title("Table 3. Support Assumption Diagnostics for CiC Corrections") ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")		
			

									
			* Table 1: tex format
			qui esttab matrix(corrections) using "${CiC_output}correction_results.tex" , replace nomtitles ///
			title("Table 1. Attrition Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE" r3 "   Coefficient" r4 "   Boots SE" r5 "   Coefficient" r6 "   Boots SE" ///
			r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
			collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
			refcat(r1 "Naive Estimator" r3 "CiC Corrections" r5 "IPW Corrections" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
			"The CiC-corrected ATE is computed using Proposition 5 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See the help file for more details." ///
			"")	
			
			* Table 2: tex format
			qui esttab matrix(testable) using "${CiC_output}correction_results.tex" , append nomtitles ///
			type ///
			title("Table 2. Testing CiC Assumptions under Random Assignment") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "Coefficient" r2 "Boots SE") ///
			collabels("CiC ATT"  "CiC ATU"  "CiC ATT- CiC ATU") ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the results of the testable implication (Remark 2) in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See the help file for more details." ///
			"")		
			

			* Table 3: tex format
			qui esttab matrix(diagnostics) using "${CiC_output}correction_results.tex" , append nomtitles ///
			title("Table 3. Support Assumption Diagnostics for CiC Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")	
									
		}
			
		
		if ("`rct'"=="yes") & "`stratavar'"!="" {  // STRATIFIED RANDOMIZATION 
			
			* -------------------------
			* 	MATRIX 1: CORRECTIONS
			* -------------------------
			
			qui clear
			qui use "${CiC_output}ate estimators bootstrap samples.dta", clear
			
			matrix corrections = J(10,4,.)
			
			* Naive estimators
			qui summ  naive if _n==1
			matrix corrections[1,1]= r(mean)  // ATE (coeff)
			qui summ  naive if _n>1
			matrix corrections[2,1]= r(sd)  // ATE  (boots SE)
			
			qui summ  naive if _n==1
			matrix corrections[1,2]= r(mean)  // ATE-R (coeff)
			qui summ  naive if _n>1
			matrix corrections[2,2]= r(sd)  // ATE-R (boots SE)
			
			
			* CiC estimators
			qui summ  cic_ate if _n==1
			matrix corrections[3,1]= r(mean)  // ATE (coeff)
			qui summ  cic_ate  if _n>1
			matrix corrections[4,1]= r(sd)  // ATE   (boots SE)
			
			qui summ  cic_ate_r if _n==1
			matrix corrections[3,2]= r(mean)  // ATE-R  (coeff)
			qui summ  cic_ate_r if _n>1
			matrix corrections[4,2]= r(sd)  // ATE-R   (boots SE)
			
			qui summ  cic_att_r if _n==1
			matrix corrections[3,3]= r(mean)  // ATT-R (coeff)
			qui summ  cic_att_r if _n>1
			matrix corrections[4,3]= r(sd)  // ATT-R  (boots SE)
			
			* IPW estimators
			qui summ  ipw_ate if _n==1
			matrix corrections[5,1]= r(mean)  // ATE  (coeff)
			qui summ  ipw_ate if _n>1
			matrix corrections[6,1]= r(sd)  // ATE   (boots SE)
			
			qui summ  ipw_ate_r if _n==1
			matrix corrections[5,2]= r(mean)  // ATE-R (coeff)
			qui summ  ipw_ate_r if _n>1
			matrix corrections[6,2]= r(sd)  // ATE-R (boots SE)
			
			*Manski bounds
						
			matrix corrections[7,1]= `ATE_MANSKI_LB' // ATE  
			matrix corrections[8,1]= `ATE_MANSKI_UB'
			
			matrix corrections[7,2]= `ATE_R_MANSKI_LB'  // ATE-R 
			matrix corrections[8,2]= `ATE_R_MANSKI_UB'
			
			
			*Lee bounds
			matrix corrections[9,4]= `LEE_LB'  // ATE-AR 
			matrix corrections[10,4]= `LEE_UB'
			

				
			
			* -----------------------------------------
			* 	MATRIX 2: DIAGNOSTIC MISSING QUANTILES 
			* -----------------------------------------
			
			matrix diagnostics = J(6,1,.)
			
			qui use "${CiC_output}diagnostic missing quantiles.dta",clear
			qui sum pctg_cfacout_TR if _n==1
			matrix diagnostics[1,1]=r(mean)
			
			qui sum pctg_cfacout_CR if _n==1
			matrix diagnostics[2,1]=r(mean)
			
			qui sum pctg_cfacout_TA_I if _n==1
			matrix diagnostics[3,1]=r(mean)

			qui sum pctg_cfacout_TA_II if _n==1
			matrix diagnostics[4,1]=r(mean)
			
			qui sum pctg_cfacout_CA_I if _n==1
			matrix diagnostics[5,1]=r(mean)	

			qui sum pctg_cfacout_CA_II if _n==1
			matrix diagnostics[6,1]=r(mean)	
			
			
			* -------------------------------------			
			*	 DISPLAY AND EXPORT TO LATEX
			* -------------------------------------

			* Table 1: text/tab format
			esttab matrix(corrections) using "${CiC_output}correction_results.tab" , replace nomtitles ///
			type ///
			title("Table 1. Attrition Corrections") ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE" r3 "   Coefficient" r4 "   Boots SE" r5 "   Coefficient" r6 "   Boots SE" ///
			r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
			collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
			refcat(r1 "Naive Estimator" r3 "CiC Corrections" r5 "IPW Corrections" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
			"The CiC-corrected ATE is computed using Proposition 4 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See the help file for more details." ///
			"")	
			

			* Table 2: text/tab format
			esttab matrix(diagnostics) using "${CiC_output}correction_results.tab" , append nomtitles ///
			type ///
			title("Table 2. Support Assumption Diagnostics for CiC Corrections") ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")		
			

									
			* Table 1: tex format
			qui esttab matrix(corrections) using "${CiC_output}correction_results.tex" , replace nomtitles ///
			title("Table 1. Attrition Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE" r3 "   Coefficient" r4 "   Boots SE" r5 "   Coefficient" r6 "   Boots SE" ///
			r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
			collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
			refcat(r1 "Naive Estimator" r3 "CiC Corrections" r5 "IPW Corrections" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
			"The CiC-corrected ATE is computed using Proposition 4 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See the help file for more details." ///
			"")	
			

			* Table 2: tex format
			qui esttab matrix(diagnostics) using "${CiC_output}correction_results.tex" , append nomtitles ///
			title("Table 2. Support Assumption Diagnostics for CiC Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")	

			
			
		}
			
				

		if ("`rct'"=="no") {    /// NO RCT
	
			* ----------------------------
			*	MATRIX 1: CORRECTIONS
			* ----------------------------
			
			qui clear
			qui use "${CiC_output}ate estimators bootstrap samples.dta", clear
			
			display "Aqui toy 1"
			
			matrix corrections = J(2,3,.)

			* CiC estimators
			qui summ  cic_ate if _n==1
			matrix corrections[1,1]= r(mean)  // ATE (coeff)
			qui summ  cic_ate if _n>1
			matrix corrections[2,1]= r(sd)  // ATE  (boots SE)
			
			qui summ  cic_ate_r if _n==1
			matrix corrections[1,2]= r(mean)  // ATE-R  (coeff)
			qui summ  cic_ate_r if _n>1
			matrix corrections[2,2]= r(sd)  // ATE-R   (boots SE)
			
			qui summ  cic_att_r if _n==1
			matrix corrections[1,3]= r(mean)  // ATT-R (coeff)
			qui summ  cic_att_r  if _n>1
			matrix corrections[2,3]= r(sd)  // ATT-R   (boots SE)
							
			
			* -----------------------------------------
			* 	MATRIX 2: DIAGNOSTIC MISSING QUANTILES 
			*-------------------------------------------
			
			matrix diagnostics = J(6,1,.)
			
			qui use "${CiC_output}diagnostic missing quantiles.dta",clear
			
			display "Aqui toy 2"
			
			qui sum pctg_cfacout_TR if _n==1
			matrix diagnostics[1,1]=r(mean)
			
			qui sum pctg_cfacout_CR if _n==1
			matrix diagnostics[2,1]=r(mean)
			
			qui sum pctg_cfacout_TA_I if _n==1
			matrix diagnostics[3,1]=r(mean)

			qui sum pctg_cfacout_TA_II if _n==1
			matrix diagnostics[4,1]=r(mean)
			
			qui sum pctg_cfacout_CA_I if _n==1
			matrix diagnostics[5,1]=r(mean)	

			qui sum pctg_cfacout_CA_II if _n==1
			matrix diagnostics[6,1]=r(mean)	
			
			* -------------------------------------			
			*			EXPORT TABLES
			* -------------------------------------
			
			* Table 1: text/tab format
			esttab matrix(corrections) using "${CiC_output}correction_results.tab" , replace nomtitles ///
			type ///
			title("Table 1. Attrition Corrections") ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE") ///
			collabels("ATE"  "ATE-R"  "ATT-R") ///
			refcat(r1 "CiC Corrections" , nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the CiC corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), and treated respondents (ATT-R)." ///
			"The CiC-corrected ATE is computed using Proposition 4 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See help file for more details." ///
			"")	
			

			* Table 2: text/tab format
			esttab matrix(diagnostics) using "${CiC_output}correction_results.tab" , append nomtitles ///
			type ///
			title("Table 2. Support Assumption Diagnostics for CiC Corrections") ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")		
			
			
			* Table 1: tex format
			qui esttab matrix(corrections) using "${CiC_output}correction_results.tex" , replace nomtitles ///
			title("Table 1. Attrition Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "   Coefficient" r2 "   Boots SE") ///
			collabels("ATE"  "ATE-R"  "ATT-R") ///
			refcat(r1 "CiC Corrections" , nolab) ///
			varwidth(15)  modelwidth(20) ///
			addnotes("This table reports the CiC corrections of the average treatment effects for the study population (ATE)" ///
			"and the subpopulations of respondents (ATE-R), and treated respondents (ATT-R)." ///
			"The CiC-corrected ATE is computed using Proposition 4 in Ghanem et al. (2024b)." ///
			"Bootstrap standard errors considering the cluster structure of the data when relevant." ///
			"See help file for more details." ///
			"")	
			

			* Table 2: tex format
			qui esttab matrix(diagnostics) using "${CiC_output}correction_results.tex" , append nomtitles ///
			title("Table 2. Support Assumption Diagnostics for CiC Corrections") ///
			substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
			varlabels(r1 "Untreated counterfactual of treated respondents" r2 "Treated counterfactual of control respondents" ///
					r3 "Treated counterfactual of treated attritors" r4 "Untreated counterfactual of treated attritors" ///
					r5 "Treated counterfactual of control attritors" r6 "Untreated counterfactual of control attritors") ///
			collabels("\%", lhs("Quantiles with missing support for estimation of:") ) ///		
			varwidth(50)  modelwidth(15) ///
			addnotes("This table displays the percentage of quantiles with missing support" ///
			"for each counterfactual outcome estimated for the CiC corrections." ///
			"")		
				
		}

qui clear
}
/** Close loop continuous outcome. **/

	
	
* _______________________________________________________________________

*#	 D. ATTRITION CORRECTIONS FOR BINARY OUTCOME
* _______________________________________________________________________


if ("`ytype'" == "binary")  {

	* ========================================================
	*	D.1  DIFFERENCE IN MEAN OUTCOMES - RESPONDENTS
	*
	*  Note: Asymptotic standard errors 
	* =========================================================
	
		** RCT (Full or clustered) **
		if ("`rct'"=="yes" & "`stratavar'"=="")  {
			
			if ("`clustervar'" == "") {
				qui reg $Y $T if $POST==1, r 
				local naive_b  = _b[$T]
				local naive_se = _se[$T]
			}
			
			if ("`clustervar'" != "") {
				qui reg $Y $T if $POST==1, r cl($C)
				local naive_b  = _b[$T]
				local naive_se = _se[$T]
			}
			
		}
		
		
		** Stratified RCT  **
		if ("`rct'"=="yes" & "`stratavar'"!="") {
			
			if ("`clustervar'" == "") {
				qui xi: reg $Y $T i.$S if $POST==1, r 
				local naive_b  = _b[$T]
				local naive_se = _se[$T]
			}
			
			if ("`clustervar'" != "") {
				qui xi: reg $Y $T i.$S if $POST==1, r cl($C)
				local naive_b  = _b[$T]
				local naive_se = _se[$T]
			}
			
		}

	
	* =============================================================
	*	    D.2  IPW CORRECTIONS
	*
	*  One-step GMM procedure to obtain consistent standard errors 
	*  Asymptotic standard errors 
	* ==============================================================
	
		preserve
	
		qui keep if $POST == 1 

		*	------------------------------------------------------------------------
		*								ATE-R
		*	Notes:
		*	- Eq1: treatment pscore. Multiply eq1 by $R to include only respondents 
		*	- Eq2: treat effect eq. Weights =1/p for T, =1/(1-p) for C
		*	------------------------------------------------------------------------
		
		
		** Full or clustered RCT **
		if ("`rct'"=="yes" & "`stratavar'"=="") {
			
			if ("`clustervar'" == "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb: $Y_b $X0 _cons})*($T - normal({xb:}))*$R )/     
					(normal({xb:})*(1-normal({xb:})) )) 
					(eq2: ((1)/(($T*normal({xb:}))+((1-$T)*(1-normal{xb:}))))*($Y - {b0}-{b1}*$T)), 
					instruments(eq1: $Y_b $X0)                               
					instruments(eq2: $T)                                                 
					wmatrix(robust) winitial(identity) twostep nocommonesample ;
				local IPW_ATER_b  = _b[/b1];
				local IPW_ATER_se = _se[/b1];
				#delimit cr	
			}
		
			if ("`clustervar'" != "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb: $Y_b $X0 _cons})*($T - normal({xb:}))*$R )/     
					(normal({xb:})*(1-normal({xb:})) )) 
					(eq2: ((1)/(($T*normal({xb:}))+((1-$T)*(1-normal{xb:}))))*($Y - {b0}-{b1}*$T)), 
					instruments(eq1: $Y_b $X0)                               
					instruments(eq2: $T)                                                 
					wmatrix(cluster `clustervar') winitial(identity) twostep nocommonesample ;
				local IPW_ATER_b  = _b[/b1];
				local IPW_ATER_se = _se[/b1];
				#delimit cr
			}
		}

		** Stratified RCT **
		if ("`rct'"=="yes" & "`stratavar'"!="") {

			if ("`clustervar'" == "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb: $Y_b $X0 i.$S _cons})*($T - normal({xb:}))*$R )/     
					(normal({xb:})*(1-normal({xb:})) )) 
					(eq2: ((1)/(($T*normal({xb:}))+((1-$T)*(1-normal{xb:}))))*($Y - {b0}-{b1}*$T)), 
					instruments(eq1: $Y_b $X0 i.$S)                               
					instruments(eq2: $T)                                                 
					wmatrix(robust) winitial(identity) twostep nocommonesample ;
				local IPW_ATER_b  = _b[/b1];
				local IPW_ATER_se = _se[/b1];
				#delimit cr	
			}
		
			if ("`clustervar'" != "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb: $Y_b $X0 i.$S  _cons})*($T - normal({xb:}))*$R )/     
					(normal({xb:})*(1-normal({xb:})) )) 
					(eq2: ((1)/(($T*normal({xb:}))+((1-$T)*(1-normal{xb:}))))*($Y - {b0}-{b1}*$T)), 
					instruments(eq1: $Y_b $X0 i.$S)                               
					instruments(eq2: $T)                                                 
					wmatrix(cluster `clustervar') winitial(identity) twostep nocommonesample ;
				local IPW_ATER_b  = _b[/b1];
				local IPW_ATER_se = _se[/b1];
				#delimit cr
			}
		}
			
	
		*	------------------------------------------------------------------------
		*								ATE
		*	Notes:
		*	- Eq1: treatment pscore. Multiply eq1 by $R to include only respondents
		*	- Eq2: response pscore
		*	- Eq3: treat effect eq. Weights tps =1/p for T, =1/(1-p) for C
		*	------------------------------------------------------------------------
		
		** Full or clustered RCT **
		if ("`rct'"=="yes" & "`stratavar'"=="") {

			if ("`clustervar'" == "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb1: $Y_b $X0 _cons})*($T- normal({xb1:}))*$R )/     
					(normal({xb1:})*(1-normal({xb1:})) )) 
					(eq2: normalden({xb2: $Y_b $X0 _cons})*($R - normal({xb2:}))/     
					(normal({xb2:})*(1-normal({xb2:})) )) 
					(eq3: ((1)/(($T*normal({xb1:}))+((1-$T)*(1-normal{xb1:}))))*((1)/normal({xb2:}))*($Y - {b1}*$T - {b0})),
					instruments(eq1: $Y_b $X0)                               
					instruments(eq2: $Y_b $X0 )   
					instruments(eq3: $T ) 
					wmatrix(robust) winitial(identity) twostep nocommonesample ;
					local IPW_ATE_b  = _b[/b1];
					local IPW_ATE_se = _se[/b1];
				#delimit cr
			}
			
			if ("`clustervar'" != "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb1: $Y_b $X0 _cons})*($T- normal({xb1:}))*$R )/     
					(normal({xb1:})*(1-normal({xb1:})) )) 
					(eq2: normalden({xb2: $Y_b $X0  _cons})*($R - normal({xb2:}))/     
					(normal({xb2:})*(1-normal({xb2:})) )) 
					(eq3: ((1)/(($T*normal({xb1:}))+((1-$T)*(1-normal{xb1:}))))*((1)/normal({xb2:}))*($Y - {b1}*$T - {b0})),
					instruments(eq1: $Y_b $X0)                               
					instruments(eq2: $Y_b $X0)   
					instruments(eq3: $T ) 
					wmatrix(cluster `clustervar') winitial(identity) twostep nocommonesample ;
					local IPW_ATE_b  = _b[/b1];
					local IPW_ATE_se = _se[/b1];
				#delimit cr
			}
		}

		** Stratified RCT **
		if ("`rct'"=="yes" & "`stratavar'"!="") {

			if ("`clustervar'" == "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb1: $Y_b $X0 i.$S _cons})*($T- normal({xb1:}))*$R )/     
					(normal({xb1:})*(1-normal({xb1:})) )) 
					(eq2: normalden({xb2: $Y_b $X0 i.$S _cons})*($R - normal({xb2:}))/     
					(normal({xb2:})*(1-normal({xb2:})) )) 
					(eq3: ((1)/(($T*normal({xb1:}))+((1-$T)*(1-normal{xb1:}))))*((1)/normal({xb2:}))*($Y - {b1}*$T - {b0})),
					instruments(eq1: $Y_b $X0 i.$S)                               
					instruments(eq2: $Y_b $X0 i.$S )   
					instruments(eq3: $T ) 
					wmatrix(robust) winitial(identity) twostep nocommonesample ;
					local IPW_ATE_b  = _b[/b1];
					local IPW_ATE_se = _se[/b1];
				#delimit cr
			}
			
			if ("`clustervar'" != "") {
				#delimit ;
				qui gmm (eq1: (normalden({xb1: $Y_b $X0 i.$S _cons})*($T- normal({xb1:}))*$R )/     
					(normal({xb1:})*(1-normal({xb1:})) )) 
					(eq2: normalden({xb2: $Y_b $X0 i.$S _cons})*($R - normal({xb2:}))/     
					(normal({xb2:})*(1-normal({xb2:})) )) 
					(eq3: ((1)/(($T*normal({xb1:}))+((1-$T)*(1-normal{xb1:}))))*((1)/normal({xb2:}))*($Y - {b1}*$T - {b0})),
					instruments(eq1: $Y_b $X0 i.$S)                               
					instruments(eq2: $Y_b $X0 i.$S)   
					instruments(eq3: $T ) 
					wmatrix(cluster `clustervar') winitial(identity) twostep nocommonesample ;
					local IPW_ATE_b  = _b[/b1];
					local IPW_ATE_se = _se[/b1];
				#delimit cr
			}
		}

			
		restore
	
	
	* ========================================
	*	    D.3   CiC CORRECTION - BOUNDS
	* ========================================
		
		* -----------------------------------------------------
		*	BOUNDS UNTREATED COUNTERFACTUAL FOR TR
		* -----------------------------------------------------

			// Calculate q as proportion of CR with follow-up outcome = 1 --> q = F_{Y_1 | G=0, R=1}(1)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=0,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=0,R=1}(q)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of TR with baseline outcome <= Finv_q  --> F_{Y_0 | G=1,R=1}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==1) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of TR with baseline outcome <= Finv2_q  --> F_{Y_0 | G=1,R=1}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==1) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			
			// Lower  bound is given by F_{Y_0 | G=1,R=1}(Finv2(q))
			local LB_CFAC_TR =  `F_Finv2_q'
			
			// Upper bound is given by  F_{Y_0 | G=1,R=1}(Finv(q))
			local UB_CFAC_TR =  `F_Finv_q'



		* ----------------------------------------------------
		*	BOUNDS TREATED COUNTERFACTUAL FOR CR
		* ----------------------------------------------------
			
			// Calculate q as proportion of TR with follow-up outcome = 1 --> q = F_{Y_1 | G=1, R=1}(1)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=1,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=1,R=1}(q)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of CR with baseline outcome <= Finv_q  --> F_{Y_0 | G=0,R=1}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==1) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of CR with baseline outcome <= Finv2_q  --> F_{Y_0 | G=0,R=1}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==1) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			
			// Lower bound is given by [F_{Y_0 | G=0,R=1}(Finv2(q))]
			local LB_CFAC_CR = `F_Finv2_q'

			// Upper bound is given by [F_{Y_0 | G=0,R=1}(Finv(q))]
			local UB_CFAC_CR =  `F_Finv_q'


		* -----------------------------------------
		*	BOUNDS TREATED COUNTERFACTUAL FOR TA
		* -----------------------------------------
			
			// Calculate q as proportion of TR with follow-up outcome = 1 --> q = F_{Y_1 | G=1, R=1}(1)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=1,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=1,R=1}(q)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of TA with baseline outcome <= Finv_q  --> F_{Y_0 | G=1,R=0}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==0) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of TA with baseline outcome <= Finv2_q  --> F_{Y_0 | G=1,R=0}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==0) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			
			// Lower bound is given by [ F_{Y_0 | G=1,R=0}(Finv2(q))]
			local LB_TCFAC_TA =  `F_Finv2_q'	

			
			// Upper bound is given by [F_{Y_0 | G=1,R=0}(Finv(q))]
			local UB_TCFAC_TA = `F_Finv_q'


			
			
		* -----------------------------------------------------
		*	BOUNDS UNTREATED COUNTERFACTUAL FOR TA
		* -----------------------------------------------------
			
			// Calculate q as proportion of CR with follow-up outcome = 1 --> q = F_{Y_1 | G=0, R=1}(1)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=0,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=0,R=1}(q)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of TA with baseline outcome <= Finv_q  --> F_{Y_0 | G=1,R=0}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==0) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of TA with baseline outcome <= Finv2_q  --> F_{Y_0 | G=1,R=0}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 1 & $R ==0) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			
			// Lower bound is given by [ F_{Y_0 | G=1,R=0}(Finv2(q))]
			local LB_UCFAC_TA = `F_Finv2_q'

			// Upper bound is given by [F_{Y_0 | G=1,R=0}(Finv(q))]
			local UB_UCFAC_TA = `F_Finv_q'



		* -----------------------------------------
		*	BOUNDS TREATED COUNTERFACTUAL FOR CA
		* -----------------------------------------
			
			// Calculate q as proportion of TR with follow-up outcome = 1 --> q = F_{Y_1 | G=1, R=1}(1)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=1,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=1,R=1}(q)
			qui sum $Y if ($T == 1 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of CA with baseline outcome <= Finv_q  --> F_{Y_0 | G=0,R=0}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==0) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of CA with baseline outcome <= Finv2_q  --> F_{Y_0 | G=0,R=0}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==0) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			
			
			// Lower bound is given by [ F_{Y_0 | G=0,R=0}(Finv2(q))]
			local LB_TCFAC_CA =  `F_Finv2_q'

			// Upper bound is given by [ F_{Y_0 | G=0,R=0}(Finv(q))]
			local UB_TCFAC_CA =  `F_Finv_q'

			

		* -----------------------------------------------------
		*	BOUNDS UNTREATED COUNTERFACTUAL FOR CA
		* -----------------------------------------------------
			
			// Calculate q as proportion of CR with follow-up outcome = 1 --> q = F_{Y_1 | G=0, R=1}(1)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 1)
			local q = r(mean)


			// Obtain 1) Finv_q  (inf) = F^{-1}_{Y_0 | G=0,R=1}(q) 
			//		& 2) Finv2_q (sup) = F^{(-1)}_{Y_0 | G=0,R=1}(q)
			qui sum $Y if ($T == 0 & $R ==1) & ($POST == 0)
			local q_aux = r(mean)

				if `q' > `q_aux' {
					local Finv_q = 1
				}

				if `q' <= `q_aux' {
					local Finv_q = 0
				}

				if `q' >= `q_aux' {
					local Finv2_q = 0
				}

				if `q' < `q_aux' {
					local Finv2_q = -1000
				}
			
			// Calculate proportion of CA with baseline outcome <= Finv_q  --> F_{Y_0 | G=0,R=0}(F^{-1}(q))
			if `Finv_q' == 1 {
				local F_Finv_q = 1
			}

			if `Finv_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==0) & ($POST == 0)
				local F_Finv_q = r(mean)
			}

			// Calculate proportion of CA with baseline outcome <= Finv2_q  --> F_{Y_0 | G=0,R=0}(F^{(-1)}(q))
			if `Finv2_q' == -1000 {
				local F_Finv2_q = 0
			}

			if `Finv2_q' == 0 {
				qui sum $Y if ($T == 0 & $R ==0) & ($POST == 0)
				local F_Finv2_q = r(mean)
			}
			

			// Upper bound is given by [F_{Y_0 | G=0,R=0}(Finv(q))]
			local UB_UCFAC_CA =  `F_Finv_q'

			// Lower bound is given by [ F_{Y_0 | G=0,R=0}(Finv2(q))]
			local LB_UCFAC_CA = `F_Finv2_q'
			

	
		* -----------------------------------------------------
		*	BOUNDS FOR ATT-R: E[Y1|G=1,R=1] - CFACTUAL TR
		* -----------------------------------------------------

			// Observed average outcome for TR at follow-up 
			qui sum $Y if ($T == 1 & $R ==1)  & ($POST == 1) 
			local obs_TR = r(mean)

			// Calculate lower bound
			local LB_ATT_R = `obs_TR' - `UB_CFAC_TR'

			// Calculate upper bound
			local UB_ATT_R = `obs_TR' - `LB_CFAC_TR'

		
		* -----------------------------------------------------
		*	BOUNDS FOR ATU-R: CFACTUAL CR - E[Y1|G=0,R=1]  
		* -----------------------------------------------------

			// Observed average outcome for CR at follow-up 
			qui sum $Y if ($T == 0 & $R ==1)  & ($POST == 1) 
			local obs_CR = r(mean)

			// Calculate lower bound
			local LB_ATU_R =  `LB_CFAC_CR' - `obs_CR'

			// Calculate upper bound
			local UB_ATU_R =  `UB_CFAC_CR' - `obs_CR'

		* --------------------------------------------------------------
		*	BOUNDS FOR ATE-R: P(T=1|R=1)*ATT-R + P(T=0|R=1)*ATU-R
		* ---------------------------------------------------------------

			// Proportion: TR/R
			qui sum $T if ($R ==1)   & ($POST == 1) 
			local prop_TR_R = r(mean)

			// Proportion: CR/R
			local prop_CR_R = 1- `prop_TR_R'

			// Calculate lower bound
			local LB_ATE_R = (`prop_TR_R'*`LB_ATT_R')+ (`prop_CR_R'*`LB_ATU_R')

			// Calculate upper bound
			local UB_ATE_R = (`prop_TR_R'*`UB_ATT_R')+ (`prop_CR_R'*`UB_ATU_R')


        * --------------------------------------------------------------------
		*	BOUNDS FOR ATT-A: TREATED CFAC TA - UNTREATED CFAC TA
		* --------------------------------------------------------------------

		
			// Calculate lower bound
			local LB_ATT_A = `LB_TCFAC_TA' - `UB_UCFAC_TA'

			// Calculate upper bound
			local UB_ATT_A = `UB_TCFAC_TA' - `LB_UCFAC_TA' 

		* -------------------------------------------------------------------
		*	BOUNDS FOR ATU-A: TREATED CFAC CA - UNTREATED CFAC CA
		* -------------------------------------------------------------------


			// Calculate lower bound
			local LB_ATU_A = `LB_TCFAC_CA' - `UB_UCFAC_CA'

			// Calculate upper bound
			local UB_ATU_A = `UB_TCFAC_CA' - `LB_UCFAC_CA' 

		
		* ---------------------------------------------------------------------------------------------------
		*	BOUNDS FOR ATE: 
		*
		*   Full or Cluster Randomization: exploit initial random assignment to simplify identification ATE
		*   ATE = E[Y1|TR]*P(R=1|G=1) +  E[Y1|TA]*P(R=0|G=1) - E[Y1|CR]*P(R=1|G=0) -E[Y1|CA]*P(R=0|G=0)
		* ---------------------------------------------------------------------------------------------------
			
			if ("`rct'"=="yes" & "`stratavar'"=="")  {

				// Proportions: TR/T and TA/T
				qui count if ($Y!=. & $POST ==0) & ($T==1)
				local T= r(N)
				qui count if ($Y!=. & $POST ==0) & ($T==1 & $R==1)
				local prop_TR_T = r(N)/`T'
				qui count if ($Y!=. & $POST ==0) & ($T==1 & $R==0)
				local prop_TA_T = r(N)/`T'
					
				// Proportions: CR/T and CA/T
				qui count if ($Y!=. & $POST ==0) & ($T==0)
				local C= r(N)
				qui count if ($Y!=. & $POST ==0) & ($T==0 & $R==1)
				local prop_CR_C = r(N)/`C'
				qui count if ($Y!=. & $POST ==0) & ($T==0 & $R==0)
				local prop_CA_C = r(N)/`C'	


				// Calculate upper and lower bounds
				local UB_ATE = (`obs_TR'*`prop_TR_T')+(`UB_TCFAC_TA'*`prop_TA_T') ///
							- (`obs_CR'*`prop_CR_C') - (`LB_UCFAC_CA'*`prop_CA_C')
							
							
				local LB_ATE = (`obs_TR'*`prop_TR_T')+(`LB_TCFAC_TA'*`prop_TA_T') ///
							- (`obs_CR'*`prop_CR_C') - (`UB_UCFAC_CA'*`prop_CA_C')
				
				
			}

			
		* -----------------------------------------------------------------------------------------------
		*	BOUNDS FOR ATE: 
		*
		*   Stratified Randomization or No Randomization: can't simplify identification ATE
		*   ATE = P(T=1 & R=1)*ATT-R + P(T=0&R=1)*ATU-R + P(T= & R=0)*ATT-A + P(T=0&R=0)*ATU-A
		* -----------------------------------------------------------------------------------------------
			
			if ("`rct'"=="yes" & "`stratavar'"!="") | ("`rct'"=="no") {

				// N
				qui count if ($Y!=. & $POST ==0)
				local N = r(N)

				// Proportion: TR/N
				qui count if ($Y!=. & $POST ==0) & ($T==1 & $R==1)
				local prop_TR = r(N)/`N'

				// Proportion: CR/N
				qui count if ($Y!=. & $POST ==0) & ($T==0 & $R==1)
				local prop_CR = r(N)/`N'

				// Proportion: TA/N
				qui count if ($Y!=. & $POST ==0) & ($T==1 & $R==0)
				local prop_TA = r(N)/`N'

				// Proportion: CA/N
				qui count if ($Y!=. & $POST ==0) & ($T==0 & $R==0)
				local prop_CA = r(N)/`N'

				// Calculate lower bound
				local LB_ATE = (`prop_TR'*`LB_ATT_R') +(`prop_CR'*`LB_ATU_R') +(`prop_TA'*`LB_ATT_A') +(`prop_CA'*`LB_ATU_A')

				// Calculate upper bound
				local UB_ATE = (`prop_TR'*`UB_ATT_R')+ (`prop_CR'*`UB_ATU_R')+(`prop_TA'*`UB_ATT_A')+ (`prop_CA'*`UB_ATU_A')

			}
	
	* ============================================
	*	    D.4  MANSKI BOUNDS
	*
	*	Note: these bounds identify ATE-R and ATE
	* ============================================

		* --------------------------
		* Mean Outcome at Follow-Up
		* --------------------------

		// E[Y1| TR]
		qui sum 	$Y if $T==1 & $R==1 & $POST==1
		local  mu_tr = r(mean)
				
		// E[Y1| CR]
		qui sum 	$Y if $T==0 & $R==1 & $POST==1
		local  mu_cr = r(mean)
		
		
		
		* -------------------------
		* 	BOUNDS FOR ATE-R
		* -------------------------
		
		// Highest and lowest value of outcome's support 
		local high = 1
		local low  = 0
		
		
		
		// Upper Bound: best case scenario (impute highest value)
		local ATE_R_MANSKI_UB = (`mu_tr'*`prop_TR_R' ) + (`high'*`prop_CR_R' )   ///
							- (`low'*`prop_TR_R' ) - (`mu_cr'*`prop_CR_R' ) 
								
								
		// Lower Bound: worst case scenario (impute lowest value)
		local ATE_R_MANSKI_LB = (`mu_tr'*`prop_TR_R' ) + (`low'*`prop_CR_R' )   ///
							- (`high'*`prop_TR_R' ) - (`mu_cr'*`prop_CR_R' ) 

							
		* -------------------------
		* 	BOUNDS FOR ATE 
		* -------------------------
		
		// Highest and lowest outcome in sample
		local high = 1
		local low  = 0
		
		

		
		// If Full or Cluster RCT --> use random assignment to simplify identification:
		
		if ("`rct'"=="yes" & "`stratavar'"=="") {

			*best case scenario ( upper bound)
			local ATE_MANSKI_UB = (`mu_tr'*`prop_TR_T' ) + (`high'*`prop_TA_T' ) ///
								- (`mu_cr'*`prop_CR_C' ) - (`low'*`prop_CA_C' )
								
								
			*worst case scenario ( lower bound)
			local ATE_MANSKI_LB = (`mu_tr'*`prop_TR_T' ) + (`low'*`prop_TA_T' ) ///
								- (`mu_cr'*`prop_CR_C' ) - (`high'*`prop_CA_C' )
								
		}

		
		// If Stratified RCT or No RCT --> use full identification equation 
		
		if ("`rct'"=="yes" & "`stratavar'"!="") | ("`rct'"=="no") {

			*best case scenario ( upper bound)
			local ATE_MANSKI_UB = (`mu_tr'*`prop_TR' ) + (`high'*`prop_CR' ) + (`high'*`prop_TA' ) + (`high'*`prop_CA' )  ///
							- (`low'*`prop_TR' ) - (`mu_cr'*`prop_CR' ) - (`low'*`prop_TA' ) - (`low'*`prop_CA')
								
								
			*worst case scenario ( lower bound)
			local ATE_MANSKI_LB  = (`mu_tr'*`prop_TR' ) + (`low'*`prop_CR' ) + (`low'*`prop_TA' ) + (`low'*`prop_CA' )  ///
							- (`high'*`prop_TR' ) - (`mu_cr'*`prop_CR' ) - (`high'*`prop_TA' ) - (`high'*`prop_CA')
								
		}


	* ========================================
	*	    D.5  LEE BOUNDS
	*
	*   Note: These bounds identify the ATE 
	*		for Always Responders, a subset of the
	*		subpopulation of respondents
	* ========================================
		
		* ----------------
		* Response rates
		* ----------------
		
			qui sum $R if $T==0 & $POST==1
			local  a = r(mean)
			qui sum $R if $T==1 & $POST==1
			local  b = r(mean)

	
		* ---------------------------------------------------------------
		* Case in which we rule out control-only responders 
		
		* Need to bound: avg treated potential outcome for always-responders
		* ---------------------------------------------------------------
		
			if `a' < `b' {

				* alpha --> ratio response n rates
					local alpha = `a'/`b'
					
				* gamma --> obs mean TR
					qui sum $Y if $R==1 & $T==1 & $POST==1
					local gamma = r(mean)
			
			
				* Lower bound treated potential outcome for always-responders
					local lee_tcfac_lb = max(((`gamma' + `alpha' - 1)/(`alpha')), 0)
					
				* Upper bound treated potential outcome for always-responders 
				
					local lee_tcfac_ub = min((`gamma'/`alpha'), 1)
					
							
				* Avg potential outcome for always responders w/o treatment = observed average for CR:
					qui sum $Y if $T==0 & $R==1 & $POST==1
					local obs = r(mean)
				
				* ATE for always responders (bounds)
					local   LEE_LB = `lee_tcfac_lb' - `obs'
					local   LEE_UB = `lee_tcfac_ub' - `obs'
			
			}
			
			
		* ---------------------------------------------------------------
		* Case in which we rule out treatment-only responders 
		
		* Need to bound: avg untreated potential outcome for always-responders
		* ---------------------------------------------------------------
		
			if `a' >= `b' {

				* alpha --> ratio response n rates
					local alpha = `b'/`a'
					
				* gamma --> obs mean CR
					qui sum $Y if $R==1 & $T==0 & $POST==1
					local gamma = r(mean)
			
			
				* Lower bound always responders w/o treatment
					local lee_ucfac_lb = max(((`gamma' + `alpha' - 1)/(`alpha')) , 0)
					
				* Upper bound always responders w/o treatment
				
					local lee_ucfac_ub = min((`gamma'/`alpha'), 1)
							
				* Avg potential outcome for always responders w treatment = observed average for TR:
					qui sum $Y if $T==1 & $R==1 & $POST==1
					local obs = r(mean)
				
				* ATE for always responders (bounds)
					local   LEE_LB =  `obs' - `lee_ucfac_ub' 
					local   LEE_UB =  `obs' - `lee_ucfac_lb'
			
			}

		
	* ===============================================
	*	    D.6   DISPLAY & EXPORT CORRECTION OUTPUT
	* ===============================================
		
		*	------------------------------
		*		       RCTs
		*
		*	Note: report all corrections
		*	------------------------------
		
		if ("`rct'"=="yes") {

			matrix corrections = J(10,4,.)

			* Naive estimators for ATE and ATE-R
			matrix corrections[1,1] = `naive_b'
			matrix corrections[2,1] = `naive_se'
			matrix corrections[1,2] = `naive_b'
			matrix corrections[2,2] = `naive_se'
			
			*IPW estimators for ATE and ATE-R
			matrix corrections[3,1] = `IPW_ATE_b'
			matrix corrections[4,1] = `IPW_ATE_se'
			matrix corrections[3,2] = `IPW_ATER_b'
			matrix corrections[4,2] = `IPW_ATER_se'
		
			*CiC bounds for ATE, ATE-R, and ATT-R
			matrix corrections[5,1] = `LB_ATE'
			matrix corrections[6,1] = `UB_ATE'
			matrix corrections[5,2] = `LB_ATE_R'
			matrix corrections[6,2] = `UB_ATE_R'
			matrix corrections[5,3] = `LB_ATT_R'
			matrix corrections[6,3] = `UB_ATT_R'
			
						
			*Manski bounds for ATE and ATE-R
			matrix corrections[7,1] = `ATE_MANSKI_LB'
			matrix corrections[8,1] = `ATE_MANSKI_UB'
			matrix corrections[7,2] = `ATE_R_MANSKI_LB'
			matrix corrections[8,2] = `ATE_R_MANSKI_UB'
		
			
			*Lee bounds for ATE-Always Resp.
			matrix corrections[9,4]  = `LEE_LB'
			matrix corrections[10,4] = `LEE_UB'

			


				// Table 1. text format
				esttab matrix(corrections) using "${CiC_output}correction_results.tab" , replace nomtitles ///
				type ///
				title("Attrition Corrections") ///
				varlabels(r1 "   Coefficient" r2 "   SE" r3 "   Coefficient" r4 "   SE" r5 "   Lower" r6 "   Upper" ///
							r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
				collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
				refcat(r1 "Naive Estimator" r3 "IPW Corrections" r5 "CiC Bounds" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
				varwidth(15)  modelwidth(20) ///
				addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
				"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
				"Asymptotic standard errors considering the cluster structure of the data when relevant." ///
				"See help file for more details." ///	
				"")	
				
				
				// Table 1. tex format
				qui esttab matrix(corrections) using "${CiC_output}correction_results.tex" , replace nomtitles ///
				title("Attrition Corrections") ///
				substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
				varlabels(r1 "   Coefficient" r2 "   SE" r3 "   Coefficient" r4 "   SE" r5 "   Lower" r6 "   Upper" ///
							r7 "   Lower" r8 "   Upper" r9 "   Lower" r10 "   Upper") ///
				collabels("ATE"  "ATE-R"  "ATT-R" "ATE-AR") ///
				refcat(r1 "Naive Estimator" r3 "IPW Corrections" r5 "CiC Bounds" r7 "Manski Bounds" r9 "Lee Bounds", nolab) ///
				varwidth(15)  modelwidth(20) ///
				addnotes("This table reports the attrition corrections of the average treatment effects for the study population (ATE)" ///
				"and the subpopulations of respondents (ATE-R), treated respondents (ATT-R), and always-responders (ATE-AR)." ///
				"Asymptotic standard errors considering the cluster structure of the data when relevant." ///
				"See help file for more details." ///	
				"")					
				
		}
		
		
		*	------------------------------------
		*	   			No RCTs
		*
		*   Note: report CiC corrections only 
		*	------------------------------------

		if ("`rct'"=="no") {

			matrix corrections = J(2,3,.)

			
			*CiC estimators for ATT-R, ATE-R, and ATE
			matrix corrections[1,1] = `LB_ATE'
			matrix corrections[2,1] = `UB_ATE'
			matrix corrections[1,2] = `LB_ATE_R'
			matrix corrections[2,2] = `UB_ATE_R'
			matrix corrections[1,3] = `LB_ATT_R'
			matrix corrections[2,3] = `UB_ATT_R'
		
				// Table 1. text format
				esttab matrix(corrections) using "${CiC_output}correction_results.tab" , replace nomtitles ///
				type ///
				title("Attrition Corrections") ///
				varlabels( r1 "   Lower" r2 "   Upper") ///
				collabels("ATE"  "ATE-R"  "ATT-R" ) ///
				refcat(r1 "CiC Bounds", nolab) ///
				varwidth(15)  modelwidth(20) ///
				addnotes("This table reports the CiC corrections of the average treatment effects for the study population (ATE)" ///
				"and the subpopulations of respondents (ATE-R), and treated respondents (ATT-R)." ///
				"Asymptotic standard errors considering the cluster structure of the data when relevant." ///
				"See help file for more details." ///	
				"")	
				
				
				// Table 1. tex format
				qui esttab matrix(corrections) using "${CiC_output}correction_results.tex" , replace nomtitles ///
				title("Attrition Corrections") ///
				substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
				varlabels( r1 "   Lower" r2 "   Upper") ///
				collabels("ATE"  "ATE-R"  "ATT-R" ) ///
				refcat(r1 "CiC Bounds", nolab) ///
				varwidth(15)  modelwidth(20) ///
				addnotes("This table reports the CiC corrections of the average treatment effects for the study population (ATE)" ///
				"and the subpopulations of respondents (ATE-R), and treated respondents (ATT-R)." ///
				"Asymptotic standard errors considering the cluster structure of the data when relevant." ///
				"See help file for more details." ///	
				"")	

												
		}

		
		
		
qui clear				
}
/** Close loop binary outcome. **/

end
