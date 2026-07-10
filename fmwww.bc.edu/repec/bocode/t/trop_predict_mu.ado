*! Predict global intercept mu from a fitted trop model

/*
    Syntax: trop_predict_mu newvar [if] [in]

    For the joint method, Y(0) = mu + alpha + beta + L, the scalar e(mu)
    is stored at estimation time.  This routine copies it into <newvar>
    for every in-sample observation.

    For the twostep method, Y(0) = alpha + beta + L contains no explicit
    intercept, so <newvar> is set to missing with a note.
*/

program define trop_predict_mu
    version 17
    syntax newvarname [if] [in]

    marksample touse, novarlist



    qui gen double `varlist' = .

    local method "`e(method)'"
    if "`method'" == "" {
        local method "twostep"
    }

    if "`method'" == "twostep" {
        // twostep decomposition has no global intercept
        di as txt "(note: mu is not identified under the twostep Algorithm 2 path; variable set to missing)"
        label variable `varlist' "Global intercept (N/A under twostep)"
    }
    else if "`method'" == "joint" {
        local mu_val = e(mu)

        if `mu_val' == . {
            di as error "e(mu) not found; joint estimation may have failed"
            exit 498
        }

        // fill in-sample observations with the estimated intercept
        qui replace `varlist' = `mu_val' if `touse'
        label variable `varlist' "Global intercept mu"
    }
    else {
        di as error "unknown estimation method: `method'"
        exit 198
    }
end
