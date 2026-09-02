*! estat_reliability.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_reliability
  version 15.1
  syntax [, Level(cilevel) ]
  tempname alpha cr ave
  matrix `alpha' = e(alpha)
  matrix `cr' = e(cr)
  matrix `ave' = e(ave)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Construct reliability and validity}{p_end}"
  display as text _col(2) "{bf:Latent variable}" _col(24) "{bf:alpha}" ///
    _col(36) "{bf:CR (rho_c)}" _col(50) "{bf:AVE}"
  display as text "{hline 60}"
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display as text _col(2) as result "`lv'" ///
      as text _col(24) as result %9.4f `alpha'[1, `j'] ///
      as text _col(36) as result %9.4f `cr'[1, `j'] ///
      as text _col(50) as result %9.4f `ave'[1, `j']
  }
  display as text "{hline 60}"
  display as text "Conventional thresholds: alpha and CR >= 0.7; AVE >= 0.5."
end
