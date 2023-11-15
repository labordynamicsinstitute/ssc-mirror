program define gmm_ivcloglog
	version 11
	syntax varlist if [fweight iweight pweight],	///
					at(name)						///			// This contains the parameter estimates
					y1(varname)						///
					y2(varlist)						///
					vhatname(string)				///
					order(integer)					///
					[								///
					derivatives(varlist)			///			// Must be optional because -gmm- presumably calls the moment evaluator program multiple times but does not request derivatives every time
					fakederivatives					///
					]
	
	local num_endo : list sizeof y2
	tokenize `varlist'		// Get the names of the variables storing the residual functions
	
	* Reduced form equations ("first stage")
	forval i = 1/`num_endo' {
		local y2_`i' : word `i' of `y2'
		
		tempvar zp_`i'
		local mfeval_reduced`i' ``i''
		matrix score double `zp_`i'' = `at' `if', eq(#`i')				// Get projection
		qui replace `mfeval_reduced`i'' = `y2_`i'' - `zp_`i'' `if'		// Gets returned as evaluated residual function
	}
	
	* Main equation ("second stage") moment functions except for CFs
	tempvar xb expxb
	local mfeval_main ``=`num_endo' + 1''
	matrix score double `xb' = `at' `if', eq(#`=`num_endo' + 1') 
	gen double `expxb' = exp(`xb')
	qui replace `mfeval_main' = cond(`y1', exp(`xb'-`expxb')/(-expm1(-`expxb')), -`expxb') `if'
	// These functions are "residual functions" (more specifically, the contribution of each observation).
	// Stata multiplies them with the instruments (specified for a given "residual equation") to get the moment functions.
	// Each residual function is used by Stata to create w moment functions, where w is the number of instruments for that residual function.
	// If no instruments are specified for a given residual function (like this section), then it directly becomes a moment function.
	
	* Calculate derivatives only if requested
	if "`derivatives'" == "" {
		exit
	}
	
	if ("`fakederivatives'" == "") {
		* Get the names of the variables storing the derivatives
		forval w = 1/`=(`num_endo' + 1)^2' {
			local d`w' : word `w' of `derivatives'
		}
		
		local c = 0
		
		* First-stage residual function(s)
		forval eq = 1/`num_endo' {
			forval pg = 1/`=`eq' - 1' {		// Note that loops do not run if the second number is less than the first
				local ++c
				replace `d`c'' = 0 `if'
			}
			
			local ++c
			replace `d`c'' = -1 `if'
			
			forval pg = 1/`=`num_endo' - `eq' + 1' {
				local ++c
				replace `d`c'' = 0 `if'
			}
		}
			
		* Second-stage residual function
		// Using expm1() rather than exp() - 1 is good practice to increase precision (though it won't matter much here)
		tempvar C_i
		gen double `C_i' = cond(`y1',																		///
								`mfeval_main' * (expm1(`xb') + exp(-`expxb')) / expm1(-`expxb'),		///
								-`expxb')
		
		forval eq = 1/`num_endo' {		// Get the needed rhos (coefficients on vhat powers)
			forval p = 1/`order' {
				scalar rho`eq'_`p' = `at'[1, colnumb(`at', "`y1': `vhatname'`eq'_`p'")]
			}
		}
		
		forval eq = 1/`num_endo' {
			forval p = 2/`order' {
				local temp`eq' "`temp`eq'' + rho`eq'_`p' * `vhatname'`eq'_`=`p' - 1'"
			}
			local resid`eq'_polyderiv "rho`eq'_1 `temp`eq''"
			
			local ++c
			replace `d`c'' = -`C_i' * (`resid`eq'_polyderiv') `if'
		}
		
		local ++c
		replace `d`c'' = `C_i' `if'
		
		// We must supply Stata with the derivatives of the residual functions, so there are
		// <no. of residual functions>*<no. of parameter groups>
		// derivatives to supply, NOT
		// <no. of moment functions>*<no. of parameter groups>
	}
	else {
		* Fake derivatives to hackily make -gmm- stop calculating the VCE
		local length : list sizeof derivatives
		forval w = 1/`length' {
			local d`w' : word `w' of `derivatives'
			replace `d`w'' = 0
		}
	}
end