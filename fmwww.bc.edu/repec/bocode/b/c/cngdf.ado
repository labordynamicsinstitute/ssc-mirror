* Authors:
* Program written by Bolin, Song (松柏林) Shenzhen University, China.
* Wechat:YJYSY91, 2021-01-02
* Original Data Source: https://data.stats.gov.cn/
* Please do not use this code for commerical purpose

capture program drop cngdf
program define cngdf

	version 14.0
    
syntax [anything] ,YEAR(numlist integer max=1 min=1 ) [CHINA] 

qui{
		
	if missing("`china'") {
		*下载数据	
		local URL "https://gitee.com/songbolin/stata/raw/master/8458467434930237.dta"
		tempfile  data   
		cap copy `"`URL'"' "`data'.dta", replace  
		local times = 0
		while _rc ~= 0 {
			local times = `times' + 1
			sleep 1000
			cap copy `"`URL'"' "`data'.dta", replace 
			if `times' > 10 {
				disp as error "Internet speeds is too low to get the data"
				exit 601
			}
		}     
		
		use "`data'.dta", clear
		*设置时间区间
		local year_small=year[1]
		local year_big  =year[_N]
		if `year'<`year_small' | `year'>`year_big'{
			disp as error  `"The year must be between `year_small' and `year_big'"'
			exit 198 
		}
		*计算GDP平减指数
		gen Real_GDP = GDP if year == `year'  
		bysort id :replace  Real_GDP= Real_GDP[_n-1]*GDPindex/100 if year!=`year' 
		gen gdp_deflator=GDP/Real_GDP  
		*结果加标签
		drop id
		drop if year<`year'
		label variable province "省份"
		label variable year "年份"
		label variable GDP "名义GDP"
		label variable Real_GDP "实际GDP"
		label variable GDPindex "GDP指数"
		label variable gdp_deflator "以`year'年为基期的GDP平减指数"
		label data "以`year'年为基期的GDP平减指数" 		
	}
	
	else{
			*下载数据		
			local URL "https://gitee.com/songbolin/stata/raw/master/8458490029.dta"
			tempfile  data   
			cap copy `"`URL'"' "`data'.dta", replace  
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`URL'"' "`data'.dta", replace 
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}     		
			*导入数据
			use "`data'.dta", clear 
			*设置时间区间
			local year_small=year[1]
			local year_big  =year[_N]
			if `year'<`year_small' | `year'>`year_big'{
				disp as error  `"The year must be between `year_small' and `year_big'"'
				exit 198 
			}
			*计算GDP平减指数
			gen Real_gdp = gdp if year == `year'  
			replace Real_gdp= Real_gdp[_n-1]*gdp_index/100 if year!=`year' 
			gen gdp_deflator=gdp/Real_gdp   
			*结果加标签
			drop if year<`year'
			label variable country "国家"
			label variable year "年份"
			label variable gdp "名义GDP"
			label variable Real_gdp "实际GDP"
			label variable gdp_index "GDP指数"
			label variable gdp_deflator "以`year'年为基期的GDP平减指数"
			label data "以`year'年为基期的GDP平减指数"     
	
		}		
}
	dis as txt "({stata br:点击打开数据})"
	dis as txt "(加入stata交流群微信：songbl_stata)"		
end
