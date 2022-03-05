*!  getbvarbmod.ado Version 1.0		RL Kaufman 	06/27/2016

***  	1.0   Calculate moderated effect of Focal and its variance at given values of moderators. Returns  BMOD & VBMOD 
***			MODs = moderators #  MODSC=caegory # of mods, MODSV= value of vars indexed by MODS or VBLIST (1 or 0 if category of a dummy var)
***			All of these EXCLUDES 3ways, added if needed.

program getbvarbmod, rclass
version 14.2
syntax  , fnum(integer)  mods(numlist integer) modsc(numlist integer) modsv(numlist)[ int3(string) EQName(string)]
tempname vget vb c bval bmod vbmod

loc nmods: list sizeof modsv
loc vblist "${fvarc`fnum'$sfx}"
***		Collect names of Focal* Mods.
forvalues i=1/`nmods' {
		loc mn: word `i' of `mods'
		loc mc: word `i' of `modsc'
		loc vblist "`vblist' ${f`fnum'm`mn'c`mc'$sfx}"
	}
*** Construct row vector of weights such that c'b = bmod and c'Var(b)c= var(bmod)
loc cn=`nmods'+1
if "`int3'" =="y" loc cn=`cn'+ 1
mat `c'=J(1,`cn',0)
mat `c'[1,1]=1
forvalues i=1/`nmods' {
	loc mv: word `i' of `modsv'
	mat `c'[1,`=`i'+1']= `mv'
}

*** Construct col vector of coeff values
mat `bval'=J(`cn',1,0)
mat `bval'[1,1]=${bfvarc`fnum'$sfx}
	forvalues i=1/`nmods' {
		loc mn: word `i' of `mods'
		loc mc: word `i' of `modsc'
		mat `bval'[`=`i'+1',1]=${bf`fnum'm`mn'c`mc'$sfx}
}
***	If 3way interaction, extend C and BVAL. Will be only 2 moderators with a 3way interaction, MUST BE 1st TWO in LIST
if "`int3'"=="y"  {
 	loc mn: word 1 of `mods'
	loc mc: word 1 of `modsc'
	loc mv: word 1 of `modsv'
	loc mn2: word 2 of `mods'
	loc mc2: word 2 of `modsc'
	loc mv2: word 2 of `modsv'
	loc vblist "`vblist' ${f`fnum'm`mn'c`mc'm`mn2'c`mc2'$sfx}"
	mat `c'[1,`cn']= `mv'*(`mv2')
	mat `bval'[`cn',1]=${bf`fnum'm`mn'c`mc'm`mn2'c`mc2'$sfx}
}
***		Get Var(b) matrix for these variables
mat `vget'=e(V)
getvb , matrix("`vget'") vname("`vblist'") eqn(`eqname') nokeep
mat `vb'= r(vbext)
***	Calculate BMOD & VBMOD 

mat `bmod'= `c'*`bval'
mat `vbmod'= `c'*`vb'*`c''

return sca bmod= el(`bmod',1,1)
return sca vbmod= el(`vbmod',1,1)
return mat vbext `vb'
end
