*!  defdualaxislabbar.ado 	Version 1.1		RL Kaufman 	01/04/2017

***  	1.0 Create rounded label values for dual axis.  Called by BARYHAT.ADO.  
***			Adapted from DEFAXISLAB.ADO
***		1.1 Create observed outcome labels for dual axis from y-standardized model metric 

program defdualaxislabbar, rclass
version 14.2
args vvmin vvmax ninc ndig xbar
qui {

if inlist("`e(cmd)'", "poisson" ,"nbreg", "zip" ,"zinb") == 1 {
	loc vmin = min(exp(`vvmin'),exp(`vvmax'))
	loc vmax = max(exp(`vvmin'),exp(`vvmax'))
}
if inlist("`e(cmd)'", "logit" )  == 1 {
	loc vmin = min(1/(1+exp(-`vvmin')),1/(1+exp(-`vvmax')))
	loc vmax = max(1/(1+exp(-`vvmin')),1/(1+exp(-`vvmax')))
}
if inlist("`e(cmd)'", "probit") == 1  {
	loc vmin = min(normal(`vvmin'),normal(`vvmax'))
	loc vmax = max(normal(`vvmin'),normal(`vvmax'))
}
if inlist("`e(cmd)'", "cloglog" ) == 1 {
	loc vmin = min(1-exp(-exp(`vvmin')),1-exp(-exp(`vvmax')))
	loc vmax = max(1-exp(-exp(`vvmin')),1-exp(-exp(`vvmax')))
}

loc ylabinc = (`vmax' - `vmin')/`ninc' 
numlist "`vmin'(`ylabinc')`vmax' `=`vmin'+.25*`ylabinc'' `=`vmin'+.5*`ylabinc''  ", sort
loc lablst "`r(numlist)' "

loc labvals1 = ""
loc labvals2 = ""
loc labdual = ""

foreach yv2 of numlist `lablst' {

	loc yhold= abs(`yv2')
	if `yhold' > 0 {
	loc p10 = int(log10(`yhold'))-1-1
	loc yvrnd = round(`yhold'+.5*(10^(`p10')),10^(`p10'+1))*sign(`yv2')
	if `yhold' < 1 {
		loc pyy=int(log10(`yhold'))*2
		loc y1=`yhold'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(`vmin')
		loc yvrnd= `y2'*(10^(`pyy'-1))
	}
}
	if inlist("`e(cmd)'", "poisson" ,"nbreg", "zip" ,"zinb") == 1  {
		loc yv1 = ln(`yvrnd')
	}
	if inlist("`e(cmd)'", "logit" ) == 1  {
		loc yv1 = ln( (`yvrnd')/(1-`yvrnd'))
	}
	if inlist("`e(cmd)'", "probit")  == 1 {
		loc yv1 = invnormal(`yvrnd')
	}
	if inlist("`e(cmd)'", "cloglog" ) == 1 {
		loc yv1 = ln( -ln(1-`yvrnd'))
	}	

	loc labvals1  "`labvals1' `=(`yv1'-${ymn$sfx})/${ystd$sfx}' "
	loc labvals2  "`labvals2' `yvrnd'"
	loc labdual  `"`labdual' `=(`yv1'-${ymn$sfx})/${ystd$sfx}'  `xbar' "`=strofreal(`yvrnd',"%9.`ndig'f")'" "'
}

return loc labvals1 = `"`labvals1'"'
return loc labvals2 = "`labvals2'"
return loc labdual = `"`labdual'"'
}
end
