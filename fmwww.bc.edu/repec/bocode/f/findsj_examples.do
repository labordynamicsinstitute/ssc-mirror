*! Stata Journal 数据库使用示例
*! 展示如何使用 findsj.dta 进行文献检索和分析
*! 作者: Yujun Lian
*! 日期: 2026-02-03

clear all
set more off

* ============================================================================
* 第一步：加载数据库
* ============================================================================

* 方式1: 从本地加载（如果已下载）
use "findsj.dta", clear

* 方式2: 从 GitHub 直接下载最新版本
* copy "https://raw.githubusercontent.com/arlionn/findsj/main/findsj.dta" findsj.dta, replace
* use findsj.dta, clear

* 查看数据结构
describe
summarize year volume number cited_by_count reference_count author_count

* ============================================================================
* 示例 1: 查看被引最多的文章
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 1: 被引次数最多的前10篇文章"
di as text "{hline 70}"

gsort -cited_by_count
list title authors year volume number cited_by_count in 1/10, ///
    sepby(cited_by_count) abbrev(30)

* ============================================================================
* 示例 2: 按年份统计
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 2: 按年份统计文章数和平均被引"
di as text "{hline 70}"

preserve
    gen one = 1
    collapse (sum) n_articles=one ///
             (mean) avg_cited=cited_by_count ///
             (mean) avg_refs=reference_count, ///
             by(year)
    
    format avg_cited avg_refs %6.1f
    
    list year n_articles avg_cited avg_refs, ///
        sepby(year) noobs
    
    * 简单可视化
    twoway (connected n_articles year, lcolor(blue) mcolor(blue)) ///
           (connected avg_cited year, lcolor(red) mcolor(red) yaxis(2)), ///
           title("Stata Journal 发文趋势") ///
           ytitle("文章数", axis(1)) ///
           ytitle("平均被引次数", axis(2)) ///
           legend(label(1 "文章数") label(2 "平均被引") position(6) row(1))
    
    graph export "sj_trend.png", replace width(1200)
restore

* ============================================================================
* 示例 3: 搜索特定主题的文章
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 3: 搜索包含 'panel' 的文章"
di as text "{hline 70}"

gen topic_panel = regexm(lower(title), "panel")

count if topic_panel
di as text "找到 " as result r(N) as text " 篇相关文章"

list title authors year cited_by_count if topic_panel, ///
    sepby(year) abbrev(40) noobs

drop topic_panel

* ============================================================================
* 示例 4: 查找特定作者的文章
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 4: Christopher F. Baum 的文章"
di as text "{hline 70}"

gen author_baum = regexm(lower(authors), "baum")

count if author_baum
di as text "找到 " as result r(N) as text " 篇文章"

list title year volume number cited_by_count if author_baum, ///
    sepby(year) noobs abbrev(40)

drop author_baum

* ============================================================================
* 示例 5: 高被引文章分析（被引 > 50 次）
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 5: 高被引文章（被引 > 50 次）"
di as text "{hline 70}"

preserve
    keep if cited_by_count > 50
    
    count
    di as text "共有 " as result r(N) as text " 篇高被引文章"
    
    * 按被引次数排序
    gsort -cited_by_count
    
    * 列出所有高被引文章
    list title first_author_family year cited_by_count, ///
        sepby(cited_by_count) noobs abbrev(35)
    
    * 导出为 CSV
    export delimited using "high_cited_articles.csv", replace
    di _n as text "已导出到: high_cited_articles.csv"
restore

* ============================================================================
* 示例 6: 作者产出分析
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 6: 发文最多的作者 Top 10"
di as text "{hline 70}"

preserve
    * 统计第一作者发文数
    bysort first_author_family: gen n_papers = _N
    bysort first_author_family: gen mean_cited = sum(cited_by_count)/_N
    
    by first_author_family: keep if _n == 1
    keep first_author_family n_papers mean_cited
    
    gsort -n_papers
    list first_author_family n_papers mean_cited in 1/10, ///
        noobs sepby(n_papers)
restore

* ============================================================================
* 示例 7: 主题词云分析（提取标题关键词）
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 7: 常见主题关键词"
di as text "{hline 70}"

