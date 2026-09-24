*! splitpopsurv_lf_lognormal v1.0.0  22sep2026
*! ml lf evaluator: split-population log-normal model (corrected likelihood)
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*! Called internally by splitpopsurv, distribution(lognormal). See
*! splitpopsurv.ado for the correction note and splitpopsurv.sthlp for the
*! full model.

capture program drop splitpopsurv_lf_lognormal
program define splitpopsurv_lf_lognormal
    version 17
    args lnf theta1 theta2 theta3
    tempvar p sigma lam sv pdfm mdens msv
    quietly gen double `p' = invlogit(`theta3') if $ML_y3==1
    quietly replace   `p' = 1-invlogit(`theta3') if $ML_y3==0
    quietly gen double `sigma' = exp(`theta2')
    quietly gen double `lam'   = ln($ML_y1)-`theta1'
    quietly gen double `sv'    = 1-normal(`lam'/`sigma')
    quietly gen double `pdfm'  = exp(-(`lam'^2)/(2*`sigma'^2))/(sqrt(2*_pi)*`sigma'*$ML_y1)
    quietly gen double `msv'   = (1-`p')*`sv' + `p'
    quietly gen double `mdens' = (1-`p')*`pdfm'
    quietly replace `lnf' = cond($ML_y2==1, ln(`mdens'), ln(`msv'))
end
