*! version 3.0.0 July 2023

program randcmdci, eclass
	version 15.1
	syntax anything [aw pw] [if] [in], treatvars(varlist) testvars(varlist) [robust cluster(varname) noCONStant absorb(varname) reps(integer 999) strata(varname) groupvar(varname) seed(real 1) max(string) maxcoef(real 0) maxwald(real 0) maxlevel(integer 100) calc1(string) calc2(string) calc3(string) calc4(string) calc5(string) calc6(string) calc7(string) calc8(string) calc9(string) calc10(string) calc11(string) calc12(string) calc13(string) calc14(string) calc15(string) calc16(string) calc17(string) calc18(string) calc19(string) calc20(string) null1(string) null2(string) null3(string) null4(string) null5(string) null6(string) null7(string) null8(string) null9(string) null10(string) ]  
	tempname ei n nk nnk nc info clinfo B BB bb vv V VV VVV dvec S A c0 b0 A0
	tempname Atilde btilde ctilde F2 Ra Rb Rc RRa RRb RRc RR xbase ak p pp ppp rho
	tempname shrink value value2 alpha beta gamma xstar xr xe xc x0 E L sela nsela sel1 sel2 sel3
	tempname X Y Z T W Z2 z2 w y z qqq xxx Aid WAid c1 c2 c3 list dcz x xx
	tempname a b c d e roots der test ii jj iii jjj cc ccc g dim uu uuu
	tempname tmatrix Resnull Rtest yy btest VVt Vtest dif Resdif2 r maxp
	tempname Bsel Vsel nsel sel Resb Resse Resder Resroots Restest Restie maxlist
	tempvar U Order OldOrder M MM Abs Cl touse

	display " "
*Extracting locals
	gettoken cmd anything: anything
	gettoken dep anything: anything
	unab anything: `anything'
	unab testvars: `testvars'
	unab treatvars: `treatvars'
	local treatnumber = wordcount("`testvars'")
	foreach var in `testvars' {
		local anything = subinword("`anything'","`var'","",1)
		}
	if ("`exp'" ~= "") gettoken token ww: exp, parse("=")
	if ("`constant'" ~= "" & "`absorb'" ~= "") {
		local constant = ""
		display as error "noconstant not compatible with absorb and is dropped."
		}
	if (substr("`cmd'",1,3) == "reg") local cmd = "reg"
	if ("`absorb'" ~= "" & "`cmd'" ~= "areg") local cmd = "areg"

*Checking estimation method is currently supported 
	local error = 0
	if ("`cmd'" ~= "reg" & "`cmd'" ~= "areg") {
		local error = 1
		display as error "Only regress & areg, but not `cmd' supported by randci."
		}
	if (`reps' < 1) {
		local error = 1
		display as error "reps() must be greater than 0."
		}
	if (`maxcoef' ~= 0 & `maxwald' ~= 0) {
		local error = 1
		display as error "Both maxcoef & maxwald selected.  Select one or the other."
		}
	if (`maxlevel' <= 0) {
		local error = 1
		display as error "maxlevel must be a positive integer"
		}
	if (`maxcoef' < 0) {
		local error = 1
		display as error "maxcoef must be a positive real number."
		}
	if (`maxwald' < 0) {
		local error = 1
		display as error "maxwald must be a positive real number."
		}
	if (`error' == 1) exit

preserve

*Establishing sample (treatvars ~= .)
	foreach var in `treatvars' {
		quietly drop if `var' == .
		}

*Baseline estimating equation
	if ("`cmd'" == "reg") `cmd' `dep' `testvars' `anything' [`weight' `exp'] `if' `in', `constant' robust cluster(`cluster')
	if ("`cmd'" == "areg" & "`cluster'" ~= "") `cmd' `dep' `testvars' `anything' [`weight' `exp'] `if' `in', absorb(`absorb') cluster(`cluster')
	if ("`cmd'" == "areg" & "`cluster'" == "") `cmd' `dep' `testvars' `anything' [`weight' `exp'] `if' `in', absorb(`absorb') robust
	quietly gen `touse' = e(sample)
		matrix `bb' = e(b)
		matrix `vv' = e(V)
	quietly keep if `touse'
	if ("`cluster'" ~= "") quietly egen `Cl' = group(`cluster')
	if ("`absorb'" ~= "") quietly egen `Abs' = group(`absorb')

*Checking all testvars are identified 
	local i = 1
	foreach var in `testvars' {
		if (`bb'[1,`i'] == 0 & `vv'[`i',`i'] == 0) {
			display as error "Test variable `var' not identified in estimating equation."
			local error = 1
			}
		local i = `i' + 1
		}
	if (`error' == 1) exit
	local newanything = ""
	foreach var in `anything' {
		if (`vv'[`i',`i'] ~= 0) {
			local newanything = "`newanything'" + "`var' "
			}
		local i = `i' + 1
		}
	local anything = "`newanything'"

*Checking consistency of groupings & strata
	local error = 0
	if ("`groupvar'" ~= "") {
		foreach var in `treatvars' {
			quietly egen `M' = sd(`var'), by(`groupvar')
			quietly sum `M'
			if (r(mean) > 0 & r(mean) ~= .) {
				display as error "`var' varies within `groupvar'.  Base treatment variables should not vary within treatment groupings."
				local error = 1
				}
			quietly drop `M' 
			}
		if ("`strata'" ~= "") {
			quietly egen `M' = group(`strata'), missing
			quietly egen `MM' = sd(`M'), by(`groupvar')
			quietly sum `MM'
			if (r(mean) > 0 & r(mean) ~= .) {
				display as error "`strata' varies within `groupvar'.  Strata should not vary within treatment groupings."
				local error = 1
				}
			quietly drop `M' `MM'
			}
		}
	if ("`cluster'" ~= "" & "`absorb'" ~= "") {
		quietly egen `M' = sd(`Cl'), by(`Abs')
		quietly sum `M'
		if (r(mean) > 0 & r(mean) ~= .) {
			local subset = "no"
			}
		quietly drop `M'
		}
	if (`error' == 1) exit
	if ("`groupvar'" ~= "") {
		quietly egen `M' = group(`groupvar')
		quietly sum `M'
		if (r(N) ~= _N) {
			display as error "`groupvar' is missing for some observations.  Randcmdci will treat missing values as one randomization group."
			}	
		quietly drop `M'
		}
	if ("`strata'" ~= "") {
		quietly egen `M' = group(`strata')
		quietly sum `M'
		if (r(N) ~= _N) {
			display as error "`strata' is missing for some observations.  Randcmdci will treat missing values as one strata."
			}
		quietly drop `M'
		foreach var in `treatvars' {
			quietly egen `M' = sd(`var'), by(`strata')
			quietly sum `M'
			if (r(mean) == 0 | r(N) == 0) {
				display as error "`var' does not vary with strata.  Base treatment variables must vary within strata."
				local error = 1
				}
			quietly drop `M' 
			}
		}
	if (`error' == 1) exit
	
