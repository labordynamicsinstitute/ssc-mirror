*! version 1.0.0  //  Ariel Linden 02oct2021 

program define ordcatsampsi, rclass
version 11.0

        syntax anything, 							///
		or(numlist max=1) 							///
		[ ALPha(real 0.05) 							///
		Power(numlist max=1) 						///
		n(numlist max=1 integer) 					///
		n1(numlist max=1 integer) 					///
		n2(numlist max=1 integer) 					///
		NRATio(real 1)			  					///
		ONESIDed ]
		
			numlist "`anything'", min(2)
			tokenize `anything', parse(" ")
			local kn : list sizeof anything
			
			if `alpha' < 0 | `alpha' > 1.0 { 
				di as err "alpha() must be between 0 and 1.0 inclusive"
				exit
			}
			if "`power'" == "" & "`n'" == "" & "`n1'" == "" & "`n2'" == "" {
				di as err "either power or sample size must be specified"
				exit
			}
			if ("`power'" != "" & "`n'" != "") {
				di as err "either power or sample size must be specified, not both"
				exit
			}	
			if ("`power'" != "" & "`n1'" != "" ) {
				di as err "either power or sample size must be specified, not both"
				exit
			}
			if ("`power'" != "" & "`n2'" != "" ) {
				di as err "either power or sample size must be specified, not both"
				exit
			}	
			if "`power'" == "" {
				if "`n'" == "" & "`n1'" != "" & "`n2'" == "" {
					di as err "either n or n2 must also be specified"
				exit
				}	
			}
			if "`power'" == "" {
				if "`n'" == "" & "`n1'" == "" & "`n2'" != "" {
					di as err "either n or n1 must also be specified"
				exit
				}	
			}

			if "`power'" != "" {
				if `power' < 0 | `power' > 1.0 { 
				di as err "power() must be between 0 and 1.0 inclusive"
				exit
				}
            }                       
			quietly {
				preserve
				clear
				set obs `kn'
				tempvar p p3
				gen `p' = .
				
				// Loop over values of proportions
				forvalues i = 1/`kn' { 
					local P : word `i' of `anything'
					replace `p' = `P' in `i'
				}	

				if "`power'" == "" {
					local pow_default = 0.80
				}
				else local pow_default = `power'
				
				local lor = abs(log(`or'))
				
				if "`onesided'" != "" {
					local side = 1
				}
				else local side = 2

				local zalpha = invnorm(1 - `alpha'/ `side')
				local zbeta = invnorm(`pow_default') 


				total `p'
				mat C = r(table)
				local sum = C[1,1]
				if abs(`sum' - 1) > .00001 {
					di as err "probabilities in p do not add up to 1"
					exit
				}

				gen `p3' = `p'^3
				total `p3'
				mat C = r(table)
				local sum = C[1,1]
				local ps = 1-`sum'
				
				*******************************
				**** compute sample size ******
				*******************************
				if "`n'" == "" {

*					if `nratio' != 1 {
*						local A = `nratio'
*					}
*					else if `nratio' == 1 {
*						local A = 1
*					}

				local A = `nratio'
			
					local n_calc = 3 * ((`A' + 1) ^ 2) * (`zalpha' + `zbeta') ^ 2 / `A' / (`lor' ^ 2) / `ps'
				} // end compute sample size
				
				***********************
				**** compute power ****
				***********************
				if "`power'" == "" {
					if "`n'" == "" {
						local n = `n1' + `n2'
					}
					if "`n1'" == "" & "`n2'" != "" {
						local n1 = `n' - `n2'
					}
					if "`n2'" == "" & "`n1'" != "" {
						local n2 = `n' - `n1'
					}
					if "`n'" != "" & "`n1'" == "" & "`n2'" == "" {
						local n1 = `n' / 2
						local n2 = `n' - `n1'
					}
					local V = `n1' * `n2' * `n' / 3 / ((`n' + 1) ^ 2) * `ps'
					local pow_calc = normal((`lor')*sqrt(`V') - `zalpha')
				} // end compute power 

				
			} // end quietly
		
			// display table header information 
			if "`n'" !="" { // power
				disp _newline "Study parameters:"
				di as txt " "
				di as txt "                N = " as result ceil(`n')
				di as txt "               N1 = " as result ceil(`n1')
				di as txt "               N2 = " as result ceil(`n2')
				di as txt "            alpha = " as result `alpha'
				di as txt "               OR = " as result `or'
				di _n
				disp as txt "Estimated power:"
				di as txt " "
				di as txt "            power = " as result `pow_calc'
			} // end power report
			
			else { // sample size
			
				// get n1 and n2 sizes based on nratio for report
				local n1_p = (1 / (`nratio' + 1)) * `n_calc'
				local n2_p = ((`nratio') / (`nratio' + 1)) * `n_calc'

				
				disp _newline "Study parameters:"
				di as txt " "
				di as txt "           power = " as result `power'
				di as txt "           alpha = " as result `alpha'
				di as txt "              OR = " as result `or'
				di as txt "           N2/N1 = " as result `nratio'
				di _n
				disp as txt "Estimated sample size:"
				di as txt " "
				di as txt "                N = " as result ceil(`n_calc')
				di as txt "               N1 = " as result ceil(`n1_p')
				di as txt "               N2 = " as result ceil(`n2_p')
			
			} // end sample size report

			// return variables     
			if "`n'" !="" {
				return scalar power = `pow_calc'
			}
			else {
				return scalar n2 = ceil(`n2_p')
				return scalar n1 = ceil(`n1_p')
				return scalar n = ceil(`n_calc')
			}
			
end				