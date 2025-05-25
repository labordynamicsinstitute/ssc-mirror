*! version 1.0.0  //  Ariel Linden 21May2025 


program define hba1c2bgi, rclass
version 11.0

	syntax anything(id="argument numlist") [, MMOL ]

		numlist "`anything'", min(1) max(1)
		tokenize `anything', parse(" ")

		local a1c `1'
		confirm number `a1c'

	
		// if HbA1c is a percent
		if "`mmol'" == "" {
			local bg_mg = (28.7 * `a1c' - 46.7)
			local bg_mmol = (`bg_mg' / 18.015)
		}
		// if HbA1c is in mmols 
		else {
			local a1cpct = (`a1c' / 10.929) + 2.15
			local bg_mg = (28.7 * `a1cpct' - 46.7)
			local bg_mmol = (`bg_mg' / 18.015)			
			
		}
		
		di _n
		di as txt "   Estimated average blood glucose (mg/dL): " as result %4.1f `bg_mg'
		di as txt "   Estimated average blood glucose (mmol/L): " as result %4.1f `bg_mmol'

		// return result
		return scalar bg_mg = `bg_mg'
		return scalar bg_mmol = `bg_mmol'		
		
end
