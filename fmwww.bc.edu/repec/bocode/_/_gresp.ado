*! version 0.5.1 07oct2021
/*
  The Activity Index (AI) of a  variable x is defined as a fraction of fractions.
  Thereby the dividend of the AI is the fraction of the original variable by the 
  aggregation of that variable along the first dimension. The divisor of the AI 
  is the fraction of the aggregation of the original variable along the second
  dimension by the overall sum of it. In mathematical notation and by the use of
  sum(x|y) as aggregation of x along y we get:
    ai(x) := (x/sum(x|dim1)) / (sum(x|dim2)/sum(x)).
	
  Further, there exists three important scaling of the AI: the logarithmic scale
  of the AI (RPA), the hyperbolic tangent of the RPA (RESP) and the hyperbolic
  tangent of the square root of the AI (RSI). In formulas:
    rpa(ai) := ln(ai)
	rsi(ai) := (ai - 1) / (ai + 1)
	resp(ai) := 100 * (ai^2 - 1) / (ai^2 + 1)
	
  Furthermore, there exists two important derivatives of the ai, that alter
  the second fraction thus the divisor of the AI and are used specifically
  for measuring collaboration in a network. Here dim1 and dim2 mean collaboration
  partner 1 and collaboration partner 2.
    aoer(x) := (x/sum(x|dim1)) / (sum(x|dim2)/(sum(x) - sum(x|dim1)))
	ric(x) := (x/sum(x|dim1)) / ((sum(x|dim2) - x)/(sum(x) - sum(x|dim1)))
	
  Author:
    Joel E. H. Fuchs a.k.a. Fantastic Captain Fox
	jfuchs@uni-wuppertal.de
*/
program define _gresp
    version 8, missing
    syntax newvarname(generate) =/exp [if] [in], /*
	 */ Dim(varlist min=2 max=2) [BY(varlist) Mode(string) DUPlicates]
	local dim1 : word 1 of `dim'
	local dim2 : word 2 of `dim'
	tempvar touse sum1 sum2T
    quietly {
	    generate byte `touse' = 1 `if' `in'
		if `"`duplicates'"' != "" {
			sort `touse' `by' `dim'
			duplicates report `by' `dim' if `touse' == 1, fast
			if `r(N)' == `r(unique_value)' {
				display as error "Data set includes duplicates."
			    error 9
			}
		}
		sort `touse' `by' `dim1'
	    by `touse' `by' `dim1': generate `type' `sum1' = sum(`exp') if `touse' == 1
		by `touse' `by' `dim1': replace `sum1' = `sum1'[_N] if `touse' == 1
		by `touse' `by' `dim1': replace `varlist' = `exp' / `sum1' if `touse' == 1
		
		by `touse' `by': generate `type' `sum2T'  = sum(`exp') if `touse' == 1
		if ((`"`mode'"' == "aoer") | (`"`mode'"' == "AOER") | (`"`mode'"' == "ric") | (`"`mode'"' == "RIC")) {
		    by `touse' `by': replace `varlist' = `varlist' * (`sum2T'[_N] - `sum1') if `touse' == 1
		}
		else {
		    by `touse' `by': replace `varlist' = `varlist' * `sum2T'[_N] if `touse' == 1
		}
		
		sort `touse' `by' `dim2'
		by `touse' `by' `dim2': replace `sum2T' = sum(`exp') if `touse' == 1
		if ((`"`mode'"' == "ric") | (`"`mode'"' == "RIC")) {
		    by `touse' `by' `dim2': replace `varlist' = `varlist' / (`sum2T'[_N] - `exp') if `touse' == 1
		}
		else {
			by `touse' `by' `dim2': replace `varlist' = `varlist' / `sum2T'[_N] if `touse' == 1
		}
		
	    if  ((`"`mode'"' == "") | (`"`mode'"' == "ai") | (`"`mode'"' == "AI") | /*
		*/ (`"`mode'"' == "aoer") | (`"`mode'"' == "AOER") | /*
		*/ (`"`mode'"' == "ric") | (`"`mode'"' == "RIC")) {
	    }
		else if ((`"`mode'"' == "rpa") | (`"`mode'"' == "RPA")) {
		    replace `varlist' = ln(`varlist') if `touse' == 1
	    }
		else if ((`"`mode'"' == "rsi") | (`"`mode'"' == "RSI")) {
		    replace `varlist' = 1 - 2/(`varlist' + 1) if `touse' == 1
		}
		else if ((`"`mode'"' == "resp") | (`"`mode'"' == "RESP")) {
		    replace `varlist' = 100 - 200/(`varlist'^2 + 1) if `touse' == 1
		}
		else {
		    display as error "Option MODE incorrectly specified."
		    error 198
	    }
	}
end
