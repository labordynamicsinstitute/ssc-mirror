*! Package sccsdta v. 1.1
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2024-05-24 > v. 1.1 Improved code and help
* 2024-05-06 > v. 1.0 Created
program define sccsdta, rclass

	version 12.1
	
	syntax varlist(min=2 max=2), /*
		*/ENter(string) /*
		*/Riskpoints(numlist sort) /*
		*/[/*
			*/Timepoints(numlist sort) /*
			*/EXit(varname) /*
			*/Absolutetimepoints /*
			*/noRegression /*
			*/noQuietly /*
			*/ * /*
		*/]
	
	if "`quietly'" == "" local QUIETLY quietly 
	`QUIETLY' {
		tokenize "`varlist'"
		
		generate _rowid = _n
		
		capture confirm variable `enter'
		if _rc {
			capture confirm number `enter'
			if _rc mata _error("Enter must be either a variable name or a number")
		}
		generate _stopp1 = `enter'
		
		local nbr 3
		foreach rsk_p in `riskpoints' {
			generate _stoprp`nbr++' = `2' + `rsk_p'
		}
		
		if "`timepoints'`exit'" == "" mata: _error("You must fill either option exit or option timepoints")

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

		bysort _rowid (_stop): generate _start = _stop[_n-1] //, before(_stop)
		drop if mi(_start)
		label variable _start "Time inteval start"

		generate _nevents = _start < `1' & `1' <= _stop
		label variable _nevents "Events (#)"
		
		local nbr 0
		generate _exgr = 0
		label define _exgr 0 "no" 
		foreach tm_p in `riskpoints' {
			if `nbr++' replace _exgr = `nbr' - 1 if (`2' + `tm_p' >= _stop & `2' + `prev' < _stop)
			if `nbr' > 1 label define _exgr `=`nbr'-1' "]`prev'; `tm_p']", add
			local prev `tm_p'
		}
		label variable _exgr "At risk"
		label values _exgr _exgr

		local nbr 1
		generate _tmgr = .
		foreach tm_p in `timepoints' {
			if `nbr' == 1 label define _tmgr `nbr' "]enter; `tm_p']", add
			else label define _tmgr `nbr' "]`prev'; `tm_p']", add
			if "`tm_p'" == "exit" & "`absolutetimepoints'" != "" local tm_p = `exit'
			if "`absolutetimepoints'" == "" replace _tmgr = `nbr' if (`enter' + `tm_p' >= _stop) & (`enter' + `prev' < _stop) 
			else replace _tmgr = `nbr' if (`tm_p' >= _stop) & (`prev' < _stop) 
			local nbr = `nbr' + 1
			local prev `tm_p'
		}
		
		label variable _tmgr "Time group"
		label values _tmgr _tmgr

		generate _interval = _stop - _start

		drop if _start == _stop 
		order _rowid _start _stop _nevents _exgr _tmgr _interval, last 
	}
	local cmd xtpoisson _nevents i._exgr i._tmgr, fe i(_rowid) exposure(_interval) irr `options'
	return local cmd = `"`cmd'"'
	if "`regression'" == "" {
		display _n `". `cmd'"' _n
		`cmd'
	}
end
