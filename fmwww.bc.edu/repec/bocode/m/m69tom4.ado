program define m69tom4, rclass
    version 11

    syntax varname(numeric), gen(name)

    local main69 `varlist'

    quietly {
        generate `gen' = .

        replace `gen' = 1 if inrange(`main69', 1, 6)
        replace `gen' = 2 if inrange(`main69', 7, 16) | inlist(`main69', 63, 64)
        replace `gen' = 3 if inrange(`main69', 18, 32) | inlist(`main69', 66, 67)
        replace `gen' = 4 if `main69' == 17 | inrange(`main69', 33, 62) | inlist(`main69', 65, 68)
        replace `gen' = . if `main69' == 69

		lab define m4 1"personal" 2"paid" 3"unpaid" 4"leisure", replace
		lab value `gen' m4
	
        label variable `gen' "4-activity code in MTUS"
    }
end
