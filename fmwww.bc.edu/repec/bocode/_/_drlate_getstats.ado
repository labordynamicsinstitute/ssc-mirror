*! version 1.0.0  12may2026  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _drlate_getstats
program define _drlate_getstats, sclass
	version 17
	
	syntax , [ late latt nrm unnrm ]
	
	// Check normalization options
	local kn 0
	if "`unnrm'" != "" local kn = `kn' + 1
	if "`nrm'" != "" local kn = `kn' + 1
	
	// Check effect type options
	local kt 0
	if "`late'" != "" local kt = `kt' + 1
	if "`latt'" != "" local kt = `kt' + 1
	
	// Enforce mutual exclusivity
	if `kn' > 1 {
		di as err "{p}{bf:nrm} and {bf:unnrm} cannot both be specified{p_end}"
		exit 184
	}
	if `kt' > 1 {
		di as err "{p}{bf:late} and {bf:latt} cannot both be specified{p_end}"
		exit 184
	}
	
	// Assign normalization type (default = nrm)
	if `kn' == 0 | "`nrm'" != "" {
		local stat2 = "nrm"
	}
	else {
		local stat2 = "unnrm"
	}
	
	// Assign effect type (default = late)
	if `kt' == 0 | "`late'" != "" {
		local stat1 = "late"
	}
	else {
		local stat1 = "latt"
	}
	
	// Return
	sreturn local stat1 "`stat1'" // "late" or "latt"
	sreturn local stat2 "`stat2'" // "nrm" or "unnrm"
	sreturn local statkn "`kn'" // number of normalization flags used
	sreturn local statkt "`kt'" // number of effect type flags used
end
