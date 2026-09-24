*! splitpopsurv_lf_loglogistic v1.0.0  22sep2026
*! ml lf evaluator: split-population log-logistic model (corrected likelihood)
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*! Called internally by splitpopsurv, distribution(loglogistic). See
*! splitpopsurv.ado for the correction note and splitpopsurv.sthlp for the
*! full model.

capture program drop splitpopsurv_lf_loglogistic
program define splitpopsurv_lf_loglogistic
    version 17
    args lnf theta1 theta2 theta3
    tempvar p lam sigma sv hzm mdens msv
    quietly gen double `p' = invlogit(`theta3') if $ML_y3==1
    quietly replace   `p' = 1-invlogit(`theta3') if $ML_y3==0
    quietly gen double `lam'   = exp(-`theta1')
    quietly gen double `sigma' = 1/`theta2'
    quietly gen double `sv'    = 1/(1+(`lam'*$ML_y1)^(`sigma'))
    quietly gen double `hzm'   = (`lam'*`sigma'*((`lam'*$ML_y1)^(`sigma'-1)))/(1+(`lam'*$ML_y1)^(`sigma'))
    quietly gen double `msv'   = (1-`p')*`sv' + `p'
    quietly gen double `mdens' = (1-`p')*`hzm'*`sv'
    quietly replace `lnf' = cond($ML_y2==1, ln(`mdens'), ln(`msv'))
end
