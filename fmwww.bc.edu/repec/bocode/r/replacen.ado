*! version 1.0.0  16feb2023  hendri.adriaens@centerdata.nl
program define replacen
	version 17
	gettoken n 0 : 0
	display "`n'"
	gettoken vname : 0
	display "`vname'"
	tempvar old
	quietly clonevar `old' = `vname'
	replace `0'
	quietly count if `vname' != `old'
	if r(N) != `n' {
		display as error "the conditions resulted in `r(N)' replacements instead of the requested `n' replacements"
		exit 31415
	}
end
