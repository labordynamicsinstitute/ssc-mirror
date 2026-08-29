*! _xtpqardl_estimate v1.0.4 — Per-panel quantile regression engine
*! Called internally by xtpqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! v1.0.4: - the whole per-panel loop now runs inside Mata (see
*!           _xtpqardl_mlib.ado).  Stata's qreg costs about 35 ms per
*!           call, which made large N unusable; the Mata solver is
*!           roughly two orders of magnitude faster and reproduces
*!           qreg to ~1e-8 on the check-function objective.
*!         - full covariance matrix for ALL derived parameters (rho,
*!           beta, AR and short-run theta) at ALL quantiles, including
*!           the cross-quantile blocks the constancy Wald tests need.
*!         - optional robust / HAC / cluster per-panel VCEs.
*!         - genuine PMG long-run pooling + second-stage ECM.
*!         - exact half-life; per-panel storage in Mata (no matsize cap).
*! v1.0.3: Fixed multi-predictor "0 panels" bug — count obs across ALL vars
*! v1.0.2: Fixed obs counting (non-missing only), relaxed min-obs filter
*! v1.0.1: Pre-generates lagged variables to avoid qreg+tsop failures


capture program drop _xtpqardl_estimate
program define _xtpqardl_estimate, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) LRVARS(string) ///
		P(integer) QLAGS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) ///
		[NOCONStant VCE(string) BW(integer -1) KERNel(string) ///
		 POOLlr QUIETdiag]

	_xtpqardl_load

	* ----------------------------------------------------------------
	* Options
	* ----------------------------------------------------------------
	if "`vce'"    == "" local vce "mg"
	if "`kernel'" == "" local kernel "bartlett"
	local vce    = lower("`vce'")
	local kernel = lower("`kernel'")

	* ----------------------------------------------------------------
	* Parse
	* ----------------------------------------------------------------
	local k    : word count `indepvars'
	local k_lr : word count `lrvars'
	local ntau : word count `tau'
	local k_x  = `k_lr' - 1

	if `k_x' < 1 {
		di as err "lr() must contain the lagged dependent level plus at least one long-run regressor"
		exit 198
	}

	local nqlags : word count `qlags'
	if `nqlags' == 1 {
		forvalues j = 1/`k' {
			local q`j' = `qlags'
		}
	}
	else if `nqlags' == `k' {
		forvalues j = 1/`k' {
			local q`j' : word `j' of `qlags'
		}
	}
	else {
		di as err "qlags() must have 1 or k elements"
		exit 198
	}

	* ================================================================
	* Pre-generate every regressor as a plain variable
	* ================================================================
	tempvar dv_plain
	qui gen double `dv_plain' = `depvar' if `touse'
	local depvar_q "`dv_plain'"

	local lr_varlist ""
	forvalues j = 1/`k_lr' {
		local lrv : word `j' of `lrvars'
		tempvar lr_plain`j'
		qui gen double `lr_plain`j'' = `lrv' if `touse'
		local lr_varlist "`lr_varlist' `lr_plain`j''"
	}

	local indep_plain ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		tempvar x_plain`j'
		qui gen double `x_plain`j'' = `xvar' if `touse'
		local indep_plain "`indep_plain' `x_plain`j''"
	}

	local ar_varlist ""
	if `p' > 1 {
		forvalues lag = 1/`= `p' - 1' {
			tempvar ar_lag`lag'
			qui gen double `ar_lag`lag'' = L`lag'.`dv_plain' if `touse'
			local ar_varlist "`ar_varlist' `ar_lag`lag''"
		}
	}
	local ncoefs_ar = `p' - 1

	local sr_varlist ""
	local ncoefs_sr = 0
	forvalues j = 1/`k' {
		local xvar_p : word `j' of `indep_plain'
		local sr_varlist "`sr_varlist' `xvar_p'"
		local ++ncoefs_sr
		if `q`j'' > 1 {
			forvalues lag = 1/`= `q`j'' - 1' {
				tempvar sr_`j'_lag`lag'
				qui gen double `sr_`j'_lag`lag'' = L`lag'.`xvar_p' if `touse'
				local sr_varlist "`sr_varlist' `sr_`j'_lag`lag''"
				local ++ncoefs_sr
			}
		}
	}

	local fullreg      "`lr_varlist' `ar_varlist' `sr_varlist'"
	local ncoefs_total = `k_lr' + `ncoefs_ar' + `ncoefs_sr'
	local nrest        = `ncoefs_ar' + `ncoefs_sr'
	local M            = 1 + `k_x' + `nrest'
	local cons         = cond("`noconstant'" == "", 1, 0)

	* ================================================================
	* Estimation sample: touse AND every regressor observed
	* ================================================================
	tempvar useall
	qui gen byte `useall' = `touse'
	qui replace `useall' = 0 if missing(`depvar_q')
	foreach _rv of local fullreg {
		qui replace `useall' = 0 if missing(`_rv')
	}
	qui count if `useall'
	if r(N) == 0 {
		di as err "no observations with all PQARDL regressors non-missing"
		exit 2000
	}

	* ================================================================
	* Stage 1 — per-panel quantile ARDL (entirely in Mata)
	* ================================================================
	tempname taumat s_np s_skip s_fail s_ok
	matrix `taumat' = J(1, `ntau', .)
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		matrix `taumat'[1, `ti'] = `tauval'
	}

	mata: _xtpq_run("`depvar_q'", "`fullreg'", "`ivar'", "`tvar'", ///
		"`useall'", "`taumat'", `k_x', `nrest', `cons', ///
		"`vce'", `bw', "`kernel'", "`s_np'", "`s_skip'", "`s_fail'", "`s_ok'")

	local npanels       = `s_np'
	local skip_obs      = `s_skip'
	local skip_fit      = `s_fail'
	local success_count = `s_ok'

	if (`skip_obs' > 0 | `skip_fit' > 0) & "`quietdiag'" == "" {
		noi di in gr "    (Diagnostics: `skip_obs' panel(s) skipped [insufficient obs], `skip_fit' quantile fit failure(s))"
	}

	* ================================================================
	* Stage 2 — PMG: pool the long run, then re-estimate the ECM
	* ================================================================
	tempname beta_pool beta_pool_V
	local n_pool   = 0
	local poolmeth ""

	tempname g_mg1 g_Vnp1 g_Veff1 s_nmg1
	local have_mg1 = 0

	if "`poollr'" != "" & `success_count' > 0 {
		* unrestricted (MG) results are needed for the Hausman test
		mata: _xtpq_mg(`k_x', `nrest', "`g_mg1'", "`g_Vnp1'", ///
			"`g_Veff1'", "`s_nmg1'")
		local have_mg1 = 1

		tempname s_npool s_pmeth
		mata: _xtpq_pool_lr(`k_x', "`beta_pool'", "`beta_pool_V'", ///
			"`s_npool'", "`s_pmeth'")
		local n_pool = `s_npool'

		if `n_pool' >= 2 {
			local poolmeth = cond(`s_pmeth' == 1, "minimum distance", "equal weight")
			mata: _xtpq_run2("`beta_pool'")
		}
		else {
			noi di in gr "    (PMG pooling not feasible; falling back to MG)"
			local poollr ""
			local have_mg1 = 0
		}
	}

	* ================================================================
	* Mean-group averages and covariance matrices
	* ================================================================
	tempname g_mg g_Vnp g_Veff s_nmg
	mata: _xtpq_mg(`k_x', `nrest', "`g_mg'", "`g_Vnp'", "`g_Veff'", "`s_nmg'")
	local n_mg = `s_nmg'

	local haus  = .
	local hausdf = .
	local hausp = .

	if "`poollr'" != "" & `n_pool' >= 2 {
		mata: _xtpq_graft_pool(`k_x', `nrest', "`g_mg'", "`g_Vnp'", ///
			"`g_Veff'", "`beta_pool'", "`beta_pool_V'")

		* Hausman test of long-run homogeneity: MG (consistent) versus
		* PMG (efficient under H0).  H0 not rejected => pooling is valid.
		if `have_mg1' {
			tempname bmg bpm Vmg Vpm dif Vdif Vinv Hst
			local kd = `k_x' * `ntau'
			matrix `bmg' = J(1, `kd', .)
			matrix `bpm' = J(1, `kd', .)
			matrix `Vmg' = J(`kd', `kd', 0)
			matrix `Vpm' = J(`kd', `kd', 0)
			forvalues t = 1/`ntau' {
				local o = (`t' - 1) * `M'
				forvalues j = 1/`k_x' {
					local a = (`t' - 1) * `k_x' + `j'
					matrix `bmg'[1, `a'] = `g_mg1'[1, `o' + 1 + `j']
					matrix `bpm'[1, `a'] = `g_mg'[1, `o' + 1 + `j']
					forvalues l = 1/`k_x' {
						local b = (`t' - 1) * `k_x' + `l'
						matrix `Vmg'[`a', `b'] = `g_Vnp1'[`o' + 1 + `j', `o' + 1 + `l']
						matrix `Vpm'[`a', `b'] = `g_Vnp'[`o' + 1 + `j', `o' + 1 + `l']
					}
				}
			}
			capture {
				matrix `dif'  = `bmg' - `bpm'
				matrix `Vdif' = `Vmg' - `Vpm'
				matrix `Vinv' = syminv(`Vdif')
				matrix `Hst'  = `dif' * `Vinv' * `dif''
				local haus   = `Hst'[1, 1]
				local hausdf = `kd' - diag0cnt(`Vinv')
			}
			if `haus' < . & `haus' >= 0 & `hausdf' > 0 {
				local hausp = chi2tail(`hausdf', `haus')
			}
			else {
				local haus = .
				local hausdf = .
			}
		}
	}

	tempname g_V
	if "`vce'" == "mg" {
		matrix `g_V' = `g_Vnp'
	}
	else {
		matrix `g_V' = `g_Veff'
	}

	* ================================================================
	* Legacy views kept for the graph module and the Wald tests
	* ================================================================
	tempname rho_mg beta_mg phi_mg sr_mg halflife_mg rho_V beta_V
	tempname rho_all beta_all halflife_all phi_all sr_all panelids

	mata: _xtpq_legacy(`k_x', `ncoefs_ar', `ncoefs_sr', ///
		"`g_mg'", "`g_V'", "`rho_mg'", "`beta_mg'", "`phi_mg'", "`sr_mg'", ///
		"`rho_V'", "`beta_V'")

	local export_panels = 0
	capture mata: _xtpq_legacy_panels(`k_x', `ncoefs_ar', `ncoefs_sr', ///
		"`rho_all'", "`beta_all'", "`phi_all'", "`sr_all'", "`panelids'")
	if _rc == 0 local export_panels = 1

	mata: _xtpq_halflife("`rho_mg'", "`halflife_mg'", `export_panels', ///
		"`rho_all'", "`halflife_all'")

	* ================================================================
	* Return
	* ================================================================
	return scalar npanels       = `npanels'
	return scalar valid_panels  = `success_count'
	return scalar n_mg          = `n_mg'
	return scalar n_pool        = `n_pool'
	return scalar ntau          = `ntau'
	return scalar k             = `k'
	return scalar k_lr          = `k_lr'
	return scalar k_x           = `k_x'
	return scalar p             = `p'
	return scalar ncoefs_ar     = `ncoefs_ar'
	return scalar ncoefs_sr     = `ncoefs_sr'
	return scalar M             = `M'
	return scalar export_panels = `export_panels'
	return local  vcetype       "`vce'"
	return local  pooled        "`poollr'"
	return local  poolmeth      "`poolmeth'"
	return scalar hausman       = `haus'
	return scalar hausman_df    = `hausdf'
	return scalar hausman_p     = `hausp'

	return matrix g_mg   = `g_mg'
	return matrix g_V    = `g_V'
	return matrix g_Vnp  = `g_Vnp'
	return matrix g_Veff = `g_Veff'

	return matrix rho_mg      = `rho_mg'
	return matrix beta_mg     = `beta_mg'
	return matrix phi_mg      = `phi_mg'
	return matrix sr_mg       = `sr_mg'
	return matrix halflife_mg = `halflife_mg'
	return matrix rho_V       = `rho_V'
	return matrix beta_V      = `beta_V'

	if `export_panels' {
		return matrix rho_all      = `rho_all'
		return matrix beta_all     = `beta_all'
		return matrix phi_all      = `phi_all'
		return matrix sr_all       = `sr_all'
		return matrix halflife_all = `halflife_all'
		return matrix panelids     = `panelids'
	}
end
