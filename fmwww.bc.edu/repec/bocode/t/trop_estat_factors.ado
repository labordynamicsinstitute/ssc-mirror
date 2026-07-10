*! Post-estimation analysis of the latent factors

program define trop_estat_factors
    version 17
    
    // Check if the last estimation command was trop
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }
    
    // Verify the existence of the factor matrix in e()
    capture confirm matrix e(factor_matrix)
    if _rc {
        di as error "factor matrix not found in estimation results"
        di as error "This may occur if the estimation did not produce a factor matrix"
        exit 111
    }
    
    // Retrieve dimensions of the factor matrix
    tempname L
    matrix `L' = e(factor_matrix)
    local T = rowsof(`L')
    local N = colsof(`L')
    
    // Display the analysis header
    di as txt ""
    di as txt "Factor Matrix (L) Analysis"
    di as txt "{hline 61}"
    di as txt "Dimensions:       T = " as res `T' as txt ", N = " as res `N'
    di as txt ""
    
    // Ensure the required Mata function is loaded
    capture mata: mata which _trop_estat_factors_svd()
    if _rc {
        capture _trop_load_mata
        if _rc {
            capture findfile trop_estat_helpers.mata
            if !_rc {
                qui do "`r(fn)'"
            }
            else {
                di as error "Mata function _trop_estat_factors_svd() not found."
                di as error "Run {cmd:trop} first, or ensure TROP Mata libraries are installed."
                exit 111
            }
        }
    }
    
    // Compute and display singular value decomposition of factors
    mata: _trop_estat_factors_svd("`L'")
    
    di as txt "{hline 61}"
end
