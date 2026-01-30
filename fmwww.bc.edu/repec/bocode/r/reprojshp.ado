cap program drop reprojshp
program define reprojshp
version 18
    
    syntax anything [, CRS(string)]
    
    * 解析并处理主文件路径（参考 gtiffdisp.ado 的方式）
    local shpfile `anything'
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
    
    * 处理重投影模式
    if `"`crs'"' == "" {
        display as error "Option crs() is required."
        exit 198
    }
    
    * crs 参数可能是 EPSG 代码、GeoTIFF 文件路径或 Shapefile 路径
    local reproj_param `"`crs'"'
    
    * 判断是否为 EPSG 代码：EPSG:4326 格式或纯数字
    local is_epsg = 0
    if strmatch(`"`reproj_param'"', "EPSG:*") {
        local is_epsg = 1
    }
    else if regexm(`"`reproj_param'"', "^[0-9]+$") {
        * 纯数字，自动添加 EPSG: 前缀
        local reproj_param `"EPSG:`reproj_param'"'
        local is_epsg = 1
    }
    
    * 如果不是 EPSG 代码，则视为文件路径，进行规范化处理
    if !`is_epsg' {
        local reproj_file `reproj_param'
        normalize_path, file(`"`reproj_file'"')
        local reproj_param `"`r(filepath)'"'
        * 检查文件是否存在
        capture confirm file `"`reproj_param'"'
        if _rc {
            display as error `"Reproject target file not found: `reproj_param'"'
            exit 601
        }
    }
    
    * 重投影模式只需要发送 shpfile 和 targetCRS 参数
    * Java 代码的 mainCheckOrReproject 方法会在有 targetCRS 时直接进行重投影
    * 确保路径正确传递，去除可能的引号
    local reproj_param_clean : subinstr local reproj_param `"""' "", all
    local reproj_param_clean = trim(`"`reproj_param_clean'"')
    local cmd `""`java_path'" -jar "`jar_path'" "`shpfile'" summary false "`reproj_param_clean'""'
    
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
