

program define epicheck

    version 14
	
	syntax , did(varlist) [QUIET]
	
    if "`did'" == "" {
        di as err "Option did() is required"
        exit 198
    }

quietly {
		
	local did `did'
	
	// Robust panel id even if did is string
	tempvar udid
	egen `udid' = group(`did')

// 1) Missing DID (count only; DO NOT drop)
capture drop __miss_did
egen __miss_did_ct = rowmiss(`did')
gen  byte __miss_did = (__miss_did_ct > 0)
drop __miss_did_ct

tempvar __tag_did
egen `__tag_did' = tag(`did') if __miss_did
count if __miss_did
scalar __n_miss_did_rows    = r(N)
count if `__tag_did' == 1
scalar __n_miss_did_diaries = r(N)
drop `__tag_did'


// 2) Missing start/end (keep in data, but exclude from checks)
capture drop __miss_se
gen byte __miss_se = missing(start) | missing(end)

tempvar __tag_miss
egen `__tag_miss' = tag(`did') if __miss_se
count if __miss_se
scalar __n_miss_rows    = r(N)
count if `__tag_miss' == 1
scalar __n_miss_diaries = r(N)
drop `__tag_miss'

// *** SAVE HERE (includes rows with missing start/end) ***

// --- Tripwire: record the original size and a unique signature ---
scalar __N0 = _N
tempvar __rowid0
gen long `__rowid0' = _n
quietly summ start, meanonly
scalar __start_sum0 = r(sum)
quietly summ end, meanonly
scalar __end_sum0   = r(sum)

tempfile startingfile
save "`startingfile'"


// Exclude missing DID and missing start/end *only for the structural checks*
keep if !__miss_did & !__miss_se

* --- Step 2 helper: mark valid-length rows (working copy only) ---
capture drop __oklen
gen byte __oklen = (start < end) if start < . & end < .
replace __oklen = 0 if start==end & start < .

* Exclude zero-length rows from structural machinery (they can break overlap/gap logic)
drop if __oklen == 0
drop __oklen

/* 1. fully overlapping episodes */

tempvar blockid blocksize ecounter flag1

egen `blockid' = group(`did' start end)
bysort `blockid': gen `ecounter'=_n
egen `blocksize' = count(`ecounter'), by(`blockid')

gen `flag1' = 0
replace `flag1'=1 if `blocksize'>1 & `ecounter'==1
drop if `ecounter'>1 & `blocksize'>1

sort `did' start

gen flag1=`flag1' // nEW

/* 2. Nested episodes */

tempvar epnum flag2 

bysort `did' (start end): gen `epnum' = _n
tsset `udid' `epnum'

gen byte `flag2' =0
replace `flag2' =1 if start<f1.start & end>f1.end & f1.start<. & f1.end<.
drop if l1.`flag2'==1 // dropping the nested episode

sort `did' start
 
gen flag2=`flag2' // nEW
 

/* 3. partial overlap of episodes */

/* ---------- PRE-PASS: SAME-START partial overlaps ----------
   Pattern: current [s .. e] and next [s .. e1] with e < e1
            and the same start time (s == f1.start).
   Fix: split the NEXT episode at e (current's end),
        drop the redundant [s .. e] copy, keep [e .. e1].
*/

tempvar newobs flag3

bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'

gen byte `flag3' = 0
replace `flag3' = 1 if   (end > f1.start & end < f1.end & f1.start != . & f1.end != .)

gen byte flag3_report = `flag3'

* Detect same-start partial overlaps among rows flagged as case 3
capture drop __sspo
gen byte __sspo = (`flag3'==1 & start==f1.start & end < f1.end) ///
                  & f1.start < . & f1.end < .

* Mark the NEXT row wherever the PREVIOUS row had same-start PO
capture drop __dupnext
gen byte __dupnext = l1.__sspo

* Duplicate only those NEXT rows
capture drop __newnext
expand 2 if __dupnext, gen(__newnext)

* Re-order and re-number after expansion
sort `did' start end __newnext
bysort `did' (start end __newnext): replace `epnum' = _n
tsset `udid' `epnum'

* Split NEXT with strict guards (positive-length only)
replace end   = l1.end if __dupnext & __newnext==0 & l1.end < . ///
                               & l1.end > start            // ensures [s .. e] with e>s
replace start = l1.end if __dupnext & __newnext==1 & l1.end < . ///
                               & l1.end < end              // ensures [e .. e1] with e<e1

* Drop the redundant overlap chunk of the NEXT episode ([s .. e])
drop if __dupnext & __newnext==0

* Re-number episodes after the drop
bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'

* This same-start case is now resolved → clear the flag on the CURRENT (shorter) row
replace `flag3' = 0 if __sspo

* Tidy helpers from same-start fix
drop __dupnext __newnext __sspo


/* ---------- CLASSIC (STAGGERED) partial overlaps ----------
   Your original logic, plus strict guards to avoid start==end or pushing starts forward.
*/

bysort `did' (start): replace `epnum' = _n
tsset `udid' `epnum'

* Expand flagged episodes into two rows (to create 3 segments total)
capture drop `newobs'
expand 2 if `flag3' == 1, gen(`newobs')
sort `did' start `newobs'

