*===================================================================================*
* Ado-file: OneClick Version 3.2 
* Author: Shutter Zor(左祥太)
* Affiliation: School of Accountancy, Wuhan Textile University
* E-mail: Shutter_Z@outlook.com 
* Date: 2022/5/2                                          
*===================================================================================*
capture program drop oneclick
program define oneclick
	version 16.0
	
	syntax varlist(numeric min=2) [if] [in] ,	///
			DEPendentvariable(varname)			///
			INDependentvariable(varname)		///
			Significance(real)					///
			Method(string)						///
			[ 									///
				Robust							///
				CLuster(varname)				///
			]
	
	preserve
		quietly{
			gen degreeOfFreedom = .
			gen tValue = .
			gen bOfIndX = .
			gen seOfIndX = .
			gen tOfIndX = .
			gen rSq = .
			gen subSet = ""	
			gen count = wordcount("`varlist'")
			gen obs = 2^count - 1
			sum obs
		}

		if _N > r(max){
		tuples `varlist'
		forvalues i = 1/`ntuples' {
			quietly{
				`method' `dependentvariable' `independentvariable' `tuple`i'', `robust' `cluster'
				
				replace bOfIndX = _b["`independentvariable'"] in `i'
				replace seOfIndX = _se["`independentvariable'"] in `i'
				replace tOfIndX = bOfIndX / seOfIndX in `i'
				replace degreeOfFreedom = e(df_r) in `i'	
				replace tValue = invttail(degreeOfFreedom, `significance') in `i'
				replace rSq = e(r2) in `i'
				replace subSet = "`tuple`i''" in `i'
			}

	}

		quietly{
			gen abstOfIndX = abs(tOfIndX)
			gen abstValue = abs(tValue)
			keep if abstOfIndX > abstValue
			gen controlVariableNumbers = wordcount(subSet) if subSet != ""
			sort controlVariableNumbers rSq 
			keep if rSq != .
		}
		
		list subSet
		keep bOfIndX seOfIndX tOfIndX rSq
		save subset.dta, replace
		}
		
		else{
			set obs `r(max)'
			tuples `varlist'
			forvalues i = 1/`ntuples' {
				quietly{
					`method' `dependentvariable' `independentvariable' `tuple`i'', `robust' `cluster'
					
					replace bOfIndX = _b["`independentvariable'"] in `i'
					replace seOfIndX = _se["`independentvariable'"] in `i'
					replace tOfIndX = bOfIndX / seOfIndX in `i'
					replace degreeOfFreedom = e(df_r) in `i'	
					replace tValue = invttail(degreeOfFreedom, `significance') in `i'
					replace rSq = e(r2) in `i'
					replace subSet = "`tuple`i''" in `i'
				}
		}
			quietly{
				gen abstOfIndX = abs(tOfIndX)
				gen abstValue = abs(tValue)
				keep if abstOfIndX > abstValue
				gen controlVariableNumbers = wordcount(subSet) if subSet != ""
				sort controlVariableNumbers rSq 
				keep if rSq != .
			}
			
			list subSet
			keep subSet bOfIndX seOfIndX tOfIndX rSq
			order subSet bOfIndX seOfIndX tOfIndX rSq
			save subset.dta, replace
		}			
	restore
end