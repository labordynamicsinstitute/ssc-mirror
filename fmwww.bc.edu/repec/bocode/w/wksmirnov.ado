*! 1.0.0	Ariel Linden 10jul2026

program define wksmirnov, rclass
	version 14

	syntax varname(numeric) [pweight fweight aweight iweight] [if] [in], ///
		BY(varname numeric) ///
		[Reps(integer 0) ///
		SEED(integer -1) ///
		NODOts ///
		GRaph]

	if `reps' < 0 {
		di as error "reps() must be nonnegative"
		exit 198
	}

	marksample touse
	markout `touse' `by'

	quietly count if `touse'
	if r(N) == 0 {
		di as error "no observations satisfy the estimation sample"
		exit 2000
	}

	// weights
	tempvar w
	if "`weight'" != "" {
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

	// validate two groups
	quietly levelsof `by' if `touse', local(glevels)
	local ng : word count `glevels'
	if `ng' != 2 {
		di as error "by(`by') must identify exactly two nonmissing groups in the estimation sample; found `ng'"
		exit 198
	}
	local g0 : word 1 of `glevels'
	local g1 : word 2 of `glevels'

	tempvar gg
	quietly gen byte `gg' = (`by' == `g1') if `touse'

	if `seed' >= 0 {
		set seed `seed'
	}

	// display dots
	local dots = ("`nodots'" == "")

	if `reps' > 0 & `dots' == 1 {
		di _n
		_dots 0
	}

	// call Mata
	tempname sD sPa sPp sNe1 sNe0 sN1 sN0

	mata: wksmirnov_calc("`varlist'", "`gg'", "`w'", "`touse'", ///
		`reps', `dots', "`sD'", "`sPa'", "`sPp'", "`sNe1'", "`sNe0'", "`sN1'", "`sN0'")

	local D   = scalar(`sD')
	local n1  = scalar(`sN1')
	local n0  = scalar(`sN0')
	local ne1 = scalar(`sNe1')
	local ne0 = scalar(`sNe0')
	local pa  = scalar(`sPa')
	if `reps' > 0 local pp = scalar(`sPp')

	// display
	if "`weight'" != "" {
		di as txt _n "Weighted two-sample Kolmogorov–Smirnov test for equality of distribution functions"
	}
	else {
		di as txt _n "Two-sample Kolmogorov–Smirnov test for equality of distribution functions"		
	}
	di as txt "{hline 55}"
	di as txt "Variable: " as res "`varlist'" _col(30) as txt "Group variable: " as res "`by'"
	di as txt "Group `g1' =" as res %6.0f `n1' as txt _col(30) "Effective N = " as res %6.0f `ne1'
	di as txt "Group `g0' =" as res %6.0f `n0' as txt _col(30) "Effective N = " as res %6.0f `ne0'
	di as txt "{hline 55}"
	di as txt "D statistic" _col(30) " = " as res %9.4f `D'
	di as txt "Analytic p-value (asymptotic)" _col(30) " = " as res %9.4f `pa'
	if `reps' > 0 {
		di as txt "Permuted p-value ({bf:`reps'} reps)" _col(30) " = " as res %9.4f `pp'
	}
	di as txt "{hline 55}"

	// saved results
	return scalar D     = `D'
	return scalar N1    = `n1'
	return scalar N0    = `n0'
	return scalar effN1 = `ne1'
	return scalar effN0 = `ne0'
	return scalar p     = `pa'
	if `reps' > 0 {
		return scalar p_perm    = `pp'
		return scalar n_reps    = `reps'
	}
	return local group1 "`g1'"
	return local group0 "`g0'"
	return local varname "`varlist'"

	// graph
	if "`graph'" != "" {
		tempname M
		mata: st_matrix("`M'", wks_ecdf(st_data(.,"`varlist'","`touse'"), ///
			st_data(.,"`gg'","`touse'"), st_data(.,"`w'","`touse'")))

		preserve
		quietly drop _all
		quietly svmat `M', names(col)
		quietly rename c1 x
		quietly rename c2 F1
		quietly rename c3 F0

		// locate the D point
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
		if "`weight'" != "" {
			local cdftitle "Weighted empirical CDFs"
			local cdfytitle "Weighted cumulative proportion"
		}

		quietly twoway (line F1 x, sort connect(stairstep) lwidth(medthick))          ///
						(line F0 x, sort connect(stairstep) lpattern(dash))           ///
						(pcspike F0 x F1 x if atmax, lcolor(black) lwidth(medium)      ///
							mcolor(black) msymbol(O) msize(small)),                   ///
						legend(order(1 "Group `g1'" 2 "Group `g0'"))                  ///
						ytitle("`cdfytitle'")                                        ///
						xtitle("`varlist'")                                          ///
						title("`cdftitle'")                                          ///
						text(`Dmidy' `Dtextx' "D = `: display %5.3f `D''", place(e) size(small)) ///
						name(wksmirnov_ecdf, replace)
		restore
	}
end

version 14
mata:

real matrix wks_ecdf(real vector x, real vector g, real vector w)
{
	real vector idx, xs, gs, ws, cw1, cw0, last, ux, Fx1, Fx0
	real scalar n, s1, s0

	n   = rows(x)
	idx = order((x,g), (1,2))
	xs  = x[idx]
	gs  = g[idx]
	ws  = w[idx]

	s1 = sum(ws :* (gs:==1))
	s0 = sum(ws :* (gs:==0))

	cw1 = runningsum(ws :* (gs:==1))
	cw0 = runningsum(ws :* (gs:==0))

	if (n > 1) {
		last = selectindex(xs[1::(n-1)] :!= xs[2::n])
		last = last \ n
	}
	else {
		last = 1
	}

	ux  = xs[last]
	Fx1 = cw1[last] :/ s1
	Fx0 = cw0[last] :/ s0

	return((ux, Fx1, Fx0))
}

real scalar wks_Dstat(real vector x, real vector g, real vector w)
{
	real matrix E
	real scalar D

	E = wks_ecdf(x, g, w)
	D = max(abs(E[.,2] :- E[.,3]))
	return(D)
}

real scalar wks_kolm_p(real scalar D, real scalar ne1, real scalar ne0)
{
	real scalar en, lambda, p, k, term

	en     = ne1*ne0/(ne1+ne0)
	lambda = (sqrt(en) + 0.12 + 0.11/sqrt(en)) * D
	p      = 0
	for (k=1; k<=100; k++) {
		term = 2*(-1)^(k-1)*exp(-2*k^2*lambda^2)
		p    = p + term
		if (abs(term) < 1e-10) break
	}
	if (p < 0) p = 0
	if (p > 1) p = 1
	return(p)
}

real vector wks_wsample(real scalar n, real scalar size, real vector prob)
{
	// weighted sampling with replacement via inverse-CDF + binary search
	real vector cume, u, idx
	real scalar i, lo, hi, mid

	cume = runningsum(prob) :/ sum(prob)
	u    = runiform(size, 1)
	idx  = J(size, 1, 0)
	for (i=1; i<=size; i++) {
		lo = 1
		hi = n
		while (lo < hi) {
			mid = floor((lo+hi)/2)
			if (cume[mid] < u[i]) {
				lo = mid+1
			}
			else {
				hi = mid
			}
		}
		idx[i] = lo
	}
	return(idx)
}

// prints Stata-style progress dots from inside a Mata loop, with a running
// count every 50 reps -- a simplified version of what _dots draws for
// bootstrap/simulate/permute (no tick-mark ruler header, just dots+counts)
void wks_dots_tick(real scalar b, real scalar B)
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

// bootstrap approach to compute p value  as used in TWANG package
real scalar wks_twang_boot_p(real vector x, real vector g, real vector w, real scalar Dobs, real scalar B, real scalar showdots)
{
	real scalar n, ess_t, ess_c, sizeb, mt, mc, b, count, Dboot
	real vector w1, idx, gb, xb

	n     = rows(g)
	ess_t = (sum(w :* (g:==1)))^2 / sum((w:*(g:==1)):^2)
	ess_c = (sum(w :* (g:==0)))^2 / sum((w:*(g:==0)):^2)

	w1 = (g:==1) :* (ess_t :* w :/ sum(w :* (g:==1))) + (g:==0) :* (ess_c :* w :/ sum(w :* (g:==0)))
	w1 = w1 :/ (ess_t + ess_c)

	sizeb = trunc(ess_t + ess_c)
	mt    = floor(ess_t)
	mc    = sizeb - mt

	count = 0
	for (b=1; b<=B; b++) {
		idx = wks_wsample(n, sizeb, w1)
		xb  = x[idx]
		gb  = J(sizeb, 1, 0)
		if (mt > 0) gb[1::mt] = J(mt, 1, 1)
		Dboot = wks_Dstat(xb, gb, J(sizeb, 1, 1))
		if (Dboot >= Dobs) count = count + 1
		if (showdots==1) wks_dots_tick(b, B)
	}
	return(count/B)
}

void wksmirnov_calc(string scalar xvar, string scalar gvar, string scalar wvar,
	string scalar touse, real scalar B, real scalar showdots,
	string scalar sD, string scalar sPa, string scalar sPp,
	string scalar sNe1, string scalar sNe0, string scalar sN1, string scalar sN0)
{
	real vector x, g, w, w1, w0
	real scalar D, ne1, ne0, n1, n0, pa, pp

	x = st_data(., xvar, touse)
	g = st_data(., gvar, touse)
	w = st_data(., wvar, touse)

	D  = wks_Dstat(x, g, w)
	n1 = sum(g:==1)
	n0 = sum(g:==0)

	w1  = select(w, g:==1)
	w0  = select(w, g:==0)
	ne1 = (sum(w1))^2 / sum(w1:^2)
	ne0 = (sum(w0))^2 / sum(w0:^2)

	st_numscalar(sD,   D)
	st_numscalar(sN1,  n1)
	st_numscalar(sN0,  n0)
	st_numscalar(sNe1, ne1)
	st_numscalar(sNe0, ne0)

	pa = wks_kolm_p(D, ne1, ne0)
	st_numscalar(sPa, pa)

	if (B > 0) {
		pp = wks_twang_boot_p(x, g, w, D, B, showdots)
		st_numscalar(sPp, pp)
	}
	else {
		st_numscalar(sPp, .)
	}
}

end
