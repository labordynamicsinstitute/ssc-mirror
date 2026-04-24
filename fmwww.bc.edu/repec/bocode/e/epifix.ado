
program define epifix

version 14
	
* --- Guard: error if user typed an empty fullfix() ---
local __raw = lower("`0'")
if strpos("`__raw'", "fullfix()") {
    di as err "Option fullfix activates the complete-fix mode (no value needed)"
    exit 198
}


syntax varlist(min=1 max=6) , did(varlist) ///
    [ attrib(varlist) fullfix errorsonly QUIET]
	
	// ---- Activities from varlist ----
    local activities `varlist'
    local nact : word count `activities'
	
* --- Simple flag: fullfix (no parentheses) ---
local do_fullfix = 0
if "`fullfix'" != "" local do_fullfix = 1




* --- errorsonly: presence/absence flag ---
local do_errorsonly = 0
if "`errorsonly'" != "" local do_errorsonly = 1



local layer_names "pri sec ter quat fif six"

local need = `nact'
if (`need' > 6) local need = 6   // safety cap


    tokenize `activities'
    forvalues i = 1/6 {
        local act`i' ``i''   // act1, act2, ... act6 (some may be empty)
    }
	
* Save original variable labels (if any) — we will preserve names; labels are optional
forvalues i = 1/`nact' {
    local vlab`i' : variable label `act`i''
}

* Save original VALUE LABEL names and formats for activity vars
forvalues i = 1/`nact' {
    local vallab`i' : value label `act`i''
    local vfmt`i'   : format `act`i''
}


	// ---- Attributes from option (may be empty) ----
    local attribvars `attrib'
    local nattr : word count `attribvars'
	
    // Check and assign the diary ID
    if "`did'" == "" {
        di as err "Option did() is required"
        exit 198
    }


* ============================================================
* ERRORSONLY: restrict processing to diaries with any issue
* ============================================================
tempfile __orig __baddids


	
	quietly save "`__orig'", replace

if (`do_errorsonly'==1) {

    capture drop __flag_case __flag_diary

    * Always run epicheck quietly in errorsonly mode
    quietly epicheck, did(`did')   // (don’t let epicheck print its table here)

    preserve
        keep if __flag_diary == 1
        keep `did'
        quietly duplicates drop `did', force
        quietly save "`__baddids'", replace
    restore

    * Restrict to problem diaries quietly
    quietly merge m:1 `did' using "`__baddids'", gen(__m_bad) 
    quietly keep if __m_bad==3
    quietly drop __m_bad

    quietly count
    if r(N) == 0 {
        quietly use "`__orig'", clear
        if "`quiet'" == "" di as txt "epifix: no problem diaries detected (errorsonly). No changes made."
        exit
    }
}
 
	
* ---- If onlyfor(yes), restrict to flagged diaries up front ----

quietly {

		
	local did `did'
	
	// Robust panel id even if did is string
    tempvar udid
    egen `udid' = group(`did')


	// ===== Initialize internal activity layers from act1..act6 =====
    // Decide storage type from act1 and enforce consistency across activities
    capture confirm string variable `act1'
    local _act_is_string = !_rc

foreach v in __pri __sec __ter __quat __fif __six {
    capture confirm variable `v'
    if !_rc {
        capture confirm string variable `v'
        if (`_act_is_string' != !_rc) {
            di as err "`v' type mismatch with activity vars. Drop __pri/__sec/... or start from a clean dataset."
            exit 198
        }
    }
}

    // (Optional but recommended) ensure all passed activity vars share same type
    forvalues i = 2/`nact' {
        local ai : word `i' of `activities'
        capture confirm string variable `ai'
        if (`_act_is_string' != !_rc) {
            di as err "All activity vars must be the same type (string vs numeric). Mismatch at: `ai'"
            exit 198
        }
    }

/* === Working layers (triple underscores) — no collision with existing __* === */

