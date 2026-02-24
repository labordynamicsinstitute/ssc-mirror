

version 16

capture program drop gweakivtest
program define gweakivtest, rclass

	version 16

	syntax [, CRITerion(name) target(name) retain(name) alpha(numlist max=1 >=0.001 <=0.999) tau(numlist max=1 >=0.001 <=0.999) points(numlist integer max=1 >=1 <=100000) procs(numlist integer max=1 >=1 <=100) verbosity(numlist integer max=1 >=0 <=3) noplugin]
	
	tempname tol
	scalar `tol' = 1e-7
	
	if ("`criterion'" == "") {
		local criterion "abs"
	}
	else {
		if !inlist("`criterion'", "rel", "abs") {
			di as error `"criterion `criterion' not allowed; must be either rel or abs."'
			error 198
		}
	}
	local rel = ("`criterion'" == "rel")
	if ("`target'" == "") local target "beta"
	if ("`retain'" == "") local retain "beta"
	if ("`alpha'" == "") local alpha = 0.05
	if ("`tau'" == "") local tau = 0.1
	if ("`points'" == "") local points = 1000
	if ("`procs'" == "") local procs = -1
	if ("`verbosity'" == "") local verbosity = 0
	local useplugin = ("`plugin'" == "")

	* Error if criterion is relative and retained regressor specified
	if ("`retain'" != "beta" & "`criterion'" == "rel") {
		di as error `"If retained regressor specified, criterion must be abs."'
		error 198
	}

	* Error if target coefficient different to retained regressor
	if ("`retain'" != "beta" & "`target'" != "beta" & "`retain'" != "`target'") {
		di as error `"Target coefficient specified but different to retained regressor (`target' vs `retain')."'
		error 198
	}

	* Error if "avar" command is not installed
	capture which avar
	if (_rc == 111) {
		di as error `"User contributed command avar is needed to run gweakivtest. Install by typing "ssc install avar"."'
		exit
	}

	* Error if ivreg2 or ivregress not just run
	if !inlist(`"`e(cmd)'"', "ivreg2", "ivregress") {
		di as error `"gweakivtest is a postestimation command after running ivreg2 or ivregress."'
		exit
	}
	
	* Error if estimator is not 2SLS
	if (("`e(estimator)'" != "2sls") & ("`e(model)'" != "iv")) {
		di as error `"gweakivtest is only compatible with 2SLS estimator."'
	}
		
	* Display info
	if (`verbosity' >= 1) {
		di as text _n "Progress:"
		di as text "> Collecting information about 2SLS regression"
	}
	
	* Identify observations in sample
	* With pweight and aweight, e(N) is number of observations (i.e. weights are assumed to have been rescaled)
	* With fweight and iweight, e(N) is sum of weights (i.e. weights assumed not to be rescaled)
	local T = e(N)
	tempvar insample
	gen byte `insample' = e(sample)
	
	* Identify if small-sample correction was requested in 2SLS command
	* If so, we will implement corresponding small-sample correction
	local small = ("`e(small)'" == "small")

	* Error if regression didn't include a constant or equivalent
	tempname ivestimates
	local has_cons = ("`e(constant)'" != "noconstant") & ("`e(cons)'" != "0")
	if (!`has_cons') {
		* Check whether a constant would be colinear with structural regressors
		tempvar cons
		gen byte `cons' = 1
		local structural_regressors : colnames e(b)
		_estimates hold `ivestimates'
		regress `cons' `structural_regressors' if `insample', noconstant noheader notable
		drop `cons'
		macro drop _cons
		if (e(rmse) > `tol') {
			di as error `"IV regression without a constant is not supported by gweakivtest."'
			exit
		}
		_estimates unhold `ivestimates'
	}
	if (!`has_cons') local no_cons "noconstant"


	if (`"`e(cmd)'"' == "ivreg2") {
		
		* Number of exogenous regressors
		local Xvarsraw "`e(inexog1)'"
		local Nx = e(inexog_ct) + `has_cons'

		* Number of endogenous variables
		local Yvarsraw "`e(instd1)'"
		local N = e(endog_ct)
		local Nact = `N'
		if ("`retain'" != "beta") {
			if (`N' == 1) {
				* If LRR1 but only single endogenous variable, switch to LTZ
				di as text _n "WARNING: Sanderson-Windmeijer test requested but only single endogenous variable; switching to Stock-Yogo setting"
				local retain "beta"
			}
			else {
				local Nact = 1
			}
		}

		* Number of instruments
		local Zvarsraw "`e(exexog1)'"
		local K = e(exexog_ct)
		local Kstar = `K'
		if ("`retain'" != "beta") local Kstar = `K' - `N' + 1
		
		
		* Dependent variables
		local yvarraw "`e(depvar1)'"
		
		* Variance type to be used in avar command
		local 0 `"`e(cmdline)'"'
		syntax anything(everything) [pweight aweight fweight iweight] [, Robust CLuster(passthru) kiefer dkraay(passthru) BW(passthru) kernel(passthru) center *]
		local avarvcetype `"`robust' `cluster' `kiefer' `dkraay' `bw' `kernel' `center'"'
		local clustdfadj = 1
		if (`"`cluster'"' != "") local clustdfadj = (`e(N)' / (`e(N)' - 1)) * (`e(N_clust)'-1) / (`e(N_clust)')

		local nw = (("`robust'" == "robust") & regexm("`kernel'","(Bartlett|bar)"))

		* Cragg-Donald statistic
		tempname cragg_donald_statistic
		scalar `cragg_donald_statistic' = e(cdf)
		
		local temp mymat

		* Stock-Yogo critical values
		tempname stock_yogo_tables_crit_val sy_table
		scalar `stock_yogo_tables_crit_val' = .
		if (abs(`alpha' - 0.05) < 1e-5 & `Nact' <= 3 & `Kstar' <= 100) {
			local ix_table = 0
			if (abs(`tau' - 0.05) < 1e-5) local ix_table = 1
			else if (abs(`tau' - 0.1) < 1e-5) local ix_table = 2
			else if (abs(`tau' - 0.2) < 1e-5) local ix_table = 3
			else if (abs(`tau' - 0.3) < 1e-5) local ix_table = 4
			if (`ix_table' > 0) {
				mata: s_cdsy("`sy_table'", `ix_table')
				scalar `stock_yogo_tables_crit_val' = `sy_table'[`Kstar',`Nact']
			}
		}

	}
	else if (`"`e(cmd)'"' == "ivregress") {
		
		* Number of exogenous regressors (adjusted for unused variables)
		local exogr = "`e(exogr)'"
		while ("`exogr'" != "") {
			gettoken thisvar exogr : exogr
			local thisvar = regexr("`thisvar'", "\b\w*[ob]\.\w*\b", "")
			local Xvarsraw "`Xvarsraw' `thisvar'"
		}
		local Nx = `: list sizeof Xvarsraw' + `has_cons'

		* Number of endogenous variables (adjusted for unused variables)
		local endog = "`e(endog)'"
		if ("`endog'" == "") local endog "`e(instd)'"
		while ("`endog'" != "") {
			gettoken thisvar endog : endog
			local thisvar = regexr("`thisvar'", "\b\w*[ob]\.\w*\b", "")
			local Yvarsraw "`Yvarsraw' `thisvar'"
		}
		local N : list sizeof Yvarsraw
		local Nact = `N'
		if ("`retain'" != "beta") {
			if (`N' == 1) {
				* If LRR1 but only single endogenous variable, switch to LTZ
				di as text _n "WARNING: Sanderson-Windmeijer test requested but only single endogenous variable; switching to Stock-Yogo setting"
				local retain "beta"
			}
			else {
				local Nact = 1
			}
		}

		* Number of instruments (adjusted for unused variables)
		local exog = "`e(exog)'"
		if ("`exog'" == "") local exog "`e(insts)'"
		while ("`exog'" != "") {
			gettoken thisvar exog : exog
			local thisvar = regexr("`thisvar'", "\b\w*[ob]\.\w*\b", "")
			local Zvarsraw "`Zvarsraw' `thisvar'"
		}
		local Zvarsraw : list Zvarsraw - Xvarsraw
		local K : list sizeof Zvarsraw
		local Kstar = `K'
		if ("`retain'" != "beta") local Kstar = `K' - `N' + 1

		* Dependent variable
		local yvarraw "`e(depvar)'"
		
		* Variance type to be used in avar command
		local clustdfadj = 1
		local nw = 0
		local vcetype "`e(vce)'"
		gettoken vcetype vceoptions : vcetype
		if ("`vcetype'" == "unadjusted") local avarvcetype ""
		else if ("`vcetype'" == "robust") local avarvcetype "robust"
		else if ("`vcetype'" == "cluster") {
			local avarvcetype "cluster(`e(clustvar)')"
			local clustdfadj = (`e(N)' / (`e(N)' - 1)) * (`e(N_clust)'-1) / (`e(N_clust)')
		}
		else if ("`vcetype'" == "hac") {
			gettoken kernel kerneloptions : vceoptions
			if ("`kernel'" == "bartlett") {
				local kernel "bar"
				local nw = 1
			}
			else if ("`kernel'" == "parzen") local kernel "par"
			else if ("`kernel'" == "quadraticspectral") local kernel "qs"
			else {
				di as error "HAC covariance kernel `kernel' not supported by gweakivtest."
				exit
			}
			local avarvcetype "robust bw(`=`e(hac_lag)'+1') kernel(`kernel')"
		}
		else {
			di as error "Covariance matrix type `vcetype' not supported by gweakivtest."
			exit
		}
		
		* Cragg-Donald statistic
		qui estat firststage, forcenonrobust
		tempname cragg_donald_statistic
		scalar `cragg_donald_statistic' = .
		* For some reason r(mineig) is missing with aweight supplied so use different source
		if (inlist("`e(wtype)'", "aweight", "pweight")) {
			* Only works if single endogenous variable
			if (`N' == 1) {
				scalar `cragg_donald_statistic' = r(singleresults)[1,4]
			}
		}
		else {
			scalar `cragg_donald_statistic' = r(mineig)
		}
		
		* Stock-Yogo critical values
		* Borrowed from ivregress_estat.ado - needed to recalculate
		* critical values in Sanderson-Windmeijer case
		
		/* Rows represent number of instrumental variables
		   cols are CV's for worst-case relative biases of
		   0.05, 0.10, 0.20, and 0.30 for n=1 endogenous
		   regressors (cols 1-4), n=2 endogenous regress-
		   ors (cols 5-8), and n=3 endogenous regressors
		   (cols 9-12).
		*/
		tempname tslsbias
		#delimit ;
		matrix `tslsbias' = (
			.,     .,    .,    .,     .,     .,    .,    .,     .,     .,    .,    . \
			.,     .,    .,    .,     .,     .,    .,    .,     .,     .,    .,    . \
		13.91,  9.08, 6.46, 5.39,     .,     .,    .,    .,     .,     .,    .,    . \
		16.85, 10.27, 6.71, 5.34, 11.04,  7.56, 5.57, 4.73,     .,     .,    .,    . \
		18.37, 10.83, 6.77, 5.25, 13.97,  8.78, 5.91, 4.79,  9.53,  6.61, 4.99, 4.30 \
		19.28, 11.12, 6.76, 5.15, 15.72,  9.48, 6.08, 4.78, 12.20,  7.77, 5.35, 4.40 \
		19.86, 11.29, 6.73, 5.07, 16.88,  9.92, 6.16, 4.76, 13.95,  8.50, 5.56, 4.44 \
		20.25, 11.39, 6.69, 4.99, 17.70, 10.22, 6.20, 4.73, 15.18,  9.01, 5.69, 4.46 \
		20.53, 11.46, 6.65, 4.92, 18.30, 10.43, 6.22, 4.69, 16.10,  9.37, 5.78, 4.46 \
		20.74, 11.49, 6.61, 4.86, 18.76, 10.58, 6.23, 4.66, 16.80,  9.64, 5.83, 4.45 \
		20.90, 11.51, 6.56, 4.80, 19.12, 10.69, 6.23, 4.62, 17.35,  9.85, 5.87, 4.44 \
		21.01, 11.52, 6.53, 4.75, 19.40, 10.78, 6.22, 4.59, 17.80, 10.01, 5.90, 4.42 \
		21.10, 11.52, 6.49, 4.71, 19.64, 10.84, 6.21, 4.56, 18.17, 10.14, 5.92, 4.41 \
		21.18, 11.52, 6.45, 4.67, 19.83, 10.89, 6.20, 4.53, 18.47, 10.25, 5.93, 4.39 \
		21.23, 11.51, 6.42, 4.63, 19.98, 10.93, 6.19, 4.50, 18.73, 10.33, 5.94, 4.37 \
		21.28, 11.50, 6.39, 4.59, 20.12, 10.96, 6.17, 4.48, 18.94, 10.41, 5.94, 4.36 \
		21.31, 11.49, 6.36, 4.56, 20.23, 10.99, 6.16, 4.45, 19.13, 10.47, 5.94, 4.34 \
		21.34, 11.48, 6.33, 4.53, 20.33, 11.00, 6.14, 4.43, 19.29, 10.52, 5.94, 4.32 \
		21.36, 11.46, 6.31, 4.51, 20.41, 11.02, 6.13, 4.41, 19.44, 10.56, 5.94, 4.31 \
		21.38, 11.45, 6.28, 4.48, 20.48, 11.03, 6.11, 4.39, 19.56, 10.60, 5.93, 4.29 \
		21.39, 11.44, 6.26, 4.46, 20.54, 11.04, 6.10, 4.37, 19.67, 10.63, 5.93, 4.28 \
		21.40, 11.42, 6.24, 4.43, 20.60, 11.05, 6.08, 4.35, 19.77, 10.65, 5.92, 4.27 \
		21.41, 11.41, 6.22, 4.41, 20.65, 11.05, 6.07, 4.33, 19.86, 10.68, 5.92, 4.25 \
		21.41, 11.40, 6.20, 4.39, 20.69, 11.05, 6.06, 4.32, 19.94, 10.70, 5.91, 4.24 \
		21.42, 11.38, 6.18, 4.37, 20.73, 11.06, 6.05, 4.30, 20.01, 10.71, 5.90, 4.23 \
		21.42, 11.37, 6.16, 4.35, 20.76, 11.06, 6.03, 4.29, 20.07, 10.73, 5.90, 4.21 \
		21.42, 11.36, 6.14, 4.34, 20.79, 11.06, 6.02, 4.27, 20.13, 10.74, 5.89, 4.20 \
		21.42, 11.34, 6.13, 4.32, 20.82, 11.05, 6.01, 4.26, 20.18, 10.75, 5.88, 4.19 \
		21.42, 11.33, 6.11, 4.31, 20.84, 11.05, 6.00, 4.24, 20.23, 10.76, 5.88, 4.18 \
		21.42, 11.32, 6.09, 4.29, 20.86, 11.05, 5.99, 4.23, 20.27, 10.77, 5.87, 4.17  );

		#delimit cr
		
		tempname stock_yogo_tables_crit_val
		scalar `stock_yogo_tables_crit_val' = .
		local col = 0
		if (abs(`tau' - 0.05) < 1e-5) local col = 1
		else if (abs(`tau' - 0.1) < 1e-5) local col = 2
		else if (abs(`tau' - 0.2) < 1e-5) local col = 3
		else if (abs(`tau' - 0.3) < 1e-5) local col = 4
		if (`col' > 0) local col = `col' + (4 * (`Nact' - 1))
		if (abs(`alpha' - 0.05) < 1e-5 & `Nact' <= 3 & `Kstar' <= 30 & `col' > 0) {
			scalar `stock_yogo_tables_crit_val' = `tslsbias'[`Kstar', `col']
		}

	}
	
	* Get weighting information
	local has_weights = ("`e(wtype)'" != "")
	if (`has_weights') {
		local addweight "[`e(wtype)'`e(wexp)']"
		tempvar wgt
		qui gen double `wgt' `e(wexp)'
	}

	
	* Convert target to integer
	if (("`target'" != "beta") & (!`: list target in Yvarsraw')) {
		local Yvarsraw = strtrim("`Yvarsraw'")
		di as error `"target `target' not allowed; must be either beta or the name of one of the endogenous variables (`Yvarsraw')."'
		error 198
	}
	if ("`target'" == "beta") {
		local target_num = 0
	}
	else {
		local target_num : list posof "`target'" in Yvarsraw
	}
	
	* Convert retain to integer
	if (("`retain'" != "beta") & (!`: list retain in Yvarsraw')) {
		local Yvarsraw = strtrim("`Yvarsraw'")
		di as error `"retain `retain' not allowed; must be either beta or the name of one of the endogenous variables (`Yvarsraw')."'
		error 198
	}
	if ("`retain'" == "beta") {
		local retain_num = 0
	}
	else {
		local retain_num : list posof "`retain'" in Yvarsraw
	}
	
	* Warn if big problem
	if ((!`useplugin') & ("`retain'" == "beta")) {
		estimate_memory, n(`N') k(`K')
		local tot_size_rounded = round(r(tot_size_gb))
		if (!`useplugin' & `tot_size_rounded' >= 1) {
			di as text _n "Warning: required memory exceeds `tot_size_rounded'GB; execution may be slow" _n
		}
	}

	* Calculate test statistic and critical values
	tempname gmin_generalized gmin_sy syn_cv lmn_cv lms_cv
	tempname lmn_converged lms_converged
	tempname W Sig Sigv
	mata: _gweakivtest(`alpha', `tau', `rel', `target_num', `retain_num', `small', `points', `procs', `verbosity', `useplugin', "`gmin_generalized'", "`gmin_sy'", "`syn_cv'", "`lmn_cv'", "`lms_cv'", "`lmn_converged'", "`lms_converged'")
	
	* Deal with -999 values from plugin
	if (`useplugin' & abs(`lmn_cv' + 999.9) < 1e-5) {
		scalar `lmn_cv' = .
		scalar `lmn_converged' = .
	}
	if (scalar(`lmn_cv') == .) {
		scalar `lmn_converged' = .
	}
	if (scalar(`lms_cv') == .) {
		scalar `lms_converged' = .
	}
		
	* Label matrices to be returned
	foreach ename in `yvarraw' `Yvarsraw' {
		local enames "`enames' `ename'_v"
		foreach Zvar of local Zvarsraw {
			local Wnames "`Wnames' `ename'_v:`Zvar'"
		}
	}
	if ("`retain'" != "beta") {
		local Wnames
		local enames
		foreach ename in `yvarraw' `retain' {
			local enames "`enames' `ename'_v"
			local i = 1
			foreach Zvar of local Zvarsraw {
				if (`i' >= `N') {
					local Wnames "`Wnames' `ename'_v:`Zvar'"
				}
				local ++i
			}
		}
	}
	matrix rownames `W' = `Wnames'
	matrix colnames `W' = `Wnames'
	if (("`criterion'" == "abs") | ("`retain'" != "beta")) {
		matrix rownames `Sig' = `enames'
		matrix colnames `Sig' = `enames'
	}
	if (("`retain'" != "beta") & ("`target'" != "beta")) {
		matrix rownames `Sigv' = `Yvarsraw'
		matrix colnames `Sigv' = `Yvarsraw'
	}
	
	local avarvcetypetext = strtrim("`avarvcetype'")
	if ("`avarvcetypetext'" == "") local avarvcetypetext "unadjusted"
	
	if (`K' <= `N' + 1) local star "*"
	
	if ("`retain'" == "beta") {
		local gmin_sy = `cragg_donald_statistic'
		local test_name "Stock-Yogo"
	}
	else {
		local test_name "Sanderson-Windmeijer"
	}
	
	tempname sybb_cv
	scalar `sybb_cv' = scalar(`syn_cv')
	if (scalar(`stock_yogo_tables_crit_val') < .) {
		scalar `sybb_cv' = scalar(`stock_yogo_tables_crit_val')
	}
	
	local criterion_full "relative"
	if ("`criterion'" == "abs") local criterion_full "absolute"
	
	* Display results
	local Tstr = strtrim("`: di %12.0fc `T''")
	local Tstr_len = max(5, strlen("`Tstr'"))
	local col1w = 100 - `Tstr_len'
	local col2w = `Tstr_len' 
	local vce_len = strlen("`avarvcetypetext'")
	local colw = 100
	di
	di as text "Lewis and Mertens (2025) robust test for weak instruments with multiple endogenous regressors"
	di
	if ("`retain'" == "beta") {
		di as text %`colw's "Stock and Yogo (2005) setting"
		di as text %`colw's "(first-stage coefficient matrix"
		di as text %`colw's "near to rank 0)"
	}
	else {
		di as text %`colw's "Sanderson and Windmeijer (2016)"
		di as text %`colw's "setting (first-stage coefficient"
		di as text %`colw's "matrix near to rank reduction of 1)"
	}
	di
	di as text %`colw's "Bias criterion: `criterion_full', `target'"
	if ("`retain'" != "beta") {
		di as text %`colw's "Retained regressor: `retain'"
	}
	di as text %`colw's "Covariance matrix type: `avarvcetypetext'"
	di
	di as text %`col1w's "Number of exogenous regressors (incl. const.) (Nx) = " as result %`col2w'.0fc `Nx'
	di as text %`col1w's "Number of endogenous regressors (N) = " as result %`col2w'.0fc `N'
	di as text %`col1w's "Number of instruments (K) = " as result %`col2w'.0fc `K'
	di as text %`col1w's "Number of observations (T) = " as result %`col2w's "`Tstr'"
	di as text %`col1w's "Significance level (alpha) = " as result %`col2w'.3f `alpha'
	di as text %`col1w's "Bias tolerance (tau) = " as result %`col2w'.3f `tau'
	di
	di as text "{hline 100}"
	di as text %84s "Test statistic (gmin_generalized)" as result %16.3f scalar(`gmin_generalized')
	di as text %84s "Lewis-Mertens sharp critical value (lms_cv)`star'" as result %16.3f scalar(`lmn_cv')
	di as text %84s "Lewis-Mertens conservative critical value (lmc_cv)" as result %16.3f scalar(`lms_cv')
	di as text "{hline 100}"
	di as text %84s "`test_name' test statistic (gmin)" as result %16.3f scalar(`gmin_sy')
	di as text %90s "`test_name' bias-based critical value (sybb_cv){c 134}" as result %16.3f scalar(`stock_yogo_tables_crit_val')
	di as text %84s "`test_name' bias-based critical value under Nagar approximation (sybbn_cv)`star'" as result %16.3f scalar(`syn_cv')
	di as text "{hline 100}"

	if (`K' == `N') {
		di as text "Just identified case: test is for median bias"
	}
	if (`K' <= `N' + 1) {
		di as text "*Not calculated if K <= N + 1"
	}
	if (scalar(`stock_yogo_tables_crit_val') < .) {
		di as text "{c 134}Critical value from Stock and Yogo (2005)"
	}
	else {
		if (`"`e(cmd)'"' == "ivreg2") local Kmax = 100
		else local Kmax "30 (ivregress limit)"
		di as text "{c 134}Critical value not available from Stock and Yogo (2005)"
		di as text " [requires N <= 3, K <= `Kmax', K > N + 1, alpha = 0.05, tau in {0.05, 0.1, 0.2, 0.3}]"
	}
	
	if (`K' > `N' + 1) {
		local sharp_conserv "sharp"
		local can_cannot = cond(scalar(`gmin_generalized') > scalar(`lmn_cv'), "can", "cannot")
	}
	else {
		local sharp_conserv "conservative"
		local can_cannot = cond(scalar(`gmin_generalized') > scalar(`lms_cv'), "can", "cannot")
	}
	local alpha_pc = strtrim("`: di %8.6g `alpha'*100'")
	local tau_pc = strtrim("`: di %8.6g `tau'*100'")
	di
	di as text "Thus, based on the `sharp_conserv' Lewis-Mertens critical value, the null of weak instruments `can_cannot' be rejected at the `alpha_pc'% level with a `tau_pc'% bias tolerance"
	
	* Return results
	if (("`retain'" != "beta") & ("`target'" != "beta")) {
		return matrix Sigv = `Sigv'
	}
	if (("`criterion'" == "abs") | ("`retain'" != "beta")) {
		return matrix Sig = `Sig'
	}
	return matrix W = `W'
	return scalar lms_converged = scalar(`lmn_converged')
	return scalar lms_cv = scalar(`lmn_cv')
	return scalar lmc_converged = scalar(`lms_converged')
	return scalar lmc_cv = scalar(`lms_cv')
	return scalar sybbn_cv = scalar(`syn_cv')
	return scalar sybb_cv = scalar(`stock_yogo_tables_crit_val')
	return scalar gmin_generalized = scalar(`gmin_generalized')
	return scalar gmin = scalar(`gmin_sy')
	return scalar tau = `tau'
	return scalar alpha = `alpha'
	
end


capture program drop estimate_memory
program define estimate_memory, rclass

	syntax, n(integer) k(integer)

	local N = `n'
	local K = `k'
	
	local X_size = `K' * `N'
	local M1_size = `N' * (`N'^3)
	local M2PsiM2_size = (`N' * (`K'^2))^2
	local X1_size = (`N'^4) * (`K'^2) * (`N'^2) * (`K'^2)
	
	local tot_size = 8 * (`X_size' + `M1_size' + `M2PsiM2_size' + `X1_size') / (1024^3)
	
	return scalar tot_size_gb = `tot_size'

end




capture program drop avar_call
program define avar_call

	syntax, v2names(varlist numeric) [v1name(varname numeric) znames(varlist numeric) addweight(string) drop avarvcetype(string)]

	if ("`znames'" == "") {
		tempname const
		gen byte `const' = 1
		qui avar (`v1name' `v2names') (`const') `addweight', `avarvcetype' noconstant smata(avar_mat)
		drop `const'
		if ("`drop'" == "drop") {
			drop `v1name' `v2names'
		}
	}
	else {
		qui avar (`v1name' `v2names') (`znames') `addweight', `avarvcetype' noconstant smata(avar_mat)
		if ("`drop'" == "drop") {
			drop `v1name' `v2names' `znames'
		}
	}
	
end



if (c(os) == "Windows") {
	program _lewis_mertens_crit_vals, plugin using(_lewis_mertens_crit_vals_win.plugin)
}
else if (c(os) == "MacOSX") {
	program _lewis_mertens_crit_vals, plugin using(_lewis_mertens_crit_vals_mac.plugin)
}
else if (c(os) == "Unix") {
	program _lewis_mertens_crit_vals, plugin using(_lewis_mertens_crit_vals_linux.plugin)
}



capture program drop lewis_mertens_crit_vals
program define lewis_mertens_crit_vals

	syntax, covmat(name) sigmat(name) sigvmat(name) numendog(integer) numinstr(integer) alpha(real) tau(real) rel(integer) target(integer) retain(integer) points(integer) procs(integer) record(integer) syn_cv_name(name) lms_cv_name(name) lmn_cv_name(name) lms_converged_name(name) lmn_converged_name(name)

	plugin call _lewis_mertens_crit_vals, `covmat' `sigmat' `sigvmat' `numendog' `numinstr' `alpha' `tau' `rel' `target' `retain' `points' `procs' `record' `syn_cv_name' `lms_cv_name' `lmn_cv_name' `lms_converged_name' `lmn_converged_name'
	
end



mata:

mata set matastrict on

struct work_struct {
	real scalar N
	real scalar K
	real matrix RNK
	real matrix M1
	real matrix M2
	real matrix Phi
	real matrix Sigma
	real matrix Psi
	real matrix X1
	real matrix M2PsiM2
}

struct opts_struct {
	real scalar xtol
	real scalar gtol
	real scalar ftol
	real scalar tau
	real scalar rhols
	real scalar eta
	real scalar retr
	real scalar gamma
	real scalar STPEPS
	real scalar nt
	real scalar mxitr
	real scalar record
	real scalar tiny
}

struct out_struct {
	real 	matrix X
	real 	scalar nfe
	string 	scalar msg
	string  scalar progress_buf
	real 	scalar feasi
	real 	scalar nrmG
	real 	scalar fval
	real 	scalar itr
}

struct result_struct {
	real scalar value
	real scalar error
	real scalar converged
}


void _gweakivtest(real scalar alpha, real scalar tau, real scalar rel, real scalar target, real scalar retain, real scalar small, real scalar points, real scalar procs, real scalar record, real scalar useplugin, string scalar gmin_scalar_name, string scalar gmin_sy_scalar_name, string scalar syn_cv_scalar_name, string scalar lmn_cv_scalar_name, string scalar lms_cv_scalar_name, string scalar lmn_converged_scalar_name, string scalar lms_converged_scalar_name) {
	
	real scalar N, Nact, K, Kact
	real matrix W, Sig, Sigv
	string scalar Wtempname, Sigtempname, Sigvtempname, plugin_prog_call_string
	struct work_struct scalar work
	real scalar gmin_generalized, gmin_sy, tau_rescaled, syn_cv
	struct result_struct scalar lms_result, lmn_result
	
	/* Calculate covariance matrices and test statistics */
	N = Nact = K = Kact = W = Sig = Sigv = gmin_generalized = gmin_sy = .
	calc_cov_matrices_and_test_stats(rel, target, retain, small, N, Nact, K, Kact, W, Sig, Sigv, gmin_generalized, gmin_sy)
	
	// Send covariance matrices to Stata (to return and because plugin has to be called from Stata)
	Wtempname = st_local("W")
	st_matrix(Wtempname, W)
	Sigtempname = st_local("Sig")
	st_matrix(Sigtempname, Sig)
	Sigvtempname = st_local("Sigv")
	st_matrix(Sigvtempname, Sigv)

	/* Return test statistics (Stock-Yogo only in LRR1 case because calculated by ivreg2 or ivregress in LTZ case) */
	st_numscalar(gmin_scalar_name, gmin_generalized)
	if (retain > 0) st_numscalar(gmin_sy_scalar_name, gmin_sy)
	

	/* Store W */
	//mm_outsheet("C:/Users/jonsh/source/gweakivtest/out/W_" + strofreal(N) + "_" + strofreal(K) + ".csv" , strofreal(W), "replace", ",")
	/* Store Sig */
	//mm_outsheet("C:/Users/jonsh/source/gweakivtest/out/Sig_" + strofreal(N) + "_" + strofreal(K) + ".csv" , strofreal(Sig), "replace", ",")
	/* Store Sigv */
	//mm_outsheet("C:/Users/jonsh/source/gweakivtest/out/Sigv_" + strofreal(N) + "_" + strofreal(K) + ".csv" , strofreal(Sigv), "replace", ",")
	
	if (useplugin == 0) {
		
		/* Calculate working matrices */
		if (record >= 1) printf("{txt}> Calculating working matrices\n")
		work = working_matrices(Nact, Kact, W, Sig, rel, retain)

		/* Rescale tau if necessary */
		tau_rescaled = rescale_tau_median_bias(tau, work)
		tau_rescaled = rescale_tau_single_coef(tau_rescaled, rel, retain, target, Sig, Sigv, work)

		/* Calcluate Stock-Yogo critical value */
		if (record >= 1) printf("{txt}> Calculating Stock-Yogo critical value\n")
		syn_cv = stock_yogo_nagar_crit_val(Nact, Kact, alpha, tau_rescaled)
		
		/* Calculate simplified Lewis-Mertens critical value */
		if (record >= 1) printf("{txt}> Calculating conservative Lewis-Mertens critical value\n")
		lms_result = lewis_mertens_simple_crit_val(W, alpha, tau_rescaled, rel, retain, record, work)

		/* Calculate Lewis-Mertens critical value */
		if (record >= 1) printf("{txt}> Calculating sharp Lewis-Mertens critical value")
		lmn_result = lewis_mertens_nagar_crit_val(W, alpha, tau_rescaled, points, record, work)
		
		/* Return result */
		st_local("Nact", strofreal(Nact))
		st_local("Kact", strofreal(Kact))
		st_numscalar(syn_cv_scalar_name, syn_cv)
		st_numscalar(lms_cv_scalar_name, lms_result.value)
		st_numscalar(lmn_cv_scalar_name, lmn_result.value)
		st_numscalar(lms_converged_scalar_name, lms_result.converged)
		st_numscalar(lmn_converged_scalar_name, lmn_result.converged)
		
	}
	else {

		printf("{smcl}\n")
	
		// Call plugin program

		plugin_prog_call_string = "lewis_mertens_crit_vals, covmat(" + Wtempname + ") sigmat(" + Sigtempname + ") sigvmat(" + Sigvtempname + ") numendog(" + strofreal(Nact) + ") numinstr(" + strofreal(Kact) + ") alpha(" + strofreal(alpha) + ") tau(" + strofreal(tau) + ") rel(" + strofreal(rel) + ") target(" + strofreal(target) + ") retain(" + strofreal(retain) + ") points(" + strofreal(points) + ") procs(" + strofreal(procs) + ") record(" + strofreal(record) + ") syn_cv_name(" + syn_cv_scalar_name + ") lms_cv_name(" + lms_cv_scalar_name + ") lmn_cv_name(" + lmn_cv_scalar_name + ") lms_converged_name(" + lms_converged_scalar_name + ") lmn_converged_name(" + lmn_converged_scalar_name + ")"
		stata(plugin_prog_call_string)
		
	}
	
}




/* Calculate covariance matrices and test statistics */
void calc_cov_matrices_and_test_stats(real scalar rel, real scalar target, real scalar retain, real scalar small, real scalar N, real scalar Nact, real scalar K, real scalar Kact, real matrix W, real matrix Sig, real matrix Sigv, real scalar gmin_lm, real scalar gmin_sy) {

	real scalar Nx, T, T_numrows, has_cons, has_weights
	real matrix X, Y, Z
	real colvector y, wgt
	
	real matrix M_X, Zo, Yo, P_Zo, PYo, v2, acv, ZV, acve, e, M_non, Ystar, Z2, shat, Yhs
	real rowvector Zobar, idx, not_retain
	string scalar v1name, v2starname, avar_call_string, addweight
	string rowvector v2names, Znames
	real colvector yo, Pyo, betahat, v1, dtilde, ystar, dbar, v2star
	real scalar L, j, r, w_l, denom
	pointer(real matrix) scalar pWavar, pSigavar, pSigvavar
	
	// Bring dimensions of problem into Mata
	Nx = strtoreal(st_local("Nx"))
	has_cons = strtoreal(st_local("has_cons"))
	N = strtoreal(st_local("N"))
	K = strtoreal(st_local("K"))
	T = strtoreal(st_local("T"))
	has_weights = strtoreal(st_local("has_weights"))

	// Bring data into Mata
	Y = st_data(., st_local("Yvarsraw"), st_local("insample"))
	Z = st_data(., st_local("Zvarsraw"), st_local("insample"))
	y = st_data(., st_local("yvarraw"), st_local("insample"))
	T_numrows = rows(y)
	if (Nx > has_cons) {
		X = st_data(., st_local("Xvarsraw"), st_local("insample"))
		/* Add constant to X if needed */
		if (has_cons) {
			X = (X, J(T_numrows, 1, 1))
		}
	}
	else if (has_cons) {
		X = J(T_numrows, 1, 1)
	}
	if (has_weights) {
		wgt = st_data(., st_local("wgt"), st_local("insample"))
		addweight = st_local("addweight")
	}
	else {
		wgt = J(T_numrows, 1, 1)
		addweight = ""
	}
	
	/* Residual-maker matrix for X */
	M_X = I(T_numrows) - (X*invsym(quadcross(X, wgt, X))*(wgt :* X)')

	/* Residuals from regression on X */
	Zo = M_X*Z
	Yo = M_X*Y
	yo = M_X*y

	/* Centre and orthonormalise Zo */
	Zobar = mean(Zo, wgt)
	Zo = (Zo :- Zobar) * matpowersym(quadcrossdev(Zo, Zobar, wgt, Zo, Zobar)/sum(wgt), -0.5)

	/* Projection matrix for Zo */
	P_Zo = Zo*invsym(quadcross(Zo, wgt, Zo))*(wgt :* Zo)'

	/* Predict from regression on Zo */
	PYo = P_Zo*Yo
	Pyo = P_Zo*yo
	
	/* Re-estimate coefficients */
	betahat = invsym(quadcross(PYo, wgt, PYo))*quadcross(PYo, wgt, Pyo)

	/* First-stage and reduced form residuals */
	v1 = yo - Pyo
	v2 = Yo - PYo

	if (retain == 0) {

		Nact = N
		Kact = K
		
		/* Call avar to calculate e and W */
		v1name = st_tempname()
		v2names = st_tempname(Nact)
		Znames = st_tempname(Kact)
		if ((idx = _st_addvar("double", v1name)) < 0) exit(error(-idx))
		if ((idx = _st_addvar("double", v2names))[1] < 0) exit(error(-idx))
		if ((idx = _st_addvar("double", Znames))[1] < 0) exit(error(-idx))
		st_store(., v1name, st_local("insample"), v1)
		st_store(., v2names, st_local("insample"), v2)
		st_store(., Znames, st_local("insample"), Zo)
		if (rel == 0) {
			avar_call_string = "avar_call, v1name(" + v1name + ") v2names(" + invtokens(v2names) + ") addweight(" + addweight + ") avarvcetype(" + st_local("avarvcetype") + ")"
			stata(avar_call_string)
			pSigavar = findexternal("avar_mat")
			Sig = (*pSigavar)
			rmexternal("avar_mat")
			if (small == 1) {
				Sig = Sig * T / (T - Kact - Nx)
			}
		}
		avar_call_string = "avar_call, v1name(" + v1name + ") v2names(" + invtokens(v2names) + ") znames(" + invtokens(Znames) + ") addweight(" + addweight + ") avarvcetype(" + st_local("avarvcetype") + ") drop"
		stata(avar_call_string)
		pWavar = findexternal("avar_mat")
		W = (*pWavar)
		rmexternal("avar_mat")
		if (small == 1) {
			W = W * T / (T - Kact - Nx)
		}
		
		// Calculate gmin_generalized test statistic
		gmin_lm = gmin_test_stat(Nact, Kact, T, W, PYo, wgt)
		
	}
	else {
		
		Nact = 1
		
		not_retain = (1..N)
		not_retain = select(not_retain, not_retain :!= retain)
		
		// Coefficient estimates from regressing retained endog on non-retained endog
		M_non = invsym(quadcross(PYo[., not_retain], wgt, PYo[., not_retain])) * (wgt :* PYo[., not_retain])'
		dtilde = M_non * Yo[., retain]
	
		/* Residual-maker matrix for non-retained */
		M_non = I(T_numrows) - (PYo[., not_retain] * M_non)

		// Residuals from regressing retained endog on non-retained endog
		Ystar = M_non * Yo[., retain]

		// Residuals from regressing outcome on non-retained endog
		ystar = M_non * yo

		// Residuals from regressing last K - N + 1 instruments on non-retained endog
		Z2 = M_non * Zo[., (N..K)]
		
		// Treat columns of vhat as random variables, calculate covariance
		// Default numerator is sum(wgt) - 1, so undo this
		shat = quadvariance(v2, wgt) * (sum(wgt)-1) / T
		if (small == 1) {
			shat = shat * T / (T - K - Nx)
		}

		// Calculate Stock-Yogo test statistic
		dbar = J(N, 1, 1)
		dbar[not_retain] = -dtilde
		denom = dbar'shat*dbar
		gmin_sy = (quadcross(Ystar, wgt, Z2)*invsym(quadcross(Z2, wgt, Z2))*quadcross(Z2, wgt, Ystar)) /((K-N+1) * denom)

		// Needed for gmin_generalized test statistic
		Yhs = Z2*invsym(quadcross(Z2, wgt, Z2))*quadcross(Z2, wgt, Ystar)

		// Orthonormalise
		Z2 = Z2 * matpowersym(quadcross(Z2, wgt, Z2)/sum(wgt), -0.5)

		// Needed for covariance matrix calculation
		v2star = v2[., retain] - v2[., not_retain] * dtilde
		Kact = cols(Z2)

		/* Call avar to calculate Wstar, Sstar and Sfull */
		v1name = st_tempname()
		v2starname = st_tempname()
		v2names = st_tempname(N)
		Znames = st_tempname(Kact)
		if ((idx = _st_addvar("double", v1name)) < 0) exit(error(-idx))
		if ((idx = _st_addvar("double", v2starname)) < 0) exit(error(-idx))
		if ((idx = _st_addvar("double", v2names))[1] < 0) exit(error(-idx))
		if ((idx = _st_addvar("double", Znames))[1] < 0) exit(error(-idx))
		st_store(., v1name, st_local("insample"), v1)
		st_store(., v2starname, st_local("insample"), v2star)
		st_store(., Znames, st_local("insample"), Z2)
		if (target > 0) {
			st_store(., v2names, st_local("insample"), v2)
			avar_call_string = "avar_call, v2names(" + invtokens(v2names) + ") addweight(" + addweight + ") avarvcetype(" + st_local("avarvcetype") + ") drop"
			stata(avar_call_string)
			pSigvavar = findexternal("avar_mat")
			Sigv = (*pSigvavar)
			rmexternal("avar_mat")
			if (small == 1) {
				Sigv = Sigv * T / (T - K - Nx)
			}
		}
		avar_call_string = "avar_call, v1name(" + v1name + ") v2names(" + v2starname + ") addweight(" + addweight + ") avarvcetype(" + st_local("avarvcetype") + ")"
		stata(avar_call_string)
		pSigavar = findexternal("avar_mat")
		Sig = (*pSigavar)
		rmexternal("avar_mat")
		if (small == 1) {
			Sig = Sig * T / (T - K - Nx)
		}
		avar_call_string = "avar_call, v1name(" + v1name + ") v2names(" + v2starname + ") znames(" + invtokens(Znames) + ") addweight(" + addweight + ") avarvcetype(" + st_local("avarvcetype") + ") drop"
		stata(avar_call_string)
		pWavar = findexternal("avar_mat")
		W = (*pWavar)
		if (small == 1) {
			W = W * T / (T - K - Nx)
		}
		rmexternal("avar_mat")
		
		// Calculate gmin_generalized test statistic
		gmin_lm = gmin_test_stat_lrr1(Kact, T, W, Yhs, wgt)

	}
	
	
}



/* Calculate test statistic */
real scalar gmin_test_stat(real scalar N, real scalar K, real scalar T, real matrix W, real matrix PYo, real colvector wgt) {

	real scalar gmin_generalized
	real matrix RNK, W2, Phi, Phiinvhalf, G_T_generalized
	
	RNK = I(N) # vec(I(K))
	W2 = W[|K+1, K+1 \ ., .|]
	Phi = RNK'(W2 # I(K)) * RNK
	Phiinvhalf = matpowersym(Phi, -0.5)
	G_T_generalized = Phiinvhalf * quadcross(PYo, wgt, PYo) * Phiinvhalf
	G_T_generalized = G_T_generalized * T / sum(wgt)
	gmin_generalized = min(symeigenvalues(G_T_generalized))
	
	return(gmin_generalized)
	
}



/* Calculate test statistic for LRR1 case */
real scalar gmin_test_stat_lrr1(real scalar Kstar, real scalar T, real matrix Wstar, real colvector Yhs, real colvector wgt) {

	real scalar Phi, gmin_generalized
	
	Phi = trace(Wstar[|Kstar+1, Kstar+1 \ ., .|])
	gmin_generalized = quadcross(Yhs, wgt, Yhs) / Phi
	gmin_generalized = gmin_generalized * T / sum(wgt)
	
	return(gmin_generalized)
	
}



/* Rescale tau if necessary (for median bias) */
real scalar rescale_tau_median_bias(real scalar tau, struct work_struct scalar work) {
	
	real scalar taunew
	
	taunew = tau
	
	if (work.K == work.N) {
		printf("{txt}Model is just-identified; test is for median bias\n")
		if (work.N == 1) {
			// Sharper bound for median bias
			taunew = tau / 0.455
		}
	}
	
	return(taunew)
	
}


/* Rescale tau if necessary (for single-coefficient test) */
real scalar rescale_tau_single_coef(real scalar tau, real scalar rel, real scalar retain, real scalar target, real matrix Sig, real matrix Sigv, struct work_struct scalar work) {
	
	real scalar taunew
	real matrix iPhi
	
	taunew = tau

	if (target > 0) {
		if (rel == 0 & retain == 0) {
			iPhi = matpowersym(work.Phi, -0.5)
			taunew = tau * norm(iPhi*matpowersym(Sig[|2,2 \ .,.|], 0.5), 2) / (sqrt(Sig[target+1,target+1]) * norm(iPhi[target,.], 2))
		}
		else if (retain > 0) {
			taunew = tau * sqrt(Sig[2,2]) / sqrt(Sigv[target,target]);
		}
	}
	
	return(taunew)
	
}




/* Calcluate Stock-Yogo critical value */
real scalar stock_yogo_nagar_crit_val(real scalar N, real scalar K, real scalar alpha, real scalar tau) {
	
	real scalar Bmax, lmin, crit_val
		
	/* Error if fewer instruments than endogenous regressors */
	if (K < N) _error(3200, "Error: not identified (fewer instruments than endogenous regressors)")

	Bmax = .
	if (K > N + 1) Bmax = (K - (1 + N)) / K
	lmin = Bmax / tau
	crit_val = invnchi2(K, K*lmin, 1 - alpha) / K

	return(crit_val)
	
}


/* Calculate working matrices */
struct work_struct scalar working_matrices(real scalar N, real scalar K, real matrix W, real matrix Sig, real scalar rel, real scalar retain) {

	real scalar r, c
	real matrix W2, W12, RNN, RNpK, Spart, S, Psibar
	struct work_struct scalar work

	/* Error if W is not square */
	r = rows(W)
	c = cols(W)
	if (r != c) exit(error(3205))
	
	/* Number of endogenous regressors */
	if (((r / K) - 1) != N) _error(3200, "Matrix W should be a (N+1)*K x (N+1)*K matrix")

	/* Working matrices */
	work.N = N
	work.K = K
	work.RNK = I(N) # vec(I(K))
	RNN = I(N) # vec(I(N)) 
	RNpK = I(N+1) # vec(I(K))
	work.M1 = RNN'*(I(N^3) + (Kgen(N,N) # I(N)))
	RNN = J(0,0,.)
	work.M2 = ((work.RNK*work.RNK' / (1 + N)) - I(N*K^2))

	W2      = W[|K+1,K+1 \ .,.|]
	W12     = W[|1,K+1 \ K,.|]

	work.Phi = work.RNK'(W2 # I(K))*work.RNK
	Spart = (matpowersym(work.Phi/K, -0.5) # I(K))
	S       = Spart * matpowersym(W2, 0.5)
	work.Sigma   = S*S'
	S = J(0,0,.)

	Psibar = ((Spart * (W12 \ W2)') # I(K)) * RNpK
	Spart = J(0,0,.)
	W2 = J(0,0,.)
	W12 = J(0,0,.)
	
	if (rel == 1 & retain == 0) {
		work.Psi = Psibar * matpowersym((RNpK'(W # I(K)) * RNpK), -0.5)
	}
	else {
		// work.Psi = Psibar * matpowersym(Sig, -0.5) / sqrt(K)
		work.Psi = Psibar * matpowersym(Sig, -0.5) * norm(matpowersym(work.Phi, -0.5) * matpowersym(Sig[|2,2 \ .,.|], 0.5), 2)
	}
	RNpK = J(0,0,.)

	/* In the Matlab code, this used sparse matrices. Mata doesn't have sparse matrices, so these can get really enormous */
	work.X1 = ((I(N) # Kgen(K^2,N)) # I(N^2)) * (vec(I(N)) # I((K^2)*(N^2))) * ((I(K) # Kgen(K,N)) # I(N)) * (I((N^2)*(K^2)) + Kgen(N*K, N*K))
	work.M2PsiM2 = work.M2 * (work.Psi*work.Psi') * work.M2'

	return(work)

}


/* Return an identity matrix with permuted rows */
/* The original Matlab implementation returned a sparse matrix but Mata doesn't have sparse matrices, so a standard matrix is returned here */
real matrix Kgen(real scalar m, real scalar n) {

	real colvector I
	real matrix K

	/* Need to check right way round */
	I = vec(colshape(1..(m*n), m))
	K = I(m*n)
	K = K[I,.]
	return(K)
	
}

/* Calculate simplified Lewis-Mertens critical value */
struct result_struct scalar lewis_mertens_simple_crit_val(real matrix W, real scalar alpha, real scalar tau, real scalar rel, real scalar retain, real scalar record, struct work_struct scalar work) {
	
	real scalar r, c, Bmax
	struct result_struct scalar lms_result

	/* Error if W is not square */
	r = rows(W)
	c = cols(W)
	if (r != c) exit(error(3205))
	
	/* Error if fewer instruments than endogenous regressors */
	if (work.K < work.N) _error(3200, "Error: not identified (fewer instruments than endogenous regressors)")
	
	Bmax = Bmax_simplified(rel, retain, work)
	
	lms_result = cv_imhof(alpha, tau, Bmax, record, work)

	return(lms_result)
	
}


/* Calculate sharp Lewis-Mertens critical value */
struct result_struct scalar lewis_mertens_nagar_crit_val(real matrix W, real scalar alpha, real scalar tau, real scalar points, real scalar record, struct work_struct scalar work) {

	real scalar r, c, Bmax
	struct result_struct scalar lmn_result

	/* Error if W is not square */
	r = rows(W)
	c = cols(W)
	if (r != c) exit(error(3205))
	
	/* Error if fewer instruments than endogenous regressors */
	if (work.K < work.N) {
		_error(3200, "Error: not identified (fewer instruments than endogenous regressors)")
	}
	else if (work.K <= work.N + 1) {
		lmn_result.value = .
		lmn_result.converged = .
	}
	else {
		Bmax = Bmax_sharp(points, record, work)
		lmn_result = cv_imhof(alpha, tau, Bmax, record, work)
	}

	return(lmn_result)

}



/* Calculate simplified maximum bias */
real scalar Bmax_simplified(real scalar rel, real scalar retain, struct work_struct scalar work) {

	real scalar N, K, Bmax, tmp
	
	N = work.N
	K = work.K

	if ((N == 1) & (rel == 1) & (retain == 0)) {
		if (K > N + 1) {
			Bmax = min((sqrt(2 * (N + 1) / K) * norm(work.M2 * work.Psi, 2), norm(work.Psi, 2), 1))
		}
		else {
			tmp = max((sqrt(2 * (N + 1) / K) * norm(work.M2 * work.Psi, 2), norm(work.Psi, 2)))
			Bmax = min((tmp, 1))
		}
	}
	else {
		if (K > N + 1) {
			Bmax = min((sqrt(2 * (N + 1) / K) * norm(work.M2 * work.Psi, 2), norm(work.Psi, 2)))
		}
		else {
			Bmax = max((sqrt(2 * (N + 1) / K) * norm(work.M2 * work.Psi, 2), norm(work.Psi, 2)))
		}
	}
	
	return(Bmax)
	
}

/* Calculate sharp maximum bias */
real scalar Bmax_sharp(real scalar points, real scalar record, struct work_struct scalar work) {

	real scalar N, K, Bmax, iter, done_new_line, i
	real colvector Bmax_iters
	real rowvector timer_val_91, timer_val_95
	real matrix X, R, L0, Z
	struct opts_struct scalar opts
	struct out_struct scalar out1
	string scalar nice_duration
	string colvector progress_buf
	
	N = work.N
	K = work.K
	
	/* Optimization settings */
	opts.record = record
	opts.mxitr  = 1000
	opts.xtol = 1e-5
	opts.gtol = 1e-5
	opts.ftol = 1.e-7
	
	Bmax_iters = J(points, 1, .)
	
	progress_buf = J(6, 1, "")
	done_new_line = 0
	if (record >= 2) progress_buf[1] = sprintf("\n{txt}Sharp maximum bias iterations (total %f):\n", points)
	
	timer_clear(91)
	timer_clear(95)
	timer_on(91)
	timer_on(95)
	
	for (iter=1; iter<=points; iter++) {

		Z = rnormal(K, K, 0, 1)
		qrd(Z, X, R)

		L0        = X[., 1..N]'

		out1 = OptStiefelGBB(L0', &objL0(), opts, work)
		Bmax_iters[iter] = sqrt(-out1.fval)
		if (record == 2) {
			if (done_new_line) {
				printf("%f>" + out1.progress_buf, iter)
			}
			else {
				progress_buf[iter+1] = sprintf("%f>" + out1.progress_buf, iter)
			}
		}
		else if (record >= 3) {
			if (done_new_line) {
				printf("\nIteration %f\n" + out1.progress_buf, iter)
			}
			else {
				progress_buf[iter+1] = sprintf("\nIteration %f\n" + out1.progress_buf, iter)
			}
		}

		if (iter == 1) {
			// If more than 1 minute or fewer than 50 iterations
			timer_off(91)
			timer_val_91 = timer_value(91)
			if ((timer_val_91[1,1] >= 60 | (points < 5)) & (points * timer_val_91[1,1] > 0.0060)) {
				nice_duration = niceify_seconds(points * timer_val_91[1,1])
				if (record == 0) printf("\n{txt}Estimated execution time remaining: %s\n", nice_duration)
				else printf("{txt} (estimated time: %s)\n", nice_duration)
				done_new_line = 1
				if (record >= 2) {
					for (i=1; i<=2; i++) {
						printf(progress_buf[i])
					}
				}
			}
		}
		if (iter == 5) {
			// If less than 1 minute and 50+ iterations
			timer_off(95)
			timer_val_95 = timer_value(95)
			if (timer_val_91[1,1] < 60 & points >= 5 & (points * timer_val_95[1,1] / 5 > 0.0060)) {
				nice_duration = niceify_seconds(points * timer_val_95[1,1] / 5)
				if (record == 0) printf("\n{txt}Estimated execution time remaining: %s\n", nice_duration)
				else printf("{txt} (estimated time: %s)\n", nice_duration)
			}
			else if (!done_new_line) {
				printf("\n")
			}
			if (!done_new_line & record >= 2) {
				for (i=1; i<=6; i++) {
					printf(progress_buf[i])
				}
			}
			done_new_line = 1
		}
		
		
	}

	timer_clear(91)
	timer_clear(95)
	
	Bmax = max(Bmax_iters)
		
	
	return(Bmax)
	
}


string scalar niceify_seconds(real scalar seconds) {
	
	string scalar nice_duration
	
	if (seconds < 60) {
		nice_duration = sprintf("%12.2f seconds", seconds)
	}
	else if (seconds < 3600) {
		nice_duration = sprintf("%12.2f minutes", seconds / 60)
	}
	else if (seconds < 3600*24) {
		nice_duration = sprintf("%12.2f hours", seconds / 3600)
	}
	else {
		nice_duration = sprintf("%12.2f days", seconds / (3600 * 24))
	}
	
	return(strtrim(nice_duration))
	
}



/* Calculate critical value based on Imhof approximation */
struct result_struct scalar cv_imhof(real scalar alpha, real scalar tau, real scalar Bmax, real scalar record, struct work_struct scalar work) {
	
	real scalar K, lmin, n, ome, nu, cc, kt_cond1, kt_cond2, kt_cond3, kt_cond, fval, errcode
	real colvector k, k_old, k_new
	real rowvector zstar
	transmorphic Sopt
	struct result_struct scalar cv_imhof_result

	K = work.K
	k = J(3, 1, .)
	lmin = Bmax / tau
	for (n=1; n<=3; n++) {
		k[n] = (2^(n - 1)) * factorial(n - 1) * (norm(work.RNK'(matpowersym(work.Sigma, n) # I(K)) * work.RNK, 2) + (n * K * lmin * (norm(work.Sigma, 2)^(n - 1))))
	}
	ome = k[2] / k[3]
	nu  = 8 * k[2] * (ome^2)
	cc = invchi2(nu, 1 - alpha)

	cv_imhof_result.error = 0
	cv_imhof_result.converged = 1
	
	/* Check Kuhn-Tucker conditions at the corner solution */
	kt_cond1 = IDfun(&D1fun(), ((cc - nu)/(4 * ome)) + k[1], ome, k, nu)
	kt_cond2 = IDfun(&D2fun(), ((cc - nu)/(4 * ome)) + k[1], ome, k, nu)
	kt_cond3 = IDfun(&D3fun(), ((cc - nu)/(4 * ome)) + k[1], ome, k, nu)
	kt_cond = (kt_cond1 >= 0) & (kt_cond2 >= 0) & (kt_cond3 >= 0)

	/* If Kuhn-Tucker conditions fail, find cumulants that maximize the critical value at alpha numerically */
	if (kt_cond != 1) {
		
		if (record >= 2) printf("Kuhn-Tucker conditions fail; finding cumulants numerically\n")
		k_old = k
		
		Sopt = optimize_init()
		optimize_init_which(Sopt, "min")
		//optimize_init_tracelevel(Sopt, "gradient")
		optimize_init_verbose(Sopt, 0)
		optimize_init_tracelevel(Sopt, "none")
		optimize_init_conv_warning(Sopt, "off")
		optimize_init_conv_ignorenrtol(Sopt, "on")
		optimize_init_conv_maxiter(Sopt, 1000)
		
		if (work.N > 1) {
			optimize_init_evaluator(Sopt, &fun_transf_to_minimize())
			/* These initial values are transformed to allow any values on real line: z = ln(k - x) */
			optimize_init_params(Sopt, ln((1e-4, 1e-4, 1e-4)))
			optimize_init_argument(Sopt, 1, k_old)
			optimize_init_argument(Sopt, 2, alpha)
			cv_imhof_result.error = _optimize(Sopt)
			if (cv_imhof_result.error) {
				Sopt = optimize_init()
				optimize_init_which(Sopt, "min")
				//optimize_init_tracelevel(Sopt, "gradient")
				optimize_init_verbose(Sopt, 0)
				optimize_init_tracelevel(Sopt, "none")
				optimize_init_conv_warning(Sopt, "off")
				optimize_init_conv_ignorenrtol(Sopt, "on")
				optimize_init_evaluator(Sopt, &fun_transf_to_minimize())
				optimize_init_params(Sopt, ln((1e-2, 1e-2, 1e-2)))
				optimize_init_argument(Sopt, 1, k_old)
				optimize_init_argument(Sopt, 2, alpha)
				optimize_init_conv_maxiter(Sopt, 1000)
				cv_imhof_result.error = _optimize(Sopt)
				if (cv_imhof_result.error) {
					printf("{error}Numerical optimization to find cumulants that maximize critical value failed\n")
					errcode = error(3360)
					return(cv_imhof_result)
				}
			}
			cv_imhof_result.converged = optimize_result_converged(Sopt)
			if (!(cv_imhof_result.converged)) {
				if (record >= 2) {
					printf("WARNING: did not converge - results may be unreliable\n")
				}
				else {
					printf("WARNING: attempt to find cumulants numerically did not converge - results may be unreliable\n")
				}
			}
			zstar = optimize_result_params(Sopt)
			/* Transform solution values back */
			k = k_old - exp(zstar')
			fval = optimize_result_value(Sopt)
			ome  = k[2] / k[3]
			nu   = 8 * k[2] * (ome^2)
		}
		else {
			optimize_init_evaluator(Sopt, &fun_n1_transf_to_minimize())
			/* These initial values are transformed to allow any values on real line: z = ln(k - x) */
			optimize_init_params(Sopt, ln((1e-4, 1e-4)))
			optimize_init_argument(Sopt, 1, k_old)
			optimize_init_argument(Sopt, 2, alpha)
			cv_imhof_result.error = _optimize(Sopt)
			if (cv_imhof_result.error) {
				Sopt = optimize_init()
				optimize_init_which(Sopt, "min")
				//optimize_init_tracelevel(Sopt, "gradient")
				optimize_init_verbose(Sopt, 0)
				optimize_init_tracelevel(Sopt, "none")
				optimize_init_conv_warning(Sopt, "off")
				optimize_init_conv_ignorenrtol(Sopt, "on")
				optimize_init_evaluator(Sopt, &fun_n1_transf_to_minimize())
				optimize_init_params(Sopt, ln((1e-2, 1e-2)))
				optimize_init_argument(Sopt, 1, k_old)
				optimize_init_argument(Sopt, 2, alpha)
				optimize_init_conv_maxiter(Sopt, 1000)
				cv_imhof_result.error = _optimize(Sopt)
				if (cv_imhof_result.error) {
					printf("{error}Numerical optimization to find cumulants that maximize critical value failed\n")
					errcode = error(3360)
					return(cv_imhof_result)
				}
			}
			cv_imhof_result.converged = optimize_result_converged(Sopt)
			if (!(cv_imhof_result.converged)) {
				if (record >= 2) {
					printf("WARNING: did not converge - results may be unreliable\n")
				}
				else {
					printf("WARNING: attempt to find cumulants numerically did not converge - results may be unreliable\n")
				}
			}
			zstar = optimize_result_params(Sopt)
			fval = optimize_result_value(Sopt)
			/* Transform solution values back */
			k_new = k_old[2..3] - exp(zstar')
			ome  = k_new[1] / k_new[2]
			nu   = 8 * k_new[1] * (ome^2)
			k[2..3] = k_new
		}
		
		cc  = invchi2(nu, 1 - alpha)
	}

	cv_imhof_result.value = (((cc - nu) / (4 * ome)) + k[1]) / K

	return(cv_imhof_result)

}



real scalar fun_phiz(real scalar z, real scalar ome, real colvector k, real scalar nu) {
	real scalar val
	val = ome * ((1+(z-k[1])/(2*k[2]*ome))^(nu/2-1)) * exp(-nu/2*(1+(z-k[1])/(2*k[2]*ome))) * (nu^(nu/2-1)) / (2^(nu/2-2)) / gamma(nu/2)
	return(val)
}

real scalar G1fun(real scalar q, real scalar nu) {
	real scalar val
	val = (-0.5) * (q - (2 * nu * (nu - 2) / q) + nu) + ((1.5) * nu * (log(q/2) - digamma(nu/2)))
	return(val)
}

real scalar G2fun(real scalar q, real scalar nu) {
	real scalar val
	val = 0.5 * (q - (nu * (nu - 2) / q))  - (nu * (log(q/2) - digamma(nu/2)))
	return(val)
}

real scalar D1fun(real scalar q, real scalar ome, real colvector k, real scalar nu) {
	real scalar val
	val = ((1 + ((q - k[1]) * 2 * ome)) / (2 * k[2] * ome)) * ((1 + ((q - k[1]) / (2 * k[2] * ome)))^(-1)) * fun_phiz(q, ome, k, nu)
	return(val)
}

real scalar D2fun(real scalar q, real scalar ome, real colvector k, real scalar nu) {
	real scalar val
	val = (fun_phiz(q, ome, k, nu) / k[2]) * G1fun(nu + ((q - k[1]) * 4 * ome), nu)
	return(val)
}

real scalar D3fun(real scalar q, real scalar ome, real colvector k, real scalar nu) {
	real scalar val
	val = (G2fun(nu + ((q - k[1]) * 4 * ome), nu) / k[3]) * fun_phiz(q, ome, k, nu)
	return(val)
}

real scalar IDfun(pointer(real scalar function) scalar fun, real scalar q, real scalar ome, real colvector k, real scalar nu) {
	
	class Quadrature scalar qture
	qture = Quadrature()
	qture.setEvaluator(fun)
	qture.setArgument(1, ome)
	qture.setArgument(2, k)
	qture.setArgument(3, nu)
	qture.setLimits((q, .))
	return(qture.integrate())
	
}

void fun_transf_to_minimize(real scalar todo, real rowvector z, real colvector k, real scalar alpha, real scalar val, real rowvector g, real matrix H) {
	real colvector x
	/* Transform back */
	x = k - exp(z')
	val = -(((invchi2(8 * x[2] * ((x[2] / x[3])^2), 1 - alpha) - (8 * x[2] * ((x[2] / x[3])^2))) / (4 * (x[2] / x[3]))) + x[1])
}

void fun_n1_transf_to_minimize(real scalar todo, real rowvector z, real colvector k, real scalar alpha, real scalar val, real rowvector g, real matrix H) {
	real colvector x
	/* Transform back */
	x = k[2..3] - exp(z')
	val = -(((invchi2(8 * x[1] * ((x[1] / x[2])^2), 1 - alpha) - (8 * x[1] * ((x[1] / x[2])^2))) / (4 * (x[1] / x[2]))) + k[1])
}



/* Objective function and gradient */
void objL0(real matrix x, struct work_struct scalar work, real scalar fval, real matrix gradient) {
	
	real matrix L0, QLL, Mobj, Qobj
	real colvector vecL0, ind, ev
	real rowvector Dvec

	L0 = x'
	vecL0 = vec(L0)
	QLL = ((I(work.N) # L0) # L0)
	Mobj = work.M1*QLL*work.M2PsiM2*QLL'work.M1' / work.K
	Mobj = 0.5 * (Mobj + Mobj')
	Mobj = nearestSPD(Mobj)

	Qobj = Dvec = .
	symeigensystem(Mobj, Qobj, Dvec)
	/* Ordering from sort descending */
	ind = order(Dvec', -1)
	Qobj = Qobj[.,ind']
	ev = Qobj[.,1]
	fval = -ev'Mobj*ev

	gradient = 2 * ((ev'work.M1*QLL*work.M2PsiM2) # (ev'work.M1)) * work.X1 * (I(work.N*work.K) # vecL0)
	gradient = -colshape(gradient, work.N)

}


struct out_struct scalar OptStiefelGBB(real matrix X, pointer(void function) scalar fun, struct opts_struct scalar opts, struct work_struct scalar work) {

	real matrix crit, G, GX, GXT, H, RX, eye2k, V, U, VU, VX, dtX, XP, GP, dtXP, aa, S, Y, SY
	real scalar n, k, F, invH, nrmG, p, Q, Cval, tau, itr, FP, nls, deriv, XDiff, FDiff, Qp
	real rowvector mcrit
	struct out_struct scalar out

	/* Check X is not empty */
	n = rows(X)
	k = cols(X)

	if (min((n,k)) == 0) {
		_error(3200, "Input X is an empty matrix")
	}

	/* Populate tolerance parameters */
	if (hasmissing(opts.xtol)) opts.xtol = 1e-6
	if (hasmissing(opts.gtol)) opts.gtol = 1e-6
	if (hasmissing(opts.ftol)) opts.ftol = 1e-12
	
	/* Populate parameters to control linear approximation in line search */
	if (hasmissing(opts.tau)) opts.tau = 1e-3
	if (hasmissing(opts.rhols)) opts.rhols = 1e-4
	if (hasmissing(opts.eta)) opts.eta = 0.1
	if (hasmissing(opts.retr)) opts.retr = 0
	if (hasmissing(opts.gamma)) opts.gamma = 0.85
	if (hasmissing(opts.STPEPS)) opts.STPEPS = 1e-10
	if (hasmissing(opts.nt)) opts.nt = 5
	if (hasmissing(opts.mxitr)) opts.mxitr = 1000
	if (hasmissing(opts.record)) opts.record = 0
	if (hasmissing(opts.tiny)) opts.tiny = 1e-13

	crit = J(opts.mxitr, 3, 1)
	
	/* Which norm to use: Euclidean if vector, Frobenius if matrix */
	p = 2 * (k == 1)
	
	
	/* Initial function value and gradient */
	/* prepare for iterations */
	(*fun)(X, work, F, G)

	out.nfe = 1
	GX = G'X

	if (opts.retr == 1) {
		invH = 1
		if (k < n/2) {
			invH = 0
			eye2k = I(2*k)
		}
		if (invH) {
			GXT = G * X'
			H = 0.5 * (GXT - GXT')
			RX = H*X
		}
		else {
			U = (G, X)
			V = (X, -G)
			VU = V'U
			VX = V'X
		}
	}
	dtX = G - X*GX

	nrmG  = norm(dtX, p)

	Q = 1
	Cval = F
	tau = opts.tau

	if (opts.record >= 3) {
		/* Print iteration header if opts.record >= 3 */
		out.progress_buf = sprintf("----------------------------------- Gradient Method with Line Search -----------------------------------\n")
		out.progress_buf = out.progress_buf + sprintf("%6s %12s %12s %12s %12s %12s %12s %12s %6s\n", "Iter", "tau", "F(X)", "nrmG", "XDiff", "FDiff", "mcrit[2]", "mcrit[3]", "nls")
	}


	/* Main iteration */
	for (itr=1; itr<=opts.mxitr; itr++) {

		/* Record values from previous step */
		XP = X
		FP = F
		GP = G
		dtXP = dtX

		/* Line search: scale step size */
		/* The number of line search attempts in each iteration */
		nls = 1
		deriv = opts.rhols * (nrmG^2)

		while (1) {

			/* Calculate G, F (really?) */
			if (opts.retr == 1) {
				if (invH) {
					X = cholsolve(I(n) + tau*H, XP - tau*RX)
				}
				else {
					aa = cholsolve(eye2k + (0.5*tau)*VU, VX)
					X = XP - U*(tau*aa)
				}
				if (hasmissing(X)) _error(3351, "Matrix X has missing values")
			}
			else {
				X = myQR(XP - tau*dtX)
			}

			if (norm(X'*X - I(k), p) > opts.tiny) {
				X = myQR(X)
			}

			(*fun)(X, work, F, G)
			out.nfe = out.nfe + 1

			if ((F <= Cval - (tau*deriv)) | (nls >= 5)) break
			
			tau = opts.eta * tau
			++nls

		}

		GX = G'X
		if (opts.retr == 1) {
			if (invH) {
				GXT = G*X'
				H = 0.5*(GXT - GXT')
				RX = H*X
			}
			else {
				U =  (G, X)
				V = (X, -G)
				VU = V'U
				VX = V'X
			}
		}

		dtX = G - X*GX
		nrmG  = norm(dtX, p)
		S = X - XP

		XDiff = norm(S, p) / sqrt(n)
		tau = opts.tau
		FDiff = abs(FP-F)/(abs(FP)+1);

		Y = dtX - dtXP
		SY = abs(iprod(S,Y))
		/* Isn't SY a matrix? If so, how is this consistent with tau being a scalar? */
		if (mod(itr, 2) == 0) {
			tau = (norm(S, p)^2) / SY
		}
		else {
			tau  = SY / (norm(Y, p)^2)
		}
    
		tau = max((min((tau, 1e20)), 1e-20))

		crit[itr,.] = (nrmG, XDiff, FDiff)
		mcrit = mean(crit[itr-min((opts.nt,itr))+1::itr, .])
		
		if (opts.record == 2) {
			/* Print iteration dots */
			// printf(".")
			out.progress_buf = out.progress_buf + "."
		}
		else if (opts.record >= 3) {
			out.progress_buf = out.progress_buf + sprintf("%6.0f %12.3e %12.3e %12.3e %12.3e %12.3e %12.3e %12.3e %6.0f\n", itr, tau, F, nrmG, XDiff, FDiff, mcrit[2], mcrit[3], nls)
		}

		/* Check for convergence */
		if ((XDiff < opts.xtol & FDiff < opts.ftol) | (nrmG < opts.gtol) | (all(mcrit[2..3] < 10*(opts.xtol, opts.ftol)))) {
			out.msg = "converged"
			break
		}
		
		Qp = Q
		Q = (opts.gamma*Qp) + 1
		Cval = ((opts.gamma*Qp*Cval) + F) / Q

	}

	if (opts.record == 2) {
		/* Print new line */
		// printf("\n")
		out.progress_buf = out.progress_buf + "\n"
	}
	else if (opts.record >= 3) {
		/* Print iteration footer if opts.record >= 3 */
		out.progress_buf = out.progress_buf + sprintf("%6s %12s %12s %12s %12s %12s %12s %12s %6s\n", "Iter", "tau", "F(X)", "nrmG", "XDiff", "FDiff", "mcrit[2]", "mcrit[3]", "nls")
	}
	if (itr >= opts.mxitr) {
		out.msg = "exceeded max iterations"
	}
	/* printf(out.msg + "\n")
	printf("itr = %8.0f\n", itr) */

	/* Check the feasibility of X (i.e., the orthogonality) */
	out.feasi = norm(X'X - I(k), p)
	
	/* If X is not close to identity, then do one more step */
	if  (out.feasi > 1e-13) {
		X = myQR(X)
		(*fun)(X, work, F, G)
		out.nfe = out.nfe + 1
		out.feasi = norm(X'X - I(k), p)
	}
	
	out.X = X
	out.nrmG = nrmG
	out.fval = F
	out.itr = itr

	return(out)
	
}



real matrix iprod(numeric matrix X, numeric matrix Y) {

	real matrix A
	A = Re(sum(conj(X) :* Y, 1))
	return(A)
	
}

real matrix myQR(real matrix X) {
	
	real rowvector tau, diagR1sign
	real matrix Q1, R1, H
	
	
	/* Calculate efficient QR decomposition */
	H = tau = R1 = .
	hqrd(X, H, tau, R1)
	Q1 = hqrdq1(H, tau)

	/* Identify negative diagonal entries */
	diagR1sign = sign(diagonal(R1)')

	/* if any negative observations in diagRR */
	if (anyof(diagR1sign, -1)) {
		/* Zero out columns corresponding to zero diagonal elements of diagRR */
		/* Multiply by -1 columns corresponding to negative diagonal elements */
		Q1 = Q1 :* diagR1sign
	}
	
	return(Q1)
}





/*
nearestSPD - the nearest (in Frobenius norm) Symmetric Positive Definite matrix to A

usage: Ahat = nearestSPD(A)

From Higham: "The nearest symmetric positive semidefinite matrix in the
Frobenius norm to an arbitrary real matrix A is shown to be (B + H)/2,
where H is the symmetric polar factor of B=(A + A')/2."

http://www.sciencedirect.com/science/article/pii/0024379588902236

Arguments: (input)
  A - square matrix, which will be converted to the nearest Symmetric
      Positive Definite Matrix.

Arguments: (output)
  Ahat - The matrix chosen as the nearest SPD matrix to A.
*/
real matrix nearestSPD(real matrix A) {

	real matrix B, U, Vt, H, Ahat
	real colvector s
	real scalar r, c, p, k, mineig, nudge

	/* Error if A is not square */
	r = rows(A)
	c = cols(A)
	if (r != c) exit(error(3205))

	/* A scalar and non-positive */
	if (r == 1) {
		if (A <= 0) return(epsilon(1))
	}

	/* Symmetrize A into B */
	if (issymmetric(A)) {
		B = A
	}
	else {
		B = (A + A')/2
	}

	/* Compute the symmetric polar factor of B. Call it H */
	/* Clearly H is itself SPD */
	U = s = Vt = .
	svd(B, U, s, Vt)
	H = Vt' * diag(s) * Vt

	/* Get Ahat in the above formula */
	Ahat = (B + H) / 2

	/* Ensure symmetry */
	if (!issymmetric(Ahat)) {
		Ahat = (Ahat + Ahat') / 2
	}

	/* Test that Ahat is in fact PD. if it is not so, then tweak it just a bit */
	k = 0
	p = hasmissing(lowertriangle(cholesky(Ahat)))
	while (p != 0) {
		/* Ahat failed the cholesky test. It must have been just a hair off, */
		/* due to floating point trash, so it is simplest now just to */
		/* tweak by adding a tiny multiple of an identity matrix. */
		k++
		mineig = min(symeigenvalues(Ahat))
		nudge = -mineig * k^2 + epsilon(mineig)
		Ahat = Ahat + I(r) * nudge
		p = hasmissing(lowertriangle(cholesky(Ahat)))
	}

	return(Ahat)
	
}


end