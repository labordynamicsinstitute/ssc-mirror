*! example_reshapehelper.do -- worked examples for -reshapehelper-
*! ----------------------------------------------------------------------------
*!  A guided tour of reshape situations, from the textbook case to the ones
*!  that fill Statalist threads.  Each tier builds a small dataset, asks
*!  reshapehelper to diagnose it, and then (where a command was suggested)
*!  runs the suggestion for real via the stored global.
*!
*!  reshapehelper NEVER reshapes your data.  It scans the variable names,
*!  hunts for i and j, composes the likely reshape command, tests it on a
*!  sample inside preserve/restore, and hands you: an ASCII before/after
*!  diagram, the suggested syntax with its dry-run verdict (also in r(cmd),
*!  $reshapehelper_cmd, and a viewable SMCL file), or a checklist of what to
*!  fix when it cannot discern the design.
*!
*!  Run top-to-bottom:  do example_reshapehelper.do
*!  Requires: reshapehelper.ado on the adopath, Stata 16+.
*! ----------------------------------------------------------------------------
version 16
clear all
set more off

* ============================================================================
* TIER 1 -- the textbook case ([D] reshape Example 1)
*   Income recorded once per year, one column per year.  reshapehelper finds
*   the stub (inc), the id (id), names the new j (year), and dry-runs it.
* ============================================================================
clear
input id sex inc80 inc81 inc82
1 0 5000 5500 6000
2 1 2000 2200 3300
3 0 3000 2000 1000
end

reshapehelper

* the suggestion is stored three ways; use whichever suits your workflow:
return list
di as txt "global: " as res `"$reshapehelper_cmd"'

* run it for real:
$reshapehelper_cmd
list in 1/6, sepby(id)


* ============================================================================
* TIER 1b -- two measures at once (inc AND ue)
*   Both stubs share the suffix set, so one command moves both.
* ============================================================================
clear
input id sex inc80 inc81 inc82 ue80 ue81 ue82
1 0 5000 5500 6000 0 1 0
2 1 2000 2200 3300 1 0 0
3 0 3000 2000 1000 0 0 1
end
reshapehelper
$reshapehelper_cmd


* ============================================================================
* TIER 1c -- long back to wide
*   On tidy long data with no to(), reshapehelper reads the design as long
*   and offers the widening command; to(wide) says it explicitly.
* ============================================================================
reshapehelper, to(wide)
$reshapehelper_cmd


* ============================================================================
* TIER 2 -- string suffixes (sysuse bpwide)
*   bp_before/bp_after: the suffix is text, so the command needs -string-.
*   reshapehelper adds it and names the j "period".
* ============================================================================
sysuse bpwide, clear
reshapehelper
$reshapehelper_cmd
list in 1/4


* ============================================================================
* TIER 2b -- the j in the MIDDLE of the name ([D] reshape Example 7)
*   inc80r inc81r inc82r: the year sits between "inc" and "r", which is what
*   reshape's @ notation is for.  ue80-ue82 ride along in the same command.
* ============================================================================
clear
input id sex inc80r inc81r inc82r ue80 ue81 ue82
1 0 5000 5500 6000 0 1 0
2 1 2000 2200 3300 1 0 0
3 0 3000 2000 1000 0 0 1
end
reshapehelper
$reshapehelper_cmd


* ============================================================================
* TIER 2c -- unbalanced stubs ([D] reshape Example 6)
*   ue81 was never collected.  reshape fills the gap with missings; the
*   note under the suggestion says so before you run anything.
* ============================================================================
clear
input id sex inc80 inc81 inc82 ue80 ue82
1 0 5000 5500 6000 0 0
2 1 2000 2200 3300 1 0
3 0 3000 2000 1000 0 1
end
reshapehelper
di as txt "note returned: " as res `"`r(note)'"'
$reshapehelper_cmd


* ============================================================================
* TIER 3 -- the inc2 trap ([D] reshape, explicit j values)
*   inc2 records something else entirely, but it matches the inc stub.  The
*   dry run PASSES -- reshape is happy to build a mostly-missing j=2 group --
*   so read the caution: it flags the mixed suffix widths and shows how to
*   restrict j explicitly or rename the stray column.
* ============================================================================
clear
input id sex inc80 inc81 inc82 inc2
1 0 5000 5500 6000 1
2 1 2000 2200 3300 0
3 0 3000 2000 1000 1
end
reshapehelper
di as txt "caution returned: " as res `"`r(caution)'"'
* the safe version, per the caution:
rename inc2 reincorporated
reshapehelper
$reshapehelper_cmd


* ============================================================================
* TIER 3b -- inconsistent stubs: inc80 / income81 / incm82 (UVA, Stata FAQ)
*   No family of names forms, so reshapehelper refuses to guess and instead
*   reports the near-miss stubs it saw.  Unify the stems and rerun.
* ============================================================================
clear
input id sex inc80 income81 incm82
1 0 5000 5500 6000
2 1 2000 2200 3300
3 0 3000 2000 1000
end
reshapehelper
* the checklist names inc(80) income(81) incm(82); do what it says:
rename income81 inc81
rename incm82 inc82
reshapehelper
$reshapehelper_cmd


* ============================================================================
* TIER 3c -- bare string suffixes need a hint ([D] reshape Example 8)
*   incm/incf have no separator, so scanning would be guesswork (the manual's
*   own warning: with an "agenda" variable, stub "age" + j "nda"!).  Hand
*   reshapehelper the stub and it discovers the -string- option by itself,
*   by iterating on reshape's error in the dry run.
* ============================================================================
clear
input id kids incm incf
1 0 5000 5500
2 1 2000 2200
3 2 3000 2000
end
reshapehelper, to(long) stubs(inc) i(id) j(sex)
$reshapehelper_cmd
list


