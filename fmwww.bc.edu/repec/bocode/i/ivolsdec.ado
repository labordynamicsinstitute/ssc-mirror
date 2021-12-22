*! version 1.0.1  October, 2021  Shoya Ishimaru
program ivolsdec, rclass
	version 12.1
	// confirmed to work in versions 12.1 and 15.1

	_iv_parse `0'
	local y `s(lhs)'
	local x `s(endog)'
	local w `s(exog)'
	local z `s(inst)'
	local 0 `s(zero)'
	
	syntax [if] [aw fw pw iw], XNBasis(varlist fv) [WBasis(varlist fv) XIBasis(varlist fv) VCE(string) DID RDd format(string)]
	
	// check if did or rd option is specified
	local didrd = 0
	if ( "`did'"!="" ){
		local didrd = 1
	}
	else if ( "`rdd'"!="" ){
		local didrd = 2
	}
	
	display " Outcome (Y): " "`y'"
	display " Treatment (X): " "`x'"
	if ( `didrd'==0 ){
		display " Instruments (Z): " "`z'"
	}
	else if ( `didrd'==1 ){
		display " Instruments (Z): " "`z' (DID-type)"	
	}
	else if ( `didrd'==2 ){
		display " Instruments (Z): " "`z' (RD-type)"
	}
	display " Covariates (W): " "`w'"
	display ""
	
	local xn = `:word count `x''
	if ( `xn'!=1 ){
		di as error "There are " `xn' " treatment variables"
		exit 198	
	}
	
	// Set up vce option (default is robust)
	if ( "`vce'"=="" ){
		local vce_opt "robust"
	}
	else{
		local vce_opt "vce(`vce')"
	}
	
	// set up basis function q(W)
	// default is q(W)=W
	if ( "`wbasis'"=="" ){
		local wb `w'
		local wb_def = 1
	}
	else{
		local wb `wbasis'
		local wb_def = 0
	}

	//" To demompose an IV-OLS gap, this command performs two auxiliary regressions"
	//" Y = W'a1 + (q(W)'b1)*X + e1, and"
	//" Y = W'a2 + (q(W)'b2)*X + q(W)'(C2)r(X) + p(X)'d2 + e2,"
	display " Basis functions for auxiliary regressions have been specified as below."
	display " p(X): `xnbasis'"
	display " q(W): `wb'"
	display " r(X): `xibasis'"
	display " See -help ivolsdec- for what they are and how they should be chosen."
	display " "
	
	// convert factor variables
	fvrevar `z'
	local zr `r(varlist)'
	fvrevar `w'
	local wr `r(varlist)'
	fvrevar `wb'
	local wb `r(varlist)'
	fvrevar `xibasis'
	local xib `r(varlist)'
	fvrevar `xnbasis'
	local xnb `r(varlist)'
	
	// Identify observations with no missing values  
	tempvar mask
	qui gen int `mask' = 1
	foreach v of varlist `y' `x' `zr' `wr' `wb' `xib' `xnb'{
		qui replace `mask' = `mask'*!missing(`v')
	}
	if ( "`if'"=="" ){
		local cond "if `mask'==1"
	}
	else{
		local cond "`if' & `mask'==1"
	}
	
	tempvar e_ols e_iv x_hat x_res z_res
	// Run OLS
	qui reg `y' `x' `w' [`weight'`exp'] `cond', `vce_opt'
	qui predict double `e_ols' `cond', resid
	local b_ols = _b[`x']
	local se_ols = _se[`x'] 
	local Nobs = e(N)
	
	// Run IV
	qui ivregress 2sls `y' (`x'=`z') `w' [`weight'`exp'] `cond', `vce_opt'
	qui predict double `e_iv' `cond', resid
	local b_iv = _b[`x']
	local se_iv = _se[`x'] 
	
	// Run first stage
	qui reg `x' `z' `w' [`weight'`exp'] `cond'
	qui predict double `x_hat' `cond', xb
	
	// Compute residuals
	qui reg `x' `w' [`weight'`exp'] `cond'
	qui predict double `x_res' `cond', resid
	qui reg `x_hat' `w' [`weight'`exp'] `cond'
	qui predict double `z_res' `cond', resid
	
	if ( "`weight'"=="" ){
		qui corr `x_res' `z_res' `cond', covar	
	}
	else{
		qui corr `x_res' `z_res' [aw`exp'] `cond', covar
	}
	local m_xx = r(Var_1)
	local m_xz = r(cov_12)	
	
	if ( `didrd'==0 ){
		foreach v of varlist `xnb' `xib'{
			tempvar `v'_res
			qui reg `v' `w' [`weight'`exp'] `cond'
			qui predict double ``v'_res' `cond', resid	
		}
	}
	else if ( `wb_def'==0 ){
		// for computing correction terms when q(W) is not linear in W for DID/RDD
		tempvar xz xz_hat 
		qui gen double `xz' = `x'*`z_res'
		qui reg `xz' `w' [`weight'`exp'] `cond'
		qui predict double `xz_hat' `cond', xb
		// linear projection of q(W)
		foreach v of varlist `wb'{
			tempvar `v'_res `v'_hat
			qui reg `v' `w' [`weight'`exp'] `cond'
			qui predict double ``v'_res' `cond', resid
			qui predict double ``v'_hat' `cond', xb
		}	
		// linear projection of r(X)*Z
		if ( "`xib'"!="" ){
			foreach u of varlist `xib'{		
				tempvar `u'z `u'z_hat
				qui gen double ``u'z' = `u'*`z_res'
				qui reg ``u'z' `w' [`weight'`exp'] `cond'
				qui predict double ``u'z_hat' `cond', xb				
			}
		}
	}

	// IV-OLS gap
	tempvar e_gap
	qui gen double `e_gap' = `e_iv'*`z_res'/`m_xz' - `e_ols'*`x_res'/`m_xx' `cond'
	qui reg `e_gap' [`weight'`exp'] `cond', `vce_opt'
	local se_gap = _se[_cons]
	local b_gap = `b_iv'-`b_ols'
	
	// Predict Y by W'a + (q(W)'b)*X
	tempvar mhat1 vhat1 zhat1 rhat1
	local qx
	foreach v of varlist `wb'{
		tempvar `v'_x
		qui gen double ``v'_x' = `v'*`x' `cond'
		local qx `qx' ``v'_x'
	}
	qui reg `y' `x' `qx' `w' [`weight'`exp'] `cond'
	qui predict double `vhat1' `cond', resid
	if ( `didrd'==0 ){
		qui gen double `mhat1' = _b[`x']*`x_res' `cond'
		qui gen double `rhat1' = 0 `cond'
		foreach v of varlist `wb'{
			qui replace `mhat1' = `mhat1' + _b[``v'_x']*`v'*`x_res' `cond'
		}
		qui reg `z_res' `x' `qx' `w' [`weight'`exp'] `cond'
		qui predict double `zhat1' `cond', xb		
	}
	else if ( `wb_def'==1 ){
		qui predict double `mhat1' `cond', xb
		qui gen double `rhat1' = 0 `cond'
		qui reg `z_res' `x' `qx' `w' [`weight'`exp'] `cond'
		qui predict double `zhat1' `cond', xb		
	}
	else{
		qui gen double `mhat1' = _b[`x']*`x' `cond'
		qui gen double `rhat1' = 0 `cond'
		foreach v of varlist `wb'{
			qui replace `mhat1' = `mhat1' + _b[``v'_x']*``v'_hat'*`x' `cond'
			qui replace `rhat1' = `rhat1' + _b[``v'_x']*``v'_res'*`xz_hat' `cond'
		}
		local qx_hat
		foreach v of varlist `wb'{
			tempvar `v'hat_x
			qui gen double ``v'hat_x' = ``v'_hat'*`x' `cond'
			local qx_hat `qx_hat' ``v'hat_x'
		}		
		qui reg `z_res' `x' `qx_hat' `w' [`weight'`exp'] `cond'
		qui predict double `zhat1' `cond', xb		
	}

	tempvar e_c e_cw
	// Compute covariate weight difference and S.E.
	qui ivregress 2sls `mhat1' (`x'=`z') `w' [`weight'`exp'] `cond'
	qui predict double `e_c' `cond', resid
	local b_c = _b[`x']
	qui gen double `e_cw' = ( `e_c'*`z_res' + `vhat1'*`zhat1' + `rhat1' )/`m_xz' - `e_ols'*`x_res'/`m_xx' `cond'
	qui reg `e_cw' [`weight'`exp'] `cond', `vce_opt'
	local se_cw = _se[_cons]
	local b_cw = `b_c'-`b_ols'
	
	// Predict Y by W'a + (q(W)'b)*X + q(W)'Cr(X) + p(X)'d
	tempvar mhat2 vhat2 zhat2 rhat2
	local qwx
	if ( "`xib'"!="" ){
		foreach u of varlist `xib'{
			foreach v of varlist `wb'{
				tempvar `v'_`u'
				qui gen double ``v'_`u'' = `v'*`u' `cond'
				local qwx `qwx' ``v'_`u''
			}
		}
	}
	qui reg `y' `x' `qx' `qwx' `xnb' `w' [`weight'`exp'] `cond'
	qui predict double `vhat2' `cond', resid
	if ( `didrd'==0 ){
		qui gen double `mhat2' = _b[`x']*`x_res' `cond'
		qui gen double `rhat2' = 0 `cond'
		foreach v of varlist `xnb'{
			qui replace `mhat2' = `mhat2' + _b[`v']*``v'_res' `cond'
		}		
		foreach v of varlist `wb'{
			qui replace `mhat2' = `mhat2' + _b[``v'_x']*`v'*`x_res' `cond'
			if ( "`xib'"!="" ){
				foreach u of varlist `xib'{
					qui replace `mhat2' = `mhat2' + _b[``v'_`u'']*`v'*``u'_res' `cond'
				}
			}
		}
		qui reg `z_res' `x' `qx' `qwx' `xnb' `w' [`weight'`exp'] `cond'
		qui predict double `zhat2' `cond', xb		
	}	
	else if ( `wb_def'==1 ){
		qui predict double `mhat2' `cond', xb
		qui gen double `rhat2' = 0 `cond'
		qui reg `z_res' `x' `qx' `qwx' `xnb' `w' [`weight'`exp'] `cond'
		qui predict double `zhat2' `cond', xb		
	}	
	else{
		qui gen double `mhat2' = _b[`x']*`x' `cond'
		qui gen double `rhat2' = 0 `cond'
		foreach v of varlist `xnb'{
			qui replace `mhat2' = `mhat2' + _b[`v']*`v' `cond'
		}	
		local qwx_hat
		foreach v of varlist `wb'{
			qui replace `mhat2' = `mhat2' + _b[``v'_x']*``v'_hat'*`x' `cond'
			qui replace `rhat2' = `rhat2' + _b[``v'_x']*``v'_res'*`xz_hat' `cond'
			if ( "`xib'"!="" ){
				foreach u of varlist `xib'{
					qui replace `mhat2' = `mhat2' + _b[``v'_`u'']*``v'_hat'*`u' `cond'
					qui replace `rhat2' = `rhat2' + _b[``v'_`u'']*``v'_res'*``u'z_hat' `cond'
					tempvar `v'hat_`u'
					qui gen double ``v'hat_`u'' = ``v'_hat'*`u' `cond'
					local qwx `qwx' ``v'hat_`u''
				}
			}
		}	
		qui reg `z_res' `x' `qx_hat' `qwx_hat' `xnb' `w' [`weight'`exp'] `cond'
		qui predict double `zhat2' `cond', xb		
	}
	
	tempvar e_ct e_tw e_me
	// Compute treatment-level weight difference and S.E.
	qui ivregress 2sls `mhat2' (`x'=`z') `w' [`weight'`exp'] `cond'
	qui predict double `e_ct' `cond', resid
	local b_ct = _b[`x']
	qui gen double `e_tw' = ( (`e_ct'*`z_res' + `vhat2'*`zhat2' + `rhat2' ) - (`e_c'*`z_res' + `vhat1'*`zhat1' + `rhat1' ) )/`m_xz' `cond'
	qui reg `e_tw' [`weight'`exp'] `cond', `vce_opt'
	local se_tw = _se[_cons]
	local b_tw = `b_ct'-`b_c'

	// Marginal effect difference and S.E.
	qui gen double `e_me' = ( `e_iv'*`z_res' - (`e_ct'*`z_res' + `vhat2'*`zhat2' + `rhat2' ) )/`m_xz' `cond'
	qui reg `e_me' [`weight'`exp'] `cond', `vce_opt'
	local se_me = _se[_cons]
	local b_me = `b_iv'-`b_ct'
	
	matrix define b = (`b_ols',`se_ols' \ `b_iv',`se_iv' \ `b_gap',`se_gap' \ `b_cw',`se_cw' \ `b_tw',`se_tw' \ `b_me',`se_me')
	matrix colnames b = "Coef" "StdErr" 
	matrix rownames b = "OLS" "IV" "IV-OLS Gap" "Covariate Weight" "Treatment-level Wgt" "Marginal Effect"
	matlist b, title("Decomposition Results") twid(19) format(`format')
	disp ""
	disp "Number of Observations: " `Nobs'
	disp "VCE Type: `vce_opt'" 
	return matrix D = b
end
