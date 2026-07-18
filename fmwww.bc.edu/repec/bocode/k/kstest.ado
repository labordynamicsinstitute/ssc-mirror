*! 1.0.0 Ariel Linden 12Jul2026

program define kstest, rclass
	version 11.0

	syntax varname [pweight aweight iweight] [if] [in], ///
		BY(varname) ///
		[Reps(integer 1000) ///
		SEED(string) ///
		DOts ///
		GRaph]

	tempvar touse
	marksample touse, novarlist
	markout `touse' `varlist'

	// handle the by() variable separately to avoid markout issues with strings
	qui replace `touse' = 0 if missing(`by')

	local depvar `varlist'
	local origby "`by'"

	// weights
	tempvar w
	local hasweight = ("`weight'" != "")
	if `hasweight' {
		local wexp = trim(`"`exp'"')
		if substr(`"`wexp'"', 1, 1) == "=" {
			local wexp = trim(substr(`"`wexp'"', 2, .))
		}
		quietly gen double `w' = `wexp' if `touse'
		quietly replace `touse' = 0 if `touse' & (`w' <= 0 | missing(`w'))
	}
	else {
		quietly gen double `w' = 1 if `touse'
	}

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

	local showdots = ("`dots'" != "")
	if `reps' > 0 & `showdots' == 1 {
		di _n
		_dots 0
	}

	// run KS test
	mata: ks_by_test("`depvar'", "`by'", "`w'", "`touse'", `reps', `showdots')

	// save stats
	local Dstat = r(stat)
	local Pstat = r(p)

	// display results
	if `hasweight' {
		di as txt _n "Weighted two-sample Kolmogorov-Smirnov test for equality of distribution functions"
		di "{hline 82}"
	}
	else {
		di as txt _n "Two-sample Kolmogorov-Smirnov test for equality of distribution functions"
		di "{hline 73}"
	}
	di as txt "Outcome:  `depvar'"
	di as txt "Groups:   `origby' (`group1' vs `group2')"
	di "{hline 55}"
	di as txt "Test Statistic:  " as res %6.4f `Dstat'
	di as txt "{it:P}-value:         " as res %6.4f `Pstat' as txt " (based on " as res `reps' as txt " permutations)"
	di "{hline 55}"


	// save return values
	return scalar stat = `Dstat'
	return scalar p = `Pstat'
	return scalar reps = `reps'
	return local group1 = "`group1'"
	return local group2 = "`group2'"
	return local by = "`origby'"

	// graph
	if "`graph'" != "" {
		tempname M
		mata: st_matrix("`M'", ks_ecdf(st_data(.,"`depvar'","`touse'"), ///
			st_data(.,"`by'","`touse'"), st_data(.,"`w'","`touse'")))

		preserve
		quietly drop _all
		quietly svmat `M', names(col)
		quietly rename c1 x
		quietly rename c2 F1
		quietly rename c3 F0

		quietly gen double gap = abs(F1 - F0)
		quietly summarize gap, meanonly
		quietly gen byte atmax = (gap == r(max)) if !missing(gap)
		quietly summarize x if atmax, meanonly
		local Dx    = r(mean)
		quietly summarize F1 if atmax, meanonly
		local DF1   = r(mean)
		quietly summarize F0 if atmax, meanonly
		local DF0   = r(mean)
		local Dmidy = (`DF1' + `DF0') / 2

		quietly summarize x, meanonly
		local Dtextx = `Dx' + 0.035 * (r(max) - r(min))

		local cdftitle "Empirical CDFs"
		local cdfytitle "Cumulative proportion"
		if `hasweight' {
			local cdftitle "Weighted empirical CDFs"
			local cdfytitle "Weighted cumulative proportion"
		}

		quietly twoway (line F1 x, sort connect(stairstep) lwidth(medthick))          ///
						(line F0 x, sort connect(stairstep) lpattern(dash))           ///
						(pcspike F0 x F1 x if atmax, lcolor(black) lwidth(medium)      ///
							mcolor(black) msymbol(O) msize(small)),                   ///
						legend(order(1 "`group2'" 2 "`group1'"))                      ///
						ytitle("`cdfytitle'")                                        ///
						xtitle("`depvar'")                                           ///
						title("`cdftitle'")                                          ///
						text(`Dmidy' `Dtextx' "D = `: display %5.3f `Dstat''", place(e) size(small)) ///
						name(kstest_ecdf, replace)
		restore
	}

	// clean up temporary variable if created
	if "`numby'" != "" {
		capture drop `numby'
	}
end

version 11.0
mata:

void ks_by_test(depvar, byvar, wvar, touse, reps, showdots)
{
	// grab data from Stata
	st_view(y = ., ., depvar, touse)
	st_view(g = ., ., byvar, touse)
	st_view(w = ., ., wvar, touse)

	// remove any rows where either variable is missing
	nonmiss = (y :!= . :& g :!= .)
	y = select(y, nonmiss)
	g = select(g, nonmiss)
	w = select(w, nonmiss)

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

	// extract group data (values AND weights, kept as fixed pairs)
	v1 = select(y, g :== g1)
	v2 = select(y, g :== g2)
	w1 = select(w, g :== g1)
	w2 = select(w, g :== g2)

	// observed statistic
	obs = ks_compute(v1, v2, w1, w2)
	st_numscalar("r(stat)", obs)

	// permutation Ns
	N = rows(y)
	n1 = rows(v1)
	n2 = rows(v2)

	count = 0

	for (r = 1; r <= reps; r++) {
		// shuffle all (value, weight) pairs together
		idx = order(runiform(N, 1), 1)
		shuf  = y[idx]
		wshuf = w[idx]

		// calculate the stat for permutation
		stat = ks_compute(shuf[1::n1], shuf[(n1+1)::N], wshuf[1::n1], wshuf[(n1+1)::N])
		if (stat >= obs) count++
		if (showdots==1) ks_dots_tick(r, reps)
	}

	p = (count + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

// dots
void ks_dots_tick(real scalar b, real scalar B)
{
	real scalar pad
	string scalar fmt

	printf(".")
	if (mod(b,50)==0) {
		printf("%5.0f\n", b)
	}
	else if (b==B) {
		pad = 50 - mod(B,50)
		fmt = "%" + strofreal(5*pad+5) + ".0f\n"
		printf(fmt, b)
	}
	displayflush()
}

real scalar ks_compute(a, b, wa, wb)
{
	n1 = rows(a); n2 = rows(b); n = n1 + n2
	d  = a \ b
	waSum = sum(wa); wbSum = sum(wb)
	e = (wa :/ waSum) \ J(n2,1,0)
	f = J(n1,1,0) \ (wb :/ wbSum)

	idx = order(d,1)
	d = d[idx]; e = e[idx]; f = f[idx]

	Dmax = 0; Ec = 0; Fc = 0

	for (i=1; i<=n-1; i++) {
		Ec = Ec + e[i]; Fc = Fc + f[i]

		if (d[i] != d[i+1]) {
			h = abs(Fc - Ec)
			if (h > Dmax) Dmax = h
		}
	}

	return(Dmax)
}

// companion to ks_compute() for the graph option
real matrix ks_ecdf(real vector x, real vector g, real vector w)
{
	real vector idx, xs, gs, ws, e, f
	real vector ux_v, Ec_v, Fc_v
	real scalar n, n0w, n1w, i, Ec, Fc, m
	real scalar g0val, g1val
	real vector groups

	groups = uniqrows(g)
	g0val  = groups[1]
	g1val  = groups[2]

	n   = rows(x)
	idx = order(x, 1)
	xs  = x[idx]
	gs  = g[idx]
	ws  = w[idx]

	n0w = sum(select(w, g:==g0val))
	n1w = sum(select(w, g:==g1val))

	e = (gs:==g0val) :* (ws :/ n0w)
	f = (gs:==g1val) :* (ws :/ n1w)

	ux_v = J(n-1, 1, .)
	Ec_v = J(n-1, 1, .)
	Fc_v = J(n-1, 1, .)

	Ec = 0
	Fc = 0
	m  = 0
	for (i=1; i<=n-1; i++) {
		Ec = Ec + e[i]
		Fc = Fc + f[i]
		if (xs[i] != xs[i+1]) {
			m = m + 1
			ux_v[m] = xs[i]
			Fc_v[m] = Fc
			Ec_v[m] = Ec
		}
	}

	ux_v = ux_v[1::m]
	Fc_v = Fc_v[1::m]
	Ec_v = Ec_v[1::m]

	return((ux_v, Fc_v, Ec_v))
}

end
