*! bf.ado v1.5.8 Wulianghai(AHUT) Chen Liwen(AHUT) Wu Hanyan(NUAA) 22Oct2025
capture prog drop bf
program define bf
version 18.0
syntax anything(name=issue), [LANGuage(string)]

if "`issue'" == "" {
    di as error "Issue number must be specified!"
    exit 198
}

// Set default language to English if not specified
if "`language'" == "" {
    local language "en"
}

// Validate language option
if !inlist("`language'", "en", "cn") {
    di as error "Language option must be either 'en' (English) or 'cn' (Chinese)!"
    exit 198
}

// Get all available drives
local drives ""
forvalues i = 67/90 {  // ASCII A-Z
    local drive = char(`i')
    capture cd "`drive':"
    if _rc == 0 {
        local drives "`drives' `drive'"
    }
}

// Prioritize drives: E > D > other non-system drives > C
local preferred_drive ""
foreach drive in E D {
    if strpos("`drives'", " `drive' ") {
        local preferred_drive "`drive'"
        continue, break
    }
}

// If no E or D, select first non-C drive
if "`preferred_drive'" == "" {
    foreach drive of local drives {
        if "`drive'" != "C" {
            local preferred_drive "`drive'"
            continue, break
        }
    }
}

// If only C drive available, use it
if "`preferred_drive'" == "" & strpos("`drives'", " C ") {
    local preferred_drive "C"
}

if "`preferred_drive'" == "" {
    di as error "No available hard drive found!"
    exit 601
}

// Set directory names based on language
if "`language'" == "cn" {
    local base_dir "益友学术"
    local project_dir "鼎园会计 `issue'"
    local model_dir "模型"
    local data_dir "数据"
    local program_dir "程序"
    local report_dir "报告"
    
    // Chinese do file names
    local data_dofile "数据管理.do"
    local program_dofile "程序定义.do"
    local model_dofile "模型估计.do"
    local report_dofile "报告生成.do"
}
else {
    local base_dir "Academic Friends"
    local project_dir "Dingyuan Accounting `issue'"
    local model_dir "model"
    local data_dir "data"
    local program_dir "program"
    local report_dir "report"
    
    // English do file names
    local data_dofile "data_management.do"
    local program_dofile "program_definition.do"
    local model_dofile "model_estimation.do"
    local report_dofile "report_generation.do"
}

// Check and create base directory (overwrite if exists)
local base_path "`preferred_drive':/`base_dir'"
capture mkdir "`base_path'"
if _rc != 0 & _rc != 693 {
    di as error "Failed to create base directory: `base_path'"
    exit _rc
}

// Create project directory (overwrite if exists)
local project_path "`base_path'/`project_dir'"
// Remove existing directory first to ensure clean setup
capture shell rmdir /s /q "`project_path'"  // Windows command to force remove directory
capture mkdir "`project_path'"
if _rc != 0 {
    // Try to create in current working directory
    local project_path "`project_dir'"
    capture shell rmdir /s /q "`project_path'"  // Windows command to force remove directory
    capture mkdir "`project_path'"
    if _rc != 0 {
        di as error "Failed to create project directory in both drive `preferred_drive': and current directory!"
        di as error "Please check your permissions or specify a different location."
        exit 693
    }
    di as text "Note: Created project directory in current working directory instead of drive `preferred_drive':"
}

cd "`project_path'"

// Create subdirectories (overwrite if exists)
local dirs "`model_dir' `data_dir' `program_dir' `report_dir'"
foreach dir of local dirs {
    capture shell rmdir /s /q "`dir'"  // Windows command to force remove directory
    capture mkdir "`dir'"
    if _rc != 0 {
        di as error "Warning: Failed to create subdirectory: `dir'"
    }
}

// Get the full project path for absolute paths
local full_project_path "`c(pwd)'"

// Create do files in each subdirectory
create_data_dofile "`data_dir'" "`data_dofile'" "`language'" "`full_project_path'"
create_program_dofile "`program_dir'" "`program_dofile'" "`language'" "`full_project_path'"
create_model_dofile "`model_dir'" "`model_dofile'" "`language'" "`full_project_path'" "`data_dir'" "`program_dir'" "`data_dofile'" "`program_dofile'"
create_report_dofile "`report_dir'" "`report_dofile'" "`language'" "`full_project_path'" "`model_dir'" "`data_dir'" "`model_dofile'"

// Display current working directory
di _n as text "Current working directory: " as result "`c(pwd)'"
di _n as text "Dingyuan Accounting Issue `issue' workspace created successfully!"
di as text "Includes the following subdirectories: " as result "`dirs'"
di as text "Ready-to-run do files have been created in each subdirectory."
di as text "Execution order: 1. data 2. program 3. model 4. report"
di as text "You can run the complete analysis by executing the report generation do file."

// Display example session
di _n(2) as text "{hline 60}"
di as text "Example Session:"
di as text "{hline 60}"
di as text "To run the complete analysis workflow, use the following commands:"
di as text ""
di as text "1. Create data management:" _n `"    do "`project_path'/`data_dir'/`data_dofile'""' _n
di as text "2. Define programs:" _n `"    do "`project_path'/`program_dir'/`program_dofile'""' _n
di as text "3. Run model estimation:" _n `"    do "`project_path'/`model_dir'/`model_dofile'""' _n
di as text "4. Generate final report:" _n `"    do "`project_path'/`report_dir'/`report_dofile'""' _n
di as text ""
di as text "Or run only the report generation to execute all steps automatically:"
di as text `"    do "`project_path'/`report_dir'/`report_dofile'""'
di as text "{hline 60}"
end

// Subprogram to create data management do file
program define create_data_dofile
args dir filename language project_path

tempname fh
capture file open `fh' using "`dir'/`filename'", write text replace
if _rc != 0 {
    di as error "Warning: Failed to create data do file: `dir'/`filename'"
    exit
}