foreach v in ___pri ___sec ___ter ___quat ___fif ___six {
    capture drop `v'
    if `_act_is_string' gen strL `v' = ""
    else                 gen double `v' = .
}

/* Copy input activity vars into working layers (only those provided) */
if "`act1'" != "" replace ___pri = `act1'
if "`act2'" != "" replace ___sec = `act2'
if "`act3'" != "" replace ___ter = `act3'
if "`act4'" != "" replace ___quat = `act4'
if "`act5'" != "" replace ___fif = `act5'
if "`act6'" != "" replace ___six = `act6'

    // Convenience list
    local _layers "___pri ___sec ___ter ___quat ___fif ___six"

    * ------------------------------------------------------------
    * Ensure flag variables exist; if not, run epicheck internally
    * ------------------------------------------------------------
    capture confirm variable __flag_case
    local has_flag_case = !_rc

    capture confirm variable __flag_diary
    local has_flag_diary = !_rc

    if (!`has_flag_case' | !`has_flag_diary') {
        if "`quiet'" != "" quietly epicheck, did(`did')
        else              epicheck, did(`did')
    }

    * If flags still do not exist after epicheck, dataset is clean
    capture confirm variable __flag_case
    local has_flag_case = !_rc

    capture confirm variable __flag_diary
    local has_flag_diary = !_rc

    if (!`has_flag_case' | !`has_flag_diary') {
        noi di as txt "epifix: no issues detected. Nothing to fix."

        if (`do_errorsonly'==1) {
            use "`__orig'", clear
            if "`quiet'" == "" di as txt "epifix: errorsonly active; returning original dataset unchanged."
        }
        exit 0
    }

    /* ===== EARLY EXIT (aware of fullfix()) ===== */
    quietly count if inlist(__flag_case,2,3,4,5,6,7,8)
    local __c28 = r(N)
	
	
	

if (`do_fullfix'==1) {
    quietly count if __flag_case==1
    local __c1 = r(N)

    if (!`__c1' & !`__c28') {
        noi di as txt "No issues to fix (including full overlaps via fullfix(yes))."

        // --- EARLY EXIT FIX (errorsonly): restore full dataset before leaving ---
       
		if (`do_errorsonly'==1) {
            use "`__orig'", clear
            if "`quiet'" == "" di as txt "epifix: errorsonly active; returning original dataset unchanged."
        }
        exit 0
    }
}
else {
    if (!`__c28') {
        noi di as txt "No issues to fix."
        *noi di as txt "Note: full overlaps (__flag_case==1) are handled by {cmd:epitrans}."

        // --- EARLY EXIT FIX (errorsonly): restore full dataset before leaving ---
     
		if (`do_errorsonly'==1) {
            use "`__orig'", clear
            if "`quiet'" == "" di as txt "epifix: errorsonly active; returning original dataset unchanged."
        }
        exit 0
    }
}



/* === PART A: Capture case 1 counts (only once) if fullfix(yes) === */
if (`do_fullfix'==1) {
    // Only create the scalars if they don't already exist
    capture confirm scalar __pre_cases1
    if _rc {
        count if __flag_case==1
        scalar __pre_cases1 = r(N)
    }

    capture confirm scalar __pre_diaries1
    if _rc {
        tempvar __tag1
        egen `__tag1' = tag(`did') if __flag_case==1
        count if `__tag1'==1
        scalar __pre_diaries1 = r(N)
        drop `__tag1'
    }
}


if (`do_fullfix'==1) {
    // Block id on (did,start,end)
    tempvar __blk __bsize __rank __keep __isfull
    egen `__blk' = group(`did' start end)

    // Blocks flagged as full overlaps
    bys `__blk': egen byte `__isfull' = max(__flag_case==1)

    // Size & rank within block (stable on current sort)
    bys `__blk': gen int `__bsize' = _N if `__isfull'
    bys `__blk': gen int `__rank'  = _n if `__isfull'

    // Survivor row (rank==1) in each full-overlap block
    gen byte `__keep' = (`__isfull' & `__rank'==1)

    // Clear internal layers in full-overlap blocks
    foreach L in ___pri ___sec ___ter ___quat ___fif ___six {
        capture confirm variable `L'
        if !_rc {
            if `_act_is_string' replace `L' = "" if `__isfull'
            else                  replace `L' = .  if `__isfull'
        }
    }

