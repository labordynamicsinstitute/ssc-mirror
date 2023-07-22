*! Version 5.3 21July2023
*! Jean-Benoit Hardouin, Myriam Blanchin
************************************************************************************************************
* Stata program : pcm
* Estimate the parameters of the Partial Credit Model
* Version 1 : December 17, 2007 [Jean-Benoit Hardouin]
* Version 2 : July 15, 2011 [Jean-Benoit Hardouin]
* Version 2.1 : October 18th, 2011 [Jean-Benoit Hardouin] : -fixedvar- option, new presentation
* Version 2.2 : October 23rd, 2013 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 2.3 : April 10th, 2014 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 2.3 : April 10th, 2014 [Jean-Benoit Hardouin] : correction of -fixedvar- option
* Version 3 : July 6th, 2019 [Jean-Benoit Hardouin] : New version using gsem
* Version 3.1 : July 9th, 2019 [Jean-Benoit Hardouin] : Small corrections
* Version 3.2 : July 17th, 2019 [Jean-Benoit Hardouin] : Small corrections
* Version 3.3 : July 25th, 2019 [Jean-Benoit Hardouin] : -pce- option
* Version 3.4 : August 23th, 2019 [Jean-Benoit Hardouin] : Correction of a bug
* Version 3.5 : August 29th, 2019 [Jean-Benoit Hardouin] : Correction of a bug with modamax``i''
* Version 4: September 13th, 2019 [Myriam Blanchin]: addition of longitudinal pcm
* Version 4.1: September 15th, 2019 [Jean-Benoit Hardouin]: correction of a small bug in the outputs
* Version 4.2: September 27th, 2019 [Jean-Benoit Hardouin] : EQUATING
* Version 4.3: November 8th, 2019 [Jean-Benoit Hardouin] : add a constant when difficulty parameters are fixed
* Version 5: August 2nd, 2022 [Jean-Benoit Hardouin] : New MAP graph, corrected estimation of the latent trait
* Version 5.1: July 8th, 2023 [Jean-Benoit Hardouin] : Correction of the MAP graph (histogram) and residuals graphs
* Version 5.2: July 16th, 2023 [Jean-Benoit Hardouin] : Add of new graphs for Equating
* Version 5.3: July 21th, 2023 [Jean-Benoit Hardouin] : Improvement for the docx option
*
*
* Jean-benoit Hardouin, Myriam Blanchin - University of Nantes - France
* INSERM UMR 1246-SPHERE "Methods in Patient Centered Outcomes and Health Research", Nantes University, University of Tours
* jean-benoit.hardouin@univ-nantes.fr, myriam.blanchin@univ-nantes.fr
*
* News about this program : http://www.anaqol.org
*
* Copyright 2007, 2011, 2013, 2014, 2019, 2022, 2023 Jean-Benoit Hardouin, Myriam Blanchin
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************************************************/


program define pcm, rclass 
syntax varlist(min=2 numeric) [iweight] [if] [in] [, CONTinuous(varlist) CATegorical(varlist) ITerate(int 100) TOLerance(real 0.01) model DIFFiculties(name) VARiance(real -1) rsm Graphs noGRAPHItems noCORRected filesave dirsave(string) docx(string) extension(string) alpha(real 0.01)  PCE WMLiterate(int 1) GENLT(string) GENINF(string) REPlace postpce visit(varname) id(varname) eqset1(varlist) eqset2(varlist) eqset1name(string) eqset2name(string) EQGraph eqaddset1(real 0) eqaddset2(real 0) eqmultset1(real 1) eqmultset2(real 1) eqwithic eqgenscore(string)  DIMname(string) minsize(int 30) vardif(varname) itemsdif(varlist)]

version 14
preserve
tokenize `varlist'
local nbitems : word count `varlist'
marksample touse ,novarlist
*preserve

/*************************************************************************************************************
QUELQUES TESTS
*************************************************************************************************************/

if `variance'!=-1&`variance'<=0 {
	di in red "The -variance- option cannot be negative"
	exit 198
}
if `variance'!=-1&"`visit'"!="" {
	di in red "The -variance- and -visit- options cannot be used simultaneously."*
	exit 198
}
if "`genlt'"!=""|"`geninf'"!="" {
    capture confirm new variable `genlt' `genlt'_se `geninf' `genlt'_corr `genlt'_opt `genlt'_opt_se 
	if _rc!=0&"`replace'"=="" {
	    di in red "The variables `genlt', `genlt'_se, `genlt'_corr, `genlt'_opt, `genlt'_opt_se and/or `geninf' alreday exist. Please modify the -genlt- and/or -geninf- option"
		exit 198
	}
	if _rc!=0&"`replace'"!="" {
	    qui capture drop `genlt' 
		qui capture drop `genlt'_se 
		qui capture drop `geninf' 
		qui capture drop `genlt'_corr
		qui capture drop `genlt'_opt
		qui capture drop `genlt'_opt_se
	}
}
if ("`eqset1'"!=""&"`eqset2'"=="")|("`eqset1'"==""&"`eqset2'"!="") {
    di in red "The two options -eqset1- and -eqset2- must be used simultaneously"
	exit 198
}
if ("`eqset1'"!=""&"`graphs'"!="") {
    di in red "The two options -eqset1- and -graph- cannot be used simultaneously"
	exit 198
}
if "`corrected'"!="" {
	local xtitle "Latent trait"
}
else {
	local xtitle "Corrected latent trait"
}



/*************************************************************************************************************
GESTION DES VARIABLES CONTINUES ET CATEGORIELLES
*************************************************************************************************************/
if "`visit'"!=""{
	if "`id'"==""{
		di in red "Option -visit- must be combined with option -id-. Please fill in the -id- option"
		exit 198
	}
	qui levelsof `visit'
	local levelsofv `r(levels)'
	local nbvisits=r(r)
	local timemin: word 1 of `levelsofv'
	local timemax: word `nbvisits' of `levelsofv'
	if `timemax'>5{
		di as error "You must use a discrete time variable (-visit- option) with less than 5 measurement occasions"
		error 198
	}
	if `timemin'!=1{
		di as error "You must use a -visit- variable coded at 1 for the first visit"
		error 198
	}
	qui reshape wide `varlist', i(`id') j(`visit')
	local multivisit=1
}
else {
	local timemax=1
	foreach i in `varlist' {
	   *rename `i' `i'1
	}
	local multivisit
}
qui count if `touse'
local nbobs=r(N)

local timelist
forvalues t=1/`timemax'{
	local timelist `timelist' T`t'
}

local modcont
local premodcont
local nbpar=0
local nbcont=0
local nbcat=0
if "`continuous'"!="" {
	tokenize `continuous'
	local nbcont : word count `continuous'
	local continuous
	forvalues i=1/`nbcont' {
		local cont`i' ``i''
		local continuous `continuous' ``i''
		local modcont `modcont' ``i''
	    local ++nbpar
	}
	local premodcont (`modcont'->T1)
	local modcont (`modcont'->`timelist')
}

local modcat
local premodcat
if "`categorical'"!="" {
	tokenize `categorical'
	local nbcat : word count `categorical'
	local categorical
	forvalues i=1/`nbcat' {
		local cat`i' ``i''
		local categorical `categorical' ``i''
		local modcat `modcat' i.``i''
		qui levelsof ``i''
		local levelsof``i'' `r(levels)'
		local nbpar=`nbpar'+`r(r)'-1
	    *di "categorical : ``i'' levels : `levelsof``i'''"
	}
	local premodcat (`modcat'->T1)
	local modcat (`modcat'->`timelist')
}


if "`dirsave'"=="" {
   local dirsave `c(pwd)'
}

/*************************************************************************************************************
GESTION DES ITEMS ET TESTS
*************************************************************************************************************/

tokenize `varlist'
local modamax=1
local modamin=0
local pbmin
local nbdiff=0
local scoremax=0
forvalues i=1/`nbitems' {
	local modamax`i'=1
	local modamax``i''=1
	if `timemax'>1 {
		forvalues t=1/`timemax'{
			 *qui replace ``i'`t''=``i'`t''-`min' 
			 qui su ``i''`t' if `touse'
			 if `r(min)'!=`modamin' {
				 local modamin=r(min)
				 local pbmin `pbmin' ``i'`t''
			 }
			 if `r(max)'>`modamax' {
				 local modamax=r(max)
			 }
			 if `r(max)'>`modamax`i'' {
				local modamax`i'=r(max)
			}
		}
	}
	else {
		*di "i: `i' ``i''"
		qui su ``i'' if `touse'
		if `r(min)'!=`modamin' {
		    local modamin=r(min)
			local pbmin `pbmin' ``i''
		}
		if `r(max)'>`modamax' {
			local modamax=r(max)
		}
		if `r(max)'>`modamax`i'' {
			local modamax`i'=r(max)
			local modamax``i''=r(max)
		}
	}
	*di "local scoremax=`scoremax'+`modamax`i''"
	local scoremax=`scoremax'+`modamax`i''
	if "`rsm'"=="" {
		local nbdiff=`nbdiff'+`modamax`i''
	}
}
if "`rsm'"!="" {
   local nbdiff=`nbitems'+`modamax'-1
}
if `modamin'!=0 {
   di as error "The minimal answer category of each item must be coded by 0. This is not the case for the following items: `pbmin' (`modamin') "
   error 198
}
qui count if `touse'
local nbind=r(N)
*set trace on
local code
local precode
if `timemax'>1 {
	forvalues k=1/`modamax' {
	   forvalues t=1/`timemax'{
			local code`k'
		   forvalues i=1/`nbitems' {
			   if `k'<=`modamax`i'' {
				  local code`k' `code`k'' `k'.``i''`t'
			   }
		   }
		   local code`k' (`code`k''<-T`t'@`k')
		   if `t'==1{
				local precode `precode' `code`k''
		   }
		   local code `code' `code`k''
		}
	}
}
else {
	forvalues k=1/`modamax' {
		local code`k'
		forvalues i=1/`nbitems' {
			if `k'<=`modamax`i'' {
				local code`k' `code`k'' `k'.``i''
			}
		}
		local code`k' (`code`k''<-T1@`k')
		local precode `precode' `code`k''
		local code `code' `code`k''
	}
}

/*************************************************************************************************************
OPTION PCE
*************************************************************************************************************/

if "`pce'"!=""&"`difficulties'"==""&"`visit'"=="" {
    tempname sedelta b
	qui raschpce `varlist' if `touse'
	local ll=r(ll)
	matrix `sedelta'=r(sedelta)
	matrix `sedelta'=`sedelta''
	matrix `b'=r(b)
	*matrix `b'=`b''
	local difficulties `b'
	*matrix list `b'
	matrix loulou=`b'
	return matrix diff_parm=`b'
	`qui' pcm `varlist' if `touse', diff(loulou)  geninf(TInf_0) genlt(lt_0) /*postpce*/
	*exit
}


/*************************************************************************************************************
RECUPERATION DES PARAMETRES DE DIFFICULTES ET DEFINITION DES CONTRAINTES
*************************************************************************************************************/
if "`difficulties'"!=""&"`rsm'"!="" {
   di as error "You can not defined in the same time the difficulties and the rsm options"
   error 198
}
local t=1
local constraints
local codemean
local codevar
local codecov
forvalues j=2/`timemax'{
	forvalues i=1/`nbitems' {
		forvalues k=1/`modamax`i'' {
			qui constraint `t' [`k'.``i''`j']_cons=[`k'.``i''`multivisit']_cons
			local constraints `constraints' `t'
			local ++t
			
		}
	}	
	if "`continuous'"=="" &  "`categorical'"==""{
		local codemean `codemean' T`j'@m`j'
		local codevar `codevar' T`j'@v`j'
		forvalues l=1/`=`j'-1'{
			local codecov `codecov' T`l'*T`j'@cov`l'`j'
		}
	}
	else{
		local codevar `codevar' e.T`j'@v`j'
		forvalues l=1/`=`j'-1'{
			local codecov `codecov' e.T`l'*e.T`j'@cov`l'`j'
		}	
	}
}
if `timemax'>1{
	if "`continuous'"=="" &  "`categorical'"==""{	
		local codelg means(T1@0 `codemean') var(T1@v1 `codevar') cov(`codecov')
	}
	else{
		local codelg var(e.T1@v1 `codevar') cov(`codecov')
	}
}
else {
    local constrvar
    if `variance'>0 {
		if "`continuous'"=="" &  "`categorical'"==""{	
			local constrvar var(T1@`variance') 
		}
		else{ 
			*local constrvar var(e.T1@`variance') 
		}
	}
}

