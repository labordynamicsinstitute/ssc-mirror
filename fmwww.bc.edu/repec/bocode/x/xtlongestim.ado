*! version 1.0.0  26jun2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! xtlongestim: long-run & mean-coefficient estimators for dynamic heterogeneous panels
*! Implements Pesaran & Zhao (1999) long-run bias-corrections (MG, NBC, DBC1, DBC2, BSBC)
*! and Hsiao, Pesaran & Tahmiscioglu (1999) short-run estimators
*! (Pooled OLS, MG, bias-corrected MG, Empirical Bayes / Swamy, Hierarchical Bayes / Gibbs)
*! Model: y(it) = a(i) + lambda(i)*y(i,t-1) + beta(i)'x(it) + e(it),  theta = beta/(1-lambda)

program define xtlongestim, eclass sortpreserve
	version 15.1

	if replay() {
		if (`"`e(cmd)'"' != "xtlongestim") error 301
		xtle_display, level(`=cond("`e(level)'"=="", c(level), `e(level)')')
		exit
	}
	Estimate `0'
end


program define Estimate, eclass sortpreserve
	syntax varlist(numeric ts min=2) [if] [in] [, 	///
		LR(varlist numeric)				///
		Methods(string)					///
		noCONStant						///
		Level(cilevel)					///
		REPS(integer 400)				///
		SEED(integer 12345)				///
		PARAmetric						///
		BURNin(integer 1000)			///
		DRAWS(integer 2000)				///
		RHO(real 2)						///
		GRAPH GNAME(string)				///
		EXPORT(string)					///
		NODOTS ]

	* ---- dependent variable and contemporaneous regressors ----------------
	gettoken depvar xvars : varlist
	local nx : word count `xvars'
	if `nx' < 1 {
		di as err "you must specify at least one regressor"
		exit 198
	}

	* ---- which methods to compute -----------------------------------------
	local methods = lower(strtrim("`methods'"))
	if "`methods'" == "" local methods "mg dbc1 dbc2 bsbc"
	if "`methods'" == "all" {
		local methods "pols mg bcmg nbc dbc1 dbc2 bsbc ebayes hbayes"
	}
	if "`methods'" == "longrun" local methods "mg nbc dbc1 dbc2 bsbc"
	if "`methods'" == "shortrun" local methods "pols mg bcmg ebayes hbayes"

	local known "pols mg bcmg nbc dbc1 dbc2 bsbc ebayes hbayes"
	foreach m of local methods {
		local ok : list m in known
		if !`ok' {
			di as err "method '`m'' not recognized"
			di as err "valid: `known' (or all, longrun, shortrun)"
			exit 198
		}
	}

	* feature flags
	local doMG    : list posof "mg"     in methods
	local doNBC   : list posof "nbc"    in methods
	local doDBC1  : list posof "dbc1"   in methods
	local doDBC2  : list posof "dbc2"   in methods
	local doBSBC  : list posof "bsbc"   in methods
	local doBCMG  : list posof "bcmg"   in methods
	local doEB    : list posof "ebayes" in methods
	local doHB    : list posof "hbayes" in methods
	local doPOLS  : list posof "pols"   in methods

	local need_boot = (`doNBC' | `doDBC1' | `doDBC2' | `doBSBC' | `doBCMG') > 0
	local need_swamy = (`doEB' | `doHB') > 0
	local need_gibbs = `doHB' > 0

	if `reps' < 20  & `need_boot' {
		di as err "reps() must be at least 20 for bias-correction"
		exit 198
	}

	* ---- panel / time settings --------------------------------------------
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if "`ivar'" == "" | "`tvar'" == "" {
		di as err "data not xtset; use {bf:xtset panelvar timevar} first"
		exit 459
	}

	* ---- build the lagged dependent variable ------------------------------
	tempvar Ly
	qui gen double `Ly' = L.`depvar'

	* ---- estimation sample -------------------------------------------------
	marksample touse
	markout `touse' `depvar' `Ly' `xvars'
	qui count if `touse'
	if r(N) == 0 {
		di as err "no observations"
		exit 2000
	}

	* drop panels with too few usable observations
	local kcols = `nx' + 1 + ("`constant'" == "")
	tempvar Tcount
	qui bysort `ivar': egen long `Tcount' = total(`touse')
	qui replace `touse' = 0 if `Tcount' <= `kcols' + 1
	qui count if `touse'
	if r(N) == 0 {
		di as err "no panel has enough observations (need T > `=`kcols'+1')"
		exit 2001
	}

	* ---- positions of long-run regressors among the betas -----------------
	if "`lr'" == "" local lr "`xvars'"
	local lrpos ""
	local nlr 0
	foreach v of local lr {
		local pos : list posof "`v'" in xvars
		if `pos' == 0 {
			di as err "long-run variable `v' is not among the regressors"
			exit 198
		}
		local lrpos "`lrpos' `pos'"
		local ++nlr
	}

	* must sort by panel then time before handing rows to Mata
	sort `ivar' `tvar'

	* resolve any time-series operators to real variables for Mata/st_data
	tsrevar `depvar'
	local dvrev "`r(varlist)'"
	tsrevar `xvars'
	local xrev "`r(varlist)'"

	* ---- output matrix names ----------------------------------------------
	tempname LRB LRSE SRB SRSE
	tempname Nout Tmin Tmax Tavg Nobs
	tempname THi THiSE BIm BISEm IDm

	if "`nodots'" != "" local pdots 0
	else local pdots 1
	local par = ("`parametric'" != "")
	local hascons = ("`constant'" == "")

	set seed `seed'

	mata: xtle_engine("`dvrev'", "`Ly'", "`xrev'", "`ivar'", "`touse'", 	///
		`hascons', "`lrpos'", `reps', `par', `pdots', 					///
		`doMG', `doNBC', `doDBC1', `doDBC2', `doBSBC', `doBCMG', 		///
		`doEB', `doHB', `doPOLS', `need_boot', `need_swamy', `need_gibbs',	///
		`burnin', `draws', `rho', 									///
		"`LRB'", "`LRSE'", "`SRB'", "`SRSE'", 						///
		"`Nout'", "`Tmin'", "`Tmax'", "`Tavg'", "`Nobs'",				///
		"`THi'", "`THiSE'", "`BIm'", "`BISEm'", "`IDm'")

	* ---- column names ------------------------------------------------------
	matrix colnames `LRB'  = `lr'
	matrix colnames `LRSE' = `lr'
	local srnames "L.`depvar' `xvars'"
	matrix colnames `SRB'  = `srnames'
	matrix colnames `SRSE' = `srnames'

	local lrmeth "mg nbc dbc1 dbc2 bsbc bcmg ebayes hbayes pols"
	local srmeth "pols mg bcmg ebayes hbayes"
	matrix rownames `LRB'  = `lrmeth'
	matrix rownames `LRSE' = `lrmeth'
	matrix rownames `SRB'  = `srmeth'
	matrix rownames `SRSE' = `srmeth'

	* per-panel matrices (for heterogeneity plots)
	matrix colnames `THi'    = `lr'
	matrix colnames `THiSE'  = `lr'
	matrix colnames `BIm'    = `srnames'
	matrix colnames `BISEm'  = `srnames'
	matrix colnames `IDm'    = `ivar'

	* ---- post the primary estimator as e(b)/e(V) --------------------------
	* primary = first method in the user list that has a long-run row
	local primary ""
	foreach m of local methods {
		local isLR : list posof "`m'" in lrmeth
		if `isLR' & "`primary'" == "" local primary "`m'"
	}
	if "`primary'" == "" local primary "mg"
	local prow : list posof "`primary'" in lrmeth

	tempname b V
	matrix `b' = `LRB'[`prow', 1...]
	matrix `V' = J(`nlr', `nlr', 0)
	forvalues j = 1/`nlr' {
		matrix `V'[`j',`j'] = `LRSE'[`prow',`j']^2
	}
	matrix colnames `b' = `lr'
	matrix colnames `V' = `lr'
	matrix rownames `V' = `lr'

	ereturn post `b' `V', depname(`depvar') esample(`touse')
	ereturn scalar N      = `Nobs'
	ereturn scalar N_g    = `Nout'
	ereturn scalar g_min  = `Tmin'
	ereturn scalar g_max  = `Tmax'
	ereturn scalar g_avg  = `Tavg'
	ereturn scalar reps   = `reps'
	ereturn scalar level  = `level'
	ereturn local  primary  "`primary'"
	ereturn local  methods  "`methods'"
	ereturn local  lrvars   "`lr'"
	ereturn local  srvars   "`srnames'"
	ereturn local  ivar     "`ivar'"
	ereturn local  tvar     "`tvar'"
	ereturn local  depvar   "`depvar'"
	ereturn local  title    "Long-run estimation in dynamic heterogeneous panels"
	ereturn local  cmd      "xtlongestim"
	ereturn matrix LR_b  = `LRB'
	ereturn matrix LR_se = `LRSE'
	ereturn matrix SR_b  = `SRB'
	ereturn matrix SR_se = `SRSE'
	ereturn matrix theta_i    = `THi'
	ereturn matrix theta_i_se = `THiSE'
	ereturn matrix coef_i     = `BIm'
	ereturn matrix coef_i_se  = `BISEm'
	ereturn matrix panel_ids  = `IDm'

	xtle_display, level(`level')

	if "`export'" != "" {
		xtle_export, using("`export'") level(`level')
	}
	if "`graph'" != "" | "`gname'" != "" {
		xtle_graph, gname(`gname') level(`level')
	}
end


* =========================================================================
* DISPLAY
* =========================================================================
program define xtle_display
	syntax [, Level(cilevel) ]

	local methods "`e(methods)'"
	local lrvars  "`e(lrvars)'"
	local srvars  "`e(srvars)'"
	tempname LRB LRSE SRB SRSE
	matrix `LRB'  = e(LR_b)
	matrix `LRSE' = e(LR_se)
	matrix `SRB'  = e(SR_b)
	matrix `SRSE' = e(SR_se)

	local z = invnormal(1 - (100 - `level')/200)

	di _n in smcl in gr "{hline 78}"
	di in gr "{bf:Long-run estimation in dynamic heterogeneous panels}" ///
		_col(64) in ye "xtlongestim"
	di in gr "{it:y(it) = a(i) + lambda(i) y(i,t-1) + beta(i)'x(it) + e(it),  theta=beta/(1-lambda)}"
	di in smcl in gr "{hline 78}"
	di in gr "Panel variable (i): " in ye abbrev("`e(ivar)'",12) ///
		_col(46) in gr "No. of groups   = " in ye %9.0g e(N_g)
	di in gr "Time variable  (t): " in ye abbrev("`e(tvar)'",12) ///
		_col(46) in gr "No. of obs      = " in ye %9.0g e(N)
	di in gr _col(46) "Obs per group   = " in ye %9.0g e(g_avg) in gr " (avg)"
	di in gr _col(46) "                  " in ye %9.0g e(g_min) in gr " (min) " ///
		in ye %5.0g e(g_max) in gr " (max)"
	di in gr "Bootstrap reps:  " in ye %5.0g e(reps)

	* ---------------- LONG-RUN COEFFICIENT TABLES --------------------------
	local lrlabels "mg nbc dbc1 dbc2 bsbc bcmg ebayes hbayes pols"
	local lrpretty `""Mean Group" "NBC (naive)" "DBC1 (dir.)" "DBC2 (dir.)" "BSBC (boot)" "BC Mean Grp" "Emp. Bayes" "Hier. Bayes" "Pooled OLS""'

	local jv 0
	foreach v of local lrvars {
		local ++jv
		di _n in gr "{bf:Long-run coefficient: }" in ye "`v'"
		di in smcl in gr "{hline 13}{c TT}{hline 64}"
		di in gr %12s "Estimator" " {c |}" ///
			_col(20) "Coef." _col(33) "Std. Err." _col(46) "z" ///
			_col(54) "P>|z|" _col(63) "[`level'% Conf. Int.]"
		di in smcl in gr "{hline 13}{c +}{hline 64}"

		local r 0
		foreach m of local lrlabels {
			local ++r
			local want : list posof "`m'" in methods
			if `want' {
				local lbl : word `r' of `lrpretty'
				local b  = `LRB'[`r', `jv']
				local se = `LRSE'[`r', `jv']
				if `b' == . {
					di in gr %12s "`lbl'" " {c |}" _col(20) in ye "(not available)"
				}
				else if `se' == . | `se' <= 0 {
					di in gr %12s "`lbl'" " {c |}" ///
						in ye _col(18) %10.0g `b'
				}
				else {
					local zz = `b' / `se'
					local pp = 2 * normal(-abs(`zz'))
					local lo = `b' - `z' * `se'
					local hi = `b' + `z' * `se'
					local star "`=cond(`pp'<.01,"***",cond(`pp'<.05,"** ",cond(`pp'<.1,"*  ","   ")))'"
					di in gr %12s "`lbl'" " {c |}" ///
						in ye _col(18) %9.0g `b' "`star'" ///
						_col(33) %9.0g `se' ///
						_col(45) %5.2f `zz' ///
						_col(52) %5.3f `pp' ///
						_col(60) %8.0g `lo' " " %8.0g `hi'
				}
			}
		}
		di in smcl in gr "{hline 13}{c BT}{hline 64}"
		di in gr "  {it:Significance:} *** p<.01, ** p<.05, * p<.1"
	}

	* ---------------- SHORT-RUN MEAN COEFFICIENT TABLE ---------------------
	local sron "pols mg bcmg ebayes hbayes"
	local anysr 0
	foreach m of local sron {
		local w : list posof "`m'" in methods
		if `w' local anysr 1
	}
	if `anysr' {
		local srpretty `""Pooled OLS" "Mean Group" "BC Mean Grp" "Emp. Bayes" "Hier. Bayes""'
		local jv 0
		foreach v of local srvars {
			local ++jv
			di _n in gr "{bf:Mean short-run coefficient: }" in ye "`v'"
			di in smcl in gr "{hline 13}{c TT}{hline 64}"
			di in gr %12s "Estimator" " {c |}" ///
				_col(20) "Coef." _col(33) "Std. Err." _col(46) "z" ///
				_col(54) "P>|z|" _col(63) "[`level'% Conf. Int.]"
			di in smcl in gr "{hline 13}{c +}{hline 64}"
			local r 0
			foreach m of local sron {
				local ++r
				local want : list posof "`m'" in methods
				if `want' {
					local lbl : word `r' of `srpretty'
					local b  = `SRB'[`r', `jv']
					local se = `SRSE'[`r', `jv']
					if `b' == . {
						di in gr %12s "`lbl'" " {c |}" _col(20) in ye "(not available)"
					}
					else if `se' == . | `se' <= 0 {
						di in gr %12s "`lbl'" " {c |}" in ye _col(18) %10.0g `b'
					}
					else {
						local zz = `b' / `se'
						local pp = 2 * normal(-abs(`zz'))
						local lo = `b' - `z' * `se'
						local hi = `b' + `z' * `se'
						local star "`=cond(`pp'<.01,"***",cond(`pp'<.05,"** ",cond(`pp'<.1,"*  ","   ")))'"
						di in gr %12s "`lbl'" " {c |}" ///
							in ye _col(18) %9.0g `b' "`star'" ///
							_col(33) %9.0g `se' ///
							_col(45) %5.2f `zz' ///
							_col(52) %5.3f `pp' ///
							_col(60) %8.0g `lo' " " %8.0g `hi'
					}
				}
			}
			di in smcl in gr "{hline 13}{c BT}{hline 64}"
			di in gr "  {it:Significance:} *** p<.01, ** p<.05, * p<.1"
		}
	}

	di in gr "Primary (posted) estimator: " in ye "`e(primary)'"
	di in gr "Full results in {bf:e(LR_b)}, {bf:e(LR_se)}, {bf:e(SR_b)}, {bf:e(SR_se)}."
