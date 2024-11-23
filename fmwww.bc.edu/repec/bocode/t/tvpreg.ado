// Package for Time-Varying-Parameter Regression
// Author: Atsushi Inoue, Barbara Rossi, Yiru Wang, Lingyun Zhou

program define tvpreg, eclass

    version 17.0

	if replay() {
		Replay
	}
	else {
		cap noi Estimate `0'
	}
	
end

program define Estimate, eclass

	loc cmdline tvpreg `0'
	_iv_parse `0'
	
	local y2z1 `s(lhs)' `s(exog)'
	local y1 `s(endog)'
	local z2 `s(inst)'
	local 0 `s(zero)'

	syntax [if] [in] [, 			///
		///* Estimator*///
		ols							/// ordinary least squares; the default when no instruments are specified
		newey						/// newey-west standard error
		2sls						/// two-stage least squares; the default when instruments are specified
		gmm							/// general method of moments
		weakiv						/// weak instrument robust method
		var							/// vector autoregressive model
		///* Model *///
		ny(real 1) 					/// # of LHS variables; default is 1
		varlag(string)				/// number list of lags in the vector autoregression
		q(real 0) 					/// # of time-varying parameters; default is all
		slope						/// only the slope parameters are time-varying; default is not
		NOCONStant 					/// whether constant is included; default is yes
		NHORizon(string) 			/// number of horizons in the local projection; default is 0
		CUMulative					/// whether the dependent and endogeneous variables are cumulated over horizons
		LPLAGged					/// whether the endogeneous variable varies with h
		NWLag(real -1) 				/// # of Newey-West lags; default is T^(-1/3)
		Cmatrix(string) 			/// smooth matrices; default is 0:5:50
		CHOLesky					/// use cholesky decomposition; default is no
		ndraw(real 1000)			/// number of draws using weakiv; default is 1000
		///* Report *///
		GETBand 					/// whether the confidence band is calculated; default is no
		Level(cilevel) 				/// confidence level; default is cilevel
		NODISplay					/// do not display the information
		///* Plot *///
		plotcoef(string) 			/// the position list of parameters to be plotted; default is the first parameter
		plotvarirf(string) 			/// the position list of impulse response function in VAR model to be plotted; default is the first parameter
		PLOTNHORizon(string)		/// the number list of horizons to be plotted; default is the list specified by nhorizon; NOTE: (1) If specifying a number, the parameter path over time is plotted; (2) If specifying a number list, the parameter path over horizons is plotted
		PLOTConst					/// add a horizon line of the constant parameter estimate
		period(varname)				/// indicating the time points to be plotted in the impulse response function
		movavg(real 1)				/// moving average when plotting the weak iv result; default is 1
		noci						/// suppress the confidence band
		TItle(string)				/// figure title
		YTItile(string)				/// title of yaxis
		XTItile(string)				/// title of xaxis
		TVPLegend(string) 			/// legend name of the time-varying-parameter estimates
		CONSTLegend(string) 		/// legend name of the constant-parameter estimates
		BANDLegend(string)			/// legend name of the confidence band
		SHADELegend(string)			/// legend name of the background shade
		PERIODLegend(string)		/// legend name of each period
		nolegend					/// suppress the legend
		SCHeme(string) 				/// graphics scheme to be used 
		TVPColor(string) 			/// line color of the time varying parameter estimate; default is green
		CONSTColor(string)			/// line color of the constant parameter estimate; default is black
		name(string)				/// figure name
	]
	
	loc estimator `ols'`newey'`2sls'`gmm'`weakiv'`var'
	if ("`estimator'" == "") {
		if ("`y1'" == "") {
			if ((`nwlag' == -1) | (`nwlag' == 0)) loc estimator ols
			else if (`nwlag' > 1) loc estimator newey
		}
		else loc estimator 2sls
	}
	else if (!inlist("`estimator'","ols","newey","2sls","gmm","weakiv","var")) {
		di as err "Unknown estimator type."
		exit
	}

	* Preliminary
	cap tsset
	if _rc {
		di as err "time variable not set, use -tsset timevar [, options]"
		exit 101
	}
    loc timevar  "`r(timevar)'"
	marksample touse
	markout `touse' `y2z1' `y1' `z2'
	qui gsort -`touse' `timevar'
	preserve
	qui keep if `touse'
	cap tsset `timevar'
	qui describe
	loc T = r(N)
	if ("`noconstant'" == "") loc cons = 1
	else loc cons = 0
	if ("`getband'" == "") loc getband 0
	else loc getband 1
	if ("`cholesky'" == "") loc chol 0
	else loc chol 1
	if ("`nhorizon'" == "") loc nhorizon = 0

	if ("`cmatrix'" == "") {
		loc cdefault yes
		mata: c = 5 * (0::10)'
		tempname cmatrix
		mata: st_matrix("`cmatrix'", c)
	}
	else mata: c = st_matrix("`cmatrix'")	

	loc minh = `T'
	loc maxh = 0
	foreach hh of numlist `nhorizon' {
		loc Nh = `Nh' + 1
		loc hlist `hlist' `hh'
		loc minh = min(`minh',`hh')
		loc maxh = max(`maxh',`hh')
	}
	if ("`estimator'" == "var") {
		loc nhorizon = 0
		loc Nh = 1
		loc maxhvar = `maxh'
		loc maxh = 0
		loc minh = 0
		if ("`varlag'" == "") loc varlag = 1
		loc maxl = 0
		foreach ll of numlist `varlag' {
			loc Nl = `Nl' + 1
			loc llist `llist' `ll'
			loc maxl = max(`maxl',`ll')
			if (`Nl' == 1) loc laglist `ll'
			else loc laglist "`laglist' \ `ll'"
		}
	}

	* Parse varlist
	foreach v in `y2z1' {
		loc p = `p' + 1
		if (`p' <= `ny')	 loc y2 `y2' `v'
		else if (`p' > `ny') loc z1 `z1' `v'
	}
	
	loc n1 = wordcount("`y1'")
	loc n2 = wordcount("`y2'")
	loc k1 = wordcount("`z1'")
	loc k2 = wordcount("`z2'")
	if ("`estimator'" == "var") {
		loc n1 = 0
		loc n2 = wordcount("`y2z1'")
		loc k1 = `Nl' * `n2'
		loc k2 = 0
	}
	if ("`noconstant'" == "") loc k1 = `k1' + 1
	loc n = `n1' + `n2' // # of LHS variables
	loc k = `k1' + `k2' // # of RHS variables (w cons)
	loc nq = `n' * `k'
	loc na = `n' * (`n' - 1) / 2
	loc nl = `n'
	loc nqbar = `n1' * `k' + `n2' * (`n1' + `k1')
	loc nqcovar = `n' * (`n' + 1) / 2
	loc qq = `nqbar' + `nqcovar' // # of reduced-form total parameters (used by weak-instrument-robust inference)
	loc qqq = `nqbar' + `nqcovar' // # of total parameters

	if (!inlist("`estimator'","ols","newey","var") & (`k2' == 0) & (`n1' == 0)) {
		di as err "No instrument available."
		exit
	}
	if (`k2' < `n1') {
		di as err "# of external instruments is less than endogeneous variables."
		exit
	}
	if (`q' == 0) { // # of time-varying parameters
		if ("`slope'" != "") {
			if ((`k2' == 0) & (`n1' == 0)) loc q = `nq'
			else {
				if ("`estimator'" != "weakiv") loc q = `nqbar'
				else if ("`estimator'" == "weakiv") loc q = `nq'
			}
		}
		else {
			if ("`estimator'" != "weakiv") loc q = `qqq'
			else if ("`estimator'" == "weakiv") loc q = `qq'
		}
	}

	* Transmit data
	if (inlist("`estimator'","ols","newey")) { // OLS
		mata: y = st_data(.,"`y1' `y2'") // LHS
		mata: x = st_data(.,"`z1' `z2'") // RHS
		if ("`noconstant'" == "") mata: x = x, J(`T',1,1)
	}
	else if ("`estimator'" == "var") { // VAR
		mata: y = st_data(.,"`y2z1'")
		loc Nl = 0
		mata: x = J(`T'-`maxl',0,0)
		foreach ll of numlist `varlag' {
			mata: x = x, y[`maxl'-`ll'+1..`T'-`ll',.]
		}
		if ("`noconstant'" == "") mata: x = x, J(`T'-`maxl',1,1)
		mata: y = y[`maxl'+1..`T',.]
		loc T = `T' - `maxl'
	}
	else { // IV
		mata: y1 = st_data(.,"`y1'")
		mata: y2 = st_data(.,"`y2'")
		mata: z2 = st_data(.,"`z2'")
		if ("`noconstant'" == "") {
			if (`k1' > 1) mata: z1 = st_data(.,"`z1'"), J(`T',1,1)
			else mata: z1 = J(`T',1,1)
		}
		else {
			if (`k1' > 1) mata: z1 = st_data(.,,"`z1'")
			else mata: z1 = J(`T',1,0)
		}
	}
	di as text "Running the Time-Varying-Parameter Estimation..."
	if ((rowsof(`cmatrix') > 1) & (`getband' == 1)) di as text "The procedure might be slow when obtaining confidence band with vector ci."

	* Estimation
	loc Tall = `T'-`minh'
	mata: coef_const_all = J((`maxh'+1)*`qqq',1,0)
	mata: coef_all = J((`maxh'+1)*`q',`Tall',0)
	mata: coef_ub_all = J((`maxh'+1)*`q',`Tall',0)
	mata: coef_lb_all = J((`maxh'+1)*`q',`Tall',0)
	mata: Omega_all = J((`maxh'+1)*`q',`q'*`Tall',0)
	mata: weight_all = J(`maxh'+1,cols(c),0)
	mata: qLL_all = J(`maxh'+1,1,0)
	mata: residual_all = J((`maxh'+1)*`n',`Tall',0)

	foreach hh of numlist `nhorizon' {
		loc Th = `T'-`hh'
		if (`nwlag' == -1) {
			if (inlist("`estimator'","ols","var")) loc nlag = 0
			else loc nlag = floor(`Th'^(1/3))
		}
		else loc nlag = `nwlag'
		if (inlist("`estimator'","ols","newey")) { // OLS
			if ("`cumulative'" == "") mata: yy = y[`hh'+1..`T',.]
			else mata: yy = cum(y,`hh')
			mata: xx = x[1..`Th',.]
			mata: result = MPpath(yy,xx,`nlag',c,`getband',`chol',`q',`level')
		}
		else if ("`estimator'" == "var") { // VAR
			if (`q' < `nq') {
				di as err "Please make sure that all the reduced-form slope parameters are assumed to be time-varying when using vector autoregression."
				exit
			}
			mata: result = MPpath(y,x,`nlag',c,`getband',`chol',`q',`level')
		}
		else { // IV
			mata: zz1 = z1[1..`Th',.]
			mata: zz2 = z2[1..`Th',.]
			if ("`cumulative'" == "") {
				mata: yy2 = y2[`hh'+1..`T',.]
				
				if ("`lplagged'" == "") mata: yy1 = y1[`hh'+1..`T',.]
				else mata: yy1 = y1[1..`Th',.]
			}
			else {
				mata: yy2 = cum(y2,`hh')
				if ("`lplagged'" == "") mata: yy1 = cum(y1,`hh')
				else mata: yy1 = y1[1..`Th',.]
			}
			if ("`estimator'" != "weakiv") { // strong IV
				clear
				if (`k1' > 0) {
					mat define m_vec_2SLS = J(1,1,0)
					mat define mu_vec_2SLS = J(1,1,0)
					getmata (yy1*)=yy1 (yy2*)=yy2 (zz1*)=zz1 (zz2*)=zz2
					loc i = 0
					foreach yy2temp of varlist yy2* {
						loc i = `i' + 1
						qui ivreg2 `yy2temp' zz1* (yy1* = zz2*), noconst
						mat m_vec_2SLS = m_vec_2SLS \ (e(b)[1,1..`n1'])'
						mat mu_vec_2SLS = mu_vec_2SLS \ (e(b)[1,`n1'+1..`n1'+`k1'])'
					}
					mat m_vec_2SLS = m_vec_2SLS[2..`n2'*`n1'+1,1]
					mat mu_vec_2SLS = mu_vec_2SLS[2..`n2'*`k1'+1,1]
					mata: m_vec_2SLS = st_matrix("m_vec_2SLS")
					mata: mu_vec_2SLS = st_matrix("mu_vec_2SLS")
				}
				else {
					mat define m_vec_2SLS = J(1,1,0)
					getmata (yy1*)=yy1 (yy2*)=yy2 (zz2*)=zz2
					loc i = 0
					foreach yy2temp of varlist yy2* {
						loc i = `i' + 1
						qui ivreg2 `yy2temp' (yy1* = zz2*), noconst
						mat m_vec_2SLS = m_vec_2SLS \ (e(b)[1,1..`n1'])'
					}
					mat m_vec_2SLS = m_vec_2SLS[2..`n2'*`n1'+1,1]
					mata: m_vec_2SLS = st_matrix("m_vec_2SLS")
					mata: mu_vec_2SLS = 0
				}
				mata: result = MPIVpath2(yy1,yy2,zz1,zz2,`nlag',c,`getband',`chol',`q',`level',"`estimator'",m_vec_2SLS,mu_vec_2SLS)
// 				mata: result = MPIVpath(yy1,yy2,zz1,zz2,`nlag',c,`getband',`chol',`q',`level',"`estimator'")
			}
			else if ("`estimator'" == "weakiv") { // weak IV
				if (`q' < `nq') {
					di as err "Please make sure that all the reduced-form slope parameters are assumed to be time-varying when using weak-instrument-robust inference."
					exit
				}
				mata: result_TVPIV = MPpath((yy1,yy2),(zz2,zz1),`nlag',c,`getband',`chol',`q',`level')
				mata: result = MPweakIVpath(yy1,yy2,zz1,zz2,result_TVPIV,`q',`ndraw',`level',`getband')
			}
		}
		if ("`estimator'" != "weakiv") {
			mata: coef_const_all[`hh'*`qqq'+1..(`hh'+1)*`qqq'] = result.coef_const
			mata: Omega_all[`hh'*`q'+1..(`hh'+1)*`q',1..`q'*`Th'] = result.Omega
		}
		mata: coef_all[`hh'*`q'+1..(`hh'+1)*`q',1..`Th'] = result.coef
		mata: coef_lb_all[`hh'*`q'+1..(`hh'+1)*`q',1..`Th'] = result.coef_lb
		mata: coef_ub_all[`hh'*`q'+1..(`hh'+1)*`q',1..`Th'] = result.coef_ub
		mata: residual_all[`hh'*`n'+1..(`hh'+1)*`n',1..`Th'] = result.residual
		mata: weight_all[`hh'+1,.] = result.weight
		mata: qLL_all[`hh'+1] = result.qLL
	}

	* extract the non-zero
	loc T = `Tall'
	mata: coef_const = J(0,1,0)
	mata: coef = J(0,`T',0)
	mata: coef_ub = J(0,`T',0)
	mata: coef_lb = J(0,`T',0)
	mata: Omega = J(0,`q'*`T',0)
	mata: weight = J(0,cols(c),0)
	mata: qLL = J(0,1,0)
	mata: residual = J(0,`T',0)
	foreach hh of numlist `nhorizon' {
		mata: coef_const = coef_const \ coef_const_all[`hh'*`qqq'+1..(`hh'+1)*`qqq',.]
		mata: Omega = Omega \ Omega_all[`hh'*`q'+1..(`hh'+1)*`q',.]
		mata: coef = coef \ coef_all[`hh'*`q'+1..(`hh'+1)*`q',.] 
		mata: coef_lb = coef_lb \ coef_lb_all[`hh'*`q'+1..(`hh'+1)*`q',.]
		mata: coef_ub = coef_ub \ coef_ub_all[`hh'*`q'+1..(`hh'+1)*`q',.]
		mata: residual = residual \ residual_all[`hh'*`n'+1..(`hh'+1)*`n',.]
		mata: weight = weight \ weight_all[`hh'+1,.]
		mata: qLL = qLL \ qLL_all[`hh'+1,.]
	}
	if ("`estimator'" != "weakiv") {
		mata: st_matrix("coef_const", coef_const)
		mata: st_matrix("Omega", Omega)
	}
	mata: hatc = `T'*sqrt(rowsum((coef[.,2..`T'] - coef[.,1..`T'-1]):^2)/(`T'-1))
	mata: st_matrix("hatc", hatc)
	mata: st_matrix("coef", coef)
	mata: st_matrix("coef_lb", coef_lb)
	mata: st_matrix("coef_ub", coef_ub)
	mata: st_matrix("residual", residual)
	mata: st_matrix("weight", weight)
	mata: st_matrix("qLL", qLL)

	* Impulse response function VAR
	if (("`hlist'" != "0") & ("`estimator'" == "var")) { // VAR
		mata: sortmat = sortvar((`laglist'), `n',`cons', `q')
		mata: coef_adj = sortmat * coef
		mata: Omega_adj = sortmat * Omega * (I(`T') # sortmat')
		mata: sortmat = sortvar((`laglist'), `n',`cons', `qqq')
		mata: coef_const_adj = sortmat * coef_const	
		mata: result_VAR = MPVARpath(coef_adj,Omega_adj,coef_const_adj,`n',`cons',`maxhvar',`ndraw',`level',`chol',`getband')
		mata: st_matrix("varirf", result_VAR.irf)
		mata: st_matrix("varirf_lb", result_VAR.irf_lb)
		mata: st_matrix("varirf_ub", result_VAR.irf_ub)
		mata: result_VARconst = varirf(coef_const_adj,`n',`cons',`maxhvar',`chol')
		mata: st_matrix("varirf_const", result_VARconst)
	}

	* matname
	// coef name
	loc slopecoef
	if ("`noconstant'" == "") loc consname _cons
	if (inlist("`estimator'","ols","newey")) {
		foreach y in `y2' { // vec(B')
			foreach x in `z1' `consname' {
				loc slopecoef `slopecoef' `y':`x'
			}
		}
	}
	else if ("`estimator'" == "var") { 
		foreach y in `y2z1' { // vec([B1(t),...,Bp(t),C(t)]')
			foreach ll in `llist' {
				foreach x in `y2z1' {
					if (`ll' == 1) loc slopecoef `slopecoef' `y':L.`x'
					else loc slopecoef `slopecoef' `y':L`ll'.`x'
				}
			}
			if ("`noconstant'" == "") loc slopecoef `slopecoef' `y':_cons
		}
	}
	else if (inlist("`estimator'","2sls","gmm","weakiv")) {
		foreach y in `y1' { // vec(α')
			foreach x in `z2' `z1' `consname' {
				loc slopecoef `slopecoef' `y':`x'
			}
		}
		foreach y in `y2' { // vec(M')
			foreach x in `y1' {
				loc slopecoef `slopecoef' `y':`x'
			}
		}
		foreach y in `y2' { // vec(μ')
			foreach x in `z1' `consname' {
				loc slopecoef `slopecoef' `y':`x'
			}
		}
	}	
	
	loc covcoef
	if (`chol' == 1) { // [a(t)',l(t)']'
		if (`n' > 1) {
			forvalues n1 = 2/`n' {
				loc ne = `n1' - 1
				forvalues n2 = 1/`ne' {
					loc covcoef `covcoef' a`n1'`n2'
				}
			}
		}
		forvalues n1 = 1/`n' {
			loc covcoef `covcoef' l`n1'
		}
	}
	else { // vech(Σ(t))
		forvalues n1 = 1/`n' {
			forvalues n2 = `n1'/`n' {
				loc covcoef `covcoef' v`n2'`n1'
			}
		}
	}

	if ("`slope'" == "") loc coefname `slopecoef' `covcoef'
	else loc coefname `slopecoef'
	loc coefname_all `slopecoef' `covcoef'
	loc rowname
	loc rowname_all
	foreach hh of numlist `nhorizon' {
		foreach v in `coefname' {
			if (`hh' == 0) loc rowname `rowname' `v'
			else loc rowname `rowname' h`hh'.`v'
		}
		foreach v in `coefname_all' {
			if (`hh' == 0) loc rowname_all `rowname_all' `v'
			else loc rowname_all `rowname_all' h`hh'.`v'
		}
	}

	mat rownames hatc = `rowname'
	mat rownames coef = `rowname'
	mat rownames coef_ub = `rowname'
	mat rownames coef_lb = `rowname'
	if ("`estimator'" != "weakiv") {
		mat rownames Omega = `rowname'
		mat rownames coef_const = `rowname_all'
	}

	// irf name
	loc varirfname
	loc rowname
	if (("`hlist'" != "0") & ("`estimator'" == "var")) {
		foreach y in `y2z1' { 
			foreach x in `y2z1' {
				loc varirfname `varirfname' `y':`x'
			}
		}
		foreach hh of numlist `hlist' {
			foreach v in `varirfname' {
				if (`hh' == 0) loc rowname `rowname' `v'
				else loc rowname `rowname' h`hh'.`v'
			}
		}
		mat rownames varirf = `rowname'
		mat rownames varirf_lb = `rowname'
		mat rownames varirf_ub = `rowname'
		mat rownames varirf_const = `rowname'
	}
	// residual name
	if ("`estimator'" == "var") loc depvar `y2z1'
	else loc depvar `y2'
	if ("`estimator'" == "var") loc rowname `depvar'
	else if (inlist("`estimator'" , "ols","newey")) {
		loc rowname
		foreach hh of numlist `hlist' {
			foreach v in `depvar' {
				if (`hh' == 0) loc rowname `rowname' `v'
				else loc rowname `rowname' h`hh'.`v'
			}
		}
	}
	else {
		loc rowname
		foreach hh of numlist `hlist' {
			foreach v in `y1' `y2' {
				if (`hh' == 0) loc rowname `rowname' `v'
				else loc rowname `rowname' h`hh'.`v'
			}
		}
	}
	mat rownames residual = `rowname'

	* ereturn list
	return clear
	restore
	if ("`estimator'" == "var") {
		tempvar timevar_var
		bysort `touse' (`timevar'): gen `timevar_var' = [_n]
		qui replace `touse' = 0 if `timevar_var' <= `maxl'
		sort `timevar'
	}
	ereturn post, esample(`touse') buildfvinfo
	ereturn scalar T = `T'
	ereturn scalar q = `q'
	ereturn local coefname = "`coefname'"
	ereturn local title = "Time-Varying-Parameter Estimation"
	ereturn local cmd = "tvpreg"
	ereturn local predict = "tvpreg_p"
	ereturn local model = "`estimator'"
	ereturn local horizon = "`hlist'"
	if ("`cumulative'" != "") ereturn local cumulative = "yes"
	else ereturn local cumulative = "no"
	if ("`lplagged'" != "") ereturn local lplagged = "yes"
	else ereturn local lplagged = "no"
	if ("`noconstant'" == "") ereturn local constant = "yes"
	else ereturn local constant = "no"
	if (`chol' == 1) ereturn local cholesky = "yes"
	else ereturn local cholesky = "no"
	if (`getband' == 1) ereturn local band = "yes"
	else ereturn local band = "no"
	ereturn scalar level = `level'
	ereturn local depvar = "`depvar'"
	if (inlist("`estimator'" , "ols","newey")) ereturn local indepvar = "`z1'"
	else if ("`estimator'" == "var") {
		ereturn local varlag = "`llist'"
		ereturn local maxvarlag = "`maxl'"
		if ("`hlist'" != "0") {
			ereturn matrix varirf = varirf
			ereturn matrix varirf_lb = varirf_lb
			ereturn matrix varirf_ub = varirf_ub
			ereturn matrix varirf_const = varirf_const
			ereturn local varirfname = "`varirfname'"
		}
	}
	else {
		ereturn local instd = "`y1'" // instrumented variables
		ereturn local insts = "`z1' `z2'" // instruments
		ereturn local inexog = "`z1'" // included instruments
		ereturn local exexog = "`z2'" // excluded instruments
	}
	ereturn local cmdline = "`cmdline'"
	if ("`cdefault'" == "yes") ereturn matrix qLL = qLL
	ereturn matrix c = `cmatrix'
	mat define `cmatrix' = e(c)
	ereturn matrix weight = weight
	if ("`estimator'" != "weakiv") {
		ereturn matrix coef_const = coef_const
		if (`getband' == 1) ereturn matrix Omega = Omega
	}
	ereturn matrix coef = coef
	ereturn matrix coef_lb = coef_lb
	ereturn matrix coef_ub = coef_ub
	ereturn matrix residual = residual
	ereturn matrix hatc = hatc

	* display information
	Replay, `nodisplay'
	
	* figures
	if (("`plotcoef'" != "") | ("`plotvarirf'" != "")) {
		di as text ""
		if ("`ci'" != "") loc noci noci
		if ("`legend'" != "") loc nolegend nolegend
		foreach opt in plotcoef plotvarirf plotnhorizon period movavg title ytitle xtitle tvplegend constlegend bandlegend shadelegend periodlegend scheme tvpcolor constcolor name {
			if ("``opt''" != "") loc `opt' `opt'(``opt'')
		}
		tvpplot, `plotcoef' `plotvarirf' `plotnhorizon' `plotconst' `period' `movavg' `noci' `title' `name' `ytitle' `xtitle' `tvplegend' `constlegend' `bandlegend' `shadelegend' `periodlegend' `nolegend' `scheme' `tvpcolor' `constcolor'
	}
end

program define Replay
	version 17.0
	
	syntax [if] [in] [, NODISplay]
	
	* Table	
	if ("`nodisplay'" == "") {
		if ("`e(constant)'" == "yes") loc consname " _cons"
		if (inlist("`e(model)'","ols","newey")) {
			loc n = wordcount("`e(depvar)'")
			loc k = wordcount("`e(indepvar)'")
			if ("`e(constant)'" == "yes") loc k = `k' + 1
			if ("`e(horizon)'" == "0") {
				di as text "The model is:"
				di as text ""
				di as text "    y(t) = B(t) × x(t) + e(t)"
				di as text ""
				di as text " with dependent variable   y(t) (`n'×1): `e(depvar)',"
				di as text "      independent variable x(t) (`k'×1): `e(indepvar)'`consname',"
				loc Bname "vec(B(t)')'"
			}
			else if ("`e(cumulative)'" == "no") {
				di as text "The model is:"
				di as text ""
				di as text "    y(t+h) = B(h,t+h) × x(t) + e(t+h)"
				di as text ""
				di as text " with horizon (h) includes `e(horizon)',"
				di as text "      dependent variable   y(t) (`n'×1): `e(depvar)',"
				di as text "      independent variable x(t) (`k'×1): `e(indepvar)'`consname',"
				loc Bname "vec(B(h,t+h)')'"
			}
			else {
				di as text "The model is:"
				di as text ""
				di as text "    cumy(t+h) = B(h,t+h) × x(t) + e(t+h)"
				di as text ""
				di as text " with horizon (h) includes `e(horizon)',"
				di as text "      dependent variable   y(t) (`n'×1): `e(depvar)', cumy(t+h) = y(t)+...+y(t+h),"
				di as text "      independent variable x(t) (`k'×1): `e(indepvar)'`consname',"
				loc Bname "vec(B(h,t+h)')'"
			}
			loc vname e
		}
		else if ("`e(model)'" == "var") {
			loc n = wordcount("`e(depvar)'")
			if ("`e(constant)'" == "yes") {
				di as text "The model is:"
				di as text ""
				di as text "       y(t) = [B(1,t),...,B(p,t),c(t)] × [y(t-1)',...,y(t-p)',1]' + e(t)"
				di as text "  Bt(L)y(t) = c(t) + u(t) = c(t) + Θ(0,t)ε(t)"
				di as text ""
				di as text " with lags (p) includes `e(varlag)',"
				di as text "      dependent variable  y(t) (`n'×1): `e(depvar)',"
				di as text "      B(t) = [B(1,t),...,B(p,t),c(t)],"
			}
			else {
				di as text "The model is:"
				di as text ""
				di as text "       y(t) = [B(1,t),...,B(p,t)] × [y(t-1)',...,y(t-p)']' + e(t)"
				di as text "  Bt(L)y(t) = u(t) = Θ(0,t)ε(t)"
				di as text ""
				di as text " with lags (p) includes `e(varlag)'"
				di as text "      dependent variable  y(t) (`n'×1): `e(depvar)',"
				di as text "      B(t) = [B(1,t),...,B(p,t)],"
			}
			loc Bname "vec(B(t)')'"
			loc vname e
		}
		else {
			loc n2 = wordcount("`e(depvar)'")
			loc n1 = wordcount("`e(instd)'")
			loc k2 = wordcount("`e(exexog)'")
			loc k1 = wordcount("`e(inexog)'")
			loc n = `n1' + `n2'
			if ("`e(constant)'" == "yes") loc k1 = `k1' + 1
			if ("`e(horizon)'" == "0") {
				di as text "The structural model is:"
				di as text ""
				di as text "    y(t) = B(x,t) × x(t) + B(z1,t) × z(1,t) + ν(2,t)"
				di as text ""
				di as text " with dependent variable   y(t) (`n2'×1): `e(depvar)',"
				di as text "      endogeneous variable x(t) (`n1'×1): `e(instd)', and"
				di as text ""
				di as text "    x(t) = Π(2,t) × z(2,t) + Π(1,t) × z(1,t) + ν(1,t)"
				di as text ""
				di as text " with included instruments z(1,t) (`k1'×1): `e(inexog)'`consname',"
				di as text "      excluded instruments z(2,t) (`k2'×1): `e(exexog)'."
				di as text ""
				di as text "The multivariate system is:"
				di as text ""
				di as text "     _      _     _                           _     _        _     _        _"
				di as text "    |  x(t)  |   |            Π(t)             |   |  z(2,t)  |   |  ν(1,t)  |"
				di as text "    |        | = |                             | × |          | + |          |"
				di as text "    |_ y(t) _|   |_ B(x,t)×Π(t) + [0 B(z1,t)] _|   |_ z(1,t) _|   |  ν(2,t) _|"
				di as text ""
				di as text " with Π(t) = [Π(2,t),Π(1,t)], ν(t) = [ν(1,t)',ν(2,t)']',"
				loc Bname "vec(Π(t)')',vec(B(x,t)')',vec(B(z1,t)')'"
			}
			else if (("`e(cumulative)'" == "no") & ("`e(lplagged)'" == "no")) {
				di as text "The structural model is:"
				di as text ""
				di as text "    y(t+h) = B(x,h,t+h) × x(t+h) + B(z1,h,t+h) × z(1,t) + ν(2,t+h)"
				di as text ""
				di as text " with dependent variable   y(t) (`n2'×1): `e(depvar)',"
				di as text "      endogeneous variable x(t) (`n1'×1): `e(instd)', and"
				di as text ""
				di as text "    x(t+h) = Π(2,h,t+h) × z(2,t) + Π(1,h,t+h) × z(1,t) + ν(1,t+h)"
				di as text ""
				di as text " with included instruments z(1,t) (`k1'×1): `e(inexog)'`consname',"
				di as text "      excluded instruments z(2,t) (`k2'×1): `e(exexog)'."
				di as text ""
				di as text "The multivariate system is:"
				di as text ""
				di as text "     _        _     _                                       _     _        _     _          _"
				di as text "    |  x(t+h)  |   |                  Π(h,t+h)               |   |  z(2,t)  |   |  ν(1,t+h)  |"
				di as text "    |          | = |                                         | × |          | + |            |"
				di as text "    |_ y(t+h) _|   |_ B(x,h,t+h)×Π(h,t+h) + [0 B(z1,h,t+h)] _|   |_ z(1,t) _|   |  ν(2,t+h) _|"
				di as text ""
				di as text " with Π(h,t+h) = [Π(2,h,t+h),Π(1,h,t+h)], ν(t+h) = [ν(1,t+h)',ν(2,t+h)']',"
				loc Bname "vec(Π(h,t+h)')',vec(B(x,h,t+h)')',vec(B(z1,h,t+h)')'"
			}
			else if (("`e(cumulative)'" == "no") & ("`e(lplagged)'" == "yes")) {
				di as text "The structural model is:"
				di as text ""
				di as text "    y(t+h) = B(x,h,t+h) × x(t) + B(z1,h,t+h) × z(1,t) + ν(2,t+h)"
				di as text ""
				di as text " with dependent variable   y(t) (`n2'×1): `e(depvar)',"
				di as text "      endogeneous variable x(t) (`n1'×1): `e(instd)', and"
				di as text ""
				di as text "     x(t)  = Π(2,t) × z(2,t) + Π(1,t) × z(1,t) + ν(1,t)"
				di as text ""
				di as text " with included instruments z(1,t) (`k1'×1): `e(inexog)'`consname',"
				di as text "      excluded instruments z(2,t) (`k2'×1): `e(exexog)'."
				di as text ""
				di as text "The multivariate system is:"
				di as text ""
				di as text "     _        _     _                                       _     _        _     _          _"
				di as text "    |   x(t)   |   |                    Π(t)                 |   |  z(2,t)  |   |   ν(1,t)   |"
				di as text "    |          | = |                                         | × |          | + |            |"
				di as text "    |_ y(t+h) _|   |_ B(x,h,t+h)×Π(h,t+h) + [0 B(z1,h,t+h)] _|   |_ z(1,t) _|   |  ν(2,t+h) _|"
				di as text ""
				di as text " with Π(t) = [Π(2,t),Π(1,t)], ν(t+h) = [ν(1,t)',ν(2,t+h)']',"
				loc Bname "vec(Π(t)')',vec(B(x,h,t+h)')',vec(B(z1,h,t+h)')'"
			}
			else if (("`e(cumulative)'" == "yes") & ("`e(lplagged)'" == "no")) {
				di as text "The structural model is:"
				di as text ""
				di as text "    cumy(t+h) = B(x,h,t+h) × cumx(t+h) + B(z1,h,t+h) × z(1,t) + ν(2,t+h)"
				di as text ""
				di as text " with dependent variable   y(t) (`n2'×1): `e(depvar)', cumy(t+h) = y(t)+...+y(t+h),"
				di as text "      endogeneous variable x(t) (`n1'×1): `e(instd)', cumx(t+h) = x(t)+...+x(t+h), and"
				di as text ""
				di as text "    cumx(t+h) = Π(2,h,t+h) × z(2,t) + Π(1,h,t+h) × z(1,t) + ν(1,t+h)"
				di as text ""
				di as text " with included instruments z(1,t) (`k1'×1): `e(inexog)'`consname',"
				di as text "      excluded instruments z(2,t) (`k2'×1): `e(exexog)'."
				di as text ""
				di as text "The multivariate system is:"
				di as text ""
				di as text "     _           _     _                                       _     _        _     _          _"
				di as text "    |  cumx(t+h)  |   |                  Π(h,t+h)               |   |  z(2,t)  |   |  ν(1,t+h)  |"
				di as text "    |             | = |                                         | × |          | + |            |"
				di as text "    |_ cumy(t+h) _|   |_ B(x,h,t+h)×Π(h,t+h) + [0 B(z1,h,t+h)] _|   |_ z(1,t) _|   |  ν(2,t+h) _|"
				di as text ""
				di as text " with Π(h,t+h) = [Π(2,h,t+h),Π(1,h,t+h)], ν(t+h) = [ν(1,t+h)',ν(2,t+h)']',"
				loc Bname "vec(Π(h,t+h)')',vec(B(x,h,t+h)')',vec(B(z1,h,t+h)')'"
			}
			else if (("`e(cumulative)'" == "yes") & ("`e(lplagged)'" == "yes")) {
				di as text "The structural model is:"
				di as text ""
				di as text "    cumy(t+h) = B(x,h,t+h) × x(t) + B(z1,h,t+h) × z(1,t) + ν(2,t+h)"
				di as text ""
				di as text " with dependent variable   y(t) (`n2'×1): `e(depvar)', cumy(t+h) = y(t)+...+y(t+h),"
				di as text "      endogeneous variable x(t) (`n1'×1): `e(instd)', and"
				di as text ""
				di as text "       x(t)   = Π(2,t) × z(2,t) + Π(1,t) × z(1,t) + ν(1,t)"
				di as text ""
				di as text " with included instruments z(1,t) (`k1'×1): `e(inexog)'`consname',"
				di as text "      excluded instruments z(2,t) (`k2'×1): `e(exexog)'."
				di as text ""
				di as text "The multivariate system is:"
				di as text ""
				di as text "     _           _     _                                       _     _        _     _          _"
				di as text "    |     x(t)    |   |                    Π(t)                 |   |  z(2,t)  |   |   ν(1,t)   |"
				di as text "    |             | = |                                         | × |          | + |            |"
				di as text "    |_ cumy(t+h) _|   |_ B(x,h,t+h)×Π(h,t+h) + [0 B(z1,h,t+h)] _|   |_ z(1,t) _|   |  ν(2,t+h) _|"
				di as text ""
				di as text " with Π(t) = [Π(2,t),Π(1,t)], ν(t+h) = [ν(1,t)',ν(2,t+h)']',"
				loc Bname "vec(Π(t)')',vec(B(x,h,t+h)')',vec(B(z1,h,t+h)')'"
			}
			loc vname ν
		}
		if ("`e(cholesky)'" == "yes") {
			if (("`e(horizon)'" == "0") | "`e(model)'" == "var") {
				if (`n' == 1) {
					di as text "      `vname'(t) ~ N(0,σ(`vname',t)^2)."
					di as text ""
					di as text "The parameter is [`Bname',lnσ(`vname',t)]',"
				}
				else if (`n' == 2) {
					di as text "      `vname'(t) ~ N(0,Σ(`vname',t)), and A(t) × Σ(`vname',t) × A(t)' = Σ(ε,t) × Σ(ε,t)',"
					di as text ""
					di as text "            _           _"
					di as text "           |   1      0  |"
					di as text "   A(t) =  |             | and Σ(ε,t) = diag[σ(1,t), σ(2,t)]."
					di as text "           |_ a(t)    1 _|"
					di as text ""
					di as text "The parameter is [`Bname',a(t),lnσ(1,t), lnσ(2,t)]',"
				}
				else if (`n' == 3) {
					di as text "      `vname'(t) ~ N(0,Σ(`vname',t)), and A(t) × Σ(`vname',t) × A(t)' = Σ(ε,t) × Σ(ε,t)',"
					di as text ""
					di as text "            _                          _"
					di as text "           |     1          0        0  |"
					di as text "   A(t) =  |  a(21,t)       1        0  |"
					di as text "           |_ a(31,t)    a(32,t)     1 _|"
					di as text ""
					di as text "and Σ(ε,t) = diag[σ(1,t), σ(2,t), σ(3,t)]."
					di as text ""
					di as text "The parameter is [`Bname',a(t)',lnσ(t)']',"
					di as text ""
					di as text " with a(t) = [a(21,t),a(31,t),a(32,t)]', and"
					di as text "      σ(t) = [σ(1,t), σ(2,t), σ(3,t)]'."
				}
				else if (`n' > 3) {
					di as text "      `vname'(t) ~ N(0,Σ(`vname',t)), and A(t) × Σ(`vname',t) × A(t)' = Σ(ε,t) × Σ(ε,t)',"
					di as text ""
					di as text "            _                                             _"
					di as text "           |     1          0        0        ...       0  |"
					di as text "           |  a(21,t)       1        0        ...       0  |"
					di as text "   A(t) =  |  a(31,t)    a(32,t)     1        ...       0  |, N = `n'"
					di as text "           |    ...        ...      ...       ...      ... |"
					di as text "           |_ a(N1,t)      ...      ...   a(N(N-1),t)   1 _|"
					di as text ""
					di as text "and Σ(ε,t) = diag[σ(1,t), ..., σ(N,t)]."
					di as text ""
					di as text "The parameter is [`Bname',a(t)',lnσ(t)']',"
					di as text ""
					di as text " with a(t) = [a(21,t),a(31,t),a(32,t),...,a(N(N-1),t)]', and"
					di as text "      σ(t) = [σ(1,t),...,σ(N,t)]'."
				}
			}
			else {
				if (`n' == 1) {
					di as text "      `vname'(t+h) ~ N(0,σ(`vname',t+h)^2)."
					di as text ""
					di as text "The parameter is [`Bname',lnσ(`vname',t+h)]',"
				}
				else if (`n' == 2) {
					di as text "      `vname'(t+h) ~ N(0,Σ(`vname',t+h)), and A(t+h) × Σ(`vname',t+h) × A(t+h)' = Σ(ε,t+h) × Σ(ε,t+h)',"
					di as text ""
					di as text "              _             _"
					di as text "             |    1       0  |"
					di as text "   A(t+h) =  |               | and Σ(ε,t+h) = diag[σ(1,t+h), σ(2,t+h)]."
					di as text "             |_ a(t+h)    1 _|"
					di as text ""
					di as text "The parameter is [`Bname',a(t+h),lnσ(1,t+h), lnσ(2,t+h)]',"
				}
				else if (`n' == 3) {
					di as text "      `vname'(t+h) ~ N(0,Σ(`vname',t+h)), and A(t+h) × Σ(`vname',t+h) × A(t+h)' = Σ(ε,t+h) × Σ(ε,t+h)',"
					di as text ""
					di as text "              _                              _"
					di as text "             |      1            0         0  |"
					di as text "   A(t+h) =  |  a(21,t+h)        1         0  |"
					di as text "             |_ a(31,t+h)    a(32,t+h)     1 _|"
					di as text ""
					di as text "and Σ(ε,t+h) = diag[σ(1,t+h), σ(2,t+h), σ(3,t+h)]."
					di as text ""
					di as text "The parameter is [`Bname',a(t+h)',lnσ(t+h)']',"
					di as text ""
					di as text " with a(t) = [a(21,t+h),a(31,t+h),a(32,t+h)]', and"
					di as text "      σ(t) = [σ(1,t+h), σ(2,t+h), σ(3,t+h)]'."
				}
				else if (`n' > 3) {
					di as text "      `vname'(t+h) ~ N(0,Σ(`vname',t+h)), and A(t+h) × Σ(`vname',t+h) × A(t+h)' = Σ(ε,t+h) × Σ(ε,t+h)',"
					di as text ""
					di as text "              _                                                   _"
					di as text "             |      1            0         0         ...        0  |"
					di as text "             |  a(21,t+h)        1         0         ...        0  |"
					di as text "   A(t+h) =  |  a(31,t+h)    a(32,t+h)     1         ...        0  |, N = `n'"
					di as text "             |     ...          ...       ...        ...       ... |"
					di as text "             |_ a(N1,t+h)       ...       ...   a(N(N-1),t+h)   1 _|"
					di as text ""
					di as text "and Σ(ε,t+h) = diag[σ(1,t+h), ..., σ(N,t+h)]."
					di as text ""
					di as text "The parameter is [`Bname',a(t+h)',lnσ(t+h)']',"
					di as text ""
					di as text " with a(t+h)   = [a(21,t+h),a(31,t+h),a(32,t+h),...,a(N(N-1),t+h)]', and"
					di as text "      σ(t+h)   = [σ(1,t+h),...,σ(N,t+h)]'."
				}
			}
		}
		else {
			if ("`e(horizon)'" == "0") {
				if (`n' == 1) {
					di as text "      `vname'(t) ~ N(0,σ(`vname',t)^2)."
					di as text ""
					di as text "The parameter is [`Bname',σ(`vname',t)^2]'."
				}
				else if (`n' > 1) {
					di as text "      `vname'(t) ~ N(0,Σ(`vname',t)), Σ(`vname',t) is a symmetric matrix."
					di as text ""
					di as text "The parameter is [`Bname',vech(Σ(`vname',t))']'."
				}
			}
			else {
				if (`n' == 1) {
					di as text "      `vname'(t+h) ~ N(0,σ(`vname',t+h)^2)."
					di as text ""
					di as text "The parameter is [`Bname',σ(`vname',t+h)^2]'."
				}
				else if (`n' > 1) {
					di as text "      `vname'(t+h) ~ N(0,Σ(`vname',t+h)), Σ(`vname',t+h) is a symmetric matrix."
					di as text ""
					di as text "The parameter is [`Bname',vech(Σ(`vname',t+h))']'."
				}
			}
		}
		di as text ""
		if ("`e(model)'" == "ols") di as text "The constant parameter model is estimated by OLS."
		else if (inlist("`e(model)'","ols","newey")) di as text "The constant parameter model is estimated by Newey."
		else if ("`e(model)'" == "var")         di as text "The constant parameter model is estimated by VAR."
		else if ("`e(model)'" == "2sls")        di as text "The constant parameter model is estimated by 2SLS."
		else if ("`e(model)'" == "gmm")         di as text "The constant parameter model is estimated by GMM."
		else if ("`e(model)'" == "weakiv")      di as text "The reduced-form constant parameter model is estimated by OLS."
	}
	
end

findfile "tvpreg.mata"
include "`r(fn)'"
exit
