*! nehurdle_truncnb1_het v1.0.0
*! 06 September 2024
*! Alfonso Sanchez-Penalver
*! Version history at the bottom.

/*******************************************************************************
*	ML lf2 evaluator for truncated negative binomial 1 hurdle model, that	   *
*	allows heterogeneity in the dispersion, and with heteroskedastic probit.   *
*******************************************************************************/

capture program drop nehurdle_truncnb1_het
program define nehurdle_truncnb1_het
	version 11
	args todo b lnfj g1 g2 g3 g4 H
	
	quietly{
		// Evaluating the variables
		tempvar xb zg lnalpha alpha mu lnssel ssel mual
		mleval `zg' = `b', eq(1)
		mleval `xb' = `b', eq(2)
		mleval `lnssel' = `b', eq(3)
		mleval `lnalpha' = `b', eq(4)
		gen double `mu' = exp(`xb')
		gen double `ssel' = exp(`lnssel')
		gen double `alpha' = exp(`lnalpha')
		gen double `mual' = `mu' / `alpha'
		
		// Generate variables that are going to help in writing the functions
		tempvar  zsel
		gen double `zsel' = `zg' / `ssel'
		
		// Log-Likelihood
		replace `lnfj' = lnnormal(- `zsel') if $ML_y1 == 0
		replace `lnfj' = lnnormal(`zsel') - ln(1 - (1 + `alpha')^(- `mual')) +	///
			lngamma($ML_y2 + `mual') - lngamma(`mual') - lngamma($ML_y2 + 1) -	///
			($ML_y2 + `mual') * ln(1 + `alpha') + $ML_y2 * `lnalpha' if			///
			$ML_y1 == 1
		
		if (`todo' == 0) exit
		
		// Generate variables to help in writing the functions for the gradient
		// and Hessian
		tempvar lamzi nlamzi
		gen double `lamzi' = normalden(`zsel') / normal(`zsel')
		gen double `nlamzi' = normalden(`zsel') / normal(- `zsel')
		
		// Gradient
		// g1 (zg)
		replace `g1' = - `ssel'^(-1) * `nlamzi' if $ML_y1 == 0
		replace `g1' = `ssel'^(-1) * `lamzi' if $ML_y1 == 1
		
		// g2 (xb)
		replace `g2' = 0 if $ML_y1 == 0
		replace `g2' = `mual' * (digamma($ML_y2 + `mual') - digamma(`mual') -	///
			ln(1 + `alpha') / (1 - (1 + `alpha')^(- `mual'))) if $ML_y1 == 1
		
		// g3 (lnssel)
		replace `g3' = `zsel' * `nlamzi' if $ML_y1 == 0
		replace `g3' = - `zsel' * `lamzi' if $ML_y1 == 1
		
		// g4 (lnalpha)
		replace `g4' = 0 if $ML_y1 == 0
		replace `g4' = `mual' * ((ln(1 + `alpha') - `alpha' / (1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual')) + digamma(`mual') - digamma($ML_y2 +	///
			`mual')) + $ML_y2 / (1 + `alpha') if $ML_y1 == 1
		
		if (`todo' == 1) exit
		
		// Hessian
		// This is going to be a 4x4 with elements h12, h14, h21, h23, h32, h34,
		// and h41 equal to 0
		
		tempvar d11 d13 d22 d24 d33 d44
		tempname h11 h12 h13 h14 h22 h23 h24 h33 h34 h44
		
		// h11 (zg zg)
		gen double `d11' = `ssel'^(-2) * `nlamzi' * (`zsel' - `nlamzi') if		///
			$ML_y1 == 0
		replace `d11' = - `ssel'^(-2) * `lamzi' * (`zsel' + `lamzi') if			///
			$ML_y1 == 1
		mlmatsum `lnfj' `h11' = `d11', eq(1)
		
		// h12 (zg xb)
		mlmatsum `lnfj' `h12' = 0, eq(1,2)
		
		// h13 (zg lnssel)
		gen double `d13' = `ssel'^(-1) * `nlamzi' * (1 - `zsel' * (`zsel' -		///
			`nlamzi')) if $ML_y1 == 0
		replace `d13' = `lamzi' / `ssel' * (`zsel' * (`zsel'+ `lamzi') - 1) ///
			if $ML_y1 == 1
		mlmatsum `lnfj' `h13' = `d13', eq(1,3)
		
		// h14 (zg lnalpha)
		mlmatsum `lnfj' `h14' = 0, eq(1,4)
		
		// h22 (xb xb)
		gen double `d22' = 0 if $ML_y1 == 0
		replace `d22' = `mual' * (digamma($ML_y2 + `mual') - digamma(`mual') -	///
			ln(1 + `alpha') / (1 - (1 + `alpha')^(- `mual')) + `mual' *			///
			(trigamma($ML_y2 + `mual') - trigamma(`mual') +						///
			(1 + `alpha')^(- `mual') * (ln(1 + `alpha') / (1 -					///
			(1 + `alpha')^(- `mual')))^2)) if $ML_y1 == 1
		mlmatsum `lnfj' `h22' = `d22', eq(2)
		
		// h23 (xb lnssel)
		mlmatsum `lnfj' `h23' = 0, eq(2,3)
		
		// h24 (xb lnalpha)
		gen double `d24' = 0 if $ML_y1 == 0
		replace `d24' = `mual' * (digamma(`mual') - digamma($ML_y2 + `mual') +	///
			(ln(1 + `alpha') - `alpha' / (1 + `alpha')) / (1 - (1 +				///
			`alpha')^(- `mual')) + `mual' * (trigamma(`mual') -					///
			trigamma($ML_y2 + `mual') - ln(1 + `alpha') * (1 +					///
			`alpha')^(- `mual') * (ln(1 + `alpha') - `alpha' / (1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual'))^2)) if $ML_y1 == 1
		mlmatsum `lnfj' `h24' = `d24', eq(2,4)
		
		// h33 (lnssel lnssel)
		gen double `d33' = `zsel' * `nlamzi' * (`zsel' * (`zsel' - `nlamzi')	///
			- 1) if $ML_y1 == 0
		replace `d33' = - `zsel' * `lamzi' * (`zsel' * (`zsel' + `lamzi') - 1)	///
			if $ML_y1 == 1
		mlmatsum `lnfj' `h33' = `d33', eq(3)
		
		// h34 (lnssel lnalpha)
		mlmatsum `lnfj' `h34' = 0, eq(3,4)
		
		// h44 (lnalpha lnalpha)
		gen double `d44' = 0 if $ML_y1 == 0
		replace `d44' = `mual' * ((`alpha' / (1 + `alpha') - ln(1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual')) + (`alpha' / (1 + `alpha'))^2 /		///
			(1 - (1 + `alpha')^(- `mual')) + digamma($ML_y2 + `mual') -			///
			digamma(`mual') + `mual' * (trigamma($ML_y2 + `mual') -				///
			trigamma(`mual') + (1 + `alpha')^(- `mual') * ((ln(1 + `alpha') -	///
			`alpha' / (1 + `alpha')) / (1 - (1 + `alpha')^(- `mual')))^2)) -	///
			$ML_y2 * `alpha' / (1 + `alpha')^2 if $ML_y1 == 1
		mlmatsum `lnfj' `h44' = `d44', eq(4)
		
		// Compose the Hessian
		mat `H' =		(`h11',`h12',`h13',`h14')
		mat `H' = `H' \ ((`h12')',`h22',`h23',`h24')
		mat `H' = `H' \ ((`h13')',(`h23')',`h33',`h34')
		mat `H' = `H' \ ((`h14')',(`h24')',(`h34')',`h44')
	}
end

// Version 1.0.0 is an lf2 evaluator.
