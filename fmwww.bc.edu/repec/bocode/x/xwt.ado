*! xwt — Cross-Wavelet Transform
*! Version 1.1.0  2026-05-11
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package

program define xwt, eclass sortpreserve
    version 11

    syntax varlist(min=2 max=2 ts) [if] [in], ///
        [DT(real 1)                 ///
         Mother(string)             ///
         PAram(real -1)             ///
         DJ(real 0.25)              ///
         S0(real -1)               ///
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
    if ("`colormap'" == "") local colormap "turbo"

    marksample touse
    qui count if `touse'
    local N = r(N)

    * ── Extract data ──
    tempname x1 x2
    mata: `x1' = st_data(., "`var1'", "`touse'")
    mata: `x2' = st_data(., "`var2'", "`touse'")

    * ── Compute XWT ──
    tempname result
    mata: `result' = _wv_xwt(`x1', `x2', `dt', "`mother'", `param', `dj', `s0', .)

    * ── Store results ──
    ereturn clear
    ereturn local cmd     "xwt"
    ereturn local var1    "`var1'"
    ereturn local var2    "`var2'"
    ereturn local mother  "`mother'"
    ereturn scalar N      = `N'
    ereturn scalar dt     = `dt'

    mata: st_matrix("e(power)",  `result'.power)
    mata: st_matrix("e(phase)",  `result'.phase)
    mata: st_matrix("e(period)", `result'.period)
    mata: st_matrix("e(scale)",  `result'.scale)
    mata: st_matrix("e(coi)",    `result'.coi)

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_xwt(`result', "`var1'", "`var2'")
    }

    * ── Cleanup ──
    mata: mata drop `x1' `x2' `result'
end
