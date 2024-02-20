*! version 0.21 2023-12-16 Niels Henrik Bruun
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2024-02-19 v0.21 Minor bug fixed
*! 2024-02-16 v0.2 Returns more detailed scalar information
*! 2024-02-16 v0.2 Cross-validation and repetition added
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
      cv(integer 0)                ///
      reps(integer 1)              ///
      GRaph                        ///
      *	                           /// /*Twoway graph options*/
    ]
  tokenize `"`varlist'"'
	qui su `1' `if', mean
	local prev = r(mean)
  if "`format'" == "" local format "%9.3f"
	tempvar pr k
	if !`cv' {
		qui logit `varlist' `if'
		qui predict `pr' if e(sample), pr
	}
	else {
		if `cv' < 2 mata: _error("CV must be an integer greater than or equal to 2")
		cvpredict `k' `pr' `if', regression(logit `varlist') cv(`cv') reps(`reps')
	}
	
	if wordcount(`"`varlist'"') == 2 mata: m = uniqrows(st_data(., ("`pr'", "`2'")))
	else mata: m = J(0, 2, .)
  qui roctab `1' `pr', detail `binomial' `bamber' `hanley'
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
	qui generate `lbl2' = `pr' if e(sample)
	label variable `lbl2' "P(`lbl1')"
	notes `lbl2': cv(`cv'), reps(`reps'), regression: logit `varlist' `if' 
  svmat _, names(col)
  label variable tpr_`lbl2' "True positive rate (sensitivity)"
  label variable fpr_`lbl2' "False positive rate (1-specificity)"
  format `lbl2' fpr_`lbl2' tpr_`lbl2' %5.2f

	if regexm("`2'", "\.(.+)$") local vn = regexs(1)
	else local vn `2'
	local lbl3 `: var l `vn''
	if "`lbl3'" == "" local lbl3 `2'
	qui logit `varlist'
  mata: st_numscalar("youden_v", pwlin(m, st_numscalar("youden_p")))
	if youden_v < . {
		local youden_text Youden: `lbl3' `=cond(_b[`2'] > 0, ">=", "<=")' `=string(youden_v, "`format'")'
		return scalar Youden_v = youden_v
		return local Youden_text = "`youden_text'"
	}
  mata: st_numscalar("liu_v", pwlin(m, st_numscalar("liu_p")))
	if liu_v < . {
		local liu_text Liu: `lbl3' `=cond(_b[`2'] > 0, ">=", "<=")' `=string(liu_v, "`format'")'
		return scalar Liu_v = liu_v
		return local Liu_text = "`liu_text'"
	}

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
  return scalar Youden_p = youden_p
  return scalar Liu_p = liu_p
  return matrix auc = _auc
  return matrix cutpt = cutpt
  return matrix roc = roc
  return local auctext = "`auc'"
  di "`auc'"
end 

program define cvpredict
    syntax newvarlist(min=2 max=2) [if/], Regression(string) ///
			[noQuietly cv(integer 10) reps(integer 1)]
    if "`quietly'" == "" local QUIETLY quietly
		if "`if'" != "" local if  & `if'
    tokenize `"`varlist'"'
    `QUIETLY' generate `1' = runiformint(1, `cv')
			tempname repsum
		forvalues rep = 1/`reps' {
			local lstcv
			forvalues r=1/`cv'{
					tempname xb xbr prdct`r' repval
					local lstcv `lstcv' , `prdct`r''
					`QUIETLY' `regression' if `1' != `r' `if'
					`QUIETLY' predict `prdct`r'' if `1' == `r', pr
			}
			`QUIETLY' generate `repval' = min(`lstcv') // cv-1 missing values and one non-missing
			`QUIETLY' drop `=subinstr("`lstcv'", ",", "", .)'
			`QUIETLY' if `rep' == 1 generate `repsum' = `repval'
			`QUIETLY' else replace `repsum' = `repsum' + `repval'
		}
		`QUIETLY' generate `2' = `repsum' / `reps'
end

mata:
	real scalar pwlin(real matrix m, real scalar val)
	{
		real scalar R, r
		
		if ( m != J(0, 2, .)) {
			R = rows(m)
			if ( cols(m) == 2 ) m = m \ (.,.)
			else _error("Only a two-column matrix is allowed")
			for(r=1; r<=R; r++) if( m[r,1] <= val & m[r+1,1] > val) break
			lp = m[r..(r+1), .]
			return((lp[2,2] - lp[1,2]) / (lp[2,1] - lp[1,1]) * (val - lp[1,1]) + lp[1,2])
		} else return(.)
	}


  real scalar cvmax(real colvector v) return(select((1::rows(v)), v :== max(v)))

  real matrix roc(colvector cpt, real scalar prev, string scalar fmt) {
		// formulas from 2017 Unal - Defining an Optimal Cut-Point Value in ROC Analysis; An Alternative Approach
    real scalar R, liu, youden
    real matrix roc
    string colvector rnms

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
		st_numscalar("youden_p", roc[youden, 1])
    rnms[youden] = rnms[youden] + " J"
    liu = cvmax(roc[.,2] :* roc[., 3])
		st_numscalar("liu_p", roc[liu, 1])
    rnms[liu] = rnms[liu] + " L"
    st_matrixrowstripe("roc", (J(R,1,""), rnms))
    st_matrix("cutpt", roc[(youden,liu),2..9])    
    st_matrixcolstripe("cutpt", (J(8,1,""), tokens("sensitivity specificity PPV NPV accuracy lr+ lr- AUC")'))
    rnms = tokens("Youden Liu")' :+ "(" :+ strofreal(roc[(youden,liu), 1], fmt) :+ ")"
    st_matrixrowstripe("cutpt", (J(2,1,""), rnms))
    return(roc)
  }
end
