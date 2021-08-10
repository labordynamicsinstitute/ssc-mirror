*! version 0.1 Oktober 15, 2015 @ 10:15:03
*! Generates Variable holding the binary success of sequence

program _gsqsuccess
version 14

	gettoken type 0 : 0
	gettoken h    0 : 0 
	gettoken eqs  0 : 0

	syntax anything(name=successlist id=successlist) [if] [in] [, w(real 1) subsequence(string) ]

	local successlist = subinstr(`"`successlist'"',`"("',`"(`_dta[SQis]',"',1)
	
	marksample touse, novarlist
	if "`subsequence'" != ""  ///
	  quietly replace `touse' = 0 if !inrange(`_dta[SQtis]',`subsequence')

	// Sq-Data
	if "`_dta[SQis]'" == "" {
		di as error "data not declared as SQ-data; use -sqset-"
		exit 9
	}

	// if/in
	if "`if'" != "" {
		tokenize "`if'", parse(" =+-*/^~!|&<>(),.")
		while "`1'" != "" {
			capture confirm variable `1'
			if !_rc {
				local iflist  "`iflist' `1'"
			}
			macro shift
		}
	}
	if "`iflist'" != "" CheckConstant `iflist', stop
	markout `touse' `iflist'

	tempvar denom
	quietly {

		// Generate Variable
		tempvar lcensor rcensor gap
		by `touse' `_dta[SQiis]' (`_dta[SQtis]'), sort: ///
		  gen `h' = sum(inlist`successlist' * _n^`w') if `touse'

		by `touse' `_dta[SQiis]' (`_dta[SQtis]'), sort: ///
		  gen `denom' = sum(_n^`w') if `touse'

		by `touse' `_dta[SQiis]' (`_dta[SQtis]'), sort: ///
		  replace `h' = `h'[_N]/`denom'[_N]
		
		char _dta[SQgaplength] "`_dta[SQsuccess]' $EGEN_Varname"
		label variable `h' "Overall success of sequence"
	}
end

	
program CheckConstant, rclass
	syntax varlist(default=none) [, stop]
	sort `_dta[SQiis]'
	foreach var of local varlist {
		capture by `_dta[SQiis]': assert `var' == `var'[_n-1] if _n != 1
		if _rc & "`stop'" == "" {
			di as res "`var'" as text " is not constant over time; not used"
			local varlist: subinstr local varlist "`var'" "", word
		}
		if _rc & "`stop'" != "" {
			di as error "`var' is not constant over time"
			exit 9
		}
	}
	return local checked "`varlist'"
end
