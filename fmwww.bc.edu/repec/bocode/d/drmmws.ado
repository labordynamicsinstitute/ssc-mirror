*! 3.00 Ariel Linden 27May2026	// added multivalued treatments (seemless to user)
*! 2.00 Ariel Linden 24May2026 // added delta-method default; bootstrap option
*! 1.00 Ariel Linden 14Dec2016

program drmmws, eclass

version 13

	syntax varlist [if] [in] [,					///
			OVars(string)						/// covariates in outcome model
			PVars(string)						/// covariates in pscore model
			NSTRata(string)						/// number of strata per level, default 5
			COMMon								/// implement common support
			ATT									/// ATT (binary treatments only)
			CONTrol(string)						/// reference treatment level (default: lowest)
			Family(string)						/// family in GLM outcome model
			Link(string)						/// link in GLM outcome model
			MEDian								/// estimate median treatment effects
			POMeans								/// show all POMs instead of treatment effects
			Bootstrap							/// use bootstrap for SEs
			NODots								/// suppress bootstrap replication dots
			SEED(string)						/// seed for bootstrap
			REPS(integer 200)					/// bootstrap replications
			LEVel(cilevel)						/// confidence level
			COEFLegend]							// display coef legend

	quietly {
		tokenize `varlist'
		local outcome `1'
		macro shift
		local treat `1'
		macro shift
		local preds `*'

		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		replace `touse' = -`touse'

		// defaults
		if "`ovars'"   == "" local ovars   `preds'
		if "`pvars'"   == "" local pvars   `preds'
		if "`family'"  == "" local family  gaussian
		if "`link'"    == "" local link    identity
		if "`nstrata'" == "" local nstrata 5

		// count treatment levels
		levelsof `treat' if `touse', local(tlevels)
		local K : word count `tlevels'

		// validate nstrata
		local n_nstrata : word count `nstrata'
		if `K' == 2 & `n_nstrata' > 1 {
			di as err "nstrata() accepts only one value for binary treatments"
			exit 198
		}

		// resolve control() level
		if "`control'" != "" {
			local ctrl_num = .
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				local lbl : label (`treat') `lv', strict
				if `"`lbl'"' == `"`control'"' local ctrl_num = `lv'
			}
			if `ctrl_num' == . {
				capture confirm integer number `control'
				if _rc {
					di as err "control() must be a numeric level or value label of `treat'"
					exit 198
				}
				local ctrl_num = `control'
			}
			local control_level = `ctrl_num'
		}
		else {
			local control_level : word 1 of `tlevels'
		}

		// validate control level exists
		count if `treat' == `control_level' & `touse'
		if r(N) == 0 {
			di as err "control() level `control_level' not found in `treat'"
			exit 198
		}

		// option conflicts
		if `K' == 2 {
			if "`pomeans'" != "" {
				di as err "pomeans is only available for multi-valued treatments"
				exit 198
			}
		}
		else {
			if "`att'" != "" {
				di as err "att is only available for binary treatments"
				exit 198
			}
			if "`pomeans'" != "" & "`control'" != "" {
				di as err "control() may not be specified with pomeans"
				exit 198
			}
		}

		// title
		if `K' == 2 {
			if      "`att'" != "" & "`median'" != "" local effect MTT
			else if "`att'" != ""                    local effect ATT
			else if "`median'" != ""                 local effect MTE
			else                                     local effect ATE
		}
		else {
			if "`median'" != "" local effect MTE
			else                local effect ATE
		}
		if "`common'" != "" local title "Estimation of `effect' with common support"
		else                 local title "Estimation of `effect'"

		// get value labels for multi-valued display
		if `K' > 2 {
			local vlname : value label `treat'
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				if "`vlname'" != "" local lbl`lv' : label `vlname' `lv'
				else                 local lbl`lv' "level `lv'"
			}
			local ctrl_lbl "`lbl`control_level''"
			local te_levels ""
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				if `lv' != `control_level' local te_levels `te_levels' `lv'
			}
		}

	} // end quietly

	*****************
	*** BOOTSTRAP ***
	*****************
	if "`bootstrap'" != "" {
		if `K' == 2 {
			// fit one GLM to capture outcome model labels before bootstrap
			if "`median'" != "" {
				local glm_varfunc "Median regression"
				local glm_link ""
			}
			else {
				quietly glm `outcome' `ovars' if `treat'==1 & `touse', ///
					link(`link') family(`family')
				local glm_varfunc = e(varfunct)
				local glm_link    = e(linkt)
			}
						if "`att'" != "" {
				quietly count if `treat'==1 & `touse'
				local N = r(N)
			}
			else if "`common'" != "" {
				tempvar pscore_tmp
				quietly logit `treat' `pvars' if `touse'
				quietly predict `pscore_tmp' if `touse'
				quietly mmws `treat' if `touse', pscore(`pscore_tmp') nstrata(`nstrata') `common' replace
				quietly count if _support==1 & `touse'
			local N = r(N)
			}
			bootstrap poms1=r(poms1) poms0=r(poms0) teffect=r(drmmws), ///
				reps(`reps') title(`title') seed(`seed') nodrop ///
				level(`level') `nodots' notable noheader: ///
				drmmws_bs `varlist' if `touse', ovars(`ovars') pvars(`pvars') ///
				nstrata(`nstrata') `att' `common' family(`family') ///
				link(`link') `median'
			// hold bootstrap e() immediately — before any ereturn post
			capture _estimates drop _drmmws_bs_hold
			_estimates hold _drmmws_bs_hold, copy
			// rename e(b) columns with value labels
			local vlname : value label `treat'
			if "`vlname'" != "" {
				local lbl1 : label `vlname' 1
				local lbl0 : label `vlname' 0
			}
			else {
				local lbl1 "1"
				local lbl0 "0"
			}
			local te_clab "(`lbl1' vs `lbl0')"
			// build 2-col display matrix
			matrix bs_b_full = e(b)
			matrix bs_V_full = e(V)
			matrix bs_b2 = (bs_b_full[1,3], bs_b_full[1,2])
			matrix bs_V2 = (bs_V_full[3,3], 0 \ 0, bs_V_full[2,2])
			mat coln bs_b2 = ATE:r1vs0.`treat' POmean:0b.`treat'
			mat coln bs_V2 = ATE:r1vs0.`treat' POmean:0b.`treat'
			mat rown bs_V2 = ATE:r1vs0.`treat' POmean:0b.`treat'
			local trt_model "logit"
			if "`median'" != "" local estimator "Quantile regression"
			else                  local estimator "GLM"
			di ""
			di as text "Doubly-robust MMWS estimation" _col(49) "Number of obs" _col(65) "=" _col(67) as result %9.0fc `N'
			di as text "Estimator      : " as result "`estimator'"
			di as text "Outcome model  : " as result "`glm_varfunc' `glm_link'"
			di as text "Treatment model: " as result "`trt_model'"
			di as text "Treatment var  : " as result "`treat'"
			di as text "Estimand       : " as result "`effect'"
			ereturn post bs_b2 bs_V2, obs(`N')
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Bootstrap"
			ereturn local title   "`title'"
			_drmmws_display, level(`level') `coeflegend'
			_estimates unhold _drmmws_bs_hold
			tempname _b _V
			matrix `_b' = e(b)
			matrix `_V' = e(V)
			mat coln `_b' = POmean:1.`treat' POmean:0b.`treat' ATE:r1vs0.`treat'
			mat coln `_V' = POmean:1.`treat' POmean:0b.`treat' ATE:r1vs0.`treat'
			mat rown `_V' = POmean:1.`treat' POmean:0b.`treat' ATE:r1vs0.`treat'
			local _N_reps = e(N_reps)
			local _level  = e(level)
			local _prefix "`e(prefix)'"
			local _cmd    "`e(cmd)'"
			local _cmd2   "`e(cmd2)'"
			tempname _bbs _Vbs _cin _cip _cibc
			capture matrix `_bbs'  = e(b_bs)
			capture matrix `_Vbs'  = e(V_bs)
			capture matrix `_cin'  = e(ci_normal)
			capture matrix `_cip'  = e(ci_percentile)
			capture matrix `_cibc' = e(ci_bc)
			ereturn post `_b' `_V', obs(`N')
			ereturn local cmd     "`_cmd'"
			ereturn local cmd2    "`_cmd2'"
			ereturn local prefix  "`_prefix'"
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Bootstrap"
			ereturn local title   "`title'"
			if `_N_reps' != . ereturn scalar N_reps = `_N_reps'
			if `_level'  != . ereturn scalar level  = `_level'
			capture ereturn matrix b_bs          = `_bbs'
			capture ereturn matrix V_bs          = `_Vbs'
			capture ereturn matrix ci_normal     = `_cin'
			capture ereturn matrix ci_percentile = `_cip'
			capture ereturn matrix ci_bc         = `_cibc'
		}
		else {
			// build bootstrap return-list
			local bs_returns ""
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				local bs_returns `bs_returns' pom`lv'=r(pom`lv')
			}
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				if `lv' != `control_level' {
					local bs_returns `bs_returns' te`lv'=r(te`lv')
				}
			}
			// fit one GLM to capture outcome model labels before bootstrap
			if "`median'" != "" {
				local glm_varfunc "Median regression"
				local glm_link ""
			}
			else {
				local ctrl_lv : word 1 of `tlevels'
				quietly glm `outcome' `ovars' if `treat'==`ctrl_lv' & `touse', ///
					link(`link') family(`family')
				local glm_varfunc = e(varfunct)
				local glm_link    = e(linkt)
			}
						if "`common'" != "" {
				quietly mlogit `treat' `pvars' if `touse', base(`control_level')
				local pscore_tmp_list ""
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					tempvar ps_tmp`lv'
					quietly predict `ps_tmp`lv'' if `touse', pr outcome(`lv')
					local pscore_tmp_list `pscore_tmp_list' `ps_tmp`lv''
				}
				quietly mmws `treat' if `touse', pscore(`pscore_tmp_list') nstrata(`nstrata_list') `common' nominal replace
				quietly count if _support==1 & `touse'
				local N = r(N)
			}
			bootstrap `bs_returns', ///
				reps(`reps') title(`title') seed(`seed') nodrop ///
				level(`level') `nodots' notable noheader: ///
				drmmws_bs `varlist' if `touse', ovars(`ovars') pvars(`pvars') ///
				nstrata(`nstrata') `common' family(`family') link(`link') ///
				`median' nominal control(`control_level')
			// hold bootstrap e() immediately — before any ereturn post
			capture _estimates drop _drmmws_bs_hold
			_estimates hold _drmmws_bs_hold, copy

			// rename bootstrap e(b) cols in-place (preserves all bootstrap e() results)
			// bootstrap stores: pom0..pomK te1..teK
			local q = char(34)
			local cnames2 ""
			if "`pomeans'" != "" {
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if `lv' == `control_level' {
						if `"`cnames2'"' == "" local cnames2 "POmeans:`lv'b.`treat'"
						else                     local cnames2 "`cnames2' POmeans:`lv'b.`treat'"
					}
					else {
						if `"`cnames2'"' == "" local cnames2 "POmeans:`lv'.`treat'"
						else                     local cnames2 "`cnames2' POmeans:`lv'.`treat'"
					}
				}
			}
			else {
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if `"`cnames2'"' == "" local cnames2 "POmeans:`lv'b.`treat'"
					else                     local cnames2 "`cnames2' POmeans:`lv'.`treat'"
				}
				foreach lv of local te_levels {
					local cnames2 "`cnames2' ATE:r`lv'vs`control_level'.`treat'"
				}
				local cnames2 "`cnames2' POmean:`control_level'b.`treat'"
			}
			// hold full bootstrap e(), repost with compact names for display, restore
			local q2 = char(34)
			local cnames2b ""
			if "`pomeans'" != "" {
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if `lv' == `control_level' {
						if `"`cnames2b'"' == "" local cnames2b "POmeans:`lv'b.`treat'"
						else                      local cnames2b "`cnames2b' POmeans:`lv'b.`treat'"
					}
					else {
						if `"`cnames2b'"' == "" local cnames2b "POmeans:`lv'.`treat'"
						else                      local cnames2b "`cnames2b' POmeans:`lv'.`treat'"
					}
				}
			}
			else {
				foreach lv of local te_levels {
					if `"`cnames2b'"' == "" local cnames2b "ATE:r`lv'vs`control_level'.`treat'"
					else                      local cnames2b "`cnames2b' ATE:r`lv'vs`control_level'.`treat'"
				}
				local cnames2b "`cnames2b' POmean:`control_level'b.`treat'"
			}
			matrix bs_b3 = e(b)
			matrix bs_V3 = e(V)
			if "`pomeans'" != "" {
				mat coln bs_b3 = `cnames2b'
				mat coln bs_V3 = `cnames2b'
				mat rown bs_V3 = `cnames2b'
			}
			else {
				// reorder: bootstrap stores pom0..pomK te1..teK, we want te..POmean
				local n_te : word count `te_levels'
				local ncols2 = `n_te' + 1
				local ctrl_pos2 = 1
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if `lv' == `control_level' local ctrl_pos2 = `k'
				}
				matrix bs_b3 = J(1, `ncols2', .)
				matrix bs_V3 = J(`ncols2', `ncols2', 0)
				local col2 = 1
				local te_col2 = `K' + 1
				foreach lv of local te_levels {
					matrix bs_b3[1,`col2'] = e(b)[1,`te_col2']
					matrix bs_V3[`col2',`col2'] = e(V)[`te_col2',`te_col2']
					local col2    = `col2' + 1
					local te_col2 = `te_col2' + 1
				}
				matrix bs_b3[1,`col2'] = e(b)[1,`ctrl_pos2']
				matrix bs_V3[`col2',`col2'] = e(V)[`ctrl_pos2',`ctrl_pos2']
				mat coln bs_b3 = `cnames2b'
				mat coln bs_V3 = `cnames2b'
				mat rown bs_V3 = `cnames2b'
			}
			local trt_model "(multinomial) logit"
			if "`median'" != "" local estimator "Quantile regression"
			else                  local estimator "GLM"
			di ""
			di as text "Doubly-robust MMWS estimation" _col(49) "Number of obs" _col(65) "=" _col(67) as result %9.0fc `N'
			di as text "Estimator      : " as result "`estimator'"
			di as text "Outcome model  : " as result "`glm_varfunc' `glm_link'"
			di as text "Treatment model: " as result "`trt_model'"
			di as text "Treatment var  : " as result "`treat'"
			di as text "Estimand       : " as result "`effect'"
			ereturn post bs_b3 bs_V3, obs(`N')
			ereturn local cmd     "drmmws"
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Bootstrap"
			ereturn local title   "`title'"
			_drmmws_display, level(`level') `coeflegend'
			_estimates unhold _drmmws_bs_hold
			// rename e(b) and bootstrap matrices in bootstrap order: pom0..pomK te1..teK
			local q2 = char(34)
			local cnames_bsord  ""
			local dispnames_bsord ""
			if "`pomeans'" != "" {
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if "`vlname'" != "" local dlbl : label `vlname' `lv'
					else                  local dlbl "`lv'"
					if `lv' == `control_level' {
						if `"`cnames_bsord'"' == "" local cnames_bsord   "POmeans:`lv'b.`treat'"
						else                           local cnames_bsord   "`cnames_bsord' POmeans:`lv'b.`treat'"
					}
					else {
						if `"`cnames_bsord'"' == "" local cnames_bsord   "POmeans:`lv'.`treat'"
						else                           local cnames_bsord   "`cnames_bsord' POmeans:`lv'.`treat'"
					}
					if `"`dispnames_bsord'"' == "" local dispnames_bsord `"`q2'POmeans:`dlbl'`q2'"'
					else                              local dispnames_bsord `"`dispnames_bsord' `q2'POmeans:`dlbl'`q2'"'
				}
			}
			else {
				// order: pom0..pomK then te1..teK
				forvalues k = 1/`K' {
					local lv : word `k' of `tlevels'
					if "`vlname'" != "" local dlbl : label `vlname' `lv'
					else                  local dlbl "`lv'"
					if `lv' == `control_level' {
						local cnames_bsord   "`cnames_bsord' POmean:`lv'b.`treat'"
						local dispnames_bsord `"`dispnames_bsord' `q2'POmean:`dlbl'`q2'"'
					}
					else {
						local cnames_bsord   "`cnames_bsord' POmeans:`lv'.`treat'"
						local dispnames_bsord `"`dispnames_bsord' `q2'POmeans:`dlbl'`q2'"'
					}
				}
				foreach lv of local te_levels {
					local clab "(`lbl`lv'' vs `ctrl_lbl')"
					local cnames_bsord   "`cnames_bsord' ATE:r`lv'vs`control_level'.`treat'"
					local dispnames_bsord `"`dispnames_bsord' `q2'ATE:`clab'`q2'"'
				}
			}
			tempname _b _V
			matrix `_b' = e(b)
			matrix `_V' = e(V)
			mat coln `_b' = `cnames_bsord'
			mat coln `_V' = `cnames_bsord'
			mat rown `_V' = `cnames_bsord'
			local _N_reps = e(N_reps)
			local _level  = e(level)
			local _prefix "`e(prefix)'"
			local _cmd    "`e(cmd)'"
			local _cmd2   "`e(cmd2)'"
			tempname _bbs _Vbs _cin _cip _cibc
			capture matrix `_bbs'  = e(b_bs)
			capture matrix `_Vbs'  = e(V_bs)
			capture matrix `_cin'  = e(ci_normal)
			capture matrix `_cip'  = e(ci_percentile)
			capture matrix `_cibc' = e(ci_bc)
			ereturn post `_b' `_V', obs(`N')
			ereturn local cmd     "`_cmd'"
			ereturn local cmd2    "`_cmd2'"
			ereturn local prefix  "`_prefix'"
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Bootstrap"
			ereturn local title   "`title'"
			if `_N_reps' != . ereturn scalar N_reps = `_N_reps'
			if `_level'  != . ereturn scalar level  = `_level'
			capture ereturn matrix b_bs          = `_bbs'
			capture ereturn matrix V_bs          = `_Vbs'
			capture ereturn matrix ci_normal     = `_cin'
			capture ereturn matrix ci_percentile = `_cip'
			capture ereturn matrix ci_bc         = `_cibc'
		}
		exit
	}

	********************
	*** DELTA-METHOD ***
	********************

	// binary treatment
	if `K' == 2 {

		quietly {

			tabulate `treat' if `touse'
			if r(r) != 2 {
				di as err "With a binary treatment, `treat' must have exactly two values (coded 0 or 1)."
				exit 420
			}
			capture assert inlist(`treat', 0, 1) if `touse'
			if _rc {
				di as err "With a binary treatment, `treat' must be coded as either 0 or 1."
				exit 450
			}

			tempvar pscore
			logit `treat' `pvars' if `touse'
			predict `pscore' if `touse'
			mmws `treat' if `touse', pscore(`pscore') nstrata(`nstrata') `att' `common' replace
			if "`att'" != "" {
				count if `treat'==1 & `touse'
				local N = r(N)
			}
			else if "`common'" != "" {
				count if _support==1 & `touse'
				local N = r(N)
			}

			tempvar pom1 pom0 pomdiff

			if "`median'" != "" {
				qreg `outcome' `ovars' [pw=_mmws] if `treat'==1 & `touse'
				if "`common'" != "" predict `pom1' if _support==1 & `touse'
				else                predict `pom1' if `touse'
				sum `pom1', meanonly
				local b_poms1  = r(mean)
				local se_poms1 = .

				qreg `outcome' `ovars' [pw=_mmws] if `treat'==0 & `touse'
				if "`common'" != "" predict `pom0' if _support==1 & `touse'
				else                predict `pom0' if `touse'
				sum `pom0', meanonly
				local b_poms0  = r(mean)
				local se_poms0 = .

				gen `pomdiff' = `pom1' - `pom0'
				if "`att'" != "" sum `pomdiff' if `treat'==1, meanonly
				else             sum `pomdiff', meanonly
				local b_teffect  = r(mean)
				local se_teffect = .
			}
			else {
				if "`common'" != "" {
					glm `outcome' `ovars' [pw=_mmws] if `treat'==1 & _support==1 & `touse', ///
						link(`link') family(`family')
					predict `pom1' if _support==1 & `touse'
				}
				else {
					glm `outcome' `ovars' [pw=_mmws] if `treat'==1 & `touse', ///
						link(`link') family(`family')
					predict `pom1' if `touse'
				}
				local glm_varfunc = e(varfunct)
				local glm_link    = e(linkt)
				sum `pom1', meanonly
				local b_poms1  = r(mean)
				margins, post
				local se_poms1 = _se[_cons]

				if "`common'" != "" {
					glm `outcome' `ovars' [pw=_mmws] if `treat'==0 & _support==1 & `touse', ///
						link(`link') family(`family')
					predict `pom0' if _support==1 & `touse'
				}
				else {
					glm `outcome' `ovars' [pw=_mmws] if `treat'==0 & `touse', ///
						link(`link') family(`family')
					predict `pom0' if `touse'
				}
				sum `pom0', meanonly
				local b_poms0  = r(mean)
				margins, post
				local se_poms0 = _se[_cons]

				local b_teffect  = `b_poms1' - `b_poms0'
				local se_teffect = sqrt(`se_poms1'^2 + `se_poms0'^2)
			}

		} // end quietly (binary)

		// resolve value labels for binary treatment levels
		local vlname : value label `treat'
		if "`vlname'" != "" {
			local lbl1 : label `vlname' 1
			local lbl0 : label `vlname' 0
		}
		else {
			local lbl1 "1"
			local lbl0 "0"
		}
		local te_clab "(`lbl1' vs `lbl0')"

		matrix b = (`b_teffect', `b_poms0')
		mat coln b = ATE:r1vs0.`treat' POmean:0b.`treat'

		if "`median'" == "" {
			matrix V = (`se_teffect'^2, 0 \ ///
			             0, `se_poms0'^2)
			mat coln V = ATE:r1vs0.`treat' POmean:0b.`treat'
			mat rown V = ATE:r1vs0.`treat' POmean:0b.`treat'

			ereturn post b V, obs(`N')
			ereturn local cmd     "drmmws"
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Robust"
			ereturn local title   "`title'"

			local trt_model "logit"
			if "`median'" != "" local estimator "Quantile regression"
			else                local estimator "GLM"
			di ""
			di as text "Doubly-robust MMWS estimation" _col(49) "Number of obs" _col(65) "=" _col(67) as result %9.0fc `N'
			di as text "Estimator      : " as result "`estimator'"
			di as text "Outcome model  : " as result "`glm_varfunc' `glm_link'"
			di as text "Treatment model: " as result "`trt_model'"
			di as text "Treatment var  : " as result "`treat'"
			di as text "Estimand       : " as result "`effect'"
			_drmmws_display, level(`level') `coeflegend'
		}
		else {
			matrix V = J(2,2,0)
			mat coln V = ATE:r1vs0.`treat' POmean:0b.`treat'
			mat rown V = ATE:r1vs0.`treat' POmean:0b.`treat'

			ereturn post b V, obs(`N')
			ereturn local cmd     "drmmws"
			ereturn local depvar  "`outcome'"
			ereturn local vcetype "Coefficient"
			ereturn local title   "`title'"

			local trt_model "logit"
			if "`median'" != "" local estimator "Quantile regression"
			else                local estimator "GLM"
			di ""
			di as text "Doubly-robust MMWS estimation" _col(49) "Number of obs" _col(65) "=" _col(67) as result %9.0fc `N'
			di as text "Estimator      : " as result "`estimator'"
			di as text "Outcome model  : " as result "Median regression"
			di as text "Treatment model: " as result "`trt_model'"
			di as text "Treatment var  : " as result "`treat'"
			di as text "Estimand       : " as result "`effect'"
			_drmmws_display, level(`level') `coeflegend'
			di as text "Note: SEs not available for median estimates without bootstrap."
		}

	} // end binary

	// multivalued treatments
	else {

		quietly {

			mlogit `treat' `pvars' if `touse', base(`control_level')

			local pscore_list ""
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				tempvar ps`lv'
				predict `ps`lv'' if `touse', pr outcome(`lv')
				local pscore_list `pscore_list' `ps`lv''
			}

			// build nstrata list: if user supplied K values use them,
			// otherwise replicate the single value K times
			local n_nstrata : word count `nstrata'
			if `n_nstrata' == 1 {
				local nstrata_list ""
				forvalues k = 1/`K' {
					local nstrata_list `nstrata_list' `nstrata'
				}
			}
			else if `n_nstrata' == `K' {
				local nstrata_list `nstrata'
			}
			else {
				di as err "nstrata() must contain either one value or one value per treatment level (`K' values)"
				exit 198
			}
			mmws `treat' if `touse', pscore(`pscore_list') nstrata(`nstrata_list') ///
				`common' nominal replace
			if "`common'" != "" {
				count if _support==1 & `touse'
				local N = r(N)
			}

			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				tempvar pom_`lv'

				if "`median'" != "" {
					qreg `outcome' `ovars' [pw=_mmws] if `treat'==`lv' & `touse'
					if "`common'" != "" predict `pom_`lv'' if _support==1 & `touse'
					else                predict `pom_`lv'' if `touse'
					sum `pom_`lv'', meanonly
					local b_pom`lv'  = r(mean)
					local se_pom`lv' = .
				}
				else {
					if "`common'" != "" {
						glm `outcome' `ovars' [pw=_mmws] ///
							if `treat'==`lv' & _support==1 & `touse', ///
							link(`link') family(`family')
						predict `pom_`lv'' if _support==1 & `touse'
					}
					else {
						glm `outcome' `ovars' [pw=_mmws] if `treat'==`lv' & `touse', ///
							link(`link') family(`family')
						predict `pom_`lv'' if `touse'
					}
					local glm_varfunc = e(varfunct)
					local glm_link    = e(linkt)
					sum `pom_`lv'', meanonly
					local b_pom`lv'  = r(mean)
					margins, post
					local se_pom`lv' = _se[_cons]
				}
			}

			// treatment effects vs control
			foreach lv of local te_levels {
				local b_te`lv'  = `b_pom`lv'' - `b_pom`control_level''
				local se_te`lv' = sqrt(`se_pom`lv''^2 + `se_pom`control_level''^2)
			}

		} // end quietly (multivalued)

		// build matrices
		local n_te : word count `te_levels'

		if "`pomeans'" != "" {
			local ncols = `K'
			matrix b = J(1, `ncols', .)
			matrix V = J(`ncols', `ncols', 0)
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				matrix b[1,`k'] = `b_pom`lv''
				if "`median'" == "" matrix V[`k',`k'] = `se_pom`lv''^2
			}
			local q = char(34)
			local cnames ""
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				if `lv' == `control_level' {
					if `"`cnames'"' == "" local cnames "POmeans:`lv'b.`treat'"
					else                    local cnames "`cnames' POmeans:`lv'b.`treat'"
				}
				else {
					if `"`cnames'"' == "" local cnames "POmeans:`lv'.`treat'"
					else                    local cnames "`cnames' POmeans:`lv'.`treat'"
				}
			}
			matrix colnames b = `cnames'
			matrix colnames V = `cnames'
			matrix rownames V = `cnames'
		}
		else {
			local ncols = `n_te' + 1
			matrix b = J(1, `ncols', .)
			matrix V = J(`ncols', `ncols', 0)
			local col = 1
			foreach lv of local te_levels {
				matrix b[1,`col'] = `b_te`lv''
				if "`median'" == "" matrix V[`col',`col'] = `se_te`lv''^2
				local col = `col' + 1
			}
			matrix b[1,`col'] = `b_pom`control_level''
			if "`median'" == "" matrix V[`col',`col'] = `se_pom`control_level''^2
			local q = char(34)
			local cnames ""
			foreach lv of local te_levels {
				local clab "(`lbl`lv'' vs `ctrl_lbl')"
				if `"`cnames'"' == "" local cnames "ATE:r`lv'vs`control_level'.`treat'"
				else                    local cnames "`cnames' ATE:r`lv'vs`control_level'.`treat'"
			}
			local cnames "`cnames' POmean:`control_level'b.`treat'"
			matrix colnames b = `cnames'
			matrix colnames V = `cnames'
			matrix rownames V = `cnames'
		}

		ereturn post b V, obs(`N')
		ereturn local cmd     "drmmws"
		ereturn local depvar  "`outcome'"
		ereturn local title   "`title'"
		ereturn local vcetype "Robust"

		if "`median'" != "" local glm_varfunc "Median regression"
		local trt_model "(multinomial) logit"
		if "`median'" != "" local estimator "Quantile regression"
			else                local estimator "GLM"
		di ""
		di as text "Doubly-robust MMWS estimation" _col(49) "Number of obs" _col(65) "=" _col(67) as result %9.0fc `N'
		di as text "Estimator      : " as result "`estimator'"
		if "`median'" == "" di as text "Outcome model  : " as result "`glm_varfunc' `glm_link'"
		else                di as text "Outcome model  : " as result "`glm_varfunc'"
		di as text "Treatment model: " as result "`trt_model'"
		di as text "Treatment var  : " as result "`treat'"
		di as text "Estimand       : " as result "`effect'"

		if "`median'" != "" {
			ereturn local vcetype "Coefficient"
		}
		_drmmws_display, level(`level') `coeflegend'
		if "`median'" != "" {
			di as text "Note: SEs not available for median estimates without bootstrap."
		}

	} // end multivalued

end

*===============================================================
* _drmmws_display: custom display replacing ereturn display
* Parses r#vs#.varname and #.varname colnames, substitutes
* value labels for display while keeping compact _b[] names
*===============================================================
program _drmmws_display, eclass
    syntax [, LEVel(cilevel) COEFLegend]

    local b_names : colfullnames e(b)
    local ncols   : word count `b_names'

    // header line widths matching standard Stata output
    local w1 = 24   // left column width
    local sep = "-"

    // build display rows: parse each colname
    // formats: ATE:r#vs#.var, POmean:#.var, POmeans:#.var
    local rows ""
    forvalues c = 1/`ncols' {
        local cn  : word `c' of `b_names'
        // split equation and colname
        local eq  = substr("`cn'", 1, strpos("`cn'", ":") - 1)
        local col = substr("`cn'", strpos("`cn'", ":") + 1, .)

        // parse varname (after last ".")
        local dotpos = strrpos("`col'", ".")
        local var    = substr("`col'", `dotpos' + 1, .)
        local vlname : value label `var'

        if "`eq'" == "ATE" {
            // format: r#vs#.var  -> parse treated and control levels
            local tmp    = subinstr("`col'", "r", "", 1)    // #vs#.var
            local vspos  = strpos("`tmp'", "vs")
            local tlev   = substr("`tmp'", 1, `vspos' - 1)
            local rest   = substr("`tmp'", `vspos' + 2, .)
            local clev   = substr("`rest'", 1, strpos("`rest'", ".") - 1)
            // get value labels if available
            if "`vlname'" != "" {
                local tlbl : label `vlname' `tlev'
                local clbl : label `vlname' `clev'
            }
            else {
                local tlbl "`tlev'"
                local clbl "`clev'"
            }
            local disp_lbl "(`tlbl' vs `clbl')"
        }
        else if "`eq'" == "POmean" | "`eq'" == "POmeans" {
            // format: #.var or #b.var (b = base/omitted)
            local lev = substr("`col'", 1, `dotpos' - 1)
            local lev = subinstr("`lev'", "b", "", 1)  // strip b suffix
            if "`vlname'" != "" {
                local disp_lbl : label `vlname' `lev'
            }
            else {
                local disp_lbl "`lev'"
            }
        }
        else {
            local disp_lbl "`col'"
        }
        local row`c'_eq   "`eq'"
        local row`c'_lbl  "`disp_lbl'"
        local row`c'_cn   "`cn'"
    }

    // now print the table using _coef_table style
    // we'll use ereturn display but first temporarily rename cols
    // to the display labels, display, then rename back

    // build display colnames
    local q = char(34)
    local dispnames ""
    forvalues c = 1/`ncols' {
        local eq  "`row`c'_eq'"
        local lbl "`row`c'_lbl'"
        if `"`dispnames'"' == "" local dispnames `"`q'`eq':`lbl'`q'"'
        else                     local dispnames `"`dispnames' `q'`eq':`lbl'`q'"'
    }

    // temporarily rename e(b) cols to display labels
    tempname b_orig V_orig b_disp V_disp
    matrix `b_orig' = e(b)    // save compact-named original
    matrix `V_orig' = e(V)

    if "`coeflegend'" != "" {
        // show compact _b[] names directly — no reposting needed
        ereturn display, level(`level') coeflegend
    }
    else {
        // copy to display matrices and rename
        matrix `b_disp' = `b_orig'
        matrix `V_disp' = `V_orig'
        matrix colnames `b_disp' = `dispnames'
        matrix colnames `V_disp' = `dispnames'
        matrix rownames `V_disp' = `dispnames'

        // repost display version, show table, restore original
        ereturn repost b = `b_disp'
        ereturn display, level(`level')

        // restore compact colnames
        ereturn repost b = `b_orig'
    }
end
