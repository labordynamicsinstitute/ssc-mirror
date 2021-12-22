mata
mata clear

// structures

struct var_struct {

	/* ======================================================== */
	/*                         KEY                          	*/
	/* ======================================================== */
	/* SCALARS 													*/
	/* ======================================================== */
	/* cconst ... indicator: 0=no constant/trend, 				*/
	/*						 1=constant, 2=trend+const, 		*/
	/*						 3=const+trend+trend^2 				*/
	/* nvar ... number of endogenous variables 					*/
	/* nlag ... number of lags on endogenous variables 			*/
	/* nvar_ex ... number of exogenous variables 				*/
	/* nlag_ex ... number of lags on exogenous variables 		*/
	/* nobs ... number of observations in dataset 				*/
	/* ncoeff ... number coefficients per eqn for endog vars 	*/
	/* ncoeff_ex ... number coefficients per eqn for exog vars 	*/
	/* ntot_coeff ... total number of coefficients 				*/
	/* ntot_coeff ... maximum eigenvalue 						*/
	/* ======================================================== */
	/* MATRICES 												*/
	/* ======================================================== */
	/* data ... matrix of data used in Stata VAR 				*/
	/* X_EX ... lagged matrix of exogenous variables 			*/
	/* Y ... nvar-dimensional time series y_t, t=1,...,T 		*/
	/* X ...  lagged time series (y_t-1 ... y_t-p) 				*/
	/* A ... OLS reduced-form matrix of coefficients 			*/
	/* A_comp ... companion matrix 								*/
	/* sigma ... variance-covariance matrix 					*/
	/* U ... matrix of residuals 								*/
	/* inv_B0 ... matrix of impact effects on struct shocks  	*/
	/* Q ... randomly drawn orthonormal matrix (SR) 			*/
	/* ======================================================== */
	/* STRINGS 													*/
	/* ======================================================== */
	/* plt_lbls ... endogenous variables' names (for plotting) 	*/
	/* tsrs_var ... name of tsset variable 						*/
	/* tsrs_dlt ... tsset delta format 							*/
	/* shck_nms ... names of structural shocks (SR) 			*/
	/* ======================================================== */
	
	real scalar 	cconst
	real scalar 	nvar
	real scalar 	nlag
	real scalar 	nvar_ex
	real scalar 	nlag_ex
	real scalar 	nobs
	real scalar 	ncoeff
	real scalar 	ncoeff_ex
	real scalar 	ntotcoeff
	real scalar 	maxEig
	
	real matrix 	data
	real matrix 	Y
	real matrix 	X
	real matrix 	X_EX
	real matrix 	A
	real matrix 	A_comp
	real matrix 	sigma
	real matrix 	U
	real matrix 	inv_B0
	real matrix 	Q
	
	string vector 	plt_lbls
	string scalar 	tsrs_var
	string scalar 	tsrs_dlt
	string vector 	shck_nms

}

struct opt_struct {

	string scalar 	ident
	real scalar 	nsteps
	real scalar 	impact
	real scalar 	shut
	real scalar 	pctg
	string scalar 	method
	
	string scalar 	save_fmt
	string scalar	shck_plt
	
	real scalar 	ndraws
	real scalar 	err_lmt
	real scalar 	updt_frqcy
	string scalar 	updt
	
}

struct irf_bands_struct {

	transmorphic scalar 	INF
	transmorphic scalar 	SUP
	transmorphic scalar 	MED
	transmorphic scalar 	BAR

}

struct fevd_bands_struct {

	transmorphic scalar 	INF
	transmorphic scalar 	SUP
	transmorphic scalar 	MED
	transmorphic scalar 	BAR

}

// functions

transmorphic scalar function opt_set() {

	struct opt_struct scalar opt

	opt.ident 		= "sr" 		// "oir" "bq"
	opt.nsteps 		= 40
	opt.impact 		= 0 		// 1
	opt.shut 		= 0 		// 1
	opt.pctg 		= 95
	opt.method 		= "bs" 		// "wild"
	
	opt.save_fmt 	= "none" 	// "gph", filetypes (ie "png")
	opt.shck_plt 	= "all" 	// name of shock or variable
	
	opt.ndraws 		= 100
	opt.err_lmt 	= 4000
	opt.updt_frqcy 	= 10000
	opt.updt 		= "no" 		// "yes"
	
	return(opt)

}

void function opt_display(struct opt_struct scalar opt) {

	string scalar 	d1
	string scalar 	d2
	string scalar 	d3
	string scalar 	d4
	string scalar 	d5
	string scalar 	d6
	string scalar 	d7
	string scalar 	d8
	string scalar 	d9
	string scalar 	d10
	string scalar 	d11
	string scalar 	d12
	
	d1 = "Identification option (ident): " + opt.ident
	d2 = "IRF maximum horizon (nsteps): " + strofreal(opt.nsteps)
	d3 = "IRF impact: one std deviation (0) or unitary (1) (impact): " + strofreal(opt.impact)
	d4 = "IRF set to zero one row of companion matrix (shut): " + strofreal(opt.shut)
	d5 = "IRF error bands percentile (pctg): " + strofreal(opt.pctg)
	d6 = "IRF re-sampling method, bootstrap (bs) or wild-bootsrap (wild) (method): " + opt.method
	d7 = "Plot file format (save_fmt): " + opt.save_fmt
	d8 = "Which variable(s) to plot (shck_plt): " + opt.shck_plt
	d9 = "Number of desired draws using [narrative] sign restrictions (ndraws): " + strofreal(opt.ndraws)
	d10 = "Maximum failed [narrative] sign restriction draws allowed (err_limit): " + strofreal(opt.err_lmt)
	d11 = "Display progress on [narrative] sign restriction loops (upt): " + opt.updt
	d12 = "[Narrative] sign restricts updates progress per (updt_frqcy) draws: " + strofreal(opt.updt_frqcy)
	
	display(d1)
	display(d2)
	display(d3)
	display(d4)
	display(d5)
	display(d6)
	display(d7)
	display(d8)
	display(d9)
	display(d10)
	display(d11)
	display(d12)

}