*Checking & displaying treatment variables, calculations & tests so that user can confirm that programme has correctly interpreted requests
	local calc = 0
	local j = 0
	forvalues k = 1/20 {
		if ("`calc`k''" ~= "") {
			local j = `j' + 1 
			if (`j' ~= `k') local calc`j' = "`calc`k''"
			}
		}
	local calc = `j'

	local tnumber = 0
	local j = 0
	forvalues k = 1/10 {
		if ("`null`k''" ~= "") {
			local j = `j' + 1
			if (`j' ~= `k') local null`j' = "`null`k''"
			matrix `tmatrix' = `null`j''
			if (colsof(`tmatrix') ~= `treatnumber') {
				display as error "Tested null hypotheses must specify a null for all treatment effects."
				display as error "Each null() must specify a 1 x `treatnumber' row vector of real numbers."
				display as error "See examples in help randcmdci."
				local error = 1
				} 
			}
		}
	local tnumber = `j'

	local mcount = 0
	local width = (`treatnumber'-1)*`treatnumber'/2
	matrix `maxlist' = J(1,`treatnumber',0)
	if ("`max'" ~= "" & `treatnumber' > 1) {
		unab max: `max'
		local j = 0
		foreach word in `testvars' {
			local j = `j' + 1
			if ("`max'" ~= subinword("`max'","`word'","",1)) matrix `maxlist'[1,`j'] = 1
			}
		local mlist = ""
		forvalues k = 1/`treatnumber' {
			if (`maxlist'[1,`k'] == 1) local mlist = "`mlist'" + " " + word("`testvars'",`k')
			}
		local mcount = wordcount("`mlist'")
		if (`mcount' == 0) {
			display as error "None of the variables in max(`max') could be found in testvars(`testvars')."
			local error = 1
			}
		}
	mata `maxlist' = st_matrix("`maxlist'")
	if (`error' == 1) exit

	mata `tmatrix' = .
	if (`tnumber' > 0) {
		matrix `tmatrix' = J(`tnumber',`treatnumber',0)
		forvalues k = 1/`tnumber' {
			capture matrix `tmatrix'[`k',1] = `null`k''
			forvalues j = 1/`treatnumber' {
				if (`tmatrix'[`k',`j'] == .) matrix `tmatrix'[`k',`j'] = 0
				}
			}
		matrix `tmatrix' = `tmatrix''
		mata `tmatrix' = st_matrix("`tmatrix'")
		}

	display " "
	display as text "Treatment variables determined directly by randomization: `treatvars'.", _newline
	display as text "Treatment based variables tested in estimating equation: `testvars'.", _newline
	display as text "Post-randomization treatment based calculations:  `calc'."
	forvalues k = 1/`calc' {
		display "  `k':   `calc`k''" 
		}
	display " "
	if (`mcount' > 0) {
		display as text "User requested calculation of maximum p-value across nulls for other treatment effects for: `mlist'.", _newline
		}

	if (`tnumber' > 0) {
		display as text "User requested tests of specific joint null hypotheses: `tnumber'."
		display as text %15s " ", _continue
		forvalues i = 1/`tnumber' {
			display as text "    test`i' ", _continue
			}
		display " "
		local j = `tnumber'*11 + 2
		display "{hline 13}{c +}{hline `j'}"
		forvalues i = 1/`treatnumber' {	
			display as text %12s abbrev(word("`testvars'",`i'),12) " {c |}", _continue
			forvalues k = 1/`tnumber' {
				local l = `tmatrix'[`i',`k']
				display as text %10.8g `l', _continue
				}
			display " "
			}
		display "{hline 13}{c +}{hline `j'}"
		display " "
		}

