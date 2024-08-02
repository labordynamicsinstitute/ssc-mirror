/*******************************************************************************
*                                                                              *
*             Handles the validation/testing part of the process               *
*                                                                              *
*******************************************************************************/

*! validateit
*! v 0.0.16
*! 05mar2024

// Drop program from memory if already loaded
cap prog drop validateit

// Define program
prog def validateit, rclass 

	// Version statement 
	version 15
	
	// Syntax
	syntax , MEtric(string asis) PStub(string asis) SPLit(varname) 			 ///   
	[ Obs(varname) MOnitors(string asis) DISplay KFold(integer 1) noall loo  ///   
	NAme(string asis) ]

	// Test to ensure the metric is not included in the monitor
	if `: list metric in monitors' {
		
		// Display an informative message
		di as error "The metric `metric' is included in the monitors `monitors'."
		
		// Throw an error code
		err 134
		
	} // End IF Block to handle metric included in monitors
	
	// Test if missing observed outcome variable name
	if mi("`obs'") & mi("`e(depvar)'") {
	
		// Display an error message
		di as err "If the dependent variable is not passed to {opt obs} it " ///   
		"must be accessible in e(depvar)."
		
		// Throw an error code and exit
		err 100
	
	} // End IF Block for unknown dependent variable
	
	// If no argument is passed to the option but it is found in e(depvar) 
	else if mi("`obs'") & !mi("`e(depvar)'") loc obs `e(depvar)'
	
	// Test for invalid KFold option
	if `kfold' < 1 {
		
		// Display an error message
		di as err "There must always be at least 1 K-Fold.  This would be "	 ///   
		"the training set in a simple train/test split.  You specified "	 ///   
		"`kfold' K-Folds."
		
		// Return error code and exit
		err 198
		
	} // End IF Block for invalid K-Fold argument
		
	// Test for invalid kfold with loo option
	if `kfold' == 1 & !mi("`loo'") {
		
		// Display an error message
		di as err "Leave-One-Out cross-validation cannot be used with a "	 ///   
		"single K-Fold."
		
		// Return error code and exit
		err 198
		
	} // End IF block for invalid kfold & loo combination
	
	// When using K-Fold and not specifying noall
	if `kfold' > 1 & mi(`"`all'"') {
		
		// Capture the code from confirming the *all variable's presence
		cap: confirm v `pstub'all
		
		// If this fails
		if _rc != 0 {
			
			// Print an error message to the console
			di as err "The variable `pstub'all was not found and you are "	 ///   
			"requesting evaluating metrics that require that variable." _n   ///   
			"You can either pass the noall option or predict the values "	 ///   
			"from your models again to generate the `pstub'all variable."
			
			// Throw an error code and exit
			err 111
			
		} // End IF Block for missing `pstub'all variable
		
	} // End IF Block for detecting missing `pstub'all w/K-Fold and missing noall
	
	// Parse the metric option
	_parse_monitors `metric'
	
	// Verify that there is only a single metric
	if `r(n)' > 1 {
		
		// Display an error message
		di as err "Users can only specify a single metric."
		
		// Throw an error code
		err 134
		
	} // End IF Block for invalid number of metric
	
	// Create macro to store all returned scalar names
	loc allnms
	
	// Mark the sample that will be used to compute the validation metrics for 
	// each K-Fold
	tempvar touse
	
	// Create the tempvariable used to identify the set to use for validation
	qui: g byte `touse' = 0
	
	// Figure out the number of splits used in the dataset
	mata: st_numscalar("vals", rows(uniqrows(st_data(., "`split'"))))
	
	// There will be two ID values > kfold in a TVT split
	if `vals' - `kfold' == 2 loc ditxt "Validation Set"
	
	// Otherwise it should be a TT split
	else loc ditxt "Test Set"
	
	// Set display related macros
	if !mi("`display'") {
		
		// Defines macros to use to construct the display strings used below
		loc kfditxt "for K-Fold #\`k'"
		loc kfalttxt "for results on entire Training Set"
		loc montxt "Monitor Results"
		loc metrictxt "Metric Result"
		
	} // End IF Block for user requested display
	
	// Check if the name parameter is missing or not
	if mi(`"`name'"') loc name xvval
	
	// Create a collection using the default name
	if `c(stata_version)' >= 17 qui: collect create `name', replace
		
	// Locate the labels for the metrics
	cap: findfile xvlabels.stjson
	
	// If the file is located
	if _rc == 0 & `c(stata_version)' >= 17 {
		
		// Load the capture labels
		collect label use `"`r(fn)'"', name(`name')
		
	} // End IF Block to load collection labels for validation metrics
	
	// If there is only a single fold
	if `kfold' == 1 & mi("`loo'") {

		// Set the touse tempvariable
		qui: replace `touse' = cond(`split' == 2, 1, 0)
		
		// Calls subroutine to compute all of the validation metrics/monitors
		// and return them
		getstats, me(`metric') p(`pstub') o(`obs') t(`touse') st(xv) 		 ///   
		monitors(`monitors') 
	
		// Adds the names so all monitor/metric names can be returned
		loc allnms `r(names)'
		
		// Loop over the returned names
		foreach i in `r(names)' {
			
			// Return the corresponding scalars
			ret sca `i' = r(`i')
						
		} // End Loop over the returned scalars
		
		// Return the matrix with all of the results
		matrix res = r(mtrx) 
		
		// Set the rownames 
		mat rownames res = `r(names)'
		
		// Set the column name
		mat colnames res = "`ditxt'"
	
	} // End IF Block for no-K-Folds
	
	// If this involves K-Fold CV
	else if `kfold' > 1 & mi("`loo'") {
		
		// Initialize this to see if it helps with removing the quotation marks
		// when used below
		loc colnms
		
		// Loop over the K-Folds
		forv k = 1/`kfold' {
			
			// Sets local macro with column names
			loc colnms `"`colnms' "Fold `k'""'
			
			// Set the value of the touse tempvariable
			qui: replace `touse' = cond(`split' == `k', 1, 0)

			// Calls subroutine to compute all of the validation metrics/monitors
			// and return them
			getstats, me(`metric') p(`pstub') o(`obs') t(`touse') st(xv) 	 ///   
			monitors(`monitors') sf(`k')
		
			// Adds the names so all monitor/metric names can be returned
			loc allnms `r(names)'
			
			// Loop over the returned names
			foreach i in `r(names)' {
				
				// Return the corresponding scalars
				ret sca `i' = r(`i')
							
			} // End Loop over the returned scalars
			
			// Gets the matrix returned by getstats
			if `k' == 1 mat res = r(mtrx)
			
			// Return the matrix with all of the results
			else mat res = (res, r(mtrx)) 

			// Resets the value of this macro
			loc rnames 

			// If the user does not specify noall
			if `k' == `kfold' & mi(`"`all'"') {
				
				// Adds the last column name
				loc colnms `"`colnms' "`ditxt'""'
				
				// Update the variable that IDs the sample to use for the metrics
				qui: replace `touse' = cond(`split' == `= `kfold' + 1', 1, 0)
				
				// Call the subroutine with modified arguments (note the use of all)
				getstats, me(`metric') p(`pstub'all) o(`obs') t(`touse') st(xv)  ///   
				monitors(`monitors') sf(all)

				// Adds the names of these scalars to the allnms macro
				loc allnms `allnms' `r(names)'
				
				// Loop over the returned scalar names
				foreach i in `r(names)' {
					
					// Return those scalars
					ret sca `i' = r(`i')
					
				} // End Loop over the returned scalars
				
				// Update the matrix to include the additional results from the 
				// validation/test split
				matrix res = (res, r(mtrx))
				
			} // End IF Block to compute metrics on the validation/test split

		} // End Loop over K-Folds
			
		// Set rownames for the returned matrix based on the monitors/metrics
		mat rownames res = `r(names)'
		
		// Set the column names for the returned matrix based on the number of 
		// K-Folds and what style of split is used
		mat colnames res = `colnms'
					
	} // End ELSE Block for K-Fold CV
	
	// Otherwise it will be for leave-one-out CV
	else if `kfold' > 1 & !mi("`loo'") {
		
		// Set the value of the touse tempvariable
		qui: replace `touse' = cond(`split' <= `kfold', 1, 0)

		// Calls subroutine to compute all of the validation metrics/monitors
		// and return them
		getstats, me(`metric') p(`pstub') o(`obs') t(`touse') st(xv) 		 ///   
		monitors(`monitors') sf(1)
	
		// Adds the names so all monitor/metric names can be returned
		loc allnms `r(names)'
		
		// Loop over the returned names
		foreach i in `r(names)' {
			
			// Return the corresponding scalars
			ret sca `i' = r(`i')
						
		} // End Loop over the returned scalars
		
		// Return the matrix with all of the results
		matrix res = r(mtrx) 

		// Resets the value of this macro
		loc rnames 

		// If the user does not specify noall
		if mi(`"`all'"') {
			
			// Update the variable that IDs the sample to use for the metrics
			qui: replace `touse' = cond(`split' == `= `kfold' + 1', 1, 0)
			
			// Call the subroutine with modified arguments (note the use of all)
			getstats, me(`metric') p(`pstub'all) o(`obs') t(`touse') st(xv)  ///   
			monitors(`monitors') sf(all)

			// Adds the names of these scalars to the allnms macro
			loc allnms `allnms' `r(names)'
			
			// Loop over the returned scalar names
			foreach i in `r(names)' {
				
				// Return those scalars
				ret sca `i' = r(`i')
				
			} // End Loop over the returned scalars
			
			// Update the matrix to include the additional results from the 
			// validation/test split
			matrix res = (res, r(mtrx))
			
		} // End IF Block to compute metrics on the validation/test split
		
		// Set rownames for the returned matrix based on the monitors/metrics
		mat rownames res = `r(names)'
		
		// Set column names for the returned matrix based on the samples
		mat colnames res = "Leave-One-Out" "`ditxt'"
				
	} // End ELSEIF Block for LOO CV case
	
	// Returns a macro containing the names of all scalars returned
	ret loc allnames = "`allnms'"
	
	// Returns a matrix containing all of the results
	ret mat xv = res, copy
	
	// If the display option is passed
	if !mi("`display'") {
		
		// Get the row names
		loc rnames : rown res, quoted
		
		// Get the column names
		loc cnames : coln res, quoted
		
		// Test the Stata version
		if `c(stata_version)' >= 17 {
		
			// Get the resulting matrix into the collection
			collect get xv = res, name(`name')
			
			// Create a title for the display
			collect title "Cross-Validation Results", name(`name')
			
			// Create a layout
			qui: collect layout (rowname[`rnames'])(colname[`cnames'])(cmdset)
			
			// Display the metrics in a not horrible layout
			collect preview
		
		} // End IF Block for current Stata display
		
		// For older Stata
		else {
			
			// Display the matrix of results
			mat li res			
			
		} // End ELSE Block for older Stata display
		
	} // End IF Block to display results if requested by the user

