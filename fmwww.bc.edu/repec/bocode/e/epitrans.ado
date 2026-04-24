

program define epitrans

    version 14
	
syntax varlist(min=1 max=1) , did(varlist) sim(varname) napi(integer) [ dur(varname) ]

local use_dur = "`dur'" != ""

if `use_dur' {
    capture confirm numeric variable `dur'
    if _rc {
        di as err "epitrans: dur() must be a numeric variable containing durations (minutes)."
        exit 198
    }
    quietly count if `dur' < 0
    if r(N) {
        di as err "epitrans: dur() contains negative values; please correct."
        exit 459
    }
}

capture assert inlist(`sim',0,1) | missing(`sim')
if _rc {
    di as err "epitrans: sim() must be coded 0/1 (1=simultaneous; 0 or .=sequential)."
    exit 198
}


local act1 `varlist'

// Store the source value-label name only if act1 is numeric (value labels do not exist for strings)
local __vl_act1 ""
capture confirm numeric variable `act1'
if !_rc {
    local __vl_act1 : value label `act1'
}

* — Keep original row order for stable ranking inside blocks —
tempvar __orig
gen long `__orig' = _n

quietly {
* --- Split off rows to ignore: missing start OR end ---
tempfile __ignored_rows
preserve
    keep if missing(start) | missing(end)
    gen byte __ignored_by_epitrans1 = 1
    count
    scalar __N_ignored = r(N)
    save "`__ignored_rows'", replace
restore

* Work only on valid rows from here on
drop if missing(start) | missing(end)

}
// Robust numeric panel id even if did is string 
*tempvar udid
*egen `udid' = group(`did')
 
	if !inrange(`napi', 1, 6) {
    di as err "napi() must be an integer between 1 and 6"
    exit 198
}

  
    // Check and assign the diary ID
    if "`did'" == "" {
        di as err "Option did() is required"
        exit 198
    }
	
    local did `did'
	
	* ----- Fast early-exit: any full-overlap blocks at all? -----
tempvar __blk0 __need0
egen `__blk0' = group(`did' start end)
bys `__blk0': gen byte `__need0' = (_N >= 2)

quietly count if `__need0'
local __any_full = r(N)

drop `__blk0' `__need0'

if (`__any_full'==0) {
    * Append back the ignored rows (start/end missing) before exiting
    capture confirm file "`__ignored_rows'"
    if !_rc {
        append using "`__ignored_rows'"
        sort `__orig'
        capture confirm scalar __N_ignored
        if !_rc & __N_ignored > 0 {
            di as txt __N_ignored " row(s) ignored by epitrans_dur because start or end was missing (left unchanged)."
        }
    }
    di as txt "Early exit: no fully overlapping (same start/end) blocks found. Nothing to transform."
    * ---- footer message (early-exit) ----
local translayers ""
foreach v in __pri __sec __ter __quat __fif __six {
    capture confirm variable `v'
    if !_rc local translayers "`translayers' `v'"
}
di as txt ""
if "`translayers'" != "" di as txt "Transformed activity layers are stored in:" as res "`translayers'"
di as txt "Note: the original activity variable you supplied (" as res "`act1'" as txt ") has been replaced by the standardized layers above."

	exit 0

}

	quietly {
	
	// ===== Internal layers (type-aware) =====
	capture confirm string variable `act1'
	local _act_is_string = !_rc

// Create/reset __pri..__six with the right type

capture drop ___pri 
capture drop ___sec 
capture drop ___ter 
capture drop ___quat 
capture drop ___fif 
capture drop ___six

if `_act_is_string' {
    gen strL ___pri = ""
    gen strL ___sec = ""
    gen strL ___ter = ""
    gen strL ___quat = ""
    gen strL ___fif = ""
    gen strL ___six = ""
}
else {
    gen double ___pri = .
    gen double ___sec = .
    gen double ___ter = .
    gen double ___quat = .
    gen double ___fif = .
    gen double ___six = .
}


// Copy provided activity vars into the layers (others remain empty)

/* Copy provided activity var into primary (others stay empty until/if transformed) */
replace ___pri = `act1'


*----------------------------------------------------------
* Enforce napi(): cap TOTAL activities per (did,start,end) block
*   - Rank rows within each block using your existing order
*   - Keep the first `napi' rows; drop rows with rank > `napi'
*----------------------------------------------------------
tempvar __blk 

egen `__blk' = group(`did' start end)


* --- Isolated sim==1 blocks (size==1) → recode to 0 and report ---
tempvar __iso1
bysort `__blk': gen byte `__iso1' = (_N==1 & `sim'==1)

