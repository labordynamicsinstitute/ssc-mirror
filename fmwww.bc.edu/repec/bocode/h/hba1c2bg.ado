*! version 1.0.0  //  Ariel Linden 21May2025 


program define hba1c2bg, rclass
version 11.0

	syntax varlist(max=1 numeric) [, MMOL REplace]
	
		
		// drop existing variables 
		if "`replace'" != "" {
			local list bg_mg bg_mmol
			foreach v of local list {
				capture confirm variable `v'
				if !_rc {
					drop `v'
				}
			}
		}
		
		// if HbA1c is a percent
		if "`mmol'" == "" {
			generate double bg_mg = (28.7 * `varlist' - 46.7)
			label var bg_mg "Estimated average blood glucose (mg/dL)"		
			generate double bg_mmol = (bg_mg / 18.015)	
			label var bg_mmol "Estimated average blood glucose (mmol/L)"
		}
		// if HbA1c is in mmols 
		else {
			tempvar a1cpct
			gen `a1cpct' = (`varlist' / 10.929) + 2.15
			generate double bg_mg = (28.7 * `a1cpct' - 46.7)
			label var bg_mg "Estimated average blood glucose (mg/dL)"	
			generate double bg_mmol = (bg_mg / 18.015)	
			label var bg_mmol "Estimated average blood glucose (mmol/L)"			
		}
		// format for viewing
		format %5.1f bg_mg bg_mmol
end

