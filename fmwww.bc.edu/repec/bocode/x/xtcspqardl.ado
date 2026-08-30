*! xtcspqardl v1.1.0  29aug2026
*! Dr Merwan Roudane  merwanroudane920@gmail.com  github.com/merwanroudane
*! Cross-Sectionally Augmented Panel Quantile ARDL (CS-PQARDL),
*! Quantile CCE Mean Group (QCCEMG) and Quantile CCE Pooled (QCCEPMG).
*!
*! Implements
*!   Harding, M., C. Lamarche and M. H. Pesaran (2018), "Common Correlated
*!     Effects Estimation of Heterogeneous Dynamic Panel Quantile Regression
*!     Models", USC-INET WP 18-11 / J. Applied Econometrics 35(3).
*!   Pesaran, M. H. (2006), Econometrica 74(4), 967-1012.
*!   Chudik, A. and M. H. Pesaran (2015), J. Econometrics 188(2), 393-420.
*!   Ul-Durar, S., Y. Bakkar, N. Arshed, S. Naveed and B. Zhang (2025),
*!     Research in International Business and Finance 73, 102543.

capture program drop xtcspqardl
program define xtcspqardl, eclass
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtcspqardl") error 301
		_xtcspq_display `0'
	}
	else _xtcspq_estimate `0'
end