*Preparing variables and matrices to be used in randomization analysis
	quietly generate `OldOrder' = _n
	sort `cluster' `absorb' `OldOrder'
	quietly generate `Order' = _n
	local oldseed = "`c(seed)'"
	set seed `seed'
	if ("`absorb'" == "" & "`constant'" == "") local anything = "`anything'" + " `touse'"
	local Xcount = wordcount("`anything'")

	mata {
		if (`Xcount' > 0) {
			`X' = st_data(.,"`anything'",.); `Y' = st_data(.,"`dep'",.); `Z' = st_data(.,"`testvars'",.); `W' = J(rows(`Y'),1,1)
			if ("`ww'" ~= "") `W' = st_data(.,"`ww'",.); `W' = `W'/mean(`W'); `w' = sqrt(`W')
			if ("`absorb'" ~= "") {
				if ("`subset'" == "") {
					`Aid' = st_data(.,"`Abs'",.); `info' = panelsetup(`Aid',1) 
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `X'[`info'[`ii',1]..`info'[`ii',2],1...] = `X'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`X'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1...] = `Y'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1...] = `Z'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					}
				else {
					`Aid' = st_data(.,("`Abs'","`Order'"),.); `X' = `X', `Aid'; `Y' = `Y', `Aid'; `Z' = `Z', `Aid'; `WAid' = `W',`Aid'
					_sort(`X',(`Xcount'+1,`Xcount'+2)); _sort(`Z',(`treatnumber'+1,`treatnumber'+2)); _sort(`Y',(2,3)); _sort(`WAid',(2,3)); `info' = panelsetup(`Y',2) 
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `X'[`info'[`ii',1]..`info'[`ii',2],1..`Xcount'] = `X'[`info'[`ii',1]..`info'[`ii',2],1..`Xcount']:-mean(`X'[`info'[`ii',1]..`info'[`ii',2],1..`Xcount'],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1] = `Y'[`info'[`ii',1]..`info'[`ii',2],1]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'] = `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber']:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					_sort(`X',`Xcount'+2); _sort(`Z',`treatnumber'+2); _sort(`Y',3); `X' = `X'[1...,1..`Xcount']; `Y' = `Y'[1...,1]; `Z' = `Z'[1...,1..`treatnumber']
					}
				}
			`X' = `X':*`w'; `Y' = `Y':*`w'; `Z' = `Z':*`w'
			`xxx' = invsym(`X''*`X')*`X''; `y' = `Y' - `X'*(`xxx'*`Y'); `z' = `Z' - `X'*(`xxx'*`Z')
			}
		else {
			`Y' = st_data(.,"`dep'",.); `Z' = st_data(.,"`testvars'",.); `W' = J(rows(`Y'),1,1)
			if ("`ww'" ~= "") `W' = st_data(.,"`ww'",.); `W' = `W'/mean(`W'); `w' = sqrt(`W')
			if ("`absorb'" ~= "") {
				if ("`subset'" == "") {
					`Aid' = st_data(.,"`Abs'",.); `info' = panelsetup(`Aid',1) 
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1...] = `Y'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1...] = `Z'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					}
				else {
					`Aid' = st_data(.,("`Abs'","`Order'"),.); `Y' = `Y', `Aid'; `Z' = `Z', `Aid'; `WAid' = `W',`Aid'
					_sort(`Z',(`treatnumber'+1,`treatnumber'+2)); _sort(`Y',(2,3)); _sort(`WAid',(2,3)); `info' = panelsetup(`Y',2)
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1] = `Y'[`info'[`ii',1]..`info'[`ii',2],1]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'] = `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber']:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					_sort(`Z',`treatnumber'+2); _sort(`Y',3); `Y' = `Y'[1...,1]; `Z' = `Z'[1...,1..`treatnumber']
					}
				}
			`Y' = `Y':*`w'; `Z' = `Z':*`w'; `y' = `Y'; `z' = `Z'
			}
		`n' = rows(`Y'); `nk' = `n'-cols(`X')-cols(`Z'); if ("`absorb'" ~= "") `nk' = `nk' - rows(`info')
		`dcz' = invsym(`z''*`z'); `qqq' = `dcz'*`z''; `B' = `qqq'*`y'; `ei' = `y' - `z'*`B'
		if ("`cluster'" ~= "") {
			`Cl' = st_data(.,"`Cl'",.); `clinfo' = panelsetup(`Cl',1); `nc' =  rows(`clinfo'); `V' = J(`nc',`treatnumber',0); `nnk' = (`nc'*(`n'-1))/(`nk'*(`nc'-1))
			for (`ii'=1;`ii'<=`nc';`ii'++) `V'[`ii',1..`treatnumber'] = colsum(`qqq'[1..`treatnumber',`clinfo'[`ii',1]..`clinfo'[`ii',2]]':*`ei'[`clinfo'[`ii',1]..`clinfo'[`ii',2],1])
			`V'= `nnk'*`V''*`V' 
			}
		else {
			`nnk' = `n'/`nk'; `V' = (`qqq':*`ei''); `V' = `nnk'*`V'*`V''
			}
		if (`tnumber' > 0 ) {
			`Rtest' = J(1,`tnumber',.); `VV' = invsym(`V');	for (`ii'=1;`ii'<=`tnumber';`ii'++) `Rtest'[1,`ii'] = (`B'-`tmatrix'[1...,`ii'])'*`VV'*(`B'-`tmatrix'[1...,`ii'])
			}
		}

sort `OldOrder'
*Preparing information to rerandomize treatment 
	if ("`groupvar'" ~= "") {
		egen `M' = group(`groupvar'), missing
		quietly sum `M'
		local N = r(max)
		quietly bysort `M': gen `n' = _n
		sort `n' `strata' `M'
		}
	if ("`groupvar'" == "") {
		local N = _N
		sort `strata' `OldOrder'
		}
	mata `list' = J(1,0,"")
	foreach var in `treatvars' {
		mata `list' = `list', "`var'"
		}
	quietly generate double `U' = .

mata {
	`T' = st_data((1,`N'),"`treatvars'"); `Resnull' = J(`reps',2*`tnumber',.); `Resb' = J(`reps',`treatnumber',.); `Resse' = J(`reps',`treatnumber',.)
	`Resroots' = J(`reps',`treatnumber'*4,.); `Resder' = J(`reps',`treatnumber'*4,.); `Restie' = J(`reps',`treatnumber',.); `Restest' = J(`reps',1,.)
	`Rc' = J(`reps',`mcount',.); `Rb' = J(`reps',`mcount'*(`treatnumber'-1),.); `Ra' = J(`reps',`mcount'*`width',.); `Resdif2' = J(`reps',`mcount',.)
	}	

display as text "Running `reps' randomization iterations:"
	
*Randomization iterations
	forvalues count = 1/`reps' {
		if (ceil(`count'/50)*50 == `count') {
			display "`count'", _continue
			}
		else {
			if (ceil(`count'/10)*10 == `count') display ".", _continue
			}

*Randomizing direct treatment and recalculating treatment based variables
		if ("`groupvar'" == "") {
			quietly sort `strata' `OldOrder'
			quietly replace `U' = uniform()
			quietly sort `strata' `U'
			mata st_store(.,`list',`T')
			}
		if ("`groupvar'" ~= "") {
			quietly sort `n' `strata' `M'  
			quietly replace `U' = uniform() if _n <= `N'
			quietly sort `strata' `U' in 1/`N'
			mata st_store((1,`N'),`list',`T')
			quietly sort `M' `n'
			foreach var in `treatvars' {
				quietly replace `var' = `var'[_n-1] if `n' > 1
				}
			}
		forvalues k = 1/`calc' {
			quietly `calc`k''
			}
		sort `Order'

*Estimating equations
		mata {
			`Z2' = st_data(.,"`testvars'",.)
			if ("`absorb'" ~= "") {
				if ("`subset'" == "") {
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z2'[`info'[`ii',1]..`info'[`ii',2],1...] = `Z2'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Z2'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					}
				else {
					`Z2' = `Z2',`Aid'; _sort(`Z2',(`treatnumber'+1,`treatnumber'+2))					
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z2'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'] = `Z2'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber']:-mean(`Z2'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					_sort(`Z2',`treatnumber'+2); `Z2' = `Z2'[1...,1..`treatnumber']
					}
				}

			if ("`ww'" ~= "") `Z2' = `Z2':*`w' 
			if (`Xcount' > 0) {
				`z2' = `Z2' - `X'*(`xxx'*`Z2') 
				}
			else {
				`z2' = `Z2'
				}
			`dcz' = invsym(`z2''*`z2'); `qqq' = `dcz'*`z2''; `BB' = `qqq'*`y'; `ei' = `y'-`z2'*`BB'
			if ("`cluster'" ~= "") {
				`VV' = J(`nc',`treatnumber',0)
				for (`ii'=1;`ii'<=`nc';`ii'++) `VV'[`ii',1..`treatnumber'] = colsum(`qqq'[1..`treatnumber',`clinfo'[`ii',1]..`clinfo'[`ii',2]]':*`ei'[`clinfo'[`ii',1]..`clinfo'[`ii',2],1])
				`VV'= `nnk'*`VV''*`VV' 
				}
			else {
				`VV' = (`qqq':*`ei''); `VV' = `nnk'*`VV'*`VV''
				}
			`A' = `qqq'*`z'; `VV' = diagonal(`VV'); `Restest'[`count',1] = min(`VV')
			if (`tnumber' > 0) {
				`yy' = `y':+(`z2'-`z')*`tmatrix'; `btest' = `qqq'*`yy'; `yy' = `yy'-`z2'*`btest'; `btest' = `btest'-`tmatrix'
				for(`ii'=1;`ii'<=`tnumber';`ii'++) {
					if ("`cluster'" ~= "") {
						`VVV' = J(`nc',`treatnumber',0); for (`jj'=1;`jj'<=`nc';`jj'++) `VVV'[`jj',1..`treatnumber'] = colsum(`qqq'[1..`treatnumber',`clinfo'[`jj',1]..`clinfo'[`jj',2]]':*`yy'[`clinfo'[`jj',1]..`clinfo'[`jj',2],`ii'])
						}
					else {
						`VVV' = (`qqq'':*`yy'[1...,`ii'])
						}
					`VVV'= invsym(`nnk'*`VVV''*`VVV'); `Resnull'[`count',`ii'] = `btest'[1...,`ii']'*`VVV'*`btest'[1...,`ii']; `Resnull'[`count',`ii'+`tnumber'] = min(diagonal(`VVV'))
					}
				}
			if (`treatnumber' == 1 & `Restest'[`count',1] ~= 0) {
				`a' = `qqq'':*`ei'; `b' =  (`z' - `z2'*`A'):*`qqq''
				if ("`cluster'" ~= "") {
					`dvec' = J(1,1,0); `S' = J(1,1,0)
					for (`iii'=1;`iii'<=`nc';`iii'++) {
						`dvec' = `dvec' + colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])'*colsum(`a'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])
						`S' = `S' + colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])'*colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])
						}
					}
				else {
					`dvec' = `b''*`a'; `S' = `b''*`b'
					}
				`dvec' = `nnk'*`dvec'; `S' = `nnk'*`S'
				`Resb'[`count',1] = `BB'; `Resse'[`count',1] = sqrt(`VV'); `c1' = `S'; `c2' = -`dvec'; `c3' = `VV'
				`a' = -`c1'; `b' = 2*`B'*`c1'-2*`c2'; `c' = `A'*`A'*`V' + 4*`B'*`c2' - `B'*`B'*`c1' - `c3'
				`d' = -2*`V'*`A'*`BB' + 2*`B'*`c3' - 2*`B'*`B'*`c2'; `e' = `BB'*`BB'*`V' -`B'*`B'*`c3'
				`dif' = abs(`a') + abs(`b'/sqrt(`V')) + abs(`c'/`V') + abs(`d'/`V'^1.5) + abs(`e'/`V'^2) 
				if (`dif' > 1e-09) {
					`roots' = polyroots((`e',`d',`c',`b',`a')); for(`jj'=1;`jj'<=4;`jj'++) if(Re(`roots'[1,`jj'])~=`roots'[1,`jj']) `roots'[1,`jj'] = .
					`roots' = Re(`roots'); `roots' = sort(`roots'',1)'; `der' = (4*`a'*(`roots':^3) + 3*`b'*(`roots':^2) + 2*`c'*`roots'):+`d'
					`Resroots'[`count',1..4] = `roots'; `Resder'[`count',1..4] = sign(`der')
					if (`roots'[1,1] == .) `Restie'[`count',1] = 3*sign(`e')
					}
				else {
					`Restie'[`count',1] = 2
					}
				}
			else if (`Restest'[`count',1] ~= 0) {
				`jjj' = 0
				for(`ii'=1;`ii'<=`treatnumber';`ii'++) {
					`a' = `qqq'[`ii',1...]':*`ei'[1...,1]; `b' =  (`z' - `z2'*`A'):*`qqq'[`ii',1...]'
					if ("`cluster'" ~= "") {
						`dvec' = J(`treatnumber',1,0); `S' = J(`treatnumber',`treatnumber',0)
						for (`iii'=1;`iii'<=`nc';`iii'++) {
							`dvec' = `dvec' + colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])'*colsum(`a'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])
							`S' = `S' + colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])'*colsum(`b'[`clinfo'[`iii',1]..`clinfo'[`iii',2],1...])
							}
						}
					else {
						`dvec' = `b''*`a'; `S' = `b''*`b'
						}
					`dvec' = `nnk'*`dvec'; `S' = `nnk'*`S'; `sel' = J(1,`treatnumber',1); `sel'[1,`ii'] = 0; `nsel' = 1:-`sel'; `Bsel' = select(`B',`sel''); `Vsel' = select(diagonal(`V'),`sel'')
					`ak' = select(`A'[`ii',1..`treatnumber'],`sel')
					if (`maxlist'[1,`ii'] == 1) {
						`jjj' = `jjj' + 1; `c0' = `BB'[`ii',1]^2*`V'[`ii',`ii'] - `B'[`ii',1]^2*`VV'[`ii',1]
						`b0' = 2*`B'[`ii',1]^2*select(`dvec'',`sel') - 2*`V'[`ii',`ii']*`BB'[`ii',1]*`ak'; `A0' = `V'[`ii',`ii']*`ak''*`ak'-select(select(`S',`sel'),`sel'')*`B'[`ii',1]^2
						`Resdif2'[`count',`jjj'] = (abs(`c0') + sum(abs(`b0':*sqrt(`Vsel')')) + sum(abs(`A0':*sqrt(`Vsel'*`Vsel''))))/`V'[`ii',`ii']^2
						`Rc'[`count',`jjj'] = `c0'; `Rb'[`count',(`jjj'-1)*(`treatnumber'-1)+1..`jjj'*(`treatnumber'-1)] = `b0'; `Ra'[`count',(`jjj'-1)*`width'+1..`jjj'*`width'] = vech(`A0')'
						}
					`c1' = `S'[`ii',`ii']; `c2' = -`dvec'[`ii',1] + select(select(`S',`sel'),`nsel'')*`Bsel'
					`c3' = `VV'[`ii',1] - 2*select(`dvec',`sel'')'`Bsel' + `Bsel''select(select(`S',`sel'),`sel'')*`Bsel'
					`Resb'[`count',`ii'] = `BB'[`ii',1] - `ak'*`Bsel'; `Resse'[`count',`ii'] = sqrt(`c3')
					`a' = -`c1'; `b' = 2*`B'[`ii',1]*`c1'-2*`c2'; `c' = (`A'[`ii',`ii']^2)*`V'[`ii',`ii'] + 4*`B'[`ii',1]*`c2' - (`B'[`ii',1]^2)*`c1' - `c3'
					`d' = -2*`V'[`ii',`ii']*`A'[`ii',`ii']*`Resb'[`count',`ii'] + 2*`B'[`ii',1]*`c3' - 2*(`B'[`ii',1]^2)*`c2'
					`e' = (`Resb'[`count',`ii']^2)*`V'[`ii',`ii'] - (`B'[`ii',1]^2)*`c3'
					`dif' = abs(`a') + abs(`b'/sqrt(`V'[`ii',`ii'])) + abs(`c'/`V'[`ii',`ii']) + abs(`d'/`V'[`ii',`ii']^1.5) + abs(`e'/`V'[`ii',`ii']^2) 
					if (`dif' > 1e-09) {
						`roots' = polyroots((`e',`d',`c',`b',`a')); for(`jj'=1;`jj'<=4;`jj'++) if(Re(`roots'[1,`jj'])~=`roots'[1,`jj']) `roots'[1,`jj'] = .
						`roots' = Re(`roots'); `roots' = sort(`roots'',1)'; `der' = (4*`a'*(`roots':^3) + 3*`b'*(`roots':^2) + 2*`c'*`roots'):+`d'
						`Resroots'[`count',(`ii'-1)*4+1..4*`ii'] = `roots'; `Resder'[`count',(`ii'-1)*4+1..4*`ii'] = sign(`der')
						if (`roots'[1,1] == .) `Restie'[`count',`ii'] = 3*sign(`e')
						}
					else {
						`Restie'[`count',`ii'] = 2
						}
					}
				}
			}
		}	
