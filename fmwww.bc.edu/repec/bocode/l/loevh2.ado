*! Version 2.0.1, Dirk Enzmann (28-Aug-2025)

program define loevh2, rclass sortpreserve byable(recall)

// Calculate Loevinger's H for two dichotomous variables

   version 15
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Table Level(cilevel) Abbreviate(integer 8)]
   marksample touse, nov

   // Set up weight syntax - simplified
   local wgt ""
   if "`weight'" != "" & "`exp'" != "" local wgt "[`weight'=`exp']"

   // Check that variables are binary (0/1) - simplified
   foreach var of varlist `varlist' {
      qui levelsof `var' if `touse', local(levels)
      if `: word count `levels'' != 2 {
         // Fallback for bootstrap sampling issues
         qui levelsof `var', local(levels)
         if `: word count `levels'' != 2 {
            di as error "Error: `var' must be a binary (0/1) variable"
            exit 450
         }
      }
      foreach val of local levels {
         if !inlist(`val', 0, 1) {
            di as error "Error: `var' must contain only values 0 and 1"
            exit 450
         }
      }
   }

   // Tabulation - simplified (no duplication)
*   qui tabulate `varlist' if `touse' `wgt', matcell(T)
   if "`table'" == "" {
      qui tabulate `varlist' if `touse' `wgt', matcell(T)
   }
   else {
      tabulate `varlist' if `touse' `wgt', cell expected matcell(T)
   }

   // H coefficient calculation
   tempname h se z p lb ub N
   mata: st_local("end_mata", "end")  // cleaner approach
   mata
      T = st_matrix("T")
      if (colsum(T)[1,2] < rowsum(T)[2,1]) {
         st_numscalar("`h'",1-T[1,2]/(colsum(T)[1,2]*rowsum(T)[1,1]/rowsum(colsum(T))))
      }
      else {
         st_numscalar("`h'",1-T[2,1]/(colsum(T)[1,1]*rowsum(T)[2,1]/rowsum(colsum(T))))
      }
   `end_mata'

   // Statistical calculations - simplified
   qui corr `varlist' if `touse' `wgt', c
   if "`weight'" == "fweight" {
      mata: st_numscalar("`N'", sum(st_matrix("T")))
   }
   else {
      scalar `N' = r(N)
   }

   scalar `z' = r(cov_12)/sqrt(r(Var_2)*r(Var_1))*sqrt(`N'-1)
   scalar `se' = `h'/`z'
   scalar `p' = 2*(1-normal(abs(`z')))
   scalar `lb' = `h' - abs(invnormal(`=(1-`level'/100)/2'))*`se'
   scalar `ub' = `h' + abs(invnormal(`=(1-`level'/100)/2'))*`se'

   // Output formatting - simplified variable names
   tokenize `varlist'
   local v1 = abbrev("`1'", `abbreviate')
   local v2 = abbrev("`2'", `abbreviate')
   local vars "`v1' `v2'"
   local colsv = max(length("`vars'"), 17) + 2
   local inc = `colsv' - 19

   // Display output
   local dig = ceil(log10(scalar(`N'))) + 2
   local nd = 8 - `dig'
   local cil = string(`level')
   local spaces = cond(length("`cil'") == 2, "   ", " ")

   di _n in smcl in gr _col(`=58+`inc'+`nd'') /*
     */ "Number of obs = " as res %`dig'.0fc `N' /*
     */ _n _n in smcl in gr _col(`=23 + `inc'') "Loevinger" /*
     */ _n in smcl in gr /*
     */ " Variables" _col(`colsv') " {c |}" _col(`=18+`inc'') /*
     */ _col(`=25+`inc'') "H Coeff" /*
     */ _col(`=34+`inc'') "Std. err." /*
     */ _col(`=51+`inc'') "z" /*
     */ _col(`=58+`inc'') "p" /*
     */ _col(`=59+`inc'') `"`spaces'[`=strsubdp("`level'")'% conf. interval]"'/*
     */ _n "{hline `colsv'}{c +}{hline 61}"

   di in smcl in gr /*
     */ " `vars'" _col(`colsv') " {c |}" _col(`=18+`inc'') as res /*
     */ _col(`=25+`inc'') %7.0g `h' /*
     */ _col(`=36+`inc'') %7.0g `se' /*
     */ _col(`=45+`inc'') %7.2f `z' /*
     */ _col(`=51+`inc'') %7.3f `p' /*
     */ _col(`=62+`inc'') %7.0g `lb' /*
     */ _col(`=75+`inc'') %7.0g `ub'

   // Returns - simplified
   return scalar level = `level'
   if _by() return local group "`_byvars'"
   if "`wgt'" != "" {
      return local weight "`exp'"
      return local weight_type "`weight'"
   }
   return local var2 "`2'"
   return local var1 "`1'"
   return scalar N = `N'
   return scalar ub = `ub'
   return scalar lb = `lb'
   return scalar se = `se'
   return scalar loevh = `h'
   scalar drop `h'
end
