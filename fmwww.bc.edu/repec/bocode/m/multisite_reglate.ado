program multisite_regLATE, eclass
    version 14.2
	syntax varlist(min=4 max=4 numeric) [if] [aweight] [, fs y0 controls(varlist numeric) mediators(varlist numeric)]
    preserve
	
	// Display an error and exit the command in cases...
	if "`controls'" == "" & "`mediators'" == "" & "`y0'" == "" & "`fs'" == ""{
		di as error "Error: No LATEs predictor specified."
        exit 200 
	}

qui{
	// Drop variables from memory. 
 	capture drop mediators
 	capture drop controls
	
	// Store the four variables properly. 
	local v=1
	foreach var of local varlist{
		 if `v' == 1 {
				local outcome `var'
			}
			else if `v' == 2 {
				local treatment `var'
			}
			else if `v' == 3 {
				local instrument `var'
			}
			else if `v' == 4 {
				local site `var'
			}
		local v = `v' + 1
    }
	
	// Count number of explanatory variables
	local num_controls : word count `controls'
	local num_med : word count `mediators'
	local num_var = `num_controls' + `num_med'

	local prior = 0
	if "`y0'" != ""{
		local num_var = `num_var' + 1	
		local prior = `prior' + 1
	}
	if "`fs'" != ""{
		local num_var = `num_var' + 1	
		local prior = `prior' + 1
	}
	
	// Store names of variables for future display 
	if "`fs'" != ""{
		if "`y0'" != ""{
			local varnames = "`fs' `y0' `mediators' `controls'"
		}
		else{
			local varnames = "`fs' `mediators' `controls'"
		}
	}
	else{
		if "`y0'" != ""{
			local varnames = "`y0' `mediators' `controls'"
		}
		else{
			local varnames = "`mediators' `controls'"
		}
	}
	
	// Keeping if sample
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
		
	// Calculate ITT and FS 
	levelsof `site', local(levels)
    local num_site : word count `levels'

	* index for site to start
	local s = 1 
	* weight vector
	matrix ws = J(`num_site',1,0)
	* weight vector
	matrix wtildes = J(`num_site',1,0)
	* FSs vector
	matrix FSs = J(`num_site',1,0)	
	* ITTs vector
	matrix ITTs = J(`num_site',1,0)	
	* site index vector
	matrix site = J(`num_site',1,0)
	
	* loop over sites
	local s=1
	foreach y of local levels {
		
		sum `treatment' [`weight' `exp'] if `instrument'==1 & `site'==`y'
		scalar Dbar1=r(mean)
		scalar nt=r(N)
		sum `treatment' [`weight' `exp'] if `instrument'==0 & `site'==`y'
		scalar Dbar0=r(mean)
		
		sum `outcome' [`weight' `exp'] if `instrument'==1 & `site'==`y'
		scalar Ybar1=r(mean)
		scalar nt=r(N)
		sum `outcome' [`weight' `exp'] if `instrument'==0 & `site'==`y'
		scalar Ybar0=r(mean)
		
		scalar nc=r(N)
		scalar n_s=nt+nc
		
		// ws fill
		matrix ws[`s',1] = n_s/_N
		// ws tilde fill 
		matrix wtildes[`s',1] = n_s/(_N/`num_site')
		// FSs fill 
		matrix FSs[`s',1] = Dbar1- Dbar0	
		// ITTs fill 
		matrix ITTs[`s',1] = Ybar1- Ybar0	
		// site index fill 
		matrix site[`s',1] = `y'
		
		local s=`s'+1
	}

	local total_obs = _N
	matrix data = ITTs, FSs, ws, site, wtildes
	svmat data 
	rename data1 ITTs
	rename data2 FSs
	rename data3 ws
	rename data4 site
	rename data5 wtildes

	// Calculate ITT and FS effects
	sum ITTs [aw=ws]
	scalar ITT= r(mean)
	sum FSs [aw=ws]
	scalar FS= r(mean)
	matrix multiplier = [1 \ -ITT/FS]
	// Calculate influence function of LATEs
	matrix A = ITTs, FSs
	matrix B = A * multiplier
	matrix phi_late = (1/FS) * B
	
	// Matrix of store coefficient of beta estimates
	matrix betas = J(`num_var',2,0)
	
	// When FS specified
	if "`fs'" != ""{			

		local fsi = 1
			
 		* To store the estimates of beta_ITT_med_j
 		multisite_regITT `outcome' `instrument' `site' [`weight' `exp'], fs(`treatment')
		matrix beta = e(coefficients) 
 		matrix betas[`fsi',1]= beta[1,1] 
		matrix phi_itts_`fsi'= phi_4s
				
 		* To store the estimates of beta_FS_med_j
 		multisite_regITT `treatment' `instrument' `site' [`weight' `exp'], fs(`treatment')
 		matrix beta = e(coefficients) 
 		matrix betas[`fsi',2]= beta[1,1] 
 		matrix phi_fss_`fsi'= phi_4s
				
 		* Compute the influence function on LATE
 		matrix phi_lates_`fsi'= phi_itts_`fsi'- (ITT/FS)*phi_fss_`fsi'- betas[`fsi',2]*phi_late	
 		svmat phi_lates_`fsi'
		* V_beta^LATE: sample variance of phi_lates
 		matrix accum V_beta_`fsi'= phi_lates_`fsi', deviations noconstant
 		matrix V_beta_`fsi' = V_beta_`fsi' /((r(N)-1)*r(N))		
		
		}
		
	// When y0 specified
	if "`y0'" != ""{
		
		if "`fs'" != ""{	
			local yi = 2
		}
		else{
			local yi = 1
		}

		* To store the estimates of beta_ITT_y0_j
		multisite_regITT `outcome' `instrument' `site' [`weight' `exp'], y0
		matrix beta = e(coefficients) 
		matrix betas[`yi',1]= beta[1,1] 
		matrix phi_itts_`yi'= phi_4s	
		
		* To store the estimates of beta_FS_y0_j
		multisite_regITT `treatment' `instrument' `site' [`weight' `exp'], y0
		matrix beta = e(coefficients) 
		matrix betas[`yi',2]= beta[1,1] 
		matrix phi_fss_`yi'= phi_4s

		* Compute the influence function on LATE
		matrix phi_lates_`yi'= phi_itts_`yi'- (ITT/FS)*phi_fss_`yi'- betas[`yi',2]*phi_late	
		svmat phi_lates_`yi'
		
		* V_beta^LATE: sample variance of phi_lates
		matrix accum V_beta_`yi'= phi_lates_`yi', deviations noconstant
		matrix V_beta_`yi' = V_beta_`yi' /((r(N)-1)*r(N))
		
		}

	// Loop over mediators
	if "`mediators'" != ""{
		
		* Tracking index of mediator
		local i=1
					
		foreach med of local mediators{
			
			local medi = `prior' + `i' 
			
			* To store the estimates of beta_ITT_med_i
			multisite_regITT `outcome' `instrument' `site' [`weight' `exp'], mediators(`med')
			matrix beta = e(coefficients) 
			matrix betas[`medi',1]= beta[1,1] 
			matrix phi_itts_`medi'= phi_4s
			
			* To store the estimates of beta_FS_med_i
			multisite_regITT `treatment' `instrument' `site' [`weight' `exp'], mediators(`med')
			matrix beta = e(coefficients) 
			matrix betas[`medi',2]= beta[1,1] 
			matrix phi_fss_`medi'= phi_4s
			
			* Compute the influence function on LATE
			matrix phi_lates_`medi'= phi_itts_`medi'- (ITT/FS)*phi_fss_`medi'- betas[`medi',2]*phi_late 
			
			svmat phi_lates_`medi'
		    * V_beta^LATE: sample variance of phi_lates
			matrix accum V_beta_`medi'= phi_lates_`medi', deviations noconstant 
			matrix V_beta_`medi' = V_beta_`medi' /((r(N)-1)*r(N))
			
			* Update tracking index
			local i=`i'+1
		}
	}
	
	// Loop over controls 
	if "`controls'" != ""{
			
			* Tracking index of mediator
			local j=1
						
			foreach con of local controls{
				
				local coni = `prior' +`num_med' + `j' 
				
				* To store the estimates of beta_ITT_med_j
				multisite_regITT `outcome' `instrument' `site' [`weight' `exp'], controls(`con')
				matrix beta = e(coefficients) 
				matrix betas[`coni',1]= beta[1,1] 
				matrix phi_itts_`coni'= phi_4s
				
				* To store the estimates of beta_FS_med_j
				multisite_regITT `treatment' `instrument' `site' [`weight' `exp'], controls(`con')
				matrix beta = e(coefficients) 
				matrix betas[`coni',2]= beta[1,1] 
				matrix phi_fss_`coni'= phi_4s
				
				* Compute the influence function on LATE
				matrix phi_lates_`coni'= phi_itts_`coni'- (ITT/FS)*phi_fss_`coni'- betas[`coni',2]*phi_late	
				svmat phi_lates_`coni'
				* V_beta^LATE: sample variance of phi_lates
				matrix accum V_beta_`coni'= phi_lates_`coni', deviations noconstant
				matrix V_beta_`coni' = V_beta_`coni' /((r(N)-1)*r(N))
				
				* Update tracking index
				local j=`j'+1
			}
		}
	
	// Calculate the cov(late, x) term
	matrix sigma_LATE_x = betas*multiplier
	matrix list sigma_LATE_x
	
	// Display the output table 
	* Number of Sites and Total Observations
	local num_sites = `num_site'
	local k = rowsof(sigma_LATE_x)
	
	* Create the Output Matrix
	matrix mat_res_XX = J(`k', 6, .)
	local rownames `varnames'
}	

	* Loop over betas to display 
	forval i = 1/`k' {
		matrix mat_res_XX[`i', 1] = sigma_LATE_x[`i', 1] // Estimate
		matrix mat_res_XX[`i', 2] = V_beta_`i'[1,1]^(1/2)  // Standard Error 
		matrix mat_res_XX[`i', 3] = sigma_LATE_x[`i', 1] - 1.96 * V_beta_`i'[1,1]^(1/2) // Lower bound
		matrix mat_res_XX[`i', 4] = sigma_LATE_x[`i', 1] + 1.96 * V_beta_`i'[1,1]^(1/2) // Upper bound
 		matrix mat_res_XX[`i', 5] = `num_sites'  // Number of Sites
 		matrix mat_res_XX[`i', 6] = `total_obs'  // Total Observations
	}
	
	matrix rownames mat_res_XX = `rownames'
	matrix colnames mat_res_XX = "Estimate" "SE"  "95% LB" "95% UB" "# Sites" "# Units"

	* Display the Table
	di "{hline 80}"
	di _skip(13) "{bf:Sign of Univariate Regression Coefficients of LATEs on Explanatory Variables}"
	di "{hline 80}"
    noisily matlist mat_res_XX, border(rows)
	di as text "The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899)."
    restore
end
