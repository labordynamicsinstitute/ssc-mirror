*! 1.1.0 Ariel Linden 08Jan2026		// fixed by() to allow a string variable and use value labels
*! 1.0.0 Ariel Linden 22Dec2025 

program define kuipertest, rclass
	version 11.0
    
	syntax varname(numeric) [if] [in], BY(varname) ///
		[Reps(integer 1000) SEED(string) Power(real 1)]
    
	tempvar touse
	marksample touse, novarlist
	markout `touse' `varlist'
	
	// handle the by() variable separately to avoid markout issues with strings
	qui replace `touse' = 0 if missing(`by')
    
	local depvar `varlist'
	local origby "`by'"
	
	// check if there are any observations in the sample
	qui count if `touse'
	if r(N) == 0 {
		di as error "no observations in the sample"
		exit 2000
	}
	
	// get distinct values of by() variable
	qui levelsof `by' if `touse', local(by_vals)
	local num_groups : word count `by_vals'
	
	if `num_groups' != 2 {
		di as error "{bf:by()} variable must have exactly 2 distinct values"
		if `num_groups' == 1 di as error "found 1 group: `by_vals'"
		else di as error "found `num_groups' groups: `by_vals'"
		exit 420
	}
    
	// extract the two group values
	local group1_str : word 1 of `by_vals'
	local group2_str : word 2 of `by_vals'
	
	// check if by() variable needs to be converted to numeric
	capture confirm numeric variable `by'
	if _rc {
		// variable is string - create numeric version
		tempvar numby
		qui gen `numby' = .
		qui replace `numby' = 0 if `origby' == "`group1_str'" & `touse'
		qui replace `numby' = 1 if `origby' == "`group2_str'" & `touse'
		
		// use original string values for display
		local group1 "`group1_str'"
		local group2 "`group2_str'"
		local by "`numby'"
	}
	else {
		// variable is numeric - get value labels if they exist
		capture local label1 : label (`by') `group1_str'
		capture local label2 : label (`by') `group2_str'
		
		// use labels if available, otherwise use numeric values
		if "`label1'" == "" local label1 "`group1_str'"
		if "`label2'" == "" local label2 "`group2_str'"
		
		local group1 "`label1'"
		local group2 "`label2'"
	}

	// set seed
	if "`seed'" != "" {
		set seed `seed'
	}
	local inis `=c(seed)'
    
	// run Kuiper test
	mata: ku_main("`depvar'", "`by'", "`touse'", `reps', `power')
    
	// display results
	di _n "Two-sample Kuiper test for equality of distribution functions"
	di "{hline 61}"	
	di "Outcome:  `depvar'"
	di "Groups:   `origby' (`group1' vs `group2')"
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
	return local by = "`origby'"
	
	// Clean up temporary variable if created
	if "`numby'" != "" {
		capture drop `numby'
	}
end

version 11.0
mata:
mata clear

void ku_main(yvar, byvar, touse, reps, power) {
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
	obs = ku_stat(v1, v2, power)
	st_numscalar("r(stat)", obs)
    
	// permutations
	N = rows(y); n1 = rows(v1); n2 = rows(v2)
	cnt = 0

	for (r=1; r<=reps; r++) {
		idx = order(runiform(N,1), 1)
		shuf = y[idx]
		s = ku_stat(shuf[1::n1], shuf[(n1+1)::N], power)
		if (s >= obs) cnt++
	}
   
	p = (cnt + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

// Kuiper statistic
real scalar ku_stat(a, b, pwr) {
	n1 = rows(a); n2 = rows(b); n = n1 + n2
	
	// joint sample
	d = a \ b
	
	// weight vectors
	ee = J(n1, 1, 1/n1) \ J(n2, 1, 0)
	ff = J(n1, 1, 0) \ J(n2, 1, 1/n2)
	
	// sort
	idx = order(d, 1)
	d = d[idx]; ee = ee[idx]; ff = ff[idx]
	
	// Kuiper statistic calculation
	up = 0
	down = 0
	Ecur = 0
	Fcur = 0
	height = 0
	
	for (i = 1; i <= n - 1; i++) {
		Ecur = Ecur + ee[i]
		Fcur = Fcur + ff[i]
		
		// only update height when values change
		if (d[i] != d[i + 1]) {
			height = Fcur - Ecur
		}
		
		// track maximum positive and negative deviations
		if (height > up) up = height
		if (height < down) down = height
	}
	
	// Kuiper statistic: |down|^power + |up|^power
	stat = (abs(down)^pwr) + (abs(up)^pwr)
	return(stat)
}
end