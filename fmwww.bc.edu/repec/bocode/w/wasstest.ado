*! 1.0.0 Ariel Linden 22Dec2025 

program define wasstest, rclass
	version 11.0
    
	syntax varname(numeric) [if] [in], BY(varname) ///
		[Reps(integer 1000) SEED(string) Power(real 1)]
    
	marksample touse
	markout `touse' `by'
	local depvar `varlist'
    
	// check groups
	tempname byvals
	qui levelsof `by' if `touse', local(`byvals')
	local num_groups : word count ``byvals''
	if `num_groups' != 2 {
		di as error "by() variable must have exactly 2 distinct values"
		exit 420
	}
    
	local group1 : word 1 of ``byvals''
	local group2 : word 2 of ``byvals''
    
	// set seed
	if "`seed'" != "" set seed `seed'
	local inis `=c(seed)'
    
	// run test
	mata: wass_main("`depvar'", "`by'", "`touse'", `reps', `power')
    
	// display results
	di _n "Two-sample Wasserstein Distance test for equality of distribution functions"
	di "{hline 75}"	
	di "Outcome:  `depvar'"
	di "Groups:   `by' (`group1' vs `group2')"
	di "{hline 25}"
	di "Test Statistic:  " %6.4f r(stat)
	di "{it:P}-value:         " %6.4f r(p) " (based on `reps' permutations)"	
    
	// save values
	return scalar stat = r(stat)
	return scalar p = r(p)
	return scalar reps = `reps'
	return scalar power = `power'
	return local group1 = "`group1'"
	return local group2 = "`group2'"

end

version 11.0
mata:
mata clear

void wass_main(yvar, byvar, touse, reps, power) {
	st_view(y=., ., yvar, touse)
	st_view(g=., ., byvar, touse)
    
	// clean data
	nonmiss = (y :!= . :& g :!= .)
	y = select(y, nonmiss)
	g = select(g, nonmiss)
    
	// get groups
	groups = uniqrows(g)
	if (rows(groups) != 2) {
		errprintf("Need exactly 2 groups\n")
		st_numscalar("r(stat)", .)
		st_numscalar("r(p)", .)
		return
	}
    
	v1 = select(y, g :== groups[1])
	v2 = select(y, g :== groups[2])
    
	// check for constant variables (all same value)
	if (rows(v1) > 0 & rows(v2) > 0) {
		if (all(v1 :== v1[1]) & all(v2 :== v2[1])) {
			if (v1[1] == v2[1]) {
				// Both groups have same constant value
				st_numscalar("r(stat)", 0)
				st_numscalar("r(p)", 1)
				return
			}
		}
	}
    
	// observed
	obs = wass_stat(v1, v2, power)
	st_numscalar("r(stat)", obs)
    
	// permutations
	N = rows(y); n1 = rows(v1); n2 = rows(v2)
	cnt = 0

	for (r=1; r<=reps; r++) {
		idx = order(runiform(N,1), 1)
		shuf = y[idx]
		s = wass_stat(shuf[1::n1], shuf[(n1+1)::N], power)
		if (s >= obs) cnt++
	}
   
	p = (cnt + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

real scalar wass_stat(a, b, pwr) {
	n1=rows(a); n2=rows(b); n=n1+n2
	
	// joint sample
	d=a\b
	
	// weight vectors
	ee=J(n1,1,1/n1)\J(n2,1,0)
	ff=J(n1,1,0)\J(n2,1,1/n2)
	
	// sort
	idx=order(d,1)
	d=d[idx]; ee=ee[idx]; ff=ff[idx]
	
	// calculate Wasserstein distance
	out=0; Ecur=0; Fcur=0
	
	for(i=1; i<=n-1; i++) {
		Ecur=Ecur+ee[i]; Fcur=Fcur+ff[i]
		height=abs(Fcur-Ecur)
		width=d[i+1]-d[i]  // distance between consecutive sorted values
		out=out+(height^pwr)*width
	}
	return(out)
}
end