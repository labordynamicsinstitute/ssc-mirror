*! estat_f2.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_f2
  version 15.1
  syntax [, Level(cilevel) ]
  tempname f2
  matrix `f2' = e(f2)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Effect size f2 (Cohen)}{p_end}"
  display as text _col(2) "{bf:Endogenous LV}" _col(24) "{bf:Predictor}" _col(44) "{bf:f2}"
  display as text "{hline 56}"
  forvalues j = 1/`P' {
    local lvj : word `j' of `lvlist'
    forvalues i = 1/`P' {
      local lvi : word `i' of `lvlist'
      if `f2'[`j', `i'] != 0 {
        display as text _col(2) as result "`lvj'" ///
          as text _col(24) as result "`lvi'" ///
          as text _col(44) as result %9.3f `f2'[`j', `i']
      }
    }
  }
  display as text "{hline 56}"
  display as text "f2 benchmarks: 0.02 small, 0.15 medium, 0.35 large."
end
