*! version 1.2 Sep 2025
pro def stfform, sortpreserve rclass
syntax [varlist (numeric default=none) ] [, NSIMulation(integer 1000) noGraph nplot(integer 20) SAVing(string asis) noxb nolog novars graphnames(name)  SIMColor(string) OBSColor(string)]
version 16 
st_is 2 analysis

cap findfile moremata.hlp
if _rc {
	//di as error "{bf: moremata} package not found please execute {bf: ssc install moremata} to install it or search it using {bf: net search}"
	di "{bf: moremata} package not found. Installing dependency..."
	ssc install moremata
}

if ( `"`e(cmd2)'"' != "stcox" ) {
	di as error "last command is not {bf: stcox}"
	exit 144
}
if ("`_dta[st_id]'"!="") {
	di as error "{bf:stfform} is not allowed with multiple records"
	exit 144
}
if (`=c(maxvar)'<`nsimulation') {
	di as text "WARNING:" _n "The desired number of simulations ({bf:nsimulation}=`nsimulation') exceeds current {bf: maxvar} (`c(maxvar)')." _n "The maximum {bf:nsimulation} is {bf: maxvar}-3."_n" Overriding graphs and {bf: saving} ..."_n	
	local saving
	local graph nograph
}
if ("`xb'"=="noxb" & "`vars'"=="novars")  {
	di as error "{bf:noxb} and {bf:novars} are mutually exclusive options"
	exit 144
}
if (`nplot'>`nsimulation') local nplot=`nsimulation'	

CheckSaving `saving'
tempvar touse
quietly gen byte `touse'=e(sample)

sort _t, stable
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
if ("`xb'"!="noxb") {
	if ("`vars'"!="novars") local datasign `datasign' `XB'
	else  local datasign _t _t0 _d `XB'
		}
	 // if ("`log'"!="nolog") _dots 0, title(Simulations) reps(`nsimulation')
  quie m: _stmgtest_fform("`touse'","`datasign'","`mg'", "`L0'", "`scores'", `nsimulation',`"`saving'"',"`graph'") 

 if ("`graph'"!="nograph") {
 	if ("`simcolor'"=="") local simcolor gs7
	if ("`obscolor'"=="") local obscolor black
 	if ("`graphnames'"=="") local graphnames _stff_
if (`nplot'>20) {	
	local ncalls=ceil(`nplot'/20)
	quie numlist "1(1)`ncalls'", integer ascending
	local ncalls=r(numlist)

	foreach c of local ncalls {
		local start=`end'+1
		local end=min(`c'*20,`nplot')
		if (`end'==`nplot') local pp W`end'	
		else local pp W`start'-W`end'
		local call `call' (line `pp' z, lpattern(dot ..) lcolor(`simcolor' ..))
	}
} 
else local call (line W1-W`nplot' z, lpattern(dot ..) lcolor(`simcolor' ..))

frame `df': {
	tw  `call'  (line M z, lcolor(`obscolor') )   , by(var, rescale yrescale note("first `nplot' simulated processes") ) ytitle("Cum. martingale residuals") xtitle("Covariate") legend(order(`=`nplot'+1' "Observed" 1 "Simulated")) 
		quie levelsof var, local(vnames)
		foreach v of local vnames {
			tw `call' (line M z, lcolor(`obscolor') )   if  var=="`v'"   , note("first `nplot' simulated processes")  ytitle("Cum. martingale residuals") xtitle("`v'") ///
						legend(order(`=`nplot'+1' "Observed" 1 "Simulated"))  name(`graphnames'`v', replace) nodraw
		}
	}
 }
if (`"`saving'"'!="")  frame `df': {
	label variable M "observed cumulative martingale residuals"	
	label variable var "variable name in the original Cox model"
	label variable z "unique values of the variable in the original data"
	foreach v of varlist W* {
		label variable `v' "simulated cumulative martingale residuals under the null"
	}	
	save `saving'
}
matlist `_fformtest', title("Functional form test based on cumulative martingale residuals - `nsimulation' replications" )
di _newline "P(S>=s): p value under the null hypothesis that the functional form is correctly specified"
if ("`xb'" !="noxb") di _newline"xb: test for the link function"
return matrix test=`_fformtest'

 end
 
program CheckSaving
	version 8.2
	capture syntax [anything(id="filename" equalok)] [, replace ]
	if c(rc) {
		di as err "invalid saving() option"
		syntax [anything(id="filename" equalok)] [, replace ]
		exit 198
	}
	if "`replace'" != "" & `"`anything'"' == "" {
		di as err "invalid saving() option, filename is required"
		exit 198
	}
end