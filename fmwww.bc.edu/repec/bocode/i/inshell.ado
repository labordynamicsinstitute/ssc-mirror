*! 1.7   MBH 16 June 2022
*!  this update contains:
*!      a) a rewrite of the cd wrapper
*!      b) a fix for the timestamping of created files that allows
*!         inshell to run on earlier versions of Stata (14 and up)
*!      c) a correction to the temporary file deletion
*! 1.6   MBH 13 June 2022
*!  a significant update which includes:
*!      a) much more robust ANSI detection
*!      b) better capture of strings with special characters
*!      c) slightly streamlined code
*!      d) corrections and revisions to the help file
*! 1.5   MBH 31 May 2022
*!   a major update which contains:
*!      a)  further corrections for Windows
*!      b)  a wrapper of -cd-
*!      c)  a subprogram to clean ANSI escape sequences from any output
*!      d)  a "theme" using SMCL line characters for error results
*!      e)  demonstration shell scripts
*!      f)  a program break when S_SHELL is set
*!      g)  code which bring the Command window back into focus
*!      h)  a displayed suggestion to use a script file for long commands
*! 1.1   MBH 12 Mar 2022
*!          including corrections for Windows
*! 1.0   MBH 30 Dec 2021

capture program drop inshell

program define inshell, rclass
version 14
syntax anything (everything equalok)

if "${S_SHELL}" != "" {
	noisily display as error ///
		">>> shell macro {bf:S_SHELL} is set to: " as text `"${S_SHELL}"' ///
		_n as error ">>> this is not allowed with {bf:inshell}. Please drop the global macro {bf:S_SHELL} and try again." ///
		_n ">>> Clear the {bf:S_SHELL} macro by clicking here: "`"[{stata `"macro drop S_SHELL"': drop S_SHELL macro }]"'
	error 991
}
if "${S_XSHELL}" != "" {
		noisily display as error ///
			">>> shell macro {bf:S_XSHELL} is set to: " as text `"${S_XSHELL}"' ///
			_n as error ">>> this is not allowed with {bf:inshell}. Please drop the global macro {bf:S_XSHELL} and try again." ///
			_n ">>> Clear the {bf:S_XSHELL} macro by clicking here: "`"[{stata `"macro drop S_XSHELL"': drop S_XSHELL macro }]"'
		error 991
}

