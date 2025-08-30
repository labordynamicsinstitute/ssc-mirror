*! Version 3.0.1, Dirk Enzmann (28-Aug-2025)

program define loevh2_boot, rclass byable(recall)

   version 14.0
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Reps(integer 100) Level(real 95) Seed(integer 0) Table ///
           Abbreviate(integer 8) Progress]
   marksample touse, nov

   // Check that variables are binary (0/1) - simplified
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

   // Simplified weight and variable setup
   local weight_type "`weight'"
   local weight_exp "`exp'"
   local wgt ""
   if "`weight'" != "" & "`exp'" != "" local wgt "[`weight'=`exp']"
   local by_var "`_byvars'"

   // Set random seed if provided
   if `seed' != 0 set seed `seed'

   // Initial calculation with original data
   loevh2 `varlist' if `touse' `wgt', level(`level') `table' ab(`abbreviate')
   tempname orig_h orig_se orig_lb orig_ub N bootframe dataframe
   scalar `orig_h' = r(loevh)
   scalar `orig_se' = r(se)
   scalar `orig_lb' = r(lb)
   scalar `orig_ub' = r(ub)
   scalar `N' = r(N)

   // Create bootstrap results frame
   capture frame drop `bootframe'
   quietly {
      frame create `bootframe'
      frame `bootframe' {
         set obs `reps'
         gen h_boot = .
      }
   }

   // Unified bootstrap approach: expand data for all weight types
   local use_expansion = ("`weight_type'" == "fweight" | "`weight_type'" == "aweight")

   if `use_expansion' {
      // Create expanded data frame
      capture frame drop `dataframe'
      quietly {
         frame create `dataframe'
         preserve
         keep if `touse'
         if "`by_var'" != "" keep `varlist' `by_var' `weight_exp'
         else keep `varlist' `weight_exp'
         tempfile tempdata
         save `tempdata'
         restore

         frame `dataframe' {
            use `tempdata', clear
            expand `weight_exp'
         }
      }
   }

