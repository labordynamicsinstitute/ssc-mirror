*! version 1.0.0  10Sep2019
capture program drop _ftruncreg_p
program define _ftruncreg_p, nclass
	version 11
	syntax newvarname [if] [in] , [ xb ]
	marksample touse, novarlist
	local case : word count `xb'
	if `case' >1 {
		display "{err}only one statistic may be specified"
	exit 498 
	}
	if `case' == 0 {
		local n n
		display "expected xb"
	}
	if "`xb'" != "" {
		_predict `typlist' `varlist' if `touse'
	}
end
