/*******************************************************************************
*                                                                              *
*        Leave-One-Out Cross-Validation for Stata Estimation Commands          *
*                                                                              *
*******************************************************************************/

*! xvloo
*! v 0.0.15
*! 28mar2024

// Drop program from memory if already loaded
cap prog drop xvloo

// Defines the program; properties lists the applicable options for this prefix 
// The tpoint option is only valid for panel/time-series cross-validation
prog def xvloo, eclass properties(prefix xv) sortpreserve

	// Stata version statement, can check for backwards compatibility later
	version 15
	
	// Set the prefix name for Stata to recognize it
	set prefix xvloo
	
	// Check to see if mata library is compiled
	cap: findfile libxv.mlib
	
	// call libxv in case mata library requires recompilation
	if _rc != 0 {
		
		// Look for the sourcecode file
		cap: findfile crossvalidate.mata
		
		// Look for the mata function used by libxv
		cap: mata: mata which distdate()
		
		// If that function is already defined in Mata, call libxv to compile 
		// everything
		if _rc == 0 qui: libxv
		
		// Otherwise run the mata file
		else run `"`r(fn)'"'
		
	} // End IF Block for unfound mata library
	
	// Check to see if the data are survey set
	if !mi(`"`: char _dta[_svy_version]'"') {
		
		// Add a warning message
		di as res "WARNING: {help xvloo} does not account for survey "		 ///
		"sample designs when splitting the data and does not use the "		 ///   
		"{help svy:subpop} option when fitting the model."
		
	} // End IF Block to display survey data warning
	
	// Allocate a tempvars for the unique identifier variable and for other 
	// options to use a default
	tempvar uuid xvtouse xvpred xvsplit
	
	// Tokenize the input string
	gettoken cv cmd : 0, parse(":") bind 
	
	// Remove leading colon from the estimation command
	loc cmd `= substr(`"`cmd'"', 2, .)'
	
	// Check for if/in conditions
	mata: getifin(`"`cmd'"')
	
	// If there is an if/in expression 
	if ustrregexm(`"`ifin'"', "\s?in\s+") {
		
		// Create an indicator that can be used to generate an if expression in 
		// the estimation command instead
		qui: g byte `xvtouse' = 1 `ifin'
		
		// Replaces the cmd macro with an updated version that uses an if 
		// expression instead of an in expression
		mata: st_local("cmd", subinstr(`"`cmd'"', `"`ifin'"', " if `xvtouse' == 1"))		
		
	} // End IF Block for in expression handling
	
	// Get any if expressions
	mata: getifin(`"`cmd'"')
	
	// Parse the prefix on the comma.  `props' will contain split proportions
	gettoken props xvopts : cv, parse(",") bind
	
	// Remove the leading comma from the options for xv.
	loc xvopts `"`= substr(`"`xvopts'"', 2, .)'"'

	// Then parse the options from the remainder of the macro
	mata: cvparse(`"`xvopts'"')
	
	// Test to see if replay option is invoked
	if !mi("`replay'") {
		
		// If there are macros around that would tell us what to replay and 
		// the user is using a later version of Stata
		if !mi(`"`e(fitnm)'`e(valnm)'"') & `c(stata_version)' >= 17 {

			// Test whether or not there are values in the fit macro
			if !mi(`"`e(fitnm)'"') collect preview, name(`e(fitnm)')
			
			// Otherwise try to estimates replay them
			else if !mi(`"`e(estresnames)'"') estimates replay `e(estresnames)'
			
			// Test if there is a value in the validation macro
			if !mi(`"`e(valnm)'"') collect preview, name(`e(valnm)')
			
			// Otherwise try to display the xv matrix
			else {
				
				// Test if there is a matrix to list
				cap: qui: mat li e(xv)
				
				// If the matrix is there display it
				if _rc == 0 mat li e(xv)
				
			} // End ELSE block for missing validation name for collection
			
			// Exit the program
			exit
			
		} // End IF Block for replay contents
		
		// For older Stata
		else if !mi(`"`e(estresnames)'"') & `c(stata_version)' < 17 {
			
			// Display the estimation results
			estimates replay `e(estresnames)'
			
			// Test if there is a matrix to list
			cap: qui: mat li e(xv)
			
			// If the matrix is there display it
			if _rc == 0 mat li e(xv)
			
		} // End ELSEIF Block for older Stata
		
		// If there aren't results we can find:
		else {
			
			// Display an error message
			di as err "Unable to find necessary returned values.  We're "	 ///   
			"confused about what we should replay if we don't find them.  "  ///   
			"Try refitting the models using {help xv} again."
			
			// Throw an error message
			err 119
			
		} // End ELSE Block for no detected collection names

	} // End IF Block to replay results and exit
	
	// Get any argument passed to fitnm
	mata: getarg("`fitnm'", "fitnm")
	
	// Get any argument passed to valnm
	mata: getarg("`valnm'", "valnm")
	
	// Assign default collection name if the user doesn't pass one for fitit
	if mi(`"`fitnm'"') loc fitnm xvfit
	
	// Assign default collection name if the user doesn't pass one for validateit
	if mi(`"`valnm'"') loc valnm xvval
	
	// Get the value of classes
	mata: getarg("`classes'")
	
	// If missing or the default downstream set the value to 1
	if (mi("`argval'") | "`argval'" == "0") loc c 1
	
	// Otherwise set it to the number of classes being predicted
	else loc c `argval'
	
	// Get the number of folds
	mata: getarg("`kfold'", "k")
	
	// Determine if this is TT or TVT
	if `: word count `props'' == 1 {
		
		// Test if the proportion is unity set the noall option on
		if `props' == 1 loc noall noall
		
		// Count the number of observations that would be used for the model
		qui: count `ifin'
		
		// Store the number of observations
		loc N `r(N)'
		
		// Test the number of variables that need to be created vs allowed
		if (`props' * `N' + `c' + `c(k)' + 2) >= `c(max_k_theory)' {
			
			// Display error message
			di as err "Currently, your Stata supports `c(max_k_theory)' "	 ///   
			"variables, but `= `props' * `c(N)' + `c(k)' + 2' variables "	 ///   
			"are needed for LOO cross-validation.  Reduce your training "	 ///   
			"set proportion or increase the maximum number of variables "	 ///   
			"(see {help memory}) in order to use LOO cross-validation."
			
			// Return error code and exit
			err 1002
			
		} // End IF Block for insufficient max variable
		
		// Test for number of estimation results that would need to be stored
		if ceil(`props' * `N') >= 298 {
			
			// Display an error message
			di as err "The maximum number of estimation results that can "	 ///   
			"be stored is 300 but the minimum number of results generated "	 ///   
			"by your use of {help xvloo} is `= ceil(`props' * `c(N)')'.  "   ///   
			"You can try using a smaller training set split.  See "			 ///   
			"{help limits} for additional information on system limits."
			
			// Return error code and exit
			err 1000
			
		} // End IF block for too many potential estimation results 
		
	} // End IF Block for TT split case
	
	// For TVT cases
	else {
		
		// Get the proportion for the training set
		loc trp `: word 1 of `props''
		
		// Test if the proportion is unity set the noall option on
		if `trp' == 1 loc noall noall
			
		// Count the number of observations that would be used for the model
		qui: count `ifin'
		
		// Store the number of observations
		loc N `r(N)'
		
		// Test the number of variables that need to be created vs allowed
		if (`trp' * `N' * `c' + `c(k)' + 2) >= `c(max_k_theory)' {
			
			// Display error message
			di as err "Currently, your Stata supports `c(max_k_theory)' "	 ///   
			"variables, but `= `trp' * `c(N)' + `c(k)' + 2' variables "		 ///   
			"are needed for LOO cross-validation.  Reduce your training "	 ///   
			"set proportion or increase the maximum number of variables "	 ///   
			"(see {help memory}) in order to use LOO cross-validation."
			
			// Return error code and exit
			err 1002
			
		} // End IF Block for insufficient max variable
				
		// Test for number of estimation results that would need to be stored
		if ceil(`trp' * `N') >= 298 {
			
			// Display an error message
			di as err "The maximum number of estimation results that can "	 ///   
			"be stored is 300 but the minimum number of results generated "	 ///   
			"by your use of {help xvloo} is `= ceil(`props' * `c(N)')'.  "   ///   
			"You can try using a smaller training set split.  See "			 ///   
			"{help limits} for additional information on system limits."
			
			// Return error code and exit
			err 1000
			
		} // End IF block for too many potential estimation results 
		
	} // End ELSE Block for TVT split case
	
	// If there is anything in the missing local throw an error message
	if mi(`"`metric'"') {
		
		// Display the error message
		di as err `"You must supply a valid argument to the metric option "' ///   
		`"to use the {help xvloo} prefix."'
		
		// Throw an error code to exit
		err 198
		
	} // End IF Block for missing required parameters
	
	// Check for uid variable.  If none, create a unique ID as _n in a tempvar
	// and pass that as uid to splitit
	if mi(`"`uid'"') {
		
		// Generate the unique identifier if the user is not using clusters for 
		// the LOO CV
		qui: g long `uuid' = _n
		
		// Set the uid local to use this variable
		loc uid "uid(`uuid')"
		
		// Set a macro for the correct flavor
		loc flav "Simple Random Sample"
		
	} // End IF Block for missing 
	
	// Test if the user passed a K-fold option
	if !mi("`kfold'") {
		
		// Display an error message
		di as err "The kfold() option is invalid with Leave-One-Out cross-"	 ///   
		"validation.  The {opt:noall} option may still be used with Leave-"	 ///   
		"One-Out cross-validation."
		
		// Throw an error message
		err 184
		
	} // End IF Block for invalid kfold argument
	
	// Otherwise
	else {
		
		// Allocate a tempname for the scalar
		tempname xvn
		
		// Parses the argument(s) passed to the uid option (or set above)
		mata: getarg("`uid'")
		
		// Gets the number of clusters/records in the dataset
		mata: st_numscalar("`xvn'",											 ///   
		rows(uniqrows(st_data(., "(" + subinstr("`argval'", " ", ", ") + ")"))))
		
		// Gets the number of records that will need to be sampled for the 
		// clusters or individual records referenced by `uid'
		loc k = int(`: word 1 of `props'' * `xvn')
		
		// Populates the kfold macro with the number of clusters to split the 
		// sample into
		loc kfold kfold(`k')
		
	} // End ELSE Block for xvloo set kfold value
	
	// If the user passes a split or pstub argument 
	if !mi(`"`split'`pstub'`results'"') {
		
		// set the retain option on automatically
		loc retain retain
		
	} // End IF Block for non-missing split or pstub
	
	// Test if results is missing a value
	if mi(`"`results'"') {
		
		// Set a default to use for the results
		loc results "results(xvres)"
		
		// Set a macro to automatically clean this up at the end
		if mi("`retain'") loc dropresults "estimates drop xvres*"
		
	} // End IF Block to set default results values
	
	// If missing the split option
	if mi(`"`split'"') {
		
		// Set the default split variable name
		loc spvar _xvsplit
		
		// Check for default name
		cap confirm new v `spvar'
	
		// If the variable already exists
		if _rc != 0 {
			
			// Set do split to 0 to prevent splitting again
			loc dosplit 0
			
			// Reassign the split macro to use the existing default splitvar
			loc split "split(`spvar')"
			
		} // End of IF Block when default split variable already exists
		
		// If it doesn't exist 
		else {
			
			// Set do split to 1 to force splitting the data
			loc dosplit 1

			// And use the tempvar to assign the splits
			loc split "split(`xvsplit')"
			
		} // End ELSE Block for non-existent default split variable
		
	} // End IF Block for the split variable name
		
	// If not missing the split option
	else {
		
		// Parses the split option
		mata: getarg("`split'")
		
		// Assigns the argument value to spvar
		loc spvar `argval'
		
		// Now set the split variable to use the tempvar
		loc split "split(`xvsplit')"
		
		// Check to see if the split variable already exists
		cap confirm new v `spvar'
		
		// If the variable already exists set the do split local to 0
		if _rc != 0 loc dosplit 0
				
		// If it doesn't exist set do split to 1
		else loc dosplit 1
				
	} // End ELSE Block for present split option

	// Check for a non-missing pstub argument
	if !mi(`"`pstub'"') {
		
		// Parses the pstub option
		mata: getarg("`pstub'")
		
		// Store the pstubn
		loc prvar `argval'
		
		// Check to see if predict stub variable is present
		cap confirm new v `argval'all
		
		// If the variable exists
		if _rc != 0 {
			
			// Display an error message
			di as err "The variable `argval'all already exists.  You " 		 ///
			"can drop the variable, or specify a new predict value stubname." 
			
			// Throw an error and exit
			err 110
			
		} // End IF Block for existing `pstub'all variable
			
		// Check to see if the predicted variable is present
		cap confirm new v `argval'
		
		// If the variable exists
		if _rc != 0 {
			
			// Display an error message
			di as err "The variable `argval' already exists.  You can drop " ///
			"the variable, or specify a new predict value stubname." 
			
			// Throw an error and exit
			err 110
			
		} // End IF Block for existing `pstub'all variable		
		
	} // End IF Block for non-missing pstub argument
	
	// If pstub is missing 
	else {
		
		// If the retain option is triggered
		if !mi(`"`retain'"') {
			
			// Confirm whether or not xvpred already exists
			cap confirm new v _xvpred _xvpredall
			
			// If these variables don't already exist 
			if _rc == 0 {
				
				// Use xvpred as the default name
				loc prvar _xvpred
				
			} // End IF Block for default predicted value variable name
			
			// Otherwise
			else {
				
				// Get the current date/time stamp
				loc cdt `= tc(`"`c(current_date)' `c(current_time)'"')' 
				
				// Add the current date time as a suffix to make the default 
				// predicted variable name unique
				loc prvar _xvpred`: di substr(strofreal(`cdt', "%15.0g"), 1, 12)'
				
			} // End ELSE Block when the default predicted variable name is used
			
		} // End IF Block for non-missing retain
		
	} // End ELSE Block for missing pstub
	
	// Set the predict stub to use the tempvar
	loc pstub "pstub(`xvpred')"
	
	// If the seed option is populated set the seed value to the seed that the 
	// user specified
	if !mi(`"`seed'"') {
		
		// Parse the seed option
		mata: getarg("`seed'")
		
		// Set the seed to the user specified value
		set seed `argval'
		
	} // End IF Block to set the pseudo-random number generator seed.
	
	// Gets any estimates that already exist
	qui: estimates dir
	
	// Stores the existing estimate names in a global for predictit
	glo xvstartest `r(names)'
	
	// Check to see if the user passed the state option
	if !mi(`"`state'"') {
		
		// Call the state command
		`state'
		
		// Capture all of the returned values in locals
		loc rng `r(rng)'
		loc rngcurrent `r(rngcurrent)'
		loc rngstate `r(rngstate)'
		loc rngseed `r(rngseed)'
		loc rngstream `r(rngstream)'
		loc filename `r(filename)'
		loc filedate `r(filedate)'
		loc version `r(version)'
		loc currentdate `r(currentdate)'
		loc currenttime `r(currenttime)'
		loc stflavor `r(stflavor)'
		loc processors `r(processors)'
		loc hostname `r(hostname)'
		loc machinetype `r(machinetype)'
		
	} // End IF Block to call the state command

	// If the split variable doesn't exist
	if `dosplit' {
		
		// Split the dataset into train/test or train/validation/test splits
		splitit `props' `ifin', `uid' `tpoint' `kfold' `split' loo
	
		// Capture the returned values so they can be returned at the end
		loc splitter `r(splitter)'
		loc training `r(training)'
		loc validation `r(validation)'
		loc testing `r(testing)'
		loc stype `r(stype)'
		loc flavor `r(flavor)'
		loc forecastset `r(forecastset)'

	} // End IF Block to create split variable
		
	// Call the command to fit the model to the data
	fitit `"`cmd'"', `split' `results' `kfold' `noall' `display' na(`fitnm')
	
	// Capture the macros that get returned
	loc estresnames `e(estresnames)'
	loc estresall `e(estresall)'
	
	// Predict the outcomes using the model fits
	predictit, `pstub' `split' `classes' `kfold' `threshold' `noall' 		 ///   
			   `pmethod' `popts'
	
	// Compute the validation metrics for the LOO sample
	validateit, `metric' `pstub' `split' `monitors' `display' `kfold' 		 ///   
				loo na(`valnm') `noall'
	
	// Loops over the names of the scalars created by validate it
	foreach i in `r(allnames)' {
		
		// Returns all of the scalars in e()
		eret sca `i' = r(`i')
		
	} // End Loop over the returned scalars
	
	// Need to assign returned matrix to a new matrix
	mat xv = r(xv)
	
	// If the user doesn't want to retain the results
	if mi(`"`retain'"') {
	
		// Drop the stored estimation results
		`dropresults'
		
		// Drop the variables created by xvloo
		drop `dropvars'
		
		// Clears all of the characteristics that may have been set 
		char _dta[rng]
		char _dta[rngcurrent]
		char _dta[rngstate]
		char _dta[rngseed]
		char _dta[rngstream]
		char _dta[filename]
		char _dta[filedate]
		char _dta[version]
		char _dta[currentdate]
		char _dta[currenttime]
		char _dta[stflavor]
		char _dta[processors]
		char _dta[hostname]
		char _dta[machinetype]
		char _dta[predifin]
		char _dta[kfpredifin]
		char _dta[modcmd]
		char _dta[kfmodcmd]
			
	} // End IF Block remove results generated by the program

	// If the user wants to retain the results
	else {
		
		// Reassign the temp splitvar to the user requested or default only when 
		// we are already splitting the data.
		if `dosplit' qui: clonevar `spvar' = `xvsplit'
		
		// Reassign the temp pstub to the user requested name
		qui: clonevar `prvar' = `xvpred'
		
		// If the all option is missing
		if mi(`"`noall'"') qui: clonevar `prvar'all = `xvpred'all
		
		// Return all of the macros from the state command if invoked
		eret loc rng = "`rng'"
		eret loc rngcurrent = "`rngcurrent'"
		eret loc rngstate = "`rngstate'"
		eret loc rngseed = "`rngseed'"
		eret loc rngstream = "`rngstream'"
		eret loc filename = "`filename'"
		eret loc filedate = "`filedate'"
		eret loc version = "`version'"
		eret loc currentdate = "`currentdate'"
		eret loc currenttime = "`currenttime'"
		eret loc stflavor = "`stflavor'"
		eret loc processors = "`processors'"
		eret loc hostname = "`hostname'"
		eret loc machinetype = "`machinetype'"

		// Return the macros from splitit
		if `dosplit' eret loc splitter = "`spvar'"
		else eret loc splitter = "`splitter'"
		eret loc training = "`training'"
		eret loc validation = "`validation'"
		eret loc testing = "`testing'"
		eret loc stype = "Leave One Out"
		if mi("`flav'") eret loc flavor = "`flavor'"
		else eret loc flavor = "`flav'"
		eret loc forecastset = "`forecastset'"

		// Then return the macros from fitit
		eret loc estresnames = "`estres'"
		eret loc estresall = "`estresall'"
		eret loc fitnm = "`fitnm'"
		
		// Return macros related to validation
		eret loc valnm = "`valnm'"
	
	} // End ELSE Block to return a few extra macros related to stored results
	
	// Remember to repost results
	ereturn repost 
	
	// Returns the matrix containing all of the validation/test metrics and 
	// monitors
	eret mat xv = xv
	
	// Check to see if the data are survey set
	if !mi(`"`: char _dta[_svy_version]'"') {
		
		// Add a warning message
		di as res "WARNING: {help xvloo} does not account for survey "		 ///
		"sample designs when splitting the data and does not use the "		 ///   
		"{help svy:subpop} option when fitting the model."
		
	} // End IF Block to display survey data warning

// End definition of ttsplit prefix command	
end 

	