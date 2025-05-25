*! version 1.0.0  //  Ariel Linden 21May2025 


program define bg2hba1c, rclass
version 11.0

	syntax varlist(max=1 numeric) [, MMOL REplace]
	
		// drop existing variables 
		if "`replace'" != "" {
			local list hba1c_pct hba1c_mmol
			foreach v of local list {
				capture confirm variable `v'
				if !_rc {
					drop `v'
				}
			}
		}
		
		// if bg is mg/dL
		if "`mmol'" == "" {
			generate double hba1c_pct = (`varlist' + 46.7) / 28.7
			label var hba1c_pct "Estimated HbA1c (%)"		
			generate double hba1c_mmol = 10.929 * (hba1c_pct - 2.15)
			label var hba1c_mmol "Estimated HbA1c (mmol/mol)"
		}
		// if bg is in mmols 
		else {
			tempvar bg
			gen `bg' = `varlist' * 18.015
			generate double hba1c_pct = (`bg' + 46.7) / 28.7
			label var hba1c_pct "Estimated HbA1c (%)"		
			generate double hba1c_mmol = 10.929 * (hba1c_pct - 2.15)	
			label var hba1c_mmol "Estimated HbA1c (mmol/mol)"		
		}
		// format for viewing
		format %5.1f hba1c_pct hba1c_mmol
end
