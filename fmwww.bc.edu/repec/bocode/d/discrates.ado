/*Script name: discrates.ado

Purpose of script: Ado to calculate the gross and net discrimination rate for a paired-test correspondence or audit design (application of minority and majority applicant for one offer)"

Author: Andreas Schneck

Date Created: 2022-11-30

Copyright (c) Andreas Schneck, 2022
Email: andreas.schneck@lmu.de
*/

version 10.0

capture program drop discrates
program define discrates, rclass
	syntax varlist (min=2 max=2) [if]
	
	qui tab `varlist' `if' [`exp'], cell matcell(matrix)
	
	local rows = `= rowsof(matrix)'
	local cols = `= colsof(matrix)'
	
	if `rows' !=2 | `cols' != 2 {
	    display as error "error: non-binary variables defined"
		exit
	} 
	
	*Diagonal frquencies for unequal treatment
	local b = matrix[1,2]
	local c = matrix[2,1]
	
	*Mc-Nemar/ Chi2 Test
	local chi2 = (`b'-`c')^2/(`b'+`c')
	local pchi2 = 1-chi2(1,`chi2')
	
	local n = (matrix[1,1]+matrix[1,2]+matrix[2,1]+matrix[2,2])
	local bd = matrix[1,2]/(matrix[1,1]+matrix[1,2]+matrix[2,1]+matrix[2,2])
    local nd = `bd'-(matrix[2,1]/(matrix[1,1]+matrix[1,2]+matrix[2,1]+matrix[2,2]))
	
	*one-sided z-Test
	local se = (`bd'*(1-`bd')/`n')^0.5
	local z = `bd'/`se'
	
	
	*rounding for locals
	local z = round(`z',0.001)
	local pz = round(1-normal(`z'),0.00001)
	local chi2 = round(`chi2', 0.001)
	local pchi2 = round(`pchi2', 0.0001)
	
	local bd = round(`bd'*100,0.001)
	local nd = round(`nd'*100, 0.001)
	
	noisily: tab response_T response_G `if',  cel nokey
	
	di "----------------------------------------------"
	di "Observed units N 	= 	`n'"
	di "----------------------------------------------"
	di "gross discrimination:	`bd'%" 	
	di "		p 	= 	`pz'"
	di "		z 	= 	`z'"
	di "one-sided z-Test H0: 	gross discrimination = 0"
	di "----------------------------------------------"
	di "net discrimination:		`nd'%"
	di "		p 	= 	`pchi2'"
	di "		chi2	= 	`chi2'"	
	di "McNemar-Test H0:		net discrimination = 0"
	di "----------------------------------------------"
	di "----------------------------------------------"

	return scalar bd = `bd'
	return scalar nd = `nd'
	return scalar n = `n'
	end

