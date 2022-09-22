*! 1.0 MBH 14 July 2022
*!   this program obtains the version info from
*!    Microsoft PowerShell

capture program drop inshell_get_pwsh_vers

program define inshell_get_pwsh_vers, rclass

version 14
syntax anything (name=location)

local outfile          "`c(tmpdir)'inshell_pwsh_version_`= clock("`c(current_time)'", "hms")'`= runiformint(1, 99999)'.txt"
capture quietly erase  "`outfile'"
capture quietly shell   \$PSVersionTable.PSVersion > "`outfile'"
capture confirm file   "`outfile'"
if (!_rc) {
  local filereadtest = fileread("`outfile'")
}
if (!missing("`filereadtest'")) {
  mata : P = subinstr(stritrim(strtrim(inshell_process_file("`outfile'"))), " ", ".")
  mata : st_numscalar("rows", rows(P))
  forvalues i = 1 / `= scalar(rows)' {
    mata : st_strscalar("line`i'", strtrim(P[`i']))
    if (regexm("`= scalar(line`i')'", "^[0-9]")) {
      local version   "`= scalar(line`i')'"
    }
    capture scalar drop line`i'
  }
  capture scalar drop rows
  local s1 2
  noisily display ///
    as text     _n " >>> {it}your default shell is{sf}"          ///
    as result      "{space `s1'}Microsoft PowerShell (pwsh)"        _n  ///
    as text        "{it}{space 7}which is at version{sf}"        ///
    as result      "{space `s1'}`version'"                   _n  ///
    as text        "{it}{space 9}and is located at{sf}"          ///
    as result      "{space `s1'}`location' `check'"          _n
}
else if (missing("`filereadtest'")) {
  noisily display ///
    as error ///
      _n " >>> Microsoft PowerShell was not determined to be the shell when using Stata on this system."
  return local pwsh_notdetected 1
}

return local shell_version "`version'"
capture quietly erase      "`outfile'"
capture mata mata drop P

end
