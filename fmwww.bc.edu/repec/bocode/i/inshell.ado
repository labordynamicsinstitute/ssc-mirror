*! 2.8   MBH  29 Dec  2022
*! an enhanced multi-platform wrapper of -shell- which captures the output of system commands
**!     a) corrections for printing stdout and stderr to avoid interpreting SMCL directives
**!     b) commands sent to the shell are now returned in r(cmd) for review and debugging
**!     c) horizontal tabs (ASCII char code 9) are now handled differently: conversion to
**!         spaces (ASCII char code 32) is now an option
**!     d) removal of the batch mode limitation on Windows for Stata 17 (23 Aug 2022) and later
**!     e) use of more tempnames for Mata variables
**!     f) code width expansion to 95 characters
**!     g) footnotes for additional comments on the most important lines of code
**! 2.7   MBH  27 Nov  2022
**!     a) refinements and corrections to the ANSI removal routine
**!     b) the diagnostics routine now checks to ensure that the INSHELL_SETSHELL_CSH
**!         option is properly set when using a csh-type shell as the default shell
**!     c) fixes to the horizontal tab-to-spaces conversion
**!     d) numerous other small coding refinements
**! 2.6   MBH  15 Oct  2022
**!     a) minimum file I/O, which should make -inshell- faster, especially on systems
**!         without solid-state hard drives
**!     b) horizontal tabs (ASCII character 9) are now translated into spaces, the
**!         number of which can be set by global macro INSHELL_TAB_SPACES, ranging from
**!         1 to 8 with a default of 4
**!     c) -return list- of standard error is now listed in proper order
**!     d) comments added to code
**!     e) the syntax parser now prevents a list of fatal interactive commands from
**!         running, which would otherwise require Stata to be force quit. This list can
**!         be augmented using global macro INSHELL_BLOCKEDCMDS
**!     f) better support when csh or tcsh is the default shell via INSHELL_SETSHELL_CSH
**!     g) removal of the -syntax- line for less command pre-processing
**! 2.5   MBH  8 Sept 2022
**!   this update contains several important improvements such as:
**!     a) a syntax parser written in Mata to properly direct commands
**!     b) removal of empty lines after the command line by using -quietly shell-
**!     c) further improvements to capturing strings
**!     d) streamlined code with less file I/O so -inshell- is faster than ever
**!     e) corrections for handling commands that produce an error code without stderr
**! 2.1   MBH 18 Aug  2022
**!     a) corrections to the syntax line to better allow commas
**! 2.0   MBH 20 July 2022
**!     a) post-redirection file processing is now done in Mata, which
**!         preserves all special characters
**!     b) compatibility with global shell macro S_SHELL
**!     b) better compatibility with csh and tcsh shells
**!     c) several useful macro options to control its behavior
**!     d) a -cd- wrapper rewritten in Mata
**!     e) a program which performs diagnostics of the user's shell setup within Stata
**! 1.7   MBH 16 June 2022
**!   this update contains:
**!     a) a rewrite of the -cd- wrapper
**!     b) a fix for the time-stamping of created files that allows
**!        -inshell- to run on earlier versions of Stata (14 and up)
**!     c) a correction to the temporary file deletion
**! 1.6   MBH 13 June 2022
**!   a significant update which includes:
**!     a) much more robust ANSI detection
**!     b) better capture of strings with special characters
**!     c) slightly streamlined code
**!     d) corrections and revisions to the help file
**! 1.5   MBH 31 May 2022
**!   a major update which contains:
**!     a)  further corrections for Windows
**!     b)  a wrapper of -cd-
**!     c)  a subprogram to clean ANSI escape sequences from the output
**!     d)  a "theme" using SMCL line characters for error results
**!     e)  demonstration shell scripts
**!     f)  a program break when S_SHELL is set
**!     g)  code which brings the Command window back into focus
**!     h)  a displayed suggestion to use a script file for long commands
**! 1.1   MBH 12 Mar 2022
**!   including corrections for Windows
**! 1.0   MBH 30 Dec 2021

