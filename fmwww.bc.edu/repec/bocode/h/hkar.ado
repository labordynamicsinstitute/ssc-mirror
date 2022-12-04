* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Xiuping Mao, Ph.D. , China Stata Club(爬虫俱乐部)(xiuping_mao@126.com)
* Tianyao Luo, China Stata Club(爬虫俱乐部)(cnl1426@163.com)
* November 21st, 2022
* Program written by Dr. Chuntao Li and Tianyao Luo
* Downloads historical financial data for a list of Hong Kong public firms.
* Can only be used in Stata version 17.0 or above



clear
capture program drop hkar 
program define hkar
	version 17.0
	if _caller() < 17.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
		exit 9
	}
	syntax anything(name = list), [path(string)]
	if "`path'" != "" {
		cap mkdir `"`path'"'
	}
	else {
		local path `"`c(pwd)'"'
        disp `"`path'"'
	}
	if regexm("`path'", "(/|\\)$") { 
		local path = regexr("`path'", ".$", "")
	}
	
	tempfile zcfz profit cash 
	foreach code in `list' {
			if length("`code'") > 5 {
				di as error `"`code' is an invalid stock code"'
				exit 601
			}
			while length("`code'") < 5 {
				local code = "0"+"`code'"
				}
			local code=substr("`code'",2,4)
			
			qui{
				copy "https://s.askci.com/StockInfo/FinancialReport/BalanceSheet/?stockCode=HK`code'&theType=BalanceSheet&UnitName=%E4%B8%87%E6%B8%AF%E5%85%83&dateRange=&reportTime=,4" "`zcfz'.txt",replace
				infix strL v 1-400000 using "`zcfz'.txt", clear
				if `=_N' < 450 {
				di as error `"The `code' is an invalid stock code"'
				exit 601
			    }
				if `=_N' < 700 {
				di as error `"The information of 0`code' is incomplete"'
				exit 601
			    }
				count if strpos(v,"-12-31") 
				local p=`r(N)'
				keep if strpos(v,"td")	
				replace v = ustrregexs(1) if ustrregexm(v,">(.*)</")
				replace v = ustrregexs(1) if ustrregexm(v,"(.*?)<s")
				replace v =ustrregexra(v,"--","")
				gen x1=v[_n+`p']
				forvalues i=1/63{
					local k=`i'+1 
					gen x`k'= x`i'[_n+`p']
									}		
				keep in 1/`p'
				foreach var of varlist * {  
				label variable `var' "`=`var'[1]'"                              
				replace `var' = "" if  _n == 1         
				destring `var' , replace         
				}
				drop in 1
				drop x1 x2 x4 x9 x5 x6 x7 x8 x63 x64 
				rename _all (Year Opinion As CA CE RCD FC AR PP ARsub ARjoin ARcontr RVAT stock SCA TCV cash CDS STIP NCA AFS APL EQsub EQjoin EQcontr RTY IPM goodwill IA DTA SNCA TLEQ Li CL SL AP ACCR FD APVAT APsub APjoin APcontr SCL NCL LL DTL SUCL EQ CS PFD RES SEQATP EQATP EQATUC SEQ)
				recast str Year
				save `"`zcfz'"', replace

								}
								
								
								
			qui{
				copy "https://s.askci.com/StockInfo/FinancialReport/Profit/?stockCode=HK`code'&theType=Profit&UnitName=%E4%B8%87%E6%B8%AF%E5%85%83&dateRange=&reportTime=,4" "`profit'.txt",replace
				infix strL v 1-400000 using "`profit'.txt", clear
				if `=_N' < 450 {
				di as error `"The `code' is an invalid stock code"'
				exit 601
			    }
				if `=_N' < 700 {
				di as error `"The information of 0`code' is incomplete"'
				exit 601
			    }
				count if strpos(v,"-12-31")
				local p=`r(N)'
				keep if strpos(v,"td")	
				replace v = ustrregexs(1) if ustrregexm(v,">(.*)</")
				replace v = ustrregexs(1) if ustrregexm(v,"(.*?)<s")
				replace v =ustrregexra(v,"--","")
				gen x1=v[_n+`p']
				forvalues i=1/63{
					local k=`i'+1 
					gen x`k'= x`i'[_n+`p']
									}		
				keep in 1/`p'
				foreach var of varlist * {  
				label variable `var' "`=`var'[1]'"                              
				replace `var' = "" if  _n == 1         
				destring `var' , replace         
				}
				drop in 1
				drop x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x41 x42 x43 x44 x45 x46 x47 x48 x49 x50 x51 x52 x53 x54 x55 x56 x57 x58 x59 x60 x61 x62 x63 x64 
				rename _all (Year GOI NOI SOI COS GM OOI SE ME FE OE IPMFVC SPREM PREM OIjoin OIcontr SPTP PTP VATE SPAP PAP PToP PTUC PTNS EPS DEPS OCI TCI OCTP OCTUC OCTNS)
				recast str Year
				save `"`profit'"', replace
								}					
								
			
			qui{
				copy "https://s.askci.com/StockInfo/FinancialReport/CashFlow/?stockCode=HK`code'&theType=CashFlow&UnitName=%E4%B8%87%E6%B8%AF%E5%85%83&dateRange=&reportTime=,4" "`cash'.txt",replace
				infix strL v 1-400000 using "`cash'.txt", clear
				if `=_N' < 450 {
				di as error `"The `code' is an invalid stock code"'
				exit 601
			    }
				if `=_N' < 700 {
				di as error `"The information of 0`code' is incomplete"'
				exit 601
			    }
				count if strpos(v,"-12-31")
				local p=`r(N)'
				keep if strpos(v,"td")	
				replace v = ustrregexs(1) if ustrregexm(v,">(.*)</")
				replace v = ustrregexs(1) if ustrregexm(v,"(.*?)<s")
				replace v =ustrregexra(v,"--","")
				gen x1=v[_n+`p']
				forvalues i=1/63{
					local k=`i'+1
					gen x`k'= x`i'[_n+`p']
									}		
				keep in 1/`p'
				foreach var of varlist * {  
				label variable `var' "`=`var'[1]'"                              
				replace `var' = "" if  _n == 1         
				destring `var' , replace         
				}
				drop in 1
				drop x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x27 x28 x26 x27 x28 x29 x30 x31 x32 x33 x34 x35 x36 x37 x38 x39 x40 x41 x42 x43 x44 x45 x46 x47 x48 x49 x50 x51 x52 x53 x54 x55 x56 x57 x58 x59 x60 x61 x62 x63 x64
				rename _all (Year CFO DA WC CFI CAPEX IP CFF GFHG Div IPOE NICE SNICE OpCE RCCE EnCE)
				recast str Year
				save `"`cash'"', replace
								}	
				
			qui{
			    use `"`zcfz'"', clear
				merge 1:1 Year using `"`profit'"'
				drop _m
				merge 1:1 Year using `"`cash'"'
				drop _m
				cap drop x*
				sort Year 
				gen code=`code'
				format %05.0f code
				order code
				compress
				save `"`path'/0`code'"', replace
				noi disp as text `"file 0`code'.dta has been generated"'
			}
			}

end
		
		
		

		
		
		
		
		
		
		
