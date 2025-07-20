*! jjgl.ado - 《经济管理》期刊导航工具
*! Version 1.6
*! Last Updated: 2025-07-02
*! Requires Stata 14+
*! 技术支持: 数量经济学微信公众号、计量经济网

capture program drop jjgl
program define jjgl
    version 14
    syntax anything(name=vol_issue) [, help]

    if "`help'" != "" {
        di as text _n "{hline 78}"
        di as text _col(30) "JJGL - 《经济管理》期刊导航"
        di as text "{hline 78}"
        di as text "语法:"
        di as text "    jjgl 年份 期数"
        di as text ""
        di as text "描述:"
        di as text "    导航并访问《经济管理》期刊论文"
        di as text ""
        di as text "参数:"
        di as text "    年份    2016年及以后的年份"
        di as text "    期数    1-12之间的期数"
        di as text ""
        di as text "示例:"
        di as text "    jjgl 2024 1   # 显示2024年第1期内容"
        di as text "    jjgl, help    # 显示帮助信息"
        di as text "{hline 78}"
        exit
    }

    tokenize "`vol_issue'"
    local vol = "`1'"
    local iss = "`2'"

    if "`vol'" == "" | "`iss'" == "" {
        di as error "必须同时提供年份和期数"
        di as error "输入 {stata jjgl, help} 查看帮助"
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

    _jjgl_display_papers `vol' `iss'
end

program define _jjgl_display_papers
    args vol iss
    
    // 确定数据文件URL
    local url "https://www.aistata.cn/jjgl"
    if `vol' < 2025 {
        local url "`url'2016-2024.txt"
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
        di as text "您可以访问《经济管理》官网查看最新内容:"
        di as text `"{browse "https://jjgl.ajcass.com/":官网链接}"'
        di as error "{hline 78}"
        exit 198
    }

    di as text _n "{hline 78}"
    di as text _col(30) "《经济管理》`vol'年第`iss'期"
    di as text "{hline 78}" _n

    tempname fh
    file open `fh' using "`journal_data'", read
    file read `fh' line

    local found_issue = 0
    local paper_count = 0
    local current_date = c(current_date)
    local is_2025_or_later = (`vol' >= 2025)

    while r(eof) == 0 {
        // 检查是否找到目标期数
        if `found_issue' == 0 {
            // 匹配期数标题行
            if strpos(`"`macval(line)'"', "# `vol'年第`iss'期") > 0 {
                local found_issue = 1
            }
            file read `fh' line
            continue
        }

        // 检查是否到达下一期或文件结尾
        if strpos(`"`macval(line)'"', "# ") > 0 {
            continue, break
        }

        // 跳过空行和注释行
        if trim(`"`macval(line)'"') == "" {
            file read `fh' line
            continue
        }

        // 处理论文行 - 格式如：- 1-标题，[PDF](链接)
        if strpos(`"`macval(line)'"', "- ") == 1 {
            // 提取标题部分（从第一个"- "后开始，到逗号前结束）
            local title_start = strpos(`"`line'"', "- ") + 2
            
            // 查找标题结束位置（PDF或逗号前）
            local title_end = .
            local markers `" "，[PDF]" "[PDF]" "，[附件]" ",[PDF]" ", [附件]" "'
            foreach marker in `markers' {
                local pos = strpos(`"`line'"', "`marker'")
                if `pos' > 0 & (`pos' < `title_end' | `title_end' == .) {
                    local title_end = `pos'
                }
            }
            
            // 如果没找到标准结束位置，使用行尾
            if `title_end' == . {
                local title = substr(`"`line'"', `title_start', .)
            }
            else {
                local title = trim(substr(`"`line'"', `title_start', `title_end' - `title_start'))
            }
            
            // 清理标题中的多余空格和特殊字符
            local title : subinstr local title "�" "", all
            local title : subinstr local title "?" "？", all
            di as text "    `title'"
            
            // 提取PDF链接
            local pdf_url = ""
            local pdf_start = strpos(`"`line'"', "[PDF](")
            if `pdf_start' > 0 {
                local pdf_start = `pdf_start' + 6
                local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
                if `pdf_end' > 0 {
                    local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
                }
            }
            
            // 正确显示PDF链接
            if `"`pdf_url'"' != "" {
                di as text _col(8) `"{browse "`pdf_url'":PDF}"'
            }
            else {
                di as text _col(8) "PDF"
            }
            
            // 提取并显示附件链接（仅2025年及以后）- 修复语法错误
            if `is_2025_or_later' {
                local attach_url = ""
                local attach_start = strpos(`"`line'"', "[附件]")
                
                if `attach_start' > 0 {
                    // 从[附件]标记后开始截取字符串
                    local rest_of_line = substr(`"`line'"', `attach_start' + 6, .)
                    
                    // 在新截取的字符串中查找URL开始位置
                    local url_start = strpos(`"`rest_of_line'"', "https://")
                    if `url_start' == 0 {
                        local url_start = strpos(`"`rest_of_line'"', "http://")
                    }
                    
                    if `url_start' > 0 {
                        // 计算原始字符串中的URL开始位置
                        local actual_start = `attach_start' + 6 + `url_start' - 1
                        
                        // 查找URL结束位置
                        local url_end = strpos(substr(`"`line'"', `actual_start', .), ")")
                        if `url_end' > 0 {
                            local attach_url = substr(`"`line'"', `actual_start', `url_end' - 1)
                        }
                    }
                }
                
                // 正确显示附件链接
                if `"`attach_url'"' != "" {
                    di as text _col(8) `"{browse "`attach_url'":附件}"'
                }
                else {
                    di as text _col(8) "附件"
                }
            }
            
            di as text "{hline 78}"
            local paper_count = `paper_count' + 1
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
    di as text _col(10) `"数据来源：《经济管理》，{browse "https://jjgl.ajcass.com/":官网链接}"'
	di as text _col(10) `"jjgl命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'
    di as text "{hline 78}"
end