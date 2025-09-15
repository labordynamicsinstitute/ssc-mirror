*! version 1.0.0  10sep2025

program flexdid_estat
	version 17.0

	local ZERO `0'

	gettoken subcmd 0 : 0, parse(" ,")
	gettoken subcmd tmp : subcmd, parse(",")
	local len = length(`"`subcmd'"')

	mata: st_global("e(inestat)", "in", "hidden")

	if (`"`subcmd'"' == "atet") flexdid_atet `0'

	else {
			display as error "{bf:estat `subcmd'} not allowed"
			exit 321
	}
 end
