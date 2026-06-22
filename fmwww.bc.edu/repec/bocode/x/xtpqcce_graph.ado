*! xtpqcce_graph v1.0.0  20jun2026  Dr Merwan Roudane
*! Quantile-process plots for xtpqcce (top-journal style):
*! one panel per regressor, MG coefficient across tau with a shaded
*! pointwise CI band and a zero reference line (cf. Zhang & Su 2026, Fig.1).

capture program drop xtpqcce_graph
program define xtpqcce_graph
	version 15.1
	syntax [, COEF(string) Level(integer -1) ///
		EXPort(string) TITLEs(string) NAME(string) * ]

	if "`e(cmd)'" != "xtpqcce" {
		di as err "xtpqcce_graph works only after xtpqcce"
		exit 301
	}
	if "`coef'" == "" local coef "main"
	if !inlist("`coef'","main","long") {
		di as err "coef() must be {bf:main} or {bf:long}"
		exit 198
	}
	local est   "`e(estimator)'"
	local vars  "`e(indepvars)'"
	local taus  "`e(tau)'"
	local k     = e(k)
	local ntau  = e(ntau)
	if `level' < 0 local level = e(level)
	local z = invnormal(1 - (100-`level')/200)

	* unique default graph name (estimator + depvar + coef type) so that
	* successive models each keep their own window instead of overwriting
	if "`name'" == "" {
		local nm0 = strtoname("xtpqcce_`est'_`e(depvar)'_`coef'")
		local name "`nm0'"
	}

	* short estimator tag for the figure title
	if "`est'" == "qmg" local etag "QCCEMG"
	else                local etag "CCEMG-CSQR"
	capture confirm matrix e(bc_mg)
	if _rc == 0 & "`est'" == "csqr" local etag "`etag' (bias-corrected)"

	* choose point estimates + SE matrices
	tempname Mc Ms
	if "`coef'" == "long" {
		if "`est'" != "qmg" {
			di as err "coef(long) is available only for the {bf:qmg} estimator"
			exit 198
		}
		matrix `Mc' = e(lr_mg)
		matrix `Ms' = e(lr_SE)
		local clab "Long-run coefficient by quantile"
	}
	else {
		capture confirm matrix e(bc_mg)
		if _rc == 0 matrix `Mc' = e(bc_mg)
		else        matrix `Mc' = e(mg)
		matrix `Ms' = e(SE)
		if "`est'" == "qmg" local clab "Short-run coefficient by quantile"
		else local clab "Mean-group coefficient by quantile"
	}

	preserve
	qui {
		clear
		set obs `ntau'
		gen double _tau = .
		forvalues t = 1/`ntau' {
			local qv : word `t' of `taus'
			replace _tau = `qv' in `t'
		}
		local glist ""
		forvalues j = 1/`k' {
			local vn : word `j' of `vars'
			gen double _b`j'  = .
			gen double _lo`j' = .
			gen double _hi`j' = .
			forvalues t = 1/`ntau' {
				local c = (`t'-1)*`k' + `j'
				local bv = `Mc'[1, `c']
				local sv = `Ms'[1, `c']
				replace _b`j' = `bv' in `t'
				if `sv' < . & `sv' > 0 {
					replace _lo`j' = `bv' - `z'*`sv' in `t'
					replace _hi`j' = `bv' + `z'*`sv' in `t'
				}
			}
			local ttl : word `j' of `titles'
			if "`ttl'" == "" local ttl "`vn'"
			twoway ///
			  (rarea _lo`j' _hi`j' _tau, sort color("31 119 180%30") lwidth(none)) ///
			  (line _b`j' _tau, sort lcolor("31 119 180") lwidth(medthick)) ///
			  (scatter _b`j' _tau, msymbol(O) msize(small) ///
			        mcolor("31 119 180") mfcolor(white)) ///
			  , yline(0, lpattern(dash) lcolor(gs8)) ///
			    xtitle("") ytitle("") ///
			    xlabel(, labsize(small)) ylabel(, labsize(small) angle(0)) ///
			    title("`ttl'", size(medsmall) color(black)) ///
			    legend(off) name(`name'_`j', replace) nodraw ///
			    graphregion(color(white)) plotregion(margin(small))
			local glist "`glist' `name'_`j'"
		}
	}
	local nc = min(`k', 3)
	local nr = ceil(`k'/`nc')
	* the per-panel sources were built nodraw; graph combine draws the
	* final figure ONCE (so it appears and stays - no flashing), then we
	* drop the sources and export the drawn figure
	graph combine `glist', name(`name', replace) ///
		title("`etag'", size(medium) color(black)) ///
		subtitle("`clab' (shaded: `level'% pointwise CI)", size(small)) ///
		l1title("Coefficient", size(small)) ///
		b1title("Quantile {&tau}", size(small)) ///
		cols(`nc') imargin(small) ///
		xsize(`=3.2*`nc'') ysize(`=2.9*`nr'+0.6') ///
		graphregion(color(white)) plotregion(color(white)) `options'
	capture graph drop `glist'
	if "`export'" != "" {
		capture graph export "`export'", replace width(2000) name(`name')
		if _rc capture graph export "`export'", replace name(`name')
		if !_rc di as txt " figure saved to " as res "`export'"
	}
	di as txt " figure kept in memory as graph " as res "`name'" ///
		as txt "  (redisplay with: " as res "graph display `name'" as txt ")"
	restore
end
