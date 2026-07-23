*! version 2.4.6
*! ntables: Advanced journal-level publication-ready tables
*! Author: Ajay Kumar Samariya, Noterva, India
*! Support: notervaindia@gmail.com

program define ntables, rclass
    version 16.0
    
    // Capture r() before anything clears it
    local r_Zt = r(Zt)
    local r_z  = r(z)
    local r_t  = r(t)
    local r_p  = r(p)
    
    // -------------------------------------------------------------
    // PREFIX PARSING
    // Check if a colon is present for hybrid prefix syntax
    capture _on_colon_parse `0'
    if _rc == 0 {
        local ntables_args `s(before)'
        local stata_cmd `s(after)'
        local 0 `ntables_args'
    }
    else {
        local stata_cmd ""
    }
    // -------------------------------------------------------------

    syntax [anything] [using/] [if] [in] [, ///
        Method(string) /// Method: Stata, PLS-SEM, SPSS, AMOS
        Test(string) /// Override test auto-detection: reg, sum, corr, unitroot, tab, desc, rf
        Format(string) /// Output format: DOCX, XLSX, HTML, CSV
        Append /// Append to existing file
        Replace /// Replace existing file
        Title(string) /// Table Title
        noHEADer /// Suppress title
        Dec(integer 3) /// Decimal places
        SE /// Report Standard Errors (default)
        TSTAT /// Report t-statistics instead of SE
        PVALS /// Report p-values in parentheses (especially for correlations)
        MODels(string) /// Space-separated list of stored estimates (e.g. m1 m2 m3)
        Keep(string) /// Variables to keep
        Drop(string) /// Variables to drop
        Label /// Use variable labels instead of names
        STAR(string) /// Custom significance levels (e.g. 0.10 0.05 0.01)
        ADDNote(string) /// Custom note to add at the bottom
        STATS(string) /// Summary stats to include (e.g. N r2 F p rmse)
        * ///
    ]
    
    // Default options
    if "`method'" == "" local method "Stata"
    if "`format'" == "" local format "DOCX"
    
    local mode "w"
    if "`append'" != "" local mode "a"
    
    if "`using'" == "" {
        local using "ntables_output.`format'"
    }
    local fmt = lower("`format'")
    
    local ntables_version "2.4.6"
    di as txt "{hline 70}"
    di as res "Noterva Tables (ntables) v`ntables_version' - `method' to `format'"
    di as txt "Exporting to: `using'"
    di as txt "{hline 70}"
    
    // Execute Prefix Command if present
    if "`stata_cmd'" != "" {
        local cmdname : word 1 of `stata_cmd'
        local cmdname = trim("`cmdname'")
        
        // Auto-detect test based on prefix command
        if "`test'" == "" {
            if "`cmdname'" == "tabulate" | "`cmdname'" == "tab" | "`cmdname'" == "tab1" | "`cmdname'" == "tab2" {
                local test "tab"
            }
            else if "`cmdname'" == "describe" | "`cmdname'" == "desc" | "`cmdname'" == "codebook" {
                local test "desc"
            }
            else if "`cmdname'" == "rforest" {
                local test "rf"
            }
            else if "`cmdname'" == "dfuller" | "`cmdname'" == "pperron" | "`cmdname'" == "kpss" {
                local test "unitroot"
            }
        }
        
        // Execute the command natively (unless it's tabulate/desc, which must be handled by the module)
        if "`test'" != "tab" & "`test'" != "desc" {
            capture quietly `stata_cmd'
            if _rc {
                di as err "Command execution failed: `stata_cmd'"
                exit _rc
            }
            local r_Zt = r(Zt)
            local r_z  = r(z)
            local r_t  = r(t)
            local r_p  = r(p)
        }
    }
    
    // Auto-detect test type from memory if still not specified
    if "`test'" == "" {
        if "`models'" != "" {
            local test "reg"
        }
        else if "`r(cmd)'" == "summarize" {
            local test "sum"
        }
        else if "`r(cmd)'" == "correlate" | "`r(cmd)'" == "pwcorr" {
            local test "corr"
        }
        else if "`e(cmd)'" != "" {
            if "`e(cmd)'" == "rforest" local test "rf"
            else local test "reg"
        }
        else {
            di as err "No estimation or returned results found. Please run a model or specify test()."
            exit 301
        }
    }
    
    di as txt "Test Mode Detected: `test'"
    
    local tflag = ""
    // syntax noHEADer stores its value in `header'; accept either spelling
    if "`header'" != "" | "`noheader'" != "" local tflag "suppresshead"
    // backward compatibility: notitle was renamed to noheader in 2.4.4
    if strpos(lower("`options'"), "notitle") > 0 {
        di as txt "note: option {bf:notitle} is deprecated; use {bf:noheader}."
        local tflag "suppresshead"
    }
    local labelflag = ""
    if "`label'" != "" local labelflag "label"
    if "`title'" == "" {
        if "`test'" == "tab" local title "Cross-Tabulation"
        else if "`test'" == "desc" local title "Data Codebook"
        else if "`test'" == "rf" local title "Random Forest: Variable Importance"
        else local title "Table 1: Estimation Results"
    }
    local pvalsflag = ""
    if "`pvals'" != "" local pvalsflag "pvals"
    
    // Route to appropriate module
    if "`test'" == "reg" {
        ntables_reg `anything', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') models("`models'") ///
            keep("`keep'") drop("`drop'") `labelflag' star("`star'") addnote("`addnote'") stats("`stats'") `replace' `append'
    }
    else if "`test'" == "sum" {
        ntables_sum `anything', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') ///
            keep("`keep'") drop("`drop'") `labelflag' addnote("`addnote'") `replace' `append'
    }
    else if "`test'" == "corr" {
        ntables_corr `anything', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') `pvalsflag' ///
            keep("`keep'") drop("`drop'") `labelflag' star("`star'") addnote("`addnote'") `replace' `append'
    }
    else if "`test'" == "unitroot" {
        ntables_unitroot `anything', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') ///
            star("`star'") addnote("`addnote'") rzt("`r_Zt'") rz("`r_z'") rt("`r_t'") rp("`r_p'") `replace' `append'
    }
    else if "`test'" == "tab" {
        ntables_tab `"`stata_cmd'"', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') ///
            `labelflag' addnote("`addnote'") `replace' `append'
    }
    else if "`test'" == "desc" {
        ntables_desc `"`stata_cmd'"', fmt("`fmt'") using("`using'") title("`title'") `tflag' ///
            addnote("`addnote'") `replace' `append'
    }
    else if "`test'" == "rf" {
        ntables_rf `anything', fmt("`fmt'") using("`using'") title("`title'") `tflag' dec(`dec') ///
            `labelflag' addnote("`addnote'") `replace' `append'
    }
    else {
        di as err "Test mode `test' is not currently supported natively by this routing script."
        exit 198
    }

end

