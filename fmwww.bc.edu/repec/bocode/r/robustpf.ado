////////////////////////////////////////////////////////////////////////////////
// Stata for Hu, Y., Huang, G., & Sasaki, Y. (2020): Estimating Production 
//           Functions with Robustness Against Errors in the Proxy Variables. 
//           Journal of Econometrics 215 (2), pp. 375-398.
////////////////////////////////////////////////////////////////////////////////
!* version 17  21sep2022
 program define robustpf, eclass
    version 17
 
    syntax varlist(min=1 max=1 numeric) [if] [in] [, CAPital(varlist min = 1 max=1) FRee(varlist min=1) M(varlist) PROXy(varname numeric) init_capital(real 0.1) init_free(real 0.1) init_m(real 0.3) ONEstep dfp bfgs]
    marksample touse
	qui xtset
	local panelid   = r(panelvar)
	local timeid  = r(timevar)
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
		
	local ones = 1
	if "`onestep'" == ""{
		local ones = 0
	}
	
	local method_dfp = 1
	if "`dfp'" == ""{
		local method_dfp = 0
	}
	
	local method_bfgs = 1
	if "`bfgs'" == ""{
		local method_bfgs = 0
	}
	
	if "`dfp'" != "" & "`bfgs'" != ""{
		di "{hline 80}"
		di "Error: The two options, dfp and bfgs, cannot be called simultaneously."
		di "{hline 80}"
		exit
	}
	
	if "`capital'" == "" || "`free'" == "" || "`proxy'" == "" {
	    di "{hline 80}"
	    di "Error: necessary options are not invoked."
		if "`capital'" == "" { 
			di "       The capital() option must be called with one variables as an argument."
		}
		if "`free'" == "" { 
			di "       The free() option must be called with at least one variable as arguments."
		}
		if "`proxy'" == "" { 
			di "       The proxy() option must be called with one variables as an argument."
		}
	    di "{hline 80}"
		exit
	}
	
	local lbl `capital' `free' `m'
	tempvar mmvar
	if "`m'" == ""{
		gen `mmvar' = 0
		local m = "`mmvar'"
		local lbl `capital' `free'
	}
	
	//if "`capital'" != "" & "`free'" != "" & "`proxy'" != ""{
		tempvar xvar
		gen `xvar' = `proxy'

		tempname b V br Vr NT N T minT maxT Obj
		mata: estimation("`depvar'", "`xvar'", "`capital'", "`free'", "`m'",	///
						 "`panelid'", "`timeid'", `init_capital', `init_free',	///
						 `init_m', `ones', `method_dfp',	`method_bfgs',		///
						 "`touse'", "`b'", "`V'", "`br'", "`Vr'", "`NT'", 		///
						 "`N'", "`T'", "`minT'", "`maxT'", "`Obj'") 
		mata: mata clear
		
		matrix colnames `b' = `lbl'
		matrix colnames `V' = `lbl'
		matrix rownames `V' = `lbl'

		ereturn post `b' `V', esample(`touse') buildfvinfo
		ereturn scalar obs  = `NT'
		ereturn scalar N    = `N'
		ereturn scalar T    = `T'
		ereturn scalar minT = `minT'
		ereturn scalar maxT = `maxT'
		ereturn matrix br	= `br'
		ereturn matrix Vr	= `Vr'
		ereturn scalar objective = `Obj'
		ereturn local  cmd  "robustpf"
	 
		ereturn display
		di "  *  robustPF is based on Hu, Y., Huang, G., & Sasaki, Y. (2020): Estimating"
		di "  Production Functions with Robustness Against Errors in the Proxy Variables."
		di "  Journal of Econometrics 215 (2), pp. 375-398."
	//}
