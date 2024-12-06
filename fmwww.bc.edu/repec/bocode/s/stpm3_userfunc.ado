version 16.1
program define stpm3_userfunc, rclass
  syntax anything [if][in], [                            ///
                           VNAME(string)                 ///
                           CENTer                        /// 
                           CENTerv(numlist min=1 max=1)  ///
                           STUB(string)                  ///
                           ]
  marksample touse                                   

  local hascenter  = "`center'"  != ""
  local hascenterv = "`centerv'" != ""
 
  gen double `vname' = `anything' if `touse' 
  
  if(`hascenter' & !`hascenterv') {
    summ `vname' if `touse', meanonly
    local centerval `r(mean)'
  }
  else if `hascenterv' local centerval `centerv'

  if "`centerval'" != "" {
    replace `vname' = `vname' - `centerval' if `touse'
  }
  
  return local fnvarname `vname'
  return local fncenter `centerval'
end