capture program drop tiva2023_MataToLocal
program define tiva2023_MataToLocal, rclass
	syntax, mataElement(string)
	mata: st_matrix("yearMatrix", `mataElement')
	
	local availableYears = ""
	local T = rowsof(yearMatrix)
	forvalues t=1/`T' {
		local yearMatrix_obs = yearMatrix[`t', 1]
		local availableYears = "`availableYears' `yearMatrix_obs'" 
		}

	return local availableYears = `"`availableYears'"'
	
end