quietly count if `__iso1'
scalar ISO_sim1_recode = r(N)

tempvar __iso1_diary
bys `did': egen byte `__iso1_diary' = max(`__iso1')
tempvar __dtag_iso
egen byte `__dtag_iso' = tag(`did')
quietly count if `__dtag_iso' & `__iso1_diary'
scalar Diaries___ISO_sim1_recode = r(N)
drop `__dtag_iso'

drop `__iso1_diary'

replace `sim' = 0 if `__iso1'
drop `__iso1'

* Treat missing sim in fully-overlapping blocks as sequential (0), and count them
tempvar __blk_size
bysort `__blk' (`__orig'): egen `__blk_size' = count(_n)

quietly count if (`__blk_size' >= 2) & missing(`sim')
scalar SIM_miss_in_overlaps = r(N)

replace `sim' = 0 if (`__blk_size' >= 2) & missing(`sim')

drop `__blk_size'
* Use your existing within-start order as the stable ordering key
* Rank rows inside each block using that order
tempvar __blk_rank
bysort `__blk' (`__orig'): gen `__blk_rank' = _n


* Flag rows beyond the allowed count
tempvar __dropflag
gen byte `__dropflag' = (`__blk_rank' > `napi')

* --- Reporting BEFORE drop ---
quietly count if `__dropflag'
scalar __overN_removed = r(N)

tempvar __dflag_overN
bys `did': egen byte `__dflag_overN' = max(`__dropflag')

tempvar _dflag_tag
gen byte `_dflag_tag' = 0
*bys `did' (start): replace `_dflag_tag' = 1 if `__dflag_overN' == 1 & _n == 1
*quietly count if `_dflag_tag'
egen byte _dtag_overN = tag(`did')
count if _dtag_overN & `__dflag_overN'
scalar Diaries___overN_removed = r(N)
drop _dtag_overN

scalar Diaries___overN_removed = r(N)

* Optional cleanup of helper markers for over-N reporting
capture drop `_dflag_tag' `__dflag_overN'

* --- Drop extras ---
drop if `__dropflag'
drop `__dropflag'

* If downstream code depends on group/anumber/simsize, refresh them now
tempvar onumber 
bysort `__blk' (`__orig'): gen `onumber' = _n


* --- Decide what to transform: any (did,start,end) block with >=2 rows ---

* --- Transform fully-overlapping blocks that are homogeneous in sim (all 1 OR all 0) ---
tempvar __bsize2 __bmin2 __bmax2 totransform __needtag
bysort `__blk' (`__orig'): egen `__bsize2'  = count(_n)
bysort `__blk' (`__orig'): egen `__bmin2'   = min(`sim')
bysort `__blk' (`__orig'): egen `__bmax2'   = max(`sim')

* Work to do = any fully-overlapping block using only {0,1} flags (homogeneous OR mixed)
gen byte `totransform' = (`__bsize2' >= 2) ///
                      & inlist(`__bmin2',0,1) & inlist(`__bmax2',0,1)

egen `__needtag' = tag(`__blk') if `totransform'
quietly count if `__needtag'
local _need_transform = r(N)
drop `__needtag' `__bsize2' `__bmin2' `__bmax2'

capture confirm scalar __overN_removed
if _rc scalar __overN_removed = 0

if (`_need_transform'==0 & __overN_removed==0) {
    di as txt "Early exit: no eligible fully-overlapping blocks (using only {0,1}) to transform."
    * ---- footer message (early-exit) ----
local translayers ""
foreach v in __pri __sec __ter __quat __fif __six {
    capture confirm variable `v'
    if !_rc local translayers "`translayers' `v'"
}
di as txt ""
if "`translayers'" != "" di as txt "Transformed activity layers are stored in:" as res "`translayers'"
di as txt "Note: the original activity variable you supplied (" as res "`act1'" as txt ") has been replaced by the standardized layers above."

	
	exit 0

}

tempfile sample
save "`sample'"

* ---- getting the starting parameters -----
	
*---------------------------------------
* 0) Helper variables (safe to re-run)
*---------------------------------------
capture drop _blk _btag _bsize _bmin _bmax _dtag_all _dflag
egen _blk   = group(`did' start end)
bys _blk: gen  byte _btag  = (_n==1)
bys _blk: egen       _bsize = count(_n)
bys _blk: egen       _bmin  = min(`sim')
bys _blk: egen       _bmax  = max(`sim')

egen _dtag_all = tag(`did')
quietly count if _dtag_all
scalar __D_total = r(N)

capture confirm scalar Diaries___overN_removed
if !_rc {
    scalar Pct___overN_removed = 100 * Diaries___overN_removed / __D_total
}

*---------------------------------------
* 1) TOTAL overlaps: _bsize >= 2
*---------------------------------------
quietly count if _btag==1 & _bsize>=2
scalar __total = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize>=2)
quietly count if _dtag_all & _dflag
scalar Diaries___total = r(N)
scalar Pct___total     = 100 * Diaries___total / __D_total

