*! qardl_makedata v1.0.0 - Generate example data for QARDL
*! DGP based on Cho, Kim & Shin (2015)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define qardl_makedata
    version 14.0
    
    syntax [, N(integer 1000) SEED(integer 12345)]
    
    * DGP parameters from Cho et al. (2015)
    local alpha = 1
    local phi1 = 0.25
    local rho = 0.5
    local the0 = 2
    local the1 = 3
    
    * True values
    local gamma_true = `the0' + `the1'
    local beta_true = `gamma_true' / (1 - `phi1')
    
    di as txt _n
    di as txt "{hline 60}"
    di as res "  Generating QARDL Example Data"
    di as txt "{hline 60}"
    di as txt "  DGP: y_t = alpha + phi*y_{t-1} + theta0*x_t + theta1*x_{t-1} + u_t"
    di as txt "  Parameters:"
    di as txt "    alpha   = " as res `alpha'
    di as txt "    phi     = " as res `phi1'
    di as txt "    theta_0 = " as res `the0'
    di as txt "    theta_1 = " as res `the1'
    di as txt "    rho     = " as res `rho'
    di as txt "  True long-run beta = " as res %8.4f `beta_true'
    di as txt "  n = " as res `n'
    di as txt "  seed = " as res `seed'
    di as txt "{hline 60}"
    
    set seed `seed'
    
    * Generate data
    clear
    local np1 = `n' + 1
    qui set obs `np1'
    qui gen int t = _n
    
    * Random innovations
    qui gen double e1 = rnormal()
    qui gen double e2 = rnormal()
    qui gen double u = rnormal()
    
    * Correlated innovation for x1
    qui gen double ee = `rho' * e1[_n-1] + sqrt(1 - `rho'^2) * e1 if _n > 1
    qui replace ee = e1 in 1
    
    * I(1) regressors (random walks)
    qui gen double x1 = sum(ee)
    qui gen double x2 = sum(e2)
    
    * Generate y from DGP
    qui gen double y = 0
    qui replace y = `alpha' + `phi1' * y[_n-1] + `the0' * x1 + ///
        `the1' * x1[_n-1] + `the0' * x2 + `the1' * x2[_n-1] + u if _n > 1
    
    * Drop first obs and reindex
    qui drop if _n == 1
    qui replace t = _n
    
    * Keep only needed variables
    qui keep t y x1 x2
    
    * Time set
    qui tsset t
    
    * Labels
    label variable t "Time period"
    label variable y "Dependent variable"
    label variable x1 "Independent variable 1 (I(1))"
    label variable x2 "Independent variable 2 (I(1))"
    
    * Summary
    di as txt _n
    di as res "  Data generated successfully."
    di as txt "  Variables: y x1 x2"
    di as txt "  Obs: `n'"
    di as txt "  Time variable: t"
    di as txt _n
    summarize y x1 x2, f
    
    di as txt _n
    di as txt "  To estimate QARDL:"
    di as txt `"  {cmd:. qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(2)}"'
end
