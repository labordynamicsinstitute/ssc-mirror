*! 1.0.0 Ariel Linden 07Oct2025

program define menger_estat, rclass
    version 11.0

	syntax [, GRaph ]

		local eig e(Ev)  // eigvals 

        // get from e(): eigenvalues ev
        tempname ev
        confirm matrix `eig'
        matrix `ev' = `eig'
		local cmd = e(cmd)
        local k = colsof(`ev')

		tempvar yvar xvar
		quietly gen float `yvar'  = `ev'[1,_n]  in 1/`k'
        quietly gen byte `xvar' = _n in 1/`k'
		
		local ytitle "Eigenvalues"
		if "`cmd'" == "pca" {
			local title "Scree plot of eigenvalues after pca"
		}
		else {
			local title "Scree plot of eigenvalues after factor"			
		}
		qui menger `xvar' `yvar'
		local elbow =  r(elbow)

		if "`graph'" != "" {

			twoway (connected `yvar' `xvar', lwidth(medthick) msymbol(o)) ///
               (scatter `yvar' `xvar' if `xvar'== `elbow', ///
                    msymbol(O) mcolor(red) msize(large) mlabel(`xvar') mlabposition(2) mlabsize(medium)),  ///
					title(`title') ///
					xtitle(Number) ytitle(`ytitle') ///
					legend(off)
		}					
					
		// saved values
		return scalar elbow = `elbow'

end
