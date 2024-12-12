*! 1.0.0 Ariel Linden 05Dec2024

program define mph, rclass

        version 11.0

        /* obtain settings */
        syntax anything , ///
        [ DP(integer -1) ]  

		if ustrpos("`anything'", ":") == 0 | ustrpos("`anything'", ".") > 0 {
			di as err "time must be specified as minutes:seconds (e.g. 6:00)" 
			exit 198
		}

		// parse mpm to extract minutes and seconds
		tokenize `anything', parse(":")
		local min `1'
		macro shift
		local sec `2'

		if `sec' > 59 {
			di as err "seconds cannot be greater than 59"
			exit 198		
		}

		// decimal points
		if `dp' == 0 {
			local mph = round(60/((`min') + (`sec'/60)),1)
			di as txt _n	
			di as txt "Miles Per Hour: " as result %-4.0f `mph'			
		} 
		else if `dp' == 1 | `dp' == -1 {
			local mph = round(60/((`min') + (`sec'/60)),0.1)
			di as txt _n	
			di as txt "Miles Per Hour: " as result %-4.1f `mph'				
		} 
		else if `dp' == 2 {
			local mph = round(60/((`min') + (`sec'/60)),0.01)
			di as txt _n	
			di as txt "Miles Per Hour: " as result %-4.2f `mph'				
		}
		else if `dp' == 3 {
			local mph = round(60/((`min') + (`sec'/60)),0.001)
			di as txt _n	
			di as txt "Miles Per Hour: " as result %-4.3f `mph'				
		} 
		else {
			local mph = (60/((`min') + (`sec'/60)))	
			di as txt _n			
			di as txt "Miles Per Hour: " as result %-12.8f `mph'			
		}	
		
		// Save results
		return scalar mph = `mph'
 	

end