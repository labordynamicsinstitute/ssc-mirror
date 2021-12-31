*! version 2.0.1 20August 2020

program randcmdci, eclass
	version 13.1
	syntax anything [aw pw] [if] [in], treatvars(varlist) testvars(varlist) [robust cluster(varname) noCONStant absorb(varname) reps(integer 999) strata(varname) groupvar(varname) seed(integer 1) calc1(string) calc2(string) calc3(string) calc4(string) calc5(string) calc6(string) calc7(string) calc8(string) calc9(string) calc10(string) calc11(string) calc12(string) calc13(string) calc14(string) calc15(string) calc16(string) calc17(string) calc18(string) calc19(string) calc20(string) calc21(string) calc22(string) calc23(string) calc24(string) calc25(string) calc26(string) calc27(string) calc28(string) calc29(string) calc30(string) test1(string) test2(string) test3(string) test4(string) test5(string) test6(string) test7(string) test8(string) test9(string) test10(string)] 
	tempname B v V ei ehbi n nk nnk nc info clinfo 
	tempname VVt X Y Z T W Z2 z2 w y z qqq xxx Aid WAid c1 c2 c3 list bi di dc dcz bhb dif Cl
	tempname Restt1 Restt2 Restt3 Restt4 ResttD1 ResttD2 ResttD3 ResttD4 ResttT1 ResttT2 ResttT3 ResttT4 Resddisc
	tempname a b c d e gamma gammai taui roots der test ii jj
	tempname tmatrix Restest Rtest yy VV btest Vtest sum
	tempvar U Order OldOrder M MM n Cl Abs touse

	display " "
