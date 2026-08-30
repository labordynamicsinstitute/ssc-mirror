*! _xtcspqardl_estimate v1.1.0  29aug2026 -- CS-PQARDL engine (one step)
*! Cross-sectionally augmented panel quantile ARDL in conditional-ECM form.
*! Called internally by xtcspqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Unit-i equation, estimated by quantile regression at each tau:
*!
*!   Dy_it = phi_i(t) y_i,t-1 + xi_i(t)' x_i,t-1
*!           + sum_{j=1}^{p-1} c_ij(t) Dy_i,t-j
*!           + sum_{m=0}^{q-1} d_im(t) Dx_i,t-m
*!           + sum_{l=0}^{pT} zbar_{t-l}' delta_il(t) + a_i(t) + e_it
*!
*! The level block (y_i,t-1, x_i,t-1) is whatever the user puts in lr().
*! Long-run coefficients follow the ARDL identity
*!
*!   theta_j(tau) = -xi_j(tau)/phi(tau) = xi_j(tau)/(1-lambda(tau)),
*!   lambda(tau)  = 1 + phi(tau),
*!
*! so the persistence parameter is stored internally as lambda and the
*! SAME delta-method machinery as QCCEMG applies, including the
*! Cov(xi, phi) term that a diagonal delta method would drop.
*!
*! Mean group and variance follow Pesaran & Smith (1995) and
*! Harding, Lamarche & Pesaran (2018, sec. 2.3).

