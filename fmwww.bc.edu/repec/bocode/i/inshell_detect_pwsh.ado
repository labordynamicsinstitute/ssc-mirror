*! 1.0 MBH 14 July 2022
*!   this program determines whether PowerShell
*!    is in use by Stata


capture program drop inshell_detect_pwsh

program define inshell_detect_pwsh, rclass
version 14

// if PowerShell is set by S_SHELL
if strpos("${S_SHELL}", "pwsh") {
  inshell_get_pwsh_vers          `: word 1 of ${S_SHELL}'
  return local shell_location   "`: word 1 of ${S_SHELL}'"
  return local pwsh_detected    1
  return local shell_version    "`r(shell_version)'"
  return local shell            "pwsh"
  return local method           "S_SHELL"
  exit 0
}
// if PowerShell is not set by S_SHELL but is the system default
else if !strpos("${S_SHELL}", "pwsh") & strpos("`: environment SHELL'", "pwsh") {
  inshell_get_pwsh_vers          `: environment SHELL'
  return local shell_location   "`: environment SHELL'"
  return local pwsh_detected    1
  return local shell_version    "`r(shell_version)'"
  return local shell            "pwsh"
  return local method           "default"
  exit 0
}
else {
  return local pwsh_notdetected  1
}

end