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

	if "`exchange'"== "all" {
		local exchange SHA SZM SZSM SZGE SHB SZB
	}

	qui {
		tempfile `exchange'

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

			clear
			set obs 1
			gen v = fileread("https://quote.cfi.cn/stockList.aspx?t=`c'")
			replace v = ustrregexs(0) if ustrregexm(v, "<div id='divcontent' runat='server'>.*")
			if c(version) >= 16 mata spredata()
			else mata spredata2()
			gen stknm = ustrregexs(1) if ustrregexm(v, `".html">(.*?)\(\d"')
			gen stkcd = ustrregexs(1) if ustrregexm(v, "\((.*?)\)")
			drop v
			keep if ustrregexm(stkcd, "^000") | ustrregexm(stkcd, "^001") | ustrregexm(stkcd, "^002") | ustrregexm(stkcd, "^003") | ustrregexm(stkcd, "^2") | ustrregexm(stkcd, "^3") | ustrregexm(stkcd, "^6") |ustrregexm(stkcd, "^9")
			drop if ustrregexm(stkcd, "\D")
			destring stkcd, replace
			if "`name'" == "SZM" {
			    drop if stkcd >= 100000
			}
			format %06.0f stkcd
			save `"``name''"', replace
		}
		
		clear
		foreach name in `exchange' {
			append using `"``name''"'
		}
		drop if stkcd == 963 & stknm == "中证下游"

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
	B = ustrsplit(A, "</a></td>")
	stata("drop in 1")
	st_addobs(cols(B))
	st_sstore(., "v", B')
}


void function spredata2() {
    string matrix A
	string matrix B
	
	A = st_sdata(., "v", .)
	B = substr(A, 1, strpos(A, "</a></td>") - 1)
	A = subinstr(A, B + "</a></td>", "", 1)
	do {
		B = B, substr(A, 1, strpos(A, "</a></td>") - 1)
		A = subinstr(A, B[1, cols(B)] + "</a></td>", "", 1)
	} while (strpos(A, "</a></td>") != 0)
	B = B, A
	stata("drop in 1")
	st_addobs(cols(B))
	st_sstore(., "v", B')
}
end









