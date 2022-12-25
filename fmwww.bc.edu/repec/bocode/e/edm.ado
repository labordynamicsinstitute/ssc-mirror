*! version 1.9.10, 21Dec2022, Jinjing Li, Michael Zyphur, Patrick J. Laub, George Sugihara, Edoardo Tescari
*! contact: <jinjing.li@canberra.edu.au> or <patrick.laub@gmail.com>

global EDM_VERSION = "1.9.10"
/* Empirical dynamic modelling

Version history:
* 29/10/2020: suppress some debug information and fix a bug on copredict with dt
* 13/10/2020: speed improvement on matrix copying
* 15/9/2020: add plugin support
* 15/8/2020: fix a bug in the default number of k in smap and labelling
* 29/5/2020: robustness improvement
* 26/5/2020: update ci() return format and add pc tile values
* 26/5/2020: return e(ub_rho1) e(lb_rho1) etc for the ci() estimates
* 19/5/2020: Update s-map / llr algorithm
* 13/5/2020: bug fix in coprediction
* 22/4/2020: allow copredict() together with dt
* 26/3/2020: remove omitted coefficients instead of reporting as 0
* 17/2/2020: robustness improvement when dt and allowmissing are specified at the same time
* 15/2/2020: improve robustness for estimations using data with missing identifier
* 4/2/2020: update smap coefficient label
* 27/1/2020: report actual E used, add "reportrawe" option
* 23/1/2020: bug fix to disallow constant in extras
* 16/1/2020: update default distance
* 16/1/2020: allow error recovery
* 9/1/2020: allow missing data to be included in the calculation
* 9/1/2020: allow automatic time difference in the embedding via dt option
* 26/11/2019: extra embedding option for both explore and xmap
* 17/11/2019: fix a bug where the missing values of the second variables are not detected in the data cleaning process
* 2/11/2019: add -force- option, improve error message for xmap
* 24/10/2019: speed improvement for duplicate values
* 24/10/2019: bug fix on develop update
* 28/9/2019: bug fixes in explore mode
* 10/7/2019: coprediction and many others including an improvement of nearest non-overlap neighbour search
* 15/6/2019: Many new features
* 12/3/2019: labelling of the savesmap

 */

program define edm, eclass sortpreserve
	version 14

	if replay() {
		if (`"`e(cmd)'"' != "edm") {
			noi di as error "results for edm not found"
			exit 301
		}
		edmDisplay `0'
		exit `rc'
	}
	else edmParser `0'
end

program define edmParser, eclass

	/* syntax anything(id="subcommand or variables" min=2 max=3)  [if], [e(numlist ascending)] [theta(numlist ascending)] [manifold(string)] [converge] */

	* identify subcommand
	local subcommand "`1'"
	if strpos("`subcommand'",",") !=0 {
		local subcommand =substr("`1'",1,strpos("`subcommand'",",")-1)
	}
	local subargs = substr("`0'", strlen("`subcommand'")+1,.)

	if "`subcommand'" == "update" {
		edmUpdate `subargs'
	}
	else if "`subcommand'" == "version" {
		edmVersion `subargs'
	}
	else {
		qui xtset
		local original_t = r(timevar)
		if "`=r(panelvar)'" == "." {
			local original_id = ""
		}
		else {
			local original_id = r(panelvar)
		}

		ereturn clear
		if inlist("`subcommand'","explore","xmap") {
			cap noi {
				nobreak {
					if "`subcommand'" == "explore" {
						edmExplore `subargs'
					}
					else if "`subcommand'" == "xmap" {
						edmXmap `subargs'
					}
				}
			}
			if _rc !=0 {
				local error_code = _rc
				cap xtset
				if _rc !=0 {
					if "`original_id'" != ""{
						qui xtset `original_id' `original_t'
					}
					else {
						qui tsset `original_t'
					}
				}
				cap error `error_code'
				/* di as text "r(`error_code');" */
				exit(`error_code')
			}

		}
		else {
			di as error `"Invalid subcommand. Use "explore" or "xmap""'
			error 1
		}
		ereturn local cmd "edm"
		ereturn local cmdline `"edm `0'"'
	}
end

program define edmUpdate
	syntax , [DEVELOPment] [replace]
	if "`development'" == "development" {
		di "Updating edm from the development channel"

		local updateFolder = "updating-edm-stata-package"
		capture cd "`updateFolder'"
		if _rc != 0 {
			cap mkdir "`updateFolder'"
			if _rc == 693 {
				di as error "Failed to make the '`updateFolder'' directory."
				di as error "Perhaps check you have write permissions."
				error 693
			}
			cd "`updateFolder'"
		}

		local path "https://github.com/EDM-Developers/edm-stata/releases/latest/download/edm-stata-package.zip"
		quietly copy "`path'" "edm-stata-package.zip", replace
		quietly unzipfile "edm-stata-package.zip", replace

		local updatePath : pwd

		capture quietly ado uninstall "edm"
		net install "edm", from("`updatePath'") `replace' `force'

		cd ..
		cap qui rmdir "`updateFolder'"
	}
	else {
		di "Updating edm from SSC"
		ssc install edm, `replace'
	}
	prog drop _all
	discard
end

program define edmVersion
	syntax , [test]
	dis "${EDM_VERSION}"
end


program define edmPluginCheck, rclass
	syntax , [mata] [gpu]
	if "${EDM_MATA}" == "1" | "`mata'" == "mata" {
		return scalar mata_mode = 1
		return scalar gpu_mode = 0
	}
	else {
		local mata_mode = 0
		local gpu_mode = "${EDM_GPU}" == "1" | "`gpu'" == "gpu"

		if `gpu_mode' {
			cap edm_plugin_gpu
			if _rc == 199 {
				di as text "Warning: GPU-powered plugin failed to load, falling back to CPU version"
				local gpu_mode = 0
			}
		}

		if !`gpu_mode' {
			cap edm_plugin
			if _rc == 199 {
				di as text "Warning: Failed to load the compiled C++ plugin, falling back to the slower Mata backup"
				local mata_mode = 1
			}
		}

		return scalar mata_mode = `mata_mode'
		return scalar gpu_mode = `gpu_mode'
	}
end

program define hasMissingValues
	syntax [anything] , out(name)
	qui gen byte `out' = 0

	if "`anything'" != "" {
		tsunab varlist : `anything'

		foreach var in `varlist' {
			qui replace `out' = 1 if `var' == .
		}
	}
end

program define edmPreprocessVariable, rclass
	syntax anything , touse(name) out(name)

	local factor_var = "0"

	if substr("`1'", 1, 2) == "z." {  // user asks for this variable to be normalized
		local varname = substr("`1'", 3, .)
		qui egen `out' = std(`varname') if `touse'
	}
	else if substr("`1'", 1, 2) == "i." {  // treat as a factor variable
		local factor_var = "1"
		local varname = substr("`1'", 3, .)
		qui gen double `out' = `varname' if `touse'
	}
	else {
		qui gen double `out' = `1' if `touse'
	}
	return local factor_var = "`factor_var'"
end


program define edmManifoldSize, rclass
	syntax , e(int) dt(int) num_extras(int) [num_eextras(int 0)]
	local num_xs = `e'
	local num_dts = `dt' * `e'
	local total_num_extras = `num_extras' + `num_eextras' * (`e' - 1)
	return local total_num_extras = `total_num_extras'
	return local manifold_size = `num_xs' + `num_dts' + `total_num_extras'
end


program define edmCountExtras, rclass
	syntax [anything]

	local extravars = strtrim("`anything'")
	local z_names = ""
	local z_count = 0
	local z_e_varying_count = 0
	local z_factor_var = ""

	// First, reorder the variables so that the "(e)" / lagged variables are first
	local laggedvars = ""
	local unlaggedvars = ""
	foreach v of local extravars {
		local e_varying = strpos("`v'", "(e)")
		if `e_varying' {
			local laggedvars = strtrim("`laggedvars' `v'")
			local ++z_e_varying_count
		}
		else {
			local unlaggedvars = strtrim("`unlaggedvars' `v'")
		}
	}

	local extravars = strtrim("`laggedvars' `unlaggedvars'")

	// Next, do the proper parsing, validation, and handle the "z."/"i." prefixes
	foreach v of local extravars {
		local z_prefix = strpos("`v'", "z.")
		if `z_prefix' {
			if `z_prefix' > 1 {
				noi di as error "Extra '`v'' must have 'z.' prefix come first"
				error 198
			}
			local v = substr("`v'",3,.)
		}

		local i_prefix = strpos("`v'", "i.")
		if `i_prefix' {
			if `z_prefix' {
				noi di as error "Extra '`v'' can't both 'z.' prefix and 'i.' prefix"
				error 198
			}
			local v = substr("`v'",3,.)
		}

		local e_varying = strpos("`v'", "(e)")
		if `e_varying' {
			local suffix_ind = strlen("`v'")-3+1
			if `e_varying' != `suffix_ind' {
				noi di as error "Extra '`v'' must have '(e)' suffix come last"
				error 198
			}
			local v = substr("`v'", 1, `suffix_ind'-1)
		}

		tsunab v_list : `v'
		local v_count = wordcount("`v_list'")
		if `v_count' > 1 & `e_varying' {
			noi di as error "Extra '`v'' can't combine '(e)' suffix to a time-series varlist"
			error 198
		}
		tokenize `v_list'
		forvalues i = 1/`v_count' {
			local z_names = "`z_names' `=cond(`z_prefix', "z.", "")'`=cond(`i_prefix', "i.", "")'``i''`=cond(`e_varying', "(e)", "")'"
			local ++z_count
			local z_factor_var = "`z_factor_var' `=cond(`i_prefix', 1, 0)'"
		}
	}

	return local z_names = strtrim("`z_names'")
	return local z_count = `z_count'
	return local z_e_varying_count = `z_e_varying_count'
	return local z_factor_var = strtrim("`z_factor_var'")
end