end


* =========================================================================
* EXPORT  -- journal-style tables to LaTeX (booktabs) and/or CSV
* =========================================================================
program define xtle_export
	syntax , Using(string) [Level(cilevel)]

	local z = invnormal(1 - (100 - `level')/200)
	tempname LRB LRSE
	matrix `LRB' = e(LR_b)
	matrix `LRSE' = e(LR_se)
	local methods "`e(methods)'"
	local lrvars  "`e(lrvars)'"
	local nlr : word count `lrvars'
	local lrmeth   "mg nbc dbc1 dbc2 bsbc bcmg ebayes hbayes pols"
	local lrpretty `""Mean Group" "NBC" "DBC1" "DBC2" "BSBC" "Bias-corr. MG" "Empirical Bayes" "Hierarchical Bayes" "Pooled OLS""'

	* present long-run method rows
	local pm ""
	local r 0
	foreach m of local lrmeth {
		local ++r
		local w : list posof "`m'" in methods
		if `w' {
			local bb = `LRB'[`r', 1]
			if `bb' != . local pm "`pm' `r'"
		}
	}

	* decide output targets from the extension
	local dot = strrpos("`using'", ".")
	if `dot' > 0 local ext = lower(substr("`using'", `dot' + 1, .))
	else local ext ""
	if "`ext'" == "tex" {
		local texf "`using'"
	}
	else if "`ext'" == "csv" {
		local csvf "`using'"
	}
	else {
		local texf "`using'.tex"
		local csvf "`using'.csv"
	}

	* ---- LaTeX (booktabs) ------------------------------------------------
	if "`texf'" != "" {
		tempname fh
		file open `fh' using "`texf'", write replace text
		file write `fh' "\begin{table}[htbp]\centering" _n
		file write `fh' "\caption{Long-run coefficient estimates}" _n
		file write `fh' "\label{tab:xtlongestim}" _n
		file write `fh' "\begin{tabular}{l*{`nlr'}{c}}" _n
		file write `fh' "\toprule" _n
		file write `fh' "Estimator"
		foreach v of local lrvars {
			file write `fh' " & `v'"
		}
		file write `fh' " \\" _n "\midrule" _n
		foreach r of local pm {
			local lbl : word `r' of `lrpretty'
			local line "`lbl'"
			local jv 0
			foreach v of local lrvars {
				local ++jv
				local b  = `LRB'[`r', `jv']
				local s  = `LRSE'[`r', `jv']
				local st ""
				if `s' != . & `s' > 0 {
					local p = 2*normal(-abs(`b'/`s'))
					if `p' < .01      local st "\$^{***}\$"
					else if `p' < .05 local st "\$^{**}\$"
					else if `p' < .1  local st "\$^{*}\$"
				}
				local bs = strtrim(string(`b', "%9.3f"))
				local line "`line' & `bs'`st'"
			}
			file write `fh' "`line' \\" _n
			local line " "
			local jv 0
			foreach v of local lrvars {
				local ++jv
				local s = `LRSE'[`r', `jv']
				if `s' != . & `s' > 0 {
					local ss = strtrim(string(`s', "%9.3f"))
					local line "`line' & (`ss')"
				}
				else local line "`line' & "
			}
			file write `fh' "`line' \\" _n
		}
		file write `fh' "\bottomrule" _n
		file write `fh' "\end{tabular}" _n
		file write `fh' "\par\smallskip" _n
		file write `fh' "{\footnotesize Standard errors in parentheses. "
		file write `fh' "\$^{*}\$ p\$<\$.1, \$^{**}\$ p\$<\$.05, \$^{***}\$ p\$<\$.01. "
		file write `fh' "Long-run \$\theta=\beta/(1-\lambda)\$ from "
		file write `fh' "\$y_{it}=a_i+\lambda_i y_{i,t-1}+\beta_i x_{it}+e_{it}\$.}" _n
		file write `fh' "\end{table}" _n
		file close `fh'
		di in gr "LaTeX table written to " in ye "`texf'"
	}

	* ---- CSV -------------------------------------------------------------
	if "`csvf'" != "" {
		tempname fc
		file open `fc' using "`csvf'", write replace text
		file write `fc' "estimator"
		foreach v of local lrvars {
			file write `fc' ",`v',`v'_se"
		}
		file write `fc' _n
		foreach r of local pm {
			local lbl : word `r' of `lrpretty'
			file write `fc' `"`lbl'"'
			local jv 0
			foreach v of local lrvars {
				local ++jv
				local b = `LRB'[`r', `jv']
				local s = `LRSE'[`r', `jv']
				file write `fc' ",`b',`s'"
			}
			file write `fc' _n
		}
		file close `fc'
		di in gr "CSV table written to " in ye "`csvf'"
	}
