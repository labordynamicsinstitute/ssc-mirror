capture program drop tiva2023_getPath
program define tiva2023_getPath, rclass
	syntax, [path(string)]
	// First I check path 
	if (`"`path'"' == "") {
		local path = c(pwd)
		}
	local path = subinstr(`"`path'"', "\","/",.)
	if !regexm(`"`path'"', "(\\$)|(/$)") {
		local path = `"`path'"' + "/"
		}
	return local path = `"`path'"'
end

