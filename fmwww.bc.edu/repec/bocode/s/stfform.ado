*! version 1.1 Sep 2024
cap pro drop stfform
pro def stfform, sortpreserve rclass
syntax [varlist (numeric default=none) ] [, NSIMulation(integer 1000) noGraph nplot(integer 20) saving(name) noxb nolog]
version 16 
st_is 2 analysis
if (!inlist(e(cmd2),"stcox")) {
	di as error "last command is not {bf: stcox}"
	exit 144
}
tempvar touse
quietly gen byte `touse'=e(sample)

sort _t
tempvar L0 mg XB
quietly predict `L0', basech
quietly predict `mg', mg
quietly predict `XB', xb

forval j=1/`=colsof(e(b))'{
	tempvar scores`j'
	local scores `scores' `scores`j''
}
predict `scores', sch 
 local datasign=e(datasignaturevars)
if ("`varlist'"=="") {
quietly vl set, clear 
local vlcateg $vlcategorical
local stsetvars _st _d _t _t0
 local vlcateg: list vlcateg - stsetvars

 local datasign: list datasign - vlcateg
} 
else  {
	local varlist _t _t0 _d `varlist'
	local datasign=e(datasignaturevars)
	local datasign: list datasign & varlist
}
	if ("`xb'"!="noxb") local datasign `datasign' `XB'
 
 quietly m: _stmgtest_fform("`touse'","`datasign'","`mg'", "`L0'", "`scores'", 1000,"`saving'","`graph'") 

 if ("`graph'"!="nograph") {
if (`nplot'>20) {	
	local ncalls=ceil(`nplot'/20)
	quie numlist "1(1)`ncalls'", integer ascending
	local ncalls=r(numlist)

	foreach c of local ncalls {
		local start=`end'+1
		local end=min(`c'*20,`nplot')
		if (`end'==`nplot') local pp W`end'	
		else local pp W`start'-W`end'
		local call `call' (line `pp' z, lpattern(dot ..) lcolor(gs14 ..))
	}
} 
else local call (line W1-W`nplot' z, lpattern(dot ..) lcolor(gs14 ..))
	
frame `df': tw (line M z )  `call' , by(var, rescale yrescale note("first `nplot' simulated processes") ) ytitle("Cum. martingale residuals") xtitle("Covariate") legend(order(1 "Observed" 2 "Simulated")) 
 }
if ("`saving'"!="")  frame `df': {
	label variable M "observed cumulative martingale residuals"	
	label variable var "variable name in the original Cox model"
	label variable z "unique values of the variable in the original data"
	forvalue s=1/`nsimulation' {
	label variable W`s' "simulated cumulative martingale residuals under the null"
		}
	save `saving', replace
}
matlist `_fformtest', title("Functional form test based on cumulative martingale residuals - `nsimulation' replications")
di _newline "P(S>=s) p value under the null hypothesis that the functional form is correctly specified"
di _newline"xb: test for the link function"
return matrix test=`_fformtest'

 end