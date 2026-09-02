*! plssem2 version 1.0.0
*! Partial least squares structural equation modeling (PLS-SEM)
*! Written 19 August 2026
*!
*! Developed on the basis of:
*!   - Stata official programs sem.ado and gsem.ado (syntax conventions,
*!     eclass/estat/predict structure, stored results)
*!   - plssem.ado (Venturini & Mehmetoglu 2019, v0.6.1) (PLS algorithm,
*!     block syntax, weighting schemes)
*!   - Wold (1975), Lohmoller (1989), Chin (1998), Henseler et al. (2015)
*!     [HTMT], Stone (1974) / Geisser (1974) [blindfolding Q2], Efron
*!     (1987) [BCa bootstrap], Henseler et al. (2016) [permutation MGA],
*!     Becker et al. (2012) [higher-order constructs, two-stage approach]
*!
*! Authors:
*!   WU Lianghai
*!   School of Business, Anhui University of Technology (AHUT)
*!   Ma'anshan, Anhui, China
*!   agd2010@yeah.net
*!
*!   WU Hanyan
*!   Department of Accountancy, City University of Hong Kong (CityU)
*!   2325476320@qq.com
*!
*! License: MIT. This program is provided for research purposes.
*! This is an independent implementation of the PLS-SEM algorithm; it is
*! not affiliated with StataCorp or with the authors of plssem.

program plssem2, eclass byable(onecall)
  version 15.1
  syntax [anything(name=blocks)] [if] [in] [, * ]

  if replay() {
    if "`e(cmd)'" != "plssem2" {
      error 301
    }
    if _by() {
      error 190
    }
    Display, `options'
    exit
  }

  if _by() {
    local BY "by `_byvars' `_byrc0':"
  }
  if (_caller() < 8) {
    local version : display "version " string(_caller()) ", missing :"
  }
  else {
    local version : display "version " string(_caller()) " :"
  }

  local isgroup = strpos(`"`options'"', "gr")
  if `isgroup' {
    if _by() {
      display as error "the 'group()' option is not allowed with by"
      exit 198
    }
    `version' Compare `0'
  }
  else {
    `version' `BY' Estimate `0'
  }
end

