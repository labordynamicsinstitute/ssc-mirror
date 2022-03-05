*! proprstr.ado	Version 1.0	RL Kaufman	10/4/2017

***		1.0 Makes Proper names, abbrevates to ABREVN characters 
***			pads short strings with blanks front (1/4) & back(3/4)
***			Called by DEFINEFM
***		1.1  Stopped making it proprer case

program proprstr, rclass
version 14.2
args instr abbrevn pad
loc outstr= abbrev(strtoname("`instr'",0),`abbrevn')
if "`pad'" == "pad" {
	loc slng =strlen("`outstr'")
	loc blank="          "
	if `slng' +1 < `abbrevn' {
	loc hold = "`outstr'"
	loc n1= round((`abbrevn'-`slng')/4)
	loc n2= `abbrevn'-`slng'-`n1'
	loc outstr=substr("`blank'",1,`n1')+"`hold'"+substr("`blank'",1,`n2')
	}
}
return local padded `"`outstr'"'
end
