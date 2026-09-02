*! estat_group.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_group
  version 15.1
  syntax [, Level(cilevel) ]
  if "`e(gmethod)'" == "" {
    display as error "multi-group results not found; rerun plssem2 with the group() option"
    exit 498
  }
  tempname B1 B2 R2_1 R2_2 diff pv
  matrix `B1' = e(B1)
  matrix `B2' = e(B2)
  matrix `R2_1' = e(R2_1)
  matrix `R2_2' = e(R2_2)
  matrix `diff' = e(diff_obs)
  matrix `pv' = e(p_values)
  local lvlist `e(lvs)'
  local P : list sizeof lvlist
  local galpha = e(galpha)
  display _newline
  display as text "{hline 78}"
  display as text "Multi-group analysis (replay) - method: " as result "`e(gmethod)'"
  display as text "Grouping variable: " as result "`e(groupvar)'"
  display as text "{hline 78}"
  display as text _col(4) "{bf:Path}" _col(28) "{bf:|diff|}" ///
    _col(42) "{bf:p-value}" _col(56) "{bf:p < `galpha'}"
  display as text "{hline 78}"
  local p = 0
  forvalues j = 1/`P' {
    local lvj : word `j' of `lvlist'
    forvalues i = 1/`P' {
      local lvi : word `i' of `lvlist'
      if `B1'[`j', `i'] != 0 {
        local ++p
        display as text _col(4) as result "`lvj' <- `lvi'" ///
          as text _col(28) as result %8.4f `diff'[1, `p'] ///
          as text _col(42) as result %8.4f `pv'[1, `p'] ///
          as text _col(56) as result cond(`pv'[1, `p'] < `galpha', "yes", "no")
      }
    }
  }
  display as text "{hline 78}"
end
