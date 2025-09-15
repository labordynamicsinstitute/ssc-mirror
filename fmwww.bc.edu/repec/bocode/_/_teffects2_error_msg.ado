*! version 1.0.0  12sep2025  S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge

* SPDX-License-Identifier: MIT
* Copyright (c) 2025 S. Derya Uysal, Tymon Sloczynski, and Jeffrey M. Wooldridge
* See the LICENSE file in this distribution for full text.

capture program drop _teffects2_error_msg
program define _teffects2_error_msg
	version 17
	
	syntax, cmd(string) case(string) [ rc(string) ]
	
	if "`rc'" == "" {
		local rc = 198
	}
	
	if "`cmd'" == "aipw" | "`cmd'" == "ipwra" {
		local vlist1 " varlist"
		local vlist2 " varlist"
	}
	else if "`cmd'" == "ipw" {
		local vlist1 ""
		local vlist2 " varlist"
	}
	
	if "`case'" == "1" {
		display as err "{p}treatment-model specification is missing{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "2" {
		display as err "{p}only two model specifications may be specified{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "3" {
		display as err "{p}too many variables in treatment-model specification{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "4" {
		display as err "{p}too many variables in outcome-model specification{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "5" {
		display as txt "{phang}The treatment model is misspecified.{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "6" {
		display as txt "{phang}There are too many variables in the " ///
		"treatment-model specification.{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)} {p_end}"
		exit `rc'
	}
	else if "`case'" == "7" {
		display as txt "{phang}The outcome model is misspecified.{p_end}"
		display as txt "{phang}An outline of the syntax is{p_end}"
		display as txt "{phang}{helpb teffects2 `cmd'} " ///
		"{bf:(}{it:outcome_variable`vlist1'}{bf:)} " ///
		"{bf:(}{it:treatment_variable`vlist2'}{bf:)}{p_end}"
		exit `rc'
	}
	else {
		exit 498
	}
end
