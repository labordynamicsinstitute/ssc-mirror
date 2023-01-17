*! version 1.0.0  26jul2022  Ben Jann
*  helper program used by riflogit and riflogit_p to generate the RIF

program riflogit_RIF
    version 11
    args Y RIF touse wgt
    sum `Y' if `touse' `wgt', meanonly
    if r(N)==0 {
        error 2000
    }
    if r(min)==r(max) {
        di as err "outcome does not vary"
        di as err "remember:                           0 = negative outcome"
        di as err "          all other nonmissing values = positive outcome"
        exit 2000
    }
    qui gen double `RIF' = (`Y' - r(mean)) / (r(mean)*(1-r(mean))) ///
        + logit(r(mean))
end

