*! 1.0.0 Ariel Linden 06Jun2015

program define looclass, rclass
version 13.0

	syntax varlist(min=2 numeric fv) [if] [in] 		///
				[fweight iweight pweight]  ,  		///
				[CUToff(real 0.50) 					///
				PROBit								///
				FIGure *]                               


	quietly {
	
	// Get Y and X variables
	gettoken dvar xvar : varlist
	
	marksample touse
	count if `touse'
	if r(N) == 0 error 2000
	local N = r(N)
	replace `touse' = -`touse'

	if `cutoff'<0 | `cutoff'>1 { 
                di in red `"cutoff() must be between 0 and 1"'
                exit 198
    }

	
	tempvar train
	
// run logit or probit regression on training (full) sample
	if "`probit'" != "" {
		probit `dvar' `xvar' if `touse' [`weight' `exp'], `options'
	}
	else logit `dvar' `xvar' if `touse' [`weight' `exp'], `options'
	predict `train'
	

	// collect cell values for classification
	count if `dvar' !=0 & `train' >= `cutoff' & `touse'
	local a1 = round((r(N)),1)
                
	count if `dvar' ==0 & `train' >= `cutoff' & `touse'
	local b1 = round((r(N)),1)
                
	count if `dvar' !=0 & `train' <`cutoff' & `touse'
	local c1 = round((r(N)),1)
                
	count if `dvar' ==0 & `train' <`cutoff' & `touse'
	local d1 = round((r(N)),1)
	
	
	tempvar yhat test

// run logit or probit regression on test (loo) sample
	gen `test'=.
	} //end quietly
	
	// fancy setup for dots
	di _n
    di as txt "Iterating across (" as res `N' as txt ") observations"
	di as txt "{hline 4}{c +}{hline 3} 1 " "{hline 3}{c +}{hline 3} 2 " "{hline 3}{c +}{hline 3} 3 " "{hline 3}{c +}{hline 3} 4 " "{hline 3}{c +}{hline 3} 5 "
	
	//loop through observations
	forval i = 1/`N' {
	_dots `i' 0

	quietly {
	if "`probit'" != "" {
		probit `dvar' `xvar' if _n!=`i' & `touse' [`weight' `exp'], `options'
	}
	else logit `dvar' `xvar' if _n!=`i' & `touse' [`weight' `exp'], `options'

	predict `yhat' if _n==`i' 
	replace `test' = `yhat' if _n==`i'
	drop `yhat'
	}
	} // end quietly 
	
	quietly {
	// collect cell values for classification
	count if `dvar' !=0 & `test' >=`cutoff' & `touse'
	local a2 = round((r(N)),1)
                
	count if `dvar' ==0 & `test' >= `cutoff' & `touse'
	local b2 = round((r(N)),1)
                
	count if `dvar' !=0 & `test' <`cutoff' & `touse'
	local c2 = round((r(N)),1)
                
	count if `dvar' ==0 & `test' <`cutoff' & `touse'
	local d2 = round((r(N)),1)

	// collect values for ROC area
	roctab `dvar' `train'
