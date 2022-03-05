*!   getfvbase.ado Version 1.0	RL Kaufman 	09/02/2016

*** 	determines which factor var value is the base value

program getfvbase , rclass
version 14.2
args invar 

fvexpand `invar'
loc hold `r(varlist)'
loc vnum: list sizeof hold
loc fvbase = .
forvalues i=1/`vnum' {
	loc hh: word `i' of `hold'
	sca match=strmatch("`hh'","*b.*") 
	if match == 1 {
		loc bp=strpos("`hh'","b.")	
		loc fvbase= substr("`hh'",1,`=`bp'-1')
		return sca fvbase = `fvbase'
	}
}	
end
