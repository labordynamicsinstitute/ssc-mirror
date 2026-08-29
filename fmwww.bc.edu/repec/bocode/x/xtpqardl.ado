*! xtpqardl v1.0.4  28aug2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Panel Quantile Autoregressive Distributed Lag (PQARDL) Model
*! Combines Panel ARDL (PMG/MG/DFE) with Quantile Regression
*! Based on: Cho, Kim & Shin (2015), Bildirici (2022), Pesaran et al. (1999)
*!
*! v1.0.4  - short-run (and AR) parameters now report Std.Err., z and P>|z|
*!         - vce(mg|iid|robust|hac|cluster), bw() and kernel() options
*!           (Newey-West HAC / Powell sandwich for quantile regression)
*!         - DFE branch reports full inference instead of point estimates only
*!         - PMG now genuinely pools the long run (was identical to MG)
*!         - exact half-life ln(.5)/ln(1+rho), consistent with the IRF
*!         - qreg called with the exact fractional quantile (no rounding)
*!         - Wald tests use the cross-quantile covariance and adjust the
*!           degrees of freedom when the restriction matrix is rank deficient
*!         - e(b)/e(V) posted so test/lincom/nlcom work after estimation

capture program drop xtpqardl
program define xtpqardl, eclass
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtpqardl") error 301
		_xtpq_Display `0'
	}
	else _xtpq_Estimate `0'
end


