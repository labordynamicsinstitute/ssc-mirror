program define sccsdta

	version 12.1
	
	syntax varlist(min=2 max=2), /*
		*/ENter(string) /*
		*/EXit(string) /*
		*/Riskpoints(numlist sort) /*
		*/[/*
			*/Timepoints(numlist sort) /*
			*/id(varname) /*
		*/]
	
	quietly {
		tokenize "`varlist'"
		
		if "`id'" != "" generate _id = `id'
		else generate _id = _n
		capture confirm variable `enter'
		if _rc {
			capture confirm number `enter'
			if _rc mata _error("Enter must be either a variable name or a number")
		}
		generate _stopp1 = `enter'
		capture confirm variable `exit'
		if _rc {
			capture confirm number `exit'
			if _rc mata _error("Exit must be either a variable name or a number")
		}
		generate _stopp2 = `exit'
		local nbr 3
		foreach rsk_p in `riskpoints' {
			generate _stopp`nbr++' = `2' + `rsk_p'
		}
		local nbr 2
		foreach tm_p in `timepoints' {
			generate _stopa`nbr++' = `tm_p'
		}
		reshape long _stop, i(_id `1') j(_type) string
		drop _type
		
		label variable _stop "Time inteval stop"
		replace _stop = min(max(_stop, `enter'), `exit')

		bysort _id (_stop): generate _start = _stop[_n-1] //, before(_stop)
		drop if mi(_start)
		label variable _start "Time inteval start"

		generate _nevents = `1' > _start & _stop >= `1'
		label variable _nevents "Events (#)"
		
		local nbr 0
		generate _exgr = 0
		label variable _exgr "At risk"
		label define _exgr 0 "no" 
		foreach tm_p in `riskpoints' {
			if `nbr++' replace _exgr = `nbr' - 1 if (`2' + `tm_p' >= _stop & `2' + `prev' < _stop)
			if `nbr' > 1 label define _exgr `=`nbr'-1' "]`prev'; `tm_p']", add
			local prev `tm_p'
		}
		label values _exgr _exgr

		local nbr 1
		local prev `enter'
		generate _tmgr = .
		label variable _tmgr "Age group"
		foreach tm_p in `timepoints' {
			if `nbr' == 1 label define _tmgr `nbr' "]`enter'; `tm_p']", add
			else label define _tmgr `nbr' "]`prev'; `tm_p']", add
			replace _tmgr = `nbr++' if (`tm_p' >= _stop) & (`prev' < _stop) 
			local prev `tm_p'
		}
		replace _tmgr = `nbr++' if (`exit' >= _stop) & (`prev' < _stop) 
		label define _tmgr `=`nbr'-1' "]`prev'; `exit']", add
		label values _tmgr _tmgr

		generate _interval = _stop - _start

		drop if _start == _stop 
		order _id _start _stop _nevents _exgr _tmgr _interval, last 
	}
end
