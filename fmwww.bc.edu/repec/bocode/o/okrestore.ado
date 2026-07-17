program define okrestore
  version 19

  if "$vpres_cnt" == "" | $vpres_cnt < 1 {
    di as error "no okpreserve level to restore"
    exit 198
  }

  local lv = $vpres_cnt
  local f "${vpres_file_`lv'}"

  quietly use "`f'", clear
  capture erase "`f'"

  macro drop vpres_file_`lv'
  global vpres_cnt = $vpres_cnt - 1

  di as text "Restored level `lv' (`=_N' obs)"
end
