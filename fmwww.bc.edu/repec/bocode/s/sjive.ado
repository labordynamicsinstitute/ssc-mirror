*! Dec 1, 2025 - Adjusted code to include partialled out Z's in shrinkage & s.e. calculation
*! Dec 9, 2025 - Added constants to the jk_fit program and clean var versions to jk_fit calls
*! Dec 23, 2025 - Added force option

capture program drop jk_fit
program define jk_fit, rclass
	syntax varlist [if], gen(name) [genres(name) genlev(name)]
	
	local y : word 1 of `varlist' //Dependent Variable First
	local x : list varlist - y       //All other variables
		
	marksample tousevar
	
	// Create the output variables first
	qui gen `gen' = .
	if ("`genlev'" != "") {
		qui gen `genlev' = .
	}
	if ("`genres'" != "") {
		qui gen `genres' = .
	}
	
	tempvar ones
    qui gen `ones' = 1
	
	// Get leverage using mata 
    mata: X = st_data(., tokens("`x' `ones'"), "`tousevar'")
    mata: y = st_data(., "`y'", "`tousevar'")
    mata: XXinv = invsym(cross(X, X))
    mata: fit = X * (XXinv * cross(X, y))
    mata: lev = rowsum(X :* (X * XXinv))
    mata: gen = (fit :- y :* lev) :/ (1 :- lev)
    mata: st_store(., "`gen'", "`tousevar'", gen)
	
    if ("`genlev'" != "") {
        mata: st_store(., "`genlev'", "`tousevar'", lev)
    }
	
    if ("`genres'" != "") {
		mata: res = y :- fit
		mata: st_store(., "`genres'", "`tousevar'", res)
    }
   
	end


capture program drop sjive
program sjive, eclass
version 17
	
	* y x (d = z) [if] [in], w() gen() chunk()
	syntax anything(equalok) [if] [in], [gen(string) w(varlist) CHUNK(integer 1000) NOSHRINK FORCE]
	
	marksample tousevar
		
	* Warn if gen is alrady specified
	cap confirm variable `gen'
	if _rc == 0{
		disp in red "Variable `gen' is already defined. Choose a new argument for gen()"
		exit 198
	}
	
	/***************************************************************************
					*Parse input and declare temporary variables*
	***************************************************************************/

	local pos1 = strpos("`anything'", "(")
	local pos2 = strpos("`anything'", "=")
	local pos3 = strpos("`anything'", ")")

	local exogenous1 = substr("`anything'", 1, `pos1' - 1)
	local d = substr("`anything'", `pos1' + 1, `pos2' - `pos1' - 1)
	local z = substr("`anything'", `pos2' + 1, `pos3' - `pos2' - 1)
	local exogenous2 = substr("`anything'", `pos3' + 1, .)

	local pos4 = strpos("`exogenous1'", " ")
	local y = substr("`exogenous1'", 1, `pos4')
	local exogenous3 = substr("`exogenous1'", `pos4', .)
	local x `exogenous3' `exogenous2'

	if "`w'" != "" {
		markout `tousevar' `y' `x' `d' `z' `w'
	}
	else {
		markout `tousevar' `y' `x' `d' `z'
	}
	
	qui count if `tousevar'
    local N_used = r(N)
	
	* Temporary Variable Names
	tempvar Y_jk Y_res Dzx_jk Dx_jk Dwx_jk S_hat P_hat_ujive d_res_jk
	tempvar lambda phattilde epshat uhat vhat Hterm Aterm ones h
	
	tempname nuhat sigphat sigshat alphahat bhatsjivef sejivef seadjsjivef
	tempname X PX Z ZX XpXinvXpZ H Q V UHAT VHAT ZTILDE D LAMBDA U2 CROSSTERM CROSSTERMMAT B QZt HTERM
	tempname zi Pi bi li ui vi hi denom_i scale_i scale_j
	tempname b_return V_return N_return weak
	tempname i1 i2 i1_mata i2_mata Zchunk Bchunk Pichunk tmp Lchunk Uchunk Vchunk Hchunk weighted denom
	
	* ---------------------------------------------------------
    * Force option - dropping obs. that uniquely. identify 
    * ---------------------------------------------------------
    
    if "`force'" != "" {
        tempvar h_current
		qui gen double `h_current' = .
		local iter = 0
		local dropped_count = 1 
		local total_dropped = 0

		while `dropped_count' > 0 {
			local ++iter
		   
			// 1. Clean variable list for CURRENT sample
			quietly _rmcoll `x' `z' `w' if `tousevar', forcedrop
			local current_vars `r(varlist)'
		   
			// 2. Calculate Leverage
			mata: st_view(M=., ., tokens("`current_vars'"), "`tousevar'")
			mata: M = M, J(rows(M), 1, 1)
			mata: H_diag = rowsum(M :* (M * invsym(cross(M, M))))
			mata: st_store(., "`h_current'", "`tousevar'", H_diag)
		   
			// 3. Identify Singletons
			quietly count if `h_current' > 0.999999 & `tousevar'
			local dropped_count = r(N)
			local total_dropped = `total_dropped' + r(N)
		   
			if `dropped_count' > 0 {
				quietly replace `tousevar' = 0 if `h_current' > 0.999999 & `tousevar'
			}
		}
		qui count if `tousevar'
        local N_used = r(N)
    }
	else {
        * No force option (Warning Check) 
        
        quietly _rmcoll `x' `z' `w' if `tousevar', forcedrop
        local check_vars `r(varlist)'
        
        tempvar h_check
        qui gen double `h_check' = .
        
        mata: st_view(M=., ., tokens("`check_vars'"), "`tousevar'")
        mata: M = M, J(rows(M), 1, 1)
        mata: H_diag = rowsum(M :* (M * invsym(cross(M, M))))
        mata: st_store(., "`h_check'", "`tousevar'", H_diag)
        
        qui count if `h_check' > 0.999999 & `tousevar'
        if r(N) > 0 {
			disp as err _newline "Error: Unable to compute SJIVE because the leave-one-out matrix is not"
			disp as err "full-rank."
			disp as err "Re-run with {bf:force} option to automatically drop problematic observations,"
			disp as err "or inspect your variables to manually remove the instruments/covariates that"
			disp as err "uniquely identify observations."
			exit 2001
        }
        drop `h_check'
    }
	
	
	/***************************************************************************
						*Form Matrices to be used later*
	***************************************************************************/
							
	qui gen `ones' = 1
	
	* Handle collinearity in Z and X variables before creating matrices
	qui _rmcoll `z' if `tousevar', forcedrop 
	local z_clean `r(varlist)'
	local N_excluded : word count `z_clean'

	* Store for later use
	tempname n_iv
	scalar `n_iv' = `N_excluded'
	
	qui _rmcoll `x' if `tousevar', forcedrop 
	local x_clean `r(varlist)'
	
	* Get X and Z matrices (use cleaned Z list)
	mata: `X' = st_data(., "`x_clean' `ones'", "`tousevar'")
	mata: `Z' = st_data(., "`z_clean' `ones'", "`tousevar'")

	* Residualize Z with respect to X (exclude constant from Z)
	* ZX = M_x * Z = (I - X(X'X)^(-1)X') * Z = (Z - X(X'X)^(-1)X'Z)
	mata: `XpXinvXpZ' = (cholsolve(cross(`X', `X'), cross(`X', `Z'[., 1..cols(`Z')-1])))
	mata: `ZX' = `Z'[., 1..cols(`Z')-1] - `X' * `XpXinvXpZ'

	* Compute leverage scores
	mata: `H' = rowsum(`ZX' :* (`ZX' * invsym(cross(`ZX', `ZX'))))

	* Store leverage in Stata variable
	qui gen `h' = .
	mata: st_store(., "`h'", "`tousevar'", `H')

	/***************************************************************************
								*Partialling out*
	***************************************************************************/

	* Partial Covariates out of y
	jk_fit `y' `x_clean' if `tousevar', gen(`Y_jk')
	qui gen `Y_res' = `y' - `Y_jk' if `tousevar'
	
	* UJIVE on D, Z, and X
	jk_fit `d' `z_clean' `x_clean' if `tousevar', gen(`Dzx_jk')
	jk_fit `d' `x_clean' if `tousevar', gen(`Dx_jk')

	*P_hat_ujive
	qui gen `P_hat_ujive' = `Dzx_jk' - `Dx_jk' if `tousevar'
	
	* UJIVE on D, W, and X
	if "`w'" != "" {
		qui _rmcoll `w' if `tousevar', forcedrop 
		local w_clean `r(varlist)'
		jk_fit `d' `w_clean' `x_clean' if `tousevar', gen(`Dwx_jk') 
		qui gen `S_hat' = `Dwx_jk' - `Dx_jk' if `tousevar'
		}
	else {
		qui gen `S_hat' = 0 if `tousevar'
		}

	/***************************************************************************
							*Get the variance constants*
	***************************************************************************/

	* Get signuhat
	qui reg `d' `z' `x' if `tousevar'
	local signuhat = sqrt(e(rss)/e(df_r))
	qui predict `nuhat' if `tousevar',resid

	* sigepshat
	qui ivregress 2sls `y' (`d' = `P_hat_ujive') `x' if `tousevar'
	qui predict `epshat' if `tousevar',resid
	local sigepshat = sqrt(e(rss)/(e(N)-e(rank)))
	
	* sigepsnuhat
	qui correlate `epshat' `nuhat' if `tousevar',cov
	local sigepsnuhat = r(cov_12)
	
	*sigshat
	qui sum `S_hat' if `tousevar'
	local sigshat = r(sd)
	
	*sigphat
	qui gen `d_res_jk' = `d' - `Dx_jk' if `tousevar'
	qui correlate `P_hat_ujive' `d_res_jk' if `tousevar', cov
	local sigphat = sqrt(abs(r(cov_12)))
	
	scalar `weak' = 0
	if r(cov_12) < 0 {
		scalar `weak' = 1
		disp in red "Possibly Weak Instruments"
	}

	/***************************************************************************
						*Calculate shrinkage and SJIVE instrument*
	***************************************************************************/

	disp "Computing shrinkage parameter. . ."

	* lambda
	if "`noshrink'" != "" {
		qui gen `lambda' = 1 if `tousevar'
	}
	else {

		mata `B' = 1:/(1:-`H')
		mata `QZt' = invsym(cross(`ZX',`ZX'))*`ZX''
		mata: `HTERM' = J(rows(`ZX'), 1, 0)
		
		forvalues i = 1(`chunk')`=ceil(`N_used'/`chunk')*`chunk'' {
			
			local i1 = `i'
			local i2 = min(`i'+(`chunk'-1), `=`N_used'')

			mata: `i1_mata' = `i1'
			mata: `i2_mata' = `i2'
			
			mata: `Zchunk' = `ZX'[|`i1_mata',1 \ `i2_mata',cols(`ZX')|]

			mata: `Pichunk' = `Zchunk' * `QZt'
			
			mata: `HTERM'[|`i1_mata' \ `i2_mata'|] = (`Pichunk':^2) * `B'
		}

		qui gen `Hterm' = .
		
		mata st_store(., "`Hterm'", "`tousevar'", `B' :* `HTERM')
		
		qui replace `Hterm' = `Hterm' - (`h'/(1-`h'))^2 if `tousevar'

		qui gen `Aterm' = `h'/(1-`h')*`signuhat'^2+`sigepsnuhat'^2/`sigepshat'^2*`Hterm' if `tousevar'
		
		* alpha
		local alphahat = `sigshat'^2/`sigphat'^2
		qui gen `lambda' = (1-`alphahat')*`sigphat'^2/((1-`alphahat')*`sigphat'^2+`Aterm') if `tousevar'
	}

	* phattilde
	qui gen `phattilde' = (1-`lambda')*`S_hat' + `lambda'*`P_hat_ujive' if `tousevar'

	/***************************************************************************
							*Final SJIVE Regression*
	***************************************************************************/

	qui ivregress 2sls `Y_res' (`d'=`phattilde') if `tousevar',robust

	*uhat
	qui predict `uhat' if `tousevar', resid
	
	*return values for ereturn
	mat `b_return' = e(b)
	mat `V_return' = e(V)
	scalar `N_return' = e(N)
	
	/***************************************************************************
							*Adjusted Standard Errors*
	***************************************************************************/
	disp "Computing adjusted standard error. . ."

	* vhat
	qui regress `d' `phattilde' `x' if `tousevar'
	qui predict `vhat' if `tousevar', resid
	
	* Matrices we need
	mata `ZTILDE' = .
	mata st_view(`ZTILDE',.,"`phattilde' `ones'", "`tousevar'") 
	
	mata `D' = .
	mata st_view(`D',.,"`d' `ones'", "`tousevar'")

	mata `UHAT' = .
	mata st_view(`UHAT',.,"`uhat'", "`tousevar'")
	
	mata `VHAT' = .
	mata st_view(`VHAT',.,"`vhat'", "`tousevar'")
	
	mata `LAMBDA' = .
	mata st_view(`LAMBDA',.,"`lambda'", "`tousevar'")
	
	mata `Q' = qrinv(`ZTILDE''*`D')
	
	mata `U2'=`UHAT':^2
	
	* Helper vector for the loop
	mata `scale_j' = (`LAMBDA' :* `UHAT' :* `VHAT') :/ (1:-`H')
	
	* Cross term calculation
	mata `CROSSTERM' = J(rows(`ZX'), 1, 0)
	
	forvalues i = 1(`chunk')`=ceil(`N_used'/`chunk')*`chunk'' {
		
		local i1 = `i'
		local i2 = min(`i'+(`chunk'-1), `=`N_used'')

		mata: `i1_mata' = `i1'
		mata: `i2_mata' = `i2'

		mata: `Zchunk' = `ZX'[|`i1_mata',1 \ `i2_mata',cols(`ZX')|]
		mata: `Lchunk' = `LAMBDA'[|`i1_mata' \ `i2_mata'|]
		mata: `Uchunk' = `UHAT'[|`i1_mata' \ `i2_mata'|]
		mata: `Vchunk' = `VHAT'[|`i1_mata' \ `i2_mata'|]
		mata: `Hchunk' = `H'[|`i1_mata' \ `i2_mata'|]
		mata: `denom' = 1 :- `Hchunk'
		mata: `scale_i' = (`Lchunk' :* `Uchunk' :* `Vchunk') :/ `denom'
		mata: `Pichunk' = `Zchunk' * `QZt'
		mata: `weighted' = (`Pichunk':^2) * `scale_j'

		mata: `CROSSTERM'[|`i1_mata' \ `i2_mata'|] = `scale_i' :* `weighted'
	}
	
	mata `CROSSTERM' = `CROSSTERM' - (`LAMBDA':^2):*(`H':^2):*(`UHAT':^2):*(`VHAT':^2):/(1:-`H'):^2

	
	* put the cross term as the upper left of a 2x2 matrix:
	mata `CROSSTERMMAT' = (sum(`CROSSTERM'),0\0,0)
	mata `V'=`Q'*((`ZTILDE':*`U2')'*`ZTILDE'+`CROSSTERMMAT')*`Q''
	mata st_numscalar("`seadjsjivef'",sqrt(`V'[1,1]))

	mat `V_return'[1,1] = `seadjsjivef'^2

	/***************************************************************************
								*Gen and Ereturn*
	***************************************************************************/

	if "`gen'" != "" {
		qui gen `gen' = `phattilde' if `tousevar'
	}

	ereturn clear
	ereturn post `b_return' `V_return'
	ereturn scalar N = `N_return'
	ereturn scalar weak = `weak'
	ereturn scalar N_excluded = `n_iv'
	if "`force'" != "" {
        ereturn scalar N_dropped = `total_dropped'
    }
	
	disp ""
	disp as text "Shrunken Jackknife IV Estimation" _col(55) "Number of obs =" _col(55) as result %9.0f `N_return'
	disp as text _col(48) "Excluded instruments =" _col(55) as result %9.0f `n_iv'

	if `weak' == 1 {
		disp as text _col(55) "Warning: Weak instruments detected"
	}
	
	ereturn local depvar "`y'"
	
	ereturn display
	if "`force'" != "" {
        disp as text "Note: {bf:force} option dropped " as result `total_dropped' as text " singleton observations."
    }

end