// Map rank→slot on survivor
forvalues k=1/6 {
    if (`k'<=`nact') {
        local layer = cond(`k'==1,"___pri", cond(`k'==2,"___sec", ///
                         cond(`k'==3,"___ter", cond(`k'==4,"___quat", ///
                         cond(`k'==5,"___fif","___six")))))
        bys `__blk' (start end): replace `layer' = `act1'[_n+`k'-1] ///
            if `__keep' & `__bsize'>=`k'
    }
}


    // Clear case-1 flag on survivor, drop the rest
    replace __flag_case = 0 if `__keep' & `__isfull'
    drop if `__isfull' & !`__keep'

    // Re-index after collapse
    tempvar epnum
    bysort `did' (start end): gen `epnum' = _n
    //tsset `udid' `epnum'
}

* Per-issue rows & diaries (7)
tempvar __tag7
count if __flag_case==7
scalar __drop7_rows = r(N)
egen `__tag7' = tag(`did') if __flag_case==7
count if `__tag7'==1
scalar __drop7_diaries = r(N)
drop `__tag7'

* Per-issue rows & diaries (8)
tempvar __tag8
count if __flag_case==8
scalar __drop8_rows = r(N)
egen `__tag8' = tag(`did') if __flag_case==8
count if `__tag8'==1
scalar __drop8_diaries = r(N)
drop `__tag8'

* Snapshot of total diaries with ANY EpiFix-relevant issue (2..8) BEFORE drop
tempvar __d_any __tag_any
egen `__d_any' = max(inlist(__flag_case,2,3,4,5,6,7,8)), by(`did')
egen `__tag_any' = tag(`did') if `__d_any'==1
count if `__tag_any'==1
scalar __pre_total_diaries_any = r(N)
drop `__tag_any' `__d_any'

* Also compute union across 1..8 BEFORE any fixes (needed when fullfix(yes))
if (`do_fullfix'==1) {
    tempvar __tag_all
    egen `__tag_all' = tag(`did') if inlist(__flag_case,1,2,3,4,5,6,7,8)
    count if `__tag_all'==1
    scalar __pre_total_diaries_all = r(N)
    drop `__tag_all'
}
else {
    scalar __pre_total_diaries_all = __pre_total_diaries_any
}

* Finally drop 7/8 rows
drop if inlist(__flag_case,7,8)

* Combined counts for reporting
capture scalar drop __drop78_rows __drop78_diaries
scalar __drop78_rows    = cond(missing(__drop7_rows),0,__drop7_rows) + cond(missing(__drop8_rows),0,__drop8_rows)
scalar __drop78_diaries = cond(missing(__drop7_diaries),0,__drop7_diaries) + cond(missing(__drop8_diaries),0,__drop8_diaries)

capture scalar drop __pre_cases2 __pre_cases3 __pre_cases4 __pre_cases5 __pre_cases6 ///
                     __pre_total_cases __pre_diaries2 __pre_diaries3 __pre_diaries4 __pre_diaries5 __pre_diaries6 ///
                     __pre_total_diaries
tempvar __tagpre

/* Per-case rows & diaries for 2–6 (unchanged) */
forvalues i = 2/6 {
    count if __flag_case == `i'
    scalar __pre_cases`i' = r(N)

    egen `__tagpre' = tag(`did') if __flag_case == `i'
    count if `__tagpre' == 1
    scalar __pre_diaries`i' = r(N)
    drop `__tagpre'
}

/* Totals & union of diaries */
if (`do_fullfix'==1) {

    capture scalar drop __pre_cases1_safe __pre_diaries1_safe
    scalar __pre_cases1_safe   = cond(missing(__pre_cases1),   0, __pre_cases1)
    scalar __pre_diaries1_safe = cond(missing(__pre_diaries1), 0, __pre_diaries1)

    /* Total cases including case 1 */
    scalar __pre_total_cases = __pre_cases1_safe
    forvalues i = 2/6 {
        scalar __pre_total_cases = __pre_total_cases + __pre_cases`i'
    }

    /* Union of diaries including case 1 */
    tempvar __tagpre_all
    egen `__tagpre_all' = tag(`did') if inlist(__flag_case,1,2,3,4,5,6)
    count if `__tagpre_all' == 1
    scalar __pre_total_diaries = r(N)
    drop `__tagpre_all'
}
else {
    /* Original behaviour: totals over 2–6 only */
    scalar __pre_total_cases = 0
    forvalues i = 2/6 {
        scalar __pre_total_cases = __pre_total_cases + __pre_cases`i'
    }

    egen `__tagpre' = tag(`did') if inlist(__flag_case,2,3,4,5,6)
    count if `__tagpre' == 1
    scalar __pre_total_diaries = r(N)
    drop `__tagpre'
}



/* Nested episodes - __flag_case==2 */

capture drop `epnum'
tempvar epnum

tempvar newobs   // <-- ADD THIS LINE (this is the fix)

bysort `did' (start end): gen long `epnum' = _n
expand 2 if __flag_case[_n-1]==2, gen(`newobs')
bysort `did' (start end `newobs'): replace `epnum' = _n


bysort `did' (start end): ///
    replace end = start[_n+1] if __flag_case==2 & _n < _N
bysort `did' (start end): ///
    replace ___sec = ___pri if __flag_case[_n-1]==2 & _n>1
bysort `did' (start end): ///
    replace ___pri = ___pri[_n-1] if __flag_case[_n-1]==2 & _n>1
bysort `did' (start end): ///
    replace ___pri = ___pri[_n-2] if __flag_case[_n-2]==2 & _n>2
bysort `did' (start end): ///
    replace start = end[_n-1] if __flag_case[_n-2]==2 & _n>2
bysort `did' (start end): ///
    replace end = start[_n+1] if __flag_case[_n-2]==2 & _n<_N

/* 3. partial overlap of episodes */

gen byte __f3a = 0
bysort `did' (start end): replace __f3a = 1 if __flag_case==3 ///
    & _n < _N ///
    & start < . & end < . ///
    & start[_n+1] < . & end[_n+1] < . ///
    & start <  start[_n+1] ///
    & end   >  start[_n+1] ///
    & end   <  end[_n+1]

gen byte __f3b = 0
bysort `did' (start end): replace __f3b = 1 if __flag_case==3 ///
    & _n < _N ///
    & start < . & end < . ///
    & start[_n+1] < . & end[_n+1] < . ///
    & start == start[_n+1] ///
    & end   <  end[_n+1]

gen byte __f3c = 0
bysort `did' (start end): replace __f3c = 1 if __flag_case==3 ///
    & _n < _N ///
    & start < . & end < . ///
    & start[_n+1] < . & end[_n+1] < . ///
    & end   == end[_n+1] ///
    & start <  start[_n+1]

/* Fixing 3a */
capture drop `newobs'
tempvar newobs
expand 2 if __f3a==1, gen(`newobs') 
bysort `did' (start end `newobs'): replace __f3a=0 if `newobs'==1 // keep only ONE flagged row per case (clear flag on the inserted copy)
 
bysort `did' (start end): replace end=start[_n+2] if __f3a==1 & _n <= _N-2
bysort `did' (start end): replace start=end[_n-1] if __f3a[_n-1]==1 & _n>1 
bysort `did' (start end): replace ___sec=___pri[_n+1] if __f3a[_n-1]==1 & _n>1 
bysort `did' (start end): replace start=end[_n-1] if __f3a[_n-2]==1 & _n>2 
	
/* Fixing 3b */
bysort `did' (start end): replace ___sec=___pri[_n+1] if __f3b==1 & _n < _N & !missing(___pri[_n+1])
bysort `did' (start end): replace start = end[_n-1] if _n > 1 & __f3b[_n-1]==1 & end[_n-1] < .

/* Fixing 3c */
bysort `did' (start end): replace end=start[_n+1] if __f3c==1 & _n < _N & !missing(start[_n+1]) & end > start[_n+1]     
bysort `did' (start end): replace ___sec=___pri if _n>1 & __f3c[_n-1]==1 & !missing(___pri) 
bysort `did' (start end): replace ___pri= ___pri[_n-1] if _n>1 & __f3c[_n-1]==1 & !missing(___pri[_n-1]) 
		
* clean up 
drop __f3a __f3b __f3c


/* 4. Gaps at beginning of diary */

* Duplicate first row when flagged; mark inserted copy
tempvar newobs
expand 2 if __flag_case == 4, gen(`newobs')

* For inserted (new) rows: set [start,end] = [0, old first start]
bysort `did' (start): replace start = 0               if `newobs'
bysort `did' (start): replace end   = start[_n+1]     if `newobs'

* Clear INTERNAL activity layers for inserted rows (type-aware)
foreach L in ___pri ___sec ___ter ___quat ___fif ___six {
    if `_act_is_string' replace `L' = "" if `newobs'
    else                  replace `L' = .  if `newobs'
}

* Clear attribute variables for inserted rows (type-aware; attrib() may be empty)
foreach attr of local attribvars {
    capture confirm string variable `attr'
    if !_rc replace `attr' = "" if `newobs'
    else    replace `attr' = .  if `newobs'
}

* Only the inserted rows carry the A-flag
replace __flag_case = 0 if __flag_case == 4 & !`newobs'
//egen __flag_case = max(`__flagA'), by(`did')

