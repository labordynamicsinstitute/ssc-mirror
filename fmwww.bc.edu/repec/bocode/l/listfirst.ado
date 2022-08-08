*! 2.0.0 NJC 6 August 2022 
* 1.0.0 NJC 10 April 2008
program listfirst 
	version 8.2 
	syntax [varlist(def=all)] [if/] ///
	[, First(numlist int >0) LAST LAST2(numlist int >0) Header * ] 

	quietly {
		tempvar OK 
		if `"`if'"' == "" local if 1 
		gen byte `OK' = `if'
		replace `OK' = cond(`OK', sum(`OK'), 0) 
	}

	if "`first'" == "" local max = 10
	else local max = `first'   
	list `varlist' if inrange(`OK', 1, `max'), `options' 
	
	if "`last'`last2'" != "" & `OK'[_N]  {
		local last = cond("`last2'" == "", "10", "`last2'") 
		su `OK', meanonly
		local min = r(max) - `last' + 1
		local min = max(1, `min')  
		local max = r(max) 
		if "`header'" != "" list `varlist' if inrange(`OK', `min', `max'), `header' `options'
		else list `varlist' if inrange(`OK', `min', `max'), noheader `options' 
	}   
	
end 	