transmorphic scalar function var_funct(string scalar end_list,string scalar nvar,string scalar nlag,
									   string scalar cconst,string scalar nvar_ex,string scalar nlag_ex,
									   string scalar tsrs_var,string scalar tsrs_dlt,string scalar EXO) {

	struct var_struct scalar v
	real scalar 	jj
	real vector 	trend
	real vector 	trend_sq
	real scalar 	diff

	// get data matrix
	v.nvar 			= strtoreal(nvar)
	v.data 			= st_data(.,(end_list))
	
	// get names for plotting, possible sign restricts
	v.plt_lbls 		= tokens(end_list)
	v.tsrs_var 		= tsrs_var
	v.tsrs_dlt 		= tsrs_dlt
	v.shck_nms 		= J(1,0,"")
	
	// get real scalars
	v.cconst 		= strtoreal(cconst)
	v.nlag 			= strtoreal(nlag)
	v.nvar_ex 		= strtoreal(nvar_ex)
	v.nlag_ex 		= strtoreal(nlag_ex)
	v.nobs 			= rows(v.data)
	
	// get exogenous variable data if applicable
	if (v.nvar_ex>0) v.X_EX = st_matrix(EXO)
	
	// coefficient counts
	v.ncoeff 		= v.nvar*v.nlag
	v.ncoeff_ex 	= cols(v.X_EX)
	v.ntotcoeff 	= v.ncoeff+v.ncoeff_ex+v.cconst
	
	// get Y matrix
	v.Y	= v.data[| v.nlag+1,1 \ .,. |]
	
	// get lagged X matrix
	v.X	= (v.data[(1 :: v.nobs-v.nlag),.]) 
	for (jj=1; jj<=v.nlag-1; jj++) {
		v.X = (v.data[(1+jj :: v.nobs-v.nlag+jj),.], v.X)
	}
	if (v.cconst==1) v.X = (J(v.nobs-v.nlag,1,1), v.X)
	else if (v.cconst==2) {
		trend = (1::rows(v.X))
		v.X = (J(v.nobs-v.nlag,1,1), trend, v.X)
	}
	else if (v.cconst==3) {
		trend = (1::rows(v.X))
		trend_sq = trend :^ 2
		v.X = (J(v.nobs-v.nlag,1,1), trend, trend_sq, v.X)
	};

	// get exogenous var data, append exog vars to X
	if (v.nvar_ex > 0) {
		// number of lags on endog vars = number of lags of exog vars
		if (v.nlag==v.nlag_ex) v.X = (v.X, v.X_EX)
		// number of lags on endog vars > number of lags of exog vars
		else if (v.nlag > v.nlag_ex) {
			diff = v.nlag - v.nlag_ex
			v.X_EX = v.X_EX[| diff+1,1 \ .,. |]
			v.X = (v.X, v.X_EX)
		}
		// number of lags on endog vars < number of lags of exog vars
		else {
			diff = v.nlag_ex - v.nlag
			v.Y = v.Y[| diff+1,1 \ .,. |]
			v.X = (v.X[| diff+1,1 \ .,. |], v.X_EX)
		}
	}
	
	// get remaining objects in structure
	v.A			= lusolve((v.X'*v.X),(v.X'*v.Y))
	v.A_comp 	= ((v.A')[.,(1+v.cconst :: v.nvar*v.nlag+v.cconst)])\(I(v.nvar*(v.nlag-1)),J(v.nvar*(v.nlag-1),v.nvar,0))
	v.sigma		= (1/((v.nobs-max((v.nlag,v.nlag_ex)))-v.ntotcoeff))*((v.Y-v.X*v.A)'*(v.Y-v.X*v.A))
	v.U			= v.Y - v.X*v.A
	v.maxEig 	= max((abs(eigenvalues(v.A_comp))))
	
	// initialize (but do not populate) inv_B0 matrix
	v.inv_B0 = J(0,0,.)

	return(v)
}

transmorphic scalar function var_simulation(struct var_struct scalar v_og, real matrix newdata) {

	struct var_struct scalar v_new
	
	real scalar 	jj
	real vector 	trend
	real vector 	trend_sq
	
	v_new = v_og
	v_new.data = newdata

	v_new.Y		= v_new.data[| v_og.nlag+1,1 \ .,. |]
	v_new.X		= (v_new.data[| 1+0,1 \ v_og.nobs-v_og.nlag+0,. |])
	
	for (jj=1; jj<=v_og.nlag-1; jj++) {
		v_new.X = (v_new.data[| 1+jj,1 \ v_og.nobs-v_og.nlag+jj,. |], v_new.X)
	}
	if (v_og.cconst==1) v_new.X = (J(v_og.nobs-v_og.nlag,1,1), v_new.X)
	else if (v_og.cconst==2) {
		trend = (1::rows(v_new.X))
		v_new.X = (J(v_og.nobs-v_og.nlag,1,1), trend, v_new.X)
	}
	else if (v_og.cconst==3) {
		trend = (1::rows(v_new.X))
		trend_sq = trend :^ 2
		v_new.X = (J(v_og.nobs-v_og.nlag,1,1), trend, trend_sq, v_new.X)
	}
	
	if (v_og.nvar_ex > 0) v_new.X = (v_new.X, v_og.X_EX)

	v_new.A			= lusolve((v_new.X'*v_new.X),(v_new.X'*v_new.Y))
	v_new.A_comp 	= ((v_new.A')[.,(1+v_new.cconst :: v_new.nvar*v_new.nlag+v_new.cconst)])\(I(v_new.nvar*(v_new.nlag-1)),J(v_new.nvar*(v_new.nlag-1),v_new.nvar,0))
	v_new.sigma		= (1/((v_new.nobs-max((v_new.nlag,v_new.nlag_ex)))-v_new.ntotcoeff))*((v_new.Y-v_new.X*v_new.A)'*(v_new.Y-v_new.X*v_new.A))
	v_new.U			= v_new.Y - v_new.X*v_new.A
	v_new.maxEig 	= max((abs(eigenvalues(v_new.A_comp))))
	
	v_new.inv_B0 = J(0,0,.)

	return(v_new)
}

transmorphic scalar function irf_funct(struct var_struct scalar v, struct opt_struct scalar opt) {
	
	transmorphic scalar 	irf
	real scalar 			mm
	real matrix 			A_comp
	real matrix 			response
	real matrix 			impulse
	real matrix 			impulse_big
	real matrix 			A_comp_i
	real scalar 			kk
	real vector 			response_big
	
	irf = asarray_create("real")
	
	A_comp = v.A_comp
	
	// get matrix inv_B0 containing structural impulses
	identify(v,opt)
	
	for (mm=1; mm<=v.nvar; mm++) {

	    // Set to zero a row of the companion matrix if "shut" is selected
		if (opt.shut!=0) A_comp[opt.shut,.] = J(1,cols(A_comp),0)
		
		// impulse and response vectors
		response 	= J(v.nvar,opt.nsteps,0)
		impulse 	= J(v.nvar,1,0)
		
		// Set size of shock
		// One standard deviation
		if (opt.impact==0) impulse[mm,1]=1
		// Unitary shock
		else if (opt.impact==1) impulse[mm,1]=1/v.inv_B0[mm,mm]
		else _error("opt.impact must be either 0 or 1")
		
		response[.,1] = v.inv_B0*impulse
		
		if (opt.shut!=0) {
			response[opt.shut,1] = 0
		}
		
		impulse_big = (response[.,1]', J(1,v.nvar*(v.nlag-1),0))'
		
		// Recursive computation
		A_comp_i = I(max((rows(A_comp),cols(A_comp))))
		for (kk=2; kk<=opt.nsteps; kk++) {
			A_comp_i = A_comp*A_comp_i
			response_big = A_comp_i*impulse_big
			response[.,kk] = response_big[1::v.nvar]
		}
		
		asarray(irf, mm, (response'))
		
	}
	
	return(irf)	
}

transmorphic scalar function irf_bands_funct(struct var_struct scalar v, struct opt_struct scalar opt) {

	struct irf_bands_struct scalar 	irfb
	struct var_struct scalar 		v_draw
	
	real matrix 			y_artfcl
	transmorphic scalar 	irf_dr
	real scalar 			tt
	
	real scalar 			rr
	real vector 			u
	real scalar 			jj
	real scalar 			mm
	real vector 			T
	real matrix 			LAG
	real vector 			LAGpl1
	real vector 			LAGpl2
	
	real scalar 			pctg_inf
	real scalar 			pctg_sup
	
	y_artfcl = J(v.nobs,v.nvar,0)
	
	irf_dr = asarray_create("real")
	
	tt = 1
	
	while (tt<=opt.ndraws) {
	
		// generate residuals using bootstrap or wild bootstrap method
		if (opt.method=="bs") {
			u = v.U[ceil(rows(v.U)*runiform(v.nobs,1)),.]
		}
		else if (opt.method=="wild") {
			rr = 1:-2*(runiform(v.nobs,1):>0.5)
			u = v.U:*(rr*J(1,v.nvar,1))
		}
		else error("The opt.method specified is unavailable")
		
		// generate initial values for artificial data
		LAG = J(1,0,.)
		for (jj=1;jj<=v.nlag;jj++) {
			y_artfcl[jj,.] = v.data[jj,.]
			LAG = (y_artfcl[jj,.], LAG)
		}
		T = (1::v.nobs)
		if (v.cconst==0) LAGpl1 = LAG
		else if (v.cconst==1) LAGpl1 = (1, LAG)
		else if (v.cconst==2) LAGpl1 = (1, T[1], LAG)
		else if (v.cconst==3) LAGpl1 = (1, T[1], T[1]:^2, LAG)
		;
		if (v.nvar_ex!=0) LAGpl1 = (LAGpl1, v.X_EX[1,.])
		;
		
		// generate artificial series
		LAGpl2 = LAGpl1
		for (jj=v.nlag+1; jj<=v.nobs; jj++) {
			for (mm=1;mm<=v.nvar;mm++) {
				y_artfcl[jj,mm] = LAGpl2*v.A[.,mm]:+u[jj-v.nlag,mm]			
			}
			if (jj<v.nobs) {
				LAG = (y_artfcl[jj,.], LAG[| 1,1 \ 1,(v.nlag-1)*v.nvar |])
				if (v.cconst==0) LAGpl2 = LAG
				else if (v.cconst==1) LAGpl2 = (1, LAG)
				else if (v.cconst==2) LAGpl2 = (1, T[jj-v.nlag+1], LAG)
				else if (v.cconst==3) LAGpl2 = (1, T[jj-v.nlag+1], T[jj-v.nlag+1]:^2, LAG)
				;
				if (v.nvar_ex!=0) LAGpl2 = (LAGpl2, v.X_EX[jj-v.nlag+1,.])
				;
			}
		}
		
		// get max eigenvalue from VAR on artificial data
		v_draw = var_simulation(v,y_artfcl)
		if (v_draw.maxEig<0.9999) {
			// calculate and store IRF
			asarray(irf_dr,tt,irf_funct(v_draw,opt))
			tt = tt+1
		}
		;
	}
	
	/* compute error bands */
	pctg_inf = (100-opt.pctg)/2
	pctg_sup = 100 - (100-opt.pctg)/2
	
	irfb.INF = prctile_or_mean(irf_dr,pctg_inf,"percentile")
	irfb.SUP = prctile_or_mean(irf_dr,pctg_sup,"percentile")
	irfb.MED = prctile_or_mean(irf_dr,50,"percentile")
	irfb.BAR = prctile_or_mean(irf_dr,.,"mean")
	
	return(irfb)

}

void irf_plot(transmorphic scalar irs, struct irf_bands_struct scalar irb,
			  struct var_struct scalar v, struct opt_struct scalar opt) {

	real scalar 	nsteps
	real scalar 	nvars
	
	string scalar 	plt_irf
	string scalar 	plt_inf
	string scalar 	plt_sup
	string scalar 	plt_list
	string scalar 	cmbn_cmd
	string scalar 	lbl1
	string scalar 	lbl2
	
	string scalar 	plt_cmd
	string scalar 	xpt_cmd
	string scalar 	drp_cmd

	real scalar 	nn
	real scalar 	pp
	real vector 	nstep_mat
	real vector 	lbl_vect

	nsteps = rows(asarray(irs,1))
	nvars = cols(asarray(irs,1))
	
	nstep_mat = (1::nsteps)
	
	// plot all IRFs
	if (opt.shck_plt=="all") {
		for (nn=1; nn<=nvars; nn++) {
			st_matrix("irf_mat_temp",(nstep_mat,(asarray(irs,nn))))
			st_matrix("inf_mat_temp",(asarray(irb.INF,nn)))
			st_matrix("sup_mat_temp",(asarray(irb.SUP,nn)))
			stata("svmat irf_mat_temp")
			stata("svmat inf_mat_temp")
			stata("svmat sup_mat_temp")
			
			plt_irf = ""
			plt_inf = ""
			plt_sup = ""
			
			for (pp=1; pp<=nvars; pp++) {
				plt_irf = "(line irf_mat_temp" + strofreal(pp+1) + " irf_mat_temp1, lcolor(dknavy)) "
				plt_inf = "(line inf_mat_temp" + strofreal(pp) + " irf_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
				plt_sup = "(line sup_mat_temp" + strofreal(pp) + " irf_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
				plt_list = plt_irf + plt_inf + plt_sup
				
				lbl1 = v.plt_lbls[pp]
				if (v.shck_nms!=J(1,0,"")) {
					lbl2 = v.shck_nms[nn]
				}
				else {
					lbl2 = v.plt_lbls[nn]
				}
				
				plt_cmd = "graph twoway " + plt_list + ", name(irf_" + strofreal(pp) + ") legend(off) title(" + lbl1 + " to " + lbl2
				plt_cmd = plt_cmd + `") xtitle("")"'
				drp_cmd = "drop irf_mat_temp" + strofreal(pp+1) + " inf_mat_temp" + strofreal(pp) + " sup_mat_temp" + strofreal(pp)
				
				stata(plt_cmd)
				stata(drp_cmd)
			}
			stata("drop irf_mat_temp1")
			
			cmbn_cmd = "graph combine "
			for (pp=1; pp<=nvars; pp++) {
				cmbn_cmd = cmbn_cmd + "irf_" + strofreal(pp) + " "
			}
			lbl2 = usubinstr(lbl2," ","_",.)
			cmbn_cmd = cmbn_cmd + ", name(IRF_" + lbl2 + ")"
			stata(cmbn_cmd)
			
			drp_cmd = "graph drop "
			for (pp=1; pp<=nvars; pp++) {
				drp_cmd = drp_cmd + " irf_" + strofreal(pp)
			}
			stata(drp_cmd)
			
			if (opt.save_fmt=="gph") xpt_cmd = "graph save IRF_" + lbl2
			else if (opt.save_fmt=="none") {
				// no save
			}
			else xpt_cmd = "graph export IRF_" + lbl2 + "." + opt.save_fmt
			stata(xpt_cmd)
		}
	}
	
	// plot only specified IRFs
	else {
		if (v.shck_nms!=J(1,0,"") & sum(v.shck_nms:==opt.shck_plt)!=0) {
			lbl_vect = (v.shck_nms:==opt.shck_plt)
			nn = lbl_vect*(1::length(lbl_vect))
			if (nn==0) _error("invalid shock/variable name")
			lbl2 = v.shck_nms[nn]
		}
		else {
			lbl_vect = (v.plt_lbls:==opt.shck_plt)
			nn = lbl_vect*(1::length(lbl_vect))
			if (nn==0) _error("invalid shock/variable name")
			lbl2 = v.plt_lbls[nn]
		}

		st_matrix("irf_mat_temp",(nstep_mat,(asarray(irs,nn))))
		st_matrix("inf_mat_temp",(asarray(irb.INF,nn)))
		st_matrix("sup_mat_temp",(asarray(irb.SUP,nn)))
		stata("svmat irf_mat_temp")
		stata("svmat inf_mat_temp")
		stata("svmat sup_mat_temp")
		
		plt_irf = ""
		plt_inf = ""
		plt_sup = ""
		
		for (pp=1; pp<=nvars; pp++) {
			plt_irf = "(line irf_mat_temp" + strofreal(pp+1) + " irf_mat_temp1, lcolor(dknavy)) "
			plt_inf = "(line inf_mat_temp" + strofreal(pp) + " irf_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
			plt_sup = "(line sup_mat_temp" + strofreal(pp) + " irf_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
			plt_list = plt_irf + plt_inf + plt_sup
			
			lbl1 = v.plt_lbls[pp]
			
			plt_cmd = "graph twoway " + plt_list + ", name(irf_" + strofreal(pp) + ") legend(off) title(" + lbl1 + " to " + lbl2
			plt_cmd = plt_cmd + `") xtitle("")"'
			drp_cmd = "drop irf_mat_temp" + strofreal(pp+1) + " inf_mat_temp" + strofreal(pp) + " sup_mat_temp" + strofreal(pp)
			
			stata(plt_cmd)
			stata(drp_cmd)
		}
		stata("drop irf_mat_temp1")
		
		cmbn_cmd = "graph combine "
		for (pp=1; pp<=nvars; pp++) {
			cmbn_cmd = cmbn_cmd + "irf_" + strofreal(pp) + " "
		}
		lbl2 = usubinstr(lbl2," ","_",.)
		cmbn_cmd = cmbn_cmd + ", name(IRF_" + lbl2 + ")"
		stata(cmbn_cmd)
		
		drp_cmd = "graph drop "
		for (pp=1; pp<=nvars; pp++) {
			drp_cmd = drp_cmd + " irf_" + strofreal(pp)
		}
		stata(drp_cmd)
		
		if (opt.save_fmt=="gph") xpt_cmd = "graph save IRF_" + lbl2
		else if (opt.save_fmt=="none") {
			// no save
		}
		else xpt_cmd = "graph export IRF_" + lbl2 + "." + opt.save_fmt
		stata(xpt_cmd)
	}
}

transmorphic scalar function fevd_funct(struct var_struct scalar v, struct opt_struct scalar opt) {

	real scalar 			mm
	real scalar 			nn
	real scalar 			ii
	
	real matrix 			sigma_temp
	real vector 			inv_B0_mm
	
	transmorphic scalar 	psi
	transmorphic scalar 	mspe
	transmorphic scalar 	mspe_j
	transmorphic scalar 	fevd
	transmorphic scalar 	fecd
	real matrix 			stderr
	
	// initialize associative arrays to simulate 3D matrices
	psi 		= asarray_create("real")
	mspe 		= asarray_create("real")
	mspe_j 		= asarray_create("real")
	fecd 		= asarray_create("real")
	fevd 		= asarray_create("real")
	stderr 		= J(opt.nsteps,v.nvar,.)
	
	// populate associative arrays w/ null values
	for (ii=1; ii<=opt.nsteps; ii++) {
		asarray(psi,ii,J(v.nvar,v.nvar,.))
		asarray(mspe,ii,J(v.nvar,v.nvar,.))
		asarray(mspe_j,ii,J(v.nvar,v.nvar,.))
	}
	for (ii=1; ii<=v.nvar; ii++) {
		asarray(fevd,ii,J(opt.nsteps,v.nvar,.))
	}
	
	// compute multipliers
	sigma_temp = v.sigma
	v.sigma = I(v.nvar)
	for (mm=1; mm<=v.nvar; mm++) {
		for (nn=1; nn<=opt.nsteps; nn++) {
			(asarray(psi,nn))[.,mm] = ((asarray(irf_funct(v,opt),mm))')[.,nn]
		}
	}
	v.sigma = sigma_temp
	
	// calculate total mean squared error
	asarray(mspe,1,v.sigma)
	for (mm=2; mm<=opt.nsteps; mm++) {
		asarray(mspe,mm,((asarray(mspe,mm-1)) + (asarray(psi,mm))*v.sigma*((asarray(psi,mm))')))
	}
	
	// get matrix inv_B0 containing structural impulses
	identify(v,opt)
	
	// calculate contribution of each shock
	for (mm=1; mm<=v.nvar; mm++) {
		
		// get columns of inv_B0 corresponding to the (mm)th shock
		inv_B0_mm = v.inv_B0[.,mm]
		
		// compute mean squared error
		asarray(mspe_j,1,inv_B0_mm*(inv_B0_mm'))
		for (nn=2; nn<=opt.nsteps; nn++) {
			asarray(mspe_j,nn,(asarray(mspe_j,nn-1))+(asarray(psi,nn))*(inv_B0_mm*(inv_B0_mm'))*((asarray(psi,nn))'))
		}
		
		// compute the forecast error covariance decomposition
		for (nn=1; nn<=opt.nsteps; nn++) {
			asarray(fecd,nn,((asarray(mspe_j,nn)):/(asarray(mspe,nn))))
		}
		
		// select only the variance terms
		for (nn=1; nn<=opt.nsteps; nn++) {
			for (ii=1; ii<=v.nvar; ii++) {
				(asarray(fevd,ii))[nn,mm] = (asarray(fecd,nn))[ii,ii]
				stderr[nn,.] = sqrt((diagonal(asarray(mspe,nn)))')
			}
		}
	
	}
	
	return(fevd)
}

transmorphic scalar function fevd_bands_funct(struct var_struct scalar v,
											 struct opt_struct scalar opt) {
	
	real matrix 			y_artfcl
	transmorphic scalar 	fevd_dr
	transmorphic scalar 	fevd_dr_i
	
	real scalar 			mm
	real scalar 			nn
	real scalar 			ii
	real scalar 			rr
	real vector 			u
	real vector 			T
	real matrix 			LAG
	real vector 			LAGpl1
	real vector 			LAGpl2
	
	real scalar 			pctg_inf
	real scalar 			pctg_sup
	
	struct fevd_bands_struct scalar 	fevdb
	struct var_struct scalar 			v_draw
	
	fevdb.INF = asarray_create("real")
	fevdb.SUP = asarray_create("real")
	fevdb.MED = asarray_create("real")
	fevdb.BAR = asarray_create("real")
	
	for (mm=1; mm<=v.nvar; mm++) {
		asarray(fevdb.INF,mm,J(opt.nsteps,v.nvar,.))
		asarray(fevdb.SUP,mm,J(opt.nsteps,v.nvar,.))
		asarray(fevdb.MED,mm,J(opt.nsteps,v.nvar,.))
		asarray(fevdb.BAR,mm,J(opt.nsteps,v.nvar,.))
	}
	
	y_artfcl = J((v.nobs-max((v.nlag,v.nlag_ex)))+v.nlag,v.nvar,0)
	
	fevd_dr = asarray_create("real")
	
	mm = 1
	
	while (mm<=opt.ndraws) {
	
		// generate residuals using bootstrap or wild bootstrap method
		if (opt.method=="bs") {
			u = v.U[ceil(rows(v.U)*runiform((v.nobs-max((v.nlag,v.nlag_ex))),1)),.]
		}
		else if (opt.method=="wild") {
			rr = 1:-2*(runiform((v.nobs-max((v.nlag,v.nlag_ex))),1):>0.5)
			u = v.U:*(rr*J(1,v.nvar,1))
		}
		else error("The opt.method specified is unavailable")
		
		// generate initial values for artificial data
		LAG = J(1,0,.)
		for (nn=1;nn<=v.nlag;nn++) {
			y_artfcl[nn,.] = v.data[nn,.]
			LAG = (y_artfcl[nn,.], LAG)
		}
		T = (1::(v.nobs-max((v.nlag,v.nlag_ex))))
		if (v.cconst==0) LAGpl1 = LAG
		else if (v.cconst==1) LAGpl1 = (1, LAG)
		else if (v.cconst==2) LAGpl1 = (1, T[1], LAG)
		else if (v.cconst==3) LAGpl1 = (1, T[1], T[1]:^2, LAG)
		;
		if (v.nvar_ex!=0) LAGpl1 = (LAGpl1, v.X_EX[1,.])
		;
		
		// generate artificial series
		LAGpl2 = LAGpl1
		for (nn=v.nlag+1;nn<=(v.nobs-max((v.nlag,v.nlag_ex)))+v.nlag;nn++) {
			for (ii=1;ii<=v.nvar;ii++) {
				y_artfcl[nn,ii] = LAGpl2*v.A[.,ii]:+u[nn-v.nlag,ii]			
			}
			if (nn<(v.nobs-max((v.nlag,v.nlag_ex)))+v.nlag) {
				LAG = (y_artfcl[nn,.], LAG[| 1,1 \ 1,(v.nlag-1)*v.nvar |])
				if (v.cconst==0) LAGpl2 = LAG
				else if (v.cconst==1) LAGpl2 = (1, LAG)
				else if (v.cconst==2) LAGpl2 = (1, T[nn-v.nlag+1], LAG)
				else if (v.cconst==3) LAGpl2 = (1, T[nn-v.nlag+1], T[nn-v.nlag+1]:^2, LAG)
				;
				if (v.nvar_ex!=0) LAGpl2 = (LAGpl2, v.X_EX[nn-v.nlag+1,.])
			}
		}
		
		// get max eigenvalue from VAR on artificial data
		v_draw = var_simulation(v,y_artfcl)
		
		// calculate "ndraws" FEVD and store them
		if (v_draw.maxEig<0.9999) {
			asarray(fevd_dr,mm,fevd_funct(v_draw,opt))
			mm = mm+1
		}
	}
	
	// compute error bands
	pctg_inf = (100-opt.pctg)/2
	pctg_sup = 100 - (100-opt.pctg)/2
	
	fevdb.INF = prctile_or_mean(fevd_dr,pctg_inf,"percentile")
	fevdb.SUP = prctile_or_mean(fevd_dr,pctg_sup,"percentile")
	fevdb.MED = prctile_or_mean(fevd_dr,50,"percentile")
	fevdb.BAR = prctile_or_mean(fevd_dr,.,"mean")
	
	return(fevdb)
}

void fevd_plot(transmorphic scalar fevd, struct fevd_bands_struct scalar fevdb,
			   struct var_struct scalar v, struct opt_struct scalar opt) {

	real scalar 	nsteps
	real scalar 	nvars
	
	string scalar 	plt_fevd
	string scalar 	plt_inf
	string scalar 	plt_sup
	string scalar 	plt_list
	string scalar 	cmbn_cmd
	string scalar 	lbl1
	string scalar 	lbl2
	
	string scalar 	plt_cmd
	string scalar 	xpt_cmd
	string scalar 	drp_cmd

	real scalar 	nn
	real scalar 	pp
	real vector 	nstep_mat
	real vector 	lbl_vect
	
	nsteps = rows(asarray(fevd,1))
	nvars = cols(asarray(fevd,1))
	
	nstep_mat = (1::nsteps)
	
	// plot all FEVDs
	if (opt.shck_plt=="all") {
		for (nn=1; nn<=nvars; nn++) {
			st_matrix("fevd_mat_temp",(nstep_mat,(asarray(fevd,nn))))
			st_matrix("inf_mat_temp",(asarray(fevdb.INF,nn)))
			st_matrix("sup_mat_temp",(asarray(fevdb.SUP,nn)))
			stata("svmat fevd_mat_temp")
			stata("svmat inf_mat_temp")
			stata("svmat sup_mat_temp")
			
			plt_fevd = ""
			plt_inf = ""
			plt_sup = ""
			
			for (pp=1; pp<=nvars; pp++) {
				plt_fevd = "(line fevd_mat_temp" + strofreal(pp+1) + " fevd_mat_temp1, lcolor(dknavy)) "
				plt_inf = "(line inf_mat_temp" + strofreal(pp) + " fevd_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
				plt_sup = "(line sup_mat_temp" + strofreal(pp) + " fevd_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
				plt_list = plt_fevd + plt_inf + plt_sup
				
				if (v.shck_nms!=J(1,0,"")) {
					lbl1 = v.shck_nms[pp]
				}
				else {
					lbl1 = v.plt_lbls[pp]
				}
				lbl2 = v.plt_lbls[nn]
				
				plt_cmd = "graph twoway " + plt_list + ", name(fevd_" + strofreal(pp) + ") legend(off) title(" + lbl2 + " to " + lbl1
				plt_cmd = plt_cmd + `") xtitle("")"'
				drp_cmd = "drop fevd_mat_temp" + strofreal(pp+1) + " inf_mat_temp" + strofreal(pp) + " sup_mat_temp" + strofreal(pp)
				
				stata(plt_cmd)
				stata(drp_cmd)
			}
			stata("drop fevd_mat_temp1")
			
			cmbn_cmd = "graph combine "
			for (pp=1; pp<=nvars; pp++) {
				cmbn_cmd = cmbn_cmd + "fevd_" + strofreal(pp) + " "
			}
			cmbn_cmd = cmbn_cmd + ", name(FEVD_" + lbl2 + ")"
			stata(cmbn_cmd)
			
			drp_cmd = "graph drop "
			for (pp=1; pp<=nvars; pp++) {
				drp_cmd = drp_cmd + " fevd_" + strofreal(pp)
			}
			stata(drp_cmd)
			
			if (opt.save_fmt=="gph") xpt_cmd = "graph save FEVD_" + lbl2
			else if (opt.save_fmt=="none") {
				// no save
			}
			else xpt_cmd = "graph export FEVD_" + lbl2 + "." + opt.save_fmt
			stata(xpt_cmd)
		}
	}
	
	// plot only specified FEVDs
	else {
		lbl_vect = (v.plt_lbls:==opt.shck_plt)
		nn = lbl_vect*(1::length(lbl_vect))
		if (nn==0) _error("invalid shock/variable name")
		lbl2 = v.plt_lbls[nn]
	
		st_matrix("fevd_mat_temp",(nstep_mat,(asarray(fevd,nn))))
		st_matrix("inf_mat_temp",(asarray(fevdb.INF,nn)))
		st_matrix("sup_mat_temp",(asarray(fevdb.SUP,nn)))
		stata("svmat fevd_mat_temp")
		stata("svmat inf_mat_temp")
		stata("svmat sup_mat_temp")
		
		plt_fevd = ""
		plt_inf = ""
		plt_sup = ""
		
		for (pp=1; pp<=nvars; pp++) {
			plt_fevd = "(line fevd_mat_temp" + strofreal(pp+1) + " fevd_mat_temp1, lcolor(dknavy)) "
			plt_inf = "(line inf_mat_temp" + strofreal(pp) + " fevd_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
			plt_sup = "(line sup_mat_temp" + strofreal(pp) + " fevd_mat_temp1, lpattern(shortdash) lcolor(ltblue)) "
			plt_list = plt_fevd + plt_inf + plt_sup
			
			if (v.shck_nms!=J(1,0,"")) {
				lbl1 = v.shck_nms[pp]
			}
			else {
				lbl1 = v.plt_lbls[pp]
			}
			
			plt_cmd = "graph twoway " + plt_list + ", name(fevd_" + strofreal(pp) + ") legend(off) title(" + lbl2 + " to " + lbl1
			plt_cmd = plt_cmd + `") xtitle("")"'
			drp_cmd = "drop fevd_mat_temp" + strofreal(pp+1) + " inf_mat_temp" + strofreal(pp) + " sup_mat_temp" + strofreal(pp)
			
			stata(plt_cmd)
			stata(drp_cmd)
		}
		stata("drop fevd_mat_temp1")
		
		cmbn_cmd = "graph combine "
		for (pp=1; pp<=nvars; pp++) {
			cmbn_cmd = cmbn_cmd + "fevd_" + strofreal(pp) + " "
		}
		cmbn_cmd = cmbn_cmd + ", name(FEVD_" + lbl2 + ")"
		stata(cmbn_cmd)
		
		drp_cmd = "graph drop "
		for (pp=1; pp<=nvars; pp++) {
			drp_cmd = drp_cmd + " fevd_" + strofreal(pp)
		}
		stata(drp_cmd)
		
		if (opt.save_fmt=="gph") xpt_cmd = "graph save FEVD_" + lbl2
		else if (opt.save_fmt=="none") {
			// no save
		}
		else xpt_cmd = "graph export FEVD_" + lbl2 + "." + opt.save_fmt
		stata(xpt_cmd)
	}
}

transmorphic scalar function hd_funct(struct var_struct scalar v, struct opt_struct scalar opt) {

	real scalar 	ii
	real scalar 	jj
	real scalar 	hd_r
	real scalar 	hd_c
	real scalar 	lctn

	transmorphic scalar 	shock
	transmorphic scalar 	shock_b
	real matrix 			shock_sum
	real matrix 			init
	real matrix 			init_b
	real matrix 			cconst
	real matrix 			cconst_b
	real matrix 			ltrend
	real matrix 			ltrend_b
	real matrix 			qtrend
	real matrix 			qtrend_b
	real matrix 			exo
	real matrix 			exo_b
	real matrix 			endo
	
	real vector 	CC
	real vector 	TT
	real vector 	TTsq
	
	real matrix 	eps
	real matrix 	eps_b
	real matrix 	inv_B0_b
	real matrix 	I_comp
	real matrix 	EXO
	real matrix 	shock_mat
	
	transmorphic scalar 	shock_holder
	transmorphic scalar 	hdo

	if (v.inv_B0==J(0,0,.)) identify(v,opt)
	
	// get structural shocks
	eps = lusolve(v.inv_B0,(v.U)')
	
	// some preliminaries
	inv_B0_b = J(v.ncoeff,v.nvar,0)
	inv_B0_b[| 1,1 \ v.nvar,. |] = v.inv_B0
	I_comp = (I(v.nvar), J(v.nvar,(v.nlag-1)*v.nvar,0))
	
	// Contribution of each shock
	shock_b = asarray_create("real")
	for (ii=1; ii<=v.nvar; ii++) {
		asarray(shock_b, ii, J(v.nlag*v.nvar,v.nobs-v.nlag+1,0))
	}
	shock = asarray_create("real")
	for (ii=1; ii<=v.nvar; ii++) {
		asarray(shock, ii, J(v.nvar,v.nobs-v.nlag+1,0))
	}
	for (jj=1; jj<=v.nvar; jj++) {
		eps_b = J(v.nvar,v.nobs-v.nlag+1,0)
		eps_b[| jj,2 \ jj,. |] = eps[jj,.]
		for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
			(asarray(shock_b,jj))[.,ii] = inv_B0_b*eps_b[.,ii]+v.A_comp*(asarray(shock_b,jj))[.,ii-1]
			(asarray(shock,jj))[.,ii] = I_comp*(asarray(shock_b,jj))[.,ii]
		}
	}
	// store in associative array (will be nested into hdo)
	shock_holder = asarray_create("real")
	for (ii=1; ii<=v.nvar; ii++) {
		asarray(shock_holder,ii,J(v.nobs,0,.))
		for (jj=1; jj<=v.nvar; jj++) {
			shock_mat = ((J(v.nlag,1,.))\((asarray(shock,jj))[| ii,2 \ ii,. |]'))
			asarray(shock_holder,ii,((asarray(shock_holder,ii)),shock_mat))  
		}
	}
	
	// Initial value
	init_b = J(v.nlag*v.nvar,v.nobs-v.nlag+1,0)
	init = J(v.nvar,v.nobs-v.nlag+1,0)
	init_b[.,1] = (v.X[| 1,1+v.cconst \ .,v.ncoeff+v.cconst |])[1,.]'
	init[.,1] = I_comp*init_b[.,1]
	for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
		init_b[.,ii] = v.A_comp*init_b[.,ii-1]
		init[.,ii] = I_comp*init_b[.,ii]
	}

	// Constant
	cconst_b = J(v.nlag*v.nvar,v.nobs-v.nlag+1,0)
	cconst = J(v.nvar,v.nobs-v.nlag+1,0)
	CC = J(v.nlag*v.nvar,1,0)
	if (v.cconst>0) {
		CC[1::v.nvar] = (v.A')[.,1]
		for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
			cconst_b[.,ii] = CC+v.A_comp*cconst_b[.,ii-1]
			cconst[.,ii] = I_comp*cconst_b[.,ii]
		}
	}

	// Trend
	ltrend_b = J(v.nlag*v.nvar,v.nobs-v.nlag+1,0)
	ltrend = J(v.nvar,v.nobs-v.nlag+1,0)
	TT = J(v.nlag*v.nvar,1,0)
	if (v.cconst>1) {
		TT[1::v.nvar] = (v.A')[.,2]
		for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
			ltrend_b[.,ii] = TT*(ii-1)+v.A_comp*ltrend_b[.,ii-1]
			ltrend[.,ii] = I_comp*ltrend_b[.,ii]
		}
	}

	// Trend squared
	qtrend_b = J(v.nlag*v.nvar,v.nobs-v.nlag+1,0)
	qtrend = J(v.nvar,v.nobs-v.nlag+1,0)
	TTsq = J(v.nlag*v.nvar,1,0)
	if (v.cconst>2) {
		TTsq[1::v.nvar] = (v.A')[.,3]
		for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
			qtrend_b[.,ii] = TTsq*((ii-1)^2)+v.A_comp*qtrend_b[.,ii-1]
			qtrend[.,ii] = I_comp*qtrend_b[.,ii]
		}
	}

	// Exogenous variables
	exo_b = J(v.nlag*v.nvar,v.nobs-v.nlag+1,0)
	exo = J(v.nvar,v.nobs-v.nlag+1,0)
	EXO = J(v.nlag*v.nvar,cols(v.X_EX),0)
	if (v.nvar_ex>0) {
		EXO[(1 :: v.nvar),.] = (v.A')[| 1,v.nvar*v.nlag+v.cconst+1 \ .,. |]
		for (ii=2; ii<=v.nobs-v.nlag+1; ii++) {
			exo_b[.,ii] = EXO*(v.X_EX[ii-1,.])'+v.A_comp*exo_b[.,ii-1]
			exo[.,ii] = I_comp*exo_b[.,ii]
		}
	}
	
	// Sum of shocks
	hd_r = rows(asarray(shock,1))
	hd_c = cols(asarray(shock,1))
	shock_sum = J(hd_r,hd_c,0)
	for (lctn=asarray_first(shock); lctn!=NULL; lctn=asarray_next(shock, lctn)) {
		shock_sum = shock_sum + (asarray_contents(shock, lctn))
	}	
	
	// Sum of all decompositions (=original data)
	endo = init + cconst + ltrend + qtrend + exo + shock_sum
	
	// Store	
	hdo = asarray_create()
	asarray(hdo,"shock",shock_holder)
	asarray(hdo,"init",(J(v.nlag-1,v.nvar,.)\(init[.,.]')))
	asarray(hdo,"cconst",(J(v.nlag,v.nvar,.)\cconst[| 1,2 \ .,. |]'))
	asarray(hdo,"ltrend",(J(v.nlag,v.nvar,.)\ltrend[| 1,2 \ .,. |]'))
	asarray(hdo,"qtrend",(J(v.nlag,v.nvar,.)\qtrend[| 1,2 \ .,. |]'))
	asarray(hdo,"exo",(J(v.nlag,v.nvar,.)\exo[| 1,2 \ .,. |]'))
	asarray(hdo,"endo",(J(v.nlag,v.nvar,.)\endo[| 1,2 \ .,. |]'))
	
	return(hdo)
}

void hd_plot(transmorphic scalar hd, struct var_struct scalar v, struct opt_struct scalar opt) {

	real scalar 	nsteps
	real scalar 	nvars
	real scalar 	tick
	real scalar 	mm
	real scalar 	tt
	real scalar 	nn
	real scalar 	pp
	string scalar 	rlbl_list
	string scalar 	rlbl_lgd
	string scalar 	title
	string scalar 	plt_list
	string scalar 	ost_cmd
	string scalar 	plt_cmd
	string scalar 	xpt_cmd
	string scalar 	drp_cmd
	real vector 	lbl_vect

	nsteps = rows(asarray(asarray(hd,"shock"),1))
	nvars = cols(asarray(asarray(hd,"shock"),1))
	
	// display 7 date labels: first, last, 5 between
	// create string to be used as stata command
	rlbl_list = ""
	tick = floor(nsteps/6)
	for (mm=0; mm<=5; mm++) {
		for (tt=2; tt<=tick; tt++) {
			rlbl_list = rlbl_list + strofreal(tt+(mm*tick)) + `" " " "'
		}
	}
	for (mm=(tick*6)+1; mm<=nsteps-1; mm++) {
		rlbl_list = rlbl_list + strofreal(mm) + `" " " "'
	}
	
	// relabel legend w/ var names or shock names (sign rstrctns)
	rlbl_lgd = "legend("
	if (v.shck_nms!=J(1,0,"")) {
		for (nn=1; nn<=length(v.shck_nms); nn++) {
			rlbl_lgd = rlbl_lgd + "label(" + strofreal(nn) + `" ""' + v.shck_nms[nn] + `"") "'
		}
	}
	else {
		for (nn=1; nn<=nvars; nn++) {
			rlbl_lgd = rlbl_lgd + "label(" + strofreal(nn) + `" ""' + v.plt_lbls[nn] + `"") "'
		}
	}
	rlbl_lgd = rlbl_lgd + ")"
	
	// plot all HDs
	if (opt.shck_plt=="all") {
		for (nn=1; nn<=nvars; nn++) {
			// pass data to Stata as matrix, create new vars from matrices
			st_matrix("hdmat_temp",(asarray(asarray(hd,"shock"),nn)))
			stata("svmat hdmat_temp")
			
			// list of varnames to graph
			plt_list = ""
			for (pp=1; pp<=nvars; pp++) {
				plt_list = plt_list + "hdmat_temp" + strofreal(pp) + " "
			}
			
			// create string variable of time series vars using their preset display format
			ost_cmd = "qui gen OVERSET = string(" + v.tsrs_var + `", ""' + v.tsrs_dlt + `"")"'
			stata(ost_cmd)
			
			// graph title
			title = "title(" + v.plt_lbls[nn] + ") "
			
			// plot
			plt_cmd = "graph bar (asis) " + plt_list + ", over(OVERSET, relabel(" + rlbl_list + /*
					  */ ")) name(HD_" + v.plt_lbls[nn] + ") stack scheme(s1color) " + title + rlbl_lgd
			stata(plt_cmd)
			 
			// save as opt.save_fmt
			if (opt.save_fmt=="gph") xpt_cmd = "graph save HD_" + v.plt_lbls[nn]
			else if (opt.save_fmt=="none") {
				// no save
			}
			else xpt_cmd = "graph export HD_" + v.plt_lbls[nn] + "." + opt.save_fmt
			stata(xpt_cmd)
			
			// drop generated variables
			drp_cmd = "drop OVERSET " + plt_list
			stata(drp_cmd)
		}
	}
	
	// plot only specified HDs
	else {
		lbl_vect = (v.plt_lbls:==opt.shck_plt)
		nn = lbl_vect*(1::length(lbl_vect))
		if (nn==0) _error("invalid shock/variable name")
	
		// pass data to Stata as matrix, create new vars from matrices
		st_matrix("hdmat_temp",(asarray(asarray(hd,"shock"),nn)))
		stata("svmat hdmat_temp")
		
		// list of varnames to graph
		plt_list = ""
		for (pp=1; pp<=nvars; pp++) {
			plt_list = plt_list + "hdmat_temp" + strofreal(pp) + " "
		}
		
		// create string variable of time series vars using their preset display format
		ost_cmd = "qui gen OVERSET = string(" + v.tsrs_var + `", ""' + v.tsrs_dlt + `"")"'
		stata(ost_cmd)
		
		// graph title
		title = "title(" + v.plt_lbls[nn] + ") "
		
		// plot
		plt_cmd = "graph bar (asis) " + plt_list + ", over(OVERSET, relabel(" + rlbl_list + /*
				  */ ")) name(HD_" + v.plt_lbls[nn] + ") stack scheme(s1color) " + title + rlbl_lgd
		stata(plt_cmd)
		
		// save as opt.save_fmt
		if (opt.save_fmt=="gph") xpt_cmd = "graph save HD_" + v.plt_lbls[nn]
		else if (opt.save_fmt=="none") {
			// no save
		}
		else xpt_cmd = "graph export HD_" + v.plt_lbls[nn] + "." + opt.save_fmt
		stata(xpt_cmd)
		
		// drop generated variables
		drp_cmd = "drop OVERSET " + plt_list
		stata(drp_cmd)
	}
}

transmorphic scalar function sign_restrict(struct var_struct scalar v, transmorphic scalar S, struct opt_struct scalar opt) {	

	real scalar 	ss
	real scalar 	jj
	real scalar 	kk
	real scalar 	nsteps_check
	real scalar 	nsteps_init
	real scalar 	updt_cntr
	
	string scalar 	err_display
	string scalar 	updt_disp
	string scalar 	sr_disp
	string scalar 	tot_disp
	
	real matrix 	Q
	real matrix 	checkall
	real matrix 	checkall_flip
	
	real vector 	nsteps_check_vec
	real vector 	sr_check_vec
	
	transmorphic scalar check_mat
	
	struct var_struct scalar v_draw
	transmorphic scalar irf_draw
	
	transmorphic scalar sro

	// Make sure S is loaded in
	if (asarray_elements(S)==0) {
		_error("Must input one or more shock matrices")
	}
	
	// Get preliminary scalar values
	nsteps_check_vec = J(1,0,.)
	for (ss=1; ss<=v.nvar; ss++) {
		nsteps_check_vec = (nsteps_check_vec, (asarray(S,ss)[.,2])')
	}
	nsteps_check = max(nsteps_check_vec)
	nsteps_init = opt.nsteps
	updt_cntr = opt.updt_frqcy
	
	// Store credible sets: stores v_draw structures
	sro = asarray_create("real")
	
	jj = 0	// accepted draws
	kk = 0 	// total draws
	
	while (jj<opt.ndraws) {
	
		// Abort if attempts exceed preset limit
		if (jj==0 & kk>opt.err_lmt) {
			err_display = strofreal(kk-1) + " iterations attempted without success. Try different sign restrictions."
			_error(err_display)
		}
		
		// Draw A and sigma from the posterior for VAR draw and assign Q to v_draw
		v_draw = posterior_draw(v)
		opt.ident = "sr"
		opt.nsteps = nsteps_check
		
		// Draw a random orthonormal matrix Q (from qr(random X))
		Q = orth_norm(v.nvar)
		v_draw.Q = Q
		
		// Compute IRFs only for the restricted periods
		// Check whether sign restrictions are satisfied
		v_draw.inv_B0 = J(0,0,.)
		irf_draw = irf_funct(v_draw,opt)
		check_mat = check_mat(irf_draw,S)
		checkall = asarray(check_mat,"checkall") 
		checkall_flip = asarray(check_mat,"checkall_flip")
		
		// if restrictions are satisfied, save draw
		opt.nsteps = nsteps_init
		if ((min(checkall)==1) | (min(checkall_flip)==1)) {
			jj = jj + 1
			// restrictions all satisfied
			if (min(checkall)==1) {
				asarray(sro,jj,v_draw)
			}
			// signs are all backwards; multiply Q by (-1)
			else if (min(checkall_flip)==1) {
				v_draw.Q = (v_draw.Q)*(-1)
				asarray(sro,jj,v_draw)
			}
		}
		// else, check if all signs are backwards for particular sign(s)
		else {
			sr_check_vec = J(1,v_draw.nvar,.)
			for (ss=1; ss<=v_draw.nvar; ss++) {
				sr_check_vec[ss] = min(checkall[.,ss])+min(checkall_flip[.,ss])
			}
			// flip sign on row of Q corresponding to shock(s) with flipped signs
			if ((min(sr_check_vec)==1) & (max(sr_check_vec)==1)) {
				jj = jj + 1
				for (ss=1; ss<=v_draw.nvar; ss++) {
					if (min(checkall_flip[.,ss])==1) {
						Q = v_draw.Q
						Q[ss,.] = (v_draw.Q)[ss,.]*(-1)
						v_draw.Q = Q
					}
				}
				asarray(sro,jj,v_draw)
			}
		}
		// if Q cannot be rectified, discard draw
		kk = kk + 1
		
		// update loop progress periodically if update setting is switched on
		if (opt.updt=="yes") {
			if (kk == updt_cntr) {
				updt_disp="Loop: "+strofreal(jj)+" SR satisfied / "+strofreal(kk)+" total draws"
				display(updt_disp)
				updt_cntr = updt_cntr + opt.updt_frqcy
			}
		}
	}
	
	// assign shock names to VAR struct (for plotting)
	v.shck_nms = asarray(S,0)
	
	// display number of loops, number of draws
	sr_disp = strofreal(jj) + " draws satisfied sign restrictions."
	tot_disp = strofreal(kk) + " total draws attempted."
	display("Success.")
	display(sr_disp)
	display(tot_disp)
	
	return(sro)
}

transmorphic scalar function narr_sign_restrict(struct var_struct scalar v, transmorphic scalar S, struct opt_struct scalar opt, transmorphic scalar nsr) {	

	real scalar 	ss
	real scalar 	jj
	real scalar 	kk
	real scalar 	ll
	real scalar 	nsteps_check
	real scalar 	nsteps_init
	real scalar 	updt_cntr
	real scalar 	sr_check
	
	string scalar 	err_display
	string scalar 	updt_disp
	string scalar 	nsr_disp
	string scalar 	sr_disp
	string scalar 	tot_disp
	
	real matrix 	checkall
	real matrix 	checkall_flip
	real matrix 	checkall_nsr
	real matrix 	Q
	
	real vector 	nsteps_check_vec
	real vector 	sr_check_vec
	
	transmorphic scalar check_mat
	
	struct var_struct scalar v_draw 
	transmorphic scalar irf_draw
	
	transmorphic scalar sro
	
	
	// Preliminary checks
	if (asarray_elements(S)==0) {
		_error("Must input one or more shock matrices")
	}
	
	// Get preliminary scalar values
	nsteps_check_vec = J(1,0,.)
	for (ss=1; ss<=v.nvar; ss++) {
		nsteps_check_vec = (nsteps_check_vec, (asarray(S,ss)[.,2])')
	}
	nsteps_check = max(nsteps_check_vec)
	nsteps_init = opt.nsteps
	updt_cntr = opt.updt_frqcy
	
	// Store credible sets: stores v_draw structures
	sro = asarray_create("real")
	
	ll = 0  // draws satisfying sign AND narrative sign restrictions
	jj = 0	// draws satisfying sign restrictions
	kk = 0 	// total draws
	
	// Initialize loop
	while (ll<opt.ndraws) {
	
		// Abort if attempts exceed preset limit
		if (jj==0 & kk>opt.err_lmt) {
			err_display = strofreal(opt.err_lmt)+" iterations attempted without " + /*
					   */ "success. Try different restrictions or up max attempts."
			_error(err_display)
		};
		
		// Draw A and sigma from the posterior for VAR draw and assign Q to v_draw
		v_draw = posterior_draw(v)
		opt.ident = "sr"
		opt.nsteps = nsteps_check
		
		// Draw a random orthonormal matrix Q  (from qr(random X))
		v_draw.Q = orth_norm(v.nvar)
		
		// Compute IRFs only for the restricted periods
		// Check whether sign restrictions are satisfied
		v_draw.inv_B0 = J(0,0,.)
		irf_draw = irf_funct(v_draw,opt)
		check_mat = check_mat(irf_draw,S)
		checkall = asarray(check_mat,"checkall") 
		checkall_flip = asarray(check_mat,"checkall_flip")
		
		// if sign restrictions are satisfied, check narrative restrictions
		sr_check = 0
		if ((min(checkall)==1) | (min(checkall_flip)==1)) {
			jj = jj + 1
			// restrictions all satisfied
			if (min(checkall)==1) {
				sr_check=1
			}
			// signs are all backwards; multiply Q by (-1)
			else if (min(checkall_flip)==1) {
				v_draw.Q = (v_draw.Q)*(-1)
				sr_check=1
			}
		}
		else {
			sr_check_vec = J(1,v_draw.nvar,.)
			for (ss=1; ss<=v_draw.nvar; ss++) {
				sr_check_vec[ss] = min(checkall[.,ss])+min(checkall_flip[.,ss])
			}
			// flip sign on row of Q corresponding to shock(s) with flipped signs
			if ((min(sr_check_vec)==1) & (max(sr_check_vec)==1)) {
				jj = jj + 1
				for (ss=1; ss<=v_draw.nvar; ss++) {
					if (min(checkall_flip[.,ss])==1) {
						Q = v_draw.Q
						Q[ss,.] = (v_draw.Q)[ss,.]*(-1)
						v_draw.Q = Q
					}
				}
				sr_check=1
			}
		}
		if (sr_check==1) {
			checkall_nsr = check_nsr(v_draw,nsr,S,opt)
			// if narr restrictions also satisfied, save outputs; else throw out
			if (min(checkall_nsr)==1) {
				opt.nsteps = nsteps_init
				ll = ll + 1
				asarray(sro,ll,v_draw)
			}
		}
		kk = kk + 1
		
		// update loop progress periodically if update setting is switched on
		if (opt.updt=="yes") {
			if (kk == updt_cntr) {
				updt_disp="Loop: "+strofreal(ll)+" NSR+SR satisfied / "+strofreal(jj)+ /*
					   */ " SR satisfied / "+strofreal(kk)+" total draws"
				display(updt_disp)
				updt_cntr = updt_cntr + opt.updt_frqcy
			}
		}

	}
	
	
	// assign shock names to VAR struct (for plotting)
	v.shck_nms = asarray(S,0)
	
	// display number of loops, number of draws
	nsr_disp = strofreal(ll) + " draws satisfied both sign and narrative sign restrictions."
	sr_disp = strofreal(jj) + " draws satisfied sign restrictions."
	tot_disp = strofreal(kk) + " total draws attempted."
	display("Success.")
	display(nsr_disp)
	display(sr_disp)
	display(tot_disp)
	
	return(sro)
}

transmorphic scalar function sr_analysis_funct(string scalar output, transmorphic scalar sro, struct opt_struct scalar opt) {	
	
	real scalar 			nn
	real scalar 			pctg_sup
	real scalar 			pctg_inf
	string scalar 			ident_store
	transmorphic scalar 	sr_set
	transmorphic scalar 	all
	transmorphic scalar 	all_shocks
	transmorphic scalar 	med
	transmorphic scalar 	hdo
	transmorphic scalar 	hdo_med
	
	struct var_struct scalar v_draw
	struct irf_bands_struct scalar irfb
	struct fevd_bands_struct scalar fevdb
	
	// generate associative arrays: 'all' stores all credible sets, 'sr_set' stores 'all', median, and bands
	sr_set = asarray_create()
	all = asarray_create("real")
	all_shocks = asarray_create("real") // to get median of shock decomposition for all HD sets
	hdo_med = asarray_create()
	
	// store opt identification setting, set to sign restrictions
	ident_store = opt.ident
	opt.ident = "sr"
	
	// store all credible outputs in associative array "all"
	for (nn=1; nn<=asarray_elements(sro); nn++) {
		if (output=="irf") {
			v_draw = asarray(sro,nn)
			asarray(all,nn,irf_funct(v_draw,opt))
		}
		else if (output=="fevd") {
			v_draw = asarray(sro,nn)
			asarray(all,nn,fevd_funct(v_draw,opt))
		}
		else if (output=="hd") {
			v_draw = asarray(sro,nn)
			hdo = hd_funct(v_draw,opt)
			asarray(all,nn,hdo)
			asarray(all_shocks,nn,asarray(hdo,"shock"))
		}
	}
	asarray(sr_set,"all",all)
	
	// identify, store median (note: HD ONLY stores median shock decompositions)
	if (output=="irf" | output=="fevd") {
		med = prctile_or_mean(all,50,"percentile")
		asarray(sr_set,"median",med)
	}
	else if (output=="hd") {
		med = prctile_or_mean(all_shocks,50,"percentile")
		asarray(hdo_med,"shock",med)
		asarray(sr_set,"median",hdo_med)
	}
	
	// identify, store upper/lower bands (determined from opt.pctg)
	pctg_sup = 100 - (100-opt.pctg)/2
	pctg_inf = (100-opt.pctg)/2
	if (output=="irf") {
		irfb.SUP = prctile_or_mean(all,pctg_sup,"percentile")
		irfb.INF = prctile_or_mean(all,pctg_inf,"percentile")
		asarray(sr_set,"bands",irfb)
	}
	else if (output=="fevd") {
		fevdb.SUP = prctile_or_mean(all,pctg_sup,"percentile")
		fevdb.INF = prctile_or_mean(all,pctg_inf,"percentile")
		asarray(sr_set,"bands",fevdb)
	}
	
	// restore opt identification setting
	opt.ident = ident_store
	
	return(sr_set)
}

transmorphic scalar function shock_create(struct var_struct scalar v) {
	
	transmorphic scalar 	aa
	real scalar 			ii
	
	// create associate array to store shock matrices
	aa = asarray_create("real")
	
	// for indexing variables
	asarray(aa,-1,v.plt_lbls)
	
	// for storing shock names
	asarray(aa,0,v.plt_lbls)
	
	// generate place-holders (unrestricted)
	for (ii=1; ii<=v.nvar; ii++) {
		asarray(aa,ii,J(v.nvar,3,0))
	}
	
	return(aa)	
}

void function shock_name(string vector names, transmorphic scalar aa) {

	real scalar 	ii

	if (length(names)!=length(asarray(aa,0))) {
		_error("length of name vector must equal number of variables")
	}
	for (ii=1; ii<=length(names); ii++) {
		if (names[ii]=="") {
			names[ii] = asarray(aa,-1)[ii]
		}
	}
	asarray(aa,0,names)
}

void function shock_set(real scalar start_pd, real scalar end_pd, string scalar pos_neg,
									   string scalar var_shock, string scalar var_affected,
									   transmorphic scalar aa) {

		real scalar 	ss
		real scalar 	rr
		real scalar 	sign
		real matrix 	temp_mat

		ss = (var_shock:==asarray(aa,-1))*(1::length(asarray(aa,-1)))
		if (ss==0) ss = (var_shock:==asarray(aa,0))*(1::length(asarray(aa,0)))
		if (ss==0) _error("Shock name not interpretable; should be endog var name or preset shock name")
		
		rr = (var_affected:==asarray(aa,-1))*(1::length(asarray(aa,-1)))
		if (rr==0) _error("Affected variable name not interpretable; should be endog var name")
		
		if (pos_neg=="positive" | pos_neg=="pos" | pos_neg=="+") sign = 1
		else if (pos_neg=="negative" | pos_neg=="neg" | pos_neg=="-") sign = -1
		else _error("Sign is not interpretable; should be 'positive' or 'negative'")
		
		if (start_pd<=0 | start_pd!=round(start_pd)) _error("'start_pd' must be positive integer")
		if (end_pd!=round(end_pd) | end_pd<start_pd) _error("'end_pd' must be positive int equal to or greater than 'start_pd'")
		
		temp_mat = asarray(aa,ss)
		temp_mat[rr,.] = (start_pd,end_pd,sign)
		asarray(aa,ss,temp_mat)
}

transmorphic scalar function nr_create(struct var_struct scalar v) {
	
	transmorphic scalar 	aa
	
	// create associate array to store shock matrices
	aa = asarray_create("real")

	asarray(aa,0,st_data(.,v.tsrs_var))
	
	return(aa)
}

void function nr_set(real scalar start_pd, real scalar end_pd, string scalar nr_type,
					 string scalar var_shock, string scalar var_affected,
					 transmorphic scalar aa) {
					 
	real scalar 	nn
	real vector 	m_pd_f
	real vector 	m_pd_l
	real vector 	ind_vect
	
	nn = asarray_elements(aa)
	
	// generate pointer array
	if (nr_type=="positive" | nr_type=="pos" | nr_type=="+" | /*
	 */ nr_type=="negative" | nr_type=="neg" | nr_type=="-") {
		asarray(aa,nn,J(3,1,NULL))
	}
	else {
		asarray(aa,nn,J(4,1,NULL))
	}
	
	// clean nr_type and verify interpretability
	if (nr_type=="pos" | nr_type=="+") nr_type = "positive"
	else if (nr_type=="neg" | nr_type=="-") nr_type = "negative"
	nr_type = usubinstr(nr_type," ","",.)
	if (nr_type!="positive" & nr_type!="negative" & /*
	 */ nr_type!="mostimportant" & nr_type!="leastimportant" & /*
	 */ nr_type!="overwhelming" & nr_type!="negligible") {
		_error("narrative restriction type is not interpretable")
	 }
	
	if (nr_type!="positive" & nr_type!="negative" & (var_affected=="" | var_affected==".")) {
		_error("must specify affected variable")
	 }
	
	// input (1) narrative restriction type, (2) shock name/var
	((asarray(aa,nn))[1]) = &nr_type
	((asarray(aa,nn))[2]) = &var_shock
	
	// (3) create vector to index periods
	if (start_pd<=0 | start_pd!=round(start_pd)) _error("'start_pd' must be positive integer")
	if (end_pd!=round(end_pd) | end_pd<start_pd) _error("'end_pd' must be positive int equal to or greater than 'start_pd'")
	if (end_pd==start_pd) {
		((asarray(aa,nn))[3]) = &(selectindex(asarray(aa,0):==start_pd))
	}
	else {
		m_pd_f = selectindex(asarray(aa,0):==start_pd)
		m_pd_l = selectindex(asarray(aa,0):==end_pd)
		ind_vect = (m_pd_f::m_pd_l)
		((asarray(aa,nn))[3]) = &(ind_vect)
	}
	
	// if restriction is on historical decomp., (4) input affected var name
	if (nr_type!="positive" & nr_type != "negative") {
		((asarray(aa,nn))[4]) = &var_affected
	}
	
}

void function identify(struct var_struct scalar v, struct opt_struct scalar opt) {

	real matrix 			A_inf_big
	real matrix 			A_inf
	real matrix 			D
	real matrix 			chol_out

	// get matrix inv_B0 containing structural impulses
	if (opt.ident=="oir") {
		v.inv_B0 = cholesky(v.sigma)
	}
	
	else if (opt.ident=="bq") {
		A_inf_big = luinv(I(max((rows(v.A_comp),cols(v.A_comp))))-v.A_comp)
		A_inf = A_inf_big[| 1,1 \ v.nvar,v.nvar |]
		D = cholesky(A_inf*v.sigma*A_inf')
		v.inv_B0 = lusolve(A_inf,D)
	}
	
	else if (opt.ident=="sr") {
		chol_out = cholesky(v.sigma)'
		if (v.Q==J(0,0,.)) _error("Rotation matrix is not provided")
		else v.inv_B0 = (chol_out')*(v.Q')
	}
	
	else _error("identification option is unavailable; select 'oir', 'bq' or 'sr'")

}

real matrix function orth_norm(real scalar nn) {

	real matrix 	X
	real matrix 	Q
	real matrix 	R
	
	real scalar 	ii
	real scalar 	norm_check
	
	X = rnormal(nn,nn,0,1)
	
	Q = J(0,0,.)
	R = J(0,0,.)
	
	qrd(X,Q,R)
	
	// flip column signs of Q to correspond to a normalized
	// R that is POSITIVE upper triangular (pos elements on diag)
	for (ii=1; ii<=nn; ii++) {
		norm_check = (R[ii,ii]>0)
		if (norm_check==0) Q[.,ii] = -1*Q[.,ii]
	}
	
	return(Q)
}

transmorphic scalar function posterior_draw(struct var_struct scalar v) {

	// input empty A and sigma matrices
	// function draws A and sigma from posterior of var
	real matrix 	Btl
	real matrix 	sigma_scaled
	real matrix 	sigma_draw
	real matrix 	V_a_mat
	real vector 	V_a_vect
	real matrix 	A_draw
	real scalar 	nn, kk
	
	struct var_struct scalar v_draw
	
	v_draw = v
	
	// Draw VCV matrix using Bartlett decomposition
	sigma_scaled = v.sigma:/v.nobs
	Btl = diag(sqrt(rchi2(1,1,((v.nobs:-(0::v.nvar-1))'))))
	for (nn=1; nn<=rows(Btl); nn++) {
		for (kk=1; kk<=nn-1; kk++) {
			Btl[nn,kk] = rnormal(1,1,0,1)
		}
	}
	sigma_draw = cholesky(sigma_scaled)*Btl*Btl'*cholesky(sigma_scaled)'
	v_draw.sigma = sigma_draw
	
	// Draw coefficient matrix
	V_a_mat = (v_draw.sigma#invsym((v.X')*v.X))
	V_a_vect = v.A[.,1]
	for (nn=2; nn<=cols(v.A); nn++) {
		V_a_vect = (V_a_vect\v.A[.,nn])
	}
	A_draw = (rnormal(1,rows(V_a_mat),0,1) * V_a_mat + V_a_vect')'
	v_draw.A = rowshape(A_draw',v.nvar)'
	
	// calculate new companion matrix
	v_draw.A_comp = ((v_draw.A')[.,(1+v.cconst :: v.nvar*v.nlag+v.cconst)]\(I(v.nvar*(v.nlag-1)),J(v.nvar*(v.nlag-1),v.nvar,0)))
	
	return(v_draw)
}

transmorphic scalar function check_mat(struct irf_struct scalar irf_draw, transmorphic scalar S) {

	real scalar 		nshocks
	real scalar 		nvar
	real scalar 		ss
	real scalar 		ii
	
	real matrix 		checkall
	real matrix 		check
	real matrix 		checkall_flip
	real matrix 		check_flip
	
	transmorphic scalar check_set
	
	nshocks = asarray_elements(S)-2
	nvar = cols((asarray(irf_draw,1)))
	
	check_set = asarray_create()
	checkall = J(nvar,nshocks,1)
	checkall_flip = J(nvar,nshocks,1)
	
	// checkall matrix is ii x ss where ii==ss
	// element checkall[ii,ss] corresponds to variable ii's response to shock ss
	for (ss=1; ss<=nshocks; ss++) {
		for (ii=1; ii<=nvar; ii++) {
			if (asarray(S,ss)[ii,3]==1) {
				check = ((asarray(irf_draw,ss))[(asarray(S,ss)[ii,1] :: asarray(S,ss)[ii,2]), ii] :> 0)
				checkall[ii,ss] = min(check)
				// check flipped signs
				check_flip = ((asarray(irf_draw,ss))[(asarray(S,ss)[ii,1] :: asarray(S,ss)[ii,2]), ii] :< 0)
				checkall_flip[ii,ss] = min(check_flip)
			}
			else if (asarray(S,ss)[ii,3]==-1) {
				check = ((asarray(irf_draw,ss))[(asarray(S,ss)[ii,1] :: asarray(S,ss)[ii,2]), ii] :< 0)
				checkall[ii,ss] = min(check)
				// check flipped signs
				check_flip = ((asarray(irf_draw,ss))[(asarray(S,ss)[ii,1] :: asarray(S,ss)[ii,2]), ii] :> 0)
				checkall_flip[ii,ss] = min(check_flip)
			}
		}
	}
	
	asarray(check_set,"checkall",checkall)
	asarray(check_set,"checkall_flip",checkall_flip)
	
	return(check_set)
}

real matrix function check_nsr(struct var_struct scalar v, transmorphic scalar nsr,
							   transmorphic scalar S, struct opt_struct scalar opt) {
	
	real scalar 	rr
	real scalar 	ss
	real scalar 	mm
	real scalar 	nn
	real scalar 	tt
	real scalar 	shock_indicator
	real scalar 	hd_indicator
	real scalar 	abs_shck
	
	string scalar 	nr_type
	
	real matrix 	struct_shocks
	real matrix 	hd_shock

	real scalar 	check_nsr
	real matrix 	checkall_nsr
	
	transmorphic scalar hd
	
	// preliminaries
	shock_indicator = 0
	hd_indicator = 0
	rr = 1
	
	// verify narrative restriction(s)
	checkall_nsr = J(asarray_elements(nsr)-1,1,0)
	while (rr<asarray_elements(nsr)) {
		// get information from nsr:
		// (1) restriction type
		// (2) column ## corresponding to structural shock mat or hist. decomp
		nr_type = *((asarray(nsr,rr))[1])
		ss = selectindex( asarray(S,0) :== *(asarray(nsr,rr))[2] )
		
		// check that column var/shock input is interpretable
		if (ss==J(0,1,.)) _error("narr. restr. shock label must match sign restr. shock label for restrictions")
		// Case 1: restrictions on shock matrix
		if ((nr_type=="positive") | (nr_type=="negative")) {
			
			// get (3) row ## range of struct shock mtx to verify
			mm = (*(asarray(nsr,rr))[3] :- v.nlag)
		
			// if first instance of case 1, get structural shock matrix
			if (shock_indicator==0) {
				struct_shocks = lusolve(v.inv_B0,(v.U)')
				shock_indicator = 1
			}
			
			// check narrative restrictions: shock ss is positive or negative during period mm
			if (nr_type=="positive") check_nsr = (sum(struct_shocks[ss,mm]:<=0)==0)
			else if (nr_type=="negative") check_nsr = (sum(struct_shocks[ss,mm]:>=0)==0)
			if (check_nsr==0) rr = asarray_elements(nsr)
			else {
				checkall_nsr[rr] = check_nsr
				rr = rr + 1
			}
		}
		
		// Case 2: restrictions on historical decomposition
		else {
		
			// get (3) row ## range of historical decomposition to verify
			// get (4) variable affected by shock
			mm = (*(asarray(nsr,rr))[3])
			nn = selectindex( v.plt_lbls :== *(asarray(nsr,rr))[4] )
		
			// if first instance of case 2, get historical decomposition
			if (hd_indicator==0) {
				hd = hd_funct(v,opt)
				hd_indicator = 1
			}
			// get historical decomposition of variable nn
			hd_shock = (asarray(asarray(hd,"shock"),nn))

			// get absolute value of shock ss' effect on variable nn during period mm
			abs_shck = (sum(abs(hd_shock[mm,ss])))
			
			// check narr restricts: shock ss is most/least important driver of unexpected change in var nn during period mm
			if ((nr_type=="mostimportant") | (nr_type=="leastimportant")) {
				check_nsr = 1
				for (tt=1; tt<=v.nvar; tt++) {
					if (tt!=ss) {
						if (nr_type=="mostimportant") check_nsr = check_nsr + (abs_shck <= sum(abs(hd_shock[mm,tt])))
						else check_nsr = check_nsr + (abs_shck >= sum(abs(hd_shock[mm,tt])))
					}
				}
				if (check_nsr==1) {
					checkall_nsr[rr] = 1
					rr = rr + 1
				}
				else rr = asarray_elements(nsr)
			}
			
			// check narr restricts: shock is overwhelming/negligible driver of unexpected change in var during period mm
			else if ((nr_type=="overwhelming") | (nr_type=="negligible")) {
				if (nr_type=="overwhelming") check_nsr = (abs_shck > (sum(abs(hd_shock[mm,.])) - abs_shck))
				else check_nsr = (abs_shck < (sum(abs(hd_shock[mm,.])) - abs_shck))
				if (check_nsr==1) {
					checkall_nsr[rr] = check_nsr
					rr = rr + 1
				}
				else rr = asarray_elements(nsr)
			}
		}

	}
	
	return(checkall_nsr)
}

real vector function prctile(real matrix mt, real scalar p) {

	// subfunction used in prctile_or_mean()
	// calculates percentile p of elements in mt

	real scalar 	n_n
	
	real vector 	v_vct
	real scalar 	jj
	real vector 	mt_vct
	real scalar 	n_flr
	real scalar 	n_cl
	real scalar 	v_flr
	real scalar 	v_cl
	real scalar 	p_flr
	real scalar 	p_cl
	real scalar 	n_diff
	real scalar 	p_diff
	
	n_n = rows(mt)
	v_vct = J(1,cols(mt),.)
	
	for (jj=1; jj<=cols(mt); jj++) {
	
		mt_vct 		= mt[.,jj]
		mt_vct 		= sort(mt_vct,1)

		n_flr 		= floor((p*n_n)/100 + 0.5)
		n_cl 		= ceil((p*n_n)/100 + 0.5)
		
		if (n_flr!=n_cl) {
			v_flr 		= mt_vct[n_flr]
			v_cl 		= mt_vct[n_cl]
			
			p_flr 		= 100*(n_flr-.5)/n_n
			p_cl 		= 100*(n_cl-.5)/n_n
			
			n_diff 		= mt_vct[n_cl]-mt_vct[n_flr]
			p_diff 		= (p-p_flr)/(p_cl-p_flr)
			
			v_vct[jj] 	= v_flr+(p_diff*(v_cl-v_flr))
		}
		else {
			v_vct[jj] 	= mt_vct[n_flr]
		}
	}
	
	return(v_vct)

}

transmorphic scalar function prctile_or_mean(transmorphic scalar mat_aa, real scalar p, string scalar prctl_or_mean) {

	// for use with associative arrays containing real matrices
	// prctl_or_mean = "percentile" or "mean"

	real scalar 			nelmt
	real scalar 			nshck
	real scalar 			nrows
	real scalar 			ncols
	real scalar 			ee
	real scalar 			ss
	real scalar 			ii
	real scalar 			jj
	real vector 			bb
	transmorphic matrix 	mat_out
	
	// Calculate PERCENTILE p across matrices
	if (prctl_or_mean=="percentile") {
		nelmt = asarray_elements(mat_aa)
		nshck = asarray_elements(asarray(mat_aa,1))
		
		nrows = rows(asarray((asarray(mat_aa,1)),1))
		ncols = cols(asarray((asarray(mat_aa,1)),1))
		
		mat_out = asarray_create("real")
		
		for (ss=1; ss<=nshck; ss++)	{
			asarray(mat_out,ss,J(nrows,ncols,.))
			for (ii=1; ii<=nrows; ii++) {				
				for (jj=1; jj<=ncols; jj++)	{
					bb = J(nelmt,1,.)
					for (ee=1; ee<=nelmt; ee++) {
						bb[ee] = (asarray((asarray(mat_aa,ee)),ss))[ii,jj]
					}
				(asarray(mat_out,ss))[ii,jj] = prctile(bb,p)
				}
			}
		}
	}
	
	// Calculate MEAN across matrices
	if (prctl_or_mean=="mean") {
		nelmt = asarray_elements(mat_aa)
		nshck = asarray_elements(asarray(mat_aa,1))
		
		nrows = rows(asarray((asarray(mat_aa,1)),1))
		ncols = cols(asarray((asarray(mat_aa,1)),1))
		
		mat_out = asarray_create("real")
		
		for (ss=1; ss<=nshck; ss++)	{
			asarray(mat_out,ss,J(nrows,ncols,.))
			for (ii=1; ii<=nrows; ii++) {				
				for (jj=1; jj<=ncols; jj++)	{
					bb = J(nelmt,1,.)
					for (ee=1; ee<=nelmt; ee++) {
						bb[ee] = (asarray((asarray(mat_aa,ee)),ss))[ii,jj]
					}
				(asarray(mat_out,ss))[ii,jj] = mean(bb)
				}
			}
		}
	}
	
	return(mat_out)
}

mata mlib create lib_var_nr, replace
mata mlib add lib_var_nr *()
mata mlib index
end