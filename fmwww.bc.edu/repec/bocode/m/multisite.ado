cap program drop multisite
program define multisite
version 12.0
    syntax anything [, *]

    local cmd_list multisite_varITT multisite_varLATE multisite_regITT
	
	* Install all of the three commands
	foreach p in `cmd_list' {
            cap which `p'
            if _rc != 0 {
                noi di as text "Installing `p' ..."
                ssc install `p', replace
            }
        }

    }   
end