*---------------------------------------
* 2) Exactly 2 episodes
*---------------------------------------
quietly count if _btag==1 & _bsize==2
scalar __m2 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize==2)
quietly count if _dtag_all & _dflag
scalar Diaries___m2 = r(N)
scalar Pct___m2     = 100 * Diaries___m2 / __D_total

*---------------------------------------
* 3) Exactly 3 episodes
*---------------------------------------
quietly count if _btag==1 & _bsize==3
scalar __m3 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize==3)
quietly count if _dtag_all & _dflag
scalar Diaries___m3 = r(N)
scalar Pct___m3     = 100 * Diaries___m3 / __D_total

*---------------------------------------
* 4) Exactly 4 episodes
*---------------------------------------
quietly count if _btag==1 & _bsize==4
scalar __m4 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize==4)
quietly count if _dtag_all & _dflag
scalar Diaries___m4 = r(N)
scalar Pct___m4     = 100 * Diaries___m4 / __D_total

*---------------------------------------
* 5) Exactly 5 episodes
*---------------------------------------
quietly count if _btag==1 & _bsize==5
scalar __m5 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize==5)
quietly count if _dtag_all & _dflag
scalar Diaries___m5 = r(N)
scalar Pct___m5     = 100 * Diaries___m5 / __D_total

*---------------------------------------
* 6) Exactly 6 episodes  (change to >=6 if you want "6+")
*---------------------------------------
quietly count if _btag==1 & _bsize==6
scalar __m6 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize==6)
quietly count if _dtag_all & _dflag
scalar Diaries___m6 = r(N)
scalar Pct___m6     = 100 * Diaries___m6 / __D_total

*---------------------------------------
* 7) All sim==1 within block (with overlaps)
*---------------------------------------
quietly count if _btag==1 & _bsize>=2 & _bmin==1 & _bmax==1
scalar __allsim1 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize>=2 & _bmin==1 & _bmax==1)
quietly count if _dtag_all & _dflag
scalar Diaries___allsim1 = r(N)
scalar Pct___allsim1     = 100 * Diaries___allsim1 / __D_total

*---------------------------------------
* 8) All sim==0 within block (with overlaps)
*---------------------------------------
quietly count if _btag==1 & _bsize>=2 & _bmin==0 & _bmax==0
scalar __allsim0 = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize>=2 & _bmin==0 & _bmax==0)
quietly count if _dtag_all & _dflag
scalar Diaries___allsim0 = r(N)
scalar Pct___allsim0     = 100 * Diaries___allsim0 / __D_total

*---------------------------------------
* 9) Mixed sim==0/1 within block (with overlaps)
*---------------------------------------
quietly count if _btag==1 & _bsize>=2 & _bmin==0 & _bmax==1
scalar __mixedsims = r(N)

capture drop _dflag
bys `did': egen byte _dflag = max(_btag==1 & _bsize>=2 & _bmin==0 & _bmax==1)
quietly count if _dtag_all & _dflag
scalar Diaries___mixedsims = r(N)
scalar Pct___mixedsims     = 100 * Diaries___mixedsims / __D_total


*Transforming the episodes:

use "`sample'", clear
keep if `totransform'==0
sort `__blk' `onumber' 
tempfile transform0
save "`transform0'"

use "`sample'", clear
keep if `totransform'==1

* --- Enforce contiguity rule for sim==1 inside each fully-overlapping block ---
* 1) Recode isolated 1's (no adjacent 1 within the block) -> 0
tempvar __prev1 __next1 __iso1within
bysort `__blk' (`onumber'): gen byte `__prev1' = (_n>1  & `sim'[_n-1]==1)
bysort `__blk' (`onumber'): gen byte `__next1' = (_n<_N & `sim'[_n+1]==1)

gen byte `__iso1within' = (`sim'==1) & !`__prev1' & !`__next1'

quietly count if `__iso1within'
scalar ISO_sim1_withinblock = r(N)

tempvar __iso1wb_diary
bys `did': egen byte `__iso1wb_diary' = max(`__iso1within')

tempvar __dtag_wb
egen byte `__dtag_wb' = tag(`did')
quietly count if `__dtag_wb' & `__iso1wb_diary'
scalar Diaries___ISO_sim1_withinblock = r(N)
drop `__dtag_wb'

drop `__iso1wb_diary'

replace `sim' = 0 if `__iso1within'
drop `__prev1' `__next1' `__iso1within'


