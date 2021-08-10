/*
v1.2 11/25/2014 (mean) supports weights. ((sum) doesn't - would need to loop through data twice)
v1.1 11/11/2014 supports missing values in xvars and byvars
v1.0 re-write 10/17/2014 AM
- now uses hash and unhash programs
- much simplified
*/
**********************
* Stata core program *
**********************

cap program drop fastcollapse
program define fastcollapse
version 13.0	// mata selectindex() is new for Stata 13
	
	// parse syntax
	// should begin with (sum) or (mean).. 
	// for now defaulting to (sum) if nothing specified (for backwards compatability) 11/12/2014 (remove in a while)
	gettoken fcn 0 : 0, parse(" ") bind
	if !inlist("`fcn'","(sum)","(mean)") {
		di as text "in the future, please specify (sum) or (mean). (defaulting to sum for now) 11/12/2014 AM"
		local 0 `fcn' `macval(0)'	// put whatever was in fcn back into syntax
		local fcn sum
	}
	else {
		local fcn : subinstr local fcn "(" "", all
		local fcn : subinstr local fcn ")" "", all
	}
	syntax varlist(numeric) [if] [in] [aweight/], by(varlist) [cw replace]
	
	// check for weights (do I need to check for negative vals? non-negative assumed later on)
	if "`exp'" != "" {
		// case 1: aw is a variable: just use the variable as weights
		cap confirm numeric variable `exp'
		if !_rc local aw `exp'
		// case 2: aw is an expression: need to generate a new variable
		else {
			tempvar aw
			gen double `aw' = `exp'
		}
		// treat missing values with 0 weight
		drop if mi(`aw')
	}
		
	// drop vars that will be unused in final dataset
	keep `varlist' `by' `aw'
	if "`if'`in'" != "" qui keep `if' `in'
	
	// casewise option:
	// 1) cw: drop rows with missing xvars
	// 2) no cw: replace with 0 (only for (sum) statistic)
	if "`cw'" == "cw" drop if mi(`: subinstr local varlist " " ",", all')
	else if "`fcn'" == "sum" {	// treat missing values as 0 when computing summary statistics
		qui foreach v of varlist `varlist' {
			replace `v' = 0 if mi(`v')
		}
	}
	
	//
	// Create Hash ID
	//
	tempvar hashid
	hash `by', gen(`hashid') `force' nodrop
	local V : word count `varlist'
	noi di as text "Hash Table rows: "  _col(15) %-15.0gc r(TableSize)
	noi di as text "Hash Table cols: "  _col(15) %-15.0gc `V'
	noi di as text "memory consumption on order of: GB"  _col(15) %-7.5gc (r(TableSize)*`V')*8/10^9
	
	//
	// Collapse by Hash ID
	//
	mata _fastcollapse("`varlist'","`hashid'",(`: char `hashid'[TableSize]'),"`fcn'","`cw'","`aw'")

	// Recover labels and variable formats
	unhash `hashid'
	order `by' `varlist'
		
end


**********************
* mata core function *
**********************

cap mata mata drop _fastcollapse()
mata
void _fastcollapse(	string scalar xvarnames, string scalar hashidname, ///
					real scalar TableSize, string scalar statistic,  ///
					string scalar cw, |string scalar awname) {
	
	// Initializations
	real scalar i, j, V, N, newN
	real vector hashid_act, aw
	real matrix R
	if (statistic=="") statistic = "sum"	// set default to sum for now
	
	// Load data
	xvarlist = tokens(xvarnames)
	st_view(xvars,.,xvarnames)
	st_view(hashid,.,hashidname)
	if (awname!="") st_view(aw,.,awname)	// weights included
	V = cols(xvars)
	N = st_nobs()
		
	// Initialize hash table
	// 	(hashed values are the rows numbers, the means/sums are the contents.
	// 	Cells that are missing in the end will not be saved)
	R = J(TableSize,V,.)	// trick - I'm setting non-existing to missing...
	R[hashid,] = J(N,V,0) 	// ... and existing to zero

	// Key loop
	if (statistic=="sum")		fc_sum(xvars,R,hashid,cw,aw)
	else if (statistic=="mean")	fc_mean(xvars,R,hashid,cw,aw)
	
	// free memory
	hashid 	= .
	xvars 	= .
	
	hashid_act = selectindex(R[,1]:!=.)	// get non-missing indices (ie:
										// relevent hashed values)
	R = R[hashid_act,]
	
	// clear dataset
	st_dropobsin(.)
	st_keepvar((xvarlist,hashidname))
	stata("recast double " + xvarnames)
	
	// Create collapsed dataset
	newN = rows(hashid_act)
	st_addobs(newN,1)
	st_store(.,xvarlist,R)
	st_store(.,hashidname,hashid_act)
	stata("qui compress")
}
end


************************************************
* Internal functions for calculating statistic *
************************************************
// right now: (sum vs mean) * (casewise vs not) * (weights vs none)
/*
note: coded rather lengthily. I could have cut the code in half
and just had aw = 1 in the no weights case, but I've unofficially 
tested having an inner loop with (stuff[i] + aw) where aw = 1 vs (stuff[i] + 1)
and it has seemed faster to not have to dereference aw
*/
mata
stata("cap mata mata drop fc_sum()")
void fc_sum(real matrix xvars, real matrix R, real vector hashid, ///
	string scalar cw,| real vector aw) {

	if (length(aw)!=0) _error("weights not allowed with sum()")
	
	// initializations
	real scalar i, j, v, V, N
	V = cols(xvars)	// number of variables
	N = rows(xvars)	// number of observations
	
	// Casewise/not-casewise same, since missings were filled with 0s
	for (i=1;i<=N;i++) {
		j = hashid[i]
		R[j,] = R[j,] + xvars[i,]
	}
}
stata("cap mata mata drop fc_mean()")
void fc_mean(real matrix xvars, real matrix R, real vector hashid, ///
	string scalar cw,| real vector aw) {

	// initializations
	real scalar i, j, v, V, N, w
	real rowvector wvec
	real matrix ctrs
	V = cols(xvars)	// number of variables
	N = rows(xvars)	// number of observations

	ctrs = J(rows(R),cols(R),0)	// all counters initialized at zero
	
	//
	// no weights
	//
	if (length(aw)==0) {
		// A) not casewise (need to check each variable for missing values)
		//	this is hard for mean. need to have separate counters for each
		//	variable/group determining how many non-missing values have passed
		//	(see help moremata_source##mm_collapse for "mean-update" formula)
		if (cw == "") {
			for (i=1;i<=N;i++) {
				j = hashid[i]
				for (v=1;v<=V;v++) {
					if (xvars[i,v]!=.) {
						ctrs[j,v] = ctrs[j,v]+1
						R[j,v] = R[j,v] + ( xvars[i,v]-R[j,v] ) / ctrs[j,v]
					}
				}
			}
		}
		// B) casewise 
		else if (cw != "") { 
			wvec = J(1,V,1)
			for (i=1;i<=N;i++) {
				j = hashid[i]
				ctrs[j,] = ctrs[j,] + wvec
				R[j,] = R[j,] + ( xvars[i,]-R[j,] ) :/ ctrs[j,]
			}
		}
	}
	//
	// weights
	//
	else if (length(aw)!=0) {
		// A) not casewise (need to check each variable for missing values)
		if (cw == "") {
			for (i=1;i<=N;i++) {
				j = hashid[i]
				for (v=1;v<=V;v++) {
					if (xvars[i,v]!=.) {
						w = aw[i]
						ctrs[j,v] = ctrs[j,v]+w
						R[j,v] = R[j,v] + ( xvars[i,v]-R[j,v] ) * ( w/ctrs[j,v] )
					}
				}
			}
		}
		// B) casewise (no need to check for missing values, due to drop `if' `in')
		else if (cw != "") { 
			for (i=1;i<=N;i++) {
				j = hashid[i]
				wvec = J(1,V,aw[i])
				ctrs[j,] = ctrs[j,] + wvec
				R[j,] = R[j,] + ( xvars[i,]-R[j,] ) :* ( wvec:/ctrs[j,] )
			}
		}
	}
	
}
end
