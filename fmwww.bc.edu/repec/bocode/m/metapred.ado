*! 2.0.0 Ariel Linden 01Nov2020 // this version ensures that all measures produce the same results as METAFOR's -influence()- function
*! 1.0.0 Ariel Linden 14Aug2020 // this version has dfbeta()

program define metapred, rclass
version 16.0

		if "`e(cmd)'"  != "meta regress" {
			di as err "You must first run {bf:meta regress} before calling {bf:metapred}"
			exit
		}
		
		local cmdline = "`e(cmdline)'"
		local model = "`e(model)'"
		local method = "`e(method)'"
		local cmd    = "`e(cmd)'"		
	
		local myopts "RSTAndard RSTUdent DFIts Cooksd Welsch COVratio DFBeta " // DFBeta(string)
		_pred_se "`myopts'" `0'
		
		local typ `s(typ)'
		local varn `s(varn)'
		local 0    `"`s(rest)'"'
	
		syntax [if][in] [, `myopts' ]


		marksample touse

        local oplist "`rstandard' `rstudent' `dfits' `cooksd' `covratio' `dfbeta'"
		opts_exclusive "`oplist'"
		local type "`rstandard'`rstudent'`dfits'`cooksd'`covratio'`dfbeta'"
		if "`type'" == "" {
			di as err "one of the available options must be specified"
			exit 198
		}
		

		***************
		** rstandard **
		***************
		else if "`type'" == "rstandard"  {
			_rsta "`typ'" "`varn'" "`touse'"
		}
		
		***************
		** rstudent **
		***************
		else if "`type'" == "rstudent" {	/* restricted to e(sample) */
			_rstu "`typ'" "`varn'" "`touse'" "`cmdline'"
		} // end rstudent
 
 
 		***************
		** dfits **
		***************
 		else if "`type'" == "dfits" {	/* restricted to e(sample) */
			if "`model'" == "fixed" {
				tempvar hh t
				qui predict double `hh' if `touse', hat
				qui metapred `t' if `touse', rstudent
				gen `typ' `varn' = `t'*sqrt(`hh'/(1-`hh')) if `touse'
				label var `varn' "DFITS"
			} // end fixed
			
			else {
				_dfits "`typ'" "`varn'" "`touse'"
			}
		}
		
		***************
		** cooksd **
		***************
		else if "`type'"=="cooksd" { /* restricted to e(sample) */
			_cooksd "`typ'" "`varn'" "`touse'"
		}
		
		***************
		** covratio **
		***************
		else if "`type'" == "covratio" { /* restricted to e(sample) */
			_covratio "`typ'" "`varn'" "`touse'"
		}

		***************
		** dfbeta **
		***************
		if "`dfbeta'"!="" {	/* restricted to e(sample) */
			_dfbeta "`typ'" "`varn'" "`touse'"
        }
		
end

capture program drop _rsta
program _rsta, rclass
        version 16
		args type newvar touse 
		
		qui {
			if "`e(model)'" == "random" {	
				tempvar resid resid_se
				predict double `resid' if `touse', residuals fixedonly se(`resid_se', marginal)
			} // end random
			
			else if "`e(model)'" == "fixed" {
				tempvar resid resid_se
				predict double `resid' if `touse', residuals se(`resid_se')
			} // end fixed
			
			* gen standardized residuals
			gen `type' `newvar' = `resid' / `resid_se'
			label var `newvar' "Standardized residuals"
		} // end quietly

end		
		

capture program drop _rstu
program _rstu, rclass
        version 16
		args type newvar touse cmdline

			qui {
				tempvar sample indho resid rse
				* account for touse from original meta regress estimation 
				gen `sample' = e(sample)
				* indicator for hold out study
				gen `indho' = .
				count if `sample'==1
				local N = r(N)

				gen double `resid' =.
				gen double `rse' = .
				gen `type' `newvar' = .
				label var `newvar' "Studentized residuals"
				
				// sort so that all touse is at top
				gsort -`sample'
			
				// block to extract options from command line
				local cmdlne = "`e(cmdline)'"
				local right = reverse("`cmdlne'")
				local right = substr("`right'", 1, strpos("`right'", ",") - 1)
				local right = reverse("`right'")
	
				// run LOO loop
				forval i = 1/`N' {
				    replace `indho' = cond(_n==`i',1,0)
					`e(cmd)' `e(indepvars)' `indho' if `sample' == 1, `right'
	
					* save table of estimates as matrix 
					qui matrix b = r(table)
					* retrieve estimate and SE for the indicator for the holdout study 
					local est = b[1,colnumb(matrix(b),"`indho'")]
					local se = b[2,colnumb(matrix(b),"`indho'")]
	
					replace `resid' = `est' if `touse' & _n==`i'
					replace `rse' = `se' if `touse' & _n==`i'
					replace `newvar' = `est' / `se' if `touse' & _n==`i'
				}
				// reset meta regress
				`cmdline'
				
				// resort by trial number
				sort _meta_id
			} // end quietly		
			
end

program define _covratio
	version 16.0
	args type newvar touse

	quietly {
		// grab std errs from data
        local sevar _meta_se

		tempvar sample vi indho
		tempname b_full V_full Vtmp tau2_full tau2tmp cov_i

		// restrict to original estimation sample
		gen byte `sample' = e(sample)

		// save full original command for reset later
		local cmdlne = "`e(cmdline)'"
		local cmd    = "`e(cmd)'"
		local indep  = "`e(indepvars)'"

		// extract all options after comma (if any)
		local right = reverse("`cmdlne'")
		if strpos("`right'", ",") {
			local right = reverse(substr("`right'", 1, strpos("`right'", ",") - 1))
		}
		else local right

		// full model info
		matrix `V_full' = e(V)
		scalar `tau2_full' = e(tau2)

		// initialize output variable (user-visible)
		gen `type' `newvar' = .

		// count usable observations
		quietly count if `sample'
		local N = r(N)

		// holdout indicator
		gen byte `indho' = 0 if `sample'

		// loop through each observation
		forvalues i = 1/`N' {
			quietly replace `indho' = cond(_n == `i', 1, 0)

			// refit model excluding observation i
			capture `cmd' `indep' if `sample' & `indho' == 0, `right'
			if (_rc) continue

			scalar `tau2tmp' = e(tau2)
			if missing(`tau2tmp') continue

			matrix `Vtmp' = e(V)

			// Covariance ratio = det(Vtmp) / det(V_full)
			scalar `cov_i' = det(`Vtmp') / det(`V_full')
            replace `newvar' = `cov_i' in `i' if `touse'
		}

		// reset to original model and restore sort order
		`cmdlne'
		sort _meta_id
        label var `newvar' "Covariance Ratio"
    }