mata `uuu' = colsum(`Restest'); st_matrix("`uuu'",`uuu')
if (`uuu'[1,1] == 0) {
	display " "
	display as error "Treatment measures are collinear in `reps' permutations of treatment."
	display as error "Use more reps() or change the regression specification."
	exit
	}

*****************************************************
*****************************************************

*Calculating confidence intervals and p-values

display , _newline
display as text "Calculating confidence intervals", _continue

matrix `VVt' = J(`treatnumber',14,.)	
matrix `VVt'[1,1] = `bb'[1,1..`treatnumber']'

mata `uuu' = uniform(1,`treatnumber'); st_matrix("`uuu'",`uuu')

forvalues j = 1/`treatnumber' {
	quietly drop _all
	quietly set obs `reps'
	foreach var in Root1 Root2 Root3 Root4 Der1 Der2 Der3 Der4 Tie Test {
		quietly generate double `var' = .
		}
	mata st_store(.,.,(`Resroots'[1..`reps',(`j'-1)*4+1..`j'*4],`Resder'[1..`reps',(`j'-1)*4+1..`j'*4],`Restie'[1..`reps',`j'],`Restest'[1..`reps',1]))
	quietly drop if Test == 0
	matrix `VVt'[`j',11] = _N
	
	quietly sum Tie if Tie == 2
	local tie = r(N) + 1
	quietly sum Der1 if Der1 == -1
	local larger = r(N)
	quietly sum Tie if Tie == 3 
	local larger = `larger' + r(N)
	
	quietly gen n = _n	
	quietly reshape long Root Der, i(n) j(step)
	quietly drop if Root == .

	if (_N > 0) {
		collapse (sum) Der, by(Root) fast
		quietly generate double pvalue = `tie'*`uuu'[1,`j'] + `larger' + Der if _n == 1
		quietly replace pvalue = pvalue[_n-1] + Der if _n > 1
		quietly replace pvalue = pvalue/(`VVt'[`j',11]+1)
		local min = (`tie'*`uuu'[1,`j']+`larger')/(`VVt'[`j',11]+1)
		quietly sum pvalue if _n == _N
		local max = r(mean)
		quietly generate Lpvalue = pvalue[_n-1]
		quietly replace Lpvalue = `min' if _n == 1
	
		local i = 5
		local k = 0
		foreach level in .1 .05 .01 {
			quietly sum Root if pvalue > `level' 
			matrix `VVt'[`j',`i'] = r(min)
			quietly sum Root if Lpvalue > `level'
			matrix `VVt'[`j',`i'+1] = r(max)
			if (`min' > `level') matrix `VVt'[`j',`i'] = .
			if (`max' > `level') matrix `VVt'[`j',`i'+1] = .
			quietly sum Root if pvalue > `level' & Lpvalue <= `level'
			local lower = r(max)
			quietly sum Root if Lpvalue > `level' & pvalue <= `level' 
			local upper = r(min)
			if (`lower' ~= . & `upper' ~= . & `lower' > `upper') {
				matrix `VVt'[`j',12+`k'] = 0
				}
			else {
				matrix `VVt'[`j',12+`k'] = 1
				}
			local i = `i' + 2
			local k = `k' + 1
			}
		}

	quietly drop _all
	quietly set obs `reps'
	quietly gen double Resb = .
	quietly gen double Resse = .
	quietly gen double Test = .
	mata st_store(.,.,(`Resb'[1..`reps',`j'],`Resse'[1..`reps',`j'],`Restest'[1..`reps',1]))
	quietly drop if Test == 0
	quietly sum Resb if abs(Resb/Resse) > abs(`bb'[1,`j']/sqrt(`vv'[`j',`j'])) + 1e-09
	local pmin0 = r(N)/(`VVt'[`j',11]+1)
	quietly sum Resb if abs(Resb/Resse) > abs(`bb'[1,`j']/sqrt(`vv'[`j',`j'])) - 1e-09
	local pmax0 = (r(N)+1)/(`VVt'[`j',11]+1)
	matrix `VVt'[`j',2] = (`pmin0',`pmax0',`pmin0'+`uuu'[1,`j']*(`pmax0'-`pmin0'))
	}

matrix rownames `VVt' = `testvars'
matrix colnames `VVt' = coef min-p max-p rand-p 90%CI 90%CI 95%CI 95%CI 99%CI 99%CI reps convex

*****************************************************
*****************************************************

*Displaying results
	display, _newline 
	if (`treatnumber' > 1) {
		display as text "Randomization-t p-values & confidence intervals under the null that other treatment effects equal estimated values.", _newline
		}
	else {
		display as text "Randomization-t p-values & confidence intervals.", _newline
		}
	display as text _col(32) "minimum" _col(42) "maximum" _col(51) "randomized" _col(64) "successful"
	display as text "    variable {c |}" _col(21) "coef." _col(32) "p-value" _col(42) "p-value" _col(52) "p-value" _col(64) "iterations"
	display "{hline 13}{c +}{hline 61}"
	forvalues i = 1/`treatnumber' {
		display as text %12s abbrev(word("`testvars'",`i'),12) " {c |}", _continue
		display as result _col(17) %10.8g `VVt'[`i',1] _col(29) %10.5f `VVt'[`i',2] _col(37) %10.5f `VVt'[`i',3] _col(48) %10.5f `VVt'[`i',4] _col(61) %10.8g `VVt'[`i',11]
		}
	display as text _col(95) "CI Convex?" 
	display as text "    variable {c |}" _col(19) "[90% Conf. Interval]"  _col(44) "[95% Conf. Interval]" _col(69) "[99% Conf. Interval]" _col(94) "90%  95%  99%" 
	display "{hline 13}{c +}{hline 94}"
	forvalues i = 1/`treatnumber' {
		display as text %12s abbrev(word("`testvars'",`i'),12) " {c |}", _continue
		display as result _col(18) %10.8g `VVt'[`i',5] _col(29) %10.8g `VVt'[`i',6] _col(43) %10.8g `VVt'[`i',7] _col(54) %10.8g `VVt'[`i',8] _col(68) %10.8g `VVt'[`i',9] _col(79) %10.8g `VVt'[`i',10], _continue 
		if (`VVt'[`i',12] == 1) display as result _col(94) "yes", _continue
		if (`VVt'[`i',12] == 0) display as result _col(95) "no", _continue
		if (`VVt'[`i',13] == 1) display as result _col(99) "yes", _continue
		if (`VVt'[`i',13] == 0) display as result _col(100) "no", _continue 
		if (`VVt'[`i',14] == 1) display as result _col(104) "yes"
		if (`VVt'[`i',14] == 0) display as result _col(105) "no"
		}
	display " "

	if (`tnumber' > 0) {
		matrix `Vtest' = J(4,`tnumber',.)
		quietly drop _all
		quietly set obs `reps'
		local label = " "
		forvalues i = 1/`tnumber' {
			quietly gen double test`i' = .
			quietly gen double ztest`i' = .
			quietly gen double Rtest`i' = .
			local label = "`label'" + "test`i' "
			}
		aorder
		mata st_store((1,1),(1..`tnumber'),`Rtest'); st_store(.,(`tnumber'+1..3*`tnumber'),`Resnull')

		forvalues i = 1/`tnumber' {
			quietly sum test`i' if test`i' > Rtest`i'[1] + 1e-09 & test`i' ~= . & ztest`i' ~= 0
			matrix `Vtest'[1,`i'] = r(N)
			quietly sum test`i' if test`i' > Rtest`i'[1] - 1e-09 & test`i' ~= . & ztest`i' ~= 0
			matrix `Vtest'[2,`i'] = r(N) + 1
			quietly sum test`i' if test`i' ~= . & ztest`i' ~= 0
			matrix `Vtest'[4,`i'] = r(N) 
			matrix `Vtest'[1,`i'] = `Vtest'[1,`i']/(`Vtest'[4,`i']+1)
			matrix `Vtest'[2,`i'] = `Vtest'[2,`i']/(`Vtest'[4,`i']+1)
			matrix `Vtest'[3,`i'] = `Vtest'[1,`i']+uniform()*(`Vtest'[2,`i']-`Vtest'[1,`i'])
			}

		display as text "User requested tests of specific joint null hypotheses: `tnumber'."
		display " " 
		display as text %24s " ", _continue
		forvalues i = 1/`tnumber' {
			display as text "    test`i' ", _continue
			}
		display " "
		local j = `tnumber'*11 + 2
		display "{hline 22}{c +}{hline `j'}"
		forvalues i = 1/`treatnumber' {	
			display as text %21s abbrev(word("`testvars'",`i'),21) " {c |}", _continue
			forvalues k = 1/`tnumber' {
				local l = `tmatrix'[`i',`k']
				display as text %10.8g `l', _continue
				}
			display " "
			}
		display "{hline 22}{c +}{hline `j'}"
		display as text %21s "minimum p-value"" {c |}", _continue
		forvalues k = 1/`tnumber' {
			display as result %10.8g `Vtest'[1,`k'], _continue
			}
		display " "
		display as text %21s "maximum p-value"" {c |}", _continue
		forvalues k = 1/`tnumber' {
			display as result %10.8g `Vtest'[2,`k'], _continue
			}
		display " "
		display as text %21s "randomized p-value"" {c |}", _continue
		forvalues k = 1/`tnumber' {
			display as result %10.8g `Vtest'[3,`k'], _continue
			}
		display " "
		display as text %21s "successful iterations"" {c |}", _continue
		forvalues k = 1/`tnumber' {
			display as result %10.8g `Vtest'[4,`k'], _continue
			}
		display " "

		matrix rownames `Vtest' = min-p max-p rand-p reps
		matrix colnames `Vtest' = `label'
		}

