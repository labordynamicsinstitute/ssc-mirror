*!mkheader version 0.2.0
*!Written 12May2017
*!Written by Sergio Venturini and Mehmet Mehmetoglu
*!The following code is distributed under GNU General Public License version 3 (GPL-3)

program mkheader
	version 10
	syntax [, matrix1(string) matrix2(string) DIGits(integer 5) noGRoup ///
		noSTRuctural RAWsum rebus_it(integer -999) rebus_gqi(real 0) ]

	/* Options:
	   --------
		 matrix1(string)						--> matrix containing the model assessment
																		indexes
		 matrix2(string)						--> matrix containing the outer weights maximum
																		relative difference history
		 digits(integer 5)					--> number of digits to display (default 5)
		 nogroup										--> multigroup indicator
		 nostructural								--> indicator of whether the model includes a
																		structural part
		 rawsum											--> scores are raw sum of indicators
		 rebus_it										--> number of REBUS iterations
		 rebus_gqi									--> REBUS group quality index (GQI)
	 */

	local props = e(properties)
	local init : word 1 of `props'
	local wscheme : word 2 of `props'
	local tol = e(tolerance)
	local alllatents = e(lvs)
	local allformative = e(formative)
	local num_lv : word count `alllatents'
	local num_lv_B : word count `allformative'
	local num_lv_A = `num_lv' - `num_lv_B'

	display

	if (`rebus_it' == -999) {
		if ("`group'" == "nogroup") {
			if ("`structural'" == "nostructural") {
				local nobs: display _skip(0) "Partial least squares path modeling" _col(49) ///
					"Number of obs" _col(69) "=" _skip(5) string(e(N))
				display as text "`nobs'"
				
				display

				local init_head: display _skip(0) "Initialization: `init'"
				display as text "`init_head'"
			}
			else {
				if ("`rawsum'" == "") {
					local niter = colsof(`matrix2')
					forvalues i = 1/`niter' {
						local iter_lbl = "Iteration " + string(`i') + ///
							":   outer weights rel. diff. = " + string(`matrix2'[1, `i'], "%9.`digits'e")
						display as text _skip(0) "`iter_lbl'"
					}
					
					display
				}
				
				local nobs: display _skip(0) "Partial least squares path modeling" _col(49) ///
					"Number of obs" _col(69) "=" _skip(5) string(e(N))
				display as text "`nobs'"

				if (`num_lv_A' > 0) {
					local avrsq: display _skip(0) _col(49) "Average R-squared" _col(69) "=" ///
						_skip(5) string(`matrix1'[1, 1], "%9.`digits'f")
					display as text "`avrsq'"
				}
				else {
					display
				}

				if ("`rawsum'" == "") {
					local avave: display _skip(0) "Weighting scheme: `wscheme'" _col(49)
				}
				else {
					local avave: display _skip(0) "Weighting scheme: rawsum" _col(49)
				}
				if (`num_lv_A' > 0) {
					local avave: display "`avave'" "Average communality" _col(69) "=" ///
					_skip(5) string(`matrix1'[1, 2], "%9.`digits'f")
				}
				display as text "`avave'"
				
				if ("`rawsum'" == "") {
					local gof: display _skip(0) "Tolerance: " string(`tol', "%9.`digits'e") ///
						_col(49)
				}
				else {
					local gof: display _skip(0) _col(49)
				}
				if (`num_lv_A' > 0) {
					local gof: display "`gof'" "GoF" _col(69) "=" _skip(5) ///
						string(`matrix1'[1, 3], "%9.`digits'f")
				}
				display as text "`gof'"
				
				if ("`rawsum'" == "") {
					local avred: display _skip(0) "Initialization: `init'" _col(49)
				}
				else {
					local avred: display _skip(0) _col(49)
				}
				if (`num_lv_A' > 0) {
					local avred: display "`avred'" "Average redundancy" _col(69) "=" _skip(5) ///
						string(`matrix1'[1, 4], "%9.`digits'f")
				}
				display as text "`avred'"
			}
		}
		else {
			if ("`structural'" == "nostructural") {
				local title: display _skip(0) "Partial least squares path modeling"
				display as text "`title'"
				
				display

				local initialize: display _skip(0) "Initialization: `init'"
				display as text "`initialize'"
			}
			else {
				local title: display _skip(0) "Partial least squares path modeling"
				display as text "`title'"
				
				display

				if ("`rawsum'" == "") {
					local wgt: display _skip(0) "Weighting scheme: `wscheme'"
					display as text "`wgt'"
					
					local toler: display _skip(0) "Tolerance: " string(`tol', "%9.`digits'e")
					display as text "`toler'"
				}
				
				if ("`rawsum'" == "") {
					local initialize: display _skip(0) "Initialization: `init'"
				}
				else {
					local initialize: display _skip(0)
				}
				display as text "`initialize'"
			}
		}
	}
	else {
		local title: display _skip(0) "Response based unit segmentation (REBUS) solution"
		display as text "`title'"
		
		display

		local wgt: display _skip(0) "Weighting scheme: `wscheme'"
		display as text "`wgt'"
		
		local toler: display _skip(0) "Tolerance: " string(`tol', "%9.`digits'e")
		display as text "`toler'"

		local initialize: display _skip(0) "Initialization: `init'"
		display as text "`initialize'"
		
		local rebit: display _skip(0) "Number of REBUS iterations: `rebus_it'"
		display as text "`rebit'"
		
		local rebgqi: display _skip(0) "Group Quality Index (GQI): " ///
			string(`rebus_gqi', "%9.`digits'f")
		display as text "`rebgqi'"
	}
end
