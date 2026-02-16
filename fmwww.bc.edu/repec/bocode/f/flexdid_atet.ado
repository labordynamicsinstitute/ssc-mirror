*! version 2.0  05feb2026
**! version 1.6  30nov2025
**! version 1.5  18oct2025
**! version 1.0  10sep2025

program flexdid_atet 
        version 17.0

        Compute `0'

end

program Compute, rclass sortpreserve
	syntax [anything], [					///
		OVERALL1							///
		OVERALL(numlist min=1)				///
		BYGET1								///
		BYGET(numlist min=1)				///
		BYEXPOSURE1							///
		BYEXPOSURE(numlist min=1)			///
		BYCALENDAR1							///
		BYCALENDAR(numlist min=1)			///
		BYCOHORT1							///
		BYCOHORT(numlist min=1)				///
		BYGROUP1							///
		BYGROUP(numlist min=1)				///
		FOR(string)							///
		DYDX								///
		NOGRaph								///
		GRAPHoptions(string)				///
		TEst(string)						///
		AGGregationweight(string)			///
		Level(cilevel)						///
		* ]
        
	tempname _flexdid
	quietly estimates store `_flexdid'

	if ("`overall'"!=""|"`overall1'"!="") {
		if ("`overall1'"!="" & "`overall'"!="") {
				opts_exclusive "overall {bf:overall()}" 
		}
		_ATET_Overall `0'
		return add
	}
	else if ("`byget'"!=""|"`byget1'"!="") {
		if ("`byget1'"!="" & "`byget'"!="") {
				opts_exclusive "byget {bf:byget()}" 
		}
		_ATET_Byget `0'
		return add
		if "`test'"!="" {
			Testing, test(`test') atettype(byget)
			return add
		}
	}
	else if ("`byexposure'"!=""|"`byexposure1'"!="") {
		if ("`byexposure1'"!="" & "`byexposure'"!="") {
				opts_exclusive "byexposure {bf:byexposure()}" 
		}
		_ATET_Byexposure `0'
		return add
		if "`test'"!="" {
			Testing, test(`test') atettype(byexposure)
			return add
		}
	}
	else if ("`bycalendar'"!=""|"`bycalendar1'"!="") {
		if ("`bycalendar1'"!="" & "`bycalendar'"!="") {
				opts_exclusive "bycalendar {bf:bycalendar()}" 
		}
		_ATET_Bycalendar `0'
		return add
		if "`test'"!="" {
			Testing, test(`test') atettype(bycalendar)
			return add
		}
	}
	else if ("`bycohort'"!=""|"`bycohort1'"!="") {
		if ("`bycohort1'"!="" & "`bycohort'"!="") {
				opts_exclusive "bycohort {bf:bycohort()}" 
		}
		_ATET_Bycohort `0'
		return add
		if "`test'"!="" {
			Testing, test(`test') atettype(bycohort)
			return add
		}
	}
	else if ("`bygroup'"!=""|"`bygroup1'"!="") {
		if ("`bygroup1'"!="" & "`bygroup'"!="") {
				opts_exclusive "bygroup {bf:bygroup()}" 
		}
		_ATET_Bygroup `0'
		return add
		if "`test'"!="" {
			Testing, test(`test') atettype(bygroup)
			return add
		}
	}

	quietly estimates restore `_flexdid'

end


program define _ATET_Overall, rclass
	syntax [anything], [overall OVERALL(numlist min=1) FOR(string) ///
		DYDX AGGregationweight(string) Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// Incorporate aggregation weights
	if "`aggregationweight'" == "" local aggregationweight "obslevel" // specify obslevel or grouplevel
	// If they gave weird strings as the specification
	if "`aggregationweight'"!="obslevel" & "`aggregationweight'"!="grouplevel" {
		display as error `"Value for {bf:aggregationweight()} must be "obslevel" or "grouplevel"."'
		exit 198
	}

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax' & `touse'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	tempvar expsubset meventtime
	quietly generate `expsubset' = .
	if "`overall'"!="" {
		local overall "`=subinstr(trim("`overall'")," ",",",.)'"
		quietly replace `expsubset' = `eventtime' if  inlist(`eventtime', `overall') & `touse'
	}
	else quietly replace `expsubset' = `eventtime' if `eventtime'>=0 & `touse'

	quietly levelsof `expsubset', local(lofby)
	local overall "`=subinstr(trim("`lofby'")," ",",",.)'"

	tempvar ttx
	quietly generate byte `ttx' = _Tx if `touse'
	quietly replace `ttx' = 1 if _Cohort>0 & `eventtime'==-1 & `touse'

	if "`for'"!="" local andfor "& (`for')"

	if "`for'"!="" local ttl "Overall ATET for `for'"
	else local ttl "Overall ATET"

	if "`aggregationweight'"=="grouplevel" {
		tempvar ngt ng aggwt
		quietly egen `ngt' = count(`group') if _Cohort>0, by(`group' `time')
		quietly egen `ng' = count(`group') if _Cohort>0, by(`group')
		quietly tab `time'
		quietly generate double `aggwt' = `ng'/r(r)/`ngt'
		quietly sum `aggwt' if `ttx'==1 & inlist(`eventtime', `overall')==1 `andfor',d
		quietly replace `aggwt' = `aggwt'/r(mean)

		if "`dydx'"=="dydx" quietly margins, expr(predict(xb)*`aggwt') dydx(_Tx) subpop(if `ttx'==1 & inlist(`eventtime', `overall')==1 `andfor') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, expr(predict(xb)*`aggwt') subpop(if `ttx'==1 & inlist(`eventtime', `overall')==1 `andfor') contrast(effects nowald) vce(unconditional) noomit post `options'
	}

	else if "`aggregationweight'"=="obslevel" {
		if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if `ttx'==1 & inlist(`eventtime', `overall')==1 `andfor') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, subpop(if `ttx'==1 & inlist(`eventtime', `overall')==1 `andfor') contrast(effects nowald) vce(unconditional) noomit post `options'
	}

	tempname beta Var nm 
	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	matrix `nm'   = r(_N)
	local nfull = r(N)
	local nsub    = r(N_sub)
	mata: mata: st_global("e(depvar)", "`yvar'")
	matrix colnames `beta' = "Overall"
	mata: st_global("e(r2)", "")
	mata: st_global("e(r2_a)", "")
	mata: st_global("e(rmse)", "")

	_coef_table_header, title(`ttl') nomodel
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var') coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate the standard error of ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET over exposure time"
	return local atettype "overall"
	if "`for'"!="" return local for "`for'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program define _ATET_Byget, rclass
	syntax [anything], [byget BYGET(numlist min=1) FOR(string) ///
		TEst(string) DYDX AGGregationweight(string)Level(cilevel) *]
      
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	if "`test'"!="" & "`test'"!="zero" & "`test'"!="equal" {
		display as error `"Value for {bf:test()} must be "zero" or "equal"."'
		exit 198
	}

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	tempvar expsubset meventtime
	quietly generate `expsubset' = .
	if "`byget'"!="" {
		local byget "`=subinstr(trim("`byget'")," ",",",.)'"
		quietly replace `expsubset' = `eventtime' if  inlist(`eventtime', `byget')
	}
	else quietly replace `expsubset' = `eventtime'

	tempvar ttx
	quietly generate byte `ttx' = _Tx if `touse'
	quietly replace `ttx' = 1 if _Cohort>0 & `eventtime'==-1 & `touse'

	if "`for'"!="" local andfor "& (`for')"

	tempvar gt
	quietly egen `gt' = group(`group' `expsubset') if _Tx==1 `andfor', label

	quietly levelsof `group' if _Cohort>0 `andfor', local(lofg)
	foreach g of local lofg {
		quietly levelsof `expsubset' if `group'==`g' & _Tx==1 `andfor', local(loft)
		foreach t of local loft {
			local lofgt `"`lofgt' "`g' `t'""'
		}
	}

	quietly levelsof `expsubset' if _Tx==1 `andfor', local(lofes)
	local byget "`=subinstr(trim("`lofes'")," ",",",.)'"

	if "`for'"!="" local ttl "ATET by group and exposure time for `for'"
	else local ttl "ATET by group and exposure time"

	if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if `ttx'==1 & inlist(`eventtime', `byget')==1 `andfor') over(`gt') vce(unconditional) post `options'

	else quietly margins r._Tx, subpop(if `ttx'==1 & inlist(`eventtime', `byget')==1 `andfor') over(`gt') contrast(effects nowald) vce(unconditional) post `options'

	tempname beta Var nm 
	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", `""G X ET""')
	matrix colnames `beta' = `lofgt'

	_coef_table_header, title(`ttl') nomodel
*	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
*	display as text "{ralign 71:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level') noabbrev
	display as text "Note: Linearization is used to calculate standard errors of each ATET"
	display as text "      G X ET is a group (G) at exposure time (ET) where exposure is"
	display as text "      is the number of periods since the first treatment time"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET by group and exposure time"
	return local atettype "byget"
	if "`for'"!="" return local for "`for'"
	return local test "`test'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program define _ATET_Byexposure, rclass
	syntax [anything], [byexposure BYEXPOSURE(numlist min=1) FOR(string) ///
		NOGraph GRAPHoptions(string) TEst(string) DYDX AGGregationweight(string)Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	if "`test'"!="" & "`test'"!="zero" & "`test'"!="equal" {
		display as error `"Value for {bf:test()} must be "zero" or "equal"."'
		exit 198
	}

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// Incorporate aggregation weights
	if "`aggregationweight'" == "" local aggregationweight "obslevel" // specify obslevel or grouplevel
	// If they gave weird strings as the specification
	if "`aggregationweight'"!="obslevel" & "`aggregationweight'"!="grouplevel" {
		display as error `"Value for {bf:aggregationweight()} must be "obslevel" or "grouplevel"."'
		exit 198
	}

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	tempvar expsubset meventtime
	quietly generate `expsubset' = .
	if "`byexposure'"!="" {
		local byexposure "`=subinstr(trim("`byexposure'")," ",",",.)'"
		quietly replace `expsubset' = `eventtime' if  inlist(`eventtime', `byexposure')
	}
	else quietly replace `expsubset' = `eventtime'
	quietly egen `meventtime' = group(`expsubset'), label
	quietly levelsof `meventtime', local(lofm)

	tempvar ttx
	quietly generate byte `ttx' = _Tx if `touse'
	quietly replace `ttx' = 1 if _Cohort>0 & `eventtime'==-1 & `touse'

	if "`for'"!="" local andfor "& (`for')"

	quietly levelsof `expsubset' if `ttx'==1 `andfor', local(lofby)
	local byexposure "`=subinstr(trim("`lofby'")," ",",",.)'"

	if "`for'"!="" local ttl "ATET by exposure time for `for'"
	else local ttl "ATET by exposure time"

	if "`aggregationweight'"=="grouplevel" {
		tempvar ngt ng aggwt
		quietly egen `ngt' = count(`group') if _Cohort>0, by(`group' `time')
		quietly egen `ng' = count(`group') if _Cohort>0, by(`group')
		quietly tab `time'
		quietly generate double `aggwt' = `ng'/r(r)/`ngt'
		quietly sum `aggwt' if `ttx'==1 & inlist(`eventtime', `byexposure')==1 `andfor',d
		quietly replace `aggwt' = `aggwt'/r(mean)

		if "`dydx'"=="dydx" quietly margins, expr(predict(xb)*`aggwt') dydx(_Tx) subpop(if `ttx'==1 & inlist(`eventtime', `byexposure')==1 `andfor') over(`meventtime') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, expr(predict(xb)*`aggwt') subpop(if `ttx'==1 & inlist(`eventtime', `byexposure')==1 `andfor') contrast(effects nowald) over(`meventtime') vce(unconditional) noomit post `options'
	}

	else if "`aggregationweight'"=="obslevel" {
		if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if `ttx'==1 & inlist(`eventtime', `byexposure')==1 `andfor') over(`meventtime') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, subpop(if `ttx'==1 & inlist(`eventtime', `byexposure')==1 `andfor') contrast(effects nowald) over(`meventtime') vce(unconditional) noomit post `options'
	}

	if "`nograph'"=="" quietly marginsplot, xtitle(Exposure `time') ytitle({&Delta} `yvar') title("`ttl'") yline(0) `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Exposure")
	matrix colnames `beta' = `lofby'

	_coef_table_header, title(`ttl') nomodel
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"
	display as text "      Exposure is the number of periods since the first treatment time"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET by exposure time"
	return local atettype "byexposure"
	if "`for'"!="" return local for "`for'"
	return local test "`test'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program define _ATET_Bycalendar, rclass
	syntax [anything], [bycalendar BYCALENDAR(numlist min=1) FOR(string) ///
		NOGraph GRAPHoptions(string) TEst(string) DYDX AGGregationweight(string)Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	if "`test'"!="" & "`test'"!="zero" & "`test'"!="equal" {
		display as error `"Value for {bf:test()} must be "zero" or "equal"."'
		exit 198
	}

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// Incorporate aggregation weights
	if "`aggregationweight'" == "" local aggregationweight "obslevel" // specify obslevel or grouplevel
	// If they gave weird strings as the specification
	if "`aggregationweight'"!="obslevel" & "`aggregationweight'"!="grouplevel" {
		display as error `"Value for {bf:aggregationweight()} must be "obslevel" or "grouplevel"."'
		exit 198
	}

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax' & `touse'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	tempvar calsubset
	quietly generate `calsubset' = .
	if "`bycalendar'"!="" {
		local bycalendar "`=subinstr(trim("`bycalendar'")," ",",",.)'"
		quietly replace `calsubset' = `time' if  inlist(`time', `bycalendar') & `touse'
	}
	else quietly replace `calsubset' = `time' if `touse'

	if "`for'"!="" local andfor "& (`for')"

	quietly levelsof `calsubset' if _Tx==1 `andfor', local(lofby)
	local bycalendar "`=subinstr(trim("`lofby'")," ",",",.)'"

	if "`for'"!="" local ttl "ATET by calendar time for `for'"
	else local ttl "ATET by calendar time"

	if "`aggregationweight'"=="grouplevel" {
		tempvar ngt ng aggwt
		quietly egen `ngt' = count(`group') if _Cohort>0, by(`group' `time')
		quietly egen `ng' = count(`group') if _Cohort>0, by(`group')
		quietly tab `time'
		quietly generate double `aggwt' = `ng'/r(r)/`ngt'
		quietly sum `aggwt' if _Tx==1 & inlist(`time', `bycalendar')==1 `andfor',d
		quietly replace `aggwt' = `aggwt'/r(mean)

		if "`dydx'"=="dydx" quietly margins, expr(predict(xb)*`aggwt') dydx(_Tx) subpop(if _Tx==1 & inlist(`time', `bycalendar')==1 `andfor') over(`calsubset') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, expr(predict(xb)*`aggwt') subpop(if _Tx==1 & inlist(`time', `bycalendar')==1 `andfor') contrast(effects nowald) over(`calsubset') vce(unconditional) noomit post `options'
	}

	else if "`aggregationweight'"=="obslevel" {
		if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if _Tx==1 & inlist(`time', `bycalendar')==1 `andfor') over(`calsubset') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, subpop(if _Tx==1 & inlist(`time', `bycalendar')==1 `andfor') contrast(effects nowald) over(`calsubset') vce(unconditional) noomit post `options'
	}

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Calendar time) ytitle({&Delta} `yvar') title("`ttl'") yline(0)  `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Calendar")
	matrix colnames `beta' = `lofby'

	_coef_table_header, title(`ttl') nomodel
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET by calendar time"
	return local atettype "bycalendar"
	if "`for'"!="" return local for "`for'"
	return local test "`test'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program define _ATET_Bycohort, rclass
	syntax [anything], [bycohort BYCOHORT(numlist min=1) FOR(string) ///
		NOGraph GRAPHoptions(string) TEst(string) DYDX AGGregationweight(string)Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	if "`test'"!="" & "`test'"!="zero" & "`test'"!="equal" {
		display as error `"Value for {bf:test()} must be "zero" or "equal"."'
		exit 198
	}

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// Incorporate aggregation weights
	if "`aggregationweight'" == "" local aggregationweight "obslevel" // specify obslevel or grouplevel
	// If they gave weird strings as the specification
	if "`aggregationweight'"!="obslevel" & "`aggregationweight'"!="grouplevel" {
		display as error `"Value for {bf:aggregationweight()} must be "obslevel" or "grouplevel"."'
		exit 198
	}

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax' & `touse'
	}

	tempvar eventtime mcohort
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	// marginsplot is nicer if cohort is defined as sequential integers (mcohort)
	tempvar chrtsubset
	local bycohort "`=subinstr(trim("`bycohort'")," ",",",.)'"
	quietly generate `chrtsubset' = .
	if "`bycohort'"!="" {
		quietly replace `chrtsubset' = _Cohort if inlist(_Cohort, `bycohort') & `touse'
	}
	else quietly replace `chrtsubset' = _Cohort if _Cohort>0 & `touse'
	quietly egen `mcohort' = group(`chrtsubset'), label
	quietly replace `mcohort' = . if _Cohort == 0 & `touse'
	quietly levelsof `mcohort', local(lofm)
	quietly levelsof `chrtsubset', local(lofby)

	if "`for'"!="" local andfor "& (`for')"

	if "`for'"!="" local ttl "ATET by treated cohort for `for'"
	else local ttl "ATET by treated cohort"

	if "`aggregationweight'"=="grouplevel" {
		tempvar ngt ng aggwt
		quietly egen `ngt' = count(`group') if _Cohort>0, by(`group' `time')
		quietly egen `ng' = count(`group') if _Cohort>0, by(`group')
		quietly tab `time'
		quietly generate double `aggwt' = `ng'/r(r)/`ngt'
		quietly sum `aggwt' if _Tx==1 & `eventtime'>=0 `andfor')==1 `andfor',d
		quietly replace `aggwt' = `aggwt'/r(mean)

		if "`dydx'"=="dydx" quietly margins, expr(predict(xb)*`aggwt') dydx(_Tx) subpop(if _Tx==1 & `eventtime'>=0 `andfor') over(`mcohort') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, expr(predict(xb)*`aggwt') subpop(if _Tx==1 & `eventtime'>=0 `andfor') contrast(effects nowald) over(`mcohort') vce(unconditional) noomit post `options'
	}

	else if "`aggregationweight'"=="obslevel" {
		if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if _Tx==1 & `eventtime'>=0 `andfor') over(`mcohort') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, subpop(if _Tx==1 & `eventtime'>=0 `andfor') contrast(effects nowald) over(`mcohort') vce(unconditional) noomit post `options'
	}

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Cohort by entry time) ytitle({&Delta} `yvar') title("`ttl'") yline(0)  xlabel(`lofm') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Treated cohort")
	matrix colnames `beta' = `lofm'

	_coef_table_header, title(`ttl') nomodel
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"
	display as text "      Cohort is labeled by the time of first treatment"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET by treated cohort"
	return local atettype "bycohort"
	if "`for'"!="" return local for "`for'"
	return local test "`test'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program define _ATET_Bygroup, rclass
	syntax [anything], [bygroup BYGROUP(numlist min=1) FOR(string) ///
		NOGraph GRAPHoptions(string) TEst(string) DYDX AGGregationweight(string)Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local usercohort `e(usercohort)'
	local clustvar `e(clustvar)'
	local wexp `e(wexp)'
	local specification `e(specification)'
	local yvar `e(depvar)'

	if "`test'"!="" & "`test'"!="zero" & "`test'"!="equal" {
		display as error `"Value for {bf:test()} must be "zero" or "equal"."'
		exit 198
	}

	// Weight var
	local wt `=subinstr("`e(wexp)'","= ","",.)'

	// Marksample
	marksample touse
	markout `touse' `clustvar' `wt' `tx' `group' `time', strok

	// Incorporate aggregation weights
	if "`aggregationweight'" == "" local aggregationweight "obslevel" // specify obslevel or grouplevel
	// If they gave weird strings as the specification
	if "`aggregationweight'"!="obslevel" & "`aggregationweight'"!="grouplevel" {
		display as error `"Value for {bf:aggregationweight()} must be "obslevel" or "grouplevel"."'
		exit 198
	}

	// If there are no never-treated units
	quietly sum _Cohort if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Cohort = 0 if _Cohort == `cmax' & `touse'
	}

	tempvar eventtime mgroup
	quietly generate `eventtime' = `time' - _Cohort if _Cohort>0 & `touse'
	quietly replace `eventtime' = -1 if _Cohort==0 & `touse'

	// marginsplot is nicer if group is defined as sequential integers (mgroup)
	tempvar grpsubset
	local bygroup "`=subinstr(trim("`bygroup'")," ",",",.)'"
	quietly generate `grpsubset' = .
	if "`bygroup'"!="" {
		quietly replace `grpsubset' = `group' if inlist(`group', `bygroup') & `touse'
	}
	else quietly replace `grpsubset' = `group' if _Cohort>0 & `touse'
	quietly egen `mgroup' = group(`grpsubset'), label
	quietly replace `mgroup' = . if _Cohort == 0 & `touse'
	quietly levelsof `mgroup', local(lofm)
	quietly levelsof `grpsubset', local(lofby)

	if "`for'"!="" local andfor "& (`for')"

	if "`for'"!="" local ttl "ATET by treated group for `for'"
	else local ttl "ATET by treated group"

	if "`aggregationweight'"=="grouplevel" {
		tempvar ngt ng aggwt
		quietly egen `ngt' = count(`group') if _Cohort>0, by(`group' `time')
		quietly egen `ng' = count(`group') if _Cohort>0, by(`group')
		quietly tab `time'
		quietly generate double `aggwt' = `ng'/r(r)/`ngt'
		quietly sum `aggwt' if _Tx==1 & `eventtime'>=0 `andfor')==1 `andfor',d
		quietly replace `aggwt' = `aggwt'/r(mean)

		if "`dydx'"=="dydx" quietly margins, expr(predict(xb)*`aggwt') dydx(_Tx) subpop(if _Tx==1 & `eventtime'>=0 `andfor') over(`mgroup') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, expr(predict(xb)*`aggwt') subpop(if _Tx==1 & `eventtime'>=0 `andfor') contrast(effects nowald) over(`mgroup') vce(unconditional) noomit post `options'
	}

	else if "`aggregationweight'"=="obslevel" {
		if "`dydx'"=="dydx" quietly margins, dydx(_Tx) subpop(if _Tx==1 & `eventtime'>=0 `andfor') over(`mgroup') vce(unconditional) noomit post `options'

		else quietly margins r._Tx, subpop(if _Tx==1 & `eventtime'>=0 `andfor') contrast(effects nowald) over(`mgroup') vce(unconditional) noomit post `options'
	}

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Treated group) ytitle({&Delta} `yvar') title("`ttl'") yline(0)  xlabel(`lofm') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Treated group")
	matrix colnames `beta' = `lofby'

	_coef_table_header, title(`ttl') nomodel
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET by treated group"
	return local atettype "bygroup"
	if "`for'"!="" return local for "`for'"
	return local test "`test'"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

end 


program Testing, sortpreserve
	syntax [anything], [TEST(string) ATETTYPE(string) Level(cilevel) *]

	if "`atettype'"=="byget" {
		if "`for'"!="" {
			if "`test'"=="zero" local ttl "Test of zero ATET by group and exposure time for `for'"
			else if "`test'"=="equal" local ttl "Test of equal ATET by group and exposure time for `for'"
		}
		else {
			if "`test'"=="zero" local ttl "Test of zero ATET by group and exposure time"
			else if "`test'"=="equal" local ttl "Test of equal ATET by group and exposure time"
		}
	}

	if "`atettype'"=="byexposure" {
		if "`for'"!="" {
			if "`test'"=="zero" local ttl "Test of zero ATET by exposure time for `for'"
			else if "`test'"=="equal" local ttl "Test of equal ATET by exposure time for `for'"
		}
		else {
			if "`test'"=="zero" local ttl "Test of zero ATET by exposure time"
			else if "`test'"=="equal" local ttl "Test of equal ATET by exposure time"
		}
	}

	if "`atettype'"=="bycalendar" {
		if "`for'"!="" {
			if "`test'"=="zero" local ttl "Test of zero ATET by calendar time for `for'"
			else if "`test'"=="equal" local ttl "Test of equal ATET by calendar time for `for'"
		}
		else {
			if "`test'"=="zero" local ttl "Test of zero ATET by calendar time"
			else if "`test'"=="equal" local ttl "Test of equal ATET by calendar time"
		}
	}

	if "`atettype'"=="bycohort" {
		if "`for'"!="" {
			if "`test'"=="zero" local ttl "Test of zero ATET by treated cohort for `for'"
			else if "`test'"=="equal" local ttl "Test of equal ATET by treated cohort for `for'"
		}
		else {
			if "`test'"=="zero" local ttl "Test of zero ATET by treated cohort"
			else if "`test'"=="equal" local ttl "Test of equal ATET by treated cohort"
		}
	}

	if "`atettype'"=="bygroup" {
		if "`for'"!="" {
			if "`test'"=="zero" local ttl "Test of zero ATET by treated group for `for'"
			else if "`test'"=="equal" local ttl "Test of equal ATET by treated group for `for'"
		}
		else {
			if "`test'"=="zero" local ttl "Test of zero ATET by treated group"
			else if "`test'"=="equal" local ttl "Test of equal ATET by treated group"
		}
	}

	if "`test'"=="zero" quietly test "`:colnames e(b)'"
	else if "`test'"=="equal" quietly test "_b[`=subinstr("`:colnames e(b)'"," ","]=_b[",.)']"
	
	display as text _n "`ttl'"
	if "`test'"=="zero" display as text "H0: All effects are equal to zero"
	else if "`test'"=="equal" display as text "H0: Effects are equal to each other"
	display as text "    F(`r(df)',`r(df_r)') = " as result "`:di %7.3f  `r(F)''"
	display as text "    Prob > F = " as result "`:di %6.4f `r(p)''"

	scalar _df = r(df)
	scalar _df_r = r(df_r)
	scalar _F = r(F)
	scalar _p = r(p)

end