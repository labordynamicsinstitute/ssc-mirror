*! 1.0.0 Ariel Linden 08Oct2025

program define auto_factor, rclass
    version 11
    syntax varlist(numeric) [if] [in]  [aw fw], ///
        [ METHod(string) COMPare SCREEplot * ]

    * Error if both method() and compare are specified
    if "`method'" != "" & "`compare'" != "" {
        di as err "Cannot specify both method() and compare simultaneously"
        exit 198
    }

    * Set default method if neither provided
    if "`method'" == "" & "`compare'" == "" {
        local compare compare
    }

    * Validate method input
    if "`method'" != "" {
        if !inlist("`method'", "pf", "ipf", "pcf", "ml") {
            di as err "'`method'' is not a valid method. Choose from: pf, ipf, pcf, or ml"
            exit 198
        }
    }
	
    marksample touse
	
	qui count if `touse'
    if r(N) < 10 {
        di as err "Too few observations (N < 10) for factor analysis"
        exit 2001
    }
	
	local nvars : word count `varlist'
    local nobs = r(N)
	
	if "`weight'" != "" {
		local wght [`weight'`exp']
	}
	
    * Display header
    di ""
    di "GENERAL INFORMATION"
    di "==================="
    di as text "Variables: `varlist'"	
    di as text "Number of variables: " as result `nvars'
    di as text "Number of observations:" as result " `nobs'
    if "`compare'" != "" {
        di as text "Method comparison: ENABLED"
    }
    if "`method'" != "" {
        di as text "Selected method: `method'"
        if "`screeplot'" != "" {
            di as text "Scree plot: ENABLED"
        }
    }
    di ""

    *************
	* KMO Measure
	*************
    quietly factor `varlist' `wght' if `touse',  pf `options'
    quietly estat kmo
    di as result "KMO MEASURE OF SAMPLING ADEQUACY"
    di as result "================================"
    di as text "Overall KMO: " as result %6.4f r(kmo)
    if r(kmo) >= 0.9 di as text "{ul:Interpretation}: Marvelous (very suitable for factor analysis)"
    else if r(kmo) >= 0.8 di as text "{ul:Interpretation}: Meritorious (good suitability)"
    else if r(kmo) >= 0.7 di as text "{ul:Interpretation}: Middling"
    else if r(kmo) >= 0.6 di as text "{ul:Interpretation}: Mediocre"
    else if r(kmo) >= 0.5 di as text "{ul:Interpretation}: Miserable"
    else di as err "{ul:Interpretation}: Unacceptable (data likely unsuitable for factor analysis)"
    di " "

	**************************
    * Constant variables check
	**************************
    di as result "DATA SUITABILITY CHECKS"
    di as result "======================="
    
    local constant_vars = 0
    foreach var of local varlist {
        quietly summarize `var' `wght' if `touse'
        if r(sd) == 0 {
            di as err "Warning: Variable `var' was found to be constant"
            local constant_vars = `constant_vars' + 1
        }
    }
    if `constant_vars' == 0 {
        di as text "No constant variables were found"
        di as text "{ul:Interpretation}: All variables have variance, suitable for factor analysis"
    }
    else {
        di as err "`constant_vars' constant variable(s) found."
        di as err "{ul:Interpretation}: Constant variables may distort factor analysis; consider removing them"
    }
    di " "
	
	*******************************************
	* Check if correlation matrix is invertible
	*******************************************
    tempname R R_inv
	quietly correlate `varlist' if `touse'
    matrix `R' = r(C)
    capture matrix `R_inv' = inv(R)
    if _rc != 0 {
        di as err "Correlation matrix is singular"
        di as err "{ul:Interpretation}: Perfect linear dependencies detected; factor analysis may not be appropriate"
    }
    else {
        di as text "Correlation matrix is invertible"
        di as text "{ul:Interpretation}: No perfect linear dependencies among variables; suitable for factor analysis"
    }
    di " "

	*****************
    * Bartlett's test
	*****************
    tempname B
    quietly matrix accum `B' = `varlist' if `touse', nocons dev
    matrix `B' = corr(`B')
    local p = `nvars'
    local n = r(N)
    local df = (1/2)*`p'*(`p'-1)
    local chi2 = -(`n'-1-(1/6)*(2*`p'+5))*ln(det(`B'))
    local pval = chi2tail(`df', `chi2')
    di as text "Bartlett's test of sphericity: chi2("as result `df' as text") = " as result %9.3f `chi2' as text", p = " as result %6.4f `pval'
    if `pval' < 0.05 {
        di as text "{ul:Interpretation}: Factor model likely appropriate"
	}	
    else {
        di as err "{ul:Interpretation}: Correlation structure may not support factor analysis"
    }
    di ""

	*************************************
	* Multivariate normality check for ML
	*************************************
    local ml_needed = 0
    if "`method'" == "ml" | "`compare'" != "" {
		local ml_needed = 1
	}	
    if `ml_needed' {
		di as result "MULTIVARIATE NORMALITY TEST FOR ML"
		di as result "=================================="
		
		if "`weight'" == "aweight" {
			di as text "{ul:NOTE}: the test for multivariate normality does not allow aweights (only fweights), therefore"
			di as text "         normality will be tested without weights"
			di " "
			qui mvtest normal `varlist' if `touse'
		}
		else {
			qui mvtest normal `varlist' `wght' if `touse'
		}
		
		local chi2 = r(chi2_dh)
		local pval = r(p_dh)
		local df = r(df_dh)
		di as text "Doornik-Hansen omnibus test of multivariate normality: chi2("as result `df' as text") = " as result %9.3f `chi2' as text",  Prob>chi2 = " as result %7.4f `pval'
		if `pval' >= 0.05 {
			di as text "{ul:Interpretation}: Multivariate normality assumption satisfied for ML"
		}
		else {
			di as text "{ul:Interpretation}: Multivariate normality assumption violated for ML"
		}
		di " "
	} // end ML_needed
	
    ***************************
	* Comparison across methods
	***************************
	if "`compare'" != "" {
		tempname results
		matrix `results' = J(4, 2, .)
		local methods pf ipf pcf ml
		local i = 1
		foreach m of local methods {
			capture quietly factor `varlist' `wght' if `touse', `m' `options'
			if !_rc {
				matrix `results'[`i',1] = e(f)
				menger_estat
				matrix `results'[`i',2] = r(elbow)
            }
            local ++i
        }
        matrix rownames `results' = PF IPF PCF ML
        matrix colnames `results' = Stata Menger
        di as result "NUMBER OF FACTORS BY METHOD"
        di as result "==========================="
        matlist `results', twidth(8) format(%7.0f) rowtitle("Method") border(top bottom)
        di ""
		di as text "{ul:note}: Stata uses the count of positive eigenvalues as the default number of factors" 
		di as text "      Menger refers to the Menger curvature where the curve becomes more flat (the elbow)"
		
		// save results
		return matrix results = `results'
    }
	
	*********************    
	* Run selected method
	*********************
	else {
        tempname uniq 
		quietly factor `varlist' `wght' if `touse', `method' `options'
        local factors = e(f)
		menger_estat
		local elbow = r(elbow)
		
		di as result "SELECTED METHOD"
		di as result "================"

        di as text "Selected method: `method'"
        di as text "Number of factors determined by Stata's -factor-  : " as result `factors'
        di as text "Number of factors determined by Menger's curvature: " as result `elbow'		
		di ""		
		
		di as result "UNIQUENESS CHECK"
		di as result "================"
		matrix `uniq' = e(Psi)
		local high_uniq_count = 0

		forvalues i = 1/`nvars' {
		local u = `uniq'[1, `i']
			if `u' > 0.70 {
				local high_uniq_count = `high_uniq_count' + 1
			}
		}

		if `high_uniq_count' > 0 {
			if `high_uniq_count' == 1 {
				di as result `high_uniq_count' as text " variable has high uniqueness (> 0.70)"
				di as text "{ul:Interpretation}: This variable is poorly explained by the factor solution. Consider removing it from the analysis"	
			}
			else {
				di as result "`high_uniq_count' as text " variable(s) have high uniqueness (> 0.70)
				di as text "{ul:Interpretation}: These variables are poorly explained by the factor solution. Consider removing them from the analysis"	
			}
		} 
		else {
			di as text "All variables are adequately represented by the factor solution (uniqueness ≤ 0.70)."
		}
		di ""
		
		************
        * Scree plot
		************
        if "`screeplot'" != "" {
            screeplot
        }
		
		***********************
		* Predict factor scores
		***********************
        quietly factor `varlist' `wght' if `touse', `method' `options'

		* drop predicted scores in the data
		local score_names : char _dta[score_names]
		if "`score_names'" != "" {
			foreach v of local score_names {
				capture drop `v'
			}
		}
        di as result "PREDICTIONS"
        di as result "==========="		
		qui predict _score*
		qui ds _score*, has(type numeric)
		local score_names `r(varlist)'
		char def _dta[score_names] "`score_names'"
		
        di as text "Predicted factor values added to the data for " as result `factors' as text " factors"		

        local factor_names
        forvalues i = 1/`factors' {
            local fname _score`i'
            local factor_names "`factor_names' `fname'"
        }

        di as text "{ul:Predicted factor values created}: `factor_names'"
    }

end
