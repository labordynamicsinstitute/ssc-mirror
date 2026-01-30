cap program drop intershp
program define intershp
version 18
    
    syntax anything(name=args) [, MERGE GROUP(string) CRS(string)]
    
    * 解析参数：期望格式为 shpfile1 with(shpfile2)
    tokenize `"`args'"', parse(" with(")
    local shpfile `1'
    
    * 检查是否有 with() 参数
    local has_with = 0
    local with_file = ""
    if `"`2'"' == "with(" {
        local with_file `3'
        * 去除可能的右括号
        local with_file : subinstr local with_file ")" "", all
        local has_with = 1
    }
    
    * 如果没有找到 with()，尝试从 anything 中解析
    if !`has_with' {
        * 尝试查找 "with(" 字符串
        local args_lower = lower(`"`args'"')
        local with_pos = strpos(`"`args_lower'"', " with(")
        if `with_pos' > 0 {
            local shpfile = substr(`"`args'"', 1, `with_pos' - 1)
            local with_part = substr(`"`args'"', `with_pos' + 6, .)
            * 提取 with() 中的内容
            local with_end = strpos(`"`with_part'"', ")")
            if `with_end' > 0 {
                local with_file = substr(`"`with_part'"', 1, `with_end' - 1)
                local has_with = 1
            }
        }
    }
    
    * 如果还是没有找到，报错
    if !`has_with' | `"`with_file'"' == "" {
        display as error "Syntax: intershp shpfile1 with(shpfile2) [, options]"
        display as error "with() is required and must be specified before the comma."
        exit 198
    }
    
    * 解析并处理主文件路径（参考 gtiffdisp.ado 的方式）
    local shpfile = trim(`"`shpfile'"')
    normalize_path, file(`"`shpfile'"')
    local shpfile `"`r(filepath)'"'
    capture confirm file `"`shpfile'"'
    if _rc {
        display as error `"shapefile not found: `shpfile'"'
        exit 601
    }
    
    * 自动确定 Java 路径
    capture java query
    if _rc == 0 {
        local java_home_dir `"`c(java_home)'"'
        local java_path `"`java_home_dir'bin/java.exe"'
        local java_path : subinstr local java_path "\" "/", all
        * 确保 java_path 被正确引用（包含空格时）
        capture confirm file `"`java_path'"'
        if _rc {
            display as error "Java not found. Please install Java and configure it in Stata using {cmd:set java_home}."
            exit 601
        }
    }
    else {
        * 尝试系统 PATH 中的 java
        local java_path "java"
    }
    
    * 自动查找 JAR 文件路径
    * 使用 findfile 在 Stata 搜索路径中查找 JAR 文件
    capture findfile checkshp-0.1.0.jar
    if _rc {
        display as error "JAR file not found: checkshp-0.1.0.jar"
        display as error "Please ensure the JAR file is in your Stata search path."
        exit 601
    }
    local jar_path `"`r(fn)'"'
    local jar_path : subinstr local jar_path "\" "/", all
    
    * 处理相交模式
    normalize_path, file(`"`with_file'"')
    local with_file `"`r(filepath)'"'
    capture confirm file `"`with_file'"'
    if _rc {
        display as error `"Shapefile not found: `with_file'"'
        exit 601
    }
    
    * 构建相交命令（确保所有路径都用引号包裹）
    local cmd `""`java_path'" -jar "`jar_path'" "`shpfile'" intersect "`with_file'""'
    
    * 检查投影参数是否提供（必选项）
    if "`crs'" == "" {
        display as error "crs() is required for intersection calculation."
        display as error "  Usage: crs(EPSG_code|tif_file|shp_file)"

        exit 198
    }
    
    * crs 参数可能是 EPSG 代码、GeoTIFF 文件路径或 Shapefile 路径
    local crs_param `"`crs'"'
    
    * 判断是否为 EPSG 代码：EPSG:4326 格式或纯数字
    local is_epsg = 0
    if strmatch(`"`crs_param'"', "EPSG:*") {
        local is_epsg = 1
    }
    else if regexm(`"`crs_param'"', "^[0-9]+$") {
        local crs_param `"EPSG:`crs_param'"'
        local is_epsg = 1
    }
    
    * 如果不是 EPSG 代码，则视为文件路径，进行规范化处理
    if !`is_epsg' {
        local crs_file `crs_param'
        normalize_path, file(`"`crs_file'"')
        local crs_param `"`r(filepath)'"'
        * 检查文件是否存在
        capture confirm file `"`crs_param'"'
        if _rc {
            display as error `"Projection reference file not found: `crs_param'"'
            exit 601
        }
    }
    
    * 确保路径正确传递，去除可能的引号
    local crs_param_clean : subinstr local crs_param `"""' "", all
    local crs_param_clean = trim(`"`crs_param_clean'"')
    local cmd `"`cmd' --projection "`crs_param_clean'""'
    
    if "`merge'" != "" {
        local cmd `"`cmd' --merge-shp2"'
    }
    
    * clip功能现在默认启用，不再需要选项参数
    
    if "`group'" != "" {
        * 处理 group 字段名，去除引号（字段名不应包含引号）
        * Stata 的 syntax GROUP(string) 会自动去除引号，但我们再次确保
        local group_field "`group'"
        removequotes, file("`group_field'")
        local group_field `r(file)'
        * 去除首尾空格和可能残留的引号
        local group_field = trim(`"`group_field'"')
        if substr(`"`group_field'"', 1, 1) == `"""' {
            local group_field = substr(`"`group_field'"', 2, .)
        }
        if substr(`"`group_field'"', -1, 1) == `"""' {
            local len = length(`"`group_field'"') - 1
            if `len' > 0 {
                local group_field = substr(`"`group_field'"', 1, `len')
            }
        }
        * 直接传递字段名，不需要引号包裹（字段名通常不包含空格）
        local cmd `"`cmd' --group-field `group_field'"'
    }
    
    shell `cmd'
    
end


cap program drop removequotes
program define removequotes, rclass
    version 16
    syntax, file(string)
    return local file `file'
end


cap program drop normalize_path
program define normalize_path, rclass
    version 16
    syntax, file(string)
    
    removequotes, file(`file')
    local filepath `r(file)'
    
    local filepath : subinstr local filepath "\" "/", all
    
    local path_len = length(`"`filepath'"')
    local is_absolute = 0
    
    if `path_len' >= 3 {
        local first_char = substr(`"`filepath'"', 1, 1)
        local second_char = substr(`"`filepath'"', 2, 1)
        local third_char = substr(`"`filepath'"', 3, 1)
        
        if regexm(`"`first_char'"', "[a-zA-Z]") & `"`second_char'"' == ":" & `"`third_char'"' == "/" {
            local is_absolute = 1
        }
    }
    
    if !`is_absolute' & substr(`"`filepath'"', 1, 1) == "/" {
        local is_absolute = 1
    }
    
    if !`is_absolute' {
        local pwd `"`c(pwd)'"'
        local pwd : subinstr local pwd "\" "/", all
        * 确保 pwd 以斜杠结尾
        if substr(`"`pwd'"', -1, 1) != "/" {
            local pwd = `"`pwd'/"'
        }
        local filepath = `"`pwd'`filepath'"'
    }
    
    local filepath : subinstr local filepath "\" "/", all
    
    return local filepath `"`filepath'"'
end
