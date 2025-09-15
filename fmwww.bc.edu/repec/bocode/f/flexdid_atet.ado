*! version 1.0.0  10sep2025

program flexdid_atet 
        version 17.0

        Compute `0'

end

program Compute, rclass sortpreserve
	syntax [anything], [					///
		 OVERALL1							///
		 OVERALL(numlist min=1)				///
		 BYEXPOSURE1						///
		 BYEXPOSURE(numlist min=1)			///
		 BYCALENDAR1						///
		 BYCALENDAR(numlist min=1)			///
		 BYCOHORT1							///
		 BYCOHORT(numlist min=1)			///
		 BYGROUP1							///
		 BYGROUP(numlist min=1)				///
		 Level(cilevel)						///
		 NOGRaph							///
		 GRAPHoptions(string)				///
		 fromestimation						///
		 * ]
        
	if ("`overall'"!=""|"`overall1'"!="") {
		if ("`overall1'"!="" & "`overall'"!="") {
				opts_exclusive "overall {bf:overall()}" 
		}
		_ATET_Overall `0'
	}
	else if ("`byexposure'"!=""|"`byexposure1'"!="") {
		if ("`byexposure1'"!="" & "`byexposure'"!="") {
				opts_exclusive "byexposure {bf:byexposure()}" 
		}
		_ATET_Byexposure `0'
	}
	else if ("`bycalendar'"!=""|"`bycalendar1'"!="") {
		if ("`bycalendar1'"!="" & "`bycalendar'"!="") {
				opts_exclusive "bycalendar {bf:bycalendar()}" 
		}
		_ATET_Bycalendar `0'
	}
	else if ("`bycohort'"!=""|"`bycohort1'"!="") {
		if ("`bycohort1'"!="" & "`bycohort'"!="") {
				opts_exclusive "bycohort {bf:bycohort()}" 
		}
		_ATET_Bycohort `0'
	}
	else if ("`bygroup'"!=""|"`bygroup1'"!="") {
		if ("`bygroup1'"!="" & "`bygroup'"!="") {
				opts_exclusive "bygroup {bf:bygroup()}" 
		}
		_ATET_Bygroup `0'
	}

	return add
end


program define _ATET_Overall, rclass
	syntax [anything], [overall OVERALL(numlist min=1) ///
		Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local txgroup `e(txgroup)'
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

	// If there are no never-treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax' & `touse'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	tempvar expsubset meventtime
	quietly generate `expsubset' = .
	if "`overall'"!="" {
		local overall "`=subinstr(trim("`overall'")," ",",",.)'"
		quietly replace `expsubset' = `eventtime' if  inlist(`eventtime', `overall') & `touse'
	}
	else quietly replace `expsubset' = `eventtime' if `eventtime'>=0 & `touse'

	quietly levelsof `expsubset', local(lofe)
	local overall "`=subinstr(trim("`lofe'")," ",",",.)'"

	tempvar ttx
	quietly generate byte `ttx' = _Tx if `touse'
	quietly replace `ttx' = 1 if _Chrt>0 & `eventtime'==-1 & `touse'

	quietly margins r._Tx, subpop(if `ttx'==1 & inlist(`eventtime', `overall')==1) contrast(effects nowald) vce(unconditional) noestimcheck `options'

	tempname beta Var nm 
	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	matrix `nm'   = r(_N)
	local nfull = r(N)
	local nsub    = r(N_sub)
	matrix colnames `beta' = "Overall"
	mata: st_global("e(depvar)", "`yvar'")
	mata: st_global("e(r2)", "")
	mata: st_global("e(r2_a)", "")
	mata: st_global("e(rmse)", "")

	_coef_table_header, title(Overall ATET) nomodel
	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
	display as text "{ralign 72:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var') coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate the standard error of ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "ATET over exposure time"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

	ret local atettype "overall"

end 


