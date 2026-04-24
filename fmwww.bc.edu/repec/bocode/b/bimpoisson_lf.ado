*! 2.1.0 Stephen P. Jenkins and Fernando Rios-Avila, March 2026


********************************************************************************
* Bivariate Mixed-Poisson Regression using Simulated Maximum Likelihood
* Implementation of Munkin & Trivedi (1999). Simulated maximum likelihood 
* 		estimation of multivariate mixed-Poisson regression
* 		models, with application. The Econometrics Journal 2, 29-48.
* 		https://doi.org/10.1111/1368-423X.00019
*
* evaluator function for MSL using sampling function
********************************************************************************

program define bimpoisson_lf

	version 15

	args lnf xb_1 xb_2  		/// Covariates
		 ln_sig_1 ln_sig_2 		/// sigma1 and sigma2
		 arho_s            		/// correlation
	
	qui: {
				
		local nsim       = $nsim___ 
		local antithetic = $antithetic___
		local bias       = $bias___
		local rho_sf     = $rho_sf___	// Rho in sampling function (default = 0)
 		set rngstate     $rngstate___   // For replication (if uniform draws)
 		local sig_1 exp(`ln_sig_1' ) 	// Transformation of sigma and rho
		local sig_2 exp(`ln_sig_2' ) 
		local rho  tanh(`arho_s')
		
		tempvar p1 p2 
		tempvar f12 g12
		tempvar e1 e2  v1 v2 
		
		tempvar local_lnf mu_1 mu_2 agg_lnf v1 v2
		
		gen double `local_lnf' = 0
		gen double `mu_1'      = 0
		gen double `mu_2'      = 0
		gen double `agg_lnf'   = 0
		gen double `f12' = .
		gen double `g12' = .
		// Other needed variables
		tempvar r1 r2
		gen double `r1'  = .
		gen double `r2'  = .
		gen double `e1'  = .
		gen double `e2'  = .
		gen double `v1'  = .
		gen double `v2'  = .
		*gen double `v1' = .
		*gen double `v2' = .
 		gen double `p1'  = .
		gen double `p2'  = .

		local S = `nsim'

		local h = 0

		if `antithetic' == 0 local SS = `S'
		if `antithetic' == 1 local SS = `S'*2
		
		tempvar px1
		gen double `px1' = .
		
		forvalues s = 1/`S' {
			
			// First get random draws for two normals via Halton/uniform draws 
			//		They have same varnames (but different values)
			//		so don't need to distinguish below in defining `r1', `r2'

			if `antithetic' == 0  {

				local h = `h' + 1

				replace `v1' =  invnormal(${dr1_`s'__}) 
				replace `v2' = (`rho_sf')*`v1' ///
								+ sqrt(1-(`rho_sf')^2)*invnormal(${dr2_`s'__}) 

				replace `e1' = `sig_1'*`v1'
				replace `e2' = `sig_2'*`v2'

				// Obtained standardized versions
				*replace `v1' = `e1'/`sig_1'
				*replace `v2' = `e2'/`sig_2'

				// get the density g(e1,e2)
				replace `g12'= -ln(2*_pi*`sig_1'*`sig_2'*sqrt(1-(`rho_sf')^2)) + ///
								  -(1/(2*(1-(`rho_sf')^2))) * ( `v1'^2 - 2*(`rho_sf')*`v1'*`v2'+`v2'^2 ) 
				// get other components
				replace `mu_1' = exp(`xb_1'+`e1')
				replace `mu_2' = exp(`xb_2'+`e2')
				// Individual Proabilities
				replace `p1' = $ML_y1 * ln(`mu_1') - `mu_1' - lngamma($ML_y1+1)
				replace `p2' = $ML_y2 * ln(`mu_2') - `mu_2' - lngamma($ML_y2+1)
				// Joint density
				replace  `f12'= -ln(2*_pi*`sig_1'*`sig_2'*sqrt(1-(`rho')^2)) + ///
								  -(1/(2*(1-(`rho')^2))) * ( `v1'^2 - 2*(`rho')*`v1'*`v2'+`v2'^2 )  			
				// Putting it all together
				replace `local_lnf' = exp(`p1')*exp(`p2')*exp(`f12'-`g12')
				if `bias' == 1 {
					tempvar f12_`h'
					gen double `f12_`h'' = exp(`p1')*exp(`p2')*exp(`f12'-`g12')
				}	
				replace `agg_lnf' = `agg_lnf' + `local_lnf'		
			}
			if `antithetic' == 1  {		
				
				forvalues j = 1/2 {
					
					local h = `h' + 1	
					
					if `j' == 1 {
						
						replace `v1' =  invnormal(${dr1_`s'__}) 
						replace `v2' = (`rho_sf')*`v1' ///
								+ sqrt(1-(`rho_sf')^2)*invnormal(${dr2_`s'__})
						
						replace `e1'=`sig_1'*`v1'
						replace `e2'=`sig_2'*`v2'
					}
					else if `j' == 2 {
						
						replace `v1' =  invnormal(1 - ${dr1_`s'__}) 
						replace `v2' = (`rho_sf')*`v1' ///
							+ sqrt(1-(`rho_sf')^2)*invnormal(1 - ${dr2_`s'__})
						
						replace `e1'=`sig_1'*`v1'
						replace `e2'=`sig_2'*`v2'												
					}
					
					// Obtained standardized versions

										// get the density
					replace `g12'= -ln(2*_pi*`sig_1'*`sig_2'*sqrt(1-(`rho_sf')^2)) + ///
								  -(1/(2*(1-(`rho_sf')^2))) * ( `v1'^2 - 2*(`rho_sf')*`v1'*`v2'+`v2'^2 ) 
					// get other components
					replace `mu_1' = exp(`xb_1'+`e1')
					replace `mu_2' = exp(`xb_2'+`e2')
					// Individual probabilities
					replace `p1' = $ML_y1 * ln(`mu_1') - `mu_1' - lngamma($ML_y1+1)
					replace `p2' = $ML_y2 * ln(`mu_2') - `mu_2' - lngamma($ML_y2+1)
					// Joint density
					replace  `f12'= -ln(2*_pi*`sig_1'*`sig_2'*sqrt(1-(`rho')^2)) + ///
									  -(1/(2*(1-(`rho')^2))) * (`v1'^2 - 2*(`rho')*`v1'*`v2'+`v2'^2 )  			
					
					// Putting it all together
					
					replace `local_lnf' = exp(`p1')*exp(`p2')*exp(`f12'-`g12')
					
					if `bias' == 1 {
						tempvar f12_`h'
						gen double `f12_`h''= exp(`p1')*exp(`p2')*exp(`f12'-`g12')
					}	
					
					replace `agg_lnf' = `agg_lnf' + `local_lnf'
				}
			}

			local SS = `S'* (2^`antithetic')

 		}
		if `bias' == 1 {
			tempvar lnf2
			gen double `lnf2' = 0
			forvalues s = 1/`SS'	 {
				replace `lnf2' = `lnf2' + (`f12_`s'' - `agg_lnf'/`SS')^2
			}
			replace `lnf2' = `lnf2'/(`agg_lnf')^2
 			replace `lnf'  = log(`agg_lnf'/`SS') + 0.5*`lnf2'
 		}
		else replace `lnf' = log(`agg_lnf'/`SS')
		
	}

end
