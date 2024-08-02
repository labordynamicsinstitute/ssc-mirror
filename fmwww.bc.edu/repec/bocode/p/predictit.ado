/*******************************************************************************
*                                                                              *
*             Handles predicting the models and returning results              *
*                                                                              *
*******************************************************************************/

*! predictit
*! v 0.0.10
*! 22mar2024

// Drop program from memory if already loaded
cap prog drop predictit

// Define program
prog def predictit

	// Version statement 
	version 15
	
	// Syntax
	syntax [anything(name = cmd id="estimation command name")],				 ///   
			PStub(string asis) [ SPLit(varname)  Classes(integer 0) 		 ///   
			KFold(integer 1) THReshold(passthru) MODifin(string asis) 		 ///   
			KFIfin(string asis) noall PMethod(string asis) POpts(string asis)]
			
	// Assign estimates global to a local
	loc xvstartest $xvstartest

	// Test for invalid KFold option
	if `kfold' < 1 {
		
		// Display an error message
		di as err "There must always be at least 1 K-Fold.  This would be "	 ///   
		"the training set in a simple train/test split.  You specified "	 ///   
		"`kfold' K-Folds."
		
		// Return error code and exit
		err 198
		
	} // End IF Block for invalid K-Fold argument
	
	// Test the value of the classes option
	if `classes' < 0 {
		
		// Display an error message
		di as err "The classes option requires a value >= 0."
		
		// Return an error code
		err 125
		
	} // End IF Block for negative valued class arguments
			
	// For linear model cases use xb as the default prediction method
	if `classes' == 0 & mi(`"`pmethod'"') loc pmethod xb
	
	// For categorical model cases use pr as the default prediction method
	else if `classes' > 0 & mi(`"`pmethod'"') loc pmethod pr
			
	// Test if the user passed of the necesary info for this to work
	if mi(`"`cmd'"') & mi(`"`modifin'"') & mi(`"`: char _dta[predifin]'"') {
		
		// Display error message
		di as err "You must provide either the estimation command string "	 ///
		"or pass an argument to modifin to use this command if "			 ///   
		"{help cmdmod} was not called previously, or the characteristics "	 ///    
		"created by {help cmdmod} were removed."
		
		// Return an error code and exit
		err 197
		
	} // End IF Block for insufficient information for the command	 
				 
	// If the user passes a command string 
	else if !mi(`"`cmd'"') {
		
		// Make sure a split variable is passed
		if mi("`split'") {
		
			// Display an error message
			di as err "If you pass a command string as the first argument "	 ///   
			"you must also specify the variable that identifies the " 		 ///   
			"variable with the split group identifiers."
			
			// Return an error code and exit
			err 198
			
		} // End IF Block for insufficient options with command string.
		
		// If there is something passed to split confirm it exists
		else confirm v `split'
		
		// Generate the modified if expressions for predictions
		cmdmod `cmd', split(`split') kf(`kfold')
	
		// Then substitute the individual split case to modifin
		loc modifin : char _dta[predifin]
		
		// And substitute the K-Fold case for the entire training set
		loc kfifin : char _dta[kfpredifin]
			
	} // End IF Block for cases where the user passes the command string
	
	// If the user doesn't pass a command string
	else if mi(`"`cmd'"') & !mi(`"`modifin'"') {
		
		// Check if kfold is > 1 and the noall option is missing
		if `kfold' > 1 & mi(`"`all'"') {
			
			// Check for the modified kf if expression
			if mi(`"`kfifin'"') & mi(`"`: char _dta[kfpredifin]'"') {
				
				// Display an error message
				di as err "A modified if expression for the validation/test" ///   
				" predictions is required.  No values were passed to the "	 ///   
				"kfifin option and the characteristic created by cmdmod "	 ///   
				"was not found.  Include the noall option, provide an "  	 ///   
				"argument to the kfifin option, or ensure cmdmod is called."
				
				// Return error code
				err 198
				
			} // End IF Block for missing kfifin/char when potentially applicable
			
			// If the characteristic isn't missing
			else if mi(`"`kfifin'"') & !mi(`"`: char _dta[kfpredifin]'"') {
				
				// Set the macro using the characteristic
				loc kfifin : char _dta[kfpredifin]
				
			} // End ELSEIF block for missing arg but available characteristic
			
		} // End IF Block for checking for macro for KF all case
		
	} // End ELSE Block for no command string and present modifin
	
	// And the case to use if no command or modified if/in exp is passed
	else if mi(`"`cmd'`modifin'"') & !mi(`"`: char _dta[predifin]'"') {
		
		// Then substitute the individual split case to modifin
		loc modifin : char _dta[predifin]
		
		// And substitute the K-Fold case for the entire training set
		loc kfifin : char _dta[kfpredifin]
			
	} // End ELSEIF Block for the default case
	
	// Get the names of all stored results
	qui: estimates dir
	
	// Store all of the estimation result names
	loc enames `r(names)'
	
	// Remove any estimates that existed prior to model fitting
	loc enames : list enames - xvstartest
			
	// Handles predictting for KFold and non-KFold CV
	forv k = 1/`kfold' {
		
		// Check to verify that the modified if expression ends with a numeric 
		// value and if it is missing a numeric value at the iterator
		if !ustrregexm(`"`modifin'"', "\d\$") loc modifin `modifin' \`k'
		
		// Get the name by matching the value of k at the end of the string and 
		// pass that name to the estimates restore command below.
		if ustrregexm(`"`enames'"', "(\s?[a-zA-Z]+`k'(\s|\$))") {
			
			// Store the matching estimation result name
			loc rname `"`= trim(ustrregexs(1))'"'
			
		} // End IF Block for matching regex
		
		// Stores the estimation results in a more persistent way
		qui: est restore `rname'
		
		// Test whether this is a "regression" task
		if `classes' == 0 {
			
			// If it is, predict on the validation sample:
			qui: predict double `pstub'`k' `modifin', `pmethod' `popts'
			
		} // End IF Block for "regression" tasks
		
		// Otherwise
		else {
			
			// Call the classification program
			// Also need to handle the if statement here as well
			qui: classify `classes' `modifin', `threshold' ps(`pstub'`k'_)	 ///   
												po(`popts')
				
		} // End ELSE Block for classifcation tasks
		
	} // Loop over the KFolds
	
	// Create the combined variable as a double for continuous outcomes
	if `classes' == 0 qui: egen double `pstub' = rowfirst(`pstub'*)
	
	// For classification models
	else qui: egen byte `pstub' = rowfirst(`pstub'*)
	
	// Attach a variable label to the predicted variable
	la var `pstub' "Predicted value of `e(depvar)'"
	
	// Test if K-Fold cross validation is being used and the user wants the 
	// predicted values based on the entire training set.
	if `kfold' > 1 & mi("`all'") {
		
		// Stores the estimation results in a more persistent way
		cap: est restore *all
		
		// If the estimation on all the training data is not done
		if _rc != 0 {
			
			// Remove all the predicted value variables
			drop `pstub'* `pstub'
			
			// Display an error message
			di as err "If {help fitit} was called without the noall option " ///   
			"predictit must also use that option."
			
			// Throw an error code
			err 198
			
		} // End IF Block for all training sample prediction w/o all sample fit
		
		// Restore the estimation results
		qui: est restore *all
		
		// Test whether this is a "regression" task
		if `classes' == 0 {
			
			// If it is, predict on the validation sample:
			qui: predict double `pstub'all `kfifin', `pmethod' `popts'
			
		} // End IF Block for "regression" tasks
		
		// Otherwise
		else {
			
			// Call the classification program
			// Also need to handle the if statement here as well
			qui: classify `classes' `kfifin', `threshold' ps(`pstub'all) 	 ///   
											  po(`popts')
				
		} // End ELSE Block for classifcation tasks
		
		// Add variable label for the all training set case
		la var `pstub'all "Predicted value of `e(depvar)' from model w/full training set"

	} // End IF Block for K-Fold CV predictting to all training data
	
	// Get all of the potential names
	qui: ds `pstub'*
	
	// Store the pstub variables in a macro
	loc todrop `r(varlist)'
	
	// Store the pstub variables that should not be dropped
	loc nodrop `pstub' `pstub'all

	// Remove the variables that should be retained from todrop
	loc todrop : list todrop - nodrop
	
	// Drop the variables that should be dropped
	qui: drop `todrop'
	
// End definition of the command
end



