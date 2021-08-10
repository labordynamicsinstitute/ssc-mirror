//------------------------------------------------------------------------------
// REGHDFE_ABSORB: Runs three steps required to demean wrt FEs
//------------------------------------------------------------------------------
/* TYPICAL USAGE - Five steps, with some user work in between (see Estimate.ado)

 (-)		Call -Parse-
			
 (1)	reghdfe_absorb, step(start) absorb(...)  avge(...) clustervar1(...) fweight(..)
			Parse absorb(), create almost-empty Mata objects
			Parse avge() and store results in Mata string vectors
			RETURN r(N_hdfe) r(N_avge) r(keepvars)

		[Until here, no data has been touched]

 (-) 		Preserve data
			Drop unused vars
			Expand factors and time series in all varlists
			Drop unused base vars of the factors vars
			Drop obs with MVs

 (2)	reghdfe_absorb, step(precompute) keepvars(...)  [depvar(...)  excludeself]
			Transform wrt -avge-
			Drop MVs caused by -excludeself-
			Fill mata objects with counts and means, delete unused vars
			RETURN r(clustervar1)

 (-)		Compute statistics such as TSS, used later on
			Save untransformed variables

 (3)	reghdfe_absorb, step(demean) varlist(...)  [maximize_options..]
			Obtain residuals of varlist wrt the FEs
			Note: can be run multiple times

 (-)		Drop IDs of the FEs if needed
			Optain DoF
			Run regressions, residuals, etc.
			Load untransformed variables
			Use predict to get resid+d

		reghdfe_absorb, step(demean) save_fe(1) var(resid_d) -> get FEs
 (4)	reghdfe_absorb, step(save) original_depvar(..)
			Save required FEs with proper name, labels, etc.

 (5)	reghdfe_absorb, step(stop)
			Clean up all Mata objects

 (-)		Restore, merge sample(), report tables
//----------------------------------------------------------------------------*/


*clear mata// -------------------------------------------------------------
// MATA functions and objects
// -------------------------------------------------------------
// struct FE: 				Container with data for each FE
// prepare(fe_varlist): 	Constructs the basic objects in order to obtain resid later on
// make_residual(varname): 	Obtains residual of varname wrt to the previously indicated FEs
// transform(x, g0, g1):	Transforms x from series (g=0) or means by FE (g>1) into either of those
// count_by_group(): 		Called by prepare

// -------------------------------------------------------------
// Shortcuts
// -------------------------------------------------------------
local Varlist 		string scalar
local Integer 		real scalar
local VarByFE 		real colvector // Should be levels*1
local Series		real colvector // Should be N*1
local Matrix		real matrix
local SharedData 	external struct FixedEffect vector

mata:
mata set matastrict on

// -------------------------------------------------------------
// Structures
// -------------------------------------------------------------
	// Notice that every FE costs around 3 -doubles- of memory (obs*8 bytes)
	struct FixedEffect {
		`Integer' levels // Distinct values of FE (recall its sorted 1..levels)
		`Integer' g // Identifier of this FE
		`Integer' is_interaction, is_cont_interaction, is_bivariate, is_mock
		`Integer' K // Number of params in a multivariate by-group regression (usually 1 or 2)
		`Matrix' v // The continuous var, if is_cont_interaction==1
		`Matrix' invxx // The inv(X'X) matrix where X is v + constant (constant last!)
		`VarByFE' count, sum_count // count=levels*1 with a count of each level. sum_count=Running sum of the above!
		`Series' group, indexfrom0, indexfrom1, sorted_weight // weight is freq. weight, sorted by indexfrom0
		`Varlist' varname, Z, target, ivars, cvars, varlabel, weightvar // weightvar is just the varname with the frequencies
	}

// -------------------------------------------------------------
// PREPARE DATA: Create almost-empty aux structures and fill them
// -------------------------------------------------------------

// Create the structures and shared variables
void function initialize() {
	`SharedData' FEs
	external `Integer' G // Number of FEs
	external `Matrix' betas

	assert(G>0 & G<=100)
	FEs = J(G, 1, FixedEffect()) // Use G=100 for now (should be enough)
	betas = 0
}

// Add basic data into each structure
void function add_fe(
		`Integer' g, `Varlist' varlabel, `Varlist' target, 
		`Varlist' ivars, `Varlist' cvars, `Integer' is_interaction,
		`Integer' is_cont_interaction, `Integer' is_bivariate,
		`Varlist' weightvar,
		`Integer' is_mock) {
	`SharedData' FEs
	assert(is_mock==0 | is_mock==1)
	FEs[g].g = g
	FEs[g].ivars = ivars
	FEs[g].cvars = cvars
	FEs[g].is_interaction = is_interaction
	FEs[g].is_bivariate = is_bivariate
	FEs[g].is_mock = is_mock
	FEs[g].K = 1 + length(tokens(cvars)) // 1 w/out cvars, 2 with bivariate, +2 with multivariate within the group
	FEs[g].is_cont_interaction = is_cont_interaction
	FEs[g].varname = "__FE" + strofreal(g) + "__"
	FEs[g].Z = "__Z" + strofreal(g) + "__"
	FEs[g].varlabel = varlabel
	FEs[g].levels = -1 // Not yet filled
	FEs[g].target = target + (is_mock & target!="" ? "_slope" : "")
	if (FEs[g].K>2 & FEs[g].target!="") FEs[g].target = FEs[g].target + strofreal(FEs[g].K-1)
	FEs[g].weightvar = weightvar
}

// Dump data of one FE to locals
void function fe2local(`Integer' g) {
	`SharedData' FEs
	stata("c_local ivars " + FEs[g].ivars)
	stata("c_local cvars " + FEs[g].cvars)
	stata("c_local target " + FEs[g].target)
	stata("c_local varname " + FEs[g].varname)
	stata("c_local Z " + FEs[g].Z)
	stata("c_local varlabel " + FEs[g].varlabel)
	stata("c_local is_interaction " + strofreal(FEs[g].is_interaction))
	stata("c_local is_cont_interaction " + strofreal(FEs[g].is_cont_interaction))
	stata("c_local is_bivariate " + strofreal(FEs[g].is_bivariate))
	stata("c_local is_mock " + strofreal(FEs[g].is_mock))
	stata("c_local levels " + strofreal(FEs[g].levels))
	stata("c_local group_k " + strofreal(FEs[g].K))
	stata("c_local fweight " + FEs[g].weightvar)
}

// Fill aux structures
void function prepare() {

	external `Integer'	G
	`SharedData' 		FEs
	external `Integer' 	VERBOSE
	`Integer'			g, obs, mem_used, is_weighted
	`Series'			group, weight
	`VarByFE'			count
	`Varlist'			weightvar

	// Setup
	assert(VERBOSE>=0 & VERBOSE<=5)
	obs = st_nobs()
	weightvar = ""
	is_weighted = (FEs[1].weightvar!="")
	if (is_weighted) {
		weightvar = FEs[1].weightvar
		weight = st_data(., weightvar)
	}
	else {
		weight = 1
	}

	// Main code
	for (g=1;g<=G;g++) {

		if (FEs[g].is_mock) {
			FEs[g].levels = FEs[g-1].levels
			continue
		}

		if (VERBOSE>1) printf("{txt}(preparing matrices for fixed effect {res}%s{txt})\n", FEs[g].varlabel)
		FEs[g].group = st_data(., FEs[g].varname)
		if (max(FEs[g].group)>1e8) _error("More than 100MM FEs found. Are you sure FE is in format 1..G?")
		if (min(FEs[g].group)!=1) _error("Minimum value for FE is not 1")
		FEs[g].indexfrom0 = order(FEs[g].group,1)
		if (g>1) FEs[g].indexfrom1 = FEs[1].group[FEs[g].indexfrom0]
		FEs[g].sorted_weight = is_weighted ? weight[FEs[g].indexfrom0, 1] : 0
		count = count_by_group(FEs[g].group, FEs[g].indexfrom0)
		FEs[g].sum_count = quadrunningsum(count)

		// If we have cont. interactions, use the above -count- only for -sum_count-
		// and use this one to get the denominators used in transform
		// Why? because -sum_count- is used to offset the submatrices, while -count- will be a denominator

		if (FEs[g].is_cont_interaction) {
			FEs[g].v = st_data(., FEs[g].cvars)

			if (!FEs[g].is_bivariate) {
				count = count_by_group(FEs[g].group, FEs[g].indexfrom0, FEs[g].v, FEs[g].sorted_weight)
			}
			else {
				count = count_by_group(FEs[g].group, FEs[g].indexfrom0, 0, FEs[g].sorted_weight)
				FEs[g].invxx = compute_invxx(FEs[g].v ,FEs[g].indexfrom0, FEs[g].sum_count, count, FEs[g].sorted_weight)
			}
		}
		else if (is_weighted) {
			count = count_by_group(FEs[g].group, FEs[g].indexfrom0, 0, FEs[g].sorted_weight)
		}
		
		FEs[g].count = count
		FEs[g].levels = rows(FEs[g].sum_count)

		if (VERBOSE>1) {
			mem_used = ( sizeof(FEs[g].group) + sizeof(FEs[g].indexfrom0) + sizeof(FEs[g].indexfrom1) + sizeof(FEs[g].sum_count) ) / 2^20
			printf(" - %3.1fMB used\n", mem_used)
		}
	}
}

