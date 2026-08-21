*! Version 3.3, Dirk Enzmann (20-Aug-2026)
*!
*! Bootstraping for Loevinger's H
*!
*! Differences to Version 3.2 (13-Jul-2026):
*! - Added an "overlap" summary line.
*! - Added a new option, bccorrect.
*! - Added a brief "When to trust the results" section to loevh2_boot.sthlp.
*! - Removed the abbreviate(#) option, now always displays full (untruncated)
*!   variable names.
*! - The immediate command loevh2_booti allows compare.
*! - Added the meta(filename, replace|append) option
*!
*! Differences to version 3.1 (10-Aug-2025):
*! - Problems due to degenenerate 2x2 tables and multiple by: variables fixed
*!
*! Differences to version 3.0.1 (28-Aug-2025):
*! - loevh2_boot reports H as calculated by loevh2 instead of the mean of the
*!   bootstrap replicates.

program define loevh2_boot, rclass byable(recall)

   version 16.0

   local _origframe = c(frame)
   local _origchanged = c(changed)

   syntax varlist(min=2 max=2 numeric) [if] [fweight/] ///
          [, Reps(integer 1000) Level(real 95) Seed(integer 0) Table ///
           Progress MAXTries(integer 50) Compare meta(string asis) ///
           BCcorrect]


   // See: https://www.statalist.org/forums/forum/general-stata-discussion/general/152134
   capture which fre
   if ( _rc ) {
      capture window stopbox rusure "This program requires -fre-. Do you want to install -fre-?"
      if ( _rc ) exit 111
      ssc install fre
   }

   // Build the fweight-forwarding local `wgt' immediately after -syntax-
   // (rather than only later, just before the main loevh2 call), so it
   // is already in scope for the "Categories of by: variable(s)" -fre-
   // calls in the early by-group skip branches below (missing by-value/
   // if-in-excluded group, or a degenerate original 2x2 table for the
   // current by-group), not just the main body of the program. Without
   // this, any fweight'ed by:+compare call (e.g. as generated
   // internally by loevh2_booti's tabi-based group expansion, but
   // equally possible with genuine survey/aggregated fweight data)
   // showed each sub-sample's RAW physical observation count in that
   // table instead of its true (weighted) N -- mirroring the identical
   // fix applied to loevh2.ado (see its own changelog).
   local wgt ""
   if "`weight'" != "" & "`exp'" != "" local wgt "[`weight'=`exp']"

   if "`compare'"=="compare" & !_by() {
      di as error "option compare requires {help by}"
      exit 498
   }

   // meta() no longer requires -compare- (nor -by-): see loevh2.ado's
   // own changelog note for the full rationale (identical here).
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
      // Also proactively check whether `touse', though not entirely
      // zero, still leaves ZERO observations with non-missing analysis
      // variables (`1'/`2', already tokenized above) for this by-group
      // -- exactly mirroring loevh2.ado's own analogous fix (see its
      // changelog/comments for the full rationale). This prevents ever
      // reaching the binary-variable-check/loevh2-call logic below with
      // zero usable observations for this by-group.
      local _byvars_empty = 0
      if !`_byvars_miss' {
         qui count if `touse'
         if r(N) == 0 local _byvars_empty = 1
         else {
            qui count if `touse' & !missing(`1') & !missing(`2')
            if r(N) == 0 local _byvars_empty = 1
         }
      }
      if `_byvars_miss' | `_byvars_empty' {
         di as text _n "Note: by-group with missing value of " ///
                       `"`_byvars'"' " (or no observations selected " ///
                       "by if/in) skipped (H is not estimated for " ///
                       "missing values of the by-variable)."
         return local error "missing_byvar"

         // If this is the true last by-group in the whole by-sequence,
         // retrieve and forward the results of the last VALID by-group
         // actually processed (saved below, in the "boothist" frame,
         // right after that group's bootstrap results were computed),
         // so that r() is not silently left empty just because the
         // by-sequence happens to end on a missing/excluded group.
         //
         // NOTE: meta() is deliberately NOT triggered here, even though
         // the forwarded results originate from the last VALID group --
         // that group already triggered its own meta() save when IT
         // was processed, so saving again here would duplicate a row.
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
                     local _lg_boot_z   = boot_z[`_last_n']
                     local _lg_boot_p   = boot_p[`_last_n']
                     local _lg_boot_lb  = boot_lb[`_last_n']
                     local _lg_boot_ub  = boot_ub[`_last_n']
                     local _lg_boot_z0  = boot_z0[`_last_n']
                     local _lg_boot_a   = boot_a[`_last_n']
                     local _lg_boot_bc    = boot_bc[`_last_n']
                     local _lg_boot_bc_lb = boot_bc_lb[`_last_n']
                     local _lg_boot_bc_ub = boot_bc_ub[`_last_n']
                     local _lg_reps     = reps[`_last_n']
                     local _lg_repsval  = reps_valid[`_last_n']
                     local _lg_repsfail = reps_failed[`_last_n']
                     local _lg_seed     = seed[`_last_n']
                     local _lg_maxtries = maxtries[`_last_n']
                     local _lg_level    = level[`_last_n']
                     local _lg_ov       = overlap[`_last_n']
                     local _lg_ov_se    = se_overlap[`_last_n']
                     local _lg_ov_lb    = lb_overlap[`_last_n']
                     local _lg_ov_ub    = ub_overlap[`_last_n']
                  }
               }
               if "`compare'"=="compare" & `_last_n' > 0 {
                  di _n _n as txt "Categories of by: variable(s):"
                  fre `_byvars' `if' `wgt'
                  capture confirm frame bootreps
                  if _rc==0 loevh2_boot_compare
                  if `"`meta'"' != `""' & "`loevh2_boot_HSEN'"!="" {
                     local HSENLAB = `"`loevh2_boot_HSEN_labels'"'
                     loevh2_meta_save, metaspec(`meta') ///
                        source(loevh2_boot) suffix("_boot") ///
                        setype("large sample, bootstrap") ///
                        hsen(`loevh2_boot_HSEN') labels(`"`HSENLAB'"') ///
                        origframe(`"`_origframe'"') origchanged(`_origchanged')
                  }
               }
               frame drop boothist
               capture frame drop bootreps
               if `_last_n' > 0 {
                  return scalar seed        = `_lg_seed'
                  return scalar maxtries    = `_lg_maxtries'
                  return scalar reps_failed = `_lg_repsfail'
                  return scalar reps_valid  = `_lg_repsval'
                  return scalar reps        = `_lg_reps'
                  return scalar boot_bc_ub  = `_lg_boot_bc_ub'
                  return scalar boot_bc_lb  = `_lg_boot_bc_lb'
                  return scalar boot_bc     = `_lg_boot_bc'
                  return scalar boot_a      = `_lg_boot_a'
                  return scalar boot_z0     = `_lg_boot_z0'
                  if "`compare'"=="compare" {
                     return scalar Hbar_N   = `loevh2_boot_Hbar_N'
                     return scalar p_boot   = `loevh2_boot_p'
                     return scalar df       = `loevh2_boot_df'
                     return scalar chi2     = `loevh2_boot_chi2'
                     return scalar Hbar_se  = `loevh2_boot_Hbar_se'
                     return scalar Hbar     = `loevh2_boot_Hbar'
                  }
                  return scalar boot_ub     = `_lg_boot_ub'
                  return scalar boot_lb     = `_lg_boot_lb'
                  return scalar boot_p      = `_lg_boot_p'
                  return scalar boot_z      = `_lg_boot_z'
                  return scalar boot_se     = `_lg_boot_se'
                  return scalar boot_h      = `_lg_boot_h'
                  return scalar ub_overlap  = `_lg_ov_ub'
                  return scalar lb_overlap  = `_lg_ov_lb'
                  return scalar se_overlap  = `_lg_ov_se'
                  return scalar overlap     = `_lg_ov'
                  return scalar N           = `_lg_N'
                  return scalar level       = `_lg_level'
                  return scalar ub          = `_lg_ub'
                  return scalar lb          = `_lg_lb'
                  return scalar se          = `_lg_se'
                  return scalar loevh       = `_lg_h'
                  if "`compare'"=="compare" & "`loevh2_boot_HSEN'" != "" {
                     return matrix H_SE_N = `loevh2_boot_HSEN'
                  }
                  return local lastgroup "`_lg_lab'"
                  if "`_byvars'" != "" return local group "`_byvars'"
                  return local se_type "large sample, bootstrap"
                  return local var2 "`2'"
                  return local var1 "`1'"
               }
            }
         }
         exit
      }
   }

   // Simplified weight and variable setup. Only fweight is supported

   // (see changelog above: pweight support has been removed -- use
   // loevh2_svy for design-based/pweight inference).
   local weight_type "`weight'"
   local weight_exp "`exp'"
   local wgt ""
   if "`weight'" != "" & "`exp'" != "" local wgt "[`weight'=`exp']"
   local by_var "`_byvars'"

   // Set random seed if provided
   if `seed' != 0 set seed `seed'

   // Initial calculation with original data.
   loevh2 `varlist' if `touse' `wgt', level(`level') `table' _boot
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
         return local error "degenerate"

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
                     local _lg_boot_z   = boot_z[`_last_n']
                     local _lg_boot_p   = boot_p[`_last_n']
                     local _lg_boot_lb  = boot_lb[`_last_n']
                     local _lg_boot_ub  = boot_ub[`_last_n']
                     local _lg_boot_z0  = boot_z0[`_last_n']
                     local _lg_boot_a   = boot_a[`_last_n']
                     local _lg_boot_bc    = boot_bc[`_last_n']
                     local _lg_boot_bc_lb = boot_bc_lb[`_last_n']
                     local _lg_boot_bc_ub = boot_bc_ub[`_last_n']
                     local _lg_reps     = reps[`_last_n']
                     local _lg_repsval  = reps_valid[`_last_n']
                     local _lg_repsfail = reps_failed[`_last_n']
                     local _lg_seed     = seed[`_last_n']
                     local _lg_maxtries = maxtries[`_last_n']
                     local _lg_level    = level[`_last_n']
                     local _lg_ov       = overlap[`_last_n']
                     local _lg_ov_se    = se_overlap[`_last_n']
                     local _lg_ov_lb    = lb_overlap[`_last_n']
                     local _lg_ov_ub    = ub_overlap[`_last_n']
                  }
               }
               if "`compare'"=="compare" & `_last_n' > 0 {
                  di _n _n as txt "Categories of by: variable(s):"
                  fre `_byvars' `if' `wgt'
                  capture confirm frame bootreps
                  if _rc==0 loevh2_boot_compare
                  if `"`meta'"' != `""' & "`loevh2_boot_HSEN'"!="" {
                     local HSENLAB = `"`loevh2_boot_HSEN_labels'"'
                     loevh2_meta_save, metaspec(`meta') ///
                        source(loevh2_boot) suffix("_boot") ///
                        setype("large sample, bootstrap") ///
                        hsen(`loevh2_boot_HSEN') labels(`"`HSENLAB'"') ///
                        origframe(`"`_origframe'"') origchanged(`_origchanged')
                  }
               }
               frame drop boothist
               capture frame drop bootreps
               if `_last_n' > 0 {
                  return scalar seed        = `_lg_seed'
                  return scalar maxtries    = `_lg_maxtries'
                  return scalar reps_failed = `_lg_repsfail'
                  return scalar reps_valid  = `_lg_repsval'
                  return scalar reps        = `_lg_reps'
                  return scalar boot_bc_ub  = `_lg_boot_bc_ub'
                  return scalar boot_bc_lb  = `_lg_boot_bc_lb'
                  return scalar boot_bc     = `_lg_boot_bc'
                  return scalar boot_a      = `_lg_boot_a'
                  return scalar boot_z0     = `_lg_boot_z0'
                  return scalar boot_ub     = `_lg_boot_ub'
                  return scalar boot_lb     = `_lg_boot_lb'
                  return scalar boot_p      = `_lg_boot_p'
                  return scalar boot_z      = `_lg_boot_z'
                  return scalar boot_se     = `_lg_boot_se'
                  return scalar boot_h      = `_lg_boot_h'
                  return scalar ub_overlap  = `_lg_ov_ub'
                  return scalar lb_overlap  = `_lg_ov_lb'
                  return scalar se_overlap  = `_lg_ov_se'
                  return scalar overlap     = `_lg_ov'
                  return scalar N           = `_lg_N'
                  return scalar level       = `_lg_level'
                  return scalar ub          = `_lg_ub'
                  return scalar lb          = `_lg_lb'
                  return scalar se          = `_lg_se'
                  return scalar loevh       = `_lg_h'
                  if "`_byvars'" != "" return local group "`_byvars'"
                  return local lastgroup "`_lg_lab'"
                  return local var2 "`2'"
                  return local var1 "`1'"
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

   // Capture the original (non-bootstrapped) H, SE, CI, N, and overlap
   // summary returned by the loevh2 call above IMMEDIATELY, before
   // anything else touches r() -- in particular, the binary-variable
   // check below uses -levelsof-, which sets its own r()-results and
   // would otherwise silently overwrite/clear r(loevh) etc. before they
   // could be saved.
   tempname orig_h orig_se orig_lb orig_ub N bootframe dataframe
   tempname ov ov_se ov_lb ov_ub
   scalar `orig_h' = r(loevh)
   scalar `orig_se' = r(se)
   scalar `orig_lb' = r(lb)
   scalar `orig_ub' = r(ub)
   scalar `N' = r(N)
   scalar `ov' = r(overlap)
   scalar `ov_se' = r(se_overlap)
   scalar `ov_lb' = r(lb_overlap)
   scalar `ov_ub' = r(ub_overlap)

   // Compute the current by-group's label (e.g. "male", "Lithuania"),
   // for use both when posting this group's results to the "boothist"
   // history frame below, and for the r(lastgroup) return.
   //
   // Each by-variable can be either numeric (in which case its value
   // label, if any, is looked up via "summarize" + ": label") or a
   // string (in which case -summarize- does not apply -- it silently
   // produces no r(min), leaving the label empty, which caused blank
   // sub-sample labels whenever the by-variable was a string). For a
   // string by-variable, its own text value (for this by-group) is
   // used directly as the label.
   local sgroupslab ""
   if _by() {
      foreach _bv of local _byvars {
         capture confirm string variable `_bv'
         if !_rc {

            // See loevh2.ado's own equivalent block for the full
            // rationale: -levelsof-'s "clean" option, combined with
            // ": word 1 of", incorrectly splits a multi-word string
            // value (e.g. "West Germany") into separate "words" on
            // whitespace, returning only the first of them. Fixed by
            // omitting "clean" (each distinct value then arrives
            // wrapped in its own double quotes, which "word 1 of"
            // treats as one atomic token regardless of embedded
            // spaces) and stripping the surrounding quotes manually.
            qui levelsof `_bv' if `touse', local(_bv_lvls)
            local _bv_lab : word 1 of `_bv_lvls'
            local _bv_lab = subinstr(`"`_bv_lab'"', `"""', "", .)
         }

         else {
            qui summarize `_bv' if `touse', meanonly
            local _bv_val = r(min)
            local _bv_lab : label (`_bv') `_bv_val'
         }
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

   // Bootstrap mechanics: build a single, unified data frame
   // (`dataframe') ONCE, before the reps loop, containing only the
   // touse-filtered rows (and, if relevant, the by-group variable(s)),
   // then always resample from THAT frame inside the loop via bsample.
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
         if "`weight_type'" == "fweight" expand `weight_exp'
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
         // Bootstrap on the pre-filtered (and, if the user supplied an
         // fweight, pre-expanded) `dataframe' -- built once, before
         // this loop, and reused for every replicate (see the note
         // above where `dataframe' is created for the full rationale).
         frame `dataframe' {
            preserve
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
   frame drop `dataframe'

   if `n_failed' > 0 {
      di as error _n "Warning: `n_failed' of `reps' bootstrap replications " ///
                   "produced a degenerate 2x2 table (a zero cell or " ///
                   "margin) even after retrying up to `maxtries' times " ///
                   "per replication, and were excluded. Results are " ///
                   "based on " as result %`dig'.0fc `=`reps'-`n_failed'' as error ///
                   " valid replications."
   }


   // Calculate bootstrap statistics
   tempname boot_h boot_se boot_z boot_p boot_lb boot_ub boot_z0 boot_a
   quietly frame `bootframe' {
      sum h_boot
      scalar `boot_h' = r(mean)
      scalar `boot_se' = r(sd)
      scalar `boot_z' = `orig_h'/`boot_se'
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

   // Bootstrap bias-corrected point estimate and shift-recentered CI
   // (Options B and C of loevh2_boot_enhancement_proposal.md). Always
   // computed and returned regardless of whether -bccorrect- was
   // specified (essentially free: a subtraction and two additions using
   // numbers already computed above); only the ON-SCREEN display of
   // these quantities is gated behind -bccorrect- (see display block
   // below). boot_bc = 2*orig_h - boot_h (Efron & Tibshirani, 1993, ch.
   // 10); the BCa CI is then shifted by the same amount
   // (shift = boot_bc - orig_h) so that the corrected CI is centered on
   // the corrected point estimate, exactly the "shift" method validated
   // in Task_11's sim_loevh2_bootbias_corrected.do.
   tempname boot_bc boot_bc_shift boot_bc_lb boot_bc_ub
   scalar `boot_bc'       = 2*`orig_h' - `boot_h'
   scalar `boot_bc_shift' = `boot_bc' - `orig_h'
   scalar `boot_bc_lb'    = `boot_lb' + `boot_bc_shift'
   scalar `boot_bc_ub'    = `boot_ub' + `boot_bc_shift'

   // Before dropping `bootframe', if -compare- is in effect, append this
   // by-group's h_boot replicate vector (long format: sample, h_boot) to
   // a persistent "bootreps" frame, so that at _bylastcall() the full
   // replicate matrix across all valid by-groups is available for the
   // bootstrap-based omnibus test. Only non-missing replicates are
   // appended (missing h_boot values, from failed/degenerate resamples,
   // are excluded; the "R common replicates per group" logic in
   // loevh2_boot_compare handles any resulting imbalance across groups).
   if "`compare'"=="compare" {
      if _byindex()==1 {
         capture frame drop bootreps
      }
      capture confirm frame bootreps
      if _rc {
         frame create bootreps double(sample h_boot)
      }
      local _sample = _byindex()
      frame bootreps: lab def sample `_sample' "`sgroupslab'", modify

      tempname _M_boot
      quietly frame `bootframe' {
         mkmat h_boot, matrix(`_M_boot') nomissing
      }
      local _nadd = rowsof(`_M_boot')
      if `_nadd' > 0 {
         quietly frame bootreps {
            local _n0 = _N
            qui set obs `=`_n0'+`_nadd''
            forvalues _r = 1/`_nadd' {
               qui replace sample = `_sample'               in `=`_n0'+`_r''
               qui replace h_boot = `_M_boot'[`_r',1]       in `=`_n0'+`_r''
            }
         }
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

   // Reuse variable formatting from loevh2 approach -- full variable
   // names (no abbreviation), same approach as loevh2_svy: `1'/`2' are
   // simply aliased directly, with no truncation.
   tokenize `varlist'
   local v1 "`1'"
   local v2 "`2'"
   local vars "`v1' `v2'"
   local colsv = max(length("`vars'"), 17) + 2
   local inc = `colsv' - 19
   local cil = string(`level')
   local spaces = cond(length("`cil'") == 2, "   ", " ")

   // NOTE: no separate Overlap display here. When -table- is
   // specified, the cross-tabulation AND its Overlap summary are
   // already shown exactly once, by the initial loevh2 ..., table call
   // above (loevh2's own display, which this program forwards -table-
   // to). Repeating the (identical, non-bootstrapped) overlap figures
   // again here -- right before the bootstrap results table -- would
   // be pure duplication, since bootstrapping does not re-estimate
   // overlap at all (only H itself is bootstrapped). r(overlap) etc.
   // remain available via r() either way, regardless of -table-.

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

     */ _col(`=45+`inc'') %7.2f `boot_z' /*
     */ _col(`=51+`inc'') %7.3f `boot_p' /*
     */ _col(`=62+`inc'') %7.0g `boot_lb' /*
     */ _col(`=75+`inc'') %7.0g `boot_ub'

   // With -bccorrect-, display one extra, clearly-labeled supplementary
   // line showing the bootstrap bias-corrected point estimate and its
   // shift-recentered CI (see computation above). Only shown when the
   // option is actually specified; the default bootstrap output above
   // is completely unchanged either way. r(boot_bc)/r(boot_bc_lb)/
   // r(boot_bc_ub) are always returned regardless of this option (see
   // Returns section below).
   if "`bccorrect'"=="bccorrect" {
      di as txt _n "   Bias-corrected (BCa-shift, supplementary -- see " ///
                "help for caveats):"
      di as txt "      H = " as res %7.4f `boot_bc' ///
         as txt "   SE = " as res %7.4f `boot_se' ///
         as txt "   [`level'% conf. interval: " ///
         as res %7.4f `boot_bc_lb' as txt "," as res %7.4f `boot_bc_ub' ///
         as txt "]"
   }

   // meta() single-row save: fires whenever meta() is specified and we
   // are NOT in the by:+compare pooling branch below (which, when it
   // fires on the last by-group, already saves ALL rows -- including
   // this group's -- via the HSEN matrix). See loevh2.ado's own
   // equivalent block for the full rationale (identical logic here):
   //   (a) a plain, non-by: call            -> label = "var1_var2"
   //   (b) by: without compare               -> label = sgroupslab,
   //       one row saved per by-group as each is processed
   //   (c) by: + compare, for every by-group EXCEPT the last one.
   // The bootstrap SE (boot_se) is used, not orig_se -- consistent with
   // loevh2_boot_compare's own r(H_SE_N) convention (see its header
   // comment for the rationale).
   if `"`meta'"' != `""' & "`compare'"!="compare" {
      local _metalab = cond(_by(), "`sgroupslab'", "`v1'_`v2'")
      loevh2_meta_save, metaspec(`meta') source(loevh2_boot) ///
         suffix("_boot") setype("large sample, bootstrap") ///
         label(`"`_metalab'"') hval(`=`orig_h'') seval(`=`boot_se'') nval(`=`N'') ///
         origframe(`"`_origframe'"') origchanged(`_origchanged')
   }

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
         frame create boothist double(sample) str32 lastgroup loevh se lb ub n ///
            boot_h boot_se boot_z boot_p boot_lb boot_ub boot_z0 boot_a ///
            boot_bc boot_bc_lb boot_bc_ub ///
            reps reps_valid reps_failed seed maxtries level ///
            overlap se_overlap lb_overlap ub_overlap
      }
      frame boothist {
         qui set obs `=_N+1'
         local _hist_n = _N
         qui replace sample     = `=_byindex()'     in `_hist_n'
         qui replace lastgroup  = "`sgroupslab'"    in `_hist_n'
         qui replace loevh      = `orig_h'          in `_hist_n'
         qui replace se         = `orig_se'         in `_hist_n'
         qui replace lb         = `orig_lb'         in `_hist_n'
         qui replace ub         = `orig_ub'         in `_hist_n'
         qui replace n          = `N'               in `_hist_n'
         qui replace boot_h     = `boot_h'          in `_hist_n'
         qui replace boot_se    = `boot_se'         in `_hist_n'
         qui replace boot_z     = `boot_z'          in `_hist_n'
         qui replace boot_p     = `boot_p'          in `_hist_n'
         qui replace boot_lb    = `boot_lb'         in `_hist_n'
         qui replace boot_ub    = `boot_ub'         in `_hist_n'
         qui replace boot_z0    = `boot_z0'         in `_hist_n'
         qui replace boot_a     = `boot_a'          in `_hist_n'
         qui replace boot_bc    = `boot_bc'         in `_hist_n'
         qui replace boot_bc_lb = `boot_bc_lb'      in `_hist_n'
         qui replace boot_bc_ub = `boot_bc_ub'      in `_hist_n'
         qui replace reps       = `reps'            in `_hist_n'
         qui replace reps_valid = `n_valid'         in `_hist_n'
         qui replace reps_failed= `n_failed'        in `_hist_n'
         qui replace seed       = `seed'            in `_hist_n'
         qui replace maxtries   = `maxtries'        in `_hist_n'
         qui replace level      = `level'           in `_hist_n'
         qui replace overlap    = `ov'              in `_hist_n'
         qui replace se_overlap = `ov_se'           in `_hist_n'
         qui replace lb_overlap = `ov_lb'           in `_hist_n'
         qui replace ub_overlap = `ov_ub'           in `_hist_n'
      }

      // If this is the true last by-group of the by-sequence, display
      // the "Categories of by: variable(s)" frequency table when
      // -compare- is requested, and, if so, compute and
      // display the bootstrap-based omnibus test of equality of H's
      // across all valid sub-samples, using the full replicate matrix
      // accumulated in "bootreps" together with each group's (orig_h,
      // orig_se, N) from "boothist". If meta() is also specified, the
      // resulting H_SE_N matrix (bootstrap SEs) is saved as the pooled
      // multi-row case (see loevh2.ado's changelog for the general
      // rationale).
      if _bylastcall() & "`compare'"=="compare" {
         di _n _n as txt "Categories of by: variable(s):"
         fre `_byvars' `if' `wgt'
         loevh2_boot_compare
         if `"`meta'"' != `""' & "`loevh2_boot_HSEN'"!="" {
            local HSENLAB = `"`loevh2_boot_HSEN_labels'"'
            loevh2_meta_save, metaspec(`meta') source(loevh2_boot) ///
               suffix("_boot") setype("large sample, bootstrap") ///
               hsen(`loevh2_boot_HSEN') labels(`"`HSENLAB'"') ///
               origframe(`"`_origframe'"') origchanged(`_origchanged')
         }
      }

      if _bylastcall() frame drop boothist
      if _bylastcall() {
         capture frame drop bootreps
      }
   }

   // Returns:
   return scalar seed = `seed'
   return scalar maxtries = `maxtries'
   return scalar reps_failed = `n_failed'
   return scalar reps_valid = `n_valid'
   return scalar reps = `reps'
   return scalar boot_bc_ub  = `boot_bc_ub'
   return scalar boot_bc_lb  = `boot_bc_lb'
   return scalar boot_bc     = `boot_bc'
   return scalar boot_a  = `boot_a'
   return scalar boot_z0 = `boot_z0'
   if "`compare'"=="compare" & _by() & _bylastcall() {
      return scalar Hbar_N  = `loevh2_boot_Hbar_N'
      return scalar p_boot  = `loevh2_boot_p'
      return scalar df      = `loevh2_boot_df'
      return scalar chi2    = `loevh2_boot_chi2'
      return scalar Hbar_se = `loevh2_boot_Hbar_se'
      return scalar Hbar    = `loevh2_boot_Hbar'
   }
   return scalar boot_ub = `boot_ub'
   return scalar boot_lb = `boot_lb'
   return scalar boot_p  = `boot_p'
   return scalar boot_z  = `boot_z'
   return scalar boot_se = `boot_se'
   return scalar boot_h  = `boot_h'
   return scalar ub_overlap = `ov_ub'
   return scalar lb_overlap = `ov_lb'
   return scalar se_overlap = `ov_se'
   return scalar overlap    = `ov'
   return scalar N       = `N'
   return scalar level   = `level'
   return scalar ub      = `orig_ub'
   return scalar lb      = `orig_lb'
   return scalar se      = `orig_se'
   return scalar loevh   = `orig_h'
   if "`compare'"=="compare" & _by() & _bylastcall() & "`loevh2_boot_HSEN'" != "" {
      return matrix H_SE_N = `loevh2_boot_HSEN'
   }
   if _by() return local lastgroup "`sgroupslab'"
   if "`_byvars'" != "" return local group "`_byvars'"
   if "`weight_type'" != "" {
      return local weight "`weight_exp'"
      return local weight_type "`weight_type'"
   }
   return local se_type "large sample, bootstrap"
   return local var2 "`2'"
   return local var1 "`1'"
end

* ------------------------------------------------------------------------------
program define loevh2_boot_compare

// loevh2_boot_compare: bootstrap-based omnibus test of equality of H's
// across k (>=2) by-group sub-samples, computed from the "boothist"
// frame (orig_h, orig_se, n per group) and the "bootreps" frame (long-
// format bootstrap replicates: sample, h_boot, per group).
//
// The observed test statistic Q_obs is exactly loevh2_compare's own
// Eq.-16 weighted chi-square statistic, computed once from each group's
// (orig_h, orig_se). For each paired replicate index b = 1,...,R (R =
// the smallest number of valid replicates across all groups; excess
// replicates from groups with more are discarded), the SAME statistic
// Q^(b) is recomputed using each group's H_i^(b) in place of orig_h_i,
// holding the weights 1/orig_se_i^2 fixed across replicates (only H_i^(b)
// varies by replicate). The bootstrap p-value is the proportion of
// Q^(b) at least as large as Q_obs -- an empirical, non-chi2-asymptotic
// significance test for the omnibus null that all sub-samples' H's are
// equal, in keeping with why loevh2_boot bootstraps at all.

   version 16.0
   tempvar ok
   quietly frame boothist: gen byte `ok' = !missing(loevh) & !missing(se)
   quietly frame boothist: count if `ok'
   local k = r(N)

   if `k' < 2 {
      di as error "Note: fewer than 2 valid sub-samples; " ///
                   "cannot test equality of H's"
      c_local loevh2_boot_p    = .
      c_local loevh2_boot_chi2 = .
      c_local loevh2_boot_df   = .
      c_local loevh2_boot_Hbar = .
      c_local loevh2_boot_Hbar_se = .
      c_local loevh2_boot_Hbar_N  = .
      c_local loevh2_boot_HSEN = ""
      c_local loevh2_boot_HSEN_labels = ""
      exit
   }

   // ---- Observed statistic Q_obs and Hbar, computed directly here
   // (same weighted chi-square formula as loevh2.ado's loevh2_compare,
   // Copas & Loeber, 1990, Eq. 16), rather than calling loevh2_compare
   // itself: loevh2_compare is a secondary ("non-file-matching") program
   // defined inside loevh2.ado, which Stata's ado autoloader cannot
   // reliably locate/load on its own when called from a different .ado
   // file's program (only the file-matching program "loevh2" is
   // autoloadable from loevh2.ado). Inlining this small, self-contained
   // computation keeps loevh2_boot.ado fully independent of loevh2.ado's
   // internals.
   tempname wsum wrsum wr2sum
   frame boothist: mata: loevh2_boot_hs = st_data(., ("loevh", "se"), "`ok'")
   mata: st_numscalar("`wsum'",   sum(1 :/ loevh2_boot_hs[.,2]:^2))
   mata: st_numscalar("`wrsum'",  sum(loevh2_boot_hs[.,1] :/ loevh2_boot_hs[.,2]:^2))
   mata: st_numscalar("`wr2sum'", sum(loevh2_boot_hs[.,1]:^2 :/ loevh2_boot_hs[.,2]:^2))
   // NOTE: loevh2_boot_hs (columns: orig_h, orig_se) is deliberately NOT
   // dropped here -- its first column (each group's original H_i) is
   // reused below to null-recenter the paired bootstrap replicates
   // (see the "recenter" note further down).
   local Hbar  = scalar(`wrsum') / scalar(`wsum')
   local Q_obs = scalar(`wr2sum') - scalar(`wrsum')^2 / scalar(`wsum')
   local df    = `k' - 1

   // ---- Per-group orig_se (weights, held fixed across replicates),
   // orig_h (each group's OWN original H, needed below to null-recenter
   // the paired bootstrap replicates), and the by-group ("sample")
   // index each row of "boothist" corresponds to -- all loaded into
   // Mata for the paired-replicate computation below. Mata calls are
   // prefixed with "frame boothist:" so that st_data() reads from the
   // "boothist" frame regardless of which frame happens to be current
   // when loevh2_boot_compare is invoked.
   frame boothist: mata: loevh2_boot_se   = st_data(., "se", "`ok'")
   frame boothist: mata: loevh2_boot_origh = st_data(., "loevh", "`ok'")
   frame boothist: mata: loevh2_boot_grp  = st_data(., "sample", "`ok'")

   // ---- Determine common number of paired replicates R across groups
   // (smallest valid-replicate count among the k groups; excess
   // replicates from groups with more are discarded, per design note).
   // Moved up (before any display) so that the header below can show
   // the correct R.
   tempname Rcommon
   scalar `Rcommon' = .
   tempname grpval_s
   forvalues _g = 1/`k' {
      mata: st_numscalar("`grpval_s'", loevh2_boot_grp[`_g'])
      local _grpval = scalar(`grpval_s')
      quietly frame bootreps: count if sample==`_grpval' & !missing(h_boot)
      local _Rg = r(N)
      if `_g'==1 scalar `Rcommon' = `_Rg'
      else if `_Rg' < scalar(`Rcommon') scalar `Rcommon' = `_Rg'
   }
   local R = scalar(`Rcommon')

   // ---- Build the r(H_SE_N) matrix (one row per valid sub-sample;
   // columns H, SE, N; row names = sub-sample labels), from the same
   // "boothist" rows selected by `ok'. Unlike loevh2.ado's own
   // loevh2_compare/r(H_SE_N) -- which necessarily uses the analytic
   // large-sample SE (Copas & Loeber Eq. 11), since loevh2 has no other
   // SE available -- here the SE column uses the BOOTSTRAP SE
   // (boot_se), not orig_se. This is a deliberate choice: boot_se
   // properly reflects H's actual (possibly skewed/non-normal) sampling
   // variability via resampling, which is particularly relevant
   // whenever a sub-sample is small or H is close to +-1 (exactly the
   // situations Eq. 11's normal-approximation SE is least reliable
   // for). Because boot_se is a simulation-based estimate, it carries
   // some Monte Carlo noise at low reps(); a higher reps() (>= 1,000)
   // is recommended whenever H_SE_N will be used as subsequent
   // meta-analysis input (see loevh2_boot.sthlp).
   //
   // Also computes the pooled bootstrap SE of Hbar,
   // SE(Hbar) = sqrt(1/sum(1/boot_se_i^2)), and the total N across all
   // valid sub-samples, both now shown as the table's own bottom row
   // ("Weighted average H"), matching loevh2's own compare layout.
   // A fixed (non-tempname) matrix name is used for the same reason as
   // in loevh2.ado's loevh2_compare: it must survive being handed back
   // to the caller via c_local across the "frame boothist:"/"frame
   // change" boundary.
   capture matrix drop __loevh2_boot_HSEN
   matrix __loevh2_boot_HSEN = J(`k', 3, .)
   local HSEN "__loevh2_boot_HSEN"
   matrix colnames `HSEN' = H SE N
   local HSEN_rownames ""
   local HSEN_labels_full ""
   tempname bwsum bnsum
   scalar `bwsum' = 0
   scalar `bnsum' = 0

   // On-screen per-sub-sample table (Sub-sample, H Coeff, Std. err., N),
   // displayed with a header ABOVE it and the weighted-average summary
   // as its own bottom row (closed with a bottom border), matching
   // loevh2.ado's own loevh2_compare table layout exactly (adaptive
   // label-column width, same column headers/spacing).
   local hlwidth = 30
   local maxlablen = length("Weighted average H")
   frame boothist {
      local _N_hist = _N
      forvalues _obs = 1/`_N_hist' {
         if missing(loevh[`_obs']) | missing(se[`_obs']) continue
         local _slab = lastgroup[`_obs']
         if length("`_slab'") > `maxlablen' local maxlablen = length("`_slab'")
      }
   }
   local labcol = `maxlablen' + 3

   // ---- Display header (BEFORE the sub-sample table, matching
   // loevh2.ado's own loevh2_compare layout: header first, then table
   // with the weighted-average row as its own bottom row, then the
   // chi2/Pr line below the table).
   di _n as txt "Bootstrap test of equality of H's across " as res `k' ///
      as txt " sub-samples" ///
      as txt _n "(based on " as res `R' as txt " paired, null-recentered replications):"

   di _n in gr ///
      _col(2) "Sub-sample" ///
      _col(`labcol') "{c |}" ///
      _col(`=`labcol'+3') "H Coeff" ///
      _col(`=`labcol'+13') "Std. err." ///
      _col(`=`labcol'+32') "N"

   di in gr "{hline `=`labcol'-1'}{c +}{hline `=`hlwidth'+2'}"

   frame boothist {
      local _row = 0
      local _N_hist = _N
      forvalues _obs = 1/`_N_hist' {
         if missing(loevh[`_obs']) | missing(se[`_obs']) continue
         local ++_row
         local _hval  = loevh[`_obs']
         local _bseval = boot_se[`_obs']
         local _nval  = n[`_obs']
         local _slab  = lastgroup[`_obs']
         matrix `HSEN'[`_row',1] = `_hval'
         matrix `HSEN'[`_row',2] = `_bseval'
         matrix `HSEN'[`_row',3] = `_nval'
         if !missing(`_bseval') & `_bseval' > 0 {
            scalar `bwsum' = `bwsum' + 1/`_bseval'^2
         }
         scalar `bnsum' = `bnsum' + `_nval'
         // Row names are simple, guaranteed-short, collision-free
         // "group N" identifiers (N = this row's position, 1-based) --
         // NOT sanitized copies of the descriptive sub-sample label
         // (see loevh2.ado's loevh2_compare for the full rationale).
         // The full, untruncated label is carried forward separately
         // via `HSEN_labels_full' for loevh2_meta_save's numeric,
         // value-labelled `study' variable.
         local HSEN_rownames `"`HSEN_rownames' "group `_row'""'
         local HSEN_labels_full `"`HSEN_labels_full' `"`_slab'"'"'

         di in gr _col(2) "`_slab'" ///
            _col(`labcol') "{c |}" as res ///
            _col(`=`labcol'+3') %7.4f `_hval' ///
            _col(`=`labcol'+15') %7.4f `_bseval' ///
            _col(`=`labcol'+20') %11.0fc `_nval'
      }
   }
   matrix rownames `HSEN' = `HSEN_rownames'
   local Hbar_se = cond(scalar(`bwsum')>0, sqrt(1/scalar(`bwsum')), .)
   local Hbar_N  = scalar(`bnsum')

   di in gr "{hline `=`labcol'-1'}{c +}{hline `=`hlwidth'+2'}"
   di in gr _col(2) "Weighted average H" ///
      _col(`labcol') "{c |}" as res ///
      _col(`=`labcol'+3') %7.4f `Hbar' ///
      _col(`=`labcol'+15') %7.4f `Hbar_se' ///
      _col(`=`labcol'+20') %11.0fc `Hbar_N'
   di in gr "{hline `=`labcol'-1'}{c BT}{hline `=`hlwidth'+2'}"

   if `R' < 1 {
      di as error _n "Note: no common bootstrap replicates available " ///
                   "across sub-samples; cannot compute bootstrap " ///
                   "equality test"
      c_local loevh2_boot_p    = .
      c_local loevh2_boot_chi2 = `Q_obs'
      c_local loevh2_boot_df   = `df'
      c_local loevh2_boot_Hbar = `Hbar'
      c_local loevh2_boot_Hbar_se = `Hbar_se'
      c_local loevh2_boot_Hbar_N  = `Hbar_N'
      c_local loevh2_boot_HSEN = "`HSEN'"
      c_local loevh2_boot_HSEN_labels `"`HSEN_labels_full'"'
      mata: mata drop loevh2_boot_se loevh2_boot_origh loevh2_boot_grp
      exit
   }

   // ---- Build an R x k matrix of paired H_i^(b) replicates. For each
   // group g, its (>= R) non-missing h_boot values from "bootreps" are
   // extracted (in file order) and the first R of them are taken as
   // that group's paired replicates.
   mata: loevh2_boot_Hmat = J(`R', `k', .)
   tempvar bsel
   quietly frame bootreps: gen byte `bsel' = .
   forvalues _g = 1/`k' {
      mata: st_numscalar("`grpval_s'", loevh2_boot_grp[`_g'])
      local _grpval = scalar(`grpval_s')
      quietly frame bootreps: replace `bsel' = (sample==`_grpval' & !missing(h_boot))
      frame bootreps: mata: loevh2_boot_hv = st_data(., "h_boot", "`bsel'")
      mata: loevh2_boot_Hmat[.,`_g'] = loevh2_boot_hv[1::`R',1]
   }

   // ---- Compute Q^(b) for each of the R paired replicates. Q^(b) uses
   // each group's NULL-RECENTERED bootstrap replicate,
   //    H_i^(b)_centered = H_i^(b) - H_i + Hbar
   // (Efron & Tibshirani, 1993, pp. 223-224; Hall & Wilson, 1991;
   // the standard "null-imposed"/shifted percentile-bootstrap device
   // for a bootstrap HYPOTHESIS TEST, as opposed to a bootstrap
   // CONFIDENCE INTERVAL, which must NOT be recentered). Without this
   // recentering, each group's raw bootstrap replicates H_i^(b) stay
   // centered on that group's OWN (possibly very different) observed
   // H_i, so Q^(b) merely reproduces the same cross-group spread that
   // produced the large Q_obs in the first place -- systematically
   // inflating p_boot (in one real test case: Pr = 0.850 from the
   // uncentered version vs. Pr = 0.000 from loevh2's chi2-asymptotic
   // test on the SAME data). Recentering each group's replicates onto
   // the shared Hbar makes the replicate statistics Q^(b) emulate the
   // null hypothesis of equal population H's, so p_boot correctly
   // reflects how extreme Q_obs is UNDER THAT NULL -- consistent with
   // loevh2's own chi2 test on the same Q_obs. The per-group weights
   // 1/orig_se_i^2 are still held fixed across replicates (only the
   // recentered H_i^(b) varies by replicate). Done in a single proper
   // "mata ... end" block (not one-liners), since it involves a
   // multi-statement for-loop. NOTE: a literal bare "end" line here
   // would (inside this "program define ... end" block) actually close
   // the ENCLOSING program rather than just this Mata block, so the
   // closing "end" is instead supplied via a local macro built at
   // runtime by Mata itself (same workaround loevh2.ado uses for its
   // own embedded Mata block).
   mata: st_local("end_mata2", "end")
   mata:
      loevh2_boot_w    = 1 :/ (loevh2_boot_se:^2)
      loevh2_boot_wsum = sum(loevh2_boot_w)
      loevh2_boot_Qb   = J(`R', 1, .)
      for (loevh2_boot_b=1; loevh2_boot_b<=`R'; loevh2_boot_b++) {
         loevh2_boot_hb     = loevh2_boot_Hmat[loevh2_boot_b,.]' :- loevh2_boot_origh :+ `Hbar'
         loevh2_boot_wrsum  = sum(loevh2_boot_w :* loevh2_boot_hb)
         loevh2_boot_wr2sum = sum(loevh2_boot_w :* loevh2_boot_hb:^2)
         loevh2_boot_Qb[loevh2_boot_b] = loevh2_boot_wr2sum - loevh2_boot_wrsum^2/loevh2_boot_wsum
      }
      st_numscalar("_n_ge", sum(loevh2_boot_Qb :>= `Q_obs'))
   `end_mata2'

   local n_ge = _n_ge
   local p_boot = `n_ge' / `R'

   mata: mata drop loevh2_boot_se loevh2_boot_origh loevh2_boot_grp ///
      loevh2_boot_Hmat loevh2_boot_hv loevh2_boot_w loevh2_boot_wsum ///
      loevh2_boot_Qb loevh2_boot_b loevh2_boot_hb loevh2_boot_wrsum ///
      loevh2_boot_wr2sum

   // ---- Display -------------------------------------------------------
   // Chi2/Pr line shown below the table, followed by the "(n_ge/R
   // replicates)" diagnostic detail on its OWN line underneath (same
   // indent), rather than as a trailing parenthetical on the same line.
   di _n as txt "   Bootstrap Chi2(" as res %1.0f `df' as txt ") = " ///
      as res %6.4f `Q_obs' as txt "   Pr = " as res %5.3f `p_boot'
   di as txt "   (" as res `n_ge' as txt "/" as res `R' as txt " replicates >= observed statistic)"

   c_local loevh2_boot_p    = `p_boot'
   c_local loevh2_boot_chi2 = `Q_obs'
   c_local loevh2_boot_df   = `df'
   c_local loevh2_boot_Hbar = `Hbar'
   c_local loevh2_boot_Hbar_se = `Hbar_se'
   c_local loevh2_boot_Hbar_N  = `Hbar_N'
   c_local loevh2_boot_HSEN = "`HSEN'"
   c_local loevh2_boot_HSEN_labels `"`HSEN_labels_full'"'
end
