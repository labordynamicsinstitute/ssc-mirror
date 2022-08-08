*! version 1.0.0  6feb2022
program define gtsheckman, eclass
*version 11.0
syntax varlist(fv ts) [if] [in], SELect(string) [HET(string) CLP(string) VCE(string) lambda]

*******************************************************************************
*** Parsing Syntax ************************************************************
*******************************************************************************
// Parse Varlist
	tokenize `varlist'
	local dep `1'
	macro shift
	local ind `*'
	fvrevar `ind'
	local indtemp `r(varlist)'
// Parse Selection Variables
	tokenize `"`select'"', parse(" =")
	local seldep `1'
	macro shift 2
	local selind `*'
	fvrevar `selind'
	local selindtemp `r(varlist)'
// Parse Het
	local het "`het'"
	fvrevar `het'
	local hettemp `r(varlist)'
// Parse CLP
	local clp "`clp'"
	fvrevar `clp'
	local clptemp `r(varlist)'
// Parse VCE syntax
	tokenize `"`vce'"'
	local vcetype `1'
	local clusterid `2'	
// Parse if
	tokenize `"`if'"'
	macro shift
	local ifexp `*'
	if "`ifexp'"!=""{
	local ifexp "& `ifexp'"
	}
tempname Zg sigma index d e con
tempname Ntot Nobs Nunobs Nclust
*******************************************************************************
*** Estimation ****************************************************************
*******************************************************************************		
// First Step
local vcestr ""
if ("`vcetype'"=="cluster") {
  local vcestr "vce(cluster `clusterid')"
}
quietly sum `seldep' `if' `in'
if r(mean)==r(max) | r(mean)==r(min) {
	display as error "Dependent variable never censored because of selection: model would simplify to OLS regression"
	exit 498
}

if "`het'" != ""{
	quietly hetprobit `seldep' `selind' `if' `in', het(`het') `vcestr'
	matrix V_p = e(V)
	quietly predict `Zg', index
	quietly predict `sigma', sigma
}
else{
	quietly probit `seldep' `selind' `if' `in', `vcestr'
	matrix V_p = e(V)
	quietly predict `Zg', index
	quietly gen `sigma' = 1
}
quietly gen `index'=`Zg'/`sigma'
quietly gen lambda = normalden(`index')/(normal(`index')*`sigma')
quietly gen `d' = lambda*(`sigma'*lambda + `index')
scalar `Ntot' = e(N)
quietly tab `seldep' `if' `in', matcell(count)
scalar `Nobs' = count[2,1]
scalar `Nunobs' = count[1,1]

di as text "Generalized Two Step Heckman Estimator" ///
  as text "             Number of obs ="  as result %11.0gc `Ntot'
di as text "                                                        Selected =" as result %11.0gc `Nobs' 
di as text "                                                     Nonselected =" as result %11.0gc `Nunobs' 

if "`het'" != ""{
	display as text "First-stage heteroskedastic probit estimates"
}
else{
	display as text "First-stage probit estimates"
}
ereturn display
	
