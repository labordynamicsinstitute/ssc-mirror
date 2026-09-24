*! splitpopsurv_lf_weibull v1.0.0  22sep2026
*! ml lf evaluator: split-population Weibull model (corrected likelihood)
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*! Called internally by splitpopsurv, distribution(weibull). See
*! splitpopsurv.ado for the correction note and splitpopsurv.sthlp for the
*! full model.

capture program drop splitpopsurv_lf_weibull
program define splitpopsurv_lf_weibull
    version 17
    args lnf theta1 theta2 theta3
    tempvar p sigma lam sv hzm mdens msv
    quietly gen double `p' = invlogit(`theta3') if $ML_y3==1
    quietly replace   `p' = 1-invlogit(`theta3') if $ML_y3==0
    quietly gen double `sigma' = exp(-`theta1')
    quietly gen double `lam'   = exp(`theta2')
    quietly gen double `sv'    = exp(-exp(`theta1')*($ML_y1^`lam'))
    quietly gen double `hzm'   = `lam'*($ML_y1^(`lam'-1))*exp(`theta1')
    quietly gen double `msv'   = (1-`p')*`sv' + `p'
    quietly gen double `mdens' = (1-`p')*`hzm'*`sv'
    quietly replace `lnf' = cond($ML_y2==1, ln(`mdens'), ln(`msv'))
end
