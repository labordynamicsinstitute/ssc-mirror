*! 1.0.0 Ariel Linden 06Dec2024

program define mpm, rclass

        version 11.0

        /* obtain settings */
        syntax anything 


		numlist "`anything'", min(1) max(1)
		
		// convert MPH to a time
		local time = 60 / `anything'

		// parse out the minutes
		tokenize `time', parse(".")
		local min `1'
		macro shift
		local sec `2'
		
		// parse out and convert seconds
		tokenize `sec', parse(".")
		local sec `1'
		local newsec = ceil(.`sec' * 60)

		// add ":00"
		if `newsec' == . {
			local mpm `min':00
		}
		else {
			local mpm `min':`newsec'
		}

		// show result
		di as txt _n
		di as txt "Minutes Per Mile: {bf:`mpm'}"
		
		// save result
		return local mpm `mpm'
		
end		