* =====================================================================
* MAIN ESTIMATION DRIVER
* =====================================================================
capture program drop _xtcspq_estimate
program define _xtcspq_estimate, eclass
	syntax varlist(min=2 ts) [if] [in], TAU(numlist >0 <1 sort)     ///
		[ LR(varlist ts)                                        ///
		  CSA(varlist ts)                                       ///
		  P(integer 1) Q(string)                                ///
		  CR_lags(integer -1)                                   ///
		  QCCEMG QCCEPMG ECM                                    ///
		  UNITVCE(string) MINT(integer 0) NOCD                  ///
		  REPS(integer 100) SEED(string)                        ///
		  LEVel(cilevel)                                        ///
		  LRMG                                                  ///
		  FULL SRTable SHOWCsa UNITtable NOTABle SHOWIndividual ///
		  GRaph GRAPHOPTS(string asis) SCHeme(string) ]

	_xtcspqardl_mata

	* ================================================================
	* Validate and set up
	* ================================================================
	local ntau : word count `tau'
	if `ntau' < 1 {
		di as err "tau() must specify at least one quantile"
		exit 198
	}
	if "`qccemg'" != "" & "`qccepmg'" != "" {
		di as err "cannot specify both qccemg and qccepmg"
		exit 198
	}
	if "`level'" == "" local level = c(level)
	local zcrit = invnormal(1 - (100 - `level')/200)

	marksample touse
	qui tsset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if "`ivar'" == "" {
		di as err "data must be xtset (or tsset) as a panel"
		exit 459
	}

	tokenize `varlist'
	local depvar `1'
	mac shift
	local indepvars `*'
	local k : word count `indepvars'

	markout `touse' `depvar' `indepvars'

	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)
	local avg_T = round(`nobs' / `npanels')

	if "`q'" == "" local q "1"
	local isqmg = ("`qccemg'" != "" | "`qccepmg'" != "")
	if !`isqmg' & "`ecm'" == "" & "`lr'" == "" {
		di as err "lr() is required for the one-step CS-PQARDL"
		di as err "  e.g.  xtcspqardl D.y D.x1 D.x2, lr(L.y L.x1 L.x2) tau(0.5)"
		di as err "  or use ecm (two-step, levels), qccemg or qccepmg."
		exit 198
	}
	if "`ecm'" != "" & "`lr'" != "" {
		di as txt "note: lr() is ignored with ecm; the two-step form " ///
			"takes the level variables from the varlist."
		local lr ""
	}

	* ================================================================
	* CROSS-SECTIONAL AVERAGES  zbar_t = (ybar_t, xbar_t')'
	*
	* Which variables are averaged matters.  For QCCEMG the model is in
	* levels, so the augmentation set is (depvar, indepvars) -- HLP eq.
	* (2.11)-(2.12).  For CS-PQARDL the equation is a conditional ECM
	* whose LEVEL variables sit in lr(); Ul-Durar et al. (2025) eq. (2)
	* puts the cross-sectional averages of the LEVEL variables in the
	* long-run relation, so the augmentation set defaults to the base
	* variables of lr(), not to the differenced regressors.
	* csa() overrides either default.
	* ================================================================
	if "`csa'" != "" {
		qui tsrevar `csa', list
		local csabase "`r(varlist)'"
	}
	else if `isqmg' | "`ecm'" != "" {
		local csabase "`depvar' `indepvars'"
	}
	else {
		qui tsrevar `lr', list
		local csabase "`r(varlist)'"
	}
	local n_csa0 : word count `csabase'

	* Default pT: floor(T^{1/3}), the Chudik-Pesaran (2015) rate that
	* satisfies the pT^3/T -> 0 condition of HLP Theorems 2-4.
	if `cr_lags' < 0 local cr_lags = max(1, floor(`avg_T'^(1/3)))

	* Pre-evaluate every ts operator BEFORE any bysort: a `bysort tvar'
	* destroys the tsset sort registration.
	local csa_src ""
	local ci = 0
	foreach v of local csabase {
		local ++ci
		tempvar csrc`ci'
		qui gen double `csrc`ci'' = `v' if `touse'
		local csa_src "`csa_src' `csrc`ci''"
	}

	local csa_all ""
	local ci = 0
	foreach v of local csa_src {
		local ++ci
		tempvar cavg`ci'
		qui bysort `tvar': egen double `cavg`ci'' = mean(`v') if `touse'
		local csa_all "`csa_all' `cavg`ci''"
	}
	qui tsset

	local csa_lagged ""
	if `cr_lags' > 0 {
		local ci = 0
		foreach cv of local csa_all {
			local ++ci
			forvalues lag = 1/`cr_lags' {
				tempvar clag`ci'_`lag'
				qui gen double `clag`ci'_`lag'' = L`lag'.`cv' if `touse'
				local csa_lagged "`csa_lagged' `clag`ci'_`lag''"
			}
		}
	}
	local csa_full "`csa_all' `csa_lagged'"
	local n_csa : word count `csa_full'

	* Readable labels for the CSA block, in the order they are entered
	local csa_labels ""
	foreach v of local csabase {
		local csa_labels "`csa_labels' cs.`v'"
	}
	local ci = 0
	foreach v of local csabase {
		local ++ci
		forvalues lag = 1/`cr_lags' {
			local csa_labels "`csa_labels' L`lag'.cs.`v'"
		}
	}

	* ================================================================
	* DISPATCH
	* ================================================================
	if `isqmg' {
		local est_type = cond("`qccepmg'" != "", "qccepmg", "qccemg")
		local est_lab  = cond("`qccepmg'" != "",                    ///
			"Quantile CCE Pooled (QCCEPMG)",                    ///
			"Quantile CCE Mean Group (QCCEMG)")
		local pooledopt = cond("`qccepmg'" != "", "pooled", "")

		_xtcspqardl_qccemg, depvar(`depvar') indepvars(`indepvars')   ///
			tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse')   ///
			csavars(`csa_full') ncsaorig(`n_csa0')                ///
			crlags(`cr_lags') `pooledopt'                         ///
			unitvce(`unitvce') mint(`mint') `nocd' `showindividual'

		local coefnames "L.`depvar' `indepvars'"
		local lrnames   "`indepvars'"
		local pv = 1 + `k'
	}
	else {
		local est_type = cond("`ecm'" != "", "cspqardl_ecm", "cspqardl")
		local est_lab  = cond("`ecm'" != "",                        ///
			"CS-PQARDL, two-step (levels then differences)",    ///
			"CS-PQARDL, one-step conditional ECM")

		if "`ecm'" != "" {
			* Ul-Durar et al. (2025) two-step procedure:
			* eq. (2) in levels with the cross-sectional averages,
			* then eq. (3) in differences with the lagged residual.
			_xtcspqardl_ecm, depvar(`depvar') indepvars(`indepvars') ///
				reps(`reps') seed(`seed')                        ///
				tau(`tau') ivar(`ivar') tvar(`tvar')             ///
				touse(`touse') csavars(`csa_full')               ///
				crlags(`cr_lags') unitvce(`unitvce')             ///
				mint(`mint') `nocd' `showindividual'
		}
		else {
			_xtcspqardl_estimate, depvar(`depvar')                   ///
				indepvars(`indepvars')                           ///
				lrvars(`lr') p(`p') q(`q')                       ///
				tau(`tau') ivar(`ivar') tvar(`tvar')             ///
				touse(`touse') csavars(`csa_full')               ///
				crlags(`cr_lags') unitvce(`unitvce')             ///
				mint(`mint') `nocd' `showindividual'
		}

		local coefnames "`r(coefnames)'"
		local lrnames   "`r(lrnames)'"
		local srnames   "`r(srnames)'"
		local pv        = r(pblk)
	}

	local n_used = r(n_used)
	if `n_used' < 2 {
		di as err "fewer than two units could be estimated at every " ///
			"requested quantile"
		di as err "  units too short: " r(n_short) ///
			"   estimation failures: " r(n_failed) ///
			"   collinear: " r(n_omitted)
		exit 2000
	}

	tempname b V lr Vlr Glr hl hlse diag unitb unitok keep csab csaV sb sv
	matrix `b'     = r(b)
	matrix `V'     = r(V)
	matrix `lr'    = r(lr)
	matrix `Vlr'   = r(V_lr)
	matrix `Glr'   = r(G_lr)
	matrix `hl'    = r(halflife)
	matrix `hlse'  = r(halflife_se)
	matrix `diag'  = r(diag)
	matrix `unitb' = r(unit_b)
	matrix `unitok'= r(unit_ok)
	matrix `keep'  = r(keep)
	matrix `csab'  = r(csa_b)
	matrix `csaV'  = r(csa_V)
	local hassr = 0
	capture matrix `sb' = r(sr_b)
	if _rc == 0 {
		capture matrix `sv' = r(sr_V)
		if _rc == 0 local hassr = 1
	}

	local valid_panels = r(valid_panels)
	local n_short      = r(n_short)
	local n_failed     = r(n_failed)
	local n_omitted    = r(n_omitted)
	local n_csaomit    = r(n_csaomit)
	local pooled       = r(pooled)
	local unitvce      "`r(unitvce)'"
	local pfull        = r(pfull)
	local vcelab       "`r(vcelab)'"
	capture local n_pool = r(n_pool)

	local nlr : word count `lrnames'
	local nsr : word count `srnames'

	if `isqmg' {
		if `pooled' {
			local srcline "Pesaran (2006) inverse-variance pooling of the unit quantile estimates"
		}
		else {
			local srcline "Harding, Lamarche & Pesaran (2018), eq. (2.17), (2.20), (2.21)"
		}
	}
	else if "`ecm'" != "" {
		local srcline "Ul-Durar et al. (2025), eq. (2) and (3); two-step estimation"
	}
	else {
		local srcline "Conditional ECM with CCE augmentation (Pesaran & Shin 1999; Pesaran 2006)"
	}

	* ================================================================
	* Name the coefficient vectors: equation q<tau> per quantile so that
	* test / lincom / coefplot / esttab all work on the result.
	* ================================================================
	local eqn ""
	local cln ""
	local eqlr ""
	local cllr ""
	foreach tauval of local tau {
		local qs = string(`tauval'*100, "%03.0f")
		foreach cn of local coefnames {
			local eqn "`eqn' q`qs'"
			local cln "`cln' `cn'"
		}
		foreach cn of local lrnames {
			local eqlr "`eqlr' lr`qs'"
			local cllr "`cllr' `cn'"
		}
	}
	matrix colnames `b'  = `cln'
	matrix coleq    `b'  = `eqn'
	matrix rownames `V'  = `cln'
	matrix roweq    `V'  = `eqn'
	matrix colnames `V'  = `cln'
	matrix coleq    `V'  = `eqn'
	matrix colnames `lr' = `cllr'
	matrix coleq    `lr' = `eqlr'

	* Joint (short-run, long-run) coefficient vector and covariance:
	*   b* = (theta, lr),   V* = [[V, V G'],[G V, G V G']]
	tempname bj Vj VG
	matrix `bj' = `b' , `lr'
	matrix `VG' = `V' * `Glr''
	matrix `Vj' = ( `V' , `VG' ) \ ( `VG'' , `Vlr' )
	matrix rownames `Vj' = `cln' `cllr'
	matrix roweq    `Vj' = `eqn' `eqlr'
	matrix colnames `Vj' = `cln' `cllr'
	matrix coleq    `Vj' = `eqn' `eqlr'

	* ================================================================
	* HEADER + TABLES
	* ================================================================
	if "`notable'" == "" {
		_xtcspq_header, estlab("`est_lab'") depvar(`depvar')          ///
			ivar(`ivar') nobs(`nobs') npanels(`npanels')          ///
			nused(`n_used') avgt(`avg_T') crlags(`cr_lags')       ///
			ncsa(`n_csa') ncsa0(`n_csa0') csabase("`csabase'")    ///
			tau(`tau') pooled(`pooled') unitvce(`unitvce')        ///
			nshort(`n_short') nfailed(`n_failed')                 ///
			nomit(`n_omitted') ncsaomit(`n_csaomit')              ///
			srcline("`srcline'")

		if `isqmg' {
			_xtcspq_table, b(`b') v(`V') tau(`tau')               ///
				names(`coefnames') level(`level')             ///
				title("Short-run (impact) coefficients")      ///
				note("Mean group of the unit-by-unit CCE-augmented quantile regressions.")

			if `nlr' > 0 {
				_xtcspq_table, b(`lr') v(`Vlr') tau(`tau')    ///
					names(`lrnames') level(`level')       ///
					hl(`hl') hlse(`hlse')                 ///
					title("Long-run coefficients")        ///
					note("theta(tau) = beta(tau)/(1-lambda(tau)); delta-method SE includes Cov(beta,lambda)")
			}
		}
		else {
			if `nlr' > 0 {
				if "`ecm'" != "" {
					_xtcspq_table, b(`lr') v(`Vlr')      ///
						tau(`tau') names(`lrnames')  ///
						level(`level')               ///
						title("Long-run coefficients (step 1, pooled level regression)") ///
						note("Ul-Durar et al. (2025) eq. (2): levels plus cross-sectional averages.") ///
						vnote("Variance: `vcelab'.")
				}
				else {
					_xtcspq_table, b(`lr') v(`Vlr')      ///
						tau(`tau') names(`lrnames')  ///
						level(`level')               ///
						title("Long-run (cointegrating) coefficients") ///
						note("theta(tau) = -xi(tau)/phi(tau); delta-method SE includes Cov(xi,phi).")
				}
			}
			if "`ecm'" != "" {
				local ectitle "Short-run dynamics and error correction (step 2)"
				local ecnote  "Ul-Durar et al. (2025) eq. (3), mean group over units."
			}
			else {
				local ectitle "Error correction and level block"
				local ecnote  "ECT = phi(tau), the speed of adjustment; convergence needs -2 < phi < 0."
			}
			_xtcspq_table, b(`b') v(`V') tau(`tau')               ///
				names(`coefnames') level(`level')             ///
				hl(`hl') hlse(`hlse') ec                      ///
				title("`ectitle'") note("`ecnote'")
		}

		if "`srtable'" != "" & `nsr' > 0 & `hassr' {
			_xtcspq_table, b(`sb') v(`sv') tau(`tau')             ///
				names(`srnames') level(`level')               ///
				title("Short-run dynamics and error correction") ///
				note("Mean group of the unit-level short-run coefficients")
		}

		if "`showcsa'" != "" & `n_csa' > 0 {
			_xtcspq_table, b(`csab') v(`csaV') tau(`tau')         ///
				names(`csa_labels') level(`level')            ///
				title("Cross-sectional-average (CCE) coefficients") ///
				note("Proxies for the unobserved common factors f_t")
		}

		_xtcspq_diag, diag(`diag') tau(`tau') nused(`n_used')

		if "`unittable'" != "" {
			_xtcspq_units, unitb(`unitb') unitok(`unitok')        ///
				tau(`tau') pfull(`pfull') ids(`ids')          ///
				name("`: word 1 of `coefnames''")
		}
	}

	* ================================================================
	* POST RESULTS
	* ================================================================
	ereturn post `bj' `Vj', esample(`touse') obs(`nobs') depname(`depvar')

	ereturn matrix b_sr       = `b'
	ereturn matrix V_sr       = `V'
	ereturn matrix b_lr       = `lr'
	ereturn matrix V_lr       = `Vlr'
	ereturn matrix halflife   = `hl'
	ereturn matrix halflife_se= `hlse'
	ereturn matrix diagnostics= `diag'
	ereturn matrix unit_b     = `unitb'
	ereturn matrix unit_ok    = `unitok'
	ereturn matrix csa_b      = `csab'
	ereturn matrix csa_V      = `csaV'
	if `hassr' {
		ereturn matrix sr_b = `sb'
		ereturn matrix sr_V = `sv'
	}

	ereturn scalar N            = `nobs'
	ereturn scalar N_g          = `npanels'
	ereturn scalar N_used       = `n_used'
	ereturn scalar valid_panels = `valid_panels'
	ereturn scalar n_short      = `n_short'
	ereturn scalar n_failed     = `n_failed'
	ereturn scalar n_omitted    = `n_omitted'
	ereturn scalar k            = `k'
	ereturn scalar ntau         = `ntau'
	ereturn scalar cr_lags      = `cr_lags'
	ereturn scalar avg_T        = `avg_T'
	ereturn scalar level        = `level'
	ereturn scalar pooled       = `pooled'

	ereturn local tau        "`tau'"
	ereturn local depvar     "`depvar'"
	ereturn local indepvars  "`indepvars'"
	ereturn local lrvars     "`lr'"
	ereturn local csabase    "`csabase'"
	ereturn local csa_labels "`csa_labels'"
	ereturn local coefnames  "`coefnames'"
	ereturn local lrnames    "`lrnames'"
	ereturn local srnames    "`srnames'"
	ereturn local ivar       "`ivar'"
	ereturn local tvar       "`tvar'"
	ereturn local unitvce    "`unitvce'"
	ereturn local estimator  "`est_type'"
	ereturn local title      "`est_lab'"
	ereturn local properties "b V"
	ereturn local cmd        "xtcspqardl"

	* ================================================================
	* OPTIONAL EXTRAS
	* ================================================================
	if "`full'" != "" {
		_xtcspqardl_advanced, level(`level')
	}
	if "`graph'" != "" {
		xtcspqardl_graph, level(`level') scheme(`scheme') ///
			`graphopts'
	}
end


* =====================================================================
* HEADER
* =====================================================================
capture program drop _xtcspq_header
program define _xtcspq_header
	syntax , ESTLAB(string) DEPVAR(string) IVAR(string)              ///
		NOBS(integer) NPANELS(integer) NUSED(integer)            ///
		AVGT(integer) CRLAGS(integer) NCSA(integer)              ///
		NCSA0(integer) CSABASE(string) TAU(numlist)              ///
		POOLED(integer) UNITVCE(string)                          ///
		NSHORT(integer) NFAILED(integer) NOMIT(integer)          ///
		[ NCSAOMIT(string) SRCLINE(string) ]

	local ntau : word count `tau'
	local taustr ""
	foreach t of local tau {
		local taustr "`taustr' `: di %4.2f `t''"
	}
	local taustr = strtrim("`taustr'")

	di
	di as txt "{hline 74}"
	di as txt "{bf:`estlab'}"
	if `"`srcline'"' != "" di as txt `"`srcline'"'
	di as txt "{hline 74}"
	di as txt "Dependent variable" _col(28) "= " as res "`depvar'"          ///
	   as txt _col(48) "Observations"  _col(66) "= " as res %11.0fc `nobs'
	di as txt "Panel variable"     _col(28) "= " as res "`ivar'"            ///
	   as txt _col(48) "Units (N)"     _col(66) "= " as res %11.0fc `npanels'
	di as txt "Quantiles"          _col(28) "= " as res "`taustr'"          ///
	   as txt _col(48) "Units used"    _col(66) "= " as res %11.0fc `nused'
	di as txt "CS-average set"     _col(28) "= " as res "`csabase'"         ///
	   as txt _col(48) "Avg. T per unit" _col(66) "= " as res %11.0fc `avgt'
	di as txt "CSA lag order (pT)" _col(28) "= " as res %-11.0f `crlags'    ///
	   as txt _col(48) "CSA terms"     _col(66) "= " as res %11.0fc `ncsa'
	di as txt "Unit VCE"           _col(28) "= " as res "`unitvce'"
	if `nshort' + `nfailed' + `nomit' > 0 {
		di as txt "Units dropped: " as res `nshort' as txt " too short, " ///
			as res `nfailed' as txt " failed, "                      ///
			as res `nomit' as txt " collinear in a parameter of interest"
	}
	if "`ncsaomit'" != "" & "`ncsaomit'" != "0" & "`ncsaomit'" != "." {
		di as txt "Note: " as res "`ncsaomit'" as txt                      ///
			" CSA terms were dropped for collinearity in some units;" ///
			_n "      their mean-group averages are attenuated " ///
			"towards zero."
	}
end


* =====================================================================
* GENERIC COEFFICIENT TABLE (journal layout)
* =====================================================================
capture program drop _xtcspq_table
program define _xtcspq_table
	syntax , B(name) V(name) TAU(numlist) NAMES(string)              ///
		TITLE(string) [ NOTE(string) LEVel(cilevel)               ///
		HL(name) HLSE(name) EC VNOTE(string) ]

	if "`level'" == "" local level = c(level)
	local z = invnormal(1 - (100 - `level')/200)
	local nv : word count `names'
	local lstr = string(`level', "%2.0f")
	if `"`vnote'"' == "" {
		local vnote "Variance: nonparametric mean group, Vv = (1/(N-1)) sum (b_i-b)(b_i-b)'."
		local vnote2 "Reported SE = sqrt(Vv/N)."
	}

	di
	di as txt "{hline 74}"
	di as txt "{bf:`title'}"
	di as txt "{hline 74}"
	di as txt %13s "" "{c |}" %10s "Coef." %10s "Std. Err." %8s "z"      ///
		%8s "P>|z|" %20s "[`lstr'% Conf. Int.]"
	di as txt "{hline 13}{c +}{hline 60}"

	local ti = 0
	foreach tauval of local tau {
		local ++ti
		di as txt %13s "tau = `: di %4.2f `tauval''" "{c |}"
		forvalues j = 1/`nv' {
			local nm : word `j' of `names'
			local c  = (`ti' - 1) * `nv' + `j'
			local est = `b'[1, `c']
			local vv  = `v'[`c', `c']
			local se = .
			local zs = .
			local pp = .
			if `vv' > 0 & `vv' < . {
				local se = sqrt(`vv')
				local zs = `est' / `se'
				local pp = 2 * normal(-abs(`zs'))
			}
			local st ""
			if `pp' < 0.01      local st "***"
			else if `pp' < 0.05 local st "** "
			else if `pp' < 0.10 local st "*  "
			if "`ec'" != "" & `j' == 1 & `est' < . {
				if `est' >= 0 | `est' <= -2 local st "`st' !"
			}

			di as txt %13s abbrev("`nm'", 13) "{c |}" _c
			if `est' >= . {
				di as txt %10s "(dropped)"
				continue
			}
			di as res %10.4f `est' _c
			if `se' < . {
				di as res %10.4f `se' %8.2f `zs' %8.3f `pp' _c
				di as res %10.4f (`est' - `z'*`se') ///
					%10.4f (`est' + `z'*`se') _c
				di as txt " `st'"
			}
			else {
				di as txt %10s "." %8s "." %8s "." %10s "." %10s "."
			}
		}
		if "`hl'" != "" {
			local h = `hl'[1, `ti']
			if `h' < . {
				local hs = .
				capture local hs = `hlse'[1, `ti']
				di as txt %13s "Half-life" "{c |}" _c
				di as res %10.3f `h' _c
				if `hs' < . di as res %10.4f `hs'
				else        di as txt %10s "."
			}
		}
	}
	di as txt "{hline 13}{c BT}{hline 60}"
	di as txt "*** p<0.01, ** p<0.05, * p<0.10"
	if "`ec'" != "" ///
		di as txt "!   flags a coefficient outside the convergent range."
	if `"`note'"' != "" di as txt `"`note'"'
	di as txt `"`vnote'"'
	if `"`vnote2'"' != "" di as txt `"`vnote2'"'
end


* =====================================================================
* PER-QUANTILE DIAGNOSTICS
* =====================================================================
capture program drop _xtcspq_diag
program define _xtcspq_diag
	syntax , DIAG(name) TAU(numlist) NUSED(integer)

	di
	di as txt "{hline 73}"
	di as txt "{bf:Fit and specification diagnostics}"
	di as txt "{hline 73}"
	di as txt %19s "" %20s "Wald (slopes)" %18s "CD (Pesaran)"
	di as txt %9s "Quantile" %10s "Pseudo R1" %9s "chi2" %4s "df" %7s "p"  ///
		%9s "no CSA" %9s "with CSA" %7s "p" %9s "GJMO D"
	di as txt "{hline 73}"

	local ti = 0
	foreach tauval of local tau {
		local ++ti
		di as txt %9s "`: di %4.2f `tauval''" _c
		local r1 = `diag'[`ti', 1]
		local w  = `diag'[`ti', 2]
		local df = `diag'[`ti', 3]
		local wp = `diag'[`ti', 4]
		local cd = `diag'[`ti', 5]
		local cp = `diag'[`ti', 6]
		local py = `diag'[`ti', 7]
		local c0 = `diag'[`ti', 9]
		if `r1' < . di as res %10.4f `r1' _c
		else         di as txt %10s "." _c
		if `w'  < . di as res  %9.2f `w'  _c
		else         di as txt  %9s "." _c
		if `df' < . di as res  %4.0f `df' _c
		else         di as txt  %4s "." _c
		if `wp' < . di as res  %7.3f `wp' _c
		else         di as txt  %7s "." _c
		if `c0' < . di as res  %9.2f `c0' _c
		else         di as txt  %9s "." _c
		if `cd' < . di as res  %9.2f `cd' _c
		else         di as txt  %9s "." _c
		if `cp' < . di as res  %7.3f `cp' _c
		else         di as txt  %7s "." _c
		if `py' < . di as res  %9.2f `py'
		else         di as txt  %9s "."
	}
	di as txt "{hline 73}"
	if colsof(`diag') >= 13 {
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local sv = `diag'[`ti', 11]
			local sd = `diag'[`ti', 12]
			local sp = `diag'[`ti', 13]
			if `sv' < . {
				di as txt "  GJMO Swamy S(tau=" ///
					%4.2f `tauval' ") = " as res %9.2f `sv' ///
					as txt "  chi2(" as res %4.0f `sd' ///
					as txt ")  p = " as res %6.3f `sp'
			}
		}
		di as txt "{hline 73}"
	}
	di as txt "Pseudo R1  Koenker & Machado (1999), pooled over the `nused' units used."
	di as txt "Wald       H0: the slope coefficients at that quantile are jointly zero."
	di as txt "CD         Pesaran (2004) test, H0: no cross-sectional dependence, on"
	di as txt "           the residuals WITHOUT and WITH the cross-sectional averages."
	di as txt "           A large fall in |CD| is the evidence that the CCE"
	di as txt "           augmentation absorbed the common factors.  With the averages"
	di as txt "           included CD is biased negative by construction (residuals sum"
	di as txt "           to about zero across units), so read the change, not the level."
	di as txt "GJMO D     Galvao, Juhl, Montes-Rojas & Olmo (2017) standardized"
	di as txt "           Swamy test for slope homogeneity in QUANTILE panels,"
	di as txt "           D = sqrt(n)[S/n - k]/sqrt(2k) ~ N(0,1), one sided."
	di as txt "           Large values reject homogeneity and favour the mean"
	di as txt "           group over pooling.  The chi2 form S ~ chi2((n-1)k),"
	di as txt "           for large T and fixed n, is in e(diagnostics)."
	di as txt "           For the standalone test with the Powell kernel variance"
	di as txt "           and a HAC option, see {helpb xtqsh} (SSC)."
end


* =====================================================================
* UNIT-LEVEL HETEROGENEITY TABLE  (Ul-Durar et al. 2025, Table 9)
* =====================================================================
capture program drop _xtcspq_units
program define _xtcspq_units
	syntax , UNITB(name) UNITOK(name) TAU(numlist) PFULL(integer)     ///
		IDS(numlist) NAME(string)

	local ntau : word count `tau'
	local nid  : word count `ids'

	di
	di as txt "{hline 74}"
	di as txt "{bf:Unit-level persistence / adjustment: `name'}"
	di as txt "{hline 74}"
	di as txt %12s "Unit" _c
	foreach t of local tau {
		di as txt %12s "tau=`: di %4.2f `t''" _c
	}
	di ""
	di as txt "{hline 74}"

	local nconv = 0
	local convlist ""
	local pi = 0
	foreach i of local ids {
		local ++pi
		di as txt %12.0f `i' _c
		local anybad = 0
		local ti = 0
		foreach t of local tau {
			local ++ti
			local c = (`ti' - 1) * `pfull' + 1
			local v = `unitb'[`pi', `c']
			if `v' >= . {
				di as txt %12s "." _c
				local anybad = 1
			}
			else {
				di as res %12.4f `v' _c
				if `v' >= 0 | `v' <= -2 local anybad = 1
			}
		}
		di ""
		if `anybad' {
			local ++nconv
			local convlist "`convlist' `i'"
		}
	}
	di as txt "{hline 74}"
	di as txt "Units outside the stable adjustment range: " as res `nconv' ///
		as txt " of " as res `nid'
	if `nconv' > 0 & `nconv' <= 40 {
		di as txt "  " as res "`convlist'"
	}
end


* =====================================================================
* REPLAY
* =====================================================================
capture program drop _xtcspq_display
program define _xtcspq_display
	syntax [, LEVel(cilevel) ]
	if "`level'" == "" local level = e(level)
	di
	di as txt "{bf:`e(title)'}   (`e(cmd)', estimator `e(estimator)')"
	_coef_table, level(`level')
end
