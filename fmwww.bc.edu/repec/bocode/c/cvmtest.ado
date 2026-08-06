*! 3.0.0 Ariel Linden 24Jul2026		// generalization to k-samples, added posthoc option
*! 2.0.0 Ariel Linden 17Jul2026		// added weights, graph, and dots options
*! 1.1.0 Ariel Linden 08Jan2026		// fixed by() to allow a string variable and use value labels
*! 1.0.0 Ariel Linden 22Dec2025

program define cvmtest, rclass
	version 11.0

	syntax varname [pweight aweight iweight] [if] [in], BY(varname) ///
		[Reps(integer 1000) SEED(string) Power(real 2) GRaph DOts POSThoc]

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

	if `num_groups' < 2 {
		di as error "{bf:by()} variable must have at least 2 distinct values"
		exit 420
	}

	// build numeric group codes (recoding string by() to 1..k), and labels
	capture confirm numeric variable `by'
	local needrecode = _rc != 0

	tempvar numby
	if `needrecode' {
		qui gen `numby' = .
	}

	local i = 0
	foreach lv of local by_vals {
		local ++i
		if `needrecode' {
			qui replace `numby' = `i' if `origby' == "`lv'" & `touse'
			local grouplabel`i' "`lv'"
			local grpval`i' "`i'"
		}
		else {
			capture local lbl : label (`by') `lv'
			if "`lbl'" == "" local lbl "`lv'"
			local grouplabel`i' "`lbl'"
			local grpval`i' "`lv'"
		}
	}
	if `needrecode' local by "`numby'"

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

	// run K-sample CVM test
	mata: cvmk_by_test("`depvar'", "`by'", "`w'", "`touse'", `reps', `power', `showdots')

	local Wstat = r(stat)
	local Pstat = r(p)

	// display results
	if `hasweight' {
		di as txt _n "Weighted `num_groups'-sample Cramer-von Mises test for equality of distribution functions"
		di "{hline 80}"
	}
	else {
		di as txt _n "`num_groups'-sample Cramer-von Mises test for equality of distribution functions"
		di "{hline 71}"
	}
	di as txt "Outcome:  `depvar'"
	di as txt "Groups:   `origby'"
	forvalues j = 1/`num_groups' {
		qui count if `by' == `grpval`j'' & `touse'
		di as txt "  `j'. `grouplabel`j''" _col(35) "N = " as res r(N)
	}
	di "{hline 60}"
	if `num_groups' == 2 {
		di as txt "Test Statistic (CVM): " as res %6.4f `Wstat'
	}
	else {
		di as txt "Test Statistic (W):   " as res %6.4f `Wstat'
	}
	di as txt "{it:P}-value:              " as res %6.4f `Pstat' as txt " (based on " as res `reps' as txt " permutations)"
	di "{hline 60}"
	if `num_groups' == 2 {
*		di as txt "Note: CVM = " as res "{c S|}" as txt "_x |S_1(x) - S_2(x)|^`power', " as txt "identical to {bf:cvmtest}'s formula (k=2 case)"
	}
	else {
*		di as txt "Note: W = " as res "{c S|}" as txt "_x " as res "{c S|}" as txt "_j W_j |S_j(x) - Sbar(x)|^`power', " as txt "cf. Kiefer (1959)"
	}

	// save return values
	return scalar stat = `Wstat'
	return scalar p = `Pstat'
	return scalar reps = `reps'
	return scalar power = `power'
	return scalar k = `num_groups'
	return local by = "`origby'"
	return local statlabel = cond(`num_groups' == 2, "CVM", "W")

	// graph
	if "`graph'" != "" {
		tempname M
		mata: cvmk_ecdf_wrap("`depvar'", "`by'", "`w'", "`touse'", `power', "`M'")

		preserve
		quietly drop _all
		quietly svmat `M', names(col)
		quietly rename c1 x
		forvalues j = 1/`num_groups' {
			local jj = `j' + 1
			quietly rename c`jj' S`j'
		}
		local sbarcol = `num_groups' + 2
		quietly rename c`sbarcol' Sbar
		local contribcol = `num_groups' + 3
		quietly rename c`contribcol' cumW

		local plotcmd ""
		local legendorder ""
		forvalues j = 1/`num_groups' {
			local plotcmd `"`plotcmd' (line S`j' x, sort connect(stairstep))"'
			local legendorder `"`legendorder' `j' "`grouplabel`j''""'
		}
		local plotcmd `"`plotcmd' (line Sbar x, sort connect(stairstep) lpattern(dash) lcolor(black) lwidth(medthick))"'
		local sbarnum = `num_groups' + 1
		local legendorder `"`legendorder' `sbarnum' "Pooled""'

		local cdftitle "Empirical CDFs"
		local cdfytitle "Cumulative proportion"
		if `hasweight' {
			local cdftitle "Weighted empirical CDFs"
			local cdfytitle "Weighted cumulative proportion"
		}

		quietly twoway `plotcmd',                    ///
			legend(order(`legendorder'))              ///
			ytitle("`cdfytitle'")                     ///
			xtitle("`depvar'")                        ///
			title("`cdftitle'")                       ///
			name(cvmtestk_ecdf, replace)

		quietly twoway (line cumW x, sort lcolor(red) lwidth(medthick)), ///
			ytitle("Cumulative W contribution")       ///
			xtitle("`depvar'")                        ///
			title("Where the W statistic accumulates") ///
			name(cvmtestk_contrib, replace)

		graph combine cvmtestk_ecdf cvmtestk_contrib, rows(2) ///
			title("`num_groups'-sample Cramer-von Mises diagnostic: `depvar'")
		restore
	}

	// post-hoc pairwise comparisons
	if "`posthoc'" != "" {
		local npairs = `num_groups' * (`num_groups' - 1) / 2

		tempname PHraw PH
		matrix `PHraw' = J(`npairs', 2, .)

		tempvar touse2
		qui gen byte `touse2' = .

		local pr = 0
		local rownames ""
		forvalues a = 1/`=`num_groups'-1' {
			forvalues b = `=`a'+1'/`num_groups' {
				local ++pr
				qui replace `touse2' = `touse' & (`by' == `grpval`a'' | `by' == `grpval`b'')

				if `showdots' {
					di as txt _n "Pairwise: `grouplabel`a'' vs `grouplabel`b''"
					_dots 0
				}
				mata: cvmk_by_test("`depvar'", "`by'", "`w'", "`touse2'", `reps', `power', `showdots')

				matrix `PHraw'[`pr',1] = r(stat)
				matrix `PHraw'[`pr',2] = r(p)
				local rn`pr' "`grouplabel`a'' vs `grouplabel`b''"
				local rownames `"`rownames' "`rn`pr''""'
			}
		}

		// compute Bonferroni, Sidak, Holm, and FDR (Benjamini-Hochberg) adjusted p-values
		mata: st_matrix("`PH'", (st_matrix("`PHraw'"), cvmtestk_padjust(st_matrix("`PHraw'")[.,2])))
		matrix colnames `PH' = Stat P_raw P_bonf P_sidak P_holm P_fdr
		matrix rownames `PH' = `rownames'

		// size the label column to the longest group-pair label (avoids truncation)
		local maxlen = strlen("Groups")
		forvalues pr = 1/`npairs' {
			local len = strlen("`rn`pr''")
			if `len' > `maxlen' local maxlen = `len'
		}
		local maxlen = `maxlen' + 2
		local tablewidth = `maxlen' + 60

		di as txt _n "Post-hoc pairwise comparisons (" as res `npairs' as txt " pairs)"
		di "{hline `tablewidth'}"
		di as txt %-`maxlen's "Groups" "     Stat     {it:P}_raw    {it:P}_bonf   {it:P}_sidak    {it:P}_holm     {it:P}_fdr"	
		di "{hline `tablewidth'}"
		forvalues pr = 1/`npairs' {
			di as txt %-`maxlen's "`rn`pr''" as res ///
				%9.4f `PH'[`pr',1] " " %9.4f `PH'[`pr',2] " " %9.4f `PH'[`pr',3] " " ///
				%9.4f `PH'[`pr',4] " " %9.4f `PH'[`pr',5] " " %9.4f `PH'[`pr',6]
		}
		di "{hline `tablewidth'}"
		di as txt "{it:P}_bonf = Bonferroni; {it:P}_sidak = Sidak; {it:P}_holm = Holm step-down; {it:P}_fdr = Benjamini-Hochberg FDR"

		return matrix pairwise = `PH'
		return scalar npairs = `npairs'
	}

	// clean up temporary variable if created
	if `needrecode' {
		capture drop `numby'
	}
