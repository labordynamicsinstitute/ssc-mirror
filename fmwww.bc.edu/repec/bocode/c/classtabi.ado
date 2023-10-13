*! 3.0.0 Ariel Linden 30Sep2022 // rearranged (and relabeled) 2 X 2 matrix, added exact confidence intervals 
*! 2.0.1 Ariel Linden 05oct2017 // accepted edits by NJC                                                                       
*! 2.0.0 Ariel Linden 03oct2017 // fixed bug occurring when cell value is 0
										// fixed output label for "correctly classified"
										// Nicholas J Cox supplied the code to accept matrix arguments
*! 1.0.1 Ariel Linden 13jan2016 //changed rowname and colname to rowlab and collab to represent labels instead of var names
*! 1.0.0 Ariel Linden 27dec2015 

capture program drop classtabi
program define classtabi, rclass
	version 11.0
    local opts [, Level(cilevel)] 
	capture { 
		syntax anything(id="matrix name") `opts' 
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
		syntax anything(id="argument numlist") `opts'  

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

	preserve
	clear	
		
	quietly {

		// run tabi here to get values for classification calculations
		tabi `1' `2' \ `3' `4'				
		
		tempname alpha
		scalar `alpha' = (100-`level')/200

		// Classification calculations and save r()
		ret scalar all = ((`1'+`4')/(`1'+`2'+`3'+`4'))*100 								/* overall correctly classified	*/
			local allden = `1'+`2'+`3'+`4'
			local allnum = `1'+`4'
			return scalar allub = invbinomial(`allden',`allnum', `alpha') * 100
			return scalar alllb = invbinomial(`allden',`allnum', 1-`alpha') * 100		
		ret scalar sens = (`1'/(`1'+`2'))*100     										/* sensitivity          		*/
			local sensden = `1'+`2'
			local sensnum = `1'
			return scalar sensub = invbinomial(`sensden',`sensnum', `alpha') * 100
			return scalar senslb = invbinomial(`sensden',`sensnum', 1-`alpha') * 100
		ret scalar spec = (`4'/(`3'+`4'))*100     										/* specificity					*/
			local specden = `3'+`4'
			local specnum = `4'
			return scalar specub = invbinomial(`specden',`specnum', `alpha') * 100
			return scalar speclb = invbinomial(`specden',`specnum', 1-`alpha') * 100		
		ret scalar ppv = (`1'/(`1'+`3'))*100     										/* positive pred value			*/
			local ppvden = `1'+`3'
			local ppvnum = `1'
			return scalar ppvub = invbinomial(`ppvden',`ppvnum', `alpha') * 100
			return scalar ppvlb = invbinomial(`ppvden',`ppvnum', 1-`alpha') * 100	
		ret scalar npv = (`4'/(`2'+`4'))*100     										/* negative pred value			*/
			local npvden = `2'+`4'
			local npvnum = `4'
			return scalar npvub = invbinomial(`npvden',`npvnum', `alpha') * 100
			return scalar npvlb = invbinomial(`npvden',`npvnum', 1-`alpha') * 100	
		ret scalar fpr = (`3'/(`3'+`4'))*100     										/* false positive rate			*/
			local fprden = `3'+`4'
			local fprnum = `3'
			return scalar fprub = invbinomial(`fprden',`fprnum', `alpha') * 100
			return scalar fprlb = invbinomial(`fprden',`fprnum', 1-`alpha') * 100	
		ret scalar fnr = (`2'/(`1'+`2'))*100     										/* false negative rate			*/
			local fnrden = `1'+`2'
			local fnrnum = `2'
			return scalar fnrub = invbinomial(`fnrden',`fnrnum', `alpha') * 100
			return scalar fnrlb = invbinomial(`fnrden',`fnrnum', 1-`alpha') * 100	
		

		// run tabi here to expand data to run -roctab-
		tabi `1' `2' \ `3' `4', replace		
		expand pop
		drop if !pop 					// drops zero values
		recode row (2=0)				// recode row values 2 to 0
		recode col (2=0)				// recode col values 2 to 0	
		
		if "`rowlabel'" != "" {
			label var row "`rowlabel'" 
		}

		if "`collabel'" != "" {
			label var col "`collabel'" 
		}
	
		/* roc curve */
		roctab row col, lev(`level')
		// local roc : di %05.4f r(area)
		ret scalar roc = r(area)*100
		ret scalar roclb = r(lb)*100
		ret scalar rocub = r(ub)*100
	
	} // end quietly

		// 2 X 2 matrix
		#delimit ;
		di _n in smcl in gr _col(14) "{hline 5}   Classified  {hline 5}" _n
                    `"   True    {c |}"' _col(22) `"+"' _col(35) 
                    `"-   {c |}"' _col(46) `"Total"' ;
		di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
		di    in smcl in gr _col(6) "+" _col(12) `"{c |} "'
              in ye %9.0g `1' _col(28) %9.0g `2'
              in gr `"  {c |}  "'
              in ye %9.0g `1'+`2' ;
		di    in smcl in gr _col(6) "-" _col(12) "{c |} "
              in ye %9.0g `3' _col(28) %9.0g `4'
              in gr `"  {c |}  "'
              in ye %9.0g `3'+`4' ;
		di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
		di    in smcl in gr `"   Total   {c |} "'
              in ye %9.0g `1'+`3' _col(28) %9.0g `2'+`4'
              in gr `"  {c |}  "'
              in ye %9.0g `1'+`2'+`3'+`4' _n ;
		#delimit cr	
		
		// table of results
		#delimit ;
		di _n ;
		di    in gr `"Measure"'	
		      in gr _col(42) `"Estimate"'
		 	  in gr	_col(52) `"[`level'% Conf. Interval]"' ;
		di    in smcl in gr "{hline 72}" ;
		di    in gr `"Sensitivity"' _col(33) `"A/(A+B)"'
              in ye %8.2f return(sens) `"%"'
			  in ye _col(51) %8.2f return(senslb) `"%"'
			  in ye _col(61) %8.2f return(sensub) `"%"' _n
              in gr `"Specificity"' _col(33) `"D/(C+D)"'
              in ye %8.2f return(spec) `"%"'
			  in ye _col(51) %8.2f return(speclb) `"%"'
			  in ye _col(61) %8.2f return(specub) `"%"' _n
              in gr `"Positive predictive value"' _col(33) `"A/(A+C)"'
              in ye %8.2f return(ppv) `"%"'
			  in ye _col(51) %8.2f return(ppvlb) `"%"'
			  in ye _col(61) %8.2f return(ppvub) `"%"' _n
              in gr `"Negative predictive value"' _col(33) `"D/(B+D)"'
              in ye %8.2f return(npv) `"%"'
			  in ye _col(51) %8.2f return(npvlb) `"%"'
			  in ye _col(61) %8.2f return(npvub) `"%"' ;
		di    in smcl in gr "{hline 72}"  ;
		di    in gr `"False positive rate"' _col(33) `"C/(C+D)"'
              in ye %8.2f return(fpr) `"%"' 
			  in ye _col(51) %8.2f return(fprlb) `"%"'
			  in ye _col(61) %8.2f return(fprub) `"%"' ;
		di	  in gr `"False negative rate"' _col(33) `"B/(A+B)"'
              in ye %8.2f return(fnr) `"%"'
			  in ye _col(51) %8.2f return(fnrlb) `"%"'
			  in ye _col(61) %8.2f return(fnrub) `"%"' ;
		di    in smcl in gr "{hline 72}"  ;	  
		di    in gr `"Correctly classified"' _col(27) `"A+D/(A+B+C+D)"'
			  in ye %8.2f return(all) `"%"' 
			  in ye _col(51) %8.2f return(alllb) `"%"'
			  in ye _col(61) %8.2f return(allub) `"%"' ;
		di    in smcl in gr "{hline 72}"  ;	  
		di    in gr `"ROC area"' _col(39)
			  in ye %9.2f return(roc) `"%"' 
			  in ye _col(51) %8.2f return(roclb) `"%"'
			  in ye _col(61) %8.2f return(rocub) `"%"' ;			  
		di    in smcl in gr "{hline 72}"  ;

		#delimit cr		
		
end