* ============================================================================
* TIER 3d -- the j hides in the PREFIX (Statalist: "no xij variables found")
*   qld_p nsw_p vic_p share only their tail.  Naive reshape throws r(111);
*   reshapehelper suggests the @-form that treats the prefix as j.
* ============================================================================
clear
input year qld_p nsw_p vic_p
2018 4.9 7.9 6.4
2019 5.0 8.0 6.5
2020 5.1 8.1 6.6
end
reshapehelper
$reshapehelper_cmd
rename _p unemployment          // give the reshaped measure a real name
list


* ============================================================================
* TIER 4 -- duplicates block the widening (Statalist, manual Example 3)
*   Two identical rows for id 2 in 2019.  There is no valid reshape until a
*   human decides: drop the duplicate, average it, or sequence it.
*   reshapehelper counts the collisions and lays out exactly those choices.
* ============================================================================
clear
input id year inc
1 2019 45000
1 2020 47000
2 2019 32000
2 2019 32000
2 2020 33500
end
reshapehelper, to(wide)
di as txt "diagnosis: " as res `"`r(diagnosis)'"'
* here the repeat is an exact duplicate, so:
duplicates drop
reshapehelper, to(wide)
$reshapehelper_cmd


* ============================================================================
* TIER 4b -- string j with spaces (Statalist r(111))
*   "New York" cannot become part of a variable name.  reshapehelper writes
*   the cleaning line for you and dry-runs the pair.
* ============================================================================
clear
input year str12 state pop
2020 "New York" 20.2
2020 "Texas" 29.1
2021 "New York" 19.8
2021 "Texas" 29.5
end
reshapehelper, to(wide) j(state)
di as txt "pre-clean line: " as res `"`r(preclean)'"'
`r(preclean)'
$reshapehelper_cmd
list


* ============================================================================
* TIER 4c -- two crossed factors (Statalist: animal x level x delay)
*   reshape takes ONE j.  reshapehelper widens one factor and its note shows
*   the two ways to finish: rerun on the result, or fold the factors into a
*   single composite j with egen concat() first.
* ============================================================================
clear
input animal s1level s1s2delay s2peakvalue
1 0 50 12.1
1 0 100 13.4
1 0 200 15.2
1 1 50 18.3
1 1 100 19.9
1 1 200 22.4
2 0 50 11.8
2 0 100 12.9
2 0 200 14.7
2 1 50 17.5
2 1 100 19.2
2 1 200 21.8
end
reshapehelper, to(wide)
di as txt "note: " as res `"`r(note)'"'
* route A: run the suggestion, then rerun reshapehelper on the result
* route B (full flatten in one pass), per the note:
egen j = concat(s1level s1s2delay), p(_)
drop s1level s1s2delay
reshape wide s2peakvalue, i(animal) j(j) string
list


* ============================================================================
* TIER 5 -- the wide-long panel (county-year rows, sectors as columns)
*   The rows already carry a time dimension (xtset county year); the sector
*   columns hide a SECOND long dimension.  reshapehelper keeps year inside
*   i() and says so in the note -- this is the case that confuses panels.
* ============================================================================
clear
input county year emp_manuf emp_retail emp_gov
1 2019 120 340 210
1 2020 115 330 215
2 2019  80 210 150
2 2020  78 220 155
3 2019  60 190 120
3 2020  61 200 118
end
xtset county year
reshapehelper
di as txt "note: " as res `"`r(note)'"'
$reshapehelper_cmd
rename (period emp_) (sector employment)
list, sepby(county year)


* ============================================================================
* TIER 5b -- doubly wide (UCLA OARC FAQ): TWO indices packed into each name
*   ht_k1_t1 = height, kid 1, time 1.  One reshape cannot unpack two
*   dimensions; reshapehelper writes the chained pair and dry-runs both.
* ============================================================================
clear
input famid ht_k1_t1 ht_k1_t2 ht_k2_t1 ht_k2_t2
1 3.1 3.6 4.0 4.4
2 3.3 3.8 4.1 4.6
3 3.0 3.5 3.9 4.3
end
reshapehelper
di as txt "step 1: " as res `"$reshapehelper_cmd"'
di as txt "step 2: " as res `"$reshapehelper_cmd2"'
$reshapehelper_cmd
$reshapehelper_cmd2
rename (grp ht_k_t) (kid height)
list, sepby(famid)


* ============================================================================
* TIER 5c -- long-long to wide-wide ([D] reshape, second-level nesting)
*   Two j dimensions (sex, year) means two widenings.  Run reshapehelper,
*   run its suggestion, run reshapehelper AGAIN on the result: the helper is
*   built to be rerun until the note falls silent.
* ============================================================================
clear
input hid str1 sex year inc
1 "f" 90 3200
1 "f" 91 4700
1 "m" 90 4500
1 "m" 91 4600
2 "f" 90 3600
2 "f" 91 3800
2 "m" 90 5100
2 "m" 91 5300
end
reshapehelper, to(wide)
$reshapehelper_cmd
reshapehelper, to(wide)
$reshapehelper_cmd
list


* ============================================================================
* TIER 5d -- not a reshape at all: transpose (Statalist xpose thread)
*   Metrics live in ROWS, samples in columns.  No i, no j, nothing to stub:
*   the checklist points at xpose (sxpose for string data).
* ============================================================================
clear
input str12 metric alpha beta gamma
"n"       100 200 150
"mean"    52.1 48.9 50.3
"missing" 3 7 5
end
reshapehelper

di as res _n "example_reshapehelper.do complete."
