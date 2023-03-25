*version 1.1 June 2018

*version 1.2 July 2022
*Fixed minor bug that returns an error message when kernel is specified as "triangular"

*version 1.3 March 2023
*Updated Stata version number
*Fixed bug when subsetting syntax ("if" or "in") is used in the command
*Per Kit Baum's suggestion, changed program from eclass to rclass

capture program drop rdmse_cct2014
program define rdmse_cct2014, rclass
	version 15.0
	syntax anything [if] [in] [, c(real 0) fuzzy(string) deriv(real 0) p(real 1) h(real 0) b(real 0) kernel(string) scalepar(real 1)]
	
	marksample marked	

	tokenize "`anything'"
	local y `1'
	local x `2'
	
	if ("`fuzzy'"=="") rdmses_cct2014 `y' `x' if `marked', c(`c') deriv(`deriv') p(`p') h(`h') b(`b') kernel(`kernel') scalepar(`scalepar')
	else rdmsef_cct2014 `y' `x' if `marked', c(`c') fuzzy(`fuzzy') deriv(`deriv') p(`p') h(`h') b(`b') kernel(`kernel') scalepar(`scalepar')

end


