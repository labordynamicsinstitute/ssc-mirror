*! reduce_aigc.ado
*! You can enter "help reduce_aigc/help reduce_quickref" for help.
*! Reduce AIGC similarity with bilingual support
*! Version: 8.0
*! Date: 06June2026
*! Authors: 
*!   Wu Lianghai, School of Business, Anhui University of Technology (AHUT), Ma'anshan, China
*!   Email: agd2010@yeah.net
*!   Wu Hanyan, School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), China
*!   Email: 2325476320@qq.com
*!   Chen Liwen, School of Business, Anhui University of Technology (AHUT), Ma'anshan, China
*!   Email: 2184844526@qq.com

capture program drop reduce_aigc
program define reduce_aigc
    version 12.0

    syntax , INPUT(string) [ OUTPUT(string) TARGET(real 0.3) INTENSITY(real 0.5) ///
                            DICT(string) METHODS(string) LANGUAGE(string) ]

    * Get the directory where this ado file is located
    local ado_dir = c(sysdir_personal)
    if substr("`ado_dir'", length("`ado_dir'"), 1) != "/" & ///
       substr("`ado_dir'", length("`ado_dir'"), 1) != "\" {
        local ado_dir "`ado_dir'/"
    }
    
    * Python script path (same directory as ado file)
    local python_script "`ado_dir'reduce_word.py"
    
    * Input file check
    local input_file `input'
    capture confirm file "`input_file'"
    if _rc != 0 {
        di as error "Error: Cannot find file `input_file'"
        exit 601
    }
    
    * Check if Python script exists
    capture confirm file "`python_script'"
    if _rc != 0 {
        di as error "Error: Cannot find Python script: `python_script'"
        di as error "Please ensure reduce_word.py is in the same directory as reduce_aigc.ado"
        di as error "Current personal ado directory: `ado_dir'"
        exit 601
    }

    * Validate parameters
    if `target' < 0.1 | `target' > 0.95 {
        di as error "Error: Target similarity must be between 0.1 and 0.95"
        exit 198
    }
    if `intensity' < 0.1 | `intensity' > 0.95 {
        di as error "Error: Intensity must be between 0.1 and 0.95"
        exit 198
    }

    * Language setting (default: zh)
    if missing("`language'") {
        local lang "zh"
    }
    else {
        local lang = lower("`language'")
        if !inlist("`lang'", "en", "zh") {
            di as error "Error: Language must be 'en' or 'zh'"
            exit 198
        }
    }

    * Output file
    if missing("`output'") {
        local output_file = subinstr("`input_file'", ".docx", "_reduced.docx", .)
        if "`input_file'" == "`output_file'" {
            local output_file "`input_file'_reduced.docx"
        }
    }
    else {
        local output_file `output'
        if strpos("`output_file'", ".docx") == 0 {
            local output_file "`output_file'.docx"
        }
    }

    * Display info
    di _n "============================================================"
    if "`lang'" == "zh" {
        di "AI-GC Reduce - 文档降重处理（双语支持）"
    }
    else {
        di "AI-GC Reduce - Document Similarity Reduction (Bilingual)"
    }
    di "============================================================"
    di "输入文件:   `input_file'"
    di "输出文件:   `output_file'"
    di "目标相似度: `target' * 100%"
    di "降重强度:   `intensity' * 100%"
    di "语言模式:   `lang'"
    if !missing("`methods'") {
        di "使用的方法:   `methods'"
    }
    if !missing("`dict'") {
        di "用户词典:   `dict'"
    }
    di "Python脚本: `python_script'"
    di "============================================================"

    di _n "正在处理，请耐心等待..."

    * Build command with full paths
    local cmd python "`python_script'" "`input_file'" -o "`output_file'" -t `target' -i `intensity' -l `lang'
    if !missing("`dict'") {
        local cmd `cmd' -d "`dict'"
    }
    if !missing("`methods'") {
        local cmd `cmd' -m "`methods'"
    }

    * Execute
    !`cmd'

    if _rc == 0 {
        capture confirm file "`output_file'"
        if _rc == 0 {
            di _n "============================================================"
            di as result "✓ 降重处理完成！"
            di as text "输出文件: " as result "`output_file'"
            di "============================================================"
        }
        else {
            di as error "警告：未找到输出文件"
        }
    }
    else {
        di as error _n "错误：执行失败（返回码：_rc）"
        di as error "请检查Python环境和python-docx包是否已安装"
        di as error "安装命令: pip install python-docx jieba"
    }

end