*! Version 3.3, Dirk Enzmann (20-Aug-2026)
*!
*! Immediate command (amalogous to rioci version 1.0.0 by Daniel Klein)
*!
*! Differences to first [sic!] Version 3.2 (13-Jul-2026):
*! - Added a compare option, allowing loevh2_booti to test the equality of
*!   H's across TWO OR MORE 2x2 tables directly from the command line.
*! - Added the meta(filename, replace|append) option

program define loevh2_booti, rclass

   version 16.0
   syntax anything(id="integer, or label+table list with compare") ///
      [ , noTAB Table Reps(integer 1000) Level(real 95) Seed(integer 0) ///
        Progress MAXTries(integer 50) Compare BCcorrect meta(string asis) ]

   if ("`tab'"=="notab" & "`table'"=="table") {
      di as error "options notab and table may not be combined"
      exit 198
   }

   if "`compare'" != "compare" {

      // ---- Single-table syntax: loevh2_booti [label] a b c d ----
      //
      // An OPTIONAL leading study/table label may be supplied before the
      // four cell frequencies (quoted if it contains spaces, e.g.
      // "West Germany", or bare if it is a single word) -- this lets
      // meta() save a meaningful "study" label for a single-table call
      // WITHOUT needing -compare- (which requires 2+ groups). When no
      // label is supplied, behavior is UNCHANGED from all prior versions
      // (a b c d only; meta()'s label then defaults to "rowvar_colvar",
      // exactly as before). See loevh2i.ado's identical block for the
      // full rationale.
      local rest `"`anything'"'
      local _label = ""
      local _tok1 = ""
      local _tok1rest = ""
      gettoken _tok1 _tok1rest : rest, parse(" \")
      capture confirm integer number `_tok1'
      if _rc != 0 {
         local _label = trim(`"`_tok1'"')
         if length(`"`_label'"') > 32 {
            di as error `"label "`_label'" exceeds 32 characters; "' ///
                         "please use a shorter label"
            exit 198
         }
         local rest `"`_tok1rest'"'
      }

      foreach x in a b c d {
         gettoken `x' rest : rest , parse(" \")
      }
      if ("`c'" == "\") {
         local c `d'
         gettoken d rest : rest
      }
      if (`"`rest'"' != "") error 198

      capture confirm integer number `a'
      if _rc {
         di as error "#a must be an integer"
         exit 198
      }
      capture confirm integer number `b'
      if _rc {
         di as error "#b must be an integer"
         exit 198
      }
      capture confirm integer number `c'
      if _rc {
         di as error "#c must be an integer"
         exit 198
      }
      capture confirm integer number `d'
      if _rc {
         di as error "#d must be an integer"
         exit 198
      }
      if (`a'<0 | `b'<0 | `c'<0 | `d'<0) {
         di as error "cell frequencies must be nonnegative"
         exit 198
      }

      preserve

         quietly {
            drop _all
            tabi `a' `b' \ `c' `d' , replace
            rename row rowvar
            rename col colvar
            replace rowvar = rowvar - 1
            replace colvar = colvar - 1
            rename pop freq
            label variable rowvar "rowvar"
            label variable colvar "colvar"
         }

         // Default (neither notab nor table specified): show the simple
         // frequency-only cross-tabulation. If table is specified, this
         // simple table is skipped in favor of loevh2's own, more detailed
         // table (passed through below, via loevh2_boot). If notab is
         // specified, no table is shown at all.
         if ("`tab'" != "notab" & "`table'" == "") tabi `a' `b' \ `c' `d', nokey

         if `"`_label'"' != "" {
            // A label was supplied: attach it as a (constant) STRING
            // by-variable and issue the call as a single-group by:, so
            // loevh2_boot's own existing "by: without compare -> label =
            // sgroupslab" logic picks up this exact text as the
            // meta()-saved row's study label -- reusing loevh2_boot's
            // machinery entirely unchanged, with no need for -compare-
            // (which requires 2+ groups) just to supply a custom label
            // for a SINGLE table.
            quietly gen str32 _label = `"`_label'"'
            bysort _label: loevh2_boot rowvar colvar [fweight=freq] , ///
               reps(`reps') level(`level') seed(`seed') ///
               maxtries(`maxtries') `progress' `table' `bccorrect' ///
               meta(`meta')
         }
         else {
            loevh2_boot rowvar colvar [fweight=freq] , reps(`reps') level(`level') ///
               seed(`seed') maxtries(`maxtries') `progress' `table' `bccorrect' ///
               meta(`meta')
         }
         return add

      restore
      exit
   }

   // ---- compare syntax: loevh2_booti label1 a1 b1 \ c1 d1 | label2 ... ----
   //
   // See loevh2i.ado's own equivalent block for the full rationale of
   // this token-shape-aware parsing (quoted multi-word labels arrive as
   // their own separate -tokenize- token; unquoted single-word labels
   // stay combined with their group's numbers in one token).
   tokenize `"`anything'"', parse("|")
   local ngroups = 0
   local k = 1
   local grouplist ""
   local groupstart ""
   local prevsep = 1
   while `"``k''"' != "" {
      if `"``k''"' == "|" {
         local prevsep = 1
      }
      else {
         if `prevsep' {
            local ++ngroups
            local grouplist `"`grouplist' `ngroups'"'
            local groupstart`ngroups' = `k'
         }
         local groupend`ngroups' = `k'
         local prevsep = 0
      }
      local ++k
   }
   if `ngroups' < 2 {
      di as error "option compare requires at least 2 groups " ///
                   `"(separated by "|")"'
      exit 198
   }

   tempfile allgroups
   local firstgroup = 1

   preserve

   foreach g of local grouplist {
      local t0 = `groupstart`g''
      local t1 = `groupend`g''

      // Does this group have at least one MORE token after tok0, and does
      // THAT next token (which -tokenize-, called with parse("|"), delivers
      // as ONE glued-together run of all remaining unquoted text, e.g.
      // "874 282 \ 432 421", since it only splits on "|" and quote
      // boundaries, not on internal whitespace) START with a valid
      // integer as its very first word? If so, tok0 must have been an
      // isolated label token, because in the combined-token case the
      // label and all four numbers are glued into tok0 itself,
      // leaving no separate, purely-numeric-led token immediately
      // following.
      local tok0 `"``t0''"'
      local haslabeltoken = 0
      if (`t1' > `t0') {
         local tok1 `"``=`t0'+1''"'
         local tok1firstword ""
         local tok1rest ""
         gettoken tok1firstword tok1rest : tok1, parse(" ")
         capture confirm integer number `tok1firstword'
         if _rc == 0 local haslabeltoken = 1
      }

      if `haslabeltoken' {

         local label = trim(`"`tok0'"')
         local chunk ""
         local j = `t0' + 1
         while `j' <= `t1' {
            local chunk `"`chunk' ``j''"'
            local ++j
         }
      }
      else {
         local chunk ""
         local j = `t0'
         while `j' <= `t1' {
            local chunk `"`chunk' ``j''"'
            local ++j
         }
         local chunk = trim(`"`chunk'"')
         gettoken label chunk : chunk, parse(" ")
      }

      local label = trim(`"`label'"')
      if length(`"`label'"') > 32 {
         di as error `"group label "`label'" exceeds 32 characters; "' ///
                      "please use a shorter label"
         exit 198
      }
      if `"`label'"' == "" {
         di as error "each group must have a (non-empty) label"
         exit 198
      }

      // Remaining tokens: a b [\] c d
      local chunk = trim(`"`chunk'"')
      gettoken ga chunk : chunk, parse(" \")
      gettoken gb chunk : chunk, parse(" \")
      if trim(`"`gb'"') == "\" {
         di as error `"malformed table for group "`label'""'
         exit 198
      }
      gettoken gc chunk : chunk, parse(" \")
      if trim(`"`gc'"') == "\" {
         gettoken gc chunk : chunk, parse(" \")
      }
      gettoken gd chunk : chunk, parse(" \")
      if trim(`"`chunk'"') != "" {
         di as error `"unexpected extra tokens for group "`label'": `chunk'"'
         exit 198
      }

      foreach x in ga gb gc gd {
         capture confirm integer number ``x''
         if _rc {
            di as error `"in group "`label'", each cell frequency must be an integer"'
            exit 198
         }
         if ``x'' < 0 {
            di as error `"in group "`label'", cell frequencies must be nonnegative"'
            exit 198
         }
      }

      // Accumulate this group's 4-row rowvar/colvar/freq/grp block
      // directly into a persistent frame ("loevh2_booti_groups",
      // created once, before this loop) instead of the historical
      // "preserve / tabi/rename / save `thisgroup`g'' / restore"
      // per-group pattern. Rationale: a SEPARATE preserve/
      // save-to-tempfile/restore cycle for EVERY group, followed by a
      // further "use/append/save allgroups" step and then a THIRD
      // (outer) preserve/use/bysort:/restore cycle, was found to
      // silently corrupt Stata's *own* preserve/restore mechanism --
      // from the third such cycle onward (i.e., as soon as >=2 prior
      // preserve-with-save-to-tempfile cycles have already run earlier
      // in the SAME program execution), a subsequent
      // "preserve / use <file>, clear / bysort byvar: <byable(recall)
      // program using frame create/post/drop at _bylastcall()> /
      // restore" sequence's final -restore- silently fails to bring
      // back the ORIGINAL (caller's) dataset (loevh2_boot's own
      // -compare- branch does exactly such frame create/post/drop at
      // _bylastcall(), so it triggers this). Use only ONE preserve/restore
      // cycle in total for the whole -compare- code path (the single
      // one immediately below, wrapping only the final
      // bysort:/loevh2_boot call), with every group's small table built
      // directly in the "loevh2_booti_groups" frame.
      if `firstgroup' {
         capture frame drop loevh2_booti_groups
         // `grporder' records each group's ORIGINAL sequence number
         // (1, 2, 3, ... in the order groups were parsed from the
         // command line, i.e. the value of `g' itself in this foreach
         // loop over `grouplist'), so that sorting/grouping on it
         // (instead of the string label `grp') below preserves
         // original input order in the -compare- output, rather than
         // falling back to -bysort-'s normal ascending-ALPHABETICAL
         // sort of the string label `grp' -- mirrors loevh2i.ado's own
         // identical fix (see its comments for the full rationale).
         frame create loevh2_booti_groups int(rowvar colvar) long freq ///
            str32 grp int grporder
         local firstgroup = 0
      }

      if ("`tab'" != "notab" & "`table'" == "") {
         di _n as txt "Group: " as res `"`label'"'
         tabi `ga' `gb' \ `gc' `gd', nokey
      }

      frame loevh2_booti_groups {
         local _n0 = _N
         qui set obs `=`_n0'+4'
         qui replace rowvar = 0        in `=`_n0'+1'
         qui replace colvar = 0        in `=`_n0'+1'
         qui replace freq   = `ga'     in `=`_n0'+1'
         qui replace grp    = `"`label'"' in `=`_n0'+1'
         qui replace grporder = `g'    in `=`_n0'+1'
         qui replace rowvar = 0        in `=`_n0'+2'
         qui replace colvar = 1        in `=`_n0'+2'
         qui replace freq   = `gb'     in `=`_n0'+2'
         qui replace grp    = `"`label'"' in `=`_n0'+2'
         qui replace grporder = `g'    in `=`_n0'+2'
         qui replace rowvar = 1        in `=`_n0'+3'
         qui replace colvar = 0        in `=`_n0'+3'
         qui replace freq   = `gc'     in `=`_n0'+3'
         qui replace grp    = `"`label'"' in `=`_n0'+3'
         qui replace grporder = `g'    in `=`_n0'+3'
         qui replace rowvar = 1        in `=`_n0'+4'
         qui replace colvar = 1        in `=`_n0'+4'
         qui replace freq   = `gd'     in `=`_n0'+4'
         qui replace grp    = `"`label'"' in `=`_n0'+4'
         qui replace grporder = `g'    in `=`_n0'+4'
      }
   }

   quietly frame loevh2_booti_groups {
      label variable rowvar "rowvar"
      label variable colvar "colvar"
      label variable grp "group"
      label variable grporder "original group order"
      save `"`allgroups'"', replace
   }
   frame drop loevh2_booti_groups

      quietly use `"`allgroups'"', clear

      // Sort/group on the numeric `grporder' (original command-line
      // sequence number) rather than the string label `grp', so the
      // -compare- output below (built by loevh2_boot's by-group logic,
      // which always processes by-groups in ascending sort order of
      // the by-variable) preserves the ORIGINAL input order of the
      // groups as entered on the command line, instead of falling
      // back to bysort's normal ascending-ALPHABETICAL sort of the
      // group label. A value label mapping each grporder value to its
      // group's text (taken from `grp') is attached to `grporder', so
      // loevh2_boot's by-group logic (which looks up the by-variable's
      // value label to build each sub-sample's display name) still
      // reports the correct group text, not a bare integer -- mirrors
      // loevh2i.ado's own identical fix.
      quietly {
         gen _grplab_tmp = grp
         bysort grporder (_grplab_tmp): gen _first = (_n==1)
         label define grporderlbl 0 "", modify
         local _n_go = _N
         forvalues _r = 1/`_n_go' {
            if _first[`_r'] {
               local _gv  = grporder[`_r']
               local _gl  = _grplab_tmp[`_r']
               label define grporderlbl `_gv' `"`_gl'"', modify
            }
         }
         label values grporder grporderlbl
         drop _grplab_tmp _first
      }

      bysort grporder: loevh2_boot rowvar colvar [fweight=freq], reps(`reps') ///
         level(`level') seed(`seed') maxtries(`maxtries') `progress' ///
         `table' compare `bccorrect' meta(`meta')
      return add
   restore

end
exit
