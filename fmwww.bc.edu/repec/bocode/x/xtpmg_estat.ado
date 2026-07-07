*! version 2.1.1  06jul2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! xtpmg postestimation: estat box|bar|rcap for per-panel coefficients
*! Mirrors the estat graph interface of xtdcce2 (Ditzen).

program define xtpmg_estat, rclass
	version 15.1
	if "`e(cmd)'" != "xtpmg" {
		di as err "estat requires xtpmg estimation results in memory"
		exit 301
	}
	gettoken sub 0 : 0, parse(" ,")
	if inlist("`sub'","box","bar","rcap") {
		xtpmg_estat_graph `sub' `0'
		return add
	}
	else if "`sub'" == "bootstrap" {
		xtpmg_estat_boot `0'
		return add
	}
	else if "`sub'" == "hausman" {
		xtpmg_estat_haus `0'
		return add
	}
	else {
		di as err "unrecognized estat subcommand '`sub''"
		di as txt "  valid subcommands: {bf:box}, {bf:bar}, {bf:rcap}, {bf:bootstrap}, {bf:hausman}"
		exit 198
	}
end

program define xtpmg_estat_haus, rclass
	syntax [anything] [, SIGMAmore NOGraph NAME(string) ]

	local ests "`anything'"
	local ne : word count `ests'
	if `ne' < 2 {
		di as err "specify at least two stored estimates, e.g. {bf:estat hausman mg pmg}"
		exit 198
	}
	local e1 : word 1 of `ests'
	local e2 : word 2 of `ests'

	* snapshot the active estimates so we can restore them on exit
	tempname _snap
	capture estimates store `_snap'

	* ---- extract long-run coefficients (eq != SR) from each model ----
	local lrvars ""
	foreach e of local ests {
		capture estimates restore `e'
		if _rc {
			di as err "estimates '`e'' not found"
			capture estimates restore `_snap'
			exit 198
		}
		tempname bb
		matrix `bb' = e(b)
		local fns : colfullnames `bb'
		foreach fn of local fns {
			local cpos = strpos("`fn'",":")
			if `cpos' > 0 {
				local eq = substr("`fn'",1,`cpos'-1)
				local nm = substr("`fn'",`cpos'+1,.)
				if "`eq'" != "SR" {
					local c_`e'_`nm' = _b[`fn']
					local s_`e'_`nm' = _se[`fn']
					local isin : list posof "`nm'" in lrvars
					if `isin' == 0 local lrvars "`lrvars' `nm'"
				}
			}
		}
	}
	local nlr : word count `lrvars'
	if `nlr' == 0 {
		di as err "no long-run coefficients found to compare"
		capture estimates restore `_snap'
		exit 198
	}

	* ---- Hausman test on the first two (consistent vs efficient) ----
	tempname chi2 pval df
	capture hausman `e1' `e2', `sigmamore'
	if _rc == 0 {
		scalar `chi2' = r(chi2)
		scalar `pval' = r(p)
		scalar `df'   = r(df)
	}
	else {
		scalar `chi2' = .
		scalar `pval' = .
		scalar `df'   = .
	}

	* ---- print a compact table ----
	di as smcl in gr _n "{hline 78}"
	di in gr "{bf:Hausman specification test}" _col(60) in ye "XTPMG 2.1.1"
	di in gr "  H0: no systematic difference (restriction of '" in ye "`e2'" ///
		in gr "' vs '" in ye "`e1'" in gr "' is valid)"
	di as smcl in gr "{hline 78}"
	if `chi2' < . {
		local star ""
		if `pval' < 0.01      local star "***"
		else if `pval' < 0.05 local star "** "
		else if `pval' < 0.10 local star "*  "
		di in gr "  chi2(" in ye `df' in gr ") = " in ye %8.3f `chi2' "  `star'"
		di in gr "  Prob > chi2 = " in ye %8.4f `pval'
		if `pval' < 0.05 di in gr "  {bf:Reject H0} at 5%: prefer the less-restrictive estimator ('" in ye "`e1'" in gr "')."
		else             di in gr "  {bf:Do not reject H0} at 5%: the more efficient estimator ('" in ye "`e2'" in gr "') is preferred."
	}
	else {
		di in ye "  Hausman statistic unavailable (V_b-V_B may not be positive definite)."
	}
	di as smcl in gr "{hline 78}"

	if "`nograph'" != "" {
		capture estimates restore `_snap'
		return scalar chi2 = `chi2'
		return scalar p    = `pval'
		return scalar df   = `df'
		exit
	}

	* ---- build the comparison plot ----
	if "`name'" == "" local name xtpmg_hausman
	local col1 "231 76 60"
	local col2 "41 128 185"
	local col3 "39 174 96"
	local col4 "142 68 173"

	preserve
	clear
	qui set obs `= `nlr' * `ne''
	qui gen vnum = .
	qui gen double xpos = .
	qui gen double coef = .
	qui gen double lo   = .
	qui gen double hi   = .
	qui gen byte estk   = .
	local row = 0
	local vi = 0
	foreach v of local lrvars {
		local vi = `vi' + 1
		local ek = 0
		foreach e of local ests {
			local ek = `ek' + 1
			local row = `row' + 1
			local off = (`ek' - (`ne'+1)/2) * (0.55/`ne')
			qui replace vnum = `vi'         in `row'
			qui replace estk = `ek'         in `row'
			qui replace xpos = `vi' + `off' in `row'
			local cc = `c_`e'_`v''
			local ss = `s_`e'_`v''
			qui replace coef = `cc'            in `row'
			qui replace lo   = `cc' - 1.96*`ss' in `row'
			qui replace hi   = `cc' + 1.96*`ss' in `row'
		}
	}
	local ylab ""
	forvalues i = 1/`nlr' {
		local vn : word `i' of `lrvars'
		local ylab `"`ylab' `i' "`vn'""'
	}

	local plots ""
	local legord ""
	local li = 0
	forvalues k = 1/`ne' {
		if `k'==1 local col "`col1'"
		else if `k'==2 local col "`col2'"
		else if `k'==3 local col "`col3'"
		else local col "`col4'"
		local ename : word `k' of `ests'
		local plots `"`plots' (rcap lo hi xpos if estk==`k', horizontal lcolor("`col'") lwidth(medthin))"'
		local plots `"`plots' (scatter xpos coef if estk==`k', msymbol(O) msize(medium) mcolor("`col'") mlcolor(white) mlwidth(vthin))"'
		local li = `li' + 2
		local legord `"`legord' `li' "`ename'""'
	}

	local hnote "Hausman `e1' vs `e2': chi2(`=`df'')=`: di %5.2f `=`chi2''', p=`: di %5.3f `=`pval'''"
	if `chi2' >= . local hnote "Hausman `e1' vs `e2': statistic unavailable"

	#delimit ;
	twoway `plots' ,
		yscale(reverse)
		ylabel(`ylab', angle(0) labsize(small))
		ytitle("")
		xtitle("Long-run coefficient", size(medium))
		xlabel(, format(%5.2f) labsize(small) grid glcolor(gs14) glpattern(dot))
		xline(0, lcolor(gs8) lwidth(thin) lpattern(dash))
		title("{bf:Hausman Comparison of Long-Run Coefficients}",
			size(medlarge) color(black))
		subtitle("Point estimates with 95% CI by estimator - XTPMG 2.1.1",
			size(small) color(gs5))
		legend(order(`legord') position(6) ring(1) rows(1) size(small)
			region(lcolor(gs14) fcolor(white%90)))
		note("`hnote'"
			 "Whiskers = 95% CI. Overlapping intervals across estimators indicate no systematic difference.",
			size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(medium))
		name(`name', replace) ;
	#delimit cr
	restore

	di in gr "  {bf:Graph saved:} " in ye "`name'"
	capture estimates restore `_snap'

	return scalar chi2 = `chi2'
	return scalar p    = `pval'
	return scalar df   = `df'
	return local graph_name "`name'"
end

program define xtpmg_estat_boot, rclass
	syntax [, Reps(integer 100) SEED(string) WILD CFResiduals ///
		PERCENTILE SHOWindividual Level(cilevel) ]

	if "`e(cmdline)'" == "" {
		di as err "e(cmdline) not available; re-run xtpmg before estat bootstrap"
		exit 198
	}
	local cmdline `"`e(cmdline)'"'
	if strpos(`"`cmdline'"',"replace") == 0 local cmdline `"`cmdline' replace"'
	local ivar  "`e(ivar)'"
	local tvar  "`e(tvar)'"
	local model "`e(model)'"

	tempname b0
	matrix `b0' = e(b)
	local cnames : colfullnames `b0'
	local k = colsof(`b0')

	if "`wild'" != "" {
		di as txt "  Note: the wild bootstrap is not yet supported for the error-"
		di as txt "  correction model (it requires re-cumulating y under the null)."
		di as txt "  Falling back to the cross-section (panel) bootstrap."
	}

	if "`seed'" != "" set seed `seed'

	di as txt _n(1)
	di as smcl in gr "{hline 78}"
	di in gr "{bf:Cross-Section Bootstrap}" _col(60) in ye "XTPMG 2.1.1"
	di in gr "  Resampling panels with replacement (Westerlund et al. 2019;"
	di in gr "  Goncalves & Perron 2014).  Replications: " in ye "`reps'"
	di as smcl in gr "{hline 78}"

	* protect the user's estimation results
	tempname _hold
	capture _estimates hold `_hold', restore nullok

	tempname boot brow
	local ok = 0
	forvalues r = 1/`reps' {
		preserve
		capture {
			bsample, cluster(`ivar') idcluster(_bsid)
			qui xtset _bsid `tvar'
			qui `cmdline'
			matrix `brow' = e(b)
		}
		local brc = _rc
		restore
		if `brc' == 0 {
			capture matrix `boot' = nullmat(`boot') \ `brow'
			if _rc == 0 local ok = `ok' + 1
		}
	}

	capture _estimates unhold `_hold'

	if `ok' < 2 {
		di as err "  bootstrap failed: only `ok' successful replication(s)"
		exit 498
	}
	if `ok' < `reps' {
		di as txt "  (`=`reps'-`ok'' replication(s) discarded due to non-convergence)"
	}

	* ---- summarise via Mata: SE + percentile CIs ----
	mata: xtpmg_bootsum("`boot'", `level')
	tempname bse blo bhi
	matrix `bse' = __xtpmg_bootse
	matrix `blo' = __xtpmg_bootlo
	matrix `bhi' = __xtpmg_boothi

	local z = invnormal(1 - (1-`level'/100)/2)

	* ---- display table ----
	di as smcl in gr "{hline 78}"
	di in gr %-20s "Coefficient" " {c |}" ///
		%11s "Estimate" %12s "Boot. SE" %11s "z" ///
		"   [`level'% Conf." %6s "Int.]"
	di as smcl in gr "{hline 21}{c +}{hline 56}"
	forvalues j = 1/`k' {
		local nm : word `j' of `cnames'
		local est = `b0'[1,`j']
		local se  = `bse'[1,`j']
		if "`percentile'" != "" {
			local lo = `blo'[1,`j']
			local hi = `bhi'[1,`j']
		}
		else {
			local lo = `est' - `z'*`se'
			local hi = `est' + `z'*`se'
		}
		local zst = .
		if `se' > 0 & `se' < . local zst = `est'/`se'
		di in gr %-20s abbrev("`nm'",20) " {c |}" ///
			in ye %11.4f `est' %12.4f `se' %11.2f `zst' ///
			%11.4f `lo' %11.4f `hi'
	}
	di as smcl in gr "{hline 78}"
	local method = cond("`percentile'"!="", "percentile", "normal-approximation")
	di in gr "  CIs: `method'.  Successful replications: " in ye "`ok'" in gr " of " in ye "`reps'"
	di as smcl in gr "{hline 78}"

	return scalar reps = `ok'
	return local method "cross-section"
	return matrix se_boot = `bse'
	return matrix ci_lo = `blo'
	return matrix ci_hi = `bhi'
end

program define _xtpmg_base, rclass
	args tok
	local b "`tok'"
	if strpos("`b'",".")>0 {
		local b = substr("`b'", strrpos("`b'",".")+1, .)
	}
	return local base "`b'"
end

program define xtpmg_estat_graph, rclass
	gettoken gtype 0 : 0
	syntax [anything] [, COMBine(string asis) INDividual(string asis) ///
		noMG CLEARgraph DROPzero ]

	tempname BI SEI
	capture matrix `BI'  = e(b_i)
	local rc1 = _rc
	capture matrix `SEI' = e(se_i)
	if `rc1' | "`e(coef_i)'"=="" {
		di as err "per-panel coefficients (e(b_i)) are not available"
		di as txt "  estat box/bar/rcap require a {bf:pmg} or {bf:mg} model"
		exit 198
	}
	local coefs  "`e(coef_i)'"
	local ncoef  : word count `coefs'
	local pids   : rownames `BI'
	local np     : word count `pids'
	local model  "`e(model)'"

	* ---- choose which coefficients to plot ----
	local sel ""
	local selpos ""
	if `"`anything'"' == "" {
		local j = 0
		foreach c of local coefs {
			local j = `j' + 1
			if "`c'" != "_cons" {
				local sel    "`sel' `c'"
				local selpos "`selpos' `j'"
			}
		}
	}
	else {
		foreach u of local anything {
			_xtpmg_base "`u'"
			local ub "`r(base)'"
			local j = 0
			local hit = 0
			foreach c of local coefs {
				local j = `j' + 1
				_xtpmg_base "`c'"
				if "`c'"=="`u'" | "`r(base)'"=="`ub'" {
					local sel    "`sel' `c'"
					local selpos "`selpos' `j'"
					local hit = 1
				}
			}
			if !`hit' di as txt "  (note: '`u'' not among estimated coefficients; skipped)"
		}
	}
	local nsel : word count `selpos'
	if `nsel' == 0 {
		di as err "no matching coefficients to plot"
		exit 198
	}

	* ---- build plotting data ----
	preserve
	clear
	qui svmat double `BI',  name(bcol)
	qui svmat double `SEI', name(scol)
	qui gen _panel = _n
	qui gen str32 _pid = ""
	local i = 0
	foreach p of local pids {
		local i = `i' + 1
		qui replace _pid = "`p'" in `i'
	}

	* ---- box plot: distribution of per-panel estimates ----
	if "`gtype'" == "box" {
		local blist ""
		local lbls  ""
		foreach j of local selpos {
			local cname : word `j' of `coefs'
			if "`dropzero'" != "" {
				qui count if bcol`j' != 0 & bcol`j' < .
				if r(N)==0 continue
			}
			local blist "`blist' bcol`j'"
			qui label variable bcol`j' "`cname'"
		}
		if "`cleargraph'" != "" {
			graph box `blist' , `combine'
		}
		else {
			#delimit ;
			graph box `blist' ,
				title("{bf:Distribution of Per-Panel Coefficients}",
					size(medlarge) color(black))
				subtitle("`=upper("`model'")' estimator, `np' panels - XTPMG 2.1.1",
					size(small) color(gs5))
				ytitle("Coefficient", size(small))
				marker(1, mcolor("41 128 185"))
				box(1, color("52 152 219%55") lcolor("41 128 185"))
				graphregion(fcolor(white) lcolor(white))
				plotregion(fcolor(white) lcolor(gs14))
				`combine'
				name(xtpmg_estat_box, replace) ;
			#delimit cr
		}
		di as res "  graph saved: xtpmg_estat_box"
		return local graph_name "xtpmg_estat_box"
		restore
		exit
	}

	* ---- bar / rcap: one subgraph per coefficient, then combine ----
	local gnames ""
	local gi = 0
	foreach j of local selpos {
		local cname : word `j' of `coefs'
		if "`dropzero'" != "" {
			qui count if bcol`j' != 0 & bcol`j' < .
			if r(N)==0 continue
		}
		local gi = `gi' + 1
		qui gen _lo`j' = bcol`j' - 1.96*scol`j'
		qui gen _hi`j' = bcol`j' + 1.96*scol`j'
		* mean-group summary of this coefficient
		qui sum bcol`j'
		local mg   = r(mean)
		local mgn  = r(N)
		qui sum bcol`j', detail
		local mgse = sqrt(r(Var)/`mgn')
		local mglo = `mg' - 1.96*`mgse'
		local mghi = `mg' + 1.96*`mgse'

		local mgopt ""
		if "`nomg'" == "" {
			local mgopt yline(`mg', lcolor("231 76 60") lwidth(medthin) lpattern(dash))
		}
		local gname "xtpmg_es`gi'"
		local gnames "`gnames' `gname'"

		if "`gtype'" == "bar" {
			if "`cleargraph'" != "" {
				twoway (bar bcol`j' _panel, `individual'), `mgopt' name(`gname', replace) nodraw
			}
			else {
				#delimit ;
				twoway (bar bcol`j' _panel,
						barwidth(0.7) color("52 152 219%75") lcolor("41 128 185")),
					title("{bf:`cname'}", size(medium) color(black))
					ytitle("Coefficient", size(small))
					xtitle("Panel", size(small))
					xlabel(1/`np', valuelabel labsize(vsmall) angle(45))
					ylabel(, format(%5.2f) labsize(vsmall) angle(0)
						grid glcolor(gs14) glpattern(dot))
					yline(0, lcolor(gs10) lwidth(thin))
					`mgopt'
					`individual'
					graphregion(fcolor(white) lcolor(white))
					plotregion(fcolor(white) lcolor(gs14))
					legend(off) name(`gname', replace) nodraw ;
				#delimit cr
			}
		}
		else {
			* rcap : caterpillar of per-panel point + 95% CI
			if "`cleargraph'" != "" {
				twoway (rcap _lo`j' _hi`j' _panel) (scatter bcol`j' _panel, `individual'), ///
					`mgopt' name(`gname', replace) nodraw
			}
			else {
				#delimit ;
				twoway (rcap _lo`j' _hi`j' _panel,
						lcolor("41 128 185") lwidth(medthin))
					   (scatter bcol`j' _panel,
						msymbol(circle) msize(small) mcolor("41 128 185")
						mlcolor(white) mlwidth(vthin)),
					title("{bf:`cname'}", size(medium) color(black))
					ytitle("Coefficient", size(small))
					xtitle("Panel", size(small))
					xlabel(1/`np', valuelabel labsize(vsmall) angle(45))
					ylabel(, format(%5.2f) labsize(vsmall) angle(0)
						grid glcolor(gs14) glpattern(dot))
					yline(0, lcolor(gs10) lwidth(thin))
					`mgopt'
					`individual'
					graphregion(fcolor(white) lcolor(white))
					plotregion(fcolor(white) lcolor(gs14))
					legend(off) name(`gname', replace) nodraw ;
				#delimit cr
			}
		}
	}

	local ngr : word count `gnames'
	if `ngr' == 0 {
		di as err "nothing to plot"
		restore
		exit 198
	}

	local ttl = cond("`gtype'"=="bar", "Per-Panel Coefficients (bar)", "Per-Panel Coefficients with 95% CI")
	local mgnote = cond("`nomg'"=="", "Dashed red line = mean-group estimate.  ", "")
	if "`cleargraph'" != "" {
		graph combine `gnames' , `combine' name(xtpmg_estat_`gtype', replace)
	}
	else {
		#delimit ;
		graph combine `gnames' ,
			title("{bf:`ttl'}", size(medlarge) color(black))
			subtitle("`=upper("`model'")' estimator, `np' panels - XTPMG 2.1.1",
				size(small) color(gs5))
			note("`mgnote'Whiskers = 95% CI.", size(vsmall) color(gs6))
			graphregion(fcolor(white) lcolor(white))
			cols(2) iscale(0.75)
			`combine'
			name(xtpmg_estat_`gtype', replace) ;
		#delimit cr
	}
	di as res "  graph saved: xtpmg_estat_`gtype'"
	return local graph_name "xtpmg_estat_`gtype'"
	restore
end

* -------------------------------------------------------------------------
* Mata: bootstrap summary (SE from bootstrap SD, percentile CIs)
* -------------------------------------------------------------------------
mata:
void xtpmg_bootsum(string scalar bootname, real scalar lvl)
{
	real matrix B
	real rowvector se, lo, hi, col
	real scalar n, k, j, a, il, ih
	B = st_matrix(bootname)
	n = rows(B)
	k = cols(B)
	se = J(1, k, .)
	lo = J(1, k, .)
	hi = J(1, k, .)
	a  = (1 - lvl/100)/2
	il = trunc(a*(n+1))
	ih = n + 1 - il
	if (il < 1)  il = 1
	if (ih > n)  ih = n
	if (ih < 1)  ih = 1
	for (j=1; j<=k; j++) {
		se[1,j] = sqrt(variance(B[,j]))
		col = sort(B[,j], 1)'
		lo[1,j] = col[1, il]
		hi[1,j] = col[1, ih]
	}
	st_matrix("__xtpmg_bootse", se)
	st_matrix("__xtpmg_bootlo", lo)
	st_matrix("__xtpmg_boothi", hi)
}
end
