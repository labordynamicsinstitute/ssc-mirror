*! version 1.0.6  02May2026
*! Khan & Watts (2009) Accounting Conservatism Measurement
*! Authors: Wu Lianghai, Wu Hanyan, Chen Liwen

program define conservatism
    version 18.0
    syntax using/, [OUTPath(string) SAVE]
    
    // Display program information
    di _n "============================================="
    di "Khan & Watts (2009) Accounting Conservatism Model"
    di "Version 1.0.6 - 02May2026"
    di "Authors: Wu Lianghai, Wu Hanyan, Chen Liwen"
    di "=============================================" _n
    
    // Step 1: Data preparation and variable calculation
    di "Step 1: Loading and preparing data..."
    
    // Fix file path - remove extra quotes and handle spaces
    local using_path = subinstr(`"`using'"', `"""', "", .)
    
    // Check if path exists
    capture cd "`using_path'"
    if _rc != 0 {
        di as error "Path does not exist: `using_path'"
        exit 601
    }
    
    // Import each dataset separately
    di "Loading stock return data..."
    import excel "`using_path'/d1.xlsx", sheet("sheet1") firstrow clear
    destring stkcd, replace
    destring year, replace
    sort stkcd year
    save "`using_path'/temp_d1.dta", replace
    
    di "Loading price and financial ratio data..."
    import excel "`using_path'/d2.xlsx", sheet("sheet1") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    order stkcd year
    drop date
    save "`using_path'/temp_d2.dta", replace
    
    di "Loading asset and profit data..."
    import excel "`using_path'/d3.xlsx", sheet("sheet1") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    gen SIZE = ln(ta)
    sort stkcd year
    drop date
    save "`using_path'/temp_d3.dta", replace
    
    di "Loading market value data..."
    import excel "`using_path'/d4.xlsx", sheet("sheet1") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    drop date
    gen indcd = cond(substr(code,1,1)=="C", substr(code,1,2), substr(code,1,1))
    encode indcd, gen(industry)
    save "`using_path'/temp_d4.dta", replace
    
    // Merge all datasets
    di "Merging datasets..."
    use "`using_path'/temp_d1.dta", clear
    forvalues i = 2/4 {
        merge m:m stkcd year using "`using_path'/temp_d`i'.dta", keep(match) force nogenerate
    }
    
    // Clean up temporary files
    forvalues i = 1/4 {
        capture erase "`using_path'/temp_d`i'.dta"
    }
    
    // Data cleaning
    duplicates drop stkcd year, force
    capture drop ISBSE ST IsNewOrSuspend BeginningStockPrice indcd code
    
    // Check if required variables exist
    capture confirm variable profit MV
    if _rc != 0 {
        di as error "Required variables (profit, MV) not found."
        di as error "Available variables:"
        describe, short
        exit 111
    }
    
    // Set panel data structure
    capture drop __*
    xtset stkcd year
    
    // Generate required variables
    gen X = profit / L.MV
    gen byte D = (R < 0)
    
    // Remove missing values
    di "Cleaning data..."
    local vars R SIZE MTB LEV X D
    foreach v of local vars {
        qui count if missing(`v')
        if r(N) > 0 {
            di "Dropping `r(N)' missing values for `v'"
            drop if missing(`v')
        }
    }
    
    di "Data preparation completed. Observations: " _N
    if _N == 0 {
        di as error "No observations left after data cleaning."
        exit 2000
    }
    
    // Step 2: Estimate Khan & Watts model
    di _n "Step 2: Estimating Khan & Watts (2009) model..."
    
    // First, check if we have enough data for regression
    qui count
    if r(N) < 100 {
        di as error "Insufficient observations for regression: " r(N)
        exit 2001
    }
    
    // Estimate Basu model for initial values with robust standard errors
    di "Estimating Basu model for initial values..."
    reg X D R D#c.R, robust
    matrix init = e(b)
    
    di "Basu model coefficients:"
    matrix list init
    
    // Initialize model type variable
    local model_type ""
    
    // Nonlinear estimation with better error handling
    di "Estimating nonlinear Khan & Watts model..."
    capture noisily nl (X = {b0} + {b1}*D + ({mu0} + {mu1}*SIZE + {mu2}*MTB + {mu3}*LEV)*R ///
       + ({lambda0} + {lambda1}*SIZE + {lambda2}*MTB + {lambda3}*LEV)*D*R), ///
       initial(b0 `=init[1,1]' b1 `=init[1,2]'       ///
               mu0 `=init[1,3]' mu1 0.001 mu2 0.001 mu3 0.001 ///
               lambda0 `=init[1,4]' lambda1 0.001 lambda2 0.001 lambda3 0.001)
    
    if _rc != 0 {
        di as error "Nonlinear regression failed. Trying alternative approach..."
        
        // Alternative: Use linear approximation
        di "Using linear approximation method..."
        gen D_R = D * R
        gen SIZE_R = SIZE * R
        gen MTB_R = MTB * R  
        gen LEV_R = LEV * R
        gen D_SIZE_R = D * SIZE * R
        gen D_MTB_R = D * MTB * R
        gen D_LEV_R = D * LEV * R
        
        reg X D R SIZE_R MTB_R LEV_R D_R D_SIZE_R D_MTB_R D_LEV_R, robust
        estimates store KW_model_linear
        
        // Extract coefficients for C_SCORE calculation
        matrix b = e(b)
        scalar lambda0 = b[1,7]  // D_R coefficient
        scalar lambda1 = b[1,8]  // D_SIZE_R coefficient  
        scalar lambda2 = b[1,9]  // D_MTB_R coefficient
        scalar lambda3 = b[1,10] // D_LEV_R coefficient
        
        di "Linear approximation coefficients:"
        di "lambda0 = " lambda0
        di "lambda1 = " lambda1  
        di "lambda2 = " lambda2
        di "lambda3 = " lambda3
        
        local model_type "linear_approximation"
    }
    else {
        // Store nonlinear estimation results
        estimates store KW_model
        
        // Extract coefficients directly from nl output
        scalar lambda0 = [lambda0]_b[_cons]
        scalar lambda1 = [lambda1]_b[_cons]  
        scalar lambda2 = [lambda2]_b[_cons]
        scalar lambda3 = [lambda3]_b[_cons]
        
        di "Nonlinear model coefficients:"
        di "lambda0 = " lambda0
        di "lambda1 = " lambda1
        di "lambda2 = " lambda2  
        di "lambda3 = " lambda3
        
        local model_type "nonlinear"
    }
    
    // Step 3: Calculate C_SCORE
    di _n "Step 3: Calculating accounting conservatism measure (C_SCORE)..."
    
    gen C_SCORE = lambda0 + lambda1*SIZE + lambda2*MTB + lambda3*LEV
    label variable C_SCORE "Accounting Conservatism Score (Khan & Watts 2009)"
    
    // Step 4: Display results
    di _n "============================================="
    di "RESULTS SUMMARY"
    di "============================================="
    
    // Display descriptive statistics
    di _n "Descriptive Statistics:"
    tabstat X R D SIZE MTB LEV C_SCORE, stat(mean sd p25 p50 p75 N) col(stat)
    
    // Save dataset if requested
    if "`save'" != "" {
        if "`outpath'" == "" {
            local outpath "."
        }
        local savefile_dta "`outpath'/C_Score_Results.dta"
        local savefile_csv "`outpath'/C_Score_Results.csv"
        
        // Save Stata dataset
        save "`savefile_dta'", replace
        // Export CSV file
        export delimited using "`savefile_csv'", replace
        
        di _n "Results saved:"
        di as text "Stata dataset: `savefile_dta'"
        di as text "Type {cmd:browse} to view the Stata dataset."
        di as smcl `"CSV file: {view "`savefile_csv'":`savefile_csv'} (click to open)"'
    }
    
    di _n "Analysis completed successfully!"
    di "Model type: `model_type'"
    di "Final sample size: " _N
end