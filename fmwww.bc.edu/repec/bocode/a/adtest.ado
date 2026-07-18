*! 2.0.0 Ariel Linden 17Jul2026		// add weights, graph, and dots options
*! 1.1.0 Ariel Linden 08Jan2026		// fixed by() to allow a string variable and use value labels
*! 1.0.0 Ariel Linden 22Dec2025

program define adtest, rclass
	version 11.0

	syntax varname [pweight fweight aweight iweight] [if] [in], BY(varname) ///
		[Reps(integer 1000) SEED(string) Power(real 2) GRaph DOts]

	tempvar touse
	marksample touse, novarlist
	markout `touse' `varlist'

	// handle the by() variable separately to avoid markout issues with strings
	qui replace `touse' = 0 if missing(`by')

	local depvar `varlist'
	local origby "`by'"

	// weights (new)
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

	// run AD test
	mata: ad_by_test("`depvar'", "`by'", "`w'", "`touse'", `reps', `power', `showdots')

	// display results
	if `hasweight' {
		di as txt _n "Weighted two-sample Anderson-Darling test for equality of distribution functions"
		di "{hline 80}"
	}
	else {
		di as txt _n "Two-sample Anderson-Darling test for equality of distribution functions"
		di "{hline 71}"
	}
	di as txt "Outcome:  `depvar'"
	di as txt "Groups:   `origby' (`group1' vs `group2')"
	di "{hline 55}"
	di as txt "Test Statistic:  " as res %6.4f r(stat)
	di as txt "{it:P}-value:         " as res %6.4f r(p) as txt " (based on " as res `reps' as txt " permutations)"
	di "{hline 55}"
	
	// save return values
	return scalar stat = r(stat)
	return scalar p = r(p)
	return scalar reps = `reps'
	return scalar power = `power'
	return local group1 = "`group1'"
	return local group2 = "`group2'"
	return local by = "`origby'"

	// graph
	if "`graph'" != "" {
		tempname M
		mata: st_matrix("`M'", ad_ecdf_ad(st_data(.,"`depvar'","`touse'"), ///
			st_data(.,"`by'","`touse'"), st_data(.,"`w'","`touse'"), `power'))

		preserve
		quietly drop _all
		quietly svmat `M', names(col)
		quietly rename c1 x
		quietly rename c2 F1
		quietly rename c3 F0
		quietly rename c4 cumAD

		local cdftitle "Empirical CDFs"
		local cdfytitle "Cumulative proportion"
		if `hasweight' {
			local cdftitle "Weighted empirical CDFs"
			local cdfytitle "Weighted cumulative proportion"
		}

		quietly twoway (line F1 x, sort connect(stairstep) lwidth(medthick))  ///
						(line F0 x, sort connect(stairstep) lpattern(dash)), ///
						legend(order(1 "`group2'" 2 "`group1'"))             ///
						ytitle("`cdfytitle'") xtitle("`depvar'")             ///
						title("`cdftitle'") name(adtest_ecdf, replace)

		quietly twoway (line cumAD x, sort lcolor(red) lwidth(medthick)),   ///
						ytitle("Cumulative AD contribution") xtitle("`depvar'") ///
						title("Where the AD statistic accumulates")         ///
						name(adtest_contrib, replace)

		graph combine adtest_ecdf adtest_contrib, rows(2)                 ///
			title("Anderson-Darling diagnostic: `depvar'")
		restore
	}

	// clean up temporary variable if created
	if "`numby'" != "" {
		capture drop `numby'
	}
end

version 11.0
mata:

void ad_by_test(depvar, byvar, wvar, touse, reps, power, showdots)
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
	obs = ad_compute(v1, v2, w1, w2, power)
	st_numscalar("r(stat)", obs)

	// permutation test Ns
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
		stat = ad_compute(shuf[1::n1], shuf[(n1+1)::N], wshuf[1::n1], wshuf[(n1+1)::N], power)
		if (stat >= obs) count++
		if (showdots==1) ad_dots_tick(r, reps)
	}

	p = (count + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

// dots
void ad_dots_tick(real scalar b, real scalar B)
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

real scalar ad_compute(a, b, wa, wb, pwr)
{
	n1 = rows(a); n2 = rows(b); n = n1 + n2
	d  = a \ b
	waSum = sum(wa); wbSum = sum(wb)
	Nw = waSum + wbSum
	ws = wa \ wb
	e = (wa :/ waSum) \ J(n2,1,0)
	f = J(n1,1,0) \ (wb :/ wbSum)

	idx = order(d,1)
	d = d[idx]; e = e[idx]; f = f[idx]; ws = ws[idx]

	out = 0; Ec = 0; Fc = 0; Gc = 0; dup = 1
	ne1 = (waSum^2) / sum(wa:^2)
	ne2 = (wbSum^2) / sum(wb:^2)
	ne  = ne1 + ne2

	for (i=1; i<=n-1; i++) {
		Ec = Ec + e[i]; Fc = Fc + f[i]; Gc = Gc + ws[i]/Nw
		sd = sqrt((2*Gc*(1-Gc))/ne)
		h = abs(Fc - Ec)

		if (d[i] != d[i+1]) {
			out = out + ((h/sd)^pwr) * dup
			dup = 1
		}
		else {
			dup = dup + 1
		}
	}

	return(out)
}

real matrix ad_ecdf_ad(real vector x, real vector g, real vector w, real scalar pwr)
{
	real vector idx, xs, gs, ws, e, f, w0, w1
	real vector ux_v, Ec_v, Fc_v, contrib
	real scalar n, n0w, n1w, Nw, ne0, ne1, ne, i, Ec, Fc, Gc, sd, h, dup, m
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

	w0 = select(w, g:==g0val)
	w1 = select(w, g:==g1val)
	n0w = sum(w0)
	n1w = sum(w1)
	Nw  = n0w + n1w
	ne0 = n0w^2 / sum(w0:^2)
	ne1 = n1w^2 / sum(w1:^2)
	ne  = ne0 + ne1

	e = (gs:==g0val) :* (ws :/ n0w)
	f = (gs:==g1val) :* (ws :/ n1w)

	ux_v    = J(n-1, 1, .)
	Ec_v    = J(n-1, 1, .)
	Fc_v    = J(n-1, 1, .)
	contrib = J(n-1, 1, .)

	Ec  = 0
	Fc  = 0
	Gc  = 0
	dup = 1
	m   = 0
	for (i=1; i<=n-1; i++) {
		Ec = Ec + e[i]
		Fc = Fc + f[i]
		Gc = Gc + ws[i]/Nw
		sd = sqrt(2*Gc*(1-Gc)/ne)
		h  = abs(Fc - Ec)
		if (xs[i] != xs[i+1]) {
			m = m + 1
			ux_v[m] = xs[i]
			Fc_v[m] = Fc
			Ec_v[m] = Ec
			contrib[m] = (m > 1 ? contrib[m-1] : 0) + (h/sd)^pwr * dup
			dup = 1
		}
		else {
			dup = dup + 1
		}
	}

	ux_v    = ux_v[1::m]
	Fc_v    = Fc_v[1::m]
	Ec_v    = Ec_v[1::m]
	contrib = contrib[1::m]

	return((ux_v, Fc_v, Ec_v, contrib))
}

end
