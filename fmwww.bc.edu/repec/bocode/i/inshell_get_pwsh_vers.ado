*! 1.3 MBH 27 Dec 2022
*! this program obtains the version info from Microsoft PowerShell
**!  this version contains numerous small coding refinements
**! 1.2 MBH  29 Nov  2022
**! 1.1 MBH  15 Oct  2022
**!  updated for -inshell- version 2.6
**! 1.0 MBH  14 July 2022

program define inshell_get_pwsh_vers, rclass
version 14
syntax anything (name=location)

local outfile          "`c(tmpdir)'inshell_pwsh_version_`= clock(c(current_time), "hms")'`= runiformint(1, 99999)'.txt"
capture quietly erase  "`outfile'"
capture quietly shell   \$PSVersionTable.PSVersion > "`outfile'"
capture confirm file   "`outfile'"
if (!_rc) {
  local filereadtest = fileread("`outfile'")
}
if (!missing("`filereadtest'")) {
  tempname P rows line
  mata : `P' = subinstr(stritrim(strtrim(cat("`outfile'"))), " ", ".")
  mata : st_numscalar("`rows'", rows(`P'))
  forvalues i = 1 / `= scalar(`rows')' {
    mata : st_strscalar("`line'`i'", strtrim(`P'[`i']))
    if (regexm(scalar(`line'`i'), "^[0-9]")) {
      local version = scalar(`line'`i')
    }
  }
  capture mata : mata drop `P'
  local s        "space 2"
  display ///
    as text     _n " >>> {it}your current shell is{sf}"        ///
    as result      "{`s'}Microsoft PowerShell (pwsh)"      _n  ///
    as text        "{it}{space 7}which is at version{sf}"      ///
    as result      "{`s'}`version'"                        _n  ///
    as text        "{it}{space 9}and is located at{sf}"        ///
    as result      "{`s'}`location' `check'"               _n
}
else if (missing("`filereadtest'")) {
  display as error ///
    _n "{p 2 1} >>> {bf:Microsoft PowerShell} was not determined to be the shell when using Stata on this system."
  return local pwsh_notdetected 1
}

return local shell_version "`version'"
capture quietly erase      "`outfile'"

end
