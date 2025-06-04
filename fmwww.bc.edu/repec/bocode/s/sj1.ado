*! sj1.ado - Enhanced Stata Journal Navigator - Formatted DOI Output or SJ Content & PDF Links for Paper Browsing in Stata Access
*! Version 1.0
*! Author: Wang Qiang
*! Last Updated: 2025-05-30
*! Requires Stata 13+
*! All retrieved articles are provided exclusively for academic research purposes. 
*! Commercial use is strictly prohibited.

capture program drop sj1
program define sj1
    version 13
    syntax [anything(name=vol_issue)] [, Paper doi help] 
    
    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "SJ1 - Stata Journal Navigator"
        di as text "{hline 78}"
        di as text "Syntax:"
        di as text "    sj1 volume [issue] [, paper doi]"
        di as text ""
        di as text "Description:"
        di as text "    Navigate and access Stata Journal content with enhanced display"
        di as text ""
        di as text "Options:"
        di as text "    paper    Display papers with clickable PDF links"
        di as text "    doi      Display DOI values instead of PDF links"
        di as text "    help     Display this help message"
        di as text ""
        di as text "Examples:"
        di as text "    sj1 19 4, paper  # Show papers with links for vol19 issue4"
        di as text "    sj1 19 4, doi    # Show papers with DOI values"
        di as text "    sj1 19           # Show all issues for volume 19"
        di as text "{hline 78}"
        exit
    }
    
    // 参数验证
    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"
    
    if "`vol'" == "" {
        di as error "Volume number required"
        di as error "Type {stata sj1, help} for usage"
        exit 198
    }
    
    if !inrange(`vol',1,25) {
        di as error "Volume must be integer 1-25"
        exit 198
    }
    
    // 处理期号缺失情况
    if "`iss'" == "" {
        if "`paper'" != "" | "`doi'" != "" {
            forvalues i = 1/4 {
                _sj_display_papers `vol' `i' "`paper'" "`doi'"
                di _n(2)  // 添加额外空行分隔不同期号
            }
        }
        else {
            forvalues i = 1/4 {
                net sj `vol'-`i'
                di _n(2)  // 添加额外空行分隔不同期号
            }
        }
        exit
    }
    
    // 验证期号
    if !inrange(`iss',1,4) {
        di as error "Issue must be integer 1-4"
        exit 198
    }
    
    // 主逻辑
    if "`paper'" != "" | "`doi'" != "" {
        _sj_display_papers `vol' `iss' "`paper'" "`doi'"
    }
    else {
        net sj `vol'-`iss'
    }
end

program define _sj_display_papers
    args vol iss paper doi
    
    tempfile paper_data
    capture copy "https://www.aistata.cn/`vol'-`iss'.txt" "`paper_data'", replace
    if _rc {
        di as error "Failed to load data for Volume `vol' Issue `iss'"
        di as error "Please check your internet connection"
        exit 198
    }
    
    // 显示标题装饰
    di as text _n "{hline 78}"
    di as text _col(25) "Stata Journal Volume `vol', Issue `iss'"
    di as text "{hline 78}"
    
    if "`doi'" != "" {
        di as text _col(30) "Papers with DOI Values"
    }
    else {
        di as text _col(30) "Papers with PDF Links"
    }
    
    di as text "{hline 78}" _n
    
    tempname fh
    file open `fh' using "`paper_data'", read
    file read `fh' line
    
    local count = 0
    while r(eof) == 0 {
        // 跳过标题行和空行
        if substr(trim(`"`macval(line)'"'),1,2) == "SJ" | trim(`"`macval(line)'"') == "" {
            file read `fh' line
            continue
        }
        
        // 添加论文间隔线
        if `count' > 0 {
            di as text "{hline 78}"
        }
        
        // 处理论文行
        _process_paper_line `"`macval(line)'"' "`doi'"
        
        // 添加空行分隔
        di _n
        
        file read `fh' line
        local ++count
    }
    file close `fh'
    
    // 显示统计信息
    di as text "{hline 78}"
    di as text _col(10) "Total papers displayed: " as result "`count'"
    di as text _col(10) "Volume: `vol' | Issue: `iss' | Date: $S_DATE"
    di as text "{hline 78}"
