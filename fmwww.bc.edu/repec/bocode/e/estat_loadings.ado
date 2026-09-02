*! estat_loadings.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_loadings
  version 15.1
  syntax [, Level(cilevel) ]
  local level = `level'
  tempname L se ci
  matrix `L' = e(loadings)
  local lvlist `e(lvs)'
  local mvs `e(mvs)'
  local P = e(k_lv)
  local Q = e(k_mv)
  local hasboot = ("`e(reps)'" != "")
  if `hasboot' {
    matrix `se' = e(se_load)
    matrix `ci' = e(ci_load)
  }
  display _newline
  display as text "{p 0 6 2}{bf:Outer loadings}{p_end}"
  display as text "Correlation of each indicator with its latent variable."
  local p = 0
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display _newline
    display as text "Latent variable: " as result "`lv'"
    display as text _col(6) "{bf:Indicator}" _col(26) "{bf:Loading}" ///
      _col(36) "{bf:SE}" _col(46) "{bf:[`level'% CI]}"
    forvalues q = 1/`Q' {
      if `L'[`q', `j'] != 0 {
        local ++p
        local indname : word `q' of `mvs'
        if `hasboot' {
          display as text _col(6) as result "`indname'" ///
            as text _col(26) as result %9.4f `L'[`q', `j'] ///
            as text _col(36) as result %9.4f `se'[1, `p'] ///
            as text _col(46) "[" %7.4f `ci'[1, `p'] "," %7.4f `ci'[2, `p'] "]"
        }
        else {
          display as text _col(6) as result "`indname'" ///
            as text _col(26) as result %9.4f `L'[`q', `j']
        }
      }
    }
  }
end
