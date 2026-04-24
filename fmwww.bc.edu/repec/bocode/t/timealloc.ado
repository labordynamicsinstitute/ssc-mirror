program timealloc
    version 11

    // Up to 6 activity variables; shares() is optional
    syntax varlist(min=1 max=6 numeric), did(varlist) [ shares(string) ]

    // --- Identify activity variables ---
    tokenize `varlist'
    local activity `1'              // unified activity name used in your aggregation
    local a1 `1'
    local a2 : word 2 of `varlist'
    local a3 : word 3 of `varlist'
    local a4 : word 4 of `varlist'
    local a5 : word 5 of `varlist'
    local a6 : word 6 of `varlist'
    
	local nvars : word count `varlist'
	local do_counts = (`nvars'==1)
    local have_shares = ("`shares'" != "")
	
	
	    // --- Fix misordered activities within row: shift non-missing values left ---
    tempvar __gapflag
    gen byte `__gapflag' = 0

    quietly {
        if `nvars' >= 2 {
            replace `__gapflag' = 1 if missing(`a1') & !missing(`a2')
        }
        if `nvars' >= 3 {
            replace `__gapflag' = 1 if (missing(`a1') & !missing(`a3')) | ///
                                     (missing(`a2') & !missing(`a3'))
        }
        if `nvars' >= 4 {
            replace `__gapflag' = 1 if (missing(`a1') & !missing(`a4')) | ///
                                     (missing(`a2') & !missing(`a4')) | ///
                                     (missing(`a3') & !missing(`a4'))
        }
        if `nvars' >= 5 {
            replace `__gapflag' = 1 if (missing(`a1') & !missing(`a5')) | ///
                                     (missing(`a2') & !missing(`a5')) | ///
                                     (missing(`a3') & !missing(`a5')) | ///
                                     (missing(`a4') & !missing(`a5'))
        }
        if `nvars' >= 6 {
            replace `__gapflag' = 1 if (missing(`a1') & !missing(`a6')) | ///
                                     (missing(`a2') & !missing(`a6')) | ///
                                     (missing(`a3') & !missing(`a6')) | ///
                                     (missing(`a4') & !missing(`a6')) | ///
                                     (missing(`a5') & !missing(`a6'))
        }

        count if `__gapflag' == 1
        local ngap = r(N)

        if `ngap' > 0 {
            tempvar __b1 __b2 __b3 __b4 __b5 __b6
            gen double `__b1' = .
            gen double `__b2' = .
            gen double `__b3' = .
            gen double `__b4' = .
            gen double `__b5' = .
            gen double `__b6' = .

            // Fill compacted positions left-to-right, preserving original order
            replace `__b1' = `a1' if !missing(`a1')
            replace `__b1' = `a2' if missing(`__b1') & !missing(`a2')
            if `nvars' >= 3 replace `__b1' = `a3' if missing(`__b1') & !missing(`a3')
            if `nvars' >= 4 replace `__b1' = `a4' if missing(`__b1') & !missing(`a4')
            if `nvars' >= 5 replace `__b1' = `a5' if missing(`__b1') & !missing(`a5')
            if `nvars' >= 6 replace `__b1' = `a6' if missing(`__b1') & !missing(`a6')

            if `nvars' >= 2 {
                replace `__b2' = `a2' if !missing(`a1') & !missing(`a2')
                if `nvars' >= 3 replace `__b2' = `a3' if missing(`__b2') & !missing(`a3') ///
                    & ((!missing(`a1')) + (!missing(`a2')) >= 1)
                if `nvars' >= 4 replace `__b2' = `a4' if missing(`__b2') & !missing(`a4') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) >= 1)
                if `nvars' >= 5 replace `__b2' = `a5' if missing(`__b2') & !missing(`a5') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) >= 1)
                if `nvars' >= 6 replace `__b2' = `a6' if missing(`__b2') & !missing(`a6') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) + (!missing(`a5')) >= 1)
            }

            if `nvars' >= 3 {
                replace `__b3' = `a3' if (!missing(`a1') + !missing(`a2') + !missing(`a3') >= 3)
                if `nvars' >= 4 replace `__b3' = `a4' if missing(`__b3') & !missing(`a4') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) >= 2)
                if `nvars' >= 5 replace `__b3' = `a5' if missing(`__b3') & !missing(`a5') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) >= 2)
                if `nvars' >= 6 replace `__b3' = `a6' if missing(`__b3') & !missing(`a6') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) + (!missing(`a5')) >= 2)
            }

            if `nvars' >= 4 {
                replace `__b4' = `a4' if (!missing(`a1') + !missing(`a2') + !missing(`a3') + !missing(`a4') >= 4)
                if `nvars' >= 5 replace `__b4' = `a5' if missing(`__b4') & !missing(`a5') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) >= 3)
                if `nvars' >= 6 replace `__b4' = `a6' if missing(`__b4') & !missing(`a6') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) + (!missing(`a5')) >= 3)
            }

            if `nvars' >= 5 {
                replace `__b5' = `a5' if (!missing(`a1') + !missing(`a2') + !missing(`a3') + !missing(`a4') + !missing(`a5') >= 5)
                if `nvars' >= 6 replace `__b5' = `a6' if missing(`__b5') & !missing(`a6') ///
                    & ((!missing(`a1')) + (!missing(`a2')) + (!missing(`a3')) + (!missing(`a4')) + (!missing(`a5')) >= 4)
            }

            if `nvars' >= 6 {
                replace `__b6' = `a6' if (!missing(`a1') + !missing(`a2') + !missing(`a3') + !missing(`a4') + !missing(`a5') + !missing(`a6') >= 6)
            }

            replace `a1' = `__b1' if `__gapflag' == 1
            if `nvars' >= 2 replace `a2' = `__b2' if `__gapflag' == 1
            if `nvars' >= 3 replace `a3' = `__b3' if `__gapflag' == 1
            if `nvars' >= 4 replace `a4' = `__b4' if `__gapflag' == 1
            if `nvars' >= 5 replace `a5' = `__b5' if `__gapflag' == 1
            if `nvars' >= 6 replace `a6' = `__b6' if `__gapflag' == 1

            drop `__b1' `__b2' `__b3' `__b4' `__b5' `__b6'
        }
    }

    if `ngap' > 0 {
	
		di as txt "note: `ngap' episode(s) had a missing first activity but a valid later activity."
		di as txt "Later activity values were moved left so the first activity is non-missing."
    }

    drop `__gapflag'
	
	
	// If only one activity variable is provided, ignore shares() and notify
if `nvars'==1 & `have_shares' {
    di as txt "note: shares() is ignored when only one activity variable is provided."
    local have_shares = 0
}

    if `have_shares' {
        // reject any char other than digits and spaces
        if regexm("`shares'","[^ 0-9]") {
            di as err "shares(): must be integers 0–100 separated by spaces only (no decimals, commas, or hyphens)."
            exit 198
        }
        // tokenize and read up to 6 integers
        tokenize "`shares'"
        local ns 0
        forvalues i=1/6 {
            if "``i''" != "" {
                local ++ns
                capture confirm integer number ``i''
                if _rc {
                    di as err "shares(): value ``i'' is not an integer."
                    exit 198
                }
                if (``i'' < 0 | ``i'' > 100) {
                    di as err "shares(): each value must be between 0 and 100."
                    exit 198
                }
                local w`i' = ``i''
            }
        }
        if `ns' != `nvars' {
            di as err "shares(): provide exactly `nvars' integers (one per activity variable)."
            exit 198
        }
        // must sum to 100
        local sumS 0
        forvalues i=1/`ns' {
            local sumS = `sumS' + `w`i''
        }
        if `sumS' != 100 {
            di as err "shares(): values must sum to 100."
            exit 198
        }
    }

    // --- Remember original order for stable splitting ---
    tempvar __oid
    gen long `__oid' = _n

    quietly {

        // Count how many of the supplied activity vars are non-missing per episode
        tempvar has2 has3 has4 has5 has6 k
gen byte `has2' = cond(`nvars'>=2 & "`a2'"!="", !missing(`a2'), 0)
gen byte `has3' = cond(`nvars'>=3 & "`a3'"!="", !missing(`a3'), 0)
gen byte `has4' = cond(`nvars'>=4 & "`a4'"!="", !missing(`a4'), 0)
gen byte `has5' = cond(`nvars'>=5 & "`a5'"!="", !missing(`a5'), 0)
gen byte `has6' = cond(`nvars'>=6 & "`a6'"!="", !missing(`a6'), 0)
gen byte `k'    = 1 + `has2' + `has3' + `has4' + `has5' + `has6'


        // Only split when 2+ present activities in the episode
        quietly count if `k' >= 2
        local _anysplit = r(N)

        // Precompute per-episode durations and shares
        tempvar dur s1 s2 s3 s4 s5 s6 sumP b1 b2 b3 b4 b5 b6
        gen double `dur' = end - start

        // Default = equal shares among present activities
        gen double `s1' = 1/`k'
        gen double `s2' = cond(`has2', 1/`k', 0)
        gen double `s3' = cond(`has3', 1/`k', 0)
        gen double `s4' = cond(`has4', 1/`k', 0)
        gen double `s5' = cond(`has5', 1/`k', 0)
        gen double `s6' = cond(`has6', 1/`k', 0)

        // If shares() provided: map weights to a1..a6, zero out missing in this episode, re-normalize
      
	  * --- If shares() provided: overwrite equal shares only for weights that exist ---
if `have_shares' {
    if "`w1'" != "" replace `s1' = `w1'/100
    if "`w2'" != "" replace `s2' = cond(`has2', `w2'/100, 0)
    if "`w3'" != "" replace `s3' = cond(`has3', `w3'/100, 0)
    if "`w4'" != "" replace `s4' = cond(`has4', `w4'/100, 0)
    if "`w5'" != "" replace `s5' = cond(`has5', `w5'/100, 0)
    if "`w6'" != "" replace `s6' = cond(`has6', `w6'/100, 0)

    * Re-normalize to sum to 1 among present activities
    gen double `sumP' = `s1'+`s2'+`s3'+`s4'+`s5'+`s6'
    replace `s1' = cond(`sumP'>0, `s1'/`sumP', 0)
    replace `s2' = cond(`sumP'>0, `s2'/`sumP', 0)
    replace `s3' = cond(`sumP'>0, `s3'/`sumP', 0)
    replace `s4' = cond(`sumP'>0, `s4'/`sumP', 0)
    replace `s5' = cond(`sumP'>0, `s5'/`sumP', 0)
    replace `s6' = cond(`sumP'>0, `s6'/`sumP', 0)
    drop `sumP'
}

	  
	  

        // Integer minutes: floor and distribute leftover minute(s) in order a1→a2→...→a6 among present
        gen double `b1' = floor(`dur'*`s1')
        gen double `b2' = floor(`dur'*`s2')
        gen double `b3' = floor(`dur'*`s3')
        gen double `b4' = floor(`dur'*`s4')
        gen double `b5' = floor(`dur'*`s5')
        gen double `b6' = floor(`dur'*`s6')

        tempvar resid
        gen double `resid' = `dur' - (`b1'+`b2'+`b3'+`b4'+`b5'+`b6')

        // Hand out leftover minutes (at most 5) in order to present activities
        quietly replace `b1' = `b1' + 1 if `resid'>=1
        quietly replace `b2' = `b2' + 1 if `resid'>=2 & `has2'
        quietly replace `b3' = `b3' + 1 if `resid'>=3 & `has3'
        quietly replace `b4' = `b4' + 1 if `resid'>=4 & `has4'
        quietly replace `b5' = `b5' + 1 if `resid'>=5 & `has5'
        quietly replace `b6' = `b6' + 1 if `resid'>=6 & `has6'

        // Prepare mapping of the j-th split to the correct variable position (skipping missings)
        tempvar j2 j3 j4 j5 j6
        gen byte `j2' = 1 + `has2'
        gen byte `j3' = 1 + `has2' + `has3'
        gen byte `j4' = 1 + `has2' + `has3' + `has4'
        gen byte `j5' = 1 + `has2' + `has3' + `has4' + `has5'
        gen byte `j6' = 1 + `has2' + `has3' + `has4' + `has5' + `has6'

        // Expand rows only where splitting is needed
        // For k==1 episodes expand 1 (no change); for k>=2 expand k pieces
        expand `k', gen(__copy)

        // position within the original episode 1..k
        bysort `__oid': gen int __j = _n

        // compute per-copy duration to apply
        tempvar dur_use
        gen double `dur_use' = .
        replace `dur_use' = `b1' if __j==1
        replace `dur_use' = `b2' if `has2' & __j==`j2'
        replace `dur_use' = `b3' if `has3' & __j==`j3'
        replace `dur_use' = `b4' if `has4' & __j==`j4'
        replace `dur_use' = `b5' if `has5' & __j==`j5'
        replace `dur_use' = `b6' if `has6' & __j==`j6'

        // Assign the chosen activity code into the FIRST var (`activity`)
        replace `activity' = `a1'                               if __j==1
