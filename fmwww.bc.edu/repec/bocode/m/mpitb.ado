*! version 0.1.4   Nicolai Suppa   14 Nov 2022
*! -mpitb- a toolbox for MPIs

capture program drop mpitb
program mpitb , rclass
	version 16
	loc cmdline mpitb 				// similar to -teffects-

	gettoken subcmd rest : 0, parse(" ,")
		loc subcmd = ustrrtrim("`subcmd'")
		*di "subc: .`subcmd'."
		*di "rest: `rest'"
*		di "0: `0'"
*		di "1: `1'"

	if "`subcmd'" == "" {
		di as err "subcommand required; see {helpb mpitb} for more details."
		exit 197
	}

	* retokenize: here or further up?

	* test for valid subcommands 
	local cmdline _mpitb_`subcmd'
	cap findfile `cmdline'.ado
	if _rc {
		di as err "invalid subcommand `subcmd'; see {helpb mpitb} for details."
		exit 197
	}

	* run cmdline
	`cmdline' `rest'

	* returns 
	if (inlist("`subcmd'","ctyselect","assoc")) return add
end

exit
