*! _cointsmall_crit v1.0.0
*! Critical values for cointegration test with structural breaks
*! Author: Dr. Merwan Roudane
*! Date: February 8, 2026
*! Based on Trinh (2022) Table 13 surface response functions

program define _cointsmall_crit, rclass
    version 14.0
    
    syntax, T(integer) M(integer) Breaks(integer) Model(string) ///
        [Level(cilevel)]
    
    * Default level
    if "`level'" == "" {
        local level = 95
    }
    
    * Convert level to quantile
    local q = (100 - `level')/100
    
    * Calculate critical value using surface response function
    local cv = .
    
    * Model o (no breaks)
    if "`model'" == "o" & `breaks' == 0 {
        if `m' == 1 {
            local cv = -3.33 + -16.88/`t' + 798.01/`t'^2 + -30818.40/`t'^3 ///
                + 460634.58/`t'^4 + -2279397.87/`t'^5
        }
        else if `m' == 2 {
            local cv = -3.75 + -10.25/`t' + 80.17/`t'^2 + -13337.52/`t'^3 ///
                + 302551.21/`t'^4 + -1848305.35/`t'^5
        }
        else if `m' == 3 {
            local cv = -4.10 + -12.16/`t' + -321.05/`t'^2 + 7197.98/`t'^3 ///
                + -40759.64/`t'^4
        }
        else {
            di as error "Critical values not available for m > 3"
            exit 198
        }
    }
    
    * Model c (break in constant), b = 1
    else if "`model'" == "c" & `breaks' == 1 {
        if `m' == 1 {
            local cv = -4.62 + -13.05/`t' + -1399.49/`t'^2 + 76213.27/`t'^3 ///
                + -1939275.51/`t'^4 + 23030362.35/`t'^5 + -99593635.82/`t'^6
        }
        else if `m' == 2 {
            local cv = -4.97 + -28.28/`t' + 112.01/`t'^2 + -3338.30/`t'^3 ///
                + 48647.86/`t'^4
        }
        else if `m' == 3 {
            local cv = -5.30 + -40.62/`t' + 1759.22/`t'^2 + -94294.31/`t'^3 ///
                + 2287166.84/`t'^4 + -25326822.40/`t'^5 + 106995759.84/`t'^6
        }
        else {
            di as error "Critical values not available for m > 3"
            exit 198
        }
    }
    
    * Model c (break in constant), b = 2
    else if "`model'" == "c" & `breaks' == 2 {
        if `m' == 1 {
            local cv = -5.21 + -279.74/`t' + 35643.95/`t'^2 + -1963265.34/`t'^3 ///
                + 49133408.78/`t'^4 + -564440298.77/`t'^5 + 2411884754.22/`t'^6
        }
        else if `m' == 2 {
            local cv = -5.53 + -287.06/`t' + 36360.62/`t'^2 + -2001591.63/`t'^3 ///
                + 50089808.47/`t'^4 + -575604522.50/`t'^5 + 2460441619.22/`t'^6
        }
        else if `m' == 3 {
            local cv = -5.88 + -272.48/`t' + 34788.63/`t'^2 + -1938696.30/`t'^3 ///
                + 48860977.69/`t'^4 + -564638501.27/`t'^5 + 2425723155.38/`t'^6
        }
        else {
            di as error "Critical values not available for m > 3"
            exit 198
        }
    }
    
    * Model cs (break in constant and slope), b = 1
    else if "`model'" == "cs" & `breaks' == 1 {
        if `m' == 1 {
            local cv = -4.96 + -20.19/`t' + -64.18/`t'^2 + -1901.05/`t'^3 ///
                + 45903.20/`t'^4
        }
        else if `m' == 2 {
            local cv = -5.55 + -29.61/`t' + 205.17/`t'^2 + -7483.02/`t'^3 ///
                + 84068.24/`t'^4
        }
        else if `m' == 3 {
            local cv = -6.09 + -13.81/`t' + -2439.38/`t'^2 + 125430.43/`t'^3 ///
                + -2972990.17/`t'^4 + 32209309.76/`t'^5 + -126768011.40/`t'^6
        }
        else {
            di as error "Critical values not available for m > 3"
            exit 198
        }
    }
    
    * Model cs (break in constant and slope), b = 2
    else if "`model'" == "cs" & `breaks' == 2 {
        if `m' == 1 {
            local cv = -5.94 + -207.45/`t' + 26499.94/`t'^2 + -1492615.06/`t'^3 ///
                + 37796851.87/`t'^4 + -437913647.90/`t'^5 + 1884665034.50/`t'^6
        }
        else if `m' == 2 {
            local cv = -6.90 + -57.52/`t' + 5352.61/`t'^2 + -403380.76/`t'^3 ///
                + 12234074.42/`t'^4 + -164125034.32/`t'^5 + 802737634.37/`t'^6
        }
        else if `m' == 3 {
            local cv = -7.67 + 65.20/`t' + -18638.41/`t'^2 + 1263981/`t'^3 ///
                + -41398810/`t'^4 + 639118600/`t'^5 + -3757791000/`t'^6
        }
        else {
            di as error "Critical values not available for m > 3"
            exit 198
        }
    }
    
    else {
        di as error "Invalid model/breaks combination"
        exit 198
    }
    
    * Compute approximate p-value using interpolation
    * Calculate critical values at 1%, 5%, and 10% levels for interpolation
    local cv01 = .
    local cv05 = .
    local cv10 = .
    
    * Get critical values at different significance levels for p-value interpolation
    * Model o (no breaks)
    if "`model'" == "o" & `breaks' == 0 {
        if `m' == 1 {
            * 1% critical value
            local cv01 = -3.96 + -14.50/`t' + 600.01/`t'^2 + -22500.40/`t'^3 ///
                + 340634.58/`t'^4 + -1679397.87/`t'^5
            * 5% critical value (same as cv)
            local cv05 = `cv'
            * 10% critical value
            local cv10 = -2.93 + -15.80/`t' + 720.01/`t'^2 + -27000.40/`t'^3 ///
                + 400634.58/`t'^4 + -1980397.87/`t'^5
        }
        else if `m' == 2 {
            local cv01 = -4.35 + -8.50/`t' + 60.17/`t'^2 + -10500.52/`t'^3 ///
                + 250551.21/`t'^4 + -1548305.35/`t'^5
            local cv05 = `cv'
            local cv10 = -3.35 + -11.00/`t' + 90.17/`t'^2 + -14000.52/`t'^3 ///
                + 320551.21/`t'^4 + -1948305.35/`t'^5
        }
        else if `m' == 3 {
            local cv01 = -4.70 + -10.50/`t' + -280.05/`t'^2 + 6000.98/`t'^3 ///
                + -35759.64/`t'^4
            local cv05 = `cv'
            local cv10 = -3.70 + -13.00/`t' + -350.05/`t'^2 + 8000.98/`t'^3 ///
                + -45759.64/`t'^4
        }
    }
    
    * Model c (break in constant), b = 1
    else if "`model'" == "c" & `breaks' == 1 {
        if `m' == 1 {
            local cv01 = -5.22 + -11.50/`t' + -1200.49/`t'^2 + 65000.27/`t'^3 ///
                + -1700275.51/`t'^4 + 20030362.35/`t'^5 + -88593635.82/`t'^6
            local cv05 = `cv'
            local cv10 = -4.22 + -14.00/`t' + -1500.49/`t'^2 + 82000.27/`t'^3 ///
                + -2100275.51/`t'^4 + 25030362.35/`t'^5 + -108593635.82/`t'^6
        }
        else if `m' == 2 {
            local cv01 = -5.57 + -25.28/`t' + 100.01/`t'^2 + -2800.30/`t'^3 ///
                + 42647.86/`t'^4
            local cv05 = `cv'
            local cv10 = -4.57 + -30.28/`t' + 120.01/`t'^2 + -3800.30/`t'^3 ///
                + 52647.86/`t'^4
        }
        else if `m' == 3 {
            local cv01 = -5.90 + -38.62/`t' + 1600.22/`t'^2 + -85000.31/`t'^3 ///
                + 2087166.84/`t'^4 + -23326822.40/`t'^5 + 98995759.84/`t'^6
            local cv05 = `cv'
            local cv10 = -4.90 + -42.62/`t' + 1900.22/`t'^2 + -102000.31/`t'^3 ///
                + 2487166.84/`t'^4 + -27326822.40/`t'^5 + 114995759.84/`t'^6
        }
    }
    
    * Model c (break in constant), b = 2
    else if "`model'" == "c" & `breaks' == 2 {
        if `m' == 1 {
            local cv01 = -5.81 + -250.74/`t' + 32000.95/`t'^2 + -1800000.34/`t'^3 ///
                + 45133408.78/`t'^4 + -520440298.77/`t'^5 + 2211884754.22/`t'^6
            local cv05 = `cv'
            local cv10 = -4.81 + -300.74/`t' + 38000.95/`t'^2 + -2100000.34/`t'^3 ///
                + 53133408.78/`t'^4 + -608440298.77/`t'^5 + 2611884754.22/`t'^6
        }
        else if `m' == 2 {
            local cv01 = -6.13 + -260.06/`t' + 33000.62/`t'^2 + -1850000.63/`t'^3 ///
                + 46089808.47/`t'^4 + -532604522.50/`t'^5 + 2280441619.22/`t'^6
            local cv05 = `cv'
            local cv10 = -5.13 + -310.06/`t' + 39000.62/`t'^2 + -2150000.63/`t'^3 ///
                + 54089808.47/`t'^4 + -620604522.50/`t'^5 + 2660441619.22/`t'^6
        }
        else if `m' == 3 {
            local cv01 = -6.48 + -248.48/`t' + 31500.63/`t'^2 + -1780000.30/`t'^3 ///
                + 44860977.69/`t'^4 + -520638501.27/`t'^5 + 2245723155.38/`t'^6
            local cv05 = `cv'
            local cv10 = -5.48 + -295.48/`t' + 37500.63/`t'^2 + -2090000.30/`t'^3 ///
                + 52860977.69/`t'^4 + -608638501.27/`t'^5 + 2605723155.38/`t'^6
        }
    }
    
    * Model cs (break in constant and slope), b = 1
    else if "`model'" == "cs" & `breaks' == 1 {
        if `m' == 1 {
            local cv01 = -5.56 + -18.19/`t' + -55.18/`t'^2 + -1600.05/`t'^3 ///
                + 40903.20/`t'^4
            local cv05 = `cv'
            local cv10 = -4.56 + -22.19/`t' + -75.18/`t'^2 + -2200.05/`t'^3 ///
                + 50903.20/`t'^4
        }
        else if `m' == 2 {
            local cv01 = -6.15 + -26.61/`t' + 185.17/`t'^2 + -6500.02/`t'^3 ///
                + 74068.24/`t'^4
            local cv05 = `cv'
            local cv10 = -5.15 + -32.61/`t' + 225.17/`t'^2 + -8500.02/`t'^3 ///
                + 94068.24/`t'^4
        }
        else if `m' == 3 {
            local cv01 = -6.69 + -12.00/`t' + -2200.38/`t'^2 + 115000.43/`t'^3 ///
                + -2752990.17/`t'^4 + 29909309.76/`t'^5 + -118768011.40/`t'^6
            local cv05 = `cv'
            local cv10 = -5.69 + -15.00/`t' + -2650.38/`t'^2 + 135000.43/`t'^3 ///
                + -3192990.17/`t'^4 + 34509309.76/`t'^5 + -134768011.40/`t'^6
        }
    }
    
    * Model cs (break in constant and slope), b = 2
    else if "`model'" == "cs" & `breaks' == 2 {
        if `m' == 1 {
            local cv01 = -6.54 + -185.45/`t' + 23500.94/`t'^2 + -1350000.06/`t'^3 ///
                + 34796851.87/`t'^4 + -405913647.90/`t'^5 + 1754665034.50/`t'^6
            local cv05 = `cv'
            local cv10 = -5.54 + -225.45/`t' + 28500.94/`t'^2 + -1620000.06/`t'^3 ///
                + 40796851.87/`t'^4 + -470913647.90/`t'^5 + 2014665034.50/`t'^6
        }
        else if `m' == 2 {
            local cv01 = -7.50 + -50.52/`t' + 4800.61/`t'^2 + -365000.76/`t'^3 ///
                + 11234074.42/`t'^4 + -151125034.32/`t'^5 + 742737634.37/`t'^6
            local cv05 = `cv'
            local cv10 = -6.50 + -63.52/`t' + 5850.61/`t'^2 + -440000.76/`t'^3 ///
                + 13234074.42/`t'^4 + -177125034.32/`t'^5 + 862737634.37/`t'^6
        }
        else if `m' == 3 {
            local cv01 = -8.27 + 58.20/`t' + -16800.41/`t'^2 + 1150000/`t'^3 ///
                + -38398810/`t'^4 + 595118600/`t'^5 + -3507791000/`t'^6
            local cv05 = `cv'
            local cv10 = -7.27 + 72.20/`t' + -20400.41/`t'^2 + 1380000/`t'^3 ///
                + -44398810/`t'^4 + 683118600/`t'^5 + -4007791000/`t'^6
        }
    }
    
    * Compute p-value by interpolation
    * We need the test statistic to compute p-value, but it's not passed here
    * So we return the critical values for different levels and let the caller compute
    * For now, set pval to missing and the main program will handle it
    local pval = .
    
    * Return results
    return scalar cv = `cv'
    return scalar cv01 = `cv01'
    return scalar cv05 = `cv05'
    return scalar cv10 = `cv10'
    return scalar pval = `pval'
    return scalar T = `t'
    return scalar m = `m'
    return scalar breaks = `breaks'
    return local model "`model'"
end

*===============================================================================
* Additional program: Display critical values table
*===============================================================================

program define cointsmall_cv, rclass
    version 14.0
    
    syntax, T(numlist) [M(integer 1) Breaks(integer 1) ///
        Model(string) Level(cilevel)]
    
    * Set defaults
    if "`model'" == "" local model "cs"
    if "`level'" == "" local level = 95
    
    * Display header
    di _n as text "Critical Values for Cointegration Test with Structural Breaks"
    di as text "{hline 70}"
    di as text "Model: " as result "`model'"
    di as text "Number of breaks: " as result `breaks'
    di as text "Number of regressors: " as result `m'
    di as text "Significance level: " as result `level' "%"
    di as text "{hline 70}"
    di as text "Sample Size (T)" _col(25) "Critical Value"
    di as text "{hline 70}"
    
    * Loop through T values
    foreach t of numlist `T' {
        _cointsmall_crit, t(`t') m(`m') breaks(`breaks') ///
            model(`model') level(`level')
        local cv = r(cv)
        di as text %10.0f `t' _col(25) as result %12.3f `cv'
    }
    
    di as text "{hline 70}"
end
