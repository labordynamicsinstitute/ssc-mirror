*! version 1.0.0  04Jul2022 
capture program drop tic

program define tic
	version 9
	
	** Standardize syntax	
	gettoken equal : 0, parse("=")
	if "`equal'" != "=" {
			local 0 `"= 0`0'"'
	}
 	
	syntax [= exp], [Pause Resume]

	** Retrieve the timer number (default = 100)
	local timer_no `exp'
	if `timer_no' <= 0 {
		local info ""
		local timer_no = 100
	}
	else {
		local info  " No. `timer_no'"
	}

	** Start the time & retrieve the first timestamp (if not pausing/resuming)
	if "`resume'"=="" & "`pause'"=="" {
		timer clear `timer_no'
		di as text "Timer`info' is turned on!"
			timer on `timer_no'
	}
	else {
		** Pausing	
		if "`pause'"!="" {
			di as text "Timer`info' is paused!"
			timer off `timer_no'
		}
	 
		** Resuming	
		if "`resume'"!="" {
			di as text "Timer`info' is resumed!"
			timer on `timer_no'
		}
	}

	
end

 
  