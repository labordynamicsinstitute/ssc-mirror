
program define tslotcheck
    version 15
	
    syntax , did(string) [quiet]

    // Check prerequisites
    quietly {
        capture confirm variable tslot
        if _rc {
            display as error "Error: Variable 'tslot' is missing."
            exit 198
        }
        capture confirm numeric variable tslot
        if _rc {
            display as error "Error: Variable 'tslot' is not numeric."
            exit 198
        }
        capture confirm variable `did'
        if _rc {
            display as error "Error: Diary ID variable '`did'' is missing."
            exit 198
        }

        capture drop problem_diary
    }

    // Determine expected number of slots
    quietly {
        preserve
        egen __maxslot = max(tslot), by(`did')
        egen __med = median(__maxslot)
        scalar expected_slots = __med[1]
        restore
    }

	capture drop problem_diary
    quietly gen byte problem_diary = .

    // Loop through each diary
	capture drop __udid
	egen __udid=group(`did')
	
    quietly levelsof __udid, local(idlist)


quietly {
	
capture drop problem_case 
capture drop problem_diary 
capture drop dup __oor 
capture drop is_missing_following 
capture drop any_problem

* Step 1: Out-of-range tslot values
gen byte __oor = tslot < 1 | tslot > `=scalar(expected_slots)'
gen byte problem_case = .
replace problem_case = 2 if __oor == 1

* Step 2: Duplicates
bysort __udid tslot: gen dup = cond(_n == 1, 0, 1)
replace problem_case = 1 if dup == 1 & missing(problem_case)

* Step 3: Flag diaries with too few slots
bysort __udid: gen slots_per_diary = _N
replace problem_case = 3 if slots_per_diary != `=scalar(expected_slots)' & missing(problem_case)

* Step 4: Diary-level flag
egen byte any_problem = max(problem_case), by(__udid)
capture drop problem_diary
gen byte problem_diary = cond(missing(any_problem), 0, any_problem > 0)

* Clean up
drop dup __oor slots_per_diary any_problem

}

//the above was the new.
    quietly {
        label define okstatus 0 "OK diary" 1 "Diary has issues", replace
        label values problem_diary okstatus
    }

    preserve
    quietly {
        tempvar tag
        gen byte `tag' = (_n == 1)
        bysort __udid (tslot): replace `tag' = (_n == 1)
        keep if `tag'
        contract problem_diary
        gen percent = 100 * _freq / sum(_freq)
        format _freq %9.0g
        format percent %6.1f
        gen total_issues = _freq if problem_diary == 1
        quietly su total_issues, meanonly
        local n_issues = r(sum)
	
    }


// NOT QUIET

if "`quiet'" == "" {
    if `n_issues' == 0 {
		
		local nslots = expected_slots
display as text "All diaries have the expected number of time slots (`nslots')."
	
    }
	
    else {
        display as text "There are issues in one or more of the diaries:"
		display as text "Fixing those before running epigen is recommended." 
		list problem_diary _freq percent, noobs sep(0) abbrev(24)
		
    }
}

// Quiet
else {
	
    if `n_issues' > 0 {
   
		display as text "There are issues in one or more of the diaries:"
		display as text "Fixing those before running epigen is recommended." 
       
    }
}


    restore
end
