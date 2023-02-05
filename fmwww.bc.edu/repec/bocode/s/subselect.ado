*! Part of package matrixtools v. 0.30
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2022-06-20 > generate + replace
*! 2022-06-20 > using(use) + clear
*! 2022-06-20 > keep/drop (generate optional)
*! 2022-06-20 > varlist instead of varlist
*! 2022-02-10 > Recoded using Stata code instead of nhb_sae_subselect()
* 2018-08-21 > Added

*TODO short name sbs
*TODO first/last _n?
*TODO edit/browse
*TODO Ngt(#)

*compare to -tag- and -duplicates tag- in help

program define subselect
	syntax varlist [if] [in] [using], ///
    [Generate(name) Clear Replace Negate Keep Drop]
    
	if `"`keep'`drop'`generate'"' == "" ///
    mata: _error("One of the options keep, drop or generate must be set")
    
  if `"`using'"' != "" use * `using', `clear'
  
  tempname slct
  sbs `varlist' `if' `in', generate(`slct')
  if "`negate'" != "" replace `slct' = !`slct'
  
  if "`keep'" != "" keep if `slct'
  else if "`drop'" != "" drop if `slct'
  else if "`generate'" != "" {
    if "`replace'" != "" drop `generate'
    generate `generate' = `slct'
  }
end

program define sbs, sortpreserve
	syntax varlist [if] [in], Generate(name)
  quietly {
    mark `generate' `if' `in'
    bysort `varlist' (`generate'): replace `generate' = `generate'[_N]  
  }
end