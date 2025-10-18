*! 1.0.0 Ariel Linden 150ct2025

program define splithalf, rclass
	version 11
	syntax varlist(min=4) [if] [in], [RANdom REPs(integer 1)]

	marksample touse

	local items `varlist'
	local nitems : word count `items'

	tempvar score1 score2 score_total
	tempname r_half sb_equal p1 p2 numerator denominator horst

	// Validate reps
	if "`random'" != "" & `reps' < 1 {
		display as error "Option reps() must be a positive integer."
		exit 198
	}

	// Initialize accumulators
	local sum_r = 0
	local sum_sb = 0
	local sum_horst = 0

	local last_half1_items
	local last_half2_items

	forvalues rep = 1/`reps' {
		if "`random'" != "" {
			preserve
			clear
			quietly {
				set obs `nitems'
				gen itemname = ""
				local i = 1
				foreach item of local items {
					replace itemname = "`item'" in `i'
					local ++i
				}
				gen rand = runiform()
				sort rand

				local half1_n = floor(`nitems'/2)
				local half2_n = `nitems' - `half1_n'

				// Randomly assign extra item to either half
				if mod(`nitems', 2) == 1 {
					if runiform() < 0.5 {
						local tmp = `half1_n'
						local half1_n = `half2_n'
						local half2_n = `tmp'
					}
				}

				levelsof itemname in 1/`half1_n', local(half1_items) clean
				levelsof itemname in `=`half1_n'+1'/`nitems', local(half2_items) clean
			} // end quietly
			restore
		} // end random
        else {
            // Only compute split once in non-random mode
			if `rep' == 1 {
				local half1_items
				local half2_items
				forvalues i = 1/`nitems' {
					local item : word `i' of `items'
					if mod(`i',2)==1 {
						local half1_items `half1_items' `item'
					}
					else {
						local half2_items `half2_items' `item'
					}
				}
			}
		} // end not random

		local n1 : word count `half1_items'
		local n2 : word count `half2_items'

        // compute correlations
		quietly {
			egen `score1' = rowtotal(`half1_items') if `touse'
			egen `score2' = rowtotal(`half2_items') if `touse'
			gen double `score_total' = `score1' + `score2'

			count if `touse' & !missing(`score1', `score2')
			if r(N) < 2 {
				display as error "Not enough complete cases in rep `rep' to compute correlation."
				continue
			}

			// correlation
			corr `score1' `score2' if `touse'
			matrix R = r(C)
			scalar `r_half' = R[1,2]

			// Spearman-Brown
			scalar `sb_equal' = (2 * `r_half') / (1 + `r_half')

			// Horst
			scalar `p1' = `n1' / (`n1' + `n2')
			scalar `p2' = `n2' / (`n1' + `n2')

			scalar `numerator' = `r_half' * sqrt(`r_half'^2 + 4 * `p1' * `p2' * (1 - `r_half'^2)) - `r_half'^2
			scalar `denominator' = 2 * `p1' * `p2' * (1 - `r_half'^2)

			if `denominator' == 0 {
				scalar `horst' = .
			}
			else {
				scalar `horst' = `numerator' / `denominator'
			}

			// Accumulate values
			local sum_r = `sum_r' + `r_half'
			local sum_sb = `sum_sb' + `sb_equal'
			local sum_horst = `sum_horst' + cond(missing(`horst'), 0, `horst')

			// Store final split for display
			if `rep' == `reps' {
				local last_half1_items "`half1_items'"
				local last_half2_items "`half2_items'"
				local n1_final = `n1'
				local n2_final = `n2'
			}
			drop `score1' `score2' `score_total'
		} // end quietly
	} // end reps

    // Compute means
	local avg_r = `sum_r' / `reps'
	local avg_sb = `sum_sb' / `reps'
	local avg_horst = `sum_horst' / `reps'

	di as result _newline(1) "Split-half items (from last split):"
	di as text "  Half 1 (" as result `n1_final' as text " items): `last_half1_items'"
	di as text "  Half 2 (" as result `n2_final' as text " items): `last_half2_items'" _newline(1)

	if `reps' > 1 {
		di as result "Average of `reps' random splits:"
	}

	di as text "Split-half correlation (unadjusted):       " as result %6.4f `avg_r'
	di as text "Spearman-Brown prophecy (equal halves):    " as result %6.4f `avg_sb'
	di as text "Horst reliability (unequal halves):        " as result %6.4f `avg_horst'

	// saved results
	return scalar corr = `avg_r'
	return scalar sb = `avg_sb'
	return scalar horst = `avg_horst'

	return local half1_items = "`last_half1_items'"
	return local half2_items = "`last_half2_items'"
	
end