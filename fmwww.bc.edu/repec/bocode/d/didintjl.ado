*! didintjl 0.7.8 June 14th 2026
/*------------------------------------*/
/*didintjl*/
/*written by Eric Jamieson */
/*version 0.7.8 2026-14-07 */
/*------------------------------------*/

cap program drop didintjl
program define didintjl, rclass
    version 16
    syntax, outcome(varname) state(varname) time(varname) ///
            [gvar(varname) ///
            treated_states(string) treatment_times(string) date_format(string) /// 
            covariates(string) ccc(string) agg(string) weighting(string) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) start_date(string) end_date(string) ///
            nperm(int 999) seed(int 0) use_pre_controls(int 0) notyet(int -1) hc(int 1) truejack(int 0) edgecase(int 0) process(int 1)]

	// PART ONE: BASIC SETUP 
    qui cap which jl
    if _rc {
        di as error "The 'julia' package is required but not installed or not found in the system path. See https://github.com/droodman/julia.ado for more details."
        exit 3
    } 

    // Check process
    if `process' != 0 & `process' != 1 {
        di as error "process must be either 1 (true) or 0 (false)."
        exit 42
    }

    // Check seed value 
    if `seed' == 0 {
        qui jl: seed = abs(round(randn(1)[1]*10000))
    }
    else {
        qui jl: seed = `seed'
    }

    // Check truejack
    if `truejack' == 0 {
        qui jl: truejack = false
    }
    else if `truejack' == 1 {
        qui jl: truejack = true
    }
    else {
        di as error "truejack must be either 1 (true) or 0 (false)."
    }

    // Check edgecase
    if `edgecase' == 0 {
        qui jl: edgecase = false
    }
    else if `edgecase' == 1 {
        qui jl: edgecase = true
    }
    else {
        di as error "edgecase must be either 1 (true) or 0 (false)."
    }

    // notyet arg
    if `notyet' >= 0 {
        if `notyet' != 0 & `notyet' != 1 {
            di as error "'notyet' must be either 1 (true) or 0 (false)."
        }
        `use_pre_controls' = `notyet'
    }

    // Check use_pre_controls arg
    if `use_pre_controls' == 1 {
        qui jl: use_pre_controls = true
    }
    else if `use_pre_controls' == 0 {
        qui jl: use_pre_controls = false
    }
    else {
        di as error "use_pre_controls must be 0 (False) or 1 (True) (Default)"
        exit 43
    }

    // Pass hc arg to julia
    qui jl: hc = `hc'

    // Check date_format
    if "`date_format'" == "" {
        qui jl: date_format = nothing
    }
    else {
        qui jl: date_format = "`date_format'"
    }

    // Check that DiDInt.jl v0.9.6 or later is installed
    tempname DiDIntOK
    qui jl: using Pkg
    qui jl: _didint_pkgs = filter(p -> p.second.name == "DiDInt", Pkg.dependencies())
    qui jl: _didint_ok = !isempty(_didint_pkgs) && first(values(_didint_pkgs)).version >= v"0.9.6"
    qui jl: SF_scal_save("`DiDIntOK'", _didint_ok ? 1.0 : 0.0)
    if `DiDIntOK' != 1 {
        di as error "DiDInt.jl v0.9.6 or later is required but not found."
        di as error "Please install or update DiDInt.jl by running: jl AddPkg DiDInt"
        exit 44
    }
    qui jl: using DiDInt


    // This section is to deal with the invalid warnings and to ensure proper conversion of categorical variables
    local allvars `outcome' `state' `time'
    if "`covariates'" != "" {
        local allvars `allvars' `covariates'
    }
    if "`gvar'" != "" {
        local allvars `allvars' `gvar'
    }
    preserve
    keep `allvars'
    if `process' == 1 {
        local outlabel : value label `outcome'
        if "`outlabel'" != "" {
            quietly label values `outcome' .
            di as text "Warning: `outcome' has a value label. Label stripped to ensure numeric outcome. Set 'process(0)' to skip this conversion."
        }
        foreach v of local covariates {
            local vallabel : value label `v'
            if "`vallabel'" != "" {
                quietly decode `v', gen(`v'_decoded)
                quietly destring `v'_decoded, gen(`v'_test) ignore(",")
                quietly count if missing(`v'_test) & !missing(`v')
                if r(N) == 0 {
                    local converted 1
                    // Truly numeric - just strip label
                    drop `v'_decoded `v'_test
                    quietly label values `v' .
                    di as text "Warning: `v' has a value label but contains numeric data. Value label stripped, variable passed as numeric. Set 'process(0)' to skip this conversion."
                }
                else {
                    // Real categorical - replace with decoded string
                    drop `v' `v'_test
                    rename `v'_decoded `v'
                    di as text "Warning: `v' has a value label and contains non-numeric data. Variable converted from numeric to string. Set 'process(0)' to skip this conversion."
                }
            }
        }
        qui label drop _all
        qui notes drop _all
    }
    qui jl save df
    restore

    // Allow some variables to be passed to Julia 
    qui jl: outcome = Symbol("`outcome'")
    qui jl: state = Symbol("`state'")
    qui jl: time = Symbol("`time'")
    qui jl: nperm = `nperm'
    qui jl: freq_multiplier = `freq_multiplier'
    if "`gvar'" != "" {
        qui jl: gvar = Symbol("`gvar'")
    }
    else {
        qui jl: gvar = nothing
    }

    if "`freq'" == "" {
        qui jl: freq = nothing
    }
    else {
        qui jl: freq = "`freq'"
    }

    if "`start_date'" == "" {
        qui jl: start_date = nothing
    }
    else {
        qui jl: start_date = "`start_date'"
    }
    if "`end_date'" == "" {
        qui jl: end_date = nothing
    }
    else {
        qui jl: end_date = "`end_date'"
    }

    // Parse treated_states and treatment_times
    if "`treated_states'" != "" {
        qui jl: treated_states = String[]
        qui jl: treated_times = String[]
        qui tokenize "`treated_states'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(treated_states, temp)
            }
            macro shift
        }
    }
    else {
        qui jl: treated_states = nothing
    }

    if "`treatment_times'" != "" {
        qui tokenize "`treatment_times'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(treated_times, temp)
            }
            macro shift
        }
    }
    else {
        qui jl: treated_times = nothing
    }

    // Parse covariates if necessary
    if "`covariates'" == ""{
        qui jl: covariates = nothing
    }
    else {
        qui jl: covariates = String[]
        tokenize "`covariates'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(covariates, temp)
            }
            macro shift
        }
    }

    if "`ccc'" == "" {
        local ccc "int"
        qui jl: ccc = "int"
    } 
    else {
        qui jl: ccc = "`ccc'"
    }
    
    if "`agg'" == "" {
        qui jl: agg = "cohort"
    } 
    else {
        qui jl: agg = "`agg'"
    }

    if "`weighting'" == "" {
        local weighting "both"
        qui jl: weighting = "both"
    } 
    else {
        qui jl: weighting = "`weighting'"
    }
 
    // Parse ref_column tokens with trimming
    if "`ref_column'" != "" {
        qui jl: ref_keys = String[]
        tokenize "`ref_column'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(ref_keys, temp)
            }
            macro shift
        }
        if "`ref_group'" == "" {
            di as error "If ref_column is specified, then ref_group must be specified as well!"
            exit 6
        }
    }

    // Parse ref_group tokens with trimming
    if "`ref_group'" != "" {
        qui jl: ref_values = String[]
        tokenize "`ref_group'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(ref_values, temp)
            }
            macro shift
        }
        if "`ref_column'" == "" {
            di as error "If ref_group is specified, then ref_column must be specified as well!"
            exit 7
        }
        qui jl: ref = Dict(zip(ref_keys, ref_values))
    }

    if "`ref_column'" == "" & "`ref_group'" == "" {
        qui jl: ref = nothing
    }
	
	// PART TWO: RUN DiDInt.jl and convert some columns to strings
    jl: results = DiDInt.didint(outcome, state, time, df, gvar = gvar, treated_states = treated_states, treatment_times = treated_times, date_format = date_format, covariates = covariates, ccc = ccc, agg = agg, weighting = weighting, ref = ref, freq = freq, freq_multiplier = freq_multiplier, start_date = start_date, end_date = end_date, nperm = nperm, seed = seed, use_pre_controls = use_pre_controls, hc = hc, truejack = truejack, edgecase = edgecase);
	
    qui jl: if "att_cohort" in DataFrames.names(results) ///
                results.labels = string.(results.treatment_time); ///
            elseif "att_s" in DataFrames.names(results) ///
                results.labels = string.(results.state); ///
            elseif "att_gt" in DataFrames.names(results) ///
                results.labels = string.(results.gvar, ";", results.time); ///
            elseif "att_sgt" in DataFrames.names(results) ///
                results.labels = string.(results.state, ";", results.gvar, ";", results.t); ///
            elseif "att_t" in DataFrames.names(results) ///
                results.labels = string.(results.periods_post_treat); ///
            end

	// PART THREE: PASS RESULTS TO STATA
	tempname result_frame
    qui cap frame drop `result_frame'
    qui frame create `result_frame'
    qui frame change `result_frame'
    qui jl use results

    qui cap confirm variable labels
	if !_rc {
		qui jl: st_local("rowlabels", join(string.(results.labels), " "))
		qui tostring labels, replace
		local counter = 1
		foreach rowlabel in `rowlabels' {
			qui replace labels = "`rowlabel'" in `counter'
			local counter = `counter' + 1
		}
	}

    qui ds 
    qui local result_vars `r(varlist)'
    foreach var in `result_vars' {
        tempvar tmp_`var' 
        qui gen `tmp_`var'' = `var'
        qui drop `var'
    }




	local condition_met 0

	qui capture confirm variable `tmp_att_s'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "                                DiDInt.jl Sub-Aggregate Results                                      "
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "State                     | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_labels'[`i']'" as text " |" as result %-16.7f `tmp_att_s'[`i'] as text " | " as result  %-7.3f `tmp_se_att_s'[`i'] as text "| " as result %-7.3f `tmp_pval_att_s'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_s'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_s'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_s'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the state name
            local state_name = `tmp_labels'[`i']
            local state_names `state_names' `state_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_s'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_s'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_s'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_s'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_s'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_s'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `state_names'
        
        // Store the matrix in r()
        return matrix didint = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: " as result "State"
	}
	
    qui capture confirm variable `tmp_att_cohort'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "                                DiDInt.jl Sub-Aggregate Results                                      "
        di as text "-----------------------------------------------------------------------------------------------------"
		di as text "Cohort                    | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local cohort_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_labels'[`i']'" as text " |" as result %-16.7f `tmp_att_cohort'[`i'] as text " | " as result  %-7.3f `tmp_se_att_cohort'[`i'] as text "| " as result %-7.3f `tmp_pval_att_cohort'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_cohort'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_cohort'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_cohort'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the cohort name
            local cohort_name = `tmp_labels'[`i']
            local cohort_names `cohort_names' `cohort_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_cohort'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_cohort'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_cohort'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_cohort'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_cohort'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_cohort'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `cohort_names'
        
        // Store the matrix in r()
        return matrix didint = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: " as result "Cohort"
	}

    qui capture confirm variable `tmp_att_sgt'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "                                DiDInt.jl Sub-Aggregate Results                                      "		
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "s;g;t                       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local state_names ""

        // Create the gt varialbe in julia
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_labels'[`i']'" as text " |" as result %-16.7f `tmp_att_sgt'[`i'] as text " | " as result  %-7.3f `tmp_se_att_sgt'[`i'] as text "| " as result %-7.3f `tmp_pval_att_sgt'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_sgt'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_sgt'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_sgt'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the gt
            local sgt_name = `tmp_labels'[`i']
            local sgt_names `sgt_names' `sgt_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_sgt'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_sgt'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_sgt'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_sgt'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_sgt'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_sgt'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `sgt_names'
        
        // Store the matrix in r()
        return matrix didint = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: " as result "sgt"
	}

    qui capture confirm variable `tmp_att_gt'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "                                DiDInt.jl Sub-Aggregate Results                                      "
	    di as text "-----------------------------------------------------------------------------------------------------"
        di as text "g;t                       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)

        // Create the gt varialbe in julia
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_labels'[`i']'" as text " |" as result %-16.7f `tmp_att_gt'[`i'] as text " | " as result  %-7.3f `tmp_se_att_gt'[`i'] as text "| " as result %-7.3f `tmp_pval_att_gt'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_gt'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_gt'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_gt'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the gt
            local gt_name = `tmp_labels'[`i']
            local gt_names `gt_names' `gt_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_gt'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_gt'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_gt'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_gt'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_gt'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_gt'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `gt_names'
        
        // Store the matrix in r()
        return matrix didint = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: " as result "Simple"
	}

    qui capture confirm variable `tmp_att_t'
	if _rc == 0 & `condition_met' == 0 {
		local condition_met 1
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "                                DiDInt.jl Sub-Aggregate Results                                      "		
		di as text "-----------------------------------------------------------------------------------------------------"
        di as text "Periods Since Treatment   | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		// Initialize a temporary matrix to store the numeric results
        tempname table_matrix
        local num_rows = _N
        local num_cols = 7
        matrix `table_matrix' = J(`num_rows', `num_cols', .)
		local time_names ""
		
		forvalues i = 1/`=_N' {
			di as text %-25s "`=`tmp_labels'[`i']'" as text " |" as result %-16.7f `tmp_att_t'[`i'] as text " | " as result  %-7.3f `tmp_se_att_t'[`i'] as text "| " as result %-7.3f `tmp_pval_att_t'[`i'] as text "| " as result  %-11.3f `tmp_jknifese_att_t'[`i'] as text "| " as result %-13.3f `tmp_jknifepval_att_t'[`i'] as text "|" as result %-9.3f `tmp_ri_pval_att_t'[`i'] as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
			
			// Store the state name
            local time_name = `tmp_labels'[`i']
            local time_names `time_names' `time_name'
            
            // Fill the matrix with numeric values
            matrix `table_matrix'[`i', 1] = `tmp_att_t'[`i']
            matrix `table_matrix'[`i', 2] = `tmp_se_att_t'[`i']
            matrix `table_matrix'[`i', 3] = `tmp_pval_att_t'[`i']
            matrix `table_matrix'[`i', 4] = `tmp_jknifese_att_t'[`i']
            matrix `table_matrix'[`i', 5] = `tmp_jknifepval_att_t'[`i']
            matrix `table_matrix'[`i', 6] = `tmp_ri_pval_att_t'[`i']
            matrix `table_matrix'[`i', 7] = `tmp_weights'[`i']
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the state names
        matrix rownames `table_matrix' = `state_names'
        
        // Store the matrix in r()
        return matrix didint = `table_matrix'
        
		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
		di as text _n "Aggregation Method: " as result "Periods Since Treatment"
	}

    if "`ccc'" == "int" {
        local model_spec "Two-way DID-INT"
    }
    else if "`ccc'" == "state" {
        local model_spec "State-varying DID-INT"
    }
    else if "`ccc'" == "time" {
        local model_spec "Time-varying DID-INT"
    }
    else if "`ccc'" == "hom" {
        local model_spec "Homogeneous DID-INT"
    }
    else if "`ccc'" == "add" {
        local model_spec "Two one-way DID-INT"
    }
    
    di as text "Model Specification: " as result "`model_spec'"
    di as text "Weighting: " as result "`weighting'"
       
       // Display aggregate results
       di as text _n "---------------------------------"
       di as text "   DiDInt.jl: Aggregate Results   "
       di as text "---------------------------------"
       di as text "Aggregate ATT: " as result `tmp_agg_att'[1]
       di as text "Standard error: " as result `tmp_se_agg_att'[1]
       di as text "p-value: " as result `tmp_pval_agg_att'[1]
       di as text "Jackknife SE: " as result `tmp_jknifese_agg_att'[1]
       di as text "Jackknife p-value: " as result `tmp_jknifepval_agg_att'[1]
       di as text "RI p-value: " as result `tmp_ri_pval_agg_att'[1]
       di as text "Random permutations: " as result `tmp_nperm'[1]
	   
	// Store aggregate results in r()
    return scalar att = `tmp_agg_att'[1]
    return scalar se = `tmp_se_agg_att'[1]
    return scalar p = `tmp_pval_agg_att'[1]
    return scalar jkse = `tmp_jknifese_agg_att'[1]
    return scalar jkp = `tmp_jknifepval_agg_att'[1]
    return scalar rip = `tmp_ri_pval_agg_att'[1]
    return scalar nperm = `tmp_nperm'[1]
    
	qui drop _all
	qui frame change default
    qui frame drop `result_frame'
	qui jl: results = nothing; GC.gc()
	
end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*0.7.8 - suggest user have DiDInt.jl version v0.9.6 or later (as opposed to only 0.9.5)
*0.7.7 - No longer automatically download DiDInt, instead suggest user download explicitly via 'jl AddPkg DiDInt'
*0.7.6 - Added arg for edgecase, made sure value labels are dropped for outcome
*0.7.5 - Added better processing for labelled variables
*0.7.4 - better error messaging
*0.7.3 - added arg for truejack
*0.7.2 - added hc arg and changed nperm to 999
*0.7.1 - run didint() from Julia with ; ending, shows error messages, but suppresses other displays. Clear results from Julia memory after running
*0.7.0 - updated output display, changed return matrix name from restab to didint
*0.6.1 - forgot a qui smh
*0.6.0 - changed syntax to accept varnames, added gvar option, overall more in line with csdid and Stata norms
*0.5.3 - changed the way that the results row labels are passed to Stata from Julia to try and work around a Stata-Julia interface bug
*0.5.2 - fixed assignment issue with start_date / end_date
*0.5.1 - changed use_pre_controls default to false
*0.5.0 - added start_date and end_date args and removed autoadjust to conincide with new version of DiDInt.jl package
*0.4.1 - added weighting arg
*0.4.0 - added sgt agg option, RI_pvals for sub-aggregate level, and seed arg
*0.3.0 - changed to rclass and added displays for outputs
*0.2.1 - removed 'stata_debug' arg, hopefully not needed anymore
*0.2.0 - fixed 'freq' arg - function actually works now for common + staggered adoption
*0.1.2 - added 'stata_debug' arg and trim whitespce for tokenized args
*0.1.1 - added 'agg' arg
*0.1.0 - created function
