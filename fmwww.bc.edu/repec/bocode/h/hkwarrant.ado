* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Xiuping Mao, Ph.D. , China Stata Club(爬虫俱乐部)(xiuping_mao@126.com)
* Tianyao Luo, China Stata Club(爬虫俱乐部)(cnl1426@163.com)
* November 21st, 2022
* Updated on Mar 20th, 2023
* Program written by Dr. Chuntao Li and Tianyao Luo
* Downloads historical stock transaction records for Hong Kong listed companies.
* Can only be used in Stata version 17.0 or above

capture program drop hkwarrant
program define hkwarrant
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

	syntax anything(name = list), [path(string) warrant(string)]
	

	if `"`path'"' != "" {
		cap mkdir `"`path'"'
	} 

	else {
		local path `"`c(pwd)'"'
        disp `"`path'"'
	}
	
	

	
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
										
							if substr("`code'", 1, 1) == "0"|substr("`code'", 1, 1) == "4"|substr("`code'", 1, 1) == "8"{
								local url "`address'`code'`t_add'"
								copy "`url'" temp.txt,replace
								clear
								set obs 1  
								gen v =fileread("temp.txt")	 
								if length(v) < 120{
												cap erase temp.txt
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
								rename _all (warrcd warrnm type time strike_price exchange_ratio name issue_price total_issuance)
								
								
								replace time=subinstr(time,"000000","",.)
								gen deadline= date(time,"YMD")
								format %dCY-N-D deadline
								drop time type total_issuance
// 								gen code="`code'"
								order name deadline
								
								label variable exchange_ratio "Exchange ratio(Unit:%)"								
								label variable issue_price "Issue price"
								label variable strike_price "Strike price"
								label variable deadline "Deadline"								
								label variable warrcd "Warrant Code"
								label variable warrnm "Warrant Name"
								label variable name "Stock Name"
// 								label variable type "Warrant Type"
// 								label variable total_issuance "Total Issue Size"
								
								
								
								destring _all,replace
								compress
								cap erase temp.txt
								save `"`path'/`code'_warrant"', replace
								noi disp as text `"file `code'_warrant.dta has been generated and saved in `path'"'
		}
		
							else if substr("`code'", 1, 1) == "1"|substr("`code'", 1, 1) == "2"|substr("`code'", 1, 1) == "3"{
								cap copy "https://stock.finance.sina.com.cn/hkstock/quotes/`code'.html" temp.txt,replace 
								if _rc!=0{
									disp as error `"There is no information for `code'."'
									exit 601
								}
								else{
									clear
									infix strL v 1-20000 using temp.txt, clear
									replace v=ustrfrom(v,"gb18030",1)	
									keep if strpos(v,"stock_cname") | strpos(v,"</td>") & strpos(v,"<td>") 
									replace v =ustrregexra(v,"<.*?>","")
									sxpose,clear
									keep _var1 _var2 _var4 _var6 _var8 _var10 _var12 _var14 _var16 _var35
									rename _all (name en_name issue_date strike_price form property issue_price exchange_ratio deadline warrnm)
									gen warrcd="`code'"
									gen DAY= date(deadline,"YMD")
									gen DAY2= date(issue_date,"YMD")
									format %dCY-N-D DAY DAY2
									drop deadline issue_date en_name form property issue_date
									rename (DAY DAY2) (deadline issue_date)
									drop issue_date
									label variable exchange_ratio "Exchange ratio(Unit:%)"								
									label variable issue_price "Issue price"
									label variable strike_price "Strike price"
									label variable deadline "Deadline"								
									label variable warrcd "Warrant Code"
									label variable warrnm "Warrant Name"
									label variable name "Stock Name"
									order name deadline warrcd warrnm strike_price exchange_ratio issue_price	
									destring _all,replace
									compress
									cap erase temp.txt
									save `"`path'/`code'(warrant)_data"', replace
									noi disp as text `"file `code'(warrant)_data.dta has been generated and saved in `path'"'
								}
							}
							
							else {
								disp as error `"There is no information for `code'. It may be wrong code."'
								
							}
							} 
							}
							

	
end