* Re-index after expand
bysort `did' (start): replace `epnum' = _n
tsset `udid' `epnum'

* Middle segment (overlap): inserted copy starts at the next episode's start
replace start = f1.start if `flag3' == 1 & `newobs' == 1

* Re-index for safe lags/leads
bysort `did' (start): replace `epnum' = _n
tsset `udid' `epnum'

* Final segment (tail of the second/original next episode's window on this row)
* Only close a real gap; never push a start forward to equality/past

replace start = l1.end if `flag3'!=1 & l1.`flag3' == 1 & l1.end > start

* Re-index again
bysort `did' (start): replace `epnum' = _n
tsset `udid' `epnum'

* Initial segment (head of the first/original flagged episode)
* Guard ensures we never create start==end
replace end = f1.start if `flag3'==1 & `newobs' == 0 & f1.start > start

* STEP 4: Assign secondary activity to the overlap (middle) segment
bysort `did' (start): replace `epnum' = _n
tsset `udid' `epnum'
//replace ___sec = f1.___pri if `flag3'==1 & `newobs' == 1

* STEP 5: Final cleanup of flags (only the initial piece gets cleared)
replace `flag3' = 0 if `flag3'==1 & `newobs' == 0

* Belt-and-braces: drop any accidental zero-length rows and renumber
//drop if start==end & start<.
bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'

replace `flag3' = flag3_report
drop flag3_report

/* 4. Gaps at beginning of diary */

tempvar flag4 
bysort `did' (start end): replace `epnum' = _n
gen byte `flag4' = (`epnum' == 1 & start != 0)
capture drop `newobs'
expand 2 if `flag4', gen(`newobs')

bysort `did' (start end): replace start = 0                     if `newobs'
bysort `did' (start end): replace end   = start[_n+1]           if `newobs' & _n < _N
bysort `did' (start end): replace end   = 1440                  if `newobs' & _n == _N

//replace `flag4' = 0 if !`newobs'
replace `flag4' = 0 if `newobs'

sort `did' start

/* 5. Gaps at end of diary — robust to same-start ties */
tempvar flag5 __diary_end __is_last

* Find each diary's true last end
bysort `did': egen `__diary_end' = max(end)

* Mark the row(s) that reach the diary's last end
gen byte `__is_last' = (end == `__diary_end')

* Flag gap at end only if the diary end is not 1440
gen byte `flag5' = 0
replace `flag5' = 1 if `__is_last' == 1 & `__diary_end' != 1440

capture drop `newobs'
expand 2 if `flag5', gen(`newobs')

* Insert filler from the true diary end to 1440
replace start = `__diary_end' if `newobs' & `__diary_end' < .
replace end   = 1440         if `newobs'

replace `flag5' = 0 if `newobs'

drop `__diary_end' `__is_last'


/* 6. Gaps between episodes */

tempvar flag6 

bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'   // use the same ID you used above

gen byte `flag6' = 0
replace `flag6' = (f1.start > end) if !missing(f1.start)

sort `did' start

/* 7. start==end & start!=. */

tempvar flag7 

bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'   

gen byte `flag7' = 0
replace `flag7' = 1 if start==end & start!=. 

sort `did' start

/* 8. start==.|end==. */

tempvar flag8 

bysort `did' (start end): replace `epnum' = _n
tsset `udid' `epnum'   

gen byte `flag8' = 0
replace `flag8' = 1 if start==.|end==. 

