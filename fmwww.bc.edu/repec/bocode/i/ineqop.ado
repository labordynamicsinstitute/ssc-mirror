*! Program to compute inequality of opportunity (IO) decomposition
*! Following Gradín and Zapata Román (2026), Review of Income and Wealth
*! Carlos Gradín
*! This version 1.0, March 2026

/*
	ineqop: Estimates the contribution of birth circumstances to overall
	inequality using direct, indirect, and Shapley decompositions.

	Syntax:
		ineqop y [aw/fw/iw] [if] [in], type(varlist) [options]

	Required:
		y           : outcome variable (e.g., income)
		type(varlist): one or more circumstance variables defining types

	Options:
		GIni        : include Gini index (included by default)
		GE(numlist) : GE indices to compute (default: -1 0 1 2)
		PATtern     : produce graph of IO shares across indices
		BYPATtern   : combined 2x2 figure over by-groups (use with bys)
		CONTributions : produce graph with RIF contributions by type (Shapley)
		CONTRTable  : display table with Shapley RIF contributions by type
		CONTRIndex(str): index for contributions graph (default: gini)
		DESCriptives: display table with distribution of circumstances
		TREnd       : plot trends over by-groups (Figures 3 & 4)
		TREndindex(str): index for Figure 3 trend levels (default: gini)
		GENerate(str): generate yb and yw variables (two names required)
		LORenz      : produce Lorenz curve graphs (Figure A3)
		ALL         : turn on all output options at once
		Format(str) : display format (default: %9.4f)
		FORMatp(str): display format for percentages (default: %9.1f)
		DETail      : show additional details (BM decomposition for Gini)
*/

