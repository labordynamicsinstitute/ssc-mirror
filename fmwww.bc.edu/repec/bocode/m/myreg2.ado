********************************************************************
*The program export a set of regression results
*the basic syntax is myreg2 xvar,dp(2) ci(-)
*example myreg2 iron4c,dp(2) ci(-) model(Unadjusted Adjusted Full) export(table2.docx,replace)
*it will export regression results for iron4c 
*! Author: Zumin Shi, Qatar University, zumin.shi@gmail.com
*!Date: 21 May 2025
*!Version: 1.0
*********************************************************************

capture program drop myreg2

program myreg2, rclass      
    syntax [varname(fv)] [, DP(integer 2) CIlimiter(string) TItle(string) ///
           NOtes(string asis) Model(string asis) PValue ALL CONStant Export(string) ]
    version 17      

    // if no cilimiter given apply default
    if "`cilimiter'" == "" {
        local cilimiter = "-"
    }

    // Include p-values in autolevels only if pvalue option is specified
    if "`pvalue'" != "" {
        qui collect style autolevels result _r_b _r_ci _r_p, clear
    }
    else {
        qui collect style autolevels result _r_b _r_ci, clear
    }

    capture collect composite drop myci
    capture collect label drop cmdset
    capture collect notes, clear

    collect composite define myci = _r_lb _r_ub, delimiter("`cilimiter'") replace
    collect style cell result[myci], nformat(%9.2f) sformat("(%s)")
    
    // Format p-values if option is specified
    if "`pvalue'" != "" {
        collect style cell result[_r_p], nformat(%9.3f) minimum(0.001) sformat("%s")
    }

    capture collect composite drop coefci2
    collect composite define coefci2 = _r_b myci, trim override 
    collect style cell result[coefci2], nformat(%9.`dp'f)

    qui collect style header result, level(hide)
    qui collect style column, dups(center)
    qui collect style cell, border(right, pattern(nil)) font(times new roman)

    // count number of models
    quietly collect levelsof cmdset
    local num_models : word count `s(levels)'

    // Apply custom model labels if provided
    if `"`model'"' != "" {
        tokenize `"`model'"'
        local i = 1
        while `"``i''"' != "" & `i' <= `num_models' {
            quietly collect label values cmdset `i' `"``i''"'
            local ++i
        }
        forval j = `i'/`num_models' {
            quietly collect label values cmdset `j' "Model `j'"
        }
    }
    else {
        foreach item in `s(levels)' {
            quietly collect label values cmdset `item' "Model `item'"
        }
    }

    // Get all variables if all option is specified
    if "`all'" != "" {
        quietly collect levelsof colname
        local varlist `s(levels)'
        qui collect style row stack, nobinder delimiter(" x ")        
        // Exclude constant if option not specified
        if "`constant'" == "" {
            local newlist
            foreach var of local varlist {
                if "`var'" != "_cons" {
                    local newlist `newlist' `var'
                }
            }
            local varlist `newlist'
        }
        
        // Long format layout
        if "`pvalue'" != "" {
            qui collect layout (colname[`varlist']) (cmdset#result[coefci2 _r_p])
            qui collect style row stack, nobinder delimiter(" x ")
        }
        else {
            qui collect layout (colname[`varlist']) (cmdset#result[coefci2])
        }
    }
    else {
        // Default wide format layout for specific variable
        if "`pvalue'" != "" {
            qui collect layout (cmdset)(colname[`varlist']#(result[coefci2 _r_p]))
        }
        else {
            qui collect layout (cmdset)(colname[`varlist']#(result[coefci2]))
        }
    }

    // Apply table title if given
    if "`title'" != "" {
        collect title "`title'"
    }

    // Apply table note(s) if given
    if `"`notes'"' != "" {
        foreach item in `notes' {
            collect notes "`item'"
        }
    }

    //export to word
    qui putdocx clear
    qui putdocx begin, landscape pagesize(A4)
    qui putdocx paragraph
    qui putdocx text (" ")
    collect style putdocx, layout(autofitcontents)
    putdocx collect
	
    // Export to Word if requested
    if `"`export'"' != "" {
        // Parse export option
        collect preview
        putdocx save `export'
    }
    else {
        // Display preview if not exporting
        collect preview
    }
end