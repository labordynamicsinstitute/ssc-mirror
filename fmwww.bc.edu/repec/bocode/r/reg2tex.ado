*! reg2tex.ado version 1.0.3 - Export regression results to LaTeX using esttab
*! Authors: Wu Lianghai(AHUT) Wu Hanyan(NUAA)

program define reg2tex
    version 16
    syntax [namelist(name=model_list)] , SAVing(string) [ ///
        DECimal(integer 3) STARLevels(string) REPLace ///
        VCE(string) Title(string) threeline LANDscape ///
        modelnames(string asis) label nodepvar nonumbers ///
        b(string) se(string) keep(string) drop(string) order(string) ///
        mtitles(string asis) stats(string) eform(string) ///
        prehead(string asis) postfoot(string asis) ///
        addnotes(string asis) esttab_options(string asis) ///
    ]
    
    // Check if esttab is available
    cap which esttab
    if _rc {
        di as error "esttab is not installed. Please install estout package: ssc install estout"
        exit 499
    }
    
    // Set default star levels if not specified
    if `"`starlevels'"' == "" {
        local starlevels "* 0.10 ** 0.05 *** 0.01"
    }
    else {
        // Convert user's starlevels to proper format
        local starlevels_list `starlevels'
        local starlevels ""
        local symbols "* ** ***"
        
        forval i = 1/`: word count `starlevels_list'' {
            local level `: word `i' of `starlevels_list''
            local symbol `: word `i' of `symbols''
            local starlevels `"`starlevels' `symbol' `level'"'
        }
        local starlevels = trim(`"`starlevels'"')
    }
    
    // Get model list if not specified
    if `"`model_list'"' == "" {
        capt estimates dir
        if _rc {
            di as error "No stored estimates found"
            exit 198
        }
        local model_list `r(names)'
    }
    
    // Check if models exist
    foreach model of local model_list {
        capt estimates restore `model'
        if _rc {
            di as error "Model `model' not found in stored estimates"
            exit 198
        }
    }
    
    // Build esttab options
    local options "starlevels(`starlevels')"
    
    // Add replace option if specified
    if "`replace'" != "" local options "`options' replace"
    
    // Add decimal formatting if not specified by user
    if `"`b'"' == "" & `"`se'"' == "" {
        local width = `decimal' + 4 // Add extra space for sign and decimal point
        local options `"`options' b(%`width'.`decimal'f) se(%`width'.`decimal'f)"'
    }
    
    // Add other options
    foreach opt in label b se keep drop order stats eform ///
                   prehead postfoot addnotes title {
        if `"``opt''"' != "" {
            // Handle addnotes specially to ensure proper quoting
            if "`opt'" == "addnotes" {
                local options `"`options' `opt'("``opt''")"'
            }
            else {
                local options `"`options' `opt'(``opt'')"'
            }
        }
    }
    
    // Handle switches (options without values)
    foreach opt in nodepvar nonumbers {
        if "``opt''" != "" {
            local options `"`options' `opt'"'
        }
    }
    
    // Handle threeline option
    if "`threeline'" != "" {
        local options `"`options' booktabs"'
    }
    
    // Handle landscape option
    if "`landscape'" != "" {
        local options `"`options' page(landscape)"'
    }
    
    // Handle modelnames option (alias for mtitles)
    if `"`modelnames'"' != "" {
        // Remove outer quotes if present
        local modelnames = subinstr(`"`modelnames'"', `"""', "", .)
        local options `"`options' mtitles(`modelnames')"'
    }
    
    // Handle mtitles option directly
    if `"`mtitles'"' != "" {
        local options `"`options' mtitles(`mtitles')"'
    }
    
    // Add esttab-specific options
    if `"`esttab_options'"' != "" {
        // Remove outer quotes from esttab_options
        local esttab_options_clean = subinstr(`"`esttab_options'"', `"""', "", .)
        local options `"`options' `esttab_options_clean'"'
    }
    
    // Execute esttab with proper filename handling
    di as text "Running: esttab `model_list' using `saving', `options'"
    esttab `model_list' using `saving', `options'
    
    // User feedback
    di as text _n `"LaTeX table saved to {browse "`saving'":`saving'}"'
    di as text "Number of models: `: word count `model_list''"
    di as text "Star levels: `starlevels'"
    di as text "Models: `model_list'"
    di as text "Authors: Wu Lianghai (AHUT), Wu Hanyan (NUAA)"
end