program define _ATET_Byexposure, rclass
	syntax [anything], [byexposure BYEXPOSURE(numlist min=1) ///
		NOGraph GRAPHoptions(string) Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local txgroup `e(txgroup)'
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

	// If there are no never-treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	tempvar expsubset meventtime
	quietly generate `expsubset' = .
	if "`byexposure'"!="" {
		local byexposure "`=subinstr(trim("`byexposure'")," ",",",.)'"
		quietly replace `expsubset' = `eventtime' if  inlist(`eventtime', `byexposure')
	}
	else quietly replace `expsubset' = `eventtime'
	quietly egen `meventtime' = group(`expsubset'), label

	quietly levelsof `expsubset', local(lofe)
	local byexposure "`=subinstr(trim("`lofe'")," ",",",.)'"
	quietly levelsof `meventtime', local(lofm)

	tempvar ttx
	quietly generate byte `ttx' = _Tx if `touse'
	quietly replace `ttx' = 1 if _Chrt>0 & `eventtime'==-1 & `touse'

	quietly margins r._Tx, subpop(if `ttx'==1 & inlist(`eventtime', `byexposure')==1) over(`meventtime') contrast(effects nowald) vce(unconditional) noestimcheck `options'

	if "`nograph'"=="" quietly marginsplot, xtitle(Exposure `time') ytitle({&Delta} `yvar') title("") yline(0) xlabel(`lofm') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Exposure")
	matrix colnames `beta' = `lofe'

	_coef_table_header, title(Heterogeneous ATET by exposure time) nomodel
	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
	display as text "{ralign 72:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"
	display as text "      Exposure is the number of periods since the first treatment time"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "Heterogeneous ATET by exposure time"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

	ret local atettype "byexposure"

end 


program define _ATET_Bycalendar, rclass
	syntax [anything], [bycalendar BYCALENDAR(numlist min=1) ///
		NOGraph GRAPHoptions(string) Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local txgroup `e(txgroup)'
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

	// If there are no never-treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax' & `touse'
	}

	tempvar eventtime
	quietly generate `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	tempvar calsubset
	quietly generate `calsubset' = .
	if "`bycalendar'"!="" {
		local bycalendar "`=subinstr(trim("`bycalendar'")," ",",",.)'"
		quietly replace `calsubset' = `time' if  inlist(`time', `bycalendar') & `touse'
	}
	else quietly replace `calsubset' = `time' if `touse'

	quietly levelsof `calsubset', local(lofe)
	local bycalendar "`=subinstr(trim("`lofe'")," ",",",.)'"

	quietly margins r._Tx, subpop(if _Tx==1 & inlist(`time', `bycalendar')==1) over(`calsubset') contrast(effects nowald) vce(unconditional) noestimcheck `options'

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Calendar time) ytitle({&Delta} `yvar') title("") yline(0)  xlabel(`lofe') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Calendar")
	matrix colnames `beta' = `lofe'

	_coef_table_header, title(Heterogeneous ATET by calendar time) nomodel
	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
	display as text "{ralign 72:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "Heterogeneous ATET by calendar time"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

	ret local atettype "bycalendar"

end 


program define _ATET_Bycohort, rclass
	syntax [anything], [bycohort BYCOHORT(numlist min=1) ///
		NOGraph GRAPHoptions(string) Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local txgroup `e(txgroup)'
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

	// If there are no never-treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax' & `touse'
	}

	tempvar eventtime mcohort
	quietly generate `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	// marginsplot is nicer if cohort is defined as sequential integers (mcohort)
	tempvar chrtsubset
	local bycohort "`=subinstr(trim("`bycohort'")," ",",",.)'"
	quietly generate `chrtsubset' = .
	if "`bycohort'"!="" {
		quietly replace `chrtsubset' = _Chrt if inlist(_Chrt, `bycohort') & `touse'
	}
	else quietly replace `chrtsubset' = _Chrt if _Chrt>0 & `touse'
	quietly egen `mcohort' = group(`chrtsubset'), label
	quietly replace `mcohort' = . if _Chrt == 0 & `touse'
	quietly levelsof `mcohort', local(lofm)

	quietly margins r._Tx, subpop(if _Tx==1 & `eventtime'>=0) over(`mcohort') contrast(effects nowald) vce(unconditional) noestimcheck `options'

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Cohort by entry time) ytitle({&Delta} `yvar') title("") yline(0)  xlabel(`lofm') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Treated cohort")
	quietly levelsof `chrtsubset', local(lofe)
	matrix colnames `beta' = `lofe'

	_coef_table_header, title(Heterogeneous ATET by treated cohort) nomodel
	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
	display as text "{ralign 72:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"
	display as text "      Cohort is labeled by the time of first treatment"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "Heterogeneous ATET by treated cohort"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

	ret local atettype "bycohort"

