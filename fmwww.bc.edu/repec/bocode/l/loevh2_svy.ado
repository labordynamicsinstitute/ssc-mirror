*! Version 1.0, Dirk Enzmann (20-Aug-2026)
*!
*! Design-based (survey) H/SE/CI for Loevinger's H (e.g. to use with pweight)

program define loevh2_svy, rclass byable(recall)

   version 16.0

   local _origframe = c(frame)
   local _origchanged = c(changed)

   syntax varlist(min=2 max=2 numeric) [if] [in] ///
          [, Table Level(cilevel) Compare meta(string asis) _svytest]

   // Tokenize `varlist' into clean `1'/`2' variable-name macros right
   // away, so that the missing-byvar skip-forwarding branch below (which
   // returns r(var1)/r(var2) using `1'/`2' BEFORE the later, pre-existing
   // "tokenize `varlist'" call further down the program) never picks up
   // a stray trailing comma or other leftover token from the raw command
   // line's positional-macro parse. The later tokenize call (kept as-is,
   // for `v1'/`v2') is now redundant but harmless.
   tokenize `varlist'

   // See: https://www.statalist.org/forums/forum/general-stata-discussion/general/152134
   capture which fre
   if ( _rc ) {
      capture window stopbox rusure "This program requires -fre-. Do you want to install -fre-?"
      if ( _rc ) exit 111
      ssc install fre
   }

   if "`compare'"=="compare" & !_by() {

      di as error "option compare requires {help by}"
      exit 498
   }

   // meta() no longer requires -compare- (nor -by-): see loevh2.ado's
   // own changelog note for the full rationale (identical here).

   // Require an active svyset design with at least one of pweight/
   // iweight, cluster(), or strata() actually set -- i.e., a genuine
   // complex-survey design, not merely an "svyset _n" no-op. If none of
   // these three is set, loevh2_svy has nothing to offer beyond loevh2/
   // loevh2_boot (which are faster and better documented for the
   // unweighted/simple-pweight case), so it errors out and points the
   // user there instead.
   //
   // The svyset design's own descriptive fields (weight type/expression,
   // cluster/strata variable names) are captured here too, right after
   // the design is confirmed active, for later use (regardless of
   // -compare-) as purely informational string columns whenever meta()
   // is specified -- see loevh2_meta_save.ado's header for the full
   // rationale on why the raw data/design itself is never replayed.
   local _svy_wexp ""
   local _svy_fpc ""
   if "`_svytest'" == "" {
      capture svyset
      if _rc {
         di as error "no svyset design is active -- loevh2_svy requires " ///
                     "{help svyset} with pweight, cluster(), and/or " ///
                     "strata() to be set first. For unweighted data, " ///
                     "or pweight without clustering/stratification, " ///
                     "use {help loevh2} or {help loevh2_boot} instead."
         exit 119
      }
      local _svy_wtype "`r(wtype)'"
      local _svy_wexp "`r(wexp)'"
      local _svy_clust "`r(su1)'"
      local _svy_strata "`r(strata1)'"
      local _svy_fpc "`r(fpc1)'"
      local _svy_has_pw = inlist("`_svy_wtype'", "pweight", "iweight")
      local _svy_has_cl = ("`_svy_clust'" != "")
      local _svy_has_st = ("`_svy_strata'" != "")
      if !`_svy_has_pw' & !`_svy_has_cl' & !`_svy_has_st' {
         di as error "the active svyset design has no pweight/iweight, " ///
                     "no cluster(), and no strata() -- loevh2_svy " ///
                     "requires at least one of these to be genuinely " ///
                     "set. For unweighted, non-clustered, non-" ///
                     "stratified data, use {help loevh2} or " ///
                     "{help loevh2_boot} instead."
         exit 119
      }
   }

   marksample touse

   // Build a second sample marker, `tousegrp', that reflects only the
   // -in- restriction (if any), but NOT the user's -if- condition,
   // exactly as loevh2/loevh2_boot do, so a by-group's missing by-value
   // can be detected independent of any -if- that might otherwise zero
   // out `touse' for an entire missing-value by-group.
   tempvar tousegrp
   mark `tousegrp' `in'
   markout `tousegrp'

   if _by() {
      local _byvars_miss = 0
      foreach _bv of local _byvars {
         qui count if `tousegrp' & missing(`_bv')
         if r(N) > 0 local _byvars_miss = 1
      }
      // Also proactively check whether `touse', though not entirely
      // zero, still leaves ZERO observations with non-missing analysis
      // variables (v1/v2) for this by-group -- exactly mirroring
      // loevh2.ado's own analogous fix (see its changelog/comments for
      // the full rationale). This prevents ever reaching the binary-
      // variable-check/tabulate/matrix logic below with zero usable
      // observations for this by-group.
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

         di as txt _n "Note: by-group with missing value of " ///
                      `"`_byvars'"' " (or no observations selected " ///
                      "by if/in) skipped (H is not estimated for " ///
                      "missing values of the by-variable)."
         return local error "missing_byvar"

         // Retrieve and forward the last VALID by-group's results
         // (r(lastgroup), r(loevh), r(se), r(N), r(overlap), etc.) from
         // the "svyressubsamp" frame, UNCONDITIONALLY (regardless of
         // -compare-) whenever this is the true last by-group of the
         // whole by-sequence -- exactly mirroring loevh2.ado's own
         // equivalent behavior (see its "ressubsamp" frame handling),
         // so that r() is never left populated with only
         // r(error)="missing_byvar" and nothing else just because the
         // by-sequence happens to end on a missing/excluded group. The
         // "svyressubsamp" frame itself is now created/posted for every
         // valid by-group regardless of -compare- (see the main-flow
         // posting block further below), so it is always available
         // here to retrieve from, whether or not -compare- was
         // requested. Only the loevh2_svy_compare() call and its
         // compare-specific returns (Hbar, chi2, df, p_chi2, H_SE_N)
         // remain conditional on -compare-.
         //
         // NOTE: meta() is deliberately NOT triggered in this skip-
         // forwarding branch, even though the forwarded results
         // originate from the last VALID group -- that valid group
         // already triggered its own meta() save when IT was
         // processed, so saving again here would create a duplicate
         // row in the meta() output file.
         if _bylastcall() {
            capture confirm frame svyressubsamp
            if _rc==0 {
               if "`compare'"=="compare" {
                  di _n _n as txt "Categories of by: variable(s):"
                  fre `_byvars' `if' `in'
               }
               frame change svyressubsamp
               lab val sample sample
               local _last_n = _N
               if `_last_n' > 0 {
                  local _lg_h    = h[`_last_n']
                  local _lg_se   = se[`_last_n']
                  local _lg_N    = n[`_last_n']
                  local _lg_sval = sample[`_last_n']
                  local _lg_lab : label (sample) `_lg_sval'
                  local _lg_ov     = ov[`_last_n']
                  local _lg_ov_se  = ov_se[`_last_n']
                  local _lg_ov_lb  = ov_lb[`_last_n']
                  local _lg_ov_ub  = ov_ub[`_last_n']
                  local _lg_sample = sample[`_last_n']

               }
               if "`compare'"=="compare" {
                  loevh2_svy_compare
                  local pchi2 = `loevh2_pchi2'
                  local df = `loevh2_df'
                  local chi2 = `loevh2_chi2'
                  local Hbar = `loevh2_Hbar'
                  local Hbar_se = `loevh2_Hbar_se'
                  local Hbar_N = `loevh2_Hbar_N'
                  local HSEN = "`loevh2_HSEN'"

                  if `"`meta'"' != `""' & "`HSEN'"!="" {
                     local HSENLAB = `"`loevh2_HSEN_labels'"'
                     loevh2_meta_save, metaspec(`meta') ///
                        source(loevh2_svy) suffix("_svy") ///
                        setype("svy, nlcom (delta method)") ///
                        hsen(`HSEN') labels(`"`HSENLAB'"') ///
                        svywtype(`"`_svy_wtype'"') svywexp(`"`_svy_wexp'"') ///
                        svycluster(`"`_svy_clust'"') svystrata(`"`_svy_strata'"') ///
                        svyfpc(`"`_svy_fpc'"') ///
                        origframe(`"`_origframe'"') origchanged(`_origchanged')
                  }
               }
               frame change `_origframe'
               frame drop svyressubsamp

                if `_last_n' > 0 {
                   tempname _crit
                   scalar `_crit' = abs(invnormal(`=(1-`level'/100)/2'))
                   return scalar loevh = `_lg_h'
                   return scalar se = `_lg_se'
                   return scalar lb = `_lg_h' - scalar(`_crit')*`_lg_se'
                   return scalar ub = `_lg_h' + scalar(`_crit')*`_lg_se'
                   return scalar level = `level'
                   return scalar N = `_lg_N'
                   return scalar overlap = `_lg_ov'
                   return scalar se_overlap = `_lg_ov_se'
                   return scalar lb_overlap = `_lg_ov_lb'
                   return scalar ub_overlap = `_lg_ov_ub'
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
                   return local se_type "svy, nlcom (delta method)"
                   return local group "`_byvars'"
                   return local lastgroup "`_lg_lab'"
                }
            }
         }
         exit
      }
   }

   tempname crit
   scalar `crit' = abs(invnormal(`=(1-`level'/100)/2'))

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

   tokenize `varlist'
   local v1 "`1'"
   local v2 "`2'"

   // Structural pre-check for a degenerate (or non-2x2) table, using a
   // plain, non-svy tabulate purely as a diagnostic -- never used for
   // the actual H/SE computation, which always comes from svy: mean +
   // nlcom below. This mirrors loevh2's own degenerate-table guard
   // exactly (any cell or margin equal to zero makes H undefined).
   //
   // CRITICAL: _T is a fixed (non-tempname) matrix name, which
   // persists across successive by-group calls (byable(recall) re-runs
   // this whole program once per group) unless explicitly cleared. If
   // this by-group's touse-restricted subsample yields ZERO
   // observations to tabulate, "tabulate ... matcell(_T)" silently
   // returns rc=0 WITHOUT creating or modifying _T at all, leaving it
   // holding the STALE matrix from the previous by-group. Dropping _T
   // first (exactly mirroring loevh2.ado's own analogous fix for its
   // T matrix) ensures a genuine "no observations" case leaves _T
   // undefined, so rowsof(_T)/colsof(_T) below correctly return 0,
   // correctly tripping the `wrongshape' guard instead of silently
   // reusing a stale previous-group table.
   capture matrix drop _T
   qui tabulate `v1' `v2' if `touse', matcell(_T)

   // _T may not exist at all here (rather than merely having the wrong
   // shape) whenever the touse-restricted tabulate above genuinely
   // matched zero observations -- capture matrix drop _T just above
   // guarantees this is a clean "not found" rather than a stale
   // leftover matrix, but rowsof()/colsof() would themselves raise
   // r(111) on a nonexistent matrix, so its existence must be checked
   // explicitly first and treated as an (rowsof=0, colsof=0) wrong-
   // shape case (mirrors loevh2.ado's own analogous fix).
   capture confirm matrix _T
   local _Texists = (_rc==0)
   local wrongshape = !`_Texists' | (rowsof(_T)!=2 | colsof(_T)!=2)
   if `wrongshape' {
      tempname _Ndeg
      scalar `_Ndeg' = 0
      if `_Texists' {
         forvalues _r=1/`=rowsof(_T)' {
            forvalues _c=1/`=colsof(_T)' {
               scalar `_Ndeg' = `_Ndeg' + _T[`_r',`_c']
            }
         }
      }

      di as error "Warning: degenerate 2x2 table (a variable has " ///
                   "only one distinct value in this (sub)sample) " ///
                   "-- H and its SE/CI are undefined; returning " ///
                   "missing values"
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `_Ndeg'
      return local error "degenerate"
      exit
   }
   tempname _a2 _b2 _c2 _d2 _e2 _f2
   scalar `_a2' = _T[2,2]
   scalar `_b2' = max(_T[1,2], _T[2,1])
   scalar `_c2' = min(_T[1,2], _T[2,1])
   scalar `_d2' = _T[1,1]
   scalar `_e2' = `_a2' + `_b2'
   scalar `_f2' = `_a2' + `_c2'
   tempname _Ndeg
   scalar `_Ndeg' = `_a2' + `_b2' + `_c2' + `_d2'
   local degenerate = (`_a2'==0 | `_b2'==0 | `_c2'==0 | `_d2'==0 | ///
                        `_e2'==0 | `_f2'==0 | (`_Ndeg'-`_e2')==0 | ///
                        (`_Ndeg'-`_f2')==0)
   if `degenerate' {
      di as error "Warning: degenerate 2x2 table (a zero cell or " ///
                  "margin) -- H and its SE/CI are undefined; " ///
                  "returning missing values"
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `_Ndeg'
      return local error "degenerate"
      exit
   }

   // Build the four joint-cell-membership indicators for the FULL
   // svyset-declared dataset in memory, so that svy, subpop(): mean can
   // use the full design information (PSUs/strata) while restricting
   // point estimation to the current touse subpopulation. Outside
   // touse==1 (excluded by if/in, or a different by-group, or missing
   // var1/var2 -- marksample already excludes missing values), the
   // indicators are set to 0, following the standard svy subpop()
   // convention (never left missing).
   //
   // NOTE: the branch-selection ("swap") decision itself is NOT made
   // here (see the block AFTER svy: mean below for why -- in short: it
   // must be based on the WEIGHTED margins, not on the unweighted `_T'
   // matrix, which is only ever used above for the structural
   // degenerate-table diagnostic).
   tempvar raw11 raw10 raw01 raw00
   qui gen byte `raw11' = 0
   qui gen byte `raw10' = 0
   qui gen byte `raw01' = 0
   qui gen byte `raw00' = 0
   qui replace `raw11' = 1 if `touse' & `v1'==1 & `v2'==1
   qui replace `raw10' = 1 if `touse' & `v1'==1 & `v2'==0
   qui replace `raw01' = 1 if `touse' & `v1'==0 & `v2'==1
   qui replace `raw00' = 1 if `touse' & `v1'==0 & `v2'==0

   // svy, subpop(): mean on the full design, restricted to the current
   // touse subpopulation -- the statistically correct way to handle
   // if/in/by-group restriction under a complex survey design (naively
   // filtering with "svy: mean ... if ..." can bias variance estimation
   // by silently dropping PSU/strata information; subpop() retains the
   // full design while estimating only for the subpopulation).
   capture qui svy, subpop(`touse'): mean `raw11' `raw10' `raw01' `raw00'

   if _rc {
      di as error "svy: mean failed (rc=" _rc ")"
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `_Ndeg'
      return local error "svy_failed"
      exit
   }

   // Save the design/header e() scalars now, immediately after svy:
   // mean, before nlcom's own "post" (below) replaces e() with the
   // nlcom estimation results -- needed for the cross-tab display's
   // header block.
   tempname _e_Nstrata _e_Npsu _e_N _e_Nsub _e_Npop _e_Nsubpop _e_dfr
   scalar `_e_Nstrata' = e(N_strata)
   scalar `_e_Npsu'    = e(N_psu)
   scalar `_e_N'       = e(N)
   scalar `_e_Nsub'    = e(N_sub)
   scalar `_e_Npop'    = e(N_pop)
   scalar `_e_Nsubpop' = e(N_subpop)
   scalar `_e_dfr'     = e(df_r)

   // Cross-tab cell proportions (x100, as percentages) and their
   // design-based SEs, straight from the svy: mean estimates just
   // computed -- always in the fixed v1 x v2 orientation (never
   // swapped), for the display table and r(overlap)/r(lb_overlap)/
   // r(ub_overlap) below.
   tempname _p11 _p10 _p01 _p00
   tempname _se11 _se10 _se01 _se00
   scalar `_p11'  = _b[`raw11']
   scalar `_p10'  = _b[`raw10']
   scalar `_p01'  = _b[`raw01']
   scalar `_p00'  = _b[`raw00']
   scalar `_se11' = _se[`raw11']
   scalar `_se10' = _se[`raw10']
   scalar `_se01' = _se[`raw01']
   scalar `_se00' = _se[`raw00']

   // Branch-selection ("swap") decision -- WEIGHTED margins.
   //
   // The branch-selection logic must match loevh2's own Mata branch
   // EXACTLY -- and that branch condition is NOT based on comparing the
   // raw off-diagonal cell counts, but on comparing the two MARGINS:
   // loevh2.ado's Mata block branches on colsum(T)[1,2] (= P(var2=1)
   // margin) versus rowsum(T)[2,1] (= P(var1=1) margin):
   //
   //   if colsum(T)[1,2] < rowsum(T)[2,1]     // i.e. p2 < p1
   //       H uses T[1,2] (var1=0,var2=1) in the numerator
   //   else                                    // i.e. p1 <= p2
   //       H uses T[2,1] (var1=1,var2=0) in the numerator
   //
   // i.e. the numerator ("cell10" role below) is always the off-
   // diagonal cell belonging to the variable with the SMALLER marginal
   // probability of being 1.
   //
   // CRITICAL FIX (version 1.2): this decision MUST be made using the
   // same (WEIGHTED, design-based) margins that H itself is computed
   // from -- i.e. `_b[raw10]'+`_b[raw11]' (weighted p1) versus
   // `_b[raw01]'+`_b[raw11]' (weighted p2), taken from the svy: mean
   // estimates just obtained above -- NOT the unweighted `_T' matrix
   // used earlier purely for the structural degenerate-table
   // diagnostic. An earlier version of this program computed the swap
   // decision from the unweighted `_T' margins before svy: mean was
   // even run. Whenever weighting shifts the ordering of the two
   // marginal probabilities relative to their UNWEIGHTED ordering --
   // which can and does happen whenever the two margins are close to a
   // tie, exactly the boundary condition where the branch choice
   // matters most -- the unweighted-margin-based decision picks the
   // WRONG branch (equivalently, the wrong off-diagonal cell/margin
   // pair) for the weighted nlcom H formula below, silently producing
   // an incorrect H, SE, and CI with no error or warning. This was
   // discovered via the ISRD dataset (test_isrd_bh.do/.log): unweighted
   // margins gave p1margin=304 > p2margin=299 (swap=1), while the
   // WEIGHTED margins gave weighted-p1=.20725 < weighted-p2=.20935
   // (swap=0) -- the two disagree, and using the unweighted decision
   // produced H=.34736 instead of the correct H=.35183 (matching an
   // independent pweight-based bootstrap recomputation and manual
   // verification to 5 decimal places). See
   // verify_h_formula.py/verify_h_formula2.py/verify_h_formula3.py for
   // the full numerical diagnosis.
   local _p1margin_w = `_p10' + `_p11'
   local _p2margin_w = `_p01' + `_p11'
   local _swap = (`_p1margin_w' > `_p2margin_w')
   local branch = cond(`_swap', "pi01", "pi10")

   // nlcom's numerator cell reference (cell10 role): _b[raw10] if
   // p1<=p2 (loevh2's "else" branch), _b[raw01] if p1>p2 (loevh2's
   // "if" branch) -- matching loevh2's own margin-based swap exactly,
   // now correctly computed from the WEIGHTED margins above.
   local _cell10ref = cond(`_swap', "`raw01'", "`raw10'")
   local _cell01ref = cond(`_swap', "`raw10'", "`raw01'")

   // r(overlap): the "both = 1" (v1==1 & v2==1) proportion, i.e. raw11.

   // Point estimate and delta-method SE come directly from the svy:
   // mean estimates already computed above (a direct linear parameter,
   // no nlcom needed for these two). The CI, however, is obtained via
   // nlcom's delta method applied to logit(raw11) and back-transformed
   // with invlogit() -- an asymmetric, boundary-respecting CI, which is
   // the natural and well-behaved choice for a bounded proportion in
   // (0,1) (unlike H itself, which can be negative and for which an
   // earlier Monte Carlo simulation found the analogous logit-CI
   // construction to badly under-cover for small H -- see the removed-
   // `logit'-option note at the top of this file; that finding does
   // NOT apply here, since raw11 is a genuine bounded proportion, the
   // textbook use case for a logit-transformed Wald CI). This nlcom
   // call is done FIRST (before H's own nlcom below), with its results
   // captured into plain scalars immediately, so that H's subsequent
   // nlcom ..., post call (which replaces the currently posted
   // estimation results) does not need to be undone or re-run.
   tempname overlap overlap_se overlap_lb overlap_ub
   scalar `overlap'    = `_p11'
   scalar `overlap_se' = `_se11'

   // NOTE: no `post' here -- nlcom's r(b)/r(V) are populated regardless
   // of `post', and using `post' would replace the currently-posted
   // svy: mean estimation results (the 4 raw-cell coefficients) with a
   // single-coefficient set, breaking the subsequent `_b[raw10]' etc.
   // references in H's own nlcom call below.
   tempname _ov_logit_h _ov_logit_se
   capture qui nlcom (overlap_logit: logit(_b[`raw11']))

   if _rc {
      di as error "nlcom (logit CI for overlap) failed (rc=" _rc ") " ///
                  "-- overlap CI is undefined (this can happen at, " ///
                  "or very near, a boundary cell proportion)"
      scalar `overlap_lb' = .
      scalar `overlap_ub' = .
   }
   else {
      scalar `_ov_logit_h'  = r(b)[1,1]
      scalar `_ov_logit_se' = sqrt(r(V)[1,1])
      scalar `overlap_lb' = invlogit(`_ov_logit_h' - `crit'*`_ov_logit_se')
      scalar `overlap_ub' = invlogit(`_ov_logit_h' + `crit'*`_ov_logit_se')
   }

   tempname h se lb ub N
   scalar `N' = `_Ndeg'

   capture qui nlcom (H: 1 - _b[`_cell10ref']/((_b[`raw11']+_b[`_cell10ref'])* ///
                   (1-(_b[`raw11']+_b[`_cell01ref'])))), post

   if _rc {
      di as error "nlcom failed (rc=" _rc ") -- H/SE/CI are undefined " ///
                  "(this can happen at, or very near, a boundary " ///
                  "cell proportion, which makes the Jacobian " ///
                  "singular)"
      return scalar loevh = .
      return scalar se = .
      return scalar lb = .
      return scalar ub = .
      return scalar N = `N'
      return scalar overlap = `overlap'
      return scalar se_overlap = `overlap_se'
      return scalar lb_overlap = `overlap_lb'
      return scalar ub_overlap = `overlap_ub'
      return local error "nlcom_failed"
      exit
   }
   if _rc==0 {
      scalar `h'  = _b[H]
      scalar `se' = _se[H]
      scalar `lb' = `h' - `crit'*`se'
      scalar `ub' = `h' + `crit'*`se'
   }

   // Display: survey design summary header, then -- ONLY if `table' is
   // specified -- the cross-tab of design-based cell percentages,
   // obtained by simply wrapping Stata's own svy: tabulate (subpop()'d
   // to the current touse restriction). This reproduces svy: tabulate's
   // exact row/column variable name and value-label display, including
   // its automatic word-wrapping of arbitrarily long variable labels,
   // rather than reimplementing that logic by hand. The 4 cell
   // proportions/SEs already extracted above (from the svy: mean call
   // used for H itself) are NOT used for this display -- svy: tabulate
   // computes its own (numerically identical) design-based cell
   // percentages directly -- so the table body and the H/SE/CI results
   // below it remain guaranteed consistent, just via two separate (but
   // equivalent) svy estimations instead of one.
   //
   // Mirrors loevh2's own `table' option (default: no cross-tab shown
   // at all; with `table', the full cross-tab is displayed). When
   // `table' is NOT specified, the design summary header is instead
   // built by hand from the e()-scalars already saved above (off the
   // svy: mean call), since svy: tabulate itself is not run in this
   // case; this keeps the design summary (Number of strata/PSUs/obs/
   // population size/subpop size/design df) always visible regardless
   // of `table'. Full variable names are always used (no abbreviation)
   // in the H results table below, matching svy: tabulate's own
   // unabbreviated variable-name display in the `table' case.
   local v1a "`v1'"
   local v2a "`v2'"
   local cil = string(`level')

   di _n as txt "Survey: Cross tabulation for Loevinger's H"
   if "`table'"=="table" {
      svy, subpop(`touse'): tabulate `v1' `v2', cell percent pearson

      // Overlap line: placed here, between the cross-tab (above) and
      // the H results table (below), in a narrow two-line format
      // (variable names on their own first line, values -- shown as
      // PERCENTAGES, i.e. x100, matching the cross-tab's own cell-
      // percentage scale -- on a second, narrower line).
      di _n as txt "Overlap (" as res "`v1a'" as txt "=1 & " as res "`v2a'" as txt "=1):"
      di as txt "   " as res %7.2f `=scalar(`overlap')*100' ///
         as txt "   Std. err. " as res %5.2f `=scalar(`overlap_se')*100' ///
         as txt "   [" as res "`cil'" as txt "% CI (logit): " ///
         as res %5.2f `=scalar(`overlap_lb')*100' " " %5.2f `=scalar(`overlap_ub')*100' as txt "]"
   }
   else {
      di _n as txt "Number of strata = " as res %8.0fc scalar(`_e_Nstrata') ///
         as txt _col(36) "Number of obs" as txt "   = " as res %12.0gc scalar(`_e_N')
      di as txt "Number of PSUs   = " as res %8.0fc scalar(`_e_Npsu') ///
         as txt _col(36) "Population size" as txt " = " as res %12.0gc scalar(`_e_Npop')
      di as txt _col(36) "Subpop. no. obs" as txt " = " as res %12.0gc scalar(`_e_Nsub')
      di as txt _col(36) "Subpop. size"    as txt "    = " as res %12.0gc scalar(`_e_Nsubpop')
      di as txt _col(36) "Design df"       as txt "       = " as res %12.0gc scalar(`_e_dfr')
   }

   local vars "`v1a' `v2a'"

   local colsv = max(length("`vars'"), 17) + 2
   local inc = `colsv' - 19
   local dig = ceil(log10(max(1,scalar(`N')))) + 2
   local nd = 8 - `dig'
   local spaces = cond(length("`cil'") == 2, "   ", " ")

   tempname z p
   scalar `z' = `h'/`se'
   scalar `p' = 2*(1-normal(abs(`z')))

   di _n in smcl in gr _col(`=58+`inc'+`nd'') /*
   */ "Number of obs = " as res %`dig'.0fc `N' /*
   */ _n _n in smcl in gr _col(`=23 + `inc'') "Loevinger (svy)" /*
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

   // by-group label, for r(lastgroup) and the compare frame
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
            qui levelsof `_bv' if `touse', local(_bv_lvls) clean
            local _bv_lab : word 1 of `_bv_lvls'
         }
         else {
            qui summarize `_bv' if `touse', meanonly
            local _bv_val = r(min)
            local _bv_lab : label (`_bv') `_bv_val'
         }
         local sgroupslab = trim("`sgroupslab' `_bv_lab'")
      }
   }

   // The "svyressubsamp" frame (posting each valid by-group's h, se,
   // n, and overlap statistics, together with its label) is now built
   // for EVERY valid by-group, UNCONDITIONALLY (regardless of
   // -compare-) -- mirroring loevh2.ado's own "ressubsamp" frame
   // handling -- so that the last valid by-group's results can always
   // be retrieved and forwarded to r() (r(lastgroup), r(loevh),
   // r(se), r(N), r(overlap), etc.) even when -compare- is not
   // requested and the by-sequence happens to end on a
   // missing/excluded group (see the missing-byvar branch above). Only
   // the loevh2_svy_compare() call itself, and its compare-specific
   // returns (Hbar, chi2, df, p_chi2, H_SE_N), remain conditional on
   // -compare-.
   if _by() {
      if _byindex()==1 {
         capture frame drop svyressubsamp
      }
      capture confirm frame svyressubsamp
      if _rc {
         frame create svyressubsamp sample h se n ov ov_se ov_lb ov_ub
      }
      local sample = _byindex()
      frame post svyressubsamp (`sample') (`h') (`se') (`N') ///
         (`overlap') (`overlap_se') (`overlap_lb') (`overlap_ub')

      frame svyressubsamp: lab def sample `sample' "`sgroupslab'", modify

       if _bylastcall() {
          if "`compare'"=="compare" {
             di _n _n as txt "Categories of by: variable(s):"
             fre `_byvars' `if' `in'
          }
          frame change svyressubsamp
         lab val sample sample
         if "`compare'"=="compare" {
            loevh2_svy_compare
            local pchi2 = `loevh2_pchi2'
            local df = `loevh2_df'
            local chi2 = `loevh2_chi2'
            local Hbar = `loevh2_Hbar'
            local Hbar_se = `loevh2_Hbar_se'
            local Hbar_N = `loevh2_Hbar_N'
            local HSEN = "`loevh2_HSEN'"

            if `"`meta'"' != `""' & "`HSEN'"!="" {
               local HSENLAB = `"`loevh2_HSEN_labels'"'
               loevh2_meta_save, metaspec(`meta') ///
                  source(loevh2_svy) suffix("_svy") ///
                  setype("svy, nlcom (delta method)") ///
                  hsen(`HSEN') labels(`"`HSENLAB'"') ///
                  svywtype(`"`_svy_wtype'"') svywexp(`"`_svy_wexp'"') ///
                  svycluster(`"`_svy_clust'"') svystrata(`"`_svy_strata'"') ///
                  svyfpc(`"`_svy_fpc'"') ///
                  origframe(`"`_origframe'"') origchanged(`_origchanged')
            }
         }
         frame change `_origframe'
         frame drop svyressubsamp
      }
   }

   // meta() single-row save: fires whenever meta() is specified and we
   // are NOT in the by:+compare pooling branch just above (which, when
   // it fires on the last by-group, already saves ALL rows -- including
   // this group's -- via the HSEN matrix). See loevh2.ado's own
   // equivalent block for the full rationale (identical logic here):
   //   (a) a plain, non-by: call            -> label = "var1_var2"
   //   (b) by: without compare               -> label = sgroupslab,
   //       one row saved per by-group as each is processed
   //   (c) by: + compare, for every by-group EXCEPT the last one.
   if `"`meta'"' != `""' & "`compare'"!="compare" {
      local _metalab = cond(_by(), "`sgroupslab'", "`v1'_`v2'")
      loevh2_meta_save, metaspec(`meta') source(loevh2_svy) ///
         suffix("_svy") setype("svy, nlcom (delta method)") ///
         label(`"`_metalab'"') hval(`=`h'') seval(`=`se'') nval(`=`N'') ///
         svywtype(`"`_svy_wtype'"') svywexp(`"`_svy_wexp'"') ///
         svycluster(`"`_svy_clust'"') svystrata(`"`_svy_strata'"') ///
         svyfpc(`"`_svy_fpc'"') ///
         origframe(`"`_origframe'"') origchanged(`_origchanged')
   }

   // Returns
   return scalar loevh = `h'
   return scalar se = `se'
   return scalar lb = `lb'
   return scalar ub = `ub'
   return scalar level = `level'
   return scalar N = `N'
   return scalar overlap = `overlap'
   return scalar se_overlap = `overlap_se'
   return scalar lb_overlap = `overlap_lb'
   return scalar ub_overlap = `overlap_ub'
   if _bylastcall() & "`compare'"=="compare" {
      return scalar Hbar = `Hbar'
      return scalar Hbar_se = `Hbar_se'
      return scalar chi2 = `chi2'
      return scalar df = `df'
      return scalar p_chi2 = `pchi2'
      return scalar Hbar_N = `Hbar_N'
      if "`HSEN'" != "" return matrix H_SE_N = `HSEN'
   }
   return local var1 "`v1'"
   return local var2 "`v2'"
   return local se_type "svy, nlcom (delta method)"
   if _by() return local group "`_byvars'"
   if _by() return local lastgroup "`sgroupslab'"
end

* ------------------------------------------------------------------------------
program define loevh2_svy_compare

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
      mata: loevh2_svy_hs = st_data(., ("h", "se"), "`ok'")
      mata: st_numscalar("`wsum'",   sum(1 :/ loevh2_svy_hs[.,2]:^2))
      mata: st_numscalar("`wrsum'",  sum(loevh2_svy_hs[.,1] :/ loevh2_svy_hs[.,2]:^2))
      mata: st_numscalar("`wr2sum'", sum(loevh2_svy_hs[.,1]:^2 :/ loevh2_svy_hs[.,2]:^2))
      mata: mata drop loevh2_svy_hs

      scalar `Hbar' = `wrsum' / `wsum'
      // Pooled (inverse-variance-weighted meta-analysis) SE of the
      // weighted average H -- SE(Hbar) = sqrt(1 / sum(1/se_i^2)) --
      // plus the total N summed across all valid sub-samples, both
      // shown alongside Hbar on the "Weighted average H" summary line
      // below.
      scalar `Hbar_se' = sqrt(1/`wsum')
      qui summarize n if `ok', meanonly
      scalar `Hbar_N' = r(sum)
      scalar `chi2' = `wr2sum' - (`wrsum')^2 / `wsum'
      scalar `df'   = `k' - 1
      scalar `pchi2' = chi2tail(`df', `chi2')

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

      capture matrix drop __loevh2_svy_HSEN
      matrix __loevh2_svy_HSEN = J(`N', 3, .)
      local HSEN "__loevh2_svy_HSEN"
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
         // Row names are simple, guaranteed-short, collision-free
         // "group N" identifiers (N = this row's position, 1-based) --
         // NOT sanitized copies of the descriptive sub-sample label
         // (see loevh2.ado's loevh2_compare for the full rationale).
         // The full, untruncated label is carried forward separately
         // via `HSEN_labels_full' for loevh2_meta_save's numeric,
         // value-labelled `study' variable.
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
      c_local loevh2_HSEN ""
      c_local loevh2_HSEN_labels ""
   }
   c_local loevh2_chi2  = `chi2'
   c_local loevh2_df    = `df'
   c_local loevh2_pchi2 = `pchi2'
   c_local loevh2_Hbar  = `Hbar'
   c_local loevh2_Hbar_se = `Hbar_se'
   c_local loevh2_Hbar_N  = `Hbar_N'
end
