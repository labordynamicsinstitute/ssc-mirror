*! xtloglin 1.0.1 12sep2023
*! author david vincent
*! email dvincent@dveconometrics.co.uk (or davidwvincent@hotmail.com)

//----------------------------------------------------------------------//
 
program define xtloglin, sortpreserve rclass

	version 15.1
 
	syntax, null(string) [NEGative *]
	
	tempvar touse
	qui gen byte `touse'=e(sample)
		
	if !inlist("`e(cmd)'","regress","xtreg"){
		di as err "xtloglin allowed after {opt regress} or {opt xtreg}"
		exit 198
	}
	
	if inlist("`e(cmd)'","xtreg") & !inlist("`e(model)'","fe","re","be"){
		di as err "models {opt fe,re,be} allowed after {opt xtreg}"
		exit 198
	}
	
	if !inlist("`null'","log","linear"){
		di as err "must specify {opt model(linear)} or {opt model(log)} as the null model to be tested"
		exit 198
	}

	if "`null'"=="log" & "`negative'"!=""{
		di as err "can only specify {opt negative} with {opt model(linear)}"
		exit 198
	}
	
	cap tsset

	if "`options'"!="" {
		
	//error structure specified in xtloglin 
		
		_parse_error_cov, `options'
	
		loc clustvar = "`r(clustvar)'"
		loc evar     = "`r(evar)'"
		
		if "`e(cmd)'"=="xtreg" & "`evar'"=="robust"{ 
			loc clustvar="`e(ivar)'"
			loc evar="cluster"
		}
	
		if ("`e(cmd)'"=="xtreg" & "`clustvar'"!=""){
		
			_check_nested `clustvar', ivar(`e(ivar)') esample(`touse')
		}
	}
	
	else{
	
	//specified at estimation 
		
		local clustvar = "`e(clustvar)'"
		local evar     = "`e(vce)'"
		
		if ("`e(cmd)'"=="xtreg" & "`clustvar'"!="")  loc evar="cluster"
		if ("`e(cmd)'"=="regress" & "`evar'"=="ols") loc evar="conventional"		
	}
					
	//match xtreg,be requirements
	
	if ("`e(cmd)'"=="xtreg" & "`e(model)'"=="be" & "`evar'"!="conventional") {
		di as error "option robust or cluster not allowed after xtreg,be"
		exit 198
	}
	
	//----------------------------------------------------------------------//
	
	local c=0
	local xvars: colname e(b)
	foreach v of local xvars{
		local c=`c'+strmatch("`v'","_cons")
	}
	
	if `c'{
		local cons "_cons"
		local xvars: list xvars-cons
	}
	
	tempvar res diff
	tempname npanels
	
	local yvar="`e(depvar)'"
	
	if "`null'"=="linear"{
	
		qui count if `yvar'<=0
		if r(N)>0 & "`negative'"==""{
			di as err "untransformed variable `yvar' must be strictly positive. Specify {opt negative} to test linear model with negative outcomes"
			exit 411
		}
	}
		
	//inputs for LM-statistic
	mata: _lm_inputs("`yvar'","`xvars'",`c',"`null'","`touse'","`res'","`diff'","`npanels'","`negative'")
	
	if "`evar'"=="cluster"{
		sort `clustvar'
		markout `touse' `clustvar'
	}

	tempname lm_name p_name
	
	//LM-statistic
	mata: _lm_stat("`res'","`diff'","`evar'","`clustvar'","`touse'","`lm_name'", "`p_name'","`npanels'")

	return scalar lm = `lm_name'
	return scalar p  = `p_name'
	
	return loc null     `null'
	return loc evar     `evar'
	return loc clustvar `clustvar'
	
	local ttype=cond("`negative'"=="","Box-Cox","MacKinnon-Magee")
	
	di
	di as txt "Robust LM test of linear and log-linear functional forms"
	di as txt "H0: `null' dependent variable"	
	di as txt "H1: `ttype' transformation"

	di in smcl as text "{hline 57}"
	di as txt _col(5) "LM-chi2(1) = " as res %10.3f `lm_name'
	di as txt _col(5) "Prob > LM  = " as res %11.4f `p_name'	
	di in smcl as text "{hline 57}"
	di as text "Error Variance: `evar'"
	
	if "`clustvar'"!=""{
		di as txt "Cluster Variable: `clustvar'"
	}
 