* 2) Identify runs of sim==1 (allow multiple runs; do NOT force sequential)
tempvar __start1 __runid __runfirst
bysort `__blk' (`onumber'): gen byte `__start1'  = (`sim'==1) & (_n==1 | `sim'[_n-1]!=1)
bysort `__blk' (`onumber'): gen int  `__runid'   = sum(`__start1')          // 0 for seq rows; 1..R for sim runs
gen byte `__runfirst' = (`sim'==1) & (`__start1'==1)
drop `__start1'


* -- Clear all activity columns for rows to transform, respecting type --
if `_act_is_string' {
    foreach c in ___pri ___sec ___ter ___quat ___fif ___six {
        replace `c' = "" if `totransform'==1
    }
}
else {
    foreach c in ___pri ___sec ___ter ___quat ___fif ___six {
        replace `c' = .  if `totransform'==1
    }
}

* -- Fill columns from the episode's activity by position within the block --
* ===== 3a-2 Equal split for pure sequential blocks =====

* Re-identify type of each block within the totransform==1 subset
tempvar __bminT __bmaxT __is_seqblk __is_simblk __is_mixedblk

bysort `__blk' (`__orig'): egen `__bminT' = min(`sim')
bysort `__blk' (`__orig'): egen `__bmaxT' = max(`sim')

gen byte `__is_seqblk' = (`__bminT'==0 & `__bmaxT'==0)
gen byte `__is_simblk' = (`__bminT'==1 & `__bmaxT'==1)

gen byte `__is_mixedblk' = (`__bminT'==0 & `__bmaxT'==1)

* 3a-1) Assign activities to layers:

if `_act_is_string' {
    replace ___pri  = "" if `__is_simblk'
    replace ___sec  = "" if `__is_simblk'
    replace ___ter  = "" if `__is_simblk'
    replace ___quat = "" if `__is_simblk'
    replace ___fif  = "" if `__is_simblk'
    replace ___six  = "" if `__is_simblk'
}
else {
    replace ___pri  = .  if `__is_simblk'
    replace ___sec  = .  if `__is_simblk'
    replace ___ter  = .  if `__is_simblk'
    replace ___quat = .  if `__is_simblk'
    replace ___fif  = .  if `__is_simblk'
    replace ___six  = .  if `__is_simblk'
}

* Now assign the activity to the appropriate layer by position
replace ___pri  = `act1' if `__is_simblk' & `onumber'==1
replace ___sec  = `act1' if `__is_simblk' & `onumber'==2
replace ___ter  = `act1' if `__is_simblk' & `onumber'==3
replace ___quat = `act1' if `__is_simblk' & `onumber'==4
replace ___fif  = `act1' if `__is_simblk' & `onumber'==5
replace ___six  = `act1' if `__is_simblk' & `onumber'==6

* For SIM blocks: gather each layer's value onto every row, so row 1 has all layers
foreach V in ___pri ___sec ___ter ___quat ___fif ___six {
    capture confirm variable `V'
    if _rc continue
    tempvar _tmp _miss
    clonevar `_tmp' = `V'
    gen byte `_miss' = missing(`_tmp')
    bysort `__blk' (`_miss' `onumber'): replace `_tmp' = `_tmp'[1] if `__is_simblk'
    drop `V'
    rename `_tmp' `V'
}


