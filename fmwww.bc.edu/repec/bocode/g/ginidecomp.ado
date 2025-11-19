*! version 1.3, November 2025
*! Authors: Vesa-Matti Heikkuri, Matthias Schief, and Aapo Välimäki
*! This program computes the Gini coefficient and implements the decomposition 
*! by population subgroups derived in Heikkuri and Schief (2024)

version 13.1

program ginidecomp, sortpreserve rclass 


syntax varname(numeric) [aweight fweight iweight pweight] [if] [in] [, BYgroup(varlist) CONFidenceintervals confidencelevel(string) fulldataset threshold(string)]

set more off
local inc "`varlist'"

if strlen("`inc'") > 14 {
	local inc_short substr("`inc'", 1, 14)
}
else local inc_short "`inc'"


* Temporary variables	 
tempvar w cumulProp gini firstObs meanIncome_k relativeMeanIncome_k totalWeights_k relativeWeight_k popShare_k incomeShare_k cumulProp_k gini_k


* Weight handling
if "`weight'" == "" gen byte `w' = 1
else qui gen `w' `exp'

qui sum `w', meanonly
qui replace `w' = `w' / r(mean) // Normalisation.


* Creates weighted income variable.
tempvar zy
qui gen `zy' = `w' * `inc'


* Initialises local flag variable depending on user's   
* specification of option "bygroup".
if ("`bygroup'" != "") | ("`by'" != "") {
	local bygroupFlag = 1
}

else local bygroupFlag = 0


* Initialises local flag variable and confidence level
* based on parameters passed to the program by the user. 
if ("`confidenceintervals'" != "") | ("`conf'" != "") {
	local conFlag = 1
	
	if "`confidencelevel'" == "" {
		local confLevel = 95 // Defaults to 95% confidence level.
	}
	
	else {
		local confLevel = `confidencelevel'
	}
}

else local conFlag = 0

if (("`confidenceintervals'" == "") | ("`conf'" == "")) & ("`confidencelevel'" != "") {
	local conFlag = 1
	
	local confLevel = `confidencelevel'
}


* Initialises variable thresholdSize.
if "`threshold'" != "" {
	scalar thresholdSize = `threshold'
}

else {
	scalar thresholdSize = 0
}

* Initialises flag variables for overriding the dynamic approach and instead
* using the full dataset for all calculations.
* Dynamic approach is taken by default.
scalar overrideMC = 0

if "`fulldataset'" != "" {
	scalar overrideMC = 1
}


* Data validation
marksample touse
qui count if `touse'
if r(N) == 0 error 2000

scalar aggrSize = r(N)

lab var `touse' "NumObs"
lab def `touse' 1 "`r(N)'"
lab val `touse' `touse'


* Report the number of missing values
qui count if missing(`inc') | missing(`w')
if r(N) > 0 {
	di as txt "(`r(N)' observations omitted due to missing values in `inc' or the weight variable)"
}


* Informs user if the variable given as principle argument contains
* negative datapoints.
qui count if `varlist' < 0

if r(N) > 0 {
	di as text "  "
	di as text "ATTENTION: Variable `varlist' contains `r(N)' negative datapoints! Negative values are used in the computation of the Gini coefficient, which may thus exceed 1."
}


* Initialises variables for aggregate Gini calculation
qui sum `inc' [w = `w'] if `touse'
local totalWeights = r(sum_w)
local meanIncome = r(mean)
scalar meanInc = r(mean)


* Ensures that mean income is non-zero.
if `meanIncome' == 0 {
	display as error "Mean of income is zero! Unable to compute the Gini coefficient."
	exit 999
}


* Gini calculation.
gsort -`touse' `inc' 
qui gen double `cumulProp' = (2 * sum(`w') - `totalWeights' - `w')/(`totalWeights'*`totalWeights'*`meanIncome') if `touse'
qui egen double `gini' = total(`w'*`inc'*`cumulProp') if `touse'

lab var `gini' "Gini"
scalar gini = `gini'
return scalar gini = `gini'


* Subgroup decomposition
if `bygroupFlag' == 1 {	
	* Bygroup handling
	tempvar bygroup_num
	qui egen double `bygroup_num' = group(`bygroup'), missing
	label variable `bygroup_num' "Subgroup"
	markout `touse' `bygroup_num'
	
	capture levelsof `bygroup_num' if `touse' , local(groupLevels)
	qui if _rc levels `bygroup_num' if `touse' , local(groupLevels)

	foreach var in `bygroup'{
		qui count if missing(`var')
		if r(N) > 0 {
			di as text "  "
			di as text "(Note: the bygroup variable(s) contain(s) missing values.  By default, missing values in the groupvar variables are treated as group identifiers. For more information, see help file.)"
			di as text "  "
			continue, break
		}
	}	

	qui {
		* Create subgroup labels
		tempvar sortVar
		gen `sortVar' = 0
		foreach g in `groupLevels' {
			replace `sortVar' = `bygroup_num' != `g'
			sort `sortVar'
			local firstBygroup = 1
			foreach var in `bygroup' {
				local value = `var'[1]
				if `firstBygroup' == 1 {
					local label_text = "`var' = `value'"
				}
				
				else {
					local label_text = "`label_text'" + ",  `var' = `value'"
				}
				
				local firstBygroup = 0
			}
			
			label define bygroup_num_label `g' "`label_text'", modify
		}
		
		label values `bygroup_num' bygroup_num_label
		
		
		* Compute and print subgroup summary statistics
		tempvar notuse
		qui gen byte `notuse' = -`touse'
		sort `notuse' `bygroup_num' `inc'

		by `notuse' `bygroup_num': gen byte `firstObs' = _n == 1 if `touse'
		by `notuse' `bygroup_num': egen `totalWeights_k' = sum(`w') if `touse'
		
		
		gen double `popShare_k' = `totalWeights_k' / `totalWeights' if `touse'
		gen double `relativeWeight_k' = `w' / `totalWeights_k' if `touse'
		by `notuse' `bygroup_num': egen  double `meanIncome_k' = sum(`relativeWeight_k' * `inc') if `touse'
		gen double `relativeMeanIncome_k' = `meanIncome_k' / `meanIncome' if `touse'
		gen double `incomeShare_k' = `popShare_k' * `relativeMeanIncome_k' if `touse'
		
		
		* Ensures that meanIncome_k is non-zero for all subpopulations.
		* Stops execution if needed and prints error message.
		qui count if `meanIncome_k' == 0
		if `r(N)' > 0 {
				display as error "A subgroup's mean of income is zero! Unable to compute the Gini coefficient."
				exit 998
			}

		* Calculates subgroup Gini.
		bysort `notuse' `bygroup_num' (`inc'): gen double `cumulProp_k' = (2 * sum(`w') - `totalWeights_k' - `w')/(`totalWeights_k'*`totalWeights_k'*`meanIncome_k') if `touse'
		by `notuse' `bygroup_num': egen double `gini_k' = total(`w'*`inc'*`cumulProp_k') if `touse'
		replace `gini_k' = abs(`gini_k')

		
		lab var `popShare_k' "Pop. share"
		lab var `meanIncome_k' "Mean"
		lab var `incomeShare_k' "`inc_short' share"
		lab var `gini_k' "Gini"	

		
		* Compute within and between-group inequality terms
		local giniW = 0

		gsort -`firstObs' `bygroup_num'
		local i = 1
		foreach k of local groupLevels {
			local giniW = `giniW' +  sqrt(`popShare_k'[`i'] * `incomeShare_k'[`i'] * `gini_k'[`i'])
			local ++i
		}
		
		local giniW = `giniW' * `giniW'
		local giniB = `gini'-`giniW'
		local shareW = `giniW' / `gini'
		local shareB = `giniB' / `gini'
		
		scalar giniW = `giniW'
		scalar giniB = `giniB'
		scalar shareW = `giniW' / `gini'
		scalar shareB = `giniB' / `gini'
		
		return scalar within = `giniW'
		return scalar between = `giniB'
		
		return scalar within_share = shareW
		return scalar between_share = shareB
	}
		
	* Compute decomposition results
	tempvar withinGroupIneq betweenGroupIneq

	qui gen double `withinGroupIneq' = `giniW' in 1
	label var `withinGroupIneq' "Within"
		
	qui gen double `betweenGroupIneq' = `gini'-`giniW' in 1
	label var `betweenGroupIneq' "Between"
	
	tempvar withinGroupIneq_percent betweenGroupIneq_percent
	
	qui gen double `withinGroupIneq_percent' = 100 * `withinGroupIneq' / `gini' in 1
	label var `withinGroupIneq_percent' "Within (%)"
	
	qui gen double `betweenGroupIneq_percent' = 100 * `betweenGroupIneq' / `gini' in 1
	label var `betweenGroupIneq_percent' "Between (%)"
}


