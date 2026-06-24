*! version 1.0  16jun2026
*! midas cii -- per-row binomial CI for diagnostic count variables

cap program drop midas_cii
program define midas_cii
version 16

syntax varlist [if] [in], p(name) lowerci(name) upperci(name) [cimethod(string) level(real 95)]
		
qui {	
		tokenize `varlist'
		gen `p' = .
		gen `lowerci' = .
		gen `upperci' = .
			
		count `if' `in'
		forvalues i = 1/`r(N)' {
		local N = `1'[`i']
		local n = `2'[`i']
		if `N' ==0 & `n' ==0 {
		replace `p' = 0 in `i'
		replace `lowerci' = 0 in `i'
		replace `upperci' = 0 in `i'	
		}
		else {
		cii proportions `N' `n', `cimethod' level(`level')
				
		replace `p' = r(proportion) in `i'
		replace `lowerci' = r(lb) in `i'
		replace `upperci' = r(ub) in `i'
			}
		}
}
end
