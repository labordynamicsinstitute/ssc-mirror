*! 1.0.0 NJC 27 February 2025
* lmoments 6.0.0 NJC 3 October 2012 
* 1.0.0 NJC 17 September 1997
* based on lshape v 2.0.1 PR 06Oct95.
program _lmoments, rclass    
	version 10 
	syntax varname(numeric) [if] [in] [, lmax(int 4) ]

	marksample touse

	forval l = 1/`lmax' { 
		local call `call' l_`l' 
	}

	mata: _lmo("`varlist'", "`touse'", "`call'", `lmax')  
  			
    return scalar N = scalar(N)  

	forval l = 1/`lmax' { 
		return scalar l_`l' = scalar(l_`l')
	}
     
	if `lmax' > 1 return scalar t = scalar(l_2) / scalar(l_1)
		
	forval l = 3/`lmax' { 
		return scalar t_`l' = scalar(l_`l') / scalar(l_2) 
	} 
end

mata : 

real matrix bweights (real scalar n, real scalar k) { 
	return(editmissing(comb((0::n-1), (0..k-1)) :/ comb(n-1, (0..k-1)), 0))  
} 	

real matrix pweights(real scalar k) { 
	real matrix w
	real scalar i, j  
	w = J(k, k, .) 

	for(i = 0; i < k; i++) { 
		for(j = 0; j < k; j++) {
			w[i+1,j+1] = (-1)^(j-i) * exp(lnfactorial(j+i) - 2 * lnfactorial(i) - lnfactorial(j-i)) 
		}
	}

	return(editmissing(w, 0))
} 

real matrix lmocoeff(real scalar n, real scalar k) { 
	return(bweights(n, k) * pweights(k)) 
}

void _lmo(
string scalar varname, 
string scalar usename, 
string scalar lnames,  
real scalar lmax
) 
{ 
	real colvector x, result    
	real scalar n, j   

	x = st_data(., varname, usename) 
	n = length(x) 
	
	st_numscalar("N", n)  
	if (n == 0) return 

	_sort(x, 1)
	result = lmocoeff(n, lmax)' * x / n

	lnames = tokens(lnames) 
	for (j = 1; j <= length(lnames); j++) { 
		st_numscalar(lnames[j], result'[j])
	}
}

end

