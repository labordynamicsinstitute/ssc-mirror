*! Version 3.2, Dirk Enzmann (13-Jul-2026)
*!
*! Differences to version 3.1 (10-Aug-2025):
*!
*! Problems due to degenenerate 2x2 tables fixed and multiple by: variables fixed
*!
*! Differences to version 3.0.1 (28-Aug-2025):
*!
*! loevh2_boot reports H as calculated by loevh2 instead of the mean of the
*! bootstrap replicates.
*!
*! z and p of bootstrap results are no longer reported.

program define loevh2_boot, rclass byable(recall)

   version 14.0
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Reps(integer 100) Level(real 95) Seed(integer 0) Table ///
           Abbreviate(integer 8) Progress Maxtries(integer 50)]
   marksample touse, nov 

   // Tokenize the (already syntax-validated, comma-free) varlist here,
   // immediately, so that `1'/`2' are available and correctly set
   // (without any stray trailing comma that Stata's raw whitespace-only
   // positional-argument splitting could otherwise attach, e.g. when
   // the command is invoked as "... asltlyp, reps(50)" with no space
   // before the comma) for use in the by-group skip branches below, as
   // well as later in the program.
   tokenize `varlist'

   // Build a second sample marker, `tousegrp', that reflects only the
   // -in- restriction (if any), but NOT the user's -if- condition. This
   // is used solely to detect whether the CURRENT by-group's
   // by-variable value is missing, independent of any -if- condition
   // that might otherwise zero out `touse' for an entire missing-value
   // by-group and hide the fact that the group's by-value is missing.
   // This mirrors loevh2's own equivalent check exactly; it must be
   // done here (rather than relying on loevh2's internal check) because
   // loevh2 is called below as a plain subroutine (not by:-prefixed),
   // so its own by-awareness (_by(), `_byvars') does not fire in that
   // context.
   tempvar tousegrp
   mark `tousegrp' `in'
   markout `tousegrp'

   // If this is a by-group call and the by-variable(s) value for the
   // current group is missing (system missing "." or an extended
   // missing value ".a" - ".z"), or the user's -if-/-in- condition
   // leaves this by-group with zero observations (e.g. "bys male:
   // loevh2_boot item1 item2 if scountry=="Finland"" still generates a
   // by-group call for every category of male, including those with no
   // Finland respondents at all), skip this by-group entirely: do not
   // compute or attempt to bootstrap H, which is undefined for it.
   if _by() {
      local _byvars_miss = 0
      foreach _bv of local _byvars {
         qui count if `tousegrp' & missing(`_bv')
         if r(N) > 0 local _byvars_miss = 1
      }
      local _byvars_empty = 0
      if !`_byvars_miss' {
         qui count if `touse'
         if r(N) == 0 local _byvars_empty = 1
      }
      if `_byvars_miss' | `_byvars_empty' {
         di as text _n "Note: by-group with missing value of " ///
                       `"`_byvars'"' " (or no observations selected " ///
                       "by if/in) skipped (H is not estimated for " ///
                       "missing values of the by-variable)."

         // If this is the true last by-group in the whole by-sequence,
         // retrieve and forward the results of the last VALID by-group
         // actually processed (saved below, in the "boothist" frame,
         // right after that group's bootstrap results were computed),
         // so that r() is not silently left empty just because the
         // by-sequence happens to end on a missing/excluded group.
         if _bylastcall() {
            capture confirm frame boothist
            if _rc==0 {
               frame boothist {
                  local _last_n = _N
                  if `_last_n' > 0 {
                     local _lg_lab      = lastgroup[`_last_n']
                     local _lg_h        = loevh[`_last_n']
                     local _lg_se       = se[`_last_n']
                     local _lg_lb       = lb[`_last_n']
                     local _lg_ub       = ub[`_last_n']
                     local _lg_N        = n[`_last_n']
                     local _lg_boot_h   = boot_h[`_last_n']
                     local _lg_boot_se  = boot_se[`_last_n']
                     local _lg_boot_lb  = boot_lb[`_last_n']
                     local _lg_boot_ub  = boot_ub[`_last_n']
                     local _lg_boot_z0  = boot_z0[`_last_n']
                     local _lg_boot_a   = boot_a[`_last_n']
                     local _lg_reps     = reps[`_last_n']
                     local _lg_repsval  = reps_valid[`_last_n']
                     local _lg_repsfail = reps_failed[`_last_n']
                     local _lg_seed     = seed[`_last_n']
                     local _lg_maxtries = maxtries[`_last_n']
                     local _lg_level    = level[`_last_n']
                  }
               }
               frame drop boothist
               if `_last_n' > 0 {
                  if "`_byvars'" != "" return local group "`_byvars'"
                  return local var2 "`2'"
                  return local var1 "`1'"
                  return local lastgroup "`_lg_lab'"
                  return scalar seed        = `_lg_seed'
                  return scalar maxtries    = `_lg_maxtries'
                  return scalar reps_failed = `_lg_repsfail'
                  return scalar reps_valid  = `_lg_repsval'
                  return scalar reps        = `_lg_reps'
                  return scalar boot_a      = `_lg_boot_a'
                  return scalar boot_z0     = `_lg_boot_z0'
                  return scalar boot_ub     = `_lg_boot_ub'
                  return scalar boot_lb     = `_lg_boot_lb'
                  return scalar boot_se     = `_lg_boot_se'
                  return scalar boot_h      = `_lg_boot_h'
                  return scalar N           = `_lg_N'
                  return scalar level       = `_lg_level'
                  return scalar ub          = `_lg_ub'
                  return scalar lb          = `_lg_lb'
                  return scalar se          = `_lg_se'
                  return scalar loevh       = `_lg_h'
               }
            }
         }
         exit
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
   if "`r(error)'" == "degenerate" {
      // In a by-group context, a degenerate 2x2 table for just ONE
      // by-group (e.g. "bysort country male: loevh2_boot ..." where a
      // particular country/male combination happens to have a zero
      // cell or margin) is a legitimate, if unfortunate, data
      // characteristic of that specific subgroup -- it should not abort
      // the entire by-sequence. Skip this group gracefully (as is
      // already done above for missing by-values), forwarding the last
      // VALID group's results if this is the true last call of the
      // by-sequence. For a plain (non-by:) call, however, preserve the
      // original hard-stop behavior: a degenerate table means the
      // requested (single) analysis simply cannot be bootstrapped, so
      // it is best to alert the user with a hard error rather than
      // silently produce no output.
      if _by() {
         di as text _n "Note: by-group with a degenerate 2x2 table " ///
                       "(a zero cell or margin) skipped (H and its " ///
                       "bootstrap CI are undefined for this by-group)."

         if _bylastcall() {
            capture confirm frame boothist
            if _rc==0 {
               frame boothist {
                  local _last_n = _N
                  if `_last_n' > 0 {
                     local _lg_lab      = lastgroup[`_last_n']
                     local _lg_h        = loevh[`_last_n']
                     local _lg_se       = se[`_last_n']
                     local _lg_lb       = lb[`_last_n']
                     local _lg_ub       = ub[`_last_n']
                     local _lg_N        = n[`_last_n']
                     local _lg_boot_h   = boot_h[`_last_n']
                     local _lg_boot_se  = boot_se[`_last_n']
                     local _lg_boot_lb  = boot_lb[`_last_n']
                     local _lg_boot_ub  = boot_ub[`_last_n']
                     local _lg_boot_z0  = boot_z0[`_last_n']
                     local _lg_boot_a   = boot_a[`_last_n']
                     local _lg_reps     = reps[`_last_n']
                     local _lg_repsval  = reps_valid[`_last_n']
                     local _lg_repsfail = reps_failed[`_last_n']
                     local _lg_seed     = seed[`_last_n']
                     local _lg_maxtries = maxtries[`_last_n']
                     local _lg_level    = level[`_last_n']
                  }
               }
               frame drop boothist
               if `_last_n' > 0 {
                  if "`_byvars'" != "" return local group "`_byvars'"
                  return local var2 "`2'"
                  return local var1 "`1'"
                  return local lastgroup "`_lg_lab'"
                  return scalar seed        = `_lg_seed'
                  return scalar maxtries    = `_lg_maxtries'
                  return scalar reps_failed = `_lg_repsfail'
                  return scalar reps_valid  = `_lg_repsval'
                  return scalar reps        = `_lg_reps'
                  return scalar boot_a      = `_lg_boot_a'
                  return scalar boot_z0     = `_lg_boot_z0'
                  return scalar boot_ub     = `_lg_boot_ub'
                  return scalar boot_lb     = `_lg_boot_lb'
                  return scalar boot_se     = `_lg_boot_se'
                  return scalar boot_h      = `_lg_boot_h'
                  return scalar N           = `_lg_N'
                  return scalar level       = `_lg_level'
                  return scalar ub          = `_lg_ub'
                  return scalar lb          = `_lg_lb'
                  return scalar se          = `_lg_se'
                  return scalar loevh       = `_lg_h'
               }
            }
         }
         exit
      }
      di as error "Error: the original (non-bootstrapped) 2x2 table is " ///
                   "degenerate (a zero cell or margin); H is undefined " ///
                   "and bootstrapping cannot proceed."
      exit 459
   }

   // Capture the original (non-bootstrapped) H, SE, CI, and N returned
   // by the loevh2 call above IMMEDIATELY, before anything else touches
   // r() -- in particular, the binary-variable check below uses
   // -levelsof-, which sets its own r()-results and would otherwise
   // silently overwrite/clear r(loevh) etc. before they could be saved.
   tempname orig_h orig_se orig_lb orig_ub N bootframe dataframe
   scalar `orig_h' = r(loevh)
   scalar `orig_se' = r(se)
   scalar `orig_lb' = r(lb)
   scalar `orig_ub' = r(ub)
   scalar `N' = r(N)

   // Compute the current by-group's label (e.g. "male", "Lithuania"),
   // for use both when posting this group's results to the "boothist"
   // history frame below, and for the r(lastgroup) return.
   local sgroupslab ""
   if _by() {
      foreach _bv of local _byvars {
         qui summarize `_bv' if `touse', meanonly
         local _bv_val = r(min)
         local _bv_lab : label (`_bv') `_bv_val'
         local sgroupslab = trim("`sgroupslab' `_bv_lab'")
      }
   }

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

   // Bootstrap loop
   local n_failed = 0
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

      // Attempt to obtain a valid (non-degenerate) bootstrap replicate,
      // retrying with a fresh resample up to `maxtries' times if the
      // resample yields a degenerate 2x2 table (a zero cell or margin),
      // which would otherwise make H undefined (missing).
      local ok = 0
      local attempt = 0
      while !`ok' & `attempt' < `maxtries' {
         local ++attempt
         if `use_expansion' {
            // Bootstrap on expanded data
            frame `dataframe' {
               preserve
               if "`by_var'" != "" qui bsample, strata(`by_var')
               else qui bsample
               capture quietly loevh2 `varlist', _boot
               local rc = _rc
               if `rc' == 0 local h = r(loevh)
               restore
            }
         }
         else {
            // Standard bootstrap
            preserve
            quietly keep if `touse'
            if "`by_var'" != "" qui bsample, strata(`by_var')
            else qui bsample 
            capture quietly loevh2 `varlist', _boot
            local rc = _rc
            if `rc' == 0 local h = r(loevh)
            restore

         }
         if `rc' == 0 & !missing(`h') local ok = 1
      }

      if `ok' frame `bootframe': qui replace h_boot = `h' in `i'
      else local ++n_failed
   }

   if "`progress'" != "" di ""  // New line after progress
   if `use_expansion' frame drop `dataframe'
   if `n_failed' > 0 {
      di as error _n "Warning: `n_failed' of `reps' bootstrap replications " ///
                   "produced a degenerate 2x2 table (a zero cell or " ///
                   "margin) even after retrying up to `maxtries' times " ///
                   "per replication, and were excluded. Results are " ///
                   "based on " as result `=`reps'-`n_failed'' as error ///
                   " valid replications."
   }


   // Calculate bootstrap statistics
   tempname boot_h boot_se boot_z boot_p boot_lb boot_ub boot_z0 boot_a
   quietly frame `bootframe' {
      sum h_boot
      scalar `boot_h' = r(mean)
      scalar `boot_se' = r(sd)
      scalar `boot_z' = `boot_h'/`boot_se'
      scalar `boot_p' = 2 * (1 - normal(abs(`boot_z')))

      // Simplified BCa confidence intervals.
      // Use the actual number of valid (non-missing) replicates rather
      // than the nominal `reps' as the denominator, since some
      // replicates may have been excluded due to degenerate resamples
      // (see n_failed above).
      local n_valid = `reps' - `n_failed'
      count if h_boot < `orig_h'
      local n_less = r(N)
      scalar `boot_z0' = invnormal(`n_less'/`n_valid')

      // Simple acceleration estimate
      sum h_boot, detail
      scalar `boot_a' = r(skewness) / (6 * sqrt(`n_valid'))

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
   if `n_failed' > 0 di as text "Number of valid replications used: " ///
                        as result %`dig'.0fc `n_valid'
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
     */ _col(`=25+`inc'') %7.0g `orig_h' /*
     */ _col(`=36+`inc'') %7.0g `boot_se' /*
     */ _col(`=62+`inc'') %7.0g `boot_lb' /*
     */ _col(`=75+`inc'') %7.0g `boot_ub'

   // Save this valid by-group's full result set into a small persistent
   // "boothist" frame (created lazily on first use), so that if a later
   // by-group in the same by-sequence is skipped (missing by-value or
   // if/in-excluded) -- including possibly the very last group -- its
   // r() can still be populated with these last-valid-group results
   // (see the skip branch above). Mirrors loevh2's own "ressubsamp"
   // pattern. Only relevant when by: is in effect; for a plain
   // (non-by:) call there is only ever one group, so no history is
   // needed and none is kept.
   if _by() {
      if _byindex()==1 {
         capture frame drop boothist
      }
      capture confirm frame boothist
      if _rc {
         frame create boothist str32 lastgroup loevh se lb ub n ///
            boot_h boot_se boot_lb boot_ub boot_z0 boot_a ///
            reps reps_valid reps_failed seed maxtries level
      }
      frame boothist {
         qui set obs `=_N+1'
         local _hist_n = _N
         qui replace lastgroup  = "`sgroupslab'"    in `_hist_n'
         qui replace loevh      = `orig_h'          in `_hist_n'
         qui replace se         = `orig_se'         in `_hist_n'
         qui replace lb         = `orig_lb'         in `_hist_n'
         qui replace ub         = `orig_ub'         in `_hist_n'
         qui replace n          = `N'               in `_hist_n'
         qui replace boot_h     = `boot_h'          in `_hist_n'
         qui replace boot_se    = `boot_se'         in `_hist_n'
         qui replace boot_lb    = `boot_lb'         in `_hist_n'
         qui replace boot_ub    = `boot_ub'         in `_hist_n'
         qui replace boot_z0    = `boot_z0'         in `_hist_n'
         qui replace boot_a     = `boot_a'          in `_hist_n'
         qui replace reps       = `reps'            in `_hist_n'
         qui replace reps_valid = `n_valid'         in `_hist_n'
         qui replace reps_failed= `n_failed'        in `_hist_n'
         qui replace seed       = `seed'            in `_hist_n'
         qui replace maxtries   = `maxtries'        in `_hist_n'
         qui replace level      = `level'           in `_hist_n'
      }
      if _bylastcall() frame drop boothist
   }

   // Returns:
   if _by() return local lastgroup "`sgroupslab'"
   if "`_byvars'" != "" return local group "`_byvars'"
   if "`weight_type'" != "" {
      return local weight "`weight_exp'"
      return local weight_type "`weight_type'"
   }
   return local var2 "`2'"
   return local var1 "`1'"
   return scalar seed = `seed'
   return scalar maxtries = `maxtries'   
   return scalar reps_failed = `n_failed'
   return scalar reps_valid = `n_valid'
   return scalar reps = `reps'
   return scalar boot_a  = `boot_a'
   return scalar boot_z0 = `boot_z0'
   return scalar boot_ub = `boot_ub'
   return scalar boot_lb = `boot_lb'
   return scalar boot_se = `boot_se'
   return scalar boot_h  = `boot_h'
   return scalar N       = `N'
   return scalar level   = `level'
   return scalar ub      = `orig_ub'
   return scalar lb      = `orig_lb'
   return scalar se      = `orig_se'
   return scalar loevh   = `orig_h'
end
