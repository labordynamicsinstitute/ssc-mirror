/*******************************************************************************
*                                                                              *
*             Handles fitting the models and returning results                 *
*                                                                              *
*******************************************************************************/

*! fitit
*! v 0.0.9
*! 27FEB2024

// Drop program from memory if already loaded
cap prog drop fitit

// Define program
prog def fitit, eclass 

	// Version statement 
	version 15
	
	// Syntax
	syntax anything(name = cmd id="estimation command name"),				 ///   
			SPLit(passthru) RESults(string asis) [ KFold(integer 1) noall 	 ///   
			DISplay NAme(string asis)]

	// Check for missing name option
	if mi(`"`name'"') loc name xvfit
			
	// Create a collection to store estimation results
	if `c(stata_version)' >= 17 qui: collect create `name', replace
			
	// Test for invalid KFold option
	if `kfold' < 1 {
		
		// Display an error message
		di as err "There must always be at least 1 K-Fold.  This would be "	 ///   
		"the training set in a simple train/test split.  You specified "	 ///   
		"`kfold' K-Folds."
		
		// Return error code and exit
		err 198
		
	} // End IF Block for invalid K-Fold argument
	
	// Test whether the results option conforms to requirements to end with a 
	// letter
	if ustrregexm("`results'", "\d\$") {
		
		// Display error message
		di as err "The argument passed to results ends in a number.  The "	 ///   
		"last character must not be a number for this option."
		
		// Return error code
		err 198
		
	} // End IF Block for invalid results option
	
	// Create a macro to store the names of all the estimation results
	loc estres 
	
	// Call the command to generate the modified estimation command string
	cmdmod `cmd', `split' kf(`kfold')
	
	// Stores the returned modified prediction if expression so it can be 
	// returned by fitit
	loc predifin `r(predifin)'
	
	// Does the same with the macro used for the all training set component when
	// used with K-Fold CV
	loc kfpredifin `r(kfpredifin)'
	
	// Create a null local to store column names for results if displayed
	loc modord

	// Handles fitting for KFold and non-KFold CV
	forv k = 1/`kfold' {
		
		// Call the estimation command passed by the user
		if !mi(`"`: char _dta[modcmd]'"') {
			if `c(stata_version)' >= 17 qui: collect, name(`name'):`: char _dta[modcmd]'
			else qui: `: char _dta[modcmd]'
		}
		
		// Otherwise call the returned macro from cmdmod
		else {
			if `c(stata_version)' >= 17 qui: collect, name(`name'):`r(modcmd)'
			else `r(modcmd)'
		}
		
		// For simple train/test splits
		if `kfold' == 1 {
			
			// Add an appropriate title to the estimation results
			est title: Model Fit on Training Sample
		
			// Add corresponding title for display
			loc modord `modord' `k' "Training Set"
		
		} // End IF Block for simple train/test splits
		
		// Add a title for K-Fold cases
		else {
			
			// Adds an appropriate title to the estimation results
			est title: Model fit on Fold #`k'
			
			// Builds the titles for the display option
			loc modord `modord' `k' `"Fold #`k'"'
		
		} // End ELSE Block for K-Fold and LOO cases
		
		// Stores the estimation results in a more persistent way
		est sto `results'`k'
		
		// Return the estimation result name in a macro
		loc estres`k' "`results'`k'"
		
		// Add the name of the estimation results to the estres macro
		loc estres "`estres' `results'`k'"
			
	} // Loop over the KFolds

	// Test if K-Fold cross validation is being used
	if `kfold' > 1 & mi(`"`all'"') {
		
		// If the dataset characteristic is not missing
		if !mi(`"`: char _dta[kfmodcmd]'"') {
			
			// Call the estimation command stored in the characteristic
			if `c(stata_version)' >= 17 qui: collect, name(`name'):`: char _dta[kfmodcmd]'
			else qui: `: char _dta[kfmodcmd]'
		
		} // End IF Block for estimation command in characteristic
		
		// Otherwise, use the returned result from cmdmod
		else {
			if `c(stata_version)' >= 17 qui: collect, name(`name'):`r(kfmodcmd)'
			else qui: `r(kfmodcmd)'
		}
		// Test if user wants title added
		est title: Model Fitted on All Training Folds 
		
		// Adds a title to for the display option
		loc modord `modord' `= `kfold' + 1' "Whole Training Set"
		
		// Stores the estimation results in a more persistent way
		est sto `results'all
		
		// Return the estimation result name in a macro
		eret loc estresall "`results'all"
		
		// Add the name of the estimation results to the estres macro
		loc estres "`estres' `results'all"

	} // End IF Block for K-Fold CV fitting to all training data
	
	// Loop over the kfolds to return the individual stored result names
	forv k = 1/`kfold' {
		
		// Returns the individual estimation result names in their own macros
		eret loc estres`k' "`estres`k''"
		
	} // End Loop over the K-Folds to return the estimation result names
	
	// Return the names of all the stored estimation results
	eret loc estresnames "`estres'"
	
	// Return the predict macro 
	eret loc predifin `macval(predifin)'
	
	// Return the predict macro for the K-Fold case on all training data
	eret loc kfpredifin `macval(kfpredifin)'
		
	// Repost the estimation results to return them to users
	ereturn repost
	
	// Check for the display option
	if !mi("`display'") {
		
		// If Stata 17 or later
		if `c(stata_version)' >= 17 {
			
			// Collects standardized results from all models
			qui: collect style autolevels result _r_b _r_se N ll ll_0 r2 	 ///   
									 r2_a rmse rss mss df_m df_r F, name(`name')
										   
			// Don't display omitted levels in the results 
			qui: collect style showomit off, name(`name')
			
			// Don't display the base level of factor variables in the results
			qui: collect style showbase off, name(`name')
			
			// Don't display results for empty factor cells/interactions
			qui: collect style showempty off, name(`name')
			
			// Shows standard errors in parentheses
			qui: collect style cell result[_r_se], sformat("(%s)") name(`name')
			
			// Aligns the cell contents
			qui: collect style cell cell_type[item column-header], 			 ///   
													 name(`name') halign(center)
			
			// Omits the labels for coefficients and standard errors in the output
			qui: collect style header result[_r_b _r_se], level(hide) 		 ///   
														  name(`name')
			
			// Adds a little additional horizontal spacing between columns
			qui: collect style column, extraspace(1) name(`name')
			
			// Stacks the coefficients, SE, and other results and uses x as an 
			// interaction delimiter
			qui: collect style row stack, spacer delimiter(" x ") 			 ///   
							 name(`name') atdelimiter(" x ") bardelimiter(" x ")
										  
			// Defines levels for significance stars and adds a note to the end of 
			// the table with the definitions
			qui: collect stars _r_p 0.001 "***" 0.01 "**" 0.05 "*", 		 ///   
											  attach(_r_b) shownote name(`name')
			
			// Relabels some of the longer named model results to save space
			collect label levels result N "N" r2 "R^2" r2_a "Adj. R^2" 		 ///   
										F "F stat." rss "Residual SS" 		 ///   
										ll_0 "Log Likelihood, null model"    ///   
										mss "Model SS", name(`name') modify

			// Sets the numeric display format for all result cells to use a comma 
			// for the thousands delimiter and to display 3 significant digits
			qui: collect style cell result, name(`name') nformat(%24.3gc)
			
			// This attaches the labels for the results created during the model 
			// fitting above to the column headers
			qui: collect label levels cmdset `modord', name(`name')
			
			// This specifies how the results should be laid out.  The interaction 
			// in the first parenthetical is how the results for the coefficients 
			// and SE get displayed as rows and the second result provides the 
			// general model fit statistics.  The second parenthetical is used to 
			// say that there will be one column per estimation command collected.
			qui: collect layout (colname#result result)(cmdset)
			
			// Display the results
			collect preview
		
		} // End IF Block for Stata 17 or later
		
		// otherwise display results separately
		else {
			
			// Replay all the stored estimation results
			estimates replay `estres'
			
		} // End ELSE Block for older Stata

	} // End IF Block for display option
	
// End definition of the command
end



