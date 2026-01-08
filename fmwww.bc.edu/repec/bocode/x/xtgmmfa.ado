/******************************************************************************
						PROGRAM DEFINES XTGMMFA
		Performs GMM estimation for factor-augmented panel data model 
								with fixed T

			Author: 	Manh Hoang Ba
			Support:	hbmanh9492@gmail.com

			Ref.: 		Joudis & Sarafidis (2022)


	31/12/25 - Version 1.0: the first contribution
									
******************************************************************************/

cap program drop xtgmmfa
program define xtgmmfa, eclass
	version 11
	
	if replay() {
		if "`e(cmd)'"!="xtgmmfa" {
			di in red "last estimate not xtgmmfa"
			exit 301
		}
		else syntax [, Level(cilevel)]
	}
	else {
		syntax varlist(num fv ts) [if] [in] , 		///
						GMMvars(string)				///		// done
					[	UNOFactors(string)			///		// done
						IVvars(varlist ts fv)		///		// done
						Wmat(int 2)					///		// done
						Robust						///		// vcetype
						CLuster(varname)			///		// vcetype
						ONEstep						///		// done
						Level(cilevel)				///		// report
						NOCONStant 					///		// done	
						OBSFactors(varlist ts fv)	///		// done
						rho(real 0.75)				///
						small						///
						]
		
		local cmdline xtgmmfa `0'
		
*			- touse var
		tempvar touse0 touse
		mark `touse' `if' `in'
		qui gen byte `touse0' = `touse'
		
*			- idvar, tvar
		tempname ivar tvar b V theta Vtheta Fe_hat ///
				n_c r_ga df_m wald waldp bic j_df j j_s j_p le d G reg_unb ft_unb

//	Check for rho
		if `rho'<=0 {
			di in red "rho must be positive"
			exit 198
		}

// Check for xtset 
		qui xtset
		if "`r(panelvar)'" == "" {
			di in red "Data must be xtset before using this command"
			exit 459
		}	
		
*			- noconstant
		if "`noconstant'" != "" {
			local nocons nocons
		}

		
*			- varlist: tempvars + varlist name + maxlag of y

		_rmcoll `varlist' if `touse', `nocons'
		local varlist0 "`r(varlist)'"

		fvrevar `varlist0' if `touse'
		local tempvars "`r(varlist)'"					// tempvars
		
		markout `touse' `tempvars'
		gettoken depvar indepvars : tempvars			// tempvar_names
		
		fvexpand `varlist0' if `touse'
		local varnames "`r(varlist)'"					// varnames
		gettoken depname rest: varnames

		if "`noconstant'" != "" {
			local cons = 0
			local indepnames "`rest'"
		}
		else {
			local cons = 1
			local indepvars0 `indepvars'
			tempname _cons
			qui gen byte `_cons' = 1 if `touse'
			local tempvars `tempvars' `_cons'
			
			local indepnames "`rest' _cons"
		}
		

*			- gmmvars
	*	Parsing gmmvars(varlist(ts fv), mlag(int -1))
		local 0 `gmmvars'
		cap syntax varlist(ts fv), [mlag(int -1)]
		if _rc {
			di as err _n "gmmvars(`0') invalid."
			exit 198
		}
		local gmmvars `varlist'
		
		_rmcoll `gmmvars' if `touse', //expand
		local gmmvars "`r(varlist)'"
		
		fvrevar `gmmvars' if `touse'
		local zvars1 "`r(varlist)'"

		qui foreach var of local zvars1 {
			replace `var'=0 if `var'==. & `touse'	
		}
		
		qui _rmcoll `zvars1' if `touse', forcedrop
		local zvars1 "`r(varlist)'"	

*			- ivvars
		if `cons' == 1 {
			local ivvars `ivvars' `_cons'
			
			_rmcoll `ivvars' if `touse', noconstant
			local ivvars "`r(varlist)'"
		}
		else {
			if "`ivvars'" != "" {
				_rmcoll `ivvars' if `touse'
				local ivvars "`r(varlist)'"
			}
		}
		
		fvrevar `ivvars' if `touse'
		local zvars2 "`r(varlist)'"

		qui _rmcoll `zvars2' if `touse', noconstant forcedrop
		local zvars2 "`r(varlist)'"	
		
		local zvars `zvars1' `zvars2'
		markout `touse'	 `zvars' //`V'
		
*			- vvars
		*	Parsing unofactors(varlist(ts fv), ///
									[wvar(varname) ///
									method(regu | bss) ///
									type(int 1) ///
									lmax(int 2)	///
									seed(int 120) ///
									power(int 0) ///
									er ///
									NOREGressor])

		local 0 `unofactors'
		cap syntax [anything], [wvar(varname) ///
									bss ///
									type(int 1) ///
									lmax(int 2)	///
									seed(int 120) ///
									power(int 0) ///
									er ///
									NOREGressor]
		if _rc {
			di as err _n "unofactors(`0') invalid."
			exit 198
		}
		
		if "`anything'" == "" {
			if "`noregressor'"== "" local vvars `depname' `rest'
			else {
				di in red "`noregressor' cannot be specified with an empty Vlist."
				di in red "unofactors(`unofactors') invalid."
				exit 198
			}
		}
		else {
			local 0 `anything'
			cap syntax varlist(ts fv)
			if "`noregressor'"== "" local vvars `varlist' `depname' `rest'
			else local vvars `varlist'
		}
		
		if "`bss'"=="" local method "regu"
		else local method "bss"
		
		if "`method'"=="regu" local method_i = 1
		else local method_i = 2
		
		if "`er'"=="" local stat "gr"
		
		if "`small'" != "" local small_vl = 1
		else local small_vl = 0
/*
		if "`stat'"!="er" & "`stat'"!="gr" {
			di in red "stat(`stat') invalid."
			di in red "unofactors() invalid."
			exit 198
		}		
*/		
		_rmcoll `vvars' if `touse0', nocons
		local vvars "`r(varlist)'"
		fvrevar `vvars' if `touse0'
		local vvars "`r(varlist)'"
		qui _rmcoll `vvars' if `touse0', nocons forcedrop
		local V "`r(varlist)'"

		if `type'==1 {
			gettoken V1 rest: V
			local V `V1'		// use only first var in vvars
		}
		
		local Vtemp
		local Vout = 0
		foreach var of local V {
			qui xtsum `var' if `touse0'
			if r(sd_w)==0 local Vout = `Vout' + 1
			else local Vtemp `Vtemp' `var'
		}
		
		if `Vout'>0 {
			di in red "Vlist (including y and X) must be time-varying."
			di in red "`Vout' time-invariant variables are dropped."
		}
		local V `Vtemp'
		
		if "`wmat'" != "1" & "`wmat'" != "2" {
			di in red "wmat(`wmat') invalid."
			exit 198
		}
		
	preserve
		qui xtset
		local timevar "`r(timevar)'"
		local panelvar "`r(panelvar)'"

*			- observed factors
		_rmcoll `obsfactors' if `touse0', `nocons'
		local obsfactors "`r(varlist)'"
		fvrevar `obsfactors' if `touse0'
		local obsfactors "`r(varlist)'"
//		markout `touse' `obsfactors'
		
