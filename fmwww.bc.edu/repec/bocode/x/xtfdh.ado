*! xtfdh — Fourier Dumitrescu-Hurlin Panel Granger Non-Causality Test
*! Version 1.0.0 — 2026-06-06
*! Author:  Dr. Merwan Roudane, Independent Researcher
*! Email:   merwanroudane920@gmail.com
*! GitHub:  https://github.com/merwanroudane
*! Copyright (c) 2026 Merwan Roudane. Distributed under the SSC Archive terms.
*!
*! Implements:
*!   Dumitrescu & Hurlin (2012) — panel Granger non-causality <doi:10.1016/j.econmod.2012.02.014>
*!   Ersin (2026) — Fourier-DH (FDH) generalization <doi:10.3390/su18062728>
*!   Enders & Lee (2012) — Fourier flexible form
*!
*! Standardization follows the convention in xtgcause (Lopez & Weber 2017).
*!
*! See also:  xtpfardl  (Fourier-augmented panel ARDL / CS-ARDL)

capture program drop xtfdh
program define xtfdh, rclass sortpreserve
    version 17

    // =====================================================================
    // SYNTAX
    // =====================================================================
    syntax varlist(min=2 max=2 ts) [if] [in] , [   ///
        LAGS(integer 1)             /// number of lags K
        MAXK(integer 3)             /// max Fourier frequency for search
        K(real -1)                  /// fix Fourier frequency
        FRACtional                  /// search k in 0.1 steps
        NOFourier                   /// standard (non-Fourier) DH test
        DIRection(string)           /// forward | reverse | both
        noGRaph                     ///
        GRAPHPrefix(string)         ///
        REGress                     /// show each unit regression
        ]

    marksample touse
    local y : word 1 of `varlist'
    local x : word 2 of `varlist'

    if "`direction'" == "" local direction "both"
    local direction = lower("`direction'")
    if !inlist("`direction'","forward","reverse","both") {
        di as err "direction() must be {bf:forward}, {bf:reverse} or {bf:both}"
        exit 198
    }
    if `lags' < 1 {
        di as err "lags() must be a positive integer"
        exit 198
    }

    // panel structure
    capture xtset
    if _rc {
        di as err "data are not {bf:xtset}. Use {bf:xtset panelvar timevar} first."
        exit 459
    }
    local id  "`r(panelvar)'"
    local tv  "`r(timevar)'"
    if "`id'" == "" {
        di as err "xtfdh requires panel data (xtset panelvar timevar)."
        exit 459
    }

    // time index & Fourier period
    tempvar tindex
    qui egen `tindex' = group(`tv') if `touse'
    qui sum `tindex' if `touse', meanonly
    local Tspan = r(max)

    // =====================================================================
    // Fourier frequency
    // =====================================================================
    if "`nofourier'" != "" {
        local kstar = 0
    }
    else if `k' >= 0 {
        local kstar = `k'
    }
    else {
        _xtfdh_kselect `y' `x' if `touse', lags(`lags') tindex(`tindex') ///
            tspan(`Tspan') maxk(`maxk') `fractional'
        local kstar = r(kstar)
        matrix _xtfdh_kgrid = r(kgrid)
    }

    capture drop _xtfdh_sin _xtfdh_cos
    if `kstar' > 0 {
        qui gen double _xtfdh_sin = sin(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        qui gen double _xtfdh_cos = cos(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        local four "_xtfdh_sin _xtfdh_cos"
    }
    else local four ""

    // =====================================================================
    // HEADER
    // =====================================================================
    local ttl = cond(`kstar'>0, "Fourier Dumitrescu-Hurlin (FDH) Panel Causality Test", ///
                                  "Dumitrescu-Hurlin (DH) Panel Causality Test")
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "`ttl'"
    di as txt _col(3) "Heterogeneous-panel Granger non-causality" _col(62) "xtfdh 1.0.0"
    di as txt "{hline 78}"
    di as txt _col(3) "Panel variable" _col(28) ": " as res "`id'" ///
        as txt "   Time: " as res "`tv'"
    di as txt _col(3) "Lag order (K)" _col(28) ": " as res "`lags'"
    if `kstar' > 0 ///
        di as txt _col(3) "Fourier frequency (k*)" _col(28) ": " as res %5.2f `kstar'
    else ///
        di as txt _col(3) "Fourier terms" _col(28) ": " as res "none (standard DH)"
    di as txt "{hline 78}"
    di as txt ""

    // =====================================================================
    // TABLE
    // =====================================================================
    di as txt "  {hline 74}"
    di as txt _col(5) "Null hypothesis (H0)" _col(40) "W-bar" _col(50) "Z-bar" ///
       _col(60) "Z-tilde" _col(70) "p-val"
    di as txt "  {hline 74}"

    local doF = ("`direction'"=="forward" | "`direction'"=="both")
    local doR = ("`direction'"=="reverse" | "`direction'"=="both")

    if `doF' {
        _xtfdh_one `y' `x' if `touse', lags(`lags') id(`id') tv(`tv') ///
            four(`four') `regress'
        local wbar_f  = r(wbar)
        local zbar_f  = r(zbar)
        local zbart_f = r(zbart)
        local zbarp_f = r(zbart_pv)
        local Nf      = r(N)
        local dec_f   = cond(`zbarp_f'<0.10,"reject","not reject")
        local lastcause  "`x'"
        local lasteffect "`y'"
        _xtfdh_resrow "`x'" "`y'" `wbar_f' `zbar_f' `zbart_f' `zbarp_f'
    }
    if `doR' {
        _xtfdh_one `x' `y' if `touse', lags(`lags') id(`id') tv(`tv') ///
            four(`four') `regress'
        local wbar_r  = r(wbar)
        local zbar_r  = r(zbar)
        local zbart_r = r(zbart)
        local zbarp_r = r(zbart_pv)
        local Nr      = r(N)
        local dec_r   = cond(`zbarp_r'<0.10,"reject","not reject")
        local lastcause  "`y'"
        local lasteffect "`x'"
        _xtfdh_resrow "`y'" "`x'" `wbar_r' `zbar_r' `zbart_r' `zbarp_r'
    }
    di as txt "  {hline 74}"
    di as txt _col(5) "{it:Z-tilde = standardized statistic for finite T (Z-bar tilde).}"
    di as txt _col(5) "{it:Stars on p-value: *** p<0.01, ** p<0.05, * p<0.10.}"

    // =====================================================================
    // VERDICT (both directions)
    // =====================================================================
    if "`direction'" == "both" {
        di as txt ""
        di as res _col(3) "Causality verdict (10% level)"
        di as txt "  {hline 70}"
        local fwd = (`zbarp_f' < 0.10)
        local rev = (`zbarp_r' < 0.10)
        if `fwd' & `rev' ///
            di as res _col(5) "`x' <--> `y'   (BIDIRECTIONAL causality)"
        else if `fwd' & !`rev' ///
            di as res _col(5) "`x' --> `y'   (UNIDIRECTIONAL: `x' causes `y')"
        else if !`fwd' & `rev' ///
            di as res _col(5) "`y' --> `x'   (UNIDIRECTIONAL: `y' causes `x')"
        else ///
            di as txt _col(5) "No Granger-causality detected in either direction."
        di as txt "  {hline 70}"
    }

    // =====================================================================
    // GRAPH: per-unit Wald distribution (last direction stored in _xtfdh_W)
    // =====================================================================
    if "`graph'" == "" {
        capture _xtfdh_plot, lags(`lags') graphprefix(`graphprefix') ///
            cause("`lastcause'") effect("`lasteffect'")
    }
    capture drop _xtfdh_sin _xtfdh_cos _xtfdh_W

    di as txt "{hline 78}"
    di as res _col(3) "xtfdh 1.0.0" as txt _col(20) ///
       "{stata help xtfdh:help}  |  {stata help xtpfardl:xtpfardl}"
    di as txt "{hline 78}"

    // =====================================================================
    // RETURNS
    // =====================================================================
    return local cmd "xtfdh"
    return scalar kstar = `kstar'
    return scalar lags  = `lags'
    if `doF' {
        return scalar wbar_f  = `wbar_f'
        return scalar zbar_f  = `zbar_f'
        return scalar zbart_f = `zbart_f'
        return scalar p_f     = `zbarp_f'
    }
    if `doR' {
        return scalar wbar_r  = `wbar_r'
        return scalar zbar_r  = `zbar_r'
        return scalar zbart_r = `zbart_r'
        return scalar p_r     = `zbarp_r'
    }
    capture matrix drop _xtfdh_kgrid
end


// =========================================================================
//  DH in one direction:  H0 = `cause' does not Granger-cause `effect'
// =========================================================================
capture program drop _xtfdh_one
program define _xtfdh_one, rclass
    syntax varlist(min=2 max=2 ts) [if] , LAGS(integer) ID(varname) ///
        TV(varname) [ FOUR(string) REGress ]
    marksample touse
    local effect : word 1 of `varlist'
    local cause  : word 2 of `varlist'
    local K = `lags'

    qui sum `tv' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)

    qui levelsof `id' if `touse', local(idlist)
    capture drop _xtfdh_W
    qui gen double _xtfdh_W = .

    local nfour : word count `four'
    local minobs = 3*`K' + 2 + `nfour'
    // coefficient list to test jointly: the K lags of the causing variable
    local clist ""
    forvalues h = 1/`K' {
        local clist "`clist' L`h'.`cause'"
    }

    local sumW 0
    local Nval 0
    foreach i of local idlist {
        qui count if `id'==`i' & `touse' & inrange(`tv',`=`tmin'+`K'',`tmax')
        if r(N) <= `minobs' continue
        capture qui reg `effect' L(1/`K').`effect' L(1/`K').`cause' `four' ///
            if `id'==`i' & `touse' & inrange(`tv',`=`tmin'+`K'',`tmax')
        if _rc continue
        if e(df_r) <= 0 continue
        // joint Wald test of the K lags of the causing variable
        capture qui test `clist'
        if _rc continue
        if missing(r(F)) continue
        local ++Nval
        local Wi = `K'*r(F)
        local sumW = `sumW' + `Wi'
        qui replace _xtfdh_W = `Wi' if `id'==`i'
        if "`regress'" != "" {
            di as txt _n "Unit `id'==`i':  W_i = " as res %8.3f `Wi'
        }
    }

    if `Nval' == 0 {
        di as err "no unit produced a usable causality regression for K=`K' lags"
        di as err "  (each unit needs more than `minobs' usable time observations)"
        exit 2001
    }

    local wbar = `sumW'/`Nval'
    local N = `Nval'
    local T = `=`tmax'-`tmin'+1'

    // Z-bar and Z-bar tilde (DH 2012; xtgcause convention with T-K)
    local zbar  = sqrt(`N'/(2*`K')) * (`wbar'-`K')
    local zbar_pv = 2*(1-normal(abs(`zbar')))
    local zbart = sqrt(`N'/(2*`K') * ((`T'-`K')-2*`K'-5)/((`T'-`K')-`K'-3)) ///
                  * (((`T'-`K')-2*`K'-3)/((`T'-`K')-2*`K'-1)*`wbar' - `K')
    local zbart_pv = 2*(1-normal(abs(`zbart')))

    return scalar wbar     = `wbar'
    return scalar zbar     = `zbar'
    return scalar zbar_pv  = `zbar_pv'
    return scalar zbart    = `zbart'
    return scalar zbart_pv = `zbart_pv'
    return scalar N        = `N'
    return scalar T        = `T'
end


// =========================================================================
//  Fourier frequency selection for FDH (pooled min SSR)
// =========================================================================
capture program drop _xtfdh_kselect
program define _xtfdh_kselect, rclass
    syntax varlist(min=2 max=2 ts) [if] , LAGS(integer) TIndex(varname) ///
        TSpan(integer) MAXK(integer) [ FRACtional ]
    marksample touse
    local y : word 1 of `varlist'
    local x : word 2 of `varlist'
    local K = `lags'
    if "`fractional'" != "" {
        local step = 0.1
        local nk = round(`maxk'/0.1)
    }
    else {
        local step = 1
        local nk = `maxk'
    }
    tempname grid
    matrix `grid' = J(`nk',2,.)
    tempvar s c
    local best = .
    local kstar = 1
    forvalues iidx = 1/`nk' {
        local kval = `iidx'*`step'
        matrix `grid'[`iidx',1] = `kval'
        capture drop `s' `c'
        qui gen double `s' = sin(2*c(pi)*`kval'*`tindex'/`tspan') if `touse'
        qui gen double `c' = cos(2*c(pi)*`kval'*`tindex'/`tspan') if `touse'
        capture qui reg `y' L(1/`K').`y' L(1/`K').`x' `s' `c' if `touse'
        if _rc==0 {
            matrix `grid'[`iidx',2] = e(rss)
            if e(rss) < `best' | missing(`best') {
                local best = e(rss)
                local kstar = `kval'
            }
        }
    }
    return scalar kstar = `kstar'
    return matrix kgrid = `grid'
end


// =========================================================================
//  result row printer with stars
// =========================================================================
capture program drop _xtfdh_resrow
program define _xtfdh_resrow
    args cause effect wbar zbar zbart p
    local stars ""
    if `p' < 0.01      local stars "***"
    else if `p' < 0.05 local stars "**"
    else if `p' < 0.10 local stars "*"
    local h0 = "`cause' -/-> `effect'"
    di as txt _col(5) abbrev("`h0'",32) ///
       _col(38) as res %8.3f `wbar' ///
       _col(48) %8.3f `zbar' ///
       _col(58) %8.3f `zbart' ///
       _col(68) %6.3f `p' as res " `stars'"
end


// =========================================================================
//  per-unit Wald distribution plot
// =========================================================================
capture program drop _xtfdh_plot
program define _xtfdh_plot
    syntax , LAGS(integer) [ GRAPHPrefix(string) cause(string) effect(string) ]
    capture confirm variable _xtfdh_W
    if _rc exit
    local K = `lags'
    local cv95 = invchi2(`K',0.95)/`K'        // per-K critical reference (W/K vs F)
    local cvW  = invchi2(`K',0.95)
    preserve
    qui {
        keep if !missing(_xtfdh_W)
        bysort _xtfdh_W: keep if _n==1
        sort _xtfdh_W
        gen long rank = _n
    }
    capture noisily {
        twoway (scatter rank _xtfdh_W, mcolor("24 54 104") msymbol(circle) msize(small)), ///
            xline(`cvW', lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
            title("{bf:Individual Wald statistics}", size(medlarge) color("24 54 104")) ///
            subtitle("Heterogeneous Granger causality:  `cause' {&rarr} `effect'", ///
                size(small) color(gs6)) ///
            xtitle("Unit Wald statistic  W{subscript:i}", size(medsmall)) ///
            ytitle("Cross-section unit (sorted)", size(medsmall)) ///
            legend(off) ///
            note("Dashed line: {&chi}{superscript:2}({sf:`K'}) 5% critical value = `=string(`cvW',"%6.2f")'", ///
                size(vsmall) color(gs8)) ///
            graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
            name(xtfdh_wald, replace)
        capture graph export "`graphprefix'xtfdh_wald.png", replace width(1400)
    }
    restore
end