end


* =========================================================================
* GRAPHS  -- publication-quality visualisations
* =========================================================================
program define xtle_graph
	syntax [, GNAME(string) Level(cilevel)]
	if "`gname'" == "" local gname xtle
	local z = invnormal(1 - (100 - `level')/200)

	tempname LRB LRSE SRB SRSE THi THiSE
	matrix `LRB'   = e(LR_b)
	matrix `LRSE'  = e(LR_se)
	matrix `SRB'   = e(SR_b)
	matrix `SRSE'  = e(SR_se)
	matrix `THi'   = e(theta_i)
	matrix `THiSE' = e(theta_i_se)

	local methods "`e(methods)'"
	local lrvars  "`e(lrvars)'"
	local srvars  "`e(srvars)'"
	local lrmeth   "mg nbc dbc1 dbc2 bsbc bcmg ebayes hbayes pols"
	local lrpretty `""Mean Group" "NBC" "DBC1" "DBC2" "BSBC" "BC-MG" "Emp. Bayes" "Hier. Bayes" "Pooled OLS""'
	local srmeth   "pols mg bcmg ebayes hbayes"
	local srpretty `""Pooled OLS" "Mean Group" "BC-MG" "Emp. Bayes" "Hier. Bayes""'

	* family colour by method (1 uncorr, 2 bias-corr, 3 Bayes, 4 pooled)
	local c1 "26 78 126"
	local c2 "39 174 96"
	local c3 "142 68 173"
	local c4 "192 57 43"
	local ccap "120 120 120"

	di _n in smcl in gr "{hline 78}"
	di in gr "{bf:Generating publication graphs}" _col(60) in ye "xtlongestim"
	di in smcl in gr "{hline 78}"

	* headless batch cannot live-render; build graphs with the device off so
	* the run never aborts (graphs are stored and can be displayed/exported).
	local gsave ""
	if "`c(mode)'" == "batch" {
		local gsave "`c(graphics)'"
		set graphics off
	}

	preserve

	* =================================================================
	* 1.  LONG-RUN forest plot(s)
	* =================================================================
	capture noisily xtle_forest, b(`LRB') se(`LRSE') vars(`lrvars') meth(`lrmeth') ///
		pretty(`lrpretty') methods(`methods') z(`z') ///
		gname(`gname'_lr) kind("Long-run coefficient") ///
		c1(`c1') c2(`c2') c3(`c3') c4(`c4') ccap(`ccap')
	if _rc di in error "  (long-run forest plot skipped, rc=" _rc ")"

	* =================================================================
	* 2.  SHORT-RUN forest plot(s)  (only if any short-run method)
	* =================================================================
	local anysr 0
	foreach m of local srmeth {
		local w : list posof "`m'" in methods
		if `w' local anysr 1
	}
	if `anysr' {
		capture noisily xtle_forest, b(`SRB') se(`SRSE') vars(`srvars') meth(`srmeth') ///
			pretty(`srpretty') methods(`methods') z(`z') ///
			gname(`gname'_sr) kind("Mean short-run coefficient") ///
			c1(`c1') c2(`c2') c3(`c3') c4(`c4') ccap(`ccap')
		if _rc di in error "  (short-run forest plot skipped, rc=" _rc ")"
	}

	* =================================================================
	* 3.  Cross-panel heterogeneity caterpillar(s) of theta_i
	*     one clean figure per variable (no by(), no graph combine)
	* =================================================================
	local nv : word count `lrvars'
	capture noisily {
		local jv 0
		foreach v of local lrvars {
			local ++jv
			clear
			qui svmat double `THi',   name(th)
			qui svmat double `THiSE', name(se)
			qui gen double lo = th`jv' - `z'*se`jv'
			qui gen double hi = th`jv' + `z'*se`jv'
			qui sort th`jv'
			qui gen long rank = _n
			* mean-group line = mean of the per-group estimates (always available)
			qui summarize th`jv', meanonly
			local mg = r(mean)
			local ylcmd ""
			if `mg' < . local ylcmd yline(`mg', lcolor("`c4'") lwidth(medthin) lpattern(dash))

			#delimit ;
			twoway (rarea lo hi rank, sort fcolor("26 78 126%12") lcolor(none))
			       (rcap lo hi rank, lcolor("`ccap'%55") lwidth(vthin))
			       (scatter th`jv' rank, msymbol(O) msize(small)
			        mcolor("26 78 126%85") mlcolor(white) mlwidth(vthin)),
				`ylcmd'
				title("{bf:Cross-panel heterogeneity:} `v'", size(medium) color(black))
				subtitle("per-group {&theta}{sub:i} with `=`level''% CIs; dashed line = mean group",
					size(vsmall) color(gs6))
				ytitle("Long-run {&theta}{sub:i}", size(small))
				xtitle("Panel (sorted by {&theta}{sub:i})", size(small))
				ylabel(, angle(0) labsize(vsmall) format(%4.1f)
					grid glcolor(gs15) glwidth(vthin))
				xlabel(, labsize(vsmall))
				legend(off)
				graphregion(fcolor(white) lcolor(white) margin(small))
				plotregion(fcolor(white) lcolor(gs13))
				scheme(s2color)
				name(`gname'_het`jv', replace) ;
			#delimit cr
		}
		if `nv' == 1 capture graph rename `gname'_het1 `gname'_het, replace
		if `nv' == 1 di in gr "  Graph saved: " in ye "`gname'_het"
		else di in gr "  Graphs saved: " in ye "`gname'_het1 ... `gname'_het`nv'"
	}
	if _rc di in error "  (heterogeneity plot skipped, rc=" _rc ")"

	restore
	if "`gsave'" != "" set graphics `gsave'
	di in gr "  Tip: export with " in ye `"graph export fig.png, name(`gname'_lr) replace"'
end


* ---- forest-plot helper (one panel per variable, combined) -----------
program define xtle_forest
	syntax , b(name) se(name) vars(string) meth(string) ///
		pretty(string asis) methods(string) z(real) ///
		gname(string) kind(string) ///
		c1(string) c2(string) c3(string) c4(string) ccap(string)

	* present method rows in meth order (shared across variables)
	local pm ""
	local r 0
	foreach m of local meth {
		local ++r
		local w : list posof "`m'" in methods
		if `w' local pm "`pm' `r'"
	}
	local M : word count `pm'
	if `M' == 0 exit
	local nv : word count `vars'
	local mgrow : list posof "mg" in meth

	* one clean forest figure per variable (no by(), no graph combine)
	local jv 0
	foreach v of local vars {
		local ++jv
		clear
		qui set obs `M'
		qui gen long ypos = _n
		qui gen double est = .
		qui gen double lo  = .
		qui gen double hi  = .
		qui gen byte   fam = .

		local yl ""
		local i 0
		foreach r of local pm {
			local ++i
			local lbl : word `r' of `pretty'
			local yl `"`yl' `i' "`lbl'""'
			local bb = `b'[`r', `jv']
			local ss = `se'[`r', `jv']
			qui replace est = `bb' in `i'
			if `ss' != . & `ss' > 0 {
				qui replace lo = `bb' - `z'*`ss' in `i'
				qui replace hi = `bb' + `z'*`ss' in `i'
			}
			local mname : word `r' of `meth'
			local f 1
			if inlist("`mname'","nbc","dbc1","dbc2","bsbc","bcmg") local f 2
			if inlist("`mname'","ebayes","hbayes") local f 3
			if "`mname'" == "pols" local f 4
			qui replace fam = `f' in `i'
		}

		local xlcmd ""
		if `mgrow' > 0 {
			local mgv = `b'[`mgrow', `jv']
			if `mgv' != . local xlcmd xline(`mgv', lcolor("`c1'%60") lwidth(thin) lpattern(dash))
		}

		#delimit ;
		twoway (rcap lo hi ypos, horizontal lcolor("`ccap'") lwidth(medthin))
		       (scatter ypos est if fam==1, msymbol(O) msize(medium)
		        mcolor("`c1'") mlcolor(white) mlwidth(vthin))
		       (scatter ypos est if fam==2, msymbol(D) msize(medium)
		        mcolor("`c2'") mlcolor(white) mlwidth(vthin))
		       (scatter ypos est if fam==3, msymbol(S) msize(medium)
		        mcolor("`c3'") mlcolor(white) mlwidth(vthin))
		       (scatter ypos est if fam==4, msymbol(T) msize(medium)
		        mcolor("`c4'") mlcolor(white) mlwidth(vthin)),
			`xlcmd'
			title("{bf:`kind':} `v'", size(medium) color(black))
			subtitle("point estimate with `=round((1-2*normal(-`z'))*100)'% CI; dashed = mean group",
				size(vsmall) color(gs6))
			xtitle("Coefficient", size(small))
			ytitle("")
			ylabel(`yl', angle(0) labsize(vsmall) nogrid)
			yscale(reverse range(0.5 `=`M'+0.5'))
			xlabel(, labsize(vsmall) format(%4.1f) grid glcolor(gs15) glwidth(vthin))
			legend(order(2 "Uncorrected" 3 "Bias-corrected" 4 "Bayes" 5 "Pooled")
				rows(1) size(vsmall) region(lcolor(gs14) fcolor(white)) position(6))
			graphregion(fcolor(white) lcolor(white) margin(small))
			plotregion(fcolor(white) lcolor(gs13))
			scheme(s2color)
			name(`gname'`jv', replace) ;
		#delimit cr
	}

	if `nv' == 1 {
		capture graph rename `gname'1 `gname', replace
		di in gr "  Graph saved: " in ye "`gname'"
	}
	else di in gr "  Graphs saved: " in ye "`gname'1 ... `gname'`nv'" in gr " (one per variable)"
