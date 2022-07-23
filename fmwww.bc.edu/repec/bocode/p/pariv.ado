*! version 1.0.0 19 July 2022

program pariv, eclass
	version 13.1
	syntax anything [aw pw fw] [if] [in], [robust cluster(varname) absorb(varname) noCONStant reps(integer 0) seed(integer 1) small] 

	tempname B ResB ResSE orderx ordert orderz norderx nordert norderz biv bx beta se 
	tempname xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl abs count ii R2max sample T TT 
	tempname bmin bmax semin semax Res
	tempvar c Cl Abs
	display " "

*Extracting and preparing locals
	if ("`exp'" ~= "") gettoken a ww: exp, parse("=")
	if ("`absorb'" ~= "") local constant = "noconstant"
	gettoken depvar anything: anything
	gettoken zvars anything: anything, match(match)
	gettoken endovars zvars: zvars, parse("=")
	gettoken zvars zvars: zvars, parse("=")
	if ("`anything'" ~= "") unab anything: `anything'
	if ("`anything'" == "") local anything = " "
	unab depvar: `depvar', min(1) max(1) name(depvar)
	unab endovars: `endovars', min(1) name(endovars)
	unab zvars: `zvars', min(1) name(excludedinst)

	quietly gen `sample' = 1 `if' `in'
	foreach var in `depvar' `endovars' `zvars' `anything' `cluster' `ww' `absorb' {
		quietly replace `sample' = . if `var' == .
		}
	quietly replace `sample' = 0 if `sample' == .

