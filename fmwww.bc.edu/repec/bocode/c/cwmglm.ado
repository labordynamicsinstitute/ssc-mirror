*! v4 29 Nov 2023
pro def cwmglm_estimate, eclass sortpreserve 
syntax [varlist (default=none numeric fv)] [if] [in], [k(int 2) ITERate(int 1200) start(namelist max=1) eee vee eve vve eev vev evv vvv eei vei evi vvi eii vii family(namelist) XNormal(varlist  numeric) XBINomial(varlist  numeric fv) XMULtinomial(varlist numeric) XPOIsson(varlist  numeric) NDraw(int 10) ITERATEXnorm(int 1200) CONVcrit(real 1e-5) INITial(varlist numeric) nolog noCLustertable noDEViance noMARginal noREGTable] 
version 16
**note: version 1 uses a for loop in the EM, version 2 uses a do-while
if (`k'<1) { // if the user supplied k=1 the packages aborts the estimation
di as error "k must be greater than 0"
exit 144
}

marksample touse //setting the estimation sample

local conc `xnormal' `xbinomial' `xpoisson' `xmultinomial' 
local conc_uniq: list uniq conc //list of all the covariates 
if (wordcount("`conc'")>wordcount("`conc_uniq'")) { //check wether the covariates have been specified twice or more
     di as error "there are repeated variables in options xnormal, xbinomial, xpoisson and xmultinomial"
	 foreach v of local conc_uniq { //tells the users which covariate have been repeated and exits
	  local times_v=wordcount("`conc'")-wordcount(subinstr("`conc'","`v'","",.) )
		if (`times_v'>1) di as error "variable `v' appears `times_v' times" 
	 }
 exit 144
	}



if ("`xnormal'"!="") { //checking specification of normal covariates
markout `touse' `xnormal' //reduces the estimation sample to the observation without missing values
_rmcoll `xnormal', forcedrop noconstant //rmeove collinear variables
local xnormal `r(varlist)' //final list of normal covariates
if (r(k_omitted)>0) di "collinearity found in xnormal,  see the `r(k_omitted)' above messages."
	if (wordcount("`eee' `vee' `eve' `vve' `eev' `vev' `evv' `vvv' `eei' `vei' `evi' `vvi' `eii' `vii'")>1) { //checking wether the user have specified more than one parsimoniuos model
	di as error "please choose one option between eee vee eve vve eev vev evv vvv eei vei evi vvi eii vii"
	exit 197
	}
	if  ("`eee'`vee'`eve'`vve'`eev'`vev'`evv'`vvv'`eei'`vei'`evi'`vvi'`eii'`vii'"=="") local Type="VVV" //setting VVV as the default type
	if (wordcount("`eee' `vee' `eve' `vve' `eev' `vev' `evv' `vvv' `eei' `vei' `evi' `vvi' `eii' `vii'")==1) local Type=strupper("`eee'`vee'`eve'`vve'`eev'`vev'`evv'`vvv'`eei'`vei'`evi'`vvi'`eii'`vii'") 
	if wordcount("`xnormal'")==1 & !inlist("`Type'","VVV","EEE") {
		di as error "error in xnorm: you specified only one normal covariate, please specify vvv or eee" //reminding the user that she can choose only vvv or eee if there is only a normal covariate 
		exit 144
	}
//if (`k'==1) local Type VVV	
}


if ("`xbinomial'"!="") { //checking specification of binomail covariates
markout `touse' `xbinomial'
_rmcoll `xbinomial' if `touse', forcedrop 
local xbinomial `r(varlist)'
if (r(k_omitted)>0) di "collinearity detected in xbinomial"
foreach v of local xbinomial {
	cap  assert `v'==0 | `v'==1
	if _rc {
		di as error "Error in {bf: xbinomial}. The values of {bf: `v'} are not equal to 0 or 1."
		exit _rc
		}
	}

}


if ("`xmultinomial'"!="") { //checking specification of multinomial covariates that are converted to facotr variables automatically
 markout `touse' `xmultinomial'
 _rmcoll `xmultinomial' if `touse', forcedrop 
 local xmultinomial `r(varlist)'
 if (r(k_omitted)>0) di "collinearity detected in xmultinomial"
 foreach xm of local xmultinomial {
 local xmult_factor `xmult_factor' i.`xm'
 }

local Nmult: word count `xmultinomial'
}

 if ("`xpoisson'"!="") {  //checking specification of Poisson covariates
 markout `touse' `xpoisson'
_rmcoll `xpoisson', force 
local xpoisson `r(varlist)'
if (r(k_omitted)>0) di "collinearity detected in xpoisson, see the `r(k_omitted)' above messages."
}

 
_rmcoll `xnormal' `xbinomial' `xpoisson' `xmultinomial'
if  (r(k_omitted)>0) { //final collinearity check of the options xnormal, xbinomial, xpoisson and xmultinomial combined
di as error "collinearity detected in options xnormal, xbinomial, xpoisson and xmultinomial"
exit 144
}
//preparing the GLM
if ("`varlist'"!="") {
gettoken y varlist : varlist
_fv_check_depvar `y'

_rmcoll `varlist', expand
local x `r(varlist)'
_rmdcoll `y' `x'
}
quie count if `touse'
local nobs=r(N)


if ("`family'"=="") local family gaussian //setting gaussian as default family and controlling the specification of family
else if (!inlist("`family'","gaussian","poisson","binomial")) {
di as error "Family `family' not supported. The supported families are gaussian,poisson and binomial"
exit 144
}

