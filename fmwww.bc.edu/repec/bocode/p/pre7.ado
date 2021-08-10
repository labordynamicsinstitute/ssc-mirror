*! version 1.1 P.MILLAR 13May2005
*! Copyright 2005 Paul Millar
*! This software can be used for non-commercial purposes only. 
*! The copyright is retained by the developer.
*! Copyright 2005 Paul Millar
*! Version 1.1 changed to allow proper handling of wieghts 

program define pre, rclass
  version 7.0
  syntax [varlist] , [Cutoff(real 0.5)]

/* The approach of this procedure has three steps */
/* 1. find the errors when guessing the mode = E1 */
/* 2. find the errors when guessing what the model predicts = E2 */
/* 3. PRE = (E1-E2)/E1 */

if `cutoff'<0 | `cutoff'>1 {
  display "Value of Cutoff must be between 0 and 1"
  exit 198
  }
local dv=e(depvar)
capture confirm variable `dv'

capture confirm new variable guess2
if _rc!=0 {
  drop guess2
  }
tempvar guess2
quietly gen guess2=.
label variable guess2 "Prediction of `dv'"

local type=e(cmd)
local PRE="."

local wtype="`e(wtype)'"
if "`e(wtype)'" == "pweight" {
  local wtype="aweight"
  }

/* ---------------------- */
/* procedure for logistic */
/* ---------------------- */
if "`type'"=="logistic" |  "`type'"=="logit" | "`type'"=="probit" {
  capture confirm new variable probdv
  if _rc!=0 {
    drop probdv
    }
  tempvar probdv
  quietly predict probdv if e(sample)
  quietly summ `dv' [`wtype' `e(wexp)'] if probdv!=.
  local guess1=int(r(mean)+(1-`cutoff'))
  quietly summ `dv' [`wtype' `e(wexp)'] if `dv' != `guess1' & probdv!=.
  local e1=r(N)
  quietly replace guess2=int(probdv+(1-`cutoff'))
  quietly summ `dv' [`wtype' `e(wexp)'] if `dv' != guess2 & probdv !=.
  local e2=r(N)
  }
/* -------------------- */
/* procedure for mlogit */
/* -------------------- */
else if "`type'"=="mlogit"  {
  local ncats=colsof(e(cat))
  mat def temp=e(cat)
  /* find the mode (i.e. the best guess of the dv) */
  local mode=0
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    quietly summ `dv'  [`wtype' `e(wexp)'] if e(sample) & `dv'==`catval'
    local freq=r(N)
    if `freq' > `mode' {
      local mode=`freq'
      local modcat=`catval'
      }
    }
  /* Get predicted probabilities for each category of DV */
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    capture confirm new variable prob`catval'
    if _rc!=0 {
      drop prob`catval'
      }
    tempvar prob`catval'
    quietly predict prob`catval'  if e(sample), outcome(`catval')
    }
  /* Use predicted probabilities to get prediction of DV */
  capture confirm new variable maxprob
  if _rc!=0 {
    drop maxprob
    }
  quietly gen maxprob=0
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    quietly replace maxprob=prob`catval' if prob`catval' > maxprob
    }
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    quietly replace guess2=`catval' if prob`catval' == maxprob & e(sample)
    }
  /* find the errors if we guess the mode */
  quietly summ `dv' [`wtype' `e(wexp)'] if e(sample)
  local nobs=r(N)
  local e1=`nobs'-`mode'
  quietly summ `dv' [`wtype' `e(wexp)'] if `dv'!= guess2 & e(sample)
  local e2=r(N)
  }
/* -------------------- */
/* procedure for ologit */
/* -------------------- */
else if "`type'"=="ologit"  | "`type'"=="oprobit" {
  local ncats=colsof(e(cat))
  mat cat=e(cat)
  /* find the mode (i.e. the best guess of the dv) */
  local mode=0
  forvalues i = 1/`ncats' {
    local catval=cat[1,`i']
    qui summ `dv' [`wtype' `e(wexp)'] if `dv' == `catval' & e(sample)
    if `mode' < r(N) {
      local mode=r(N)
      local modcat=`catval'
      }
    }

  /* get the probabilities for each category (they sum to 1.0) */
  local pvars=" "
  forvalues i = 1/`ncats' {
    local catval=cat[1,`i']
    capture confirm new variable prob`catval'
    if _rc!=0 {
      drop prob`catval'
      }
    tempvar prob`catval'
    quietly predict prob`catval' if e(sample), outcome(`catval')
    }

  capture confirm new variable maxprob
  if _rc!=0 {
    drop maxprob
    }
  tempvar maxprob
  qui gen maxprob=0

  capture confirm new variable guess2
  if _rc!=0 {
    drop guess2
    }
  quietly gen guess2=.

  forvalues i = 1/`ncats' {
    local catval=cat[1,`i']
    qui replace maxprob=prob`catval' if prob`catval'>maxprob
    quietly replace guess2=`catval'  if maxprob == prob`catval'
    }

  /* find the errors if we guess the mode */
  quietly summ `dv' if e(sample)
  local nobs=r(N)
  local e1=`nobs'-`mode'
  quietly summ `dv' [`wtype' `e(wexp)'] if `dv'!= guess2 & e(sample)
  local e2=r(N)
  }

/* --------------------- */
/* procedure for regress */
/* --------------------- */
else if "`type'" == "regress" {
  local e1=1
  local e2=1-e(r2)
  }

