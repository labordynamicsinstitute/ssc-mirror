program define stpm3quadchk,
  version 16.0
  syntax anything, [SURVival HAZard]
  numlist "`anything'" , ascending  integer  sort
  local newnodes `r(numlist)'
  local Nnodes = wordcount("`newnodes'")
  tempname  origmodel origbeta S_orig h_orig
  
  est store `origmodel'
  local orignodes `e(nodes)'
  matrix `origbeta' = e(b)'
  local lloriginal  = e(ll)
  if "`survival'" != "" predict `S_orig', survival
  if "`hazard'"   != "" predict `h_orig', hazard
  local matnames `""`e(nodes)' nodes""'
  
  local cmd2 = "`e(cmdline)'"
  local 0 `cmd2'
  syntax [anything], [NODEs(string) *]
  local has_nodes_option = "`nodes'"!="" 
 
  foreach k in `newnodes' {
    if `has_nodes_option' {
      local stpm3cmd = "stpm3 " + subinstr("`cmd2'","nodes(`orignodes')","nodes(`k')",1)
    }
    else {
      local stpm3cmd = "stpm3 " + "`cmd2' nodes(`k')"
    }
    di as input "Fitting model with `k' nodes"
    capture `stpm3cmd'
    if _rc {
      di "Model with `k' knots did not fit"
      est restore `origmodel'
      exit 198
    }
    tempname model`k' beta`k' S`k' h`k'
    est store `model`k''
    matrix `beta`k'' = e(b)'
    local ll_model`k' = e(ll)
    if "`survival'" != "" predict `S`k'', survival
    if "`hazard'" != ""   predict `h`k'', hazard
    local modellist `modellist' `model`k''
    local matnames `"`matnames' "`k' nodes""'
  }
  
  
  tempname likelihoods likelihoods_reldif 
  tempname betas betas_reldif
  
  mata: stpm3_quadcalc()
  
  di as result _newline "Compare likelihoods"
  matrix colnames `likelihoods' = `matnames'
  matrix rownames `likelihoods' = "ll" "rel diff"
  matlist `likelihoods', noblank
  
  di as result _newline "Compare betas"
  matrix colnames `betas' = `matnames'  
  local betanames: colfullnames e(b)
  matrix rownames `betas' = `betanames'  
  matlist `betas', noblank 
  
  di as result _newline "Betas (relative differences)"
  matrix colnames `betas_reldif' = `matnames'  
  matrix rownames `betas_reldif' = `betanames'  
  matlist `betas_reldif', noblank 
 
  
  if "`survival'" != "" {
    local j 1
    foreach k in `newnodes' {
      tempname Sdiff`k'
      qui gen `Sdiff`k'' = `S`k'' - `S_orig'
      local Sdifflist `Sdifflist' `Sdiff`k''
      local Slegend `"`Slegend' `j' "`k' Nodes" "'
      local ++j
    }
    twoway (scatter `Sdifflist' _t, msize(tiny..)),       ///
           ytitle("Difference in survival probability") ///
           legend(order(`Slegend'))                     ///
           caption("Original model: `orignodes' nodes") ///
           name(quadchk_survival, replace)
  }
  
  if "`hazard'" != "" {
    local j 1
    foreach k in `newnodes' {
      tempname hdiff`k'
      qui gen `hdiff`k'' = `h`k'' - `h_orig'
      local hdifflist `hdifflist' `hdiff`k''
      local hlegend `"`hlegend' `j' "`k' Nodes" "'
      local ++j
    }
    twoway (scatter `hdifflist' _t,  msize(tiny..)),      ///
           ytitle("Difference in hazard rates")         ///
           legend(order(`hlegend'))                     ///
           caption("Original model: `orignodes' nodes") ///
           name(quadchk_hazard, replace)
  }
    
  qui est restore `origmodel'

end 

mata:
void function stpm3_quadcalc()
{
 
  ll_original  = strtoreal(st_local("lloriginal"))
  beta_original = st_matrix(st_local("origbeta"))
  N_newnodes   = strtoreal(st_local("Nnodes"))
  newnodes     = strtoreal(tokens(st_local("newnodes")))

  beta_new = J(rows(beta_original),N_newnodes,.)
  like_new = J(1,N_newnodes,.)
  for(k=1;k<=N_newnodes;k++) {
    beta_new[,k]  = st_matrix(st_local("beta"+strofreal(newnodes[k])))
    like_new[1,k] = strtoreal(st_local("ll_model"+strofreal(newnodes[k])))
  }
  
  // likelihood
  like_reldif = reldif((ll_original,like_new),J(1,N_newnodes+1,ll_original))
  st_matrix(st_local("likelihoods"),(ll_original,like_new \ like_reldif))
    
  betas = beta_original, beta_new
  st_matrix(st_local("betas"),betas)
  
  // betas reldif  
  betas_reldif = reldif(betas,J(1,N_newnodes+1,beta_original))
  st_matrix(st_local("betas_reldif"),betas_reldif)
  
}


end