program define edmPreprocessExtras, rclass
	syntax [anything] , touse(name) [z_vars(string)]

	local z_names = strtrim("`anything'")
	local z_count = wordcount("`z_names'")

	forvalues i = 1/`z_count' {
		local z_name : word `i' of `z_names'
		local z_var : word `i' of `z_vars'

		local e_varying = strpos("`z_name'", "(e)")
		if `e_varying' {
			local suffix_ind = strlen("`z_name'")-3+1
			local z_name = substr("`z_name'", 1, `suffix_ind'-1)
		}

		edmPreprocessVariable `z_name' , touse(`touse') out(`z_var')
	}
end

program define edmPrintPluginProgress
	syntax , plugin_name(string)

	plugin call `plugin_name' , "report_progress"

	local breakJustHit = 0
	local breakEverHit = 0
	local sleepTime = 0.001
	local numSleeps = 0

	while !plugin_finished {
		local ++numSleeps

		// This is the only time when the plugin will accept the 'break' button
		capture break sleep `sleepTime'

		if _rc {
			local breakJustHit = 1
			local breakEverHit = 1
		}
		plugin call `plugin_name' , "report_progress" "`breakJustHit'"

		local breakJustHit = 0

		if `numSleeps' == 1000 {
			local sleepTime = 1
		}
	}

	if `breakEverHit' {
		exit 1
	}
end

program define edmExplore, eclass
	syntax anything [if], [e(numlist ascending >=1)] ///
		[tau(integer 1)] [theta(numlist ascending)] [k(integer 0)] [ALGorithm(string)] [REPlicate(integer 0)] ///
		[seed(integer 0)] [full] [RANDomize] [PREDICTionsave(name)] [COPREDICTionsave(name)] [copredictvar(string)] ///
		[CROSSfold(integer 0)] [CI(integer 0)] [EXTRAembed(string)] [ALLOWMISSing] [MISSINGdistance(real 0)] ///
		[dt] [reldt] [DTWeight(real 0)] [DTSave(name)] [DETails] [reportrawe] [strict] [Predictionhorizon(string)] ///
		[dot(integer 1)] [mata] [gpu] [nthreads(integer 0)] [savemanifold(name)] [idw(real 0)] [predictwithpast] ///
		[verbosity(integer 1)] [saveinputs(string)] [lowmemory] [metrics(string)] [distance(string)] [aspectratio(real 1)] [wassdt(integer 1)]

	edmPluginCheck, `mata' `gpu'
	local mata_mode = r(mata_mode)

	if !`mata_mode' {
		if `r(gpu_mode)' {
			local plugin_name = "edm_plugin_gpu"
		}
		else {
			local plugin_name = "edm_plugin"
		}

		if `r(gpu_mode)' & "`lowmemory'" == "lowmemory" {
			di as text "Warning: Lowmemory mode currently not working with the GPU implementation."
			local lowmemory = ""
		}
	}

	local predictWithPast = ("`predictwithpast'" == "predictwithpast")
	if (`predictWithPast' & "`strict'" == "strict") {
		di as text "Warning: 'strict' is ignored when 'predictwithpast' is specified."
		local strict = ""
	}

	if ("`strict'" != "strict") {
		local force = "force"
	}

	local cmdline = "edm explore `0'"

	if `seed' != 0 {
		set seed `seed'
	}

	if "`dtsave'" != "" {
		confirm new variable `dtsave'
	}
	if "`predictionsave'" != "" {
		confirm new variable `predictionsave'
	}
	if "`copredictionsave'" != "" {
		confirm new variable `copredictionsave'

		if "`copredictvar'" == "" {
			di as error "The copredictvar() option is not specified"
			error 111
		}
	}

	if "`randomize'" == "randomize" | `replicate' > 0 {
		local shuffle = 1
	}
	else {
		local shuffle = 0
	}

	if `replicate' == 0 {
		local replicate = 1
	}

	local copredictvar = strtrim("`copredictvar'")
	if "`copredictvar'" != "" & strpos("`copredictvar'", " ") {
		di as error "The copredictvar() should only specify one variable"
		error 111
	}

	if `crossfold' > 1 {
		if `replicate' > 1 {
			di as error "Replication must be not set if crossfold validation is used."
			error 119
		}
		if "`full'" == "full" {
			di as error "option full cannot be specified in combination with crossfold."
			error 119
		}
	}

	// If we say 'use all neighbours', then this is implicitly using 'force' mode
	if `k' < 0 {
		if "`strict'" == "strict" {
			di as text "Warning: 'strict' is ignored when a negative 'k' is specified."
		}
		local force = "force"
	}

	* default values
	if "`theta'" == "" {
		local theta = 1
	}

	if "`predictionhorizon'" == "" {
		local predictionhorizon = `tau'
	}
	else {
		local predictionhorizon = real("`predictionhorizon'")

		if `predictionhorizon' == . {
			dis as error "Require [Predictionhorizon] to either be empty or an integer"
			error 9
		}
	}

	* identify data structure
	qui xtset
	local timevar "`=r(timevar)'"
	if "`=r(panelvar)'" != "." {
		local ispanel =1
		local panel_id = r(panelvar)
	}
	else {
		local ispanel =0
	}
	if !inlist("`algorithm'","smap","simplex","llr","") {
		dis as error "Not valid algorithm specification"
		error 121
	}
	if "`algorithm'" == "" {
		local algorithm "simplex"
	}

	local allow_missing_mode = `missingdistance' != 0 | "`allowmissing'" == "allowmissing"
	if `allow_missing_mode' & "`algorithm'" == "smap" {
		dis as error "Can't use 'allowmissing' with S-map algorithm"
		error 121
	}

	if "`distance'" == "" {
		local distance = "euclidean"
	}

	if "`metrics'" == "" {
		local metrics = "auto"
	}

	// Allow global variables to overwrite some options.
	// This is to make it easier to change an option for all edm calls in a large do file.
	if "${EDM_VERBOSITY}" != "" {
		local verbosity = ${EDM_VERBOSITY}
	}

	if "${EDM_NTHREADS}" != "" {
		local nthreads = ${EDM_NTHREADS}
	}

	if "${EDM_DISTANCE}" != "" {
		local distance = "${EDM_DISTANCE}"
	}

	if "${EDM_METRICS}" != "" {
		local metrics = "${EDM_METRICS}"
	}

	if "${EDM_SAVE_INPUTS}" != "" {
		local saveinputs = "${EDM_SAVE_INPUTS}"
	}

	local wasserstein_mode = ("`=strlower("`distance'")'" == "wasserstein")
	local parsed_dt = ("`dt'" == "dt") | ("`reldt'" == "reldt")
	local parsed_reldt = ("`reldt'" == "reldt")
	local parsed_dtw = "`dtweight'"
	local parsed_dtsave = "`dtsave'"

	* create manifold as variables
	tokenize "`anything'"
	local ori_x "`1'"
	if "`2'" != "" {
		error 103
	}
	if "`e'" == "" {
		local e = 2
	}
	local report_actuale = "`reportrawe'" ==""
	marksample touse
	markout `touse' `timevar' `panel_id'

	sum `touse', meanonly
	local num_touse = r(sum)

	tempvar x
	edmPreprocessVariable "`1'", touse(`touse') out(`x')

	if "`copredictvar'" != "" {
		* build prediction manifold
		tokenize "`copredictvar'"
		tempvar co_x
		edmPreprocessVariable "`1'", touse(`touse') out(`co_x')
	}

	if `mata_mode' & `parsed_dt' {
		// Get the column of dt values if needed for dtsave or the dtweight default
		if `parsed_dtw' == 0 | !inlist("`parsed_dtsave'","",".") {
			tempvar dt_value
			qui gen `dt_value' = .
			mata: calculate_dt("`timevar'", "`x'", "`panel_id'", `allow_missing_mode', ///
					`tau', `predictionhorizon', "", "`dt_value'")
		}

		// Calculate the default value for 'dtweight'
		if `parsed_dtw' == 0 {
			qui sum `x' if `touse'
			local xsd = r(sd)
			qui sum `dt_value' if `touse'
			local tsd = r(sd)
			local parsed_dtw = `xsd'/`tsd'
			if `tsd' == 0 & !`wasserstein_mode' {
				// if there is no variance, no sampling required
				local parsed_dtw = 0
				local parsed_dt = 0
				local parsed_dtsave = ""
			}
		}

		if !inlist("`parsed_dtsave'","",".") {
			qui clonevar `parsed_dtsave' = `dt_value'
			qui label variable `parsed_dtsave' "Time delta (`timevar')"
		}
	}

	edmCountExtras `extraembed'
	local z_count = `r(z_count)'
	local z_names = "`r(z_names)'"
	local z_e_varying_count = `r(z_e_varying_count)'
	local z_factor_var = "`r(z_factor_var)'"

	local z_vars = ""
	forvalues i = 1/`z_count' {
		tempvar z
		local z_vars = "`z_vars' `z'"
	}
	edmPreprocessExtras `z_names' , touse(`touse') z_vars(`z_vars')

	numlist "`e'"
	local e_size = wordcount("`=r(numlist)'")
	local max_e : word `e_size' of `e'

	if (`max_e' > 100000) {
		dis as error "The proposed embedding dimension E is too big."
		error 121
	}

	numlist "`theta'"
	local theta_size = wordcount("`=r(numlist)'")
	local round = max(`crossfold', `replicate')

	local task_num = 1
	local num_tasks = `round'*`theta_size'*`e_size'
	mat r = J(`num_tasks', 4, .)

	if ("`copredictvar'" != "") {
		mat co_r = J(`num_tasks', 4, .)
	}

	edmManifoldSize, e(`max_e') dt(`parsed_dt') ///
		num_extras(`z_count') num_eextras(`z_e_varying_count')
	local manifold_size = `r(manifold_size)'
	local total_num_extras = `r(total_num_extras)'

	if `mata_mode' {
		mata: construct_manifold("`touse'", "`panel_id'", "`x'", "`timevar'", "`z_vars'", "`x'", ///
			`z_count', `z_e_varying_count', `parsed_dt', `parsed_reldt', `parsed_dtw', ///
			`max_e', `tau', `predictionhorizon', `allow_missing_mode', 0)

		// Choose which rows of the manifold we will use for the analysis
		// (this mainly depends on whether we're keeping or discarding rows
		// with some missing values).
		tempvar usable

		if `allow_missing_mode' {
			// Work on any row of the manifold with >= 1 non-missing value
			qui {
				qui gen byte `usable' = 0
				foreach v of local max_e_manifold {
					replace `usable' = 1 if `v' != . & `touse'
				}
			}
		}
		else {
			// Find which rows of the manifold have any values which are missing
			tempvar any_missing_in_manifold
			hasMissingValues `max_e_manifold', out(`any_missing_in_manifold')
			gen byte `usable' = `touse' & !`any_missing_in_manifold'
		}

		// Default value for 'missingdistance'
		if `allow_missing_mode' & `missingdistance' <= 0 {
			qui sum `x' if `touse'
			local missingdistance = 2/sqrt(c(pi))*r(sd)
		}

		if "`copredictvar'" != "" {
			mata: construct_manifold("`touse'", "`panel_id'", "`co_x'", "`timevar'", "`z_vars'", "`co_x'", ///
				`z_count', `z_e_varying_count', `parsed_dt', `parsed_reldt', `parsed_dtw', ///
				`max_e', `tau', `predictionhorizon', `allow_missing_mode', 1)

			// Generate the same way as `usable'.
			tempvar co_usable
			if `allow_missing_mode' {
				qui gen byte `co_usable' = 0
				foreach v of local max_e_co_manifold {
					qui replace `co_usable' = 1 if `v' !=. & `touse'
				}
			}
			else {
				tempvar any_missing_in_co_manifold
				hasMissingValues `max_e_co_manifold', out(`any_missing_in_co_manifold')
				gen byte `co_usable' = `touse' & !`any_missing_in_co_manifold'
			}

			tempvar co_predict_set
			gen byte `co_predict_set' = `co_usable'
		}
	}

	if !`mata_mode' {
		// Setup variables which the plugin will modify
		scalar plugin_finished = 0
		local missing_dist_used = .
		local dtw_used = .
		local num_usable = .

		local explore_mode = 1
		local full_mode = ("`full'" == "full")
		local copredict_mode = ("`copredictvar'" != "")

		if `copredict_mode' {
			local co_xvar = "`co_x'"
		}
		else {
			local co_xvar = ""
		}

		// Can't pass the c(rngstate) directly to the plugin as a function argument as it is too long.
		// Instead, just save it as a local and have the plugin read it using the Stata C API.
		local originalRNG = "`c(rng)'"
		if ("`originalRNG'" != "default") | ("`originalRNG'" != "mt64") {
			set rng mt64
		}

		local rngstate = c(rngstate)

		local low_memory_mode = "`lowmemory'" == "lowmemory"

		if "`parsed_dtsave'" != "" {
			qui gen double `parsed_dtsave' = .
		}

		local manifold_vars = ""

		if "`savemanifold'" != "" {
			forvalues ii=1/`manifold_size' {
				cap gen double `savemanifold'_`ii' = .
				if _rc!=0 {
					di as error "Cannot save the manifold using variable `savemanifold'_`ii' - is the prefix used already?"
					exit(100)
				}
				local manifold_vars = "`manifold_vars' `savemanifold'_`ii'"
			}
		}

		plugin call `plugin_name' `timevar' `x' `x' `z_vars' `co_xvar' `panel_id' `parsed_dtsave' `manifold_vars', "launch_edm_tasks" ///
				"`z_count'" "`parsed_dt'" "`dtweight'" "`algorithm'" "`force'" "`missingdistance'" ///
				"`nthreads'" "`verbosity'" "`num_tasks'" "`explore_mode'" "`full_mode'" "`shuffle'" "`crossfold'" "`tau'" ///
				"`max_e'" "`allow_missing_mode'" "`theta'" "`aspectratio'"  "`distance'" "`metrics'" ///
				"`copredict_mode'" "`cmdline'" "`z_e_varying_count'" "`idw'" "`ispanel'" "`parsed_reldt'" "`wassdt'" ///
				"`predictionhorizon'" "`low_memory_mode'" "`predictWithPast'"

		local missingdistance = `missing_dist_used'

		if `parsed_dt' {
			local parsed_dtw = `dtw_used'
			if `dtw_used' < 0 {
				local parsed_dt = 0
			}
		}
	}

	if `mata_mode' {
		tempvar train_set predict_set
		tempvar x_p
		qui gen double `x_p' = .

		if "`copredictvar'" != "" {
			tempvar co_x_p
			qui gen double `co_x_p' = .
		}

		sum `usable', meanonly
		local num_usable = r(sum)
	}

	if `crossfold' > 1 {
		if `crossfold' > `num_usable' / `max_e' {
			di as error "Not enough observations for cross-validations"
			error 149
		}

		if `mata_mode' {
			if `shuffle' {
				tempvar crossfoldu crossfoldunum
				qui gen double `crossfoldu' = runiform() if `usable'
				qui egen `crossfoldunum'= rank(`crossfoldu'), unique
			}

			tempvar counting_up fold_number
			qui gen double `counting_up' = sum(`usable') if `usable'
			qui gen `fold_number' = .

			local num_in_each_fold = round(`num_usable' / `crossfold')

			local start = 1
			forvalues t=1/`crossfold' {
				qui replace `fold_number' = `t' if `counting_up' >= `start' & `counting_up' < `start' + `num_in_each_fold'
				local start = `start' + `num_in_each_fold'
			}
		}
	}

	if `num_usable' == 0 | (`num_usable' == 1 & "`full'" != "full") | (`crossfold' > 1 & `num_usable' < `crossfold') {
		noi display as error "Invalid dimension or library specifications"
		error 9
	}

	if `round' > 1 & `dot' > 0 {
		if `replicate' > 1 {
			di "Replication progress (`replicate' in total)"
		}
		else if `crossfold' > 1 {
			di "`crossfold'-fold cross-validation progress (`crossfold' in total)"
		}
		local finished_rep = 0
	}

	if (`crossfold' <= 1 & "`full'" != "full") {
		tempvar u
	}

	if !`mata_mode' {
		// Count how many random numbers that the plugin will have used
		if (`crossfold' > 1) {
			local numRVs = `num_usable' * `shuffle'
		}
		else {
			local numRVs = `num_usable' * `round' * `shuffle' * ("`full'" != "full")
		}

		// Burn through them in the Stata RNG so that both streams are synchronised
		mata: burn_rvs(`numRVs')

		set rng `originalRNG'
	}


	if "`predictionsave'" != "" {
		cap gen double `predictionsave' = .
		qui label variable `predictionsave' "edm prediction result"
	}

	if ("`copredictionsave'" != "") {
		qui gen double `copredictionsave' = .
		qui label variable `copredictionsave' "edm copredicted `copredictvar' using manifold `ori_x'"
	}

	if `mata_mode' {
		local k_min = .
		local k_max = .

		forvalues t=1/`round' {

			// Generate some random numbers (if we're in a mode which needs them
			// to separate the testing and prediction sets.)
			if `crossfold' <= 1 & "`full'" != "full" & `shuffle' {
				if `t' == 1 {
					qui gen double `u' = runiform() if `usable'
				}
				else {
					qui replace `u' = runiform() if `usable'
				}
			}

			// Split the data into training and prediction sets.
			cap drop `train_set' `predict_set'
			if `crossfold' > 1 {
				if `shuffle' {
					qui gen byte `train_set' = mod(`crossfoldunum',`crossfold') != (`t' - 1) & `usable'
					qui gen byte `predict_set' = mod(`crossfoldunum',`crossfold') == (`t' - 1) & `usable'
				}
				else {
					qui gen byte `predict_set' = `fold_number' == `t' & `usable'
					qui gen byte `train_set' = `fold_number' != `t' & `usable'
				}
			}
			else if "`full'" == "full"  {
				gen byte `train_set' = `usable'
				gen byte `predict_set' = `usable'
			}
			else {
				if `shuffle' {
					qui sum `u', d
					qui gen byte `train_set' = `u' < r(p50) & `u' !=.
					qui gen byte `predict_set' = `u' >= r(p50) & `u' !=.
				}
				else {
					tempvar counting_up
					cap drop `counting_up'
					qui gen double `counting_up' = sum(`usable') if `usable'
					local half_size = `num_usable' / 2

					qui gen byte `train_set' = `counting_up' <= `half_size' & `counting_up' != .
					qui gen byte `predict_set' = `counting_up' > `half_size' & `counting_up' != .
				}
			}

			qui replace `train_set' = 0 if `x_f' == .

			if `crossfold' > 1 {
				local num_in_each_fold = round(`num_usable' / `crossfold')
				if `t' != `crossfold' {
					local train_size = `num_usable' - `num_in_each_fold'
				}
				else {
					local train_size = `num_in_each_fold' * (`crossfold' - 1)
				}
			}
			else if "`full'" == "full"  {
				local train_size = `num_usable'
			}
			else {
				local train_size = floor(`num_usable'/2)
			}

			// Set library size (unless k=0, when an adaptive default is applied)
			if `k' > 0 {
				local lib_size = min(`k', `train_size')
			}
			else if `k' < 0 {
				local lib_size = `train_size'
			}

			foreach i of numlist `e' {

				local manifold "mapping_`=`i'-1'"
				local co_manifold "co_mapping_`=`i'-1'"

				edmManifoldSize, e(`i') dt(`parsed_dt') ///
					num_extras(`z_count') num_eextras(`z_e_varying_count')
				local total_num_extras = `r(total_num_extras)'
				local e_offset = `r(manifold_size)' - `i'
				local current_e =`i' + cond(`report_actuale'==1,`e_offset',0)

				// Set the adaptive default library size
				if `k' == 0 {
					local is_smap = cond("`algorithm'" == "smap", 1, 0)
					local def_lib_size = `r(manifold_size)' + `is_smap' + 1
					local lib_size = min(`def_lib_size',`train_size')
				}

				foreach j of numlist `theta' {

					mat r[`task_num',1] = `current_e'
					mat r[`task_num',2] = `j'

					if "`copredictvar'" != "" {
						mat co_r[`task_num',1] = `current_e'
						mat co_r[`task_num',2] = `j'
					}

					local savesmap_vars ""
					break mata: smap_block("``manifold''", "", "`x_f'", "`x_p'", "`train_set'", "`predict_set'", `j', ///
						`lib_size', "`algorithm'", "`savesmap_vars'", "`force'", `missingdistance', `idw', "`panel_id'", ///
						`i', `total_num_extras', `z_e_varying_count', "`z_factor_var'")

					if `k_min' == . | k_min_scalar < `k_min' {
						local k_min = k_min_scalar
					}
					if `k_max' == . | k_max_scalar > `k_max' {
						local k_max = k_max_scalar
					}

					cap corr `x_f' `x_p' if `predict_set'
					mat r[`task_num',3] = r(rho)

					tempvar mae
					qui gen double `mae' = abs(`x_p' - `x_f') if `predict_set'
					qui sum `mae'
					drop `mae'
					mat r[`task_num', 4] = r(mean)
					if r(mean) < 1e-8 {
						mat r[`task_num', 4] = 0
					}

					if ("`predictionsave'" != "") & ((`crossfold' > 1) | (`task_num' == `num_tasks')) {
						cap replace `predictionsave' = `x_p' if `x_p' !=.
					}

					if "`copredictvar'" != "" {
						break mata: smap_block("``manifold''", "``co_manifold''", "`x_f'", "`co_x_p'", ///
							"`train_set'", "`co_predict_set'", `j', `lib_size', "`algorithm'", "", ///
							"`force'", `missingdistance', `idw', "`panel_id'", `current_e', ///
							`total_num_extras', `z_e_varying_count', "`z_factor_var'")

						if `k_min' == . | k_min_scalar < `k_min' {
							local k_min = k_min_scalar
						}
						if `k_max' == . | k_max_scalar > `k_max' {
							local k_max = k_max_scalar
						}

						cap corr `co_x_f' `co_x_p' if `co_predict_set'
						mat co_r[`task_num',3] = r(rho)

						tempvar mae
						qui gen double `mae' = abs(`co_x_p' - `co_x_f') if `co_predict_set'
						qui sum `mae'
						drop `mae'
						mat co_r[`task_num', 4] = r(mean)
						if r(mean) < 1e-8 {
							mat co_r[`task_num', 4] = 0
						}

						if ("`copredictionsave'" != "") & ((`crossfold' > 1) | (`task_num' == `num_tasks')) {
							cap replace `copredictionsave' = `co_x_p' if `co_x_p' !=.
						}
					}

					local ++task_num
				}
			}

			if `round' > 1 & `dot' > 0 {
				local ++finished_rep
				if mod(`finished_rep', 50*`dot') == 0 {
					di as text ". `finished_rep'"
				}
				else if mod(`finished_rep', `dot') == 0{
					di as text "." _c
				}
			}
		}

	}
	if `round' > 1 & `dot' > 0 {
		if mod(`finished_rep', 50*`dot') != 0 {
			di ""
		}
	}

	// Save the manifold back to Stata if requested.
	if `mata_mode' & "`savemanifold'" !="" {
		local counter = 1
		foreach v of varlist ``manifold'' {
			cap gen double `savemanifold'`direction_num'_`counter' = `v'
			if _rc!=0 {
				di as error "Cannot save the manifold using variable `savemanifold'`direction_num'_`counter' - is the prefix used already?"
				exit(100)
			}
			local ++counter
		}
	}

	// Collect all the asynchronous predictions from the plugin
	if !`mata_mode' {
		// Setup variables which the plugin will modify
		local k_min = .
		local k_max = .

		edmPrintPluginProgress , plugin_name(`plugin_name')
		local result_matrix = "r"
		local save_predict_mode = ("`predictionsave'" != "")
		local save_copredict_mode = ("`copredictvar'" != "")
		plugin call `plugin_name' `predictionsave' `copredictionsave', "collect_results" "`result_matrix'" "`save_predict_mode'" "`save_copredict_mode'"
	}

	if `k' <= 0 | `k_min' != `k_max' {
		if `k_min' == `k_max' {
			local cmdfootnote = "Note: Number of neighbours (k) is set to `k_min'" + char(10)
		}
		else {
			local cmdfootnote = "Note: Number of neighbours (k) is set to between `k_min' and `k_max'" + char(10)
		}
	}

	mat cfull = r[1,3]
	local cfullname= subinstr("`ori_x'",".","/",.)
	matrix colnames cfull = `cfullname'
	matrix rownames cfull = rho

	ereturn post cfull, esample(`touse')
	ereturn scalar N = `num_touse'

	ereturn local subcommand = "explore"
	ereturn local direction = "oneway"

	edmManifoldSize, e(`max_e') dt(`parsed_dt') ///
		num_extras(`z_count') num_eextras(`z_e_varying_count')
	ereturn scalar e_offset = `r(manifold_size)' - `max_e'

	ereturn scalar report_actuale = `report_actuale'
	ereturn local x "`ori_x'"
	if `crossfold' > 1 {
		ereturn local cmdfootnote "`cmdfootnote'Note: `crossfold'-fold cross validation results reported"
	}
	else {
		if "`full'" == "full" {
			ereturn local cmdfootnote "`cmdfootnote'Note: Full sample used for the computation"
		}
		else {
			if `shuffle' {
				ereturn local cmdfootnote "`cmdfootnote'Note: Random 50/50 split for training and validation data"
			}
			else {
				ereturn local cmdfootnote "`cmdfootnote'Note: 50/50 split for training and validation data"
			}
		}

	}

	ereturn matrix explore_result  = r
	if "`copredictvar'" != "" {
		ereturn matrix co_explore_result  = co_r
	}

	ereturn local algorithm "`algorithm'"
	ereturn scalar tau = `tau'
	ereturn scalar replicate = `replicate'
	ereturn scalar crossfold = `crossfold'
	ereturn scalar rep_details = "`details'" == "details"
	ereturn scalar ci = `ci'
	ereturn local copredict = "`copredictionsave'"
	ereturn local copredictvar = "`copredictvar'"
	ereturn scalar force_compute = "`force'" == "force"
	ereturn scalar panel =`ispanel'
	ereturn scalar dt =`parsed_dt'
	if `allow_missing_mode' {
		ereturn scalar missingdistance = `missingdistance'
	}
	if `parsed_dt' {
		ereturn scalar dtw =`parsed_dtw'
		ereturn local dtsave "`parsed_dtsave'"
		if "`z_names'" != "" {
			ereturn local extraembed = "`z_names' (+ time delta)"
		}
		else {
			ereturn local extraembed = "(time delta)"
		}

	}
	else {
		ereturn local extraembed = "`z_names'"
	}
	if ("`dt'" == "dt") {
		if `parsed_dt' == 0 {
			ereturn local cmdfootnote "`cmdfootnote'Note: dt option is ignored due to lack of variations in time delta"
		}
	}
	ereturn local mode = cond(`mata_mode', "mata", "`plugin_name'")
	edmDisplay
end


program define edmXmap, eclass
	syntax anything [if],  [e(integer 2)] [tau(integer 1)] [theta(real 1)] ///
		[Library(numlist)] [RANDomize] [k(integer 0)] [ALGorithm(string)] [REPlicate(integer 0)] [strict] ///
		[DIrection(string)] [seed(integer 0)] [PREDICTionsave(name)] [COPREDICTionsave(name)] [copredictvar(string)] ///
		[CI(integer 0)] [EXTRAembed(string)] [ALLOWMISSing] [MISSINGdistance(real 0)] [dt] [reldt] ///
		[DTWeight(real 0)] [DTSave(name)] [oneway] [DETails] [SAVEsmap(string)] [Predictionhorizon(string)] ///
		[dot(integer 1)] [mata] [gpu] [nthreads(integer 0)] [savemanifold(name)] [idw(real 0)] [predictwithpast] ///
		[verbosity(integer 1)] [saveinputs(string)] [lowmemory] [metrics(string)] [distance(string)] ///
		[aspectratio(real 1)] [wassdt(integer 1)]

	edmPluginCheck, `mata' `gpu'
	local mata_mode = r(mata_mode)

	if !`mata_mode' {
		if `r(gpu_mode)' {
			local plugin_name = "edm_plugin_gpu"
		}
		else {
			local plugin_name = "edm_plugin"
		}

		if `r(gpu_mode)' & "`lowmemory'" == "lowmemory" {
			di as text "Warning: Lowmemory mode currently not working with the GPU implementation."
			local lowmemory = ""
		}
	}

	local predictWithPast = ("`predictwithpast'" == "predictwithpast")
	if (`predictWithPast' & "`strict'" == "strict") {
		di as text "Warning: 'strict' is ignored when 'predictwithpast' is specified."
		local strict = ""
	}

	if ("`strict'" != "strict") {
		local force = "force"
	}

	local cmdline = "edm xmap `0'"

	if `seed' != 0 {
		set seed `seed'
	}

	if "`randomize'" == "randomize" | `replicate' > 0 {
		local shuffle = 1
	}
	else {
		local shuffle = 0
	}

	if `replicate' == 0 {
		local replicate = 1
	}

	if "`oneway'" == "oneway" {
		if !inlist("`direction'","oneway","") {
			di as error "option oneway does not match direction() option"
			error 9
		}
		else {
			local direction "oneway"
		}
	}

	if "`direction'" != "oneway" {
		if "`dtsave'" != "" {
			di as error "dtsave() option can only be used together with oneway"
			error 9
		}
		if "`predictionsave'" != "" {
			dis as error "direction() option must be set to oneway if predicted values are to be saved."
			error 197
		}
		if "`copredictionsave'" != "" {
			dis as error "direction() option must be set to oneway if copredicted values are to be saved."
			error 197
		}
	}

	if "`dtsave'" != ""{
		confirm new variable `dtsave'
	}
	if "`predictionsave'" != "" {
		confirm new variable `predictionsave'
	}
	if "`copredictionsave'" != "" {
		confirm new variable `copredictionsave'

		if "`copredictvar'" == "" {
			di as error "The copredictvar() option is not specified"
			error 111
		}
	}

	local copredictvar = strtrim("`copredictvar'")
	if "`copredictvar'" != "" & strpos("`copredictvar'", " ") {
		di as error "The copredictvar() should only specify one variable"
		error 111
	}

	// If we say 'use all neighbours', then this is implicitly using 'force' mode
	if `k' < 0 {
		if "`strict'" == "strict" {
			di as text "Warning: 'strict' is ignored when a negative 'k' is specified."
		}
		local force = "force"
	}

	* default values
	// PJL: If these are varlists then it is fine. If they are real values, we can delete these defaults
	if "`e'" == "" {
		local e = "2"
	}

	if (`e' < 1) {
		dis as error "The proposed embedding dimension E is too small."
		error 121
	}

	if (`e' > 100000) {
		dis as error "The proposed embedding dimension E is too big."
		error 121
	}

	if "`theta'" == ""{
		local theta = 1
	}

	if "`predictionhorizon'" == "" {
		local predictionhorizon = 0
	}
	else {
		local predictionhorizon = real("`predictionhorizon'")

		if `predictionhorizon' == . {
			dis as error "Require [Predictionhorizon] to either be empty or an integer"
			error 9
		}
	}

	local l_ori "`library'"
	if !inlist("`algorithm'","smap","simplex","llr","") {
		dis as error "Not valid algorithm specification"
		error 121
	}
	if "`algorithm'" == "" {
		local algorithm "simplex"
	}
	else if ("`algorithm'" == "smap"|"`algorithm'" == "llr") {
		if "`savesmap'" != "" {
			cap sum `savesmap'*
			if _rc != 111 {
				dis as error "There should be no variable with existing prefix when savesmap() option is used"
				error 110
			}
		}
	}
	if "`savesmap'" != "" & !("`algorithm'" =="smap" | "`algorithm'" =="llr") {
		dis as error "savesmap() option should only be specified with S-map"
		error 119
	}

	local allow_missing_mode = `missingdistance' != 0 | "`allowmissing'" == "allowmissing"
	if `allow_missing_mode' & "`algorithm'" == "smap" {
		dis as error "Can't use 'allowmissing' with S-map algorithm"
		error 121
	}

	if "`direction'" == ""  {
		local direction "both"
	}
	if !inlist("`direction'","both","oneway") {
		dis as error "direction() option should be either both or oneway"
		error 197
	}

	if "`distance'" == "" {
		local distance = "euclidean"
	}

	if "`metrics'" == "" {
		local metrics = "auto"
	}

	// Coprediction shouldn't be combined with multiple hyperparameters,
	// so count the number of hyperparameter combinations requested
	numlist "`e'"
	local e_size = wordcount("`=r(numlist)'")
	local max_e : word `e_size' of `e'

	numlist "`theta'"
	local theta_size = wordcount("`=r(numlist)'")

	if "`l_ori'" == "" | "`l_ori'" == "0" {
		local l_size = 1
	}
	else {
		numlist "`library'"
		local l_size = wordcount("`=r(numlist)'")
	}

	local num_tasks = `replicate' * `theta_size' * `e_size' * `l_size'

	// Allow global variables to overwrite some options.
	// This is to make it easier to change an option for all edm calls in a large do file.
	if "${EDM_VERBOSITY}" != "" {
		local verbosity = ${EDM_VERBOSITY}
	}

	if "${EDM_NTHREADS}" != "" {
		local nthreads = ${EDM_NTHREADS}
	}

	if "${EDM_DISTANCE}" != "" {
		local distance = "${EDM_DISTANCE}"
	}

	if "${EDM_METRICS}" != "" {
		local metrics = "${EDM_METRICS}"
	}

	if "${EDM_SAVE_INPUTS}" != "" {
		local saveinputs = "${EDM_SAVE_INPUTS}"
	}

	local wasserstein_mode = ("`=strlower("`distance'")'" == "wasserstein")
	local parsed_dt = ("`dt'" == "dt") | ("`reldt'" == "reldt")
	local parsed_reldt = ("`reldt'" == "reldt")
	local parsed_dtsave = "`dtsave'"

	* identify data structure
	qui xtset
	local timevar "`=r(timevar)'"
	if "`=r(panelvar)'" != "." {
		local ispanel = 1
		local panel_id = r(panelvar)
	}
	else {
		local ispanel = 0
	}

	marksample touse
	markout `touse' `timevar' `panel_id'
	sort `panel_id' `timevar'

	sum `touse', meanonly
	local num_touse = r(sum)

	* create manifold as variables
	tokenize "`anything'"

	local ori_x "`1'"
	local ori_y "`2'"
	if "`3'" != "" {
		error 103
	}

	if "`1'" == "" | "`2'" == "" {
		error 102
	}

	tempvar x y
	edmPreprocessVariable "`1'", touse(`touse') out(`x')
	edmPreprocessVariable "`2'", touse(`touse') out(`y')

	if "`copredictvar'" != "" {
		tempvar co_x
		edmPreprocessVariable "`copredictvar'", touse(`touse') out(`co_x')
	}

	edmCountExtras `extraembed'
	local z_count = `r(z_count)'
	local z_names = "`r(z_names)'"
	local z_e_varying_count = `r(z_e_varying_count)'
	local z_factor_var = "`r(z_factor_var)'"

	local z_vars = ""
	forvalues i = 1/`z_count' {
		tempvar z
		local z_vars = "`z_vars' `z'"
	}
	edmPreprocessExtras `z_names' , touse(`touse') z_vars(`z_vars')

	mat r2 = J(1, 4, .)
	if "`copredictvar'" != "" {
		mat co_r2 = J(1, 4, .)
	}

	if "`predictionsave'" != "" {
		cap gen double `predictionsave' = .
		qui label variable `predictionsave' "edm prediction result"
	}
	if "`copredictionsave'" != "" {
		qui gen double `copredictionsave' = .
		qui label variable `copredictionsave' "edm copredicted `copredictvar' using manifold `ori_x' `ori_y'"
	}

	local num_directions = 1 + ("`direction'" == "both")

	forvalues direction_num = 1/`num_directions' {
		mat r`direction_num' = J(`num_tasks', 1, `direction_num'), J(`num_tasks', 3, .)
		if "`copredictvar'" != "" {
			mat co_r`direction_num' = J(`num_tasks', 1, `direction_num'), J(`num_tasks', 3, .)
		}

		if `direction_num' == 2 {
			local swap "`x'"
			local x "`y'"
			local y "`swap'"
		}

		// To give both explore & xmap the same name for this variable:
		local round = `replicate'

		local parsed_dtw = "`dtweight'"

		if `mata_mode' & `parsed_dt' {
			// Get the column of dt values if needed for dtsave or the dtweight default
			if `parsed_dtw' == 0 | !inlist("`parsed_dtsave'","",".") {
				tempvar dt_value
				qui gen `dt_value' = .
				mata: calculate_dt("`timevar'", "`x'", "`panel_id'", `allow_missing_mode', ///
						`tau', `predictionhorizon', "", "`dt_value'")
			}

			// Calculate the default value for `dtweight'
			if `parsed_dtw' == 0 {
				qui sum `x' if `touse'
				local xsd = r(sd)
				qui sum `dt_value' if `touse'
				local tsd = r(sd)
				local parsed_dtw = `xsd'/`tsd'
				if `tsd' == 0 & !`wasserstein_mode' {
					// If there is no variance, no sampling required
					local parsed_dtw = 0
					local parsed_dt = 0
					local parsed_dtsave = ""
				}
			}
			local parsed_dtw`direction_num' = `parsed_dtw'

			if !inlist("`parsed_dtsave'","",".") {
				qui clonevar `parsed_dtsave' = `dt_value'
				qui label variable `parsed_dtsave' "Time delta (`timevar')"
			}
		}

		edmManifoldSize, e(`max_e') dt(`parsed_dt') ///
			num_extras(`z_count') num_eextras(`z_e_varying_count')
		local manifold_size = `r(manifold_size)'
		local total_num_extras = `r(total_num_extras)'

		if `mata_mode' {
			mata: construct_manifold("`touse'", "`panel_id'", "`x'", "`timevar'", "`z_vars'", "`y'", ///
				`z_count', `z_e_varying_count', `parsed_dt', `parsed_reldt', `parsed_dtw', ///
				`max_e', `tau', `predictionhorizon', `allow_missing_mode', 0)

			// Select the points which we'll use in the analysis.
			tempvar usable

			local missingdistance`direction_num' = `missingdistance'

			if `allow_missing_mode' {
				qui gen byte `usable' = 0
				foreach v of local max_e_manifold {
					qui replace `usable' = 1 if `v' !=. & `touse'
				}

				if `missingdistance' <= 0 {
					qui sum `x' if `touse'
					local defaultmissingdist = 2/sqrt(c(pi))*r(sd)
					local missingdistance`direction_num' = `defaultmissingdist'
				}
			}
			else {
				tempvar any_missing_in_manifold
				hasMissingValues `max_e_manifold', out(`any_missing_in_manifold')
				gen byte `usable' = `touse' & !`any_missing_in_manifold'
			}

			if ("`copredictvar'" != "") {
				mata: construct_manifold("`touse'", "`panel_id'", "`co_x'", "`timevar'", "`z_vars'", "`co_x'", ///
					`z_count', `z_e_varying_count', `parsed_dt', `parsed_reldt', `parsed_dtw', ///
					`max_e', `tau', `predictionhorizon', `allow_missing_mode', 1)

				// Generate the same way as `usable'.
				tempvar co_usable
				if `allow_missing_mode' {
					qui gen byte `co_usable' = 0
					foreach v of local max_e_co_manifold {
						qui replace `co_usable' = 1 if `v' !=. & `touse'
					}
				}
				else {
					tempvar any_missing_in_co_manifold
					hasMissingValues `max_e_co_manifold', out(`any_missing_in_co_manifold')
					gen byte `co_usable' = `touse' & !`any_missing_in_co_manifold'
				}

				tempvar co_predict_set
				gen byte `co_predict_set' = `co_usable'
			}
		}

		if !`mata_mode' {
			// Setup variables which the plugin will modify
			scalar plugin_finished = 0
			local missing_dist_used = .
			local dtw_used = .
			local num_usable = .

			local explore_mode = 0
			local full_mode = 0
			local crossfold = 0

			local copredict_mode = ("`copredictvar'" != "")

			if `copredict_mode' {
				local co_xvar = "`co_x'"
			}
			else {
				local co_xvar = ""
			}

			// Can't pass the c(rngstate) directly to the plugin as a function argument as it is too long.
			// Instead, just save it as a local and have the plugin read it using the Stata C API.
			local originalRNG = "`c(rng)'"
			if ("`originalRNG'" != "default") | ("`originalRNG'" != "mt64") {
				set rng mt64
			}

			local rngstate = c(rngstate)

			local low_memory_mode = "`lowmemory'" == "lowmemory"

			if "`parsed_dtsave'" != "" {
				qui gen double `parsed_dtsave' = .
			}

			local manifold_vars = ""
			if "`savemanifold'" != "" {
				forvalues ii=1/`manifold_size' {
					cap gen double `savemanifold'`direction_num'_`ii' = .
					if _rc!=0 {
						di as error "Cannot save the manifold using variable `savemanifold'`direction_num'_`ii' - is the prefix used already?"
						exit(100)
					}
					local manifold_vars = "`manifold_vars' `savemanifold'`direction_num'_`ii'"
				}
			}

			plugin call `plugin_name' `timevar' `x' `y' `z_vars' `co_xvar' `panel_id' `parsed_dtsave' `manifold_vars', "launch_edm_tasks" ///
					"`z_count'" "`parsed_dt'" "`dtweight'" "`algorithm'" "`force'" "`missingdistance'" ///
					"`nthreads'" "`verbosity'" "`num_tasks'" "`explore_mode'" "`full_mode'" "`shuffle'" "`crossfold'" "`tau'" ///
					"`max_e'" "`allow_missing_mode'" "`theta'" "`aspectratio'" "`distance'" "`metrics'" ///
					"`copredict_mode'" "`cmdline'" "`z_e_varying_count'" "`idw'" "`ispanel'" "`parsed_reldt'" "`wassdt'" ///
					"`predictionhorizon'" "`low_memory_mode'" "`predictWithPast'"

			local missingdistance`direction_num' = `missing_dist_used'

			if `parsed_dt' {
				local parsed_dtw`direction_num' = `dtw_used'
				if `dtw_used' < 0 {
					local parsed_dt = 0
				}
			}

			// Collect a list of all the variables created to store the SMAP coefficients
			// across all the 'replicate's for this xmap direction.
			local all_savesmap_vars = ""
		}

		tempvar train_set predict_set

		if `mata_mode' {
			tempvar x_p
			qui gen double `x_p' = .

			if "`copredictvar'" != "" {
				tempvar co_x_p
				qui gen double `co_x_p' = .
			}

			qui gen byte `predict_set' = `usable'
			qui gen byte `train_set' = . // to be decided by library length
		}

		tempvar u urank

		local task_num = 1
		if `replicate' > 1 & `direction_num' == 1 & `dot' > 0 {
			di "Replication progress (`=`replicate'*`num_directions'' in total)"
			local finished_rep = 0
		}

		// Set the default library size to be the number of usable observations.
		if `mata_mode' {
			sum `usable', meanonly
			local num_usable = r(sum)
		}

		if "`l_ori'" == "" | "`l_ori'" == "0" {
			local library = `num_usable'
		}

		// Also check that the the supplied library sizes are valid.
		foreach lib_size of numlist `library' {
			if `lib_size' > `num_usable' {
				di as error "Library size exceeds the limit."
				error 1
			}

			foreach i of numlist `e' {
				if `lib_size' <= `i' + 1 {
					if "`lib_size_warning'" != "" {
						di as text "Warning: library size is quite small relative to the chosen E"
					}
					local lib_size_warning = 1
					break
				}
			}
		}

		if !`mata_mode' {
			// Count how many random numbers that the plugin will have used
			local numRVs = `num_usable' * `round' * `l_size' * `shuffle'

			// Burn through them in the Stata RNG so that both streams are synchronised
			mata: burn_rvs(`numRVs')

			set rng `originalRNG'
		}

		qui gen double `u' = .

		// Setup variables which will hold the S-map coefficients if we are saving them.
		if "`savesmap'" != "" {
			forvalues rep = 1/`round' {

				local xx = "`=cond(`direction_num'==1,"`ori_x'","`ori_y'")'"
				local yy = "`=cond(`direction_num'==1,"`ori_y'","`ori_x'")'"

				qui gen double `savesmap'`direction_num'_b0_rep`rep' = .
				qui label variable `savesmap'`direction_num'_b0_rep`rep' "constant in `xx' predicting `yy' S-map equation (rep `rep')"
				local savesmap_vars "`savesmap'`direction_num'_b0_rep`rep'"

				local mapping_name "`xx'"

				forvalues ii=1/`=`e'-1' {
					local mapping_name "`mapping_name' l`=`ii'*`tau''.`xx'"
				}
				if `parsed_dt' {
					forvalues ii=0/`=`e'-1' {
						local mapping_name "`mapping_name' dt`ii'"
					}
				}

				forvalues kk=1/`z_count' {
					local z_name : word `kk' of `z_names'

					local e_varying = strpos("`z_name'", "(e)")
					if `e_varying' {
						local suffix_ind = strlen("`z_name'")-3+1
						local z_name = substr("`z_name'", 1, `suffix_ind'-1)
					}

					local mapping_name = "`mapping_name' `z_name'"
					forvalues ii=1/`=(`e_varying'>0)*(`e'-1)' {
						local lagged_z_name = "l`=`ii'*`tau''.`z_name'"
						local mapping_name = "`mapping_name' `lagged_z_name'"
					}
				}

				local ii = 1
				local label "predicting `yy' or `yy'|M(`xx') S-map coefficient (rep `rep')"
				foreach name of local mapping_name {
					qui gen double `savesmap'`direction_num'_b`ii'_rep`rep' = .
					qui label variable `savesmap'`direction_num'_b`ii'_rep`rep' "`name' `label'"
					local savesmap_vars "`savesmap_vars' `savesmap'`direction_num'_b`ii'_rep`rep'"
					local ++ii
				}
				local all_savesmap_vars`direction_num' "`all_savesmap_vars`direction_num'' `savesmap_vars'"
			}
		}


		if `mata_mode' {
			local k_min = .
			local k_max = .

			forvalues rep = 1/`round' {
				foreach i of numlist `e' {
					local manifold "mapping_`=`i'-1'"
					local co_manifold "co_mapping_`=`i'-1'"

					foreach lib_size of numlist `library' {

						cap drop `urank'
						if `shuffle' {
							qui replace `u' = runiform() if `usable'
							qui egen double `urank' = rank(`u') if `usable', unique
						}
						else {
							qui gen double `urank' = sum(`usable')
						}
						qui replace `train_set' = `urank' <= `lib_size' & `usable'
						qui replace `train_set' = 0 if `x_f' == .

						local train_size = `lib_size'

						// detect k size
						if `k' > 0 {
							local k_size = min(`k', `train_size')
						}
						else if `k' == 0 {
							edmManifoldSize, e(`i') dt(`parsed_dt') ///
								num_extras(`z_count') num_eextras(`z_e_varying_count')

							local is_smap = cond("`algorithm'" == "smap", 1, 0)
							local def_lib_size = `r(manifold_size)' + `is_smap' + 1
							local k_size = min(`def_lib_size', `train_size')
						}
						else if `k' < 0  {
							// The next line is just guessing there's only 1 point
							// with zero distance to the target, so if there's more then
							// this number will be off.
							local k_size = `lib_size' - 1
						}

						if "`savemanifold'" != "" {
							local counter = 1
							foreach v of varlist ``manifold'' {
								cap gen double `savemanifold'`direction_num'_`counter' = `v'
								if _rc!=0 {
									di as error "Cannot save the manifold using variable `savemanifold'`direction_num'_`counter' - is the prefix used already?"
									exit(100)
								}
								local ++counter
							}
						}

						foreach j of numlist `theta' {

							mat r`direction_num'[`task_num',2] = `lib_size'

							if "`copredictvar'" != "" {
								mat co_r`direction_num'[`task_num',2] = `lib_size'
							}

							break mata: smap_block("``manifold''", "", "`x_f'", "`x_p'", "`train_set'", "`predict_set'", ///
								`j', `k_size', "`algorithm'", "`savesmap_vars'", "`force'", `missingdistance`direction_num'', ///
								`idw', "`panel_id'", `max_e', `total_num_extras', `z_e_varying_count', "`z_factor_var'")

							if `k_min' == . | k_min_scalar < `k_min' {
								local k_min = k_min_scalar
							}
							if `k_max' == . | k_max_scalar > `k_max' {
								local k_max = k_max_scalar
							}

							// Ignore super tiny S-map coefficients (the plugin seems to do this)
							foreach smapvar of local savesmap_vars {
								qui replace `smapvar' = . if abs(`smapvar') < 1e-8
							}

							cap corr `x_f' `x_p' if `predict_set'
							mat r`direction_num'[`task_num',3] = r(rho)

							tempvar mae
							qui gen double `mae' = abs(`x_p' - `x_f') if `predict_set'
							qui sum `mae'
							drop `mae'
							mat r`direction_num'[`task_num', 4] = r(mean)
							if r(mean) < 1e-8 {
								mat r`direction_num'[`task_num', 4] = 0
							}

							if (`task_num' == `num_tasks' & "`predictionsave'" != "") {
								cap replace `predictionsave' = `x_p' if `x_p' != .
							}

							if "`copredictvar'" != "" {

								break mata: smap_block("``manifold''", "``co_manifold''", "`x_f'", "`co_x_p'", "`train_set'", ///
									"`co_predict_set'", `j', `k_size', "`algorithm'", "", "`force'", `missingdistance`direction_num'', ///
									`idw', "`panel_id'", `max_e', `total_num_extras', `z_e_varying_count', "`z_factor_var'")

								if `k_min' == . | k_min_scalar < `k_min' {
									local k_min = k_min_scalar
								}
								if `k_max' == . | k_max_scalar > `k_max' {
									local k_max = k_max_scalar
								}

								cap corr `co_x_f' `co_x_p' if `co_predict_set'
								mat co_r`direction_num'[`task_num',3] = r(rho)

								tempvar mae
								qui gen double `mae' = abs(`co_x_p' - `co_x_f') if `co_predict_set'
								qui sum `mae'
								drop `mae'
								mat co_r`direction_num'[`task_num', 4] = r(mean)
								if r(mean) < 1e-8 {
									mat co_r`direction_num'[`task_num', 4] = 0
								}

								if (`task_num' == `num_tasks' & "`copredictionsave'" != "") {
									cap replace `copredictionsave' = `co_x_p' if `co_x_p' != .
								}
							}

							local ++task_num
						}
					}
				}

				if `replicate' > 1 & `dot' > 0 {
					local ++finished_rep
					if mod(`finished_rep',50*`dot') == 0 {
						di as text ". `finished_rep'"
					}
					else if mod(`finished_rep',`dot') == 0 {
						di as text "." _c
					}
				}
			}
		}

		// Collect all the asynchronous predictions from the plugin
		if !`mata_mode' {
			// Setup variables which the plugin will modify
			local k_min = .
			local k_max = .

			edmPrintPluginProgress , plugin_name(`plugin_name')
			local result_matrix = "r`direction_num'"
			local save_predict_mode = ("`predictionsave'" != "")
			local save_copredict_mode = ("`copredictvar'" != "")
			plugin call `plugin_name' `predictionsave' `copredictionsave' `all_savesmap_vars`direction_num'', ///
					"collect_results" "`result_matrix'" "`save_predict_mode'" "`save_copredict_mode'"
		}

		if `k' <= 0 | `k_min' != `k_max' {
			if `k_min' == `k_max' {
				local cmdfootnote = "Note: Number of neighbours (k) is set to `k_min'" + char(10)
			}
			else {
				local cmdfootnote = "Note: Number of neighbours (k) is set to between `k_min' and `k_max'" + char(10)
			}
		}

		if ("`dt'" == "dt") {
			if `parsed_dt' == 0 {
				if "`direction'" == "oneway" {
					local cmdfootnote "`cmdfootnote'Note: dt option is ignored due to lack of variations in time delta"
				}
				else {
					local cmdfootnote "Note: dt option is ignored in at least one direction"
				}
			}
		}
	}

	if `mata_mode' & `replicate' > 1 & `dot' > 0 {
		if mod(`finished_rep', 50*`dot') != 0 {
			di ""
		}
	}

	mat cfull = (r1[1,3],r2[1,3])

	local name1 = subinstr("`ori_y'|M(`ori_x')",".","/",.)
	local name2 = subinstr("`ori_x'|M(`ori_y')",".","/",.)
	local shortened = 1
	forvalues n = 1/2 {
		if strlen("`name`n''") > 32 {
			local name`n' = substr("`name`n''",1,29) + "~`shortened'"
			local ++shortened
		}
	}
	matrix colnames cfull = `name1' `name2'
	matrix rownames cfull = rho

	if "`direction'" == "oneway" {
		mat cfull = cfull[1...,1]
	}

	ereturn post cfull, esample(`touse')
	ereturn scalar N = `num_touse'

	ereturn local subcommand = "xmap"
	ereturn matrix xmap_1 = r1
	if "`direction'" == "both" {
		ereturn matrix xmap_2 = r2
	}
	if "`copredictvar'" != "" {
		ereturn matrix co_xmap_1 = co_r1
		if "`direction'" == "both" {
			ereturn matrix co_xmap_2 = co_r2
		}
	}

	// the actual size of e should be main e + dt + extras
	ereturn scalar e_main = `e'
	edmManifoldSize, e(`e') dt(`parsed_dt') ///
		num_extras(`z_count') num_eextras(`z_e_varying_count')
	ereturn scalar e_actual = `r(manifold_size)'
	ereturn scalar e_offset = `r(manifold_size)' - `e'
	ereturn scalar theta = `theta'
	ereturn local x "`ori_x'"
	ereturn local y "`ori_y'"
	ereturn local algorithm "`algorithm'"
	ereturn local cmdfootnote "`cmdfootnote'"
	ereturn scalar tau = `tau'
	ereturn scalar replicate = `replicate'
	ereturn scalar rep_details = "`details'" == "details"
	ereturn local direction = "`direction'"
	ereturn scalar ci = `ci'
	ereturn local copredict = "`copredictionsave'"
	ereturn local copredictvar = "`copredictvar'"
	ereturn scalar force_compute = "`force'" == "force"
	ereturn local extraembed = "`extraembed'"
	ereturn scalar panel =`ispanel'
	ereturn scalar dt =`parsed_dt'
	if `allow_missing_mode' {
		ereturn scalar missingdistance = `missingdistance1'
		ereturn scalar missingdistance1 = `missingdistance1'
		if "`direction'" == "both" {
			ereturn scalar missingdistance2 = `missingdistance2'
		}
	}
	if `parsed_dt' {
		ereturn scalar dtw =`parsed_dtw1'
		ereturn scalar dtw1 =`parsed_dtw1'
		if "`direction'" == "both" {
			ereturn scalar dtw2 =`parsed_dtw2'
		}
		ereturn local dtsave "`parsed_dtsave'"
		if "`z_names'" != "" {
			ereturn local extraembed = "`z_names' (+ time delta)"
		}
		else {
			ereturn local extraembed = "(time delta)"
		}
	}
	else {
		ereturn local extraembed = "`z_names'"
	}
	ereturn local mode = cond(`mata_mode', "mata", "`plugin_name'")
	edmDisplay
end

program define edmDisplayHeader, eclass
	display _n "Empirical Dynamic Modelling"

	if e(subcommand) =="explore" {
		if !inlist("`=e(extraembed)'","",".") {
			di as text "Multivariate mapping with `=e(x)' and its lag values"
		}
		else {
			di as text "Univariate mapping with `=e(x)' and its lag values"
		}

		if !inlist("`=e(extraembed)'","",".") {
			di as text "Additional variable" _c
			di cond(wordcount("`=e(extraembed)'")>1,"s","") _c
			di " in the embedding: `=e(extraembed)'"
		}
		if e(missingdistance)>0 & e(missingdistance)!= .{
			di as text "Missing values are assumed to have a distance of " _c
			di `:di %8.2g `=e(missingdistance)'' _c
			di " with all values."
		}
	}
	else if e(subcommand) == "xmap" {
		di as txt "Convergent Cross-mapping result for variables {bf:`=e(x)'} and {bf:`=e(y)'}"
		if !inlist("`=e(extraembed)'","",".") {
			di as text "Additional variable" _c
			di cond(wordcount("`=e(extraembed)'")>1,"s","") _c
			di " in the embedding: `=e(extraembed)'"
		}
		if e(missingdistance)>0 & e(missingdistance)!= . {
			di as text "Missing values are assumed to have a distance of " _c

			if `=e(missingdistance1)' != `=e(missingdistance2)' & `=e(missingdistance1)' !=. & e(direction) != "oneway" {
				di `:di %8.2g `=e(missingdistance1)'' _c
				di " and " _c
				di `:di %8.2g `=e(missingdistance2)''
			}
			else {
				di `:di %8.2g `=e(missingdistance)'' _c
				di " with all values."
			}
		}
	}

end

program define edmDisplayFooter, eclass

	if e(subcommand) =="explore" {
		if ((e(replicate) == 1 & e(crossfold) <=0) | e(rep_details) == 1) {
		}
		else {
			di as text "Note: Results from `=max(`=e(replicate)',`=e(crossfold)')' runs"
		}
		if e(e_offset) != 0 {
			di as text "Note: Actual E is higher than the specified E due to extras"
		}
		di as text ustrtrim(e(cmdfootnote))
	}
	else if e(subcommand) == "xmap" {
		if (e(replicate) == 1 | e(rep_details) == 1) {
			* the case of no replication
		}
		else {
			* the case of replication
			di as text "Note: Results from `=e(replicate)' replications"
		}

		if "`=e(cmdfootnote)'" != "." {
			di as text ustrtrim(e(cmdfootnote))
		}
		di as txt "Note: The embedding dimension E is `=e(e_actual)'" _c

		if e(e_main) != e(e_actual) {
			di " (including `=e(e_offset)' extra`=cond(e(e_offset)>1,"s","")')"
		}
		else {
			di ""
		}
	}

	if `=e(force_compute)' == 1 {
		//di as txt "Note: -force- option is specified. The estimate may not be derived from the specified k."
	}
	if `=e(dt)' == 1 {
		di as txt "Note: Embedding includes the delta of the time variable with a weight of " _c
		if `=e(dtw1)' != `=e(dtw2)' & `=e(dtw2)' !=. & e(direction) !="oneway" {
			di `:di %8.2g `=e(dtw1)'' _c
			di " and " _c
			di `:di %8.2g `=e(dtw2)''
		}
		else {
			di `:di %8.2g `=e(dtw)''
		}
	}
end

program define edmDisplayCI, rclass
	syntax ,  mat(name) ci(integer) [maxr(integer 2)]
	quietly {
		noi di as result %18s "Est. mean `ci'% CI" _c

		if `maxr' == 1 {
			noi di as result %17s " " _c
		}
		local datasize = r(N)
		tempname varbuffer
		/* noi mat list `mat' */
		svmat `mat',names(`varbuffer'_ci`ci'_)

		local type1 "rho"
		local type2 "mae"

		forvalues j=1/`maxr' {
			cap ci `varbuffer'_ci`ci'_`j', level(`ci')
			if _rc !=0 {
				cap ci means `varbuffer'_ci`ci'_`j', level(`ci')
			}
			return scalar lb_mean_`type`j'' = `=r(lb)'
			return scalar ub_mean_`type`j'' = `=r(ub)'

			noi di as result "   [" _c

			/* noi di as result  %9.5g  `=`matmean'[1,`j']-invnormal(1-(100-`ci')/200)*`matsd'[1,`j']/sqrt(`rep')' _c */
			noi di as result  %9.5g  `=r(lb)' _c
			noi di as result ", " _c

			/* noi di as result  %9.5g  `=`matmean'[1,`j']+invnormal(1-(100-`ci')/200)*`matsd'[1,`j']/sqrt(`rep')' _c */
			noi di as result  %9.5g  `=r(ub)' _c
			noi di as result " ]" _c
		}
		noi qui count
		local datasize = r(N)

		noi di ""
		noi di as result %18s "`=(100-`ci')/2'/`=100 - (100-`ci')/2' Pc (Est.)" _c
		forvalues j=1/`maxr' {
			if `maxr' == 1 {
				noi di as result %17s " " _c
			}
			qui sum `varbuffer'_ci`ci'_`j'
			noi di as result "   [" _c
			noi di as result %9.5g `=r(mean)-invnormal(1-(100-`ci')/200)*r(sd)' _c
			return scalar lb_pce_`type`j'' = `=r(mean)-invnormal(1-(100-`ci')/200)*r(sd)'
			noi di as result ", " _c
			noi di as result %9.5g `=r(mean)+invnormal(1-(100-`ci')/200)*r(sd)' _c
			return scalar ub_pce_`type`j'' = `=r(mean)+invnormal(1-(100-`ci')/200)*r(sd)'
			noi di as result " ]" _c
		}

		noi di ""
		noi di as result %18s "`=(100-`ci')/2'/`=100 - (100-`ci')/2' Pc (Obs.)" _c
		forvalues j=1/`maxr' {

			if `maxr' == 1 {
				noi di as result %17s " " _c
			}
			_pctile `varbuffer'_ci`ci'_`j', percentile(`=(100-`ci')/2' `=100 - (100-`ci')/2' )
			noi di as result "   [" _c
			noi di as result %9.5g `=r(r1)' _c
			return scalar lb_pco_`type`j'' = `=r(r1)'
			noi di as result ", " _c
			noi di as result %9.5g `=r(r2)' _c
			return scalar ub_pco_`type`j'' = `=r(r2)'
			noi di as result " ]" _c
			drop `varbuffer'_ci`ci'_`j'
		}

		cap drop `varbuffer'_ci`ci'_*
		qui keep if _n<=`datasize'
		noi di ""
	}
end


program define edmDisplayTable, eclass
	syntax ,  result_matrix(name)

	local diopts "`options'"
	local fmt "%12.5g"
	local fmtprop "%8.3f"
	local ci_counter = 1
	if e(subcommand) =="explore" {
		if ((e(replicate) == 1 & e(crossfold) <=0) | e(rep_details) == 1) {
			di as txt "{hline 68}"
			display as text %18s cond(e(report_actuale)==1,"Actual E","E")  _c
			display as text %16s "theta"  _c
			display as text %16s "rho"  _c
			display as text %16s "MAE"
			di as txt "{hline 68}"

			mat r = e(`result_matrix')
			local nr = rowsof(r)
			local kr = colsof(r)
			forvalues i = 1/ `nr' {
				forvalues j=1/`kr' {
					if `j'==1 {
						local dformat "%18s"
					}
					else {
						local dformat "%16s"
					}
					display as result `dformat' `"`:display `fmt' r[`i',`j'] '"' _c
				}
				display " "
			}
			di as txt "{hline 68}"
		}
		else {
			di as txt "{hline 70}"
			di as text %22s " " _c
			di as txt "{hline 9} rho {hline 9}  " _c
			di as txt "{hline 9} MAE {hline 9}"
			/* di as txt "{hline 70}" */
			display as text %9s cond(e(report_actuale)==1,"Actual E","E")  _c
			display as text %9s "theta"  _c
			display as text %13s "Mean"  _c
			display as text %13s "Std. Dev."  _c
			display as text %13s "Mean"  _c
			display as text %13s "Std. Dev."
			di as txt "{hline 70}"
			local dformat "%13s"

			// process the return matrix
			tempname reported_r r buffer summary_r
			mat `r' = e(`result_matrix')
			local nr = rowsof(`r')
			local kr = colsof(`r')
			mat `reported_r' = J(`nr',1,0)
			mat `summary_r' = J(1,6,.)

			forvalues i = 1/ `nr' {
				mat `buffer' = J(1,2,.)
				if `reported_r'[`i',1] == 1 {
					continue
				}
				local base_E = `r'[`i',1]
				local base_theta = `r'[`i',2]
				forvalues j=1/`nr' {
					if `reported_r'[`j',1] ==0 {
						if `r'[`j',1] == `base_E' & `r'[`j',2] == `base_theta' {
							mat `buffer' = (`buffer'\ `=`r'[`j',3]',`=`r'[`j',4]')
							mat `reported_r'[`j',1] =1
						}
					}
				}

				// now get the mean and st
				tempname mat_mean mat_sd
				mata: st_matrix("`mat_sd'", diagonal(sqrt(variance(st_matrix("`buffer'"))))')

				/* if changes to standard error */
				/* mata: st_matrix("`mat_sd'", diagonal(sqrt(variance(st_matrix("`buffer'"))))/sqrt(`nr')') */
				mata: st_matrix("`mat_mean'", mean(st_matrix("`buffer'")))

				di as result %9s  `"`: display %9.0g `r'[`i',1] '"' _c
				di as result %9s  `"`: display %9.5g `r'[`i',2] '"' _c
				forvalues j=1/2{
					display as result `dformat' `"`:display `fmt' `mat_mean'[1,`j'] '"' _c
					display as result `dformat' `"`:display `fmt' `mat_sd'[1,`j'] '"' _c
				}
				mat `summary_r' = (`summary_r'\ `=`r'[`i',1]',`=`r'[`i',2]', `=`mat_mean'[1,1]',`=`mat_sd'[1,1]', `=`mat_mean'[1,2]',`=`mat_sd'[1,2]')

				di ""
				if `=e(ci)'>0 & `=e(ci)'<100 {
					edmDisplayCI , mat(`buffer') ci(`=e(ci)')
					local type1 "rho"
					local type2 "mae"
					forvalues j=1/2 {
						foreach t_type in "lb_mean" "ub_mean" "lb_pco" "ub_pco" "lb_pce" "ub_pce" {
							ereturn scalar `t_type'_`type`j''`ci_counter' =r(`t_type'_`type`j'')
						}
					}
					local ++ci_counter
				}
			}
			mat `summary_r'=`summary_r'[2...,.]
			ereturn matrix summary = `summary_r'
			di as txt "{hline 70}"
		}
	}
	else if e(subcommand) == "xmap" {
		local direction1 = "`=e(y)' ~ `=e(y)'|M(`=e(x)')"
		local direction2 = "`=e(x)' ~ `=e(x)'|M(`=e(y)')"
		forvalues i=1/2{
			if strlen("`direction`i''")>26 {
				local direction`i' = substr("`direction`i''",1,24) + ".."
			}
		}
		local mapp_col_length = min(28, max(strlen("`direction1'"), strlen("`direction2'")) +3)
		local line_length = 50 + `mapp_col_length'
		if (e(replicate) == 1 | e(rep_details) == 1) {
			* the case of no replication
			di as txt "{hline `line_length'}"
			display as text %`mapp_col_length's "Mapping"  _c
			display as text %16s "Library size"  _c
			display as text %16s "rho"  _c
			display as text %16s "MAE"
			di as txt "{hline `line_length'}"
			local num_directions = 1 + (e(direction) == "both")
			forvalues direction_num = 1/`num_directions' {
				if `direction_num' == 1 {
					mat r = e(`result_matrix'_1)
				}
				else {
					mat r = e(`result_matrix'_2)
				}

				local nr = rowsof(r)
				local kr = colsof(r)

				forvalues i = 1/ `nr' {

					forvalues j=1/`kr' {
						if `j' == 1 {
							display as result %`mapp_col_length's "`direction`=r[`i',`j']''" _c
						}
						else {
							display as result %16s `"`:display `fmt' r[`i',`j'] '"' _c
						}
					}
					display " "
				}
			}

			di as txt "{hline `line_length'}"
		}
		else {
			* the case of replication
			di as txt "{hline `line_length'}"
			display as text %`mapp_col_length's "Mapping"  _c
			display as text %16s "Lib size"  _c
			display as text %16s "Mean rho"  _c
			display as text %16s "Std. Dev."
			di as txt "{hline `line_length'}"
			local dformat "%16s"

			// process the return matrix
			tempname reported_r r buffer summary_r

			forvalues direction_num = 1/2 {
				if `direction_num' == 1 {
					mat `r' = e(`result_matrix'_1)
				}
				else {
					mat `r' = e(`result_matrix'_2)
					if e(direction) =="oneway" {
						continue, break
					}
				}

				local nr = rowsof(`r')
				local kr = colsof(`r')
				mat `reported_r' = J(`nr',1,0)

				mat `summary_r' = J(1,6,.)

				forvalues i = 1/ `nr' {
					mat `buffer' = J(1,2,.)
					if `reported_r'[`i',1] == 1 {
						continue
					}
					local base_direction = `r'[`i',1]
					local base_L = `r'[`i',2]
					forvalues j=1/`nr' {
						if `reported_r'[`j',1] ==0 {
							if `r'[`j',1] == `base_direction' & `r'[`j',2] == `base_L' {
								mat `buffer' = (`buffer'\ `=`r'[`j',3]',`=`r'[`j',4]')
								mat `reported_r'[`j',1] =1
							}
						}
					}
					// now get the mean and st
					tempname mat_mean mat_sd

					mata: st_matrix("`mat_sd'", diagonal(sqrt(variance(st_matrix("`buffer'"))))')
					mata: st_matrix("`mat_mean'", mean(st_matrix("`buffer'")))

					di as result %`mapp_col_length's "`direction`base_direction''" _c
					di as result `dformat' `"`: display `fmt' `r'[`i',2] '"' _c
					forvalues j=1/1{
						display as result `dformat' `"`:display `fmt' `mat_mean'[1,`j'] '"' _c
						display as result `dformat' `"`:display `fmt' `mat_sd'[1,`j'] '"' _c
					}
					mat `summary_r' = (`summary_r'\ `=`r'[`i',1]',`=`r'[`i',2]', `=`mat_mean'[1,1]',`=`mat_sd'[1,1]', `=`mat_mean'[1,2]',`=`mat_sd'[1,2]')
					/* mat list `summary_r' */
					display ""
					if `=e(ci)'>0 & `=e(ci)'<100 {
						edmDisplayCI , mat(`buffer') ci(`=e(ci)') maxr(1)
						local type1 "rho"
						local type2 "mae"
						forvalues j=1/1 {
							foreach t_type in "lb_mean" "ub_mean" "lb_pco" "ub_pco" "lb_pce" "ub_pce" {
								ereturn scalar `t_type'_`type`j''`ci_counter' =r(`t_type'_`type`j'')
							}
						}
						local ++ci_counter
					}
				}
			}
			mat `summary_r'=`summary_r'[2...,.]
			ereturn matrix summary = `summary_r'
			di as txt "{hline `line_length'}"
		}
	}
