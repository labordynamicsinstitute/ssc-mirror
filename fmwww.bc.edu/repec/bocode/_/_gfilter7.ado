* renamed 5 Dec 2003
*! 1.0.1 NJC 26 June 2001 
* promoted to 7 to avoid problems with -normali?e- 
* 1.0.0 NJC 25 January 2000 aided and abetted by CFB  
program define _gfilter7 
        version 7.0
	qui tsset /* error if not set as time series */ 
	
	gettoken type 0 : 0 
	gettoken g 0 : 0 
	gettoken eqs 0 : 0 
	syntax varname [if] [in] , Lags(numlist int min=1) /* 
	*/ Coef(numlist min=1) [ Normalise Normalize ]

	local ncoef : word count `coef' 
	local nlags : word count `lags' 
	if `nlags' != `ncoef' { 
		di in r "lags( ) and coef( ) not consistent" 
		exit 198 
	}	

	marksample touse
	tokenize `coef'
	
	local norm = "`normalise'`normalize'" != "" 
	if `norm' { 
		local i = 1
		local total = 0 
		while `i' <= `ncoef' { 
			local total = `total' + (``i'')  
			local i = `i' + 1
		} 
		local i = 1 
		while `i' <= `ncoef' { 
			local `i' = ``i'' / `total' 
			local i = `i' + 1
		} 
	} 	
	
	local rhs "0" 

	local i = 1 
	while `i' <= `nlags' { 
		local l : word `i' of `lags' 
		local L = -`l'
		local op = cond(`l' < 0, "F`L'.", "L`l'.") 
		local rhs "`rhs' + (``i'') * `op'.`varlist'" 
		local i = `i' + 1
	} 	
	
	qui gen `type' `g' = `rhs' if `touse' 
end
