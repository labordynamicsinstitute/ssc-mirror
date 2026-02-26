*! rardl — Rolling-Window & Recursive ARDL Cointegration Analysis
*! Version 1.1.0 — 2026-02-23
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements:
*!   Shahbaz, Khan & Mubarak (2023) — Rolling-Window ARDL bounds testing
*!   Khan, Shahbaz & Napari (2023) — Recursive ARDL, ADF & Granger causality
*!   Pesaran, Shin & Smith (2001) — ARDL bounds testing framework
*!
*! Five analysis types:
*!   rolling   — Rolling-window ARDL bounds test with simulated CVs
*!   recursive — Recursive ARDL bounds test with simulated CVs
*!   radf      — Recursive ADF unit root test
*!   rgranger  — Recursive Granger causality test
*!   simulate  — Monte Carlo simulation for critical values

capture program drop rardl
program define rardl, rclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=1 ts) [if] [in], ///
        Type(string) ///
        [ maxlag(integer 4) ///
          ic(string) ///
          Case(integer 3) ///
          Level(integer 5) ///
          Wsize(numlist min=1 integer >10) ///
          INITobs(integer 60) ///
          nsim(integer 50000) ///
          seed(integer -1) ///
          NOSimulate ///
          TRANSform(string) ///
          ADFcase(string) ///
          graph ///
          NOTable ///
          ALLModels ///
          ALLCases ]

    // Validate type
    local type = lower("`type'")
    if !inlist("`type'", "rolling", "recursive", "radf", "rgranger", "simulate") {
        di as err "{bf:type()} must be one of: rolling, recursive, radf, rgranger, simulate"
        exit 198
    }

    // Default IC
    if "`ic'" == "" local ic "bic"

    // =========================================================================
    // 2. DISPATCH TO APPROPRIATE SUB-PROGRAM
    // =========================================================================
    if "`type'" == "rolling" {
        // Rolling-Window ARDL Bounds Test
        local nv : word count `varlist'
        if `nv' < 2 {
            di as err "rolling type requires at least 2 variables (depvar indepvar)"
            exit 198
        }
        
        local opts "maxlag(`maxlag') ic(`ic') case(`case') level(`level')"
        local opts "`opts' nsim(`nsim') seed(`seed')"
        if "`wsize'" != "" local opts "`opts' wsize(`wsize')"
        if "`nosimulate'" != "" local opts "`opts' nosimulate"
        if "`graph'" != "" local opts "`opts' graph"
        if "`notable'" != "" local opts "`opts' notable"
        if "`allmodels'" != "" local opts "`opts' allmodels"
        
        _rardl_rolling `varlist' `if' `in', `opts'
        
        // Pass through returns
        return add
    }
    else if "`type'" == "recursive" {
        // Recursive ARDL Bounds Test
        local nv : word count `varlist'
        if `nv' < 2 {
            di as err "recursive type requires at least 2 variables"
            exit 198
        }
        
        local opts "initobs(`initobs') maxlag(`maxlag') ic(`ic') case(`case') level(`level')"
        local opts "`opts' nsim(`nsim') seed(`seed')"
        if "`transform'" != "" local opts "`opts' transform(`transform')"
        if "`nosimulate'" != "" local opts "`opts' nosimulate"
        if "`graph'" != "" local opts "`opts' graph"
        if "`notable'" != "" local opts "`opts' notable"
        if "`allcases'" != "" local opts "`opts' allcases"
        
        _rardl_recursive `varlist' `if' `in', `opts'
        
        return add
    }
    else if "`type'" == "radf" {
        // Recursive ADF Unit Root Test
        local opts "initobs(`initobs') maxlag(`maxlag') ic(`ic') level(`level')"
        if "`transform'" != "" local opts "`opts' transform(`transform')"
        if "`adfcase'" != "" local opts "`opts' adfcase(`adfcase')"
        if "`graph'" != "" local opts "`opts' graph"
        if "`notable'" != "" local opts "`opts' notable"
        
        _rardl_radf `varlist' `if' `in', `opts'
        
        return add
    }
    else if "`type'" == "rgranger" {
        // Recursive Granger Causality Test
        local nv : word count `varlist'
        if `nv' != 2 {
            di as err "rgranger type requires exactly 2 variables"
            exit 198
        }
        
        local opts "initobs(`initobs') maxlag(`maxlag') ic(`ic') level(`level')"
        if "`transform'" != "" local opts "`opts' transform(`transform')"
        if "`graph'" != "" local opts "`opts' graph"
        if "`notable'" != "" local opts "`opts' notable"
        
        _rardl_rgranger `varlist' `if' `in', `opts'
        
        return add
    }
    else if "`type'" == "simulate" {
        // Monte Carlo Simulation
        local nv : word count `varlist'
        // For simulate, varlist gives number of regressors context
        // Use nregs = nv - 1 (treating first as dep)
        local nregs = max(1, `nv' - 1)
        
        local tobs_str ""
        if "`wsize'" != "" {
            local tobs_str "`wsize'"
        }
        else {
            local tobs_str "60 120 180 240 500"
        }
        
        local opts "tobs(`tobs_str') nregs(`nregs') nsim(`nsim') maxlag(`maxlag') ic(`ic')"
        if `seed' > 0 local opts "`opts' seed(`seed')"
        if "`notable'" != "" local opts "`opts' notable"
        
        _rardl_simulate, `opts'
        
        return add
    }

    // =========================================================================
    // 3. STORE ESTIMATION RESULTS
    // =========================================================================
    return local cmd "rardl"
    return local type "`type'"
    return local depvar = word("`varlist'", 1)
    return local cmdline "rardl `0'"
    return scalar maxlag = `maxlag'
    return scalar level = `level'
    return local ic "`ic'"

end