end

program define edmDisplay, eclass
	edmDisplayHeader
	if e(subcommand) == "explore" {
		edmDisplayTable , result_matrix(explore_result)

		if("`e(copredictvar)'" != "") {
			display _n "Copredictions"
			edmDisplayTable , result_matrix(co_explore_result)
		}
	}
	if e(subcommand) == "xmap" {
		edmDisplayTable , result_matrix(xmap)

		if("`e(copredictvar)'" != "") {
			display _n "Copredictions"
			edmDisplayTable , result_matrix(co_xmap)
		}
	}
	edmDisplayFooter
end


capture mata mata drop burn_rvs()
mata:
mata set matastrict on
void burn_rvs(real scalar num)
{
	(void) runiform(1, num)
}
end

capture mata mata drop observation_numbers()
mata:
mata set matastrict on
real matrix observation_numbers(real matrix t, real matrix x,
		real scalar allow_missing_mode, real scalar dtMode)
{
	real matrix obsNum, tScaled

	real scalar obs, n, i
	obs = 0
	n = rows(t)

	obsNum = J(n, 1, .)

	if (dtMode) {
		for(i=1; i<=n; i++) {
			if (t[i] != . && (allow_missing_mode || x[i] != .)) {
				obsNum[i] = obs
				obs = obs + 1
			}
			else {
				obsNum[i] = .
			}
		}
	}
	else {
		real matrix dt
		real scalar minDT

		dt = t[2..rows(t)] :- t[1..rows(t)-1]
		minDT = min(dt)

		tScaled = (t :- min(t)) :/ minDT

		for(i = 1; i <= n; i++) {
			if (t[i] != .) {
				obsNum[i] = round(tScaled[i])
			}
			else {
				obsNum[i] = .
			}
		}
	}
	return(obsNum)
}
end