*  - For SEQUENTIAL (but overlapping) blocks: keep each row's activity in PRIMARY only
*    (blank other layers so you don't get "secondary-only" rows)
if `_act_is_string' {
    replace ___pri  = `act1' if `__is_seqblk'
    replace ___sec  = ""     if `__is_seqblk'
    replace ___ter  = ""     if `__is_seqblk'
    replace ___quat = ""     if `__is_seqblk'
    replace ___fif  = ""     if `__is_seqblk'
    replace ___six  = ""     if `__is_seqblk'
}
else {
    replace ___pri  = `act1' if `__is_seqblk'
    replace ___sec  = .      if `__is_seqblk'
    replace ___ter  = .      if `__is_seqblk'
    replace ___quat = .      if `__is_seqblk'
    replace ___fif  = .      if `__is_seqblk'
    replace ___six  = .      if `__is_seqblk'
}

* ---------- Mixed blocks: layer sim rows; keep seq rows primary-only ----------
* Position among sim==1 rows (1,2,3,...) within the block
tempvar _simpos
bysort `__blk' `__runid' (`onumber'): gen int `_simpos' = sum(`sim'==1) if `__is_mixedblk' & `__runid'>0

* Clear layers for mixed sim rows; set by position
if `_act_is_string' {
    foreach c in ___pri ___sec ___ter ___quat ___fif ___six {
        replace `c' = "" if `__is_mixedblk' & `sim'==1
    }
}
else {
    foreach c in ___pri ___sec ___ter ___quat ___fif ___six {
        replace `c' = .  if `__is_mixedblk' & `sim'==1
    }
}

replace ___pri  = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==1
replace ___sec  = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==2
replace ___ter  = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==3
replace ___quat = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==4
replace ___fif  = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==5
replace ___six  = `act1' if `__is_mixedblk' & `sim'==1 & `_simpos'==6

* Broadcast layered values so the first sim row holds all layers later
foreach V in ___pri ___sec ___ter ___quat ___fif ___six {
    tempvar _tmp _miss
    clonevar `_tmp' = `V'
    gen byte `_miss' = missing(`_tmp')
    bysort `__blk' `__runid' (`_miss' `_simpos'): replace `_tmp' = `_tmp'[1] if `__is_mixedblk' & `sim'==1 & `__runid'>0
   drop `V'
    rename `_tmp' `V'
}

* For mixed sequential rows: keep only primary
if `_act_is_string' {
    foreach c in ___sec ___ter ___quat ___fif ___six {
        replace `c' = ""  if `__is_mixedblk' & `sim'==0
    }
    replace ___pri = `act1' if `__is_mixedblk' & `sim'==0
}
else {
    foreach c in ___sec ___ter ___quat ___fif ___six {
        replace `c' = .   if `__is_mixedblk' & `sim'==0
    }
    replace ___pri = `act1' if `__is_mixedblk' & `sim'==0
}




* ----- Mixed-block timing: handle multiple sim runs + sequential rows -----
* Build phases = each sim run (first row of the run) + each seq row
tempvar __nruns __nseq __phases __T __phaseflag __phaseix __phasedur __cumdur __pstart __pend
bysort `__blk' (`__orig'): egen int `__nruns' = max(`__runid') if `__is_mixedblk'
bysort `__blk' (`__orig'): egen int `__nseq'  = total(`sim'==0)  if `__is_mixedblk'
gen int `__phases' = `__nruns' + `__nseq' if `__is_mixedblk'
gen double `__T'   = end - start if `__is_mixedblk'

* Mark the phase rows (seq rows + first row of each sim run)
gen byte `__phaseflag' = 0
replace `__phaseflag' = 1 if `__is_mixedblk' & (`sim'==0 | `__runfirst')

* Phase order within block
bysort `__blk' (`onumber'): gen int `__phaseix' = sum(`__phaseflag') if `__is_mixedblk'

* Phase durations: from dur() if provided, else equal phases
gen double `__phasedur' = .

if `use_dur' {
    * Sequential rows: phase duration is their own dur
    replace `__phasedur' = `dur' if `__is_mixedblk' & `__phaseflag' & `sim'==0

    /* Simultaneous runs: phase duration is the SUM of dur within the run, assigned to run-first
    tempvar __rundur
    bysort `__blk' `__runid': egen double `__rundur' = total(`dur') ///
        if `__is_mixedblk' & `sim'==1 & `__runid'>0
    replace `__phasedur' = `__rundur' if `__is_mixedblk' & `__runfirst'
    drop `__rundur' */

* Simultaneous runs: phase duration should be the OVERLAP time, not the sum.
* Use MAX(dur) within the run (usually all equal anyway), assigned to run-first.
tempvar __rundur
bysort `__blk' `__runid': egen double `__rundur' = max(`dur')
replace `__phasedur' = `__rundur' if `__is_mixedblk' & `__runfirst'
drop `__rundur'

    * Scale to match block length if needed (and enforce integer minutes)
	tempvar __sumphase __scale __base
    bysort `__blk': egen double `__sumphase' = total(cond(`__phaseflag', `__phasedur', 0)) if `__is_mixedblk'
    gen double `__scale' = cond(`__sumphase'>0, `__T'/`__sumphase', .) if `__is_mixedblk'
    replace `__phasedur' = `__phasedur' * `__scale' if `__is_mixedblk' & `__phaseflag'
* floor to minutes, then distribute leftover minutes to earliest phases
gen double `__base' = floor(`__phasedur') if `__is_mixedblk' & `__phaseflag'

* sum of floored minutes across phases in the block
tempvar __sumbase __resid __ord __takeextra
bysort `__blk': egen double `__sumbase' = total(cond(`__phaseflag', `__base', 0)) if `__is_mixedblk'

* integer remainder to distribute so that sum(phasedur) == block length `__T'
gen double `__resid' = `__T' - `__sumbase' if `__is_mixedblk'

* give +1 minute to the first round(`__resid') phases in left-to-right order
bysort `__blk' (`__phaseix'): gen int `__ord' = _n if `__is_mixedblk' & `__phaseflag'
gen byte `__takeextra' = (`__ord' <= round(`__resid')) if `__is_mixedblk' & `__phaseflag'

replace `__phasedur' = `__base' + `__takeextra' if `__is_mixedblk' & `__phaseflag'

drop `__sumbase' `__resid' `__ord' `__takeextra' `__base'

   
}
else {
    * Original equal-phase split when no dur()
    tempvar __basedur __extra
    gen double `__basedur' = floor(`__T'/`__phases') if `__is_mixedblk'
    gen double `__extra'   = `__T' - `__basedur'*`__phases' if `__is_mixedblk'
    replace `__phasedur'   = `__basedur' + (`__phaseix'<=`__extra') if `__is_mixedblk' & `__phaseflag'
    drop `__basedur' `__extra'
}

* Build cumulative phase boundaries and apply
bysort `__blk' (`onumber'): gen double `__cumdur' = sum(cond(`__phaseflag', `__phasedur', 0)) if `__is_mixedblk'

bysort `__blk' (`onumber'): ///
    gen double `__pstart' = start[1] + (`__cumdur' - cond(`__phaseflag', `__phasedur', 0)) if `__is_mixedblk' & `__phaseflag'

bysort `__blk' (`onumber'): ///
    gen double `__pend'   = start[1] +  `__cumdur' if `__is_mixedblk' & `__phaseflag'

* Apply to rows (same pattern as your original code)
replace start = `__pstart' if `__is_mixedblk' & `sim'==0
replace end   = `__pend'   if `__is_mixedblk' & `sim'==0

replace start = `__pstart' if `__is_mixedblk' & `__runfirst'
replace end   = `__pend'   if `__is_mixedblk' & `__runfirst'
bysort `__blk' `__runid' (`onumber'): replace start = start[1] if `__is_mixedblk' & `sim'==1 & `__runid'>0
bysort `__blk' `__runid' (`onumber'): replace end   = end[1]   if `__is_mixedblk' & `sim'==1 & `__runid'>0

drop `__nruns' `__nseq' `__phases' `__T' `__phaseflag' `__phaseix' `__phasedur' `__cumdur' `__pstart' `__pend'



* 3a-2) Equal split of each block's time across its n rows (single pass)
* ===== Sequential blocks: allocate time (dur() if given; else equal split) =====
tempvar actno nacts totaltime dur_use cum new_start new_end

bysort `__blk' (`__orig'): gen `actno' = _n
bysort `__blk' (`__orig'): gen `nacts' = _N

gen double `totaltime' = end - start if `__is_seqblk'

if `use_dur' {
    * Use provided durations within block; scale to match block length; enforce integer minutes
    tempvar _sumdur _share _ideal _base _resid _ord _takeextra
    bysort `__blk' (`__orig'): egen double `_sumdur' = total(`dur') if `__is_seqblk'
    gen double `_share' = cond(`_sumdur'>0, `dur'/`_sumdur', .) if `__is_seqblk'
    gen double `_ideal' = `_share' * `totaltime' if `__is_seqblk'
    gen double `_base'  = floor(`_ideal')       if `__is_seqblk'

    bysort `__blk': egen double `_resid' = total(`_ideal' - `_base') if `__is_seqblk'
    bysort `__blk' (`actno'): gen int `_ord' = _n if `__is_seqblk'
    gen byte `_takeextra' = (`_ord' <= round(`_resid')) if `__is_seqblk'

    gen double `dur_use' = cond(missing(`_base'), ., `_base' + `_takeextra') if `__is_seqblk'

    * Fallback to equal split if all dur are zero/missing in the block
    replace `dur_use' = . if `__is_seqblk' & `_sumdur'==0
}

if !`use_dur' {
    tempvar base_dur extra
    gen double `base_dur' = floor(`totaltime' / `nacts') if `__is_seqblk'
    gen double `extra'    = `totaltime' - `base_dur' * `nacts' if `__is_seqblk'
    gen double `dur_use'  = `base_dur' if `__is_seqblk'
    bysort `__blk' (`actno'): replace `dur_use' = `base_dur' + 1 if `__is_seqblk' & `actno' <= `extra'
}
else {
    * fallback only where no usable dur() was available in the block
    tempvar base_dur extra
    gen double `base_dur' = floor(`totaltime' / `nacts') if `__is_seqblk' & missing(`dur_use')
    gen double `extra'    = `totaltime' - `base_dur' * `nacts' if `__is_seqblk' & missing(`dur_use')
    replace `dur_use' = `base_dur' if `__is_seqblk' & missing(`dur_use')
    bysort `__blk' (`actno'): replace `dur_use' = `base_dur' + 1 if `__is_seqblk' & missing(`dur_use') & `actno' <= `extra'
}

* Build cumulative to set new [start,end]
bysort `__blk' (`actno'): gen double `cum'        = sum(`dur_use') if `__is_seqblk'
bysort `__blk' (`actno'): gen double `new_start'  = start[1] + (`cum' - `dur_use') if `__is_seqblk'
bysort `__blk' (`actno'): gen double `new_end'    = start[1] +  `cum'              if `__is_seqblk'
drop `cum'

replace start = `new_start' if `__is_seqblk'
replace end   = `new_end'   if `__is_seqblk'
drop `new_start' `new_end'


tempvar _keep_mixed
gen byte `_keep_mixed' = 0
replace `_keep_mixed' = 1 if `__is_mixedblk' & (`sim'==0 | `__runfirst')

keep if `__is_seqblk' | (`__is_simblk' & `onumber'==1) | `_keep_mixed'
drop `_keep_mixed'



sort `__blk' `onumber'
tempfile transform1
save "`transform1'"

	
use "`transform0'", clear
append using "`transform1'"

sort `__blk' `onumber'

* — Restore original row order across the whole dataset —
sort `__orig'

/* copy working columns → official __pri … __six   */
* Ensure targets exist (create if missing), then copy working → official

/* __pri */
capture drop __pri
if `_act_is_string' gen strL __pri = ""
else                gen double __pri = .
replace __pri = ___pri

/* __sec */
capture drop __sec
if `_act_is_string' gen strL __sec = ""
else                gen double __sec = .
replace __sec = ___sec

/* __ter */
capture drop __ter
if `_act_is_string' gen strL __ter = ""
else                gen double __ter = .
replace __ter = ___ter

/* __quat */
capture drop __quat
if `_act_is_string' gen strL __quat = ""
else                gen double __quat = .
replace __quat = ___quat

/* __fif */
capture drop __fif
if `_act_is_string' gen strL __fif = ""
else                gen double __fif = .
replace __fif = ___fif

/* __six */
capture drop __six
if `_act_is_string' gen strL __six = ""
else                gen double __six = .
replace __six = ___six

// Reattach value labels to the new activity-layer variables (numeric only; and only if act1 had a value label)
if "`__vl_act1'" != "" {
    capture label values __pri  `__vl_act1'
    capture label values __sec  `__vl_act1'
    capture label values __ter  `__vl_act1'
    capture label values __quat `__vl_act1'
    capture label values __fif  `__vl_act1'
    capture label values __six  `__vl_act1'
}

* Blank layered columns for sequential (sim==0) blocks AFTER copying ___* -> __*
tempvar __is_seqblk2
//bysort `__blk': egen byte `__is_seqblk2' = (min(`sim')==0 & max(`sim')==0)

tempvar __bmin2 __bmax2
egen `__bmin2' = min(`sim'), by(`__blk')
egen `__bmax2' = max(`sim'), by(`__blk')
gen byte `__is_seqblk2' = (`__bmin2'==0 & `__bmax2'==0)
drop `__bmin2' `__bmax2'

if `_act_is_string' {
    foreach v in __sec __ter __quat __fif __six {
        capture confirm variable `v'
        if !_rc replace `v' = "" if `__is_seqblk2'
    }
}
else {
    foreach v in __sec __ter __quat __fif __six {
        capture confirm variable `v'
        if !_rc replace `v' = . if `__is_seqblk2'
    }
}
drop `__is_seqblk2'

/* Drop extra layers as per napi() */
if `napi'==1 {
    capture drop __sec __ter __quat __fif __six
}
else if `napi'==2 {
    capture drop __ter __quat __fif __six
}
else if `napi'==3 {
    capture drop __quat __fif __six
}
else if `napi'==4 {
    capture drop __fif __six
}
else if `napi'==5 {
    capture drop __six
}

