*！area v1.0.0 Yangpei 11Nov2024
program area, rclass
	version 18.0
	syntax varlist(max=1 string)
	quietly{
		gen str12 region = ""
			foreach i in 安徽 湖北 湖南 河南 江西 山西{
			replace region = "中部地区" if 省份 == "`i'"
		}
			foreach j in 四川 陕西 重庆 新疆 云南     ///
				广西 贵州 甘肃 内蒙古 西藏 宁夏 青海{
			replace region = "西部地区" if 省份 == "`j'"
		}
		replace region ="东部地区" if region == ""
		tab region
	encode `varlist', gen(province)
	encode region, gen(area)
}
end	