// End of program definition
end

// Subroutine to compute all of the stats and build a matrix that will persist 
// over all of the loops to return results as a table instead of printing 
// individually
prog def getstats, rclass

	// Defines the syntax for the sub-routine
	syntax , MEtric(string asis) Pstub(string asis) Obs(string asis) 		 ///  
			 Touse(string asis) STo(string asis) 							 ///   
			[ MOnitors(string asis) SFx(string asis)]
	
	// Parse the monitors option
	_parse_monitors `monitors'
	
	// Store the parsed monitors
	loc monargs `"`r(mons)'"'
	
	// Count the words in monitors
	loc mons `r(n)'
	
	// Create index for matrix
	loc m `= `mons' + 1'
	
	// Initialize the storage matrix in mata
	mata: `sto' = J(`m', 1, .)
	
	// Create a macro with the names that get returned
	loc rnms 
	
	// Only execute if there are monitors
	if !mi("`mons'") & `mons' >= 1 {
		
		// Loop over the monitors
		forv i = 1/`mons' {
			
			// Get the name of the function for monitoring
			loc mon : word `i' of `monargs'
			
			// Get the monitor name from the parsed string
			mata: getname(`"`mon'"', "monnm")
			
			// Get any arguments passed to the monitor
			mata: getarg(`"`mon'"', "mnopt")
			
			// Call the mata function
			mata: `sto'[`i', 1] = `monnm'("`pstub'", "`obs'", "`touse'", `mnopt')
			
			// Creates a Stata scalar with the appropriate value
			mata: st_numscalar("`monnm'`sfx'", `sto'[`i', 1])
			
			// Sets the return value for the scalar
			return scalar `monnm'`sfx' = `= `monnm'`sfx''
			
			// Add this name to rnms
			loc rnms `rnms' `monnm'`sfx'
			
		} // End loop over monitors

	} // End IF Block to compute monitors only if requested
		
	// Get the name of the metric (in case there are options passed to it)
	mata: getname(`"`metric'"', "metnm")
	
	// Get any arguments passed to the metric
	mata: getarg(`"`metric'"', "meopt")
	
	// Call the mata function for the metric
	mata: `sto'[`m', 1] = `metnm'("`pstub'", "`obs'", "`touse'", `meopt')
	
	// Push the value into a scalar
	mata: st_numscalar("`metnm'sc", `sto'[`m', 1])
	
	// Sets the return value for the scalar
	return scalar metric`sfx' = `= `metnm'sc'
	
	// Add this name to rnms
	loc rnms `rnms' metric`sfx'

	// Return the column from the matrix of results to a stata matrix
	mata: st_matrix("vmat", `sto')
	
	// Sets the return matrix value
	return matrix mtrx = vmat
	
	// Returns the name of the metrics/monitors
	ret loc names = "`rnms'"
	
// End of subroutine to compute the statistics			
end

// Define subroutine to handle parsing of monitors option
prog def _parse_monitors, rclass

	// Define syntax
	syntax [anything(name = monitors id = "Options passed to monitors")]
	
	// If there are no options passed to monitors return an empty string
	if mi(`"`monitors'"') {
		
		// Return an empty string for the monitors
		ret loc mons = ""
		
		// Return a value of 0 for the number of monitors
		ret loc n = 0
		
	} // End IF Block for no monitors

	// Otherwise if monitors is not empty
	else {
		
		// Parse the contents initially
		gettoken 1 2 : monitors, bind
		
		// Store the first argument in the macro that will be used to return 
		// all the arguments
		loc args `"`args' `"`1'"' "'
		
		// Continue to parse the remainder of the string 
		while !mi(`"`2'"') {
			
			// Parse the next token from the remaining portion of the macro
			gettoken 1 2 : 2, bind
			
			// Add the next token to the parsed and quoted tokens
			loc args `"`args' `"`1'"' "'
			
		} // End of WHILE loop to parse monitor arguments
		
		// Get the number of arguments parsed 
		ret loc n = `"`: word count `args''"'
		
		// Return the parsed monitor options
		ret loc mons = `"`args'"'
		
	} // End ELSE Block for optional arguments to monitors
	
// End of subroutine definition
end

	