*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_vlist_exclusive2
program define _teffects2_vlist_exclusive2
	version 17
	
	syntax, vlist1(varlist numeric fv) vlist2(varlist numeric fv) ///
	[ wh2(string) wh1(string) case(string) ]
	
	while strlen("`vlist1'") {
		local xlist2 `vlist2'
		gettoken var1 vlist1 : vlist1, bind
		while strlen("`xlist2'") {
			gettoken var2 xlist2 : xlist2, bind
			if "`var1'"=="`var2'" {
				if ("`case'"=="1") {
					display as err "{p}the outcome variable cannot be " ///
					"the same as the treatment variable{p_end}"
					exit 198
				}
				else if ("`case'"=="2") {
					display as err "{p}the treatment variable cannot be " ///
					"in the outcome-model specification{p_end}"
					exit 198
				}
				else if ("`case'"=="3") {
					display as err "{p}`wh1'{p_end}"
					exit 198
				}
				else if ("`case'"=="4") {
					display as err "{p}the treatment variable cannot be " ///
					"repeated in the treatment-model specification{p_end}"
					exit 198
				}
				else {
					di as err "syntax error"
					exit 498
				}
			}
		}
	}
end
