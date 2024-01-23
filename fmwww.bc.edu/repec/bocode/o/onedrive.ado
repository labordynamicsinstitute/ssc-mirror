program define onedrive, rclass
	syntax

*! First written 22/01/2024
*! Version 1.0 (22/01/2024)
*! Based on the user-written program 'dropbox'. All credits to their authors, Raymond Hicks and Dustin Tingley.

version 14

	if "`c(os)'" == "Windows" {
		local _db "/Users/`c(username)'"
	}

	if "`c(os)'" ~= "Windows" {
		local _db "~"
	}

	capture local onedrive: dir "`_db'" dir "*OneDrive*", respectcase

	if _rc == 0 & `"`onedrive'"' ~= "" {

		local onedrive: subinstr local onedrive `"""' "", all
		if "`nocd'" == "" {
			cd "`_db'/`onedrive'/"
		}

		return local db "`_db'/`onedrive'/"		
		exit
	}


	if _rc ~= 0 & "`c(os)'" == "Windows" {

		capture cd c:/
		if _rc ~= 0 {
			nois di in red "Cannot find Onedrive folder"
			exit
		}

		capture local onedrive: dir "`_db'" dir "*OneDrive*", respectcase
		if _rc == 0 & `"`onedrive'"' ~= "" {
			local onedrive: subinstr local onedrive `"""' "", all
			if "`nocd'" == "" {
				cd "`_db'/`onedrive'/"
			}
			return local db "`_db'/`onedrive'/"
			exit
		}

		capture local onedrive: dir "/documents and settings/`c(username)'/my documents/" dir "*onedrive*", 
		if _rc == 0 & `"`onedrive'"' ~= ""{
			local onedrive: subinstr local onedrive `"""' "", all
			if "`nocd'" == "" {
				cd "c:/documents and settings/`c(username)'/my documents/`onedrive'"
			}
			return local db "c:/documents and settings/`c(username)'/my documents/`onedrive'"
			exit
		}

		capture local onedrive: dir "/documents and settings/`c(username)'/documents/" dir "*onedrive*", 
		if _rc == 0 & `"`onedrive'"' ~= ""{
			local onedrive: subinstr local onedrive `"""' "", all
			if "`nocd'" == "" {
				cd "c:/documents and settings/`c(username)'/documents/`onedrive'"
			}
			return local db "c:/documents and settings/`c(username)'/documents/`onedrive'"
			exit
		}
	}

	if _rc ~= 0 & "`c(os)'" ~= "Windows" {
		nois di in red "Cannot find onedrive folder"
		exit
	}

	if _rc == 0 & `"`onedrive'"' == "" {
		capture local onedrive: dir "`_db'/Documents" dir "*OneDrive*", respectcase
		if _rc == 0 {
			local doc "Documents"
		}

		if `"`onedrive'"' == "" {
			capture local onedrive: dir "`_db'/My Documents" dir "*OneDrive*", respectcase
			if _rc == 0 {
				local doc "My Documents"
			}
		}

		if `"`onedrive'"' ~= "" {
			local onedrive: subinstr local onedrive `"""' "", all
			if "`nocd'" == "" {
				cd "`_db'/`doc'/`onedrive'/"
			}
			return local db "`_db'/`doc'/`onedrive'/"
			exit
		}

		if `"`onedrive'"' == "" & "`c(os)'" == "Windows" {
			local onedrive: dir "C:/" dir "*OneDrive*", respectcase
			local onedrive: subinstr local onedrive `"""' "", all
			if "`nocd'" == "" {
				cd "/`onedrive'"
			}
			return local db "/`onedrive'"
			exit
		}

		if `"`onedrive'"' == "" & "`c(os)'" ~= "Windows" {
			nois di in red "Cannot find Onedrive folder"
			exit
		}
	}

end