if "`language'" == "cn" {
    file write `fh' `"// 数据管理脚本"' _n
    file write `fh' `"// 作者: Dingyuan Accounting Team"' _n
    file write `fh' `"// 创建日期: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* 设置工作目录到数据文件夹"' _n
    file write `fh' `"cd "`project_path'/`dir'""' _n
    file write `fh' _n
    file write `fh' `"* 导入Stata自带的auto数据集"' _n
    file write `fh' `"sysuse auto, clear"' _n
    file write `fh' _n
    file write `fh' `"* 数据清洗和变量创建"' _n
    file write `fh' `"gen price_ln = ln(price)"' _n
    file write `fh' `"gen weight_sq = weight^2"' _n
    file write `fh' `"label variable price_ln "价格的对数""' _n
    file write `fh' `"label variable weight_sq "重量的平方""' _n
    file write `fh' _n
    file write `fh' `"* 数据描述"' _n
    file write `fh' `"describe"' _n
    file write `fh' `"summarize"' _n
    file write `fh' _n
    file write `fh' `"* 保存处理后的数据到当前目录（数据文件夹）"' _n
    file write `fh' `"save "auto_processed.dta", replace"' _n
    file write `fh' _n
    file write `fh' `"* 检查文件是否保存成功"' _n
    file write `fh' `"capture confirm file "auto_processed.dta""' _n
    file write `fh' `"if _rc == 0 {"' _n
    file write `fh' `"    di "数据管理完成！已保存处理后的数据到 auto_processed.dta""' _n
    file write `fh' `"    di "文件位置: `project_path'/`dir'/auto_processed.dta""' _n
    file write `fh' `"}"' _n
    file write `fh' `"else {"' _n
    file write `fh' `"    di as error "错误: 数据文件保存失败！""' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"* 返回项目根目录"' _n
    file write `fh' `"cd "`project_path'""' _n
}
else {
    file write `fh' `"// Data Management Script"' _n
    file write `fh' `"// Author: Dingyuan Accounting Team"' _n
    file write `fh' `"// Created: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* Set working directory to data folder"' _n
    file write `fh' `"cd "`project_path'/`dir'""' _n
    file write `fh' _n
    file write `fh' `"* Load Stata built-in auto dataset"' _n
    file write `fh' `"sysuse auto, clear"' _n
    file write `fh' _n
    file write `fh' `"* Data cleaning and variable creation"' _n
    file write `fh' `"gen price_ln = ln(price)"' _n
    file write `fh' `"gen weight_sq = weight^2"' _n
    file write `fh' `"label variable price_ln "Log of Price""' _n
    file write `fh' `"label variable weight_sq "Weight Squared""' _n
    file write `fh' _n
    file write `fh' `"* Data description"' _n
    file write `fh' `"describe"' _n
    file write `fh' `"summarize"' _n
    file write `fh' _n
    file write `fh' `"* Save processed data to current directory (data folder)"' _n
    file write `fh' `"save "auto_processed.dta", replace"' _n
    file write `fh' _n
    file write `fh' `"* Check if file was saved successfully"' _n
    file write `fh' `"capture confirm file "auto_processed.dta""' _n
    file write `fh' `"if _rc == 0 {"' _n
    file write `fh' `"    di "Data management completed! Processed data saved to auto_processed.dta""' _n
    file write `fh' `"    di "File location: `project_path'/`dir'/auto_processed.dta""' _n
    file write `fh' `"}"' _n
    file write `fh' `"else {"' _n
    file write `fh' `"    di as error "Error: Data file save failed!""' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"* Return to project root directory"' _n
    file write `fh' `"cd "`project_path'""' _n
}

file close `fh'
end

// Subprogram to create program definition do file
program define create_program_dofile
args dir filename language project_path

tempname fh
capture file open `fh' using "`dir'/`filename'", write text replace
if _rc != 0 {
    di as error "Warning: Failed to create program do file: `dir'/`filename'"
    exit
}

if "`language'" == "cn" {
    file write `fh' `"// 程序定义脚本"' _n
    file write `fh' `"// 作者: Dingyuan Accounting Team"' _n
    file write `fh' `"// 创建日期: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* 设置工作目录到程序文件夹"' _n
    file write `fh' `"cd "`project_path'/`dir'""' _n
    file write `fh' _n
    file write `fh' `"* 定义数据描述程序"' _n
    file write `fh' `"capture program drop describe_data"' _n
    file write `fh' `"program define describe_data"' _n
    file write `fh' `"    version 18.0"' _n
    file write `fh' `"    syntax [varlist]"' _n
    file write `fh' `"    "' _n
    file write `fh' `"    di "=== 数据描述分析 ===""' _n
    file write `fh' `"    if "\`varlist'" != "" {"' _n
    file write `fh' `"        describe \`varlist'"' _n
    file write `fh' `"        summarize \`varlist', detail"' _n
    file write `fh' `"        tabstat \`varlist', statistics(mean sd min max) columns(statistics)"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    else {"' _n
    file write `fh' `"        describe"' _n
    file write `fh' `"        summarize, detail"' _n
    file write `fh' `"        tabstat, statistics(mean sd min max) columns(statistics)"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"end"' _n
    file write `fh' _n
    file write `fh' `"* 定义回归分析程序"' _n
    file write `fh' `"capture program drop run_regression"' _n
    file write `fh' `"program define run_regression"' _n
    file write `fh' `"    version 18.0"' _n
    file write `fh' `"    syntax, depvar(varname) indepvars(varlist) [if] [in]"' _n
    file write `fh' `"    "' _n
    file write `fh' `"    di "=== 回归分析: \`depvar' 对 \`indepvars' ===""' _n
    file write `fh' `"    regress \`depvar' \`indepvars' \`if' \`in'"' _n
    file write `fh' `"    estimates store model_\`depvar'"' _n
    file write `fh' `"end"' _n
    file write `fh' _n
    file write `fh' `"di "程序定义完成！已定义 describe_data 和 run_regression 程序""' _n
    file write `fh' _n
    file write `fh' `"* 返回项目根目录"' _n
    file write `fh' `"cd "`project_path'""' _n
}
else {
    file write `fh' `"// Program Definition Script"' _n
    file write `fh' `"// Author: Dingyuan Accounting Team"' _n
    file write `fh' `"// Created: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* Set working directory to program folder"' _n
    file write `fh' `"cd "`project_path'/`dir'""' _n
    file write `fh' _n
    file write `fh' `"* Define data description program"' _n
    file write `fh' `"capture program drop describe_data"' _n
    file write `fh' `"program define describe_data"' _n
    file write `fh' `"    version 18.0"' _n
    file write `fh' `"    syntax [varlist]"' _n
    file write `fh' `"    "' _n
    file write `fh' `"    di "=== Data Description Analysis ===""' _n
    file write `fh' `"    if "\`varlist'" != "" {"' _n
    file write `fh' `"        describe \`varlist'"' _n
    file write `fh' `"        summarize \`varlist', detail"' _n
    file write `fh' `"        tabstat \`varlist', statistics(mean sd min max) columns(statistics)"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    else {"' _n
    file write `fh' `"        describe"' _n
    file write `fh' `"        summarize, detail"' _n
    file write `fh' `"        tabstat, statistics(mean sd min max) columns(statistics)"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"end"' _n
    file write `fh' _n
    file write `fh' `"* Define regression analysis program"' _n
    file write `fh' `"capture program drop run_regression"' _n
    file write `fh' `"program define run_regression"' _n
    file write `fh' `"    version 18.0"' _n
    file write `fh' `"    syntax, depvar(varname) indepvars(varlist) [if] [in]"' _n
    file write `fh' `"    "' _n
    file write `fh' `"    di "=== Regression Analysis: \`depvar' on \`indepvars' ===""' _n
    file write `fh' `"    regress \`depvar' \`indepvars' \`if' \`in'"' _n
    file write `fh' `"    estimates store model_\`depvar'"' _n
    file write `fh' `"end"' _n
    file write `fh' _n
    file write `fh' `"di "Program definition completed! Defined describe_data and run_regression programs""' _n
    file write `fh' _n
    file write `fh' `"* Return to project root directory"' _n
    file write `fh' `"cd "`project_path'""' _n
}

file close `fh'
end

// Subprogram to create model estimation do file
program define create_model_dofile
args dir filename language project_path data_dir program_dir data_dofile program_dofile

tempname fh
capture file open `fh' using "`dir'/`filename'", write text replace
if _rc != 0 {
    di as error "Warning: Failed to create model do file: `dir'/`filename'"
    exit
}

if "`language'" == "cn" {
    file write `fh' `"// 模型估计脚本"' _n
    file write `fh' `"// 作者: Dingyuan Accounting Team"' _n
    file write `fh' `"// 创建日期: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* 首先运行数据管理和程序定义"' _n
    file write `fh' `"di "正在运行数据管理脚本...""' _n
    file write `fh' `"do "`project_path'/`data_dir'/`data_dofile'""' _n
    file write `fh' `"di "正在运行程序定义脚本...""' _n
    file write `fh' `"do "`project_path'/`program_dir'/`program_dofile'""' _n
    file write `fh' _n
    file write `fh' `"* 检查数据文件是否存在"' _n
    file write `fh' `"capture confirm file "`project_path'/`data_dir'/auto_processed.dta""' _n
    file write `fh' `"if _rc != 0 {"' _n
    file write `fh' `"    di as error "错误: 数据文件不存在！请先运行数据管理脚本。""' _n
    file write `fh' `"    exit 601"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"* 加载处理后的数据"' _n
    file write `fh' `"use "`project_path'/`data_dir'/auto_processed.dta", clear"' _n
    file write `fh' _n
    file write `fh' `"* 运行数据描述程序"' _n
    file write `fh' `"describe_data price mpg weight"' _n
    file write `fh' _n
    file write `fh' `"* 运行回归分析"' _n
    file write `fh' `"run_regression, depvar(price) indepvars(mpg weight foreign)"' _n
    file write `fh' _n
    file write `fh' `"* 保存模型结果（Stata格式，供后续分析使用）"' _n
    file write `fh' `"estimates save "`project_path'/`dir'/model_results.ster", replace"' _n
    file write `fh' _n
    file write `fh' `"* 将回归结果输出到文本文件"' _n
    file write `fh' `"capture log close"' _n
    file write `fh' `"log using "`project_path'/`dir'/regression_results.txt", replace text"' _n
    file write `fh' _n
    file write `fh' `"* 输出详细的回归结果"' _n
    file write `fh' `"di "=== 回归分析结果 ===""' _n
    file write `fh' `"estimates table model_price, b stats(N r2_a) star"' _n
    file write `fh' `"di """' _n
    file write `fh' _n
    file write `fh' `"* 输出模型统计量"' _n
    file write `fh' `"di "=== 模型统计量 ===""' _n
    file write `fh' `"di "观测值数量: " e(N)"' _n
    file write `fh' `"di "R平方: " e(r2)"' _n
    file write `fh' `"di "调整R平方: " e(r2_a)"' _n
    file write `fh' `"di "F统计量: " e(F)"' _n
    file write `fh' `"di """' _n
    file write `fh' _n
    file write `fh' `"* 模型诊断"' _n
    file write `fh' `"di "=== 模型诊断 ===""' _n
    file write `fh' `"estat hettest"' _n
    file write `fh' `"estat ovtest"' _n
    file write `fh' _n
    file write `fh' `"log close"' _n
    file write `fh' _n
    file write `fh' `"di "模型估计完成！结果已保存到以下文件：""' _n
    file write `fh' `"di "- Stata格式: model_results.ster（用于Stata内部使用）""' _n
    file write `fh' `"di "- 文本格式: regression_results.txt（可用任何文本编辑器打开）""' _n
}
else {
    file write `fh' `"// Model Estimation Script"' _n
    file write `fh' `"// Author: Dingyuan Accounting Team"' _n
    file write `fh' `"// Created: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* First run data management and program definition"' _n
    file write `fh' `"di "Running data management script...""' _n
    file write `fh' `"do "`project_path'/`data_dir'/`data_dofile'""' _n
    file write `fh' `"di "Running program definition script...""' _n
    file write `fh' `"do "`project_path'/`program_dir'/`program_dofile'""' _n
    file write `fh' _n
    file write `fh' `"* Check if data file exists"' _n
    file write `fh' `"capture confirm file "`project_path'/`data_dir'/auto_processed.dta""' _n
    file write `fh' `"if _rc != 0 {"' _n
    file write `fh' `"    di as error "Error: Data file does not exist! Please run data management script first.""' _n
    file write `fh' `"    exit 601"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"* Load processed data"' _n
    file write `fh' `"use "`project_path'/`data_dir'/auto_processed.dta", clear"' _n
    file write `fh' _n
    file write `fh' `"* Run data description program"' _n
    file write `fh' `"describe_data price mpg weight"' _n
    file write `fh' _n
    file write `fh' `"* Run regression analysis"' _n
    file write `fh' `"run_regression, depvar(price) indepvars(mpg weight foreign)"' _n
    file write `fh' _n
    file write `fh' `"* Save model results (Stata format for internal use)"' _n
    file write `fh' `"estimates save "`project_path'/`dir'/model_results.ster", replace"' _n
    file write `fh' _n
    file write `fh' `"* Export regression results to text file"' _n
    file write `fh' `"capture log close"' _n
    file write `fh' `"log using "`project_path'/`dir'/regression_results.txt", replace text"' _n
    file write `fh' _n
    file write `fh' `"* Output detailed regression results"' _n
    file write `fh' `"di "=== Regression Analysis Results ===""' _n
    file write `fh' `"estimates table model_price, b stats(N r2_a) star"' _n
    file write `fh' `"di """' _n
    file write `fh' _n
    file write `fh' `"* Output model statistics"' _n
    file write `fh' `"di "=== Model Statistics ===""' _n
    file write `fh' `"di "Number of observations: " e(N)"' _n
    file write `fh' `"di "R-squared: " e(r2)"' _n
    file write `fh' `"di "Adjusted R-squared: " e(r2_a)"' _n
    file write `fh' `"di "F-statistic: " e(F)"' _n
    file write `fh' `"di """' _n
    file write `fh' _n
    file write `fh' `"* Model diagnostics"' _n
    file write `fh' `"di "=== Model Diagnostics ===""' _n
    file write `fh' `"estat hettest"' _n
    file write `fh' `"estat ovtest"' _n
    file write `fh' _n
    file write `fh' `"log close"' _n
    file write `fh' _n
    file write `fh' `"di "Model estimation completed! Results saved to the following files:""' _n
    file write `fh' `"di "- Stata format: model_results.ster (for internal Stata use)""' _n
    file write `fh' `"di "- Text format: regression_results.txt (can be opened with any text editor)""' _n
}

file close `fh'
end

// Subprogram to create report generation do file
program define create_report_dofile
args dir filename language project_path model_dir data_dir model_dofile

tempname fh
capture file open `fh' using "`dir'/`filename'", write text replace
if _rc != 0 {
    di as error "Warning: Failed to create report do file: `dir'/`filename'"
    exit
}

if "`language'" == "cn" {
    file write `fh' `"// 报告生成脚本"' _n
    file write `fh' `"// 作者: Dingyuan Accounting Team"' _n
    file write `fh' `"// 创建日期: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* 首先运行模型估计"' _n
    file write `fh' `"di "正在运行模型估计脚本...""' _n
    file write `fh' `"do "`project_path'/`model_dir'/`model_dofile'""' _n
    file write `fh' _n
    file write `fh' `"* 设置输出格式"' _n
    file write `fh' `"set linesize 100"' _n
    file write `fh' `"* 关闭可能已存在的日志文件"' _n
    file write `fh' `"capture log close"' _n
    file write `fh' `"log using "`project_path'/`dir'/analysis_report.log", replace text"' _n
    file write `fh' _n
    file write `fh' `"* 加载模型结果"' _n
    file write `fh' `"use "`project_path'/`data_dir'/auto_processed.dta", clear"' _n
    file write `fh' `"estimates use "`project_path'/`model_dir'/model_results.ster""' _n
    file write `fh' _n
    file write `fh' `"* 生成描述性统计表格"' _n
    file write `fh' `"estpost summarize price mpg weight foreign"' _n
    file write `fh' `"esttab using "`project_path'/`dir'/descriptive_stats.rtf", replace cells("mean sd min max") noobs"' _n
    file write `fh' _n
    file write `fh' `"* 生成回归结果表格"' _n
    file write `fh' `"esttab model_price using "`project_path'/`dir'/regression_results.rtf", replace b(3) se(3) r2 ar2"' _n
    file write `fh' _n
    file write `fh' `"* 生成图表"' _n
    file write `fh' `"twoway (scatter price mpg) (lfit price mpg), title("价格与MPG的关系")"' _n
    file write `fh' `"graph export "`project_path'/`dir'/price_mpg_scatter.png", replace"' _n
    file write `fh' _n
    file write `fh' `"twoway (scatter price weight) (lfit price weight), title("价格与重量的关系")"' _n
    file write `fh' `"graph export "`project_path'/`dir'/price_weight_scatter.png", replace"' _n
    file write `fh' _n
    file write `fh' `"* 关闭日志"' _n
    file write `fh' `"log close"' _n
    file write `fh' _n
    file write `fh' `"di "报告生成完成！请查看以下文件：""' _n
    file write `fh' `"di "- 分析日志: `project_path'/`dir'/analysis_report.log""' _n
    file write `fh' `"di "- 描述统计: `project_path'/`dir'/descriptive_stats.rtf""' _n
    file write `fh' `"di "- 回归结果: `project_path'/`dir'/regression_results.rtf""' _n
    file write `fh' `"di "- 散点图: `project_path'/`dir'/price_mpg_scatter.png, `project_path'/`dir'/price_weight_scatter.png""' _n
}
else {
    file write `fh' `"// Report Generation Script"' _n
    file write `fh' `"// Author: Dingyuan Accounting Team"' _n
    file write `fh' `"// Created: `c(current_date)'"' _n
    file write `fh' _n
    file write `fh' `"* First run model estimation"' _n
    file write `fh' `"di "Running model estimation script...""' _n
    file write `fh' `"do "`project_path'/`model_dir'/`model_dofile'""' _n
    file write `fh' _n
    file write `fh' `"* Set output format"' _n
    file write `fh' `"set linesize 100"' _n
    file write `fh' `"* Close any existing log file"' _n
    file write `fh' `"capture log close"' _n
    file write `fh' `"log using "`project_path'/`dir'/analysis_report.log", replace text"' _n
    file write `fh' _n
    file write `fh' `"* Load model results"' _n
    file write `fh' `"use "`project_path'/`data_dir'/auto_processed.dta", clear"' _n
    file write `fh' `"estimates use "`project_path'/`model_dir'/model_results.ster""' _n
    file write `fh' _n
    file write `fh' `"* Generate descriptive statistics table"' _n
    file write `fh' `"estpost summarize price mpg weight foreign"' _n
    file write `fh' `"esttab using "`project_path'/`dir'/descriptive_stats.rtf", replace cells("mean sd min max") noobs"' _n
    file write `fh' _n
    file write `fh' `"* Generate regression results table"' _n
    file write `fh' `"esttab model_price using "`project_path'/`dir'/regression_results.rtf", replace b(3) se(3) r2 ar2"' _n
    file write `fh' _n
    file write `fh' `"* Generate graphs"' _n
    file write `fh' `"twoway (scatter price mpg) (lfit price mpg), title("Price vs MPG")"' _n
    file write `fh' `"graph export "`project_path'/`dir'/price_mpg_scatter.png", replace"' _n
    file write `fh' _n
    file write `fh' `"twoway (scatter price weight) (lfit price weight), title("Price vs Weight")"' _n
    file write `fh' `"graph export "`project_path'/`dir'/price_weight_scatter.png", replace"' _n
    file write `fh' _n
    file write `fh' `"* Close log"' _n
    file write `fh' `"log close"' _n
    file write `fh' _n
    file write `fh' `"di "Report generation completed! Please check the following files:""' _n
    file write `fh' `"di "- Analysis log: `project_path'/`dir'/analysis_report.log""' _n
    file write `fh' `"di "- Descriptive statistics: `project_path'/`dir'/descriptive_stats.rtf""' _n
    file write `fh' `"di "- Regression results: `project_path'/`dir'/regression_results.rtf""' _n
    file write `fh' `"di "- Scatter plots: `project_path'/`dir'/price_mpg_scatter.png, `project_path'/`dir'/price_weight_scatter.png""' _n
}

file close `fh'
end