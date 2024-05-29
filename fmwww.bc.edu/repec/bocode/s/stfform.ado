cap pro drop stfform
pro def stfform, sortpreserve rclass
syntax  [, NSIMulation(integer 1000) noGraph nplot(integer 20) saving(name)  ]

version 16

st_is 2 analysis
if (!inlist(e(cmd2),"stcox")) {
	di as error "last command is not {bf: stcox}"
	exit 144
}
tempvar touse
gen byte `touse'=e(sample)

sort _t
tempvar L0 mg xb
predict `L0', basech
predict `mg', mg
predict `xb', xb

forval j=1/`=colsof(e(b))'{
	tempvar scores`j'
	local scores `scores' `scores`j''
}
predict `scores', sch 

quie vl set, clear 
local vlcateg $vlcategorical
local stsetvars _st _d _t _t0
 local vlcateg: list vlcateg - stsetvars

 
 local datasign=e(datasignaturevars)
 local datasign: list datasign - vlcateg
 
 quie m: _stmgtest_fform("`touse'","`datasign' `xb'","`mg'", "`L0'", "`scores'", 1000,"`saving'","`graph'") 

 if ("`graph'"!="nograph") {
frame `df': tw (line M z, lcolor(navy) ) (line W1-W`nplot' z, lpattern(`=`nplot'*"dot "') lcolor(`=`nplot'*"black "')), by(var, rescale yrescale note("first `nplot' simulated processes") ) ytitle("Cum. Martingale residuals") xtitle("Covariate") legend(order(1 "Observed" 2 "Simulated")) 
 }
if ("`saving'"!="")  frame `df': save `saving', replace

matlist `_fformtest', title("Functional form test based on cumulative martingale residuals - `nsimulation' replications")
di _newline "P(S>=s) p value under the null hypothesis that the functional form is correctly specified"
di _newline"xb: test for the link function"
return matrix test=`_fformtest'

 end
