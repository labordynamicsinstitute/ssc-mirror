*! bmc.ado v2.7 - Automatically generate chapter configuration text files
*! Authors: 
*!   Wu Lianghai (First Author) - School of Business, Anhui University of Technology (AHUT)
*!   Wu Hanyan   (Second Author) - School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA)
*!   Hu Fangfang (Third Author)  - School of Finance and Economics, Wanjiang University of Technology (WJUT)
*! Date: 02May2026
*! Purpose: Generate bmc#.txt files based on user-input chapter numbers and titles
*! Update: v2.7 Add mono() option for monograph title customization
program define bmc
    version 16.0
    syntax [, Chapter(integer 1) Title(string) Save(string) Date(string) Length(integer 8000) Replace Author(string) LANGuage(string) LOGO(string) CASElength(integer 1000) SLIDe(integer 10) MONOgraph(string)]
    
    // Set default values
    if "`author'" == "" {
        local author "Prof. Wu Lianghai"
    }
    
    // Set monograph default value
    if "`monograph'" == "" {
        local monograph "智能会计：理论、工具与应用"
    }
    
    if "`language'" == "" {
        local language "Chinese"
    }
    else if !inlist("`language'", "Chinese", "中文", "English", "英文") {
        di "Warning: language() parameter must be 'Chinese'/'中文' or 'English'/'英文', automatically set to 'Chinese'"
        local language "Chinese"
    }
    
    // Set Logo default value
    if "`logo'" == "" {
        local logo "ahut"
    }
    
    // Validate and set case length
    if `caselength' <= 0 {
        local caselength 1000
        if inlist("`language'", "Chinese", "中文") {
            di "警告：caselength()参数必须为正整数，已自动设置为1000"
        }
        else {
            di "Warning: caselength() parameter must be a positive integer, automatically set to 1000"
        }
    }
    
    // Validate and set slide number
    if `slide' <= 0 {
        local slidenum 10
        if inlist("`language'", "Chinese", "中文") {
            di "警告：slide()参数必须为正整数，已自动设置为10"
        }
        else {
            di "Warning: slide() parameter must be a positive integer, automatically set to 10"
        }
    }
    else {
        local slidenum `slide'
    }
    
    // Prompt for title if not provided
    if "`title'" == "" {
        if inlist("`language'", "Chinese", "中文") {
            di "请输入第`chapter'章标题（例如：智能财务报告与分析）："
        }
        else {
            di "Please enter the title for Chapter `chapter' (e.g., Intelligent Financial Reporting and Analysis):"
        }
        display _request(title)
    }
    
    // Process save path
    if "`save'" == "" {
        local savepath ""
        local filename "bmc`chapter'.txt"
    }
    else {
        local savepath "`save'"
        // Ensure path ends with backslash (Windows compatible)
        if substr("`savepath'", -1, 1) != "\" {
            local savepath "`savepath'\"
        }
        // Create directory if it doesn't exist
        capture mkdir "`savepath'"
        local filename "`savepath'bmc`chapter'.txt"
    }
    
    // Process date
    if "`date'" == "" {
        local filedate "18Jan2026"
    }
    else {
        local filedate "`date'"
    }
    
    // Process text length
    if `length' <= 0 {
        local textlength 8000
        if inlist("`language'", "Chinese", "中文") {
            di "警告：length()参数必须为正整数，已自动设置为8000"
        }
        else {
            di "Warning: length() parameter must be a positive integer, automatically set to 8000"
        }
    }
    else {
        local textlength `length'
    }
    
    // Check if file already exists
    if "`replace'" == "" {
        capture confirm file "`filename'"
        if _rc == 0 {
            if inlist("`language'", "Chinese", "中文") {
                di "错误：文件 `filename' 已存在！"
                di "请使用replace选项覆盖现有文件，或选择其他章节号。"
            }
            else {
                di "Error: File `filename' already exists!"
                di "Please use the replace option to overwrite the existing file, or choose a different chapter number."
            }
            exit 602
        }
    }
    else {
        if inlist("`language'", "Chinese", "中文") {
            di "注意：将覆盖已存在的文件 `filename'"
        }
        else {
            di "Note: Will overwrite the existing file `filename'"
        }
    }
    
    // Open file and write content
    tempname fh
    if "`replace'" != "" {
        capture file open `fh' using "`filename'", write text replace
    }
    else {
        capture file open `fh' using "`filename'", write text
    }
    
    if _rc {
        if inlist("`language'", "Chinese", "中文") {
            di "错误：无法创建文件 `filename'"
            di "错误代码：`=_rc'"
        }
        else {
            di "Error: Cannot create file `filename'"
            di "Error code: `=_rc'"
        }
        exit _rc
    }
    
    // Write file header
    file write `fh' `"[file name]: bmc`chapter'.txt"' _n
    file write `fh' `"[file content begin]"' _n
    
    // Select template based on language
    if inlist("`language'", "Chinese", "中文") {
        // Chinese template
        // Item 1: Upload chapter file and generate content
        file write `fh' "1、（上传教学大纲outline.pdf）开发《`title'》，学术专著《`monograph'》的第`chapter'章。核心观点包括：（这里填写观点文本）；基本框架是：（这里填写框架文本）。作者：`author'，时间：`filedate'。篇幅控制在`textlength'字左右。" _n _n
        
        // Item 2: Generate LaTeX program file
        file write `fh' "2、(上传`title'.docx)生成本章的程序文件ch`chapter'.tex，以便LaTeX一键编译生成PDF文档，目录蓝色超链接并独占一页，中文左双引号需要规范化，相应tex代码形如``，即两个左单引号。作者：`author'，时间：`filedate'。添加单位Logo：`logo'.jpg(png/pdf)；tex文档类型为article。" _n _n
        
        // Item 3: Generate teaching plan
        file write `fh' "3、（上传教学大纲outline.pdf和ch`chapter'.pdf）生成第`chapter'章的教案teaching`chapter'。编写：`author'，时间：`filedate'。" _n _n
        
        // Item 4: Generate teaching plan LaTeX program file
        file write `fh' "4、（上传teaching`chapter'.docx）生成教案的程序文件teaching`chapter'.tex，以便LaTeX一键编译生成PDF文档，目录蓝色超链接并独占一页，中文左双引号需要规范化，相应tex代码形如``，即两个左单引号。编写：`author'，时间：`filedate'。添加单位Logo：`logo'.jpg(png/pdf)。" _n _n
        
        // Item 5: Generate slides
        file write `fh' "5、（上传teaching`chapter'.pdf）生成`slidenum'张演示幻灯片设计lecture`chapter'.tex（LaTeX代码）。要求幻灯片突出教学重点，直接插入flowchart.pdf，充分展示核心流程与代码精要，风格简洁大方，暖色调，充分彰显秀山汇文智能会计【人文向善，科学规范】的学术追求；运用tikz，生成独立绘图的tex程序文件，从lecture`chapter'.tex中剥离tikz绘图代码；修改后的lecture`chapter'.tex直接插入这些独立绘图文件生成的PDF图片。编写：`author'，时间：`filedate'。添加单位Logo：`logo'.jpg(png/pdf)。" _n _n
        
        // Item 6: Generate mini case
        file write `fh' "6、(上传第`chapter'章ch`chapter'.pdf)生成微型案例case`chapter'.docx，`caselength'字左右。" _n _n
        
        // Item 7: Generate case LaTeX program file
        file write `fh' "7、（上传case`chapter'.docx）生成case`chapter'.tex，以便LaTeX一键编译生成PDF文档，目录蓝色超链接并独占一页，中文左双引号需要规范化，相应tex代码形如``，即两个左单引号。编写：`author'，时间：`filedate'。添加单位Logo：`logo'.jpg(png/pdf)。" _n
    }
    else {
        // English template - need to check if monograph title is in Chinese
        local is_chinese_title = regexm("`monograph'", "[一-龥]")
        
        if `is_chinese_title' {
            // If monograph title is in Chinese, use Chinese title in quotes
            local monograph_display "`monograph'"
        }
        else {
            // If monograph title is in English, use English title without extra quotes
            local monograph_display "`monograph'"
        }
        
        // Item 1: Upload chapter file and generate content
        file write `fh' "1. (Upload syllabus outline.pdf) Develop Chapter `chapter' titled '`title'' for the academic monograph '`monograph_display''. Key points include: (fill in the key points); Basic framework: (fill in the framework). Author: `author', Date: `filedate'. Length: about `textlength' words." _n _n
        
        // Item 2: Generate LaTeX program file
        file write `fh' "2. (Upload `title'.docx) Generate LaTeX program file ch`chapter'.tex for compiling PDF documents with one click. The table of contents should have blue hyperlinks and occupy a separate page. Author: `author', Date: `filedate'. Add `logo' Logo: `logo'.jpg(png/pdf); Document type: article." _n _n
        
        // Item 3: Generate teaching plan
        file write `fh' "3. (Upload syllabus outline.pdf and ch`chapter'.pdf) Generate teaching plan teaching`chapter' for Chapter `chapter'. Author: `author', Date: `filedate'." _n _n
        
        // Item 4: Generate teaching plan LaTeX program file
        file write `fh' "4. (Upload teaching`chapter'.docx) Generate LaTeX program file teaching`chapter'.tex for the teaching plan. The table of contents should have blue hyperlinks and occupy a separate page. Author: `author', Date: `filedate'. Add `logo' Logo: `logo'.jpg(png/pdf)." _n _n
        
        // Item 5: Generate slides
        file write `fh' "5. (Upload teaching`chapter'.pdf) Generate `slidenum'-slide presentation lecture`chapter'.tex (LaTeX code). Slides should highlight teaching key points, directly insert flowchart.pdf, fully demonstrate core processes and code essentials, with a simple and elegant warm-tone style. Use tikz to generate standalone drawing tex files, separate tikz drawing code from lecture`chapter'.tex; the modified lecture`chapter'.tex should directly insert PDF images generated by these standalone drawing files. Author: `author', Date: `filedate'. Add institution Logo: `logo'.jpg(png/pdf)." _n _n
        
        // Item 6: Generate mini case
        file write `fh' "6. (Upload Chapter `chapter' ch`chapter'.pdf) Generate mini case study case`chapter'.docx, about `caselength' words." _n _n
        
        // Item 7: Generate case LaTeX program file
        file write `fh' "7. (Upload case`chapter'.docx) Generate case`chapter'.tex for compiling PDF documents with one click. The table of contents should have blue hyperlinks and occupy a separate page. Author: `author', Date: `filedate'. Add `logo' Logo: `logo'.jpg(png/pdf)." _n
    }
    
    // Write file footer
    file write `fh' `"[file content end]"'
    
    // Close file
    file close `fh'
    
    // Display generation results - bilingual support
    di _n
    if inlist("`language'", "Chinese", "中文") {
        di "已成功生成配置文件：`filename'"
        di "章节信息：第`chapter'章 `title'"
        di "学术专著：《`monograph'》"
        di "保存路径：`savepath'"
        di "文件时间：`filedate'"
        di "章节文本长度：约`textlength'字"
        di "案例文本长度：约`caselength'字"
        di "幻灯片数量：`slidenum'张"
        di "作者：`author'"
        di "语言：`language'"
        di "Logo文件：`logo'.jpg(png/pdf)"
        di "编写：`author'，时间：`filedate'"
    }
    else {
        di "Configuration file successfully generated: `filename'"
        di "Chapter info: Chapter `chapter' '`title''"
        di "Monograph: '`monograph''"
        di "Save path: `savepath'"
        di "File date: `filedate'"
        di "Chapter text length: about `textlength' words"
        di "Case text length: about `caselength' words"
        di "Slide number: `slidenum' slides"
        di "Author: `author'"
        di "Language: `language'"
        di "Logo file: `logo'.jpg(png/pdf)"
        di "Created by: `author', Date: `filedate'"
    }
    
    // Display file content (optional)
    di _n
    if inlist("`language'", "Chinese", "中文") {
        di "文件内容预览："
    }
    else {
        di "File content preview:"
    }
    type "`filename'"
end