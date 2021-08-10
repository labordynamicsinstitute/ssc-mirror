*! 1.0.0 NJC 20 November 2016
program entropyetc, rclass    
        version 11.2
        syntax varname [if] [in] [aweight fweight] /// 
        [, by(varlist) Generate(str) Format(str) * ]

	quietly { 
		marksample touse, strok  
		if "`by'" != "" markout `touse' `by' 
		count if `touse' 
		if r(N) == 0 error 2000 

		if "`generate'" != "" parsegenerate `generate' 
		
		tempvar group which Shannon Simpson Shannon2 Simpson2 dissim 
	        tempname mylbl matname matrix vector 

		if "`by'" != "" { 
			egen `group' = group(`by') if `touse', label 
			su `group', meanonly  
			local ng = r(max) 
		} 	
		else { 
			gen byte `group' = `touse' 
			local ng = 1 
			label define `group' 1 "all"
			label val `group' `group' 
		}
			
        	gen long `which' = _n
                compress `which'
                
		foreach s in Shannon Simpson Shannon2 Simpson2 dissim { 
			gen ``s'' = . 
		} 

		label var `Shannon'  "Shannon H" 
		label var `Shannon2' "exp(H)" 
		label var `Simpson'  "Simpson" 
		label var `Simpson2' "1/Simpson" 
		label var `dissim'   "dissim." 

	        mat `matname' = J(`ng', 5, 0) 

		tab `group' `varlist' [`weight' `exp'] if `touse', ///
		matcell(`matrix') 

		local J = colsof(`matrix') 
		return scalar categories = `J' 

		forval i = 1/`ng' { 
			matrix `vector' = `matrix'[`i', 1..`J'] 						
			mata: my_entropyetc("`vector'") 
	
			su `which' if `group' == `i', meanonly  
			local where = r(min) 

	                replace `Shannon' = `H' in `where'
		        replace `Simpson' = `lambda' in `where'
        		replace `Shannon2' = exp(`H') in `where'
	                replace `Simpson2' = 1/`lambda' in `where'
			replace `dissim' = `D' in `where' 
		
			mat `matname'[`i',1] = `H'
			mat `matname'[`i',2] = exp(`H')
			mat `matname'[`i',3] = `lambda' 
			mat `matname'[`i',4] = 1/`lambda' 
			mat `matname'[`i',5] = `D' 
			local V = trim(`"`: label (`group') `i''"')
			local rownames `"`rownames' `"`V'"'"' 
		} /// loop over groups 

       	        mat colnames `matname' = ///
		Shannon exp_H Simpson rec_lambda dissim 

		capture mat rownames `matname' = `rownames' 
		if _rc { 
			numlist "1/`ng'" 
			mat rownames `matname' = `r(numlist)' 
		}

		label var `group' "Group" 
		if "`format'" == "" local format "%4.3f"
	}	
        	
	tabdisp `group' if `touse', ///
	c(`Shannon' `Shannon2' `Simpson' `Simpson2' `dissim') ///
	format(`format') `options' 

	quietly if "`generate'" != "" { 
		local lbl1 "Shannon H" 
		local lbl2 "exp(H)" 
		local lbl3 "Simpson" 
		local lbl4 "1/Simpson" 
		local lbl5 "dissimilarity index" 

		tokenize `Shannon' `Shannon2' `Simpson' `Simpson2' `dissim'  
		forval j = 1/5 { 
			if "`var_`j''" != "" { 
				egen `var_`j'' = max(``j''), by(`group') 
				label var `var_`j'' "`lbl`j''" 
			}
		}
	}  

	return matrix entropyetc = `matname' 
end

mata : 

void my_entropyetc(string scalar matname) { 
	real colvector p 
	p = st_matrix(matname') 
	p = p / sum(p) 
	st_local("H", strofreal(-sum(p :* ln(p)))) 
	st_local("lambda", strofreal(sum(p:^2)))
	st_local("D", strofreal(0.5 * sum(abs(p :- (1/cols(p))))))
} 

end 

program parsegenerate 
	tokenize `0' 
	if "`6'" != "" { 
		di as err "generate() should specify 1 to 5 tokens" 
		exit 134 
	}

	forval j = 1/5 { 
		if "``j''" != "" { 
			gettoken no rest : `j', parse(=)  
			capture numlist "`no'", max(1) int range(>=1 <=5) 
			if _rc { 
				di as err "generate() error: ``j''"
				exit _rc 
			} 

			gettoken eqs rest : rest, parse(=) 
			confirm new var `rest' 
			c_local var_`no' "`rest'" 
		}
	}  
end 