* 统计常见关键词出现频率
gen has_regression = regexm(lower(title), "regression")
gen has_panel = regexm(lower(title), "panel")
gen has_bootstrap = regexm(lower(title), "bootstrap")
gen has_iv = regexm(lower(title), "instrumental variable|endogen")
gen has_ml = regexm(lower(title), "maximum likelihood")
gen has_gmm = regexm(lower(title), "gmm|moment")
gen has_time = regexm(lower(title), "time series|cointegrat")
gen has_survival = regexm(lower(title), "survival|hazard|cox")

di _n as text "{hline 50}"
di as text "关键词" _col(30) "出现次数" _col(45) "占比"
di as text "{hline 50}"

foreach var in regression panel bootstrap iv ml gmm time survival {
    qui count if has_`var'
    local n = r(N)
    local pct = `n' / _N * 100
    
    local keyword: subinstr local var "_" " ", all
    di as text "`keyword'" _col(30) as result `n' _col(45) %5.1f `pct' "%"
}
di as text "{hline 50}"

* ============================================================================
* 示例 8: 引用统计分析
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 8: 引用统计分布"
di as text "{hline 70}"

* 被引次数分布
summarize cited_by_count, detail

di _n as text "被引次数分位数:"
_pctile cited_by_count, percentiles(25 50 75 90 95 99)
di as text "  25%: " as result r(r1)
di as text "  50%: " as result r(r2)
di as text "  75%: " as result r(r3)
di as text "  90%: " as result r(r4)
di as text "  95%: " as result r(r5)
di as text "  99%: " as result r(r6)

* 被引次数直方图
histogram cited_by_count if cited_by_count < 100, ///
    width(5) percent ///
    title("Stata Journal 文章被引分布") ///
    xtitle("被引次数") ytitle("百分比 (%)") ///
    note("注: 仅显示被引次数 < 100 的文章")
graph export "citation_distribution.png", replace width(1000)

* ============================================================================
* 示例 9: 近期文章（最近3年）
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 9: 近期高影响力文章（最近3年，被引>10）"
di as text "{hline 70}"

preserve
    * 获取最大年份
    qui sum year
    local max_year = r(max)
    local start_year = `max_year' - 2
    
    keep if year >= `start_year' & cited_by_count > 10
    
    count
    if r(N) > 0 {
        gsort -cited_by_count
        list title authors year cited_by_count, ///
            sepby(year) noobs abbrev(40)
    }
    else {
        di as text "未找到符合条件的文章"
    }
restore

* ============================================================================
* 示例 10: 生成自定义搜索函数
* ============================================================================
di _n as text "{hline 70}"
di as text "示例 10: 自定义搜索功能"
di as text "{hline 70}"

* 重新加载数据以确保干净的数据集
use "findsj.dta", clear

* 定义搜索程序
capture program drop findsj_search
program define findsj_search
    syntax [anything(everything)] [, Author(string) MINcite(integer 0)]
    
    * 搜索标题
    capture drop _match
    local search_term = lower(strtrim(`"`anything'"'))
    
    if "`search_term'" != "" {
        gen _match = regexm(lower(title), "`search_term'")
    }
    else {
        gen _match = 1
    }
    
    * 筛选作者
    if `"`author'"' != "" {
        replace _match = 0 if !regexm(lower(authors), lower("`author'"))
    }
    
    * 筛选被引次数
    replace _match = 0 if cited_by_count < `mincite'
    
    * 显示结果
    count if _match
    local n = r(N)
    
    if `n' > 0 {
        di _n as text "找到 " as result `n' as text " 篇文章:"
        list title authors year cited_by_count if _match, ///
            sepby(year) noobs abbrev(40)
    }
    else {
        di as error "未找到匹配的文章"
    }
    
    drop _match
end

* 使用示例
di _n as text "搜索标题包含 'panel data' 的文章:"
findsj_search panel data

di _n as text "搜索 Baum 的文章，被引 > 30:"
findsj_search, author(baum) mincite(30)

* ============================================================================
* 完成
* ============================================================================
di _n as text "{hline 70}"
di as result "✓ 示例运行完成！"
di as text "{hline 70}"
di _n as text "生成的文件:"
di as text "  - sj_trend.png (发文趋势图)"
di as text "  - citation_distribution.png (被引分布图)"
di as text "  - high_cited_articles.csv (高被引文章列表)"
di _n as text "更多信息请查看: README_UPDATE.md"
di as text "{hline 70}"