capture mata mata drop find_obs_num()
mata:
mata set matastrict on
real scalar find_obs_num(real matrix obsNum, real scalar target, real scalar start,
		real scalar direction, real scalar panelMode, real matrix panel)
{
	real scalar i, nobs

	i = start
	nobs = rows(obsNum)

	while (i >= 1 && i <= nobs) {
		if (panelMode) {
			if (panel[i] != panel[start]) {
				return(.)
			}
		}

		if (obsNum[i] == target) {
			return(i)
		}

		i = i + direction;
	}

	return(.)
}
end

capture mata mata drop calculate_dt()
mata:
mata set matastrict on
void calculate_dt(
		string scalar timeVar, string scalar xVar, string scalar panelVar,
		real scalar allow_missing_mode, real scalar tau, real scalar p,
		string scalar dt0Var, string scalar dtValueVar)
{
	real matrix t, x, obsNum, panel, dt, dt0
	real scalar panelMode

	st_view(t, ., timeVar, .)
	st_view(x, ., xVar, .)

	obsNum = observation_numbers(t, x, allow_missing_mode, 1)

	if (panelVar != "") {
		panelMode = 1
		st_view(panel, ., panelVar, .)
	}
	else {
		panelMode = 0
		panel = .
	}

	if (dt0Var != "") {
		st_view(dt0, ., dt0Var, .)
	}
	st_view(dt, ., dtValueVar, .)

	real scalar n, i, ii
	n = rows(t)

	for(i=1 ; i <= n; i++) {
		if (obsNum[i] == .) {
			if (dt0Var != "") {
				dt0[i] = .
			}
			dt[i] = .
			continue
		}

		/* Go forward by 'p' to find the time of the corresponding target. */
		ii = find_obs_num(obsNum, obsNum[i] + p, i, p / abs(p), panelMode, panel)

		if (dt0Var != "") {
			if (ii != .) {
				dt0[i] = t[ii] - t[i]
			}
			else {
				dt0[i] = .
			}
		}

		/* For all other 'dt', we go backward to find the distance between
		 * this observation and the tau-previous one. */
		ii = find_obs_num(obsNum, obsNum[i] - tau, i, -tau / abs(tau), panelMode, panel)

		if (ii != .) {
			dt[i] = t[i] - t[ii]
		}
		else {
			dt[i] = .
		}
	}
}
end


