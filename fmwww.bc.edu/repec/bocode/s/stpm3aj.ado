*! version 0.5 2024-04-24
program define stpm3aj, rclass
  version 16.1
  syntax [anything], crmodels(string) [cif *]
  if "`cif'" == "" local addcif cif
  stpm3km `0' `addcif'
end