*! didintjl_plot 0.0.4 June 14th 2026
/*------------------------------------*/
/*didintjl_plot*/
/*written by Eric Jamieson */
/*version 0.0.4 2026-14-06 */
/*------------------------------------*/

cap program drop didintjl_plot
program define didintjl_plot
    version 16
    syntax, outcome(varname) state(varname) time(varname) ///
            [gvar(varname) ///
            treated_states(string) treatment_times(string) date_format(string) /// 
            covariates(string) ccc(string) weights(int 1) ref_column(string) ref_group(string) ///
            freq(string) freq_multiplier(int 1) start_date(string) end_date(string) ///
            hc(int 1) event(int 0) ci(real 0.95) groupmin(int 3) window(numlist min=2 max=2) process(int 1)]

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

    // Pass hc, event, and ci args to julia
    qui jl: hc = `hc'
    qui jl: ci = `ci'
    if `event' == 1 {
        qui jl: event = true
    }
    else if `event' == 0 {
        qui jl: event = false
    }
    else {
        di as error "'event' must be either 1 (True) or 0 (False)."
    }

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
        qui jl: treated_times = String[]
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
        local ccc "all"
        qui jl: ccc = "all"
    } 
    else {
        qui jl: ccc = String[]
        tokenize "`ccc'"
        while "`1'" != "" {
            local token = trim("`1'")
            if ("`token'" != "") {
                qui jl: temp = "`token'"
                qui jl: push!(ccc, temp)
            }
            macro shift
        }
    }

    if `weights' == 0 {
        qui jl: weights = false
    }
    else if `weights' == 1 {
        qui jl: weights = true
    }
    else {
        di as err "Set 'weights' to either 0 (False) or 1 (True)."
        exit 4
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

    // PART TWO: Run didint_plot in Julia
	jl: plot_data = DiDInt.didint_plot(outcome, state, time, df, gvar = gvar, treated_states = treated_states, treatment_times = treated_times, date_format = date_format, covariates = covariates, ref = ref, ccc = ccc, event = event, weights = weights, ci = ci, freq = freq, freq_multiplier = freq_multiplier, start_date = start_date, end_date = end_date, hc = hc);
	if `event' == 0 {
        // Get treatment periods from data
        qui jl: treat_period = string.(collect(skipmissing(plot_data[!, "treat_period"])))
        qui jl: st_local("treat_periods", join(string.(treat_period), " "))
        qui jl: n_treat = length(collect(treat_period))
        qui jl: plot_data = plot_data[1:(end-n_treat), Not(:treat_period)]
    }

    // PART THREE: PASS RESULTS TO STATA
    tempname result_frame
    qui cap frame drop `result_frame'
    qui frame create `result_frame'
    qui frame change `result_frame'
    qui jl use plot_data 

    // PART FOUR: Make plots
    if `event' == 0 {
        // Create a mapping of period to time labels
        bysort period: gen first = _n == 1

        // Apply window filter if specified
        if "`window'" != "" {
            tokenize `window'
            local period_start `1'
            local period_end `2'

            qui keep if period >= `period_start' & period <= `period_end'

            // Filter treat_periods (these are already period numbers from Julia)
            local filtered_treat_periods ""
            qui levelsof period, local(existing_periods)
            foreach t of local treat_periods {
                local found = 0
                foreach p of local existing_periods {
                    if `t' == `p' {
                        local found = 1
                        continue, break
                    }
                }
                if `found' == 1 {
                    local filtered_treat_periods "`filtered_treat_periods' `t'"
                }
            }
            local treat_periods "`filtered_treat_periods'"
        }

        // Determine x-axis frequency (every 2nd period)
        local xfreq = 2

        // Build xlabel string with every xfreq periods
        local xlabel_sparse
        qui levelsof period if first, local(all_periods)
        foreach p of local all_periods {
            if mod(`p', `xfreq') == 0 {
                qui levelsof time if period == `p' & first, local(tm) clean
                local xlabel_sparse `"`xlabel_sparse' `p' "`tm'""'
            }
        }

        // Check if grc1leg2 is available
        local use_grc1leg2 = 1
        capture which grc1leg2
        if _rc != 0 {
            local use_grc1leg2 = 0
            local yspacing = 7
            local final_ncols = 3
            local final_nrows = 2
        }
        else {
            local yspacing = 1
            local final_ncols = 3
            local final_nrows = 2
        }

        // Get list of unique states and ccc (specifications) for later use
        qui levelsof state, local(state_list)
        local n_states : word count `state_list'
        local ncols = min(5, max(2, ceil(`n_states'/10)))

        qui levelsof ccc, local(ccc_list)
        local n_specs : word count `ccc_list'

        // Create numeric versions for reshape
        qui encode state, gen(state_num)
        qui encode ccc, gen(ccc_num)

        // Drop string and temporary variables before reshape
        qui drop state ccc first time start_date period_length

        // Reshape to have one column per state
        qui reshape wide lambda, i(ccc_num period) j(state_num)
        // Define colors for plotting
        local colours "navy maroon forest_green orange purple dkorange teal cranberry ebblue emerald brown erose gold lavender lime ltblue magenta mint olive olive_teal pink red sand sandb sienna stone yellow bluishgray emidblue eltgreen gs6 gs10"
        local n_colours : word count `colours'
        // Create plots for each specification (ccc)
        local graph_names ""
        local spec_counter = 1
        foreach spec_name of local ccc_list {
            // Build the twoway plot command dynamically
            local plot_cmd ""
            forvalues st = 1/`n_states' {
                local colour_index = mod(`st' - 1, `n_colours') + 1
    			local colour : word `colour_index' of `colours'
                if `st' > 1 local plot_cmd "`plot_cmd' ||"
                local plot_cmd `"`plot_cmd' (connected lambda`st' period if ccc_num == `spec_counter', lcolor(`colour') mcolor(`colour'))"'
            }
            // Build legend order dynamically
            local legend_order ""
            local counter = 1
            foreach state_name of local state_list {
                local legend_order `"`legend_order' `counter' "`state_name'""'
                local counter = `counter' + 1
            }

        // Build xline option if treatment periods exist
        if "`treat_periods'" != "" {
            local xline_option "xline(`treat_periods', lcolor(gray) lpattern(dash) lwidth(medium))"
        }
        else {
            local xline_option ""
        }

        // Execute the plot with ccc name as title
        twoway `plot_cmd' ///
               , title("`spec_name'") ///
               `xline_option' ///
               legend(order(`legend_order') cols(`ncols') size(small) ///
                      symxsize(3) colgap(9) region(lcolor(black))) ///
               ytitle("`outcome'", margin(r=`yspacing')) ///
               ylabel(, angle(0) labsize(small)) ///
               xtitle("Time") ///
               xlabel(`xlabel_sparse', angle(0) labsize(small)) ///
               name(spec`spec_counter', replace) nodraw

                    local graph_names `graph_names' spec`spec_counter'
                    local spec_counter = `spec_counter' + 1
                }

        // Combine graphs
        if `use_grc1leg2' == 1 {
            grc1leg2 `graph_names', ///
                rows(`final_nrows') cols(`final_ncols') ///
                title("Parallel Trends", justification(center)) ///
                legendfrom(spec1) ///
                position(6) ///
                name(by_spec, replace)
        }
        else {
            graph combine `graph_names', ///
                rows(`final_nrows') cols(`final_ncols') ///
                title("Parallel Trends", justification(center)) ///
                name(by_spec, replace)
        }
    }
    else if `event' == 1 {
        // Convert string columns to numeric
        qui destring y, replace
        qui destring se, replace
        qui destring ci_lower, replace
        qui destring ci_upper, replace
        qui destring time_since_treatment, replace
        qui destring ngroup, replace
    
        // Apply event window filter if specified
        if "`window'" != "" {
            tokenize `window'
            local event_start `1'
            local event_end `2'
            qui keep if time_since_treatment >= `event_start' & time_since_treatment <= `event_end'
        }
    
        // Apply groupmin rule to hide CI when too few groups
        qui count if ngroup < `groupmin'
        if r(N) > 0 {
            qui replace se = . if ngroup < `groupmin'
            qui replace ci_lower = . if ngroup < `groupmin'
            qui replace ci_upper = . if ngroup < `groupmin'
        }
    
        // Get period length for subtitle
        local period_length = period_length[1]
        local display_ci = `ci' * 100

        // Get list of unique ccc specifications
        qui levelsof ccc, local(ccc_list)
        local n_specs : word count `ccc_list'

        // Encode ccc for plotting
        qui encode ccc, gen(ccc_num)

        // Create plots for each specification
        local graph_names ""
        local spec_counter = 1
    
        foreach spec_name of local ccc_list {
            twoway (rarea ci_upper ci_lower time_since_treatment if ccc_num == `spec_counter', ///
                         color(ltblue%60) lwidth(none)) ///
                   (line y time_since_treatment if ccc_num == `spec_counter', ///
                         lcolor(navy) lwidth(medthick) lpattern(solid)) ///
                   (scatter y time_since_treatment if ccc_num == `spec_counter' & !missing(se), ///
                         mcolor(navy) msize(small) msymbol(circle)) ///
                   (scatter y time_since_treatment if ccc_num == `spec_counter' & missing(se), ///
                         mcolor(navy) msize(small) msymbol(square)), ///
                   xline(0, lcolor(gray) lpattern(dot) lwidth(thick)) ///
                   yline(0, lcolor(black) lpattern(solid) lwidth(thin)) ///
                   xlabel(, grid glcolor(gs14) glwidth(vthin)) ///
                   ylabel(, grid glcolor(gs14) glwidth(vthin)) ///
                   legend(order(2 "Point Estimate" 1 "`display_ci'% CI") ///
                          position(6) ring(1) rows(1) ///
                          symxsize(5) keygap(2) colgap(8) size(small) ///
                          region(lcolor(none) fcolor(none))) ///
                   xtitle("Periods Relative to Treatment", size(medsmall)) ///
                   ytitle("`outcome'", size(medsmall) margin(r=5)) ///
                   title("`spec_name'", size(medium) color(black)) ///
                   graphregion(color(white) lcolor(black) margin(l=3 r=3)) ///
                   plotregion(lcolor(black) lwidth(thin) margin(l=3 r=3)) ///
                   scheme(s1mono) ///
                   name(event_spec`spec_counter', replace) nodraw
    
            local graph_names `graph_names' event_spec`spec_counter'
            local spec_counter = `spec_counter' + 1
        }
    
        // Determine layout based on number of specs
        if `n_specs' <= 3 {
            local final_nrows = 1
            local final_ncols = `n_specs'
        }
        else if `n_specs' <= 6 {
            local final_nrows = 2
            local final_ncols = 3
        }
        else {
            local final_nrows = 3
            local final_ncols = 3
        }
    
        // Combine graphs
        graph combine `graph_names', ///
            rows(`final_nrows') cols(`final_ncols') ///
            title("Event Study: `outcome'", justification(center) size(medium)) ///
            subtitle("Period Length: `period_length'", size(small)) ///
            name(event_study, replace) ///
            graphregion(color(white))
    }
    
    qui drop _all
	qui frame change default
    qui frame drop `result_frame'
	qui jl: plot_data = nothing; GC.gc()
end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
* 0.0.4 - suggest user have DiDInt.jl version v0.9.6 or later (as opposed to only 0.9.5)
* 0.0.3 - changed default hc value to 1 (from 3)
* 0.0.2 - Got everything working with Julia v1.11.7, julia.ado v1.2.2 & DiDInt.jl v0.6.15
* 0.0.1 - created function