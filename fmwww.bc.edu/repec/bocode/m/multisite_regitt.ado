program multisite_regITT, eclass
    version 14.2
	syntax varlist(min=3 max=3 numeric) [if] [aweight] [,controls(varlist numeric) mediators(varlist numeric) y0 fs(varlist numeric min=1 max=1)]
    preserve

qui{
	// Display an error and exit the command in cases...
	if "`controls'" == "" & "`mediators'" == "" & "`y0'" == "" & "`fs'" == ""{
		di as error "Error: No ITTs predictor specified."
        exit 200 
	}
	
	// Drop variables from memory. 
	capture drop mediators
	capture drop controls
	
	// Tokenize varlist elements
	tempvar outcome instrument site 
	tokenize `varlist'
	gen `outcome'=`1'
	gen `instrument'=`2'
	gen `site'=`3'
	
	*Keeping if sample
if `"`if'"' != "" {
keep `if'
}	
	// In case missing observations
 	drop if `outcome'==.
	
	// Drop site lack of observations
	bys `site': egen multisiteITT_n1s = total(`instrument')
	bys `site': gen multisiteITT_ns = _N
	gen multisiteITT_n0s = multisiteITT_ns - multisiteITT_n1s
	drop if multisiteITT_n1s < 2 | multisiteITT_n0s < 2
	drop multisiteITT_ns multisiteITT_n1s multisiteITT_n0s
	
	// Group Xs and Fs
	local mediators `mediators'
	if "`fs'" != "" {
		local mediators "`mediators' `fs'"
	}
	
	// Count number of variables 
	local num_controls : word count `controls'
	local num_med : word count `mediators'
	local num_var = `num_controls' + `num_med'
	if "`y0'" != ""{
		local num_var = `num_var' + 1
	}
	
	if "`y0'" != ""{
		local varnames = "`mediators' `y0' `controls'"
		}
	else{
		local varnames = "`mediators' `controls'"
		}
		
	// Calculate Site Level Basics
* For xxp: Estimated X_s,k (FS_s), Y_0s. 
* For correction: r^2 terms (3 for each m_k) and c_(m_k1,m_k2) terms ((k*(k-1)/2)*2)

	levelsof `site', local(levels)
    local num_site : word count `levels'
	matrix X = J(`num_site',`num_var',0)
	
	* index for site to start
	local s = 1 
	* list of matrices to be deleted
	local matlist
	* weight vector
	matrix ws = J(`num_site',1,0)
	* weight vector
	matrix wtildes = J(`num_site',1,0)
	* ITTs vector
	matrix ITTs = J(`num_site',1,0)	
	* site index vector
	matrix site = J(`num_site',1,0)
	* robust variance of ITT
	matrix V_rob_ITT = J(`num_site',1,0)	
	
	* loop over sites
	foreach y of local levels {		
		sum `outcome' [`weight' `exp'] if `instrument'==1 & `site'==`y'
		scalar Ybar1=r(mean)
		scalar nt=r(N)
		sum `outcome' [`weight' `exp'] if `instrument'==0 & `site'==`y'
		scalar Ybar0=r(mean)
		scalar nc=r(N)
		scalar n_s=nt+nc

		scalar ATE_s=Ybar1 - Ybar0
		gen multisiteITT_diff1treat= (`outcome'-Ybar1)^2 if `instrument'==1 & `site'==`y'
		gen multisiteITT_diff1control= (`outcome'-Ybar0)^2 if `instrument'==0 & `site'==`y'
		summ  multisiteITT_diff1treat [`weight' `exp']
		scalar rY1S=(nt/(nt-1))*r(mean)
		summ multisiteITT_diff1control [`weight' `exp']
		scalar rY0S=(nc/(nc-1))*r(mean)
		scalar V_rob_s=(1/nt)*rY1S+(1/nc)*rY0S
		drop multisiteITT_diff*
		
		// ws fill
		matrix ws[`s',1] = n_s/_N
		// ws tilde fill 
		matrix wtildes[`s',1] = n_s/(_N/`num_site')
		// ITTs fill 
		matrix ITTs[`s',1] = Ybar1- Ybar0	
		// site index fill 
		matrix site[`s',1] = `y'
		// robust variance of ITT fill
		matrix V_rob_ITT[`s',1] = V_rob_s
	
		* Variance-covariance matrix of regressors for site y:  V_Xs
		matrix V_Xs_`y' = J(`num_var',`num_var',0)
		* Covariance matrix for site y : Cov(\hat{X}s, \hat{ITT}s)
		matrix Cov_Xs_ITTs_`y' = J(`num_var',1, 0)

		/* Loop over mediators to calculate all the variances and covariances matrices needed. */
		if "`mediators'" != ""{
		
			* mediator track index
			local i = 1
			 
			// Outer loop over mediator
			foreach med of local mediators{
				
					capture drop  c_m_y_0 c_m_y_1
				
					// Elements
					sum `med' [`weight' `exp'] if `instrument'==0 & `site'==`y'
					scalar mean_med0=r(mean)
					sum `med' [`weight' `exp'] if `instrument'==1 & `site'==`y'
					scalar mean_med1=r(mean)
					
					gen c_m_y_0 = (`med' - mean_med0)*(`outcome' - Ybar0) if `instrument'==0 & `site'==`y'
					summ c_m_y_0 [`weight' `exp'] if `instrument'==0 & `site'==`y'
					scalar cmy0=r(mean)
					gen c_m_y_1 = (`med' - mean_med1)*(`outcome' - Ybar1) if `instrument'==1 & `site'==`y'
					summ c_m_y_1 [`weight' `exp'] if `instrument'==1 & `site'==`y'
					scalar cmy1=r(mean)
					
					// Covariance between ITT_Mk and ITT
					scalar cov_med_ITT_s = cmy0*(1/(nc-1)) + cmy1*(1/(nt-1))
					matrix Cov_Xs_ITTs_`y'[`i',1] = cov_med_ITT_s
					
					// Xs: Estimated Xs,i for site s and mediator i.
					matrix X[`s',`i'] = mean_med1-mean_med0	
				
				* pair mediator track index
				local j=1
				
				/* Inner loop over mediator: combinations with i fixed */ 
				foreach med_prime of local mediators{
					if `j'< `i'{	
					}
					else{
						
						capture drop c_m_mp_0 c_m_mp_1 
					
						sum `med_prime' [`weight' `exp'] if `instrument'==0 & `site'==`y'
						scalar mean_medp0=r(mean)
						sum `med_prime' [`weight' `exp'] if `instrument'==1 & `site'==`y'
						scalar mean_medp1=r(mean)

						gen c_m_mp_0 = (`med' - mean_med0)*(`med_prime' - mean_medp0) if `instrument'==0 & `site'==`y'
						summ c_m_mp_0 [`weight' `exp'] if `instrument'==0 & `site'==`y'
						scalar cmmp0=r(mean)
						gen c_m_mp_1 = (`med' - mean_med1)*(`med_prime' - mean_medp1) if `instrument'==1 & `site'==`y'
						summ c_m_mp_1 [`weight' `exp'] if `instrument'==1 & `site'==`y'
						scalar cmmp1=r(mean)
						
						// Correction matrix element: cov(m_i,m_j) covariance between mediators
						matrix V_Xs_`y'[`i',`j'] = cmmp0*(1/(nc-1)) + cmmp1*(1/(nt-1))
						matrix V_Xs_`y'[`j',`i'] =  V_Xs_`y'[`i',`j']
						
						if V_Xs_`y'[`i',`j'] == .{
							* check if somesite has something wrong.
							di "site `y' something wrong..."
							exit 300
						}
						
					}
					
				* move on to next mediator to be paried with i	
				local j = `j'+1 
				}
			/* End inner loop with combinations */
				
			local i = `i' +1
			}
			/* End Outer loop with i of mediators */
		}
	
		/* Loop over mediators + y0 if y0 specified. */
		if "`y0'" ! = ""{
			* Variance-covariance matrix of regressors for site y:  V_Xs
			matrix V_Xs_`y' [`num_med'+1, `num_med'+1 ] = rY0S/nc
			* Covariance vector for site y : Cov(\hat{X}s, \hat{ITT}s)
			matrix Cov_Xs_ITTs_`y' [`num_med' +1 , 1 ] = - rY0S/nc
			* Estimates vector
			matrix X[`s',`num_med' +1 ] = Ybar0

			/* Loop over mediators for filling the last column/row of var-cov of regressors */ 
			* track index for mediators to be combined with y0
			local m=1
			
			if "`mediators'" != ""{
			foreach med of local mediators{
						capture drop c_m_y0_0
						
						sum `med' [`weight' `exp'] if `instrument'==0 & `site'==`y'
						scalar mean_med0=r(mean)

						gen c_m_y0_0 = (`med' - mean_med0)*(`outcome' - Ybar0) if `instrument'==0 & `site'==`y'
						summ c_m_y0_0 [`weight' `exp'] if `instrument'==0 & `site'==`y'
						scalar cmy00=r(mean)

						matrix V_Xs_`y'[`num_med'+1,`m'] = cmy00*(1/(nc-1))
						matrix V_Xs_`y'[`m',`num_med'+1] =  V_Xs_`y'[`num_med'+1,`m']
						local m=`m'+1	
						
			}
		}
		}
		/* End loop over y0 */ 
		
		// Variance not needed to be estimated:unemployment rate in site s: zero variance and zero variance-covariance 
		// diff from y0: only obs from control group, proxy for treat group.
		if "`controls'" ! = ""{
			* index for control
			local i = 1
			foreach con of local controls{
				sum `con'  [`weight' `exp'] if `site' == `y'
				* add controls to estimates (regressor) vector 
				matrix X[`s',`num_var'-`num_controls'+`i'] = r(mean)
				* IMPUTE 0S TO THE VARIANCE COVARIANCE MATRIX
				local i = `i'+1	
			}
		}
		
		// Upate track index （site loop)
		local s = `s'+1
		local matlist "`matlist' Cov_Xs_ITTs_`y' V_Xs_`y'"
	}
/* End loop over site */
	local total_obs = _N

	* Matrix num_site times 1, keep total observations. 
	matrix N = J(`num_site',1,_N)
	* Merge vector to matrix dataset, site level: ITT estimates, weight, site identifier, total obs, regressors(estimates)
	matrix data =  ITTs, ws, site, N, V_rob_ITT, X
	* Transform matrix to data
	matrix list data
	svmat data
	keep data*
	rename data1 ITTs
	rename data2 ws
	rename data3 site
	rename data4 N
	rename data5 V_rob_ITT

	* ITT demeaned
	sum ITTs [aw=ws]
	scalar temp= r(mean)
	gen forITT = ITTs - temp
	scalar avg_ITT = r(mean)
	
	* Estimated variance of ITT
    gen sigma2_ITT= forITT^2-V_rob_ITT
	sum sigma2_ITT [aw=ws]
	scalar sigma2_ITT_est = r(sum)
	
	* Regressor demeaned: fordata
	* t: column no. of last regressor in the dataframe
	local t = `num_var'+5
	forvalues i = 6(1) `t' {
		sum data`i' [aw = ws]
		scalar temp = r(sum)
		gen fordata`i' = data`i' - temp
	}
	
	* demeaned product
	matrix vecaccum cross_X_ITT = forITT fordata* [iw=ws], noconstant
	
	// Compute the correction terms: sum over variance-covariance matrix with weight 
	matrix correction_VXs = J(`num_var',`num_var',0)
	matrix correction_Cov_Xs_ITTs = J(`num_var',1,0)
	local s = 1
	foreach y of local levels{
		matrix correction_VXs = ws[`s',1]*V_Xs_`y'+ correction_VXs
		matrix correction_Cov_Xs_ITTs = ws[`s',1]*Cov_Xs_ITTs_`y' + correction_Cov_Xs_ITTs
		local s = `s'+1
	}

	matrix accum xxp = fordata* [iw=ws], noconstant
	
	// Compute the estimated variance covariance of beta estimator with above matrices. 
	matrix beta = J(`num_var',1,0)
	matrix xxp2 = xxp - correction_VXs
	matrix xxpi = inv(xxp2)
	matrix xyp = cross_X_ITT' - correction_Cov_Xs_ITTs
	matrix beta = xxpi* xyp
	
	// Coding the analytical variance of beta estimator. 
	matrix A= xxp2
	matrix B= xyp
	
	// Coding RITTX
	matrix R2=beta'*xxp2*beta/sigma2_ITT_est
	
	// Coding the phi matrices for each site
	local s = 1 
	
	foreach y of local levels{
	
		* Extract demeaned Xs for site y
		mkmat fordata* if site == `y', matrix(forX_`y')
		matrix forX_`y' = forX_`y''
		matrix phi_2s_`y' =( forX_`y'*forX_`y'' - V_Xs_`y') * ws[`s',1]* `num_site' 
		
		* Extract demeaned ITTs for site y
		mkmat forITT if site == `y', matrix(forITT_`y')
		matrix phi_3s_`y' = ( forX_`y'*forITT_`y' - Cov_Xs_ITTs_`y') * ws[`s',1]* `num_site'
		
		* phi4 matrix for site y : phi 4, s
		matrix phi_4s_`y' = - xxpi* phi_2s_`y' *xxpi*B + xxpi * phi_3s_`y'
		matrix phi_4s_`y' = phi_4s_`y''
		
		* Create site-level matrix of phi4s
		if `s' == 1{
			matrix phi_4s = phi_4s_`y'
		}
		else{
			matrix phi_4s = phi_4s\ phi_4s_`y'
		}
		
		local s = `s' +1
		local matlist "`matlist' forX_`y' phi_2s_`y' forITT_`y' phi_3s_`y' phi_4s_`y'"
    
	}
	drop *
 
	* Site-level data of phi4: Each row represents phi4s of a site and k columns
	svmat phi_4s
	
	* Generate Covariance of betas 
	// V_beta^ITT: sample variance of phi_4s
	matrix accum V_beta = *, deviations noconstant
	matrix V_beta = V_beta /((r(N)-1)*r(N))
	
	* Display Beta vector and Var-Cov matrix
	matrix list beta
	matrix list V_beta
	
	// Output the Final Table
	* Number of Sites and Total Observations
	local num_sites = `num_site'
	local k = rowsof(beta)

	* Create the Output Matrix
	matrix mat_res_XX = J(`k', 6, .)
	* Loop over betas to display 
	forval i = 1/`k' {
		local var: word `i' of `varnames'
		if `i' <= `num_med'{
			if `i' == `num_med' & "`fs'"!= ""{
				local rownames "`rownames' FS"
			}
			else{
				local rownames "`rownames' ITT_`var'"
			}
		}
		else if `i' == `num_med' +1 & "`y0'" != ""{
				local rownames "`rownames' Y0"
		}
		else{
			local rownames "`rownames' `var'"
		}
		
		matrix mat_res_XX[`i', 1] = beta[`i', 1] // Estimate
		matrix mat_res_XX[`i', 2] = V_beta[`i', `i']^(1/2)  // Standard Error
		matrix mat_res_XX[`i', 3] = beta[`i', 1] - 1.96 * V_beta[`i', `i']^(1/2)  // Lower bound
		matrix mat_res_XX[`i', 4] = beta[`i', 1] + 1.96 * V_beta[`i', `i']^(1/2)  // Upper bound
 		matrix mat_res_XX[`i', 5] = `num_sites'  // Number of Sites
 		matrix mat_res_XX[`i', 6] = `total_obs'  // Total Observations
	}
	
	matrix rownames mat_res_XX = `rownames'
	matrix colnames mat_res_XX = "Estimate" "SE"  "95% LB" "95% UB" "# Sites" "# Units"
}
	* Save Beta vector, Var-Cov matrix, R2, etc. 
	ereturn clear
	ereturn matrix coefficients = beta
	ereturn matrix variance = V_beta
	ereturn scalar R2 = R2[1,1]
	ereturn scalar N = `total_obs'
	ereturn scalar Sites = `num_sites'
	
	* Delete site-specific matrices in memory
	capture matrix drop `matlist'
	
	* Display the Table
	di "{hline 80}"
	di _skip(13) "{bf:Regression of ITTs on explanatory variables}"
	di "{hline 80}"
    noisily matlist mat_res_XX, border(rows)
	di as text "{it:R-squared of the OLS regression of ITT on explanatory variables} " R2[1,1]
	di as text "The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899)."
    restore
end