capture mata mata drop construct_manifold()
mata:
mata set matastrict on
void construct_manifold(
		string scalar touse, string scalar panelVar,
		string scalar xVar, string scalar timeVar, string scalar zStr, string scalar target,
		real scalar numExtras, numEExtras, real scalar dtMode, real scalar reldt, real scalar dtw,
		real scalar E, real scalar tau, real scalar p,
		real scalar allow_missing_mode, real scalar copredict_mode)
{

	string rowvector zVarsSplit
	real scalar numUnlaggedExtras

	zStr = strtrim(zStr)
	zVarsSplit = tokens(zStr)

	numUnlaggedExtras = numExtras - numEExtras

	real scalar k
	real matrix t, x, obsNum, panel, zVars, yTS
	real scalar panelMode

	st_view(t, ., timeVar, touse)
	st_view(x, ., xVar, touse)
	st_view(zVars, ., zVarsSplit, touse)
	st_view(yTS, ., target, touse)

	obsNum = observation_numbers(t, x, allow_missing_mode, dtMode)

	if (panelVar != "") {
		panelMode = 1
		st_view(panel, ., panelVar, touse)
	}
	else {
		panelMode = 0
		panel = .
	}

	/* Create temporary variables to hold the manifold, and
	 * create matrix views to be able to populate the variables. */
	string rowvector xLagNames, dtLagNames, eextraLagNames, extraNames
	real matrix xLags, dtLags, eextraLags, extras

	xLagNames = st_tempname(E)
	st_view(xLags, ., st_addvar("double", xLagNames), touse)

	dtLagNames = st_tempname(dtMode * E)
	st_view(dtLags, ., st_addvar("double", dtLagNames), touse)

	eextraLagNames = st_tempname(numEExtras * E)
	st_view(eextraLags, ., st_addvar("double", eextraLagNames), touse)

	extraNames = st_tempname(numUnlaggedExtras)
	st_view(extras, ., st_addvar("double", extraNames), touse)

	/* Start generating the manifold point-by-point. */
	real scalar n, i, targetInd, j, col
	n = rows(t)

	string scalar yName
	real matrix y

	yName = st_tempname()
	st_view(y, ., st_addvar("double", yName), touse)
	y[.] = J(n, 1, .)

	real rowvector laggedIndices
	real scalar tNowInd, tNextInd

	for(i = 1; i <= n; i++) {
		if (obsNum[i] == .) {
			continue
		}

		/* Go forward by 'p' to find the time of the corresponding target. */
		targetInd = find_obs_num(obsNum, obsNum[i] + p, i, p / abs(p), panelMode, panel)
		if (targetInd != .) {
			y[i] = yTS[targetInd]
		}

		laggedIndices = J(1, E, .)

		for(j = 1; j <= E; j++) {
			laggedIndices[j] = find_obs_num(obsNum, obsNum[i] - (j-1)*tau, i, -1, panelMode, panel)
		}

		for(j = 1; j <= E; j++) {
			if (laggedIndices[j] != .) {
				xLags[i, j] = x[laggedIndices[j]]
			}
		}

		for(j = 1; j <= dtMode * E; j++) {
			if (j == 1 || reldt) {
				tNowInd = laggedIndices[j];

				if (targetInd != . && tNowInd != .) {
					dtLags[i, j] = dtw * (t[targetInd] - t[tNowInd])
				}
				else {
					dtLags[i, j] = .
				}
			}
			else {
				/* For all other 'dt', we go backward to find the distance between
				 * this observation and the tau-previous one. */
				tNextInd = laggedIndices[j - 1];
			    tNowInd = laggedIndices[j];

				if (tNextInd != . && tNowInd != .) {
					dtLags[i, j] = dtw * (t[tNextInd] - t[tNowInd])
				}
				else {
					dtLags[i, j] = .
				}
			}
		}

		col = 0
		for (k = 1; k <= numEExtras; k++) {
			for(j = 1; j <= E; j++) {
				if (laggedIndices[j] != .) {
					eextraLags[i, col + j] = zVars[laggedIndices[j], k]
				}
			}
			col = col + E
		}

		for (k = 1; k <= numUnlaggedExtras; k++) {
			extras[i, k] = zVars[i, numEExtras + k]
		}
	}

	/* Put the manifolds together */
	string scalar mani, maniName
	real scalar sE

	for(i = 1; i <= E-1; i++) {
		sE = i + 1

		mani = invtokens(xLagNames[1..sE])

		if (dtMode) {
			mani = mani + " " + invtokens(dtLagNames[1..sE])
		}

		col = 0
		for (k = 0; k < numEExtras; k++) {
			mani = mani + " " + invtokens(eextraLagNames[col+1..col+sE])
			col = col + E
		}

		if (numUnlaggedExtras > 0) {
			mani = mani + " " + invtokens(extraNames)
		}

		if (!copredict_mode) {
			maniName = sprintf("mapping_%f", i)
			st_local(maniName, mani)
		}
		else {
			maniName = sprintf("co_mapping_%f", i)
			st_local(maniName, mani)
		}
	}


	if (!copredict_mode) {
		st_local("max_e_manifold", mani)
		st_local("x_f", yName)
	}
	else {
		st_local("max_e_co_manifold", mani)
		st_local("co_x_f", yName)
	}
}
end

