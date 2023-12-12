capture program drop tiva2023_store
program define tiva2023_store
	syntax anything, [clear] [indicator(string) cou(string) ind(string)]
	
	if `"`anything'"' == "init" {

		capture sysuse cancer 
		if _rc == 4 & `"`clear'"' == "" error 4
		else {
			mata: data._initStorage()
			destring year, replace
			}
		}

	else if `"`anything'"' == "indicator" {
		mata: data._storeIndicator(`"`indicator'"', result)
		}
	
	else if `"`anything'"' == "keep" {
		quietly {
			if `"`cou'"' != "" {
				local cou = upper(`"`cou'"')
				tiva2021_getConditionFromLocal, input(`"`cou'"') var(cou)
				replace toKeep = . if !(`r(if_cou)')
				}
			
			if `"`ind'"' != "" {
				tiva2021_getConditionFromLocal, input(`"`ind'"') var(ind)
				/* local if_ind = `"`r(if_ind)'"' */
				/* display `"`if_ind'"' */
				replace toKeep = . if !(`r(if_ind)')
				}
			
			keep if toKeep == 1
			drop toKeep
			}
		
		}
end



