*! mvardlurt_multivariate_diag - Diagnostic tests
*! Version 1.0.0 - 2026-09-09

capture program drop mvardlurt_multivariate_diag
program define mvardlurt_multivariate_diag
    version 14
    
    di as txt ""
    di as txt "{hline 80}"
    di as res _col(3) "Diagnostic Tests"
    di as txt "{hline 80}"
    
    * Serial correlation (Breusch-Godfrey)
    qui estat bgodfrey, lags(1 2 3)
    di as txt _col(3) "Breusch-Godfrey LM test for serial correlation:"
    di as txt _col(15) "Chi2(1): " as res %8.4f r(lm1) " (p=" %6.4f r(p1) ")"
    di as txt _col(15) "Chi2(2): " as res %8.4f r(lm2) " (p=" %6.4f r(p2) ")"
    di as txt _col(15) "Chi2(3): " as res %8.4f r(lm3) " (p=" %6.4f r(p3) ")"
    
    * Heteroskedasticity
    qui estat hettest
    di as txt _col(3) "Breusch-Pagan test for heteroskedasticity:"
    di as txt _col(15) "Chi2: " as res %8.4f r(chi2) " (p=" %6.4f r(p) ")"
    
    * Normality (Jarque-Bera)
    qui predict residuals, resid
    qui sktest residuals
    di as txt _col(3) "Jarque-Bera test for normality:"
    di as txt _col(15) "Chi2: " as res %8.4f r(chi2) " (p=" %6.4f r(p) ")"
    
    * Functional form (Ramsey RESET)
    qui estat ovtest
    di as txt _col(3) "Ramsey RESET test for functional form:"
    di as txt _col(15) "F: " as res %8.4f r(F) " (p=" %6.4f r(p) ")"
    
    di as txt "{hline 80}"
    di as txt ""
end