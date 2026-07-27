*! version 1.0.0  25jul2026  Alexandre Poirier and Tymon Słoczyński

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 Alexandre Poirier and Tymon Słoczyński
* See the LICENSE file in this distribution for full text.

capture program drop causalrep
program define causalrep, eclass
	version 14
	
	local cmdline `"causalrep `0'"'
	local cmdline: list retokenize cmdline
	
	gettoken proc rest : 0, parse(" ,")
	local proc = lower(`"`proc'"')
	
	if `"`proc'"'=="" | `"`proc'"'=="," {
		display as error "subcommand required; expected one of {bf:ols}, {bf:iv}, or {bf:did}"
		exit 198
	}
	
	local 0 `"`rest'"'
	
	if `"`proc'"'=="ols" {
		_causalrep_ols `0'
	}
	else if `"`proc'"'=="iv" {
		_causalrep_iv `0'
	}
	else if `"`proc'"'=="did" {
		_causalrep_did `0'
	}
	else {
		display as error "invalid subcommand {bf:`proc'}; expected one of {bf:ols}, {bf:iv}, or {bf:did}"
		exit 198
	}
	
	ereturn local subcmd "`proc'"
	ereturn local cmd "causalrep"
	ereturn local cmdline `"`cmdline'"'
end

exit
