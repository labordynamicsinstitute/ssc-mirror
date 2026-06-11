*! xtquantilebreak.ado — Shrinkage Quantile Regression for Panel Data
*!                       with Multiple Structural Breaks
*! Implements: Zhang, Zhu, Feng & He (2022, Canadian Journal of Statistics 50:820-851)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define xtquantilebreak, eclass
  version 14.0

  capture findfile _xtquantilebreak_engine.ado
  if _rc {
    di in red "required file _xtquantilebreak_engine.ado not found"
    exit 601
  }
  qui run "`r(fn)'"

  syntax varlist(min=2 ts) [if] [in] [, ///
    Quantiles(numlist >0 <1 sort)   ///
    Lambda2(numlist >0 sort)        ///
    Lambda1(real 0.05)              ///
    Kappa(real 1)                   ///
    MAXIter(integer 15)             ///
    TOLerance(real 1e-4)            ///
    Rconstant(real 0.5)             ///
    noCONStant                      ///
    NOGraph                         ///
    HEATmap                         ///
    Level(cilevel)                  ///
  ]

  * ---- quantiles ----
  if "`quantiles'" == "" local quantiles "0.25 0.5 0.75"
  local K : word count `quantiles'

  * ---- lambda2 grid (default log-spaced) ----
  if "`lambda2'" == "" local lambda2 "0.005 0.01 0.025 0.05 0.1 0.25 0.5 1"

  * ---- panel setup ----
  qui xtset
  local ivar = r(panelvar)
  local tvar = r(timevar)
  if "`ivar'" == "" | "`tvar'" == "" {
    di in red "panel data not set; use {bf:xtset} first"
    exit 459
  }

  gettoken depvar indepvars : varlist
  local p : word count `indepvars'
  if `p' == 0 {
    di in red "at least one independent variable required"
    exit 198
  }

  marksample touse
  markout `touse' `varlist'

  qui levelsof `ivar' if `touse', local(panels)
  local N : word count `panels'

  qui summ `tvar' if `touse', meanonly
  local Tmin = r(min)
  local Tmax = r(max)
  local TT = `Tmax' - `Tmin' + 1
  if `TT' < 3 {
    di in red "at least 3 time periods required"
    exit 198
  }

  * ---- balance check ----
  qui count if `touse'
  if r(N) != `N' * `TT' {
    di in red "strongly balanced panel required (N*T = " `N'*`TT' ", found " r(N) ")"
    di in red "use {bf:tsfill} or impute missing observations first"
    exit 459
  }

  local addcons = 1
  if "`constant'" == "noconstant" local addcons = 0
  local pp = `p' + `addcons'

  * ====================================================================
  * BUILD DATA MATRICES (N x T) and (N x T*p)
  * ====================================================================
  tempname y_mat x_mat
  matrix `y_mat' = J(`N', `TT', 0)
  matrix `x_mat' = J(`N', `TT'*`p', 0)

  local ui = 0
  foreach i of local panels {
    local ui = `ui' + 1
    forvalues t = `Tmin'/`Tmax' {
      local col = `t' - `Tmin' + 1
      qui summ `depvar' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
      if r(N) > 0 matrix `y_mat'[`ui', `col'] = r(mean)
    }
    local xi = 0
    foreach xv of local indepvars {
      local xi = `xi' + 1
      forvalues t = `Tmin'/`Tmax' {
        local ct = `t' - `Tmin' + 1
        local xcol = (`ct' - 1) * `p' + `xi'
        qui summ `xv' if `touse' & `ivar' == `i' & `tvar' == `t', meanonly
        if r(N) > 0 matrix `x_mat'[`ui', `xcol'] = r(mean)
      }
    }
  }

  * ---- coefficient names ----
  local cnames ""
  if `addcons' local cnames "_cons"
  local cnames "`cnames' `indepvars'"

  * ---- tau row vector for Mata ----
  tempname tauv lamv
  matrix `tauv' = J(1, `K', 0)
  local j = 0
  foreach q of local quantiles {
    local j = `j' + 1
    matrix `tauv'[1, `j'] = `q'
  }
  local nlam : word count `lambda2'
  matrix `lamv' = J(1, `nlam', 0)
  local j = 0
  foreach l of local lambda2 {
    local j = `j' + 1
    matrix `lamv'[1, `j'] = `l'
  }

  * ====================================================================
  * RUN MATA ENGINE
  * ====================================================================
  capture matrix drop __xtqb_reginfo __xtqb_regcoef __xtqb_regse ///
    __xtqb_betapath __xtqb_brkmat __xtqb_alpha __xtqb_icvec __xtqb_lamgrid
  capture scalar drop __xtqb_lambda __xtqb_ic __xtqb_nbreaks __xtqb_pp __xtqb_K

  di as txt _n "Estimating (N=`N', T=`TT', K=`K' quantiles, " ///
     "`nlam' lambda values)..." _c

  mata: _xtqb_run(st_matrix("`y_mat'"), st_matrix("`x_mat'"), ///
        `N', `TT', `p', st_matrix("`tauv'"), `lambda1', ///
        st_matrix("`lamv'"), `kappa', `maxiter', `tolerance', ///
        `addcons', `rconstant')

  di as txt " done."

  local lambda  = __xtqb_lambda
  local icval   = __xtqb_ic
  local nbtotal = __xtqb_nbreaks

  * ====================================================================
  * DISPLAY (Table 6 style)
  * ====================================================================
  _xtqb_display, reginfo(__xtqb_reginfo) regcoef(__xtqb_regcoef) ///
     regse(__xtqb_regse) brkmat(__xtqb_brkmat) ///
     k(`K') pp(`pp') tmin(`Tmin') tt(`TT') ///
     quantiles(`quantiles') cnames(`cnames') ///
     n(`N') depvar(`depvar') lambda(`lambda') kappa(`kappa') ///
     nbtotal(`nbtotal') ic(`icval')

  * ====================================================================
  * GRAPHS
  * ====================================================================
  if "`nograph'" == "" {
    capture xtquantilebreak_graph, betapath(__xtqb_betapath) ///
        brkmat(__xtqb_brkmat) reginfo(__xtqb_reginfo) ///
        regcoef(__xtqb_regcoef) regse(__xtqb_regse) ///
        k(`K') pp(`pp') tmin(`Tmin') tt(`TT') ///
        quantiles(`quantiles') cnames(`cnames') ///
        depvar(`depvar') level(`level') `heatmap'
    if _rc di as err "(graph step failed; rc=" _rc ")"
  }

  * ====================================================================
  * STORED RESULTS
  * ====================================================================
  tempname bnames
  ereturn clear
  ereturn scalar N = `N'
  ereturn scalar T = `TT'
  ereturn scalar p = `p'
  ereturn scalar K = `K'
  ereturn scalar nbreaks = `nbtotal'
  ereturn scalar lambda2 = `lambda'
  ereturn scalar lambda1 = `lambda1'
  ereturn scalar kappa = `kappa'
  ereturn scalar ic = `icval'

  ereturn matrix reginfo = __xtqb_reginfo
  ereturn matrix coef    = __xtqb_regcoef
  ereturn matrix se      = __xtqb_regse
  ereturn matrix betapath = __xtqb_betapath
  ereturn matrix breaks  = __xtqb_brkmat
  ereturn matrix alpha   = __xtqb_alpha
  ereturn matrix ic_path = __xtqb_icvec
  ereturn matrix lambda_grid = __xtqb_lamgrid

  ereturn local depvar "`depvar'"
  ereturn local indepvars "`indepvars'"
  ereturn local quantiles "`quantiles'"
  ereturn local coefnames "`cnames'"
  ereturn local cmd "xtquantilebreak"
  ereturn local cmdline "xtquantilebreak `0'"
  ereturn local title "Shrinkage QR with Structural Breaks (Zhang et al. 2022)"
end


* ====================================================================
* DISPLAY PROGRAM  (mirrors Table 6 of Zhang et al. 2022)
* ====================================================================
program _xtqb_display
  syntax, reginfo(name) regcoef(name) regse(name) brkmat(name) ///
    k(integer) pp(integer) tmin(integer) tt(integer) ///
    quantiles(string) cnames(string) n(integer) depvar(string) ///
    lambda(string) kappa(string) nbtotal(integer) ic(string)

  local K = `k'
  local nr = rowsof(`reginfo')

  * total width: 18 for regime + 13 per coefficient
  local cw = 13
  local lead = 20
  local twidth = `lead' + `pp' * `cw'
  if `twidth' > 100 local twidth = 100

  di
  di in smcl in gr "{hline `twidth'}"
  di in smcl in gr _col(3) "{bf:Shrinkage Quantile Regression with Multiple Structural Breaks}"
  di in smcl in gr _col(3) "Zhang, Zhu, Feng and He (2022)"
  di in smcl in gr "{hline `twidth'}"
  di in gr _col(3) "Dependent variable" _col(28) "= " in ye "`depvar'"
  di in gr _col(3) "Cross-sections (N)" _col(28) "= " in ye "`n'" ///
     in gr _col(45) "Periods (T)" _col(60) "= " in ye "`tt' (`tmin'-`=`tmin'+`tt'-1')"
  di in gr _col(3) "Quantile levels" _col(28) "= " in ye "`quantiles'"
  di in gr _col(3) "Selected lambda2" _col(28) "= " in ye %9.5f `lambda' ///
     in gr _col(45) "Total breaks" _col(60) "= " in ye "`nbtotal'"
  di in gr _col(3) "Information criterion" _col(28) "= " in ye %9.4f `ic' ///
     in gr _col(45) "kappa" _col(60) "= " in ye "`kappa'"
  di in smcl in gr "{hline `twidth'}"
  di in smcl in gr _col(3) "{bf:Regime-specific coefficient estimates}"
  di in smcl in gr "{hline `twidth'}"

  * ---- column header ----
  di in gr _col(3) "Regime" _c
  local pos = `lead'
  local ci = 0
  foreach cn of local cnames {
    local ci = `ci' + 1
    local cshow = abbrev("`cn'", 11)
    di in gr _col(`=`pos'+1') %~12s "`cshow'" _c
    local pos = `pos' + `cw'
  }
  di
  di in smcl in gr "{hline `twidth'}"

  * ---- rows grouped by quantile ----
  forvalues kk = 1/`K' {
    local q : word `kk' of `quantiles'
    di in gr _col(3) in gr "{bf:tau = `q'}"
    forvalues r = 1/`nr' {
      if `reginfo'[`r', 1] == `kk' {
        local s = `reginfo'[`r', 3]
        local e = `reginfo'[`r', 4]
        local s_time = `s' + `tmin' - 1
        local e_time = `e' + `tmin' - 1
        di in ye _col(5) "`s_time'-`e_time'" _c
        local pos = `lead'
        forvalues d = 1/`pp' {
          local cf = `regcoef'[`r', `d']
          local sv = `regse'[`r', `d']
          local stars ""
          if `sv' > 0 & `sv' < . {
            local z = abs(`cf' / `sv')
            local pv = 2 * (1 - normal(`z'))
            if `pv' < 0.01 local stars "***"
            else if `pv' < 0.05 local stars "**"
            else if `pv' < 0.10 local stars "*"
          }
          local cfstr = string(`cf', "%8.3f") + "`stars'"
          di in ye _col(`=`pos'+1') %~12s "`cfstr'" _c
          local pos = `pos' + `cw'
        }
        di
      }
    }
  }
  di in smcl in gr "{hline `twidth'}"
  di in gr _col(3) "{it:Significance: * p<0.10, ** p<0.05, *** p<0.01.}"
  di in gr _col(3) "{it:Standard errors via Powell kernel sandwich on regime sub-samples.}"
  di
end
