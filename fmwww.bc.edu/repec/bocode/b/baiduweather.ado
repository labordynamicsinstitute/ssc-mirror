* baiduweather.ado
* 百度地图API通过经纬度查询天气
* 日期：2025年6月1日
* 版本：v1.0

capture program drop baiduweather
program define baiduweather, rclass
    version 14.0
    syntax, ak(string) LONGitude(string) LATitude(string) [COORDtype(string) ///
                   SAving(string) replace CLEAR FCperiod(integer 0) ///
                   TIMeout(integer 60) DEBUG]
    
    // 清理变量名：去除前导和尾部空格
    local longitude = strtrim("`longitude'")
    local latitude = strtrim("`latitude'")
    
    // 验证并清理API密钥
    local ak = subinstr("`ak'", " ", "", .)
    if "`ak'" == "" {
        di as error "必须提供有效的百度API密钥 (ak)"
        exit 198
    }
    
    // 确认变量存在
    cap confirm variable `longitude'
    if _rc {
        di as error "经度变量 `longitude' 不存在"
        exit 198
    }
    
    cap confirm variable `latitude'
    if _rc {
        di as error "纬度变量 `latitude' 不存在"
        exit 198
    }
    
    // 设置默认坐标类型
    if "`coordtype'" == "" local coordtype "bd09ll"
    local valid_coordtypes "bd09ll bd09mc wgs84 gcj02"
    if !`: list coordtype in valid_coordtypes' {
        di as error "坐标类型必须是: bd09ll, bd09mc, wgs84, gcj02"
        exit 198
    }
    
    // 保存当前数据状态
    preserve
    
    // 显示处理进度
    local total_obs = _N
    di as text "开始处理 " as result `total_obs' as text " 条经纬度记录..."
    di as text "经度变量: `longitude'"
    di as text "纬度变量: `latitude'"
    
    // 准备存储结果的变量
    qui {
        // 删除可能已存在的天气变量
        cap drop _weather_*
        cap drop weather_*
        
        // 创建新变量
        gen str50 _weather_status = "待处理"     // API状态
        gen str100 _weather_location = ""       // 位置信息
        gen str20 _weather_text = ""            // 天气描述
        gen double _weather_temp = .            // 温度
        gen double _weather_feels_like = .      // 体感温度
        gen double _weather_humidity = .        // 湿度
        gen str40 _weather_wind = ""             // 风速风向
        *gen int _weather_aqi = .                // AQI指数
        *gen int _weather_pm25 = .               // PM2.5浓度
        *gen str100 _weather_warning = ""         // 天气预警信息
        gen strL _weather_response = ""          // 存储原始API响应
        gen _weather_timestamp = clock(c(current_date) + " " + c(current_time), "DMY hms") // 查询时间戳
        format _weather_timestamp %tc
    }
    
    // 处理每个观测值
    forvalues i = 1/`total_obs' {
        // 获取当前记录的经纬度值
        local lon = `longitude'[`i']
        local lat = `latitude'[`i']
        
        // 检查经纬度是否有效
        if missing(`lon') | missing(`lat') {
            di as error "  记录 #`i': 经纬度存在缺失值 (lon=`lon', lat=`lat')"
            qui {
                replace _weather_status = "经纬度缺失" in `i'
                replace _weather_location = "无效记录" in `i'
            }
            continue
        }
        
        di as text "处理记录 #`i' : (" %10.6f `lon' ", " %10.6f `lat' ")"
        
        // 构建API请求URL
        local location = "`lon',`lat'"
        local url "https://api.map.baidu.com/weather/v1/?location=`location'&data_type=all&ak=`ak'&coordtype=`coordtype'"
        
        if "`debug'" != "" {
            di as text "API请求URL: `url'"
        }
        
        // 安全获取API数据
        cap {
            copy "`url'" "__temp_weather_response.json", replace
            tempname fh
            file open `fh' using "__temp_weather_response.json", read
            file read `fh' response
            file close `fh'
            if "`debug'" != "" di as text "  原始响应已保存到: __temp_weather_response.json"
        }
        
        // 处理HTTP错误
        if _rc {
            di as error "  API请求失败: HTTP错误代码 " _rc
            qui {
                replace _weather_status = "HTTP错误 " + string(_rc) in `i'
                replace _weather_location = "请求失败" in `i'
            }
            continue
        }
        
        // 解析API状态
        local status = "error"
        if ustrregexm(`"`response'"', `"\"status\":(\d+)"') {
            local status = ustrregexs(1)
            qui replace _weather_status = "状态码 " + string(`status') in `i'
        }
        else {
            qui replace _weather_status = "状态码未知" in `i'
        }
        
        // 检查API状态码
        if `status' != 0 {
            di as error "  API请求失败，状态码: `status'"
            
            if ustrregexm(`"`response'"', `"\"message\":\"([^\"]+)\""') {
                local errmsg = ustrregexs(1)
                di as error "  错误信息: `errmsg'"
                qui replace _weather_location = "`errmsg'" in `i'
            }
            
            continue
        }
        
        // 存储原始响应
        qui replace _weather_response = `"`response'"' in `i'
        
        // 解析位置信息
        local province = ""
        local city = ""
        local name = ""
        
        if ustrregexm(`"`response'"', `"\"province\":\"([^\"]+)\""') local province = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"city\":\"([^\"]+)\""') local city = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"name\":\"([^\"]+)\""') local name = ustrregexs(1)
        
        local location_name = "`province'`city'`name'"
        di as text "  位置信息: `location_name'"
        
        // 解析主要天气数据
        local weather_text = ""
        local temp = ""
        local feels_like = ""
        local humidity = ""
        local wind_class = ""
        local wind_dir = ""
        
        if ustrregexm(`"`response'"', `"\"text\":\"([^\"]+)\""') local weather_text = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"temp\":([\-0-9\.]+)"') local temp = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"feels_like\":([\-0-9\.]+)"') local feels_like = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"rh\":([0-9\.]+)"') local humidity = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"wind_class\":\"([^\"]+)\""') local wind_class = ustrregexs(1)
        if ustrregexm(`"`response'"', `"\"wind_dir\":\"([^\"]+)\""') local wind_dir = ustrregexs(1)
        
        /*// 强化解析AQI和PM2.5数据
        local aqi = ""
        local pm25 = ""
        
        // 方法1：尝试从now对象中提取
        if ustrregexm(`"`response'"', `"\"now\"\s*:\s*\{[^\}]*\"aqi\"\s*:\s*(\d+)"') {
            local aqi = ustrregexs(1)
            if "`debug'" != "" di as text "  方法1找到aqi: `aqi'"
        }
        if ustrregexm(`"`response'"', `"\"now\"\s*:\s*\{[^\}]*\"pm25\"\s*:\s*(\d+)"') {
            local pm25 = ustrregexs(1)
            if "`debug'" != "" di as text "  方法1找到pm25: `pm25'"
        }
        
        // 方法2：在整个响应中搜索
        if "`aqi'" == "" {
            if ustrregexm(`"`response'"', `"\"aqi\"\s*:\s*(\d+)"') {
                local aqi = ustrregexs(1)
                if "`debug'" != "" di as text "  方法2找到aqi: `aqi'"
            }
        }
        if "`pm25'" == "" {
            if ustrregexm(`"`response'"', `"\"pm25\"\s*:\s*(\d+)"') {
                local pm25 = ustrregexs(1)
                if "`debug'" != "" di as text "  方法2找到pm25: `pm25'"
            }
        }
        
        // 方法3：在indexes数组中搜索
        if "`aqi'" == "" {
            if ustrregexm(`"`response'"', `"\"indexes\"\s*:\s*$$[^$$]*\{\s*\"name\"\s*:\s*\"aqi\"[^\}]*\"value\"\s*:\s*\"(\d+)\""') {
                local aqi = ustrregexs(1)
                if "`debug'" != "" di as text "  方法3找到aqi: `aqi'"
            }
        }
        if "`pm25'" == "" {
            if ustrregexm(`"`response'"', `"\"indexes\"\s*:\s*$$[^$$]*\{\s*\"name\"\s*:\s*\"pm25\"[^\}]*\"value\"\s*:\s*\"(\d+)\""') {
                local pm25 = ustrregexs(1)
                if "`debug'" != "" di as text "  方法3找到pm25: `pm25'"
            }
        }
        
        // 方法4：在result对象中搜索
        if "`aqi'" == "" {
            if ustrregexm(`"`response'"', `"\"result\"\s*:\s*\{[^\}]*\"aqi\"\s*:\s*(\d+)"') {
                local aqi = ustrregexs(1)
                if "`debug'" != "" di as text "  方法4找到aqi: `aqi'"
            }
        }
        if "`pm25'" == "" {
            if ustrregexm(`"`response'"', `"\"result\"\s*:\s*\{[^\}]*\"pm25\"\s*:\s*(\d+)"') {
                local pm25 = ustrregexs(1)
                if "`debug'" != "" di as text "  方法4找到pm25: `pm25'"
            }
        }
        
        // 如果仍然未找到，输出警告
        if "`aqi'" == "" & "`debug'" != "" {
            di as text "  警告: 未找到aqi数据"
        }
        if "`pm25'" == "" & "`debug'" != "" {
            di as text "  警告: 未找到pm25数据"
        }
        
        // 处理异常值
        foreach var in temp feels_like humidity aqi pm25 {
            if "``var''" != "" {
                if real("``var''") > 900000 | "``var''" == "999999" | "``var''" == "999" {
                    local `var' = ""
                    if "`debug'" != "" di as text "  异常值处理: `var'"
                }
            }
        }
        
        // 解析天气预警
        local warning = ""
        if ustrregexm(`"`response'"', `"\"alerts\":$$(.*?)$$"') {
            local alerts = ustrregexs(1)
            if `"`alerts'"' != "[]" {
                if ustrregexm(`"`alerts'"', `"\"type\":\"([^\"]+)\""') local wtype = ustrregexs(1)
                if ustrregexm(`"`alerts'"', `"\"level\":\"([^\"]+)\""') local wlevel = ustrregexs(1)
                if ustrregexm(`"`alerts'"', `"\"title\":\"([^\"]+)\""') local wtitle = ustrregexs(1)
                
                local warning = "`wlevel'级`wtype'预警: `wtitle'"
                di as error "  天气预警: `warning'"
            }
        }
        */
		
        // 更新数据
        qui {
            replace _weather_status = "成功" in `i'
            replace _weather_location = "`location_name'" in `i'
            replace _weather_text = "`weather_text'" in `i'
            replace _weather_temp = cond("`temp'" != "", real("`temp'"), .) in `i'
            replace _weather_feels_like = cond("`feels_like'" != "", real("`feels_like'"), .) in `i'
            replace _weather_humidity = cond("`humidity'" != "", real("`humidity'"), .) in `i'
            replace _weather_wind = "`wind_dir' `wind_class'" in `i'
           *replace _weather_aqi = cond("`aqi'" != "", real("`aqi'"), .) in `i'
           *replace _weather_pm25 = cond("`pm25'" != "", real("`pm25'"), .) in `i'
           *replace _weather_warning = "`warning'" in `i'
        }
        
        // 添加延迟以避免请求过快
        if `i' < `total_obs' {
            sleep 200  // 200毫秒延迟
        }
    }
    
    // 删除临时文件
    cap rm "__temp_weather_response.json"
    
    // 重命名变量为友好名称
    qui {
        rename _weather_status weather_status
        rename _weather_location weather_location
        rename _weather_text weather_text
        rename _weather_temp weather_temp
        rename _weather_feels_like weather_feels_like
        rename _weather_humidity weather_humidity
        rename _weather_wind weather_wind
        *rename _weather_aqi weather_aqi
        *rename _weather_pm25 weather_pm25
        *rename _weather_warning weather_warning
        rename _weather_timestamp weather_timestamp
        rename _weather_response weather_response
		
		
		*批量重新加入标签
		label var weather_status       "API状态"
        label var weather_location     "位置信息"
        label var weather_text         "天气描述 " 
        label var weather_temp         "温度 "
        label var weather_feels_like   "体感温度"
        label var weather_humidity     "湿度"
        label var weather_wind         "风速风向"
        label var weather_timestamp    "查询时间戳"
        label var weather_response     " 存储原始API响应"
			
    }
    
    // 计算成功和失败数量
    qui count if weather_status == "成功"
    local success = r(N)
    local fail = _N - `success'
    
    // 输出结果
    di _n(2) as text "{hline}"
    di as text "已完成 " as result `total_obs' as text " 条记录的天气查询"
    di as text "成功记录数: " as result `success'
    di as text "失败记录数: " as result `fail'
    
    // 显示关键天气结果
    di as text _n "关键天气指标:"
    list weather_location weather_text  weather_temp weather_feels_like weather_humidity  weather_wind in 1/`=min(5, _N)', ///
        noobs ab(20) sep(0)
    
    // 保存数据
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
    else if "`clear'" != "" {
        di as text "天气数据已添加到当前数据集"
    }
    
    // 恢复原始数据或保留结果
    if "`clear'" == "" {
        di as text "恢复原始数据集"
        restore
    }
    else {
        di as text "当前数据集已更新为包含天气信息"
    }
end