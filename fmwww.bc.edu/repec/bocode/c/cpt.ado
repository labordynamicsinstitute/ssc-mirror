*! version 0.25 2025-01-03 Niels Henrik Bruun
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2025-11-28 v0.25 Back to basics. Removed reps and cross-validation
* 2025-01-03 v0.24 The seed option is stringent now
* 2025-01-03 v0.24 Bug in option reps fixed
* 2025-01-03 v0.24 Rewritten
* 2024-12-10 v0.24 handle values outside range in pwlin()
* 2024-12-10 v0.24 Select first of more minima in cvmax()
* 2024-03-13 v0.23 Mysterious bug fixed
* 2024-03-10 v0.22 Bug in lookup is fixed
* 2024-03-10 v0.22 Option seed added
* 2024-02-19 v0.21 Minor bug fixed
* 2024-02-16 v0.2 Returns more detailed scalar information
* 2024-02-16 v0.2 Cross-validation and repetition added
* 2023-12-16 v0.1 created


/* references
* https://www.perplexity.ai/search/what-is-the-algorithm-for-cros-Nw0aMAWOT7GAt9SAs9LMCQ?login-source=oneTapThread
* https://www.jstor.org/stable/2685844
* https://stats.stackexchange.com/questions/186337/average-roc-for-repeated-10-fold-cross-validation-with-probability-estimates
  - Look at Harrels comment
* https://intobioinformatics.wordpress.com/2018/12/25/optimism-corrected-bootstrapping-a-problematic-method/
* https://discourse.datamethods.org/t/bootstrap-vs-cross-validation-for-model-performance/2779/4
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1476201-bootstrap-for-internal-validation-how-can-we-calculate-the-testing-performance-the-performance-of-bootstrapmodel-in-the-original-sample
* https://scikit-learn.org/1.5/auto_examples/model_selection/plot_roc_crossval.html
* https://scikit-learn.org/1.5/auto_examples/model_selection/plot_roc.html#sphx-glr-auto-examples-model-selection-plot-roc-py
* "H:\Documents\nhb\STATA\Research\Prediction modelling\bad roc data.dta"
*/