end

program define _process_paper_line
    args line doi_option
    
    // 清理行内容
    local line = trim(subinstr(`"`line'"', "- ", "", 1))
    
    // 分割主内容和链接
    local link_start = strpos(`"`line'"', "[")
    if `link_start' == 0 {
        di as text "`line'"
        exit
    }
    
    // 获取主文本
    local main_text = substr(`"`line'"', 1, `link_start'-1)
    local remaining = substr(`"`line'"', `link_start', .)
    
    // 显示主内容 - 智能换行
    local main_len = strlen(`"`main_text'"')
    if `main_len' > 78 {
        // 在最后一个逗号处分割
        local split_pos = strrpos(`"`main_text'"', ",")
        if `split_pos' == 0 local split_pos = int(`main_len'/2)
        
        local line1 = substr(`"`main_text'"', 1, `split_pos')
        local line2 = substr(`"`main_text'"', `split_pos'+1, .)
        
        di as text _col(5) "`line1'"
        di as text _col(5) "`line2'"
    }
    else {
        di as text _col(5) "`main_text'"
    }
    
    // 处理DOI选项
    if "`doi_option'" != "" {
        // 提取并显示DOI值 - 修复版
        di as text _col(10) "DOI: " _continue
        
        // 查找第一个链接中的DOI
        local url_start = strpos(`"`remaining'"', "https://journals.sagepub.com/doi/pdf/")
        if `url_start' > 0 {
            // 计算DOI起始位置
            local doi_start = `url_start' + 40  // "https://journals.sagepub.com/doi/pdf/" 长度为40
            local doi_end = strpos(substr(`"`remaining'"', `doi_start', .), ")")
            if `doi_end' == 0 local doi_end = strpos(substr(`"`remaining'"', `doi_start', .), ",")
            if `doi_end' == 0 local doi_end = 20 // 默认长度
            
            local doi_value = substr(`"`remaining'"', `doi_start', `doi_end' - 1)
            di as result `"`doi_value'"'
        }
        else {
            // 尝试其他可能的DOI位置
            local url_start = strpos(`"`remaining'"', "10.")
            if `url_start' > 0 {
                local doi_end = strpos(substr(`"`remaining'"', `url_start', .), ")")
                if `doi_end' == 0 local doi_end = strpos(substr(`"`remaining'"', `url_start', .), ",")
                if `doi_end' == 0 local doi_end = 20 // 默认长度
                
                local doi_value = substr(`"`remaining'"', `url_start', `doi_end' - 1)
                di as result `"`doi_value'"'
            }
            else {
                di as error "DOI not found"
            }
        }
    }
    else {
        // 解析并显示链接
        di as text _col(10) "PDF Links: " _continue
        
        local link_count = 0
        while `link_count' < 5 & `"`remaining'"' != "" {
            // 获取链接文本
            local text_start = strpos(`"`remaining'"', "[") + 1
            local text_end = strpos(`"`remaining'"', "]")
            local link_text = substr(`"`remaining'"', `text_start', `text_end' - `text_start')
            
            // 获取链接URL
            local url_start = strpos(`"`remaining'"', "(") + 1
            local url_end = strpos(`"`remaining'"', ")")
            local url = substr(`"`remaining'"', `url_start', `url_end' - `url_start')
            
            // 显示链接
            di as text `"{browse "`url'":`link_text'}"' _continue
            
            // 添加分隔符
            if `link_count' < 4 di as text ", " _continue
            
            // 移除已处理部分
            local remaining = substr(`"`remaining'"', `url_end' + 1, .)
            local ++link_count
        }
    }
end