local fixedmean
if "`difficulties'"!="" {
    tempname beta
	matrix `beta'=J(`nbitems',`modamax',.)
	matrix list `difficulties'
	forvalues i=1/`nbitems' {
		forvalues k=1/`modamax`i'' {
			if `difficulties'[`i',`k']==. {
				 di as error "The kth difficulty parameter of the item ``i'' is not correctly defined in the difficulties matrix"
				 error 198
			}
			else {
				if `k'==1 {
					matrix `beta'[`i',1]=-`difficulties'[`i',1]
  			    }
				else {
				    matrix `beta'[`i',`k']=`beta'[`i',`=`k'-1']-`difficulties'[`i',`k']
				}
				qui constraint `t' [`k'.``i''`multivisit']_cons=`beta'[`i',`k']
				local constraints `constraints' `t'
				local ++t
			}
		}
	}
	if "`continuous'"=="" &  "`categorical'"=="" {	
		local fixedmean mean(T1) 
	}
	else{
		local fixedmean 
	}
}



/*************************************************************************************************************
DEFINITION DES CONTRAINTES POUR UN RSM
*************************************************************************************************************/
if "`rsm'"!="" {
   local constraints
   forvalues k=2/`modamax' {
       forvalues i=2/`nbitems' {
	       qui constraint `t'   [`=`k'-1'.``i''`multivisit']_cons-[`k'.``i''`multivisit']_cons+[1.``i''`multivisit']_cons=[`=`k'-1'.`1'1]_cons-[`k'.`1'1]_cons+[1.`1'1]_cons
		   local constraints `constraints' `t'
		   local ++t
	   }
   }
}

/*************************************************************************************************************
MODELE
*************************************************************************************************************/


discard
*di "`qui' gsem `code' `modcont' `modcat' ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `codelg' "
if "`model'"!="" {
    local qui
}
else {
	local qui qui
}
if `timemax'==1{
   *di "`qui' gsem `code' `modcont' `modcat' ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `constrvar' `fixedmean'"
   `qui' gsem `code' `modcont' `modcat' if `touse' ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `constrvar' `fixedmean'
   *qui gen un=1
   *`qui' gsem `code' (i.group un->T) ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `constrvar' `fixedmean'
}
else{
    *di "`qui' gsem `precode' `premodcont' `premodcat',iterate(`iterate') tol(`tolerance') "
    `qui' gsem `precode' `premodcont' `premodcat' if `touse',iterate(`iterate') tol(`tolerance') constraint(`constraints') 
     matrix esti_B = e(b)
    *di "`qui' gsem `code' `modcont' `modcat' ,iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `codelg' from(esti_B,skip)"
    `qui' gsem `code' `modcont' `modcat' if `touse',iterate(`iterate') tol(`tolerance') constraint(`constraints') latent(`timelist') `codelg' from(esti_B,skip)
}
local ll=e(ll)

*set trace on
tempvar latent score group selatent latent2 miss
tempname groups
*capture qui predict mu, mu
*su mu 
qui predict `latent'* if `touse',latent se(`selatent'*)
*di "latent=`latent' "
*su
*set trace on

if "`genlt'"!="" {
	if `timemax'==1 {
		qui gen `genlt'=`latent'1 if `touse'
		qui gen `genlt'_se=`selatent'1 if `touse'
	}
	forvalues t=2/`timemax' {
		qui gen `genlt'`t'=`latent'`t' if `touse'
		qui gen `genlt'`t'_se=`selatent'`t' if `touse'
	}
}

set seed 123456
if `timemax'>1 {
	forvalues t=1/`timemax'{
		qui gen `latent2'`t'=`latent'`t'+invnorm(uniform())*`selatent'`t' if `touse'
		local listit 
		forvalues i=1/`nbitems' {
			local listit `listit' ``i''`t'
		}
		qui genscore `listit' if `touse',score(`score'`t')
		qui gengroup `latent'`t' if `touse',newvariable(`group'`t') continuous minsize(`minsize')
	}
}
else {
	qui gen `latent2'=`latent'1+invnorm(uniform())*`selatent'1 if `touse'
	local listit 
	forvalues i=1/`nbitems' {
		local listit `listit' ``i''
	}
	qui genscore `listit' if `touse',score(`score')
	qui gengroup `latent'1 if `touse',newvariable(`group') continuous minsize(`minsize')
}
forvalues s=0/`scoremax' {
    qui count if `score'==`s'&`touse'
	local effscore`s'=r(N)
}


/*time 1 only*/
qui levelsof `group'`multivisit' if `touse'
local nbgroups=r(r)
matrix `groups'=J(`nbgroups',`=`nbitems'+6',.)
forvalues g=1/`nbgroups' {
	matrix `groups'[`g',`=`nbitems'+3']=0
	qui count if `group'`multivisit'==`g'&`touse'
	local effgroup`g'=r(N)
	forvalues i=1/`nbitems' {
			qui count if ``i''`multivisit'!=.&`group'`multivisit'==`g'&`touse'
			local n=r(N)
			if `n'>0 {
				qui su ``i''`multivisit' if `group'`multivisit'==`g'&`touse'
				matrix `groups'[`g',`i']=r(mean)
				matrix `groups'[`g',`=`nbitems'+3']=`groups'[`g',`=`nbitems'+3']+`r(mean)'
			}
			else {
				matrix `groups'[`g',`i']=.
				matrix `groups'[`g',`=`nbitems'+3']=.
			}		
	}
	qui su `latent'1 if `group'`multivisit'==`g'&`touse'
	matrix `groups'[`g',`=`nbitems'+1']=r(mean)
	qui count if `group'`multivisit'==`g'&`touse'
	matrix `groups'[`g',`=`nbitems'+2']=r(N)
	qui su `score' if `group'`multivisit'==`g'&`score'!=.&`touse'
	matrix `groups'[`g',`=`nbitems'+4']=r(min)
	matrix `groups'[`g',`=`nbitems'+5']=r(max)	
}

/*number of non-missing on all time points*/
egen `miss'=rowmiss(`score'*) if `touse'
qui count if `miss'==0&`touse'
local nbobsssmd=r(N)
drop `miss'	

di
di as text "Number of individuals:" %6.0f as result `nbobs'
di as text "Number of complete individuals:" %6.0f as result `nbobsssmd'
di as text "Number of items:" %6.0f as result `nbitems'

di as text "Marginal log-likelihood:" %12.4f as result `ll'
di 
return scalar ll=`ll'



*set trace on
/*************************************************************************************************************
RECUPERATION DES ESTIMATIONS DES PARAMETRES DE DIFFICULTE
*************************************************************************************************************/

tempname diff diffmat vardiff diffmat2
*set trace on
qui matrix `diffmat'=J(`nbitems',`modamax',.)
qui matrix `diffmat2'=J(`nbitems',`modamax',.)
qui matrix `diff'=J(`nbdiff',6,.)
local rn
*qui matrix `vardiff'=J(`nbdiff',`nbdiff',.)
*matrix list `diff'
*set trace on
local t=1
forvalues i=1/`nbitems' {
    qui matrix `diffmat'[`i',1]=-_b[1.``i''`multivisit':_cons]
    qui matrix `diffmat2'[`i',1]=-_b[1.``i''`multivisit':_cons]
	qui lincom -_b[1.``i''`multivisit':_cons]
    qui matrix `diff'[`t',1]=`r(estimate)'
    qui matrix `diff'[`t',2]=`r(se)'
    qui matrix `diff'[`t',3]=`r(z)'
    qui matrix `diff'[`t',4]=`r(p)'
    qui matrix `diff'[`t',5]=`r(lb)'
    qui matrix `diff'[`t',6]=`r(ub)'
	local rn `rn' 1.``i''`multivisit'
	local ++t
	local sum _b[1.``i''`multivisit':_cons]
	if "`rsm'"=="" {
	    forvalues k=2/`modamax`i'' {
			local sum "_b[`k'.``i''`multivisit':_cons]-(`sum')"
			*di "``i''`multivisit' `k' `sum'"
			local sum2 "_b[`=`k'-1'.``i''`multivisit':_cons]-_b[`k'.``i''`multivisit':_cons]"
			qui lincom (`sum2')
			*set trace on
			qui matrix `diffmat'[`i',`k']=`r(estimate)'
			qui matrix `diffmat2'[`i',`k']=`diffmat2'[`i',`=`k'-1']+`diffmat'[`i',`k']
			qui matrix `diff'[`t',1]=`r(estimate)'
			qui matrix `diff'[`t',2]=`r(se)'
			qui matrix `diff'[`t',3]=`r(z)'
			qui matrix `diff'[`t',4]=`r(p)'
			qui matrix `diff'[`t',5]=`r(lb)'
			qui matrix `diff'[`t',6]=`r(ub)'
			*qui matrix `vardiff'[`t',`t']=`r(se)'^2
			*set trace off
			local rn `rn' `k'.``i''`multivisit'
			local ++t
		}
    }
}
if "`rsm'"!="" {
    forvalues k=2/`modamax' {
		qui lincom _b[`=`k'-1'.`1'`multivisit':_cons]-_b[`k'.`1'`multivisit':_cons]+_b[1.`1'`multivisit':_cons] /*``i'' instead of `i'?*/
		qui matrix `diff'[`t',1]=`r(estimate)'
		qui matrix `diff'[`t',2]=`r(se)'
		qui matrix `diff'[`t',3]=`r(z)'
		qui matrix `diff'[`t',4]=`r(p)'
		qui matrix `diff'[`t',5]=`r(lb)'
		qui matrix `diff'[`t',6]=`r(ub)'
		forvalues i=1/`nbitems' {
		    qui matrix `diffmat'[`i',`k']=`diff'[`t',1]+`diffmat'[`i',1]
		    qui matrix `diffmat2'[`i',`k']=`diffmat'[`i',`k']+`diffmat2'[`i',`=`k'-1']
		}
		local rn `rn' tau`k'
		local ++t
	}
}
local cn Estimate S.e. z p "Lower bound" "Upper Bound"
matrix colnames `diff'=`cn'
matrix rownames `diff'=`rn'
*matrix list `diff'
*matrix list `diffmat'
*matrix list `diffmat2'
*matrix list `vardiff'

/*************************************************************************************************************
RECUPERATION DES ESTIMATIONS DES PARAMETRES POUR LES COVARIABLES, MOYENNES ET VARIANCES
*************************************************************************************************************/
tempname covariates
local nbcov=0
forvalues j=2/`timemax'{
	local nbcov=`nbcov'+`j'-1
}
qui matrix `covariates'=J(`=`nbpar'+`timemax'+2*`nbcov'',6,.)

*set trace on
local t=1