*Error messages
	local ct = wordcount("`endovars'")
	local cz = wordcount("`zvars'")
	local cx = wordcount("`anything'")
	local error = 0
	if ("`weight'" ~= "fweight") quietly sum `sample' if `sample' == 1
	if ("`weight'" == "fweight") quietly sum `sample' [fw = `ww'] if  `sample' == 1
	local N = r(N)
	if (`N' == 0) {
		display as error "No observations.  All observations missing at least one variable."
		local error = 1
		}
	if (`cz' < `ct') {
		display as error "Must have at least as many excluded instruments as endogenous variables."
		local error = 1
		}
	forvalues i = 1/`ct' {
		if "`depvar'" == word("`endovars'",`i') {
			display as error "`depvar' specified as both regresand and endogenous regressor."
			local error = 1
			}
		}
	forvalues i = 1/`cz' {
		if "`depvar'" == word("`zvars'",`i') {
			display as error "`depvar' specified as both regresand and excluded instrument."
			local error = 1
			}
		}
	forvalues i = 1/`cx' {
		if "`depvar'" == word("`anything'",`i') {
			display as error "`depvar' specified as both regresand and included instrument."
			local error = 1
			}
		}
	foreach var in `endovars' {
		forvalues i = 1/`cz' {
			if ("`var'" == word("`zvars'",`i')) {
				display as error "`var' specified as both endogenous regressor and excluded instrument."
				local error = 1
				}
			}
		forvalues i = 1/`cx' {
			if ("`var'" == word("`anything'",`i')) {
				display as error "`var' specified as both endogenous regressor and included instrument."
				local error = 1
				}
			}
		}
	if (`error' == 1) exit

*Eliminating perfectly collinear variables
	quietly matrix accum `B' = `endovars' `zvars' `anything' [`weight' `exp'] if `sample' == 1, `constant' absorb(`absorb')
	matrix `B' = invsym(`B')
	local newendovars = ""
	local newzvars = ""
	local newanything = ""
	forvalues i = 1/`ct' {
		local var = word("`endovars'",`i')
		if (`B'[`i',`i'] == 0) {
			display "note: Endogenous variable `var' is perfectly collinear with other variables and is dropped."
			}
		else {
			local newendovars = "`newendovars'" + "`var'" + " "
			}
		}
	forvalues i = 1/`cz' {
		local var = word("`zvars'",`i')
		if (`B'[`ct'+`i',`ct'+`i'] == 0) {
			display "note: Excluded instrument `var' is perfectly collinear with other variables and is dropped."
			}
		else {
			local newzvars = "`newzvars'" + "`var'" + " "
			}
		}
	forvalues i = 1/`cx' {
		local var = word("`anything'",`i')
		if (`B'[`ct'+`cz'+`i',`ct'+`cz'+`i'] == 0) {
			display "note: Included instrument `var' is perfectly collinear with other variables and is dropped."
			}
		else {
			local newanything = "`newanything'" + "`var'" + " "
			}
		}
	local ct = wordcount("`newendovars'")
	local cz = wordcount("`newzvars'")
	local cx = wordcount("`newanything'")
	local cn = 0
	local error = 0
	if (`ct' ==  0) {
		display as error "Must have at least one endogenous variable that is not perfectly collinear with the instruments."
		local error = 1
		}
	if (`cz' < `ct') {
		display as error "Must have at least as many non-perfectly collinear excluded instruments as endogenous variables."
		local error = 1
		}
	if (`error' == 1) exit

*Preparation
	local extra = ""
	if ("`constant'" == "") {
		local cx = `cx' + 1
		quietly gen byte `c' = 1
		local extra = "`c'"
		}
	if ("`weight'" ~= "") local extra = "`extra'" + " `ww'"
	if ("`cluster'" ~= "") {
		quietly egen `Cl' = group(`cluster') if `sample' == 1
		local extra = "`extra'" + " `Cl'"
		}
	if ("`absorb'" ~= "") {
		quietly egen `Abs' = group(`absorb') if `sample' == 1
		quietly sum `Abs'
		local cn = r(max)
		}
	if ("`small'" ~= "" & "`cluster'" ~= "") {
		quietly sum `Cl' 
		local adj = sqrt((`N'-1)*r(max)/((r(max)-1)*(`N'-`ct'-`cx'-`cn')))
		local dof = r(max) - 1
		}
	else if ("`small'" ~= "") {
		local adj = sqrt(`N'/(`N'-`ct'-`cx'-`cn'))
		local dof = `N'-`ct'-`cx'-`cn'
		}
	else {
		local adj = 1
		local dof = 0
		}

	local oldseed = "`c(seed)'"
	set seed `seed'

	local max = max(`reps',`ct'+`cx')
	quietly query memory
	local oldmatsize = "`r(matsize)'"
	if (r(matsize) < `max') set matsize `max'

	local newlist = "`newzvars'" + " " + "`newanything'"
	if ("`constant'" == "") quietly matrix accum `T' = `newlist' [`weight' `exp'] if `sample', deviations noconstant 
	if ("`constant'" ~= "") quietly matrix accum `T' = `newlist' [`weight' `exp'] if `sample', noconstant absorb(`absorb')
	mata `T' = st_matrix("`T'"); `TT' = cholsolve(`T',I(cols(`T'))) 
	mata `T' = 1:/(diagonal(`TT'):*diagonal(`T')); `T' = 1:-`T'; `TT' = colmax(`T'); st_matrix("`R2max'",`TT')

	mata {
*Base estimates
		`B' = J(`ct'+`cx',2,0); `dat' = st_data(.,"`depvar' `newendovars' `newzvars' `newanything' `extra'","`sample'")
		if ("`weight'" ~= "") {
			`dat'[1...,2+`ct'+`cz'+`cx'] = sqrt(`dat'[1...,2+`ct'+`cz'+`cx']); `dat'[1...,1..1+`ct'+`cz'+`cx'] =`dat'[1...,1..1+`ct'+`cz'+`cx']:*`dat'[1...,2+`ct'+`cz'+`cx'] 
			if ("`absorb'" ~= "") {
				`abs' = st_data(.,"`Abs'","`sample'"); `dat' = `dat',`abs'; `dat' = sort(`dat',cols(`dat')); `info' = panelsetup(`dat',cols(`dat')); `cl' = rows(`info')
				for(`ii'=1;`ii'<=`cl';`ii'++) `dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx'] = `dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx']-`dat'[`info'[`ii',1]..`info'[`ii',2],2+`ct'+`cz'+`cx']*(quadcross(`dat'[`info'[`ii',1]..`info'[`ii',2],2+`ct'+`cz'+`cx'],`dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx'])/quadcross(`dat'[`info'[`ii',1]..`info'[`ii',2],2+`ct'+`cz'+`cx'],`dat'[`info'[`ii',1]..`info'[`ii',2],2+`ct'+`cz'+`cx']))   
				`dat' = `dat'[1...,1..cols(`dat')-1]
				}
			}
		if ("`weight'" == "" & "`absorb'" ~= "") {
			`abs' = st_data(.,"`Abs'","`sample'"); `dat' = `dat', `abs'; `dat' = sort(`dat',cols(`dat')); `info' = panelsetup(`dat',cols(`dat')); `cl' = rows(`info')
			for(`ii'=1;`ii'<=`cl';`ii'++) `dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx'] = `dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx']:-mean(`dat'[`info'[`ii',1]..`info'[`ii',2],1..1+`ct'+`cz'+`cx'])
			`dat' = `dat'[1...,1..cols(`dat')-1]
			}
		`Y' = `dat'[1...,1..1+`ct'+`cz']
		if (`cx' > 0) {
			`x' = `dat'[1...,2+`ct'+`cz'..1+`ct'+`cz'+`cx']; `xx' = invsym(quadcross(`x',`x')); `bx' = `xx'*quadcross(`x',`Y'); `Y' = `Y' - `x'*`bx'
			}
		`y' = `Y'[1...,1]; `t' = `Y'[1...,2..1+`ct']; `z' = `Y'[1...,2+`ct'..1+`ct'+`cz']
		`zz' = invsym(quadcross(`z',`z')); `zt' = quadcross(`z',`t'); `zy' = quadcross(`z',`y'); `tt' = `z'*(`zz'*`zt'); `ttt' = invsym(quadcross(`tt',`tt')); `biv' =`ttt'*quadcross(`tt',`y'); `e' = `y' - `t'*`biv'
		if ("`cluster'" ~= "") {
			`te' = `tt':*`e'; `te' = `te', `dat'[1...,cols(`dat')]; `te' = sort(`te',cols(`te')); `info' = panelsetup(`te',cols(`te')); `te' = `te'[1...,1..cols(`te')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`te'),0)
			for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`te'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `ttt'*quadcross(`se',`se')*`ttt'
			}
		else if ("`robust'" ~= "" | "`weight'" == "pweight") {
			`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `ttt'*quadcross(`se',`se')*`ttt'
			}
		else {
			`se' = `ttt'*quadcross(`e',`e')/`N'
			}
		`B'[1..`ct',1..2] = `biv', `adj'*sqrt(diagonal(`se'))
		if (`cx' > 0) {
			`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
			if ("`cluster'" ~= "") {
				`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcross(`se',`se')
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = quadcross(`se',`se')
				}
			else {
				`se' = quadcross(`xtilde',`xtilde')*quadcross(`e',`e')/`N'
				}
			`B'[`ct'+1..`ct'+`cx',1..2] = `beta', `adj'*sqrt(diagonal(`se'))
			}
*Permute
		if (`reps' > 0) {
			`ResB' = J(`reps',`ct'+`cx',0); `ResSE' = J(`reps',`ct'+`cx',0)
			if (`cx' > 1) `orderx' = range(1,`cx',1); if (`cz' > 1) `orderz' = range(1,`cz',1); if (`ct' > 1) `ordert' = range(1,`ct',1)
			}
		for(`count'=1;`count'<=`reps';`count'++) {
			`dat' = jumble(`dat'); `y' = `dat'[1...,1]; `t' = `dat'[1...,2..1+`ct']; `z' = `dat'[1...,2+`ct'..1+`ct'+`cz']; `norderz' = 1; `nordert' = 1
			if (`cz' >1) {
				`z' = `z''; `z' = `z',`orderz'; `z' = jumble(`z'); `norderz' = `z'[1...,cols(`z')]; `z' = `z'[1...,1..cols(`z')-1]; `z' = `z''
				}
			if (`ct' >1) {
				`t' = `t''; `t' = `t',`ordert'; `t' = jumble(`t'); `nordert' = `t'[1...,cols(`t')]; `t' = `t'[1...,1..cols(`t')-1]; `t' = `t''
				}
			if (`cx' > 0) {
				`Y' = `y', `t', `z'; `x' = `dat'[1...,2+`ct'+`cz'..1+`ct'+`cz'+`cx']; `norderx' = 1
				if (`cx' > 1) {
					 `x' = `x''; `x' = `x',`orderx'; `x' = jumble(`x'); `norderx' = `x'[1...,cols(`x')]; `x' = `x'[1...,1..cols(`x')-1]; `x' = `x''
					}
				`xx' = invsym(quadcross(`x',`x')); `bx' = `xx'*quadcross(`x',`Y'); `Y' = `Y' - `x'*`bx'; `y' = `Y'[1...,1]; `t' = `Y'[1...,2..1+`ct']; `z' = `Y'[1...,2+`ct'..1+`ct'+`cz']
				}
			`zz' = invsym(quadcross(`z',`z')); `zt' = quadcross(`z',`t'); `zy' = quadcross(`z',`y'); `tt' = `z'*(`zz'*`zt'); `ttt' = invsym(quadcross(`tt',`tt')); `biv' =`ttt'*quadcross(`tt',`y'); `e' = `y' - `t'*`biv'; 
			if ("`cluster'" ~= "") {
				`te' = `tt':*`e'; `te' = `te', `dat'[1...,cols(`dat')]; `te' = sort(`te',cols(`te')); `info' = panelsetup(`te',cols(`te')); `te' = `te'[1...,1..cols(`te')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`te'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`te'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `ttt'*quadcross(`se',`se')*`ttt'
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `ttt'*quadcross(`se',`se')*`ttt'
				}
			else {
				`se' = `ttt'*quadcross(`e',`e')/`N'
				}
			`se' = `biv', sqrt(diagonal(`se')),`nordert'; `se' = sort(`se',3)
			`ResB'[`count',1..`ct'] = `se'[1...,1]'; `ResSE'[`count',1..`ct'] = `adj'*`se'[1...,2]' 
			if (`cx' > 0) {
				`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
				if ("`cluster'" ~= "") {
					`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
					for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcross(`se',`se')
					}
				else if ("`robust'" ~= "" | "`weight'" == "pweight") {
					`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = quadcross(`se',`se')
					}
				else {
					`se' = quadcross(`xtilde',`xtilde')*quadcross(`e',`e')/`N'
					}
				`se' = `beta', sqrt(diagonal(`se')),`norderx'; `se' = sort(`se',3)
				`ResB'[`count',1+`ct'..`ct'+`cx'] = `se'[1...,1]'; `ResSE'[`count',1+`ct'..`ct'+`cx'] = `adj'*`se'[1...,2]' 
				}
			}
		`Res' = J(rows(`B'),6,0); `Res'[1...,1..2] = `B'; `Res'[1...,3] = abs(`Res'[1...,1]:/`Res'[1...,2])
		if ("`small'" ~= "") `Res'[1...,4..6] = Ftail(1,`dof',`Res'[1...,3]:^2), `Res'[1...,1]-invttail(`dof',.025)*`Res'[1...,2],`Res'[1...,1]+invttail(`dof',.025)*`Res'[1...,2]
		if ("`small'" == "") `Res'[1...,4..6] = chi2tail(1,`Res'[1...,3]:^2), `Res'[1...,1]-invnormal(.975)*`Res'[1...,2],`Res'[1...,1]+invnormal(.975)*`Res'[1...,2]
		if (`reps' >0) {
			`bmin' = colmin(`ResB'); `bmax' = colmax(`ResB'); `semin' = colmin(`ResSE'); `semax' = colmax(`ResSE')
			st_matrix("`ResB'",`ResB'); st_matrix("`ResSE'",`ResSE'); `Res' = `Res', `bmin'', `bmax'', `semin'', `semax''
			}
		st_matrix("`Res'",`Res')
		}

if ("`constant'" == "") local newanything = "`newanything'" + "_cons"
if ("`reps'" ~= "0") {
	matrix colnames `ResB' = `newendovars' `newanything' 
	matrix colnames `ResSE' = `newendovars' `newanything' 
	ereturn matrix ResB = `ResB', copy
	ereturn matrix ResSE = `ResSE', copy
	if ("`small'" == "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper mincoef maxcoef minse maxse
	if ("`small'" ~= "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper mincoef maxcoef minse maxse
	}
else {
	if ("`small'" == "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper 
	if ("`small'" ~= "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper 
	}
matrix rownames `Res' = `newendovars' `newanything' 
ereturn matrix Res = `Res', copy
ereturn matrix R2max = `R2max', copy

display " "
display as text "Partitioned (collinear robust) 2SLS                 Number of obs  =", _continue
display as result %10.7g  `N'
display " "
	display as text "                      Estimates                Statistical Significance "  
	if ("`small'" == "") display as text "               coefficient  std. err.      |z|   P>|z|     [95% conf. interval]"  
	if ("`small'" ~= "") display as text "               coefficient  std. err.      |t|   P>|t|     [95% conf. interval]"  
	display "{hline 13}{c +}{hline 65}"
	local ct = `ct' + `cx'
	local list = "`newendovars'" + " " + "`newanything'"
	forvalues i = 1/`ct' {	
		display as text %12s abbrev(word("`list'",`i'),12) " {c |}", _continue
		display as result %10.7g `Res'[`i',1], _continue
		display as result %10.7g `Res'[`i',2], _continue
		display "    ", _continue
		display as result %3.2f `Res'[`i',3], _continue
		display " ", _continue
		display as result %4.3f `Res'[`i',4], _continue
		display "  ", _continue
		display as result %10.7g `Res'[`i',5], _continue
		display as result %10.7g `Res'[`i',6]
		}
	display "{hline 13}{c BT}{hline 65}"
display " "
if ("`reps'" ~= "0") {
	display as text "     Range in `reps' Permutations of Data and Variable Order"  
	display as text "                     coefficients          standard errors"  
	display as text "                    min        max          min        max"  
	display "{hline 13}{c +}{hline 46}"
	local list = "`newendovars'" + " " + "`newanything'"
	forvalues i = 1/`ct' {	
		display as text %12s abbrev(word("`list'",`i'),12) " {c |}", _continue
		display as result %10.7g `Res'[`i',7], _continue
		display as result %10.7g `Res'[`i',8], _continue
		display " ", _continue
		display as result %10.7g `Res'[`i',9], _continue
		display as result %10.7g `Res'[`i',10]
		}
	display "{hline 13}{c BT}{hline 45}"
	}

display as text "Instrumented: `newendovars'"
display as text "Excluded instruments: `newzvars'"
display as text "Included instruments: `newanything'"
if ("`absorb'" ~= "") display as text "Fixed effects for `absorb' as included instruments"
if ("`robust'" == "" & "`cluster'" == "") local list = "Homoskedastic standard errors"
if ("`robust'" ~= "" & "`cluster'" == "") local list = "Heteroskedasticity robust standard errors"
if ("`cluster'" ~= "") local list = "Clustered standard errors"
display as text "`list' "
if ("`small'" ~= "") display as text "Results reported with Stata's small sample adjustment of std. err. & degrees of freedom."
display " "
display as text "Maximum R2 found in the regression of any one instrument on the others:", _continue
display as result %10.8g `R2max'[1,1]

foreach j in B ResB ResSE orderx ordert orderz norderx nordert norderz biv bx beta se xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl count ii bmin bmax semin semax Res R2max T TT abs {
	capture mata mata drop ``j''
	}

set seed `oldseed'
set matsize `oldmatsize'

end



