*! xtpqroot v1.0.1
*! Panel Quantile Unit Root Tests
*! Author: Dr. Merwan Roudane
*! Date: March 2026
capture program drop xtpqroot
program define xtpqroot, rclass sortpreserve
    version 14.0
    syntax varname(numeric ts) [if] [in], [Quantile(numlist >0 <1) FOURier Model(string) MAXLag(integer -1) REPS(integer 1000) BOOTReps(integer 2000) NOGRaph NOTABle Level(integer 95) CDtest INDividual]

    qui xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"
    
    if "`panelvar'" == "" | "`timevar'" == "" {
        di as error "Panel and time variables must be set."
        exit 198
    }
    
    marksample touse
    sort `panelvar' `timevar'
    
    if "`model'" == "" {
        local model "intercept"
    }
    else {
        local model = lower("`model'")
        if !inlist("`model'", "intercept", "trend", "trendshift") {
            di as error "model() must be intercept, trend, or trendshift"
            exit 198
        }
    }
    
    if "`quantile'" == "" & "`fourier'" == "" {
        local quantile "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
    }
    
    if "`quantile'" != "" & "`fourier'" != "" {
        di as error "Cannot specify both quantile() and fourier options."
        exit 198
    }
    
    tempvar gid
    qui egen `gid' = group(`panelvar') if `touse'
    qui sum `gid' if `touse', meanonly
    local N = r(max)
    
    qui tab `timevar' if `touse'
    local T = r(r)
    
    if `N' < 3 {
        di as error "At least 3 panels are required."
        exit 2001
    }
    if `T' < 15 {
        di as error "Insufficient time periods. Need at least 15, have `T'."
        exit 2001
    }
    
    qui count if `touse'
    local NTobs = r(N)
    
    local expected_obs = `N' * `T'
    if `NTobs' != `expected_obs' {
        di as error "Panel must be strongly balanced."
        exit 198
    }
    
    if `maxlag' == -1 {
        local maxlag = floor(4 * (`T'/100)^(1/4))
        if `maxlag' < 1 local maxlag = 1
    }
    
    if "`quantile'" != "" {
        * Force-drop old cached programs and Mata functions
        capture program drop _xtpqroot_cips
        capture program drop _xtpqroot_cips_display
        capture program drop _xtpqroot_cips_graph
        capture program drop _xtpqroot_display_row
        capture mata: mata drop _xtpqroot_cips_mata()
        capture mata: mata drop _xtpqroot_cadf_mata()
        capture mata: mata drop _xtpqroot_cadf_tau_real()
        capture mata: mata drop _xtpqroot_simulate_pvalues()
        capture mata: mata drop _xtpqroot_qreg()
        capture mata: mata drop _xtpqroot_cd_test()
        capture mata: mata drop _xtpqroot_cd_qreg_panel()
        capture mata: mata drop _xtpqroot_rho_graph()
        
        capture findfile _xtpqroot_cips.ado
        if _rc {
            di as error "Required file _xtpqroot_cips.ado not found."
            exit 601
        }
        local _cips_path "`r(fn)'"
        di as text "  [loading: `_cips_path']"
        qui run "`_cips_path'"
        
        _xtpqroot_cips `varlist' if `touse', panelvar(`panelvar') timevar(`timevar') quantile(`quantile') model(`model') maxlag(`maxlag') reps(`reps') level(`level') n(`N') t(`T') ntobs(`NTobs') `nograph' `notable' `cdtest' `individual'
        
        return add
    }
    else if "`fourier'" != "" {
        * Force-drop old cached programs and Mata functions
        capture program drop _xtpqroot_fourier
        capture program drop _xtpqroot_sieve_boot
        capture mata: mata drop _xtpqroot_sieve_boot_mata()
        capture mata: mata drop _xtpqroot_fourier_est_mata()
        
        capture findfile _xtpqroot_fourier.ado
        if _rc {
            di as error "Required file _xtpqroot_fourier.ado not found."
            exit 601
        }
        local _fourier_path "`r(fn)'"
        di as text "  [loading: `_fourier_path']"
        qui run "`_fourier_path'"
        
        _xtpqroot_fourier `varlist' if `touse', panelvar(`panelvar') timevar(`timevar') model(`model') maxlag(`maxlag') bootreps(`bootreps') level(`level') n(`N') t(`T') ntobs(`NTobs') `nograph' `notable'
        
        return add
    }
    
    return local cmd        "xtpqroot"
    return local varname    "`varlist'"
    return local panelvar   "`panelvar'"
    return local timevar    "`timevar'"
    return local model      "`model'"
    return scalar N_panels  = `N'
    return scalar T_periods = `T'
    
end