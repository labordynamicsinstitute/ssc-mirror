*! estat_vif.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_vif
  version 15.1
  syntax [, Level(cilevel) ]
  tempname vif
  matrix `vif' = e(vif)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Inner model VIF (collinearity of the predictors)}{p_end}"
  display as text _col(2) "{bf:Endogenous LV}" _col(24) "{bf:Predictor}" _col(44) "{bf:VIF}"
  display as text "{hline 56}"
  forvalues j = 1/`P' {
    local lvj : word `j' of `lvlist'
    forvalues i = 1/`P' {
      local lvi : word `i' of `lvlist'
      if `vif'[`j', `i'] != 0 {
        display as text _col(2) as result "`lvj'" ///
          as text _col(24) as result "`lvi'" ///
          as text _col(44) as result %9.3f `vif'[`j', `i']
      }
    }
  }
  display as text "{hline 56}"
  display as text "VIF < 5 (or 10) indicates no problematic collinearity."
end
