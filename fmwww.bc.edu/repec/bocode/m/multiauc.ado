*! version 1.0.0 06jan2025 Leonardo Guizzetti
program define multiauc, rclass
  version 17
  syntax varlist (min=3) [if] [in] , ///
        [ IDvar(varname numeric) ///
          CItype(string) ///
          level(cilevel) ///
          KEEPDvalues ///
          ONLYDvalues /// requires -keepdvalues-
          verbose ///     NOT DOCUMENTED
          testauc(real 0.5)     ///
          testdelta(real 0)     ///
        ]
        
  * check existence of dependency
  cap which moremata.hlp
  if _rc {
     di as err `"Please install package {it:moremata} from SSC in order to run this do-file;"' ///
               _newline "you can do so by clicking this link: " _c ///
               `"{stata "ssc install moremata":auto-install moremata}"'
      exit 199
  }
  
  marksample touse , novarlist
  gettoken grp xvars : varlist
  markout `touse' `grp'
    
  cap assert inlist(`grp', 0, 1) if `touse'
  if _rc {
    di as err "Group variable ({bf:`grp'}) must be binary valued (0/1)."
    exit 420
  }
  
  summ `touse', meanonly
  if r(sum)<=5 {
    di as err "Insufficient number of observations."
    exit 2001
  }

  * Check validity of options
  if "`idvar'"!="" {
    local id `idvar'
    cap isid `id'
    if _rc {
      di as err "ID variable ({bf: `id'}) must uniquely identify observations."
      exit 198
    }
  }
  else {
    tempname pseudoid
    local id `pseudoid'
    qui gen `c(obs_t)' `id' = _n
  }
  
  if `"`citype'"'==`""' {
    local citype "logit"
  }
  if !inlist(`"`citype'"', "logit", "atanh", "normal") {
    do as err "Option {bf:citype()} must only be one of: {bf:logit}, {bf:atanh} or {bf:normal}."
    exit 198
  }
  
  if "`verbose'"=="" {
    local q quietly
  } 
  else {
    local q noisily
  }
  
  if !inrange(`testauc', 0.5, 1) {
    di as err "The null hypothesis test value for AUC has a default value of 0.5, and must be between 0.5 and 1."
    exit 198
  }

  if !inrange(`testdelta', -1, 1) {
    di as err "The null hypothesis test value for AUC differences has a default value of 0, and must be between -1 and 1."
    exit 198
  }

  local origframe = c(frame)

  local alpha = 1-(1-`level'/100)/2

  parse_dvars `varlist'
  local grp = s(group)
  local xvars = s(xvars)
  local dvals = s(dvals)
  local nscores = s(nscores)
  
  * names for returned result matrices
  tempname Nobs B_auc V_auc SE_auc CI_auc Pval_auc B_delta SE_delta CI_delta Pval_delta
  
  * save total estimation sample size per score
  mata: calc_N("`grp'", "`xvars'", "`touse'", "`Nobs'")
  
  * calculate D-values and push into temp frame -work-
  tempname work
  tempname D
  mata: `D' = calc_dvalues("`grp'", "`xvars'", "`touse'")
  frame put `id' `grp' if `touse', into(`work')
  mata: save_dvalues("`work'", `D')
  mata: mata drop `D'
    
  if "`onlydvalues'"=="onlydvalues" & "`keepdvalues'"!="keepdvalues" {
    cap cwf `origframe'
    di as err "Option -onlydvalues- must be used with -keepdvalues-."
    exit 198
  }
  
  if "`keepdvalues'"=="keepdvalues" {
    cap frame drop _Dvalues
    frame copy `work' _Dvalues
    frame _Dvalues: sort `grp' `id'
  }
  
  if "`onlydvalues'"=="onlydvalues" {
    cap cwf `origframe'
    exit
  }

  * now the MVN model can be fit
  qui reshape long dval , i(`id') j(score)
  cap `q' mixed dval i.`grp'##i.score || `id' :, nocons ///
                  reml dfmethod(kr) resid(un, by(`grp') t(score))
  if _rc | `e(converged)'==0 {
    di as err "convergence not achieved"
    exit 430
  }
  
  * and the relevant non-linear combinations for AUC estimates and VCE matrix obtained
  forval i = 1/`nscores' {
    local nlcombolist `nlcombolist' (score`i': _b[1.`grp'] + _b[1.`grp'#`i'.score])
  }
  `q' nlcom `nlcombolist', post
  
  mata: extract_auc("`B_auc'", "`V_auc'")
  mata: get_SE_from_V("`V_auc'", "`SE_auc'")
  ereturn clear // discard residual nlcom results
    
  mata: calc_auc_ci("`citype'", `alpha', "`B_auc'", "`V_auc'", "`CI_auc'", `testauc', "`Pval_auc'")
    
  mata: calc_deltas("`B_auc'", "`V_auc'", `alpha', "`B_delta'", "`SE_delta'", "`CI_delta'", ///
                    `testdelta', "`Pval_delta'")
  
  ** Print results to screen  
/*
    5   10   15   20   25   30   35   40   45   50   55   60   65   70   75
++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++
*/
  _disp_header `grp' `nscores' "`xvars'"

  _disp_line 11 "{c TT}" 53
  di in smcl as txt _col(11) " {c |}" _c
  if "`citype'"=="normal" {
    di _col(52) "Normal"
  }
  else if "`citype'"=="logit" {
    di _col(53) "Logit"
  }
  else if "`citype'"=="atanh" {
    di _col(41) "Fisher's Z (atanh)"
  }
  
  di in smcl as txt "Score" _col(11) " {c |}" ///
                    _col(14) %7s "Obs" ///
                    _col(24) %6s "AUC" ///
                    _col(32) %9s "Std. err." ///
                    _col(42) %24s "[`level'% conf. interval]"  
  _disp_line 11 "{c +}" 53

  forval i = 1/`nscores' {
    local x_i : word `i' of `xvars'
    local n_i = `Nobs'[`i',1]
    local est_i = `B_auc'[`i',1]
    local se_i = `SE_auc'[`i',1]
    local ll_i = `CI_auc'[`i',1]
    local ul_i = `CI_auc'[`i',2]
    _disp_auc "`x_i'" `n_i' `est_i' `se_i' `ll_i' `ul_i'
  }
  _disp_line 11 "{c BT}" 53
  
  di in smcl as txt _n "Differences between AUCs"  
  _disp_line 14 "{c TT}" 44
  di in smcl as txt _col(14) " {c |}" ///
                    _col(41) "Fisher's Z (atanh)"
  di in smcl as txt _col(14) " {c |}" ///
                    _col(16) %8s "Delta" ///
                    _col(26) %9s "Std. err." ///
                    _col(36) %24s "[`level'% conf. interval]"
  _disp_line 14 "{c +}" 44
  forval i = 1/`: rowsof `B_delta'' {
    local x_i : word `i' of `: rownames `B_delta''
    local est_i = `B_delta'[`i',1]
    local se_i = `SE_delta'[`i',1]
    local ll_i = `CI_delta'[`i',1]
    local ul_i = `CI_delta'[`i',2]
    _disp_delta "`x_i'" `est_i' `se_i' `ll_i' `ul_i'
  }
  _disp_line 14 "{c BT}" 44
  
  * finally return results
  * macros
  return local delta_citype = "atanh"
  return local auc_citype = "`citype'"
  return local scores = `"`xvars'"'
  return local group = "`grp'"
  
  return scalar test_delta = `testdelta'
  return scalar test_auc = `testauc'
  return scalar level = `level'
  
  return matrix pvalue_delta = `Pval_delta'
  return matrix CI_delta = `CI_delta'
  return matrix SE_delta = `SE_delta'
  return matrix delta = `B_delta'
  
  matrix colnames `Pval_auc' = "pvalue"
  matrix rownames `Pval_auc' = `xvars'
  return matrix pvalue_auc = `Pval_auc'
  
  matrix rownames `CI_auc' = `xvars'
  return matrix CI_auc = `CI_auc'
  
  matrix colnames `SE_auc' = "se"
  matrix rownames `SE_auc' = `xvars'
  return matrix SE_auc = `SE_auc'
  
  matrix colnames `V_auc' = `xvars'
  matrix rownames `V_auc' = `xvars'
  return matrix V_auc = `V_auc'
  
  matrix colnames `B_auc' = "auc"
  matrix rownames `B_auc' = `xvars'
  return matrix auc = `B_auc'
  
  matrix rownames `Nobs' = `xvars'
  matrix colnames `Nobs' = "N"
  return matrix N_obs = `Nobs'
  
  cwf `origframe'
end


program parse_dvars, sclass
  syntax namelist
  gettoken grp xvars : namelist
  local group `grp'
  local xvars `xvars'
  local nscores : word count `xvars'
  
  local i = 0
  foreach v in `xvars' {
    local ++i
    local dvals `dvals' dval`i'
  }
  local nscores `i'

  sret local group = "`group'"
  sret local xvars = "`xvars'"
  sret local nscores = `nscores'
  sret local dvals = "`dvals'"
end


program _disp_header
  args group nscores xvarlist
  di as txt "Comparison of multiple correlated AUCs" _n
  di as txt "Group variable:" _col(20) as res "`group'" _n ///
     as txt "Scores:" _col(20) as res "`nscores'" _n ///
     as txt "Score variables:" _col(20) as res "`xvarlist'"
end


program _disp_auc
  args name nobs est se ll ul

  local name = bsubstr("`name'", 1, 10)
  di in smcl as txt %10s "`name'" ///
                    _col(11) " {c |}" ///
             as res _col(14) %7.0f `nobs' ///
                    _col(24) %6.3f `est' ///
                    _col(34) %6.3f `se' ///
                    _col(49) %6.3f `ll' ///
                    _col(60) %6.3f `ul'
end


program _disp_delta
  args name est se ll ul

  local name = bsubstr("`name'", 1, 12)
  di in smcl as txt %13s "`name'" ///
                    _col(14) " {c |}" ///
             as res _col(18) %6.3f `est' ///
                    _col(28) %6.3f `se' ///
                    _col(43) %6.3f `ll' ///
                    _col(54) %6.3f `ul'
end


program _disp_line
  args left div right
  di in smcl as txt "{hline `left'}`div'{hline `right'}"
end


* define helpful shorthand macros for Mata types
local RS real scalar
local RM real matrix
local RCV real colvector
local RRV real rowvector
local RV real vector

local SS string scalar
local SV string vector
local SM string matrix

mata:

/***************************************************************************************************
**# calc_dvalues()

Calculate D-values given the group identifier, X variable(s) represent scores, and any sample 
restriction by if/in.
***************************************************************************************************/
`RM' calc_dvalues(`SS' grp, `SV' xvars, `SS' touse) {
  `RS'  i
  `RCV' G
  `RM'  X, N01, ORank, GRank, Dvals, Res
  
  G = st_data(., grp, touse)
  X = st_data(., xvars, touse)
  
  N01 = J(2, cols(X), .)
  N01 = colsum((X:<.) :& G:==0) \  ///
        colsum((X:<.) :& G:==1)
  
  ORank = J(rows(X), cols(X), .)
  GRank = J(rows(X), cols(X), .)
  Dvals = J(rows(X), cols(X), .)
  
  for (i=1; i<=cols(X); i++) {
    ORank[selectindex((X[.,i]:<.)), i]          = mm_ranks(X[selectindex((X[.,i]:<.)), i], 1, 2)
    GRank[selectindex((X[.,i]:<.) :& G:==1), i] = mm_ranks(X[selectindex((X[.,i]:<.) :& G:==1), i], 1, 2)
    GRank[selectindex((X[.,i]:<.) :& G:==0), i] = mm_ranks(X[selectindex((X[.,i]:<.) :& G:==0), i], 1, 2)
  }
  Dvals = ORank - GRank
  Dvals[selectindex(G:==1),.] = Dvals[selectindex(G:==1),.] :/ N01[1,.]
  Dvals[selectindex(G:==0),.] = Dvals[selectindex(G:==0),.] :/ N01[2,.]

  Res = Dvals
  return(Res)
}


/***************************************************************************************************
**# calc_N()

Return the total sample size for each score in the estimation sample
***************************************************************************************************/
void calc_N(`SS' grp, `SV' xvars, `SS' touse, `SS' nobs_mat) {
  `RS'  i
  `RCV' G, Which
  `RM'  X, Nobs
  G = st_data(., grp, touse)
  X = st_data(., xvars, touse)
  Which = (X:<.) :& (G:==0 :| G:==1)
  Nobs = colsum(Which)'
  st_matrix(nobs_mat, Nobs)
}


/***************************************************************************************************
**# save_dvalues()

Save matrix of D-values to an existing target frame
***************************************************************************************************/
void save_dvalues(`SS' outframe, `RM' Dvalues) {
  `SV' Dvalnames
  st_framecurrent(outframe)
  Dvalnames = "dval" :+ strofreal((1..cols(Dvalues)))
  (void) st_addvar("double", Dvalnames)
  st_store(., Dvalnames, Dvalues)
}


/***************************************************************************************************
**# extract_auc()

Extracts AUC values and variance-covariance matrix V of scores.
b, V matrices returned to Stata.
***************************************************************************************************/
void extract_auc(`SS' b_auc_mat, `SS' V_auc_mat) {
  `RV'  Bnl, B
  `RM'  V
  Bnl = st_matrix("e(b)")
  B = Bnl:/2 :+ 0.5
  V = st_matrix("e(V)")
  st_matrix(b_auc_mat, B')
  st_matrix(V_auc_mat, V)
}


/***************************************************************************************************
**# calc_auc_ci()

Compute CI for AUC estimates.
***************************************************************************************************/
void calc_auc_ci(`SS' citype, `RS' level, `SS' b_auc_mat, `SS' V_auc_mat, `SS' ci_mat, `RS' testval, `SS' pval_mat) {
  `RS'  z_a
  `RCV'  B, Z, Pval
  `RM'  V, CI
  `SM'  ci_colstripe

  z_a = invnormal(level)
  B = st_matrix(b_auc_mat)
  V = st_matrix(V_auc_mat)
  
  CI = J(rows(V), 2, .)
  
  if (citype=="logit") {
    CI = invlogit( logit(B) :- sqrt(diagonal(V)) :* z_a :/ (B:*(1 :- B)) ) , ///
         invlogit( logit(B) :+ sqrt(diagonal(V)) :* z_a :/ (B:*(1 :- B)) )
  }
  else if (citype=="atanh") {
    CI = tanh( atanh(B) :- sqrt(diagonal(V)) :* z_a :/ (1 :- (B):^2 ) ) , ///
         tanh( atanh(B) :+ sqrt(diagonal(V)) :* z_a :/ (1 :- (B):^2 ) )
    
  }
  else if (citype=="normal") {
    CI = B :- sqrt(diagonal(V)) :* z_a , ///
         B :+ sqrt(diagonal(V)) :* z_a
  }
  
  Z = J(rows(B), 1, .)
  Pval = J(rows(B), 1, .)
  Z = (B :- testval) :/ sqrt(diagonal(V))
  Pval = 2*(normal(-abs(Z)))
  
  ci_colstripe = J(2, 1, "") , ("ll"\"ul")
  st_matrix(ci_mat, CI)
  st_matrixcolstripe(ci_mat, ci_colstripe)
  
  st_matrix(pval_mat, Pval)
}


/***************************************************************************************************
**# get_SE_from_V()

Utlity function to extract variances and convert to row vector containing standard errors.
***************************************************************************************************/
void get_SE_from_V(`SS' V_mat, `SS' SE_mat) {
  `RM'   V
  `RRV'  SE
  V = st_matrix(V_mat)
  SE = sqrt(diagonal(V))
  st_matrix(SE_mat, SE)
}


/***************************************************************************************************
**# calc_deltas()

Compute estimates, SE and CI of AUC differences
***************************************************************************************************/
void calc_deltas(`SS' b_auc_mat, `SS' V_auc_mat, `RS' level, `SS' b_delta_mat, ///
                 `SS' se_delta_mat, `SS' ci_delta_mat, `RS' testval, `SS' pval_mat) {
  `RRV'  B_auc
  `RM'   V_auc
  `RS'   z_a
  `RS'   n_scores,  i,  j,  pair_i
  `RCV'  B_delta, SE_delta, Z, Pval
  `RM'   CI_delta
  `SM'   bse_rowstripe, ci_colstripe, ci_rowstripe
  `SV'   delta_names

  z_a = invnormal(level)
  B_auc = st_matrix(b_auc_mat)
  V_auc = st_matrix(V_auc_mat)
  
  n_scores = cols(V_auc)
  n_pairs = n_scores * (n_scores-1) / 2
  
  B_delta = J(n_pairs, 1, .)
  SE_delta = J(n_pairs, 1, .)
  delta_names = J(n_pairs, 1, "")

  pair_i = 0
  for (i=1; i <= n_scores; i++) {
    for (j=1; j <= n_scores; j++) {
      if (i<j) {
        pair_i++
        delta_names[pair_i] = "Delta" :+ "(" :+ strofreal(i) :+ "-" :+ strofreal(j) :+ ")"
        B_delta[pair_i] = B_auc[i] - B_auc[j]
        SE_delta[pair_i] = sqrt(V_auc[i,i] + V_auc[j,j] - 2*V_auc[i,j])
      }
    }
  }
  
  // Note: Fisher Z (atanh) transformation only for deltas
  CI_delta = tanh( atanh(B_delta) :- SE_delta :* z_a :/ (1 :- (B_delta):^2 ) ) , ///
             tanh( atanh(B_delta) :+ SE_delta :* z_a :/ (1 :- (B_delta):^2 ) )
  
  Z = J(rows(B_delta), 1, .)
  Pval = J(rows(B_delta), 1, .)
  Z = (B_delta :- testval) :/ SE_delta
  Pval = 2*(normal(-abs(Z)))
  
  bse_rowstripe = J(n_pairs, 1, "") , delta_names
  st_matrix(b_delta_mat, B_delta)
  st_matrixcolstripe(b_delta_mat, ("", "Delta"))
  st_matrixrowstripe(b_delta_mat, bse_rowstripe)

  st_matrix(se_delta_mat, SE_delta)
  st_matrixcolstripe(se_delta_mat, ("", "se"))
  st_matrixrowstripe(se_delta_mat, bse_rowstripe)

  ci_colstripe = J(2, 1, "") , ("ll"\"ul")
  ci_rowstripe = J(n_pairs, 1, "") , delta_names
  st_matrix(ci_delta_mat, CI_delta)
  st_matrixcolstripe(ci_delta_mat, ci_colstripe)
  st_matrixrowstripe(ci_delta_mat, ci_rowstripe)
  
  pval_colstripe = ("", "pvalue")
  pval_rowstripe = J(n_pairs, 1, "") , delta_names
  st_matrix(pval_mat, Pval)
  st_matrixcolstripe(pval_mat, pval_colstripe)
  st_matrixrowstripe(pval_mat, pval_rowstripe)
}

end
exit

Changelog:
1.0.0 02dec2023 - initial version
