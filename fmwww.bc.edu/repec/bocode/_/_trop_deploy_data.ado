*! _trop_deploy_data — one-time data deployment after net install
*! Downloads example datasets to adopath PLUS directory for persistent caching.
*! Called silently by trop.ado on first invocation; users need not call directly.

program define _trop_deploy_data
    version 17
    
    * Check if data already deployed (use cps_logwage as sentinel)
    capture findfile cps_logwage.dta
    if _rc == 0 {
        exit  // already deployed
    }
    
    * Determine adopath PLUS directory
    local plusdir "`c(sysdir_plus)'"
    
    * Dataset list with first-letter subdirectories
    local datasets "cps_logwage cps_urate pwt_loggdp germany_gdp basque_gdp smoking_packs"
    local subdirs  "c            c         p          g           b          s"
    
    local baseurl "https://raw.githubusercontent.com/gorgeousfish/TROP/main/data"
    
    local i = 1
    foreach ds of local datasets {
        local subdir : word `i' of `subdirs'
        local destdir "`plusdir'`subdir'"
        capture mkdir "`destdir'"
        local destfile "`destdir'/`ds'.dta"
        capture confirm file "`destfile'"
        if _rc != 0 {
            quietly capture copy "`baseurl'/`ds'.dta" "`destfile'"
            if _rc != 0 {
                di as txt "Note: Could not download `ds'.dta (no internet?). Use {bf:trop_data `ds'} later."
            }
        }
        local ++i
    }
end