sort `did' start
bysort `did': replace `epnum' = _n

	
/* 5. Gaps at end of diary */

* Identify the last episode's end per diary (one-liner, no propagation needed)
tempvar last_end
bysort `did' (start): gen `last_end' = end[_N]

* Duplicate the row(s) that need the end-gap fill (your flag==5)
tempvar newobs
expand 2 if __flag_case==5, gen(`newobs')


* Assign [start,end] on the inserted row
replace start = `last_end' if __flag_case==5 & `newobs'==1
replace end   = 1440       if __flag_case==5 & `newobs'==1

* Clear INTERNAL activity layers for inserted rows (type-aware)
foreach L in ___pri ___sec ___ter ___quat ___fif ___six {
    capture confirm variable `L'
    if !_rc {
        if `_act_is_string' replace `L' = "" if `newobs'
        else                  replace `L' = .  if `newobs'
    }
}

* Clear attribute variables for inserted rows (type-aware; attrib() may be empty)
if `"`attribvars'"' != "" {
    foreach attr of local attribvars {
        capture confirm variable `attr'
        if !_rc {
            capture confirm string variable `attr'
            if !_rc replace `attr' = "" if `newobs'
            else    replace `attr' = .  if `newobs'
        }
    }
}


* Keep/assign the flag safely: only mark the new row as case 5; leave others unchanged
//replace __flag_case = 0 if __flag_case==5 & `newobs'==1
replace __flag_case = 0 if __flag_case==5 & `newobs'==0

		
/* 6. Other Gaps between episodes */

tempvar newobs
expand 2 if __flag_case==6, gen(`newobs')

