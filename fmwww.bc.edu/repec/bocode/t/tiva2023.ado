capture program drop tiva2023
program define tiva2023, nclass
version 15.0
	syntax namelist(max=1 name=opt id="Options list") [, path(string) indicator(string) year(numlist) cou(string) par(string) ind(string) clear]

	if `"`cou'"' != "" local cou = upper(`"`cou'"')
	
	tiva2023_getPath, path(`"`path'"')
	local path = `"`r(path)'"'
	
	tiva2023_checkTivaFiles mmatFiles, path(`"`path'"')
	if `r(exist_AllmmatFiles)' == 1 display as text "Matrices were found."
	
	else {

		display as text "No TiVA matrix found: importing data from csv files."
		
		tiva2023_checkTivaFiles csvFiles, path(`"`path'"')
		local availableYears = "`r(availableYears)'"
		
		tiva2023_getTivaFiles, path(`"`path'"') years(`"`availableYears'"')

		}
	
	if (`"`opt'"' == "load") {

		mata: data = tiva2023()
		mata: data.path = `"`path'"'
		mata: data.importMatrices(`"`path'"')
		
		tiva2023_MataToLocal, mataElement(data.year)
		local availableYears = `"`r(availableYears)'"'
		display `"`availableYears'"'
		
		display "Loading TiVA matrices into mata"
		mata: data.load(`"`path'"')
	
		if (`"`indicator'"' != "") {
			display as text "You typed 'load' with 'indicator' option."
			display as text "'load' only loads TiVA matrices into Stata, you can check it by typing 'mata: mata describe'."
			display as text "To calculate indicators please use option 'calc'."
			}
		}
	
	else if (`"`opt'"' == "calc") {

		// choose class to initialize
		
		if regexm(`"`indicator'"', "MY") mata: data = tiva2023_MYindicators()
		else if regexm(`"`indicator'"', "OECD") mata: data = tiva2023_oecdindicators()
		else if regexm(`"`indicator'"', "UV_") mata: data = tiva2023_UpDOwnIndicators()
		else mata: data = tiva2023_commonICIO()

		mata: data._checkClear(`"`clear'"') 		// before any calculation, check clear 

		// import data
		
		mata: data.path = `"`path'"'
		mata: data.importMatrices(`"`path'"')
		tiva2023_MataToLocal, mataElement(data.year)
		local availableYears = `"`r(availableYears)'"'
		display `"available years: `availableYears'"'

		// for which year should the indicator be calculated?
		if (`"`year'"' == "") local year = `"`availableYears'"' 		// if year option not mentioned, then I calculate for all years

		// Calculate and store!
		
		local database_initialised = 0 
		foreach idc of local indicator {
			local var_alreadyAdded = 0
			foreach yyyy of local year {

				display as text "~ Calculating `idc' for `yyyy'"
				
				mata: data.result = data.`idc'(`yyyy', `"`cou'"', `"`par'"') // calculate

				mata: data.result = data.hN_to_N(data.result) // into right dimension (sum values for heterogeneous countries such as MEX and CHN).

				if `database_initialised++' == 0 mata: data._initStorage(data.result)
				if `var_alreadyAdded++' == 0 mata: indicator_name = data._storeIndicator(`"`idc'"', data.result, `"`par'"')
				mata: data._storeResult(indicator_name, data.result, `yyyy', `"`cou'"')
				}
			}

		keep if toKeep == 1
		drop toKeep 
		}

end

