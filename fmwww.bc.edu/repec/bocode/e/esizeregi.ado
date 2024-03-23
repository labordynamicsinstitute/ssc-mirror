*! 2.0.1 Ariel Linden 20Mar2024 // added z-distribution option (default is t-distribution with noncentrality parameter)
*! 2.0.0 Ariel Linden 08Mar2024 //  added Hedges g option
								//  -esizeregi- now requires user to specify pooled SD
*! 1.0.1 Ariel Linden 27Oct2021 // changed 'anything' to a scalar `est' to avoid issues with squaring negative values (which happens with local)
*! 1.0.0 Ariel Linden 29May2019

capture program drop esizeregi
program define esizeregi, rclass
version 11.0

			syntax  anything ,				 	///
				SDp(numlist max=1)				///
				n1(numlist max=1)				///
				n2(numlist max=1)				///
				[, COHensd HEDgesg Zdistribution LEVel(cilevel) ]

			numlist "`anything'", min(1) max(1)

			tempname est N sdpooled CohensD v se iz CohensD_Lower CohensD_Upper 

			// make a scalar out of varlist
			scalar `est' = `anything'
			scalar `N' = `n1' + `n2'
			
						// CALCULATE COHEN'S D
			// ==============================================================
			scalar `CohensD' = `est' / `sdp'
			scalar `v' = (`n1' + `n2') / (`n1' * `n2') + (`CohensD'^2) / (2 *(`n1' + `n2'))
			scalar `se' = sqrt(`v')
			
			if "`zdistribution'" != "" {			
				scalar `iz' = invnorm(1-(1-`level'/100)/2)
				scalar `CohensD_Lower' = `CohensD' - `iz' * sqrt(`v')
				scalar `CohensD_Upper' = `CohensD' + `iz' * sqrt(`v')
			}
			else {
				tempname alpha AlphaLower AlphaUpper ns df LowerLambda UpperLambda
				scalar `alpha' = 1-(`level'/100)
				scalar `AlphaLower' = `alpha'/2
				scalar `AlphaUpper' = 1 - (`alpha'/2)
				scalar `ns' = sqrt((`n1'*`n2')/(`n1'+`n2'))
				scalar `df' = `N' - 2
				scalar `LowerLambda' = npnt(`df',`CohensD'*`ns',`AlphaUpper')
				scalar `UpperLambda' = npnt(`df',`CohensD'*`ns',`AlphaLower')
				scalar `CohensD_Lower' = `LowerLambda' * sqrt((`n1'+`n2')/(`n1'*`n2'))
				scalar `CohensD_Upper' = `UpperLambda' * sqrt((`n1'+`n2')/(`n1'*`n2'))
			}			
			
			// CALCULATE HEDGE'S G 
			// =================================================================
			// EXACT BIAS CORRECTION: Hedges (1981) pg 111, Equation 6e
			tempname m BiasCorrectionFactor HedgesG HedgesG_Lower HedgesG_Upper
			scalar `m' = (`n1'+`n2'- 2)
			scalar `BiasCorrectionFactor' = exp(lngamma(`m'/2) - 1/2 * ln(`m'/2) - lngamma((`m'-1)/2))
			// Turner & Bernard (2006) , Eq 4
			scalar `HedgesG' = `CohensD' * `BiasCorrectionFactor'
			scalar `HedgesG_Lower' = `CohensD_Lower' * `BiasCorrectionFactor'
			scalar `HedgesG_Upper' = `CohensD_Upper' * `BiasCorrectionFactor'
			
			// DISPLAY OUTPUT
			// ====================================================================
			// SET DEFAULT OUTPUT
			if "`cohensd'"== "" & "`hedgesg'"== "" {                       
				local cohensd "cohensd"
				local hedgesg "hedgesg"
			}

			// Display Title (weighted or unweighted)
			if "`weightexp'" == "" {
				disp _newline as text "Effect size based on the regression coefficient of the treatment (exposure) variable"
            }
			else {
				disp _newline as text "{bf:Weighted} effect size based on the regression coefficient of the treatment (exposure) variable"
			}
			
			// Display table header information 
			disp _newline %45s "Obs per group:"
			disp %47s "Group 1 = " %10.0fc `n1'
			disp %47s "Group 2 = " %10.0fc `n2'
      
			// Display output table
			tempname mytab
			.`mytab' = ._tab.new, col(5) lmargin(0)
			.`mytab'.width    20   |11  12  12    12
			.`mytab'.titlefmt  .     .   . %24s   .
			.`mytab'.pad       .     1   1  3     3
			.`mytab'.numfmt    . %9.0g %9.0g %9.0g %9.0g
			.`mytab'.strcolor result  .  .  .  .
			.`mytab'.strfmt    %19s  .  .  .  .
			.`mytab'.strcolor   text  .  .  .  .
			.`mytab'.sep, top
			.`mytab'.titles "Effect Size"							/// 1
							"Estimate"								/// 2
							"Std. Err."								/// 3
							"[`level'% Conf. Interval]" ""          //  4 5
			.`mytab'.sep, middle
                .`mytab'.strfmt    %24s  .  .  .  .
			if "`cohensd'" != "" {
                .`mytab'.row    "Cohen's {it:d}"        ///
                        `CohensD' 	                   	///
                        `se'							///
						`CohensD_Lower'                 ///
                        `CohensD_Upper'
			}	
			if "`hedgesg'" != "" {
                .`mytab'.row    "Hedges's {it:g}"       ///
                        `HedgesG' 	                   	///
                        `se'							///
						`HedgesG_Lower'                 ///
                        `HedgesG_Upper'
			}
				.`mytab'.sep, bottom

			// Return results
			if "`hedgesg'" != "" {
                return scalar ub_g = `HedgesG_Upper'
                return scalar lb_g = `HedgesG_Lower'
                return scalar g = `HedgesG'
			}
			if "`cohensd'" != "" {
                return scalar ub_d = `CohensD_Upper'
                return scalar lb_d = `CohensD_Lower'
                return scalar d = `CohensD'
			}
			
			return scalar se = `se'
			return scalar n2 = `n2'
			return scalar n1 = `n1'
			return scalar sdpooled = `sdp'
			return scalar est = `est'
	
			// Make a c_local macro of d, g and se 
			c_local d = `CohensD'
			c_local g = `HedgesG'			
			c_local se = `se'

end