/* ---------------------------------------------------------------------- */
/* Estimate: parse the model and run the PLS algorithm                     */
/* ---------------------------------------------------------------------- */
program Estimate, eclass byable(recall)
  version 15.1
  syntax anything(id="Measurement model" name=blocks) [if] [in], ///
    [ STRuctural(string) Wscheme(string) ///
    BOot(numlist integer >0 max=1) SEed(numlist max=1) ///
    Tol(real 1e-7) MAXiter(integer 100) ///
    INIT(string) DIGits(integer 3) Level(cilevel) ///
    noHEADer noMEAStable noDISCRIMtable noSTRUCTtable ///
    BLINDfold(integer 0) BCA noJACK ///
    HIGHER(string) STATs ///
    RAWsum noSCale CONVcrit(string) ///
    noHTMT noCLEANup ]

  local cmdline : list clean 0
  local cmdline `"`cmdline'"'

  /* ------------------------- defaults -------------------------------- */
  if "`wscheme'" == "" {
    local wscheme "path"
  }
  if !inlist("`wscheme'", "centroid", "factorial", "path") {
    display as error "wscheme() must be 'centroid', 'factorial', or 'path'"
    exit 198
  }
  if "`init'" == "" {
    local init "indsum"
  }
  if !inlist("`init'", "indsum", "eigen") {
    display as error "init() must be 'indsum' or 'eigen'"
    exit 198
  }
  if "`convcrit'" == "" {
    local convcrit "relative"
  }
  if !inlist("`convcrit'", "relative", "square", "absolute") {
    display as error "convcrit() must be 'relative', 'square', or 'absolute'"
    exit 198
  }
  if "`seed'" != "" {
    set seed `seed'
  }
  local level = `level'

  /* ------------------------- parse blocks ---------------------------- */
  local blist `blocks'
  local k = 0
  local allindicators ""
  local alllatents ""
  while "`blist'" != "" {
    gettoken block blist : blist, match(paren)
    if "`block'" == "" {
      continue
    }
    gettoken lv block : block
    gettoken arrow block : block
    if !inlist("`arrow'", ">", "<") {
      display as error "block syntax: (LV > indicators) reflective or (LV < indicators) formative"
      exit 198
    }
    if "`block'" == "" {
      display as error "latent variable `lv' has no indicators"
      exit 198
    }
    capture confirm name `lv'
    if _rc {
      display as error "`lv' is not a valid latent-variable name"
      exit 198
    }
    unab inds : `block'
    foreach v of varlist `inds' {
      capture confirm numeric variable `v'
      if _rc {
        display as error "indicator `v' is not a numeric variable"
        exit 198
      }
    }
    local ++k
    local lv`k' `lv'
    local arrow`k' `arrow'
    local ind`k' `inds'
    local allindicators `allindicators' `inds'
    local alllatents `alllatents' `lv'
  }
  if `k' < 2 {
    display as error "at least two latent variables are required"
    exit 198
  }

  /* duplicate LV names? */
  local chk ""
  foreach lv of local alllatents {
    if `: list lv in chk' {
      display as error "duplicate latent variable name: `lv'"
      exit 198
    }
    local chk `chk' `lv'
  }

  /* ------------------------- mark sample ----------------------------- */
  marksample touse
  markout `touse' `allindicators'
  count if `touse'
  local n = r(N)
  if `n' < 3 {
    display as error "not enough observations"
    exit 2001
  }

  /* ------------------------- higher-order ---------------------------- */
  /* higher("HO1: comp1a comp1b [ , mode(reflective|formative) ]"        */
  /*        ["HO2: comp2a comp2b [ , mode(...) ]] ...)                   */
  /* multiple higher-order constructs separated by ";"                   */
  local k_ho = 0
  if "`higher'" != "" {
    local hwork `higher'
    while strlen(`"`hwork'"') > 0 {
      local semi = strpos(`"`hwork'"', ";")
      if `semi' == 0 {
        local hpart `hwork'
        local hwork ""
      }
      else {
        local hpart = substr(`"`hwork'"', 1, `semi' - 1)
        local hwork = substr(`"`hwork'"', `semi' + 1, .)
      }
      local hpart : list clean hpart
      if "`hpart'" == "" {
        continue
      }
      gettoken hname hpart : hpart, parse(":")
      gettoken colon hpart : hpart, parse(":")
      if "`colon'" != ":" {
        display as error "higher() must be specified as higher(\"HOname: lv1 lv2 ...\")"
        exit 198
      }
      capture confirm name `hname'
      if _rc {
        display as error "`hname' is not a valid latent-variable name"
        exit 198
      }
      /* hpart = "comp1 comp2" possibly followed by ", mode(...)" */
      local hcomp `hpart'
      local hmode "reflective"
      local comma = strpos(`"`hcomp'"', ",")
      if `comma' > 0 {
        local hmode = substr(`"`hcomp'"', `comma' + 1, .)
        local hcomp = substr(`"`hcomp'"', 1, `comma' - 1)
        local hmode : subinstr local hmode "mode" "" , all
        local hmode : subinstr local hmode "(" "" , all
        local hmode : subinstr local hmode ")" "" , all
        local hmode : list clean hmode
      }
      local hcomp : list clean hcomp
      if !inlist("`hmode'", "reflective", "formative") {
        display as error "higher-order mode must be 'reflective' or 'formative'"
        exit 198
      }
      if "`hcomp'" == "" {
        display as error "higher-order construct `hname' has no components"
        exit 198
      }
      foreach c of local hcomp {
        if !`: list c in alllatents' {
          display as error "higher-order component `c' is not a latent variable of the model"
          exit 198
        }
      }
      if `: list hname in alllatents' {
        display as error "higher-order latent variable `hname' must not appear in the measurement blocks"
        exit 198
      }
      local ++k_ho
      local honame_ho`k_ho' `hname'
      local hcomp_ho`k_ho' `hcomp'
      local hmode_ho`k_ho' `hmode'
      local alllatents `alllatents' `hname'
    }
    if `k_ho' == 0 {
      display as error "no valid higher-order specification found in higher()"
      exit 198
    }
  }
  local k_lv = `k' + `k_ho'

  /* ------------------------- structural model ------------------------ */
  /* structural(dep1 preds, dep2 preds)                                  */
  /* equations are separated by commas; parentheses, if used, are        */
  /* ignored                                                            */
  local slist `structural'
  local nstruct = 0
  local endolist ""
  while strlen(`"`slist'"') > 0 {
    local comma = strpos(`"`slist'"', ",")
    if `comma' == 0 {
      local eq `slist'
      local slist ""
    }
    else {
      local eq = substr(`"`slist'"', 1, `comma' - 1)
      local slist = substr(`"`slist'"', `comma' + 1, .)
    }
    local eq : subinstr local eq "(" " " , all
    local eq : subinstr local eq ")" " " , all
    local eq : list clean eq
    if "`eq'" == "" {
      continue
    }
    gettoken dep eq : eq
    if !`: list dep in alllatents' {
      display as error "endogenous LV `dep' is not in the model"
      exit 198
    }
    foreach p of local eq {
      if !`: list p in alllatents' {
        display as error "predictor LV `p' is not in the model"
        exit 198
      }
    }
    local ++nstruct
    local sdep`nstruct' `dep'
    local spred`nstruct' `eq'
    local endolist `endolist' `dep'
  }
  local chk ""
  foreach e of local endolist {
    if !`: list e in chk' {
      local chk `chk' `e'
    }
  }
  local endolist `chk'

  /* ------------------------- build full matrices --------------------- */
  tempname adj_meas adj_struct modes
  local Q = 0
  foreach v of varlist `allindicators' {
    local ++Q
  }
  matrix `adj_meas' = J(`Q', `k_lv', 0)
  matrix rownames `adj_meas' = `allindicators'
  matrix colnames `adj_meas' = `alllatents'
  local jj = 0
  foreach v of varlist `allindicators' {
    local ++jj
    forvalues j = 1/`k_lv' {
      if `: list v in ind`j'' {
        matrix `adj_meas'[`jj', `j'] = 1
      }
    }
  }
  matrix `adj_struct' = J(`k_lv', `k_lv', 0)
  matrix rownames `adj_struct' = `alllatents'
  matrix colnames `adj_struct' = `alllatents'
  forvalues s = 1/`nstruct' {
    local dep = `"`sdep`s''"'
    local di = 0
    foreach lv of local alllatents {
      local ++di
      if "`lv'" == "`dep'" {
        foreach p of local spred`s' {
          local pi = 0
          foreach lvlv2 of local alllatents {
            local ++pi
            if "`lvlv2'" == "`p'" {
              matrix `adj_struct'[`di', `pi'] = 1
            }
          }
        }
      }
    }
  }
  matrix `modes' = J(1, `k_lv', 0)
  matrix colnames `modes' = `alllatents'
  forvalues j = 1/`k_lv' {
    if "`arrow`j''" == "<" {
      matrix `modes'[1, `j'] = 1
    }
  }

  local reflective ""
  local formative ""
  forvalues j = 1/`k_lv' {
    if "`arrow`j''" == "<" {
      local formative `formative' `lv`j''
    }
    else {
      local reflective `reflective' `lv`j''
    }
  }

  /* ------------------------- estimation ------------------------------ */
  tempname res converged niter
  tempname W L scores B R2 alpha cr ave lvcorr crossload htmt vif f2
  tempname btot bind bvec

  if `k_ho' {
    /* ============ two-stage approach (Becker et al. 2012) ============= */
    /* ---- stage 1: first-order model (all HO LVs removed) ------------- */
    /* the first k columns of the full matrices correspond to the        */
    /* first-order LVs (HO names are appended at the end of alllatents)  */
    local k_lv1 = `k'
    local alllatents1 ""
    forvalues j = 1/`k_lv1' {
      local alllatents1 `alllatents1' `: word `j' of `alllatents''
    }
    tempname adj_meas1 adj_struct1 modes1
    matrix `adj_meas1' = `adj_meas'[1..`Q', 1..`k_lv1']
    matrix rownames `adj_meas1' = `allindicators'
    matrix colnames `adj_meas1' = `alllatents1'
    matrix `adj_struct1' = `adj_struct'[1..`k_lv1', 1..`k_lv1']
    matrix rownames `adj_struct1' = `alllatents1'
    matrix colnames `adj_struct1' = `alllatents1'
    matrix `modes1' = `modes'[1, 1..`k_lv1']
    matrix colnames `modes1' = `alllatents1'
    tempname res1
    mata: `res1' = plssem2_estimate( ///
      st_data(., "`allindicators'", "`touse'"), ///
      st_matrix("`adj_meas1'"), ///
      st_matrix("`adj_struct1'"), ///
      st_matrix("`modes1'")', ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`wscheme'", ///
      "`convcrit'", ///
      "`init'", ///
      "`rawsum'", ///
      "`noscale'")
    /* stage-1 scores -> dataset variables (used as HO indicators) */
    tempname scores1
    mata: st_matrix("`scores1'", `res1'.scores)
    forvalues j = 1/`k_lv1' {
      local lv : word `j' of `alllatents1'
      capture confirm variable `lv'
      if !_rc {
        local lbl : variable label `lv'
        if "`lbl'" == "PLS-SEM score of `lv'" {
          quietly replace `lv' = .
        }
        else {
          display as error "variable `lv' already exists and is not a plssem2 score variable"
          exit 110
        }
      }
      else {
        quietly generate double `lv' = .
      }
      mata: st_store(selectindex(st_data(., "`touse'")), "`lv'", st_matrix("`scores1'")[., `j'])
      label variable `lv' "PLS-SEM score of `lv'"
    }
    /* ---- stage 2: full model, HO LVs measured by component scores ---- */
    local hoinds ""
    local qrow = `Q'
    local hoidx = `k_lv1'
    local ncomp = 0
    forvalues h = 1/`k_ho' {
      local ++hoidx
      local hn = `"`honame_ho`h''"'
      local hc = `"`hcomp_ho`h''"'
      foreach c of local hc {
        local ++qrow
        local ++ncomp
        local hoinds `hoinds' `c'
      }
      if "`hmode_ho`h''" == "formative" {
        matrix `modes'[1, `hoidx'] = 1
      }
    }
    local Q2 = `qrow'
    local k_lv2 = `k_lv'
    local alllatents2 `alllatents'
    tempname adj_meas2 adj_struct2 modes2 X2 res2
    matrix `adj_meas2' = J(`Q2', `k_lv2', 0)
    matrix rownames `adj_meas2' = `allindicators' `hoinds'
    matrix colnames `adj_meas2' = `alllatents2'
    forvalues q = 1/`Q' {
      forvalues j = 1/`k_lv' {
        matrix `adj_meas2'[`q', `j'] = `adj_meas'[`q', `j']
      }
    }
    local qrow = `Q'
    local hoidx = `k_lv1'
    forvalues h = 1/`k_ho' {
      local ++hoidx
      local hc = `"`hcomp_ho`h''"'
      foreach c of local hc {
        local ++qrow
        matrix `adj_meas2'[`qrow', `hoidx'] = 1
      }
    }
    matrix `adj_struct2' = `adj_struct'
    matrix rownames `adj_struct2' = `alllatents2'
    matrix colnames `adj_struct2' = `alllatents2'
    matrix `modes2' = `modes'
    matrix colnames `modes2' = `alllatents2'
    mata: `X2' = st_data(., "`allindicators'", "`touse'") , ///
      st_data(., "`hoinds'", "`touse'")
    mata: `res2' = plssem2_estimate( ///
      `X2', ///
      st_matrix("`adj_meas2'"), ///
      st_matrix("`adj_struct2'"), ///
      st_matrix("`modes2'")', ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`wscheme'", ///
      "`convcrit'", ///
      "`init'", ///
      "`rawsum'", ///
      "`noscale'")
    mata: st_numscalar("`converged'", `res2'.converged)
    mata: st_numscalar("`niter'", `res2'.niter)
    mata: st_matrix("`W'", `res2'.outer_weights)
    mata: st_matrix("`L'", `res2'.loadings)
    mata: st_matrix("`scores'", `res2'.scores)
    mata: st_matrix("`B'", `res2'.pathcoef)
    mata: st_matrix("`R2'", `res2'.r2)
    mata: st_matrix("`alpha'", `res2'.alpha)
    mata: st_matrix("`cr'", `res2'.cr)
    mata: st_matrix("`ave'", `res2'.ave)
    mata: st_matrix("`lvcorr'", `res2'.lvcorr)
    mata: st_matrix("`crossload'", `res2'.crossload)
    mata: st_matrix("`htmt'", `res2'.htmt)
    mata: st_matrix("`vif'", `res2'.vif)
    mata: st_matrix("`f2'", `res2'.f2)
    matrix rownames `W' = `allindicators' `hoinds'
    matrix colnames `W' = `alllatents2'
    matrix rownames `L' = `allindicators' `hoinds'
    matrix colnames `L' = `alllatents2'
    matrix rownames `B' = `alllatents2'
    matrix colnames `B' = `alllatents2'
    matrix rownames `R2' = "R2"
    matrix colnames `R2' = `alllatents2'
    matrix rownames `alpha' = "alpha"
    matrix colnames `alpha' = `alllatents2'
    matrix rownames `cr' = "CR"
    matrix colnames `cr' = `alllatents2'
    matrix rownames `ave' = "AVE"
    matrix colnames `ave' = `alllatents2'
    matrix rownames `lvcorr' = `alllatents2'
    matrix colnames `lvcorr' = `alllatents2'
    matrix rownames `crossload' = `allindicators' `hoinds'
    matrix colnames `crossload' = `alllatents2'
    matrix rownames `htmt' = `alllatents2'
    matrix colnames `htmt' = `alllatents2'
    matrix `adj_meas' = `adj_meas2'
    matrix `adj_struct' = `adj_struct2'
    matrix `modes' = `modes2'
    local alllatents `alllatents2'
    local allindicators `allindicators' `hoinds'
    local k_lv = `k_lv2'
    local Q = `Q2'
    /* generate the HO LV score variables */
    local hoidx = `k_lv1'
    forvalues h = 1/`k_ho' {
      local ++hoidx
      local hn = `"`honame_ho`h''"'
      capture confirm variable `hn'
      if !_rc {
        local lbl : variable label `hn'
        if "`lbl'" == "PLS-SEM score of `hn'" {
          quietly replace `hn' = .
        }
        else {
          display as error "variable `hn' already exists and is not a plssem2 score variable"
          exit 110
        }
      }
      else {
        quietly generate double `hn' = .
      }
      mata: st_store(selectindex(st_data(., "`touse'")), "`hn'", st_matrix("`scores'")[., `hoidx'])
      label variable `hn' "PLS-SEM score of `hn'"
    }
  }
  else {
    /* ================= single-stage estimation ======================= */
    mata: `res' = plssem2_estimate( ///
      st_data(., "`allindicators'", "`touse'"), ///
      st_matrix("`adj_meas'"), ///
      st_matrix("`adj_struct'"), ///
      st_matrix("`modes'")', ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`wscheme'", ///
      "`convcrit'", ///
      "`init'", ///
      "`rawsum'", ///
      "`noscale'")
    mata: st_numscalar("`converged'", `res'.converged)
    mata: st_numscalar("`niter'", `res'.niter)
    mata: st_matrix("`W'", `res'.outer_weights)
    mata: st_matrix("`L'", `res'.loadings)
    mata: st_matrix("`scores'", `res'.scores)
    mata: st_matrix("`B'", `res'.pathcoef)
    mata: st_matrix("`R2'", `res'.r2)
    mata: st_matrix("`alpha'", `res'.alpha)
    mata: st_matrix("`cr'", `res'.cr)
    mata: st_matrix("`ave'", `res'.ave)
    mata: st_matrix("`lvcorr'", `res'.lvcorr)
    mata: st_matrix("`crossload'", `res'.crossload)
    mata: st_matrix("`htmt'", `res'.htmt)
    mata: st_matrix("`vif'", `res'.vif)
    mata: st_matrix("`f2'", `res'.f2)
    matrix rownames `W' = `allindicators'
    matrix colnames `W' = `alllatents'
    matrix rownames `L' = `allindicators'
    matrix colnames `L' = `alllatents'
    matrix rownames `B' = `alllatents'
    matrix colnames `B' = `alllatents'
    matrix rownames `R2' = "R2"
    matrix colnames `R2' = `alllatents'
    matrix rownames `alpha' = "alpha"
    matrix colnames `alpha' = `alllatents'
    matrix rownames `cr' = "CR"
    matrix colnames `cr' = `alllatents'
    matrix rownames `ave' = "AVE"
    matrix colnames `ave' = `alllatents'
    matrix rownames `lvcorr' = `alllatents'
    matrix colnames `lvcorr' = `alllatents'
    matrix rownames `crossload' = `allindicators'
    matrix colnames `crossload' = `alllatents'
    matrix rownames `htmt' = `alllatents'
    matrix colnames `htmt' = `alllatents'
    /* generate LV score variables in the dataset (as plssem does) */
    forvalues j = 1/`k_lv' {
      local lv = `"`lv`j''"'
      capture confirm variable `lv'
      if !_rc {
        local lbl : variable label `lv'
        if "`lbl'" == "PLS-SEM score of `lv'" {
          quietly replace `lv' = .
        }
        else {
          display as error "variable `lv' already exists and is not a plssem2 score variable"
          exit 110
        }
      }
      else {
        quietly generate double `lv' = .
      }
      mata: st_store(selectindex(st_data(., "`touse'")), "`lv'", st_matrix("`scores'")[., `j'])
      label variable `lv' "PLS-SEM score of `lv'"
    }
  }

  /* ------------------------- effects --------------------------------- */
  mata: st_matrix("`btot'", plssem2_effects(st_matrix("`B'"), st_matrix("`adj_struct'"), 0))
  mata: st_matrix("`bind'", plssem2_effects(st_matrix("`B'"), st_matrix("`adj_struct'"), 1))
  matrix rownames `btot' = `alllatents'
  matrix colnames `btot' = `alllatents'
  matrix rownames `bind' = `alllatents'
  matrix colnames `bind' = `alllatents'

  /* ------------------------- blindfolding ---------------------------- */
  tempname q2red q2com q2indr q2indc
  if `blindfold' > 0 {
    if `blindfold' >= `n' {
      display as error "blindfold() omission distance must be smaller than the sample size"
      exit 198
    }
    tempname bf
    mata: `bf' = plssem2_blindfold( ///
      st_data(., "`allindicators'", "`touse'"), ///
      st_matrix("`adj_meas'"), ///
      st_matrix("`adj_struct'"), ///
      st_matrix("`modes'")', ///
      strtoreal("`blindfold'"), ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`init'", ///
      "`wscheme'", ///
      "`convcrit'")
    mata: st_matrix("`q2red'", `bf'.q2red)
    mata: st_matrix("`q2com'", `bf'.q2com)
    mata: st_matrix("`q2indr'", `bf'.q2ind_red)
    mata: st_matrix("`q2indc'", `bf'.q2ind_com)
    matrix rownames `q2red' = "Q2red"
    matrix colnames `q2red' = `alllatents'
    matrix rownames `q2com' = "Q2com"
    matrix colnames `q2com' = `alllatents'
    matrix rownames `q2indr' = `allindicators'
    matrix colnames `q2indr' = "Q2"
    matrix rownames `q2indc' = `allindicators'
    matrix colnames `q2indc' = "Q2"
  }

  /* ------------------------- bootstrap ------------------------------- */
  tempname bootV se_b ci_b se_l ci_l se_w ci_w
  tempname ci_ind ci_tot reps_ind reps_tot reps_r2 ci_r2 n_inad
  if "`boot'" != "" {
    local reps = `boot'
    tempname bres
    mata: `bres' = plssem2_boot( ///
      st_data(., "`allindicators'", "`touse'"), ///
      st_matrix("`adj_meas'"), ///
      st_matrix("`adj_struct'"), ///
      st_matrix("`modes'")', ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`wscheme'", ///
      "`convcrit'", ///
      "`init'", ///
      "`rawsum'", ///
      "`noscale'", ///
      strtoreal("`reps'"), ///
      strtoreal("`level'"), ///
      "`bca'", ///
      "`nojack'")
    mata: st_numscalar("`n_inad'", `bres'.n_inadmiss)
    mata: st_matrix("`se_b'", `bres'.se_path)
    mata: st_matrix("`ci_b'", `bres'.ci_path)
    mata: st_matrix("`se_l'", `bres'.se_load)
    mata: st_matrix("`ci_l'", `bres'.ci_load)
    mata: st_matrix("`se_w'", `bres'.se_weg)
    mata: st_matrix("`ci_w'", `bres'.ci_weg)
    mata: st_matrix("`reps_ind'", `bres'.reps_ind)
    mata: st_matrix("`ci_ind'", `bres'.ci_ind)
    mata: st_matrix("`reps_tot'", `bres'.reps_tot)
    mata: st_matrix("`ci_tot'", `bres'.ci_tot)
    mata: st_matrix("`reps_r2'", `bres'.reps_r2)
    mata: st_matrix("`ci_r2'", `bres'.ci_r2)
    mata: st_matrix("`bootV'", `bres'.cov_path)
  }

  /* ------------------------- store results --------------------------- */
  /* e(b) = structural path coefficients (direct effects) */
  local npaths = 0
  local bnames ""
  forvalues j = 1/`k_lv' {
    local lvj : word `j' of `alllatents'
    forvalues i = 1/`k_lv' {
      local lvi : word `i' of `alllatents'
      if `adj_struct'[`j', `i'] {
        local ++npaths
        local bnames `bnames' "`lvj':`lvi'"
      }
    }
  }
  matrix `bvec' = J(1, `npaths', 0)
  local p = 0
  forvalues j = 1/`k_lv' {
    local lvj : word `j' of `alllatents'
    forvalues i = 1/`k_lv' {
      local lvi : word `i' of `alllatents'
      if `adj_struct'[`j', `i'] {
        local ++p
        matrix `bvec'[1, `p'] = `B'[`j', `i']
      }
    }
  }
  matrix colnames `bvec' = `bnames'

  if "`boot'" != "" {
    matrix rownames `bootV' = `bnames'
    matrix colnames `bootV' = `bnames'
    ereturn post `bvec' `bootV', esample(`touse') obs(`n')
  }
  else {
    ereturn post `bvec', esample(`touse') obs(`n')
  }
  ereturn local cmd "plssem2"
  ereturn local cmdline `"`cmdline'"'
  ereturn local title "Partial least squares structural equation modeling"
  ereturn local estat_cmd "plssem2_estat"
  ereturn local predict "plssem2_predict"
  ereturn local lvs "`alllatents'"
  ereturn local mvs "`allindicators'"
  ereturn local reflective "`reflective'"
  ereturn local formative "`formative'"
  ereturn local wscheme "`wscheme'"
  ereturn local convcrit "`convcrit'"
  ereturn local init "`init'"
  ereturn local properties "`init' `wscheme'"
  ereturn local struct_eqs "`structural'"
  if `k_ho' {
    local hdesc ""
    forvalues h = 1/`k_ho' {
      local hn `honame_ho`h''
      local hc `hcomp_ho`h''
      local hm `hmode_ho`h''
      local part = "`hn'" + ": " + "`hc'" + " (" + "`hm'" + ")"
      local hdesc = "`hdesc'" + " " + "`part'"
    }
    ereturn local higher "`hdesc'"
  }
  ereturn scalar N = `n'
  ereturn scalar k_lv = `k_lv'
  ereturn scalar k_mv = `Q'
  ereturn scalar k_aux = 0
  ereturn scalar iterations = `niter'
  ereturn scalar converged = `converged'
  ereturn scalar tolerance = `tol'
  ereturn scalar maxiter = `maxiter'
  ereturn scalar level = `level'
  if `blindfold' > 0 {
    ereturn scalar blindfold = `blindfold'
  }
  if "`boot'" != "" {
    ereturn scalar reps = `reps'
    ereturn scalar n_inadmissibles = `n_inad'
    if "`bca'" != "" {
      ereturn local bca "bca"
    }
    ereturn matrix ci_path = `ci_b'
    ereturn matrix se_path = `se_b'
    ereturn matrix ci_load = `ci_l'
    ereturn matrix se_load = `se_l'
    ereturn matrix ci_weg = `ci_w'
    ereturn matrix se_weg = `se_w'
    ereturn matrix ci_ind = `ci_ind'
    ereturn matrix ci_tot = `ci_tot'
    ereturn matrix ci_r2 = `ci_r2'
    ereturn matrix reps_ind = `reps_ind'
    ereturn matrix reps_tot = `reps_tot'
  }
  ereturn matrix modes = `modes'
  ereturn matrix loadings = `L'
  ereturn matrix outerweights = `W'
  ereturn matrix cross_loadings = `crossload'
  ereturn matrix scores = `scores'
  ereturn matrix pathcoef = `B'
  ereturn matrix rsquared = `R2'
  ereturn matrix alpha = `alpha'
  ereturn matrix cr = `cr'
  ereturn matrix ave = `ave'
  ereturn matrix lvcorr = `lvcorr'
  ereturn matrix htmt = `htmt'
  ereturn matrix vif = `vif'
  ereturn matrix f2 = `f2'
  ereturn matrix adj_meas = `adj_meas'
  ereturn matrix adj_struct = `adj_struct'
  ereturn matrix total_effects = `btot'
  ereturn matrix indirect_effects = `bind'
  if `blindfold' > 0 {
    ereturn matrix q2_redundancy = `q2red'
    ereturn matrix q2_communality = `q2com'
    ereturn matrix q2_ind_red = `q2indr'
    ereturn matrix q2_ind_com = `q2indc'
  }

  /* ------------------------- display --------------------------------- */
  if "`stats'" != "" {
    display _newline
    display as text "{p 0 6 2}{bf:Indicator summary statistics}{p_end}"
    quietly summarize `allindicators'
  }
  Display, digits(`digits') `noheader' `nomeastable' `nodiscrimtable' ///
    `nostructtable' `nohtmt' level(`level')
