*! version 1.0, Chao Wang, 25/05/2022
* calculates polytomous discrimination index (PDI)
* see: Dover, DC, Islam, S, Westerhout, CM, Moore, LE, Kaul, P, Savu, A. Computing the polytomous discrimination index. Statistics in Medicine. 2021; 40: 3667– 3681. https://doi.org/10.1002/sim.8991

program pdi, rclass

version 16
syntax varlist(min=2 numeric) [if] [in]
marksample touse

gettoken depvar indepvar : varlist
local varnum: word count `indepvar'

tempname result
matrix `result'=J(`varnum',1,.)
matrix rownames `result'=`indepvar'
matrix colnames `result'="PDI #"

local pdi=0
forvalues i = 1/`varnum' {
	local var: word `i' of `indepvar'
	qui pdi_outcome `depvar' `var' if `touse', outcome(`i')
	matrix `result'[`i',1]=r(pdi_outcome)
	local pdi=`pdi'+`r(pdi_outcome)'
}

local pdi=`pdi'/`varnum'

di "The overall polytomous discrimination index (PDI) is: " as result %5.3f `pdi'
return scalar pdi=`pdi'

di ""
di "PDI for each outcome:"
local seps: di _dup(`varnum') "&"
matlist `result', cspec(& %6s | %9.3g o2&) rspec(&-`seps')

return matrix result `result'

end