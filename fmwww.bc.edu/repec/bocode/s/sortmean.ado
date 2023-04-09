*! 1.2.0 NJC 1 April 2023 
*! 1.1.0 NJC 30 March 2023 
*! 1.0.0 NJC 29 March 2023 
program sortmean 
	// invtokens() introduced in Stata 10 
	version 10
	
	syntax [varlist] [if] [in] [fweight aweight] [, ALLOBS DESCending local(str) ] 
	
	quietly {
		ds `varlist', has(type numeric)  
		local varlist "`r(varlist)'"

		if "`varlist'" == "" error 102 
		
		if "`allobs'" != "" { 
			marksample touse, novarlist 
		}
		else marksample touse 

		count if `touse'
		if r(N) == 0 error 2000

		local direction = cond("`descending'" != "", -1, 1) 
		local macname = cond("`local'" != "", "`local'", "sortlist") 

		if "`weight'" != "" { 
			tempvar wt 
			gen double `wt' `exp' 
		}
		else local wt `touse' 
	}

	mata: _sortmean("`varlist'", "`touse'", `direction', "`macname'", "`wt'") 

	di "``macname''"
	c_local `macname' ``macname'' 
end 

mata 

void _sortmean(string vector varnames,
               string scalar tousename, 
               real scalar direction, 
	       string scalar macname, 
	       string scalar wtname) {

	real matrix data 
	real vector means, include 
	real scalar mean 
	string vector names 
	st_view(data = ., ., varnames, tousename)
	st_view(weights = ., ., wtname, tousename) 

	if (missing(data) > 0) {
		means = J(1, 0, .)
		
		for(j = 1; j <= cols(data); j++) {
			include = data[,j] :< .  
			mean = quadcolsum(data[,j] :* weights :* include) 
			mean = mean :/ quadcolsum(weights :* include) 
			means = means, mean
		}

		means = means' 
	}
	else means = mean(data, weights)' 

	names = tokens(varnames)' 
	names = names[order(means, direction)]
	st_local(macname, invtokens(names'))  
}
 
end 

