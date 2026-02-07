*! 1.0.0 Ariel Linden 04Feb2026

program binomci, rclass byable(recall)
	version 11
	
	local vv : di "version " string(_caller()) ", missing:"
	
	// define all method options
	local SYN_type exact wald waldcorrected waldblythstill wilson ///
		Agresti Jeffreys score scorecorrected waldlogit waldlogitcorrected arcsine
		
	gettoken before rest : 0, parse(" ,")
	
	if (`"`before'"' == "," | `"`before'"' == "") {
		local something anything
	}
	else {
		local something varlist
	}
	
	syntax [`something'] [if] [in] [fw] [, Level(cilevel) ///
		MEthod(string) Total SEParator(integer 5) ///
		`SYN_type']
	
	// mark sample for total calculations
	tempvar touse
	marksample touse, novarlist
	
	// for by prefix with total, save original touse BEFORE by-group subsetting
	if "`total'" != "" & _by() {
		tempvar orig_touse
		mark `orig_touse' [`weight'`exp'] `if' `in', noby
		local has_orig_touse 1
	}
	
	// check total option - only allowed with "by" prefix
	if "`total'" != "" & !_by() {
		di as err "option {bf:total} may only be specified with by prefix"
		exit 198
	}
	
	// filter for binary variables
	local no01 0
	local binvars
	
	foreach v of local `something' {
		capture confirm variable `v'
		if _rc continue
		
		capture levelsof `v' `if' `in'
		if !_rc & r(r) > 2 {
			continue
		}
		else {
			local binvars `binvars' `v'
			qui summ `v' `if' `in'
			if (r(min) != 0 & r(min) != 1) | (r(max) != 0 & r(max) != 1) {
				local no01 = `no01' + 1
			}
		}
	}
	
	local nbin : word count `binvars'
	
	// error if no binary variables found
	if "``something''" != "" & ("`binvars'" == "" | `no01' == `nbin') {
		di as err "variables must contain two values coded as either 0 or 1"
		exit 198
	}
	
	local nvar : word count ``something''
	
	// check for multiple method specifications
	local specified_methods `exact' `wald' `wilson' `agresti' `jeffreys' ///
		`waldcorrected' `waldblythstill' `score' `scorecorrected' ///
		`waldlogit' `waldlogitcorrected' `arcsine'
	local method_count : word count `specified_methods'
	
	if `method_count' > 1 {
		di as err "only one method option allowed"
		exit 198
	}
	
	// convert option to method string
	if "`exact'" != "" local method "exact"
	if "`wald'" != "" local method "wald"
	if "`waldcorrected'" != "" local method "wald corrected"
	if "`waldblythstill'" != "" local method "wald-blyth-still"
	if "`agresti'" != "" local method "agresti"
	if "`wilson'" != "" local method "wilson"
	if "`jeffreys'" != "" local method "jeffreys"
	if "`score'" != "" local method "score"
	if "`scorecorrected'" != "" local method "score corrected"
	if "`waldlogit'" != "" local method "wald logit"
	if "`waldlogitcorrected'" != "" local method "wald logit corrected"
	if "`arcsine'" != "" local method "arcsine"
	
	// Handle "by:" prefix
	if _by() & _bylastcall() {
		if "`weight'" != "" {
			local wgt `"[`weight'`exp']"'
		}
		
		if "`level'" != "" {
			local level_opt "level(`level')"
		}
		
		if "`method'" != "" {
			local method_opt "method(`method')"
		}
		
		// display by-group results
		`vv' binomci_core `binvars' if `touse' `wgt', ///
			`level_opt' `method_opt' separator(`separator')
		
		// display total if requested
		if "`total'" != "" {
			di
			di in smcl as txt "{hline 79}"
			di in smcl as txt "-> Total"
			
			// use original touse for total (all observations)
			`vv' binomci_core `binvars' if `orig_touse' `wgt', ///
				`level_opt' `method_opt' separator(`separator')
		}
		exit
	}
	
	// call core program for regular case (no by/ total)
	if "`weight'" != "" {
		local wgt `"[`weight'`exp']"'
	}
	
	`vv' binomci_core `binvars' if `touse' `wgt', ///
		level(`level') method(`method') separator(`separator')

	// return results
	ret scalar level = `level'
	ret scalar ub = r(ci_upper)
	ret scalar lb = r(ci_lower)
	ret scalar se = r(se)
	ret scalar proportion = r(prop)
	ret scalar N = r(n)
	ret scalar x = r(x)
	ret local method = r(method)
	
end

// core calculation program
program binomci_core, rclass
	version 11
	syntax varlist [if] [in] [fw] [, Level(cilevel) MEthod(string) ///
		SEParator(integer 5)]
	
	marksample touse
	
	local nlines 0
	local first_var 1
	local table_marked 0
	local table_warnl ""
	local table_warnh ""
	
	foreach v of local varlist {
		confirm numeric variable `v'
		
		// check if variable is binary
		qui levelsof `v' if `touse', local(levels)
		if !(`"`levels'"' == "0 1" | `"`levels'"' == "1 0" | ///
			`"`levels'"' == "0" | `"`levels'"' == "1") {
			di as err "Variable `v' must be have binary (0/1) values"
			continue
		}
		
		// count successes and trials
		qui sum `v' if `touse'
		local x = r(sum)
		local n = r(N)
		
		if `n' == 0 {
			di as err "No observations for variable `v'"
			continue
		}
		
		local prop = r(mean)
		local se = sqrt(`prop'*(1-`prop')/`n')
		
		// default method if not specified is "exact"
		if "`method'" == "" local method "exact"
		
		// convert Level to alpha for z-value
		local alpha_z = (100 - `level') / 200
		local z = invnormal(1 - `alpha_z')
		
		// convert Level to alpha for proportion calculations
		local alpha = (100 - `level')/100
		
		// calculate lcor for boundary cases (from binomCI in R)
		local lcor = exp(log(`alpha'/2)/`n')
		
		// convert method name
		local method_lower = strlower("`method'")
		local method_index = 0
		local method_display = ""
		
		// method mapping
		if "`method_lower'" == "jeffreys" | "`method_lower'" == "jeffrey" {
			local method_index 1
			local method_display "Jeffreys"
		}
		else if "`method_lower'" == "wald" {
			local method_index 2
			local method_display "Binomial Wald"
		}
		else if "`method_lower'" == "wald corrected" | "`method_lower'" == "waldcorrected" {
			local method_index 3
			local method_display "Wald corrected"
		}
		else if "`method_lower'" == "wald-blyth-still" | "`method_lower'" == "waldblythstill" {
			local method_index 4
			local method_display "Wald-Blyth-Still"
		}
		else if "`method_lower'" == "agresti" | "`method_lower'" == "agresticoull" {
			local method_index 5
			local method_display "Agresti-Coull"
		}
		else if "`method_lower'" == "wilson" {
			local method_index 6
			local method_display "Wilson"
		}
		else if "`method_lower'" == "score" {
			local method_index 7
			local method_display "Score"
		}
		else if "`method_lower'" == "score corrected" | "`method_lower'" == "scorecorrected" {
			local method_index 8
			local method_display "Score corrected"
		}
		else if "`method_lower'" == "wald logit" | "`method_lower'" == "waldlogit" {
			local method_index 9
			local method_display "Wald logit"
		}
		else if "`method_lower'" == "wald logit corrected" | "`method_lower'" == "waldlogitcorrected" {
			local method_index 10
			local method_display "Wald logit corrected"
		}
		else if "`method_lower'" == "arcsine" {
			local method_index 11
			local method_display "Arcsine"
		}
		else if "`method_lower'" == "exact" | "`method_lower'" == "exact binomial" | "`method_lower'" == "exactbinomial" {
			local method_index 12
			local method_display "exact"
		}
		else {
			di as error "Unknown method: `method'"
			di as text "Available methods: jeffreys, wald, waldcorrected, waldblythstill, agresti, wilson, score, scorecorrected, waldlogit, waldlogitcorrected, arcsine, exact"
			continue
		}
		
		// calculate confidence interval
		tempname ci_lower ci_upper
		scalar `ci_lower' = .
		scalar `ci_upper' = .
		
		local mark = ""
		local marked = 0
		local clipped_lower = 0
		local clipped_upper = 0
		
		// 1. JEFFREYS METHOD
		if `method_index' == 1 {
			mata: jeffreys_ci(`x', `n', `alpha')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
		}
		
		// 2. WALD METHOD
		else if `method_index' == 2 {
			if `x' == 0 {
				scalar `ci_lower' = 0
				scalar `ci_upper' = 1 - `lcor'
				local clipped_lower = 1
			}
			else if `x' == `n' {
				scalar `ci_lower' = `lcor'
				scalar `ci_upper' = 1
				local clipped_upper = 1
			}
			else {
				scalar `ci_lower' = `prop' - `z' * `se'
				scalar `ci_upper' = `prop' + `z' * `se'
				
				if scalar(`ci_lower') <= 0 | (scalar(`ci_lower') > -1e-10 & scalar(`ci_lower') < 1e-10) {
					scalar `ci_lower' = 0
					local clipped_lower = 1
				}
				if scalar(`ci_upper') > 1 {
					scalar `ci_upper' = 1
					local clipped_upper = 1
				}
			}
		}
		
		// 3. WALD CORRECTED METHOD
		else if `method_index' == 3 {
			if `x' == 0 {
				scalar `ci_lower' = 0
				scalar `ci_upper' = 1 - `lcor'
				local clipped_lower = 1
			}
			else if `x' == `n' {
				scalar `ci_lower' = `lcor'
				scalar `ci_upper' = 1
				local clipped_upper = 1
			}
			else {
				scalar `ci_lower' = `prop' - `z' * `se' - 0.5/`n'
				scalar `ci_upper' = `prop' + `z' * `se' + 0.5/`n'
				
				if scalar(`ci_lower') <= 0 | (scalar(`ci_lower') > -1e-10 & scalar(`ci_lower') < 1e-10) {
					scalar `ci_lower' = 0
					local clipped_lower = 1
				}
				if scalar(`ci_upper') > 1 {
					scalar `ci_upper' = 1
					local clipped_upper = 1
				}
			}
		}
		
		// 4. WALD-BLYTH-STILL METHOD
		else if `method_index' == 4 {
			if `x' == 0 {
				scalar `ci_lower' = 0
				scalar `ci_upper' = 1 - `lcor'
				local clipped_lower = 1
			}
			else if `x' == `n' {
				scalar `ci_lower' = `lcor'
				scalar `ci_upper' = 1
				local clipped_upper = 1
			}
			else {
				local term = `n' - `z'^2 - 2*`z'/sqrt(`n') - 1/`n'
				if `term' <= 0 local term = 0.0001
				scalar `ci_lower' = `prop' - `z' * sqrt(`prop'*(1-`prop'))/sqrt(`term') - 0.5/`n'
				scalar `ci_upper' = `prop' + `z' * sqrt(`prop'*(1-`prop'))/sqrt(`term') + 0.5/`n'
				
				if scalar(`ci_lower') <= 0 | (scalar(`ci_lower') > -1e-10 & scalar(`ci_lower') < 1e-10) {
					scalar `ci_lower' = 0
					local clipped_lower = 1
				}
				if scalar(`ci_upper') > 1 {
					scalar `ci_upper' = 1
					local clipped_upper = 1
				}
			}
		}
		
		// 5. AGRESTI-COULL METHOD
		else if `method_index' == 5 {
			local xt = `x' + `z'^2/2
			local nt = `n' + `z'^2
			local pt = `xt'/`nt'
			local qt = 1 - `pt'
			
			tempname btem
			scalar `btem' = `pt' - `z' * sqrt(`pt'*`qt')/sqrt(`nt')
			if scalar(`btem') <= 0 | (scalar(`btem') > -1e-10 & scalar(`btem') < 1e-10) {
				scalar `btem' = 0
				local clipped_lower = 1
			}
			scalar `ci_lower' = scalar(`btem')
			
			scalar `btem' = `pt' + `z' * sqrt(`pt'*`qt')/sqrt(`nt')
			if scalar(`btem') > 1 & scalar(`btem') < . {
				scalar `btem' = 1
				local clipped_upper = 1
			}
			scalar `ci_upper' = scalar(`btem')
		}
		
		// 6. WILSON METHOD
		else if `method_index' == 6 {
			local xb = `x' + `z'^2/2
			local nb = `n' + `z'^2
			local pb = `xb'/`nb'
			
			tempname btem
			scalar `btem' = `pb' - (`z' * sqrt(`n')/`nb') * sqrt(`prop'*(1-`prop') + `z'^2/(4*`n'))
			
			if scalar(`btem') <= 0 | (scalar(`btem') > -1e-10 & scalar(`btem') < 1e-10) {
				scalar `btem' = 0
				local clipped_lower = 1
			}
			scalar `ci_lower' = scalar(`btem')
			
			scalar `btem' = `pb' + (`z' * sqrt(`n')/`nb') * sqrt(`prop'*(1-`prop') + `z'^2/(4*`n'))
			if scalar(`btem') > 1 & scalar(`btem') < . {
				scalar `btem' = 1
				local clipped_upper = 1
			}
			scalar `ci_upper' = scalar(`btem')
		}
		
		// 7. SCORE METHOD
		else if `method_index' == 7 {
			mata: score_ci(`x', `n', `alpha', `z')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
			local clipped_lower = r(clipped_lower)
			local clipped_upper = r(clipped_upper)
		}
		
		// 8. SCORE CORRECTED METHOD
		else if `method_index' == 8 {
			mata: score_corrected_ci(`x', `n', `alpha', `z')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
			local clipped_lower = r(clipped_lower)
			local clipped_upper = r(clipped_upper)
		}
		
		// 9. WALD LOGIT METHOD
		else if `method_index' == 9 {
			mata: wald_logit_ci(`x', `n', `alpha', `z')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
			local clipped_lower = r(clipped_lower)
			local clipped_upper = r(clipped_upper)
		}
		
		// 10. WALD LOGIT CORRECTED METHOD
		else if `method_index' == 10 {
			mata: wald_logit_corrected_ci(`x', `n', `alpha', `z')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
			local clipped_lower = r(clipped_lower)
			local clipped_upper = r(clipped_upper)
		}
		
		// 11. ARCSINE METHOD
		else if `method_index' == 11 {
			mata: arcsine_ci(`x', `n', `alpha', `z')
			scalar `ci_lower' = r(ci_lower)
			scalar `ci_upper' = r(ci_upper)
			local clipped_lower = r(clipped_lower)
			local clipped_upper = r(clipped_upper)
		}
		
		// 12. EXACT METHOD (Clopper-Pearson)
		else if `method_index' == 12 {
			if `x' == 0 {
				scalar `ci_lower' = 0
				scalar `ci_upper' = 1 - (`alpha'/2)^(1/`n')
				local mark "*"
				local marked = 1
			}
			else if `x' == `n' {
				scalar `ci_lower' = (`alpha'/2)^(1/`n')
				scalar `ci_upper' = 1
				local mark "*"
				local marked = 1
			}
			else {
				mata: exact_ci(`x', `n', `alpha')
				scalar `ci_lower' = r(ci_lower)
				scalar `ci_upper' = r(ci_upper)
			}
		}
		
		// final safety check with tolerance
		if scalar(`ci_lower') < 0 | (scalar(`ci_lower') > -1e-10 & scalar(`ci_lower') < 1e-10) {
			scalar `ci_lower' = 0
			if `method_index' != 1 & `method_index' != 12 {
				local clipped_lower = 1
			}
		}
		if scalar(`ci_upper') > 1 {
			scalar `ci_upper' = 1
			if `method_index' != 1 & `method_index' != 12 {
				local clipped_upper = 1
			}
		}
		
		// track Exact method marking
		if `marked' == 1 {
			if `table_marked' == 0 {
				local table_marked 1
			}
		}
		
		// track warnings for clipping
		if `clipped_lower' == 1 & `method_index' != 1 & `method_index' != 12 {
			if `"`table_warnl'"' == "" {
				local table_warnl "(*) The `method_display' interval was clipped at the lower endpoint"
			}
			local mark "*"
			local table_marked 2
		}
		if `clipped_upper' == 1 & `method_index' != 1 & `method_index' != 12 {
			if `"`table_warnh'"' == "" {
				local table_warnh "(**) The `method_display' interval was clipped at the upper endpoint"
			}
			if "`mark'" == "" {
				local mark "**"
			}
			else {
				local mark "* **"
			}
			local table_marked 2
		}
		
		// display method header for first variable
		if `first_var' {
			local level_display = `level'
			
			if "`method_display'" == "Jeffreys" {
				di as txt _newline _col(64) "Jeffreys"
			}
			else if "`method_display'" == "Wilson" {
				di as txt _newline _col(65) "Wilson"
			}
			else if "`method_display'" == "Score" {
				di as txt _newline _col(65) "Score"
			}
			else if "`method_display'" == "Arcsine" {
				di as txt _newline _col(65) "Arcsine"
			}
			else if "`method_display'" == "Wald logit" {
				di as txt _newline _col(64) "Wald logit"
			}
			else if "`method_display'" == "Wald logit corrected" {
				di as txt _newline _col(58) "Wald logit corrected"
			}
			else if "`method_display'" == "Binomial Wald" {
				di as txt _newline _col(62) "Binomial Wald"
			}
			else if "`method_display'" == "Agresti-Coull" {
				di as txt _newline _col(61) "Agresti{char 150}Coull"
			}
			else if "`method_display'" == "Wald-Blyth-Still" {
				di as txt _newline _col(61) "Wald{char 150}Blyth{char 150}Still"
			}
			else if "`method_display'" == "Wald corrected" {
				di as txt _newline _col(61) "Wald corrected"
			}
			else if "`method_display'" == "exact" {
				di as txt _newline _col(61) "Binomial exact"
			}
			else {
				di as txt _newline _col(61) "`method_display'"
			}
			
			di as txt %12s "Variable" " {c |}" /*
				*/ _col(23) "Obs" /*
				*/ _col(29) "Proportion" /*
				*/ _col(44) "Std. err." /*
				*/ _col(58) "[`level_display'% conf. interval]"
			di as txt "{hline 13}{c +}{hline 63}"
			
			local first_var 0
		}
		
		// display separator line
		if (mod(`nlines++', `separator') == 0) {
			if `nlines' != 1 {
				di as txt "{hline 13}{c +}{hline 63}"
			}
		}
		
		// display the main result line
		local fmt = "%9.0g"
		di as txt %12s abbrev("`v'",12) " {c |}" /*
			*/ as res _col(17) `fmt' `n' /*
			*/ _col(30) `fmt' `prop' /*
			*/ _col(43) `fmt' `se' /*
			*/ _col(57) `fmt' scalar(`ci_lower') /*
			*/ _col(69) `fmt' scalar(`ci_upper') in gr "`mark'"

		// return values for this variable
		return scalar n = `n'
		return scalar x = `x'
		return scalar prop = `prop'
		return scalar se = `se'
		return scalar ci_lower = scalar(`ci_lower')
		return scalar ci_upper = scalar(`ci_upper')
		return scalar clipped_lower = `clipped_lower'
		return scalar clipped_upper = `clipped_upper'
		return local method "`method_display'"
	}
	
	// display warnings at the end of the table
	if `table_marked' == 1 {
		di _n in gr "(*) one-sided, " 100-(100-`level')/2 /*
		*/ "% confidence interval"
	}
	if `table_marked' == 2 {
		if `"`table_warnl'"'!="" | `"`table_warnh'"' != "" {
			di
			if `"`table_warnl'"'!="" {
				di in gr "`table_warnl'"
			}
			if `"`table_warnh'"'!="" {
				di in gr "`table_warnh'"
			}
		}
	}
