*! cjs.ado - 《社会》期刊导航工具
*! Version 1.0
*! Last Updated: 2025-07-01
*! Requires Stata 14+


capture program drop cjs
program define cjs
    version 14
    syntax anything(name=vol_issue) [, help]

    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(30) "CJS - 《社会》期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    cjs 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《社会》期刊论文"
        di as text ""
        di as text "参数:"
        di as text "    年份    2005年及以后的年份"
        di as text "    期数    1-6之间的期数（双月刊）"
        di as text ""
        di as text "示例:"
        di as text "    cjs 2024 1   # 显示2024年第1期内容"
        di as text "    cjs 2025 1, help     # 显示帮助信息"
		di as text "    cjs 2025 , help     # 显示帮助信息"
        di as text "{hline 78}"
        exit
    }

    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"

    if "`vol'" == "" | "`iss'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata cjs, help} 查看帮助"
        exit 198
    }

    capture confirm integer number `vol'
    if _rc {
        di as error "年份必须是整数"
        exit 198
    }

    if `vol' < 2005 {
        di as error "年份必须大于或等于2005"
        exit 198
    }

    capture confirm integer number `iss'
    if _rc {
        di as error "期数必须是整数"
        exit 198
    }

    if !inrange(`iss', 1, 6) {
        di as error "期数必须在1-6之间（双月刊）"
        exit 198
    }

    _cjs_display_papers `vol' `iss'
end

program define _cjs_display_papers
    args vol iss
    
    // 确定数据文件URL
    local url "https://www.aistata.cn/cjs_"
    if `vol' < 2025 | (`vol' == 2025 & `iss' <= 2) {
        local url "`url'2005-2025.txt"
    }
    else {
        local url "`url'`vol'.txt"
    }

    tempfile journal_data
    capture copy "`url'" "`journal_data'", replace
    if _rc {
        di as error _n "{hline 78}"
        di as error "无法加载`vol'年数据"
        di as error "可能原因:"
        di as error "1. 数据库尚未更新该年内容"
        di as error "2. 输入年份或期数有误"
        di as error ""
        di as text "您可以访问《社会》官网查看最新内容:"
        di as text `"{browse "https://www.society.shu.edu.cn/":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }

    di as text _n "{hline 78}"
    di as text _col(30) "《社会》`vol'年第`iss'期"
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
            // 匹配期数标题行，如：## 2025年 第45卷 第2期
            if strpos(`"`macval(line)'"', "## `vol'年") > 0 & ///
               strpos(`"`macval(line)'"', "第`iss'期") > 0 {
                local found_issue = 1
            }
            file read `fh' line
            continue
        }

        // 检查是否到达下一期或文件结尾
        if strpos(`"`macval(line)'"', "## ") > 0 {
            continue, break
        }

        // 跳过空行、注释行和日期行
        if trim(`"`macval(line)'"') == "" | ///
           substr(trim(`"`macval(line)'"'), 1, 1) == "#" | ///
           strpos(`"`macval(line)'"', "刊出日期：") > 0 {
            file read `fh' line
            continue
        }

        // 处理论文标题行 - 格式如：1. **[标题](链接)**
        if ustrregexm(`"`macval(line)'"', "^\d+\.\s+\*\*\[(.+?)\]\((.+?)\)\*\*") {
            local title = ustrregexs(1)
            local html_url = ustrregexs(2)
            di as text "    `title'"
            di as text _col(8) `"{browse "`html_url'":HTML网页}"'
            local paper_count = `paper_count' + 1
        }
        // 处理PDF下载行 - 格式如：[PDF下载](链接)
        else if ustrregexm(`"`macval(line)'"', "\[PDF下载\]\((.+?)\)") {
            local pdf_url = ustrregexs(1)
            di as text _col(8) `"{browse "`pdf_url'":PDF}"'
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
    di as text _col(10) `"数据来源：《社会》，{browse "https://www.society.shu.edu.cn/":官网链接}"'
    di as text _col(10) `"cjs命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    di as text "{hline 78}"
end