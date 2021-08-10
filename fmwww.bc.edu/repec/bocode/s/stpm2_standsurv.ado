*! version 1.0.2 22nov2016 PCL

// add a check for illegal options
// work on other scales
// error check for factor variables??

program define stpm2_standsurv
	version 12.2
	syntax  [if] [in],			 							///
		[													///	
		ATVARs(string)										/// list or stub for at variables
		CONTRASTVARs(string)								/// list or stub for contrasts
		ATREFerence(integer 1)								/// reference at() - default 1
		TIMEVar(varname) 									/// timepoints for predictions
		CONtrast(string)	 								/// type of contrast
		TRANSform(string)									/// Transformation for variance calculation
		CI 													/// request CI to be calculated
		FAILure												/// calculate failure function
		LEVel(real `c(level)')								/// level for CIs
		*													/// atn() options
		]
	
	tempvar touse_time touse_model xb expxb dxb  
	marksample touse, novarlist

// Extract at() options
	local optnum 1
	local end_of_ats 0
	local 0 ,`options'
	while `end_of_ats' == 0 {
		capture syntax [,] AT`optnum'(string) [*]
		if _rc {
			local N_at_options = `optnum' - 1
			local end_of_ats 1
			continue, break
		}
		else local 0 ,`options'

		local optnum = `optnum' + 1
	}
	local N_at_options = `optnum' - 1
	if "`0'" != "," {
		di as error "Illegal option: `0'"
		exit 198
	}
	local hasatoptions = `N_at_options' > 0
	if !`hasatoptions' local N_at_options 1
// Parse at() options	
// Probably does not work with factor variables
	if `hasatoptions' > 0 {
		forvalues i = 1/`N_at_options' {
	// parse "if" suboption
			tokenize "`at`i''", parse(",")
			local at`i'opt  `1'
			local atoptif `3'
			local 0 ,`3'
			syntax ,[if2(string)]
			if `"`if'"' != "" & `"`atoptif'"' != "" {
				di as error "You can either use an if statement or the if suboptions" _newline ///
							"of the at() options"
				exit 198
			}
			tempvar touse_at`i'
			if `"`atoptif'"' == "" {
				gen byte `touse_at`i'' = `touse'
			}
			else {
				gen byte `touse_at`i'' = (`if2')
			}

			tokenize `at`i'opt'
			while "`1'"!="" {
				fvunab tmpfv: `1'
				local 1 `tmpfv'
				_ms_parse_parts `1'
				if "`r(type)'"!="variable" {
					display as error "level indicators of factor" /*
									*/ " variables may not be individually set" /*
									*/ " with the at() option; set one value" /*
									*/ " for the entire factor variable"
					exit 198
				}
				cap confirm var `2'
				if _rc {
					cap confirm num `2'
					if _rc {
						di as err "invalid at(... `1' `2' ...)"
						exit 198
					}
				}
				local at`i'vars `at`i'vars' `1'
				local at`i'_`1'_value `2'
				mac shift 2
			}
		}
	}
	else {
		tempvar touse_at1
		gen byte `touse_at1' = `touse'
	}

	
// Number of observations for each at() option	
	forvalues i = 1/`N_at_options' {
		quietly count if `touse_at`i'' == 1
		local Nobs_predict_at1 `r(N)'
		local touse_at_list `touse_at_list' `touse_at`i''
	}

// names of new variables
	if "`atvars'" == "" {
		forvalues i = 1/`N_at_options' {
			local at_varnames `at_varnames' _at`i'
		}
	}
	else {
		capture _stubstar2names double `atvars', nvars(`N_at_options') 
		local at_varnames `s(varlist)'
		if _rc>0 {
			di as error "atvars() option should either give `N_at_options' new variable names " ///
				"or use the {it:stub*} option"
			exit 198
		}
	}
	if "`contrastvars'" == "" {
		forvalues i = 1/`N_at_options' {
			local contrast_varnames `contrast_varnames' _contrast`i'_`atreference'
		}
	}
	else {
		capture _stubstar2names double `contrastvars', nvars(`=`N_at_options'-1') 
		local contrast_varnames  `s(varlist)'
		if _rc>0 {
			di as error "contrastvars() option should either give `=`N_at_options'-1' new variable names " ///
				"or use the {it:stub*} option"
			exit 198
		}
	}
	if `atreference' != 1 {
		if !inrange(`atreference',1,`N_at_options') {
			di as error "atreference option out of range"
			exit 198
		}
	}