*****************************************************
*****************************************************

mata `r' = 0
if (`mcount' > 0) {
	display, _newline 
	display as text "Calculating maximum p-values for each treatment measure across nulls for other treatment measures.", _newline
	if (`maxcoef' == 0 & `maxwald' == 0) {
		mata `r' = sqrt(invchi2tail(`treatnumber'-1,1e-10))
		display as text "Neither maxcoef() nor maxwald() specified. maxwald() set such that nulls on untested measures restricted to"
		display as text "those for which the p-value of the conventional wald test is > 10^(-10). maxwald(#) set at # = " sqrt(invchi2tail(`treatnumber'-1,1e-10))
		}
	else {
		mata `r' = max((`maxcoef',`maxwald'))
		if (`maxcoef' ~= 0) display as text "maxcoef(#) bound set at # = " `maxcoef'
		if (`maxwald' ~= 0) display as text "maxwald(#) bound set at # = " `maxwald'
		}

	display " "
	if (`treatnumber' == 2) {
		display as text "With 2 treatment measures, calculation is analytic."
		display as text "Calculation is made across all nulls as well as bounded space of nulls."
		display as text "To change the bounds use the maxcoef(#) or maxwald(#) options."

		}
	else if (`treatnumber' == 3) {
		display as text "With 3 treatment measures, calculation is made using a `maxlevel' point grid search across pi radians."
		display as text "Calculation is made across all nulls as well as bounded space of nulls."
		display as text "To change the intensity of the grid search, use the maxlevel(integer) option."
		display as text "To change the bounds use the maxcoef(#) or maxwald(#) options."
		}
	else {
		display as text "With N >= 4 treatment measures, calculation takes the maximum of `maxlevel' Nelder-Mead simplex searches in [0,pi]^N-2 space."
		display as text "Separate searches are made to calculate maximum across the unbounded/bounded space of nulls."
		display as text "To change the intensity of the search, use the maxlevel(integer) option."
		display as text "To change the bounds use the maxcoef(#) or maxwald(#) options."
		} 
	display " "
	}


*Calculating maximum p-values across nulls for other treatment variables (if requested)
mata {	
	`p' = J(`mcount',5,.); `jjj' = 0; `Ra' = select(`Ra',`Restest'); `Rb' = select(`Rb',`Restest'); `Rc' = select(`Rc',`Restest'); `Resdif2' = select(`Resdif2',`Restest') 
	`Resdif2' =  (`Resdif2':>1e-09); `p'[1...,4] = rows(`Resdif2'):-colsum(`Resdif2')'
	for(`ii'=1;`ii'<=`treatnumber';`ii'++) {
		if (`maxlist'[1,`ii'] == 1) {
			`jjj' = `jjj' + 1; `p'[`jjj',5] = `uuu'[1,`ii']
			if (`treatnumber' == 2) {
				`a' = select(`Ra'[1...,`jjj'],`Resdif2'[1...,`jjj']); `b' = select(`Rb'[1...,`jjj'],`Resdif2'[1...,`jjj']); `c' = select(`Rc'[1...,`jjj'],`Resdif2'[1...,`jjj'])
				`sel' = J(1,`treatnumber',1); `sel'[1,`ii'] = 0; `nsel' = 1:-`sel'; `Bsel' = select(`B',`sel'')
				if (`maxcoef' ~= 0) {
					`c' = `c' + `b'*`Bsel' + `a'*(`Bsel'^2); `b' = `b' + 2*`a'*`Bsel'
					}
				else {
					`c' = `c' + `b'*`Bsel' + `a'*(`Bsel'^2); `b' = sqrt(`V'[3-`ii',3-`ii'])*(`b' + 2*`a'*`Bsel'); `a' = `a'*`V'[3-`ii',3-`ii']			
					}
				`sela' = (`a':~=0); `nsela' = 1:-`sela'; `n' = rows(`a')
				`x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
				`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
				`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
				if (rows(`x')==0) {
					`p'[`jjj',1..3] = (`g',`g',`n')
					}
				else {
					`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `p'[`jjj',1] = max((max(`pp'),`g'))
					`sel1' = `x'[1...,1]:>=-`r'; `sel2' = `x'[1...,1]:<=`r'; `sel3' = `x'[1...,1]:>-`r'
					`pp' = `pp', (`pp':-`x'[1...,2]):*`sel3'; `ppp' = select(`pp',`sel1':*`sel2')
					if (rows(`ppp')==0) {
						if (`x'[1,1]>`r') {
							`p'[`jjj',2..3] = `g',`n'
							}
						else if (`x'[rows(`x'),1]<-`r') {
							`p'[`jjj',2..3] = `pp'[rows(`x'),1], `n'
							}
						else {
							`ppp' = select(`pp',1:-`sel1'); `p'[`jjj',2..3] = `ppp'[rows(`ppp'),1], `n'
							}
						}
					else {
						`p'[`jjj',2..3] = max(colmax(`ppp')), `n'
						}
					}
				}
			else if (`treatnumber' == 3) {
				`RRc' = select(`Rc'[1...,`jjj'],`Resdif2'[1...,`jjj']); `RRb' = select(`Rb'[1...,(`jjj'-1)*(`treatnumber'-1)+1..`jjj'*(`treatnumber'-1)],`Resdif2'[1...,`jjj'])
				`RRa' = select(`Ra'[1...,(`jjj'-1)*`width'+1..`jjj'*`width'],`Resdif2'[1...,`jjj'])
				`sel' = J(1,`treatnumber',1); `sel'[1,`ii'] = 0; `nsel' = 1:-`sel'; `Bsel' = select(`B',`sel''); `n' = rows(`RRa') 
				if (`maxcoef' ~= 0) {
					`Atilde' = J(`n'*2,2,.); `btilde' = J(`n',2,.); `ctilde' = J(`n',1,.)
					for(`iii'=1;`iii'<=`n';`iii'++) {
						`A' = invvech(`RRa'[`iii',1..`width']'); `b' = `RRb'[`iii',1..2]'
						`ctilde'[`iii',1] = `RRc'[`iii',1] + `b''`Bsel' + `Bsel''`A'*`Bsel'; `b' = `b' + 2*`A'*`Bsel'
						`Atilde'[(`iii'-1)*2+1..`iii'*2,1..2] = `A'; `btilde'[`iii',1..2] = `b''
						}
					}
				else {
					symeigensystem(select(select(`V',`sel'),`sel''),`E'=.,`L'=.); `F2' = `E'*diag(sqrt(`L'))*`E''
					`Atilde' = J(`n'*2,2,.); `btilde' = J(`n',2,.); `ctilde' = J(`n',1,.)
					for(`iii'=1;`iii'<=`n';`iii'++) {
						`A' = invvech(`RRa'[`iii',1..`width']'); `b' = `RRb'[`iii',1..2]' 
						`ctilde'[`iii',1] = `RRc'[`iii',1] + `b''`Bsel' + `Bsel''`A'*`Bsel'; `b' = `F2'*(`b' + 2*`A'*`Bsel')
						`Atilde'[(`iii'-1)*2+1..`iii'*2,1..2] = `F2''`A'*`F2'; `btilde'[`iii',1..2] = `b'' 
						}
					}
	
				printf(ustrword("`mlist'",`jjj')+": ")
				`RR' = J(`maxlevel',2,.); `c' = `ctilde'; `a' = J(`n',1,.)
				for(`jj'=1;`jj'<=`maxlevel';`jj'++) {
					if (ceil(10*`jj'/`maxlevel')*(`maxlevel'/10) == `jj') {
						printf("%g ",`jj'); displayflush()
						}
					`xstar' = sin(`jj'*pi()/`maxlevel'),cos(`jj'*pi()/`maxlevel'); `b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*2+1..`iii'*2,1..2]*`xstar''
					`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
					`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
					`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
					if (rows(`x')==0) {
						`RR'[`jj',1..2] = (`g',`g')
						}
					else {
						`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `RR'[`jj',1] = max((max(`pp'),`g'))
						`sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r' 
						`pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
						if (rows(`ppp')==0) {
							if (`x'[1,1]>`r') {
								`RR'[`jj',2] = `g'
								}
							else if (`x'[rows(`x'),1]<-`r') {
								`RR'[`jj',2] = `pp'[rows(`x'),1]
								}
							else {
								`ppp' = select(`pp',`sel3'); `RR'[`jj',2] = `ppp'[rows(`ppp'),1]
								}
							}
						else {
							`RR'[`jj',2] = max(colmax(`ppp'))
							}
						}
					}
				printf("\n"); `p'[`jjj',1..3] = colmax(`RR'[1..`maxlevel',1..2]), `n'
				}
			else {			
				`RRc' = select(`Rc'[1...,`jjj'],`Resdif2'[1...,`jjj']); `RRb' = select(`Rb'[1...,(`jjj'-1)*(`treatnumber'-1)+1..`jjj'*(`treatnumber'-1)],`Resdif2'[1...,`jjj'])
				`RRa' = select(`Ra'[1...,(`jjj'-1)*`width'+1..`jjj'*`width'],`Resdif2'[1...,`jjj'])
				`sel' = J(1,`treatnumber',1); `sel'[1,`ii'] = 0; `Bsel' = select(`B',`sel''); `n' = rows(`RRa'); `dim' = cols(`RRb')

				if (`maxcoef' ~= 0) {
					`Atilde' = J(`n'*`dim',`dim',.); `btilde' = J(`n',`dim',.); `ctilde' = J(`n',1,.)
					for(`iii'=1;`iii'<=`n';`iii'++) {
						`A' = invvech(`RRa'[`iii',1..`width']'); `b' = `RRb'[`iii',1..`dim']'
						`ctilde'[`iii',1] = `RRc'[`iii',1] + `b''`Bsel' + `Bsel''`A'*`Bsel'; `b' = `b' + 2*`A'*`Bsel'
						`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim'] = `A'; `btilde'[`iii',1..`dim'] = `b''
						}
					}
				else {
					symeigensystem(select(select(`V',`sel'),`sel''),`E'=.,`L'=.); `F2' = `E'*diag(sqrt(`L'))*`E''
					`Atilde' = J(`n'*`dim',`dim',.); `btilde' = J(`n',`dim',.); `ctilde' = J(`n',1,.)
					for(`iii'=1;`iii'<=`n';`iii'++) {
						`A' = invvech(`RRa'[`iii',1..`width']'); `b' = `RRb'[`iii',1..`dim']'
						`ctilde'[`iii',1] = `RRc'[`iii',1] + `b''`Bsel' + `Bsel''`A'*`Bsel'; `b' = `F2'*(`b' + 2*`A'*`Bsel')
						`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim'] = `F2''`A'*`F2'; `btilde'[`iii',1..`dim'] = `b''
						}
					}

				printf(ustrword("`mlist'",`jjj')+": ")
				`c' = `ctilde'; `a' = J(`n',1,.); `maxp' = 0
				for(`ccc'=1;`ccc'<=`maxlevel';`ccc'++) {
					if (ceil(10*`ccc'/`maxlevel')*(`maxlevel'/10) == `ccc') {
						printf("%g ",`ccc'); displayflush()
						}
					`RR' = J(`dim'+1,`dim'+1,0)
					for(`jj'=1;`jj'<=`dim'+1;`jj'++) {
						`uu' = uniform(1,`dim'); `xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
						`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
						`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
						`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
						`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
						`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
						if (rows(`x')==0) {
							`RR'[`jj',1..`dim'+1] = `g', `uu'
							}
						else {
							`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `RR'[`jj',1..`dim'+1] = max((max(`pp'),`g')), `uu'
							}			
						}
					`RR' = `RR', uniform(rows(`RR'),1); _sort(`RR',(-1,`dim'+2))
	
					`qqq' = variance(`RR'[1..`dim'+1,1])
					while (`qqq' > 0) { 
						`alpha' = uniform(1,1); `gamma' = 1 + uniform(1,1); `beta' = uniform(1,1); `rho' = uniform(1,1)
						`shrink' = 0; _sort(`RR',(-1,`dim'+2)); `x0' = mean(`RR'[1..`dim',2..`dim'+1]); `xr' = `x0' + `alpha'*(`x0' - `RR'[`dim'+1,2..`dim'+1]); `uu' = `xr'
							`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
							`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
							`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
							`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
							`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
							`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
							if (rows(`x')==0) {
								`value' = `g'
								}
							else {
								`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `value' = max((max(`pp'),`g'))
								}
						if (`value' > `RR'[`dim',1] & `value' <= `RR'[1,1]) {
							`RR'[`dim'+1,1..`dim'+1] = (`value',`xr')
							}
						else if (`value' > `RR'[1,1]) {
							`xe' = `x0' + `gamma'*(`xr'-`x0'); `uu' = `xe'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `value2' = max((max(`pp'),`g'))
									}
							if (`value2' > `value') {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xe')
								}
							else {
								`RR'[`dim'+1,1..`dim'+1] = (`value',`xr')
								}		
							}
						else if (`value' <= `RR'[`dim',1] & `value' > `RR'[`dim'+1,1]) {
							`xc' = `x0' + `beta'*(`xr'-`x0'); `uu' = `xc'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `value2' = max((max(`pp'),`g'))
									}
							if (`value2' > `value') {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xc')
								}
							else {
								`shrink' = 1
								}
							}
						else {
							`xc' = `x0' + `beta'*(`RR'[`dim'+1,2..`dim'+1]-`x0'); `uu' = `xc'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `value2' = max((max(`pp'),`g'))
									}
							if (`value2' > `RR'[`dim'+1,1]) {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xc')
								}
							else {
								`shrink' = 1
								}
							}
						if (`shrink' == 1) {
							`RR'[2..`dim'+1,2..`dim'+1] = `rho'*`RR'[2..`dim'+1,2..`dim'+1]:+(1-`rho')*`RR'[1,2..`dim'+1]
							for(`cc'=2;`cc'<=`dim'+1;`cc'++) {
								`uu' = `RR'[`cc',2..`dim'+1]
									`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
									`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
									`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
									`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
									`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
									`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
									if (rows(`x')==0) {
										`value2' = `g'
										}
									else {
										`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `value2' = max((max(`pp'),`g'))
										}
								`RR'[`cc',1] = `value2'
								}
							}
						`qqq' = variance(`RR'[1..`dim'+1,1])
						}
					`maxp' = max((`maxp',`RR'[1,1]))
					if (`RR'[1,1] == `n') {
						for(`cc'=`ccc'+1;`cc'<=`maxlevel';`cc'++) {
							if (ceil(10*`cc'/`maxlevel')*(`maxlevel'/10) == `cc') {
								printf("%g ",`cc'); displayflush()
								}
							}
						`ccc' = `maxlevel' + 1
						}
					}
				printf("\n"); `p'[`jjj',1] = `maxp'; `p'[`jjj',3] = `n'
				printf(ustrword("`mlist'",`jjj')+"(bounded): ")
				`c' = `ctilde'; `a' = J(`n',1,.); `maxp' = 0
				for(`ccc'=1;`ccc'<=`maxlevel';`ccc'++) {
					if (ceil(10*`ccc'/`maxlevel')*(`maxlevel'/10) == `ccc') {
						printf("%g ",`ccc'); displayflush()
						}
					`RR' = J(`dim'+1,`dim'+1,0)
					for(`jj'=1;`jj'<=`dim'+1;`jj'++) {
						`uu' = uniform(1,`dim'); `xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
						`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
						`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
						`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
						`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
						`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
						if (rows(`x')==0) {
							`RR'[`jj',1..`dim'+1] = `g', `uu'
							}
						else {
							`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
							if (rows(`ppp')==0) {
								if (`x'[1,1]>`r') {
									`RR'[`jj',1..`dim'+1] = `g', `uu'
									}
								else if (`x'[rows(`x'),1]<-`r') {
									`RR'[`jj',1..`dim'+1] = `pp'[rows(`x'),1], `uu'
									}
								else {
									`ppp' = select(`pp',`sel3'); `RR'[`jj',1..`dim'+1] = `ppp'[rows(`ppp'),1], `uu'
									}
								}
							else {
								`RR'[`jj',1..`dim'+1] = max(colmax(`ppp')), `uu'
								}
							}		
						}
					`RR' = `RR', uniform(rows(`RR'),1); _sort(`RR',(-1,`dim'+2))

					`qqq' = variance(`RR'[1..`dim'+1,1])
					while (`qqq' > 0) { 
						`alpha' = uniform(1,1); `gamma' = 1 + uniform(1,1); `beta' = uniform(1,1); `rho' = uniform(1,1)
						`shrink' = 0; _sort(`RR',(-1,`dim'+2)); `x0' = mean(`RR'[1..`dim',2..`dim'+1]); `xr' = `x0' + `alpha'*(`x0' - `RR'[`dim'+1,2..`dim'+1]); `uu' = `xr'
							`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
							`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
							`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
							`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
							`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
							`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
							if (rows(`x')==0) {
								`value' = `g'
								}
							else {
								`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
								if (rows(`ppp')==0) {
									if (`x'[1,1]>`r') {
										`value' = `g'
										}
									else if (`x'[rows(`x'),1]<-`r') {
										`value' = `pp'[rows(`x'),1]
										}
									else {
										`ppp' = select(`pp',`sel3'); `value' = `ppp'[rows(`ppp'),1]
										}
									}
								else {
									`value' = max(colmax(`ppp'))
									}
								}
						if (`value' > `RR'[`dim',1] & `value' <= `RR'[1,1]) {
							`RR'[`dim'+1,1..`dim'+1] = (`value',`xr')
							}
						else if (`value' > `RR'[1,1]) {
							`xe' = `x0' + `gamma'*(`xr'-`x0'); `uu' = `xe'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
									if (rows(`ppp')==0) {
										if (`x'[1,1]>`r') {
											`value2' = `g'
											}
										else if (`x'[rows(`x'),1]<-`r') {
											`value2' = `pp'[rows(`x'),1]
											}
										else {
											`ppp' = select(`pp',`sel3'); `value2' = `ppp'[rows(`ppp'),1]
											}
										}
									else {
										`value2' = max(colmax(`ppp'))
										}
									}
							if (`value2' > `value') {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xe')
								}
							else {
								`RR'[`dim'+1,1..`dim'+1] = (`value',`xr')
								}
							}
						else if (`value' <= `RR'[`dim',1] & `value' > `RR'[`dim'+1,1]) {
							`xc' = `x0' + `beta'*(`xr'-`x0'); `uu' = `xc'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
									if (rows(`ppp')==0) {
										if (`x'[1,1]>`r') {
											`value2' = `g'
											}
										else if (`x'[rows(`x'),1]<-`r') {
											`value2' = `pp'[rows(`x'),1]
											}
										else {
											`ppp' = select(`pp',`sel3'); `value2' = `ppp'[rows(`ppp'),1]
											}
										}
									else {
										`value2' = max(colmax(`ppp'))
										}
									}
							if (`value2' > `value') {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xc')
								}
							else {
								`shrink' = 1
								}
							}
						else {
							`xc' = `x0' + `beta'*(`RR'[`dim'+1,2..`dim'+1]-`x0'); `uu' = `xc'
								`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
								`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
								`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
								`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
								`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
								`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
								if (rows(`x')==0) {
									`value2' = `g'
									}
								else {
									`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
									if (rows(`ppp')==0) {
										if (`x'[1,1]>`r') {
											`value2' = `g'
											}
										else if (`x'[rows(`x'),1]<-`r') {
											`value2' = `pp'[rows(`x'),1]
											}
										else {
											`ppp' = select(`pp',`sel3'); `value2' = `ppp'[rows(`ppp'),1]
											}
										}
									else {
										`value2' = max(colmax(`ppp'))
										}
									}
							if (`value2' > `RR'[`dim'+1,1]) {
								`RR'[`dim'+1,1..`dim'+1] = (`value2',`xc')
								}
							else {
								`shrink' = 1
								}
							}
						if (`shrink' == 1) {
							`RR'[2..`dim'+1,2..`dim'+1] = `rho'*`RR'[2..`dim'+1,2..`dim'+1]:+(1-`rho')*`RR'[1,2..`dim'+1]
							for(`cc'=2;`cc'<=`dim'+1;`cc'++) {
								`uu' = `RR'[`cc',2..`dim'+1]
									`xbase' = sin(`uu'[1,1]*pi()); for(`iii'=2;`iii'<=`dim'-1;`iii'++) `xbase' = `xbase', `xbase'[1,cols(`xbase')]*sin(`uu'[1,`iii']*pi())
									`xstar' = cos(`uu'[1,1]*pi()), `xbase'[1,1..`dim'-2]:*cos(pi()*`uu'[1,2..`dim'-1]), `xbase'[1,`dim'-1]
									`b' = `btilde'*`xstar''; for(`iii'=1;`iii'<=`n';`iii'++) `a'[`iii',1] = `xstar'*`Atilde'[(`iii'-1)*`dim'+1..`iii'*`dim',1..`dim']*`xstar''
									`sela' = (`a':~=0); `nsela' = 1:-`sela'; `x' = .5*(-`b'-sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,-1); `x' = `x', .5*(-`b'+sqrt((`b':*`b')-4*(`a':*`c'))):/`a', J(`n',1,1)
									`x' = select(`x',`sela'); `x' = `x'[1...,1..2] \ `x'[1...,3..4]; `xx' = -`c':/`b', sign(`b'); `xx' = select(`xx',`nsela'); `x' = `x' \ `xx'; _sort(`x',(1,-2))
									`g' = (`a':>0) + (`nsela':*(`b':<0)) + (`nsela':*(`b':==0):*(`c':>0)); `g' = sum(`g'); `x' = select(`x',(`x'[1...,1]:~=.))
									if (rows(`x')==0) {
										`value2' = `g'
										}
									else {
										`pp' = runningsum(`x'[1...,2]); `pp' = `pp':+`g'; `sel' = abs(`x'[1...,1]):<=`r'; `sel2' = abs(`x'[1...,1]):<`r'; `sel3' = `x'[1...,1]:<-`r'; `pp' = `pp', (`pp':-`x'[1...,2]):*`sel2'; `ppp' = select(`pp',`sel')
										if (rows(`ppp')==0) {
											if (`x'[1,1]>`r') {
												`value2' = `g'
												}
											else if (`x'[rows(`x'),1]<-`r') {
												`value2' = `pp'[rows(`x'),1]
												}
											else {
												`ppp' = select(`pp',`sel3'); `value2' = `ppp'[rows(`ppp'),1]
												}
											}
										else {
											`value2' = max(colmax(`ppp'))
											}
										}
								`RR'[`cc',1] = `value2'
								}
							}
						`qqq' = variance(`RR'[1..`dim'+1,1])
						}
					`maxp' = max((`maxp',`RR'[1,1]))
					if (`RR'[1,1] == `n') {
						for(`cc'=`ccc'+1;`cc'<=`maxlevel';`cc'++) {
							if (ceil(10*`cc'/`maxlevel')*(`maxlevel'/10) == `cc') {
								printf("%g ",`cc'); displayflush()
								}
							}
						`ccc' = `maxlevel' + 1
						}
					}
				printf("\n"); `p'[`jjj',2] = `maxp'
				}
			}
		}
	if (`treatnumber' > 2) printf("\n") 
	`p'[1...,4] = `p'[1...,4]:+1; `p'[1...,3] = `p'[1...,3]+`p'[1...,4]
	`p' = `p'[1...,1]:/`p'[1...,3], (`p'[1...,1]+`p'[1...,4]):/`p'[1...,3],(`p'[1...,1]+(`p'[1...,4]:*`p'[1...,5])):/`p'[1...,3], `p'[1...,2]:/`p'[1...,3], (`p'[1...,2]+`p'[1...,4]):/`p'[1...,3], (`p'[1...,2]+(`p'[1...,4]:*`p'[1...,5])):/`p'[1...,3]
	st_matrix("`p'",`p')
	}

