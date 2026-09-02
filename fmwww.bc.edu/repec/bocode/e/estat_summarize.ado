*! estat_summarize.ado version 1.0.0
*! Post-estimation for plssem2 (PLS-SEM)
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program estat_summarize
  version 15.1
  syntax [, Level(cilevel) ]
  local mvs `e(mvs)'
  display _newline
  display as text "{p 0 6 2}{bf:Indicator summary statistics}{p_end}"
  quietly summarize `mvs'
end
