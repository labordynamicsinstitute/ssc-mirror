*! version 1.2.0  18sep2024  hendri.adriaens@centerdata.nl
program define docd
	version 17

	gettoken path 0 : 0
	splitpath "`path'"

	local current "`c(pwd)'"
	local isAbsolute = substr(trim("`path'"), 2, 1) == ":"
	if `isAbsolute' {
		local fullpath = "`path'"
	}
	else {
		local fullpath = subinstr("`current'/`path'", "\", "/", .)
	}
	
	// Change the working directory to the path of the do-file
	capture cd "`r(directory)'"
	if _rc != 0 {
		display as error `"error changing directory to "`r(directory)'""'
		exit _rc
	}
	
	// We want to be able to restore the working directory at
	// the end of the program, even if an error occurs. So we
	// need to capture the error, but that also stops output
	// to the screen, which we need to turn on using "noisily".
	capture noisily do "`r(filename)'" `0'

	// Remember the error
	local error = _rc

	// Restore the working directory
	capture cd "`current'"

	// Exit in case the do-file produced an error
	if `error' != 0 {
		disp as error "error in '`fullpath''"
		exit `error'
	}

end
