*! 1.0.0 NJC 1 March 2025 
program lmomentsets 
	version 10 
	
	capture syntax varname(numeric) [if] [in] ///
	, OVER(varname) [ lmax(int 4)) Total SAVING(str asis) * ]   
	
	if _rc == 0  { 
		lmomentsets_g `0'
		exit 0  
	}
	
	syntax varlist(numeric) [if] [in] ///
	[, SAVING(str asis) lmax(int 4)  ALLobs inclusive cw * ]   
	
	if "`allobs'`inclusive'`cw'" != "" marksample touse, novarlist 
	else marksample touse 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse'

	if `"`saving'"' == "" {
		tempfile saving 
		local wantsave 0  
	}
	else local wantsave 1 
	
	forval k = 1/`lmax' {
		local call1 `call1' l_`k'
		local call2 `call2' (r(l_`k'))
		if `k'== 2 { 
			local call1 `call1' t
			local call2 `call2' (r(t))
		}
		else if `k' >= 3 {
			local call1 `call1' t_`k'
			local call2 `call2' (r(t_`k'))
		}
	}
	
	tempname handle 
	postfile `handle' str32 varname str80 varlabel n `call1' using `saving'
	
	quietly foreach v of local varlist {
	    local varlabel : var label `v'
		if `"`varlabel'"' == "" local varlabel "`v'"
		_lmoments `v', lmax(`lmax')
		post `handle' ("`v'") ("`varlabel'") (r(N)) `call2'
	}
	
	postclose `handle'
	
	gettoken filename rest : saving, parse(,) 
	use "`filename'", clear 
	
	list, noobs `options'
	
	if `wantsave' {
		quietly compress
		display  
		save "`filename'", replace
	} 
end 

program lmomentsets_g                                                        
	syntax varname(numeric) [if] [in]             ///
	, OVER(varname) [ SAVING(str asis) lmax(int 4) Total  * ]   

	marksample touse  
	markout `touse' `over', strok 
	
	quietly count if `touse'
	if r(N) == 0 error 2000
	if r(N) == 1 error 2001 
	
	preserve 
	quietly keep if `touse' 
	
	local varlabel : variable label `varlist'
	local gvarlabel : variable label `over' 
	
	quietly statsby , by(`over') clear `total' : ///
	_lmoments `varlist', lmax(`lmax')
	
	quietly egen group = group(`over'), label 
	_crcslbl group `over'

	quietly if "`total'" != "" { 
		su group, meanonly 
		local gmax = r(max) + 1 
		replace group = `gmax' if group == . 
		label def group `gmax' "Total", modify 
	}
	
	rename `over' origgvar  
	rename N n  
	
	gen varname = "`varlist'"
	gen varlabel = cond(missing("`varlabel'"), varname, "`varlabel'")
	gen groupvar = "`over'"
	gen gvarlabel = cond(missing("`gvarlabel'"), groupvar, "`gvarlabel'")

	foreach v in n {
		label var `v' 
	}
	
	forval k = 1/`lmax' {
		local call `call' l_`k'
		if `k'== 2 	local call `call' t 
		else if `k' >= 3 local call `call' t_`k'
	
	}
	
	foreach v of local call { 
		label var `v'
	}
	
	order varname varlabel origgvar groupvar gvarlabel group n `call'
	
	list, noobs `options'

	if `"`saving'"' != "" { 
		quietly compress 
		display 
		save `saving'
	}
end 

* the following code needs to be in a separate ado, 
* but is included here for documentation 

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

