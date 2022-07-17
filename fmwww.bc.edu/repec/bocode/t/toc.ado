*! version 1.0.0  04Jul2022 
capture program drop toc

program define toc
	version 9
	
	** Standardize syntax
	gettoken equal : 0, parse("=")
	if "`equal'" != "=" {
			local 0 `"= 0`0'"'
	}
 
	syntax [= exp] 
	 
	** Retrieve the timer number (default = 100)
	local timer_no `exp'
	if `timer_no' <= 0 {
		local info ""
		local timer_no = 100	
	}
	else {
		local info  " No. `timer_no'"
	}
 
	** Retrieve the second timestamp 
	timer off `timer_no'
	timer on `timer_no'
	qui timer list `timer_no'
	
	** Print out elapsed time
	di as result "Elapsed time: " r(t`timer_no') " sec"
	
	** Structured time information: 
	if r(t`timer_no') > 60 {
		local res_day = floor((r(t`timer_no')) / (60*60*24))
		local res_hrs = floor((r(t`timer_no') - `res_day'*60*60*24) / (60*60))
		local res_min = floor((r(t`timer_no') - `res_day'*60*60*24 - `res_hrs'*60*60) / (60))
		local res_sec = r(t`timer_no') - `res_day'*60*60*24 - `res_hrs'*60*60 - `res_min'*60 
		
		if `res_day' > 0 {
			di as result "             =" `res_day' " d, "	`res_hrs' `" hr, "'	`res_min' " min & "  `res_sec' " sec"
		}		
		else if `res_hrs' > 0 {
			di as result "             =" `res_hrs' `" hr, "'	`res_min' " min & "  `res_sec' " sec"
		}
		else if `res_min' > 0 {
			di as result "             =" `res_min' " min & "  `res_sec' " sec"
		}
	}	
end  