/* --------------------- */
/* procedure for Poisson */
/* --------------------- */
else if "`type'" == "poisson" | "`type'" == "nbreg"  {
  qui tab1 `dv', nol matrow(rowval)
  local ncats=r(r)
  /* find the mode (i.e. the best guess of the dv) */
  local mode=0
  forvalues i = 1/`ncats' {
    local catval=rowval[`i',1]
    qui summ `dv' [`wtype' `e(wexp)'] if `dv' == `catval' & e(sample)
    if `mode' < r(N) {
      local mode=r(N)
      local modcat=`catval'
      }
    }
  mat drop rowval
  tempvar probdv
  quietly predict probdv if e(sample)
  qui replace guess2=round(probdv)
  quietly summ `dv' if e(sample)
  local nobs=r(N)
  local e1=`nobs'-`mode'
  quietly summ `dv' [`wtype' `e(wexp)'] if `dv'!= guess2 & e(sample)
  local e2=r(N)
  }

/* --------------------------------- */
/* Now we are ready to calc PRE!!!   */
/* --------------------------------- */
local pre=(`e1'-`e2')/`e1'
di as text _newline "Model reduces errors in the prediction of `dv' by " as result %6.2f `pre'*100 "%"

/* get matrix of predicted versus actual */
if "`type'" != "regress" {
  tab `dv' guess2 if e(sample), matcell(temp0) matcol(temp1) matrow(temp2)
  }

if "`type'"=="logistic" |  "`type'"=="logit" | "`type'"=="probit" {
  local pos=temp0[2,2]/(temp0[1,2]+temp0[2,2])*100
  di as text "If model predicts `dv'=1, there is a " %2.0f `pos' "% chance of this being correct"
  }

if "`type'"=="mlogit" {
  local good=0
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    local good=`good' + temp0[`i',`i']
    }
  local nc=`ncats'+1
  local good=`good'/`nobs'*100
  di as text "Model predicts `dv' correctly " %2.0f `good' "% of the time"
  }


/* Cleanup */
if "`type'"=="logistic" |  "`type'"=="logit" | "`type'"=="probit" {
  drop probdv guess2
  }
else if "`type'"=="mlogit" {
  drop guess2
  forvalues i = 1/`ncats' {
    local catval=temp[1,`i']
    if `catval'!=`e(ibasecat)' {
      drop prob`catval'
      }
    }
  mat drop temp
  }
else if "`type'"=="ologit" | "`type'"=="oprobit" {
  drop guess2
  forvalues i = 1/`ncats' {
    local catval=cat[1,`i']
    drop prob`catval'
    }
  mat drop cat
  }
else if "`type'"=="poisson" | "`type'"=="nbreg" {
  drop guess2 probdv
  }

if "`type'" != "regress" {
  mat drop temp0 temp1 temp2
  }

return local pre=`pre'
return local PRE=`pre'

end