* The table of results is printed after calculating the confidence intervals
* if the option is specified by user.
if `conFlag' != 1 {
	* Print aggregate Gini coefficient
	di "  "
	di as txt "Aggregate Gini coefficient of `inc':"
	tabdisp `touse' in 1, c(`gini') f(%9.5f)
	return scalar gini = `gini'

	if `bygroupFlag' == 1 {
		* Print subgroup summary statistics
		noi di "  "
		noi di as txt "Subgroup summary statistics:"
		capture noi tabdisp `bygroup_num' if `firstObs' & `touse' , c(`popShare_k' `meanIncome_k' `incomeShare_k' `gini_k') f(%15.5f)

		* Print the decomposition results
		di "  "
		di as txt "Subgroup Decomposition:"
		tabdisp `touse' in 1, c(`gini' `withinGroupIneq' `betweenGroupIneq') f(%9.5f)
		di "  "
		di as txt "Sugroup Decomposition (% of total):"
		tabdisp `touse' in 1, c(`withinGroupIneq_percent' `betweenGroupIneq_percent') f(%9.5f)
		di "Note: The above results show the decomposition of the aggregate Gini coefficient of '`inc'' into inequality within and between subgroups defined by '`bygroup''. The subgroup decomposition is based on the formula presented in Heikkuri and Schief (2024). For more information, type 'help ginidecomp'."
	}
}


** ** ** **
** Confidence intervals will be calculated here,
** if the option is specified by the user.
** ** ** **