// -------------------------------------------------------------
// TRANSFORM: Transform the dim of a vector by taking avgs
// -------------------------------------------------------------
// Type <`VarByFE'> but also works with <`Series'> (<real colvector> both)
// NOTE: g==0 means the raw Stata series, g==1 is collapsed by FE1, etc.
// (This function could benefit from a refactoring...)
//

`VarByFE' function transform(`VarByFE' indata, `Integer' g_from, `Integer' g_to) {
	`VarByFE'		outdata
	`SharedData'	FEs
	`Integer'		from_v, to_v // Whether the new or old FEs have cont. interactions
	`Integer'		is_weighted
	`Series'		indata_v
	`Integer'		from_bivariate, to_bivariate
	external `Matrix' betas

	assert(g_from>=0 & g_from<=100)
	assert(g_to>=0 & g_to<=100)
	assert(g_to!=g_from)
	is_weighted = (FEs[1].weightvar!="")

	// -v- is the possible cont. interaction of the FE
	to_v = from_v = 0 // There is no FEs[0]
	if (g_to>0) to_v = FEs[g_to].is_cont_interaction
	if (g_from>0) from_v = FEs[g_from].is_cont_interaction // & (!FEs[g_from].is_bivariate | FEs[g_from].is_mock)
	
	// g_from, g_to, from_v, to_v

	if (g_to>0) {
		if (FEs[g_to].is_mock==1) {
			_error("g_to shouldn't be the 2nd part of a ## interaction")
		}
	}

	if (g_from>0) {
		if (FEs[g_from].is_mock==1) {
			--g_from // Go back to non-mock
		}
	}


	if (g_to>0) {
		// If g_to is the first FE of a bivariate, do the regression and save the cache
		assert(FEs[g_to].is_bivariate==0 | FEs[g_to].is_bivariate==1)
		if (FEs[g_to].is_bivariate==1) {
			assert(!FEs[g_to].is_mock)
			// We have to deal with 0->g and 1->g transforms

			if (g_from>0 & !from_v) {
				assert(g_from==1)
				indata = indata[FEs[g_from].group, 1]
			}
		
			// -outdata- will have the predicted values (i.e. yhat = alpha + v1*beta1 + ..) by group, expanded
			outdata= regress_by_group(indata, FEs[g_to].v, FEs[g_to].indexfrom0, FEs[g_to].sum_count, FEs[g_to].count, FEs[g_to].invxx, FEs[g_to].sorted_weight, FEs[g_to].group)
			assert(rows(outdata)==st_nobs())
			assert(cols(outdata)==1)
			// b1 b2 .. alpha are in the external matrix -betas- , of size (K*levels,K)
			assert(rows(betas)==FEs[g_to].levels)
			assert(cols(betas)==FEs[g_to].K)
			return(outdata)
		}
	}

	if (!to_v & !from_v) {
		// sorted_weight should be of the same group as sum_count .. 
		if (g_to==0) {
			outdata = indata[FEs[g_from].group,1]
		}
		else if (g_from==0) {
			outdata = mean_by_group(indata, FEs[g_to].indexfrom0, FEs[g_to].sum_count, FEs[g_to].count, FEs[g_to].sorted_weight)
		}
		else if (g_from==1) {
			outdata = remean_by_group(indata, FEs[g_to].indexfrom1, FEs[g_to].sum_count, FEs[g_to].count, FEs[g_to].sorted_weight)
		}
		else {
			_error(sprintf("\nNot implemented"))
		}
	}
	else { // With cont interaction but not bivariate
		if (from_v & g_to==0) return(indata)
		
		if (from_v & g_to>0 & !to_v) {
			outdata = mean_by_group(indata, FEs[g_to].indexfrom0, FEs[g_to].sum_count, FEs[g_to].count, FEs[g_to].sorted_weight)
			return(outdata)
		}

		// In the remaining cases, the output has same dim as -v-
		
		if (g_from==0 | (from_v & to_v) ) {
			// Inline it?? BUGBUG TODO
			indata_v = FEs[g_to].v :* indata
		}
		else if (g_from==1 & !from_v) { // Either to_v==1 or g_to==0
			// Convert to a g==0 dimension
			indata_v = FEs[g_to].v :* indata[FEs[g_from].group, 1]
		}
		else {
			_error(sprintf("\nNot implemented"))
		}
		// Will have MVs for groups where all obs of V are zero
		outdata = editmissing(mean_by_group(indata_v, FEs[g_to].indexfrom0, FEs[g_to].sum_count, FEs[g_to].count, FEs[g_to].sorted_weight) , 0)
		outdata = FEs[g_to].v :* outdata[FEs[g_to].group, 1]
		assert(rows(outdata)==st_nobs())
	}
	return(outdata)
}


// -------------------------------------------------------------
// COUNT_BY_GROUP: alternative to mm_freq(group) (~10% of runtime)
// -------------------------------------------------------------
`VarByFE' function count_by_group(`Series' group, `Series' index, | `Series' v, `Series' sorted_weight)
{
	`Integer' 	levels, obs, i, count, g, is_cont_interaction, is_weighted, ww, vv
	`Series'	sorted_group, sorted_v
	`VarByFE'	ans
	sorted_group = group[index, 1]
	levels = max(group)
	obs = rows(group)
	ans = J(levels, 1, 0)
	if (levels>obs) _error("Error: more levels of FE than observations!")
	is_cont_interaction = (args()>=3 & length(v)>1 ) // -v- is the continuous interaction
	is_weighted = (args()>=4 & length(sorted_weight)>1 )
	if (is_cont_interaction) sorted_v = v[index]
	
	// -g- iterates over the values of the FE, -i- over observations
	// Should we have the -if- for v and weights inside or outside the hot loop?
	// If we put the -if- outside, we can use "count++" for the simple case
	// Check how large is the slowdown...
	count = 0
	for (i=g=1; i<=obs; i++) {
		if (g<sorted_group[i]) {
			ans[g++] = count
			count = 0
		}
		ww = is_weighted ? sorted_weight[i] : 1
		vv = is_cont_interaction ? sorted_v[i] ^ 2 : 1
		count = count + ww * vv
	}
	ans[g] = count // Last group
	if (!is_cont_interaction) assert( all(ans) ) // assert( all(ans:>0) )
	// BUGBUG -ans- may be zero for some cases!!!!!!!!!!!
	return(ans)
}

// -------------------------------------------------------------
// MEAN_BY_GROUP: Take a N*1 vector and save the avg by FE into a levels*1 vector
// -------------------------------------------------------------
`VarByFE' function mean_by_group(`Series' indata, `Series' index, `VarByFE' sum_count, `VarByFE' counts_to, `Series' sorted_weight)
{
	`Integer'	levels, i, j_lower, j_upper
	`Series'	sorted_indata
	`VarByFE'	outdata

	assert(rows(indata)==rows(index))
	levels = rows(sum_count)
	sorted_indata = indata[index] // Also very crucial to speed
	if (length(sorted_weight)>1) sorted_indata = sorted_indata :* sorted_weight
	outdata = J(levels, 1 , 0)
	
	// !! This is one of the most hot / crucial loops in the entire program
	j_lower = 1
	for (i=1; i<=levels; i++) {
		j_upper = sum_count[i]
		outdata[i] = quadcolsum(sorted_indata[| j_lower \ j_upper |])
		j_lower = j_upper + 1
	}
	outdata = outdata :/ counts_to
	return(outdata)
}