end

/* ---------------------------------------------------------------------- */
/* Display: print the estimation output                                    */
/* ---------------------------------------------------------------------- */
program Display
  version 15.1
  syntax [, DIGits(integer 3) noHEADer noMEAStable noDISCRIMtable ///
    noSTRUCTtable noHTMT Level(cilevel) ]

  /* ---- replay of multi-group results ---- */
  if "`e(gmethod)'" != "" {
    tempname B1 B2 R2_1 R2_2 diff pv
    capture matrix `B1' = e(B1)
    if _rc {
      display as error "no multi-group results found; run plssem2 with group()"
      exit 301
    }
    matrix `R2_1' = e(R2_1)
    matrix `R2_2' = e(R2_2)
    matrix `diff' = e(diff_obs)
    matrix `pv' = e(p_values)
    local lvlist `e(lvs)'
    local P : list sizeof lvlist
    local galpha = e(galpha)
    display _newline
    display as text "{hline 78}"
    display as text "Multi-group analysis (MGA) - method: " as result "`e(gmethod)'"
    display as text "Grouping variable: " as result "`e(groupvar)'" ///
      as text "   Permutations: " as result %6.0f e(greps)
    display as text "{hline 78}"
    display as text _col(4) "{bf:Path}" _col(30) "{bf:|diff|}" ///
      _col(44) "{bf:p-value}" _col(58) "{bf:p < `galpha'}"
    display as text "{hline 78}"
    local p = 0
    forvalues j = 1/`P' {
      local lvj : word `j' of `lvlist'
      forvalues i = 1/`P' {
        local lvi : word `i' of `lvlist'
        if `B1'[`j', `i'] != 0 {
          local ++p
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %8.4f `diff'[1, `p'] ///
            as text _col(44) as result %8.4f `pv'[1, `p'] ///
            as text _col(58) as result cond(`pv'[1, `p'] < `galpha', "yes", "no")
        }
      }
    }
    display as text "{hline 78}"
    display as text "Permutation p-values (Henseler et al. 2016)."
    exit
  }

  tempname dummy
  capture matrix `dummy' = e(loadings)
  if _rc {
    display as error "no estimation results found; run plssem2 first"
    exit 301
  }

  if "`noheader'" == "" {
    display _newline
    display as text "{hline 78}"
    display as text "Partial least squares structural equation modeling (PLS-SEM)"
    display as text "Algorithm: Wold (1975) / Lohmoller (1989);  inner scheme: " ///
      as result "`e(wscheme)'"
    display as text "Number of observations = " as result %9.0f e(N) ///
      as text "   Latent variables = " as result %3.0f e(k_lv) ///
      as text "   Indicators = " as result %3.0f e(k_mv)
    display as text "Iterations = " as result %4.0f e(iterations) ///
      as text "   Converged = " as result %1.0f e(converged) ///
      as text "   Tolerance = " as result e(tolerance)
    display as text "{hline 78}"
  }

  if "`nomeastable'" == "" {
    DisplayMeasurement, digits(`digits') level(`level')
  }
  if "`nodiscrimtable'" == "" {
    DisplayDiscriminant, digits(`digits') level(`level') `nohtmt'
  }
  if "`nostructtable'" == "" {
    DisplayStructural, digits(`digits') level(`level')
  }
  display as text _newline "{p 0 6 2}Note: PLS-SEM is not a likelihood-based method: it does not " ///
    "provide a global goodness-of-fit statistic (no chi-squared, RMSEA, CFI, " ///
    "or similar CB-SEM fit indices). Model evaluation relies on the measurement, " ///
    "discriminant-validity and structural assessment criteria reported above.{p_end}"
end

program DisplayMeasurement
  version 15.1
  syntax [, DIGits(integer 3) Level(cilevel) ]
  tempname L W alpha cr ave modes
  capture matrix `L' = e(loadings)
  if _rc {
    exit
  }
  matrix `W' = e(outerweights)
  matrix `alpha' = e(alpha)
  matrix `cr' = e(cr)
  matrix `ave' = e(ave)
  matrix `modes' = e(modes)
  local lvlist `e(lvs)'
  local mvs `e(mvs)'
  local P = e(k_lv)
  local Q = e(k_mv)
  display _newline
  display as text "{p 0 6 2}{bf:Measurement model (outer model)}{p_end}"
  display as text "Loadings: correlation of each indicator with its latent variable;"
  display as text "weights: outer weights used to build the composite scores."
  display as text "Reliability: Cronbach's alpha, composite reliability (CR, rho_c),"
  display as text "average variance extracted (AVE).  Mode A = reflective, Mode B = formative."
  local j = 0
  foreach lv of local lvlist {
    local ++j
    local modestr "A (reflective)"
    if `modes'[1, `j'] == 1 {
      local modestr "B (formative)"
    }
    display as text _newline "Latent variable: " as result "`lv'" ///
      as text "  (" as result "Mode `modestr'" as text ")"
    display as text "{col 8}{bf:Indicator}{col 28}{bf:Loading}{col 42}{bf:Weight}"
    forvalues q = 1/`Q' {
      if `L'[`q', `j'] != 0 {
        local indname : word `q' of `mvs'
        display as text _col(8) as result "`indname'" ///
          as text _col(28) as result %9.`digits'f `L'[`q', `j'] ///
          as text _col(42) as result %9.`digits'f `W'[`q', `j']
      }
    }
    display as text _col(8) "Cronbach's alpha" _col(28) as result %9.`digits'f `alpha'[1, `j']
    display as text _col(8) "Composite reliability (CR)" _col(28) as result %9.`digits'f `cr'[1, `j']
    display as text _col(8) "Average variance extracted (AVE)" _col(28) as result %9.`digits'f `ave'[1, `j']
  }
