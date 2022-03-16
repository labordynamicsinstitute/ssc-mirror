*! 1.1.0 MBH 12 March 2022
*!   --including corrections for Windows
*! 1.0.0 MBH 30 December 2021


program define inshell, rclass
version 10.0
syntax anything (everything equalok)

tempfile stdout stderr rc
tempname out err c

// Send commands to the shell via one of two methods; one for Windows, one for all other (UNIX-like) OSes
if c(os)!="Windows"{
	if "$S_SHELL"!=""{
		di as error "global variable S_SHELL is set. This is not recommended. See 'Technical note' on page 793 of the pdf Stata manual"
	}
	! `macval(anything)' 2> `stderr' 1> `stdout' || echo $? > `rc'
}

if c(os)=="Windows"{
	if "`c(mode)'"=="batch" {
		display as error "inshell will not function in batch mode on Windows. This is a Stata limitation."
		exit 1
	}
	// using a tempfile for the .bat command does not work for some reason
	local bat "`c(tmpdir)'inshell.bat"     // cf. help creturn##directories
	capture quietly erase "`bat'"
	tempname batf
	capture file close `batf'
	quietly file open `batf' using "`bat'", write text replace
	file write `batf'  `"`macval(anything)' 1> `stdout' 2> `stderr'"' _n
	file write `batf' `"echo %ErrorLevel% > `rc' "' _n
	file close `batf'
	winexec "`bat'"
	sleep 150  // a small timeout is required after winexec to wait for the files to be created
	erase "`bat'"
}

// read and print the files that were created
capture quietly{
	file open `err' using `stderr', read
	file seek `err' eof
	file seek `err' query
	local is_err = r(loc)
	file close `err'
}

if `is_err' == 0 {
	file open `out' using "`stdout'", read
	file read `out' line
	local ln = 0
	while r(eof) == 0 {
		local ln = `ln' + 1
		return local no`ln' = `"`macval(line)'"'
		file read `out' line
	}
	return local no = `ln'
	file close `out'
	type "`stdout'"
	return local rc = 0
}
else if `is_err' != 0 {
  local errormessage = ustrrtrim(fileread("`stderr'"))
  if "`errormessage'" != "" {
  	display as error "`errormessage'"
  }
  local errorcode = ustrrtrim(fileread("`rc'"))
  if "`errorcode'" != "" {
  	display as error "return code: `errorcode'"
  }
  return local rc = "`errorcode'"
  return local no = 0                  // 0 lines of stdout
}

end
