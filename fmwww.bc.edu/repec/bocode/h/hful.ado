*! version 2.5  2021/11/10
program define hful, eclass byable(recall) sortpreserve
	version 14
if !replay(){
	syntax [anything(name=0)] [if] [in][, noCONStant boots(real 0) modelbased casesampling wild]
	marksample touse
	tempname b V
		local n 0
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
		while `s(stop)'==0 {
			if "`paren'"=="(" {
				local ++n
				if `n'>1 { 
di as err `"syntax is "(all instrumented variables = instrument variables)""'
					exit 198
				}
				gettoken p lhs : lhs, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
di as err `"syntax is "(all instrumented variables = instrument variables)""'
di as er `"the equal sign "=" is required"'
						exit 198
					}
					local endo `endo' `p'
					gettoken p lhs : lhs, parse(" =")
				}
				local exexog `lhs'
			}
			else {
				local inexog `inexog' `lhs'
			}
			gettoken lhs 0 : 0, parse(" ,[") match(paren)
			IsStop `lhs'
		}
// lhs attached to front of inexog
		gettoken lhs inexog	: inexog
		local endo			: list retokenize endo
		local inexog		: list retokenize inexog
		local exexog		: list retokenize exexog
// If depname not provided (default) name is lhs variable
		if "`depname'"=="" {
			local depname `lhs'
		}

// partial, including legacy FWL option
		local partial		`partial' `fwl'
