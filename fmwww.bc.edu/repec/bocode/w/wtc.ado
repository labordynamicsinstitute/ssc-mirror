*! wtc — Wavelet Coherence
*! Version 1.1.0  2026-05-11
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package

program define wtc, eclass sortpreserve
    version 11

    syntax varlist(min=2 max=2 ts) [if] [in], ///
        [DT(real 1)                 ///
         Mother(string)             ///
         PAram(real -1)             ///
         DJ(real 0.25)              ///
         S0(real -1)               ///
         NRands(integer 300)        ///  Monte Carlo realizations
         NODisplay                  ///
         PLOT                       ///
         COLormap(string)           ///
        ]

    * ── Parse ──
    tokenize `varlist'
    local var1 "`1'"
    local var2 "`2'"

    if ("`mother'" == "") local mother "morlet"
    local mother = lower(trim("`mother'"))
    if (`s0' < 0) local s0 = 2 * `dt'
    if ("`colormap'" == "") local colormap "jet"

    marksample touse
    qui count if `touse'
    local N = r(N)

    * ── Extract data ──
    tempname x1 x2
    mata: `x1' = st_data(., "`var1'", "`touse'")
    mata: `x2' = st_data(., "`var2'", "`touse'")

    * ── Compute WTC ──
    di as text ""
    di as text "{hline 60}"
    di as text "{bf:  Computing Wavelet Coherence (WTC)}"
    di as text "  lwavelet package — Dr. Merwan Roudane"
    di as text "{hline 60}"
    di as text ""
    di as text "  Computing CWT of both series..."

    tempname result
    mata: `result' = _wv_wtc(`x1', `x2', `dt', "`mother'", `param', ///
                              `dj', `s0', ., `nrands')

    * ── Store results ──
    ereturn clear
    ereturn local cmd      "wtc"
    ereturn local var1     "`var1'"
    ereturn local var2     "`var2'"
    ereturn local mother   "`mother'"
    ereturn scalar N       = `N'
    ereturn scalar dt      = `dt'
    ereturn scalar nrands  = `nrands'

    mata: st_matrix("e(rsq)",    `result'.rsq)
    mata: st_matrix("e(phase)",  `result'.phase)
    mata: st_matrix("e(period)", `result'.period)
    mata: st_matrix("e(scale)",  `result'.scale)
    mata: st_matrix("e(coi)",    `result'.coi)
    mata: st_matrix("e(signif)", `result'.signif)

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_wtc(`result', "`var1'", "`var2'", `nrands')
    }

    * ── Plot ──
    if ("`plot'" != "") {
        _wv_plot_wtc `var1' `var2' if `touse', colormap(`colormap')
    }

    * ── Cleanup ──
    mata: mata drop `x1' `x2' `result'
end

* ═══════════════════════════════════════════════════════════════════════════
* WTC heatmap — MATLAB Grinsted-toolbox style
* ═══════════════════════════════════════════════════════════════════════════
program define _wv_plot_wtc
    syntax varlist(min=2 max=2) [if] [in], [colormap(string)]

    if ("`colormap'" == "") local colormap "jet"

    tokenize `varlist'
    local var1 "`1'"
    local var2 "`2'"

    tempname rmat smat cmat
    matrix `rmat' = e(rsq)
    matrix `smat' = e(period)
    matrix `cmat' = e(coi)

    local ns = rowsof(`smat')
    local N  = colsof(`rmat')

    local dt = e(dt)
    if ("`dt'" == "" | `dt' == .) local dt 1

    preserve
    clear

    * Display smoothing — moderate in both axes.  Heavy lifting against
    * streaks now happens upstream via reflect-padded FFT in _wv_cwt.
    tempname rmed rsm
    mata: st_matrix("`rmed'", _wv_median_2d(st_matrix("`rmat'"), 2))
    mata: st_matrix("`rsm'",  _wv_smooth_2d(st_matrix("`rmed'"), 2.5, 1.0))

    * Phase matrix.
    tempname phmat
    matrix `phmat' = e(phase)

    * Arrow subsampling (MATLAB default ~30 arrows per axis).
    local step_t = max(3, round(`N' / 30))
    local step_s = max(2, round(`ns' / 30))
    local maxarr = ceil(`ns' / `step_s') * ceil(`N' / `step_t') + 1

    qui set obs `= `ns' * `N' + `N' + `maxarr''
    qui gen double _time   = .
    qui gen double _period = .
    qui gen double _rsq    = .
    qui gen double _coi_t  = .
    qui gen double _coi_p  = .
    qui gen double _arr_x0 = .
    qui gen double _arr_y0 = .
    qui gen double _arr_x1 = .
    qui gen double _arr_y1 = .

    * Heatmap data in log2(period) — uniform grid.
    local obs = 0
    forvalues i = 1/`ns' {
        local lp_i = ln(`smat'[`i', 1]) / ln(2)
        forvalues j = 1/`N' {
            local ++obs
            qui replace _time   = (`j' - 1) * `dt' in `obs'
            qui replace _period = `lp_i'            in `obs'
            qui replace _rsq    = `rsm'[`i', `j']   in `obs'
        }
    }

    * COI line (log2 space).
    forvalues j = 1/`N' {
        local row = `ns' * `N' + `j'
        qui replace _coi_t = (`j' - 1) * `dt'           in `row'
        qui replace _coi_p = ln(`cmat'[`j', 1]) / ln(2) in `row'
    }

    * Phase arrows — visible size so direction (in/anti-phase) is readable.
    local time_range = (`N' - 1) * `dt'
    local arr_len_t = `time_range' * 0.030
    local arr_len_s = 0.18

    local arr_base = `ns' * `N' + `N'
    local arr_idx = 0
    forvalues i = 1(`step_s')`ns' {
        local p_i  = `smat'[`i', 1]
        local lp_i = ln(`p_i') / ln(2)
        forvalues j = 1(`step_t')`N' {
            if (`rsm'[`i', `j'] > 0.5 & `cmat'[`j', 1] >= `p_i') {
                local ++arr_idx
                local row = `arr_base' + `arr_idx'
                local x_st = (`j' - 1) * `dt'
                local ph_v = `phmat'[`i', `j']
                local x_en = `x_st' + `arr_len_t' * cos(`ph_v')
                local y_en = `lp_i' - `arr_len_s' * sin(`ph_v')
                qui replace _arr_x0 = `x_st' in `row'
                qui replace _arr_y0 = `lp_i' in `row'
                qui replace _arr_x1 = `x_en' in `row'
                qui replace _arr_y1 = `y_en' in `row'
            }
        }
    }

    * Colormap (64 colors).
    local ncolors 64
    mata: _wv_plot_cwt_colors("`colormap'", `ncolors')

    local cclist ""
    forvalues c = 1/`ncolors' {
        local cclist `"`cclist' "`color`c''""'
    }

    * Y-axis ticks.
    local pmin = `smat'[1, 1]
    local pmax = `smat'[`ns', 1]
    local ylab ""
    foreach v in 0.25 0.5 1 2 4 8 16 32 64 128 256 {
        if (`v' >= `pmin' & `v' <= `pmax') {
            local lv = ln(`v') / ln(2)
            local ylab `"`ylab' `lv' "`v'""'
        }
    }
    if (`"`ylab'"' == "") {
        local lv1 = ln(`pmin') / ln(2)
        local lv2 = ln(`pmax') / ln(2)
        local ylab `"`lv1' "`pmin'" `lv2' "`pmax'""'
    }

    twoway (contour _rsq _period _time,                       ///
                levels(`ncolors')                              ///
                ccolors(`cclist')                              ///
                interp(shepard)                                ///
                zlabel(0 "0.0" 0.2 "0.2" 0.4 "0.4"            ///
                       0.6 "0.6" 0.8 "0.8" 1 "1.0"))          ///
           (line _coi_p _coi_t,                                ///
                lcolor(black) lpattern(dash) lwidth(medthick)) ///
           (pcarrow _arr_y0 _arr_x0 _arr_y1 _arr_x1,          ///
                lcolor(black) lwidth(medium)                    ///
                mcolor(black) msize(small) mlwidth(medium))     ///
           , ///
           yscale(reverse)                            ///
           ylabel(`ylab', angle(0))                   ///
           ytitle("Period")                           ///
           xtitle("Time")                             ///
           ztitle("")                                 ///
           legend(off)                                ///
           title("Wavelet Coherence: `var1' vs `var2'") ///
           graphregion(color(white))                  ///
           plotregion(color(white))                   ///
           scheme(s2mono)                             ///
           name(wtc_`var1'_`var2', replace)

    restore
end
