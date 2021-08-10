*! Part of package matrixtools v. 0.27
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2021-01-29 option label and extend added

program define strtonum
	version 12.1
	syntax varlist(min=1) [, Base(integer 1) Keep Label(string) Extend]

	quietly {
		foreach vn of varlist `varlist' {
			mata st_local("__is_string", strofreal(st_isstrvar("`vn'")))
			if `__is_string' {
				capture drop __`vn'
				rename `vn' __`vn'
                if "`label '" == "" {
                    levelsof __`vn', local(__tmp)
                    generate `vn' = .
                    local nbr `base'
                    foreach txt in `__tmp' {
                        local __lbl_values `"`__lbl_values' `nbr' `"`txt'"'"'
                        replace `vn' = `nbr++' if __`vn' == `"`txt'"'
                    }
                    label variable `vn' "`: variable label __`vn''"
                    label define `vn' `__lbl_values', replace
                    label values `vn' `vn'                	
                }
                else {
                	if "`extend'" == "" local extend noextend
                    else local extend ""
                	encode __`vn', generate(`vn') label(`label') `extend' 
                }
				order `vn', before(__`vn')
				if "`keep'" == "" drop __`vn'
			}
			else noisily display "{error:`vn' is not a string variable}"
		}
		macro drop __*
	}
end
