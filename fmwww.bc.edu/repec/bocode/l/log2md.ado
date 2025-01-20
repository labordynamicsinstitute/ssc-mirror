prog define log2md 

    version 8.0

    // 解析输入参数，支持文件名、替换、追加、自定义标题 (目前内置在程序中，为默认的分隔符)
    syntax [anything] [, Replace Append Title(string) ]
    
	*syntax [anything] [, Replace Append Title(string) Separator(string)]
	
    // 如果未提供文件名或关键字，提示错误
    if "`anything'" == "" {
        display as error "You must specify a filename or use 'log close'."
        exit
    }

    // 检查是否是关闭命令
    if lower("`anything'") == "close" {
        // 检查是否有日志文件正在打开
        if "`c(logname)'" == "" {
            display as error "No log file is currently open."
            exit
        }

        // 关闭日志文件
        capture log close
        if _rc != 0 {
            display as error "Error occurred while closing the log file."
            exit
        }

        // 写入 Markdown 代码块的结束标记
        quietly {
            file open final_file using "`c(logname)'", write text append
            file write final_file "```" _n
            file close final_file
        }
        display as result "Markdown log closed and saved."
        exit
    }

    // 获取文件名
    local filename `"`anything'"'

    // 检查扩展名是否为 .md
    if !strpos(lower("`filename'"), ".md") {
        local filename "`filename'.md"
    }

    // 检查是否有日志文件已打开
    capture log close
    if _rc == 0 {
        display as result "Existing log file closed to start a new log."
    }

    // 处理文件替换逻辑
    if "`append'" == "" & "`replace'" == "" {
        capture confirm file "`filename'"
        if _rc == 0 {
            display as error "File `filename' already exists. Use option replace or append to continue."
            exit
        }
    }

    // 创建临时文件
    tempfile temp_output
    file open temp_out using `temp_output', write text replace

    // 添加欢迎语（始终在顶部）
    file write temp_out "## 欢迎使用自编外部命令log2md进行Markdown格式日志输出" _n

    // 输出日志模式
    if "`append'" != "" {
        file write temp_out "## 追加内容开始" _n
        file write temp_out "## 日志模式: 追加（append选项）" _n
    }
    else {
        file write temp_out "## Log工作日志已覆盖" _n
        file write temp_out "## 日志模式: 覆盖（replace选项）" _n
    }

    // 添加时间戳
    local timestamp = c(current_time)
    file write temp_out "## 开始时间: `timestamp'" _n

    // 输出自定义标题（如提供）
    if "`title'" != "" {
        file write temp_out "# `title'" _n
    }

    // 输出分隔符，使用默认分隔符（自定义分隔符目前暂未进行参数化）
    local separator "---"
    *if "`separator'" != "" {
    *    local separator "`separator'"
    *}
    file write temp_out "`separator'" _n

    // 添加 Markdown 代码块的起始标记
    file write temp_out "```" _n

    // 关闭临时文件以完成写入
    file close temp_out

    // 如果是追加模式，检查文件末尾是否有结束代码块
    if "`append'" != "" {
        // 打开目标文件以检查末尾
        file open check_file using "`filename'", read text
        local last_line ""
        while r(eof) == 0 {
            file read check_file line
            local last_line "`line'"
        }
        file close check_file

        // 如果最后一行不是 "```"，则追加结束代码块
        if trim("`last_line'") != "```" {
            file open finalize_file using "`filename'", write text append
            file write finalize_file "```" _n
            file close finalize_file
        }

        // 开始记录到 Markdown 文件
        quietly {
            log using "`filename'", text append
        }
        display as result "Markdown log started in append mode: `filename'"
    }
    else {
        // 开始记录到 Markdown 文件
        quietly {
            log using "`filename'", text replace
        }
        display as result "Markdown log started: `filename'"
    }

    // 重新打开临时文件为 "read" 模式
    file open temp_out using `temp_output', read text

    // 打开目标文件，写入临时文件内容
    file open final_file using "`filename'", write text append
    file read temp_out line
    while r(eof) == 0 {
        file write final_file "`line'" _n
        file read temp_out line		
    }

    // 关闭所有文件
    file close temp_out
    file close final_file

end
