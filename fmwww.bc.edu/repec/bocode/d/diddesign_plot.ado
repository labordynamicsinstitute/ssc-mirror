*! diddesign_plot.ado - Visualization command for DIDdesign estimation results
*! version 1.0.2  03jul2026
*!
*! Generates diagnostic plots for Double DID analysis including trend plots
*! for standard DID designs and treatment pattern visualizations for
*! staggered adoption designs.


// =============================================================================
// diddesign_plot
// Main entry point for DIDdesign visualization
//
// Creates five types of plots for Double DID analysis:
//   - estimates : Double-DID estimates across lead values with stored CI bounds
//   - trends    : Outcome trajectories for treated and control groups
//   - placebo   : Pre-treatment placebo test with equivalence CI
//   - pattern   : Treatment timing heatmap (staggered adoption only)
//   - both      : Combined diagnostic plot (placebo + trends/pattern)
//
// Options:
//   type()     : string - Plot type (default: estimates after diddesign,
//                         both after diddesign_check)
//   saving()   : string - Output file path
//   replace    : flag   - Overwrite existing file
//   scheme()   : string - Graph scheme name
//   title()    : string - Graph title
//   xtitle()   : string - X-axis title
//   ytitle()   : string - Y-axis title
//   xlabel()   : string - X-axis tick/label spec (twoway passthru); on the
//                         pattern plot, overrides the auto-detected year axis
//   ylabel()   : string - Y-axis tick/label spec (twoway passthru); on the
//                         pattern plot, overrides the default hidden axis
//   ci         : flag   - Display confidence bands on trends plot
//   band       : flag   - Display CI as ribbon on estimates plot
//   name()     : string - Graph name in memory
//   use_check(): string - Name of stored diddesign_check results to overlay
//   level()    : integer - Confidence level for estimates plot CI (default 90)
//
// Data source:
//   Reads from e() results produced by diddesign or diddesign_check
// =============================================================================

