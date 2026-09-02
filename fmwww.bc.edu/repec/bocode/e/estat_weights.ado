*! estat_weights.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_weights
  version 15.1
  syntax [, Level(cilevel) ]
  local level = `level'
  tempname W se ci
  matrix `W' = e(outerweights)
  local lvlist `e(lvs)'
  local mvs `e(mvs)'
  local P = e(k_lv)
  local Q = e(k_mv)
  local hasboot = ("`e(reps)'" != "")
  if `hasboot' {
    matrix `se' = e(se_weg)
    matrix `ci' = e(ci_weg)
  }
  display _newline
  display as text "{p 0 6 2}{bf:Outer weights}{p_end}"
  display as text "Weights used to build the composite (latent variable) scores."
  local p = 0
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display _newline
    display as text "Latent variable: " as result "`lv'"
    display as text _col(6) "{bf:Indicator}" _col(26) "{bf:Weight}" ///
      _col(36) "{bf:SE}" _col(46) "{bf:[`level'% CI]}"
    forvalues q = 1/`Q' {
      if `W'[`q', `j'] != 0 {
        local ++p
        local indname : word `q' of `mvs'
        if `hasboot' {
          display as text _col(6) as result "`indname'" ///
            as text _col(26) as result %9.4f `W'[`q', `j'] ///
            as text _col(36) as result %9.4f `se'[1, `p'] ///
            as text _col(46) "[" %7.4f `ci'[1, `p'] "," %7.4f `ci'[2, `p'] "]"
        }
        else {
          display as text _col(6) as result "`indname'" ///
            as text _col(26) as result %9.4f `W'[`q', `j']
        }
      }
    }
  }
end
