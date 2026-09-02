*! estat_q2.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_q2
  version 15.1
  syntax [, Level(cilevel) ]
  if "`e(blindfold)'" == "" {
    display as error "blindfolding results not found; rerun plssem2 with the blindfold(#) option"
    exit 498
  }
  tempname q2red q2com q2indr q2indc
  matrix `q2red' = e(q2_redundancy)
  matrix `q2com' = e(q2_communality)
  local lvlist `e(lvs)'
  local mvs `e(mvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Stone-Geisser Q2 (blindfolding, omission distance " ///
    "`e(blindfold)')}{p_end}"
  display as text _col(2) "{bf:Latent variable}" _col(24) "{bf:Q2 communality}" ///
    _col(46) "{bf:Q2 redundancy}"
  display as text "{hline 60}"
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display as text _col(2) as result "`lv'" ///
      as text _col(24) as result %9.4f `q2com'[1, `j'] ///
      as text _col(46) as result %9.4f `q2red'[1, `j']
  }
  display as text "{hline 60}"
  display as text "Q2 > 0 indicates predictive relevance of the construct."
  capture matrix `q2indr' = e(q2_ind_red)
  if !_rc {
    matrix `q2indc' = e(q2_ind_com)
    display _newline
    display as text "{p 0 6 2}{bf:Per-indicator Q2}{p_end}"
    display as text _col(2) "{bf:Indicator}" _col(26) "{bf:Q2 communality}" ///
      _col(48) "{bf:Q2 redundancy}"
    local Q = e(k_mv)
    forvalues q = 1/`Q' {
      local indname : word `q' of `mvs'
      display as text _col(2) as result "`indname'" ///
        as text _col(26) as result %9.4f `q2indc'[`q', 1] ///
        as text _col(48) as result %9.4f `q2indr'[`q', 1]
    }
  }
end
