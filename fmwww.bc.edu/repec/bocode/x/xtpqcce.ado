*! xtpqcce v1.0.0  20jun2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! github.com/merwanroudane
*! Panel Quantile Common Correlated Effects (CCE) Mean Group estimators
*! ---------------------------------------------------------------------
*!  qmg  : Quantile CCE Mean Group (QCCEMG / QMG), dynamic, standard QR
*!         Harding, Lamarche & Pesaran (2018) <doi:10.2139/ssrn.3242269>
*!  csqr : Convolution-Smoothed Quantile CCE Mean Group (CCEMG-CSQR)
*!         with two-step bias correction (smoothing-bias + split-panel
*!         jackknife). Zhang & Su (2026, JBES)
*!         <doi:10.1080/07350015.2026.2641575>
*! References: Pesaran (2006) <doi:10.1111/j.1468-0262.2006.00692.x>,
*!   Chudik & Pesaran (2015) <doi:10.1016/j.jeconom.2015.03.007>,
*!   Dhaene & Jochmans (2015) <doi:10.1093/restud/rdv007>,
*!   Fernandes, Guerre & Horta (2021) <doi:10.1080/07350015.2019.1660177>

capture program drop xtpqcce
program define xtpqcce, eclass sortpreserve
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtpqcce") error 301
		Display `0'
	}
	else Estimate `0'
end