* =====================================================================
* MAIN ESTIMATION PROGRAM
* =====================================================================
capture program drop _xtpq_Estimate
program define _xtpq_Estimate, eclass
	syntax varlist(min=2 ts) [if] [in], TAU(numlist >0 <1 sort) ///
		[LR(varlist ts) EC(name) ///
		 P(integer 1) Q(string) PMAX(integer 4) QMAX(integer 4) ///
		 noCONStant LEVel(cilevel) ///
		 LAGSel(string) ///
		 VCE(string) BW(integer -1) KERNel(string) ///
		 PMG MG DFE ECM FULL REPLACE HLApprox ///
		 SRTable HALFlife IRF(integer 0) ///
		 GRaph NOTABle]

	_xtpqardl_load

	* ================================================================
	* Validate inputs
	* ================================================================
	if ("`mg'" != "") + ("`dfe'" != "") + ("`pmg'" != "") > 1 {
		di as err "choose only one of pmg, mg, or dfe"
		exit 198
	}
	if "`mg'" == "" & "`dfe'" == "" local pmg "pmg"

	local ntau : word count `tau'
	if `ntau' < 1 {
		di as err "tau() must specify at least one quantile"
		exit 198
	}

	if `p' < 1 {
		di as err "p() must be at least 1"
		exit 198
	}
	if "`q'" == "" local q "1"

	if "`lagsel'" != "" {
		if !inlist("`lagsel'", "aic", "bic", "both") {
			di as err "lagsel() must be one of: aic, bic, both"
			exit 198
		}
	}

	* ---- VCE options ------------------------------------------------
	if "`kernel'" == "" local kernel "bartlett"
	local kernel = lower("`kernel'")
	if !inlist("`kernel'", "bartlett", "parzen", "qs") {
		di as err "kernel() must be bartlett, parzen or qs"
		exit 198
	}
	if "`vce'" == "" {
		local vce = cond("`dfe'" != "", "robust", "mg")
	}
	local vce = lower("`vce'")
	if !inlist("`vce'", "mg", "iid", "robust", "hac", "cluster") {
		di as err "vce() must be one of: mg, iid, robust, hac, cluster"
		exit 198
	}
	if "`dfe'" != "" & "`vce'" == "mg" {
		di as txt "  (note: vce(mg) is not defined for dfe; using vce(robust))"
		local vce "robust"
	}
	if "`dfe'" == "" & "`vce'" == "cluster" {
		di as txt "  (note: vce(cluster) is not defined for the per-panel" ///
			" estimator; using vce(hac))"
		local vce "hac"
	}

	local vcelab "mean-group (Pesaran-Smith non-parametric)"
	if "`vce'" == "iid"     local vcelab "conventional (i.i.d. quantile regression)"
	if "`vce'" == "robust"  local vcelab "heteroskedasticity-robust (Powell sandwich)"
	if "`vce'" == "hac"     local vcelab "HAC (`kernel' kernel, Powell sandwich)"
	if "`vce'" == "cluster" local vcelab "cluster-robust by panel (Powell sandwich)"

	* ================================================================
	* Panel setup
	* ================================================================
	marksample touse
	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'

	if "`ivar'" == "" {
		di as err "data must be xtset or tsset as panel data"
		exit 459
	}

	tokenize `varlist'
	local depvar `1'
	mac shift
	local indepvars `*'
	local k = wordcount("`indepvars'")

	if "`lr'" == "" {
		di as err "lr() option required — specify long-run level variables"
		di as err "  Example: lr(L.y x1 x2) or lr(ly x1 x2)"
		exit 198
	}

	tokenize `lr'
	local lr_y `1'
	mac shift
	local lr_x `*'
	local k_lr  = wordcount("`lr'")
	local k_lrx = wordcount("`lr_x'")

	if `k_lrx' < 1 {
		di as err "lr() must contain the lagged dependent level plus at" ///
			" least one long-run regressor"
		exit 198
	}

	if "`ec'" == "" local ec "ECT"
	if "`replace'" != "" capture drop `ec'

	local nq : word count `q'
	if `nq' == 1 {
		local qlags ""
		forvalues j = 1/`k' {
			local qlags "`qlags' `q'"
		}
		local qlags = strtrim("`qlags'")
	}
	else if `nq' == `k' {
		local qlags "`q'"
	}
	else {
		di as err "q() must be a single number or k numbers (one per indepvar)"
		exit 198
	}

	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)

	* ================================================================
	* BIC LAG SELECTION (if lagsel specified)
	* ================================================================
	if "`lagsel'" != "" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "  {bf:PQARDL Lag Order Selection (`lagsel')}"
		di in smcl in gr "{hline 78}"

		local best_bic = .
		local best_p = 1
		forvalues j = 1/`k' {
			local best_q`j' = 1
		}

		di in gr "  BIC Grid: rows = p, columns = q"
		di in smcl in gr "  {hline 62}"
		di in gr "  {ralign 6:p \ q}" _c
		forvalues jq = 1/`qmax' {
			di in gr "  {ralign 10:q=`jq'}" _c
		}
		di ""
		di in smcl in gr "  {hline 62}"

		forvalues ip = 1/`pmax' {
			di in gr "  {ralign 6:p=`ip'}" _c

			forvalues jq = 1/`qmax' {
				local test_ar ""
				if `ip' > 1 {
					forvalues lag = 1/`= `ip' - 1' {
						tempvar test_ar_`ip'_`jq'_`lag'
						capture qui gen double `test_ar_`ip'_`jq'_`lag'' = L`lag'.`depvar' if `touse'
						if _rc == 0 {
							local test_ar "`test_ar' `test_ar_`ip'_`jq'_`lag''"
						}
					}
				}
				local test_sr ""
				forvalues xj = 1/`k' {
					local xvar : word `xj' of `indepvars'
					tempvar test_x_`ip'_`jq'_`xj'_0
					capture qui gen double `test_x_`ip'_`jq'_`xj'_0' = `xvar' if `touse'
					if _rc == 0 {
						local test_sr "`test_sr' `test_x_`ip'_`jq'_`xj'_0'"
					}
					if `jq' > 1 {
						forvalues lag = 1/`= `jq' - 1' {
							tempvar test_x_`ip'_`jq'_`xj'_`lag'
							capture qui gen double `test_x_`ip'_`jq'_`xj'_`lag'' = L`lag'.`xvar' if `touse'
							if _rc == 0 {
								local test_sr "`test_sr' `test_x_`ip'_`jq'_`xj'_`lag''"
							}
						}
					}
				}
				local test_lr ""
				forvalues lj = 1/`k_lr' {
					local lrv : word `lj' of `lr'
					tempvar test_lr_`ip'_`jq'_`lj'
					capture qui gen double `test_lr_`ip'_`jq'_`lj'' = `lrv' if `touse'
					if _rc == 0 {
						local test_lr "`test_lr' `test_lr_`ip'_`jq'_`lj''"
					}
				}

				tempvar test_dv_`ip'_`jq'
				qui gen double `test_dv_`ip'_`jq'' = `depvar' if `touse'

				local test_reg "`test_lr' `test_ar' `test_sr'"

				capture qui reg `test_dv_`ip'_`jq'' `test_reg' if `touse'
				if _rc == 0 & e(N) > 5 {
					local n_bic = e(N)
					local k_bic = e(df_m) + 1
					local rss = e(rss)
					local bic_val = `n_bic' * ln(`rss'/`n_bic') + `k_bic' * ln(`n_bic')

					if `bic_val' < `best_bic' | `best_bic' == . {
						di as res " " %9.2f `bic_val' "*" _c
						local best_bic = `bic_val'
						local best_p = `ip'
						forvalues j = 1/`k' {
							local best_q`j' = `jq'
						}
					}
					else {
						di in gr "  " %9.2f `bic_val' " " _c
					}
				}
				else {
					di in gr "  {ralign 10:    .}" _c
				}
			}
			di ""
		}

		di in smcl in gr "  {hline 62}"

		local p = `best_p'
		local qlags ""
		local qdisp ""
		forvalues j = 1/`k' {
			local qlags "`qlags' `best_q`j''"
			local qdisp "`qdisp',`best_q`j''"
		}
		local qlags = strtrim("`qlags'")

		di as res "  ► Optimal: PQARDL(`p'`qdisp')" in gr "  BIC = " %9.2f `best_bic'
		di in smcl in gr "{hline 78}"
	}

	* ================================================================
	* ARDL order string
	* ================================================================
	local ardl_order "`p'"
	forvalues j = 1/`k' {
		local qj : word `j' of `qlags'
		local ardl_order "`ardl_order',`qj'"
	}

	* ================================================================
	* Labels for the short-run block
	* ================================================================
	local sr_labels ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		local qj   : word `j' of `qlags'
		forvalues lag = 0/`= `qj' - 1' {
			if `lag' == 0 {
				local lab = cond(substr("`xvar'", 1, 2) == "D.", "`xvar'", "D.`xvar'")
			}
			else {
				local lab = cond(substr("`xvar'", 1, 2) == "D.", ///
					"L`lag'.`xvar'", "D.L`lag'.`xvar'")
			}
			local sr_labels "`sr_labels' `lab'"
		}
	}
	local ar_labels ""
	if `p' > 1 {
		forvalues lag = 1/`= `p' - 1' {
			local ar_labels "`ar_labels' D.L`lag'.`depvar'"
		}
	}

	* ================================================================
	* DISPLAY HEADER
	* ================================================================
	if "`pmg'" != ""      local model_label "Pooled Mean Group (PMG)"
	else if "`mg'" != ""  local model_label "Mean Group (MG)"
	else if "`dfe'" != "" local model_label "Dynamic Fixed Effects (DFE)"

	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "  {bf:|}" _col(5) in ye "  XTPQARDL — Panel Quantile ARDL" _col(72) in gr "{bf:|}"
	di in smcl in gr "  {bf:|}" _col(5) in ye "  Version 1.0.4" _col(72) in gr "{bf:|}"
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "{hline 78}"
	di in gr "  Model:            " in ye "`model_label'"
	di in gr "  Dep. variable:    " in ye "`depvar'"
	di in gr "  SR variables:     " in ye "`indepvars'"
	di in gr "  LR variables:     " in ye "`lr_x'"
	di in gr "  LR depvar (ECT):  " in ye "`lr_y'"
	di in gr "  PQARDL(" in ye "`ardl_order'" in gr ")"
	di in gr "  Panels (N):       " in ye "`npanels'"
	di in gr "  Time periods:     " in ye %6.2f `= `nobs' / `npanels''
	di in gr "  Observations:     " in ye "`nobs'"
	di in gr "  Std. errors:      " in ye "`vcelab'"
	if "`vce'" == "hac" & `bw' >= 0 {
		di in gr "  HAC bandwidth:    " in ye "`bw'"
	}
	else if "`vce'" == "hac" {
		di in gr "  HAC bandwidth:    " in ye "automatic (Newey-West rule)"
	}
	di in gr "  Quantiles:        " _c
	foreach tauval of local tau {
		di in ye %5.2f `tauval' " " _c
	}
	di ""

	di in smcl in gr "{hline 78}"
	di in gr "  Regressors per panel:"
	di in gr "    ECT:    " in ye "`lr_y'" in gr " (speed of adjustment rho)"
	di in gr "    LR:     " in ye "`lr_x'" in gr " (long-run beta = -coef/rho)"
	if `p' > 1 {
		di in gr "    AR:     " in ye "`ar_labels'"
	}
	di in gr "    SR:     " in ye "`sr_labels'"
	di in smcl in gr "{hline 78}"

	* ================================================================
	* ESTIMATION (PMG / MG)
	* ================================================================
	if "`dfe'" == "" {
		di
		di in gr "  {bf:Step 1:} Estimating PQARDL(`ardl_order') per panel..."

		local poolopt = cond("`pmg'" != "", "poollr", "")

		_xtpqardl_estimate, depvar(`depvar') indepvars(`indepvars') ///
			lrvars(`lr') p(`p') qlags(`qlags') ///
			tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
			vce(`vce') bw(`bw') kernel(`kernel') `poolopt' `constant'

		local valid_panels = r(valid_panels)
		local k_est        = r(k)
		local k_lr_est     = r(k_lr)
		local ncoefs_sr    = r(ncoefs_sr)
		local ncoefs_ar    = r(ncoefs_ar)
		local M            = r(M)
		local n_mg         = r(n_mg)
		local n_pool       = r(n_pool)
		local export_panels = r(export_panels)
		local pooled       "`r(pooled)'"
		local poolmeth     "`r(poolmeth)'"
		local haus         = r(hausman)
		local hausdf       = r(hausman_df)
		local hausp        = r(hausman_p)

		di in gr "  ► " in ye "`valid_panels'" in gr "/" in ye "`npanels'" ///
			in gr " panels estimated successfully"

		if `valid_panels' == 0 {
			local ncoefs_tot = `k_lr_est' + (`p' - 1) + `ncoefs_sr'
			local min_T = `ncoefs_tot' + 2
			local avg_T = round(`nobs' / `npanels', 0.1)
			di as err "  ERROR: No panels could be estimated"
			di as err "  Reason: insufficient degrees of freedom"
			di as err "  The PQARDL(`ardl_order') model has `ncoefs_tot' regressors" ///
				" (+ constant)"
			di as err "  Each panel needs at least T >= `min_T' non-missing observations,"
			di as err "  but average T in the data is about `avg_T'"
			di as err "  Suggestions:"
			di as err "    - Reduce the number of predictors"
			di as err "    - Use longer time series (more periods)"
			di as err "    - Try the {bf:dfe} option (pools across panels)"
			exit 2000
		}

		tempname g_mg g_V g_Vnp g_Veff
		tempname rho_mg beta_mg halflife_mg phi_mg sr_mg rho_V beta_V
		tempname rho_all beta_all halflife_all phi_all sr_all panelids

		matrix `g_mg'   = r(g_mg)
		matrix `g_V'    = r(g_V)
		matrix `g_Vnp'  = r(g_Vnp)
		matrix `g_Veff' = r(g_Veff)

		matrix `rho_mg'      = r(rho_mg)
		matrix `beta_mg'     = r(beta_mg)
		matrix `halflife_mg' = r(halflife_mg)
		matrix `phi_mg'      = r(phi_mg)
		matrix `sr_mg'       = r(sr_mg)
		matrix `rho_V'       = r(rho_V)
		matrix `beta_V'      = r(beta_V)

		if `export_panels' {
			matrix `rho_all'      = r(rho_all)
			matrix `beta_all'     = r(beta_all)
			matrix `halflife_all' = r(halflife_all)
			matrix `phi_all'      = r(phi_all)
			matrix `sr_all'       = r(sr_all)
			matrix `panelids'     = r(panelids)
			local npest = rowsof(`rho_all')
		}

		* Approximate half-life on request (pre-1.0.4 formula)
		if "`hlapprox'" != "" {
			forvalues t = 1/`ntau' {
				local rv = `rho_mg'[1, `t']
				if `rv' < . & `rv' < 0 {
					matrix `halflife_mg'[1, `t'] = ln(2) / abs(`rv')
				}
			}
		}

		if "`pooled'" != "" {
			di in gr "  ► Long-run coefficients pooled across " in ye "`n_pool'" ///
				in gr " panels (`poolmeth')"
		}
		di in gr "  ► Mean-group covariance from " in ye "`n_mg'" ///
			in gr " complete-case panels"

		* ==============================================================
		* DISPLAY TABLES
		* ==============================================================
		if "`notable'" == "" {

			* --- Table 1: Long-run beta(tau) ---------------------------
			_xtpq_header "Table 1: Long-Run Cointegrating Parameters beta(tau)" ///
				"beta_j(tau) = -coef(x_j) / rho(tau)"
			_xtpq_colhead

			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 55}"
				local o = (`ti' - 1) * `M'
				local vnum = 0
				foreach v of local lr_x {
					local ++vnum
					local idx = `o' + 1 + `vnum'
					_xtpq_prow "`v'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"

			* --- Table 2: ECM speed of adjustment ----------------------
			_xtpq_header "Table 2: ECM Speed of Adjustment rho(tau)" ///
				"rho(tau) = coef(`lr_y') — negative implies convergence"
			di in gr "  {ralign 10:Quantile}" _c
			di in gr " {ralign 12:rho(tau)}" _c
			di in gr " {ralign 11:Std.Err.}" _c
			di in gr " {ralign 9:z}" _c
			di in gr " {ralign 9:P>|z|}" _c
			di in gr " {ralign 10:Half-Life}" _c
			di in gr " {ralign 12:Status}"
			di in smcl in gr "{hline 78}"

			local ti = 0
			foreach tauval of local tau {
				local ++ti
				local o   = (`ti' - 1) * `M'
				local idx = `o' + 1
				local rho_val = `g_mg'[1, `idx']
				local hl_val  = `halflife_mg'[1, `ti']

				if `rho_val' >= . {
					di in gr "  {ralign 10:tau=" %4.2f `tauval' "}" _c
					di in gr " {ralign 12:       n/a}" _c
					di in gr " {ralign 11: }" _c
					di in gr " {ralign 9: }" _c
					di in gr " {ralign 9: }" _c
					di in gr " {ralign 10:   n/a}" _c
					di in gr " {ralign 12:   —}"
					continue
				}

				local rvar = `g_V'[`idx', `idx']
				local se = .
				local zstat = .
				local pval = .
				if `rvar' > 0 & `rvar' < . {
					local se    = sqrt(`rvar')
					local zstat = `rho_val' / `se'
					local pval  = 2 * normal(-abs(`zstat'))
				}

				if `rho_val' < -0.5      local status "Strong"
				else if `rho_val' < -0.1 local status "Moderate"
				else if `rho_val' < 0    local status "Weak"
				else                     local status "No conv."

				di in gr "  {ralign 10:tau=" %4.2f `tauval' "}" _c
				if `rho_val' < -0.1 {
					di in ye " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				else if `rho_val' < 0 {
					di in gr " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				else {
					di as res " {ralign 12:" %10.4f `rho_val' "}" _c
				}

				if `se' < . {
					di in gr " {ralign 11:" %9.4f `se' "}" _c
					di in gr " {ralign 9:" %7.2f `zstat' "}" _c
					if `pval' < 0.05 {
						di as res " {ralign 9:" %7.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 9:" %7.4f `pval' "}" _c
					}
				}
				else {
					di in gr " {ralign 11:        .}" _c
					di in gr " {ralign 9:      .}" _c
					di in gr " {ralign 9:      .}" _c
				}

				if `hl_val' < . & `hl_val' > 0 {
					di in ye " {ralign 10:" %8.2f `hl_val' "}" _c
				}
				else {
					di in gr " {ralign 10:     inf}" _c
				}

				if `rho_val' < -0.1 {
					di in ye " {ralign 12:`status'}"
				}
				else {
					di as res " {ralign 12:`status'}"
				}
			}
			di in smcl in gr "{hline 78}"
			if "`hlapprox'" != "" {
				di in gr "  Half-life = ln(2)/|rho(tau)|   (hlapprox: first-order approximation)"
			}
			else {
				di in gr "  Half-life = ln(0.5)/ln(1+rho(tau)) — periods to close 50% of the gap"
			}

			* --- Table 3: Short-run ECM parameters ---------------------
			_xtpq_header "Table 3: Short-Run Error Correction Parameters" ///
				"D.y = rho(t)*ECT(t-1) + sum phi* D.y(t-j) + sum theta D.x(t-m) + e"
			_xtpq_colhead

			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 55}"
				local o = (`ti' - 1) * `M'

				* ECT
				local idx = `o' + 1
				_xtpq_prow "ECT(t-1)" `tauval' (`g_mg'[1,`idx']) ///
					(`g_V'[`idx',`idx']) `level'

				* AR lags of D.y
				forvalues j = 1/`ncoefs_ar' {
					local lab : word `j' of `ar_labels'
					local idx = `o' + 1 + `k_lrx' + `j'
					_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}

				* Short-run impacts
				forvalues j = 1/`ncoefs_sr' {
					local lab : word `j' of `sr_labels'
					local idx = `o' + 1 + `k_lrx' + `ncoefs_ar' + `j'
					_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  ECT = `lr_y' - beta(tau)'X   (error correction term)"
			di in gr "  Std. errors: `vcelab'"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in smcl in gr "{hline 78}"
		}

		* ==============================================================
		* Per-panel ECT table
		* ==============================================================
		if ("`srtable'" != "" | "`full'" != "") & `export_panels' {
			_xtpq_header "Per-Panel ECT Speed of Adjustment rho_i(tau)" ""
			di in gr "  {ralign 10:Panel}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:tau=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"

			forvalues pi = 1/`npest' {
				local i = `panelids'[`pi', 1]
				di in gr "  {ralign 10:`i'}" _c
				forvalues t = 1/`ntau' {
					local rv = `rho_all'[`pi', `t']
					if `rv' < . {
						if `rv' < -0.5 {
							di in ye " {ralign 12:" %10.4f `rv' "}" _c
						}
						else if `rv' < 0 {
							di in gr " {ralign 12:" %10.4f `rv' "}" _c
						}
						else {
							di as res " {ralign 12:" %10.4f `rv' "}" _c
						}
					}
					else {
						di in gr " {ralign 12:     n/a}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
			di in gr "  Yellow = strong convergence (rho < -0.5);" ///
				" Red = non-convergent (rho >= 0)"
		}
		else if ("`srtable'" != "" | "`full'" != "") & !`export_panels' {
			di in gr "  (per-panel table suppressed: too many panels to store" ///
				" as a Stata matrix)"
		}

		* ==============================================================
		* Half-life table
		* ==============================================================
		if "`halflife'" != "" & `export_panels' {
			_xtpq_header "Half-Life of Adjustment HL_i(tau)" ///
				"HL = ln(0.5)/ln(1+rho_i(tau))"
			di in gr "  {ralign 10:Panel}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:tau=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"

			forvalues pi = 1/`npest' {
				local i = `panelids'[`pi', 1]
				di in gr "  {ralign 10:`i'}" _c
				forvalues t = 1/`ntau' {
					local hv = `halflife_all'[`pi', `t']
					if `hv' < . & `hv' > 0 {
						if `hv' < 5 {
							di in ye " {ralign 12:" %10.2f `hv' "}" _c
						}
						else {
							di in gr " {ralign 12:" %10.2f `hv' "}" _c
						}
					}
					else {
						di in gr " {ralign 12:     n/a}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
			di in ye "  {ralign 10:Mean}" _c
			forvalues t = 1/`ntau' {
				local mhl = `halflife_mg'[1, `t']
				if `mhl' < . & `mhl' > 0 {
					di in ye " {ralign 12:" %10.2f `mhl' "}" _c
				}
				else {
					di in gr " {ralign 12:     n/a}" _c
				}
			}
			di ""
			di in smcl in gr "{hline 78}"
		}

		* ==============================================================
		* IRF simulation by quantile
		* ==============================================================
		if `irf' > 0 {
			_xtpq_header "Impulse Response Function by Quantile" ///
				"Response of a unit ECM disequilibrium: (1+rho)^h"
			di in gr "  {ralign 8:Period}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:tau=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"

			forvalues t = 0/`irf' {
				di in gr "  {ralign 8:`t'}" _c
				local ti = 0
				foreach tauval of local tau {
					local ++ti
					local rv = `rho_mg'[1, `ti']
					if `rv' < . & `rv' < 0 & `rv' > -2 {
						local irf_val = (1 + `rv')^`t'
						if `irf_val' > 0.5 {
							di in ye " {ralign 12:" %10.4f `irf_val' "}" _c
						}
						else {
							di in gr " {ralign 12:" %10.4f `irf_val' "}" _c
						}
					}
					else {
						di as res " {ralign 12:     div.}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
		}

		* ==============================================================
		* Wald tests
		* ==============================================================
		if `ntau' >= 2 {
			_xtpqardl_waldtest, gmat(`g_mg') vmat(`g_Vnp') tau(`tau') ///
				kx(`k_lrx') nar(`ncoefs_ar') nsr(`ncoefs_sr') mdim(`M') ///
				note("Covariance: non-parametric mean-group (the only one carrying cross-quantile blocks)")
			local w_beta  = r(wald_beta)
			local w_rho   = r(wald_rho)
			local w_sr    = r(wald_sr)
			local w_joint = r(wald_joint)
		}

		* ==============================================================
		* Hausman test of long-run homogeneity (PMG vs MG)
		* ==============================================================
		if "`pooled'" != "" {
			_xtpq_header "Hausman Test of Long-Run Homogeneity (PMG vs MG)" ///
				"H0: the pooled long run is valid — PMG is consistent and efficient"
			if `haus' < . & `hausdf' < . {
				di in gr "  {ralign 28:chi2(`hausdf')}" _c
				di as res " {ralign 12:" %10.3f `haus' "}" _c
				di in gr "   Prob > chi2 = " _c
				if `hausp' < 0.05 {
					di as res %6.4f `hausp' _c
					di in gr "   => reject: use {bf:mg}"
				}
				else {
					di in gr %6.4f `hausp' _c
					di in gr "   => do not reject: {bf:pmg} is supported"
				}
			}
			else {
				di in gr "  (Hausman statistic not computable — the difference in"
				di in gr "   covariances is not positive definite, which usually means"
				di in gr "   the long run is very imprecisely estimated)"
			}
			di in smcl in gr "{hline 78}"
		}

		* ==============================================================
		* Post results
		* ==============================================================
		_xtpq_names, tau(`tau') mdim(`M') lrx(`lr_x') ///
			arlab(`ar_labels') srlab(`sr_labels')
		local eqnames "`r(eqnames)'"
		local cnames  "`r(cnames)'"

		tempname bpost Vpost
		matrix `bpost' = `g_mg'
		matrix `Vpost' = `g_V'

		local postable = 1
		local GD = colsof(`bpost')
		forvalues c = 1/`GD' {
			if `bpost'[1, `c'] >= . local postable = 0
		}

		ereturn clear
		if `postable' {
			matrix colnames `bpost' = `cnames'
			matrix coleq    `bpost' = `eqnames'
			matrix colnames `Vpost' = `cnames'
			matrix rownames `Vpost' = `cnames'
			matrix coleq    `Vpost' = `eqnames'
			matrix roweq    `Vpost' = `eqnames'
			capture noisily ereturn post `bpost' `Vpost', ///
				esample(`touse') obs(`nobs') depname(`depvar')
			if _rc {
				ereturn post, esample(`touse') obs(`nobs')
				local postable = 0
			}
		}
		else {
			ereturn post, esample(`touse') obs(`nobs')
		}

		ereturn matrix g_mg   = `g_mg'
		ereturn matrix g_V    = `g_V'
		ereturn matrix g_Vnp  = `g_Vnp'
		ereturn matrix g_Veff = `g_Veff'

		ereturn matrix beta_mg     = `beta_mg'
		ereturn matrix rho_mg      = `rho_mg'
		ereturn matrix halflife_mg = `halflife_mg'
		ereturn matrix phi_mg      = `phi_mg'
		ereturn matrix sr_mg       = `sr_mg'
		ereturn matrix beta_V      = `beta_V'
		ereturn matrix rho_V       = `rho_V'

		if `export_panels' {
			ereturn matrix beta_all     = `beta_all'
			ereturn matrix rho_all      = `rho_all'
			ereturn matrix halflife_all = `halflife_all'
			ereturn matrix phi_all      = `phi_all'
			ereturn matrix sr_all       = `sr_all'
			ereturn matrix panelids     = `panelids'
		}

		if "`w_beta'" != "" {
			capture ereturn scalar wald_beta  = `w_beta'
			capture ereturn scalar wald_rho   = `w_rho'
			capture ereturn scalar wald_sr    = `w_sr'
			capture ereturn scalar wald_joint = `w_joint'
		}

		ereturn scalar N            = `nobs'
		ereturn scalar n_g          = `npanels'
		ereturn scalar valid_panels = `valid_panels'
		ereturn scalar n_mg         = `n_mg'
		ereturn scalar n_pool       = `n_pool'
		capture ereturn scalar hausman    = `haus'
		capture ereturn scalar hausman_df = `hausdf'
		capture ereturn scalar hausman_p  = `hausp'
		ereturn scalar p            = `p'
		ereturn scalar k            = `k'
		ereturn scalar k_lr         = `k_lrx'
		ereturn scalar ntau         = `ntau'
		ereturn scalar M            = `M'
		ereturn scalar level        = `level'

		ereturn local depvar    "`depvar'"
		ereturn local indepvars "`indepvars'"
		ereturn local lrvars    "`lr_x'"
		ereturn local lr_y      "`lr_y'"
		ereturn local srlabels  "`sr_labels'"
		ereturn local arlabels  "`ar_labels'"
		ereturn local taulist   "`tau'"
		ereturn local ivar      "`ivar'"
		ereturn local tvar      "`tvar'"
		ereturn local cmd       "xtpqardl"
		ereturn local title     "PQARDL Estimation"
		ereturn local ardl_order "PQARDL(`ardl_order')"
		ereturn local qlags     "`qlags'"
		ereturn local vce       "`vce'"
		ereturn local poolmeth  "`poolmeth'"
		ereturn local vcetype   "`vcelab'"
		ereturn local kernel    "`kernel'"
		ereturn local author    "Dr Merwan Roudane"
		ereturn local email     "merwanroudane920@gmail.com"

		if "`pmg'" != ""     ereturn local model "pmg"
		else if "`mg'" != "" ereturn local model "mg"

		* ==============================================================
		* Graphs
		* ==============================================================
		if "`graph'" != "" {
			xtpqardl_graph, tau(`tau') p(`p') q(1) k(`k_lrx') ///
				depvar("`depvar'") indepvars("`lr_x'") ///
				ecm npanels(`npanels') ivar("`ivar'")
		}
	}

	* ================================================================
	* DFE ESTIMATION
	* ================================================================
	else {
		di
		di in gr "  {bf:Step 1:} Pooled quantile regression with panel FE..."

		if `npanels' > 500 {
			di as err "  ERROR: dfe requires one dummy per panel and this"
			di as err "  data set has `npanels' panels."
			di as err "  Use {bf:mg} or {bf:pmg} instead, or estimate dfe on a subset."
			exit 198
		}

		qui tab `ivar' if `touse', gen(__xtpqfe_)
		local ndummies = r(r)
		local fe_vars ""
		forvalues j = 2/`ndummies' {
			local fe_vars "`fe_vars' __xtpqfe_`j'"
		}

		local sr_list ""
		forvalues j = 1/`k' {
			local xvar : word `j' of `indepvars'
			local qj   : word `j' of `qlags'
			local sr_list "`sr_list' `xvar'"
			if `qj' > 1 {
				forvalues lag = 1/`= `qj' - 1' {
					local sr_list "`sr_list' L`lag'.`xvar'"
				}
			}
		}

		local ar_list ""
		if `p' > 1 {
			forvalues lag = 1/`= `p' - 1' {
				local ar_list "`ar_list' L`lag'.`depvar'"
			}
		}

		local ncoefs_ar = `p' - 1
		local ncoefs_sr : word count `sr_list'
		local nrest     = `ncoefs_ar' + `ncoefs_sr'
		local M         = 1 + `k_lrx' + `nrest'
		local GD        = `M' * `ntau'

		local dfe_core "`lr' `ar_list' `sr_list'"
		local dfe_reg  "`dfe_core' `fe_vars'"

		tempname g_mg g_V b_dfe V_dfe g_i Vg_i halflife_mg rho_mg beta_mg
		matrix `g_mg' = J(1, `GD', .)
		matrix `g_V'  = J(`GD', `GD', 0)

		* qreg needs plain variables for the sandwich; build them once
		tempvar dv_p
		qui gen double `dv_p' = `depvar' if `touse'
		local reg_p ""
		local rj = 0
		foreach rv of local dfe_reg {
			local ++rj
			tempvar rp`rj'
			qui gen double `rp`rj'' = `rv' if `touse'
			local reg_p "`reg_p' `rp`rj''"
		}

		local ti = 0
		local nfit = 0
		foreach tauval of local tau {
			local ++ti

			capture qui qreg `dv_p' `reg_p' if `touse', quantile(`tauval') `constant'
			local rc_d = _rc
			if `rc_d' != 0 & `rc_d' != 498 {
				di in gr "    (tau=`tauval': qreg rc=`rc_d' — skipped)"
				continue
			}
			local ++nfit
			matrix `b_dfe' = e(b)

			local have_V = 0
			if inlist("`vce'", "robust", "hac", "cluster") {
				capture _xtpqardl_vce, yvar(`dv_p') xvars(`reg_p') ///
					touse(`touse') tau(`tauval') bname(`b_dfe') ///
					vce(`vce') bw(`bw') kernel(`kernel') ///
					tvar(`tvar') clustvar(`ivar') `constant'
				if _rc == 0 {
					if r(ok) == 1 {
						matrix `V_dfe' = r(V)
						local have_V = 1
					}
				}
			}
			if `have_V' == 0 & `rc_d' == 0 {
				capture matrix `V_dfe' = e(V)
				if _rc == 0 local have_V = 1
			}
			if `have_V' == 0 {
				local KD = colsof(`b_dfe')
				matrix `V_dfe' = J(`KD', `KD', .)
			}

			* keep only the structural block (drop the FE dummies)
			local nkeep = 1 + `k_lrx' + `nrest'
			matrix `b_dfe' = `b_dfe'[1, 1..`nkeep']
			matrix `V_dfe' = `V_dfe'[1..`nkeep', 1..`nkeep']

			_xtpqardl_delta, bname(`b_dfe') vname(`V_dfe') kx(`k_lrx') ///
				nrest(`nrest') gname(`g_i') vgname(`Vg_i')

			local o = (`ti' - 1) * `M'
			forvalues a = 1/`M' {
				matrix `g_mg'[1, `o' + `a'] = `g_i'[1, `a']
				forvalues b = 1/`M' {
					matrix `g_V'[`o' + `a', `o' + `b'] = `Vg_i'[`a', `b']
				}
			}
		}

		capture drop __xtpqfe_*

		if `nfit' == 0 {
			di as err "  ERROR: the pooled quantile regression failed at every quantile"
			exit 2000
		}

		* rho / half-life views
		matrix `rho_mg'      = J(1, `ntau', .)
		matrix `halflife_mg' = J(1, `ntau', .)
		matrix `beta_mg'     = J(1, `= `k_lrx' * `ntau'', .)
		forvalues t = 1/`ntau' {
			local o = (`t' - 1) * `M'
			matrix `rho_mg'[1, `t'] = `g_mg'[1, `o' + 1]
			local rv = `rho_mg'[1, `t']
			if `rv' < . & `rv' < 0 & `rv' > -2 {
				if "`hlapprox'" != "" {
					matrix `halflife_mg'[1, `t'] = ln(2) / abs(`rv')
				}
				else {
					matrix `halflife_mg'[1, `t'] = ln(0.5) / ln(1 + `rv')
				}
			}
			forvalues j = 1/`k_lrx' {
				matrix `beta_mg'[1, (`t' - 1) * `k_lrx' + `j'] = ///
					`g_mg'[1, `o' + 1 + `j']
			}
		}

		if "`notable'" == "" {
			_xtpq_header "Table 1: DFE Long-Run Cointegrating Parameters beta(tau)" ///
				"beta_j(tau) = -coef(x_j) / rho(tau)"
			_xtpq_colhead
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 55}"
				local o = (`ti' - 1) * `M'
				local vnum = 0
				foreach v of local lr_x {
					local ++vnum
					local idx = `o' + 1 + `vnum'
					_xtpq_prow "`v'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"

			_xtpq_header "Table 2: DFE Short-Run / ECM Parameters" ///
				"D.y = rho(t)*ECT(t-1) + sum phi* D.y(t-j) + sum theta D.x(t-m) + e"
			_xtpq_colhead
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 55}"
				local o = (`ti' - 1) * `M'

				local idx = `o' + 1
				_xtpq_prow "ECT(t-1)" `tauval' (`g_mg'[1,`idx']) ///
					(`g_V'[`idx',`idx']) `level'
				forvalues j = 1/`ncoefs_ar' {
					local lab : word `j' of `ar_labels'
					local idx = `o' + 1 + `k_lrx' + `j'
					_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}
				forvalues j = 1/`ncoefs_sr' {
					local lab : word `j' of `sr_labels'
					local idx = `o' + 1 + `k_lrx' + `ncoefs_ar' + `j'
					_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) ///
						(`g_V'[`idx',`idx']) `level'
				}

				local hl = `halflife_mg'[1, `ti']
				if `hl' < . {
					di in gr "  {ralign 16:Half-life}" _c
					di in gr " {ralign 9:" %5.2f `tauval' "}" _c
					di in ye " {ralign 12:" %10.2f `hl' "}"
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  Std. errors: `vcelab'"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in smcl in gr "{hline 78}"
		}

		if `ntau' >= 2 {
			_xtpqardl_waldtest, gmat(`g_mg') vmat(`g_V') tau(`tau') ///
				kx(`k_lrx') nar(`ncoefs_ar') nsr(`ncoefs_sr') mdim(`M') ///
				note("Covariance: `vcelab'; quantiles fitted separately, so cross-quantile blocks are zero")
			local w_beta  = r(wald_beta)
			local w_rho   = r(wald_rho)
			local w_sr    = r(wald_sr)
			local w_joint = r(wald_joint)
		}

		_xtpq_names, tau(`tau') mdim(`M') lrx(`lr_x') ///
			arlab(`ar_labels') srlab(`sr_labels')
		local eqnames "`r(eqnames)'"
		local cnames  "`r(cnames)'"

		local postable = 1
		forvalues c = 1/`GD' {
			if `g_mg'[1, `c'] >= . local postable = 0
		}

		ereturn clear
		if `postable' {
			tempname bpost Vpost
			matrix `bpost' = `g_mg'
			matrix `Vpost' = `g_V'
			matrix colnames `bpost' = `cnames'
			matrix coleq    `bpost' = `eqnames'
			matrix colnames `Vpost' = `cnames'
			matrix rownames `Vpost' = `cnames'
			matrix coleq    `Vpost' = `eqnames'
			matrix roweq    `Vpost' = `eqnames'
			capture noisily ereturn post `bpost' `Vpost', ///
				esample(`touse') obs(`nobs') depname(`depvar')
			if _rc ereturn post, esample(`touse') obs(`nobs')
		}
		else {
			ereturn post, esample(`touse') obs(`nobs')
		}

		ereturn matrix g_mg        = `g_mg'
		ereturn matrix g_V         = `g_V'
		ereturn matrix beta_mg     = `beta_mg'
		ereturn matrix rho_mg      = `rho_mg'
		ereturn matrix halflife_mg = `halflife_mg'

		if "`w_beta'" != "" {
			capture ereturn scalar wald_beta  = `w_beta'
			capture ereturn scalar wald_rho   = `w_rho'
			capture ereturn scalar wald_sr    = `w_sr'
			capture ereturn scalar wald_joint = `w_joint'
		}

		ereturn scalar N     = `nobs'
		ereturn scalar n_g   = `npanels'
		ereturn scalar p     = `p'
		ereturn scalar k     = `k'
		ereturn scalar k_lr  = `k_lrx'
		ereturn scalar ntau  = `ntau'
		ereturn scalar M     = `M'
		ereturn scalar level = `level'

		ereturn local depvar     "`depvar'"
		ereturn local indepvars  "`indepvars'"
		ereturn local lrvars     "`lr_x'"
		ereturn local lr_y       "`lr_y'"
		ereturn local srlabels   "`sr_labels'"
		ereturn local arlabels   "`ar_labels'"
		ereturn local taulist    "`tau'"
		ereturn local cmd        "xtpqardl"
		ereturn local model      "dfe"
		ereturn local vce        "`vce'"
		ereturn local vcetype    "`vcelab'"
		ereturn local kernel     "`kernel'"
		ereturn local ardl_order "PQARDL(`ardl_order')"
		ereturn local author     "Dr Merwan Roudane"
	}

	* ================================================================
	* FOOTER
	* ================================================================
	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:XTPQARDL v1.0.4} — Panel Quantile ARDL" ///
		_col(50) in ye "PQARDL(`ardl_order')"
	di in smcl in gr "{hline 78}"
	di
