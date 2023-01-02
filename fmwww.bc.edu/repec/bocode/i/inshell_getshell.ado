*! 1.3 MBH Dec 29  2022
*! this program determines which shell is in use by Stata and displays it along with its version info
**!  a) includes minor coding refinements
**!  b) in additon to the shell versions tested in the Sept 8 2022 revision, this
**!      program has now been tested with:
**!     bash (5.2.15)
**!     dash (0.5.12)
**!     ksh93 (93u+m/1.0.4 2022-10-22)
**!     Microsoft PowerShell (7.3.1)
**!     oksh (5.2.14 99/07/13.2)
**!     oil (0.13.1)
**!     tcsh (6.24.07)
**! 1.2  MBH 15 Oct 2022
**!     updated for inshell version 2.6
**! 1.1  MBH  8 Sept 2022
**!  a) ksh is identified by the presense of a "ksh" string rather than
**!      a string equal to "ksh," primarily for users of ksh93
**!  b) better handling of version strings
**!   this program has now been tested with:
**!     bash (3.2.57 and 5.1.16)
**!     dash (0.5.11.5, though the shell does not report version numbers)
**!     ksh (93u+ 2012-08-01)
**!     ksh93 (93u+m/1.0.3 2022-08-25)
**!     mksh (R59 2020/10/31)
**!     oil (0.12.5)
**!     Microsoft PowerShell (7.2.6)
**!     tcsh (6.21.00 and 6.24.01)
**!     yash (2.53)
**!     zsh (5.9 and 5.7.1)
**! 1.0  MBH 11 July 2022

program define inshell_getshell, rclass
version 14

// detect whether Stata is using PowerShell ***************************************************
capture which inshell_detect_pwsh
if (!_rc) {
  inshell_detect_pwsh
  if (!missing(r(pwsh_detected))) {
    return add
    exit 0
  }
}

// obtain the shell's location ****************************************************************
if (!missing("${S_SHELL}")) {
  local shell_location   : word 1 of ${S_SHELL}
  local method           "S_SHELL"
}
else if (missing("${S_SHELL}")) {
  local shell_location   : environment SHELL
  local method           "default"
}
if (!missing("`shell_location'")) {
  local shell = substr("`shell_location'", strrpos("`shell_location'", "/") + 1, .)
}
else if (missing("`shell_location'")) {
  display as error ///
    " >>> your shell's path could not be determined"
  exit 1
}
if (strpos("`shell_location'", "//")) {
  local shell_location = subinstr("`shell_location'", "//", "/", .)
}
if ("`shell_location'" == "`: environment SHELL'") local check "✅"

// obtain the shell's version *****************************************************************
local version_file        "`c(tmpdir)'inshell_sh_version_`= clock(c(current_time), "hms")'`= runiformint(1, 99999)'.txt"
capture quietly erase     "`version_file'"
if ("`shell'" == "bash") {
  quietly shell echo \$BASH_VERSION > "`version_file'"
}
else if (inlist("`shell'", "oil", "osh")) {
  quietly shell echo \$OIL_VERSION > "`version_file'"
}
else if ("`shell'" == "sh") {
  quietly shell echo $($0 --version) > "`version_file'"
}
else if ("`shell'" == "yash") {
  quietly shell echo \$YASH_VERSION > "`version_file'"
}
else if ("`shell'" == "zsh") {
  quietly shell echo \$ZSH_VERSION > "`version_file'"
}
else if (strpos("`shell'", "ksh")) {
  quietly shell echo \$KSH_VERSION 2> "`version_file'" 1> "`version_file'"
}
else if (inlist("`shell'", "csh", "tcsh")) {
  quietly shell echo \$tcsh > "`version_file'"
}

// clean the shell's version ******************************************************************
if (inlist("`shell'", "ash", "dash")) {
  local shell_version_pure "{it:(not available in`= cond("`shell'" == "dash", " Debian", "")' Almquist shell)}"
}
if (!inlist("`shell'", "ash", "dash")) {
  mata : st_local("shell_version2", cat("`version_file'")[1])
}
if (inlist("`shell'", "sh", "bash", "csh", "oil", "osh", "tcsh", "yash", "zsh")) {
  local shell_version_pure         : word 1 of `shell_version2'
  if ("`shell'" == "bash") {
    local shell_version_pure = substr("`shell_version_pure'", 1, `= strpos("`shell_version_pure'", "(") - 1')
  }
  return local shell_version_pure  "`shell_version_pure'"
}
if (strpos("`shell'", "ksh")) {
  local shell_version2 = trim(regexr("`shell_version2'", "sh (AT&T Research)|Version [AJM?]*|.*KSH *v|.*KSH", ""))
  local shell_version_pure  "`shell_version2'"
}
local version_text = cond(inlist("`shell'", "ash", "dash"), "text", "result")

local s1 "space 2"
display ///
  as text        _n " >>> {it}your current shell is{sf}"        ///
  as result         "{`s1'}`shell'"                         _n  ///
  as text           "{it}{space 7}which is at version{sf}"      ///
  as `version_text' "{`s1'}`shell_version_pure'"            _n  ///
  as text           "{it}{space 9}and is located at{sf}"        ///
  as result         "{`s1'}`shell_location' `check'"        _n

return local shell            "`shell'"
return local shell_location   "`shell_location'"
return local shell_version    "`shell_version2'"
return local method           "`method'"

capture quietly erase "`version_file'"

end
