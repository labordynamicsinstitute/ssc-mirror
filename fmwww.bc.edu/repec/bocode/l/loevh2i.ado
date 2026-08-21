*! Version 3.3, Dirk Enzmann (20-Aug-2026)
*!
*! Immediate command (analogous to rioci version 1.0.0 by Daniel Klein)
*!
*! Differences to first Version 3.2 [sic!] (13-Jul-2026):
*! - Added a compare option, allowing loevh2i to test the equality of H's
*!   across TWO OR MORE 2x2 tables directly from the command line.
*! - Added the meta(filename, replace|append) option

program define loevh2i, rclass

   version 16.0
   syntax anything(id="integer, or label+table list with compare") ///
      [ , noTAB Table Level(cilevel) Pearson Small Compare meta(string asis) ]

   if ("`tab'"=="notab" & "`table'"=="table") {
      di as error "options notab and table may not be combined"
      exit 198
   }
   if ("`compare'"=="compare" & ("`small'"=="small" | "`pearson'"=="pearson")) {
      di as error "option compare not allowed with small or pearson"
      exit 198
   }
   if (`"`meta'"' != `""' & ("`small'"=="small" | "`pearson'"=="pearson")) {
      di as error "option meta() not allowed with small or pearson"
      exit 198
   }

   if "`compare'" != "compare" {

      // ---- Single-table syntax: loevh2i [label] a b c d ----
      //
      // An OPTIONAL leading study/table label may be supplied before the
      // four cell frequencies (quoted if it contains spaces, e.g.
      // "West Germany", or bare if it is a single word) -- this lets
      // meta() save a meaningful "study" label for a single-table call
      // WITHOUT needing -compare- (which requires 2+ groups). When no
      // label is supplied, behavior is UNCHANGED from all prior versions
      // (a b c d only; meta()'s label then defaults to "rowvar_colvar",
      // exactly as before).
      //
      // Detection follows the same structural logic already used by the
      // -compare- branch below: tokenize the whole `anything' on
      // whitespace/backslash and inspect whether the FIRST token is
      // itself a valid integer. If it is NOT, the first token must be a
      // label (whether quoted or a bare single word -- -syntax-'s own
      // anything() parsing already stripped any quotes and delivered a
      // quoted multi-word label as one atomic token), so it is peeled
      // off before parsing the remaining four numbers; if it IS an
      // integer, no label was supplied and the plain 4-number syntax
      // applies exactly as before.
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
         // simple table is skipped in favor of loevh2's own, more
         // detailed table (passed through below). If notab is
         // specified, no table is shown at all.
         if ("`tab'" != "notab" & "`table'" == "") tabi `a' `b' \ `c' `d', nokey

         if `"`_label'"' != "" {
            // A label was supplied: attach it as a (constant) STRING
            // by-variable and issue the call as a single-group by:,
            // so loevh2's own existing "by: without compare -> label =
            // sgroupslab" logic (see loevh2.ado) picks up this exact
            // text as the meta()-saved row's study label -- reusing
            // loevh2's machinery entirely unchanged, with no need for
            // -compare- (which requires 2+ groups) just to supply a
            // custom label for a SINGLE table.
            quietly gen str32 _label = `"`_label'"'
            bysort _label: loevh2 rowvar colvar [fweight=freq] , level(`level') ///
                                                  `pearson' `small' `table' ///
                                                  meta(`meta')
         }
         else {
            loevh2 rowvar colvar [fweight=freq] , level(`level') ///
                                                  `pearson' `small' `table' ///
                                                  meta(`meta')
         }
         return add

      restore
      exit
   }

   // ---- compare syntax: loevh2i label1 a1 b1 \ c1 d1 | label2 ... ----
   //
   // Split `anything' on "|" into GROUP-SEPARATOR tokens. Stata's own
   // -tokenize-, when given a compound-quoted string like `"`anything'"'
   // to parse, automatically treats any double-quoted substring (e.g.
   // "West Germany") as a single atomic token in its own right (quotes
   // stripped), separate from any adjoining unquoted text -- so a
   // QUOTED multi-word label always arrives as its OWN token, distinct
   // from the "a b \ c d" numbers that follow it (which arrive as one
   // or more SEPARATE, unquoted tokens). An UNQUOTED single-word label,
   // by contrast, is NOT separated from the numbers that follow it on
   // the same "|"-delimited segment -- it stays combined with them in
   // one single token (e.g. "M 874 282 \ 432 421"), needing its own
   // gettoken-based split (on whitespace) to peel the label off. Both
   // shapes are handled below: after splitting the OVERALL token
   // stream on "|", each group's run of tokens (up to the next "|" or
   // end of input) is inspected -- if its very first token, TRIMMED,
   // contains no digits at all, it is treated as an already-isolated
   // (quoted) label token, and the numbers are read from the
   // FOLLOWING token(s); otherwise the first token is a combined
   // "label a b \ c d" string requiring gettoken-based splitting, as
   // in the original (single-table) syntax above.
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

      // Does the first token of this group already look like an
      // ISOLATED label token (i.e., it was quoted -- so -tokenize-
      // stripped the quotes and delivered it as its own separate
      // token, no matter how many words it contains internally, e.g.
      // "West Germany" or "1" -- or is a genuinely bare unquoted
      // single word with nothing glued to it), as opposed to a
      // COMBINED "label a b \ c d" token (an unquoted label with the
      // numbers glued onto it in the same token, e.g. "M 874 282 \
      // 432 421" as ONE token)?
      //
      // Neither a digit-based check (fails on a quoted numeric label
      // like "1") nor an internal-word-count check (fails on a quoted
      // multi-word label like "West Germany", which is one isolated
      // token containing 2 words) is reliable here. The robust,
      // structural signal instead is: does this group have at least
      // one MORE token after tok0 (i.e. `t1' > `t0'), and does THAT
      // next token, whether it is itself a single number or a longer
      // "874 282 \ 432 421"-style run (since -tokenize-, called with
      // parse("|"), only splits on "|" and quote boundaries -- NOT on
      // internal whitespace within an already-unquoted run -- so any
      // unquoted numbers following a quoted label all arrive glued
      // together into ONE token), START with a valid integer as its
      // very first word? If so, tok0 must have been an isolated label
      // token (quoted or a bare single word), because in the
      // COMBINED-token case (unquoted label glued to its numbers) the
      // label and all four numbers are glued into tok0 itself,
      // leaving no separate, purely-numeric-led token immediately
      // following it.
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
         // Remaining tokens (t0+1 .. t1) form the "a b \ c d" numbers,
         // concatenated back into one chunk for gettoken-based parsing
         // below.
         local chunk ""
         local j = `t0' + 1
         while `j' <= `t1' {
            local chunk `"`chunk' ``j''"'
            local ++j
         }
      }
      else {
         // Combined "label a b \ c d" token(s): concatenate all of
         // this group's tokens back into one chunk, then peel the
         // label off its front via gettoken (whitespace-delimited).
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
      // directly into a persistent frame ("loevh2i_groups", created
      // once, before this loop). Uses only ONE preserve/restore cycle in
      // total for the whole -compare- code path (the single one
      // immediately below, wrapping only the final bysort:/loevh2 call),
      // with every group's small table built directly in the
      // "loevh2i_groups" frame.
      if `firstgroup' {
         capture frame drop loevh2i_groups
         // `grporder' records each group's ORIGINAL sequence number
         // (1, 2, 3, ... in the order groups were parsed from the
         // command line, i.e. the value of `g' itself in this foreach
         // loop over `grouplist'), so that sorting/grouping on it
         // (instead of the string label `grp') below preserves
         // original input order in the -compare- output, rather than
         // falling back to -bysort-'s normal ascending-ALPHABETICAL
         // sort of the string label `grp'.
         frame create loevh2i_groups int(rowvar colvar) long freq ///
            str32 grp int grporder
         local firstgroup = 0
      }

      if ("`tab'" != "notab" & "`table'" == "") {
         di _n as txt "Group: " as res `"`label'"'
         tabi `ga' `gb' \ `gc' `gd', nokey
      }

      frame loevh2i_groups {
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

   quietly frame loevh2i_groups {
      label variable rowvar "rowvar"
      label variable colvar "colvar"
      label variable grp "group"
      label variable grporder "original group order"
      save `"`allgroups'"', replace
   }
   frame drop loevh2i_groups

      quietly use `"`allgroups'"', clear

      // Sort/group on the numeric `grporder' (original command-line
      // sequence number) rather than the string label `grp', so the
      // -compare- output below (built by loevh2's by-group logic,
      // which always processes by-groups in ascending sort order of
      // the by-variable) preserves the ORIGINAL input order of the
      // groups as entered on the command line, instead of falling
      // back to bysort's normal ascending-ALPHABETICAL sort of the
      // group label. A value label mapping each grporder value to its
      // group's text (taken from `grp') is attached to `grporder', so
      // loevh2's by-group logic (which looks up the by-variable's
      // value label to build each sub-sample's display name) still
      // reports the correct group text, not a bare integer.
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

      bysort grporder: loevh2 rowvar colvar [fweight=freq], level(`level') ///
         `table' compare meta(`meta')
      return add
   restore

end
exit