*			- wvars
		tempvar w0 touse2
		sort `panelvar' `timevar'
		if "`wvar'"=="" {
			qui by `panelvar': gen double `w0' = `depname'[1] if `touse0'
		}
		else {
			local n_w : word count `wvar'
			if `n_w' > 1 {
				di in red "too many variables specified."
				di in red "wvar(`wvar') invalid."
				exit 198
			}
			else {
				qui by `panelvar': gen double `w0' = `wvar'[1] if `touse0' 
			}
		}
		local W `w0'
		
		qui gen byte `touse2' = `touse0'
		markout `touse2' `V' `W' `obsfactors'

//		V, W and obsfactors are conditional on [if] [in]
		foreach var of varlist `V' `W' `obsfactors' {
			qui replace `var' = `var'*`touse2'
			qui replace `var' = 0 if `var'==.
		}
		
		qui egen long `ivar' = group(`panelvar') if `touse'
		sort `ivar' `timevar'
		qui sum `ivar'	if `touse', mean
		local N = r(max)

qui		keep if `touse'
		qui keep `panelvar' `ivar' `timevar' `tempvars' `zvars' ///
					`V' `W' `obsfactors' `cluster'	`touse'


// 		Treat unbalanced panel
		local balance = 1
		tempvar Ti
		qui egen `Ti' = sum(`touse') /*if `touse'*/, by(`ivar')
		qui sum `Ti' /*if `touse'*/, mean
		local T_bar = r(mean)
		local T_max = r(max)
		local T_min = r(min)
		
		if r(min) != r(max) {
			
			local balance = 0		
			
			local N0 = _N
			qui drop if `Ti' < 2
			local n_drop = `N0' - _N
			if `n_drop' >  0 {
				di in red "`r(N_drop)' observations is dropped"
				di in red "xtgmmfa requires at least 2 periods for each group"
			}
			
			tempvar reg_miss ft_miss
			qui egen byte `reg_miss' = rowmiss(`tempvars' `zvars') /*if `touse'*/
			qui gen byte `reg_unb' = (`reg_miss'==0) /*if `touse'*/
			
			qui egen byte `ft_miss' = rowmiss(`V' `W' `obsfactors') /*if `touse'*/
			qui gen byte `ft_unb' = (`ft_miss'==0) /*if `touse'*/	
			
			tempfile temp_data
			sort `ivar' `timevar'

			qui save `temp_data', replace
			
			qui sum `timevar' /*if `touse'*/
			local Tmax = r(max)
			local Tmin = r(min)

			
			clear
			qui set obs `=`N'*(`Tmax' - `Tmin' + 1)'
			
			qui gen long `ivar' = ceil(_n/(`Tmax' - `Tmin' + 1))
			qui gen long `timevar' = `Tmin' + mod(_n-1, (`Tmax' - `Tmin' + 1))
			
			qui merge 1:1 `ivar' `timevar' using `temp_data', nogen
			
			foreach var of varlist `tempvars' `zvars' `reg_unb' ///
				`V' `W' `obsfactors' `ft_unb' `Ti' {
					qui replace `var' = 0 if missing(`var') /*& `touse'*/
				}
			
// 		Hadarmad control
			foreach var of varlist `tempvars' `zvars' {
					qui replace `var' = `var'*`reg_unb' /*if `touse'*/
			}	
			foreach var of varlist `V' `W' `obsfactors' {
					qui replace `var' = `var'*`ft_unb' /*if `touse'*/
			}
		}
		
		sort `ivar' `timevar'
		qui by `ivar': gen byte `tvar' = _n /*if `touse'*/
		qui sum `tvar' /*if `touse'*/, mean
		local T = r(max)
		

*			- N, T, maxlag, k, exp, seed, onestep, robust
		
		get_maxlag, varlist("`varlist0'")
		local maxlag = r(maxlag)
	
		if `balance'==1 local obs = `T'*`N'
		else {
			qui sum `touse' /*if `touse'*/, mean
			local obs = r(sum)
		}

		if `T'<2 {
			di in red "xtgmmfa requires at least 2 periods for each group"
			exit 459
		}

		local k1 : word count `tempvars'
		local k = `k1' - 1
		local pow_max = `T'-1
		local l_max = `lmax'
			
		if `method_i'==1 {
			if "`er'" != "" local stat_vl = 1
			else {
				if `T'<3 {
					di in red "GR statistic requires at least 3 periods" _n ///
						"use ER statistic (option {bf:er}) if you only have 2"
					exit 459
				} 
				local stat_vl = 0
			}
		}
		else local stat_vl = 2
		
		if "`onestep'" != "" local step = 1
		else local step = 2
		
		if "`robust'"  != "" local rob = 1
		else local rob = 0
		
		if `wmat' == 1 local iden = 1
		else local iden = 0
		
*		- cluster var		
		local n_cl : word count `cluster'
		if `n_cl'>1 {
			di in red "cluster(`cluster') invalid."
			exit 198
		}
		else if `n_cl'==1 {
			local clust = 1

//			Check if clustervar time-variance
			qui xtsum `cluster' /*if `touse'*/
			if r(sd_w) > 0 {
				di in red "cluster variable must be time-invariant within panel"
				exit 198
			}
			
//			Check if panelvar nested within clustervar
*				(inspired by _xtreg_chk_cl2.ado)

			tempname temp1 temp2
			
*				Mark the first obs in each group
			sort `cluster'		
			qui by `cluster': gen long `temp1' = (_n==1) /*if `touse'*/
			
*				Cummulative sum: g=1 --> temp1 = 1, g=2 --> temp1 = 2, ...		
			qui replace `temp1' = sum(`temp1')
			
*				Sort id cluster		
			sort `ivar' `touse' `cluster'
			
*				If panelvar nested within cluster var: first = last obs
			qui by `ivar' `touse' : gen long `temp2' = `temp1'[_n] - `temp1'[1]
			qui count if `temp2' != 0 //& `touse' //& `cluster' != .
			if r(N) > 0 {
				di in red "panels are not nested within clusters"
				exit 198
			}
			qui replace `cluster' = 0 if `cluster'==. //& `touse'
		
		}	
		else local clust = 0
			

