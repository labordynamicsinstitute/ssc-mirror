* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@hust.edu.cn)
* ZeYuan Guo , China Stata Club(爬虫俱乐部)(guozeyuan4513@163.com)
* Kong Meng, China Stata Club(爬虫俱乐部)(mengkong147@163.com)
* February 25th, 2023
* Program written by Dr. Chuntao Li, ZeYuan Guo and Kong Meng
* Used to get information about keywords which you are interested in in the county-level city from Gaode Map API
* Can only be used in Stata version 17.0 or above
capture program drop cnpoi
program define cnpoi
version 17.0
       if _caller() < 17.0 {
                disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
                exit 9
        }
        
		syntax,gaodekey(string) city(string) [keywords(string) types(string) path(string)]
		clear all
		
		if "`path'" != "" {
			capture mkdir `"`path'"'
			disp `"`path'"'
		}
		else {
			local path `"`c(pwd)'"'
		}

qui{    
		if `"`keywords'"' == "" & `"`types'"' == ""{
				noisily di as error "error: must specify at least one option of keywords and types
		  exit 198
	    }
		
	    else if `"`keywords'"' != "" & `"`types'"' == ""{
	       local keywords1 = geturi("`keywords'") 
		   local types1 = ""
	    }
	
	    else if `"`types'"' != "" & `"`keywords'"' == ""{
	       local types1 = geturi("`types'") 
		   local keywords1= ""
	    }
		
		else {
		   local types1 = geturi("`types'") 
		   local keywords1= geturi("`keywords'") 
		}
   
	    local city1 = geturi("`city'")
	    forvalues p = 1/20{
	   	local url = "http://restapi.amap.com/v3/place/text?&keywords=`keywords1'&types=`types1'&city=`city1'&output=json&offset=20&page=`p'&key=`gaodekey'&extension=all"
		cap copy "`url'" temp.txt,replace
	
		clear
		set obs 1
		gen v = fileread("temp.txt")
		if index(v,`""info":"INVALID_USER_KEY""'){
			noisily di as error "error: please check your gaodekey"
			exit 198
		}
		else if index(v,`""info":"USER_DAILY_QUERY_OVER_LIMIT""'){
			noisily di as error "error: your gaodekey is over_limit"
			exit 198
		}
	
		replace v = ustrregexra(v,"\r\n","")
		replace v = ustrregexra(v,"\s","")
		if index(v, `""count":"0""') {
				continue, break
			}  
		split v, p(`""parent""')
		if index(v, `""count":"1""'){
			gen v3 = `""pname":"1""cityname":"1""adname":"1""name":"1""address":"1""type":"1""location":"1""'
		}	  
		drop v v1
		sxpose,clear
		gen pname = ustrregexs(1) if ustrregexm(_var1,`""pname":"(.*?)""')
		gen cityname = ustrregexs(1) if ustrregexm(_var1,`""cityname":"(.*?)""')
		gen adname = ustrregexs(1) if ustrregexm(_var1,`""adname":"(.*?)""')
		gen name = ustrregexs(1) if ustrregexm(_var1,`""name":"(.*?)""')
		gen address = ustrregexs(1) if ustrregexm(_var1,`""address":"(.*?)""')
		gen type = ustrregexs(1) if ustrregexm(_var1,`""type":"(.*?)""')
		gen location = ustrregexs(1) if ustrregexm(_var1,`""location":"(.*?)""')
		split location,p(",")
		drop _var1 location
		rename (location1 location2) (lon lat)
		format name %-30s
		format address %-50s
		format type %-50s
		compress
		save `"`path'/`city'`keywords'`types'`p'.dta"',replace
		}

		clear
		cd `"`path'"'
		local files: dir "." file `"`city'`keywords'`types'*.dta"'
			foreach file in `files' {
			append using `file'
		}
		duplicates drop
		label var pname 省份
		label var cityname 地级市
		label var adname 县级市或区
		label var name 名称
		label var address 地址
		label var type 类型
		label var lon 经度
		label var lat 纬度
}
		save `"`city'`keywords'`types'总和.dta"',replace
		cap erase temp.txt
		forvalues p=1/20{
			cap erase `city'`keywords'`types'`p'.dta
		}
		
end

	

	
	