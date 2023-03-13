// Mar 25 2018 14:53:47
// version of combinprep.ado to generate spell variables in the same data
program define cal2spell, rclass sortpreserve
version 9.0
syntax, STate(string) SPELLvar(string) length(string) NSPells(string)
tempvar spno l idvar
tempfile workfile

qui {
  gen `idvar' = _n

  preserve

  keep `idvar' `state'*
    reshape long `state', i(`idvar') j(`l')

  su `state'
  return scalar nels = 1 + r(max) - r(min)

  gen `spno'=1
  by `idvar': replace `spno' = `spno'[_n-1]+(`state'!=`state'[_n-1]) if _n>1
  sort `idvar' `spno' `l'
  by `idvar' `spno': gen mark = _N==_n
  keep if mark
  drop if `state'==-1
  drop mark
  by `idvar': gen `nspells'=_N
  gen `length' = `l'
  by `idvar': replace `length' = `l' - `l'[_n-1] if _n>1
  drop `l'
  rename `state' `spellvar'
  order `spellvar' `length'
  reshape wide `spellvar' `length', i(`idvar') j(`spno')
  sort `idvar'

  save `workfile'

  restore

  merge 1:1 `idvar' using `workfile'
  drop _merge

  su `nspells'
}
return scalar maxspells = r(max)

end
