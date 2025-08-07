*! sumtex.ado
*! Author: WU Lianghai/Yang Lu (AHUT, Anhui University of Technology)
*! Version: 5.5.3
*! Date: 2025-08-05
*! Generate publication-ready descriptive statistics tables in LaTeX format

program define sumtex
    version 16
    syntax [varlist] , SAVing(string) [STATs(string)] [FMT(string)] [ROTate] [REPlace] [TItle(string)] [THREEline] [LANDscape]
    
    // Set default format and statistics if not specified
    if "`fmt'" == "" local fmt "%9.3f"
    if "`stats'" == "" local stats "mean sd min max p50"
    local three = cond("`threeline'" != "", "booktabs", "")
    
    // Enable landscape mode if requested
    if "`rotate'" != "" | "`landscape'" != "" local landscape "landscape"
    
    // Get numeric variables
    if "`varlist'" == "" {
        quietly ds, has(type numeric)
        local varlist `r(varlist)'
    }
    else {
        local numeric_vars ""
        foreach var of local varlist {
            capture confirm numeric variable `var'
            if !_rc local numeric_vars `numeric_vars' `var'
        }
        local varlist `numeric_vars'
    }
    
    // Exit if no numeric variables found
    if "`varlist'" == "" {
        di as error "No numeric variables found"
        exit 111
    }
    
    // Validate format string
    if !regexm("`fmt'", "^%[0-9]+\.?[0-9]*[a-z]$") {
        di as error "Invalid format string: `fmt'. Using default format %9.3f"
        local fmt "%9.3f"
    }
    
    // Prepare output file
    if "`replace'" != "" capture erase "`saving'"
    tempname fh
    file open `fh' using "`saving'", write text replace
    
    // LaTeX document header
    file write `fh' "\documentclass{article}" _n
    file write `fh' "\usepackage{geometry}" _n
    if "`three'" != "" file write `fh' "\usepackage{booktabs}" _n
    file write `fh' "\usepackage{multirow}" _n
    file write `fh' "\usepackage{array}" _n
    if "`landscape'" != "" {
        file write `fh' "\usepackage{pdflscape}" _n
        file write `fh' "\geometry{a4paper, landscape, margin=1cm}" _n
    }
    else file write `fh' "\geometry{a4paper, margin=2cm}" _n
    file write `fh' "\begin{document}" _n
    if "`landscape'" != "" file write `fh' "\begin{landscape}" _n
    
    // Table environment
    file write `fh' "\begin{table}[htbp]" _n
    file write `fh' "\centering" _n
    if "`title'" != "" file write `fh' "\caption{`title'}" _n
    file write `fh' "\label{tab:descriptives}" _n
    
    // Prepare matrix for statistics
    local stat_count = wordcount("`stats'")
    local var_count : word count `varlist'
    matrix stats = J(`var_count', `stat_count', .)
    
    // Store variable labels
    forvalues i = 1/`var_count' {
        local var : word `i' of `varlist'
        local varlabel_`i' : variable label `var'
        if "`varlabel_`i''" == "" local varlabel_`i' "`var'"
    }
    
    // Create and store statistic labels
    forvalues k = 1/`stat_count' {
        local stat : word `k' of `stats'
        if "`stat'" == "mean"      local statlab "Mean"
        if "`stat'" == "sd"        local statlab "Std. Dev."
        if "`stat'" == "min"       local statlab "Min"
        if "`stat'" == "max"       local statlab "Max"
        if "`stat'" == "p50"       local statlab "Median"
        if "`stat'" == "count"     local statlab "N"
        if "`stat'" == "sum"       local statlab "Sum"
        if "`stat'" == "var"       local statlab "Variance"
        if "`stat'" == "cv"        local statlab "CV"
        if "`stat'" == "semean"    local statlab "SE Mean"
        if "`stat'" == "skewness"  local statlab "Skewness"
        if "`stat'" == "kurtosis"  local statlab "Kurtosis"
        if "`stat'" == "p1"        local statlab "P1"
        if "`stat'" == "p5"        local statlab "P5"
        if "`stat'" == "p10"       local statlab "P10"
        if "`stat'" == "p25"       local statlab "P25"
        if "`stat'" == "p75"       local statlab "P75"
        if "`stat'" == "p90"       local statlab "P90"
        if "`stat'" == "p95"       local statlab "P95"
        if "`stat'" == "p99"       local statlab "P99"
        
        // Escape special characters
        local statlab = subinstr(`"`statlab'"', "&", "\&", .)
        local statlab = subinstr(`"`statlab'"', "_", "\_", .)
        local statlab = subinstr(`"`statlab'"', "%", "\%", .)
        local statlab = subinstr(`"`statlab'"', "$", "\$", .)
        local statlab = subinstr(`"`statlab'"', "#", "\#", .)
        local statlab = subinstr(`"`statlab'"', "{", "\{", .)
        local statlab = subinstr(`"`statlab'"', "}", "\}", .)
        local statlab = subinstr(`"`statlab'"', "^", "\^{}", .)
        local statlab = subinstr(`"`statlab'"', "~", "\~{}", .)
        
        local statlab_`k' `"`statlab'"'
    }
    
    // Calculate statistics for each variable
    local i = 0
    foreach var of local varlist {
        local i = `i' + 1
        quietly summarize `var', detail
        local j = 0
        foreach stat of local stats {
            local j = `j' + 1
            local value = .
            
            // Retrieve statistic value
            if "`stat'" == "mean"      local value = r(mean)
            if "`stat'" == "sd"        local value = r(sd)
            if "`stat'" == "min"       local value = r(min)
            if "`stat'" == "max"       local value = r(max)
            if "`stat'" == "p50"       local value = r(p50)
            if "`stat'" == "count"     local value = r(N)
            if "`stat'" == "sum"       local value = r(sum)
            if "`stat'" == "var"       local value = r(Var)
            if "`stat'" == "cv"        & r(mean) != 0 local value = 100 * r(sd) / r(mean)
            if "`stat'" == "semean"    local value = r(sd) / sqrt(r(N))
            if "`stat'" == "skewness"  local value = r(skewness)
            if "`stat'" == "kurtosis"  local value = r(kurtosis)
            if "`stat'" == "p1"        local value = r(p1)
            if "`stat'" == "p5"        local value = r(p5)
            if "`stat'" == "p10"       local value = r(p10)
            if "`stat'" == "p25"       local value = r(p25)
            if "`stat'" == "p75"       local value = r(p75)
            if "`stat'" == "p90"       local value = r(p90)
            if "`stat'" == "p95"       local value = r(p95)
            if "`stat'" == "p99"       local value = r(p99)
            
            matrix stats[`i', `j'] = `value'
        }
    }
    
    // Generate table
    if "`rotate'" == "" {
        // Default layout: variables in rows, stats in columns
        file write `fh' "\begin{tabular}{l*{`stat_count'}{c}}" _n
        
        // Table header
        if "`three'" != "" file write `fh' "\toprule" _n
        else file write `fh' "\hline" _n
        
        file write `fh' "Variable"
        forval k = 1/`stat_count' {
            file write `fh' " & `statlab_`k''"
        }
        file write `fh' " \\" _n
        
        if "`three'" != "" file write `fh' "\midrule" _n
        else file write `fh' "\hline" _n
        
        // Table body
        forvalues i = 1/`var_count' {
            local varlabel `"`varlabel_`i''"'
            
            // Escape LaTeX special characters in variable labels
            local varlabel = subinstr(`"`varlabel'"', "_", "\_", .)
            local varlabel = subinstr(`"`varlabel'"', "&", "\&", .)
            local varlabel = subinstr(`"`varlabel'"', "%", "\%", .)
            local varlabel = subinstr(`"`varlabel'"', "$", "\$", .)
            local varlabel = subinstr(`"`varlabel'"', "#", "\#", .)
            local varlabel = subinstr(`"`varlabel'"', "{", "\{", .)
            local varlabel = subinstr(`"`varlabel'"', "}", "\}", .)
            local varlabel = subinstr(`"`varlabel'"', "^", "\^{}", .)
            local varlabel = subinstr(`"`varlabel'"', "~", "\~{}", .)
            
            file write `fh' "`varlabel'"
            
            forvalues j = 1/`stat_count' {
                local val = stats[`i', `j']
                local current_stat: word `j' of `stats'
                
                if !missing(`val') {
                    // Special formatting for count statistic
                    if "`current_stat'" == "count" {
                        local valstr: display %12.0f `val'
                    }
                    else {
                        local valstr: display `fmt' `val'
                    }
                    file write `fh' " & `valstr'"
                }
                else file write `fh' " & -- "
            }
            file write `fh' " \\" _n
        }
        
        // Table footer
        if "`three'" != "" file write `fh' "\bottomrule" _n
        else file write `fh' "\hline" _n
    }
    else {
        // Rotated layout: variables in columns, stats in rows
        file write `fh' "\begin{tabular}{l*{`var_count'}{c}}" _n
        
        // Table header
        if "`three'" != "" file write `fh' "\toprule" _n
        else file write `fh' "\hline" _n
        
        file write `fh' "Statistic"
        forvalues i = 1/`var_count' {
            local varlabel `"`varlabel_`i''"'
            
            // Escape LaTeX special characters in variable labels
            local varlabel = subinstr(`"`varlabel'"', "_", "\_", .)
            local varlabel = subinstr(`"`varlabel'"', "&", "\&", .)
            local varlabel = subinstr(`"`varlabel'"', "%", "\%", .)
            local varlabel = subinstr(`"`varlabel'"', "$", "\$", .)
            local varlabel = subinstr(`"`varlabel'"', "#", "\#", .)
            local varlabel = subinstr(`"`varlabel'"', "{", "\{", .)
            local varlabel = subinstr(`"`varlabel'"', "}", "\}", .)
            local varlabel = subinstr(`"`varlabel'"', "^", "\^{}", .)
            local varlabel = subinstr(`"`varlabel'"', "~", "\~{}", .)
            
            file write `fh' " & `varlabel'"
        }
        file write `fh' " \\" _n
        
        if "`three'" != "" file write `fh' "\midrule" _n
        else file write `fh' "\hline" _n
        
        // Table body
        forval k = 1/`stat_count' {
            file write `fh' "`statlab_`k''"
            
            forvalues i = 1/`var_count' {
                local val = stats[`i', `k']
                local current_stat: word `k' of `stats'
                
                if !missing(`val') {
                    // Special formatting for count statistic
                    if "`current_stat'" == "count" {
                        local valstr: display %12.0f `val'
                    }
                    else {
                        local valstr: display `fmt' `val'
                    }
                    file write `fh' " & `valstr'"
                }
                else file write `fh' " & -- "
            }
            file write `fh' " \\" _n
        }
        
        // Table footer
        if "`three'" != "" file write `fh' "\bottomrule" _n
        else file write `fh' "\hline" _n
    }
    
    // End table
    file write `fh' "\end{tabular}" _n
    file write `fh' "\end{table}" _n
    
    // Document footer
    if "`landscape'" != "" file write `fh' "\end{landscape}" _n
    file write `fh' "\end{document}" _n
    file close `fh'
    
    // User feedback
    di _n as text `"LaTeX document saved to "' as result `"`saving'"'
    di as text `"Compile with: TeXworks (Open the file and generate PDF with one click)"'
end