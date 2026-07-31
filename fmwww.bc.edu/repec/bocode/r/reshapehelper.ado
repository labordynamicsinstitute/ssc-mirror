*! version 1.0.0  20260715  Eric A. Booth, Sr Researcher, Texas 2036
*! reshapehelper: diagnose the data and SUGGEST (never run) the likely reshape
*
*  reshapehelper never reshapes the caller's data.  It scans variable names
*  for wide patterns, hunts for i/j candidates (honoring xtset/tsset and
*  svyset), composes a candidate -reshape- command, and tests it on a small
*  sample inside preserve/restore, iterating on reshape's own errors.  The
*  caller's data are restored untouched; the only side effects are the
*  returned r() results, the $reshapehelper_cmd global, and a viewable SMCL
*  file holding the unwrapped suggestion.

program define reshapehelper, rclass
    version 16.0

    syntax [anything] [, TO(string) I(varlist) J(string) STUBs(string)   ///
        SAMPle(integer 500) NOTESt SMCL(string) REPLACE GLobal(name)     ///
        Detail ]

    * ---- bare-token shorthand: reshapehelper long / reshapehelper wide ------
    local scanvars ""
    if `"`anything'"' != "" {
        local rest `"`anything'"'
        gettoken tk rest : rest
        while "`tk'" != "" {
            capture unab chk : `tk'
            if !_rc local scanvars `scanvars' `chk'
            else if inlist("`tk'", "long", "wide") {
                if "`to'" != "" & "`to'" != "`tk'" {
                    di as err "you typed `tk' but also to(`to'); pick one"
                    exit 198
                }
                local to `tk'
            }
            else {
                di as err "`tk' is neither a variable nor long/wide"
                exit 198
            }
            gettoken tk rest : rest
        }
    }
    if !inlist("`to'", "", "long", "wide") {
        di as err "to() must be long or wide"
        exit 198
    }
    if `sample' < 10 {
        di as err "sample() must be at least 10"
        exit 198
    }
    if "`global'" == "" local global reshapehelper_cmd
    if c(k) == 0 | _N == 0 {
        di as err "no data in memory to diagnose"
        exit 2000
    }
    if `"`smcl'"' != "" {
        if lower(substr(`"`smcl'"', -5, .)) != ".smcl" local smcl `"`smcl'.smcl"'
        if "`replace'" == "" {
            capture confirm new file `"`smcl'"'
            if _rc {
                di as err `"smcl file `smcl' already exists; specify replace"'
                exit 602
            }
        }
    }

    local NFULL = _N
    local KFULL = c(k)

    * =========================================================================
    * 1. Declared structure: xtset/tsset and svyset are the analyst's own
    *    statement of i and j; take them as high-priority candidates.
    * =========================================================================
    local xtpanel ""
    local xttime  ""
    capture quietly xtset
    if _rc == 0 {
        local xtpanel `"`r(panelvar)'"'
        local xttime  `"`r(timevar)'"'
        if `"`xtpanel'"' == "." local xtpanel ""
        if `"`xttime'"'  == "." local xttime  ""
    }
    local svypsu ""
    capture quietly svyset
    if _rc == 0 {
        local svypsu `"`r(su1)'"'
        if `"`svypsu'"' == "." | `"`svypsu'"' == "_n" local svypsu ""
    }

    * =========================================================================
    * 2. Name scans (names only, no data touched).  A varlist restricts which
    *    variables the PATTERN SCAN considers (stub discovery going long, the
    *    measure list going wide); the i/j hunt always sees every variable, so
    *    typing "reshapehelper inc80 inc81" does not hide the id.
    * =========================================================================
    unab allv : _all
    if "`scanvars'" != "" local scanv `scanvars'
    else                  local scanv `allv'

    * ---- 2a. trailing-numeric suffix groups:  inc80 inc81 inc82 -------------
    local nng 0
    foreach v of local scanv {
        if regexm("`v'", "^(.*[^0-9])([0-9]+)$") {
            local s = regexs(1)
            local x = regexs(2)
            local hit 0
            forvalues g = 1/`nng' {
                if "`ng_stub`g''" == "`s'" {
                    local ng_sufs`g' `ng_sufs`g'' `x'
                    local ng_vars`g' `ng_vars`g'' `v'
                    local hit 1
                    continue, break
                }
            }
            if !`hit' {
                local ++nng
                local ng_stub`nng' `s'
                local ng_sufs`nng' `x'
                local ng_vars`nng' `v'
            }
        }
    }
    * keep groups with >= 2 distinct suffixes
    local numgroups ""
    forvalues g = 1/`nng' {
        local u : list uniq ng_sufs`g'
        local nu : word count `u'
        if `nu' >= 2 local numgroups `numgroups' `g'
    }

    * ---- 2b. doubly-wide: two digit runs:  ht_k1_t2 --------------------------
    local ndb 0
    foreach v of local scanv {
        if regexm("`v'", "^(.*[^0-9])([0-9]+)([^0-9]+)([0-9]+)$") {
            local p1 = regexs(1)
            local d1 = regexs(2)
            local md = regexs(3)
            local d2 = regexs(4)
            local hit 0
            forvalues g = 1/`ndb' {
                if "`db_p1`g''" == "`p1'" & "`db_mid`g''" == "`md'" {
                    local db_d1s`g' `db_d1s`g'' `d1'
                    local db_d2s`g' `db_d2s`g'' `d2'
                    local hit 1
                    continue, break
                }
            }
            if !`hit' {
                local ++ndb
                local db_p1`ndb'  `p1'
                local db_mid`ndb' `md'
                local db_d1s`ndb' `d1'
                local db_d2s`ndb' `d2'
            }
        }
    }
    local dblgroups ""
    forvalues g = 1/`ndb' {
        local u1 : list uniq db_d1s`g'
        local u2 : list uniq db_d2s`g'
        if `: word count `u1'' >= 2 & `: word count `u2'' >= 2 {
            local dblgroups `dblgroups' `g'
        }
    }

    * ---- 2c. @ mid-name: digits inside, letters after:  inc80r ---------------
    local nat 0
    foreach v of local scanv {
        if regexm("`v'", "^([a-zA-Z_]+)([0-9]+)([a-zA-Z_]+)$") {
            local pre = regexs(1)
            local dig = regexs(2)
            local suf = regexs(3)
            local hit 0
            forvalues g = 1/`nat' {
                if "`at_pre`g''" == "`pre'" & "`at_suf`g''" == "`suf'" {
                    local at_digs`g' `at_digs`g'' `dig'
                    local hit 1
                    continue, break
                }
            }
            if !`hit' {
                local ++nat
                local at_pre`nat'  `pre'
                local at_suf`nat'  `suf'
                local at_digs`nat' `dig'
            }
        }
    }
    local atgroups ""
    forvalues g = 1/`nat' {
        local u : list uniq at_digs`g'
        if `: word count `u'' >= 2 local atgroups `atgroups' `g'
    }

    * ---- 2d. string suffix after last underscore:  bp_before bp_after --------
    local nsg 0
    foreach v of local scanv {
        if regexm("`v'", "^(.+_)([a-zA-Z][a-zA-Z0-9]*)$") {
            local s = regexs(1)
            local x = regexs(2)
            local hit 0
            forvalues g = 1/`nsg' {
                if "`sg_stub`g''" == "`s'" {
                    local sg_sufs`g' `sg_sufs`g'' `x'
                    local hit 1
                    continue, break
                }
            }
            if !`hit' {
                local ++nsg
                local sg_stub`nsg' `s'
                local sg_sufs`nsg' `x'
            }
        }
    }
    local strgroups ""
    forvalues g = 1/`nsg' {
        local u : list uniq sg_sufs`g'
        if `: word count `u'' >= 2 local strgroups `strgroups' `g'
    }

    * ---- 2e. prefix-as-j: qld_p nsw_p vic_p (the j sits in FRONT) -------------
    *      group by the trailing token; the prefixes are the j values
    local npg 0
    foreach v of local scanv {
        if regexm("`v'", "^([a-zA-Z][a-zA-Z0-9]*)(_[a-zA-Z][a-zA-Z0-9]*)$") {
            local pfx = regexs(1)
            local tail = regexs(2)
            local hit 0
            forvalues g = 1/`npg' {
                if "`pg_tail`g''" == "`tail'" {
                    local pg_pfx`g' `pg_pfx`g'' `pfx'
                    local hit 1
                    continue, break
                }
            }
            if !`hit' {
                local ++npg
                local pg_tail`npg' `tail'
                local pg_pfx`npg' `pfx'
            }
        }
    }
    * conservative: either >=2 tail-groups sharing an identical prefix set, or
    * a single group with >=3 prefixes (first_name/last_name must NOT trigger)
    local pfxgroups ""
    forvalues g = 1/`npg' {
        local u : list uniq pg_pfx`g'
        local nu : word count `u'
        if `nu' >= 3 local pfxgroups `pfxgroups' `g'
        else if `nu' == 2 {
            forvalues h = 1/`npg' {
                if `h' == `g' continue
                local uh : list uniq pg_pfx`h'
                local uh : list sort uh
                local us : list sort u
                local same : list us === uh
                if `same' {
                    local pfxgroups `pfxgroups' `g'
                    continue, break
                }
            }
        }
    }
    local pfxgroups : list uniq pfxgroups

    * a numeric-suffix group beats a string reading of the same variables, and
    * doubly-wide groups subsume their single-run parses; user-supplied
    * stubs() are wide evidence by declaration
    local widejudge = ("`numgroups'`dblgroups'`atgroups'`strgroups'`pfxgroups'" != "") ///
        | ("`stubs'" != "")

    * =========================================================================
    * 3. Value probes on a sample, inside preserve.  BEFORE-snapshot is taken
    *    first, in original row order.  All heavy checks run on the sample.
    * =========================================================================
    preserve
    if _N > `sample' quietly keep in 1/`sample'
    local NS = _N

    * distinct counts for candidate scoring, stored POSITIONALLY (dist1...)
    * and looked up through dvlist with posof: a variable name near Stata's
    * 32-char limit would make a name-keyed local ("dist_<name>") illegal.
    * Skips strL; caps at 80 vars.  A variable absent from dvlist simply has
    * no distinct-count info and drops out of i/j candidacy.
    local dvlist ""
    foreach v of local allv {
        local ty : type `v'
        if "`ty'" == "strL" continue
        if `: word count `dvlist'' >= 80 continue, break
        tempvar f
        quietly bysort `v': gen byte `f' = (_n == 1)
        quietly count if `f'
        local dd = r(N)          // grab r(N) before anything can clear it
        drop `f'
        local dvlist `dvlist' `v'
        local dist`: word count `dvlist'' = `dd'
    }

    * ---- i candidates: unique in sample, or declared, or name-prior ----------
    local icands ""
    if "`i'" != "" local icands `i'
    else {
        if "`xtpanel'" != "" local icands `xtpanel'
        foreach v of local allv {
            local dpos : list posof "`v'" in dvlist
            if `dpos' == 0 continue
            local nm = lower("`v'")
            local prior = regexm("`nm'", "(^|_)(id|code|fips|ssn|key)$|^id|id$|county|state|dist|inst|firm|person|hh|fam|stu|patient")
            if `dist`dpos'' == `NS' local icands `icands' `v'
            else if `prior' local icands `icands' `v'
        }
        if "`svypsu'" != "" local icands `icands' `svypsu'
        local icands : list uniq icands
    }

    * ---- j candidates (for long->wide): low cardinality, time-ish names ------
    local jcands ""
    if "`j'" != "" {
        capture confirm variable `j'
        if !_rc local jcands `j'
    }
    if "`jcands'" == "" {
        if "`xttime'" != "" local jcands `xttime'
        foreach v of local allv {
            local dpos : list posof "`v'" in dvlist
            if `dpos' == 0 continue
            if `dist`dpos'' < 2 continue
            if `dist`dpos'' > min(60, ceil(`NS'/2)) continue
            local nm = lower("`v'")
            if regexm("`nm'", "year|^yr|wave|time|round|visit|period|qtr|quarter|month|week|grade|term|semester|^j$|^t$") {
                local jcands `jcands' `v'
            }
        }
        * fall back: any small-cardinality integer var not already an i cand
        if "`jcands'" == "" {
            foreach v of local allv {
                local dpos : list posof "`v'" in dvlist
                if `dpos' == 0 continue
                if `dist`dpos'' < 2 | `dist`dpos'' > 30 continue
                local isi : list v in icands
                if `isi' continue
                capture confirm numeric variable `v'
                if !_rc {
                    capture assert `v' == int(`v') | missing(`v')
                    if !_rc local jcands `jcands' `v'
                }
                else local jcands `jcands' `v'
            }
        }
        local jcands : list uniq jcands
    }

    * =========================================================================
    * 4. Direction
    * =========================================================================
    local direction ""
    local note ""
    * long evidence: some i+j combo uniquely identifies sample rows.
    * A var that is unique BY ITSELF is skipped as a lone i: in long data the
    * id repeats across j, and widening one-row groups is degenerate.
    * When name-based i candidates fail, fall back to trying other variables,
    * singly and in pairs (this is how a compound i like (animal, arm) or
    * (household, year) gets found without being named id-anything).
    local longi ""
    local longj ""
    * singles pool: named candidates first, then a bounded general fill, so a
    * simple one-variable i is always tried before any pair
    local ipool2 `icands'
    foreach v of local allv {
        if `: word count `ipool2'' >= 12 continue, break
        local in1 : list v in ipool2
        local dpos : list posof "`v'" in dvlist
        if !`in1' & `dpos' > 0 local ipool2 `ipool2' `v'
    }
    local sparsecand ""
    local sparsej ""
    foreach jv of local jcands {
        foreach iv of local ipool2 {
            if "`iv'" == "`jv'" continue
            capture isid `iv' `jv'
            if !_rc {
                * plausibility: in real long data each i repeats across j, so
                * an i with (nearly) one row per value is an accident of the
                * data (auto's weight+mpg), not a design.  Record such a
                * would-be i so the checklist can flag a genuinely sparse panel
                * (most units seen once, a few repeated) rather than stay mute.
                local dpos : list posof "`iv'" in dvlist
                if `dpos' > 0 {
                    if `dist`dpos'' > `NS'/2 {
                        if "`sparsecand'" == "" {
                            local sparsecand `iv'
                            local sparsej `jv'
                        }
                        continue
                    }
                }
                local longi `iv'
                local longj `jv'
                continue, break
            }
        }
        if "`longi'" != "" continue, break
        * pairs: name-based candidates first, then a bounded general pool.
        * A variable that is unique BY ITSELF is barred from pairs: it would
        * make any isid trivially true (the measure would end up inside i).
        local ppool ""
        foreach v of local icands {
            local dpos : list posof "`v'" in dvlist
            if `dpos' == 0 continue
            if `dist`dpos'' < `NS' & "`v'" != "`jv'" local ppool `ppool' `v'
        }
        foreach v of local allv {
            if `: word count `ppool'' >= 6 continue, break
            local in1 : list v in ppool
            if `in1' | "`v'" == "`jv'" continue
            local dpos : list posof "`v'" in dvlist
            if `dpos' == 0 continue
            if `dist`dpos'' < `NS' local ppool `ppool' `v'
        }
        local np : word count `ppool'
        forvalues a = 1/`= min(`np', 6)' {
            forvalues b = `= `a' + 1'/`= min(`np', 6)' {
                local iva : word `a' of `ppool'
                local ivb : word `b' of `ppool'
                capture isid `iva' `ivb' `jv'
                if !_rc {
                    tempvar gg
                    quietly bysort `iva' `ivb': gen byte `gg' = (_n == 1)
                    quietly count if `gg'
                    local ngrp = r(N)
                    drop `gg'
                    if `ngrp' > `NS'/2 continue
                    local longi `iva' `ivb'
                    local longj `jv'
                    continue, break
                }
            }
            if "`longi'" != "" continue, break
        }
        if "`longi'" != "" continue, break
    }
    local longjudge = ("`longi'" != "")

    if "`to'" == "long" {
        if `widejudge' local direction wide2long
        else           local direction none_for_long
    }
    else if "`to'" == "wide" {
        if `longjudge' | "`j'" != ""   local direction long2wide
        else if "`jcands'" != ""       local direction long2wide
        else                           local direction none_for_wide
    }
    else {
        if `widejudge' & "`dblgroups'" != "" local direction doubly
        else if `widejudge'                  local direction wide2long
        else if `longjudge'                  local direction long2wide
        else                                 local direction unknown
    }

    * =========================================================================
    * 5. Compose the candidate command(s)
    * =========================================================================
    local status needinfo
    local cmd ""
    local cmd2 ""
    local preline ""
    local usei ""
    local usej ""
    local usestubs ""
    local tested 0
    local finalrc .
    local resultN .
    local resultK .
    local caution ""
    local diagmsg ""

    * ---------- 5a. WIDE -> LONG ---------------------------------------------
    if "`direction'" == "wide2long" {
        * strongest pattern family: numeric > @ > string suffix > prefix-j
        * (a doubly-wide layout also matches the numeric scan; the single-step
        *  suggestion it yields is the correct FIRST of the two chained steps)
        local family ""
        if "`numgroups'" != ""      local family num
        else if "`atgroups'" != ""  local family at
        else if "`strgroups'" != "" local family str
        else if "`pfxgroups'" != "" local family pfx
        if "`stubs'" != "" local family user

        * stub list + j metadata per family
        local jstring ""
        local sufset ""
        if "`family'" == "num" {
            * merge groups whose suffix sets match, or overlap in >=2 places
            * with one set containing the other (reshape long fills the gaps
            * of an unbalanced stub with missings - manual Example 6)
            local g1 : word 1 of `numgroups'
            local ref : list uniq ng_sufs`g1'
            local ref : list sort ref
            local usestubs "`ng_stub`g1''"
            local stubvars `ng_vars`g1''
            local unbal 0
            foreach g of local numgroups {
                if `g' == `g1' continue
                local u : list uniq ng_sufs`g'
                local u : list sort u
                local same : list ref === u
                local ovl : list ref & u
                local novl : word count `ovl'
                local sub1 : list u in ref
                local sub2 : list ref in u
                if `same' {
                    local usestubs "`usestubs' `ng_stub`g''"
                    local stubvars `stubvars' `ng_vars`g''
                }
                else if `novl' >= 2 & (`sub1' | `sub2') {
                    local usestubs "`usestubs' `ng_stub`g''"
                    local stubvars `stubvars' `ng_vars`g''
                    local unbal 1
                    if `sub2' {
                        local ref : list ref | u
                        local ref : list sort ref
                    }
                }
            }
            local sufset `ref'
            if `unbal' local note "stubs are unbalanced (a stub is missing some suffixes); reshape fills the gaps with missing values"
            * fold in @-groups that share the same suffix set (inc@r beside ue)
            foreach g of local atgroups {
                local u : list uniq at_digs`g'
                local u : list sort u
                local same : list sufset === u
                if `same' {
                    local usestubs "`usestubs' `at_pre`g''@`at_suf`g''"
                    foreach d of local u {
                        local stubvars `stubvars' `at_pre`g''`d'`at_suf`g''
                    }
                }
            }
        }
        else if "`family'" == "at" {
            local g1 : word 1 of `atgroups'
            local usestubs "`at_pre`g1''@`at_suf`g1''"
            local sufset : list uniq at_digs`g1'
            local stubvars ""
            foreach d of local sufset {
                local stubvars `stubvars' `at_pre`g1''`d'`at_suf`g1''
            }
        }
        else if "`family'" == "str" {
            local g1 : word 1 of `strgroups'
            local ref : list uniq sg_sufs`g1'
            local ref : list sort ref
            local usestubs "`sg_stub`g1''"
            foreach g of local strgroups {
                if `g' == `g1' continue
                local u : list uniq sg_sufs`g'
                local u : list sort u
                local same : list ref === u
                if `same' local usestubs "`usestubs' `sg_stub`g''"
            }
            local sufset `ref'
            local jstring " string"
            local stubvars ""
            foreach s of local usestubs {
                foreach x of local sufset {
                    capture confirm variable `s'`x'
                    if !_rc local stubvars `stubvars' `s'`x'
                }
            }
        }
        else if "`family'" == "pfx" {
            * the j values are the PREFIXES; stubs are @tail forms
            local g1 : word 1 of `pfxgroups'
            local usestubs "@`pg_tail`g1''"
            local sufset : list uniq pg_pfx`g1'
            local stubvars ""
            foreach p of local sufset {
                local stubvars `stubvars' `p'`pg_tail`g1''
            }
            foreach g of local pfxgroups {
                if `g' == `g1' continue
                local u : list uniq pg_pfx`g'
                local u : list sort u
                local ref : list sort sufset
                local same : list ref === u
                if `same' {
                    local usestubs "`usestubs' @`pg_tail`g''"
                    foreach p of local u {
                        local stubvars `stubvars' `p'`pg_tail`g''
                    }
                }
            }
            local jstring " string"
        }
        else if "`family'" == "user" {
            local usestubs `stubs'
            local stubvars ""
            foreach s of local stubs {
                local s2 : subinstr local s "@" "*", all
                capture unab got : `s2'*
                if !_rc local stubvars `stubvars' `got'
            }
        }

        * i for wide->long: must uniquely identify rows; exclude stub vars
        local ipool : list icands - stubvars
        if "`xttime'" != "" {
            local intime : list xttime in stubvars
            if !`intime' local ipool `ipool' `xttime'
        }
        local ipool : list uniq ipool
        if "`i'" != "" local usei `i'
        else {
            foreach iv of local ipool {
                capture isid `iv'
                if !_rc {
                    local usei `iv'
                    continue, break
                }
            }
            if "`usei'" == "" {
                local np : word count `ipool'
                forvalues a = 1/`= min(`np', 5)' {
                    forvalues b = `= `a' + 1'/`= min(`np', 5)' {
                        local iva : word `a' of `ipool'
                        local ivb : word `b' of `ipool'
                        capture isid `iva' `ivb'
                        if !_rc {
                            local usei `iva' `ivb'
                            continue, break
                        }
                    }
                    if "`usei'" != "" continue, break
                }
            }
        }
        * wide-long panel note: the row id already includes a time variable
        local nw : word count `usei'
        if `nw' >= 2 {
            foreach iv of local usei {
                if regexm(lower("`iv'"), "year|^yr|wave|time|period|qtr|quarter|month|date") {
                    local note "rows already carry `iv'; this reshape adds a SECOND long dimension"
                }
            }
        }

        * j name: infer, avoid collisions with existing variables
        if "`j'" != "" local usej `j'
        else {
            local usej j
            local all4 1
            local all2 1
            foreach x of local sufset {
                if !regexm("`x'", "^(19|20)[0-9][0-9]$") local all4 0
                if !regexm("`x'", "^[4-9][0-9]$")        local all2 0
            }
            if "`sufset'" == "" {
                local all4 0
                local all2 0
            }
            if (`all4' | `all2') & "`jstring'" == "" local usej year
            else if "`family'" == "pfx"              local usej j
            else if "`jstring'" != ""                local usej period
            foreach cand in `usej' j _j {
                capture confirm variable `cand'
                if _rc {
                    local usej `cand'
                    continue, break
                }
            }
        }
        capture confirm variable `usej'
        if !_rc local usej _j

        * suffix-numbers-may-be-items caution
        if "`jstring'" == "" & "`family'" != "at" {
            local smallsuf 1
            foreach x of local sufset {
                if real("`x'") > 12 local smallsuf 0
            }
            if `smallsuf' & "`sufset'" != "" {
                local caution "suffixes `sufset' could be item numbers rather than repeats over time; confirm these are repeated measures before reshaping"
            }
            * mixed-width suffixes: the manual's inc2-beside-inc80 false match.
            * reshape would happily build a mostly-missing j group; offer the
            * explicit j-value restriction instead of silence
            local lens ""
            foreach x of local sufset {
                local lens `lens' `= strlen("`x'")'
            }
            local lens : list uniq lens
            if `: word count `lens'' >= 2 {
                local caution "suffix widths differ (`sufset'): a stray variable like inc2 beside inc80-inc82 matches the same stub and would create a mostly-missing j group; if any suffix is a false match, restrict j explicitly, e.g. j(`usej' 80 81 82), or rename the stray variable first"
            }
        }

        if "`usei'" != "" & "`usestubs'" != "" {
            local cmd "reshape long `usestubs', i(`usei') j(`usej')`jstring'"
            local status ok
        }
        else if "`usestubs'" != "" {
            local status needinfo
            local diagmsg "wide pattern found (stubs: `usestubs') but no variable or pair uniquely identifies the rows; rerun with i(yourid)"
        }
    }

    * ---------- 5b. DOUBLY WIDE -> LONG-LONG (two chained reshapes) -----------
    if "`direction'" == "doubly" {
        local g1 : word 1 of `dblgroups'
        local p1  `db_p1`g1''
        local md  `db_mid`g1''
        local d1s : list uniq db_d1s`g1'
        local d1s : list sort d1s
        local d2s : list uniq db_d2s`g1'
        * step 1: long over the LAST digit run; one stub per first-index value
        local st1 ""
        foreach d of local d1s {
            local st1 `st1' `p1'`d'`md'
        }
        * i: unique row id
        if "`i'" != "" local usei `i'
        else {
            foreach iv of local icands {
                capture isid `iv'
                if !_rc {
                    local usei `iv'
                    continue, break
                }
            }
        }
        local j2 time
        capture confirm variable `j2'
        if !_rc local j2 _t
        local j1 grp
        capture confirm variable `j1'
        if !_rc local j1 _g
        if "`usei'" != "" {
            local cmd  "reshape long `st1', i(`usei') j(`j2')"
            local cmd2 "reshape long `p1'@`md', i(`usei' `j2') j(`j1')"
            local usestubs "`st1'"
            local usej "`j2' then `j1'"
            local status ok
            local note "doubly wide: two chained reshapes; rename `j1'/`j2' to your real dimensions afterward"
        }
        else {
            local status needinfo
            local diagmsg "doubly-wide pattern found (`p1'#`md'#) but no unique row id; rerun with i(yourid)"
        }
    }

    * ---------- 5c. LONG -> WIDE ----------------------------------------------
    if "`direction'" == "long2wide" {
        if "`j'" != "" {
            capture confirm variable `j'
            if _rc {
                di as err "j(`j') not found: going wide, j() must name an EXISTING variable (going long it names the variable to create)"
                exit 111
            }
            local usej `j'
        }
        else if "`longj'" != "" local usej `longj'
        else local usej : word 1 of `jcands'
        if "`i'" != "" local usei `i'
        else           local usei `longi'
        if "`usei'" == "" & "`usej'" != "" {
            * j is settled but i is not: try named candidates, then a bounded
            * general pool, singly and in pairs
            * pool excludes j and any unique-by-itself variable (a measure
            * with all-distinct values would make isid trivially true)
            local ipool3 ""
            foreach v of local icands {
                if "`v'" == "`usej'" continue
                local dpos : list posof "`v'" in dvlist
                if `dpos' == 0 continue
                if `dist`dpos'' < `NS' local ipool3 `ipool3' `v'
            }
            foreach v of local allv {
                if `: word count `ipool3'' >= 8 continue, break
                local in1 : list v in ipool3
                if `in1' | "`v'" == "`usej'" continue
                local dpos : list posof "`v'" in dvlist
                if `dpos' == 0 continue
                if `dist`dpos'' < `NS' local ipool3 `ipool3' `v'
            }
            foreach iv of local ipool3 {
                capture isid `iv' `usej'
                if !_rc {
                    local dpos : list posof "`iv'" in dvlist
                    if `dpos' > 0 {
                        if `dist`dpos'' > `NS'/2 {
                            if "`sparsecand'" == "" {
                                local sparsecand `iv'
                                local sparsej `usej'
                            }
                            continue
                        }
                    }
                    local usei `iv'
                    continue, break
                }
            }
            if "`usei'" == "" {
                local np : word count `ipool3'
                forvalues a = 1/`= min(`np', 6)' {
                    forvalues b = `= `a' + 1'/`= min(`np', 6)' {
                        local iva : word `a' of `ipool3'
                        local ivb : word `b' of `ipool3'
                        capture isid `iva' `ivb' `usej'
                        if !_rc {
                            tempvar gg
                            quietly bysort `iva' `ivb': gen byte `gg' = (_n == 1)
                            quietly count if `gg'
                            local ngrp = r(N)
                            drop `gg'
                            if `ngrp' > `NS'/2 continue
                            local usei `iva' `ivb'
                            continue, break
                        }
                    }
                    if "`usei'" != "" continue, break
                }
            }
        }

        if "`usei'" != "" & "`usej'" != "" {
            * stubs = variables that VARY within i (across j); constants ride along
            local usestubs ""
            local consts ""
            foreach v of local scanv {
                local ini : list v in usei
                if `ini' | "`v'" == "`usej'" continue
                tempvar w
                capture confirm string variable `v'
                if !_rc quietly bysort `usei' (`v'): gen byte `w' = (`v'[1] != `v'[_N])
                else    quietly bysort `usei' (`v'): gen byte `w' = (`v'[1] != `v'[_N]) & !(missing(`v'[1]) & missing(`v'[_N]))
                quietly count if `w'
                if r(N) > 0 local usestubs `usestubs' `v'
                else        local consts `consts' `v'
                drop `w'
            }
            if "`usestubs'" == "" {
                local status needinfo
                local diagmsg "no variable varies within i(`usei') across j(`usej'); nothing to widen"
            }
            else {
                * string j pre-checks: option string; spaces cleaned first
                local jstring ""
                local badj 0
                capture confirm string variable `usej'
                if !_rc {
                    local jstring " string"
                    quietly count if strpos(`usej', " ") > 0
                    if r(N) > 0 {
                        local preline `"replace `usej' = subinstr(`usej', " ", "_", .)"'
                        quietly replace `usej' = subinstr(`usej', " ", "_", .)
                        local note "j values contained spaces; the first line below cleans them (reshape refuses a string j with spaces)"
                    }
                }
                else {
                    capture assert `usej' == int(`usej') | missing(`usej')
                    if _rc {
                        local badj 1
                        local status needinfo
                        local diagmsg "j candidate `usej' has non-integer values; reshape wide needs an integer or string j"
                    }
                }
                if !`badj' {
                    local cmd "reshape wide `usestubs', i(`usei') j(`usej')`jstring'"
                    local status ok
                    * a COMPOUND i() that still holds a low-cardinality factor
                    * means the data can widen FURTHER (the long-long case).  A
                    * single-variable i() is just the identifier, so the note
                    * must not fire there - it would call the id a "factor".
                    if `: word count `usei'' >= 2 {
                        foreach iv of local usei {
                            local dpos : list posof "`iv'" in dvlist
                            if `dpos' == 0 continue
                            if `dist`dpos'' >= 2 & `dist`dpos'' <= 12 {
                                local note "i() still contains the factor `iv'; this reshape widens one dimension - rerun reshapehelper on the result to widen the next, or fold factors into one j: egen newj = concat(`usej' `iv'), p(_)"
                            }
                        }
                    }
                    * long stub names + suffix may exceed 32 chars.  The j value
                    * is spliced into a string for length only.  It is compound-
                    * quoted and read with -macval- so a value carrying a " does
                    * not unbalance the quotes, and the whole probe is wrapped in
                    * -capture- so an exotic value (a backtick, say) can never
                    * escape to the caller; the caution is advisory, so on any
                    * failure it is simply skipped.
                    local maxlen 0
                    capture {
                        foreach s of local usestubs {
                            quietly levelsof `usej' in 1/`= min(_N, 200)', ///
                                local(jl) clean
                            foreach lv of local jl {
                                if strlen(`"`s'`macval(lv)'"') > 32 local maxlen 1
                            }
                        }
                    }
                    if `maxlen' local caution "some new names (stub+j) would exceed 32 characters; shorten stubs or j values first"
                }
            }
        }
        else if "`usej'" != "" {
            local status needinfo
            * if a candidate DID make i+j unique but was set aside as sparse, the
            * cause is sparseness, not duplicates; the dedicated sparse note (in
            * the checklist) carries the advice, so keep this diagnosis short.
            if "`sparsecand'" != "" {
                local diagmsg "no i() both identifies the rows and repeats enough to widen (see the sparse-units note below)"
            }
            else {
                local topi : word 1 of `icands'
                if "`topi'" != "" & "`topi'" != "`usej'" {
                    tempvar dtag
                    capture duplicates tag `topi' `usej', generate(`dtag')
                    local ndup 0
                    if !_rc {
                        quietly count if `dtag' > 0
                        local ndup = r(N)
                        drop `dtag'
                    }
                    local diagmsg "no i() makes i+j unique with j(`usej'); with i(`topi'), `ndup' of `NS' sample rows share an (i, j) pair. Remedies: duplicates report `topi' `usej' then drop true duplicates; collapse repeated measures; sequence them: bysort `topi' `usej': gen seq = _n and use i(`topi' seq); or fold a second factor into j: egen newj = concat(`usej' otherfactor), p(_) then reshape on j(newj) string"
                }
                else local diagmsg "j(`usej') looks right but no i makes i+j unique; run: duplicates report <yourid> `usej'"
            }
        }
    }

    * ---------- 5d. nothing discernible ---------------------------------------
    if inlist("`direction'", "unknown", "none_for_long", "none_for_wide") {
        local status needinfo
        if "`direction'" == "none_for_long" ///
            local diagmsg "you asked for to(long) but no wide naming pattern (stub+suffix) was found"
        if "`direction'" == "none_for_wide" ///
            local diagmsg "you asked for to(wide) but no i+j combination uniquely identifies the rows"
    }

    * ---------- xpose / sxpose advisory ----------------------------------------
    local xposeflag 0
    if "`status'" == "needinfo" & `NFULL' <= 40 {
        local nstr 0
        local nnum 0
        foreach v of local allv {
            capture confirm string variable `v'
            if !_rc local ++nstr
            else    local ++nnum
        }
        if `nnum' >= 2 & `nstr' <= 1 & "`icands'" == "" local xposeflag 1
        if `nnum' >= 2 & `nstr' == 1 & `NFULL' < `KFULL' local xposeflag 1
    }

    * =========================================================================
    * 6. BEFORE snapshot (original order), then the dry run
    * =========================================================================
    restore, preserve
    if _N > `sample' quietly keep in 1/`sample'

    * pick display vars for the before box
    local shovars ""
    if "`usei'" != "" local shovars `usei'
    if "`direction'" == "long2wide" local shovars `shovars' `usej'
    local nsv : word count `shovars'
    foreach v of local allv {
        if `: word count `shovars'' >= 5 continue, break
        local in1 : list v in shovars
        if !`in1' {
            local instub : list v in stubvars
            if "`direction'" == "long2wide" {
                local instub : list v in usestubs
            }
            if `instub' local shovars `shovars' `v'
        }
    }
    if `: word count `shovars'' < 2 {
        local shovars ""
        local kk 0
        foreach v of local allv {
            local ++kk
            if `kk' > 4 continue, break
            local shovars `shovars' `v'
        }
    }
    _rh_snap, vars(`shovars') rows(3)
    local b_hdr `"`r(hdr)'"'
    local b_n   = r(n)
    forvalues r = 1/`b_n' {
        local b_l`r' `"`r(l`r')'"'
    }
    local b_obs = _N

    * ---- the dry run: run suggestion on the sample, iterate on failures ------
    local a_hdr ""
    local a_n 0
    if "`cmd'" != "" & "`notest'" == "" {
        if `"`preline'"' != "" quietly capture `preline'
        local attempt 0
        local lastrc .
        while `attempt' < 4 {
            local ++attempt
            capture `cmd'
            local lastrc = _rc
            if `lastrc' == 0 continue, break
            * iterate: known fixable failures (rc map verified against Stata:
            * 109 string j w/o -string-; 498 string suffixes read as all-missing
            * j in reshape long; 110 j name already exists; 111 no xij found /
            * string j with spaces; 9 uniqueness & constancy failures)
            if inlist(`lastrc', 109, 498) & strpos("`cmd'", " string") == 0 {
                local cmd "`cmd' string"
                continue
            }
            if `lastrc' == 110 & "`direction'" != "long2wide" {
                * proposed j name collides with an existing variable
                if "`usej'" != "_j" local usej _j
                else                local usej _jj
                local cmd "reshape long `usestubs', i(`usei') j(`usej')`jstring'"
                continue
            }
            if `lastrc' == 111 & "`direction'" != "long2wide" {
                local diagmsg "reshape found no variables matching stub(s) `usestubs' (r(111) no xij variables); check the naming with: describe `: word 1 of `usestubs''*"
                continue, break
            }
            if `lastrc' == 9 & "`direction'" == "long2wide" {
                * duplicates within i,j: diagnose, then try augmenting i once
                tempvar dtag
                capture duplicates tag `usei' `usej', generate(`dtag')
                if !_rc {
                    quietly count if `dtag' > 0
                    local ndup = r(N)
                    local diagmsg "`ndup' sample rows share the same (i, j): reshape wide cannot place two values in one cell. Check: duplicates report `usei' `usej' - then drop true duplicates, collapse repeated measures, add the distinguishing variable to i(), or fold a second factor into j: egen newj = concat(`usej' otherfactor), p(_) - and reshape on j(newj) string. After your own failed try, -reshape error- lists the offending rows"
                    drop `dtag'
                }
                local aug 0
                foreach av of local jcands {
                    if "`av'" == "`usej'" continue
                    local ini : list av in usei
                    if `ini' continue
                    capture isid `usei' `av' `usej'
                    if !_rc {
                        local usei `usei' `av'
                        local cmd "reshape wide `usestubs', i(`usei') j(`usej')`jstring'"
                        local note "i() was widened to include `av' to make rows unique - confirm that is the design"
                        local aug 1
                        continue, break
                    }
                }
                if !`aug' continue, break
                continue
            }
            if `lastrc' == 9 & "`direction'" == "wide2long" {
                local diagmsg "i(`usei') does not uniquely identify the wide rows; check: duplicates report `usei' - or supply a fuller i()"
                continue, break
            }
            continue, break
        }
        local finalrc = `lastrc'
        if `lastrc' == 0 {
            local tested 1
            * chained second step for doubly-wide
            if "`cmd2'" != "" {
                capture `cmd2'
                if _rc {
                    local tested 0
                    local finalrc = _rc
                    local diagmsg "step 1 ran but step 2 failed with r(`finalrc'); run step 1, inspect, then adjust step 2"
                }
            }
        }
        if `tested' {
            local resultN = _N
            local resultK = c(k)
            * AFTER snapshot from the actually-reshaped sample
            local avars ""
            if "`usei'" != "" local avars `usei'
            if "`direction'" != "long2wide" & "`cmd2'" == "" {
                capture confirm variable `usej'
                if !_rc local avars `avars' `usej'
            }
            unab aall : _all
            foreach v of local aall {
                if `: word count `avars'' >= 5 continue, break
                local in1 : list v in avars
                if !`in1' local avars `avars' `v'
            }
            _rh_snap, vars(`avars') rows(3)
            local a_hdr `"`r(hdr)'"'
            local a_n   = r(n)
            forvalues r = 1/`a_n' {
                local a_l`r' `"`r(l`r')'"'
            }
        }
        else if "`status'" == "ok" {
            local status blocked
            if "`diagmsg'" == "" ///
                local diagmsg "the dry run failed with r(`finalrc'); run the command under -capture noisily- on a copy, or see help reshape"
        }
    }
    restore

    * =========================================================================
    * 7. Emit
    * =========================================================================
    di as txt _n "{hline 70}"
    di as txt "reshapehelper 1.0.0 " as txt "{c |} " as res `NFULL' as txt " obs, " ///
        as res `KFULL' as txt " vars" _c
    if "`xtpanel'`xttime'" != "" di as txt " {c |} xtset: " as res "`xtpanel' `xttime'" _c
    if "`svypsu'" != "" di as txt " {c |} svy psu: " as res "`svypsu'" _c
    di as txt ""
    di as txt "{hline 70}"

    if "`detail'" != "" {
        di as txt "patterns:  numeric-suffix groups: " as res `: word count `numgroups'' ///
            as txt "   @-groups: " as res `: word count `atgroups'' ///
            as txt "   string-suffix: " as res `: word count `strgroups'' ///
            as txt "   doubly-wide: " as res `: word count `dblgroups''
        di as txt "i candidates: " as res "`icands'"
        di as txt "j candidates: " as res "`jcands'"
        di as txt "{hline 70}"
    }

    * ---- the diagram -----------------------------------------------------------
    if `b_n' > 0 {
        local shape1 = cond("`direction'" == "long2wide", "long", "wide")
        local bmore = cond(`b_obs' > `b_n', "more", "")
        di as txt _n "  NOW (`shape1'): " as res `b_obs' as txt " sample obs"
        _rh_box, hdr(`"`b_hdr'"') n(`b_n') l1(`"`b_l1'"') l2(`"`b_l2'"') l3(`"`b_l3'"') `bmore'
    }
    if `tested' & `a_n' > 0 {
        di as txt "        {c |}"
        if "`cmd2'" == "" di as txt "        {c |}  " as res "`cmd'"
        else {
            di as txt "        {c |}  " as res "`cmd'"
            di as txt "        {c |}  " as res "`cmd2'"
        }
        di as txt "        v"
        local shape2 = cond("`direction'" == "long2wide", "wide", "long")
        local amore = cond(`resultN' > `a_n', "more", "")
        di as txt "  AFTER (`shape2'): " as res `resultN' as txt " obs, " ///
            as res `resultK' as txt " vars  " as res "[dry run: OK]"
        _rh_box, hdr(`"`a_hdr'"') n(`a_n') l1(`"`a_l1'"') l2(`"`a_l2'"') l3(`"`a_l3'"') `amore'
    }

    * ---- verdict + suggestion ----------------------------------------------------
    if "`status'" == "ok" | "`status'" == "blocked" {
        di as txt _n "suggested command" _c
        if "`notest'" != "" di as txt " (not dry-run tested):"
        else if `tested' di as txt " (dry-run " as res "PASSED" as txt " on `b_obs' sample obs):"
        * the FAILED verdict is a report, not an error: -as err- output is never
        * suppressed by -quietly-, which would leak a bare "FAILED198" out of
        * -quietly reshapehelper-.  Genuine errors above still use -as err-.
        else di as txt " (dry-run " as res "FAILED" as txt ", r(" as res "`finalrc'" as txt ")):"
        local ls = c(linesize)
        capture set linesize 255
        if `"`preline'"' != "" di as res `"  `preline'"'
        di as res `"  `cmd'"'
        if "`cmd2'" != "" di as res `"  `cmd2'"'
        capture set linesize `ls'
        if "`note'" != ""    di as txt _n "  note: `note'"
        if "`caution'" != "" di as txt "  caution: `caution'"
        if "`diagmsg'" != "" & "`status'" == "blocked" di as txt _n "  what to check: `diagmsg'"

        * global + smcl + links.  The globals always mirror THIS run: a run
        * with no second step clears the stale `global'2 from a previous run
        * (a pipeline testing "$reshapehelper_cmd2" != "" must not fire on the
        * prior dataset's chained step).
        global `global' `"`cmd'"'
        if "`cmd2'" != "" global `global'2 `"`cmd2'"'
        else              global `global'2
        if `"`smcl'"' == "" {
            local smclout = c(tmpdir)
            if substr(`"`smclout'"', -1, .) != "/" & substr(`"`smclout'"', -1, .) != "\" ///
                local smclout `"`smclout'/"'
            local smclout `"`smclout'reshapehelper_suggestion.smcl"'
        }
        else local smclout `"`smcl'"'
        capture {
            tempname fh
            file open `fh' using `"`smclout'"', write text replace
            file write `fh' "{smcl}" _n
            file write `fh' "{txt}reshapehelper suggestion  {c -}  `c(current_date)' `c(current_time)'" _n
            file write `fh' "{hline}" _n
            if `"`preline'"' != "" file write `fh' `"{res}`preline'"' _n
            file write `fh' `"{res}`cmd'"' _n
            if "`cmd2'" != "" file write `fh' `"{res}`cmd2'"' _n
            file write `fh' "{txt}{hline}" _n
            file write `fh' "{txt}also stored in r(cmd) and " _char(36) "`global'" _n
            file close `fh'
        }
        * only advertise the file if it was actually written (smcl() can name an
        * unwritable directory; the write above is captured)
        capture confirm file `"`smclout'"'
        local haveout = (_rc == 0)
        di as txt ""
        * click-to-RUN links.  A link is emitted only when it is safe to click:
        * the command carries no double-quote, and there is no pre-clean line it
        * would skip.  A chained (doubly-wide) suggestion gets one link per step.
        local safe1 = (strpos(`"`cmd'"', `"""') == 0 & `"`preline'"' == "")
        if `safe1' & "`cmd2'" == "" {
            di as smcl `"  {stata `"`cmd'"':>> click to RUN this on the full data}"'
        }
        else if `safe1' & "`cmd2'" != "" & strpos(`"`cmd2'"', `"""') == 0 {
            di as smcl `"  {stata `"`cmd'"':>> click to RUN step 1}"'
            di as smcl `"  {stata `"`cmd2'"':>> click to RUN step 2 (after step 1)}"'
        }
        if `haveout' {
            di as smcl `"  {view `"`smclout'"':>> click to VIEW/copy the unwrapped syntax}"'
        }
        di as txt  `"  stored: r(cmd)  and  "' _char(36) `"`global'"'
        if `haveout' return local smcl `"`smclout'"'
    }
    else {
        * ---- needinfo: no suggestion, so the mirror globals are cleared too ---
        global `global'
        global `global'2
        di as txt _n "reshapehelper could not settle on a single command."
        if "`diagmsg'" != "" di as txt "  diagnosis: `diagmsg'"
        * sparse-panel note: a candidate DID make i+j unique but was set aside
        * because it barely repeats (near one row per unit).  Say so plainly and
        * give advice even though no command is offered.
        if "`sparsecand'" != "" & "`usei'" == "" {
            di as txt _n "  {bf:possible cause: sparse units.}  " as res "`sparsecand'" ///
                as txt " together with " as res "`sparsej'" as txt " does uniquely"
            di as txt "  identify the rows, but each unit appears only about once, so it was"
            di as txt "  set aside as an unlikely identifier.  If this is a genuinely sparse"
            di as txt "  panel (most units observed once, a few repeated), that is a valid but"
            di as txt "  unusual design.  Then either:"
            di as txt "    - force it: " as res "reshapehelper, to(wide) i(`sparsecand') j(`sparsej')"
            di as txt "    - or confirm there are repeats to widen at all: " ///
                as res "duplicates report `sparsecand'"
            di as txt "  If instead most rows should share an id, the real identifier may be"
            di as txt "  missing or mis-typed (e.g. a name with trailing spaces); clean it first."
        }
        di as txt _n "  Things to check or supply, then rerun reshapehelper:"
        local k 1
        if "`icands'" == "" {
            di as txt "   `k'. no unique row identifier found - state one with i(): " ///
                as res "reshapehelper, i(yourid)"
            local ++k
        }
        else {
            di as txt "   `k'. confirm the row identifier: " as res "isid `: word 1 of `icands''"
            local ++k
        }
        if !`widejudge' & "`to'" != "wide" {
            di as txt "   `k'. no stub+suffix naming pattern found; if the data are wide," ///
                " rename to a consistent pattern first, e.g. " as res "rename inc* income*"
            local ++k
            * near-miss report: single-suffix stubs that almost form a family
            local nearmiss ""
            forvalues g = 1/`nng' {
                local u : list uniq ng_sufs`g'
                if `: word count `u'' == 1 {
                    local nearmiss "`nearmiss' `ng_stub`g''(`u')"
                }
            }
            if `: word count `nearmiss'' >= 2 {
                di as txt "      near-miss stubs seen, each with only one suffix:" ///
                    as res "`nearmiss'"
                di as txt "      if these are the same measure, unify the stems" ///
                    " (rename income81 inc81 ...) and rerun"
            }
        }
        local ic1 : word 1 of `icands'
        local jc1 : word 1 of `jcands'
        if "`jc1'" != "" & "`ic1'" != "`jc1'" & "`ic1'" != "" & "`to'" != "long" {
            di as txt "   `k'. duplicates may block a wide reshape - inspect: " ///
                as res "duplicates report `ic1' `jc1'"
            local ++k
        }
        di as txt "   `k'. tell reshapehelper the target shape: " ///
            as res "reshapehelper, to(long)" as txt " or " as res "to(wide)"
        local ++k
        di as txt "   `k'. or hand it the pieces: " ///
            as res "reshapehelper, to(wide) i(id) j(year)"
        local njc : word count `jcands'
        if `njc' >= 2 & "`to'" != "long" {
            local ++k
            di as txt "   `k'. if several category variables together define the column," ///
                " fold them into one j first: " ///
                as res "egen newj = concat(`: word 1 of `jcands'' `: word 2 of `jcands''), p(_)"
        }
        if `xposeflag' {
            local ++k
            di as txt "   `k'. this looks more like a TRANSPOSE than a reshape (few rows," ///
                " columns are really observations): see " as res "help xpose" ///
                as txt " (or ssc install sxpose for string data)"
        }
    }
    di as txt "{hline 70}"

    * ---- returns -----------------------------------------------------------------
    * none_for_long / none_for_wide are internal "you asked for X but the
    * evidence is not there" states; collapse them to the documented -unknown-
    local retdir "`direction'"
    if inlist("`retdir'", "none_for_long", "none_for_wide") local retdir unknown
    return local  status    "`status'"
    return local  direction "`retdir'"
    return local  cmd       `"`cmd'"'
    return local  cmd2      `"`cmd2'"'
    return local  preclean  `"`preline'"'
    return local  i         "`usei'"
    return local  j         "`usej'"
    return local  stubs     "`usestubs'"
    return local  icands    "`icands'"
    return local  jcands    "`jcands'"
    return local  note      "`note'"
    return local  caution   "`caution'"
    return local  diagnosis "`diagmsg'"
    if "`status'" == "needinfo" & "`usei'" == "" & "`sparsecand'" != "" ///
        return local sparse "`sparsecand'"
    return scalar tested    = `tested'
    return scalar rc        = cond(`finalrc' == ., 0, `finalrc')
    return scalar xpose     = `xposeflag'
end


* -----------------------------------------------------------------------------
* _rh_snap: capture header + up to rows() formatted lines of vars() from the
* data in memory.  Cells are fixed 9 wide; strings truncated to 8 chars.
* -----------------------------------------------------------------------------
program define _rh_snap, rclass
    version 16.0
    syntax , VARS(varlist) ROWS(integer)

    local hdr ""
    foreach v of local vars {
        local vn = abbrev("`v'", 8)
        local hdr `"`hdr'`vn'"'
        local pad = 9 - strlen("`vn'")
        forvalues p = 1/`pad' {
            local hdr `"`hdr' "'
        }
    }
    local n = min(`rows', _N)
    forvalues r = 1/`n' {
        local line ""
        foreach v of local vars {
            capture confirm string variable `v'
            if !_rc {
                local cell = substr(`v'[`r'], 1, 8)
                * a cell value can carry a " or ` (inch marks, coded text);
                * scrub the quote characters so re-expansion of the assembled
                * line cannot unbalance quotes or start a phantom macro
                local cell : subinstr local cell `"""' "'", all
                local cell : subinstr local cell "`=char(96)'" "'", all
            }
            else {
                local cell = strofreal(`v'[`r'], "%8.0g")
                local cell = strtrim("`cell'")
            }
            local line `"`macval(line)'`macval(cell)'"'
            local pad = 9 - strlen(`"`macval(cell)'"')
            if `pad' < 1 local pad 1
            forvalues p = 1/`pad' {
                local line `"`macval(line)' "'
            }
        }
        return local l`r' `"`macval(line)'"'
    }
    return local hdr `"`hdr'"'
    return scalar n = `n'
end


* -----------------------------------------------------------------------------
* _rh_box: draw a boxed snapshot from _rh_snap output
* -----------------------------------------------------------------------------
program define _rh_box
    version 16.0
    syntax , HDR(string) N(integer) [ L1(string) L2(string) L3(string) MORE ]
    local w = strlen(`"`hdr'"') + 2
    if `w' > 74 local w 74
    local dash : di _dup(`w') "-"
    di as txt "  +`dash'+"
    di as txt "  | " as txt `"`= substr(`"`hdr'"', 1, 72)'"' as txt " |"
    forvalues r = 1/`n' {
        local pad = `w' - 2 - strlen(`"`l`r''"')
        local sp ""
        if `pad' > 0 local sp : di _dup(`pad') " "
        di as txt "  | " as res `"`= substr(`"`l`r''"', 1, 72)'"' `"`sp'"' as txt " |"
    }
    if "`more'" != "" di as txt "  | ..." _col(`= `w' + 3') " |"
    di as txt "  +`dash'+"
end
