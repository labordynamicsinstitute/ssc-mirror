*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_assoc
program define _mpitb_assoc , rclass
	* di "mpitb refsh was run!"
	syntax [if] [in] [aw] , [ DEPind(varlist min=2) Name(name)]
		
		if "`depind'" == "" & "`name'" == "" {
			di as err "one of {bf:depind()} and {bf:name()} is needed!"
			e 198
		}
		if "`name'" != "" {
			if "`depind'" != "" {
				di as err "either {bf:depind()} or {bf:name()}!"
				e 198
			}
			else if "`depind'" == "" {
				// test whether spec exists
				loc slist `_dta[MPITB_names]' 
				loc ninslist : list name in slist 
				if `ninslist' == 0 {
					di as err "Specification {bf:`name'} not found!"
					e 198
				}
				loc varlist `_dta[MPITB_`name'_dep_vars]'
				*disp "varlist: `varlist'"
			}
		}
		if "`depind'" != "" {
			loc varlist `depind'
		}


		local Nvar : word count `varlist'
		
		marksample touse 	// account for if, in, mv
	qui {			
		count if `touse' 
		local N = r(N)

		* create matrices
		mat R =J(`Nvar',`Nvar',.)
		mat coln R = `varlist'
		mat rown R = `varlist'
		
		mat CV =J(`Nvar',`Nvar',.)
		mat coln CV = `varlist'
		mat rown CV = `varlist'
		
		mat hd = J(1,`Nvar',.)
		mat rown hd = hd 
		mat coln hd = `varlist' 
		
		tempvar id
		gen `id' = _n

	foreach v1 of varlist `varlist' {

		sum `v1' if `touse' [`weight'`exp'], mean
		mat hd[1, colnumb(hd,"`v1'")] = r(mean)
		
		local resvarlist : subinstr local varlist "`v1'" ""
		
		foreach v2 of varlist `resvarlist' {
		
			* (1) obtain cross-tab freq
			* joint
			sum `id' if `v1' == 1 & `v2' == 1 & `touse' [`weight'`exp'], mean
			local n11 = r(sum_w)	// r(sum_w) is sum of weights: w/o -svy- = raw obs; w -svy- = weighted obs

			*disp as res "`n11'"	// for debug
			sum `id' if `v1' == 0 & `v2' == 0 & `touse' [`weight'`exp'], mean
			local n00 = r(sum_w)

			sum `id' if `v1' == 1 & `v2' == 0 & `touse' [`weight'`exp'], mean
			local n10 = r(sum_w)

			sum `id' if `v1' == 0 & `v2' == 1 & `touse' [`weight'`exp'], mean
			local n01 = r(sum_w)
			
			* marginal
			sum `id' if `v1' == 0 & `touse' [`weight'`exp'], mean
			local n0x = r(sum_w)
			
			sum `id' if `v1' == 1 & `touse' [`weight'`exp'], mean
			local n1x = r(sum_w)

			sum `id' if `v2' == 0 & `touse' [`weight'`exp'], mean
			local nx0 = r(sum_w)

			sum `id' if `v2' == 1 & `touse' [`weight'`exp'], mean
			local nx1 = r(sum_w)
		
			* (2) calc R0
			// test whether one var exhibits 0 dep
			local R = `n11' / min(`nx1',`n1x')

			*disp "R=`R'"
			// store value in matrix
			mat R[rownumb(R,"`v1'"), colnumb(R,"`v2'")] = `R'

			* (3) calc CV
			local CV = (`n00'*`n11' - `n01'*`n10') / sqrt(`n0x'*`n1x'*`nx0'*`nx1')
			*disp "CV=`CV'"
			mat CV[rownumb(CV,"`v1'"), colnumb(CV,"`v2'")] = `CV'
		}
	}
	}
		*mat R = (R,hd)	// add hd to R0
		* display
		
		*_coef_table_header , title(Redundancy Analysis)
		matlist R , format(%9.3f) title("R0-measure")  bor (t)
		matlist hd , format(%9.3f) nam(r) nob bor(t b)
		matlist CV , format(%9.3f) title("Cramer's V") bor(t b)

		disp _n as txt "N=" as res"`N'" 
		if "`exp'"=="" {
			disp as txt "(Note: Observations are not weighted.)"
		}
		else {
			disp as txt "(Note: Observations are weighted with `weight' `exp')."
		}

		* returns
		ret sca N = `N'
		ret mat R0 = R	
		ret mat CV = CV
		ret mat hd = hd 
		
	end

exit
