*! 1.0.0  MBH 11 July 2022
*!	this program determines which shell is in use by Stata
*!   and displays it along with its version info

capture program drop inshell_getshell

program define inshell_getshell, rclass

version 14

// detect whether Stata is using PowerShell
capture which inshell_detect_pwsh
if (!_rc) {
  inshell_detect_pwsh
  if !missing("`r(pwsh_detected)'") {
    return add
    exit 0
  }
}

// obtain the shell's location
if !missing("${S_SHELL}") {
  local shell_location   "`: word 1 of ${S_SHELL}'"
  local method           "S_SHELL"
}
else if missing("${S_SHELL}") {
  local shell_location   "`: environment SHELL'"
  local method           "default"
}
if !missing("`shell_location'") {
  local shell = substr("`shell_location'", strrpos("`shell_location'", "/") + 1 , .)
}
else if missing("`shell_location'") {
  exit 1
}
// obtain the shell's version
local version_file        "`c(tmpdir)'inshell_sh_version_`= clock("`c(current_time)'", "hms")'`= runiformint(1, 99999)'.txt"
capture quietly erase     "`version_file'"
if inlist("`shell'", "sh", "bash", "ksh", "oil", "osh", "yash", "zsh") {
  capture quietly shell `shell_location' --version > "`version_file'" 2>&1
}
else if inlist("`shell'", "csh", "tcsh") {
  capture quietly shell (`shell_location' --version > "`version_file'") >& "`version_file'"
}
// clean the shell's version
else if inlist("`shell'", "ash", "dash") {
  local shell_version_pure "(not available in`= cond("`shell'" == "dash", " Debian", "")' Almquist shell)"
}
if !inlist("`shell'", "ash", "dash") {
  tempname shvers
  mata : st_strscalar("`shvers'", inshell_process_file("`version_file'")[1])
  if scalar(`shvers') != "" {
    local shell_version = trim(substr("`= subinstr(trim(itrim(scalar(`shvers'))), "version", "@", .)'",  `= strpos("`= subinstr(trim(itrim(scalar(`shvers'))), "version", "@", .)'", "@") + 1', .))
    if strpos("`shell_version'", "`shell'") {
      local shell_version2 = trim(substr(subinstr("`shell_version'", "`shell'", "@", 1), `= strpos("`shell_version'", "@") + 2', .))
    }
    else local shell_version2 "`shell_version'"
  }
}
if inlist("`shell'", "sh", "bash", "csh", "ksh", "oil", "osh", "tcsh", "yash", "zsh") {
  local shell_version_pure         "`: word 1 of `shell_version2''"
  if "`shell'" == "bash" {
    local shell_version_pure = substr("`shell_version_pure'", 1, `=strpos("`shell_version_pure'", "(") - 1')
  }
  return local shell_version_pure  "`shell_version_pure'"
}
if strpos("`shell'", "ksh") {
  local shell_version2 = trim(itrim(subinstr("`shell_version2'", "sh (AT&T Research)", "", .)))
  return local shell_version_pure  "`shell_version2'"
}

local s1 2
if strpos("`shell_location'", "//") {
  local shell_location = subinstr("`shell_location'", "//", "/", .)
}
if "`shell_location'" == "`: environment SHELL'" {
  local check "✅"
}

local version_text = cond(inlist("`shell'", "ash", "dash"), "text", "result")

noisily display ///
  as text           " >>> {it}your default shell is{sf}"        ///
  as result         "{space `s1'}`shell'"                   _n  ///
  as text           "{it}{space 7}which is at version{sf}"      ///
  as `version_text' "{space `s1'}`shell_version_pure'"      _n  ///
  as text           "{it}{space 9}and is located at{sf}"        ///
  as result         "{space `s1'}`shell_location' `check'"  _n

return local shell            "`shell'"
return local shell_location   "`shell_location'"
return local shell_version    "`shell_version2'"
return local method           "`method'"

capture quietly erase "`version_file'"

end
