/*******************************************************************************
*                                                                              *
*             Handles splitting the data set into train/test,                  *
*               train/validation/test, or K-Fold samples.                      *
*                                                                              *
*******************************************************************************/

*! splitit
*! v 0.0.11
*! 28FEB2024

// Drop program from memory if already loaded
cap prog drop splitit

// Define program
prog def splitit, rclass sortpreserve

	// Version statement 
	version 15
	
	// Syntax for the splitit subroutine
	syntax anything(name = props id = "Split proportion(s)") [if] [in] [, 	 ///   
		   Uid(varlist) TPoint(string asis) KFold(integer 1) 				 ///   
		   SPLit(string asis) loo ]
	
	// Test for invalid KFold option
	if `kfold' < 1 {
		
		// Display an error message
		di as err "There must always be at least 1 K-Fold.  This would be "	 ///   
		"the training set in a simple train/test split.  You specified "	 ///   
		"`kfold' K-Folds."
		
		// Return error code and exit
		err 198
		
	} // End IF Block for invalid K-Fold argument
		
	// Mark the sample to handle any if/in arguments (can now pass if `touse') 
	// for the downstream work to handle user specified if/in conditions.
	marksample touse
	
	// First we'll check/verify that appropriate arguments are passed to the 
	// parameters and handle as much defensive stuff up front as possible.
	// Tokenize the first argument
	gettoken train validate: props
	
	// Validate that the train value is numeric
	if !ustrregexm("`train'", "^[\d\.]+[\d]*\$") {
		
		// Display an error message
		di as err "Only numeric values can be passed for split proportions."

		// Throw an error code
		err 121
		
	} // End IF Block for invalid training split value
	
	// Check validation split value
	if !mi("`validate'") & !ustrregexm("`validate'", "^\s*[\d\.]+[\d]*\$") {
		
		// Display an error message
		di as err "Only numeric values can be passed for split proportions."

		// Throw an error code
		err 121
		
	} // End IF Block for invalid training split value
	
	// Set a macro for label use later to define the type of splitting
	if `: word count `props'' == 1 {
		
		// Define this as K-Fold if they want multiple cross-validation folds
		if `kfold' > 1 loc stype "K-Fold Train/Test Split"
		
		// Otherwise, plain train/test split
		else loc stype "Train/Test Split"
		
	} // End IF Block for train/test split types
	
	// If there are two thresholds it is tvt
	if `: word count `props'' == 2 {
		
		// Define the split type macro to include K-Fold if the user wants that
		if `kfold' > 1 loc stype "K-Fold Train/Validate/Test Split"
		
		// Set the split type macro to indicate train, validation, test split
		else loc stype "Train/Validate/Test Split"
		
		// Replace the validate macro with the sum of train and validate
		loc validate `= `train' + `validate''

	} // End IF Block for train, validation, test split	
	
	// Test if the user is requesting assigning all the data to the training set 
	// without using K-Fold cv (effectively not splitting the data at all)
	if `: word 1 of `props'' == 1 & `kfold' == 1 {
		
		// Display error message to the screen
		di as err "You cannot assign all of the data to a single training split."
		
		// Return error code and exit
		err 198
		
	} // End IF Block for invalid training proportion for non-K-Fold case
		
	// Define the flavor of the splits based on how the units are allocated
	if !mi(`"`uid'"') & !mi("`tpoint'") loc flavor "Clustered & Panel Sample"
	else if !mi(`"`uid'"') & mi("`tpoint'") loc flavor "Clustered Random Sample"
	else if mi(`"`uid'"') & !mi("`tpoint'") loc flavor "Panel Unit Sample"
	else if mi(`"`uid'"') & mi("`tpoint'") loc flavor "Simple Random Sample"
	
	// Allocate tempname for xt/group splitting
	tempvar tag sgrp sgrp2 uni
	
	// Determine if the values are not proportions
	if `train' > 1 {
		
		// If not a proportion issue an error message
		di as err "Splits must be specified as proportions of the sample."
		
		// Return error code 
		error 198
		
	} // End of IF Block for non-proportion splits
	
	// Now test for invalid combination of splits
	if !mi("`validate'") {
		
		// Test if the sum of the split proportions is greater than unity
		if `validate' > 1 {
			
			// Print error message
			di as err "Invalid validation/test split.  The proportion is > 1."
		
			// Return error code
			error 198
		
		} // End IF Block for invalid validation proportion
		
	} // End IF Block for proportions that sum to greater than unity

	// Require an argument for split if the user wants a validation and test 
	// split
	if !mi("`validate'") & mi(`"`split'"') {
		
		// Check to see if _xvsplit is already defined
		cap confirm v _xvsplit

		// If the variable exists
		if _rc == 0 {
			
			// If no varname is passed to split
			di as err "New varname required for validation/test splits if _xvsplit already exists."
			
			// Return error code
			error 100	
		
		} // End IF Block for existing split variable defined

	} // End IF Block for new varname requirement for tvt splits
	
	// If no variable name is passed to split use _xvsplit
	if mi("`split'") loc split _xvsplit
	
	// If tpoint is used expect that the data are xt/tsset
	if !mi(`"`tpoint'"') {
				
		// If not xt/ts set 
		if mi(`"`: char _dta[tis]'"') {
			
			// Display an error message
			di as err "Data required to be xt/tsset when using tpoint."
			
			// Return an error code
			error 459
			
		} // End IF Block for non-xt/tsset data with panel data arguments
		
		// Store the panel variable in ivar
		loc ivar `: char _dta[iis]'
		
		// Store the time variable in tvar
		loc tvar `: char _dta[tis]'
		
		// Test if the `uid' parameter has an argument and if so if it includes 
		// the panel variable, when there is a panel variable
		if !mi(`"`uid'"') & !`: list ivar in uid' & !mi(`"`ivar'"') {
			
			// Test to see if the panel variable is nested within the clusters
			mata: st_local("nested", strofreal(isnested("`uid' `ivar'", "`touse'")))
			
			// If the panel variable is not nested within the user defined 
			// clusters
			if `nested' == 0 {
				
				// Return an error message
				di as err "The panel variable must be nested within the" ///   
				" clustered identified in: `uid'."
				
				// Return an error code and exit
				error 459
				
			} // End IF Block for non-nested panel vars within clusters
			
			// If the panel variable is nested, add it to the cluster ID macro
			else loc uid `uid' `ivar'
							
		} // End IF Block for missing panel var in uid 
		
	} // End IF Block to check for the time point option
	
	/***************************************************************************
	* This is the section where we create a marker to identify how we will     *
	* split the records.  For hierarchical/panel data, we need to assign whole *
	* clusters of observations, while cross-sectional data can split the all   *
	* of the records.  The temporary variable `tag' is used to mark the obs in *
	* conjunction with any if/in expressions passed by the user.               *
	***************************************************************************/
	
	// Test for presence of sampling unit id if provided
	if !mi(`"`uid'"') {
		
		// Confirm the variable exists and let this handle returning the error 
		confirm v `uid'
		
		// Test if time point is also listed to determine how to tag records
		// If there is a time point, that should be included in the if condition
		if !mi("`tpoint'") qui: egen byte `tag' = tag(`uid') if `touse' 
		
		// This will handle hierarchical cases as well
		else qui: egen byte `tag' = tag(`uid') if `touse'
		
	} // End IF Block to verify variable in uid if specified
	
	// Handle the case where we use the xtset info for the xt case
	else if mi(`"`uid'"') & !mi("`tpoint'") {
		
		// If a panel ID variable is defined by xtset
		if !mi(`"`ivar'"') {
			
			// If the panel variable exists, flag an individual case per panel
			// unit
			qui: egen byte `tag' = tag(`ivar') if `touse' 
			
		} // End IF Block for panel data

		// If this is a timeseries instead of a panel data set:
		else {
			
			// Create the tag for the timeseries including all obs 
			qui: g byte `tag' = 1 if `touse' & `tvar' < `tpoint'

		} // End ELSE Block for time series
		
	} // End IF block for xtset based splits
	
	// Create the tag variable for non xt/hierarchical cases
	else {
		
		// Create the tag for cases that don't involve clustering or panels
		qui: g byte `tag' = 1 if `touse' 
		
	} // End ELSE Block for non-clustered/panel/timeseries sampling
	
	// Generate a random uniform in [0, 1] for the tagged observations
	qui: g double `uni' = runiform() if `touse' & `tag' == 1
	
	/***************************************************************************
	* This is the section where the splits get defined now that we've ID'd the *
	* way we will allocate the observations/clusters.                          *
	***************************************************************************/
	
	// For the kfold case, we'll use xtile on the random uniform to create the 
	// groups
	if `kfold' != 1 & mi("`loo'") {
		
		// Generate the split group tempvar to create `kfold' equal groups
		xtile `sgrp' = `uni' if `touse' & `tag' == 1 & `uni' <= `train',	 ///   
		n(`kfold')
			
		// Define the training splits
		mata: st_local("trainsplit", invtokens(strofreal(1..`kfold')))
				
		// Set number of levels for the splits
		deflabs, val(`trainsplit') t(Training)
		
		// If there is no validation split 
		if mi("`validate'") {
			
			// Define the test split
			loc testsplit `= `kfold' + 1'
			
			// Add the testsplit ID to the variable for the test cases
			qui: replace `sgrp' = `testsplit' if `touse' & `tag' == 1 & 	 ///   
												 `uni' > `train' & !mi(`uni')
			
			// Generate the value label for the test split
			deflabs, val(`testsplit') t(Test)
			
		} // End IF Block for KFold CV train/test split
		
		// If the user also wants to use kfold for a validation set as well:
		else {
			
			// Create a macro with the validation splits
			loc validsplit `= `kfold' + 1'
			
			// Set the value for the test set
			loc testsplit `= `validsplit' + 1'
			
			// Add the validation group to the existing variable
			qui: replace `sgrp' = `validsplit' if `touse' & `tag' == 1 &	 ///   
										(`uni' > `train' & `uni' <= `validate')

			// Create the test split in a similar fashion
			qui: replace `sgrp' = `testsplit' if `touse' & `tag' == 1 &		 ///   
												 (`uni' > `validate')
			
			// Generate value labels for the validation set
			deflabs, val(`validsplit') t(Validation)
			
			// Generate value labels for the test set
			deflabs, val(`testsplit') t(Test)
				
		} // End ELSE Block for kfold CV with validation and test splits
		
	} // End IF block to handle splitting the training set
	
	// For Leave-One-Out cross-validation splits
	else if `kfold' > 1 & !mi("`loo'") {
		
		// Sort the data so all of the tagged cases appear first and the random
		// uniform is sorted in ascending order
		qui: gsort -`tag' -`touse' +`uni'
		
		// Now the _n should correspond with the order of the random uniform
		// value and won't produce duplicates.  We'll use a long here just to 
		// be safe but will compress before returning from the command.
		qui: g long `sgrp' = _n if `touse' & `tag' == 1 & `uni' <= `train' & ///   
							_n <= `kfold'
		
		// Define the training splits
		mata: st_local("trainsplit", invtokens(strofreal(1..`kfold')))
				
		// Set number of levels for the splits
		deflabs, val(`trainsplit') t(Training)
		
		// If there is no validation split 
		if mi("`validate'") {
			
			// Define the test split
			loc testsplit `= `kfold' + 1'
			
			// Add the testsplit ID to the variable for the test cases
			qui: replace `sgrp' = `testsplit' if `touse' & `tag' == 1 & 	 ///   
												 mi(`sgrp') & !mi(`uni') //`uni' > `train' & 
			
			// Generate the value label for the test split
			deflabs, val(`testsplit') t(Test)
			
		} // End IF Block for KFold CV train/test split
		
		// If the user also wants to use kfold for a validation set as well:
		else {
			
			// Create a macro with the validation splits
			loc validsplit `= `kfold' + 1'
			
			// Set the value for the test set
			loc testsplit `= `validsplit' + 1'
			
			// Add the validation group to the existing variable
			qui: replace `sgrp' = `validsplit' if `touse' & `tag' == 1 &	 ///   
							mi(`sgrp') & (`uni' > `train' & `uni' <= `validate') 

			// Create the test split in a similar fashion
			qui: replace `sgrp' = `testsplit' if `touse' & `tag' == 1 &		 ///   
											   mi(`sgrp') & (`uni' > `validate') 
			
			// Generate value labels for the validation set
			deflabs, val(`validsplit') t(Validation)
			
			// Generate value labels for the test set
			deflabs, val(`testsplit') t(Test)
				
		} // End ELSE Block for kfold CV with validation and test splits
		
		// Compress the group identifier
		qui: compress `sgp'
		
	} // End ELSEIF block for the LOO-CV case
	
	// For the other cases we can generate the train and validation splits 
	// in a single step
	else {
		
		// For train, validate, test splits:
		if !mi("`validate'") {
			
			// Create the split indicator for the training, validation, and test set
			g byte `sgrp' = cond(`touse' & `tag' == 1 & `uni' <= `train', 1, ///   
							cond(`touse' & `tag' == 1 & `uni' > `train' & 	 ///   
								 `uni' <= `validate' & !mi(`uni'), 2, 		 ///   
							cond(`touse' & `tag' == 1 & `uni' > `validate' & ///   
								 !mi(`uni'), 3, .)))
			
			// Generate value labels for the training set ID					 
			deflabs, val(1) t(Training)
			
			// Generate value labels for the validation set ID
			deflabs, val(2) t(Validation)
			
			// Generate value labels for the test set ID
			deflabs, val(3) t(Test)
														
			// Stores the values of the split variable that identify the training split
			loc trainsplit 1
			
			// Stores the value of the split variable for the validation split
			loc validsplit 2
			
			// Stores the value of the split variable for the test split
			loc testsplit 3
		
		} // End IF Block for TVT Split
		
		// Otherwise:
		else {
			
			// Create the split indicator for training and test sets
			g byte `sgrp' = cond(`touse' & `tag' == 1 & `uni' <= `train', 1, ///  
							cond(`touse' & `tag' == 1 & `uni' > `train' & 	 ///   
								 !mi(`uni'), 2, .))

			// Generate value labels for the training set ID					 
			deflabs, val(1) t(Training)
			
			// Generate value labels for the test set ID
			deflabs, val(2) t(Test)
			
			// Stores the values of the split variable that identify the training split
			loc trainsplit 1
			
			// Stores the value of the split variable for the test split
			loc testsplit 2
			
		} // End ELSE Block for TT split

	} // End IF block for train/validation/test splits
	
	/***************************************************************************
	* This is the section where we will handle populating the split ID record  *
	* for cases involving hierarchical/custered sampling, panel/timeseries, &  *
	* combinations of the two cases, since we only assigned split IDs to a     *
	* single record per cluster/group above.                                   *
	***************************************************************************/
	
	// Handle populating the split ID for hierarchical cases/clustered splits
	if !mi("`uid'") {

		// This should fill in the split group ID assignment for the case of 
		// hierarchical splitting
		qui: bys `uid' (`sgrp'): replace `sgrp' = `sgrp'[_n - 1] if `touse'  ///   
										  & mi(`sgrp'[_n]) & !mi(`sgrp'[_n - 1]) 
							
		// For clustered sampling with panel/timeseries data
		if !mi("`tpoint'") { 
			
			// Create a new variable to identify the corresponding forecast sample
			qui: g byte `split'xv4 = `sgrp' if `touse' & `tvar' > `tpoint'
			
			// Label the variable
			la var `split'xv4 "Forecasting sample for the corresponding split"
		
			// Then unflag those records from the main sample
			replace `sgrp' = . if `touse' & `tvar' > `tpoint'

		} // End IF Block for timeseries/panel cases
										
	} // End IF Block to fill things in for hierarchical splits
		
	// Handle timeseries/panel case without additional hierarchy specified
	else if mi("`uid'") & !mi("`tpoint'") & !mi(`"`ivar'"') {
		
		// This should fill in the split group ID assignment for the case of 
		// hierarchical splitting
		qui: bys `ivar' (`sgrp'): replace `sgrp' = `sgrp'[_n - 1] if `touse' ///   
							& mi(`sgrp'[_n]) & !mi(`sgrp'[_n - 1]) 
							
		// Create the forecast identifier
		qui: g long `split'xv4 = `sgrp' if `touse' & `tvar' > `tpoint'
		
		// Compress the forecast identifier
		qui: compress `split'xv4
		
		// Label the variable
		la var `split'xv4 "Forecasting sample for the corresponding split"
		
		// And now replace the split variables with missings for the forecast 
		// sample
		qui: replace `sgrp' = . if `touse' & `tvar' > `tpoint'

	} // End ELSEIF Block for panel/timeseries data with a specified panel var
	
	// Create a variable label for the split IDs
	la var `sgrp' `"`stype' Identifiers"'
	
	// For the last step we'll move the values from the tempvar into the 
	// permanent variable (which could have happened earlier)
	clonevar `split' = `sgrp' if `touse'
	
	// Apply the value label to the split group variable
	la val `split' _splitvar
	
	// Set an r macro with the variable name with the split variable to make 
	// sure it can be cleaned up by the calling command later in the process
	ret loc splitter = "`split'"
	
	// Return the IDs that identifies the training splits
	ret loc training = "`trainsplit'"
	
	// Return the IDs that identifies the validation splits
	if !mi("`validsplit'") ret loc validation = `validsplit'
	
	// Return the ID that identifies the test split
	if !mi("`testsplit'") ret loc testing = `testsplit'
	
	// Return the type of split
	ret loc stype = `"`stype'"'
	
	// Return the flavor of the split
	ret loc flavor = `"`flavor'"'
	
	// If using for panel/timeseries return the forecast variable name
	if !mi("`tpoint'") ret loc forecastset = "`split'xv4"
	
// End of program definitions	
end

// Subroutine to define value labels for the split identifier
prog def deflabs

	// Declares the syntax for this subroutine
	syntax, VALues(numlist integer min = 1 > 0) Type(string asis) 
	
	// If there is only a single ID passed to the command generate this style of 
	// value label for that split type
	if `: word count `values'' == 1 la def _splitvar `values' "`type' Split", modify
	
	// If multiple ID values are passed loop over them and construct the split 
	// labels like this
	else {
		
		// Loop over the values in the numlist
		foreach i in `values' {
			
			// Generate a new value label with the split IDs
			la def _splitvar `i' "`type' Split #`i'", modify
			
		} // End Loop over the range
		
	} // End ELSE Block for multiple values
	
// End sub-sub-routine for other label types	
end

