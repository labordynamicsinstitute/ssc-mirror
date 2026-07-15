*! Version 3.2, Dirk Enzmann (13-Jul-2026)
*!
*! Differences to Version 3.1 (10-Jul-2026):
*!
*! Added option to compare H from sub-samples.
*!
*! Differences to version 3.0 (10-Jul-2026):
*!
*! Added detection of degenerate 2x2 tables (any cell or margin equal to
*! zero).
*!
*! Differences to version 2.0.1 (28-Aug-2025):
*!
*! Calculates SE using /sqrt(N) for exact test of independene instead of 
*! /sqrt(N-1). The exact test should be used only to test whether H differs
*! significantly from zero (score test) not for confidence intervals (Wald CI).
*! This becomes optional (pearson).
*!
*! Calculates SE using the general asymptotic variance of H (Copas & Lober,
*! Eq. 11) and CIs reflecting the variance of H at the estimated value as
*! default.
*!
*! Added option for small sample asymmetric CI (Copas & Loeber, Eqs. 20-23)

program define loevh2_compare
   tempname wsum wrsum wr2sum Hbar chi2 df pchi2
   scalar `Hbar' = .
   scalar `chi2' = .
   scalar `df' = .
   scalar `pchi2' = .
   tempvar ok
   qui gen byte `ok' = !missing(h) & !missing(se)
   qui count if `ok'
   local k = r(N)
   mata: loevh2_hs = st_data(., ("h", "se"), "`ok'")
   mata: st_numscalar("`wsum'",   sum(1 :/ loevh2_hs[.,2]:^2))
   mata: st_numscalar("`wrsum'",  sum(loevh2_hs[.,1] :/ loevh2_hs[.,2]:^2))
   mata: st_numscalar("`wr2sum'", sum(loevh2_hs[.,1]:^2 :/ loevh2_hs[.,2]:^2))
   mata: mata drop loevh2_hs

   if `k' > 1 {
      scalar `Hbar' = `wrsum' / `wsum'
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
      }

      di in gr "{hline `=`labcol'-1'}{c +}{hline `=`hlwidth'+2'}"
      di in gr _col(2) "Weighted average H" ///
         _col(`labcol') "{c |}" as res _col(`=`labcol'+3') %7.4f scalar(`Hbar')
      di in gr "{hline `=`labcol'-1'}{c BT}{hline `=`hlwidth'+2'}"

      di _n as txt "   Pearson chi2(" as res %1.0f scalar(`df') as text ") = " ///
         as res %6.4f scalar(`chi2') ///
         as text "   Pr = " as res %5.3f scalar(`pchi2')
   }
   else {
      di as error "Note: fewer than 2 valid sub-samples; " ///
                   "cannot test equality of H's"
   }
   c_local loevh2_chi2  = `chi2'
   c_local loevh2_df    = `df'
   c_local loevh2_pchi2 = `pchi2'
   c_local loevh2_Hbar  = `Hbar'
end

* ------------------------------------------------------------------------------
program define loevh2, rclass sortpreserve byable(recall)

// Calculate Loevinger's H for two dichotomous variables

   version 14.0
   syntax varlist(min=2 max=2 numeric) [if] [aweight fweight/] ///
          [, Table Level(cilevel) Abbreviate(integer 8) Pearson Small ///
             Compare _boot]

   if "`compare'"=="compare" & ("`small'"=="small" | "`pearson'"=="pearson") {
      di as error "option compare not allowed with small or pearson"
      exit 198
   }
   if "`compare'"=="compare" & !_by() {
      di as error "option compare requires {help by}"
      exit 498
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
      local _byvars_empty = 0
      if !`_byvars_miss' {
         qui count if `touse'
         if r(N) == 0 local _byvars_empty = 1
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
         if "`small'"=="" & "`pearson'"=="" & _bylastcall() {
            capture confirm frame ressubsamp
            if _rc==0 {
               di _n _n as txt "Categories of by: variable(s):"
               fre `_byvars'
               frame change ressubsamp
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
               }
               frame change default
               frame drop ressubsamp

               if `_last_n' > 0 {
                  tempname _crit
                  scalar `_crit' = abs(invnormal(`=(1-`level'/100)/2'))
                  return scalar level = `level'
                  if _by() return local group "`_byvars'"
                  if "`wgt'" != "" {
                     return local weight "`exp'"
                     return local weight_type "`weight'"
                  }
                  tokenize `varlist'
                  return local se_type "large sample"
                  return local var2 "`2'"
                  return local var1 "`1'"
                  return local lastgroup "`_lg_lab'"
                  return scalar N = `_lg_N'
                  return scalar ub = `_lg_h' + scalar(`_crit')*`_lg_se'
                  return scalar lb = `_lg_h' - scalar(`_crit')*`_lg_se'
                  return scalar se = `_lg_se'
                  return scalar loevh = `_lg_h'
               }
               if "`compare'"=="compare" {
                  return scalar p_chi2 = `pchi2'
                  return scalar df = `df'
                  return scalar chi2 = `chi2'
                  return scalar Hbar = `Hbar'
               }
            }
         }
         exit
      }

   }

   tempname crit
   scalar `crit' = abs(invnormal(`=(1-`level'/100)/2'))

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
   local wrongshape = (rowsof(T)!=2 | colsof(T)!=2)
   if `wrongshape' {
      tempname N
      scalar `N' = 0
      forvalues _r=1/`=rowsof(T)' {
         forvalues _c=1/`=colsof(T)' {
            scalar `N' = `N' + T[`_r',`_c']
         }
      }
      if "`_boot'" == "" {
         di as error "Warning: degenerate 2x2 table (a variable has " ///
                      "only one distinct value in this (sub)sample) " ///
                      "-- H and its SE/CI are undefined; returning " ///
                      "missing values"
      }
      return local error "degenerate"
      return scalar N = `N'
      return scalar ub = .
      return scalar lb = .
      return scalar se = .
      return scalar loevh = .
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
      return local error "degenerate"
      return scalar N = `N'
      return scalar ub = .
      return scalar lb = .
      return scalar se = .
      return scalar loevh = .
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
   local sgroupslab ""
   if _by() {
      foreach _bv of local _byvars {
         qui summarize `_bv' if `touse', meanonly
         local _bv_val = r(min)
         local _bv_lab : label (`_bv') `_bv_val'
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
         di _n _n as txt "Categories of by: variable(s):"
         fre `_byvars'
         frame change ressubsamp
         lab val sample sample
         if "`compare'"=="compare" {
            frame ressubsamp: loevh2_compare
            local pchi2 = `loevh2_pchi2'
            local df = `loevh2_df'
            local chi2 = `loevh2_chi2'
            local Hbar = `loevh2_Hbar'
         }
         frame change default
         frame drop ressubsamp
      }
   }

   // Returns
   return scalar level = `level'
   if _by() return local group "`_byvars'"
   if "`wgt'" != "" {
      return local weight "`exp'"
      return local weight_type "`weight'"
   }
   if "`pearson'"=="pearson" return local se_type "Pearson Chi²" 
   else if "`small'"=="small" return local se_type "small sample"
   else return local se_type "large sample"
   return local var2 "`2'"
   return local var1 "`1'"
   if _by() return local lastgroup "`sgroupslab'"
   if _bylastcall() & "`compare'"=="compare" {
      return scalar p_chi2 = `pchi2'
      return scalar df = `df'
      return scalar chi2 = `chi2'
      return scalar Hbar = `Hbar'
   }
   return scalar N = `N'
   return scalar ub = `ub'
   return scalar lb = `lb'
   if "`small'" != "small" return scalar se = `se'
   return scalar loevh = `h'
   scalar drop `h'
end
