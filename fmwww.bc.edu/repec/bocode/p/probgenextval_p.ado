*! version 1.0.1
*! Predict Program for the Command probgenextval
*! Diallo Ibrahima Amadou
*! All comments are welcome, 30Nov2021



capture program drop probgenextval_p
program probgenextval_p
	version 16.0
	syntax anything(id="newvarname") [if] [in] [, cxi pr * ]
	if "`options'" != "" {
		ml_p `0'
		exit
	}
	if "`cxi'" != "" {
		syntax newvarname [if] [in] [, cxi ]
		_predict `typlist' `varlist' `if' `in', equation(cxi)
		label variable `varlist' "Predicted cxi"
		exit
	}
	syntax newvarname [if] [in] [, pr ]
	tempvar xbv cxiv lsev 
	quietly _predict double `xbv'  `if' `in', equation(GEV)
	quietly _predict double `cxiv'          , equation(cxi)
	local cxilca = `cxiv'[1]
	quietly generate double `lsev' = ln(exp(1 + `cxilca'*`xbv') + 1) `if' `in'	
	generate `typlist' `varlist'   = exp(-(`lsev')^(-1/`cxilca'))    `if' `in'	
	label variable `varlist' "Pr(`e(depvar)')"	

end


