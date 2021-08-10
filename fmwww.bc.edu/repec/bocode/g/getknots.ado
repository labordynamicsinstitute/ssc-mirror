*! version 1.0.0 MLB 15March2008
program define getknots
	if "`: r(scalars)' `: r(matrices)'" != "N_knots knots" {
		di as err "getknots can only be used after mkspline"
		exit 198
	}
	tempname knotmat
	matrix `knotmat' = r(knots)
	forvalues k = 1/`r(N_knots)' {
		local k = el(`knotmat',1,`k')
		local knots "`knots' `k'"
	}
	local knots : list retokenize knots
	c_local knots "`knots'"
end
