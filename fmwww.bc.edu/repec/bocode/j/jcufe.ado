*! jcufe.ado - 《中央财经大学学报》知识库导航工具
*! Version 1.1
*! Last Updated: 2025-06-28
*! Requires Stata 14+

capture program drop jcufe
program define jcufe
    version 14
    syntax anything(name=vol_issue) [, help]

    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "JCUFE - 中央财经大学学报导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    jcufe 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《中央财经大学学报》期刊内容"
        di as text ""
        di as text "参数:"
        di as text "    年份    2015年及以后的年份"
        di as text "    期数    1-12之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    jcufe 2024 1   # 显示2024年第1期内容"
        di as text "    jcufe 2024 1, help    # 显示帮助信息"
        di as text "{hline 78}"
        exit
    }

    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"

    if "`vol'" == "" | "`iss'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata jcufe, help} 查看帮助"
        exit 198
    }

    capture confirm integer number `vol'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }

    if `vol' < 2015 {
        di as error "年份必须大于或等于2015"
        exit 198
    }

    capture confirm integer number `iss'
    if _rc {
        di as error "期数必须是整数"
        exit 198
    }

    if !inrange(`iss', 1, 12) {
        di as error "期数必须在1-12之间"
        exit 198
    }

    _jcufe_display_papers `vol' `iss'
end

program define _jcufe_display_papers
    args vol iss

    local url "https://www.aistata.cn/jcufe_`vol'.txt"
    tempfile journal_data

    capture copy "`url'" "`journal_data'", replace
    if _rc {
        di as error _n "{hline 78}"
        di as error "无法加载`vol'年数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该年内容"
        di as error "2. 输入年份有误"
        di as error ""
        di as text "您可以访问《中央财经大学学报》官网查看最新内容:"
        di as text `"{browse "https://xbbjb.cufe.edu.cn/CN/home":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }

    di as text _n "{hline 78}"
    di as text _col(20) "《中央财经大学学报》`vol'年第`iss'期"
    di as text "{hline 78}" _n

    tempname fh
    file open `fh' using "`journal_data'", read
    file read `fh' line

    local found_issue = 0
    local paper_count = 0
    local current_date = c(current_date)

    while r(eof) == 0 {
        if `found_issue' == 0 {
            if strpos(`"`macval(line)'"', "## `vol'年第`iss'期") > 0 {
                local found_issue = 1
                file read `fh' line  // Skip the source URL line
                file read `fh' line  // Skip the next line (usually empty or source URL)
            }
            file read `fh' line
            continue
        }

        if strpos(`"`macval(line)'"', "## ") > 0 {
            continue, break
        }

        // Skip lines that are not paper entries
        if trim(`"`macval(line)'"') == "" | substr(trim(`"`macval(line)'"'), 1, 1) == "#" | ustrleft(trim(`"`macval(line)'"'),5)=="源URL:" {
            file read `fh' line
            continue
        }

        // Fix 1: Correct HTML URL extraction to remove extra characters
        local title_start = strpos(`"`line'"', ". ") + 2
        local title_end = strpos(`"`line'"', "[-")
        if `title_end' == 0 local title_end = .
        local title = substr(`"`line'"', `title_start', `title_end' - `title_start')
        local title = ustrtrim(subinstr(`"`title'"', "，", "", .))
        
        di as text "    `title'"

        // Fix 2: Correct URL extraction by removing leading ']('
        if strpos(`"`line'"', "[-HTML网页-](") > 0 {
            local html_start = strpos(`"`line'"', "[-HTML网页-](") + 13
            if `html_start' > 13 {
                local html_end = strpos(substr(`"`line'"', `html_start', .), ")")
                local html_url = substr(`"`line'"', `html_start', `html_end' - 1)
                
                // Remove any leading '](' in URLs
                while inlist(substr(`"`html_url'"', 1, 1), "]", "(") {
                    local html_url = substr(`"`html_url'"', 2, .)
                }
                
                di as text _col(8) `"{browse "`html_url'":HTML网页}"'
            }
        }

        // Apply the same fix to PDF URLs
        if strpos(`"`line'"', "[-PDF-](") > 0 {
            local pdf_start = strpos(`"`line'"', "[-PDF-](") + 8
            if `pdf_start' > 8 {
                local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
                local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
                
                // Remove any leading '](' in URLs
                while inlist(substr(`"`pdf_url'"', 1, 1), "]", "(") {
                    local pdf_url = substr(`"`pdf_url'"', 2, .)
                }
                
                di as text _col(8) `"{browse "`pdf_url'":PDF}"'
            }
        }

        di as text "{hline 78}"
        local paper_count = `paper_count' + 1
        file read `fh' line
    }

    file close `fh'

    if `found_issue' == 0 {
        di as error "未找到`vol'年第`iss'期的数据"
        di as text "{hline 78}"
        exit
    }

    di as text _col(10) "共显示论文: " as result "`paper_count'篇"
    di as text _col(10) "期刊: `vol'年 第`iss'期 | 日期: `current_date'"
    di as text _col(10) `"数据来源：《中央财经大学学报》，{browse "https://xbbjb.cufe.edu.cn/CN/home":官网链接}"'
    di as text _col(10) `"jcufe命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    di as text "{hline 78}"
end