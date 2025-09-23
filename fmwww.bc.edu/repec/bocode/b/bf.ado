capture prog drop bf
*! bf.ado v1.4.0 Wulianghai(AHUT) Chen Liwen(AHUT) Wu Hanyan(NUAA) 21Sep2025
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
}
else {
    local base_dir "Academic Friends"
    local project_dir "Dingyuan Accounting `issue'"
    local model_dir "model"
    local data_dir "data"
    local program_dir "program"
    local report_dir "report"
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

// Display current working directory
di _n as text "Current working directory: " as result "`c(pwd)'"
di _n as text "Dingyuan Accounting Issue `issue' workspace created successfully!"
di as text "Includes the following subdirectories: " as result "`dirs'"
end