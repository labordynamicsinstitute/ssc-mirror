*! varck 1.0.2  2026-06-21
*! 鼎园会计 (Dingyuan Accounting)
*! "科学向善，人文规范" — Science for Good, Humanities as Norm
*!
*! Purpose:  Check existence of variables in Stata memory dataset
*!           Supports single or multiple variable queries
*!           Bilingual (Chinese/English) friendly output
*!           Tailored for accounting empirical big data analysis
*!
*! Authors:  Wu Lianghai
*!             School of Business, Anhui University of Technology (AHUT)
*!             agd2010@yeah.net
*!           Yang Lu
*!             Rugao City Finance Bureau, Jiangsu Province
*!             1026835594@qq.com
*!           Hu Fangfang
*!             Wanjiang University of Technology (WJUT)
*!             huff470@163.com
*!           Chen Liwen
*!             School of Business, Anhui University of Technology (AHUT)
*!             2184844526@qq.com
*!           Wu Hanyan
*!             School of Economics and Management, NUAA
*!             2325476320@qq.com
*!
*! Acknowledgments:
*!           The development team extends our most sincere gratitude to
*!           Professor Kit Baum for his humility, generosity, and erudite
*!           scholarship. His timely and sustained attention and support
*!           have been the wellspring of strength for the Dingyuan
*!           Accounting Intelligent Learning Platform.
*!
*! Version History:
*!   1.0.2  2026-06-21  Bugfix release
*!                         - Fixed detail mode display: variables concatenated
*!                           on one line due to _continue across loop iterations
*!                         - Replaced %~60s centering with SMCL {center:}
*!                           to avoid encoding artifacts with Unicode text
*!                         - Fixed unbalanced braces in example do-file
*!                           (missing } before else)
*!   1.0.1  2026-06-21  Bugfix release
*!                         - Fixed motto display (r/111, r/198) caused by
*!                           literal double-quote characters in macro values
*!                         - Fixed table mode parsing error (r/198) caused by
*!                           complex inline function expressions in display
*!                         - Fixed unbalanced braces in example do-file
*!                         - Improved macro handling for safer display formatting
*!   1.0.0  2026-06-21  Initial release

