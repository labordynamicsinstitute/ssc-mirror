/*------------------------------------*/
/*undid_plot*/
/*written by Eric Jamieson */
/*version 1.1.0 2025-09-30 */
/*------------------------------------*/
cap program drop undid_plot
program define undid_plot
    version 16
    syntax, dir_path(string) /// 
            [plot(string) weights(int 1) covariates(int 0) omit_silos(string) include_silos(string) ///
            treated_colours(string) control_colours(string) ci(real 0.95) event_window(numlist min=2 max=2)]

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------- PART ONE: Basic Input Checks ------------------------------ // 
    // ---------------------------------------------------------------------------------------- //

    if "`plot'" == "" {
        local plot "agg"
    }
    if !inlist("`plot'", "agg", "dis", "event", "silo") {
        di as error "'plot' must be set to one of: 'agg', 'dis', 'event', or 'silo'."
        exit 2
    }

    if !inlist(`weights', 0, 1) {
        di as error "'weights' must be set to either 1 (true) or 0 (false)."
        exit 3
    }

    if !inlist(`covariates', 0, 1)  {
        di as error "'covariates' must be set to either 1 (true) or 0 (false)."
        exit 4
    }

    if `ci' < 0 | `ci' >= 1 {
        di as error "'ci' must be between 0 and 1."
        exit 11
    }

    if "`event_window'" != "" {
        tokenize `event_window'
        local event_start `1'
        local event_end `2'
    }

    local files : dir "`dir_path'" files "trends_data_*.csv"
    local nfiles : word count `files'
    if `nfiles' == 0 {
        display as error "No trends_data_*.csv files found in `dir_path'"
        exit 5
    }

    if "`plot'" == "dis" & `weights' == 1 {
        di as error "If 'plot' is set to to 'dis' (disaggregate), then weights are not applied."
        di as error "Overwriting 'weights' to 0."
        local weights = 0
    }


    // ---------------------------------------------------------------------------------------- //
    // -------------------------------- PART TWO: Read In Data -------------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    // Read in data
    tempfile master
    local first = 1
    qui tempname temploadframe
    qui cap frame drop `temploadframe'  
    qui frame create `temploadframe'
    qui frame change `temploadframe'
    foreach f of local files {
        local fn = "`dir_path'/`f'"
        qui import delimited using "`fn'", clear stringcols(_all) case(preserve)

        if `first' {
            qui save "`master'", replace
            local first = 0
        }
        else {
            qui append using "`master'"
            qui save "`master'", replace
        }
    }
    qui use "`master'", clear

    // Omit or restrict based on omit_silos and include_silos options
    local omit_toggled = 0
    local include_toggled = 0
    if "`omit_silos'" != "" {
        local nsilo_omit : list sizeof omit_silos
        local omit_toggled = 1
    }
    if "`include_silos'" != "" {
        local nsilo_include : list sizeof include_silos
        local include_toggled = 1
    }
    if `include_toggled' == 1 & `omit_toggled' == 1 {
        local overlap : list omit_silos & include_silos
        if "`overlap'" != "" {
            di as error "The following silos appear in both 'omit_silos' and 'include_silos': `overlap'"
            exit 6
        }
    }
    qui levelsof silo_name, local(data_silos) clean
    if `omit_toggled' == 1 {
        local missing_omit ""
        foreach omit_silo of local omit_silos {
            local found = 0
            foreach data_silo of local data_silos {
                local clean_data_silo = subinstr(`"`data_silo'"', `"""', "", .)
                if "`omit_silo'" == "`clean_data_silo'" {
                    local found = 1
                    continue, break
                }
            }
            if `found' == 0 {
                local missing_omit "`missing_omit' `omit_silo'"
            }
        }
        if "`missing_omit'" != "" {
            di as error "The following silos in 'omit_silos' do not exist in the data: `missing_omit'"
            di as error "Available silos in data: `data_silos'"
            exit 7
        }
    }
    if `include_toggled' == 1 {
        local missing_include ""
        foreach include_silo of local include_silos {
            local found = 0
            foreach data_silo of local data_silos {
                local clean_data_silo = subinstr(`"`data_silo'"', `"""', "", .)
                if "`include_silo'" == "`clean_data_silo'" {
                    local found = 1
                    continue, break
                }
            }
            if `found' == 0 {
                local missing_include "`missing_include' `include_silo'"
            }
        }
        if "`missing_include'" != "" {
            di as error "The following silos in 'include_silos' do not exist in the data: `missing_include'"
            di as error "Available silos in data: `data_silos'"
            exit 8
        }
    }
    if `include_toggled' == 1 {
        local keep_condition ""
        foreach include_silo of local include_silos {
            if "`keep_condition'" == "" {
                local keep_condition `"silo_name == "`include_silo'""'
            }
            else {
                local keep_condition `"`keep_condition' | silo_name == "`include_silo'""'
            }
        }
        qui keep if `keep_condition'
    }
    if `omit_toggled' == 1 {
        local drop_condition ""
        foreach omit_silo of local omit_silos {
            if "`drop_condition'" == "" {
                local drop_condition `"silo_name != "`omit_silo'""'
            }
            else {
                local drop_condition `"`drop_condition' & silo_name != "`omit_silo'""'
            }
        }
        qui keep if `drop_condition'
    }

    // Convert string date information to numeric 
    local date_format = date_format[1]
    local period_length = freq[1]
    qui _parse_string_to_date, varname(time) date_format("`date_format'") newvar(t)

    // Additional processing for event plot
    if "`plot'" == "event" {
        qui keep if treatment_time != "control"
        qui _parse_string_to_date, varname(treatment_time) date_format("`date_format'") newvar(gvar_date)
        qui gen double event_time = .
        qui gen freq_n = real(word(freq, 1))
        qui gen freq_unit = lower(word(freq, 2))
        if substr(freq_unit, 1, 3) == "yea" {
            qui replace event_time = floor((year(t) - year(gvar_date)) / freq_n)
        }
        else if substr(freq_unit, 1, 3) == "mon" {
            qui replace event_time = floor((ym(year(t),  month(t)) - ym(year(gvar_date), month(gvar_date))) / freq_n)
        }
        else if substr(freq_unit, 1, 3) == "wee" {
            qui replace event_time = floor((t - gvar_date) / (7 * freq_n))
        }
        else if substr(freq_unit, 1, 3) == "day" { 
            qui replace event_time = floor((t - gvar_date) / freq_n)
        }
        qui drop freq_n
        qui drop freq_unit
    }
    else {
        qui gen treated = (treatment_time != "control")
        preserve
            qui keep if treatment_time != "control"
            qui _parse_string_to_date, varname(treatment_time) date_format("`date_format'") newvar(gvar_date)
            qui levelsof gvar_date, local(treatment_times) clean
        restore
    }

    // Select mean_outcome or mean_outcome_residualized based on covariates option
    if `covariates' == 0 {
        qui count if mean_outcome == "NA" | mean_outcome == "missing" | mean_outcome == ""
        if r(N) > 0 {
            di as error "Found silos with missing values for mean_outcome. Dropping those observations:"
            list silo_name time if mean_outcome == "NA" | mean_outcome == "missing" | mean_outcome == ""
            qui drop if mean_outcome == "NA" | mean_outcome == "missing" | mean_outcome == ""
        }
        qui gen double y =  real(mean_outcome)
    }
    else if `covariates' == 1 {
        qui count if  mean_outcome_residualized == "" | mean_outcome_residualized == "NA" | mean_outcome_residualized == "missing"
        if r(N) > 0 {
            di as error "Found silos with missing values for mean_outcome_residualized. Dropping those observations:"
            list silo_name time if mean_outcome_residualized == "" | mean_outcome_residualized == "NA" | mean_outcome_residualized == "missing"
            qui drop if mean_outcome_residualized == "" | mean_outcome_residualized == "NA" | mean_outcome_residualized == "missing"
        }
        qui gen double y = real(mean_outcome_residualized)
    }
    qui format y %20.15g

    if `weights' == 1 {
        qui replace n = "" if n == "NA" | n == "missing"
        qui destring n, replace
        qui count if missing(n)
        if r(N) > 0 {
            qui levelsof silo_name if missing(n), local(missing_silos) clean
            di as error "Error: Missing values of n for weights for the following silos: `missing_silos'"
            exit 10
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // -------------------------------- PART THREE: Collapse Data ----------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    if "`plot'" == "agg" {
        if `weights' == 1 {
            qui bysort t treated: egen total_n = sum(n)
            qui gen W = n / total_n
            qui gen weighted_y = W * y
            qui collapse (sum) y=weighted_y, by(t treated time)
        }
        else {
            qui collapse (mean) y=y, by(t treated time)
        }
    }
    else if "`plot'" == "silo" {
        qui replace silo_name = "Control Silos" if treatment_time == "control"
        if `weights' == 1 {
            qui bysort t treated silo_name: egen total_n = sum(n)
            qui gen W = n / total_n
            qui gen weighted_y = W * y
            qui collapse (sum) y=weighted_y, by(t treated silo_name)
        }
        else {
            qui collapse (mean) y=y, by(t treated silo_name)
        }
    }
    else if "`plot'" == "event" {
        if "`event_window'" != "" {
            qui drop if event_time < `event_start' | event_time > `event_end'
        }
        qui gen intercept = 1
        if `weights' == 1 {
            qui bysort event_time: egen total_n = sum(n)
            qui gen W = n / total_n
            qui gen weighted_y = W * y
            qui replace intercept = sqrt(W)
            qui replace y = intercept * y
        }
        else {
            qui bysort event_time: gen count_obs = _N
            qui gen W = 1 / count_obs
            qui gen weighted_y = W * y
            qui replace intercept = sqrt(W)
            qui replace y = intercept * y
        }
        qui gen se = . 
        qui gen ci_upper = .
        qui gen ci_lower = .
        qui levelsof event_time, local(ev_times)
        foreach et of local ev_times {
            qui count if event_time == `et'
            if r(N) > 1 {
                qui reg y intercept if event_time == `et', noconstant vce(robust) 
                qui replace se = _se[intercept] if event_time == `et'
                local t_crit = invttail(e(df_r), ((1-`ci')/2))  
                qui replace ci_lower = _b[intercept] - `t_crit' * _se[intercept] if event_time == `et'
                qui replace ci_upper = _b[intercept] + `t_crit' * _se[intercept] if event_time == `et'
            }
        }
        qui collapse (sum) y = weighted_y (first) se = se ci_lower = ci_lower ci_upper, by(event_time)
    }
        
                       

    // ---------------------------------------------------------------------------------------- //
    // -------------------------------- PART Four: Plot Data ---------------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    if "`plot'" == "agg" {
        twoway (line y t if treated == 0, lcolor(navy) lwidth(medthick) lpattern(solid)) ///
               (line y t if treated == 1, lcolor(cranberry) lwidth(medthick) lpattern(solid)) ///
               (scatter y t if treated == 0, mcolor(navy) msize(small) msymbol(square)) ///
               (scatter y t if treated == 1, mcolor(cranberry) msize(small) msymbol(triangle)), ///
               xline(`treatment_times', lcolor(gray) lpattern(dot) lwidth(thick)) ///
               xlabel(, grid glcolor(gs14) glwidth(vthin)) ///
               ylabel(, grid glcolor(gs14) glwidth(vthin)) ///
               legend(order(1 "Control Group" 2 "Treatment Group") ///
                      position(6) ring(1) cols(2) size(small) ///
                      region(lcolor(none) fcolor(none))) ///
               xtitle("Time", size(medsmall)) ///
               ytitle("Outcome Variable", size(medsmall)) ///
               title("Parallel Trends Plot", size(medium) color(black)) ///
               subtitle("Plot Type: Aggregated", size(small)) ///
               graphregion(color(white) lcolor(black)) ///
               plotregion(lcolor(black) lwidth(thin)) ///
               scheme(s1mono)
    }
    else if inlist("`plot'", "dis", "silo") {
        levelsof silo_name, local(silos)
        local n_silos : word count `silos'
        local ncols = min(5, max(2, ceil(`n_silos'/10)))
        if "`treated_colours'" == "" {
            local treated_colours "cranberry maroon red orange_red dkorange sienna brown gold pink magenta purple"
        }
        if "`control_colours'" == "" {
            local control_colours "navy dknavy blue midblue ltblue teal dkgreen emerald forest_green mint cyan"
        }
        local n_treated_colours : word count `treated_colours'
        local n_control_colours : word count `control_colours'
        local plot_cmd "twoway"
        local legend_spec "legend(order("
        local line_counter = 1  
        local treated_count = 0
        local control_count = 0

        if "`plot'" == "dis" {
            local subtitle "Plot Type: Disaggregated"
        } 
        else {
            local subtitle "Plot Type: Silo"
        }

        foreach silo of local silos {
            qui sum treated if silo_name == "`silo'"
            local is_treated = r(mean)

            if `is_treated' == 1 {
                local treated_count = `treated_count' + 1
                local color_index = mod(`treated_count'-1, `n_treated_colours') + 1
                local color : word `color_index' of `treated_colours'
                local symbol "triangle" 
                local legend_spec `"`legend_spec' `line_counter' "`silo' (T)""'
            }
            else {
                local control_count = `control_count' + 1
                local color_index = mod(`control_count'-1, `n_control_colours') + 1
                local color : word `color_index' of `control_colours'
                local symbol "square"  
                local legend_spec `"`legend_spec' `line_counter' "`silo' (C)""'
            }
       
            local plot_cmd `"`plot_cmd' (line y t if silo_name == "`silo'", lwidth(medthick) lcolor(`color'))"'
            local plot_cmd `"`plot_cmd' (scatter y t if silo_name == "`silo'", mcolor(`color') msize(small) msymbol(`symbol'))"'
            local line_counter = `line_counter' + 2 
        }
   
        local legend_spec `"`legend_spec') position(6) ring(1) cols(`ncols') size(small) region(lcolor(none) fcolor(none)))"'
   
        `plot_cmd', ///
            xline(`treatment_times', lcolor(gray) lpattern(dot) lwidth(thick)) ///
            xlabel(, grid glcolor(gs14) glwidth(vthin)) ///
            ylabel(, grid glcolor(gs14) glwidth(vthin)) ///
            `legend_spec' ///
            xtitle("Time", size(medsmall)) ///
            ytitle("Outcome Variable", size(medsmall)) ///
            title("Parallel Trends Plot", size(medium) color(black)) ///
            subtitle("`subtitle'", size(small)) ///
            graphregion(color(white) lcolor(black)) ///
            plotregion(lcolor(black) lwidth(thin)) ///
            scheme(s1mono)
    } 
    else if "`plot'" == "event" {
            local display_ci = `ci' * 100
            twoway (rarea ci_upper ci_lower event_time, color(ltblue%60) lwidth(none)) ///
                   (line y event_time, lcolor(navy) lwidth(medthick) lpattern(solid)) ///
                   (scatter y event_time, mcolor(navy) msize(small) msymbol(circle)), ///
                   xline(0, lcolor(gray) lpattern(dot) lwidth(thick)) ///
                   yline(0, lcolor(black) lpattern(solid) lwidth(thin)) ///
                   xlabel(minmax, grid glcolor(gs14) glwidth(vthin)) ///
                   ylabel(, grid glcolor(gs14) glwidth(vthin)) ///
                   legend(order(2 "Point Estimate" 1 "`display_ci'% CI") ///
                          position(6) ring(1) cols(2) size(small) ///
                          region(lcolor(none) fcolor(none))) ///
                   xtitle("Time Since Event (Period Length: `period_length')", size(medsmall)) ///
                   ytitle("Outcome Variable", size(medsmall)) ///
                   title("Event Study Plot", size(medium) color(black)) ///
                   subtitle("Plot Type: Event Study with `display_ci'% Confidence Intervals", size(small)) ///
                   graphregion(color(white) lcolor(black)) ///
                   plotregion(lcolor(black) lwidth(thin)) ///
                   scheme(s1mono)
    }
    

end 

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.1.0 - now shows which silo-year combinations have missing values of mean_outcome or mean_outcome_residualized before dropping them
*1.0.0 - created function