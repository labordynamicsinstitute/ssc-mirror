*! Version 1.0 (1 Feb 2024)
	
* Define the compreg program
program define compreg

version 10

	syntax varlist, comp(varlist min=3) [ilr] [, *]

    * Assign the dependent (base) variable for regression
    local num_comp : word count `comp'

   	* Perform ILR transformation on the variable
	ilr `comp'

	* Construct ILR variable names for the regression
	foreach vars in `comp' {

		local ilrnames_`vars'

		forval j = 1 / `=`num_comp' - 1' {

			local ilrnames_`vars' "`ilrnames_`vars'' `vars'_ilr`j'"

		}

		*Run regression
		reg `varlist' `ilrnames_`vars'', `options'

		*Drop ILR variables if [ilr] is not selected
		if "`ilr'" == "" {

			drop `ilrnames_`vars''

		}

	}
end