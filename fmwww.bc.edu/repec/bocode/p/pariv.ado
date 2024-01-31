*! version 2.0.0 August 2023

program pariv, eclass
	version 15.1
	syntax anything [aw pw fw] [if] [in], [robust cluster(varname) absorb(varname) noCONStant reps(integer 0) seed(integer 1) small] 

	tempname B ResB ResSE orderx ordert norderx nordert biv bx beta se select 
	tempname xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl abs count ii R2max sample T TT W sumW N n
	tempname bmin bmax semin semax Res
	tempvar c Cl Abs mean
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

*Marking sample
	marksample touse
	markout `touse' `depvar' `endovars' `zvars' `anything' `cluster' `absorb'

*Demeaning while keeping same names to pass on to _rmcoll to alert reader to which variables are collinear
if ("`absorb'" ~= "") {
	preserve
	foreach var in `depvar' `endovars' `zvars' `anything' {
		if ("`weight'" ~= "") quietly areg `var' [`weight' = `ww'] if `touse', absorb(`absorb')
		if ("`weight'" == "") quietly areg `var' if `touse', absorb(`absorb')
		quietly predict double `mean', resid
		quietly drop `var'
		quietly rename `mean' `var'
		}
	}

*Eliminating collinear variables
	local ct = wordcount("`endovars'")
	local cz = wordcount("`zvars'")
	local cx = wordcount("`anything'")
	_rmcoll `endovars' `zvars' `anything' if `touse', `constant'
	local newendovars = ""
	forvalues i = 1/`ct' {
		if (word(r(varlist),`i') ~= "o." + word("`endovars'",`i')) local newendovars = "`newendovars'" + word("`endovars'",`i') + " "
		}
	local newzvars = ""
	forvalues i = 1/`cz' {
		if (word(r(varlist),`i'+`ct') ~= "o." + word("`zvars'",`i')) local newzvars = "`newzvars'" + word("`zvars'",`i') + " "
		}
	local newanything = ""
	forvalues i = 1/`cx' {
		if (word(r(varlist),`i'+`ct'+`cz') ~= "o." + word("`anything'",`i')) local newanything = "`newanything'" + word("`anything'",`i') + " "
		}
	local endovars = "`newendovars'"
	local zvars = "`newzvars'"
	local anything = "`newanything'"

	_rmdcoll `depvar' `endovars' `zvars' `anything' if `touse', `constant'
	local ct = wordcount("`endovars'")
	local cz = wordcount("`zvars'")
	local cx = wordcount("`anything'")

*Checking minimal identification
	local error = 0
	if ("`weight'" ~= "fweight") quietly sum `touse' if `touse' == 1
	if ("`weight'" == "fweight") quietly sum `touse' [fw = `ww'] if  `touse' == 1
	local N = r(N)
	if (`N' == 0) {
		display as error "No observations. All observations missing at least one variable."
		local error = 1
		}
	else if (`ct' == 0) {
		display as error "Must have at least one endogenous variable that is not collinear with the instruments."
		local error = 1
		}
	else if (`cz' < `ct') {
		display as error "Must have at least as many non-collinear excluded instruments as endogenous variables."
		local error = 1
		}
	if (`error' == 1) exit

*Preparation
	local cn = 0
	local cxx = `cx' + ("`constant'" == "")
	local extra = ""
	if ("`weight'" ~= "") local extra = "`extra'" + "`ww'"
	if ("`cluster'" ~= "") {
		quietly egen `Cl' = group(`cluster') if `touse' == 1
		local extra = "`extra'" + " `Cl'"
		}
	if ("`absorb'" ~= "") {
		quietly egen `Abs' = group(`absorb') if `touse' == 1
		quietly sum `Abs'
		local cn = r(max)
		}
	if ("`small'" ~= "" & "`cluster'" ~= "") {
		quietly sum `Cl' 
		local adj = sqrt((`N'-1)*r(max)/((r(max)-1)*(`N'-`ct'-`cxx'-`cn')))
		local dof = r(max) - 1
		}
	else if ("`small'" ~= "") {
		local adj = sqrt(`N'/(`N'-`ct'-`cxx'-`cn'))
		local dof = `N'-`ct'-`cx'-`cn'
		}
	else {
		local adj = 1
		local dof = 0
		}

	local oldseed = "`c(seed)'"
	set seed `seed'
	local max = max(`reps',`ct'+`cxx')
	quietly query memory
	local oldmatsize = "`r(matsize)'"
	if (r(matsize) < `max') quietly set matsize `max'

	local newlist = "`zvars'" + " " + "`anything'"
	if ("`constant'" == "") quietly matrix accum `T' = `newlist' [`weight' `exp'] if `touse', deviations noconstant 
	if ("`constant'" ~= "") quietly matrix accum `T' = `newlist' [`weight' `exp'] if `touse', noconstant 
	mata `T' = st_matrix("`T'"); `TT' = cholsolve(`T',I(cols(`T'))) 
	mata `T' = 1:/(diagonal(`TT'):*diagonal(`T')); `T' = 1:-`T'; `TT' = colmax(`T'); st_matrix("`R2max'",`TT')

	mata {
*Base estimates
		`B' = J(`ct'+`cxx',2,0); `dat' = st_data(.,"`depvar' `endovars' `zvars' `anything' `extra'","`touse'"); `sumW' = `N'; `n' = rows(`dat')
		if ("`weight'" ~= "") {
			`sumW' = colsum(`dat'[1...,2+`ct'+`cz'+`cx']); `dat'[1...,2+`ct'+`cz'+`cx'] = sqrt(`dat'[1...,2+`ct'+`cz'+`cx'])
			`W' = `dat'[1...,2+`ct'+`cz'+`cx']; `dat'[1...,1..1+`ct'+`cz'+`cx'] =`dat'[1...,1..1+`ct'+`cz'+`cx']:*`W'
			if ("`constant'" == "") {
				`T' = quadcross(`W',`dat'[1...,1..1+`ct'+`cz'+`cx'])/quadcross(`W',`W'); `dat'[1...,1..1+`ct'+`cz'+`cx'] = `dat'[1...,1..1+`ct'+`cz'+`cx']:-`W'*`T'
				`select' = J(1,1+`ct'+`cz'+`cx',1); `select'[1,2+`ct'..1+`ct'+`cz'] = J(1,`cz',0); `T' = select(`T',`select')
				}
			}
		else if ("`constant'" == "") {
			`T' = mean(`dat'[1...,1..1+`ct'+`cz'+`cx']); `dat'[1...,1..1+`ct'+`cz'+`cx'] = `dat'[1...,1..1+`ct'+`cz'+`cx']:-`T' 
			`select' = J(1,1+`ct'+`cz'+`cx',1); `select'[1,2+`ct'..1+`ct'+`cz'] = J(1,`cz',0); `T' = select(`T',`select'); `W' = J(`n',1,1)
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
			`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = `ttt'*quadcross(`se',`se')*`ttt'
			}
		else {
			`se' = `ttt'*quadcross(`e',`e')/`N'
			}
		`B'[1..`ct',1..2] = `biv', `adj'*sqrt(diagonal(`se'))
		if (`cx' > 0) {
			`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
			if ("`constant'" == "") {
				`beta' = `beta' \ (`T'[1,1] - `T'[1,2..1+`ct'+`cx']*(`biv' \ `beta'))
				`xtilde' = `xtilde', (`W'/`sumW' - `x'*`xx'*`T'[1,2+`ct'..1+`ct'+`cx']' - `tt'*`ttt'*(`T'[1,2..1+`ct']'-`bx'[1...,2..1+`ct']'*`T'[1,2+`ct'..1+`ct'+`cx']'))
				}
			if ("`cluster'" ~= "") {
				`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcolsum(`se':*`se')
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = quadcolsum(`se':*`se')
				}
			else {
				`se' = quadcolsum(`xtilde':*`xtilde')*quadcross(`e',`e')/`N'
				}
			`B'[`ct'+1..`ct'+`cxx',1..2] = `beta', `adj'*sqrt(`se')'
			}
		else if ("`constant'" == "") {
			`beta' = `T'[1,1] - `T'[1,2..1+`ct']*`biv'; `xtilde' = `W'/`sumW' - `tt'*`ttt'*`T'[1,2..1+`ct']'
			if ("`cluster'" ~= "") {
				`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcross(`se',`se')
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = quadcross(`se',`se')
				}
			else {
				`se' = quadcross(`xtilde',`xtilde')*quadcross(`e',`e')/`N'
				}
			`B'[`ct'+1,1..2] = `beta', `adj'*sqrt(`se')'
			}
*Permute
		if (`reps' > 0) {
			`ResB' = J(`reps',`ct'+`cxx',0); `ResSE' = J(`reps',`ct'+`cxx',0); `TT' = `T'
			if (`cx' > 0) `orderx' = range(1,`cx',1); if (`ct' > 1) `ordert' = range(1,`ct',1)
			}
		for(`count'=1;`count'<=`reps';`count'++) {
			`dat' = jumble(`dat'); `y' = `dat'[1...,1]; `t' = `dat'[1...,2..1+`ct']; `z' = `dat'[1...,2+`ct'..1+`ct'+`cz']
			if ("`weight'" ~= "") `W' = `dat'[1...,2+`ct'+`cz'+`cx']; `T' = `TT'; `nordert' = 1 
			if (`cz' > 1) {
				`z' = `z''; `z' = jumble(`z'); `z' = `z''
				}
			if (`ct' > 1) {
				`t' = `t''; if ("`constant'" == "") `t' = `t', `T'[1,2..1+`ct']'; `t' = `t',`ordert'; `t' = jumble(`t')
				`nordert' = `t'[1...,cols(`t')]; if ("`constant'" == "") `T'[1,2..1+`ct'] = `t'[1...,cols(`t')-1]'; `t' = `t'[1...,1..`n']'
				}
			if (`cx' > 0) {
				`Y' = `y', `t', `z'; `x' = `dat'[1...,2+`ct'+`cz'..1+`ct'+`cz'+`cx']; `norderx' = 1
				 `x' = `x''; if ("`constant'" == "") `x' = `x', `T'[1,2+`ct'..1+`ct'+`cx']'; `x' = `x',`orderx'; `x' = jumble(`x') 
				`norderx' = `x'[1...,cols(`x')]; if ("`constant'" == "") `T'[1,2+`ct'..1+`ct'+`cx'] = `x'[1...,cols(`x')-1]'; `x' = `x'[1...,1..`n']'
				`xx' = invsym(quadcross(`x',`x')); `bx' = `xx'*quadcross(`x',`Y'); `Y' = `Y' - `x'*`bx'; `y' = `Y'[1...,1]; `t' = `Y'[1...,2..1+`ct']; `z' = `Y'[1...,2+`ct'..1+`ct'+`cz']
				}
			`zz' = invsym(quadcross(`z',`z')); `zt' = quadcross(`z',`t'); `zy' = quadcross(`z',`y'); `tt' = `z'*(`zz'*`zt'); `ttt' = invsym(quadcross(`tt',`tt')); `biv' =`ttt'*quadcross(`tt',`y'); `e' = `y' - `t'*`biv'
			if ("`cluster'" ~= "") {
				`te' = `tt':*`e'; `te' = `te', `dat'[1...,cols(`dat')]; `te' = sort(`te',cols(`te')); `info' = panelsetup(`te',cols(`te')); `te' = `te'[1...,1..cols(`te')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`te'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`te'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `ttt'*quadcross(`se',`se')*`ttt'
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = `ttt'*quadcross(`se',`se')*`ttt'
				}
			else {
				`se' = `ttt'*quadcross(`e',`e')/`N'
				}
			`se' = `biv', sqrt(diagonal(`se')),`nordert'; `se' = sort(`se',3)
			`ResB'[`count',1..`ct'] = `se'[1...,1]'; `ResSE'[`count',1..`ct'] = `adj'*`se'[1...,2]' 
			if (`cx' > 0) {
				`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
				if ("`constant'" == "") {
					`beta' = `beta' \ (`T'[1,1] - `T'[1,2..1+`ct'+`cx']*(`biv' \ `beta')); `norderx' = `norderx' \ .
					`xtilde' = `xtilde', (`W'/`sumW' - `x'*`xx'*`T'[1,2+`ct'..1+`ct'+`cx']' - `tt'*`ttt'*(`T'[1,2..1+`ct']'-`bx'[1...,2..1+`ct']'*`T'[1,2+`ct'..1+`ct'+`cx']'))
					}
				if ("`cluster'" ~= "") {
					`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
					for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcolsum(`se':*`se')
					}
				else if ("`robust'" ~= "" | "`weight'" == "pweight") {
					`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = quadcolsum(`se':*`se')
					}
				else {
					`se' = quadcolsum(`xtilde':*`xtilde')*quadcross(`e',`e')/`N'
					}
				`se' = `beta', sqrt(`se')',`norderx'; `se' = sort(`se',3)
				`ResB'[`count',1+`ct'..`ct'+`cxx'] = `se'[1...,1]'; `ResSE'[`count',1+`ct'..`ct'+`cxx'] = `adj'*`se'[1...,2]' 
				}
			else if ("`constant'" == "") {
				`beta' = `T'[1,1] - `T'[1,2..1+`ct']*`biv'; `xtilde' = `W'/`sumW' - `tt'*`ttt'*`T'[1,2..1+`ct']'
				if ("`cluster'" ~= "") {
					`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
					for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = quadcolsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = quadcross(`se',`se')
					}
				else if ("`robust'" ~= "" | "`weight'" == "pweight") {
					`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`W'; `se' = quadcross(`se',`se')
					}
				else {
					`se' = quadcross(`xtilde',`xtilde')*quadcross(`e',`e')/`N'
					}
				`ResB'[`count',1+`ct'] = `beta'; `ResSE'[`count',1+`ct'] = `adj'*sqrt(`se')
				}
			}
		`Res' = J(rows(`B'),6,0); `Res'[1...,1..2] = `B'; `Res'[1...,3] = abs(`Res'[1...,1]:/`Res'[1...,2])
		if ("`small'" ~= "") `Res'[1...,4..6] = Ftail(1,`dof',`Res'[1...,3]:^2), `Res'[1...,1]-invttail(`dof',.025)*`Res'[1...,2],`Res'[1...,1]+invttail(`dof',.025)*`Res'[1...,2]
		if ("`small'" == "") `Res'[1...,4..6] = chi2tail(1,`Res'[1...,3]:^2), `Res'[1...,1]-invnormal(.975)*`Res'[1...,2],`Res'[1...,1]+invnormal(.975)*`Res'[1...,2]
		if (`reps' > 0) {
			`bmin' = colmin(`ResB'); `bmax' = colmax(`ResB'); `semin' = colmin(`ResSE'); `semax' = colmax(`ResSE')
			st_matrix("`ResB'",`ResB'); st_matrix("`ResSE'",`ResSE'); `Res' = `Res', `bmin'', `bmax'', `semin'', `semax''
			}
		st_matrix("`Res'",`Res')
		}

if ("`constant'" == "") local anything = "`anything'" + "_cons"
if ("`reps'" ~= "0") {
	matrix colnames `ResB' = `endovars' `anything' 
	matrix colnames `ResSE' = `endovars' `anything' 
	ereturn matrix ResB = `ResB', copy
	ereturn matrix ResSE = `ResSE', copy
	if ("`small'" == "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper mincoef maxcoef minse maxse
	if ("`small'" ~= "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper mincoef maxcoef minse maxse
	}
else {
	if ("`small'" == "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper 
	if ("`small'" ~= "") matrix colnames `Res' = coef  se |z| P>|z| 95%lower 95%upper 
	}
matrix rownames `Res' = `endovars' `anything' 
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
	local ct = `ct' + `cxx'
	local list = "`endovars'" + " " + "`anything'"
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
	local list = "`endovars'" + " " + "`anything'"
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

display as text "Instrumented: `endovars'"
display as text "Excluded instruments: `zvars'"
display as text "Included instruments: `anything'"
if ("`absorb'" ~= "") display as text "Fixed effects for `absorb' as included instruments"
if ("`robust'" == "" & "`cluster'" == "") local list = "Homoskedastic standard errors"
if ("`robust'" ~= "" & "`cluster'" == "") local list = "Heteroskedasticity robust standard errors"
if ("`cluster'" ~= "") local list = "Clustered standard errors"
display as text "`list' "
if ("`small'" ~= "") display as text "Results reported with Stata's small sample adjustment of std. err. & degrees of freedom."
display " "
if ("`absorb'" == "") display as text "Maximum R2 found in the regression of one instrument on the others:", _continue
if ("`absorb'" ~= "") display as text "Maximum partial (net of fixed effects) R2 found in the regression of one instrument on the others:", _continue
display as result %10.8g `R2max'[1,1]

foreach j in B ResB ResSE orderx ordert norderx nordert biv bx beta se select xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl abs count ii bmin bmax semin semax Res R2max T TT abs W sumW N n {
	capture mata mata drop ``j''
	}

set seed `oldseed'
set matsize `oldmatsize'

end



