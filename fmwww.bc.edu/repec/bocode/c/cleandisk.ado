*! cleandisk v1.1 Wu LiangHai/Chen Liwen/Wu HanYan/Ma Defang
*! New features:
*! 1. exit option: automatically exit Stata after cleaning
*! 2. Progress display: show cleaning progress and estimated remaining time

program define cleandisk
    version 16
    syntax [, DRIVES(string) TEMPonly QUIetly EXIT]
    
    // Record start time
    local start_time = clock(c(current_date) + " " + c(current_time), "DMY hms")
    
    // Default drives
    if "`drives'" == "" {
        local drives "c d e f"
    }
    
    // Calculate number of drives
    local total_drives = wordcount("`drives'")
    local current_drive_num = 0
    
    // Display start message
    if "`quietly'" == "" {
        di as text _n "Starting disk cleaning..."
        di as text "Total drives to clean: `total_drives'"
        di as text "{hline 50}"
    }
    
    // Clean temporary files
    if "`temponly'" != "" {
        foreach drive of local drives {
            local current_drive_num = `current_drive_num' + 1
            
            // Display progress
            if "`quietly'" == "" {
                local progress = round((`current_drive_num' - 1) / `total_drives' * 100)
                di as text "Cleaning drive `drive':\ (Progress: `progress'%)"
                di as text "Cleaning temporary files and recycle bin..."
            }
            
            // Cleaning operations
            cap qui {
                // Clean Windows temporary folder
                shell del /q "`drive':\Windows\Temp\*" 2>nul
                
                // Clean user temporary folders
                shell del /q "`drive':\Users\*\AppData\Local\Temp\*" 2>nul
                
                // Clean recycle bin
                shell rd /s /q "`drive':\$Recycle.Bin" 2>nul
            }
            
            // Display completion message
            if "`quietly'" == "" {
                local progress = round(`current_drive_num' / `total_drives' * 100)
                
                // Calculate elapsed time and estimated remaining time
                local current_time = clock(c(current_date) + " " + c(current_time), "DMY hms")
                local elapsed_seconds = (`current_time' - `start_time') / 1000
                local avg_time_per_drive = `elapsed_seconds' / `current_drive_num'
                local remaining_drives = `total_drives' - `current_drive_num'
                local estimated_seconds_remaining = round(`remaining_drives' * `avg_time_per_drive')
                
                if `estimated_seconds_remaining' > 0 {
                    local minutes_remaining = floor(`estimated_seconds_remaining' / 60)
                    local seconds_remaining = mod(`estimated_seconds_remaining', 60)
                    di as text "Drive `drive':\ cleaned (Progress: `progress'%)"
                    di as text "Estimated time remaining: `minutes_remaining' minutes `seconds_remaining' seconds"
                }
                else {
                    di as text "Drive `drive':\ cleaned (Progress: `progress'%)"
                }
                di as text "{hline 30}"
            }
        }
    }
    
    // Perform full disk cleaning (including cleanmgr)
    if "`temponly'" == "" {
        if "`quietly'" == "" {
            di as text _n "Starting full disk cleaning..."
            di as text "This may take several minutes, please wait..."
        }
        
        // Run Windows Disk Cleanup tool
        shell cleanmgr /sagerun:1
        
        if "`quietly'" == "" {
            di as text "Disk cleaning completed"
        }
    }
    
    // Display final completion message
    if "`quietly'" == "" {
        local end_time = clock(c(current_date) + " " + c(current_time), "DMY hms")
        local total_seconds = (`end_time' - `start_time') / 1000
        local minutes = floor(`total_seconds' / 60)
        local seconds = mod(`total_seconds', 60)
        
        di as result _n "{hline 50}"
        di as result "All disk cleaning operations completed"
        di as result "Total time: `minutes' minutes `seconds' seconds"
        di as result "{hline 50}"
    }
    
    // If exit option is specified, exit Stata
    if "`exit'" != "" {
        if "`quietly'" == "" {
            di as text _n "Exiting Stata..."
            sleep 2000  // Wait 2 seconds for user to see the exit message
			di as text _n "Type the  exit  command in the command window."
        }
        exit
    }
end