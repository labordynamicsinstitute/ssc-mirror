*! Version 1.0 23Jan2025
*! This program is based on a modification of the user-written program 'dropbox'. All credits to their authors, Raymond Hicks and Dustin Tingley.


program define box, rclass
	syntax [, NOCD]

	version 10

	if "`c(os)'" == "Windows" {
		local _db "/Users/`c(username)'"
	}

	if "`c(os)'" ~= "Windows" {
		local _db "~"
	}

	capture local box: dir "`_db'" dir "*Box*", respectcase

	if _rc == 0 & `"`box'"' ~= "" {

		local box: subinstr local box `"""' "", all
		if "`nocd'" == "" {
			cd "`_db'/`box'/"
		}

		return local db "`_db'/`box'/"		
		exit
	}


	if _rc ~= 0 & "`c(os)'" == "Windows" {

		capture cd c:/
		if _rc ~= 0 {
			nois di in red "Cannot find Box folder"
			exit
		}

		capture local box: dir "`_db'" dir "*Box*", respectcase
		if _rc == 0 & `"`box'"' ~= "" {
			local box: subinstr local box `"""' "", all
			if "`nocd'" == "" {
				cd "`_db'/`box'/"
			}
			return local db "`_db'/`box'/"
			exit
		}

		capture local box: dir "/documents and settings/`c(username)'/my documents/" dir "*Box*", 
		if _rc == 0 & `"`box'"' ~= ""{
			local box: subinstr local box `"""' "", all
			if "`nocd'" == "" {
				cd "c:/documents and settings/`c(username)'/my documents/`box'"
			}
			return local db "c:/documents and settings/`c(username)'/my documents/`box'"
			exit
		}

		capture local box: dir "/documents and settings/`c(username)'/documents/" dir "*Box*", 
		if _rc == 0 & `"`box'"' ~= ""{
			local box: subinstr local box `"""' "", all
			if "`nocd'" == "" {
				cd "c:/documents and settings/`c(username)'/documents/`box'"
			}
			return local db "c:/documents and settings/`c(username)'/documents/`box'"
			exit
		}
	}

	if _rc ~= 0 & "`c(os)'" ~= "Windows" {
		nois di in red "Cannot find Box folder"
		exit
	}

	if _rc == 0 & `"`box'"' == "" {
		capture local box: dir "`_db'/Documents" dir "*Box*", respectcase
		if _rc == 0 {
			local doc "Documents"
		}

		if `"`box'"' == "" {
			capture local box: dir "`_db'/My Documents" dir "*Box*", respectcase
			if _rc == 0 {
				local doc "My Documents"
			}
		}

		if `"`box'"' ~= "" {
			local box: subinstr local box `"""' "", all
			if "`nocd'" == "" {
				cd "`_db'/`doc'/`box'/"
			}
			return local db "`_db'/`doc'/`box'/"
			exit
		}

		if `"`box'"' == "" & "`c(os)'" == "Windows" {
			local box: dir "C:/" dir "*Box*", respectcase
			local box: subinstr local box `"""' "", all
			if "`nocd'" == "" {
				cd "/`box'"
			}
			return local db "/`box'"
			exit
		}

		if `"`box'"' == "" & "`c(os)'" ~= "Windows" {
			nois di in red "Cannot find Box folder"
			exit
		}
	}

end