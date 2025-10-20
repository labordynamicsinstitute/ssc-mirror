*! 1.0.0 Ariel Linden 18oct2025

program define rotatesort, rclass
    version 11
    syntax [, FORmat(string) BLanks(real 0) ]

	// Check if e(r_L) exists
	cap mat li e(r_L)
	if _rc {
		di as err "matrix e(r_L) not found. Rerun {bf:rotate}
		exit 198
	}

	// clear and load matrix into dataset
	preserve
	clear
	qui svmat e(r_L), names(col)

	// call mata function to add rownames
	mata: get_rownames("e(r_L)", "rownames")

	// get list of factor columns
	qui ds Factor*
	local cols `r(varlist)'

	// build a gsort option string with - (descending) before each column
	local sortvars
	foreach var of local cols {
		local sortvars `sortvars' -`var'
	}

	// suppress values below threshold
	foreach var of local cols {
		qui replace `var' = . if abs(`var') < `blanks'
	}
	
	// format the factor columns for display
	if "`format'" != "" { 
		confirm numeric format `format' 
		foreach var of local cols {
			format `var' `format'
		}
	}
	else local format %6.3f 


	// sort descending by all columns
	gsort `sortvars'
	rename rownames Variable
	list Variable `cols', noobs divider separator(0) 
	restore
	
end	

version 11.0
mata:
mata clear
void get_rownames(string matrix_name, string varname) {
	real matrix stripe, rownames
	real scalar n, current_obs

	stripe = st_matrixrowstripe(matrix_name)
	rownames = stripe[., 2]
	n = rows(rownames)
	current_obs = st_nobs()

	if (n > current_obs) {
		st_addobs(n - current_obs)
	}
	add = st_addvar("str12", varname)
	for (i = 1; i <= n; i++) {
		st_sstore(i, varname, rownames[i])
	}
}
end