forvalues j=1/`=`timemax'-1'{
	forvalues k=`=`j'+1'/`timemax'{
		if "`categorical'"=="" & "`continuous'"=="" {
			if `j'==1{
				qui lincom [/]mean(T`k')
			}
			else{
				qui lincom [/]mean(T`k')-[/]mean(T`j')
			}
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
		else{
			if "`categorical'"!=""{
				local first=0 
				foreach l in `levelsof`cat1'' {
					if `first'==0 {
						local ++first
					}
					else{
						if `first'==1 {
							qui lincom [T`k']`l'.`cat1'-[T`j']`l'.`cat1'
							qui matrix `covariates'[`t',1]=`r(estimate)'
							qui matrix `covariates'[`t',2]=`r(se)'
							qui matrix `covariates'[`t',3]=`r(z)'
							qui matrix `covariates'[`t',4]=`r(p)'
							qui matrix `covariates'[`t',5]=`r(lb)'
							qui matrix `covariates'[`t',6]=`r(ub)'
							local ++t
							local ++first
						}
					}
				}
			}
			else{
				qui lincom [T`k']`cont1'-[T`j']`cont1'
				qui matrix `covariates'[`t',1]=`r(estimate)'
				qui matrix `covariates'[`t',2]=`r(se)'
				qui matrix `covariates'[`t',3]=`r(z)'
				qui matrix `covariates'[`t',4]=`r(p)'
				qui matrix `covariates'[`t',5]=`r(lb)'
				qui matrix `covariates'[`t',6]=`r(ub)'
				local ++t
			}		
		}
	}
}	
		
forvalues j=1/`timemax'{
	if "`continuous'"!=""|"`categorical'"!="" {
		qui lincom _b[/var(e.T`j')]
	}
	else {
		qui lincom _b[/var(T`j')]
	}
	qui matrix `covariates'[`t',1]=`r(estimate)'
	qui matrix `covariates'[`t',2]=`r(se)'
	qui matrix `covariates'[`t',3]=`r(z)'
	qui matrix `covariates'[`t',4]=`r(p)'
	qui matrix `covariates'[`t',5]=`r(lb)'
	qui matrix `covariates'[`t',6]=`r(ub)'
	local ++t
}
forvalues j=1/`=`timemax'-1'{
	if "`continuous'"!=""|"`categorical'"!="" {
		forvalues k=`=`j'+1'/`timemax'{
			qui lincom _b[/cov(e.T`j',e.T`k')]
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
	}
	else{
		forvalues k=`=`j'+1'/`timemax'{
			qui lincom _b[/cov(T`j',T`k')]
			qui matrix `covariates'[`t',1]=`r(estimate)'
			qui matrix `covariates'[`t',2]=`r(se)'
			qui matrix `covariates'[`t',3]=`r(z)'
			qui matrix `covariates'[`t',4]=`r(p)'
			qui matrix `covariates'[`t',5]=`r(lb)'
			qui matrix `covariates'[`t',6]=`r(ub)'
			local ++t
		}
	}
}
forvalues i=1/ `nbcont' {
   qui lincom `cont`i''
   qui matrix `covariates'[`t',1]=`r(estimate)'
   qui matrix `covariates'[`t',2]=`r(se)'
   qui matrix `covariates'[`t',3]=`r(z)'
   qui matrix `covariates'[`t',4]=`r(p)'
   qui matrix `covariates'[`t',5]=`r(lb)'
   qui matrix `covariates'[`t',6]=`r(ub)'
   local ++t
}
forvalues i=1/ `nbcat' {
   local first=0
   foreach j in `levelsof`cat`i''' {
	   if `first'==0 {
	      local ++first
	   }
	   else {
		   qui	lincom `j'.`cat`i''
		   qui matrix `covariates'[`t',1]=`r(estimate)'
		   qui matrix `covariates'[`t',2]=`r(se)'
		   qui matrix `covariates'[`t',3]=`r(z)'
		   qui matrix `covariates'[`t',4]=`r(p)'
		   qui matrix `covariates'[`t',5]=`r(lb)'
		   qui matrix `covariates'[`t',6]=`r(ub)'
		   local ++t
	   }
   }
}
*matrix list `covariates'


/*************************************************************************************************************
OUTPUTS
*************************************************************************************************************/

if "`postpce'"=="" {
	local t=1
	local diffname
	*set trace on
	di "{hline 83}"
	di  as text _col(70) "<--95% IC -->"
	di   _col(70) "Lower" _col(78) "Upper"
	di "Items" _col(22) "Threshold" _col(35) "Estimate" _col(47) "s.e." _col(58) "z" _col(66) "p" _col(69) " Bound" _col(78) "Bound"
	di "{hline 83}"
	*set trace on
	forvalues i=1/`nbitems' {
	   *local l=1
	   forvalues j=1/`modamax`i'' {
		  if "`rsm'"==""|`j'==1 {
			  if `j'==1 {
				 di as text abbrev("``i''",19) _c
			  }
			  di as text _col(30) %5.2f "`j'" as result _col(38) %5.2f `diff'[`t',1]  _col(46) %5.2f `diff'[`t',2] _col(54) %5.2f `diff'[`t',3] _col(62) %5.2f `diff'[`t',4] _col(70) %5.2f `diff'[`t',5] _col(78) %5.2f `diff'[`t',6] 
			  local ++t
			  *local ++l
			  local diffname `diffname' `j'.``i''
		  }
	   }
	}
	if "`rsm'"!="" {
		forvalues k=2/`modamax' {
			di as text "tau`k'"  as result _col(38) %5.2f `diff'[`t',1]  _col(46) %5.2f `diff'[`t',2] _col(54) %5.2f `diff'[`t',3] _col(62) %5.2f `diff'[`t',4] _col(70) %5.2f `diff'[`t',5] _col(78) %5.2f `diff'[`t',6] 
			local diffname `diffname' tau`k'
			local ++t
		}
	}
	di as text "{hline 83}"
	local t=1
	local listmoy
	local listvar
	local listcov
	forvalues j=1/`timemax'{
		local listvar `listvar' Variance_T`j'
		forvalues k=`=`j'+1'/`timemax'{
			local listcov `listcov' Cov_T`j'_T`k'
		}
		forvalues k=`=`j'+1'/`timemax'{
			local listmoy `listmoy' Mean_diff_T`j'_T`k'
		}
	}
	local n: word count `listmoy' `listvar' `listcov' `continuous' 
	forvalues i=1/`n' {
		local v: word `i' of `listmoy' `listvar' `listcov' `continuous' 
		di as text _col(1) %5.2f "`v'" as result _col(38) %5.2f `covariates'[`t',1]  _col(46) %5.2f `covariates'[`t',2] _col(54) %5.2f `covariates'[`t',3] _col(62) %5.2f `covariates'[`t',4] _col(70) %5.2f `covariates'[`t',5] _col(78) %5.2f `covariates'[`t',6] 
		local ++t
	}

	local rn Variance `continuous'

	local n: word count of  `categorical' 
	local catname
	forvalues i=1/`n' {
		local v: word `i' of `categorical'
		local first=1
		local saute=1
		foreach j in `levelsof`cat`i''' {
			if `saute'==0 {
				if `first'==1 {
					di as text _col(1) abbrev("`v'",19) _c
				}
				di  as text _col(30) %5.2f "`j'" as result _col(38) %5.2f `covariates'[`t',1]  _col(46) %5.2f `covariates'[`t',2] _col(54) %5.2f `covariates'[`t',3] _col(62) %5.2f `covariates'[`t',4] _col(70) %5.2f `covariates'[`t',5] _col(78) %5.2f `covariates'[`t',6] 
				local ++first
				local rn `rn' `j'.`n'
				local ++t
				local catname `catname' `j'.`v'
			}
			else {
			   local saute=0
			}
		}
		*local ++t
	}
	di as text "{hline 83}"
	if "`visit'"==""{
		di
		qui su `latent'1 if `touse'
		*qui local PSI=1-(`r(sd)')^2/((`covariates'[1,1])+(`r(sd)')^2)
		*di as text "Variance of the estimated latent variable: " as result %4.2f `=(`r(sd)')^2'
        tempvar se2latent
		qui gen `se2latent'=(`selatent'1)^2 if `touse'
		qui su `se2latent' if `touse'
		local resvar=r(mean)
		di as text "Mean squared std error of the latent variable: " as result %4.2f `resvar'
		di as text "Global variance of the latent variable: " as result %4.2f `=((`covariates'[1,1])+(`resvar'))'
		local PSI=(`covariates'[1,1])/((`covariates'[1,1])+(`resvar'))
		di as text "PSI: " as result %4.2f `PSI' _c
		if "`continuous'"!=""|"`categorical'"!="" {
		    di as text " (without adjustment on covariates)"
	    }
		else {
		    di
		}
		di
		return scalar PSI=`PSI'

	}



	matrix colnames `covariates'=`cn'
	matrix rownames `covariates'=`rn'
}


