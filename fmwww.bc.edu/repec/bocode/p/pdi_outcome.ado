*! version 1.2, Chao Wang, 16/02/2024
*! version 1.1, Chao Wang, 24/05/2023
*! version 1.0, Chao Wang, 25/05/2022
* calculates contribution to polytomous discrimination index (PDI) for a specific level of outcome
* see: Dover, DC, Islam, S, Westerhout, CM, Moore, LE, Kaul, P, Savu, A. Computing the polytomous discrimination index. Statistics in Medicine. 2021; 40: 3667– 3681. https://doi.org/10.1002/sim.8991

program pdi_outcome, rclass

version 16
syntax varlist(min=2 numeric) [if] [in] [, outcome(numlist max=1 integer)]
marksample touse

gettoken depvar indepvar : varlist

* similar to Table 3 in Dover et al. (2021)
tempname pdioutcome
qui tab `indepvar' `depvar' if `touse', matcell(`pdioutcome')
local num_outcomes=colsof(`pdioutcome')

tempname C _tempC _temp
frame create `_tempC'
frame `_tempC' {
	qui set obs 2

	forvalues i=1/`num_outcomes' {
	qui gen c`i'=0 in 1
	qui replace c`i'=1 in 2
	}

	fillin c*
	qui drop if c`outcome'==0
	egen total=rowtotal(c*)
	qui gen weight=1/total
	
	mkmat c* weight, matrix(`C')
	local num_c=colsof(`C')
}

frame create `_temp'
frame `_temp' {
	qui svmat `pdioutcome', names("n")
	
	qui count
	
	forvalues i=1/`num_outcomes' {
		qui gen N`i'=0 in 1
		qui replace N`i'=N`i'[_n-1]+n`i'[_n-1] in 2/`r(N)'
	}
	
	forvalues i=1/`num_c' {
		qui svmat `C', names(col)

		forvalues j=1/`num_outcomes' {
			qui replace c`j'=c`j'[`i']
		}
		qui replace weight=weight[`i']
		
		// calculate the contribution to PDI: weight*(c1*n1+(1-c1)*N1) * (c2*n2+(1-c2)*N2) * ....	
		forvalues j=1/`num_outcomes' {
			qui gen term`j'=c`j'*n`j'+(1-c`j')*N`j'
		}
		
		qui ds weight term*
		local formula=subinstr("`r(varlist)'", " ", "*",.)
		qui gen double contribution=`formula'
			
		qui sum contribution
		capture local contribution=`contribution'+`r(mean)'*`r(N)'
		* for binary outcome contribution=. (since c, weight, term etc=.) for the last i, so 'capture' is required as it would otherwise cause error
		
		drop c* weight term* contribution
	}	
}


tempname freq
qui tab `depvar' if `touse', matcell(`freq')
local combinations=1
forvalues i=1/`num_outcomes' {
	local combinations=`combinations'*`freq'[`i',1]
}

local pdi_outcome=`contribution'/`combinations'

di ""
di as text "The contribution to PDI for outcome level `outcome' is: " as result %5.3f `pdi_outcome'
return scalar pdi_outcome=`pdi_outcome'
end