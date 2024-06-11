*! 1.0.0 NJC 9jun2024 
program myweeks 
	version 8.2 
	syntax varname(numeric) [if] [in] , GENerate(str) [  DOWstart(integer 0) DAILYdate format(str)]
	
	marksample touse 
	qui count if `touse' 
	if r(N) == 0 error 2000 
	
	if !inrange(`dowstart', 0, 6) {
		di as err "{p}dowstart() must offer an integer between 0 (Sunday) and 6 (Saturday){p_end}"
		exit 498
	} 
	
	qui count if `touse' & `varlist' != round(`varlist') 
	if r(N) {
		di as err "{p}non-integers found in what was offered as a daily date variable{p_end}"
		exit 451 
	}
	
	if "`format'" != "" { 
		capture display `format' 0 
		if _rc { 
			di "format `format' appears unsuitable"
			exit 498
		}
	}
	else local format %td
	
	confirm new var `generate'
	
	if "`dailydate'" != "" { 
		gen float `generate' = `varlist' - mod(dow(`varlist') - `dowstart', 7)
		format `generate' `format'
	}
	else { 
		gen float `generate' = floor((`varlist' - mod(`dowstart' + 2, 7)) / 7)
	}
end 
		
	
	
	
	