*   // Progress display - simplified
*   if "`progress'" != "" {
*      di _n "Bootstrap progress:"
*      di "0%{dup 50:.}100%"
*      di _c "  "
*   }
   * For complex progress indicator:
   if "`progress'" != "" {
      di _n "Bootstrap progress (percent of replications):"
      di "0%|{dup 49:{c -}}| 50%"
      display as text "  |" _c
      local dot_count = 0
      local comma_count = 0
   }

   // Bootstrap loop - unified
   
   forvalues i = 1/`reps' {
*      // Simple progress indicator
*      if "`progress'" != "" & mod(`i', max(1, `reps'/50)) == 0 {
*         di _c "."
*      }
      // Complex progress indicator
      if "`progress'" != "" {
         local pos = floor(100 * `i'/`reps')
         if `pos' <= 50 {
            local target = min(49, floor(98 * `i'/`reps'))
            if `target' > `dot_count' & mod(`i', max(1, floor(`reps'/100))) == 0 {
               local step = cond(`reps' < 100, ceil(100/`reps'), 1)
               forvalues s = 1/`step' {
                  if `dot_count' < 49 {
                     local ++dot_count
                     if mod(`dot_count', 5) == 0 {
                        if mod(`dot_count', 50) != 0 {
                           local ++comma_count
                           if mod(`comma_count', 2) == 0 display as text char(124) _c
                           else display as text char(44) _c
                        }
                     }
                     else display as text char(46) _c
                  }
               }
            }
            if `pos' >= 50 & `dot_count' == 49 {
               display as text "| 50%" _newline "  |" _c
               local dot_count = 0
               local comma_count = 0
            }
         }
         else {
            local target = min(49, floor(98 * (`i' - `reps'/2)/(`reps'/2)))
            if `target' > `dot_count' & mod(`i', max(1, floor(`reps'/100))) == 0 {
               local step = cond(`reps' < 100, ceil(100/`reps'), 1)
               forvalues s = 1/`step' {
                  if `dot_count' < 49 {
                     local ++dot_count
                     if mod(`dot_count', 5) == 0 {
                        if mod(`dot_count', 50) != 0 {
                           local ++comma_count
                           if mod(`comma_count', 2) == 0 display as text char(124) _c
                           else display as text char(44) _c
                        }
                     }
                     else display as text char(46) _c
                  }
               }
            }
            if `pos' == 100 & `dot_count' == 49 di "| 100%"
         }
      }

      if `use_expansion' {
         // Bootstrap on expanded data
         frame `dataframe' {
            preserve
            if "`by_var'" != "" qui bsample, strata(`by_var')
            else qui bsample
            quietly loevh2 `varlist'
            local h = r(loevh)
            restore
         }
      }
      else {
         // Standard bootstrap
         preserve
         quietly keep if `touse'
         if "`by_var'" != "" qui bsample, strata(`by_var')
         else qui bsample 
         quietly loevh2 `varlist'
         local h = r(loevh)
         restore
      }

      frame `bootframe': qui replace h_boot = `h' in `i'
   }

   if "`progress'" != "" di ""  // New line after progress
   if `use_expansion' frame drop `dataframe'

   // Calculate bootstrap statistics - simplified
   tempname boot_h boot_se boot_z boot_p boot_lb boot_ub boot_z0 boot_a
   quietly frame `bootframe' {
      sum h_boot
      scalar `boot_h' = r(mean)
      scalar `boot_se' = r(sd)
      scalar `boot_z' = `boot_h'/`boot_se'
      scalar `boot_p' = 2 * (1 - normal(abs(`boot_z')))

      // Simplified BCa confidence intervals
      count if h_boot < `orig_h'
      local n_less = r(N)
      scalar `boot_z0' = invnormal(`n_less'/`reps')

      // Simple acceleration estimate
      sum h_boot, detail
      scalar `boot_a' = r(skewness) / (6 * sqrt(`reps'))

      // BCa percentiles
      local alpha = (100 - `level')/100
      local z_alpha_2 = invnormal(`alpha'/2)
      local z_1_alpha_2 = invnormal(1 - `alpha'/2)

      local denom1 = 1 - `boot_a' * (`boot_z0' + `z_alpha_2')
      local denom2 = 1 - `boot_a' * (`boot_z0' + `z_1_alpha_2')

      if abs(`denom1') < 0.0001 | abs(`denom2') < 0.0001 {
         local p_lower = (`alpha'/2) * 100
         local p_upper = (1 - `alpha'/2) * 100
      }
      else {
         local p1 = normal(`boot_z0' + (`boot_z0' + `z_alpha_2') / `denom1')
         local p2 = normal(`boot_z0' + (`boot_z0' + `z_1_alpha_2') / `denom2')
         local p1 = max(0.001, min(0.999, `p1'))
         local p2 = max(0.001, min(0.999, `p2'))
         local p_lower = `p1' * 100
         local p_upper = `p2' * 100
      }

      _pctile h_boot, p(`p_lower' `p_upper')
      scalar `boot_lb' = r(r1)
      scalar `boot_ub' = r(r2)

      // Fallback to normal approximation if needed
      if missing(`boot_lb') | missing(`boot_ub') | `boot_lb' == `boot_ub' {
         local z_crit = invnormal(1 - `alpha'/2)
         scalar `boot_lb' = `boot_h' - `z_crit' * `boot_se'
         scalar `boot_ub' = `boot_h' + `z_crit' * `boot_se'
      }
   }
   frame drop `bootframe'

   // Display results - simplified using tokenize like loevh2
   local dig = ceil(log10(`reps')) + 2
   di _n as text "Bootstrap results (BCa method):"
   di as text "Number of bootstrap replications: " as result %`dig'.0fc `reps'
   if `seed' != 0 di as text "Random seed: " as result `seed'

   // Reuse variable formatting from loevh2 approach
   tokenize `varlist'
   local v1 = abbrev("`1'", `abbreviate')
   local v2 = abbrev("`2'", `abbreviate')
   local vars "`v1' `v2'"
   local colsv = max(length("`vars'"), 17) + 2
   local inc = `colsv' - 19
   local cil = string(`level')
   local spaces = cond(length("`cil'") == 2, "   ", " ")

   di _n in smcl in gr _col(`=23 + `inc'') "Loevinger" /*
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
     */ _col(`=25+`inc'') %7.0g `boot_h' /*
     */ _col(`=36+`inc'') %7.0g `boot_se' /*
     */ _col(`=45+`inc'') %7.2f `boot_z' /*
     */ _col(`=51+`inc'') %7.3f `boot_p' /*
     */ _col(`=62+`inc'') %7.0g `boot_lb' /*
     */ _col(`=75+`inc'') %7.0g `boot_ub'

   // Returns - simplified
   return scalar seed = `seed'
   return scalar reps = `reps'
   return scalar level = `level'
   if "`by_var'" != "" return local group "`by_var'"
   if "`weight_type'" != "" {
      return local weight "`weight_exp'"
      return local weight_type "`weight_type'"
   }
   return local var2 "`2'"
   return local var1 "`1'"
   return scalar N = `N'
   return scalar ub = `orig_ub'
   return scalar lb = `orig_lb'
   return scalar se = `orig_se'
   return scalar loevh = `orig_h'
   return scalar boot_a = `boot_a'
   return scalar boot_z0 = `boot_z0'
   return scalar boot_ub = `boot_ub'
   return scalar boot_lb = `boot_lb'
   return scalar boot_se = `boot_se'
   return scalar boot_h = `boot_h'
end