if "`a2'" != "" replace `activity' = `a2'              if `has2' & __j==`j2'
if "`a3'" != "" replace `activity' = `a3'              if `has3' & __j==`j3'
if "`a4'" != "" replace `activity' = `a4'              if `has4' & __j==`j4'
if "`a5'" != "" replace `activity' = `a5'              if `has5' & __j==`j5'
if "`a6'" != "" replace `activity' = `a6'              if `has6' & __j==`j6'

		
        // New [start,end] by cumulative minutes within each original episode
        tempvar start0
        gen double `start0' = start
        bysort `__oid' (__j): gen double __cum = sum(`dur_use')
        replace start = `start0' + (__cum - `dur_use')
        replace end   = `start0' + __cum
        drop __cum `start0' `dur_use'

        // Drop the extra activity columns; from here on we only need `activity'
        capture drop `a2' `a3' `a4' `a5' `a6'

        // Clean helpers
        drop `has2' `has3' `has4' `has5' `has6' `k' `j2' `j3' `j4' `j5' `j6' `dur' ///
             `s1' `s2' `s3' `s4' `s5' `s6' `b1' `b2' `b3' `b4' `b5' `b6' `resid' __copy __j
    }

    // --- Recompute time etc. AFTER splitting so your totals are correct ---
    quietly epigenx `activity', did(`did') dst(4)

    // ===== Your original aggregation code (unchanged) =====
    quietly {
        levelsof `activity', local(levels)
        local vlname: value label `activity'

        foreach l of local levels {
            tempvar x
            gen `x' = 0
            replace `x' = time if `activity' == `l'
            bysort `did': egen `activity'_`l' = total(`x')
            capture qui local thelabel: label `vlname' `l'
            capture lab var `activity'_`l' "mpd on: `thelabel'"
        }

        
		levelsof `activity', local(levels)
local nlev    : word count `levels'
local firstlev: word 1 of `levels'
local lastlev : word `nlev' of `levels'
local vlname: value label `activity'

if `do_counts' {
    foreach l of local levels {
        tempvar x
        gen `x'=0
        replace `x'=1 if `activity'==`l'
        bysort `did': egen `activity'_`l'_n=total(`x')
        capture qui local thelabel: label `vlname' `l'
        capture lab var `activity'_`l'_n "n episodes: `thelabel'"
    }
}

		

        keep if epnum==1
        drop `activity'
        drop start end epnum time clockst

	capture drop __flag_case
        capture drop __flag_diary*

        order `did' `activity'_*

        // 1440 check
        tempvar y
        gen `y'=0
        foreach l of local levels {
            replace `y' = `y' + `activity'_`l'
        }
    }

    qui sum `y'
    local e = 1440 - `r(mean)'

    if `e' == 0 {
        di as txt "`activity' has no missing values: the vars created add up to 1440 minutes."
    }
    else {
        di as txt "The activities created do not add up to 1440 minutes."
        di as txt "`activity' had missing values; recode them if you need a full 1440 mpd."
    }

    // --- Friendly reminder about the default split vs shares() ---
    if `nvars' > 1 & !`have_shares' {
        di as txt "Because more than one activity variable was supplied, each episode’s"
		di as txt "duration was divided evenly among the non-missing activities."
		di as txt "Use the shares() option to customize the split."

    }
    if `have_shares' {
		di as txt "Because more than one activity variable was supplied, each episode's"
		di as txt "duration was divided among the activities according to the proportions"
		di as txt "specified in shares()."

	}
 

end
