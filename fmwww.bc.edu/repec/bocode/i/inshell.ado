*! 2.6   MBH  15 Oct  2022
*!      a) minimum file I/O, which should make inshell faster, especially on systems
*!          without solid-state hard drives
*!      b) escaped tabs are now translated into spaces, the number of which can be set by
*!          global macro INSHELL_ESCTAB_SIZE, ranging from 1 to 8. The default is 3
*!      c) -return list- of standard error is now listed in proper order
*!      d) comments added to code
*!      e) the syntax parser now prevents a list of fatal interactive commands from
*!          running, which would otherwise require Stata to be force quit. This list can
*!          be augmented using global macro INSHELL_BLOCKEDCMDS
*!      f) better support when csh or tcsh is the default shell via INSHELL_SETSHELL_CSH
*!      g) removal of the -syntax- line for less command pre-processing
*! 2.5   MBH  8 Sept 2022
*!    this update contains several important improvements such as:
*!      a) a syntax parser written in Mata to properly direct commands
*!      b) removal of empty lines after the command line by using -quietly shell-
*!      c) further improvements to capturing strings
*!      d) streamlined code with less file I/O so -inshell- is faster than ever
*!      e) corrections for handling commands that produce an error code without stderr
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

// capture program drop inshell
program define inshell, rclass
version 14                                                 // (due to -udstrlen- function)
// syntax anything(everything equalok) [, * ]              // better without -syntax- line
mata : st_rclear()                                                // clear the return list
mata : inshell_parse_syntax2()                             // parse the syntax within Mata
                              // (cont.) to better allow unbalanced quoting and back-ticks

// blocked commands - prevent certain interactive commands from running ******************
if ("`parser'" == "blocked") {
	noisily display ///
		as error ///
			"{p 2 1} >>> the command {res:{bf:`1'}} has been blocked from running because "  ///
			"it is incompatible with Stata's non-interactive shell." _n
	exit 1
}
if ("`parser'" == "userblocked") {
	noisily display ///
		as error ///
			"{p 2 1} >>> the command {res:{bf:`1'}} has been blocked from running because "  ///
			"you have added it to the block list set by global macro option {bf:INSHELL_BLOCKEDCMDS}." _n
	exit 1
}

// "diagnostics" *************************************************************************
// display information about the shell, its PATH, and the various inshell macro options
if ("`parser'" == "diagnostics") {
	if (lower(c(os)) != "windows") {
		capture which inshell_diagnostics
		if (!_rc) {
			inshell_diagnostics
			exit 0
		}
		else if (_rc) {
			noisily display ///
				as error ///
					"{p 2 1} >>> the diagnostics program for {bf:inshell} was not found on your system. " ///
					"Perhaps it has become lost, deleted, renamed, or otherwise corrupted."
				exit 1
		}
	}
	else if (lower(c(os)) == "windows") {
		noisily display ///
			as error ///
				_n "{p 2 1} >>> Sorry, but {bf:inshell} does not currently have a diagnostics mode for {bf:Microsoft Windows}." ///
					 "Stay tuned."
		exit 1
	}
}

// "auto cd" *****************************************************************************
// this feature mimics zsh's AUTO_CD feature: if a command is issued that is the name of
// a sub-directory within the current working directory, it will perform the -cd- command
// to that sub-directory. It is toggled off by default.
if ("`parser'" == "autocd") {
	mata : if (direxists("`macval(1)'")); chdir("`macval(1)'")
	noisily pwd
	return local no1 = c(pwd)
	return local no  = 1
	exit 0
}

// -cd- wrapper **************************************************************************
if ("`parser'" == "cd") {
	if (`"`2'"' == "-") {
		noisily display ///
			as error ///
				"{p 2 1} >>> previous directory switching is not supported by this cd wrapper"
		exit 1
	}
	else if (`"`2'"' == "" & lower(c(os)) == "windows") {
		noisily pwd                // -cd- without arguments on Windows is equivalent to -pwd-
		return local no1 = c(pwd)
		return local no  = 1
		exit 0
	}
	else {
		mata : inshell_cd2(`"`macval(2)'"')           // use Mata function to change directory
		if (`cdsuccess' == 1) {
			noisily pwd
			return local no1 = c(pwd)
			return local no  = 1
			exit 0
		}
		else if (`cdsuccess' == 0) {
			return local rc = 1
			exit 1
		}
	}
}