*			- Selector matrix
		selectorMatrix, t(`T') gmm(`zvars1') iv(`zvars2') m(`mlag') 
		tempname S
		mat `S'=r(S)
		local zeta = rowsof(`S')		// Number of instruments


/*=================================================================
		1.2. Reshape data and import to mata
=================================================================*/

		qui keep if `touse'

		qui keep `ivar' `tvar' `tempvars' `zvars' ///
					`V' `W' `obsfactors' `cluster' `Ti'
		qui ds `ivar' `tvar', not
			
		qui reshape wide `r(varlist)', ///
			i(`ivar') j(`tvar')

		
/*=================================================================
		1.3. Estimate
=================================================================*/

		mata: estimate(`small_vl',`balance',`T', `l_max', /*
			*/		`pow_max', `power', `N', `seed', /*
			*/		`stat_vl', `zeta', `iden', `rob', `step', /*
			*/		`rho', `cons', `type', `method_i', `clust', "cluster", /*
			*/		"tempvars", "zvars", "V", "W", "`S'", "obsfactors", /*
			*/		"b", "Vb", "`theta'", "`Vtheta'", "`Fe_hat'", /*
			*/		"`j'", "`df_m'", "`wald'", "`waldp'", "`bic'", /*
			*/		"`j_df'", "`j_s'", "`j_p'", "`le'", "`d'", "`r_ga'", /*
			*/		"`G'", "Ti")

		restore
// small adjustment
		if "`small'" != "" {
			local df = scalar(`df_m')
			loc dof "dof(`df')"
		}
	
//	Rename rows/columns matrix	
		mat colname b = `indepnames'
		mat colname Vb = `indepnames'
		mat rowname Vb = `indepnames'

		cap ereturn clear
		ereturn post b Vb, esample(`touse') dep(`depname') `dof'

// Store in e()
		*		- 	Matrix
		ereturn mat Fe_hat 	= `Fe_hat'		
		ereturn mat S		= `S'
		ereturn mat Vtheta 	= `Vtheta'
		ereturn mat theta  	= `theta'

		
		*		- 	Scalar
		ereturn scalar N		= `obs'	
		ereturn scalar N_g		= `N'
		ereturn scalar Tmax		= `T_max'
		ereturn scalar Tmin		= `T_min'
		ereturn scalar Tbar		= `T_bar'
		ereturn scalar k		= `k'
		ereturn scalar r_ga		= `r_ga'
		ereturn scalar j		= `j'
		ereturn scalar j_s		= `j_s'
		ereturn scalar j_p		= `j_p'
		ereturn scalar j_df		= `j_df'	
		ereturn scalar df_m		= `df_m'
		
		if "`small'" == "" {
			ereturn scalar chi2	= `wald'
			ereturn scalar chi2p = `waldp'
			local waldp_r "Prob > chi2"
		}
		else {
			local df_r = `N' - `r_ga'
			ereturn scalar df_r = `df_r'
			ereturn scalar F	= `wald'
			ereturn scalar F_p 	= `waldp'
			ereturn local small "`small'"
			local waldp_r "Prob > F"			
		}
	
		ereturn scalar Le		= `le'
		ereturn scalar d		= `d'
		ereturn scalar bic		= `bic'
		ereturn scalar type		= `type'
		
		*		-	Macros

		if "`onestep'"=="" {
			if "`robust'"!="" & "`cluster'"=="" {
				ereturn local clustvar "`panelvar'"
				ereturn scalar N_clust	= `N'
				ereturn local vcetype "WC-Robust"
			}
			else if "`cluster'"!="" {
				ereturn local clustvar "`cluster'"
				ereturn scalar N_clust	= `G'
				ereturn local vcetype "WC-Robust"
			}
			ereturn local gmmstep	"twostep"
		}
		else {
			if "`cluster'"!="" {
				ereturn local clustvar "`cluster'"
				ereturn scalar N_clust	= `G'
				ereturn local vcetype "Robust"
			}
			else {
				ereturn local clustvar "`panelvar'"				
				ereturn scalar N_clust	= `N'
				ereturn local vcetype "Robust"
			}
			ereturn local gmmstep	"onestep"
		}

		if "`method'"=="regu" {
			if "`er'" != "" ereturn local stat_note "Estimated Le (ER)"
			else ereturn local stat_note "Estimated Le (GR)"
			ereturn local method "Regularization"
		}
		else {
			ereturn local stat_note "Selected Le (BIC)"
			ereturn local method "Best-Subset Selection (BSS)"			
		}
		
		if "`noconstant'"!="" ereturn local constant "noconstant"
		else ereturn local constant "hasconstant"
		
		ereturn local tvar		"`timevar'"
		ereturn local ivar		"`panelvar'"
		ereturn local cmdline 	"`cmdline'"
		ereturn local cmd 		"xtgmmfa"
		
	}	// end replay-block
	
/*=================================================================
		1.4 Display
=================================================================*/

	if e(wald) > 999999 {
		local cfmt `"%10.0g"'
	}
	else	local cfmt `"%10.3f"'	
	
	if "`robust'"!="" | "`cluster'"!="" | "`onestep'"=="" {
		local overid "Hansen"
	}
	else local overid "Sargan"
	
	di
	di in gr "Fixed-T Factor-Augmented Panel Data Regression" _n
	di in gr "Estimator:"	_col(15) in ye "Asymptotically linear `e(gmmstep)' GMM"
	di in gr "Method:"		_col(15) in ye "`e(method)'" 
	di in gr "Reference:"	_col(15) in ye "Juodis & Sarafidis (2022)"	_n
	
	di in gr "Number of instruments"			///
		_col(25) "= " in ye %10.0g e(j) 		///
		_col(49) in gr "Number of obs" 			///
		_col(67)  "= " in ye %10.0g e(N)

	di in gr "Estimated coefficients"			///
		_col(25) "= " in ye %10.0g e(r_ga)   	///
		_col(49) in gr "Number of groups" 		///
		_col(67)  "= " in ye %10.0g e(N_g)
	di
	di in gr "`e(stat_note)'"					///
		_col(25) "= " in ye %10.0g e(Le)		///
		_col(49) in gr "Time periods:" 		///
		_col(63) "min" _col(67) "= " in ye %10.0g e(Tmin)

	di in gr "`overid' chi2("					///
				 in ye e(j_df)					///
				 in gr ")"						///
		_col(25) "= " in ye %10.4f e(j_s)		///		
		_col(63) in gr "avg" _col(67) "=  " in ye %9.1f e(Tbar)

	di in gr "Prob > chi2"						///
		_col(25) "= " in ye %10.4f e(j_p) 		///		
		_col(63) in gr "max" _col(67) "= " in ye %10.0g e(Tmax)
	di
	if "`small'" == "" {
		di _col(49) in gr "Wald chi2(" 			///
					 in ye e(df_m)				///
					 in gr ")"					///
			_col(67)  "= " in ye `cfmt' `wald'		
	}
	else {
	di _col(49) in gr "F(" 						///
				 in ye e(df_m)					///
				 in gr ", "						///
				 in ye e(df_r)					///
				 in gr ")"						///
		_col(67)  "= " in ye `cfmt' `wald'		
	}
		
	di in gr "BIC"								///
		_col(25) "= " in ye %10.4f e(bic) 		///
		_col(49) in gr "`waldp_r'" 				///
		_col(67)  "= " in ye %10.4f `waldp'		
	di
		
	ereturn display, l(`level') noemptycells
	
end		// end program defines xtgmmfa


/*==============================================================================
						Program define get_maxlag
==============================================================================*/

cap program drop get_maxlag
program define get_maxlag, rclass
    syntax , VARLIST(string) [VAR(string)]

    local maxlag = 0
    local foundvar = 0

    foreach token of local varlist {
        local lag = 0
        local vname ""

        //  Use for l(1/3).x   l2.x   l.x   x
        if regexm("`token'", "L\(([0-9]+)/([0-9]+)\)\.([A-Za-z0-9_]+)") {
            local vname = regexs(3)
            local lag = regexs(2)
        }
        else if regexm("`token'", "L([0-9]+)\.([A-Za-z0-9_]+)") {
            local vname = regexs(2)
            local lag = regexs(1)
        }
        else if regexm("`token'", "L\.([A-Za-z0-9_]+)") {
            local vname = regexs(1)
            local lag = 1
        }
        else {
            local vname = "`token'"
            local lag = 0
        }

        // If var() is specified, return maxlag of var
        if "`var'" != "" {
            if "`vname'" == "`var'" {
                if `lag' > `maxlag' local maxlag = `lag'
                local foundvar = 1
            }
        }
        // If not, return maxlag of varlist
        else {
            if `lag' > `maxlag' local maxlag = `lag'
        }
    }

    if "`var'" != "" & `foundvar' == 0 {
        di as err "`var' is not in varlist."
        exit 198
    }

    return scalar maxlag = `maxlag'
end


/*==============================================================================
							SELECTOR MATRIX GENERATOR
==============================================================================*/

cap program drop selectorMatrix
program define selectorMatrix, rclass
    version 11
    
    syntax, Tmax(integer) ///
            GMMvars(varlist) [IVvars(varlist) Maxlag(integer -1)]

	local k_gmm : word count `gmmvars'
	local k_iv	: word count `ivvars'

//	1. Create S_GMM
	
    // Set default maxlags if not specified
    if `maxlag' == -1 local maxlag = `tmax'
    
    *   Step 1. Create S_var_t

	foreach var in `gmmvars' {
		if `maxlag' >= `tmax' {
			forvalues t = 1/`tmax' {
				tempname S_`var'_`t'             
				mat `S_`var'_`t'' = J(`t', `tmax', 0)
				forvalues i = 1/`t' {
					mat `S_`var'_`t''[`i', `i'] = 1
				}				
			}
		}
		else {
			local inst_num = `maxlag'
			// While t <= inst_num
			forvalues t = 1/`inst_num' {
				tempname S_`var'_`t'            
				mat `S_`var'_`t'' = J(`t', `tmax', 0)        
				forvalues i = 1/`t' {
					mat `S_`var'_`t''[`i', `i'] = 1
				}
			}
			
			// While t > inst_num (rolling window)
			local t_start = `inst_num' + 1
			forvalues t = `t_start'/`tmax' {
				tempname S_`var'_`t'
				mat `S_`var'_`t'' = J(`inst_num', `tmax', 0)
				local col_start = `t' - `inst_num' + 1
				forvalues i = 1/`inst_num' {
					local col = `col_start' + `i' - 1
					mat `S_`var'_`t''[`i', `col'] = 1
				}
			}
		}
	}
	
                        
    *   Step 2. Create S_t = blockdiag(S_var_t)
    
    forvalues t = 1/`tmax' {
        tempname S_`t'
        
        // First var = l.depvar
        gettoken first_var rest_vars : gmmvars
        
        matr `S_`t'' = `S_`first_var'_`t''
        
        // Remain vars
        foreach var in `rest_vars' {
            mata: st_matrix("`S_`t''", /*
                        */  blockdiag(st_matrix("`S_`t''"), /*
                        */  st_matrix("`S_`var'_`t''")))
        }
		
		// Add columns to S_`t': number of columns = k_iv*tmax
		if `k_iv'>0 {
			mat `S_`t'' = `S_`t'', J(rowsof(`S_`t''), `k_iv'*`tmax', 0)
		}
    }
 
	*   Step 3. Create matrix S=blockdiag(S_t)
	
    tempname S_final
    mat `S_final' = `S_1'
  
    forvalues t = 2/`tmax' {
        mata: st_matrix("`S_final'", /*
                    */  blockdiag(st_matrix("`S_final'"), /*
                    */  st_matrix("`S_`t''")))
    }