program define diddesign_plot
    version 16.0
    
    local raw0 `"`0'"'
    local raw0 = trim(`"`raw0'"')
    if substr(`"`raw0'"', 1, 1) == "," {
        local raw0 = trim(substr(`"`raw0'"', 2, .))
    }
    
    local type ""
    local saving ""
    local replace ""
    local scheme ""
    local title ""
    local xtitle ""
    local ytitle ""
    local xlabel ""
    local ylabel ""
    local ci ""
    local band ""
    local name ""
    local usecheck ""
    local level ""
    local colorcheck ""
    local estcolor ""
    local checkcolor ""
    
    while `"`raw0'"' != "" {
        gettoken token raw0 : raw0, bind
        while strpos(`"`token'"', "(") > 0 & substr(`"`token'"', length(`"`token'"'), 1) != ")" & `"`raw0'"' != "" {
            gettoken token_more raw0 : raw0, bind
            local token `"`token' `token_more'"'
        }
        local token_l = lower(`"`token'"')
        
        if substr(`"`token_l'"', 1, 5) == "type(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local type = substr(`"`token'"', 6, length(`"`token'"') - 6)
        }
        else if substr(`"`token_l'"', 1, 7) == "saving(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local saving = substr(`"`token'"', 8, length(`"`token'"') - 8)
            // Stata allows saving("path", replace); split the optional ", replace"
            // suffix off and strip surrounding quotes so downstream code
            // receives a clean filename.
            local saving_trim = trim(`"`saving'"')
            // 1. Peel off ", replace" suffix if present.
            local lparen_pos = strpos(`"`saving_trim'"', ",")
            if `lparen_pos' > 0 {
                local suffix = trim(substr(`"`saving_trim'"', `lparen_pos' + 1, .))
                if lower(`"`suffix'"') == "replace" {
                    local saving_trim = trim(substr(`"`saving_trim'"', 1, `lparen_pos' - 1))
                    local replace "replace"
                }
            }
            // 2. Strip a single pair of surrounding double quotes.
            if length(`"`saving_trim'"') >= 2 ///
                 & substr(`"`saving_trim'"', 1, 1) == `"""' ///
                 & substr(`"`saving_trim'"', length(`"`saving_trim'"'), 1) == `"""' {
                local saving_trim = substr(`"`saving_trim'"', 2, length(`"`saving_trim'"') - 2)
            }
            local saving `"`saving_trim'"'
        }
        else if substr(`"`token_l'"', 1, 7) == "scheme(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local scheme = substr(`"`token'"', 8, length(`"`token'"') - 8)
        }
        else if substr(`"`token_l'"', 1, 6) == "title(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local title = substr(`"`token'"', 7, length(`"`token'"') - 7)
        }
        else if substr(`"`token_l'"', 1, 7) == "xtitle(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local xtitle = substr(`"`token'"', 8, length(`"`token'"') - 8)
        }
        else if substr(`"`token_l'"', 1, 7) == "ytitle(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local ytitle = substr(`"`token'"', 8, length(`"`token'"') - 8)
        }
        else if substr(`"`token_l'"', 1, 7) == "xlabel(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local xlabel = substr(`"`token'"', 8, length(`"`token'"') - 8)
        }
        else if substr(`"`token_l'"', 1, 7) == "ylabel(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local ylabel = substr(`"`token'"', 8, length(`"`token'"') - 8)
        }
        else if substr(`"`token_l'"', 1, 5) == "name(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local name = substr(`"`token'"', 6, length(`"`token'"') - 6)
        }
        else if substr(`"`token_l'"', 1, 9) == "usecheck(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local usecheck = substr(`"`token'"', 10, length(`"`token'"') - 10)
        }
        else if substr(`"`token_l'"', 1, 10) == "use_check(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local usecheck = substr(`"`token'"', 11, length(`"`token'"') - 11)
        }
        else if substr(`"`token_l'"', 1, 6) == "level(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local level = substr(`"`token'"', 7, length(`"`token'"') - 7)
        }
        else if substr(`"`token_l'"', 1, 9) == "estcolor(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local estcolor = substr(`"`token'"', 10, length(`"`token'"') - 10)
        }
        else if substr(`"`token_l'"', 1, 11) == "checkcolor(" & substr(`"`token'"', length(`"`token'"'), 1) == ")" {
            local checkcolor = substr(`"`token'"', 12, length(`"`token'"') - 12)
        }
        else if lower(`"`token'"') == "colorcheck" {
            local colorcheck "colorcheck"
        }
        else if lower(`"`token'"') == "replace" {
            local replace "replace"
        }
        else if lower(`"`token'"') == "ci" {
            local ci "ci"
        }
        else if lower(`"`token'"') == "band" {
            local band "band"
        }
        else if `"`token'"' != "" {
            display as error "option `token' not allowed"
            exit 198
        }
    }
    
    foreach opt in saving scheme title xtitle ytitle name usecheck {
        local optval `"` ``opt'' '"'
        if substr(`"`optval'"', 1, 1) == `"""' & substr(`"`optval'"', length(`"`optval'"'), 1) == `"""' {
            local `opt' = substr(`"`optval'"', 2, length(`"`optval'"') - 2)
        }
    }

    while length(`"`saving'"') >= 2 & ///
        substr(`"`saving'"', 1, 1) == `"""' & ///
        substr(`"`saving'"', length(`"`saving'"'), 1) == `"""' {
        local saving = substr(`"`saving'"', 2, length(`"`saving'"') - 2)
    }
    foreach opt in title xtitle ytitle {
        while length(`"``opt''"') >= 2 & ///
            substr(`"``opt''"', 1, 1) == `"""' & ///
            substr(`"``opt''"', length(`"``opt''"'), 1) == `"""' {
            local `opt' = substr(`"``opt''"', 2, length(`"``opt''"') - 2)
        }
    }
    
    // -------------------------------------------------------------------------
    // Validate estimation results
    // -------------------------------------------------------------------------
    
    if "`e(cmd)'" == "" {
        display as error "no estimation results found"
        display as error "run diddesign or diddesign_check first"
        exit 301
    }
    
    if !inlist("`e(cmd)'", "diddesign", "diddesign_check") {
        display as error "diddesign_plot requires diddesign or diddesign_check results"
        display as error "run diddesign or diddesign_check first"
        exit 301
    }
    
    // Source command type is stored for subsequent routing
    local current_cmd "`e(cmd)'"
    
    // -------------------------------------------------------------------------
    // Get design type
    // -------------------------------------------------------------------------
    local design = "`e(design)'"
    if "`design'" == "" {
        local design "did"
    }
    
    // -------------------------------------------------------------------------
    // Set default plot type based on source command
    // -------------------------------------------------------------------------
    // Default type is "estimates" for diddesign results and "both" for
    // diddesign_check results
    
    if "`type'" == "" {
        if "`current_cmd'" == "diddesign" {
            local type "estimates"
        }
        else {
            local type "both"
        }
    }
    
    // Validate type option
    if !inlist("`type'", "trends", "placebo", "pattern", "both", "estimates") {
        display as error "type() must be one of: trends, placebo, pattern, both, estimates"
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Validate type-design compatibility
    // -------------------------------------------------------------------------
    // Pattern plot is only available for staggered adoption design
    // Trends plot is only available for standard DID design
    
    if "`type'" == "pattern" & "`design'" != "sa" {
        display as error "pattern plot is only available for SA design"
        exit 198
    }
    
    if "`type'" == "trends" & "`design'" == "sa" {
        display as error "trends plot is only available for standard DID design"
        exit 198
    }
    
    // Diagnostic plots require diddesign_check results
    if inlist("`type'", "trends", "placebo", "pattern", "both") & "`current_cmd'" != "diddesign_check" {
        display as error "type(`type') requires diddesign_check results"
        display as error "run diddesign_check first, or use type(estimates)"
        exit 198
    }
    
    // Estimates plot requires e(estimates) matrix
    if "`type'" == "estimates" {
        capture confirm matrix e(estimates)
        if _rc {
            display as error "e(estimates) not found; type(estimates) requires diddesign results"
            exit 301
        }
    }
    
    // -------------------------------------------------------------------------
    // Build common options
    // -------------------------------------------------------------------------
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt `"scheme("`scheme'")"'
    }
    
    // -------------------------------------------------------------------------
    // Dispatch to appropriate plot function
    // -------------------------------------------------------------------------
    
    if "`type'" == "trends" {
        _plot_trends, `scheme_opt' title("`title'") xtitle("`xtitle'") ///
                      ytitle("`ytitle'") `ci' name("`name'")
        if "`saving'" != "" {
            _export_graph, saving("`saving'") `replace'
        }
    }
    else if "`type'" == "placebo" {
        _plot_placebo, `scheme_opt' title("`title'") xtitle("`xtitle'") ///
                       ytitle("`ytitle'") name("`name'")
        if "`saving'" != "" {
            _export_graph, saving("`saving'") `replace'
        }
    }
    else if "`type'" == "pattern" {
        local xlab_pass ""
        if `"`xlabel'"' != "" {
            local xlab_pass `"xlabel_opt(`xlabel')"'
        }
        local ylab_pass ""
        if `"`ylabel'"' != "" {
            local ylab_pass `"ylabel_opt(`ylabel')"'
        }
        _plot_pattern, `scheme_opt' title("`title'") xtitle("`xtitle'") ///
                       ytitle("`ytitle'") name("`name'") ///
                       `xlab_pass' `ylab_pass'
        if "`saving'" != "" {
            _export_graph, saving("`saving'") `replace'
        }
    }
    else if "`type'" == "both" {
        // Combined diagnostic plot is generated. For staggered-adoption
        // designs the right-hand panel is a pattern plot, so we pass the
        // user-supplied xlabel()/ylabel() through to _plot_pattern via
        // _plot_combined.
        local xlab_pass ""
        if `"`xlabel'"' != "" {
            local xlab_pass `"xlabel_opt(`xlabel')"'
        }
        local ylab_pass ""
        if `"`ylabel'"' != "" {
            local ylab_pass `"ylabel_opt(`ylabel')"'
        }
        _plot_combined, design("`design'") `scheme_opt' ///
                        title("`title'") xtitle("`xtitle'") ///
                        ytitle("`ytitle'") saving("`saving'") ///
                        name("`name'") `ci' `replace' ///
                        `xlab_pass' `ylab_pass'
    }
    else if "`type'" == "estimates" {
        // Double-DID estimates plot across lead values
        local use_check_opt ""
        if "`usecheck'" != "" {
            local use_check_opt `"usecheck("`usecheck'")"'
        }
        if "`level'" != "" {
            local level_num = real("`level'")
            if missing(`level_num') | `level_num' <= 0 | `level_num' >= 100 {
                display as error "level() must be a number between 1 and 99"
                exit 198
            }
            local level_opt "level(`level_num')"
        }
        else {
            local level_opt ""
        }
        local colorcheck_opt ""
        if "`colorcheck'" != "" {
            local colorcheck_opt "colorcheck"
        }
        local estcolor_opt ""
        if "`estcolor'" != "" {
            local estcolor_opt `"estcolor("`estcolor'")"'
        }
        local checkcolor_opt ""
        if "`checkcolor'" != "" {
            local checkcolor_opt `"checkcolor("`checkcolor'")"'
        }
        _plot_estimates, design("`design'") `scheme_opt' ///
                         title("`title'") xtitle("`xtitle'") ytitle("`ytitle'") ///
                         name("`name'") `use_check_opt' `band' `level_opt' ///
                         `colorcheck_opt' `estcolor_opt' `checkcolor_opt'
        if "`saving'" != "" {
            _export_graph, saving("`saving'") `replace'
        }
    }
    
end


// =============================================================================
// _plot_combined()
// Generate combined diagnostic plot with two subplots arranged horizontally
//
// Layout:
//   - Standard DID: placebo (left) + trends (right)
//   - Staggered adoption: placebo (left) + pattern (right)
//
// Arguments:
//   design  : string - Design type ("did" or "sa")
//   scheme  : string - Graph scheme name
//   title   : string - Combined graph title
//   saving  : string - Output file path
//   name    : string - Graph name in memory
//   ci      : flag   - Display confidence intervals in trends subplot
//   replace : flag   - Overwrite existing file
// =============================================================================

program define _plot_combined
    version 16.0
    
    syntax , DESIGN(string) [SCHeme(string) TItle(string) XTItle(string) YTItle(string) SAVing(string) NAME(string) CI REPlace ///
             XLABel_opt(string asis) YLABel_opt(string asis)]
    
    // -------------------------------------------------------------------------
    // Build scheme option
    // -------------------------------------------------------------------------
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt `"scheme(`scheme')"'
    }
    
    // -------------------------------------------------------------------------
    // Generate subplots based on design type
    // -------------------------------------------------------------------------
    // Placebo plot is positioned on the left for both designs
    
    if "`design'" == "sa" {
        // Staggered adoption: placebo (left) + pattern (right)
        capture graph drop _tmp_placebo
        capture graph drop _tmp_pattern
        
        quietly _plot_placebo, `scheme_opt' title("") ///
            xtitle("`xtitle'") ytitle("`ytitle'") name(_tmp_placebo)
        // Build xlabel/ylabel pass-through strings.  string-asis options keep
        // their surrounding quotes; we therefore re-expand the locals without
        // adding another layer of quotes so _plot_pattern receives the raw
        // specifier (e.g. xlabel_opt(2000(2)2010), not xlabel_opt("2000(2)2010")).
        local xlab_pass ""
        if `"`xlabel_opt'"' != "" {
            local xlab_pass `"xlabel_opt(`xlabel_opt')"'
        }
        local ylab_pass ""
        if `"`ylabel_opt'"' != "" {
            local ylab_pass `"ylabel_opt(`ylabel_opt')"'
        }
        quietly _plot_pattern, `scheme_opt' title("") ///
            xtitle("`xtitle'") ytitle("`ytitle'") name(_tmp_pattern) ///
            `xlab_pass' `ylab_pass'
        
        local title_opt ""
        if `"`title'"' != "" {
            local title_opt `"title(`"`title'"')"'
        }
        
        local graph_name "combined_plot"
        if "`name'" != "" {
            local graph_name "`name'"
        }
        
        graph combine _tmp_placebo _tmp_pattern, ///
            rows(1) ///
            `title_opt' ///
            `scheme_opt' ///
            name(`graph_name', replace)
        
        capture graph drop _tmp_placebo
        capture graph drop _tmp_pattern
    }
    else {
        // Standard DID: placebo (left) + trends (right)
        capture graph drop _tmp_placebo
        capture graph drop _tmp_trends
        
        quietly _plot_placebo, `scheme_opt' title("") ///
            xtitle("`xtitle'") ytitle("`ytitle'") name(_tmp_placebo)
        quietly _plot_trends, `scheme_opt' title("") ///
            xtitle("`xtitle'") ytitle("`ytitle'") name(_tmp_trends) `ci'
        
        local title_opt ""
        if `"`title'"' != "" {
            local title_opt `"title(`"`title'"')"'
        }
        
        local graph_name "combined_plot"
        if "`name'" != "" {
            local graph_name "`name'"
        }
        
        graph combine _tmp_placebo _tmp_trends, ///
            rows(1) ///
            `title_opt' ///
            `scheme_opt' ///
            name(`graph_name', replace)
        
        capture graph drop _tmp_placebo
        capture graph drop _tmp_trends
    }
    
    // -------------------------------------------------------------------------
    // Save graph if requested
    // -------------------------------------------------------------------------
    if "`saving'" != "" {
        _export_graph, saving("`saving'") `replace'
    }
    
end


// =============================================================================
// _export_graph()
// Export graph to file with automatic format detection
//
// Arguments:
//   saving  : string - Output file path
//   replace : flag   - Overwrite existing file
//
// Supported formats: .png, .pdf, .eps, .svg, .tif
// Default format is PNG if no recognized extension is provided.
// =============================================================================

program define _export_graph
    version 16.0
    
    syntax , SAVing(string) [REPlace]

    local saving_clean = trim(`"`saving'"')
    while length(`"`saving_clean'"') >= 2 & ///
       substr(`"`saving_clean'"', 1, 1) == `"""' & ///
       substr(`"`saving_clean'"', length(`"`saving_clean'"'), 1) == `"""' {
        local saving_clean = substr(`"`saving_clean'"', 2, length(`"`saving_clean'"') - 2)
    }
    
    // Determine file extension and export format
    local ext = lower(substr("`saving_clean'", -4, .))
    if inlist("`ext'", ".png", ".pdf", ".eps", ".svg", ".tif") {
        graph export `"`saving_clean'"', `replace'
    }
    else if "`ext'" == ".gph" {
        // .gph is a Stata graph file; use graph save rather than graph export.
        // Saving the currently active graph (no explicit graph name) avoids
        // the default "Graph" name which _plot_combined replaces with
        // "combined_plot".
        graph save `"`saving_clean'"', `replace'
    }
    else {
        // Default to PNG if no recognized extension
        graph export `"`saving_clean'.png"', `replace'
    }
    
end



// =============================================================================
// _plot_trends()
// Generate trend plot showing outcome means for treated and control groups
//
// Displays outcome trajectories over time relative to treatment assignment.
// Control and treated groups are shown as connected lines with markers.
// A vertical dashed line at x=0 indicates the treatment timing.
//
// Arguments:
//   saving  : string - Output file path
//   scheme  : string - Graph scheme name
//   title   : string - Graph title
//   xtitle  : string - X-axis title (default: "Time relative to treatment assignment")
//   ytitle  : string - Y-axis title (default: "Mean Outcome")
//   ci      : flag   - Display 90% confidence bands for group means
//   name    : string - Graph name in memory (default: "trends_plot")
//
// Data source:
//   e(trends) matrix with columns: id_time_std, Gi, outcome_mean, outcome_sd, n_obs
// =============================================================================

program define _plot_trends
    version 16.0
    
    syntax [, SAVing(string) SCHeme(string) ///
              TItle(string) XTItle(string) YTItle(string) ///
              CI name(string)]
    
    // -------------------------------------------------------------------------
    // Validate e(trends) exists
    // -------------------------------------------------------------------------
    if "`e(cmd)'" == "" {
        display as error "no estimation results found"
        exit 301
    }
    
    capture confirm matrix e(trends)
    if _rc {
        display as error "e(trends) not found; run diddesign or diddesign_check first"
        exit 301
    }
    
    // -------------------------------------------------------------------------
    // Extract data to temporary dataset
    // -------------------------------------------------------------------------
    preserve
    clear
    
    tempname trends
    matrix `trends' = e(trends)
    local nrows = rowsof(`trends')
    
    if `nrows' == 0 {
        display as error "e(trends) matrix is empty"
        restore
        exit 198
    }
    
    quietly {
        set obs `nrows'
        
        gen double id_time_std = .
        gen byte Gi = .
        gen double outcome_mean = .
        gen double outcome_sd = .
        gen long n_obs = .
        
        forvalues i = 1/`nrows' {
            replace id_time_std = `trends'[`i', 1] in `i'
            replace Gi = `trends'[`i', 2] in `i'
            replace outcome_mean = `trends'[`i', 3] in `i'
            replace outcome_sd = `trends'[`i', 4] in `i'
            replace n_obs = `trends'[`i', 5] in `i'
        }
        
        gen str8 group = cond(Gi == 1, "Treated", "Control")
    }
    
    // -------------------------------------------------------------------------
    // Calculate confidence intervals (optional)
    // -------------------------------------------------------------------------
    // Match the reference R plot: use the stored group-period outcome SD
    // directly as the band width scale rather than converting it to an SE.

    if "`ci'" != "" {
        quietly {
            gen double outcome_ci_lb = outcome_mean - invnormal(0.95) * outcome_sd
            gen double outcome_ci_ub = outcome_mean + invnormal(0.95) * outcome_sd
        }
    }
    
    // -------------------------------------------------------------------------
    // Set default values
    // -------------------------------------------------------------------------
    if "`title'" == "" local title ""
    if "`xtitle'" == "" local xtitle "Time relative to treatment assignment"
    if "`ytitle'" == "" local ytitle "Mean Outcome"
    if "`name'" == "" local name "trends_plot"
    
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt "scheme(`scheme')"
    }
    
    // -------------------------------------------------------------------------
    // Build graph command
    // -------------------------------------------------------------------------
    // Colors: Control = gray (gs8), Treated = teal (#1E88A8 = "30 136 168")
    
    local graph_cmd ""
    
    if "`ci'" != "" {
        // CI bands with 30% transparency
        local graph_cmd `graph_cmd' (rarea outcome_ci_lb outcome_ci_ub id_time_std if Gi==0, color(gs8%30) lwidth(none))
        local graph_cmd `graph_cmd' (rarea outcome_ci_lb outcome_ci_ub id_time_std if Gi==1, color("30 136 168"%30) lwidth(none))
    }
    
    // Main trend lines with point markers
    local graph_cmd `graph_cmd' (connected outcome_mean id_time_std if Gi==0, lcolor(gs8) mcolor(gs8) lpattern(solid) msymbol(O))
    local graph_cmd `graph_cmd' (connected outcome_mean id_time_std if Gi==1, lcolor("30 136 168") mcolor("30 136 168") lpattern(solid) msymbol(O))
    
    // -------------------------------------------------------------------------
    // Configure legend
    // -------------------------------------------------------------------------
    local legend_order ""
    if "`ci'" != "" {
        // With CI bands, legend references line elements (3 and 4)
        local legend_order `"order(3 "Control" 4 "Treated") title("Group")"'
    }
    else {
        local legend_order `"order(1 "Control" 2 "Treated") title("Group")"'
    }
    
    // -------------------------------------------------------------------------
    // Generate graph
    // -------------------------------------------------------------------------
    local title_opt ""
    if "`title'" != "" {
        local title_opt `"title("`title'")"'
    }
    
    twoway `graph_cmd', ///
        xline(0, lpattern(dash) lcolor(black)) ///
        legend(`legend_order' rows(1)) ///
        `title_opt' ///
        xtitle("`xtitle'") ///
        ytitle("`ytitle'") ///
        `scheme_opt' ///
        name(`name', replace)
    
    restore
    
