*! tabbit 0.6.1
* Siobhan McAndrew, 2025
* Weighted crosstabulation tables exported to Excel
* Iorras abú

cap program drop tabbit
program define tabbit
    version 15.0

    /*
        tabbit varlist [if] [in] using filename, breakdown(varlist) [options]

        Required:
            breakdown(varlist)

        Main options:
            wtvar(varname)      weight variable (default equal weights)
            sheet(str)          sheet name (default "Frequencies")
            replace             replace Excel file
            bybreakdown         one sheet per breakdown variable
            mincoln(#)          suppress columns with unweighted N < #

        Missing:
            missingasrow        treat missing outcome as a row
            nomissing           suppress missing % line and missing row in N table

        Display:
            decimals(#)         decimal places for percentages (default 1)
            nooverall           drop overall % column
            nototal             drop Total % row
            rowpct              show row % instead of column %
            noformat            minimal formatting (no bold/italic)

        Export:
            longdata(filename)  reserved for future use
    */

    syntax varlist(min=1) [if] [in] using/, ///
        BREAKdown(varlist) ///
        [ WTVAR(varname numeric) ///
          SHEET(string asis) ///
          REPLACE ///
          BYBREAKDOWN ///
          MISSINGASROW ///
          NOMISSING ///
          MINCOLN(integer 0) ///
          DECIMALS(integer 1) ///
          NOOVERALL ///
          NOTOTAL ///
          ROWPCT ///
          LONGDATA(string asis) ///
          NOFORMAT ///
          MAYO ]

    // Undocumented option
    if "`mayo'" != "" {
        di as txt "💚❤️ Maigh Eo abú"
    }

    * Conflicting options: missingasrow vs nomissing
    if ("`missingasrow'" != "" & "`nomissing'" != "") {
        di as err "tabbit: options {bf:missingasrow} and {bf:nomissing} may not be combined"
        exit 198
    }

    * Sample indicator: observe if/in, do not drop missings on varlist
    marksample touse, novarlist

    * Flags from options
    local use_overall = ("`nooverall'" == "")
    local use_total   = ("`nototal'"   == "")
    local use_rowpct  = ("`rowpct'"    != "")
    local use_format  = ("`noformat'"  == "")
    local use_nomiss  = ("`nomissing'" != "")

    * Decimals: pass as number
    local dec = `decimals'
    if `dec' < 0 local dec = 0
    if `dec' > 6 local dec = 6

    * Excel file and sheet base
    local outfile    "`using'"
    local base_sheet "`sheet'"

    * Weight temp copy; default = 1
    tempvar wt_safe
    if "`wtvar'" != "" {
        quietly gen double `wt_safe' = `wtvar' if `touse'
    }
    else {
        quietly gen double `wt_safe' = 1 if `touse'
    }

    local corevars "`varlist'"
    local bvarlist "`breakdown'"
    local num_bvars : word count `bvarlist'

    local first = 1

    forvalues bi = 1/`num_bvars' {
        local bvar : word `bi' of `bvarlist'
        di as txt "tabbit: breakdown variable `bvar'"

        capture confirm variable `bvar'
        if _rc {
            di as err "tabbit: (skip) breakdown variable `bvar' not found"
            continue
        }

        quietly count if `touse' & !missing(`bvar')
        if r(N) == 0 {
            di as txt "tabbit: (skip) `bvar' has no non-missing values in sample"
            continue
        }

        * Sheet name
        if "`bybreakdown'" != "" {
            * One sheet per breakdown variable
            local sheetname "`bvar'"
        }
        else {
            * Single sheet for all breakdowns
            if trim("`base_sheet'") != "" local sheetname "`base_sheet'"
            else                         local sheetname "Frequencies"
        }
        * Excel sheet name limit is 31 characters
        local sheetname = substr("`sheetname'", 1, 31)

        * Open workbook
        if `first' {
            if "`replace'" != "" local wbopt "replace"
            else                 local wbopt "modify"
            local first = 0
        }
        else {
            local wbopt "modify"
        }

        putexcel set "`outfile'", sheet("`sheetname'") `wbopt'
		
		if _rc {
			di as err "tabbit: unable to open Excel file `outfile', sheet `sheetname' (rc=" _rc ")"
			exit _rc
		}


        * Row pointer for this sheet
        local row = 1

        * Simple header for the sheet
        if `use_format' {
            putexcel A`row' = "Outcome breakdowns by `bvar'", bold
        }
        else {
            putexcel A`row' = "Outcome breakdowns by `bvar'"
        }
        local row = `row' + 1

        * High-level description: branch on nomissing
        if `use_nomiss' {
            putexcel A`row' = "Weighted %, unweighted N"
            local row = `row' + 1
            putexcel A`row' = "Missing values for the outcome not included"
            local row = `row' + 2
        }
        else {
            putexcel A`row' = "Weighted %, unweighted N"
            local row = `row' + 1
            putexcel A`row' = "Weighted percentages exclude missing responses from main table"
            local row = `row' + 1
            putexcel A`row' = ///
                "Percentage of cases missing on the outcome variable reported beneath main table within each breakdown column"
            local row = `row' + 2
        }

        * Row/column % description
        if `use_rowpct' {
            putexcel A`row' = "Weighted row percentages", italic
        }
        else {
            putexcel A`row' = "Weighted column percentages", italic
        }
        local row = `row' + 1

        * Missing description depends on options
        if (`use_nomiss') {
            putexcel A`row' = ///
                "Missing outcome values excluded from tables and not reported separately"
        }
        else if ("`missingasrow'" != "") {
            putexcel A`row' = ///
                "Missing outcome values included in 'response missing' row in both tables"
        }
        else {
            putexcel A`row' = ///
                "Missing outcome values are excluded from weighted totals and reported below as % of column totals"
        }
        local row = `row' + 1

        * Unweighted N description
        if (`use_nomiss') {
            putexcel A`row' = ///
                "Unweighted Ns are based on non-missing outcome values only"
        }
        else {
            putexcel A`row' = ///
                "Unweighted Ns include missing within column totals"
        }
        local row = `row' + 2

        * Tables for each outcome variable
		foreach vv of local corevars {
			capture noisily tabbit_write_breakdown ///
				`vv' `bvar' `wt_safe' `touse' `row' ///
				"`missingasrow'" `mincoln' ///
				`dec' ///
				`use_overall' `use_total' `use_rowpct' `use_format' `use_nomiss'

			local rc = _rc
			if `rc' {
				di as err "tabbit: fatal error for v=`vv', bvar=`bvar' (rc=`rc')"

				// optional: try to save anything already written
				capture noisily putexcel save
				capture noisily putexcel close

				exit `rc'
			}

			// only reached if rc==0 (normal completion or a clean 'skip' case)
			local row = r(nextrow)
		}


			putexcel save
			if _rc {
			di as err "tabbit: error saving Excel file `outfile' (sheet `sheetname') (rc=" _rc ")"
			capture noisily putexcel close
			exit _rc
		}
		
	}

    capture noisily putexcel save
    capture noisily putexcel close

    di as txt "tabbit: breakdowns completed. Output saved to `outfile'"