//	2. Create S_IV
	if `k_iv'>0 {
		tempname S_iv S_iv_k
		local c_S = colsof(`S_final')
		mat `S_iv' = J(`k_iv', `c_S', 0)
	
		forvalues k=1/`k_iv' {			
			forvalues t=1/`tmax' {				
				mat `S_iv'[`k', `k_gmm'*`t'*`tmax'+(`t'-1)*`k_iv'*`tmax'+`t' + (`k'-1)*`tmax']=1
			}
		}

		mat `S_final' = `S_final' \ `S_iv'
	}
    
    // Return matrix S
    return matrix S = `S_final'
                    
end

/*==============================================================================
						DEFINE MATA FUNCTIONS
				1) blockdiag()
==============================================================================*/

mata:
mata clear

real matrix blockdiag(real matrix A, real matrix B)
{
    real matrix result
    real scalar ra, ca, rb, cb
    
    ra = rows(A)
    ca = cols(A)
    rb = rows(B)
    cb = cols(B)
    
    result = J(ra + rb, ca + cb, 0)
    result[1..ra, 1..ca] = A
    result[(ra+1)..(ra+rb), (ca+1)..(ca+cb)] = B
    
    return(result)
}



/*==============================================================================
				2) data2MataMat()
==============================================================================*/

/*==============================================================================
		2.1 data2MataMat()
		Input:
			rowvector 	:	include varnames stored in local macro
			k			:	number of columns of rowvector
			T         	: 	number of time period
		Output:
			MataMat		:	Tx(kN) data matrix
==============================================================================*/

real matrix function data2MataMat(string rowvector M_vars, real scalar k, real scalar T)
{
    // Create varlist in wide data
    string rowvector allvars
    allvars = J(1, k*T, "")
    for (j=1; j<=k; j++) {
        for (t=1; t<=T; t++) {
            allvars[(j-1)*T + t] = M_vars[j] + strofreal(t)
        }
    }

    // Read data from STATA
    real matrix M_data
    //st_view(M_data = ., ., allvars)
	M_data = st_data(., allvars)
    N = rows(M_data)

    // Create empty MataMat: T x (k*N)
    real matrix MataMat
    MataMat = J(T, k*N, .)

    // Fill data
    for (i=1; i<=N; i++) {
        Vi = J(T, k, .)
        for (j=1; j<=k; j++) {
            Vi[., j] = (M_data[i, (j-1)*T + 1 .. j*T])'
        }
        col1 = (i-1)*k + 1
        col2 = i*k
        MataMat[., col1..col2] = Vi
    }
	
    return(MataMat)
}

/*==============================================================================
		2.2 get_MataMat_i()
			~ Take Mata matrix Txk for individual i, i=1,N
==============================================================================*/
real matrix function get_MataMat_i(real matrix MataMat, real scalar i, real scalar k)
{
    col1 = (i-1)*k + 1
    col2 = i*k
    return(MataMat[., col1..col2])
}


/*==============================================================================
				3) Wmaker()
==============================================================================*/

real matrix Wmaker(string rowvector Wvars, /*
	*/	real scalar pow_max,/*
	*/	real scalar w_pow, /*
	*/	real scalar type) {
	
	string rowvector Wvars1
	Wvars1 = Wvars + "1"	// name + 1 = name1

//  st_view(Wdata = ., ., W_t1vars)
	data = st_data(., Wvars1)
	N = rows(data)
	if (type==2) {
		W = data :^w_pow
//		W[data :== 0] = 0
	}	
	else {
		W = data :^ J(N, 1, 0..(pow_max-1))
	}
	return(W)	
}


/*==============================================================================
				4) combs_maker
==============================================================================*/

function combs_maker(real scalar L, real scalar R)
{
    real matrix result
    real scalar n_comb, i, j, k
    real rowvector current
    
    n_comb = comb(R, L)
    result = J(n_comb, L, .)
    
    // 1st combination: [1, 2, ..., L]
    current = J(1, L, .)
    for (j = 1; j <= L; j++) {
        current[j] = j
    }
    result[1, .] = current
    
    // other combinations
    k = 1
    while (k < n_comb) {
        // Finding from right to left
        i = L
        while (i >= 1 && current[i] == R - L + i) {
            i--
        }
        
        if (i >= 1) {
            current[i] = current[i] + 1
			
            for (j = i + 1; j <= L; j++) {
                current[j] = current[j-1] + 1
            }
            
            k++
            result[k, .] = current
        }
    }
    
    return(result)
}


/*==============================================================================
				5) Fe_selector
==============================================================================*/

transmorphic function Fe_selector(real scalar L,  real matrix F_hat)
{
    real scalar R, n_comb, p
    real matrix combs
    transmorphic Fe_sel

    R = cols(F_hat)
    
    n_comb = comb(R, L)
    
    // Store results in array
    Fe_sel = asarray_create("real", 1)
    combs = combs_maker(L, R)
	
    for (p = 1; p <= n_comb; p++) {
		asarray(Fe_sel, p, F_hat[., combs[p, .]])
    }
    
    return(Fe_sel)
}


/*==============================================================================
				6) estimate()
==============================================================================*/

real matrix estimate(
/*	input						*/
		real scalar small,
		real scalar balance,
		real scalar T,
		real scalar l_max,
		real scalar pow_max,
		real scalar w_pow,
		real scalar N,
		real scalar seed,
		real scalar stat_vl,
		real scalar zeta,
		real scalar iden,
		real scalar rob,
		real scalar step,
		real scalar rho,
		real scalar cons,
		real scalar type,
		real scalar method,			// regu = 1, bss = 2
		real scalar clust,			// clust = 0 | 1
		string scalar stata_clust,	
		string scalar stata_vars,	// "local_name" , not "`local_name'"
		string scalar stata_zvars,
		string scalar stata_V,
		string scalar stata_M_W,
		string scalar stata_S,		// "`local_name'"
		string scalar stata_H,