end

version 11.0
mata:

void cvmk_by_test(string scalar depvar, string scalar byvar, string scalar wvar, ///
	string scalar touse, real scalar reps, real scalar power, real scalar showdots)
{
	real vector y, g, w, groups, nonmiss
	real scalar N, obs, count, r

	st_view(y = ., ., depvar, touse)
	st_view(g = ., ., byvar, touse)
	st_view(w = ., ., wvar, touse)

	nonmiss = (y :!= . :& g :!= .)
	y = select(y, nonmiss)
	g = select(g, nonmiss)
	w = select(w, nonmiss)

	groups = uniqrows(g)
	if (rows(groups) < 2) {
		errprintf("Need at least 2 groups\n")
		st_numscalar("r(stat)", .)
		st_numscalar("r(p)", .)
		return
	}

	N = rows(y)

	obs = cvmk_compute(y, g, w, groups, power)
	st_numscalar("r(stat)", obs)

	count = 0
	for (r = 1; r <= reps; r++) {
		idx = order(runiform(N, 1), 1)
		stat = cvmk_compute(y[idx], g, w[idx], groups, power)
		if (stat >= obs) count++
		if (showdots == 1) cvmk_dots_tick(r, reps)
	}

	p = (count + 1) / (reps + 1)
	st_numscalar("r(p)", p)
}

// dots
void cvmk_dots_tick(real scalar b, real scalar B)
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