end

// Mata functions
version 11
mata:
mata clear

void exact_ci(real scalar x, real scalar n, real scalar alpha)
{
	real scalar a1, a2, d1, d2, res1, res2
	
	a1 = n - x + 1
	if (2*a1 > 0 & 2*x > 0) {
		d1 = x * invF(2*x, 2*a1, alpha/2)
	}
	else {
		d1 = x * 1000
	}
	
	a2 = a1 - 1
	if (2*(x + 1) > 0 & 2*a2 > 0) {
		d2 = (x + 1) * invF(2*(x + 1), 2*a2, 1 - alpha/2)
	}
	else {
		d2 = (x + 1) * 0.001
	}
	
	res1 = 1/(1 + a1/d1)
	res2 = 1/(1 + a2/d2)
	
	st_numscalar("r(ci_lower)", res1)
	st_numscalar("r(ci_upper)", res2)
}

void jeffreys_ci(real scalar x, real scalar n, real scalar alpha)
{
	real scalar com
	
	com = n - x + 0.5
	if (x == 0) {
		st_numscalar("r(ci_lower)", 0)
		st_numscalar("r(ci_upper)", invibeta(x + 0.5, com, 1 - alpha/2))
	}
	else if (x == n) {
		st_numscalar("r(ci_lower)", invibeta(x + 0.5, com, alpha/2))
		st_numscalar("r(ci_upper)", 1)
	}
	else {
		st_numscalar("r(ci_lower)", invibeta(x + 0.5, com, alpha/2))
		st_numscalar("r(ci_upper)", invibeta(x + 0.5, com, 1 - alpha/2))
	}
}

