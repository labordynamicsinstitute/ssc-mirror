*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _drlate_options
program define _drlate_options, sclass
	version 17
	
	syntax, [ from(passthru) NOLOg LOg ENSeparator verbose ///
		PSTOLerance(real 1E-5) OSample(name) EPSCD(real 1E-8) * ]
	
	// Validate pstolerance
	if "`pstolerance'" != "" {
		if `pstolerance' < 0 | `pstolerance' >= 1 {
			di as err "{p}{bf:pstolerance()} must be >= 0 and < 1{p_end}"
			exit 198
		}
		local pstol pstolerance(`pstolerance')
	}
	
	// Validate epscd
	if "`epscd'" != "" {
		if `epscd' < 0 | `epscd' >= 1 {
			di as err "{p}{bf:epscd()} must be >= 0 and < 1{p_end}"
			exit 198
		}
		local epscd epscd(`epscd')
	}
	
	// Validate osample
	if "`osample'" != "" {
		cap confirm variable `osample'
		if !c(rc) {
			di as err "{p}invalid option {bf:osample()}; variable `osample' already exists{p_end}"
			exit 110
		}
		local osopt osample(`osample')
	}
	
	local opts "`from' `log' `nolog' `enseparator' `verbose'"
	local opts "`opts' `pstol' `epscd' `osopt'"
	
	sreturn local drlateopts "`opts'"
	sreturn local rest `"`options'"'
end