/*	ouput						*/
		string scalar stata_b,		// "`local_name'" 
		string scalar stata_Vb,
		string scalar stata_theta,
		string scalar stata_Vtheta,
		string scalar stata_Fe_hat,
		string scalar stata_j,
		string scalar stata_df_m,
		string scalar stata_wald,
		string scalar stata_waldp,
		string scalar stata_bic,
		string scalar stata_j_df,
		string scalar stata_j_s,
		string scalar stata_j_p,
		string scalar stata_le,
		string scalar stata_d,
		string scalar stata_r_ga,
		string scalar stata_G,
		string scalar stata_Ti
	)
{
	
	//	--	M_vars = M_depvar, M_indepvars

	vars = tokens(st_local(stata_vars))
	k1 = length(vars)
	k  = k1 - 1
	M_vars = data2MataMat(vars, k1, T)
			
	// Truy xu?t M_vars_i Tx(k+1) matrix for individual i
	//M_vars_i = get_MataMat_i(M_vars, i, k1)
	
	
	//	--	M_zvars, Z_i, z_i	-----------------------------------
	
	zvars = tokens(st_local(stata_zvars))
	k_z = length(zvars)
	M_zvars = data2MataMat(zvars, k_z, T)	
	d=rows(vec(get_MataMat_i(M_zvars, 1, k_z)))
	
	S  		= st_matrix(stata_S)
	I 		= I(T)
	M_Z 	= asarray_create("real")
			
	for (i=1; i<=N; i++) {
		M_zvarsi	= get_MataMat_i(M_zvars, i, k_z)	// T x k_z
		zi 			= vec(M_zvarsi)
		Zi 			= (S * (I # zi))'					// T x zeta
		asarray(M_Z, i, Zi)
	}
	
	
	//	--	M_Zvars	-----------------------------------

	M_Zvars	= J(zeta, k1, 0)

	for (i=1; i<=N; i++) {
		M_varsi 	= get_MataMat_i(M_vars, i, k1)		// T x k1
		Zi 			= asarray(M_Z, i)					// T x zeta
		M_Zvarsi	= Zi'*M_varsi						// zeta x k1
		M_Zvars 	= M_Zvars + M_Zvarsi
	}
	
//	M_Zvars = M_Zvars / N								// zeta x k1
	M_Zvars = M_Zvars 								// zeta x k1
	M_Zy 	= M_Zvars[,1]								// zeta x 1
	M_ZX 	= M_Zvars[,2..k1]							// zeta x k

	
	//	--	cluster var	-----------------------------------
	if (clust==1) {
		clustvar = tokens(st_local(stata_clust))
		clustvar = clustvar + "1"
		g_panel	= st_data(., clustvar)
		N_G 		= max(g_panel)
	}
	
	//	--	Ti var	-----------------------------------
	if (balance==0) {
		Tivar = tokens(st_local(stata_Ti))
		Tivar = Tivar + "1"
		Ti	  = st_data(., Tivar)
		obs   = sum(Ti)
	}	

	
	//	--	initial GMM weigth -----------------------------------
	B    	= I(zeta)
	
	if (iden==1) {
		C  	= B
	}
	else {
		C 	= J(zeta, zeta, 0)
		for (i=1; i<=N; i++) {
			Zi 		= asarray(M_Z, i)					// T x zeta
			ZiZi	= Zi'*Zi							// zeta x zeta
			C 		= C + ZiZi							// Z'Z
		}
//		C	= C / N
		C = invsym((C+C')/2)							// (Z'Z)^-1
	}
	C_int = C
	
	//	--	M_V			-----------------------------------
	
	V = tokens(st_local(stata_V))
	k_v = length(V)
	M_V = data2MataMat(V, k_v, T)
	
	
	//	--	Observed factors	---------------------------
		
	H = tokens(st_local(stata_H))
	k_h = length(H)
	if (k_h>0) {
		M_H = get_MataMat_i(data2MataMat(H, k_h, T), 1, k_h) // optimal needed
	}
	else {
		M_H=J(T,1,0)
	}
	
	if (balance==1) {
		M_H = M_H * N
	}
	else {
		M_H = M_H * obs
	}
	
	//	--	M_W			-----------------------------------
	
	Wvars = tokens(st_local(stata_M_W))

	M_W = Wmaker(Wvars, pow_max, w_pow, type)	
	r_w		= cols(M_W)
	F_hat 	= J(T, k_v*r_w, 0)
	
	if (balance==1) {
		for (i=1; i<=N; i++) {
			M_Vi 	= get_MataMat_i(M_V, i, k_v)	// Txk_v
			M_Wi 	= M_W[i,]
			F_hat	= F_hat + M_Vi # M_Wi
		}
	}
	else {
		for (i=1; i<=N; i++) {
			M_Vi 	= get_MataMat_i(M_V, i, k_v)				// Txk_v
			M_Wi 	= M_W[i,]
			F_hat	= F_hat + M_Vi # M_Wi * (Ti[i]/obs)			// Ti/obs
		}
	}
		
	
	/*=================================================================	
							2. Estimate facto proxies
	=================================================================*/
	
	if (method==1) {
		
//		F_hat = F_hat/N
			
	//	rademach
		rseed(seed)
		rademach = (runiform(N, 1) :< 0.5)* -2 :+ 1
		M_WT 	= M_W, rademach		// l_max + 1 = T
		r_wT	= cols(M_WT)
		F_hatT 	= J(T, k_v*r_wT, 0)
		
		if (balance==1) {
			for (i=1; i<=N; i++) {
				M_Vi 	= get_MataMat_i(M_V, i, k_v)	// Txk_v
				M_WTi 	= M_WT[i,]
				F_hatT	= F_hatT + M_Vi # M_WTi
			}			
		}
		else {
			for (i=1; i<=N; i++) {
				M_Vi 	= get_MataMat_i(M_V, i, k_v)	// Txk_v
				M_WTi 	= M_WT[i,]
				F_hatT	= F_hatT + M_Vi # M_WTi *(Ti[i]/obs)
			}
		}
		
//		F_hatT 	= F_hatT/N
		
		A		= F_hat*F_hat'
		A		= (A + A')/2
		B 		= F_hatT*F_hatT'
		B		= (B + B')/2

		symeigensystem(A, eigenvector_A=., eigenvalue_A=.)
		symeigensystem(B, eigenvector_ev=., eigenvalue_ev=.)

		eigenvalue_ev = eigenvalue_ev'
		eigenvalue_ev = sort(eigenvalue_ev, -1)
		eigenvalue_ev = eigenvalue_ev'
				
		if (stat_vl==1) {
			//	ER statistic
				er 		= eigenvalue_ev[1..T-1] :/ eigenvalue_ev[2..T]
				er_max 	= er[1]
				le 		= 1
				for (i = 2; i <= cols(er); i++) {
					if (er[i] > er_max) {
						er_max 	= er[i]
						le 		= i
					}
				}
		}
		else {
		//	GR statistic
			G = J(1, T, .)
				
			for (r=0; r<=T-1; r++) {
				G[r+1] = rowsum(eigenvalue_ev[1,(r+1)..T])
			}
				
			gr = J(1, T-2, .)
			for (r=1; r<=T-2; r++) {
				gr[r] = (ln(G[r] / G[r+1])) / (ln(G[r+1] / G[r+2]))
			}

			gr_max 	= gr[1]
			le 		= 1
			n_gr	= cols(gr)
			for (i = 2; i <= n_gr; i++) {
				if (gr[i] > gr_max) {
					gr_max 	= gr[i]
					le 		= i
				}
			}
		}
		
		if (balance==1) {
			Fe_hat 	= -sqrt(T) * eigenvector_A[,1..le] * N
		}
		else {
			Fe_hat 	= -sqrt(T) * eigenvector_A[,1..le] * obs
		}

	}
	else {
//	Best-Subset Selection: lowest BIC
		R = cols(F_hat)
		if (l_max>R) {
//			printf("\n{text}Lmax must be less than or equal T-1")
//			printf("\n{text}Let Lmax = %f", T-1)
			l_max = R
		}
		
		A_bic = asarray_create("real")
		A_Fe = asarray_create("real")
		
		idx = 0
		
		for (L = 1; L <= l_max; L++) {
			
			n_comb = comb(R, L)
			Fe_L = Fe_selector(L, F_hat)
			
			for (m = 1; m <= n_comb; m++) {
				
				idx = idx + 1
				
				Fe_L_m = asarray(Fe_L, m)
				
				if (k_h>0) {
					XX = S*(Fe_L_m # I(d)), S*(M_H # I(d))
				}
				else {
					XX = S*(Fe_L_m # I(d))
				}

				Zy   	= M_Zy
				ZX	 	= M_ZX, XX
						
				ZXCZX	= ZX'*C*ZX
				ZXCZX	= (ZXCZX + ZXCZX')/2
//				Vtheta1 = invsym(ZXCZX)/N
				Vtheta1 = invsym(ZXCZX)
				Vtheta1 = (Vtheta1 + Vtheta1')/2
//				theta1  = N*Vtheta1*ZX'*C*Zy
				theta1  = Vtheta1*ZX'*C*Zy
				n_c	 	= rows(theta1)
				r_ga 	= rank(ZX)		
					
				if (zeta < r_ga) {
					BIC = 10^9
				}
				else {
					b1	 	= theta1[1..k,1]
					g1 		= theta1[k1..n_c,1]
						
					df_j	= zeta - r_ga

					Delta 	= J(zeta, zeta, 0)
					
					if (balance==1) {
						XX1 = XX/N						
						if (clust==1) {
	/*	
							i	g_panel
							1	1		g_panel[1]=1 <-> g=1
							2	2		g_panel[2]=2 <-> g=2
							3	1		g_panel[3]=1 <-> g=1
							4	2		g_panel[4]=2 <-> g=2
							5	0		g_panel[5]=0 <-> missing
	*/	
							Mg 		= J(N_G, zeta, 0)							// G x zeta
								
							for (i=1; i<=N; i++) {
								M_varsi 	= get_MataMat_i(M_vars, i, k1)
								Zi 			= asarray(M_Z, i)				// T x zeta		
											
								M_Zvarsi	= Zi'*M_varsi					// zeta x k1
								M_Zyi 		= M_Zvarsi[, 1]
								M_ZXi 		= M_Zvarsi[, 2..k1]
											
								Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1		// zeta x 1		
									
								gi 			= g_panel[i]
								if (gi > 0) {
									Mg[gi,] 	= Mg[gi,] + Zei'	// 1 x zeta
								}
									
							}
							
							for (g=1; g<=N_G; g++) {
								Delta = Delta + Mg[g,]'*Mg[g,]
							}
							
	//						Delta = Delta/N_G						
						}
						else {
							for (i=1; i<=N; i++) {
								M_varsi 	= get_MataMat_i(M_vars, i, k1)
								Zi 			= asarray(M_Z, i)	
										
								M_Zvarsi	= Zi'*M_varsi
								M_Zyi 		= M_Zvarsi[, 1]
								M_ZXi 		= M_Zvarsi[, 2..k1]
										
								Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1
								Delta 		= Delta + Zei*Zei'
							}
							
	//						Delta	= Delta / N
						}						
					}
					else {
						if (clust==1) {

							Mg 		= J(N_G, zeta, 0)							// G x zeta
								
							for (i=1; i<=N; i++) {
								M_varsi 	= get_MataMat_i(M_vars, i, k1)
								Zi 			= asarray(M_Z, i)				// T x zeta		
											
								M_Zvarsi	= Zi'*M_varsi					// zeta x k1
								M_Zyi 		= M_Zvarsi[, 1]
								M_ZXi 		= M_Zvarsi[, 2..k1]
								
								XX1			= XX *(Ti[i]/obs)		// Hadamard
								Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1		// zeta x 1		
									
								gi 			= g_panel[i]
								if (gi > 0) {
									Mg[gi,] 	= Mg[gi,] + Zei'				// 1 x zeta									
								}
									
							}
							
							for (g=1; g<=N_G; g++) {
								Delta = Delta + Mg[g,]'*Mg[g,]
							}
							
	//						Delta = Delta/N_G						
						}
						else {
							for (i=1; i<=N; i++) {
								M_varsi 	= get_MataMat_i(M_vars, i, k1)
								Zi 			= asarray(M_Z, i)	
										
								M_Zvarsi	= Zi'*M_varsi
								M_Zyi 		= M_Zvarsi[, 1]
								M_ZXi 		= M_Zvarsi[, 2..k1]
											
								XX1			= XX * (Ti[i]/obs)
//								XX1			= XX/N
								Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1
								
								Delta 		= Delta + Zei*Zei'
							}

	//						Delta	= Delta / N
						}
					}
					
					Delta	= (Delta + Delta')/2

					if (step==1) {
						
					//	===========		GMM 1 step		===========
						
						C		= invsym(Delta)
						Ze1	 	= Zy-ZX*theta1
						J_s 	= Ze1'*C*Ze1
						BIC 	= J_s - (log(N)/T^0.3)*rho*df_j
					}		
					else {
								
					//	===========		GMM 2 step		===========

						C 		= invsym(Delta)
						XZCZX	= ZX'*C*ZX
						XZCZX	= (XZCZX + XZCZX')/2
						Vtheta2	= invsym(XZCZX)
						Vtheta2	= (Vtheta2+ Vtheta2')/2
						theta2	= Vtheta2*ZX'*C*Zy
						n_c		= rows(theta2)
						b	 	= theta2[1..k,1]
						Ze2	 	= Zy-ZX*theta2
						
						J_s 	= Ze2'*C*Ze2
						BIC 	= J_s - (log(N)/T^0.3)*rho*df_j
					}
				}
				
				// Store bic and Fe_sel
				asarray(A_bic, idx, BIC)
				asarray(A_Fe, idx, Fe_L_m)
				
			}
		}
		
		// Find BIC min and Fe_hat
		min_bic = asarray(A_bic, 1)
		best_idx = 1
		
		n_models = 0
		for (L = 1; L <= l_max; L++) {
			n_models = n_models + comb(R, L)
		}
		
		for (i = 2; i <= n_models; i++) {
			if (asarray(A_bic, i) < min_bic) {
				min_bic = asarray(A_bic, i)
				best_idx = i
			}
		}
		
		Fe_hat = asarray(A_Fe, best_idx)
		le = cols(Fe_hat)
		
//		balance==1: sum-F_hat's columns -> Fe_hat -> no need to divide by N		
		if (balance==0) {
			Fe_hat = Fe_hat*obs
		}

	}

	/*=================================================================
			3. Perform GMM
	=================================================================*/
	
	C = C_int
	
	if (k_h>0) {
		XX = S*(Fe_hat # I(d)), S*(M_H # I(d))
	}
	else {
		XX 	 	= S*(Fe_hat # I(d))
	}

	Zy   	= M_Zy
	ZX	 	= M_ZX, XX
			
	ZXCZX	= ZX'*C*ZX
	ZXCZX	= (ZXCZX + ZXCZX')/2
	Vtheta1 = invsym(ZXCZX)
	Vtheta1 = (Vtheta1 + Vtheta1')/2
	theta1  = Vtheta1*ZX'*C*Zy
	n_c	 	= rows(theta1)
	r_ga 	= rank(ZX)
		
	if (zeta < r_ga) {
		printf("\n{err}Error: GMM under-identified!\n")
		_error(3498, "Number of instruments (" + strofreal(zeta) + 
						") < number of parameters (" + strofreal(r_ga) + ")")
	}
			
	b1	 	= theta1[1::k,1]
	g1 		= theta1[k1::n_c,1]
		
	df_j	= zeta - r_ga
			
//	Delta = Z'OmegaZ = Z'Block.diag(ei*ei')Z = sum_i (Ze_i*Ze_i')
	Delta 	= J(zeta, zeta, 0)					// zeta x zeta = K x K
	
	if (balance==1) {
		XX1 = XX/N
		if (clust == 1) {
	/*	
			i	g_panel
			1	1		g_panel[1]=1 <-> g=1
			2	2		g_panel[2]=2 <-> g=2
			3	1		g_panel[3]=1 <-> g=1
			4	2		g_panel[4]=2 <-> g=2
	*/	
			Mg 		= J(N_G, zeta, 0)						// N_G x zeta
				
			for (i=1; i<=N; i++) {
				M_varsi 	= get_MataMat_i(M_vars, i, k1)
				Zi 			= asarray(M_Z, i)				// T x zeta		
							
				M_Zvarsi	= Zi'*M_varsi					// zeta x k1
				M_Zyi 		= M_Zvarsi[, 1]
				M_ZXi 		= M_Zvarsi[, 2..k1]
							
				Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1		// zeta x 1		
					
				gi = g_panel[i]
				if (gi > 0) {
					Mg[gi,] = Mg[gi,] + Zei'					// 1 x zeta
				}
			}
			
			for (g=1; g<=N_G; g++) {
				Delta = Delta + Mg[g,]'*Mg[g,]
			}
			
		}	
		else {
			for (i=1; i<=N; i++) {
				M_varsi 	= get_MataMat_i(M_vars, i, k1)
				Zi 			= asarray(M_Z, i)				// T x zeta		
						
				M_Zvarsi	= Zi'*M_varsi					// zeta x k1
				M_Zyi 		= M_Zvarsi[, 1]
				M_ZXi 		= M_Zvarsi[, 2..k1]
						
				Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1
				Delta 		= Delta + Zei*Zei'		
			}

		}		
	}
	else {
		if (clust == 1) {
	
			Mg 		= J(N_G, zeta, 0)						// N_G x zeta
				
			for (i=1; i<=N; i++) {
				M_varsi 	= get_MataMat_i(M_vars, i, k1)
				Zi 			= asarray(M_Z, i)				// T x zeta		
							
				M_Zvarsi	= Zi'*M_varsi					// zeta x k1
				M_Zyi 		= M_Zvarsi[, 1]
				M_ZXi 		= M_Zvarsi[, 2..k1]
				
				XX1 		= XX * (Ti[i]/obs)				// hadamard
				Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1		// zeta x 1		
					
				gi = g_panel[i]
				if (gi > 0) {
					Mg[gi,] = Mg[gi,] + Zei'				// 1 x zeta
				}
					
			}
			
			for (g=1; g<=N_G; g++) {
				Delta = Delta + Mg[g,]'*Mg[g,]
			}
			
		}	
		else {
			for (i=1; i<=N; i++) {
				M_varsi 	= get_MataMat_i(M_vars, i, k1)
				Zi 			= asarray(M_Z, i)				// T x zeta		
						
				M_Zvarsi	= Zi'*M_varsi					// zeta x k1
				M_Zyi 		= M_Zvarsi[, 1]
				M_ZXi 		= M_Zvarsi[, 2..k1]
				
				XX1 		= XX * (Ti[i]/obs)				// hadamard
				Zei 		= M_Zyi - M_ZXi*b1 - XX1*g1
				Delta 		= Delta + Zei*Zei'		
			}
	//		Delta	= Delta / N	
		}		
	}
	
	
	Delta	= (Delta + Delta')/2

//	GMM 1-step allaway using robust SE cause conventional SE can't be estimated
	Vtheta1r	= Vtheta1*(ZX'*C*Delta*C*ZX)*Vtheta1
	Vtheta1r	= (Vtheta1r + Vtheta1r')/2

	if (step==1) {
		
	//	===========		GMM 1 step		============================
					
		if (rob==1 | clust==1) {
			Vtheta	= Vtheta1r
			V1		= Vtheta1r[1::k, 1::k]
					
			C		= invsym(Delta)
		}
		else {
/*			
			sigma2 	= mean(eit^2)/(NT-n_c)	// <- can not be estimated
			Z'Z		= sum_(i=1..N) (Zi'*Zi)
			Vtheta	= sigma2*Vtheta1*ZX'*C*Z'Z*C*ZX*Vtheta1
			V1 		= Vtheta[1::k, 1::k]
*/		
			Vtheta	= Vtheta1r
			V1		= Vtheta1r[1::k, 1::k]
					
			C		= invsym(Delta)			
		}
		
		Ze1	 	= Zy-ZX*theta1			// e1 = Z'e
		J_s 	= Ze1'*C*Ze1
		J_p 	= 1 - chi2(df_j, J_s)
					
		BIC 	= J_s - (log(N)/T^0.3)*rho*df_j			
				
		b		= b1
		V		= V1
		theta	= theta1

	}		
	else {
				
	//	===========		GMM 2 step		============================

		C 		= invsym(Delta)	// (Z'OmegaZ)^-1
		XZCZX	= ZX'*C*ZX
		XZCZX	= (XZCZX + XZCZX')/2
		Vtheta2	= invsym(XZCZX)
		Vtheta2	= (Vtheta2+ Vtheta2')/2
		theta2	= Vtheta2*ZX'*C*Zy
		n_c		= rows(theta2)
		b	 	= theta2[1::k,1]
		Ze2	 	= Zy-ZX*theta2
	
		if (rob==1 & clust==0) {
/*
			Windmeijer (2005) corection
				
			D 		= -(ZX'*C*ZX)^-1*ZX'*C*P*C*ZE
					= -N*Vtheta2*ZX'*C*P*C*ZE
			
			C 		= (Z'e*e'Z)^-1 = (Ze*Ze')^-1
			P*C*ZE 	= -sum (e1i'Zi*C*Ze2*ZXi + Zi'e1i*Ze2'*C*ZXi)
					= -sum (Ze1i'*C*Ze2*ZXi + Ze1i*Ze2'*C*ZXi)
					
			V_W 	= Vtheta2 + D*Vtheta2 + Vtheta2*D' + D*Vtheta1r*D'
*/
			D		= J(n_c, n_c, 0)			
			PCZE2	= J(zeta, n_c, 0)
			H		= J(n_c, n_c, 0)
			
			if (balance==1) {
				for (i=1; i<=N; i++) {
					M_varsi = get_MataMat_i(M_vars, i, k1)
					Zi 		= asarray(M_Z, i)	// T x zeta		
							
					M_Zvarsi= Zi'*M_varsi		// zeta x k1
					M_Zyi 	= M_Zvarsi[, 1]
					M_ZXi 	= M_Zvarsi[, 2..k1]
							
					Ze1i 	= M_Zyi - M_ZXi*b1 - XX1*g1
							
					M_ZXi	= M_ZXi, XX1
					PCZE2	= PCZE2 + Ze1i'*C*Ze2*M_ZXi + Ze1i*Ze2'*C*M_ZXi
					
				}				
			}
			else {
				for (i=1; i<=N; i++) {
					M_varsi = get_MataMat_i(M_vars, i, k1)
					Zi 		= asarray(M_Z, i)	// T x zeta		
							
					M_Zvarsi= Zi'*M_varsi		// zeta x k1
					M_Zyi 	= M_Zvarsi[, 1]
					M_ZXi 	= M_Zvarsi[, 2..k1]
					
					XX1		= XX * (Ti[i]/obs)			// Hadamard
					Ze1i 	= M_Zyi - M_ZXi*b1 - XX1*g1
							
					M_ZXi	= M_ZXi, XX1
					PCZE2	= PCZE2 + Ze1i'*C*Ze2*M_ZXi + Ze1i*Ze2'*C*M_ZXi
					
				}
			}
			
			//	20x20x(20x40)x(40x40)x(40x20) = 20x20
			D = Vtheta2*ZX'*C*PCZE2
					
			V_W 	  = Vtheta2 + D*Vtheta2 + Vtheta2*D' + D*Vtheta1r*D'
			
			V_W		  = (V_W + V_W')/2
			V	  	  = V_W[1::k,1::k]
			Vtheta	  = V_W			
		}	
		else if (clust==1) {

			Ze1g 	= J(N_G, zeta, 0)
			M_ZXg 	= J(1, N_G, NULL)
			g = .
			for (g=1; g<=N_G; g++) {
				M_ZXg[g] = &(J(zeta, n_c, 0))
			}
			
			D		= J(n_c, n_c, 0)
			PCZE2	= J(zeta, n_c, 0)
			
			if (balance==1) {
				for (i=1; i<=N; i++) {
					M_varsi 	= get_MataMat_i(M_vars, i, k1)
					Zi 			= asarray(M_Z, i)				// T x zeta		
								
					M_Zvarsi	= Zi'*M_varsi					// zeta x k1
					M_Zyi 		= M_Zvarsi[, 1]
					M_ZXi 		= M_Zvarsi[, 2..k1]
								
					Ze1i 		= M_Zyi - M_ZXi*b1 - XX1*g1
					
					M_ZXi	= M_ZXi, XX1
					gi 			= g_panel[i]
					if (gi > 0) {
// 						sum_(i in g) (e1i'*Zi) 1xzeta
						Ze1g[gi,]	= Ze1g[gi,] + Ze1i'
						
// 						sum_(i in g) (Zi'*Xi) zetaxk
						*M_ZXg[gi] 	= *M_ZXg[gi] + M_ZXi
					}
				}				
			}
			else {
				for (i=1; i<=N; i++) {
					M_varsi 	= get_MataMat_i(M_vars, i, k1)
					Zi 			= asarray(M_Z, i)				// T x zeta		
								
					M_Zvarsi	= Zi'*M_varsi					// zeta x k1
					M_Zyi 		= M_Zvarsi[, 1]
					M_ZXi 		= M_Zvarsi[, 2..k1]
					
					XX1			= XX * (Ti[i]/obs)				// Hadamard
					Ze1i 		= M_Zyi - M_ZXi*b1 - XX1*g1
					
					M_ZXi	= M_ZXi, XX1
					gi 			= g_panel[i]
					if (gi > 0) {
						Ze1g[gi,]	= Ze1g[gi,] + Ze1i'
						*M_ZXg[gi] 	= *M_ZXg[gi] + M_ZXi
					}
				}
			}
				
			for (g=1; g<=N_G; g++) {
				ZXg		= *M_ZXg[g]
				PCZE2	= PCZE2 + Ze1g[g,]*C*Ze2*ZXg + Ze1g[g,]'*Ze2'*C*ZXg
			}
			
			D = Vtheta2*ZX'*C*PCZE2
			
			V_W 	  = Vtheta2 + D*Vtheta2 + Vtheta2*D' + D*Vtheta1r*D'
			V_W		  = (V_W + V_W')/2
			V	  	  = V_W[1::k,1::k]
			Vtheta	  = V_W		
		}
		else {
			V		  = Vtheta2[1::k,1::k]
			Vtheta	  = Vtheta2
		}
		
		theta	  = theta2
				
//		J_s 	= N*Ze2'*C*Ze2
		J_s 	= Ze2'*C*Ze2
		J_p 	= 1 - chi2(df_j, J_s)

		BIC 	= J_s - (log(N)/T^0.3)*rho*df_j
	}

//	Small sample adjustment
	if (small == 1) {
		if (clust==1) {
			V 		= V * (N-1)/(N-r_ga) * (N_G/(N_G-1))
			Vtheta 	= Vtheta * (N-1)/(N-r_ga) * (N_G/(N_G-1))
		}
		else {
			V = V * (N-1)/(N-r_ga) * (N/(N-1))
			Vtheta 	= Vtheta * (N-1)/(N-r_ga) * (N/(N-1))			
		}
	}
	
//	Wald test
	if (cons==1) {
		R = I(n_c)              // R = ma tr?n don v?
		R[k, k]=0				// intercept
		q = J(n_c, 1, 0)        // q = vector 0
				
		df_m = r_ga - 1
		wald = (R*theta - q)' * pinv(R*Vtheta*R') * (R*theta - q)
		if (small==1) {
			df2 = N-r_ga
			waldp = 1 - F(df_m,  df2, wald)
		}
		else {
			waldp = 1 - chi2(df_m, wald)
		}	
	}
	else {
		R = I(n_c)              // R = ma tr?n don v?
		q = J(n_c, 1, 0)        // q = vector 0

		df_m = r_ga
		wald = (R*theta - q)' * invsym(R*Vtheta*R') * (R*theta - q)
		if (small==1) {
			df2 = N-r_ga
			waldp = 1 - F(df_m,  df2, wald)
		}
		else {
			waldp = 1 - chi2(df_m, wald)
		}
	}
	
	
	/*=================================================================
		4. Post and store results
	=================================================================*/

	//	Export to STATA
	b 		= b'
	
	if (balance==1) {
		Fe_hat = Fe_hat/N
	}
	else {
		Fe_hat = Fe_hat/obs
	}
	
	st_matrix(stata_b, b)
	st_matrix(stata_Vb, V)
	st_matrix(stata_theta, 	theta)
	st_matrix(stata_Vtheta, 	Vtheta)
	st_matrix(stata_Fe_hat,	Fe_hat)
			
	st_numscalar(stata_j, 	zeta)
	st_numscalar(stata_df_m, 	df_m)
	st_numscalar(stata_wald, 	wald)
	st_numscalar(stata_waldp, waldp)

	st_numscalar(stata_bic, 	BIC)
	st_numscalar(stata_j_df,  df_j)
	st_numscalar(stata_j_s, 	J_s)
	st_numscalar(stata_j_p, 	J_p)
	st_numscalar(stata_le,   	le)
	st_numscalar(stata_d, 	d)
	st_numscalar(stata_r_ga, 	r_ga)
	st_numscalar(stata_G, 	N_G)

}

end