/* Labels (optional) */
capture label var __pri  "Primary activity"
capture label var __sec  "Secondary activity"
capture label var __ter  "Tertiary activity"
capture label var __quat "Quaternary activity"
capture label var __fif  "Fifth activity"
capture label var __six  "Sixth activity"

/* (optional) drop working columns once copied */
capture drop ___pri 
capture drop ___sec 
capture drop ___ter 
capture drop ___quat 
capture drop ___fif 
capture drop ___six

drop `act1'
drop `sim'

        order `did' start end __pri 
capture order `did' start end __pri __sec
capture order `did' start end __pri __sec __ter
capture order `did' start end __pri __sec __ter __quat
capture order `did' start end __pri __sec __ter __quat __fif 
capture order `did' start end __pri __sec __ter __quat __fif __six


* --- Append back the ignored rows unchanged and restore original order ---
capture confirm file "`__ignored_rows'"
if !_rc {
    append using "`__ignored_rows'"
    * If any vars created later don't exist on ignored rows, they’ll be missing — that's fine.
}

* Restore original row order across the whole dataset
sort `__orig'

* Optional: report how many were ignored
capture confirm scalar __N_ignored
if !_rc & __N_ignored > 0 {
 
	di as txt __N_ignored " row(s) ignored by epitrans_dur because start or end was missing (left unchanged)."

}



} // end of quietly?

*Report here*


di as txt "Summary of transformations:"

if `use_dur' {
    quietly count if `totransform'==1 & missing(`dur')
    if r(N) > 0 {
        di as txt r(N) " transformed row(s) had missing dur(); epitrans_dur used equal split within those blocks."
    }
}

