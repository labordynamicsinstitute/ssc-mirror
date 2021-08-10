*! version 1.0.1 Ariel Linden 13jan2016 //changed rowname and colname to rowlab and collab to represent labels instead of var names
*! 1.0.0 Ariel Linden 27dec2015 

capture program drop classtabi
program define classtabi, rclass
	version 11.0
	syntax anything(id="argument numlist") [, ROWlabel(string asis) COLlabel(string asis)] 

	preserve
	clear

	tokenize `anything'
	local variable_tally : word count `anything'
    if (`variable_tally' > 4) exit = 103
    if (`variable_tally' < 4) exit = 102
	
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
	
	quietly {

		tabi `1' `2' \ `3' `4'				// run tabi here to get values for classification calculations

		/* Save r() */
    
		* Classification calculations
		ret scalar P_corr = ((`1'+`4')/(`1'+`2'+`3'+`4'))*100 							/* overall correctly classified	*/
		ret scalar P_p1 = (`4'/(`3'+`4'))*100     										/* sensitivity          		*/
		ret scalar P_n0 = (`1'/(`1'+`2'))*100     										/* specificity					*/
		ret scalar P_1p = (`4'/(`2'+`4'))*100     										/* positive pred value			*/
		ret scalar P_0n = (`1'/(`1'+`3'))*100     										/* negative pred value			*/
		ret scalar P_0p = (`2'/(`1'+`2'))*100     										/* false positive rate			*/
		ret scalar P_1n = (`3'/(`3'+`4'))*100     										/* false negative rate			*/
		ret scalar ess = (((return(P_p1) + return(P_n0)) / 2) - 50) / 50 * 100			/* effect strength sensitivity	*/
		
		tabi `1' `2' \ `3' `4', replace		// run tabi here to expand data to run -roctab-
		expand pop
		recode row (1=0) (2=1)			// recode row values to 0,1 from 1,2								
		recode col (1=0) (2=1)			// recode col values to 0,1 from 1,2	
		
		if "`rowlabel'" != "" {
			label var row "`rowlabel'" 
		}

		if "`collabel'" != "" {
			label var col "`collabel'" 
		}
	
		roctab row col
		local roc = "0" + string(round(r(area),0.0001))	
		ret scalar roc = `roc'																/* roc curve 		    */

	}
	tab row col						// run tab to get final table with new row/col names
	

	#delimit ;
	di _n ;	
	di    in smcl in gr "{hline 49}" ;
    di    in gr `"Sensitivity"' _col(33) `"D/(C+D)"'
		in ye %8.2f return(P_p1) `"%"' _col(55) _n
              in gr `"Specificity"' _col(33) `"A/(A+B)"'
              in ye %8.2f return(P_n0) `"%"' _col(55) _n
              in gr `"Positive predictive value"' _col(33) `"D/(B+D)"'
              in ye %8.2f return(P_1p) `"%"' _col(55) _n
              in gr `"Negative predictive value"' _col(33) `"A/(A+C)"'
              in ye %8.2f return(P_0n) `"%"' _col(55) ;
    di    in smcl in gr "{hline 49}"  ;
    di    in gr `"False positive rate"' _col(33) `"B/(A+B)"'
              in ye %8.2f return(P_0p) `"%"' _col(55) _n
              in gr `"False negative rate"' _col(33) `"C/(C+D)"'
              in ye %8.2f return(P_1n) `"%"'  _col(55);
    di    in smcl in gr "{hline 49}"  ;
    di    in gr `"Correctly classified"' _col(27) `"A+C/(A+B+C+D)"'
              in ye %8.2f return(P_corr) `"%"' _col(55) ;
    di    in smcl in gr "{hline 49}"  ;
	di    in gr `"Effect strength for sensitivity"' _col(40)
			  in ye %8.2f return(ess)  `"%"' _col(55)  ;
	di    in smcl in gr "{hline 49}"  ;
	di    in gr `"ROC area"' _col(40)
			  in ye %9.4f return(roc)  _col(55)  ;
	di    in smcl in gr "{hline 49}"  ;

	
end ;

