*! version 1.0.1 02jun2014 MJC

/*
History
MJC 02jun2014: version 1.0.1 - ln_gamma changed to ln_p when Weibull model fitted
							 - random effects table variable labels were incorrect when random covariate effects were specified, now fixed
							 - likelihoods in stmixed now made comparable to streg exp/weib/gomp models and stpm2
							 - help file description improved
							 - warning added when only 1 random effect detected -> assumes identity
MJC 23may2014: version 1.0.0

Development:
- fixed bug in exponential distribution likelihood calc.
- non-adaptive iterations added to refine starting values. Options retolerance(), reiterate() and refineopts() added.
- FPM added including time-dependent effects, VCV results table done, AFTs added
- Changed syntax to be consistent with xt internal parsing
*/

program stmixed, eclass sortpreserve properties(st)
	version 12.1
	if replay() {
		if (`"`e(cmd)'"' !="stmixed") error 301
		Replay `0'
	}
	else Estimate `0'
end

program Estimate, eclass
	st_is 2 analysis
	
	// model opts
		local modelopts `"Distribution(string)"'
		local modelopts `"`modelopts' COVariance(string)"'
		local modelopts `"`modelopts' DF(passthru)"'
		local modelopts `"`modelopts' KNOTS(passthru)"'
		local modelopts `"`modelopts' KEEPCons"'
		local modelopts `"`modelopts' TVC(varlist)"'
		local modelopts `"`modelopts' DFTvc(passthru)"'
		local modelopts `"`modelopts' KNOTSTvc(passthru)"'
		local modelopts `"`modelopts' NOORTHog"'
		local modelopts `"`modelopts' RCSBASEOFF"'
		
	//Max opts
		local modelopts `"`modelopts' GH(real 9)"'
		local modelopts `"`modelopts' NONADAPT"'	
		local modelopts `"`modelopts' SHOWADAPT"'			
		local modelopts `"`modelopts' INITMATrix(string)"'				
		local modelopts `"`modelopts' VCVINITMATrix(string)"'
		local modelopts `"`modelopts' RETOLerance(real 1e-8) "'
        local modelopts `"`modelopts' REITERate(integer 200)"'
		local modelopts `"`modelopts' REFINEopts(string)"'		
		
	// mlopts
        local mlopts `"NONRTOLerance NRTOLerance(string)"'
        local mlopts `"`mlopts' TRace GRADient HESSian showstep"'
        local mlopts `"`mlopts' TECHnique(string) SHOWNRtolerance"'
        local mlopts `"`mlopts' ITERate(string) TOLerance(string)"'
        local mlopts `"`mlopts' LTOLerance(string) GTOLerance(string)"'
        local mlopts `"`mlopts' DIFficult dots depsilon(passthru) showh"'
	
	//Display opts
		local modelopts `"`modelopts' SHOWINIT"'
		local modelopts `"`modelopts' Level(cilevel)"'
		local modelopts `"`modelopts' NOLOG"'
		local modelopts `"`modelopts' INITMAT(string)"'
		local modelopts `"`modelopts' COPY"'
		local modelopts `"`modelopts' SKIP"'
		local modelopts `"`modelopts' NOHR"'
		local modelopts `"`modelopts' VARiance"'
			
	//Undocumented for use by predict and parsing check
		local modelopts `"`modelopts' GETBLUPS(string)"'
		local modelopts `"`modelopts' REISE"'
		local modelopts `"`modelopts' POSTTOUSE(varname)"'
		local modelopts `"`modelopts' check"'
		
		local globallow `"`modelopts' `mlopts'"'
		local cmdline `0'
		
	//parse
		_parse expand cmd glob : 0 , common(`globallow')
		if `cmd_n'<1 {
			di as error "No random effect equation has been specified"
			exit 198
		}
		if `cmd_n'>2 {
			di as error "Only two levels are currently allowed"
			exit 198
		}
		
        forvalues k = 1/`cmd_n' {                       // Parse global if/in
			local cmds `"`cmds' `"`cmd_`k''"'"'
			//di in green "`cmd_`k''"
        }
        _mixed_parseifin stmixed `=`cmd_n'+1' `cmds' `"`glob_if' `glob_in'"'

        local 0 `"`glob_if' `glob_in'"'                 // set estimation sample
        syntax [if] [in]
        marksample touse
        local allnms : subinstr local allnms "_all" "" , word all
        markout `touse' `allnms' , strok
		qui replace `touse' = 0 if _st==0

	//global options are in glob_op 
	//-> parse model options
        local 0 `", `glob_op'"'
        syntax [ , `modelopts' *]
			
			// error checks
			local l = length("`distribution'")
			if substr("weibull",1,max(1,`l')) == "`distribution'" {
				local smodel w
			}
			else if substr("gompertz",1,max(3,`l')) == "`distribution'" {
				local smodel gom
			}
			else if substr("exponential",1,max(1,`l')) == "`distribution'" {
				local smodel e
			}
			else if "fpm"=="`distribution'" {
				local smodel fpm
				capture which stpm2
				if _rc {
					display in yellow "You need to install the command stpm2. This can be installed using,"
					display in yellow ". {stata ssc install stpm2}"
					exit 198
				}
			}
			else if substr("loglogistic",1,max(`l',4))  == "`distribution'"  | substr("llogistic",1,max(`l',2)) == "`distribution'"  {
				local smodel "llogistic"
			}
			else if substr("lognormal",1,max(`l',4)) == "`distribution'" | substr("lnormal",1,max(`l',2)) == "`distribution'" {
				local smodel "lnormal"
			}
			else if substr("gamma",1,max(3,`l')) == "`distribution'" {
				local smodel "gamma"
			}
			else {
				di as error "Unknown distribution()"
				exit 198
			}
			local aft = 0
			if "`smodel'"=="gamma" | "`smodel'"=="lnormal" | "`smodel'"=="llogistic" local aft = 1
			
			if `aft' & "`nohr'"!="" {
				di as error "Option nohr not allowed"
				exit 198
			}
			
			if "`smodel'"!="fpm" & ("`df'"!="" | "`knots'"!="") {
				di as error "df()/knots() can only be specified with dist(fpm)"
				exit 198
			}
			
			if "`smodel'"=="fpm" & ("`df'"=="" & "`knots'"=="") {
				di as error "One of df() or knots() must be specified with distribution(fpm)"
				exit 198
			}
						
			if "`covariance'"=="" {
				local cov "unstr"
				local covtype "Unstructured"
			}
			else {
				local l = length("`covariance'")
				if substr("independent",1,max(3,`l')) == "`covariance'" {
					local cov "ind"
					local covtype "Independent"
				}
				else if substr("exchangeable",1,max(2,`l')) == "`covariance'" {
					local cov "exch"
					local covtype "Exchangeable"
				}
				else if substr("identity",1,max(2,`l')) == "`covariance'" {
					local cov "iden"
					local covtype "Identity"
				}
				else if substr("unstructured",1,max(2,`l')) == "`covariance'" {
					local cov "unstr"
					local covtype "Unstructured"
				}
				else {
					di as error "Unknown variance-covariance structure"
					exit 198
				}
			}
			
			local docheck = 0
			if "`check'"!="" {
				local docheck = 1
			}
			
		//parse mlopts
		mlopts mlopts , `options'
		local extra_constraints `s(constraints)'
															
	//==================================================================================================================================//
	// Parse equation syntax
		
		//fixed effects
		local feind = 1
		if `cmd_n'==2 {
			local 0 `cmd_1'
			syntax [varlist(numeric default=none)] [if] [in] [, NOConstant]
			fvexpand `varlist'
			if "`r(fvops)'" != "" {
				display as error "Factor variables not allowed. Create your own dummy variables."
				exit 198
			}
			local fixed_vars `varlist'
			local fe_nocons `noconstant'
			if `docheck' di in green "Fixed effects: " as res "`fixed_vars'"
			local feind = 2
		}
		
		//extract level var
		gettoken lev rest : cmd_`feind' , parse(":")
        gettoken colon rest : rest , parse(":")
        if `"`colon'"' == `":"' {
			local lev = trim("`lev'")
			if "`lev'" != "_all" {
				confirm variable `lev'
			}
        }
        else {
			di as err "{p 0 6 2}invalid random-effects "
			di as err "specification; perhaps you omitted the "
			di as err "colon after the level "
			di as err "variable{p_end}"
			exit 198
        }
		if `docheck' di in green "Level var: " as res "`lev'"
		
		//random effects
		local 0 `rest'
		syntax [varlist(numeric default=none)] [, NOConstant]
		fvexpand `varlist'
		if "`r(fvops)'" != "" {
			display as error "Factor variables not allowed. Create your own dummy variables."
			exit 198
		}		
		local random_vars `varlist'
		local random_vars_eret `random_vars'
		local re_nocons `noconstant'
		if ("`noconstant'"!="" & "`random_vars'"=="") {
			di as error "No random effects have been specified"
			exit 198
		}
		if "`noconstant'"=="" {
			tempvar int
			qui gen byte `int' = 1 if `touse'
			local random_vars `random_vars' `int'
		}
		local nres : list sizeof random_vars
		if `docheck' {
			di in green "Random vars: " as res "`random_vars'"
			di as txt "No. of random effects = " as res "`nres'"
		}
		
		fvexpand `fixed_vars' `lev' `random_vars'
		if "`r(fvops)'" != "" {
			display as error "Factor variables not allowed. Create your own dummy variables."
			exit 198
		}

		if "`cov'"!="iden" & `nres'==1 {
			di in green "Note: single-variable random-effects specification; covariance structure set to identity"
			local cov "iden"
			local covtype "Identity"
		}		
		
		markout `touse' `fixed_vars' `lev' `random_vars'
		 
	//==================================================================================================================================//
	// Preliminaries
		
		//# obs and # panels
		qui count if `touse'==1
		local nobs = `r(N)'
		tempvar _tempid
		qui egen `_tempid' = group(`lev')	if `touse'==1			
		local id "`_tempid'"
		tempvar surv_ind 
		qui bys `_tempid': gen `surv_ind'= (_n==_N & `touse'==1)	
		qui count if `surv_ind'==1
		local N = `r(N)'		
		
		//delayed entry
		qui su _t0 if `touse'==1, meanonly
		if `r(max)'>0 {
			di as error "Delayed entry is not supported"
			exit 198
		}
		local delentry = 0
		
		//prolog and refining starting values
		local refine 0
		if "`nonadapt'"=="" {
			local prolog derivprolog(stmixed_prolog())
			local refine 1
		}
		
		//show initial value fits
		if ("`showinit'"!="" & "`initmat'"=="") local noisily noisily
		
		// Variance ml equation names 
		if "`cov'"=="ind" | "`cov'"=="unstr" {
			forvalues i=1/`nres' {
				local var_re_eqn_names "`var_re_eqn_names' /lns_`i'"											
			}
		}
		else local var_re_eqn_names "/lns_1"
		
		if "`cov'"=="exch" & `nres'>1 {
			local corr_eqn_names "/art_1_1"
			local corr_eqn_names2 "art_1_1"		
		}
		else if "`cov'"=="unstr" {
			local subind = 1
			while (`subind'<`nres') {
				forvalues i=`=`subind'+1'/`nres' {
					local corr_eqn_names  "`corr_eqn_names' /art_`subind'_`i'"
					local corr_eqn_names2 "`corr_eqn_names2' art_`subind'_`i'"
				}
				local `++subind'
			}
		}

		//getblups and exit
		if "`getblups'"!="" {
			mata: stmixed_setup()	
			capture mata: rmexternal("`stmixed_struct'")
			exit
		}	
		
	//==============================================================================================================================================//
	// Starting values
	
		qui `noisily' di in green "Obtaining starting values:"
		
		if "`smodel'"!="fpm" {
			if "`initmatrix'"=="" {
				qui `noisily' streg `fixed_vars' if `touse', dist(`smodel') `nohr' `fe_nocons'
			}
			if "`smodel'"=="w" 				local mleqn1 (ln_lambda: `fixed_vars', `fe_nocons') /ln_p
			else if "`smodel'"=="gom" 		local mleqn1 (ln_lambda: `fixed_vars', `fe_nocons') /gamma
			else if "`smodel'"=="e" 		local mleqn1 (ln_lambda: `fixed_vars', `fe_nocons')
			else if "`smodel'"=="gamma" 	local mleqn1 (mu: `fixed_vars', `fe_nocons') /ln_sigma /kappa
			else if "`smodel'"=="lnormal" 	local mleqn1 (mu: `fixed_vars', `fe_nocons') /ln_sigma
			else if "`smodel'"=="llogistic" local mleqn1 (beta: `fixed_vars', `fe_nocons') /ln_gamma
			
		}
		else {
			cap which rcsgen.ado
			if _rc {
				di as error "You need to install rcsgen from SSC"
				exit 198
			}
			
			local collinear collinear
			if "`initmatrix'"!="" local iter0 iter(0)															//still need to get spline vars
			qui `noisily' stpm2 `fixed_vars' if `touse', 	scale(h) `df' `knots' 		///
															tvc(`tvc') `dftvc' `knotstvc' 			///
															`fe_nocons' `noorthog' keepcons		///
															`iter0' `rcsbaseoff'
			
			local rcsnames `e(rcsterms_base)'
			local drcsnames `e(drcsterms_base)'
			local bhknots `e(bhknots)'
			local ln_bhknots `e(ln_bhknots)'
			local boundary_knots `e(boundary_knots)'
			local nsplines : list sizeof rcsnames
			if "`noorthog'"=="" {
				tempname rmat
				mat `rmat' = e(R_bh)
			}
			
			if "`tvc'"!="" {
				foreach var of varlist `tvc' {
					local rcsterms_`var' `e(rcsterms_`var')'
					local tvcbasevars `tvcbasevars' `rcsterms_`var''
					local drcsterms_`var' `e(drcsterms_`var')'
					local tvcdbasevars `tvcdbasevars' `drcsterms_`var''
					if "`noorthog'"=="" {
						tempname rmat_`var'
						mat `rmat_`var'' = e(R_`var')
					}
					
					local tvcknots_`var' `e(tvcknots_`var')'
					local ln_tvcknots_`var' `e(ln_tvcknots_`var')'
					local boundary_knots_`var' `e(boundary_knots_`var')'
					local df_`var' = `e(df_`var')'
					
					if `delentry' {
						local ntvcsplines : word count `e(rcsterms_`var')'
						if `ntvcsplines'==1 {
							local tvcs0basevars `tvcs0basevars' _s0_rcs_`var'
						}
						else {
							forvalues i=1/`ntvcsplines' {
								local tvcs0basevars `tvcs0basevars' _s0_rcs_`var'`i'
							}
						}
					}
				}			
			}
			
			//ML equations
			local mleqn1 (xb: `fixed_vars' `e(rcsterms_base)' `tvcbasevars', `fe_nocons') (dxb: `e(drcsterms_base)' `tvcdbasevars',nocons) 
			if (`delentry') {
				forvalues i = 1/`nsplines' {
					local xb0names `xb0names' _s0_rcs`i'
				}
				local mleqn1 `mleqn1' (xb0: `fixed_vars' `xb0names' `tvcs0basevars', `fe_nocons')
			}

			//constraints
			local conslist `e(sp_constraints)'
			local dropconslist `conslist'
			if "`extra_constraints'" != "" {
				local mlopts : subinstr local mlopts "constraints(`extra_constraints')" "", word
				local conslist `conslist' `extra_constraints'
			}	
			local constopts "constraints(`conslist')"
	
		}
		
		tempname initmat
		if "`initmatrix'"=="" {
			mat `initmat' = e(b)
		}
		else mat `initmat' = `initmatrix'
		
		// Add initial values for VCV parameters
		if "`vcvinitmatrix'"=="" {
			local nvarparams : list sizeof var_re_eqn_names
			mat `initmat' = `initmat',J(1,`nvarparams',0)
			local ncovparams : list sizeof corr_eqn_names
			if (`ncovparams'>0) {
				mat `initmat' = `initmat',J(1,`ncovparams',0)
			}
		}
		else mat `initmat' = `initmat',`vcvinitmatrix'
		local initopt init(`initmat',copy `skip')
		
	//==============================================================================================================================================//
	// ML
		
		// Setup Mata struct
		mata: stmixed_setup()

		if "`nonadapt'"=="" {
		
			mlopts refops, `refineopts'
			local 0 `", `refops'"'
			syntax [, technique(string) ITERate(int 2) *]
			local refops `"technique(`technique') iter(`iterate') `options'"'
			if `:list posof "bhhh" in technique' {
                di as err "option technique(bhhh) not allowed"
                exit 198
			}

			di as txt _n "Refining starting values:"
			ml model d0 stmixed_d0_refine()	`mleqn1' `var_re_eqn_names' `corr_eqn_names' if `touse',			///
											`refops' `initopt' `constopts' collinear waldtest(0) search(off)	///
											`nolog'	nowarn userinfo(`stmixed_struct') maximize	
			mat `initmat' = e(b)
		}	
			
		
		di as txt _n "Performing gradient-based optimization:"
		ml model d0 stmixed_d0()	`mleqn1' 						///
									`var_re_eqn_names' 				///
									`corr_eqn_names'				///
									if `touse',						///
									`mlopts'						///
									`initopt'						///
									`constopts'						///
									`collinear'						///
									waldtest(0)						///
									search(off) 					///
									`nolog'							///
									userinfo(`stmixed_struct')		///
									`prolog'						///
									maximize	
									
		capture mata: rmexternal("`stmixed_struct'")

		ereturn local title "Mixed effects survival regression"
		ereturn local model "`smodel'"
		ereturn local cmd stmixed
		ereturn local cmdline stmixed `cmdline'
		ereturn local predict stmixed_pred
		ereturn local fixed_varlist `fixed_vars'
		ereturn local random_varlist `random_vars_eret'
		ereturn local fe_nocons `fe_nocons'
		ereturn local re_nocons `re_nocons'
		ereturn local gh `gh'
		ereturn local adapt = "`nonadapt'"==""
		ereturn local Nobs = `nobs'
		ereturn local Npanels = `N'
		ereturn local panel "`lev'"
		ereturn local n_re = `nres'
		ereturn local covtype `covtype'
		ereturn local aft = `aft'
		ereturn scalar dev = -2*e(ll)
        ereturn scalar AIC = -2*e(ll) + 2 * e(rank) 
        qui count if `touse' == 1 & _d == 1
        ereturn scalar BIC = -2*e(ll) + ln(r(N)) * e(rank)

		if "`smodel'"=="fpm" {
			ereturn local rcsterms_base `rcsnames'
			ereturn local drcsterms_base `drcsnames'
			ereturn local bhknots `bhknots'
			ereturn local ln_bhknots `ln_bhknots'
			ereturn local boundary_knots `boundary_knots'
			ereturn local noorthog `noorthog'
			ereturn local rcsbaseoff `rcsbaseoff'
			if "`noorthog'"=="" {
				ereturn matrix R_bh = `rmat'
			}
			
			ereturn local tvc `tvc'
			if "`tvc'"!="" {
				foreach var of varlist `tvc' {
					ereturn local rcsterms_`var' `rcsterms_`var''
					ereturn local drcsterms_`var' `drcsterms_`var''
					ereturn local tvcknots_`var' `tvcknots_`var''
					ereturn local ln_tvcknots_`var' `ln_tvcknots_`var''
					ereturn local boundary_knots_`var' `boundary_knots_`var''
					ereturn local df_`var' `df_`var''
					if "`noorthog'"=="" {
						ereturn matrix R_`var' = `rmat_`var''
					}					
				}
			}
			if "`keepcons'"!="" ereturn local sp_constraints `conslist'
			else constraint drop `dropconslist'
		}
		
		tempname tempvcv
		matrix `tempvcv' = J(`nres',`nres',0)
		if "`covtype'"=="Independent" | "`covtype'"=="Unstructured" {
			forvalues i=1/`nres' {											
				mat `tempvcv'[`i',`i'] 	= exp([lns_`i'][_cons])^2
			}
		}
		else {
			forvalues i=1/`nres' {				
				mat `tempvcv'[`i',`i'] 	= exp([lns_1][_cons])^2
			}
		}
		if "`covtype'"=="Exchangeable" & `nres'>1 {
			local test=1												
			while (`test'<`nres') {
				forvalues i=`=`test'+1'/`nres' {
					mat `tempvcv'[`test',`i'] 	 = tanh([art_1_2][_cons])*exp([lns_1][_cons])^2
					mat `tempvcv'[`i',`test'] 	 = `tempvcv'[`test',`i']
				}
				local `++test'
			}	
		}
		else if "`covtype'"=="Unstructured" {
			local test=1												
			while (`test'<`nres') {
				forvalues i=`=`test'+1'/`nres' {
					mat `tempvcv'[`test',`i'] 	 = exp([lns_`test'][_cons])*exp([lns_`i'][_cons])*tanh([art_`test'_`i'][_cons])
					mat `tempvcv'[`i',`test'] 	 = `tempvcv'[`test',`i']
				}
				local `++test'
			}	
		}
		ereturn matrix vcv = `tempvcv'
		
		Replay, level(`level') `nohr' `showcons' `variance'

end

program Replay
		syntax [, Level(cilevel) NOHR SHOWCons alleq VARiance]
		
	if "`nohr'"=="" local hr hr
	if `e(aft)' local hr
	if "`showcons'"=="" local nocnsreport nocnsreport
	if "`e(model)'"=="w" | "`e(model)'"=="gom" | `e(aft)' | ("`e(model)'"=="fpm" & "`alleqn'"!="") local plus plus
	local k = length("`level'")

	if "`variance'"=="" {
		local sdtxt "sd"
		local corrtxt "corr"
	}
	else {
		local sdtxt "var"
		local corrtxt "cov"
	}
	
	di
	di 	as txt "Mixed effects survival regression"			///
		as txt _col(50) "Number of obs.   = "							///
		as res _col(`=79-length("`e(Nobs)'")') `e(Nobs)'                                
	di 	as txt "Panel variable: " as res abbrev("`e(panel)'",12)		///
		as txt _col(50) "Number of panels = "							///
		as res _col(`=79-length("`e(Npanels)'")') `e(Npanels)'
	
	di
	di as txt "Log-likelihood = " as res e(ll)
	di
		
		ml display, neq(1) level(`level') noheader nofootnote nolstretch `hr' `nocnsreport' `plus'
		
		if "`e(model)'"=="w" {
			di as res _col(1) "ln_p" as txt _col(14) "{c |}"
			_diparm ln_p, label("_cons")	
		}
		else if "`e(model)'"=="gom" {
			di as res _col(1) "gamma" as txt _col(14) "{c |}"
			_diparm gamma, label("_cons")	
		}
		else if "`e(model)'"=="fpm" {
		
		
		}
		else if "`e(model)'"=="llogistic" {
			di as res _col(1) "ln_gamma" as txt _col(14) "{c |}"
			_diparm ln_gamma, label("_cons")	
		}
		else if "`e(model)'"=="lnormal" {
			di as res _col(1) "ln_sigma" as txt _col(14) "{c |}"
			_diparm ln_sigma, label("_cons")	
		}
		else if "`e(model)'"=="gamma" {
			di as res _col(1) "ln_sigma" as txt _col(14) "{c |}"
			_diparm ln_sigma, label("_cons")	
			di as txt "{hline 13}{c +}{hline 64}"
			di as res _col(1) "kappa" as txt _col(14) "{c |}"
			_diparm kappa, label("_cons")
		}
		if "`e(model)'"=="w" | "`e(model)'"=="gom" | `e(aft)' | ("`e(model)'"=="fpm" & "`alleqn'"!="") di as txt "{hline 13}{c BT}{hline 64}"
		
		//RE table
			di 
			di as txt "{hline 29}{c TT}{hline 48}"
			di as txt _col(3) "Random effects Parameters" _col(30) "{c |}" _col(34) "Estimate" _col(45) "Std. Err." _col(`=61-`k'') ///
			`"[`=strsubdp("`level'")'% Conf. Interval]"'
			di as txt "{hline 29}{c +}{hline 48}"
			if "`e(n_re)'"!="1"{
				local labtextvcv `e(covtype)'
			}
			else local labtextvcv "Identity"
			di as res abbrev("`e(panel)'",12) as txt ": `labtextvcv'" _col(30) "{c |}"

			//Std. dev./Variances of random effects 
			local retimelabelnames2 `e(random_varlist)' 
			if "`e(re_nocons)'" =="" {
				local retimelabelnames2 `retimelabelnames2'	_cons
			}
			if ("`labtextvcv'"=="Independent" | "`labtextvcv'"=="Unstructured") {
				local test = 1
				forvalues i=1/`e(n_re)' {
					local lab : word `test' of `retimelabelnames2'
					Var_display, param("lns_`i'") label("`sdtxt'(`lab')") `variance'
					local `++test'
				}
			}
			else {
				local name = abbrev(trim("`retimelabelnames2'"),19)
				local n2 = length("`retimelabelnames2'")
				if `n2'>19 {
					local n1 "(1)"
				}
				Var_display, param("lns_1") label("`sdtxt'(`name')`n1'") `variance'
			}
			
		//Corrs/Covariances of random effects
			if ("`labtextvcv'"=="Unstructured" & `e(n_re)'>1) {
				local firstindex = 1
				local txtindex = 1
				while (`firstindex'<`e(n_re)') {
					local test = `firstindex' + 1
					local test2 = 1
					forvalues i=`test'/`e(n_re)' {
						local ind2 = `i'-1
						local lab1 : word `txtindex' of `retimelabelnames2'
						local lab2 : word `=`txtindex'+`test2'' of `retimelabelnames2'
						if "`variance'"=="" {
							Covar_display, param1("art_`firstindex'_`test'") label("`corrtxt'(`lab1',`lab2')") `variance'
						}
						else {
							Covar_display, param1("art_`firstindex'_`test'") param2("lns_`firstindex'") param3("lns_`test'") label("`corrtxt'(`lab1',`lab2')") `variance'
						}
						local `++test'
						local `++test2'
					}
					local `++firstindex'
					local `++txtindex'
				}
			}
			else if ("`labtextvcv'"=="Exchangeable" & `e(n_re)'>1) {
				local name = abbrev(trim("`retimelabelnames2'"),19)
				local n2 = length("`retimelabelnames2'")
				if `n2'>19 {
					local n1 "(1)"
				}
				if "`variance'"=="" {
					Covar_display, param1("art_1_1") label("`corrtxt'(`name')`n1'") `variance'
				}
				else {
					Covar_display, param1("art_1_1") param2("lns_1") param3("lns_1") label("`corrtxt'(`name')`n1'") `variance'
				}
			}
		
		di as txt "{hline 29}{c BT}{hline 48}"
		//overflow text		
		local l = length(trim("`retimelabelnames2'"))	
		if `l'>19 & ("`labtextvcv'"=="Exchangeable" | "`labtextvcv'"=="Identity") {
			di in green "(1) `retimelabelnames2'"
		}
		
		//final text
		if (`e(adapt)') local quadtxt Adaptive Gauss-Hermite quadrature using `e(gh)' nodes
		else local quadtxt Gauss-Hermite quadrature using `e(gh)' nodes
		
		if "`e(model)'"=="w" 				local stxt Weibull proportional hazards model
		else if "`e(model)'"=="gom" 		local stxt Gompertz proportional hazards model
		else if "`e(model)'"=="e" 			local stxt Exponential proportional hazards model
		else if "`e(model)'"=="fpm" 		local stxt Flexible parametric model
		else if "`e(model)'"=="llogistic" 	local stxt Log-logistic accelerated failure time model
		else if "`e(model)'"=="lnormal" 	local stxt Log-normal accelerated failure time model
		else if "`e(model)'"=="gamma" 		local stxt Generalised gamma accelerated failure time model
		
		di in green "  Survival submodel: `stxt'"
		di in green " Integration method: `quadtxt'"

end

program Var_display
	syntax, PARAM(string) LABEL(string) [VARiance]
	if "`variance'"=="" _diparm `param', exp notab
	else _diparm `param', f(exp(2*@)) d(2*exp(2*@)) notab
	Di_re_param, label("`label'")
end

program Covar_display
	syntax, param1(string) [PARAM2(string) PARAM3(string) LABEL(string) VARiance]
	if "`variance'"=="" {
		_diparm `param1', tanh notab
	}
	else {
		_diparm `param1' `param2' `param3', f(tanh(@1)*exp(@2)*exp(@3)) d((1-(tanh(@1)^2))*exp(@2+@3) tanh(@1)*exp(@2+@3) tanh(@1)*exp(@2+@3)) notab
	}
	Di_re_param, label("`label'")
end

program Di_re_param
	syntax, LABEL(string)
	local p = 29 - length("`label'")
	di as txt _col(`p') "`label'" _col(30) "{c |}" ///
			as res _col(33) %9.0g r(est) ///
			as res _col(44) %9.0g r(se)  ///
			as res _col(58) %9.0g cond(missing(r(se)),.,r(lb))  ///
			as res _col(70) %9.0g cond(missing(r(se)),.,r(ub))
end
