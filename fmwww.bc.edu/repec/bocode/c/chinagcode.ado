program chinagcode
version 14.0
syntax, baidukey(string) [province(string) city(string) address(string) district(string) fulladdress(string) lat(string) long(string) ffirst]

if "`province'" == "" & "`city'" == "" & "`address'" == "" & "`district'" == "" & "`fulladdress'" == "" {
	di in red "error: must specify at least one option of 'province', 'city', 'district', 'address' and 'fulladdress'"
	exit
}

if "`ffirst'" == "ffirst" & "`fulladdress'" == "" {
	di in red "error: must specify specify option 'fulladdress' in order to use ffirst"
	exit
}

quietly {
	tempvar blank work1 work2 baidumap
	
	gen `blank' = ""
	
	if "`province'" == "" local province `blank'
	if "`city'"     == "" local city     `blank'
	if "`district'" == "" local district `blank'
	if "`address'"  == "" local address  `blank'
	if "`long'"     == "" local long     longitude
	if "`lat'"      == "" local lat      latitude
	
	if "`ffirst'" != "" {
		gen `work1' = `fulladdress'
		gen `work2' = `province' + `city' + `district' + `address'
	
	}
	
	else {
		gen `work1' = `province' + `city' + `district' + `address'
		
		if "`fulladdress'" == "" {
			gen `work2' = ""
		
		}
		
		else {
			gen `work2' = `fulladdress'
		
		}
	
	}
	
	
	drop `blank'

	gen `baidumap' = ""
	
	forvalues i = 1/`=_N' {
		
		replace `baidumap' = fileread(`"http://api.map.baidu.com/geocoder/v2/?output=json&ak=`baidukey'&address=`=`work1'[`i']'"') in `i'
		
		if index(`baidumap'[`i'],"AK有误请检查再重试") {
			di in red "error: please check your baidukey"
			continue,break
		}
			
		if index(`baidumap'[`i'],"lack address or location") | index(`baidumap'[`i'],"无相关结果") {

			replace `baidumap' = fileread(`"http://api.map.baidu.com/geocoder/v2/?output=json&ak=`baidukey'&address=`=`work2'[`i']'"') in `i'
				
			if index(`baidumap'[`i'],"lack address or location") | index(`baidumap'[`i'],"无相关结果") {
				noisily di as text "the address is wrong or missing in `i', neither longitude nor latitude can be extracted"
			}

		}
			
	}
	gen `long' = ustrregexs(1) if ustrregexm(`baidumap',`""lng":(.*?),"')

	gen `lat'  = ustrregexs(1) if ustrregexm(`baidumap',`""lat":(.*?)\}"')
	
	destring `long' `lat',replace

}
end
