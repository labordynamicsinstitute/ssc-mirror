*! cjoe.ado - 《计量经济学报》期刊知识库导航工具
*! Version 1.2
*! Last Updated: 2025-06-28
*! Requires Stata 14+

capture program drop cjoe
program define cjoe
version 14
syntax anything(name=vol_issue) [, help]

// 显示帮助信息
if "`help'" != "" {
    di as text _n "{hline 78}"
    di as text _col(25) "CJOE - 计量经济学报期刊导航"
    di as text "{hline 78}"
    di as text "语法:"
    di as text "    cjoe 年份 期数"
    di as text ""
    di as text "描述:"
    di as text "    导航并访问《计量经济学报》期刊内容"
    di as text ""
    di as text "参数:"
    di as text "    年份    2021年及以后的年份"
    di as text "    期数    1-6之间的期数（2021年-2023年为1-4,2024年为1-6）"
    di as text ""
    di as text "示例:"
    di as text "    cjoe 2025 1   # 显示2025年第1期内容"
    di as text "    cjoe 2025 1, help    # 显示帮助信息"
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
    di as error "输入 {stata cjoe, help} 查看帮助"
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
if !inrange(`iss', 1, 6) {
    di as error "期数必须在1-6之间"
    exit 198
}

// 验证年份范围
if `vol' < 2021 {
    di as error "年份必须为2021年及以后"
    exit 198
}

// 主逻辑
_cjoe_display_papers `vol' `iss'
end

program define _cjoe_display_papers
args vol iss

// 修正卷号计算：根据示例固定为5（2021-2025年均为第5卷）
*local vol_prefix = 5  //后台重新修正文件名
local url "https://www.aistata.cn/`vol'_issue`iss'.txt"  //已经修正
tempfile paper_data

// 下载数据
capture copy "`url'" "`paper_data'", replace
if _rc {
    // 错误处理
    di as error _n "{hline 78}"
    di as error "无法加载第`vol'年第`iss'期数据"
    di as error "可能原因:"
    di as error "1. 数据库尚未更新该期内容"
    di as error "2. 输入年份或期数有误"
    di as error ""
    di as text "您可以访问《计量经济学报》官网查看最新内容:"
    di as text `"{browse "https://cjoe.cjoe.ac.cn":官网链接}"'
    di as error "{hline 78}"
    
    // 提供可能的解决方案
    di as text _n "建议操作:"
    di as text "1. 检查输入是否正确 (年份: `vol', 期数: `iss')"
    di as text "2. 尝试访问官网确认该期是否已发布"
    di as text "3. 稍后再试，数据库可能正在更新"
	di as text "4. 若还有问题，您可以邮件联系我们！"
    di as text "{hline 78}"
    exit 198
}

// 显示标题
di as text _n "{hline 78}"
di as text _col(20) "《计量经济学报》`vol'年第`iss'期"
di as text "{hline 78}" _n

// 处理并显示论文
tempname fh
file open `fh' using "`paper_data'", read
file read `fh' line

local count = 0

while r(eof) == 0 {
    // 跳过标题行和空行
    if substr(trim(`"`macval(line)'"'), 1, 1) == "#" | trim(`"`macval(line)'"') == "" {
        file read `fh' line
        continue
    }
    
    // 处理论文行（使用安全方法处理标题）
    _process_cjoe_format_line `"`macval(line)'"'
    
    // 添加分隔线
    di as text "{hline 78}"
    
    file read `fh' line
    local ++count
}
file close `fh'

// 显示统计信息
di as text _col(10) "共显示论文: " as result "`count'篇"
di as text _col(10) "期刊: `vol'年 第`iss'期 | 日期: " as result "$S_DATE"

// 添加来源信息
di as text _col(10) `"数据来源：《计量经济学报》，{browse "https://cjoe.cjoe.ac.cn":官网链接}"'

// 添加技术支持信息
di as text _col(10) `"cjoe命令由数量经济学微信公众号及{browse "https://www.aistata.cn":计量经济网}提供技术支持"'

di as text "{hline 78}"
end

// 处理计量经济学报格式的论文行
program define _process_cjoe_format_line
args line

// 安全提取标题 - 使用双引号处理标题中的特殊字符
local title_start = strpos(`"`line'"', ". ") + 2
local title_end = strpos(`"`line'"', "[-HTML网页-]")
if `title_end' == 0 {
    local title_end = strlen(`"`line'"')
}
local title = substr(`"`line'"', `title_start', `title_end' - `title_start')

// 清理标题末尾的逗号（中英文）
local title = ustrregexra(`"`title'"', "[,，.。]?$", "")

// 安全显示标题
di as text _col(5) `"`title'"'

// 提取HTML链接
local html_prefix = "[-HTML网页-]("
local html_start = strpos(`"`line'"', "`html_prefix'")
if `html_start' {
    local html_start = `html_start' + strlen("`html_prefix'")
    local html_end = strpos(substr(`"`line'"', `html_start', .), ")")
    if `html_end' {
        local html_url = substr(`"`line'"', `html_start', `html_end' - 1)
        local html_url = strtrim(subinstr(`"`html_url'"', " ", "", .))
        di as text _col(10) `"{browse "`html_url'":HTML网页}"'
    }
}

// 提取PDF链接
local pdf_prefix = "[-PDF-]("
local pdf_start = strpos(`"`line'"', "`pdf_prefix'")
if `pdf_start' {
    local pdf_start = `pdf_start' + strlen("`pdf_prefix'")
    local pdf_end = strpos(substr(`"`line'"', `pdf_start', .), ")")
    if `pdf_end' {
        local pdf_url = substr(`"`line'"', `pdf_start', `pdf_end' - 1)
        local pdf_url = strtrim(subinstr(`"`pdf_url'"', " ", "", .))
        di as text _col(10) `"{browse "`pdf_url'":PDF}"'
    }
}

// 不再提取和显示附件链接
end