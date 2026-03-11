*! xtpcaus v1.0.0
*! Panel Causality Tests: PFTY and Panel Quantile Causality
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! References:
*!  Yilanci & Gorus (2020) "Panel Fourier Toda-Yamamoto Causality"
*!  Emirmahmutoglu & Kose (2011) "Testing for Granger causality in heterogeneous mixed panels"
*!  Toda & Yamamoto (1995) J.Econometrics 66:225-250
*!  Nazlioglu, Gormus, Soytas (2016) Energy Economics 60:168-175
*!  Dumitrescu & Hurlin (2012) Economic Modelling 29:1450-1460
*!  Chuang, Kuan, Lin (2009) J.Banking & Finance 33:1351-1360
*!  Wang & Nguyen (2022) Economic Research 35:873-893
*!  Koenker & Machado (1999) J.American Statistical Association 94:1296-1310

capture program drop xtpcaus
program define xtpcaus, eclass sortpreserve
    version 14.0
    
    // ── Parse syntax ──────────────────────────────────────────────
    syntax varlist(min=2 max=2 numeric ts) [if] [in], ///
        TEST(string)                    ///
        [ LAGs(integer 1)               ///
          DMAX(integer 1)               ///
          NBOOT(integer 1000)           ///
          KMAX(integer 3)               ///
          IC(string)                    ///
          Quantiles(numlist >0 <1)      ///
          SEED(integer -1)              ///
          NOGRaph                       ///
          NOTABle                       ///
          Level(integer 95)             ///
          PMAX(integer 4)               ///
          SCHeme(string)                ///
        ]
    
    // ── Validate test() ───────────────────────────────────────────
    local test = lower("`test'")
    if !inlist("`test'", "pfty", "pqc") {
        di as error "test() must be {bf:pfty} (Panel Fourier Toda-Yamamoto) or {bf:pqc} (Panel Quantile Causality)."
        exit 198
    }
    
    // ── Validate panel setup ──────────────────────────────────────
    qui xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"
    
    if "`panelvar'" == "" | "`timevar'" == "" {
        di as error "Panel and time variables must be set. Use {bf:xtset} before running xtpcaus."
        exit 459
    }
    
    // ── Mark sample ───────────────────────────────────────────────
    marksample touse, novarlist
    
    // ── Separate variables ────────────────────────────────────────
    tokenize `varlist'
    local depvar   `1'
    local indepvar `2'
    
    sort `panelvar' `timevar'
    
    // ── Panel dimensions ──────────────────────────────────────────
    qui tab `panelvar' if `touse'
    local N = r(r)
    qui tab `timevar' if `touse'
    local T = r(r)
    qui sum `timevar' if `touse'
    local tmin = r(min)
    local tmax = r(max)
    
    // ── Check balanced panel ──────────────────────────────────────
    if `=`tmax'-(`tmin'-1)' > `T' {
        di as error "Panel must be strongly balanced and without gaps."
        exit 459
    }
    qui count if `touse' & mi(`depvar', `indepvar')
    if r(N) > 0 {
        di as error "Panel must be strongly balanced (no missing values in {bf:`depvar'} and {bf:`indepvar'})."
        exit 459
    }
    
    // ── Minimum dimensions ────────────────────────────────────────
    if `N' < 2 {
        di as error "At least 2 panels required."
        exit 2001
    }
    if `T' < 10 {
        di as error "At least 10 time periods required."
        exit 2001
    }
    
    // ── Defaults ──────────────────────────────────────────────────
    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "sbc", "bic") {
        di as error "ic() must be aic or sbc."
        exit 198
    }
    if "`ic'" == "bic" local ic "sbc"
    
    if "`scheme'" == "" local scheme "s1color"
    
    if "`quantiles'" == "" & "`test'" == "pqc" {
        local quantiles "0.05 0.10 0.25 0.50 0.75 0.90 0.95"
    }
    
    if `nboot' < 99 {
        di as error "nboot() must be at least 99."
        exit 198
    }
    
    if `seed' >= 0 {
        set seed `seed'
    }
    
    // ── Dispatch to subcommand ────────────────────────────────────
    if "`test'" == "pfty" {
        // Force-drop cached programs
        capture program drop _xtpcaus_pfty
        capture mata: mata drop _xtpcaus_pfty_mata()
        capture mata: mata drop _xtpcaus_pfty_boot()
        capture mata: mata drop _xtpcaus_pfty_wald()
        capture mata: mata drop _xtpcaus_pfty_select()
        capture mata: mata drop _xtpcaus_pfty_graph()
        
        capture findfile _xtpcaus_pfty.ado
        if _rc {
            di as error "Required file {bf:_xtpcaus_pfty.ado} not found. Ensure it is installed."
            exit 601
        }
        local _pfty_path "`r(fn)'"
        qui run "`_pfty_path'"
        
        _xtpcaus_pfty `depvar' `indepvar' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') ///
            pmax(`pmax') dmax(`dmax') kmax(`kmax') ///
            ic(`ic') nboot(`nboot') ///
            npanels(`N') tperiods(`T') tmin(`tmin') tmax(`tmax') ///
            level(`level') scheme(`scheme') ///
            `nograph' `notable'
    }
    else if "`test'" == "pqc" {
        // Force-drop cached programs
        capture program drop _xtpcaus_pqc
        capture mata: mata drop _xtpcaus_pqc_wald()
        capture mata: mata drop _xtpcaus_pqc_boot()
        
        capture findfile _xtpcaus_pqc.ado
        if _rc {
            di as error "Required file {bf:_xtpcaus_pqc.ado} not found. Ensure it is installed."
            exit 601
        }
        local _pqc_path "`r(fn)'"
        qui run "`_pqc_path'"
        
        _xtpcaus_pqc `depvar' `indepvar' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') ///
            pmax(`pmax') dmax(`dmax') ///
            nboot(`nboot') quantiles(`quantiles') ///
            npanels(`N') tperiods(`T') tmin(`tmin') tmax(`tmax') ///
            level(`level') scheme(`scheme') ///
            `nograph' `notable'
    }
    
    // ── Store common returns ──────────────────────────────────────
    ereturn local  cmd        "xtpcaus"
    ereturn local  test       "`test'"
    ereturn local  depvar     "`depvar'"
    ereturn local  indepvar   "`indepvar'"
    ereturn local  panelvar   "`panelvar'"
    ereturn local  timevar    "`timevar'"
    ereturn scalar N_panels   = `N'
    ereturn scalar T_periods  = `T'
    ereturn scalar nboot      = `nboot'
    
end