end


* =========================================================================
* MATA ENGINE
* =========================================================================
version 15.1
mata:

// ---------- ordinary least squares -------------------------------------
// returns b (k x 1); fills V (k x k), s2, resid (T x 1) through pointers
real colvector xtle_ols(real matrix Z, real colvector y,
                        real matrix V, real scalar s2, real colvector e)
{
	real matrix  ZZinv
	real colvector b
	real scalar  T, k

	T = rows(Z)
	k = cols(Z)
	ZZinv = invsym(quadcross(Z, Z))
	b = ZZinv * quadcross(Z, y)
	e = y - Z * b
	if (T - k > 0) {
		s2 = (e' * e) / (T - k)
	} else {
		s2 = (e' * e) / T
	}
	V = s2 * ZZinv
	return (b)
}

// ---------- draw from N(mu, S) -----------------------------------------
real colvector xtle_mvn(real colvector mu, real matrix S)
{
	real matrix C
	real scalar k
	k = rows(mu)
	C = cholesky(makesymmetric(S))
	return (mu + C * rnormal(k, 1, 0, 1))
}

// ---------- Wishart draw: W ~ Wishart(Scale, df), k x k ----------------
real matrix xtle_wishart(real matrix Scale, real scalar df)
{
	real matrix L, A
	real scalar k, i, j
	k = rows(Scale)
	L = cholesky(makesymmetric(Scale))
	A = J(k, k, 0)
	for (i = 1; i <= k; i++) {
		A[i, i] = sqrt(rchi2(1, 1, df - i + 1))
		for (j = 1; j < i; j++) {
			A[i, j] = rnormal(1, 1, 0, 1)
		}
	}
	return (L * A * A' * L')
}

// ---------- delta-method variance of g = b/(1-lam) ---------------------
real scalar xtle_delta(real scalar lam, real scalar b,
                       real scalar vlam, real scalar vb, real scalar clb)
{
	real scalar d, glam, gb
	d = 1 - lam
	if (d == 0) {
		return (.)
	}
	gb   = 1 / d
	glam = b / (d * d)
	return (glam * glam * vlam + gb * gb * vb + 2 * glam * gb * clb)
}

// =======================================================================
// MAIN ENGINE
// =======================================================================
void xtle_engine(
	string scalar depv, string scalar lyv, string scalar xv,
	string scalar idv, string scalar tousev,
	real scalar hascons, string scalar lrposstr,
	real scalar reps, real scalar par, real scalar pdots,
	real scalar doMG, real scalar doNBC, real scalar doDBC1,
	real scalar doDBC2, real scalar doBSBC, real scalar doBCMG,
	real scalar doEB, real scalar doHB, real scalar doPOLS,
	real scalar need_boot, real scalar need_swamy, real scalar need_gibbs,
	real scalar burnin, real scalar draws, real scalar rho,
	string scalar oLRB, string scalar oLRSE,
	string scalar oSRB, string scalar oSRSE,
	string scalar oN, string scalar oTmin, string scalar oTmax,
	string scalar oTavg, string scalar oNobs,
	string scalar oTHi, string scalar oTHiSE, string scalar oBI,
	string scalar oBISE, string scalar oID)
{
	real colvector y, Ly, id, uid, lo, hi, lrpos
	real matrix    X, Z, V, allb, allV, alls2
	real scalar    N, k, kx, nlr, i, r, c
	real scalar    Nobs, j

	// --- read data (already sorted by id then t in the ado) ------------
	y  = st_data(., depv, tousev)
	Ly = st_data(., lyv,  tousev)
	X  = st_data(., xv,   tousev)
	id = st_data(., idv,  tousev)
	kx = cols(X)
	Nobs = rows(y)

	uid = uniqrows(id)
	N   = rows(uid)

	// panel row ranges (id is sorted ascending and contiguous)
	lo = J(N, 1, 0)
	hi = J(N, 1, 0)
	for (i = 1; i <= N; i++) {
		c = selectindex(id :== uid[i])
		lo[i] = c[1]
		hi[i] = c[rows(c)]
	}

	// design columns: [Ly, X, (1)]
	k = 1 + kx + hascons
	// long-run beta positions among regressors (1-based within betas)
	lrpos = strtoreal(tokens(lrposstr))'
	nlr = rows(lrpos)

	// --- per-panel OLS storage ------------------------------------------
	allb  = J(N, k, .)        // each row = b_i'
	allV  = J(N, k * k, .)    // vectorised V_i
	alls2 = J(N, 1, .)
	real colvector Tvec
	Tvec = J(N, 1, 0)

	real colvector b_i, e_i
	real matrix    Zi, Vi
	real scalar    s2_i
	V = J(k, k, 0)

	for (i = 1; i <= N; i++) {
		yi  = y[|lo[i] \ hi[i]|]
		Lyi = Ly[|lo[i] \ hi[i]|]
		Xi  = X[|lo[i], . \ hi[i], .|]
		Tvec[i] = rows(yi)
		if (hascons) {
			Zi = Lyi, Xi, J(rows(yi), 1, 1)
		} else {
			Zi = Lyi, Xi
		}
		s2_i = 0
		Vi = J(k, k, 0)
		b_i = xtle_ols(Zi, yi, Vi, s2_i, e_i=.)
		allb[i, .]  = b_i'
		allV[i, .]  = vec(Vi)'
		alls2[i]    = s2_i
	}

	// --- output containers ---------------------------------------------
	// LR rows: 1 mg 2 nbc 3 dbc1 4 dbc2 5 bsbc 6 bcmg 7 ebayes 8 hbayes 9 pols
	// SR rows: 1 pols 2 mg 3 bcmg 4 ebayes 5 hbayes
	real matrix LRB, LRSE, SRB, SRSE
	LRB  = J(9, nlr, .)
	LRSE = J(9, nlr, .)
	SRB  = J(5, kx + 1, .)
	SRSE = J(5, kx + 1, .)

	// convenience: lambda and beta vectors across panels
	real colvector lam
	real matrix    bet
	lam = allb[., 1]
	bet = allb[., 2..(1 + kx)]

	// ---------- (1) MEAN GROUP long-run ---------------------------------
	// per-panel theta for each LR var, then average + Pesaran-Smith var
	real matrix Theta
	Theta = J(N, nlr, .)
	for (j = 1; j <= nlr; j++) {
		c = lrpos[j] + 1            // column in allb for this beta
		Theta[., j] = allb[., c] :/ (1 :- lam)
	}
	if (doMG) {
		xtle_mgrow(Theta, LRB, LRSE, 1)
	}

	// per-panel SEs (delta method) and short-run coefficients, for plots
	real matrix ThetaSE, BI, BISE
	ThetaSE = J(N, nlr, .)
	BI = allb[., 1..(kx + 1)]
	BISE = J(N, kx + 1, .)
	for (i = 1; i <= N; i++) {
		Vi = rowshape(allV[i, .], k)
		for (c = 1; c <= kx + 1; c++) {
			BISE[i, c] = sqrt(Vi[c, c])
		}
		for (j = 1; j <= nlr; j++) {
			cpos = lrpos[j]
			ThetaSE[i, j] = sqrt(xtle_delta(allb[i, 1], allb[i, 1 + cpos],
			    Vi[1, 1], Vi[1 + cpos, 1 + cpos], Vi[1, 1 + cpos]))
		}
	}

	// ---------- short-run MEAN GROUP ------------------------------------
	if (doMG) {
		xtle_mgrow(allb[., 1..(kx + 1)], SRB, SRSE, 2)
	}

	// ---------- (per-panel bootstrap for bias terms) --------------------
	real matrix Blam, Bbet           // bias estimates per panel
	real scalar thetaR               // mean over reps of MG(theta) for BSBC
	real matrix bsbcAcc
	Blam = J(N, 1, 0)
	Bbet = J(N, kx, 0)
	bsbcAcc = J(1, nlr, 0)

	if (need_boot) {
		xtle_bootstrap(y, Ly, X, lo, hi, allb, alls2, Tvec, N, k, kx,
		    hascons, reps, par, pdots, lrpos, nlr, Blam, Bbet, bsbcAcc)
	}

	// ---------- (2) NBC : naive bias-corrected --------------------------
	if (doNBC) {
		real colvector lamC
		real matrix    betC, ThetaC
		lamC = lam - Blam
		betC = bet - Bbet
		ThetaC = J(N, nlr, .)
		for (j = 1; j <= nlr; j++) {
			ThetaC[., j] = betC[., lrpos[j]] :/ (1 :- lamC)
		}
		xtle_mgrow(ThetaC, LRB, LRSE, 2)
	}

	// ---------- (3,4) DBC1 / DBC2 ---------------------------------------
	if (doDBC1 | doDBC2) {
		real matrix Td1, Td2
		Td1 = J(N, nlr, .)
		Td2 = J(N, nlr, .)
		for (i = 1; i <= N; i++) {
			Vi = rowshape(allV[i, .], k)
			lami = lam[i]
			vlam = Vi[1, 1]
			for (j = 1; j <= nlr; j++) {
				cpos = lrpos[j]            // beta index
				bj   = bet[i, cpos]
				thj  = bj / (1 - lami)
				clb  = Vi[1, 1 + cpos]     // cov(lam, beta_j)
				Bb   = Bbet[i, cpos]
				Bl   = Blam[i]
				num  = (Bb + thj * Bl)
				// DBC2 : denominator (1-lambda)
				d2   = 1 - lami
				psi2 = ((1 - lami) * num + clb + thj * vlam) / (d2 * d2)
				Td2[i, j] = thj - psi2
				// DBC1 : denominator (1-lambda-B_lambda)
				d1   = 1 - lami - Bl
				if (d1 != 0) {
					psi1 = ((1 - lami - Bl) * num + clb + thj * vlam) / (d1 * d1)
					Td1[i, j] = thj - psi1
				}
			}
		}
		if (doDBC1) xtle_mgrow(Td1, LRB, LRSE, 3)
		if (doDBC2) xtle_mgrow(Td2, LRB, LRSE, 4)
	}

	// ---------- (5) BSBC : bootstrap bias-corrected ---------------------
	if (doBSBC) {
		// theta_MG point already in Theta; mghat = colmean
		real rowvector mghat
		mghat = xtle_cmean(Theta)
		for (j = 1; j <= nlr; j++) {
			LRB[5, j] = 2 * mghat[j] - bsbcAcc[j]
			// SE: same asymptotic cross-panel variance as MG
			LRSE[5, j] = xtle_mgse(Theta[., j])
		}
	}

	// ---------- (6) BIAS-CORRECTED MEAN GROUP (short-run) ---------------
	if (doBCMG) {
		real matrix bC
		bC = J(N, kx + 1, .)
		bC[., 1] = lam - Blam
		bC[., 2..(kx + 1)] = bet - Bbet
		xtle_mgrow(bC, SRB, SRSE, 3)
		// implied long-run = mean(betaC)/(1-mean(lamC))
		real rowvector mb
		mb = xtle_cmean(bC)
		for (j = 1; j <= nlr; j++) {
			LRB[6, j]  = mb[1 + lrpos[j]] / (1 - mb[1])
			LRSE[6, j] = xtle_mgse(Theta[., j])
		}
	}

	// ---------- (9) POOLED OLS ------------------------------------------
	if (doPOLS) {
		real matrix Zall, Vp
		real colvector bp, ep
		real scalar s2p
		if (hascons) {
			Zall = Ly, X, J(Nobs, 1, 1)
		} else {
			Zall = Ly, X
		}
		s2p = 0
		Vp = J(k, k, 0)
		bp = xtle_ols(Zall, y, Vp, s2p, ep=.)
		// short-run row 1
		for (c = 1; c <= kx + 1; c++) {
			SRB[1, c]  = bp[c]
			SRSE[1, c] = sqrt(Vp[c, c])
		}
		// long-run via delta method
		for (j = 1; j <= nlr; j++) {
			cpos = lrpos[j]
			bj   = bp[1 + cpos]
			LRB[9, j] = bj / (1 - bp[1])
			vg = xtle_delta(bp[1], bj, Vp[1,1], Vp[1+cpos,1+cpos], Vp[1,1+cpos])
			LRSE[9, j] = sqrt(vg)
		}
	}

	// ---------- (7) EMPIRICAL BAYES (Swamy) -----------------------------
	real matrix Delta
	Delta = J(k, k, .)
	if (need_swamy) {
		Delta = xtle_swamy(allb, allV, alls2, N, k)
	}
	if (doEB) {
		xtle_ebayes(allb, allV, Delta, N, k, kx, lrpos, nlr, SRB, SRSE, LRB, LRSE)
	}

	// ---------- (8) HIERARCHICAL BAYES (Gibbs) --------------------------
	if (doHB) {
		xtle_gibbs(y, Ly, X, lo, hi, allb, alls2, Delta, Tvec, N, k, kx,
		    hascons, burnin, draws, rho, lrpos, nlr, pdots, SRB, SRSE, LRB, LRSE)
	}

	// --- export ---------------------------------------------------------
	st_matrix(oLRB,  LRB)
	st_matrix(oLRSE, LRSE)
	st_matrix(oSRB,  SRB)
	st_matrix(oSRSE, SRSE)
	st_numscalar(oN,    N)
	st_numscalar(oTmin, colmin(Tvec))
	st_numscalar(oTmax, colmax(Tvec))
	st_numscalar(oTavg, mean(Tvec))
	st_numscalar(oNobs, Nobs)
	st_matrix(oTHi,   Theta)
	st_matrix(oTHiSE, ThetaSE)
	st_matrix(oBI,    BI)
	st_matrix(oBISE,  BISE)
	st_matrix(oID,    uid)
}

// ---------- column means -----------------------------------------------
real rowvector xtle_cmean(real matrix M)
{
	return (colsum(M) :/ rows(M))
}

// ---------- Pesaran-Smith MG std error of one column -------------------
real scalar xtle_mgse(real colvector x)
{
	real scalar n, m, v
	n = rows(x)
	if (n < 2) {
		return (.)
	}
	m = sum(x) / n
	v = sum((x :- m) :^ 2) / (n * (n - 1))
	return (sqrt(v))
}

// ---------- standard deviation of a column -----------------------------
real scalar xtle_sd(real colvector x)
{
	real scalar n, m
	n = rows(x)
	if (n < 2) {
		return (.)
	}
	m = sum(x) / n
	return (sqrt(sum((x :- m) :^ 2) / (n - 1)))
}

// ---------- fill a method row with MG mean + Pesaran-Smith se ----------
void xtle_mgrow(real matrix M, real matrix B, real matrix SE, real scalar row)
{
	real scalar j, ncol
	ncol = cols(M)
	for (j = 1; j <= ncol; j++) {
		B[row, j]  = mean(M[., j])
		SE[row, j] = xtle_mgse(M[., j])
	}
}

// =======================================================================
// BOOTSTRAP : per-panel bias terms (Blam, Bbet) and BSBC accumulator
// =======================================================================
void xtle_bootstrap(real colvector y, real colvector Ly, real matrix X,
	real colvector lo, real colvector hi, real matrix allb,
	real colvector alls2, real colvector Tvec, real scalar N,
	real scalar k, real scalar kx, real scalar hascons,
	real scalar reps, real scalar par, real scalar pdots,
	real colvector lrpos, real scalar nlr,
	real matrix Blam, real matrix Bbet, real matrix bsbcAcc)
{
	real scalar i, r, t, Ti, c, j, row
	real matrix  bstar_lam, bstar_bet, repThetaMG, repTheta
	real colvector yi, Lyi, ei, ec, idx, ystar, Lystar, bb, betarow, estar
	real matrix  Xi, Zs, Vs
	real scalar  cons_i, lam_i, s2_i, ss, yprev, xcontrib

	bstar_lam = J(N, reps, .)
	bstar_bet = J(N * kx, reps, .)
	repThetaMG = J(reps, nlr, 0)

	if (pdots) {
		printf("{txt}Bootstrap (%g reps): ", reps)
		displayflush()
	}

	for (r = 1; r <= reps; r++) {
		repTheta = J(N, nlr, .)
		for (i = 1; i <= N; i++) {
			Ti  = Tvec[i]
			yi  = y[|lo[i] \ hi[i]|]
			Lyi = Ly[|lo[i] \ hi[i]|]
			Xi  = X[|lo[i], . \ hi[i], .|]
			lam_i = allb[i, 1]
			betarow = allb[i, 2..(1 + kx)]'
			if (hascons) {
				cons_i = allb[i, k]
			} else {
				cons_i = 0
			}
			// residuals (centered) for nonparametric resampling
			if (hascons) {
				ei = yi - (Lyi * lam_i + Xi * betarow :+ cons_i)
			} else {
				ei = yi - (Lyi * lam_i + Xi * betarow)
			}
			ec = ei :- mean(ei)
			s2_i = alls2[i]

			// draw errors
			if (par) {
				estar = rnormal(Ti, 1, 0, sqrt(s2_i))
			} else {
				idx = 1 :+ floor(runiform(Ti, 1) :* Ti)
				estar = ec[idx]
			}

			// recursive generation of y*
			ystar = J(Ti, 1, 0)
			yprev = Lyi[1]
			for (t = 1; t <= Ti; t++) {
				xcontrib = (Xi[t, .] * betarow)
				ystar[t] = cons_i + lam_i * yprev + xcontrib + estar[t]
				yprev = ystar[t]
			}
			Lystar = Lyi[1] \ ystar[|1 \ Ti - 1|]

			if (hascons) {
				Zs = Lystar, Xi, J(Ti, 1, 1)
			} else {
				Zs = Lystar, Xi
			}
			ss = 0
			Vs = J(k, k, 0)
			bb = xtle_ols(Zs, ystar, Vs, ss, ev=.)
			bstar_lam[i, r] = bb[1]
			bstar_bet[((i - 1) * kx + 1)..(i * kx), r] = bb[2..(1 + kx)]
			for (j = 1; j <= nlr; j++) {
				repTheta[i, j] = bb[1 + lrpos[j]] / (1 - bb[1])
			}
		}
		// MG over panels of this rep's theta
		for (j = 1; j <= nlr; j++) {
			repThetaMG[r, j] = mean(repTheta[., j])
		}
		if (pdots & mod(r, ceil(reps / 25)) == 0) {
			printf(".")
			displayflush()
		}
	}
	if (pdots) {
		printf(" done\n")
		displayflush()
	}

	// bias estimates  B = mean(bstar) - bhat
	for (i = 1; i <= N; i++) {
		Blam[i] = mean(bstar_lam[i, .]') - allb[i, 1]
		for (c = 1; c <= kx; c++) {
			row = (i - 1) * kx + c
			Bbet[i, c] = mean(bstar_bet[row, .]') - allb[i, 1 + c]
		}
	}
	// BSBC accumulator = mean over reps of MG(theta)
	for (j = 1; j <= nlr; j++) {
		bsbcAcc[j] = mean(repThetaMG[., j])
	}
}

// =======================================================================
// SWAMY estimate of Delta (heterogeneity covariance)
// =======================================================================
real matrix xtle_swamy(real matrix allb, real matrix allV,
                       real colvector alls2, real scalar N, real scalar k)
{
	real matrix Delta, S, Vi, meanV
	real rowvector mb
	real scalar i
	mb = colsum(allb) :/ N
	S = J(k, k, 0)
	for (i = 1; i <= N; i++) {
		d = (allb[i, .] - mb)'
		S = S + d * d'
	}
	S = S / (N - 1)
	meanV = J(k, k, 0)
	for (i = 1; i <= N; i++) {
		meanV = meanV + rowshape(allV[i, .], k)
	}
	meanV = meanV / N
	Delta = S - meanV
	// drop the (negative) correction term if not positive definite
	if (xtle_isposdef(Delta) == 0) {
		Delta = S
	}
	return (Delta)
}

real scalar xtle_isposdef(real matrix A)
{
	real matrix C
	real scalar k, i
	k = rows(A)
	C = cholesky(makesymmetric(A))
	for (i = 1; i <= k; i++) {
		if (C[i, i] <= 0 | C[i, i] == .) {
			return (0)
		}
	}
	return (1)
}

// =======================================================================
// EMPIRICAL BAYES (Swamy) estimator, eq (7)
// =======================================================================
void xtle_ebayes(real matrix allb, real matrix allV, real matrix Delta,
	real scalar N, real scalar k, real scalar kx,
	real colvector lrpos, real scalar nlr,
	real matrix SRB, real matrix SRSE, real matrix LRB, real matrix LRSE)
{
	real matrix Prec, Vi, Wi, Veb
	real colvector thetaEB
	real scalar i, c, j

	Prec = J(k, k, 0)
	for (i = 1; i <= N; i++) {
		Vi = rowshape(allV[i, .], k)
		Prec = Prec + invsym(makesymmetric(Vi + Delta))
	}
	Veb = invsym(makesymmetric(Prec))     // posterior variance of theta-bar
	thetaEB = J(k, 1, 0)
	for (i = 1; i <= N; i++) {
		Vi = rowshape(allV[i, .], k)
		Wi = Veb * invsym(makesymmetric(Vi + Delta))
		thetaEB = thetaEB + Wi * allb[i, .]'
	}
	// short-run row 4
	for (c = 1; c <= kx + 1; c++) {
		SRB[4, c]  = thetaEB[c]
		SRSE[4, c] = sqrt(Veb[c, c])
	}
	// long-run via delta method, row 7
	for (j = 1; j <= nlr; j++) {
		cpos = lrpos[j]
		bj = thetaEB[1 + cpos]
		LRB[7, j] = bj / (1 - thetaEB[1])
		vg = xtle_delta(thetaEB[1], bj, Veb[1,1], Veb[1+cpos,1+cpos], Veb[1,1+cpos])
		LRSE[7, j] = sqrt(vg)
	}
}

// =======================================================================
// HIERARCHICAL BAYES via Gibbs sampling
//   full conditionals (Hsiao, Pesaran & Tahmiscioglu 1999, p.275):
//   theta_i | . ~ N(A_i(Z_i'y_i/s2_i + Dinv tbar), A_i),
//                  A_i=(Z_i'Z_i/s2_i + Dinv)^-1
//   tbar   | . ~ N(mean(theta_i), Delta/N)            (diffuse prior on tbar)
//   Dinv   | . ~ Wishart((sum(t_i-tbar)(.)'+rho*R)^-1, rho+N)
//   s2_i   | . ~ InvGamma(T_i/2, e_i'e_i/2)
// =======================================================================
void xtle_gibbs(real colvector y, real colvector Ly, real matrix X,
	real colvector lo, real colvector hi, real matrix allb,
	real colvector alls2, real matrix Delta, real colvector Tvec,
	real scalar N, real scalar k, real scalar kx, real scalar hascons,
	real scalar burnin, real scalar draws, real scalar rho,
	real colvector lrpos, real scalar nlr, real scalar pdots,
	real matrix SRB, real matrix SRSE, real matrix LRB, real matrix LRSE)
{
	real scalar it, total, i, j, c, Ti, d2, Nobs, ss
	real matrix  theta, Dinv, R, Ai, Si, Zi, Zfull, ZZstack, Zystack, ZZi
	real colvector s2, tbar, yi, ev, mi, mbar, d, Zyi
	real matrix  keepTbar, keepLR

	total = burnin + draws
	Nobs = rows(y)
	// initialise
	theta = allb                       // N x k
	s2    = alls2
	tbar  = (colsum(allb) :/ N)'
	if (xtle_isposdef(Delta) == 0) {
		Delta = I(k)
	}
	Dinv = invsym(makesymmetric(Delta))
	R    = Delta                       // prior scale = Swamy estimate

	// full design and per-panel stacked Z'Z, Z'y (no pointers)
	if (hascons) {
		Zfull = Ly, X, J(Nobs, 1, 1)
	} else {
		Zfull = Ly, X
	}
	ZZstack = J(N * k, k, 0)
	Zystack = J(N * k, 1, 0)
	for (i = 1; i <= N; i++) {
		Zi = Zfull[|lo[i], . \ hi[i], .|]
		yi = y[|lo[i] \ hi[i]|]
		ZZstack[|(i - 1) * k + 1, 1 \ i * k, k|] = quadcross(Zi, Zi)
		Zystack[|(i - 1) * k + 1, 1 \ i * k, 1|] = quadcross(Zi, yi)
	}

	keepTbar = J(draws, k, 0)
	keepLR   = J(draws, nlr, 0)

	if (pdots) {
		printf("{txt}Gibbs sampler (%g burn-in + %g draws): ", burnin, draws)
		displayflush()
	}

	for (it = 1; it <= total; it++) {
		// 1) theta_i
		for (i = 1; i <= N; i++) {
			ZZi = ZZstack[|(i - 1) * k + 1, 1 \ i * k, k|]
			Zyi = Zystack[|(i - 1) * k + 1, 1 \ i * k, 1|]
			Ai = invsym(makesymmetric(ZZi :/ s2[i] + Dinv))
			mi = Ai * (Zyi :/ s2[i] + Dinv * tbar)
			theta[i, .] = xtle_mvn(mi, Ai)'
		}
		// 2) tbar  (diffuse prior -> N(mean theta, Delta/N))
		mbar = (colsum(theta) :/ N)'
		tbar = xtle_mvn(mbar, invsym(makesymmetric(Dinv * N)))
		// 3) Dinv via Wishart
		Si = J(k, k, 0)
		for (i = 1; i <= N; i++) {
			d = (theta[i, .]' - tbar)
			Si = Si + d * d'
		}
		Dinv = xtle_wishart(invsym(makesymmetric(Si + rho * R)), rho + N)
		// 4) s2_i via inverse gamma
		for (i = 1; i <= N; i++) {
			yi = y[|lo[i] \ hi[i]|]
			Zi = Zfull[|lo[i], . \ hi[i], .|]
			ev = yi - Zi * theta[i, .]'
			Ti = Tvec[i]
			ss = (ev' * ev) / 2
			s2[i] = 1 / rgamma(1, 1, Ti / 2, 1 / ss)
		}
		// store
		if (it > burnin) {
			d2 = it - burnin
			keepTbar[d2, .] = tbar'
			for (j = 1; j <= nlr; j++) {
				keepLR[d2, j] = tbar[1 + lrpos[j]] / (1 - tbar[1])
			}
		}
		if (pdots & mod(it, ceil(total / 25)) == 0) {
			printf(".")
			displayflush()
		}
	}
	if (pdots) {
		printf(" done\n")
		displayflush()
	}

	// posterior means / sds
	for (c = 1; c <= kx + 1; c++) {
		SRB[5, c]  = mean(keepTbar[., c])
		SRSE[5, c] = xtle_sd(keepTbar[., c])
	}
	for (j = 1; j <= nlr; j++) {
		LRB[8, j]  = mean(keepLR[., j])
		LRSE[8, j] = xtle_sd(keepLR[., j])
	}
}

end
