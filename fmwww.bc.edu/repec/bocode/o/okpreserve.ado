program define okpreserve
  version 19

  if "$vpres_cnt" == "" {
    global vpres_cnt = 0
  }

  * Create a unique session ID once, without disturbing the RNG state
  if "$vpres_id" == "" {
    local rs "`c(rngstate)'"
    global vpres_id = string(runiformint(1, 999999999))
    set rngstate `rs'
  }

  global vpres_cnt = $vpres_cnt + 1
  local lv = $vpres_cnt

  local f "`c(tmpdir)'/okpreserve_${vpres_id}_`lv'.dta"
  global vpres_file_`lv' "`f'"

  quietly save "`f'", replace

  di as text "Preserve level `lv' saved (`=_N' obs)"
end