if `conFlag' == 1 {
	
	di "  "
	di "Calculating confidence intervals."
	di "This may take a while..."
	
	* Passes variables to mata.
	mata: income = st_data(., "`inc'")
	mata: touse = st_data(., "`touse'")
	mata: N = st_numscalar("aggrSize")
	mata: z = st_data(., "`w'")
	mata: zy = st_data(., "`zy'")
	mata: mu_z = mean(select(z, touse :== 1))
	mata: mu_zy = mean(select(zy, touse :== 1))
	
	mata: overrideMC = st_numscalar("overrideMC")
	mata: onlyMC = st_numscalar("onlyMC")
	
	
	* Precision of Monte-Carlo integration.
	if thresholdSize == 0 {
		mata: thresholdSize = 10000 // Size of threshold defaults to 10 000.
	}
	
	else {
		mata: thresholdSize = st_numscalar("thresholdSize")
	}
	
	mata: precision_vec = int_precision(thresholdSize, N)
	
	mata: numDraws = precision_vec[1]
	mata: numIter = precision_vec[2]
	
	* Asymptotic moments related to subgroup adjusted GMDs.
	if `bygroupFlag' != 0 {
	
		* Initialises result vectors for subgroup adjusted GMDs, their 
		* asymptotic variances, and their asymptotic covariances
		* with the aggregate means of weights and weighted income.
		mata: adjGMD_vec = J(0, 1, .)
		mata: aV_adjGMD_vec = J(0, 1, .)
		mata: aC_adjGMD_Mz_vec = J(0, 1, .)
		mata: aC_adjGMD_Mzy_vec = J(0, 1, .)
		
		
		* Initialises an indicator variable that's used to select valid
		* observations from a specific subgroup.
		tempvar subgroup_touse
		qui gen byte `subgroup_touse' = .
		
		* Loops through subgroups.
		foreach k of local groupLevels {
			
			qui replace `subgroup_touse' = `touse' & (`bygroup_num' == `k')
			mata: subgrouptouse = st_data(., "`subgroup_touse'")
			
			qui sum `gini_k' if `subgroup_touse', meanonly
			scalar gini_k = r(mean) // Subgroup Gini.
			mata: gini_k = st_numscalar("gini_k")
		
			qui count if `subgroup_touse'
			scalar pi_k = r(N) / aggrSize
			mata: pi = st_numscalar("pi_k")
		
			* Calculates subgroup adjusted GMD.
			mata: adjGMD = adjGMD(income, z, zy, subgrouptouse, gini_k, N)
			mata: adjGMD_vec = adjGMD_vec \ adjGMD
			
			
			* Calculates asymptotic variance of subgroup adjusted GMD.
			mata: aV_adjGMD = aV_adjGMD_e(income, z, subgrouptouse, adjGMD, pi, numDraws, thresholdSize, numIter, N, overrideMC)
			mata: aV_adjGMD_vec = aV_adjGMD_vec \ aV_adjGMD
			
			
			* Calculates asymptotic covariance of subgroup adjGMD and
			* aggregate mean of weights.
			mata: aC_adjGMD_Mz = aC_adjGMD_Mz_e(income, z, subgrouptouse, adjGMD, mu_z, pi, numDraws, thresholdSize, numIter, N, overrideMC)
			mata: aC_adjGMD_Mz_vec = aC_adjGMD_Mz_vec \ aC_adjGMD_Mz
			
			
			* Calculates asymptotic covariance of subgroup adjusted GMD
			* and aggregate mean of weighted income.
			mata: aC_adjGMD_Mzy = aC_adjGMD_Mzy_e(income, z, zy, subgrouptouse, adjGMD, mu_zy, pi, numDraws, thresholdSize, numIter, N, overrideMC)
			mata: aC_adjGMD_Mzy_vec = aC_adjGMD_Mzy_vec \ aC_adjGMD_Mzy
		}
	}
	
	
	* Asymptotic moments related to aggregate GMD.
	mata: aggrGini = st_numscalar("gini")
	
	mata: aggrGMD = aggrGini * 2 * mu_z * mu_zy
	
	
	* Calculates asymptotic variance of aggregate GMD.
	mata: pi = 1

	mata: aV_aggrGMD = aV_adjGMD_e(income, z, touse, aggrGMD, pi, numDraws, thresholdSize, numIter, N, overrideMC)

	
	* Calculates asymptotic covariance of aggregate GMD and
	* aggregate mean of weights.
	mata: aC_aggrGMD_Mz = aC_aggrGMD_Mz_e(income, z, touse, aggrGMD, numDraws, thresholdSize, numIter, overrideMC)
	
	
	* Calculates asymptotic covariance of aggregate GMD and
	* aggregate mean of weighted income.
	mata: aC_aggrGMD_Mzy = aC_aggrGMD_Mzy_e(income, z, zy, touse, aggrGMD, numDraws, thresholdSize, numIter, overrideMC)
	
	
	* Calculates Theta (cross mean absolute difference).
	if `bygroupFlag' != 0 {
		mata: Theta = aggrGMD - colsum(adjGMD_vec)
	}
	
	
	* Asymptotic moments related to Theta.
	if `bygroupFlag' != 0 {
		mata: bygroup_num = st_data(., "`bygroup_num'")
		mata: popShare_k = st_data(., "`popShare_k'")
		mata: sub_num = rows(uniqrows(bygroup_num)) // Number of subgroups.
		
		mata: aux_estim_aV = J(0, 1, .) // Intermediate results: as. var. of Theta
		mata: aux_estim_aC = J(0, 1, .) // Int. results: as. cov. of Theta and mu_z.
		mata: estim_vec_aC2 = J(0, 1, .) // Final results: as. cov. of Theta and adjGMDs.
		mata: aux_estim_aC3 = J(0, 1, .) // Int. results: as. cov. of Theta and mu_zy.
		
		* Loops through subgroups.
		foreach k of local groupLevels {
			
			qui replace `subgroup_touse' = `touse' & (`bygroup_num' == `k')
			mata: subgroup_touse = st_data(., "`subgroup_touse'")
			
			scalar k = `k'
			mata: k = st_numscalar("k")
			
			* Selects valid observations belonging to focal subgroup.
			mata: y_focal = select(income, subgroup_touse :== 1)
			mata: z_focal = select(z, subgroup_touse :== 1)
			
			qui count if `subgroup_touse'
			scalar pi_k = r(N) / aggrSize
			mata: pi_k = st_numscalar("pi_k")
			
			* Monte Carlo integration for asymptotic moments.
			mata: results = J(4, 1, .) // Vector to store intermediate results.
			mata: results = iterFunction(income, z, y_focal, z_focal, subgroup_touse, touse, pi_k, numDraws, thresholdSize, numIter, overrideMC)
			
			* Int. res. asymptotic var. of Theta
			mata: aux_estim_aV = aux_estim_aV \ results[1]
			
			* Int. res. asymptotic cov. of Theta and mu_z.
			mata: aux_estim_aC = aux_estim_aC \ results[2]
			
			* Int. res. asymptotic cov. of Theta and mu_zy.
			mata: aux_estim_aC3 = aux_estim_aC3 \ results[4]
			
			* Asymptotic covariance of Theta and subgroup adjusted GMD.
			mata: res_aC2 = 4 * (results[3] - Theta * adjGMD_vec[k])
			mata: estim_vec_aC2 = estim_vec_aC2 \ res_aC2
		}
		
		* Calculates asymptotic variance of Theta.
		mata: aV_Theta = 4 * (colsum(aux_estim_aV) - Theta^2)
		
		
		* Calculates asymptotic covariance of Theta and aggregate mean of weights.
		mata: aC_Theta_Mz = 2 * colsum(aux_estim_aC) - 2 * Theta * mu_z
		
		
		* Calculates asymptotic covariance of Theta and aggregate mean of weighted income.
		mata: aC_Theta_Mzy = 2 * colsum(aux_estim_aC3) - 2 * Theta * mu_zy
	}
	
	
	qui sum `w' if `touse'
	scalar var_z = r(Var) // Sample variance of weights.
	
	qui sum `zy' if `touse'
	scalar var_zy = r(Var) // Sample variance of weighted income.
	
	qui correlate `w' `zy' if `touse', covariance 
	scalar cov_z_zy = el(r(C), 1, 2) // Sample covariance of weights and weighted income.
	
	mata: var_z = st_numscalar("var_z")
	mata: var_zy = st_numscalar("var_zy")
	mata: cov_z_zy = st_numscalar("cov_z_zy")
	
	* Calculates asymptotic variance of aggregate Gini.
	mata: aV_Gini = aV_Gini_e(aggrGini, mu_z, mu_zy, var_z, var_zy, cov_z_zy, aV_aggrGMD, aC_aggrGMD_Mz, aC_aggrGMD_Mzy)
	
	
	if `bygroupFlag' != 0 {
		
		* Calculates asymptotic variance of the biased Within-group term.
		mata: temp_vec = select(adjGMD_vec, adjGMD_vec :> 0)
		mata: b_giniW = (1/(2 * mu_z * mu_zy)) * (sum(sqrt(temp_vec)))^2

		mata: aV_Gw = aV_Gw_e(b_giniW, mu_z, mu_zy, var_z, var_zy, cov_z_zy, adjGMD_vec, aV_adjGMD_vec, aC_adjGMD_Mz_vec, aC_adjGMD_Mzy_vec)
	
	
		* Calculates asymptotic variance of the biased Between-group term.
		mata: b_giniB = b_Gb(adjGMD_vec, mu_z, mu_zy, Theta)

		mata: aV_Gb = aV_Gb_e(b_giniB, mu_z, mu_zy, var_z, var_zy, cov_z_zy, adjGMD_vec, aV_adjGMD_vec, aC_adjGMD_Mz_vec, aC_adjGMD_Mzy_vec, aV_Theta, aC_Theta_Mz, aC_Theta_Mzy, estim_vec_aC2)
	
	
		* Calculates asymptotic covariance of Within- and Between-group terms.
		mata: aC_Gw_Gb = 0.5 * (aV_Gini - aV_Gw - aV_Gb)
		
		
		* Calculates asymptotic variance of the Within-group share, which
		* is equal to the asymptotic variance of the Between-group share.
		mata: giniW = st_numscalar("giniW") // Unbiased W-group term.
		
		mata: aV_GwGb_share = aV_GwGb_share_e(aggrGini, giniW, aV_Gw, aV_Gb, aC_Gw_Gb)
	}
}


* Table of results with confidence intervals.
if `conFlag' == 1 {
	qui {
		
		* Informs user if Monte Carlo integration had to be used
		* to obtain the confidence intervals.
		scalar MC_flag = 0
		
		mata: st_numscalar("thresholdSize", thresholdSize)
		
		if `bygroupFlag' == 1 {
			foreach k of local groupLevels {
				count
				if `r(N)' > thresholdSize {
					scalar MC_flag = 1
				}
			}
		}
		
		count if `touse'
		if `r(N)' > thresholdSize {
			scalar MC_flag = 1
		}
		
		if (MC_flag == 1) & (overrideMC == 0) {
			noi di "  "
			noi di "Monte Carlo integration was used in computing the confidence intervals."
		}
		
		
		tempvar stats_names stat_id point_estims std_errs CI_lows CI_ups
		
		gen `stats_names' = "" // For results tables.
		replace `stats_names' = "Gini" in 1
		replace `stats_names' = "Within" in 2
		replace `stats_names' = "Between" in 3
		replace `stats_names' = "Within (%)" in 4
		replace `stats_names' = "Between (%)" in 5
		
		gen `stat_id' = . // To prevent tabdisp from sorting alphabetically.
		replace `stat_id' = _n in 1/5
		lab define stat_lbl 1 "Gini" 2 "Within" 3 "Between" 4 "Within (%)" 5 "Between (%)"
		lab values `stat_id' stat_lbl
		lab var `stat_id' "Statistic"
		
		
		if (`confLevel' != 95) & (`confLevel' != 99) {
			local half_alpha = (100 - `confLevel')/2
		}
		
		if `confLevel' == 95 {
			local half_alpha = 0.975
		}
		
		else local half_alpha = 0.995
		
		
		local z = invnormal(`half_alpha')
		
		mata: st_numscalar("aV_Gini", aV_Gini)
		mata: st_numscalar("aV_Gw", aV_Gw)
		mata: st_numscalar("aV_Gb", aV_Gb)
		mata: st_numscalar("aV_GwGb_share", aV_GwGb_share)

		local G_se = sqrt(aV_Gini/aggrSize)
		return scalar G_se = sqrt(aV_Gini/aggrSize)
		
		if `bygroupFlag' == 1 {
			local Gw_se = sqrt(aV_Gw/aggrSize)
			local Gb_se = sqrt(aV_Gb/aggrSize)
			local share_se = sqrt(aV_GwGb_share/aggrSize)
			
			return scalar Gw_se = sqrt(aV_Gw/aggrSize)
			return scalar Gb_se = sqrt(aV_Gb/aggrSize)
			return scalar share_se = sqrt(aV_GwGb_share/aggrSize)
		}
	}
	
	qui {
		gen `point_estims' = .
		lab var `point_estims' "Estimate"
		replace `point_estims' = gini in 1
		
		gen `std_errs' = .
		lab var `std_errs' "Std. err."
		replace `std_errs' = `G_se' in 1
			
		gen `CI_lows' = .
		lab var `CI_lows' "[`confLevel'% conf."
		replace `CI_lows' = `gini' - (`z' * `G_se') in 1
		
		gen `CI_ups' = .
		lab var `CI_ups' "interval]"
		replace `CI_ups' = `gini' + (`z' * `G_se') in 1
		
		if `bygroupFlag' == 1 {
			replace `point_estims' = giniW in 2
			replace `point_estims' = giniB in 3
			replace `point_estims' = 100 * shareW in 4
			replace `point_estims' = 100 * shareB in 5
			
			replace `std_errs' = `Gw_se' in 2
			replace `std_errs' = `Gb_se' in 3
			replace `std_errs' = 100 * `share_se' in 4
			replace `std_errs' = 100 * `share_se' in 5
			
			replace `CI_lows' = `giniW' - (`z' * `Gw_se') in 2
			replace `CI_lows' = `giniB' - (`z' * `Gb_se') in 3
			
			replace `CI_lows' = 100 * (`shareW' - (`z' * `share_se')) in 4
			replace `CI_lows' = 100 * (`shareB' - (`z' * `share_se')) in 5
			
			replace `CI_ups' = `giniW' + (`z' * `Gw_se') in 2
			replace `CI_ups' = `giniB' + (`z' * `Gb_se') in 3
			
			replace `CI_ups' = 100 * (`shareW' + (`z' * `share_se')) in 4
			replace `CI_ups' = 100 * (`shareB' + (`z' * `share_se')) in 5
		}
	}
	
	if `bygroupFlag' != 1 {
		* Print aggregate Gini coefficient
		di "  "
		di as txt "Aggregate Gini coefficient of `inc' and Confidence Intervals:"
		tabdisp `stat_id' in 1, c(`point_estims' `std_errs' `CI_lows' `CI_ups') f(%15.5f)
	}
	
	else {
		* Print subgroup summary statistics
		di "  "
		di as txt "Subgroup summary statistics:"
		tabdisp `bygroup_num' if `firstObs' & `touse' , c(`popShare_k' `meanIncome_k' `incomeShare_k' `gini_k') f(%15.5f)
	
		
		* Print the decomposition results
		di "  "
		di as txt "Subgroup Decomposition and Confidence Intervals:"
		tabdisp `stat_id' in 1/5, c(`point_estims' `std_errs' `CI_lows' `CI_ups') f(%15.5f)
		di "Note: The above results show the decomposition of the aggregate Gini coefficient of '`inc'' into inequality within and between subgroups defined by '`bygroup''. The subgroup decomposition is based on the formula presented in Heikkuri and Schief (2024). For more information, type 'help ginidecomp'."
	}
	
	label drop stat_lbl // Allows us to run the program consecutively.
}

end


** ** ** **
** Functions required to calculate the confidence intervals:
** ** ** **

* Calculates and returns subgroup adjusted GMDs based on Davidson (2009).
mata:
real scalar adjGMD(
    real matrix data,
	real matrix z,
	real matrix zy,
    real matrix touse,
	real scalar gini_k,
    real scalar N
)
{
    real matrix y_use, z_use, zy_use
    real scalar n_k, aux, aux2

    // Selects usable observations.
    y_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)
	zy_use = select(zy, touse :== 1)

    // Checks that there are more than zero observations.
    n_k = rows(y_use)
    if (n_k == 0) {
        return(0)
    }
	
	aux = gini_k * 2 * mean(z_use) * mean(zy_use)
	aux2 = n_k * (n_k - 1) / N / (N - 1)
	
    my_estimate = aux * aux2

    return(my_estimate)
}

end


* Calculates and returns asymptotic variance of subgroup adjusted GMDs.
mata:
real scalar aV_adjGMD_e(
	real matrix data,
	real matrix z,
	real matrix touse,
	real scalar adjGMD,
	real scalar pi,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar N,
	real scalar overrideMC
)
{
	real scalar i, aux4, len
	real matrix X, Y, idx_X, idx_Y, Z_X, Z_Y, aux, aux_weighted, aux2, aux3, aux_z
	real matrix data_use, z_use
	real matrix integral_estimate
	
	// Selects usable observations.
	data_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)
	
	len = rows(data_use)
	
	integral_estimate = J(numIter, 1, .)
	
	if ((len <= thresholdSize) | (overrideMC == 1)) {
		// Calculates value of estimator if subgroup is sufficiently small.
		aux_z = z_use * z_use'
		aux = abs(data_use * J(1, len, 1) - J(len, 1, 1) * data_use')
		aux2 = aux_z :* aux
		aux3 = (1/N * rowsum(aux2)) :^ 2
		
		final_estimate = 4 * (1/N * colsum(aux3)) - 4 * (adjGMD^2)	
	}
	
	else {
		// Monte Carlo integration for large subgroups.
		for (i = 1; i <= numIter; i++) {
			// Takes random draws from income and weight variables.
			idx_X = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_X) > 1) idx_X = idx_X'
			
			idx_Y = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_Y) > 1) idx_Y = idx_Y'
				
			X = data_use[idx_X]
			Z_X = z_use[idx_X]
			
			Y = data_use[idx_Y]
			Z_Y = z_use[idx_Y]
			
			// Computes expected weighted pairwise absolute differences.
			aux = abs(X * J(1, numDraws, 1) - J(numDraws, 1, 1) * Y')
			aux_weighted = aux :* (J(numDraws, 1, 1) * Z_Y')
			
			aux2 = mean(aux_weighted')'
			aux3 = (aux2 :^ 2) :* (Z_X :^ 2)
			aux4 = mean(aux3)
			
			integral_estimate[i] = aux4
		}
		
		final_estimate = ((pi^3) * mean(integral_estimate) - adjGMD^2) * 4
	}
	
	return(final_estimate)
}

