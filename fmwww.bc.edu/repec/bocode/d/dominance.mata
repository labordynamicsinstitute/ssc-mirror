*! dominance.mata version 0.0.1  1/27/2023 Joseph N. Luchman

version 12.1

**# Container object for domin specs
mata:

mata set matastrict on

struct domin_specs {
	
	string scalar mi, reg, dv, all, weight, exp, touse, regopts
	
}

end

**# Mata function to compute all combinations of predictors or predictor sets run all subsets regression, and compute all dominance criteria
mata: 

mata set matastrict on

void dominance(struct domin_specs scalar model_specs, pointer scalar model_call, /// 
	string scalar cdlcompu, string scalar cptcompu, string scalar iv_string, ///
	real scalar all_subsets_fitstat, real scalar constant_model_fitstat)
{
	/*# object declarations*/
	real matrix IV_antiindicator_matrix, conditional_dominance, ///
		weighted_order_fitstats, weighted_order1less_fitstats, ///
		weight_matrix, complete_dominance, select2IVfits, ///
		IV_indicator_matrix, sorted_two_IVs, compare_two_IVs

	string matrix IV_name_matrix

	real rowvector fitstat_vector, orders, combin_at_order, ///
		combin_at_order_1less, general_dominance, standardized, ///
		focal_row_numbers, nonfocal_row_numbers, cpt_desig, ///
		indicator_weight, antiindicator_weight

	real colvector binary_pattern, cdl3, cpt_setup_vec, select2IVs

	string colvector IVs
	
	real scalar number_of_IVs, number_of_regressions, display, fitstat, ///
		var1, var2, x, y

	string scalar IVs_in_model
	
	transmorphic cpt_permute_container, t, wchars, pchars, qchars
	
	/*parse the predictor inputs*/
	t = tokeninit(wchars = (" "), pchars = (" "), qchars = ("<>")) //set up parsing rules
	
	tokenset(t, iv_string) //register the "iv_string" string scalar for parsing/tokenizing
	
	IVs = tokengetall(t)' //obtain all IV sets and IVs as a vector

	/*remove characters binding sets together (i.e., "<>")*/
	for (x = 1; x <= rows(IVs); x++) {
	
		if (substr(IVs[x], 1, 1) == "<") { //if any entry begins with "<" (will be the case for any/all sets)...
		
			IVs[x] = substr(IVs[x], 1, strlen(IVs[x]) - 1) //first character removed ("<")
			
			IVs[x] = substr(IVs[x], 2, strlen(IVs[x])) //last character removed (">")
			
		}
		
	}
	
	/*set-up and compute all combinations of predictors and predictor sets*/
	number_of_IVs = rows(IVs) //compute total number of IV sets and IVs
	
	number_of_regressions = 2^number_of_IVs - 1 //compute total number of regressions
	
	printf("\n{txt}Total of {res}%f {txt}sub-models\n", number_of_regressions)
	
	if (number_of_IVs > 12) printf("\n{txt}Computing all independent variable combination sub-models\n")

	IV_indicator_matrix = J(number_of_IVs, 2^number_of_IVs, .)	//indicating the IV by it's sequence in the rows (each row is an IV) and presence in a model by the columns (each column is a model); all models and the IVs in those models will be represented in this matrix; the matrix starts off empty/as all missings
	
	for (x = 1; x <= rows(IV_indicator_matrix); x++) {	//fills in the IV indicators matrix - for each row...
	
		binary_pattern = J(1, 2^(x-1), 0), J(1, 2^(x-1), 1)	//...make a binary matrix that grows exponentially; (0,1), then (0,0,1,1), then (0,0,0,0,1,1,1,1) growing in size until it fills the entire set of columns with sequences of 0's and 1's...
		
		IV_indicator_matrix[x, .] = J(1, 2^(number_of_IVs-x), binary_pattern)	//...spread the binary pattern across all rows forcing it to repeat when not long enough to fill all columns - net effect is staggering all binary patters across rows to obtain all subsets in the final matrix
		
	}

	IV_indicator_matrix = IV_indicator_matrix[., 2..cols(IV_indicator_matrix)]	//omit the first column that indicates a model with no IVs

	IV_indicator_matrix = (colsum(IV_indicator_matrix) \ IV_indicator_matrix)'	//transpose the indicator matrix and create a column indicating the "order"/number of IVs in the model - used to sort all the models

	IV_indicator_matrix = sort(IV_indicator_matrix, (1..cols(IV_indicator_matrix)))	//sort beginning with the order of the model indicator column followed by all other columns's binary values - net effect results in same sort order as cvpermute() as desired/originally designed in domin 3.0
	
	orders = (IV_indicator_matrix[.,1]')[rows(IV_indicator_matrix)..1] //keep the orders of each model - sort order is reversed below which is also implemented here
	
	IV_indicator_matrix = IV_indicator_matrix[., 2..cols(IV_indicator_matrix)]'	//omit orders from IV indicators matrix and transpose back to the models as rows
	
	//IV_indicator_matrix = sort(((cols(IV_indicator_matrix)::1), IV_indicator_matrix'), 1)[., 2..rows(IV_indicator_matrix)+1]'	//reverse sort order, functions below expect reversed order
	IV_indicator_matrix = IV_indicator_matrix[., cols(IV_indicator_matrix)..1] // reverse the IV indicator matrix's order; functions below expect a reversed order as originally designed in domin 3.0
	
	IV_name_matrix = IV_indicator_matrix:*IVs	//apply string variable names to all subsets indicator matrix 
	
 /*all subsets regressions and progress bar syntax if predictors or sets of predictors is above 5*/
	display = 1 //for the display of dots during estimation - keeps track of where the regressions are - every 5% of models complete another "." is added
	
	if (number_of_IVs > 4) {
	
		printf("\n{txt}Progress in running all sub-models\n{res}0%%{txt}{hline 6}{res}50%%{txt}{hline 6}{res}100%%\n")
		
		printf(".")
		
		displayflush()
		
	}

	fitstat_vector = J(1, cols(IV_indicator_matrix), .) //pre-allocate container vector that will contain fitstats across all models
	
	for (x = 1; x <= number_of_regressions; x++) { //loop to obtain all possible regression subsets
	
		if (number_of_IVs > 4) {
	
			if (floor(x/number_of_regressions*20) > display) {
			
				printf(".")
				
				displayflush()
				
				display++	
				
			}
			
		}
	
		IVs_in_model = invtokens(IV_name_matrix[., x]') //collect a distinct subset of IVs, then collpase names into single string separated by spaces
		
		fitstat = (*model_call)(IVs_in_model, all_subsets_fitstat, ///
			constant_model_fitstat, model_specs)  //implement called model - will differ for domin vs. domme
	
		fitstat_vector[1, x] = fitstat //add fitstat to vector of fitstats

	}

	/*define the incremental prediction matrices and combination rules*/
	IV_antiindicator_matrix = (IV_indicator_matrix:-1) //matrix flagging which IVs are not included in each model and setting them up for a subtractive effect
	
	combin_at_order = J(1, number_of_regressions, 1):*comb(number_of_IVs, orders) //vector indicating the number of model combinations at each "order"/# of predictors for each models - this is used as a "weight" to construct general dominance statistics
	
	combin_at_order_1less = J(1, number_of_regressions, 1):*comb(number_of_IVs - 1, orders) //vector indicating the number of model combinations from the previous "order" - this is also used as a "weight" to construct general dominance statistics
	
	combin_at_order_1less[1] = 0 //replace missing first value in vector with 0
	
	combin_at_order = combin_at_order - combin_at_order_1less //remove # of combinations for the "order" less the value at "order" - 1; this gives the number of relevant combinations at each order that include the focal IV and thus produce the right weight for averaging
	
	indicator_weight = IV_indicator_matrix:*combin_at_order //"spread" the vector indicating number of combinations at the current order involving the relevant IV to all models including that IV - to be used as a weight for summing the fitstat values in raw form (not increments)

	antiindicator_weight = IV_antiindicator_matrix:*combin_at_order_1less //"spread" the vector indicating number of combinations at the previous order not involving the relevant IV to all models not including the relevant IV - these components assist to subtract out values to make the values "increments"

	/*define the full design matrix - compute general dominance (average conditional dominance across orders)*/
	weight_matrix = ((indicator_weight + antiindicator_weight):*number_of_IVs):^-1 //combine weight matrices (which reflect the conditional dominance weights/within order averages) with the number of ivs (between order averages) and invert cell-wise - now can be multiplied by fit stat vector and summed to obtain general dominance statistics

	general_dominance = colsum((weight_matrix:*fitstat_vector)') //general dominance weights created by computing product of weights and fitstats and summing for each IV row-wise; in implementing the rows are transposed and column summed so it forms a row vector as will be needed to make it an "e(b)" vector

	fitstat = rowsum(general_dominance) + all_subsets_fitstat + constant_model_fitstat //total fitstat is then sum of gen. dom. wgts replacing the constant-only model and the "all" subsets stat

	st_matrix("r(domwgts)", general_dominance) //return the general dom. wgts as r-class matrix

	standardized = general_dominance:*fitstat^-1 //generate the standardized gen. dom. wgts
	
	st_matrix("r(sdomwgts)", standardized) //return the stdzd general dom. wgts as r-class matrix	
	
	st_matrix("r(ranks)", mm_ranks(general_dominance'*-1, 1, 1)') //return the ranks of the general dom. wgts as r-class matrix

	st_numscalar("r(fs)", fitstat) //return overall fit statistic in r-class scalar
	
	/*compute conditional dominance*/
	if (strlen(cdlcompu) == 0) {
	
		if (number_of_IVs > 5) printf("\n\n{txt}Computing conditional dominance\n")
	
		conditional_dominance = J(number_of_IVs, number_of_IVs, 0) //pre-allocate contrainer matrix to hold conditional dominance stats
		
		weighted_order_fitstats = ((IV_indicator_matrix:*combin_at_order):^-1):*fitstat_vector // create matrix fit stats weighted by within-order counts - to be summed to create the conditional dominance statistics; these fit stats are "raw"/not incrments without the antiindicators
		
		weighted_order1less_fitstats = ((IV_antiindicator_matrix:*combin_at_order_1less):^-1):*fitstat_vector // create matrix fit stats weighted by within-order counts at the previous order - these are negative and also to be summed to create the conditional dominance statistics; they ensure that the values are increments
		
		/*loop over orders/number of predictors to obtain average incremental prediction within order*/
		for (x = 1; x <= number_of_IVs; x++) { //proceed order by order
		
			conditional_dominance[., x] = rowsum(select(weighted_order_fitstats, orders:==x)):+rowsum(select(weighted_order1less_fitstats, orders:==x-1)) //sum the weighted fit statistics at the focal order and the weighted (negative) fit statistics from the previous order
		
		}
		
		st_matrix("r(cdldom)", conditional_dominance) //return r-class matrix "cdldom"
	
	}
	
	/*compute complete dominance*/
	if (strlen(cptcompu) == 0) {
	
		if (number_of_IVs > 5) printf("\n{txt}Computing complete dominance\n")

		complete_dominance = J(number_of_IVs, number_of_IVs, 0) //pre-allocate matrix for complete dominance
		
		cpt_setup_vec = (J(2, 1, 1) \ J(number_of_IVs - 2, 1, 0)) //set-up a vector the length of the number of IVs with two "1"s and the rest "0"s; used to compare each 2 IVs via 'cvpermute()'
	
		cpt_permute_container = cvpermutesetup(cpt_setup_vec) //create a 'cvpermute' container to extract all permutations of two IVs
		
		for (x = 1; x <= comb(number_of_IVs, 2); x++) {  
		
			select2IVs = cvpermute(cpt_permute_container) //invoke 'cvpermute' on the container - selects a unique combination of two IVs
		
			select2IVfits = colsum(select(IV_indicator_matrix, select2IVs)):==1 //filter IV indicator matrix to include just those fit statistic columns that inlude focal IVs - then only keep the columns that have one (never both or neither) of the IVs 
		
			focal_row_numbers = (1..rows(IV_indicator_matrix)) //sequence of numbers for selecting specific rows indicating focal IVs
			
			nonfocal_row_numbers = select(focal_row_numbers, (!select2IVs)') //select row numbers for all non-focal IVs; needed for sorting (below)
			
			focal_row_numbers = select(focal_row_numbers, select2IVs') //select row numbers for all focal IVs; also needed for sorting
			
			sorted_two_IVs = ///
				sort((select((IV_indicator_matrix \ fitstat_vector), select2IVfits))', /// //combine the indicators for IVs and fit statistic matrix - selecting only those columns corresponding with fit statistics where the focal two IVs are located, then...
					(nonfocal_row_numbers, focal_row_numbers)) // ...sort this matrix on the nonfocal IVs first then the focal IVs.  This ensures that sequential rows are comparable ~ all odd numbered rows can be compared with its subsequent even numbered row
			
			compare_two_IVs = ///
				(select(sorted_two_IVs[,cols(sorted_two_IVs)], mod(1::rows(sorted_two_IVs), 2)), /// //select the odd rows for comparison (see constuction of 'sorted_two_IVs')
				select(sorted_two_IVs[,cols(sorted_two_IVs)], mod((1::rows(sorted_two_IVs)):+1, 2))) //select the even rows for comparison 
			
			cpt_desig = ///
				(all(compare_two_IVs[,1]:>compare_two_IVs[,2]), /// //are all fit statistics in odd/first variable larger than the even/second variable?
				all(compare_two_IVs[,1]:<compare_two_IVs[,2])) //are all fit statistics in even variable larger than the odd variable?
			
			if (cpt_desig[2] == 1) complete_dominance[focal_row_numbers[1], focal_row_numbers[2]] = 1 	//if the even/second variables' results are all larger, record "1"...
				else if (cpt_desig[1] == 1) complete_dominance[focal_row_numbers[1], focal_row_numbers[2]] = -1 //else if the odd/first variables' results are all larger, record "-1"...
					else complete_dominance[focal_row_numbers[1], focal_row_numbers[2]] = 0 //otherwise record "0"...
	
		}
		
		complete_dominance = complete_dominance + complete_dominance'*-1 //make cptdom matrix symmetric
	
		st_matrix("r(cptdom)", complete_dominance) //return r-class matrix "cptdom"
	
	}
	
}

end

**# Mata function to execute 'domin-flavored' models
version 12.1

mata:

	mata set matastrict on

	real scalar domin_call(string scalar IVs_in_model,  
		real scalar all_subsets_fitstat, real scalar constant_model_fitstat, ///
		struct domin_specs scalar model_specs) 
	{ 

		real scalar fitstat

		if (strlen(model_specs.mi) == 0) { //if not multiple imputation, then regular regression

			stata(model_specs.reg + " " + model_specs.dv + " " + ///
				model_specs.all + " " + IVs_in_model + " [" + ///
				model_specs.weight + model_specs.exp + "] if " + 
				model_specs.touse + ", " + model_specs.regopts, 1) //conduct regression

			fitstat = st_numscalar(st_local("fitstat")) - all_subsets_fitstat - constant_model_fitstat //record fitstat omitting constant and all subsets values; note that the fitstat to be pulled from Stata is stored as the Stata local "fitstat"

		}

		else { //otherwise, regression with "mi estimate:"

			stata("mi estimate, saving(\`mifile', replace) \`miopt': " + ///
				model_specs.reg + " " + model_specs.dv + " " + ///
				model_specs.all + " " + IVs_in_model + " [" + ///
				model_specs.weight + model_specs.exp + "] if " + 
				model_specs.touse + ", " + model_specs.regopts, 1) //conduct regression with "mi estimate:"

			stata("mi_dom, name(\`mifile') fitstat(\`fitstat') list(\`=e(m_est_mi)')", 1) //use built-in program to obtain average fitstat across imputations

			fitstat = st_numscalar("r(passstat)") - all_subsets_fitstat - constant_model_fitstat //record fitstat omitting constant and "all" subsets values with "mi estimate:"

		}

		return(fitstat)

	}
	
end

**# Mata function to execute epsilon-based relative importance
version 12.1

mata: 

mata set matastrict on

void eps_ri(string scalar varlist, string scalar reg, string scalar touse, string scalar regopts) 
{
	/*object declarations*/
	real matrix X, L, R, Lm, glmdat, glmdats, L2, R2, orth

	real rowvector V, Bt, V2, glmwgts, varloc
	
	string rowvector orthnames
	
	real scalar sd_yhat, cor_yhat
	
	string scalar predmu
	
	/*begin processing*/
	X = correlation(st_data(., tokens(varlist), st_varindex(touse))) //obtain correlations
	
	L = R = X[2..rows(X), 2..cols(X)] //set-up for svd()
	
	V = J(1, cols(X)-1, .) //placeholder for eigenvalues
	
	svd(X[2..rows(X), 2..cols(X)], L, V, R) //conduct singular value decomposition
	
	Lm = (L*diag(sqrt(V))*R) //process orthogonalized predictors
	
	if (reg == "regress") Bt = invsym(Lm)*X[2..rows(X), 1] //obtain adjusted regression weights
	
	else if (reg == "glm") { //if glm-based...
	
		glmdat = st_data(., tokens(varlist), st_varindex(touse)) //pull data into Mata
		
		L2 = R2 = glmdat[., 2..cols(glmdat)] //set-up for svd()
		
		V2 = V //placeholder for eigenvalues
		
		glmdats = (glmdat[., 2..cols(glmdat)]:-mean(glmdat[., 2..cols(glmdat)])):/sqrt(diagonal(variance(glmdat[., 2..cols(glmdat)])))' //standardize the input data
	
		svd(glmdats, L2, V2, R2) //conduct singular value decomposition on full data
		
		orth = L2*R2 //produce the re-constructed orthogonal predictors for use in regression
		
		orth = (orth:-mean(orth)):/sqrt(diagonal(variance(orth)))' //standardize the orthogonal predictors
		
		orthnames = st_tempname(cols(orth))
		
		varloc = st_addvar("double", orthnames) //generate some tempvars for Stata
		
		st_store(., orthnames, st_varindex(touse), orth) //put the orthogonalized variables in Stata
		
		stata("capture " + reg + " " + tokens(varlist)[1] + " " + invtokens(orthnames) + " if " + touse + ", " + regopts) //conduct the analysis

		if (st_numscalar("c(rc)")) {
		
			display("{err}{cmd:" + reg + "} failed when executing {cmd:epsilon}.")
		
			exit(st_numscalar("c(rc)"))
			
		}
		
		glmwgts = st_matrix("e(b)") //record the regression weights to standardize
		
		predmu = st_tempname() //generate some more tempvars for Stata
		
		sd_yhat = sqrt(variance(orth*glmwgts[1, 1..cols(glmwgts)-1]')) //SD of linear predictor
		
		stata("quietly predict double " + predmu + " if " + touse + ", mu") //translated with link function
		
		cor_yhat = correlation((glmdat[., 1], st_data(., st_varindex(predmu), st_varindex(touse))))
		
		Bt = (glmwgts[1, 1..cols(glmwgts)-1]:*((cor_yhat[2, 1])/(sd_yhat)))'

	}
	
	else { //asked for invalid reg
	
		display("{err}{opt reg(" + reg + ")} invalid with {opt epsilon}.")
	
		exit(198)
		
	}
	
	Bt = Bt:^2 //square values of regression weights
	
	Lm = Lm:^2 //square values of orthogonalized predictors

	st_matrix("r(domwgts)", (Lm*Bt)')	//produce proportion of variance explained and put into Stata
	
	st_numscalar("r(fs)", sum(Lm*Bt))	//sum relative weights to obtain R2
	
}

end
