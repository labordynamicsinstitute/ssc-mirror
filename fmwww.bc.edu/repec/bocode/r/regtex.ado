*! regtex v3.8.7
*! Authors: 
*!   Wu Lianghai: agd2010@yeah.net, Anhui University of Technology (AHUT), Ma'anshan, China
*!   Wu Hanyan: 2325476320@qq.com, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China
*!   Wu Xinzhuo: 2957833979@qq.com, 
*!     Shenzhen MSU-BIT University (Undergraduate), 
*!     University of Bristol (Postgraduate),
*!     Shenzhen, China
*! Date: 2025-08-05 - Fixed modelnames parsing

program define regtex
    version 16
    syntax anything(name=model_list) [if] [in], SAVing(string) [ ///
        DECimal(integer 3) STARLevels(string) star(string) REPLace ///
        VCE(string) Title(string) threeline LANDscape ///  
        modelnames(string asis)]  // FIXED: Added (string asis)
    
    if `"`star'"' != "" {
        local starlevels `"`star'"'
    }
    
    // 检查是否提供了 modelnames
    local has_modelnames = (`"`modelnames'"' != "")
    
    if `"`starlevels'"' == "" local starlevels "0.10 0.05 0.01"
    local starlevels = subinstr(`"`starlevels'"', ",", " ", .)
    
    // Parse models
    local num_models = 0
    local models ""
    while `"`model_list'"' != "" {
        gettoken model model_list : model_list, parse(",:") bind
        if `"`model'"' == "," | `"`model'"' == ":" continue
        local ++num_models
        local models `"`models' `"`model'"'"'
    }
    
    // Handle model names - FIXED: Proper parsing with quotes
    if `has_modelnames' {
        // Count the number of quoted names
        local modelnames_list `"`modelnames'"'
        local modelnames_count = 0
        local modelnames_parsed ""
        
        while `"`modelnames_list'"' != "" {
            gettoken token modelnames_list : modelnames_list, parse(`"""') bind
            if `"`token'"' == `""""' continue
            if `"`token'"' != "" {
                local ++modelnames_count
                local modelnames_parsed `"`modelnames_parsed' `"`token'"'"'
            }
        }
        
        // Check if number of names matches number of models
        if `modelnames_count' != `num_models' {
            di as error "Number of model names (`modelnames_count') does not match number of models (`num_models')"
            exit 198
        }
        
        // Store parsed names
        forval i = 1/`modelnames_count' {
            local modelname`i' : word `i' of `modelnames_parsed'
        }
    }
    
    // Create temporary file handle
    tempname fh
    qui estimates clear
    local depvars ""
    local all_vars ""
    
    // Run all regression models
    forval m = 1/`num_models' {
        local model : word `m' of `models'
        
        // Professionally handle vce option
        if `"`vce'"' != "" {
            capture qui regress `model' `if' `in', vce(`vce')
            if _rc {
                di as error "Error in model `m': `model'"
                di as error "vce option: vce(`vce')"
                exit _rc
            }
        }
        else {
            capture qui regress `model' `if' `in'
            if _rc {
                di as error "Error in model `m': `model'"
                exit _rc
            }
        }
        
        estimates store model`m'
        gettoken depvar indep : model
        local depvars `depvars' `depvar'
        local vars : colnames e(b)
        local all_vars `all_vars' `vars'
    }
    
    // Get unique variable list
    local unique_vars : list uniq all_vars
    local clean_unique_vars ""
    foreach var in `unique_vars' {
        if "`var'" != "_cons" {
            local clean_unique_vars `clean_unique_vars' `var'
        }
    }
    local unique_vars `clean_unique_vars'
    
    // File handling
    if "`replace'" != "" capture erase `"`saving'"'
    file open `fh' using `"`saving'"', write text replace
    
    // LaTeX document header
    file write `fh' "\documentclass{article}" _n
    if "`landscape'" != "" {
        file write `fh' "\usepackage{pdflscape}" _n
    }
    file write `fh' "\usepackage{booktabs}" _n
    file write `fh' "\usepackage{threeparttable}" _n
    file write `fh' "\usepackage{multirow}" _n
    file write `fh' "\usepackage{amsmath}" _n
    file write `fh' "\usepackage[utf8]{inputenc}" _n
    file write `fh' "\usepackage[T1]{fontenc}" _n
    file write `fh' "\usepackage{siunitx}" _n
    file write `fh' "\sisetup{" _n
    file write `fh' "  group-separator = {,}," _n
    file write `fh' "  group-minimum-digits = 4," _n
    file write `fh' "  output-decimal-marker = {.}," _n
    file write `fh' "  exponent-product = \times" _n
    file write `fh' "}" _n
    file write `fh' "\begin{document}" _n
    
    // Landscape mode
    if "`landscape'" != "" {
        file write `fh' "\begin{landscape}" _n
    }
    
    // Table start
    file write `fh' "\begin{table}[htbp]" _n
    file write `fh' "\centering" _n
    if "`threeline'" != "" {
        file write `fh' "\begin{threeparttable}" _n
    }
    
    // Caption
    if `"`title'"' != "" {
        file write `fh' "\caption{`title'}" _n
    }
    
    // Table column format
    file write `fh' "\begin{tabular}{@{}l"
    forval i = 1/`num_models' {
        file write `fh' "c"
    }
    file write `fh' "@{}}" _n
    file write `fh' "\toprule" _n
    
    // Model names row - FIXED: Use parsed names
    file write `fh' " & "
    forval i = 1/`num_models' {
        if `has_modelnames' {
            local mname `"`modelname`i''"'
        }
        else {
            local mname ""
        }
        
        if `i' < `num_models' {
            file write `fh' "(`i') `mname' & "
        }
        else {
            file write `fh' "(`i') `mname' "
        }
    }
    file write `fh' " \\" _n
    file write `fh' "\midrule" _n
    
    // Dependent variable row
    file write `fh' "Dependent variable & "
    forval i = 1/`num_models' {
        local depvar : word `i' of `depvars'
        if `i' < `num_models' {
            file write `fh' "`depvar' & "
        }
        else {
            file write `fh' "`depvar' "
        }
    }
    file write `fh' " \\" _n
    file write `fh' "\midrule" _n
    
    // Variable coefficients and standard errors
    foreach var in `unique_vars' {
        local display_var = subinstr("`var'", "_", "\_", .)
        file write `fh' "`display_var' "
        
        forval m = 1/`num_models' {
            file write `fh' " & "
            
            qui estimates restore model`m'
            matrix b = e(b)
            matrix V = e(V)
            
            local found = 0
            if colnumb(b, "`var'") != . {
                local b_val = b[1, colnumb(b, "`var'")]
                local se_val = sqrt(V[colnumb(V, "`var'"), colnumb(V, "`var'")])
                local found = 1
            }
            
            if `found' {
                // Calculate significance
                local t = `b_val'/`se_val'
                local p = 2*(1 - normal(abs(`t')))
                
                local level1 = word("`starlevels'", 1)
                local level2 = word("`starlevels'", 2)
                local level3 = word("`starlevels'", 3)
                
                if `p' < `level3' {
                    local stars "$^{***}$"
                }
                else if `p' < `level2' {
                    local stars "$^{**}$"
                }
                else if `p' < `level1' {
                    local stars "$^{*}$"
                }
                else {
                    local stars ""
                }
                
                // Format coefficient value
                local coef_str = string(`b_val', "%20.`decimal'f")
                local coef_str = trim("`coef_str'")
                // Remove trailing zeros
                if strpos("`coef_str'", ".") > 0 {
                    while substr("`coef_str'", -1, 1) == "0" {
                        local coef_str = substr("`coef_str'", 1, length("`coef_str'")-1)
                    }
                    if substr("`coef_str'", -1, 1) == "." {
                        local coef_str = substr("`coef_str'", 1, length("`coef_str'")-1)
                    }
                }
                local coef_str = "`coef_str'`stars'"
                file write `fh' "`coef_str'"
            }
            else {
                file write `fh' " "
            }
        }
        file write `fh' " \\" _n
        
        // Standard error row
        file write `fh' " & "
        forval m = 1/`num_models' {
            if `m' > 1 file write `fh' " & "
            
            qui estimates restore model`m'
            matrix b = e(b)
            matrix V = e(V)
            
            if colnumb(b, "`var'") != . {
                local se_val = sqrt(V[colnumb(V, "`var'"), colnumb(V, "`var'")])
                
                // Format standard error
                local se_str = string(`se_val', "%20.`decimal'f")
                local se_str = trim("`se_str'")
                if strpos("`se_str'", ".") > 0 {
                    while substr("`se_str'", -1, 1) == "0" {
                        local se_str = substr("`se_str'", 1, length("`se_str'")-1)
                    }
                    if substr("`se_str'", -1, 1) == "." {
                        local se_str = substr("`se_str'", 1, length("`se_str'")-1)
                    }
                }
                local fmt_se = "(" + "`se_str'" + ")"
                file write `fh' "`fmt_se'"
            }
            else {
                file write `fh' " "
            }
        }
        file write `fh' " \\" _n
    }
    
    // Constant term
    file write `fh' "Constant "
    forval m = 1/`num_models' {
        file write `fh' " & "
        
        qui estimates restore model`m'
        matrix b = e(b)
        matrix V = e(V)
        
        local found = 0
        if colnumb(b, "_cons") != . {
            local b_val = b[1, colnumb(b, "_cons")]
            local se_val = sqrt(V[colnumb(V, "_cons"), colnumb(V, "_cons")])
            local found = 1
        }
        
        if `found' {
            // Calculate significance
            local t = `b_val'/`se_val'
            local p = 2*(1 - normal(abs(`t')))
            
            local level1 = word("`starlevels'", 1)
            local level2 = word("`starlevels'", 2)
            local level3 = word("`starlevels'", 3)
            
            if `p' < `level3' {
                local stars "$^{***}$"
            }
            else if `p' < `level2' {
                local stars "$^{**}$"
            }
            else if `p' < `level1' {
                local stars "$^{*}$"
            }
            else {
                local stars ""
            }
            
            // Format coefficient value
            local coef_str = string(`b_val', "%20.`decimal'f")
            local coef_str = trim("`coef_str'")
            if strpos("`coef_str'", ".") > 0 {
                while substr("`coef_str'", -1, 1) == "0" {
                    local coef_str = substr("`coef_str'", 1, length("`coef_str'")-1)
                }
                if substr("`coef_str'", -1, 1) == "." {
                    local coef_str = substr("`coef_str'", 1, length("`coef_str'")-1)
                }
            }
            local coef_str = "`coef_str'`stars'"
            file write `fh' "`coef_str'"
        }
        else {
            file write `fh' " "
        }
    }
    file write `fh' " \\" _n
    
    // Constant standard error
    file write `fh' " & "
    forval m = 1/`num_models' {
        if `m' > 1 file write `fh' " & "
        
        qui estimates restore model`m'
        matrix b = e(b)
        matrix V = e(V)
        
        if colnumb(b, "_cons") != . {
            local se_val = sqrt(V[colnumb(V, "_cons"), colnumb(V, "_cons")])
            
            // Format standard error
            local se_str = string(`se_val', "%20.`decimal'f")
            local se_str = trim("`se_str'")
            if strpos("`se_str'", ".") > 0 {
                while substr("`se_str'", -1, 1) == "0" {
                    local se_str = substr("`se_str'", 1, length("`se_str'")-1)
                }
                if substr("`se_str'", -1, 1) == "." {
                    local se_str = substr("`se_str'", 1, length("`se_str'")-1)
                }
            }
            local fmt_se = "(" + "`se_str'" + ")"
            file write `fh' "`fmt_se'"
        }
        else {
            file write `fh' " "
        }
    }
    file write `fh' " \\" _n
    
    // Model statistics
    file write `fh' "\midrule" _n
    file write `fh' "Observations"
    forval m = 1/`num_models' {
        qui estimates restore model`m'
        file write `fh' " & `e(N)'"
    }
    file write `fh' " \\" _n
    
    file write `fh' "R-squared"
    forval m = 1/`num_models' {
        qui estimates restore model`m'
        local r2 = e(r2)
        
        // Format R-squared value
        local r2_str = string(`r2', "%20.`decimal'f")
        local r2_str = trim("`r2_str'")
        if strpos("`r2_str'", ".") > 0 {
            while substr("`r2_str'", -1, 1) == "0" {
                local r2_str = substr("`r2_str'", 1, length("`r2_str'")-1)
            }
            if substr("`r2_str'", -1, 1) == "." {
                local r2_str = substr("`r2_str'", 1, length("`r2_str'")-1)
            }
        }
        file write `fh' " & `r2_str'"
    }
    file write `fh' " \\" _n
    
    // End table
    file write `fh' "\bottomrule" _n
    file write `fh' "\end{tabular}" _n
    
    // Table note
    if "`threeline'" != "" {
        local level1 = word("`starlevels'",1)
        local level2 = word("`starlevels'",2)
        local level3 = word("`starlevels'",3)
        
        file write `fh' "\begin{tablenotes}" _n
        file write `fh' "\small" _n
        file write `fh' "\item \textit{Notes:} Standard errors in parentheses; " ///
            "*** p<`level3', ** p<`level2', * p<`level1'" _n
        file write `fh' "\end{tablenotes}" _n
        file write `fh' "\end{threeparttable}" _n
    }
    
    file write `fh' "\end{table}" _n
    
    // End landscape mode
    if "`landscape'" != "" {
        file write `fh' "\end{landscape}" _n
    }
    
    // End document
    file write `fh' "\end{document}" _n
    file close `fh'
    
    // User feedback
    di as text _n `"LaTeX table saved to {browse "`saving'":`saving'}"'
    di as text "Number of models: `num_models'"
    di as text "Star levels: `starlevels'"
    di as text "Authors: Wu Lianghai (AHUT), Wu Hanyan (NUAA), Wu Xinzhuo (Shenzhen MSU-BIT & Bristol)"
end