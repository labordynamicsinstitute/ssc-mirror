*! Package sccsdta v. 1.4
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2025-03-13 > v. 1.4 Bugfix in rtbl()
* 2025-02-19 > v. 1.3 A data summary matrix is returned and echoed in the Resut window
* 2025-02-19 > v. 1.3 Help file modified according to Stata Journal review comments
* 2024-06-21 > v. 1.2 Option preserve added
* 2024-06-21 > v. 1.2 Use event times as time period end points (semiparametric) 2006 Farrington - Semiparametric analysis of case series data
* 2024-06-14 > v. 1.2 preserve added
* 2024-06-14 > v. 1.2 if added
* 2024-06-09 > v. 1.2 code for _tmgr refined
* 2024-06-09 > v. 1.2 log output modified
* 2024-05-24 > v. 1.2 Bugfix
* 2024-05-24 > v. 1.1 Improved code and help
* 2024-05-06 > v. 1.0 Created
program define sccsdta, rclass

	version 12.1
	
	syntax varlist(min=2 max=2) [if], /*
		*/ENter(string) /*
		*/Riskpoints(numlist sort) /*
		*/[/*
			*/Timepoints(numlist sort) /*
			*/EXit(varname) /*
			*/Absolutetimepoints /*
			*/EVenttimes /*
			*/NKnots(passthru) /*
			*/noRegression /*
			*/noQuietly /*
			*/Preserve /*
			*/ * /*
		*/]
	
	if "`quietly'" == "" local QUIETLY quietly 
	`QUIETLY' {
		
		`preserve'
		
		if "`if'" != "" keep `if'
		
		tokenize "`varlist'"
		
		generate _rowid = _n
		label variable _rowid "Row Id"
		
		capture confirm variable `enter'
		if _rc {
			capture confirm number `enter'
			if _rc mata _error("Enter must be either a variable name or a number")
			if _rc mata _error("Enter must be a variable name")
		}
		generate _stopp1 = `enter'
		
		local nbr 3
		foreach rsk_p in `riskpoints' {
			generate _stoprp`nbr++' = `2' + `rsk_p'
		}
		
		if "`nknots'" != "" local eventtimes eventtimes
		
		if "`eventtimes'" != "" {
			qui levelsof `1', local(timepoints)
			local absolutetimepoints absolutetimepoints
		}
		
		if "`timepoints'`exit'`eventtimes'" == "" mata: _error("One of the options exit, timepoints, eventtimes, or nknots must be set")

		if "`exit'" != "" { 
			generate _stopp2 = `exit'
			local timepoints `timepoints' exit
		}
		
		local nbr 2
		foreach tm_p in `timepoints' {
			if "`tm_p'" == "exit" continue
			if "`absolutetimepoints'" == "" generate _stoptm`nbr++' = `enter' + `tm_p'
			else generate _stoptm`nbr++' = `tm_p'
		}

		reshape long _stop, i(_rowid `1') j(_type) string
				
		drop _type
		
		label variable _stop "Time inteval stop"
		
		tempname ub
		if "`exit'" == "" bysort _rowid (_stop): generate `ub' = _stop[_N]
		else generate `ub' = `exit'
		replace _stop = min(max(_stop, `enter'), `ub')

		local tmgr i._tmgr
		if "`eventtimes'" != "" {
			if "`nknots'" != "" {
				mkspline _rcs_tm = _stop, cubic `nknots'
				local tmgr c._rcs_tm?
			}
		}
		
		bysort _rowid (_stop): generate _start = _stop[_n-1]
		drop if mi(_start)
		label variable _start "Time inteval start"

		generate _nevents = _start < `1' & `1' <= _stop
		label variable _nevents "Events (#)"
		
		local nbr 0
			generate _exgr = 0
		label define _exgr 0 "ctrl" 
		foreach tm_p in `riskpoints' {
			if `nbr++' replace _exgr = `nbr' - 1 if (`2' + `tm_p' >= _stop & `2' + `prev' < _stop)
			if `nbr' > 1 label define _exgr `=`nbr'-1' "(`prev', `tm_p']", add
			local prev `tm_p'
		}
		label variable _exgr "At risk"
		label values _exgr _exgr

		local nbr 1
		generate _tmgr = .
		if "`absolutetimepoints'" == "" {
			tempvar lb
			generate `lb' = `enter'
			foreach tm_p in `timepoints' {
				if "`tm_p'" == "exit" local tm_p = `exit'
				tempvar ub
				generate `ub' = `enter' + `tm_p'
				replace _tmgr = `nbr' if (`ub' >= _stop) & (`lb' < _stop) 
				local nbr = `nbr' + 1
				replace `lb' = `ub'
			}
		}
		else {
			local prev 
			foreach tm_p in `timepoints' {
				if "`tm_p'" == "exit" local tm_p = `exit'
				if `nbr' > 1 replace _tmgr = `nbr' if (`tm_p' >= _stop) & (`prev' < _stop) 
				else replace _tmgr = `nbr' if (`tm_p' >= _stop) & (`enter' < _stop) 
				local nbr = `nbr' + 1
				local prev `tm_p'
			}
		}
		if "`absolutetimepoints'" == "" local rel_tm_txt "enter+" 
		local nbr 1
		foreach tm_p in `timepoints' {
			if `nbr' == 1 local lbl 1 "(enter, `rel_tm_txt'`tm_p']"
			else local lbl `lbl' `nbr' "(`rel_tm_txt'`prev', `rel_tm_txt'`tm_p']"
			local nbr = `nbr' + 1
			local prev `tm_p'
		}
		label variable _tmgr "Time group"
		label define _tmgr `lbl'
		label values _tmgr _tmgr
		`QUIETLY' drop if mi(_tmgr)

		generate _interval = _stop - _start
		label variable _interval "Follow-up time"

		drop if _start == _stop 
		order _rowid _start _stop _nevents _exgr _tmgr _interval, last 
	}
	mata: summary()
	matlist summary, twidth(32) title("Interval and event counts, and follow-up time by risk groups")
	return matrix summary = summary
	if "`regression'" == "" {
		local cmd xtpoisson _nevents i._exgr `tmgr', fe i(_rowid) exposure(_interval) irr `options'
		return local cmd = `"`cmd'"'
		`QUIETLY' `cmd'
		mata: rtbl("r(table)", "sccsdta")
		matlist sccsdta, format(`c(cformat)') twidth(32) title("The SCCS regression table")
		return matrix sccsdta = sccsdta
	}
	if "`preserve'" != "" restore
end

mata:
	void summary()
	{
		real matrix x, info, tbl
		string colvector lbl
		
		x = sort(st_data(., "_exgr _nevents _interval"), 1)
		info=panelsetup(x, 1)
		tbl = panelsum((J(rows(x),1,1), x[.,2..3]), info)
		st_matrix("summary", tbl \ colsum(tbl))
		lbl = st_vlmap("_exgr", uniqrows(x[.,1]))  \ "Total"
		st_matrixrowstripe("summary", (J(rows(lbl),1,""), lbl))
		st_matrixcolstripe("summary", (J(3,1,""), ("n", "events", "Follow-up")'))
	}

	void rtbl(string scalar matnm, string scalar new_nm) {
		string scalar rn
		string matrix rns, new_rns
		real scalar r, R
		
		rns = st_matrixcolstripe(matnm)
		R = rows(rns)
		new_rns = J(R, 2, "NA")

		for(r=1; r<=R; r++) {
			rn = regexm(rns[r,2], "^([0-9]+).?\.(.+)$") ? st_vlmap(regexs(2), strtoreal(regexs(1))) : "NA2"
			if ( regexm(rns[r,2], "_exgr$") ) {
				new_rns[r, .] = "At risk", rn
			} else if ( regexm(rns[r,2], "_tmgr$") ) {
				new_rns[r, .] = "Time group", rn
			} else if ( regexm(rns[r,2], "_rcs_tm") ) {
				new_rns[r, .] = "Time by restricted cubic splines", rns[r,2]
			}
		}
		st_matrix(new_nm, st_matrix(matnm)[(1,5,6,4), .]')
		st_matrixrowstripe(new_nm, new_rns)
		st_matrixcolstripe(new_nm, (J(4,1,""), ("IRR" \ "[95%" \ "CI]" \ "P(IRR=1)")))
	}
end
