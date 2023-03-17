* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Xiuping Mao, Ph.D. , China Stata Club(爬虫俱乐部)(xiuping_mao@126.com)
* Tianyao Luo, China Stata Club(爬虫俱乐部)(cnl1426@163.com)
* November 21st, 2022
* Updated on Mar 20th, 2023
* Program written by Dr. Chuntao Li and Tianyao Luo
* Downloads historical stock transaction records for Hong Kong listed companies.
* Can only be used in Stata version 17.0 or above

capture program drop hktrade
program define hktrade
	clear all
	version 17.0
	set maxvar 120000 	
	set max_memory .
	
	qui cap findfile sxpose.ado
	if  _rc>0 {
                disp as error "command sxpose is unrecognized,you need "ssc install sxpose" "
                exit 601
        }

		
	if _caller() < 17.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
		exit 9
	}

	syntax anything(name = list), [fqt(string) path(string)]
	

	if `"`path'"' != "" {
		cap mkdir `"`path'"'
	} 

	else {
		local path `"`c(pwd)'"'
        disp `"`path'"'
	}
	
	if `"`fqt'"' == "" {
		local klt "101"
	} 

	if `"`fqt'"' == "w"|`"`fqt'"' == "W" {
		local klt "102"
	} 
	
	if `"`fqt'"' == "m"|`"`fqt'"' == "M"  {
		local klt "103"
	} 
	
	local address "http://97.push2his.eastmoney.com/api/qt/stock/kline/get?secid=116." 
	local t_add "&fields1=f1%2Cf2%2Cf3%2Cf4%2Cf5%2Cf6&fields2=f51%2Cf52%2Cf53%2Cf54%2Cf55%2Cf56%2Cf57%2Cf58%2Cf59%2Cf60%2Cf61&klt=`klt'&fqt=0&end=20500101&lmt=10000&_="
	
	tempfile temp
	
	foreach code in `list' {
                
					qui{											
										
	
							if length("`code'") >5 {
                                        disp as error `"`code' is an invalid stock code"'
                                        exit 601
                                } 
							while length("`code'") < 5 {
                                        local code = "0" + "`code'"
										}
								local real_time=(clock("`c(current_date)' `c(current_time)'", "DMY hms" )/1000 - clock("2 Jan 1970", "DMY" )/1000+57600)*1000+int(43*runiform() )
								local url "`address'`code'`t_add'`real_time'"
								copy "`url'" temp.txt,replace
								set obs 1
								gen v =fileread("temp.txt")									
								if length(v) < 2500{
												disp as error `"`code' is an invalid stock code"'
												exit 601
													}  	
								replace v = ustrregexs(0) if ustrregexm(v, `"\"klines\"\:\[.*?\]\}\}"')
								
								
								if ustrregexm(v, `"","2004-"'){
										replace v = ustrregexs(0) if ustrregexm(v, `"","2004-(.*)"')
										cap split v,p(`"",""')
										drop v
										sxpose,clear
										replace _var1=subinstr(_var1,"]}}","",.)
										replace _var1=subinstr(_var1,`""klines":"',"",.)
										replace _var1=subinstr(_var1,`"[""',"",.)
										replace _var1=subinstr(_var1,`"""',"",.)
										
										
										
										split _var1,p(",")
										drop _var1
										rename _all (date open close high low volume Turnover amplitude price_limit change_amount turnover_rate)


										gen time= date(date,"YMD")
										format %dCY-N-D time
										order time
										drop date
										destring _all,replace
										compress
										save "2004", replace
										
										clear
										local real_time=(clock("`c(current_date)' `c(current_time)'", "DMY hms" )/1000 - clock("2 Jan 1970", "DMY" )/1000+57600)*1000+int(43*runiform() )
										local url "`address'`code'`t_add'`real_time'"
										copy "`url'" temp.txt,replace
										copy "`url'" temp.txt,replace
										set obs 1
										gen v =fileread("temp.txt")
										replace v = ustrregexs(0) if ustrregexm(v, `"\"klines\"\:\[.*?\]\}\}"')
										replace v = ustrregexs(0) if ustrregexm(v, `"(.*)","2003-"')
										cap split v,p(`"",""')
										drop v
										sxpose,clear
										replace _var1=subinstr(_var1,"]}}","",.)
										replace _var1=subinstr(_var1,`""klines":"',"",.)
										replace _var1=subinstr(_var1,`"[""',"",.)
										replace _var1=subinstr(_var1,`"""',"",.)
										
										
										
										split _var1,p(",")
										drop _var1
										rename _all (date open close high low volume Turnover amplitude price_limit change_amount turnover_rate)


										gen time= date(date,"YMD")
										format %dCY-N-D time
										order time
										drop date
										destring _all,replace
										compress
										
										cap append using 2004.dta
										cap erase 2004.dta
										noi disp as text `"file `code'_trade.dta has been generated"'
								}
								
								else{
										
										cap split v,p(`"",""')
										drop v
										sxpose,clear
										replace _var1=subinstr(_var1,"]}}","",.)
										replace _var1=subinstr(_var1,`""klines":"',"",.)
										replace _var1=subinstr(_var1,`"[""',"",.)
										replace _var1=subinstr(_var1,`"""',"",.)
										
										
										
										split _var1,p(",")
										drop _var1
										rename _all (date open close high low volume Turnover amplitude price_limit change_amount turnover_rate)


									gen time= date(date,"YMD")
									format %dCY-N-D time
									order time
									drop date
									destring _all,replace
									compress
									gen code="`code'"
									order code
									save `"`path'/`code'_trade"', replace
									noi disp as text `"file `code'_trade.dta has been generated"'
								}
																
						}
							}			
end


