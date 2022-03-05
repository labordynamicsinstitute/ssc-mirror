*!  getvb.ado Version 2.5	RL Kaufman 	06/01/2016	

***		Gets Var(b) matrix for specfied variables
***		2.0 Keeps eqn names in extracted matrix  		
***		2.1 replaces with passed EQNAME  
***		2.2 uses same processing for mlogit, regress and tobit 
***		2.3 switch to e(depvar) as default for EQNM if not specified and do not keep eqn names
***		2.4 preserves input matrix so can be reused
***		2.3  EQNAME is processed by eqndefine.ado    NOKEEP is separate option

program getvb, rclass
version 14.2
syntax  , MATrix(name) VName(varlist fv) [EQName(string asis) noKEEP ] 

*** MATRIX =coef vector, VNAME = list of var names	EQNAME= col/row equation name to strip from Var(b) matrix
***		EQNM = EQNAME  is set by  eqndefine.ado     	EQNM used to strip row & col eqn names 
***			if NOKEEP is specified then equation names are NOT retained (put) on output matrix.
*** 
***		Except for mlogit can run getvb w/o EQNAME and w/o NOKEEP to use default equation & keep names 

mat bb=`matrix'
eqndefine , eqnmin(`eqname')
loc eqnm ""`r(eqnmout)'""
if "`eqname'" != "" loc eqnm ""`eqname'""
loc ceq: coleq bb
loc ceq2= subinword("`ceq'",`eqnm',"_",.)
mat coleq bb = `ceq2'
loc req: roweq bb
loc req2= subinword("`req'",`eqnm',"_",.)
mat roweq bb = `req2'

***  	stripfv.ado leaves non-factor vars as is.  factor vars  expanded and base terms deleted.
stripfv "`vname'"
loc c=0
loc ceq2 ""
loc req2 ""
loc vvnm "`r(strip)'"
loc cn: list sizeof vvnm
mat vbx=J(`cn',`cn',.)
*** 	pick Var(b) entries needed by stripped varnames
foreach vnc of local vvnm {
	loc ++c
	loc r=0
	loc ceq2 ="`ceq2' " + `eqnm' 
	foreach vnr of local vvnm {
		loc ++r
		if `c' ==1 	loc req2 ="`req2' " + `eqnm'
		mat vbx[`r',`c']=bb["`vnr'","`vnc'"]
	}
}
mat colnames vbx = `vvnm'
mat rownames vbx = `vvnm'
***		if keep specified , add back in eqn names
if "`keep'"!="nokeep"{	
	mat coleq vbx = `ceq2'
	mat roweq vbx = `req2'	
}
return matrix vbext vbx
end
** Works for reg, logit, ologit, mlogit, probit, oprobit, poisson, zip, nbreg, zinb , tobit 
