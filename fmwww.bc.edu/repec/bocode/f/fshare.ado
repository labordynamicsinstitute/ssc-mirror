*! fshare.ado version 2.1.0 2025-12-31
*! Authors: Wu Lianghai, Chen Liwen, Wu Hanyan, Liu Rui
*! Email: agd2010@yeah.net, 2184844526@qq.com, 2325476320@qq.com, 3221241855@qq.com
*! Function: Create course folder structure with syllabus and multiple modules

program define fshare
    version 16.0
    syntax anything(name=path id="Directory path") [, Module(numlist integer >0) m(numlist integer >0) LANGuage(string) STATA]
    
    // Clean path: remove extra quotes if present
    local path = subinstr(`"`path'"', `"""', "", .)
    local path = trim("`path'")
    
    // Handle module option aliases
    if "`module'" == "" & "`m'" != "" {
        local module `m'
    }
    
    // Set default language to Chinese
    if "`language'" == "" {
        local language "cn"
    }
    
    // Validate language option
    if !inlist("`language'", "cn", "en") {
        display as error "Language must be 'cn' (Chinese) or 'en' (English)"
        exit 198
    }
    
    // Language-specific messages
    if "`language'" == "cn" {
        local msg_path_error "路径 `path' 已存在同名文件，无法创建目录"
        local msg_module_default "注意：未指定模块号，将使用默认模块号 1"
        local msg_file_exists " 已存在同名文件，无法创建目录"
        local msg_dir_exists "注意：文件夹 "
        local msg_dir_exists2 " 已存在"
        local msg_create_error "无法创建目录 "
        local msg_success "文件夹结构创建成功："
        local msg_main_dir "  主目录: "
        local msg_syllabus "  教学大纲: "
        local msg_module "  模块"
        local msg_slash ": "
        local msg_subfolder "    ├─ "
        local msg_mod_label "模块"
        local msg_syllabus_name "教学大纲"
        local msg_main_dir_exists "注意：主目录已存在，将跳过创建"
        local msg_warning "警告："
        local msg_continue "将继续创建新的子文件夹..."
        local msg_reasons "可能的原因："
        local msg_reason1 "  1. 没有创建目录的权限"
        local msg_reason2 "  2. 路径包含非法字符"
        local msg_reason3 "  3. 磁盘已满或只读"
        local msg_reason4 "  4. 路径中的父目录不存在"
        local msg_reason5 "  5. 之前删除的目录可能仍在被系统锁定"
        local msg_readonly "注意：创建的文件夹可能被系统设置为只读属性"
        local msg_readonly_fix "可以手动右键点击文件夹->属性->取消'只读'选项"
        local msg_permission_advice "若创建失败，请检查权限和路径"
        local msg_stata_subfolders "数据 模型 程序 报告"
        local msg_stata_folder "stata"
        local msg_case "案例"
        local msg_slides "幻灯片"
        local msg_lectures "教案"
        local msg_papers "论文"
        local msg_tools_do "mytools.do"
    }
    else {
        local msg_path_error "Path `path' already exists as a file, cannot create directory"
        local msg_module_default "Note: No module number specified, using default module number 1"
        local msg_file_exists " already exists as a file, cannot create directory"
        local msg_dir_exists "Note: Directory "
        local msg_dir_exists2 " already exists"
        local msg_create_error "Cannot create directory "
        local msg_success "Directory structure created successfully:"
        local msg_main_dir "  Main directory: "
        local msg_syllabus "  Syllabus: "
        local msg_module "  Module"
        local msg_slash ": "
        local msg_subfolder "    ├─ "
        local msg_mod_label "Module"
        local msg_syllabus_name "Syllabus"
        local msg_main_dir_exists "Note: Main directory already exists, skipping creation"
        local msg_warning "Warning:"
        local msg_continue "Will continue to create new subfolders..."
        local msg_reasons "Possible reasons:"
        local msg_reason1 "  1. No permission to create directory"
        local msg_reason2 "  2. Path contains invalid characters"
        local msg_reason3 "  3. Disk is full or read-only"
        local msg_reason4 "  4. Parent directory does not exist"
        local msg_reason5 "  5. Previously deleted directory may still be locked by the system"
        local msg_readonly "Note: Created folders may have read-only attributes set by the system"
        local msg_readonly_fix "You can manually right-click folder->Properties->Uncheck 'Read-only'"
        local msg_permission_advice "If creation fails, check permissions and path"
        local msg_stata_subfolders "data models programs reports"
        local msg_stata_folder "stata"
        local msg_case "Cases"
        local msg_slides "Slides"
        local msg_lectures "Lectures"
        local msg_papers "Papers"
        local msg_tools_do "mytools.do"
    }
    
    // Check if path exists as a file
    capture confirm file `"`path'"'
    if _rc == 0 {
        display as error "`msg_path_error'"
        exit 693
    }
    
    // Set default module number if not specified
    if "`module'" == "" {
        local module = 1
        display as text "`msg_module_default'"
    }
    
    // Create syllabus directory path
    local syllabus_dir `"`path'/`msg_syllabus_name'"'
    
    // Check for syllabus directory as a file
    capture confirm file `"`syllabus_dir'"'
    if _rc == 0 {
        display as error `"`syllabus_dir'`msg_file_exists'"'
        exit 693
    }
    
    // Check if syllabus directory exists
    capture confirm directory `"`syllabus_dir'"'
    local syllabus_exists = (_rc == 0)
    
    // Check if main directory exists
    capture confirm directory `"`path'"'
    local main_dir_exists = (_rc == 0)
    
    // If main directory exists, display message
    if `main_dir_exists' {
        display as text "`msg_main_dir_exists'"
    }
    
    // Process multiple modules
    local module_dirs_list ""
    
    foreach mod_num of numlist `module' {
        // Create module directory path
        if "`language'" == "cn" {
            local module_dir `"`path'/模块`mod_num'"'
        }
        else {
            local module_dir `"`path'/Module`mod_num'"'
        }
        
        // Check for module directory as a file
        capture confirm file `"`module_dir'"'
        if _rc == 0 {
            display as error `"`module_dir'`msg_file_exists'"'
            exit 693
        }
        
        // Check if module directory exists
        capture confirm directory `"`module_dir'"'
        local mod_exists = (_rc == 0)
        
        if !`mod_exists' {
            local module_dirs_list "`module_dirs_list' `mod_num'"
        }
        else {
            display as text "`msg_dir_exists'`module_dir'`msg_dir_exists2'"
        }
    }
    
    // Exit if no new directories to create
    if ("`module_dirs_list'" == "" & !`main_dir_exists' & !`syllabus_exists') {
        if "`language'" == "cn" {
            display as text "所有文件夹已存在，无需创建"
        }
        else {
            display as text "All directories already exist, no need to create"
        }
        exit 0
    }
    
    // Create main directory if it doesn't exist
    if !`main_dir_exists' {
        capture mkdir `"`path'"'
        if _rc != 0 {
            capture confirm directory `"`path'"'
            if _rc != 0 {
                display as error "`msg_create_error'`path'"
                display as text "`msg_reasons'"
                display as text "`msg_reason1'"
                display as text "`msg_reason2'"
                display as text "`msg_reason3'"
                display as text "`msg_reason4'"
                display as text "`msg_reason5'"
                exit 693
            }
        }
    }
    
    // Create syllabus directory if it doesn't exist
    if !`syllabus_exists' {
        capture mkdir `"`syllabus_dir'"'
        if _rc != 0 {
            capture confirm directory `"`syllabus_dir'"'
            if _rc != 0 {
                display as error "`msg_create_error'`syllabus_dir'"
                display as text "`msg_reasons'"
                display as text "`msg_reason1'"
                display as text "`msg_reason2'"
                display as text "`msg_reason3'"
                display as text "`msg_reason4'"
                display as text "`msg_reason5'"
                exit 693
            }
        }
    }
    
    // Display success message
    display as result _n "`msg_success'"
    display as result "`msg_main_dir'`path'"
    
    if !`syllabus_exists' {
        display as result "`msg_syllabus'`syllabus_dir'"
    }
    
    // Display warning about read-only folders
    display as text _n "`msg_readonly'"
    display as text "`msg_readonly_fix'"
    display as text "`msg_permission_advice'"
    
    // Create module directories and subdirectories, and display them
    foreach mod_num of local module_dirs_list {
        // Create module directory path again
        if "`language'" == "cn" {
            local module_dir `"`path'/模块`mod_num'"'
        }
        else {
            local module_dir `"`path'/Module`mod_num'"'
        }
        
        // Create module directory
        capture mkdir `"`module_dir'"'
        if _rc != 0 {
            capture confirm directory `"`module_dir'"'
            if _rc != 0 {
                display as error "`msg_create_error'`module_dir'"
                display as text "`msg_reasons'"
                display as text "`msg_reason1'"
                display as text "`msg_reason2'"
                display as text "`msg_reason3'"
                display as text "`msg_reason4'"
                display as text "`msg_reason5'"
                exit 693
            }
        }
        
        // Display module directory
        display as result "`msg_module'`mod_num'`msg_slash'`module_dir'"
        
        // Create module subdirectories
        if "`stata'" != "" {
            if "`language'" == "cn" {
                local subfolders "案例 幻灯片 教案 论文 stata"
            }
            else {
                local subfolders "Cases Slides Lectures Papers stata"
            }
        }
        else {
            if "`language'" == "cn" {
                local subfolders "案例 幻灯片 教案 论文"
            }
            else {
                local subfolders "Cases Slides Lectures Papers"
            }
        }
        
        // Create and display subfolders
        local counter = 0
        local total = wordcount("`subfolders'")
        
        foreach subfolder of local subfolders {
            local subdir `"`module_dir'/`subfolder'"'
            
            // Check if subdirectory exists
            capture confirm directory `"`subdir'"'
            local subdir_exists = (_rc == 0)
            
            if !`subdir_exists' {
                // Create subdirectory
                capture mkdir `"`subdir'"'
                if _rc != 0 {
                    capture confirm directory `"`subdir'"'
                    if _rc != 0 {
                        display as error "`msg_create_error'`subdir'"
                        display as text "`msg_reasons'"
                        display as text "`msg_reason1'"
                        display as text "`msg_reason2'"
                        display as text "`msg_reason3'"
                        display as text "`msg_reason4'"
                        display as text "`msg_reason5'"
                        exit 693
                    }
                }
                
                // If this is stata folder and stata option is on, create stata subfolders
                if "`subfolder'" == "stata" & "`stata'" != "" {
                    foreach stata_sub of local msg_stata_subfolders {
                        local stata_subdir `"`subdir'/`stata_sub'"'
                        capture mkdir `"`stata_subdir'"'
                        
                        // If this is programs subfolder, create mytools.do file
                        if "`stata_sub'" == "程序" | "`stata_sub'" == "programs" {
                            local tools_file `"`stata_subdir'/`msg_tools_do'"'
                            
                            // Create mytools.do file with correct content
                            tempname fh
                            capture file open `fh' using `"`tools_file'"', write text replace
                            if _rc == 0 {
                                file write `fh' "/* Developed SSC online ado programs: " _n
                                file write `fh' "    art2tex; case2tex; area; qta; eui; ……; tab2excel; myedit." _n
                                file write `fh' "*/ " _n
                                file write `fh' "" _n
                                file write `fh' "* Download methods   " _n
                                file write `fh' "    ssc install myedit  " _n
                                file write `fh' "    ssc install art2tex, replace  " _n
                                file write `fh' "    ssc new  " _n
                                file write `fh' "    ssc hot  " _n
                                file write `fh' "    ssc desc tab2excel" _n
                                file close `fh'
                            }
                        }
                    }
                }
            }
            
            // Display subfolder
            local counter = `counter' + 1
            if `counter' == `total' {
                display as result "    └─ `subfolder'"
            }
            else {
                display as result "    ├─ `subfolder'"
            }
        }
        
        // Add blank line between multiple modules
        if wordcount("`module_dirs_list'") > 1 & "`mod_num'" != word("`module_dirs_list'", wordcount("`module_dirs_list'")) {
            display as result ""
        }
    }
    
end