// shell command *************************************************************************
if ("`parser'" == "command") {

	tempfile stdout stderr rc     // create tempfiles that will store the redirected streams

	// check that the alternative escaped-tab size is properly set
	capture assert inrange("${INSHELL_ESCTAB_SIZE}", 1, 8)
	if (!_rc) {
		capture confirm integer number ${INSHELL_ESCTAB_SIZE}
		if (_rc) global INSHELL_ESCTAB_SIZE = 3
	}
	else global INSHELL_ESCTAB_SIZE = 3

	// choose between Windows or not-Windows
	if (lower(c(os)) != "windows") {
		if (strpos("${S_SHELL}", "pwsh")) {
			quietly shell `macval(0)' 2> `stderr' 1> `stdout' ; echo  $? > `rc'
		}
		else if (!strpos("${S_SHELL}", "pwsh") & !strpos("${S_SHELL}", "csh")) {
			if (!missing("${INSHELL_PATHEXT}")) {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				if (scalar(`pathextisvalid') == 0) {
					noisily display ///
						as error " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "  ///
						as text  `"${INSHELL_PATHEXT}"'                                                 _n  ///
						as error ///
							" >>> Either this directory does not exist or it is inaccessible."            _n  ///
							" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."        _n  ///
							" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "                    ///
							`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if (scalar(`pathextisvalid') == 1) {
					if (missing("${INSHELL_TERM}")) {
						quietly shell export PATH=${INSHELL_PATHEXT}:\$PATH && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
					}
					else if (!missing("${INSHELL_TERM}")) {
						quietly shell export PATH=${INSHELL_PATHEXT}:\$PATH && export TERM=${INSHELL_TERM} && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
					}
				}
			}
			else if (missing("${INSHELL_PATHEXT}")) {
				if (!missing("${INSHELL_TERM}")) {
					quietly shell export TERM=${INSHELL_TERM} && `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
				}
				else if (missing("${INSHELL_TERM}")) {
					quietly shell `macval(0)' 2> `stderr' 1> `stdout' || echo $? > `rc'
				}
			}
		}
		else if (strpos("${S_SHELL}", "csh") | (!missing("${INSHELL_SETSHELL_CSH}"))) {
			if (!missing("${INSHELL_PATHEXT}")) {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				if (scalar(`pathextisvalid') == 0) {
					noisily display ///
						as error " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "  ///
						as text  `"${INSHELL_PATHEXT}"'                                                 _n  ///
						as error ///
							" >>> Either this directory does not exist or it is inaccessible."            _n  ///
							" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."        _n  ///
							" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "                    ///
							`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if (scalar(`pathextisvalid') == 1) {
					if (missing("${INSHELL_TERM}")) {
						quietly shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
					}
					else if (!missing("${INSHELL_TERM}")) {
						quietly shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && setenv TERM ${INSHELL_TERM} && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
					}
				}
			}
			else if (missing("${INSHELL_PATHEXT}")) {
				if (!missing("${INSHELL_TERM}")) {
					quietly shell setenv TERM ${INSHELL_TERM} && ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
				}
				else if (missing("${INSHELL_TERM}")) {
					quietly shell ( `macval(0)' > `stdout' ) >& `stderr' || echo $? > `rc'
				}
			}
		}
	}
	else if (lower(c(os)) == "windows") {
		if ("`c(mode)'" == "batch") {
			noisily display ///
				as error ///
					"{p 2 1} >>> {bf:inshell} will not function in batch mode on {bf:Microsoft Windows}. " ///
					"This is a Stata limitation."
			exit 990
		}
						local       batf  "`c(tmpdir)'inshell_`= clock("`c(current_time)'", "hms")'`= runiformint(1, 99999)'.bat"
						// using -tempfile- to create the .bat does not work for some reason
						tempname    batn
		capture file close `batn'
		quietly file open  `batn' using "`batf'" , write text replace
						file write `batn' ///
							`"`macval(0)' 1> `stdout' 2> `stderr'"' _n
						file write `batn' ///
							`"echo %ErrorLevel% > `rc' "' _n
						file close `batn'
		quietly shell     "`batf'"
		quietly erase     "`batf'"
	}

	// read the stdout *********************************************************************
	capture quietly confirm file "`stdout'"     // confirm the file exists before proceeding
	if (!_rc) {                                        // if there's no problem with that...
		mata : M = inshell_process_file2("`stdout'")             // process the stdout in Mata
		mata : for (i=1; i<=rows(M); i++) printf("%s\n", M[i])   // print the matrix from Mata
		mata : Q = select(M, strlen(M))     // create a matrix containing only non-blank lines
		return local no  = `rows'              // return the number of lines of stdout (r(no))
		forvalues i = 1 / `rows' {
			                               // this cannot be looped in an inline Mata statement:
			                                  // "non rclass programs my not set r-class values"
			local j = `rows' - `i' + 1                                   // reverse the sequence
			mata : st_global("r(no`j')", Q[`j'])                   // return the macros via Mata
		}
		return add                                        // add captured lines to return list
		capture mata mata drop Q i                      // drop the unneeded matrix and scalar
	}

	// read the return code ****************************************************************
	capture quietly confirm file "`rc'"         // confirm the file exists before proceeding
	if (!_rc) {                                        // if there's no problem with that...
		local errorcode    = ustrtrim(fileread("`rc'"))                    // read in the file
		                                  // following two lines are for Microsoft PowerShell:
		if ("`errorcode'" == "True")  local errorcode 0  // set the errorcode to 0 for "True"
		if ("`errorcode'" == "False") local errorcode 1  // set the errorcode to 1 for "False"
		capture confirm integer number `errorcode'     // confirm that errorcode is an integer
		if (_rc) local errorcode "?"                  // set the errorcode to "?" if it is not
	}

	// read the standard error *************************************************************
	capture quietly confirm file "`stderr'"     // confirm the file exists before proceeding
	if (!_rc) {                                        // if there's no problem with that...
		mata : N = inshell_process_file2("`stderr'")                       // process the file
		mata : st_local("displayrows", strofreal(rows(N)))      // get the number of rows of N
		if (`displayrows' > 0) {
			mata : R = select(N, strlen(N))   // create a matrix containing only non-blank lines
			mata : st_local("errormessage", invtokens(R'))        // condense the lines into one
			mata : for (i=1; i<=rows(N); i++) st_local("E" + strofreal(i), N[i])
			forvalues i = 1 / `rows' {
				                             // this cannot be looped in an inline Mata statement:
				                                // "non rclass programs my not set r-class values"
				local j = `rows' - `i' + 1                                 // reverse the sequence
				mata : st_global("r(err`j')", R[`j'])                // return the macros via Mata
			}
			capture mata mata drop R i                    // drop the unneeded matrix and scalar
			return local errln = `rows'                   // return the number of non-blank rows
			return add                                      // add captured lines to return list
			if missing("`errorcode'") local errorcode "?"     // set errorcode to "?" if missing

			// display the standard error ******************************************************
			if (`maxdlen' <= `= `: set linesize' - min(`: strlen local errorcode', 2) - 9') {
				local errbox  = `maxdlen' + 2
				if (`: strlen local errorcode' < 2) {
					local rcbox = `: strlen local errorcode' + 3
					local pad     " "
				}
				else {
					local rcbox = `: strlen local errorcode' + 2
				}
				local s       = "space `= `: set linesize' - `errbox' - `rcbox' - 4'"
				local rchl    = `: strlen local rcbox' - 6
				if (`displayrows' >= 2) {
					forvalues i = 2 / `displayrows' {
						local error_box`i' _n "{c |} `macval(E`i')' {space `= `maxdlen' - `: udstrlen local E`i'''}{c |}"
						if (`i' == 2) {
							local error_box`i' `"`macval(error_box`i')' "{`s'}{c BLC}{hline `rchl'}{it: rc }{c BRC}""'
						}
						local error_box_total "`macval(error_box_total)' `macval(error_box`i')'"
					}
					noisily display ///
						as smcl ///
							 "{err}{c TLC}{hline `errbox'}{c TRC}{`s'}{c TLC}{hline `rcbox'}{c TRC}" ///
						_n "{c |} `macval(E1)' {space `= `errbox' - `: udstrlen local E1' - 2'}{c |}{`s'}{c |} {bf:`pad'`errorcode'} {c |}" ///
						          `macval(error_box_total)'   ///
						_n "{c BLC}{it: stderr }{hline `= `errbox' - 8'}{c BRC}"
				}
				else if (`displayrows' == 1) {
					noisily display ///
						as smcl ///
							 "{err}{c TLC}{hline `errbox'}{c TRC}{`s'}{c TLC}{hline `rcbox'}{c TRC}" ///
						_n        "{c |} `macval(E1)' {c |}{`s'}{c |} {bf:`pad'`errorcode'} {c |}" ///
						_n      "{c BLC}{it: stderr }{hline `= `errbox' - 8'}{c BRC}{`s'}{c BLC}{hline `rchl'}{it: rc }{c BRC}"
				}
			}
			else {
				if (!missing("`macval(errormessage)'")) {
					noisily display ///
						as error ///
							`"{p 2 1}`macval(errormessage)'{p_end}"'
					noisily display ///
						as error ///
							"{it:return code:}{bf: `errorcode'}"
				}
			}
			return local stderr = subinstr(ustrtrim(`"`macval(errormessage)'"'),  char(10), " ", .)
		}
	}
	if (!missing("`errorcode'") & missing("`errormessage'")) {
		if ("`errorcode'" != "0") {
			if `: strlen local errorcode' == 1 local pad " "
		  local rcline = max(`: strlen local errorcode' - 2, 0)
		  local rcbox  = `rchl' + 4
			noisily display ///
				as error ///
					   "{right:{c TLC}{hline        `rcbox'}{c TRC}}"        ///
					_n "{right:{c   |}{bf: `pad'`errorcode' }{c |}}"         ///
					_n "{right:{c BLC}{hline `rcline'}{it: rc }{c BRC}}"
		}
	}
}

// display a message for a long shell command ********************************************
if ("`parser'" == "command" & "`parser2'" == "longcmd") {
	local long_command_box_size = 73
	noisily display ///
		as smcl ///
			 "{txt}{c TLC}{hline `long_command_box_size'}{c TRC}"                                        ///
		_n "{c |} >>>  This is not an error. The command you have entered is very long.   {c |}"       ///
		_n "{c |} >>> You are probably better off storing this set of commands in a shell {c |}"       ///
		_n "{c |} >>> script and then executing that script file using {bf:inshell} as found   {c |}"  ///
		_n "{c |} >>> in syntax (3) in the help file: " `"[{stata `"help inshell##suggestions"':help inshell: Suggestions}]{space 9}{c |}"' ///
		_n "{c BLC}{hline `long_command_box_size'}{c BRC}"
}

// refocus to Command window *************************************************************
if (missing("${INSHELL_DISABLE_REFOCUS}")) {
	// refocus to the Command window to aid interactive use, as the shell's actions can potentially shift it away
	if (missing(c(console)) & c(mode) != "batch") {
		if (lower(c(os)) != "windows") window manage forward command
		if (lower(c(os)) == "windows") window manage forward results
		// on Windows the Results window must be called instead, oddly enough
		// this was tested with StataSE 17 on Windows 10
	}
}

return local rc "`errorcode'"

end
