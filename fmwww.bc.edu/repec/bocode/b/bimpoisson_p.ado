*! 1.0.4 Stephen P. Jenkins and Fernando Rios-Avila, February 2026

program bimpoisson_p
	
	version 15, missing

    syntax anything(id="newvarname") [if] [in] , [ 			///
			n1 n2  xb1 xb2 stdp1 stdp2						///
			pr1(numlist >=0 integer min=1 max=1) 			///
			pr2(numlist >=0 integer min=1 max=1) 			///
			pr12(numlist >=0 integer min=2 max=2) 			///			
			nsim(int 100) seed(string) * ]
	
	tokenize `e(depvar)'
	local dep1 `1'
	local dep2 `2'
		
	marksample touse, novarlist
	set rngstate `e(rngstate)'
	quietly { 
		
			// linear index/predictor, equation 1 
		if "`xb1'" != "" {  
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', xb eq(#1) `offset'
			label var `varlist' "Linear prediction, `dep1'"
		}
			// Count index standard error, equation 1 
		else if "`stdp1'" != "" { 
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', stdp eq(#1) `offset'
			label var `varlist' "SE of linear prediction, `dep1'"
		}
			// Count predictor, equation 1 
		else if "`n1'" != "" {   
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', xb eq(#1)
			replace  `varlist' = exp(`varlist')*exp( e(sigma1)^2/2 )
			label var `varlist' "Count prediction, `dep1'"
		}
			// Probability predictor, equation 1
		else if "`pr1'" != "" {   		
			tempvar xb prx ui
			syntax newvarname [if] [in] [, * ]		
			_predict double `xb' if `touse', xb eq(#1)
			gen double `prx' = 0 if `touse'
			gen double `ui' = .
			if "`seed'" != "" set seed `seed'
			forvalues i = 1/`nsim' {
				replace `ui' = `xb' + e(sigma1)*rnormal() if `touse'
				replace `prx' = `prx' + exp( (`pr1' * `ui') - exp(`ui') ///
					- lngamma(`pr1'+1))/`nsim'	if `touse'	 	
			}
			gen `typlist' `varlist' = `prx'
			label var `varlist' "Predicted prob(`dep1' = `pr1')"
		}

		
			// linear index/predictor, equation 2 
		if "`xb2'" != "" {  
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', xb eq(#2) `offset'
			label var `varlist' "Linear prediction, `dep2'"
		}
			// Count index standard error, equation 2
		else if "`stdp2'" != "" { 
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', stdp eq(#2) `offset'
			label var `varlist' "SE of linear prediction, `dep2'"
		}
			// Count predictor, equation 2 
		else if "`n2'" != "" {   
			syntax newvarname [if] [in] [, * ]
			_predict `typlist' `varlist' if `touse', xb eq(#2)
			replace  `varlist' = exp(`varlist')*exp( e(sigma1)^2/2 )
			label var `varlist' "Count prediction, `dep2'"
		}
			// Probability predictor, equation 2
		else if "`pr2'" != "" {   		
			
			tempvar xb prx ui
			syntax newvarname [if] [in] [, * ]		
			_predict double `xb' if `touse', xb eq(#2)
			gen double `prx' = 0 if `touse'
			gen double `ui' = .
			if "`seed'" != "" set seed `seed'
			forvalues i = 1/`nsim' {
				replace `ui' = `xb' + e(sigma2)*rnormal() if `touse'
				replace `prx' = `prx' + exp( (`pr2' * `ui') - exp(`ui') ///
					- lngamma(`pr2'+1))/`nsim'	if `touse'	 	
			}
			gen `typlist' `varlist' = `prx'
			label var `varlist' "Predicted prob(`dep2' = `pr2')"
		}
		
			// Joint count probability predictor
		else if "`pr12'" != "" {   		
			tempvar xb1 prx1 u1i xb2 prx2 u2i e1i e2i prx
			syntax newvarname [if] [in] [, * ]		
			_predict double `xb1' if `touse', xb eq(#1)
			gen double `prx1' = 0 if `touse'
			gen double `u1i' = .
			_predict double `xb2' if `touse', xb eq(#2)
			gen double `prx2' = 0 if `touse'
			gen double `u2i' = .
			if "`seed'" != "" set seed `seed'
			gen double `prx' = 0 if `touse'
			local k1: word 1 of `pr12'
			local k2: word 2 of `pr12'			
			drawnorm  `e1i' `e2i', cov(1 `e(rho)' 1) double cstorage(upper)
			forvalues i = 1/`nsim' {
				replace `u1i' = `xb1' + e(sigma1)*`e1i' if `touse'
				replace `u2i' = `xb2' + e(sigma2)*`e2i' if `touse'
				replace `prx1' = exp( (`k1' * `u1i') - exp(`u1i') ///
					- lngamma(`k1'+1))	if `touse'	 	
				replace `prx2' = exp( (`k2' * `u2i') - exp(`u2i') ///
					- lngamma(`k2'+1))	if `touse'
				replace `prx' = `prx1' * `prx2'	
				replace `prx' = `prx' + `prx'/`nsim'
			}
			gen `typlist' `varlist' = `prx'
			label var `varlist' "Predicted prob(`dep1' = `k1' & `dep2' = `k2')"
		}
	
	} // end quietly


end
 