// for -cd- wrapper
if inlist("`1'", "cd", "chdir") {
	_inshell_cd `macval(2)'
	return add
}

if !inlist(`"`1'"', "cd", "chdir") {

	tempfile stdout stderr rc
	tempname out err c

	local ansi_regex_1 "[\x1b]*\[[?0-9;]*[CADJKlmhsu]"
	local ansi_regex_2 "[\x1b]*\[[^@-~]*[@-~]"

	if c(os) != "Windows" {
		shell `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
	}

	if c(os) == "Windows" {
		if "`c(mode)'" == "batch" {
			display as error ///
				">>> {bf:inshell} will not function in batch mode on Windows." ///
				" This is a Stata limitation."
			exit 990
		}
						local timestamp `=clock("`c(current_time)'","hms")'
						local       batf `c(tmpdir)'inshell_`timestamp'.bat               // added timestamp
						// using -tempfile- to create the .bat does not work for some reason
		capture erase     "`batf'"
						tempname    batn
		capture file close `batn'
		quietly file open  `batn' using "`batf'" , write text replace
						file write `batn' ///
							`"`macval(0)' 1> `stdout' 2> `stderr'"' _n
						file write `batn' ///
							`"echo %ErrorLevel% > `rc' "' _n
						file close `batn'
		quietly shell     "`batf'"
						erase     "`batf'"
	}

	capture confirm file `stderr'
	// because the output files are created via -tempfile-, they generally will exist but will hopefully
	// have zero length because there is nothing directed to the file, however there are edge cases
	// where a strangely formatted command will cause a type of "unhandled exception"
	if !_rc {
		file open `err' using `stderr' , read
		file seek `err' eof
		file seek `err' query
		local is_err = r(loc)
		file close `err'
	}
	else exit 601

	if `is_err' == 0 {
		capture confirm file "`stdout'"
		if !_rc {
			tempname is_ansi_scalar
			scalar `is_ansi_scalar' = subinstr(fileread("`stdout'"),  char(10), "", . )
			if ustrregexm(scalar(`is_ansi_scalar'), "`ansi_regex_1'") == 1 {
				_inshell_deansify, file("`stdout'")
				local stdout2 "`r(outfile)'"
				if !missing("`r(deansify_errors)'") return local line_errors = "`r(deansify_errors)'"
			}
			else local stdout2 "`stdout'"
			file open `out' using "`stdout2'", read
			file read `out' line
			local ln = 0
			while r(eof) == 0 {
				if `:strlen local line' != 0 {
					local ++ln
					return local no`ln' `"`macval(line)'"'
				}
				file read `out' line
			}
			return local no = `ln'
			file close `out'
			noisily type "`stdout2'", asis
			return local rc = 0
		}
		else exit 601
	}
	else if `is_err' != 0 {
		local errormessage = ustrtrim(fileread("`stderr'"))
		local is_ansi = ustrregexm("`errormessage'" , "`ansi_regex_1'")
		if `is_ansi' == 1 {
			_inshell_deansify, file("`stderr'") error
			local stderr2          "`r(outfile)'"
			local stderr_nosmcl    "`r(outfile_nosmcl)'"
			local typeoption       ", smcl"
		}
		else{
			local stderr2          "`stderr'"
			local stderr_nosmcl    "`stderr'"
			local typeoption       ""
		}
		file open `err' using "`stderr_nosmcl'", read
		file read `err' line
		local ln = 0
		local maxlinelength = 0
		while r(eof) == 0 {
			local linelength = udstrlen("`macval(line)'")
			if `linelength' != 0 {
				local ++ln
				return local err`ln' `"`macval(line)'"'
				local err`ln'_int `"`macval(line)'"'
				if `linelength' > `maxlinelength' {
					local maxlinelength = `linelength'
				}
			}
			file read `err' line
		}
		return local errln = `ln'
		file close `err'
		local errormessage = ustrtrim(fileread("`stderr_nosmcl'"))
		local errorcode = ustrtrim(fileread("`rc'"))
		capture confirm integer number `errorcode'
		if _rc local errorcode "?"
		if "`c(console)'" == "" & `maxlinelength' <= `=`:set linesize' - min(`:strlen local errorcode', 2) - 9' {
			local stderr_size = `maxlinelength' + 2
			if `:strlen local errorcode' < 2 {
				local rc_size   = `:strlen local errorcode' + 3
				local padding   " "
			}
			else {
				local rc_size   = `:strlen local errorcode' + 2
			}
			local space_size  = `:set linesize' - `stderr_size' - `rc_size' - 4
			local rc_hline    = `:strlen local rc_size' - 6
			if `ln' >= 2 {
				forvalues i = 2 / `ln' {
					local error_box`i' _n "{c |} `macval(err`i'_int)' {space `=`maxlinelength' - `:udstrlen local err`i'_int''}{c |}"
					if `i' == 2 {
						local error_box`i' `"`error_box`i'' "{space `space_size'}{c BLC}{hline `rc_hline'}{it: rc }{c BRC}""'
					}
					local error_box_total "`error_box_total' `error_box`i''"
				}
				noisily display as smcl ///
					_n "{err}{c TLC}{hline `stderr_size'}{c TRC}{space `space_size'}{c TLC}{hline `rc_size'}{c TRC}" ///
					_n "{c |} `macval(err1_int)' {space `=`stderr_size'-`:udstrlen local err1_int'-2'}{c |}{space `space_size'}{c |} {bf:`padding'`errorcode'} {c |}" ///
					`error_box_total' ///
					_n "{c BLC}{it: stderr }{hline `=`stderr_size'-8'}{c BRC}"
				}
			else if `ln' == 1 {
				noisily display as smcl ///
					_n "{err}{c TLC}{hline `stderr_size'}{c TRC}{space `space_size'}{c TLC}{hline `rc_size'}{c TRC}" ///
					_n "{c |} `macval(err1_int)' {c |}{space `space_size'}{c |} {bf:`padding'`errorcode'} {c |}" ///
					_n "{c BLC}{it: stderr }{hline `=`stderr_size'-8'}{c BRC}{space `space_size'}{c BLC}{hline `rc_hline'}{it: rc }{c BRC}"
			}
		}
		else {
			if `is_ansi' == 1 noisily type "`stderr2'" `typeoption'
			else display as error `"`macval(errormessage)'"'
			display as error ///
					"return code: `errorcode'"
	  }
		return local stderr = subinstr(ustrtrim(`"`macval(errormessage)'"'),  char(10), " ", .)
		return local rc = "`errorcode'"
		return local no = 0
	}
}

if strlen(`"`macval(0)'"') > 250 {
		local long_command_box_size = 73
		noisily display as smcl ///
				 "{txt}{c TLC}{hline `long_command_box_size'}{c TRC}" ///
			_n "{c |} >>>  This is not an error. The command you have entered is very long.   {c |}" ///
			_n "{c |} >>> You are probably better off storing this set of commands in a shell {c |}" ///
			_n "{c |} >>> script and then executing that script file using -{bf:inshell}- as found {c |}" ///
			_n "{c |} >>> in syntax (3) in the help file: " `"[{stata `"help inshell##syntax"':help inshell: Syntax}]{space 14}{c |}"' ///
			_n "{c BLC}{hline `long_command_box_size'}{c BRC}"
}

quietly {
	// refocus to the Command window to aid interactive use, as the shell's actions can potentially shift it away
	if "`c(console)'" == "" & "`c(mode)'" != "batch" {
		if "`c(os)'" != "Windows" window manage forward command
		if "`c(os)'" == "Windows" window manage forward results
		// on Windows the Results window must be called instead, oddly enough
		// tested on StataSE 17 on Windows 10
	}
}

if !inlist(`"`1'"', "cd", "chdir") {
	foreach file in "`stdout2'" "`stderr2'" "`stderr_nosmcl'" {
		capture confirm file "`file'"
		if !_rc {
			erase "`file'"
		}
	}
}

end
