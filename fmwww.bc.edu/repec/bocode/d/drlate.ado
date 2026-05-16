*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop drlate
program define drlate, eclass byable(onecall)
	version 17
	
	if _by() {
		local BY "by `_byvars'`_byrc0':"
	}
	
	local cmdline `"drlate `0'"'
	local cmdline: list retokenize cmdline
	
	_drlate_parse `0'
	
	// Extract each block using separate sreturn values
	// Avoid tokenize which rejects factor variable operators
	local y "`s(depvar_1)'"
	local ymodel `"`s(indepvars_1)'"'
	local ymethod "`s(model_1)'"
	
	local d "`s(depvar_2)'"
	local dmodel `"`s(indepvars_2)'"'
	local dmethod "`s(model_2)'"
	
	local z "`s(depvar_3)'"
	local zmodelvars `"`s(indepvars_3)'"'
	local zmethod "`s(model_3)'"
	
	// Translate linear -> regress for internal use
	if "`ymethod'" == "linear" local ymethod "regress"
	if "`dmethod'" == "linear" local dmethod "regress"
	
	// Call the main estimation routine
	`BY' drlate_estimate `s(if)' `s(in)' `s(wt)', ///
		yvar(`y') ///
		tvar(`d') ///
		zvar(`z') ///
		omodel(`ymethod') ///
		tmodel(`dmethod') ///
		zmodel(`zmethod') ///
		ymodelvars(`ymodel') ///
		tmodelvars(`dmodel') ///
		zmodelvars(`zmodelvars') ///
		`s(options)'
	
	// Store metadata
	ereturn local cmd "drlate"
	ereturn local cmdline `"`cmdline'"'
	ereturn local yvar "`y'"
	ereturn local tvar "`d'"
	ereturn local zvar "`z'"
	ereturn local omodel "`ymethod'"
	ereturn local tmodel "`dmethod'"
	ereturn local zmodel "`zmethod'"
	ereturn local ymodelvars `"`ymodel'"'
	ereturn local tmodelvars `"`dmodel'"'
	ereturn local zmodelvars `"`zmodelvars'"'
	ereturn local ifcond "`s(if)'"
	ereturn local options "`s(options)'"
	ereturn local method "`method'"
	ereturn display
end
