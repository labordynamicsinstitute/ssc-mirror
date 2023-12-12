capture program drop tiva2023_checkTivaFiles
program define tiva2023_checkTivaFiles, rclass
version 15.0
	syntax namelist(max=1 name=type id="Type of files to check"), [path(string)]

	tiva2023_getPath, path(`"`path'"')
	local path = `"`r(path)'"'

	// I check the existences of the .mmat files.
	if (`"`type'"' == "mmatFiles") {
		local exist_AllmmatFiles = 1
		local mmatFiles : dir `"`path'"' files "*.mmat"
		local required_mmatFiles = "_dimensions.mmat _descriptions.mmat _icio.mmat _transitions.mmat _ew_multiplications.mmat"
		foreach r_mmatF of local required_mmatFiles {
			local exist_mmatFile = 0
			foreach mmatF of local mmatFiles {
				if regexm(lower(`"`mmatF'"'), lower(`"`r_mmatF'"')) {
					local exist_mmatFile = 1
					display as text "`mmatF' found."
					}
				}
				if `exist_mmatFile' == 0 local exist_AllmmatFiles = 0
			}
			return local exist_AllmmatFiles = `exist_AllmmatFiles'
		}

	// Check the existence of the zipfiles.
	else if (`"`type'"' == "csvFiles") {
		local availableYears = ""
		local csvFiles : dir `"`path'"' files "????.csv"
		display `"`csvFiles'"'
		foreach csvf of local csvFiles {
			local yyyy = substr(`"`csvf'"', 1, 4)
			local availableYears = `"`availableYears'"' + `"`yyyy' "'
			}
		if `"`availableYears'"' != "" {
			display as text "ICIO matrices were found for the following years: `availableYears'"
			}
		else {
			display as error "No ICIO found, make sure you did not rename them, the name should be: ICIO2023_YYYY.zip. Also, make sure you mentioned the correct path in the option."
			err 601
			}
		
		return local availableYears = trim(`"`availableYears'"')
		}
	
end

