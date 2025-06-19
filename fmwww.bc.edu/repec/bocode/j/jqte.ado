*! jqte.ado - 数量经济技术经济研究期刊知识库导航工具
*! Version 1.2
*! Last Updated: 2025-06-11
*! Requires Stata 14+

capture program drop jqte
program define jqte
    version 14
    syntax anything(name=vol_issue) [, help]
    
    // 显示帮助信息
    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "JQTE - 数量经济技术经济研究期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    jqte 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《数量经济技术经济研究》期刊内容"
        di as text ""
        di as text "参数:"
        di as text "    年份    2018年及以后的年份"
        di as text "    期数    1-12之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    jqte 2025 5   # 显示2025年第5期内容"
        di as text "    jqte, help    # 显示帮助信息"
        di as text "{hline 78}"
        exit
    }
    
    // 参数解析
    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"
    
    // 参数验证
    if "`vol'" == "" | "`iss'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata jqte, help} 查看帮助"
        exit 198
    }
    
    // 验证年份是否为有效数字
    capture confirm integer number `vol'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }
    
    // 验证期数是否为有效数字
    capture confirm integer number `iss'
    if _rc {
        di as error "期数必须是整数"
        exit 198
    }
    
    // 验证期数范围
    if !inrange(`iss', 1, 12) {
        di as error "期数必须在1-12之间"
        exit 198
    }
    
    // 主逻辑
    _jqte_display_papers `vol' `iss'
end

program define _jqte_display_papers
    args vol iss
    
    // 构建URL
    local url "https://www.aistata.cn/`vol'-`iss'.txt"
    tempfile paper_data
    
    // 下载数据
    capture copy "`url'" "`paper_data'", replace
    if _rc {
        // 智能错误处理
        di as error _n "{hline 78}"
        di as error "无法加载第`vol'年第`iss'期数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该期内容"
        di as error "2. 输入年份或期数有误"
        di as error ""
        di as text "您可以访问《数量经济技术经济研究》官网查看最新内容:"
        di as text `"{browse "https://www.jqte.net/sljjjsjjyj/ch/index.aspx":官网链接}"'
        di as error "{hline 78}"
        
        // 提供可能的解决方案
        di as text _n "建议操作:"
        di as text "1. 检查输入是否正确 (年份: `vol', 期数: `iss')"
        di as text "2. 尝试访问官网确认该期是否已发布"
        di as text "3. 稍后再试，数据库可能正在更新"
        di as text "{hline 78}"
        exit 198
    }
    
    // 显示标题
    di as text _n "{hline 78}"
    di as text _col(20) "《数量经济技术经济研究》`vol'年第`iss'期"
    di as text "{hline 78}" _n
    
    // 处理并显示论文
    tempname fh
    file open `fh' using "`paper_data'", read
    file read `fh' line
    
    local count = 0
    local format_type = "new" // 默认使用新格式
    
    // 检查是否为旧格式（2018-2022.8）
    if (`vol' < 2022) | (`vol' == 2022 & `iss' < 9) {
        local format_type = "old"
    }
    
    while r(eof) == 0 {
        // 跳过标题行和空行
        if substr(trim(`"`macval(line)'"'), 1, 1) == "#" | trim(`"`macval(line)'"') == "" {
            file read `fh' line
            continue
        }
        
        // 根据格式类型处理论文行
        if "`format_type'" == "old" {
            _process_old_format_line `"`macval(line)'"'
        }
        else {
            _process_new_format_line `"`macval(line)'"'
        }
        
        // 添加分隔线
        di as text "{hline 78}"
        
        file read `fh' line
        local ++count
    }
    file close `fh'
    
    // 显示统计信息
    di as text _col(10) "共显示论文: " as result "`count'篇"
	di as text _col(10) "Note：部分期数第一篇及第二篇论文重复，请注意查看，显示篇数总数等信息以官网为准！"
    di as text _col(10) "期刊: `vol'年 第`iss'期 | 日期: $S_DATE"
    
    // 添加来源信息
    di as text _col(10) `"来源：《数量经济技术经济研究》，{browse "https://www.jqte.net/sljjjsjjyj/ch/index.aspx":官网链接}"'
    
    // 添加数据支持信息
    di as text _col(10) `"jqte命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    
    di as text "{hline 78}"
end

// 处理新格式（2022.9及以后）
program define _process_new_format_line
    args line
    
    // 提取标题
    local title_start = strpos(`"`line'"', "• ") + 2
    local title_end = strpos(`"`line'"', ". [-PDF-]")
    local title = substr(`"`line'"', `title_start', `title_end' - `title_start')
    di as text _col(5) "`title'"
    
    // 提取PDF链接
    local pdf_prefix = "[-PDF-]("
    local pdf_start = strpos(`"`line'"', "`pdf_prefix'") + strlen("`pdf_prefix'")
    local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
    local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
    
    // 提取附件链接
    local attach_prefix = "[-附件-]("
    local attach_start = strpos(`"`line'"', "`attach_prefix'") + strlen("`attach_prefix'")
    local attach_end = strpos(substr(`"`line'"', `attach_start', .), ")")
    local attach_url = substr(`"`line'"', `attach_start', `attach_end' - 1)
    
    // 清理URL中的多余字符
    local pdf_url = strtrim(subinstr(`"`pdf_url'"', " ", "", .))
    local attach_url = strtrim(subinstr(`"`attach_url'"', " ", "", .))
    
    // 显示链接
    di as text _col(10) `"{browse "`pdf_url'":PDF} | {browse "`attach_url'":附件}"'
end

// 处理旧格式（2018-2022.8）
program define _process_old_format_line
    args line
    
    // 提取标题
    local title_start = strpos(`"`line'"', ". ") + 2
    if `title_start' == 2 {
        local title_start = 1 // 如果没有序号，从行首开始
    }
    
    local title_end = strpos(`"`line'"', "[-PDF-]")   
    local title = substr(`"`line'"', `title_start', `title_end' - `title_start')
    
    // 清理标题末尾的标点符号
    local last_char = substr(`"`title'"', -1, 1)
    if inlist(`"`last_char'"', "，", ",", "。", ".") {
        local title = substr(`"`title'"', 1, strlen(`"`title'"') - 1)
    }
    
    di as text _col(5) "`title'"
    
    // 提取PDF链接
    local pdf_prefix = "[-PDF-]("
    local pdf_start = strpos(`"`line'"', "`pdf_prefix'") + strlen("`pdf_prefix'")
    local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
    local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
    
    // 清理URL中的多余字符
    local pdf_url = strtrim(subinstr(`"`pdf_url'"', " ", "", .))
    
    // 显示链接（旧格式只有PDF）
    di as text _col(10) `"{browse "`pdf_url'":PDF}"'
end