// -------------------------------------------------------------
// REMEAN_BY_GROUP: Transform one mean by group into another (of a diff group)
// -------------------------------------------------------------
`VarByFE' function remean_by_group(`VarByFE' indata, `Series' index, `VarByFE' sum_count, `VarByFE' counts_to, `Series' sorted_weight)
{
	`Integer'	levels_from, levels_to, i, j_lower, j_upper, obs
	`Series'	se_indata
	`VarByFE'	outdata

	obs = rows(index)
	levels_to = rows(sum_count)
	levels_from = rows(indata)
	assert(obs==st_nobs())
	assert(levels_from==max(index))
	//assert( all(indata:<.) )
	se_indata = indata[index, 1] // SE = Sorted & Expanded
	if (length(sorted_weight)>1) se_indata = se_indata :* sorted_weight
	outdata = J(levels_to, 1 , 0)
	// assert( all(se_indata:<.) )
	
	// !! This is one of the most hot / crucial loops in the entire program
	j_lower = 1
	for (i=1; i<=levels_to; i++) {
		j_upper = sum_count[i]
		outdata[i] = quadcolsum(se_indata[| j_lower \ j_upper |])
		j_lower = j_upper + 1
	}

	outdata = outdata :/ counts_to
	// mean() is much* slower than doing -quadcolsum- and then dividing by counts_to
	return(outdata)
}

// -------------------------------------------------------------
// REGRESS_BY_GROUP: Multivariate regression on constant and at least 1 var.
// -------------------------------------------------------------
// Returns block-column matrix with estimates by group; last estimate is the constant
// (This function hasn't been optimized very much)
`Matrix' function regress_by_group(`Series' y, `Matrix' x, `Series' index, 
	`VarByFE' offset, `VarByFE' count, `Matrix' invxx, `Series' sorted_weight, group)
{
	`Integer'			N, K, levels, is_weighted, j_lower, j_upper, i
	`Series'			predicted, tmp_y, tmp_w, sorted_y
	real colvector		b
	external `Matrix'   betas
	`Matrix'			tmp_x, tmp_invxx, sorted_x

	N = rows(x)
	K = 1 + cols(x)
	levels = rows(offset)
	is_weighted = length(sorted_weight)>1
	sorted_y = y[index,.]
	sorted_x = x[index,.]
	predicted = J(N, 1 , 0)
	betas = J(levels, K, 0)
	
	assert(rows(y)==N)
	assert(rows(index)==N)
	assert(rows(count)==levels)
	assert(rows(invxx)==levels*K & cols(invxx)==K)
	if (is_weighted) assert(rows(sorted_weight)==N)
	if (!is_weighted) assert(sorted_weight==0)
	
	j_lower = 1
	for (i=1; i<=levels; i++) {
		j_upper = offset[i]
		tmp_x = sorted_x[| j_lower , 1 \ j_upper , . |]
		tmp_y = sorted_y[| j_lower , 1 \ j_upper , . |]
		tmp_invxx = invxx[| 1+(i-1)*K , 1 \ i*K , . |]
		if (is_weighted) {
			tmp_w = sorted_weight[| j_lower , 1 \ j_upper , 1 |]
			b = tmp_invxx * quadcross(tmp_x, 1, tmp_w, tmp_y, 0)
		}
		else {
			b = tmp_invxx * quadcross(tmp_x, 1, tmp_y, 0)
		}
		betas[i, .] = b'
		//predicted[| j_lower , 1 \ j_upper , . |] = b[K] :+ tmp_x * b[|1 \ K-1|] // Doesn't work b/c its sorted by index, and I didn't save the reverse sort....
		j_lower = j_upper + 1
	}

	predicted = rowsum( (x , J(rows(predicted),1,1)) :* betas[group,.] )
	return(predicted)
}

// -------------------------------------------------------------
// COMPUTE_INVXX
// -------------------------------------------------------------
`Matrix' function compute_invxx(`Matrix' x, `Series' index, `VarByFE' offset, `VarByFE' count, `Series' sorted_weight)
{
	`Integer'	N, levels, K, is_weighted, j_lower, j_upper, i
	`Matrix'	ans, invxx, tmp_x, sorted_x
	`Series'	tmp_w

	N = rows(x)
	K = 1 + cols(x)
	levels = rows(offset)
	is_weighted = length(sorted_weight)>1
	sorted_x = x[index,.]
	ans = J(levels * K, K, 0)
	
	assert(rows(index)==N)
	assert(rows(count)==levels)
	if (is_weighted) assert(rows(sorted_weight)==N)
	if (!is_weighted) assert(sorted_weight==0)
	
	j_lower = 1
	for (i=1; i<=levels; i++) {
		j_upper = offset[i]
		tmp_x = sorted_x[| j_lower , 1 \ j_upper , . |]
		if (is_weighted) {
			tmp_w = sorted_weight[| j_lower , 1 \ j_upper , 1 |]
			invxx = invsym(quadcross(tmp_x,1,tmp_w,tmp_x,1))
		}
		else {
			invxx = invsym(quadcross(tmp_x,1,tmp_x,1))
		}
		ans[| 1+(i-1)*K , 1 \ i*K , . |] = invxx
		j_lower = j_upper + 1
	}
	return(ans)
}

