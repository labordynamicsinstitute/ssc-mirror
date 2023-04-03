*! version 0.1 2023-02-22 Niels Henrik Bruun
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2023-04-01 v0.11  Bug fix
*  2023-02-22 v0.1   created

program define tteir
  version 12

  syntax varname , /*
    */Failure(passthru) /*
    */[ /*
      */id(passthru) /*
      */Origin(passthru) /*
      */Enter(passthru) /*
      */Exit(passthru) /*
      */SCale(passthru) /*
      */AT(passthru) /*
      */EVery(passthru) /*
      */AFter(passthru) /*
      */trim /*
      */by(varlist) /*
      */NIntervals(integer 0) /*
      */MINInterval(integer 0) /*
      */noQuietly /*
    */]

    foreach var in _tp _futm _total _x {
      capture drop `var'
    }
    if "`id'" == "" {
      tempname id
      generate `id' = _n
      local id id(`id')
    }
    
    if "`quietly'" == "" local QUI quietly
    `QUI' {
      stset `varlist', `failure' `origin' `enter' `exit' `scale' `id'
      if `mininterval' > 0 | `nintervals' > 0 {        
        if `mininterval' > 0 {        
          quietly summarize _d
          local nintervals = max(floor(`r(sum)' / `mininterval'), 1)
        }
        if `nintervals' > 1 {
          equal_n_events, nintervals(`nintervals')
          local at at(`r(lst)')
        }
        else {
          quietly summarize _t
          local at at(`=r(max) + 1')
        }
      }
      
      if !regexm("`every'", "^every\(\ *\.\ *\)$") stsplit _start, `at' `every' `trim' `after'
      else stsplit, at(failures) riskset(_start)
      generate  _futm = _t - _t0
      format _futm %8.3f
      
      collapse (max) _stop=_t (count) _total=_d (sum) _x=_d _futm, by(_start `by')
      sort `by' _start 
    } 
end

program define equal_n_events, sortpreserve rclass
  syntax , nintervals(integer)

  tempname w
  bysort _t: generate `w' = sum(_d)
  bysort _t: replace `w' = `w'[_N] / _N
  _pctile _t [pw = `w'], n(`nintervals')
  local lst 0 
  forvalues g = 1/`=`nintervals'-1' { 
    local lst `lst' `r(r`g')'
  }
  local lst `lst' `=_t[_N]+1'
  return local lst `lst'
end
