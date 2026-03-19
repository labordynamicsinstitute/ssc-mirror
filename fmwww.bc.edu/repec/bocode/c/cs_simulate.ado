*! cs_simulate.ado  v1.0.0  2026-03-17
*! Simulate nonlinear dose-response data for causalspline
*!
*! Syntax:
*!   cs_simulate n, dgp(threshold|diminishing|nonmonotone|linear|sinusoidal)
*!               [confounding(#) seed(#) clear]
*!
*! Creates variables: Y T X1 X2 X3 true_effect

program define cs_simulate
    version 14.0

    syntax anything(name=nobs) ,    ///
        DGP(string)                 ///
        [ Confounding(real 0.5)     ///
          Seed(integer 42)          ///
          clear                     ///
        ]

    // -- Validate -------------------------------------------------------------
    confirm integer number `nobs'
    if `nobs' < 10 {
        di as error "n must be >= 10"
        exit 198
    }
    if !inlist("`dgp'", "threshold", "diminishing", "nonmonotone", ///
               "linear", "sinusoidal") {
        di as error "dgp() must be: threshold diminishing nonmonotone " ///
            "linear sinusoidal"
        exit 198
    }
    if "`clear'" != "" qui drop _all

    // -- Check that dataset is empty or clear was specified --------------------
    qui count
    if r(N) > 0 & "`clear'" == "" {
        di as error "Dataset not empty. Use clear option to replace."
        exit 4
    }

    // -- Simulate --------------------------------------------------------------
    set seed `seed'
    qui set obs `nobs'

    // Covariates
    qui gen double X1 = rnormal(0, 1)
    qui gen double X2 = rnormal(0, 1)
    qui gen double X3 = rbinomial(1, 0.5)

    // Treatment: confounded by X1, X2, X3
    qui gen double T = 5 + `confounding' * (0.5*X1 - 0.3*X2 + 0.2*X3) ///
                       + rnormal(0, 1)

    // True causal effect by DGP
    qui gen double true_effect = .

    if "`dgp'" == "threshold" {
        local c = 3
        qui replace true_effect = 0            if T < `c'
        qui replace true_effect = 2 * (T - `c') if T >= `c'
    }
    else if "`dgp'" == "diminishing" {
        qui replace true_effect = 2*T - 0.15*T^2
    }
    else if "`dgp'" == "nonmonotone" {
        qui replace true_effect = 5 * sin(T - 3)
    }
    else if "`dgp'" == "linear" {
        qui replace true_effect = 2 * T
    }
    else if "`dgp'" == "sinusoidal" {
        qui replace true_effect = 3 * sin(1.5 * T)
    }

    // Outcome: true effect + confounding + noise
    qui gen double Y = true_effect                          ///
                     + `confounding' * (0.3*X1 - 0.2*X2)  ///
                     + rnormal(0, 1)

    // Labels
    label var Y           "Outcome"
    label var T           "Continuous treatment"
    label var X1          "Covariate 1 (confounder)"
    label var X2          "Covariate 2 (confounder)"
    label var X3          "Covariate 3 (binary confounder)"
    label var true_effect "True causal effect mu(T)"

    // -- Summary ---------------------------------------------------------------
    di as text _n "Simulated dataset: DGP = " as result "`dgp'" ///
        as text "  n = " as result `nobs' ///
        as text "  seed = " as result `seed'
    di as text "Variables: Y T X1 X2 X3 true_effect"
    qui sum T
    di as text "Treatment: mean = " %6.3f r(mean) ///
        "  sd = " %6.3f r(sd) ///
        "  range = [" %6.3f r(min) ", " %6.3f r(max) "]"

end
