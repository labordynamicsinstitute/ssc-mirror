*! version 1.0.0
*! 文本标准化程序 - 处理全角半角转换、空格清理等
*! Author: Xiaokang Wu
*! Affiliation: Nanjing University of Science and Technology
*! Contact: wuxk@njust.edu.cn
*! Date: 2025

program define cnclean
    version 14.0
    syntax varlist(string) [, ///
        Replace                /// 替换原变量（默认生成新变量）
        GENerate(string)       /// 指定新变量名前缀
        TRIM                   /// 去除首尾空格（默认执行）
        NOTRIM                 /// 不去除首尾空格
        SPACES                 /// 处理多余空格（默认执行）
        NOSPACES              /// 不处理多余空格
        FULLWIDTH             /// 全角转半角（默认执行）
        NOFULLWIDTH           /// 不进行全角转半角
        LOWER                 /// 转换为小写
        UPPER                 /// 转换为大写
        PROPER                /// 首字母大写
        PUNCT                 /// 标准化标点符号
        TABS                  /// 将制表符转为空格
        NEWLINES             /// 移除换行符
        SPECIAL              /// 移除特殊字符
        DIGITS               /// 统一数字格式（全角数字转半角）
        ALPHA                /// 统一字母格式（全角字母转半角）
        VERBOSE              /// 显示详细处理信息
        ]
    
    * 参数冲突检查
    if "`lower'" != "" & "`upper'" != "" {
        display as error "不能同时指定 lower 和 upper 选项"
        exit 198
    }
    if "`lower'" != "" & "`proper'" != "" {
        display as error "不能同时指定 lower 和 proper 选项"
        exit 198
    }
    if "`upper'" != "" & "`proper'" != "" {
        display as error "不能同时指定 upper 和 proper 选项"
        exit 198
    }
    if "`replace'" != "" & "`generate'" != "" {
        display as error "不能同时指定 replace 和 generate 选项"
        exit 198
    }
    
    * 设置默认选项
    if "`notrim'" == "" local trim "trim"
    if "`nospaces'" == "" local spaces "spaces"
    if "`nofullwidth'" == "" local fullwidth "fullwidth"
    
    * 如果没有指定generate且没有replace，默认使用原变量名加_std
    if "`generate'" == "" & "`replace'" == "" {
        local generate "_std"
    }
    
    * 处理每个变量
    foreach var of varlist `varlist' {
        
        * 确认是字符串变量
        capture confirm string variable `var'
        if _rc {
            display as text "`var' 不是字符串变量，跳过"
            continue
        }
        
        * 确定目标变量名
        if "`replace'" != "" {
            local newvar "`var'"
            tempvar tempvar
            quietly gen `tempvar' = `var'
            local sourcevar "`tempvar'"
        }
        else {
            local newvar "`var'`generate'"
            local sourcevar "`var'"
            
            * 检查新变量是否已存在
            capture confirm variable `newvar'
            if !_rc {
                display as error "变量 `newvar' 已存在"
                exit 110
            }
            
            * 创建新变量
            quietly gen `newvar' = `sourcevar'
        }
        
        if "`verbose'" != "" {
            display as text _n "正在处理变量: `var'"
        }
        
        * 1. 全角转半角（包括数字、字母和常用符号）
        if "`fullwidth'" != "" {
            if "`verbose'" != "" display as text "  - 全角转半角..."
            
            * 全角空格转半角空格
            quietly replace `newvar' = ustrregexra(`newvar', "　", " ")
            
            * 全角数字转半角（如果指定了digits选项或默认fullwidth）
            if "`digits'" != "" | "`fullwidth'" != "" {
                forvalues i = 0/9 {
                    local fullwidth_num = uchar(65296 + `i')  // ０-９
                    quietly replace `newvar' = ustrregexra(`newvar', "`fullwidth_num'", "`i'")
                }
            }
            
            * 全角大写字母转半角（如果指定了alpha选项或默认fullwidth）
            if "`alpha'" != "" | "`fullwidth'" != "" {
                forvalues i = 65/90 {
                    local halfwidth_char = char(`i')
                    local fullwidth_char = uchar(65248 + `i')  // Ａ-Ｚ
                    quietly replace `newvar' = ustrregexra(`newvar', "`fullwidth_char'", "`halfwidth_char'")
                }
                
                * 全角小写字母转半角
                forvalues i = 97/122 {
                    local halfwidth_char = char(`i')
                    local fullwidth_char = uchar(65248 + `i')  // ａ-ｚ
                    quietly replace `newvar' = ustrregexra(`newvar', "`fullwidth_char'", "`halfwidth_char'")
                }
            }
            
            * 常用全角符号转半角
            quietly replace `newvar' = ustrregexra(`newvar', "！", "!")
            quietly replace `newvar' = ustrregexra(`newvar', "＂", `"""')
            quietly replace `newvar' = ustrregexra(`newvar', "＃", "#")
            quietly replace `newvar' = ustrregexra(`newvar', "＄", "$")
            quietly replace `newvar' = ustrregexra(`newvar', "％", "%")
            quietly replace `newvar' = ustrregexra(`newvar', "＆", "&")
            quietly replace `newvar' = ustrregexra(`newvar', "＇", "'")
            quietly replace `newvar' = ustrregexra(`newvar', "（", "(")
            quietly replace `newvar' = ustrregexra(`newvar', "）", ")")
            quietly replace `newvar' = ustrregexra(`newvar', "＊", "*")
            quietly replace `newvar' = ustrregexra(`newvar', "＋", "+")
            quietly replace `newvar' = ustrregexra(`newvar', "，", ",")
            quietly replace `newvar' = ustrregexra(`newvar', "－", "-")
            quietly replace `newvar' = ustrregexra(`newvar', "．", ".")
            quietly replace `newvar' = ustrregexra(`newvar', "／", "/")
            quietly replace `newvar' = ustrregexra(`newvar', "：", ":")
            quietly replace `newvar' = ustrregexra(`newvar', "；", ";")
            quietly replace `newvar' = ustrregexra(`newvar', "＜", "<")
            quietly replace `newvar' = ustrregexra(`newvar', "＝", "=")
            quietly replace `newvar' = ustrregexra(`newvar', "＞", ">")
            quietly replace `newvar' = ustrregexra(`newvar', "？", "?")
            quietly replace `newvar' = ustrregexra(`newvar', "＠", "@")
            quietly replace `newvar' = ustrregexra(`newvar', "［", "[")
            quietly replace `newvar' = ustrregexra(`newvar', "＼", "\")
            quietly replace `newvar' = ustrregexra(`newvar', "］", "]")
            quietly replace `newvar' = ustrregexra(`newvar', "＾", "^")
            quietly replace `newvar' = ustrregexra(`newvar', "＿", "_")
            quietly replace `newvar' = ustrregexra(`newvar', "｀", "`")
            quietly replace `newvar' = ustrregexra(`newvar', "｛", "{")
            quietly replace `newvar' = ustrregexra(`newvar', "｜", "|")
            quietly replace `newvar' = ustrregexra(`newvar', "｝", "}")
            quietly replace `newvar' = ustrregexra(`newvar', "～", "~")
        }
        
        * 2. 标准化标点符号
        if "`punct'" != "" {
            if "`verbose'" != "" display as text "  - 标准化标点符号..."
            
            * 中文标点转英文标点（可选）
            quietly replace `newvar' = ustrregexra(`newvar', "。", ".")
            quietly replace `newvar' = ustrregexra(`newvar', "，", ",")
            quietly replace `newvar' = ustrregexra(`newvar', "；", ";")
            quietly replace `newvar' = ustrregexra(`newvar', "：", ":")
            quietly replace `newvar' = ustrregexra(`newvar', "？", "?")
            quietly replace `newvar' = ustrregexra(`newvar', "！", "!")
            quietly replace `newvar' = ustrregexra(`newvar', """, `"""')
            quietly replace `newvar' = ustrregexra(`newvar', """, `"""')
            quietly replace `newvar' = ustrregexra(`newvar', "'", "'")
            quietly replace `newvar' = ustrregexra(`newvar', "'", "'")
            quietly replace `newvar' = ustrregexra(`newvar', "【", "[")
            quietly replace `newvar' = ustrregexra(`newvar', "】", "]")
            quietly replace `newvar' = ustrregexra(`newvar', "《", "<")
            quietly replace `newvar' = ustrregexra(`newvar', "》", ">")
        }
        
        * 3. 处理制表符
        if "`tabs'" != "" {
            if "`verbose'" != "" display as text "  - 制表符转空格..."
            quietly replace `newvar' = ustrregexra(`newvar', "\t", " ")
        }
        
        * 4. 处理换行符
        if "`newlines'" != "" {
            if "`verbose'" != "" display as text "  - 移除换行符..."
            quietly replace `newvar' = ustrregexra(`newvar', "\r\n", " ")
            quietly replace `newvar' = ustrregexra(`newvar', "\n", " ")
            quietly replace `newvar' = ustrregexra(`newvar', "\r", " ")
        }
        
        * 5. 移除特殊字符（保留基本ASCII字符和中文）
        if "`special'" != "" {
            if "`verbose'" != "" display as text "  - 移除特殊字符..."
            * 保留：英文字母、数字、基本标点、空格和中文字符
            quietly replace `newvar' = ustrregexra(`newvar', "[^\x20-\x7E\u4E00-\u9FFF\u3000-\u303F]", "")
        }
        
        * 6. 处理多余空格
        if "`spaces'" != "" {
            if "`verbose'" != "" display as text "  - 处理多余空格..."
            * 多个空格替换为单个空格
            quietly replace `newvar' = ustrregexra(`newvar', "[ ]+", " ")
            * 移除标点符号前的空格
            quietly replace `newvar' = ustrregexra(`newvar', " ([,.\!\?;:）】])", "$1")
            * 移除左括号后的空格
            quietly replace `newvar' = ustrregexra(`newvar', "([\(（【]) ", "$1")
        }
        
        * 7. 去除首尾空格
        if "`trim'" != "" {
            if "`verbose'" != "" display as text "  - 去除首尾空格..."
            quietly replace `newvar' = ustrtrim(`newvar')
        }
        
        * 8. 大小写转换
        if "`lower'" != "" {
            if "`verbose'" != "" display as text "  - 转换为小写..."
            quietly replace `newvar' = ustrlower(`newvar')
        }
        else if "`upper'" != "" {
            if "`verbose'" != "" display as text "  - 转换为大写..."
            quietly replace `newvar' = ustrupper(`newvar')
        }
        else if "`proper'" != "" {
            if "`verbose'" != "" display as text "  - 首字母大写..."
            quietly replace `newvar' = ustrtitle(`newvar')
        }
        
        * 如果是replace模式，将处理后的数据复制回原变量
        if "`replace'" != "" {
            quietly replace `var' = `newvar'
            drop `tempvar'
        }
        
        * 显示完成信息
        if "`verbose'" != "" {
            if "`replace'" != "" {
                display as text "  变量 `var' 已标准化"
            }
            else {
                display as text "  已创建标准化变量 `newvar'"
            }
        }
    }
    
    * 显示总体完成信息
    local nvars : word count `varlist'
    if "`verbose'" == "" {
        if "`replace'" != "" {
            display as result "`nvars' 个变量已完成标准化处理"
        }
        else {
            display as result "`nvars' 个标准化变量已创建（后缀: `generate'）"
        }
    }
    
end

* 定义帮助文件内容
* 使用方法示例：
* cnclean varname
* cnclean var1 var2 var3, replace
* cnclean varlist, gen(_clean) lower spaces
* cnclean text*, upper trim punct verbose