end



// =============================================================================
// _plot_placebo()
// Generate placebo plot showing 95% standardized equivalence confidence intervals
//
// Displays error bars for pre-treatment period estimates to assess the
// parallel trends assumption. The 95% equivalence CI is symmetric around zero.
//
// Equivalence CI calculation:
//   EqCI95_UB = max(|estimate + z_{0.95} * se|, |estimate - z_{0.95} * se|)
//   EqCI95_LB = -EqCI95_UB
//
// Arguments:
//   saving  : string - Output file path
//   scheme  : string - Graph scheme name
//   title   : string - Graph title
//   xtitle  : string - X-axis title (default: "Time relative to treatment assignment")
//   ytitle  : string - Y-axis title (default: "95% Standardized Equivalence CI")
//   name    : string - Graph name in memory (default: "placebo_plot")
//
// Data source:
//   e(placebo) matrix with columns: lag, estimate, std_error, estimate_orig,
//   std_error_orig, EqCI95_LB, EqCI95_UB
// =============================================================================

program define _plot_placebo
    version 16.0
    
    syntax [, SAVing(string) SCHeme(string) ///
              TItle(string) XTItle(string) YTItle(string) ///
              name(string)]
    
    // -------------------------------------------------------------------------
    // Validate e(placebo) exists
    // -------------------------------------------------------------------------
    if "`e(cmd)'" == "" {
        display as error "no estimation results found"
        exit 301
    }
    
    capture confirm matrix e(placebo)
    if _rc {
        display as error "e(placebo) not found; run diddesign_check first"
        exit 301
    }
    
    // -------------------------------------------------------------------------
    // Extract data to temporary dataset
    // -------------------------------------------------------------------------
    // e(placebo) columns: lag, estimate, std_error, estimate_orig,
    // std_error_orig, EqCI95_LB, EqCI95_UB
    preserve
    clear
    
    tempname placebo
    matrix `placebo' = e(placebo)
    local nrows = rowsof(`placebo')
    local ncols = colsof(`placebo')
    
    if `nrows' == 0 {
        display as error "e(placebo) is empty"
        restore
        exit 198
    }
    
    // Validate expected matrix structure
    if `ncols' < 7 {
        display as error "e(placebo) has unexpected structure (expected 7 columns, found `ncols')"
        display as error "Please re-run diddesign_check"
        restore
        exit 198
    }
    
    quietly {
        set obs `nrows'
        gen double lag = .
        gen double estimate = .
        gen double std_error = .
        gen double estimate_orig = .
        gen double std_error_orig = .
        gen double EqCI95_LB = .
        gen double EqCI95_UB = .
        
        forvalues i = 1/`nrows' {
            replace lag = `placebo'[`i', 1] in `i'
            replace estimate = `placebo'[`i', 2] in `i'
            replace std_error = `placebo'[`i', 3] in `i'
            replace estimate_orig = `placebo'[`i', 4] in `i'
            replace std_error_orig = `placebo'[`i', 5] in `i'
            // Pre-computed EqCI95 values (columns 6-7)
            replace EqCI95_LB = `placebo'[`i', 6] in `i'
            replace EqCI95_UB = `placebo'[`i', 7] in `i'
        }
    }

    quietly count if EqCI95_LB < . & EqCI95_UB < .
    local n_plot = r(N)

    if `n_plot' == 0 {
        quietly count if estimate_orig < . | std_error_orig < .
        local has_raw_support = r(N) > 0

        if `has_raw_support' {
            display as error "E011: Standardized placebo plot is unavailable"
            display as error "      No lag has a defined standardized equivalence CI"
            display as error "      This typically occurs when the baseline control-group SD is zero"
            display as error "      Raw placebo estimates remain available in e(placebo)"
        }
        else {
            display as error "E011: Placebo plot data contain no plottable equivalence intervals"
        }
        restore
        exit 498
    }

    if `n_plot' < `nrows' {
        local n_omitted = `nrows' - `n_plot'
        display as text "Note: `n_omitted' lag(s) omitted from placebo plot because the standardized equivalence CI is undefined."
        quietly keep if EqCI95_LB < . & EqCI95_UB < .
    }
    
    // -------------------------------------------------------------------------
    // Calculate time relative to treatment (time_to_treat = -lag)
    // -------------------------------------------------------------------------
    gen double time_to_treat = -lag
    
    // -------------------------------------------------------------------------
    // Set default values
    // -------------------------------------------------------------------------
    if `"`title'"' == "" local title ""
    if `"`xtitle'"' == "" local xtitle "Time relative to treatment assignment"
    if `"`ytitle'"' == "" local ytitle "95% Standardized Equivalence CI"
    if "`name'" == "" local name "placebo_plot"
    
    // -------------------------------------------------------------------------
    // Handle single lag case (expand x-axis range)
    // -------------------------------------------------------------------------
    local xlim_opt ""
    if `n_plot' == 1 {
        quietly sum lag
        local lag_val = r(mean)
        local xlim_lb = -`lag_val' - 1
        local xlim_ub = -`lag_val' + 1
        local xlim_opt "xscale(range(`xlim_lb' `xlim_ub'))"
    }
    
    // -------------------------------------------------------------------------
    // Build options
    // -------------------------------------------------------------------------
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt "scheme(`scheme')"
    }
    
    local title_opt ""
    if `"`title'"' != "" {
        local title_opt `"title(`"`title'"')"'
    }
    
    // -------------------------------------------------------------------------
    // Generate placebo plot
    // -------------------------------------------------------------------------
    // Equivalence CI bars (rcap) + point estimate marker (scatter)
    // Color: teal (#1E88A8 = "30 136 168")
    // Reference line at y=0 (dotted, gray)
    
    twoway (rcap EqCI95_LB EqCI95_UB time_to_treat, ///
                lcolor("30 136 168") msize(vsmall)) ///
           (scatter estimate time_to_treat, ///
                mcolor("30 136 168") msymbol(O) msize(small)), ///
           yline(0, lpattern(dot) lcolor(gs8)) ///
           `title_opt' ///
           xtitle(`"`xtitle'"') ///
           ytitle(`"`ytitle'"') ///
           legend(off) ///
           `xlim_opt' ///
           `scheme_opt' ///
           name(`name', replace)
    
    // -------------------------------------------------------------------------
    // Save graph if requested
    // -------------------------------------------------------------------------
    if "`saving'" != "" {
        _export_graph, saving("`saving'") `replace'
    }
    
    restore
    
end



// =============================================================================
// _plot_pattern()
// Generate treatment pattern heatmap for staggered adoption design
//
// Displays treatment status over time for each unit as a tile plot.
// Units are sorted by first treatment timing (earliest at top, never-treated
// at bottom).
//
// Arguments:
//   saving  : string - Output file path
//   scheme  : string - Graph scheme name
//   title   : string - Graph title
//   xtitle  : string - X-axis title (default: "Time")
//   ytitle  : string - Y-axis title (default: "Unit")
//   name    : string - Graph name in memory (default: "pattern_plot")
//
// Data source:
//   e(Gmat) matrix from diddesign_check with design(sa)
//   Rows: units, Columns: time periods
//   Values: 0=not treated, non-zero=treated
// =============================================================================

program define _plot_pattern
    version 16.0
    
    syntax [, SAVing(string) SCHeme(string) ///
              TItle(string) XTItle(string) YTItle(string) ///
              name(string) ///
              XLABel_opt(string asis) YLABel_opt(string asis)]
    
    // -------------------------------------------------------------------------
    // Validate e(Gmat) exists and design is SA
    // -------------------------------------------------------------------------
    if "`e(cmd)'" == "" {
        display as error "no estimation results found"
        exit 301
    }
    
    if "`e(design)'" != "sa" {
        display as error "pattern plot only available for SA design"
        exit 198
    }
    
    capture confirm matrix e(Gmat)
    if _rc {
        display as error "e(Gmat) not found; run diddesign_check with design(sa) first"
        exit 301
    }
    
    // -------------------------------------------------------------------------
    // Detect calendar-year range from the caller's data before preserve/clear.
    // When Gmat columns map one-to-one to consecutive calendar years (as in
    // balanced staggered-adoption panels), we record the min year so users can
    // request year-labelled xlabel() without hard-coding the mapping.
    // -------------------------------------------------------------------------
    local auto_year_min ""
    local auto_year_max ""
    local time_var_saved "`e(time)'"
    if "`time_var_saved'" != "" {
        capture confirm numeric variable `time_var_saved'
        if _rc == 0 {
            quietly summarize `time_var_saved', meanonly
            if !missing(r(min)) & !missing(r(max)) {
                local auto_year_min = r(min)
                local auto_year_max = r(max)
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Extract Gmat matrix
    // -------------------------------------------------------------------------
    preserve
    clear
    
    tempname Gmat
    matrix `Gmat' = e(Gmat)
    local n_units = rowsof(`Gmat')
    local n_times = colsof(`Gmat')
    
    if `n_units' == 0 | `n_times' == 0 {
        display as error "e(Gmat) is empty"
        restore
        exit 198
    }
    
    // Check for placeholder matrix indicating failed analysis
    if `n_units' == 1 & `n_times' == 1 {
        if missing(`Gmat'[1,1]) {
            display as error "e(Gmat) is a placeholder matrix (1x1 with missing value)"
            display as error "SA analysis may have failed. Please check diddesign_check output."
            display as error "Tip: Verify that your data has sufficient treated units meeting the threshold."
            restore
            exit 198
        }
    }
    
    // -------------------------------------------------------------------------
    // Compute treatment timing and sort order
    // -------------------------------------------------------------------------
    // Units are sorted by first treatment period:
    //   - Never-treated units: Y = 1 (bottom)
    //   - Latest-treated units: middle positions
    //   - Earliest-treated units: Y = n_units (top)
    
    tempname sorted_pos
    mata: _compute_treat_timing("`Gmat'")
    matrix `sorted_pos' = r(sort_order)
    
    // -------------------------------------------------------------------------
    // Determine whether automatic year labelling is applicable.
    // Applies when the caller's data has numeric time values and the number of
    // Gmat columns matches the calendar span (one column per unit time step).
    // -------------------------------------------------------------------------
    local use_year_axis = 0
    if "`auto_year_min'" != "" & "`auto_year_max'" != "" {
        local span_implied = `auto_year_max' - `auto_year_min' + 1
        if `span_implied' == `n_times' {
            local use_year_axis = 1
        }
    }
    
    // -------------------------------------------------------------------------
    // Convert to long format dataset
    // -------------------------------------------------------------------------
    quietly {
        local n_obs = `n_units' * `n_times'
        set obs `n_obs'
        
        gen long id_subject = .
        gen long id_time = .
        gen double id_time_plot = .
        gen byte treated = .
        gen long id_subject_sorted = .
        
        local obs = 1
        forvalues i = 1/`n_units' {
            forvalues t = 1/`n_times' {
                replace id_subject = `i' in `obs'
                replace id_time = `t' in `obs'
                if `use_year_axis' {
                    replace id_time_plot = `auto_year_min' + `t' - 1 in `obs'
                }
                else {
                    replace id_time_plot = `t' in `obs'
                }
                // Binary treatment indicator: 0=control, non-zero=treated
                replace treated = (`Gmat'[`i', `t'] != 0) in `obs'
                replace id_subject_sorted = `sorted_pos'[`i', 1] in `obs'
                local obs = `obs' + 1
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Set default values
    // -------------------------------------------------------------------------
    if `"`title'"' == "" local title ""
    if `"`xtitle'"' == "" local xtitle "Time"
    if `"`ytitle'"' == "" local ytitle "Unit"
    if "`name'" == "" local name "pattern_plot"
    
    // -------------------------------------------------------------------------
    // Calculate tile size based on data dimensions
    // -------------------------------------------------------------------------
    if `n_units' <= 20 & `n_times' <= 20 {
        local tile_size = "vlarge"
    }
    else if `n_units' <= 50 & `n_times' <= 50 {
        local tile_size = "large"
    }
    else if `n_units' <= 100 & `n_times' <= 100 {
        local tile_size = "medium"
    }
    else {
        local tile_size = "small"
    }
    
    // -------------------------------------------------------------------------
    // Build options
    // -------------------------------------------------------------------------
    local title_opt ""
    if `"`title'"' != "" {
        local title_opt `"title(`"`title'"')"'
    }
    
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt "scheme(`scheme')"
    }
    
    // -------------------------------------------------------------------------
    // Generate pattern plot (heatmap)
    // -------------------------------------------------------------------------
    // Colors: control = light gray (#D3D3D3), treated = teal (#1E88A8)
    // Axis labels default to hidden; user-supplied xlabel_opt/ylabel_opt override
    // the default to allow year labels or unit labels in paper-quality figures.
    
    if `"`xlabel_opt'"' != "" {
        local xlab_arg `"xlabel(`xlabel_opt')"'
    }
    else if `use_year_axis' {
        // Auto-label calendar years every two steps (endpoints always shown)
        local xlab_year_step = 2
        if `n_times' <= 6 local xlab_year_step = 1
        local xlab_arg `"xlabel(`auto_year_min'(`xlab_year_step')`auto_year_max')"'
    }
    else {
        local xlab_arg "xlabel(, nolabels noticks)"
    }
    if `"`ylabel_opt'"' != "" {
        local ylab_arg `"ylabel(`ylabel_opt')"'
    }
    else {
        local ylab_arg "ylabel(, nolabels)"
    }
    
    // Use id_time_plot (real calendar year when auto detection succeeds,
    // otherwise the 1..n_times index) so the x-axis reads as the caller's
    // time variable rather than as an anonymous column index.
    twoway (scatter id_subject_sorted id_time_plot if treated==0, ///
                msymbol(S) msize(`tile_size') mcolor("211 211 211")) ///
           (scatter id_subject_sorted id_time_plot if treated==1, ///
                msymbol(S) msize(`tile_size') mcolor("30 136 168")), ///
           `title_opt' ///
           xtitle("`xtitle'") ///
           ytitle("`ytitle'") ///
           legend(order(1 "control" 2 "treated") title("Status") rows(1)) ///
           `xlab_arg' `ylab_arg' ///
           `scheme_opt' ///
           name(`name', replace)
    
    // -------------------------------------------------------------------------
    // Save graph if requested
    // -------------------------------------------------------------------------
    if "`saving'" != "" {
        _export_graph, saving("`saving'") `replace'
    }
    
    restore
    
end


// =============================================================================
// _plot_estimates()
// Generate Double-DID estimates plot with confidence intervals
//
// Displays Double-DID point estimates across lead values with fixed 90% CI.
// Optionally overlays placebo estimates from stored diddesign_check results.
//
// Arguments:
//   design    : string - Design type ("did" or "sa")
//   scheme    : string - Graph scheme name
//   title     : string - Graph title
//   xtitle    : string - X-axis title (default: "Time")
//   ytitle    : string - Y-axis title (default: "Estimates (90% CI)")
//   name      : string - Graph name in memory (default: "estimates_plot")
//   use_check : string - Name of stored diddesign_check results to overlay
//   band      : flag   - Display CI as ribbon instead of error bars
//
// Data source:
//   e(estimates) matrix from diddesign
//   Row structure: 3 rows per lead (Double-DID, DID, sequential DID)
//   Columns: lead, estimate, std_error, ci_lo, ci_hi, weight
// =============================================================================

program define _plot_estimates
    version 16.0
    
    syntax [, DESIGN(string) SCHeme(string) ///
              TItle(string) XTItle(string) YTItle(string) ///
              name(string) USECHECK(string) BAND LEVEL(integer 90) ///
              COLORCHECK ESTCOLOR(string) CHECKCOLOR(string)]
    
    // -------------------------------------------------------------------------
    // Validate e(estimates) exists
    // -------------------------------------------------------------------------
    if "`e(cmd)'" == "" {
        display as error "no estimation results found"
        exit 301
    }
    
    capture confirm matrix e(estimates)
    if _rc {
        display as error "e(estimates) not found; run diddesign first"
        exit 301
    }
    
    // -------------------------------------------------------------------------
    // Extract Double-DID estimates
    // -------------------------------------------------------------------------
    // e(estimates) contains 3 rows per lead: Double-DID, DID, sequential DID
    // Extract only Double-DID rows (every 3rd row starting from 1)
    
    preserve
    
    tempname estimates
    matrix `estimates' = e(estimates)
    local nrows = rowsof(`estimates')
    local ncols = colsof(`estimates')
    local plot_level = `level'
    local plot_z = invnormal((1 + `level' / 100) / 2)
    
    if `nrows' == 0 {
        display as error "e(estimates) is empty"
        restore
        exit 198
    }
    
    local rownames : rownames `estimates'
    // Determine block size: K>2 path has (1+kmax) rows per lead, K=2 has 3
    local _plot_kmax = e(kmax)
    if missing(`_plot_kmax') | `_plot_kmax' == . {
        local _plot_kmax = 2
    }
    local _plot_block = 3
    if `_plot_kmax' > 2 {
        local _plot_block = 1 + `_plot_kmax'
    }
    local n_ddid = ceil(`nrows' / `_plot_block')

    // -------------------------------------------------------------------------
    // Validate and capture placebo overlay inputs before clearing data
    // -------------------------------------------------------------------------
    if "`usecheck'" != "" {
        local main_depvar "`e(depvar)'"
        local main_treatment "`e(treatment)'"
        local main_clustvar "`e(clustvar)'"
        local main_covariates "`e(covariates)'"
        if "`main_covariates'" == "" {
            local main_covariates "`e(covars)'"
        }
        local main_datatype "`e(datatype)'"
        local main_id "`e(id)'"
        local main_time "`e(time)'"
        local main_post "`e(post)'"
        local main_sample_ifin `"`e(sample_ifin)'"'
        tempvar main_sample_marker check_sample_marker
        quietly gen byte `main_sample_marker' = 0
        if `"`main_sample_ifin'"' == "" | trim(`"`main_sample_ifin'"') == "" {
            quietly replace `main_sample_marker' = 1
        }
        else {
            quietly replace `main_sample_marker' = 1 `main_sample_ifin'
        }
        capture estimates describe `usecheck'
        if _rc {
            display as error "stored results '`usecheck'' not found"
            display as error "use 'estimates store' to save diddesign_check results first"
            restore
            exit 301
        }
        
        // Temporarily restore stored results to access e(placebo)
        tempname current_est
        _estimates hold `current_est', restore
        
        quietly estimates restore `usecheck'
        
        if "`e(cmd)'" != "diddesign_check" {
            _estimates unhold `current_est'
            display as error "'`usecheck'' is not diddesign_check results"
            restore
            exit 198
        }

        local check_design = lower("`e(design)'")
        local main_design = lower("`design'")
        if "`main_design'" == "" {
            local main_design "did"
        }
        if "`check_design'" == "" {
            local check_design "did"
        }
        if "`check_design'" != "`main_design'" {
            _estimates unhold `current_est'
            display as error "use_check() design mismatch: current estimate is `main_design', stored check result is `check_design'"
            restore
            exit 198
        }

        local check_datatype "`e(datatype)'"
        if "`main_datatype'" != "`check_datatype'" {
            _estimates unhold `current_est'
            display as error "use_check() datatype mismatch: current estimate is `main_datatype', stored check result is `check_datatype'"
            restore
            exit 198
        }

        if "`main_datatype'" == "rcs" {
            local check_post "`e(post)'"
            if "`main_post'" == "" | "`check_post'" == "" {
                _estimates unhold `current_est'
                display as error "use_check() post() metadata unavailable for RCS results; re-run with current diddesign and diddesign_check versions"
                restore
                exit 198
            }
            if "`main_post'" != "`check_post'" {
                _estimates unhold `current_est'
                display as error "use_check() post mismatch: current estimate uses `main_post', stored check result uses `check_post'"
                restore
                exit 198
            }
        }
        else {
            local check_id "`e(id)'"
            if "`main_id'" == "" | "`check_id'" == "" {
                _estimates unhold `current_est'
                display as error "use_check() id() metadata unavailable for panel results; re-run with current diddesign and diddesign_check versions"
                restore
                exit 198
            }
            if "`main_id'" != "`check_id'" {
                _estimates unhold `current_est'
                display as error "use_check() id mismatch: current estimate uses `main_id', stored check result uses `check_id'"
                restore
                exit 198
            }
            local check_time "`e(time)'"
            if "`main_time'" == "" | "`check_time'" == "" {
                _estimates unhold `current_est'
                display as error "use_check() time() metadata unavailable for panel results; re-run with current diddesign and diddesign_check versions"
                restore
                exit 198
            }
            if "`main_time'" != "`check_time'" {
                _estimates unhold `current_est'
                display as error "use_check() time mismatch: current estimate uses `main_time', stored check result uses `check_time'"
                restore
                exit 198
            }
        }

        local check_sample_ifin `"`e(sample_ifin)'"'
        quietly gen byte `check_sample_marker' = 0
        if `"`check_sample_ifin'"' == "" | trim(`"`check_sample_ifin'"') == "" {
            quietly replace `check_sample_marker' = 1
        }
        else {
            quietly replace `check_sample_marker' = 1 `check_sample_ifin'
        }

        local check_depvar "`e(depvar)'"
        if "`main_depvar'" != "`check_depvar'" {
            _estimates unhold `current_est'
            display as error "use_check() depvar mismatch: current estimate uses `main_depvar', stored check result uses `check_depvar'"
            restore
            exit 198
        }

        local check_treatment "`e(treatment)'"
        if "`main_treatment'" != "`check_treatment'" {
            _estimates unhold `current_est'
            display as error "use_check() treatment mismatch: current estimate uses `main_treatment', stored check result uses `check_treatment'"
            restore
            exit 198
        }

        local check_clustvar "`e(clustvar)'"
        if "`main_clustvar'" != "`check_clustvar'" {
            _estimates unhold `current_est'
            display as error "use_check() clustvar mismatch: current estimate uses `main_clustvar', stored check result uses `check_clustvar'"
            restore
            exit 198
        }

        local check_covariates "`e(covariates)'"
        if "`check_covariates'" == "" {
            local check_covariates "`e(covars)'"
        }
        if "`main_covariates'" != "`check_covariates'" {
            _estimates unhold `current_est'
            display as error "use_check() covariates mismatch: current estimate uses `main_covariates', stored check result uses `check_covariates'"
            restore
            exit 198
        }

        quietly count if `main_sample_marker' != `check_sample_marker'
        if r(N) > 0 {
            _estimates unhold `current_est'
            display as error "use_check() sample mismatch: current estimate and stored check result use different if/in samples"
            restore
            exit 198
        }
        
        capture confirm matrix e(placebo)
        if _rc {
            _estimates unhold `current_est'
            display as error "e(placebo) not found in '`usecheck''"
            restore
            exit 301
        }
        
        tempname placebo
        matrix `placebo' = e(placebo)
        local n_placebo = rowsof(`placebo')
        local check_level_val = e(level)
        if missing(`check_level_val') {
            // Legacy diddesign_check results do not store e(level); their
            // placebo and equivalence intervals are still defined from 90% CI.
            local check_level_val = 90
        }
        local check_plot_z = invnormal((1 + `check_level_val' / 100) / 2)
        
        _estimates unhold `current_est'
    }

    clear
    
    quietly {
        set obs `n_ddid'
        gen double time = .
        gen double estimate = .
        gen double std_error = .
        gen double CI90_LB = .
        gen double CI90_UB = .
        gen byte source = 1  // 1 = diddesign estimates
        
        // Extract final estimator rows (first row of each block)
        local obs = 1
        forvalues i = 1(`_plot_block')`nrows' {
            replace time = `estimates'[`i', 1] in `obs'
            replace estimate = `estimates'[`i', 2] in `obs'
            replace std_error = `estimates'[`i', 3] in `obs'
            // CI bounds use the level() specified by the user (default 90).
            replace CI90_LB = `estimates'[`i', 2] - `plot_z' * `estimates'[`i', 3] in `obs'
            replace CI90_UB = `estimates'[`i', 2] + `plot_z' * `estimates'[`i', 3] in `obs'
            local obs = `obs' + 1
        }
    }
    
    // -------------------------------------------------------------------------
    // Overlay placebo estimates (if use_check specified)
    // -------------------------------------------------------------------------
    // Placebo estimates are placed at time = -lag (negative lag values)
    
    if "`usecheck'" != "" {
        local new_obs = _N + `n_placebo'
        quietly {
            set obs `new_obs'
            
            local start = _N - `n_placebo' + 1
            forvalues i = 1/`n_placebo' {
                local obs = `start' + `i' - 1
                replace time = -`placebo'[`i', 1] in `obs'
                replace estimate = `placebo'[`i', 4] in `obs'
                replace std_error = `placebo'[`i', 5] in `obs'
                replace CI90_LB = `placebo'[`i', 4] - `check_plot_z' * `placebo'[`i', 5] in `obs'
                replace CI90_UB = `placebo'[`i', 4] + `check_plot_z' * `placebo'[`i', 5] in `obs'
                replace source = 0 in `obs'  // 0 = placebo estimates
            }
        }
        
        sort time
    }
    
    // -------------------------------------------------------------------------
    // Set default values
    // -------------------------------------------------------------------------
    if `"`title'"' == "" local title ""
    if `"`xtitle'"' == "" local xtitle "Time"
    if `"`ytitle'"' == "" local ytitle "Estimates (`plot_level'% CI)"
    if "`name'" == "" local name "estimates_plot"
    
    // -------------------------------------------------------------------------
    // Handle single time point case (expand x-axis range)
    // -------------------------------------------------------------------------
    local xlim_opt ""
    quietly count
    if r(N) == 1 {
        quietly sum time
        local time_val = r(mean)
        local xlim_lb = `time_val' - 1
        local xlim_ub = `time_val' + 1
        local xlim_opt "xscale(range(`xlim_lb' `xlim_ub'))"
    }
    
    // -------------------------------------------------------------------------
    // Build options
    // -------------------------------------------------------------------------
    local scheme_opt ""
    if "`scheme'" != "" {
        local scheme_opt "scheme(`scheme')"
    }
    
    local title_opt ""
    if `"`title'"' != "" {
        local title_opt `"title(`"`title'"')"'
    }
    
    // -------------------------------------------------------------------------
    // Generate estimates plot
    // -------------------------------------------------------------------------
    // X-axis labels at unique time values
    quietly levelsof time, local(time_values)
    local xlabel_opt "xlabel(`time_values')"
    
    // Resolve colors for colorcheck mode
    if "`estcolor'" == "" local estcolor "navy"
    if "`checkcolor'" == "" local checkcolor "cranberry"
    
    if "`band'" != "" {
        if "`colorcheck'" != "" & "`usecheck'" != "" {
            // Band mode + colorcheck: two-color ribbon + connected lines
            twoway ///
                (rarea CI90_LB CI90_UB time if source == 0, ///
                    color(`checkcolor'%25) lwidth(none)) ///
                (connected estimate time if source == 0, ///
                    lcolor(`checkcolor') mcolor(`checkcolor') ///
                    lpattern(dash) msymbol(D) msize(small)) ///
                (rarea CI90_LB CI90_UB time if source == 1, ///
                    color(`estcolor'%25) lwidth(none)) ///
                (connected estimate time if source == 1, ///
                    lcolor(`estcolor') mcolor(`estcolor') ///
                    lpattern(solid) msymbol(O) msize(small)), ///
                yline(0, lpattern(dash) lcolor(gs10)) ///
                `title_opt' ///
                xtitle(`"`xtitle'"') ///
                ytitle(`"`ytitle'"') ///
                `xlabel_opt' ///
                `xlim_opt' ///
                legend(order(2 "Placebo Estimates" 4 "DID Estimates") ///
                    position(5) ring(0) cols(1) ///
                    region(lcolor(gs12) fcolor(white%80))) ///
                `scheme_opt' ///
                name(`name', replace)
        }
        else {
            // Band mode (default): single-color CI ribbon + connected line
            twoway (rarea CI90_LB CI90_UB time, color(gs8%50) lwidth(none)) ///
                   (connected estimate time, lcolor(black) mcolor(black) ///
                        lpattern(solid) msymbol(O)), ///
                   yline(0, lpattern(dash) lcolor(gs8)) ///
                   `title_opt' ///
                   xtitle(`"`xtitle'"') ///
                   ytitle(`"`ytitle'"') ///
                   `xlabel_opt' ///
                   `xlim_opt' ///
                   legend(off) ///
                   `scheme_opt' ///
                   name(`name', replace)
        }
    }
    else {
        if "`colorcheck'" != "" & "`usecheck'" != "" {
            // Error bar mode + colorcheck: two-color rcap + scatter
            twoway ///
                (rcap CI90_LB CI90_UB time if source == 0, ///
                    lcolor(`checkcolor') lwidth(medthin)) ///
                (scatter estimate time if source == 0, ///
                    mcolor(`checkcolor') msymbol(D) msize(small)) ///
                (rcap CI90_LB CI90_UB time if source == 1, ///
                    lcolor(`estcolor') lwidth(medthin)) ///
                (scatter estimate time if source == 1, ///
                    mcolor(`estcolor') msymbol(O) msize(small)), ///
                yline(0, lpattern(dash) lcolor(gs10)) ///
                `title_opt' ///
                xtitle(`"`xtitle'"') ///
                ytitle(`"`ytitle'"') ///
                `xlabel_opt' ///
                `xlim_opt' ///
                legend(order(2 "Placebo Estimates" 4 "DID Estimates") ///
                    position(5) ring(0) cols(1) ///
                    region(lcolor(gs12) fcolor(white%80))) ///
                `scheme_opt' ///
                name(`name', replace)
        }
        else {
            // Error bar mode (default): single-color error bars + scatter
            twoway (rcap CI90_LB CI90_UB time, lcolor(black) msize(vsmall)) ///
                   (scatter estimate time, mcolor(black) msymbol(O)), ///
                   yline(0, lpattern(dash) lcolor(gs8)) ///
                   `title_opt' ///
                   xtitle(`"`xtitle'"') ///
                   ytitle(`"`ytitle'"') ///
                   `xlabel_opt' ///
                   `xlim_opt' ///
                   legend(off) ///
                   `scheme_opt' ///
                   name(`name', replace)
        }
    }
    
    restore
    
end
