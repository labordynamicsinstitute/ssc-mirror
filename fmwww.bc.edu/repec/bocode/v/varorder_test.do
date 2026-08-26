version 16.0

/*
    Release test for varorder 1.1.0.

    Usage:
        do varorder_test.do

    If the distribution files are stored in another directory:
        do varorder_test.do "D:/path/to/varorder"

    This test uses only the documented public interfaces varorder and
    varorder, undo. In an interactive Stata session, press Enter at the one
    confirmation prompt to test application and undo. In batch mode, the
    test verifies that the unavailable confirmation is declined safely.
*/

args release_dir
clear all
set more off
set linesize 255
capture log close

if `"`release_dir'"' == "" local release_dir `"`c(pwd)'"'
local release_dir = subinstr(`"`release_dir'"', "\", "/", .)
while substr(`"`release_dir'"', -1, 1) == "/" {
    local release_dir = substr(`"`release_dir'"', 1, strlen(`"`release_dir'"')-1)
}

log using `"`release_dir'/varorder_test.log"', text replace

scalar TV_tests = 0
scalar TV_pass = 0
scalar TV_fail = 0

program define tvassert
    syntax anything(name=expr equalok)
    scalar TV_tests = TV_tests + 1
    capture assert `expr'
    if _rc {
        scalar TV_fail = TV_fail + 1
        di as error "TEST_VARORDER_ASSERTION_FAILED: `expr'"
    }
    else scalar TV_pass = TV_pass + 1
end

program define tvasserteq
    args actual expected
    scalar TV_tests = TV_tests + 1
    if `"`actual'"' != `"`expected'"' {
        scalar TV_fail = TV_fail + 1
        di as error `"TEST_VARORDER_ASSERTION_FAILED: `actual' != `expected'"'
    }
    else scalar TV_pass = TV_pass + 1
end

foreach release_file in varorder.ado varorder.sthlp varorder_example.do varorder_example_data.dta {
    capture confirm file `"`release_dir'/`release_file'"'
    local file_rc = _rc
    tvassert `file_rc' == 0
}

adopath ++ `"`release_dir'"'
capture which varorder
local which_rc = _rc
tvassert `which_rc' == 0

* Only the two documented command forms are accepted.
clear
set obs 1
generate byte placeholder = 1
capture noisily varorder placeholder
local syntax_rc = _rc
tvassert `syntax_rc' == 101
capture noisily varorder, reverse
local syntax_rc = _rc
tvassert `syntax_rc' == 198

* Validate the public preview with the distributed example dataset.
use `"`release_dir'/varorder_example_data.dta"', clear
unab example_before : _all
local is_batch = (lower(c(mode)) == "batch")

capture log close tvpreview
log using `"`release_dir'/varorder_test_preview.log"', text replace name(tvpreview)
noisily varorder
local example_changed = r(changed)
local example_k = r(k)
local example_detected = r(n_families_detected)
local example_confirmed = r(n_families_confirmed)
local example_related = r(n_families_related)
local example_ambiguous = r(n_families_ambiguous)
local example_families_changed = r(n_families_changed)
local example_suppressed = r(n_families_suppressed)
local example_moved = r(n_moved)
local example_displacement = r(max_displacement)
local example_lists = r(order_lists_returned)
local example_old `r(oldorder)'
local example_new `r(neworder)'
mata: st_numscalar("__tv_quotes",substr(st_global("r(oldorder)"),1,2)==char(96)+char(34) | substr(st_global("r(oldorder)"),-2,2)==char(34)+char(39) | substr(st_global("r(neworder)"),1,2)==char(96)+char(34) | substr(st_global("r(neworder)"),-2,2)==char(34)+char(39))
mata: st_numscalar("__tv_words",cols(tokens(st_global("r(oldorder)")))==146 & cols(tokens(st_global("r(neworder)")))==146)
local direct_new_rc = .
local direct_old_rc = .
if `is_batch' {
    capture order `r(neworder)'
    local direct_new_rc = _rc
    capture order `r(oldorder)'
    local direct_old_rc = _rc
}
log close tvpreview

unab example_after : _all
tvassert `example_k' == 146
tvassert `example_detected' == 42
tvassert `example_confirmed' == 29
tvassert `example_related' == 6
tvassert `example_ambiguous' == 7
tvassert `example_suppressed' == 13
tvassert `example_lists' == 1
tvassert __tv_quotes == 0
tvassert __tv_words == 1
tvasserteq `"`example_old'"' `"`example_before'"'
if `is_batch' {
    tvassert `example_changed' == 0
    tvassert `example_families_changed' == 0
    tvassert `example_moved' == 0
    tvassert `example_displacement' == 0
    tvassert `direct_new_rc' == 0
    tvassert `direct_old_rc' == 0
    tvasserteq `"`example_new'"' `"`example_before'"'
    tvasserteq `"`example_after'"' `"`example_before'"'
}
else {
    tvassert `example_changed' == 1
    tvassert `example_families_changed' == 29
    tvassert `example_moved' == 131
    tvassert `example_displacement' == 89
    tvasserteq `"`example_after'"' `"`example_new'"'
}

