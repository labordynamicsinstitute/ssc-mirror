*! version 1.1.0  URALL: Unified Tests + Full Detailed Footnotes

capture program drop urall
capture program drop _urall_run_std
capture program drop _urall_run_za
capture program drop _urall_adf_select_lag
capture program drop _urall_center
capture program drop _urall_print_stat_p
capture program drop _urall_za_get_date
capture program drop _urall_za_get_sig

program define urall
    version 11.0
    syntax varlist(ts) [if] [in], TEST(string) ///
        [ ///
        /* Shared / ADF / PP / ERS Options */ ///
        CRIT(string) MAXlag(integer 12) PPLAG(integer 4) PPMATCH ERSMETHOD(string) ///
        /* Zivot-Andrews Options */ ///
        ZLAGMETHOD(string) ZMAXLAGS(string) ZTRIM(real 0.15) ZLEVEL(real 0.10) ///
        /* Formatting */ ///
        TITLE(string) FOOTNOTE(string) ///
        ]

    marksample touse
    
    local test = upper("`test'")
    if "`test'"=="RES" | "`test'"=="DFGLS" local test "ERS"
    
    if !inlist("`test'", "ADF", "PP", "ERS", "ZA") {
        di as err "Error: TEST() must be one of: ADF, PP, ERS, or ZA."
        exit 198
    }

    if "`test'" == "ZA" {
        if "`title'" == "" local title "Table 1. Zivot-Andrews Unit Root Test (Structural Break)"
        _urall_run_za `varlist' if `touse', ///
            zlagmethod(`zlagmethod') zmaxlags(`zmaxlags') ///
            ztrim(`ztrim') zlevel(`zlevel') title("`title'")
    }
    else {
        _urall_run_std `varlist' if `touse', ///
            test(`test') crit(`crit') maxlag(`maxlag') ///
            pplag(`pplag') `ppmatch' ersmethod(`ersmethod') ///
            title("`title'") footnote("`footnote'")
    }
end

* ==============================================================================
*  SUB-ROUTINE A: STANDARD TESTS (ADF, PP, ERS)
* ==============================================================================
program define _urall_run_std
    syntax varlist(ts) [if], TEST(string) [CRIT(string) MAXlag(integer 12) PPLAG(integer 4) PPMATCH ERSMETHOD(string) TITLE(string) FOOTNOTE(string)]
    
    marksample touse
    if "`crit'"=="" local crit "BIC"
    local crit = upper("`crit'")
    if "`crit'"=="SIC" local crit "BIC"
    
    local ersmethod = upper("`ersmethod'")
    if "`test'"=="ERS" {
        if "`ersmethod'"=="" local ersmethod "SIC"
        if "`ersmethod'"=="BIC" local ersmethod "SIC"
        capture which ersur
        if _rc {
            di as err "Command {bf:ersur} not found. Install via: ssc install ersur"
            exit 199
        }
    }

    local cols "L.C L.C+T d.C d.C+T"
    local nvars : word count `varlist'
    local ncols : word count `cols'

    tempname UR_STAT UR_P
    matrix `UR_STAT' = J(`nvars', `ncols', .)
    matrix `UR_P'    = J(`nvars', `ncols', .)

    matrix rownames `UR_STAT' = `varlist'
    matrix rownames `UR_P'    = `varlist'
    matrix colnames `UR_STAT' = `cols'
    matrix colnames `UR_P'    = `cols'

    local r = 0
    foreach v of local varlist {
        local ++r
        
        local L_L_C  .
        local L_L_CT .
        local L_D_C  .
        local L_D_CT .

        quietly _urall_adf_select_lag `v' if `touse', maxlag(`maxlag') det(c)  crit(`crit')
        local L_L_C = r(lag)
        quietly _urall_adf_select_lag `v' if `touse', maxlag(`maxlag') det(ct) crit(`crit')
        local L_L_CT = r(lag)
        quietly _urall_adf_select_lag D.`v' if `touse', maxlag(`maxlag') det(c)  crit(`crit')
        local L_D_C = r(lag)
        quietly _urall_adf_select_lag D.`v' if `touse', maxlag(`maxlag') det(ct) crit(`crit')
        local L_D_CT = r(lag)

        if "`test'"=="ADF" {
            quietly dfuller `v' if `touse', lags(`L_L_C')
            matrix `UR_STAT'[`r', 1] = r(Zt)
            matrix `UR_P'[`r',    1] = r(p)
            quietly dfuller `v' if `touse', lags(`L_L_CT') trend
            matrix `UR_STAT'[`r', 2] = r(Zt)
            matrix `UR_P'[`r',    2] = r(p)
            quietly dfuller D.`v' if `touse', lags(`L_D_C')
            matrix `UR_STAT'[`r', 3] = r(Zt)
            matrix `UR_P'[`r',    3] = r(p)
            quietly dfuller D.`v' if `touse', lags(`L_D_CT') trend
            matrix `UR_STAT'[`r', 4] = r(Zt)
            matrix `UR_P'[`r',    4] = r(p)
        }
        if "`test'"=="PP" {
            local P_L_C  = cond("`ppmatch'"!="", `L_L_C',  `pplag')
            local P_L_CT = cond("`ppmatch'"!="", `L_L_CT', `pplag')
            local P_D_C  = cond("`ppmatch'"!="", `L_D_C',  `pplag')
            local P_D_CT = cond("`ppmatch'"!="", `L_D_CT', `pplag')

            quietly pperron `v' if `touse', lags(`P_L_C')
            matrix `UR_STAT'[`r', 1] = r(Zt)
            matrix `UR_P'[`r',    1] = r(p)
            quietly pperron `v' if `touse', lags(`P_L_CT') trend
            matrix `UR_STAT'[`r', 2] = r(Zt)
            matrix `UR_P'[`r',    2] = r(p)
            quietly pperron D.`v' if `touse', lags(`P_D_C')
            matrix `UR_STAT'[`r', 3] = r(Zt)
            matrix `UR_P'[`r',    3] = r(p)
            quietly pperron D.`v' if `touse', lags(`P_D_CT') trend
            matrix `UR_STAT'[`r', 4] = r(Zt)
            matrix `UR_P'[`r',    4] = r(p)
        }
        if "`test'"=="ERS" {
            local ridx = .
            if "`ersmethod'"=="FIX"   local ridx = 1
            if "`ersmethod'"=="AIC"   local ridx = 2
            if "`ersmethod'"=="SIC"   local ridx = 3
            if "`ersmethod'"=="GTS05" local ridx = 4
            if "`ersmethod'"=="GTS10" local ridx = 5

            tempname R
            quietly ersur `v' if `touse', noprint maxlag(`maxlag')
            matrix `R' = r(results)
            matrix `UR_STAT'[`r',1] = `R'[`ridx',2]
            matrix `UR_P'[`r',   1] = `R'[`ridx',3]
            quietly ersur `v' if `touse', noprint maxlag(`maxlag') trend
            matrix `R' = r(results)
            matrix `UR_STAT'[`r',2] = `R'[`ridx',2]
            matrix `UR_P'[`r',   2] = `R'[`ridx',3]
            quietly ersur D.`v' if `touse', noprint maxlag(`maxlag')
            matrix `R' = r(results)
            matrix `UR_STAT'[`r',3] = `R'[`ridx',2]
            matrix `UR_P'[`r',   3] = `R'[`ridx',3]
            quietly ersur D.`v' if `touse', noprint maxlag(`maxlag') trend
            matrix `R' = r(results)
            matrix `UR_STAT'[`r',4] = `R'[`ridx',2]
            matrix `UR_P'[`r',   4] = `R'[`ridx',3]
        }
    }

    if "`title'"=="" {
        if "`test'"=="ADF" local title "Table 1. Unit Root Test (ADF): Test statistic and (p-value)"
        if "`test'"=="PP"  local title "Table 1. Unit Root Test (PP): Test statistic and (p-value)"
        if "`test'"=="ERS" local title "Table 1. Unit Root Test (ERS/DF-GLS): Test statistic and (p-value)"
    }
    
    local fn "`footnote'"
    if "`fn'" == "" {
        if "`test'"=="PP" & "`ppmatch'" != "" local fn "PP lags are set equal to ADF-selected lags using maxlag(`maxlag') and `crit'."
        if "`test'"=="ERS" local fn "Lag selection method for ERS/DF-GLS (ersur): `ersmethod'."
    }
    _urall_print_stat_p, statname(`UR_STAT') pname(`UR_P') test("`test'") title("`title'") footnote("`fn'")
end


* ==============================================================================
*  SUB-ROUTINE B: ZIVOT-ANDREWS (ZA)
* ==============================================================================
program define _urall_run_za
    syntax varlist(ts) [if], [ZLAGMETHOD(string) ZMAXLAGS(string) ZTRIM(real 0.15) ZLEVEL(real 0.10) TITLE(string)]
    
    marksample touse
    
    capture which zandrews
    if _rc {
        di as err "Error: {bf:zandrews} not found. Install via: ssc install zandrews"
        exit 199
    }

    if "`zlagmethod'" == "" local zlagmethod "BIC"
    local method_clean = upper(trim("`zlagmethod'"))
    
    local za_opts ""
    if "`method_clean'" == "INPUT" {
        if "`zmaxlags'" == "" {
            di as err "Error: zlagmethod(input) requires zmaxlags(#)."
            exit 198
        }
        local za_opts "maxlags(`zmaxlags') lagmethod(BIC)"
    }
    else {
        local za_opts "lagmethod(`method_clean')"
        if "`zmaxlags'" != "" local za_opts "`za_opts' maxlags(`zmaxlags')"
        if "`method_clean'" == "TTEST" local za_opts "`za_opts' level(`zlevel')"
    }
    local za_opts "`za_opts' trim(`ztrim')"

    quietly tsset
    local timevar "`r(timevar)'"
    local timefmt "`r(tsfmt)'"
    if "`timefmt'" == "" local timefmt "%9.0g"
    
    local w_lbl 12
    local w_col 20
    local pos1 1
    local pos2 14
    local pos3 34
    local pos4 54
    local pos5 74
    local totw = `pos5' + `w_col'

    if "`title'" != "" di as txt "`title'"
    di as txt "{hline `totw'}"
    di as txt _col(`pos1') "Variable" _continue
    di _col(`pos2') _continue
    _urall_center, text("L.C") width(`w_col')
    di _col(`pos3') _continue
    _urall_center, text("L.C+T") width(`w_col')
    di _col(`pos4') _continue
    _urall_center, text("d.C") width(`w_col')
    di _col(`pos5') _continue
    _urall_center, text("d.C+T") width(`w_col')
    di ""
    di as txt "{hline `totw'}"

    foreach var of local varlist {
        
        * 1. Level Intercept
        quietly capture zandrews `var' if `touse', break(intercept) `za_opts'
        if _rc { 
            local l1_1 "N/A"
            local l2_1 ""
        } 
        else {
            scalar temp_stat = r(tmin)
            scalar temp_obs  = r(tminobs)
            _urall_za_get_date temp_obs "`timevar'" "`timefmt'"
            local l1_1 : display %9.3f temp_stat " [" r(date_str) "]"
            _urall_za_get_sig temp_stat "A"
            local l2_1 "(`r(sig_str)')"
        }

        * 2. Level Both
        quietly capture zandrews `var' if `touse', break(both) `za_opts'
        if _rc { 
            local l1_2 "N/A"
            local l2_2 ""
        } 
        else {
            scalar temp_stat = r(tmin)
            scalar temp_obs  = r(tminobs)
            _urall_za_get_date temp_obs "`timevar'" "`timefmt'"
            local l1_2 : display %9.3f temp_stat " [" r(date_str) "]"
            _urall_za_get_sig temp_stat "C"
            local l2_2 "(`r(sig_str)')"
        }

        * 3. Diff Intercept
        quietly capture zandrews D.`var' if `touse', break(intercept) `za_opts'
        if _rc { 
            local l1_3 "N/A"
            local l2_3 ""
        } 
        else {
            scalar temp_stat = r(tmin)
            scalar temp_obs  = r(tminobs)
            _urall_za_get_date temp_obs "`timevar'" "`timefmt'"
            local l1_3 : display %9.3f temp_stat " [" r(date_str) "]"
            _urall_za_get_sig temp_stat "A"
            local l2_3 "(`r(sig_str)')"
        }

        * 4. Diff Both
        quietly capture zandrews D.`var' if `touse', break(both) `za_opts'
        if _rc { 
            local l1_4 "N/A"
            local l2_4 ""
        } 
        else {
            scalar temp_stat = r(tmin)
            scalar temp_obs  = r(tminobs)
            _urall_za_get_date temp_obs "`timevar'" "`timefmt'"
            local l1_4 : display %9.3f temp_stat " [" r(date_str) "]"
            _urall_za_get_sig temp_stat "C"
            local l2_4 "(`r(sig_str)')"
        }

        * PRINT
        local vname = substr("`var'", 1, `w_lbl')
        di as txt _col(`pos1') "`vname'" _continue
        
        di _col(`pos2') _continue
        _urall_center, text("`l1_1'") width(`w_col')
        di _col(`pos3') _continue
        _urall_center, text("`l1_2'") width(`w_col')
        di _col(`pos4') _continue
        _urall_center, text("`l1_3'") width(`w_col')
        di _col(`pos5') _continue
        _urall_center, text("`l1_4'") width(`w_col')
        di ""

        di as txt _col(`pos1') "" _continue
        di _col(`pos2') _continue
        _urall_center, text("`l2_1'") width(`w_col')
        di _col(`pos3') _continue
        _urall_center, text("`l2_2'") width(`w_col')
        di _col(`pos4') _continue
        _urall_center, text("`l2_3'") width(`w_col')
        di _col(`pos5') _continue
        _urall_center, text("`l2_4'") width(`w_col')
        di ""
        di ""
    }
    di as txt "{hline `totw'}"
    
    * --- FULL ZA FOOTNOTES ---
    di as txt "Notes: Statistic [Break Date]."
    di as txt "       (Significance Level based on Zivot-Andrews 1992)."
    di as txt "       < 0.01: 1%, < 0.05: 5%, < 0.10: 10%."
    di as txt "       Lag selection: `method_clean' (Max: `zmaxlags'). Trim: `ztrim'."
end

* ==============================================================================
*  HELPERS
* ==============================================================================

program define _urall_center, sclass
    syntax , TEXT(string) WIDTH(integer)
    local len = length("`text'")
    if `len' >= `width' {
        di "`text'" _continue
        sreturn local out = substr("`text'", 1, `width')
    }
    else {
        local lpad = int((`width' - `len')/2)
        di _skip(`lpad') "`text'" _continue
        sreturn local out " " // dummy
    }
end

program define _urall_adf_select_lag, rclass
    syntax varname(ts) [if], MAXlag(integer) DET(string) CRIT(string)
    marksample touse
    tempvar dy ly tr
    quietly gen double `dy' = D.`varlist' if `touse'
    quietly gen double `ly' = L.`varlist' if `touse'
    if "`det'"=="ct" quietly gen double `tr' = _n if `touse'

    local bestlag = 0
    local bestic  = .
    forvalues L = 0/`maxlag' {
        local dlist ""
        if `L' > 0 local dlist "L(1/`L').D.`varlist'"
        if "`det'"=="c" quietly regress `dy' `ly' `dlist' if `touse'
        else            quietly regress `dy' `ly' `tr' `dlist' if `touse'
        
        scalar __N = e(N)
        scalar __rss = e(rss)
        scalar __k = e(rank)
        scalar __aic = __N*ln(__rss/__N) + 2*__k
        scalar __bic = __N*ln(__rss/__N) + ln(__N)*__k
        local cur = cond("`crit'"=="AIC", __aic, __bic)
        
        if missing(`bestic') | (`cur' < `bestic') {
            local bestic  = `cur'
            local bestlag = `L'
        }
    }
    return scalar lag = `bestlag'
end

program define _urall_za_get_date, rclass
    args idx tvar tfmt
    if "`idx'"!="" & "`idx'"!="." {
        capture {
            local val = `tvar'[`idx']
            local dstr : display `tfmt' `val'
        }
    }
    return local date_str = trim("`dstr'")
end

program define _urall_za_get_sig, rclass
    args stat model
    local c1  = cond("`model'"=="A", -5.34, -5.57)
    local c5  = cond("`model'"=="A", -4.80, -5.08)
    local c10 = cond("`model'"=="A", -4.58, -4.82)
    
    if "`stat'"=="" | "`stat'"=="." return local sig_str ""
    else {
        if `stat' < `c1'      return local sig_str "< 0.01"
        else if `stat' < `c5' return local sig_str "< 0.05"
        else if `stat' < `c10' return local sig_str "< 0.10"
        else return local sig_str "> 0.10"
    }
end

program define _urall_print_stat_p
    syntax , STATname(name) Pname(name) TEST(string) [TITLE(string) FOOTNOTE(string)]
    local rnames : rownames `statname'
    local cnames : colnames `statname'
    local nrows : word count `rnames'
    local ncols : word count `cnames'
    
    local varw 12
    local colw 12
    local totw = `varw' + 3 + `ncols'*`colw'

    if "`title'" != "" di as txt "`title'"
    di as txt "{hline `totw'}"
    di as txt _col(1) "Variable" _continue
    local pos = `varw' + 3
    forvalues j = 1/`ncols' {
        local cn : word `j' of `cnames'
        di _col(`pos') _continue
        _urall_center, text("`cn'") width(`colw')
        local pos = `pos' + `colw'
    }
    di ""
    di as txt "{hline `totw'}"

    tempname s p
    forvalues i = 1/`nrows' {
        local rn : word `i' of `rnames'
        if length("`rn'") > `varw' local rn = substr("`rn'",1,`varw')
        di as txt _col(1) "`rn'" _continue
        
        * Stat Line
        local pos = `varw' + 3
        forvalues j = 1/`ncols' {
            scalar `s' = `statname'[`i',`j']
            local stxt : display %9.4f `s'
            di _col(`pos') _continue
            _urall_center, text("`stxt'") width(`colw')
            local pos = `pos' + `colw'
        }
        di ""
        
        * P-value Line
        di as txt _col(1) "" _continue
        local pos = `varw' + 3
        forvalues j = 1/`ncols' {
            scalar `p' = `pname'[`i',`j']
            if missing(`p') local pcell "(.)"
            else {
                local ptxt : display %6.4f `p'
                local pcell "(`ptxt')"
            }
            di _col(`pos') _continue
            _urall_center, text("`pcell'") width(`colw')
            local pos = `pos' + `colw'
        }
        di ""
    }
    di as txt "{hline `totw'}"
    
    * --- FULL STANDARD FOOTNOTES ---
    di as txt "Note: p-values are reported in parentheses."
    di as txt "      L denotes level and d denotes first difference."
    di as txt "      C denotes Constant, T denotes Trend, and C+T denotes Constant and Trend."

    if "`test'"=="ADF" | "`test'"=="PP" {
        di as txt "      Reported p-values are based on MacKinnon (1996) one-sided critical values."
    }
    else if "`test'"=="ERS" {
        di as txt "      Reported p-values are based on response-surface approximations for the ERS/DF-GLS test."
    }

    if "`footnote'" != "" {
        di as txt "      `footnote'"
    }
end