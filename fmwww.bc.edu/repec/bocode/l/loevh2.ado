*! Version 3.3, Dirk Enzmann (20-Aug-2026)
*!
*! Calculate Loevinger's H (= RIOC) with SE/CI
*!
*! Differences to Version 3.2 (13-Jul-2026):
*! - Removed aweight support entirely-- users with pweighted (and/or
*!   clustered/stratified) data should use loevh2_svy instead. loevh2 now
*!   accepts only fweight.
*! - Added an "overlap" summary line
*! - Returnes as new scalars r(Hbar_se) and r(Hbar_N).
*! - Added a brief "When to trust the results" section to loevh2.sthlp.
*! - Removed the abbreviate(#) option, now always displays full (untruncated)
*!   variable names.
*! - The immediate command loevhi allows compare.
*! - Added the meta(filename, replace|append) option.
*!
*! Differences to Version 3.2 (13-Jul-2026):
*! - Added option to compare H from sub-samples.
*!
*! Differences to version 3.0 (10-Jul-2026):
*! - Added detection of degenerate 2x2 tables (any cell or margin equal to
*!   zero).
*!
*! Differences to version 2.0.1 (28-Aug-2025):
*! - Calculates SE using /sqrt(N) for exact test of independence instead of 
*!   /sqrt(N-1). This becomes optional (pearson).
*! - Calculates SE using the general asymptotic variance of H (Copas & Lober,
*!   Eq. 11) and CIs reflecting the variance of H at the estimated value as
*!   default.
*! - Added option for small sample asymmetric CI (Copas & Loeber, Eqs. 20-23)

program define loevh2, rclass sortpreserve byable(recall)

// Calculate Loevinger's H for two dichotomous variables

   version 16.0

   local _origframe = c(frame)
   local _origchanged = c(changed)

   syntax varlist(min=2 max=2 numeric) [if] [fweight/] ///
          [, Table Level(cilevel) Pearson Small ///
             Compare meta(string asis) _boot]

   // See: https://www.statalist.org/forums/forum/general-stata-discussion/general/152134

   capture which fre
   if ( _rc ) {
      capture window stopbox rusure "This program requires -fre-. Do you want to install -fre-?"
      if ( _rc ) exit 111
      ssc install fre
   }

   // Build the fweight-forwarding local `wgt' immediately after -syntax-
   // (rather than only later, just before the main tabulate/corr calls),
   // so it is already in scope for the "Categories of by: variable(s)"
   // -fre- calls in the early by-group skip branches below (missing
   // by-value, or an -if/in- condition leaving zero observations for
   // this by-group), not just the main body of the program. Without
   // this, any fweight'ed by:+compare call (e.g. as generated
   // internally by loevh2i's tabi-based group expansion, but equally
   // possible with genuine survey/aggregated fweight data) showed each
   // sub-sample's RAW physical observation count in that table instead
   // of its true (weighted) N.
   local wgt ""
   if "`weight'" != "" & "`exp'" != "" local wgt "[`weight'=`exp']"

   if "`compare'"=="compare" & ("`small'"=="small" | "`pearson'"=="pearson") {
      di as error "option compare not allowed with small or pearson"
      exit 198
   }
   if "`compare'"=="compare" & !_by() {
      di as error "option compare requires {help by}"
      exit 498
   }

   // meta() no longer requires -compare- (nor -by-): it can be used
   // standalone with a plain, single-sample call (one row saved), with
   // by: alone (one row saved per by-group, labeled by its by-value),
   // or with by: + compare (the pooled compare-table rows, exactly as
   // before). meta() IS still incompatible with small/pearson, since
   // those SE types are not on the large-sample scale that the
   // meta-analysis pooling formula (and Stata's -meta- suite) assumes.
   if `"`meta'"' != `""' & ("`small'"=="small" | "`pearson'"=="pearson") {
      di as error "option meta() not allowed with small or pearson"
      exit 198
   }

   marksample touse, nov

   // Build a second sample marker, `tousegrp', that reflects only the
   // -in- restriction (if any), but NOT the user's -if- condition. This
   // is used solely to detect whether the CURRENT by-group's
   // by-variable value is missing. We cannot rely on `touse' for this
   // purpose because a user -if- condition (e.g. "if male < .") can
   // zero out `touse' for an entire missing-value by-group, which would
   // otherwise hide the fact that the group's by-value is missing and
   // let execution fall through to compute H on a stale/empty
   // tabulation. `tousegrp' is scoped correctly to just the current
   // by-group's observations by Stata's by: mechanism (like `touse'
   // would be, absent the user's -if-), so checking missingness of the
   // by-variable against `tousegrp' correctly reflects only this group.

   tempvar tousegrp
   mark `tousegrp' `in'
   markout `tousegrp'

   // If this is a by-group call and the by-variable(s) value for the
   // current group is missing (system missing "." or an extended
   // missing value ".a" - ".z"), skip this by-group entirely: do not
   // compute or display H, and do not add it to the sub-sample
   // comparison frame. This avoids relying on egen's group()/label
   // numbering (which does not map cleanly onto _byindex() when the
   // by-variable has missing values) and keeps the behavior simple and
   // predictable, as requested.
   //
   // Because Stata's by: always sorts missing values of the by-variable
   // last, any missing-value by-group(s) will always be the final
   // group(s) processed, so _bylastcall() will be true for the very
   // last missing-value group (if any). We therefore also check for
   // _bylastcall() here, so the sub-sample comparison summary (built
   // from all prior, non-missing groups) is displayed once, right after
   // the note for the last (possibly missing) by-group, matching the
   // normal behavior below for the non-missing case.

   if _by() {
      // A by-group is skipped if the by-variable(s) actual value for
      // this group is missing (system or extended missing), detected
      // using `tousegrp' (scoped to the current by-group, but
      // unaffected by the user's -if- condition).
      local _byvars_miss = 0
      foreach _bv of local _byvars {
         qui count if `tousegrp' & missing(`_bv')
         if r(N) > 0 local _byvars_miss = 1
      }

      // Also determine whether the user's -if/in- condition leaves
      // zero observations for this particular by-group (e.g. "bysort
      // country: loevh2 ... if inlist(country, 3580, 3700)" still
      // creates a by-group call for EVERY distinct value of country in
      // the dataset, including those excluded by the -if-; for those,
      // `touse' is all zero even though the by-value itself is not
      // missing).
      //
      // Also proactively check whether `touse', though not entirely
      // zero, still leaves ZERO observations with non-missing analysis
      // variables (var1/var2) for this by-group. This happens whenever
      // an -if- condition UNRELATED to the by-variable(s) (e.g. "if
      // some_other_var==5"), or simply having both analysis variables
      // entirely missing within one particular by-group, effectively
      // empties the group -- even though `touse' itself (built with
      // marksample's `nov' option, which does NOT auto-exclude missing
      // varlist values) remains nonzero. Catching this case here, up
      // front, avoids ever reaching the binary-variable-check/tabulate/
      // matrix logic below with zero usable observations, which would
      // otherwise require ad hoc, fragile matrix-existence handling
      // there instead of the single, consistent "by-group ... skipped"
      // path used for every other reason a group can be empty.
      local _byvars_empty = 0
      if !`_byvars_miss' {
         qui count if `touse'
         if r(N) == 0 local _byvars_empty = 1
         else {
            tokenize `varlist'
            qui count if `touse' & !missing(`1') & !missing(`2')
            if r(N) == 0 local _byvars_empty = 1
         }
      }

      if `_byvars_miss' | `_byvars_empty' {
         if "`_boot'" == "" {
            di as txt _n "Note: by-group with missing value of " ///
                         `"`_byvars'"' " (or no observations selected " ///
                         "by if/in) skipped (H is not estimated for " ///
                         "missing values of the by-variable)."
         }

         return local error "missing_byvar"

         // If this is the true last by-group in the whole by-sequence,
         // display the final comparison summary now, using the results
         // already accumulated (in the "ressubsamp" frame) from prior
         // valid groups. This branch must return, alongside the
         // compare scalars (r(Hbar), r(chi2), r(df), r(p_chi2)), the
         // SAME per-group results (r(loevh), r(se), r(lb), r(ub),
         // r(N)) that were displayed for the last VALID by-group
         // processed -- otherwise, whenever the last by-group call in
         // the sequence happens to be a missing/if-excluded one, these
         // per-group results would never be returned to the user, even
         // though they were computed and displayed earlier. r(lastgroup)
         // identifies (by its by-value label) which valid group these
         // returned per-group results belong to.
         //
         // NOTE: meta() is deliberately NOT triggered in this skip-
         // forwarding branch, even though the forwarded results
         // (r(loevh) etc.) originate from the last VALID group -- that
         // valid group already triggered its own meta() save when IT
         // was processed (further down in this program, or via the
         // compare block just below), so saving again here would
         // create a duplicate row in the meta() output file.
         if "`small'"=="" & "`pearson'"=="" & _bylastcall() {
            capture confirm frame ressubsamp
            if _rc==0 {
               if "`compare'"=="compare" {
                  di _n _n as txt "Categories of by: variable(s):"
                  fre `_byvars' `if' `in' `wgt'
               }

               frame ressubsamp {

                  lab val sample sample

                  local _last_n = _N
                  if `_last_n' > 0 {
                     local _lg_h    = h[`_last_n']
                     local _lg_se   = se[`_last_n']
                     local _lg_N    = n[`_last_n']
                     local _lg_sval = sample[`_last_n']
                     local _lg_lab : label (sample) `_lg_sval'
                  }

                  if "`compare'"=="compare" {
                     loevh2_compare
                     local pchi2 = `loevh2_pchi2'

                     local df = `loevh2_df'
                     local chi2 = `loevh2_chi2'
                     local Hbar = `loevh2_Hbar'
                     local Hbar_se = `loevh2_Hbar_se'
                     local Hbar_N = `loevh2_Hbar_N'
                     local HSEN = "`loevh2_HSEN'"
                     local HSENLAB = `"`loevh2_HSEN_labels'"'

                if `"`meta'"' != `""' & "`HSEN'"!="" {
                   loevh2_meta_save, metaspec(`meta') ///
                      source(loevh2) setype("large sample") ///
                      hsen(`HSEN') labels(`"`HSENLAB'"') ///
                      origframe(`"`_origframe'"') origchanged(`_origchanged')
                }
             }
          }
          frame drop ressubsamp

          if `_last_n' > 0 {
                  tempname _crit
                  scalar `_crit' = abs(invnormal(`=(1-`level'/100)/2'))
                  tokenize `varlist'
                  return scalar loevh = `_lg_h'
                  return scalar se = `_lg_se'
                  return scalar lb = `_lg_h' - scalar(`_crit')*`_lg_se'
                  return scalar ub = `_lg_h' + scalar(`_crit')*`_lg_se'
                  return scalar level = `level'
                  return scalar N = `_lg_N'
               }
               if "`compare'"=="compare" {
                  return scalar Hbar = `Hbar'
                  return scalar Hbar_se = `Hbar_se'
                  return scalar chi2 = `chi2'
                  return scalar df = `df'
                  return scalar p_chi2 = `pchi2'
                  return scalar Hbar_N = `Hbar_N'
                  if "`HSEN'" != "" return matrix H_SE_N = `HSEN'
               }
               if `_last_n' > 0 {
                  return local var1 "`1'"
                  return local var2 "`2'"
                  return local se_type "large sample"
                  if "`wgt'" != "" {
                     return local weight_type "`weight'"
                     return local weight "`exp'"
                  }
                  if _by() return local group "`_byvars'"
                  return local lastgroup "`_lg_lab'"
               }
             }
          }
          exit
       }

   }

   tempname crit
   scalar `crit' = abs(invnormal(`=(1-`level'/100)/2'))

   // Set up weight syntax - simplified. Only fweight is supported (see
   // changelog above: pweight/aweight support has been removed; use
   // loevh2_svy for design-based/pweight inference).
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
   //
   // CRITICAL: T is a fixed (non-tempname) matrix name, which means it
   // PERSISTS across successive by-group calls (byable(recall) re-runs
   // this whole program once per group) unless explicitly cleared. If a
   // particular by-group's touse-restricted subsample happens to yield
   // ZERO observations to tabulate (e.g., all analysis-variable values
   // are missing in that by-group -- possible because `touse' is built
   // with marksample's `nov' option, which does NOT auto-exclude
   // missing varlist values), "tabulate ... matcell(T)" silently
   // returns rc=0 WITHOUT creating or modifying T at all -- leaving T
   // holding the STALE 2x2 matrix from the previous by-group's
   // tabulation. Without clearing T first, this stale table would
   // silently produce a plausible-looking but WRONG (not missing, not
   // degenerate-flagged) H/SE/N for the current by-group, identical to
   // the previous group's results. Dropping T first forces a genuine
   // "no observations" case to leave T undefined, so rowsof(T)/
   // colsof(T) below correctly return 0, correctly tripping the
   // existing `wrongshape' guard (which already handles a non-2x2
   // result by returning missing values with a clear warning).
   capture matrix drop T
   if "`table'" == "" {
      qui tabulate `varlist' if `touse' `wgt', matcell(T)
   }
   else {
      tabulate `varlist' if `touse' `wgt', cell expected matcell(T)
   }

   // Guard against a non-2x2 tabulation matrix. Even though both
   // varlist variables are checked above to take on the values 0/1
   // somewhere (possibly falling back to the full, un-by-restricted
   // dataset to accommodate bootstrap resampling), it is still possible
   // for THIS by-group's touse-restricted subsample to contain only one
   // distinct value of one (or both) variables -- e.g. a specific
   // country/sex subgroup where everyone answered the same way on one
   // item. In that case, "tabulate ... matcell(T)" returns a matrix
   // with fewer than 2 rows and/or columns, which would otherwise crash
   // the Mata block below (subscript invalid) when indexing T[1,2] or
   // T[2,1]. Treat this exactly like a degenerate 2x2 table: return
   // missing results gracefully instead of aborting.
   // T may not exist at all here (rather than merely having the wrong
   // shape) whenever the touse-restricted tabulate above genuinely
   // matched zero observations (e.g. all analysis-variable values are
   // missing for this by-group) -- capture matrix drop T just above
   // guarantees this is a clean "not found" rather than a stale
   // leftover matrix, but rowsof()/colsof() would themselves raise
   // r(111) on a nonexistent matrix, so its existence must be checked
   // explicitly first and treated as an (rowsof=0, colsof=0) wrong-
   // shape case.
   capture confirm matrix T
   local _Texists = (_rc==0)
   local wrongshape = !`_Texists' | (rowsof(T)!=2 | colsof(T)!=2)
   if `wrongshape' {
      tempname N
      scalar `N' = 0
      if `_Texists' {
         forvalues _r=1/`=rowsof(T)' {
            forvalues _c=1/`=colsof(T)' {
               scalar `N' = `N' + T[`_r',`_c']
            }
         }
      }

      if "`_boot'" == "" {
         di as error "Warning: degenerate 2x2 table (a variable has " ///
                      "only one distinct value in this (sub)sample) " ///
                      "-- H and its SE/CI are undefined; returning " ///
                      "missing values"
      }
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `N'
      return local error "degenerate"
      exit
   }

   // H coefficient calculation
   tempname h se z p lb ub N
   tempname a b c d e f alpha beta delta se_delta philb phiub
   scalar `a' = T[2,2]
   scalar `b' = max(T[1,2], T[2,1])
   scalar `c' = min(T[1,2], T[2,1])
   scalar `d' = T[1,1]
   scalar `e' = `a' + `b'
   scalar `f' = `a' + `c'
   scalar `N' = `a' + `b' + `c' + `d'

   // Overlap summary: P(var1=1 & var2=1) = a/N (the (2,2) cell of the
   // already-tabulated matrix T, i.e. cell "a" above), shown as a
   // percentage together with its standard error and a logit-
   // transformed asymmetric Wald CI, displayed (with -table- only)
   // immediately after the cross-tabulation and BEFORE the "Number of
   // obs"/"Loevinger" header block, analogous to loevh2_svy's own
   // overlap summary. Unlike loevh2_svy's design-based SE, this SE uses
   // the simple binomial-proportion formula sqrt(p*(1-p)/N), consistent
   // with loevh2's existing N-based large-sample approach for H itself
   // (not a design-based SE -- see loevh2_svy for that). Computed here,
   // right after the T matrix is available and before the degenerate-
   // table guard below, so it can be displayed on screen immediately
   // after the cross-tab even in the (rare) case that H itself later
   // turns out to be undefined (a/N is always computable as long as
   // N>0, unlike H, which additionally requires non-zero margins).
   // Always available via r() regardless of -table-. `crit' was
   // already computed earlier in the program (before the by-group
   // missing-value checks), so it is simply reused here, not
   // redeclared.
   tempname ov ov_se ov_lb ov_ub ov_logit ov_logit_se

   scalar `ov' = `a'/`N'
   if `ov'>0 & `ov'<1 {
      scalar `ov_se' = sqrt(`ov'*(1-`ov')/`N')
      scalar `ov_logit' = ln(`ov'/(1-`ov'))
      scalar `ov_logit_se' = `ov_se'/(`ov'*(1-`ov'))
      scalar `ov_lb' = invlogit(`ov_logit' - `crit'*`ov_logit_se')
      scalar `ov_ub' = invlogit(`ov_logit' + `crit'*`ov_logit_se')
   }
   else {
      // p at the boundary (0 or 1): logit is undefined; leave SE/CI
      // missing rather than attempting a division by zero.
      scalar `ov_se' = .
      scalar `ov_lb' = .
      scalar `ov_ub' = .
   }
   local cil = string(`level')
   if "`table'"=="table" {

      // `1'/`2' must be freshly (re-)tokenized from `varlist' here,
      // immediately before first use: at this point in the program,
      // positional locals `1'/`2' may still hold stale tokens left
      // over from Stata's own internal command-line parsing (which,
      // for a plain non-by: call, can leave a spurious trailing comma
      // attached to `2', e.g. "item2," instead of "item2" -- since the
      // comma separating the variable list from the option list is
      // itself a token boundary Stata's parser does not always strip
      // before -syntax- has fully processed the command). The later,
      // pre-existing "tokenize `varlist''" call further down (in the
      // "Output formatting" section) refreshes `1'/`2' correctly for
      // its own purposes, but that happens only after this Overlap
      // block runs, so it cannot be relied on here.
      tokenize `varlist'
      di _n as txt "Overlap (" as res "`1'" as txt "=1 & " as res "`2'" as txt "=1):"
      if `ov_se'<. {

         di as txt "   " as res %7.2f `=`ov'*100' ///
            as txt "   Std. err. " as res %5.2f `=`ov_se'*100' ///
            as txt "   [" as res "`cil'" as txt "% CI (logit): " ///
            as res %5.2f `=`ov_lb'*100' " " %5.2f `=`ov_ub'*100' as txt "]"
      }
      else {
         di as txt "   " as res %7.2f `=`ov'*100' ///
            as txt "   Std. err. " as res "." ///
            as txt "   [" as res "`cil'" as txt "% CI (logit): . .]"
      }
   }

   // Check for a degenerate 2x2 table: any cell (a,b,c,d) or margin
   // (e, f, N-e, N-f) equal to zero makes H (and its SE) undefined
   // (division by zero). This can happen, e.g., during bootstrap
   // resampling when a resample yields an unbalanced or constant
   // variable. Rather than aborting (which would break capture-based
   // callers such as loevh2_boot), return missing results gracefully.
   local degenerate = (`a'==0 | `b'==0 | `c'==0 | `d'==0 | ///
                        `e'==0 | `f'==0 | (`N'-`e')==0 | (`N'-`f')==0)
   if `degenerate' {
      if "`_boot'" == "" {
         di as error "Warning: degenerate 2x2 table (a zero cell or " ///
                      "margin) -- H and its SE/CI are undefined; " ///
                      "returning missing values"
      }
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `N'
      return scalar overlap = `ov'
      return scalar se_overlap = `ov_se'
      return scalar lb_overlap = `ov_lb'
      return scalar ub_overlap = `ov_ub'
      return local error "degenerate"
      exit
   }

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
   scalar `alpha' = `e'/`N'
   scalar `beta' = `f'/`N'
   
   // Statistical calculations

   scalar `se' = sqrt(`N'*`c'*(`N'*`f'*(`N'-`e') + ///
                       `c'*(`N'*`e' + `e'*`f'-2*`N'*`f'-`N'^2) + ///
                       2*`N'*`c'^2) / ///
                       ((`N'-`e')^3*`f'^3))
   scalar `z' = `h'/`se'
   scalar `p' = 2*(1-normal(abs(`z')))
   scalar `lb' = `h' - `crit'*`se'
   scalar `ub' = `h' + `crit'*`se'
   
   if "`pearson'"=="pearson" {
      qui corr `varlist' if `touse' `wgt', c
      scalar `z' = r(cov_12)/sqrt(r(Var_2)*r(Var_1))*sqrt(`N')
      scalar `se' = `h'/`z'
      scalar `p' = 2*(1-normal(abs(`z')))
   }
   else if "`small'"=="small" {
      scalar `delta' = ln((`a' + 0.5)*(`d' + 0.5)/((`b' + 0.5)*(`c' + 0.5)))
      scalar `se_delta' = sqrt((`e'+1)*(`e'+2)/ /// 
                               (`e'*(`a'+1)*(`b'+1)) + ///
                               (`N'+1-`e')*(`N'+2-`e')/ ///
                               ((`N'-`e')*(`c'+1)*(`d'+1)))
      scalar `philb' = exp(`delta' - `crit'*`se_delta')
      scalar `phiub' = exp(`delta' + `crit'*`se_delta')
      scalar `se' = .
      scalar `z'  = .
      scalar `p'  = .
      scalar `lb' = (1+(`philb'-1)*(`alpha'+`beta'-2*`alpha'*`beta') - ///
                    sqrt((1+(`alpha'+`beta')*(`philb'-1))^2 - ///
                          4*`alpha'*`beta'*`philb'*(`philb'-1))) / ///
                    ( 2*(`philb'-1)*min(`beta',`alpha')*(1-max(`alpha',`beta')))
      scalar `ub' = (1+(`phiub'-1)*(`alpha'+`beta'-2*`alpha'*`beta') - ///
                    sqrt((1+(`alpha'+`beta')*(`phiub'-1))^2 - ///
                          4*`alpha'*`beta'*`phiub'*(`phiub'-1))) / ///
                    ( 2*(`phiub'-1)*min(`beta',`alpha')*(1-max(`alpha',`beta')))
   }

   // Output formatting -- full variable names (no abbreviation), same
   // approach as loevh2_svy: `1'/`2' are simply aliased directly, with
   // no truncation.
   tokenize `varlist'
   local v1 "`1'"
   local v2 "`2'"

   local vars "`v1' `v2'"
   local colsv = max(length("`vars'"), 17) + 2
   local inc = `colsv' - 19

   // Display output
   local dig = ceil(log10(max(1,scalar(`N')))) + 2
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

   if "`small'"=="small" {
      di in smcl in gr /*
      */ " `vars'" _col(`colsv') " {c |}" _col(`=18+`inc'') as res /*
      */ _col(`=25+`inc'') %7.0g `h' /*
      */ _col(`=62+`inc'') %7.0g `lb' /*
      */ _col(`=75+`inc'') %7.0g `ub'
   }
   else {
      di in smcl in gr /*
      */ " `vars'" _col(`colsv') " {c |}" _col(`=18+`inc'') as res /*
      */ _col(`=25+`inc'') %7.0g `h' /*
      */ _col(`=36+`inc'') %7.0g `se' /*
      */ _col(`=45+`inc'') %7.2f `z' /*
      */ _col(`=51+`inc'') %7.3f `p' /*
      */ _col(`=62+`inc'') %7.0g `lb' /*
      */ _col(`=75+`inc'') %7.0g `ub'
   }

   // Compute the current by-group's label (e.g. "male", "Lithuania")
   // unconditionally whenever by: is in effect, regardless of small/
   // pearson, so that r(lastgroup) -- identifying which sub-sample the
   // just-returned per-group results (r(loevh), r(se), r(N), etc.)
   // belong to -- is always available with by:, not just with the
   // default (large-sample) SE type or with -compare-.
   //
   // Each by-variable can be either numeric (in which case its value
   // label, if any, is looked up via "summarize" + ": label") or a
   // string (in which case -summarize- does not apply at all -- it
   // silently produces no r(min), leaving the label empty, which was
   // the cause of blank/"." sub-sample labels whenever the by-variable
   // was a string). For a string by-variable, its own text value (for
   // this by-group) is used directly as the label, obtained from the
   // first `touse'-selected observation.
   local sgroupslab ""
   if _by() {
      foreach _bv of local _byvars {
         capture confirm string variable `_bv'
         if !_rc {

            // String by-variable: -summarize- does not apply, so use
            // the by-variable's own text value (for this by-group)
            // directly as the label, taken from the first
            // `touse'-selected observation. -levelsof-'s "clean" option
            // strips the surrounding quotes it would otherwise wrap
            // around each distinct value, but ALSO makes the resulting
            // local a plain, UNquoted, whitespace-separated word list --
            // so a multi-word string value (e.g. "West Germany") is
            // incorrectly split into two separate "words" ("West" and
            // "Germany"), and ": word 1 of ..." then returns only the
            // first of them. Fixed by omitting "clean": without it,
            // -levelsof- instead wraps each distinct value in its own
            // pair of double quotes (e.g. `"West Germany"'), which
            // Stata's macro-list functions (including "word 1 of")
            // correctly treat as ONE atomic token regardless of any
            // embedded spaces; the surrounding quotes are then stripped
            // manually via -subinstr-.
            qui levelsof `_bv' if `touse', local(_bv_lvls)
            local _bv_lab : word 1 of `_bv_lvls'
            local _bv_lab = subinstr(`"`_bv_lab'"', `"""', "", .)
         }

         else {
            // Numeric by-variable: look up its value label (if any)
            // for this group's value, as before.
            qui summarize `_bv' if `touse', meanonly
            local _bv_val = r(min)
            local _bv_lab : label (`_bv') `_bv_val'
         }
         local sgroupslab = trim("`sgroupslab' `_bv_lab'")
      }
   }

   tempname ressubsamp
   if "`small'"=="" & "`pearson'"=="" & _by() {

      // Create the ressubsamp frame lazily, the first time any
      // by-group actually reaches this point. We cannot rely on
      // _byindex()==1 to know whether this is the first group to post
      // results, because an earlier by-group (by _byindex() order) may
      // have been skipped -- e.g. a missing by-value (handled above)
      // or a degenerate/non-2x2 table for that group (handled by the
      // early-exit guards above, before this code is ever reached for
      // that group). Using a robust "create if not exists" check makes
      // frame creation independent of which by-group happens to be
      // first in the overall by-sequence.
      //
      // Safety net: if this is the very first by-group of a brand new
      // by-sequence (_byindex()==1) but a "ressubsamp" frame already
      // exists (e.g. left over from a prior run of loevh2 that was
      // interrupted by an error before its own end-of-sequence cleanup
      // could run), drop it first so results from an earlier,
      // unrelated run never leak into/accumulate with the current run.
      if _byindex()==1 {
         capture frame drop ressubsamp
      }
      capture confirm frame ressubsamp
      if _rc {
         frame create ressubsamp sample h se n
      }

      local sample = _byindex()
      frame post ressubsamp (`sample') (`h') (`se') (`N')
      frame ressubsamp: lab def sample `sample' "`sgroupslab'", modify

      if _bylastcall() {
         if "`compare'"=="compare" {
            di _n _n as txt "Categories of by: variable(s):"
            fre `_byvars' `if' `in' `wgt'
         }
         frame ressubsamp {
            lab val sample sample
            if "`compare'"=="compare" {
               loevh2_compare
               local pchi2 = `loevh2_pchi2'
               local df = `loevh2_df'
               local chi2 = `loevh2_chi2'
               local Hbar = `loevh2_Hbar'
               local Hbar_se = `loevh2_Hbar_se'
               local Hbar_N = `loevh2_Hbar_N'
               local HSEN = "`loevh2_HSEN'"
               local HSENLAB = `"`loevh2_HSEN_labels'"'

               if `"`meta'"' != `""' & "`HSEN'"!="" {
                  loevh2_meta_save, metaspec(`meta') ///
                     source(loevh2) setype("large sample") ///
                     hsen(`HSEN') labels(`"`HSENLAB'"') ///
                     origframe(`"`_origframe'"') origchanged(`_origchanged')
               }
            }
         }
         frame drop ressubsamp
      }
   }

   // meta() single-row save: fires whenever meta() is specified and we
   // are NOT in the by:+compare pooling branch just above (which, when
   // it fires on the last by-group, already saves ALL rows -- including
   // this group's -- via the HSEN matrix). This uniformly covers:
   //   (a) a plain, non-by: call            -> label = "var1_var2"
   //   (b) by: without compare               -> label = sgroupslab,
   //       one row saved per by-group as each is processed
   //   (c) by: + compare, for every by-group EXCEPT the last one (the
   //       last one's row is already included in the pooled HSEN save
   //       above, so it must NOT also be single-row-saved here, or it
   //       would be duplicated).
   if `"`meta'"' != `""' & "`compare'"!="compare" {
      local _metalab = cond(_by(), "`sgroupslab'", "`v1'_`v2'")
      loevh2_meta_save, metaspec(`meta') source(loevh2) ///
         setype("large sample") label(`"`_metalab'"') ///
         hval(`=`h'') seval(`=`se'') nval(`=`N'') ///
         origframe(`"`_origframe'"') origchanged(`_origchanged')
   }

   // Returns
   if "`small'" != "small" return scalar se = `se'
   return scalar loevh = `h'
   return scalar lb = `lb'
   return scalar ub = `ub'
   return scalar level = `level'
   return scalar N = `N'
   return scalar overlap = `ov'
   return scalar se_overlap = `ov_se'
   return scalar lb_overlap = `ov_lb'
   return scalar ub_overlap = `ov_ub'
   if _bylastcall() & "`compare'"=="compare" {
      return scalar Hbar = `Hbar'
      return scalar Hbar_se = `Hbar_se'
      return scalar chi2 = `chi2'
      return scalar df = `df'
      return scalar p_chi2 = `pchi2'
      return scalar Hbar_N = `Hbar_N'
      if "`HSEN'" != "" return matrix H_SE_N = `HSEN'
   }
   return local var1 "`1'"
   return local var2 "`2'"
   if "`pearson'"=="pearson" return local se_type "Pearson Chi²" 
   else if "`small'"=="small" return local se_type "small sample"
   else return local se_type "large sample"
   if "`wgt'" != "" {
      return local weight_type "`weight'"
      return local weight "`exp'"
   }
   if _by() return local group "`_byvars'"
   if _by() return local lastgroup "`sgroupslab'"
   scalar drop `h'
end

* ------------------------------------------------------------------------------
program define loevh2_compare

   version 16.0
   tempname wsum wrsum wr2sum Hbar Hbar_se Hbar_N chi2 df pchi2
   scalar `Hbar' = .
   scalar `Hbar_se' = .
   scalar `Hbar_N' = .
   scalar `chi2' = .
   scalar `df' = .
   scalar `pchi2' = .
   tempvar ok
   qui gen byte `ok' = !missing(h) & !missing(se)
   qui count if `ok'
   local k = r(N)

   if `k' > 1 {

      // The equality test (chi2/df/p below) reproduces Copas & Loeber's
      // (1990) Eq. 16 test exactly, on the raw (untransformed) H_i/SE_i:
      // for each valid sub-sample i, weight w_i = 1/SE_i^2; Hbar is the
      // weighted average of H_i, and chi2 = sum(w_i*H_i^2) -
      // (sum(w_i*H_i))^2/sum(w_i), distributed on (k-1) df under the
      // null that all population H's are equal.
      mata: loevh2_hs = st_data(., ("h", "se"), "`ok'")
      mata: st_numscalar("`wsum'",   sum(1 :/ loevh2_hs[.,2]:^2))
      mata: st_numscalar("`wrsum'",  sum(loevh2_hs[.,1] :/ loevh2_hs[.,2]:^2))
      mata: st_numscalar("`wr2sum'", sum(loevh2_hs[.,1]:^2 :/ loevh2_hs[.,2]:^2))
      mata: mata drop loevh2_hs

      scalar `Hbar' = `wrsum' / `wsum'

      // Pooled (inverse-variance-weighted meta-analysis) SE of the
      // weighted average H -- SE(Hbar) = sqrt(1 / sum(1/SE_i^2)) --
      // plus the total N summed across all valid sub-samples, both
      // shown alongside Hbar on the "Weighted average H" summary line
      // below (mirroring loevh2_svy_compare).
      scalar `Hbar_se' = sqrt(1/`wsum')
      qui summarize n if `ok', meanonly
      scalar `Hbar_N' = r(sum)

      scalar `chi2' = `wr2sum' - (`wrsum')^2 / `wsum'
      scalar `df'   = `k' - 1
      scalar `pchi2' = chi2tail(`df', `chi2')

      // Column layout: sample label, H Coeff, Std. err., N. The label
      // column width adapts to the longest sub-sample label (or to the
      // "Weighted average H" row label, if that is longer), so labels
      // are never truncated.
      local hlwidth = 30
      local maxlablen = length("Weighted average H")
      local N = _N
      forvalues obs = 1/`N' {
         local sval = sample[`obs']
         local slab : label (sample) `sval'
         if length("`slab'") > `maxlablen' local maxlablen = length("`slab'")
      }
      local labcol = `maxlablen' + 3

      di _n as txt "Test of equality of H's across " as res `N' ///
         as txt " sub-samples:"
      di _n in gr ///
         _col(2) "Sub-sample" ///
         _col(`labcol') "{c |}" ///
         _col(`=`labcol'+3') "H Coeff" ///
         _col(`=`labcol'+13') "Std. err." ///
         _col(`=`labcol'+32') "N"
      di in gr "{hline `=`labcol'-1'}{c +}{hline `=`hlwidth'+2'}"

      // Build the returned r(H_SE_N) matrix (rows = sub-samples, in the
      // same order as the on-screen table below; columns = H, SE, N)
      // alongside the table display. Row names are short, guaranteed-
      // unique "group N" identifiers (N = row position, 1-based) --
      // see the in-loop comment below for the full rationale; the
      // on-screen table itself always shows the full, untruncated
      // descriptive sub-sample label.
      //
      // A fixed (non-tempname) matrix name is used here rather than
      // -tempname-, because this matrix must survive being handed back
      // to the caller via c_local across a "frame change"/"frame drop"
      // boundary (loevh2_compare is typically invoked as "frame
      // ressubsamp: loevh2_compare"); a tempname matrix's automatic
      // name is only reliably valid within the scope of the program
      // instance that created it and does not survive that transition
      // intact. The caller copies it into its own tempname matrix
      // immediately upon return and this fixed-name matrix is dropped
      // here at the very start of each call, so no stale copy persists
      // across repeated calls.
      capture matrix drop __loevh2_HSEN
      matrix __loevh2_HSEN = J(`N', 3, .)
      local HSEN "__loevh2_HSEN"
      matrix colnames `HSEN' = H SE N
      local HSEN_rownames ""
      local HSEN_labels_full ""

      forvalues obs = 1/`N' {
         local hval = h[`obs']
         local seval = se[`obs']
         local nval = n[`obs']
         local sval = sample[`obs']
         local slab : label (sample) `sval'
         if missing(`hval') | missing(`seval') continue

         di in gr _col(2) "`slab'" ///
            _col(`labcol') "{c |}" as res ///
            _col(`=`labcol'+3') %7.4f `hval' ///
            _col(`=`labcol'+15') %7.4f `seval' ///
            _col(`=`labcol'+20') %11.0fc `nval'

         matrix `HSEN'[`obs',1] = `hval'
         matrix `HSEN'[`obs',2] = `seval'
         matrix `HSEN'[`obs',3] = `nval'
         // Row names are now simple, guaranteed-short, collision-free
         // "group N" identifiers (N = this row's position in the
         // on-screen table above, 1-based) -- NOT sanitized copies of
         // the descriptive sub-sample label. This avoids Stata's
         // matlist/matrix-list display abbreviating long/special-
         // character labels (e.g. "West & Farrington (1977) [1]") down
         // to an unreadable "West___Fa~1_"-style truncation. The full,
         // untruncated descriptive label remains visible in the
         // on-screen table above (never truncated) and is ALSO carried
         // forward, in full, via `HSEN_labels_full' (handed back to
         // the caller via c_local loevh2_HSEN_labels, below) for use
         // by loevh2_meta_save's numeric, value-labelled `study'
         // variable -- see loevh2_meta_save.ado/loevh2_meta_writedo.ado.
         local HSEN_rownames `"`HSEN_rownames' "group `obs'""'
         local HSEN_labels_full `"`HSEN_labels_full' `"`slab'"'"'
      }
      matrix rownames `HSEN' = `HSEN_rownames'

      di in gr "{hline `=`labcol'-1'}{c +}{hline `=`hlwidth'+2'}"
      di in gr _col(2) "Weighted average H" ///
         _col(`labcol') "{c |}" as res ///
         _col(`=`labcol'+3') %7.4f scalar(`Hbar') ///
         _col(`=`labcol'+15') %7.4f scalar(`Hbar_se') ///
         _col(`=`labcol'+20') %11.0fc scalar(`Hbar_N')
      di in gr "{hline `=`labcol'-1'}{c BT}{hline `=`hlwidth'+2'}"

      di _n as txt "   Pearson chi2(" as res %1.0f scalar(`df') as text ") = " ///
         as res %6.4f scalar(`chi2') ///
         as text "   Pr = " as res %5.3f scalar(`pchi2')

      c_local loevh2_HSEN "`HSEN'"
      c_local loevh2_HSEN_labels `"`HSEN_labels_full'"'

   }
   else {
      di as error "Note: fewer than 2 valid sub-samples; " ///
                   "cannot test equality of H's"
   }
   c_local loevh2_chi2  = `chi2'
   c_local loevh2_df    = `df'
   c_local loevh2_pchi2 = `pchi2'
   c_local loevh2_Hbar  = `Hbar'
   c_local loevh2_Hbar_se = `Hbar_se'
   c_local loevh2_Hbar_N  = `Hbar_N'
end
