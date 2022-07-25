* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Jiaqi LI, China Stata Club(爬虫俱乐部)(jeremylee_41@163.com)
* Updated on July 24th, 2020
* Original Data Source: "https://www.so.studiodahu.com/wiki/%E9%A6%99%E6%B8%AF%E4%BA%A4%E6%98%93%E6%89%80%E4%B8%8A%E5%B8%82%E5%85%AC%E5%8F%B8%E5%88%97%E8%A1%A8"
* Please do not use this code for commercial purposes
capture program drop hkstock
program define hkstock

	version 14
	
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
	copy "https://www.so.studiodahu.com/wiki/%E9%A6%99%E6%B8%AF%E4%BA%A4%E6%98%93%E6%89%80%E4%B8%8A%E5%B8%82%E5%85%AC%E5%8F%B8%E5%88%97%E8%A1%A8"  `"`path'\temphkstkcd.txt"',replace
	infix strL v 1-100000 using `"`path'\temphkstkcd.txt"', clear   
	
	gen v2=1 if index(v, `"<h2><span id=".E5.89.B5.E6.A5.AD.E6.9D.BF.EF.BC.888001-8098.EF.BC.89""')
	replace v2=1 if index(v,`"" id="9600-9899""')
	replace v2=0 if v2==.
	gen v3=sum(v2)

	tempfile `exchange'
	foreach name in `exchange'{	
		if  "`name'" == "GEM" {
			keep if v3 ==1
			
		}
		else if  "`name'" == "MAIN" {
			drop if v3 ==1
		}
		else if   "`name'" == "ALL" {
			continue		
		}
		else {
			disp as error `"`name' is an invalid exchange"'
			exit 601
		}
	}	
		drop v2 v3
		erase `"`path'\temphkstkcd.txt"'
		
		keep if ustrregexm(v,"<td>([0-9]+)</td>") |  index(v, "<td><a href="http://fmwww.bc.edu/repec/bocode/h/)&#32;		replace&#32;v&#32;=&#32;ustrregexra(v,"<.*?>", "")
		gen v1 = v[_n - 1]
		keep if mod(_n, 2) == 0
		gen stkcd =real(v1)
		format %05.0f stkcd
		rename v stknm 
		drop v1
		order stkcd,before(stknm)
		compress
	}

	di "You've got the stock names and stock codes from `exchange'"
	save `"`path'/hkstock.dta"', replace
	

end