end


* Calculates and returns asymptotic covariance of subgroup adjusted GMDs and 
* aggregate mean of weights.
mata:
real scalar aC_adjGMD_Mz_e(
	real matrix data,
	real matrix z,
	real matrix touse,
	real scalar adjGMD,
	real scalar mu_z,
	real scalar pi,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar N,
	real scalar overrideMC
)
{
	real scalar i, len
	real matrix X, Y, idx_i, idx_j, Z_X, Z_Y, aux, aux2, aux3, aux4, aux_z
	real matrix data_use, z_use
	real matrix integral_estimate

	// Selects usable observations.
	data_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)
	
	len = rows(data_use)

	integral_estimate = J(numIter, 1, .)
	
	if ((len <= thresholdSize) | (overrideMC == 1)) {
		// Calculates value of estimator.
		aux_z = (z_use :^ 2) * z_use'
		aux = abs(data_use * J(1, len, 1) - J(len, 1, 1) * data_use')
		aux2 = aux_z :* aux
		aux3 = 1/N * rowsum(aux2)
		
		final_estimate = 2 * (1/N * colsum(aux3)) - 2 * adjGMD * mu_z
	}
	
	else {
		// Monte Carlo integration.
		for (i = 1; i <= numIter; i++) {
			idx_i = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_i) > 1) idx_i = idx_i'
			
			idx_j = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_j) > 1) idx_j = idx_j'
			
			X = data_use[idx_i]
			Z_X = z_use[idx_i]
			
			Y = data_use[idx_j]
			Z_Y = z_use[idx_j]
			
			aux = (abs(X * J(1, numDraws, 1) - J(numDraws, 1, 1) * Y'))
			aux2 = ((Z_X * J(1, numDraws, 1))) :^ 2	
			aux3 = J(numDraws, 1, 1) * Z_Y'
			aux4 = aux :* aux2 :* aux3

			integral_estimate[i] = mean(mean(aux4')')
		}
		
		final_estimate = 2 * (pi^2) * mean(integral_estimate) - 2 * adjGMD * mu_z
	}
	
	return(final_estimate)
}

