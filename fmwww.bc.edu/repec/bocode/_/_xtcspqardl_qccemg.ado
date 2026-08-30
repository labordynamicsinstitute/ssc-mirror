*! _xtcspqardl_qccemg v1.1.0  29aug2026 -- QCCEMG / QCCEPMG estimation engine
*! Quantile CCE Mean Group estimator (Harding, Lamarche & Pesaran 2018)
*! and its inverse-variance pooled counterpart (Pesaran 2006 CCEP).
*! Called internally by xtcspqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Step -> equation map (Harding, Lamarche & Pesaran 2018):
*!   [1] cross-section averages zbar_t = (ybar_t, xbar_t)'      eq (2.11)-(2.12)
*!   [2] unit-i augmented quantile regression
*!         y_it = a_i(t) + lam_i(t) y_i,t-1 + x_it'bet_i(t)
*!                + sum_{l=0}^{pT} zbar_{t-l}' del_il(t) + e_it   eq (2.17)
*!       minimised by the check function                          eq (2.19)-(2.20)
*!   [3] mean group  thetahat(t) = (1/N) sum_i thetahat_i(t)      eq (2.21)
*!   [4] variance    Vv = (1/(N-1)) sum (th_i-th)(th_i-th)'       sec 2.3
*!       reported SE = sqrt(Vv_jj / N)                            Thm 4
*!   [5] long run    theta_j(t) = beta_j(t)/(1-lambda(t))         sec 3, p.25
*!       (plug-in of the mean-group estimates, delta-method SE)
*!   [6] pooled      th_P = (sum W_i)^-1 sum W_i th_i             Pesaran (2006)

