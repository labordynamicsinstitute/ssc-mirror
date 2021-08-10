/*
v1.3 bug fix - display format of cumulative_prods changed to %15.0g to 
	 ensure that exact integer is recorded (issue for large values of hashid) 
	 11/24/2014
v1.2 modified to support missing values in by vars and x vars 11/11/2014
v1.1 characteristics stored with hash var 10/20/2014
v1.0 initial commit AM 10/17/2014
*/
cap program drop hash
program define hash, rclass
version 12.0
syntax varlist [if] [in], [gen(name) replace nodrop]
	/*
	2 Syntaxes:
		1)	Typical: For self-contained hashing. Specify gen(varname) to 
			generate the hash variable. You can later use unhash to
			recreate the original variables
		2) 	Advanced: Use the info matrix from r-class results, r(info) along
			with r(hasheqn) and r(TableSize). This information may be used
			to perform hashing later on
	*/
	/*
	Output:
		1) info matrix			(V rows x 4 cols)
		2) TableSize local		(integer)
		3) hasheqn local		(string)
		4) if nogen not specified, variable hashid
	Store all output as variable characteristics on hashid (6 objects)
		hashid[varlist]
		hashid[mins]
		hashid[maxs]
		hashid[ranges]
		hashid[cumulative_prods]
		hashid[hasheqn]
	Store all variable metadata (4 objects)
		hashid[vlabs]
		hashid[vformats]
		hashid[vtypes]
		hashid[vvallabs]
	*/	
	
	tempname info
	
	// verify syntax
	if "`gen'" == "" & "`replace'" == "replace" {
		di as error "replace may not be specified without gen"
		error 10
	}

	// Write info matrix with min/max/range/"cumulative product"/"has missing" for each by variable
	local V : word count `varlist'
	mat `info' = J(`V',5,.)
	mat rownames `info' = `varlist'
	qui foreach vname of varlist `varlist' {
		sum `vname', meanonly
		// check validity of datatypes and for missing values
		if r(N) != _N {
			noi di as text "note: `vname' has missing values"
			local hasmis = (r(N) != _N) 
		}
		else local hasmis = 0
		if !inlist("`: type `vname''","byte","int","long") {
			noi di as error "`vname' is not of type byte, int, or long, which is necessary for hash"
			error 10
		}
		matrix `info'[rownumb(`info',"`vname'"), 1] = r(min)
		matrix `info'[rownumb(`info',"`vname'"), 2] = r(max)
		matrix `info'[rownumb(`info',"`vname'"), 3] = (r(max)-r(min))+1+`hasmis' // col3 = range
		matrix `info'[rownumb(`info',"`vname'"), 5] = `hasmis' // col4 = hasmissing 
	}
	// Cumulative product of ranges
	// 	- create in 4th column of info matrix
	mat `info'[`V',4] = 1
	forval i = `=`V'-1'(-1)1 {
		mat `info'[`i',4] = `info'[`=`i'+1',4]*`info'[`=`i'+1',3]
	}

	// Get hashed id of each observation (tree method)
	// format will be 6*(c+offset-1) + 2*(p+offset-1) + d
	forval v = 1/`V' {
		local vname 	: word `v' of `varlist'
		local offset	= `info'[rownumb(`info',"`vname'"),1]
		local pref 		= `info'[rownumb(`info',"`vname'"),4]
		local hasmis	= `info'[rownumb(`info',"`vname'"),5]
		// special treatment for missing values
		//local hasheqn 	`hasheqn' `pref'*(`vname'-`offset') + 
		if `hasmis' {
			local maxvalp1 = `info'[rownumb(`info',"`vname'"),2]+1
			local vname cond(!mi(`vname'),`vname',`maxvalp1')
		}
		local hasheqn 	`hasheqn' `pref'*(`vname'-`offset') + 
		
	}
	// need to add one to hashid because of the minimum value being 0
	// (can't reference the 0th element of a vector)
	local hasheqn `hasheqn' 1
	local TableSize = `info'[1,3] * `info'[1,4] // equivalent to product of all ranges
	
	// Display results
	if "`trace'" == "trace" {
		noi di as text _n `"hasheqn:	`hasheqn'"' _n
		noi di as text "TableSize:	" %15.0fc `TableSize'
	}
	
	// The maximum matrix size in mata is ~2.148billion. Check that this is not violated
	if `TableSize' > 2.148*10^9 mata _error("Dimensionality exceeds 2.148billion")
	
	//
	// Syntax 1
	//
	qui if "`gen'" != "" {
		// Get hash info metadata
		mata st_local("mins",invtokens(strofreal(st_matrix("`info'")[.,1])'))
		mata st_local("maxs",invtokens(strofreal(st_matrix("`info'")[.,2])'))
		mata st_local("ranges",invtokens(strofreal(st_matrix("`info'")[.,3])'))
		mata st_local("cumulative_prods",invtokens(strofreal(st_matrix("`info'")[.,4],"%15.0g")'))
		mata st_local("hasmises",invtokens(strofreal(st_matrix("`info'")[.,5])'))
		// Get variable metadata
		foreach v of varlist `varlist' {
			local `v'lab 		: variable label `v'
			local `v'format 	: format `v'
			local `v'type 		: type `v'
			local `v'vallabel 	: value label `v'
			
			// store to lists
			local vlabs		"`vlabs' `"``v'lab'"'"
			local vformats 	"`vformats' `"``v'format'"'"
			local vtypes 	"`vtypes' `"``v'type'"'"
			local vvallabs 	"`vvallabs' `"``v'vallabel'"'"
		}
		// Store hash info as characteristics on the hash variable
		if "`replace'" != "" cap drop `gen'
		gen long `gen' = `hasheqn' `if' `in'
		char define `gen'[varlist]			`"`varlist'"'
		char define `gen'[mins]				`"`mins'"'
		char define `gen'[maxs]				`"`maxs'"'
		char define `gen'[ranges]			`"`ranges'"'
		char define `gen'[cumulative_prods]	`"`cumulative_prods'"'
		char define `gen'[hasmises]			`"`hasmises'"'
		char define `gen'[hasheqn]			`"`hasheqn'"'
		char define `gen'[vlabs]			`"`vlabs'"'
		char define `gen'[vformats] 		`"`vformats'"'
		char define `gen'[vtypes]			`"`vtypes'"'
		char define `gen'[vvallabs]			`"`vvallabs'"'
		char define `gen'[TableSize]		`TableSize'
		// complicated last bit - store characteristics from original variables
		mata _storechars("`gen'","`varlist'")
		if "`drop'" != "nodrop" drop `varlist'
	}
	//
	// Syntax 2
	//
	return matrix info = `info'
	return local hasheqn = `"`hasheqn'"'
	return scalar TableSize = `TableSize'
	
end


// mata utility
cap mata mata drop _storechars()
mata
void function _storechars(string scalar hostvar, string scalar varlist) {
	
	// Setup
	vars = tokens(varlist)
	V = length(vars)
	
	// Store char for how many chars are being saved
	st_global(hostvar+"[storedcharV]",varlist) 	
	
	// Loop through variables
	for (v=1;v<=V;v++) {
		
		// store list of variable's characteristics
		vs = strofreal(v)
		innerlist = st_dir("char",vars[v],"*")
		J = length(innerlist)
		
		if (J==0) st_global(hostvar+"[var"+vs+"charlist]",`""""') 
		else st_global(hostvar+"[var"+vs+"charlist]",invtokens(innerlist')) 
		
		// Loop through characteristics of variable i
		for (j=1;j<=J;j++) {
			// store the individual characteristic as var[v]char[j]
			js = strofreal(j)
			vars[v]+"["+innerlist[j]+"]"
			charval = st_global(vars[v]+"["+innerlist[j]+"]")
			st_global(hostvar+"[var"+vs+"char"+js+"]",charval)
			st_global(vars[v]+"["+innerlist[j]+"]","") // debugging line
		}
	}
}
end
