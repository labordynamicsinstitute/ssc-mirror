*! 1.0.0 MBH 30 December 2021

program define inshell, rclass
version 10.0
syntax anything (everything equalok) , ///
[ Lines(numlist min=1 max=1 >=0 <=`c(max_macrolen)') ]

if "`c(os)'" == "Windows" & "`c(mode)'" == "batch" {
		display as error "inshell will not function in batch mode on Windows. This is a Stata limitation."
		exit 1
}

tempfile stdout stderr rc
tempname out err c

! `macval(anything)' 2> `stderr' 1> `stdout' || echo $? > `rc'

file open `err' using `stderr', read
file seek `err' eof
file seek `err' query
local is_err = r(loc)
file close `err'

if `is_err' == 0 {
  file open `out' using "`stdout'", read
  file read `out' line
  local ln = 0
  while r(eof) == 0 {
    local ln = `ln' + 1
		return local no`ln' = `"`macval(line)'"'
    file read `out' line
  }
	return local no = `ln'
  file close `out'
  if "`lines'" != "" {
		local printlines = `lines'
	}
  else local printlines = `ln'
  if `printlines' != 0 {
    type "`stdout'", lines(`printlines')
  }
  return local rc = 0
}
else if `is_err' > 0 {
      local errormessage = ustrrtrim(fileread("`stderr'"))
      if "`errormessage'" != "" {
          display as error "`errormessage'"
      }
      local errorcode = ustrrtrim(fileread("`rc'"))
      if "`errorcode'" != "" {
          display as error "return code: `errorcode'"
      }
  return local rc = "`errorcode'"
  return local no = 0
}

end