file open tvp using `"`release_dir'/varorder_test_preview.log"', read text
local preview_headers = 0
local examined_lines = 0
local confirmed_lines = 0
local reordered_lines = 0
local displacement_lines = 0
local issue_headers = 0
local gap_lines = 0
local related_lines = 0
local ambiguous_lines = 0
local decision_lines = 0
local preview_prompts = 0
local prompt_spacing = 0
local confirmed_name_lines = 0
local diagnostic_lines = 0
local postview_lines = 0
local success_lines = 0
local decline_lines = 0
local previous_line ""
file read tvp line
while r(eof) == 0 {
    if strtrim(`"`line'"') == "varorder preview summary" local ++preview_headers
    if strtrim(`"`line'"') == "Examined: 146 variables" local ++examined_lines
    if strtrim(`"`line'"') == "Confirmed temporal structures: 29" local ++confirmed_lines
    if strtrim(`"`line'"') == "Variables to be reordered: 131" local ++reordered_lines
    if strtrim(`"`line'"') == "Maximum displacement: 89 columns" local ++displacement_lines
    if strtrim(`"`line'"') == "Issues requiring review:" local ++issue_headers
    if strpos(`"`line'"', "Gap warnings but ordering allowed (2): mobility, vigor") local ++gap_lines
    if strpos(`"`line'"', "Related/unverified") & strpos(`"`line'"', "(6): eng, exercise, lab, mood, promotion_status, reading") local ++related_lines
    if strpos(`"`line'"', "Ambiguous/conflicting") & strpos(`"`line'"', "(7): focus, memory, mirage, pain, prism_check") local ++ambiguous_lines
    if strpos(`"`line'"', "All eligible structures will be included in the proposed ordering.") local ++decision_lines
    if strpos(`"`line'"', "Press Enter to apply the proposed ordering.") {
        local ++preview_prompts
        if strtrim(`"`previous_line'"') == "" local ++prompt_spacing
    }
    if strpos(`"`line'"', "stems:") local ++confirmed_name_lines
    if strpos(`"`line'"', "missing indexed position") | strpos(`"`line'"', "temporal meaning unverified") | strpos(`"`line'"', "construct conflict") | strpos(`"`line'"', "metadata conflict") | strpos(`"`line'"', "normalized-key collision") local ++diagnostic_lines
    if strpos(`"`line'"', "postview summary") | strpos(`"`line'"', "post-operation summary") | strpos(`"`line'"', "Updated:") local ++postview_lines
    if strpos(`"`line'"', "Variable order updated.") local ++success_lines
    if strpos(`"`line'"', "Confirmation declined; dataset unchanged.") local ++decline_lines
    local previous_line `"`line'"'
    file read tvp line
}
file close tvp