sort `did' start `newobs'
bysort `did': replace `epnum' = _n
tsset `udid' `epnum'

replace start = l1.end   if __flag_case==6 & `newobs'==1
replace end   = f1.start if __flag_case==6 & `newobs'==1

* Clear INTERNAL activity layers for inserted rows (type-aware)
foreach L in ___pri ___sec ___ter ___quat ___fif ___six {
    if `_act_is_string' replace `L' = "" if __flag_case==6 & `newobs'==1
    else                  replace `L' = .  if __flag_case==6 & `newobs'==1
}

* Clear attributes for inserted rows (type-aware; attrib() may be empty)
foreach attr of local attribvars {
    capture confirm string variable `attr'
    if !_rc replace `attr' = "" if __flag_case==6 & `newobs'==1
    else    replace `attr' = .  if __flag_case==6 & `newobs'==1
}


* Flag for reporting (keep the flag on the inserted row)
replace __flag_case = 0   if __flag_case==6 & `newobs'==0


*----------------------------------------------------------------*
* Enforce exclusivity across issue flags (1 > 2 > 3 > 4 > 5)     *
*----------------------------------------------------------------*

/* Diary-level flag */
capture drop __flag_diary
egen __flag_diary = max(inlist(__flag_case,2,3,4,5,6)), by(`did')
label variable __flag_diary "Diary contained issue(s) fixed by epifix"

/* capture drop __flag_diary
egen __flag_diary = max(__flag_case > 0), by(`did') */

* Diaries affected by any issue (unique)
tempvar __tagTotal
quietly egen `__tagTotal' = tag(`did') if __flag_diary == 1
quietly count if `__tagTotal' == 1
scalar __total_diaries = r(N)


* ------------------------------------------------------------ *
* Drop unused activity slots at the end if they are fully empty
* ------------------------------------------------------------ *

* Sort & (best-effort) order: ignore any vars that might be absent
sort `did' start
capture order `did' start end ___pri ___sec ___ter ___quat ___fif ___six `attribvars' __flag_case __flag_diary