// --------------------------------------------------------------------------------
// Module: Codebook / Describe
// --------------------------------------------------------------------------------
program define ntables_desc
    syntax anything(name=cmd_str), fmt(string) using(string) title(string) [suppresshead addnote(string) replace append]
    
    local using_file "`using'"
    local 0 `cmd_str'
    gettoken tabcmd 0 : 0
    syntax [varlist]
    local using "`using_file'"
    
    if "`varlist'" == "" {
        quietly ds
        local varlist "`r(varlist)'"
    }
    
    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        local num_vars : word count `varlist'
        local rows = `num_vars' + 1
        putdocx table results = (`rows', 4), border(all, nil) border(top, single) border(bottom, single)
        putdocx table results(1, 1) = ("Variable"), border(bottom, single) bold
        putdocx table results(1, 2) = ("Type"), border(bottom, single) bold halign(center)
        putdocx table results(1, 3) = ("Format"), border(bottom, single) bold halign(center)
        putdocx table results(1, 4) = ("Label"), border(bottom, single) bold
        local r = 2
        foreach v of local varlist {
            local vtype : type `v'
            local vfmt : format `v'
            local vlbl : variable label `v'
            putdocx table results(`r', 1) = ("`v'")
            putdocx table results(`r', 2) = ("`vtype'"), halign(center)
            putdocx table results(`r', 3) = ("`vfmt'"), halign(center)
            putdocx table results(`r', 4) = ("`vlbl'")
            local r = `r' + 1
        }
        if "`addnote'" != "" {
            putdocx paragraph
            putdocx text ("Note: `addnote'")
        }
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Variable"), bold border(bottom)
        putexcel B`base_r' = ("Type"), bold border(bottom) hcenter
        putexcel C`base_r' = ("Format"), bold border(bottom) hcenter
        putexcel D`base_r' = ("Label"), bold border(bottom)
        local r = `base_r' + 1
        foreach v of local varlist {
            local vtype : type `v'
            local vfmt : format `v'
            local vlbl : variable label `v'
            putexcel A`r' = ("`v'")
            putexcel B`r' = ("`vtype'"), hcenter
            putexcel C`r' = ("`vfmt'"), hcenter
            putexcel D`r' = ("`vlbl'")
            local r = `r' + 1
        }
        if "`addnote'" != "" {
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        file write `fh' "Variable,Type,Format,Label" _n
        foreach v of local varlist {
            local vtype : type `v'
            local vfmt : format `v'
            local vlbl : variable label `v'
            file write `fh' `""`v'","`vtype'","`vfmt'","`vlbl'""' _n
        }
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        file write `fh' "<tr><th>Variable</th><th>Type</th><th>Format</th><th>Label</th></tr>" _n
        foreach v of local varlist {
            local vtype : type `v'
            local vfmt : format `v'
            local vlbl : variable label `v'
            file write `fh' "<tr><td>`v'</td><td>`vtype'</td><td>`vfmt'</td><td>`vlbl'</td></tr>" _n
        }
        file write `fh' "</table>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end

// --------------------------------------------------------------------------------
// Module: Summary Statistics
// --------------------------------------------------------------------------------
program define ntables_sum
    syntax [anything], fmt(string) using(string) title(string) dec(integer) [keep(string) drop(string) label suppresshead addnote(string) replace append]
    
    if "`anything'" != "" local vars "`anything'"
    else {
        quietly ds, has(type numeric)
        local vars "`r(varlist)'"
    }
    
    // Robust Keep/Drop logic
    local final_vars ""
    foreach v of local vars {
        local in_drop : list posof "`v'" in drop
        local in_keep : list posof "`v'" in keep
        if `in_drop' == 0 {
            if "`keep'" == "" | `in_keep' > 0 {
                local final_vars "`final_vars' `v'"
            }
        }
    }
    local vars "`final_vars'"

    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        local n_vars : word count `vars'
        local rows = `n_vars' + 1
        putdocx table results = (`rows', 6), border(all, nil) border(top, single) border(bottom, single)
        putdocx table results(1, 1) = ("Variable"), border(bottom, single) bold
        putdocx table results(1, 2) = ("Obs"), border(bottom, single) bold halign(center)
        putdocx table results(1, 3) = ("Mean"), border(bottom, single) bold halign(center)
        putdocx table results(1, 4) = ("Std. Dev."), border(bottom, single) bold halign(center)
        putdocx table results(1, 5) = ("Min"), border(bottom, single) bold halign(center)
        putdocx table results(1, 6) = ("Max"), border(bottom, single) bold halign(center)
        
        local r = 2
        foreach v of local vars {
            capture quietly summarize `v'
            if _rc == 0 {
                local display_var "`v'"
                if "`label'" != "" {
                    capture local lbl : variable label `v'
                    if "`lbl'" != "" local display_var "`lbl'"
                }
                putdocx table results(`r', 1) = ("`display_var'")
                putdocx table results(`r', 2) = ("`r(N)'"), halign(center)
                local mean : display %9.`dec'f r(mean)
                putdocx table results(`r', 3) = ("`mean'"), halign(center)
                local sd : display %9.`dec'f r(sd)
                putdocx table results(`r', 4) = ("`sd'"), halign(center)
                local min : display %9.`dec'f r(min)
                putdocx table results(`r', 5) = ("`min'"), halign(center)
                local max : display %9.`dec'f r(max)
                putdocx table results(`r', 6) = ("`max'"), halign(center)
                local r = `r' + 1
            }
        }
        if "`addnote'" != "" {
            putdocx paragraph
            putdocx text ("Note: `addnote'")
        }
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        file write `fh' "Variable,Obs,Mean,Std. Dev.,Min,Max" _n
        foreach v of local vars {
            capture quietly summarize `v'
            if _rc == 0 {
                local display_var "`v'"
                if "`label'" != "" {
                    capture local lbl : variable label `v'
                    if "`lbl'" != "" local display_var "`lbl'"
                }
                local mean : display %9.`dec'f r(mean)
                local sd : display %9.`dec'f r(sd)
                local min : display %9.`dec'f r(min)
                local max : display %9.`dec'f r(max)
                file write `fh' `""`display_var'",`r(N)',`mean',`sd',`min',`max'"' _n
            }
        }
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        file write `fh' "<tr><th>Variable</th><th>Obs</th><th>Mean</th><th>Std. Dev.</th><th>Min</th><th>Max</th></tr>" _n
        foreach v of local vars {
            capture quietly summarize `v'
            if _rc == 0 {
                local display_var "`v'"
                if "`label'" != "" {
                    capture local lbl : variable label `v'
                    if "`lbl'" != "" local display_var "`lbl'"
                }
                local mean : display %9.`dec'f r(mean)
                local sd : display %9.`dec'f r(sd)
                local min : display %9.`dec'f r(min)
                local max : display %9.`dec'f r(max)
                file write `fh' "<tr><td>`display_var'</td><td>`r(N)'</td><td>`mean'</td><td>`sd'</td><td>`min'</td><td>`max'</td></tr>" _n
            }
        }
        file write `fh' "</table>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Variable"), bold border(bottom)
        putexcel B`base_r' = ("Obs"), bold border(bottom) hcenter
        putexcel C`base_r' = ("Mean"), bold border(bottom) hcenter
        putexcel D`base_r' = ("Std. Dev."), bold border(bottom) hcenter
        putexcel E`base_r' = ("Min"), bold border(bottom) hcenter
        putexcel F`base_r' = ("Max"), bold border(bottom) hcenter
        
        local r = `base_r' + 1
        foreach v of local vars {
            capture quietly summarize `v'
            if _rc == 0 {
                local display_var "`v'"
                if "`label'" != "" {
                    capture local lbl : variable label `v'
                    if "`lbl'" != "" local display_var "`lbl'"
                }
                local mean : display %9.`dec'f r(mean)
                local sd : display %9.`dec'f r(sd)
                local min : display %9.`dec'f r(min)
                local max : display %9.`dec'f r(max)
                putexcel A`r' = ("`display_var'")
                putexcel B`r' = (`r(N)'), hcenter
                putexcel C`r' = (`mean'), hcenter
                putexcel D`r' = (`sd'), hcenter
                putexcel E`r' = (`min'), hcenter
                putexcel F`r' = (`max'), hcenter
                local r = `r' + 1
            }
        }
        if "`addnote'" != "" {
            putexcel A`r' = ("Note: `addnote'")
        }
    }
end

// --------------------------------------------------------------------------------
// Module: Regression & Lasso
// --------------------------------------------------------------------------------
program define ntables_reg
    syntax [anything], fmt(string) using(string) title(string) dec(integer) [suppresshead models(string) keep(string) drop(string) label star(string) addnote(string) stats(string) replace append]
    
    local s1 = 0.10
    local s2 = 0.05
    local s3 = 0.01
    if "`star'" != "" {
        tokenize "`star'"
        if "`1'" != "" local s1 = `1'
        if "`2'" != "" local s2 = `2'
        if "`3'" != "" local s3 = `3'
    }
    
    capture confirm matrix e(b)
    if _rc {
        di as err "No estimation results found (e(b) matrix missing). Please run a model first."
        exit 301
    }
    
    tempname b V
    matrix `b' = e(b)
    capture matrix `V' = e(V)
    local has_V = (_rc == 0)
    // set to 1 only if at least one usable standard error is produced;
    // e(V) can exist but be degenerate (e.g. lasso), so has_V is not enough
    local any_se = 0
    
    local names : colnames `b'
    
    // Robust Keep/Drop logic
    local final_names ""
    foreach v of local names {
        local in_drop : list posof "`v'" in drop
        local in_keep : list posof "`v'" in keep
        if `in_drop' == 0 {
            if "`keep'" == "" | `in_keep' > 0 {
                local final_names "`final_names' `v'"
            }
        }
    }
    local names "`final_names'"

    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        
        if "`models'" == "" {
            local n_vars : word count `names'
            if `has_V' {
                local rows = `n_vars' * 2 + 3
            }
            else {
                local rows = `n_vars' + 3
            }
            if "`stats'" == "" local stats "N r2"
            local n_stats : word count `stats'
            local rows = `rows' + `n_stats' - 2 
            
            putdocx table results = (`rows', 2), border(all, nil) border(top, single) border(bottom, single)
            putdocx table results(1, 1) = ("Variables"), border(bottom, single) bold
            putdocx table results(1, 2) = ("Coefficient"), border(bottom, single) bold halign(center)
            
            local r = 2
            local all_names : colnames `b'
            foreach var of local names {
                local v_idx = 0
                local k = 1
                foreach nv of local all_names {
                    if "`nv'" == "`var'" local v_idx = `k'
                    local k = `k' + 1
                }
                
                if `v_idx' > 0 {
                    local coef = `b'[1, `v_idx']
                    local coef_str : display %9.`dec'f `coef'
                    local coef_str = trim("`coef_str'")
                    
                    local se_str "-"
                    local star_sym ""
                    if `has_V' {
                        local se = sqrt(`V'[`v_idx', `v_idx'])
                        if `se' > 0 & `se' != . {
                            local t = `coef' / `se'
                            local p = .
                            capture local df = e(df_r)
                            if _rc == 0 & "`df'" != "." & "`df'" != "" {
                                local p = 2 * ttail(`df', abs(`t'))
                            }
                            else {
                                local p = 2 * normal(-abs(`t'))
                            }
                            if `p' < `s3' local star_sym "***"
                            else if `p' < `s2' local star_sym "**"
                            else if `p' < `s1' local star_sym "*"
                            local se_str : display %9.`dec'f `se'
                            local se_str = trim("`se_str'")
                            local any_se = 1
                        }
                    }
                    
                    local display_var "`var'"
                    if "`label'" != "" {
                        if "`var'" == "_cons" local display_var "Constant"
                        else {
                            capture local lbl : variable label `var'
                            if "`lbl'" != "" local display_var "`lbl'"
                        }
                    }
                    putdocx table results(`r', 1) = ("`display_var'")
                    putdocx table results(`r', 2) = ("`coef_str'`star_sym'"), halign(center)
                    local r = `r' + 1
                    if "`se_str'" != "-" {
                        putdocx table results(`r', 2) = ("(`se_str')"), halign(center)
                        local r = `r' + 1
                    }
                }
            }
            
            foreach st of local stats {
                local stat_val = e(`st')
                if "`stat_val'" == "." | "`stat_val'" == "" local stat_val = r(`st')
                if "`stat_val'" != "." & "`stat_val'" != "" {
                    local display_stat "`st'"
                    if "`st'" == "N" local display_stat "Observations"
                    else if "`st'" == "r2" local display_stat "R-squared"
                    else if "`st'" == "r2_a" local display_stat "Adjusted R-squared"
                    else if "`st'" == "F" local display_stat "F-statistic"
                    else if "`st'" == "p" local display_stat "Prob > F"
                    local stat_str : display %9.`dec'f `stat_val'
                    local stat_str = trim("`stat_str'")
                    if "`st'" == "N" local stat_str "`stat_val'" 
                    putdocx table results(`r', 1) = ("`display_stat'")
                    putdocx table results(`r', 2) = ("`stat_str'"), halign(center)
                    local r = `r' + 1
                }
            }
            putdocx paragraph
            if `any_se' {
                if "`addnote'" != "" putdocx text ("Note: * p<`s1', ** p<`s2', *** p<`s3'. `addnote'")
                else putdocx text ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
            }
            else {
                if "`addnote'" != "" putdocx text ("Note: `addnote'")
            }
            if "`append'" != "" putdocx save "`using'", append
            else putdocx save "`using'", replace
        }
        else {
            // SIDE-BY-SIDE logic
            local num_models : word count `models'
            local cols = `num_models' + 1
            
            // Build universal variable list
            local all_vars ""
            forvalues i = 1/`num_models' {
                local m : word `i' of `models'
                quietly estimates restore `m'
                tempname b`i' V`i'
                matrix `b`i'' = e(b)
                capture matrix `V`i'' = e(V)
                local m_vars : colnames `b`i''
                foreach v of local m_vars {
                    local found : list posof "`v'" in all_vars
                    if `found' == 0 {
                        local all_vars "`all_vars' `v'"
                    }
                }
            }
            
            // Apply drop
            if "`drop'" != "" {
                local final_vars ""
                foreach v of local all_vars {
                    local in_drop : list posof "`v'" in drop
                    if `in_drop' == 0 {
                        local final_vars "`final_vars' `v'"
                    }
                }
                local all_vars "`final_vars'"
            }
            
            // Apply keep
            if "`keep'" != "" {
                local final_vars ""
                foreach v of local all_vars {
                    local in_keep : list posof "`v'" in keep
                    if `in_keep' > 0 {
                        local final_vars "`final_vars' `v'"
                    }
                }
                local all_vars "`final_vars'"
            }
            
            // Reorder _cons to the end
            local has_cons = 0
            local final_vars ""
            foreach v of local all_vars {
                if "`v'" == "_cons" {
                    local has_cons = 1
                }
                else {
                    local final_vars "`final_vars' `v'"
                }
            }
            if `has_cons' == 1 {
                local final_vars "`final_vars' _cons"
            }
            local all_vars "`final_vars'"
            
            if "`stats'" == "" local stats "N r2"

            local n_stats : word count `stats'
            
            local n_vars : word count `all_vars'
            local rows = `n_vars' * 2 + 1 + `n_stats'
            
            putdocx table results = (`rows', `cols'), border(all, nil) border(top, single) border(bottom, single)
            putdocx table results(1, 1) = ("Variables"), border(bottom, single) bold
            
            local c = 2
            foreach m of local models {
                putdocx table results(1, `c') = ("(`m')"), border(bottom, single) bold halign(center)
                local c = `c' + 1
            }
            
            local r = 2
            foreach var of local all_vars {
                local display_var "`var'"
                if "`label'" != "" {
                    if "`var'" == "_cons" local display_var "Constant"
                    else {
                        capture local lbl : variable label `var'
                        if "`lbl'" != "" local display_var "`lbl'"
                    }
                }
                putdocx table results(`r', 1) = ("`display_var'")
                
                local c = 2
                forvalues i = 1/`num_models' {
                    local m_vars : colnames `b`i''
                    local v_idx : list posof "`var'" in m_vars
                    
                    if `v_idx' > 0 {
                        local coef = `b`i''[1, `v_idx']
                        local coef_str : display %9.`dec'f `coef'
                        local coef_str = trim("`coef_str'")
                        
                        local se_str "-"
                        local star_sym ""
                        
                        capture confirm matrix `V`i''
                        if _rc == 0 {
                            local se = sqrt(`V`i''[`v_idx', `v_idx'])
                            if `se' > 0 & `se' != . {
                                local t = `coef' / `se'
                                local p = .
                                quietly estimates restore `: word `i' of `models''
                                capture local df = e(df_r)
                                if _rc == 0 & "`df'" != "." & "`df'" != "" {
                                    local p = 2 * ttail(`df', abs(`t'))
                                }
                                else {
                                    local p = 2 * normal(-abs(`t'))
                                }
                                if `p' < `s3' local star_sym "***"
                                else if `p' < `s2' local star_sym "**"
                                else if `p' < `s1' local star_sym "*"
                                local se_str : display %9.`dec'f `se'
                                local se_str = trim("`se_str'")
                                local any_se = 1
                            }
                        }
                        putdocx table results(`r', `c') = ("`coef_str'`star_sym'"), halign(center)
                        local rp1 = `r' + 1
                        putdocx table results(`rp1', `c') = ("(`se_str')"), halign(center)
                    }
                    else {
                        putdocx table results(`r', `c') = ("-"), halign(center)
                    }
                    local c = `c' + 1
                }
                local r = `r' + 2
            }
            
            // Stats rows
            foreach st of local stats {
                local display_stat "`st'"
                if "`st'" == "N" local display_stat "Observations"
                else if "`st'" == "r2" local display_stat "R-squared"
                else if "`st'" == "r2_a" local display_stat "Adjusted R-squared"
                else if "`st'" == "F" local display_stat "F-statistic"
                else if "`st'" == "p" local display_stat "Prob > F"
                
                putdocx table results(`r', 1) = ("`display_stat'")
                
                local c = 2
                forvalues i = 1/`num_models' {
                    quietly estimates restore `: word `i' of `models''
                    local stat_val = e(`st')
                    if "`stat_val'" == "." | "`stat_val'" == "" local stat_val = r(`st')
                    if "`stat_val'" != "." & "`stat_val'" != "" {
                        local stat_str : display %9.`dec'f `stat_val'
                        local stat_str = trim("`stat_str'")
                        if "`st'" == "N" local stat_str "`stat_val'"
                        putdocx table results(`r', `c') = ("`stat_str'"), halign(center)
                    }
                    else {
                        putdocx table results(`r', `c') = ("-"), halign(center)
                    }
                    local c = `c' + 1
                }
                local r = `r' + 1
            }
            
            putdocx paragraph
            if "`addnote'" != "" putdocx text ("Note: * p<`s1', ** p<`s2', *** p<`s3'. `addnote'")
            else putdocx text ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
            if "`append'" != "" putdocx save "`using'", append
            else putdocx save "`using'", replace
        }
    }
    else if "`fmt'" == "xlsx" {
        if "`models'" != "" {
            di as err "Side-by-side models currently only supported in DOCX natively."
            exit 198
        }
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Variables"), bold border(bottom)
        putexcel B`base_r' = ("Coefficient"), bold border(bottom) hcenter
        
        local r = `base_r' + 1
        local all_names : colnames `b'
        foreach var of local names {
            local v_idx = 0
            local k = 1
            foreach nv of local all_names {
                if "`nv'" == "`var'" local v_idx = `k'
                local k = `k' + 1
            }
            
            if `v_idx' > 0 {
                local coef = `b'[1, `v_idx']
                local coef_str : display %9.`dec'f `coef'
                local coef_str = trim("`coef_str'")
                local se_str "-"
                local star_sym ""
                if `has_V' {
                    local se = sqrt(`V'[`v_idx', `v_idx'])
                    if `se' > 0 & `se' != . {
                        local t = `coef' / `se'
                        local p = .
                        capture local df = e(df_r)
                        if _rc == 0 & "`df'" != "." & "`df'" != "" {
                            local p = 2 * ttail(`df', abs(`t'))
                        }
                        else {
                            local p = 2 * normal(-abs(`t'))
                        }
                        if `p' < `s3' local star_sym "***"
                        else if `p' < `s2' local star_sym "**"
                        else if `p' < `s1' local star_sym "*"
                        local se_str : display %9.`dec'f `se'
                        local se_str = trim("`se_str'")
                        local any_se = 1
                    }
                }
                
                local display_var "`var'"
                if "`label'" != "" {
                    if "`var'" == "_cons" local display_var "Constant"
                    else {
                        capture local lbl : variable label `var'
                        if "`lbl'" != "" local display_var "`lbl'"
                    }
                }
                
                putexcel A`r' = ("`display_var'")
                putexcel B`r' = ("`coef_str'`star_sym'"), hcenter
                local r = `r' + 1
                if "`se_str'" != "-" {
                    putexcel B`r' = ("(`se_str')"), hcenter
                    local r = `r' + 1
                }
            }
        }
        if "`stats'" == "" local stats "N r2"
        foreach st of local stats {
            local stat_val = e(`st')
            if "`stat_val'" == "." | "`stat_val'" == "" local stat_val = r(`st')
            if "`stat_val'" != "." & "`stat_val'" != "" {
                local display_stat "`st'"
                if "`st'" == "N" local display_stat "Observations"
                else if "`st'" == "r2" local display_stat "R-squared"
                else if "`st'" == "r2_a" local display_stat "Adjusted R-squared"
                else if "`st'" == "F" local display_stat "F-statistic"
                else if "`st'" == "p" local display_stat "Prob > F"
                local stat_str : display %9.`dec'f `stat_val'
                local stat_str = trim("`stat_str'")
                if "`st'" == "N" local stat_str "`stat_val'" 
                putexcel A`r' = ("`display_stat'")
                putexcel B`r' = ("`stat_str'"), hcenter
                local r = `r' + 1
            }
        }
        if `any_se' putexcel A`r' = ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
        if "`addnote'" != "" {
            local r = `r' + 1
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        if "`models'" != "" {
            di as err "Side-by-side models currently only supported in DOCX natively."
            exit 198
        }
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        file write `fh' "Variables,Coefficient" _n
        
        local all_names : colnames `b'
        foreach var of local names {
            local v_idx = 0
            local k = 1
            foreach nv of local all_names {
                if "`nv'" == "`var'" local v_idx = `k'
                local k = `k' + 1
            }
            if `v_idx' > 0 {
                local coef = `b'[1, `v_idx']
                local coef_str : display %9.`dec'f `coef'
                local coef_str = trim("`coef_str'")
                local se_str "-"
                local star_sym ""
                if `has_V' {
                    local se = sqrt(`V'[`v_idx', `v_idx'])
                    if `se' > 0 & `se' != . {
                        local t = `coef' / `se'
                        local p = .
                        capture local df = e(df_r)
                        if _rc == 0 & "`df'" != "." & "`df'" != "" {
                            local p = 2 * ttail(`df', abs(`t'))
                        }
                        else {
                            local p = 2 * normal(-abs(`t'))
                        }
                        if `p' < `s3' local star_sym "***"
                        else if `p' < `s2' local star_sym "**"
                        else if `p' < `s1' local star_sym "*"
                        local se_str : display %9.`dec'f `se'
                        local se_str = trim("`se_str'")
                        local any_se = 1
                    }
                }
                local display_var "`var'"
                if "`label'" != "" {
                    if "`var'" == "_cons" local display_var "Constant"
                    else {
                        capture local lbl : variable label `var'
                        if "`lbl'" != "" local display_var "`lbl'"
                    }
                }
                file write `fh' `""`display_var'","`coef_str'`star_sym'""' _n
                if "`se_str'" != "-" file write `fh' `""","(`se_str')""' _n
            }
        }
        if "`stats'" == "" local stats "N r2"
        foreach st of local stats {
            local stat_val = e(`st')
            if "`stat_val'" == "." | "`stat_val'" == "" local stat_val = r(`st')
            if "`stat_val'" != "." & "`stat_val'" != "" {
                local display_stat "`st'"
                if "`st'" == "N" local display_stat "Observations"
                else if "`st'" == "r2" local display_stat "R-squared"
                local stat_str : display %9.`dec'f `stat_val'
                local stat_str = trim("`stat_str'")
                if "`st'" == "N" local stat_str "`stat_val'" 
                file write `fh' `""`display_stat'","`stat_str'""' _n
            }
        }
        if `any_se' file write `fh' `""Note: * p<`s1', ** p<`s2', *** p<`s3'""' _n
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        if "`models'" != "" {
            di as err "Side-by-side models currently only supported in DOCX natively."
            exit 198
        }
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        file write `fh' "<tr><th>Variables</th><th>Coefficient</th></tr>" _n
        
        local all_names : colnames `b'
        foreach var of local names {
            local v_idx = 0
            local k = 1
            foreach nv of local all_names {
                if "`nv'" == "`var'" local v_idx = `k'
                local k = `k' + 1
            }
            if `v_idx' > 0 {
                local coef = `b'[1, `v_idx']
                local coef_str : display %9.`dec'f `coef'
                local coef_str = trim("`coef_str'")
                local se_str "-"
                local star_sym ""
                if `has_V' {
                    local se = sqrt(`V'[`v_idx', `v_idx'])
                    if `se' > 0 & `se' != . {
                        local t = `coef' / `se'
                        local p = .
                        capture local df = e(df_r)
                        if _rc == 0 & "`df'" != "." & "`df'" != "" {
                            local p = 2 * ttail(`df', abs(`t'))
                        }
                        else {
                            local p = 2 * normal(-abs(`t'))
                        }
                        if `p' < `s3' local star_sym "***"
                        else if `p' < `s2' local star_sym "**"
                        else if `p' < `s1' local star_sym "*"
                        local se_str : display %9.`dec'f `se'
                        local se_str = trim("`se_str'")
                        local any_se = 1
                    }
                }
                local display_var "`var'"
                if "`label'" != "" {
                    if "`var'" == "_cons" local display_var "Constant"
                    else {
                        capture local lbl : variable label `var'
                        if "`lbl'" != "" local display_var "`lbl'"
                    }
                }
                file write `fh' "<tr><td>`display_var'</td><td>`coef_str'`star_sym'</td></tr>" _n
                if "`se_str'" != "-" file write `fh' "<tr><td></td><td>(`se_str')</td></tr>" _n
            }
        }
        if "`stats'" == "" local stats "N r2"
        foreach st of local stats {
            local stat_val = e(`st')
            if "`stat_val'" == "." | "`stat_val'" == "" local stat_val = r(`st')
            if "`stat_val'" != "." & "`stat_val'" != "" {
                local display_stat "`st'"
                if "`st'" == "N" local display_stat "Observations"
                else if "`st'" == "r2" local display_stat "R-squared"
                local stat_str : display %9.`dec'f `stat_val'
                local stat_str = trim("`stat_str'")
                if "`st'" == "N" local stat_str "`stat_val'" 
                file write `fh' "<tr><td>`display_stat'</td><td>`stat_str'</td></tr>" _n
            }
        }
        file write `fh' "</table>" _n
        if `any_se' file write `fh' "<p>Note: * p&lt;`s1', ** p&lt;`s2', *** p&lt;`s3'</p>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end

// --------------------------------------------------------------------------------
// Module: Random Forest (Feature Importance)
// --------------------------------------------------------------------------------
program define ntables_rf
    syntax [anything], fmt(string) using(string) title(string) dec(integer) [label suppresshead addnote(string) replace append]
    
    // Check if rforest matrix exists
    capture confirm matrix e(importance)
    if _rc {
        di as err "Random forest importance matrix not found. Run rforest first."
        exit 301
    }
    
    tempname imp
    matrix `imp' = e(importance)
    local vars : rownames `imp'
    
    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        
        local n_vars : word count `vars'
        local rows = `n_vars' + 1
        putdocx table results = (`rows', 2), border(all, nil) border(top, single) border(bottom, single)
        putdocx table results(1, 1) = ("Variable"), border(bottom, single) bold
        putdocx table results(1, 2) = ("Importance"), border(bottom, single) bold halign(center)
        
        local r = 2
        local i = 1
        foreach v of local vars {
            local val = `imp'[`i', 1]
            local val_str : display %9.`dec'f `val'
            putdocx table results(`r', 1) = ("`v'")
            putdocx table results(`r', 2) = ("`val_str'"), halign(center)
            local r = `r' + 1
            local i = `i' + 1
        }
        if "`addnote'" != "" {
            putdocx paragraph
            putdocx text ("Note: `addnote'")
        }
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Variable"), bold border(bottom)
        putexcel B`base_r' = ("Importance"), bold border(bottom) hcenter
        
        local r = `base_r' + 1
        local i = 1
        foreach v of local vars {
            local val = `imp'[`i', 1]
            local val_str : display %9.`dec'f `val'
            putexcel A`r' = ("`v'")
            putexcel B`r' = ("`val_str'"), hcenter
            local r = `r' + 1
            local i = `i' + 1
        }
        if "`addnote'" != "" {
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        file write `fh' "Variable,Importance" _n
        
        local i = 1
        foreach v of local vars {
            local val = `imp'[`i', 1]
            local val_str : display %9.`dec'f `val'
            file write `fh' `""`v'","`val_str'""' _n
            local i = `i' + 1
        }
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        file write `fh' "<tr><th>Variable</th><th>Importance</th></tr>" _n
        
        local i = 1
        foreach v of local vars {
            local val = `imp'[`i', 1]
            local val_str : display %9.`dec'f `val'
            file write `fh' "<tr><td>`v'</td><td>`val_str'</td></tr>" _n
            local i = `i' + 1
        }
        file write `fh' "</table>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end

// --------------------------------------------------------------------------------
// Module: Correlation Matrix
// --------------------------------------------------------------------------------
program define ntables_corr
    syntax [anything], fmt(string) using(string) title(string) dec(integer) [pvals suppresshead keep(string) drop(string) label star(string) addnote(string) replace append]
    
    local s1 = 0.10
    local s2 = 0.05
    local s3 = 0.01
    if "`star'" != "" {
        tokenize "`star'"
        if "`1'" != "" local s1 = `1'
        if "`2'" != "" local s2 = `2'
        if "`3'" != "" local s3 = `3'
    }
    
    tempname Cmat
    capture matrix `Cmat' = r(C)
    
    if "`anything'" != "" {
        local vars "`anything'"
    }
    else if _rc == 0 {
        local vars : rownames `Cmat'
    }
    else {
        quietly ds, has(type numeric)
        local vars "`r(varlist)'"
    }
    
    local final_vars ""
    foreach v of local vars {
        local in_drop : list posof "`v'" in drop
        local in_keep : list posof "`v'" in keep
        if `in_drop' == 0 {
            if "`keep'" == "" | `in_keep' > 0 {
                local final_vars "`final_vars' `v'"
            }
        }
    }
    local vars "`final_vars'"
    
    local n_vars : word count `vars'
    local cols = `n_vars' + 1
    
    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        
        local rows = `n_vars' + 1
        if "`pvals'" != "" local rows = (`n_vars' * 2) + 1
        
        putdocx table results = (`rows', `cols'), border(all, nil) border(top, single) border(bottom, single)
        putdocx table results(1, 1) = ("Variables"), border(bottom, single) bold
        local c = 2
        foreach v of local vars {
            local n = `c' - 1
            putdocx table results(1, `c') = ("(`n')"), border(bottom, single) bold halign(center)
            local c = `c' + 1
        }
        
        local r = 2
        local i = 1
        foreach v1 of local vars {
            local display_var "`v1'"
            if "`label'" != "" {
                local lbl : variable label `v1'
                if "`lbl'" != "" local display_var "`lbl'"
            }
            putdocx table results(`r', 1) = ("(`i') `display_var'")
            local c = 2
            local j = 1
            foreach v2 of local vars {
                if `j' <= `i' {
                    quietly correlate `v1' `v2'
                    local coef = r(rho)
                    local N = r(N)
                    local t = `coef' * sqrt((`N'-2)/(1-`coef'^2))
                    local p = 2 * ttail(`N'-2, abs(`t'))
                    if `coef' >= 0.9999 local p = 0
                    local star_sym ""
                    if `p' < `s3' local star_sym "***"
                    else if `p' < `s2' local star_sym "**"
                    else if `p' < `s1' local star_sym "*"
                    local coef_str : display %9.`dec'f `coef'
                    local coef_str = trim("`coef_str'")
                    local coef_str = trim("`coef_str'")
                    if `i' == `j' local coef_str "1.000"
                    
                    if "`pvals'" != "" & `i' != `j' {
                        putdocx table results(`r', `c') = ("`coef_str'`star_sym'"), halign(center)
                        local r_pval = `r' + 1
                        local p_str : display %9.`dec'f `p'
                        local p_str = trim("`p_str'")
                        local p_str = trim("`p_str'")
                        putdocx table results(`r_pval', `c') = ("(`p_str')"), halign(center)
                    }
                    else {
                        putdocx table results(`r', `c') = ("`coef_str'`star_sym'"), halign(center)
                    }
                }
                local c = `c' + 1
                local j = `j' + 1
            }
            if "`pvals'" != "" local r = `r' + 2
            else local r = `r' + 1
            local i = `i' + 1
        }
        putdocx paragraph
        putdocx text ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
        if "`pvals'" != "" putdocx text (" (p-values in parentheses)")
        if "`addnote'" != "" putdocx text (" `addnote'")
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Variables"), bold border(bottom)
        
        // Column mapping
        local letters "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ"
        local c = 1
        foreach v of local vars {
            local col_letter : word `c' of `letters'
            putexcel `col_letter'`base_r' = ("(`c')"), bold border(bottom) hcenter
            local c = `c' + 1
        }
        
        local r = `base_r' + 1
        local i = 1
        foreach v1 of local vars {
            local display_var "`v1'"
            if "`label'" != "" {
                local lbl : variable label `v1'
                if "`lbl'" != "" local display_var "`lbl'"
            }
            putexcel A`r' = ("(`i') `display_var'")
            local c = 1
            local j = 1
            foreach v2 of local vars {
                if `j' <= `i' {
                    quietly correlate `v1' `v2'
                    local coef = r(rho)
                    local N = r(N)
                    local t = `coef' * sqrt((`N'-2)/(1-`coef'^2))
                    local p = 2 * ttail(`N'-2, abs(`t'))
                    if `coef' >= 0.9999 local p = 0
                    local star_sym ""
                    if `p' < `s3' local star_sym "***"
                    else if `p' < `s2' local star_sym "**"
                    else if `p' < `s1' local star_sym "*"
                    local coef_str : display %9.`dec'f `coef'
                    local coef_str = trim("`coef_str'")
                    local coef_str = trim("`coef_str'")
                    if `i' == `j' local coef_str "1.000"
                    
                    local col_letter : word `c' of `letters'
                    
                    if "`pvals'" != "" & `i' != `j' {
                        putexcel `col_letter'`r' = ("`coef_str'`star_sym'"), hcenter
                        local r_pval = `r' + 1
                        local p_str : display %9.`dec'f `p'
                        local p_str = trim("`p_str'")
                        local p_str = trim("`p_str'")
                        putexcel `col_letter'`r_pval' = ("(`p_str')"), hcenter
                    }
                    else {
                        putexcel `col_letter'`r' = ("`coef_str'`star_sym'"), hcenter
                    }
                }
                local c = `c' + 1
                local j = `j' + 1
            }
            if "`pvals'" != "" local r = `r' + 2
            else local r = `r' + 1
            local i = `i' + 1
        }
        putexcel A`r' = ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
        if "`pvals'" != "" {
            local r = `r' + 1
            putexcel A`r' = ("(p-values in parentheses)")
        }
        if "`addnote'" != "" {
            local r = `r' + 1
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        
        local header "Variables"
        local c = 1
        foreach v of local vars {
            local header "`header',(`c')"
            local c = `c' + 1
        }
        file write `fh' "`header'" _n
        
        local i = 1
        foreach v1 of local vars {
            local display_var "`v1'"
            if "`label'" != "" {
                local lbl : variable label `v1'
                if "`lbl'" != "" local display_var "`lbl'"
            }
            local row_str `""(`i') `display_var'""'
            local row_pval `""""'
            
            local j = 1
            foreach v2 of local vars {
                if `j' <= `i' {
                    quietly correlate `v1' `v2'
                    local coef = r(rho)
                    local N = r(N)
                    local t = `coef' * sqrt((`N'-2)/(1-`coef'^2))
                    local p = 2 * ttail(`N'-2, abs(`t'))
                    if `coef' >= 0.9999 local p = 0
                    local star_sym ""
                    if `p' < `s3' local star_sym "***"
                    else if `p' < `s2' local star_sym "**"
                    else if `p' < `s1' local star_sym "*"
                    local coef_str : display %9.`dec'f `coef'
                    local coef_str = trim("`coef_str'")
                    local coef_str = trim("`coef_str'")
                    if `i' == `j' local coef_str "1.000"
                    
                    local row_str "`row_str',`coef_str'`star_sym'"
                    
                    if "`pvals'" != "" & `i' != `j' {
                        local p_str : display %9.`dec'f `p'
                        local p_str = trim("`p_str'")
                        local p_str = trim("`p_str'")
                        local row_pval "`row_pval',(`p_str')"
                    }
                    else {
                        local row_pval "`row_pval',"
                    }
                }
                else {
                    local row_str "`row_str',"
                    local row_pval "`row_pval',"
                }
                local j = `j' + 1
            }
            file write `fh' "`row_str'" _n
            if "`pvals'" != "" file write `fh' "`row_pval'" _n
            local i = `i' + 1
        }
        file write `fh' `""Note: * p<`s1', ** p<`s2', *** p<`s3'""' _n
        if "`pvals'" != "" file write `fh' `""(p-values in parentheses)""' _n
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        
        local header "<tr><th>Variables</th>"
        local c = 1
        foreach v of local vars {
            local header "`header'<th>(`c')</th>"
            local c = `c' + 1
        }
        local header "`header'</tr>"
        file write `fh' "`header'" _n
        
        local i = 1
        foreach v1 of local vars {
            local display_var "`v1'"
            if "`label'" != "" {
                local lbl : variable label `v1'
                if "`lbl'" != "" local display_var "`lbl'"
            }
            local row_str "<tr><td>(`i') `display_var'</td>"
            local row_pval "<tr><td></td>"
            
            local j = 1
            foreach v2 of local vars {
                if `j' <= `i' {
                    quietly correlate `v1' `v2'
                    local coef = r(rho)
                    local N = r(N)
                    local t = `coef' * sqrt((`N'-2)/(1-`coef'^2))
                    local p = 2 * ttail(`N'-2, abs(`t'))
                    if `coef' >= 0.9999 local p = 0
                    local star_sym ""
                    if `p' < `s3' local star_sym "***"
                    else if `p' < `s2' local star_sym "**"
                    else if `p' < `s1' local star_sym "*"
                    local coef_str : display %9.`dec'f `coef'
                    local coef_str = trim("`coef_str'")
                    local coef_str = trim("`coef_str'")
                    if `i' == `j' local coef_str "1.000"
                    
                    local row_str "`row_str'<td>`coef_str'`star_sym'</td>"
                    
                    if "`pvals'" != "" & `i' != `j' {
                        local p_str : display %9.`dec'f `p'
                        local p_str = trim("`p_str'")
                        local p_str = trim("`p_str'")
                        local row_pval "`row_pval'<td>(`p_str')</td>"
                    }
                    else {
                        local row_pval "`row_pval'<td></td>"
                    }
                }
                else {
                    local row_str "`row_str'<td></td>"
                    local row_pval "`row_pval'<td></td>"
                }
                local j = `j' + 1
            }
            local row_str "`row_str'</tr>"
            local row_pval "`row_pval'</tr>"
            file write `fh' "`row_str'" _n
            if "`pvals'" != "" file write `fh' "`row_pval'" _n
            local i = `i' + 1
        }
        file write `fh' "</table>" _n
        file write `fh' "<p>Note: * p&lt;`s1', ** p&lt;`s2', *** p&lt;`s3'</p>" _n
        if "`pvals'" != "" file write `fh' "<p>(p-values in parentheses)</p>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end

// --------------------------------------------------------------------------------
// Module: Stationarity / Unit Root Test
// --------------------------------------------------------------------------------
program define ntables_unitroot
    syntax [anything], fmt(string) using(string) title(string) dec(integer) [star(string) addnote(string) suppresshead rzt(string) rz(string) rt(string) rp(string) replace append]
    
    local z = .
    local p = .
    local stat_name "Statistic"
    if "`rzt'" != "" {
        local z = `rzt'
        local stat_name "Dickey-Fuller Z(t)"
    }
    else if "`rz'" != "" {
        local z = `rz'
        local stat_name "Z-statistic"
    }
    else if "`rt'" != "" {
        local z = `rt'
        local stat_name "t-statistic"
    }
    if "`rp'" != "" {
        local p = `rp'
    }
    
    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        
        putdocx table results = (3, 2), border(all, nil) border(top, single) border(bottom, single)
        putdocx table results(1, 1) = ("Statistic"), border(bottom, single) bold
        putdocx table results(1, 2) = ("Value"), border(bottom, single) bold halign(center)
        
        if `z' != . {
            local z_str : display %9.`dec'f `z'
            local z_str = trim("`z_str'")
            putdocx table results(2, 1) = ("`stat_name'")
            putdocx table results(2, 2) = ("`z_str'"), halign(center)
        }
        if `p' != . {
            local p_str : display %9.`dec'f `p'
            local p_str = trim("`p_str'")
            putdocx table results(3, 1) = ("MacKinnon approximate p-value")
            putdocx table results(3, 2) = ("`p_str'"), halign(center)
        }
        
        if "`addnote'" != "" {
            putdocx paragraph
            putdocx text ("Note: `addnote'")
        }
        
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        putexcel A`base_r' = ("Test Statistic"), bold border(bottom)
        putexcel B`base_r' = ("Value"), bold border(bottom) hcenter
        putexcel C`base_r' = ("P-value"), bold border(bottom) hcenter
        
        local r = `base_r' + 1
        putexcel A`r' = ("`stat_name'")
        putexcel B`r' = ("`z_str'`star_sym'"), hcenter
        putexcel C`r' = ("(`p_str')"), hcenter
        
        local r = `r' + 1
        putexcel A`r' = ("Note: * p<`s1', ** p<`s2', *** p<`s3'")
        if "`addnote'" != "" {
            local r = `r' + 1
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        file write `fh' "Test Statistic,Value,P-value" _n
        file write `fh' `""`stat_name'","`z_str'`star_sym'","(`p_str')""' _n
        file write `fh' `""Note: * p<`s1', ** p<`s2', *** p<`s3'""' _n
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        file write `fh' "<tr><th>Test Statistic</th><th>Value</th><th>P-value</th></tr>" _n
        file write `fh' "<tr><td>`stat_name'</td><td>`z_str'`star_sym'</td><td>(`p_str')</td></tr>" _n
        file write `fh' "</table>" _n
        file write `fh' "<p>Note: * p&lt;`s1', ** p&lt;`s2', *** p&lt;`s3'</p>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end

// --------------------------------------------------------------------------------
// Module: Cross-Tabulation
// --------------------------------------------------------------------------------
program define ntables_tab
    syntax anything(name=cmd_str), fmt(string) using(string) title(string) dec(integer) [suppresshead label addnote(string) replace append]
    
    local using_file "`using'"
    local 0 `cmd_str'
    gettoken tabcmd 0 : 0
    syntax varlist(max=2)
    local using "`using_file'"
    
    local n_vars : word count `varlist'
    local var1 : word 1 of `varlist'
    if `n_vars' == 2 {
        local var2 : word 2 of `varlist'
    }
    
    if "`fmt'" == "docx" {
        putdocx clear
        putdocx begin
        if "`append'" != "" putdocx pagebreak
        if "`suppresshead'" == "" {
            putdocx paragraph, style(Heading1)
            putdocx text ("`title'")
        }
        
        if `n_vars' == 1 {
            quietly tabulate `var1', matcell(freq) matrow(names)
            local rows = rowsof(freq) + 2
            putdocx table results = (`rows', 3), border(all, nil) border(top, single) border(bottom, single)
            putdocx table results(1, 1) = ("`var1'"), border(bottom, single) bold
            putdocx table results(1, 2) = ("Freq."), border(bottom, single) bold halign(center)
            putdocx table results(1, 3) = ("Percent"), border(bottom, single) bold halign(center)
            
            local total = 0
            forvalues i = 1/`=rowsof(freq)' {
                local total = `total' + freq[`i', 1]
            }
            
            local r = 2
            forvalues i = 1/`=rowsof(freq)' {
                local val = names[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local f = freq[`i', 1]
                local p = (`f' / `total') * 100
                local p_str : display %9.`dec'f `p'
                local p_str = trim("`p_str'")
                
                putdocx table results(`r', 1) = ("`val'")
                putdocx table results(`r', 2) = ("`f'"), halign(center)
                putdocx table results(`r', 3) = ("`p_str'"), halign(center)
                local r = `r' + 1
            }
            putdocx table results(`r', 1) = ("Total"), border(top, single) bold
            putdocx table results(`r', 2) = ("`total'"), border(top, single) halign(center) bold
            putdocx table results(`r', 3) = ("100.00"), border(top, single) halign(center) bold
        }
        else {
            quietly tabulate `var1' `var2', matcell(freq) matrow(rnames) matcol(cnames)
            local num_rows = rowsof(freq)
            local num_cols = colsof(freq)
            
            local tbl_rows = `num_rows' + 2
            local tbl_cols = `num_cols' + 2
            
            putdocx table results = (`tbl_rows', `tbl_cols'), border(all, nil) border(top, single) border(bottom, single)
            putdocx table results(1, 1) = ("`var1' \ `var2'"), border(bottom, single) bold
            
            local c = 2
            forvalues j = 1/`num_cols' {
                local val = cnames[1, `j']
                if "`label'" != "" {
                    local val_lbl : label (`var2') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                putdocx table results(1, `c') = ("`val'"), border(bottom, single) bold halign(center)
                local c = `c' + 1
            }
            putdocx table results(1, `c') = ("Total"), border(bottom, single) bold halign(center)
            
            local r = 2
            local grand_total = 0
            forvalues i = 1/`num_rows' {
                local val = rnames[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                putdocx table results(`r', 1) = ("`val'")
                
                local row_total = 0
                local c = 2
                forvalues j = 1/`num_cols' {
                    local f = freq[`i', `j']
                    local row_total = `row_total' + `f'
                    putdocx table results(`r', `c') = ("`f'"), halign(center)
                    local c = `c' + 1
                }
                local grand_total = `grand_total' + `row_total'
                putdocx table results(`r', `c') = ("`row_total'"), halign(center) bold
                local r = `r' + 1
            }
            putdocx table results(`r', 1) = ("Total"), border(top, single) bold
            local c = 2
            forvalues j = 1/`num_cols' {
                local col_total = 0
                forvalues i = 1/`num_rows' {
                    local col_total = `col_total' + freq[`i', `j']
                }
                putdocx table results(`r', `c') = ("`col_total'"), border(top, single) halign(center) bold
                local c = `c' + 1
            }
            putdocx table results(`r', `c') = ("`grand_total'"), border(top, single) halign(center) bold
        }
        
        if "`addnote'" != "" {
            putdocx paragraph
            putdocx text ("Note: `addnote'")
        }
        if "`append'" != "" putdocx save "`using'", append
        else putdocx save "`using'", replace
    }
    else if "`fmt'" == "xlsx" {
        if "`append'" == "" capture erase "`using'"
        putexcel set "`using'", modify
        local base_r = 1
        if "`suppresshead'" == "" {
            putexcel A`base_r' = ("`title'"), bold
            local base_r = `base_r' + 2
        }
        
        if `n_vars' == 1 {
            quietly tabulate `var1', matcell(freq) matrow(names)
            putexcel A`base_r' = ("`var1'"), border(bottom) bold
            putexcel B`base_r' = ("Freq."), border(bottom) bold hcenter
            putexcel C`base_r' = ("Percent"), border(bottom) bold hcenter
            
            local total = 0
            forvalues i = 1/`=rowsof(freq)' {
                local total = `total' + freq[`i', 1]
            }
            
            local r = `base_r' + 1
            forvalues i = 1/`=rowsof(freq)' {
                local val = names[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local f = freq[`i', 1]
                local p = (`f' / `total') * 100
                local p_str : display %9.`dec'f `p'
                local p_str = trim("`p_str'")
                
                putexcel A`r' = ("`val'")
                putexcel B`r' = (`f'), hcenter
                putexcel C`r' = (`p_str'), hcenter
                local r = `r' + 1
            }
            putexcel A`r' = ("Total"), border(top) bold
            putexcel B`r' = (`total'), border(top) hcenter bold
            putexcel C`r' = (100.00), border(top) hcenter bold
            local r = `r' + 1
        }
        else {
            quietly tabulate `var1' `var2', matcell(freq) matrow(rnames) matcol(cnames)
            local num_rows = rowsof(freq)
            local num_cols = colsof(freq)
            
            local letters "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ"
            
            putexcel A`base_r' = ("`var1' \ `var2'"), border(bottom) bold
            local c = 1
            forvalues j = 1/`num_cols' {
                local val = cnames[1, `j']
                if "`label'" != "" {
                    local val_lbl : label (`var2') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local col_letter : word `c' of `letters'
                putexcel `col_letter'`base_r' = ("`val'"), border(bottom) bold hcenter
                local c = `c' + 1
            }
            local col_letter : word `c' of `letters'
            putexcel `col_letter'`base_r' = ("Total"), border(bottom) bold hcenter
            
            local r = `base_r' + 1
            local grand_total = 0
            forvalues i = 1/`num_rows' {
                local val = rnames[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                putexcel A`r' = ("`val'")
                
                local row_total = 0
                local c = 1
                forvalues j = 1/`num_cols' {
                    local f = freq[`i', `j']
                    local row_total = `row_total' + `f'
                    local col_letter : word `c' of `letters'
                    putexcel `col_letter'`r' = (`f'), hcenter
                    local c = `c' + 1
                }
                local grand_total = `grand_total' + `row_total'
                local col_letter : word `c' of `letters'
                putexcel `col_letter'`r' = (`row_total'), hcenter bold
                local r = `r' + 1
            }
            putexcel A`r' = ("Total"), border(top) bold
            local c = 1
            forvalues j = 1/`num_cols' {
                local col_total = 0
                forvalues i = 1/`num_rows' {
                    local col_total = `col_total' + freq[`i', `j']
                }
                local col_letter : word `c' of `letters'
                putexcel `col_letter'`r' = (`col_total'), border(top) hcenter bold
                local c = `c' + 1
            }
            local col_letter : word `c' of `letters'
            putexcel `col_letter'`r' = (`grand_total'), border(top) hcenter bold
            local r = `r' + 1
        }
        
        if "`addnote'" != "" {
            putexcel A`r' = ("Note: `addnote'")
        }
    }
    else if "`fmt'" == "csv" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' `""`title'""' _n
        
        if `n_vars' == 1 {
            quietly tabulate `var1', matcell(freq) matrow(names)
            file write `fh' `""`var1'","Freq.","Percent""' _n
            
            local total = 0
            forvalues i = 1/`=rowsof(freq)' {
                local total = `total' + freq[`i', 1]
            }
            
            forvalues i = 1/`=rowsof(freq)' {
                local val = names[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local f = freq[`i', 1]
                local p = (`f' / `total') * 100
                local p_str : display %9.`dec'f `p'
                local p_str = trim("`p_str'")
                
                file write `fh' `""`val'",`f',`p_str'"' _n
            }
            file write `fh' `""Total",`total',100.00"' _n
        }
        else {
            quietly tabulate `var1' `var2', matcell(freq) matrow(rnames) matcol(cnames)
            local num_rows = rowsof(freq)
            local num_cols = colsof(freq)
            
            local header `""`var1' \ `var2'""'
            forvalues j = 1/`num_cols' {
                local val = cnames[1, `j']
                if "`label'" != "" {
                    local val_lbl : label (`var2') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local header "`header',`val'"
            }
            local header "`header',Total"
            file write `fh' "`header'" _n
            
            local grand_total = 0
            forvalues i = 1/`num_rows' {
                local val = rnames[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local row_str `""`val'""'
                
                local row_total = 0
                forvalues j = 1/`num_cols' {
                    local f = freq[`i', `j']
                    local row_total = `row_total' + `f'
                    local row_str "`row_str',`f'"
                }
                local grand_total = `grand_total' + `row_total'
                local row_str "`row_str',`row_total'"
                file write `fh' "`row_str'" _n
            }
            local row_str `""Total""'
            forvalues j = 1/`num_cols' {
                local col_total = 0
                forvalues i = 1/`num_rows' {
                    local col_total = `col_total' + freq[`i', `j']
                }
                local row_str "`row_str',`col_total'"
            }
            local row_str "`row_str',`grand_total'"
            file write `fh' "`row_str'" _n
        }
        if "`addnote'" != "" file write `fh' `""Note: `addnote'""' _n
        file close `fh'
    }
    else if "`fmt'" == "html" {
        tempname fh
        local mode "write replace"
        if "`append'" != "" local mode "write append"
        file open `fh' using "`using'", `mode'
        if "`suppresshead'" == "" file write `fh' "<h2>`title'</h2>" _n
        file write `fh' "<table border='1' cellspacing='0' cellpadding='5'>" _n
        
        if `n_vars' == 1 {
            quietly tabulate `var1', matcell(freq) matrow(names)
            file write `fh' "<tr><th>`var1'</th><th>Freq.</th><th>Percent</th></tr>" _n
            
            local total = 0
            forvalues i = 1/`=rowsof(freq)' {
                local total = `total' + freq[`i', 1]
            }
            
            forvalues i = 1/`=rowsof(freq)' {
                local val = names[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local f = freq[`i', 1]
                local p = (`f' / `total') * 100
                local p_str : display %9.`dec'f `p'
                local p_str = trim("`p_str'")
                
                file write `fh' "<tr><td>`val'</td><td>`f'</td><td>`p_str'</td></tr>" _n
            }
            file write `fh' "<tr><td><b>Total</b></td><td><b>`total'</b></td><td><b>100.00</b></td></tr>" _n
        }
        else {
            quietly tabulate `var1' `var2', matcell(freq) matrow(rnames) matcol(cnames)
            local num_rows = rowsof(freq)
            local num_cols = colsof(freq)
            
            local header "<tr><th>`var1' \ `var2'</th>"
            forvalues j = 1/`num_cols' {
                local val = cnames[1, `j']
                if "`label'" != "" {
                    local val_lbl : label (`var2') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local header "`header'<th>`val'</th>"
            }
            local header "`header'<th>Total</th></tr>"
            file write `fh' "`header'" _n
            
            local grand_total = 0
            forvalues i = 1/`num_rows' {
                local val = rnames[`i', 1]
                if "`label'" != "" {
                    local val_lbl : label (`var1') `val', strict
                    if "`val_lbl'" != "" local val = "`val_lbl'"
                }
                local row_str "<tr><td>`val'</td>"
                
                local row_total = 0
                forvalues j = 1/`num_cols' {
                    local f = freq[`i', `j']
                    local row_total = `row_total' + `f'
                    local row_str "`row_str'<td>`f'</td>"
                }
                local grand_total = `grand_total' + `row_total'
                local row_str "`row_str'<td><b>`row_total'</b></td></tr>"
                file write `fh' "`row_str'" _n
            }
            local row_str "<tr><td><b>Total</b></td>"
            forvalues j = 1/`num_cols' {
                local col_total = 0
                forvalues i = 1/`num_rows' {
                    local col_total = `col_total' + freq[`i', `j']
                }
                local row_str "`row_str'<td><b>`col_total'</b></td>"
            }
            local row_str "`row_str'<td><b>`grand_total'</b></td></tr>"
            file write `fh' "`row_str'" _n
        }
        file write `fh' "</table>" _n
        if "`addnote'" != "" file write `fh' "<p>Note: `addnote'</p>" _n
        file write `fh' "<br/>" _n
        file close `fh'
    }
end
