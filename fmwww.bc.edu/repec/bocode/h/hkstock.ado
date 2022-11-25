* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Tianyao Luo, China Stata Club(爬虫俱乐部)(cnl1426@163.com)
* November 21st, 2022
* Program written by Dr. Chuntao Li and Tianyao Luo
* Downloads Security names and codes for Hong Kong listed companies.
* Can only be used in Stata version 17.0 or above

clear
capture program drop hkstock
program define hkstock
		version 17.0
		if _caller() < 17.0 {
                disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
                exit 9
        }
		 syntax anything(name = code), [path(string) filename(string)] 
		 clear
		 if "`path'" != "" {
                capture mkdir `"`path'"'
         }

         if "`path'" == "" {
                local path `"`c(pwd)'"'
                disp `"`path'"'
         }

         if "`filename'" == "" {
                local filename hkstock
         }
		 local HN "Stocks listed in Mainland and Hong Kong at the same time"
		 local hN "Stocks listed in Mainland and Hong Kong at the same time"
		 local MainN "Hong Kong Main Board Listed Firms"
		 local MAINN "Hong Kong Main Board Listed Firms"
		 local mainN "Hong Kong Main Board Listed Firms"
		 local GrowthN "Hong Kong Growth Enterprise Board Listed Firms"
		 local growthN "Hong Kong Growth Enterprise Board Listed Firms"
		 local GROWTHN "Hong Kong Growth Enterprise Board Listed Firms"
		 local ETFN "Hong Kong Connect ETF Fund"
		 local EtfN "Hong Kong Connect ETF Fund"
		 local etfN "Hong Kong Connect ETF Fund"
		 local StockN "all Hong Kong Securities"
		 local STOCKN "all Hong Kong Securities"
		 local stockN "all Hong Kong Securities"
		 local OptionN "Hong Kong Warrants"
		 local optionN "Hong Kong Warrants"
		 local OPTIONN "Hong Kong Warrants"
		 
		 
         qui {
                tempfile `code'

                foreach name in `code'{
                        
                        if "`name'" == "Main"|"`name'" =="main"|"`name'" =="MAIN" local fs = "m:128+t:3"
                        else if "`name'" == "Growth"|"`name'" =="growth"|"`name'" =="GROWTH" local fs = "m:128+t:4"
						else if "`name'" == "ETF"|"`name'" =="etf"|"`name'" =="Etf" local fs = "b:MK0837,b:MK0838"
						else if "`name'" == "H"|"`name'" =="h" local fs = "b:DLMK0101"
						else if "`name'" == "Option"|"`name'" =="option"|"`name'" =="OPTION" local fs = "m:128+t:6"
                        else if "`name'" == "Stock"|"`name'" =="stock"|"`name'" =="STOCK" local fs = "m:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2"
                        else {
                                disp as error `"`name' is an invalid CODE. the Code must be the following:"'
								disp as error `"Main: Hong Kong Main Board Listed Firms"'
								disp as error `"Growth: Hong Kong Growth Enterprise Board Listed Firms"'
								disp as error `"ETF:Hong Kong Connect ETF Fund"'
								disp as error `"H:Stocks listed in Mainland and Hong Kong at the same time"'
								disp as error `"Stock:all Hong Kong Securities"'
								disp as error `"Option:Hong Kong Warrants"'
                                exit 601
                        }

                        clear
                        set obs 1
                        gen v = fileread("https://90.push2.eastmoney.com/api/qt/clist/get?pn=1&pz=10000&web&fs=`fs'&fields=f12,f14")
                        replace v = ustrregexs(1) if ustrregexm(v, `""diff":\{"0":\{(.*?)\}\}\}\}"')
                        replace v = ustrregexra(v, `""\d+":"', "")
                        mata tempname() 
                        gen stknm = ustrregexs(1) if ustrregexm(v, `""f14":"(.*?)""')
                        gen stkcd = ustrregexs(1) if ustrregexm(v, `""f12":"(.*?)""')
                        drop v
                        destring stkcd, replace
                        format %05.0f stkcd
                        save `"``name''"', replace
						noi di "You've got the names and codes for ``name'N'"
                }
                
                clear
                foreach name in `code' {
                        append using `"``name''"'
                }
                compress
                label var stkcd stockcode
                label var stknm stockname
        }

        
        save `"`path'/`filename'.dta"', replace
end

mata
void function tempname() {
    
    string matrix tmp
        string matrix tmp1
        
        tmp = st_sdata(., "v", .)
        tmp1 = substr(tmp, 1, strpos(tmp, "},{") - 1)
        tmp = subinstr(tmp, tmp1 + "},{", "", 1)
        do {
                tmp1 = tmp1, substr(tmp, 1, strpos(tmp, "},{") - 1)
                tmp = subinstr(tmp, tmp1[1, cols(tmp1)] + "},{", "", 1)
        } while (strpos(tmp, "},{") != 0)
        tmp1 = tmp1, tmp
        stata("drop in 1")
        st_addobs(cols(tmp1))
        st_sstore(., "v", tmp1')
}
end
