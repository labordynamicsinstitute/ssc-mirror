*! 13mar2024
/*******************************************************************************
*                                                                              *
*                    Mata library for -crossvalidate- package                  *
*                                                                              *
*******************************************************************************/

**# Utilities
// Starts mata interpreter
mata:

// A function to retrieve an if/in expression from an estimation command.  The 
// value is returned in a Stata local macro named `ifin' and will be missing if 
// no if or in conditions were included in the command passed to the function.
string scalar getifin(string scalar x) {
	
	// Used to store the result from testing the match for the regular expression
	real scalar matched
	
	// Contains the if/in expression from the command that will be modified
	string scalar strexp
	
	// Tests if there is an if/in expression in the estimation command
	matched = ustrregexm(x, " i[fn]{1}\s+.*?(?=, *[a-zA-Z]|\$)")
	
	// If there is an expression in the estimation command
	if (matched) {
		
		// Stores the expression in strexp
		strexp = ustrregexs(0)
		
	// If there isn't a match	
	} else {
		
		// Stores an empty string
		strexp = ""
		
	} // End ELSE block from testing for presence of if/in expression
	
	// Stores the if/in expression in the local macro ifin
	st_local("ifin", strtrim(strexp))
	
	// Returns the matched string
	return(strexp)
	
} // End of Mata function definition to retrieve if/in expressions from command

// Defines a function to parse and return the command string up to the comma 
// that starts specification of options.  This is needed for cases where no if 
// or in statements are included in the estimation command to insert the 
// appropriate if statement to fit the model to the training data only.
string scalar getnoifin(string scalar x) {
	
	// Used to store the result from testing the match for the regular expression
	real scalar matched
	
	// Contains the if/in expression from the command that will be modified
	string scalar strexp
	
	// Tests the regular expression that will capture everything up to options
	matched = ustrregexm(x, "^(.*?)(?![^()]*\)),")
	
	// If there is a comma not enclosed in parentheses
	if (matched) {
		
		// Return the syntax up to the comma that starts the options
		strexp = ustrregexs(1)

	// If this doesn't result in a match
	} else {
		
		// We'll assume no options are specified and return the string 
		strexp = x
		
	} // End ELSE Block for cmd string w/o options
	
	// Returns the string upto
	st_local("noifin", strexp)
	
	// Returns the matched string
	return(strexp)
	
} // End of function definition to return the cmd string up to the options