*Displaying maximum p-values
if (`mcount' > 0) {
	display as text "Maximum p-value for tests of zero individual treatment effects across possible nulls for other (untested) treatment effects."
	display as text "Difference between min max and max max reflects universal ties, which are resolved using draw from uniform distribution on (0,1).", _newline
	display as text _col(21) "across all possible nulls" _col(58) "across bounded nulls"
	display as text "    variable {c |}" _col(19) "min max" _col(29) "max max" _col(38) "randomized" _col(54) "min max" _col(64) "max max" _col(73) "randomized"
	display as text "             {c |}" _col(19) "p-value" _col(29) "p-value" _col(38) "max p-value" _col(54) "p-value" _col(64) "p-value" _col(73) "max p-value"
	display "{hline 13}{c +}{hline 71}"
	forvalues i = 1/`mcount' {
		display as text %12s abbrev(word("`mlist'",`i'),12) " {c |}", _continue
		display as result _col(16) %10.5f `p'[`i',1] _col(26) %10.5f `p'[`i',2] _col(36) %10.5f `p'[`i',3] _col(51) %10.5f `p'[`i',4] _col(61) %10.5f `p'[`i',5] _col(71) %10.5f `p'[`i',6]
		}
	display " "
	matrix rownames `p' = `mlist'
	matrix colnames `p' = max boundedmax
	}

ereturn matrix HB = `VVt', copy
if (`tnumber' > 0) ereturn matrix Jtest = `Vtest', copy
if (`mcount' > 0) ereturn matrix Pmax = `p', copy

*****************************************************
*****************************************************

*Cleaning up

foreach j in ei n nk nnk nc info clinfo B BB bb vv V VV VVV dvec S A X Y Z T W Z2 z2 w y z qqq x xx xxx Aid WAid c1 c2 c3 list dcz F2 Finv2 shrink value value2 alpha beta gamma xstar xr xe xc E L nsela sela sel1 sel2 sel3 {
	capture mata mata drop ``j''
	}

foreach j in Ra Rb Rc RRa RRb RRc RR xbase ak Atilde btilde ctilde x0 p pp ppp rho g dim uu uuu r maxp c0 b0 A0 dif Resdif2 {
	capture mata mata drop ``j''
	}

foreach j in a b c d e roots der test ii jj iii jjj cc ccc tmatrix Resnull Rtest yy btest VVt Vtest sum U Abs Cl touse Bsel Vsel nsel sel Resb Resse Resder Resroots Restest Restie maxlist {
	capture mata mata drop ``j''
	}

restore

set seed `oldseed'

end