void score_ci(real scalar x, real scalar n, real scalar alpha, real scalar z)
{
	real scalar clipped_lower, clipped_upper, com, res1, res2, prop
	
	clipped_lower = 0
	clipped_upper = 0
	prop = x/n
	
	com = z * sqrt(z^2 + 4*n*prop*(1 - prop))
	res1 = (2*n*prop + z^2 - com) / (2*(n + z^2))
	res2 = (2*n*prop + z^2 + com) / (2*(n + z^2))
	
	if (res1 < 0) {
		res1 = 0
		clipped_lower = 1
	}
	if (res2 > 1) {
		res2 = 1
		clipped_upper = 1
	}
	
	st_numscalar("r(ci_lower)", res1)
	st_numscalar("r(ci_upper)", res2)
	st_numscalar("r(clipped_lower)", clipped_lower)
	st_numscalar("r(clipped_upper)", clipped_upper)
}

void score_corrected_ci(real scalar x, real scalar n, real scalar alpha, real scalar z)
{
	real scalar clipped_lower, clipped_upper, prop, q, z2, nz2, term1, term2, res1, res2
	
	clipped_lower = 0
	clipped_upper = 0
	prop = x/n
	q = 1 - prop
	z2 = z^2
	nz2 = n + z2
	
	if (x == 0) {
		res1 = 0
		term2 = sqrt(z2 + 2 - 1/n + 4*0*(n*1 - 1))
		res2 = (2*n*0 + z2 + 1 + z*term2) / (2*nz2)
		clipped_lower = 1
	}
	else if (x == n) {
		term1 = sqrt(z2 - 2 - 1/n + 4*1*(n*0 + 1))
		res1 = (2*n*1 + z2 - 1 - z*term1) / (2*nz2)
		res2 = 1
		clipped_upper = 1
	}
	else {
		term1 = sqrt(z2 - 2 - 1/n + 4*prop*(n*q + 1))
		term2 = sqrt(z2 + 2 - 1/n + 4*prop*(n*q - 1))
		
		res1 = (2*n*prop + z2 - 1 - z*term1) / (2*nz2)
		res2 = (2*n*prop + z2 + 1 + z*term2) / (2*nz2)
		
		if (res1 < 0) {
			res1 = 0
			clipped_lower = 1
		}
		if (res2 > 1) {
			res2 = 1
			clipped_upper = 1
		}
	}
	
	st_numscalar("r(ci_lower)", res1)
	st_numscalar("r(ci_upper)", res2)
	st_numscalar("r(clipped_lower)", clipped_lower)
	st_numscalar("r(clipped_upper)", clipped_upper)
}