di as text "---------------------------------------------------"
di as text "N. of overlaps" _col(23) "Blocks" _col(34) "Diaries" _col(45) "%"
di as text "---------------------------------------------------"

* Rows for 2..napi episodes (numbers in yellow)
if `napi' >= 2 {
    forvalues _k = 2/`napi' {
        di as text %-20s "`_k' episodes"  ///
            as text " " as result %8.0f __m`_k'              ///
            as text " " as result %8.0f Diaries___m`_k'      ///
            as text " " as result %6.1f Pct___m`_k'
    }
}

di as text "---------------------------------------------------"
di as text %-20s "Total"  ///
    as text " " as result %8.0f __total              ///
    as text " " as result %8.0f Diaries___total      ///
    as text " " as result %6.1f Pct___total

di as text ""
di as text "N by sim type" _col(23) "Blocks" _col(34) "Diaries" _col(45) "%"
di as text "---------------------------------------------------"

di as text %-20s "All simultaneous"  ///
    as text " " as result %8.0f __allsim1              ///
    as text " " as result %8.0f Diaries___allsim1      ///
    as text " " as result %6.1f Pct___allsim1

di as text %-20s "All sequential"  ///
    as text " " as result %8.0f __allsim0              ///
    as text " " as result %8.0f Diaries___allsim0      ///
    as text " " as result %6.1f Pct___allsim0

di as text %-20s "Mixed"  ///
    as text " " as result %8.0f __mixedsims            ///
    as text " " as result %8.0f Diaries___mixedsims    ///
    as text " " as result %6.1f Pct___mixedsims

di as text "---------------------------------------------------"
di as text %-20s "Total"  ///
    as text " " as result %8.0f __total              ///
    as text " " as result %8.0f Diaries___total      ///
    as text " " as result %6.1f Pct___total
di as text "---------------------------------------------------"
di as txt ""


* Conditionally display over-napi drops
capture confirm scalar __overN_removed
capture confirm scalar Diaries___overN_removed
capture confirm scalar Pct___overN_removed

if !_rc & __overN_removed > 0 {
    di as txt "Some episodes were removed because they exceeded the number of episodes allowed per interval. This applied to " ///
        __overN_removed " cases, affecting " ///
        Diaries___overN_removed " diary(ies), " ///
        %4.1f Pct___overN_removed "% of all diaries."
}

* -- Report isolated sim==1 → 0 recodes
capture confirm scalar ISO_sim1_recode
capture confirm scalar Diaries___ISO_sim1_recode
if !_rc & ISO_sim1_recode > 0 {
    di as txt ISO_sim1_recode " isolated episode(s) had sim==1 without a pair; epitrans treated them as sequential (sim=0)."
    di as txt "This affected " Diaries___ISO_sim1_recode " diary(ies)."
}

* -- Report isolated-within-block sim==1 -> 0 recodes
capture confirm scalar ISO_sim1_withinblock
capture confirm scalar Diaries___ISO_sim1_withinblock
if !_rc & ISO_sim1_withinblock > 0 {
    di as txt ISO_sim1_withinblock " episode(s) had noncontiguous sim==1 inside a block; recoded to 0."
    di as txt "This affected " Diaries___ISO_sim1_withinblock " diary(ies)."
}


* -- Report missing-sim assumptions made in overlapping blocks
capture confirm scalar SIM_miss_in_overlaps
if !_rc & SIM_miss_in_overlaps > 0 {
    di as txt SIM_miss_in_overlaps ///
        " episode(s) had sim==., epitrans replaced those by 0 (assuming sequentiality). If that was not intended, please correct sim before running epitrans."
}

qui capture drop __ignored_by_epitrans1

* ------------------------------------------------------------
* User message: where to find the transformed activity variables
* ------------------------------------------------------------

* Build list of standardized activity layers that exist
local translayers ""
foreach v in __pri __sec __ter __quat __fif __six {
    capture confirm variable `v'
    if !_rc local translayers "`translayers' `v'"
}

di as txt ""

if "`translayers'" != "" {
    di as txt "epitrans finished."
    di as txt "Transformed activity layers are stored in:" as res "`translayers'"
}

capture confirm variable `act1'
di as txt "Note: the original activity variable you supplied (" ///
    as res "`act1'" as txt ") has been replaced by the standardized layers above."


end 




