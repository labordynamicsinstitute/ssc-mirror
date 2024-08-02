/*******************************************************************************
*                                                                              *
*     Handles classification results to ensure classes are returned            *
*                                                                              *
*******************************************************************************/

*! classify
*! v 0.0.6
*! 08mar2024

// Drop program from memory if already loaded
cap prog drop classify

// Define program
prog def classify, 

	// Version statement 
	version 15
	
	// Syntax
	syntax anything(name = classes id = "Number of Classes") [if] ,			 ///   
			PStub(string asis) [ THReshold(real 0.5) PMethod(string asis)	 ///   
			POpts(string asis)]

	// Mark the sample that will be used
	marksample touse, strok
	
	// Set default prediction method if missing
	if mi(`"`pmethod'"') loc pmethod pr
	
	// Ensure classes is an integer
	if mod(`classes', 1) != 0 {
		
		// Display an error message
		di as err "The number of classes for a classification model must be" ///
		" an integer.  You specified `classes' number of classes."
		
		// Return error code and exit 
		error 126
		
	} // End of IF Block to handle invalid number of classes
	
	// Ensure classes has a value that is >= 2
	if `classes' < 2 {
		
		// Display an error message
		di as err "The number of classes specified for your model is < 2."
		
		// Return error code and exit
		error 125		
		
	} // End IF Block for invalid number of classes
	
	// Test that the threshold value is valid
	if (`threshold' >= 1 | `threshold' <= 0) {
		
		// Display an error message
		di as err "The classification threshold must be in (0, 1).  You "	 ///   
		"specified a value of `threshold'."
		
		// Return error code and exit
		error 125
		
	} // End IF Block to handle invalid threshold values
	
	// Test the number of classes:
	if `classes' == 2 {
		
		// Generate predicted values
		predict double `pstub' if `touse', `pmethod' `popts'
		
		// Replace predicted values with classes
		replace `pstub' = cond(`pstub' < `threshold' & !mi(`pstub'), 0,	 ///   
						  cond(`pstub' >= `threshold' & !mi(`pstub'), 1, .))
		
	} // End IF Block for binary classification problems
	
	// For values > 2
	else {
		
		// Generate predicted values
		predict double `pstub'_* if `touse', `pmethod' `popts'
		
		// Get the names of the variables that were just generated
		qui: ds `pstub'_*
		
		// Store varlist
		loc pvars `r(varlist)'
		
		// Identifies the highest probability value
		egen double `pstub' = rowmax(`pvars')
		
		// Loop over the predicted variable names
		foreach v in `pvars' {
			
			// Remove all letters from the variable name
			loc clsval `= ustrregexra("`v'", "^.*_", "")'
			
			// Replace the value of pstub with the class value if that is the 
			// highest probability
			replace `pstub' = `clsval' if `pstub' == `v' & !mi(`pstub')
			
		} // End of Loop over the predicted variables
		
		// Remove the individual predicted variables
		drop `pvars'
		
	} // End ELSE Block for multinomial/ordinal classification problems
	
	// Compress the classification variable
	qui: compress `pstub'
	
// End definition of the command
end