// Defines a function to indicate whether or not the command string includes
// optional arguments
real scalar hasoptions(string scalar x) {
	
	return(ustrregexm(x, `"(?:(?!["\(]).)*?,\s*(?![^\(]*\))(.*)\$"'))
	
} // End of function definition to return an indicator for options in cmd

// Defines a function to parse the prefix command into it's constituent parts
void function cvparse(string scalar cv) {
	
	// Declares a transmorphic scalar for the tokenizer 
	transmorphic scalar t
	
	// Declares a string rowvector with valid option names
	string rowvector optnms
	
	// Declares a string matrix to store the parsed tokens
	string matrix opts
	
	// Declares the counter to identify token boundaries and the index for 
	// inserting of parsed tokens into the opts matrix, and an iterator used to 
	// loop over the rows of the matrix containing the parsed tokens
	real scalar cnt, optcnt, i
	
	// Declares a string scalar used to build the token and a string scalar that 
	// stores the token
	string scalar opt, token, fname
	
	// Initialize the tokenizer
	t = tokeninit("", ("(", " ", ")"), (""), 1)
	
	// Define the valid option names
	optnms = ("metric", "monitors", "uid", "tpoint", "retain", "kfold", 	 ///   
			 "state", "results", "grid", "params", "tuner", "seed", 		 ///   
			 "classes", "threshold", "pstub", "split", "display", "obs", 	 ///   
			 "modifin", "kfifin", "noall", "pmethod", "replay", "name", 	 ///   
			 "fitnm", "validnm", "popts")
	
	// Initialize a null matrix to store the valid results
	opts = J(26, 1, "")
	
	// Initialize the counter used to identify token boundaries based on 
	// parentheses
	cnt = 0
	
	// Initialize the row index scalar used to insert the parsed tokens into the 
	// matrix with the results
	optcnt = 1

	// Initialize the string scalar used to construct the parsed token from its 
	// constituent pieces
	opt = ""
	
	// Pass the string into the tokenizer
	tokenset(t, cv)
	
	// Loop over each of the tokens parsed by the tokenizer until the end
	while((token = tokenget(t)) != "") {
		
		// Check the next token to determine if it is an opening parenthesis
		// If so, increment the cnt variable to indicate that more tokens need 
		// to be combined in order to parse the option and its arguments and 
		// keep the value of cnt the same if it is not an opening parenthesis
		cnt = (tokenpeek(t) == "(" ? cnt + 1 : cnt)
		
		// Check the current token to determine if it is a closing parenthesis.
		// If it is decrement cnt and if not do not change cnt
		cnt = (token == ")" ? cnt - 1 : cnt) 
		
		// If the value of cnt is positive add this token to the opt variable
		if (cnt > 0) opt = opt + token
		
		// If the value is 0 
		else {
			
			// Insert the existing option string and it's closing parenthesis 
			// into the matrix with the options
			opts[optcnt, 1] = opt + token
			
			// Reset the opt variable so we can parse the next option
			opt = ""
			
			// If the nulled out string and the current token only contains a 
			// space increment the optcnt variable to insert the next opt into 
			// the next row of the matrix
			if (!ustrregexm(opt + token, "^\s\$")) optcnt = optcnt + 1
			
		} // End ELSE Block to insert parsed option into the matrix of results
		
	} // End of WHILE loop over the tokens parsed from cv	
	
	// Loop over the result matrix to verify valid options
	for(i = 1; i < optcnt; i++) {
		
		// Get the name of the option from the stored result
		getname(opts[i, 1])
		
		// Gets the full name of the function
		fname = fullnm(st_local("fnm"))
		
		// If the full name is contained in the rowvector above, return the 
		// parsed option to a local macro using the full name (even if it is an 
		// abbreviated option name)
		if (anyof(optnms, fname)) st_local(fname, opts[i, 1])
		
	} // End Loop to verify and return the valid options
	
} // End of function definition to parse prefix options for crossvalidate package

// Defines a function to retrieve the argument(s) passed to a parameter with an 
// option to specify the name of the returned macro
void function getarg(string scalar param, | string scalar rname) {
	
	// String scalar to store the argument(s)
	string scalar retval, retnm
	
	// Determines whether to use the default return name or a user supplied 
	// return name
	retnm = (rname == "" ? "argval" : rname)
	
	// Removes everything up to the opening parentheses with the regex, then 
	// removes the closing parenthesis with subinstr
	retval = ustrregexrf(param, "[a-zA-Z0-9_]+\(", "")
	
	// If the string ends with a closing parenthesis remove it to prevent 
	// unbalanced parentheses
	if (substr(retval, -1, 1) == ")") { 
		
		// Remove the trailing parenthesis
		retval = substr(retval, 1, strrpos(retval, ")") - 1)
		
	} // End IF Block to remove trailing parenthesis	
	
	// If the parameter doesn't include any parentheses return an empty string
	if (ustrregexm(param, "[\(\)]") == 0) st_local(retnm, "")
	
	// Returns the argument value in a local macro
	else st_local(retnm, retval)
	
} // End of function definition to get argument value from a parameter

// Defines a function to retrieve the metric name to support passing optional 
// arguments to metrics/monitors
void function getname(string scalar fname, | string scalar rname) {
	
	// Declares string scalar to store the return name
	string scalar retnm
	
	// Test if a return name was passed
	retnm = (rname == "" ? "fnm" : rname)

	// If a valid function name is used, this should return the function name
	if (ustrregexm(fname, "\s*([a-zA-Z0-9_]+).*")) st_local(retnm, ustrregexs(1))
	
	// Otherwise, return a blank string
	else st_local(retnm, "")
	
} // End of function definition to get function name for monitors/metrics

// Defines a struct object to store a richer representation of the data used for
// classification metrics
struct Crosstab {
	
	// The confusion matrix and reversed confusion matrix (for 2x2 cases only)
	real matrix conf, revconf
	
	// The row margins (sums of predicted categories) for the normal and 
	// reversed confusion matrix (for 2x2 cases only)
	real colvector rowm, revrowm
	
	// The diagonal from the confusion matrix (correctly classified cells)
	real colvector correct
	
	// The vector storing each of the values in the matrix in ascending order
	real colvector values
	
	// The column margins (sums of observed categories) for the normal and 
	// reversed confusion matrix (for 2x2 cases only)
	real rowvector colm, revcolm
	
	// The total number of observations
	real scalar n
	
	// The total number of true positive (correctly classified) cases
	real scalar tp
	
	// The number of categories in the confusion matrix
	real scalar levs
	
} // End of Struct definition returned by xtab

// Defines a function to compute cross tabulations and return the cross tab
// as a Mata matrix
struct Crosstab scalar xtab(string scalar pred, string scalar obs, 			 ///   
							string scalar touse) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Allocates column vectors to store the unique values; the predicted and 
	// observed values of the dependent variable; the indices for the relevant
	// rows in the dataset; and the row margins
	real colvector vals, yhat, y, idx, rowm
	
	// Allocates a row vector to store the column margins
	real rowvector colm
	
	// Defines the matrix that will store the confusion matrix
	real matrix conf
	
	// Defines scalars that store the number of unique levels of the variable of 
	// interest, and two iterators for the rows and columns of the matrix
	real scalar levs, i, j
	
	// Gets the predicted values of the variable of interest
	yhat = st_data(., pred, touse)
	
	// Gets the observed values of the variable of interest
	y = st_data(., obs, touse)
	
	// Gets the unique values across both sets of values ordered from lowest to 
	// highest values
	vals = uniqrows(yhat \ y)
	
	// Stores the unique values in the struct element values
	c.values = vals
	
	// Gets the number of unique values
	levs = rows(vals)	
	
	// Stores the number of unique values in the struct element levs
	c.levs = levs
	
	// Creates a square matrix with missing values 
	conf = J(levs, levs, .)
	
	// Creates column vector with missing values
	rowm = J(levs, 1, .)
	
	// Creates row vector with missing values
	colm = J(1, levs, .)
	
	// Loop over the values of the predicted variable
	for(i = 1; i <= levs; i++) {
		
		// Gets the indices from the predicted variable that have the first 
		// value from the set of all values
		idx = selectindex(yhat :== vals[i, 1])
		
		// Gets the total number of cases predicted to be in the ith class
		rowm[i, 1] = rows(idx)
		
		// Gets the total number of cases observed in the ith class
		colm[1, i] = rows(selectindex(y :== vals[i, 1]))
		
		// Loop over the values of the observed variable
		for(j = 1; j <= levs; j++) {
			
			// count the number of cases with the ith predicted value that have 
			// the jth observed value
			conf[i, j] = rows(selectindex(y[idx, 1] :== vals[j, 1]))
			
		} // End Loop over the observed variable values	
		
	} // End Loop over the rows of the confusion matrix
	
	// Stores the column margins in the struct element colm
	c.colm = colm
	
	// Stores the row margins in the struct element rowm
	c.rowm = rowm
	
	// Stores the confusion matrix in the struct element conf
	c.conf = conf
	
	// Test if this is a 2x2 matrix
	if (levs == 2) {
		
		// reverse codes the confusion matrix for binary metric options to use
		// (e.g., if the user specifies they want to use a different 
		// "event_level" in the R functions' terminology it will use this)
		c.revconf = (conf[2, 2], conf[2, 1] \ conf[1, 2], conf[1, 1])
		
		// Computes the column margins from the reverse coded confusion matrix
		c.revcolm = colsum(c.revconf)
		
		// Computes the row margins from the reverse coded confusion matrix
		c.revrowm = rowsum(c.revconf)
		
	} // End IF Block for binary case
	
	// For any multinomial/ordinal case with > 2 distinct levels
	else {
		
		// Return a null matrix for the reverse coded confusion matrix
		c.revconf = J(0, 0, .)
		
		// Return a null vector for the reverse coded column margins
		c.revcolm = J(1, 0, .)
		
		// Return a null vector for the reverse coded row margins
		c.revrowm = J(0, 1, .)
		
	} // End ELSE Block to populate struct elements with null matrices/vectors
	
	// Stores the total number of observations in the struct element n
	c.n = sum(conf)
	
	// Stores count of correctly predicted classes in the struct element correct 
	c.correct = diagonal(conf)
	
	// Stores the total correctly classified cases in the struct element tp
	c.tp = sum(diagonal(conf))
	
	// Returns the struct with all of this information precomputed
	return(c)
	
} // End definition of cross-tabulation function

// Defines a function to test the nesting of values in a dataset
real scalar isnested(string scalar varnms, string scalar touse) {
	
	// Declares a matrix to store the data that we need to check nesting on
	real matrix df
	
	// Declares a scalar for the number of columns in the matrix and to identify 
	// the column with the variable that is most deeply nested
	real scalar vars
	
	// Gets the unique combinations of the data that should be nested
	df = uniqrows(st_data(., varnms, touse))
	
	// Gets the number of columns in the matrix with the data
	vars = cols(df)
	
	// Returns a value of 1 if the data are nested and a value of 0 otherwise
	return(rows(df) == rows(uniqrows(df[., vars])) ? 1 : 0)
	
} // End definition of function to check the nesting of variables

// Defines a function to retrieve the distribution date from the file passed to 
// the function.
string scalar distdate(string scalar fname) {
	
	// Declares a scalar to store the file handle
	real scalar fh
	
	// Declares a scalar to store the contents of a single line of the file
	string scalar line
	
	// Opens a connection to the file passed as a parameter
	fh = fopen(fname, "r")
	
	// Loops over the lines of the file from start to end
	while ((line = fget(fh)) != J(0, 0, "")) {
		
		// Tests if this is the line that has the distro date
		if (ustrregexm(line, "^\*!\s([0-9]{1,2}[a-z]{3}[0-9]{4})")) {
			
			// Closes the connection to the file
			fclose(fh)

			// Returns the distrodate
			return(ustrregexs(1))
		
		} // End IF Block to find the star bang with the distrodate
		
	} // End of loop over the source code file
	
} // End of function definition to retrieve distribution date	

// Create a function to implement the Poisson density function
real colvector dpois(real colvector events, real colvector means, | 		 ///   
					 real scalar ln){
	
	// Declares a column vector to store the densities temporarily
	real colvector density
	
	// Compute the density 
	density = means :^ events :* exp(-means) :/ factorial(events)
	
	// Test if there is an argument passed to ln and it equals 1
	if (args() == 3 & ln == 1) return(log(density))
	
	// Otherwise return the density without transformation
	else return(density)

} // End definition for the Poisson density function

// Defines function to make weighting matrix for Kappa
real matrix kappawgts(real scalar levs, real scalar pow) {
	
	// Declares a real matrix that will be returned
	real matrix wgts
	
	// This is equivalent to:
	// w <- rlang::seq2(0L, n_levels - 1L)
	// w <- matrix(w, nrow = n_levels, ncol = n_levels)
	wgts = J(1, levs, (0::levs - 1))
	
	// This generates the weight matrix
	return(abs(wgts - wgts'):^pow)
	
} // End of function definition for MC Kappa weighting matrix

// Defines a function to convert abbreviated option names to their full names
string scalar fullnm(string scalar key) {
	
	// Declares an associative array
	class AssociativeArray scalar nm
	
	// Reinitialize the associative array
	nm.reinit("string", 1)
	
	// populate the associative array with the key value pairs
	nm.put("u", "uid")
	nm.put("tp", "tpoint")
	nm.put("kf", "kfold")
	nm.put("spl", "split")
	nm.put("res", "results")
	nm.put("noall", "noall")
	nm.put("dis", "display")
	nm.put("na", "name")
	nm.put("fit", "fitnm")
	nm.put("ps", "pstub")
	nm.put("c", "classes")
	nm.put("thr", "threshold")
	nm.put("mod", "modifin")
	nm.put("kfi", "kfifin")
	nm.put("pm", "pmethod")
	nm.put("po", "popts")
	nm.put("me", "metric")
	nm.put("o", "obs")
	nm.put("mo", "monitors")
	nm.put("val", "valnm")
	nm.put("ret", "retain")
	nm.put("state", "state")
	nm.put("g", "grid")
	nm.put("par", "params")
	nm.put("tun", "tuner")
	nm.put("seed", "seed")
	nm.put("rep", "replay")
	nm.put("loo", "loo")
	
	// Sets the not found default to be the value passed to the function
	nm.notfound(key)
	
	// Returns the value based on the key passed to this function
	return(nm.get(key))
	
} // End of function definition to expand available option names

// End Mata interpreter
end

**# Binary Metrics
/*******************************************************************************
*                                                                              *
*                        Binary Classification Metrics                         *
*                                                                              *
*******************************************************************************/

// Start mata
mata: 

// Can define each of the common metrics/monitors for binary prediction, based 
// on passing the arguments for the confusion matrix.  There will be additional 
// computational overhead this way, but we could also consider coding around 
// this so we would return the confusion matrix to a Mata object and then do the 
// subsequent computations on the single confusion matrix.

// For sensitivity, specificity, prevalence, ppv, and npv see:
// https://yardstick.tidymodels.org/reference/ppv.html	
// For others in this section see other pages from above			
real scalar sens(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Creates the confusion matrix
	c = xtab(pred, obs, touse)
	
	// For now, at least, we'll restrict these metrics to only the binary case
	// so this assertion will make sure that we have a binary confusion matrix
	// assert(rows(c.conf) == 2 & cols(c.conf) == 2)
	
	// Computes the metric from the confusion matrix
	result = (args() == 4 & opts == 1 ?										 ///   
			  c.revconf[2, 2] / colsum(c.revconf[, 2]) :					 ///   
			  c.conf[2, 2] / colsum(c.conf[, 2]))
	
	// Returns the metric as a scalar
	return(result)
	
} // End of function definition for sensitivity
					
// Function to compute precision from a confusion matrix.  See:
// https://yardstick.tidymodels.org/reference/precision.html for the formula
real scalar prec(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Creates the confusion matrix
	c = xtab(pred, obs, touse)
	
	// For now, at least, we'll restrict these metrics to only the binary case
	// so this assertion will make sure that we have a binary confusion matrix
	// assert(rows(c.conf) == 2 & cols(c.conf) == 2)
	
	// Computes the metric from the confusion matrix
	result = (args() == 4 & opts == 1 ?										 ///   
			  c.revconf[2, 2] / c.revrowm[2, ] :	c.conf[2, 2] / c.rowm[2, ])
			  
	// Returns the metric
	return(result)
	
} // End of function definition for precision

// Function to compute recall, which appears to be a synonym for sensitivity.  
// See https://yardstick.tidymodels.org/reference/precision.html for formula					  
real scalar recall(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {
		
	// Declares a scalar to store the result
	real scalar result
	
	// Recall is a synonym for sensitivity, so it just calls that function
	result = sens(pred, obs, touse, opts)
	
	// Returns the metric
	return(result)
	
} // End of function definition for recall
				
// Defines function to compute specificity from a confusion matrix.  
// See: https://yardstick.tidymodels.org/reference/ppv.html for the formula
real scalar spec(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Creates the confusion matrix
	c = xtab(pred, obs, touse)
	
	// For now, at least, we'll restrict these metrics to only the binary case
	// so this assertion will make sure that we have a binary confusion matrix
	// assert(rows(c.conf) == 2 & cols(c.conf) == 2)
	
	// Computes the metric from the confusion matrix
	result = (args() == 4 & opts == 1 ?										 ///   
			  c.revconf[1, 1] / c.revcolm[, 1] : c.conf[1, 1] / c.colm[, 1])
	
	// Returns the metric
	return(result)
	
} // End of function definition for specificity

// Defines a function to compute prevalence.  
// See: https://yardstick.tidymodels.org/reference/ppv.html for the formula
real scalar prev(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Creates the confusion matrix
	c = xtab(pred, obs, touse)
	
	// For now, at least, we'll restrict these metrics to only the binary case
	// so this assertion will make sure that we have a binary confusion matrix
	// assert(rows(c.conf) == 2 & cols(c.conf) == 2)
	
	// Computes the metric from the confusion matrix
	result = (args() == 4 & opts == 1 ?										 ///   
			  c.revcolm[, 2] / c.n : c.colm[, 2] / c.n)

	// Returns the metric
	return(result)
	
} // End of function definition for prevalence

// Defines a function to compute positive predictive value.
// See: https://yardstick.tidymodels.org/reference/ppv.html for the formula
real scalar ppv(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Declares a scalar to store the resulting metric, sensitivity, 
	// specificity, and prevalence (used to compute the metric)
	real scalar result, sens, spec, prev
	
	// Computes sensitivity 
	sens = sens(pred, obs, touse, opts)
	
	// Computes prevalence
	prev = prev(pred, obs, touse, opts)
	
	// Computes specificity
	spec = spec(pred, obs, touse, opts)
	
	// Computes positive predictive value
	result = (sens * prev) / ((sens * prev) + ((1 - spec) * (1 - prev)))
	
	// Returns the metric
	return(result)
	
} // End of function definition for positive predictive value

// Defines a function to compute negative predictive value.
// See: https://yardstick.tidymodels.org/reference/ppv.html for the formula
real scalar npv(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Declares a scalar to store the resulting metric, sensitivity, 
	// specificity, and prevalence (used to compute the metric)
	real scalar result, sens, spec, prev
	
	// Computes sensitivity 
	sens = sens(pred, obs, touse, opts)
	
	// Computes prevalence
	prev = prev(pred, obs, touse, opts)
	
	// Computes specificity
	spec = spec(pred, obs, touse, opts)
	
	// Computes negative predictive value
	result = (spec * (1 - prev)) / (((1 - sens) * prev) + (spec * (1 - prev)))
	
	// Returns the metric
	return(result)
	
} // End of function definition for negative predictive value

// Defines a function to compute accuracy.
real scalar acc(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares a scalar to store the resulting metric
	// real scalar result
	
	// Creates the confusion matrix
	c = xtab(pred, obs, touse)
	
	// Computes the metric from the confusion matrix
	// result = c.tp / c.n

	// Returns the metric
	return(c.tp / c.n)
	
} // End of function definition for accuracy

// Defines a function to compute "balanced" accuracy.  
// See https://yardstick.tidymodels.org/reference/bal_accuracy.html for more info
real scalar bacc(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Declares a scalar to store the resulting metric, sensitivity, 
	// specificity, and prevalence (used to compute the metric)
	real scalar result, sens, spec
	
	// Computes sensitivity 
	sens = sens(pred, obs, touse, opts)
	
	// Computes specificity
	spec = spec(pred, obs, touse, opts)
	
	// Computes "balanced" accuracy as the average of sensitivity and specificity
	result = (sens + spec) / 2
	
	// Returns the metric
	return(result)
	
} // End of function definition for balanced accuracy

// Defines function to compute the F1 statistic
// Based on second equation here: https://www.v7labs.com/blog/f1-score-guide
//# Bookmark #1
real scalar f1(string scalar pred, string scalar obs, string scalar touse,   ///   
					| transmorphic matrix opts) {
	
	// Declares a scalar to store the resulting metric, precision, and recall
	real scalar result, prec, rec, beta
	
	// Determine what value of beta to use
	beta = (args() == 4 & eltype(opts) == "real" & cols(opts) == 2 ? opts[1, 2] : 1)

	// Computes precision
	prec = (args() == 4 & eltype(opts) == "real" ?							 ///   
			prec(pred, obs, touse, opts[1, 1]) : prec(pred, obs, touse))

	// Computes recall
	rec = (args() == 4 & eltype(opts) == "real" ?							 ///   
			recall(pred, obs, touse, opts[1, 1]) : recall(pred, obs, touse))
	
	// Computes the f1 score 
	result = ((1 + beta^2) * prec * rec) / ((beta^2 * prec) + rec)
	
	// Returns the metric
	return(result)
	
} // End of function definition for f1score

// Defines J-index (Youden's J statistic)
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-j_index.R
real scalar jindex(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {

	// Return the micro averaged detection prevalence
	return(sens(pred, obs, touse, opts) + spec(pred, obs, touse, opts) - 1)

} // End of function definition for j-index

// Defines a binary R^2 (tetrachoric correlation)
real scalar binr2(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Declares a scalar to store the result
	real scalar result
					
	// Call the tetrachoric command in Stata
	stata("cap: qui: tetrachoric " + pred + " " + obs + " if " + touse + ", ed")

	// Stores the result in a variable
	result = st_numscalar("r(rho)")
	
	// If the result is missing, return a missing value
	if (hasmissing(result)) return(J(1, 1, .))
	
	// otherwise return the correlation coefficient
	else return(result)

} // End of function definition for binary R^2 

// Defines Matthews correlation coefficient
// based on: https://en.wikipedia.org/wiki/Phi_coefficient#Multiclass_case
real scalar mcc(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
		
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// To store the row margins
	real colvector rowm
	
	// To store the column margins
	real rowvector colm
	
	// Scalars used in the computation
	real scalar i, num, den1, den2
	
	// Stores confusion matrix
	c = xtab(pred, obs, touse)
	
	// If the confusion matrix isn't square return a missing value.
	if (rows(c.conf) != cols(c.conf)) return(.)
	
	// Stores the row margins
	rowm = c.rowm
	
	// Stores the column margins
	colm = c.colm
	
	// Stores the first term for the numerator (correct classified * n)
	num = c.tp * c.n
		
	// Initializes the denominator terms
	den1 = c.n^2
	den2 = den1
	
	// Loop over the dimension for the margins
	for(i = 1; i <= rows(rowm); i++) {
		
		// Starts subtracting the true * predicted cell sizes
		num = num - colm[1, i] * rowm[i, 1]
		
		// Subtracts the squared number of predicted cases for each value 
		// from the squared sample size
		den1 = den1 - rowm[i, 1]^2
		
		// Subtracts the squared number of observed cases for each value from 
		// the squared sample size
		den2 = den2 - colm[1, i]^2
		
	} // End Loop over the margins
	
	// Return the correlation coefficient
	return(num / (sqrt(den1) * sqrt(den2)))
	
} // End of function definition for Matthew's correlation coefficent

// End mata
end

**# Multinomial Metrics
/*******************************************************************************
*                                                                              *
*                     Multinomial Classification Metrics                       *
*                                                                              *
*******************************************************************************/

// Start mata
mata:

// Defines multiclass specificity
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-spec.R
real scalar mcspec(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares column vectors to store the total sample size in a J(x, 1, n) 
	// sized column vector, , true positive counts,
	// true positive + false positive counts, true positive + false negative 
	// counts, true negative counts, false positives, and the numerator and 
	// denominator for the metric
	real colvector n, tp, tpfp, tpfn, tn, fp, num, den
	
	// Get the confusion matrix
	c = xtab(pred, obs, touse)
	
	// Store the total sample size in a column vector with the sample size in 
	// each element
	n = J(rows(c.conf), 1, c.n)
	
	// Get the vector of true positives
	tp = c.correct
	
	// Get the true positive + false positive counts
	tpfp = c.rowm
	
	// Get the true positive + false negative counts and transpose the result
	tpfn = c.colm'
	
	// Get the count of true negatives
	tn = n - (tpfp + tpfn - tp)
	
	// Get the count of false positives
	fp = tpfp - tp
	
	// Return the micro average specificity
	return(sum(tn) / sum((tn + fp)))

} // End of function definition for multiclass specificity

// Defines multiclass sensitivity
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-sens.R
real scalar mcsens(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Get the confusion matrix
	c = xtab(pred, obs, touse)

	// Return the micro averaged sensitivity
	return(c.tp / sum(c.colm))

} // End of function definition for multiclass sensitivity

// Defines multiclass recall
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-recall.R
real scalar mcrecall(string scalar pred, string scalar obs, 				 ///   
					 string scalar touse, | transmorphic matrix opts) {
	
	// Return the micro averaged recall
	return(mcsens(pred, obs, touse))

} // End of function definition for multiclass recall

// Defines multiclass precision
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-precision.R
real scalar mcprec(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Get the confusion matrix
	c = xtab(pred, obs, touse)

	// Return the micro averaged precision
	return(c.tp / sum(c.rowm))

} // End of function definition for multiclass precision

// Defines multiclass positive predictive value
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-ppv.R
real scalar mcppv(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Return the micro averaged PPV
	// Lines 176-178 indicate that multiclass PPV should be equal to precision 
	// in all cases EXCEPT when the prevalence paramter in that function is 
	// passed an argument.  With our method signature, there isn't a way to 
	// pass that parameter.
	return(mcprec(pred, obs, touse))

} // End of function definition for multiclass positive predictive value

// Defines multiclass negative predictive value
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-npv.R
real scalar mcnpv(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Declares column vectors to store the total sample size in a J(x, 1, n) 
	// sized column vector and true positive + false negative counts
	real colvector n, tpfn

	// Declares scalars to store intermediate results
	real scalar prev, sens, spec, num, den
	
	// Get the confusion matrix
	c = xtab(pred, obs, touse)
	
	// Store the total sample size in a column vector with the sample size in 
	// each element
	n = J(c.levs, 1, c.n)
	
	// Get the true positive + false negative counts and transpose the result
	tpfn = c.colm'
	
	// Compute prevalence
	prev = sum(tpfn) / sum(n)
	
	// Compute multiclass sensitivity
	sens = mcsens(pred, obs, touse)
	
	// Compute multiclass specificity
	spec = mcspec(pred, obs, touse)
	
	// Define the numerator for the metric
	num = spec * (1 - prev)

	// Define the denominator for the metric
	den = (1 - sens) * prev + spec * (1 - prev)
	
	// Return the micro averaged NPV
	return(num / den)

} // End of function definition for multiclass negative predictive value

// Defines multiclass F1 statistic
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-f_meas.R
real scalar mcf1(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Declares scalars to store intermediate results
	real scalar prec, sens, beta
	
	// Determine whether to use the default value for beta
	beta = (args() == 4 & eltype(opts) == "real" ? opts[1, 1] : 1)
	
	// Compute precision
	prec = mcprec(pred, obs, touse)
	
	// Compute multiclass sensitivity
	sens = mcsens(pred, obs, touse)
	
	// For the default case return the micro averaged F1 Statistic
	return(((1 + beta^2 ) * prec * sens) / ((beta^2 * prec) + sens))

} // End of function definition for multiclass negative predictive value

// Defines multiclass Detection Prevalence
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-detection_prevalence.R
real scalar mcdetect(string scalar pred, string scalar obs, 				 ///   
					 string scalar touse, | transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c
	
	// Compute the confusion matrix
	c = xtab(pred, obs, touse)
	
	// Return the micro averaged detection prevalence
	return(sum(c.rowm) / sum(J(c.levs, 1, c.n)))

} // End of function definition for multiclass detection prevalence

// Defines multiclass J-index (Youden's J statistic)
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-j_index.R
real scalar mcjindex(string scalar pred, string scalar obs, 				 ///   
					 string scalar touse, | transmorphic matrix opts) {

	// Return the micro averaged detection prevalence
	return(mcsens(pred, obs, touse) + mcspec(pred, obs, touse) - 1)

} // End of function definition for multiclass j-index

// Defines multiclass accuracy
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-accuracy.R
real scalar mcacc(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Return the accuracy
	return(acc(pred, obs, touse))
	
} // End of multiclass accuracy synonym

// Defines multiclass Balanced Accuracy
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-bal_accuracy.R
real scalar mcbacc(string scalar pred, string scalar obs, 					 ///   
				   string scalar touse, | transmorphic matrix opts) {
	
	// Declares scalars to store the intermediate results
	real scalar rec, sens
		
	// Compute the recall
	rec = mcrecall(pred, obs, touse)
	
	// Compute the sensitivity
	sens = mcsens(pred, obs, touse)
	
	// Return the balanced accuracy
	return((rec + sens) / 2)
	
} // End of function definition for multiclass balanced accuracy

// Defines multiclass Kappa
// similar to accuracy, but normalized by accuracy expected by random chance
// based on: https://github.com/tidymodels/yardstick/blob/main/R/class-kap.R
real scalar mckappa(string scalar pred, string scalar obs, 					 ///   
					string scalar touse, | transmorphic matrix opts) {
	
	// Creates the struct that gets returned
	struct Crosstab scalar c

	// Declares matrix to store random chance outcome
	real matrix wgts, conf, expected
	
	// Declares scalars to store the intermediate results
	real scalar i
	
	// Get the confusion matrix
	c = xtab(pred, obs, touse)
	
	// Normalizes the outer product of row margins * col margins
	expected = (c.rowm * c.colm) :/ c.n
	
	// Test whether or not the user is specifying a weighting option
	if (args() == 4 & eltype(opts) == "real") {
		
		// Generate the weighting matrix based on the power specified in the 
		// optional argument
		wgts = kappawgts(c.levs, opts[1, 1])
		
	} // End IF Block for user specified weighting option

	// If the user doesn't specify anything use the default weighting matrix
	else {
		
		// Generates the weighting matrix for the no-weighting case
		wgts = J(c.levs, c.levs, 1)
		
		// Will need to replace the diagonal with 0s for wgts
		for(i = 1; i <= rows(wgts); i++) wgts[i, i] = 0
				
	} // End ELSE Block for default weight matrix
	
	// Return the metric 
	return(1 - sum(wgts * c.conf) / sum(wgts * expected))
	
} // End of function definition for multiclass Kappa 

// Defines multiclass Mathews correlation coefficient
// based on: https://github.com/tidymodels/yardstick/blob/main/src/mcc-multiclass.c
real scalar mcmcc(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Call the other implementation
	return(mcc(pred, obs, touse))
	
} // End of function definition for multiclass MCC

// Defines a multiclass R^2 (polychoric correlation)
real scalar mcordr2(string scalar pred, string scalar obs, 					 ///   
					string scalar touse, | transmorphic matrix opts) {

	// Call the tetrachoric command in Stata
	stata("cap: qui: polychoric " + pred + " " + obs + " if " + touse)

	// Returns the correlation coefficient
	return(st_numscalar("r(rho)"))

} // End of function definition for ordinal R^2

// End mata
end

**# Continuous Metrics
/*******************************************************************************
*                                                                              *
*                          Continuous Metrics/Utilities                        *
*                                                                              *
*******************************************************************************/

// Start mata
mata:

// Defines function to compute mean squared error from predicted and observed 
// outcomes
real scalar mse(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Column vector to store the squared difference of pred - obs
	real colvector sqdiff
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Computes squared differences
	sqdiff = (st_data(., obs, touse) - st_data(., pred, touse)) :^2
	
	// Computes the average of the squared differences
	result = sum(sqdiff) / rows(sqdiff)
	
	// Returns the mean squared error
	return(result)

} // End of function definition for MSE

// Defines function to compute mean absolute error from predicted and observed 
// outcomes
real scalar mae(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Column vector to store the absolute difference of pred - obs
	real colvector absdiff
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Computes absolute differences
	absdiff = abs(st_data(., obs, touse) - st_data(., pred, touse))
	
	// Computes the average of the squared differences
	result = sum(absdiff) / rows(absdiff)
	
	// Returns the mean absolute error
	return(result)

} // End of function definition for MAE

// Metric based on definition here:
// https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/
real scalar bias(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Returns the sum of residuals
	return(sum(st_data(., obs, touse) - st_data(., pred, touse)))
	
} // End of function definition for bias

// Metric based on definition here:
// https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/
real scalar mbe(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Returns the sum of residuals
	return(sum(st_data(., obs, touse) - st_data(., pred, touse)) /			 ///   
		   rows(st_data(., obs, touse)))
	 
} // End of function definition for mean bias error

// Metric based on definition here:
// https://github.com/tidymodels/yardstick/blob/main/R/num-rsq.R
real scalar r2(string scalar pred, string scalar obs, string scalar touse,   ///   
					| transmorphic matrix opts) {
	
	// Returns the correlation between the predicted and observed variable
	return(corr(variance((st_data(., pred, touse), ///   
						  st_data(., obs, touse))))[2, 1])
	
} // End of function definition for R^2

// Creates function for root mean squared error
real scalar rmse(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Returns the square root of the mean squared error
	return(sqrt(mse(pred, obs, touse)))

} // End of function definition for RMSE

// Metric based on definition of mean absolute percentage error here:
// https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/
real scalar mape(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Allocates a column vector to store the differences
	real colvector diff
	
	// Computes the residuals
	diff = st_data(., obs, touse) - st_data(., pred, touse)
	
	// Returns the sum of the absolute value of the residual divided by observed 
	// value, which is then divided by the number of observations
	return(sum(abs(diff :/ st_data(., obs, touse))) / rows(st_data(., obs, touse)))
	
} // End of function definition for mean absolute percentage error


// Metric based on definition of symmetric mean absolute percentage error here:
// https://github.com/tidymodels/yardstick/blob/main/R/num-smape.R
real scalar smape(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Allocates a column vector to store the differences
	real colvector num, denom
	
	// Creates a column vector with the observed outcome data
	num = abs(st_data(., obs, touse) - st_data(., pred, touse))
	
	// Computes the residuals
	denom = (abs(st_data(., obs, touse)) + abs(st_data(., pred, touse))) :/ 2
	
	// Returns the sum of the absolute value of the residual divided by the 
	// average of the sum of absolute observed and predicted values, divided by 
	// the number of observations
	return(sum(num :/ denom) / rows(denom))
	
} // End of function definition for mean absolute percentage error

// Defines function to compute mean squared log error from predicted and observed 
// outcomes.  Based on definition here:
// https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/
real scalar msle(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Column vector to store the squared difference of pred - obs
	real colvector sqdiff
	
	// Declares a scalar to store the resulting metric
	real scalar result
	
	// Computes squared differences
	sqdiff = (log(st_data(., obs, touse) :+ 1) - log(st_data(., pred, touse)  :+ 1)) :^2
	
	// Computes the average of the squared differences
	result = sum(sqdiff) / rows(sqdiff)
	
	// Returns the mean squared error
	return(result)

} // End of function definition for mean squared log error

// Defines function to compute the root mean squared log error.  Based on 
// definition here:
// https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/
real scalar rmsle(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Returns the square root of the mean squared log error
	return(sqrt(msle(pred, obs, touse)))
	
} // End of function definition for root mean squared log error

// Defines function for the ratio of performance to deviation
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-rpd.R
real scalar rpd(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Returns the ratio of the SD of predicted to the RMSE
	return(sqrt(variance(st_data(., pred, touse))) / rmse(pred, obs, touse))

} // End of function definition for RPD

// Defines function for the Index of ideality of correlation
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-iic.R
real scalar iic(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Declares some columnvectors
	real colvector neg, pos, delta
	
	// Declares scalars needed
	real scalar muneg, mupos, adj

	// Gets the difference in observed vs predict values
	delta = st_data(., obs, touse) - st_data(., pred, touse)
	
	// Selects only the differences that are negative
	neg = select(delta, delta :< 0)
	
	// Selects only the differences that are positive
	pos = select(delta, delta :>= 0)
	
	// Computes the absolute mean of the negative values
	muneg = sum(abs(neg)) / rows(neg)
	
	// Computes the absolute mean of the positive values
	mupos = sum(abs(pos)) / rows(pos)
	
	// Computes the adjustment factor for the correlation
	adj = min((muneg, mupos)) / max((muneg, mupos))
	
	// Returns the adjusted correlation
	return(r2(pred, obs, touse) * adj)

} // End of function definition for IIC

// Defines function for the Concordance Correlation Coefficient
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-ccc.R
real scalar ccc(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Declares scalars needed
	real scalar mupred, muobs, varpred, varobs, cov, n
	
	// Get the number of rows of the data
	n = rows(st_data(., obs, touse))

	// estimate_mean in R function
	mupred = mean(st_data(., pred, touse))

	// truth_mean in R function
	muobs = mean(st_data(., obs, touse)) 

	// estimate_variance in R function
	varpred = variance(st_data(., pred, touse))[1, 1] 

	// truth_variance in R function
	varobs = variance(st_data(., obs, touse))[1, 1] 

	// Gets the covariance between the predicted and observed values
	cov = variance((st_data(., pred, touse), st_data(., obs, touse)))[2, 1] 

	// Check for option to use the bias term
	if (args() == 4 & opts == 1) {
		
		// Adjust the values using the bias term
		return((2 * (cov * (n - 1) / n)) /									 ///   
		((varobs * (n - 1) / n) + (varpred * (n - 1) / n) + (muobs - mupred)^2))
		
	} // End ELSE Block for the use of the bias term
	
	// Computes and returns the coefficient w/o the bias term
	else return((2 * cov) / (varobs + varpred + (muobs - mupred)^2))
	
} // End of function definition for CCC

// Defines function for Pseudo-Huber Loss
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-pseudo_huber_loss.R
real scalar phl(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Declares a column vector to store the errors
	real colvector a
	
	// Declares a real scalar for delta
	real scalar delta
	
	// Test the number of arguments passed
	delta = (args() == 4 & eltype(opts) == "real" ? opts[1, 1] : 1)
	
	// Gets the difference between the observed and predicted values
	a = st_data(., obs, touse) - st_data(., pred, touse)

	// Computes and returns the loss function value
	return(mean(delta^2 :* (sqrt(1 :+ (a :/ delta) :^2) :- 1)))
	
} // End of function definition for Pseud-Huber Loss

// Defines function for Huber Loss
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-huber_loss.R
real scalar huber(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Declares a column vector to store the errors and absolute errors
	real colvector a, absa 
	
	// Declares a scalar for delta that would be passed in opts
	real scalar delta
	
	// Assign delta
	delta = (args() == 4 & eltype(opts) == "real" ? opts[1, 1] : 1)
	
	// Gets the difference between the observed and predicted values
	a = st_data(., obs, touse) - st_data(., pred, touse)
	
	// Gets the absolute difference of the observed and predicted values
	absa = abs(a)
	 
	// Computes and returns the loss function value
	return(mean(0.5 :* a[selectindex(absa :<= delta)]:^ 2 \						 ///   
				delta :* absa[selectindex(absa :> delta)] :- 0.5 * delta))
	
} // End of function definition for the Huber Loss function

// Defines function for Poisson Log Loss
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-poisson_log_loss.R
real scalar pll(string scalar pred, string scalar obs, string scalar touse,  ///   
					| transmorphic matrix opts) {
	
	// Returns the mean of the negative log poisson density
	return(mean(-dpois(st_data(., obs, touse), st_data(., pred, touse), 1)))
	
} // End of function definition for Poisson Log Loss

// Defines function for ratio of performance to interquartile range
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-rpiq.R
real scalar rpiq(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {

	// Declares scalar to store the iqr
	real scalar iqr
	
	// quietly calls the summarize command on the observed values
	stata("qui: su " + obs + " if " + touse + " == 1, de")
	
	// Get the interquartile range
	iqr = st_numscalar("r(p75)") - st_numscalar("r(p25)")

	// Returns the ratio of performance to interquartile range
	return(iqr / rmse(pred, obs, touse))
	
} // End of function definition for Poisson Log Loss

// Defines function for "Traditional" R^2
// based on: https://github.com/tidymodels/yardstick/blob/main/R/num-rsq_trad.R
real scalar r2ss(string scalar pred, string scalar obs, string scalar touse, ///   
					| transmorphic matrix opts) {
	
	// Declares a scalar to store the mean of the observed values
	real scalar mu
	
	// Mean of the observed values
	mu = mean(st_data(., obs, touse))

	// Returns 1 - (Residual SS / Total SS)
	return(1 - (sum((st_data(., obs, touse) - st_data(., pred, touse)):^2) / ///   
				sum((st_data(., obs, touse) :- mu):^2)))

} // End of function definition for "Traditional" R^2



// End mata interpreter
end