* Remove trailing empty layers only (string "" or numeric . both count as missing())
foreach act in ___six ___fif ___quat ___ter ___sec {
    capture confirm variable `act'
    if !_rc {
        quietly count if !missing(`act')
        if r(N)==0 capture drop `act'
    }
}

/* === Finalize: rebuild official activity columns and copy from working === */

/* === Finalize (EpiFix): rebuild official columns, then copy from working if present === */

/* __pri */
capture drop __pri
if `_act_is_string' gen strL __pri = ""
else                gen double __pri = .
capture confirm variable ___pri
if !_rc replace __pri = ___pri

* Reattach value label + format from act1 (only if numeric)
if !`_act_is_string' {
    if "`vallab1'" != "" label values __pri `vallab1'
    if "`vfmt1'"   != "" format __pri `vfmt1'
}

/* __sec */
capture drop __sec
if `_act_is_string' gen strL __sec = ""
else                gen double __sec = .
capture confirm variable ___sec
if !_rc replace __sec = ___sec

if !`_act_is_string' {
    if "`vallab2'" != "" label values __sec `vallab2'
    if "`vfmt2'"   != "" format __sec `vfmt2'
}

/* __ter */
capture drop __ter
if `_act_is_string' gen strL __ter = ""
else                gen double __ter = .
capture confirm variable ___ter
if !_rc replace __ter = ___ter

if !`_act_is_string' {
    if "`vallab3'" != "" label values __ter `vallab3'
    if "`vfmt3'"   != "" format __ter `vfmt3'
}

/* __quat */
capture drop __quat
if `_act_is_string' gen strL __quat = ""
else                gen double __quat = .
capture confirm variable ___quat
if !_rc replace __quat = ___quat

if !`_act_is_string' {
    if "`vallab4'" != "" label values __quat `vallab4'
    if "`vfmt4'"   != "" format __quat `vfmt4'
}

/* __fif */
capture drop __fif
if `_act_is_string' gen strL __fif = ""
else                gen double __fif = .
capture confirm variable ___fif
if !_rc replace __fif = ___fif

if !`_act_is_string' {
    if "`vallab5'" != "" label values __fif `vallab5'
    if "`vfmt5'"   != "" format __fif `vfmt5'
}

/* __six */
capture drop __six
if `_act_is_string' gen strL __six = ""
else                gen double __six = .
capture confirm variable ___six
if !_rc replace __six = ___six

if !`_act_is_string' {
    if "`vallab6'" != "" label values __six `vallab6'
    if "`vfmt6'"   != "" format __six `vfmt6'
}

/* Optional labels */
capture label var __pri  "Primary activity"
capture label var __sec  "Secondary activity"
capture label var __ter  "Tertiary activity"
capture label var __quat  "Quaternary activity"
capture label var __fif  "Fifth activity"
capture label var __six  "Sixth activity"

/* Optional: drop working columns */
capture drop ___pri 
capture drop ___sec 
capture drop ___ter 
capture drop ___quat 
capture drop ___fif 
capture drop ___six

/* Drop official activity columns beyond what we actually need */
forvalues j = `= `need' + 1' / 6 {
    local L : word `j' of `layer_names'
    capture drop __`L'
}

/* (optional) also drop unused working columns beyond need, or drop them all */
forvalues j = `= `need' + 1' / 6 {
    local L : word `j' of `layer_names'
    capture drop ___`L'
}


order `did' start end __pri `varlist' __flag_case __flag_diary
capture order `did' start end __pri __sec `varlist' __flag_case __flag_diary
capture order `did' start end __pri __sec __ter `varlist' __flag_case __flag_diary
capture order `did' start end __pri __sec __ter __quat `varlist' __flag_case __flag_diary
capture order `did' start end __pri __sec __ter __quat __fif `varlist' __flag_case __flag_diary
capture order `did' start end __pri __sec __ter __quat __fif __six `varlist' __flag_case __flag_diary

sort `did' start end


* ------------------------------------------------------------
* Write results back into the original user-supplied variables
* and cap the number of layers to min(napi, nact).
* ------------------------------------------------------------

local nkeep = `nact'

* Count if we would lose information above nkeep (for warning)
tempname __lost
scalar `__lost' = 0
forvalues j = `= `nkeep' + 1' / 6 {
    local L = cond(`j'==1,"__pri", cond(`j'==2,"__sec", cond(`j'==3,"__ter", ///
                cond(`j'==4,"__quat", cond(`j'==5,"__fif","__six")))))
    capture confirm variable `L'
    if !_rc {
        quietly count if !missing(`L')
        if r(N)>0 scalar `__lost' = `__lost' + r(N)
    }
}

* Overwrite the user's original variables with finalized layers (preserves names)
forvalues i = 1/`nkeep' {
    local L = cond(`i'==1,"__pri", cond(`i'==2,"__sec", cond(`i'==3,"__ter", ///
                cond(`i'==4,"__quat", cond(`i'==5,"__fif","__six")))))
    capture confirm variable `L'
    if !_rc {
        * Ensure type compatibility already handled in build step
        quietly replace `act`i'' = `L'
        * Optionally restore the original variable label
        capture label var `act`i'' "`vlab`i''"
    }
}

