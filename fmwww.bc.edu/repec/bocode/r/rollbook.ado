*! rollbook v1.4
*! Authors: 
*!   (1) Wu Lianghai, School of Business, Anhui University of Technology(AHUT) Ma'anshan, China, Email: agd2010@yeah.net
*!   (2) Chen Liwen, School of Business, Anhui University of Technology(AHUT) Ma'anshan, China, Email: 2184844526@qq.com
*!   (3) Hu Fangfang, School of Finance and Economics, Wanjiang University of Technology(WJUT), Ma'anshan, China, Email: huff470@163.com
*!   (4) Jin Xuening, School of Business, Anhui University of Technology(AHUT), Ma'anshan, China, Email: 1418924481@qq.com

capture program drop rollbook
program define rollbook
    version 15
    syntax using/, [n(integer 0) serial(string) even(string) major(string) sheet(string)]
    
    // Check if file exists
    capture confirm file "`using'"
    if _rc != 0 {
        di as error "File '`using'' not found in current directory."
        di as error "Please make sure the rollbook.xlsx file is placed in the current working directory."
        exit 601
    }
    
    // Handle sheet option
    if "`sheet'" != "" {
        import excel "`using'", clear firstrow sheet("`sheet'")
        di "Successfully read Excel file, sheet: `sheet', total " _N " records"
    }
    else {
        import excel "`using'", clear firstrow
        di "Successfully read Excel file, total " _N " records"
    }
    
    // Handle major option (if specified)
    if "`major'" != "" {
        keep if 专业 == "`major'"
        if _N == 0 {
            di as error "Specified major not found"
            exit 198
        }
        di "Filtered by major: `major', remaining " _N " records"
    }
    
    // Handle serial option
    if "`serial'" != "" {
        // Ensure serial number column is string type to handle various formats
        capture confirm numeric variable 序号
        if _rc == 0 {
            tostring 序号, replace
        }
        
        // Clean serial number column, remove possible spaces
        replace 序号 = strtrim(序号)
        
        // Process serial number list
        local serial_list ""
        foreach s in `serial' {
            local serial_list "`serial_list' `s'"
        }
        local serial_list = strtrim("`serial_list'")
        
        preserve
        gen keep_flag = 0
        foreach s in `serial_list' {
            replace keep_flag = 1 if 序号 == "`s'"
        }
        
        keep if keep_flag == 1
        drop keep_flag
        
        if _N == 0 {
            di as error "Specified serial numbers not found"
            exit 198
        }
        
        di _n(2)
        di as green "Sampling results by serial number:"
        di as green "=========================================="
        forvalues i = 1/`=_N' {
            local selected_id = 学号[`i']
            local selected_name = 姓名[`i']
            local selected_major = 专业[`i']
            local selected_serial = 序号[`i']
            
            di as green "Serial: `selected_serial'"
            di as green "Student ID: `selected_id'"
            di as green "Name: `selected_name'"
            di as green "Major: `selected_major'"
            di as green "------------------------------------------"
        }
        restore
        exit
    }
    
    // Handle even option
    if "`even'" != "" {
        if !inlist("`even'", "odd", "even") {
            di as error "even() option must be odd or even"
            exit 198
        }
        
        // Ensure student ID is string type
        capture confirm numeric variable 学号
        if _rc == 0 {
            tostring 学号, replace
        }
        
        // Clean student ID, remove possible spaces
        replace 学号 = strtrim(学号)
        
        // Get last digit
        gen last_digit = substr(学号, -1, 1)
        
        // Ensure last character is a digit
        gen is_digit = regexm(last_digit, "^[0-9]$")
        
        // Determine odd/even
        gen is_even = mod(real(last_digit), 2) == 0 if is_digit
        
        if "`even'" == "odd" {
            preserve
            keep if is_even == 0 & is_digit == 1
        }
        else {
            preserve
            keep if is_even == 1 & is_digit == 1
        }
        
        drop last_digit is_digit is_even
        
        if _N == 0 {
            di as error "No student IDs matching the criteria found"
            exit 198
        }
        
        di _n(2)
        di as green "Sampling results by student ID parity (`even'):"
        di as green "=========================================="
        forvalues i = 1/`=_N' {
            local selected_id = 学号[`i']
            local selected_name = 姓名[`i']
            local selected_major = 专业[`i']
            
            di as green "Student ID: `selected_id'"
            di as green "Name: `selected_name'"
            di as green "Major: `selected_major'"
            di as green "------------------------------------------"
        }
        restore
        exit
    }
    
    // Handle major option (when used alone)
    if "`major'" != "" {
        di _n(2)
        di as green "Sampling results by major (`major'):"
        di as green "=========================================="
        forvalues i = 1/`=_N' {
            local selected_id = 学号[`i']
            local selected_name = 姓名[`i']
            local selected_major = 专业[`i']
            
            di as green "Student ID: `selected_id'"
            di as green "Name: `selected_name'"
            di as green "Major: `selected_major'"
            di as green "------------------------------------------"
        }
        exit
    }
    
    // Default random sampling
    if `n' == 0 {
        di as error "Must specify sampling quantity n()"
        exit 198
    }
    
    if `n' > _N local n = _N
    
    // Use simpler method to set random seed
    *set seed 12345
    gen random = runiform()
    sort random
    
    di _n(2)
    di as green "Random sampling results:"
    di as green "=========================================="
    
    forvalues i = 1/`n' {
        local selected_id = 学号[`i']
        local selected_name = 姓名[`i']
        local selected_major = 专业[`i']
        
        di as green "Student selected #`i':"
        di as green "Student ID: `selected_id'"
        di as green "Name: `selected_name'"
        di as green "Major: `selected_major'"
        di as green "------------------------------------------"
    }
end