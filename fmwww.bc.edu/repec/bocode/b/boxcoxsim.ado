* for test of ros command 
*capture program drop boxcoxsim
program define boxcoxsim, rclass
  version 12
  syntax, [n(integer 200) Mean(real 4) SD(real 1) Theta(real 1) nd(integer 0) ///
    Outlierpct(real 0) OMean(real 10) OSD(real 2) OTheta(real 1) ///
    Fmt(string) Percentiles(numlist >0 <100 sort) Clear]
    
  if "`fmt'" == "" local fmt "%6.2f"
  if "`percentiles'" == "" local percentiles 50 75 90 95 99
  `clear'
  if `n' > _N qui set obs `n'
  tempname nrm1 nrm2
  
  if `sd' <= 0 mata: _error("sd must be positive")
  if `nd' < 0 mata: _error("nd must be non-negative")
  if `mean' < 4 * `sd' {
    local mean = 4 * `sd'
    display as error "Mean is reset to 4 times SD"
  }
  qui generate `nrm1' = rnormal(`mean', `sd')
  if "`theta'" == "0" qui replace `nrm1' = exp(`nrm1')
  else qui replace `nrm1' = `nrm1' ^ `theta' / abs(`theta')
  
  if !inrange(`outlierpct', 0, 100) mata: _error("Outlierpct must be between 0 and 100")
  else local outlierpct = `outlierpct' / 100
  if `outlierpct' > 0 {
    if `osd' <= 0 mata: _error("osd must be positive")
    if `omean' < 4 * `osd' {
      local omean = 4 * `osd'
      display as error "OMean is reset to 4 times OSD"
    }    
    qui generate `nrm2' = rnormal(`omean', `osd')
    if "`otheta'" == "0" qui replace `nrm2' = exp(`nrm2')
    else qui replace `nrm2' = `nrm2' ^ `otheta' / abs(`otheta')
    *generate y = cond(runiform(0,1) < `= 1 - `outlierpct'', `nrm1', `nrm2')
	generate y = cond(runiform() < `= 1 - `outlierpct'', `nrm1', `nrm2')
  }
  else generate y = `nrm1'
  
  qui centile y, centile(`nd')
  qui g censored = (y <= r(c_1))
  qui g yc = cond(censored, r(c_1), y)
  label variable censored "Non-detects = `nd'%"
  format y yc `fmt'
  
  tempname pcts
  local rnms
  local np : word count `percentiles'
  forvalues j = 1/`np' {
    local p : word `j' of `percentiles'
    local rnms  `rnms' P`p'%
    quietly centile y, centile(`p')
    matrix `pcts' = nullmat(`pcts') \ r(c_1)
    return scalar y_percentile`=subinstr("`p'", ".", "c", .)' = r(c_1)
  }
  matrix rownames `pcts' = `rnms'
  matrix colnames `pcts' = Percentiles(y)
  matprint `pcts', title(`ttl')
  if `outlierpct' > 0 return scalar omean = `omean'
  if `outlierpct' > 0 return scalar osd = `osd'
  if `outlierpct' > 0 return scalar otheta = `otheta'
  return scalar outlierpct = `outlierpct'
  return scalar non_detects_pct = `nd'
  return matrix percentiles = `pcts'
  return scalar n = `n'
  return scalar mean = `mean'
  return scalar sd = `sd'
  return scalar theta = `theta'
end