* Drop any extra standardized layers above nkeep
forvalues j = `= `nkeep' + 1' / 6 {
    local L = cond(`j'==1,"__pri", cond(`j'==2,"__sec", cond(`j'==3,"__ter", ///
                cond(`j'==4,"__quat", cond(`j'==5,"__fif","__six")))))
    capture drop `L'
}

* Always drop working columns
capture drop ___pri ___sec ___ter ___quat ___fif ___six


* Optional: warn if information was discarded due to layer cap
if (scalar(`__lost') > 0) {
    noi di as res "Note: Additional parallel activities existed above layer " `nkeep' ///
        " and were not preserved in the output (rows: " %9.0f `__lost' ")."
    noi di as txt "      Consider using {cmd:epitrans} first, or rerun with more activity variables."
}

}   // end quietly (main work)
 
* ============================================================
* ERRORSONLY: reassemble full dataset (drop bad diaries, append fixed)
* ============================================================

if (`do_errorsonly'==1) {

    tempfile __fixed_subset
    quietly save "`__fixed_subset'", replace

    quietly use "`__orig'", clear

    * Drop original bad diaries quietly (suppress merge table)
    quietly merge m:1 `did' using "`__baddids'", gen(__m_bad) keep(1 3)
    quietly drop if __m_bad == 3
    quietly drop __m_bad

    * Append quietly, and suppress “label ... already defined”
    quietly append using "`__fixed_subset'", nolabel

    * Fill standardized layers quietly (suppress “missing values generated” / “real changes made”)
    quietly {
        capture confirm string variable `act1'
        local _act_is_string = !_rc

        foreach v in __pri __sec __ter __quat __fif __six {
            capture confirm variable `v'
            if _rc {
                if `_act_is_string' gen strL `v' = ""
                else                 gen double `v' = .
            }
        }

        if "`act1'" != "" replace __pri  = `act1' if missing(__pri)
        if "`act2'" != "" replace __sec  = `act2' if missing(__sec)
        if "`act3'" != "" replace __ter  = `act3' if missing(__ter)
        if "`act4'" != "" replace __quat = `act4' if missing(__quat)
        if "`act5'" != "" replace __fif  = `act5' if missing(__fif)
        if "`act6'" != "" replace __six  = `act6' if missing(__six)

        capture confirm variable start
        if !_rc sort `did' start end
        else    sort `did'
    }
}

 
 * ============================================================
* FINAL CLEANUP (must be AFTER errorsonly reassembly)
* ============================================================
foreach v in __six __fif __quat __ter __sec {
    capture confirm variable `v'
    if !_rc {
        quietly count if !missing(`v')
        if (r(N) == 0) drop `v'
    }
}

// --- Clean summary table output for epifix ---

*---------------------------------------------*
* Count total number of unique diaries
*---------------------------------------------*
tempvar __tagdiary
quietly egen `__tagdiary' = tag(`did')
quietly count if `__tagdiary' == 1
scalar __n_diaries = r(N)

*---------------------------------------------*
* Use pre-fix snapshot for reporting (cases 2–6)
*---------------------------------------------*

scalar __cases2 = cond(missing(__pre_cases2), 0, __pre_cases2)
scalar __cases3 = cond(missing(__pre_cases3), 0, __pre_cases3)
scalar __cases4 = cond(missing(__pre_cases4), 0, __pre_cases4)
scalar __cases5 = cond(missing(__pre_cases5), 0, __pre_cases5)
scalar __cases6 = cond(missing(__pre_cases6), 0, __pre_cases6)
scalar __cases7 = cond(missing(__drop7_rows), 0, __drop7_rows)
scalar __cases8 = cond(missing(__drop8_rows), 0, __drop8_rows)

scalar __total_cases = __cases2 + __cases3 + __cases4 + __cases5 + __cases6 + __cases7 + __cases8

if (`do_fullfix'==1) {
    scalar __cases1   = cond(missing(__pre_cases1),   0, __pre_cases1)
    scalar __diaries1 = cond(missing(__pre_diaries1), 0, __pre_diaries1)
    scalar __total_cases = __total_cases + __cases1
}


if (scalar(__total_cases) == 0) {
    di as txt "No issues detected by epifix."
    if (scalar(__drop78_rows) > 0) {
        di as txt ""
        di as txt "Additionally, dropped " %9.0f __drop78_rows " row(s) with Issue 7/8 (start==end or missing start/end)"
        di as txt "across " %9.0f __drop78_diaries " diary(ies) before applying fixes."
    }
    exit 0
}

scalar __diaries2 = cond(missing(__pre_diaries2), 0, __pre_diaries2)
scalar __diaries3 = cond(missing(__pre_diaries3), 0, __pre_diaries3)
scalar __diaries4 = cond(missing(__pre_diaries4), 0, __pre_diaries4)
scalar __diaries5 = cond(missing(__pre_diaries5), 0, __pre_diaries5)
scalar __diaries6 = cond(missing(__pre_diaries6), 0, __pre_diaries6)


* Union of diaries that had any issue 2..8 BEFORE the drop
scalar __total_diaries = cond(missing(__pre_total_diaries_all), 0, __pre_total_diaries_all)

* Avoid divide-by-zero in % calculations
scalar __den = cond(__n_diaries>0, __n_diaries, .)


*---------------------------------------------*
* Display formatted summary table (Explorer-style)
*---------------------------------------------*

local w1 28   // width for first column with labels
local w2 8
local w3 8
local w4 9

* Title
di as txt "Summary of fixes"
di as txt "---------------------------------------------------------------"

* Header row
di as txt "  " %-`w1's "Issue type"  ///
    " |" %`w2's "Cases"        ///
    " |" %`w3's "Diaries"      ///
    " |" %`w4's "Diaries (%)"

* Header underline
di as txt "-------------------------------+---------+---------+-----------"

* Body (EpiFix scope = cases 2–6 only)
if (`do_fullfix'==1) {
    scalar __cases1   = cond(missing(__pre_cases1),   0, __pre_cases1)
    scalar __diaries1 = cond(missing(__pre_diaries1), 0, __pre_diaries1)

    di as result "  " %-`w1's "Full overlap" ///
        " |" %`w2'.0f __cases1   " |" %`w3'.0f __diaries1   " |" %`w4'.1f (100 * __diaries1 / __n_diaries)
}

di as result "  " %-`w1's "Nested episode"       ///
    " |" %`w2'.0f __cases2   " |" %`w3'.0f __diaries2   " |" %`w4'.1f (100 * __diaries2 / __n_diaries)

di as result "  " %-`w1's "Partial overlap"      ///
    " |" %`w2'.0f __cases3   " |" %`w3'.0f __diaries3   " |" %`w4'.1f (100 * __diaries3 / __n_diaries)

di as result "  " %-`w1's "Gap at min 0"         ///
    " |" %`w2'.0f __cases4   " |" %`w3'.0f __diaries4   " |" %`w4'.1f (100 * __diaries4 / __n_diaries)

di as result "  " %-`w1's "Gap at end of diary"  ///
    " |" %`w2'.0f __cases5   " |" %`w3'.0f __diaries5   " |" %`w4'.1f (100 * __diaries5 / __n_diaries)

di as result "  " %-`w1's "Gap between episodes" ///
    " |" %`w2'.0f __cases6   " |" %`w3'.0f __diaries6   " |" %`w4'.1f (100 * __diaries6 / __n_diaries)

di as result "  " %-`w1's "Row start==end (dropped)" ///
    " |" %`w2'.0f __cases7   " |" %`w3'.0f __drop7_diaries   " |" %`w4'.1f (100 * __drop7_diaries / __n_diaries)

di as result "  " %-`w1's "Missing start/end (dropped)" ///
    " |" %`w2'.0f __cases8   " |" %`w3'.0f __drop8_diaries   " |" %`w4'.1f (100 * __drop8_diaries / __n_diaries)
	
* Footer underline
di as txt "-------------------------------+---------+---------+-----------"

* Total row
di as result "  " %-`w1's "Total" ///
    " |" %`w2'.0f __total_cases ///
    " |" %`w3'.0f __total_diaries ///
    " |" %`w4'.1f (100 * __total_diaries / __n_diaries)

di as txt "---------------------------------------------------------------"

* ------------------------------------------------------------
* User message: where to find the fixed activity variables
* ------------------------------------------------------------
if "`quiet'" == "" {

    * Build a list of the fixed (standardized) activity-layer vars that exist
    local fixedlayers ""
    foreach v in __pri __sec __ter __quat __fif __six {
        capture confirm variable `v'
        if !_rc local fixedlayers "`fixedlayers' `v'"
    }

    * Build a list of the original activity vars passed in (if they still exist)
    local origvars ""
    foreach v of local varlist {
        capture confirm variable `v'
        if !_rc local origvars "`origvars' `v'"
    }

    di as txt ""

    if "`fixedlayers'" != "" {
        di as txt "Fixed activity layers are stored in:" as res "`fixedlayers'"
    }
    else {
        di as err "Warning: no fixed activity-layer variables (__pri, __sec, ...) were found."
    }

    if "`origvars'" != "" & "`fixedlayers'" != "" {
        di as txt "Note: the original activity variables you supplied (" as res "`origvars'" as txt ///
                  ") are still in the dataset."
    }
}

end 
