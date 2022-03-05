*!  getfvname.ado 	Version 1.0		RL Kaufman 	08/30/2016

***  	1.0 Gets root name of factor variable.  Called by MKMARGVAR

program getfvname, rclass
version 14.2
args name1   
tokenize `name1', parse(".")
loc vname "`3'"
ret loc vname "`vname'"
end
