*! version 0.1 2023-12-16 Niels Henrik Bruun
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2023-12-16 v0.1   created

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
      GRaph                        ///
      *	                           /// /*Twoway graph options*/
    ]
  tokenize `"`varlist'"'
	qui su `1' `if', mean
	local prev = r(mean)
  if "`format'" == "" local format "%9.3f"
  qui logit `varlist' `if'
  tempvar pr
  qui predict `pr' if e(sample), pr
  qui roctab `1' `pr', detail `binomial' `bamber' `hanley'
  local auc = "AUC(%) = `=string((r(area))*100, "%6.1f")' [`=string((r(lb))*100, "%6.1f")'; `=string((r(ub))*100, "%6.1f")']"
  matrix _auc = r(N), r(area), r(se), r(lb), r(ub)
  local lbl1 = abbrev("`:var l `1''", 32)
  if "`lbl1'" == "" local lbl1 `1'
  matrix roweq _auc = "`lbl1'"
  tempname v2
  if wordcount(`"`varlist'"') == 2 {
    local lbl2 = abbrev("`2'", 28)
    generate `v2' = `2' if e(sample)
  }
  else {
    local lbl2 = abbrev("p_`1'", 28)
    if "`rowname'" != "" local lbl2 = abbrev("`rowname'", 28)
    generate `v2' = `pr' if e(sample)
  }
  matrix rownames _auc = "`lbl2'"
  matrix colnames _auc = N AUC se [`r(level)'% CI]
  mata: _roc = roc("`v2'", `prev', "`format'" )[., (2,3)]
  mata: _roc[.,2] = 1 :- _roc[.,2]
  mata: st_matrix("_", _roc)
  if "`replace'" != "" capture drop tpr_`lbl2' fpr_`lbl2'
  matrix colnames _ = tpr_`lbl2' fpr_`lbl2'
  svmat _, names(col)
  label variable tpr_`lbl2' "True positive rate (sensitivity)"
  label variable fpr_`lbl2' "False positive rate (1-specificity)"
  format fpr_`lbl2' tpr_`lbl2' %5.2f

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
  
  return matrix auc = _auc
  return matrix cutpt = cutpt
  return matrix roc = roc
  return local auctext = "`auc'"
  di "`auc'"
end 

mata:
  real scalar cvmax(real colvector v) return(select((1::rows(v)), v :== max(v)))

  real matrix roc(string scalar vn, real scalar prev, string scalar fmt) {
    real scalar R, liu, youden
    real matrix roc
    string colvector rnms

    roc = uniqrows(st_data(., vn) \ .), st_matrix("r(detail)")[., 2..6]
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
    rnms[youden] = rnms[youden] + " J"
    liu = cvmax(roc[.,2] :* roc[., 3])
    rnms[liu] = rnms[liu] + " L"
    st_matrixrowstripe("roc", (J(R,1,""), rnms))
    st_matrix("cutpt", roc[(youden,liu),2..9])    
    st_matrixcolstripe("cutpt", (J(8,1,""), tokens("sensitivity specificity PPV NPV accuracy lr+ lr- AUC")'))
    rnms = tokens("Youden Liu")' :+ "(" :+ strofreal(roc[(youden,liu), 1], fmt) :+ ")"
    st_matrixrowstripe("cutpt", (J(2,1,""), rnms))
    return(roc)
  }
end
