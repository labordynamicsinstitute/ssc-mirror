
*! version 1.1.0 - 21mar2021 - Federico Belotti
* See the end for versioning

program hetsar, eclass
	version 15
	syntax varlist(min=1 fv) [if] [in] [pweight/], ///
		[ WMATrix(string) 		///
		  NOCONStant 			///
		  ITERations(integer 100) ///
		  vce(string) ROBust	///
		  TECHnique(string) TRace(string) DIFFicult	///
		  POSTHessian POSTscores ///
		  DETailed ivarlag(string) DYNamic ///
		  FROM(string) ///
		  TOLerance(real 1e-6) ///
		  LTOLerance(real 1e-7) ///
		  NRTOLerance(real 1e-5) ]

	// Parse dep and indep variables
	gettoken lhs rhs: varlist
	loc k: word count `rhs'

	// Mark the sample using the temporary var "touse"
	marksample touse

	// Check for panel setup
	_xt, trequired
	local id: char _dta[_TSpanel]
	local time: char _dta[_TStvar]
	tempvar temp_id temp_t Ti
	qui egen `temp_id'=group(`id')
	sort `temp_id' `time'
	qui by `temp_id': g `temp_t' = _n if `touse'==1
	qui replace `temp_id' = . if `temp_t'== .
	sort `temp_id' `time'

	// Parse wmatrix
	tempname _wmat
	capture confirm matrix `wmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`wmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' != 0 {
			cap m _SPMATRIX_assert_object("`wmatrix'")
			if _rc != 0 {
				di as error "Only Stata matrices, {help spmat} or {help spmatrix} objects are allowed as wmatrix() argument"
				exit 198
			}
			else capture spmatrix matafromsp `_wmat' `id' = `wmatrix'
		}
		else capture spmat getmatrix `wmatrix' `_wmat'
	}
	else m `_wmat' = st_matrix("`wmatrix'")



	***********************************************************************
	*** Get temporary variable names and perform Factor Variables check ***
	***********************************************************************
	*** (Note: Also remove base collinear variables if fv are specified)


	local fvops = "`s(fvops)'" == "true"
	if `fvops' {
		if _caller() >= 11 {

	    	local vv_fv : di "version " string(max(11,_caller())) ", missing:"

			********* Factor Variables parsing ****
			`vv_fv' _fv_check_depvar `lhs'

			local fvars "rhs ivarlag"
			foreach l of local fvars {
				if "`l'"=="rhs" local fv_nocons "`nocons'"
				fvexpand ``l''
				local _n_vars: word count `r(varlist)'
				local rvarlist "`r(varlist)'"
				fvrevar `rvarlist'
				local _`l'_temp "`r(varlist)'"
				forvalues _var=1/`_n_vars'  {
					_ms_parse_parts `:word `_var' of `rvarlist''
					*** Get temporary names here
					if "`r(type)'"=="variable" {
						local _`l'_tempnames "`_`l'_tempnames' `r(name)'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"
					}
					if "`r(type)'"=="factor" & `r(omit)'==0 {
						local _`l'_tempnames "`_`l'_tempnames' `r(op)'.`r(name)'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"
					}
					if ("`r(type)'"=="interaction" | "`r(type)'"=="product") & `r(omit)'==0 {
						local _inter
						forvalues lev=1/`r(k_names)' {
							if `lev'!=`r(k_names)' local _inter "`_inter'`r(op`lev')'.`r(name`lev')'#"
							else local _inter "`_inter'`r(op`lev')'.`r(name`lev')'"
						}
						local _`l'_tempnames "`_`l'_tempnames' `_inter'"
						local _`l'_ntemp "`_`l'_ntemp' `:word `_var' of `_`l'_temp''"
					}
				}
				*** Remove duplicate names (Notice that collinear regressor other than fv base levels are removed later)
				local _`l'_names: list uniq _`l'_tempnames
				*** Update fvars components after fv parsing
				local `l' "`_`l'_ntemp'"
			}
		}
	}

	/*
	if `fvops' & "`d_i_t_effects'"!="" {
		local d_i_t_effects
		di in yel "Warning: direct and indirect effects cannot be computed if factor variables are specified"
		di in yel "         option -effects- ignored. Notice that total effects can be obtained using -margins-"
	}
	*/

	*** Test for missing values in dependent and independent variables
	local __check_missing "`lhs' `rhs' `ivarlag'"
  	egen _hetsar_missing_obs=rowmiss(`__check_missing') if `touse'
  	quietly sum _hetsar_missing_obs if `touse'
  	drop _hetsar_missing_obs
  	local nobs=r(N)
  	local nmissval=r(sum)
  	if `nmissval' > 0 {
    	display as error "Error - the panel data must be strongly balanced with no missing values"
    	error 198
  	}

	// Parse VCV
	if "`detailed'"!="" {
		_vce_parse `touse', optlist(Robust) old: , vce(`vce') `robust'
    	local vce        "`r(vce)'"
    	//local clustervar "`r(cluster)'"
    	if regexm("`vce'", "robust") {
        	local vcetype "Robust"
			local crittype "negative log-pseudolikelihood"
    	}
		else {
			local vcetype "oim"
			local crittype "negative log-likelihood"
		}
	}
	else {
		local vce "mg"
		local crittype "negative log-likelihood"
	}

	if regexm("`vce'", "clust") {
		di as error "vce(cluster ...) is not allowed"
		error 198
	}

	*** Remove collinearity
	if "`rhs'"!="" {
		_rmcollright `rhs' if `touse' [`weight' `__equal' `exp'], `noconstant'
		local rhs "`r(varlist)'"
		if "`ivarlag'"!="" {
			_rmcollright `ivarlag' if `touse' [`weight' `__equal' `exp'], `noconstant'
			local ivarlag "`r(varlist)'"
		}
	}

	if `fvops'==0 {
		local _rhs_names "`rhs'"
		local _ivarlag_names "`ivarlag'"
	}

	// Create some locals
	// if constant term is needed
	if "`noconstant'"=="" {
		local cons 1
		local nocons
		local _cons _cons
	}
	else {
		local cons 0
		local nocons noconstant
		local _cons
	}

	// Collect data
	// Put them in _hetsar_bag()
	sort `temp_t' `temp_id'
	m r = _hetsar_getdata("`temp_id'", "`temp_t'", "`lhs'", "`rhs'", "`ivarlag'", "`touse'", `_wmat', `cons', "`dynamic'", "`weight'", "`exp'")

	// Naming of out objects
	*if "`dynamic'" != "" local _rhs_names "l.`lhs_name' l.W`lhs_name' `_rhs_names'"
	loc __n = __n
	loc __k = __k
	if "`detailed'"!="" {
		forv i = 1/`__n' {
			loc hetcoeffs "`hetcoeffs' `id'(`i')"
			// These are coleqs
			local Wy "`Wy' Wy"
			local Alpha "`Alpha' Alpha"
			if "`dynamic'" != "" {
				local y_1 "`y_1' l.y"
				local Wy_1 "`Wy_1' l.Wy"
			}

			/*if "`dynamic'" != "" local X_1 "`X_1' X_1"
			if "`dynamic'" != "" local WX "`WX' WX"
			if "`dynamic'" != "" local WX_1 "`WX_1' WX_1"*/
			local sigmasq "`sigmasq' Sigmasq"
		}
		if `cons'==0 local Alpha ""

		// These are coleqs
		foreach v of local _rhs_names {
			forv i = 1/`__n' {
				local X "`X' `v'"
			}
		}
		if "`ivarlag'"!="" {
			// These are coleqs
			foreach v of local _ivarlag_names {
				forv i = 1/`__n' {
					local DX "`DX' W`v'"
				}
			}
		}

		if "`dynamic'" != "" {
			// These are coleqs
			foreach v of local _rhs_names {
				forv i = 1/`__n' {
					local X_1 "`X_1' l.`v'"
				}
			}
			if "`ivarlag'"!="" {
				// These are coleqs
				foreach v of local _ivarlag_names {
					forv i = 1/`__n' {
						local DX_1 "`DX_1' l.W`v'"
					}
				}
			}
		}

		forv kk = 1/`__k' {
			local _colnames "`_colnames' `hetcoeffs'"
		}
		loc _eqnames "`Wy' `Alpha' `y_1' `Wy_1' `X' `DX' `X_1' `DX_1' `sigmasq'"
	}
	else {
		if "`dynamic'"!="" {
			loc y_1 "y_1"
			loc Wy_1 "Wy_1"
		}
		foreach v of local _rhs_names {
			local X_1 "`X_1' l.`v'"
		}
		if "`dynamic'"=="" local X_1

		if "`ivarlag'"!="" {
			foreach v of local _ivarlag_names {
				local DX "`DX' W`v'"
				local DX_1 "`DX_1' l.W`v'"
			}
		}
		if "`dynamic'"=="" local DX_1

		local _colnames "Wy `_cons' `y_1' `Wy_1' `_rhs_names' `DX' `X_1' `DX_1' sigmasq"
	}


	// Collect user-defined starting values
	// Put them in _hetsar_sv()
	tempname init_theta
	if "`from'" != "" {
		local arg `from'
		`vv' _mkvec `init_theta', from(`arg') /*colnames(`_colfullnames')*/ update error("from()")
	}
	else m  st_matrix("`init_theta'", J(1,`=`__k'*`__n'',0))

	local _params_list "init_theta"
	scalar np = wordcount("`_params_list'")
	/// Structure definition for initialisation
	// Old structure for multiparameters
	m s = J(1, st_numscalar("np"), _hetsar_sv())
	local pp 1
	foreach p of local _params_list {
		m s = _hetsar_getsv("``p''", `pp', s)
		//m liststruct(s)
		local pp =`pp'+1
	}


	// Init options
	// Parsing
	local eval "_hetsar_fn"
	local evaltype "d1"
	if "`technique'" == "" local technique "nr"
	if "`difficult'" != "" local difficult "hybrid"
	scalar iter = `iterations'
	scalar ptol = `tolerance'
	scalar vtol = `ltolerance'
	scalar nrtol = `nrtolerance'

	// Collect init options
	// Put them in _hetsar_init()
	m i = _hetsar_init_opt()
	//m liststruct(i)

	// Collect post options
	// Put them in _hetsar_post()
	m p = _hetsar_post_anc()
	//m liststruct(p)

	// QML estimation
	m M = _hetsar_est(r, s, i, p)


	mat colnames _theta = `_colnames'
	mat colnames _Vtheta = `_colnames'
	mat rownames _Vtheta = `_colnames'
	if "`detailed'"!="" {
		mat coleq _theta = `_eqnames'
		mat coleq _Vtheta = `_eqnames'
		mat roweq _Vtheta = `_eqnames'
	}

	// Post RESULTS
	ereturn post _theta _Vtheta, depname(`lhs') esample(`touse')

	// Scalars
	ereturn scalar N_g = __n
	ereturn scalar N = __N
	ereturn scalar T = __T
	if "`detailed'"=="" {
		ereturn scalar k_mg = `__k'
		ereturn scalar mean_group = 1
	}
	ereturn scalar k = `__k'*`__n'
	ereturn scalar converged = __converged
	ereturn scalar iterations = __iter
	ereturn scalar ll = __ll

	// Locals
	ereturn local cmd "hetsar"
	ereturn local vcetype "`vcetype'"
	ereturn local vce "`vce'"

	di ""
	if "`dynamic'"!="" {
		loc dyntit "Dynamic "
		eret scalar dynamic = 1
	}
	else eret scalar dynamic = 0
	loc title "`dyntit'SAR model with heterogenous coefficients"
	_coef_table_header, ti(`title')
	if "`detailed'"=="" di in yel "Mean-group estimator"
	_coef_table

	_scalar_Destructor __iter __ll __T __N __converged iter np __n __k ptol vtol nrtol
	_struct_Destructor M i p r s

end



prog define _scalar_Destructor
syntax namelist

 foreach nn of local namelist {
	 sca drop `nn'
 }

end

prog define _struct_Destructor
syntax namelist

 foreach nn of local namelist {
	 m mata drop `nn'
 }

end


exit

* version 1.0.0 - 3sep2020 - start up
* version 1.0.1 - 17feb2021 - first sharable version allowing for dynamic model. Only Stata matrices are allowed.
* version 1.1.0 - 21mar2021 - durbin and dynamic models can now be estimated. Stata matrices, spmat and spmatrix objects are allowed. MG estimator coded. Still d1 evaluator.
