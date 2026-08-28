*! _ardldml_nullgraph 1.0.1  24aug2026
*! graph helper for ardldml -- DML-Bounds
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Lives in its own file rather than inside ardldml.ado because
*  ardldml_estat.ado calls it: a sub-program defined inside another ado is
*  only in memory while that ado is loaded, and Stata resolves a command
*  name to a file of the same name.

program define _ardldml_nullgraph
	version 14.0
	syntax [, NAME(string) *]

	tempname D
	matrix `D' = e(draws)
	local F   = e(F)
	local cv  = e(crit)
	local B   = e(B)
	local pv  = e(p)
	local lev = e(level)
	local nm "ardldml_null"
	if ("`name'" != "") local nm "`name'"

	// twoway takes a string literal here, so the subtitle has to be built
	// before the call: "..." + string(...) inside subtitle() is printed
	// verbatim rather than evaluated.
	local sF  : di %6.3f `F'
	local scv : di %6.3f `cv'
	local spv : di %5.3f `pv'
	local sub "B = `B' draws;  observed F = `=trim("`sF'")',  `lev'% cv = `=trim("`scv'")',  p = `=trim("`spv'")'"

	preserve
	quietly {
		clear
		svmat double `D', name(fstar)
		local top = max(`F', `cv')
		summarize fstar1, detail
		local xmax = max(`top'*1.15, r(p99))

		// The observed statistic is drawn as a pci layer rather than a
		// second xline(): repeated xline() options are merged by twoway
		// and share one set of suboptions, so the two reference lines
		// would come out in the same pattern and could not be told apart.
		//
		// pci needs the height to span, so reproduce histogram's own
		// binning and take the tallest bar rather than guessing.
		summarize fstar1 if fstar1 <= `xmax'
		local ntot = r(N)
		local lo   = r(min)
		local hi   = r(max)
		local nb   = round(min(sqrt(`ntot'), 10 * ln(`ntot') / ln(10)))
		if (`nb' < 5) local nb = 5
		local w = (`hi' - `lo') / `nb'
		tempvar bin cnt
		gen int `bin' = min(floor((fstar1 - `lo') / `w'), `nb' - 1) ///
			if fstar1 <= `xmax'
		bysort `bin': gen long `cnt' = _N if !missing(`bin')
		summarize `cnt', meanonly
		local ytop = 100 * r(max) / `ntot' * 1.04

		twoway (histogram fstar1 if fstar1 <= `xmax', percent			///
					color(navy%35) lcolor(navy%60) lwidth(vthin))		///
			   (kdensity fstar1 if fstar1 <= `xmax', yaxis(2)			///
					lcolor(navy) lwidth(medthick) yscale(off axis(2)))	///
			   (pci 0 `F' `ytop' `F',									///
					lcolor(cranberry) lwidth(thick) lpattern(solid)),	///
			   xline(`cv', lcolor(orange) lpattern(dash) lwidth(medthick))	///
			   xtitle("bootstrap statistic F*") ytitle("percent of draws")	///
			   title("Restricted system wild bootstrap null")			///
			   subtitle(`"`sub'"')										///
			   note("Solid red: observed statistic.  Dashed orange: bootstrap"	///
					" critical value.  Do not compare with the tabulated bounds.")	///
			   legend(off) graphregion(color(white)) plotregion(color(white))	///
			   xscale(range(0 `xmax')) yscale(range(0 `ytop'))			///
			   name(`nm', replace) `options'
	}
	restore
end
