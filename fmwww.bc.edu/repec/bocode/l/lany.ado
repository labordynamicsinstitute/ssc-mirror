*! 1.1.0 MLB 06Oct2022
program define lany, sortpreserve
    version 8.1
	syntax [varlist] [if/] , by(varlist) [sort(varlist) *]
	
    if `"`if'"' == "" {
        di as err "{p}an if condition is required{p_end}"
        exit 198
    }
    
    if "`sort'" == ""  {
        tempvar sort
        qui gen double `sort' = _n
    }
    
	// find the ids when at least one if is true
    quietly {
        tempvar mark
        bysort `by' (`sort') : gen `mark' = (`if')
        by     `by'          : replace `mark' = sum(`mark')
        by     `by'          : replace `mark' = `mark'[_N] > 0
    }
		
	// list
	list `varlist' if `mark', `options'

end