end

 //----------------------------------------------------------------------//
	
 program _check_nested, sortpreserve
 
	syntax varname, ivar(varname) esample(varname)
		
	local cvar `varlist'
	
	if "`cvar'" == "`ivar'" exit
	
	marksample touse
	qui replace `touse'=0 if !`esample'
		
	tempvar uniq tot
	
	sort `ivar' `cvar'
	qui egen `uniq'=tag(`ivar' `cvar') if `touse'
	qui egen `tot'=total(`uniq'), by(`ivar')

	qui count if `tot'>1 & `touse'
	
	if r(N)>0{
		di as err "panels are not nested within clusters"
		exit 498
	}
	
 end
 
 //----------------------------------------------------------------------//
 
 program _parse_error_cov, rclass
 
	syntax, [NOTRobust ROBust CLUSter(varname)]
		
	local cluster_opt=cond("`cluster'"!="","cluster(varname)","")
	
	opts_exclusive "`notrobust' `robust' `cluster_opt'"

	if "`cluster'"!="" {
	
		confirm var `cluster'			
		return loc evar =  "cluster"
		return loc clustvar  = "`cluster'"
	}
	
	if "`robust'"!="" {
			
		return loc evar =  "robust"
		return loc clustvar  = ""
	}

	if "`notrobust'"!="" {
			
		return loc evar =  "conventional"
		return loc clustvar  = ""
	}

end
 	
//--------------------------------------------------------------------------//
    
mata:

struct data
{

 string scalar yvar,xvars
 string scalar touse
 string scalar null
 string scalar negative
 string scalar idvar

 real   matrix X,y
 real   matrix T_lam
 real   matrix id_rows
 
 real   matrix beta
 real   matrix yhat_n
 real   matrix res
 real   matrix diff

 real   matrix MZZ 
 real   matrix MXX
 real   matrix MZT_lam
 real   matrix MXT_lam

 real   scalar K 
 real   scalar N
 real   scalar NT
 real   scalar cons
 real   scalar sigma_e,sigma_u,sigma_b,rmse

}

//--------------------------------------------------------------------------//

void setup(struct data scalar z,
           string scalar yvar,
		   string scalar xvars,
		   real   scalar cons,
		   string scalar null,
		   string scalar negative,
		   string scalar touse)
{

 real scalar sf 
 real vector id,y_T
 
 st_view(z.y,.,yvar,touse)			//y-transformed = y_T, or log(y_T)
 st_view(z.X,.,tokens(xvars),touse)
 z.beta=st_matrix("e(b)")
 
 z.negative=negative 
 z.touse=touse
 z.null=null
 z.cons=cons
 z.NT=rows(z.X)
 z.K=cols(z.X)
 z.N=z.NT 
 
 
 if(st_global("e(cmd)")=="xtreg"){
 
	z.idvar=st_global("e(ivar)")
	st_view(id,.,z.idvar,touse)
	z.id_rows=panelsetup(id,1)	
	z.N=rows(z.id_rows)

	if(st_global("e(model)")=="fe" | st_global("e(model)")=="re"){
		
		z.sigma_e=st_numscalar("e(sigma_e)")
		z.sigma_u=st_numscalar("e(sigma_u)")
	}	
 }

 //untransformed y-variable
 y_T=(z.null=="linear" ? z.y : exp(z.y)) 
  
 if(z.negative=="negative" & z.null=="linear"){
 
	//derivative of MacKinnon-Magee transformation for testing linearity (theta=0)
	z.T_lam=y_T:^2

 }
 else{
 
	//scaling factor (Box Cox only)
	sf=exp(mean(log(abs(y_T))))
 
	//derivative of scaled Box-Cox transformation for testing linear & log-linear (lambda=1 | 0)
	z.T_lam=(z.null=="linear" ? (y_T:*(ln(y_T:/sf):-1):+1) : ln(y_T):*(ln(sqrt(y_T):/sf)))

 }
 
}

//--------------------------------------------------------------------------//

void _lm_stat(string scalar resvar,
			  string scalar diffvar,
			  string scalar evar,
			  string scalar clustvar,
			  string scalar touse,
		      string scalar lm_name, 
			  string scalar p_name,
			  string scalar npanels)
{

 real scalar N,M,lm
 real vector res,diff,clust

 if(st_global("e(model)")!="be"){
 
	st_view(res,.,resvar,touse)
	st_view(diff,.,diffvar,touse)
 }
 else{
 
	//number of panels (first N-rows in dataset)
	N=st_numscalar(npanels)
 	st_view(res,(1::N),resvar)
	st_view(diff,(1::N),diffvar)
		
 }
 
 if(evar=="conventional"){
 
	N=rows(res)
	M=quadcross(diff,diff)*(quadcross(res,res)/N)

 }
 
 if(evar=="robust"){
 
	M=quadcross(diff,res:^2,diff)
 } 
 
 if(evar=="cluster"){
 
	st_view(clust,.,clustvar,touse)
	M=_cluster_cross(clust,res,diff)

 }
   
 lm=(quadcross(res,diff)^2)/M
   
 st_numscalar(lm_name,lm)
 st_numscalar(p_name,1-chi2(1,lm))

} 
 
//--------------------------------------------------------------------------//

real scalar _cluster_cross(real vector clust,
				           real vector res,
						   real vector diff)
{

 real scalar N,M,i
 real vector res_i,diff_i,clust_rows

 clust_rows=panelsetup(clust,1)
 N=rows(clust_rows)
 M=0
 
 for(i=1;i<=N ;i++){
 
		res_i=panelsubmatrix(res,i,clust_rows)
		diff_i=panelsubmatrix(diff,i,clust_rows)
		
		M=M+diff_i'(res_i*res_i')*diff_i

 }
 
 return(M)
 
}