/*************************************************************************************************************
ESTIMATION OF THE CORRECTED VALUES OF THE LT ESTIMATORS (values of lt that explained the best the score)
**************************************************************************************************************/
*set trace on
tempfile savefile
qui save `savefile'

qui drop _all
		
qui set obs 2000
qui gen u=(_n-1000)/200*`=sqrt(`covariates'[1,1])'
qui gen Tcum=0
qui gen TInf=0
forvalues i=1/`nbitems' {
		local d=1
		qui gen cum``i''=0
		if "`rsm'"=="" {
			local mm=`modamax`i''
		}
		else {
			local mm `modamax'
		}	
		forvalues k=1/`mm' {
			local d `d'+exp(`k'*u-`diffmat2'[`i',`k'])
		}
		qui gen c0_``i''=1/(`d')
		forvalues k=1/`mm' {
			qui gen c`k'_``i''=exp(`k'*u-`diffmat2'[`i',`k'])/(`d')
			qui replace cum``i''=cum``i''+c`k'_``i''*`k'
		}
		qui gen Inf``i''=0
		forvalues k=1/`mm' {
			qui replace Inf``i''=Inf``i''+(`k'-cum``i'')^2*c`k'_``i''
		}
		*set trace on
		qui replace Tcum=Tcum+cum``i''
		qui replace TInf=TInf+Inf``i''	
	    local scoremax=0
		forvalues l=1/`nbitems' {
		      local scoremax=`scoremax'+`modamax`l''
	    }
		qui gen ecart=.
		forvalues l=0/`scoremax' {
		    if `l'==0 {  
			   local j=0.25
			}
			else if `l'==`scoremax' {
			   local j=`scoremax'-0.25
			}
			else {
			   local j=`l'
			}
		    qui replace ecart=abs(Tcum-`j')
		    qui su ecart
			local tmp=r(min)
			qui su u if round(ecart, 0.01)==round(`tmp',0.01)
			local estlt`l'=`r(mean)'
			*qui su TInf if round(ecart, 0.01)==round(`tmp',0.01)
			*local setlt`l'=sqrt(1/`r(mean)')
		}
		qui drop ecart
}
qui use `savefile', clear


*set trace on
/*************************************************************************************************************
FIT TESTS
*************************************************************************************************************/

/*Quelques explications
latent : estimation EAP du trait latent
latent2 : estimation Plausible Value à partir de l'estimation EAP
corrlatent : estimation corrigée cherchant la meilleur valeur du trait latent qui explique le score, interpolation à partir de l'EAP pour les individus avec des données manquantes
*/


if "`visit'"==""{
	tempvar corrlatent corrlatenttmp 
	qui gen `corrlatenttmp'=.
	forvalues s=0/`scoremax' {
	    qui replace `corrlatenttmp'=`estlt`s'' if `score'==`s'
	}
	qui ipolate `corrlatenttmp' `latent'1 , generate(`corrlatent') epolate
	*list `corrlatenttmp' `latent2' `corrlatent' 
	qui replace `corrlatent'=`corrlatenttmp' if `corrlatenttmp'!=.
	*su  `corrlatenttmp' `latent2' `corrlatent' 
    *twoway (scatter `corrlatent' `score') (scatter `latent2' `score') 
	
	tempname fit
	qui matrix `fit'=J(`nbitems',6,.)
	matrix colnames `fit'=OUTFIT INFIT "Standardized OUTFIT" "Standardized INFIT" "corrOUTFIT" "corrINFIT"
	matrix rownames `fit'=`varlist'
	*matrix list `fit'

	tempvar Tcum TInf cum
	qui gen `Tcum'=0 if `touse'
	qui gen `TInf'=0 if `touse'
	if "`postpce'"=="" {
		di as text "{hline 90}"
		di as text _col(60) "<---  Standardized   --->"
		di as text "Items" _col(34) "OUTFIT" _col(50) "INFIT" _col(64) "OUTFIT" _col(80) "INFIT"
		di as text "{hline 90}"
		di as text "Referenced values*" _col(29) "[" %4.2f `=1-6/sqrt(`nbobs')' ";" %4.2f `=1+6/sqrt(`nbobs')' "]" _col(44) "[" %4.2f `=1-2/sqrt(`nbobs')' ";" %4.2f `=1+2/sqrt(`nbobs')' "]" _col(60) "[-2.6;2.6]" _col(75) "[-2.6;2.6]"
		di as text "Referenced values**" _col(29) "[0.75;1.30]" _col(44) "[0.75;1.30]" _col(60) "[-2.6;2.6]" _col(75) "[-2.6;2.6]"
		di as text "{hline 90}"
	}
	*set trace on
	local chi2=0
	local chi2_old=0
	forvalues g=1/`nbgroups' {
	   local chi2_g`g'=0
	   local chi2_old_g`g'=0
	}
	forvalues i=1/`nbitems' {
		if "`rsm'"=="" {
			local mm=`modamax`i''
		}
		else {
			local mm `modamax'
		}	
		tempvar cum_old``i'' c_old0_``i'' Inf_old``i'' y_old``i'' y2_old``i''  	
		tempvar cum``i'' c0_``i'' Inf``i'' C``i'' C2``i'' C3``i'' y``i'' y2``i'' z``i'' z2``i'' i``i'' 
		tempvar corrcum``i'' corrc0_``i'' corrInf``i'' corry``i'' corrz``i'' corrz2``i'' corri``i'' 

		local d=1
		local corrd=1
		local d_old=1
		qui gen `corrcum``i'''=0 if `touse'
		qui gen `cum``i'''=0 if `touse'
		qui gen `cum_old``i'''=0 if `touse'
		forvalues k=1/`mm' {
			local corrd `corrd'+exp(`k'*`corrlatent'-`diffmat2'[`i',`k'])
			local d `d'+exp(`k'*`latent2'-`diffmat2'[`i',`k'])
			local d_old `d_old'+exp(`k'*`latent'1-`diffmat2'[`i',`k'])
		}
		qui gen `corrc0_``i'''=1/(`corrd') if `touse' 
		qui gen `c0_``i'''=1/(`d') if `touse' 
		qui gen `c_old0_``i'''=1/(`d_old') if `touse'
		forvalues k=1/`mm' {
			tempvar corrc`k'_``i'' c`k'_``i'' c_old`k'_``i''
			qui gen `corrc`k'_``i'''=exp(`k'*`corrlatent'-`diffmat2'[`i',`k'])/(`corrd') if `touse'
			qui gen `c`k'_``i'''=exp(`k'*`latent2'-`diffmat2'[`i',`k'])/(`d') if `touse'
			qui gen `c_old`k'_``i'''=exp(`k'*`latent'1-`diffmat2'[`i',`k'])/(`d') if `touse'
			qui replace `corrcum``i'''=`corrcum``i'''+`corrc`k'_``i'''*`k' if `touse'
			qui replace `cum``i'''=`cum``i'''+`c`k'_``i'''*`k' if `touse'
			qui replace `cum_old``i'''=`cum_old``i'''+`c_old`k'_``i'''*`k' if `touse'
		}
		qui gen `corrInf``i'''=0 if `touse'
		qui gen `Inf``i'''=0 if `touse'
		qui gen `Inf_old``i'''=0 if `touse'
		qui gen `C``i'''=0 if `touse'
		forvalues k=0/`mm' {
			qui replace `corrInf``i'''=`corrInf``i'''+(`k'-`corrcum``i''')^2*`corrc`k'_``i''' if `touse'
			qui replace `Inf``i'''=`Inf``i'''+(`k'-`cum``i''')^2*`c`k'_``i''' if `touse'
			qui replace `Inf_old``i'''=`Inf_old``i'''+(`k'-`cum_old``i''')^2*`c_old`k'_``i''' if `touse'
			qui replace `C``i'''=`C``i'''+(`k'-`cum``i''')^4*`c`k'_``i''' if `touse'
		}
		qui count if ``i''!=.&`touse'
		local n``i''=r(N)
		
		qui gen `C2``i'''=`C``i'''/((`Inf``i''')^2) if `touse'
		qui su `C2``i''' if `touse'
		local q2o``i''=(`r(mean)'-1)/((`n``i'''))

		qui gen `C3``i'''=`C``i'''-(`Inf``i''')^2 if `touse'
		qui su `C3``i'''
		local n=r(sum)
		qui su `Inf``i''' if `touse'
		local d=r(sum)
		local q2i``i''=`n'/((`d')^2)
		
		//di "``i'' qo = `=sqrt(`q2o``i''')' qi = `=sqrt(`q2i``i''')'"
		
		qui replace `Tcum'=`Tcum'+`cum``i''' if `touse'
		qui replace `TInf'=`TInf'+`Inf``i''' if `touse'
		qui gen `corry``i'''=``i''-`corrcum``i''' if `touse'
		qui gen `y``i'''=``i''-`cum``i''' if `touse'
		qui gen `y_old``i'''=``i''-`cum_old``i''' if `touse'
		qui gen `y2``i'''=(`y``i''')^2 if `touse'
		qui gen `y2_old``i'''=(`y_old``i''')^2 if `touse'
		qui gen `corrz``i'''=(`corry``i'''/sqrt(`corrInf``i''')) if `touse'
		qui gen `z``i'''=(`y``i'''/sqrt(`Inf``i''')) if `touse'
		local chi2_``i''=0
		local chi2_old_``i''=0
		forvalues g=1/`nbgroups' {
			qui su `y2``i''' if `group'==`g'&`touse'
			local n=r(sum)
			qui su ``i'' if `group'==`g'&`touse'
			local n1=r(sum)
			qui su `cum``i''' if `group'==`g'&`touse'
			local n2=r(sum)
			qui su `Inf``i''' if `group'==`g'&`touse'
			local d=r(sum)
			*qui count if `group'==`g'
			*local eff=r(N)
			*di "chi2_`g'_``i''=`chi2'+/*`eff'**/(`n1'-`n2')^2/(`d')"
			local chi2=`chi2'+/*`eff'**/(`n1'-`n2')^2/(`d')
			local chi2_``i''=`chi2_``i'''+/*`eff'**/(`n1'-`n2')^2/(`d')
			local chi2_g`g'=`chi2_g`g''+/*`eff'**/(`n1'-`n2')^2/(`d')
			qui su `y2_old``i''' if `group'==`g'&`touse'
			local n_old=r(sum)
			qui su ``i'' if `group'==`g'&`touse'
			local n1_old=r(sum)
			qui su `cum_old``i''' if `group'==`g'&`touse'
			local n2_old=r(sum)
			qui su `Inf_old``i''' if `group'==`g'&`touse'
			local d_old=r(sum)
			local chi2_old=`chi2_old'+(`n1_old'-`n2_old')^2/(`d_old')
			local chi2_old_``i''=`chi2_old_``i'''+(`n_old')/(`d_old')
			local chi2_old_g`g'=`chi2_old_g`g''+(`n_old')/(`d_old')
		}
		*di "Item ``i'' Chi2``i''=`chi2_``i''' et chi2=`chi2'  Chi2_old=`chi2_old_``i''' et chi2_old=`chi2_old' "
		*su `z``i'''
		label variable `corrz``i''' "Corrected standardized residuals associated to ``i''"
		label variable `z``i''' "Standardized residuals associated to ``i''"
		label variable `latent'1 "Latent trait"
		label variable `corrlatent' "Corrected latent trait"
		*set trace on
		if  "`graphs'"!=""&"`graphitems'"=="" {
			*set trace on
			*set tracedepth 1
			if "`filesave'"!="" {
				local fs saving("`dirsave'//residuals_``i''",replace)
			}
			local thr=abs(invnorm(`alpha'/2))
			tempvar id``i''
			if "`corrected'"!="" {
				qui gen `id``i'''=_n if abs(`z``i''')>`thr'*sqrt(`covariates'[1,1])&`touse'
				qui tostring `id``i''',replace
				qui replace `id``i'''="" if `id``i'''=="."&`touse'
				qui su `z``i''' if `touse'
				local min=r(min)
				local max=r(max)
				local min=floor(min(`min',`=-`thr'*sqrt(`covariates'[1,1])'))
				local max=ceil(max(`max',`=`thr'*sqrt(`covariates'[1,1])'))
			
				qui graph twoway scatter `z``i''' `latent' if `touse', ylabel(`min'(1)`max') yline(`=-`thr'*sqrt(`covariates'[1,1])' `=`thr'*sqrt(`covariates'[1,1])',lcolor(black)) mlabel(`id``i''') name(residuals``i'',replace) title("Standardized residuals associated to ``i''") `fs'
			}
			else {
			*set trace on
				qui gen `id``i'''=_n if abs(`corrz``i''')>`thr'*sqrt(`covariates'[1,1])&`touse'
				qui tostring `id``i''',replace
				qui replace `id``i'''="" if `id``i'''=="."&`touse'
				qui su `corrz``i''' if `touse'
				local min=r(min)
				local max=r(max)
				local min=floor(min(`min',`=-`thr'*sqrt(`covariates'[1,1])'))
				local max=ceil(max(`max',`=`thr'*sqrt(`covariates'[1,1])'))
				qui graph twoway scatter `corrz``i''' `corrlatent' if `touse', ylabel(`min'(1)`max') yline(`=-`thr'*sqrt(`covariates'[1,1])' `=`thr'*sqrt(`covariates'[1,1])',lcolor(black)) mlabel(`id``i''') name(residuals``i'',replace) title("Standardized residuals associated to ``i''") `fs' /*colorvar(`group') colordiscrete*/
			}
			*set trace off
		}
		*set trace off 
		qui gen `z2``i'''=(`z``i''')^2 if `touse'
		qui su `z2``i''' if `touse'
		local OUTFIT``i''=`r(mean)'
		qui matrix `fit'[`i',1]=`OUTFIT``i'''
		local OUTFITs``i''=((`r(mean)')^(1/3)-1)*(3/sqrt(`q2o``i'''))+sqrt(`q2o``i''')/3
		qui matrix `fit'[`i',3]=`OUTFITs``i'''
		qui su `Inf``i''' if ``i''!=.&`touse'
		local sumw``i''=r(sum)
		qui gen `i``i'''=`Inf``i'''*`z2``i''' if `touse' 
		qui su `i``i''' if ``i''!=.&`touse'
		local INFIT``i'' = `=`r(sum)'/`sumw``i''''
		qui matrix `fit'[`i',2]=`INFIT``i'''
		local INFITs``i''=(`=`r(sum)'/`sumw``i''''^(1/3)-1)*(3/sqrt(`q2i``i'''))+sqrt(`q2i``i''')/3
		qui matrix `fit'[`i',4]=`INFITs``i'''
		
		/*corrected*/
		qui gen `corrz2``i'''=(`corrz``i''')^2 if `touse'
		qui su `corrz2``i''' if `touse'
		local corrOUTFIT``i''=`r(mean)'
		qui matrix `fit'[`i',5]=`corrOUTFIT``i'''
		*local OUTFITs``i''=((`r(mean)')^(1/3)-1)*(3/sqrt(`q2o``i'''))+sqrt(`q2o``i''')/3
		*qui matrix `fit'[`i',3]=`OUTFITs``i'''
		qui su `corrInf``i''' if ``i''!=.&`touse'
		local corrsumw``i''=r(sum)
		qui gen `corri``i'''=`corrInf``i'''*`corrz2``i''' if `touse' 
		qui su `corri``i''' if ``i''!=.&`touse'
		local corrINFIT``i'' = `=`r(sum)'/`corrsumw``i''''
		qui matrix `fit'[`i',6]=`corrINFIT``i'''
		*local INFITs``i''=(`=`r(sum)'/`sumw``i''''^(1/3)-1)*(3/sqrt(`q2i``i'''))+sqrt(`q2i``i''')/3
		*qui matrix `fit'[`i',4]=`INFITs``i'''


		if "`postpce'"=="" {
			di "``i''" _col(35) %5.3f `OUTFIT``i''' _col(50) %5.3f `INFIT``i''' _col(64) %6.3f `OUTFITs``i''' _col(79) %6.3f `INFITs``i''' /*_col(94) %5.3f `corrOUTFIT``i''' _col(109) %5.3f `corrINFIT``i'''*/
		}
	}
	if "`postpce'"=="" {
		di as text "{hline 90}"
		di as text "*: As suggested by Wright (Smith, 1998)"
		di as text "**: As suggested by Bond and Fox (2007)"
	}
	if "`geninf'"!="" {
	    gen `geninf'=`TInf' if `touse'
	}
}
*set trace off
/*************************************************************************************************************
ESTIMATION OF THE WEIGHTED ML ESTIMATORS
**************************************************************************************************************/
*set trace on
*di "estimation `wmliterate'"
if "`postpce'"!="" {
    local conv=10
	local it=`wmliterate'
	di "Iteration : `it'"
	while(`conv'>=1) {
		di "Iteration `it' : conv=`conv'"
		tempvar   sinf
		qui gen `sinf'=sqrt(TInf_`=`it'-1') if `touse'
		`qui' pcm `varlist' [iweight=`sinf'] if `touse',diff(loulou) wmliterate(`it') geninf(TInf_`it') genlt(lt_`it') 
		tempvar  ecart_`it' 
		qui gen `ecart_`it''=abs(lt_`it'-lt_`=`it'-1') if `touse'
		qui su `ecart_`it'' if `touse'
		local conv =r(mean)
		local ++it
	}
    exit	
}

/*ANCIENNE PLACE DES CORRECTED VALUES*/





/*************************************************************************************************************
RESULTS BY GROUP
*************************************************************************************************************/
if "`visit'"==""{
*set trace on
    tempname matscorelt matgroupscorelt
	*di "qui matrix `matscorelt'=J(`=`nbitems'*`modamax'+1',3,.)"
	qui matrix `matscorelt'=J(`=`nbitems'*`modamax'+1',3,.)
	qui matrix `matgroupscorelt'=J(`=`nbitems'*`modamax'+1'+2*`nbgroups'',7,.)
	qui matrix colnames `matgroupscorelt'="Group" "Score" "Frequency" "Estimation of latent trait" "s.e. of latent trait" "Expected score" "Corrected latent trait"
	
	local row=1
	di
	di as text "{hline 71}"
	di _col(32) "Latent Trait" _col(50) "Expected" _col(63) "Corrected"
	di "Group" _col(10) "Score" _col(20) "Freq" _col(32) "Mean" _col(42) "s.e." _col(53) "Score" _col(60) "latent trait"
	di as text "{hline 71}"
	forvalues g=1/`nbgroups' {
		local sumuc=0
		local sumc=0
		qui count if `group'`multivisit'==`g'&`touse'
		local eff`g'=r(N)
		qui count if `group'`multivisit'==`g'&`score'`multivisit'!=.&`touse'
		local effcompleted`g'=r(N)
		qui count if `score'`multivisit'!=.&`group'`multivisit'==`g'&`touse'
		local n=r(N)
		di as text "`g' (n=" as result `eff`g'' as text ")" _c
		if `n'>0 {
			qui su `score'`multivisit' if `group'`multivisit'==`g'&`touse'
			local scoremin`g'=`r(min)'
			local scoremax`g'=`r(max)'
			forvalues s=`scoremin`g''/`scoremax`g'' {
				qui count if `group'`multivisit'==`g'&`score'`multivisit'==`s'&`touse'
				local eff=r(N)
				local effscore`s'=r(N)
				if `eff'!=0 {
					qui su `latent'1 if `group'`multivisit'==`g'&`score'`multivisit'==`s'&`touse'
					local mean=r(mean)
					*di "local ltscore`s'=`=ceil(`r(mean)'*100)/100'"
					local ltscore`s'=`=ceil(`r(mean)'*100)/100'
					*di "local sumc=`sumc'+(`eff')*(`estlt`s'')"
					*di "local sumuc=`sumuc'+(`eff')*(`mean')"
				    local sumuc=(`sumuc'+((`eff')*(`mean')))
				    local sumc=(`sumc'+((`eff')*(`estlt`s'')))
				}
				qui su `selatent'1 if `group'`multivisit'==`g'&`score'`multivisit'==`s'&`touse'
				local se=r(mean)
				qui su `Tcum' if `group'`multivisit'==`g'&`score'`multivisit'==`s'&`touse'
				local exp=r(mean)
				if `eff'>0 {
				   di as text _col(10) %5.0f `s' as result _col(20) %4.0f `eff' _col(30) %6.3f `mean' _col(40) %6.3f `se' _col(53) %5.2f `exp' _col(66) %6.3f `estlt`s''  `setlt`s''
				}
				*set trace on
				*matrix list `matscorelt'
				qui matrix `matscorelt'[`=`s'+1',1]=`eff'
				qui matrix `matscorelt'[`=`s'+1',2]=`mean'
				qui matrix `matscorelt'[`=`s'+1',3]=`se'
				qui matrix `matgroupscorelt'[`row',1]=`g'
				qui matrix `matgroupscorelt'[`row',2]=`s'
				qui matrix `matgroupscorelt'[`row',3]=`eff'
				qui matrix `matgroupscorelt'[`row',4]=`mean'
				qui matrix `matgroupscorelt'[`row',5]=`se'
				qui matrix `matgroupscorelt'[`row',6]=`exp'
				qui matrix `matgroupscorelt'[`row',7]=`estlt`s''
				local ++row
				*set trace off
			}
			
		}
		*set trace on
		qui count if `group'`multivisit'==`g'&`score'`multivisit'==.&`touse'
		local eff=r(N)
		local eff_md_`g'=r(N)
		if `eff'!=0 {
			qui su `latent'1 if `group'`multivisit'==`g'&`score'`multivisit'==.&`touse'
			local mean=r(mean)
			local lt_md_`g'=r(mean)
			local sumuc=(`sumuc'+((`eff')*(`mean')))
			qui su `selatent'1 if `group'`multivisit'==`g'&`score'`multivisit'==.&`touse'
			local se=r(mean)
			qui su `Tcum' if `group'`multivisit'==`g'&`score'`multivisit'==.&`touse'
			local exp=r(mean)
			di  as text _col(10) "    ." as result _col(20) %4.0f `eff' _col(30) %6.3f `mean' _col(40) %6.3f `se' _col(53) /*%5.2f `exp'*/
			qui matrix `matgroupscorelt'[`row',1]=`g'
			*qui matrix `matgroupscorelt'[`row',2]=`s'
			qui matrix `matgroupscorelt'[`row',3]=`eff'
			qui matrix `matgroupscorelt'[`row',4]=`mean'
			qui matrix `matgroupscorelt'[`row',5]=`se'
			qui matrix `matgroupscorelt'[`row',6]=`exp'
			*qui matrix `matgroupscorelt'[`row',7]=`estlt`s''
			local ++row
		}
		*set trace off
		*di "local lt`g'=`sumuc'/`eff`g''"		
		*di "local clt`g'=`sumc'/`effcompleted`g''"
		local lt`g'=(`sumuc')/(`eff`g'')
		local clt`g'=(`sumc')/(`effcompleted`g'')
		matrix `groups'[`g',`=`nbitems'+6']=`clt`g''
		*di "group `g' est=`lt`g'' corrected est=`clt`g''"
		di as text "         " "{dup 62:-}"
		if "`scoremin`g''"=="" {
			local scoremin`g' "."
		}
		if "`scoremax`g''"=="" {
			local scoremax`g' "."
		}
		di  as text _col(10) "`scoremin`g''/`scoremax`g''" as result _col(20) %4.0f `eff`g'' _col(30) %6.3f `lt`g''  _col(66) %6.3f `clt`g''
		di as text "{hline 71}"
		qui matrix `matgroupscorelt'[`row',1]=`g'
		*qui matrix `matgroupscorelt'[`row',2]="`scoremin`g''/`scoremax`g''"
		qui matrix `matgroupscorelt'[`row',3]=`eff`g''
		qui matrix `matgroupscorelt'[`row',4]=`lt`g''
		qui matrix `matgroupscorelt'[`row',5]=`se'
		*qui matrix `matgroupscorelt'[`row',6]=`exp'
		qui matrix `matgroupscorelt'[`row',7]=`clt`g''
		local ++row
	}
	local nbrowmat=`row'-1
	qui matrix `matgroupscorelt'=`matgroupscorelt'[1..`nbrowmat',1..7]
	*matrix list `matscorelt'
}	

