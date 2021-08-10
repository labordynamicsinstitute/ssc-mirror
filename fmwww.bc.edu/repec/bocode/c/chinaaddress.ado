program chinaaddress
version 14.0
syntax, baidukey(string) lat(string) long(string) [province(string) city(string) district(string) street(string) address(string) description(string)]

quietly {
	tempvar baidumap
	
	if "`province'"    == "" local province    province
	if "`city'"        == "" local city        city
	if "`district'"    == "" local district    district
	if "`street'"      == "" local street      street
	if "`address'"     == "" local address     address
	if "`description'" == "" local description discription

	
	gen `baidumap' = ""
		
	forvalues i = 1/`=_N' {
		
		if `lat'[`i'] == . {
			noisily di as text "the latitude is missing and no address can be extracted in `i'"
			continue
		}
		
		if `long'[`i'] == . {
			noisily di as text "the longitude is missing and no address can be extracted in `i'"
			continue
		
		}
		
		replace `baidumap' = fileread(`"http://api.map.baidu.com/geocoder/v2/?output=json&ak=`baidukey'&location=`=string(`lat'[`i'])',`=string(`long'[`i'])'"') in `i'
		
		if index(`baidumap'[`i'],"AK有误请检查再重试") {
			di in red "error: please check your baidukey"
			continue,break
		
		}
		
		if index(`baidumap'[`i'],`"address":"",""') {
			noisily di as text "the location is wrong and no address can be extracted in `i'"
			replace `baidumap' = "" in `i'
		
		}
	}
	
	gen `province'    = ustrregexs(1) if ustrregexm(`baidumap',`"province":"(.*?)",""')
	gen `city'        = ustrregexs(1) if ustrregexm(`baidumap',`"city":"(.*?)",""')
	gen `district'    = ustrregexs(1) if ustrregexm(`baidumap',`"district":"(.*?)",""')
	gen `street'      = ustrregexs(1) if ustrregexm(`baidumap',`"street":"(.*?)",""')
	gen `address'     = ustrregexs(1) if ustrregexm(`baidumap',`"address":"(.*?)",""')
	gen `description' = ustrregexs(1) if ustrregexm(`baidumap',`"description":"(.*?)",""')

}
end
