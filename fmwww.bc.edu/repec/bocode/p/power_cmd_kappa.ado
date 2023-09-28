*! 1.0.0 Ariel Linden 09Sep2023 


capture program drop power_cmd_kappa
program define power_cmd_kappa, rclass
version 12.0


			/* obtain settings */
			syntax anything(id="numlist"),	///
				MArg(numlist)				///			
				[ Alpha(real 0.05)        	/// significance level
				n(string)					/// total sample size
				Power(string)				///
				ONESIDed					///
				]

				numlist "`anything'", min(2) max(2)
				
				gettoken kappa0 rest : anything
				gettoken kappa1 rest : rest
				
				if `kappa0' < 0 | `kappa0' > 1 {
					noi di in red "Kappa0 must be a number between 0 and 1"
					exit 198
				} 
				if `kappa1' < 0 | `kappa1' > 1 {
					noi di in red "Kappa1 must be a number between 0 and 1"
					exit 198
				} 
				
				local varcnt : word count `anything'
				
				// error checking in marg()
				local margcnt : word count `marg'		
				if `margcnt' < 2 {
					noi di in red "At least 2 marginal probabilities must be specified"
					exit 198
				}
				if `kappa0' == `kappa1' {
					noi di in red "Kappa0 must be different than Kappa1"
					exit 198					
				}
				if `alpha' < 0 | `alpha' > 1 {
					di as err "option {bf:alpha()} must contain numbers between 0 and 1"
					exit 121
				}
				
				// tempnames
				tempname A B C D m BB BC CC DD EE equal coeff rhs1 rhsequal lowerbd upperbd margsum PIe PI0 Part1 Part3 Part2 tausq tau tau0 tau1

				clear matrix
				
				foreach el of local marg {
					if `el' < 0 {
						noi di in red "All marginal probabilities must be positive"
						exit
					}
					matrix `A' = nullmat(`A'),`el'
				}
				mata : st_matrix("`B'", rowsum(st_matrix("`A'")))
				scalar `margsum' = el("`B'",1,1)
				
				if round(`margsum',0.01) != 1 {
					noi di in red "Marginal probabilities must sum to 1.0"
					exit 198
				}

				*****************************
				// find maximum std error  //
				*****************************
				quietly {		
					local cnt = 1
				
					foreach var of numlist `anything' {
					
						mat `C' = `A'' * `A'
						mata : st_matrix("`C'", rowsum(diag(st_matrix("`C'"))))
						mata : st_matrix("`D'", colsum(st_matrix("`C'")))
						scalar `PIe'=el("`D'",1,1)
						scalar `PI0' = `var' + `PIe' * (1 - `var')
						scalar `Part1' = `PI0' * (1 - `PIe')^2
						scalar `Part3' = (`PI0' * `PIe'- 2 * `PIe' + `PI0')^2
				
						mat `m' = J(`margcnt',`margcnt',0) 

						forval ii = 1/`margcnt' {
							forval jj = 1/`margcnt' {
								if (`ii'==`jj') {
									mat	`m'[`ii',`ii'] = -1 * (1 -`PI0') * 2 * `A'[1,`ii'] * (2 * (1 - `PIe') - (1 - `PI0') * 2 * `A'[1,`ii'])
								}
								else { 
									mat `m'[`ii',`jj'] = (1 - `PI0')^2 * (`A'[1,`ii'] + `A'[1,`jj'])^2	
								}
							}
						}	

						mat `BC' = I(`margcnt')
						forval i = 1/`margcnt'{
							forval j = 1/`margcnt'{
								mat `BB' = nullmat(`BB'), `BC'[`i', 1...]'
							}
						}

						forval i = 2/`margcnt'{
							mata : st_matrix("`CC'", mm_repeat(st_matrix("`BC'"),1,`i'))
						}

						mat `DD' = J(1,`margcnt'^2,1)
						mata : st_matrix("`EE'", rowshape(st_matrix("`BC'"), 1))
					
						// constraints for equals
						mat `equal' = `BB' \ `CC' \ `DD' \ `EE'
				
						// coefficients
						mata : st_matrix("`coeff'", rowshape(st_matrix("`m'"), 1))
					
						// rhs variables for equals
						mata : st_matrix("`rhs1'", mm_repeat(st_matrix("`A'"),1,2))
						mat `rhsequal' = (`rhs1', 1, `PI0')'
				
						// set bounds
						mata : st_matrix("`lowerbd'", mm_repeat(0,`margcnt'^2,1)')
						mata : st_matrix("`upperbd'", mm_repeat(.,`margcnt'^2,1)')

						// Compute Part2 using linear programming 
						mata:	q = LinearProgram()
						mata:	`coeff'=st_matrix("`coeff'") // coefficients
						mata:	`equal'=st_matrix("`equal'") // constraints that are tested to be equal 
						mata:	`rhsequal'=st_matrix("`rhsequal'") // constraints that are tested to be equal 					
						mata:	`lowerbd' = st_matrix("`lowerbd'")
						mata:	`upperbd' = st_matrix("`upperbd'")
						mata:	q.setCoefficients(`coeff')
						mata:	q.setMaxOrMin("max")
						mata:	q.setEquality(`equal', `rhsequal')
						mata:	q.setBounds(`lowerbd', `upperbd')
						mata:	q.optimize()
						mata:	q.value()
						mata:	st_numscalar("`Part2'", q.value())

						scalar `tausq' = (`Part1' + `Part2' - `Part3')
						scalar `tau' = sqrt(`tausq')/(1-`PIe')^2
					
						if `cnt' == 1 {
							scalar `tau0' = `tau'
						}
						else if `cnt' == 2 {
							scalar `tau1' = `tau'
						}
						local cnt = `cnt' + 1
					
						matrix drop `BB' `BC' `CC' `DD' `EE'
					} // end foreach
				
				} // end quietly

				*******************
				// Sample size  //
				*******************
				if ("`n'" == "") {
					
					if `power' < 0 | `power' > 1 {
						di as err "option {bf:alpha()} must contain numbers between 0 and 1"
						exit 121
					} 
					tempname zalpha zbeta delta n
				
					// set default test type to "twosided"  
					if "`onesided'" == "" {
						local test = `alpha'/ 2
					}
					else local test = `alpha'

					scalar `zalpha' = invnorm(1-`test')
					scalar `zbeta' = invnorm(`power')
					scalar `delta' = abs(`kappa0' - `kappa1')

 					scalar `n' =  ceil((((`zalpha' * `tau0') + (`zbeta' * `tau1')) / (`delta'))^2) 
				} // end sample size
				
				*******************
				// Power  //
				*******************				
				else if ("`n'" !="") {	
					
					tempname zalpha delta power
				
					// set default test type to "twosided"  
					if "`onesided'" == "" {
						local test = `alpha'/ 2
					}
					else local test = `alpha'

					scalar `zalpha' = invnorm(1-`test')
					scalar `delta' = abs(`kappa0' - `kappa1')					

					scalar `power' = normal(((sqrt(`n' * `delta'^2) - (`zalpha' * `tau0')) / (`tau1')))
							
				} // end power
				
				// saved results
				return scalar N = `n'
				return scalar alpha = `alpha'
				return scalar power = `power'
				return scalar kappa0 = `kappa0'
				return scalar kappa1 = `kappa1'
				return scalar delta = `delta'
				return scalar tau0 = `tau0'
				return scalar tau1 = `tau1'


end				
                        

