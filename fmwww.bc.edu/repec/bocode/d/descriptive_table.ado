// Program to create descriptive_table in open word document with suppression
*! Author(s) Christiaan Righolt & Colton Poitras
*! Orthopaedic Innovation Centre, Winnipeg, MB
*! Version history
*! 2.1 Aug 2025		Allow for percentages of non-missing (and minor changes)
*! 2.0 Dec 2024		Mata suppression
*! 1.1 Sep 2024		Initial suppression
*! 1.0 Dec 2022		Initial version

program define descriptive_table
	version 18.0 // Do not have lower version to test this on, but may work
	syntax varlist(fv) [if/] [in], [COL_var(varname) title(string) footnote(string) suppression_threshold(int 0) med_iqr minmax nomeansd nomiss_percent]

	local fmt_num %12.0fc
	local fmt_perc %12.1f

	local print_mean_row = missing("`meansd'") // See help syntax for inverted meaning of option nomeansd
	local print_median_row = !missing("`med_iqr'")
	local print_minmax_row = !missing("`minmax'")
	if !`print_mean_row' & !`print_median_row' & !`print_minmax_row' di as error "Continuous variables not printed, nomeansd selected" 
	local percent_exclude_missing = !missing("`miss_percent'") // See help syntax for inverted meaning of nomiss_percent
	local any_cat_missing_flag = 0

	local suppression_flag = 0
	local primary_supp_str = "<" + string(`suppression_threshold', "`fmt_num'")
	local secondary_supp_str = "S"
	scalar _supp_threshold = `suppression_threshold'
	matrix _supp_suppression = (.)

	if !missing("`title'") {
		putdocx paragraph
		putdocx text ("`title'")
	}

	// Need a
	if !missing("`if'") local if_from_function_call "if `if'"
	if missing("`if'") local and_if_from_function_call ""
	else local and_if_from_function_call "& `if'"

	// Column attributes
	local has_col_var = !missing("`col_var'")
	if `has_col_var' {
		local col_var_label : var label `col_var'
		local col_val_label : val label `col_var'
		if missing("`col_var_label'") local col_var_label "`col_var'"
		if missing("`col_val_label'") {
			display as error "col_var does not have a value label and may not be appropriate as a column variable"
			display as error "Set a column label explicitly"
			error 119
		}
		qui levelsof `col_var' `if_from_function_call' `in', missing local(col_levels)
		local n_col_levels : list sizeof col_levels
		local n_rows = 2 // Header and overall 
		local headerrow = 2
	}
	else {
		local n_rows = 1 //Only overall row
		local headerrow = 1
		// Set up dummy variable for later looping
		tempvar dummy
		gen `dummy' = 1
		local col_var `dummy'
		local col_levels 1
		local n_col_levels 1
	}
	local n_cols = `n_col_levels' + 1

	// Get number of rows required
	foreach var in `varlist' {
		get_var_info `var'
		local var_base_name = "`r(base_name)'"
		char `var_base_name'[__row_start] `=`n_rows'+1'
		
		if "`r(type)'" == "cat" {
			// Categorical (could be binary)
			qui levelsof `var_base_name', missing local(row_levels)
			local n_row_levels : list sizeof row_levels
			char `var_base_name'[__levels] "`row_levels'"

			get_var_info `var' // Return got overwritten by levelsof
			if (`n_row_levels'==2) & !(`r(is_string)') & !(`r(is_i_dot)') {
				// Binary variable (1 level)
				char `var_base_name'[__bin] 1
				local n_rows = `n_rows' + 1
			}
			else {
				// Categorical var (multi-level)
				char `var_base_name'[__bin] 0
				local n_rows = `n_rows' + `n_row_levels' + 1 // One extra for variable name
			}
		}
		else {
			// Continuous
			char `var_base_name'[__bin] 0

			local n_rows = `n_rows' + `print_mean_row' + `print_median_row' + `print_minmax_row'
			quietly count if missing(`var') `if_from_function_call' `in'
			if r(N)>0 local n_rows = `n_rows' + 1 // Add an extra row for unknowns if needed
		}
	}

	putdocx table t_desc = (`n_rows',`n_cols'), border(all, nil) layout(autofitcontents) headerrow(`headerrow')

	// Print header and overall
	quietly tabulate `col_var' `if_from_function_call' `in', missing matcell(N_per_col)
	matrix _supp_data = N_per_col
	if `has_col_var' {
		mata: do_suppression()
		local i_col = 1
		putdocx table t_desc(1,1) = (" "), bold border(top, single)
		putdocx table t_desc(2,1) = (" "), bold border(bottom, single) 
		foreach col of local col_levels {
			local ++i_col
			local col_label : label `col_val_label' `col'
			putdocx table t_desc(1,`i_col') = ("`col_label'"), bold border(top, single)
			
			// 2nd column of table is 1st level (1st row of matrix)
			if _supp_suppression[`=`i_col'-1',1]==0 local N_str = "N = " + string(_supp_data[`=`i_col'-1',1], "`fmt_num'") // Actual number of the cell
			else if _supp_suppression[`=`i_col'-1',1]==1 local N_str "N `primary_supp_str'"
			else if _supp_suppression[`=`i_col'-1',1]==2 {
				local N_str "N = `secondary_supp_str'"
				local suppression_flag = 1 
			}
			else local N_str "" // Should not be possible, but put empty cell for safety
			putdocx table t_desc(2,`i_col') = ("`N_str'"), bold border(bottom, single)
		}
	}
	else {
		putdocx table t_desc(1,1) = ("Overall"), bold border(top, single) border(bottom, single)
		local total_count = _supp_data[1,1]
		if `total_count'<`suppression_threshold' local total_str "`primary_supp_str'"
		else local total_str = "N = " + string(`total_count', "`fmt_num'")
		putdocx table t_desc(1,2) = ("`total_str'"), bold border(top, single) border(bottom, single)
	}

	// Body of table
	foreach var in `varlist' {
		get_var_info `var'
		local base_name `r(base_name)'
		local i_row : char `base_name'[__row_start]
		local is_bin : char `base_name'[__bin]
		local row_levels : char `base_name'[__levels]
		local row_var_label : var label `base_name'
		local row_val_label : val label `base_name'
		local var_type `r(type)'
		local is_string_var `r(is_string)'

		if "`var_type'" == "cont" {
			// Continuous variables
			local fmt_var : format `var'
			if `print_mean_row' { // Row with mean and SD
				putdocx table t_desc(`i_row',1) = ("`row_var_label', mean (SD)")
				local i_col = 1
				foreach col of local col_levels {
					local ++i_col
					quietly summarize `var' if `col_var'==`col' `and_if_from_function_call' `in', detail
					local cell_str = string(r(mean),"`fmt_var'") + " ("+ string(r(sd),"`fmt_var'") + ")"
					putdocx table t_desc(`i_row',`i_col') = ("`cell_str'")
				}
				local ++i_row
			}
			if `print_median_row' { // Row with median and IQR (=Q1-Q3)
				putdocx table t_desc(`i_row',1) = ("`row_var_label', median (IQR)")
				local i_col = 1
				foreach col of local col_levels {
					local ++i_col
					quietly summarize `var' if `col_var'==`col' `and_if_from_function_call' `in', detail
					local cell_str = string(r(p50),"`fmt_var'") + " (" + string(r(p25),"`fmt_var'") + "-" + string(r(p75),"`fmt_var'") + ")"
					putdocx table t_desc(`i_row',`i_col') = ("`cell_str'")
				}
				local ++i_row
			}
			if `print_minmax_row' { // Row with mix-max range
				putdocx table t_desc(`i_row',1) = ("`row_var_label', range (min-max)")
				local i_col = 1
				foreach col of local col_levels {
					local ++i_col
					quietly summarize `var' if `col_var'==`col' `and_if_from_function_call' `in', detail
					local cell_str = string(r(min),"`fmt_var'") + "-" + string(r(max),"`fmt_var'")
					putdocx table t_desc(`i_row',`i_col') = ("`cell_str'")
				}
				local ++i_row
			}
			// Print missing row if some are missing
			quietly count if missing(`var') `if_from_function_call' `in'
			if r(N)>0 {
				// Tabulate on the missing won't work as one of the columns may not have missing values
				putdocx table t_desc(`i_row',1) = ("    Missing")
				local i_col = 1
				foreach col of local col_levels {
					local ++i_col
					qui count if missing(`var') & `col_var'==`col' `and_if_from_function_call' `in'
					local cell_count = r(N)
					local col_count = N_per_col[`=`i_col'-1',1]
					if 0<`cell_count' & `cell_count'<`suppression_threshold' {
						local cell_str "`primary_supp_str'"
					}
					else {
						local N_str = string(`cell_count', "`fmt_num'")
						local perc_str = string(`=`cell_count'/`col_count'*100', "`fmt_perc'")
						local cell_str = "`N_str' (`perc_str'%)"
					}
					putdocx table t_desc(`i_row',`i_col') = ("`cell_str'")
				}
			}
		}
		else {
			// Categorical (including binary)

			// Row labels
			if `is_bin' {
				local print_level : word 2 of `row_levels'
				local print_label : label `row_val_label' `print_level'
				putdocx table t_desc(`i_row',1) = ("`print_label'")
			}
			else {
				putdocx table t_desc(`i_row',1) = ("`row_var_label'"),  colspan(`n_cols')
				local j_row = `i_row' // Second counter for labels, use primary counter for printing values later on (i_row is start point of variable in table grid)
				foreach val of local row_levels {
					local ++j_row
					if `is_string_var'|missing("`row_val_label'") local print_label = "`val'" 
					else local print_label : label `row_val_label' `val'
					putdocx table t_desc(`j_row',1) = ("  `print_label'")
				}
			}

			quietly tabulate `base_name' `col_var' `if_from_function_call' `in', missing matcell(_supp_data)
			mata: do_suppression()

			// Need percentage of non-missing if option turned on and any missing
			if `percent_exclude_missing' {
				quietly tabulate `base_name' `col_var' `if_from_function_call' `in', matcell(non_missing_data)
				quietly tabulate `col_var' if !missing(`base_name') `and_if_from_function_call' `in', matcell(N_per_col_no_missing)
				quietly count if missing(`base_name') `if_from_function_call' `in'
				if r(N)>0 {
					local any_cat_missing_flag = 1
				}
			}

			// Values, loop over matrices
			local n_row_levels : list sizeof row_levels
			// Set up values to loop over tabulate result matrix whose indices are off-set related to the table grid
			// Table col 1 is labels, so table col 2 houses matrix row 1 
			// Binary only prints row 2, and counter starts at line to be printed only
			// Categorical prints row 1 to N, counter starts at var label (is line before print)
			// Set the (0,0) in the table grid, so the first cell of the two way table is at (+1,+1) compared to (t_row_0, t_col_0)
			local t_col_0 = 1
			if `is_bin' {
				local t_row_0 = `i_row' - 2
				local row_start = 2
			}
			else {
				local t_row_0 = `i_row'
				local row_start = 1
			}

			// r is row counter, c is col count
			foreach r of numlist `row_start'/`n_row_levels' {
				foreach c of numlist 1/`n_col_levels' {
					// Print cells
					local cell_suppression = _supp_suppression[`r',`c']
					if `cell_suppression' == 0 {
						local cell_count = _supp_data[`r',`c']
						local col_count = N_per_col[`c',1]
						local perc_suffix
						if `percent_exclude_missing' {
							// Only exclude missings from non-missing values, these missings will be missing from the non-missing results (stata has missing as + infinity so indices will be correct)
							if !missing(non_missing_data[`r',`c']) {
								local cell_count = non_missing_data[`r',`c']
								local col_count = N_per_col_no_missing[`c',1]
							}
							else local perc_suffix " *"
						}
						// Actual print value
						local N_str = string(`cell_count', "`fmt_num'")
						local perc_str = string(`=`cell_count'/`col_count'*100', "`fmt_perc'")
						local cell_str = "`N_str' (`perc_str'%)`perc_suffix'"
					}
					else if `cell_suppression' == 1 {
						local cell_str "`primary_supp_str'"
					}
					else if `cell_suppression' == 2 {
						local cell_str "`secondary_supp_str'"
						local suppression_flag = 1 
					}
					else local cell_str "" // Should not be possible, but put empty cell for safety

					putdocx table t_desc(`=`t_row_0'+`r'',`=`t_col_0'+`c'') = ("`cell_str'")
				}
			}
		}
	}

	if `suppression_flag' {
		local suppression_note "`secondary_supp_str' indicates the cell's value is suppressed to avoid deriving cells with values <`suppression_threshold'."
		if !missing("`footnote'") local footnote "`footnote' `suppression_note'"
		else {
			local footnote "`suppression_note'"
		}
	}

	if `any_cat_missing_flag' & `percent_exclude_missing' {
		local nonmissing_perc_note "* Missing values; missing values are excluded from the non-missing percentages (%)"
		if !missing("`footnote'") local footnote "`footnote' `nonmissing_perc_note'"
		else {
			local footnote "`nonmissing_perc_note'"
		}
	}
	
	if !missing("`footnote'") {
		// Add row for footnote (does not count toward n_rows)
		putdocx table t_desc(`n_rows',.), addrows(1, after)
		putdocx table t_desc(`=`n_rows'+1',1) = ("`footnote'"), colspan(`n_cols')
	}
	
	putdocx table t_desc(`n_rows',.), border(bottom, single)
	putdocx table t_desc(., .), halign(center)
	putdocx table t_desc(., 1), halign(left)
end

// Mata code to run suppression logic

mata:
    // Run the actual suppression code in mata
    // Primary suppression if 0<value<threshold; secondary suppression to avoid deriving this with addition and subtraction
	// _supp_suppression will be
	//   0 for no suppression
	//   1 for primary suppression
	//   2 for secondary suppression
    void do_suppression() {
        data_in = st_matrix("_supp_data")
        threshold = st_numscalar("_supp_threshold")

        primary_suppression = (data_in:>0) :& (data_in:<threshold)
        suppression_okay = . 
        col_violation = J(1,cols(data_in),.)
        row_violation = J(rows(data_in),1,.)
        check_suppression(data_in, primary_suppression, threshold, row_violation, col_violation, suppression_okay)

        all_suppression = primary_suppression
        cell_to_suppress = J(rows(data_in), cols(data_in), .)

        while (!suppression_okay) {
            next_suppression(data_in, all_suppression, cell_to_suppress, row_violation, col_violation)
            all_suppression = all_suppression + cell_to_suppress
            check_suppression(data_in, all_suppression, threshold, row_violation, col_violation, suppression_okay)
        }
        suppression = 2*all_suppression - primary_suppression

        st_matrix("_supp_suppression",suppression)
    }

    // Function to check if suppression rules are valid
    // The rule is that:
	//   all suppressed values in each row and each column sum to 0 (no suppression) or >=threshold (value cannot be derived) 
	//   AND
	//   the number suppressed in a row or column is not 1 (it could be derived then) 
	//   UNLESS all nonzero values have been suppressed
    void check_suppression(real matrix data, real matrix suppression, real scalar threshold, real matrix row_fail, real matrix col_fail, real scalar pass) {
        suppressed_vals = data:*suppression
		nonsuppressed_vals = data:*!suppression

        row_fail_total_supp = (rowsum(suppressed_vals):>0) :& (rowsum(suppressed_vals):<threshold)
		row_fail_N_supp = rowsum(suppression):==1
		row_has_zero_nonsuppressed = rowsum(nonsuppressed_vals):>0
		row_fail = (row_fail_total_supp:|row_fail_N_supp) :& row_has_zero_nonsuppressed
		
		col_fail_total_supp = (colsum(suppressed_vals):>0) :& (colsum(suppressed_vals):<threshold)
		col_fail_N_supp = colsum(suppression):==1
		col_has_zero_nonsuppressed = colsum(nonsuppressed_vals):>0
		col_fail = (col_fail_total_supp:|col_fail_N_supp) :& col_has_zero_nonsuppressed
		        
		pass_by_suppressed_values = (rowsum(col_fail)==0 & colsum(row_fail)==0)
        zero_or_suppressed = ( (data:==0) :| suppression )
        pass = pass_by_suppressed_values | ( zero_or_suppressed==J(rows(data),cols(data),1) )
    }

    // Function to identify next suppression
    // Look for next value to suppress, in any case it is the non-zero minimum value of the candidates
    // 1) Look for cells for which both the row or column violates the condition
    // 2) If none, look for other cells in violating rows or columns
    // If >1 are this minimum, only pick the first one
    // 1:/ options is to set zeros to missing and select the minimum non-zero values
    void next_suppression(real matrix data, real matrix suppression, real matrix next_suppression, real matrix row_fail, real matrix col_fail) {
        zero_vals = (data:==0)
        candidate_cells = (row_fail * col_fail) :& !suppression :& !zero_vals
        if (sum(candidate_cells)==0) {
            candidate_cells = (J(1,cols(data),row_fail) :| J(rows(data),1,col_fail) ) :& !suppression :& !zero_vals
        }
		if (sum(candidate_cells)==0) {
			display("INTERNAL ERROR.")
			display("No candidate cell for suppression. Internal logic failed.")
			_error(3498)
		}

        next_suppression = min( (1:/candidate_cells) :*data):== (data:*candidate_cells)
        if (sum(next_suppression)>1) {
            cell_index = rowshape( (1::rows(data)*cols(data)), rows(data))
            next_suppression = min( (1:/next_suppression :* cell_index ) ):==cell_index
        }
    }
end
