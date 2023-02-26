*! version 1.0.0
cap program drop eacf
program define eacf, rclass
	version 15
	syntax varname(ts) [if] [in] [,ar(integer 7) ma(integer 13)]

	preserve
	marksample touse
	_ts tvar panelvar `if' `in', sort onepanel
	markout `touse' `tvar'
	quietly keep if `touse'
	
	tempvar zVar zVarMean
	// Demean time-series
	// DEMEAN is required indirectly to get the same result as that in the paper
	egen double `zVarMean' = mean(`varlist')
	gen double `zVar' = `varlist' - `zVarMean'

	local nrow = `ar' + `ma' + 1
	// NOT ar , because of the nature of using EQ.<2.7> in the paper
	// The reason is explained below

	// Calculate AR(k) coefficients Whose MA = 0
	matrix coefficients = J(`nrow',`nrow',0)
	forval ar_order = 1/`nrow' {
		quietly reg `zVar' L(1/`ar_order').`zVar', nocons
		matrix matret = e(b)
		matrix coefficients[`ar_order',1] = matret[1,1..`ar_order']
	}
	
	// Turn data to matrix, for MATA usage
	mkmat `zVar',matrix(z_matrix)
	restore
	// MATA calculation of EACF
	mata: eacf_calculate("z_matrix","coefficients",`ar',`ma')
	
	// Return key results
	return matrix seacf = seacf
	return matrix symbol = symbol
end