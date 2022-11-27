cap program drop supercompress
cap program drop superdupercompress

program define supercompress

	version 14
	
	

	syntax , TOPlevel(string)
	
	qui global totalsaved__supercomp = 0
	
	superdupercompress, toplevel(`toplevel')
	
	di "supercompress compressed every .dta file it could find within your top path"
	
	di "and its subfolders and saved " $totalsaved__supercomp " bytes in total!"
	
	qui global totalsaved__supercomp

end

program define superdupercompress

	syntax , TOPlevel(string)

	**display the directory name
	di "Compressing all .dta files in `toplevel'..."
	
	**compress all the .dta files in toppath
	local flist: dir "`toplevel'" files "*.dta"
		foreach f of local flist {
		quietly {
			use "`toplevel'/`f'", clear
			memory
			local precompress = r(data_data_u)
			compress
			memory
			local postcompress = r(data_data_u)
		save "`toplevel'/`f'", replace
		local dif = `precompress' - `postcompress'
		global totalsaved__supercomp = $totalsaved__supercomp + `dif'
		}
	}
	
	di "All .dta files in `toplevel' have been compressed!"
	di ""

	** make a list of all the folders within folder_path and run supercompress on them
	local dlist: dir "`toplevel'" dirs "*"
	foreach d of local dlist {
		superdupercompress, toplevel("`toplevel'/`d'")
	}

end

