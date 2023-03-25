*version 2.0 January 2021
*Add option to allow different polynomial orders and bandwidths on two sides of the threshold
*Following the update of rdrobust, changed to a more stable method for inverting matrices

*version 2.1 July 2022
*Fixed minor bug that returns an error message when kernel is specified as "triangular"

*version 2.2 December 2022
*Fixed bug when subsetting syntax ("if" or "in") is used in the command

*version 2.3 March 2023
*Updated Stata version number
*Per Kit Baum's suggestion, changed program from eclass to rclass
*These changes do not affect any calculation

set type double
capture program drop rdmse
program define rdmse, rclass
	version 15.0
	syntax anything [if] [in] [, c(real 0) fuzzy(string) deriv(real 0) p(real 1) h(real 0) b(real 0) kernel(string) scalepar(real 1) ///
	twosided pl(real 1) pr(real 1) hl(real 0) hr(real 0) bl(real 0) br(real 0)]
	
	marksample marked

	tokenize "`anything'"
	local y `1'
	local x `2'
	
	if ("`twosided'"=="") {
		if ("`fuzzy'"=="") rdmses `y' `x' if `marked', c(`c') deriv(`deriv') p(`p') h(`h') b(`b') kernel(`kernel') scalepar(`scalepar')
		else rdmsef `y' `x' if `marked', c(`c') fuzzy(`fuzzy') deriv(`deriv') p(`p') h(`h') b(`b') kernel(`kernel') scalepar(`scalepar')
							}
							
	else {
		if ("`fuzzy'"=="") rdmses2s `y' `x' if `marked', c(`c') deriv(`deriv') pl(`pl') pr(`pr') hl(`hl') hr(`hr') bl(`bl') br(`br') kernel(`kernel') scalepar(`scalepar')
		else {
			di "The {cmd:fuzzy()} option is not allowed with {cmd:twosided}. See help file for details."
			}
		}							
end