// Need to nonvars "_cons" from list if present
// Also set `partialcons' local to 0/1
// Need word option so that varnames with cons in them aren't zapped
		local partial		: subinstr local partial "_cons" "", all count(local partialcons) word
		local partial		: list retokenize partial
		if "`partial'"=="_all" {
			local partial	`inexog'
		}
// constant always partialled out if present in regression and other inexog are being partialled out
// (incompatibilities caught in error-check section below)
		if "`partial'"~="" {
			local partialcons	= (`cons' | `partialcons')
		}


	
mata: mywork("`lhs'", "`endo'", "`inexog'","`exexog'", "`touse'","`constant'", "`boots'", "`modelbased'","`casesampling'","`wild'",) 

	if ("`constant'"==""){
	matrix V = V'
	matrix b = b'
	matrix colnames b = _cons `inexog' `endo'
	matrix rownames b = `lhs'
	matrix colnames V = _cons `inexog' `endo'
	matrix rownames V = _cons `inexog' `endo'
	ereturn post b V, depname(`lhs') 
	}
	if ("`constant'"!=""){

		matrix V = V'
	matrix b = b'

	matrix colnames b = `inexog' `endo'
	matrix rownames b = `lhs'
	
	matrix colnames V = `inexog' `endo'
	matrix rownames V =  `inexog' `endo'
	ereturn post b V, depname(`lhs') 

	}
	
	
	
	}
	else{
	if "`e(cmd)'"!="myest" error 301
	syntax
	}
	
	ereturn display

end


program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	version 14.2
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else	sret local stop 0
end


**********************************Mata*****************************
mata:

void mywork( string scalar lhs,  string scalar endo, 
             string scalar inexog, string scalar exexog, string scalar touse,
			 string scalar constant, scalar boots , string scalar modelbased, string scalar casesampling, string scalar wild)
{

    real matrix y, X, Z
   
	y = st_data(.,lhs,touse)
	X = st_data(.,(inexog, endo),touse)
	Z = st_data(.,(inexog, exexog),touse)
	if (constant == "") {
        X = J(rows(X),1,1),X
	Z = J(rows(X),1,1),Z
    }
	/*number of bootstrap replications for the estimation of the standard errors*/
	
	if (boots == "0") {
        boot = 10000
    }
	
	if (boots != "0") {
        boot = strtoreal(boots)
    }
 
 /*seed of the random number generator*/
rseed(111) 

n=rows(X)
G=cols(X)
K=cols(Z)

/*Parameter for HFUL estimation. Must be strictly positive*/
C=1


/************************************************/
/*HFUL estimator                                */

P1=Z*luinv(Z'*Z)
S=Z'

X_bar=(y,X)

PX_barX_bar=J(G+1,G+1,0)
PXX=J(G,G,0)
PXy=J(G,1,0)

for (i=1;i<=n;i++){
PX_barX_bar=P1[i,.]*S[.,i]*X_bar[i,.]'*X_bar[i,.]+PX_barX_bar
PXX=P1[i,.]*S[.,i]*X[i,.]'*X[i,.]+PXX
PXy=P1[i,.]*S[.,i]*X[i,.]'*y[i]+PXy
}


MAT=luinv(X_bar'*X_bar)*(X_bar'*P1*S*X_bar-PX_barX_bar)
e=eigenvalues(MAT)
e=Re(e)
alpha_tilde=min(e)
 
alpha_hat=(alpha_tilde-(1-alpha_tilde)*C/n)/(1-(1-alpha_tilde)*C/n)

/*HFUL estimates*/
delta_tilde_HFUL=luinv(X'*P1*S*X-PXX-alpha_hat*X'*X)*(X'*P1*S*y-PXy-alpha_hat*X'*y)

/************************************************/
/*Variance of the HFUL estimator                */

Epsilon_hat=y-X*delta_tilde_HFUL
Gamma_hat=X'*Epsilon_hat/(Epsilon_hat'*Epsilon_hat)
X_hat=X-Epsilon_hat*Gamma_hat'
X_b1=Z*luinv(Z'*Z)
X_b2=Z'*X_hat
X_b=X_b1*X_b2
Z_tilde=Z*luinv(Z'*Z)
H_hat=X'*P1*S*X-PXX-alpha_hat*X'*X

Sigma_hat1=J(G,G,0)
for (i=1;i<=n;i++){
    Sigma_hat1=(X_b[i,.]'*X_b[i,.]-X_hat[i,.]'*P1[i,.]*S[.,i]*X_b[i,.]-X_b[i,.]'*P1[i,.]*S[.,i]*X_hat[i,.])*Epsilon_hat[i]^2+Sigma_hat1
}

Sigma_hat4=J(G,G,0)
for (k=1;k<=K;k++){
    Sigma_hat3=J(G,G,0)
    for (l=1;l<=K;l++){
        Sigma_hat21=J(G,1,0)
        Sigma_hat22=J(G,1,0)
        for (i=1;i<=n;i++){
            Sigma_hat21=(Z_tilde[i,k]*Z_tilde[i,l]*X_hat[i,.]'*Epsilon_hat[i])+Sigma_hat21
        }
        for (j=1;j<=n;j++){
            Sigma_hat22=(Z_tilde[j,k]*Z_tilde[j,l]*X_hat[j,.]'*Epsilon_hat[j])+Sigma_hat22
        }
        Sigma_hat2=Sigma_hat21*Sigma_hat22'
        Sigma_hat3=Sigma_hat3+Sigma_hat2
    }
    Sigma_hat4=Sigma_hat3+Sigma_hat4
}

Sigma_hat=Sigma_hat1+Sigma_hat4

/*Variance estimator*/
V_hat_HFUL=luinv(H_hat)*Sigma_hat*luinv(H_hat)

/*Standard error estimator*/
se_hat_HFUL=(diagonal(V_hat_HFUL)):^(1/2)


/************************************************/
/*Output depends on input*/


/*Case1: default    */
if (modelbased == "" && casesampling=="" && wild=="") {
	b = delta_tilde_HFUL
	V = V_hat_HFUL
}
  

/*Case2: case sampling    */
if (modelbased == "" && casesampling!=""&& wild=="") {

/*************************************************/
/*Bootstrap HFUL estimator (case sampling)*/
rseed(111)

delta_tilde_HFUL_b_c=J(boot,G,0)
for (s=1;s<=boot;s++){
    y_boot=J(n,1,0)
    X_boot=J(n,G,0)
    Z_boot=J(n,K,0)
    for (t=1;t<=n;t++){
        index=1+floor(n*runiform(1,1))
        y_boot[t]=Re(y[index])
        X_boot[t,.]=Re(X[index,.])
        Z_boot[t,.]=Re(Z[index,.])    
    }

    P1_boot=Z_boot*luinv(Z_boot'*Z_boot)
    S_boot=Z_boot'

    X_bar_boot=(y_boot,X_boot)

    PX_barX_bar_boot=J(G+1,G+1,0)
    PXX_boot=J(G,G,0)
    PXy_boot=J(G,1,0)

    for (i=1;i<=n;i++){
        PX_barX_bar_boot=P1_boot[i,.]*S_boot[.,i]*X_bar_boot[i,.]'*X_bar_boot[i,.]+PX_barX_bar_boot
        PXX_boot=P1_boot[i,.]*S_boot[.,i]*X_boot[i,.]'*X_boot[i,.]+PXX_boot
        PXy_boot=P1_boot[i,.]*S_boot[.,i]*X_boot[i,.]'*y_boot[i]+PXy_boot
    }

    MAT_boot=luinv(X_bar_boot'*X_bar_boot)*(X_bar_boot'*P1_boot*S_boot*X_bar_boot-PX_barX_bar_boot)
    e_boot=eigenvalues(MAT_boot)
    e_boot=Re(e_boot)
    alpha_tilde_boot=min(e_boot)
    alpha_hat_boot=(alpha_tilde_boot-(1-alpha_tilde_boot)*C/n)/(1-(1-alpha_tilde_boot)*C/n)

    delta_tilde_HFUL_boot=luinv(X_boot'*P1_boot*S_boot*X_boot-PXX_boot-alpha_hat_boot*X_boot'*X_boot)*(X_boot'*P1_boot*S_boot*y_boot-PXy_boot-alpha_hat_boot*X_boot'*y_boot)
    delta_tilde_HFUL_b_c[s,.]=Re(delta_tilde_HFUL_boot')
}

se_hat_HFUL_boot_c=diagonal(variance(delta_tilde_HFUL_b_c)):^(1/2)

b = mean(delta_tilde_HFUL_b_c)'
V = variance(delta_tilde_HFUL_b_c)
}


/*Case3: model-based    */
if (modelbased != "" && casesampling=="" && wild=="") {

/*************************************************/
/*Bootstrap HFUL estimator (model-based sampling)*/
rseed(111)

delta_tilde_HFUL_b=J(boot,G,0)
for (s=1;s<=boot;s++){
    Epsilon_hat_boot=J(n,1,0)
    for (t=1;t<=n;t++){
        Epsilon_hat_boot[t]=Re(Epsilon_hat[1+floor(n*runiform(1,1))])
    }

    y_boot=X*delta_tilde_HFUL+Epsilon_hat_boot
    X_bar_boot=(y_boot,X)

    PX_barX_bar_boot=J(G+1,G+1,0)
    PXX_boot=J(G,G,0)
    PXy_boot=J(G,1,0)

    for (i=1;i<=n;i++){
        PX_barX_bar_boot=P1[i,.]*S[.,i]*X_bar_boot[i,.]'*X_bar_boot[i,.]+PX_barX_bar_boot
        PXX_boot=P1[i,.]*S[.,i]*X[i,.]'*X[i,.]+PXX_boot
        PXy_boot=P1[i,.]*S[.,i]*X[i,.]'*y_boot[i]+PXy_boot
    }

    MAT_boot=luinv(X_bar_boot'*X_bar_boot)*(X_bar_boot'*P1*S*X_bar_boot-PX_barX_bar_boot)
    e_boot=eigenvalues(MAT_boot)
    e_boot=Re(e_boot)
    alpha_tilde_boot=min(e_boot)
    alpha_hat_boot=(alpha_tilde_boot-(1-alpha_tilde_boot)*C/n)/(1-(1-alpha_tilde_boot)*C/n)

    delta_tilde_HFUL_boot=luinv(X'*P1*S*X-PXX_boot-alpha_hat_boot*X'*X)*(X'*P1*S*y_boot-PXy_boot-alpha_hat_boot*X'*y_boot)
    delta_tilde_HFUL_b[s,.]=Re(delta_tilde_HFUL_boot')
}
    
se_hat_HFUL_boot=diagonal(variance(delta_tilde_HFUL_b)):^(1/2)


b = mean(delta_tilde_HFUL_b)'
V = variance(delta_tilde_HFUL_b)

}
	
	
/*Case4: model-based wild   */
if (modelbased == "" && casesampling=="" && wild!="") {

/*******************************************************/
/*Bootstrap HFUL estimator (model-based sampling, wild)*/
rseed(111)

delta_tilde_HFUL_bw=J(boot,G,0)
for (s=1;s<=boot;s++){
    Epsilon_hat_boot=J(n,1,0)
    for (t=1;t<=n;t++){
        Epsilon_hat_boot[t]=Re(Epsilon_hat[1+floor(n*runiform(1,1))])
    }
    Epsilon_hat_boot=Epsilon_hat_boot:*(rbinomial(n,1,1,0.5)*2-J(n,1,1))

    y_boot=X*delta_tilde_HFUL+Epsilon_hat_boot
    X_bar_boot=(y_boot,X)

    PX_barX_bar_boot=J(G+1,G+1,0)
    PXX_boot=J(G,G,0)
    PXy_boot=J(G,1,0)

    for (i=1;i<=n;i++){
        PX_barX_bar_boot=P1[i,.]*S[.,i]*X_bar_boot[i,.]'*X_bar_boot[i,.]+PX_barX_bar_boot
        PXX_boot=P1[i,.]*S[.,i]*X[i,.]'*X[i,.]+PXX_boot
        PXy_boot=P1[i,.]*S[.,i]*X[i,.]'*y_boot[i]+PXy_boot
    }

    MAT_boot=luinv(X_bar_boot'*X_bar_boot)*(X_bar_boot'*P1*S*X_bar_boot-PX_barX_bar_boot)
    e_boot=eigenvalues(MAT_boot)
    e_boot=Re(e_boot)
    alpha_tilde_boot=min(e_boot)
    alpha_hat_boot=(alpha_tilde_boot-(1-alpha_tilde_boot)*C/n)/(1-(1-alpha_tilde_boot)*C/n)

    delta_tilde_HFUL_boot=luinv(X'*P1*S*X-PXX_boot-alpha_hat_boot*X'*X)*(X'*P1*S*y_boot-PXy_boot-alpha_hat_boot*X'*y_boot)
    delta_tilde_HFUL_bw[s,.]=Re(delta_tilde_HFUL_boot')
}
    
se_hat_HFUL_boot_w=diagonal(variance(delta_tilde_HFUL_bw)):^(1/2)

b = mean(delta_tilde_HFUL_bw)'
V = variance(delta_tilde_HFUL_bw)
}
	
	
 st_matrix("V",V)
 st_matrix("b",b)
}

end