end
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Function for the GMM Criterion
void GMMc(todo, para, size, numlmumm, yearlist, yearyk, l, m, x, z, W, crit, g, H){
	numl = numlmumm[1,1]
	numm = numlmumm[1,2]
	
	a_x0 = para[1] // J(1,1,0)
	a_xk = para[2] // J(1,1,0)
	a_xomega = para[3] // J(1,1,0)
	b_k = para[4] // J(1,1,0)
	b_l = para[5..(4+numl)]' // J(numl,1,0)
	b_m = para[(5+numl)..(4+numl+numm)]' // J(numm,1,0.5)
	phi1 = para[5+numl+numm] // J(1,1,1)

	year = yearyk[.,1]
	y    = yearyk[.,2]
	k    = yearyk[.,3]
	
	ytilde = y :- k * b_k :- l * b_l
	if( numm > 0 ){
		ytilde = y :- k * b_k :- l * b_l :- m * b_m
	}
	xtilde = x :- a_x0 :- k * a_xk
	ytilde_tplus1 = ytilde
	xtilde_tplus1 = xtilde
    for( idx = 1 ; idx <= rows(y) ; idx++ ){
	    if( year[idx] == min(yearlist) ){
		    ytilde_tplus1[idx] = 0
		    xtilde_tplus1[idx] = 0
		}else{
		    ytilde_tplus1[idx] = ytilde[idx-1]
		    xtilde_tplus1[idx] = xtilde[idx-1]
		}
	}
	//xtilde_tplus1,xtilde
	
	moments = J(cols(z)*2,1,0)
	for( idx = 1 ; idx <= cols(z) ; idx++ ){
		moments[2*(idx-1)+1] = sum( z[.,idx] :* (ytilde_tplus1 :- (a_xomega*phi1) :* ytilde) )
		moments[2*(idx-1)+2] = sum( z[.,idx] :* (xtilde_tplus1 :- phi1 :* ytilde) )
	}
	moments = moments :/ size

    crit = moments' * W * moments
}
//////////////////////////////////////////////////////////////////////////////// 
// Function for the GMM Variance
void GMMv(para, size, numlmumm, yearlist, yearyk, l, m, x, z, variance){
	numl = numlmumm[1,1]
	numm = numlmumm[1,2]
	
	a_x0 = para[1] // J(1,1,0)
	a_xk = para[2] // J(1,1,0)
	a_xomega = para[3] // J(1,1,0)
	b_k = para[4] // J(1,1,0)
	b_l = para[5..(4+numl)]' // J(numl,1,0)
	b_m = para[(5+numl)..(4+numl+numm)]' // J(numm,1,0.5)
	phi1 = para[5+numl+numm] // J(1,1,1)

	year = yearyk[.,1]
	y    = yearyk[.,2]
	k    = yearyk[.,3]

	ytilde = y :- k * b_k :- l * b_l
	if( numm > 0 ){
		ytilde = y :- k * b_k :- l * b_l :- m * b_m
	}
	xtilde = x :- a_x0 :- k * a_xk
	ytilde_tplus1 = ytilde
	xtilde_tplus1 = xtilde
    for( idx = 1 ; idx <= rows(y) ; idx++ ){
	    if( year[idx] == min(yearlist) ){
		    ytilde_tplus1[idx] = 0
		    xtilde_tplus1[idx] = 0
		}else{
		    ytilde_tplus1[idx] = ytilde[idx-1]
		    xtilde_tplus1[idx] = xtilde[idx-1]
		}
	}
	//xtilde_tplus1,xtilde

	moments = J(cols(z)*2,size,0)
	for( idx = 1 ; idx <= cols(z) ; idx++ ){
	    index = 1
	    for( jdx = 1 ; jdx <= rows(z) ; jdx++ ){
		    if( year[jdx] != min(yearlist) ){
				moments[2*(idx-1)+1,index] = sum( z[jdx,idx] :* (ytilde_tplus1[jdx] :- (a_xomega*phi1) :* ytilde[jdx]) )
				moments[2*(idx-1)+2,index] = sum( z[jdx,idx] :* (xtilde_tplus1[jdx] :- phi1 :* ytilde[jdx]) )
				index++
			}
		}
	}
	
	variance = moments * moments' :/ size :- (moments :/ size) * (moments :/ size)'
}
//////////////////////////////////////////////////////////////////////////////// 
// Function for the GMM moments
void GMMm(para, size, numlmumm, yearlist, yearyk, l, m, x, z, moments){
	numl = numlmumm[1,1]
	numm = numlmumm[1,2]
	
	a_x0 = para[1] // J(1,1,0)
	a_xk = para[2] // J(1,1,0)
	a_xomega = para[3] // J(1,1,0)
	b_k = para[4] // J(1,1,0)
	b_l = para[5..(4+numl)]' // J(numl,1,0)
	b_m = para[(5+numl)..(4+numl+numm)]' // J(numm,1,0.5)
	phi1 = para[5+numl+numm] // J(1,1,1)

	year = yearyk[.,1]
	y    = yearyk[.,2]
	k    = yearyk[.,3]

	ytilde = y :- k * b_k :- l * b_l
	if( numm > 0 ){
		ytilde = y :- k * b_k :- l * b_l :- m * b_m
	}
	xtilde = x :- a_x0 :- k * a_xk
	ytilde_tplus1 = ytilde
	xtilde_tplus1 = xtilde
    for( idx = 1 ; idx <= rows(y) ; idx++ ){
	    if( year[idx] == min(yearlist) ){
		    ytilde_tplus1[idx] = 0
		    xtilde_tplus1[idx] = 0
		}else{
		    ytilde_tplus1[idx] = ytilde[idx-1]
		    xtilde_tplus1[idx] = xtilde[idx-1]
		}
	}
	//xtilde_tplus1,xtilde
	
	moments = J(cols(z)*2,1,0)
	for( idx = 1 ; idx <= cols(z) ; idx++ ){
		moments[2*(idx-1)+1] = sum( z[.,idx] :* (ytilde_tplus1 :- (a_xomega*phi1) :* ytilde) )
		moments[2*(idx-1)+2] = sum( z[.,idx] :* (xtilde_tplus1 :- phi1 :* ytilde) )
	}
	moments = moments :/ size
}
//////////////////////////////////////////////////////////////////////////////// 
// Function for the GMM gradients
void GMMg(para, size, numlmumm, yearlist, yearyk, l, m, x, z, gradients){
    real matrix moments
	GMMm(para, size, numlmumm, yearlist, yearyk, l, m, x, z, moments)

	gradients = J(length(moments),length(para),0)
	
	real matrix delta_moments
	delta = 0.001

	for( idx = 1 ; idx <= length(para) ; idx++ ){
		delta_para = para
		delta_para[idx] = delta_para[idx] + delta
		GMMm(delta_para, size, numlmumm, yearlist, yearyk, l, m, x, z, delta_moments)
		
		gradients[.,idx] = (delta_moments - moments ) :/ delta
	}
}
////////////////////////////////////////////////////////////////////////////////
// Main Estimation Function
void estimation( string scalar depvar,	string scalar xvar,	
				 string scalar cvar, 	string scalar lvar,	
				 string scalar mvar, 	string scalar panelid, 
				 string scalar timeid,	real scalar init_k,	
				 real scalar init_l, 	real scalar init_m,	
				 real scalar onestep, 	real scalar dfp,		
				 real scalar bfgs, 		string scalar touse,   
				 string scalar bname, 	string scalar Vname,   
				 string scalar brname, 	string scalar Vrname,	
				 string scalar ntname, 	string scalar nname,	
				 string scalar tname, 	string scalar mintname,
				 string scalar maxtname,string scalar oname) 
{
	printf("\nExecuting robustPF.\n")
 
 	////////////////////////////////////////////////////////////////////////////
	// depvar ==> y, first row of indepvar ==> k, the last row of indepvar ==> x
    y    = st_data(., depvar, touse)
	k    = st_data(., cvar, touse)
	l    = st_data(., lvar, touse)
	numl = cols(l)
	x    = st_data(., xvar, touse)
	m    = st_data(., mvar, touse)
	numm = cols(m)
    year = st_data(., timeid, touse)
	id   = st_data(., panelid, touse)
	
	if( sum(m:!=0)==0 ){
	 m = J(rows(y),0,0)
	 numm=0
	}

	////////////////////////////////////////////////////////////////////////////
	// Get the list of ids
	idlist = id :* 0
	idlist[1] = id[1]
	index = 1
	for( idx = 2 ; idx <= length(id) ; idx++ ){
		if( sum( id[idx] :== idlist[1..index] ) == 0 ){
			index++
			idlist[index] = id[idx]
		}
	}
	idlist = idlist[1..index]
	idlist = sort(idlist,1)
	N = length(idlist)

	////////////////////////////////////////////////////////////////////////////
	// Get the list of years
	yearlist = year :* 0
	yearlist[1] = year[1]
	index = 1
	for( idx = 2 ; idx <= length(year) ; idx++ ){
		if( sum( year[idx] :== yearlist[1..index] ) == 0 ){
			index++
			yearlist[index] = year[idx]
		}
	}
	yearlist = yearlist[1..index]
	yearlist = sort(yearlist,1)
	T = length(yearlist)
	
	size = sum( min(yearlist) :!= year ) // Effective Sample Size
	
	////////////////////////////////////////////////////////////////////////////
	// Form instruments - first if x is a part of m, then take the lag of that m
	z = m, l, k, J(rows(m),1,1)
	m_proxy_index = 0
	for( idx = 1 ; idx <= numm ; idx++ ){
	    if( sum( m[.,idx] :!= x )  :== 0 ){
		    m_proxy_index = idx
		}
	}
	if( m_proxy_index > 0 ){
	    for( idx = 1 ; idx <= rows(z) ; idx++ ){
		    if( year[idx] == min(yearlist) ){
			    z[idx,.] = J(1,cols(z),0)
			}else{
			    z[idx,m_proxy_index] = m[idx-1,m_proxy_index]
			}
		}
	}
	//m,z

	////////////////////////////////////////////////////////////////////////////
	// 1st Step GMM Estimation
	printf("  GMM: 1st Step Estimation\n")
	W = diag(J(cols(z)*2,1,1))

	a_x0 = J(1,1,0.0)
	a_xk = J(1,1,0.0)
	a_xomega = J(1,1,0)
	b_k = J(1,1,init_k)
	b_l = J(numl,1,init_l)
	b_m = J(numm,1,init_m)
	phi1 = J(1,1,1)
	init = ( a_x0, a_xk, a_xomega, b_k, b_l', b_m', phi1 )
	S = optimize_init()
	optimize_init_evaluator(S,&GMMc())
	optimize_init_which(S,"min")
	optimize_init_evaluatortype(S, "d0")
	optimize_init_technique(S,"nr")
	if( dfp ){
		optimize_init_technique(S,"dfp")
	}
	if( bfgs ){
		optimize_init_technique(S,"bfgs")
	}
	optimize_init_singularHmethod(S,"hybrid") 
	optimize_init_argument(S,1,size)
	optimize_init_argument(S,2,(numl,numm))
	optimize_init_argument(S,3,yearlist)
	optimize_init_argument(S,4,(year,y,k))
	optimize_init_argument(S,5,l) 
	optimize_init_argument(S,6,m)
	optimize_init_argument(S,7,x)
	optimize_init_argument(S,8,z)
	optimize_init_argument(S,9,W)
	optimize_init_params(S, init)
	optimize_init_tracelevel(S, "none")
	optimize_init_trace_dots(S, "on")
	//optimize_init_conv_maxiter(S, 2)
	est=optimize(S)	
	//est

	////////////////////////////////////////////////////////////////////////////
	// Estimate 1st GMM variance
	real matrix variance
	GMMv(est, size, (numl,numm), yearlist, (year,y,k), l, m, x, z, variance)
	//variance
	
	////////////////////////////////////////////////////////////////////////////
	// Estimate 1st GMM gradients
	real matrix graidents
	GMMg(est, size, (numl,numm), yearlist, (year,y,k), l, m, x, z, gradients)
	
	if( !onestep ){
	////////////////////////////////////////////////////////////////////////////
	// 2nd Step GMM Estimation
	printf("  GMM: 2nd Step Estimation\n")
	W = luinv(variance)
	
	S = optimize_init()
	optimize_init_evaluator(S,&GMMc())
	optimize_init_which(S,"min")
	optimize_init_evaluatortype(S, "d0")
	optimize_init_technique(S,"nr")
	if( dfp ){
		optimize_init_technique(S,"dfp")
	}
	if( bfgs ){
		optimize_init_technique(S,"bfgs")
	}
	optimize_init_singularHmethod(S,"hybrid") 
	optimize_init_argument(S,1,size)
	optimize_init_argument(S,2,(numl,numm))
	optimize_init_argument(S,3,yearlist)
	optimize_init_argument(S,4,(year,y,k))
	optimize_init_argument(S,5,l) 
	optimize_init_argument(S,6,m)
	optimize_init_argument(S,7,x)
	optimize_init_argument(S,8,z)
	optimize_init_argument(S,9,W)
	optimize_init_params(S, init)
	optimize_init_tracelevel(S, "none")
	optimize_init_trace_dots(S, "on")
	//optimize_init_conv_maxiter(S, 2)
	est=optimize(S)	
	//est
	
	////////////////////////////////////////////////////////////////////////////
	// Estimate 2nd GMM variance
	GMMv(est, size, (numl,numm), yearlist, (year,y,k), l, m, x, z, variance)
	//variance
	
	////////////////////////////////////////////////////////////////////////////
	// Estimate 2nd GMM gradients
	GMMg(est, size, (numl,numm), yearlist, (year,y,k), l, m, x, z, gradients)
	
	//gradients' * luinv(variance) * gradients / (N*(T-1))
	} // END IF !onestep //
		
	b = est[1,4..(length(est)-1)]'
	V = ( gradients' * luinv(variance) * gradients / size )[4..(length(est)-1),4..(length(est)-1)]

    st_matrix(bname, b')
    st_matrix(Vname, V)
    st_numscalar(ntname, rows(year))
    st_numscalar(nname, N)
    st_numscalar(tname, T)
    st_numscalar(mintname, min(year))
    st_numscalar(maxtname, max(year))
	st_numscalar(oname, optimize_result_value(S))
	
	RTS = J(1,length(b),1) * b
	V_RTS = J(1,length(b),1) * V * J(1,length(b),1)'
	SE_RTS = (V_RTS)^0.5
	
    st_matrix(brname, RTS)
    st_matrix(Vrname, V_RTS)
	
	printf("\n")
	printf("{hline 78}\n")
	if( N*T == rows(year) ){
	printf("Exactly balanced panel:                                    observations=%6.0f\n",rows(year))
	}else{
	printf("Unbalanced panel:                                          observations=%6.0f\n",rows(year))
	}
	printf("Number of cross-sectional observations in the subsample:              N=%6.0f\n", N)
	printf("Number of time periods in the subsample:                              T=%6.0f\n", T)
	printf("                                                                   minT=%6.0f\n",min(year))
	printf("                                                                   maxT=%6.0f\n",max(year))
	printf("{hline 78}\n")
	printf("Returns to Scale (Std. Err.) = %f (%f)\n",RTS,SE_RTS)
}
end
////////////////////////////////////////////////////////////////////////////////