*set trace on

/*************************************************************************************************************
Categories/Items/Test Characteristics Curves and Information graphs
*************************************************************************************************************/
*set trace on
if "`visit'"==""{
	if "`graphs'"!=""|"`graphs'"=="" {

		tempfile savefile
		qui save `savefile'

		*qui clear
		qui drop _all
		local pas=1000*round(`=sqrt(`covariates'[1,1])',0.001)
		qui set obs `pas'
		qui gen u=round((_n-`pas'/2)/(`pas'/10)*`=sqrt(`covariates'[1,1])',0.01)
		*list u
		qui gen Tcum=0
		qui gen TInf=0
		qui gen ecartcum=.
		forvalues i=1/`nbitems' {
		   local scatteri`i' 
		   local scatteric`i' 
		   forvalues g=1/`nbgroups' {
			  local x=`groups'[`g',`=`nbitems'+1']
			  local xc=`groups'[`g',`=`nbitems'+6']
			  local y=`groups'[`g',`i']
			  local s1=`groups'[`g',`=`nbitems'+2']
			  local seuil=30
			  local s vtiny
			  *set trace on
			  foreach lab in  /*tiny*/ vsmall small medsmall medium medlarge  large   vlarge  huge vhuge /*ehuge*/ {
				  if `s1'>`seuil' {
					 local s `lab'
				  }
				  local seuil=`seuil'+10
			  }
			  local scatteri`i' `scatteri`i'' || scatteri `y' `x' , mcolor(black) msize(`s') legend(off)
			  local scatteric`i' `scatteric`i'' || scatteri `y' `xc' , mcolor(black) msize(`s') legend(off)
			*set trace off
			}
			local d=1
			qui gen cum``i''=0
			*set trace on
			if "`rsm'"=="" {
				local mm=`modamax`i''
			}
			else {
				local mm `modamax'
			}	
			forvalues k=1/`mm' {
				local d `d'+exp(`k'*u-`diffmat2'[`i',`k'])
			}
			qui gen c0_``i''=1/(`d')
			label variable c0_``i'' "Pr(``i''=0)"
			forvalues k=1/`mm' {
				qui gen c`k'_``i''=exp(`k'*u-`diffmat2'[`i',`k'])/(`d')
				qui replace cum``i''=cum``i''+c`k'_``i''*`k'
				label variable c`k'_``i'' "Pr(``i''=`k')"
			}
			forvalues k=0/`mm' {
			    if `k'==0 {
				   local l=0.25
				}
				else if `k'==`mm' {
				   local l=`k'-0.25
				}
				else {
				   local l=`k'
				}
				qui replace ecartcum=abs(cum``i''-`l')
				qui su ecartcum
				qui su u if round(ecartcum,0.01)==round(`r(min)',0.01)
				local bestest``i''_`k'=r(mean)
				*di "item ``i'' cat `k' : est=`bestest``i''_`k''"
			}
			qui gen Inf``i''=0
			forvalues k=0/`mm' {
				qui replace Inf``i''=Inf``i''+(`k'-cum``i'')^2*c`k'_``i''
			}
			if "`graphitems'"=="" {
				if "`filesave'"!="" {
					local fsc saving("`dirsave'//CCC_``i''",replace)
					local fsi saving("`dirsave'//ICC_``i''",replace)
				}
				if "`graphs'"!="" {
					qui graph twoway line c*_``i'' u , name(CCC``i'', replace) title(Categories Characteristic Curve (CCC) of ``i'') ytitle("Probability") xtitle("`xtitle'") `fsc'
					if "`corrected'"!="" {
						qui graph twoway line cum``i'' u, name(ICC``i'',replace) title("Item Characteristic Curve (ICC) of ``i''") ytitle("Score to the item") xtitle("Latent trait") `scatteri`i'' `fsi'
					}
					else {
						qui graph twoway line cum``i'' u, name(ICC``i'',replace) title("Item Characteristic Curve (ICC) of ``i''") ytitle("Score to the item") xtitle("Corrected latent trait") `scatteric`i'' `fsi'
					}
				}
			}
			qui replace Tcum=Tcum+cum``i''
			*tab Tcum
			qui replace TInf=TInf+Inf``i''	
			label variable Inf``i'' "``i''"
		}
	    local scoremax=0
		forvalues i=1/`nbitems' {
		      local scoremax=`scoremax'+`modamax`i''
	    }
		qui gen ecart=.
		forvalues i=0/`scoremax' {
		    if `i'==0 {  
			   local j=0.25
			}
			else if `i'==`scoremax' {
			   local j=`scoremax'-0.25
			}
			else {
			   local j=`i'
			}
		    qui replace ecart=abs(Tcum-`j')
		    qui su ecart
			local tmp=r(min)
			qui su u if round(ecart, 0.01)==round(`tmp',0.01)
			local estlt`i'=`r(mean)'
			*di "score `i' : `r(mean)'"
		}
		if "`filesave'"!="" {
			local fst saving("`dirsave'//TCC",replace)
			local fsteo saving("`dirsave'//TCCeo",replace)
			local fsi saving("`dirsave'//ICC",replace)
			local fsti saving("`dirsave'//TIC",replace)
			local fstii saving("`dirsave'//TICi",replace)
			local fsm saving("`dirsave'//map",replace)
		}
		if "`graphs'"!="" {
*qui save "C:\temp\info\info",replace
			qui graph twoway line Tcum u, name(TCC,replace) title("Test Characteristic Curve (TCC)") ytitle("Score to the test") xtitle("`xtitle'") `fst' subtitle(`dimname')
			qui graph twoway line Inf* u, name(IIC,replace) title("Item Information Curves") ytitle("Information") xtitle("`xtitle'")  `fsi' subtitle(`dimname')
			qui graph twoway line TInf u, name(TIC,replace) title("Test Information Curve") ytitle("Information") xtitle("`xtitle'")  `fsti' subtitle(`dimname')
			qui graph twoway (line Inf*  u, lwidth(thin)) (line TInf u, lwidth(thick)), name(TIC,replace) title("Test/Item Information Curve") ytitle("Information") xtitle("`xtitle'")  `fstii' subtitle(`dimname')
		}
		local scatteri
		local scatteric
		forvalues g=1/`nbgroups' {
			local x=`groups'[`g',`=`nbitems'+1']
			local xc=`groups'[`g',`=`nbitems'+6']
			local y=`groups'[`g',`=`nbitems'+3']
			  local s1=`groups'[`g',`=`nbitems'+2']
			  local seuil=30
			  local s vtiny
			  *set trace on
			  foreach lab in  tiny vsmall small medsmall medium medlarge  large   vlarge  huge vhuge /*ehuge*/ {
				  if `s1'>`seuil' {
					 local s `lab'
				  }
				  local seuil=`seuil'+10
			  }
			local scatteri `scatteri' || scatteri `y' `x' , mcolor(black) msize(`s') legend(off)
			local scatteric `scatteric' || scatteri `y' `xc' , mcolor(black) msize(`s') legend(off)
		}
		if "`graphs'"!="" {
			if "`corrected'"!="" {
				qui graph twoway line Tcum u , name(TCCeo,replace) title("Test Characteristic Curve (TCC)") ytitle("Score to the test") xtitle("Latent trait") `scatteri' `fsteo' subtitle(`dimname')
			}
			else {
				qui graph twoway line Tcum u , name(TCCeo,replace) title("Test Characteristic Curve (TCC)") ytitle("Score to the test") xtitle("Corrrected latent trait") `scatteric' `fsteo' subtitle(`dimname')
			}
		}
	}
	
	