void wald_logit_ci(real scalar x, real scalar n, real scalar alpha, real scalar z)
{
	real scalar clipped_lower, clipped_upper, prop, b, com, r1, r2, lcor
	
	clipped_lower = 0
	clipped_upper = 0
	prop = x/n
	lcor = exp(log(alpha/2)/n)
	
	if (x == 0) {
		st_numscalar("r(ci_lower)", 0)
		st_numscalar("r(ci_upper)", 1 - lcor)
		clipped_lower = 1
	}
	else if (x == n) {
		st_numscalar("r(ci_lower)", lcor)
		st_numscalar("r(ci_upper)", 1)
		clipped_upper = 1
	}
	else {
		b = log(x/(n - x))
		com = z/sqrt(x * (1 - prop))
		r1 = exp(b - com)
		r2 = exp(b + com)
		r1 = 1 - 1/(1 + r1)
		r2 = 1 - 1/(1 + r2)
		
		if (r1 <= 0 | (r1 > -1e-10 & r1 < 1e-10)) {
			r1 = 0
			clipped_lower = 1
		}
		if (r2 > 1) {
			r2 = 1
			clipped_upper = 1
		}
		
		st_numscalar("r(ci_lower)", r1)
		st_numscalar("r(ci_upper)", r2)
	}
	
	st_numscalar("r(clipped_lower)", clipped_lower)
	st_numscalar("r(clipped_upper)", clipped_upper)
}