capture program drop _xtcspqardl_estimate
program define _xtcspqardl_estimate, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) LRVARS(string)          ///
		P(integer) Q(string)                                      ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string)         ///
		TOUSE(string) CSAVARS(string) CRLAGS(integer)             ///
		[ NOCONStant SHOWIndividual                               ///
		  UNITVCE(string) MINT(integer 0) NOCD ]

	_xtcspqardl_mata

	local k     : word count `indepvars'
	local k_lr  : word count `lrvars'
	local ntau  : word count `tau'
	local n_csa : word count `csavars'

	if `k_lr' < 2 {
		di as err "lr() must list the lagged dependent level first, " ///
			"then at least one level regressor"
		exit 198
	}
	if `p' < 1 {
		di as err "p() must be at least 1"
		exit 198
	}

	if "`q'" == "" local q "1"
	local nq : word count `q'
	if `nq' == 1 {
		forvalues j = 1/`k' {
			local q`j' = `q'
		}
	}
	else if `nq' == `k' {
		forvalues j = 1/`k' {
			local q`j' : word `j' of `q'
		}
	}
	else {
		di as err "q() must be a single number or one number per " ///
			"short-run regressor"
		exit 198
	}

	if !inlist("`unitvce'", "", "iid", "robust") {
		di as err "unitvce() must be iid or robust"
		exit 198
	}
	if "`unitvce'" == "" local unitvce "iid"

	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'

	* =================================================================
	* Build plain (non-ts) regressors
	* =================================================================
	tempvar dv
	qui gen double `dv' = `depvar' if `touse'

	* --- level (long-run) block, taken from lr() verbatim ---
	local lr_plain ""
	forvalues j = 1/`k_lr' {
		local v : word `j' of `lrvars'
		tempvar lp`j'
		qui gen double `lp`j'' = `v' if `touse'
		local lr_plain "`lr_plain' `lp`j''"
	}

	* --- extra lags of the dependent variable: p-1 of them ---
	local ar_plain ""
	local n_ar = `p' - 1
	local arnames ""
	if `n_ar' > 0 {
		forvalues lag = 1/`n_ar' {
			tempvar ap`lag'
			qui gen double `ap`lag'' = L`lag'.`dv' if `touse'
			local ar_plain "`ar_plain' `ap`lag''"
			local arnames "`arnames' L`lag'.`depvar'"
		}
	}

	* --- short-run regressors and their lags ---
	local sr_plain ""
	local srnames ""
	local n_sr = 0
	forvalues j = 1/`k' {
		local xv : word `j' of `indepvars'
		tempvar sp`j'_0
		qui gen double `sp`j'_0' = `xv' if `touse'
		local sr_plain "`sr_plain' `sp`j'_0'"
		local srnames "`srnames' `xv'"
		local ++n_sr
		if `q`j'' > 1 {
			forvalues m = 1/`= `q`j'' - 1' {
				tempvar sp`j'_`m'
				qui gen double `sp`j'_`m'' = L`m'.`sp`j'_0' if `touse'
				local sr_plain "`sr_plain' `sp`j'_`m''"
				local srnames "`srnames' L`m'.`xv'"
				local ++n_sr
			}
		}
	}

	local csa_plain ""
	local ci = 0
	foreach cv of local csavars {
		local ++ci
		tempvar cp`ci'
		qui gen double `cp`ci'' = `cv' if `touse'
		local csa_plain "`csa_plain' `cp`ci''"
	}

	local fullreg "`lr_plain' `ar_plain' `sr_plain' `csa_plain'"

	local pv    = `k_lr'
	local n_dyn = `n_ar' + `n_sr'
	local pfull = `k_lr' + `n_dyn' + `n_csa'
	local minT  = `pfull' + 5
	if `mint' > 0 local minT = `mint'

	local dynnames "`arnames' `srnames'"

	* residual holders for the CD test
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
	* Unit-by-unit quantile regressions
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
		qui count if `touse' & `ivar' == `i' & `lp1' < .
		local ni = r(N)
		if `ni' < `minT' {
			local ++n_short
			continue
		}

		local any_tau_ok = 0
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			capture qui qreg `dv' `fullreg' ///
				if `touse' & `ivar' == `i', ///
				quantile(`tauval') vce(`unitvce')
			local rc = _rc
			if `rc' != 0 & `rc' != 498 {
				local ++n_failed
				continue
			}
			if e(N) < `minT' continue

			matrix `bfull' = e(b)
			local cn : colnames `bfull'

			local bad = 0
			matrix `bblk' = J(1, `pfull', .)
			forvalues j = 1/`pfull' {
				local nm : word `j' of `cn'
				if `j' <= `pv' {
					if substr("`nm'", 1, 2) == "o." local bad = 1
				}
				else if `j' > `= `pv' + `n_dyn'' {
					if substr("`nm'", 1, 2) == "o." ///
						local ++n_csaomit
				}
				matrix `bblk'[1, `j'] = `bfull'[1, `j']
			}
			if `bad' {
				local ++n_omitted
				continue
			}

			* store persistence as lambda = 1 + phi so that the shared
			* long-run delta method applies unchanged
			matrix `bblk'[1, 1] = 1 + `bfull'[1, 1]

			matrix `vblk' = J(`pv', `pv', .)
			if `rc' == 0 {
				capture matrix `vfull' = e(V)
				if _rc == 0 matrix `vblk' = `vfull'[1..`pv', 1..`pv']
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
				capture qui qreg `dv' `lr_plain' `ar_plain' `sr_plain' ///
					if `touse' & `ivar' == `i', quantile(`tauval')
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
	* Aggregation
	* =================================================================
	tempname bmg Vmg keep
	mata: _xtcspq_mg(`ntau', `pfull', `pv', "`bmg'", "`Vmg'", ///
		"r_nused", "`keep'")
	local n_used = r_nused
	scalar drop r_nused

	return scalar valid_panels = `success_count'
	return scalar n_used       = `n_used'
	return scalar n_short      = `n_short'
	return scalar n_failed     = `n_failed'
	return scalar n_omitted    = `n_omitted'
	if `n_used' < 2 exit

	* ---- core block (lambda, xi) ----
	tempname b V
	matrix `b' = J(1, `ntau' * `pv', .)
	matrix `V' = J(`ntau' * `pv', `ntau' * `pv', .)
	forvalues t1 = 1/`ntau' {
		forvalues a = 1/`pv' {
			local r1 = (`t1' - 1) * `pv' + `a'
			local s1 = (`t1' - 1) * `pfull' + `a'
			matrix `b'[1, `r1'] = `bmg'[1, `s1']
			forvalues t2 = 1/`ntau' {
				forvalues bq = 1/`pv' {
					local r2 = (`t2' - 1) * `pv' + `bq'
					local s2 = (`t2' - 1) * `pfull' + `bq'
					matrix `V'[`r1', `r2'] = `Vmg'[`s1', `s2']
				}
			}
		}
	}

	* ---- long run theta_j = xi_j/(1-lambda) = -xi_j/phi ----
	local klr1 = `k_lr' - 1
	tempname lr Vlr Glr
	mata: _xtcspq_lrdelta(`ntau', `klr1', 1, 1, "`b'", "`V'", ///
		"`lr'", "`Vlr'", "`Glr'")

	* ---- half-life from lambda ----
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
			if `vl' > 0 & `vl' < . ///
				matrix `hlse'[1, `t'] = abs(`g') * sqrt(`vl')
		}
	}

	* ---- convert the stored lambda back to the speed of adjustment
	*      phi = lambda - 1 for reporting.  This is an affine shift, so
	*      V, Glr and the cross-covariance are unchanged. ----
	forvalues t = 1/`ntau' {
		local c0 = (`t' - 1) * `pv' + 1
		matrix `b'[1, `c0'] = `b'[1, `c0'] - 1
	}

	* ---- short-run dynamics block ----
	tempname sb sv
	if `n_dyn' > 0 {
		matrix `sb' = J(1, `ntau' * `n_dyn', .)
		matrix `sv' = J(`ntau' * `n_dyn', `ntau' * `n_dyn', 0)
		forvalues t = 1/`ntau' {
			forvalues a = 1/`n_dyn' {
				local r1 = (`t' - 1) * `n_dyn' + `a'
				local s1 = (`t' - 1) * `pfull' + `pv' + `a'
				matrix `sb'[1, `r1'] = `bmg'[1, `s1']
				matrix `sv'[`r1', `r1'] = `Vmg'[`s1', `s1']
			}
		}
	}

	* ---- CSA block ----
	tempname csab csaV
	matrix `csab' = J(1, `ntau' * `n_csa', .)
	matrix `csaV' = J(`ntau' * `n_csa', `ntau' * `n_csa', 0)
	forvalues t = 1/`ntau' {
		forvalues a = 1/`n_csa' {
			local r1 = (`t' - 1) * `n_csa' + `a'
			local s1 = (`t' - 1) * `pfull' + `pv' + `n_dyn' + `a'
			matrix `csab'[1, `r1'] = `bmg'[1, `s1']
			matrix `csaV'[`r1', `r1'] = `Vmg'[`s1', `s1']
		}
	}

	* =================================================================
	* Diagnostics
	* =================================================================
	tempname diag
	matrix `diag' = J(`ntau', 13, .)
	matrix colnames `diag' = ///
		r1 wald wald_df wald_p cd cd_p gjmo_d gjmo_d_p cd0 cd0_p ///
		gjmo_s gjmo_s_df gjmo_s_p

	forvalues t = 1/`ntau' {
		mata: _xtcspq_r1(`t', "r_r1")
		matrix `diag'[`t', 1] = r_r1
		scalar drop r_r1

		* H0: all long-run level regressors have a zero coefficient
		tempname idx
		matrix `idx' = J(1, `klr1', .)
		forvalues j = 1/`klr1' {
			matrix `idx'[1, `j'] = (`t' - 1) * `pv' + 1 + `j'
		}
		mata: _xtcspq_wald("`b'", "`V'", "`idx'", "r_w", "r_df", "r_p")
		matrix `diag'[`t', 2] = r_w
		matrix `diag'[`t', 3] = r_df
		matrix `diag'[`t', 4] = r_p
		scalar drop r_w r_df r_p

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

	tempname unitb unitok
	mata: _xtcspq_getall("`unitb'")
	mata: _xtcspq_getok("`unitok'")
	matrix rownames `unitb'  = `ids'
	matrix rownames `unitok' = `ids'
	mata: _xtcspq_drop()

	* =================================================================
	* Names and return
	* =================================================================
	local lr_y : word 1 of `lrvars'
	local lr_x ""
	forvalues j = 2/`k_lr' {
		local v : word `j' of `lrvars'
		local lr_x "`lr_x' `v'"
	}
	return local coefnames "ECT `lr_x'"
	return local lrnames   "`lr_x'"
	return local srnames   "`dynnames'"
	return local unitvce   "`unitvce'"

	return scalar npanels   = `npanels'
	return scalar ntau      = `ntau'
	return scalar k         = `k'
	return scalar k_lr      = `k_lr'
	return scalar pblk      = `pv'
	return scalar pfull     = `pfull'
	return scalar n_csa     = `n_csa'
	return scalar n_dyn     = `n_dyn'
	return scalar cr_lags   = `crlags'
	return scalar pooled    = 0
	return scalar n_csaomit = `n_csaomit'

	return matrix b        = `b'
	return matrix V        = `V'
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
	if `n_dyn' > 0 {
		return matrix sr_b = `sb'
		return matrix sr_V = `sv'
	}
end
