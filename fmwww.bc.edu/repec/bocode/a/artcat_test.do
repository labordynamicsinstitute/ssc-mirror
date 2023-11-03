/*
MAIN TESTING FILE FOR ARTCAT
artcat_test.do
IRW and EMZ, 1jun2022
*/

local path c:\ian\git\artcat // CHANGE TO YOUR FILE LOCATION

adopath ++ `path'/package
adopath ++ `path'/moreado
cd `path'/package
cap log close
set more off
set linesize 79
version 14

foreach type in float double {

set type `type'


// 1. We compared results with those given by \citet{Whitehead93}. Exact agreement was achieved.

log using artcat_compare_with_Whitehead_`type', replace text
do artcat_compare_with_Whitehead
log close



// 2. We compared results for a binary outcome in a superiority trial with those given by \texttt{artbin} and \texttt{power} across a range of probabilities and allocation ratios. Close, but not exact, agreement was achieved, except in a few well understood cases.

log using artcat_compare_with_artbin_`type', replace text
do artcat_compare_with_artbin, nostop
log close

log using artcat_compare_with_power_`type', replace text
do artcat_compare_with_power, nostop
log close



// 3. We checked error messages in a number of impossible cases, for example negative odds ratio.

log using artcat_check_errormsgs_`type', replace text
do artcat_check_errormsgs, nostop
log close



// 4. We compared results with those given by the R package dani \citep{Quartagno2019b}. This calculates sample sizes for a binary outcome on the odds ratio scale for non-inferiority trials and implicitly uses the AA method. Exact agreement was achieved for the AA method.

log using artcat_compare_with_dani_`type', replace text
do artcat_compare_with_dani
log close

}



// 5. We re-ran the test script, implementing the above tests, in Stata versions 13 and 16, and with the default variable type (\texttt{set type}) as \texttt{float} and as \texttt{double}.



/* 6. We did various tests of internal consistency of the program.
	We compared different ways of stating the same problem (e.g. interchanging C and E arms, and reversing the order of the categories) and verified the same answer was achieved.
	We calculated the power $p$ for a sample size $n$, then calculated the sample size for power $p$, and checked that this equalled the original $n$.
	We changed options that should change the sample size and verified that they did change the sample size.
NB this is done outside the type loop as one of its test involves changing type
*/

log using artcat_test_consistency, replace text
do artcat_test_consistency
log close



// 7. The simulations reported in Section \ref{sec:sim} also test the software.



/* 
NB Why we didn't test against other programs:
	ssi and niss: these for non-inferiority or equivalence designs, which are not comparable to artcat (do not use same null hypotheses)
	sampsi: this is no longer a part of Stata (since v13)
*/



/*** END OF MAIN TESTING PROGRAM FOR ARTCAT ***/
