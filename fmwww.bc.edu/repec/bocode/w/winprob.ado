*! 1.0 14jan2025 Leonardo Guizzetti - initial version
program define winprob, sortpreserve rclass
  version 16
  syntax varlist (min=2 max=2 numeric) [if] [in] , ///
              [ ///
              alpha(real 0.05) ///
              test0(real 0.5) ///
              winfrac(name) DIRection(string) replace ///
              citype(string) ///
              verbose /// NOT DOCUMENTED
              ]
  marksample touse
  
  unab varlist : `varlist'
  
  tempvar orank grank winfracvar
  tempname wfname 
  tempname betahat winp se_winp t_crit z_winp t_winp t_df p_winp winp_ll winp_ul logit_se
  
  * parse varlist : groupvar scorevar
  tokenize `varlist'
  local grpvar `1'
  local scorevar `2'
  
  * syntax error checking
  cap confirm numeric var `grpvar'
  if _rc {
    di as err "Group variable must be numeric and binary (0/1) coded."
    exit 198
  }
  qui summ `grpvar', meanonly
  if !(`r(min)'==0 & `r(max)'==1) {
    di as err "Group variable must be numeric and binary (0/1) coded."
    exit 198
  }
  cap confirm numeric var `scorevar'
  if _rc {
    di as err "Score variable must be numeric."
    exit 198
  }
  
  if `"`direction'"'==`""' | substr(`"direction"',1,3)=="pos" | substr(`"direction"',1,1)=="p" | `"`direction'"'=="+" | `"`direction'"'==">" {
    local rankdir ""
    local ineqdir ">="
  }
  else if substr(`"direction"',1,3)=="neg" | substr(`"direction"',1,1)=="n" | `"`direction'"'=="-" | `"`direction'"'=="<" {
    local rankdir "-"
    local ineqdir "<="
  }
  else {
    di as err "Incorrect direction was specified."
    exit 198
  }
  
  if "`citype'"=="" {
    local citype "logit"
  }
  local citype = strlower("`citype'")
  if !inlist("`citype'", "normal", "logit") {
    di as err "Invalid confidence interval type declared."
    exit 198
  }
  
  if `"`winfrac'"'!=`""' {
    cap confirm new var `winfrac'
    if _rc & "`replace'"=="" {
      di as err "New win fraction variable name is already in use. Specify replace if you want to overwrite the values."
    } 
    else {
      cap drop `winfrac'
    }
    
    local `wfname' `winfrac'
  }
  else {
    local `wfname' `winfracvar'
  }
  
  if "`verbose'"=="" {
    local q quietly
  }

  * count number in each group and overall
  qui summ `scorevar' if `touse', meanonly
  local ntot = r(N)
  qui summ `scorevar' if `grpvar'==0 & `touse', meanonly
  local n0 = r(N)
  qui summ `scorevar' if `grpvar'==1 & `touse', meanonly
  local n1 = r(N)
  
  * compute WinP
  qui egen double `orank' = rank(cond(`touse', `rankdir'`scorevar', .))
  qui bys `grpvar': egen double `grank' = rank(cond(`touse', `rankdir'`scorevar', .))  
  qui gen double ``wfname'' = (`orank' - `grank') / (`ntot' - cond(`grpvar'==1, `n1', `n0'))
  `q' reg ``wfname'' i.`grpvar', vce(hc2) 
  `q' lincom 1.`grpvar'
  
  scalar `betahat' = r(estimate)
  scalar `winp' = (`betahat'/2) + 0.5
  scalar `se_winp' = `r(se)'
  scalar `t_df' = `r(df)'
  
  * CI construction
  if "`citype'"=="logit" {
    scalar `t_crit' = invt(`t_df', 1-(`alpha'/2))
    scalar `logit_se' = `se_winp'/(`winp'*(1-`winp'))
    scalar `winp_ll' = invlogit(logit(`winp') - `t_crit'*`se_winp'/(`winp'*(1-`winp')) )
    scalar `winp_ul' = invlogit(logit(`winp') + `t_crit'*`se_winp'/(`winp'*(1-`winp')) )
    scalar `t_winp' = (logit(`winp') - logit(`test0')) / `logit_se'
    scalar `p_winp' = 2*(1 - t(`t_df', abs(`t_winp')))
    
    return scalar logit_se = `logit_se'
    return scalar winp_ll = `winp_ll'
    return scalar winp_ul = `winp_ul'
    return scalar t = `t_winp'
    return scalar t_df = `t_df'
    return scalar p = `p_winp'
  }
  else if "`citype'"=="normal" {
    scalar `winp_ll' = `winp' - invnormal(1-(`alpha'/2))*`se_winp'
    scalar `winp_ul' = `winp' + invnormal(1-(`alpha'/2))*`se_winp'
    scalar `z_winp' = (`winp' - `test0') / `se_winp'
    scalar `p_winp' = 2*(1 - normal(abs(`z_winp')))
    
    return scalar winp_ll = `winp_ll'
    return scalar winp_ul = `winp_ul'
    return scalar z = `z_winp'
    return scalar p = `p_winp'
  }
  
  return local citype = "`citype'"
  return scalar alpha = `alpha'
  return scalar test0 = `test0'
  return scalar winp = `winp'
  return scalar se_winp = `se_winp'

  local cilevel = round(100*(1-`alpha'), 0.01)
  
    ** Print results to screen  
/*
    5   10   15   20   25   30   35   40   45   50   55   60   65   70   75
++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++
*/
  di as txt "Group variable:" _col(20) as res "`grpvar'" _n ///
     as txt "Score variable:" _col(20) as res "`scorevar'" _n ///
     as txt "Number of obs:"  _col(20) as res "`ntot'"
     
  if "`citype'"=="logit" {
    di as txt "df" _col(20) as res `t_df'
  }

  di as txt "H0 test:" _col(20) as res %-8.3f `test0'

  di in smcl as txt _n `"Win Prob. = Prob[ "' ///
                        `"{bf:`=abbrev("`scorevar'", 10)'}({bf:`=abbrev("`grpvar'", 10)'}==1)"' ///
                        `" `ineqdir' "' ///
                        `"{bf:`=abbrev("`scorevar'", 10)'}({bf:`=abbrev("`grpvar'", 10)'}==0) ]"'
  
  di in smcl as txt "{hline 11}{c TT}{hline 61}"

  di in smcl as txt _col(11) " {c |}" _c
  
  if "`citype'"=="logit" {
    di _col(59) "Logit"
    di in smcl as txt "Score" _col(11) " {c |}" ///
                      _col(14) %8s "Win Prob." ///
                      _col(25) %6s "Std. err." ///
                      _col(37) %6s "t" ///
                      _col(44) %6s "P>|t|" ///
                      _col(50) %24s "[`cilevel'% conf. interval]"  
    di in smcl as txt "{hline 11}{c +}{hline 61}"
    
    di in smcl as txt %10s `"`=abbrev("`scorevar'", 10)'"' ///
                      _col(11) " {c |}" ///
               as res _col(17) %6.3f `winp' ///
                      _col(28) %6.3f `se_winp' ///
                      _col(37) %6.3f `t_winp' ///
                      _col(44) %6.3f `p_winp' ///
                      _col(57) %6.3f `winp_ll' ///
                      _col(68) %6.3f `winp_ul'
    di in smcl as txt "{hline 11}{c BT}{hline 61}"
  }
  else if "`citype'"=="normal" {
    di _col(58) "Normal"
    di in smcl as txt "Score" _col(11) " {c |}" ///
                      _col(14) %8s "Win Prob." ///
                      _col(25) %6s "Std. err." ///
                      _col(37) %6s "t" ///
                      _col(44) %6s "P>|t|" ///
                      _col(50) %24s "[`cilevel'% conf. interval]"  
    di in smcl as txt "{hline 11}{c +}{hline 61}"
    
    di in smcl as txt %10s `"`=bsubstr("`scorevar'",1,10)'"' ///
                      _col(11) " {c |}" ///
               as res _col(17) %6.3f `winp' ///
                      _col(28) %6.3f `se_winp' ///
                      _col(37) %6.3f `z_winp' ///
                      _col(44) %6.3f `p_winp' ///
                      _col(57) %6.3f `winp_ll' ///
                      _col(68) %6.3f `winp_ul'
    di in smcl as txt "{hline 11}{c BT}{hline 61}"
    di as txt "Note: Normal confidence interval is only valid for large sample sizes." _n
  }
  
  ereturn clear

end
exit

Revision history:
1.0 14jan2025 Leonardo Guizzetti - initial version
