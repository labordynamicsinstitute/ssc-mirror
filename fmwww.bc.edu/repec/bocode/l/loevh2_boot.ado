*! Version 2.1, Dirk Enzmann (10-Feb-2025)

// Bootstrapping for loevh2 with support for:
// 1. No weights (simple bootstrap)
// 2. Analytic weights (bootstrap with normalized weights)
// 3. Frequency weights (using frame expansion)

capture program drop loevh2_boot
program define loevh2_boot, rclass byable(recall)

   version 14.0
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Reps(integer 100) Level(real 95) Seed(integer 0) Table ///
           ABbreviate(integer 8) Progress]
   marksample touse, nov

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

   // Store weight type and expression
   local weight_type "`weight'"
   local weight_exp "`exp'"
   if "`weight'" == "aweight" & "`exp'" != "" local wgt = "[aw=`exp']"
   if "`weight'" == "fweight" & "`exp'" != "" local wgt = "[fw=`exp']"

   // Get by-group variable
   if _by() {
       local by_var "`_byvars'"
       local by_val "`_byvalues'"
   }

   // Create temporary names
   tempname orig_h orig_z orig_p orig_se orig_lb orig_ub N bootframe dataframe boot_lb boot_ub boot_se boot_z boot_p

   // Set random seed if provided
   if `seed' != 0 set seed `seed'

   // Initial calculation with original data
   loevh2 `varlist' if `touse' `wgt', level(`level')
   scalar `orig_h' = r(loevh)
   scalar `orig_z' = r(z)
   scalar `orig_p' = r(p)
   scalar `orig_se' = r(se)
   scalar `orig_lb' = r(lb)
   scalar `orig_ub' = r(ub)
   scalar `N' = r(N)

   // Clean up any existing temporary frames
   capture frame drop `bootframe'
   capture frame drop `dataframe'

   // Create temporary frame for bootstrap results
   quietly {
      frame create `bootframe'
      frame `bootframe' {
         set obs `reps'
         gen h_boot = .
      }
   }

   // Handle different weight scenarios
   if "`weight_type'" == "fweight" {
      // For frequency weights: Create new frame with expanded data
      quietly {
         frame create `dataframe'

         // Copy required variables to new frame
         preserve
         keep if `touse'
         if _by() keep `varlist' `by_var' `weight_exp'
         else keep `varlist' `weight_exp'
         tempfile tempdata
         save `tempdata'
         restore

         // Load data into new frame and expand
         frame `dataframe' {
            use `tempdata', clear
            expand `weight_exp'
         }
      }

      // Bootstrap replications on expanded data
      if "`progress'" != "" {
         di _n "Bootstrap progress:"
         di "0%{c |}{dup 50:{c -}}| 100%"
         di "{c |}", _continue
      }
      forvalues i = 1/`reps' {
         if "`progress'" != "" & mod(`i', max(1, `reps'/50)) == 0 {
            di ".", _continue
         }
         frame `dataframe' {
            preserve
            if _by() qui bsample, strata(`by_var')
            else qui bsample
            quietly loevh2 `varlist'
            local h = r(loevh)
            restore
         }
         frame `bootframe': qui replace h_boot = `h' in `i'
      }
      frame drop `dataframe'
   }
   else {
      // For no weights or analytic weights
      if "`progress'" != "" {
         di _n "Bootstrap progress:"
         di "0%{c |}{dup 50:{c -}}| 100%"
         di "{c |}", _continue
      }
      forvalues i = 1/`reps' {
         if "`progress'" != "" & mod(`i', max(1, `reps'/50)) == 0 {
            di ".", _continue
         }
         preserve
         if "`weight_type'" == "aweight" {
            // Normalize weights to sum to N
            tempvar norm_weight
            qui gen double `norm_weight' = `weight_exp' * _N/sum(`weight_exp')
            local wgt "[aw=`norm_weight']"
         }

         if _by() quietly bsample if `touse', strata(`by_var')
         else quietly bsample if `touse'

         quietly loevh2 `varlist' if `touse' `wgt'
         local h = r(loevh)
         restore
         frame `bootframe': qui replace h_boot = `h' in `i'
      }
   }

   // Calculate bootstrap statistics
   if "`progress'" != "" di _n

   quietly frame `bootframe' {
      _pctile h_boot, p(`=(100-`level')/2' `=100-((100-`level')/2)')
      scalar `boot_lb' = r(r1)
      scalar `boot_ub' = r(r2)
      sum h_boot
      scalar `boot_se' = r(sd)
      scalar `boot_z' = `orig_h'/r(sd)
      scalar `boot_p' = 2 * (1 - normal(abs(`boot_z')))
   }
   frame drop `bootframe'

   * Display bootstrap results
   display _n as text "Bootstrap Results (percentile method):"
   display as text "Number of bootstrap replications: " as result `reps'
   if `seed' != 0 {
      display as text "Random seed: " as result `seed'
   }

   // Format table header
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

   di _n in smcl in gr /*
     */ in smcl in gr _col(`=23 + `inc'') "Bootstrap" /*
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
     */ _col(`=25+`inc'') `ofmt' `orig_h' /*
     */ _col(`=36+`inc'') `ofmt' `boot_se' /*
     */ _col(`=45+`inc'') %7.2f  `boot_z' /*
     */ _col(`=51+`inc'') %7.3f  `boot_p' /*
     */ _col(`=62+`inc'') `ofmt' `boot_lb' /*
     */ _col(`=75+`inc'') `ofmt' `boot_ub'

   * Return results
   // Additional information
   return scalar seed = `seed'           // Random seed (0 if not set)
   return scalar reps = `reps'           // Number of bootstrap replications
   return scalar level = `level'         // Confidence level
   if _by() return local group "`by_var'"     // By-group variable name
   if "`weight_type'" != "" {
      return local weight "`weight_exp'"        // Weight variable name
      return local weight_type "`weight_type'"  // Weight type (aw/fw)
   }
   return local var2 : word 2 of `varlist'  // Second variable name
   return local var1 : word 1 of `varlist'  // First variable name
   return scalar N = `N'                 // Sample size

   // Bootstrap returns
   return scalar boot_ub = `boot_ub'     // Bootstrap upper bound of CI
   return scalar boot_lb = `boot_lb'     // Bootstrap lower bound of CI
   return scalar boot_se = `boot_se'     // Bootstrap standard error

   // Original loevh2 returns
   return scalar ub = `orig_ub'          // Original upper bound of CI
   return scalar lb = `orig_lb'          // Original lower bound of CI
   return scalar se = `orig_se'          // Original standard error
   return scalar loevh = `orig_h'        // Original Loevinger's H

end
