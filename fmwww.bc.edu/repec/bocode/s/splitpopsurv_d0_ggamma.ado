*! splitpopsurv_d0_ggamma v1.0.0  22sep2026
*! ml d0 evaluator: split-population generalized gamma model (corrected likelihood)
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*! Called internally by splitpopsurv, distribution(ggamma). See
*! splitpopsurv.ado for the correction note and splitpopsurv.sthlp for the
*! full model. Nests Weibull (kappa=1), log-normal (kappa=0), and gamma
*! (sigma=1) as special cases (Prentice 1974; Yamaguchi & Ferguson 1995).

capture program drop splitpopsurv_d0_ggamma
program define splitpopsurv_d0_ggamma
    version 17
    args todo b lnf
    tempvar theta1 theta2 theta3 theta4 p k s l z u pdfm cdf gam sv msv mdens
    mleval `theta1' = `b', eq(1)
    mleval `theta2' = `b', eq(2)
    mleval `theta3' = `b', eq(3)
    mleval `theta4' = `b', eq(4)
    quietly {
        gen double `p' = invlogit(`theta4') if $ML_y3==1
        replace   `p' = 1-invlogit(`theta4') if $ML_y3==0
        gen double `k' = `theta3'
        replace `k' = sign(`k')*.01 if abs(`k')<0.01
        gen double `s' = exp(`theta2')
        gen double `l' = (abs(`k'))^(-2)
        gen double `z' = sign(`k')*(ln($ML_y1)-`theta1')/`s'
        gen double `u' = `l'*exp(abs(`k')*`z')

        gen double `cdf' = 1-gammap(`l', `u')
        replace `cdf' = gammap(`l', `u') if `k'>=0.01
        replace `cdf' = normal(`z') if abs(`k')<0.01

        gen double `gam'  = exp(lngamma(`l'))
        gen double `pdfm' = ((`l'^`l')*exp(`z'*sqrt(`l')-`u'))/(`s'*$ML_y1*sqrt(`l')*`gam')
        replace `pdfm' = (exp((-(`z'^2))/2))/(`s'*$ML_y1*sqrt(2*_pi)) if abs(`k')<0.01

        gen double `sv'   = 1-`cdf'
        gen double `msv'  = (1-`p')*`sv' + `p'
        gen double `mdens' = (1-`p')*`pdfm'
        mlsum `lnf' = cond($ML_y2==1, ln(`mdens'), ln(`msv'))
        if (`todo'==0 | `lnf'>=.) exit
    }
end
