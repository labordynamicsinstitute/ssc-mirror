*! version 1.0.0  //  Ariel Linden 21May2025 


program define bg2hba1ci, rclass
version 11.0

	syntax anything(id="argument numlist") [, MMOL ]

		numlist "`anything'", min(1) max(1)
		tokenize `anything', parse(" ")

		local bg `1'
		confirm number `bg'

	
		// if bg is in mg/dL
		if "`mmol'" == "" {
			local hba1c_pct = (`bg' + 46.7) / 28.7
			local hba1c_mmol = 10.929 * (`hba1c_pct' - 2.15)			
		}
		// if bg is in mmols 
		else {
			local bg = `bg' * 18.015
			local hba1c_pct = (`bg' + 46.7) / 28.7
			local hba1c_mmol = 10.929 * (`hba1c_pct' - 2.15)	
		}
		
		di _n
		di as txt "   Estimated HbA1c (%): " as result %4.1f `hba1c_pct'
		di as txt "   Estimated HbA1c (mmol/mol): " as result %4.1f `hba1c_mmol'

		// return result
		return scalar hba1c_pct = `hba1c_pct'
		return scalar hba1c_mmol = `hba1c_mmol'		
		
end