// Transform option
	if "`transform'" == "" local transform loglog
	if !inlist("`transform'","loglog","logit","log","none") {
		di as error "Transform options are none, log, loglog or logit"
		exit 198
	}
// Number of observations used in the model	
	quietly gen `touse_model' = e(sample)
	quietly count if `touse_model' == 1
	local Nobs_model `r(N)'

// time variable
	if "`timevar'" == "" local timevar _t
	gen byte `touse_time' = `timevar' != .

// transform option?	
	
//==============================================================================
// Need to add check for out of sample predictions 	

// Need to add some checks
// These are the old ones
/*	
	if "`contrast'" == "" {
		if `has_at2' & wordcount("`varlist'") != 2 {
			di as error "Two new variables need to be specified, one for each of the at1() and at2() options."
			exit 198
		}
	}
	
	if "`contrast'" != "" {
		if wordcount("`varlist'") != 3 {
			di as error "Three new variables need to be specified," _newline ///
				"one for each of the at1() and at2() options and" _newline ///
				"one for the contrast() option."
			exit 198
		}
		if `has_at2' == 0 {
			di as warning "Warning: at2() option has not been specified"
		}
	}
*/	

// Check contrast option	
	if "`contrast'" != "" {
		if !inlist("`contrast'","difference","ratio") {
			di as error "contrast option should either be difference or ratio"
			exit 198
		}
	}

// Use meansurv for point esxtimates	
	forvalues i = 1/`N_at_options' {
		tempvar S`i'
		local tempatopt = cond(`hasatoptions',"at(`at`i'opt')","")
		quietly predict `S`i'' if `touse_at`i'', meansurv `tempatopt' timevar(`timevar')
		local Smean_list `Smean_list' `S`i''
	}

// predict xb and dxb	
	if "`ci'" != "" {
		quietly predict `xb'  if e(sample), xb
		quietly predict `dxb' if e(sample) , dxb 
	}

	mata: standsurv()
end

// =============================================================================
// mata functions

