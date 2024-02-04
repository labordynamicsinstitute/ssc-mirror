*! Version 1.0 1Feb2024
	
* Define the program
program define ilr

	version 10

    syntax varlist(min=3) // Ensures at least three variables are provided

    tempname sumvar
    gen `sumvar' = 0

    foreach var of varlist `varlist' {
		
        quietly replace `sumvar' = `sumvar' + `var'
    
	}

    * Check the standard deviation of the new sum variable
	qui summarize `sumvar', detail
    local sd = r(sd)

	if round(`sd', 0.0001) == 0.0000 {


		************************
		*Create order variables*
		************************

		* Get the number of variables
		local numvars : word count `varlist'

		* Initialize a local macro to store the reordered list
		local neworder

		* Loop over the number of variables to cycle the first variable
		forval i = 1/`numvars' {

			* Clear the neworder macro
			local neworder ""

			* Make the ith variable the first in the list
			local neworder "`: word `i' of `varlist''"

			* Append the remaining variables, skipping the one that's now first
			forval j = 1/`numvars' {

				if `j' != `i' {

					local neworder "`neworder' `: word `j' of `varlist''"

				}

			}

			* Order the variables according to neworder
			order `neworder'


			*****
			*ILR*
			*****

			* Get the number of variables
			local numvars_ilr : word count `neworder'

			* Start the loop to compute ilr components
			forval k = 1/`=`numvars_ilr' - 1' {

				* Create a temporary variable for the product of x[j] for j = i+1 to D
				local prodvarname prod`k'

				gen `prodvarname' = 1

				forval z = `=`k'+1'/`numvars_ilr' {

					quietly replace `prodvarname' = `prodvarname' * `: word `z' of `neworder''

				}

				* Compute the k-th component of the ilr transformation
				gen `: word 1 of `neworder''_ilr`k' = (sqrt((`numvars_ilr'-`k')/(`numvars_ilr'-`k'+1))) * (ln((`: word `k' of `neworder'' / ((`prodvarname')^(1/(`numvars_ilr'-`k'))))))
				drop `prodvarname'
				
			}

		}
		
		* Display a message
		display "Isometric log-ratio transformation (ilr) completed."

	}

	else {

		* Exit the program if the standard deviation is not zero
        display "The components do not add up to the same number (at 0.0001 precision level). The programme will not continue."
        exit 198 
    }

	drop `sumvar'

end