forval i=1/`k' { 
	tempvar posterior`i'
}


if ("`start'"=="") local start kmeans //default start is kmeans, checking the allowed initializations
if (!inlist("`start'", "randompr", "kmeans","randomid","custom") | `: word count `start''!=1) {
di as error "option start incorrectly specified: please specify start as randompr, randomid ,kmeans or custom"
exit 198
}

if ("`start'"=="randompr" | "`start'"=="randomid") { //random starting values are done in Mata whitin main(), so they are set as missing
	forval i=1/`k' {
	quie gen double `posterior`i''=.
	local zetas `zetas' `posterior`i''
	}
}
if ("`start'"=="kmeans") { //kmeans
tempvar _groups
tempname clustername
//cluster dir
cap cluster delete `clustername', zap   allvarzap   delname  allcharzap   allothers 
	if ("`y'"!="") {   
	fvrevar `x'
	cluster kmeans `y' `r(varlist)' if `touse', k(`k') gen(`_groups') name(`clustername')
	}
else cluster kmeans `conc_uniq' if `touse', k(`k') gen(`_groups') name(`clustername')


forval i=1/`k' {
quie gen double `posterior`i''=`i'.`_groups'
local zetas `zetas' `posterior`i''
}
recast double `zetas'
cluster delete `clustername', zap   allvarzap   delname  allcharzap   allothers             


}
if ("`start'"=="custom") { //custom (inputed by the user) starting values
   //confirm numeric variable `initial' 
   cap assert `:word count `initial''==`k'
   	if _rc {
	di as error "option start: `k' variables are needed for initialization"
	exit 133
	}
	local i=1
	foreach ini of local  initial {
	quie count if missing(`ini') & `touse'
	if r(N)>0 {
	di as error "option start: variable `ini' has missing values"
    exit 133
	}
	quie gen double `posterior`i''=`ini'  if `touse'
	local zetas `zetas' `posterior`i''  
	local i=`i'+1	
	}
	
	
}

