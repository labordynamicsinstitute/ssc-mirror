*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_getstatsaipw
program define _teffects2_getstatsaipw, sclass
	version 17
	
	syntax , [ ate atet nrm unnrm ]
	
	local kn 0
	if "`unnrm'"!="" local kn = `kn' + 1
	if "`nrm'"!="" local kn = `kn' + 1
	
	local kt 0
	if "`ate'"!="" local kt = `kt' + 1
	if "`atet'"!="" local kt = `kt' + 1
	
	if `kn' > 1 {
		di as err "{p}{bf:nrm} and {bf:unnrm} cannot both be specified{p_end}"
		exit 184
	}
	
	if `kt' > 1 {
		di as err "{p}{bf:ate} and {bf:atet} cannot both be specified{p_end}"
		exit 184
	}
	
	if `kn'==0 {
		local stat2 = "unnrm"
	}
	else if `kn'==1 & "`nrm'"!="" {
		local stat2 = "nrm"
	}
	else if `kn'==1 & "`unnrm'"!="" {
		local stat2 = "unnrm"
	}
	
	if `kt'==0 {
		local stat1 = "ate"
	}
	else if `kt'==1 & "`ate'"!="" {
		local stat1 = "ate"
	}
	else if `kt'==1 & "`atet'"!="" {
		local stat1 = "atet"
	}
	
	sreturn local stat1 "`stat1'"
	sreturn local stat2 "`stat2'"
	sreturn local statkt "`kt'"
	sreturn local statkn "`kn'"
end