void wald_logit_corrected_ci(real scalar x, real scalar n, real scalar alpha, real scalar z)
{
	real scalar clipped_lower, clipped_upper, pb_adj, qb, b, com, r1, r2, lcor
	
	clipped_lower = 0
	clipped_upper = 0
	lcor = exp(log(alpha/2)/n)
	
	if (x == 0) {
		st_numscalar("r(ci_lower)", 0)
		st_numscalar("r(ci_upper)", 1 - lcor)
		clipped_lower = 1
	}
	else if (x == n) {
		st_numscalar("r(ci_lower)", lcor)
		st_numscalar("r(ci_upper)", 1)
		clipped_upper = 1
	}
	else {
		pb_adj = x + 0.5
		qb = n - x + 0.5
		b = log(pb_adj/qb)
		com = z/sqrt((n + 1) * pb_adj/(n + 1) * (1 - pb_adj/(n + 1)))
		r1 = exp(b - com)
		r2 = exp(b + com)
		r1 = 1 - 1/(1 + r1)
		r2 = 1 - 1/(1 + r2)
		
		if (r1 <= 0 | (r1 > -1e-10 & r1 < 1e-10)) {
			r1 = 0
			clipped_lower = 1
		}
		if (r2 > 1) {
			r2 = 1
			clipped_upper = 1
		}
		
		st_numscalar("r(ci_lower)", r1)
		st_numscalar("r(ci_upper)", r2)
	}
	
	st_numscalar("r(clipped_lower)", clipped_lower)
	st_numscalar("r(clipped_upper)", clipped_upper)
}

