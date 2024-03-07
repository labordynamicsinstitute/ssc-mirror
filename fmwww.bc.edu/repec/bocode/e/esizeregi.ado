*! 2.0.0 Ariel Linden 05MAr2024 //  -esizeregi- now requires user to specify pooled SD
*! 1.0.1 Ariel Linden 27Oct2021 // changed 'anything' to a scalar `est' to avoid issues with squaring negative values (which happens with local)
*! 1.0.0 Ariel Linden 29May2019

capture program drop esizeregi
program define esizeregi, rclass
version 11.0

			syntax  anything ,				 	///
				SDp(numlist max=1)				///
				n1(numlist max=1)				///
				n2(numlist max=1)				///
				[, LEVel(cilevel) ]

			numlist "`anything'", min(1) max(1)

			tempname est N sdpooled d v se iz CohensD_Lower CohensD_Upper 

			// make a scalar out of varlist
			scalar `est' = `anything'
			scalar `N' = `n1' + `n2'

			// Compute values
			scalar `d' = `est' / `sdp'
			scalar `v' = (`n1' + `n2') / (`n1' * `n2') + (`d'^2) / (2 *(`n1' + `n2'))
			scalar `se' = sqrt(`v')
			scalar `iz' = invnorm(1-(1-`level'/100)/2)
			scalar `CohensD_Lower' = `d' - `iz' * sqrt(`v')
			scalar `CohensD_Upper' = `d' + `iz' * sqrt(`v')

			// Display Title
			disp _newline as text "Effect size based on the regression coefficient of the treatment (exposure) variable"
                
			// Display table header information 
			disp _newline %45s "Obs per group:"
			disp %47s "Group 1 = " %10.0fc `n1'
			disp %47s "Group 2 = " %10.0fc `n2'
      
			// Display output table for the flavor of -esize-

			tempname mytab
			.`mytab' = ._tab.new, col(5) lmargin(0)
			.`mytab'.width    20   |11  12  12    12
			.`mytab'.titlefmt  .     .   . %24s   .
			.`mytab'.pad       .     1   1  3     3
			.`mytab'.numfmt    . %9.6f %9.6f %9.6f %9.6f
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
                .`mytab'.row    "Cohen's {it:d}"        ///
                        `d' 	                      	///
                        `se'							///
						`CohensD_Lower'                 ///
                        `CohensD_Upper'
			.`mytab'.sep, bottom	

			// Return results
			return scalar d = `d'
			return scalar se_d = `se'
            return scalar lb_d = `CohensD_Lower'
			return scalar ub_d = `CohensD_Upper'
	
			// Make a c_local macro of d and se 
			c_local d = `d'
			c_local se = `se'

end