* =====================================================================
* ESTIMATION DRIVER
* =====================================================================
program define Estimate, eclass
	syntax varlist(min=2 ts) [if] [in], Quantiles(numlist >0 <1 sort) ///
		[ QMG CSQR ///
		  Lags(integer -1) ///
		  CRLags(integer -1) ///
		  DETerministics(varlist ts) ///
		  BC ///
		  C0(real 0.5) ///
		  BWidth(real -1) ///
		  Jbw(integer 11) ///
		  noCONStant ///
		  Level(cilevel) ///
		  LRun ///
		  GRaph GRAPHExport(string) ///
		  noTABle noDOTs ]

	* -----------------------------------------------------------------
	* Estimator selection
	* -----------------------------------------------------------------
	if ("`qmg'" != "") + ("`csqr'" != "") > 1 {
		di as err "specify only one of {bf:qmg} or {bf:csqr}"
		exit 198
	}
	if ("`qmg'" == "") & ("`csqr'" == "") local qmg "qmg"   // default
	if ("`qmg'" != "") local est "qmg"
	else                local est "csqr"

	local tau "`quantiles'"
	local ntau : word count `tau'

	* -----------------------------------------------------------------
	* Panel setup
	* -----------------------------------------------------------------
	marksample touse
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if "`ivar'" == "" | "`tvar'" == "" {
		di as err "data must be {bf:xtset} as panel data (panel and time)"
		exit 459
	}
	if "`deterministics'" != "" markout `touse' `deterministics'

	* depvar / regressors
	gettoken depvar indepvars : varlist
	local indepvars : list retokenize indepvars
	local k : word count `indepvars'
	if `k' < 1 {
		di as err "at least one regressor in {it:varlist} is required"
		exit 198
	}

	* default dynamic order
	if `lags' < 0 {
		if "`est'" == "qmg" local lags 1
		else                local lags 0
	}
	if "`est'" == "csqr" & `lags' > 0 {
		di as err "{bf:csqr} (Zhang & Su 2026) is a static estimator; {bf:lags()} not allowed"
		exit 198
	}

	* panel dimensions
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)
	tempvar Tcount
	qui bysort `touse' `ivar' (`tvar') : gen long `Tcount' = _N if `touse'
	qui sum `Tcount' if `touse', meanonly
	local avg_T = round(`nobs' / `npanels')
	local minT = r(min)

	* default CSA lags pT = floor(Tbar^{1/3}) (Chudik & Pesaran 2015)
	if `crlags' < 0 {
		local crlags = floor(`avg_T'^(1/3))
		if `crlags' < 0 local crlags 0
	}

	* -----------------------------------------------------------------
	* Build cross-sectional averages z-bar_t = mean_i (y_it, x_it)
	* (pre-evaluate ts ops BEFORE bysort to keep tsset sort valid)
	* -----------------------------------------------------------------
	tempvar yplain
	qui gen double `yplain' = `depvar' if `touse'
	local xplain ""
	forvalues j = 1/`k' {
		local xj : word `j' of `indepvars'
		tempvar xp`j'
		qui gen double `xp`j'' = `xj' if `touse'
		local xplain "`xplain' `xp`j''"
	}

	tempvar csa_y
	qui bysort `tvar' : egen double `csa_y' = mean(`yplain') if `touse'
	local csa0 "`csa_y'"
	forvalues j = 1/`k' {
		tempvar csa_x`j'
		qui bysort `tvar' : egen double `csa_x`j'' = mean(`xp`j'') if `touse'
		local csa0 "`csa0' `csa_x`j''"
	}
	local n_csa0 = `k' + 1            // contemporaneous CSA dimension

	* restore tsset sort, then build CSA lags
	qui xtset `ivar' `tvar'
	local csalist "`csa0'"
	if `crlags' > 0 {
		foreach cv of local csa0 {
			forvalues l = 1/`crlags' {
				tempvar cl_`cv'_`l'
				qui gen double `cl_`cv'_`l'' = L`l'.`cv' if `touse'
				local csalist "`csalist' `cl_`cv'_`l''"
			}
		}
	}
	local n_csa : word count `csalist'

	* -----------------------------------------------------------------
	* Restrict estimation sample to rows with complete CSA proxies
	* (initial pT periods per panel are lost). CSA themselves were
	* computed over the full sample above, so this only trims the fit.
	* -----------------------------------------------------------------
	markout `touse' `csalist'
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)
	qui bysort `touse' `ivar' (`tvar') : replace `Tcount' = _N if `touse'
	qui sum `Tcount' if `touse', meanonly
	local avg_T = round(`nobs' / `npanels')
	local minT = r(min)
	qui xtset `ivar' `tvar'

	* -----------------------------------------------------------------
	* Header
	* -----------------------------------------------------------------
	if "`est'" == "qmg" {
		local estlab "QCCEMG  (Quantile CCE Mean Group)"
		local estcite "Harding, Lamarche & Pesaran (2018)"
	}
	else {
		local estlab "CCEMG-CSQR  (Convolution-Smoothed Quantile CCE MG)"
		local estcite "Zhang & Su (2026, JBES)"
		if "`bc'" != "" local estlab "`estlab', two-step bias-corrected"
	}
	di
	di as txt "{hline 78}"
	di as txt " {bf:xtpqcce}" _col(12) as res "`estlab'"
	di as txt _col(12) as txt "`estcite'"
	di as txt "{hline 78}"
	di as txt " Dependent variable {col 30}= " as res "`depvar'"
	di as txt " Regressors (x) {col 30}= " as res "`indepvars'"
	if "`est'" == "qmg" ///
	di as txt " Dynamic lags of y {col 30}= " as res "`lags'"
	di as txt " Panels (N) {col 30}= " as res "`npanels'"
	di as txt " Avg. obs per panel (T) {col 30}= " as res "`avg_T'"   ///
		as txt "   (min T = " as res "`minT'" as txt ")"
	di as txt " Total observations {col 30}= " as res "`nobs'"
	di as txt " CSA lags (pT) {col 30}= " as res "`crlags'"
	di as txt " CSA proxies in each unit {col 30}= " as res "`n_csa'" ///
		as txt " = " as res "`n_csa0'" as txt " x (1+" as res "`crlags'" as txt ")"
	di as txt " Quantiles {col 30}= " _c
	foreach q of local tau {
		di as res %4.2f `q' " " _c
	}
	di ""
	di as txt "{hline 78}"

	* -----------------------------------------------------------------
	* Dispatch to engine
	* -----------------------------------------------------------------
	if "`est'" == "qmg" {
		_xtpqcce_qmg, depvar(`depvar') indepvars(`indepvars') ///
			tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
			csa(`csalist') lags(`lags') `constant' `dots'
	}
	else {
		_xtpqcce_csqr, depvar(`depvar') indepvars(`indepvars') ///
			tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
			csa(`csalist') det("`deterministics'") c0(`c0') bw(`bwidth') ///
			jbw(`jbw') `bc' `constant' `dots'
	}

	local valid = r(valid_panels)
	local bw_used .
	if "`est'" == "csqr" local bw_used = r(bw)
	tempname b_i mg V SE
	matrix `b_i' = r(b_i)
	matrix `mg'  = r(mg)
	matrix `V'   = r(V)
	matrix `SE'  = r(SE)
	tempname lr_i lr_mg lr_V lr_SE hl_mg
	if "`est'" == "qmg" {
		matrix `lr_i'  = r(lr_i)
		matrix `lr_mg' = r(lr_mg)
		matrix `lr_V'  = r(lr_V)
		matrix `lr_SE' = r(lr_SE)
		matrix `hl_mg' = r(hl_mg)
	}
	tempname bc_mg
	if "`est'" == "csqr" & "`bc'" != "" {
		matrix `bc_mg' = r(bc_mg)
	}

	di as txt " {col 3}-> " as res "`valid'" as txt "/" as res "`npanels'" ///
		as txt " panels estimated successfully"
	if `valid' == 0 {
		di as err " no panel could be estimated"
		exit 2000
	}

	* -----------------------------------------------------------------
	* Display tables
	* -----------------------------------------------------------------
	local bcon = ("`bc'" != "")
	if "`table'" == "" {
		Tab_main, est(`est') tau(`tau') k(`k') indepvars(`indepvars') ///
			lags(`lags') mg(`mg') v(`V') se(`SE') bcon(`bcon') ///
			bcmg(`bc_mg') level(`level') depvar(`depvar')
		if "`est'" == "qmg" {
			Tab_speed, tau(`tau') lags(`lags') mg(`mg') v(`V') ///
				hl(`hl_mg') level(`level')
			if "`lrun'" != "" {
				Tab_lr, tau(`tau') k(`k') indepvars(`indepvars') ///
					mg(`lr_mg') v(`lr_V') se(`lr_SE') level(`level')
			}
		}
	}

	* -----------------------------------------------------------------
	* Post results to e()
	* -----------------------------------------------------------------
	tempname bmat vmat
	_xtpqcce_ebuild, est(`est') tau(`tau') k(`k') indepvars(`indepvars') ///
		lags(`lags') mg(`mg') v(`V') bcon(`bcon') bcmg(`bc_mg')
	matrix `bmat' = r(bpost)
	matrix `vmat' = r(vpost)

	capture ereturn post `bmat' `vmat', esample(`touse') obs(`nobs') depname(`depvar')
	if _rc {
		* fall back if a quantile block failed (missing in b/V)
		ereturn post, esample(`touse') obs(`nobs') depname(`depvar')
	}
	ereturn matrix b_i      = `b_i'
	ereturn matrix mg       = `mg'
	ereturn matrix V_mg     = `V'
	ereturn matrix SE       = `SE'
	if "`est'" == "qmg" {
		ereturn matrix lr_i   = `lr_i'
		ereturn matrix lr_mg  = `lr_mg'
		ereturn matrix lr_V   = `lr_V'
		ereturn matrix lr_SE  = `lr_SE'
		ereturn matrix hl_mg  = `hl_mg'
	}
	if "`est'" == "csqr" & "`bc'" != "" ereturn matrix bc_mg = `bc_mg'

	ereturn scalar N        = `nobs'
	ereturn scalar N_g      = `npanels'
	ereturn scalar g_valid  = `valid'
	ereturn scalar Tbar     = `avg_T'
	ereturn scalar Tmin     = `minT'
	ereturn scalar k        = `k'
	ereturn scalar ntau     = `ntau'
	ereturn scalar crlags   = `crlags'
	ereturn scalar lags     = `lags'
	ereturn scalar level    = `level'
	if "`est'" == "csqr" {
		ereturn scalar c0   = `c0'
		ereturn scalar bw   = `bw_used'
	}

	ereturn local tau       "`tau'"
	ereturn local depvar    "`depvar'"
	ereturn local indepvars "`indepvars'"
	ereturn local ivar      "`ivar'"
	ereturn local tvar      "`tvar'"
	ereturn local estimator "`est'"
	if "`est'" == "csqr" & "`bc'" != "" ereturn local biascorr "twostep"
	ereturn local title     "`estlab'"
	ereturn local cmd       "xtpqcce"
	ereturn local cmdline   "xtpqcce `0'"

	* -----------------------------------------------------------------
	* Graphs
	* -----------------------------------------------------------------
	if "`graph'" != "" {
		local gexp ""
		if "`graphexport'" != "" local gexp export("`graphexport'")
		xtpqcce_graph, `gexp'
	}

	di as txt "{hline 78}"
	if "`est'" == "qmg" ///
		di as txt " {bf:xtpqcce} (qmg). Significance: " ///
			as res "*** p<.01  ** p<.05  * p<.10"
	else ///
		di as txt " {bf:xtpqcce} (csqr). Significance: " ///
			as res "*** p<.01  ** p<.05  * p<.10"
	di as txt "{hline 78}"
end


* =====================================================================
* TABLE 1 : Mean-group coefficients on x (both estimators)
* =====================================================================
program define Tab_main
	syntax , est(string) tau(numlist) k(integer) indepvars(string) ///
		lags(integer) mg(string) v(string) se(string) bcon(integer) ///
		bcmg(string) level(integer) depvar(string)

	local z = invnormal(1 - (100-`level')/200)
	local ntau : word count `tau'

	di
	di as txt "{hline 78}"
	if "`est'" == "qmg" ///
		di as txt "  {bf:Short-run mean-group coefficients}  ({it:beta}, on x_it)"
	else ///
		di as txt "  {bf:Mean-group quantile coefficients}  ({it:beta}, on x_it)"
	di as txt "{hline 78}"
	di as txt %-14s "Variable" _col(15) %-7s "tau" ///
		_col(23) %11s "Coef." _col(35) %10s "Std.Err." ///
		_col(46) %9s "z" _col(56) %9s "P>|z|" ///
		_col(66) %11s "[`level'% CI]"
	di as txt "{hline 78}"

	local ti 0
	foreach q of local tau {
		local ++ti
		di as txt "  tau = " as res %4.2f `q' as txt " {hline 60}"
		forvalues j = 1/`k' {
			local xv : word `j' of `indepvars'
			local col = (`ti'-1)*`k' + `j'
			if `bcon' local est_val = `bcmg'[1, `col']
			else      local est_val = `mg'[1, `col']
			local se_val = `se'[1, `col']
			Row_one "`xv'" `q' `est_val' `se_val' `z'
		}
	}
	di as txt "{hline 78}"
	if `bcon' ///
		di as txt "  Coef. = bias-corrected MG (eq 3.10); SE from Omega-hat/N (eq 3.11-3.12)."
	else if "`est'" == "csqr" ///
		di as txt "  Coef. = CCEMG-CSQR (eq 2.10); SE from Omega-hat/N (eq 3.11-3.12)."
	else ///
		di as txt "  Coef. = MG average (eq 2.21); nonparametric MG SE (HLP 2018, sec 2.3)."
end

* ----- one coefficient row with stars and CI -----
program define Row_one
	args name q est se z
	if `se' < . & `se' > 0 {
		local zst = `est'/`se'
		local p = 2*(1-normal(abs(`zst')))
		local star ""
		if `p' < 0.01      local star "***"
		else if `p' < 0.05 local star "** "
		else if `p' < 0.10 local star "*  "
		local lo = `est' - `z'*`se'
		local hi = `est' + `z'*`se'
		di as txt %-14s abbrev("`name'",14) _col(15) as res %4.2f `q' ///
			_col(22) as res %11.4f `est' _col(34) as res %10.4f `se' ///
			_col(45) as res %9.3f `zst' _col(55) as res %9.3f `p' ///
			_col(64) as res %8.3f `lo' " " %8.3f `hi' as res " `star'"
	}
	else {
		di as txt %-14s abbrev("`name'",14) _col(15) as res %4.2f `q' ///
			_col(22) as res %11.4f `est' _col(34) as txt "      (se n/a)"
	}
end

* =====================================================================
* TABLE 2 : Speed of adjustment lambda(tau) + half-life (qmg only)
* =====================================================================
program define Tab_speed
	syntax , tau(numlist) lags(integer) mg(string) v(string) ///
		hl(string) level(integer)
	if `lags' < 1 exit
	local z = invnormal(1 - (100-`level')/200)
	local ntau : word count `tau'
	di
	di as txt "{hline 78}"
	di as txt "  {bf:Persistence / speed of adjustment}  lambda(tau) = sum of AR coefs"
	di as txt "{hline 78}"
	di as txt %-10s "tau" _col(13) %11s "lambda" _col(26) %10s "Std.Err." ///
		_col(38) %9s "P>|z|" _col(50) %11s "Half-life" _col(64) %12s "Persistence"
	di as txt "{hline 78}"
	local ti 0
	foreach q of local tau {
		local ++ti
		* lambda stored in mg as the last `lags' columns-group? It is stored
		* separately: column index = k*ntau + (ti-1)*lags + (1..lags), summed
		local lam = `mg'[1, colnumb(`mg',"lam_`ti'")]
		local lse = sqrt(`v'[colnumb(`v',"lam_`ti'"), colnumb(`v',"lam_`ti'")])
		local hlv = `hl'[1, `ti']
		local p .
		if `lse' < . & `lse' > 0 local p = 2*(1-normal(abs(`lam'/`lse')))
		* persistence label from the AR root |lambda| (|lambda|<1 = stationary)
		local al = abs(`lam')
		if `al' >= 1         local status "Nonstationary"
		else if `al' >= 0.90 local status "Very persist."
		else if `al' >= 0.70 local status "Persistent"
		else if `al' >= 0.40 local status "Moderate"
		else                 local status "Low persist."
		di as txt "  tau=" as res %4.2f `q' _col(13) as res %11.4f `lam' ///
			_col(26) as res %10.4f `lse' _col(38) as res %9.3f `p' ///
			_col(50) as res %11.2f `hlv' _col(64) as res %12s "`status'"
	}
	di as txt "{hline 78}"
	di as txt "  lambda from L.y coefficient(s); half-life = ln(.5)/ln(|lambda|)."
end

* =====================================================================
* TABLE 3 : Long-run effects theta(tau) = beta/(1-lambda) (qmg only)
* =====================================================================
program define Tab_lr
	syntax , tau(numlist) k(integer) indepvars(string) ///
		mg(string) v(string) se(string) level(integer)
	local z = invnormal(1 - (100-`level')/200)
	di
	di as txt "{hline 78}"
	di as txt "  {bf:Long-run effects}  theta(tau) = beta(tau)/(1 - lambda(tau))"
	di as txt "  Nonparametric MG inference on unit-level theta_i (HLP 2018)"
	di as txt "{hline 78}"
	di as txt %-14s "Variable" _col(15) %-7s "tau" ///
		_col(23) %11s "LR Coef." _col(35) %10s "Std.Err." ///
		_col(46) %9s "z" _col(56) %9s "P>|z|" _col(66) %11s "[`level'% CI]"
	di as txt "{hline 78}"
	local ti 0
	foreach q of local tau {
		local ++ti
		di as txt "  tau = " as res %4.2f `q' as txt " {hline 60}"
		forvalues j = 1/`k' {
			local xv : word `j' of `indepvars'
			local col = (`ti'-1)*`k' + `j'
			Row_one "`xv'" `q' (`mg'[1,`col']) (`se'[1,`col']) `z'
		}
	}
	di as txt "{hline 78}"
end


* =====================================================================
* REPLAY
* =====================================================================
program define Display
	syntax [, *]
	di
	di as txt " {bf:xtpqcce} results: " as res "`e(title)'"
	di as txt " estimator = " as res "`e(estimator)'" ///
		as txt ", N = " as res e(N_g) as txt ", Tbar = " as res e(Tbar)
	di as txt " (use {bf:ereturn list} / {bf:matrix list e(b_i)} for stored results)"
end


* The shared Mata helper xtpqcce_mgvar() is defined in _xtpqcce_qmg.ado
* (self-contained engines: each ado compiles the Mata it needs on load).