end


* =====================================================================
* REPLAY
* =====================================================================
capture program drop _xtpq_Display
program define _xtpq_Display, eclass
	syntax [, LEVel(cilevel)]

	if "`level'" == "" local level = e(level)
	if "`level'" == "" local level = c(level)

	tempname g_mg g_V
	capture matrix `g_mg' = e(g_mg)
	if _rc {
		di as err "no stored xtpqardl results to replay"
		exit 301
	}
	matrix `g_V' = e(g_V)

	local M    = e(M)
	local kx   = e(k_lr)
	local arlab "`e(arlabels)'"
	local srlab "`e(srlabels)'"
	local lrvv  "`e(lrvars)'"
	local nar  = wordcount("`arlab'")
	local nsr  = wordcount("`srlab'")
	local tau  "`e(taulist)'"

	_xtpq_header "xtpqardl results (`e(model)') — `e(ardl_order)'" ///
		"Std. errors: `e(vcetype)'"
	_xtpq_colhead

	local ti = 0
	foreach tauval of local tau {
		local ++ti
		di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 55}"
		local o = (`ti' - 1) * `M'

		local idx = `o' + 1
		_xtpq_prow "ECT(t-1)" `tauval' (`g_mg'[1,`idx']) (`g_V'[`idx',`idx']) `level'

		local vnum = 0
		foreach v of local lrvv {
			local ++vnum
			local idx = `o' + 1 + `vnum'
			_xtpq_prow "LR:`v'" `tauval' (`g_mg'[1,`idx']) (`g_V'[`idx',`idx']) `level'
		}
		forvalues j = 1/`nar' {
			local lab : word `j' of `arlab'
			local idx = `o' + 1 + `kx' + `j'
			_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) (`g_V'[`idx',`idx']) `level'
		}
		forvalues j = 1/`nsr' {
			local lab : word `j' of `srlab'
			local idx = `o' + 1 + `kx' + `nar' + `j'
			_xtpq_prow "`lab'" `tauval' (`g_mg'[1,`idx']) (`g_V'[`idx',`idx']) `level'
		}
	}
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* =====================================================================
* DISPLAY HELPERS
* =====================================================================
capture program drop _xtpq_header
program define _xtpq_header
	args title subtitle
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "  {bf:|}  " in ye "{bf:`title'}"
	if `"`subtitle'"' != "" {
		di in smcl in gr "  {bf:|}  " in gr "`subtitle'"
	}
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "{hline 78}"
end

