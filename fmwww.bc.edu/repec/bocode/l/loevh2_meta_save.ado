*! Version 1.0, Dirk Enzmann (20-Aug-2026)
*!
*! Shared subroutine used by loevh2_compare, loevh2_boot_compare, and
*! loevh2_svy_compare to implement the meta() option (see loevh2).

program define loevh2_meta_save

   version 16.0
   syntax , metaspec(string) source(string) setype(string) ///
      [ hsen(string) labels(string) label(string) hval(real -999999999) ///
        seval(real -999999999) nval(real -999999999) ///
        svywtype(string) svywexp(string) svycluster(string) ///
        svystrata(string) svyfpc(string) suffix(string) ///
        origframe(string) origchanged(integer -1) ]

   // Exactly one of the two calling conventions (hsen() vs. the
   // label()/hval()/seval()/nval() quartet) must be used.
   local _have_hsen = ("`hsen'" != "")
   local _have_single = ("`label'" != "" | `hval' != -999999999 | ///
                          `seval' != -999999999 | `nval' != -999999999)
   if `_have_hsen' & `_have_single' {
      di as error "loevh2_meta_save: specify either hsen() or " ///
                   "label()/hval()/seval()/nval(), not both"
      exit 198
   }
   if !`_have_hsen' & !`_have_single' {
      di as error "loevh2_meta_save: must specify either hsen() or " ///
                   "label()/hval()/seval()/nval()"
      exit 198
   }
   if `_have_single' & ("`label'" == "" | `hval' == -999999999 | ///
                         `seval' == -999999999 | `nval' == -999999999) {
      di as error "loevh2_meta_save: label(), hval(), seval(), and " ///
                   "nval() must all be supplied together"
      exit 198
   }

   // Single-row (no-compare) case: build a small one-row matrix with
   // the same shape/rowname convention as a caller-supplied hsen(),
   // then fall through to exactly the same code path below.
   //
   // Matrix rownames must be valid Stata names (letters, digits,
   // underscores only, <=32 chars) -- so the caller's `label()' text
   // is sanitized (special characters replaced with "_") ONLY for use
   // as the matrix rowname `_rowlab'. The ORIGINAL, unsanitized label
   // text is separately preserved in `_singlelab' and is what actually
   // gets stored in the saved .dta's "label" column below (see the
   // forvalues loop), so a descriptive label such as "West &
   // Farrington (1973) [1]" is NOT mangled into
   // "West___Farrington__1973___1_" merely because the single-row
   // calling convention needs a valid matrix rowname internally.
   local _singlelab ""
   if `_have_single' {
      tempname _single_hsen
      matrix `_single_hsen' = J(1, 3, .)
      matrix `_single_hsen'[1,1] = `hval'
      matrix `_single_hsen'[1,2] = `seval'
      matrix `_single_hsen'[1,3] = `nval'
      matrix colnames `_single_hsen' = H SE N
      local _rowlab = substr(ustrregexra(`"`label'"', "[^A-Za-z0-9_]", "_"), 1, 32)
      if "`_rowlab'" == "" local _rowlab = "_"
      matrix rownames `_single_hsen' = `_rowlab'
      local hsen "`_single_hsen'"
      local _singlelab `"`label'"'
   }

   // ---- Parse metaspec into filename + replace|append ----------------
   // metaspec is expected to be "filename, replace" or "filename, append"
   // (whitespace around the comma is tolerated). No default mode is
   // assumed: if the mode is missing or is anything other than exactly
   // "replace" or "append", loevh2_meta_save aborts with a clear error,
   // per the design decision that the user must always explicitly
   // choose between overwriting and appending.
   gettoken _mf _mm : metaspec, parse(",")
   local _mf = trim("`_mf'")
   local _mm = trim(subinstr("`_mm'", ",", "", 1))
   local _mm = lower("`_mm'")

   if "`_mf'" == "" {
      di as error "meta(): a filename is required, e.g. meta(myfile, replace)"
      exit 198
   }
   if "`_mm'" != "replace" & "`_mm'" != "append" {
      di as error "meta(): a mode of exactly replace or append " ///
                   "is required, e.g. meta(myfile, replace) or " ///
                   "meta(myfile, append)"
      exit 198
   }

   // Strip a trailing .dta extension (case-insensitive) from the user-
   // supplied filename, if present, so that both the .dta and .do
   // outputs share exactly the same base name regardless of whether the
   // user wrote meta(results) or meta(results.dta).
   local _base = "`_mf'"
   local _extpos = strlen("`_base'") - 4
   if `_extpos' > 0 {
      local _ext4 = lower(substr("`_base'", `_extpos'+1, 4))
      if "`_ext4'" == ".dta" local _base = substr("`_base'", 1, `_extpos')
   }

   // Append the caller-supplied suffix (may be empty, e.g. for plain
   // loevh2 calls) to the base name -- see the file header note above.
   local _base "`_base'`suffix'"

   local _dta "`_base'.dta"
   local _do  "`_base'.do"

   // Safety guard: the companion .do file at `_do' is always fully
   // (re)written from scratch by loevh2_meta_writedo (see that .ado's
   // own header for why it is unconditionally regenerated on every
   // call). If the user's meta() filename happens to coincide with an
   // unrelated, pre-existing .do file (e.g., a currently open/important
   // script of their own -- not one loevh2_meta_save itself wrote
   // earlier), silently overwriting it would be destructive. Guard
   // against this by refusing to proceed -- BEFORE any .dta is written
   // or appended to, in either mode -- unless `_do' does not yet exist,
   // or its very first line already carries loevh2_meta_writedo's own
   // "Auto-generated by loevh2_meta_save" marker comment.
   capture confirm file "`_do'"
   if _rc == 0 {
      tempname _doguard
      local _do_firstline ""
      capture noisily file open `_doguard' using "`_do'", read text
      if _rc == 0 {
         file read `_doguard' _do_firstline
         file close `_doguard'
      }
      if !strpos(`"`_do_firstline'"', "Auto-generated by loevh2_meta_save") {
         di _n as error "meta(): " as res "`_do' " _n as error ///
            "already exists and does not appear to be a companion file previously written by " _n ///
            "loevh2_meta_save (its first line does not carry the expected " as res `""Auto-generated by "' _n ///
            `"by loevh2_meta_save" "' as error "marker comment) -- refusing to overwrite it. Choose a " _n ///
            "different meta() filename, or remove/rename " _n ///
            as res "`_do' " as error "and/or " _n as res ///
            "`_dta' " _n as error ///
            "yourself first if you are certain it is safe to replace." as txt
         exit 602
      }
   }

   if "`_mm'" == "append" {
      capture confirm file "`_dta'"
      if _rc {
         di _n as error "meta(): append requested but" _n as res ///
            "`_dta '" _n as error ///
            "does not exist -- use " as res "meta(`_mf', replace) " ///
            as error "first." as txt
         exit 601
      }
   }

   // ---- append-mode only: peek at the MAXIMUM run_id already present
   // in the existing `_dta', so that the new run_id computed below
   // (whole-second clock resolution) can be nudged to be strictly
   // greater than it whenever both calls happen to land in the same
   // wall-clock second (e.g. two "loevh2 ..., compare meta()" calls --
   // the first with replace, the second with append -- executed back
   // to back). Without this, two such calls produce byte-for-byte
   // IDENTICAL run_id values (clock() truncates to whole seconds), so
   // rows contributed by genuinely different runs become
   // indistinguishable in the saved .dta (they'd wrongly appear as a
   // SINGLE run to -meta- / any later analysis keyed on run_id).
   //
   // On "replace" (a fresh, logically independent file/history), no
   // such check is made -- see the design note directly below where
   // `_now' is computed.
   tempname _prev_runid
   scalar `_prev_runid' = .
   if "`_mm'" == "append" {
      tempname _peekframe
      frame create `_peekframe'
      frame `_peekframe' {
         quietly use "`_dta'", clear
         capture confirm numeric variable run_id
         if _rc == 0 {
            quietly summarize run_id, meanonly
            if r(N) > 0 scalar `_prev_runid' = r(max)
         }
      }
      frame drop `_peekframe'
   }


   // ---- Build the rows to add, from the (caller-supplied or just-
   // built single-row) H_SE_N matrix -------------------------------
   // `hsen' is a k x 3 matrix (columns H, SE, N) with sanitized row
   // names (sub-sample labels), exactly as built by loevh2_compare /
   // loevh2_boot_compare / loevh2_svy_compare (or the single-row block
   // above). Only rows with non-missing H and SE are written (matching
   // the on-screen -compare- table, which already excludes degenerate
   // sub-samples).
   local _k = rowsof(`hsen')
   local _rn : rowfullnames `hsen'

   // run_id: a single timestamp (to the second), shared by every row
   // added in THIS call, so that rows contributed by different
   // loevh2/loevh2_boot/loevh2_svy invocations (even to the same file)
   // can be distinguished from one another later.
   local _now = clock(c(current_date) + " " + c(current_time), "DMYhms")

   // Append-mode tie-breaker: if this call's whole-second run_id would
   // not be strictly greater than the MAXIMUM run_id already present
   // in the existing `_dta' (peeked above, into `_prev_runid'), nudge
   // `_now' up by a tiny sub-second fractional increment (0.001 %tc
   // units = 1 millisecond) so the two runs remain distinguishable by
   // run_id -- e.g. for -meta-'s own subgroup()/by-run analyses, or any
   // later "list run_id ..." / "bysort run_id:" style inspection of the
   // saved .dta. Since %tc's default display format rounds/shows only
   // whole seconds, both runs still visually DISPLAY as the identical
   // second (as one would expect/want), even though their underlying
   // stored numeric values now differ. Only relevant on "append" --
   // see the note above `_prev_runid' for why "replace" is exempt.
   if "`_mm'" == "append" & !missing(scalar(`_prev_runid')) {
      if `_now' <= scalar(`_prev_runid') {
         local _now = scalar(`_prev_runid') + 0.001
      }
   }


   tempname _addframe
   frame create `_addframe' ///
      double(run_id H SE N) ///
      str32 label str32 source str40 se_type ///
      str40 svy_wtype str80 svy_wexp str32 svy_cluster ///
      str32 svy_strata str32 svy_fpc

   // Pre-split the caller-supplied labels() string (one compound-
   // quoted label per hsen() row, e.g.
   // `" "West & Farrington (1973) [1]"' "Farrington (1979) [1]"' ... "')
   // into positional locals 1, 2, 3, ... via -tokenize-, done ONCE
   // here, before the forvalues loop below. This is NOT equivalent to
   // the (broken) alternative of using `: word `_i' of `labels'' inside
   // the loop: by the time `labels' reaches this point (having been
   // passed through syntax's string(asis) option handling), its
   // embedded `"..."' sequences are literal quote/backtick CHARACTERS
   // stored inside the macro's text, not live nested compound quotes.
   // `: word of` (an extended macro function) splits purely on
   // whitespace and does NOT re-interpret literal embedded quote
   // characters as quoting, so a multi-word label such as "West &
   // Farrington (1973) [1]" was being split into several separate
   // "words" at each internal space -- with sometimes bizarre
   // downstream consequences (e.g. an isolated word like "Farrington"
   // later being treated as a variable/command name, triggering
   // "Farrington not found"). By contrast, -tokenize-, when handed
   // `"`labels'"' (i.e. re-wrapped in ITS OWN fresh pair of compound
   // double quotes), has that whole expression evaluated by Stata's
   // parser at expansion time, which DOES correctly re-interpret the
   // embedded `"..."' sequences as live nested compound quotes -- so
   // each label, however many internal words/special characters it
   // contains, is correctly delivered as its own single positional
   // token (1, 2, 3, ...), matching hsen() row order.
   if `"`labels'"' != "" {
      tokenize `"`labels'"'
   }


   local _added = 0
   frame `_addframe' {
      forvalues _i = 1/`_k' {
         local _hv = `hsen'[`_i',1]
         local _sv = `hsen'[`_i',2]
         local _nv = `hsen'[`_i',3]
         if missing(`_hv') | missing(`_sv') continue
         local ++_added
         qui set obs `_added'
         // Prefer the caller-supplied full descriptive label (from
         // labels(), one quoted word per hsen() row, in row order) over
         // the hsen matrix's own rowname -- the latter is, as of this
         // version, a short, non-descriptive "group N" placeholder (see
         // loevh2.ado's loevh2_compare header comment for the
         // rationale). For the single-row calling convention (where
         // labels() is never supplied), prefer the ORIGINAL, unsanitized
         // `_singlelab' preserved above over the matrix rowname `_rn'
         // (which is sanitized, since matrix rownames must be valid
         // Stata names) -- so a descriptive label such as "West &
         // Farrington (1973) [1]" is stored in the "label" column
         // exactly as supplied, not mangled into
         // "West___Farrington__1973___1_". The sanitized rowname
         // remains only a final fallback, for the (unexpected) case
         // where `_singlelab' is somehow empty.
         if `"`labels'"' != "" {
            local _lab `"``_i''"'
         }
         else if `"`_singlelab'"' != "" {
            local _lab `"`_singlelab'"'
         }
         else {
            local _lab : word `_i' of `_rn'
         }

         qui replace run_id      = `_now'          in `_added'
         qui replace H           = `_hv'           in `_added'
         qui replace SE          = `_sv'           in `_added'
         qui replace N           = `_nv'           in `_added'
         qui replace label       = "`_lab'"        in `_added'
         qui replace source      = "`source'"      in `_added'
         qui replace se_type     = `"`setype'"'    in `_added'
         qui replace svy_wtype   = `"`svywtype'"'  in `_added'
         qui replace svy_wexp    = `"`svywexp'"'   in `_added'
         qui replace svy_cluster = `"`svycluster'"' in `_added'
         qui replace svy_strata  = `"`svystrata'"' in `_added'
         qui replace svy_fpc     = `"`svyfpc'"'    in `_added'
      }
      format run_id %tc
   }

   if `_added' == 0 {
      di as error "meta(): no valid (non-missing H/SE) sub-samples to " ///
                   "save -- nothing written to `_dta'"
      frame drop `_addframe'
      exit
   }

   di _n
   if "`_mm'" == "replace" {
      frame `_addframe': save "`_dta'", replace
      di as txt _n "meta(): " as res `_added' as txt ///
         " sub-sample row(s) written to " as res "`_dta'"
   }
   else {
      // Append mode: load the existing .dta into its own frame, append
      // the newly-built rows onto it there, then save back to the same
      // file -- all via a save-to-tempfile + "append using" so that no
      // preserve/restore of the CALLER's dataset in the default frame
      // is ever needed.
      tempfile _addfile
      frame `_addframe': save "`_addfile'"

      tempname _master
      frame create `_master'
      frame `_master' {
         quietly use "`_dta'", clear
         quietly append using "`_addfile'"
         quietly save "`_dta'", replace
      }
      frame drop `_master'
      di as txt _n "meta(): " as res `_added' as txt ///
         " sub-sample row(s) appended to " as res "`_dta'"
   }
   frame drop `_addframe'

   // ---- (Re)build a numeric `study' variable + value label from the
   // just-saved .dta's own (string) `label' column, so that Stata's
   // -meta- suite and any user code that prefers a numeric study
   // identifier (e.g. meta forestplot, meta summarize, subgroup(study))
   // has one available alongside the original descriptive string. Value
   // codes are assigned by first appearance, in the order rows CURRENTLY
   // occur in the .dta (i.e. essentially by run_id/insertion order), and
   // are always freshly (re)computed from the CURRENTLY complete file --
   // both on a plain replace() and after an append() -- so that the same
   // descriptive label text is guaranteed to always map to the very same
   // numeric code throughout the file's history, and codes never grow
   // unboundedly across repeated append() calls beyond the number of
   // distinct labels actually present.
   tempname _studyframe
   frame create `_studyframe'
   frame `_studyframe' {
      quietly use "`_dta'", clear
      capture confirm variable study
      if _rc == 0 {
         quietly drop study
      }
      quietly gen long study = .
      local _nextcode = 0
      quietly levelsof label, local(_uniquelabs)
      // levelsof sorts alphabetically, which is fine here: it merely
      // needs to be a fixed, deterministic order so that re-running
      // this block on an unchanged .dta reproduces identical codes.
      foreach _ulab of local _uniquelabs {
         local ++_nextcode
         quietly replace study = `_nextcode' if label == `"`_ulab'"'
         label define _loevh2_study_lbl `_nextcode' `"`_ulab'"', modify
      }
      label values study _loevh2_study_lbl

      // ---- (Re)build a numeric `run' variable + value label from the
      // .dta's own `run_id' column, exactly parallel to `study' above.
      // Each DISTINCT run_id value present in the (now-complete) file
      // gets its own small integer code (1, 2, 3, ... in run_id/
      // insertion order, i.e. chronological order of the original
      // loevh2/loevh2_boot/loevh2_svy ..., compare meta() calls that
      // contributed rows to this file), value-labelled with that run's
      // own human-readable %tc timestamp string. This gives users a
      // short, easy-to-type numeric handle (e.g. "keep if run==2",
      // "drop if run==1", "keep if inlist(run,2,3)") for selecting/
      // combining/excluding specific runs in their OWN later, custom
      // meta-analyses -- without ever having to type out a raw run_id
      // double literal. Always freshly (re)computed from the complete
      // .dta, exactly like `study', so codes stay stable and never grow
      // unboundedly across repeated append() calls.
      capture confirm variable run
      if _rc == 0 {
         quietly drop run
      }
      quietly gen long run = .
      local _nextrun = 0
      quietly levelsof run_id, local(_uniqueruns)
      // levelsof sorts numerically ascending for a numeric variable,
      // i.e. exactly chronological run_id order -- run=1 is always the
      // EARLIEST call that ever contributed rows to this file.
      foreach _urun of local _uniqueruns {
         local ++_nextrun
         local _rundisp : display %tc `_urun'
         local _rundisp = trim(`"`_rundisp'"')
         quietly replace run = `_nextrun' if run_id == `_urun'
         label define _loevh2_run_lbl `_nextrun' `"Run `_nextrun': `_rundisp'"', modify
      }
      label values run _loevh2_run_lbl

      // Format N
      qui sum N, meanonly
      local dig = ceil(log10(max(1,scalar(r(max))))) + 2
      format N %`dig'.0fc

      quietly save "`_dta'", replace
   }
   frame drop `_studyframe'

   // ---- (Re)write the companion .do file ------------------------------
   // Always regenerated fresh (it is small, deterministic, and derived
   // entirely from the .dta's own fixed column layout) -- it is NOT
   // itself append/replace-mode-sensitive: no matter whether THIS call
   // replaced or appended rows, the .do file always simply reflects
   // "pool whatever is currently in <base>.dta", so a freshly rewritten
   // copy is always correct and current. (See loevh2_meta_writedo.ado,
   // a separate helper .ado, for the actual line-by-line writing --
   // kept separate so its generated-code lines can use plain double
   // quotes without any nested-quote escaping.)
   loevh2_meta_writedo "`_dta'" "`_do'" "`origframe'" `origchanged'

end