end


* Calculates and returns asymptotic covariance of aggregate GMD and aggregate
* mean of weights.
mata:
real scalar aC_aggrGMD_Mz_e(
	real matrix data,
	real matrix z,
	real matrix touse,
	real scalar aggrGMD,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar overrideMC
)
{
	real scalar i, len
	real matrix X, Y, idx_i, idx_j, Z_X, Z_Y, aux, aux2, aux3, aux_z
	real matrix data_use, z_use
	real matrix integral_estimate

	// Selects usable observations.
	data_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)

	len = rows(data_use)
	
	integral_estimate = J(numIter, 1, .)
	
	if ((len <= thresholdSize) | (overrideMC == 1)) {
		// Calculates value of estimator.
		aux_z = (z_use :^ 2) * z_use'
		aux = abs(data_use * J(1, len, 1) - J(len, 1, 1) * data_use')
		aux2 = aux_z :* aux
		aux3 = (mean(aux2'))'
		
		final_estimate = 2 * mean(aux3) - 2 * aggrGMD * mean(z_use)
	}
	
	else {
		// Monte Carlo integration.
		for (i = 1; i <= numIter; i++) {
			idx_i = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_i) > 1) idx_i = idx_i'
			
			idx_j = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_j) > 1) idx_j = idx_j'
			
			X = data_use[idx_i]
			Z_X = z_use[idx_i]
			
			Y = data_use[idx_j]
			Z_Y = z_use[idx_j]
			
			aux = abs(X * J(1, numDraws, 1) - J(numDraws, 1, 1) * Y')
			aux2 = (Z_X * J(1, numDraws, 1)) :^ 2
			aux3 = aux :* aux2 :* Z_Y'
			
			integral_estimate[i] = mean(mean(aux3')')
		}
		
		final_estimate = 2 * mean(integral_estimate) - 2 * aggrGMD * mean(z_use)
	}
	
	return(final_estimate)
}

end



* Calculates and returns asymptotic covariance of subgroup adjusted GMDs and
* aggregate mean of weighted income.
mata:
real scalar aC_adjGMD_Mzy_e(
	real matrix data,
	real matrix z,
	real matrix zy,
	real matrix touse,
	real scalar adjGMD,
	real scalar mu_zy,
	real scalar pi,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar N,
	real scalar overrideMC
)
{
	real scalar i, len
	real matrix aux, aux2, aux3, aux4, aux_z
	real matrix data_use, z_use, zy_use
	real matrix integral_estimate
	
	// Selects usable observations.
	data_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)
	zy_use = select(zy, touse :== 1)
	
	len = rows(data_use)
	
	integral_estimate = J(numIter, 1, .)
	
	if ((len <= thresholdSize) | (overrideMC == 1)) {
		// Calculates value of estimator.
		aux_z = ((z_use :^ 2) :* data_use) * z_use'
		aux = abs(data_use * J(1, len, 1) - J(len, 1, 1) * data_use')
		aux2 = aux_z :* aux
		aux3 = 1/N * rowsum(aux2)

		final_estimate = 2 * (1/N * colsum(aux3)) - 2 * adjGMD * mu_zy
	}
	
	else {
		// Monte Carlo integration.
		for (i = 1; i <= numIter; i++) {
			idx_i = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_i) > 1) idx_i = idx_i'
			
			idx_j = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_j) > 1) idx_j = idx_j'
			
			X = data_use[idx_i]
			Z_X = z_use[idx_i]
			
			Y = data_use[idx_j]
			Z_Y = z_use[idx_j]
			
			aux = abs(X * J(1, numDraws, 1) - J(numDraws, 1, 1) * Y')
			aux2 = (Z_X * J(1, numDraws, 1)) :^ 2
			aux3 = (J(numDraws, 1, 1) * Z_Y') :* (X * J(1, numDraws, 1))
			aux4 = aux :* aux2 :* aux3
		
			integral_estimate[i] = mean(mean(aux4')')
		}
		
		final_estimate = 2 * (pi^2) * mean(integral_estimate) - 2 * adjGMD * mu_zy
	}
	
	return(final_estimate)
}

end


