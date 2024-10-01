*! nehurdle_truncnb1 v1.0.0
*! 16 September 2024
*! Alfonso Sanchez-Penalver
*! Version history at the bottom.

/*******************************************************************************
*	ML lf2 evaluator for truncated negative binomial 2 hurdle model, that	   *
*	allows heterogeneity in the dispersion, and with homoskedastic probit.	   *
*******************************************************************************/

capture program drop nehurdle_truncnb1
program define nehurdle_truncnb1
	version 11
	args todo b lnfj g1 g2 g3 H
	
	quietly{
		// Evaluating the variables
		tempvar xb zg lnalpha alpha mu mual
		mleval `zg' = `b', eq(1)
		mleval `xb' = `b', eq(2)
		gen double `mu' = exp(`xb')
		mleval `lnalpha' = `b', eq(3)
		gen double `alpha' = exp(`lnalpha')
		gen double `mual' = `mu' / `alpha'
		// Log-Likelihood
		replace `lnfj' = lnnormal(- `zg') if $ML_y1 == 0
		
		replace `lnfj' = lnnormal(`zg') - ln(1 - (1 + `alpha')^(- `mual')) +	///
			lngamma($ML_y2 + `mual') - lngamma(`mual') - lngamma($ML_y2 + 1) -	///
			($ML_y2 + `mual') * ln(1 + `alpha') + $ML_y2 * `lnalpha' if			///
			$ML_y1 == 1
		
		if (`todo' == 0) exit
		
		// Variables to make typing easier
		tempvar lamzi nlamzi
		gen double `lamzi' = normalden(`zg') / normal(`zg')
		gen double `nlamzi' = normalden(`zg') / normal(- `zg')
		
		// Gradient
		// g1 (zg)
		replace `g1' = - `nlamzi' if $ML_y1 == 0
		replace `g1' = `lamzi' if $ML_y1 == 1
		
		// g2 (xb)
		replace `g2' = 0 if $ML_y1 == 0
		replace `g2' = `mual' * (digamma($ML_y2 + `mual') - digamma(`mual') -	///
			ln(1 + `alpha') / (1 - (1 + `alpha')^(- `mual'))) if $ML_y1 == 1
		
		// g3 (lnalpha)
		replace `g3' = 0 if $ML_y1 == 0
		replace `g3' = `mual' * ((ln(1 + `alpha') - `alpha' / (1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual')) + digamma(`mual') - digamma($ML_y2 +	///
			`mual')) + $ML_y2 / (1 + `alpha') if $ML_y1 == 1
		
		if (`todo' == 1) exit
		
		// Hessian
		// The Hessian is 3x3, with four elements (12, 13, 21, and 31) being 0.
		tempvar d11 d22 d23 d33
		tempname h11 h12 h13 h22 h23 h33
		
		// h11 (zg zg)
		gen double `d11' = `nlamzi' * (`zg' - `nlamzi') if $ML_y1 == 0
		replace `d11' = - `lamzi' * (`zg' + `lamzi') if $ML_y1 == 1
		mlmatsum `lnfj' `h11' = `d11', eq(1)
		
		// h12 (zg xb)
		mlmatsum `lnfj' `h12' = 0, eq(1,2)
		
		// h13 (zg lnalpha)
		mlmatsum `lnfj' `h13' = 0, eq(1,3)
		
		// h22 (xb xb)
		gen double `d22' = 0 if $ML_y1 == 0
		replace `d22' = `mual' * (digamma($ML_y2 + `mual') - digamma(`mual') -	///
			ln(1 + `alpha') / (1 - (1 + `alpha')^(- `mual')) + `mual' *			///
			(trigamma($ML_y2 + `mual') - trigamma(`mual') +						///
			(1 + `alpha')^(- `mual') * (ln(1 + `alpha') / (1 -					///
			(1 + `alpha')^(- `mual')))^2)) if $ML_y1 == 1
		mlmatsum `lnfj' `h22' = `d22', eq(2)
		
		// h23 (xb lnalpha)
		gen double `d23' = 0 if $ML_y1 == 0
		replace `d23' = `mual' * (digamma(`mual') - digamma($ML_y2 + `mual') +	///
			(ln(1 + `alpha') - `alpha' / (1 + `alpha')) / (1 - (1 +				///
			`alpha')^(- `mual')) + `mual' * (trigamma(`mual') -					///
			trigamma($ML_y2 + `mual') - ln(1 + `alpha') * (1 +					///
			`alpha')^(- `mual') * (ln(1 + `alpha') - `alpha' / (1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual'))^2)) if $ML_y1 == 1
		mlmatsum `lnfj' `h23' = `d23', eq(2,3)
		
		// h33 (lnalpha lnalpha)
		gen double `d33' = 0 if $ML_y1 == 0
		replace `d33' = `mual' * ((`alpha' / (1 + `alpha') - ln(1 + `alpha')) /	///
			(1 - (1 + `alpha')^(- `mual')) + (`alpha' / (1 + `alpha'))^2 /		///
			(1 - (1 + `alpha')^(- `mual')) + digamma($ML_y2 + `mual') -			///
			digamma(`mual') + `mual' * (trigamma($ML_y2 + `mual') -				///
			trigamma(`mual') + (1 + `alpha')^(- `mual') * ((ln(1 + `alpha') -	///
			`alpha' / (1 + `alpha')) / (1 - (1 + `alpha')^(- `mual')))^2)) -	///
			$ML_y2 * `alpha' / (1 + `alpha')^2 if $ML_y1 == 1
		mlmatsum `lnfj' `h33' = `d33', eq(3)
		
		mat `H' =		(`h11',`h12',`h13')
		mat `H' = `H' \ ((`h12')',`h22',`h23')
		mat `H' = `H' \ ((`h13')',(`h23')',`h33') 
	}
end

// Version 1.0.0 is an lf2 evaluator.
