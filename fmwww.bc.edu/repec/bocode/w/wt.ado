*! wt — Continuous Wavelet Transform
*! Version 1.1.0  2026-05-11
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package

program define wt, eclass sortpreserve
    version 11

    syntax varname(ts) [if] [in], ///
        [DT(real 1)                 ///  time step
         Mother(string)             ///  mother wavelet (morlet/paul/dog)
         PAram(real -1)             ///  mother wavelet parameter
         DJ(real 0.25)              ///  scale spacing (sub-octaves)
         S0(real -1)               ///  smallest scale (-1 = auto)
         SIGlvl(real 0.95)         ///  significance level
         NODisplay                  ///  suppress output
         PLOT                       ///  produce heatmap plot
         COLormap(string)           ///  colormap: jet, parula, turbo
        ]

    * ── Defaults ──
    if ("`mother'" == "") local mother "morlet"
    local mother = lower(trim("`mother'"))
    if (`s0' < 0) local s0 = 2 * `dt'
    if ("`colormap'" == "") local colormap "parula"

    * ── Sample ──
    marksample touse
    qui count if `touse'
    local N = r(N)

    if (`N' < 4) {
        di as error "Insufficient observations (N=`N'). Need at least 4."
        exit 2001
    }

    * ── Extract data ──
    tempname xvec
    mata: `xvec' = st_data(., "`varlist'", "`touse'")

    * ── Compute CWT ──
    tempname result
    mata: `result' = _wv_cwt(`xvec', `dt', "`mother'", `param', `dj', `s0', .)

    * ── Read back resolved param (sentinel -1 → mother-specific default) ──
    mata: st_numscalar("__wv_param_resolved", `result'.param)
    local param = __wv_param_resolved

    * ── Compute significance ──
    tempname sig
    mata: `sig' = _wv_cwt_signif(`xvec', `dt', `result'.scale, "`mother'", `param', `siglvl')

    * ── Store in e() ──
    ereturn clear
    ereturn local cmd      "wt"
    ereturn local varname  "`varlist'"
    ereturn local mother   "`mother'"
    ereturn scalar N       = `N'
    ereturn scalar dt      = `dt'
    ereturn scalar param   = `param'
    ereturn scalar dj      = `dj'
    ereturn scalar s0      = `s0'

    mata: st_matrix("e(power)",  `result'.power)
    mata: st_matrix("e(period)", `result'.period)
    mata: st_matrix("e(scale)",  `result'.scale)
    mata: st_matrix("e(coi)",    `result'.coi)
    mata: st_matrix("e(signif)", `sig')

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_cwt(`result', `sig', "`varlist'")
    }

    * ── Plot ──
    if ("`plot'" != "") {
        _wv_plot_cwt `varlist' if `touse', colormap(`colormap')
    }

    * ── Cleanup ──
    mata: mata drop `xvec' `result' `sig'
end

* ═══════════════════════════════════════════════════════════════════════════
* Internal: Header display helper (Stata program)
* ═══════════════════════════════════════════════════════════════════════════
program define _wv_display_header
    args title subtitle
    local w = max(length("`title'"), length("`subtitle'")) + 4
    if (`w' < 60) local w 60
    di as text ""
    di as text "{hline `w'}"
    di as text "{bf:  `title'}"
    if ("`subtitle'" != "") {
        di as text "  `subtitle'"
    }
    di as text "{hline `w'}"
end

program define _wv_plot_cwt
    syntax varname [if] [in], [colormap(string)]

    * MATLAB-style smooth heatmap: parula default, 64 color levels.
    if ("`colormap'" == "") local colormap "parula"

    tempname pmat smat cmat
    matrix `pmat' = e(power)
    matrix `smat' = e(period)
    matrix `cmat' = e(coi)

    local ns = rowsof(`smat')
    local N  = colsof(`pmat')

    preserve
    clear
    qui set obs `= `ns' * `N''

    qui gen double _time   = .
    qui gen double _period = .
    qui gen double _power  = .

    local dt = e(dt)
    if ("`dt'" == "" | `dt' == .) local dt 1

    local obs = 0
    forvalues i = 1/`ns' {
        forvalues j = 1/`N' {
            local ++obs
            qui replace _time   = (`j' - 1) * `dt'  in `obs'
            qui replace _period = `smat'[`i', 1]    in `obs'
            qui replace _power  = ln(`pmat'[`i', `j'] + 1e-10) in `obs'
        }
    }

    * Generate ncolors RGB colors via Mata, then build the ccolors list.
    local ncolors 64
    mata: _wv_plot_cwt_colors("`colormap'", `ncolors')

    local cclist ""
    forvalues c = 1/`ncolors' {
        local cclist `"`cclist' "`color`c''""'
    }

    * Log-spaced y-axis tick labels covering the period range.
    local pmin = `smat'[1, 1]
    local pmax = `smat'[`ns', 1]
    local ylab ""
    foreach v in 0.25 0.5 1 2 4 8 16 32 64 128 256 {
        if (`v' >= `pmin' & `v' <= `pmax') local ylab "`ylab' `v'"
    }
    if ("`ylab'" == "") local ylab "`pmin' `pmax'"

    * Sparsen the colorbar tick labels (otherwise all 64 levels show).
    qui sum _power
    local zmin = ceil(r(min))
    local zmax = floor(r(max))
    local zstep = max(1, floor((`zmax' - `zmin') / 5))
    local zlab "`zmin'(`zstep')`zmax'"

    twoway contour _power _period _time,         ///
        levels(`ncolors')                         ///
        ccolors(`cclist')                         ///
        yscale(reverse log)                       ///
        ylabel(`ylab', angle(0))                  ///
        ytitle("Period")                          ///
        xtitle("Time")                            ///
        ztitle("")                                ///
        zlabel(`zlab')                            ///
        title("CWT Power Spectrum: `varlist'")    ///
        graphregion(color(white))                 ///
        plotregion(color(white))                  ///
        scheme(s2mono)                            ///
        name(cwt_`varlist', replace)

    restore
end
