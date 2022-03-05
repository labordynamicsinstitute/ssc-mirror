*! ctrstr.ado	Version 1.0		RL Kaufman	7/07/2016

program ctrstr, rclass
version 14.2
syntax , instr(string) length(integer)
loc outstr "`instr'"
loc slng =strlen("`instr'")
loc blank="                "
if `slng' < `length' {
loc n1= round((`length'-`slng')/2)
loc n2= `length'-`slng'-`n1'
loc outstr=substr("`blank'",1,`n1')+"`instr'"+substr("`blank'",1,`n2')
}
return local padded= `"`outstr'"'
end
