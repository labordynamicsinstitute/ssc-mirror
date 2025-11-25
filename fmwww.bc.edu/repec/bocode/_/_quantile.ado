* 1.0.0 NJC 17 November 2025
program _quantile, rclass    
	version 19.50
	syntax varname(numeric) [if] [in] , Prob(str) Method(str)

	marksample touse

	local nq : word count `prob'
	forval q = 1/`nq' { 
		local call `call' q`q' 
	}

	mata: _qua("`varlist'", "`touse'", "`call'", "`prob'", "`method'")  
  			
    return scalar n = scalar(n)  

	forval q = 1/`nq' { 
		return scalar q`q' = scalar(q`q')
	}
end

mata : 

void _qua(
string scalar varname, 
string scalar usename, 
string scalar qnames,  
string scalar p,
string scalar method
) 
{ 
	real colvector x, results    
	real scalar n, j   

	x = st_data(., varname, usename) 
	n = length(x) 
	
	st_numscalar("n", n)  
	if (n == 0) return 

	results = quantile(x, strtoreal(tokens(p))', method) 
	qnames = tokens(qnames) 

	for (j = 1; j <= length(qnames); j++) { 
		st_numscalar(qnames[j], results'[j])
	}
}

end

