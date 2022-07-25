* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Zijian LI, China Stata Club(爬虫俱乐部)(jeremylee_41@163.com)
* Yuan Xue, China Stata Club(爬虫俱乐部)(xueyuan19920310@163.com)
* Updated on Oct 31th, 2018
* Fix some bugs and make this command run faster
* Original Data Source: https://quote.cfi.cn/stockList.aspx
* Please do not use this code for commerical purpose


program define cnstock
	
	if _caller() < 14.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 14.0 programs"
		exit 9
	}
	
	syntax anything(name = exchange), [path(string)]
	
	clear

	if "`path'" != "" {
		capture mkdir `"`path'"'
	}

	if "`path'" == "" {
		local path `"`c(pwd)'"'
		disp `"`path'"'
	}

	qui {
		tempfile `exchange'

		foreach name in `exchange'{
			
			if "`name'" == "SHA" local fs = "m:1+t:2,m:1+t:23"
			else if "`name'" == "SZA" local fs = "m:0+t:6,m:0+t:80"
			else if "`name'" == "BJA" local fs = "m:0+t:81+s:2048"
			else if "`name'" == "SZGE" local fs = "m:0+t:80"
			else if "`name'" == "SHSTAR" local fs = "m:1+t:23"
			else if "`name'" == "A" local fs "m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:0+t:81+s:2048"
			else if "`name'" == "SZB" local fs = "m:0+t:7"
			else if "`name'" == "SHB" local fs = "m:1+t:3"
			else if "`name'" == "B" local fs = "m:0+t:7,m:1+t:3"
			else if "`name'" == "all" local fs = "m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:0+t:81+s:2048,m:0+t:7,m:1+t:3"
			else {
				disp as error `"`name' is an invalid exchange"'
				exit 601
			}

			clear
			set obs 1
			gen v = fileread("https://20.push2.eastmoney.com/api/qt/clist/get?pn=1&pz=10000&web&fs=`fs'&fields=f12,f14")
			replace v = ustrregexs(1) if ustrregexm(v, `""diff":\{"0":\{(.*?)\}\}\}\}"')
			replace v = ustrregexra(v, `""\d+":"', "")
			mata spredata()
			gen stknm = ustrregexs(1) if ustrregexm(v, `""f14":"(.*?)""')
			gen stkcd = ustrregexs(1) if ustrregexm(v, `""f12":"(.*?)""')
			drop v
			destring stkcd, replace
			format %06.0f stkcd
			save `"``name''"', replace
		}
		
		clear
		foreach name in `exchange' {
			append using `"``name''"'
		}
		compress
		label var stkcd stockcode
		label var stknm stockname
	}

	di "You've got the stock names and stock codes from `exchange'"
	save `"`path'/cnstock.dta"', replace
end

mata
void function spredata() {
    
    string matrix A
	string matrix B
	
	A = st_sdata(., "v", .)
	B = substr(A, 1, strpos(A, "},{") - 1)
	A = subinstr(A, B + "},{", "", 1)
	do {
		B = B, substr(A, 1, strpos(A, "},{") - 1)
		A = subinstr(A, B[1, cols(B)] + "},{", "", 1)
	} while (strpos(A, "},{") != 0)
	B = B, A
	stata("drop in 1")
	st_addobs(cols(B))
	st_sstore(., "v", B')
}
end









