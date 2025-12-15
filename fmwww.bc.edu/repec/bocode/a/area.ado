*! area v2.0.3 - Revised 14Dec2025
* Authors: 
*   Wu Lianghai, School of Business, Anhui University of Technology (AHUT)
*   Wu Xinzhuo, University of Bristol (UB)
*   Wu Hanyan, School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA)
* Emails: agd2010@yeah.net, 2957833979@qq.com, 2325476320@qq.com
* Description: Program to generate regional dummy variables with standardization and descriptive statistics

program area, rclass
    version 18.0
    syntax varlist(max=1)  // Accept both string and numeric variables
    
    // Check if the dataset has been saved; if not, warn the user
    if `"`c(filename)'"' == "" {
        display as error "Warning: The dataset has not been saved. Please save your data before proceeding."
        exit 601
    }
    
    // Get the variable name from varlist
    local var_name `varlist'
    
    // Check if area variable already exists
    capture confirm variable area
    if !_rc {
        display as error "Error: Variable 'area' already exists in the dataset. Please drop or rename it before running this command."
        exit 110
    }
    
    // Check if region variable already exists
    capture confirm variable region
    if !_rc {
        display as error "Error: Variable 'region' already exists in the dataset. Please drop or rename it before running this command."
        exit 110
    }
    
    // Clean up any existing value labels that might conflict
    capture label drop area_lbl
    capture label drop region_lbl
    
    // Clean up any existing temporary variables from previous runs
    forval i = 0/99 {
        local temp_num = 10000 + `i'
        local temp_var = "__" + substr("`temp_num'", 2, .)
        capture confirm variable `temp_var'
        if !_rc {
            capture drop `temp_var'
            display as text "Note: Temporary variable `temp_var' found and removed."
        }
    }
    
    quietly {
        // Check if the variable is string; if not, convert it to string
        capture confirm string variable `var_name'
        if _rc != 0 {
            display as text "Note: Variable `var_name' is not a string variable. Converting to string."
            
            // Create a unique temporary variable name
            local temp_counter 0
            while 1 {
                local temp_str "_area_temp_str_`temp_counter'"
                capture confirm variable `temp_str'
                if _rc {
                    // Variable doesn't exist, we can use this name
                    local str_temp `temp_str'
                    continue, break
                }
                local temp_counter = `temp_counter' + 1
            }
            
            tostring `var_name', gen(`str_temp')
            local var_name `str_temp'
        }
        
        // Create a unique name for cleaned province variable
        local temp_counter 0
        while 1 {
            local temp_prov "_area_temp_prov_`temp_counter'"
            capture confirm variable `temp_prov'
            if _rc {
                // Variable doesn't exist, we can use this name
                local prov_clean `temp_prov'
                continue, break
            }
            local temp_counter = `temp_counter' + 1
        }
        
        // Standardize province names (remove trailing characters like 省, 市, etc.)
        gen `prov_clean' = ustrtrim(`var_name')
        
        // Remove common suffixes
        replace `prov_clean' = ustrregexra(`prov_clean', "省$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "市$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "自治区$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "维吾尔自治区$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "壮族自治区$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "回族自治区$", "")
        replace `prov_clean' = ustrregexra(`prov_clean', "特别行政区$", "")
        
        // Standardize specific province names
        replace `prov_clean' = "内蒙古" if inlist(`prov_clean', "内蒙古", "内蒙古自治区", "内蒙")
        replace `prov_clean' = "广西" if inlist(`prov_clean', "广西", "广西壮族自治区", "广西省")
        replace `prov_clean' = "西藏" if inlist(`prov_clean', "西藏", "西藏自治区")
        replace `prov_clean' = "宁夏" if inlist(`prov_clean', "宁夏", "宁夏回族自治区")
        replace `prov_clean' = "新疆" if inlist(`prov_clean', "新疆", "新疆维吾尔自治区")
        replace `prov_clean' = "北京" if inlist(`prov_clean', "北京", "北京市")
        replace `prov_clean' = "天津" if inlist(`prov_clean', "天津", "天津市")
        replace `prov_clean' = "上海" if inlist(`prov_clean', "上海", "上海市")
        replace `prov_clean' = "重庆" if inlist(`prov_clean', "重庆", "重庆市")
        replace `prov_clean' = "香港" if inlist(`prov_clean', "香港", "香港特别行政区")
        replace `prov_clean' = "澳门" if inlist(`prov_clean', "澳门", "澳门特别行政区")
        replace `prov_clean' = "台湾" if inlist(`prov_clean', "台湾", "台湾省")
        
        // Generate region variable
        gen str12 region = ""
        
        // Central region provinces
        foreach i in 安徽 湖北 湖南 河南 江西 山西 {
            replace region = "中部地区" if `prov_clean' == "`i'"
        }
        
        // Western region provinces
        foreach j in 四川 陕西 重庆 新疆 云南 广西 贵州 甘肃 内蒙古 西藏 宁夏 青海 {
            replace region = "西部地区" if `prov_clean' == "`j'"
        }
        
        // Eastern region (all remaining provinces)
        replace region = "东部地区" if region == "" & `prov_clean' != ""
        
        // Create numeric area variable manually to avoid value label conflicts
        gen byte area = .
        replace area = 1 if region == "东部地区"
        replace area = 2 if region == "中部地区"
        replace area = 3 if region == "西部地区"
        
        // Define value labels for the area variable
        label define area_lbl 1 "东部地区" 2 "中部地区" 3 "西部地区"
        label values area area_lbl
        
        // Add variable label
        label variable area "Regional classification (1=East, 2=Central, 3=West)"
        
        // Clean up temporary variables
        if "`str_temp'" != "" {
            capture drop `str_temp'
        }
        
        if "`prov_clean'" != "" {
            capture drop `prov_clean'
        }
     }   
        // Return summary statistics
		display as text _newline "summary statistics: area"
        summarize area, detail
        return scalar N = r(N)
        return scalar mean = r(mean)
        return scalar sd = r(sd)
        return scalar min = r(min)
        return scalar max = r(max)
        
        // Count observations by region
        count if area == 1
        return scalar east_N = r(N)
        return scalar east_prop = r(N)/return(N)
        
        count if area == 2
        return scalar central_N = r(N)
        return scalar central_prop = r(N)/return(N)
        
        count if area == 3
        return scalar west_N = r(N)
        return scalar west_prop = r(N)/return(N)
        
        // Save the dataset with new variables
        save, replace
        
		display as text "Data saved with regional variable 'area' added."
		
		// Provide descriptive statistics
        display as text _newline "Regional Distribution:"
        tabulate area, missing
    
    // Display summary of changes
    display as text _newline "Summary:"
    display as text "1. Province names standardized"
    display as text "2. Regional variable 'area' created with value labels"
    display as text "3. Eastern region coded as 1, Central as 2, Western as 3"
    display as text "4. Dataset saved with changes"
    
end