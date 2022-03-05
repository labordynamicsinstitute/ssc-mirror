*!   stripfv.ado Version 2.0	RL Kaufman 	05/31/2016

*** 	stripfv.ado leaves non-factor vars in list as is.  
***		factor vars  expanded and base terms deleted. result stored as return loc string
***		2.0 switch to rclass and also return nvar= # of variables in stripped list 

program stripfv , rclass
version 14.2
args invar 
tempname outvar
loc isfv="n"
fvexpand `invar'
if "`r(fvops)'"== "true" loc isfv="y" 
loc hold `r(varlist)'
loc vnum: list sizeof hold
loc outvar ""
forvalues i=1/`vnum' {
	loc hh: word `i' of `hold'
	sca match=strmatch("`hh'","*b.*") 
	if match==0 & `i' != `vnum' {
		loc outvar= "`outvar'" +"`hh'" + " "
	}
	else if match==0 {
		loc outvar= "`outvar'" +"`hh'"
	}
}
loc vnum: list sizeof outvar
return local strip `"`outvar'"'
return local isfv "`isfv'"
return scalar nvar =`vnum'
end