/*************************************************************************************************************
MAP
*************************************************************************************************************/
	*set trace on
	if "`graphs'"!=""|"eqset1"!="" {
		gen eff=0
		gen eff_md=0
		local effmax=0
			*gen uround=round(u,0.01)
			*list uround
		/*le bloc suivant était pour avoir des batons par groupe*/
		/*forvalues g=1/`nbgroups' {
			local eff=`groups'[`g',`=`nbitems'+2']
			if `groups'[`g',`=`nbitems'+2']>`effmax' {
			   local effmax=`groups'[`g',`=`nbitems'+2']
			}
			local lat=round(`groups'[`g',`=`nbitems'+1'],0.01)
			*di "replace eff=`eff' if round(u,0.01)==`lat'"
			qui replace eff=`eff' if round(u,0.01)==`lat'
		}*/
		/*le bloc suivant est pour avoir des batons par score*/
		qui gen uceil=ceil(u*100)/100
		forvalues s=0/`scoremax' {
			if `effscore`s''>`effmax' {
			   local effmax=`effscore`s''
			}
			*di "`s' qui replace eff=`effscore`s'' if ceil(u*100)/100==`=round(`ltscore`s'',0.01)'"
			qui replace eff=`effscore`s'' if round(u,0.01)==round(`ltscore`s'',0.01)
		}
		forvalues g=1/`nbgroups' {
			*di "if `eff_md_`g''>`effmax' { (`lt_md_`g'')"
			if `eff_md_`g''>`effmax' {
			   local effmax=`eff_md_`g''
			}
			qui replace eff_md=`eff_md_`g'' if round(u,0.01)==round(`lt_md_`g'',0.01)
		}

		gen density=normalden(u)*sqrt(`covariates'[1,1])
		label variable eff "Frequencies"
		label variable u "Latent trait"
		label variable TInf "Information curve"
		label variable density "Density function of the latent trait"
		local scatteri
		local scatterj
		local color 
		qui su u if eff!=0|eff_md!=0
		*set trace on
		*set tracedepth 1
		*if eff!=0|eff_md!=0 {
			local floor=floor(`r(min)')
			local ceil=ceil(`r(max)')
		*}
		*else  {
		*	local floor=-10
		*	local ceil=10
		*}
		local sep
		local ylbl
		forvalues i=1/`nbitems' {
		   local color`i':word `i' of `color'
		   local unit=round(`effmax'/`nbitems',1)
		   local y=-`i'*`unit'             
		   loca staritem
		   local legend `"3 "1" "'
		   forvalues l=1/`modamax' {
			   if `l'>=2 {
			      local legend `" `legend' `=2*`l'+1' "`l'" "'
			   }			   
			   local x=`diffmat'[`i',`l']
			   local scatteri `scatteri' || scatteri `y' `x' "`l'" ,mcolor(black) mlabcolor(black)
			   if `l'==1 {
			      local xant=`x'
			   }
			   else {
			      local xant=`diffmat'[`i',`=`l'-1']
			   }
			   if `xant'>`x' {
				  local star *
				  local staritem *
			   }
			   else {
			      local star
			   }
			   local scatterj `" `scatterj' `sep' scatteri `y' `x'   , pstyle(p`l') || pci `y' `xant' `y' `x', pstyle(p1) color(black)"'
			   local sep ||
			   if `x'<`floor' {
				  local floor=floor(`x')
			   }
			   if `x'>`ceil'&`x'!=. {
				  local ceil=ceil(`x')
			   }
		   }
   		   local ylbl `ylbl' `=-`i'*`unit'' "``i''`staritem'"
		   local scatteri `scatteri' || scatteri `y' `=`floor'-2' "``i''",mcolor(black) mlabcolor(black) msize(vtiny)
		}
		qui su eff
		local maxe=ceil(`=(floor(`r(max)'/10)+1)*10')
		qui su eff_md
		local maxe_md=ceil(`=(floor(`r(max)'/10)+1)*10')
		local maxe=max(`maxe',`maxe_md')
		qui su TInf
		local maxi=1.2*ceil(`r(max)')
		qui su density
		local maxd=round(`r(max)', 0.01)+0.01
		qui drop if u<`floor'|u>`ceil'
		*di "qui graph twoway (bar eff u, barwidth(.2) yaxis(1) legend(off) xlabel(0(1)`ceil')) (line TInf u,yaxis(2)) (line density u,yaxis(3)) `scatterj'   , name(map,replace) ytitle(Frequencies)  ylabel(0(`=`maxi'/5')`maxi' ,axis(2)) ylabel(0(`=`maxd'/5')`maxd' ,axis(3)) ylabel(-`maxe'(`=`maxe'/5')`maxe' ,axis(1)) title(Individuals/items representations (Map)) xsize(12) ysize(9) note(Red line: Information curve - Green line : Density of the latent trait) xtitle(Latent trait) `fsm'"
		*graph combine TIC IIC,  col(1)
		*graph save "map" "map.gph", replace
		*discard
		*qui graph twoway line TInf u , name(map,replace)
		*qui graph twoway `scatterj'  , name(map2,replace) ytitle("")   ylabel(`ylbl', grid angle(0))  legend(off) xsize(12) ysize(9) 
		*su
*list eff u if eff!=0
*browse
		if "`eqset1'"==""&"`graphs'"!="" {
		    *list eff u uceil if eff!=0&eff!=.
			*save tmp, replace
			qui graph twoway (bar eff u,  barwidth(.1) yaxis(1) xlabel(`floor'(1)`ceil') color(erose) ) (line TInf u,yaxis(2) lwidth(medthick)) (line density u,yaxis(3) lwidth(medthick) lcolo(green) ) (bar eff_md u,  barwidth(.05) yaxis(1) xlabel(`floor'(1)`ceil') color(stred) )  `scatterj'   , xline(0, lcolor(black)) legend(on position(6) cols(`modamax') rows(1) order(`"`legend'"')  subtitle(Threshold parameters) size(small)) name(map,replace) ytitle("                           Frequencies")  ylabel(0(`=`maxi'/5')`maxi' `maxi'(`maxi')`=`maxi'*2' ,axis(2)) yscale(axis(2) off) yscale(axis(3) off)  ylabel(-`maxd'(`=`maxd'/5')`maxd' ,axis(3)) yline(0,lwidth(medium) lpattern(solid) lcolor(black))  ylabel(`ylbl',/*noticks*/ grid angle(0) axis(1)) ylabel(`ylbl' 0(`=`maxe'/5')`maxe', grid angle(0) axis(1)) title("Individuals/items representations (Map)") xsize(12) ysize(9) note("Red line: Information curve - Green line : Density of the latent trait - * : dysfunctioning items") xtitle("`xtitle'") `fsm' subtitle(`dimname')
		}
		else if "`eqset1'"!="" {
			qui su eff
	        local ceil=ceil(ceil(`r(max)'/10)*10)

            qui tempfile equating
			qui save `equating', replace
		}
	}
	qui use `savefile', clear
}
		 


/*************************************************************************************************************
Best estimates by category 
*************************************************************************************************************/

tempname bestest
matrix `bestest'=J(`nbitems',`=`modamax'+1',.)
di
local long=`modamax'*8+33
di
di "Best estimates by answer category" 
di "{hline `long'}"
di "Item" _col(29) "Cat 0"  _c
forvalues j=1/`modamax' {
     local col=29+`j'*8 
	 di _col(`col') "Cat `j'"     _c
}
di
di "{hline `long'}"
forvalues i=1/`nbitems' {
    di "``i''" _c
	forvalues j=0/`modamax`i'' {
	    di _col(`=28+`j'*8') %6.3f round(`bestest``i''_`j'', 0.001) _c
		matrix `bestest'[`i',`=`j'+1']=`bestest``i''_`j''
	}
	di
}
di "{hline `long'}"
		


