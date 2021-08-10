* v1.0 10/30/2014 Andrew Maurer
/*
To do:
	- dataframe save (to valid dta file) (ie equiv to save with IF/IN)
	- dataframe list
	- dataframe restore IF/IN
	- align dataframe restore behavior with "use"
		- 	what to do if there's an empty dataset, but there are 
			dataset characteristics, value labels, mata objects, etc?
	- add support for variable and dataset characteristics
*/

program define dataframe
version 12.0
gettoken call 0 : 0
	/*
	Outline:
	dataframe is a wrapper for filling and taking data from the dataframe()
	struct in mata. dataframe() is designed/intended to hold all information
	of a Stata dataset in a single mata object.
	*/

	*********
	* store *
	*********
	if `"`=trim("`call'")'"' == "store" {
		// Syntax 1: all data
		cap syntax name(name=name)
		if _rc {
			// Syntax 2: subset of data
			syntax varlist [if] [in], name(name)
			if "`if'`in'" != "" marksample touse, novarlist	// don't marksample if 
															// [if] or [in] weren't specified
															// (more efficient) this way
		}
		if "`varlist'" == "" unab varlist : _all
		// Work
		mata `name' = df_store("`touse'","`varlist'")
	}

	***********
	* restore *
	***********
	else if `"`=trim("`call'")'"' == "restore" {
		syntax name(name=name), [nodrop clear]
		if "`clear'" == "clear" clear
		mata df_restore(`name')
		if "`drop'" != "nodrop" mata mata drop `name' // drop the dataframe
	}
	
	// else syntax error
	else error 198
	
end

******************
* mata structure *
******************
mata
struct dataframe {
	real scalar		K, N 
	string vector 	varnames
	string vector 	varlabels
	string vector 	vartypes
	string vector 	varformats
	string vector 	varvaluelabels
	string vector 	varcharacteristics
	real matrix		data_num
	string matrix	data_str
	struct vallabelstruct scalar	vallabels
}
struct vallabelstruct {	// stores all value label information
	real scalar						L
	string vector					names
	pointer(real vector) vector		text
	pointer(string vector) vector	vals
}
end

***********************
* core mata functions *
***********************
mata
struct dataframe scalar df_store(string scalar touse, string scalar varlist) {
	/*
	touse may be set to "" for all observations
	*/

	// Declarations
	real scalar					i
	real vector					allnum, allstr	// variable indexes of numeric and string variables
	struct dataframe scalar		X
	string vector 				vallabnames
	pointer(real vector)		vallabel_vals	// temp object -> X.vallabels.vals
	pointer(string vector)		vallabel_text	// temp object -> X.vallabels.text

	// Get variable indexes and separate by string/numeric
	allv = st_varindex(X.varnames=tokens(varlist))
	X.K = length(allv)
	for (i=1;i<=X.K;i++) if (st_isnumvar(allv[i])==1) allnum = allnum, allv[i]; else allstr = allstr, allv[i];
	
	// Populate dataframe
	if (allnum != J(1,0,.)) X.data_num = st_data(.,allnum,touse)
	if (allstr != J(1,0,.)) X.data_str = st_sdata(.,allstr,touse)
	X.N = max((rows(X.data_num),rows(X.data_str)))

	// Data attributes (variable 1) labels, 2) types, 3) formats, 4) val labels)
	X.varlabels = X.vartypes = X.varformats = X.varvaluelabels = J(1,X.K,"a")
	for (i=1;i<=X.K;i++) {
		X.varlabels[i]	= st_varlabel(allv[i])
		X.vartypes[i]	= st_vartype(allv[i])
		X.varformats[i]	= st_varformat(allv[i])
		X.varvaluelabels[i]	= st_varvaluelabel(allv[i])
	}

	// Value labels
	/*
	This works, but isn't very efficient. Requires function vlload_labels()
		Stores:
			1) value label names
			2) A pointer vector to value label values
			2) A pointer vector to value label texts
	The problem is trying to get the value label text and values 
	into the pointer elements of the structure directly through st_vlload().
	Is there working syntax like:
		st_vlload(X.vallabels.names[i],&X.vallabels.vals,&X.vallabels.text)
	*/
	stata("qui label dir")	// can't list labels from mata directly?
	X.vallabels.names = tokens(st_global("r(names)"))
	X.vallabels.L = length(X.vallabels.names)
	vallabel_vals = J(1,X.vallabels.L,NULL)
	vallabel_text = J(1,X.vallabels.L,NULL)
	for (i=1;i<=X.vallabels.L;i++) {
		vallabel_vals[1,i] = &vlload_labels(X.vallabels.names[i],"vals")
		vallabel_text[1,i] = &vlload_labels(X.vallabels.names[i],"text")
	}
	X.vallabels.vals = vallabel_vals
	X.vallabels.text = vallabel_text
		
	return(X)

}
end

mata
void df_restore(struct dataframe scalar X) {
	
	// Check for clear dataset
	if (st_nobs()!=0 | st_nvar()!=0) _error("no; data in memory would be lost")
	
	// populate dataset
	is = in = 0 // counters for numeric and string variable indexes
				// (focus on retaining original variable order)
	st_addobs(X.N,1)
	for (i=1;i<=X.K;i++) {
		id = st_addvar(X.vartypes[i],X.varnames[i])
		st_varformat(X.varnames[i],X.varformats[i])
		st_varlabel(X.varnames[i],X.varlabels[i])
		if (X.varvaluelabels[i]!= "") {
			st_varvaluelabel(X.varnames[i],X.varvaluelabels[i])
		}
		if(st_isnumfmt(X.varformats[i])) { // numeric variable
			st_store(.,id,(X.data_num[.,++in]))
		}
		else { // string variable
			st_sstore(.,id,X.data_str[.,++is])
		}
	}
	
	// restore value labels
	for (i=1;i<=X.vallabels.L;i++) {
		if (st_vlexists(X.vallabels.names[i])) st_vldrop(X.vallabels.names[i])
		st_vlmodify(X.vallabels.names[i],*X.vallabels.vals[i],*X.vallabels.text[i])
	}
	
}
end


******************
* mata utilities *
******************
mata
matrix vlload_labels(labname, valsvstext) {
	/*
	Wrapper for st_vlload() to return the values or text
	associated with a value label
	-	required for dataframe, since the values and text need to be pointed
		to from the vallabelstruct struct. I can't figure out how to do this 
		directly with vlload(). not possible?
	*/
		
	// Declarations
	real colvector 		vlload_vals
	string colvector	vlload_text

	st_vlload(labname, vlload_vals, vlload_text)
	if (valsvstext == "vals") return(vlload_vals)
	else if (valsvstext == "text") return(vlload_text)
	else _error(`"must specify "vals" or "text""')
}
end

exit



***********
* Example *
***********
/*
set obs 10
gen x:mytest = 5*runiform()
gen y = 5*runiform()
gen z = string(floor(500*runiform()))
label var z "this labz"
label define mytest 1 "asd" 2 "asd321"
label define opps 1 "a123sd" 2 "a1sd321"
label var x "this is amsdf"
gen app = "apple" in 8/9

unab varlist : _all
local varlist x z
//mata X = df_store("","`varlist'")
df_store x y app in 6/10, name(X)
mata liststruct(X)

clear

df_restore X

exit

*/