// Second Step 
local vcestr ""
if ("`vcetype'"=="cluster") {
  local vcestr "vce(cluster `clusterid')"
}
else if ("`vcetype'"=="robust") {
  local vcestr "vce(robust)"
}
local clplist ""
if ("`clp'"!="") {
  fvexpand c.lambda#c.(`clp')
  local clplist `r(varlist)'
}
quietly reg `dep' `ind' lambda `clplist' if `seldep'==1 `ifexp' `in', `vcestr'
if ("`vcetype'"=="cluster") {
  scalar `Nclust' = e(N_clust)
}
matrix V_2 = e(V)
matrix alpha = _b[lambda]
	if "`clp'"!=""{
		foreach var of local clplist{
			matrix alpha =alpha\_b[`var']
		}
	}
quietly predict `e', resid

*******************************************************************************
*** Standard Errors ***********************************************************
*******************************************************************************
// Store into Mata matrices
quietly gen `con' = 1
mata: mata clear
quietly putmata Z1 = (`selindtemp') if `seldep' ==1 `ifexp' `in'
quietly putmata X = (`indtemp') if `seldep' ==1 `ifexp' `in'
quietly putmata W = (`con' `clptemp') if `seldep' ==1 `ifexp' `in'
quietly putmata `d' if `seldep' ==1 `ifexp' `in'
quietly putmata `index' if `seldep' ==1 `ifexp' `in'
quietly putmata `e' if `seldep' == 1 `ifexp' `in'
quietly putmata lambda if `seldep' == 1 `ifexp' `in'
if "`het'" != ""{
quietly putmata Z2 = (`hettemp') if `seldep' ==1 `ifexp' `in'
quietly putmata `sigma' if `seldep' ==1	 `ifexp' `in'
}
if "`vce'" == ""{
	if "`het'" == ""{
		mata: V_p = st_matrix("V_p")
		mata: alpha = st_matrix("alpha")
		mata: sig2 = (`e''*`e' + sum((W*alpha):^2:*`d'))/rows(`d')
		mata: rho = alpha/(sig2)^.5
		mata: G= (X,W:*lambda,J(rows(X),1,1))
		mata: D = ((W*alpha):*`d')*J(1,cols(Z1)+1,1):*(Z1,J(rows(Z1),1,1))
		mata: Q = (G'*D)*V_p*(G'*D)'
		mata: R = sig2*(J(rows(`d'),1, 1)-(W*rho):^2:*`d')*J(1,cols(G),1)
		mata: Var = invsym(G'*G)*(G'*(R:*G)+Q)*invsym(G'*G) 
		mata: st_matrix("Var",Var)
	}
	else{
		mata: V_p = st_matrix("V_p")
		mata: alpha = st_matrix("alpha")
		mata: sig2 = (`e''*`e' + sum((W*alpha):^2:*(`index':*lambda + lambda:^2)))/rows(`d')
		mata: rho = alpha/(sig2)^.5
		mata: G= (X,W:*lambda,J(rows(X),1,1))
		mata: D = (((W*alpha):*`d')*J(1,cols(Z1)+1,1):*(Z1,J(rows(Z1),1,1)):/(`sigma'*J(1,cols(Z1)+1,1)), -(W*alpha):*(`d':*`index' - lambda)*J(1,cols(Z2),1):*Z2)
		mata: Q = (G'*D)*V_p*(G'*D)'
		mata: R = sig2*(J(rows(`d'),1, 1)-(W*rho):^2:*(`index':*lambda+lambda:^2))*J(1,cols(G),1)
		mata: Var = invsym(G'*G)*(G'*(R:*G)+Q)*invsym(G'*G) 
		mata: st_matrix("Var",Var)
	}
}
else if "`vce'"!=""{
	if "`het'" == ""{
		mata: V_p = st_matrix("V_p")
		mata: V_2 = st_matrix("V_2")
		mata: alpha = st_matrix("alpha")
		mata: G= (X,W:*lambda,J(rows(X),1,1))
		mata: D = ((W*alpha):*`d')*J(1,cols(Z1)+1,1):*(Z1,J(rows(Z1),1,1))
		mata: Q = (G'*D)*V_p*(G'*D)'
		mata: Var = V_2 + invsym(G'*G)*(Q)*invsym(G'*G) 
		mata: st_matrix("Var",Var)
	}
	else{
		mata: V_p = st_matrix("V_p")
		mata: V_2 = st_matrix("V_2")
		mata: alpha = st_matrix("alpha")
		mata: G= (X,W:*lambda,J(rows(X),1,1))
		mata: D = (((W*alpha):*`d')*J(1,cols(Z1)+1,1):*(Z1,J(rows(Z1),1,1)):/(`sigma'*J(1,cols(Z1)+1,1)), -(W*alpha):*(`d':*`index' - lambda)*J(1,cols(Z2),1):*Z2)
		mata: Q = (G'*D)*V_p*(G'*D)'
		mata: Var = V_2 + invsym(G'*G)*(Q)*invsym(G'*G) 
		mata: st_matrix("Var",Var)
	}
}
tempname tempb tempV
mat `tempb' = e(b)
mat colnames `tempb' = `dep': 
mat `tempV' = e(V)
mat colnames `tempV' = `dep': 
mat rownames `tempV' = `dep':
marksample sample
ereturn post `tempb' `tempV', esample(`sample')

ConvertVar
display as text "Second-stage augmented regression estimates"
if "`vcetype'"!=""{
	ereturn local vcetype =  "Robust"
	ereturn local vce = "`vcetype'"
	if "`vcetype'"=="cluster"{
		ereturn local clustvar = "`clusterid'"
		ereturn scalar N_clust = `Nclust'
	}
}
ereturn scalar N = `Ntot'
ereturn scalar N_selected = `Nobs'
ereturn scalar N_nonselected = `Nunobs'
ereturn local cmd = "gtsheckman"

ereturn display

*******************************************************************************
*** Warnings ******************************************************************
*******************************************************************************

if "`het'" != ""{
	if "`vce'" == ""{
		display  "Warning: Only allow for heteroskedasticity in first stage and not in second stage, should use vce(robust) option"
	}
	if "`clp'"==""{
		display "Warning: If introducing heteroskedasticity should specify clp(varlist)"
	}
}
if "`lambda'"!="lambda" {
capture drop lambda*
}

end

capture program drop ConvertVar	
program define ConvertVar, eclass
ereturn repost V = Var
end