end


* Convert 1, 2, ..., 26, 27, ... into A, B, ..., Z, AA, AB, ...
cap program drop tabbit_colname
program define tabbit_colname, rclass
    version 15.0
    syntax, IDX(integer)

    local n = `idx'
    local s ""
    while `n' > 0 {
        local rem = mod(`n' - 1, 26)
        local s   = char(65 + `rem') + "`s'"
        local n   = floor((`n' - 1)/26)
    }
    return local col "`s'"
end


* Write one table for v x bvar
cap program drop tabbit_write_breakdown
program define tabbit_write_breakdown, rclass
    version 15.0

    // args: v bvar wtvar touse row missingasrow mincoln decimals use_overall use_total use_rowpct use_format use_nomiss
    args v bvar wt_safe touse row missingasrow mincoln decimals use_overall use_total use_rowpct use_format use_nomiss

    local currow       = `row'
    local use_missrow  = ("`missingasrow'" != "")
    local drop_missing = (`use_nomiss' == 1)
    local mincoln      = `mincoln'

    // decimals() -> number format for percentages
    local d = `decimals'
    if `d' < 0 local d = 0
    if `d' > 6 local d = 6

    local fmt_pct "0"
    if `d' > 0 {
        local fmt_pct "0."
        forvalues k = 1/`d' {
            local fmt_pct "`fmt_pct'0"
        }
    }

    // Basic checks
    capture confirm variable `v'
    if _rc exit
    capture confirm variable `bvar'
    if _rc exit

    quietly count if `touse' & !missing(`v') & !missing(`bvar')
    if r(N) == 0 exit

    // Convert to numeric, keep value labels
    tempvar vN bN

    // v -> vN
    capture confirm string variable `v'
    if !_rc {
        quietly encode `v' if `touse', gen(`vN')
    }
    else {
        local vlab_orig : value label `v'
        quietly gen long `vN' = `v' if `touse'
        if "`vlab_orig'" != "" label values `vN' `vlab_orig'
    }

    // bvar -> bN
    capture confirm string variable `bvar'
    if !_rc {
        quietly encode `bvar' if `touse', gen(`bN')
    }
    else {
        local blab_orig : value label `bvar'
        quietly gen long `bN' = `bvar' if `touse'
        if "`blab_orig'" != "" label values `bN' `blab_orig'
    }

    // Levels among valid cells (for % block)
    if `use_missrow' {
        quietly levelsof `vN' if `touse' & !missing(`bN'), missing ///
            local(row_levels_valid)
    }
    else {
        quietly levelsof `vN' if `touse' & !missing(`vN') & !missing(`bN'), ///
            local(row_levels_valid)
    }
    quietly levelsof `bN' if `touse' & !missing(`bN'), local(col_levels_valid)

    local r : word count `row_levels_valid'
    local c : word count `col_levels_valid'
    if (`r' == 0 | `c' == 0) exit

    // Apply mincoln() threshold (based on unweighted column N)
    if `mincoln' > 0 {
        local col_keep ""
        foreach cl of local col_levels_valid {
            quietly count if `touse' & `bN' == `cl'
            if (r(N) >= `mincoln') local col_keep `col_keep' `cl'
        }
        local col_levels_valid "`col_keep'"
        local c : word count `col_levels_valid'
        if `c' == 0 exit
    }

    // Row labels
    local rowhdr_valid
    local vlabN : value label `vN'
    foreach rl of local row_levels_valid {
        local txt "`rl'"
        if "`vlabN'" != "" & "`rl'" != "." {
            local t2 : label `vlabN' `rl'
            if "`t2'" != "" local txt "`t2'"
        }
        if "`rl'" == "." local txt "Response missing"
        local txt : display substr("`txt'", 1, 60)
        local rowhdr_valid `"`rowhdr_valid' "`txt'""'
    }

    // Column headers (valid subset)
    local colhdr_valid_subset ""
    local bvlabN : value label `bN'
    foreach cl of local col_levels_valid {
        local txt "`cl'"
        if "`bvlabN'" != "" {
            local t2 : label `bvlabN' `cl'
            if "`t2'" != "" local txt "`t2'"
        }
        // strip tabs/newlines and trim
        local txt : display ustrtrim(ustrregexra("`txt'","[\r\n\t]"," "))
        local txt : display substr("`txt'", 1, 28)
        // add % symbol for % table
        local txt "`txt' %"
        local colhdr_valid_subset `"`colhdr_valid_subset' "`txt'""'
    }

    // Weighted matrix Mw (r x c)
    tempname Mw
    matrix `Mw' = J(`r', `c', 0)

    local j = 0
    foreach cl of local col_levels_valid {
        local ++j
        local i = 0
        foreach rl of local row_levels_valid {
            local ++i
            quietly summarize `wt_safe' if `touse' & `vN' == `rl' & `bN' == `cl'
            local wsum = r(sum)
            if missing(`wsum') local wsum = 0
            matrix `Mw'[`i',`j'] = `wsum'
        }
    }

    // Column totals of weighted base (always needed)
    tempname coltot
    matrix ones_r = J(`r', 1, 1)
    matrix `coltot' = ones_r' * `Mw'   // 1 x c

    // Percentages: column (default) or row
    tempname rowtot
    tempname P
    if `use_rowpct' == 0 {
        // column %
        tempname invcol
        matrix `invcol' = `coltot'
        forvalues j = 1/`c' {
            scalar __ct = `coltot'[1,`j']
            scalar __f  = cond(__ct > 0, 100/__ct, 0)
            matrix `invcol'[1,`j'] = __f
        }
        matrix `P' = `Mw' * diag(`invcol')
    }
    else {
        // row %
        matrix ones_c = J(`c',1,1)
        matrix `rowtot' = `Mw' * ones_c   // r x 1
        tempname invrow
        matrix `invrow' = J(`r',1,0)
        forvalues i = 1/`r' {
            scalar __rt = `rowtot'[`i',1]
            scalar __f  = cond(__rt > 0, 100/__rt, 0)
            matrix `invrow'[`i',1] = __f
        }
        matrix `P' = diag(`invrow') * `Mw'
    }

    // Overall % over rows (ignoring breakdown) – row distribution
    matrix ones_c_all = J(`c',1,1)
    matrix `rowtot' = `Mw' * ones_c_all   // r x 1
    tempname grandvec
    matrix `grandvec' = J(1,`r',1) * `rowtot'
    scalar grand = `grandvec'[1,1]

    tempname OverallP
    matrix `OverallP' = J(`r',1,0)
    forvalues i = 1/`r' {
        scalar __rt = `rowtot'[`i',1]
        matrix `OverallP'[`i',1] = cond(grand > 0, 100*__rt/grand, 0)
    }

    // Row totals of percentage table (for rowpct mode)
    tempname RowP
    if `use_rowpct' {
        matrix ones_cP = J(`c',1,1)
        matrix `RowP' = `P' * ones_cP   // r x 1, sums across columns
    }

    // Write weighted % block
    local v_label : variable label `v'
    if "`v_label'" == "" local v_label "`v'"

    if `use_format' {
        putexcel A`currow' = "Variable: `v'", bold
    }
    else {
        putexcel A`currow' = "Variable: `v'"
    }
    local currow = `currow' + 1
    putexcel A`currow' = "`v_label'"
    local currow = `currow' + 1

    // Header row
    putexcel A`currow' = "Response (valid only)", bold
    forvalues j = 1/`c' {
        local colnum = 1 + `j'
        tabbit_colname, idx(`colnum')
        local COL = r(col)
        local __hdr : word `j' of `colhdr_valid_subset'
        putexcel `COL'`currow' = "`__hdr'", bold
    }

    // Positions of extra overall columns
    local overall_colnum = 2 + `c'
    local trow_colnum    = .

    if (`use_rowpct' & `use_overall') {
        local trow_colnum    = 2 + `c'
        local overall_colnum = 3 + `c'
    }

    // Get Excel column letters
    tabbit_colname, idx(`overall_colnum')
    local OCOL = r(col)
    if (`use_rowpct' & `use_overall') {
        tabbit_colname, idx(`trow_colnum')
        local TROWCOL = r(col)
    }

    if `use_overall' {
        if `use_rowpct' {
            putexcel `TROWCOL'`currow' = ///
                "Overall row % (across breakdowns)", bold
        }
        putexcel `OCOL'`currow' = ///
            "Overall % (valid, all breakdowns)", bold
    }

    // Bases under headers
    local base_row = `currow' + 1
    putexcel A`base_row' = "Weighted base W (valid)"
    putexcel B`base_row' = matrix(`coltot'), nformat("0")

    tempname Nvalid
    matrix `Nvalid' = J(1,`c',0)
    local jj = 0
    foreach cl of local col_levels_valid {
        local ++jj
        quietly count if `touse' & !missing(`vN') & !missing(`bN') & `bN' == `cl'
        matrix `Nvalid'[1,`jj'] = r(N)
    }
    local base_row2 = `base_row' + 1
    putexcel A`base_row2' = "Unweighted base N (valid)"
    putexcel B`base_row2' = matrix(`Nvalid'), nformat("0")

    // Data block
    local data_row = `base_row2' + 1

    // Row labels
    local i = 0
    foreach rh of local rowhdr_valid {
        local ++i
        local rr = `data_row' + `i' - 1
        putexcel A`rr' = "`rh'"
    }

    // Weighted %s
    putexcel B`data_row' = matrix(`P'), nformat("`fmt_pct'")

    if `use_overall' {
        if `use_rowpct' {
            // Row totals from P (should be ~100 each)
            putexcel `TROWCOL'`data_row' = matrix(`RowP'), nformat("`fmt_pct'")
        }
        // Overall distribution across all breakdowns
        putexcel `OCOL'`data_row' = matrix(`OverallP'), nformat("`fmt_pct'")
    }

    // Total row: meaning depends on rowpct
    local rows_p = rowsof(`P')
    local totalpct_row = `data_row' + `rows_p'

    if `use_total' {
        if `use_rowpct' == 0 {
            // Column mode: Total % (sanity check – should be ~100)
            putexcel A`totalpct_row' = "Total %"
            tempname ColTotP
            matrix `ColTotP' = J(1,`rows_p',1) * `P'    // 1 x c
            putexcel B`totalpct_row' = matrix(`ColTotP'), nformat("`fmt_pct'")
            // (Optional) could also put 100 in overall column here if desired
        }
        else {
            // Row mode: show column share of total weighted base
            putexcel A`totalpct_row' = "Column share % (of total weighted base)"
            tempname ColShare
            matrix `ColShare' = (100/grand) * `coltot'   // 1 x c
            putexcel B`totalpct_row' = matrix(`ColShare'), nformat("`fmt_pct'")

            // Also show totals in the overall columns to guide the reader
            if (`use_overall') {
                // Overall row % total = 100
                if ("`TROWCOL'" != "") {
                    putexcel `TROWCOL'`totalpct_row' = 100, nformat("`fmt_pct'")
                }
                // Overall % (valid, all breakdowns) total = 100
                putexcel `OCOL'`totalpct_row' = 100, nformat("`fmt_pct'")
            }
        }
    }


    // Missing % row (unless missingasrow or nomissing)
    local miss_row = `totalpct_row'
    if (`drop_missing' == 0 & `use_missrow' == 0) {
        tempname Mmiss
        matrix `Mmiss' = J(1,`c',0)

        local j = 0
        foreach cl of local col_levels_valid {
            local ++j

            quietly summarize `wt_safe' if `touse' & missing(`vN') & `bN' == `cl'
            local wmiss = r(sum)
            if missing(`wmiss') local wmiss = 0

            scalar __den  = `coltot'[1,`j'] + `wmiss'
            scalar __pctm = cond(__den > 0, 100*`wmiss'/__den, 0)

            matrix `Mmiss'[1,`j'] = __pctm
        }

        quietly summarize `wt_safe' if `touse' & missing(`vN') & !missing(`bN')
        local wmiss_all = r(sum)
        if missing(`wmiss_all') local wmiss_all = 0

        quietly summarize `wt_safe' if `touse' & !missing(`vN') & !missing(`bN')
        local wvalid_all = r(sum)
        if missing(`wvalid_all') local wvalid_all = 0

        scalar __den_all = `wmiss_all' + `wvalid_all'
        scalar overall_miss_pct = cond(__den_all > 0, 100*`wmiss_all'/__den_all, 0)

        // First row: short label
        local miss_row = `totalpct_row' + 1
        putexcel A`miss_row' = "Missing %"

        // Second row: explanation + numbers
        local miss_row = `miss_row' + 1
        putexcel A`miss_row' = ///
            "(weighted; denominator = column total)"
        putexcel B`miss_row' = matrix(`Mmiss'), nformat("`fmt_pct'")
        if `use_overall' {
            putexcel `OCOL'`miss_row' = overall_miss_pct, nformat("`fmt_pct'")
        }
    }

    // Unweighted N (responses incl. missing or not, depending on nomissing)
    if `drop_missing' {
        quietly levelsof `vN' if `touse' & !missing(`vN') & !missing(`bN'), ///
            local(row_levels_all)
    }
    else {
        quietly levelsof `vN' if `touse' & !missing(`bN'), missing ///
            local(row_levels_all)
    }
    local rN : word count `row_levels_all'

    quietly levelsof `bN' if `touse', local(col_levels_all)
    if `mincoln' > 0 {
        local col_keep2 ""
        foreach cl of local col_levels_all {
            quietly count if `touse' & `bN' == `cl'
            if (r(N) >= `mincoln') local col_keep2 `col_keep2' `cl'
        }
        local col_levels_all "`col_keep2'"
    }
    local ncol_all : word count `col_levels_all'

    if `rN' > 0 & `ncol_all' > 0 {
        tempname Mn
        matrix `Mn' = J(`rN', `ncol_all', 0)

        local j = 0
        foreach cl of local col_levels_all {
            local ++j
            local i = 0
            foreach lev of local row_levels_all {
                local ++i
                if ("`lev'" == "." & `drop_missing' == 0) {
                    quietly count if `touse' & missing(`vN') & `bN' == `cl'
                }
                else {
                    quietly count if `touse' & `vN' == `lev' & `bN' == `cl'
                }
                matrix `Mn'[`i',`j'] = r(N)
            }
        }

        // Headers for N table
        local n_colhdr ""
        foreach cl of local col_levels_all {
            local txt "`cl'"
            if "`bvlabN'" != "" {
                local t2 : label `bvlabN' `cl'
                if "`t2'" != "" local txt "`t2'"
            }
            local txt : display ustrtrim(ustrregexra("`txt'","[\r\n\t]"," "))
            local txt : display substr("`txt'", 1, 31)
            local n_colhdr `"`n_colhdr' "`txt'""'
        }

        local n_head_row = `miss_row' + 2
        putexcel A`n_head_row' = "Response", bold

        forvalues j = 1/`ncol_all' {
            local colnum = 1 + `j'
            tabbit_colname, idx(`colnum')
            local __nh : word `j' of `n_colhdr'
            putexcel `r(col)'`n_head_row' = "`__nh'", bold
        }
        local totaln_colnum = 2 + `ncol_all'
        tabbit_colname, idx(`totaln_colnum')
        local NCOL = r(col)
        putexcel `NCOL'`n_head_row' = "Total N", bold

        // Row labels for N table
        local vvl_all : value label `vN'
        local n_data_row = `n_head_row' + 1
        local i = 0
        foreach lev of local row_levels_all {
            local ++i
            local rr = `n_data_row' + `i' - 1
            local txt "`lev'"
            if "`vvl_all'" != "" & "`lev'" != "." {
                local t2 : label `vvl_all' `lev'
                if "`t2'" != "" local txt "`t2'"
            }
            if ("`lev'" == "." & `drop_missing' == 0) local txt "Response missing"
            local __rowtxt : display substr("`txt'", 1, 60)
            putexcel A`rr' = "`__rowtxt'"
        }

        // Data
        putexcel B`n_data_row' = matrix(`Mn'), nformat("0")

        // Column totals
        matrix ones_rN = J(1,`rN',1)
        tempname ColTotN
        matrix `ColTotN' = ones_rN * `Mn'
        local count_total_row = `n_data_row' + `rN'
        putexcel A`count_total_row' = "Column totals"
        putexcel B`count_total_row' = matrix(`ColTotN'), nformat("0")

        // Row totals and grand total
        matrix ones_cN = J(`ncol_all',1,1)
        tempname RowTotN
        matrix `RowTotN' = `Mn' * ones_cN
        putexcel `NCOL'`n_data_row' = matrix(`RowTotN'), nformat("0")

        tempname G
        matrix `G' = J(1,`rN',1) * `RowTotN'
        scalar GrandN = `G'[1,1]
        putexcel `NCOL'`count_total_row' = GrandN, nformat("0")

        local currow = `count_total_row' + 1
    }
    else {
        local currow = `miss_row' + 1
    }

    // Spacer between variables
    putexcel A`currow' = ""
    local currow = `currow' + 1

    putexcel A`currow' = "=============================================================="
    local currow = `currow' + 1

    putexcel A`currow' = ""
    local currow = `currow' + 1

    return scalar nextrow = `currow'
end


* Hidden companion command
cap program drop tabbit_mayo
program define tabbit_mayo
    version 15.0
    di as txt "💚❤️ Maigh Eo abú"
end