// -------------------------------------------------------------
// MAKE_RESIDUAL: Take a variable and obtain its residual wrt many FEs
// -------------------------------------------------------------
// num_fe: Allows running nested models
void function make_residual(
	`Varlist' varname, `Varlist' resid_varname, 
	`Integer' tolerance, `Integer' max_iterations, | `Integer' save_fe, 
	`Integer' accelerate, `Integer' num_fe,
	`Integer' bad_loop_threshold, `Integer' stuck_threshold,
	`Integer' pause_length, `Integer' accel_freq, `Integer' accel_start)
{
	`SharedData' 		FEs
	external `Integer' 	VERBOSE
	external `Integer'	G
	
	// bad_loop_threshold, stuck_threshold, accel_freq, accel_start, pause_length
	`Integer'	update_error, converged, iter, accelerate_candidate, accelerated, mu, accelerate_norm
	`Integer'	eps, g, obs, stdev, levels, gstart, gextra, k // , _
	`Integer'	acceleration_countdown, old_error, oldest_error, bad_loop, improvement
	`Series' 	y, resid, ZZZ // ZZZ = sum of Zs except Z1
	`VarByFE'	P1y
	string scalar		code, msg
	pointer(`VarByFE') colvector	Deltas, oldDeltas, Zs, oldZs, Pytildes
	external `Matrix'	betas
	
	// Parse options
	assert(G==rows(FEs))
	obs = st_nobs()
	assert(VERBOSE>=0 & VERBOSE<=5)

	if (args()<5 | save_fe==.) save_fe = 0
	if (args()<6 | accelerate==.) accelerate = 1
	if (args()<7 | num_fe==-1) num_fe = G
	if (save_fe!=0 & save_fe!=1) _error("Option -save_fe- must be either 0 or 1")

	// See below for explanation
	if (args()<8 | bad_loop_threshold==-1) bad_loop_threshold = 1
	if (args()<9 | stuck_threshold==-1) stuck_threshold = 5e-3
	if (args()<10 | pause_length==-1) pause_length = 20
	if (args()<11 | accel_freq==-1) accel_freq = 3
	if (args()<12 | accel_start==-1) accel_start = 6
	// BUGBUG: These defaults are in triplicate: here, in reghdfe_absorb, and in reghdfe.prase

	// Should I expose these parameters?
	// bad_loop_threshold = 1 // If acceleration seems stuck X times in a row, pause it
	// stuck_threshold = 5e-3 // Call the improvement "slow" when it's less than e.g. 1%
	// pause_length = 20 // This is in terms of candidate accelerations, not iterations (i.e. x3)?
	// accel_freq = 3
	// accel_start = 6

	// Initialize vectors of pointers and others
	gstart = 1 + FEs[1].K
	Deltas = oldDeltas = Zs = oldZs = Pytildes = J(num_fe,1,NULL)
	ZZZ = J(obs, 1, 0) // oldZZZ = 
	for (g=gstart;g<=num_fe;g++) {
		if (FEs[g].is_cont_interaction) levels = obs
		else levels = FEs[g].levels

		if (FEs[g].is_mock) levels = 0 // Better than not initializing them
		
		Deltas[g] = &J(levels,1,.)
		oldDeltas[g] = &J(levels,1,.)
		Zs[g] = &J(levels,1,0) // Needs to start with 0s
		oldZs[g] = &J(levels,1,0) // Needs to start with 0s
		Pytildes[g] = &J(levels,1,.)
	}
	
	// Calculate P1*y and save in mata, then M1*y==ytilde and save in stata
	if (VERBOSE>0) {
		if (substr(varname, 1, 2)=="__") {
			msg = st_global(varname+"[fvrevar]")
			msg = msg + st_global(varname+"[tsrevar]")
			msg = msg + st_global(varname+"[avge]")
			if (msg=="") msg = "[residuals]"
		}
		else {
			msg = varname
		}
		printf("{txt}(computing residual of {res}%s{txt} with respect to %1.0f FE%s" + (VERBOSE==1 & num_fe>1? " " : ")\n"), msg, num_fe, num_fe==1? "" : "s")
		displayflush()
	}
	if (VERBOSE>1) printf("{txt} - Demeaning wrt FE1\n")

	st_view(y=., ., varname)
	stdev = sqrt(quadvariance(y))
	if (VERBOSE>1) printf("{txt} - Stdev of var is %12.6g\n",stdev)
	if (stdev<1e-8) stdev = 1 // Probably a constant, can't standardize
	
	if (FEs[1].is_cont_interaction & !FEs[1].is_bivariate) {
		_error("error: the first absvar cannot be an interaction with a cont. var")
	}

	P1y = transform(y, 0, 1)
	st_store(., st_addvar("double", resid_varname), transform(P1y, 1, 0)) // Store P1*y
	stata(sprintf(`"qui replace %s = %s - %s"', resid_varname, varname, resid_varname)) // ytilde===M1*y = y - P1*y
	stata(sprintf(`"la var %s "[reghdfe residuals of %s]" "', resid_varname, varname)) // Useful to know what is what when debugging

	if (num_fe<gstart) {
		if (save_fe!=0) {
			if (VERBOSE>1) printf("{txt} - Saving FE\n")
			if (gstart==2) {
				st_store(., st_addvar("double", FEs[1].Z), transform(P1y, 1, 0))
			}
			else {
				st_store(., st_addvar("double", FEs[1].Z), betas[FEs[1].group,FEs[1].K] )
				for (k=2; k<=FEs[1].K; k++) {
					st_store(., st_addvar("double", FEs[k].Z), FEs[1].v[.,k-1] :* betas[FEs[1].group,k-1] )
				}
			}
		}
		return
	}

	// Compute P2*ytilde, P3*ytilde and so on
	st_view(resid=., ., resid_varname) // BUGBUG? is using view too slow??
	for (g=gstart;g<=num_fe;g++) {
		if (FEs[g].is_mock) continue
		(*Pytildes[g]) = transform(resid, 0, g) :/ stdev // Standarize to get convergence independent of the scale (1000s, units, etc)
		assert(rows(*Pytildes[g])>0)
	}

	// --------------------------------
	if (VERBOSE>1) printf("{txt} - Starting iteration...\n")
	// --------------------------------
	converged = 0
	eps = epsilon(1) // Which one works better? sqrt(epsilon(1)) // 1e-8  ...  epsilon(1) ~ 2e-16
	old_error = oldest_error = bad_loop = acceleration_countdown = 0
	gextra = gstart + FEs[gstart].is_bivariate
	if (VERBOSE>1) timer_clear(40)
	for (iter=1; iter<=max_iterations; iter++) {
		// _ = _stata("parallel break")

		// Acceleration setup
		
		accelerated = 0
		accelerate_candidate = accelerate & (mod(iter, accel_freq)==1) & (iter>accel_start) // Optimal accel interval? // ==0 ?
		// If the FP is stuck, stop accelerating for a few periods
		code = accelerate_candidate ? "x" : "."
		if (accelerate_candidate==1 & acceleration_countdown>0) {
			--acceleration_countdown
			accelerate_candidate = 0
		}
		
		// Update Zs
		if (VERBOSE>1) timer_on(40)		
		for (g=gstart;g<=num_fe;g++) {
			if (FEs[g].is_mock) continue
			if (accelerate_candidate) (*oldDeltas[g]) = (*Deltas[g]) // Only update when needed

			// -reghdfe.ado- will spend most of its time in this line:
			if (FEs[g].is_bivariate) {
				(*Deltas[g]) = (*Pytildes[g]) + transform(transform(ZZZ,0,1), 1, g) - (num_fe>gextra? transform(ZZZ, 0, g) : (*Zs[g]) )
			}
			else {
				(*Deltas[g]) = (*Pytildes[g]) + transform(transform(ZZZ,0,1), 1, g) - (num_fe>gextra? transform(ZZZ, 0, g) : (*Zs[g]) )
			}


			(*Zs[g]) = (*Zs[g]) + (*Deltas[g])
			ZZZ = ZZZ + transform(*Deltas[g], g, 0)
		}
		
		if (VERBOSE>1) timer_off(40)
		// Optional: Acceleration
		// This is method 3 of Macleod (1986), a vector generalization of the Aitken-Steffensen method
		// Also: "when numerically computing the sequence.. stop..  when rounding errors become too 
		// important in the denominator, where the ^2 operation may cancel too many significant digits"

		// Sometimes the iteration gets "stuck"; can we unstuck it with adding randomness in the accelerate decision?
		// There should be better ways too..
		
		if (accelerate_candidate) {
			mu = accelerate_norm = 0
			for (g=gstart;g<=num_fe;g++) {
				if (FEs[g].is_mock) continue
				mu = mu + quadcross( (*Deltas[g]) , (*Deltas[g]) - (*oldDeltas[g]) )
				accelerate_norm = accelerate_norm + norm((*Deltas[g]) - (*oldDeltas[g])) ^ 2
			}
			accelerate_norm = max((accelerate_norm, eps))
			//(iter, mu, accelerate_norm, mu/accelerate_norm, mean(*Zs[2]), mean(*Deltas[2]))
			mu = mu / accelerate_norm

			// Don't accelerate if mu is close to 0 (highly unlikely)
			if (abs(mu)>1e-6) {
				code = "a"
				accelerated = 1
				for (g=gstart;g<=num_fe;g++) {
					if (FEs[g].is_mock) continue
					(*Zs[g]) = (*Zs[g]) - mu :* (*Deltas[g])
					ZZZ = ZZZ - mu :* transform((*Deltas[g]), g, 0)
				}
			}
		} // accelerate_candidate
		
		// Reporting
		//update_error = (iter==1)? 1 : mean(reldif((*oldZs[g]), (*Zs[g])))
		update_error = 0
		for (g=gstart;g<=num_fe;g++) {
			if (FEs[g].is_mock) continue
			update_error = max(( update_error , mean(reldif( (*oldZs[g]) , (*Zs[g]) )) )) // max or mean?
			(*oldZs[g]) = (*Zs[g])
		}
		if (iter==1) update_error = 1
		//oldZZZ = ZZZ

		if ((VERBOSE>=2 & VERBOSE<=3 & mod(iter,1)==0) | (VERBOSE==1 & mod(iter,99)==0)) {
			printf(code)
			displayflush()
		}

		// Experimental: Pause acceleration when it seems stuck
		if (accelerated==1) {
			improvement = max(( (old_error-update_error)/update_error , (oldest_error-update_error)/update_error ))
			bad_loop = improvement < stuck_threshold ? bad_loop+1 : 0
			// bad_loop, improvement, update_error, old_error, oldest_error
			// Tolerate two problems (i.e. 6+2=8 iters) and then try to unstuck
			if (bad_loop>bad_loop_threshold) {
				bad_loop = 0
				if (VERBOSE==3) printf(" Fixed point iteration seems stuck, acceleration paused\n")
				acceleration_countdown = pause_length
			}
			assert(bad_loop<=3)	
			oldest_error = old_error
			old_error = update_error
		}

		if (VERBOSE>=2 & VERBOSE<=3 & mod(iter,99)==0) printf("%9.1f\n", update_error/tolerance)
		if (VERBOSE>=4) printf("%12.7e %1.0f \n", update_error, accelerate_candidate + accelerate_candidate*(acceleration_countdown==pause_length) ) // 0=Normal 1=Accel 2=BadAccel
		
		if ( (accelerated==0) & (update_error<tolerance) ) {
			converged = 1
			break
		}
	} // for

	if (VERBOSE>=2 & VERBOSE<=3 & mod(iter,99)!=0) printf("\n")
	if (!converged) {
		stata(sprintf(`"di as error "could not obtain resid of %s in %g iterations (last error=%e)""', varname, max_iterations, update_error))
		exit(error(430))
	}
	if (VERBOSE>1) printf("{txt} - Converged in %g iterations (last error =%3.1e)\n", iter, update_error)
	if (VERBOSE==1) printf("{txt} converged in %g iterations, last error =%3.1e)\n", iter, update_error)
	if (VERBOSE>1) printf("{txt} - Saving output\n")

	// Recover Z1 = P1(y-ZZZ) where ZZZ=Z2+..+ZG
	Zs[1] = &transform(transform(y-stdev:*ZZZ, 0, 1), 1, 0)
	// Recover resid of y = y - ZZZ - Z1
	st_store(., resid_varname, y-stdev:*ZZZ-*Zs[1]) // BUGBUG if resid is just a vew, just do resid[.,.] = y-...

	// Save FEs
	if (save_fe!=0) {
		if (VERBOSE>1) printf("{txt} - Saving FEs\n")
		
		if (gstart==2) {
			st_store(., st_addvar("double", FEs[1].Z), *Zs[1])
		}
		else {
			st_store(., st_addvar("double", FEs[1].Z), betas[FEs[1].group,FEs[1].K] )
			for (k=2; k<=FEs[1].K; k++) {
				st_store(., st_addvar("double", FEs[k].Z), FEs[1].v[.,k-1] :* betas[FEs[1].group,k-1] )
			}
		}

		for (g=gstart;g<=num_fe;g++) {
			if (FEs[g].is_mock) continue

			if (!FEs[g].is_bivariate) {
				st_store(., st_addvar("double", FEs[g].Z), transform(stdev :* (*Zs[g]), g, 0))
			}
			else {
				(*Zs[g]) = transform((*Zs[g]), 0, g) // this saves -betas-
				st_store(., st_addvar("double", FEs[g].Z), stdev :* betas[FEs[g].group,FEs[g].K] )
				for (k=2; k<=FEs[g].K; k++) {
					st_store(., st_addvar("double", FEs[g+k-1].Z), stdev :* FEs[g].v[.,k-1] :* betas[FEs[g].group,k-1] )
				}
			}
		}

	}

	if (VERBOSE>1) {
		printf("{txt} - make_residual: inner loop took {res}%-6.2g \n\n", timer_value(40)[1])
		timer_clear(40)
		printf("")
	}

}

end


//------------------------------------------------------------------------------
program define reghdfe_absorb, rclass
//------------------------------------------------------------------------------
	local version `clip(`c(version)', 11.2, 13.1)' // 11.2 minimum, 13+ preferred
	qui version `version'

* This allows to dump the information for one FE as locals in the caller namespace
	cap syntax, fe2local(integer) [*]
	local rc = _rc
	 if (`rc'==0) {
		local g `fe2local'
		assert inrange(`g',1,100)
		mata: fe2local(`fe2local')
		exit
	}

* Parallel instance
	cap syntax, instance [*]
	local rc = _rc
	 if (`rc'==0) {
		ParallelInstance, `options'
		exit
	}

* Parse
	syntax, STEP(string) [CORES(integer 1)] [*]

* Sanity checks
	local numstep = ("`step'"=="start") + 2*("`step'"=="precompute") + ///
		3*("`step'"=="demean") + 4*("`step'"=="save") + 5*("`step'"=="stop")
	Assert (`numstep'>0), msg("reghdfe_absorb: -`step'- is an invalid step name" _n ///
			"valid steps are: start precompute demean save stop")

	cap mata: st_local("prev_numstep", strofreal(prev_numstep))
	if (_rc) local prev_numstep 0

	Assert (`numstep'==`prev_numstep'+1) | (`numstep'==5) | ///
		(`numstep'==3 & `prev_numstep'==3) ///
		, msg("reghdfe_absorb: expected step `=`prev_numstep'+1' instead of step 	`numstep'")
	mata: prev_numstep = `numstep'
	if (`numstep'<5) Debug, msg(_n as text "{title:Running -reghdfe_absorb- step `numstep'/5 (`step')}") level(3)

* Call subroutine and return results
	if (`numstep'==1) {
		Initialize, `options'
		return local keepvars "`r(keepvars)'"
		return scalar N_hdfe = r(N_hdfe)
		return scalar N_avge = r(N_avge)
	}
	else if (`numstep'==2) {
		Prepare, `options'
		return local clustervar1 "`r(clustervar1)'"
	}
	else if (`numstep'==3 & `cores'==1) {
		Annihilate, `options'
	}
	else if (`numstep'==3 & `cores'>1) {
		AnnihilateParallel, numcores(`cores') `options'
	}
	else if (`numstep'==4) {
		Save, `options'
		return local keepvars "`r(keepvars)'"
	}
	else if (`numstep'==5) {
		Stop, `options'
	}
	else {
		error 198
	}
end

//------------------------------------------------------------------------------
program define Initialize, rclass
//------------------------------------------------------------------------------
syntax, Absorb(string) [AVGE(string)] [CLUSTERVAR1(string)] [OVER(varname numeric)] [FWEIGHT(varname numeric)]
	Assert !regexm("`absorb'","[*?-]"), ///
		msg("error: please avoid pattern matching in -absorb-")

	if ("`over'"!="") Assert "`avge'"=="", msg("-avge- needs to be empty if -over- is used")

**** ABSORB PART ****

* First pass to get the true number of FEs
	local i 0
	Debug, level(3) msg(_n "Fixed effects:")
	foreach var of local absorb {
		ParseOneAbsvar, absvar(`var')
		local i = `i' + cond(r(is_bivariate), 2, 1)
		* Output: r(target) cvars ivars is_interaction is_cont_interaction is_bivariate
		Assert `i'>1 | "`r(cvars)'"=="" | `r(is_bivariate)', ///
			msg("error parsing absorb : first absvar cannot be continuous interaction" ///
			_n "solution: i) reorder absvars, ii) replace # with ##, iii) add a constant as first absvar (as a workaround)")

		if ("`over'"!="") {
			local ivars r(ivars)
			local dupe : list ivars & over
			Assert ("`dupe'"==""), msg("-over- cannot be part of any absvar")
		}
	}

	if ("`over'"!="") {
		local ++i // We'll add -over- as the first FE
		local pre_absorb `absorb'
		local absorb `over' `absorb'
	}

* Create vector of structures with the FEs
	Assert inrange(`i',1,100), msg("error: too many absorbed variables (do not include the dummies, just the variables)")
	Debug, msg(`"(`i' absorbed fixed `=plural(`i',"effect")': "' as result "`absorb'" as text ")")
	mata: weightexp = ""
	mata: weightvar = ""
	if ("`fweight'"!="") {
		Debug, msg(`"(fweight/aweight: "' as result "`fweight'" as text ")")
		mata: weightexp = "[fw=`fweight']"
		mata: weightvar = "`fweight'"
		**qui cou if `fweight'<=0 | `fweight'>=. | (`fweight'!=int(`fweight'))
		** Move this somewhere else.. else it will fail needlesly if some excluded obs. have missing weights
		**Assert (`r(N)'==0), msg("fweight -`fweight'- can only have strictly positive integers (no zero, negative, MVs, or reals)!")
	}
	mata: G = `i'
	mata: initialize()

* Second pass to save the values
	local i 0
	foreach var of local absorb {
		qui ParseOneAbsvar, absvar(`over_prefix'`var')
		local keepvars `keepvars' `r(ivars)' `r(cvars)'
		local varlabel = "i." + subinstr("`r(ivars)'", " ", "#i.", .)
		if (`r(is_cont_interaction)' & !`r(is_bivariate)') local varlabel "`varlabel'#c.`r(cvars)'"
		
		local args `" "`r(target)'", "`r(ivars)'", "`r(cvars)'", `r(is_interaction)', `r(is_cont_interaction)', `r(is_bivariate)', "`fweight'" "'
		mata: add_fe(`++i', "`varlabel'", `args', 0)
		if (`r(is_bivariate)') {
			local varlabel "`varlabel'#c.`r(cvars)'"
			mata: add_fe(`++i', "`varlabel'", `args', 1)
		}

		if ("`over'"!="") local over_prefix "i.`over'#" // Not for the first one
	}
	local N_hdfe = `i'

	if ("`over'"!="") Debug, msg("absvars expanded due to over: `pre_absorb' -> `absorb'")

**** AVGE PART ****

* First pass to get the true number of FEs
local N_avge = 0
if ("`avge'"!="") {
	local i 0
	foreach var of local avge {
		Debug, level(3) msg(_n "AvgE effects:")
		ParseOneAbsvar, absvar(`var')
		local ++i
		* Output: r(target) cvars ivars is_interaction is_bivariate
		Assert ("`r(cvars)'"=="" & `r(is_bivariate)'==0), ///
			msg("error parsing avge : continuous interactions not allowed")
	}

* Create vectors
	Assert inrange(`i',1,100), msg("error: too many avge variables (do not include the dummies, just the variables)")
	Debug, msg(`"(`i' avge `=plural(`i',"effect")': "' as result "`avge'" as text ")")
}

* Always save this to avoid not-found errors
	mata: avge_ivars = J(1, `i', "")
	mata: avge_target = J(1, `i', "")
	mata: avge_varlabel = J(1, `i', "")

* Second pass to save the values
if ("`avge'"!="") {
	local i 0
	foreach var of local avge {
		qui ParseOneAbsvar, absvar(`var')
		local ++i
		local varlabel = "i." + subinstr("`r(ivars)'", " ", "#i.", .)
		mata: avge_ivars[`i'] = "`r(ivars)'"
		mata: avge_target[`i'] = "`r(target)'"
		mata: avge_varlabel[`i'] = "`varlabel'"
		local keepvars `keepvars' `r(ivars)'
	}
	local N_avge = `i'
}
	mata: avge_num = `N_avge'

*** CLUSTER PART ****
* EG: If clustervar1=foreign, absorb=foreign, then clustervar1 -> __FE1__
	mata: ivars_clustervar1 = ""
	if ("`clustervar1'"!="") {
		Debug, level(3) msg(_n "Cluster by:")
		ParseOneAbsvar, absvar(`clustervar1')
		Assert "`r(cvars)'"=="", msg("clustervar cannot contain continuous interactions")
		local ivars_clustervar1 "`r(ivars)'"
		local keepvars `keepvars' `r(ivars)'
		mata: ivars_clustervar1 = "`ivars_clustervar1'"
	}
	
**** Returns ****
	Debug, level(3) newline
	local keepvars : list uniq keepvars
	return local keepvars `keepvars'
	return scalar N_hdfe = `N_hdfe'
	return scalar N_avge = `N_avge'
end


//------------------------------------------------------------------------------
program define ParseOneAbsvar, rclass
//------------------------------------------------------------------------------
syntax, ABSVAR(string)

	Assert !strpos("`absvar'","###"), msg("error parsing <`absvar'> : ### is invalid")
	Assert regexm("`absvar'", "^[a-zA-Z0-9_=.#]+$"), msg("error parsing <`absvar'> : illegal characters ")
	Assert !regexm("`absvar'", "##([^c]|(c[^.]))"), msg("error parsing <`absvar'> : expected c. after ##")
	local original_absvar `absvar'

* Split at equal sign
	local equalsign = strpos("`absvar'","=")
	local target = substr("`absvar'",1,`equalsign'-1)
	local absvar = substr("`absvar'",`equalsign'+1, .)
	if ("`target'"!="") conf new var `target'

	local is_interaction = strpos("`absvar'", "#")>0
	local is_bivariate = strpos("`absvar'", "##")>0

* Split interactions
	mata: st_local("vars", subinstr("`absvar'", "#", " ") )
	foreach var of local vars {

		local dot = strpos("`var'", ".")
		local root = substr("`var'", `dot'+1, .)
		unab root : `root' , max(1)
		conf numeric var `root'
		
		local prefix = substr("`var'", 1, `dot'-1)
		local prefix = lower( cond("`prefix'"=="", "i", "`prefix'") ) // -i.- is default prefix

		Assert inlist("`prefix'", "i", "c") , msg("error parsing <`absvar'><`var'> : only i. and c. allowed, not `prefix'.")
		Assert !strpos("`root'", ".") , msg("error parsing <`absvar'><`var'> : no time series operators allowed")
		
		if ("`prefix'"=="i") {
			local ivars `ivars' `root'
		}
		else {
			Assert "`cvars'"=="", msg("error: can't have more than one continuous variable in the interaction")
			local cvars `cvars' `root'
		}
	}
	local tab  "        "
	Debug, level(3) msg(as text "    Parsing " as result "`original_absvar'")
	Debug, level(3) msg(as text "`tab'ivars = " as result "`ivars'")
	if ("`cvars'"!="") Debug, level(3) msg(as text "`tab'cvars = " as result "`cvars'")
	if ("`target'"!="") Debug, level(3) msg(as text "`tab'target = " as result "`target'")
	Debug, level(3) msg(as text "`tab'is_interaction = " as result "`is_interaction'")
	Debug, level(3) msg(as text "`tab'is_bivariate = " as result "`is_bivariate'")
	// Debug, level(3) newline

	return scalar is_interaction = `is_interaction'
	return scalar is_cont_interaction = `is_interaction' & ("`cvars'"!="")
	return scalar is_bivariate = `is_bivariate'
	if ("`target'"!="") return local target "`target'"
	if ("`cvars'"!="") return local cvars "`cvars'"
	return local ivars "`ivars'"
end


//------------------------------------------------------------------------------
program define Prepare, rclass
//------------------------------------------------------------------------------
syntax, KEEPvars(varlist) [DEPVAR(varname numeric) EXCLUDESELF]

**** AVGE PART ****
mata: st_local("N_avge", strofreal(avge_num))
if (`N_avge'>0) {
	forv g=1/`N_avge' {
		Assert ("`depvar'"!=""), msg("reghdfe_absorb: depvar() required")
		mata: st_local("ivars", avge_ivars[`g'])
		mata: st_local("varlabel", avge_varlabel[`g'])
		mata: st_local("target", avge_target[`g'])
		local W __W`g'__

		local note = cond("`excludeself'"=="",""," (excluding obs. at hand)")
		local original_depvar = cond(substr("`depvar'",1,2)=="__", "`: var label `depvar''", "`depvar'")
		Debug, level(2) msg(" - computing AvgE(`original_depvar') wrt (`varlabel')`note'")

		* Syntax: by ... : AverageOthers varname , Generate(name) EXCLUDESELF
		qui AverageOthers `depvar', by(`ivars') gen(`W') `excludeself'
		char `W'[target] `target'
	}

	* Marked obs should have been previously deleted
	tempvar touse
	mark `touse'
	markout `touse' __W*__
	qui keep if `touse'
	drop `touse'
	local keepvars `keepvars' __W*__
}

	Assert c(N)>0, rc(2000) msg("Empty sample, check for missing values or an always-false if statement")
	Assert c(N)>1, rc(2001)

**** ABSORB PART ****

* Create compact IDs and store them into the __FE1__ (and so on)
* Also structures the IDs in the 1..K sense, which is needed by mata:prepare
* (b/c it uses the largest value of the ID as the number of categories)

	mata: st_local("G", strofreal(G))
	mata: st_local("ivars_clustervar1", ivars_clustervar1)
	local clustervar1 `ivars_clustervar1' // Default if cluster not a FE

	* Get list of cvars to avoid this bug:
	* i.t i.zipcode##c.t -> -t- is missing
	forv g=1/`G' {
		reghdfe_absorb, fe2local(`g') // Dump FEs[g] data into locals
		local all_cvars `all_cvars' `cvars'
	}

	
	forv g=1/`G' {
		reghdfe_absorb, fe2local(`g') // Dump FEs[g] data into locals
		if (`is_mock') continue

		Debug, level(2) msg(" - creating compact IDs for categories of `varlabel' -> " as result "__FE`g'__")

		local ivar_is_cvar : list ivars & all_cvars
		local ivar_is_cvar = ("`ivar_is_cvar'"!="")

		if (`is_interaction' | `ivar_is_cvar') {
			GenerateID `ivars',  gen(`varname')
		}
		else {
			* Can't rename it now b/c it may be used in other absvars
			GenerateID `ivars' , replace
			local rename`g' rename `ivars' `varname'
		}

		local is_cluster 0
		if ("`ivars_clustervar1'"!="") {
			local is_cluster : list ivars_clustervar1 === ivars
			*di in red "`ivars_clustervar1' === `ivars'"
			if (`is_cluster') {
				Debug, level(3) msg(" - clustervar1: " as result "`ivars_clustervar1'" as text " -> " as result "`varname'")
				local clustervar1 `varname'
			}			
		}

		local all_cvars `all_cvars' `cvars'
	}

* Create clustervar if needed
	if (!`is_cluster' & `: word count `ivars_clustervar1''>1) {
		*local clustervar1 = subinstr("`ivars_clustervar1'", " ", "_", .)
		*local clustervar1 : permname `clustervar1'
		local clustervar1 __clustervar1__
		GenerateID `ivars_clustervar1',  gen(`clustervar1')
		// Optional: Use GenerateID even with one ivar; will likely save space
	}

* Rename all absvars into __FE1__ notation
	forv g=1/`G' {
		reghdfe_absorb, fe2local(`g')
		if (`is_mock') continue

		`rename`g''
		qui su __FE`g'__, mean
		local K`g' = r(max)
		Assert `K`g''>0
		local name : char __FE`g'__[name]
		local summarize_fe `"`summarize_fe' as text " `name'=" as result "`K`g''" "'
	}

	return local clustervar1 "`clustervar1'"
	keep __FE*__ `all_cvars' `clustervar1' `keepvars' `fweight'
	Debug, level(1) msg("(number of categories by fixed effect:" `summarize_fe' as text ")") newline

* Fill in auxiliary Mata structures
	Debug, level(2) tic(20)
	mata: prepare()
	Debug, level(2) toc(20) msg("mata:prepare took")
end


//------------------------------------------------------------------------------
cap pr drop program Annihilate
program Annihilate
//------------------------------------------------------------------------------
syntax , VARlist(varlist numeric) ///
	[TOLerance(real 1e-7) MAXITerations(integer 1000) ACCELerate(integer 1) /// See reghdfe.Parse
	CHECK(integer 0) SAVE_fe(integer 0) /// Runs regr of FEs
	NUM_fe(integer -1)] /// Regress only against the first Nth FEs (used in nested Fstats)
	[bad_loop_threshold(integer 1) stuck_threshold(real 5e-3) pause_length(integer 20) ///
	accel_freq(integer 3) accel_start(integer 6)] /// Advanced options

	assert inrange(`tolerance', 1e-20, 1) // However beyond 1e-16 we reach the limits of -double-
	assert inrange(`maxiterations',1,.)
	assert inlist(`accelerate',0,1)
	assert inlist(`check',0,1)
	assert inlist(`save_fe',0,1)
	assert inrange(`num_fe',1,100) | `num_fe'==-1 // -1 ==> Use all FEs

	assert `bad_loop_threshold'>0
	assert `stuck_threshold'>0 & `stuck_threshold'<=1
	assert `pause_length'>=0
	assert `accel_freq'>=0
	assert `accel_start'>0

	* We need to recast everything to -double- (-float- is not good enough)
	Debug, level(2) msg("(recasting variables as -double-)")
	recast double `varlist'

	* We can't save the FEs if there is more than one variable
	cap unab _ : `varlist', max(1)
	Assert (_rc==0 | `save_fe'==0) , rc(`=_rc') ///
		msg("reghdfe_absorb: cannot save FEs of more than one variable at a time")

	tempvar resid
	local save = `save_fe' | `check' // check=1 implies save_fe=1
	local base_args `" "`resid'", `tolerance', `maxiterations', `save', `accelerate', `num_fe'  "'
	local adv_args `" `bad_loop_threshold', `stuck_threshold', `pause_length', `accel_freq', `accel_start' "'
	local args `" `base_args' , `adv_args' "'
	* di in red `"<`args'>"'

	Debug, level(2) tic(30)
	mata: st_local("weightexp", weightexp)
	
	foreach var of varlist `varlist' {
		cap drop __Z*__
		Assert !missing(`var'), msg("reghdfe_absorb: `var' has missing values and cannot be transformed")
		
		* Syntax: MAKE_RESIDUAL(var, newvar, tol, maxiter | , save=0 , accel=1, first_n=`num_fe')
		qui su `var' `weightexp', mean
		local AVG = r(mean)
		mata: make_residual("`var'", `args')
		assert !missing(`resid')

		* Check that coefs are approximately 1
		if (`check') {
			unab _ : __Z*__, min(1)
			local backup = ("`e(cmd)'"!="")
			if (`backup') {
				tempname backup_results
				est store `backup_results', nocopy // nocopy needed to avoid having e(_estimates_name)
			}
			qui _regress `var' __Z*__
			local label : var label `var'
			if ("`label'"=="") local label `var'
			di as text "FE coefficients for `label':{col 36}" _continue
			foreach z of varlist __Z*__ {
				assert !missing(`z')
				di as text " `=string(_b[`z'], "%9.7f")'"  _continue
			}
			di
			
			if (`backup') qui est restore `backup_results'
			if (!`save_fe') cap drop __Z*__
		}

		* If the tol() is not high enough (e.g. 1e-14), we may fail to detect variables collinear with the absorbed categories
		qui su `resid' `weightexp'
		local prettyvar `var'
		if (substr("`var'", 1, 2)=="__") local prettyvar : var label `var'
		if inrange(r(sd), 1e-20 , epsfloat()) di in ye "(warning: variable `prettyvar' is probably collinear, maybe try a tighter tolerance)"

		** Add r(mean) so we don't swipe away the intercept in the main regression
		qui replace `var' = `resid' + `AVG' // This way I keep labels and so on
		drop `resid'
		Assert !missing(`var'), msg("REGHDFE.Annihilate: `var' has missing values after transformation")
	}
	Debug, level(2) toc(30) msg("(timer for calls to mata:make_residual)")
end


//------------------------------------------------------------------------------
program Save, rclass
//------------------------------------------------------------------------------
// Run this after -Annihilate .. , save_fe(1)-
// For each FE, if it has a -target-, add label, chars, and demean or divide
syntax , original_depvar(string)

	mata: st_local("G", strofreal(G))
	mata: st_local("weightexp", weightexp)
	forv g=1/`G' {

		// ivars cvars target varname varlabel is_interaction is_cont_interaction is_bivariate is_mock levels
		reghdfe_absorb, fe2local(`g')
		if ("`target'"=="") continue

		* Rename, add label and chars
		rename __Z`g'__ `target'
		local label `varlabel'
		la var `target' "Fixed effects of `label' on `original_depvar'"
		char `target'[label] `label'
		char `target'[levels] `levels'

		* Substract mean, or divide by cvar (fixing division by zero errors)
		if ("`cvars'"!="" & !(`is_bivariate' & !`is_mock')) {
			char `target'[cvars] `cvars'
			qui replace `target' = cond(abs(`cvars')<epsfloat(), 0,  `target'/`cvars')
			// BUGBUG BUGBUG float(`target'/`cvars')) -> this makes them have the same FE but loses precision!
		}
		else {
			qui su `target' `weightexp', mean
			// qui replace `target' = `target' - r(mean)
			// BUGBUG BUGBUG
		}

		local keepvars `keepvars' `target'
	}

	cap drop __Z*__
	return local keepvars " `keepvars'" // the space prevents MVs
end


//------------------------------------------------------------------------------
program Stop
//------------------------------------------------------------------------------
	cap mata: mata drop prev_numstep // Created at step 1
	cap mata: mata drop VERBOSE // Created before step 1
	cap mata: mata drop G // Num of absorbed FEs
	cap mata: mata drop FEs // Main Mata structure
	cap mata: mata drop betas // Temporary matrices used to store bi/multivariate regr coefs
	cap mata: mata drop varlist_cache // Hash table with the names of the precomputed residuals
	cap mata: mata drop ivars_clustervar1
	cap mata: mata drop avge_* // Drop AvgE structures
	cap mata: mata drop weightexp weightvar

	if ("${reghdfe_pwd}"!="") {
		qui cd "${reghdfe_pwd}"
		global reghdfe_pwd
	}

	* PARALLEL SPECIFIC CLEANUP
	cap mata: st_local("path", parallel_path)
	if ("`path'"!="") {
		mata: st_local("cores", strofreal(parallel_cores))
		assert "`cores'"!=""
		local path "`path'"
		cap erase `"`path'hdfe_mata.mo"'
		forv core=1/`cores' {
			cap erase `"`path'`core'_done.txt"'
			cap erase `"`path'`core'_ok.txt"'
			cap erase `"`path'`core'_error.txt"'
			cap erase `"`path'`core'_output.dta"'
			cap erase `"`path'`core'_log.log"'
		}
		cap rmdir `"`path'"'
		cap mata: mata drop parallel_cores
		cap mata: mata drop parallel_dta
		cap mata: mata drop parallel_vars
		cap mata: mata drop parallel_opt
		cap mata: mata drop parallel_path
	}
end

//------------------------------------------------------------------------------
program ParallelInstance
//------------------------------------------------------------------------------
	syntax, core(integer) code(string asis)
	set more off
	assert inrange(`core',1,32)
	local path "`c(tmpdir)'reghdfe_`code'`c(dirsep)'"
	cd "`path'"
	set processors 1

	file open fh using "`core'_started.txt" , write text all
	file close _all

	cap noi {
		set linesize 120
		log using `core'_log.log, text

		mata: mata matuse "hdfe_mata.mo"
		mata: st_local("cores",strofreal(parallel_cores))
		assert `core' <= `cores'
		mata: st_local("usedta",parallel_dta)
		mata: st_local("vars",parallel_vars[`core'])
		mata: st_local("weightvar",weightvar)
		mata: st_local("opt",parallel_opt)
		Debug, msg(" - This is core `core'/`cores'")
		sleep 100
	
		local outfn "`core'_output.dta"
		conf new file "`outfn'"

		use `vars' `weightvar' using "`usedta'"
		de, full
		reghdfe_absorb, step(demean) varlist(`vars') `opt'
		keep `vars'
		save `"`outfn'"'
		log close _all
	}

	local rc = _rc
	sleep 100

	if `rc'>0 {
		di in red "ERROR: `rc'"
		file open fh using "`core'_error.txt" , write text all
		file close _all
	}
	else {
		file open fh using "`core'_ok.txt" , write text all
		file close _all
	}

	file open fh using "`core'_done.txt" , write text all
	file close _all
	exit, STATA
end

//------------------------------------------------------------------------------
program AnnihilateParallel
//------------------------------------------------------------------------------
// Notes:
// First cluster is taking by this stata instance, to save HDD/memory/merge time
// Also, this cluster should have more obs than the other ones so we let it have
// the default number of processes
// (the other start with 1 proc allowed, which should be fine)
// Thus it will usually finish faster, to start waiting for the 2nd fastest  to merge

syntax, VARlist(varlist numeric) FILEname(string) UID(varname numeric) Numcores(integer) [*]

	local varlist : list uniq varlist
	local K : list sizeof varlist
	local numcores = min(`numcores',`K')
	local size = c(N) * c(width) / 2^30
	local wait = int(100 + 1000 * `size') // each gb wait 1 sec

	* Deal each variable like cards in Poker
	local core 1
	foreach var of local varlist {
		local varlist`core' `varlist`core'' `var'
		local ++core
		if (`core'>`numcores') local core 1
	}

	* Folder name.. need some entropy.. use varlist + time
	mata: st_local("hash", strofreal(hash1("`varlist'"), "%20.0f"))
	local seed = real(subinstr(c(current_time),":","",.)) + `hash'
	local seed = mod(`seed',2^30) // Needs to be < 2^31-1
	set seed `seed'
	local code = string(int( uniform() * 1e6 ), "%08.0f")

	* Prepare
	local path "`c(tmpdir)'reghdfe_`code'`c(dirsep)'"
	Debug, level(1) msg(" - tempdir will be " as input "`path'")
	mata: parallel_cores = `numcores'
	mata: parallel_dta = `"`filename'"'
	mata: parallel_vars = J(`numcores',1,"")
	mata: parallel_vars = J(`numcores',1,"")
	mata: parallel_opt = `"`options'"'
	mata: parallel_path = `"`path'"'
	forv i=1/`numcores' {
		mata: parallel_vars[`i'] = "`varlist`i''"
	}

	local dropvarlist : list varlist - varlist1
	drop `dropvarlist' // basically, keeps UID and clustervar
	mata: st_global("reghdfe_pwd",pwd())
	mkdir "`path'"
	qui cd "`path'"

	local objects VERBOSE G FEs betas prev_numstep parallel_* weightexp weightvar
	qui mata: mata matsave "`path'hdfe_mata.mo" `objects' , replace

	* Call -parallel-
	Debug, level(1) msg(" - running parallel instances")
	qui mata: parallel_setstatadir("")
	local binary `"$PLL_DIR"'
	global PLL_DIR

	cap mata: st_local("VERBOSE",strofreal(VERBOSE))
	if (`VERBOSE'==0) local qui qui
	`qui' di as text _n 44 * "_" + "/ PARALLEL \" + 44 * "_"

	* Create instances
	forv i=2/`numcores' {
		local cmd `"winexec `binary' /q  reghdfe_absorb, instance core(`i') code(`code') "'
		Debug, level(1) msg(" - Executing " in ye `"`cmd' "')
		`cmd'
		Debug, level(1) msg(" - Sleeping `wait'ms")
		if (`i'!=`numcores') sleep `wait'
	}
	reghdfe_absorb, step(demean) varlist(`varlist1') `options' // core=1

	* Wait until all instances have started
	local timeout 20
	local elapsed 0
	forv i=2/`numcores' {
		local ok 0
		while !`ok' {
			sleep 100
			local fn "`path'`i'_started.txt"
			cap conf file "`fn'"
			local rc = _rc
			if (`rc'==0) {
				local ok 1
				Debug, level(1) msg(" - process `i' started")
				erase "`fn'"
			}
			else {
				local elapsed = `elapsed' + 0.1
				Assert `elapsed'<`timeout', msg("Failed to start subprocess `i'")
			}
		}
		local cores `cores' `i' // Will contain remaining cores
	}

	* Wait for termination and merge
	while ("`cores'"!="") {
		foreach core of local cores {
			local donefn "`path'`core'_done.txt"
			local okfn "`path'`core'_ok.txt"
			local errorfn "`path'`core'_error.txt"
			local dtafn "`path'`core'_output.dta"
			local logfile "`path'`core'_log.log"


			cap conf file "`donefn'"
			local rc = _rc

			if (`rc'==0) {
				Debug, level(1) msg(" - process `core' finished")
				erase "`donefn'"

				cap conf file "`okfn'"
				if (`=_rc'>0) {
					type "`logfile'"
					//di as error "<`dtafn'> not found"
					Assert 0, msg("Call to subprocess `core' failed, see logfile")
				}

				erase "`okfn'"
				Debug, level(1) msg(" - Subprocess `core' done")
				local cores : list cores - core
				mata: st_local("VERBOSE",strofreal(VERBOSE))
				
				if (`VERBOSE'>=3) {
					type "`logfile'"
				}
				erase "`logfile'"

				* Merge file
				Debug, level(1) msg(" - Merging dta #`core'")
				merge 1:1 _n using "`dtafn'", nogen nolabel nonotes noreport sorted assert(match)
				erase "`dtafn'"
			}
			else {
				sleep 500 // increase this
			}
		}
	}

	* Cleanup
	qui cd "${reghdfe_pwd}"
	erase "`path'hdfe_mata.mo"
	cap rmdir `"`path'"'
	`qui' di as text 44 * "_" + "\ PARALLEL /" + 44 * "_"

end

//------------------------------------------------------------------------------


// -------------------------------------------------------------
// Faster alternative to -egen group-. MVs, IF, etc not allowed!
// -------------------------------------------------------------
program define GenerateID, sortpreserve
syntax varlist(numeric) , [REPLACE Generate(name)]

	assert ("`replace'"!="") + ("`generate'"!="") == 1
	// replace XOR generate, could also use -opts_exclusive -
	foreach var of varlist `varlist' {
		assert !missing(`var')
	}

	local numvars : word count `varlist'
	if ("`replace'"!="") assert `numvars'==1 // Can't replace more than one var!
	
	// Create ID
	tempvar new_id
	sort `varlist'
	by `varlist': gen long `new_id' = (_n==1)
	qui replace `new_id' = sum(`new_id')
	qui compress `new_id'
	assert !missing(`new_id')
	
	local name = "i." + subinstr("`varlist'", " ", "#i.", .)
	char `new_id'[name] `name'
	la var `new_id' "[ID] `name'"

	// Either replace or generate
	if ("`replace'"!="") {
		drop `varlist'
		rename `new_id' `varlist'
	}
	else {
		rename `new_id' `generate'
	}

end


// -------------------------------------------------------------
// AvgE: Average of all the other obs in a group, except each obs itself
// -------------------------------------------------------------
program AverageOthers , sortpreserve
syntax varname , BY(varlist) Generate(name) [EXCLUDESELF]

* EXCLUDESELF: Excludes obs at hand when computing avg

***[EXCLUDE(varname)]
*** Do not use obs where `exclude'!=0 to compute the means, but do fill out these values

* Alternative:
* MeanOthers = MeanAll * N/(N-1) - X / (N-1) = (SumAll-X)/(N-1)
* Also, using mean() instead of total() would give less rounding errors

	sort `by'

	conf new var `generate'
	***if ("`exclude'"!="") local cond " if !`exclude'"
	
	* Calculate avg by group
	tempvar total count
	qui gen double `generate' = `varlist' `cond'
	
	* Sum
	*qui by `by' : egen double `generate' = mean(`var')
	qui by `by' : gen double `total' = sum(`generate')
	qui by `by' : replace `total' = `total'[_N]
	
	* Count
	qui by `by' : gen double `count' = sum(`generate'<.)
	qui by `by' : replace `count' = `count'[_N]
	
	* Substract itself
	if ("`excludeself'"!="") qui by `by' : replace `total' = `total' - `generate' if (`generate'<.)
	if ("`excludeself'"!="") qui by `by' : replace `count' = `count' - 1 if (`generate'<.)
	
	* Divide
	qui replace `generate' = `total' / `count'
	
	**qui by `by' : replace `generate' = `generate'[_N]
	
	* Adjust negative values b/c of rounding errors introduced by -excludeself- (risky)
	if ("`excludeself'"!="") {
		replace `generate' = 0 if inrange(`generate', -1e-8, 0)
		local note X
	}

	* Add label and chars
	local name = subinstr("`by'", " ", "_", .)
	char `generate'[avge_equation]  AvgE`note'
	char `generate'[name] `name'
	char `generate'[depvar] `varlist'
	la var `generate' "Avg`note'. of `varlist' by `by'"
end


// -------------------------------------------------------------
// Simple assertions
// -------------------------------------------------------------
program define Assert
    syntax anything(everything equalok) [, MSG(string asis) RC(integer 198)]
    if !(`anything') {
        di as error `msg'
        exit `rc'
    }
end


// -------------------------------------------------------------
// Simple debugging
// -------------------------------------------------------------
program define Debug

	syntax, [MSG(string asis) Level(integer 1) NEWline COLOR(string)] [tic(integer 0) toc(integer 0)]
	
	cap mata: st_local("VERBOSE",strofreal(VERBOSE)) // Ugly hack to avoid using a global
	if ("`VERBOSE'"=="") {
		di as result "Mata scalar -VERBOSE- not found, setting VERBOSE=3"
		local VERBOSE 3
		mata: VERBOSE = `VERBOSE'
	}


	assert "`VERBOSE'"!=""
	assert inrange(`level',0, 4)
	assert (`tic'>0) + (`toc'>0)<=1

	if ("`color'"=="") local color text
	assert inlist("`color'", "text", "res", "result", "error", "input")

	if (`VERBOSE'>=`level') {

		if (`tic'>0) {
			timer clear `tic'
			timer on `tic'
		}
		if (`toc'>0) {
			timer off `toc'
			qui timer list `toc'
			local time = r(t`toc')
			if (`time'<10) local time = string(`time'*1000, "%tcss.ss!s")
			else if (`time'<60) local time = string(`time'*1000, "%tcss!s")
			else if (`time'<3600) local time = string(`time'*1000, "%tc+mm!m! SS!s")
			else if (`time'<24*3600) local time = string(`time'*1000, "%tc+hH!h! mm!m! SS!s")
			timer clear `toc'
			local time `" as result " `time'""'
		}

		if (`"`msg'"'!="") di as `color' `msg'`time'
		if ("`newline'"!="") di
	}
end

