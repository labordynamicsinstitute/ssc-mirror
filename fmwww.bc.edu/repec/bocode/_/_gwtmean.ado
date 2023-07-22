/*
_gwtmean.ado  originated 6-5-2001

David Kantor, Originally developed at Institute for Policy Studies, Johns Hopkins University

This is an egen weighted mean function, based on c:\stata\ado\_\_gmean.ado
Actually, it is just a very minor tweaking of _gmean.

In fact this could be considered an enhancement to _gmean.


Also note, that if you want to subsequently condense to byvar groups, you
might as well use -collapse- instead, with a weight.


This is used with egen as follows:

 egen newvar = wtmean(exp), by(byvar) weight(wgt_expr)

This allows a weight option.  egen does not allow a weight in the usual
manner ([weight= wgtvar]), so we us an option.  If the weight option is
omitted, then the action and results are identical to egen mean
(_gmean.ado).  (If the weight expression is a non-zero constant, then, too,
the results are identical to egen mean.)

The weight macro captures the weight.  If it is non-empty, then
it is changed to include parentheses and the * operator.  The inclusion
of parentheses actually allows an expression -- not just a variable.
*/


* 2023jul18: updating to use -syntax-, rather than -parse-
*! version 2.0.0  2023jul18

program define _gwtmean
	version 14.2
	syntax newvarname =/exp [if] [in] [, by(varlist) weight(string)]
	
	tempvar touse 
	if `"`weight'"' ~= "" {
		tempvar w
		capture noisily gen double `w' = `weight'
		if _rc {
			disp as err "error in weight expression"
			exit 198
		}
		local wtfactor "*`w'"
	}
	quietly {
		gen byte `touse'=1 `if' `in'
		sort `touse' `by'
		by `touse' `by': gen `typlist' `varlist' = /*
			*/ sum((`exp')`wtfactor')/sum((~mi(`exp'))`wtfactor') if `touse'==1
		by `touse' `by': replace `varlist' = `varlist'[_N]
	}
end