sort `did' start

* Enforce exclusivity across issue flags (8 > 7 > 1 > 2 > 3 > 4 > 5 > 6) *

/* Ensure all issue flags exist and are 0/1 (missing -> 0) */
foreach f in `flag1' `flag2' `flag3' `flag4' `flag5' `flag6' `flag7' `flag8' {
    capture confirm variable `f'
    if _rc gen byte `f' = 0
    replace `f' = 0 if missing(`f')
    replace `f' = (`f' != 0)
}

capture drop __flag_case
gen byte __flag_case = 0
replace __flag_case = 8 if __flag_case==0 & `flag8' == 1
replace __flag_case = 7 if __flag_case==0 & `flag7' == 1
replace __flag_case = 1 if __flag_case==0 & `flag1' == 1
replace __flag_case = 2 if __flag_case==0 & `flag2' == 1
replace __flag_case = 3 if __flag_case==0 & `flag3' == 1
replace __flag_case = 4 if __flag_case==0 & `flag4' == 1
replace __flag_case = 5 if __flag_case==0 & `flag5' == 1
replace __flag_case = 6 if __flag_case==0 & `flag6' == 1

label define __issue 0 "No issues" 1 "Full overlap" 2 "Nested episode" 3 "Partial overlap" 4 "Gap at min 0" 5 "Gap at end of diary" 6 "Gap between episodes" 7 "Row with start==end" 8 "Row with start==.|end==.", replace 
label values __flag_case __issue
label variable __flag_case "Episode issue flag (0=no issue, 1–8=type)"

capture drop __ecounter
bysort `did' start: gen __ecounter = _n   // create BEFORE filtering


keep if __flag_case > 0

if _N {
    isid `did' start __ecounter
}

keep `did' start __ecounter __flag_case
sort `did' start __ecounter
tempfile flags
save "`flags'"
			  
use "`startingfile'", clear 

// --- Tripwire: confirm we are back to the original dataset ---
capture confirm scalar __N0
if _rc {
	noi di as err "EpiCheck internal error: original-data signature scalars not found after reload."
    exit 459
}

if _N != __N0 {
    noi di as err "EpiCheck internal error: dataset size differs after reload. Before=" ///
              %12.0f __N0 " After=" %12.0f _N
    exit 459
}

quietly summ start, meanonly
if r(sum) != __start_sum0 {
    noi di as err "EpiCheck internal error: start differs after reload (signature mismatch)."
    exit 459
}

quietly summ end, meanonly
if r(sum) != __end_sum0 {
    noi di as err "EpiCheck internal error: end differs after reload (signature mismatch)."
    exit 459
}

capture drop __flag_case
capture drop __flag_diary 

capture drop __ecounter
sort `did' start
bysort `did' start: gen __ecounter = _n

sort `did' start __ecounter
capture drop _merge
merge m:1 `did' start __ecounter using "`flags'", keep(1 3)

assert _merge != 2
drop _merge
drop __ecounter


// Rows with missing start/end are coded as Issue 8
replace __flag_case = 8 if __miss_se == 1

* Flag raw zero-length episodes on the ORIGINAL data (so Step 2 can't hide them)
replace __flag_case = 7 if missing(__flag_case) & start==end & start<. & __miss_se==0

// Any remaining empty flags become 0 (no need for the __miss_se condition)
replace __flag_case = 0 if missing(__flag_case)


/* Diary-level flag: 1 if diary has any episode with issue 1–6.
   For rows with missing start/end, diary-level flag shown as missing (.) */

 capture drop __flag_diary
egen __flag_diary = max(__flag_case > 0), by(`did')
label variable __flag_diary "Diary contained at least one issue (1–8)"
format __flag_diary %5.0g 
 
forvalues i = 1/8 {
    capture drop __flag_diary_`i'
    egen __flag_diary_`i' = max(__flag_case == `i'), by(`did')
	format __flag_diary_`i' %5.0g 
}



label var __flag_diary_1 "Diary contains fully overlapping episodes" 
// do we need the capture?
label var __flag_diary_2 "Diary contains nested episode/s"
label var __flag_diary_3 "Diary contains partly overlapping episode/s"
label var __flag_diary_4 "Diary contains gap at beggining of diary"
label var __flag_diary_5 "Diary contains gap at the end of diary"
label var __flag_diary_6 "Diary contains gap/s between episode/s"
label var __flag_diary_7 "Diary contains episode/s where start==end"
label var __flag_diary_8 "Diary contains episode/s where start==.|end==."


*---------------------------------------------*
* Count total number of unique diaries
*---------------------------------------------*

tempvar __tagdiary
quietly egen `__tagdiary' = tag(`did')
quietly count if `__tagdiary' == 1
scalar __n_diaries = r(N)


* Count cases and diaries for issues 1–7 (Issue 8 handled separately)
* Count cases and diaries per issue code (1–8)
forvalues i = 1/8 {
    count if __flag_case == `i'
    scalar __cases`i' = r(N)

    egen __tag`i' = tag(`did') if __flag_case == `i'
    count if __tag`i' == 1
    scalar __diaries`i' = r(N)

    drop __tag`i'
}