end

program DisplayDiscriminant
  version 15.1
  syntax [, DIGits(integer 3) Level(cilevel) noHTMT ]
  tempname lvcorr ave htmt
  capture matrix `lvcorr' = e(lvcorr)
  if _rc {
    exit
  }
  matrix `ave' = e(ave)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  display _newline
  display as text "{p 0 6 2}{bf:Discriminant validity}{p_end}"
  display as text "Fornell-Larcker criterion: the square root of the AVE (diagonal,"
  display as text "in brackets) of each latent variable must exceed its correlations"
  display as text "with the other latent variables (off-diagonal)."
  display _newline
  local j = 0
  foreach lv of local lvlist {
    local ++j
    display as text _col(2) as result %-12s "`lv'" _continue
    local i = 0
    foreach lvlv2 of local lvlist {
      local ++i
      local col = 14 + 9 * (`i' - 1)
      if `i' == `j' {
        local v = sqrt(`ave'[1, `j'])
        display as text _col(`col') "[" %6.`digits'f `v' "]" _continue
      }
      else {
        display as result _col(`col') %8.`digits'f `lvcorr'[`j', `i'] _continue
      }
    }
    display
  }
  if "`nohtmt'" == "" {
    display _newline
    display as text "{p 0 6 2}Heterotrait-monotrait ratio of correlations (HTMT; " ///
      "Henseler et al. 2015). Discriminant validity is supported if all HTMT " ///
      "values are below 0.90 (or 0.85 for conceptually distinct constructs).{p_end}"
    matrix `htmt' = e(htmt)
    local j = 0
    foreach lv of local lvlist {
      local ++j
      display as text _col(2) as result %-12s "`lv'" _continue
      local i = 0
      foreach lvlv2 of local lvlist {
        local ++i
        local col = 14 + 9 * (`i' - 1)
        if `i' == `j' {
          display as text _col(`col') "1" _continue
        }
        else {
          display as result _col(`col') %8.`digits'f `htmt'[`j', `i'] _continue
        }
      }
      display
    }
  }
end

program DisplayStructural
  version 15.1
  syntax [, DIGits(integer 3) Level(cilevel) ]
  tempname B R2 f2 vif
  capture matrix `B' = e(pathcoef)
  if _rc {
    exit
  }
  matrix `R2' = e(rsquared)
  matrix `f2' = e(f2)
  matrix `vif' = e(vif)
  local lvlist `e(lvs)'
  local P = e(k_lv)
  local hasboot = ("`e(reps)'" != "")
  display _newline
  display as text "{p 0 6 2}{bf:Structural model (inner model)}{p_end}"
  display as text "Path coefficients (OLS among the composite scores); significance"
  display as text "is obtained by nonparametric bootstrap (e(reps) replications)."
  if "`e(bca)'" != "" {
    display as text "Confidence intervals are bias-corrected and accelerated (BCa)."
  }
  display _newline
  display as text _col(4) "{bf:Path}" _col(30) "{bf:Coef}" _col(40) "{bf:SE}" ///
    _col(50) "{bf:t}" _col(60) "{bf:p>|t|}" _col(72) "{bf:[`level'% CI]}"
  display as text "{hline 78}"
  tempname se_b ci_b
  if `hasboot' {
    matrix `se_b' = e(se_path)
    matrix `ci_b' = e(ci_path)
  }
  local p = 0
  forvalues j = 1/`P' {
    local lvj : word `j' of `lvlist'
    forvalues i = 1/`P' {
      local lvi : word `i' of `lvlist'
      if `B'[`j', `i'] != 0 {
        local ++p
        local coef = `B'[`j', `i']
        if `hasboot' {
          local se = `se_b'[1, `p']
          local t = `coef' / `se'
          local pv = 2 * tprob(`e(N)' - 1, abs(`t'))
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %9.`digits'f `coef' ///
            as text _col(40) as result %9.`digits'f `se' ///
            as text _col(50) as result %7.2f `t' ///
            as text _col(60) as result %6.4f `pv' ///
            as text _col(72) "[" %6.`digits'f `ci_b'[1, `p'] "," ///
            %6.`digits'f `ci_b'[2, `p'] "]"
        }
        else {
          display as text _col(4) as result "`lvj' <- `lvi'" ///
            as text _col(30) as result %9.`digits'f `coef'
        }
      }
    }
  }
  display as text "{hline 78}"
  display as text _col(4) "{bf:Endogenous LV}" _col(30) "{bf:R-squared}"
  local j = 0
  foreach lv of local lvlist {
    local ++j
    if `R2'[1, `j'] != 0 {
      display as text _col(4) as result "`lv'" ///
        as text _col(30) as result %9.`digits'f `R2'[1, `j']
    }
  }
  if "`e(blindfold)'" != "" {
    display as text _newline _col(4) "{bf:Endogenous LV}" _col(30) "{bf:Q2 redundancy}" ///
      _col(50) "{bf:Q2 communality}"
    tempname q2red q2com
    matrix `q2red' = e(q2_redundancy)
    matrix `q2com' = e(q2_communality)
    local j = 0
    foreach lv of local lvlist {
      local ++j
      if `R2'[1, `j'] != 0 {
        display as text _col(4) as result "`lv'" ///
          as text _col(30) as result %9.`digits'f `q2red'[1, `j'] ///
          as text _col(50) as result %9.`digits'f `q2com'[1, `j']
      }
    }
  }
  else {
    display as text _newline _col(4) "Use the blindfold(#) option to obtain Stone-Geisser Q2."
  }
  display as text _newline _col(4) "Effect size f2 and inner VIF: see estat f2 and estat vif."
end