capture program drop _xtpq_colhead
program define _xtpq_colhead
	di in gr "  {ralign 16:Variable}" _c
	di in gr " {ralign 9:Quantile}" _c
	di in gr " {ralign 12:Coef.}" _c
	di in gr " {ralign 11:Std.Err.}" _c
	di in gr " {ralign 9:z}" _c
	di in gr " {ralign 9:P>|z|}" _c
	di in gr " {ralign 4: }"
	di in smcl in gr "{hline 78}"
end

* print one coefficient row: label, tau, estimate, variance, level
capture program drop _xtpq_prow
program define _xtpq_prow
	args lab tauval est var level

	if "`level'" == "" local level = c(level)

	di in gr "  {ralign 16:`lab'}" _c
	di in gr " {ralign 9:" %5.2f `tauval' "}" _c

	if `est' >= . {
		di in gr " {ralign 12:       n/a}" _c
		di in gr " {ralign 11:        .}" _c
		di in gr " {ralign 9:      .}" _c
		di in gr " {ralign 9:      .}" _c
		di in gr " {ralign 4: }"
		exit
	}

	di as res " {ralign 12:" %10.4f `est' "}" _c

	local se = .
	local z  = .
	local pv = .
	if `var' > 0 & `var' < . {
		local se = sqrt(`var')
		local z  = `est' / `se'
		local pv = 2 * normal(-abs(`z'))
	}

	if `se' >= . {
		di in gr " {ralign 11:        .}" _c
		di in gr " {ralign 9:      .}" _c
		di in gr " {ralign 9:      .}" _c
		di in gr " {ralign 4: }"
		exit
	}

	local stars ""
	if `pv' < 0.01      local stars "***"
	else if `pv' < 0.05 local stars "** "
	else if `pv' < 0.10 local stars "*  "

	di in gr " {ralign 11:" %9.4f `se' "}" _c
	di in gr " {ralign 9:" %7.2f `z' "}" _c
	if `pv' < 0.01 {
		di as res " {ralign 9:" %7.4f `pv' "}" _c
	}
	else if `pv' < 0.05 {
		di as res " {ralign 9:" %7.4f `pv' "}" _c
	}
	else {
		di in gr " {ralign 9:" %7.4f `pv' "}" _c
	}
	di in ye " `stars'"
end

* build equation and coefficient names for ereturn post
capture program drop _xtpq_names
program define _xtpq_names, rclass
	syntax , TAU(numlist) MDIM(integer) LRX(string) ///
		[ARLAB(string) SRLAB(string)]

	local eqnames ""
	local cnames  ""

	foreach tauval of local tau {
		local eqn = "q" + subinstr(strtrim("`: di %5.3f `tauval''"), ".", "", .)

		local this "ECT"
		foreach v of local lrx {
			local vs = subinstr("`v'", ".", "_", .)
			local vs = subinstr("`vs'", "-", "_", .)
			local this "`this' lr_`vs'"
		}
		foreach v of local arlab {
			local vs = subinstr("`v'", ".", "_", .)
			local this "`this' `vs'"
		}
		foreach v of local srlab {
			local vs = subinstr("`v'", ".", "_", .)
			local this "`this' `vs'"
		}

		local nthis : word count `this'
		forvalues a = 1/`nthis' {
			local w : word `a' of `this'
			local cnames  "`cnames' `w'"
			local eqnames "`eqnames' `eqn'"
		}
	}

	return local eqnames "`eqnames'"
	return local cnames  "`cnames'"
end