mata
void function standsurv() {
	N_at_options = strtoreal(st_local("N_at_options"))				// number of at options
	hasatoptions = N_at_options >1
	touse_time = st_local("touse_time")								// indicator for timevar
	touse_model = st_local("touse_model")							// touse e(sample)
	Nobs_model = strtoreal(st_local("Nobs_model"))					// Number of individuals in model
	
	Nobs_predict_at = J(1,N_at_options,.)
	at_vars = J(1,N_at_options,"")
	for(i=1;i<=N_at_options;i++) {
		Nobs_predict_at[1,i] = strtoreal(st_local("Nobs_predict_at"+strofreal(i)))
		at_vars[1,i] = st_local("at"+strofreal(i)+"vars")
	}
	at_reference = strtoreal(st_local("atreference"))
	at_varnames = tokens(st_local("at_varnames"))				// new variables for at

	hascontrast = st_local("contrast") != ""						// contrast option
	contrast = st_local("contrast")									// type of contrast
	ci = st_local("ci") != ""										// indicator to calculate CIs
	level = strtoreal(st_local("level"))
	transform = st_local("transform")
	hasfailure = st_local("failure") != ""							// failure option
	hascons = st_global("e(noconstant)") == ""  
	hastvc = st_global("e(tvc)") != ""
	orthog = st_global("e(orthog)") != ""
    rcsbaseoff = st_global("rcsbaseoff") != ""
	scale = st_global("e(scale)")									// scale not yet implemented
	if (hastvc) {
		tvcnames = tokens(st_global("e(tvc)"))						// name of tvc covariates
		Ntvc = cols(tvcnames)										// Number of tvc covariates
	}
	if(hascontrast) contrast_varnames = tokens(st_local("contrast_varnames"))

//======================================================================================================================================//
// Variables created in Stata
	Smean = st_data(.,(st_local("Smean_list")),touse_time)				// Mean survival for each at() option

	if(ci) {
		xb = st_data(.,st_local("xb"),touse_model)						// observed (xb)
		expxb = exp(xb)													// observed exp(xb)
		dxb = st_data(.,st_local("dxb"),touse_model)					// observed dxb
		d = st_data(.,"_d",touse_model)									// event indicator
		t = st_data(.,st_local("timevar"),touse_time)					// times to predict at (timevar)
		Nt = rows(t)													// Number of time points
		touse_at = st_data(.,st_local("touse_at_list"),touse_model)

//======================================================================================================================================//
// get knot locations
		knots = asarray_create()
		if(!rcsbaseoff) asarray(knots,"baseline",strtoreal(tokens(st_global("e(ln_bhknots)"))))

		if(hastvc) {
			for(i=1;i<=cols(tvcnames);i++) {
				asarray(knots,tvcnames[i],strtoreal(tokens(st_global("e(ln_tvcknots_"+tvcnames[i]+")")))) 
			}
		}

//======================================================================================================================================//
// get R matrix	
		Rmatrix = asarray_create()
		if(orthog & !rcsbaseoff) asarray(Rmatrix,"baseline",st_matrix("e(R_bh)"))
		else asarray(Rmatrix,"baseline","")
		if(orthog & hastvc) {
			for(i=1;i<=cols(tvcnames);i++) {
				asarray(Rmatrix,tvcnames[i],st_matrix("e(R_"+tvcnames[i]+")"))
			}
		}	

//======================================================================================================================================//
// Observed X matrix and derivative of spline functions
		Nvarlist = cols(tokens(st_global("e(varlist)")))
		covariates = J(1,0,"")
		drcsvars = J(1,0,"")
		if(Nvarlist > 0) covariates = covariates, tokens(st_global("e(varlist)")) 
		if(!rcsbaseoff) {
			covariates = covariates, tokens(st_global("e(rcsterms_base)"))
			drcsvars = drcsvars, tokens(st_global("e(drcsterms_base)"))
		}
		if(hastvc) {
			for(i=1;i<=cols(tvcnames);i++) {
				covariates = covariates, tokens(st_global("e(rcsterms_"+tvcnames[i]+")"))
				drcsvars = drcsvars, tokens(st_global("e(drcsterms_"+tvcnames[i]+")"))
			}
		}
		X = st_data(.,covariates,touse_model)
		if(hascons) X = X,J(Nobs_model,1,1)

		Xdrcs = st_data(.,drcsvars,touse_model)
		Nparameters = cols(X)
		beta = st_matrix("e(b)")'[1..Nparameters,1]
		V = st_matrix("e(V)")[1..Nparameters,1..Nparameters]
	
//======================================================================================================================================//
// changes to X matrix needed for at() options
		X_at = asarray_create()
		X_at_index = asarray_create()
		if(hastvc) X_at_tvc = asarray_create() 

		for(i=1;i<=N_at_options;i++) {
			ati = "at" + strofreal(i)
			asarray(X_at_index,ati,J(1,0,.))
			asarray(X_at,ati,J(Nobs_model,0,.))
			// main effects
			for(j=1;j<=Nvarlist;j++) {
				if(subinword(at_vars[1,i],covariates[j],"") != at_vars[1,i]) {
					asarray(X_at_index,ati, (asarray(X_at_index,ati), j))
					atval_macro = st_local("at" + strofreal(i) + "_" + covariates[j]+"_value")
					asarray(X_at,ati,(asarray(X_at,ati), J(Nobs_model,1,strtoreal(atval_macro))))
				}
			}

			// tvcs
			if(hastvc) {
				asarray(X_at_tvc,ati, J(Nobs_model,0,.))
				for(j=1;j<=Ntvc;j++) {
					if(subinword(at_vars[1,i],tvcnames[j],"") != at_vars[1,i]) {
						atval_macro = st_local("at" + strofreal(i) + "_" + tvcnames[j]+"_value")
						asarray(X_at_tvc, ati, (asarray(X_at_tvc, ati),J(Nobs_model,1,strtoreal(atval_macro)))) 
					}
					else {
						asarray(X_at_tvc,ati, (asarray(X_at_tvc,ati), st_data(.,tvcnames[j],touse_model)))
					}
				}
			}
		}


//======================================================================================================================================//	
// Get U_beta (derivative of score function) as does not depend on t.
		Ubeta = J(Nobs_model,Nparameters,.)
		drcs_index = 1
		for(k=1;k<=Nparameters;k++) {
			if(k<=Nvarlist | k == Nparameters) {
				Ubeta[,k] = (d :- expxb):*X[,k]
			}
			else {
				Ubeta[,k]  = (d:/dxb):*Xdrcs[,drcs_index] :+ (d :- expxb):*X[,k]
				drcs_index++
			}
		}

//======================================================================================================================================//	
// A11 and A22 do not depend on t

		A11 = -1*diag(mean(touse_at))
		A22 = -luinv(V):/ Nobs_model
		
		CI_at_lci = J(Nt,N_at_options,.)
		CI_at_uci = J(Nt,N_at_options,.)
		
		if(hascontrast) {
			CI_contrast_lci = J(Nt,N_at_options,.)
			CI_contrast_uci = J(Nt,N_at_options,.)
			contrast_est = J(Nt,N_at_options,.)
		}
		SurvVcov = asarray_create("real")

//======================================================================================================================================//	
// Loop over time points
		for(j=1;j<=Nt;j++) {
		// splines for baseline and tvcs
			lnt = ln(t[j])
			if(orthog) Xrcsbase = rcsgen_core(lnt,asarray(knots,"baseline"),0,asarray(Rmatrix,"baseline"))
			else Xrcsbase = rcsgen_core(lnt,asarray(knots,"baseline"),0)
			if(hastvc) {
				Xrcstvc = asarray_create()
				for(i=1;i<=Ntvc;i++) {
					if(orthog) asarray(Xrcstvc,tvcnames[i],rcsgen_core(lnt,asarray(knots,tvcnames[i]),0,asarray(Rmatrix,tvcnames[i])))
					else asarray(Xrcstvc,tvcnames[i],rcsgen_core(lnt,asarray(knots,tvcnames[i]),0))
				}
			}
		// Different X matrices for each at() option	
			X_at_t = asarray_create()
			Si = J(Nobs_model,N_at_options,.)
			for(i=1;i<=N_at_options;i++) {
				ati = "at" + strofreal(i)
				X_tmp = X[,1..Nvarlist]
				X_tmp[,asarray(X_at_index,ati)] = asarray(X_at,ati)
				X_tmp = X_tmp, J(Nobs_model,1,Xrcsbase)
				if(hastvc) {
					for(k=1;k<=Ntvc;k++) {
						X_tmp = X_tmp, J(Nobs_model,1,asarray(Xrcstvc,tvcnames[k])):*asarray(X_at_tvc,ati)[,k]
					}
				}
				if(hascons) X_tmp = X_tmp,J(Nobs_model,1,1)	
				asarray(X_at_t,ati,X_tmp)
				Si[,i] = exp(-exp(asarray(X_at_t,ati)*beta))
			}

			// U matrix	
			U = (Si :- Smean[j,]):*touse_at
			VarU = quadvariance((U,Ubeta))

			// A12 matrix
			A12 = J(N_at_options,Nparameters,.)
			for(i=1;i<=N_at_options;i++) {
				ati = "at" + strofreal(i)
				for(k=1;k<=Nparameters;k++) {
					A12[i,k] = mean(Si[,i] :* log(Si[,i]):*asarray(X_at_t,ati)[,k]:*touse_at[,i])
				}
			}
			
			zeros = J(Nparameters,N_at_options,0)
			Ainv = luinv((A11,A12 \ zeros, A22))
			asarray(SurvVcov,j,((Ainv*VarU*Ainv'):/Nobs_model)[1..N_at_options,1..N_at_options])
			// transform to scale to calculate CIs
			est = Smean[j,]
			Vest = asarray(SurvVcov,j)[1..N_at_options,1..N_at_options] 

			if(transform == "none") {
				est_trans = est
				Vest_trans =  Vest
				dtransform = I(N_at_options)
			}
			else if(transform == "log") {
				dtransform = diag(1:/est)
				est_trans = log(est)
			}
			else if(transform == "logit") {
				dtransform = diag(1:/(est:*(1:-est)))
				est_trans = logit(est)
			}
			else if(transform == "loglog") {
				dtransform = diag(1:/(est:*ln(est))) // Update thius
				est_trans = log(-log(est))
			}	

			Vest_trans = dtransform' * Vest * dtransform
			
			// return CIs of mean survival for each at() option 
			theta = invnormal(1-(1-level/100)/2)*sqrt(diagonal(Vest_trans))
			at_lci = est_trans - theta'
			at_uci = est_trans + theta'
			if(transform != "") {
				if(transform == "log") {
					CI_at_lci[j,] = exp(at_lci)
					CI_at_uci[j,] = exp(at_uci)
				}
				else if(transform == "logit") {
					CI_at_lci[j,] = invlogit(at_lci)
					CI_at_uci[j,] = invlogit(at_uci)				
				}	
				else if(transform == "loglog") {
					CI_at_lci[j,] = exp(-exp(at_uci))
					CI_at_uci[j,] = exp(-exp(at_lci))
				}
			}
			else {
					CI_at_lci[j,] = (at_lci)
					CI_at_uci[j,] = (at_uci)
			}
	
//======================================================================================================================================//	
// Now perform contrasts
// Note at1() is the reference by default

			if(hascontrast) {
				if(contrast == "difference") {
					dcontrast_dtransform = I(N_at_options)
					dcontrast_dtransform[,at_reference] = J(N_at_options,1,-1)
					dcontrast_dtransform[at_reference,at_reference] = 0
					contrast_est[j,] = est :- est[,at_reference]
				}
				if(contrast == "ratio") {	// calculate on log scale
					dcontrast_dtransform = I(N_at_options):/est
					dcontrast_dtransform[,at_reference] = -1:/est'
					dcontrast_dtransform[at_reference,at_reference] = 0
					contrast_est[j,] = ln(est) :- ln(est[,at_reference])
				}
				Vcont = dcontrast_dtransform*Vest*dcontrast_dtransform'
				if(contrast== "difference") {
					CI_contrast_lci[j,] = contrast_est[j,] - invnormal(1-(1-level/100)/2)*sqrt(diagonal(Vcont)')
					CI_contrast_uci[j,] = contrast_est[j,] + invnormal(1-(1-level/100)/2)*sqrt(diagonal(Vcont)')
				}
				else if(contrast== "ratio") {
					CI_contrast_lci[j,] = exp((contrast_est[j,]) - invnormal(1-(1-level/100)/2)*sqrt(diagonal(Vcont)'))
					CI_contrast_uci[j,] = exp((contrast_est[j,]) + invnormal(1-(1-level/100)/2)*sqrt(diagonal(Vcont)'))
					contrast_est[j,] = exp(contrast_est[j,])
				}
			}
		}
	}

//======================================================================================================================================//
// failure option
	if(hasfailure) {
		Smean = 1 :- Smean
		if(ci) {
			CI_at_lci = 1:-CI_at_lci
			CI_at_uci = 1:-CI_at_uci
			swap(CI_at_lci,CI_at_uci)
		}
		if(hascontrast) {
			contrast_est = -contrast_est
			if(ci) {
				CI_contrast_lci = -CI_contrast_lci
				CI_contrast_uci = -CI_contrast_uci
				swap(CI_contrast_lci,CI_contrast_uci)
			}
		}
	}
//======================================================================================================================================//
// Store results in Stata
	for(i=1;i<=N_at_options;i++) {
		(void) st_addvar("double",at_varnames[1,i])
		st_store(.,at_varnames[1,i],touse_time,Smean[,i])
		if(ci) {
			(void) st_addvar(("double","double"),(at_varnames[1,i]+"_lci",at_varnames[1,i]+"_uci"))
			st_store(.,at_varnames[1,i]+"_lci",touse_time,CI_at_lci[,i])
			st_store(.,at_varnames[1,i]+"_uci",touse_time,CI_at_uci[,i])
		}
	}
	if(hascontrast) {
		cont_index = 1
		for(i=1;i<=N_at_options;i++) {
			if(i != at_reference) { 						// do not write for reference
				(void) st_addvar("double",contrast_varnames[1,cont_index])
				st_store(.,contrast_varnames[1,cont_index],touse_time,contrast_est[,i])
				if(ci) {
					(void) st_addvar(("double","double"),(contrast_varnames[1,cont_index]+"_lci",contrast_varnames[1,cont_index]+"_uci"))
					st_store(.,contrast_varnames[1,cont_index]+"_lci",touse_time,CI_contrast_lci[,i])
					st_store(.,contrast_varnames[1,cont_index]+"_uci",touse_time,CI_contrast_uci[,i])
				}
				cont_index = cont_index + 1
			}
		}
	}
}

//calculate splines with provided knots
real matrix rcsgen_core(	real colvector variable,	///
							real rowvector knots, 		///
							real scalar deriv,|			///
							real matrix rmatrix			///
						)
{
	real scalar  Nobs, Nknots, kmin, kmax, interior, Nparams
	real matrix splines, knots2

	//======================================================================================================================================//
	// Extract knot locations

		Nobs 	= rows(variable)
		Nknots 	= cols(knots)
		kmin 	= knots[1,1]
		kmax 	= knots[1,Nknots]
	
		if (Nknots==2) interior = 0
		else interior = Nknots - 2
		Nparams = interior + 1
		
		splines = J(Nobs,Nparams,.)

	//======================================================================================================================================//
	// Calculate splines

		if (Nparams>1) {
			lambda = J(Nobs,1,(kmax:-knots[,2..Nparams]):/(kmax:-kmin))
			knots2 = J(Nobs,1,knots[,2..Nparams])
		}

		if (deriv==0) {
			splines[,1] = variable
			if (Nparams>1) {
				splines[,2..Nparams] = (variable:-knots2):^3 :* (variable:>knots2) :- lambda:*((variable:-kmin):^3):*(variable:>kmin) :- (1:-lambda):*((variable:-kmax):^3):*(variable:>kmax) 
			}
		}
		else if (deriv==1) {
			splines[,1] = J(Nobs,1,1)
			if (Nparams>1) {
				splines[,2..Nparams] = 3:*(variable:-knots2):^2 :* (variable:>knots2) :- lambda:*(3:*(variable:-kmin):^2):*(variable:>kmin) :- (1:-lambda):*(3:*(variable:-kmax):^2):*(variable:>kmax) 	
			}
		}
		else if (deriv==2) {
			splines[,1] = J(Nobs,1,0)
			if (Nparams>1) {
				splines[,2..Nparams] = 6:*(variable:-knots2) :* (variable:>knots2) :- lambda:*(6:*(variable:-kmin)):*(variable:>kmin) :- (1:-lambda):*(6:*(variable:-kmax)):*(variable:>kmax) 	
			}
		}
		else if (deriv==3) {
			splines[,1] = J(Nobs,1,0)
			if (Nparams>1) {
				splines[,2..Nparams] = 6:*(variable:>knots2) :- lambda:*6:*(variable:>kmin) :- (1:-lambda):*6:*(variable:>kmax)
			}
		}
	
		//orthog
		if (args()==4) {
			real matrix rmat
			rmat = luinv(rmatrix)
			if (deriv==0) splines = (splines,J(Nobs,1,1)) * rmat[,1..Nparams]
			else splines = splines * rmat[1..Nparams,1..Nparams]
		}
		return(splines)
}

end
	
