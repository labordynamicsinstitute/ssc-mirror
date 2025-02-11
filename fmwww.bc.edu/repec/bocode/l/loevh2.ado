*! Version 1.1, Dirk Enzmann (10-Feb-2025)

cap program drop loevh2
program define loevh2, rclass sortpreserve byable(recall)

// Calculate Loevinger's H for two dichotomous variables

   version 15
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Table Level(cilevel) ABbreviate(integer 8)]
   marksample touse, nov
   if "`weight'" == "aweight" & "`exp'" != "" local wgt = "[aw=`exp']"
   if "`weight'" == "fweight" & "`exp'" != "" local wgt = "[fw=`exp']"

   // Check that variables are binary (0/1)
   foreach var of varlist `varlist' {
      qui levelsof `var' if `touse', local(levels)
      if `: word count `levels'' != 2 {
         di as error "Error: `var' must be a binary (0/1) variable"
         exit 450
      }
      foreach val of local levels {
         if !inlist(`val', 0, 1) {
            di as error "Error: `var' must contain only values 0 and 1"
            exit 450
         }
      }
   }
   
   // Calculation:

   if "`table'" == "" qui tabulate `varlist' if `touse' `wgt', matcell(T)
   else tabulate `varlist' if `touse' `wgt', cell expected matcell(T)
   tempname h se z p lb ub N
   local end_mata end  // to use end to end mata within program
   mata
      T = st_matrix("T")
      if (colsum(T)[1,2] < rowsum(T)[2,1]) {
         st_numscalar("`h'",1-T[1,2]/(colsum(T)[1,2]*rowsum(T)[1,1]/rowsum(colsum(T))))
      }
      else {
         st_numscalar("`h'",1-T[2,1]/(colsum(T)[1,1]*rowsum(T)[2,1]/rowsum(colsum(T))))
      }
   `end_mata'
   qui corr `varlist' if `touse' `wgt', c
   if "`weight'"=="fweight" scalar `N' = r(sum_w)
   else scalar `N' = r(N)
   scalar `N' = r(N)
   scalar `z' = r(cov_12)/sqrt(r(Var_2)*r(Var_1))*sqrt(`N'-1)
   scalar `se' = `h'/`z'
   scalar `p' = 2*(1-normal(abs(`z')))
   scalar `lb' = `h' - abs(invnormal(`=(1-`level'/100)/2'))*`se'
   scalar `ub' = `h' + abs(invnormal(`=(1-`level'/100)/2'))*`se'

   // Output:

   local v1 : word 1 of `varlist'
   local v1 = abbrev("`v1'",`abbreviate')
   local v2 : word 2 of `varlist'
   local v2 = abbrev("`v2'",`abbreviate')
   local vars = "`v1' `v2'"
   local varsl `=length("`vars'")'
   local colsv = max(`varsl',17)+2
   local inc = `colsv'-19

   local ttl "Std. err."
   local cil `=string(`level')'
   local cil `=length("`cil'")'
   local spaces ""
   if `cil' == 2 local spaces "   "
   else if `cil' == 4 local spaces " "

   di _n in smcl in gr _col(`=59+`inc'') "Number of obs = " as res %7.0fc `N' /*
     */ _n _n in smcl in gr _col(`=23 + `inc'') "Loevinger" /*
     */ _n in smcl in gr /*
     */ " Variables" _col(`colsv') " {c |}" _col(`=18+`inc'') /*
     */ _col(`=25+`inc'') "H Coeff" /*
     */ _col(`=34+`inc'') "`ttl'" /*
     */ _col(`=51+`inc'') "z" /*
     */ _col(`=58+`inc'') "p" /*
     */ _col(`=59+`inc'') `"`spaces'[`=strsubdp("`level'")'% conf. interval]"'/*
     */ _n "{hline `colsv'}{c +}{hline 61}"

   local efmt %10.0fc
   local ofmt "%7.0g"

   di in smcl in gr /*
     */ " `vars'" _col(`colsv') " {c |}" _col(`=18+`inc'') as res /*
     */ _col(`=25+`inc'') `ofmt' `h' /*
     */ _col(`=36+`inc'') `ofmt' `se' /*
     */ _col(`=45+`inc'') %7.2f  `z' /*
     */ _col(`=51+`inc'') %7.3f  `p' /*
     */ _col(`=62+`inc'') `ofmt' `lb' /*
     */ _col(`=75+`inc'') `ofmt' `ub'

   // r-class returns:

   return scalar level = `level'
   if _by() return local group = "`_byvars'"
   if "`wgt'" != "" {
     return local weight = "`exp'" 
     return local weight_type = "`weight'"
   } 
   return local var2 : word 2 of `varlist'
   return local var1 : word 1 of `varlist'
   return scalar N = r(N)
   return scalar ub = `ub'
   return scalar lb = `lb'
   return scalar se = `se'
   return scalar loevh = `h'
   scalar drop `h'
end
