*! 1.0.0 NJC 29 April 2022 
program nicelabels           
	/// step() undocumented 
	version 9

 	gettoken first 0 : 0, parse(" ,")  

	capture confirm numeric variable `first' 

	if _rc == 0 {
		// syntax varname(numeric), Local(str) [ nvals(int 5) tight step(str)] 

		syntax [if] [in] , Local(str) [ nvals(int 5) tight step(str) ] 
		local varlist `first'  

		marksample touse 
		quietly count if `touse' 	
		if r(N) == 0 exit 2000 
	} 
	else { 
		// syntax #1 #2 , Local(str) [ nvals(int 5) tight step(str) ] 

		confirm number `first' 
		gettoken second 0 : 0, parse(" ,") 
		syntax , Local(str) [ nvals(int 5) tight step(str) ]
 
		if _N < 2 { 
			preserve 
			quietly set obs 2 
		}
	
		tempvar varlist touse 
		gen double `varlist' = cond(_n == 1, `first', `second') 
		gen byte `touse' = _n <= 2 
	}	

	local tight = "`tight'" == "tight"
	su `varlist' if `touse', meanonly
	mata: nicelabels(`r(min)', `r(max)', `nvals', `tight') 

	di "step:{col 12}`interval'"
	di "labels:{col 12}`results'"
	c_local `local' "`results'"
	if "`step'" != "" c_local `step' "`interval'" 
end  

mata : 

void nicelabels(real min, real max, real nvals, real tight) { 
	if (min == max) {
		st_local("results", min) 
		exit(0) 
	}

	real range, d, newmin, newmax
	colvector nicevals 
	range = nicenum(max - min, 0) 
	d = nicenum(range / (nvals - 1), 1)
	newmin = tight == 0 ? d * floor(min / d) : d * ceil(min / d)
	newmax = tight == 0 ? d * ceil(max / d) : d * floor(max / d)  
	nvals = 1 + (newmax - newmin) / d 
	nicevals = newmin :+ (0 :: nvals - 1) :* d  
	st_local("interval", strofreal(d)) 
	st_local("results", invtokens(strofreal(nicevals')))   
}

real nicenum(real x, real round) { 
	real expt, f, nf 
	
	expt = floor(log10(x)) 
	f = x / (10^expt) 
	
	if (round) { 
		if (f < 1.5) nf = 1 
		else if (f < 3) nf = 2
		else if (f < 7) nf = 5
		else nf = 10 
	}
	else { 
		if (f <= 1) nf = 1 
		else if (f <= 2) nf = 2 
		else if (f <= 5) nf = 5 
		else nf = 10 
	}

	return(nf * 10^expt)
}

end 