*Extracting locals
	gettoken cmd anything: anything
	gettoken dep anything: anything
	unab anything: `anything'
	unab testvars: `testvars'
	unab treatvars: `treatvars'
	local treatnumber = wordcount("`testvars'")
	foreach var in `testvars' {
		local anything = subinstr("`anything'","`var'","",1)
		}
	if ("`exp'" ~= "") gettoken token ww: exp, parse("=")
	if ("`constant'" ~= "" & "`absorb'" ~= "") {
		local constant = ""
		display as error "noconstant not compatible with absorb and is dropped."
		}
	if (`reps' < 99) {
		local reps = 99
		display as error "A minimum of 99 repetitions is necessary for bounded 99% confidence intervals.  Option reps reset to 99."
		}
	if (substr("`cmd'",1,3) == "reg") local cmd = "reg"
	if ("`absorb'" ~= "" & "`cmd'" ~= "areg") local cmd = "areg"

*Checking estimation method is currently supported
	local error = 0
	if ("`cmd'" ~= "reg" & "`cmd'" ~= "areg") {
		local error = 1
		display as error "Only regress & areg, but not `cmd' supported by randci."
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
		matrix `b' = e(b)
		matrix `v' = e(V)
	quietly keep if `touse'
	if ("`cluster'" ~= "") quietly egen `Cl' = group(`cluster')
	if ("`absorb'" ~= "") quietly egen `Abs' = group(`absorb')

*Checking all testvars are identified 
	local i = 1
	foreach var in `testvars' {
		if (`b'[1,`i'] == 0 & `v'[`i',`i'] == 0) {
			display as error "Test variable `var' not identified in estimating equation."
			local error = 1
			}
		local i = `i' + 1
		}
	if (`error' == 1) exit

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
			if (r(mean) == 0) {
				display as error "`var' does not vary with strata.  Base treatment variables must vary within strata."
				local error = 1
				}
			quietly drop `M' 
			}
		}
	if (`error' == 1) exit
	
*Displaying treatment variables so that user can confirm that programme has correctly identified treatment variables and interaction equations
	local calc = 0
	forvalues k = 1/20 {
		if ("`calc`k''" ~= "") local calc = `k'
		}
	local tnumber = 0
	forvalues k = 1/10 {
		if ("`test`k''" ~= "") local tnumber = `k'
		}
	mata `tmatrix' = .
	if (`tnumber' > 0) {
		matrix `tmatrix' = J(`tnumber',`treatnumber',0)
		forvalues k = 1/`tnumber' {
			capture matrix `tmatrix'[`k',1] = `test`k''
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
		}
	display " "

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
					`Aid' = st_data(.,"`absorb'",.); `info' = panelsetup(`Aid',1) 
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `X'[`info'[`ii',1]..`info'[`ii',2],1...] = `X'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`X'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1...] = `Y'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1...] = `Z'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					}
				else {
					`Aid' = st_data(.,("`absorb'","`Order'"),.); `X' = `X', `Aid'; `Y' = `Y', `Aid'; `Z' = `Z', `Aid'; `WAid' = `W',`Aid'
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
					`Aid' = st_data(.,"`absorb'",.); `info' = panelsetup(`Aid',1) 
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1...] = `Y'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1...] = `Z'[`info'[`ii',1]..`info'[`ii',2],1...]:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1...],`W'[`info'[`ii',1]..`info'[`ii',2],1])
					}
				else {
					`Aid' = st_data(.,("`absorb'","`Order'"),.); `Y' = `Y', `Aid'; `Z' = `Z', `Aid'; `WAid' = `W',`Aid'
					_sort(`Z',(`treatnumber'+1,`treatnumber'+2)); _sort(`Y',(2,3)); _sort(`WAid',(2,3)); `info' = panelsetup(`Y',2)
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Y'[`info'[`ii',1]..`info'[`ii',2],1] = `Y'[`info'[`ii',1]..`info'[`ii',2],1]:-mean(`Y'[`info'[`ii',1]..`info'[`ii',2],1],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					for (`ii'=1;`ii'<=rows(`info');`ii'++) `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'] = `Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber']:-mean(`Z'[`info'[`ii',1]..`info'[`ii',2],1..`treatnumber'],`WAid'[`info'[`ii',1]..`info'[`ii',2],1])
					_sort(`Z',`treatnumber'+2); _sort(`Y',3); `Y' = `Y'[1...,1]; `Z' = `Z'[1...,1..`treatnumber']
					}
				}
			`Y' = `Y':*`w'; `Z' = `Z':*`w'; `y' = `Y'; `z' = `Z'
			}
		`n' = rows(`Y'); `nk' = `n'-cols(`X')-cols(`Z'); if ("`absorb'" ~= "") `nk' = `nk' - rows(`info')
		`dcz' = invsym(`z''*`z'); `qqq' = `dcz'*`z''; `B' = `qqq'*`y'; `ei' = `y' - `z'*`B'; `dcz' = min(diagonal(`dcz'))
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
		`V' = diagonal(`V'); `taui' = `V'/`nnk'
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
	`T' = st_data((1,`N'),"`treatvars'"); `Resddisc' = J(`reps',1,.)
	`Restt1' = J(`reps',`treatnumber',.); `Restt2' = J(`reps',`treatnumber',.); `Restt3' = J(`reps',`treatnumber',.); `Restt4' = J(`reps',`treatnumber',.)
	`ResttD1' = J(`reps',`treatnumber',.); `ResttD2' = J(`reps',`treatnumber',.); `ResttD3' = J(`reps',`treatnumber',.); `ResttD4' = J(`reps',`treatnumber',.)
	`ResttT1' = J(`reps',`treatnumber',.); `ResttT2' = J(`reps',`treatnumber',.); `ResttT3' = J(`reps',`treatnumber',.); `ResttT4' = J(`reps',`treatnumber',.)
	`Restest' = J(`reps',`tnumber',.)
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

			`dc' = invsym(`z2''*`z2'); `qqq' = `dc'*`z2''; `bi' = `qqq'*`y'; `ei' = `y'-`z2'*`bi'; `di' = `qqq'*(`z2'-`z'); `dc' = min(diagonal(`dc')); `gammai' = `z2'-`z2'*`di'-`z'
			if (`dc'[1,1]/`dcz'[1,1] > 1e-10) {
				`Resddisc'[`count',1] = 0
				if (`tnumber' > 0) {
					`yy' = `y':+(`z2'-`z')*`tmatrix'; `btest' = `qqq'*`yy'; `yy' = `yy'-`z2'*`btest'; `btest' = `btest'-`tmatrix'
					if ("`cluster'" ~= "") {
						for(`ii'=1;`ii'<=`tnumber';`ii'++) {
							`V' = J(`nc',`treatnumber',0) 
							for (`jj'=1;`jj'<=`nc';`jj'++) `V'[`jj',1..`treatnumber'] = colsum(`qqq'[1..`treatnumber',`clinfo'[`jj',1]..`clinfo'[`jj',2]]':*`yy'[`clinfo'[`jj',1]..`clinfo'[`jj',2],`ii'])
							`V'= `nnk'*`V''*`V'; `Restest'[`count',`ii'] = `btest'[1...,`ii']'*invsym(`V')*`btest'[1...,`ii']
							}
						}
					else {
						for(`ii'=1;`ii'<=`tnumber';`ii'++) {
							`V' = (`qqq':*`yy'[1...,`ii']'); `V' = `nnk'*`V'*`V''; `Restest'[`count',`ii'] = `btest'[1...,`ii']'*invsym(`V')*`btest'[1...,`ii']
							}
						}
					}

				`bhb' = J(`treatnumber',`treatnumber',0)
				for (`ii'=1;`ii'<=`treatnumber';`ii'++) {
					`bhb'[1..`treatnumber',`ii'] = `bi' + `di'*`B'-`di'[1..`treatnumber',`ii']*`B'[`ii',1]
					}
				`ehbi' = -((`z2'-`z'):*`B'')-(`z2'*`bhb'); `ehbi' = `ehbi':+(`y'+(`z2'-`z')*`B')
 
				if ("`cluster'" ~= "") {
					`c1' = J(1,`treatnumber',0); `c2' = J(1,`treatnumber',0); `c3' = J(1,`treatnumber',0) 
					for (`ii'=1;`ii'<=`nc';`ii'++) {
						`a' = colsum(`gammai'[`clinfo'[`ii',1]..`clinfo'[`ii',2],1..`treatnumber']:*`qqq'[1..`treatnumber',`clinfo'[`ii',1]..`clinfo'[`ii',2]]')
						`b' = colsum(`qqq'[1..`treatnumber',`clinfo'[`ii',1]..`clinfo'[`ii',2]]':*`ehbi'[`clinfo'[`ii',1]..`clinfo'[`ii',2],1..`treatnumber'])
						`c1' = `c1' + `a':^2; `c2' = `c2' + `a':*`b'; `c3' = `c3' + `b':^2
						}
					}
				else {
					`a' = `gammai':*`qqq''; `b' = `qqq'':*`ehbi'; `c1' = colsum(`a':*`a'); `c2' = colsum(`a':*`b'); `c3' = colsum(`b':*`b')
					}

				for(`ii'=1;`ii'<=`treatnumber';`ii'++) {
					`gamma' = `di'[`ii',`ii']-1
					`a' = -`c1'[1,`ii']; `b' = 2*`B'[`ii',1]*`c1'[1,`ii']-2*`c2'[1,`ii']; `c' = `gamma'*`gamma'*`taui'[`ii',1] - `c3'[1,`ii'] - `B'[`ii',1]^2*`c1'[1,`ii'] + 4*`B'[`ii',1]*`c2'[1,`ii']
					`d' = 2*`gamma'*`bhb'[`ii',`ii']*`taui'[`ii',1] + 2*`B'[`ii',1]*`c3'[1,`ii'] - 2*`B'[`ii',1]^2*`c2'[1,`ii']; `e' = `taui'[`ii',1]*`bhb'[`ii',`ii']^2-`B'[`ii',1]^2*`c3'[1,`ii']
					`sum' = abs(`a') + abs(`b') + abs(`c') + abs(`d') + abs(`e')
					if (`sum' > 0) {
						if (abs(`a'/`sum') > 1e-08) {
							`roots' = polyroots((`e',`d',`c',`b',`a'))'; for(`jj'=1;`jj'<=4;`jj'++) if(Re(`roots'[`jj',1])~=`roots'[`jj',1]) `roots'[`jj',1] = .; `roots' = Re(`roots'); _sort(`roots',1)
							`der' = (4*`a'*(`roots':^3) + 3*`b'*(`roots':^2) + 2*`c'*`roots'):+`d'; `der' = sign(`der')
							`test' = (`a'*(`roots':^4) + `b'*(`roots':^3) + `c'*(`roots':^2) + `d'*`roots'):+`e'
							`Restt1'[`count',`ii'] = `roots'[1,1]; `Restt2'[`count',`ii'] = `roots'[2,1]; `Restt3'[`count',`ii'] = `roots'[3,1]; `Restt4'[`count',`ii'] = `roots'[4,1]
							`ResttD1'[`count',`ii'] = `der'[1,1]; `ResttD2'[`count',`ii'] = `der'[2,1]; `ResttD3'[`count',`ii'] = `der'[3,1]; `ResttD4'[`count',`ii'] = `der'[4,1]
							`ResttT1'[`count',`ii'] = `test'[1,1]; `ResttT2'[`count',`ii'] = `test'[2,1]; `ResttT3'[`count',`ii'] = `test'[3,1]; `ResttT4'[`count',`ii'] = `test'[4,1]
							if (`roots'[1,1] == .) `ResttD1'[`count',`ii'] = 3*sign(`e')
							}
						else if (abs(`b'/`sum') > 1e-08) {
							`roots' = polyroots((`e',`d',`c',`b'))'; for(`jj'=1;`jj'<=3;`jj'++) if(Re(`roots'[`jj',1])~=`roots'[`jj',1]) `roots'[`jj',1] = .; `roots' = Re(`roots'); _sort(`roots',1)
							`der' = (4*`a'*(`roots':^3) + 3*`b'*(`roots':^2) + 2*`c'*`roots'):+`d'; `der' = sign(`der')
							`test' = (`a'*(`roots':^4) + `b'*(`roots':^3) + `c'*(`roots':^2) + `d'*`roots'):+`e'
							`Restt1'[`count',`ii'] = `roots'[1,1]; `Restt2'[`count',`ii'] = `roots'[2,1]; `Restt3'[`count',`ii'] = `roots'[3,1]
							`ResttD1'[`count',`ii'] = `der'[1,1]; `ResttD2'[`count',`ii'] = `der'[2,1]; `ResttD3'[`count',`ii'] = `der'[3,1]
							`ResttT1'[`count',`ii'] = `test'[1,1]; `ResttT2'[`count',`ii'] = `test'[2,1]; `ResttT3'[`count',`ii'] = `test'[3,1]
							if (`roots'[1,1] == .) `ResttD1'[`count',`ii'] = 3*sign(`e')
							}
						else if (abs(`c'/`sum') > 1e-08) {
							`roots' = polyroots((`e',`d',`c'))'; for(`jj'=1;`jj'<=2;`jj'++) if(Re(`roots'[`jj',1])~=`roots'[`jj',1]) `roots'[`jj',1] = .; `roots' = Re(`roots'); _sort(`roots',1)
							`der' = (4*`a'*(`roots':^3) + 3*`b'*(`roots':^2) + 2*`c'*`roots'):+`d'; `der' = sign(`der')
							`test' = (`a'*(`roots':^4) + `b'*(`roots':^3) + `c'*(`roots':^2) + `d'*`roots'):+`e'
							`Restt1'[`count',`ii'] = `roots'[1,1]; `Restt2'[`count',`ii'] = `roots'[2,1]
							`ResttD1'[`count',`ii'] = `der'[1,1]; `ResttD2'[`count',`ii'] = `der'[2,1]
							`ResttT1'[`count',`ii'] = `test'[1,1]; `ResttT2'[`count',`ii'] = `test'[2,1]
							if (`roots'[1,1] == .) `ResttD1'[`count',`ii'] = 3*sign(`e')
							}
						else if (abs(`d'/`sum') > 1e-08) {
							`Restt1'[`count',`ii'] = -`e'/`d'; `ResttD1'[`count',`ii'] = sign(`d')
							}
						else {
							`Restt1'[`count',`ii'] = .; `ResttD1'[`count',`ii'] = 3*sign(`e')
							}
						}
					else {
						`Restt1'[`count',`ii'] = .; `ResttD1'[`count',`ii'] = 2
						}
					}
				}
			}
		}


*****************************************************
*****************************************************

*Calculating confidence intervals and p-values

display , _newline
display as text "Calculating confidence intervals", _continue

matrix `VVt' = J(`treatnumber',12,.)	
matrix `VVt'[1,1] = `b'[1,1..`treatnumber']'

