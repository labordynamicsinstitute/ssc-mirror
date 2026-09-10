*! _finegray_check_level Version 1.3.2  2026/09/08
*! Validate an explicitly supplied level() against Stata's own cilevel rule
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal (nclass)

/*
  _finegray_check_level, level(<what the user typed>)

WHY THIS EXISTS.  The `finegray' command parses Level(cilevel) and so inherits
the Stata rule: 10 to 99.99 inclusive, at most two decimals.  The post-estimation
commands cannot use `cilevel' -- it auto-fills an OMITTED level() with
c(level), which destroys the "was level() supplied?" test their
"level() requires ci" guards depend on -- so they parse `Level(string)' and
validated by hand.  Three hand-written copies (`finegray_cif',
`finegray_predict', `_finegray_display') drifted from the parent: each rejected
only `>= 100', so `finegray, level(99.995)' stopped at r(198) while
`finegray_cif, level(99.995)' printed a table headed "99.995% CI".  Each also
printed "must be a number between 10 and 99.99" while accepting 99.995 -- a
message contradicting its own check, independent of the cross-command gap.

Delegating to cilevel here makes the bound and the message identical to the
parent command in all four places, so they cannot drift again.  Callers pass level() only when the
user supplied it; an omitted level() is the caller's own c(level)/e(level)
default and never reaches this program.

This program is deliberately NOT rclass: it must be callable from anywhere in a
parse block without disturbing a pending r() surface.
*/

capture program drop _finegray_check_level
program define _finegray_check_level
    version 16.0
    syntax , Level(cilevel)
end
