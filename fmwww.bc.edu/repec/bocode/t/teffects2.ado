*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop teffects2
program define teffects2, eclass byable(onecall) prop(twopart)
	version 17
	
	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	local cmdline `"teffects2 `0'"'
	local cmdline: list retokenize cmdline
	
	gettoken proc rest : 0, parse(" ,")
	
	else {
		local 0 `rest'
		if "`proc'" == "ipw" {
			`BY' _vce_parserun _teffects2_ipw: `0'
		}
		else if "`proc'" == "ipwra" {
			`BY' _vce_parserun _teffects2_ipwra: `0'
		}
		else if "`proc'" == "aipw" {
			`BY' _vce_parserun _teffects2_aipw: `0'
		}
		if "`s(exit)'" != "" & !inlist("`proc'","nnmatch","psmatch","overlap") {
			ereturn local predict teffects2_p
			ereturn local cmdline `"`cmdline'"'
			ereturn local cmd "teffects2"
			ereturn hidden local _contrast_not_ok "_ALL"
			exit
		}
	}
	
	if "`proc'" == "ipw" {
		`BY' _teffects2_ipw `0'
	}
	else if "`proc'" == "ipwra" {
		`BY' _teffects2_ipwra `0'
	}
	else if "`proc'" == "aipw" {
		`BY' _teffects2_aipw `0'
	}
	else {
		di as err "{p}invalid procedure; expected one of {bf:ipw}, " ///
		"{bf:ipwra}, or {bf:aipw}{p_end}"
		exit 198
	}
end

exit
