*! plssem2_predict version 1.0.0
*! predict after plssem2 (PLS-SEM): latent variable (composite) scores
*! Authors: WU Lianghai (AHUT) & WU Hanyan (CityU), 19 August 2026

program plssem2_predict
  version 15.1
  /* note: this Stata 18 build does not parse `syntax [type] newvarlist`
     correctly (newvarlist comes back empty / invalid syntax), so the new
     variable names are collected with namelist */
  syntax namelist(min=1) [if] [in] [, lv(string) ]

  if "`e(cmd)'" != "plssem2" {
    display as error "last estimates not found; run plssem2 first"
    exit 301
  }

  if "`lv'" == "" {
    local lv `e(lvs)'
  }
  else {
    /* validate the requested LV names */
    local alllvs `e(lvs)'
    foreach l of local lv {
      if !`: list l in alllvs' {
        display as error "`l' is not a latent variable of the model"
        exit 198
      }
    }
  }
  local nlv : list sizeof lv
  local newvarlist `namelist'
  local nnew : list sizeof newvarlist
  if `nlv' != `nnew' {
    display as error "number of new variables must equal the number of latent variables requested"
    display as error "requested LVs: `lv'"
    exit 198
  }

  tempname scores
  matrix `scores' = e(scores)
  tempvar touse
  quietly generate byte `touse' = e(sample)
  if "`if'`in'" != "" {
    marksample touse2, novarlist
    quietly replace `touse' = 0 if !`touse2'
  }
  local lvlist `e(lvs)'
  local j = 0
  foreach l of local lv {
    local ++j
    local col : list posof "`l'" in lvlist
    gettoken newvar newvarlist : newvarlist
    quietly generate double `newvar' = .
    mata: st_store(selectindex(st_data(., "`touse'")), "`newvar'", st_matrix("`scores'")[., `col'])
    label variable `newvar' "PLS-SEM score of latent variable `l'"
  }
  display as text "(`nlv' latent-variable score(s) generated)"
end