void arcsine_ci(real scalar x, real scalar n, real scalar alpha, real scalar z)
{
	real scalar clipped_lower, clipped_upper, prop, pb, com, r1, r2, lcor
	
	clipped_lower = 0
	clipped_upper = 0
	prop = x/n
	lcor = exp(log(alpha/2)/n)
	
	if (x == 0) {
		st_numscalar("r(ci_lower)", 0)
		st_numscalar("r(ci_upper)", 1 - lcor)
		clipped_lower = 1
	}
	else if (x == n) {
		st_numscalar("r(ci_lower)", lcor)
		st_numscalar("r(ci_upper)", 1)
		clipped_upper = 1
	}
	else {
		pb = asin(sqrt(prop))
		com = 0.5 * z/sqrt(n)
		r1 = pb - com
		r2 = pb + com
		r1 = sin(r1)^2
		r2 = sin(r2)^2
		
		if (r1 <= 0 | (r1 > -1e-10 & r1 < 1e-10)) {
			r1 = 0
			clipped_lower = 1
		}
		if (r2 > 1) {
			r2 = 1
			clipped_upper = 1
		}
		
		st_numscalar("r(ci_lower)", r1)
		st_numscalar("r(ci_upper)", r2)
	}
	
	st_numscalar("r(clipped_lower)", clipped_lower)
	st_numscalar("r(clipped_upper)", clipped_upper)
}

end