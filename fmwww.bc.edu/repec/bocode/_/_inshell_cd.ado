*! 1.0   MBH 27 May 2022
*!   	this program is a wrapper for -cd- and is a subprogram of the shell
*!   wrapper package -inshell-
*!   	its usefulness is found primary in its ability to -cd- to paths set by
*!   shell variables

capture program drop _inshell_cd

program define _inshell_cd, rclass
	version 9
	syntax [, home DIRectory(string) ]

	capture scalar drop direxist
	if "`macval(directory)'" != "" & "`home'" == "" {
		mata : st_numscalar("direxist", direxists("`macval(directory)'"))
		if scalar(direxist) == 1 {
			quietly capture cd `"`macval(directory)'"'
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
			quietly shell echo `macval(directory)' > "`cdtempfile'"
			local cdtemp = ustrtrim(fileread("`cdtempfile'"))
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
	else if "`home'" != "" & "`macval(directory)'" == "" {
		if c(os) != "Windows" {
			// cd to Home directory
			quietly capture cd "`:environment HOME'"
			if _rc quietly capture cd ~
			if !_rc {
				noisily pwd
				return local no = 1
				return local no1 "`c(pwd)'"
				return local rc = 0
				exit 0
			}
			else {
				display as error ///
					">>> {bf:inshell} could not {bf:cd} to the Home directory" ///
					_n ">>> please check that " as result "`:environment HOME'" as error " is your Home directory"
				return local no = 0
				return local rc = 0
				exit 170
			}
		}
		if c(os) == "Windows" {
			// -cd- without arguments on Windows is equivalent to -pwd-
			noisily pwd
			return local no = 1
			return local no1 "`c(pwd)'"
			return local rc = 0
			exit 0
		}
	}
	else if missing("`home'", "`macval(directory)'") | ("`home'" != "" & "`macval(directory)'" != "") {
		display as error ///
			">>> you have either specified both options or neither of them. this is invalid"
	}

end
