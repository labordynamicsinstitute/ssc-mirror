*!  axisdigit.ado Version 1.0	RL Kaufman 	10/4/2017

***  	Determine # of digits for axis labels from numlist for range

program axisdigit, rclass
version 14.2
args rangelist
qui {
numlist "`rangelist'"
loc numd=0
foreach nn of numlist `r(numlist)' {
	loc nd=.
	forvalues i=0/8 {
		if abs(`nn' - round(`nn',10^(-`i'))) < epsfloat() & `nd' == .  loc nd = `i'	
	}
	if `nd' > `numd' & `nd' < . loc numd = `nd'
}
ret local numd = `numd'
}
end
