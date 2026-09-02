*! estat_htmt.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_htmt
  version 15.1
  syntax [, Level(cilevel) ]
  tempname htmt
  matrix `htmt' = e(htmt)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Heterotrait-monotrait ratio of correlations (HTMT)}{p_end}"
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display as text _col(2) as result %-12s "`lv'" _continue
    local i = 0
    foreach lv2 of local lvlist {
      local ++i
      local col = 14 + 9 * (`i' - 1)
      if `i' == `j' {
        display as text _col(`col') "1" _continue
      }
      else {
        display as result _col(`col') %8.4f `htmt'[`j', `i'] _continue
      }
    }
    display
  }
  display as text "Discriminant validity is supported if all HTMT < 0.90 (0.85)."
end
