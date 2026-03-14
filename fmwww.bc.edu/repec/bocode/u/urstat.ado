*! version 1.3.0  11mar2026  Dr. Merwan Roudane
*! URSTAT: Comprehensive Unified Unit Root & Stationarity Testing
*! Supports: ADF, PP, KPSS, ZA, CLEMAO1, CLEMAO2, CLEMIO1, CLEMIO2, ERS, BSRW, KM
*! With Elder-Kennedy (2001) Decision Strategy

capture program drop urstat
capture program drop _urs_adf_lag
capture program drop _urs_star
capture program drop _urs_kpss_star
capture program drop _urs_center
capture program drop _urs_za_date
capture program drop _urs_za_sig
capture program drop _urs_table1
capture program drop _urs_table2
capture program drop _urs_table3
capture program drop _urs_table4
capture program drop _urs_table5
capture program drop _urs_table6
capture program drop _urs_graphs

program define urstat, rclass
    version 14.0
    syntax varlist(ts) [if] [in], [ ///
        TEST(string) NONe ///
        MAXlag(integer 12) CRIT(string) PPLAG(integer 4) ///
        ZTRIM(real 0.15) CLEMtrim(real 0.05) CLEMmaxlag(integer 12) ///
        BSReps(integer 500) ///
        KMLags(integer 0) NODrift ///
        STRAtegy LEVEL(cilevel) ///
        TITLE(string) NOSTARs ///
        ERSMETHOD(string) ///
        GRAPH GRAPHDir(string) ///
        ]
    
    marksample touse
    if "`test'" == "" local test "ALL"
    local test = upper("`test'")
    if "`crit'" == "" local crit "BIC"
    local crit = upper("`crit'")
    if "`crit'" == "SIC" local crit "BIC"
    local stars = ("`nostars'" == "")
    
    * Parse tests
    local do_adf  = 0
    local do_pp   = 0
    local do_kpss = 0
    local do_za   = 0
    local do_clem = 0
    local do_ers  = 0
    local do_bsrw = 0
    local do_km   = 0
    
    if "`test'" == "ALL" {
        local do_adf = 1
        local do_pp  = 1
        local do_kpss = 1
        local do_za  = 1
        local do_clem = 1
        local do_ers = 1
        local do_bsrw = 1
        local do_km  = 1
    }
    else {
        foreach t of local test {
            if "`t'" == "ADF"  local do_adf = 1
            if "`t'" == "PP"   local do_pp  = 1
            if "`t'" == "KPSS" local do_kpss = 1
            if "`t'" == "ZA"   local do_za  = 1
            if inlist("`t'","CLEMAO1","CLEMAO2","CLEMIO1","CLEMIO2","CLEM") local do_clem = 1
            if inlist("`t'","ERS","DFGLS","RES") local do_ers = 1
            if "`t'" == "BSRW" local do_bsrw = 1
            if "`t'" == "KM"   local do_km  = 1
        }
    }
    
    if `do_adf' | `do_pp' | `do_kpss' {
        _urs_table1 `varlist' if `touse', ///
            do_adf(`do_adf') do_pp(`do_pp') do_kpss(`do_kpss') ///
            maxlag(`maxlag') crit(`crit') pplag(`pplag') ///
            `none' stars(`stars') title("`title'")
    }
    if `do_za' | `do_clem' {
        _urs_table2 `varlist' if `touse', ///
            do_za(`do_za') do_clem(`do_clem') ///
            ztrim(`ztrim') clemtrim(`clemtrim') clemmaxlag(`clemmaxlag') stars(`stars')
    }
    if `do_ers' | `do_bsrw' {
        _urs_table3 `varlist' if `touse', ///
            do_ers(`do_ers') do_bsrw(`do_bsrw') ///
            maxlag(`maxlag') bsreps(`bsreps') ersmethod("`ersmethod'") crit(`crit') stars(`stars')
    }
    if `do_km' {
        _urs_table4 `varlist' if `touse', kmlags(`kmlags') `nodrift' stars(`stars')
    }
    if "`strategy'" != "" | "`test'" == "ALL" {
        _urs_table5 `varlist' if `touse', maxlag(`maxlag') crit(`crit') pplag(`pplag') stars(`stars') ersmethod("`ersmethod'") ztrim(`ztrim')
        _urs_table6 `varlist' if `touse', maxlag(`maxlag') crit(`crit') pplag(`pplag') stars(`stars') ersmethod("`ersmethod'") ztrim(`ztrim') bsreps(`bsreps') clemtrim(`clemtrim') clemmaxlag(`clemmaxlag')
    }
    * Graphs
    if "`graph'" != "" {
        _urs_graphs `varlist' if `touse', ///
            do_za(`do_za') ztrim(`ztrim') ///
            maxlag(`maxlag') crit(`crit') pplag(`pplag') ///
            stars(`stars') graphdir("`graphdir'")
    }
end

* ==============================================================================
*  ADF LAG SELECTION
* ==============================================================================
program define _urs_adf_lag, rclass
    syntax varname(ts) [if], MAXlag(integer) DET(string) CRIT(string)
    marksample touse
    tempvar dy ly tr
    qui gen double `dy' = D.`varlist' if `touse'
    qui gen double `ly' = L.`varlist' if `touse'
    if "`det'" == "ct" qui gen double `tr' = _n if `touse'
    local bestlag = 0
    local bestic  = .
    forvalues L = 0/`maxlag' {
        local dlist ""
        if `L' > 0 local dlist "L(1/`L').D.`varlist'"
        if "`det'" == "nc"     capture qui regress `dy' `ly' `dlist' if `touse', noconstant
        else if "`det'" == "c" capture qui regress `dy' `ly' `dlist' if `touse'
        else                   capture qui regress `dy' `ly' `tr' `dlist' if `touse'
        if _rc continue
        scalar __N = e(N)
        scalar __rss = e(rss)
        scalar __k = e(rank)
        scalar __aic = __N*ln(__rss/__N) + 2*__k
        scalar __bic = __N*ln(__rss/__N) + ln(__N)*__k
        local cur = cond("`crit'" == "AIC", __aic, __bic)
        if missing(`bestic') | (`cur' < `bestic') {
            local bestic  = `cur'
            local bestlag = `L'
        }
    }
    return scalar lag = `bestlag'
end

* ==============================================================================
*  STAR HELPERS
* ==============================================================================
program define _urs_star, sclass
    args pval
    if missing(`pval')       sreturn local s ""
    else if `pval' < 0.01    sreturn local s "***"
    else if `pval' < 0.05    sreturn local s "**"
    else if `pval' < 0.10    sreturn local s "*"
    else                     sreturn local s ""
end

program define _urs_kpss_star, sclass
    args stat det
    if "`det'" == "c" {
        if `stat' > 0.739       sreturn local s "***"
        else if `stat' > 0.463  sreturn local s "**"
        else if `stat' > 0.347  sreturn local s "*"
        else                    sreturn local s ""
    }
    else {
        if `stat' > 0.216       sreturn local s "***"
        else if `stat' > 0.146  sreturn local s "**"
        else if `stat' > 0.119  sreturn local s "*"
        else                    sreturn local s ""
    }
end

program define _urs_center
    syntax , TEXT(string) WIDTH(integer)
    local len = udstrlen("`text'")
    if `len' >= `width' {
        di "`text'" _continue
    }
    else {
        local lpad = int((`width' - `len')/2)
        di _skip(`lpad') "`text'" _continue
    }
end

* ==============================================================================
*  TABLE 1: ADF / PP / KPSS  (Level + 1st Diff + 2nd Diff)
* ==============================================================================
program define _urs_table1
    syntax varlist(ts) [if], do_adf(integer) do_pp(integer) do_kpss(integer) ///
        MAXlag(integer) CRIT(string) PPLAG(integer) ///
        [NONe STARs(integer 1) TITLE(string)]
    
    marksample touse
    local nvars : word count `varlist'
    local has_none = ("`none'" != "")
    
    * Columns per block: with none = 3 (nc, c, ct); without = 2 (c, ct)
    local cpb = cond(`has_none', 3, 2)
    local nblocks = 3  // Level, 1st Diff, 2nd Diff
    local ncols = `cpb' * `nblocks'
    
    local vw = 14
    local cw = 14
    local totw = `vw' + `ncols'*`cw' + 4
    
    local ttl "`title'"
    if "`ttl'" == "" {
        local ttl "Table 1. Unit Root Tests"
        local parts ""
        if `do_adf'  local parts "ADF"
        if `do_pp'   local parts "`parts' / PP"
        if `do_kpss' local parts "`parts' / KPSS"
        local ttl "`ttl': `parts'"
    }
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  `ttl'"
    di as txt "{hline `totw'}"
    
    * --- Block headers ---
    di as txt _col(1) "" _col(`=`vw'+1') "{c |}" _continue
    local bstart = `vw' + 2
    forvalues b = 1/3 {
        local bw = `cpb'*`cw'
        local bmid = `bstart' + int(`bw'/2)
        if `b' == 1      di _col(`bmid') "Level" _continue
        else if `b' == 2 di _col(`bmid') "1st Difference" _continue
        else             di _col(`bmid') "2nd Difference" _continue
        local bstart = `bstart' + `bw'
        if `b' < 3 di "{c |}" _continue
    }
    di ""
    
    * --- Sub-column headers ---
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    forvalues b = 1/3 {
        if `has_none' {
            di _col(`pos') %~`cw's "None" _continue
            local pos = `pos' + `cw'
        }
        di _col(`pos') %~`cw's "Const" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "Const+Trend" _continue
        local pos = `pos' + `cw'
        if `b' < 3 di "{c |}" _continue
    }
    di ""
    di as txt "{hline `totw'}"
    
    * ======= PANEL A: ADF =======
    if `do_adf' {
        local panlbl = cond(`do_pp' | `do_kpss', "Panel A: ADF Test", "ADF Test")
        local mid = int(`totw'/2) - 5
        di as res _col(`mid') "`panlbl'"
        di as txt "{hline `totw'}"
        
        foreach v of local varlist {
            * Build specs list
            local specs "c ct"
            if `has_none' local specs "nc c ct"
            
            * Matrices to store results
            tempname STAT PVAL
            matrix `STAT' = J(1, `ncols', .)
            matrix `PVAL' = J(1, `ncols', .)
            
            * Fill: block 1=Level, block 2=d., block 3=d2.
            local col = 0
            forvalues b = 1/3 {
                foreach sp of local specs {
                    local ++col
                    if `b' == 1      local tv "`v'"
                    else if `b' == 2 local tv "D.`v'"
                    else             local tv "D2.`v'"
                    
                    capture qui _urs_adf_lag `tv' if `touse', maxlag(`maxlag') det(`sp') crit(`crit')
                    local lg = cond(_rc, 0, r(lag))
                    
                    if "`sp'" == "nc" {
                        capture qui dfuller `tv' if `touse', lags(`lg') noconstant
                    }
                    else if "`sp'" == "c" {
                        capture qui dfuller `tv' if `touse', lags(`lg')
                    }
                    else {
                        capture qui dfuller `tv' if `touse', lags(`lg') trend
                    }
                    if !_rc {
                        matrix `STAT'[1, `col'] = r(Zt)
                        matrix `PVAL'[1, `col'] = r(p)
                    }
                }
            }
            
            * Print stat row
            local vname = substr("`v'", 1, `=`vw'-2')
            di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
            local pos = `vw' + 2
            forvalues c = 1/`ncols' {
                if `c' == `=`cpb'+1' | `c' == `=2*`cpb'+1' {
                    di _col(`=`pos'-1') "{c |}" _continue
                }
                scalar _sv = `STAT'[1,`c']
                if missing(_sv) {
                    di _col(`pos') %~`cw's "---" _continue
                }
                else {
                    local stxt : display %9.4f _sv
                    if `stars' {
                        scalar _pv = `PVAL'[1,`c']
                        _urs_star _pv
                        local stxt = trim("`stxt'") + "`s(s)'"
                    }
                    di _col(`pos') %~`cw's "`stxt'" _continue
                }
                local pos = `pos' + `cw'
            }
            di ""
            
            * Print p-value row
            di as txt _col(`=`vw'+1') "{c |}" _continue
            local pos = `vw' + 2
            forvalues c = 1/`ncols' {
                if `c' == `=`cpb'+1' | `c' == `=2*`cpb'+1' {
                    di _col(`=`pos'-1') "{c |}" _continue
                }
                scalar _pv = `PVAL'[1,`c']
                if missing(_pv) {
                    di _col(`pos') %~`cw's "" _continue
                }
                else {
                    local ptxt : display %6.4f _pv
                    local ptxt "(`ptxt')"
                    di _col(`pos') %~`cw's "`ptxt'" _continue
                }
                local pos = `pos' + `cw'
            }
            di ""
        }
        di as txt "{hline `totw'}"
    }
    
    * ======= PANEL B: PP =======
    if `do_pp' {
        local panlbl = cond(`do_adf' | `do_kpss', "Panel B: PP Test", "PP Test")
        local mid = int(`totw'/2) - 5
        di as res _col(`mid') "`panlbl'"
        di as txt "{hline `totw'}"
        
        foreach v of local varlist {
            tempname STAT PVAL
            matrix `STAT' = J(1, `ncols', .)
            matrix `PVAL' = J(1, `ncols', .)
            
            local col = 0
            forvalues b = 1/3 {
                if `has_none' {
                    local ++col
                    * PP has no noconstant option
                }
                * Const
                local ++col
                if `b' == 1      local tv "`v'"
                else if `b' == 2 local tv "D.`v'"
                else             local tv "D2.`v'"
                capture qui pperron `tv' if `touse', lags(`pplag')
                if !_rc {
                    matrix `STAT'[1,`col'] = r(Zt)
                    matrix `PVAL'[1,`col'] = r(p)
                }
                * Const+Trend
                local ++col
                capture qui pperron `tv' if `touse', lags(`pplag') trend
                if !_rc {
                    matrix `STAT'[1,`col'] = r(Zt)
                    matrix `PVAL'[1,`col'] = r(p)
                }
            }
            
            local vname = substr("`v'", 1, `=`vw'-2')
            di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
            local pos = `vw' + 2
            forvalues c = 1/`ncols' {
                if `c' == `=`cpb'+1' | `c' == `=2*`cpb'+1' {
                    di _col(`=`pos'-1') "{c |}" _continue
                }
                scalar _sv = `STAT'[1,`c']
                if missing(_sv) {
                    di _col(`pos') %~`cw's "---" _continue
                }
                else {
                    local stxt : display %9.4f _sv
                    if `stars' {
                        scalar _pv = `PVAL'[1,`c']
                        _urs_star _pv
                        local stxt = trim("`stxt'") + "`s(s)'"
                    }
                    di _col(`pos') %~`cw's "`stxt'" _continue
                }
                local pos = `pos' + `cw'
            }
            di ""
            
            di as txt _col(`=`vw'+1') "{c |}" _continue
            local pos = `vw' + 2
            forvalues c = 1/`ncols' {
                if `c' == `=`cpb'+1' | `c' == `=2*`cpb'+1' {
                    di _col(`=`pos'-1') "{c |}" _continue
                }
                scalar _pv = `PVAL'[1,`c']
                if missing(_pv) {
                    di _col(`pos') %~`cw's "" _continue
                }
                else {
                    local ptxt : display %6.4f _pv
                    di _col(`pos') %~`cw's "(`ptxt')" _continue
                }
                local pos = `pos' + `cw'
            }
            di ""
        }
        di as txt "{hline `totw'}"
    }
    
    * ======= PANEL C: KPSS =======
    if `do_kpss' {
        capture which kpss
        if _rc {
            di as err "  Warning: {bf:kpss} not installed. Run: {stata ssc install kpss}"
        }
        else {
            local panlbl = cond(`do_adf' | `do_pp', "Panel C: KPSS Test", "KPSS Test")
            local mid = int(`totw'/2) - 5
            di as res _col(`mid') "`panlbl'"
            di as txt "{hline `totw'}"
            
            foreach v of local varlist {
                tempname STAT
                matrix `STAT' = J(1, `ncols', .)
                local stars_line ""
                
                local col = 0
                forvalues b = 1/3 {
                    if `has_none' {
                        local ++col
                        local stars_line "`stars_line' ."
                    }
                    foreach sp in "c" "ct" {
                        local ++col
                        if `b' == 1      local tv "`v'"
                        else if `b' == 2 local tv "D.`v'"
                        else             local tv "D2.`v'"
                        
                        tempvar kv
                        capture qui gen double `kv' = `tv' if `touse'
                        if !_rc {
                            if "`sp'" == "c" {
                                capture qui kpss `kv' if `touse', notrend auto
                            }
                            else {
                                capture qui kpss `kv' if `touse', auto
                            }
                            if !_rc {
                                * kpss returns r(kpss0) for base, r(kpssN) for lag N
                                * with auto, maxlag is computed; use r(kpss<maxlag>) if available
                                local _kval = .
                                capture local _kval = r(kpss`=r(maxlag)')
                                if missing(`_kval') {
                                    capture local _kval = r(kpss0)
                                }
                                if !missing(`_kval') {
                                    matrix `STAT'[1,`col'] = `_kval'
                                    _urs_kpss_star `_kval' `sp'
                                    local stars_line "`stars_line' `s(s)'"
                                }
                                else {
                                    local stars_line "`stars_line' ."
                                }
                            }
                            else {
                                local stars_line "`stars_line' ."
                            }
                        }
                        else {
                            local stars_line "`stars_line' ."
                        }
                        capture drop `kv'
                    }
                }
                
                local vname = substr("`v'", 1, `=`vw'-2')
                di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
                local pos = `vw' + 2
                forvalues c = 1/`ncols' {
                    if `c' == `=`cpb'+1' | `c' == `=2*`cpb'+1' {
                        di _col(`=`pos'-1') "{c |}" _continue
                    }
                    scalar _sv = `STAT'[1,`c']
                    if missing(_sv) {
                        di _col(`pos') %~`cw's "---" _continue
                    }
                    else {
                        local stxt : display %9.4f _sv
                        if `stars' {
                            local st : word `c' of `stars_line'
                            if "`st'" != "." local stxt = trim("`stxt'") + "`st'"
                        }
                        di _col(`pos') %~`cw's "`stxt'" _continue
                    }
                    local pos = `pos' + `cw'
                }
                di ""
            }
            di as txt "{hline `totw'}"
        }
    }
    
    * --- Footnotes ---
    di as txt "Notes:"
    if `do_adf' | `do_pp' di as txt "  ADF/PP: Null = unit root. p-values in parentheses (MacKinnon, 1996)."
    if `do_kpss' {
        di as txt "  KPSS: Null = stationarity. Compare statistic to critical values."
        di as txt "  KPSS c.v.: Const(1%=0.739, 5%=0.463, 10%=0.347); C+T(1%=0.216, 5%=0.146, 10%=0.119)."
    }
    if `stars' di as txt "  ***, **, * denote significance at 1%, 5%, 10% levels."
    di as txt "  Lag selection: `crit' (maxlag=`maxlag'). PP bandwidth: `pplag'."
    if `has_none' di as txt "  None = no constant, no trend. PP/KPSS do not support None (---)."
    di ""
end

* ==============================================================================
*  TABLE 2: STRUCTURAL BREAK TESTS
* ==============================================================================
program define _urs_table2
    syntax varlist(ts) [if], do_za(integer) do_clem(integer) ///
        ZTRIM(real) CLEMtrim(real) CLEMmaxlag(integer) [STARs(integer 1)]
    
    marksample touse
    qui tsset
    local timevar "`r(timevar)'"
    local timefmt "`r(tsfmt)'"
    if "`timefmt'" == "" local timefmt "%9.0g"
    
    local vw = 14
    local cw = 20
    local ncols = 0
    if `do_za'   local ncols = `ncols' + 2
    if `do_clem' local ncols = `ncols' + 4
    local totw = `vw' + 2 + `ncols'*`cw'
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  Table 2. Structural Break Unit Root Tests"
    di as txt "{hline `totw'}"
    
    * Headers
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    if `do_za' {
        di _col(`pos') %~`cw's "ZA(Intercept)" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "ZA(Both)" _continue
        local pos = `pos' + `cw'
    }
    if `do_clem' {
        di _col(`pos') %~`cw's "ClemAO1" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "ClemAO2" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "ClemIO1" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "ClemIO2" _continue
    }
    di ""
    di as txt "{hline `totw'}"
    
    * Check ZA
    local za_ok = 0
    if `do_za' {
        capture which zandrews
        if _rc {
            di as err "  Warning: {bf:zandrews} not installed. Run: {stata ssc install zandrews}"
        }
        else local za_ok = 1
    }
    
    foreach v of local varlist {
        foreach form in "L" "D" "D2" {
            if "`form'" == "L" {
                local tv "`v'"
                local prefix "L."
            }
            else if "`form'" == "D" {
                local tv "D.`v'"
                local prefix "d."
            }
            else {
                local tv "D2.`v'"
                local prefix "d2."
            }
            
            local vname = substr("`prefix'`v'", 1, `=`vw'-2')
            di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
            local pos = `vw' + 2
            
            * ZA
            if `do_za' {
                foreach brk in "intercept" "both" {
                    if `za_ok' {
                        capture qui zandrews `tv' if `touse', break(`brk') trim(`ztrim')
                        if _rc {
                            di _col(`pos') %~`cw's "N/A" _continue
                        }
                        else {
                            * Save r() IMMEDIATELY — rclass helpers wipe them
                            local _za_tmin = r(tmin)
                            local _za_obs  = r(tminobs)
                            local zs : display %8.3f `_za_tmin'
                            local mdl = cond("`brk'"=="intercept","A","C")
                            _urs_za_sig `_za_tmin' `mdl'
                            if `stars' local zs = trim("`zs'") + "`r(sig_star)'"
                            _urs_za_date `_za_obs' "`timevar'" "`timefmt'"
                            local zs "`zs' [`r(date_str)']"
                            di _col(`pos') %~`cw's "`zs'" _continue
                        }
                    }
                    else {
                        di _col(`pos') %~`cw's "N/A" _continue
                    }
                    local pos = `pos' + `cw'
                }
            }
            
            * Clemente
            if `do_clem' {
                foreach cmd in "clemao1" "clemao2" "clemio1" "clemio2" {
                    capture which `cmd'
                    if _rc {
                        di _col(`pos') %~`cw's "N/A" _continue
                        local pos = `pos' + `cw'
                        continue
                    }
                    capture qui `cmd' `tv' if `touse', maxlag(`clemmaxlag') trim(`clemtrim')
                    if _rc {
                        di _col(`pos') %~`cw's "N/A" _continue
                    }
                    else {
                        local cs : display %8.3f r(tst)
                        if "`cmd'" == "clemao1"      local cv5 = -3.560
                        else if "`cmd'" == "clemio1" local cv5 = -4.270
                        else                         local cv5 = -5.490
                        if `stars' & r(tst) < `cv5' local cs = trim("`cs'") + "**"
                        local bd : display `timefmt' r(Tb1)
                        local bd = trim("`bd'")
                        if inlist("`cmd'","clemao2","clemio2") {
                            local bd2 : display `timefmt' r(Tb2)
                            local bd "`bd',`=trim("`bd2'")'"
                        }
                        local cs "`cs' [`bd']"
                        di _col(`pos') %~`cw's "`cs'" _continue
                    }
                    local pos = `pos' + `cw'
                }
            }
            di ""
        }
        di ""
    }
    
    di as txt "{hline `totw'}"
    di as txt "Notes: Break dates in brackets."
    if `do_za'   di as txt "  ZA c.v.(5%): Intercept=-4.80, Both=-5.08 (Zivot & Andrews, 1992)."
    if `do_clem' di as txt "  Clem c.v.(5%): AO1=-3.56, IO1=-4.27, AO2/IO2=-5.49 (Perron-Vogelsang, 1992)."
    if `stars'   di as txt "  **, *** denote significance at 5%, 1% levels."
    di ""
end

* ==============================================================================
*  TABLE 3: ADVANCED TESTS (ERS + BOOTSTRAP)
* ==============================================================================
program define _urs_table3
    syntax varlist(ts) [if], do_ers(integer) do_bsrw(integer) ///
        MAXlag(integer) BSReps(integer) ///
        [ERSMETHOD(string) CRIT(string) STARs(integer 1)]
    
    marksample touse
    local vw = 14
    local cw = 14
    local ncols = 0
    if `do_ers'  local ncols = `ncols' + 6
    if `do_bsrw' local ncols = `ncols' + 3
    local totw = `vw' + 2 + `ncols'*`cw'
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  Table 3. Advanced Unit Root Tests"
    di as txt "{hline `totw'}"
    
    * Block headers
    di as txt _col(1) "" _col(`=`vw'+1') "{c |}" _continue
    local bstart = `vw' + 2
    if `do_ers' {
        forvalues b = 1/3 {
            local bw = 2*`cw'
            local bmid = `bstart' + int(`bw'/2) - 4
            if `b' == 1      di _col(`bmid') "Level" _continue
            else if `b' == 2 di _col(`bmid') "1st Difference" _continue
            else             di _col(`bmid') "2nd Difference" _continue
            local bstart = `bstart' + `bw'
            if `b' < 3 | `do_bsrw' di "{c |}" _continue
        }
    }
    if `do_bsrw' {
        local bw = 3*`cw'
        local bmid = `bstart' + int(`bw'/2) - 5
        di _col(`bmid') "Bootstrap RW" _continue
    }
    di ""
    
    * Sub-column headers
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    if `do_ers' {
        foreach h in "ERS(C)" "ERS(C+T)" "ERS(C)" "ERS(C+T)" "ERS(C)" "ERS(C+T)" {
            di _col(`pos') %~`cw's "`h'" _continue
            local pos = `pos' + `cw'
        }
    }
    if `do_bsrw' {
        foreach h in "Level" "1st Diff" "2nd Diff" {
            di _col(`pos') %~`cw's "`h'" _continue
            local pos = `pos' + `cw'
        }
    }
    di ""
    di as txt "{hline `totw'}"
    
    local ers_ok = 0
    if `do_ers' {
        capture which ersur
        if _rc di as err "  Warning: {bf:ersur} not installed. Run: {stata ssc install ersur}"
        else local ers_ok = 1
    }
    local bsrw_ok = 0
    if `do_bsrw' {
        capture which bsrwalkdrift
        if _rc di as err "  Warning: {bf:bsrwalkdrift} not installed."
        else local bsrw_ok = 1
    }
    
    local ersm = upper("`ersmethod'")
    if "`ersm'" == "" local ersm "SIC"
    local ridx = 3
    if "`ersm'" == "FIX"   local ridx = 1
    if "`ersm'" == "AIC"   local ridx = 2
    if "`ersm'" == "GTS05" local ridx = 4
    if "`ersm'" == "GTS10" local ridx = 5
    
    foreach v of local varlist {
        local vname = substr("`v'", 1, `=`vw'-2')
        di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
        local pos = `vw' + 2
        
        if `do_ers' {
            if `ers_ok' {
                tempname R
                foreach pair in "`v' " "`v' trend" "D.`v' " "D.`v' trend" "D2.`v' " "D2.`v' trend" {
                    local tvar : word 1 of `pair'
                    local topt : word 2 of `pair'
                    capture qui ersur `tvar' if `touse', noprint maxlag(`maxlag') `topt'
                    if _rc {
                        di _col(`pos') %~`cw's "N/A" _continue
                    }
                    else {
                        matrix `R' = r(results)
                        local es : display %9.4f `R'[`ridx',2]
                        local ep = `R'[`ridx',3]
                        if `stars' & !missing(`ep') {
                            _urs_star `ep'
                            local es = trim("`es'") + "`s(s)'"
                        }
                        di _col(`pos') %~`cw's "`es'" _continue
                    }
                    local pos = `pos' + `cw'
                }
            }
            else {
                forvalues i = 1/6 {
                    di _col(`pos') %~`cw's "N/A" _continue
                    local pos = `pos' + `cw'
                }
            }
        }
        
        if `do_bsrw' {
            if `bsrw_ok' {
                foreach btv in "`v'" "D.`v'" "D2.`v'" {
                    tempvar bv
                    capture qui gen double `bv' = `btv' if `touse'
                    if !_rc {
                        capture qui bsrwalkdrift `bv' if `touse', bsreps(`bsreps') nodots
                        if !_rc {
                            local bst : display %9.4f r(Zt)
                            if `stars' {
                                local bsp = r(pval)
                                if !missing(`bsp') {
                                    _urs_star `bsp'
                                    local bst = trim("`bst'") + "`s(s)'"
                                }
                            }
                            di _col(`pos') %~`cw's "`bst'" _continue
                        }
                        else {
                            di _col(`pos') %~`cw's "N/A" _continue
                        }
                    }
                    else {
                        di _col(`pos') %~`cw's "N/A" _continue
                    }
                    capture drop `bv'
                    local pos = `pos' + `cw'
                }
            }
            else {
                forvalues i = 1/3 {
                    di _col(`pos') %~`cw's "N/A" _continue
                    local pos = `pos' + `cw'
                }
            }
        }
        di ""
    }
    
    di as txt "{hline `totw'}"
    di as txt "Notes:"
    if `do_ers'  di as txt "  ERS/DF-GLS: lag method `ersm'. Null = unit root. Level/1st Diff/2nd Diff."
    if `do_bsrw' di as txt "  Bootstrap: `bsreps' reps. Null = random walk with drift (Park, 2003). Level/1st Diff/2nd Diff."
    if `stars'   di as txt "  ***, **, * denote significance at 1%, 5%, 10% levels."
    di ""
end

* ==============================================================================
*  TABLE 4: KM TEST
* ==============================================================================
program define _urs_table4
    syntax varlist(ts) [if], KMLags(integer) [NODrift STARs(integer 1)]
    
    marksample touse
    capture which kmtest
    if _rc {
        di as err "Warning: {bf:kmtest} not installed. Run: {stata ssc install kmtest}"
        exit
    }
    
    local vw = 14
    local cw = 14
    local totw = `vw' + 2 + 6*`cw'
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  Table 4. Kobayashi-McAleer Test: Linear vs Logarithmic"
    di as txt "{hline `totw'}"
    
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    foreach h in "Drift" "H0:Linear" "p-val" "H0:Log" "p-val" "Recommend." {
        di _col(`pos') %~`cw's "`h'" _continue
        local pos = `pos' + `cw'
    }
    di ""
    di as txt "{hline `totw'}"
    
    foreach v of local varlist {
        qui sum `v' if `touse'
        local vname = substr("`v'", 1, `=`vw'-2')
        if r(min) <= 0 {
            di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
            di _col(`=`vw'+2') "  Skipped: non-positive values"
            di ""
            continue
        }
        
        capture qui kmtest `v' if `touse', lags(`kmlags') `nodrift'
        if _rc {
            di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
            di _col(`=`vw'+2') "  Error running kmtest"
            di ""
            continue
        }
        
        di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
        local pos = `vw' + 2
        
        local ttype "`r(test_type)'"
        di _col(`pos') %~`cw's "`=cond("`ttype'"=="with_drift","Yes","No")'" _continue
        local pos = `pos' + `cw'
        
        if "`ttype'" == "with_drift" {
            local t1 = r(V1)
            local p1 = r(V1_pval)
            local t2 = r(V2)
            local p2 = r(V2_pval)
        }
        else {
            local t1 = r(U1)
            local p1 = r(U1_pval)
            local t2 = r(U2)
            local p2 = r(U2_pval)
        }
        
        * H0:Linear stat
        local t1s : display %9.4f `t1'
        if `stars' {
            _urs_star `p1'
            local t1s = trim("`t1s'") + "`s(s)'"
        }
        di _col(`pos') %~`cw's "`t1s'" _continue
        local pos = `pos' + `cw'
        
        * p-val 1
        local p1s : display %6.4f `p1'
        di _col(`pos') %~`cw's "`p1s'" _continue
        local pos = `pos' + `cw'
        
        * H0:Log stat
        local t2s : display %9.4f `t2'
        if `stars' {
            _urs_star `p2'
            local t2s = trim("`t2s'") + "`s(s)'"
        }
        di _col(`pos') %~`cw's "`t2s'" _continue
        local pos = `pos' + `cw'
        
        * p-val 2
        local p2s : display %6.4f `p2'
        di _col(`pos') %~`cw's "`p2s'" _continue
        local pos = `pos' + `cw'
        
        * Recommendation
        local concl "`r(conclusion)'"
        if "`concl'" == "linear"          local rec "-> LEVELS"
        else if "`concl'" == "logarithmic" local rec "-> LOGS"
        else if "`concl'" == "both"       local rec "Inconclusive"
        else                              local rec "Neither"
        di _col(`pos') %~`cw's "`rec'" _continue
        di ""
    }
    
    di as txt "{hline `totw'}"
    di as txt "Notes: Kobayashi & McAleer (1999)."
    di as txt "  V1/V2 with drift (Normal). U1/U2 no drift (nonstandard c.v.: 10%=0.477, 5%=0.664, 1%=1.116)."
    di as txt "  Reject H0:Linear + fail to reject H0:Log -> LOGS; vice versa -> LEVELS."
    if `stars' di as txt "  ***, **, * denote significance at 1%, 5%, 10% levels."
    di ""
end

* ==============================================================================
*  TABLE 5: ELDER-KENNEDY DECISION STRATEGY
* ==============================================================================
program define _urs_table5
    syntax varlist(ts) [if], MAXlag(integer) CRIT(string) PPLAG(integer) ///
        [STARs(integer 1) ERSMETHOD(string) ZTRIM(real 0.15)]
    
    marksample touse
    
    local vw = 13
    local cw = 11
    local ncols = 11
    local totw = `vw' + 2 + `ncols'*`cw'
    
    * ERS setup
    local ersm = upper("`ersmethod'")
    if "`ersm'" == "" local ersm "SIC"
    local ridx = 3
    if "`ersm'" == "FIX"   local ridx = 1
    if "`ersm'" == "AIC"   local ridx = 2
    if "`ersm'" == "GTS05" local ridx = 4
    if "`ersm'" == "GTS10" local ridx = 5
    local ers_ok = 0
    capture which ersur
    if !_rc local ers_ok = 1
    local za_ok = 0
    capture which zandrews
    if !_rc local za_ok = 1
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  Table 5. Integration Order & Decision (Elder & Kennedy 2001)"
    di as txt "{hline `totw'}"
    
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    foreach h in "ADF(L.ct)" "ADF(d.c)" "ADF(d2.c)" "PP(L.ct)" "KPSS(L.c)" "ERS(L.c)" "ERS(d.c)" "ZA(L)" "Trend" "Order" "Process" {
        di _col(`pos') %~`cw's "`h'" _continue
        local pos = `pos' + `cw'
    }
    di ""
    di as txt "{hline `totw'}"
    
    foreach v of local varlist {
        local vname = substr("`v'", 1, `=`vw'-2')
        
        * ADF Level C+T
        capture qui _urs_adf_lag `v' if `touse', maxlag(`maxlag') det(ct) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller `v' if `touse', lags(`lg') trend
        local adf_ct_s = cond(_rc, ., r(Zt))
        local adf_ct_p = cond(_rc, ., r(p))
        
        * ADF 1st Diff C
        capture qui _urs_adf_lag D.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller D.`v' if `touse', lags(`lg')
        local adf_dc_s = cond(_rc, ., r(Zt))
        local adf_dc_p = cond(_rc, ., r(p))
        
        * ADF 2nd Diff C
        capture qui _urs_adf_lag D2.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller D2.`v' if `touse', lags(`lg')
        local adf_d2c_s = cond(_rc, ., r(Zt))
        local adf_d2c_p = cond(_rc, ., r(p))
        
        * PP Level C+T
        capture qui pperron `v' if `touse', lags(`pplag') trend
        local pp_ct_s = cond(_rc, ., r(Zt))
        local pp_ct_p = cond(_rc, ., r(p))
        
        * KPSS Level C
        local kpss_s = .
        local kpss_star = ""
        capture which kpss
        if !_rc {
            tempvar kv
            capture qui gen double `kv' = `v' if `touse'
            if !_rc {
                capture qui kpss `kv' if `touse', notrend auto
                if !_rc {
                    local kpss_s = .
                    capture local kpss_s = r(kpss`=r(maxlag)')
                    if missing(`kpss_s') {
                        capture local kpss_s = r(kpss0)
                    }
                    if !missing(`kpss_s') {
                        _urs_kpss_star `kpss_s' c
                        local kpss_star "`s(s)'"
                    }
                }
            }
            capture drop `kv'
        }
        
        * ERS Level C
        local ers_lc_s = .
        local ers_lc_p = .
        if `ers_ok' {
            tempname _ER
            capture qui ersur `v' if `touse', noprint maxlag(`maxlag')
            if !_rc {
                matrix `_ER' = r(results)
                local ers_lc_s = `_ER'[`ridx',2]
                local ers_lc_p = `_ER'[`ridx',3]
            }
        }
        
        * ERS 1st Diff C
        local ers_dc_s = .
        local ers_dc_p = .
        if `ers_ok' {
            capture qui ersur D.`v' if `touse', noprint maxlag(`maxlag')
            if !_rc {
                tempname _ER2
                matrix `_ER2' = r(results)
                local ers_dc_s = `_ER2'[`ridx',2]
                local ers_dc_p = `_ER2'[`ridx',3]
            }
        }
        
        * ZA Level (intercept break)
        local za_l_s = .
        if `za_ok' {
            capture qui zandrews `v' if `touse', break(intercept) trim(`ztrim')
            if !_rc {
                local za_l_s = r(tmin)
            }
        }
        
        * Trend significance
        local trend_sig = 0
        local trend_p = .
        capture qui {
            tempvar tr
            gen `tr' = _n if `touse'
            regress `v' `tr' if `touse'
            local trend_p = 2*ttail(e(df_r), abs(_b[`tr']/_se[`tr']))
            drop `tr'
        }
        if !missing(`trend_p') & `trend_p' < 0.05 local trend_sig = 1
        
        * === DECISION LOGIC ===
        local lev_rej = (!missing(`adf_ct_p') & `adf_ct_p' < 0.05)
        local d1_rej  = (!missing(`adf_dc_p') & `adf_dc_p' < 0.05)
        local d2_rej  = (!missing(`adf_d2c_p') & `adf_d2c_p' < 0.05)
        
        if `lev_rej' & `trend_sig' {
            local order "I(0)"
            local proc "TS"
        }
        else if `lev_rej' & !`trend_sig' {
            local order "I(0)"
            local proc "Stationary"
        }
        else if `d1_rej' {
            local order "I(1)"
            local proc "DS"
        }
        else if `d2_rej' {
            local order "I(2)"
            local proc "DS"
        }
        else {
            local order "I(>2)"
            local proc "?"
        }
        
        * === PRINT STAT ROW ===
        di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
        local pos = `vw' + 2
        
        * ADF L.ct
        if !missing(`adf_ct_s') {
            local tx : display %8.3f `adf_ct_s'
            if `stars' {
                _urs_star `adf_ct_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * ADF d.c
        if !missing(`adf_dc_s') {
            local tx : display %8.3f `adf_dc_s'
            if `stars' {
                _urs_star `adf_dc_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * ADF d2.c
        if !missing(`adf_d2c_s') {
            local tx : display %8.3f `adf_d2c_s'
            if `stars' {
                _urs_star `adf_d2c_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * PP L.ct
        if !missing(`pp_ct_s') {
            local tx : display %8.3f `pp_ct_s'
            if `stars' {
                _urs_star `pp_ct_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * KPSS L.c
        if !missing(`kpss_s') {
            local tx : display %8.4f `kpss_s'
            if `stars' & "`kpss_star'" != "" local tx = trim("`tx'") + "`kpss_star'"
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * ERS L.c
        if !missing(`ers_lc_s') {
            local tx : display %8.3f `ers_lc_s'
            if `stars' & !missing(`ers_lc_p') {
                _urs_star `ers_lc_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * ERS d.c
        if !missing(`ers_dc_s') {
            local tx : display %8.3f `ers_dc_s'
            if `stars' & !missing(`ers_dc_p') {
                _urs_star `ers_dc_p'
                local tx = trim("`tx'") + "`s(s)'"
            }
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * ZA L (intercept)
        if !missing(`za_l_s') {
            local tx : display %8.3f `za_l_s'
            _urs_za_sig `za_l_s' A
            if `stars' local tx = trim("`tx'") + "`r(sig_star)'"
        }
        else local tx "."
        di _col(`pos') %~`cw's "`tx'" _continue
        local pos = `pos' + `cw'
        
        * Trend sig
        di _col(`pos') %~`cw's "`=cond(`trend_sig',"Yes","No")'" _continue
        local pos = `pos' + `cw'
        
        * Order + Process
        di _col(`pos') %~`cw's "`order'" _continue
        local pos = `pos' + `cw'
        di _col(`pos') %~`cw's "`proc'" _continue
        di ""
        
        * === PRINT P-VALUE ROW ===
        di as txt _col(`=`vw'+1') "{c |}" _continue
        local pos = `vw' + 2
        
        foreach pv in `adf_ct_p' `adf_dc_p' `adf_d2c_p' `pp_ct_p' {
            if !missing(`pv') {
                local ptx : display %6.4f `pv'
                local ptx "(`ptx')"
            }
            else local ptx ""
            di _col(`pos') %~`cw's "`ptx'" _continue
            local pos = `pos' + `cw'
        }
        * KPSS, ERS, ZA, Trend, Order, Process - leave blank on p-val row
        forvalues i = 1/7 {
            di _col(`pos') %~`cw's "" _continue
            local pos = `pos' + `cw'
        }
        di ""
    }
    
    di as txt "{hline `totw'}"
    di as txt "Notes: Elder & Kennedy (2001) Testing Strategy:"
    di as txt "  Step 1: ADF with C+T at level. Reject + trend sig. -> TS (detrend)"
    di as txt "  Step 2: If fail, test 1st diff with C. Reject -> I(1) DS (difference)"
    di as txt "  Step 3: If fail, test 2nd diff with C. Reject -> I(2) DS (diff twice)"
    di as txt "  TS = Trend Stationary. DS = Difference Stationary."
    di as txt "  KPSS: Null=stationarity. ERS/DF-GLS: Null=unit root. ZA: Null=unit root with structural break."
    if `stars' di as txt "  ***, **, * denote significance at 1%, 5%, 10% levels."
    di ""
end

* ==============================================================================
*  TABLE 6: COMPREHENSIVE SUMMARY — Per-Test Integration Order & Consensus
* ==============================================================================
program define _urs_table6
    syntax varlist(ts) [if], MAXlag(integer) CRIT(string) PPLAG(integer) ///
        [STARs(integer 1) ERSMETHOD(string) ZTRIM(real 0.15) ///
         BSReps(integer 500) CLEMtrim(real 0.05) CLEMmaxlag(integer 12)]
    
    marksample touse
    
    * Check which packages are available
    local ers_ok = 0
    capture which ersur
    if !_rc local ers_ok = 1
    local za_ok = 0
    capture which zandrews
    if !_rc local za_ok = 1
    local kpss_ok = 0
    capture which kpss
    if !_rc local kpss_ok = 1
    local bsrw_ok = 0
    capture which bsrwalkdrift
    if !_rc local bsrw_ok = 1
    local clem_ok = 0
    capture which clemao1
    if !_rc local clem_ok = 1
    
    * ERS setup
    local ersm = upper("`ersmethod'")
    if "`ersm'" == "" local ersm "SIC"
    local ridx = 3
    if "`ersm'" == "FIX"   local ridx = 1
    if "`ersm'" == "AIC"   local ridx = 2
    if "`ersm'" == "GTS05" local ridx = 4
    if "`ersm'" == "GTS10" local ridx = 5
    
    * ---------- LAYOUT ----------
    local vw = 14
    local cw = 9
    local ncols = 9
    local totw = `vw' + 2 + `ncols'*`cw'
    
    di ""
    di as txt "{hline `totw'}"
    di as res "  Table 6. Comprehensive Integration Order Summary"
    di as txt "{hline `totw'}"
    
    di as txt _col(1) "Variable" _col(`=`vw'+1') "{c |}" _continue
    local pos = `vw' + 2
    foreach h in "ADF" "PP" "KPSS" "ERS" "ZA" "BSRW" "Clem." "Consens" "Process" {
        di _col(`pos') %~`cw's "`h'" _continue
        local pos = `pos' + `cw'
    }
    di ""
    di as txt "{hline `totw'}"
    
    * ---------- LOOP OVER VARIABLES ----------
    foreach v of local varlist {
        local vname = substr("`v'", 1, `=`vw'-2')
        
        * ====== TREND SIGNIFICANCE ======
        local trend_sig = 0
        local _tp = .
        capture qui {
            tempvar _ttr
            gen `_ttr' = _n if `touse'
            regress `v' `_ttr' if `touse'
            local _tp = 2*ttail(e(df_r), abs(_b[`_ttr']/_se[`_ttr']))
            drop `_ttr'
        }
        if !missing(`_tp') & `_tp' < 0.05 local trend_sig = 1
        
        * ====== ADF DECISION ======
        capture qui _urs_adf_lag `v' if `touse', maxlag(`maxlag') det(ct) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller `v' if `touse', lags(`lg') trend
        local _adf_lp = cond(_rc, ., r(p))
        capture qui _urs_adf_lag D.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller D.`v' if `touse', lags(`lg')
        local _adf_dp = cond(_rc, ., r(p))
        capture qui _urs_adf_lag D2.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
        local lg = cond(_rc, 0, r(lag))
        capture qui dfuller D2.`v' if `touse', lags(`lg')
        local _adf_d2p = cond(_rc, ., r(p))
        
        if !missing(`_adf_lp') & `_adf_lp' < 0.05 & `trend_sig' {
            local adf_ord "TS"
        }
        else if !missing(`_adf_lp') & `_adf_lp' < 0.05 {
            local adf_ord "I(0)"
        }
        else if !missing(`_adf_dp') & `_adf_dp' < 0.05 {
            local adf_ord "I(1)"
        }
        else if !missing(`_adf_d2p') & `_adf_d2p' < 0.05 {
            local adf_ord "I(2)"
        }
        else {
            local adf_ord "I(>2)"
        }
        
        * ====== PP DECISION ======
        capture qui pperron `v' if `touse', lags(`pplag') trend
        local _pp_lp = cond(_rc, ., r(p))
        capture qui pperron D.`v' if `touse', lags(`pplag')
        local _pp_dp = cond(_rc, ., r(p))
        capture qui pperron D2.`v' if `touse', lags(`pplag')
        local _pp_d2p = cond(_rc, ., r(p))
        
        if !missing(`_pp_lp') & `_pp_lp' < 0.05 & `trend_sig' {
            local pp_ord "TS"
        }
        else if !missing(`_pp_lp') & `_pp_lp' < 0.05 {
            local pp_ord "I(0)"
        }
        else if !missing(`_pp_dp') & `_pp_dp' < 0.05 {
            local pp_ord "I(1)"
        }
        else if !missing(`_pp_d2p') & `_pp_d2p' < 0.05 {
            local pp_ord "I(2)"
        }
        else {
            local pp_ord "I(>2)"
        }
        
        * ====== KPSS DECISION ======
        local kpss_ord "N/A"
        if `kpss_ok' {
            local _kl = .
            tempvar _kv1
            capture qui gen double `_kv1' = `v' if `touse'
            if !_rc {
                capture qui kpss `_kv1' if `touse', notrend auto
                if !_rc {
                    capture local _kl = r(kpss`=r(maxlag)')
                    if missing(`_kl') capture local _kl = r(kpss0)
                }
            }
            capture drop `_kv1'
            local _kl_stat = cond(!missing(`_kl') & `_kl' < 0.463, 1, 0)
            
            local _kd = .
            tempvar _kv2
            capture qui gen double `_kv2' = D.`v' if `touse'
            if !_rc {
                capture qui kpss `_kv2' if `touse', notrend auto
                if !_rc {
                    capture local _kd = r(kpss`=r(maxlag)')
                    if missing(`_kd') capture local _kd = r(kpss0)
                }
            }
            capture drop `_kv2'
            local _kd_stat = cond(!missing(`_kd') & `_kd' < 0.463, 1, 0)
            
            local _kd2 = .
            tempvar _kv3
            capture qui gen double `_kv3' = D2.`v' if `touse'
            if !_rc {
                capture qui kpss `_kv3' if `touse', notrend auto
                if !_rc {
                    capture local _kd2 = r(kpss`=r(maxlag)')
                    if missing(`_kd2') capture local _kd2 = r(kpss0)
                }
            }
            capture drop `_kv3'
            local _kd2_stat = cond(!missing(`_kd2') & `_kd2' < 0.463, 1, 0)
            
            if `_kl_stat' & `trend_sig' {
                local kpss_ord "TS"
            }
            else if `_kl_stat' {
                local kpss_ord "I(0)"
            }
            else if `_kd_stat' {
                local kpss_ord "I(1)"
            }
            else if `_kd2_stat' {
                local kpss_ord "I(2)"
            }
            else {
                local kpss_ord "I(>2)"
            }
        }
        
        * ====== ERS DECISION ======
        local ers_ord "N/A"
        if `ers_ok' {
            tempname _ER
            local _ers_lp = .
            capture qui ersur `v' if `touse', noprint maxlag(`maxlag')
            if !_rc {
                matrix `_ER' = r(results)
                local _ers_lp = `_ER'[`ridx',3]
            }
            local _ers_dp = .
            capture qui ersur D.`v' if `touse', noprint maxlag(`maxlag')
            if !_rc {
                matrix `_ER' = r(results)
                local _ers_dp = `_ER'[`ridx',3]
            }
            local _ers_d2p = .
            capture qui ersur D2.`v' if `touse', noprint maxlag(`maxlag')
            if !_rc {
                matrix `_ER' = r(results)
                local _ers_d2p = `_ER'[`ridx',3]
            }
            
            if !missing(`_ers_lp') & `_ers_lp' < 0.05 & `trend_sig' {
                local ers_ord "TS"
            }
            else if !missing(`_ers_lp') & `_ers_lp' < 0.05 {
                local ers_ord "I(0)"
            }
            else if !missing(`_ers_dp') & `_ers_dp' < 0.05 {
                local ers_ord "I(1)"
            }
            else if !missing(`_ers_d2p') & `_ers_d2p' < 0.05 {
                local ers_ord "I(2)"
            }
            else {
                local ers_ord "I(>2)"
            }
        }
        
        * ====== ZA DECISION ======
        local za_ord "N/A"
        if `za_ok' {
            local _za_lrej = 0
            capture qui zandrews `v' if `touse', break(intercept) trim(`ztrim')
            if !_rc {
                if r(tmin) < -4.80 local _za_lrej = 1
            }
            local _za_drej = 0
            capture qui zandrews D.`v' if `touse', break(intercept) trim(`ztrim')
            if !_rc {
                if r(tmin) < -4.80 local _za_drej = 1
            }
            local _za_d2rej = 0
            capture qui zandrews D2.`v' if `touse', break(intercept) trim(`ztrim')
            if !_rc {
                if r(tmin) < -4.80 local _za_d2rej = 1
            }
            
            if `_za_lrej' & `trend_sig' {
                local za_ord "TS"
            }
            else if `_za_lrej' {
                local za_ord "I(0)"
            }
            else if `_za_drej' {
                local za_ord "I(1)"
            }
            else if `_za_d2rej' {
                local za_ord "I(2)"
            }
            else {
                local za_ord "I(>2)"
            }
        }
        
        * ====== BSRW DECISION ======
        local bsrw_ord "N/A"
        if `bsrw_ok' {
            * Level
            local _bs_lrej = 0
            tempvar _bv1
            capture qui gen double `_bv1' = `v' if `touse'
            if !_rc {
                capture qui bsrwalkdrift `_bv1' if `touse', bsreps(`bsreps') nodots
                if !_rc {
                    if r(pval) < 0.05 local _bs_lrej = 1
                }
            }
            capture drop `_bv1'
            * 1st Diff
            local _bs_drej = 0
            tempvar _bv2
            capture qui gen double `_bv2' = D.`v' if `touse'
            if !_rc {
                capture qui bsrwalkdrift `_bv2' if `touse', bsreps(`bsreps') nodots
                if !_rc {
                    if r(pval) < 0.05 local _bs_drej = 1
                }
            }
            capture drop `_bv2'
            * 2nd Diff
            local _bs_d2rej = 0
            tempvar _bv3
            capture qui gen double `_bv3' = D2.`v' if `touse'
            if !_rc {
                capture qui bsrwalkdrift `_bv3' if `touse', bsreps(`bsreps') nodots
                if !_rc {
                    if r(pval) < 0.05 local _bs_d2rej = 1
                }
            }
            capture drop `_bv3'
            
            if `_bs_lrej' & `trend_sig' {
                local bsrw_ord "TS"
            }
            else if `_bs_lrej' {
                local bsrw_ord "I(0)"
            }
            else if `_bs_drej' {
                local bsrw_ord "I(1)"
            }
            else if `_bs_d2rej' {
                local bsrw_ord "I(2)"
            }
            else {
                local bsrw_ord "I(>2)"
            }
        }
        
        * ====== CLEMENTE DECISION ======
        * Use ClemAO1 (additive outlier, 1 break) at 5% cv = -3.560
        local clem_ord "N/A"
        if `clem_ok' {
            local _cl_lrej = 0
            capture qui clemao1 `v' if `touse', maxlag(`clemmaxlag') trim(`clemtrim')
            if !_rc {
                if r(tst) < -3.560 local _cl_lrej = 1
            }
            local _cl_drej = 0
            capture qui clemao1 D.`v' if `touse', maxlag(`clemmaxlag') trim(`clemtrim')
            if !_rc {
                if r(tst) < -3.560 local _cl_drej = 1
            }
            local _cl_d2rej = 0
            capture qui clemao1 D2.`v' if `touse', maxlag(`clemmaxlag') trim(`clemtrim')
            if !_rc {
                if r(tst) < -3.560 local _cl_d2rej = 1
            }
            
            if `_cl_lrej' & `trend_sig' {
                local clem_ord "TS"
            }
            else if `_cl_lrej' {
                local clem_ord "I(0)"
            }
            else if `_cl_drej' {
                local clem_ord "I(1)"
            }
            else if `_cl_d2rej' {
                local clem_ord "I(2)"
            }
            else {
                local clem_ord "I(>2)"
            }
        }
        
        * ====== CONSENSUS ======
        local n_ts = 0
        local n_i0 = 0
        local n_i1 = 0
        local n_i2 = 0
        local n_ig = 0
        local n_tests = 0
        
        foreach tord in "`adf_ord'" "`pp_ord'" "`kpss_ord'" "`ers_ord'" "`za_ord'" "`bsrw_ord'" "`clem_ord'" {
            if "`tord'" == "N/A" continue
            local ++n_tests
            if "`tord'" == "TS"    local ++n_ts
            if "`tord'" == "I(0)"  local ++n_i0
            if "`tord'" == "I(1)"  local ++n_i1
            if "`tord'" == "I(2)"  local ++n_i2
            if "`tord'" == "I(>2)" local ++n_ig
        }
        
        * Majority rule
        local consensus "?"
        local con_proc "?"
        local max_vote = max(`n_ts', `n_i0', `n_i1', `n_i2', `n_ig')
        
        * Check TS + I(0) combined (both mean stationary at level)
        local n_stat = `n_ts' + `n_i0'
        if `n_stat' > `n_i1' & `n_stat' > `n_i2' & `n_stat' > `n_ig' & `n_stat' > 0 {
            if `n_ts' >= `n_i0' & `n_ts' > 0 {
                local consensus "TS"
                local con_proc "Detrend"
                local max_vote = `n_stat'
            }
            else {
                local consensus "I(0)"
                local con_proc "Stationary"
                local max_vote = `n_stat'
            }
        }
        else if `n_i1' == `max_vote' & `n_i1' > 0 {
            local consensus "I(1)"
            local con_proc "Diff. once"
        }
        else if `n_i2' == `max_vote' & `n_i2' > 0 {
            local consensus "I(2)"
            local con_proc "Diff. twice"
        }
        else if `n_ig' == `max_vote' & `n_ig' > 0 {
            local consensus "I(>2)"
            local con_proc "Non-Stat."
        }
        
        local consensus "`consensus'(`max_vote'/`n_tests')"
        
        * ====== PRINT ROW ======
        di as txt _col(1) "`vname'" _col(`=`vw'+1') "{c |}" _continue
        local pos = `vw' + 2
        
        foreach tord in "`adf_ord'" "`pp_ord'" "`kpss_ord'" "`ers_ord'" "`za_ord'" "`bsrw_ord'" "`clem_ord'" {
            if "`tord'" == "TS" | "`tord'" == "I(0)" {
                di as res _col(`pos') %~`cw's "`tord'" _continue
            }
            else if "`tord'" == "I(1)" {
                di as txt _col(`pos') %~`cw's "`tord'" _continue
            }
            else if "`tord'" == "I(2)" | "`tord'" == "I(>2)" {
                di as err _col(`pos') %~`cw's "`tord'" _continue
            }
            else {
                di as txt _col(`pos') %~`cw's "`tord'" _continue
            }
            local pos = `pos' + `cw'
        }
        
        * Consensus column
        if "`con_proc'" == "Stationary" | "`con_proc'" == "Detrend" {
            di as res _col(`pos') %~`cw's "`consensus'" _continue
        }
        else if "`con_proc'" == "Diff. once" {
            di as txt _col(`pos') %~`cw's "`consensus'" _continue
        }
        else {
            di as err _col(`pos') %~`cw's "`consensus'" _continue
        }
        local pos = `pos' + `cw'
        
        * Process column
        di as txt _col(`pos') %~`cw's "`con_proc'" _continue
        di ""
    }
    
    di as txt "{hline `totw'}"
    di as txt "Notes: Per-test integration order from Level->1st Diff->2nd Diff testing."
    di as txt "  TS = Trend Stationary (detrend). I(0) = Stationary. I(1) = Diff once."
    di as txt "  I(2) = Diff twice. I(>2) = Non-stationary at tested orders."
    di as txt "  Consensus = majority vote (count/total)."
    di as txt "  ADF/PP/ERS/ZA/BSRW/Clem: Null=unit root. KPSS: Null=stationarity."
    di ""
end

* ==============================================================================
*  GRAPH EXPORT — Comprehensive Stata-native visualizations
* ==============================================================================
program define _urs_graphs
    syntax varlist(ts) [if], do_za(integer) ZTRIM(real) ///
        MAXlag(integer) CRIT(string) PPLAG(integer) ///
        [STARs(integer 1) GRAPHDir(string)]
    
    marksample touse
    
    * Set output directory
    local gdir "`graphdir'"
    if "`gdir'" == "" local gdir "urstat_graphs"
    capture mkdir "`gdir'"
    
    qui tsset
    local timevar "`r(timevar)'"
    local timefmt "`r(tsfmt)'"
    if "`timefmt'" == "" local timefmt "%9.0g"
    
    local nvars : word count `varlist'
    
    di ""
    di as txt "{hline 70}"
    di as res "  URSTAT Visualizations"
    di as txt "{hline 70}"
    di as txt "  Output directory: `gdir'/"
    di ""
    
    foreach v of local varlist {
        
        * ==================================================================
        * GRAPH 1: Time Series Panel — Level + 1st Diff + 2nd Diff
        * ==================================================================
        tempvar dv d2v
        qui gen double `dv'  = D.`v' if `touse'
        qui gen double `d2v' = D2.`v' if `touse'
        
        twoway (tsline `v' if `touse', lcolor("24 53 103") lwidth(medthick)), ///
            title("Level", size(medsmall) color(black)) ///
            ytitle("`v'", size(small)) xtitle("") ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
            name(_urs_lev, replace) nodraw
        
        twoway (tsline `dv' if `touse', lcolor("178 34 34") lwidth(medthick)) ///
            , ///
            title("First Difference", size(medsmall) color(black)) ///
            ytitle("D.`v'", size(small)) xtitle("") ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
            yline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
            name(_urs_d1, replace) nodraw
        
        twoway (tsline `d2v' if `touse', lcolor("34 139 34") lwidth(medthick)) ///
            , ///
            title("Second Difference", size(medsmall) color(black)) ///
            ytitle("D2.`v'", size(small)) xtitle("") ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
            yline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
            name(_urs_d2, replace) nodraw
        
        graph combine _urs_lev _urs_d1 _urs_d2, ///
            cols(1) ///
            title("Time Series Analysis: `v'", size(medium) color(black)) ///
            subtitle("Level, First Difference, and Second Difference", size(small) color(gs6)) ///
            graphregion(color(white)) ///
            xsize(9) ysize(11) ///
            name(_urs_ts_`v', replace)
        
        graph export "`gdir'/`v'_timeseries.png", replace width(1200) height(1600)
        di as txt "  {c +} `gdir'/`v'_timeseries.png"
        
        * ==================================================================
        * GRAPH 2: Level vs. Diff overlay comparison
        * ==================================================================
        twoway ///
            (tsline `v'  if `touse', lcolor("24 53 103") lwidth(medthick) yaxis(1)) ///
            (tsline `dv' if `touse', lcolor("178 34 34") lwidth(medium) lpattern(dash) yaxis(2)) ///
            , ///
            title("Level vs. First Difference: `v'", size(medium) color(black)) ///
            subtitle("Dual-axis comparison", size(small) color(gs6)) ///
            ytitle("Level (`v')", axis(1) size(small) color("24 53 103")) ///
            ytitle("D.`v'", axis(2) size(small) color("178 34 34")) ///
            xtitle("") ///
            legend(order(1 "Level" 2 "1st Difference") ///
                ring(0) pos(11) cols(1) size(small) ///
                region(lcolor(gs14) fcolor(white))) ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14) axis(1)) ///
            ylabel(, labsize(vsmall) angle(0) axis(2)) ///
            xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
            xsize(10) ysize(6) ///
            name(_urs_cmp_`v', replace)
        
        graph export "`gdir'/`v'_level_vs_diff.png", replace width(1400) height(800)
        di as txt "  {c +} `gdir'/`v'_level_vs_diff.png"
        
        capture graph drop _urs_lev _urs_d1 _urs_d2
        drop `dv' `d2v'
        
        * ==================================================================
        * GRAPH 3: ACF / PACF Correlogram (Level + 1st Diff)
        * ==================================================================
        local _acf_ok = 1
        capture {
            ac `v' if `touse', lags(20) ///
                title("ACF: Level", size(medsmall) color(black)) ///
                graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, labsize(vsmall) angle(0)) ///
                xlabel(, labsize(vsmall)) ///
                name(_urs_acf_l, replace) nodraw
            pac `v' if `touse', lags(20) ///
                title("PACF: Level", size(medsmall) color(black)) ///
                graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, labsize(vsmall) angle(0)) ///
                xlabel(, labsize(vsmall)) ///
                name(_urs_pacf_l, replace) nodraw
        }
        if _rc local _acf_ok = 0
        
        capture {
            ac D.`v' if `touse', lags(20) ///
                title("ACF: 1st Difference", size(medsmall) color(black)) ///
                graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, labsize(vsmall) angle(0)) ///
                xlabel(, labsize(vsmall)) ///
                name(_urs_acf_d, replace) nodraw
            pac D.`v' if `touse', lags(20) ///
                title("PACF: 1st Difference", size(medsmall) color(black)) ///
                graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, labsize(vsmall) angle(0)) ///
                xlabel(, labsize(vsmall)) ///
                name(_urs_pacf_d, replace) nodraw
        }
        if _rc local _acf_ok = 0
        
        if `_acf_ok' {
            graph combine _urs_acf_l _urs_pacf_l _urs_acf_d _urs_pacf_d, ///
                cols(2) rows(2) ///
                title("Correlogram: `v'", size(medium) color(black)) ///
                subtitle("ACF and PACF for Level and First Difference", size(small) color(gs6)) ///
                graphregion(color(white)) ///
                xsize(10) ysize(8) ///
                name(_urs_corr_`v', replace)
            graph export "`gdir'/`v'_correlogram.png", replace width(1400) height(1000)
            di as txt "  {c +} `gdir'/`v'_correlogram.png"
            capture graph drop _urs_acf_l _urs_pacf_l _urs_acf_d _urs_pacf_d
        }
        
        * ==================================================================
        * GRAPH 4: Structural Break — ZA with break date lines
        * ==================================================================
        if `do_za' {
            capture which zandrews
            if !_rc {
                local za_brk_obs = .
                local za_tstat = .
                local za_cv5 = .
                local za_brk_obs2 = .
                local za_tstat2 = .
                local za_cv5_2 = .
                
                * Model A: intercept break
                capture qui zandrews `v' if `touse', break(intercept) trim(`ztrim')
                if !_rc {
                    local za_tstat = r(tmin)
                    local za_brk_obs = r(tminobs)
                    local za_cv5 = r(crit05)
                }
                
                * Model C: both intercept + trend break 
                capture qui zandrews `v' if `touse', break(both) trim(`ztrim')
                if !_rc {
                    local za_tstat2 = r(tmin)
                    local za_brk_obs2 = r(tminobs)
                    local za_cv5_2 = r(crit05)
                }
                
                * Get break date values for xline
                local za_brk_val = .
                local za_brk_val2 = .
                if !missing(`za_brk_obs') & `za_brk_obs' >= 1 & `za_brk_obs' <= _N {
                    local za_brk_val = `timevar'[`za_brk_obs']
                }
                if !missing(`za_brk_obs2') & `za_brk_obs2' >= 1 & `za_brk_obs2' <= _N {
                    local za_brk_val2 = `timevar'[`za_brk_obs2']
                }
                
                * Build xline options
                local xlines ""
                local brk_note ""
                
                if !missing(`za_brk_val') {
                    local xlines `"xline(`za_brk_val', lcolor("220 50 50") lwidth(thick) lpattern(dash))"'
                    local bd1 : display `timefmt' `za_brk_val'
                    local _sig1 = cond(`za_tstat' < `za_cv5', "Reject", "Fail")
                    local brk_note `"Model A break: `=trim("`bd1'")'  (t=`=string(`za_tstat',"%7.3f")',  5% cv=`=string(`za_cv5',"%7.2f")',  `_sig1')"'
                }
                if !missing(`za_brk_val2') {
                    local xlines `"`xlines' xline(`za_brk_val2', lcolor("230 140 20") lwidth(thick) lpattern(shortdash))"'
                    local bd2 : display `timefmt' `za_brk_val2'
                    local _sig2 = cond(`za_tstat2' < `za_cv5_2', "Reject", "Fail")
                    if "`brk_note'" != "" local brk_note `"`brk_note'  |  "'
                    local brk_note `"`brk_note'Model C break: `=trim("`bd2'")'  (t=`=string(`za_tstat2',"%7.3f")',  5% cv=`=string(`za_cv5_2',"%7.2f")',  `_sig2')"'
                }
                
                if !missing(`za_brk_val') | !missing(`za_brk_val2') {
                    * --- Plot a: Series with break lines ---
                    twoway ///
                        (tsline `v' if `touse', lcolor("24 53 103") lwidth(medthick)) ///
                        , ///
                        `xlines' ///
                        title("Level with Structural Breaks", size(medsmall) color(black)) ///
                        ytitle("`v'", size(small)) xtitle("") ///
                        graphregion(color(white)) plotregion(color(white)) ///
                        ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
                        xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
                        legend(off) ///
                        name(_urs_brk_lev, replace) nodraw
                    
                    * --- Plot b: 1st Diff with break lines ---
                    twoway ///
                        (tsline D.`v' if `touse', lcolor("178 34 34") lwidth(medthick)) ///
                        , ///
                        `xlines' ///
                        title("First Difference with Structural Breaks", size(medsmall) color(black)) ///
                        ytitle("D.`v'", size(small)) xtitle("") ///
                        graphregion(color(white)) plotregion(color(white)) ///
                        ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
                        xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
                        yline(0, lcolor(gs12) lpattern(dot) lwidth(thin)) ///
                        legend(off) ///
                        name(_urs_brk_dif, replace) nodraw
                    
                    * --- Plot c: 2nd Diff with break lines ---
                    twoway ///
                        (tsline D2.`v' if `touse', lcolor("34 139 34") lwidth(medthick)) ///
                        , ///
                        `xlines' ///
                        title("Second Difference with Structural Breaks", size(medsmall) color(black)) ///
                        ytitle("D2.`v'", size(small)) xtitle("") ///
                        graphregion(color(white)) plotregion(color(white)) ///
                        ylabel(, labsize(vsmall) angle(0) grid glcolor(gs14)) ///
                        xlabel(, labsize(vsmall) grid glcolor(gs14)) ///
                        yline(0, lcolor(gs12) lpattern(dot) lwidth(thin)) ///
                        legend(off) ///
                        name(_urs_brk_d2, replace) nodraw
                    
                    graph combine _urs_brk_lev _urs_brk_dif _urs_brk_d2, ///
                        cols(1) ///
                        title("Structural Break Analysis: `v'", size(medium) color(black)) ///
                        subtitle("Zivot-Andrews Break Detection", size(small) color(gs6)) ///
                        note("`brk_note'", size(vsmall)) ///
                        graphregion(color(white)) ///
                        xsize(10) ysize(12) ///
                        name(_urs_brk_`v', replace)
                    
                    graph export "`gdir'/`v'_structural_break.png", replace width(1400) height(1600)
                    di as txt "  {c +} `gdir'/`v'_structural_break.png"
                    capture graph drop _urs_brk_lev _urs_brk_dif _urs_brk_d2
                }
                else {
                    di as txt "  {c -} `v': ZA could not determine break dates"
                }
            }
        }
    }
    
    * ==================================================================
    * GRAPH 5: Integration Order Decision Summary (bar chart)
    * ==================================================================
    if `nvars' >= 1 {
        local nv : word count `varlist'
        
        * --- Compute integration orders BEFORE preserve/clear ---
        local i = 0
        foreach v of local varlist {
            local ++i
            
            * ADF level C+T
            capture qui _urs_adf_lag `v' if `touse', maxlag(`maxlag') det(ct) crit(`crit')
            local lg = cond(_rc, 0, r(lag))
            capture qui dfuller `v' if `touse', lags(`lg') trend
            local _lp = cond(_rc, ., r(p))
            
            * Trend sig
            local _tsig = 0
            local _tp = .
            capture {
                tempvar _ttr
                gen `_ttr' = _n if `touse'
                qui regress `v' `_ttr' if `touse'
                local _tp = 2*ttail(e(df_r), abs(_b[`_ttr']/_se[`_ttr']))
                drop `_ttr'
            }
            if !missing(`_tp') & `_tp' < 0.05 local _tsig = 1
            
            * ADF d.c
            capture qui _urs_adf_lag D.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
            local lg = cond(_rc, 0, r(lag))
            capture qui dfuller D.`v' if `touse', lags(`lg')
            local _dp = cond(_rc, ., r(p))
            
            * ADF d2.c
            capture qui _urs_adf_lag D2.`v' if `touse', maxlag(`maxlag') det(c) crit(`crit')
            local lg = cond(_rc, 0, r(lag))
            capture qui dfuller D2.`v' if `touse', lags(`lg')
            local _d2p = cond(_rc, ., r(p))
            
            * Decision
            if !missing(`_lp') & `_lp' < 0.05 & `_tsig' {
                local _ord_`i' = 0
                local _prc_`i' = "TS"
            }
            else if !missing(`_lp') & `_lp' < 0.05 & !`_tsig' {
                local _ord_`i' = 0
                local _prc_`i' = "Stat."
            }
            else if !missing(`_dp') & `_dp' < 0.05 {
                local _ord_`i' = 1
                local _prc_`i' = "DS"
            }
            else if !missing(`_d2p') & `_d2p' < 0.05 {
                local _ord_`i' = 2
                local _prc_`i' = "DS"
            }
            else {
                local _ord_`i' = 3
                local _prc_`i' = "?"
            }
        }
        
        * --- Now build dataset for bar chart ---
        qui {
            preserve
            clear
            set obs `nv'
            gen _vnum = _n
            gen _iord = .
            gen str32 _vname = ""
            gen str10 _proc = ""
        }
        
        local i = 0
        foreach v of local varlist {
            local ++i
            qui replace _iord = `_ord_`i'' in `i'
            qui replace _vname = "`v'" in `i'
            qui replace _proc = "`_prc_`i''" in `i'
        }
        
        * Draw bar chart
        twoway ///
            (bar _iord _vnum if _iord==0, color("34 197 94") barwidth(0.7)) ///
            (bar _iord _vnum if _iord==1, color("251 191 36") barwidth(0.7)) ///
            (bar _iord _vnum if _iord==2, color("239 68 68") barwidth(0.7)) ///
            (bar _iord _vnum if _iord>=3, color("148 163 184") barwidth(0.7)) ///
            , ///
            title("Integration Order Summary", size(medium) color(black)) ///
            subtitle("Elder & Kennedy (2001) Decision Strategy", size(small) color(gs6)) ///
            ytitle("Integration Order", size(small)) ///
            xtitle("") ///
            ylabel(0 "I(0)" 1 "I(1)" 2 "I(2)" 3 "I(>2)", angle(0) labsize(small) grid glcolor(gs14)) ///
            xlabel(, valuelabel labsize(small)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            legend(order(1 "I(0) Stationary" 2 "I(1) Diff. Stat." 3 "I(2) Diff. Stat." 4 "I(>2) Unknown") ///
                ring(0) pos(2) cols(1) size(vsmall) ///
                region(lcolor(gs14) fcolor(white))) ///
            xsize(10) ysize(6) ///
            name(_urs_decision, replace)
        
        graph export "`gdir'/integration_order_summary.png", replace width(1400) height(800)
        di as txt "  {c +} `gdir'/integration_order_summary.png"
        
        restore
    }
    
    di ""
    di as txt "{hline 70}"
    di as res "  All graphs saved to: `gdir'/"
    di as txt "  Use {bf:graph dir} to see named graphs in memory."
    di as txt "  Use {bf:graph display _urs_*} to re-display any graph."
    di as txt "{hline 70}"
    di ""
end

* ==============================================================================
*  ZA HELPERS
* ==============================================================================
program define _urs_za_date, rclass
    args idx tvar tfmt
    local dstr ""
    if "`idx'" != "" & "`idx'" != "." {
        * idx is observation number from zandrews r(tminobs)
        * tvar is the name of the time variable
        * tfmt is the time format
        local iidx = real("`idx'")
        if !missing(`iidx') & `iidx' >= 1 & `iidx' <= _N {
            tempname _zdate
            capture scalar `_zdate' = `tvar'[`iidx']
            if !_rc & !missing(scalar(`_zdate')) {
                capture local dstr : display `tfmt' scalar(`_zdate')
                if _rc {
                    * fallback: plain numeric display
                    local dstr : display %9.0g scalar(`_zdate')
                }
            }
        }
    }
    return local date_str = trim("`dstr'")
end

program define _urs_za_sig, rclass
    args stat model
    local c1  = cond("`model'"=="A", -5.34, -5.57)
    local c5  = cond("`model'"=="A", -4.80, -5.08)
    local c10 = cond("`model'"=="A", -4.58, -4.82)
    if "`stat'" == "" | "`stat'" == "." {
        return local sig_star ""
    }
    else if `stat' < `c1'  return local sig_star "***"
    else if `stat' < `c5'  return local sig_star "**"
    else if `stat' < `c10' return local sig_star "*"
    else                    return local sig_star ""
end