/* ---------------------------------------------------------------------- */
/* Compare: multi-group analysis (MGA)                                     */
/* ---------------------------------------------------------------------- */
program Compare, eclass
  version 15.1
  syntax anything(name=blocks) [if] [in], ///
    [ STRuctural(string) Wscheme(string) ///
    BOot(numlist integer >0 max=1) SEed(numlist max=1) ///
    Tol(real 1e-7) MAXiter(integer 100) ///
    INIT(string) DIGits(integer 3) Level(cilevel) ///
    BLINDfold(integer 0) BCA noJACK ///
    HIGHER(string) STATs RAWsum noSCale CONVcrit(string) ///
    noHTMT GRoup(string) noCLEANup ]

  if "`boot'" != "" {
    display as error "the boot() option is not allowed with group(); use group(..., method(bootstrap))"
    exit 198
  }

  /* ---- parse group() ---- */
  local gvar `group'
  local gmethod "permutation"
  local greps 1000
  local gseed ""
  local galpha 0.05
  if strpos(`"`gvar'"', ",") {
    local gvar : subinstr local gvar "," " " , all
    gettoken gvar gopts : gvar
    gettoken gopt gopts : gopts
    while "`gopt'" != "" {
      gettoken gname grest : gopt, parse("()")
      if inlist("`gname'", "method", "reps", "seed", "alpha") {
        gettoken lp grest : grest, parse("()")
        gettoken gval grest : grest, parse(")")
        gettoken rp grest : grest, parse("()")
        if "`gname'" == "method" {
          local gmethod `gval'
        }
        else if "`gname'" == "reps" {
          local greps `gval'
        }
        else if "`gname'" == "seed" {
          local gseed `gval'
        }
        else if "`gname'" == "alpha" {
          local galpha `gval'
        }
      }
      gettoken gopt gopts : gopts
    }
  }
  if !inlist("`gmethod'", "permutation", "normal") {
    display as error "group() method must be 'permutation' or 'normal'"
    exit 198
  }
  capture confirm numeric variable `gvar'
  if _rc {
    display as error "grouping variable `gvar' is not numeric"
    exit 198
  }
  if "`seed'" != "" {
    set seed `seed'
  }
  local level = `level'

  /* ---- reparse the model ---- */
  local blist `blocks'
  local k = 0
  local allindicators ""
  local alllatents ""
  while "`blist'" != "" {
    gettoken block blist : blist, match(paren)
    if "`block'" == "" continue
    gettoken lv block : block
    gettoken arrow block : block
    if !inlist("`arrow'", ">", "<") {
      display as error "block syntax: (LV > indicators) reflective or (LV < indicators) formative"
      exit 198
    }
    unab inds : `block'
    local ++k
    local lv`k' `lv'
    local arrow`k' `arrow'
    local ind`k' `inds'
    local allindicators `allindicators' `inds'
    local alllatents `alllatents' `lv'
  }

  /* ---- higher-order constructs (two-stage, Becker et al. 2012) ---- */
  local k_ho = 0
  if "`higher'" != "" {
    local hwork `higher'
    while strlen(`"`hwork'"') > 0 {
      local semi = strpos(`"`hwork'"', ";")
      if `semi' == 0 {
        local hpart `hwork'
        local hwork ""
      }
      else {
        local hpart = substr(`"`hwork'"', 1, `semi' - 1)
        local hwork = substr(`"`hwork'"', `semi' + 1, .)
      }
      local hpart : list clean hpart
      if "`hpart'" == "" {
        continue
      }
      gettoken hname hpart : hpart, parse(":")
      gettoken colon hpart : hpart, parse(":")
      if "`colon'" != ":" {
        display as error "higher() must be specified as higher(\"HOname: lv1 lv2 ...\")"
        exit 198
      }
      capture confirm name `hname'
      if _rc {
        display as error "`hname' is not a valid latent-variable name"
        exit 198
      }
      local hcomp `hpart'
      local hmode "reflective"
      local comma = strpos(`"`hcomp'"', ",")
      if `comma' > 0 {
        local hmode = substr(`"`hcomp'"', `comma' + 1, .)
        local hcomp = substr(`"`hcomp'"', 1, `comma' - 1)
        local hmode : subinstr local hmode "mode" "" , all
        local hmode : subinstr local hmode "(" "" , all
        local hmode : subinstr local hmode ")" "" , all
        local hmode : list clean hmode
      }
      local hcomp : list clean hcomp
      if !inlist("`hmode'", "reflective", "formative") {
        display as error "higher-order mode must be 'reflective' or 'formative'"
        exit 198
      }
      if "`hcomp'" == "" {
        display as error "higher-order construct `hname' has no components"
        exit 198
      }
      foreach c of local hcomp {
        if !`: list c in alllatents' {
          display as error "higher-order component `c' is not a latent variable of the model"
          exit 198
        }
      }
      if `: list hname in alllatents' {
        display as error "higher-order latent variable `hname' must not appear in the measurement blocks"
        exit 198
      }
      local ++k_ho
      local honame_ho`k_ho' `hname'
      local hcomp_ho`k_ho' `hcomp'
      local hmode_ho`k_ho' `hmode'
      local alllatents `alllatents' `hname'
    }
    if `k_ho' == 0 {
      display as error "no valid higher-order specification found in higher()"
      exit 198
    }
  }
  local k_lv = `k' + `k_ho'

  marksample touse
  markout `touse' `allindicators' `gvar'
  count if `touse'
  local n = r(N)
  if `n' < 3 {
    display as error "not enough observations"
    exit 2001
  }

  tempname adj_meas adj_struct modes
  local Q = 0
  foreach v of varlist `allindicators' {
    local ++Q
  }
  matrix `adj_meas' = J(`Q', `k_lv', 0)
  matrix rownames `adj_meas' = `allindicators'
  matrix colnames `adj_meas' = `alllatents'
  local jj = 0
  foreach v of varlist `allindicators' {
    local ++jj
    forvalues j = 1/`k' {
      if `: list v in ind`j'' {
        matrix `adj_meas'[`jj', `j'] = 1
      }
    }
  }
  matrix `adj_struct' = J(`k_lv', `k_lv', 0)
  matrix rownames `adj_struct' = `alllatents'
  matrix colnames `adj_struct' = `alllatents'
  local slist `structural'
  while strlen(`"`slist'"') > 0 {
    local comma = strpos(`"`slist'"', ",")
    if `comma' == 0 {
      local eq `slist'
      local slist ""
    }
    else {
      local eq = substr(`"`slist'"', 1, `comma' - 1)
      local slist = substr(`"`slist'"', `comma' + 1, .)
    }
    local eq : subinstr local eq "(" " " , all
    local eq : subinstr local eq ")" " " , all
    local eq : list clean eq
    if "`eq'" == "" {
      continue
    }
    gettoken dep eq : eq
    local di = 0
    foreach lv of local alllatents {
      local ++di
      if "`lv'" == "`dep'" {
        foreach p of local eq {
          local pi = 0
          foreach lvlv2 of local alllatents {
            local ++pi
            if "`lvlv2'" == "`p'" {
              matrix `adj_struct'[`di', `pi'] = 1
            }
          }
        }
      }
    }
  }
  matrix `modes' = J(1, `k_lv', 0)
  matrix colnames `modes' = `alllatents'
  forvalues j = 1/`k' {
    if "`arrow`j''" == "<" {
      matrix `modes'[1, `j'] = 1
    }
  }
  forvalues h = 1/`k_ho' {
    if "`hmode_ho`h''" == "formative" {
      matrix `modes'[1, `k' + `h'] = 1
    }
  }

  /* ---- two-stage higher-order: stage-1 scores on the pooled sample ---- */
  tempname Xm
  if `k_ho' > 0 {
    local k_lv1 = `k'
    local alllatents1 ""
    forvalues j = 1/`k_lv1' {
      local alllatents1 `alllatents1' `: word `j' of `alllatents''
    }
    tempname adj_meas1 adj_struct1 modes1 res1 scores1
    matrix `adj_meas1' = `adj_meas'[1..`Q', 1..`k_lv1']
    matrix rownames `adj_meas1' = `allindicators'
    matrix colnames `adj_meas1' = `alllatents1'
    matrix `adj_struct1' = `adj_struct'[1..`k_lv1', 1..`k_lv1']
    matrix rownames `adj_struct1' = `alllatents1'
    matrix colnames `adj_struct1' = `alllatents1'
    matrix `modes1' = `modes'[1, 1..`k_lv1']
    matrix colnames `modes1' = `alllatents1'
    mata: `res1' = plssem2_estimate( ///
      st_data(., "`allindicators'", "`touse'"), ///
      st_matrix("`adj_meas1'"), ///
      st_matrix("`adj_struct1'"), ///
      st_matrix("`modes1'")', ///
      strtoreal("`tol'"), ///
      strtoreal("`maxiter'"), ///
      "`wscheme'", ///
      "`convcrit'", ///
      "`init'", ///
      "`rawsum'", ///
      "`noscale'")
    mata: st_matrix("`scores1'", `res1'.scores)
    forvalues j = 1/`k_lv1' {
      local lv : word `j' of `alllatents1'
      capture confirm variable `lv'
      if !_rc {
        local lbl : variable label `lv'
        if "`lbl'" == "PLS-SEM score of `lv'" {
          quietly replace `lv' = .
        }
        else {
          display as error "variable `lv' already exists and is not a plssem2 score variable"
          exit 110
        }
      }
      else {
        quietly generate double `lv' = .
      }
      mata: st_store(selectindex(st_data(., "`touse'")), "`lv'", st_matrix("`scores1'")[., `j'])
      label variable `lv' "PLS-SEM score of `lv'"
    }
    /* stage-2: component scores become HO indicators */
    local hoinds ""
    local qrow = `Q'
    forvalues h = 1/`k_ho' {
      local hc = `"`hcomp_ho`h''"'
      foreach c of local hc {
        local ++qrow
        local hoinds `hoinds' `c'
      }
    }
    local Q2 = `qrow'
    tempname adj_meas2 adj_struct2 modes2
    matrix `adj_meas2' = J(`Q2', `k_lv', 0)
    matrix rownames `adj_meas2' = `allindicators' `hoinds'
    matrix colnames `adj_meas2' = `alllatents'
    forvalues q = 1/`Q' {
      forvalues j = 1/`k_lv' {
        matrix `adj_meas2'[`q', `j'] = `adj_meas'[`q', `j']
      }
    }
    local qrow = `Q'
    forvalues h = 1/`k_ho' {
      local hc = `"`hcomp_ho`h''"'
      foreach c of local hc {
        local ++qrow
        matrix `adj_meas2'[`qrow', `k' + `h'] = 1
      }
    }
    matrix `adj_struct2' = `adj_struct'
    matrix rownames `adj_struct2' = `alllatents'
    matrix colnames `adj_struct2' = `alllatents'
    matrix `modes2' = `modes'
    matrix colnames `modes2' = `alllatents'
    mata: `Xm' = st_data(., "`allindicators'", "`touse'") , ///
      st_data(., "`hoinds'", "`touse'")
    matrix `adj_meas' = `adj_meas2'
    matrix `adj_struct' = `adj_struct2'
    matrix `modes' = `modes2'
    local allindicators `allindicators' `hoinds'
    local Q = `Q2'
  }
  else {
    mata: `Xm' = st_data(., "`allindicators'", "`touse'")
  }

  if "`gseed'" != "" {
    set seed `gseed'
  }

  tempname mg W1 L1 B1 R2_1 W2 L2 B2 R2_2 diff pv
  mata: `mg' = plssem2_mga( ///
    `Xm', ///
    st_data(., "`gvar'", "`touse'"), ///
    st_matrix("`adj_meas'"), ///
    st_matrix("`adj_struct'"), ///
    st_matrix("`modes'")', ///
    strtoreal("`tol'"), ///
    strtoreal("`maxiter'"), ///
    "`wscheme'", ///
    "`convcrit'", ///
    "`init'", ///
    "`gmethod'", ///
    strtoreal("`greps'"), ///
    "`gseed'", ///
    strtoreal("`level'"))
  mata: st_matrix("`W1'", `mg'.W1)
  mata: st_matrix("`L1'", `mg'.L1)
  mata: st_matrix("`B1'", `mg'.B1)
  mata: st_matrix("`R2_1'", `mg'.R21)
  mata: st_matrix("`W2'", `mg'.W2)
  mata: st_matrix("`L2'", `mg'.L2)
  mata: st_matrix("`B2'", `mg'.B2)
  mata: st_matrix("`R2_2'", `mg'.R22)
  mata: st_matrix("`diff'", `mg'.diff_obs)
  mata: st_matrix("`pv'", `mg'.p_values)
  matrix rownames `B1' = `alllatents'
  matrix colnames `B1' = `alllatents'
  matrix rownames `B2' = `alllatents'
  matrix colnames `B2' = `alllatents'
  matrix rownames `W1' = `allindicators'
  matrix colnames `W1' = `alllatents'
  matrix rownames `W2' = `allindicators'
  matrix colnames `W2' = `alllatents'
  matrix rownames `R2_1' = "R2"
  matrix colnames `R2_1' = `alllatents'
  matrix rownames `R2_2' = "R2"
  matrix colnames `R2_2' = `alllatents'

  tempname dummy
  matrix `dummy' = J(1, 1, 0)
  matrix colnames `dummy' = "dummy"
  ereturn post `dummy', esample(`touse') obs(`n')
  ereturn local cmd "plssem2"
  ereturn local estat_cmd "plssem2_estat"
  ereturn local cmdline `"`0'"'
  ereturn local title "Multi-group analysis (PLS-SEM)"
  ereturn local groupvar "`gvar'"
  ereturn local gmethod "`gmethod'"
  ereturn local lvs "`alllatents'"
  ereturn local mvs "`allindicators'"
  ereturn scalar greps = `greps'
  ereturn scalar level = `level'
  ereturn scalar galpha = `galpha'
  ereturn matrix W1 = `W1'
  ereturn matrix W2 = `W2'
  ereturn matrix L1 = `L1'
  ereturn matrix L2 = `L2'
  ereturn matrix B1 = `B1'
  ereturn matrix B2 = `B2'
  ereturn matrix R2_1 = `R2_1'
  ereturn matrix R2_2 = `R2_2'
  ereturn matrix diff_obs = `diff'
  ereturn matrix p_values = `pv'

  /* ---- display ---- */
  display _newline
  display as text "{hline 78}"
  display as text "Multi-group analysis (MGA) - method: " as result "`gmethod'"
  display as text "Grouping variable: " as result "`gvar'" ///
    as text "   Permutations: " as result %6.0f `greps'
  display as text "{hline 78}"
  display as text _col(4) "{bf:Path}" _col(30) "{bf:|diff|}" ///
    _col(44) "{bf:p-value}" _col(58) "{bf:p < `galpha'}"
  display as text "{hline 78}"
  /* e() holds copies of the tempname matrices (ereturn matrix consumes
     the tempnames); re-read them for the display */
  tempname eB1 ediff epv
  matrix `eB1' = e(B1)
  matrix `ediff' = e(diff_obs)
  matrix `epv' = e(p_values)
  local p = 0
  forvalues j = 1/`k_lv' {
    local lvj : word `j' of `alllatents'
    forvalues i = 1/`k_lv' {
      local lvi : word `i' of `alllatents'
      if `eB1'[`j', `i'] != 0 {
        local ++p
        local diffv = `ediff'[1, `p']
        local pvv = `epv'[1, `p']
        display as text _col(4) as result "`lvj' <- `lvi'" ///
          as text _col(30) as result %8.4f `diffv' ///
          as text _col(44) as result %8.4f `pvv' ///
          as text _col(58) as result cond(`pvv' < `galpha', "yes", "no")
      }
    }
  }
  display as text "{hline 78}"
  display as text "Permutation p-values (Henseler et al. 2016): the group labels are"
  display as text "randomly permuted and the absolute difference of the group-specific"
  display as text "path estimates is compared with the observed difference."
end

/* ====================================================================== */
/* Mata library                                                           */
/* ====================================================================== */
mata:

struct plssem2_res {
    real matrix outer_weights
    real matrix loadings
    real matrix scores
    real matrix pathcoef
    real matrix lvcorr
    real matrix crossload
    real matrix htmt
    real matrix vif
    real matrix f2
    real matrix indcorr
    real vector r2
    real vector alpha
    real vector cr
    real vector ave
    real scalar converged
    real scalar niter
}

struct plssem2_bf {
    real vector q2red
    real vector q2com
    real vector q2ind_red
    real vector q2ind_com
}

struct plssem2_bootres {
    real matrix reps_path
    real matrix se_path
    real matrix ci_path
    real matrix reps_load
    real matrix se_load
    real matrix ci_load
    real matrix reps_weg
    real matrix se_weg
    real matrix ci_weg
    real matrix reps_ind
    real matrix ci_ind
    real matrix reps_tot
    real matrix ci_tot
    real matrix reps_r2
    real matrix ci_r2
    real matrix cov_path
    real scalar n_inadmiss
}

struct plssem2_mgares {
    real matrix scores1
    real matrix scores2
    real matrix W1
    real matrix W2
    real matrix L1
    real matrix L2
    real matrix B1
    real matrix B2
    real vector R21
    real vector R22
    real matrix diff_obs
    real matrix p_values
}

