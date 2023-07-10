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
				keep if strpos(v,"td")|strpos(v,`"h3 class="bakg12""')
				replace v = ustrregexs(1) if ustrregexm(v,`"<h3 class="bakg12">(.*)<i>"')
				local title=v[1]
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
				rename _all (Year Opinion As CA CE RCD FA AR PDR Rsub Rjoint Rcontr RT Stocks SCA TC Cash TD StI NCA AFS PL EQsub EQjoint EQcontr Rty IP Goodwill IA DTA SNCA TLEQ TL CL SL AP AC DFL TP P2sub P2joint P2contr SCL NCL LL DTL SNCL TEQ SC PS Res SEQ2O EQ2O EQ2NI SEQ)
				recast str Year
				gen name="`title'"
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
				rename _all (Year OR OI SOI CS GM OIn SE O FE OE IPVC SPre Pre OIjoint OIcontr SPBT PBT ITE SPAT PAT P2O P2NI MI EPS DEPS OCI TCI TC2O TC2NI TC2NO)
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
				rename _all (Year CFO DA WC CFI CEx IA NCF RS Div SI NICE SNICE BCE RCCE ECE)
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
				gen year = date(Year, "YMD")
				format %dCY-N-D year
				order code year name
				drop Year
				compress
				label variable name "Company Name"
				label variable year "Reporting Period"
				label variable code "Stock Code"
				label variable Opinion "Audit Opinion"
				label variable As "Total Assets"
				label variable CA "Current Assets"
				label variable CE "Cash and Cash Equivalents"
				label variable RCD "Restricted Cash and Deposits"
				label variable FA "Trading Financial Assets"
				label variable AR "Accounts Receivable and Bills Receivable"
				label variable PDR "Prepayments, Deposits and Other Receivables"
				label variable Rsub "Receivables from Subsidiaries"
				label variable Rjoint "Receivables from Joint"
				label variable Rcontr "Receivables from Jointly Controlled Entities"
				label variable RT "Refundable Taxes"
				label variable Stocks "Inventories"
				label variable SCA "Special Items of Current Assets"
				label variable TC "Total Cash"
				label variable Cash "Monetary Funds"
				label variable TD "Time Deposits"
				label variable StI "Short-term Investments"
				label variable NCA "Non-current Assets"
				label variable AFS "Available-for-sale Financial Assets"
				label variable PL "Prepaid Lease Payments"
				label variable EQsub "Equity of Subsidiaries"
				label variable EQjoint "Equity of Joint"
				label variable EQcontr "Equity of Jointly Controlled Entities"
				label variable Rty "Realty"
				label variable IP "Investment Property"
				label variable Goodwill "Goodwill"
				label variable IA "Intangible Assets"
				label variable DTA  "Deferred Tax Assets"
				label variable SNCA "Special Items of Non-Current Assets"
				label variable TLEQ "Total Liabilities and Equity"
				label variable TL "Total Liabilities"
				label variable CL "Current Liabilities"
				label variable SL "Short-term Loans"
				label variable AP "Accounts Payable and Bills Payable"
				label variable AC "Accrued Cost and Other Payables"
				label variable DFL  "Derivative Financial Liabilities"
				label variable TP "Taxes Payable"
				label variable P2sub "Payables to Subsidiaries"
				label variable P2joint  "Payables to Joint"
				label variable P2contr "Payables to Jointly Controlled Entities"
				label variable SCL "Special Items of Current Liabilities"
				label variable NCL "Non-Current Liabilities"
				label variable LL  "Long-term Loans"
				label variable DTL "Deferred Tax Liabilities"
				label variable SNCL "Special Items of Non-Current Liabilities"
				label variable TEQ "Total Equity"
				label variable SC "Share Capital"
				label variable PS "Preferred Shares"
				label variable Res  "Reserves"
				label variable SEQ2O "Special Items of Equity Attributable to Owners of the Company"
				label variable EQ2O  "Equity Attributable to Owners of the Company"
				label variable EQ2NI "Equity Attributable to Non-controlling Interests"
				label variable SEQ  "Special Items of Equity"
				label variable OR  "Operating Revenue"
				label variable OI "Including: Operating Income"
				label variable SOI "Special Items of Operating Revenue"
				label variable CS "Cost of Sales"
				label variable GM  "Gross Profit"
				label variable OIn "Plus: Other Income"
				label variable SE "Less: Sales Expenses"
				label variable O "Overhead"
				label variable FE "Financial Expenses"
				label variable OE "Other Expenses"
				label variable IPVC "Plus: Fair Value Changes of Investment Property"
				label variable SPre "Special Items of Operating Premium"
				label variable Pre "Operating Premium"
				label variable OIjoint "Plus: Share of Profit of Joint"
				label variable OIcontr "Share of Profit of Jointly Controlled Entities"
				label variable SPBT "Special Items of Profit Before Tax"
				label variable PBT "Profit Before Tax"
				label variable ITE "Less: Income Tax Expenses"
				label variable SPAT "Plus: Special Items of Profit After Tax"
				label variable PAT "Profit After Tax"
				label variable P2O "Profit Attributable to Owners of the Company"
				label variable P2NI "Profit Attributable to Non-controlling Interests"
				label variable MI  "Minority Interest"
				label variable EPS "Basic Earnings per Share"
				label variable DEPS "Diluted Earnings per Share"
				label variable OCI "Other Comprehensive Income"
				label variable TCI "Total Comprehensive Income"
				label variable TC2O "Total Comprehensive Income Attributable to Owners of the Company" 
				label variable TC2NI  "Total Comprehensive Income Attributable to Non-controlling Interests"
				label variable TC2NO  "Total Comprehensive Income Attributable to Non-owners"
				label variable CFO "Net Cash Flows from Operating Activities"
				label variable DA "Depreciation and Amortization"
				label variable WC "Changes in Operating Working Capital"
				label variable CFI "Net Cash Flows from Investing Activities"
				label variable CEx "Capital Expenditures"
				label variable IA "Investment Acquisitions"
				label variable NCF "Net Cash Flows from Financing Activities"
				label variable RS "Repurchase of Shares"
				label variable Div "Dividend Payments"
				label variable SI "Stock Issuances"
				label variable NICE "Net Increase in Cash and Cash Equivalents"
				label variable SNICE "Special Items of Net Increase in Cash and Cash Equivalents"
				label variable BCE "Plus: Cash and Cash Equivalents at Beginning of Period"
				label variable RCCE "Effect of Exchange Rate Changes on Cash and Cash Equivalents"
				label variable ECE "Cash and Cash Equivalents at End of Period"
				save `"`path'/0`code'_ar"', replace
				noi disp as text `"file 0`code'_ar.dta has been generated and saved in `path'"'
			}
			}

end
		
		
		

		
		
		
		
		
		
		