//executing main; returns all the values
 mata: _cwmglm_main(`k',"`start'",`ndraw',`iterate', "`touse'" ,"`zetas'","`y'","`x'","`family'" , "`xnormal'","`Type'" , "`xbinomial'", "`xmult_factor'","`xpoisson'", `iteratexnorm', `convcrit',"`log'")

if (`converged'!=1) di "WARNING: convergence not achieved"
quie count if `touse'


//the following code returns the estimates
if ("`y'"!="") {
	ereturn post `b' `V' , esample(`touse') depname(`y') 
	ereturn local indepvars="`x'"
	//ereturn local glmcmd="glm `y' `x' [aw=`posterior'*],family(`family')"
	tempname R2
	matrix `R2'=`localdeviance'[4,1..`=`k'+1']
	ereturn matrix R2=`R2'
	ereturn matrix localdeviance=`localdeviance'
	matrix colnames `globaldeviance'=RWD EWD BD TD
	matrix rownames `globaldeviance'="Deviance" "Normalized Deviance"
	ereturn matrix globaldeviance=`globaldeviance'
	
	//ereturn matrix R_sq=`R_sq'
	if ("`family'"!="gaussian") matrix `phi0'=J(1,`k',1)
	matrix colnames `phi0'=`: colnames `cl_table'' 	
	matrix rownames `phi0'=phi0
	ereturn matrix phi0=`phi0'
}
else ereturn post , esample(`touse') 
//ereturn matrix prior=prior

if ("`xnormal'"!="") {
ereturn matrix mu=`mu'
ereturn matrix sigma=`sigma'
}
if ("`xpoisson'"!="") {
	//matrix `lambda'=`lambda''
	ereturn matrix lambda=`lambda'
	}
if ("`xbinomial'"!="") {
matrix rownames `p_binomial'=`xbinomial'
ereturn matrix p_binomial=`p_binomial'
}

if ("`xmultinomial'"!="") {
//ereturn matrix p_multi=p_multi

forval i=1/`Nmult' {
local var: word `i' of `xmultinomial'
quie levelsof `var'
matrix rownames `p_multi_`i''=`r(levels)'
matrix roweq `p_multi_`i''="`var'"

ereturn matrix p_multi_`i'=`p_multi_`i''
}
ereturn scalar nmult=`Nmult'
}
ereturn scalar N=`nobs'
ereturn scalar dof=`dof'
ereturn matrix prior=`prior'
ereturn matrix cl_table=`cl_table'
ereturn scalar ll=`ll'
ereturn scalar bic=e(dof)*ln(e(N))-2*e(ll)
ereturn scalar aic=2*e(dof)-2*e(ll)

tempname ic
matrix `ic'=e(aic),e(bic)
matrix colnames `ic'=AIC BIC
matrix rownames `ic'=""
ereturn matrix ic=`ic'

ereturn local cmd="cwmglm"
ereturn local xnormmodel=strlower("`Type'")
ereturn local xnormal="`xnormal'"
ereturn local xpoisson="`xpoisson'"
ereturn local xmultinomial="`xmultinomial'"
ereturn local xmultinomial_fv="`xmult_factor'"
ereturn local xbinomial="`xbinomial'"
ereturn scalar iteratexnorm=`iteratexnorm'
ereturn scalar convcrit= `convcrit'
ereturn local glmfamily="`family'"
ereturn scalar iterate=`iterate'
ereturn scalar k=`k'
//ereturn local posterior="`zetas'"
ereturn local predict="cwmglm_predict"
ereturn scalar converged=`converged'

if ("`converged_xnorm'"!="") ereturn scalar converged_xnorm=`converged_xnorm'

if ("`clustertable'"=="") {
matlist e(prior), title("Prior Probabilities") names(c)  border(top bottom) 
matlist e(cl_table), title("Clustering Table") names(c)  border(top bottom)
}
matlist e(ic), title("Information criteria") names(c)  border(top bottom)

//ereturn scalar dof=dof
if ("`y'"!="") {
/*	
matlist (e(deviance)\e(R_sq)), title("Deviance measures and coefficient of determination")  border(top bottom) 
di "WD: within deviance, RD: residual (within) deviance, ED: explained (within) deviance, BD: between deviance"
di "WD=ED+RD"
di "TD=RD+ED+BD"*/
if ("`deviance'"=="") {
matlist e(localdeviance), title("Local Deviance")  border(top bottom) 
matlist e(globaldeviance), title("Global Deviance")  border(top bottom) 
}
if ("`marginal'"=="") {
	if ("`xnormal'"!="") {
		matlist  e(mu), title("mean vectors of the Gaussian variables")	  border(top bottom) 
		matlist e(sigma), title("variance matrices of the Gaussian variables")	  border(top bottom) 
	}
	if ("`xpoisson'"!="") matlist e(lambda), title("means of the Poisson variables")	  border(top bottom) 
	if ("`xbinomial'"!="") matlist e(p_binomial), title("means of the Binomial variables")	  border(top bottom) 
	if ("`xmultinomial'"!="") {
		forval i=1/`Nmult' {
			matlist e(p_multi_`i'), title("means of multinomial variable")  border(top bottom) 
		}
		
		}
	di _newline	
	}

if ("`regtable'"=="") ereturn display,  noemptycells
}
ereturn local cmd="cwmglm"
end

//this program allows to display the last cwmglm estimates or to estimate
program define cwmglm, eclass 
version 16 
if "`0'"!="" cwmglm_estimate `0' //estimate
	else { // replay  border(top bottom) 
		if "`e(cmd)'"!="cwmglm" error 301
		else cwmglm_display `0'
	}
end

//this program allows to display the last cwmglm estimates
pro def cwmglm_display 
syntax [, Level(int $S_level) *]
		_get_diopts diopts, `options'

matlist e(prior), title("Prior Probabilities") names(c)  border(top bottom) 
matlist e(cl_table), title("Clustering Table") names(c)  border(top bottom)
matlist e(ic), title("Information criteria") names(c)  border(top bottom)

//ereturn scalar dof=dof
if ("`e(depvar)'"!="") {
matlist e(localdeviance), title("Local Deviance")  border(top bottom) 
matlist e(globaldeviance), title("Global Deviance")  border(top bottom) 

	ereturn display, `diopts' level(`level')
}
end 

