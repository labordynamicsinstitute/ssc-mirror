*! asycaus_all v1.0.0  24may2026
*! Comprehensive asymmetric causality battery — runs all available tests and
*! produces a single professional summary table + multi-panel visualization.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_all, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 4)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
          BOOT(integer 500)         ///
          SEED(integer 12345)       ///
          LNform                    ///
          SKIPDynamic                ///
          SKIPSpectral               ///
          SKIPQuantile               ///
          WINDow(integer 0)         ///
          KMAX(integer 5)           ///
          NFreq(integer 50)         ///
          Quantiles(numlist >0 <1 sort) ///
          noGRAPH                   ///
          SAVing(string)            ///
        ]

    if "`ic'" == "" local ic hjc
    if "`quantiles'" == "" local quantiles 0.1 0.25 0.5 0.75 0.9

    tokenize `varlist'
    local dep `1'
    local cau `2'
    local opts maxlag(`maxlag') ic(`ic') intorder(`intorder') boot(`boot') seed(`seed') `lnform' nograph

    di as txt _n "{hline 78}"
    di as txt "{center 78:ASYMMETRIC CAUSALITY BATTERY}"
    di as txt "{center 78:Author: Dr Merwan Roudane}"
    di as txt "{hline 78}"
    di as txt _col(2) "Direction tested:  " as res "`cau'" as txt " → " as res "`dep'"

    // --- 1. STATIC (Hatemi-J 2012) ---
    di as txt _n as res "[1/5] " as txt "Static Asymmetric Causality (Hatemi-J 2012)..."
    capture asycaus static `dep' `cau' `if' `in', `opts' shock(both)
    if _rc {
        di as err "  static failed (rc=`_rc')"
    }
    else {
        tempname M_static
        matrix `M_static' = r(results)
    }

    // --- 2. FOURIER (Nazlioglu 2016) ---
    di as txt _n as res "[2/5] " as txt "Fourier Asymmetric TY Causality (Nazlioglu et al. 2016)..."
    capture asycaus fourier `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') kmax(`kmax') `lnform' nograph shock(both) form(single)
    if !_rc {
        tempname M_fourier
        matrix `M_fourier' = r(results)
    }

    // --- 3. EFFICIENT (Hatemi-J 2024) ---
    di as txt _n as res "[3/5] " as txt "Efficient Asymmetric Causality (Hatemi-J 2024)..."
    capture asycaus efficient `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') `lnform' nograph
    if !_rc {
        local Wp_eff     = r(Wpos)
        local Wn_eff     = r(Wneg)
        local Wj_eff     = r(Wjoint)
        local Wd_eff     = r(Wdiff)
        local pp_eff     = r(p_pos)
        local pn_eff     = r(p_neg)
        local pj_eff     = r(p_joint)
        local pd_eff     = r(p_diff)
    }

    // --- 4. SPECTRAL (Bahmani-Oskooee et al. 2016) ---
    if "`skipspectral'" == "" {
        di as txt _n as res "[4/5] " as txt "Asymmetric Spectral Causality (Bahmani-Oskooee et al. 2016)..."
        capture asycaus spectral `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') nfreq(`nfreq') `lnform' nograph shock(both)
        if !_rc {
            tempname M_spec
            matrix `M_spec' = r(results)
        }
    }

    // --- 5. QUANTILE (Fang et al. 2026) ---
    if "`skipquantile'" == "" {
        di as txt _n as res "[5/5] " as txt "Quantile Asymmetric Causality (Fang et al. 2026)..."
        capture asycaus quantile `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') quantiles(`quantiles') `lnform' nograph shock(both)
        if !_rc {
            tempname M_quant
            matrix `M_quant' = r(results)
        }
    }

    // --- 6. DYNAMIC (Hatemi-J 2021) ---
    if "`skipdynamic'" == "" {
        di as txt _n as res "[*]   " as txt "Dynamic Asymmetric Causality (Hatemi-J 2021)..."
        local wopt
        if `window' > 0 local wopt window(`window')
        capture asycaus dynamic `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') boot(`=min(`boot',200)') seed(`seed') `lnform' rolling shock(pos) `wopt' nograph
        if !_rc {
            tempname M_dyn_pos
            matrix `M_dyn_pos' = r(results)
        }
        capture asycaus dynamic `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') boot(`=min(`boot',200)') seed(`seed') `lnform' rolling shock(neg) `wopt' nograph
        if !_rc {
            tempname M_dyn_neg
            matrix `M_dyn_neg' = r(results)
        }
    }

    // ====================================================
    //  UNIFIED SUMMARY TABLE
    // ====================================================
    di as txt _n _n "{hline 78}"
    di as txt _col(2) "{bf:UNIFIED ASYMMETRIC CAUSALITY SUMMARY}"
    di as txt _col(2) "H0: " as res "`cau'" as txt " does not Granger-cause " as res "`dep'"
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 34:Test}" ///
              _col(40) "{ralign 6:Shock}" ///
              _col(48) "{ralign 11:Statistic}" ///
              _col(60) "{ralign 11:p-value}" ///
              _col(72) "Decision"
    di as txt "{hline 78}"

    // STATIC
    if "`M_static'" != "" {
        local r 1
        foreach lbl in Positive Negative {
            if `r' <= rowsof(`M_static') {
                local W   = `M_static'[`r', 1]
                local dof = `M_static'[`r', 3]
                local c5  = `M_static'[`r', 5]
                local pv  = chi2tail(`dof', `W')
                local dd  = cond(`W' > `c5', "Reject", "Fail to reject")
                di as res _col(2) "{ralign 34:Static (Hatemi-J 2012)}" ///
                          _col(40) "{ralign 6:`=substr("`lbl'",1,3)'}" ///
                          _col(48) %11.4f `W' ///
                          _col(60) %11.4f `pv' ///
                          _col(72) "`dd'"
                local r = `r' + 1
            }
        }
    }

    // FOURIER
    if "`M_fourier'" != "" {
        local r 1
        foreach lbl in Positive Negative {
            if `r' <= rowsof(`M_fourier') {
                local W  = `M_fourier'[`r', 1]
                local pv = `M_fourier'[`r', 4]
                local dd = cond(`pv' < 0.05, "Reject", "Fail to reject")
                di as res _col(2) "{ralign 34:Fourier (Nazlioglu 2016)}" ///
                          _col(40) "{ralign 6:`=substr("`lbl'",1,3)'}" ///
                          _col(48) %11.4f `W' ///
                          _col(60) %11.4f `pv' ///
                          _col(72) "`dd'"
                local r = `r' + 1
            }
        }
    }

    // EFFICIENT
    if "`Wp_eff'" != "" {
        local dd_p = cond(`pp_eff' < 0.05, "Reject", "Fail to reject")
        local dd_n = cond(`pn_eff' < 0.05, "Reject", "Fail to reject")
        local dd_j = cond(`pj_eff' < 0.05, "Reject", "Fail to reject")
        local dd_d = cond(`pd_eff' < 0.05, "Reject", "Fail to reject")
        di as res _col(2) "{ralign 34:Efficient Pos only (HJ 2024)}" ///
                  _col(40) "{ralign 6:Pos}" ///
                  _col(48) %11.4f `Wp_eff' ///
                  _col(60) %11.4f `pp_eff' ///
                  _col(72) "`dd_p'"
        di as res _col(2) "{ralign 34:Efficient Neg only (HJ 2024)}" ///
                  _col(40) "{ralign 6:Neg}" ///
                  _col(48) %11.4f `Wn_eff' ///
                  _col(60) %11.4f `pn_eff' ///
                  _col(72) "`dd_n'"
        di as res _col(2) "{ralign 34:Efficient Joint (HJ 2024)}" ///
                  _col(40) "{ralign 6:both}" ///
                  _col(48) %11.4f `Wj_eff' ///
                  _col(60) %11.4f `pj_eff' ///
                  _col(72) "`dd_j'"
        di as res _col(2) "{ralign 34:Efficient Pos=Neg (HJ 2024)}" ///
                  _col(40) "{ralign 6:diff}" ///
                  _col(48) %11.4f `Wd_eff' ///
                  _col(60) %11.4f `pd_eff' ///
                  _col(72) "`dd_d'"
    }

    // SPECTRAL
    if "`M_spec'" != "" {
        local nrowspec = rowsof(`M_spec')
        forvalues sid = 1/2 {
            local count_rej = 0
            local total = 0
            forvalues r = 1/`nrowspec' {
                if `M_spec'[`r', 1] == `sid' {
                    local total = `total' + 1
                    if `M_spec'[`r', 3] > `M_spec'[`r', 5] local count_rej = `count_rej' + 1
                }
            }
            if `total' > 0 {
                local lbl = cond(`sid' == 1, "Pos", "Neg")
                local pct = `count_rej' / `total'
                local dd  = cond(`count_rej' > 0, "Reject at some", "Fail to reject")
                di as res _col(2) "{ralign 34:Spectral (BCRanjbar 2016)}" ///
                          _col(40) "{ralign 6:`lbl'}" ///
                          _col(48) "{ralign 11:freq rej.}" ///
                          _col(60) %11.4f `pct' ///
                          _col(72) "`dd'"
            }
        }
    }

    // QUANTILE
    if "`M_quant'" != "" {
        local nrowq = rowsof(`M_quant')
        forvalues sid = 1/2 {
            local nrej = 0
            local total = 0
            forvalues r = 1/`nrowq' {
                if `M_quant'[`r', 1] == `sid' {
                    local total = `total' + 1
                    if `M_quant'[`r', 5] < 0.05 local nrej = `nrej' + 1
                }
            }
            if `total' > 0 {
                local lbl = cond(`sid' == 1, "Pos", "Neg")
                local pct = `nrej' / `total'
                local dd  = cond(`nrej' > 0, "Reject at some", "Fail to reject")
                di as res _col(2) "{ralign 34:Quantile (Fang et al. 2026)}" ///
                          _col(40) "{ralign 6:`lbl'}" ///
                          _col(48) "{ralign 11:quant. rej.}" ///
                          _col(60) %11.4f `pct' ///
                          _col(72) "`dd'"
            }
        }
    }
    di as txt "{hline 78}"
    di as txt _col(2) "Decision at 5% level. Reject = causality from {it:`cau'} to {it:`dep'} present."
    di as txt _col(2) "Spectral/quantile rows report the fraction of frequencies/quantiles rejecting."
    _asycaus_footer

    if "`graph'" != "nograph" {
        // Combine all individual graphs into a single dashboard if possible
        capture _asycaus_dashboard `dep' `cau' `if' `in', `opts' kmax(`kmax') nfreq(`nfreq') quantiles(`quantiles')
    }

    return local depvar "`dep'"
    return local cause  "`cau'"
end


program define _asycaus_dashboard
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 4)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
          BOOT(integer 500)         ///
          SEED(integer 12345)       ///
          LNform                    ///
          KMAX(integer 5)           ///
          NFreq(integer 50)         ///
          Quantiles(numlist >0 <1 sort) ///
          NOGRAPH                   ///
        ]

    tokenize `varlist'
    local dep `1'
    local cau `2'

    // Render each individual graph
    capture asycaus static    `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') boot(`boot') seed(`seed') `lnform' shock(both)
    capture asycaus fourier   `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') kmax(`kmax') `lnform' shock(both) form(single)
    capture asycaus spectral  `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') nfreq(`nfreq') `lnform' shock(both)
    capture asycaus quantile  `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') quantiles(`quantiles') `lnform' shock(both)
    capture asycaus efficient `dep' `cau' `if' `in', maxlag(`maxlag') ic(`ic') intorder(`intorder') `lnform'

    capture graph combine asycaus_static asycaus_fourier asycaus_efficient asycaus_spectral asycaus_quantile, ///
        cols(2) rows(3) graphregion(color(white)) ///
        title("Asymmetric Causality Dashboard: {it:`cau'} → {it:`dep'}", size(small)) ///
        name(asycaus_dashboard, replace)
end
