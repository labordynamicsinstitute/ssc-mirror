cd "E:\mkes"

/* Clear any cached old program definition */
capture program drop mkes

/* ============================================================
   sunny_test.do — Test script for mkes.ado v3.1.0
   ============================================================ */

display _n "{hline 70}"
display as result "mkes v3.1.0 — Test Suite"
display "{hline 70}"

/* --- Single-prompt mode (original) --- */
display _n ">> Test 1: Single-prompt mode"
mkes "I'm", n(30) output(output) replace
mkes "There is no", n(15) replace
mkes "Can you", n(10) replace
mkes "I want to", n(20) output(my_sentences) replace

/* --- Multi-unit mode: sequential --- */
display _n ">> Test 2: Multi-unit sequential mode"
mkes , units(3) mode(sequential) n(5) output(test_multi) replace

/* --- Multi-unit mode: random --- */
display _n ">> Test 3: Multi-unit random mode"
mkes , units(3) mode(random) n(5) output(test_random) replace

/* --- Multi-unit mode: sequential with start --- */
display _n ">> Test 4: Multi-unit sequential with start"
mkes , units(3) mode(sequential) start(50) n(5) output(test_start) replace

/* --- Multi-unit mode: default sequential --- */
display _n ">> Test 5: Multi-unit with default mode"
mkes , units(5) n(8) output(test_default) replace
mkes, units(300) n(8) output(oral-english) replace

/* --- List patterns --- */
display _n ">> Test 6: List all patterns"
mkes --list

display _n "{hline 70}"
display as result "All tests completed. Check output files:"
display as text "  mkes_output.txt, output.txt, my_sentences.txt"
display as text "  test_multi.txt, test_random.txt, test_start.txt, test_default.txt，oral-english.txt"
display "{hline 70}"
