*===================================================================================*
* Ado-file: OneClick Version 4.0 
* Author: Shutter Zor(左祥太)
* Affiliation: School of Accountancy, Wuhan Textile University
* E-mail: Shutter_Z@outlook.com 
* Date: 2022/8/17                                          
*===================================================================================*

capture program drop oneclick
program define oneclick
	version 16.0
	
	syntax varlist(min=3) [if] [in],			///
			Method(string)						///
			Pvalue(real)						///
			FIXvar(varlist)						///
			[									///
				Options(string)					///
				Zvalue							///
			]


	gettoken y ctrlvar : varlist
	gettoken x otherx : fixvar
	
	preserve
		qui gen subset = ""
		qui gen positive = .
		
		* judge osb num
		tuples `ctrlvar'
		local n = _N
		if `ntuples' > `n' {
			qui set obs `ntuples'
		}
		if `ntuples' <= `n' {
			qui set obs `n'
		}
		
		local minutes = int(`ntuples'/60) + 1
		dis "This will probably take you up to `minutes' minutes"
		
		* select
		forvalues i = 1/`ntuples' {
			local percentcurrent = floor(`i' / `ntuples' * 100) 
			dis "`percentcurrent'% calculation has been completed"
			
			quietly {
			
				`method' `y' `fixvar' `tuple`i'', `options'
			
				local distribution_v = _b[`x']/_se[`x']
				if "`zvalue'" == "" & !missing(e(df_r)){
					local pv = 2 * ttail(e(df_r),abs(`distribution_v'))
				}
				if "`zvalue'" != ""{
					local pv = 2 * (1-normal(abs(`distribution_v')))
				}

				local ifsignificant = cond(`pv'<`pvalue',1,0)
				
				replace subset = "`tuple`i''" in `i' if `ifsignificant'
				replace positive = 1 if `ifsignificant' & `distribution_v'>0
				replace positive = 0 if `ifsignificant' & `distribution_v'<0
			}
		}
		
		* drop 
		quietly {
			drop if subset == ""
			keep subset positive
			save subset.dta, replace
			
			local totalNum = _N 
			sum positive if positive == 1
			local positiveNum = r(N)
			sum positive if positive == 0
			local negativeNum = r(N)
		}
			
		dis "A total of `totalNum' significant groups: `positiveNum' positive, `negativeNum' negative"
	restore
end


