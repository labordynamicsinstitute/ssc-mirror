*! version 1.0.0 02Jun2022 MLB
program define closedesc, rclass
	version 10.1
	syntax varname, [n(integer 3) FORWard BACKWard]
	
	if "`forward'`backward'" == "" {
		local forward "forward"
		local backward "backward"
	}
	if `n' <= 0 {
		di as err "n() must be a positive number"
		exit 198
	}
	
	quietly {
		ds
		local varl = r(varlist)
		local i = 1
		foreach var of local varl {
			if "`var'" == "`varlist'" {
				continue, break
			}
			local `i++'
		}
		local lb = cond("`backward'"=="",`i', max(`i'-`n',1))
		local ub = cond("`forward'"=="", `i', min(`i'+`n', `c(k)'))
		forvalues i = `lb'/`ub' {
			local wanted  "`wanted' `:word `i' of `varl''"
		}
	}
	
	desc `wanted'
	return local varlist `wanted'
end
