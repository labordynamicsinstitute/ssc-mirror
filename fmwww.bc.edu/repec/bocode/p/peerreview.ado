*! 1.1.1                14dec2020
*! Wouter Wakker     	wouter.wakker@outlook.com

* 1.1.1     14dec2020   if in syntax documented
* 1.1.0     10dec2020   byable
* 1.0.2     08dec2020   simplified syntax; string variables are encoded first
* 1.0.1     30jun2020   aesthetic changes
* 1.0.0     15apr2020   born

program peerreview, sortpreserve byable(onecall)
	version 9.0
	
	// Syntax 
	syntax varname [if] [in] , Review(string) [by(varlist)]
	
	// By prefix
	if _by() {
		if "`by'" != "" {
			di as error "by prefix or by() option allowed, not both"
			exit 198
		}
		else local by "`_byvars'"
	}
		
	// Preserve the data
	preserve
	
	// Sample to use
	if "`if'`in'" != "" marksample touse, strok
	else {
		tempvar touse
		qui gen byte `touse' = 1
	}
	
	// Sort
	if "`by'" != "" {
		tempvar group
		bysort `by' (`_sortindex'): gen long `group' = _n == 1
		qui replace `group' = sum(`group')
	}
	
	// Get number of reviews to be assigned and varname
	parse_name_opt `review'
	local reviews `s(integer)'
	local var_reviews `s(newvarname)'
	if "`var_reviews'" == "" local var_reviews "review" // Default
	
	// Check if variable is string or numeric
	cap confirm string variable `varlist'
	if _rc {
		local isstring 0
		local var_reviewer `varlist'
	}
	else {
		local isstring 1
		if _byindex() == 1 {
			tempvar var_reviewer
			encode `varlist', gen(`var_reviewer')
		}
	}
	
	// Check if variables to be created exist already
	if `reviews' == 1 {
		confirm new variable `var_reviews'
		if `isstring' {
			tempvar `var_reviews'
			local var_reviews_label ``var_reviews''
		}
	}
	else {
		forval i = 1/`reviews' {
			confirm new variable `var_reviews'`i'	
			if `isstring' {
				tempvar `var_reviews'`i'
				local var_reviews_label `var_reviews_label' ``var_reviews'`i''
			}
		}
	}
	
	// Generate review variables
	if `reviews' == 1 {
		if `isstring' {
			qui gen ``var_reviews'' = .
		}
		else {
			qui gen `var_reviews' = . 
		}		
	}
	else {
		if `isstring' {
			forval i = 1/`reviews' {
				qui gen ``var_reviews'`i'' = .
			}
		}
		else {
			forval i = 1/`reviews' {
				qui gen `var_reviews'`i' = .
			}
		}
	}
	
	// Assign
	if "`by'" != "" {
		tempvar touse_group
		qui gen `touse_group' = .
		qui levelsof `group' if `touse', local(groups)
		if "`groups'" == "" error 2000
		else {
			foreach g of local groups {
				qui replace `touse_group' = `touse' & `group' == `g'
				peerreview_assign "`var_reviewer'" "`touse_group'" "`reviews'" "`isstring'" "`var_reviews'" "`var_reviews_label'" "`g'" "`_sortindex'" "`varlist'"
			}
		}
	}
	else peerreview_assign "`var_reviewer'" "`touse'" "`reviews'" "`isstring'" "`var_reviews'" "`var_reviews_label'" "" "`_sortindex'" "`varlist'"
	
	// Decode review variables if string
	if `isstring' {
		lab val `var_reviews_label' `var_reviewer'
		if `reviews' == 1 decode ``var_reviews'', gen(`var_reviews')
		else {
			forval i = 1/`reviews' {
				decode ``var_reviews'`i'', gen(`var_reviews'`i')
			}
		}
	}
	
	restore, not
end

program peerreview_assign
	version 9
	
	args var_reviewer touse reviews isstring var_reviews var_reviews_label group sortindex varlist
	
	// Sort
	gsort -`touse' `sortindex'
	
	// Store observations
	qui count if `touse'
	local reviewers = r(N)
	
	// Argument conditions
	qui tab `var_reviewer' if `touse'
	if `r(r)' != `reviewers' {
		di as error "duplicate values in variable {bf:`varlist'}"
		exit 499
	}

	if `reviews' < 1 {
		di as error "number of reviews must be at least 1"
		exit 119
	}
	
	if `reviewers' < 2 {
		if `reviewers' == 0 error 2000
		else {
			di as error "number of reviewers must be at least 2"
			exit 119
		}
	}
	
	if `reviewers' <= `reviews' {
		di as error "number of reviews must be smaller than number of reviewers"
		exit 119
	}	
	
	// Create list of reviews based on varname
	qui levelsof `var_reviewer' if `touse', local(levels)
	forval i = 1/`reviews' {
		local review_pool `review_pool' `levels'
	}
	
	// Make sure tempvars are referenced correctly for string variables
	if `isstring' {
		if `reviews' == 1 local `var_reviews' `var_reviews_label'
		else {
			forval i = 1/`reviews' {
				local `var_reviews'`i' `:word `i' of `var_reviews_label''
			}
		}
	}

	// Mata: create inlist conditions and reviewer/author combination matrix
	tempname rvwrs_rvws_comb_mat
	mata : peerreview_comb_mat(`reviewers', `reviews', `isstring')

	// Shuffle list of reviews and assign to reviewers
	// Reviews are put at the end of the list if one of the conditions is not satisfied
	// In some cases, the reviews that are left cannot satisfy the conditions for the last couple of reviewers
	// If this is the case, the loop breaks and the list of reviews is reshuffled
	local iterations = 1
	local counter = 1
	while `counter' != `= `reviewers' * `reviews' + 1' { // Only false when succesfully assigned reviews to all reviewers
		
		// Randomize list of reviews and assignment order
		mata : peerreview_shuffle_comb_mat("`rvwrs_rvws_comb_mat'")
		mata : st_local("review_list", invtokens(jumble(tokens(st_local("review_pool"))')'))
		
		// Generate review variables
		if `reviews' == 1 {
			if `isstring' {
				qui replace ``var_reviews'' = . if `touse'
			}
			else {
				qui replace `var_reviews' = . if `touse'
			}		
		}
		else {
			if `isstring' {
				forval i = 1/`reviews' {
					qui replace ``var_reviews'`i'' = . if `touse'
				}
			}
			else {
				forval i = 1/`reviews' {
					qui replace `var_reviews'`i' = . if `touse'
				}
			}
		}
		
		// Assign reviews to reviewers
		local counter = 1
		local cond_not_satisf = 0
		foreach rvw of local review_list {
			local i : word `counter' of `reviewer_nr'
			local j : word `counter' of `author_nr'

			if `var_reviewer'[`i'] == `rvw' | inlist(`rvw' `inlist_cond') { // Conditions: Reviewer cannot review themselves or review more than once
				local review_list `review_list' `rvw' // Add review to the end of the list
				local ++cond_not_satisf // Count times condition not satisfied
				if `cond_not_satisf' == `= `reviews' * 2 ' {
					local ++iterations
					continue, break // Break and reshuffle if condition is repeatedly not satisfied
				}
				continue
			}
			
			// Assign review to reviewer
			if `isstring' {
				if `reviews' == 1 qui replace ``var_reviews'' = `rvw' in `i' 
				else qui replace ``var_reviews'`j'' = `rvw' in `i' 
			}
			else {
				if `reviews' == 1 qui replace `var_reviews' = `rvw' in `i'
				else qui replace `var_reviews'`j' = `rvw' in `i'
			}
			
			// Reset count condition not satisfied
			local cond_not_satisf = 0 
			local ++counter
		}
	}
	
	if "`group'" == "" di as txt "assigned succesfully; iterations: " as res `iterations'
	else di as txt "-> group `group': assigned succesfully; iterations: " as res `iterations'
end

// Parser for options with name suboption
program parse_name_opt, sclass
	version 9.0
    
	syntax anything(id="integer") [, Name(name)]
	confirm integer number `anything'
    
	sreturn local integer `anything'
	sreturn local newvarname `name'
end

// Mata functions
version 9.0
mata:
// Create reviewers/reviews combination matrix and inlist conditions
void peerreview_comb_mat(real scalar rvwrs, real scalar rvws, real scalar isstring)
{
	// Create empty matrices
	inlist_mat = J(1, rvws, ".")
	rvwrs_rvws_comb_mat = J(rvws * rvwrs, 2, .)
	
	row_nr = 1
	for (i=1; i<=rvws; i++) {
		// Create reviewers/reviews combination matrix
		for (j=1; j<=rvwrs; j++) {
			rvwrs_rvws_comb_mat[row_nr, 1] = j
			rvwrs_rvws_comb_mat[row_nr, 2] = i
			row_nr++
		}
		// Create inlist conditions for inlist below (conditions are different for different number of reviews)
		if (rvws == 1) {
			if (isstring) inlist_mat[i] = ", \`\`var_reviews''" + "[\`i']"
			else inlist_mat[i] = ", \`var_reviews'" + "[\`i']"
		}
		else {
			if (isstring) inlist_mat[i] = ", \`\`var_reviews'" + strofreal(i) + "'[\`i']"
			else inlist_mat[i] = ", \`var_reviews'" + strofreal(i) + "[\`i']"
		}
	}
	
	st_local("inlist_cond", invtokens(inlist_mat))
	st_matrix(st_local("rvwrs_rvws_comb_mat"), rvwrs_rvws_comb_mat)
}

// Shuffle reviewers/reviews combination matrix
void peerreview_shuffle_comb_mat(string scalar matname)
{
	comb_mat = strofreal(jumble(st_matrix(matname)))
	st_local("reviewer_nr", invtokens(comb_mat[1...,1]'))
	st_local("author_nr", invtokens(comb_mat[1...,2]'))
}
end