capture mata mata drop smap_block()
mata:
mata set matastrict on
void smap_block(
		string scalar manifold, string scalar p_manifold,
		string scalar prediction, string scalar result,
		string scalar train_use, string scalar predict_use,
		real scalar theta, real scalar l, string scalar algorithm,
		string scalar saveSMAPCoeffs, string scalar force,
		real scalar missingdistance, real scalar idw,
		string scalar panel_id, real scalar E, real scalar total_num_extras,
		real scalar z_e_varying_count, string scalar z_factor_var)
{
	real scalar force_compute, k, i
	force_compute = force == "force" /* check whether we need to force the computation if k is too high */
	real matrix M, Mp, y, ystar, train_panel_ids, predict_panel_ids
	st_view(M, ., tokens(manifold), train_use) /* base manifold */
	st_view(y, ., prediction, train_use) /* known prediction of the base manifold */
	st_view(ystar, ., result, predict_use)

	if (idw != 0) {
		st_view(train_panel_ids, ., panel_id, train_use)
		st_view(predict_panel_ids, ., panel_id, predict_use)
	}

	if (p_manifold != "") {
		/* data used for prediction is different than the source manifold */
		st_view(Mp, ., tokens(p_manifold), predict_use)
	}
	else {
		st_view(Mp, ., tokens(manifold), predict_use)
	}

	if (l <= 0) { /* default value of local library size */
		k = cols(M)
		l = k + 1 /* local library size (E+1) + itself */
	}

	string matrix zFactors
	real scalar zFactorsSize
	if (z_factor_var != "") {
		zFactors = tokens(z_factor_var)
		zFactorsSize = cols(zFactors)
	}
	else {
		zFactorsSize = 0
	}

	real scalar num_x_and_dt
	num_x_and_dt = cols(M) - total_num_extras

	real matrix factorVars
	factorVars = J(1, cols(M), 0)

	real scalar ind, numLags
	ind = num_x_and_dt + 1

	for (i = 1; i <= zFactorsSize; i++) {
		if (i <= z_e_varying_count) {
			numLags = E
		}
		else {
			numLags = 1
		}

		for (j = 1; j <= numLags; j++) {
			factorVars[ind] = (zFactors[i] == "1")
			ind = ind + 1
		}
	}

	real scalar savingSMAPCoeffs
	savingSMAPCoeffs = (saveSMAPCoeffs != "")

	real matrix smapCoeffs
	if (savingSMAPCoeffs) {
		st_view(smapCoeffs, ., tokens(saveSMAPCoeffs), predict_use)
	}

	real scalar n
	n = rows(Mp)

	real rowvector b
	real scalar targetPanel

	real scalar kMin, kMax

	for(i = 1; i <= n; i++) {
		b = Mp[i,.]
		if (idw != 0) {
			targetPanel = predict_panel_ids[i]
		}
		else {
			targetPanel = .
		}
		ystar[i] = make_prediction(i, M, b, y, l, theta, algorithm,
				savingSMAPCoeffs, smapCoeffs, force_compute,
				missingdistance, idw, train_panel_ids,
				targetPanel, factorVars, k)

		if (i == 1 || k < kMin) {
			kMin = k
		}
		if (i == 1 || k > kMax) {
			kMax = k
		}
	}

	st_numscalar("k_min_scalar", kMin)
	st_numscalar("k_max_scalar", kMax)
}
end


