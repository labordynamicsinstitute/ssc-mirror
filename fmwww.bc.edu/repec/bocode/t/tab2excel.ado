*! tab2excel.ado version 2.1
*! Authors: Wu Lianghai (AHUT); Wu Hanyan (NUAA); Wu Xinzhuo (UB)
*! Development date: 12Dec2025
*! Export tabstat results to Excel with enhanced features

* 定义获取Excel列字母的辅助程序
program define get_col_letter, rclass
    args colnum
    
    local colnum = `colnum'
    local letters ""
    
    while `colnum' > 0 {
        local remainder = mod(`colnum' - 1, 26)
        local colnum = floor((`colnum' - 1) / 26)
        local letters = char(65 + `remainder') + "`letters'"
    }
    
    return local col_letter "`letters'"
end

* 主程序
program define tab2excel
    version 14.2
    
    * Parse syntax with enhanced options
    syntax varlist(numeric) [if] [in] ///
        [,  Language(string)          ///
            filename(string)          ///
            Title(string)             ///
            Replace                   ///
            Statistics(string)        ///
        ]
    
    * Create temporary variable for sample selection
    tempvar touse
    mark `touse' `if' `in'
    
    * Set default values
    if "`language'" == ""     local language "chinese"
    if "`filename'" == ""     local filename "summary.xlsx"
    if "`statistics'" == ""   local statistics "n mean p25 p50 p75 min max"
    
    * Handle title default based on language
    if `"`title'"' == "" {
        if "`language'" == "chinese" {
            local title "描述性统计"
        }
        else {
            local title "Descriptive Statistics"
        }
    }
    
    * Check if file exists and handle replace option
    capture confirm file "`filename'"
    if _rc == 0 & "`replace'" == "" {
        di as error "File `filename' already exists. Use replace option to overwrite."
        exit 602
    }
    
    * 显示统计表格（这是用户需要的，不抑制）
    tabstat `varlist' if `touse', save statistics(`statistics')
    matrix define x = r(StatTotal)'
    
    * Build format strings for Excel
    * Set fixed format for non-observation statistics (2 decimal places)
    local fmt_other "0.00"
    
    * Observations format (fixed as integer)
    local fmt_obs "0"
    
    * 使用quietly抑制所有putexcel的冗余消息，但保留统计表格显示
    quietly {
        * Initialize Excel file
        putexcel clear
        putexcel set "`filename'", sheet("Summary Statistics") replace
        
        * Write title
        putexcel A1 = ("`title'"), bold
        
        * Write variable name column header
        if "`language'" == "chinese" {
            putexcel A2 = ("变量"), bold hcenter border(bottom)
        }
        else {
            putexcel A2 = ("Variable"), bold hcenter border(bottom)
        }
        
        * Write statistics headers
        local col = 2
        foreach stat in `statistics' {
            * Get column letter using our function
            get_col_letter `col'
            local col_letter = r(col_letter)
            
            if "`language'" == "chinese" {
                * Chinese labels
                if "`stat'" == "n"          local header "观测数"
                else if "`stat'" == "mean"  local header "均值"
                else if "`stat'" == "sd"    local header "标准差"
                else if "`stat'" == "var"   local header "方差"
                else if "`stat'" == "cv"    local header "变异系数"
                else if "`stat'" == "sem"   local header "均值标准误"
                else if "`stat'" == "skew"  local header "偏度"
                else if "`stat'" == "kurt"  local header "峰度"
                else if "`stat'" == "sum"   local header "总和"
                else if "`stat'" == "p1"    local header "第1百分位"
                else if "`stat'" == "p5"    local header "第5百分位"
                else if "`stat'" == "p10"   local header "第10百分位"
                else if "`stat'" == "p25"   local header "第25百分位"
                else if "`stat'" == "p50"   local header "中位数"
                else if "`stat'" == "p75"   local header "第75百分位"
                else if "`stat'" == "p90"   local header "第90百分位"
                else if "`stat'" == "p95"   local header "第95百分位"
                else if "`stat'" == "p99"   local header "第99百分位"
                else if "`stat'" == "min"   local header "最小值"
                else if "`stat'" == "max"   local header "最大值"
                else if "`stat'" == "iqr"   local header "四分位距"
                else if "`stat'" == "range" local header "极差"
                else                        local header "`stat'"
            }
            else {
                * English labels
                if "`stat'" == "n"          local header "Observations"
                else if "`stat'" == "mean"  local header "Mean"
                else if "`stat'" == "sd"    local header "Std. Dev."
                else if "`stat'" == "var"   local header "Variance"
                else if "`stat'" == "cv"    local header "Coef. of Variation"
                else if "`stat'" == "sem"   local header "Std. Error of Mean"
                else if "`stat'" == "skew"  local header "Skewness"
                else if "`stat'" == "kurt"  local header "Kurtosis"
                else if "`stat'" == "sum"   local header "Sum"
                else if "`stat'" == "p1"    local header "1st Percentile"
                else if "`stat'" == "p5"    local header "5th Percentile"
                else if "`stat'" == "p10"   local header "10th Percentile"
                else if "`stat'" == "p25"   local header "25th Percentile"
                else if "`stat'" == "p50"   local header "Median"
                else if "`stat'" == "p75"   local header "75th Percentile"
                else if "`stat'" == "p90"   local header "90th Percentile"
                else if "`stat'" == "p95"   local header "95th Percentile"
                else if "`stat'" == "p99"   local header "99th Percentile"
                else if "`stat'" == "min"   local header "Minimum"
                else if "`stat'" == "max"   local header "Maximum"
                else if "`stat'" == "iqr"   local header "IQR"
                else if "`stat'" == "range" local header "Range"
                else                        local header "`stat'"
            }
            
            * Write header to Excel
            putexcel `col_letter'2 = ("`header'"), bold hcenter border(bottom)
            local ++col
        }
        
        * Write variable labels and statistics with formatting
        local row = 3
        local var_count = 1
        
        foreach var of varlist `varlist' {
            * Write variable label in column A
            local varlabel : variable label `var'
            if "`varlabel'" == "" local varlabel "`var'"
            putexcel A`row' = ("`varlabel'")
            
            * Write statistics for each variable
            local col = 2
            
            foreach stat in `statistics' {
                * Get the value from matrix
                local value = x[`var_count', `col'-1]
                
                * Get column letter using our function
                get_col_letter `col'
                local col_letter = r(col_letter)
                
                * Determine format based on statistic type
                if "`stat'" == "n" {
                    * Observations - integer format (fixed)
                    putexcel `col_letter'`row' = (`value'), nformat("`fmt_obs'")
                }
                else {
                    * Other statistics - fixed decimal format (2 decimal places)
                    putexcel `col_letter'`row' = (`value'), nformat("`fmt_other'")
                }
                
                local ++col
            }
            
            local ++row
            local ++var_count
        }
    }
    
    * Display file path with hyperlink (这是需要的，不抑制)
    di as text `"File saved: {browse "`filename'":`filename'}"'
end