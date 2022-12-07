*! cooksd2 1.0.1 01nov2022
*! author david vincent
*! email dvincent@dveconometrics.co.uk (or davidwvincent@hotmail.com)

program define cooksd2, sortpreserve rclass
 version 15.1
 
 syntax newvarname, [cvars(varlist ts fv numeric) noCONStant Panela Panelb(varname numeric) parms(string)]
	
 tempvar touse
 qui gen `touse'=0 if !e(sample)
	
	
 if !inlist("`e(cmd)'","regress","xtreg"){
	di as err "cooksd2 allowed after {opt regress} or {opt xtreg}"
	exit 301
 }
	
 if inlist("`e(cmd)'","xtreg") & !inlist("`e(model)'","fe","re","be"){
	di as err "models {opt fe,re,be} allowed after {opt xtreg}"
	exit 301
 }
	
 if "`panelb'"!="" & inlist("`e(cmd)'","xtreg"){
	di as err "cannot specify {it:varname} in {opt panel(varname)} after xtreg"" 
	exit 198
 }
	
 if "`panela'"!="" & "`panelb'"=="" & "`e(cmd)'"=="regress" {
	di as err "specify {it:varname} in {opt panel(varname)} after regress" 
	exit 198
 }

 local panel= "`panela'"!="" | "`panelb'"!=""

 if inlist("`e(cmd)'","xtreg"){
	local idvar="`e(ivar)'"
	sort `idvar' 
	local Tbar=`e(g_avg)'
 }

 else{
	local idvar="`panelb'"
 }
		
 if `panel' & "`e(cmd)'"=="regress"{
	qui describe, varlist
	if "`r(sortlist)'"!="`idvar'"{
		sort `idvar'
	}
 }
			
 local c=0
 local xvars: colname e(b)
 foreach v of local xvars{
	local c=`c'+strmatch("`v'","_cons")
 }
	
 local cons _cons
 local xvars: list xvars-cons

 _ms_extract_varlist `xvars', noomit
	
 if "`r(varlist)'"=="" & !`c'{
	di as err "model contains no variables"
	exit 198	
 }
			
 if "`cvars'"!=""{
	_ms_extract_varlist `cvars', noomit
		
	if "`r(varlist)'"==""{
		di as err "all variables in {opt cvars} are omitted from model"
		exit 198	
	}
 }
 else{
	_ms_extract_varlist `xvars', noomit
 }

 local cvars="`r(varlist)'"
	
 if "`cvars'"=="" & "`constant'"!=""{
	di as err "cannot specify {opt noconstant} when model contains a constant and no other variables"
	exit 198	
 }

 local c1=`c' & "`constant'"==""
	
 local depvar="`e(depvar)'"
	
 di as txt "Cooks-distance using: " cond(`c1',"`cvars' _cons","`cvars'")


 qui if "`e(model)'"=="re"{		
	
	tempname estre
	tempvar Sig2e Sig2b
		
	_estimates hold `estre'

	*fixed effects: sig2_e
	xtreg `depvar' `xvars', fe
	mata: add_variances("`idvar'","`depvar'","`xvars'","`touse'","`Sig2e'",`c',`c1',`panel')

	*between effects: sig2_b
	xtreg `depvar' `xvars', be
	mata: add_variances("`idvar'","`depvar'","`xvars'","`touse'","`Sig2b'",`c',`c1',`panel')
	
	_estimates unhold `estre'
	
}

mata: cooksd2("`varlist'","`idvar'","`depvar'","`xvars'","`cvars'","`touse'","`parms'","`Sig2e'","`Sig2b'",`c',`c1',`panel',`Tbar')

 

	
end



mata:

struct data
{

real matrix X
real matrix Sig2e,Sig2b,Sig2u
real matrix beta
real matrix Beta
real matrix id_rows

real vector y,id

real scalar NT,K,N
real scalar df_b,df_m
real scalar cons_xvars
real scalar cons_cvars
real scalar panel
real scalar sigma_e,sigma_u,sigma_b,rmse
real scalar muT

string scalar xvars,idvar,touse


}

//--------------------------------------------------------------------------//

struct data scalar setup(string scalar idvar,
						 string scalar yvar,
						 string scalar xvars,
						 string scalar touse,
						 real   scalar cons_xvars,
						 real   scalar cons_cvars,
						 real   scalar panel)
{


struct data scalar z

st_view(z.X,.,tokens(xvars),touse)
st_view(z.y,.,yvar,touse)

z.rmse=st_numscalar("e(rmse)")

if(st_global("e(cmd)")=="xtreg" | panel){

	z.idvar=idvar

	//panel identifier
	st_view(z.id,.,idvar,touse)
	
	//panel rows
	z.id_rows=panelsetup(z.id,1)
	
	//number of panels
	z.N=rows(z.id_rows)
}


if(st_global("e(cmd)")=="xtreg"){

	if(st_global("e(model)")=="fe" | st_global("e(model)")=="re"){
		
		z.sigma_e=st_numscalar("e(sigma_e)")
		z.sigma_u=st_numscalar("e(sigma_u)")
	}
	
}


//constant indicators
z.cons_xvars=cons_xvars
z.cons_cvars=cons_cvars

//panel indicator 
z.panel=panel

z.xvars=xvars
z.touse=touse

z.NT=rows(z.y)
z.K=cols(z.X)+cons_xvars

z.Beta=J(z.NT,z.K,.)
z.Sig2e=J(z.NT,1,.)
z.Sig2b=J(z.NT,1,.)
z.Sig2u=J(z.NT,1,.)

z.beta=st_matrix("e(b)")
z.df_b=st_numscalar("e(df_b)")
z.df_m=st_numscalar("e(df_m)")


return(z)

}

//--------------------------------------------------------------------------//

void jkparms(struct data scalar z)
{

//drop observation

 if(!z.panel){


	if(st_global("e(model)")=="re"){
		dropobs_re(z)
	}

	if(st_global("e(model)")=="fe"){
		dropobs_fe(z)
	}
	
	if(st_global("e(model)")=="be"){
		dropobs_be(z)
	}

	if(st_global("e(model)")=="ols"){
		dropobs_ols(z)
	}

 }
 
//drop panel

 else{

	if(st_global("e(model)")=="re"){
		droppanel_re(z)
	}
	
	if(st_global("e(model)")=="fe"){
		droppanel_fe(z)
	}
	
	if(st_global("e(model)")=="be"){
		droppanel_be(z)
	}

	if(st_global("e(model)")=="ols"){
		droppanel_ols(z)
	}

 }

}

//--------------------------------------------------------------------------//

real matrix add_variances(string scalar idvar,
				  string scalar yvar,
				  string scalar xvars,
				  string scalar touse,
				  string scalar newsig2,
				  real   scalar cons_xvars,
				  real   scalar cons_cvars,
				  real   scalar panel)

{

 struct data scalar z
 
 z=setup(idvar,yvar,xvars,touse,cons_xvars,cons_cvars,panel)

 jkparms(z)
 

 if(st_global("e(model)")=="fe"){
	st_store(.,st_addvar("double",newsig2),touse,z.Sig2e)
 }
 
 if(st_global("e(model)")=="be"){
	st_store(.,st_addvar("double",newsig2),touse,z.Sig2b)
	
 }

 
}

//--------------------------------------------------------------------------//

void cooksd2(string scalar newvar,
	         string scalar idvar,
			 string scalar yvar,
			 string scalar xvars,
			 string scalar cvars,
			 string scalar touse,
			 string scalar parms,
			 string scalar Sig2e,
			 string scalar Sig2b,
			 real   scalar cons_xvars,
			 real   scalar cons_cvars,
			 real   scalar panel,
		   | real 	scalar muT)
			

{


struct data scalar z

z=setup(idvar,yvar,xvars,touse,cons_xvars,cons_cvars,panel)

//add estimated variances
if(st_global("e(model)")=="re"){

	st_view(z.Sig2e,.,Sig2e,touse)
	st_view(z.Sig2b,.,Sig2b,touse)
	z.muT=muT
	
}

jkparms(z)

//add coefficients to dataset
if(parms!=""){

	//coefficient names
	clabels=(z.cons_xvars ? (tokens(z.xvars),"cons") : tokens(z.xvars))

	//remove special characters
	cnames=subinstr(parms:+"_b_":+clabels, ".", "")
	cnames=subinstr(cnames, "#", "_x_")

	st_store(.,st_addvar("double",cnames),touse,z.Beta)
	
	//add coefficient labels
	for(i=1;i<=z.K;i++){
		st_varlabel(cnames[i], "_b["+clabels[i]+"]")
	}
	
	if (st_global("e(model)")=="fe") {
		st_store(.,st_addvar("double",parms+"_sigma_e"),touse,z.Sig2e:^0.5)
	}
	
	if (st_global("e(model)")=="be") {
		st_store(.,st_addvar("double",parms+"_sigma_b"),touse,z.Sig2b:^0.5)
	}

	if (st_global("e(model)")=="re") {
		st_store(.,st_addvar("double",parms+"_sigma_u"),touse,z.Sig2u:^0.5)
		st_store(.,st_addvar("double",parms+"_sigma_e"),touse,z.Sig2e:^0.5)
	}
	
}


//variables for cooks2
cvars2=tokens(cvars)
xvars2=tokens(xvars)
k1=cols(xvars2)
k2=cols(cvars2)
c=J(1,k1,0)

for(i=1;i<=k2;i++){	
	c=c+strmatch(cvars2[i],xvars2)	
}

//add constant
if(z.cons_xvars){
	c=(z.cons_cvars ? (c,1) : (c,0))
}
	
beta=z.beta
M=st_matrix("e(V)")

//exclude - last row & col to omit constant
M=select(select(M,c'),c)

diff=select(beta:-z.Beta,c)
k=sum(c)

cd=rowsum((diff*invsym(M)):*diff)/k

if (st_global("e(model)")=="fe"){
	pr_F=F(k,z.NT-z.N-z.df_b,cd)

}
if (st_global("e(model)")=="be"){
	pr_F=F(k,z.N-z.df_m-1,cd)

}
if(st_global("e(model)")=="re"){
	pr_F=F(k,z.NT-z.df_m-1,cd)

}
if(st_global("e(model)")=="ols"){
	pr_F=F(k,z.NT-z.df_m-1,cd)

}

pr_chi2=chi2(k,cd*k)
st_store(.,st_addvar("double",newvar),touse,cd)
st_store(.,st_addvar("double",newvar:+"_pr_chi2"),touse,pr_chi2)
st_store(.,st_addvar("double",newvar:+"_pr_F"),touse,pr_F)

}

//--------------------------------------------------------------------------//

void dropobs_re(struct data z)
{

//harmonic mean 
Tbar=st_numscalar("e(Tbar)")

r_old=(z.sigma_u/z.sigma_e)^2

Axx=xVx(z)
Axy=xVy(z)
Bxx=Axx-xQx(z)
Bxy=Axy-xQy(z)
Axx_inv=Mxx_re(z)

eigensystem(Axx_inv*Bxx,C=.,Lam=.)
C_inv=luinv(C)
C_inv_Axx_inv=C_inv*Axx_inv


for(i=1;i<=z.N;i++){

	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(X,J(rows(X),1,1))
	T=rows(X)
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]
	
	sig2e=panelsubmatrix(z.Sig2e,i,z.id_rows)
    sig2b=panelsubmatrix(z.Sig2b,i,z.id_rows)
	
  	Tbar_t =(T==1 ? ((z.N/Tbar-1)*(1/(z.N-1)))^-1 : (1/Tbar+1/(z.N*T*(T-1)))^-1 )
	sig2u=rowmax((sig2b-sig2e/Tbar_t,J(T,1,0)))
	
	r_new=(sig2u:/sig2e)
	m=(z.muT*r_old:+1):/(z.muT*r_new:+1)
	lambda =1:-sqrt((1:/(T*r_old:+1)):*m) 
	
	muX=e'X/T
	muy=e'y/T

	X1=(X-lambda*muX) 
	y1=(y-lambda*muy)

		
	Beta=J(T,z.K,.)

	if(T==1){
		
		M=Re(makesymmetric(C*((I(z.K)-(1-m)*diag(Lam)):^-1)*C_inv_Axx_inv))		
		
		h=X1*M*X1'
		beta=M*(Axy-(1-m)*Bxy)	
		res=(y1-X1*beta)		
		Beta=beta'-(X1*M):*(res:/(1-h))
	}

	else{

		s=((T-1)*r_new:+1):/(T*r_new:+1)	
		X1=X1-(lambda:*(1:-lambda))*muX	
		y1=y1-(lambda:*(1:-lambda))*muy
				
		for(t=1;t<=T;t++){
	
			M=Re(makesymmetric(C*((I(z.K)-(1-m[t])*diag(Lam)):^-1)*C_inv_Axx_inv))

			h=diagonal(X1[t,]*M*X1[t,]')
			beta=M*(Axy-(1-m[t])*Bxy)
			res=(y1[t]-X1[t,]*beta)
			Beta[t,.]=beta':-(X1[t,]*M):*(res:/(s[t]-h))
			
		}
	}
	
	z.Beta[st::fi,.]=Beta
	z.Sig2u[st::fi]=sig2u

}

}

//--------------------------------------------------------------------------//

void droppanel_re(struct data z)
{

//harmonic mean 
Tbar=st_numscalar("e(Tbar)")

r_old=(z.sigma_u/z.sigma_e)^2

Axx=xVx(z)
Axy=xVy(z)
Bxx=Axx-xQx(z)
Bxy=Axy-xQy(z)
Axx_inv=Mxx_re(z)

eigensystem(Axx_inv*Bxx,C=.,Lam=.)
C_inv=luinv(C)
C_inv_Axx_inv=C_inv*Axx_inv


 for(i=1;i<=z.N;i++){

 	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(X,J(rows(X),1,1))
	T=rows(X)
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]
	
	sig2e=panelsubmatrix(z.Sig2e,i,z.id_rows)
    sig2b=panelsubmatrix(z.Sig2b,i,z.id_rows)

	Tbar_i=(((z.N/Tbar)-(1/T))*(1/(z.N-1)))^-1 	
	sig2u=rowmax((sig2b-sig2e/Tbar_i,J(T,1,0)))
	
	r_new=mean(sig2u:/sig2e)
	m=(z.muT*r_old+1)/(z.muT*r_new+1)
		
	M=Re(makesymmetric(C*((I(z.K)-(1-m)*diag(Lam)):^-1)*C_inv_Axx_inv))		

	lambda=1-sqrt((1/(T*r_old+1))*m) 
	X1=X-e*(1/T)*(e'X)*lambda
	y1=y-e*(1/T)*(e'y)*lambda
	
	H=X1*M*X1'
	beta=M*(Axy-(1-m)*Bxy)

	res=(y1-X1*beta)

	z.Beta[st::fi,.]=e*(beta'-((M*X1')*invsym(I(T)-H)*res)')
	z.Sig2u[st::fi]=sig2u

}

}

//--------------------------------------------------------------------------//

real matrix Mxx_re(struct data scalar z)
{

 if (st_global("e(vce)")=="conventional") {
	M=st_matrix("e(V)")/z.rmse^2
 }
 else{
 
	M=invsym(xVx(z))
 }

 return(M)

}

//--------------------------------------------------------------------------//

void dropobs_fe(struct data z)
{

M=Mxx_fe(z)
 
df=z.NT-z.N-z.df_b
beta=select(z.beta,!e(z.K,z.K))
e_K=J(z.K-1,1,1)

for(i=1;i<=z.N;i++){
 
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	T=rows(X)
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]

	if(T==1){
	
		z.Beta[st::fi,1::z.K-1]=beta
		z.Sig2e[st::fi]=z.sigma_e^2
	}
	
	else{
	
		X1=X-e*(1/T)*(e'X)
		y1=y-e*(1/T)*(e'y)

		h=diagonal(X1*M*X1')	
		res=(y1-X1*beta')
	
		s=(T-1)/T
		z.Beta[st::fi,1::z.K-1]=beta:-(X1*M):*(res:/(e*s-h))
	
		z.Sig2e[st::fi]=((df/(df-1))*z.sigma_e^2):-(res:^2):/((s:-h)*(df-1))
	}
	
}


//overall mean without obs-it
e_NT=J(z.NT,1,1)
mu_Xit=(1/(z.NT-1))*((e_NT'z.X):-z.X)
mu_yit=(1/(z.NT-1))*((e_NT'z.y):-z.y)

//add constant
e_K=J(z.K-1,1,1)	
z.Beta[.,z.K]=mu_yit-(mu_Xit:*z.Beta[.,1::z.K-1])*e_K

}

//--------------------------------------------------------------------------//

void droppanel_fe(struct data z)
{

M=Mxx_fe(z)

df=z.NT-z.N-z.df_b
beta=select(z.beta,!e(z.K,z.K))

 for(i=1;i<=z.N;i++){

 	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	T=rows(X)
	e=J(T,1,1)
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]

	X1=X-e*(1/T)*(e'X)
	y1=y-e*(1/T)*(e'y)
	
	H=X1*M*X1'
	res=(y1-X1*beta')
	
	z.Beta[st::fi,1::z.K-1]=e*(beta-((M*X1')*invsym(I(T)-H)*res)')
	
	//mean without panel i
	e_NT=J(z.NT,1,1)
	mu_Xi=(1/(z.NT-T))*(e_NT'z.X-e'X)
	mu_yi=(1/(z.NT-T))*(e_NT'z.y-e'y)
		
	//add constant
	z.Beta[st::fi,z.K]=mu_yi:-z.Beta[st::fi,1::z.K-1]*mu_Xi'
	
	z.Sig2e[st::fi]=e*(((df/(df-T+1))*z.sigma_e^2):-(res'invsym(I(T)-H)*res)/(df-T+1))

 }

}

//--------------------------------------------------------------------------//

real matrix Mxx_fe(struct data scalar z)
{
 if (st_global("e(vce)")=="conventional") {
	M=st_matrix("e(V)")/z.rmse^2	
 }
 else{

	M=invsym(xQx(z))	
 }
 
 //exclude - last row & col to omit constant
M=select(select(M,!e(z.K, z.K)),!e(z.K, z.K)')

return(M)

}

//--------------------------------------------------------------------------//

void dropobs_be(struct data scalar z)
{

 M=Mxx_be(z)
 
 df=z.N-z.df_m-1
 beta=z.beta
 Tbar=st_numscalar("e(Tbar)")

 for(i=1;i<=z.N;i++){
	
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]
	
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	T=rows(X)
	X=(X,J(T,1,1))
	Beta=J(T,z.K,.)
	Sig2b=J(T,1,.)
	e=J(T,1,1)	

	
	if(T==1){
	
		h=X*M*X'
		res=(y-X*beta') 
		Beta=beta-(X*M)*(res/(1-h))
		
		if(st_global("e(typ)")!=""){
	
			Tbar1=(Tbar*z.N-1)/(z.N-1)
		
			//rmse = sig2b/Tbar		
			Sig2b=((Tbar/Tbar1)*(df/(df-1))*z.rmse^2)-(res^2)/((1-h)*Tbar1*(df-1))
		}
		else{
			//rmse = sig2b
			Sig2b=((df/(df-1))*z.rmse^2)-(res^2)/((1-h)*(df-1))		
		}
	}
	
	else{
	
		muX=e'X/T
		muy=e'y/T
		
		S =(st_global("e(typ)")!="" ? diag((1/T,-(T-1))) : diag((1,-(T-1)^2)))

		for(t=1;t<=T;t++){
		
			X1=(muX',(T*muX-X[t,.])')
			Y1=(muy, (T*muy-y[t]))
			
			res=Y1'-X1'*beta'	
			H=X1'*M*X1
	
			Beta[t,.]=(beta'-M*X1*luinv(S-H)*res)'
			
			if (st_global("e(typ)")!=""){
			
				Tbar1=(Tbar*z.N-1)/z.N

				//rmse = sig2b/Tbar		
				Sig2b[t,.]=(Tbar/Tbar1)*z.rmse^2-res'luinv(S-H)*res/(df*Tbar1)
			}
			else{
				//rmse = sig2b
				Sig2b[t,.]=z.rmse^2-res'luinv(S-H)*res/df
			}
			
		}
		
	}
		
	z.Beta[st::fi,.]=Beta
	z.Sig2b[st::fi]=Sig2b

 }
	

}

//--------------------------------------------------------------------------//

void droppanel_be(struct data scalar z)
{

 M=Mxx_be(z)
 
 df=z.N-z.df_m-1
 beta=z.beta
 Tbar=st_numscalar("e(Tbar)")
 
 for(i=1;i<=z.N;i++){
	
	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]
	
	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	T=rows(X)
	X=(X,J(T,1,1))
	Beta=J(T,z.K,.)
	Sig2b=J(T,1,.)
	e=J(T,1,1)	

	//between transformation means
	w=(st_global("e(typ)")!="" ? sqrt(T) : 1)
	
	mux=(1/T)*(e'X)*w
	muy=(1/T)*(e'y)*w
	h=mux*M*mux'
	res=(muy-mux*beta')
	
	z.Beta[st::fi,.]=e*(beta-(mux*M)*res/(1-h))

	if(st_global("e(typ)")!=""){

		Tbar1=(Tbar*z.N-T)/(z.N-1)
		
		//rmse = sig2b/Tbar
		z.Sig2b[st::fi]=e*((Tbar/Tbar1)*(df/(df-1))*z.rmse^2-(res^2)/((1-h)*(df-1)*Tbar1))		
	}
	else{
			
		//rmse=sig2b
		z.Sig2b[st::fi]=e*((df/(df-1))*z.rmse^2-(res^2)/((1-h)*(df-1)))
	}

 }	
	

}

//--------------------------------------------------------------------------//

real matrix Mxx_be(struct data scalar z)
{

 if (st_global("e(vce)")=="conventional") {
 
	Tbar=st_numscalar("e(Tbar)")
	
	if(st_global("e(typ)")!=""){

		M=st_matrix("e(V)")/(z.rmse^2*Tbar)
	}
	else{
	
		M=st_matrix("e(V)")/(z.rmse^2)
	}
 }
 
 else{
	
	w=(st_global("e(typ)")!="" ? 1 : 2)

	M=invsym(xPx(z,w))	
	
 }
 
 return(M)

}

//--------------------------------------------------------------------------//

void dropobs_ols(struct data z)
{

M=Mxx_ols(z)
 
beta=z.beta
e=J(z.NT,1,1)
h=J(z.NT,1,0)
 
X=(z.cons_xvars ? (z.X,J(rows(z.X),1,1)) : z.X)

 for(i=1;i<=z.NT;i++){
	h[i]=diagonal(X[i,]*M*X[i,]')
 }
 
res=(z.y-X*beta')
 
z.Beta=beta:-(X*M):*(res:/(e-h))
 

}

//--------------------------------------------------------------------------//

void droppanel_ols(struct data z)
{

M=Mxx_ols(z)
 
beta=z.beta

for(i=1;i<=z.N;i++){

	y=panelsubmatrix(z.y,i,z.id_rows)
	X=panelsubmatrix(z.X,i,z.id_rows)
	T=rows(X)
	e=J(T,1,1)

	X=(z.cons_xvars ? (X,J(T,1,1)) : X)
	
	H=X*M*X'
	res=(y-X*beta')

	st=z.id_rows[i,1]
	fi=z.id_rows[i,2]
	z.Beta[st::fi,.]=e*(beta-((M*X')*invsym(I(T)-H)*res)')
	
}

}

//--------------------------------------------------------------------------//

real matrix Mxx_ols(struct data scalar z)
{

 if (st_global("e(vce)")=="ols") {
	M=st_matrix("e(V)")/z.rmse^2

 }
 else{
 
	X=(z.cons_xvars ? (z.X,J(rows(z.X),1,1)) : z.X)
	
	M=invsym(X'X)
 }

return(M)


}

//--------------------------------------------------------------------------//

real matrix xPx(struct data scalar z, real scalar w)
{

 M=J(z.K,z.K,0)

 for(i=1;i<=z.N;i++){
	
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(z.cons_xvars ? X,J(rows(X),1,1) : X)
	T=rows(X)
	e=J(T,1,1)
	P=e*e'/(T^w)
	M=M+X'P*X
 }

 return(M)

}

//--------------------------------------------------------------------------//

real matrix xQx(struct data scalar z)
{

 M=J(z.K,z.K,0)

 for(i=1;i<=z.N;i++){
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(z.cons_xvars ? X,J(rows(X),1,1) : X)
	T=rows(X)	
	e=J(T,1,1)
	Q=I(T)-e*e'/T
	M=M+X'Q*X
 }
 
 return(M)
 
}

//--------------------------------------------------------------------------//

real matrix xQy(struct data scalar z)
{

 M=J(z.K,1,0)

 for(i=1;i<=z.N;i++){
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(z.cons_xvars ? X,J(rows(X),1,1) : X)
	y=panelsubmatrix(z.y,i,z.id_rows)
	T=rows(X)	
	e=J(T,1,1)
	Q=I(T)-e*e'/T
	M=M+X'Q*y
 }
 
 return(M)
 
}

//--------------------------------------------------------------------------//

real matrix xVy(struct data scalar z)
{

 M=J(z.K,1,0)
	
 for(i=1;i<=z.N;i++){
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(z.cons_xvars ? X,J(rows(X),1,1) : X)
	y=panelsubmatrix(z.y,i,z.id_rows)
	T=rows(X)
	e=J(T,1,1)
	Q=I(T)-e*e'/T
	phi2=(z.sigma_e^2)/(T*z.sigma_u^2+z.sigma_e^2)
	V_inv=(Q+phi2*(I(T)-Q)) 
	M=M+X'V_inv*y
 }
 
 return(M)

}

//--------------------------------------------------------------------------//

real matrix xVx(struct data scalar z)
{

 M=J(z.K,z.K,0)
	
 for(i=1;i<=z.N;i++){
	X=panelsubmatrix(z.X,i,z.id_rows)
	X=(z.cons_xvars ? X,J(rows(X),1,1) : X)
	T=rows(X)
	e=J(T,1,1)
	Q=I(T)-e*e'/T
	phi2=(z.sigma_e^2)/(T*z.sigma_u^2+z.sigma_e^2)
	V_inv=(Q+phi2*(I(T)-Q)) 
	M=M+X'V_inv*X
 }
 
 return(M)

}



end
