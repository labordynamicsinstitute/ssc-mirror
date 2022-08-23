*! 2.1   MBH 18 Aug  2022
*!      a) corrections to the syntax line to better allow commas
*! 2.0   MBH 20 July 2022
*!      a) post-redirection file processing is now done in Mata, which
*!          preserves all special characters
*!      b) compatibility with global shell macro S_SHELL
*!      b) better compatibility with csh and tcsh
*!      c) several useful macro options to control its behavior
*!      d) a -cd- wrapper rewritten in Mata
*!      e) a do-file which performs diagnostics of the user's shell setup within Stata
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
*!      g)  code which brings the Command window back into focus
*!      h)  a displayed suggestion to use a script file for long commands
*! 1.1   MBH 12 Mar 2022
*!          including corrections for Windows
*! 1.0   MBH 30 Dec 2021

capture program drop inshell

program define inshell, rclass
version 14
syntax anything(everything equalok) [, * ]

// inshell diagnostics
if inlist(`"`0'"', "diag", "diagn", "diagno", "diagnos", "diagnost", "diagnosti", "diagnostic", "diagnostics") {
	if lower(c(os)) != "windows" {
		capture which inshell_diagnostics
		if (!_rc) {
			inshell_diagnostics
			exit 0
		}
		if (_rc) {
			noisily display ///
				as error " >>> the program which runs the diagnostic routines for {bf:inshell} was not found on your system. Perhaps it has become lost, deleted, renamed, or otherwise corrupted.
				exit 1
		}
	}
	else if lower(c(os)) == "windows" {
		noisily display ///
			as error _n " >>> Sorry, but {bf:inshell} does not currently have a diagnostics mode for {bf:Microsoft Windows}. Stay tuned."
		exit 1
	}
}

// "auto cd" -- this feature mimics zsh's AUTO_CD feature: if a command is
// issued that is the name of a sub-directory within the current working
// directory, it will perform the -cd- command to that sub-directory. It is
// toggled off by default
if !inlist(`"`1'"', "", "cd", "chdir") & missing("`2'") & !missing("${INSHELL_ENABLE_AUTOCD}") {
	tempname direxist
	mata : st_numscalar("`direxist'", direxists("`macval(1)'"))
	if scalar(`direxist') == 1 {
		quietly capture cd `"`macval(1)'"'
		if (!_rc) {
			noisily pwd
			return local no = 1
			return local no1 "`c(pwd)'"
			return local rc = 0
			exit 0
		}
	}
}

