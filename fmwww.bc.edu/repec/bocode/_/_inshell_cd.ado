*! 1.1    MBH 16 June 2022
*!    completely streamlined, only for use with inshell 1.7
*! 1.0.1  MBH 13 June 2022
*! 		minor revisions
*! 1.0    MBH 27 May 2022
*!   	this program is a wrapper for -cd- and is a subprogram of the shell
*!   wrapper package -inshell-
*!   	its usefulness is found primary in its ability to -cd- to paths set by
*!   shell variables

capture program drop _inshell_cd

program define _inshell_cd, rclass
version 13
syntax [ anything (name=directory) ]

if missing(`"`macval(0)'"') {
	capture quietly cd
	if !_rc {
		noisily pwd
		return local no = 1
		return local no1 "`c(pwd)'"
		return local rc = 0
		exit 0
	}
}
if !missing("`macval(directory)'") {
	capture scalar drop direxist
	mata : st_numscalar("direxist", direxists("`macval(directory)'"))
	if scalar(direxist) == 1 {
		quietly capture cd `macval(directory)'
		if !_rc {
			noisily pwd
			return local no = 1
			return local no1 "`c(pwd)'"
			return local rc = 0
			scalar drop direxist
			exit 0
		}
	}
	else if scalar(direxist) != 1 {
		// this section is meant for -cd-ing to a directory that has been set as a shell variable
		// dollar signs still need to be escaped
		tempfile cdtempfile
		quietly shell echo "`macval(directory)'" > "`cdtempfile'"
		local cdtemp = subinstr(strtrim(fileread("`cdtempfile'")), char(10), "", .)
		quietly capture cd "`cdtemp'"
		if !_rc {
			noisily pwd
			return local no = 1
			return local no1 "`c(pwd)'"
			return local rc = 0
			scalar drop direxist
			exit 0
		}
		else if _rc {
			display as error ///
			">>> the directory " as result "`macval(directory)'" as error " is invalid. Please try again." ///
			_n ">>> the current directory is " as result "`c(pwd)'"
			scalar drop direxist
			exit 170
		}
	}
}

end
