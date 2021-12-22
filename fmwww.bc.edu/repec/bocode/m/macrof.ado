program  macroF ,rclass
*! version 0.1.0  Aug, 2021 
    version 17.0
    syntax [if] [in], pred(str) true(str) 
	
	// the variables pred and true must have integer values (not strings)
	confirm numeric variable `pred' `true'
	
	//  obs excluded by [if] [in]
	marksample touse , novarlist
	qui count if `touse' 
	if r(N) == 0 { 
		error 2000 
	} 
	local truth="`true'" 
	
	preserve 
	qui drop if !`touse'
	
	qui levelsof `truth'
	local mylevels = "`r(levels)'"
	local n_levels= wordcount("`mylevels'")
	local macroF=0

	tempvar true1 pred1
	qui gen `true1'=.
	qui gen `pred1'=.
	di "Level    F1"
	foreach i of numlist 1/`n_levels' { 
		local level= word("`mylevels'",`i')
		// generate indicators for each level
		qui replace `true1'= `truth'==`level' if !missing(`truth')
		qui replace `pred1' = `pred'==`level' if !missing(`truth')
		qui evalcrit2, pred(`pred1')  true(`true1') // evalcrit is only for binary
		local macroF= `macroF' + `r(F)'
		di %5.0g `level' "   "   %8.5f `r(F)' 
	}
	local macroF=`macroF'/`n_levels'
	di " "
	di "macroF=" `macroF'
	return scalar macroF=`macroF'
end
//////////////////////////////////////////////////////////////////////////////////
// This is a copy of a separate program, evalcrit. 
// I have changed the name to evalcrit2 just to avoid confusion.
// I am including it in this file to make the macroF program independent.
program  evalcrit2 ,rclass
// version 0.3.1  Dec, 2020 added round
    version 13.1
    syntax [if] [in], pred(str) true(str) [ round(real 0.0001) ]

	//  obs excluded by [if] [in]
	marksample touse , novarlist
	qui count if `touse' 
	if r(N) == 0 { 
		error 2000 
	} 
	preserve 

	local binary=1
	qui tab `pred' if `touse'
	if r(r)>2 local binary=0
	qui tab `true' if `touse'
	if r(r)>2 local binary=0
	
	tempname TP TN FN FP F jaccard
	if `binary' {
		qui count if `pred'==1 & `true'==1 & `touse'
		scalar `TP'=r(N)
		qui count if `pred'==0 & `true'==0 & `touse'
		scalar `TN'=r(N)
		qui count if `pred'==0 & `true'==1 & `touse'
		scalar `FN'=r(N)
		qui count if `pred'==1 & `true'==0 & `touse'
		scalar `FP'=r(N)
		scalar `F'= 2 *`TP' / (2* `TP' + `FP' + `FN' )
		scalar `jaccard' = `TP' / (`TP' + `FP' + `FN' )
		di "Sensitivity: " round(`TP'/(`TP'+`FN'),`round')
		di "Specificity: " round(`TN'/(`TN'+`FP'),`round')
		di "F:           " round(`F',`round')
		di "Jaccard:     " round(`jaccard',`round')
	}

	tempvar correct
	tempname acc
	qui gen `correct'= `pred' == `true' if `touse'
	qui sum `correct' if `touse'
        scalar `acc'= r(mean)
	di "Accuracy:    " round(`acc',`round')

	return scalar accuracy = `acc'
	
	if `binary' {
		return scalar sensitivity = `TP'/(`TP'+`FN')
		return scalar specificity = `TN'/(`TN'+`FP')
		return scalar F = `F'
		return scalar jaccard= `jaccard'
	}
end
/////////////////////////////////////////////////////////////////
// version history of macroF
* version 0.1.0  Aug , 2021