capture mata mata drop make_prediction()
mata:
mata set matastrict on
real scalar make_prediction(
		real scalar Mp_i, real matrix M, real rowvector b, real colvector y,
		real scalar l, real scalar theta, string scalar algorithm,
		real scalar savingSMAPCoeffs, real matrix smapCoeffs,
		real scalar force, real scalar missingdistance, real scalar idw,
		real matrix panel_ids, real scalar targetPanel, real matrix factorVars,
		real scalar k)
{
	/* M : manifold matrix
	 * b : the vector used for prediction
	 * y: existing predicted value for M (same number of rows with M)
	 * l : library size
	 * theta: exponential weighting parameter
	*/

	real colvector d, w, a
	real colvector ind, v
	real scalar i, j, n, r
	n = rows(M)
	d = J(1, n, .)

	for(i = 1; i <= n; i++) {
		a = M[i,.] - b

		for (j = 1; j <= cols(a); j++) {
			if (factorVars[j]) {
				a[j] = M[i,j] != b[j]
			}
		}

		if (missingdistance != 0) {
			a = editvalue(a,. , missingdistance)
		}

		/* d is (temporarily) the squared Euclidean distance */
		d[i] = (a*a')

		/* If we have panel data, penalise the points if they
		 * come from different panels */
		if (idw != 0) {
			if (panel_ids[i] != targetPanel) {
				if (idw < 0) {
					d[i] = .
				}
				else {
					d[i] = d[i] + idw
				}
			}
		}

		/* Now d is the Euclidean distance */
		d[i] = d[i]^(1/2)

		if (d[i] == 0) {
			d[i] = .
		}
	}

	/* This is important to copy 'l' into 'k', otherwise we may
	 * accidently 'force' l to be too small for future predictions. */
	k = l

	minindex(d, k, ind, v)

	if (rows(ind) < k) {
		if (force) {
			k = rows(ind) /* Force k to use fewer neighbours */
		}
		else {
			sprintf("Insufficient number of unique observations, consider tweaking the values of E or k")
			exit(error(503))
		}
	}

	/* We need at least k=1 to continue.
	 * For example, 'force' may reduce k to 0. */
	if (k < 1) {
		/* Normally we just let the prediction be '.' and silently keep going. */
		if (force) {
			return(.)
		}
		else {
			/* We should never be able to end up here, but just in case.. */
			sprintf("Cannot make predictions using k=0 neighbours.")
			exit(error(503))
		}
	}

	/* Find the smallest non-zero distance */
	real scalar d_base
	d_base = d[ind[1]]

	w = J(k, 1, .)

	r = 0

	if (algorithm == "" | algorithm == "simplex") {
		for(j = 1; j <= k; j++) {
			w[j] = exp(-theta*(d[ind[j]] / d_base))
		}
		w = w / sum(w)

		for(j = 1; j <= k; j++) {
			r = r + y[ind[j]] * w[j]
		}

		return(r)
	}
	else if (algorithm == "smap" | algorithm == "llr") {

		real colvector y_ls, b_ls, w_ls
		real matrix X_ls, XpXi
		real rowvector x_pred
		real scalar mean_d

		for(j = 1; j <= k; j++) {
			w[j] = d[ind[j]]
		}

		mean_d = mean(w)

		for(j = 1; j <= k; j++) {
			w[j] = exp(-theta*(w[j] / mean_d))
		}

		y_ls = J(k, 1, .)
		X_ls = J(k, cols(M), .)
		w_ls = J(k, 1, .)

		real scalar rowc
		rowc = 0

		for(j = 1; j <= k; j++) {
			rowc++
			if (algorithm == "llr") {
				y_ls[rowc] = y[ind[j]]
				X_ls[rowc, .] = M[ind[j], .]
				w_ls[rowc] = w[j]
			}
			else if (algorithm =="smap") {
				y_ls[rowc] = y[ind[j]] * w[j]
				X_ls[rowc, .] = M[ind[j], .] * w[j]
				w_ls[rowc] = w[j]
			}
		}
		if (rowc == 0) {
			return(.)
		}

		y_ls = y_ls[1..rowc]
		X_ls = X_ls[1..rowc,.]
		w_ls = w_ls[1..rowc]

		n_ls = rows(X_ls)

		/* Add a (weighted) column of ones to represent the constant */
		X_ls = w_ls, X_ls

		if (algorithm == "llr") {
			XpXi = quadcross(X_ls, w_ls, X_ls)
			XpXi = invsym(XpXi)
			b_ls = XpXi * quadcross(X_ls, w_ls, y_ls)
		}
		else {
			b_ls = svsolve(X_ls' * X_ls, X_ls' * y_ls)
		}

		if (savingSMAPCoeffs) {
			smapCoeffs[Mp_i, .] = editvalue(b_ls', 0, .)
		}

		x_pred = 1, editvalue(b, ., 0)

		r = x_pred * b_ls

		return(r)
	}
}
end

// Load the C++ implementation
cap program edm_plugin, plugin using(edm.plugin)

// Load the C++/GPU implementation
cap program edm_plugin_gpu, plugin using(edm_gpu.plugin)
