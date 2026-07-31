cap program drop nnlme
program define nnlme, eclass byable(onecall) prop(me xt mi bayes xtbs)
    version 17.0

    // Step 1: Parse the dependent variable
    syntax varlist(min=1 max=1) [if] [in], ///
        SURV(varlist) Time(varname)  ///
		[ID(varname)] ///
        [SHAPE(varlist)] [ITer(integer 0)]		///
		[	METHod(string)		///
			RESCOVariance(string)	///
			RESCORRelation(string) 	///
			RESVARiance(string)	///
			INITial(string)		///
			lmeopts(string)		///
			pnlsopts(string)	///
			NOCONStant		/// /* eq linear form	*/
			xb			/// /* eq linear form	*/
			EMITERate(passthru)	///
			EMTOLerance(passthru)	///
			emlog			///
		]
    // Extract dependent variable
    gettoken depvar rest : varlist

    // Validate required options
    if "`id'" == "" {
        di as error "option id() is required"
        exit 198
    }
    if "`surv'" == "" {
        di as error "option surv() is required"
        exit 198
    }
    if "`time'" == "" {
        di as error "option time() is required"
        exit 198
    }

    capture confirm numeric variable `time'
    if _rc {
        di as error "The variable specified in time() must be numeric."
        exit 198
    }
	qui 

    // Run the model
    di as txt " "
    di as txt " "
    di as txt ">>> Starting up NNLME <<<"
    di as txt " "
    di as txt " "
	
	// Set default iteration count
    if `iter' == 0 {
        local iter = 25
    } 
	else {
        di as txt ">>> Max Iteration Set: `iter'"
    }

        // Build the model based on whether shape variables are specified
        if "`shape'" != "" {
            menl `depvar' = {ri1:} + {surv:}*{sl1:} + {shp:}, ///
                define(ri1: U0[`id'] , xb) ///
                define(shp: `shape', xb) ///
				define(sl1: -exp({a00})) ///
                define(surv: ln(1 + exp(min(700, `time' - exp(-{curv_c1: `surv', xb}))))) ///
                iterate(`iter') ///
                stddev noretable nofetable noheader
        }
        else {
            menl `depvar' = {ri1:} + {surv:}*{sl1:}, ///
                define(ri1: U0[`id'], xb) ///
				define(sl1: -exp({a00})) ///
                define(surv: ln(1 + exp(min(700, `time' - exp(-{curv_c1: `surv', xb}))))) ///
                iterate(`iter') ///
                stddev noretable nofetable noheader
        }
		
    // Check if model estimation succeeded
    if _rc {
        di as error ">>> Model estimation failed, code: `_rc'."
        exit _rc
    }
   // Store estimation results
    tempname coef V coef_mat
    matrix `coef' = e(b)
    matrix `coef_mat' = e(b)
    matrix `V' = e(V)
    local N = e(N)
	local L = e(ll)
	local fit = round(e(ll),.01)
    local names : colnames `coef_mat'
    local n_coef = colsof(`coef_mat')
	local eqs : coleq `coef_mat'
    local p = round(e(p),.001)
	local ch = round(e(chi2),.01)
	mat def H = e(hierstats)
	local group = H[1,1]
	local hier = round(H[1,2],.001)
    
    ereturn post `coef' `V', obs(`N') 
	ereturn scalar ll = `L'
    ereturn local cmd "nnlme"
   
	// Custom display routine
    di as txt _n "Nested Non-Linear Longitudinal Mixed-Effects Model" _col(58) "Number of obs" _col(72) "= "  as res `N'
    di as txt "Group Variable: `id' "	_col(58) "N. Groups" _col(72) "= "  as res `group'
    di as txt " "	_col(45) "Obs. w/in Groups" _col(72) "= "  as res `hier'
	di as txt _col(58) "Wald chi2"  _col(72) "= " as res "`ch'"
	di as txt "Linearization log likelihood = `fit'"	_col(58) "Prob. > Chi2" _col(72) "= " as res "`p'"
	di as txt " "	
	
	// Track printed sections
	local surv_printed = 0
	local shape_printed = 0
	local a00_printed = 0
	local first_cons = 1
	local re_printed = 0
	local resid_printed = 0

	forvalues i = 1/`n_coef' {
		local eq : word `i' of `eqs'
		local vname : word `i' of `names'

		// Identify parameter type
		local is_shape = ("`eq'" == "shp")
		local is_surv = ("`eq'" == "curv_c1")
		local is_cons = ("`vname'" == "_cons")
		local is_a00 = ("`eq'" == "a00" | "`vname'" == "a00")
		local is_re = ("`eq'" == "`id'" | "`vname'" == "`id'" | strpos("`vname'", "lnsd"))
		local is_resid = strpos("`vname'", "lnsigma")

	
		// Skip if not relevant
		if !(`is_surv' | `is_shape' | `is_a00' | `is_re' | `is_resid') continue

		// Print headers
		if `is_surv' & !`surv_printed' {
			di as txt "{hline 80}"
			di as txt _col(14) "{c |}" _col(20) "NIR" _col(30) "Std. Err." _col(45) "Z" _col(52) "P>|Z|" _col(60) "[95% Conf. Interval]"
			di as txt "{hline 13}{c +}{hline 67}"    
			di as txt "/survival" _col(14) "{c |}"
			local surv_printed = 1
		}
		if `is_shape' & !`shape_printed' {
			di as txt "{hline 13}{c +}{hline 67}"
			di as txt _col(14) "{c |}" _col(20) "Coef." _col(30) "Std. Err." _col(45) "Z" _col(52) "P>|z|" _col(60) "[95% Conf. Interval]"
			di as txt "{hline 13}{c +}{hline 67}"
			di as txt "/shape" _col(14) "{c |}"
			local shape_printed = 1
		}
		if `is_a00' & !`a00_printed' {
			di as txt "{hline 13}{c +}{hline 67}"
			di as txt "/acc. param." _col(14) "{c |}"
			local a00_printed = 1
		}
		if `is_re' & !`re_printed' {
		di as txt "{hline 13}{c +}{hline 67}"
		di as txt "Random Eff." _col(14) "{c |}" _col(20) "Est." _col(30) "Std. Err." _col(45) "Z" _col(52) "P>|z|" _col(60) "[95% Conf. Interval]"
		di as txt "{hline 13}{c +}{hline 67}"
		di as txt "/`id'" _col(14) "{c |}"
        local re_printed = 1
		}
		if `is_resid' & !`resid_printed' {
			di as txt "/residual" _col(14) "{c |}"
			local resid_printed = 1
		}
		// Extract statistics
		local coef = `coef_mat'[1, `i']
		local se = sqrt(e(V)[`i', `i'])
		local z = `coef' / `se'
		local p = 2*(1 - normal(abs(`z')))
		local ci_lb = `coef' - 1.96*`se'
		local ci_ub = `coef' + 1.96*`se'

		// Rename second _cons in shape to intercept
		local display_vname "`vname'"
		if "`vname'" == "_cons" & `first_cons' & `is_shape' {
			local display_vname "intercept"
			local first_cons = 1
		}
	
		// Custom display formatting
		if `is_surv' {
			local display_coef = exp(`coef')
			local display_ci_lb = exp(`ci_lb')
			local display_ci_ub = exp(`ci_ub')
		}   

		else {
			local display_coef = `coef'
			local display_ci_lb = `ci_lb'
			local display_ci_ub = `ci_ub'
		}

	// Display row
	di as txt %12s "`display_vname'" _col(14) "{c |}" as res ///
    _col(16) %9.0g `display_coef' ///
    _col(28) %9.0g `se' ///
    _col(40) %6.2f `z' ///
    _col(49) %6.3f `p' ///
    _col(58) %9.0g `display_ci_lb' ///
    _col(70) %9.0g `display_ci_ub'
	}
	if e(converged)==1 {
		di "Warning: Convergence not achieved."
}
di as txt "{hline 80}"
end