program define varck, rclass

    version 14.0

    /* ───────────────────────────────────────────
       1. Syntax Parsing
       ─────────────────────────────────────────── */
    syntax anything(id="variable list")          ///
        [,                                      ///
            LANGuage(string)                    ///  cn | en | auto
            Detail                               ///  show variable details
            TAble                                ///  output in table format
            NOIsily                              ///  verbose output
        ]

    /* Validate input */
    if `"`anything'"' == "" {
        di as error "varck: No variables specified."
        exit 198
    }

    /* ───────────────────────────────────────────
       2. Language Setup
       ─────────────────────────────────────────── */
    local lang "auto"
    if `"`language'"' != "" {
        local lang = lower(`"`language'"')
        if !inlist("`lang'", "cn", "en", "auto") {
            di as error "varck: invalid language option '{bf:`language'}'. Valid options: cn, en, auto"
            exit 198
        }
    }

    /* Auto-detect language from Stata's locale setting */
    if "`lang'" == "auto" {
        /* Check if Stata is running in Chinese locale */
        capture local st_lang = c(language)
        if _rc == 0 {
            /* c(language) may return locale codes; try to match Chinese */
            local lang_test = lower("`st_lang'")
            if strpos("`lang_test'", "zh") | strpos("`lang_test'", "cn") | strpos("`lang_test'", "chinese") {
                local lang "cn"
            }
            else {
                local lang "en"
            }
        }
        else {
            local lang "en"
        }
    }

    /* Define bilingual message macros */
    if "`lang'" == "cn" {
        local MSG_HEADER      "【鼎园会计】varck — 变量存在性检验"
        local MSG_MOTTO       "科学向善，人文规范"
        local MSG_QUERY       "查询变量 ({it:`anything'}) ..."
        local MSG_EXIST       "存在"
        local MSG_NOTEXIST    "不存在"
        local MSG_CHECK       "✓"
        local MSG_CROSS       "✗"
        local MSG_SUMMARY     "查询结果汇总"
        local MSG_TOTAL       "查询总数"
        local MSG_N_EXIST     "存在变量数"
        local MSG_N_NOTEXIST  "不存在变量数"
        local MSG_ALL_OK      "所有指定变量均存在。"
        local MSG_SOME_MISS   "部分变量不存在，请核实变量名称。"
        local MSG_ALL_MISS    "所有指定变量均不存在！请检查变量名称是否正确。"
        local MSG_SUGGEST     "提示：可使用 {cmd:ds} 或 {cmd:describe, short} 查看数据集中所有变量。"
        local MSG_SEP         "—"
        local MSG_LABEL       "标签"
        local MSG_TYPE        "类型"
        local MSG_FORMAT      "格式"
        local MSG_N           "数量"
        local MSG_TAB_EXIST   "✓ 存在"
        local MSG_TAB_NOT     "✗ 不存在"
        local MSG_NONE        "无"
        local MSG_ACCT_TIP    "会计实证提示：在合并多个数据源（如CSMAR、Wind、CNRDS）后，变量名常因来源不同而有差异。"
    }
    else {
        local MSG_HEADER      "【Dingyuan Accounting】varck — Variable Existence Check"
        local MSG_MOTTO       "Science for Good, Humanities as Norm"
        local MSG_QUERY       "Checking variable(s): {it:`anything'} ..."
        local MSG_EXIST       "exists"
        local MSG_NOTEXIST    "does NOT exist"
        local MSG_CHECK       "+"
        local MSG_CROSS       "!"
        local MSG_SUMMARY     "Summary of Results"
        local MSG_TOTAL       "Total queried"
        local MSG_N_EXIST     "Existing"
        local MSG_N_NOTEXIST  "Missing"
        local MSG_ALL_OK      "All specified variables exist."
        local MSG_SOME_MISS   "Some variables do not exist. Please verify variable names."
        local MSG_ALL_MISS    "None of the specified variables exist! Please check variable names."
        local MSG_SUGGEST     "Tip: Use {cmd:ds} or {cmd:describe, short} to list all variables in the dataset."
        local MSG_SEP         "-"
        local MSG_LABEL       "Label"
        local MSG_TYPE        "Type"
        local MSG_FORMAT      "Format"
        local MSG_N           "N"
        local MSG_TAB_EXIST   "+ Exists"
        local MSG_TAB_NOT     "! Missing"
        local MSG_NONE        "(none)"
        local MSG_ACCT_TIP    "Accounting tip: After merging multiple data sources (e.g., CSMAR, Wind, CRSP, Compustat), variable names often differ by source convention."
    }

    /* ───────────────────────────────────────────
       3. Variable Checking
       ─────────────────────────────────────────── */
    quietly {
        /* Count total observations for context */
        capture count
        local N = cond(_rc, 0, r(N))
    }

    /* Initialize result lists */
    local exist_list    ""
    local notexist_list ""
    local n_exist       0
    local n_notexist    0

    /* Print header */
    di _n as text "{hline 60}"
    di as result "{center:`MSG_HEADER'}"
    di as text "{center:`MSG_MOTTO'}"
    di as text "{hline 60}"

    if "`noisily'" != "" {
        di _n as text "`MSG_QUERY'"
    }

    /* Tokenize the input variable list */
    tokenize `anything'
    local n_total : word count `anything'

    /* ───────────────────────────────────────────
       4. Check Each Variable
       ─────────────────────────────────────────── */
    /* Capture table mode early, before any tokenize or loop,
       into a simple 0/1 flag.  This avoids any possible
       interaction between the `table' local (set by syntax)
       and the positional macros set by tokenize. */
    if "`table'" != "" {
        local do_table = 1
    }
    else {
        local do_table = 0
    }

    /* ───────────────────────────────────────────
       4. Check Each Variable
       ─────────────────────────────────────────── */
    if `do_table' {
        if "`lang'" == "cn" {
            di _n as text "{hline 50}"
            di as text %-20s "变量名" " | " %-12s "状态" " | " %-10s "类型"
            di as text "{hline 50}"
        }
        else {
            di _n as text "{hline 50}"
            di as text %-20s "Variable" " | " %-12s "Status" " | " %-10s "Type"
            di as text "{hline 50}"
        }
    }

    forvalues i = 1/`n_total' {
        local vname = "``i''"

        /* Check if variable exists using capture confirm */
        capture confirm variable `vname'

        if _rc == 0 {
            /* Variable exists */
            local exist_list "`exist_list' `vname'"
            local ++n_exist

            if `do_table' {
                capture local vtype : type `vname'
                if _rc {
                    local vtype "?"
                }
                local vname_ab = abbrev("`vname'", 18)
                di as text %-20s "`vname_ab'" " | " as result %-12s "`MSG_TAB_EXIST'" " | " as text %-10s "`vtype'"
            }
            else {
                if "`detail'" != "" {
                    capture local vtype : type `vname'
                    capture local vlabel : variable label `vname'
                    if `"`vlabel'"' != "" {
                        di as text "  " as result "`MSG_CHECK'" as text " `vname' — `MSG_TYPE': " as result "`vtype'" as text ", `MSG_LABEL': " as result `"`vlabel'"'
                    }
                    else {
                        di as text "  " as result "`MSG_CHECK'" as text " `vname' — `MSG_TYPE': " as result "`vtype'"
                    }
                }
                else {
                    di as text "  " as result "`MSG_CHECK'" as text " `vname' — " as result "`MSG_EXIST'"
                }
            }
        }
        else {
            /* Variable does not exist */
            local notexist_list "`notexist_list' `vname'"
            local ++n_notexist

            if `do_table' {
                local vname_ab = abbrev("`vname'", 18)
                di as text %-20s "`vname_ab'" " | " as error %-12s "`MSG_TAB_NOT'" " | " as text %-10s "-"
            }
            else {
                di as text "  " as error "`MSG_CROSS'" as text " `vname' — " as error "`MSG_NOTEXIST'"
            }
        }
    }

    if `do_table' {
        di as text "{hline 50}"
    }

    /* ───────────────────────────────────────────
       5. Summary
       ─────────────────────────────────────────── */
    di _n as text "{hline 36}"
    di as result "  `MSG_SUMMARY'"
    di as text "{hline 36}"
    di as text "  `MSG_TOTAL'"         _col(28) as result "`n_total'"
    di as text "  `MSG_N_EXIST'"       _col(28) as result "`n_exist'"
    di as text "  `MSG_N_NOTEXIST'"    _col(28) as result "`n_notexist'"
    di as text "{hline 36}"

    /* ───────────────────────────────────────────
       6. Status Messages
       ─────────────────────────────────────────── */
    di ""
    if `n_notexist' == 0 {
        di as result "  ◉  `MSG_ALL_OK'"
    }
    else if `n_exist' == 0 {
        di as error "  ◉  `MSG_ALL_MISS'"
        di as text "  `MSG_SUGGEST'"
    }
    else {
        di as text "  ◉  " as result "`MSG_SOME_MISS'"
    }

    /* ───────────────────────────────────────────
       7. Accounting Research Tip
       ─────────────────────────────────────────── */
    if `n_notexist' > 0 & "`noisily'" != "" {
        di _n as text "  {p 4 4 2}💡 `MSG_ACCT_TIP'{p_end}"
    }

    /* ───────────────────────────────────────────
       8. Detailed Listing (if requested)
       ─────────────────────────────────────────── */
    if "`detail'" != "" & `n_exist' > 0 {
        di _n as text "{hline 60}"
        if "`lang'" == "cn" {
            di as result "存在变量的详细信息："
        }
        else {
            di as result "Details of existing variables:"
        }
        di as text "{hline 60}"

        foreach v of local exist_list {
            capture local vtype : type `v'
            capture local vlabel : variable label `v'
            capture local vfmt : format `v'
            capture quietly count if !missing(`v')
            local vn = cond(_rc, ., r(N))

            di as text "  {bf:`v'}"
            di as text "    `MSG_TYPE':   " as result "`vtype'"
            di as text "    `MSG_FORMAT': " as result "`vfmt'"
            if `"`vlabel'"' != "" {
                di as text "    `MSG_LABEL':  " as result `"`vlabel'"'
            }
            di as text "    `MSG_N':      " as result "`vn'"
            di ""
        }
    }

    /* ───────────────────────────────────────────
       9. Footer
       ─────────────────────────────────────────── */
    di as text "{hline 60}"
    di as text "  {it:鼎园会计 Dingyuan Accounting} | varck 1.0.2 | 2026-06-21"
    di as text "{hline 60}" _n

    /* ───────────────────────────────────────────
       10. Return Values
       ─────────────────────────────────────────── */
    /* Trim leading/trailing spaces */
    local exist_list    = strtrim("`exist_list'")
    local notexist_list = strtrim("`notexist_list'")

    return local exist      "`exist_list'"
    return local notexist   "`notexist_list'"
    return scalar n_total   = `n_total'
    return scalar n_exist   = `n_exist'
    return scalar n_notexist = `n_notexist'
    return scalar all_exist = (`n_notexist' == 0)
    return scalar any_exist = (`n_exist' > 0)

    /* Stored results for programming use */
    return local varlist    "`exist_list'"
    return local badlist    "`notexist_list'"

end

/* ───────────────────────────────────────────────
   EOF
   ─────────────────────────────────────────────── */