program define inshell, rclass
version 14
mata : st_rclear()                                                 // clear the return list [1]
mata : inshell_syntax_parser()   // parse the syntax through Mata to avoid parsing in Stata [2]

local p "{p 2 1}"                                         // paragraph sizing for SMCL messages
// blocked commands ***************************************************************************
//  prevent specified interactive commands from running because they can crash Stata
if ("`parser'" == "blocked") {
	display as error ///
		"`p' >>> the command {res:{bf:`1'}} has been blocked from running because " ///
		"it is incompatible with Stata's non-interactive shell." _n
	exit 1
}
if ("`parser'" == "userblocked") {
	display as error ///
		"`p' >>> the command {res:{bf:`1'}} has been blocked from running because " ///
		"you have added it to the block list set by global macro option {bf:INSHELL_BLOCKEDCMDS}." _n
	exit 1
}

// diagnostics ********************************************************************************
//  display information about the shell, its PATH, and the various inshell global macro options
if ("`parser'" == "diagnostics") {
	if (lower(c(os)) != "windows") {
		capture which inshell_diagnostics
		if (!_rc) {
			inshell_diagnostics
		}
		else if (_rc) {
			display as error ///
				"`p' >>> the diagnostics program for {bf:inshell} was not found on your system. " ///
				"Perhaps it has become lost, deleted, renamed, or otherwise corrupted."
			exit 1
		}
	}
	else if (lower(c(os)) == "windows") {
		display as error ///
			_n "`p' >>> Sorry, but {bf:inshell} does not currently have a diagnostics mode for " ///
			   "{bf:Microsoft Windows}. Stay tuned."
		exit 1
	}
}

// auto -cd- **********************************************************************************
//  this feature mimics zsh's AUTO_CD feature: if a command is issued that is the name of
// a sub-directory within the current working directory, it will perform the -cd- command to
// that sub-directory. It is toggled off by default.
if ("`parser'" == "autocd") {
	mata : if (direxists(st_local("1"))); chdir(st_local("1"))
	noisily pwd
	return local no1 = c(pwd)
	return local no  = 1
	exit 0
}

// -cd- wrapper *******************************************************************************
if ("`parser'" == "cd") {
	if ((`"`2'"' == "") & (lower(c(os)) == "windows")) {
		noisily pwd                     // -cd- without arguments on Windows is equivalent to -pwd-
		return local no1 = c(pwd)
		return local no  = 1
		exit 0
	}
	else {
		mata : inshell_chdir(st_local("2"))                // use Mata function to change directory
		if (`cdsuccess') {
			noisily pwd
			return local no1 = c(pwd)
			return local no  = 1
			exit 0
		}
		else if (!`cdsuccess') {
			return local rc = 1
		}
	}
}