tvassert `preview_headers' == 1
tvassert `examined_lines' == 1
tvassert `confirmed_lines' == 1
tvassert `reordered_lines' == 1
tvassert `displacement_lines' == 1
tvassert `issue_headers' == 1
tvassert `gap_lines' == 1
tvassert `related_lines' == 1
tvassert `ambiguous_lines' == 1
tvassert `decision_lines' == 1
tvassert `preview_prompts' == 1
tvassert `prompt_spacing' == 1
tvassert `confirmed_name_lines' == 0
tvassert `diagnostic_lines' == 0
tvassert `postview_lines' == 0
if `is_batch' {
    tvassert `success_lines' == 0
    tvassert `decline_lines' == 1
    capture noisily varorder, undo
    local undo_rc = _rc
    tvassert `undo_rc' == 459
}
else {
    tvassert `success_lines' == 1
    tvassert `decline_lines' == 0
    capture noisily varorder, undo
    local undo_rc = _rc
    tvassert `undo_rc' == 0
    unab example_undo : _all
    tvasserteq `"`example_undo'"' `"`example_before'"'
    capture noisily varorder, undo
    local undo2_rc = _rc
    tvassert `undo2_rc' == 459
}

* With no review issue and no physical change, omit both issue section and prompt.
clear
set obs 2
generate byte kinetic_t1 = _n
generate byte kinetic_t2 = _n
capture log close tvnoop
log using `"`release_dir'/varorder_test_noop.log"', text replace name(tvnoop)
noisily varorder
local noop_changed = r(changed)
local noop_k = r(k)
local noop_detected = r(n_families_detected)
local noop_confirmed = r(n_families_confirmed)
local noop_related = r(n_families_related)
local noop_ambiguous = r(n_families_ambiguous)
local noop_families_changed = r(n_families_changed)
local noop_suppressed = r(n_families_suppressed)
local noop_moved = r(n_moved)
local noop_displacement = r(max_displacement)
local noop_lists = r(order_lists_returned)
local noop_old `r(oldorder)'
local noop_new `r(neworder)'
log close tvnoop
unab noop_order : _all
tvasserteq `"`noop_order'"' `"kinetic_t1 kinetic_t2"'
tvassert `noop_changed' == 0
tvassert `noop_k' == 2
tvassert `noop_detected' == 1
tvassert `noop_confirmed' == 1
tvassert `noop_related' == 0
tvassert `noop_ambiguous' == 0
tvassert `noop_families_changed' == 0
tvassert `noop_suppressed' == 0
tvassert `noop_moved' == 0
tvassert `noop_displacement' == 0
tvassert `noop_lists' == 1
tvasserteq `"`noop_old'"' `"kinetic_t1 kinetic_t2"'
tvasserteq `"`noop_new'"' `"kinetic_t1 kinetic_t2"'

file open tvn using `"`release_dir'/varorder_test_noop.log"', read text
local noop_issues = 0
local noop_prompts = 0
local noop_messages = 0
local noop_postviews = 0
file read tvn line
while r(eof) == 0 {
    if strpos(`"`line'"', "Issues requiring review:") local ++noop_issues
    if strpos(`"`line'"', "Press Enter to apply the proposed ordering.") local ++noop_prompts
    if strpos(`"`line'"', "No variable-order changes were required.") local ++noop_messages
    if strpos(`"`line'"', "postview summary") | strpos(`"`line'"', "post-operation summary") | strpos(`"`line'"', "Updated:") local ++noop_postviews
    file read tvn line
}
file close tvn
tvassert `noop_issues' == 0
tvassert `noop_prompts' == 0
tvassert `noop_messages' == 1
tvassert `noop_postviews' == 0

* A gap remains orderable and is the only issue category displayed.
clear
set obs 2
generate byte canopy_t1 = _n
generate byte canopy_t4 = _n
capture log close tvgap
log using `"`release_dir'/varorder_test_gap.log"', text replace name(tvgap)
noisily varorder
local gap_changed = r(changed)
local gap_confirmed = r(n_families_confirmed)
log close tvgap
tvassert `gap_changed' == 0
tvassert `gap_confirmed' == 1

file open tvg using `"`release_dir'/varorder_test_gap.log"', read text
local gap_issue_headers = 0
local gap_warnings = 0
local gap_related = 0
local gap_ambiguous = 0
file read tvg line
while r(eof) == 0 {
    if strpos(`"`line'"', "Issues requiring review:") local ++gap_issue_headers
    if strpos(`"`line'"', "Gap warnings but ordering allowed (1): canopy") local ++gap_warnings
    if strpos(`"`line'"', "Related/unverified") local ++gap_related
    if strpos(`"`line'"', "Ambiguous/conflicting") local ++gap_ambiguous
    file read tvg line
}
file close tvg
tvassert `gap_issue_headers' == 1
tvassert `gap_warnings' == 1
tvassert `gap_related' == 0
tvassert `gap_ambiguous' == 0

di as result "TEST_VARORDER_TESTS=" TV_tests
di as result "TEST_VARORDER_PASS=" TV_pass
di as result "TEST_VARORDER_FAIL=" TV_fail

local final_fail = TV_fail
log close
if `final_fail' > 0 exit 9
exit, clear