* Calculates and returns asymptotic covariance of aggregate GMD and aggregate 
* mean of weighted income.
mata:
real scalar aC_aggrGMD_Mzy_e(
	real matrix data,
	real matrix z,
	real matrix zy,
	real matrix touse,
	real scalar aggrGMD,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar overrideMC
)
{
	real scalar i, len
	real matrix aux, aux2, aux3, aux4, aux_z
	real matrix data_use, z_use, zy_use
	real matrix integral_estimate
	
	// Selects usable observations.
	data_use = select(data, touse :== 1)
	z_use = select(z, touse :== 1)
	zy_use = select(zy, touse :== 1)
	
	len = rows(data_use)
	
	integral_estimate = J(numIter, 1, .)
	
	if ((len <= thresholdSize) | (overrideMC == 1)) {
		// Calculates value of estimator.
		aux_z = ((z_use :^ 2) :* data_use) * z_use'
		aux = abs(data_use * J(1, len, 1) - J(len, 1, 1) * data_use')
		aux2 = aux_z :* aux
		aux3 = (mean(aux2'))'
		
		final_estimate = 2 * mean(aux3) - 2 * aggrGMD * mean(zy_use)
	}
	
	else {
		// Works similarly to previous Monte Carlo integrations.
		for (i = 1; i <= numIter; i++) {
			idx_i = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_i) > 1) idx_i = idx_i'
			
			idx_j = ceil(rows(data_use) * runiform(numDraws, 1))
			if (cols(idx_j) > 1) idx_j = idx_j'
			
			X = data_use[idx_i]
			Z_X = z_use[idx_i]
			
			Y = data_use[idx_j]
			Z_Y = z_use[idx_j]
			
			aux = abs(X * J(1, numDraws, 1) - J(numDraws, 1, 1) * Y')
			aux2 = (Z_X * J(1, numDraws, 1)) :^ 2
			aux3 = J(numDraws, 1, 1) * Z_Y' :* (X * J(1, numDraws, 1))
			aux4 = aux :* aux2 :* aux3
			
			integral_estimate[i] = mean(mean(aux4')')
		}
		
		final_estimate = 2 * mean(integral_estimate) - 2 * aggrGMD * mean(zy_use)
	}
	
	return(final_estimate)
}

end


* Used to calculate and return intermediate results for the estimators of
* asymptotic moments related to Theta.
* Called inside iterFunction.
mata:
real matrix auxFunction(
	real matrix focal_income,
	real matrix focal_z,
	real matrix others_income,
	real matrix others_z,
	real scalar N
)
{
	real matrix Y_f, Y_o, Z_f, Z_o, aV_aux, aV_aux2, aC_aux, aC_aux2
	real matrix aC2_aux, aC2_aux2, aC3_aux, aC3_aux2, aC3_aux3, aux_res_vec
	real scalar len_f, len_o, aV_aux_res, aC_aux_res, aC2_aux_res, aC3_aux_res
	
	len_f = rows(focal_income)
	len_o = rows(others_income)
	
	Y_f = focal_income * J(1, len_o, 1)
	Y_o = J(len_f, 1, 1) * others_income'
	
	Z_f = focal_z * J(1, len_o, 1)
	Z_o = J(len_f, 1, 1) * others_z'
	
	Y = focal_income * J(1, len_f, 1)
	
	aux_res_vec = J(4, 1, .)
	
	// Intermediate result for the estimator of the asymptotic variance of Theta.
	aV_aux = (Z_f :* Z_o) :* abs(Y_f :- Y_o)
	aV_aux2 = (1/N * rowsum(aV_aux)) :^ 2
	aV_aux_res = 1/N * colsum(aV_aux2)
	
	// Int. result for the estimator of as. cov. of Theta and mean of weights.
	aC_aux = ((Z_f :^ 2) :* Z_o) :* abs(Y_f :- Y_o)
	aC_aux2 = 1/N * rowsum(aC_aux)
	aC_aux_res = 1/N * colsum(aC_aux2)
	
	// Int. result for the estimator of as. cov of Theta and subgroup
	// adjusted GMD.
	aC2_aux = (Z_f :* Z_o) :* abs(Y_f :- Y_o)
	aC2_aux2 = (focal_z * focal_z') :* abs(Y :- Y')
	aC2_aux3 = (1/N * rowsum(aC2_aux)) :* (1/N * rowsum(aC2_aux2))
	aC2_aux_res = 1/N * colsum(aC2_aux3)
	
	// Int. result for the estimator of as. cov of Theta and mean of weighted income.
	aC3_aux = ((Z_f :^ 2) :* Y_f :* Z_o) :* abs(Y_f :- Y_o)
	aC3_aux2 = 1/N * rowsum(aC3_aux)
	aC3_aux_res = 1/N * colsum(aC3_aux2)
	
	aux_res_vec[1] = aV_aux_res
	aux_res_vec[2] = aC_aux_res
	aux_res_vec[3] = aC2_aux_res
	aux_res_vec[4] = aC3_aux_res	
	
	return(aux_res_vec)
}

end


* Wrapper to calculate and return intermediate results of the asymptotic
* moments related to Theta. 
mata: 
real matrix iterFunction(
	real matrix data,
	real matrix z,
	real matrix y_focal,
	real matrix z_focal,
	real matrix subgroup_touse,
	real matrix touse,
	real scalar pi_k,
	real scalar numDraws,
	real scalar thresholdSize,
	real scalar numIter,
	real scalar overrideMC
)
{
	real scalar i, j, idx, pi_j, len_focal, len_others
	real matrix X, Y, Z, Y_2, int_estim_aV, int_estim_aC1, idx_focal1, idx_focal2
	real matrix int_estim_aC2, int_estim_aC3
	real matrix other_j_y, other_j_z
	
	len_focal = rows(y_focal)
	len_others = rows(data) - len_focal
	
	if (len_focal <= numDraws) {
		// Variable size_diff is used to make sure that
		// the vector X has as many rows as Y.
		size_diff = numDraws - len_focal
		
		// Variable iter_diff is used to improve accuracy
		// when the lenghts of Y and X are small.
		iter_diff = ceil(len_others / len_focal)  // NOTE: HOW SHOULD WE SET THIS?
		
		if (iter_diff > 500) {
			iter_diff = 500
		}
		
		// All data in focal subgroup is used if it's sufficiently small.
		Y = y_focal
		Y_2 = y_focal
		Z_focal = z_focal
		Z_focal2 = z_focal
	}
	
	else {
		size_diff = 0
		iter_diff = 0
	}
	
	others_income = select(data, (touse :== 1) :& (subgroup_touse :== 0))
	others_z = select(z, (touse :== 1) :& (subgroup_touse :== 0))
	
	// Monte Carlo integration is forgone if dataset is sufficiently small.
	if (((len_focal * len_others) <= thresholdSize^2) | (overrideMC == 1)) {
		// Used to store intermediate results.
		int_estim_aV = J(1, 1, .)
		int_estim_aC1 = J(1, 1, .)
		int_estim_aC2 = J(1, 1, .)
		int_estim_aC3 = J(1, 1, .)
		
		N = rows(select(data, touse :== 1))
		
		res_vec = auxFunction(y_focal, z_focal, others_income, others_z, N)
		
		int_estim_aV = res_vec[1]
		int_estim_aC1 = res_vec[2]
		int_estim_aC2 = res_vec[3]
		int_estim_aC3 = res_vec[4]
		
		// Initialises vector for results.
		final_res = J(4, 1, .)
		
		final_res[1] = mean(int_estim_aV)
		final_res[2] = mean(int_estim_aC1)
		final_res[3] = mean(int_estim_aC2)
		final_res[4] = mean(int_estim_aC3)
	}
	
	// Monte Carlo integration is used if dataset is large.
	else {
		// Intermediate integral estimate for asymptotic variance of Theta.
		int_estim_aV = J((numIter + iter_diff), 1, .)
		
		// Intermediate integral estimate for asymptotic covariance of Theta
		// and mean of weights.
		int_estim_aC1 = J((numIter + iter_diff), 1, .)
		
		// Intermediate integral estimate for asymptotic covariance of Theta
		// and subgroup adjusted GMD.
		int_estim_aC2 = J((numIter + iter_diff), 1, .)
		
		// Intermediate integral estimate for asymptotic covariance of Theta and
		// mean of weighted income.
		int_estim_aC3 = J((numIter + iter_diff), 1, .)
	
		// This loop repeats the random sampling many times.
		for (i = 1; i <= (numIter + iter_diff); i++) {
			
			// Initialises vectors for samples drawn from
			// non-focal subgroups.
			X = J((numDraws - size_diff), 1, .)
			Z = J((numDraws - size_diff), 1, .)
			
			if (len_focal > numDraws) {		
				// Draws random sample from the focal subgroup.
				idx_focal1 = ceil(rows(y_focal) * runiform(numDraws, 1))
				idx_focal2 = ceil(rows(y_focal) * runiform(numDraws, 1))
				
				Y = y_focal[idx_focal1]
				Y_2 = y_focal[idx_focal2]
				
				Z_focal = z_focal[idx_focal1]
				Z_focal2 = z_focal[idx_focal2]
			}
		
			// Draws observations uniformly from pool of non-focal subgroups.
			idx_other = ceil(rows(others_income) * runiform((numDraws - size_diff), 1))
			
			X = others_income[idx_other]
			if (cols(X) > 1) X = X'
			
			Z = others_z[idx_other]
			if (cols(Z) > 1) Z = Z'
			
			// Monte Carlo integration.
			res_vec = auxFunction(Y, Z_focal, X, Z, (numDraws - size_diff))
			
			int_estim_aV[i] = res_vec[1]
			int_estim_aC1[i] = res_vec[2]
			int_estim_aC2[i] = res_vec[3]
			int_estim_aC3[i] = res_vec[4]
		}
		
		// Initialises vector for results.
		final_res = J(4, 1, .)

		final_res[1] = pi_k * ((1 - pi_k)^2) * mean(int_estim_aV)
		final_res[2] = pi_k * (1 - pi_k) * mean(int_estim_aC1)
		final_res[3] = (pi_k^2) * (1 - pi_k) * mean(int_estim_aC2)
		final_res[4] = pi_k * (1 - pi_k) * mean(int_estim_aC3)
	}
	
	return(final_res)
}

end


* Calculates and returns the asymptotic variance of aggregate Gini.
mata:
real scalar aV_Gini_e(
	real scalar aggrGini,
	real scalar mu_z,
	real scalar mu_zy,
	real scalar var_z,
	real scalar var_zy,
	real scalar cov_z_zy,
	real scalar aV_aggrGMD,
	real scalar aC_aggrGMD_Mz,
	real scalar aC_aggrGMD_Mzy
)
{
	real scalar aux, aux2, aux3, aux4, aux5, aV_Gini
	
	aux = ((aggrGini / mu_z)^2) * var_z + ((aggrGini / mu_zy)^2) * var_zy
	aux2 = (1 / (4 * mu_z^2 * mu_zy^2)) * aV_aggrGMD
	aux3 = 2 * (aggrGini^2 / (mu_z * mu_zy)) * cov_z_zy
	aux4 = (aggrGini / (mu_z^2 * mu_zy)) * aC_aggrGMD_Mz
	aux5 = (aggrGini / (mu_z * mu_zy^2)) * aC_aggrGMD_Mzy
	
	aV_Gini = aux + aux2 + aux3 - aux4 - aux5
	
	return(aV_Gini)
}

end


* Calculates and returns the asymptotic variance of the Within-group inequality term.
mata:
real scalar aV_Gw_e(
	real scalar b_giniW,
	real scalar mu_z,
	real scalar mu_zy,
	real scalar var_z,
	real scalar var_zy,
	real scalar cov_z_zy,
	real matrix adjGMD_vec,
	real matrix aV_adjGMD_vec,
	real matrix aC_adjGMD_Mz_vec,
	real matrix aC_adjGMD_Mzy_vec
)
{	
	real scalar term1, term2, term3, term4, term5, term6, term7
	real scalar len, i, j, k, sum_sqrt, aux
	real matrix auxMat, auxMat2
	
	len = rows(adjGMD_vec)
	
	term1 = ((b_giniW / mu_z)^2) * var_z
	term2 = ((b_giniW / mu_zy)^2) * var_zy
	
	term3 = 0
	term5 = 0
	term6 = 0
	for (k = 1; k <= len; k++) {
		if (adjGMD_vec[k] > 0) {
			
			aux = b_giniW / (2 * mu_zy * mu_z * adjGMD_vec[k]) * aV_adjGMD_vec[k]
			term3 = term3 + aux
			
			aux = (b_giniW / mu_z)^(1.5) * sqrt(2/(mu_zy * adjGMD_vec[k])) * aC_adjGMD_Mz_vec[k]
			term5 = term5 - aux
			
			aux = (b_giniW / mu_zy)^(1.5) * sqrt(2/(mu_z * adjGMD_vec[k])) * aC_adjGMD_Mzy_vec[k]
			term6 = term6 - aux
		}
	}
	
	term4 = 2 * (b_giniW^2) / (mu_z * mu_zy) * cov_z_zy
	
	term7 = 0
	for (i = 1; i <= len; i++) {
		for (j = 1; j <= len; j++) {
			if (j == i) continue
			
			aux = (2 * b_giniW) / (mu_z * mu_zy) * sqrt(adjGMD_vec[i] * adjGMD_vec[j])
			term7 = term7 - aux
		}
	}
	
	aV_Gw = term1 + term2 + term3 + term4 + term5 + term6 + term7
	
	return(aV_Gw)
}

end


* Wrapper that calculates and returns the asymptotic variance of the 
* Between-group inequality term.
mata:
real scalar aV_Gb_e(
	real scalar b_Gb,
	real scalar mu_z,
	real scalar mu_zy,
	real scalar var_z,
	real scalar var_zy,
	real scalar cov_z_zy,
	real matrix adjGMD_vec,
	real matrix aV_adjGMD_vec,
	real matrix aC_adjGMD_Mz_vec,
	real matrix aC_adjGMD_Mzy_vec,
	real scalar aV_Theta,
	real scalar aC_Theta_Mz,
	real scalar aC_Theta_Mzy,
	real matrix aC_Theta_adjGMD_vec
)
{
	real scalar term1, term2, term3, term5, term6, term7
	
	term1 = ((b_Gb / mu_z)^2) * var_z
	term2 = ((b_Gb / mu_zy)^2) * var_zy
	term3 = aV_Theta / ((2 * mu_z * mu_zy)^2)
	term5 = 2 * (b_Gb^2) * cov_z_zy / (mu_z * mu_zy)
	term6 = - b_Gb * aC_Theta_Mz / (mu_z^2 * mu_zy)
	term7 = - b_Gb * aC_Theta_Mzy / (mu_z * mu_zy^2)
	
	term_vec = auxLoops(b_Gb, mu_z, mu_zy, adjGMD_vec, aV_adjGMD_vec, aC_adjGMD_Mz_vec, aC_adjGMD_Mzy_vec, aC_Theta_Mz, aC_Theta_adjGMD_vec)
	
	term11 = auxF11(mu_z, mu_zy, adjGMD_vec)
	
	aV_Gb = term1 + term2 + term3 + term_vec[1] + term5 + term6 + term7 + term_vec[2] + term_vec[3] + term_vec[4] + term11
	
	return(aV_Gb)
}

end


* Auxiliary function that calculates and returns terms 4, 8, 9 and 10
* required to obtain the asymptotic variance of the Between-group term.
* Called inside aV_Gb_e.
mata:
real matrix auxLoops(
	real scalar b_Gb,
	real scalar mu_z,
	real scalar mu_zy,
	real matrix adjGMD_vec,
	real matrix aV_adjGMD_vec,
	real matrix aC_adjGMD_Mz_vec,
	real matrix aC_adjGMD_Mzy_vec,
	real scalar aC_Theta_Mz,
	real matrix aC_Theta_adjGMD_vec
)
{
	real scalar i, j, k, l, sum_sqrt, coeff, aux
	real scalar fourthAux, eightAux, ninthAux, tenthAux
	real scalar term4, term8, term9, term10
	real matrix resTerms
	
	resTerms = J(4, 1, .)
	len = rows(adjGMD_vec)
	
	fourthAux = 0
	for (i = 1; i <= len; i++) {
		
		aux = 0
		for (j = 1; j <= len; j++) {
			if (j == i) continue
			
			if (adjGMD_vec[j] > 0) {
				aux = aux + sqrt(adjGMD_vec[j])
			}
		}
		
		if (adjGMD_vec[i] > 0) {
			fourthAux = fourthAux + ((aux / sqrt(adjGMD_vec[i]))^2) * aV_adjGMD_vec[i]
		}
	}
	
	term4 = (1/((2 * mu_z * mu_zy)^2)) * fourthAux
	
	eightAux = 0
	ninthAux = 0
	tenthAux = 0
	for (k = 1; k <= len; k++) {
		
		if (adjGMD_vec[k] > 0) {
			sum_sqrt = 0
			
			for (l = 1; l <= len; l++) {
				if (l == k) continue
				
				if (adjGMD_vec[l] > 0) {
					sum_sqrt = sum_sqrt + sqrt(adjGMD_vec[l])
				}
			}
			
			coeff = sum_sqrt / sqrt(adjGMD_vec[k])
			
			eightAux = eightAux + coeff * aC_adjGMD_Mz_vec[k]
			ninthAux = ninthAux + coeff * aC_adjGMD_Mzy_vec[k]
			tenthAux = tenthAux + coeff * aC_Theta_adjGMD_vec[k]
		}
	}
	
	term8 = eightAux * b_Gb / (mu_z^2 * mu_zy)
	term9 = ninthAux * b_Gb / (mu_z * mu_zy^2)
	term10 = tenthAux * (-1 / (2 * mu_z^2 * mu_zy^2))
	
	resTerms[1] = term4
	resTerms[2] = term8
	resTerms[3] = term9
	resTerms[4] = term10
	
	return(resTerms)
}

end


* Auxiliary function that calculates term 11 required to obtain the
* asymptotic variance of the Between-group term.
* Called inside aV_Gb_e.
mata: 
real scalar auxF11(
	real scalar mu_z,
	real scalar mu_zy,
	real matrix adjGMD_vec
)
{	
	real scalar i, j, k, l, sum_i, sum_j, cross_term, aux
	real scalar term11
	
	len = rows(adjGMD_vec)
	
	aux = 0
	for (k = 1; k <= len; k++) {
		if (adjGMD_vec[k] <= 0) continue
		
		sum_i = 0
		for (i = 1; i <= len; i++) {
			if (i == k) continue
			
			if (adjGMD_vec[i] > 0) {
				sum_i = sum_i + sqrt(adjGMD_vec[i])
			}
		}
		
		for (l = 1; l <= len; l++) {
			if (l == k | adjGMD_vec[l] <= 0) continue
			
			sum_j = 0
			for (j = 1; j <= len; j++) {
				if (j == l) continue
				
				if (adjGMD_vec[j] > 0) {
					sum_j = sum_j + sqrt(adjGMD_vec[j])
				}
			}
			
			cross_term = sqrt(adjGMD_vec[k] * adjGMD_vec[l]) * sum_i * sum_j
			
			aux = aux + cross_term
		}
	}
	
	term11 = aux * (-1 / (mu_z^2 * mu_zy^2))
	
	return(term11)
}

end


** Calculates the biased Between-group inequality term.
mata:
real scalar b_Gb(
	real matrix adjGMD_vec,
	real scalar mu_z,
	real scalar mu_zy,
	real scalar Theta
)
{	
	real scalar i, j, sum_sqrt
	
	len = rows(adjGMD_vec)
	
	sum_sqrt = 0
	for (i = 1; i <= len; i++) {
		for (j = 1; j <= len; j++) {
			if (j == i) continue
			
			if (adjGMD_vec[i] > 0 & adjGMD_vec[j] > 0) {
				sum_sqrt = sum_sqrt + sqrt(adjGMD_vec[i] * adjGMD_vec[j])
			}
		}
	}
	
	b_Gb = (1/(2 * mu_z * mu_zy)) * (Theta - sum_sqrt)
	
	return(b_Gb)
}

end


* Calculates and returns the asymptotic variance of the Within-group 
* inequality share, which is equal to the asymptotic variance
* of the Between-group share.
mata:
real scalar aV_GwGb_share_e(
	real scalar aggrGini,
	real scalar giniW,
	real scalar aV_Gw,
	real scalar aV_Gb,
	real scalar aC_Gw_Gb
)
{
	real scalar aux, aux2, aux3
	real scalar aV_GwGb_share
	
	aux = ((aggrGini - giniW)^2) * aV_Gw
	aux2 = (giniW^2) * aV_Gb
	aux3 = 2 * (aggrGini - giniW) * giniW * aC_Gw_Gb
	
	aV_GwGb_share = (aux + aux2 - aux3) / (aggrGini^4)
	
	return(aV_GwGb_share)
}

end


* Adjusts precision of Monte Carlo integration based on given
* coverage parameter and ensures that the values aren't too high.
mata:
real matrix int_precision(
	real scalar thresholdSize,
	real scalar N
)
{	
	real scalar aux
	real matrix results
	
	results = J(2, 1, .)
	
	// Checks numDraws.
	if (N <= thresholdSize) {
		my_numDraws = N
	}
	
	else {
		my_numDraws = 1000
	}
	
	// Adjusts numIter as needed.
	if (N > thresholdSize) { // Monte Carlo method will be used iff. this is True.
		aux = ceil(N / my_numDraws)
	}
	
	else {
		aux = 1
	}
	
	// Safety checks.
	if (aux > 500) {
		my_numIter = 500
	}
	
	else {
		my_numIter = aux
	}
	
	if (aux < 1) {
		my_numIter = 1
	}
	
	results[1] = my_numDraws
	results[2] = my_numIter
	
	return(results)
}

end