*	local roc1 = round(r(area),0.001)
	local roc1="0"+string(round(r(area),0.0001))	
	
	roctab `dvar' `test'
	local roc2="0"+string(round(r(area),0.0001))	
	} // end quietly
	
	* Graph the ROC curves
	if "`figure'" != "" {
		roccomp `dvar' `train' `test' , graph legend(rows(2) order(1 2 3)  label(1 "Training ROC area: `roc1'") label(2 "Test ROC area: `roc2'") label(3 "Reference") )
	}

	/* double save in S_# and r() */
    
	* for training data
	ret scalar P_corr_1 = ((`a1'+`d1')/(`a1'+`b1'+`c1'+`d1'))*100 /* correctly classified */
	ret scalar P_p1_1 = (`a1'/(`a1'+`c1'))*100     				/* sensitivity          */
	ret scalar P_n0_1 = (`d1'/(`b1'+`d1'))*100     				/* specificity          */
	ret scalar P_p0_1 = (`b1'/(`b1'+`d1'))*100     				/* false + given ~D     */
	ret scalar P_n1_1 = (`c1'/(`a1'+`c1'))*100     				/* false - given D      */
	ret scalar P_1p_1 = (`a1'/(`a1'+`b1'))*100     				/* + pred value         */
	ret scalar P_0n_1 = (`d1'/(`c1'+`d1'))*100     				/* - pred value         */
	ret scalar P_0p_1 = (`b1'/(`a1'+`b1'))*100     				/* false + given +      */
	ret scalar P_1n_1 = (`c1'/(`c1'+`d1'))*100     				/* false - given -      */
	ret scalar roc1 = `roc1'									/* roc curve 		    */
	* for test data
	ret scalar P_corr_2 = ((`a2'+`d2')/(`a2'+`b2'+`c2'+`d2'))*100 /* correctly classified */
	ret scalar P_p1_2 = (`a2'/(`a2'+`c2'))*100     				/* sensitivity          */
	ret scalar P_n0_2 = (`d2'/(`b2'+`d2'))*100     				/* specificity          */
	ret scalar P_p0_2 = (`b2'/(`b2'+`d2'))*100     				/* false + given ~D     */
	ret scalar P_n1_2 = (`c2'/(`a2'+`c2'))*100     				/* false - given D      */
	ret scalar P_1p_2 = (`a2'/(`a2'+`b2'))*100     				/* + pred value         */
	ret scalar P_0n_2 = (`d2'/(`c2'+`d2'))*100     				/* - pred value         */
	ret scalar P_0p_2 = (`b2'/(`a2'+`b2'))*100     				/* false + given +      */
	ret scalar P_1n_2 = (`c2'/(`c2'+`d2'))*100     				/* false - given -      */
	ret scalar roc2 = `roc2'									/* roc curve 		    */

    #delimit ; 
 	di _n ;	
	di _n in gr `"Classification Table for Training Data:"' ;
		
		
	di _n in smcl in gr _col(15) "{hline 8} True {hline 8}" _n
                    `"Classified {c |}"' _col(22) `"D"' _col(35) 
                    `"~D  {c |}"' _col(46) `"Total"' ;
    di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
    di    in smcl in gr _col(6) "+" _col(12) `"{c |} "'
              in ye %9.0g `a1' _col(28) %9.0g `b1'
              in gr `"  {c |}  "'
              in ye %9.0g `a1'+`b1' ;
    di    in smcl in gr _col(6) "-" _col(12) "{c |} "
              in ye %9.0g `c1' _col(28) %9.0g `d1'
              in gr `"  {c |}  "'
              in ye %9.0g `c1'+`d1' ;
    di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
    di    in smcl in gr `"   Total   {c |} "'
              in ye %9.0g `a1'+`c1' _col(28) %9.0g `b1'+`d1'
              in gr `"  {c |}  "'
              in ye %9.0g `a1'+`b1'+`c1'+`d1' ;
        
	di _n ;	
    di _n in gr `"Classification Table for Test Data:"' ;
		
		
	di _n in smcl in gr _col(15) "{hline 8} True {hline 8}" _n
                    `"Classified {c |}"' _col(22) `"D"' _col(35) 
                    `"~D  {c |}"' _col(46) `"Total"' ;
    di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
    di    in smcl in gr _col(6) "+" _col(12) `"{c |} "'
              in ye %9.0g `a2' _col(28) %9.0g `b2'
              in gr `"  {c |}  "'
              in ye %9.0g `a2'+`b2' ;
    di    in smcl in gr _col(6) "-" _col(12) "{c |} "
              in ye %9.0g `c2' _col(28) %9.0g `d2'
              in gr `"  {c |}  "'
              in ye %9.0g `c2'+`d2' ;
    di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
    di    in smcl in gr `"   Total   {c |} "'
              in ye %9.0g `a2'+`c2' _col(28) %9.0g `b2'+`d2'
              in gr `"  {c |}  "'
              in ye %9.0g `a2'+`b2'+`c2'+`d2' ;		
		
	di _n ;	
	di _n in gr `"Classified + if predicted Pr(D) >= `cutoff'"' _n
                    `"True D defined as `y' != 0"' ;
        
	di    in gr _col(45) `"Training"' _col(58) `"Test"';
	di    in smcl in gr "{hline 64}" ;
    di    in gr `"Sensitivity"' _col(33) `"Pr( +| D)"'
              in ye %8.2f return(P_p1_1) `"%"' _col(55) in ye %8.2f return(P_p1_2) `"%"' _n
              in gr `"Specificity"' _col(33) `"Pr( -|~D)"'
              in ye %8.2f return(P_n0_1) `"%"' _col(55) in ye %8.2f return(P_n0_2) `"%"' _n
              in gr `"Positive predictive value"' _col(33) `"Pr( D| +)"'
              in ye %8.2f return(P_1p_1) `"%"' _col(55) in ye %8.2f return(P_1p_2) `"%"' _n
              in gr `"Negative predictive value"' _col(33) `"Pr(~D| -)"'
              in ye %8.2f return(P_0n_1) `"%"' _col(55) in ye %8.2f return(P_0n_2) `"%"' ;
    di    in smcl in gr "{hline 64}"  ;
    di    in gr `"False + rate for true ~D"' _col(33) `"Pr( +|~D)"'
              in ye %8.2f return(P_p0_1) `"%"' _col(55) in ye %8.2f return(P_p0_2) `"%"' _n
              in gr `"False - rate for true D"' _col(33) `"Pr( -| D)"'
              in ye %8.2f return(P_n1_1) `"%"'  _col(55) in ye %8.2f return(P_n1_2) `"%"' _n
              in gr `"False + rate for classified +"' _col(33) `"Pr(~D| +)"'
              in ye %8.2f return(P_0p_1) `"%"' _col(55) in ye %8.2f return(P_0p_2) `"%"' _n
              in gr `"False - rate for classified -"' _col(33) `"Pr( D| -)"'
              in ye %8.2f return(P_1n_1) `"%"' _col(55) in ye %8.2f return(P_1n_2) `"%"';
    di    in smcl in gr "{hline 64}"  ;
    di    in gr `"Correctly classified"' _col(42) 
              in ye %8.2f return(P_corr_1) `"%"' _col(55) in ye %8.2f return(P_corr_2) `"%"' ;
    di    in smcl in gr "{hline 64}"  ;
	di    in gr `"ROC area"' _col(42)
			  in ye %9.4f return(roc1)  _col(55) in ye %9.4f return(roc2)  ;
	di    in smcl in gr "{hline 64}"  ;
	

end ;

