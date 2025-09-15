*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_count_obs
program define _teffects2_count_obs, rclass
	version 17
	syntax varname(numeric), [ why(string) freq(varname) ]
	
	local touse `varlist'
	
	// Count observations
	quietly count if `touse'
	if r(N)==0 {
		if "`why'"!="" {
			di as err "{p}No observations after dropping `why'{p_end}"
			exit 2000
		}
		else error 2000
	}
	
	// Optional: warn if < 4 obs
	if r(N)<4 {
		if "`why'"!="" {
			di as err "{p}Insufficient observations after dropping `why'{p_end}"
			exit 2001
		}
		else error 2001
	}
	
	return scalar N = r(N)
end