capture scalar drop __total_cases __total_diaries

scalar __total_cases = 0
forvalues i = 1/8 {
    scalar __total_cases = __total_cases + __cases`i'
}

/* Total diaries = union of diaries with any issue (1–8) */
tempvar __tagTotal
quietly {
    egen `__tagTotal' = tag(`did') if __flag_diary == 1
    count if `__tagTotal' == 1
    scalar __total_diaries = r(N)
    drop `__tagTotal'
}

// Keep running so the final report (including missing start/end note) prints
scalar __noissues = (__total_cases == 0)



* =======================
* FINAL TRIPWIRE (Step 2)
* Put this RIGHT HERE
* =======================
if _N != __N0 {
    noi di as err "EpiCheck internal error (END): dataset size changed by end of program. Before=" ///
        %12.0f __N0 " After=" %12.0f _N
    exit 459
}

* (Optional but nice) also check start/end signatures
quietly summ start, meanonly
if r(sum) != __start_sum0 {
    noi di as err "EpiCheck internal error (END): start signature mismatch at end."
    exit 459
}

quietly summ end, meanonly
if r(sum) != __end_sum0 {
    noi di as err "EpiCheck internal error (END): end signature mismatch at end."
    exit 459
}

order `did' start end // __* 

} // end of quietly

	
* Updated table: header underline + issue labels instead of codes
local w1 34
local w2 8
local w3 8
local w4 9

/* Show output unless user asked for quiet AND there are no issues.
   If quiet & issues>0 → print full report (unchanged).
   If not quiet        → print as usual (including "No issues detected."). */
if !("`quiet'" != "" & __total_cases == 0) {

    /* === REPORT (base it on __total_cases we just computed) === */
    if (__total_cases == 0) {
        di as txt "No issues detected."
    }
    else {
        di as txt "Summary of issues detected"
        di as txt "---------------------------------------------------------------------"

        * Header row
        di as txt "  " %-`w1's "Issue (code - name)" ///
            " |" %`w2's "Cases"                      ///
            " |" %`w3's "Diaries"                    ///
            " |" %`w4's "Diaries (%)"

        * Header underline
        di as txt "-------------------------------------+---------+---------+-----------"

        * Table body with issue labels (1..8; 8 covers missing start/end)
        forvalues i = 1/8 {
            local label : label __issue `i'
            local rowlbl "`i'. `label'"
            di as result "  " %-`w1's "`rowlbl'" ///
                " |" %`w2'.0f scalar(__cases`i') ///
                " |" %`w3'.0f scalar(__diaries`i') ///
                " |" %`w4'.1f (100 * scalar(__diaries`i') / scalar(__n_diaries))
        }

        * Footer underline
        di as txt "-------------------------------------+---------+---------+-----------"

        * Total row
        di as result "  " %-`w1's "Total" ///
             " |" %`w2'.0f __total_cases ///
             " |" %`w3'.0f __total_diaries ///
             " |" %`w4'.1f (100 * __total_diaries / __n_diaries)

        di as txt "---------------------------------------------------------------------"

    }

    // ---- Transparency notes about dropped/excluded rows ----
    if (scalar(__n_miss_did_rows) > 0) {
        di as txt ""
        local n : display %1.0f scalar(__n_miss_did_rows)
        di as txt "Some rows " as res "(`n')" as txt " were found with missing values in one or more of the did() variables. " ///
        "These rows were ignored during issue detection. " ///
        "You may drop them; none of the timealloc utilities will ever use those observations."
    }
}

qui drop __miss_did __miss_se 

if (__total_cases == 0) {
    qui capture drop __flag_case __flag_diary
    forvalues i = 1/8 {
        qui capture drop __flag_diary_`i'
    }
}

end 