capture program drop _xtcspqardl_qccemg
program define _xtcspqardl_qccemg, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) CSAVARS(string) ///
		NCSAORIG(integer) CRLAGS(integer) ///
		[ POOLED NOCONStant SHOWIndividual ///
		  UNITVCE(string) MINT(integer 0) NOCD RESIDSTUB(string) ]

	_xtcspqardl_mata

	local k     : word count `indepvars'
	local ntau  : word count `tau'
	local n_csa : word count `csavars'

	* ---- parameters of interest: vartheta_i = (lambda_i, beta_i') ----
	* pv    = the block whose unit VCE is kept (used for pooling and for
	*         the Galvao et al. homogeneity test)
	* pfull = every coefficient stored per quantile, i.e. the parameters
	*         of interest PLUS the cross-sectional-average coefficients
	*         delta_i(tau), which are reported in their own table (they
	*         are substantive in the CS-PQARDL application of Ul-Durar
	*         et al. and nuisance in Harding, Lamarche & Pesaran).
	local pv    = 1 + `k'
	local pfull = 1 + `k' + `n_csa'

	if !inlist("`unitvce'", "", "iid", "robust") {
		di as err "unitvce() must be iid or robust"
		exit 198
	}
	if "`unitvce'" == "" local unitvce "iid"
	local vceopt "vce(`unitvce')"

	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'

	* =================================================================
	* [1] Build plain (non-ts) copies -- qreg rejects ts operators
	* =================================================================
	tempvar dv_plain lag_dv
	qui gen double `dv_plain' = `depvar'   if `touse'
	qui gen double `lag_dv'   = L.`depvar' if `touse'

	local indep_plain ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		tempvar xp`j'
		qui gen double `xp`j'' = `xvar' if `touse'
		local indep_plain "`indep_plain' `xp`j''"
	}

	local csa_plain ""
	local ci = 0
	foreach csav of local csavars {
		local ++ci
		tempvar cp`ci'
		qui gen double `cp`ci'' = `csav' if `touse'
		local csa_plain "`csa_plain' `cp`ci''"
	}

	* X_it = (y_{i,t-1}, x_it', zbar_t', ..., zbar_{t-pT}')     eq (2.17)
	local fullreg "`lag_dv' `indep_plain' `csa_plain'"
	local ncoefs_total = 1 + `k' + `n_csa'

	* minimum usable T_i: enough residual degrees of freedom
	local minT = `ncoefs_total' + 5
	if `mint' > 0 local minT = `mint'

	* ---- residual holders for the CD test (one per quantile) ----
	local docd = 1
	if "`nocd'" != "" local docd = 0
	if `docd' {
		forvalues t = 1/`ntau' {
			tempvar rr`t' r0`t'
			qui gen double `rr`t'' = .
			qui gen double `r0`t'' = .
			local resvars  "`resvars' `rr`t''"
			local resvars0 "`resvars0' `r0`t''"
		}
	}

	* =================================================================
	* [2] Unit-by-unit augmented quantile regressions
	* =================================================================
	mata: _xtcspq_init(`npanels', `ntau', `pfull', `pv')

	tempname bfull vfull bblk vblk
	local pi = 0
	local success_count = 0
	local n_short   = 0
	local n_failed  = 0
	local n_omitted = 0
	local n_csaomit = 0

	foreach i of local ids {
		local ++pi

		qui count if `touse' & `ivar' == `i' & `lag_dv' < .
		local ni = r(N)
		if `ni' < `minT' {
			local ++n_short
			continue
		}

		local any_tau_ok = 0
		local ti = 0
		foreach tauval of local tau {
			local ++ti

			* NOTE: pass the quantile as a fraction so that tau is used
			* EXACTLY as requested (quantile(round(tau*100)) silently
			* snapped tau to a 1% grid).
			capture qui qreg `dv_plain' `fullreg' ///
				if `touse' & `ivar' == `i', quantile(`tauval') `vceopt'
			local rc = _rc

			* rc 498 = VCE not of full rank; the coefficients are still
			* the solution of (2.20), so keep them but drop the VCE.
			if `rc' != 0 & `rc' != 498 {
				local ++n_failed
				continue
			}
			if e(N) < `minT' continue

			matrix `bfull' = e(b)
			local cn : colnames `bfull'

			* --- reject the unit-quantile if a parameter of interest was
			*     dropped for collinearity: qreg keeps the column with a
			*     coefficient of exactly 0, which would otherwise be
			*     averaged into the mean group as a genuine estimate.
			local bad = 0
			matrix `bblk' = J(1, `pfull', .)
			forvalues j = 1/`pfull' {
				local nm : word `j' of `cn'
				if `j' <= `pv' {
					if substr("`nm'", 1, 2) == "o." local bad = 1
				}
				else {
					if substr("`nm'", 1, 2) == "o." ///
						local ++n_csaomit
				}
				matrix `bblk'[1, `j'] = `bfull'[1, `j']
			}
			if `bad' {
				local ++n_omitted
				continue
			}

			matrix `vblk' = J(`pv', `pv', .)
			if `rc' == 0 {
				capture matrix `vfull' = e(V)
				if _rc == 0 {
					matrix `vblk' = `vfull'[1..`pv', 1..`pv']
				}
			}

			local adev = e(sum_adev)
			local rdev = e(sum_rdev)
			local nobs = e(N)
			mata: _xtcspq_put(`pi', `ti', `pfull', `pv', ///
				"`bblk'", "`vblk'", `adev', `rdev', `nobs')

			if `docd' {
				tempvar rtmp
				capture qui predict double `rtmp' if e(sample), residuals
				if _rc == 0 {
					local rv : word `ti' of `resvars'
					qui replace `rv' = `rtmp' if `rtmp' < .
					drop `rtmp'
				}
				* Same unit-level quantile regression WITHOUT the
				* cross-sectional averages, so that the CD statistic
				* can be reported before and after the augmentation.
				capture qui qreg `dv_plain' `lag_dv' `indep_plain' ///
					if `touse' & `ivar' == `i',                ///
					quantile(`tauval')
				if _rc == 0 | _rc == 498 {
					tempvar r0tmp
					capture qui predict double `r0tmp' ///
						if e(sample), residuals
					if _rc == 0 {
						local rv0 : word `ti' of `resvars0'
						qui replace `rv0' = `r0tmp' if `r0tmp' < .
						drop `r0tmp'
					}
				}
			}

			local any_tau_ok = 1
		}

		if `any_tau_ok' local ++success_count

		if "`showindividual'" != "" & `any_tau_ok' {
			di in gr "    unit `i': T_i = " in ye %4.0f `ni' in gr "   ok"
		}
	}

	* =================================================================
	* [3]-[4] Aggregation and the FULL joint covariance
	* =================================================================
	tempname bmg Vmg bpool Vpool Vpoolh keep
	mata: _xtcspq_mg(`ntau', `pfull', `pv', "`bmg'", "`Vmg'", ///
		"r_nused", "`keep'")
	local n_used = r_nused
	scalar drop r_nused

	if `n_used' < 2 {
		return scalar valid_panels = `success_count'
		return scalar n_used = `n_used'
		exit
	}

	local pooled_ok = 0
	if "`pooled'" != "" {
		mata: _xtcspq_pool(`ntau', `pfull', `pv', "`bpool'", ///
			"`Vpool'", "`Vpoolh'", "r_npool")
		local n_pool = r_npool
		scalar drop r_npool
		if `n_pool' >= 2 {
			local pooled_ok = 1
		}
		else {
			di as txt "  note: too few units with a usable variance " ///
				"matrix for pooling; reporting the mean group."
		}
	}

	* ---- b/V carry the parameters of interest only (pv per quantile);
	*      the CSA coefficients keep their own mean-group table.
	tempname b V bcore Vcore
	matrix `bcore' = J(1, `ntau' * `pv', .)
	matrix `Vcore' = J(`ntau' * `pv', `ntau' * `pv', .)
	forvalues t1 = 1/`ntau' {
		forvalues a = 1/`pv' {
			local r1 = (`t1' - 1) * `pv' + `a'
			local s1 = (`t1' - 1) * `pfull' + `a'
			matrix `bcore'[1, `r1'] = `bmg'[1, `s1']
			forvalues t2 = 1/`ntau' {
				forvalues bq = 1/`pv' {
					local r2 = (`t2' - 1) * `pv' + `bq'
					local s2 = (`t2' - 1) * `pfull' + `bq'
					matrix `Vcore'[`r1', `r2'] = ///
						`Vmg'[`s1', `s2']
				}
			}
		}
	}
	if `pooled_ok' {
		matrix `b' = `bpool'
		matrix `V' = `Vpool'
		return matrix V_pooled_hom = `Vpoolh'
		return matrix b_mgcore = `bcore'
		return matrix V_mgcore = `Vcore'
		return scalar n_pool = `n_pool'
	}
	else {
		matrix `b' = `bcore'
		matrix `V' = `Vcore'
	}

	* =================================================================
	* [5] Long-run effects theta_j(tau) = beta_j(tau)/(1-lambda(tau))
	*     with a delta-method variance that INCLUDES Cov(beta, lambda)
	* =================================================================
	tempname lr Vlr Glr
	mata: _xtcspq_lrdelta(`ntau', `k', 1, 1, "`b'", "`V'", ///
		"`lr'", "`Vlr'", "`Glr'")

	* =================================================================
	* Half-life from the mean-group persistence, exact discrete form
	*   h(tau) = ln(0.5)/ln(lambda(tau)),   dh/dlam = -ln(.5)/(lam ln(lam)^2)
	* =================================================================
	tempname hl hlse
	matrix `hl'   = J(1, `ntau', .)
	matrix `hlse' = J(1, `ntau', .)
	forvalues t = 1/`ntau' {
		local c0 = (`t' - 1) * `pv' + 1
		local lam = `b'[1, `c0']
		if `lam' > 0 & `lam' < 1 {
			matrix `hl'[1, `t'] = ln(0.5) / ln(`lam')
			local g = -ln(0.5) / (`lam' * (ln(`lam'))^2)
			local vl = `V'[`c0', `c0']
			if `vl' > 0 & `vl' < . {
				matrix `hlse'[1, `t'] = abs(`g') * sqrt(`vl')
			}
		}
	}

	* =================================================================
	* Per-quantile diagnostics: pseudo-R1, Wald, CD, slope homogeneity
	* =================================================================
	tempname diag
	matrix `diag' = J(`ntau', 13, .)
	matrix colnames `diag' = ///
		r1 wald wald_df wald_p cd cd_p gjmo_d gjmo_d_p cd0 cd0_p ///
		gjmo_s gjmo_s_df gjmo_s_p

	forvalues t = 1/`ntau' {
		* Koenker-Machado pseudo-R1
		mata: _xtcspq_r1(`t', "r_r1")
		matrix `diag'[`t', 1] = r_r1
		scalar drop r_r1

		* joint Wald H0: beta_1(tau)=...=beta_k(tau)=0
		tempname idx
		matrix `idx' = J(1, `k', .)
		forvalues j = 1/`k' {
			matrix `idx'[1, `j'] = (`t' - 1) * `pv' + 1 + `j'
		}
		mata: _xtcspq_wald("`b'", "`V'", "`idx'", "r_w", "r_df", "r_p")
		matrix `diag'[`t', 2] = r_w
		matrix `diag'[`t', 3] = r_df
		matrix `diag'[`t', 4] = r_p
		scalar drop r_w r_df r_p

		* Pesaran (2004) CD on the residuals, after and before the
		* CCE augmentation.
		if `docd' {
			local rv : word `t' of `resvars'
			capture mata: _xtcspq_cd("`rv'", "`ivar'", "`tvar'", ///
				"`touse'", "r_cd", "r_cdp", "r_cdn", "r_cdt")
			if _rc == 0 {
				matrix `diag'[`t', 5] = r_cd
				matrix `diag'[`t', 6] = r_cdp
				scalar drop r_cd r_cdp r_cdn r_cdt
			}
			local rv0 : word `t' of `resvars0'
			capture mata: _xtcspq_cd("`rv0'", "`ivar'", "`tvar'", ///
				"`touse'", "r_cd", "r_cdp", "r_cdn", "r_cdt")
			if _rc == 0 {
				matrix `diag'[`t', 9]  = r_cd
				matrix `diag'[`t', 10] = r_cdp
				scalar drop r_cd r_cdp r_cdn r_cdt
			}
		}

		* Galvao, Juhl, Montes-Rojas & Olmo (2017) slope homogeneity
		capture mata: _xtcspq_gjmo(`t', `pfull', `pv', "r_s", ///
			"r_sdf", "r_sp", "r_d", "r_dp", "r_n")
		if _rc == 0 {
			matrix `diag'[`t', 7]  = r_d
			matrix `diag'[`t', 8]  = r_dp
			matrix `diag'[`t', 11] = r_s
			matrix `diag'[`t', 12] = r_sdf
			matrix `diag'[`t', 13] = r_sp
			scalar drop r_s r_sdf r_sp r_d r_dp r_n
		}
	}

	* =================================================================
	* CSA (cross-sectional-average) coefficients, mean group
	* =================================================================
	tempname csab csaV
	matrix `csab' = J(1, `ntau' * `n_csa', .)
	matrix `csaV' = J(`ntau' * `n_csa', `ntau' * `n_csa', 0)
	forvalues t = 1/`ntau' {
		forvalues a = 1/`n_csa' {
			local r1 = (`t' - 1) * `n_csa' + `a'
			local s1 = (`t' - 1) * `pfull' + `pv' + `a'
			matrix `csab'[1, `r1'] = `bmg'[1, `s1']
			matrix `csaV'[`r1', `r1'] = `Vmg'[`s1', `s1']
		}
	}

	* =================================================================
	* Unit-level estimates (for the heterogeneity table and plots)
	* =================================================================
	tempname unitb unitok
	mata: _xtcspq_getall("`unitb'")
	mata: _xtcspq_getok("`unitok'")
	matrix rownames `unitb' = `ids'
	matrix rownames `unitok' = `ids'

	mata: _xtcspq_drop()

	* =================================================================
	* Return
	* =================================================================
	return scalar npanels      = `npanels'
	return scalar valid_panels = `success_count'
	return scalar n_used       = `n_used'
	return scalar n_short      = `n_short'
	return scalar n_failed     = `n_failed'
	return scalar n_omitted    = `n_omitted'
	return scalar ntau         = `ntau'
	return scalar k            = `k'
	return scalar pblk         = `pv'
	return scalar pfull        = `pfull'
	return scalar n_csaomit    = `n_csaomit'
	return scalar n_csa        = `n_csa'
	return scalar cr_lags      = `crlags'
	return scalar pooled       = `pooled_ok'
	return local  unitvce      "`unitvce'"

	return matrix b        = `b'
	return matrix V        = `V'
	return matrix b_mg     = `bmg'
	return matrix V_mg     = `Vmg'
	return matrix lr       = `lr'
	return matrix V_lr     = `Vlr'
	return matrix G_lr     = `Glr'
	return matrix halflife = `hl'
	return matrix halflife_se = `hlse'
	return matrix diag     = `diag'
	return matrix csa_b    = `csab'
	return matrix csa_V    = `csaV'
	return matrix unit_b   = `unitb'
	return matrix unit_ok  = `unitok'
	return matrix keep     = `keep'
end