// shell command ******************************************************************************
if ("`parser'" == "command") {

	mata : st_global("r(cmd)", st_local("0"))    // store command sent to the shell in return [3]
	return add

	tempfile stdout stderr rc          // create tempfiles that will store the redirected streams

	// choose between Windows or not-Windows
	if (lower(c(os)) != "windows") {
		if (strpos("${S_SHELL}", "pwsh")) {
			quietly shell `macval(0)' 2> "`stderr'" 1> "`stdout'" ; echo  $? > "`rc'"
		}
		else if ((!strpos("${S_SHELL}", "pwsh")) & (!strpos("${S_SHELL}", "csh"))) {
			if (!missing("${INSHELL_PATHEXT}")) {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				if (scalar(`pathextisvalid') == 0) {
					display as error ///
						" >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "       ///
						as text  `"${INSHELL_PATHEXT}"'                                             _n  ///
						as error ///
							" >>> Either this directory does not exist or it is inaccessible."        _n  ///
							" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."    _n  ///
							" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "                ///
							`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if (scalar(`pathextisvalid') == 1) {
					if (missing("${INSHELL_TERM}")) {
						quietly shell export PATH=${INSHELL_PATHEXT}:\$PATH && `macval(0)' 2> "`stderr'" 1> "`stdout'" || echo $? > "`rc'"
					}
					else if (!missing("${INSHELL_TERM}")) {
						quietly shell export PATH=${INSHELL_PATHEXT}:\$PATH && export TERM=${INSHELL_TERM} && `macval(0)' 2> "`stderr'" 1> "`stdout'" || echo $? > "`rc'"
					}
				}
			}
			else if (missing("${INSHELL_PATHEXT}")) {
				if (!missing("${INSHELL_TERM}")) {
					quietly shell export TERM=${INSHELL_TERM} && `macval(0)' 2> "`stderr'" 1> "`stdout'" || echo $? > "`rc'"
				}
				else if (missing("${INSHELL_TERM}")) {
					quietly shell `macval(0)' 2> "`stderr'" 1> "`stdout'" || echo $? > "`rc'"
				}
			}
		}
		else if ((strpos("${S_SHELL}", "csh")) | (!missing("${INSHELL_SETSHELL_CSH}"))) {
			if (!missing("${INSHELL_PATHEXT}")) {
				tempname pathextisvalid
				mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
				if (scalar(`pathextisvalid') == 0) {
					display as error ///
						" >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} is set to "       ///
						as text  `"${INSHELL_PATHEXT}"'                                             _n  ///
						as error ///
							" >>> Either this directory does not exist or it is inaccessible."        _n  ///
							" >>> Please fix the {bf:INSHELL_PATHEXT} global macro and try again."    _n  ///
							" >>> Clear the {bf:INSHELL_PATHEXT} macro by clicking here: "                ///
							`"[{stata `"macro drop INSHELL_PATHEXT"': drop INSHELL_PATHEXT macro }]"'
					exit 991
				}
				else if (scalar(`pathextisvalid') == 1) {
					if (missing("${INSHELL_TERM}")) {
						quietly shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && ( `macval(0)' > "`stdout'" ) >& "`stderr'" || echo $? > "`rc'"
					}
					else if (!missing("${INSHELL_TERM}")) {
						quietly shell setenv PATH ${INSHELL_PATHEXT}:\$PATH && setenv TERM ${INSHELL_TERM} && ( `macval(0)' > "`stdout'" ) >& "`stderr'" || echo $? > "`rc'"
					}
				}
			}
			else if (missing("${INSHELL_PATHEXT}")) {
				if (!missing("${INSHELL_TERM}")) {
					quietly shell setenv TERM ${INSHELL_TERM} && ( `macval(0)' > "`stdout'" ) >& "`stderr'" || echo $? > "`rc'"
				}
				else if (missing("${INSHELL_TERM}")) {
					quietly shell ( `macval(0)' > "`stdout'" ) >& "`stderr'" || echo $? > "`rc'"
				}
			}
		}
	}
	else if (lower(c(os)) == "windows") {
		local date "23 Aug 2022"
		if ((!missing(c(mode))) & ((date(c(born_date), "DMY") - date("`date'", "DMY")) < 0)) {
			display as error ///
				"`p' >>> {bf:inshell} will not function on this copy of Stata in batch mode on"    ///
				" {bf:Microsoft Windows}. This is a limitation of any version of Stata prior to"   ///
				" the {bf:`date'} update of Stata 17. You must update to the {bf:`date'} update"   ///
				" of Stata 17 or newer to use shell commands in batch mode{p_end}" _n
			exit 990
		}
		local       batf  "`c(tmpdir)'inshell_`= clock(c(current_time), "hms")'`= runiformint(1, 99999)'.bat"
		// using -tempfile- to create the .bat does not work for some reason
		tempname            batn
		capture file close `batn'
		quietly file open  `batn' using "`batf'" , write text replace
						file write `batn' `"`macval(0)' 1> `stdout' 2> `stderr'"' _n
						file write `batn' `"echo %ErrorLevel% > `rc' "' _n
						file close `batn'
		quietly shell     "`batf'"
		quietly erase     "`batf'"
	}

	// check that the alternative horizontal tab (ASCII character 9) size is properly set     [4]
	if (!missing("${INSHELL_TAB_SPACES}")) {
		capture assert inrange(${INSHELL_TAB_SPACES}, 1, 8)
		if (!_rc) {
			capture confirm integer number ${INSHELL_TAB_SPACES}
			if (_rc) macro drop INSHELL_TAB_SPACES
		}
		else macro drop INSHELL_TAB_SPACES
	}

	// read the stdout **************************************************************************
	capture quietly confirm file "`stdout'"          // confirm the file exists before proceeding
	if (!_rc) {                                             // if there's no problem with that...
		tempname Q m                               // create temporary names for Mata variables [5]
		mata : M = inshell_capture_format("`stdout'", $INSHELL_TAB_SPACES)   // process stdout file
		mata : for (`m'=1; `m'<=rows(M); `m'++) display(sprintf("%s", M[`m']), 1)  // display M [6]
		mata : `Q' = select(M, M :!= "")     // create a vector containing only non-blank lines [7]
		return local no  = `rows'                   // return the number of lines of stdout (r(no))
		forvalues i = 1 / `rows' {
			                                    // this cannot be looped in an inline Mata statement:
			                                       // "non rclass programs my not set r-class values"
			local j = `rows' - `i' + 1                                        // reverse the sequence
			mata : st_global("r(no`j')", `Q'[`j'])                  // return the macros via Mata [8]
		}
		return add                                       // add r() globals set from Mata to return
		capture mata : mata drop `Q' `m'                 // drop the unneeded vector and scalar [9]
	}

	// read the return code *********************************************************************
	capture quietly confirm file "`rc'"              // confirm the file exists before proceeding
	if (!_rc) {                                           // if there is no problem with that...
		local errorcode    = ustrtrim(fileread("`rc'"))        // read in and process the file [10]
		                                   // the following two lines are for Microsoft PowerShell:
		if ("`errorcode'" == "True")  local errorcode 0        // set the errorcode to 0 for "True"
		if ("`errorcode'" == "False") local errorcode 1       // set the errorcode to 1 for "False"
		capture confirm integer number `errorcode'          // confirm that errorcode is an integer
		if (_rc) local errorcode "?"                       // set the errorcode to "?" if it is not
	}

	// read the standard error ******************************************************************
	capture quietly confirm file "`stderr'"          // confirm the file exists before proceeding
	if (!_rc) {                                            // if there is no problem with that...
		tempname R E n                                 // create temporary names for Mata variables
		mata : N = inshell_capture_format("`stderr'", 4)                 // process the stderr file
		mata : st_local("displayrows", strofreal(rows(N)))           // get the number of rows of N
		if (`displayrows' > 0) {
			mata : `R' = select(N, N :!= "")   // create a vector containing only non-blank lines [7]
			mata : for (`n'=1; `n'<=rows(N); `n'++) st_strscalar("`E'" + strofreal(`n'), N[`n'])   /*
			                     set temporary string scalars from Mata for error display box [11] */
			forvalues i = 1 / `rows' {
				                                  // this cannot be looped in an inline Mata statement:
				                                     // "non rclass programs my not set r-class values"
				local j = `rows' - `i' + 1                                      // reverse the sequence
				mata : st_global("r(err`j')", `R'[`j'])               // return the macros via Mata [8]
			}
			mata : st_global("r(stderr)", strtrim(invtokens(`R'')))  // return the stderr on one line
			capture mata : mata drop `R' `n'               // drop the unneeded vector and scalar [9]
			return local errln = `rows'                        // return the number of non-blank rows
			return add                                     // add r() globals set from Mata to return
			if (missing("`errorcode'")) local errorcode "?"        // set errorcode to "?" if missing

			// display the standard error and return code *******************************************
			if ((`maxdlen') <= (`= c(linesize) - min(`: strlen local errorcode', 2) - 9')) {
				if (`: strlen local errorcode' < 2) {
					local rcbox = `: strlen local errorcode' + 3
					local pad     " "
				}
				else {
					local rcbox = `: strlen local errorcode' + 2
				}
				local errbox  = `maxdlen' + 2
				local s       = "space `= c(linesize) - `errbox' - `rcbox' - 4'"
				local s1      = "space `= `errbox' - udstrlen(scalar(`E'1)) - 2'"
				local rchl    = "hline `= cond(`: strlen local errorcode' > 2, 1, 0)'"
				local errhl   = "hline `= `errbox' - 8'"
				if (`displayrows' >= 2) {
					forvalues i = 2 / `displayrows' {
						local s`i' = `maxdlen' - udstrlen(scalar(`E'`i'))
						local error_box`i' _n "{c |} " _asis scalar(`E'`i') in smcl " {space `s`i''}{c |}"
						if (`i' == 2) {
							local error_box`i' `"`macval(error_box`i')' "{`s'}{c BLC}{`rchl'}{it: rc }{c BRC}""'
						}
						local error_box_total `"`macval(error_box_total)' `macval(error_box`i')'"'
					}
					display as error ///
						"{c TLC}{hline `errbox'}{c TRC}{`s'}{c TLC}{hline `rcbox'}{c TRC}" _n "{c |} " _continue
					display _asis as error ///
						return(err1) _continue
					display as error ///
						" {`s1'}{c |}{`s'}{c |} {bf:`pad'`errorcode'} {c |}"  ///
						`macval(error_box_total)'                             ///
						_n "{c BLC}{it: stderr }{`errhl'}{c BRC}"
				}
				else if (`displayrows' == 1) {
					display as error ///
						"{c TLC}{hline `errbox'}{c TRC}{`s'}{c TLC}{hline `rcbox'}{c TRC}" _n "{c |} " _continue
					display _asis as error ///
						return(err1) _continue
					display as error ///
						" {c |}{`s'}{c |} {bf:`pad'`errorcode'} {c |}" _n  ///
						"{c BLC}{it: stderr }{`errhl'}{c BRC}{`s'}{c BLC}{`rchl'}{it: rc }{c BRC}"
				}
			}
			else {
				if (!missing(return(stderr))) {
					display as error ///
						"`p'" _asis return(stderr) in smcl "{p_end}"
					local pad    = cond(`: strlen local errorcode' == 1, " ", "")
					local rcline =  max(`: strlen local errorcode' - 2, 0)
					local rcbox  = `rchl' + 4
					display as error ///
							 "{right:{c TLC}{hline         `rcbox'}{c   TRC}}"  ///
						_n "{right:{c   |}{bf: `pad'`errorcode' }{c     |}}"  ///
						_n "{right:{c BLC}{hline `rcline'}{it: rc }{c BRC}}"
				}
			}
		}
		return local rc "`errorcode'"
	}

	// display the return code if there is no standard error ************************************
	if ((!missing("`errorcode'")) & (missing(return(stderr)))) {
		if ("`errorcode'" != "0") {
			local pad    = cond(`: strlen local errorcode' == 1, " ", "")
			local rcline =  max(`: strlen local errorcode' - 2, 0)
			local rcbox  = `rchl' + 4
			display as error ///
				   "{right:{c TLC}{hline        `rcbox'}{c TRC}}"     ///
				_n "{right:{c   |}{bf: `pad'`errorcode' }{c |}}"      ///
				_n "{right:{c BLC}{hline `rcline'}{it: rc }{c BRC}}"
		}
	}
}

// display a message for a long shell command *************************************************
if (("`parser'" == "command") & ("`parser2'" == "longcmd")) {
	display as text ///
		   "{c TLC}{hline 73}{c TRC}"                                                                  ///
		_n "{c |} >>>  This is not an error. The command you have entered is very long.   {c |}"       ///
		_n "{c |} >>> You are probably better off storing this set of commands in a shell {c |}"       ///
		_n "{c |} >>> script and then executing that script file using {bf:inshell} as found   {c |}"  ///
		_n "{c |} >>> in syntax (3) in the help file: " `"[{help inshell##suggestions: help inshell: Suggestions }]{space 7}{c |}"'  ///
		_n "{c BLC}{hline 73}{c BRC}"
}

// refocus ************************************************************************************
//   bring the Command window into focus to aid interactive use, as the shell's actions can
//  potentially shift it away
if (missing("${INSHELL_DISABLE_REFOCUS}")) {
	if ((missing(c(console))) & (c(mode) != "batch")) {
		if (lower(c(os)) != "windows") capture window manage forward command
		if (lower(c(os)) == "windows") capture window manage forward results
		// on Windows the Results window must be called instead, oddly enough
		// this was tested with StataSE 17 on Windows 10
	}
}

end

version 14
mata:

void inshell_syntax_parser()
{
  string colvector   dirs, diag, cd, blocked, userblocked

  st_local("parser2", "empty")

  diag        = ("diag" \ "diagn" \ "diagno" \ "diagnos" \ "diagnost" \ "diagnosti" \ "diagnostic" \ "diagnostics")
  cd          = ("cd" \ "chdir")
  blocked     = ("emacs" \ "htop" \ "links" \ "lynx" \ "micro" \ "top" \ "vim" \ "yes")
  userblocked = tokens(st_global("INSHELL_BLOCKEDCMDS"))'

  if (anyof(blocked, st_local("1"))) {
    st_local("parser", "blocked")
  }
  else if (anyof(userblocked, st_local("1"))) {
    st_local("parser", "userblocked")
  }
  else if (anyof(diag, st_local("1"))) {
    st_local("parser", "diagnostics")
  }
  else if (anyof(cd, st_local("1"))) {
    st_local("parser", "cd")
  }
  else if (!anyof((cd \ diag \ blocked \ userblocked), st_local("1"))) {
    if (st_global("INSHELL_ENABLE_AUTOCD") == "") {
      st_local("parser", "command")
      if ((strlen(st_local("0")) >= 300) & (st_global("INSHELL_DISABLE_LONGCMDMSG") == "")) {
        st_local("parser2", "longcmd")
      }
    }
    else if (st_global("INSHELL_ENABLE_AUTOCD") != "") {
      dirs = dir(".", "dirs", "*")
      if (anyof(dirs, st_local("1"))) {
        st_local("parser", "autocd")
      }
      else if (!anyof(dirs, st_local("1"))) {
        st_local("parser", "command")
        if ((strlen(st_local("0")) >= 300) & (st_global("INSHELL_DISABLE_LONGCMDMSG") == "")) {
          st_local("parser2", "longcmd")
        }
      }
    }
  }
  else {
    st_local("parser", "other")
  }
}

string colvector inshell_capture_format(string scalar file, | real scalar tabsize)
{
	real scalar         i
	string scalar       ansi
	string colvector    X, Y

	ansi = char(27) + "\[[^@-~]*[@-~]"
	X    = cat(file)
	for (i=1; i<=rows(X); i++) {
		if (tabsize != J(1, 1, .)) {
			X[i] = subinstr(X[i], char(9), char(32) * tabsize, .)
		}
		if (st_global("INSHELL_DISABLE_ANSI") == "") {
			while (regexm(X[i], ansi)) {
				X[i] = regexr(X[i], ansi, "")
			}
		}
	}
	Y = select(X, X :!= "")
	st_local("maxdlen", strofreal(max(udstrlen(Y))))
	st_local("rows", strofreal(rows(Y)))
	return(X)
}

void inshell_chdir(string scalar directory)
{
	string scalar     shelldir, cdtemp, s_shell

	if (direxists(directory)) {
		if (_chdir(directory) == 0) {
			st_local("cdsuccess", "1")
		}
		else {
			st_local("cdsuccess", "0")
			errprintf(" >>> there was an error in changing to the specified directory\n")
		}
	}
	else if (!direxists(directory)) {
		stata(sprintf("shell echo %s > %s", directory, cdtemp = st_tempfilename()), 1, 1)
		shelldir = cat(cdtemp)
		if (shelldir != "") {
			if (direxists(shelldir)) {
				if (_chdir(shelldir) == 0) {
					st_local("cdsuccess", "1")
				}
				else {
					st_local("cdsuccess", "0")
					errprintf(" >>> there was an error in changing to the specified directory\n")
				}
			}
			else if (!direxists(shelldir)) {
				st_local("cdsuccess", "0")
				errprintf(" >>> the directory {res:%s} does not exist\n", directory)
			}
		}
		else if (shelldir == "") {
			errprintf("`p' >>> there is no directory stored within the shell variable {res:%s}, according to the current environment", directory)
			s_shell = st_global("S_SHELL")
			if (s_shell != "") {
				errprintf(". This is likely the result of specifying an alternative shell within global macro {bf:S_SHELL}, which is currently set to: {res}%s\n", s_shell)
			}
			st_local("cdsuccess", "0")
		}
	}
	st_local("pwd", pwd())
}

end

/* Footnotes **********************************************************************************

[1] Clearing the -return list- using this Mata function will clear anything previously stored in r() after the command is executed. Therefore, macros left in r() from a previous command can be referenced once and only once by -inshell-; afterward they will be cleared and replaced by the -return- from -inshell-. It is necessary to use -st_rclear()- because creating r() globals via Mata to add to -return- requires using -return add-, which will overwrite but not clear -return-. It is not to be confused with -return clear-. Without clearing -return- in this way, subsequent -inshell- commands that output more lines of stdout or stderr than the previous -inshell- command would not see those additional lines removed

[2] In order to implement additional functionality such as the -cd- wrapper, diagnostic routine, and measurement of command length, the syntax must be parsed in Mata in case it contains unbalanced quoting. Even more importantly, omission of the -syntax- line is necessary, as commands issued to the shell could possibly contain strings of characters that mimic or approximate Stata macro dereferencing structures, and could result in a -syntax- error. The last version of -inshell- containing a -syntax- line used:
		syntax anything (everything equalok) [, * ]
	which is the most permissive, though a -capture- can also be added

[3] Storing the command sent to -inshell- after macro parsing (and immediately adding it to -return-) allows the user to debug their commands

[4] The user is allowed to specify whether or not horizontal tabs (ASCII character code 9) are converted into spaces (ranging in number from 1 to 8) or to be left as is. Leaving horizontal tabs in place will ensure a more accurate display of output, however the user must note that these tabs occupy only one character space

[5] Although these these names are set via -tempname-, they will remain in Mata after the program concludes, so they are later dropped, as in [9]

[6] -display(sprintf( ), 1)- must be used here, as -printf()- will interpret SMCL directives. The 1 option to -display()- disables interpreting SMCL directives. This is the only available method to accurately print the captured (and formatted) column vector of lines of stdout or stderr exactly as they are found in -return-, minus any invisible characters (ASCII character codes 0-27)

[7] A new string column vector containing only non-blank lines must be created because blank lines cannot be stored as macros in -return-

[8] Creating r() globals from Mata directly from the string column vector where they are stored ensures that no macro expansion will occur and that they will be copied exactly

[9] Although items with -tempname-s should disappear after the program has completed, these two items would otherwise remain and thus need to be dropped

[10] -fileread()- can be used here, since the file containing the return code is very simple. However, for some unknown reason, the Unicode version of the -strtrim()- function (-ustrtrim()-) must be used

[11] The temporary string scalars created via Mata are used in the display of the stderr and its "theme." It is necessary to use string scalars for this purpose because they can store empty lines, unlike macros in -return()-. They are used in line 333 in the creation of the lines of the error display box because of this property. This is the raionale behind creating a new string colvector using -select(X, X := "")-; this new string colvector contains only the lines that are possible to -return- in r()

**********************************************************************************************/