cap program drop ineqop
program def ineqop, rclass byable(recall) sortpreserve
	version 14
	syntax varlist(min=1 max=1) [aweight iweight fweight] [if] [in] , ///
		Type(varlist) ///
		[ GIni noGIni GE(numlist) ///
		  PATtern BYPATtern CONTributions CONTRTable CONTRIndex(string) ///
		  DESCriptives TREnd TREndindex(string) ///
		  GENerate(string) LORenz ///
		  ALL ///
		  Format(string) FORMatp(string) DETail ]

	marksample touse
	set more off

	* If 'all' is specified, turn on all output options
	if "`all'" != "" {
		local pattern     "pattern"
		local contributions "contributions"
		local contrtable  "contrtable"
		local descriptives "descriptives"
		local lorenz      "lorenz"
		local detail      "detail"
		* bypattern and trend only make sense with by:
		if "`_byvars'" != "" {
			local bypattern   "bypattern"
			local trend       "trend"
		}
	}

	* ------------------------------------------------------------------
	* 0. Setup: variable names, weights, formats
	* ------------------------------------------------------------------

	* Detect by-group value for graph naming
	local _byvars "`_byvars'"
	local _bysuf ""
	if "`_byvars'" != "" {
		local _byvar1 : word 1 of `_byvars'
		qui sum `_byvar1' if `touse', meanonly
		local _gbyval = r(min)
		* Create a clean suffix for graph names (e.g., _2022)
		local _bysuf "_`: di %8.0g `_gbyval''"
		local _bysuf = trim("`_bysuf'")
		local _bysuf = subinstr("`_bysuf'", " ", "", .)
	}

	local y : word 1 of `varlist'

	if "`format'" == "" {
		local format "%9.4f"
	}
	if "`formatp'" == "" {
		local formatp "%9.1f"
	}

	* Weight handling
	tempvar w
	if "`weight'" == "" {
		qui gen double `w' = 1 if `touse'
	}
	else {
		qui gen double `w' `exp' if `touse'
	}

	* ------------------------------------------------------------------
	* 1. Create type variable from circumstance variables
	* ------------------------------------------------------------------

	tempvar typevar

	* Count number of variables in type()
	local ntvars : word count `type'

	if `ntvars' == 1 {
		* Single variable: use it directly as the type
		qui gen `typevar' = `type' if `touse'
	}
	else {
		* Multiple variables: create types from all combinations
		* Use egen group() to create unique type identifiers
		qui egen `typevar' = group(`type') if `touse', missing
	}

	* ------------------------------------------------------------------
	* Check for missing values in y, weights, and type
	* ------------------------------------------------------------------

	* Count initial sample
	qui count if `touse'
	local _n_initial = r(N)

	* Flag observations with missing outcome
	qui count if `touse' & missing(`y')
	local _nmiss_y = r(N)

	* Flag observations with missing weight
	qui count if `touse' & missing(`w')
	local _nmiss_w = r(N)

	* Flag observations with missing type
	qui count if `touse' & missing(`typevar')
	local _nmiss_t = r(N)

	* Drop all observations with any missing value
	qui replace `touse' = 0 if missing(`y') | missing(`w') | missing(`typevar')

	* Count final sample
	qui count if `touse'
	local _n_final = r(N)
	local _nmiss_total = `_n_initial' - `_n_final'

	* Display warning if any observations were dropped
	if `_nmiss_total' > 0 {
		di as text ""
		di as text "{hline 60}"
		di as text "Warning: `_nmiss_total' observations with missing values" ///
			" not used in calculations."
		if `_nmiss_y' > 0 {
			di as text "  - outcome variable (`y'): `_nmiss_y' missing"
		}
		if `_nmiss_w' > 0 {
			di as text "  - weights: `_nmiss_w' missing"
		}
		if `_nmiss_t' > 0 {
			di as text "  - type variable(s) (`type'): `_nmiss_t' missing"
		}
		di as text "Using `_n_final' complete observations."
		di as text "{hline 60}"
		di as text ""
	}

	* ------------------------------------------------------------------
	* Check for zero or negative values in outcome variable
	* ------------------------------------------------------------------

	* Count zeros and negatives
	qui count if `touse' & `y' == 0
	local _n_zero = r(N)
	qui count if `touse' & `y' < 0
	local _n_neg = r(N)
	local _n_nonpos = `_n_zero' + `_n_neg'

	* Flag which GE indices cannot be computed
	* GE(a) for a <= 1 requires strictly positive incomes (uses log)
	* GE(2) = half squared CV, can handle zeros but not negatives
	local _has_zero = (`_n_zero' > 0)
	local _has_neg  = (`_n_neg' > 0)

	if `_n_nonpos' > 0 {
		di as text ""
		di as text "{hline 60}"
		di as text "Warning: outcome variable (`y') contains" ///
			" non-positive values."
		if `_n_neg' > 0 {
			di as text "  - `_n_neg' negative observations"
		}
		if `_n_zero' > 0 {
			di as text "  - `_n_zero' zero observations"
		}
		di as text "GE indices with alpha <= 1 (GE(-1), MLD, Theil)" ///
			" require"
		di as text "strictly positive values and will not be computed."
		di as text "Consider removing these observations" ///
			" if you want all indices."
		di as text "{hline 60}"
		di as text ""
	}

	* ------------------------------------------------------------------
	* 2. Set default indices
	* ------------------------------------------------------------------

	* Default: compute Gini and GE(-1, 0, 1, 2)
	local do_gini = 1
	if "`nogini'" != "" {
		local do_gini = 0
	}

	if "`ge'" == "" {
		local ge "-1 0 1 2"
	}

	* Remove GE indices that cannot be computed with non-positive values
	* GE(a) for a <= 1 uses log(y) or 1/y, requiring y > 0
	* GE(a) for a > 1 (e.g., GE(2)=½CV²) does not require y > 0
	if `_n_nonpos' > 0 {
		local _ge_ok ""
		foreach a of local ge {
			if `a' <= 1 {
				local _aname = cond(`a'==0, "MLD", cond(`a'==1, "Theil", "GE(`a')"))
				di as text "Note: `_aname' dropped" ///
					" (requires strictly positive values)."
				continue
			}
			local _ge_ok "`_ge_ok' `a'"
		}
		local ge = trim("`_ge_ok'")
		if "`ge'" == "" & `do_gini' == 0 {
			di as error "No inequality index can be computed" ///
				" with the current data."
			error 459
		}
	}

	* Validate contrindex option (default: gini)
	if "`contrindex'" == "" {
		local contrindex "gini"
	}
	local contrindex = lower("`contrindex'")
	if !inlist("`contrindex'", "gini", "ge-1", "ge0", "ge1", "ge2") {
		* Check against the user-specified GE list
		local _ci_ok = 0
		if "`contrindex'" == "gini" & `do_gini' {
			local _ci_ok = 1
		}
		foreach a of local ge {
			if "`contrindex'" == "ge`a'" {
				local _ci_ok = 1
			}
		}
		if !`_ci_ok' {
			di as error "contrindex(`contrindex') is not among the computed indices."
			di as error "Valid values: gini, ge-1, ge0, ge1, ge2 (matching your ge() list)."
			error 198
		}
	}

	* Validate trendindex option (default: gini)
	if "`trendindex'" == "" {
		local trendindex "gini"
	}
	local trendindex = lower("`trendindex'")

	* ------------------------------------------------------------------
	* 3. Construct counterfactual distributions: y_b and y_w
	* ------------------------------------------------------------------

	* y_b = smoothed distribution (replace each y with type mean)
	* y_w = standardized distribution (rescale each type to overall mean)

	tempvar yb yw ymean gmean sw_tot yw_tot

	* Overall mean
	qui sum `y' [aw=`w'] if `touse'
	local mu = r(mean)
	local N  = r(N)
	local sw = r(sum_w)

	if `mu' <= 0 {
		di as error "Overall mean is non-positive (`mu'). Cannot compute all indices."
	}

	* Type means (weighted)
	tempvar type_mean type_sw
	qui bysort `typevar' (`y'): egen double `type_mean' = total(`y' * `w') if `touse'
	qui bysort `typevar' (`y'): egen double `type_sw'   = total(`w') if `touse'
	qui replace `type_mean' = `type_mean' / `type_sw' if `touse'

	* y_b: smoothed distribution — everyone gets their type mean
	qui gen double `yb' = `type_mean' if `touse'

	* y_w: standardized distribution — rescale so all types have overall mean
	qui gen double `yw' = `y' * `mu' / `type_mean' if `touse'

	* Population share of each type
	tempvar pg
	qui gen double `pg' = `type_sw' / `sw' if `touse'

	* ------------------------------------------------------------------
	* 3b. Generate user-requested variables (gen option)
	* ------------------------------------------------------------------

	if "`generate'" != "" {
		local _gen_n : word count `generate'
		if `_gen_n' != 2 {
			di as error "gen() requires exactly two variable names: gen(yb_name yw_name)"
			error 198
		}
		local _gen_yb : word 1 of `generate'
		local _gen_yw : word 2 of `generate'

		* Check variables do not already exist
		cap confirm new variable `_gen_yb'
		if _rc {
			di as error "variable `_gen_yb' already exists"
			error 110
		}
		cap confirm new variable `_gen_yw'
		if _rc {
			di as error "variable `_gen_yw' already exists"
			error 110
		}

		qui gen double `_gen_yb' = `yb' if `touse'
		qui gen double `_gen_yw' = `yw' if `touse'
		label variable `_gen_yb' "Smoothed distribution (type means)"
		label variable `_gen_yw' "Standardized distribution (equalized means)"
		di as text "Variables `_gen_yb' and `_gen_yw' created."
	}

	* ------------------------------------------------------------------
	* 4. Compute inequality indices for y, y_b, y_w
	* ------------------------------------------------------------------

	* We need Gini and GE(alpha) for each of y, yb, yw

	* ============ GINI ============

	if `do_gini' {
		* Gini of y
		qui _ineqop_gini `y' `w' `touse'
		local G_y = r(gini)

		* Gini of y_b
		qui _ineqop_gini `yb' `w' `touse'
		local G_yb = r(gini)

		* Gini of y_w
		qui _ineqop_gini `yw' `w' `touse'
		local G_yw = r(gini)

		* BM within (weighted sum of within-group Ginis)
		local G_BM_within = 0
		qui levelsof `typevar' if `touse', local(types)
		tempvar _condvar
		qui gen byte `_condvar' = 0
		foreach t of local types {
			qui replace `_condvar' = (`typevar' == `t')
			qui _ineqop_gini `y' `w' `touse' `_condvar'
			local g_t = r(gini)
			qui sum `w' if `touse' & `typevar' == `t', meanonly
			local sw_t = r(sum)
			qui sum `y' [aw=`w'] if `touse' & `typevar' == `t', meanonly
			local mu_t = r(mean)
			local G_BM_within = `G_BM_within' + (`sw_t'/`sw') * (`mu_t'/`mu') * `g_t'
		}
		local G_BM_residual = `G_y' - `G_yb' - `G_BM_within'

		* Interaction
		local G_Ibw = `G_y' - `G_yb' - `G_yw'

		* IO shares
		local G_IOD = `G_yb' / `G_y' * 100
		local G_IOI = (`G_y' - `G_yw') / `G_y' * 100
		local G_IOs = (`G_yb' + 0.5 * `G_Ibw') / `G_y' * 100

		* IR shares
		local G_IRD = (`G_y' - `G_yb') / `G_y' * 100
		local G_IRI = `G_yw' / `G_y' * 100
		local G_IRs = (`G_yw' + 0.5 * `G_Ibw') / `G_y' * 100

		* Shapley values
		local G_Isb = `G_yb' + 0.5 * `G_Ibw'
		local G_Isw = `G_yw' + 0.5 * `G_Ibw'

		* Return scalars
		ret scalar G_y   = `G_y'
		ret scalar G_yb  = `G_yb'
		ret scalar G_yw  = `G_yw'
		ret scalar G_Ibw = `G_Ibw'
		ret scalar G_Isb = `G_Isb'
		ret scalar G_Isw = `G_Isw'
		ret scalar G_IOD = `G_IOD'
		ret scalar G_IOI = `G_IOI'
		ret scalar G_IOs = `G_IOs'
	}

	* ============ GE indices ============

	local j = 0
	foreach a of local ge {
		local j = `j' + 1

		* GE(a) of y
		qui _ineqop_ge `y' `w' `touse' `a'
		local GE`j'_y = r(ge)

		* GE(a) of y_b
		qui _ineqop_ge `yb' `w' `touse' `a'
		local GE`j'_yb = r(ge)

		* GE(a) of y_w
		qui _ineqop_ge `yw' `w' `touse' `a'
		local GE`j'_yw = r(ge)

		* Interaction
		local GE`j'_Ibw = `GE`j'_y' - `GE`j'_yb' - `GE`j'_yw'

		* IO shares (as percentages)
		local GE`j'_IOD = `GE`j'_yb' / `GE`j'_y' * 100
		local GE`j'_IOI = (`GE`j'_y' - `GE`j'_yw') / `GE`j'_y' * 100
		local GE`j'_IOs = (`GE`j'_yb' + 0.5 * `GE`j'_Ibw') / `GE`j'_y' * 100

		* IR shares
		local GE`j'_IRD = (`GE`j'_y' - `GE`j'_yb') / `GE`j'_y' * 100
		local GE`j'_IRI = `GE`j'_yw' / `GE`j'_y' * 100
		local GE`j'_IRs = (`GE`j'_yw' + 0.5 * `GE`j'_Ibw') / `GE`j'_y' * 100

		* Shapley values
		local GE`j'_Isb = `GE`j'_yb' + 0.5 * `GE`j'_Ibw'
		local GE`j'_Isw = `GE`j'_yw' + 0.5 * `GE`j'_Ibw'

		* Return scalars
		local atxt = subinstr("`a'", "-", "m", .)
		ret scalar GE`atxt'_y   = `GE`j'_y'
		ret scalar GE`atxt'_yb  = `GE`j'_yb'
		ret scalar GE`atxt'_yw  = `GE`j'_yw'
		ret scalar GE`atxt'_Ibw = `GE`j'_Ibw'
		ret scalar GE`atxt'_Isb = `GE`j'_Isb'
		ret scalar GE`atxt'_Isw = `GE`j'_Isw'
		ret scalar GE`atxt'_IOD = `GE`j'_IOD'
		ret scalar GE`atxt'_IOI = `GE`j'_IOI'
		ret scalar GE`atxt'_IOs = `GE`j'_IOs'
	}
	local nge = `j'

	* ------------------------------------------------------------------
	* 5. Display Table 1
	* ------------------------------------------------------------------

	* Build header
	di ""
	di as text "{hline 100}"
	di as text "Inequality of opportunity decomposition"
	di as text "Outcome variable: " as result "`y'" as text "  |  Mean = " as result `format' `mu'
	di as text "N = " as result `N' as text "  |  Types defined by: " as result "`type'"
	di as text "{hline 100}"
	di ""

	* Column headers
	local ncols = `do_gini' + `nge'

	* Build column labels
	local collabels ""
	if `do_gini' {
		local collabels "Gini"
	}
	local j = 0
	foreach a of local ge {
		local j = `j' + 1
		if `a' == 0 {
			local collabels `"`collabels' "GE(`a') (MLD)""'
		}
		else if `a' == 1 {
			local collabels `"`collabels' "GE(`a') (Theil)""'
		}
		else if `a' == 2 {
			local collabels `"`collabels' "GE(`a') (1/2CV2)""'
		}
		else {
			local collabels `"`collabels' "GE(`a')""'
		}
	}

	* Display the table header row
	di as text _col(3) "{ralign 30:}" _c
	if `do_gini' {
		di as text _col(35) "{ralign 12:Gini}" _c
	}
	local col = 35 + `do_gini' * 14
	local j = 0
	foreach a of local ge {
		local j = `j' + 1
		if `a' == 0 {
			di as text _col(`col') "{ralign 12:GE(`a')=MLD}" _c
		}
		else if `a' == 1 {
			di as text _col(`col') "{ralign 12:GE(`a')=Theil}" _c
		}
		else {
			di as text _col(`col') "{ralign 12:GE(`a')}" _c
		}
		local col = `col' + 14
	}
	di ""
	di as text "{hline 100}"

	* Row: Overall I(y)
	di as text _col(3) "{ralign 30:Overall I(y)}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_y' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_y' _c
		local col = `col' + 14
	}
	di ""

	* DIRECT APPROACH
	di ""
	di as text _col(3) "Direct approach"

	* Between: I(y_b)
	di as text _col(5) "{ralign 28:Between I(y_b)}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_yb' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_yb' _c
		local col = `col' + 14
	}
	di ""

	* IO^D %
	di as text _col(5) "{ralign 28:IO^D %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IOD' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IOD' _c
		local col = `col' + 14
	}
	di ""

	* Within: I(y) - I(y_b)
	di as text _col(5) "{ralign 28:Within I(y)-I(y_b)}" _c
	if `do_gini' {
		local tmp = `G_y' - `G_yb'
		di as result _col(35) `format' `tmp' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		local tmp = `GE`j'_y' - `GE`j'_yb'
		di as result _col(`col') `format' `tmp' _c
		local col = `col' + 14
	}
	di ""

	* IR^I %
	di as text _col(5) "{ralign 28:IR^I %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IRD' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IRD' _c
		local col = `col' + 14
	}
	di ""

	* BM detail for Gini (only if detail option)
	if `do_gini' & "`detail'" != "" {
		di ""
		di as text _col(5) "  of which (Gini only):"
		di as text _col(7) "{ralign 26:BM 'within' weighted}" _c
		di as result _col(35) `format' `G_BM_within' _c
		di ""
		di as text _col(7) "{ralign 26:% }" _c
		local tmp = `G_BM_within' / `G_y' * 100
		di as result _col(35) `formatp' `tmp' _c
		di ""
		di as text _col(7) "{ralign 26:BM residual}" _c
		di as result _col(35) `format' `G_BM_residual' _c
		di ""
		di as text _col(7) "{ralign 26:% }" _c
		local tmp = `G_BM_residual' / `G_y' * 100
		di as result _col(35) `formatp' `tmp' _c
		di ""
	}

	* INDIRECT APPROACH
	di ""
	di as text _col(3) "Indirect approach"

	* Between: I(y) - I(y_w)
	di as text _col(5) "{ralign 28:Between I(y)-I(y_w)}" _c
	if `do_gini' {
		local tmp = `G_y' - `G_yw'
		di as result _col(35) `format' `tmp' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		local tmp = `GE`j'_y' - `GE`j'_yw'
		di as result _col(`col') `format' `tmp' _c
		local col = `col' + 14
	}
	di ""

	* IO^I %
	di as text _col(5) "{ralign 28:IO^I %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IOI' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IOI' _c
		local col = `col' + 14
	}
	di ""

	* Within: I(y_w)
	di as text _col(5) "{ralign 28:Within I(y_w)}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_yw' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_yw' _c
		local col = `col' + 14
	}
	di ""

	* IR^D %
	di as text _col(5) "{ralign 28:IR^D %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IRI' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IRI' _c
		local col = `col' + 14
	}
	di ""

	* INTERACTION
	di ""
	di as text _col(3) "Interaction"

	* I_bw
	di as text _col(5) "{ralign 28:I_bw = I(y)-I(y_b)-I(y_w)}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_Ibw' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_Ibw' _c
		local col = `col' + 14
	}
	di ""

	* I_bw / I(y) %
	di as text _col(5) "{ralign 28:I_bw/I(y) %}" _c
	if `do_gini' {
		local tmp = `G_Ibw' / `G_y' * 100
		di as result _col(35) `formatp' `tmp' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		local tmp = `GE`j'_Ibw' / `GE`j'_y' * 100
		di as result _col(`col') `formatp' `tmp' _c
		local col = `col' + 14
	}
	di ""

	* SHAPLEY APPROACH
	di ""
	di as text _col(3) "Shapley (average)"

	* I_sb
	di as text _col(5) "{ralign 28:I_sb = I(y_b) + 1/2 I_bw}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_Isb' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_Isb' _c
		local col = `col' + 14
	}
	di ""

	* IO^s %
	di as text _col(5) "{ralign 28:IO^s %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IOs' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IOs' _c
		local col = `col' + 14
	}
	di ""

	* I_sw
	di as text _col(5) "{ralign 28:I_sw = I(y_w) + 1/2 I_bw}" _c
	if `do_gini' {
		di as result _col(35) `format' `G_Isw' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `format' `GE`j'_Isw' _c
		local col = `col' + 14
	}
	di ""

	* IR^s %
	di as text _col(5) "{ralign 28:IR^s %}" _c
	if `do_gini' {
		di as result _col(35) `formatp' `G_IRs' _c
	}
	local col = 35 + `do_gini' * 14
	forvalues j = 1/`nge' {
		di as result _col(`col') `formatp' `GE`j'_IRs' _c
		local col = `col' + 14
	}
	di ""

	di as text "{hline 100}"
	di ""

	* ------------------------------------------------------------------
	* 6. Pattern: IO shares across indices (combined 2x2 figure)
	*    a) Direct IO^D   b) Indirect IO^I
	*    c) Interaction    d) Shapley IO^s
	* ------------------------------------------------------------------

	if "`pattern'" != "" {

		* Build a temporary dataset with:
		*   - one row per GE alpha value (connected with lines)
		*   - Gini stored separately (plotted as standalone marker)

		preserve
		qui clear
		qui set obs `nge'

		* GE indices: x-axis is alpha, y-axis is IO share
		qui gen double _alpha  = .
		qui gen double _ge_IOD = .
		qui gen double _ge_IOI = .
		qui gen double _ge_Ibw = .
		qui gen double _ge_IOs = .

		local _pj = 0
		foreach a of local ge {
			local _pj = `_pj' + 1
			qui replace _alpha  = `a'                                    in `_pj'
			qui replace _ge_IOD = `GE`_pj'_IOD'                         in `_pj'
			qui replace _ge_IOI = `GE`_pj'_IOI'                         in `_pj'
			qui replace _ge_Ibw = `GE`_pj'_Ibw' / `GE`_pj'_y' * 100    in `_pj'
			qui replace _ge_IOs = `GE`_pj'_IOs'                         in `_pj'
		}

		sort _alpha

		* Gini values stored in locals for overlay as single markers
		if `do_gini' {
			local _g_IOD = `G_IOD'
			local _g_IOI = `G_IOI'
			local _g_Ibw = `G_Ibw' / `G_y' * 100
			local _g_IOs = `G_IOs'
		}

		* X-axis label: alpha values with index names
		* Build custom xlabel
		local _xlab ""
		foreach a of local ge {
			if `a' == 0 {
				local _xlab `"`_xlab' `a' "MLD""'
			}
			else if `a' == 1 {
				local _xlab `"`_xlab' `a' "Theil""'
			}
			else {
				local _xlab `"`_xlab' `a' `"GE(`a')"'"'
			}
		}

		* Common graph options
		local _gopts "graphregion(color(white)) plotregion(color(white))"
		local _yopts "ylabel(, angle(horizontal) labsize(small))"
		local _xopts `"xlabel(`_xlab', labsize(small) nogrid) xtitle("{&alpha}")"'

		* --- Gini overlay: use scatteri at an x position outside the
		*     alpha range, with a separate x-axis label ---
		* Place Gini at x = min(alpha) - 1.5 for visual separation
		qui sum _alpha
		local _gini_x = r(min) - 1.5

		* Extend xlabel to include Gini position
		if `do_gini' {
			local _xlab `"`_gini_x' "Gini" `_xlab'"'
			local _xopts `"xlabel(`_xlab', labsize(small) nogrid) xtitle("")"'
		}

		* ----------------------------------------------------------
		* Panel a) Direct IO^D
		* ----------------------------------------------------------
		if `do_gini' {
			twoway (connected _ge_IOD _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) ///
				(scatteri `_g_IOD' `_gini_x' , ///
					msymbol(D) msize(medlarge) mcolor(cranberry)) , ///
				ytitle("% of overall inequality") ///
				title("a) Direct, IO^D", size(medium)) ///
				legend(order(1 "GE({&alpha})" 2 "Gini") ///
					position(6) rows(1) size(small) ///
					region(lcolor(white))) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_a, replace)
		}
		else {
			twoway (connected _ge_IOD _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) , ///
				ytitle("% of overall inequality") ///
				title("a) Direct, IO^D", size(medium)) ///
				legend(off) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_a, replace)
		}

		* ----------------------------------------------------------
		* Panel b) Indirect IO^I
		* ----------------------------------------------------------
		if `do_gini' {
			twoway (connected _ge_IOI _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) ///
				(scatteri `_g_IOI' `_gini_x' , ///
					msymbol(D) msize(medlarge) mcolor(cranberry)) , ///
				ytitle("% of overall inequality") ///
				title("b) Indirect, IO^I", size(medium)) ///
				legend(order(1 "GE({&alpha})" 2 "Gini") ///
					position(6) rows(1) size(small) ///
					region(lcolor(white))) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_b, replace)
		}
		else {
			twoway (connected _ge_IOI _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) , ///
				ytitle("% of overall inequality") ///
				title("b) Indirect, IO^I", size(medium)) ///
				legend(off) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_b, replace)
		}

		* ----------------------------------------------------------
		* Panel c) Interaction I_bw/I(y)
		* ----------------------------------------------------------
		if `do_gini' {
			twoway (connected _ge_Ibw _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) ///
				(scatteri `_g_Ibw' `_gini_x' , ///
					msymbol(D) msize(medlarge) mcolor(cranberry)) , ///
				ytitle("% of overall inequality") ///
				title("c) Interaction, I_bw/I(y)", size(medium)) ///
				yline(0, lcolor(gs10) lpattern(dash)) ///
				legend(order(1 "GE({&alpha})" 2 "Gini") ///
					position(6) rows(1) size(small) ///
					region(lcolor(white))) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_c, replace)
		}
		else {
			twoway (connected _ge_Ibw _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) , ///
				ytitle("% of overall inequality") ///
				title("c) Interaction, I_bw/I(y)", size(medium)) ///
				yline(0, lcolor(gs10) lpattern(dash)) ///
				legend(off) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_c, replace)
		}

		* ----------------------------------------------------------
		* Panel d) Shapley IO^s
		* ----------------------------------------------------------
		if `do_gini' {
			twoway (connected _ge_IOs _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) ///
				(scatteri `_g_IOs' `_gini_x' , ///
					msymbol(D) msize(medlarge) mcolor(cranberry)) , ///
				ytitle("% of overall inequality") ///
				title("d) Shapley, IO^s", size(medium)) ///
				legend(order(1 "GE({&alpha})" 2 "Gini") ///
					position(6) rows(1) size(small) ///
					region(lcolor(white))) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_d, replace)
		}
		else {
			twoway (connected _ge_IOs _alpha , ///
					msymbol(O) mcolor(navy) lcolor(navy) lpattern(solid)) , ///
				ytitle("% of overall inequality") ///
				title("d) Shapley, IO^s", size(medium)) ///
				legend(off) ///
				`_xopts' `_yopts' `_gopts' ///
				name(_pat_d, replace)
		}

		* Combine into 2x2 figure
		graph combine _pat_a _pat_b _pat_c _pat_d , ///
			rows(2) cols(2) ///
			title("Contribution of IO as % of overall inequality") ///
			graphregion(color(white)) ///
			name(pattern`_bysuf', replace)

		* Clean up individual panels
		cap graph drop _pat_a
		cap graph drop _pat_b
		cap graph drop _pat_c
		cap graph drop _pat_d

		restore
	}

	* ------------------------------------------------------------------
	* 6b. Bypattern: accumulate IO shares across by-groups and draw
	*     combined Figure 2 on the last group
	* ------------------------------------------------------------------

	if "`bypattern'" != "" {

		* Number of columns: byvar value + 4 values per index
		*   (IOD, IOI, Ibw%, IOs) for each index
		local _bp_nidx = `do_gini' + `nge'

		* Each row stores: byval, then for each index: IOD IOI Ibw% IOs
		* Total columns = 1 + 4 * _bp_nidx
		local _bp_ncols = 1 + 4 * `_bp_nidx'

		* Determine the by-group value (first obs of by-variable)
		* With byable(recall), _byvars contains the by-variable name(s)
		local _byvars "`_byvars'"
		local _byval = .
		if "`_byvars'" != "" {
			local _byvar1 : word 1 of `_byvars'
			qui sum `_byvar1' if `touse', meanonly
			local _byval = r(min)
		}
		else {
			* Not in a by context — use observation number or 1
			local _byval = 1
		}

		* Track by-group position using globals
		* (byable(recall) does not provide _byindex()/_byN())
		if "$INEQOP_BP_I" == "" {
			* First call: count total by-groups and initialize
			if "`_byvars'" != "" {
				qui tab `_byvar1'
				local _tmpN `r(r)'
				global INEQOP_BP_N `_tmpN'
			}
			else {
				global INEQOP_BP_N 1
			}
			global INEQOP_BP_I 1
			mat _ineqop_bp = J($INEQOP_BP_N, `_bp_ncols', .)
		}
		else {
			local _tmpi = $INEQOP_BP_I + 1
			global INEQOP_BP_I `_tmpi'
		}
		local _byi = $INEQOP_BP_I
		local _byN = $INEQOP_BP_N

		* Store this group's results in row _byi
		mat _ineqop_bp[`_byi', 1] = `_byval'

		local _bpc = 1
		if `do_gini' {
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `G_IOD'
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `G_IOI'
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `G_Ibw' / `G_y' * 100
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `G_IOs'
		}
		forvalues j = 1/`nge' {
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `GE`j'_IOD'
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `GE`j'_IOI'
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `GE`j'_Ibw' / `GE`j'_y' * 100
			local _bpc = `_bpc' + 1
			mat _ineqop_bp[`_byi', `_bpc'] = `GE`j'_IOs'
		}

		* On the last by-group, produce the combined figure
		* Layout: x-axis = indices (alpha for GE, separate pos for Gini)
		*         each line = one by-group (e.g., year)
		if `_byi' == `_byN' {

			preserve
			qui clear

			* One obs per (by-group x index)
			local _bp_nobs = `_byN' * `_bp_nidx'
			qui set obs `_bp_nobs'

			qui gen double _byval   = .
			qui gen double _alpha   = .
			qui gen byte   _is_gini = 0
			qui gen double _IOD     = .
			qui gen double _IOI     = .
			qui gen double _Ibw     = .
			qui gen double _IOs     = .

			* Position for Gini on alpha axis (offset left of min GE alpha)
			local _gini_x = 0
			if `do_gini' & `nge' > 0 {
				local _min_a : word 1 of `ge'
				forvalues _j = 2/`nge' {
					local _a : word `_j' of `ge'
					if `_a' < `_min_a'  local _min_a = `_a'
				}
				local _gini_x = `_min_a' - 1.5
			}

			* Fill dataset: one obs per (by-group x index)
			local _obs = 0
			forvalues g = 1/`_byN' {
				local _bv = _ineqop_bp[`g', 1]
				local _bpc = 1

				if `do_gini' {
					local _obs = `_obs' + 1
					qui replace _byval   = `_bv'      in `_obs'
					qui replace _alpha   = `_gini_x'   in `_obs'
					qui replace _is_gini = 1           in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOD = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOI = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _Ibw = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOs = _ineqop_bp[`g', `_bpc'] in `_obs'
				}

				forvalues j = 1/`nge' {
					local _obs = `_obs' + 1
					local _a : word `j' of `ge'
					qui replace _byval   = `_bv'  in `_obs'
					qui replace _alpha   = `_a'   in `_obs'
					qui replace _is_gini = 0      in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOD = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOI = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _Ibw = _ineqop_bp[`g', `_bpc'] in `_obs'
					local _bpc = `_bpc' + 1
					qui replace _IOs = _ineqop_bp[`g', `_bpc'] in `_obs'
				}
			}

			* Get distinct by-values (years) for separate lines
			qui levelsof _byval, local(_byvals)

			* Colors, markers, line patterns for up to 9 years
			local _colors "navy cranberry forest_green dkorange purple teal maroon olive_teal ltblue"
			local _msyms  "O D T S + X o d t"
			local _lpats  "solid dash longdash shortdash dash_dot shortdash_dot solid dash longdash"

			* X-axis labels: Gini + GE alpha values
			local _xlabs ""
			if `do_gini' {
				local _xlabs `"`_gini_x' "Gini""'
			}
			foreach _a of local ge {
				if `_a' == 0 {
					local _xlabs `"`_xlabs' `_a' "MLD""'
				}
				else if `_a' == 1 {
					local _xlabs `"`_xlabs' `_a' "Theil""'
				}
				else {
					local _xlabs `"`_xlabs' `_a' "GE(`_a')""'
				}
			}

			* Build four panels (one per decomposition approach)
			foreach _panel in IOD IOI Ibw IOs {

				local _tw_cmd ""
				local _tw_leg ""
				local _tw_i = 0
				local _plt_i = 0

				foreach _bv of local _byvals {
					local _tw_i = `_tw_i' + 1
					local _col : word `_tw_i' of `_colors'
					local _ms  : word `_tw_i' of `_msyms'
					local _lp  : word `_tw_i' of `_lpats'

					* Format by-value as integer label (e.g. year)
					local _bvlab : di %4.0f `_bv'
					local _bvlab = strtrim("`_bvlab'")

					* GE indices: connected line
					if `nge' > 0 {
						local _plt_i = `_plt_i' + 1
						local _leg_i = `_plt_i'
						local _tw_cmd `"`_tw_cmd' (connected _`_panel' _alpha if _is_gini==0 & _byval==`_bv', msymbol(`_ms') mcolor(`_col') lcolor(`_col') lpattern(`_lp'))"'
					}

					* Gini: standalone diamond marker
					if `do_gini' {
						local _plt_i = `_plt_i' + 1
						if `nge' == 0  local _leg_i = `_plt_i'
						local _tw_cmd `"`_tw_cmd' (scatter _`_panel' _alpha if _is_gini==1 & _byval==`_bv', msymbol(D) mcolor(`_col') msize(medium))"'
					}

					* Legend: one entry per year
					local _tw_leg `"`_tw_leg' `_leg_i' "`_bvlab'""'
				}

				if "`_panel'" == "IOD" {
					local _ttl "a) Direct, IO^D"
				}
				else if "`_panel'" == "IOI" {
					local _ttl "b) Indirect, IO^I"
				}
				else if "`_panel'" == "Ibw" {
					local _ttl "c) Interaction, I_bw/I(y)"
				}
				else {
					local _ttl "d) Shapley, IO^s"
				}

				local _yline ""
				if "`_panel'" == "Ibw" {
					local _yline "yline(0, lcolor(gs10) lpattern(dash))"
				}

				twoway `_tw_cmd' , ///
					ytitle("% of overall inequality") ///
					title("`_ttl'", size(medium)) ///
					legend(order(`_tw_leg') ///
						position(6) rows(1) size(vsmall) ///
						region(lcolor(white))) ///
					xtitle("") ///
					xlabel(`_xlabs', labsize(small) nogrid) ///
					ylabel(, angle(horizontal) labsize(small)) ///
					`_yline' ///
					graphregion(color(white)) plotregion(color(white)) ///
					name(_bpat_`_panel', replace)
			}

			* Combine into 2x2 figure
			graph combine _bpat_IOD _bpat_IOI _bpat_Ibw _bpat_IOs , ///
				rows(2) cols(2) ///
				title("Contribution of IO as % of overall inequality") ///
				graphregion(color(white)) ///
				name(bypattern, replace)

			* Clean up
			cap graph drop _bpat_IOD
			cap graph drop _bpat_IOI
			cap graph drop _bpat_Ibw
			cap graph drop _bpat_IOs
			cap mat drop _ineqop_bp
			global INEQOP_BP_I
			global INEQOP_BP_N

			restore

		}  /* end if last by-group */

	}  /* end bypattern */

	* ------------------------------------------------------------------
	* 6c. Trend: accumulate levels & shares over by-groups (Figures 3 & 4)
	* ------------------------------------------------------------------

	if "`trend'" != "" {

		* Number of indices
		local _tr_nidx = `do_gini' + `nge'

		* Per index store: I(y), I(y_b), I(y_w), I_sb, I_sw, IOs%
		* Total columns = 1 (byval) + 6 * nidx
		local _tr_ncols = 1 + 6 * `_tr_nidx'

		* Get current by-group value
		local _byvars "`_byvars'"
		local _tr_byval = .
		if "`_byvars'" != "" {
			local _byvar1 : word 1 of `_byvars'
			qui sum `_byvar1' if `touse', meanonly
			local _tr_byval = r(min)
		}
		else {
			local _tr_byval = 1
		}

		* Track by-group position using globals
		if "$INEQOP_TR_I" == "" {
			* First call: count total by-groups and initialize
			if "`_byvars'" != "" {
				qui tab `_byvar1'
				local _tmpN `r(r)'
				global INEQOP_TR_N `_tmpN'
			}
			else {
				global INEQOP_TR_N 1
			}
			global INEQOP_TR_I 1
			mat _ineqop_tr = J($INEQOP_TR_N, `_tr_ncols', .)
		}
		else {
			local _tmpi = $INEQOP_TR_I + 1
			global INEQOP_TR_I `_tmpi'
		}
		local _tri = $INEQOP_TR_I
		local _trN = $INEQOP_TR_N

		* Store this group's results in row _tri
		mat _ineqop_tr[`_tri', 1] = `_tr_byval'

		local _trc = 1
		if `do_gini' {
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_y'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_yb'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_yw'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_Isb'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_Isw'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `G_IOs'
		}
		forvalues j = 1/`nge' {
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_y'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_yb'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_yw'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_Isb'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_Isw'
			local _trc = `_trc' + 1
			mat _ineqop_tr[`_tri', `_trc'] = `GE`j'_IOs'
		}

		* On the last by-group, produce the trend figures
		if `_tri' == `_trN' {

			preserve
			qui clear
			qui set obs `_trN'

			qui gen double _byval = .
			qui gen double _Iy    = .
			qui gen double _Iyb   = .
			qui gen double _Iyw   = .
			qui gen double _Isb   = .
			qui gen double _Isw   = .
			qui gen double _IOs   = .

			* ---- Figure 3: Trend of levels for one index ----

			* Determine which index to use for Figure 3
			local _tr_idx = "`trendindex'"
			local _tr_col_start = 1  /* will be set to correct column offset */
			local _tr_label ""

			if "`_tr_idx'" == "gini" & `do_gini' {
				local _tr_col_start = 2
				local _tr_label "Gini"
			}
			else {
				* Check GE indices
				local _tr_found = 0
				local _tr_offset = 1
				if `do_gini' {
					local _tr_offset = 7  /* 1 (byval) + 6 (Gini cols) */
				}
				forvalues j = 1/`nge' {
					local _a : word `j' of `ge'
					if "`_tr_idx'" == "ge`_a'" {
						local _tr_col_start = `_tr_offset' + (`j' - 1) * 6 + 1
						local _tr_found = 1
						if `_a' == 0 {
							local _tr_label "MLD"
						}
						else if `_a' == 1 {
							local _tr_label "Theil"
						}
						else {
							local _tr_label "GE(`_a')"
						}
					}
				}
				if !`_tr_found' {
					* Default to Gini if available, else first GE
					if `do_gini' {
						local _tr_col_start = 2
						local _tr_label "Gini"
					}
					else {
						local _tr_col_start = 2
						local _a : word 1 of `ge'
						if `_a' == 0 {
							local _tr_label "MLD"
						}
						else if `_a' == 1 {
							local _tr_label "Theil"
						}
						else {
							local _tr_label "GE(`_a')"
						}
					}
				}
			}

			* Fill dataset for Figure 3
			forvalues g = 1/`_trN' {
				qui replace _byval = _ineqop_tr[`g', 1]               in `g'
				qui replace _Iy    = _ineqop_tr[`g', `_tr_col_start']     in `g'
				local _c2 = `_tr_col_start' + 1
				qui replace _Iyb   = _ineqop_tr[`g', `_c2']          in `g'
				local _c3 = `_tr_col_start' + 2
				qui replace _Iyw   = _ineqop_tr[`g', `_c3']          in `g'
				local _c4 = `_tr_col_start' + 3
				qui replace _Isb   = _ineqop_tr[`g', `_c4']          in `g'
				local _c5 = `_tr_col_start' + 4
				qui replace _Isw   = _ineqop_tr[`g', `_c5']          in `g'
			}

			* Figure 3: 5 lines — I(y), I(y_b), I(y_w) solid; I_sb, I_sw dashed
			twoway ///
				(connected _Iy  _byval, msymbol(O) mcolor(navy)         lcolor(navy)         lpattern(solid)) ///
				(connected _Iyb _byval, msymbol(D) mcolor(cranberry)     lcolor(cranberry)     lpattern(solid)) ///
				(connected _Iyw _byval, msymbol(T) mcolor(forest_green)  lcolor(forest_green)  lpattern(solid)) ///
				(connected _Isb _byval, msymbol(S) mcolor(dkorange)      lcolor(dkorange)      lpattern(dash)) ///
				(connected _Isw _byval, msymbol(+) mcolor(purple)        lcolor(purple)        lpattern(dash)) ///
				, ///
				ytitle("`_tr_label'") ///
				title("Trend of `_tr_label' — levels", size(medium)) ///
				legend(order( ///
					1 "I(y)" ///
					2 "I(y_b)" ///
					3 "I(y_w)" ///
					4 "I_sb (Shapley between)" ///
					5 "I_sw (Shapley within)" ///
					) position(6) rows(2) size(vsmall) ///
					region(lcolor(white))) ///
				xtitle("") ///
				xlabel(, labsize(small) nogrid) ///
				ylabel(, angle(horizontal) labsize(small)) ///
				graphregion(color(white)) plotregion(color(white)) ///
				name(trend_levels, replace)

			* ---- Figure 4: IO^s trend for all indices ----

			* Need one obs per (by-group x index) for Figure 4
			qui clear
			local _tr4_nobs = `_trN' * `_tr_nidx'
			qui set obs `_tr4_nobs'

			qui gen double _byval  = .
			qui gen double _IOs    = .
			qui gen int    _idxord = .
			qui gen str20  _idxname = ""

			local _obs = 0
			forvalues g = 1/`_trN' {
				local _bv = _ineqop_tr[`g', 1]
				local _trc = 1
				local _iord = 0

				if `do_gini' {
					local _iord = `_iord' + 1
					local _obs = `_obs' + 1
					qui replace _byval   = `_bv'   in `_obs'
					qui replace _idxord  = `_iord'  in `_obs'
					qui replace _idxname = "Gini"   in `_obs'
					* IOs is the 6th value per index block
					local _c = 1 + 6
					qui replace _IOs = _ineqop_tr[`g', `_c'] in `_obs'
				}

				forvalues j = 1/`nge' {
					local _iord = `_iord' + 1
					local _obs = `_obs' + 1
					local _a : word `j' of `ge'
					qui replace _byval  = `_bv'   in `_obs'
					qui replace _idxord = `_iord'  in `_obs'
					if `_a' == 0 {
						qui replace _idxname = "MLD" in `_obs'
					}
					else if `_a' == 1 {
						qui replace _idxname = "Theil" in `_obs'
					}
					else {
						qui replace _idxname = "GE(`_a')" in `_obs'
					}
					* IOs column: byval(1) + gini_block(6*do_gini) + (j-1)*6 + 6
					local _c = 1 + 6 * `do_gini' + (`j' - 1) * 6 + 6
					qui replace _IOs = _ineqop_tr[`g', `_c'] in `_obs'
				}
			}

			* Build connected plots per index
			qui levelsof _idxord, local(_iords)
			local _colors "navy cranberry forest_green dkorange purple teal"
			local _msyms  "O D T S + X"
			local _lpats  "solid dash longdash shortdash dash_dot shortdash_dot"

			local _tw_cmd ""
			local _tw_leg ""
			local _tw_i = 0

			foreach _io of local _iords {
				local _tw_i = `_tw_i' + 1
				local _col : word `_tw_i' of `_colors'
				local _ms  : word `_tw_i' of `_msyms'
				local _lp  : word `_tw_i' of `_lpats'
				qui levelsof _idxname if _idxord == `_io', local(_inam) clean
				local _tw_cmd `"`_tw_cmd' (connected _IOs _byval if _idxord == `_io', msymbol(`_ms') mcolor(`_col') lcolor(`_col') lpattern(`_lp'))"'
				local _tw_leg `"`_tw_leg' `_tw_i' "`_inam'""'
			}

			twoway `_tw_cmd' , ///
				ytitle("IO^s (% of overall inequality)") ///
				title("Shapley IO share — trend", size(medium)) ///
				legend(order(`_tw_leg') ///
					position(6) rows(1) size(vsmall) ///
					region(lcolor(white))) ///
				xtitle("") ///
				xlabel(, labsize(small) nogrid) ///
				ylabel(, angle(horizontal) labsize(small)) ///
				graphregion(color(white)) plotregion(color(white)) ///
				name(trend_shares, replace)

			* Clean up
			cap mat drop _ineqop_tr
			global INEQOP_TR_I
			global INEQOP_TR_N

			restore

		}  /* end if last by-group (trend) */

	}  /* end trend */

	* ------------------------------------------------------------------
	* 6d. Lorenz curves (Figure A3a and A3b)
	* ------------------------------------------------------------------

	if "`lorenz'" != "" {

		preserve
		qui keep if `touse'

		* --- Lorenz curve for y ---
		sort `y'
		qui gen double _cw = sum(`w')
		local _totw = _cw[_N]
		qui gen double _cy = sum(`y' * `w')
		local _toty = _cy[_N]
		qui gen double _p_y = _cw / `_totw'
		qui gen double _L_y = _cy / `_toty'
		drop _cw _cy

		* --- Lorenz curve for y_b ---
		sort `yb'
		qui gen double _cw = sum(`w')
		qui gen double _cy = sum(`yb' * `w')
		local _totyb = _cy[_N]
		qui gen double _p_yb = _cw / `_totw'
		qui gen double _L_yb = _cy / `_totyb'
		drop _cw _cy

		* --- Lorenz curve for y_w ---
		sort `yw'
		qui gen double _cw = sum(`w')
		qui gen double _cy = sum(`yw' * `w')
		local _totyw = _cy[_N]
		qui gen double _p_yw = _cw / `_totw'
		qui gen double _L_yw = _cy / `_totyw'
		drop _cw _cy

		* --- Figure A3a: Lorenz curves of y, y_b, y_w ---
		twoway ///
			(line _L_y _p_y, sort lcolor(black) lpattern(solid) lwidth(medium)) ///
			(line _L_yb _p_yb, sort lcolor(blue) lpattern(dash) lwidth(medium)) ///
			(line _L_yw _p_yw, sort lcolor(red) lpattern(dot) lwidth(thick)) ///
			(function y=x, range(0 1) lcolor(black) lpattern(solid) lwidth(thin)) ///
			, ///
			ytitle("Cumulative income share") ///
			xtitle("Cumulative population share") ///
			title("Lorenz curves", size(medium)) ///
			legend(order(1 "L(y)" 2 "L(y_b)" 3 "L(y_w)" ///
				4 "45-degree line") ///
				position(3) cols(1) size(vsmall) ///
				region(lcolor(white))) ///
			graphregion(color(white)) plotregion(color(white)) ///
			ylabel(, nogrid) xlabel(, nogrid) ///
			aspectratio(1) ///
			name(lorenz_a`_bysuf', replace)

		* --- Figure A3b: Shapley Lorenz curves ---
		* Need all three Lorenz curves on a common p grid
		* Use Mata for interpolation onto common grid and Shapley Lorenz
		local _ngrid = 200
		cap drop _pgrid _Ly_g _Lsb_g _Lsw_g
		mata: _ineqop_shapley_lorenz(strtoreal(st_local("_ngrid")))

		* Plot Figure A3b
		twoway ///
			(line _Ly_g _pgrid in 1/`_ngrid', lcolor(black) ///
				lpattern(solid) lwidth(medium)) ///
			(line _Lsb_g _pgrid in 1/`_ngrid', lcolor(blue) ///
				lpattern(dash) lwidth(medium)) ///
			(line _Lsw_g _pgrid in 1/`_ngrid', lcolor(red) ///
				lpattern(dot) lwidth(thick)) ///
			(function y=x, range(0 1) lcolor(black) lpattern(solid) lwidth(thin)) ///
			, ///
			ytitle("Cumulative income share") ///
			xtitle("Cumulative population share") ///
			title("Shapley Lorenz curves", size(medium)) ///
			legend(order(1 "L(y)" 2 "L_sb (Shapley between)" ///
				3 "L_sw (Shapley within)" 4 "45-degree line") ///
				position(3) cols(1) size(vsmall) ///
				region(lcolor(white))) ///
			graphregion(color(white)) plotregion(color(white)) ///
			ylabel(, nogrid) xlabel(, nogrid) ///
			aspectratio(1) ///
			name(lorenz_b`_bysuf', replace)

		restore

	}  /* end lorenz */

	* ------------------------------------------------------------------
	* 7. Shapley RIF contributions by type (contributions graph/table)
	* ------------------------------------------------------------------

	if "`contributions'" != "" | "`contrtable'" != "" {

		* ---- Compute RIF for each distribution: y, y_b, y_w ----

		* We need RIF of Gini for y, y_b, y_w, and from those
		* compute Shapley per capita contributions by type:
		*   beta_i     = mean RIF(y) in type i
		*   beta_b_i   = mean RIF(y_b) in type i
		*   beta_w_i   = mean RIF(y_w) in type i
		*   beta_sb_i  = 0.5*(beta_b_i + beta_i - beta_w_i)
		*   beta_sw_i  = 0.5*(beta_w_i + beta_i - beta_b_i)
		*   Contribution to IO = beta_sb_i * p_i
		*   Contribution to IR = beta_sw_i * p_i

		* --- Gini RIFs ---
		if `do_gini' {
			* RIF of Gini for y
			tempvar rif_G_y rif_G_yb rif_G_yw
			qui _ineqop_rif_gini `y'  `w' `touse' `rif_G_y'
			qui _ineqop_rif_gini `yb' `w' `touse' `rif_G_yb'
			qui _ineqop_rif_gini `yw' `w' `touse' `rif_G_yw'

			* Weighted per capita contributions by type
			* beta_i = sum(RIF_j * w_j) / sum(w_j) for j in type i
			tempvar wrif_G wrif_Gb wrif_Gw
			tempvar beta_G beta_Gb beta_Gw beta_Gsb beta_Gsw
			tempvar contrib_Gsb contrib_Gsw

			qui gen double `wrif_G'  = `rif_G_y'  * `w' if `touse'
			qui gen double `wrif_Gb' = `rif_G_yb' * `w' if `touse'
			qui gen double `wrif_Gw' = `rif_G_yw' * `w' if `touse'

			qui bysort `typevar': egen double `beta_G'  = total(`wrif_G')  if `touse'
			qui bysort `typevar': egen double `beta_Gb' = total(`wrif_Gb') if `touse'
			qui bysort `typevar': egen double `beta_Gw' = total(`wrif_Gw') if `touse'

			qui replace `beta_G'  = `beta_G'  / `type_sw' if `touse'
			qui replace `beta_Gb' = `beta_Gb' / `type_sw' if `touse'
			qui replace `beta_Gw' = `beta_Gw' / `type_sw' if `touse'

			* Shapley per capita
			qui gen double `beta_Gsb' = 0.5 * (`beta_Gb' + `beta_G' - `beta_Gw') if `touse'
			qui gen double `beta_Gsw' = 0.5 * (`beta_Gw' + `beta_G' - `beta_Gb') if `touse'

			* Total contribution = beta * p (as % of overall inequality)
			qui gen double `contrib_Gsb' = `beta_Gsb' * `pg' / `G_y' * 100 if `touse'
			qui gen double `contrib_Gsw' = `beta_Gsw' * `pg' / `G_y' * 100 if `touse'
		}

		* --- GE RIFs ---
		local j = 0
		foreach a of local ge {
			local j = `j' + 1

			tempvar rif_GE`j'_y rif_GE`j'_yb rif_GE`j'_yw
			qui _ineqop_rif_ge `y'  `w' `touse' `a' `rif_GE`j'_y'
			qui _ineqop_rif_ge `yb' `w' `touse' `a' `rif_GE`j'_yb'
			qui _ineqop_rif_ge `yw' `w' `touse' `a' `rif_GE`j'_yw'

			* Weighted per capita contributions by type
			tempvar wrif_GE`j' wrif_GE`j'b wrif_GE`j'w
			tempvar beta_GE`j' beta_GE`j'b beta_GE`j'w beta_GE`j'sb beta_GE`j'sw
			tempvar contrib_GE`j'sb contrib_GE`j'sw

			qui gen double `wrif_GE`j''  = `rif_GE`j'_y'  * `w' if `touse'
			qui gen double `wrif_GE`j'b' = `rif_GE`j'_yb' * `w' if `touse'
			qui gen double `wrif_GE`j'w' = `rif_GE`j'_yw' * `w' if `touse'

			qui bysort `typevar': egen double `beta_GE`j''  = total(`wrif_GE`j'')  if `touse'
			qui bysort `typevar': egen double `beta_GE`j'b' = total(`wrif_GE`j'b') if `touse'
			qui bysort `typevar': egen double `beta_GE`j'w' = total(`wrif_GE`j'w') if `touse'

			qui replace `beta_GE`j''  = `beta_GE`j''  / `type_sw' if `touse'
			qui replace `beta_GE`j'b' = `beta_GE`j'b' / `type_sw' if `touse'
			qui replace `beta_GE`j'w' = `beta_GE`j'w' / `type_sw' if `touse'

			qui gen double `beta_GE`j'sb' = 0.5 * (`beta_GE`j'b' + `beta_GE`j'' - `beta_GE`j'w') if `touse'
			qui gen double `beta_GE`j'sw' = 0.5 * (`beta_GE`j'w' + `beta_GE`j'' - `beta_GE`j'b') if `touse'

			qui gen double `contrib_GE`j'sb' = `beta_GE`j'sb' * `pg' / `GE`j'_y' * 100 if `touse'
			qui gen double `contrib_GE`j'sw' = `beta_GE`j'sw' * `pg' / `GE`j'_y' * 100 if `touse'
		}

		* --- Display contributions table ---
		if "`contrtable'" != "" | "`contributions'" != "" {

			di as text "{hline 100}"
			di as text "Shapley RIF contributions by type (as % of overall inequality)"
			di as text "{hline 100}"

			* Get unique types sorted by Gini IO contribution (descending)
			preserve

			* Keep one obs per type
			qui bysort `typevar': keep if _n == 1
			qui keep if `touse'

			* Type id, mean income, pop share
			qui gen _type_id = `typevar'
			qui gen _type_mean = `type_mean'
			qui gen _type_pg   = `pg'

			if `do_gini' {
				qui gen _cGsb = `contrib_Gsb'
				qui gen _cGsw = `contrib_Gsw'
				qui gsort - _cGsb
			}

			local j = 0
			foreach a of local ge {
				local j = `j' + 1
				qui gen _cGE`j'sb = `contrib_GE`j'sb'
				qui gen _cGE`j'sw = `contrib_GE`j'sw'
			}

			* Display header
			di as text _col(1) "{ralign 6:Type}" _col(9) "{ralign 10:Mean}" ///
				_col(21) "{ralign 8:Pop%}" _c
			if `do_gini' {
				di as text _col(31) "{ralign 8:G_IO%}" _col(41) "{ralign 8:G_IR%}" _c
			}
			local col = 31 + `do_gini' * 20
			local j = 0
			foreach a of local ge {
				local j = `j' + 1
				di as text _col(`col') "{ralign 8:GE`a'_IO%}" _c
				local col = `col' + 10
				di as text _col(`col') "{ralign 8:GE`a'_IR%}" _c
				local col = `col' + 10
			}
			di ""
			di as text "{hline 100}"

			* Display each type
			local nrows = _N
			forvalues i = 1/`nrows' {
				di as result _col(1) %6.0f _type_id[`i'] _c
				di as result _col(9) `format' _type_mean[`i'] _c
				local tmppg = _type_pg[`i'] * 100
				di as result _col(21) `formatp' `tmppg' _c
				if `do_gini' {
					di as result _col(31) `formatp' _cGsb[`i'] _c
					di as result _col(41) `formatp' _cGsw[`i'] _c
				}
				local col = 31 + `do_gini' * 20
				local j = 0
				foreach a of local ge {
					local j = `j' + 1
					di as result _col(`col') `formatp' _cGE`j'sb[`i'] _c
					local col = `col' + 10
					di as result _col(`col') `formatp' _cGE`j'sw[`i'] _c
					local col = `col' + 10
				}
				di ""
			}

			di as text "{hline 100}"

			* Display totals
			di as text _col(1) "{ralign 6:Total}" _c
			di as text _col(9) "{ralign 10:}" _col(21) "{ralign 8:}" _c
			if `do_gini' {
				qui sum _cGsb
				local totGsb = r(sum)
				qui sum _cGsw
				local totGsw = r(sum)
				di as result _col(31) `formatp' `totGsb' _c
				di as result _col(41) `formatp' `totGsw' _c
			}
			local col = 31 + `do_gini' * 20
			local j = 0
			foreach a of local ge {
				local j = `j' + 1
				qui sum _cGE`j'sb
				local tmp1 = r(sum)
				qui sum _cGE`j'sw
				local tmp2 = r(sum)
				di as result _col(`col') `formatp' `tmp1' _c
				local col = `col' + 10
				di as result _col(`col') `formatp' `tmp2' _c
				local col = `col' + 10
			}
			di ""
			di as text "{hline 100}"

			* --- Contributions graph ---
			if "`contributions'" != "" {

				* Determine which index to graph
				local _graph_sb ""
				local _graph_sw ""
				local _graph_label ""
				local _graph_name ""

				if "`contrindex'" == "gini" & `do_gini' {
					local _graph_sb "_cGsb"
					local _graph_sw "_cGsw"
					local _graph_label "Gini"
					local _graph_name "contr_gini`_bysuf'"
				}
				else {
					* Find the matching GE index
					local _gj = 0
					foreach _ga of local ge {
						local _gj = `_gj' + 1
						if "`contrindex'" == "ge`_ga'" {
							local _graph_sb "_cGE`_gj'sb"
							local _graph_sw "_cGE`_gj'sw"
							if `_ga' == 0 {
								local _graph_label "MLD"
							}
							else if `_ga' == 1 {
								local _graph_label "Theil"
							}
							else {
								local _graph_label "GE(`_ga')"
							}
							local _graph_name "contr_ge`_ga'`_bysuf'"
						}
					}
					* Fallback to Gini if contrindex not found in ge()
					if "`_graph_sb'" == "" & `do_gini' {
						local _graph_sb "_cGsb"
						local _graph_sw "_cGsw"
						local _graph_label "Gini"
						local _graph_name "contr_gini`_bysuf'"
						di as text "Note: contrindex(`contrindex') not available; using Gini."
					}
				}

				if "`_graph_sb'" != "" {
					* Sort by IO contribution (descending)
					qui gsort - `_graph_sb'
					cap drop _order
					qui gen _order = _n

					graph bar (asis) `_graph_sb' `_graph_sw' , ///
						over(_type_id, sort(_order) ///
							label(labsize(tiny) angle(90))) ///
						stack ///
						bar(1, color(navy)) bar(2, color(cranberry)) ///
						legend(order(1 "IO (between, Shapley)" ///
							2 "IR (within, Shapley)") ///
							position(6) rows(1) size(small) ///
							region(lcolor(white))) ///
						ytitle("% of overall inequality (`_graph_label')") ///
						title("Shapley contribution of types to inequality" ///
							"(`_graph_label')") ///
						note("Types sorted by IO contribution (descending)") ///
						ylabel(, angle(horizontal) labsize(small)) ///
						graphregion(color(white)) ///
						plotregion(color(white)) ///
						nofill ///
						name(`_graph_name', replace)
				}
				else {
					di as error "Cannot produce contributions graph:" ///
						" no matching index available."
				}
			}

			restore
		}
	}

	* ------------------------------------------------------------------
	* 9. Descriptive statistics: distribution of circumstances (Table A2)
	* ------------------------------------------------------------------

	if "`descriptives'" != "" {

		local _byvars "`_byvars'"

		* Total weighted and unweighted sample for this group
		qui sum `w' if `touse'
		local _desc_N = r(N)
		local _desc_sw = r(sum)

		if "`_byvars'" != "" {

			* ============================================================
			* By context: accumulate across groups, one combined table
			* ============================================================

			local _byvar1 : word 1 of `_byvars'
			qui sum `_byvar1' if `touse', meanonly
			local _d_byval = r(min)

			if "$INEQOP_D_I" == "" {
				* -- First call: build row structure, initialize --

				qui tab `_byvar1'
				local _tmpN `r(r)'
				global INEQOP_D_N `_tmpN'
				global INEQOP_D_I 1

				* Number of circumstance variables
				local _d_nv : word count `type'
				global INEQOP_D_NV `_d_nv'

				* Iterate variables, get ALL categories from full dataset
				local _d_row = 0
				local _d_v = 0
				foreach _dvar of local type {
					local _d_v = `_d_v' + 1

					* Variable label
					local _dvlab : variable label `_dvar'
					if "`_dvlab'" == "" local _dvlab "`_dvar'"
					global INEQOP_D_VL_`_d_v' `_dvlab'

					* Start row for this variable
					local _d_rs = `_d_row' + 1
					global INEQOP_D_VR_`_d_v' `_d_rs'

					* Value label name
					local _dvlbl : value label `_dvar'

					* Get ALL categories (full dataset, not just touse)
					qui levelsof `_dvar', local(_dvals)
					local _d_k : word count `_dvals'
					global INEQOP_D_VK_`_d_v' `_d_k'

					foreach _dv of local _dvals {
						local _d_row = `_d_row' + 1

						if "`_dvlbl'" != "" {
							local _dcat : label `_dvlbl' `_dv'
						}
						else {
							local _dcat "`_dv'"
						}
						global INEQOP_D_CL_`_d_row' `_dcat'
						global INEQOP_D_CV_`_d_row' `_dv'
						global INEQOP_D_VN_`_d_row' `_dvar'
					}
				}
				global INEQOP_D_NR `_d_row'

				* Initialize matrices
				mat _ineqop_desc   = J(`_d_row', $INEQOP_D_N, 0)
				mat _ineqop_desc_n = J(1, $INEQOP_D_N, 0)
			}
			else {
				local _tmpi = $INEQOP_D_I + 1
				global INEQOP_D_I `_tmpi'
			}

			local _d_g = $INEQOP_D_I

			* Store by-value label for column header
			local _d_bvfmt : di %8.0g `_d_byval'
			local _d_bvfmt = strtrim("`_d_bvfmt'")
			global INEQOP_D_BV_`_d_g' `_d_bvfmt'

			* Store sample size
			mat _ineqop_desc_n[1, `_d_g'] = `_desc_N'

			* Compute percentages for each category row
			forvalues r = 1/$INEQOP_D_NR {
				local _vn = "${INEQOP_D_VN_`r'}"
				local _cv = ${INEQOP_D_CV_`r'}
				qui sum `w' if `touse' & `_vn' == `_cv'
				if `_desc_sw' > 0 {
					mat _ineqop_desc[`r', `_d_g'] = r(sum) / `_desc_sw' * 100
				}
			}

			* On the last by-group, display the combined table
			if `_d_g' == $INEQOP_D_N {

				local _d_ncols = $INEQOP_D_N
				local _d_nrows = $INEQOP_D_NR
				local _d_nvars = $INEQOP_D_NV

				* Column layout: label (30) + year columns (10 each)
				local _lab_w = 30
				local _col_w = 10
				local _total_w = `_lab_w' + `_d_ncols' * `_col_w'

				* Header
				di ""
				di as text "{hline `_total_w'}"
				di as text "Distribution of circumstances (Percentage %)"
				di as text "{hline `_total_w'}"

				* Column headers (year labels)
				di as text _col(`_lab_w') _c
				forvalues g = 1/`_d_ncols' {
					local _bvh = "${INEQOP_D_BV_`g'}"
					di as text %`_col_w's "`_bvh'" _c
				}
				di ""

				* Body: iterate by variable
				local _d_row = 0
				forvalues v = 1/`_d_nvars' {
					local _vl = "${INEQOP_D_VL_`v'}"
					local _vk = ${INEQOP_D_VK_`v'}

					* Variable header row
					di as result "`_vl'"

					forvalues k = 1/`_vk' {
						local _d_row = `_d_row' + 1
						local _cl = "${INEQOP_D_CL_`_d_row'}"

						* Truncate if too long
						local _cl_len = `_lab_w' - 4
						if length("`_cl'") > `_cl_len' {
							local _cl = substr("`_cl'", 1, `_cl_len' - 2) + ".."
						}

						di as text %`_lab_w's "  `_cl'" _c
						forvalues g = 1/`_d_ncols' {
							local _pct = _ineqop_desc[`_d_row', `g']
							di as result %`_col_w'.1f `_pct' _c
						}
						di ""
					}
				}

				* Total sample size
				di as text "{hline `_total_w'}"
				di as text %`_lab_w's "Total sample (n. obs.)" _c
				forvalues g = 1/`_d_ncols' {
					local _sn = _ineqop_desc_n[1, `g']
					di as result %`_col_w'.0f `_sn' _c
				}
				di ""
				di as text "{hline `_total_w'}"
				di ""

				* Clean up globals
				forvalues r = 1/`_d_nrows' {
					global INEQOP_D_CL_`r'
					global INEQOP_D_CV_`r'
					global INEQOP_D_VN_`r'
				}
				forvalues v = 1/`_d_nvars' {
					global INEQOP_D_VL_`v'
					global INEQOP_D_VK_`v'
					global INEQOP_D_VR_`v'
				}
				forvalues g = 1/`_d_ncols' {
					global INEQOP_D_BV_`g'
				}
				global INEQOP_D_I
				global INEQOP_D_N
				global INEQOP_D_NR
				global INEQOP_D_NV
				cap mat drop _ineqop_desc
				cap mat drop _ineqop_desc_n

			}  /* end last by-group display */
		}
		else {

			* ============================================================
			* Single group: display immediately
			* ============================================================

			di ""
			di as text "{hline 50}"
			di as text "Distribution of circumstances"
			di as text "{hline 50}"
			di as text %35s "Category" _col(40) as text %10s "(Pct. %)"

			foreach _dvar of local type {
				local _dvlab : variable label `_dvar'
				if "`_dvlab'" == "" local _dvlab "`_dvar'"

				di as text ""
				di as result "`_dvlab'"

				local _dvlbl : value label `_dvar'
				qui levelsof `_dvar' if `touse', local(_dvals)

				foreach _dv of local _dvals {
					if "`_dvlbl'" != "" {
						local _dcat : label `_dvlbl' `_dv'
					}
					else {
						local _dcat "`_dv'"
					}
					qui sum `w' if `touse' & `_dvar' == `_dv'
					local _dpct = r(sum) / `_desc_sw' * 100

					di as text %35s "`_dcat'" _col(40) as result `formatp' `_dpct'
				}
			}

			di as text ""
			di as text "{hline 50}"
			di as text %35s "Total sample (n. obs.)" _col(40) as result %10.0fc `_desc_N'
			di as text "{hline 50}"
			di ""
		}

		ret scalar desc_N = `_desc_N'
	}

	* ------------------------------------------------------------------
	* 10. Return matrices
	* ------------------------------------------------------------------

	* Return a summary matrix with all results
	local ncols_mat = `do_gini' + `nge'

	* Rows: I(y), I(y_b), IO^D%, I(y)-I(y_b), IR^I%,
	*        I(y)-I(y_w), IO^I%, I(y_w), IR^D%,
	*        I_bw, I_bw/I(y)%, I_sb, IO^s%, I_sw, IR^s%

	mat _ineqop_results = J(15, `ncols_mat', .)

	local c = 0
	if `do_gini' {
		local c = `c' + 1
		mat _ineqop_results[1, `c']  = `G_y'
		mat _ineqop_results[2, `c']  = `G_yb'
		mat _ineqop_results[3, `c']  = `G_IOD'
		mat _ineqop_results[4, `c']  = `G_y' - `G_yb'
		mat _ineqop_results[5, `c']  = `G_IRD'
		mat _ineqop_results[6, `c']  = `G_y' - `G_yw'
		mat _ineqop_results[7, `c']  = `G_IOI'
		mat _ineqop_results[8, `c']  = `G_yw'
		mat _ineqop_results[9, `c']  = `G_IRI'
		mat _ineqop_results[10, `c'] = `G_Ibw'
		mat _ineqop_results[11, `c'] = `G_Ibw' / `G_y' * 100
		mat _ineqop_results[12, `c'] = `G_Isb'
		mat _ineqop_results[13, `c'] = `G_IOs'
		mat _ineqop_results[14, `c'] = `G_Isw'
		mat _ineqop_results[15, `c'] = `G_IRs'
	}

	forvalues j = 1/`nge' {
		local c = `c' + 1
		mat _ineqop_results[1, `c']  = `GE`j'_y'
		mat _ineqop_results[2, `c']  = `GE`j'_yb'
		mat _ineqop_results[3, `c']  = `GE`j'_IOD'
		mat _ineqop_results[4, `c']  = `GE`j'_y' - `GE`j'_yb'
		mat _ineqop_results[5, `c']  = `GE`j'_IRD'
		mat _ineqop_results[6, `c']  = `GE`j'_y' - `GE`j'_yw'
		mat _ineqop_results[7, `c']  = `GE`j'_IOI'
		mat _ineqop_results[8, `c']  = `GE`j'_yw'
		mat _ineqop_results[9, `c']  = `GE`j'_IRI'
		mat _ineqop_results[10, `c'] = `GE`j'_Ibw'
		mat _ineqop_results[11, `c'] = `GE`j'_Ibw' / `GE`j'_y' * 100
		mat _ineqop_results[12, `c'] = `GE`j'_Isb'
		mat _ineqop_results[13, `c'] = `GE`j'_IOs'
		mat _ineqop_results[14, `c'] = `GE`j'_Isw'
		mat _ineqop_results[15, `c'] = `GE`j'_IRs'
	}

	mat rownames _ineqop_results = "I(y)" "I(y_b)" "IO_D%" "I(y)-I(y_b)" "IR_I%" ///
		"I(y)-I(y_w)" "IO_I%" "I(y_w)" "IR_D%" "I_bw" "I_bw/I(y)%" ///
		"I_sb" "IO_s%" "I_sw" "IR_s%"

	* Build column names
	local cnames ""
	if `do_gini' {
		local cnames "Gini"
	}
	foreach a of local ge {
		local atxt = subinstr("`a'", "-", "m", .)
		local cnames `"`cnames' GE`atxt'"'
	}
	mat colnames _ineqop_results = `cnames'

	ret mat results = _ineqop_results

	di as text "Results saved in r(results) matrix."
	di ""

end


* ======================================================================
* Auxiliary programs
* ======================================================================

* ------------------------------------------------------------------
* _ineqop_gini: Compute Gini index
*   Usage: _ineqop_gini y w touse [condition_var]
*   If condition_var is provided, compute Gini only where condition_var==1
* ------------------------------------------------------------------

cap program drop _ineqop_gini
program def _ineqop_gini, rclass
	args y w touse condvar

	preserve

	* Keep only relevant observations
	if "`condvar'" != "" {
		qui keep if `touse' & `condvar'
	}
	else {
		qui keep if `touse'
	}

	qui sum `y' [aw=`w']
	local sy = r(sum)
	local sw2 = r(sum_w)

	if `sy' == 0 | `sw2' == 0 | r(N) <= 1 {
		ret scalar gini = 0
		restore
		exit
	}

	sort `y'

	tempvar wc yc _gini

	qui gen double `wc' = sum(`w') / `sw2'
	qui gen double `yc' = sum(`w' * `y') / `sy'

	local Nm1 = _N - 1
	qui gen double `_gini' = sum(`wc'[_n] * `yc'[_n+1] - `wc'[_n+1] * `yc'[_n])

	ret scalar gini = `_gini'[`Nm1']

	restore
end


* ------------------------------------------------------------------
* _ineqop_ge: Compute GE(alpha) index
* ------------------------------------------------------------------

cap program drop _ineqop_ge
program def _ineqop_ge, rclass sortpreserve
	args y w touse alpha

	qui sum `y' [aw=`w'] if `touse'
	local mu = r(mean)
	local sw2 = r(sum_w)

	if `mu' <= 0 {
		ret scalar ge = .
		exit
	}

	tempvar v

	if `alpha' == 0 {
		* MLD = E[ln(mu/y)]
		* Only for positive y
		qui gen double `v' = ln(`mu'/`y') * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		ret scalar ge = r(sum)
	}
	else if `alpha' == 1 {
		* Theil = E[(y/mu)*ln(y/mu)]
		qui gen double `v' = (`y'/`mu') * ln(`y'/`mu') * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		ret scalar ge = r(sum)
	}
	else {
		* GE(a) = [1/(a*(a-1))] * [E[(y/mu)^a] - 1]
		qui gen double `v' = (`y'/`mu')^`alpha' * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		local Eya = r(sum)
		ret scalar ge = (`Eya' - 1) / (`alpha' * (`alpha' - 1))
	}
end


* ------------------------------------------------------------------
* _ineqop_rif_gini: Compute RIF of Gini for each observation
*   Creates a variable with RIF values
*   Note: called on the full touse sample (no subsets), so sorting is safe
* ------------------------------------------------------------------

cap program drop _ineqop_rif_gini
program def _ineqop_rif_gini, sortpreserve
	args y w touse rifvar

	tempvar wc yc ysort

	qui sum `y' [aw=`w'] if `touse'
	local mu = r(mean)
	local sw2 = r(sum_w)
	local sy = r(sum)

	* Create sort variable: y for touse obs, missing otherwise
	* This ensures non-touse obs sort to the end and don't interfere
	qui gen double `ysort' = `y' if `touse'
	sort `ysort'

	* Cumulative weight and income shares (only over touse observations)
	qui gen double `wc' = sum(`w' * `touse') / `sw2'
	qui gen double `yc' = sum(`w' * `y' * `touse') / `sy'

	* Compute Gini
	tempvar _gini_tmp
	local Nm1 = _N - 1
	qui gen double `_gini_tmp' = sum( ///
		`wc'[_n] * `yc'[_n+1] - `wc'[_n+1] * `yc'[_n] )
	local gini = `_gini_tmp'[`Nm1']

	* RIF(y; Gini) = 2*(y/mu)*(F(y) - (1+G)/2) + 2*(0.5 - L(y))
	* where F(y) = cumulative weight share, L(y) = cumulative income share
	qui gen double `rifvar' = 2 * (`y'/`mu') * (`wc' - (1 + `gini')/2) ///
		+ 2 * (0.5 - `yc') if `touse'
end


* ------------------------------------------------------------------
* _ineqop_rif_ge: Compute RIF of GE(alpha) for each observation
*   Creates a variable with RIF values
* ------------------------------------------------------------------

cap program drop _ineqop_rif_ge
program def _ineqop_rif_ge, sortpreserve
	args y w touse alpha rifvar

	qui sum `y' [aw=`w'] if `touse'
	local mu = r(mean)
	local sw2 = r(sum_w)

	* First compute GE(alpha)
	tempvar v
	local ge_val = .

	if `alpha' == 0 {
		qui gen double `v' = ln(`mu'/`y') * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		local ge_val = r(sum)

		* RIF for MLD: ln(mu/y) + (y - mu)/mu
		qui gen double `rifvar' = ln(`mu'/`y') + (`y' - `mu') / `mu' if `touse' & `y' > 0
		qui replace `rifvar' = . if `touse' & `y' <= 0
	}
	else if `alpha' == 1 {
		qui gen double `v' = (`y'/`mu') * ln(`y'/`mu') * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		local ge_val = r(sum)

		* RIF for Theil: (y/mu)*ln(y/mu) - (1+GE1)*(y-mu)/mu
		qui gen double `rifvar' = (`y'/`mu') * ln(`y'/`mu') ///
			- (1 + `ge_val') * (`y' - `mu') / `mu' if `touse' & `y' > 0
		qui replace `rifvar' = . if `touse' & `y' <= 0
	}
	else {
		qui gen double `v' = (`y'/`mu')^`alpha' * `w' / `sw2' if `touse' & `y' > 0
		qui sum `v', meanonly
		local Eya = r(sum)
		local ge_val = (`Eya' - 1) / (`alpha' * (`alpha' - 1))

		* RIF for GE(a): [(y/mu)^a - 1]/(a*(a-1)) - a*((y-mu)/mu)*(GE_a + 1/(a*(a-1)))
		qui gen double `rifvar' = ((`y'/`mu')^`alpha' - 1) / (`alpha' * (`alpha' - 1)) ///
			- `alpha' * ((`y' - `mu') / `mu') * (`ge_val' + 1/(`alpha'*(`alpha'-1))) ///
			if `touse' & `y' > 0
		qui replace `rifvar' = . if `touse' & `y' <= 0
	}
end

* ==================================================================
* Mata functions for Shapley Lorenz curve interpolation
* ==================================================================
cap mata: mata drop _ineqop_linterp()
cap mata: mata drop _ineqop_shapley_lorenz()
mata:

// Linear interpolation: xp and yp sorted ascending, evaluate at xnew
real colvector _ineqop_linterp(real colvector xp, real colvector yp,
		real colvector xnew) {
	real scalar n, m, i, j
	real scalar frac
	real colvector ynew
	n = rows(xp)
	m = rows(xnew)
	ynew = J(m, 1, .)
	j = 1
	for (i = 1; i <= m; i++) {
		while (j < n & xp[j] < xnew[i]) j++
		if (j == 1) {
			ynew[i] = yp[1] * xnew[i] / xp[1]
		}
		else if (j > n) {
			ynew[i] = yp[n]
		}
		else {
			frac = (xnew[i] - xp[j-1]) / (xp[j] - xp[j-1])
			ynew[i] = yp[j-1] + frac * (yp[j] - yp[j-1])
		}
	}
	return(ynew)
}

// Main wrapper: read Lorenz data, interpolate, compute Shapley, store back
void _ineqop_shapley_lorenz(real scalar ngrid) {
	real colvector p_y, L_y, p_yb, L_yb, p_yw, L_yw
	real colvector oy, oyb, oyw
	real colvector p_ys, L_ys, p_ybs, L_ybs, p_yws, L_yws
	real colvector pgrid, Ly_g, Lb_g, Lw_g, intxn, Lsb_g, Lsw_g
	real scalar idx1, idx2, idx3, idx4

	// Read Lorenz curve data from Stata
	p_y  = st_data(., "_p_y")
	L_y  = st_data(., "_L_y")
	p_yb = st_data(., "_p_yb")
	L_yb = st_data(., "_L_yb")
	p_yw = st_data(., "_p_yw")
	L_yw = st_data(., "_L_yw")

	// Sort each curve by its own p and prepend (0,0)
	oy  = order(p_y, 1)
	oyb = order(p_yb, 1)
	oyw = order(p_yw, 1)

	p_ys  = 0 \ p_y[oy];   L_ys  = 0 \ L_y[oy]
	p_ybs = 0 \ p_yb[oyb]; L_ybs = 0 \ L_yb[oyb]
	p_yws = 0 \ p_yw[oyw]; L_yws = 0 \ L_yw[oyw]

	// Common percentile grid
	pgrid = (1::ngrid) / ngrid

	// Interpolate each Lorenz curve onto common grid
	Ly_g  = _ineqop_linterp(p_ys, L_ys, pgrid)
	Lb_g  = _ineqop_linterp(p_ybs, L_ybs, pgrid)
	Lw_g  = _ineqop_linterp(p_yws, L_yws, pgrid)

	// Shapley Lorenz curves
	// L_sb(p) = 0.5 * [p + L(p) + L_b(p) - L_w(p)]
	// L_sw(p) = 0.5 * [p + L(p) + L_w(p) - L_b(p)]
	Lsb_g = 0.5 * (pgrid + Ly_g + Lb_g - Lw_g)
	Lsw_g = 0.5 * (pgrid + Ly_g + Lw_g - Lb_g)

	// Store results in Stata variables (first ngrid obs)
	idx1 = st_addvar("double", "_pgrid")
	idx2 = st_addvar("double", "_Ly_g")
	idx3 = st_addvar("double", "_Lsb_g")
	idx4 = st_addvar("double", "_Lsw_g")
	st_store((1, ngrid), idx1, pgrid)
	st_store((1, ngrid), idx2, Ly_g)
	st_store((1, ngrid), idx3, Lsb_g)
	st_store((1, ngrid), idx4, Lsw_g)
}

end