/* ---------------------------------------------------------------------- */
/* helpers                                                                */
/* ---------------------------------------------------------------------- */
real matrix plssem2_standcols(real matrix Y) {
    real matrix Ys
    real vector mu, sd
    real scalar j
    Ys = Y
    for (j = 1; j <= cols(Y); j++) {
        mu = mean(Y[., j])
        sd = sqrt(variance(Y[., j]))
        if (sd < 1e-15) sd = 1
        Ys[., j] = (Y[., j] :- mu) :/ sd
    }
    return(Ys)
}

real scalar plssem2_corrxy(real colvector a, real colvector b) {
    real colvector as, bs
    real scalar sda, sdb
    sda = sqrt(variance(a))
    sdb = sqrt(variance(b))
    if (sda < 1e-15 | sdb < 1e-15) return(0)
    as = (a :- mean(a)) :/ sda
    bs = (b :- mean(b)) :/ sdb
    return(mean(as :* bs))
}

real matrix plssem2_corrmat(real matrix Y) {
    real matrix Ys
    Ys = plssem2_standcols(Y)
    return(cross(Ys, Ys) / (rows(Ys) - 1))
}

real scalar plssem2_quantile(real colvector x, real scalar p) {
    real colvector xs
    real scalar B, idx
    xs = sort(x, 1)
    B = length(x)
    if (B == 0) return(.)
    idx = ceil(p * B)
    if (idx < 1) idx = 1
    if (idx > B) idx = B
    return(xs[idx])
}