//--------------------------------------------------------------------------//

void _lm_inputs(string scalar yvar,
				string scalar xvars,
				real   scalar cons,
			    string scalar null,
				string scalar touse,
				string scalar resvar,
				string scalar diffvar,
				string scalar npanels,
				string scalar negative)
{

 struct data scalar z

 setup(z,yvar,xvars,cons,null,negative,touse)
 
 if(st_global("e(model)")=="ols"){
	_ols_inputs(z)
 }
 
 if(st_global("e(model)")=="re"){
	_re_inputs(z)

 }
	
 if(st_global("e(model)")=="fe"){
	_fe_inputs(z)
 }
	
 if(st_global("e(model)")=="be"){
	_be_inputs(z)
 }
 
 
 if(st_global("e(model)")!="be"){
	
	//row specific, order matters
	st_store(.,st_addvar("double",(resvar,diffvar)),touse,(z.res,z.diff))
 }
 else{
 
	//add means to first N-rows order irrelevant as clustering not allowed
	st_store((1::z.N),st_addvar("double",(resvar,diffvar)),(z.res,z.diff))
 }
 
 st_numscalar(npanels,z.N)

}	

//--------------------------------------------------------------------------//

void _ols_inputs(struct data scalar z)
{
 
 real scalar min,max
 real vector beta,res,diff
 real matrix X,Z,yhat_n,MZZ_inv,MXX_inv
 
 beta=z.beta
 
 res=J(z.NT,1,.)
 diff=J(z.NT,1,.)

 X=(z.cons ? (z.X,J(rows(z.X),1,1)) : z.X)

 //use normalised_yhat(it) = a*yhat(it)+b to avoid huge yhat^r values (no impact on LM-stat)
 yhat_n=X*beta'
 min=min(yhat_n)
 max=max(yhat_n)
 yhat_n = (z.null=="linear" & z.negative!="negative" ? yhat_n:^-1 : (yhat_n:-min):/(max:-min))
 
//instruments
 Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
 _editmissing(Z,0)
  
 MZZ_inv=invsym(quadcross(Z,Z))
 MXX_inv=invsym(quadcross(X,X))
 
 //predict T_lam using Z then partial out X
 z.diff=(Z*MZZ_inv*quadcross(Z,z.T_lam))-(X*MXX_inv*quadcross(X,z.T_lam))

 //residuals
 z.res=(z.y-X*beta')

}
 
//--------------------------------------------------------------------------//
 
void _fe_inputs(struct data scalar z)
{

 real scalar i,max,min,T,st,fi
 real vector beta,beta1,res,diff,y,e
 real matrix X,Z,yhat_n,MZZ_inv,MXX_inv,Q
 
 beta=z.beta
 beta1=select(z.beta,!e(z.K+1,z.K+1))

 res=J(z.NT,1,.)
 diff=J(z.NT,1,.)
    
 //normalised fitted values (before FE-transformation)
 X=(z.X,J(rows(z.X),1,1))
 z.yhat_n=X*beta'
 min=min(z.yhat_n)
 max=max(z.yhat_n)
 z.yhat_n = (z.null=="linear" & z.negative!="negative" ? z.yhat_n:^-1 : (z.yhat_n:-min):/(max:-min))

 _fe_ZZ_XX_components(z)
 
 MZZ_inv=invsym(z.MZZ)
 MXX_inv=invsym(z.MXX)

 for(i=1;i<=z.N;i++){
 
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows)

	T=rows(X)
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]	
	Q=I(T)-e*e'/T
			
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)

	//transformed variables
	y=Q*y
	X=Q*X
	Z=Q*Z
	
	//predict T_lam_FE using Z_FE then partial out X_FE
	diff[st::fi]=Z*MZZ_inv*z.MZT_lam-X*MXX_inv*z.MXT_lam
	
	//residuals FE=eit
 	res[st::fi]=(y-X*beta1')
	
 }
 
 z.diff=diff
 z.res=res
 

}
 
