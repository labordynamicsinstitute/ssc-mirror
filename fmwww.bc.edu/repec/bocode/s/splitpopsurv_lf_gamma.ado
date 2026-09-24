*! splitpopsurv_lf_gamma v1.0.0  22sep2026
*! ml lf evaluator: split-population gamma model (corrected likelihood)
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*! Called internally by splitpopsurv, distribution(gamma). See
*! splitpopsurv.ado for the correction note and splitpopsurv.sthlp for the
*! full model. Note: theta1 (H_regression) is used directly as a rate here
*! (no exp() transform) and must stay positive; splitpopsurv supplies a
*! safe positive starting value for it automatically.

capture program drop splitpopsurv_lf_gamma
program define splitpopsurv_lf_gamma
    version 17
    args lnf theta1 theta2 theta3
    tempvar p l k gam pdfm sv mdens msv
    quietly gen double `p' = invlogit(`theta3') if $ML_y3==1
    quietly replace   `p' = 1-invlogit(`theta3') if $ML_y3==0
    quietly gen double `l' = `theta1'*$ML_y1
    quietly gen double `k' = `theta2'
    quietly gen double `gam'  = exp(lngamma(`k'))
    quietly gen double `pdfm' = (`theta1'*((`l')^(`k'-1))*exp(-`l'))/`gam'
    quietly gen double `sv'   = 1-gammap(`k', `l')
    quietly gen double `msv'  = (1-`p')*`sv' + `p'
    quietly gen double `mdens' = (1-`p')*`pdfm'
    quietly replace `lnf' = cond($ML_y2==1, ln(`mdens'), ln(`msv'))
end