// For k=2, reduces to the classic two-sample CVM statistic
// For k>2, computes Kiefer's (1959) W statistic
real scalar cvmk_compute(real vector y, real vector g, real vector w, ///
	real vector groups, real scalar pwr)
{
	real scalar n, k, j, i, Wtot, Fcum, out
	real vector idx, ys, gs, ws, Wsum, Ecum, diff

	n = rows(y)
	k = rows(groups)

	idx = order(y, 1)
	ys = y[idx]; gs = g[idx]; ws = w[idx]

	Wsum = J(k, 1, 0)
	for (j=1; j<=k; j++) Wsum[j] = sum(select(w, g :== groups[j]))
	Wtot = sum(w)

	Ecum = J(k, 1, 0)
	Fcum = 0
	out = 0

	for (i=1; i<=n-1; i++) {
		j = selectindex(groups :== gs[i])
		Ecum[j] = Ecum[j] + ws[i] / Wsum[j]
		Fcum = Fcum + ws[i] / Wtot

		if (ys[i] != ys[i+1]) {
			if (k == 2) {
				out = out + abs(Ecum[1] - Ecum[2])^pwr
			}
			else {
				diff = Ecum :- Fcum
				out = out + sum(Wsum :* abs(diff):^pwr)
			}
		}
	}

	return(out)
}

// wrapper to build ECDF + contribution matrix for graphing
void cvmk_ecdf_wrap(string scalar depvar, string scalar byvar, string scalar wvar, ///
	string scalar touse, real scalar pwr, string scalar matname)
{
	real vector y, g, w, groups

	y = st_data(., depvar, touse)
	g = st_data(., byvar, touse)
	w = st_data(., wvar, touse)
	groups = uniqrows(g)

	st_matrix(matname, cvmk_ecdf(y, g, w, groups, pwr))
}

real matrix cvmk_ecdf(real vector y, real vector g, real vector w, ///
	real vector groups, real scalar pwr)
{
	real scalar n, k, j, i, Wtot, Fcum, m, h
	real vector idx, ys, gs, ws, Wsum, Ecum, diff, ux_v, Sbar_v, contrib
	real matrix S_v

	n = rows(y)
	k = rows(groups)

	idx = order(y, 1)
	ys = y[idx]; gs = g[idx]; ws = w[idx]

	Wsum = J(k, 1, 0)
	for (j=1; j<=k; j++) Wsum[j] = sum(select(w, g :== groups[j]))
	Wtot = sum(w)

	Ecum = J(k, 1, 0)
	Fcum = 0

	ux_v    = J(n-1, 1, .)
	S_v     = J(n-1, k, .)
	Sbar_v  = J(n-1, 1, .)
	contrib = J(n-1, 1, .)
	m = 0

	for (i=1; i<=n-1; i++) {
		j = selectindex(groups :== gs[i])
		Ecum[j] = Ecum[j] + ws[i] / Wsum[j]
		Fcum = Fcum + ws[i] / Wtot

		if (ys[i] != ys[i+1]) {
			m = m + 1
			ux_v[m] = ys[i]
			S_v[m,.] = Ecum'
			Sbar_v[m] = Fcum
			if (k == 2) {
				h = abs(Ecum[1] - Ecum[2])^pwr
			}
			else {
				diff = Ecum :- Fcum
				h = sum(Wsum :* abs(diff):^pwr)
			}
			contrib[m] = (m > 1 ? contrib[m-1] : 0) + h
		}
	}

	ux_v    = ux_v[1::m]
	S_v     = S_v[1::m,.]
	Sbar_v  = Sbar_v[1::m]
	contrib = contrib[1::m]

	return((ux_v, S_v, Sbar_v, contrib))
}

// multiple-comparison adjustments
real matrix cvmtestk_padjust(real vector p)
{
	real scalar m, i, val, runmax, runmin
	real vector bonf, idx, ps, adjs, holm, idxa, psa, adja, fdr, sidak

	m = rows(p)

	// Bonferroni
	bonf = p :* m
	for (i=1; i<=m; i++) if (bonf[i] > 1) bonf[i] = 1

	// Sidak
	sidak = 1 :- (1 :- p):^m

	// Holm step-down
	idx = order(p, 1)
	ps  = p[idx]
	adjs = J(m, 1, .)
	runmax = 0
	for (i=1; i<=m; i++) {
		val = (m - i + 1) * ps[i]
		if (val > 1) val = 1
		if (val < runmax) val = runmax
		runmax = val
		adjs[i] = val
	}
	holm = J(m, 1, .)
	for (i=1; i<=m; i++) holm[idx[i]] = adjs[i]

	// Benjamini-Hochberg FDR step-up
	idxa = order(p, 1)
	psa  = p[idxa]
	adja = J(m, 1, .)
	runmin = 1
	for (i=m; i>=1; i--) {
		val = (m / i) * psa[i]
		if (val > 1) val = 1
		if (val > runmin) val = runmin
		runmin = val
		adja[i] = val
	}
	fdr = J(m, 1, .)
	for (i=1; i<=m; i++) fdr[idxa[i]] = adja[i]

	return((bonf, sidak, holm, fdr))
}

end
