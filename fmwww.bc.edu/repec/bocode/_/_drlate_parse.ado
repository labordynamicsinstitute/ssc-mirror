*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

// -----------------------------------------------------------------
// _drlate_parse
// Parse drlate equation specification:
// (y [xvars] [, model]) (d [xvars] [, model]) (z [xvars] [, model])
//
// Returns via sreturn for each equation i=1,2,3:
// s(depvar_i) - dependent variable
// s(indepvars_i) - independent variables (may include factor vars)
// s(model_i) - model type string
// s(eqn_i) - "depvar indepvars" combined
//
// Also: s(if), s(in), s(wt), s(options), s(eqn_n)
//
// Block extraction to handle nested
// parentheses in factor variable notation:
// i.(black south smsa), c.exper##c.exper etc.
// -----------------------------------------------------------------

capture program drop _drlate_parse
program define _drlate_parse, sclass
	version 17
	
	syntax anything(name=spec) [if] [in] [pw] [, *]
	
	sreturn clear
	sreturn local if `"`if'"'
	sreturn local in `"`in'"'
	if `"`weight'"' != "" sreturn local wt `"[`weight'`exp']"'
	sreturn local options `"`options'"'
	
	// -----------------------------------------------------------------
	// Extract three equation blocks by counting parenthesis
	// depth. This correctly handles nested parens such as
	// i.(black south smsa) and c.exper##c.exper inside blocks.
	// -----------------------------------------------------------------
	local remaining `"`spec'"'
	local nblocks 0
	
	while `"`remaining'"' != "" {
		// Find the next opening paren
		local pos_open = strpos(`"`remaining'"', "(")
		if `pos_open' == 0 {
			// Stop if no more opening parens
			continue, break
		}
		
		// Advance past the opening paren
		local remaining = substr(`"`remaining'"', `pos_open' + 1, .)
		
		// Now collect everything until the matching closing paren
		// using depth counting
		local depth 1
		local block ""
		local len = strlen(`"`remaining'"')
		local i 1
		
		while `i' <= `len' & `depth' > 0 {
			local ch = substr(`"`remaining'"', `i', 1)
			if `"`ch'"' == "(" {
				local depth = `depth' + 1
				local block `"`block'`ch'"'
			}
			else if `"`ch'"' == ")" {
				local depth = `depth' - 1
				if `depth' > 0 {
					local block `"`block'`ch'"'
				}
				// If depth==0 we have found the matching close paren
			}
			else {
				local block `"`block'`ch'"'
			}
			local i = `i' + 1
		}
		
		// Advance remaining past what we consumed
		local remaining = substr(`"`remaining'"', `i', .)
		
		local nblocks = `nblocks' + 1
		local rawblock`nblocks' `"`block'"'
	}
	
	if `nblocks' < 3 {
		di as err "{p}Syntax error: expected " ///
			"(y [xvars] [, model]) " ///
			"(d [xvars] [, model]) " ///
			"(z [xvars] [, model]){p_end}"
		exit 198
	}
	
	if `nblocks' > 3 {
		di as err "{p}Syntax error: too many equation blocks; " ///
			"expected exactly 3{p_end}"
		exit 198
	}
	
	// -----------------------------------------------------------------
	// Parse each raw block into depvar, indepvars, model
	// -----------------------------------------------------------------
	local default_1 linear
	local default_2 logit
	local default_3 logit
	
	forvalues i = 1/3 {
		local raw `"`rawblock`i''"'
		
		// Split on comma to get varlist part vs model option
		// Use strpos to find first comma
		local pos_comma = strpos(`"`raw'"', ",")
		
		if `pos_comma' > 0 {
			local varpart = substr(`"`raw'"', 1, `pos_comma' - 1)
			local modelpart = substr(`"`raw'"', `pos_comma' + 1, .)
			local model : list retokenize modelpart
		}
		else {
			local varpart `"`raw'"'
			local model "`default_`i''"
		}
		
		// Validate model type
		if `i' == 1 {
			if !inlist("`model'", "linear", "logit", "poisson") {
				di as err "{p}Invalid model for outcome equation: " ///
					"{bf:`model'}. " ///
					"Allowed: linear, logit, poisson.{p_end}"
				exit 198
			}
		}
		else if `i' == 2 {
			if !inlist("`model'", "linear", "logit", "poisson") {
				di as err "{p}Invalid model for treatment equation: " ///
					"{bf:`model'}. " ///
					"Allowed: linear, logit, poisson.{p_end}"
				exit 198
			}
		}
		else if `i' == 3 {
			if !inlist("`model'", "logit", "ipt", "cbps") {
				di as err "{p}Invalid model for instrument equation: " ///
					"{bf:`model'}. " ///
					"Allowed: logit, ipt, cbps.{p_end}"
				exit 198
			}
		}
		
		// Trim leading/trailing whitespace from varpart
		local varpart : list retokenize varpart
		
		// Split varpart into depvar (first token) and indepvars (rest)
		// using gettoken which handles factor variable tokens correctly
		gettoken depvar indepvars : varpart, bind
		local indepvars : list retokenize indepvars
		
		if "`depvar'" == "" {
			di as err "{p}Syntax error in equation `i': " ///
				"no dependent variable found{p_end}"
			exit 198
		}
		
		sreturn local depvar_`i' "`depvar'"
		sreturn local indepvars_`i' `"`indepvars'"'
		sreturn local model_`i' "`model'"
		sreturn local eqn_`i' `"`depvar' `indepvars'"'
	}
	
	sreturn local eqn_n 3
end