//--------------------------------------------------------------------------//
 
void _fe_ZZ_XX_components(struct data scalar z)
{
 
 real scalar i,T
 real vector T_lam,yhat_n,e
 real matrix X,Z,Q
 
 z.MZZ     = J(z.K+4,z.K+4,0)
 z.MXX     = J(z.K,z.K,0)
 z.MZT_lam = J(z.K+4,1,0)
 z.MXT_lam = J(z.K,1,0)
 
 for(i=1;i<=z.N;i++){

	X=panelsubmatrix(z.X,i,z.id_rows)
	T_lam=panelsubmatrix(z.T_lam,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows) 
	
	T=rows(X)
	e=J(T,1,1)
	Q=I(T)-e*e'/T
			
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)

	z.MZZ=z.MZZ+Z'Q*Z
	z.MXX=z.MXX+X'Q*X	
	
	z.MZT_lam=z.MZT_lam+Z'Q*T_lam
	z.MXT_lam=z.MXT_lam+X'Q*T_lam
	
 }
 
 
}
 
//--------------------------------------------------------------------------//

void _re_inputs(struct data scalar z)
{
 
 real scalar i,max,min,T,st,fi,phi2
 real vector beta,res,diff,y,e
 real matrix X,Z,yhat_n,MZZ_inv,MXX_inv,Q,V

 beta=z.beta
 
 res=J(z.NT,1,.)
 diff=J(z.NT,1,.)
    
 //normalised fitted values (before RE-transformation)
 X=(z.X,J(rows(z.X),1,1))
 z.yhat_n=X*beta'
 min=min(z.yhat_n)
 max=max(z.yhat_n)
 z.yhat_n = (z.null=="linear" & z.negative!="negative" ? z.yhat_n:^-1 : (z.yhat_n:-min):/(max:-min))

 _re_ZZ_XX_components(z)
 
 MZZ_inv=invsym(z.MZZ)
 MXX_inv=invsym(z.MXX)
 
 for(i=1;i<=z.N;i++){
 
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows)
	T=rows(X)
	X=(X,J(T,1,1))
	
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]	
	Q=I(T)-e*e'/T
	phi2=(z.sigma_e^2)/(T*z.sigma_u^2+z.sigma_e^2)
	V=(Q+sqrt(phi2)*(I(T)-Q)) 							//note sqrt transform
			
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)
	
	//transformed variables
	y=V*y
	X=V*X
	Z=V*Z	
		
	//predict T_lam_RE using Z_RE then partial out X_RE
	diff[st::fi]=Z*MZZ_inv*z.MZT_lam-X*MXX_inv*z.MXT_lam
	
	//residuals_RE
 	res[st::fi]=(y-X*beta')

 }
 
 z.diff=diff
 z.res=res
  
}
 
//--------------------------------------------------------------------------//
 
