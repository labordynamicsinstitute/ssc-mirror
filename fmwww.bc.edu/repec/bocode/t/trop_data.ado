*! trop_data — Download example datasets bundled with the trop package
*! Version 1.2.1  2026-07-03
*!
*! Usage:
*!   trop_data cps_logwage       — CPS log-wage panel (50 units × 40 periods)
*!   trop_data cps_urate         — CPS unemployment rate
*!   trop_data pwt_loggdp        — Penn World Table log-GDP
*!   trop_data basque_gdp        — Basque Country GDP (semi-synthetic, d=0)
*!   trop_data germany_gdp       — Germany GDP (semi-synthetic, d=0)
*!   trop_data smoking_packs     — Smoking packs (semi-synthetic, d=0)

program define trop_data
    version 17
    syntax anything(name=dataset)
    
    local valid "cps_logwage cps_urate pwt_loggdp basque_gdp germany_gdp smoking_packs"
    local found 0
    foreach v of local valid {
        if "`dataset'" == "`v'" {
            local found 1
        }
    }
    if `found' == 0 {
        di as error "`dataset' is not a valid dataset name."
        di as txt "Available datasets: `valid'"
        error 198
    }
    
    * Strategy 1: Check current directory
    capture confirm file "`dataset'.dta"
    if _rc == 0 {
        use "`dataset'.dta", clear
        di as txt "Dataset {bf:`dataset'} loaded from current directory."
        exit
    }
    
    * Strategy 2: Check adopath (findfile)
    capture findfile `dataset'.dta
    if _rc == 0 {
        use "`r(fn)'", clear
        di as txt "Dataset {bf:`dataset'} loaded from adopath."
        exit
    }
    
    * Strategy 3: Check data/ subdirectory relative to trop.ado
    quietly capture which trop.ado
    if _rc == 0 {
        local troppath "`r(fn)'"
        local tropdir = subinstr("`troppath'", "trop.ado", "", 1)
        local datapath "`tropdir'../data/`dataset'.dta"
        capture confirm file "`datapath'"
        if _rc == 0 {
            use "`datapath'", clear
            di as txt "Dataset {bf:`dataset'} loaded ({result:`c(N)'} obs, {result:`c(k)'} vars)."
            exit
        }
    }
    
    * Strategy 4: Download from GitHub to adopath (persistent)
    local baseurl "https://raw.githubusercontent.com/gorgeousfish/TROP/main/data"
    local firstletter = substr("`dataset'", 1, 1)
    local destdir "`c(sysdir_plus)'`firstletter'"
    capture mkdir "`destdir'"
    local destfile "`destdir'/`dataset'.dta"
    capture copy "`baseurl'/`dataset'.dta" "`destfile'", replace
    if _rc == 0 {
        use "`destfile'", clear
        di as txt "Dataset {bf:`dataset'} downloaded to adopath ({result:`c(N)'} obs, {result:`c(k)'} vars)."
        di as txt "Future calls will load instantly without internet."
        exit
    }
    
    * All strategies failed
    di as error "Cannot find `dataset'.dta"
    di as txt "Try: copy {c 34}https://raw.githubusercontent.com/gorgeousfish/TROP/main/data/`dataset'.dta{c 34} {c 34}`dataset'.dta{c 34}"
    error 601
end
