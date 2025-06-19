*! cie.ado - 中国工业经济期刊知识库导航工具
*! Version 1.2
*! Last Updated: 2025-06-12
*! Requires Stata 14+

capture program drop cie
program define cie
    version 14
    syntax anything(name=year_issue) [, help]
    
    // 显示帮助信息
    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "CIE - 中国工业经济期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    cie 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《中国工业经济》期刊内容"
        di as text ""
        di as text "参数:"
        di as text "    年份    2017年及以后的年份"
        di as text "    期数    01-12之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    cie 2025 05        # 显示2025年第5期内容"
		di as text "    cie 2024 12        # 显示2024年第12期内容"
        di as text "{hline 78}"
        exit
    }
    
    // 参数解析
    tokenize "`year_issue'"
    local year = "`1'"
    local issue = "`2'"
    
    // 参数验证
    if "`year'" == "" | "`issue'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata cie, help} 查看帮助"
        exit 198
    }
    
    // 验证年份是否为有效数字
    capture confirm integer number `year'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }
    
    // 验证期数是否为有效数字
    capture confirm integer number `issue'
    if _rc {
        di as error "期数必须是整数"
        exit 198
    }
    
    // 验证年份范围（从2017年开始）
    if `year' < 2017 {
        di as error "年份必须为2017年及以后"
        exit 198
    }
    
    // 验证期数范围
    if !inrange(`issue', 1, 12) {
        di as error "期数必须在1-12之间"
        exit 198
    }
    
    // 主逻辑
    _cie_display_papers `year' `issue'
end

program define _cie_display_papers
    args year issue
    
    // 构建URL
    local url "https://www.aistata.cn/cie-`year'-`issue'.txt"
    tempfile paper_data
    
    // 下载数据
    capture copy "`url'" "`paper_data'", replace
    if _rc {
        di as error _n "{hline 78}"
        di as error "无法加载`year'年第`issue'期数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该期内容"
        di as error "2. 输入年份或期数有误"
        di as error ""
        di as text "您可以访问《中国工业经济》官网查看最新内容:"
        di as text `"{browse "https://ciejournal.ajcass.com":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }
    
    // 显示标题
    di as text _n "{hline 78}"
    di as text _col(20) "《中国工业经济》`year'年第`issue'期"
    di as text "{hline 78}" _n
    
    // 处理并显示论文
    tempname fh
    file open `fh' using "`paper_data'", read
    file read `fh' line
    
    local count = 0
    
    while r(eof) == 0 {
        // 跳过注释行和空行
        if substr(trim(`"`macval(line)'"'), 1, 1) == "#" | trim(`"`macval(line)'"') == "" {
            file read `fh' line
            continue
        }
        
        // 处理论文行
        _process_cie_line `"`macval(line)'"'
        
        // 添加分隔线
        di as text "{hline 78}"
        
        file read `fh' line
        local ++count
    }
    file close `fh'
    
    // 显示统计信息
    di as text _col(10) "共显示论文: " as result "`count'篇"
    di as text _col(10) "期刊: `year'年 第`issue'期 | 日期: $S_DATE"
    di as text _col(10) `"数据来源：《中国工业经济》，{browse "https://ciejournal.ajcass.com":官网链接}"'
    di as text _col(10) `"cie命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    di as text "{hline 78}"
end

program define _process_cie_line
    args line
    
    // 去除行首的序号（例如："1. "、"10. "等）
    local line = trim(subinstr(`"`line'"', ". ", "", 1))
    
    // 提取标题（标题被**包围）
    local title_start = strpos(`"`line'"', "**") + 2
    local title_end = strpos(substr(`"`line'"', `title_start', .), "**") - 1
    local title = substr(`"`line'"', `title_start', `title_end')
    
    // 显示标题
    di as text _col(5) "`title'"
    
    // 提取PDF链接（修正链接提取）
    local pdf_start = strpos(`"`line'"', "[PDF](") + 6
    if `pdf_start' > 6 {
        local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
        local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
        di as text _col(10) `"{browse "`pdf_url'":PDF}"'
    }
    else {
        di as text _col(10) "PDF链接信息缺失"
    }
    
    // 提取附件链接（修正链接提取）
    local attach_start = strpos(`"`line'"', "[附件](") + 7
    if `attach_start' > 7 {
        local attach_end = strpos(substr(`"`line'"', `attach_start', .), ")")
        local attach_url = substr(`"`line'"', `attach_start', `attach_end' - 1)
        
        // 检查链接是否以"http"开头，避免包含多余字符
        if substr("`attach_url'", 1, 4) != "http" {
            // 如果链接不以http开头，尝试重新定位http位置
            local http_pos = strpos("`attach_url'", "http")
            if `http_pos' > 0 {
                local attach_url = substr("`attach_url'", `http_pos', .)
            }
        }
        
        di as text _col(10) `"{browse "`attach_url'":附件}"'
    }
    else {
        // 检查是否有"无附件"字样
        if strpos(`"`line'"', "无附件") > 0 {
            di as text _col(10) "无附件"
        }
        else {
            // 尝试其他可能的附件标记格式
            local alt_attach_start = strpos(`"`line'"', "附件](")
            if `alt_attach_start' > 0 {
                local attach_start = `alt_attach_start' + 5
                local attach_end = strpos(substr(`"`line'"', `attach_start', .), ")")
                local attach_url = substr(`"`line'"', `attach_start', `attach_end' - 1)
                
                // 清理链接中的多余字符
                local attach_url = subinstr("`attach_url'", "](https", "https", 1)
                di as text _col(10) `"{browse "`attach_url'":附件}"'
            }
            else {
                di as text _col(10) "附件链接信息缺失"
            }
        }
    }
end