end

program define _cooksd
	version 16.0
	args type newvar touse

	quietly {
		// grab SE from data
        local sevar _meta_se

        tempvar sample vi yhat_full hatval indho
        tempname tau2_full b_full V_full V_inv btmp db cdmat tau2tmp cook_i

		// restrict to original estimation sample
		gen byte `sample' = e(sample)

		// save full original model call for later reset
		local cmdlne = "`e(cmdline)'"
		local cmd    = "`e(cmd)'"
		local indep  = "`e(indepvars)'"

		// extract options after comma (if any)
		local right = reverse("`cmdlne'")
		if strpos("`right'", ",") {
			local right = reverse(substr("`right'", 1, strpos("`right'", ",") - 1))
		}
		else local right

		// -within-study variances
		gen double `vi' = `sevar'^2 if `sample'

		// full model predictions and hat values
		predict double `yhat_full' if `sample', xb
		predict double `hatval' if `sample', hat

		// extract coefficients, variance matrix, and tau² from full model
		matrix `b_full'  = e(b)
		matrix `V_full'  = e(V)
		scalar `tau2_full' = e(tau2)

		// invert full-model variance–covariance matrix
		matrix `V_inv' = syminv(`V_full')

		// initialize output variable (user-visible)
        gen `type' `newvar' = .

		// count observations from estimation model
		quietly count if `sample'
		local N = r(N)

		// holdout indicator
		gen byte `indho' = 0 if `sample'

		// loop through estimation sample (leave-one-out)
		forvalues i = 1/`N' {
			replace `indho' = cond(_n == `i', 1, 0)

			// rerun same meta regression excluding observation i
			capture `cmd' `indep' if `sample' & `indho' == 0, `right'
			if (_rc) continue

			scalar `tau2tmp' = e(tau2)
			if missing(`tau2tmp') continue

			// extract new coefficients
			matrix `btmp' = e(b)

			// compute Cook's D = (b - b_del)' * inv(V_full) * (b - b_del)
			matrix `db' = `b_full' - `btmp'
			matrix `cdmat' = `db' * `V_inv' * `db''
			scalar `cook_i' = `cdmat'[1,1]

			replace `newvar' = `cook_i' in `i' if `touse'
        }

		// reset to original model and restore sort order
		`cmdlne'
		sort _meta_id

        label var `newvar' "Cook's D"
    }
end

program define _dfits
	version 16.0
	args type newvar touse

	quietly {
		// grab std errs
		local sevar _meta_se

		// use original estimation sample only
		tempvar sample
		gen byte `sample' = e(sample)

		// parse command line and components
		local cmdlne = "`e(cmdline)'"
		local cmd    = "`e(cmd)'"
		local indep  = "`e(indepvars)'"

		// extract all options after the comma (if any)
		local right = reverse("`cmdlne'")
		if strpos("`right'", ",") {
			local right = reverse(substr("`right'", 1, strpos("`right'", ",") - 1))
		}
		else local right

		// within-study variances
		tempvar vi yhat_full hatval ydel
		gen double `vi' = `sevar'^2 if `sample'

		// full model predictions and hat values
		tempname tau2_full
		scalar `tau2_full' = e(tau2)

		predict double `yhat_full' if `sample', xb
		predict double `hatval' if `sample', hat

		// initialize output
		gen `type' `newvar' = .
		gen double `ydel' = .

		// count observations in estimation sample
		count if `sample'
		local N = r(N)

		// create a holdout indicator
		tempvar indho
		gen byte `indho' = 0 if `sample'

		// loop over each observation in the estimation sample
		forvalues i = 1/`N' {
			replace `indho' = cond(_n == `i', 1, 0)

			// re-run original meta regression, excluding obs i
			capture `cmd' `indep' if `sample' & `indho' == 0, `right'
			if (_rc) continue

			// extract tau2 and fitted coefficients
			scalar tau2tmp = e(tau2)
			if missing(tau2tmp) continue

			// predicted value for obs i under leave-one-out model
			tempname btmp
			matrix `btmp' = e(b)

			local ydel_i = 0
			if colnumb(`btmp', "_cons") < . {
				local ydel_i = `btmp'[1,"_cons"]
			}

			foreach m of local indep {
				if colnumb(`btmp', "`m'") < . {
					summarize `m' if _n == `i', meanonly
					local xval = r(mean)
					local ydel_i = `ydel_i' + `btmp'[1,"`m'"] * `xval'
				}
			}
			replace `ydel' = `ydel_i' in `i'

			// DFFITS computation
			replace `newvar' = ///
				(`yhat_full'[`i'] - `ydel'[`i']) / ///
				sqrt(max(`hatval'[`i'] * (tau2tmp + `vi'[`i']), 1e-12)) ///
				in `i' if `touse'
        }
		
		// reset to original meta regression
		`cmdlne'

		// restore sort order (by study id)
		sort _meta_id

		label var `newvar' "DFITS"
	}
end

program define _dfbeta
	version 16.0
	args type newvar touse

	quietly {
		// store the original model command to restore later
		local original_cmdline `e(cmdline)'
        
		// use original estimation sample only
		tempvar sample
		gen byte `sample' = e(sample)

		// command line and components for repeating LOO
		local cmdlne = "`e(cmdline)'"
		local cmd    = "`e(cmd)'"
		local indep  = "`e(indepvars)'"

		// extract all options after the comma (if any)
		local right = reverse("`cmdlne'")
		if strpos("`right'", ",") {
			local right = reverse(substr("`right'", 1, strpos("`right'", ",") - 1))
		}
		else local right

		// full model coefficients and names
		tempname b_full
		matrix `b_full' = e(b)
		local bnames : colnames `b_full'
		local p : word count `bnames'
        
		// within-study variances
		tempvar vi
		gen double `vi' = _meta_se^2 if `sample'

		// Create output variables for all observations
		foreach b of local bnames {
			local clean_b = subinstr("`b'", "_cons", "intercept", .)
			local clean_b = subinstr("`clean_b'", ".", "_", .)
			local clean_b = subinstr("`clean_b'", "-", "_", .)
			cap drop `newvar'_`clean_b' // drops variables if they already exist
			local varname `newvar'_`clean_b'
			gen `type' `varname' = . 
			label var `varname' "DFBETA for `b'"
		}

		// count observations
		count if `sample'
		local N = r(N)
		count if `touse'
		local N_touse = r(N)

		// create a holdout indicator
		tempvar indho
		gen byte `indho' = 0 if `sample'

		// loop over each observation in the estimation sample
		forvalues i = 1/`N' {
			replace `indho' = cond(_n == `i', 1, 0)

			// only process if this observation if in the touse sample
			if `touse'[`i'] {
				// re-run original meta regression, excluding obs i
				capture `cmd' `indep' if `sample' & `indho' == 0, `right'
				if (_rc) continue

				// extract tau2 and fitted coefficients
				tempname tau2tmp
				scalar `tau2tmp' = e(tau2)
				if missing(`tau2tmp') continue

				tempname b_tmp
				matrix `b_tmp' = e(b)
				local tmpnames : colnames `b_tmp'

				// compute coefficient differences
                mata: diff_vec = J(1, `p', .)
				local k = 1
				foreach b of local bnames {
					local pos : list posof "`b'" in tmpnames
					if "`pos'" != "" {
						local diff_val = `b_full'[1,"`b'"] - `b_tmp'[1,"`b'"]
						mata: diff_vec[1, `k'] = `diff_val'
					}
					else {
						mata: diff_vec[1, `k'] = .
					}
					local k = `k' + 1
				}

				// compute vb.del using FULL data with leave-one-out tau2
				tempvar wi_temp
				gen double `wi_temp' = 1/(`vi' + `tau2tmp') if `sample'

				// Mata computation
				mata: X_full = st_data(., tokens(st_local("indep")), st_local("sample"))
				mata: w_full = st_data(., st_local("wi_temp"), st_local("sample"))
				mata: cons = J(rows(X_full), 1, 1)
				mata: X_full = (X_full, cons)
				mata: W_mat_full = diag(w_full)
				mata: XWX_full = X_full' * W_mat_full * X_full
				mata: vbdel_full = invsym(XWX_full)
				mata: vbdiag_full = diagonal(vbdel_full)'
                
				// call Mata function
				mata: compute_dfbetas(strtoreal(st_local("i")), st_local("newvar"), ///
					tokens(st_local("bnames")), vbdiag_full, diff_vec)

				drop `wi_temp'
			}
        } // end LOO
        
		// restore the original model
		`original_cmdline'
 	
	} // end quietly
end

// Mata function to get dfbeta names and values for alignment with model order
mata:
void compute_dfbetas(real scalar i, string scalar newvar, string matrix bnames, 
				real rowvector vbdiag_full, real rowvector diff_vec)
{
	for (k = 1; k <= cols(bnames); k++) {
		bname = bnames[k]
        
		// create clean variable name
		clean_b = subinstr(bname, "_cons", "intercept")
		clean_b = subinstr(clean_b, ".", "_")
		clean_b = subinstr(clean_b, "-", "_")
        
		// create full variable name
		varname = newvar + "_" + clean_b
        
		// get values
		dfb = diff_vec[1, k]
		vb_diag = vbdiag_full[1, k]
        
		// compute and store if valid
		if (!missing(dfb) & !missing(vb_diag) & vb_diag > 0) {
			dfbeta_val = dfb / sqrt(vb_diag)
			stata(sprintf("replace %s = %f in %g", varname, dfbeta_val, i))
		}
	}
}
end

