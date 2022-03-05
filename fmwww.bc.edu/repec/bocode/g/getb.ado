*!  getb.ado Version 2.3	RL Kaufman 	06/01/2016

***		Called by DEFINEFM.ADO
*** 	Returns a numeric matrix if NUMYN is not blank & = "y"  	else returns a string formated by BFORM
*** 	MATRIX =coef vector, VNAME = list of var names	EQNAME= col equation name to strip from coef vector
***		EQNM = EQNAME  is set by  eqndefine.ado     	EQNM used to strip row & col eqn names 
***			if NOKEEP is specified then equation names are NOT retained (put) on output matrix.
*** 
***		Except for mlogit can run getb w/o EQNAME and w/o NOKEEP to use default equation & keep names 
***			
***  	2.0 Modified to use same process for tobit, regress, mlogit a la GETBV.ADO
***		2.1 switch to e(depvar) as default for EQNM if not specified
***		2.2 preserves input matrix so can be reused
***		2.3  EQNAME is processed by eqndefine.ado    NOKEEP is separate option
***

program getb, rclass
version 14.2
syntax  , MATrix(name) VName(varlist fv) [EQName(string asis)  noKEEP BForm(string) NUMyn(string)]

mat bb=`matrix'
eqndefine , eqnmin(`eqname')
loc eqnm ""`r(eqnmout)'""
if "`eqname'" != "" loc eqnm ""`eqname'""
if "`bform'"=="" loc bf "%9.4f" 
if "`bform'"!="" loc bf "`bform'"

*** 	strip col eqn names using EQNM 
	loc ceq: coleq bb
	loc ceq2= subinword("`ceq'",`eqnm',"_",.)
	mat coleq bb = `ceq2'
	
***  	stripv.ado leaves non-factor vars as is.  factor vars  expanded and base terms deleted.
stripfv "`vname'"
loc vvnm "`r(strip)'"

loc c=0
loc ceq2 ""

***		option NUMYN=y  Create numeric vector of coeffcients
***		collect col eqn names if needed to add back in

if "`numyn'"!="" & strlower("`numyn'")=="y" {
	loc cn: list sizeof vvnm
	mat bx=J(1,`cn',.)
	foreach vn of local vvnm {
		loc ++c
		mat bx[1,`c']=bb[1,"`vn'"]
		loc ceq2 ="`ceq2' " + `eqnm' 
	}
	mat colnames bx = `vvnm'
	
***  Add in col eqn names unless nokeep is specified
	if "`keep'"!="nokeep" mat coleq bx = `ceq2'
	if `cn'==1 ret scalar b1ext=el(bx,1,1)
	return matrix bext bx
}
*** option NUMYN default or specified not eq "y"    Create string of coeffcients
if "`numyn'" == "" | strlower("`numyn'")!="y" {
	foreach vn of local vvnm {
		mat bnum=bb[1,"`vn'"]
		loc bs=strofreal(el(bnum,1,1),"`bf'")
		if el(bnum,1,1)>0 loc bs " `bs'"
		loc ++c
		if `c'==1 loc bacc "`bs'"
		if `c'>1  loc bacc "`bacc' `bs'"
	}
	return local bstr =`"`bacc'"'
}
end
** Works for reg, logit, ologit, mlogit, probit, oprobit, poisson, zip, nbreg, zinb , tobit 
