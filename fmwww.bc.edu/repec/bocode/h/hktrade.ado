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

	syntax anything(name = list), [fqt(string) path(string) warrant(string)]
	

	if `"`path'"' != "" {
		cap mkdir `"`path'"'
	} 

	else {
		local path `"`c(pwd)'"'
        disp `"`path'"'
	}
	
	if `"`fqt'"' == ""|`"`fqt'"' == "d"|`"`fqt'"' == "D" {
		local klt "101"
	} 

	if `"`fqt'"' == "w"|`"`fqt'"' == "W" {
		local klt "102"
	} 
	
	if `"`fqt'"' == "m"|`"`fqt'"' == "M"  {
		local klt "103"
	} 
	
	if `"`fqt'"' != ""&`"`warrant'"' != ""  {
		disp as error "fqt() is only for stock data;warrant() is only for warrant data.Cannot be selected at the same time."
		exit 9
	} 
	
	if `"`fqt'"' == "" & `"`warrant'"' == ""{
				noisily di as error "error: must specify at least one option of fqt and warrant
		  exit 198
	    }
	
	**********option************
	if `"`warrant'"' == "True"|`"`warrant'"' == "true" |`"`warrant'"' == "t" |`"`warrant'"' == "T"{
		local address "https://datacenter.eastmoney.com/securities/api/data/v1/get?reportName=RPT_HK_STRUCTURED_LIST&columns=SECUCODE%2CSECURITY_CODE%2CSECURITY_NAME%2CSECURITY_TYPE%2CEXPIRE_DATE%2CSTRIKE_PRICE%2CSTRIKE_PRICE_CURRENCY%2CSWAP_RATIO%2CUNDERLYING_CODE%2CUNDERLYING_NAME%2CISSUE_PRICE%2CTOTAL_ISSUE_SIZE%2CSP_CLASSIF_NAME&quoteColumns=&filter=(UNDERLYING_CODE%3D%22" 
		local t_add "%22)(SECURITY_TYPE%20in%20(%22001001%22%2C%22001002%22))&pageNumber=1&pageSize=300&sortTypes=-1&sortColumns=EXPIRE_DATE&source=F10&client=PC"
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
										
								
								local url "`address'`code'`t_add'"
								copy "`url'" temp.txt,replace
								clear
								set obs 1  
								gen v =fileread("temp.txt")	 
								if length(v) < 120{
												disp as error `"There is no warrant information for `code'."'
												exit 601
													}  	
 								replace v = ustrregexs(1) if ustrregexm(v, `"\"data\"\:\[\{\"(.*)"')
								

								cap split v,p(`",""')
 								drop v
 								sxpose,clear
								replace _var1=subinstr(_var1,`"""',"",.)
								replace _var1=subinstr(_var1,":","",.)
								replace _var1=subinstr(_var1,"SECUCODE","",.)
								replace _var1=subinstr(_var1,"SECURITY_CODE","",.)
								replace _var1=subinstr(_var1,"SECURITY_NAME","",.)
								replace _var1=subinstr(_var1,"SECURITY_TYPE","",.)
								replace _var1=subinstr(_var1,"EXPIRE_DATE","",.)
								replace _var1=subinstr(_var1,"UNDERLYING_NAME","",.)
								replace _var1=subinstr(_var1,"ISSUE_PRICE","",.)
								replace _var1=subinstr(_var1,"TOTAL_ISSUE_SIZE","",.)
								replace _var1=subinstr(_var1,"STRIKE_PRICE","",.)
								replace _var1=subinstr(_var1,"SWAP_RATIO","",.)
								
								drop if ustrregexm(_var1, "SP")
								drop if ustrregexm(_var1, "HK")
								drop if ustrregexm(_var1, "CODE")
								
								forvalues i=1/9{
                                        gen v`i'= _var1[_n+`i']
                                                                        }
								keep if mod(_n,9)==1
								drop v9
								drop if v8==""
								rename _all (code_name warrant_name type time strike_price Exchange_ratio name issue_price total_issuance)
								label variable Exchange_ratio "Unit:%"								
								label variable strike_price "Unit:Hong Kong dollar"
								label variable issue_price "Unit:Hong Kong dollar"
								label variable total_issuance "Unit:copies"
								
								replace time=subinstr(time,"000000","",.)
								gen Deadline= date(time,"YMD")
								format %dCY-N-D Deadline
								drop time
								drop type
								gen code="`code'"
								order code name Deadline

								destring _all,replace
								compress
								cap erase temp.txt
								save `"`path'/`code'_warrant"', replace
								noi disp as text `"file `code'_warrant.dta has been generated"'
		
							} 
							}
							}
	
	
	

	
	
	**********stock*************
	if `"`fqt'"' == "d"|`"`fqt'"' == "D"|`"`fqt'"' == "w"|`"`fqt'"' == "m"|`"`fqt'"' == "W"|`"`fqt'"' == "M"{
	    
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
								clear
								set obs 1  
								gen v =fileread("temp.txt")	 
								if length(v) < 2500{
												disp as error `"`code' is an invalid stock code or fqt() syntax error"'
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
										
										destring _all,replace
										compress
										cap append using 2004.dta
										cap erase 2004.dta
										
										gen time= date(date,"YMD")
										format %dCY-N-D time
										order time
										drop date
										gen code="`code'"
										order code
										label variable price_limit "Unit:%"
										label variable amplitude "Unit:%"
										label variable turnover_rate "Unit:%"
										cap erase temp.txt
										save `"`path'/`code'_trade"', replace
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
									label variable price_limit "Unit:%"
									label variable amplitude "Unit:%"
									label variable turnover_rate "Unit:%"
									cap erase temp.txt
									save `"`path'/`code'_trade"', replace
									noi disp as text `"file `code'_trade.dta has been generated"'
								}
																
						}
							}		
	}
	
end


