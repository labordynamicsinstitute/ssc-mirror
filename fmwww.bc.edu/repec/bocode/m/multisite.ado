cap program drop multisite
program define multisite
version 12.0

    local cmd_list multisite_varITT multisite_varLATE multisite_regITT multisite_regLATE
	
	* Install all of the three commands
	foreach p in `cmd_list' {            
		cap which `p'
            if _rc != 0 {
                noi di as text "Installing `p' ..."
                ssc install `p', replace
            }		
	}

end
