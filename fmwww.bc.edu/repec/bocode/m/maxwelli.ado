*! 1.0.0 Ariel Linden 16Jul2023 

capture program drop maxwelli
program define maxwelli, rclass
	version 11.0
	capture { 
		syntax anything(id="matrix name") [, tab]
		confirm matrix `anything' 
		if rowsof(`anything') != 2 | colsof(`anything') != 2 { 
			di as err "matrix not 2 x 2" 
			exit 498
		} 

		local 1 = `anything'[1,1] 
		local 2 = `anything'[1,2] 
		local 3 = `anything'[2,1] 
		local 4 = `anything'[2,2] 
	}
	if _rc { 
		syntax anything(id="argument numlist") [, tab]

		tokenize `anything'
		local variable_tally : word count `anything'
	    if (`variable_tally' > 4) exit = 103
    	if (`variable_tally' < 4) exit = 102
	} 
	
	forvalues i = 1/4 {
		capture confirm integer number ``i''
		if _rc {
			display in smcl as error "values must all be integers"
            exit = 499
		}
	}
	forvalues i = 1/4 {
		capture assert ``i'' >= 0
		if _rc {
			display in smcl as error "values must all be nonnegative"
			exit = 499
		}
	}

		// run tabi here to display data in cells
		if "`tab'" != "" {
			tabi `1' `2' \ `3' `4',  col row
		}
*		disp _newline
		local total = `1' + `2' + `3' + `4'
		local maxwell = ((`1'+`4') - (`2'+`3'))/(`1'+`2'+`3'+`4')
		local nrat = 2
		
		disp _newline "Maxwell's random error (RE) coefficient of agreement for binary data"		
		disp "      Number of targets =" %3.0f `total'
		disp "       Number of raters =" %3.0f `nrat'
		disp _newline
		disp "         RE coefficient = " %6.4f `maxwell'      
                                
 		
		// return list
		return scalar nrat = `nrat'
		return scalar ntar = `total'
		return scalar maxwell = `maxwell'

		
	
end