end 


program define _ATET_Bygroup, rclass
	syntax [anything], [bygroup BYGROUP(numlist min=1) ///
		NOGraph GRAPHoptions(string) Level(cilevel) *]
        
	local group `e(group)'
	local time `e(time)'
	local tx `e(tx)'
	local txgroup `e(txgroup)'
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

	// If there are no never-treated units
	quietly sum _Chrt if `touse', meanonly
	local cmin = r(min)
	local cmax = r(max)
	if (`cmin'>0) {
		tempvar lc
		quietly generate `lc' = (`time'>=`cmax')
		quietly replace `lc' = . if `lc'==1
		markout `touse' `lc'
		quietly replace _Chrt = 0 if _Chrt == `cmax' & `touse'
	}

	tempvar eventtime mgroup
	quietly generate `eventtime' = `time' - _Chrt if _Chrt>0 & `touse'
	quietly replace `eventtime' = -1 if _Chrt==0 & `touse'

	// marginsplot is nicer if group is defined as sequential integers (mgroup)
	tempvar grpsubset
	local bygroup "`=subinstr(trim("`bygroup'")," ",",",.)'"
	quietly generate `grpsubset' = .
	if "`bygroup'"!="" {
		quietly replace `grpsubset' = _Grp if inlist(_Grp, `bygroup') & `touse'
	}
	else quietly replace `grpsubset' = _Grp if _Chrt>0 & `touse'
	quietly egen `mgroup' = group(`grpsubset'), label
	quietly replace `mgroup' = . if _Chrt == 0 & `touse'
	quietly levelsof `mgroup', local(lofm)

	quietly margins r._Tx, subpop(if _Tx==1 & `eventtime'>=0) over(`mgroup') contrast(effects nowald) vce(unconditional) noestimcheck `options'

	if "`nograph'"=="" quietly marginsplot, recast(scatter) xtitle(Treated group) ytitle({&Delta} `yvar') title("") yline(0)  xlabel(`lofm') `graphoptions'
	tempname beta Var nm 

	matrix `beta' = r(b)
	matrix `Var'  = r(V)
	local nfull = r(N)
	local nsub = r(N_sub)
	mata: mata: st_global("e(depvar)", "Treated group")
	quietly levelsof `grpsubset', local(lofe)
	matrix colnames `beta' = `lofe'

	_coef_table_header, title(Heterogeneous ATET by treated group) nomodel
	_align maxlen "diN diNt" : "`nfull' `nsub'" "15.0fc"
	display as text "{ralign 72:Treated obs = }" as result "`diNt'"
	display ""
	_coef_table, bmatrix(`beta') vmatrix(`Var')  coeftitle("ATET") level(`level')
	display as text "Note: Linearization is used to calculate standard errors of each ATET"

	mata: mata: st_global("e(depvar)", "`=word("`e(cmdline)'",2)'")

	tempname table 
	matrix `table' = r(table)
	return hidden local title "Heterogeneous ATET by treated group"
	return matrix table = `table'
	return matrix b     = `beta'
	return matrix V     = `Var'
	return add

	ret local atettype "bygroup"

end 
