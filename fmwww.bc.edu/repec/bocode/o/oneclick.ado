*===================================================================================*
* Ado-file: OneClick Version 5
* Author: Shutter Zor(左祥太)
* Affiliation: School of Accountancy, Wuhan Textile University
* E-mail: Shutter_Z@outlook.com 
* Date: 2023/3/4
* Update: drop tuples command and set a new method to select subsets                                          
*===================================================================================*

*- Decimal-to-Binary function
capture program drop bin_transfer
program define bin_transfer, rclass
	version 14
	args dec_num
	local bin_num ""
	local remainder 0
	while `dec_num' > 0 {
		local remainder = mod(`dec_num', 2)
		local bin_num "`remainder'`bin_num'"
		local dec_num = floor(`dec_num'/2)
	}
	return local binary "`bin_num'"
end

*- Main function
capture program drop oneclick
program define oneclick
	version 14
	
	syntax varlist(min=3 fv ts),			    ///
			Method(string)						///
			Pvalue(real)						///
			FIXvar(varlist fv ts)				///
			[									///
				Options(string)					///
				Zvalue							///
			]


	gettoken y ctrlvar : varlist
	gettoken x otherx : fixvar
	tokenize "`ctrlvar'"
	
	preserve
		qui gen subset = ""
		qui gen positive = .
		
		* computer combination
		local CtrlLen = wordcount("`ctrlvar'")
		local temp = ustrregexra("`ctrlvar'"," ","")
		local Lenth = 2^`CtrlLen'
		forvalues i = 1/`Lenth' {
			local Combo ""
			bin_transfer `i'
			forvalues j = 1/`CtrlLen' {
				if substr(r(binary),-`j',1) == "1" {
					local addword "``j''"
					local Combo "`Combo' `addword'"
				}
			}
			local Combo`i' = "`Combo'"
		}
		
		*- set obs num
		local n = _N
		if `Lenth' > `n' {
			qui set obs `Lenth'
		}
		if `Lenth' <= `n' {
			qui set obs `n'
		}
		
		local minutes = int(`Lenth'/300) + 1
		dis "This will probably take you up to `minutes' minutes"
		dis _newline(1) "The program is working:"
		
		* select
		timer clear 1
		timer on 1
		forvalues i = 1/`Lenth' {
			_dots `dotDisplay' 0

			quietly {
			
				`method' `y' `fixvar' `Combo`i'', `options'
			
				local distribution_v = _b[`x']/_se[`x']
				if "`zvalue'" == "" & !missing(e(df_r)){
					local pv = 2 * ttail(e(df_r),abs(`distribution_v'))
				}
				if "`zvalue'" != ""{
					local pv = 2 * (1-normal(abs(`distribution_v')))
				}

				local ifsignificant = cond(`pv'<`pvalue',1,0)
				
				replace subset = "`Combo`i''" in `i' if `ifsignificant'
				replace positive = 1 in `i' if `ifsignificant' & `distribution_v'>0
				replace positive = 0 in `i' if `ifsignificant' & `distribution_v'<0
			}
			
			local dotDisplay = `dotDisplay' + 1
		}
		timer off 1
		qui timer list 1
		dis _newline "Time=" r(t1) "S"
		
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
			
		dis _newline(1) "A total of `totalNum' significant groups: `positiveNum' positive, `negativeNum' negative"
	restore
end


