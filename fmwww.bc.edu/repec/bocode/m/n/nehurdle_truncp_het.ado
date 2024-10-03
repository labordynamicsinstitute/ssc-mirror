*! nehurdle_truncp_het v1.0.0
*! 11 August 2024
*! Alfonso Sanchez-Penalver
*! Version history at the bottom.

/*******************************************************************************
*	ML lf2 evaluator for Poisson Truncated Hurdle, with heteroskedastic parti- *
*	cipation errors.														   *
*******************************************************************************/

capture program drop nehurdle_truncp_het
program define nehurdle_truncp_het
	version 11
	args todo b lnfj g1 g2 g3 H
	
	quietly {
		// Evaluating the equations
		tempvar zg xb lnsig
		
		mleval `zg' = `b', eq(1)
		mleval `xb' = `b', eq(2)
		mleval `lnsig' = `b', eq(3)
		
		// Useful variables
		tempvar exb sig zsel
		gen double `exb' = exp(`xb')
		gen double `sig' = exp(`lnsig')
		gen double `zsel' = `zg' / `sig'
		
		// Log-likelihood
		replace `lnfj' = lnnormal(- `zsel') if $ML_y1 == 0
		replace `lnfj' = lnnormal(`zsel') - `exb' + $ML_y2 * `xb' - 			///
			ln(1 - exp(- `exb')) - lnfactorial($ML_y2) if $ML_y1 == 1
		
		if (`todo' == 0) exit
		
		// Gradient
		tempvar lamzi nlamzi
		gen double `lamzi' = normalden(`zsel') / normal(`zsel')
		gen double `nlamzi' = normalden(`zsel') / normal(- `zsel')
		
		// g1 (zg) 
		replace `g1' = - `sig'^(-1) * `nlamzi' if $ML_y1 == 0
		replace `g1' = `sig'^(-1) * `lamzi' if $ML_y1 == 1
		
		// g2 (xb)
		replace `g2' = 0 if $ML_y1 == 0
		replace `g2' = $ML_y2 - `exb' * (1 + exp(- `exb') / (1 - exp(- `exb'))) ///
			if $ML_y1 == 1
		
		// g3 (lnsig)
		replace `g3' = `zsel' * `nlamzi' if $ML_y1 == 0
		replace `g3' = - `zsel' * `lamzi' if $ML_y1 == 1
		
		if (`todo' == 1) exit
		
		// Hessian
		tempvar d11 d13 d22 d33
		tempname h11 h12 h13 h22 h23 h33
		
		// h11 (zg zg)
		gen double `d11' = `sig'^(-2) * `nlamzi' * (`zsel' - `nlamzi')			///
			if $ML_y1 == 0
		replace `d11' = - `sig'^(-2) * `lamzi' * (`zsel' + `lamzi')		///
			if $ML_y1 == 1
		mlmatsum `lnfj' `h11' = `d11', eq(1)
		
		// h12 (zg xb)
		mlmatsum `lnfj' `h12' = 0, eq(1,2)
		
		// h13 (zg lnsig)
		gen double `d13' = `sig'^(-1) * `nlamzi' * (1 - `zsel' * (`zsel' -		///
			`nlamzi')) if $ML_y1 == 0
		replace `d13' = `sig'^(-1) * `lamzi' * (`zsel' * (`zsel'+ `lamzi') - 1) ///
			if $ML_y1 == 1
		mlmatsum `lnfj' `h13' = `d13', eq(1,3)
		
		// h22 (xb xb)
		gen double `d22' = 0 if $ML_y1 == 0
		replace `d22' = `exb' * (`exb' * exp(- `exb') / (1 - exp(- `exb')) - 1) * ///
			(1 + exp(- `exb') / (1 - exp(- `exb'))) if $ML_y1 == 1
		mlmatsum `lnfj' `h22' = `d22', eq(2)
		
		// h23 (xb lnsig)
		mlmatsum `lnfj' `h23' = 0, eq(2,3)
		
		// h33 (lnsig lnsig)
		gen double `d33' = `zsel' * `nlamzi' * (`zsel' * (`zsel' - `nlamzi')	///
			- 1) if $ML_y1 == 0
		replace `d33' = `zsel' * `lamzi' * (1 - `zsel' * (`zsel' + `lamzi'))	///
			if $ML_y1 == 1
		mlmatsum `lnfj' `h33' = `d33', eq(3)
		
		// Let's form the matrix.
		mat `H' = (`h11', `h12', `h13')
		mat `H' = `H' \ ((`h12')', `h22', `h23')
		mat `H' = `H' \ ((`h13')', (`h23')', `h33')
	}
	
end
// Version 1.0.0 is an lf2 evaluator.