forvalues j = 1/`treatnumber' {
	quietly drop _all
	quietly set obs `reps'
	foreach var in Order1 Order2 Order3 Order4 Der1 Der2 Der3 Der4 Disc {
		quietly generate double `var' = .
		}
	forvalues i = 1/4 {
		mata st_store((1,`reps'),"Order`i'",`Restt`i''[1...,`j']); st_store((1,`reps'),"Der`i'",`ResttD`i''[1...,`j'])
		}
	mata st_store((1,`reps'),"Disc",`Resddisc'[1...,1])
	quietly drop if Disc == .
	matrix `VVt'[`j',11] = _N
	
	quietly sum Der1 if Der1 == 2
	local tie = r(N) + 1
	quietly sum Der1 if Der1 == -1
	local larger = r(N)
	quietly sum Der1 if Der1 == 3 
	local larger = `larger' + r(N)
	
	quietly gen n = _n	
	quietly reshape long Order Der, i(n) j(step)
	quietly drop if Order == .

	collapse (sum) Der, by(Order) fast
	local u = uniform()
	quietly generate double pvalue = `tie'*`u' + `larger' + Der if _n == 1
	quietly replace pvalue = pvalue[_n-1] + Der if _n > 1
	quietly replace pvalue = pvalue/(`VVt'[`j',11]+1)
	local min = (`tie'*`u'+`larger')/(`VVt'[`j',11]+1)
	quietly sum pvalue if _n == _N
	local max = r(mean)
	quietly generate Lpvalue = pvalue[_n-1]
	quietly replace Lpvalue = `min' if _n == 1

	local i = 5
	foreach level in .1 .05 .01 {
		quietly sum Order if pvalue > `level' 
		matrix `VVt'[`j',`i'] = r(min)
		quietly sum Order if Lpvalue > `level'
		matrix `VVt'[`j',`i'+1] = r(max)
		if (`min' > `level') matrix `VVt'[`j',`i'] = .
		if (`max' > `level') matrix `VVt'[`j',`i'+1] = .
		quietly sum Order if pvalue > `level' & Lpvalue < `level'
		local lower = r(max)
		quietly sum Order if Lpvalue > `level' & pvalue < `level' 
		local upper = r(min)
		if (`lower' ~= . & `upper' ~= . & `lower' > `upper') {
			matrix `VVt'[`j',12] = 0
			}
		else {
			matrix `VVt'[`j',12] = 1
			}
		local i = `i' + 2
		}

	quietly sum Der if Order < 0 
	local pmin0 = (r(sum)+`larger')/(`VVt'[`j',11]+1)
	quietly sum Der if Order <= 0
	local pmax0 = (r(sum)+`larger' + `tie')/(`VVt'[`j',11]+1)
	matrix `VVt'[`j',2] = (`pmin0',`pmax0',`pmin0'+`u'*(`pmax0'-`pmin0'))
	}

matrix rownames `VVt' = `testvars'
matrix colnames `VVt' = coef min-p max-p rand-p 90%CI 90%CI 95%CI 95%CI 99%CI 99%CI reps convex

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
	display, _newline
	display as text "    variable {c |}" _col(19) "[90% Conf. Interval]"  _col(44) "[95% Conf. Interval]" _col(69) "[99% Conf. Interval]" _col(94) "CI Convex?" 
	display "{hline 13}{c +}{hline 90}"
	forvalues i = 1/`treatnumber' {
		display as text %12s abbrev(word("`testvars'",`i'),12) " {c |}", _continue
		display as result _col(18) %10.8g `VVt'[`i',5] _col(29) %10.8g `VVt'[`i',6] _col(43) %10.8g `VVt'[`i',7] _col(54) %10.8g `VVt'[`i',8] _col(68) %10.8g `VVt'[`i',9] _col(79) %10.8g `VVt'[`i',10], _continue 
		if (`VVt'[`i',12] == 1) display as result _col(97) "yes"
		if (`VVt'[`i',12] == 0) display as result _col(98) "no"  
		}
if (`tnumber' > 0) {
	display " "
	matrix `Vtest' = J(4,`tnumber',.)
	quietly drop _all
	quietly set obs `reps'
	local label = " "
	forvalues i = 1/`tnumber' {
		quietly gen double test`i' = .
		quietly gen double Rtest`i' = .
		local label = "`label'" + "test`i' "
		}
	aorder
	mata st_store((1,1),(1..`tnumber'),`Rtest');st_store(.,(`tnumber'+1..2*`tnumber'),`Restest')

	forvalues i = 1/`tnumber' {
		quietly sum test`i' if test`i' > 1.000001*Rtest`i'[1]
		matrix `Vtest'[1,`i'] = r(N)
		quietly sum test`i' if test`i' > .999999*Rtest`i'[1]
		matrix `Vtest'[2,`i'] = r(N) + 1
		quietly sum test`i'
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

ereturn matrix HB = `VVt', copy
if (`tnumber' > 0) ereturn matrix Jtest = `Vtest', copy

foreach j in B v V ei ehbi n nk nnk nc info clinfo VVt X Y Z T W Z2 z2 w y z qqq xxx Aid WAid c1 c2 c3 list bi di dc dcz bhb dif Cl ii jj {
	capture mata mata drop ``j''
	}

foreach j in Restt1 Restt2 Restt3 Restt4 ResttD1 ResttD2 ResttD3 ResttD4 ResttT1 ResttT2 ResttT3 ResttT4 Resddisc a b c d e sum gamma gammai taui roots der test tmatrix Restest Rtest yy VV btest Vtest {
	capture mata mata drop ``j''
	}

restore

set seed `oldseed'

end



