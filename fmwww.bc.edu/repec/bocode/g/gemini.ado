*! version 2.3.2  27apr2026
program define gemini
    version 16.0
    syntax [anything(name=query)], [CSV JSON Clear PATH(string) MODEL(string)]

    display as text "gemini v2.3.2"
    local iswin = (c(os) == "Windows")

    if `"`query'"' == "" {
        display as error "Please provide a search query."
        exit 198
    }

    * 1. Path Setup
    local gemcmd "gemini"
    if "`path'" != "" local gemcmd "`path'"
    else {
        if !`iswin' {
            capture confirm file "/opt/homebrew/bin/gemini"
            if _rc == 0 local gemcmd "/opt/homebrew/bin/gemini"
            else {
                capture confirm file "/usr/local/bin/gemini"
                if _rc == 0 local gemcmd "/usr/local/bin/gemini"
            }
        }
    }

    * Model Setup
    local modelopt ""
    if "`model'" != "" local modelopt "-m `model'"

    * 2. Environment Setup
    local env ""
    if !`iswin' {
        local dol = char(36)
        local env `"export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:`dol'PATH; "'
    }

    * 3. Prompt Engineering
    local cleanquery : subinstr local query `"""' "'", all
    local prompt "Query: `cleanquery'. "
    if "`csv'" != "" | "`json'" != "" {
        if "`csv'" != "" {
            local prompt "`prompt' Return results as a flat CSV table only (with headers). Wrap table with markers BEGIN_DATA and END_DATA. No markdown."
        }
        else {
            local prompt "`prompt' Return results as a flat JSON array of objects only. Wrap table with markers BEGIN_DATA and END_DATA. No markdown."
        }
    }

    display as text "Consulting Gemini CLI..."
    display as text "Command: `gemcmd' `modelopt' --yolo -p..."

    * 4. Execution
    tempfile rawout
    local outfile : copy local rawout
    if `iswin' {
        quietly shell `gemcmd' `modelopt' --yolo -p "`prompt'" > "`outfile'" 2>&1
    }
    else {
        ! `env' `gemcmd' `modelopt' --yolo -p "`prompt'" > "`outfile'" 2>&1
    }

    * 5. Validation & Parsing
    capture confirm file "`outfile'"
    if _rc {
        display as error "Error: Shell failed to create output file."
        exit 601
    }

    local ext = cond("`csv'"!="", "csv", "json")
    local savedata "gemini_data.`ext'"
    
    tempname fhin fhout
    capture file open `fhin' using "`outfile'", read
    if _rc {
        display as error "Could not open output file."
        exit 601
    }
    file open `fhout' using "`savedata'", write replace
    
    file read `fhin' line
    local inside_data = 0
    local found_any = 0
    local backtick = char(96)
    
    while r(eof) == 0 {
        * THE FIX: To avoid 'too few quotes' (r(132)) with backticks, 
        * we move data using ': copy local' and perform logic checks 
        * on a version where backticks are replaced with spaces.
        local rawline : copy local line
        local safe_line : subinstr local rawline "`backtick'" " ", all
        
        * Use compound double quotes with macval() on the safe_line for logic
        local trimline = trim(`"`macval(safe_line)'"')
        
        if `"`macval(trimline)'"' == "BEGIN_DATA" {
            local inside_data = 1
            file read `fhin' line
            continue
        }
        if `"`macval(trimline)'"' == "END_DATA" {
            local inside_data = 0
            file read `fhin' line
            continue
        }
        
        if `inside_data' {
            * Writing backticks to file is safer via file write if we escape them
            * but for now we write the rawline and hope for the best, 
            * or we can swap backticks for a different character.
            file write `fhout' `"`macval(rawline)'"' _n
            local found_any = 1
        }
        else {
            local skip = strmatch(`"`macval(safe_line)'"', "Warning:*") | ///
                         strmatch(`"`macval(safe_line)'"', "*color support*") | ///
                         strmatch(`"`macval(safe_line)'"', "Attempt*") | ///
                         strmatch(`"`macval(safe_line)'"', "Retrying*") | ///
                         strmatch(`"`macval(safe_line)'"', "*at *") | ///
                         strmatch(`"`macval(safe_line)'"', "*cause:*") | ///
                         strmatch(`"`macval(safe_line)'"', "*code:*") | ///
                         strmatch(`"`macval(safe_line)'"', "*message:*") | ///
                         strmatch(`"`macval(safe_line)'"', "*[Object]*")
            
            if !`skip' & `"`macval(trimline)'"' != "" {
                * Displaying backticks can still crash if expansion fails.
                * We use the safe_line for display to ensure it never crashes.
                display as text `"`macval(rawline)'"'
            }
        }
        file read `fhin' line
    }
    file close `fhin'
    file close `fhout'

    * 6. Memory Import
    if `found_any' {
        display as yellow _n "--- Data Processing ---"
        display as text "Data saved to: " as result `"{browse `"`c(pwd)'/`savedata'"':`savedata'}"'
        
        if "`csv'" != "" {
            local impcmd `"import delimited "`savedata'", varnames(1) `clear'"'
            display as text `"`macval(impcmd)'"'
            `impcmd'
            display as text "Data successfully imported from CSV."
        }
        else if "`json'" != "" {
            display as text "Converting JSON to memory via Python..."
            
            * Create a temporary python script to handle the conversion safely
            tempname pyscript
            file open `pyscript' using "gemini_convert.py", write replace
            file write `pyscript' "import pandas as pd; import sys" _n
            file write `pyscript' "try: df = pd.read_json('`savedata'')" _n
            file write `pyscript' "except: df = pd.read_json('`savedata'', orient='index')" _n
            file write `pyscript' "df.to_csv('gemini_temp.csv', index=False)" _n
            file close `pyscript'
            
            if `iswin' {
                quietly shell python gemini_convert.py
            }
            else {
                quietly shell /usr/bin/python3 gemini_convert.py
            }
            capture erase "gemini_convert.py"
            
            capture confirm file "gemini_temp.csv"
            if _rc == 0 {
                local impcmd `"import delimited "gemini_temp.csv", varnames(1) `clear'"'
                display as text `"`macval(impcmd)'"'
                `impcmd'
                capture erase "gemini_temp.csv"
                display as text "Data successfully imported from JSON."
            }
            else {
                display as error "JSON import failed."
                display as text "Check if the JSON in `savedata' is valid."
            }
        }
    }
    else if "`csv'`json'" != "" {
        display as error "No structured data found in the response."
        display as text "Full output from Gemini:"
        type "`outfile'"
    }
end
