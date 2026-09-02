*! estat_effects.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_effects
  version 15.1
  syntax [, Level(cilevel) direct indirect total ]
  local level = `level'
  if "`direct'`indirect'`total'" == "" {
    local direct "direct"
    local indirect "indirect"
    local total "total"
  }
  tempname B bind btot ci_ind ci_tot
  matrix `B' = e(pathcoef)
  matrix `bind' = e(indirect_effects)
  matrix `btot' = e(total_effects)
  local hasboot = ("`e(reps)'" != "")
  if `hasboot' {
    matrix `ci_ind' = e(ci_ind)
    matrix `ci_tot' = e(ci_tot)
  }
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Effects}{p_end}"
  if "`direct'" != "" {
    display _newline as text "{bf:Direct effects}"
    display as text _col(4) "{bf:Path}" _col(30) "{bf:Coef}"
    if `hasboot' {
      display as text _col(40) "{bf:[`level'% CI]}"
    }
    forvalues j = 1/`P' {
      local lvj : word `j' of `lvlist'
      forvalues i = 1/`P' {
        local lvi : word `i' of `lvlist'
        if `B'[`j', `i'] != 0 {
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %9.4f `B'[`j', `i'] _continue
          if `hasboot' {
            local idx = (`i' - 1) * `P' + `j'
            display as text _col(40) "[" %7.4f `ci_ind'[1, `idx'] "," ///
              %7.4f `ci_ind'[2, `idx'] "]" _continue
          }
          display
        }
      }
    }
  }
  if "`indirect'" != "" {
    display _newline as text "{bf:Indirect effects}"
    display as text _col(4) "{bf:Path}" _col(30) "{bf:Coef}"
    if `hasboot' {
      display as text _col(40) "{bf:[`level'% CI]}"
    }
    forvalues j = 1/`P' {
      local lvj : word `j' of `lvlist'
      forvalues i = 1/`P' {
        local lvi : word `i' of `lvlist'
        if `bind'[`j', `i'] != 0 {
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %9.4f `bind'[`j', `i'] _continue
          if `hasboot' {
            local idx = (`i' - 1) * `P' + `j'
            display as text _col(40) "[" %7.4f `ci_ind'[1, `idx'] "," ///
              %7.4f `ci_ind'[2, `idx'] "]" _continue
          }
          display
        }
      }
    }
  }
  if "`total'" != "" {
    display _newline as text "{bf:Total effects}"
    display as text _col(4) "{bf:Path}" _col(30) "{bf:Coef}"
    if `hasboot' {
      display as text _col(40) "{bf:[`level'% CI]}"
    }
    forvalues j = 1/`P' {
      local lvj : word `j' of `lvlist'
      forvalues i = 1/`P' {
        local lvi : word `i' of `lvlist'
        if `btot'[`j', `i'] != 0 {
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %9.4f `btot'[`j', `i'] _continue
          if `hasboot' {
            local idx = (`i' - 1) * `P' + `j'
            display as text _col(40) "[" %7.4f `ci_tot'[1, `idx'] "," ///
              %7.4f `ci_tot'[2, `idx'] "]" _continue
          }
          display
        }
      }
    }
  }
end
