*! myedit.ado version 1.4 
*! Author: Wu Lianghai(AHUT); Wu Hanyan(NUAA)  
*! Date: 25Dec2025

program define myedit
    version 18.0
    syntax anything(name=fname)
    
    // Remove possible .ado extension, uniform processing
    if substr("`fname'", -4, 4) == ".ado" {
        local cmd_name = substr("`fname'", 1, length("`fname'") - 4)
    }
    else {
        local cmd_name "`fname'"
    }
    
    // First check if it's a built-in command
    // Create a list of known built-in commands
    local builtin_cmds summarize drop list describe display save use clear set
    local is_builtin 0
    foreach builtin in `builtin_cmds' {
        if "`cmd_name'" == "`builtin'" {
            local is_builtin 1
            continue, break
        }
    }
    
    if `is_builtin' == 1 {
        display as text "`cmd_name' is a Stata built-in command, no corresponding ado file to edit."
        exit 0
    }
    
    // Try to find ado file directly using findfile
    capture findfile "`cmd_name'.ado"
    if _rc == 0 {
        local file_path "`r(fn)'"
    }
    else {
        // If findfile fails, use which command to check
        capture which `cmd_name'
        if _rc {
            display as error "Command `cmd_name' does not exist."
            exit 111
        }
        
        // Use simpler method to get path
        // Handle Windows and Unix/Mac separately
        if inlist(c(os), "Windows") {
            // Windows system
            capture {
                tempname handle
                tempfile temp_output
                // Use cmd's dir command to search
                shell dir /b/s "`c(sysdir_stata)'ado\**\`cmd_name'.ado" > "`temp_output'" 2>nul
                file open `handle' using "`temp_output'", read
                file read `handle' line
                if r(eof) == 0 {
                    local file_path = trim(`"`macval(line)'"')
                }
                file close `handle'
            }
        }
        else {
            // Unix/Mac system
            capture {
                tempname handle
                tempfile temp_output
                // Use find command to search
                shell find "`c(sysdir_stata)'" -name "`cmd_name'.ado" -type f 2>/dev/null | head -1 > "`temp_output'"
                file open `handle' using "`temp_output'", read
                file read `handle' line
                if r(eof) == 0 {
                    local file_path = trim(`"`macval(line)'"')
                }
                file close `handle'
            }
        }
        
        // If still not found, try simple search
        if `"`file_path'"' == "" {
            // Search in common ado directories
            local adodirs "`c(sysdir_personal)' `c(sysdir_plus)' `c(sysdir_base)'"
            foreach dir in `adodirs' {
                capture findfile "`cmd_name'.ado", path("`dir'")
                if !_rc {
                    local file_path "`r(fn)'"
                    continue, break
                }
            }
        }
        
        // If file path still not found
        if `"`file_path'"' == "" {
            display as error "Unable to find ado file for `cmd_name'."
            exit 601
        }
    }
    
    // Ensure file_path is defined
    if `"`file_path'"' == "" {
        display as error "Cannot determine file path for `cmd_name'."
        exit 601
    }
    
    // Handle path starting with "~" on Linux/Mac
    if inlist(c(os), "Unix", "MacOSX") {
        if substr(`"`file_path'"', 1, 1) == "~" {
            local home_path = c(sysdir_personal)
            local home_path = substr(`"`home_path'"', 1, strpos(`"`home_path'"', "/ado") - 1)
            if `"`home_path'"' != "" {
                local file_path = subinstr(`"`file_path'"', "~", `"`home_path'"', 1)
            }
        }
    }
    
    // Check if file exists
    capture confirm file `"`file_path'"'
    if _rc {
        display as error "Cannot access file: `file_path'"
        exit 601
    }
    
    // Check file size (over 1MB considered large)
    capture {
        mata: st_numscalar("filesize", filelength("`file_path'"))
        local file_size = filesize
    }
    if _rc == 0 {
        if `file_size' > 1048576 {  // 1MB = 1048576 bytes
            display as error "File too large (over 1MB), Stata editor may not handle it."
            display as text "Consider using an external text editor to open the file:"
            display as result `"`file_path'"'
            exit
        }
    }
    
    // Determine file source and give corresponding prompt
    display _newline as text "Opening: " as result `"`file_path'"' _newline
    
    // Check if in base directory
    if regexm(`"`file_path'"', "[\\/]base[\\/]") {
        display as error "Note: This file is a core file of Stata distribution, located in base directory."
        display as text "It is recommended to back up before editing, in case recovery is needed."
        display as text "The ado file has been opened and is ready for editing..."
		more
    }
    // Check if in personal directory
    else if regexm(`"`file_path'"', "[\\/]personal[\\/]") {
        display as error "Note: This file is in personal directory, likely a user-defined file."
        display as text "It is recommended to back up before editing, in case recovery is needed."
        display as text "The ado file has been opened and is ready for editing..."
        more
    }
    // Check if from SSC (plus directory)
    else if regexm(`"`file_path'"', "[\\/]plus[\\/]") {
        // Try to extract SSC package name
        local ssc_pkg ""
        // More precise regex, matching package names under plus directory
        if regexm(`"`file_path'"', "[\\/]plus[\\/]([a-z]+)[\\/]") {
            local ssc_pkg = regexs(1)
        }
        
        display as text "This file is from SSC (unofficial ado file repository)."
        
        // Prefer using command name as package name, as usually SSC package name matches command name
        if `"`cmd_name'"' != "" {
            display as text "To restore original file, you can reinstall:"
            display as result "ssc install `cmd_name', replace"
        }
        // If command name not suitable, use extracted package name
        else if `"`ssc_pkg'"' != "" {
            display as text "To restore original file, you can reinstall:"
            display as result "ssc install `ssc_pkg', replace"
        }
        else {
            display as text "To restore original file, please check SSC website to find corresponding package name."
        }
        display as text "The ado file has been opened and is ready for editing..."
        more
    }
    
    // Open file for editing
    doedit `"`file_path'"'
end