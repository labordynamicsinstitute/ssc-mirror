*! corr2tex v1.2.3
*! Authors: 
*!   Wu Lianghai: agd2010@yeah.net, Anhui University of Technology (AHUT), Ma'anshan, China
*!   Wu Hanyan: 2325476320@qq.com, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China
*!   Hu Fangfang: huff470@163.com, Wanjiang University of Technology (WJUT), Ma'anshan, China
*! Date: 2025-08-08
*! Generate correlation matrices in LaTeX format with significance stars

program define corr2tex
    version 16
    syntax varlist(numeric) [if] [in], SAVing(string) [ ///
        DECimal(integer 3) REPLace LANDscape TItle(string) THREELine /// 
        Format(string) LABel NOTE(string) STAR ]

    // Validate decimal option
    if `decimal' < 0 | `decimal' > 6 {
        di as error "decimal must be between 0 and 6"
        exit 198
    }
    
    // Create valid format string
    if `decimal' == 0 {
        local fmt_str "%12.0f"
    }
    else {
        local fmt_str "%12.`decimal'f"
    }
    
    // Prepare output file
    if "`replace'" != "" capture erase "`saving'"
    tempname fh
    file open `fh' using "`saving'", write text replace
    
    // LaTeX document header
    file write `fh' "\documentclass{article}" _n
    file write `fh' "\usepackage{geometry}" _n
    file write `fh' "\usepackage{booktabs}" _n
    file write `fh' "\usepackage{multirow}" _n
    file write `fh' "\usepackage{array}" _n
    file write `fh' "\usepackage{rotating}" _n
    file write `fh' "\usepackage{threeparttable}" _n
    file write `fh' "\usepackage{amsmath}" _n
    
    if "`landscape'" != "" {
        file write `fh' "\usepackage{pdflscape}" _n
        file write `fh' "\geometry{a4paper, landscape, margin=1.5cm}" _n
    }
    else {
        file write `fh' "\geometry{a4paper, portrait, margin=2cm}" _n
    }
    
    file write `fh' "\begin{document}" _n
    if "`landscape'" != "" file write `fh' "\begin{landscape}" _n
    
    // Table environment
    file write `fh' "\begin{table}[htbp]" _n
    file write `fh' "\centering" _n
    if `"`title'"' != "" file write `fh' "\caption{`title'}" _n
    if "`threeline'" != "" file write `fh' "\begin{threeparttable}" _n
    
    // Calculate correlation matrix
    marksample touse
    qui correlate `varlist' if `touse'
    matrix C = r(C)
    local n = r(N)
    local nvars = rowsof(C)
    
    // Store variable labels
    local varlabels ""
    local i = 0
    foreach var of local varlist {
        local ++i
        if "`label'" != "" {
            local lbl : variable label `var'
            if `"`lbl'"' == "" local lbl "`var'"
        }
        else {
            local lbl "`var'"
        }
        
        // Escape LaTeX special characters
        local lbl = subinstr(`"`lbl'"', "_", "\_", .)
        local lbl = subinstr(`"`lbl'"', "&", "\&", .)
        local lbl = subinstr(`"`lbl'"', "%", "\%", .)
        local lbl = subinstr(`"`lbl'"', "#", "\#", .)
        local lbl = subinstr(`"`lbl'"', "{", "\{", .)
        local lbl = subinstr(`"`lbl'"', "}", "\}", .)
        local varlabels `"`varlabels' `"`lbl'"'"'
    }
    
    // Start tabular environment
    file write `fh' "\begin{tabular}{@{}l" _n
    forval i = 1/`nvars' {
        file write `fh' "c"
    }
    file write `fh' "@{}}" _n
    
    if "`threeline'" != "" file write `fh' "\toprule" _n
    else file write `fh' "\hline" _n
    
    // Table header: Variable names
    file write `fh' " "
    foreach lbl of local varlabels {
        file write `fh' " & `lbl'"
    }
    file write `fh' " \\" _n
    if "`threeline'" != "" file write `fh' "\midrule" _n
    else file write `fh' "\hline" _n
    
    // Table body: Correlation matrix with significance stars
    forval i = 1/`nvars' {
        local rowlbl : word `i' of `varlabels'
        file write `fh' "`rowlbl'"
        
        forval j = 1/`nvars' {
            local corr_val = C[`i', `j']
            
            // Format correlation value
            if `i' == `j' {
                file write `fh' " & $1$"  // Diagonal elements
            }
            else {
                if missing(`corr_val') {
                    file write `fh' " & --"
                }
                else {
                    // Add significance stars if requested
                    local star_str ""
                    if "`star'" != "" & `i' > `j' {
                        // Calculate t-statistic and p-value
                        local t = `corr_val' * sqrt(`n' - 2) / sqrt(1 - `corr_val'^2)
                        local p = 2 * ttail(`n' - 2, abs(`t'))
                        
                        // Determine significance level
                        if `p' < 0.01 {
                            local star_str "^{***}"
                        }
                        else if `p' < 0.05 {
                            local star_str "^{**}"
                        }
                        else if `p' < 0.10 {
                            local star_str "^{*}"
                        }
                    }
                    
                    // Format coefficient with stars
                    local corr_str : display `fmt_str' `corr_val'
                    file write `fh' " & $`corr_str'`star_str'$"
                }
            }
        }
        file write `fh' " \\" _n
    }
    
    // Table footer
    if "`threeline'" != "" file write `fh' "\bottomrule" _n
    else file write `fh' "\hline" _n
    
    file write `fh' "\end{tabular}" _n
    
    // Table notes
    if "`threeline'" != "" {
        file write `fh' "\begin{tablenotes}" _n
        file write `fh' "\small" _n
        file write `fh' "\item \textit{Notes:} Correlation coefficients shown."
        
        // Add significance note if stars are used
        if "`star'" != "" {
            file write `fh' " Significance levels: *** p$<0.01$, ** p$<0.05$, * p$<0.10$."
        }
        
        // Add custom note
        if `"`note'"' != "" {
            file write `fh' " `note'" _n
        }
        else {
            file write `fh' _n
        }
        file write `fh' "\end{tablenotes}" _n
        file write `fh' "\end{threeparttable}" _n
    }
    else {
        if `"`note'"' != "" | "`star'" != "" {
            file write `fh' "\par\medskip\footnotesize{\textit{Notes:} "
            if "`star'" != "" {
                file write `fh' "Significance levels: *** p$<0.01$, ** p$<0.05$, * p$<0.10$. "
            }
            if `"`note'"' != "" {
                file write `fh' "`note'"
            }
            file write `fh' "}" _n
        }
    }
    
    file write `fh' "\end{table}" _n
    if "`landscape'" != "" file write `fh' "\end{landscape}" _n
    file write `fh' "\end{document}" _n
    file close `fh'
    
    // User feedback
    di _n as text `"LaTeX table saved to "' as result `"`saving'"'
    di as text "Variables: `varlist'"
    di as text "Observations: `n'"
    if "`star'" != "" {
        di as text "Significance stars: * p<0.10, ** p<0.05, *** p<0.01"
    }
end