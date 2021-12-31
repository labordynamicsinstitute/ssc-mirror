*! version 1.0.0 23 September 2021

program ivpermute, eclass
	version 13.1
	syntax anything [aw pw fw] [if] [in], [robust cluster(varname) noCONStant reps(integer 10) seed(integer 1) small] 

	tempname B ResB ResSE orderx ordert orderz norderx nordert norderz biv bx beta se 
	tempname xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl count ii R2max L sample T TT 
	tempname bmin bmax semin semax Res
	tempvar c Cl
	display " "

*Initial Estimation using ivregress

	ivregress 2sls `anything' `if' `in' [`weight' `exp'], `robust' cluster(`cluster') `constant' `small'
	quietly gen `sample' = e(sample)
	matrix `B' = e(V)
	local N = e(N)

*Extracting locals
	local y = e(depvar)
	local dep = e(instd)
	local ct = wordcount("`dep'")
	capture local cx = wordcount(e(exogr))
	if (_rc ~= 0) local cx = 0
	local list = e(insts)
	local nlist = wordcount("`list'")
	local zvars = ""
	local xvars = ""
	forvalues i = 1/`nlist' {
		local a = word("`list'",`i')
		if ( strpos("`a'","o.") ~= 1 & `B'[`i'+`ct',`i'+`ct'] ~= 0 & `i' <= `cx') local xvars = "`xvars'" + "`a'" + " "
		if ( strpos("`a'","o.") ~= 1 & `i' > `cx') local zvars = "`zvars'" + "`a'" + " "
		}
	local cz = wordcount("`zvars'")
	local cx = wordcount("`xvars'")
	if (`ct' == 0 | `cz' == 0) {
		display as error "To use ivpermute equation must have at least one endogenous variable and one excluded instrument."
		exit
		}
	if ("`exp'" ~= "") gettoken token ww: exp, parse("=")

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
	if ("`small'" ~= "" & "`cluster'" ~= "") {
		quietly sum `Cl' 
		local adj = sqrt((`N'-1)*r(max)/((r(max)-1)*(`N'-`ct'-`cx')))
		}
	else if ("`small'" ~= "") {
		local adj = sqrt(`N'/(`N'-`ct'-`cx'))
		}
	else {
		local adj = 1
		}

	local oldseed = "`c(seed)'"
	set seed `seed'

	local max = max(`reps',`ct'+`cx')
	quietly query memory
	local oldmatsize = "`r(matsize)'"
	if (r(matsize) < `max') set matsize `max'

	local newlist = "`zvars'" + " " + "`xvars'"
	if ("`constant'" == "") quietly matrix accum `B' = `newlist' [`weight' `exp'] if `sample', deviations noconstant
	if ("`constant'" ~= "") quietly matrix accum `B' = `newlist' [`weight' `exp'] if `sample', noconstant
	mata `T' = st_matrix("`B'"); `TT' = invsym(`T'); `T' = 1:/(diagonal(`TT'):*diagonal(`T')); `T' = 1:-`T'; `TT' = colmax(`T'); st_matrix("`R2max'",`TT')

	mata {
*Base estimates
		`B' = J(`ct'+`cx',2,0); `ResB' = J(`reps',`ct'+`cx',0); `ResSE' = J(`reps',`ct'+`cx',0)
		if (`cx' > 1) {
			`orderx' = J(`cx',1,1); for(`ii'=2;`ii'<=`cx';`ii'++) `orderx'[`ii',1] = `ii'
			}
		if (`cz' > 1) {
			`orderz' = J(`cz',1,1); for(`ii'=2;`ii'<=`cz';`ii'++) `orderz'[`ii',1] = `ii'
			}
		if (`ct' > 1) {
			`ordert' = J(`ct',1,1); for(`ii'=2;`ii'<=`ct';`ii'++) `ordert'[`ii',1] = `ii'
			}
		`dat' = st_data(.,"`y' `dep' `zvars' `xvars' `extra'","`sample'")
		if ("`weight'" ~= "" & "`cluster'" ~= "") {
			`dat'[1...,cols(`dat')-1] = sqrt(`dat'[1...,cols(`dat')-1]); `dat'[1...,1..cols(`dat')-2] = `dat'[1...,1..cols(`dat')-2]:*`dat'[1...,cols(`dat')-1]
			}
		if ("`weight'" ~= "" & "`cluster'" == "") {
			`dat'[1...,cols(`dat')] = sqrt(`dat'[1...,cols(`dat')]); `dat'[1...,1..cols(`dat')-1] = `dat'[1...,1..cols(`dat')-1]:*`dat'[1...,cols(`dat')]
			}
		`Y' = `dat'[1...,1..1+`ct'+`cz']
		if (`cx' > 0) {
			`x' = `dat'[1...,2+`ct'+`cz'..1+`ct'+`cz'+`cx']; `xx' = invsym(`x''`x'); `bx' = `xx'*(`x''`Y'); `Y' = `Y' - `x'*`bx'
			}
		`y' = `Y'[1...,1]; `t' = `Y'[1...,2..1+`ct']; `z' = `Y'[1...,2+`ct'..1+`ct'+`cz']
		`zz' = invsym(`z''`z'); `zt' = `z''`t'; `zy' = `z''`y'; `tt' = `z'*(`zz'*`zt'); `ttt' = invsym(`tt''`tt'); `biv' =`ttt'*(`tt''`y'); `e' = `y' - `t'*`biv'
		if ("`cluster'" ~= "") {
			`te' = `tt':*`e'; `te' = `te', `dat'[1...,cols(`dat')]; `te' = sort(`te',cols(`te')); `info' = panelsetup(`te',cols(`te')); `te' = `te'[1...,1..cols(`te')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`te'),0)
			for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = colsum(`te'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `ttt'*(`se''`se')*`ttt'
			}
		else if ("`robust'" ~= "" | "`weight'" == "pweight") {
			`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `ttt'*(`se''`se')*`ttt'
			}
		else {
			`se' = `ttt'*(`e''`e')/`N'
			}
		`B'[1..`ct',1..2] = `biv', `adj'*sqrt(diagonal(`se'))
		if (`cx' > 0) {
			`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
			if ("`cluster'" ~= "") {
				`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = colsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `se''`se'
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `se''`se'
				}
			else {
				`se' = (`xtilde''`xtilde')*(`e''`e')/`N'
				}
			`B'[`ct'+1..`ct'+`cx',1..2] = `beta', `adj'*sqrt(diagonal(`se'))
			}
*Permute
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
			`xx' = invsym(`x''`x'); `bx' = `xx'*(`x''`Y'); `Y' = `Y' - `x'*`bx'; `y' = `Y'[1...,1]; `t' = `Y'[1...,2..1+`ct']; `z' = `Y'[1...,2+`ct'..1+`ct'+`cz']
			}
		`zz' = invsym(`z''`z'); `zt' = `z''`t'; `zy' = `z''`y'; `tt' = `z'*(`zz'*`zt'); `ttt' = invsym(`tt''`tt'); `biv' =`ttt'*(`tt''`y'); `e' = `y' - `t'*`biv'; 
		if ("`cluster'" ~= "") {
			`te' = `tt':*`e'; `te' = `te', `dat'[1...,cols(`dat')]; `te' = sort(`te',cols(`te')); `info' = panelsetup(`te',cols(`te')); `te' = `te'[1...,1..cols(`te')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`te'),0)
			for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = colsum(`te'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `ttt'*(`se''`se')*`ttt'
			}
		else if ("`robust'" ~= "" | "`weight'" == "pweight") {
			`se' = `tt':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `ttt'*(`se''`se')*`ttt'
			}
		else {
			`se' = `ttt'*(`e''`e')/`N'
			}
		`se' = `biv', sqrt(diagonal(`se')),`nordert'; `se' = sort(`se',3)
		`ResB'[`count',1..`ct'] = `se'[1...,1]'; `ResSE'[`count',1..`ct'] = `adj'*`se'[1...,2]' 
		if (`cx' > 0) {
			`beta' = `bx'[1...,1]-`bx'[1...,2..1+`ct']*`biv'; `xtilde' = `x'*`xx'  - `tt'*`ttt'*`bx'[1...,2..1+`ct']'
			if ("`cluster'" ~= "") {
				`xtilde' = `xtilde':*`e'; `xtilde' = `xtilde', `dat'[1...,cols(`dat')]; `xtilde' = sort(`xtilde',cols(`xtilde')); `info' = panelsetup(`xtilde',cols(`xtilde')); `xtilde' = `xtilde'[1...,1..cols(`xtilde')-1]; `cl' = rows(`info'); `se' = J(`cl',cols(`xtilde'),0)
				for(`ii'=1;`ii'<=`cl';`ii'++) `se'[`ii',1...] = colsum(`xtilde'[`info'[`ii',1]..`info'[`ii',2],1...]); `se' = `se''`se'
				}
			else if ("`robust'" ~= "" | "`weight'" == "pweight") {
				`se' = `xtilde':*`e'; if ("`weight'" == "fweight") `se' = `se':/`dat'[1...,cols(`dat')]; `se' = `se''`se'
				}
			else {
				`se' = (`xtilde''`xtilde')*(`e''`e')/`N'
				}
			`se' = `beta', sqrt(diagonal(`se')),`norderx'; `se' = sort(`se',3)
			`ResB'[`count',1+`ct'..`ct'+`cx'] = `se'[1...,1]'; `ResSE'[`count',1+`ct'..`ct'+`cx'] = `adj'*`se'[1...,2]' 
			}
		}
	`bmin' = colmin(`ResB'); `bmax' = colmax(`ResB'); `semin' = colmin(`ResSE'); `semax' = colmax(`ResSE')
	`Res' = J(rows(`B'),6,0); `Res'[1...,1..2] = `B'; for (`ii'=1;`ii'<=rows(`Res');`ii'++) `Res'[`ii',3..6] = (`bmin'[1,`ii'], `bmax'[1,`ii'], `semin'[1,`ii'], `semax'[1,`ii'])
	st_matrix("`ResB'",`ResB'); st_matrix("`ResSE'",`ResSE'); st_matrix("`Res'",`Res')
	}

if ("`constant'" == "") local xvars = "`xvars'" + "_cons"
matrix colnames `ResB' = `dep' `xvars' 
matrix colnames `ResSE' = `dep' `xvars'
matrix rownames `Res' = `dep' `xvars'
matrix colnames `Res' = coef  se mincoef maxcoef minse maxse

display " "
display as text "Estimates using partitioned IV regression (`reps' permutations):"
display " "
display as text "                       Estimates             Permuted Coef.         Permuted Std. Err.
display as text "                   Coef.    Std. Err.        min        max           min        max"  
display "{hline 13}{c +}{hline 72}"
local ct = `ct' + `cx'
local list = "`dep'" + " " + "`xvars'"
forvalues i = 1/`ct' {	
	display as text %12s abbrev(word("`list'",`i'),12) " {c |}", _continue
	display as result %10.7g `Res'[`i',1], _continue
	display as result %10.7g `Res'[`i',2], _continue
	display "  ", _continue
	display as result %10.7g `Res'[`i',3], _continue
	display as result %10.7g `Res'[`i',4], _continue
	display "  ", _continue
	display as result %10.7g `Res'[`i',5], _continue
	display as result %10.7g `Res'[`i',6]
	}
display "{hline 13}{c BT}{hline 72}"
display as text "Instrumented: `dep'"
display as text "Excluded instruments: `zvars'"
display as text "Included instruments: `xvars'"
display " "
display as text "Maximum R2 found in the regression of any one instrument on the others:", _continue
display as result %8.6g `R2max'[1,1]

ereturn matrix Res = `Res', copy
ereturn matrix ResB = `ResB', copy
ereturn matrix ResSE = `ResSE', copy
ereturn matrix R2max = `R2max', copy

foreach j in B ResB ResSE orderx ordert orderz norderx nordert norderz biv bx beta se xx zz dat zt zy Y ttt tt te xtilde info x t y z e cl count ii L bmin bmax semin semax Res R2max T TT {
	capture mata mata drop ``j''
	}

set seed `oldseed'
set matsize `oldmatsize'

end

