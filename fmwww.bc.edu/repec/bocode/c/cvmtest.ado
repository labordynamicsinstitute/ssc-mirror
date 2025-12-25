*! 1.0.0 Ariel Linden 22Dec2025 

program define cvmtest, rclass
	version 11.0
    
	syntax varname [if] [in], BY(varname) ///
		[Reps(integer 1000) SEED(string) Power(real 2)]
    
	// mark sample
	marksample touse
	markout `touse' `by'
    
	local depvar `varlist'
    
	// error check groups
	tempname byvals
	qui levelsof `by' if `touse', local(`byvals')
	local num_groups : word count ``byvals''
    
	if `num_groups' != 2 {
		di as error "{bf:by()} variable must have exactly 2 distinct values"
		di as error "found `num_groups' groups: ``byvals''"
		exit 420
	}
    
	local group1 : word 1 of ``byvals''
	local group2 : word 2 of ``byvals''
    
	// set seed
	if "`seed'" != "" {
		set seed `seed'
	}
	local inis `=c(seed)'
    
	// run CVM test
	mata: cvm_by_test("`depvar'", "`by'", "`touse'", `reps', `power')
    
    // display results
	di _n "Two-sample Cramer-von Mises test for equality of distribution functions"
	di "{hline 70}"
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

void cvm_by_test(depvar, byvar, touse, reps, power)
{
	// grab data from Stata
	st_view(y = ., ., depvar, touse)
	st_view(g = ., ., byvar, touse)
    
	// remove any rows where either variable is missing
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
    
	g1 = groups[1]
	g2 = groups[2]
    
	// extract group data
	v1 = select(y, g :== g1)
	v2 = select(y, g :== g2)
    
	// observed statistic
	obs = cvm_compute(v1, v2, power)
	st_numscalar("r(stat)", obs)
    
	// permutation test
	N = rows(y)
	n1 = rows(v1)
	n2 = rows(v2)
    
	count = 0
    
	for (r = 1; r <= reps; r++) {
		// shuffle all values
		idx = order(runiform(N, 1), 1)
		shuf = y[idx]
        
		// calculate the stat for permutation
		stat = cvm_compute(shuf[1::n1], shuf[(n1+1)::N], power)
		if (stat >= obs) count++
	}
    
	p = (count + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

real scalar cvm_compute(a, b, pwr)
{
	n1 = rows(a); n2 = rows(b); n = n1 + n2
	d = a \ b
	e = J(n1,1,1/n1) \ J(n2,1,0)
	f = J(n1,1,0) \ J(n2,1,1/n2)
    
	idx = order(d,1)
	d = d[idx]; e = e[idx]; f = f[idx]
    
	out = 0; Ec = 0; Fc = 0
    
	for (i=1; i<=n-1; i++) {
		Ec = Ec + e[i]; Fc = Fc + f[i]
		h = abs(Fc - Ec)
        
		// CVM: only add when values change (no duplicate handling)
		if (d[i] != d[i+1]) {
			out = out + h^pwr
		}
		// Note: No duplicate counting for CVM
	}
    
	return(out)
}

end