*mata mata clear
*capture program drop cpt
program define cpt, rclass
	version 15.1

	syntax varlist(min=2 fv) [if],   ///
    [                              ///
		Format(string)               ///
		ROwname(string)              ///
		Replace                      ///
		BAmber                       ///
		Hanley                       ///
		BInomial                     ///
		noQuietly				     ///
		GRaph                        ///
		*	                         /// /*Twoway graph options*/
    ]
		
	if "`quietly'" == "" local QUIETLY quietly
  *tokenize `"`varlist'"'
	gettoken 1 2 : varlist

	*mata: lookup = J(0, 2, .)
	qui su `1' `if', mean
	local prev = r(mean)
	if "`format'" == "" local format "%9.3f"
	
	tempname pr
	`QUIETLY' logit `1' `2'
	`QUIETLY' predict double `pr', pr
	
	* This roctab call adds one empty row
	`QUIETLY' roctab `1' `pr', detail `binomial' `bamber' `hanley'
	scalar auc = r(area)
	local auc = "AUC(%) = `=string((r(area))*100, "%6.1f")' [`=string((r(lb))*100, "%6.1f")'; `=string((r(ub))*100, "%6.1f")']"

	mata: cpt = select((cpt=tokens("`r(cutpoints)'")'), regexm(cpt, "[0-9]$"))
	mata: cpt = strtoreal(cpt)
	matrix _auc = r(N), r(area), r(se), r(lb), r(ub)
	local lbl1 = abbrev("`:var l `1''", 32)
	if "`lbl1'" == "" local lbl1 `1'
	
	matrix roweq _auc = "`lbl1'"
	local lbl2 = abbrev("p_`1'", 28)
	if "`rowname'" != "" local lbl2 = abbrev("`rowname'", 28)
	matrix rownames _auc = "`lbl2'"
	matrix colnames _auc = N AUC se [`r(level)'% CI]

	mata: _roc = roc(cpt, `prev', "`format'")[., (2,3)]
	mata: _roc[.,2] = 1 :- _roc[.,2]
	mata: st_matrix("_", _roc)
	matrix colnames _ = tpr_`lbl2' fpr_`lbl2'
	if "`replace'" != "" {
		capture drop `lbl2' 
		capture drop tpr_`lbl2' 
		capture drop fpr_`lbl2'
	}
	qui generate `lbl2' = `pr'
	label variable `lbl2' "P(`lbl1')"
	svmat _, names(col)
	label variable tpr_`lbl2' "True positive rate (sensitivity)"
	label variable fpr_`lbl2' "False positive rate (1-specificity)"
	format `lbl2' fpr_`lbl2' tpr_`lbl2' %5.2f

	if ( `"`options'"' != "" | "`graph'" != "" ) {
		_get_gropts , graphopts(`options') gettwoway
		local gr_cmd = `"twoway"' + ///
			`"(line tpr_`lbl2' fpr_`lbl2', connect(direct) lcolor(plb1) msymbol(i) lpattern(solid))"' + /// 
			`"(function y = x)"' + ///
			`", xtitle("False positive rate (1-specificity)")"' + ///
			`"ytitle("True positive rate (sensitivity)")"' + ///
			`"xlabel(0 "0" .25 "25" .5 "50" .75 "75" 1 "100", labsize(small))"' + ///
			`"ylabel(0 "0" .25 "25" .5 "50" .75 "75" 1 "100", labsize(small))"' + ///
			`"legend(off) aspectratio(1) note("`auc'", size(small)) `s(twowayopts)'"'  
		`gr_cmd'
		return local graph_cmd `"`gr_cmd'"'
	}
	return scalar aucvalue = auc
	return local auctext = "`auc'"
	return matrix auc = _auc
	return matrix cutpt = cutpt
	return matrix roc = roc
	di "`auc'"

	if youden_index < . return scalar Youden_p = `lbl2'[youden_index]
	if liu_index < . return scalar Liu_p = `lbl2'[liu_index]
	*scalar list

	* the empty row from the roctab above is removed
	qui egen _drp = rowmin(*)
	qui drop if mi(_drp)
	qui drop _drp
end
********************************************************************************
mata:
  real colvector cvmax(real colvector v) {
		real colvector mx
		real scalar index 
		
		mx = max(v)
		index = select((1::rows(v)), v :== mx) 
		return(index)
	} 

  real matrix roc(colvector cpt, real scalar prev, string scalar fmt) {
		// formulas from 2017 Unal - Defining an Optimal Cut-Point Value in ROC Analysis; An Alternative Approach
    real scalar R
    real matrix roc
    string colvector rnms 
		real colvector liu, youden, cutindex
    roc = cpt, st_matrix("r(detail)")[., 2..6]
    st_rclear()
    R = rows(roc)
    roc[R, 1] = roc[R-1,1]
    roc[., 2..4] = roc[., 2..4] / 100
		ppv = (prev :* roc[.,2]) :/ (prev :* roc[.,2] :+ (1 - prev) :* (1 :- roc[.,3]))
		npv = ((1 - prev) :* roc[.,3]) :/ (prev * (1 :- roc[.,2]) :+ (1 - prev) :* roc[.,3])
		roc = roc[.,1..3], ppv, npv, roc[.,4..6]
    roc = roc, (roc[., 2] + roc[., 3]) :* 0.5
    st_matrix("roc", roc[.,2..9])
    st_matrixcolstripe("roc", (J(8,1,""), tokens("sensitivity specificity PPV NPV accuracy lr+ lr- AUC")'))
    rnms = ":>=" :+ strofreal(roc[.,1], fmt)
    youden = cvmax(roc[.,2] :+ roc[., 3] :- 1)
		st_numscalar("youden_index", rows(youden) == 1 ? youden[1] : .)
    rnms[youden] = rnms[youden] :+ " J"
    liu = cvmax(roc[.,2] :* roc[., 3])
		st_numscalar("liu_index", rows(liu) == 1 ? liu[1] : .)
    rnms[liu] = rnms[liu] :+ " L"
    st_matrixrowstripe("roc", (J(R,1,""), rnms))
		cutindex = uniqrows(youden \ liu)
    st_matrix("cutpt", roc[cutindex,2..9])    
    st_matrixcolstripe("cutpt", (J(8,1,""), tokens("sensitivity specificity PPV NPV accuracy lr+ lr- AUC")'))
    st_matrixrowstripe("cutpt", (J(rows(cutindex),1,""), rnms[cutindex]))
    return(roc)
  }
end
