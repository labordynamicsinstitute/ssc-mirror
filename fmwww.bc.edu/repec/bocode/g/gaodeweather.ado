* gaodeweather.ado
* 高德地图天气查询命令
* 日期：2025年6月1日
* 版本：v1.0

capture program drop gaodeweather
program define gaodeweather, rclass
    version 14.0
    syntax, key(string) city(string) [EXTensions(string) SAVing(string) replace DEBUG TIMeout(integer 60)]
    
    * 清理输入参数
    local key = strtrim(stritrim("`key'"))
    local city = strtrim(stritrim("`city'"))
    
    * 验证必须参数
    if "`key'" == "" {
        di as error "必须提供有效的API密钥 (key)"
        exit 198
    }
    
    cap confirm variable `city'
    if _rc {
        di as error "城市编码变量 `city' 不存在"
        exit 198
    }
    
    * 设置默认扩展类型
    if inlist("`extensions'", "", "base", "all") == 0 {
        di as error "extensions 参数必须是 base 或 all"
        exit 198
    }
    if "`extensions'" == "" local extensions "base"
    
    * 保存当前数据
    preserve
    
    * 显示处理进度
    local total_obs = _N
    di as text "开始处理 " as result `total_obs' as text " 条记录..."
    di as text "API密钥: `key'"
    di as text "城市编码变量: `city'"
    di as text "查询类型: `extensions'"
    
    * 创建存储结果的变量
    qui {
        cap drop _gd_*
        gen str40 _gd_status = "待处理"      // API状态
        gen str40 _gd_province = ""          // 省份名
        gen str40 _gd_city = ""              // 城市名
        gen str10 _gd_adcode = ""            // 区域编码
        gen str20 _gd_weather = ""           // 天气现象
        gen double _gd_temperature = .       // 实时温度(℃)
        gen str20 _gd_winddirection = ""     // 风向描述
        gen str10 _gd_windpower = ""         // 风力级别
        gen double _gd_humidity = .          // 空气湿度(%)
        gen str20 _gd_reporttime = ""        // 数据发布时间
        gen strL _gd_response = ""           // 原始API响应
    }
    
    * 处理每个观测值
    forvalues i = 1/`total_obs' {
        * 获取当前记录的城市编码
        local citycode = `city'[`i']
        
        * 检查城市编码是否有效
        if missing(`citycode') {
            di as error "  记录 #`i': 城市编码存在缺失值"
            qui replace _gd_status = "城市编码缺失" in `i'
            continue
        }
        
        di as text "处理记录 #`i' : 城市编码 " as result `citycode'
        
        * 构建API请求URL
        local url "https://restapi.amap.com/v3/weather/weatherInfo?key=`key'&city=`citycode'&extensions=`extensions'&output=JSON"
        
        if "`debug'" != "" {
            di as text "API请求URL: `url'"
        }
        
        * 获取API数据
        cap copy "`url'" "__temp_gd_response.json", replace
        cap {
            tempname fh
            file open `fh' using "__temp_gd_response.json", read
            file read `fh' response
            file close `fh'
            if "`debug'" != "" di as text "  原始响应已保存到: __temp_gd_response.json"
        }
        
        * 处理HTTP错误
        if _rc {
            di as error "  API请求失败: HTTP错误代码 " _rc
            qui replace _gd_status = "HTTP错误" in `i'
            continue
        }
        
        * 解析API状态
        local status = ""
        if ustrregexm(`"`response'"', `"\"status\":\"(\d+)\""') {
            local status = ustrregexs(1)
            qui replace _gd_status = "状态码 " + "`status'" in `i'
        }
        
        * 检查API状态码
        if "`status'" != "1" {
            di as error "  API请求失败，状态码: `status'"
            
            * 尝试获取错误信息
            local errmsg = ""
            if ustrregexm(`"`response'"', `"\"info\":\"([^\"]+)\""') {
                local errmsg = ustrregexs(1)
                di as error "  错误信息: `errmsg'"
                qui replace _gd_province = "`errmsg'" in `i'
            }
            
            continue
        }
        
        * 存储原始响应
        qui replace _gd_response = `"`response'"' in `i'
        
        * 解析天气数据
        local province = ""
        local city_name = ""
        local adcode = ""
        local weather = ""
        local temperature = ""
        local winddirection = ""
        local windpower = ""
        local humidity = ""
        local reporttime = ""
        
        * 确定要解析的字段前缀
        local prefix = cond("`extensions'" == "all", "forecasts\\\\", "lives\\\\")
        
        if ustrregexm(`"`response'"', `"\"province\":\"([^\"]+)\""') local province = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"city\":\"([^\"]+)\""') local city_name = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"adcode\":\"(\d+)\""') local adcode = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"weather\":\"([^\"]+)\""') local weather = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"temperature\":\"([\d\.]+)\""') local temperature = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"winddirection\":\"([^\"]+)\""') local winddirection = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"windpower\":\"([\d≤≥]+)\""') local windpower = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"humidity\":\"([\d\.]+)\""') local humidity = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"reporttime\":\"([^\"]+)\""') local reporttime = ustrregexs(1)
        
        * 更新数据
        qui {
            replace _gd_status = "成功" in `i'
            replace _gd_province = "`province'" in `i'
            replace _gd_city = "`city_name'" in `i'
            replace _gd_adcode = "`adcode'" in `i'
            replace _gd_weather = "`weather'" in `i'
            replace _gd_temperature = cond("`temperature'" != "", real("`temperature'"), .) in `i'
            replace _gd_winddirection = "`winddirection'" in `i'
            replace _gd_windpower = "`windpower'" in `i'
            replace _gd_humidity = cond("`humidity'" != "", real("`humidity'"), .) in `i'
            replace _gd_reporttime = "`reporttime'" in `i'
        }
        
        di as text "  获取结果: `province' `city_name' `weather' `temperature'℃"
        
        * 添加延迟以避免请求过快
        if `i' < `total_obs' {
            sleep 200  // 200毫秒延迟
        }
    }
    
    * 删除临时文件
    cap rm "__temp_gd_response.json"
    
    * 重命名变量为友好名称
    qui {
        rename _gd_status gd_status
        rename _gd_province gd_province
        rename _gd_city gd_city
        rename _gd_adcode gd_adcode
        rename _gd_weather gd_weather
        rename _gd_temperature gd_temperature
        rename _gd_winddirection gd_winddirection
        rename _gd_windpower gd_windpower
        rename _gd_humidity gd_humidity
        rename _gd_reporttime gd_reporttime
        rename _gd_response gd_response
		
        label var gd_status         "API状态"
        label var gd_province       "省份名"
        label var gd_city           "城市名"
        label var gd_adcode         "区域编码"
        label var gd_weather        "天气现象"
        label var gd_temperature    "实时温度(℃)"
        label var gd_winddirection  "风向描述"
        label var gd_windpower      "风力级别"
        label var gd_humidity       "空气湿度(%)"
        label var gd_reporttime     "数据发布时间"
        label var gd_response       "原始API响应"
    }
    
    * 计算成功和失败数量
    qui count if gd_status == "成功"
    local success = r(N)
    local fail = _N - `success'
    
    * 输出结果
    di _n(2) as text "{hline}"
    di as text "已完成 " as result `total_obs' as text " 条记录的天气查询"
    di as text "成功记录数: " as result `success'
    di as text "失败记录数: " as result `fail'
    
    * 显示关键天气结果
    di as text _n "天气查询结果:"
    list gd_province gd_city gd_weather gd_temperature gd_humidity gd_reporttime in 1/`=min(5, _N)', ///
        noobs ab(20) sep(0)
    
    * 保存数据
    if `"`saving'"' != "" {
        if "`replace'" != "" {
            save `"`saving'"', replace
            di as text "天气数据已保存到: `saving' (已替换)"
        }
        else {
            cap save `"`saving'"', replace
            if _rc == 0 {
                di as text "天气数据已保存到: `saving'"
            }
            else {
                di as error "保存数据失败，错误代码: " _rc
            }
        }
    }
    
    * 恢复原始数据
    restore
end