// for -cd- wrapper
if inlist(`"`1'"', "cd", "chdir") {
	if `"`2'"' == "-" {
		noisily display ///
			as error " >>> previous directory switching is not supported by this cd wrapper"
		exit 1
	}
	mata : inshell_cd(`"`macval(2)'"')
	if `cdsuccess' == 1 {
		noisily pwd
		return local no1 = "`c(pwd)'"
		return local no = 1
		return local rc = 0
		exit 0
	}
	else if `cdsuccess' == 0 {
		return local rc = 1
		exit 1
	}
}

if !inlist(`"`1'"', "cd", "chdir") {

	tempfile stdout stderr rc
	tempname out err c

	if lower(c(os)) != "windows" {
		if strpos("${S_SHELL}", "pwsh") {
			shell `macval(0)' 2> `stderr' 1> `stdout' ; echo $? > `rc'
		}
		if !strpos("${S_SHELL}", "pwsh") & !strpos("${S_SHELL}", "csh") {
			if !missing("${INSHELL_PATHEXT}") {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				quietly if scalar(`pathextisvalid') == 0 {
					noisily display ///
						as error   " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "  ///
						as text   `"${INSHELL_PATHEXT}"'                                                  _n  ///
						as error   " >>> Either this directory does not exist or it is inaccessible."     _n  ///
						" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."            _n  ///
						" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if scalar(`pathextisvalid') == 1 {
					if missing("${INSHELL_TERM}") {
						shell export PATH=${INSHELL_PATHEXT}:\$PATH && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
					}
					else if !missing("${INSHELL_TERM}") {
						shell export PATH=${INSHELL_PATHEXT}:\$PATH && export TERM=${INSHELL_TERM} && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
					}
				}
			}
			else if missing("${INSHELL_PATHEXT}") {
				if !missing("${INSHELL_TERM}") {
					shell export TERM=${INSHELL_TERM} && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
				}
				else if missing("${INSHELL_TERM}") {
					shell `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
				}
			}
		}
		else if strpos("${S_SHELL}", "csh") {
			if !missing("${INSHELL_PATHEXT}") {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				quietly if scalar(`pathextisvalid') == 0 {
					noisily display ///
						as error   " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "  ///
						as text   `"${INSHELL_PATHEXT}"'                                                  _n  ///
						as error   " >>> Either this directory does not exist or it is inaccessible."     _n  ///
						" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."            _n  ///
						" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if scalar(`pathextisvalid') == 1 {
					if missing("${INSHELL_TERM}") {
						shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
					}
					else if !missing("${INSHELL_TERM}") {
						shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && setenv TERM ${INSHELL_TERM} && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
					}
				}
			}
			else if missing("${INSHELL_PATHEXT}") {
				if !missing("${INSHELL_TERM}") {
					shell setenv TERM ${INSHELL_TERM} && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
				}
				else if missing("${INSHELL_TERM}") {
					shell ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
				}
			}
		}
	}
	else if lower(c(os)) == "windows" {
		if "`c(mode)'" == "batch" {
			display ///
				as error " >>> {bf:inshell} will not function in batch mode on {bf:Windows}. This is a Stata limitation."
			exit 990
		}
						local       batf  "`c(tmpdir)'inshell_`= clock("`c(current_time)'", "hms")'`= runiformint(1, 99999)'.bat"
						// using -tempfile- to create the .bat does not work for some reason. I hope the timestamp random number combination is sufficient for all of the future uses of inshell and its future derivatives
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
	// confirm that the stderr file has length greater than zero
	capture confirm file "`stderr'"
	if (!_rc) {
		file open `err' using "`stderr'" , read
		file seek `err' eof
		file seek `err' query
		local is_err = r(loc)
		file close `err'
	}
	else exit 601

	if `is_err' == 0 {
		capture confirm file "`stdout'"
		if (!_rc) {
			quietly mata : M = inshell_process_file("`stdout'")
			quietly mata : Q = select(M, strlen(M))
			forvalues i = 1 / `rows' {
			  local j = `rows' - `i' + 1
			  mata : st_strscalar("no`j'", Q[`j'])
			  return local no`j' = scalar(no`j')
				capture scalar drop no`j'
			}
			return local no = `rows'
			noisily type "`outfile'", asis
			local rc2 = 0
			capture mata mata drop Q
		}
		else exit 601
	}
	else if `is_err' != 0 {
		quietly mata : inshell_process_file("`stderr'")
		file open `err' using "`outfile'", read
		file read `err' line
		local ln = 0
		while r(eof) == 0 {
			local ++ln
			return local err`ln' `"`macval(line)'"'
			local err`ln'_int    `"`macval(line)'"'
			file read `err' line
		}
		return local errln = `ln'
		file close `err'
		local errormessage = ustrtrim(fileread("`outfile'"))
		local errorcode    = ustrtrim(fileread("`rc'"))
		// two lines below for PowerShell
		if "`errorcode'" == "True"  local errorcode 1
		if "`errorcode'" == "False" local errorcode 0
		capture confirm integer number `errorcode'
		if (_rc) local errorcode "?"

		if "`c(console)'" == "" & `maxdlen' <= `= `: set linesize' - min(`: strlen local errorcode', 2) - 9' {
			local stderr_size = `maxdlen' + 2
			if `: strlen local errorcode' < 2 {
				local rc_size   = `: strlen local errorcode' + 3
				local pad         " "
			}
			else {
				local rc_size   = `: strlen local errorcode' + 2
			}
			local s1          = `: set linesize' - `stderr_size' - `rc_size' - 4
			local rc_hline    = `: strlen local rc_size' - 6
			if `ln' >= 2 {
				forvalues i = 2 / `ln' {
					local error_box`i' _n "{c |} `macval(err`i'_int)' {space `= `maxdlen' - `: udstrlen local err`i'_int''}{c |}"
					if `i' == 2 {
						local error_box`i' `"`error_box`i'' "{space `s1'}{c BLC}{hline `rc_hline'}{it: rc }{c BRC}""'
					}
					local error_box_total "`error_box_total' `error_box`i''"
				}
				noisily display as smcl ///
					_n "{err}{c TLC}{hline `stderr_size'}{c TRC}{space `s1'}{c TLC}{hline `rc_size'}{c TRC}" ///
					_n "{c |} `macval(err1_int)' {space `= `stderr_size' - `: udstrlen local err1_int' - 2'}{c |}{space `s1'}{c |} {bf:`pad'`errorcode'} {c |}" ///
					`error_box_total'   ///
					_n "{c BLC}{it: stderr }{hline `= `stderr_size' - 8'}{c BRC}"
			}
			else if `ln' == 1 {
				noisily display as smcl ///
					_n "{err}{c TLC}{hline `stderr_size'}{c TRC}{space `s1'}{c TLC}{hline `rc_size'}{c TRC}" ///
					_n "{c |} `macval(err1_int)' {c |}{space `s1'}{c |} {bf:`pad'`errorcode'} {c |}" ///
					_n "{c BLC}{it: stderr }{hline `= `stderr_size' - 8'}{c BRC}{space `s1'}{c BLC}{hline `rc_hline'}{it: rc }{c BRC}"
			}
		}
		else {
			display ///
				as error `"`macval(errormessage)'"'
			display ///
				as error "return code: `errorcode'"
	  }
		return local stderr = subinstr(ustrtrim(`"`macval(errormessage)'"'),  char(10), " ", .)
		local rc2 = "`errorcode'"
		return local no = 0
	}
}

if strlen(`"`macval(0)'"') > 300 & missing("${INSHELL_DISABLE_LONGCMDMSG}") {
		local long_command_box_size = 73
		noisily display as smcl ///
				 "{txt}{c TLC}{hline `long_command_box_size'}{c TRC}" ///
			_n "{c |} >>>  This is not an error. The command you have entered is very long.   {c |}" ///
			_n "{c |} >>> You are probably better off storing this set of commands in a shell {c |}" ///
			_n "{c |} >>> script and then executing that script file using {bf:inshell} as found {c |}" ///
			_n "{c |} >>> in syntax (3) in the help file: " `"[{stata `"help inshell##suggestions"':help inshell: Suggestions}]{space 14}{c |}"' ///
			_n "{c BLC}{hline `long_command_box_size'}{c BRC}"
}

if missing("${INSHELL_DISABLE_REFOCUS}") {
	quietly {
		// refocus to the Command window to aid interactive use, as the shell's actions can potentially shift it away
		if ("`c(console)'" == "" & "`c(mode)'" != "batch") {
			if lower(c(os)) != "windows" window manage forward command
			if lower(c(os)) == "windows" window manage forward results
			// on Windows the Results window must be called instead, oddly enough
			// tested on StataSE 17 on Windows 10
		}
	}
}

return local rc `rc2'

end