/* ---------------------------------------------------------------------- */
/* inner weights matrix                                                   */
/* ---------------------------------------------------------------------- */
real matrix plssem2_innerweights(real matrix Y, real matrix adj_struct,
    string scalar wscheme) {
    real matrix E, C, Xp
    real colvector b, preds
    real scalar P, j, k, n
    P = cols(Y)
    n = rows(Y)
    E = J(P, P, 0)
    C = plssem2_corrmat(Y)
    if (wscheme == "centroid") {
        for (j = 1; j <= P; j++) {
            for (k = 1; k <= P; k++) {
                if (adj_struct[j, k] | adj_struct[k, j]) {
                    E[j, k] = C[j, k] >= 0 ? 1 : -1
                }
            }
        }
    }
    else if (wscheme == "factorial") {
        for (j = 1; j <= P; j++) {
            for (k = 1; k <= P; k++) {
                if (adj_struct[j, k] | adj_struct[k, j]) {
                    E[j, k] = C[j, k]
                }
            }
        }
    }
    else {
        /* path weighting scheme (default) */
        for (j = 1; j <= P; j++) {
            preds = select(1::P, adj_struct[j, .]')
            if (length(preds) > 0) {
                Xp = (J(n, 1, 1), Y[., preds])
                b = invsym(cross(Xp, Xp)) * cross(Xp, Y[., j])
                for (k = 1; k <= length(preds); k++) {
                    E[j, preds[k]] = b[k + 1]
                }
            }
            for (k = 1; k <= P; k++) {
                if (adj_struct[k, j]) E[j, k] = C[j, k]
            }
        }
    }
    /* fallback: a latent variable with no connected LVs uses its outer
       estimate as the inner estimate (E[j,j] = 1); required e.g. for the
       measurement-only stage-1 model of the two-stage higher-order
       approach */
    for (j = 1; j <= P; j++) {
        if (sum(abs(E[j, .])) == 0) E[j, j] = 1
    }
    return(E)
}

/* ---------------------------------------------------------------------- */
/* main PLS estimation                                                    */
/* ---------------------------------------------------------------------- */
struct plssem2_res scalar plssem2_estimate(
    real matrix X,
    real matrix adj_meas,
    real matrix adj_struct,
    real colvector modes,
    real scalar tol,
    real scalar maxiter,
    string scalar wscheme,
    string scalar convcrit,
    string scalar init,
    string scalar rawsum,
    string scalar noscale) {

    struct plssem2_res scalar res
    real matrix Xs, W, Wnew, Y, Z, E, L, CL, B, Cj, Xp, Xj
    real vector R2, lam
    real scalar Q, P, n, it, j, k, q, diff, denom, K, rbar
    real colvector cols, wj, b, others, reduced, yhat
    complex vector ev
    complex matrix evec

    Q = rows(adj_meas)
    P = cols(adj_meas)
    n = rows(X)
    if (noscale == "noscale") {
        Xs = X
    }
    else {
    Xs = plssem2_standcols(X)
    }

    res.converged = 0
    res.niter = 0

    /* ---- initialization of the outer weights -------------------------- */
    W = J(Q, P, 0)
    if (rawsum == "rawsum") {
        /* summated scales: equal weights, no iteration */
        for (j = 1; j <= P; j++) {
            cols = select(1::Q, adj_meas[., j])
            W[cols, j] = J(length(cols), 1, 1)
        }
        res.niter = 1
        res.converged = 1
    }
    else {
        if (init == "eigen") {
            for (j = 1; j <= P; j++) {
                cols = select(1::Q, adj_meas[., j])
                Xj = Xs[., cols]
                if (cols(Xj) == 1) {
                    W[cols, j] = 1
                }
                else {
                    Cj = plssem2_corrmat(Xj)
                    eigensystem(Cj, ev, evec)
                    k = maxindex(Re(ev))
                    W[cols, j] = Re(evec[., k])
                }
            }
        }
        else {
            /* indsum (default) */
            for (j = 1; j <= P; j++) {
                cols = select(1::Q, adj_meas[., j])
                W[cols, j] = J(length(cols), 1, 1)
            }
        }

        /* ---- iterative PLS algorithm ---------------------------------- */
        for (it = 1; it <= maxiter; it++) {
            Y = Xs * W
            Y = plssem2_standcols(Y)
            E = plssem2_innerweights(Y, adj_struct, wscheme)
            Z = Y * E'
            Z = plssem2_standcols(Z)
            Wnew = J(Q, P, 0)
            for (j = 1; j <= P; j++) {
                cols = select(1::Q, adj_meas[., j])
                Xj = Xs[., cols]
                if (modes[j] == 1) {
                    /* Mode B: regression weights */
                    wj = invsym(cross(Xj, Xj)) * cross(Xj, Z[., j])
                }
                else {
                    /* Mode A: correlation weights */
                    wj = J(length(cols), 1, 0)
                    for (q = 1; q <= length(cols); q++) {
                        wj[q] = plssem2_corrxy(Xj[., q], Z[., j])
                    }
                }
                Wnew[cols, j] = wj
            }
            if (convcrit == "relative") {
                denom = abs(W) :+ 1e-12
                diff = max(abs((Wnew - W) :/ denom))
            }
            else if (convcrit == "square") {
                diff = max(abs(Wnew :^ 2 - W :^ 2))
            }
            else {
                diff = max(abs(Wnew - W))
            }
            W = Wnew
            if (diff < tol) {
                res.converged = 1
                break
            }
        }
        res.niter = res.converged ? it : maxiter
    }

    /* ---- final scores and parameters ----------------------------------- */
    Y = plssem2_standcols(Xs * W)
    res.outer_weights = W
    res.scores = Y

    /* outer loadings */
    L = J(Q, P, 0)
    for (j = 1; j <= P; j++) {
        cols = select(1::Q, adj_meas[., j])
        for (q = 1; q <= length(cols); q++) {
            L[cols[q], j] = plssem2_corrxy(Xs[., cols[q]], Y[., j])
        }
    }
    res.loadings = L

    /* cross loadings */
    CL = J(Q, P, 0)
    for (q = 1; q <= Q; q++) {
        for (j = 1; j <= P; j++) {
            CL[q, j] = plssem2_corrxy(Xs[., q], Y[., j])
        }
    }
    res.crossload = CL
    res.lvcorr = plssem2_corrmat(Y)
    res.indcorr = plssem2_corrmat(Xs)

    /* path coefficients (OLS on the LV scores) */
    B = J(P, P, 0)
    R2 = J(1, P, 0)
    for (j = 1; j <= P; j++) {
        cols = select(1::P, adj_struct[j, .]')
        if (length(cols) > 0) {
            Xp = (J(n, 1, 1), Y[., cols])
            b = invsym(cross(Xp, Xp)) * cross(Xp, Y[., j])
            for (k = 1; k <= length(cols); k++) {
                B[j, cols[k]] = b[k + 1]
            }
            yhat = Xp * b
            R2[j] = 1 - cross(Y[., j] - yhat, Y[., j] - yhat) / ///
                (cross(Y[., j], Y[., j]) - n * mean(Y[., j])^2)
        }
    }
    res.pathcoef = B
    res.r2 = R2

    /* reliability */
    res.alpha = J(1, P, .)
    res.cr = J(1, P, .)
    res.ave = J(1, P, .)
    for (j = 1; j <= P; j++) {
        cols = select(1::Q, adj_meas[., j])
        K = length(cols)
        lam = L[cols, j]
        if (K > 1) {
            Cj = plssem2_corrmat(Xs[., cols])
            rbar = (sum(Cj) - K) / (K * (K - 1))
            res.alpha[j] = (K * rbar) / (1 + (K - 1) * rbar)
        }
        else {
            res.alpha[j] = .
        }
        res.cr[j] = sum(lam)^2 / (sum(lam)^2 + sum(1 :- lam :^ 2))
        res.ave[j] = mean(lam :^ 2)
    }

    /* HTMT */
    res.htmt = plssem2_htmt(res.indcorr, adj_meas)

    /* VIF: inner */
    res.vif = J(P, P, 0)
    for (j = 1; j <= P; j++) {
        cols = select(1::P, adj_struct[j, .]')
        if (length(cols) > 1) {
            for (k = 1; k <= length(cols); k++) {
                others = select(cols, cols :!= cols[k])
                Xp = (J(n, 1, 1), Y[., others])
                b = invsym(cross(Xp, Xp)) * cross(Xp, Y[., cols[k]])
                yhat = Xp * b
                r2 = 1 - cross(Y[., cols[k]] - yhat, Y[., cols[k]] - yhat) / ///
                    (cross(Y[., cols[k]], Y[., cols[k]]) - ///
                    n * mean(Y[., cols[k]])^2)
                res.vif[j, cols[k]] = 1 / (1 - r2)
            }
        }
    }

    /* effect size f2 */
    res.f2 = J(P, P, 0)
    for (j = 1; j <= P; j++) {
        cols = select(1::P, adj_struct[j, .]')
        if (length(cols) > 1) {
            for (k = 1; k <= length(cols); k++) {
                reduced = select(cols, cols :!= cols[k])
                Xp = (J(n, 1, 1), Y[., reduced])
                b = invsym(cross(Xp, Xp)) * cross(Xp, Y[., j])
                yhat = Xp * b
                r2red = 1 - cross(Y[., j] - yhat, Y[., j] - yhat) / ///
                    (cross(Y[., j], Y[., j]) - n * mean(Y[., j])^2)
                denom = 1 - R2[j]
                if (denom > 0) res.f2[j, cols[k]] = (R2[j] - r2red) / denom
                else res.f2[j, cols[k]] = .
            }
        }
    }
    return(res)
}

/* ---------------------------------------------------------------------- */
/* HTMT                                                                   */
/* ---------------------------------------------------------------------- */
real matrix plssem2_htmt(real matrix indcorr, real matrix adj_meas) {
    real matrix H
    real scalar Q, P, i, j, a, b, Ki, Kj, mono_i, mono_j, het, denom
    real colvector ci, cj
    Q = rows(adj_meas)
    P = cols(adj_meas)
    H = J(P, P, 0)
    for (i = 1; i <= P; i++) {
        for (j = i + 1; j <= P; j++) {
            ci = select(1::Q, adj_meas[., i])
            cj = select(1::Q, adj_meas[., j])
            Ki = length(ci)
            Kj = length(cj)
            het = 0
            for (a = 1; a <= Ki; a++) {
                for (b = 1; b <= Kj; b++) {
                    het = het + indcorr[ci[a], cj[b]]
                }
            }
            het = het / (Ki * Kj)
            mono_i = 0
            for (a = 1; a <= Ki; a++) {
                for (b = a + 1; b <= Ki; b++) {
                    mono_i = mono_i + indcorr[ci[a], ci[b]]
                }
            }
            mono_i = Ki > 1 ? mono_i / (Ki * (Ki - 1) / 2) : 1
            mono_j = 0
            for (a = 1; a <= Kj; a++) {
                for (b = a + 1; b <= Kj; b++) {
                    mono_j = mono_j + indcorr[cj[a], cj[b]]
                }
            }
            mono_j = Kj > 1 ? mono_j / (Kj * (Kj - 1) / 2) : 1
            denom = sqrt(mono_i * mono_j)
            if (denom <= 0) denom = 1e-12
            H[i, j] = het / denom
            H[j, i] = H[i, j]
        }
    }
    for (i = 1; i <= P; i++) H[i, i] = 1
    return(H)
}

/* ---------------------------------------------------------------------- */
/* direct / indirect / total effects                                      */
/* ---------------------------------------------------------------------- */
real matrix plssem2_effects(real matrix B, real matrix adj_struct,
    real scalar indirect) {
    real matrix I, T, A
    real scalar P
    P = cols(B)
    I = I(P)
    A = I - B
    if (indirect) {
        T = luinv(A) - I - B
    }
    else {
        T = luinv(A) - I
    }
    return(T)
}

/* ---------------------------------------------------------------------- */
/* blindfolding (Stone-Geisser Q2)                                        */
/* ---------------------------------------------------------------------- */
struct plssem2_bf scalar plssem2_blindfold(
    real matrix X,
    real matrix adj_meas,
    real matrix adj_struct,
    real colvector modes,
    real scalar d,
    real scalar tol,
    real scalar maxiter,
    string scalar init,
    string scalar wscheme,
    string scalar convcrit) {

    struct plssem2_bf scalar bf
    struct plssem2_res scalar full, est
    real matrix Xs, Xo, Yhat, Yk, Xp, b
    real vector sse_red, sso_red, sse_com, sso_com, mu, sd
    real scalar Q, P, n, b0, j, q, k, sr, so, sc, so2
    real colvector omit, keep, cols, pk, xq, pred, predlv

    Q = rows(adj_meas)
    P = cols(adj_meas)
    n = rows(X)
    /* standardize once on the full sample; the reduced-data estimates then
       use noscale so that weights/loadings and the predictions are on the
       same scale */
    Xs = plssem2_standcols(X)
    full = plssem2_estimate(Xs, adj_meas, adj_struct, modes, tol, maxiter,
        wscheme, convcrit, init, "", "noscale")
    sse_red = J(Q, 1, 0)
    sso_red = J(Q, 1, 0)
    sse_com = J(Q, 1, 0)
    sso_com = J(Q, 1, 0)
    for (b0 = 1; b0 <= d; b0++) {
        omit = J(n, 1, 0)
        for (k = b0; k <= n; k = k + d) omit[k] = 1
        keep = selectindex(1 :- omit)
        if (length(keep) < 3) continue
        est = plssem2_estimate(Xs[keep, .], adj_meas, adj_struct, modes, tol,
            maxiter, wscheme, convcrit, init, "", "noscale")
        Yk = est.scores
        Xo = Xs[selectindex(omit), .]
        /* case-wise LV scores of the omitted cases: apply the same
           standardization (mean/sd of the kept raw scores) as used for the
           kept cases, so that the predictions are on a consistent scale */
        Yraw = Xs[keep, .] * est.outer_weights
        mu = mean(Yraw)
        sd = sqrt(diagonal(variance(Yraw))) :+ 1e-15
        Yhat = Xo * est.outer_weights
        for (j = 1; j <= P; j++) {
            Yhat[., j] = (Yhat[., j] :- mu[j]) :/ sd[j]
        }
        for (j = 1; j <= P; j++) {
            cols = select(1::Q, adj_meas[., j])
            for (q = 1; q <= length(cols); q++) {
                xq = Xo[., cols[q]]
                if (length(xq) == 0) continue
                pred = est.loadings[cols[q], j] * Yhat[., j]
                sse_com[cols[q]] = sse_com[cols[q]] + cross(xq - pred, xq - pred)
                sso_com[cols[q]] = sso_com[cols[q]] + cross(xq, xq)
            }
            pk = select(1::P, adj_struct[j, .]')
            if (length(pk) > 0) {
                Xp = (J(rows(Yk), 1, 1), Yk[., pk])
                b = invsym(cross(Xp, Xp)) * cross(Xp, Yk[., j])
                predlv = (J(rows(Xo), 1, 1), Yhat[., pk]) * b
                for (q = 1; q <= length(cols); q++) {
                    xq = Xo[., cols[q]]
                    if (length(xq) == 0) continue
                    pred = est.loadings[cols[q], j] * predlv
                    sse_red[cols[q]] = sse_red[cols[q]] + cross(xq - pred, xq - pred)
                    sso_red[cols[q]] = sso_red[cols[q]] + cross(xq, xq)
                }
            }
        }
    }
    bf.q2red = J(1, P, .)
    bf.q2com = J(1, P, .)
    bf.q2ind_red = J(Q, 1, .)
    bf.q2ind_com = J(Q, 1, .)
    for (j = 1; j <= P; j++) {
        cols = select(1::Q, adj_meas[., j])
        sr = sum(sse_red[cols]); so = sum(sso_red[cols])
        sc = sum(sse_com[cols]); so2 = sum(sso_com[cols])
        if (so > 0) bf.q2red[j] = 1 - sr / so
        if (so2 > 0) bf.q2com[j] = 1 - sc / so2
    }
    for (q = 1; q <= Q; q++) {
        if (sso_red[q] > 0) bf.q2ind_red[q] = 1 - sse_red[q] / sso_red[q]
        if (sso_com[q] > 0) bf.q2ind_com[q] = 1 - sse_com[q] / sso_com[q]
    }
    return(bf)
}

/* ---------------------------------------------------------------------- */
/* parameter extraction helpers                                           */
/* ---------------------------------------------------------------------- */
real rowvector plssem2_extract_path(real matrix B, real matrix adj_struct) {
    real rowvector out
    real scalar P, j, k, p
    P = cols(B)
    p = 0
    for (j = 1; j <= P; j++) {
        for (k = 1; k <= P; k++) {
            if (adj_struct[j, k]) p++
        }
    }
    out = J(1, p, 0)
    p = 0
    for (j = 1; j <= P; j++) {
        for (k = 1; k <= P; k++) {
            if (adj_struct[j, k]) {
                p++
                out[p] = B[j, k]
            }
        }
    }
    return(out)
}

real rowvector plssem2_extract_r2(real vector r2, real matrix adj_struct) {
    real rowvector out
    real scalar P, j, p
    P = cols(r2)
    p = 0
    for (j = 1; j <= P; j++) {
        if (any(adj_struct[j, .])) p++
    }
    out = J(1, p, 0)
    p = 0
    for (j = 1; j <= P; j++) {
        if (any(adj_struct[j, .])) {
            p++
            out[p] = r2[j]
        }
    }
    return(out)
}

real rowvector plssem2_extract_load(real matrix M, real matrix adj_meas) {
    real rowvector out
    real scalar Q, P, j, q, p
    Q = rows(M)
    P = cols(M)
    p = 0
    for (j = 1; j <= P; j++) p = p + sum(adj_meas[., j])
    out = J(1, p, 0)
    p = 0
    for (j = 1; j <= P; j++) {
        for (q = 1; q <= Q; q++) {
            if (adj_meas[q, j]) {
                p++
                out[p] = M[q, j]
            }
        }
    }
    return(out)
}

/* ---------------------------------------------------------------------- */
/* bootstrap with percentile and BCa confidence intervals                 */
/* ---------------------------------------------------------------------- */
struct plssem2_bootres scalar plssem2_boot(
    real matrix X,
    real matrix adj_meas,
    real matrix adj_struct,
    real colvector modes,
    real scalar tol,
    real scalar maxiter,
    string scalar wscheme,
    string scalar convcrit,
    string scalar init,
    string scalar rawsum,
    string scalar noscale,
    real scalar B,
    real scalar level,
    string scalar usebca,
    string scalar nojack) {

    struct plssem2_bootres scalar br
    struct plssem2_res scalar orig, eb
    real matrix reps_path, reps_load, reps_weg, reps_ind, reps_tot, reps_r2
    real matrix jack_path, jack_load, jack_weg, jack_ind, jack_tot, jack_r2
    real matrix idx, Xb, origp, origl, origw, origi, origt, origr
    real colvector valid
    real scalar Q, P, n, b, j, k, npaths, nload, nweg, nind, ntot, nendo
    real scalar n_inad, it, hasjack

    Q = rows(adj_meas)
    P = cols(adj_meas)
    n = rows(X)

    /* parameter layout ---------------------------------------------------- */
    npaths = 0
    nload = 0
    nweg = 0
    nind = 0
    ntot = 0
    nendo = 0
    for (j = 1; j <= P; j++) {
        if (any(adj_struct[j, .])) nendo++
        for (k = 1; k <= P; k++) {
            if (adj_struct[j, k]) npaths++
        }
        nload = nload + sum(adj_meas[., j])
        nweg = nweg + sum(adj_meas[., j])
    }
    nind = P * P
    ntot = P * P

    orig = plssem2_estimate(X, adj_meas, adj_struct, modes, tol, maxiter,
        wscheme, convcrit, init, rawsum, noscale)
    origp = plssem2_extract_path(orig.pathcoef, adj_struct)
    origl = plssem2_extract_load(orig.loadings, adj_meas)
    origw = plssem2_extract_load(orig.outer_weights, adj_meas)
    origi = vec(plssem2_effects(orig.pathcoef, adj_struct, 1))
    origt = vec(plssem2_effects(orig.pathcoef, adj_struct, 0))
    origr = vec(plssem2_extract_r2(orig.r2, adj_struct))

    reps_path = J(B, (npaths > 1 ? npaths : 1), 0)
    reps_load = J(B, (nload > 1 ? nload : 1), 0)
    reps_weg = J(B, (nweg > 1 ? nweg : 1), 0)
    reps_ind = J(B, (nind > 1 ? nind : 1), 0)
    reps_tot = J(B, (ntot > 1 ? ntot : 1), 0)
    reps_r2 = J(B, (nendo > 1 ? nendo : 1), 0)
    n_inad = 0
    for (b = 1; b <= B; b++) {
        idx = ceil(runiform(n, 1) :* n)
        Xb = X[idx, .]
        eb = plssem2_estimate(Xb, adj_meas, adj_struct, modes, tol, maxiter,
            wscheme, convcrit, init, rawsum, noscale)
        if (!eb.converged) {
            n_inad++
            continue
        }
        if (npaths > 0) reps_path[b, .] = plssem2_extract_path(eb.pathcoef, adj_struct)
        if (nload > 0) reps_load[b, .] = plssem2_extract_load(eb.loadings, adj_meas)
        if (nweg > 0) reps_weg[b, .] = plssem2_extract_load(eb.outer_weights, adj_meas)
        if (nind > 0) reps_ind[b, .] = vec(plssem2_effects(eb.pathcoef, adj_struct, 1))'
        if (ntot > 0) reps_tot[b, .] = vec(plssem2_effects(eb.pathcoef, adj_struct, 0))'
        if (nendo > 0) reps_r2[b, .] = plssem2_extract_r2(eb.r2, adj_struct)
    }
    /* drop inadmissible rows (any missing) */
    if (npaths > 0) {
        valid = rowsum(reps_path :== .) :== 0
        reps_path = select(reps_path, valid)
    }
    if (nload > 0) {
        valid = rowsum(reps_load :== .) :== 0
        reps_load = select(reps_load, valid)
    }
    if (nweg > 0) {
        valid = rowsum(reps_weg :== .) :== 0
        reps_weg = select(reps_weg, valid)
    }
    if (nind > 0) {
        valid = rowsum(reps_ind :== .) :== 0
        reps_ind = select(reps_ind, valid)
    }
    if (ntot > 0) {
        valid = rowsum(reps_tot :== .) :== 0
        reps_tot = select(reps_tot, valid)
    }
    if (nendo > 0) {
        valid = rowsum(reps_r2 :== .) :== 0
        reps_r2 = select(reps_r2, valid)
    }

    br.reps_path = reps_path
    br.reps_load = reps_load
    br.reps_weg = reps_weg
    br.reps_ind = reps_ind
    br.reps_tot = reps_tot
    br.reps_r2 = reps_r2
    br.n_inadmiss = n_inad

    /* covariance of the path coefficients (for e(V) / estout) */
    if (npaths > 0 & rows(reps_path) > 1) {
        br.cov_path = (cross(reps_path, reps_path) - ///
            rows(reps_path) * mean(reps_path)' * mean(reps_path)) / ///
            (rows(reps_path) - 1)
    }
    else {
        br.cov_path = J(npaths, npaths, .)
    }

    br.se_path = J(1, (npaths > 1 ? npaths : 1), .)
    br.se_load = J(1, (nload > 1 ? nload : 1), .)
    br.se_weg = J(1, (nweg > 1 ? nweg : 1), .)
    br.ci_path = J(2, (npaths > 1 ? npaths : 1), .)
    br.ci_load = J(2, (nload > 1 ? nload : 1), .)
    br.ci_weg = J(2, (nweg > 1 ? nweg : 1), .)
    br.ci_ind = J(2, (nind > 1 ? nind : 1), .)
    br.ci_tot = J(2, (ntot > 1 ? ntot : 1), .)
    br.ci_r2 = J(2, (nendo > 1 ? nendo : 1), .)

    /* jackknife (for BCa acceleration) */
    hasjack = 0
    if (usebca == "bca" & nojack != "nojack" & n > 3) {
        jack_path = J(n, (npaths > 1 ? npaths : 1), 0)
        jack_load = J(n, (nload > 1 ? nload : 1), 0)
        jack_weg = J(n, (nweg > 1 ? nweg : 1), 0)
        jack_ind = J(n, (nind > 1 ? nind : 1), 0)
        jack_tot = J(n, (ntot > 1 ? ntot : 1), 0)
        jack_r2 = J(n, (nendo > 1 ? nendo : 1), 0)
        for (it = 1; it <= n; it++) {
            keep = selectindex((1::n) :!= it)
            eb = plssem2_estimate(X[keep, .], adj_meas, adj_struct, modes,
                tol, maxiter, wscheme, convcrit, init, rawsum, noscale)
            if (eb.converged) {
                if (npaths > 0) jack_path[it, .] = plssem2_extract_path(eb.pathcoef, adj_struct)
                if (nload > 0) jack_load[it, .] = plssem2_extract_load(eb.loadings, adj_meas)
                if (nweg > 0) jack_weg[it, .] = plssem2_extract_load(eb.outer_weights, adj_meas)
                if (nind > 0) jack_ind[it, .] = vec(plssem2_effects(eb.pathcoef, adj_struct, 1))'
                if (ntot > 0) jack_tot[it, .] = vec(plssem2_effects(eb.pathcoef, adj_struct, 0))'
                if (nendo > 0) jack_r2[it, .] = plssem2_extract_r2(eb.r2, adj_struct)
            }
        }
        hasjack = 1
    }

    /* percentile CIs */
    for (k = 1; k <= npaths; k++) {
        if (rows(reps_path) > 1) br.se_path[1, k] = sqrt(variance(reps_path[., k]))
        br.ci_path[1, k] = plssem2_quantile(reps_path[., k], (100 - level) / 200)
        br.ci_path[2, k] = plssem2_quantile(reps_path[., k], 1 - (100 - level) / 200)
    }
    for (k = 1; k <= nload; k++) {
        if (rows(reps_load) > 1) br.se_load[1, k] = sqrt(variance(reps_load[., k]))
        br.ci_load[1, k] = plssem2_quantile(reps_load[., k], (100 - level) / 200)
        br.ci_load[2, k] = plssem2_quantile(reps_load[., k], 1 - (100 - level) / 200)
    }
    for (k = 1; k <= nweg; k++) {
        if (rows(reps_weg) > 1) br.se_weg[1, k] = sqrt(variance(reps_weg[., k]))
        br.ci_weg[1, k] = plssem2_quantile(reps_weg[., k], (100 - level) / 200)
        br.ci_weg[2, k] = plssem2_quantile(reps_weg[., k], 1 - (100 - level) / 200)
    }
    for (k = 1; k <= nind; k++) {
        br.ci_ind[1, k] = plssem2_quantile(reps_ind[., k], (100 - level) / 200)
        br.ci_ind[2, k] = plssem2_quantile(reps_ind[., k], 1 - (100 - level) / 200)
    }
    for (k = 1; k <= ntot; k++) {
        br.ci_tot[1, k] = plssem2_quantile(reps_tot[., k], (100 - level) / 200)
        br.ci_tot[2, k] = plssem2_quantile(reps_tot[., k], 1 - (100 - level) / 200)
    }
    for (k = 1; k <= nendo; k++) {
        br.ci_r2[1, k] = plssem2_quantile(reps_r2[., k], (100 - level) / 200)
        br.ci_r2[2, k] = plssem2_quantile(reps_r2[., k], 1 - (100 - level) / 200)
    }

    /* BCa */
    if (usebca == "bca") {
        if (!hasjack) {
            /* bias-corrected only (acceleration 0) */
            if (npaths > 0) br.ci_path = plssem2_bca0(origp, reps_path, level)
            if (nload > 0) br.ci_load = plssem2_bca0(origl, reps_load, level)
            if (nweg > 0) br.ci_weg = plssem2_bca0(origw, reps_weg, level)
            if (nind > 0) br.ci_ind = plssem2_bca0(origi, reps_ind, level)
            if (ntot > 0) br.ci_tot = plssem2_bca0(origt, reps_tot, level)
            if (nendo > 0) br.ci_r2 = plssem2_bca0(origr, reps_r2, level)
        }
        else {
            if (npaths > 0) br.ci_path = plssem2_bca(origp, reps_path, jack_path, level)
            if (nload > 0) br.ci_load = plssem2_bca(origl, reps_load, jack_load, level)
            if (nweg > 0) br.ci_weg = plssem2_bca(origw, reps_weg, jack_weg, level)
            if (nind > 0) br.ci_ind = plssem2_bca(origi, reps_ind, jack_ind, level)
            if (ntot > 0) br.ci_tot = plssem2_bca(origt, reps_tot, jack_tot, level)
            if (nendo > 0) br.ci_r2 = plssem2_bca(origr, reps_r2, jack_r2, level)
        }
    }
    return(br)
}

/* bias-corrected (no acceleration) intervals */
real matrix plssem2_bca0(real vector orig, real matrix reps,
    real scalar level) {
    real matrix res
    real scalar K, k, z0, p1, p2, za2, prop
    K = length(orig)
    za2 = invnormal((100 - level) / 200)
    res = J(2, K, .)
    for (k = 1; k <= K; k++) {
        prop = mean(reps[., k] :< orig[k])
        if (prop < 1e-6) prop = 1e-6
        if (prop > 1 - 1e-6) prop = 1 - 1e-6
        z0 = invnormal(prop)
        p1 = normal(z0 + (z0 + za2))
        p2 = normal(z0 + (z0 - za2))
        res[1, k] = plssem2_quantile(reps[., k], p1)
        res[2, k] = plssem2_quantile(reps[., k], p2)
    }
    return(res)
}

/* bias-corrected and accelerated intervals */
real matrix plssem2_bca(real vector orig, real matrix reps,
    real matrix jack, real scalar level) {
    real matrix res
    real scalar K, k, z0, acc, p1, p2, za2, prop, num, den
    real colvector jm
    K = length(orig)
    za2 = invnormal((100 - level) / 200)
    res = J(2, K, .)
    for (k = 1; k <= K; k++) {
        prop = mean(reps[., k] :< orig[k])
        if (prop < 1e-6) prop = 1e-6
        if (prop > 1 - 1e-6) prop = 1 - 1e-6
        z0 = invnormal(prop)
        jm = mean(jack[., k])
        num = sum((jm :- jack[., k]) :^ 3)
        den = 6 * (sum((jm :- jack[., k]) :^ 2))^1.5
        acc = den == 0 ? 0 : num / den
        p1 = normal(z0 + (z0 + za2) / (1 - acc * (z0 + za2)))
        p2 = normal(z0 + (z0 - za2) / (1 - acc * (z0 - za2)))
        res[1, k] = plssem2_quantile(reps[., k], p1)
        res[2, k] = plssem2_quantile(reps[., k], p2)
    }
    return(res)
}

/* ---------------------------------------------------------------------- */
/* multi-group analysis (permutation-based)                               */
/* ---------------------------------------------------------------------- */
struct plssem2_mgares scalar plssem2_mga(
    real matrix X,
    real colvector group,
    real matrix adj_meas,
    real matrix adj_struct,
    real colvector modes,
    real scalar tol,
    real scalar maxiter,
    string scalar wscheme,
    string scalar convcrit,
    string scalar init,
    string scalar method,
    real scalar reps,
    string scalar seed,
    real scalar level) {

    struct plssem2_mgares scalar mg
    struct plssem2_res scalar e1, e2, ep
    real vector gvals
    real scalar n, g1, g2, r, j, k, npar, n1
    real colvector idx, gperm, a1, a2
    real rowvector p1, p2, dperm
    real matrix cnt, diff_obs

    n = rows(X)
    gvals = uniqrows(group)
    if (length(gvals) != 2) {
        exit(198)
    }
    g1 = gvals[1]
    g2 = gvals[2]
    e1 = plssem2_estimate(X[selectindex(group :== g1), .], adj_meas,
        adj_struct, modes, tol, maxiter, wscheme, convcrit, init, "", "")
    e2 = plssem2_estimate(X[selectindex(group :== g2), .], adj_meas,
        adj_struct, modes, tol, maxiter, wscheme, convcrit, init, "", "")
    mg.scores1 = e1.scores
    mg.scores2 = e2.scores
    mg.W1 = e1.outer_weights
    mg.W2 = e2.outer_weights
    mg.L1 = e1.loadings
    mg.L2 = e2.loadings
    mg.B1 = e1.pathcoef
    mg.B2 = e2.pathcoef
    mg.R21 = e1.r2
    mg.R22 = e2.r2

    p1 = plssem2_extract_path(e1.pathcoef, adj_struct)
    p2 = plssem2_extract_path(e2.pathcoef, adj_struct)
    npar = length(p1)
    diff_obs = abs(p1 - p2)
    mg.diff_obs = diff_obs
    if (seed != "") rseed(strtoreal(seed))
    n1 = sum(group :== g1)
    cnt = J(1, npar, 0)
    for (r = 1; r <= reps; r++) {
        idx = order(runiform(n, 1), 1)
        gperm = group[idx]
        a1 = selectindex(gperm :== g1)
        a2 = selectindex(gperm :== g2)
        if (length(a1) == 0 | length(a2) == 0) continue
        ep = plssem2_estimate(X[a1, .], adj_meas, adj_struct, modes, tol,
            maxiter, wscheme, convcrit, init, "", "")
        dperm = abs(p1 - plssem2_extract_path(ep.pathcoef, adj_struct))
        ep = plssem2_estimate(X[a2, .], adj_meas, adj_struct, modes, tol,
            maxiter, wscheme, convcrit, init, "", "")
        dperm = dperm + abs(plssem2_extract_path(ep.pathcoef, adj_struct) - p2)
        cnt = cnt + (dperm :>= diff_obs)
    }
    mg.p_values = (cnt :+ 1) :/ (reps :+ 1)
    return(mg)
}

end
