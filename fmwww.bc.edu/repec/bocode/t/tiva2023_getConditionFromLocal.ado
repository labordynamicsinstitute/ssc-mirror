capture program drop tiva2023_getConditionFromLocal
program define tiva2023_getConditionFromLocal, rclass
	syntax, input(string) var(string)
	
	local if_input = ""
	foreach i of local input {
		local if_input = trim(`"`if_input'"' + " " +`"`i'"')
		}
	local if_input = `"`var' == ""' + subinstr(`"`if_input'"', " ", `"" | `var' == ""',.) + `"""'
	return local if_`var' = `"`if_input'"'
end

