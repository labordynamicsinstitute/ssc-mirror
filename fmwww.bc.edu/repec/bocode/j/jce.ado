*! jce.ado - 中国经济学期刊导航工具
*! Version 1.0
*! Last Updated: 2025-06-30
*! Requires Stata 17+

capture program drop jce
program define jce
    version 18
    syntax anything(name=vol_issue) [, help]

    // 显示帮助信息
    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "JCE - 中国经济学期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    jce 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《中国经济学》期刊内容"
        di as text ""
        di as text "参数:"
        di as text "    年份    2022年及以后的年份"
        di as text "    期数    1-4之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    jce 2024 2          # 显示2024年第2期内容"
        di as text "    jce 2024 2, help    # 显示帮助信息"
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
        di as error "输入 {stata jce, help} 查看帮助"
        exit 198
    }

    // 验证年份是否为有效数字
    capture confirm integer number `vol'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }

    // 验证年份范围
    if `vol' < 2022 {
        di as error "年份必须大于或等于2022"
        exit 198
    }

    // 验证期数是否为有效数字
    capture confirm integer number `iss'
    if _rc {
        di as error "期数必须是整数"
        exit 198
    }

    // 验证期数范围
    if !inrange(`iss', 1, 4) {
        di as error "期数必须在1-4之间"
        exit 198
    }

    // 主逻辑
    _jce_display_papers `vol' `iss'
end

program define _jce_display_papers
    args vol iss

    // 构建URL
    local url "https://www.aistata.cn/`vol'jce.txt"
    tempfile journal_data

    // 下载数据
    capture copy "`url'" "`journal_data'", replace
    if _rc {
        di as error _n "{hline 78}"
        di as error "无法加载`vol'年数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该年内容"
        di as error "2. 输入年份有误"
        di as error ""
        di as text "您可以访问《中国经济学》官网查看最新内容:"
        di as text `"{browse "https://www.jcejournal.com.cn/":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }

    // 显示标题
    di as text _n "{hline 78}"
    di as text _col(20) "《中国经济学》`vol'年第`iss'辑"
    di as text "{hline 78}" _n

    // 处理并显示论文
    tempname fh
    file open `fh' using "`journal_data'", read
    file read `fh' line

    local found_issue = 0
    local paper_count = 0
    local current_date = c(current_date)
    local issue_pattern = "第`iss'辑"

    // 存储当前论文信息的临时变量
    local current_title ""
    local current_html_url ""

    while r(eof) == 0 {
        // 查找目标期数
        if `found_issue' == 0 {
            if strpos(`"`macval(line)'"', "# 中国经济学 `vol'年`issue_pattern'") > 0 {
                local found_issue = 1
                file read `fh' line  // 跳过刊出日期行
            }
            file read `fh' line
            continue
        }

        // 检查是否到达下一期
        if strpos(`"`macval(line)'"', "# 中国经济学") > 0 {
            // 输出最后一篇可能未完成的论文
            if "`current_title'" != "" {
                di as text "    `current_title'"
                di as text _col(8) `"{browse "`current_html_url'":HTML网页}"'
                di as text "{hline 78}"
                local paper_count = `paper_count' + 1
                local current_title ""
                local current_html_url ""
            }
            continue, break
        }

        // 跳过空行
        if trim(`"`macval(line)'"') == "" {
            file read `fh' line
            continue
        }

        // 提取论文标题和HTML链接 
        // 修改点1：使用[^\]]+替代.*?
        local title_regex = "^[0-9]+\.\s*\*\*\s*\[([^\]]+)\]\((https?://[^\)]+)\)\s*\*\*"
        if regexm(`"`line'"', "`title_regex'") {
            // 输出上一篇已解析的论文（如果有）
            if "`current_title'" != "" {
                di as text "    `current_title'"
                di as text _col(8) `"{browse "`current_html_url'":HTML网页}"'
                di as text "{hline 78}"
                local paper_count = `paper_count' + 1
            }
            
            // 存储当前论文信息
            local current_title = regexs(1)
            local current_html_url = regexs(2)
        }

        // 提取PDF链接 - 
        // 修改点2：保持原样（已兼容）
        local pdf_regex = "\[PDF下载\]\((https?://[^\)]+)\)"
        if regexm(`"`line'"', "`pdf_regex'") {
            local pdf_url = regexs(1)
            
            // 如果有存储的标题和HTML链接，输出完整信息
            if "`current_title'" != "" {
                di as text "    `current_title'"
                di as text _col(8) `"{browse "`current_html_url'":HTML网页}"'
                *di as text _col(8) `"{browse "`pdf_url'":PDF}"'
                di as text "{hline 78}"
                local paper_count = `paper_count' + 1
                
                // 重置临时变量
                local current_title ""
                local current_html_url ""
            }
        }

        file read `fh' line
    }

    file close `fh'

    // 检查是否找到目标期数
    if `found_issue' == 0 {
        di as error "未找到`vol'年第`iss'辑的数据"
        di as text "{hline 78}"
        exit
    }

    // 显示统计信息
    di as text _col(10) "共显示论文: " as result "`paper_count'篇"
    di as text _col(10) "期刊: `vol'年 第`iss'辑 | 日期: `current_date'"
    di as text _col(10) `"数据来源：《中国经济学》，{browse "https://www.jcejournal.com.cn/":官网链接}"'
    di as text _col(10) `"jce命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    di as text "{hline 78}"
end