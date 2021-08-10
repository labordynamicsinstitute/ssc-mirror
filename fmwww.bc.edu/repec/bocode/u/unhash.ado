/*
v1.3 (corresponding to updated hash.ado) 11/24/2015
v1.2 modified to support missing values in by vars and x vars 11/11/2014
v1.0 AM 10/17/2014
*/

cap program drop unhash
program define unhash
version 12.0
syntax varname, [nodrop]
	
	/*
	Example hash table mapping :
		gen byte product_class = mod( floor(hashid/2754000),4 )+1
		gen byte product = mod( floor(hashid/76500),36 )+1 
		gen int asof_dtem = mod( floor(hashid/750),102 )+543
		gen int orig_dtem =  mod( hashid,750 )-105-1
	*/
	
	local hashid `varlist'
	
	local varlist : char `hashid'[varlist]
	local V : word count `varlist'
	foreach char in mins maxs ranges cumulative_prods hasmises vlabs vformats vtypes vvallabs {
		local `char' : char `hashid'[`char']
		if "`: word count ``char'''" != "`V'" mata _error("word count in `char' bad. invalid hashing")
	}
	
	// Recover all variables from the hashid
	qui forval v = 1/`V' {
		local vname : word `v' of `varlist'
			
		// variable specifications
		local min 				: word `v' of `mins'
		local max 				: word `v' of `maxs'
		local range 			: word `v' of `ranges'
		local cumulative_prod 	: word `v' of `cumulative_prods'
		local hasmis 			: word `v' of `hasmises'
		local vlab 				: word `v' of `vlabs'
		local vformat 			: word `v' of `vformats'
		local vtype 			: word `v' of `vtypes'
		local vvallab 			: word `v' of `vvallabs'
						
		// Generate variable
		local val (mod( floor((`hashid'-1)/`cumulative_prod'), `range' ) + `min')
		if !`hasmis' 		gen `vtype' `vname' = `val'
		else if `hasmis' 	gen `vtype' `vname' = cond(`val'<=`max',`val',.)
		format 		`vname' `vformat'
		label var 	`vname' `"`vlab'"'
		
		// Label if needed
		if "`vvallab'" != "" label values `vname' `vvallab'
	}
	// complicated last bit - restore characteristics for original variables
	mata _restorechars("`hashid'")
	
	if "drop" != "nodrop" drop `hashid'
	
end

cap mata mata drop _restorechars()
mata
void function _restorechars(string scalar hostvar) {
	
	// Setup
	vars = tokens(st_global(hostvar+"[storedcharV]"))
	V = length(vars)
	
	// Loop through variables
	for (v=1;v<=V;v++) {
		
		// recover list of variable's characteristics
		vs = strofreal(v)
		innerlist = tokens(st_global(hostvar+"[var"+vs+"charlist]"))
		if (innerlist == `""') innerlist = J(0,0,"") // override for null list
		J = length(innerlist)
		
		// Loop through characteristics of variable i
		for (j=1;j<=J;j++) {
			// restore the individual characteristic from var[v]char[j]
			js = strofreal(j)
			charval = st_global(hostvar+"[var"+vs+"char"+js+"]")
			st_global(vars[v]+"["+innerlist[j]+"]",charval)
			// uncomment below to remove chars from hostvar debugging line
			st_global(hostvar+"[var"+vs+"char"+js+"]","") 
		}
	}
}
end

exit

/*
//mata version of unhash:
mata
real vector unhash(real vector hash, real matrix info, real vector vid) {
	/*
	input:	hash: vector created by hash
			info: r(info) matrix created by hash
			vid: the relevent row of the info matrix
	output:	the unhashed variable corresponding to vid
	*/
		
	// Initialization
	real scalar	minv, maxV, rangev, cumulative_prodv, hasmisv
	real vector D
	
	minv			 = info[vid,1]
	maxv 			 = info[vid,2]
	rangev 			 = info[vid,3]
	cumulative_prodv = info[vid,4]
	hasmisv 		 = info[vid,5]
	if (!hasmisv) {
		return((mod( floor((hash:-1)/cumulative_prodv), rangev ) :+ minv))
	}
	else if (hasmisv) {
		D = (mod( floor((hash:-1)/cumulative_prodv), rangev ) :+ minv)
		_editvalue(D,maxv+1,.)
		return(D)
	}
}
end
*/














