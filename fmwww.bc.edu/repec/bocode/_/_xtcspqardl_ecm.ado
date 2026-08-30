*! _xtcspqardl_ecm v1.1.0  29aug2026 -- two-step CS-PQARDL
*! Ul-Durar, Bakkar, Arshed, Naveed & Zhang (2025), RIBAF 73, 102543.
*! Called internally by xtcspqardl.ado via the ecm option.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Step 1 (their equation 2) -- POOLED panel quantile regression of the
*! level dependent variable on the level regressors AND the cross-
*! sectional averages of every variable (contemporaneous plus pT lags):
*!
*!   Q_y(tau | .) = a0(tau) + sum_j a_j(tau) x_jit
*!                          + sum_j b_j(tau) zbar_jt + e_it(tau)
*!
*! Estimated over the whole panel, so the reported sample is N*T; the
*! variance-covariance matrix is obtained by a block bootstrap that
*! resamples whole cross-sectional units (the panel analogue of the
*! bootstrap the paper uses).  Reported with the Koenker-Machado pseudo
*! R1 and the joint Wald statistic, i.e. their Table 7.
*!
*! Step 2 (their equation 3) -- UNIT-BY-UNIT quantile regression of the
*! differences on the differences and the LAGGED step-1 residual:
*!
*!   Q_Dy(tau | .) = c_i(tau) + sum_j d_ij(tau) Dx_jit
*!                            + delta_i(tau) ehat_i,t-1(tau) + v_it
*!
*! then averaged over units (pooled mean group).  This is their Table 8,
*! and the unit-level delta_i are their Figure 3 and Table 9.
*!
*! NOTE on inference: step 1 and step 2 come from different regressions,
*! so the joint covariance posted in e(V) treats the two blocks as
*! independent.  Do not use `test' across a long-run and a short-run
*! coefficient in this mode; use the one-step form for that.

capture program drop _xtcspqardl_ecm
program define _xtcspqardl_ecm, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string)                         ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string)         ///
		TOUSE(string) CSAVARS(string) CRLAGS(integer)             ///
		[ LRVARS(string) P(integer 1) Q(string)                   ///
		  REPS(integer 100) SEED(string)                          ///
		  UNITVCE(string) MINT(integer 0) NOCD SHOWIndividual ]

	_xtcspqardl_mata

	local k     : word count `indepvars'
	local ntau  : word count `tau'
	local n_csa : word count `csavars'

	if "`unitvce'" == "" local unitvce "iid"
	if "`seed'" != "" set seed `seed'

	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'

	* =================================================================
	* Plain copies
	* =================================================================
	tempvar yl
	qui gen double `yl' = `depvar' if `touse'

	local xl ""
	forvalues j = 1/`k' {
		local v : word `j' of `indepvars'
		tempvar xl`j'
		qui gen double `xl`j'' = `v' if `touse'
		local xl "`xl' `xl`j''"
	}

	local csa_plain ""
	local ci = 0
	foreach cv of local csavars {
		local ++ci
		tempvar cp`ci'
		qui gen double `cp`ci'' = `cv' if `touse'
		local csa_plain "`csa_plain' `cp`ci''"
	}

	local lvlreg "`xl' `csa_plain'"
	local nlvl = `k' + `n_csa'

	* =================================================================
	* STEP 1 -- pooled level quantile regression, one per quantile
	* =================================================================
	tempname lvb lvV diag
	matrix `lvb'  = J(1, `ntau' * `nlvl', .)
	matrix `lvV'  = J(`ntau' * `nlvl', `ntau' * `nlvl', 0)
	matrix `diag' = J(`ntau', 13, .)
	matrix colnames `diag' = ///
		r1 wald wald_df wald_p cd cd_p gjmo_d gjmo_d_p cd0 cd0_p ///
		gjmo_s gjmo_s_df gjmo_s_p

	forvalues t = 1/`ntau' {
		tempvar eh`t'
		qui gen double `eh`t'' = .
		local ehats "`ehats' `eh`t''"
	}
	if "`nocd'" == "" {
		forvalues t = 1/`ntau' {
			tempvar e0`t'
			qui gen double `e0`t'' = .
			local ehat0 "`ehat0' `e0`t''"
		}
	}

	* The bootstrap prefix resamples whole units, which duplicates panel
	* identifiers; tsset must be cleared while it runs.  Every regressor
	* above is already a plain variable, so nothing is lost.
	qui tsset
	local savedi "`r(panelvar)'"
	local savedt "`r(timevar)'"

	local ti = 0
	foreach tauval of local tau {
		local ++ti

		* ---- point estimates and the residual for step 2 ----
		capture qui qreg `yl' `lvlreg' if `touse', quantile(`tauval')
		if _rc != 0 & _rc != 498 {
			di as err "step 1 quantile regression failed at tau = " ///
				"`tauval' (rc = " _rc ")"
			exit 498
		}
		tempname b1
		matrix `b1' = e(b)
		matrix `diag'[`ti', 1] = e(r2_p)
		local eh : word `ti' of `ehats'
		tempvar rres
		qui predict double `rres' if e(sample), residuals
		qui replace `eh' = `rres'
		drop `rres'

		* ---- residual without the cross-sectional averages, for CD ----
		if "`nocd'" == "" {
			capture qui qreg `yl' `xl' if `touse', quantile(`tauval')
			if _rc == 0 | _rc == 498 {
				tempvar r0
				qui predict double `r0' if e(sample), residuals
				local e0 : word `ti' of `ehat0'
				qui replace `e0' = `r0'
				drop `r0'
			}
			capture qui qreg `yl' `lvlreg' if `touse', quantile(`tauval')
		}

		* ---- clustered block bootstrap for the variance ----
		tempname V1
		matrix `V1' = J(`nlvl', `nlvl', .)
		if `reps' > 0 {
			tempvar bsid
			qui tsset, clear
			capture qui bootstrap, reps(`reps') cluster(`ivar')       ///
				idcluster(`bsid') nodots nowarn notable:          ///
				qreg `yl' `lvlreg' if `touse', quantile(`tauval')
			local brc = _rc
			qui tsset `savedi' `savedt'
			if `brc' == 0 {
				tempname Vb
				matrix `Vb' = e(V)
				matrix `V1' = `Vb'[1..`nlvl', 1..`nlvl']
			}
		}
		if `V1'[1,1] >= . {
			* fall back on the asymptotic (Koenker sparsity) variance
			capture qui qreg `yl' `lvlreg' if `touse', quantile(`tauval')
			tempname Va
			matrix `Va' = e(V)
			matrix `V1' = `Va'[1..`nlvl', 1..`nlvl']
			local vcelab "asymptotic"
		}
		else local vcelab "block bootstrap, `reps' reps, clustered on `ivar'"

		forvalues a = 1/`nlvl' {
			local r1 = (`ti' - 1) * `nlvl' + `a'
			matrix `lvb'[1, `r1'] = `b1'[1, `a']
			forvalues bq = 1/`nlvl' {
				local r2 = (`ti' - 1) * `nlvl' + `bq'
				matrix `lvV'[`r1', `r2'] = `V1'[`a', `bq']
			}
		}

		* ---- joint Wald on the level regressors (their Table 7) ----
		tempname idx
		matrix `idx' = J(1, `k', .)
		forvalues j = 1/`k' {
			matrix `idx'[1, `j'] = (`ti' - 1) * `nlvl' + `j'
		}
		mata: _xtcspq_wald("`lvb'", "`lvV'", "`idx'", "r_w", "r_df", "r_p")
		matrix `diag'[`ti', 2] = r_w
		matrix `diag'[`ti', 3] = r_df
		matrix `diag'[`ti', 4] = r_p
		scalar drop r_w r_df r_p

		* ---- CD on the step-1 residuals, with and without the CSAs ----
		if "`nocd'" == "" {
			capture mata: _xtcspq_cd("`eh'", "`ivar'", "`tvar'",     ///
				"`touse'", "r_cd", "r_cdp", "r_cdn", "r_cdt")
			if _rc == 0 {
				matrix `diag'[`ti', 5] = r_cd
				matrix `diag'[`ti', 6] = r_cdp
				scalar drop r_cd r_cdp r_cdn r_cdt
			}
			local e0 : word `ti' of `ehat0'
			capture mata: _xtcspq_cd("`e0'", "`ivar'", "`tvar'",     ///
				"`touse'", "r_cd", "r_cdp", "r_cdn", "r_cdt")
			if _rc == 0 {
				matrix `diag'[`ti', 9]  = r_cd
				matrix `diag'[`ti', 10] = r_cdp
				scalar drop r_cd r_cdp r_cdn r_cdt
			}
		}
	}
	qui tsset `savedi' `savedt'

	* =================================================================
	* STEP 2 -- unit-by-unit error-correction regressions
	* =================================================================
	tempvar dy
	qui gen double `dy' = D.`depvar' if `touse'
	local dx ""
	forvalues j = 1/`k' {
		local v : word `j' of `indepvars'
		tempvar dx`j'
		qui gen double `dx`j'' = D.`v' if `touse'
		local dx "`dx' `dx`j''"
	}
	local lehat ""
	local srnames "ECM(-1)"
	forvalues j = 1/`k' {
		local v : word `j' of `indepvars'
		local srnames "`srnames' D.`v'"
	}
	forvalues t = 1/`ntau' {
		local eh : word `t' of `ehats'
		tempvar leh`t'
		qui gen double `leh`t'' = L.`eh' if `touse'
		local lehat "`lehat' `leh`t''"
	}

	local pv    = 1 + `k'
	local pfull = `pv'
	local minT  = `pfull' + 5
	if `mint' > 0 local minT = `mint'

	mata: _xtcspq_init(`npanels', `ntau', `pfull', `pv')

	tempname bfull vfull bblk vblk
	local pi = 0
	local success_count = 0
	local n_short   = 0
	local n_failed  = 0
	local n_omitted = 0

	foreach i of local ids {
		local ++pi
		qui count if `touse' & `ivar' == `i' & `dy' < .
		local ni = r(N)
		if `ni' < `minT' {
			local ++n_short
			continue
		}
		local any_tau_ok = 0
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local le : word `ti' of `lehat'
			capture qui qreg `dy' `le' `dx' if `touse' & `ivar' == `i', ///
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
				if substr("`nm'", 1, 2) == "o." local bad = 1
				matrix `bblk'[1, `j'] = `bfull'[1, `j']
			}
			if `bad' {
				local ++n_omitted
				continue
			}
			matrix `vblk' = J(`pv', `pv', .)
			if `rc' == 0 {
				capture matrix `vfull' = e(V)
				if _rc == 0 matrix `vblk' = `vfull'[1..`pv', 1..`pv']
			}
			local adev = e(sum_adev)
			local rdev = e(sum_rdev)
			local nobs = e(N)
			mata: _xtcspq_put(`pi', `ti', `pfull', `pv', "`bblk'",  ///
				"`vblk'", `adev', `rdev', `nobs')
			local any_tau_ok = 1
		}
		if `any_tau_ok' local ++success_count
	}

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

	* ---- half-life from the error-correction coefficient ----
	tempname hl hlse
	matrix `hl'   = J(1, `ntau', .)
	matrix `hlse' = J(1, `ntau', .)
	forvalues t = 1/`ntau' {
		local c0 = (`t' - 1) * `pv' + 1
		local phi = `bmg'[1, `c0']
		local lam = 1 + `phi'
		if `lam' > 0 & `lam' < 1 {
			matrix `hl'[1, `t'] = ln(0.5) / ln(`lam')
			local g = -ln(0.5) / (`lam' * (ln(`lam'))^2)
			local vl = `Vmg'[`c0', `c0']
			if `vl' > 0 & `vl' < . ///
				matrix `hlse'[1, `t'] = abs(`g') * sqrt(`vl')
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
	* Split the step-1 vector into the level block and the CSA block
	* =================================================================
	tempname lr Vlr Glr csab csaV
	matrix `lr'  = J(1, `ntau' * `k', .)
	matrix `Vlr' = J(`ntau' * `k', `ntau' * `k', 0)
	matrix `csab'= J(1, `ntau' * `n_csa', .)
	matrix `csaV'= J(`ntau' * `n_csa', `ntau' * `n_csa', 0)
	forvalues t = 1/`ntau' {
		forvalues a = 1/`k' {
			local r1 = (`t' - 1) * `k' + `a'
			local s1 = (`t' - 1) * `nlvl' + `a'
			matrix `lr'[1, `r1'] = `lvb'[1, `s1']
			forvalues bq = 1/`k' {
				local r2 = (`t' - 1) * `k' + `bq'
				local s2 = (`t' - 1) * `nlvl' + `bq'
				matrix `Vlr'[`r1', `r2'] = `lvV'[`s1', `s2']
			}
		}
		forvalues a = 1/`n_csa' {
			local r1 = (`t' - 1) * `n_csa' + `a'
			local s1 = (`t' - 1) * `nlvl' + `k' + `a'
			matrix `csab'[1, `r1'] = `lvb'[1, `s1']
			matrix `csaV'[`r1', `r1'] = `lvV'[`s1', `s1']
		}
	}

	* Step 1 and step 2 come from different regressions: the joint
	* covariance is block diagonal, i.e. the cross-block Jacobian is 0.
	matrix `Glr' = J(`ntau' * `k', `ntau' * `pv', 0)

	* =================================================================
	* Return
	* =================================================================
	return local coefnames "`srnames'"
	return local lrnames   "`indepvars'"
	return local srnames   ""
	return local unitvce   "`unitvce'"
	return local vcelab    "`vcelab'"

	return scalar npanels   = `npanels'
	return scalar ntau      = `ntau'
	return scalar k         = `k'
	return scalar pblk      = `pv'
	return scalar pfull     = `pfull'
	return scalar n_csa     = `n_csa'
	return scalar cr_lags   = `crlags'
	return scalar pooled    = 0
	return scalar reps      = `reps'
	return scalar n_csaomit = 0

	return matrix b        = `bmg'
	return matrix V        = `Vmg'
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