/*************************************************************************************************************
EQUATING
*************************************************************************************************************/
if "`eqset1'"!="" {
    if "`eqgenscore'"!="" {
	   local tmp1 `=ustrlen("`eqgenscore'`eqset1name'")'
	   local tmp2 `=ustrlen("`eqgenscore'`eqset2name'")'
	   local mlength=max(`tmp1',`tmp2')
	   if `mlength'>27 {
			di as error "The number of characters containing in the strings eqgenscore+eqset1name or eqgenscore+eqset2name must be lesser than 27"
			di as error "eqgenscore+eqset1name : `tmp1' characters"
			di as error "eqgenscore+eqset2name : `tmp2' characters"
			error 130
			*exit
		}
	}
	if "`eqset1name'"=="" {
	   local eqset1name="Set 1"
	}
	if "`eqset2name'"=="" {
	   local eqset2name="Set 2"
	}
	local eqset1name `=regexreplaceall("`eqset1name'"," ","_",.)'
	local eqset2name `=regexreplaceall("`eqset2name'"," ","_",.)'
	*di "set1:`eqset1name' set2:`eqset2name'"  

    tokenize `eqset1'
	local nbset1: word count `eqset1'
	forvalues i=1/`nbset1' {
	   local eq1_`i':word `i' of `eqset1'
	}
    tokenize `eqset2'
	local nbset2: word count  `eqset2'
	forvalues i=1/`nbset2' {
	   local eq2_`i':word `i' of `eqset2'
	}	



	tempfile fileeq
	qui save `fileeq',replace
	forvalues t=1/2{
		local scoremaxset`t'=0
		forvalues i=1/`nbset`t'' {
			local scoremaxset`t'=`scoremaxset`t''+`modamax`eq`t'_`i'''
		}
	}
	drop _all
	qui set obs `=(`scoremaxset1'+`scoremaxset2'+2)*3'
	forvalues t=1/2 {
		qui gen scoreset`t'=.
		qui gen scoreset`t'm=.
		qui gen scoreset`t'p=.	
	}
	forvalues i=0/`scoremaxset1' {
	    qui replace scoreset1=`i' in `=`i'+1'
	    qui replace scoreset1m=`i' in `=`i'+1+(`scoremaxset1'+`scoremaxset2'+2)'
	    qui replace scoreset1p=`i' in `=`i'+1+(`scoremaxset1'+`scoremaxset2'+2)*2'
	}
	forvalues i=`=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2' {
	    qui replace scoreset2=`i'-`scoremaxset1'-2 in `i'
	    qui replace scoreset2m=`i'-`scoremaxset1'-2 in `=`i'+(`scoremaxset1'+`scoremaxset2'+2)'
	    qui replace scoreset2p=`i'-`scoremaxset1'-2 in `=`i'+(`scoremaxset1'+`scoremaxset2'+2)*2'
	}
	local s=0
	local eqset1b
	foreach i in `eqset1' {
		qui gen s1_`i'=0
		forvalues m=1/`modamax`i'' {
		   qui gen s1_`i'_`m'=0 in 1/`=`scoremaxset1'+1'
		   qui replace s1_`i'_`m'=1 if scoreset1>`s' in 1/`=`scoremaxset1'+1'
		   qui replace s1_`i'=s1_`i'+s1_`i'_`m'
		   local ++s
		}
	    local eqset1b `eqset1b' s1_`i'
	}
	local s=0
	local eqset2b
	foreach i in `eqset2' {
		qui gen s2_`i'=0
		forvalues m=1/`modamax`i'' {
		   qui gen s2_`i'_`m'=0 in `=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2'
		   qui replace s2_`i'_`m'=1 if scoreset2>`s' in `=`scoremaxset1'+2'/`=`scoremaxset1'+`scoremaxset2'+2'
		   qui replace s2_`i'=s2_`i'+s2_`i'_`m'
		   local ++s
		}
		local eqset2b `eqset2b' s2_`i'
	}
	tokenize `varlist'
	tempname diffset1 diffset2
	forvalues t=1/2 {
		qui matrix `diffset`t''=J(`nbset`t'',`modamax',.)
		local n=1
		local listset`t'
		foreach j in `eqset`t'' {
			forvalues i=1/`nbitems' {
				if "`j'"=="``i''" {
					local listset`t' `listset`t'' `i'
					forvalues m=1/`modamax' {
						qui matrix `diffset`t''[`n',`m']=`diffmat'[`i',`m']
					}
					local ++n						
				}
			}
		}
	}
	local var=`covariates'[1,1]
	qui gen lt=.
	forvalues t=1/2 {
		tempname matscorelt`t'
		qui pcm `eqset`t'b', diff(`diffset`t'') var(`var') minsize(1)
		qui matrix `matscorelt`t''=r(matscorelt)
		forvalues i=0/`scoremaxset`t'' {
			qui replace lt=`matscorelt`t''[`=`i'+1',2] if scoreset`t'==`i'
			qui replace lt=`matscorelt`t''[`=`i'+1',2]+1.96*`matscorelt`t''[`=`i'+1',3] if scoreset`t'p==`i'
			qui replace lt=`matscorelt`t''[`=`i'+1',2]-1.96*`matscorelt`t''[`=`i'+1',3] if scoreset`t'm==`i'
		}
		qui ipolate scoreset`t' lt, gen(score`t') epolate
	}
	qui ipolate scoreset1 lt, gen(score1bis) epolate


	forvalues t=1/2 {
		qui replace score`t'=scoreset`t'm if scoreset`t'm!=.
		qui replace score`t'=scoreset`t'p if scoreset`t'p!=.
		qui replace score1=score1bis if score1==.
		qui replace score`t'=0 if score`t'<0
		qui replace score`t'=`scoremaxset`t'' if score`t'>`scoremaxset`t''
	}
	local pciset1
	local pciset2
	*set trace on
	local minimini=0
	local maximaxi=0
	forvalues t=1/2 {
        qui gen adjscore`t'=(score`t'+`eqaddset`t'')*`eqmultset`t''
	    qui gen adjscore`=3-`t''=(score`=3-`t''+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''
		tempname matscore`t'
		qui matrix `matscore`t''=J(`=`scoremaxset`t''+1',7,.)
		*set trace on
		forvalues s=0/`scoremaxset`t'' {
		    qui matrix `matscore`t''[`=`s'+1',1]=`s'
			qui su lt if scoreset`t'==`s'
		    qui matrix `matscore`t''[`=`s'+1',2]=r(mean)
			if `ceil'==0 {
				local ceil=1
			}
			if "`eqwithic'"=="" {
				local pciset`t'  `pciset`t'' scatteri `=-`ceil'/5*`t'' `r(mean)' (12) "`=round((`s'+`eqaddset`t'')*`eqmultset`t'',1)'"  , mlabsize(tiny) mcolor(black) mlabcolor(black)||
			}
			local mean=r(mean)
			qui su lt if scoreset`t'm==`s'
		    qui matrix `matscore`t''[`=`s'+1',3]=r(mean)
			local moins=r(mean)
			if `moins'<`minimini' {
				*di "local minimini=floor(`moins')"
				local minimini=floor(`moins')
			}
			qui su lt if scoreset`t'p==`s'
		    qui matrix `matscore`t''[`=`s'+1',4]=r(mean)
			local plus=r(mean)
			if `plus'>`maximaxi' {
				*di "local maximaxi=ceil(`plus')"
				local maximaxi=ceil(`plus')
			}

			if "`eqwithic'"!="" {
				local y=-`ceil'/5*((2.5*`t'-2)+2*(`s'/`scoremaxset`t''))
				*local pciset`t'  `pciset`t'' scatteri `y' `mean' (12) "`=round((`s'+`eqaddset`t'')*`eqmultset`t'',1)'"  , mlabsize(tiny) mcolor(black) mlabcolor(black)|| pci `y' `moins' `y' `plus',pstyle(p1) color(black)||
				local pciset`t'  `pciset`t'' scatteri `y' `mean'  , mlabsize(tiny) mcolor(black) mlabcolor(black)|| scatteri `y' `moins' (9) "`=round((`s'+`eqaddset`t'')*`eqmultset`t'',1)'"  , msize(0) mlabsize(tiny) mcolor(black) mlabcolor(black)|| pci `y' `moins' `y' `plus',pstyle(p1) color(black)||
			}
			qui su score`=3-`t'' if scoreset`t'==`s'
		    qui matrix `matscore`t''[`=`s'+1',5]=r(mean)
			qui su score`=3-`t'' if scoreset`t'm==`s'
		    qui matrix `matscore`t''[`=`s'+1',6]=r(mean)
			qui su score`=3-`t'' if scoreset`t'p==`s'
		    qui matrix `matscore`t''[`=`s'+1',7]=r(mean)
		}
		matrix colnames `matscore`t'' =score`t' lt lt- lt+ score`=3-`t'' score`=3-`t''- score`=3-`t''+
		di as text
		di as text "{hline 78}"
		di as text "EQUATING `eqset`t'name' TO `eqset`=3-`t''name'"
		di as text "{hline 78}"
		di "`eqset`t'name' : `eqset`t''"
		di "`eqset`=3-`t''name' : `eqset`=3-`t'''"
		local eqset`t'namea=abbrev("`eqset`t'name'",18)
		local eqset`=3-`t''namea=abbrev("`eqset`=3-`t''name'",12)
		di "{hline 78}"
		di "Score"           _col(20) "<----- Latent trait ----->" _col(52) "<- Score `eqset`=3-`t''namea'" _col(77) "->"
		di "`eqset`t'namea'" _col(20) "Estimated" _col(39) "[95%IC]" _col(52) "Estimated" _col(72) "[95%IC]"
		di "{hline 78}"
		forvalues s=0/`scoremaxset`t'' {
		    local min=min(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
		    local max=max(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
			
			di %4.0f `=(`matscore`t''[`=`s'+1',1]+`eqaddset`t'')*`eqmultset`t''' _col(24) %5.2f `matscore`t''[`=`s'+1',2] _col(33) "[" %5.2f `matscore`t''[`=`s'+1',3] ";" %5.2f `matscore`t''[`=`s'+1',4] "]" _col(56) %5.2f `=(`matscore`t''[`=`s'+1',5]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''' _col(66) "[" %5.2f `min' ";" %5.2f `max' "]"			
		}
		di "{hline 78}"
		if "`eqgraph'"!="" {
		    *set trace on
			if `eqmultset`=3-`t'''>0 {
				local xlabel 	"`=`eqaddset`=3-`t'''*`eqmultset`=3-`t''''(`=ceil((`scoremaxset`=3-`t'''*`eqmultset`=3-`t''')/20)')`=(`scoremaxset`=3-`t'''+`eqaddset`=3-`t''')*`eqmultset`=3-`t''''"
			}
			else {
				local xlabel 	"`=(`scoremaxset`=3-`t'''+`eqaddset`=3-`t''')*`eqmultset`=3-`t''''(`=ceil((-`scoremaxset`=3-`t'''*`eqmultset`=3-`t''')/20)')`=`eqaddset`=3-`t'''*`eqmultset`=3-`t''''"
			}
			if `eqmultset`t''>0 {
				local ylabel 	"`=`eqaddset`t''*`eqmultset`t'''(`=ceil((`scoremaxset`t''*`eqmultset`t'')/20)')`=(`scoremaxset`t''+`eqaddset`t'')*`eqmultset`t'''"
			}
			else {
				local ylabel 	"`=(`scoremaxset`t''+`eqaddset`t'')*`eqmultset`t'''(`=ceil((-`scoremaxset`t''*`eqmultset`t'')/20)')`=`eqaddset`t''*`eqmultset`t'''"
			}
			*set trace off
			*di "xlabel : `xlabel'"
			*di "subtitle=`subtitle'"
			twoway (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''!=.,lcolor(black) lpattern(solid) lwidth(thick)) (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''m!=.,lcolor(black) lpattern(dash) lwidth(thin)) (line adjscore`t' adjscore`=3-`t'' if scoreset`=3-`t''p!=.,lcolor(black) lpattern(dash) lwidth(thin)), title("Equating score of `eqset`=3-`t''name' to `eqset`t'name' ") ytitle("Score `eqset`t'name'") xtitle("Score `eqset`=3-`t''name'") ylabel(`ylabel') xlabel(`xlabel') name(eq`t'to`=3-`t'') legend(order(1 2) label(1 "Estimated") label(2 "95%IC") position(6)) subtitle("`dimname'") 
		}
		qui drop adjscore`t' adjscore`=3-`t''
	}
	
	if "`eqgraph'"!="" {
		qui use "`equating'",clear
	    qui su u
	    local flooru=floor(`r(min)')
	    local ceilu=ceil(`r(max)')
		qui su eff
	    local ceil=ceil(ceil(`r(max)'/10)*10)
		if `ceil'==0 {
		   local ceil=1
		}

		local title "Equating"
		if "`eqset1name'"!=""&"`eqset2name'"!=""{
		   local title "Equating between `eqset1name' and `eqset2name'"
		}
		if "`eqwithic'"=="" {
		   local ylabel1=-`ceil'/5
		   local ylabel2=-2*`ceil'/5
		   local gapu=ceil((`ceilu'-`flooru')/15)
		}
		else {
		    local ylabel1=-0.5*`ceil'/5
		    local ylabel2=-3*`ceil'/5
		   	local flooru=min(`flooru',`minimini')
			local ceilu=max(`ceilu',`maximaxi')
			local gapu=ceil((`ceilu'-`flooru')/15)
		}
	    *di "qui graph twoway (bar eff u, barwidth(.2) yaxis(1) xlabel(`flooru'(1)`ceilu') color(erose)) || `pciset1' `pciset2'  , yline(0, lcolor(black)) legend(off) name(equating,replace) ytitle(                           Frequencies)    ylabel(`=-`ceil'/5*2' `eqset1name' `=-`ceil'/5' `eqset2name' 0(`=`ceil'/5')`ceil', grid angle(0) axis(1)) title(Equating) xsize(12) ysize(9)  xtitle(Latent trait) "
	    qui graph twoway (bar eff u, barwidth(.2) yaxis(1) xlabel(`flooru'(`gapu')`ceilu') color(erose)) || `pciset1' `pciset2'  , yline(0, lcolor(black)) legend(off) name(equating,replace) ytitle("                           Frequencies")    /*ylabel(`ylbl', grid angle(0) axis(1))*/ ylabel(`ylabel1' "`eqset1name'" `ylabel2' "`eqset2name'" 0(`=`ceil'/5')`ceil', grid angle(0) axis(1)) title("`title'") subtitle("`dimname'") xsize(12) ysize(9)  xtitle("Latent trait") 
	}
	qui use `fileeq',clear
	*set trace on
	tempname scoreset1 scoreset2
	forvalues t=1/2 {
		qui genscore `eqset`t'' if `touse',score(`scoreset`t'')
	 	qui su `scoreset`t'' if `touse'
		local maxscoreset=r(max)
		*qui matrix list `matscore`t''
		if "`eqgenscore'"!="" {
			local eqgenscore `=regexreplaceall("`eqgenscore'"," ","_")'
			*di "eqgenscore : `eqgenscore'"
			foreach k in mean min max random {
				capture confirm  variable `eqgenscore'_`k'_`eqset`=3-`t''name'
				if _rc==0&"`replace'"!="" {
					qui replace `eqgenscore'_`k'_`eqset`=3-`t''name'=. if `touse'
				}
				else if _rc==0&"`replace'"!="" {
					di as error "The variable `eqgenscore'_`k'_`eqset`=3-`t''name' already exists"
					error 198
				}
				else {
					qui gen `eqgenscore'_`k'_`eqset`=3-`t''name'=. if `touse'
				}
			}
			*tab `scoreset`t''
			forvalues s=0/`maxscoreset' {
				*di "qui replace `eqgenscore'_`eqset`=3-`t''name'=`=(`matscore`t''[`=`s'+1',5]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''' if `scoreset`t''==`s'"
				local min=min(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
				local max=max(`=(`matscore`t''[`=`s'+1',6]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',`=(`matscore`t''[`=`s'+1',7]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''')
				qui replace `eqgenscore'_mean_`eqset`=3-`t''name'=round(`=(`matscore`t''[`=`s'+1',5]+`eqaddset`=3-`t''')*`eqmultset`=3-`t'''',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_min_`eqset`=3-`t''name'=round(`min',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_max_`eqset`=3-`t''name'=round(`max',1) if round(`scoreset`t'',1)==`s'&`touse'
				qui replace `eqgenscore'_random_`eqset`=3-`t''name'=round(uniform()*(`max'-`min')+`min',1) if round(`scoreset`t'',1)==`s'&`touse'
			}
		}
		return matrix score`t'_to_`=3-`t''=`matscore`t''
	}
	
}


/*************************************************************************************************************
RETOUR AU FICHIER INITIAL ET SAUVEGARDE DES NOUVELLES VARIABLES
*************************************************************************************************************/
*set trace on
if "`visit'"!="" {
	tempfile sauv
	*set trace on
	*tempname corrlatent corrbilatent
	qui keep `latent'* `selatent'* `id' `visit' 
    qui reshape wide , i(`id') j(`visit')
	qui sort `id'	
	qui save `sauv', replace
	restore,preserve
	if "`replace'"!=""&("`genlt'"!=""|"`geninf'"!="") {
    	capture drop `genlt' 
    	capture drop `genlt'_se 
    	capture drop `geninf' 
    	capture drop `genlt'_corr
    	capture drop `genlt'_opt
    	capture drop `genlt'_opt_se
    }
	*su
	tempname idorder
	qui gen `idorder'=_n 
	qui sort `id'
	qui merge 1:1 `id' using `sauv'
	
	qui sort `idorder'
    qui drop `idorder'	
}
else {
*set trace on
*set tracedepth 1
    if "`genlt'"!="" {
		qui gen `genlt'_corr=`corrlatent' if `touse'
/*		qui gen `genlt'_corr2=. if `touse'
		forvalues s=0/`scoremax' {
			qui replace `genlt'_corr2=`estlt`s'' if `score'==`s'&`touse'
		}
		forvalues g=1/`nbgroups' {
			qui replace `genlt'_corr2=`clt`g'' if `group'==`g'&`genlt'_corr==.&`touse'
		}
*/
		tempvar tmpitem mean nbnonmiss
		forvalues i=1/`nbitems' {
			qui gen `tmpitem'_`i'=. if `touse'
			forvalues k=0/`modamax' {
				qui replace `tmpitem'_`i'=`bestest'[`i',`=`k'+1'] if ``i''==`k'&`touse'
			}
		}
		*su
		qui egen `genlt'_opt=rowmean(`tmpitem'_*) if `touse'
		*qui egen `genlt'_opt_se=rowsd(`tmpitem'_*) if `touse'
		qui egen `nbnonmiss'=rownonmiss(`tmpitem'_*) if `touse'
		*qui replace `genlt'_opt_se=sqrt((`genlt'_opt_se^2+`resvar')/`nbnonmiss') if `touse'
 	}
	restore,not
}

/*************************************************************************************************************
CREATION DU DOCX
*************************************************************************************************************/

if "`docx'"!="" {
    putdocx clear
    putdocx begin, footer(fall_report)
	putdocx table hdr = (1, 3), border(all, nil) tofooter(fall_report)
	if "`rsm'"=="" {
		putdocx table hdr(1, 1) = ("Partial Credit Model")
	}
	else {
		putdocx table hdr(1, 1) = ("Rating Scale Model")
	}
	putdocx table hdr(1, 2) = ("`dimname'"), halign(center)
	putdocx table hdr(1, 3) = ("Page "), pagenumber
	putdocx table hdr(1, 3) = ("/"), totalpages append
	putdocx table hdr(1, 3), halign(right)
	putdocx paragraph ,style(Title)
	if "`dimname'" =="" {
	    local dimname2 "Rasch analysis"
	}
	else {
	    local dimname2 "Rasch analysis of the `dimname' dimension"
	}
	putdocx text ("`dimname2'") ,
	putdocx paragraph ,style(Subtitle)
	putdocx text ("General informations") ,
	putdocx paragraph
	putdocx text ("Number of individuals: `nbobs'")
	putdocx paragraph
	putdocx text ("Number of complete individuals: `nbobsssmd'")
	putdocx paragraph
    putdocx text ("Number of items: `nbitems'")
	putdocx paragraph
    putdocx text ("Names of the dimension: `dimname'")
	putdocx paragraph
    putdocx text ("List of items: `varlist'")
	putdocx paragraph
    putdocx text ("Date: $S_DATE, $S_TIME")
	putdocx paragraph
	local model Partial Credit Model (PCM)
	if "`rsm'"!="" {
	   local model Rating Scale Model (RSM)
	}
	putdocx text ("Model: `model'")
	putdocx paragraph
	putdocx text ("Marginal log-likelihood: `ll'")

	putdocx paragraph, style(Subtitle)
	putdocx text ("Estimation of the parameters") , 
	local paramname
	forvalues j=1/`nbitems' {
		forvalues k=1/`modamax' {
		     if `k'<=`modamax`j'' {
			     local paramname `paramname' "``j''_`k'"
			 }
	    }
	}
	*di "matrix colnames `diff'=`paramname'"
	matrix rownames `diff'=`paramname'
    putdocx table table1 = matrix(`diff') , nformat(%9.3f) rownames colnames  border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil) headerrow(1)  halign(center)
    putdocx table table1(.,1), halign(left) 
    putdocx table table1(.,2/7), halign(right) 
    putdocx table table1(1,.), halign(right) border(top) border(bottom)
	
	
	qui putdocx table table2 = matrix(`covariates') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)  headerrow(1)
    putdocx table table2(.,1), halign(left) 
    putdocx table table2(.,2/7), halign(right) 
    putdocx table table2(1,.), halign(right) border(top) border(bottom)



	
	putdocx paragraph,style(Subtitle)
	putdocx text ("Fit indexes for items") , /*bold underline font(,14) smallcaps*/
	qui putdocx table table3 = matrix(`fit') , nformat(%9.3f) rownames colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)    headerrow(1)
    putdocx table table3(.,1), halign(left) 
    putdocx table table3(.,2/5), halign(right) 
    putdocx table table3(1,.), halign(right) border(top) border(bottom)



	putdocx paragraph, style(Subtitle)
	putdocx text ("Estimation per group/score")
	*putdocx text ("Estimation per group/score") , bold underline font(,14) smallcaps
	*set trace on
	putdocx table tbl = (`=`nbrowmat'+1',7), border(all,nil) width(7) halign(center) note(EAP: Expected A Posteriori ; BE: Best Estimates) headerrow(1)
    putdocx table tbl(1,.), halign(right) border(top) border(bottom)
	putdocx table tbl(1,1) = ("Group"), halign(right) 
	putdocx table tbl(1,2) = ("score"), halign(right) 
	putdocx table tbl(1,3) = ("Frequency"), halign(right) 
	putdocx table tbl(1,4) = ("EAP Mean"), halign(right) 
	putdocx table tbl(1,5) = ("EAP s.e."), halign(right) 
	putdocx table tbl(1,6) = ("Exp score"), halign(right) 
	putdocx table tbl(1,7) = ("BE Mean"), halign(right) 
	local fin=1
	forvalues row=1/`nbrowmat' {
	    local row2=`row'+1
		local g: di %9.0f `matgroupscorelt'[`row',1]
		local gh=`matgroupscorelt'[`row',1]
		if `fin'==1 {
			putdocx table tbl(`row2',1) = ("`g'"), halign(right) 
		}
		if `matgroupscorelt'[`row',2]!=.|`matgroupscorelt'[`row',7]==. {
		    local s: di %9.0f `matgroupscorelt'[`row',2]
			local fin=0
		}
		else {
			local s "`scoremin`gh''/`scoremax`gh''"
			local fin=1
			*local fin "border(top) border(bottom)"
			*di "c'est la fin"
			putdocx table tbl(`row2',.),  border(bottom) border(top, dashed)
			putdocx table tbl(`row2',1), border(top, nil)
		}
		local eff: di %9.0f `matgroupscorelt'[`row',3]
		local lt: di %9.3f `matgroupscorelt'[`row',4]
		local se: di %9.3f `matgroupscorelt'[`row',5]
		local exp: di %9.2f `matgroupscorelt'[`row',6]
		local clt: di %9.3f `matgroupscorelt'[`row',7]
		*putdocx table tbl(`row',.), addrows(7)
		putdocx table tbl(`row2',2) = ("`s'"), halign(right) 
		putdocx table tbl(`row2',3) = ("`eff'"), halign(right) 
		putdocx table tbl(`row2',4) = ("`lt'"), halign(right) 
		putdocx table tbl(`row2',5) = ("`se'"), halign(right) 
		putdocx table tbl(`row2',6) = ("`exp'"), halign(right) 
		putdocx table tbl(`row2',7) = ("`clt'"), halign(right) 

	}

/*
		qui matrix `matgroupscorelt'[`row',1]=`g'
		*qui matrix `matgroupscorelt'[`row',2]="`scoremin`g''/`scoremax`g''"
		qui matrix `matgroupscorelt'[`row',3]=`eff`g''
		qui matrix `matgroupscorelt'[`row',4]=`lt`g''
		qui matrix `matgroupscorelt'[`row',5]=`se'
		*qui matrix `matgroupscorelt'[`row',6]=`exp'
		qui matrix `matgroupscorelt'[`row',7]=`clt`g''
		local ++row
	}
	local nbrowmat=`row'-1


local row 1
local vari 1
foreach x in gear_ratio turn foreign _cons {
putdocx table tbl5(`row',.), addrows(2)
local b: display %9.3f rtable[`vari',1]
local se: display %9.3f rtable[`vari',2]
local ++vari
local ++row
putdocx table tbl5(`row',1) = ("`x'"), halign(right)
putdocx table tbl5(`row',2) = ("`b'"), halign(right)
local ++row
local se = strtrim("`se'")
putdocx table tbl5(`row',2) = ("(`se')"), halign(right)
}*/
	
	*qui putdocx table tablename = matrix(`matgroupscorelt') , nformat(%9.3f) /*rownames*/ colnames border(start, nil) border(insideH, nil) border(insideV, nil) border(end, nil)   
	local extension png
}

/*************************************************************************************************************
SAUVEGARDE DES GRAPHIQUES
*************************************************************************************************************/
*set trace on
if "`filesave'"!="" {
    if "`graphs'"!="" {
		if "`docx'"!="" {
		    putdocx pagebreak
				putdocx paragraph, style(Subtitle)
				putdocx text ("General Graphs")
		}
		foreach i in TCC TCCeo TIC IIC map {
			if "`extension'"!="" {
			    qui graph export "`dirsave'//`i'.`extension'", replace name(`i')     
            }
			*graph display `i' 
			*qui graph save "`dirsave'//`i'", replace    
			if "`docx'"!="" {
			    putdocx paragraph
			    putdocx image "`dirsave'//`i'.png", height(10cm)
			}
		}
	    *discard
		if "`graphitems'"=="" {
			putdocx paragraph, style(Subtitle)
			putdocx text ("Graphs per item")
			forvalues i=1/`nbitems' {
				if "`docx'"!="" {
					putdocx paragraph, style(Heading1)
				    putdocx text ("Graphs for ``i''") 
				}
				foreach j in CCC ICC residuals {
					*graph display `j'``i'' 
					*qui graph save "`dirsave'//`j'_``i''", replace    

	 			    if "`extension'"!="" {
					    qui graph export "`dirsave'//`j'_``i''.`extension'", replace name(`j'``i'') 
					}
					if "`docx'"!="" {
						putdocx paragraph
						putdocx image "`dirsave'//`j'_``i''.png" , height(10cm)
					}
				}
			}
		}
	}
}
if "`docx'"!="" {
    putdocx save "`dirsave'//`docx'.docx", replace
}


/*************************************************************************************************************
RETURNS
*************************************************************************************************************/

*set trace on

matrix colnames `diff'=Estimate "s.e." z p lb ul
matrix colnames `covariates'=Estimate "s.e." z p lb ul
matrix rownames `diff'=`diffname'
matrix rownames `covariates'=Variance `continuous' `catname'
return matrix difficulties=`diff'
return matrix covariates=`covariates'
return matrix matscorelt=`matscorelt'
return matrix matgroupscorelt=`matgroupscorelt'
return matrix bestest=`bestest'
capture restore, not
end
