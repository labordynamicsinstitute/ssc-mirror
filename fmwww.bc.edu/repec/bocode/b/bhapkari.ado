*! 1.0.0 Ariel Linden 25Aug2023 

capture program drop bhapkari
program define bhapkari, rclass
		version 11.0
			
			syntax anything(id="matrix name") 
				confirm matrix `anything' 
				if 	rowsof(`anything') != colsof(`anything') {
					di as err "matrix must be symmetrical" 
					exit 503
				} 

				matrix list `anything'

				tempname A R C dmat dmat_t D D1 delta smx smx_t E W W1 chimat chi chisq pval
                        
				mata : st_matrix("`A'", sum(st_matrix("`anything'")))
				local ntar = el("`A'",1,1)
				mata : st_matrix("`R'", rowsum(st_matrix("`anything'")))
				mata : st_matrix("`C'", colsum(st_matrix("`anything'")))
				mat `C' = `C''
                        
                
				***************************
				* dmat and transposed dmat
				**************************
				mat `dmat' = `R' - `C'
                        
				* get rows minus 1
				local rcnt = rowsof(`dmat') - 1
                        
				mat `dmat' = `dmat'[1..`rcnt', 1]
				mata : st_matrix("`dmat_t'", mm_repeat(st_matrix("`dmat'"),1,`rcnt'))
				mat `dmat' = `dmat_t''

				********************
				* delta (cell sums)
				*******************
				mat `D' = `R' + `C'
				mata : st_matrix("`D1'", diag(st_matrix("`A'")))
				mat `delta' = inv(`D1')*`D1'*diag(`D')
				mat `delta' = `delta'[1..`rcnt', 1..`rcnt']
                
				**************************************
				* smx (excludes last category of dmat)
				**************************************
				mat `smx' = `anything'[1..`rcnt', 1..`rcnt']
				mat `smx_t' = `smx''
                        
				********************
				* compute W matrix
				********************
				mata : st_matrix("`E'", (st_matrix("`dmat'") :* (st_matrix("`dmat_t'"))))
				mat `W' = `delta' - `smx' - `smx_t' - `E' / `ntar'

				******************************
				* compute inverse of W matrix
				******************************
				mat `W1' = inv(`W')
                
				***********************
				* compute chisq matrix
				***********************
				mata: st_matrix("`chimat'", (st_matrix("`E'") :* (st_matrix("`W1'"))))

				* get sum of chisq matrix
				mata : st_matrix("`chi'", sum(st_matrix("`chimat'")))
                        
				scalar `chisq' = el(`chi',1,1)
				scalar `pval' = chi2tail(`rcnt',`chisq')                        
                        
				// header info
				disp _newline "Bhapkar's coefficient of interrater agreement between two raters for categorical observations"

				disp "         Number of targets = " %3.0f `ntar'
				disp "          Number of raters = " %3.0f 2
                        
				disp _newline
				disp "            Chi-squared(`rcnt') = " %9.5f `chisq'   
				disp "                   p-value = " %9.5f `pval' 
                        
				// saved values
				return scalar df = `rcnt'
				return scalar nrat = 2
				return scalar ntar = `ntar'
				return scalar chisq = `chisq'
				return scalar pval = `pval'                     

end
                        
