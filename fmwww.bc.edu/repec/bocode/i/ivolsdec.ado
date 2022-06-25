*! version 1.0.2  June, 2022  Shoya Ishimaru
program ivolsdec, rclass
	version 12.1
	// confirmed to work in versions 12.1 and 15.1

	_iv_parse `0'
	local y `s(lhs)'
	local x `s(endog)'
	local w `s(exog)'
	local z `s(inst)'
	local 0 `s(zero)'
	
	syntax [if] [aw fw pw iw] [, XNBasis(varlist fv) WBasis(varlist fv) XIBasis(varlist fv) VCE(string) DID RDd BINary CGroup(varlist fv) TLevel(numlist) format(string)]
	
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
	
	if ( "`cgroup'"!="" ){
		fvrevar `cgroup'
		local cg `r(varlist)'
		foreach v of varlist `cg'{
			capture tabulate `v'
			if _rc!=0 | (_rc==0 & r(r)!=2) {
				di as error `""cgroup" must be all binary"'
				exit 198
			}
			quietly summarize `v'
			if r(min)!=0 | r(max)!=1 {
				di as error `""cgroup" must be all binary (take on values zero or one)"'
				exit 198
			}
		}
	}
	
	if ( "`binary'"=="" ){
		if ( "`xnbasis'"=="" ){
			di as error `""xnbasis" must be nonempty unless "binary" option is chosen in a command."'
			exit 198
		}
		// make sure basis functions do not include X itself
		foreach v of varlist `xnb' `xib'{
			if ( "`v'"=="`x'" ){
				di as error "xnbasis or xibasis cannot contain a treatment variable itself"
				exit 198
			}
		}		
	}
	else{
		// check if X is really binary
		capture tabulate `x'
		if _rc!=0 | (_rc==0 & r(r)!=2) {
			di as error `"Treatment must be binary when "binary" option is chosen in a command."'
			exit 198
		}	
		if ( "`xnbasis'"!="" ){
			di as error `""xnbasis" must be empty when "binary" option is chosen in a command."'
			exit 198
		}		
		if ( "`xibasis'"!="" ){
			di as error `""xibasis" must be empty when "binary" option is chosen in a command."'
			exit 198
		}		
	}
	
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
		if !( "`xnb'"=="" & "`xib'"=="" ){
			foreach v of varlist `xnb' `xib'{
				tempvar `v'_res
				qui reg `v' `w' [`weight'`exp'] `cond'
				qui predict double ``v'_res' `cond', resid	
			}
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
	
	if ( "`binary'"=="" ){
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
	}
	else{
		// Since treatment is binary, treatment-level weight difference and S.E. are zero.
		local se_tw = 0
		local b_tw = 0
		// Marginal effect difference and S.E.
		tempvar e_me
		qui gen double `e_me' = ( `e_iv'*`z_res' - ( `e_c'*`z_res' + `vhat1'*`zhat1' + `rhat1' ) )/`m_xz' `cond'
		qui reg `e_me' [`weight'`exp'] `cond', `vce_opt'
		local se_me = _se[_cons]
		local b_me = `b_iv'-`b_c'	
	}
	
	matrix define b = (`b_ols',`se_ols' \ `b_iv',`se_iv' \ `b_gap',`se_gap' \ `b_cw',`se_cw' \ `b_tw',`se_tw' \ `b_me',`se_me')
	matrix colnames b = "Coef" "StdErr" 
	matrix rownames b = "OLS" "IV" "IV-OLS Gap" "Covariate Weight" "Treatment-level Wgt" "Marginal Effect"
	matlist b, title("Decomposition Results") twid(19) format(`format')
	disp ""
	disp "Number of Observations: " `Nobs'
	disp "VCE Type: `vce_opt'" 
	return matrix D = b
	
	// compute weights on treatment level
	if ( "`tlevel'"!="" ){
		local nl=0
		local matrows = ""
		foreach i of numlist `tlevel'{
			local nl = `nl'+1
			local matrows = "`matrows'" + " " + "`i' "
		}
		matrix define LW_m = J(`nl',4,0)
		matrix colnames LW_m = "OLS wgt" "(s.e.)" "IV wgt" "(s.e.)"
		matrix rownames LW_m = `matrows'
		local j=0
		foreach i of numlist `tlevel'{
			local j = `j'+1
			tempvar x`j'
			qui gen double `x`j'' = (`x'>=`i')
			qui reg `x`j'' `x' `w' [`weight'`exp'] `cond', `vce_opt'
			matrix LW_m[`j',1] = _b[`x']
			matrix LW_m[`j',2] = _se[`x']
			qui ivregress 2sls `x`j'' (`x'=`z') `w' [`weight'`exp'] `cond', `vce_opt'
			matrix LW_m[`j',3] = _b[`x']
			matrix LW_m[`j',4] = _se[`x']			
		}
		disp ""
		matlist LW_m, title("Weights on Treatment Levels") format(`format')
		return matrix LW = LW_m
	}
	
	// compute weights on treatment groups
	if ( "`cgroup'"!="" ){
		local ng = 0
		foreach v of varlist `cg'{
			local ng = `ng'+1
		}
		local matrows = ""
		fvexpand `cgroup'
		foreach v in `r(varlist)'{
			local matrows = "`matrows'" + " " + "`v' "
		}				
		matrix define CW_m = J(`ng',5,0)
		matrix colnames CW_m = "Share" "OLS wgt" "(s.e.)" "IV wgt" "(s.e.)"
		matrix rownames CW_m = `matrows'
		if ( `didrd'!=0 & `wb_def'!=0 ){
			// For SE correction terms with DID/RD (computed already if wb_def==0)
			tempvar xz xz_hat 
			qui gen double `xz' = `x'*`z_res'
			qui reg `xz' `w' [`weight'`exp'] `cond'
			qui predict double `xz_hat' `cond', xb
		}
		local j = 0
		foreach v of varlist `cg'{
			local j = `j'+1
			qui reg `v' [`weight'`exp'] `cond'
			matrix CW_m[`j',1] =  _b[_cons]
			tempvar w_`v' 
			qui gen double `w_`v'' = `v'*`x_res'
			qui reg `w_`v'' `x' `w' [`weight'`exp'] `cond', `vce_opt'
			matrix CW_m[`j',2] =  _b[`x']
			matrix CW_m[`j',3] = _se[`x']
			if ( `didrd'==0 ){
				qui ivregress 2sls `w_`v'' (`x'=`z') `w' [`weight'`exp'] `cond', `vce_opt'
				matrix CW_m[`j',4] =  _b[`x']
				matrix CW_m[`j',5] = _se[`x']	
			}
			else{
			// slightly different formula for RD/DID
				tempvar `v'_hat `v'_res w`v'_res e`v'_res
				qui reg `v' `w' [`weight'`exp'] `cond'
				qui predict double ``v'_hat' `cond', xb
				qui predict double ``v'_res' `cond', resid
				qui replace `w_`v'' = ``v'_hat'*`x' `cond'
				qui ivregress 2sls `w_`v'' (`x'=`z') `w' [`weight'`exp'] `cond'
				matrix CW_m[`j',4] =  _b[`x']		
				qui predict double `w`v'_res' `cond', resid
				qui gen double `e`v'_res' = (`w`v'_res'*`z_res' + ``v'_res'*`xz_hat')/`m_xz' `cond'
				qui regress `e`v'_res' [`weight'`exp'] `cond', `vce_opt'
				matrix CW_m[`j',5] =  _se[_cons]
			}
		}
		disp ""
		matlist CW_m, title("Weights on Covariate Groups") format(`format')
		return matrix CW = CW_m
	}
	
end
