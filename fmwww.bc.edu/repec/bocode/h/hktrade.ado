* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Tianyao Luo, China Stata Club(爬虫俱乐部)(cnl1426@163.com)
* November 21st, 2022
* Program written by Dr. Chuntao Li and Tianyao Luo
* Downloads historical stock transaction records for Hong Kong listed companies.
* Can only be used in Stata version 17.0 or above

clear
capture program drop hktrade
program define hktrade
	version 17.0
	set maxvar 120000 	
	qui cap findfile sxpose.ado
        if  _rc>0 {
                disp as error "command sxpose is unrecognized,you need "ssc install sxpose" "
                exit 601
        }  
	if _caller() < 17.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
		exit 9
	}

	syntax anything(name = list), [ path(string)]
	local address "https://web.ifzq.gtimg.cn/appstock/app/kline/kline?_var=kline_day1980&"

	if `"`path'"' != "" {
		cap mkdir `"`path'"'
	} 

	else {
		local path `"`c(pwd)'"'
        disp `"`path'"'
	}
	
	
	foreach code in `list' {
                
			qui{			
						if length("`code'") >5 {
                                        disp as error `"`code' is an invalid stock code"'
                                        exit 601
                                } 
                        while length("`code'") < 5 {
                                        local code = "0" + "`code'"
										}
						local z=2010
						clear
						set obs 1
						local x=`z'+14 
						local url "`address'param=hk`code',day,`z'-01-01,`x'-12-31,10000,&r=0.016412179353956224"
						gen v = fileread("`url'")
						if length(v) < 2500{
										disp as error `"`code' is an invalid stock code"'
                                        exit 601
											}  
						split v,p("],[")
						drop v 
						sxpose,clear
						replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"day\"\:\[\[\"(.*)\""')
						replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"(.*)\",\{\"cqr\""')
						replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"(.*)"]],"qt""')
						replace _var1=subinstr(_var1,`"""',"",.)
						split _var1,p(",")
						drop _var1 
						while _rc != 0 & _rc != 1 {
													clear
													di as error "`code' is an invalid stock code"
													exit 601
													}
						rename _all (date open close high low volume)
						destring _all,replace
						save `"`code'_`z'"', replace
						clear
						
					    forvalues y = 1980(15)1995 {
												clear
												set obs 1
												local x=`y'+14 
												local url "`address'param=hk`code',day,`y'-01-01,`x'-12-31,10000,&r=0.016412179353956224"

												gen v = fileread("`url'")
												if length(v) < 2500{
																continue
												}  
												split v,p("],[")
												drop v 
												sxpose,clear
												replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"day\"\:\[\[\"(.*)\""')
												replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"(.*)\",\{\"cqr\""')
												replace _var1= ustrregexs(1) if ustrregexm(_var1, `"\"(.*)"]],"qt""')
												replace _var1=subinstr(_var1,`"""',"",.)
												split _var1,p(",")
												drop _var1 
												while _rc != 0 & _rc != 1 {
																		clear
																		di as error "`code' is an invalid stock code"
																		exit 601
																			}
												rename _all (date open close high low volume)
												destring _all,replace
												compress
												save `"`code'_`y'"', replace
												clear
												}	
						

					use `"`code'_2010"', clear
					cap append using `code'_1980.dta
					cap append using `code'_1995.dta
					cap erase `code'_1980.dta
					cap erase `code'_1995.dta
					cap erase `code'_2010.dta
					gen code=`code'
					format %05.0f code
					sort date 
					order code
					destring _all,replace
					save `"`path'/`code'"', replace
					noi disp as text `"file `code'.dta has been generated"'
											}						
					
							}			
end