void _re_ZZ_XX_components(struct data scalar z)
{

 real scalar i,T,phi2
 real vector T_lam,yhat_n,e
 real matrix X,Z,Q,V

 z.MZZ     = J(z.K+5,z.K+5,0)
 z.MXX     = J(z.K+1,z.K+1,0)
 z.MZT_lam = J(z.K+5,1,0)
 z.MXT_lam = J(z.K+1,1,0)

 for(i=1;i<=z.N;i++){
 
 	X=panelsubmatrix(z.X,i,z.id_rows)
	T_lam=panelsubmatrix(z.T_lam,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows) 
	T=rows(X)
	X=(X,J(T,1,1))
	
	e=J(T,1,1)
	Q=I(T)-e*e'/T
	phi2=(z.sigma_e^2)/(T*z.sigma_u^2+z.sigma_e^2)
	V=(Q+phi2*(I(T)-Q)) 							  //note no sqrt transform
			
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)

	z.MZZ=z.MZZ+Z'V*Z
	z.MXX=z.MXX+X'V*X	
	
	z.MZT_lam=z.MZT_lam+Z'V*T_lam
	z.MXT_lam=z.MXT_lam+X'V*T_lam
		
 }
 
}

//--------------------------------------------------------------------------//
 
void _be_inputs(struct data scalar z)
{
 
 real scalar i,max,min,T,st,fi,w
 real vector beta,res,diff,y,e
 real matrix X,Z,yhat_n,MZZ_inv,MXX_inv,P
 
 beta=z.beta
 
 res=J(z.N,1,.)
 diff=J(z.N,1,.)
    
 //normalised fitted values (before BE-transformation)
 X=(z.X,J(rows(z.X),1,1))
 z.yhat_n=X*beta'
 min=min(z.yhat_n)
 max=max(z.yhat_n)
 z.yhat_n = (z.null=="linear" & z.negative!="negative" ? z.yhat_n:^-1 : (z.yhat_n:-min):/(max:-min))

 _be_ZZ_XX_components(z)
 
 MZZ_inv=invsym(z.MZZ)
 MXX_inv=invsym(z.MXX)

 
 for(i=1;i<=z.N;i++){
 
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows)
	T=rows(X)
	X=(X,J(T,1,1))
 	
	//weight by sqrt(Ti) for WLS
	w=(st_global("e(typ)")!="" ? sqrt(T) : 1)	//sqrt not 1 
	e=J(T,1,1)
	P=(e'/T)*w
	
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)
			
	//transformed variables (panel means)
	y=P*y
	X=P*X		//i.e., 1 x K 
	Z=P*Z	
		
	//predict T_lam_BE using Z_BE then partial out X_BE
	diff[i]=Z*MZZ_inv*z.MZT_lam-X*MXX_inv*z.MXT_lam
	
	//residuals_RE
 	res[i]=(y-X*beta')

 }
 
 z.diff=diff
 z.res=res
  
}
 
//--------------------------------------------------------------------------//
 
void _be_ZZ_XX_components(struct data scalar z)
{
 
 real scalar i,T,w
 real vector T_lam,yhat_n,e
 real matrix X,Z,P
  
 z.MZZ     = J(z.K+5,z.K+5,0)
 z.MXX     = J(z.K+1,z.K+1,0)
 z.MZT_lam = J(z.K+5,1,0)
 z.MXT_lam = J(z.K+1,1,0)

 for(i=1;i<=z.N;i++){
 
 	X=panelsubmatrix(z.X,i,z.id_rows)
	T_lam=panelsubmatrix(z.T_lam,i,z.id_rows)
	yhat_n=panelsubmatrix(z.yhat_n,i,z.id_rows) 
	T=rows(X)
	X=(X,J(T,1,1))
	
	//weight by Ti for WLS
	w=(st_global("e(typ)")!="" ? 1 : 2)
	e=J(T,1,1)
	P=(e*e')/(T^w)
			
	//instruments
	Z=(X,yhat_n,yhat_n:^2,yhat_n:^3,yhat_n:^4)
	_editmissing(Z,0)

	z.MZZ=z.MZZ+Z'P*Z
	z.MXX=z.MXX+X'P*X	
	
	z.MZT_lam=z.MZT_lam+Z'P*T_lam
	z.MXT_lam=z.MXT_lam+X'P*T_lam
	
 }
 
}

end

