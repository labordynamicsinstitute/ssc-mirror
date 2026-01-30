
cap program drop checkshp
program define checkshp
version 18
    
    syntax anything [, Detail Summary Clean]
    
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
    
    * 验证选项的互斥性
    if ("`detail'" != "" & "`summary'" != "") {
        display as error "Options detail and summary are mutually exclusive."
        exit 198
    }
    
    * 处理检查模式（默认）
    local output_mode "summary"
    if "`detail'" != "" {
        local output_mode "detail"
    }
    
    local delete_flag "false"
    if "`clean'" != "" {
        local delete_flag "true"
    }
    
    local cmd `""`java_path'" -jar "`jar_path'" "`shpfile'" `output_mode' `delete_flag'""'
    
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
