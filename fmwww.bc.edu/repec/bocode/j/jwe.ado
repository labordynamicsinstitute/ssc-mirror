*! jwe.ado - 《世界经济》期刊导航工具
*! Version 1.0
*! Last Updated: 2025-07-01
*! Requires Stata 14+

capture program drop jwe
program define jwe
    version 14
    syntax anything(name=vol_issue) [, help]

    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(25) "JWE - 《世界经济》期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    jwe 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《世界经济》期刊论文"
        di as text ""
        di as text "参数:"
        di as text "    年份    2016年及以后的年份"
        di as text "    期数    1-12之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    jwe 2024 1   # 显示2024年第1期内容"
        di as text "    jwe 2024 1, help    # 显示帮助信息"
        di as text "{hline 78}"
        exit
    }

    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"

    if "`vol'" == "" | "`iss'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata jwe, help} 查看帮助"
        exit 198
    }

    capture confirm integer number `vol'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }

    if `vol' < 2016 {
        di as error "年份必须大于或等于2016"
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

    _jwe_display_papers `vol' `iss'
end

program define _jwe_display_papers
    args vol iss

    local url "https://www.aistata.cn/jwe_`vol'.txt"
    tempfile journal_data

    capture copy "`url'" "`journal_data'", replace
    if _rc {
        di as error _n "{hline 78}"
        di as error "无法加载`vol'年数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该年内容"
        di as error "2. 输入年份有误"
        di as error ""
        di as text "您可以访问《世界经济》官网查看最新内容:"
        di as text `"{browse "https://manu30.magtech.com.cn/sjjj/CN/home":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }

    di as text _n "{hline 78}"
    di as text _col(25) "《世界经济》`vol'年第`iss'期"
    di as text "{hline 78}" _n

    tempname fh
    file open `fh' using "`journal_data'", read
    file read `fh' line

    local found_issue = 0
    local paper_count = 0
    local current_date = c(current_date)

    while r(eof) == 0 {
        // 检查是否找到目标期数
        if `found_issue' == 0 {
            if strpos(`"`macval(line)'"', "## `vol'年第`iss'期") > 0 {
                local found_issue = 1
            }
            file read `fh' line
            continue
        }

        // 检查是否到达下一期或文件结尾
        if strpos(`"`macval(line)'"', "## ") > 0 {
            continue, break
        }

        // 跳过空行、注释行和源URL行
        if trim(`"`macval(line)'"') == "" | ///
           substr(trim(`"`macval(line)'"'), 1, 1) == "#" | ///
           ustrregexm(`"`macval(line)'"', "^源URL:") {
            file read `fh' line
            continue
        }

        // 处理论文标题行
        if ustrregexm(`"`macval(line)'"', "^\d+\.\s+\*\*(.+)\*\*") {
            local title = ustrregexs(1)
            local title = ustrtrim(subinstr(`"`title'"', "，", "", .))
            di as text "    `title'"
            local paper_count = `paper_count' + 1
        }
        // 处理HTML链接行
        else if strpos(`"`macval(line)'"', "HTML页面:") > 0 {
            local html_start = strpos(`"`line'"', "](https://") + 2
            if `html_start' > 2 {
                local html_end = strpos(substr(`"`line'"', `html_start', .), ")")
                local html_url = substr(`"`line'"', `html_start', `html_end' - 1)
                di as text _col(8) `"{browse "`html_url'":HTML网页}"'
            }
        }
        // 处理PDF链接行
        else if strpos(`"`macval(line)'"', "PDF下载:") > 0 {
            local pdf_start = strpos(`"`line'"', "](https://") + 2
            if `pdf_start' > 2 {
                local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
                local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
                di as text _col(8) `"{browse "`pdf_url'":PDF}"'
            }
        }
        // 处理附件链接行
        else if strpos(`"`macval(line)'"', "附件:") > 0 {
            local attach_start = strpos(`"`line'"', "](https://") + 2
            if `attach_start' > 2 {
                local attach_end = strpos(substr(`"`line'"', `attach_start', .), ")")
                local attach_url = substr(`"`line'"', `attach_start', `attach_end' - 1)
                di as text _col(8) `"{browse "`attach_url'":附件}"'
            }
        }
        // 每篇论文后添加分隔线
        else if strpos(`"`macval(line)'"', "---") > 0 {
            di as text "{hline 78}"
        }

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
    di as text _col(10) `"数据来源：《世界经济》，{browse "https://manu30.magtech.com.cn/sjjj/CN/home":官网链接}"'
    di as text _col(10) "jwe命令由数量经济学微信公众号及计量经济网提供技术支持"
    di as text "{hline 78}"
end