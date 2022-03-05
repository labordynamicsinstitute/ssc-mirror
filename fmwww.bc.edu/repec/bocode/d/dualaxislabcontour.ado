*!  dualaxislabcontour.ado 	Version 1.1		RL Kaufman 	01/04/2017

***  	1.0 Create rounded label values for dual axis.  Called by CONTYHAT.ADO .  
***			Heavily adapted from DEFDUALAXISLAB.ADO
***		1.1 Observed outcome labels on dual axis for y-standardized model metric outcome

program dualaxislabcontour, rclass
version 14.2
syntax , [ lablst(numlist) ndig(integer 3)]
qui {
loc labdual = ""
foreach yvstd of numlist `lablst' {
loc yv = `yvstd'*${ystd$sfx}
if inlist("`e(cmd)'", "poisson" ,"nbreg", "zip" ,"zinb") == 1 {
	loc val = exp(`yv')
}
if inlist("`e(cmd)'", "logit")  == 1 {
	loc val = 1/(1+exp(-`yv'))
}
if inlist("`e(cmd)'", "probit") == 1  {
	loc val = normal(`yv')
}
if inlist("`e(cmd)'", "cloglog" ) == 1 {
	loc val = 1-exp(-exp(`yv'))
}
	loc labdual `"`labdual' `yvstd' "`=strofreal(`yvstd',"%6.`ndig'f")'  [`=strofreal(`val',"%6.`ndig'f")']""'
}
return loc labdual = `"`labdual'"'
}
end
