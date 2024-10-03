*! nehurdle_truncp v1.0.0
*! 10 August 2024
*! Alfonso Sanchez-Penalver
*! Version history at the bottom.

/*******************************************************************************
*	ML lf2 evaluator for Poisson Truncated Hurdle, with homoskedastic partici- *
*	pation errors.															   *
*******************************************************************************/

capture program drop nehurdle_truncp
program define nehurdle_truncp
	version 11
	args todo b lnfj g1 g2 H
	
	quietly {
		// Evaluating the functions and forming variables that help program
		tempvar zg xb exb
		
		mleval `zg' = `b', eq(1)
		mleval `xb' = `b', eq(2)
		
		gen double `exb' = exp(`xb')
		
		// Log-Likelihood
		replace `lnfj' = lnnormal(- `zg') if $ML_y1 == 0
		
		replace `lnfj' = lnnormal(`zg') - `exb' + $ML_y2 * `xb' - 				///
			ln(1 - exp(- `exb')) - lnfactorial($ML_y2) if $ML_y1 == 1
			
		if (`todo' == 0) exit
		
		// Gradient
		
		tempvar lamzi nlamzi
		gen double `lamzi' = normalden(`zg') / normal(`zg')
		gen double `nlamzi' = normalden(`zg') / normal(- `zg')
		
		// g1 (zg)
		replace `g1' = - `nlamzi' if $ML_y1 == 0
		replace `g1' = `lamzi' if $ML_y1 == 1
		
		// g2 (xb)
		replace `g2' = 0 if $ML_y1 == 0
		replace `g2' = $ML_y2 - `exb' * (1 + exp(- `exb') / (1 - exp(- `exb'))) ///
			if $ML_y1 == 1
		
		if (`todo' == 1) exit
		
		// Hessian
		tempvar d11 d22
		tempname h11 h12 h22
		
		// h11 (zg zg)
		gen double `d11' = `nlamzi' * (`zg' - `nlamzi') if $ML_y1 == 0
		replace `d11' = - `lamzi' * (`zg' + `lamzi') if $ML_y1 == 1
		mlmatsum `lnfj' `h11' = `d11', eq(1)
		
		// h12 (zg xb)
		mlmatsum `lnfj' `h12' = 0, eq(1,2)
		
		// h22 (xb xb)
		gen double `d22' = 0 if $ML_y1 == 0
		replace `d22' = `exb' * (`exb' * exp(- `exb') / (1 - exp(- `exb')) - 1) * ///
			(1 + exp(- `exb') / (1 - exp(- `exb'))) if $ML_y1 == 1
		mlmatsum `lnfj' `h22' = `d22', eq(2)
		
		mat `H' = (`h11', `h12')
		mat `H' = `H' \ ((`h12')', `h22')
	}
end
// Version 1.0.0 is an lf2 evaluator.
