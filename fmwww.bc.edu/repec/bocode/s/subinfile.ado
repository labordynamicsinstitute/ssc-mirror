program define subinfile
	version 14.0
	syntax anything(id="file source" name=filesource), ///
	[from(string) to(string) replace save(string) fromregex dropempty index(string) indexregex] 
	if "`replace'" == "" & "`save'" == "" {
		di as error "You must specify at least one of the two options replace or save."
		exit 498
	}
	if `"`from'"' == "" & `"`to'"' != "" {
		di as error "You must specify the substring you want to substitute."
		exit 198
	}
	if `"`index'"' == "" & "`indexregex'" != "" {
		di as error "You must specify the option 'index()' if you want to use regular expression to keep lines."
		exit 198
	}
	if `"`from'"' == "" & "`fromregex'" != "" {
		di as error "You must specify the option 'from()' if you want to use regular expression to subinstitute strings."
		exit 198
	}
	if !fileexists(`"`filesource'"') {
		di as error `"file `filesource' could not be found"'
		exit 601
	}
	
	if `"`save'"' == "" local save `"`filesource'"'
	if index(`"`save'"', ".") == 0 local save `"`save'.txt"'
	if fileexists(`"`save'"') {
		if "`replace'" == "" {
			di as error `"file "`save'" have exsited, you need specify the option replace"'
			error 498
		}
		else if `"`save'"' != `"`filesource'"' {
			if fileexists(`"`save'"') {
				cap erase `"`save'"'
				if _rc != 0 {
					! del `"`save'"' /F
				}
			}
		}
		else {
			local save "subinfile_temp.txt"
			if fileexists("subinfile_temp.txt") {
				cap erase "subinfile_temp.txt"
				if _rc != 0 {
					! del "subinfile_temp.txt" /F
				}
			}
		}
	}	

	qui {
		mata subinfile(`"`filesource'"', `"`index'"', "`indexregex'", `"`from'"', "`fromregex'", `"`to'"', "`dropempty'", `"`save'"')
		if `"`save'"' == "subinfile_temp.txt" {
			cap erase `"`filesource'"'
			if _rc != 0 {
				! del `"`filesource'"' /F
			}
			copy "subinfile_temp.txt" `"`filesource'"', replace
			cap erase "subinfile_temp.txt"
			if _rc != 0 {
				! del "subinfile_temp.txt" /F
			}
		}
	}
end

cap mata mata drop subinfile()
mata
	void function subinfile(string scalar filesource, string scalar index, string scalar indexregex, string scalar from, string scalar fromregex, string scalar to, string scalar dropempty, string scalar save)
	{
		string matrix rewritefile
		real scalar i
		real scalar writefile
		rewritefile = cat(filesource)
		if (index != "") {
			if (indexregex == "indexregex") {
				rewritefile = select(rewritefile, ustrregexm(rewritefile, index))
			}
			else {
				rewritefile = select(rewritefile, ustrpos(rewritefile, index))
			}
		}
		if (from != "") {
			if (fromregex == "fromregex") {
				rewritefile = ustrregexra(rewritefile, from, to)
			}
			else {
				rewritefile = usubinstr(rewritefile, from, to, .)
			}
		}
		if (dropempty != "") {
			rewritefile = select(rewritefile, ustrregexm(rewritefile, "."))
		}
		writefile = fopen(save, "rw")
		for (i = 1; i <= rows(rewritefile); i++) {
			fwrite(writefile, sprintf("%s\r\n", rewritefile[i]))
		}
		fclose(writefile)
	}
end
