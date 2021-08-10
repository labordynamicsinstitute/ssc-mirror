

 prog drop _all
 program define cnstock
 version 14.0
 syntax anything(name=exchange), [ path(string)]

 clear  
 set more off


	if "`path'"~="" {
			capture mkdir `path'
			} 
                                   
	if "`path'"=="" {
			local path `c(pwd)'
	        disp "`path'"
			} 
	if index("`path'"," "){
			local path=subinstr("`path'"," ","_",.)
			capture mkdir `path'
			}
	if "`exchange'"== "all" {
			local exchange SHA SZM SZSM SZGE SHB SZB
			}
 foreach name in `exchange'{
	if "`name'" == "SHA" local c "11"
	else if "`name'" == "SZM" local c "12"
	else if "`name'" == "SZSM" local c "13"
	else if "`name'" == "SZGE" local c "14"
	else if "`name'" == "SHB" local c "15"
	else if "`name'" == "SZB" local c "16"
	else {
		disp as error `"`name' is an invalid exchange"'
		exit 601
         }
  

quietly {
	infix strL v 1-100000 using "http://quote.cfi.cn/stockList.aspx?t=`c'",clear
	keep if index(v,"<div id='divcontent' runat=")
	split v,p("</a></td>")
	drop v
	
	gen id=_n
	cap reshape long v, i(id) j(vv) 
	drop id vv
	rename v _var1
	format _var1 %100s
	split _var1,p(`"">"')
	gen v = 1 if index(_var12,"国债")
	gen v1 = sum(v)
	drop if v1 != 0 
	drop v v1 
	split _var12,p("(")
	replace _var122 = subinstr(_var122,")","",.)
	drop _var1 _var11 _var12 
	rename _var121 stknm
	rename _var122 stkcd
	destring stkcd,replace
	format stkcd %06.0f
	drop if stkcd == .
	save `path'/`name'.dta,replace
	}
	}
clear
foreach name in `exchange' {
	append using `path'/`name'.dta
	erase `path'/`name'.dta
	}
 
 label var stkcd stockcode
 label var stknm stockname
 di "You've got the stock names and stock codes from `exchange'"
 
 save `path'/cnstock.dta,replace
 
 end
