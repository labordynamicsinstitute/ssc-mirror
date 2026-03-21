*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! LRMBOUNDS: Bounds Approach to Inference Using the Long Run Multiplier
*! Implements Webb, Linn & Lebo (2019, Political Analysis) and
*! Webb, Linn & Lebo (2020, Journal of Politics)

capture program drop lrmbounds
capture program drop _lrmbounds_stars
capture program drop _lrmbounds_decision
capture program drop _lrmbounds_center
capture program drop _lrmbounds_cv_ftest
capture program drop _lrmbounds_cv_ttest_ecr
capture program drop _lrmbounds_cv_lrm
capture program drop _lrmbounds_cv_lrm_lookup
capture program drop _lrmbounds_estimate
capture program drop _lrmbounds_ftest
capture program drop _lrmbounds_lrm
capture program drop _lrmbounds_graph


* ==============================================================================
*  FROM: _lrmbounds_stars.ado
* ==============================================================================
program define _lrmbounds_stars, sclass
    args pval
    if missing(`pval')       sreturn local s ""
    else if `pval' < 0.01    sreturn local s "***"
    else if `pval' < 0.05    sreturn local s "**"
    else if `pval' < 0.10    sreturn local s "*"
    else                     sreturn local s ""
end

capture program drop _lrmbounds_decision
program define _lrmbounds_decision, sclass
    * Given a test statistic, lower bound, upper bound, and test type
    * Returns decision string
    args tstat lb ub testtype
    
    if "`testtype'" == "f" {
        * F-test: reject if above upper bound
        if `tstat' > `ub' {
            sreturn local decision "Reject H0"
            sreturn local dcode "reject"
        }
        else if `tstat' < `lb' {
            sreturn local decision "Fail to Reject"
            sreturn local dcode "fail"
        }
        else {
            sreturn local decision "Inconclusive"
            sreturn local dcode "inconclusive"
        }
    }
    else {
        * t-test: reject if |t| > upper bound (bounds are positive, t is negative)
        local abst = abs(`tstat')
        if `abst' > `ub' {
            sreturn local decision "Reject H0"
            sreturn local dcode "reject"
        }
        else if `abst' < `lb' {
            sreturn local decision "Fail to Reject"
            sreturn local dcode "fail"
        }
        else {
            sreturn local decision "Inconclusive"
            sreturn local dcode "inconclusive"
        }
    }
end

capture program drop _lrmbounds_center
program define _lrmbounds_center
    syntax , TEXT(string) WIDTH(integer)
    local len = udstrlen("`text'")
    if `len' >= `width' {
        di "`text'" _continue
    }
    else {
        local lpad = int((`width' - `len')/2)
        di _skip(`lpad') "`text'" _continue
    }
end


* ==============================================================================
*  FROM: _lrmbounds_critvals.ado
* ==============================================================================
* ============================================================================
*  PSS F-BOUNDS CRITICAL VALUES
*  From Pesaran, Shin & Smith (2001), Table CI
*  Returns: lower I(0) bound and upper I(1) bound
* ============================================================================
capture program drop _lrmbounds_cv_ftest
program define _lrmbounds_cv_ftest, rclass
    syntax , K(integer) CASE(integer) ALPHA(real) [NOBS(integer 1000)]
    * k = number of regressors (independent variables)
    * case = 3 (unrestricted intercept, no trend) or 5 (unrestricted intercept + trend)
    * alpha = significance level (0.01, 0.025, 0.05, 0.10)
    * nobs = sample size (for Narayan small-sample adjustment)
    
    * -----------------------------------------------------------------------
    *  Case III: Unrestricted intercept, no trend
    *  PSS (2001) Table CI(iii), asymptotic critical values
    *  Format: I(0)_lower  I(1)_upper
    * -----------------------------------------------------------------------
    if `case' == 3 {
        if `alpha' == 0.10 {
            if `k' == 1  {
                local lb = 3.02
                local ub = 3.51
            }
            else if `k' == 2  {
                local lb = 2.63
                local ub = 3.35
            }
            else if `k' == 3  {
                local lb = 2.37
                local ub = 3.20
            }
            else if `k' == 4  {
                local lb = 2.20
                local ub = 3.09
            }
            else if `k' == 5  {
                local lb = 2.08
                local ub = 3.00
            }
            else if `k' == 6  {
                local lb = 1.99
                local ub = 2.94
            }
            else if `k' == 7  {
                local lb = 1.92
                local ub = 2.89
            }
            else if `k' == 8  {
                local lb = 1.85
                local ub = 2.85
            }
            else if `k' == 9  {
                local lb = 1.80
                local ub = 2.80
            }
            else if `k' == 10  {
                local lb = 1.76
                local ub = 2.77
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.05 {
            if `k' == 1  {
                local lb = 3.62
                local ub = 4.16
            }
            else if `k' == 2  {
                local lb = 3.10
                local ub = 3.87
            }
            else if `k' == 3  {
                local lb = 2.79
                local ub = 3.67
            }
            else if `k' == 4  {
                local lb = 2.56
                local ub = 3.49
            }
            else if `k' == 5  {
                local lb = 2.39
                local ub = 3.38
            }
            else if `k' == 6  {
                local lb = 2.27
                local ub = 3.28
            }
            else if `k' == 7  {
                local lb = 2.17
                local ub = 3.21
            }
            else if `k' == 8  {
                local lb = 2.11
                local ub = 3.15
            }
            else if `k' == 9  {
                local lb = 2.04
                local ub = 3.11
            }
            else if `k' == 10  {
                local lb = 1.98
                local ub = 3.04
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.025 {
            if `k' == 1  {
                local lb = 4.18
                local ub = 4.79
            }
            else if `k' == 2  {
                local lb = 3.55
                local ub = 4.38
            }
            else if `k' == 3  {
                local lb = 3.17
                local ub = 4.14
            }
            else if `k' == 4  {
                local lb = 2.89
                local ub = 3.87
            }
            else if `k' == 5  {
                local lb = 2.70
                local ub = 3.73
            }
            else if `k' == 6  {
                local lb = 2.55
                local ub = 3.61
            }
            else if `k' == 7  {
                local lb = 2.42
                local ub = 3.50
            }
            else if `k' == 8  {
                local lb = 2.33
                local ub = 3.42
            }
            else if `k' == 9  {
                local lb = 2.26
                local ub = 3.35
            }
            else if `k' == 10  {
                local lb = 2.19
                local ub = 3.30
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.01 {
            if `k' == 1  {
                local lb = 4.94
                local ub = 5.58
            }
            else if `k' == 2  {
                local lb = 4.13
                local ub = 5.00
            }
            else if `k' == 3  {
                local lb = 3.65
                local ub = 4.66
            }
            else if `k' == 4  {
                local lb = 3.29
                local ub = 4.37
            }
            else if `k' == 5  {
                local lb = 3.06
                local ub = 4.15
            }
            else if `k' == 6  {
                local lb = 2.88
                local ub = 3.99
            }
            else if `k' == 7  {
                local lb = 2.73
                local ub = 3.90
            }
            else if `k' == 8  {
                local lb = 2.62
                local ub = 3.77
            }
            else if `k' == 9  {
                local lb = 2.54
                local ub = 3.68
            }
            else if `k' == 10  {
                local lb = 2.45
                local ub = 3.61
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else {
            local lb = .
            local ub = .
        }
    }
    * -----------------------------------------------------------------------
    *  Case V: Unrestricted intercept + unrestricted trend
    * -----------------------------------------------------------------------
    else if `case' == 5 {
        if `alpha' == 0.10 {
            if `k' == 1  {
                local lb = 3.78
                local ub = 4.27
            }
            else if `k' == 2  {
                local lb = 3.38
                local ub = 4.02
            }
            else if `k' == 3  {
                local lb = 3.05
                local ub = 3.87
            }
            else if `k' == 4  {
                local lb = 2.84
                local ub = 3.76
            }
            else if `k' == 5  {
                local lb = 2.68
                local ub = 3.67
            }
            else if `k' == 6  {
                local lb = 2.57
                local ub = 3.61
            }
            else if `k' == 7  {
                local lb = 2.47
                local ub = 3.56
            }
            else if `k' == 8  {
                local lb = 2.40
                local ub = 3.52
            }
            else if `k' == 9  {
                local lb = 2.34
                local ub = 3.48
            }
            else if `k' == 10  {
                local lb = 2.28
                local ub = 3.44
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.05 {
            if `k' == 1  {
                local lb = 4.42
                local ub = 4.99
            }
            else if `k' == 2  {
                local lb = 3.88
                local ub = 4.61
            }
            else if `k' == 3  {
                local lb = 3.47
                local ub = 4.45
            }
            else if `k' == 4  {
                local lb = 3.24
                local ub = 4.35
            }
            else if `k' == 5  {
                local lb = 3.04
                local ub = 4.23
            }
            else if `k' == 6  {
                local lb = 2.89
                local ub = 4.13
            }
            else if `k' == 7  {
                local lb = 2.78
                local ub = 4.07
            }
            else if `k' == 8  {
                local lb = 2.69
                local ub = 4.00
            }
            else if `k' == 9  {
                local lb = 2.62
                local ub = 3.95
            }
            else if `k' == 10  {
                local lb = 2.54
                local ub = 3.91
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.025 {
            if `k' == 1  {
                local lb = 5.03
                local ub = 5.65
            }
            else if `k' == 2  {
                local lb = 4.37
                local ub = 5.16
            }
            else if `k' == 3  {
                local lb = 3.89
                local ub = 4.97
            }
            else if `k' == 4  {
                local lb = 3.59
                local ub = 4.82
            }
            else if `k' == 5  {
                local lb = 3.36
                local ub = 4.69
            }
            else if `k' == 6  {
                local lb = 3.19
                local ub = 4.59
            }
            else if `k' == 7  {
                local lb = 3.06
                local ub = 4.51
            }
            else if `k' == 8  {
                local lb = 2.97
                local ub = 4.45
            }
            else if `k' == 9  {
                local lb = 2.88
                local ub = 4.40
            }
            else if `k' == 10  {
                local lb = 2.79
                local ub = 4.34
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.01 {
            if `k' == 1  {
                local lb = 6.10
                local ub = 6.73
            }
            else if `k' == 2  {
                local lb = 5.15
                local ub = 5.94
            }
            else if `k' == 3  {
                local lb = 4.56
                local ub = 5.65
            }
            else if `k' == 4  {
                local lb = 4.18
                local ub = 5.44
            }
            else if `k' == 5  {
                local lb = 3.90
                local ub = 5.22
            }
            else if `k' == 6  {
                local lb = 3.65
                local ub = 5.10
            }
            else if `k' == 7  {
                local lb = 3.49
                local ub = 4.99
            }
            else if `k' == 8  {
                local lb = 3.36
                local ub = 4.89
            }
            else if `k' == 9  {
                local lb = 3.24
                local ub = 4.80
            }
            else if `k' == 10  {
                local lb = 3.13
                local ub = 4.73
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else {
            local lb = .
            local ub = .
        }
    }
    else {
        local lb = .
        local ub = .
    }
    
    * Small-sample adjustment using Narayan (2005) for T < 80
    if `nobs' < 80 & `nobs' >= 30 {
        * Narayan (2005) small-sample critical values, Case III, 5%
        * Approximate scaling factor based on sample size
        local scale = 1 + (80 - `nobs') * 0.005
        local lb = `lb' * `scale'
        local ub = `ub' * `scale'
    }
    
    return scalar lb = `lb'
    return scalar ub = `ub'
end

* ============================================================================
*  PSS ECR t-BOUNDS CRITICAL VALUES
*  From PSS (2001), Table CII
*  t-test on the error correction rate (psi_yy)
* ============================================================================
capture program drop _lrmbounds_cv_ttest_ecr
program define _lrmbounds_cv_ttest_ecr, rclass
    syntax , K(integer) CASE(integer) ALPHA(real)
    
    * Case III: Unrestricted intercept, no trend
    if `case' == 3 {
        if `alpha' == 0.10 {
            if `k' == 1  {
                local lb = -1.62
                local ub = -2.28
            }
            else if `k' == 2  {
                local lb = -1.62
                local ub = -2.68
            }
            else if `k' == 3  {
                local lb = -1.62
                local ub = -3.00
            }
            else if `k' == 4  {
                local lb = -1.62
                local ub = -3.26
            }
            else if `k' == 5  {
                local lb = -1.62
                local ub = -3.49
            }
            else if `k' == 6  {
                local lb = -1.62
                local ub = -3.70
            }
            else if `k' == 7  {
                local lb = -1.62
                local ub = -3.86
            }
            else if `k' == 8  {
                local lb = -1.62
                local ub = -4.04
            }
            else if `k' == 9  {
                local lb = -1.62
                local ub = -4.18
            }
            else if `k' == 10  {
                local lb = -1.62
                local ub = -4.34
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.05 {
            if `k' == 1  {
                local lb = -1.95
                local ub = -2.60
            }
            else if `k' == 2  {
                local lb = -1.95
                local ub = -3.02
            }
            else if `k' == 3  {
                local lb = -1.95
                local ub = -3.33
            }
            else if `k' == 4  {
                local lb = -1.95
                local ub = -3.60
            }
            else if `k' == 5  {
                local lb = -1.95
                local ub = -3.83
            }
            else if `k' == 6  {
                local lb = -1.95
                local ub = -4.04
            }
            else if `k' == 7  {
                local lb = -1.95
                local ub = -4.21
            }
            else if `k' == 8  {
                local lb = -1.95
                local ub = -4.37
            }
            else if `k' == 9  {
                local lb = -1.95
                local ub = -4.52
            }
            else if `k' == 10  {
                local lb = -1.95
                local ub = -4.66
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.01 {
            if `k' == 1  {
                local lb = -2.58
                local ub = -3.22
            }
            else if `k' == 2  {
                local lb = -2.58
                local ub = -3.59
            }
            else if `k' == 3  {
                local lb = -2.58
                local ub = -3.93
            }
            else if `k' == 4  {
                local lb = -2.58
                local ub = -4.23
            }
            else if `k' == 5  {
                local lb = -2.58
                local ub = -4.44
            }
            else if `k' == 6  {
                local lb = -2.58
                local ub = -4.67
            }
            else if `k' == 7  {
                local lb = -2.58
                local ub = -4.84
            }
            else if `k' == 8  {
                local lb = -2.58
                local ub = -5.03
            }
            else if `k' == 9  {
                local lb = -2.58
                local ub = -5.17
            }
            else if `k' == 10  {
                local lb = -2.58
                local ub = -5.31
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else {
            local lb = .
            local ub = .
        }
    }
    * Case V: Unrestricted intercept + unrestricted trend
    else if `case' == 5 {
        if `alpha' == 0.10 {
            if `k' == 1  {
                local lb = -2.57
                local ub = -3.21
            }
            else if `k' == 2  {
                local lb = -2.57
                local ub = -3.53
            }
            else if `k' == 3  {
                local lb = -2.57
                local ub = -3.80
            }
            else if `k' == 4  {
                local lb = -2.57
                local ub = -4.01
            }
            else if `k' == 5  {
                local lb = -2.57
                local ub = -4.21
            }
            else if `k' == 6  {
                local lb = -2.57
                local ub = -4.38
            }
            else if `k' == 7  {
                local lb = -2.57
                local ub = -4.52
            }
            else if `k' == 8  {
                local lb = -2.57
                local ub = -4.66
            }
            else if `k' == 9  {
                local lb = -2.57
                local ub = -4.79
            }
            else if `k' == 10  {
                local lb = -2.57
                local ub = -4.91
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.05 {
            if `k' == 1  {
                local lb = -2.86
                local ub = -3.53
            }
            else if `k' == 2  {
                local lb = -2.86
                local ub = -3.83
            }
            else if `k' == 3  {
                local lb = -2.86
                local ub = -4.10
            }
            else if `k' == 4  {
                local lb = -2.86
                local ub = -4.34
            }
            else if `k' == 5  {
                local lb = -2.86
                local ub = -4.52
            }
            else if `k' == 6  {
                local lb = -2.86
                local ub = -4.69
            }
            else if `k' == 7  {
                local lb = -2.86
                local ub = -4.85
            }
            else if `k' == 8  {
                local lb = -2.86
                local ub = -4.99
            }
            else if `k' == 9  {
                local lb = -2.86
                local ub = -5.11
            }
            else if `k' == 10  {
                local lb = -2.86
                local ub = -5.23
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else if `alpha' == 0.01 {
            if `k' == 1  {
                local lb = -3.43
                local ub = -4.10
            }
            else if `k' == 2  {
                local lb = -3.43
                local ub = -4.44
            }
            else if `k' == 3  {
                local lb = -3.43
                local ub = -4.73
            }
            else if `k' == 4  {
                local lb = -3.43
                local ub = -4.96
            }
            else if `k' == 5  {
                local lb = -3.43
                local ub = -5.13
            }
            else if `k' == 6  {
                local lb = -3.43
                local ub = -5.31
            }
            else if `k' == 7  {
                local lb = -3.43
                local ub = -5.46
            }
            else if `k' == 8  {
                local lb = -3.43
                local ub = -5.60
            }
            else if `k' == 9  {
                local lb = -3.43
                local ub = -5.72
            }
            else if `k' == 10  {
                local lb = -3.43
                local ub = -5.84
            }
            else {
                local lb = .
                local ub = .
            }
        }
        else {
            local lb = .
            local ub = .
        }
    }
    else {
        local lb = .
        local ub = .
    }
    
    return scalar lb = abs(`lb')
    return scalar ub = abs(`ub')
end

* ============================================================================
*  WEBB, LINN & LEBO (2019) LRM t-BOUNDS CRITICAL VALUES
*  From Tables 3–6 in "A Bounds Approach to Inference Using the
*  Long Run Multiplier" (Political Analysis, 27(3), 2019)
*
*  Table 6 provides the COMBINED bounds given uncertainty about
*  deterministic features of the DGP:
*    Lower bound = from DGPs with deterministics (y has trend/constant)
*    Upper bound = from DGPs without deterministics (pure random walk)
*
*  Values computed via 100,000 MC replications for the LRM t-statistic
*  in the Bewley IV regression.
*
*  CRITICAL: These are the KEY INNOVATION of Webb et al. (2019).
*  The bounds are for the absolute value of the t-statistic on each LRM.
* ============================================================================
capture program drop _lrmbounds_cv_lrm
program define _lrmbounds_cv_lrm, rclass
    syntax , K(integer) NOBS(integer) ALPHA(real)
    * k = number of independent variables (regressors)
    * nobs = effective sample size T
    * alpha = significance level (0.01, 0.05, 0.10)
    
    * Webb et al. (2019) Table 6: Combined bounds
    * Format: lower_bound upper_bound
    * Lower bound: minimum |t| needed when all x are I(0)
    * Upper bound: minimum |t| needed when all x are I(1)
    
    * -----------------------------------------------------------------------
    *  alpha = 0.05 (5% significance level)
    *  From Webb (2019) Table 6
    * -----------------------------------------------------------------------
    if `alpha' == 0.05 {
        if `nobs' <= 40 {
            * T = 30
            if `k' == 1  {
                local lb = 1.05
                local ub = 3.69
            }
            else if `k' == 2  {
                local lb = 1.05
                local ub = 3.68
            }
            else if `k' == 3  {
                local lb = 1.05
                local ub = 3.62
            }
            else if `k' == 4  {
                local lb = 1.05
                local ub = 3.61
            }
            else if `k' == 5  {
                local lb = 1.05
                local ub = 3.60
            }
            else {
                local lb = 1.05
                local ub = 3.60
            }
        }
        else if `nobs' <= 65 {
            * T = 50
            if `k' == 1  {
                local lb = 1.01
                local ub = 3.69
            }
            else if `k' == 2  {
                local lb = 1.01
                local ub = 3.63
            }
            else if `k' == 3  {
                local lb = 1.01
                local ub = 3.63
            }
            else if `k' == 4  {
                local lb = 1.01
                local ub = 3.59
            }
            else if `k' == 5  {
                local lb = 1.01
                local ub = 3.58
            }
            else {
                local lb = 1.01
                local ub = 3.58
            }
        }
        else {
            * T >= 80 (asymptotic)
            if `k' == 1  {
                local lb = 0.998
                local ub = 3.65
            }
            else if `k' == 2  {
                local lb = 0.998
                local ub = 3.60
            }
            else if `k' == 3  {
                local lb = 0.998
                local ub = 3.65
            }
            else if `k' == 4  {
                local lb = 0.998
                local ub = 3.61
            }
            else if `k' == 5  {
                local lb = 0.998
                local ub = 3.60
            }
            else {
                local lb = 0.998
                local ub = 3.60
            }
        }
    }
    * -----------------------------------------------------------------------
    *  alpha = 0.10 (10% significance level)
    *  Interpolated from Webb (2019) Tables 3-5
    * -----------------------------------------------------------------------
    else if `alpha' == 0.10 {
        if `nobs' <= 40 {
            if `k' == 1  {
                local lb = 0.68
                local ub = 3.06
            }
            else if `k' == 2  {
                local lb = 0.68
                local ub = 3.03
            }
            else if `k' == 3  {
                local lb = 0.68
                local ub = 2.99
            }
            else if `k' == 4  {
                local lb = 0.68
                local ub = 2.97
            }
            else if `k' == 5  {
                local lb = 0.68
                local ub = 2.96
            }
            else {
                local lb = 0.68
                local ub = 2.96
            }
        }
        else if `nobs' <= 65 {
            if `k' == 1  {
                local lb = 0.66
                local ub = 3.04
            }
            else if `k' == 2  {
                local lb = 0.66
                local ub = 3.01
            }
            else if `k' == 3  {
                local lb = 0.66
                local ub = 2.99
            }
            else if `k' == 4  {
                local lb = 0.66
                local ub = 2.96
            }
            else if `k' == 5  {
                local lb = 0.66
                local ub = 2.95
            }
            else {
                local lb = 0.66
                local ub = 2.95
            }
        }
        else {
            if `k' == 1  {
                local lb = 0.65
                local ub = 3.02
            }
            else if `k' == 2  {
                local lb = 0.65
                local ub = 2.99
            }
            else if `k' == 3  {
                local lb = 0.65
                local ub = 2.98
            }
            else if `k' == 4  {
                local lb = 0.65
                local ub = 2.95
            }
            else if `k' == 5  {
                local lb = 0.65
                local ub = 2.94
            }
            else {
                local lb = 0.65
                local ub = 2.94
            }
        }
    }
    * -----------------------------------------------------------------------
    *  alpha = 0.01 (1% significance level)
    *  Interpolated from Webb (2019) Tables 3-5
    * -----------------------------------------------------------------------
    else if `alpha' == 0.01 {
        if `nobs' <= 40 {
            if `k' == 1  {
                local lb = 1.72
                local ub = 4.96
            }
            else if `k' == 2  {
                local lb = 1.72
                local ub = 4.92
            }
            else if `k' == 3  {
                local lb = 1.72
                local ub = 4.88
            }
            else if `k' == 4  {
                local lb = 1.72
                local ub = 4.85
            }
            else if `k' == 5  {
                local lb = 1.72
                local ub = 4.82
            }
            else {
                local lb = 1.72
                local ub = 4.82
            }
        }
        else if `nobs' <= 65 {
            if `k' == 1  {
                local lb = 1.68
                local ub = 4.94
            }
            else if `k' == 2  {
                local lb = 1.68
                local ub = 4.90
            }
            else if `k' == 3  {
                local lb = 1.68
                local ub = 4.86
            }
            else if `k' == 4  {
                local lb = 1.68
                local ub = 4.82
            }
            else if `k' == 5  {
                local lb = 1.68
                local ub = 4.80
            }
            else {
                local lb = 1.68
                local ub = 4.80
            }
        }
        else {
            if `k' == 1  {
                local lb = 1.65
                local ub = 4.90
            }
            else if `k' == 2  {
                local lb = 1.65
                local ub = 4.86
            }
            else if `k' == 3  {
                local lb = 1.65
                local ub = 4.84
            }
            else if `k' == 4  {
                local lb = 1.65
                local ub = 4.80
            }
            else if `k' == 5  {
                local lb = 1.65
                local ub = 4.78
            }
            else {
                local lb = 1.65
                local ub = 4.78
            }
        }
    }
    else {
        local lb = .
        local ub = .
    }
    
    return scalar lb = `lb'
    return scalar ub = `ub'
end

* ============================================================================
*  WEBB (2020) / WEBB (2019) TABLE 6: COMBINED LRM BOUNDS
*  Used in the empirical applications of the 2020 paper
*  Sample-size-specific values from Tables 3-5 aggregated
*  The 2020 paper uses same critical values from 2019
* ============================================================================
capture program drop _lrmbounds_cv_lrm_lookup
program define _lrmbounds_cv_lrm_lookup, rclass
    syntax , K(integer) NOBS(integer) [ALPHA(real 0.05)]
    
    * Get the appropriate bounds
    _lrmbounds_cv_lrm, k(`k') nobs(`nobs') alpha(`alpha')
    local lb = r(lb)
    local ub = r(ub)
    
    return scalar lb = `lb'
    return scalar ub = `ub'
    return scalar nobs = `nobs'
    return scalar k = `k'
    return scalar alpha = `alpha'
end


* ==============================================================================
*  FROM: _lrmbounds_estimate.ado
* ==============================================================================
program define _lrmbounds_estimate, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        MAXLAG(integer 4)                      ///
        LAGSEL(string)                         ///
        LAGS(numlist integer >=0)              ///
        ARDL(numlist integer >=0)              ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        ]
    
    marksample touse
    
    * Parse dependent and independent variables
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    if `nindep' < 1 {
        di as err "At least one independent variable required"
        exit 198
    }
    
    * Lag selection
    if "`lagsel'" == "" local lagsel "bic"
    local lagsel = lower("`lagsel'")
    
    * ================================================================
    *  Determine lag orders: ARDL(p, q1, q2, ...)
    * ================================================================
    if "`ardl'" != "" {
        * User specified ARDL(p, q1, q2, ...) directly
        local nardl : word count `ardl'
        local p_lag : word 1 of `ardl'
        local ardl_spec "`p_lag'"
        local j = 0
        foreach xv of local indepvars {
            local ++j
            local jj = `j' + 1
            if `jj' <= `nardl' {
                local q_`j' : word `jj' of `ardl'
            }
            else {
                local q_`j' = `p_lag'
            }
            local ardl_spec "`ardl_spec',`q_`j''"
        }
    }
    else if "`lags'" != "" {
        * Single lag for all: lags(p)
        local p_lag : word 1 of `lags'
        local ardl_spec "`p_lag'"
        forvalues j = 1/`nindep' {
            local q_`j' = `p_lag'
            local ardl_spec "`ardl_spec',`p_lag'"
        }
    }
    else {
        * Automatic lag selection via IC
        local bestlag = 1
        local bestic = .
        
        forvalues p = 1/`maxlag' {
            local reglist ""
            local reglist "`reglist' L.`depvar'"
            foreach xv of local indepvars {
                local reglist "`reglist' L.`xv'"
            }
            foreach xv of local indepvars {
                local reglist "`reglist' D.`xv'"
            }
            if `p' > 1 {
                forvalues i = 1/`=`p'-1' {
                    local reglist "`reglist' L`i'D.`depvar'"
                    foreach xv of local indepvars {
                        local reglist "`reglist' L`i'D.`xv'"
                    }
                }
            }
            if "`trend'" != "" {
                tempvar tvar
                qui gen double `tvar' = _n if `touse'
                local reglist "`reglist' `tvar'"
            }
            capture qui regress D.`depvar' `reglist' if `touse', `noconstant'
            if _rc continue
            
            local N = e(N)
            local k_est = e(rank)
            local rss = e(rss)
            
            if "`lagsel'" == "aic" {
                local ic = `N' * ln(`rss'/`N') + 2 * `k_est'
            }
            else {
                local ic = `N' * ln(`rss'/`N') + ln(`N') * `k_est'
            }
            
            if missing(`bestic') | (`ic' < `bestic') {
                local bestic = `ic'
                local bestlag = `p'
            }
        }
        local p_lag = `bestlag'
        local ardl_spec "`p_lag'"
        forvalues j = 1/`nindep' {
            local q_`j' = `p_lag'
            local ardl_spec "`ardl_spec',`p_lag'"
        }
    }
    
    * Compute maxq for display
    local maxq = `p_lag'
    forvalues j = 1/`nindep' {
        if `q_`j'' > `maxq' local maxq = `q_`j''
    }
    
    * ================================================================
    *  Construct regressor list with per-variable lags
    * ================================================================
    local ecm_levels ""
    local ecm_diffs ""
    local allregs ""
    
    * Lagged levels: y_{t-1} and x_{t-1}
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    
    * Short-run: contemporaneous Dx_t for each x (if q_j >= 0)
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' >= 0 {
            local ecm_diffs "`ecm_diffs' D.`xv'"
        }
    }
    
    * Lagged differences of y: LD.y_{t-1}, ..., L(p-1)D.y for ARDL p
    if `p_lag' > 1 {
        forvalues i = 1/`=`p_lag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
        }
    }
    
    * Lagged differences of each x: L1D.x, ..., L(q_j-1)D.x
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' > 1 {
            forvalues i = 1/`=`q_`j''-1' {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    
    * Trend variable
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    
    * Full regressor list
    local allregs "`ecm_levels' `ecm_diffs' `trendvar'"
    
    * ================================================================
    *  Estimate the ECM by OLS
    * ================================================================
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    * Save estimation results
    local N = e(N)
    local k_total = e(rank)
    local r2 = e(r2)
    local r2_a = e(r2_a)
    local rmse = e(rmse)
    local rss = e(rss)
    local F_model = e(F)
    local ll = e(ll)
    
    * ECR
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    local ecr_t = `ecr' / `ecr_se'
    local ecr_p = 2 * ttail(`N' - `k_total', abs(`ecr_t'))
    
    * Psi_yx
    local j = 0
    foreach xv of local indepvars {
        local ++j
        local psi_yx_`j' = _b[L.`xv']
        local psi_yx_se_`j' = _se[L.`xv']
        local psi_yx_t_`j' = `psi_yx_`j'' / `psi_yx_se_`j''
        local psi_yx_p_`j' = 2 * ttail(`N' - `k_total', abs(`psi_yx_t_`j''))
    }
    
    * Delta method LRMs
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    
    local j = 0
    foreach xv of local indepvars {
        local ++j
        local lrm_`j' = -`psi_yx_`j'' / `ecr'
        local pos_yy = colnumb(`b', "L.`depvar'")
        local pos_xj = colnumb(`b', "L.`xv'")
        local var_yy = `V'[`pos_yy', `pos_yy']
        local var_xj = `V'[`pos_xj', `pos_xj']
        local cov_xy = `V'[`pos_xj', `pos_yy']
        local g1 = -1 / `ecr'
        local g2 = `psi_yx_`j'' / (`ecr' * `ecr')
        local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
        local lrm_se_`j' = sqrt(`var_lrm')
        local lrm_t_`j' = `lrm_`j'' / `lrm_se_`j''
        local lrm_p_`j' = 2 * ttail(`N' - `k_total', abs(`lrm_t_`j''))
    }
    
    * Return results
    return scalar N = `N'
    return scalar k = `nindep'
    return scalar optlag = `p_lag'
    return scalar r2 = `r2'
    return scalar r2_a = `r2_a'
    return scalar rmse = `rmse'
    return scalar rss = `rss'
    return scalar ll = `ll'
    return scalar F_model = `F_model'
    return scalar k_total = `k_total'
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar ecr_t = `ecr_t'
    return scalar ecr_p = `ecr_p'
    return scalar nindep = `nindep'
    
    local j = 0
    foreach xv of local indepvars {
        local ++j
        return scalar lrm_`j' = `lrm_`j''
        return scalar lrm_se_`j' = `lrm_se_`j''
        return scalar lrm_t_`j' = `lrm_t_`j''
        return scalar lrm_p_`j' = `lrm_p_`j''
        return scalar psi_yx_`j' = `psi_yx_`j''
        return scalar psi_yx_se_`j' = `psi_yx_se_`j''
        return scalar q_`j' = `q_`j''
        return local xvar_`j' "`xv'"
    }
    
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
    return local ecm_levels "`ecm_levels'"
    return local ecm_diffs "`ecm_diffs'"
    return local allregs "`allregs'"
    return local trendvar "`trendvar'"
    return local lagsel "`lagsel'"
    return local hasrobust "`robust'"
    return local hastrend "`trend'"
    return local ardl_spec "`ardl_spec'"
end


* ==============================================================================
*  FROM: _lrmbounds_ftest.ado
* ==============================================================================
program define _lrmbounds_ftest, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        OPTLAG(integer 1)                      ///
        ARDLSPEC(string)                       ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        ]
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    * Parse ARDL spec
    if "`ardlspec'" != "" {
        local nspec : word count `ardlspec'
        local p_lag : word 1 of `ardlspec'
        local j = 0
        foreach xv of local indepvars {
            local ++j
            local jj = `j' + 1
            if `jj' <= `nspec' {
                local q_`j' : word `jj' of `ardlspec'
            }
            else {
                local q_`j' = `p_lag'
            }
        }
    }
    else {
        local p_lag = `optlag'
        forvalues j = 1/`nindep' {
            local q_`j' = `optlag'
        }
    }
    
    * Build regressor lists using per-variable lags
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    
    local ecm_diffs ""
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' >= 0 {
            local ecm_diffs "`ecm_diffs' D.`xv'"
        }
    }
    if `p_lag' > 1 {
        forvalues i = 1/`=`p_lag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
        }
    }
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' > 1 {
            forvalues i = 1/`=`q_`j''-1' {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    
    local allregs "`ecm_levels' `ecm_diffs' `trendvar'"
    
    * Unrestricted model
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    local N_u = e(N)
    local k_u = e(rank)
    local rss_u = e(rss)
    local df_u = e(df_r)
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    local ecr_t = `ecr' / `ecr_se'
    
    * Restricted model (drop all lagged levels)
    if "`robust'" != "" {
        qui regress D.`depvar' `ecm_diffs' `trendvar' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `ecm_diffs' `trendvar' if `touse', `noconstant'
    }
    
    local rss_r = e(rss)
    local k_r = e(rank)
    
    * F-statistic
    local q = `nindep' + 1
    local F_pss = ((`rss_r' - `rss_u') / `q') / (`rss_u' / `df_u')
    
    * Critical values
    local case = cond("`trend'" != "", 5, 3)
    
    foreach alpha in 0.01 0.05 0.10 {
        _lrmbounds_cv_ftest, k(`nindep') case(`case') alpha(`alpha') nobs(`N_u')
        local f_lb_`=100*`alpha'' = r(lb)
        local f_ub_`=100*`alpha'' = r(ub)
    }
    
    if `F_pss' > `f_ub_5' {
        local f_decision "Reject H0: Evidence of a level relationship"
        local f_dcode "reject"
    }
    else if `F_pss' < `f_lb_5' {
        local f_decision "Fail to Reject H0: No evidence of a level relationship"
        local f_dcode "fail"
    }
    else {
        local f_decision "Inconclusive: F-statistic falls between bounds"
        local f_dcode "inconclusive"
    }
    
    * ECR t-test
    foreach alpha in 0.01 0.05 0.10 {
        _lrmbounds_cv_ttest_ecr, k(`nindep') case(`case') alpha(`alpha')
        local t_lb_`=100*`alpha'' = r(lb)
        local t_ub_`=100*`alpha'' = r(ub)
    }
    
    if abs(`ecr_t') > `t_ub_5' {
        local t_decision "Reject H0: Significant error correction"
        local t_dcode "reject"
    }
    else if abs(`ecr_t') < `t_lb_5' {
        local t_decision "Fail to Reject H0: No error correction"
        local t_dcode "fail"
    }
    else {
        local t_decision "Inconclusive"
        local t_dcode "inconclusive"
    }
    
    * Degenerate equilibrium check
    local ecr_sig = (abs(`ecr_t') > `t_ub_5')
    local any_psi_sig = 0
    local j = 0
    foreach xv of local indepvars {
        local ++j
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
        local psi_t = _b[L.`xv'] / _se[L.`xv']
        local psi_p = 2 * ttail(`df_u', abs(`psi_t'))
        if `psi_p' < 0.05 local any_psi_sig = 1
    }
    
    if "`f_dcode'" == "reject" {
        if `ecr_sig' & `any_psi_sig' {
            local equil_type "Nondegenerate: Valid long-run equilibrium (H_A3)"
            local equil_code "valid"
        }
        else if !`ecr_sig' & `any_psi_sig' {
            local equil_type "Degenerate: Nonsense equilibrium (H_A1)"
            local equil_code "nonsense"
        }
        else if `ecr_sig' & !`any_psi_sig' {
            local equil_type "Degenerate: y is independent of x (H_A2)"
            local equil_code "degenerate"
        }
        else {
            local equil_type "Undefined: Neither psi_yy nor psi_yx significant"
            local equil_code "undefined"
        }
    }
    else {
        local equil_type "N/A (F-test null not rejected)"
        local equil_code "na"
    }
    
    * Returns
    return scalar F_pss = `F_pss'
    return scalar N = `N_u'
    return scalar q = `q'
    return scalar case = `case'
    return scalar df_u = `df_u'
    return scalar rss_u = `rss_u'
    return scalar rss_r = `rss_r'
    return scalar f_lb_1 = `f_lb_1'
    return scalar f_ub_1 = `f_ub_1'
    return scalar f_lb_5 = `f_lb_5'
    return scalar f_ub_5 = `f_ub_5'
    return scalar f_lb_10 = `f_lb_10'
    return scalar f_ub_10 = `f_ub_10'
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar ecr_t = `ecr_t'
    return scalar t_lb_1 = `t_lb_1'
    return scalar t_ub_1 = `t_ub_1'
    return scalar t_lb_5 = `t_lb_5'
    return scalar t_ub_5 = `t_ub_5'
    return scalar t_lb_10 = `t_lb_10'
    return scalar t_ub_10 = `t_ub_10'
    return local f_decision "`f_decision'"
    return local f_dcode "`f_dcode'"
    return local t_decision "`t_decision'"
    return local t_dcode "`t_dcode'"
    return local equil_type "`equil_type'"
    return local equil_code "`equil_code'"
end


* ==============================================================================
*  FROM: _lrmbounds_lrm.ado
* ==============================================================================
program define _lrmbounds_lrm, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        OPTLAG(integer 1)                      ///
        ARDLSPEC(string)                       ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        BEWLEY                                 ///
        ALPHA(real 0.05)                       ///
        ]
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    * Parse ARDL spec
    if "`ardlspec'" != "" {
        local nspec : word count `ardlspec'
        local p_lag : word 1 of `ardlspec'
        local j = 0
        foreach xv of local indepvars {
            local ++j
            local jj = `j' + 1
            if `jj' <= `nspec' {
                local q_`j' : word `jj' of `ardlspec'
            }
            else {
                local q_`j' = `p_lag'
            }
        }
    }
    else {
        local p_lag = `optlag'
        forvalues j = 1/`nindep' {
            local q_`j' = `optlag'
        }
    }
    
    * Build regressor lists
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    local ecm_diffs ""
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' >= 0 {
            local ecm_diffs "`ecm_diffs' D.`xv'"
        }
    }
    if `p_lag' > 1 {
        forvalues i = 1/`=`p_lag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
        }
    }
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `q_`j'' > 1 {
            forvalues i = 1/`=`q_`j''-1' {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    
    local allregs "`ecm_levels' `ecm_diffs' `trendvar'"
    
    * Estimate ECM
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    local N = e(N)
    local k_total = e(rank)
    local df_r = e(df_r)
    
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    
    * Delta method LRMs
    local j = 0
    foreach xv of local indepvars {
        local ++j
        local psi_yx = _b[L.`xv']
        local psi_yx_se = _se[L.`xv']
        local lrm = -`psi_yx' / `ecr'
        local pos_yy = colnumb(`b', "L.`depvar'")
        local pos_xj = colnumb(`b', "L.`xv'")
        local var_yy = `V'[`pos_yy', `pos_yy']
        local var_xj = `V'[`pos_xj', `pos_xj']
        local cov_xy = `V'[`pos_xj', `pos_yy']
        local g1 = -1 / `ecr'
        local g2 = `psi_yx' / (`ecr' * `ecr')
        local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
        local lrm_se = sqrt(max(`var_lrm', 0))
        local lrm_t = `lrm' / `lrm_se'
        local dm_lrm_`j' = `lrm'
        local dm_se_`j' = `lrm_se'
        local dm_t_`j' = `lrm_t'
    }
    
    * Bewley IV (if requested)
    * Bewley (1979) regression: y_t = theta*x_t + ... + u_t
    * where x_t in levels is instrumented by D.x_t and D.y_t
    * Webb (2019) eq. 13-14
    local bewley_ok = 0
    if "`bewley'" != "" {
        * Exogenous regressors (included instruments)
        local bw_exog ""
        if `p_lag' > 1 {
            forvalues i = 1/`=`p_lag'-1' {
                local bw_exog "`bw_exog' L`i'D.`depvar'"
            }
        }
        local j = 0
        foreach xv of local indepvars {
            local ++j
            if `q_`j'' > 1 {
                forvalues i = 1/`=`q_`j''-1' {
                    local bw_exog "`bw_exog' L`i'D.`xv'"
                }
            }
        }
        if "`trend'" != "" {
            local bw_exog "`bw_exog' `trendvar'"
        }
        
        * Excluded instruments for x_t levels: D.x_t and D.y_t
        local bw_excluded "D.`depvar'"
        foreach xv of local indepvars {
            local bw_excluded "`bw_excluded' D.`xv'"
        }
        
        capture qui ivregress 2sls `depvar' `bw_exog' ///
            (`indepvars' = `bw_excluded') if `touse'
        
        if !_rc {
            local j = 0
            foreach xv of local indepvars {
                local ++j
                local bw_lrm_`j' = _b[`xv']
                local bw_se_`j' = _se[`xv']
                local bw_t_`j' = `bw_lrm_`j'' / `bw_se_`j''
            }
            local bewley_ok = 1
        }
    }
    
    * Webb bounds
    _lrmbounds_cv_lrm_lookup, k(`nindep') nobs(`N') alpha(`alpha')
    local cv_lb = r(lb)
    local cv_ub = r(ub)
    
    foreach a in 0.01 0.05 0.10 {
        _lrmbounds_cv_lrm_lookup, k(`nindep') nobs(`N') alpha(`a')
        local cv_lb_`=100*`a'' = r(lb)
        local cv_ub_`=100*`a'' = r(ub)
    }
    
    * Decisions
    local j = 0
    foreach xv of local indepvars {
        local ++j
        if `bewley_ok' {
            local use_t = abs(`bw_t_`j'')
        }
        else {
            local use_t = abs(`dm_t_`j'')
        }
        if `use_t' > `cv_ub' {
            local lrm_decision_`j' "Reject H0: Significant LRR"
            local lrm_dcode_`j' "reject"
        }
        else if `use_t' < `cv_lb' {
            local lrm_decision_`j' "Fail to Reject H0: No LRR"
            local lrm_dcode_`j' "fail"
        }
        else {
            local lrm_decision_`j' "Inconclusive"
            local lrm_dcode_`j' "inconclusive"
        }
    }
    
    * Returns
    return scalar N = `N'
    return scalar k = `nindep'
    return scalar alpha = `alpha'
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar cv_lb = `cv_lb'
    return scalar cv_ub = `cv_ub'
    return scalar cv_lb_1 = `cv_lb_1'
    return scalar cv_ub_1 = `cv_ub_1'
    return scalar cv_lb_5 = `cv_lb_5'
    return scalar cv_ub_5 = `cv_ub_5'
    return scalar cv_lb_10 = `cv_lb_10'
    return scalar cv_ub_10 = `cv_ub_10'
    
    local j = 0
    foreach xv of local indepvars {
        local ++j
        return scalar dm_lrm_`j' = `dm_lrm_`j''
        return scalar dm_se_`j' = `dm_se_`j''
        return scalar dm_t_`j' = `dm_t_`j''
        if `bewley_ok' {
            return scalar bw_lrm_`j' = `bw_lrm_`j''
            return scalar bw_se_`j' = `bw_se_`j''
            return scalar bw_t_`j' = `bw_t_`j''
        }
        return local lrm_decision_`j' "`lrm_decision_`j''"
        return local lrm_dcode_`j' "`lrm_dcode_`j''"
        return local xvar_`j' "`xv'"
    }
    
    return scalar bewley_ok = `bewley_ok'
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
end


* ==============================================================================
*  FROM: _lrmbounds_graph.ado
* ==============================================================================
program define _lrmbounds_graph
    syntax , [                                  ///
        DEPVAR(string)                          ///
        INDEPVARS(string)                       ///
        NINDEP(integer 1)                       ///
        OPTLAG(integer 1)                       ///
        TREND                                   ///
        NOCONStant                              ///
        GRAPHDIR(string)                        ///
        FPSS(real 0)                            ///
        FLB(real 0)                             ///
        FUB(real 0)                             ///
        ECRATE(real 0)                          ///
        NOBS(integer 100)                       ///
        ]
    
    if "`graphdir'" == "" local graphdir "lrmbounds_graphs"
    capture mkdir "`graphdir'"
    
    * ================================================================
    *  Graph 1: LRM Forest Plot with Bounds Decision
    *  Shows each LRM with CI, color-coded by bounds decision
    * ================================================================
    capture {
        * Re-estimate to get results in memory
        local ecm_levels "L.`depvar'"
        foreach xv of local indepvars {
            local ecm_levels "`ecm_levels' L.`xv'"
        }
        local ecm_diffs ""
        foreach xv of local indepvars {
            local ecm_diffs "`ecm_diffs' D.`xv'"
        }
        if `optlag' > 1 {
            forvalues i = 1/`=`optlag'-1' {
                local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
                foreach xv of local indepvars {
                    local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
                }
            }
        }
        local trendvar ""
        if "`trend'" != "" {
            tempvar tvar
            qui gen double `tvar' = _n
            local trendvar "`tvar'"
        }
        
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        
        local ecrate_val = _b[L.`depvar']
        
        * Build dataset for forest plot
        tempname bmat Vmat
        matrix `bmat' = e(b)
        matrix `Vmat' = e(V)
        
        preserve
        clear
        qui set obs `nindep'
        qui gen str32 varname = ""
        qui gen double lrm = .
        qui gen double lrm_se = .
        qui gen double lrm_lo = .
        qui gen double lrm_hi = .
        qui gen double lrm_t = .
        qui gen int order = _n
        
        local j = 0
        foreach xv of local indepvars {
            local ++j
            
            local psi_yx = `bmat'[1, colnumb(`bmat', "L.`xv'")]
            local pos_yy = colnumb(`bmat', "L.`depvar'")
            local pos_xj = colnumb(`bmat', "L.`xv'")
            
            local lrm_val = -`psi_yx' / `ecrate_val'
            
            local var_yy = `Vmat'[`pos_yy', `pos_yy']
            local var_xj = `Vmat'[`pos_xj', `pos_xj']
            local cov_xy = `Vmat'[`pos_xj', `pos_yy']
            local g1 = -1 / `ecrate_val'
            local g2 = `psi_yx' / (`ecrate_val' * `ecrate_val')
            local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
            local se_val = sqrt(max(`var_lrm', 0))
            
            qui replace varname = "`xv'" in `j'
            qui replace lrm = `lrm_val' in `j'
            qui replace lrm_se = `se_val' in `j'
            qui replace lrm_lo = `lrm_val' - 1.96 * `se_val' in `j'
            qui replace lrm_hi = `lrm_val' + 1.96 * `se_val' in `j'
            qui replace lrm_t = abs(`lrm_val' / `se_val') in `j'
        }
        
        * Create forest plot
        twoway (rcap lrm_lo lrm_hi order, horizontal lcolor("55 71 133") lwidth(medthick)) ///
               (scatter order lrm, msymbol(D) msize(large) mcolor("220 95 60") mlcolor("55 71 133") mlwidth(thin)), ///
               yline(0, lcolor(gs10) lpattern(dash)) ///
               ylabel(1(1)`nindep', valuelabel angle(0) labsize(small)) ///
               xlabel(, labsize(small) grid glcolor(gs14)) ///
               ytitle("") xtitle("Long Run Multiplier (LRM)", size(medsmall)) ///
               title("{bf:Long-Run Multiplier Estimates}", size(medlarge), size(medium) color("55 71 133")) ///
               subtitle("Webb, Linn & Lebo (2019) Bounds Approach", size(small) color(gs6)) ///
               legend(off) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_forest, replace)
        
        qui graph export "`graphdir'/lrm_forest_plot.png", as(png) width(2400) height(1600) replace
        restore
    }
    
    * ================================================================
    *  Graph 2: PSS F-Bounds Comparison Chart
    *  Bar showing F-stat against I(0)/I(1) bounds with colored zones
    * ================================================================
    capture {
        preserve
        clear
        qui set obs 100
        qui gen double x = _n / 10
        qui gen double zone_below = 0
        qui gen double zone_between = 0
        qui gen double zone_above = 0
        
        qui replace zone_below = 1 if x <= `flb'
        qui replace zone_between = 1 if x > `flb' & x <= `fub'
        qui replace zone_above = 1 if x > `fub'
        
        * Create the bar chart
        twoway (area zone_below x if zone_below == 1, color("144 190 109%40") base(0)) ///
               (area zone_between x if zone_between == 1, color("255 193 37%40") base(0)) ///
               (area zone_above x if zone_above == 1, color("220 95 60%40") base(0)) ///
               (pci 0 `fpss' 1 `fpss', lcolor("55 71 133") lwidth(thick) lpattern(solid)), ///
               xline(`flb', lcolor("144 190 109") lwidth(medthick) lpattern(dash)) ///
               xline(`fub', lcolor("220 95 60") lwidth(medthick) lpattern(dash)) ///
               xtitle("F-statistic", size(medsmall)) ytitle("") ///
               title("{bf:PSS Bounds Test}", size(medium) color("55 71 133")) ///
               subtitle("F-statistic vs. Critical Value Bounds (5%)", size(small) color(gs6)) ///
               ylabel(none) ///
               xlabel(, labsize(small) grid glcolor(gs14)) ///
               text(0.9 `flb' "I(0) = `: display %5.3f `flb''", place(w) size(vsmall) color("144 190 109")) ///
               text(0.9 `fub' "I(1) = `: display %5.3f `fub''", place(e) size(vsmall) color("220 95 60")) ///
               text(0.5 `fpss' "F = `: display %6.3f `fpss''", place(e) size(small) color("55 71 133")) ///
               legend(off) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_fbounds, replace)
        
        qui graph export "`graphdir'/pss_fbounds.png", as(png) width(2400) height(1200) replace
        restore
    }
    
    * ================================================================
    *  Graph 3: Actual vs Fitted with Residuals
    * ================================================================
    capture {
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        tempvar fitted resid
        qui predict double `fitted', xb
        qui predict double `resid', residuals
        
        qui tsset
        local timevar "`r(timevar)'"
        
        twoway (tsline D.`depvar', lcolor("55 71 133") lwidth(medthick)) ///
               (tsline `fitted', lcolor("220 95 60") lwidth(medium) lpattern(dash)), ///
               ytitle("D.`depvar'", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:Actual vs. ECM-Fitted Values}", size(medlarge), size(medium) color("55 71 133")) ///
               subtitle("Conditional ECM: D.`depvar'", size(small) color(gs6)) ///
               legend(order(1 "Actual" 2 "Fitted") rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_actual_fit, replace)
        
        qui graph export "`graphdir'/actual_vs_fitted.png", as(png) width(2400) height(1400) replace
    }
    
    * ================================================================
    *  Graph 4: Residual Diagnostics Panel
    *  Residual time series + histogram + QQ plot
    * ================================================================
    capture {
        * Residual time series  
        twoway (tsline `resid', lcolor("55 71 133") lwidth(medium)), ///
               yline(0, lcolor("220 95 60") lwidth(thin) lpattern(dash)) ///
               ytitle("Residuals", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:ECM Residuals}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_ts, replace)
        
        * Histogram
        histogram `resid', ///
               fcolor("55 71 133%60") lcolor("55 71 133") ///
               normal normopts(lcolor("220 95 60") lwidth(medthick)) ///
               xtitle("Residuals", size(medsmall)) ///
               ytitle("Density", size(medsmall)) ///
               title("{bf:Residual Distribution}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_hist, replace)
        
        * QQ plot
        qnorm `resid', ///
               msymbol(O) msize(small) mcolor("55 71 133") ///
               rlopts(lcolor("220 95 60") lwidth(medthick)) ///
               xtitle("Theoretical Quantiles", size(medsmall)) ///
               ytitle("Sample Quantiles", size(medsmall)) ///
               title("{bf:Normal Q-Q Plot}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_qq, replace)
        
        * Combine into panel
        graph combine _lrm_resid_ts _lrm_resid_hist _lrm_resid_qq, ///
               cols(3) ///
               title("{bf:Residual Diagnostics Panel}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               name(_lrm_resid_panel, replace)
        
        qui graph export "`graphdir'/residual_diagnostics.png", as(png) width(3600) height(1200) replace
    }
    
    * ================================================================
    *  Graph 5: CUSUM Stability Plot
    * ================================================================
    capture {
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        tempvar resid2
        qui predict double `resid2', residuals
        
        local N = e(N)
        local k_p = e(rank)
        
        * Compute CUSUM
        tempvar cusum cusum_upper cusum_lower obs_id
        qui gen double `cusum' = .
        qui gen double `obs_id' = _n
        
        * Standardize residuals
        qui sum `resid2'
        local sigma = r(sd)
        
        * Recursive CUSUM
        local cumsum = 0
        forvalues i = 1/`N' {
            local rv = `resid2'[`i']
            if !missing(`rv') {
                local cumsum = `cumsum' + `rv' / `sigma'
                qui replace `cusum' = `cumsum' in `i'
            }
        }
        
        * 5% significance boundaries
        local a = 0.948
        qui gen double `cusum_upper' = `a' * sqrt(`N' - `k_p') + 2 * `a' * (`obs_id' - `k_p') / sqrt(`N' - `k_p')
        qui gen double `cusum_lower' = -`cusum_upper'
        
        twoway (tsline `cusum', lcolor("55 71 133") lwidth(medthick)) ///
               (tsline `cusum_upper', lcolor("220 95 60") lwidth(medium) lpattern(dash)) ///
               (tsline `cusum_lower', lcolor("220 95 60") lwidth(medium) lpattern(dash)), ///
               ytitle("CUSUM", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:CUSUM Stability Test}", size(medlarge), size(medium) color("55 71 133")) ///
               subtitle("5% Significance Boundaries", size(small) color(gs6)) ///
               legend(order(1 "CUSUM" 2 "5% Boundary") rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_cusum, replace)
        
        qui graph export "`graphdir'/cusum_stability.png", as(png) width(2400) height(1400) replace
    }
    
    * ================================================================
    *  Graph 6: Dynamic Multiplier Plot
    *  Cumulative effect of a unit change in x over time
    * ================================================================
    capture {
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        
        local ecrate_dm = _b[L.`depvar']
        
        preserve
        clear
        local nperiods = 30
        qui set obs `nperiods'
        qui gen int period = _n - 1
        
        * For each x variable, compute dynamic multiplier
        local j = 0
        foreach xv of local indepvars {
            local ++j
            
            * Short-run effect (contemporaneous): beta_0 = coeff on D.xv
            capture local sr = `bmat'[1, colnumb(`bmat', "D.`xv'")]
            if _rc local sr = 0
            
            * Long-run multiplier
            local psi_yx = `bmat'[1, colnumb(`bmat', "L.`xv'")]
            local lr = -`psi_yx' / `ecrate_dm'
            
            * Dynamic path: cumulative effect converges from sr to lr
            * Using: M_h = LRM * (1 - (1+ecr)^h) + sr * (1+ecr)^(h-1)
            qui gen double dm_`j' = .
            qui replace dm_`j' = 0 in 1
            
            forvalues h = 1/`=`nperiods'-1' {
                local cum = `lr' * (1 - (1 + `ecrate_dm')^`h')
                qui replace dm_`j' = `cum' in `=`h'+1'
            }
        }
        
        * Build plot command
        local plotcmd ""
        local legorder ""
        local colors `" "55 71 133" "220 95 60" "144 190 109" "178 102 178" "70 130 180" "'
        
        local j = 0
        foreach xv of local indepvars {
            local ++j
            local col : word `j' of `colors'
            if "`col'" == "" local col "55 71 133"
            local plotcmd "`plotcmd' (line dm_`j' period, lcolor("`col'") lwidth(medthick))"
            local legorder "`legorder' `j' `" "`xv'" "'"
        }
        
        twoway `plotcmd', ///
               ytitle("Cumulative Effect", size(medsmall)) ///
               xtitle("Periods After Shock", size(medsmall)) ///
               title("{bf:Dynamic Multiplier Paths}", size(medium) color("55 71 133")) ///
               subtitle("Cumulative effect of a unit change in each x", size(small) color(gs6)) ///
               xlabel(0(5)30, labsize(small) grid glcolor(gs14)) ///
               legend(order(`legorder') rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(medium)) ///
               plotregion(margin(small)) ///
               name(_lrm_dynmult, replace)
        
        qui graph export "`graphdir'/dynamic_multipliers.png", as(png) width(2400) height(1400) replace
        restore
    }
    
    di ""
    di as res "  Graphs saved to: `graphdir'/"
    di as txt "    lrm_forest_plot.png       — LRM estimates with 95% CI"
    di as txt "    pss_fbounds.png           — F-statistic vs. bounds"
    di as txt "    actual_vs_fitted.png      — Actual vs. fitted values"
    di as txt "    residual_diagnostics.png  — Residual panel (time series, histogram, QQ)"
    di as txt "    cusum_stability.png       — CUSUM stability test"
    di as txt "    dynamic_multipliers.png   — Dynamic multiplier paths"
end


* ==============================================================================
*  MAIN COMMAND
* ==============================================================================
program define lrmbounds, rclass
    version 14.0
    syntax varlist(ts min=2) [if] [in], [       ///
        MAXlag(integer 4)                        ///
        LAGSEL(string)                           ///
        LAGS(numlist integer >=0)                 ///
        ARDL(numlist integer >=0)                 ///
        TREND                                    ///
        NOCONStant                               ///
        ROBUST                                   ///
        BEWLEY                                   ///
        LEVEL(cilevel)                           ///
        NOSTARs                                  ///
        NODIAGnostics                            ///
        GRAPH                                    ///
        GRAPHDir(string)                         ///
        ]
    
    marksample touse
    
    * Parse variables
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    local stars = ("`nostars'" == "")
    
    * Check tsset
    qui tsset
    local timevar "`r(timevar)'"
    
    * Count effective observations
    qui count if `touse'
    local N_total = r(N)
    
    di ""
    di as txt "{hline 90}"
    di as res _col(4) "{bf:LRMBOUNDS}" _col(20) as txt ///
        "Bounds Approach to Inference Using the Long Run Multiplier"
    di as txt _col(20) "Webb, Linn & Lebo (2019, {it:Political Analysis}; 2020, {it:Journal of Politics})"
    di as txt "{hline 90}"
    di ""
    
    * ================================================================
    *  TABLE 1: MODEL SPECIFICATION
    * ================================================================
    di as res "  {bf:Model Specification}"
    di as txt "  {hline 60}"
    di as txt "  Dependent variable:   " as res "`depvar'"
    di as txt "  Independent variables: " as res "`indepvars'"
    di as txt "  Number of regressors:  " as res "`nindep'"
    di as txt "  Observations:          " as res "`N_total'"
    if "`trend'" != "" {
        di as txt "  Deterministics:        " as res "Unrestricted constant + trend (Case V)"
    }
    else {
        di as txt "  Deterministics:        " as res "Unrestricted constant (Case III)"
    }
    if "`robust'" != "" {
        di as txt "  Standard errors:       " as res "Heteroskedasticity-robust (HC1)"
    }
    else {
        di as txt "  Standard errors:       " as res "OLS"
    }
    di ""
    
    * ================================================================
    *  STEP 1: ESTIMATE THE CONDITIONAL ECM
    *  Webb (2019) eq. (5): 
    *  Dy_t = c + psi_yy*y_{t-1} + psi_yx*x_{t-1} + delta*Dz_{t-i} + u_t
    * ================================================================
    * Pass ARDL spec if provided
    local ardl_opt ""
    if "`ardl'" != "" {
        local ardl_opt "ardl(`ardl')"
    }
    
    _lrmbounds_estimate `varlist' if `touse', ///
        maxlag(`maxlag') lagsel("`lagsel'") ///
        `trend' `noconstant' `robust' ///
        lags(`lags') `ardl_opt' 
    
    local optlag = r(optlag)
    local ardl_spec = r(ardl_spec)
    local N = r(N)
    local k = r(k)
    local r2 = r(r2)
    local r2_a = r(r2_a)
    local rmse = r(rmse)
    local ll = r(ll)
    local F_model = r(F_model)
    local k_total = r(k_total)
    local ecr = r(ecr)
    local ecr_se = r(ecr_se)
    local ecr_t = r(ecr_t)
    local ecr_p = r(ecr_p)
    local lagsel_used = r(lagsel)
    
    * Store LRM values
    forvalues j = 1/`nindep' {
        local lrm_`j' = r(lrm_`j')
        local lrm_se_`j' = r(lrm_se_`j')
        local lrm_t_`j' = r(lrm_t_`j')
        local lrm_p_`j' = r(lrm_p_`j')
        local psi_yx_`j' = r(psi_yx_`j')
        local psi_yx_se_`j' = r(psi_yx_se_`j')
        local xvar_`j' = r(xvar_`j')
    }
    
    local ecm_levels = r(ecm_levels)
    local ecm_diffs = r(ecm_diffs)
    local allregs = r(allregs)
    
    * ================================================================
    *  TABLE 2: ECM ESTIMATION RESULTS
    * ================================================================
    di as res "  {bf:Table 1. Conditional ECM Estimation Results}"
    di as txt "  {hline 86}"
    di as txt "  ARDL order: " as res "(`ardl_spec')" as txt " (selected by " as res upper("`lagsel_used'") as txt ")" ///
        as txt _col(50) "Obs = " as res "`N'" ///
        as txt "   R² = " as res %6.4f `r2'
    di as txt _col(50) "F = " as res %8.3f `F_model' ///
        as txt "   RMSE = " as res %8.4f `rmse'
    di as txt "  {hline 86}"
    
    * Re-estimate to display full coefficient table
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    local ecm_levels_full "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels_full "`ecm_levels_full' L.`xv'"
    }
    local ecm_diffs_full ""
    foreach xv of local indepvars {
        local ecm_diffs_full "`ecm_diffs_full' D.`xv'"
    }
    if `optlag' > 1 {
        forvalues i = 1/`=`optlag'-1' {
            local ecm_diffs_full "`ecm_diffs_full' L`i'D.`depvar'"
            foreach xv of local indepvars {
                local ecm_diffs_full "`ecm_diffs_full' L`i'D.`xv'"
            }
        }
    }
    
    if "`robust'" != "" {
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse', `noconstant'
    }
    
    * Display coefficient table
    local totw = 86
    di as txt "  " %~14s "Variable" "{c |}" ///
        %~12s "Coef." %~12s "Std. Err." %~10s "t" %~10s "P>|t|" %~12s "[95% CI]"
    di as txt "  {hline `totw'}"
    
    * Panel A: Long-run (ECM) coefficients
    di as res _col(4) "{it:Long-run coefficients (Lagged levels)}"
    
    * ECR (psi_yy)
    local ci_lo = `ecr' - invttail(`N' - `k_total', 0.025) * `ecr_se'
    local ci_hi = `ecr' + invttail(`N' - `k_total', 0.025) * `ecr_se'
    local star ""
    if `stars' {
        _lrmbounds_stars `ecr_p'
        local star "`s(s)'"
    }
    di as txt "  " %~14s "L.`depvar'" "{c |}" ///
        as res %11.5f `ecr' "  " %11.5f `ecr_se' "  " %9.3f `ecr_t' "  " %8.4f `ecr_p' ///
        "  " %10.4f `ci_lo' "  " %10.4f `ci_hi' "`star'"
    
    * psi_yx for each x
    forvalues j = 1/`nindep' {
        local b = `psi_yx_`j''
        local se = `psi_yx_se_`j''
        local t = `b' / `se'
        local p = 2 * ttail(`N' - `k_total', abs(`t'))
        local lo = `b' - invttail(`N' - `k_total', 0.025) * `se'
        local hi = `b' + invttail(`N' - `k_total', 0.025) * `se'
        local star ""
        if `stars' {
            _lrmbounds_stars `p'
            local star "`s(s)'"
        }
        di as txt "  " %~14s "L.`xvar_`j''" "{c |}" ///
            as res %11.5f `b' "  " %11.5f `se' "  " %9.3f `t' "  " %8.4f `p' ///
            "  " %10.4f `lo' "  " %10.4f `hi' "`star'"
    }
    
    * Panel B: Short-run coefficients
    di as txt "  {hline `totw'}"
    di as res _col(4) "{it:Short-run coefficients (First differences)}"
    
    * Contemporaneous Dx terms
    foreach xv of local indepvars {
        local b = _b[D.`xv']
        local se = _se[D.`xv']
        if `se' > 0 {
            local t = `b' / `se'
            local p = 2 * ttail(`N' - `k_total', abs(`t'))
            local lo = `b' - invttail(`N' - `k_total', 0.025) * `se'
            local hi = `b' + invttail(`N' - `k_total', 0.025) * `se'
            local star ""
            if `stars' {
                _lrmbounds_stars `p'
                local star "`s(s)'"
            }
            di as txt "  " %~14s "D.`xv'" "{c |}" ///
                as res %11.5f `b' "  " %11.5f `se' "  " %9.3f `t' "  " %8.4f `p' ///
                "  " %10.4f `lo' "  " %10.4f `hi' "`star'"
        }
    }
    
    * Lagged difference terms
    if `optlag' > 1 {
        forvalues i = 1/`=`optlag'-1' {
            capture local b = _b[L`i'D.`depvar']
            if !_rc {
                local se = _se[L`i'D.`depvar']
                if `se' > 0 {
                    local t = `b' / `se'
                    local p = 2 * ttail(`N' - `k_total', abs(`t'))
                    local lo = `b' - invttail(`N' - `k_total', 0.025) * `se'
                    local hi = `b' + invttail(`N' - `k_total', 0.025) * `se'
                    local star ""
                    if `stars' {
                        _lrmbounds_stars `p'
                        local star "`s(s)'"
                    }
                    di as txt "  " %~14s "L`i'D.`depvar'" "{c |}" ///
                        as res %11.5f `b' "  " %11.5f `se' "  " %9.3f `t' "  " %8.4f `p' ///
                        "  " %10.4f `lo' "  " %10.4f `hi' "`star'"
                }
            }
            foreach xv of local indepvars {
                capture local b = _b[L`i'D.`xv']
                if !_rc {
                    local se = _se[L`i'D.`xv']
                    if `se' > 0 {
                        local t = `b' / `se'
                        local p = 2 * ttail(`N' - `k_total', abs(`t'))
                        local lo = `b' - invttail(`N' - `k_total', 0.025) * `se'
                        local hi = `b' + invttail(`N' - `k_total', 0.025) * `se'
                        local star ""
                        if `stars' {
                            _lrmbounds_stars `p'
                            local star "`s(s)'"
                        }
                        di as txt "  " %~14s "L`i'D.`xv'" "{c |}" ///
                            as res %11.5f `b' "  " %11.5f `se' "  " %9.3f `t' "  " %8.4f `p' ///
                            "  " %10.4f `lo' "  " %10.4f `hi' "`star'"
                    }
                }
            }
        }
    }
    
    * Constant and trend
    capture local b = _b[_cons]
    if !_rc {
        local se = _se[_cons]
        if `se' > 0 {
            local t = `b' / `se'
            local p = 2 * ttail(`N' - `k_total', abs(`t'))
            local star ""
            if `stars' {
                _lrmbounds_stars `p'
                local star "`s(s)'"
            }
            di as txt "  {hline `totw'}"
            di as txt "  " %~14s "_cons" "{c |}" ///
                as res %11.5f `b' "  " %11.5f `se' "  " %9.3f `t' "  " %8.4f `p' "`star'"
        }
    }
    
    di as txt "  {hline `totw'}"
    if `stars' di as txt "  ***, **, * denote significance at 1%, 5%, 10% levels."
    di ""
    
    * ================================================================
    *  TABLE 3: PSS BOUNDS TEST RESULTS
    *  F-bounds test (PSS 2001) and ECR t-bounds test
    * ================================================================
    _lrmbounds_ftest `varlist' if `touse', ///
        optlag(`optlag') `trend' `noconstant' `robust'
    
    local F_pss = r(F_pss)
    local f_decision = r(f_decision)
    local f_dcode = r(f_dcode)
    local f_lb_1 = r(f_lb_1)
    local f_ub_1 = r(f_ub_1)
    local f_lb_5 = r(f_lb_5)
    local f_ub_5 = r(f_ub_5)
    local f_lb_10 = r(f_lb_10)
    local f_ub_10 = r(f_ub_10)
    
    local ecr_t_val = r(ecr_t)
    local t_decision = r(t_decision)
    local t_dcode = r(t_dcode)
    local t_lb_1 = r(t_lb_1)
    local t_ub_1 = r(t_ub_1)
    local t_lb_5 = r(t_lb_5)
    local t_ub_5 = r(t_ub_5)
    local t_lb_10 = r(t_lb_10)
    local t_ub_10 = r(t_ub_10)
    
    local equil_type = r(equil_type)
    local equil_code = r(equil_code)
    local pss_case = r(case)
    
    di as res "  {bf:Table 2. PSS Bounds Test for Level Relationships}"
    di as txt "  {hline 72}"
    di ""
    
    * F-test panel
    di as res "  {bf:Panel A: F-Bounds Test}"
    di as txt "  H0: No level relationship (psi_yy = psi_yx = 0)"
    di as txt "  k = `nindep', Case `=cond(`pss_case'==5, "V", "III")'"
    di as txt "  {hline 72}"
    di as txt "                    " %~14s "I(0) Bound" %~14s "I(1) Bound"
    di as txt "  {hline 72}"
    di as txt "  10% level         " as res %14.3f `f_lb_10' %14.3f `f_ub_10'
    di as txt "   5% level         " as res %14.3f `f_lb_5' %14.3f `f_ub_5'
    di as txt "   1% level         " as res %14.3f `f_lb_1' %14.3f `f_ub_1'
    di as txt "  {hline 72}"
    di as txt "  F-statistic:      " as res %14.4f `F_pss'
    di ""
    
    * Color-coded decision
    if "`f_dcode'" == "reject" {
        di as res "  {bf:Decision:} " as res "`f_decision'"
    }
    else if "`f_dcode'" == "fail" {
        di as err "  {bf:Decision:} " as txt "`f_decision'"
    }
    else {
        di as txt "  {bf:Decision:} " as res "{bf:`f_decision'}"
    }
    di ""
    
    * ECR t-test panel
    di as res "  {bf:Panel B: ECR t-Bounds Test}"
    di as txt "  H0: No error correction (psi_yy = 0)"
    di as txt "  {hline 72}"
    di as txt "                    " %~14s "I(0) Bound" %~14s "I(1) Bound"
    di as txt "  {hline 72}"
    di as txt "  10% level         " as res %14.3f `t_lb_10' %14.3f `t_ub_10'
    di as txt "   5% level         " as res %14.3f `t_lb_5' %14.3f `t_ub_5'
    di as txt "   1% level         " as res %14.3f `t_lb_1' %14.3f `t_ub_1'
    di as txt "  {hline 72}"
    di as txt "  EC rate (psi_yy): " as res %14.5f `ecr' as txt "   t = " as res %8.3f `ecr_t_val'
    di ""
    if "`t_dcode'" == "reject" {
        di as res "  {bf:Decision:} " as res "`t_decision'"
    }
    else {
        di as txt "  {bf:Decision:} `t_decision'"
    }
    di ""
    
    * ================================================================
    *  TABLE 4: DEGENERATE EQUILIBRIUM CHECK
    *  Webb (2019) Table 1
    * ================================================================
    di as res "  {bf:Table 3. Equilibrium Classification (Webb et al. 2019, Table 1)}"
    di as txt "  {hline 72}"
    di as txt "  Type: " as res "`equil_type'"
    di ""
    if "`equil_code'" == "valid" {
        di as res "  => Both psi_yy ≠ 0 and psi_yx ≠ 0: Valid long-run equilibrium"
        di as txt "     The variables are in a meaningful long-run relationship."
    }
    else if "`equil_code'" == "nonsense" {
        di as err "  => psi_yy = 0 but psi_yx ≠ 0: DEGENERATE (Nonsense) equilibrium"
        di as txt "     y is a unit root but NOT cointegrated with x."
        di as txt "     The apparent relationship is spurious."
    }
    else if "`equil_code'" == "degenerate" {
        di as txt "  => psi_yy ≠ 0 but psi_yx = 0: DEGENERATE equilibrium"
        di as txt "     y has its own equilibrium but is independent of x."
    }
    else {
        di as txt "  => Unable to determine (F-test null not rejected or neither"
        di as txt "     psi_yy nor psi_yx is individually significant)."
    }
    di ""
    
    * ================================================================
    *  TABLE 5: LRM BOUNDS TEST (CORE WEBB 2019 INNOVATION)
    *  Webb, Linn & Lebo (2019) Tables 3-6
    * ================================================================
    _lrmbounds_lrm `varlist' if `touse', ///
        optlag(`optlag') ardlspec(`ardl_spaces') `trend' `noconstant' `robust' `bewley' alpha(0.05)
    
    local cv_lb_1 = r(cv_lb_1)
    local cv_ub_1 = r(cv_ub_1)
    local cv_lb_5 = r(cv_lb_5)
    local cv_ub_5 = r(cv_ub_5)
    local cv_lb_10 = r(cv_lb_10)
    local cv_ub_10 = r(cv_ub_10)
    local bewley_ok = r(bewley_ok)
    
    * Store LRM bounds results
    forvalues j = 1/`nindep' {
        local dm_lrm_`j' = r(dm_lrm_`j')
        local dm_se_`j' = r(dm_se_`j')
        local dm_t_`j' = r(dm_t_`j')
        if `bewley_ok' {
            local bw_lrm_`j' = r(bw_lrm_`j')
            local bw_se_`j' = r(bw_se_`j')
            local bw_t_`j' = r(bw_t_`j')
        }
        local lrm_decision_`j' = r(lrm_decision_`j')
        local lrm_dcode_`j' = r(lrm_dcode_`j')
    }
    
    di as res "  {bf:Table 4. Long Run Multiplier (LRM) Bounds Test}"
    di as txt "  {hline 86}"
    di ""
    
    * Display Webb bounds
    di as txt "  Critical Value Bounds (|t| on LRM): T = `N', k = `nindep'"
    di as txt "  {hline 50}"
    di as txt "                    " %~14s "Lower Bound" %~14s "Upper Bound"
    di as txt "  {hline 50}"
    di as txt "  10% level         " as res %14.3f `cv_lb_10' %14.3f `cv_ub_10'
    di as txt "   5% level         " as res %14.3f `cv_lb_5' %14.3f `cv_ub_5'
    di as txt "   1% level         " as res %14.3f `cv_lb_1' %14.3f `cv_ub_1'
    di as txt "  {hline 50}"
    di ""
    
    * LRM estimates table
    di as txt "  {hline 86}"
    if `bewley_ok' {
        di as txt "  " %-14s "Variable" "{c |}" ///
            %~10s "LRM(DM)" %~10s "SE(DM)" %~8s "t(DM)" ///
            %~10s "LRM(BW)" %~10s "SE(BW)" %~8s "t(BW)" %~12s "Decision"
    }
    else {
        di as txt "  " %-14s "Variable" "{c |}" ///
            %~12s "LRM" %~12s "Std. Err." %~10s "|t|" %~16s "Decision (5%)"
    }
    di as txt "  {hline 86}"
    
    forvalues j = 1/`nindep' {
        local xv "`xvar_`j''"
        
        if `bewley_ok' {
            * Display both delta method and Bewley results
            di as txt "  " %-14s "`xv'" "{c |}" ///
                as res %10.4f `dm_lrm_`j'' "  " %10.4f `dm_se_`j'' "  " %8.3f abs(`dm_t_`j'') ///
                "  " %10.4f `bw_lrm_`j'' "  " %10.4f `bw_se_`j'' "  " %8.3f abs(`bw_t_`j'') _continue
        }
        else {
            di as txt "  " %-14s "`xv'" "{c |}" ///
                as res %12.5f `dm_lrm_`j'' "  " %12.5f `dm_se_`j'' "  " %10.3f abs(`dm_t_`j'') _continue
        }
        
        * Color-coded decision
        if "`lrm_dcode_`j''" == "reject" {
            di as res "  {bf:Signif.}" _continue
        }
        else if "`lrm_dcode_`j''" == "fail" {
            di as txt "  Not Signif." _continue
        }
        else {
            di as res "  {bf:Incon.}" _continue
        }
        di ""
    }
    di as txt "  {hline 86}"
    di as txt "  DM = Delta Method; BW = Bewley (1979) IV. Decision based on 5% Webb bounds."
    di as txt "  Signif. = |t| > Upper Bound; Not Signif. = |t| < Lower Bound; Incon. = between."
    di ""
    
    * Interpretation
    di as res "  {bf:Interpretation Guide (Webb et al. 2019, 2020):}"
    di as txt "  {hline 72}"
    di as txt "  • If |t_LRM| > Upper Bound: Reject H0 — significant long-run"
    di as txt "    relationship REGARDLESS of whether variables are I(0) or I(1)."
    di as txt "  • If |t_LRM| < Lower Bound: Fail to reject — no evidence of a"
    di as txt "    long-run relationship under ANY integration assumption."
    di as txt "  • If Lower < |t_LRM| < Upper: INCONCLUSIVE — the inference"
    di as txt "    depends on the (unknown) integration order of the variables."
    di as txt "  {hline 72}"
    di ""
    
    * ================================================================
    *  TABLE 6: DIAGNOSTIC TESTS
    * ================================================================
    if "`nodiagnostics'" == "" {
        di as res "  {bf:Table 5. Diagnostic Tests}"
        di as txt "  {hline 60}"
        
        * Re-estimate for diagnostics
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse', `noconstant'
        
        * Breusch-Godfrey serial correlation (manual LM test)
        tempvar resid_diag
        qui predict double `resid_diag', residuals
        
        * BG lag 1
        qui regress `resid_diag' `ecm_levels_full' `ecm_diffs_full' `trendvar' L.`resid_diag' if `touse'
        local bg_n = e(N)
        local bg_r2_1 = e(r2)
        local bg_chi2_1 = `bg_n' * `bg_r2_1'
        local bg_p_1 = chi2tail(1, `bg_chi2_1')
        
        di as txt "  Breusch-Godfrey (1 lag):  chi2 = " as res %8.3f `bg_chi2_1' ///
            as txt "   p = " as res %6.4f `bg_p_1' _continue
        if `bg_p_1' > 0.05 {
            di as res "  [No serial corr.]"
        }
        else {
            di as err "  [Serial corr. detected]"
        }
        
        * BG lag 4
        qui regress `resid_diag' `ecm_levels_full' `ecm_diffs_full' `trendvar' ///
            L(1/4).`resid_diag' if `touse'
        local bg_r2_4 = e(r2)
        local bg_chi2_4 = `bg_n' * `bg_r2_4'
        local bg_p_4 = chi2tail(4, `bg_chi2_4')
        
        di as txt "  Breusch-Godfrey (4 lags): chi2 = " as res %8.3f `bg_chi2_4' ///
            as txt "   p = " as res %6.4f `bg_p_4' _continue
        if `bg_p_4' > 0.05 {
            di as res "  [No serial corr.]"
        }
        else {
            di as err "  [Serial corr. detected]"
        }
        
        * Breusch-Pagan heteroskedasticity
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse'
        tempvar bp_resid bp_resid_sq bp_resid_norm
        qui predict double `bp_resid', residuals
        qui gen double `bp_resid_sq' = `bp_resid'^2
        qui sum `bp_resid_sq', meanonly
        local sig2 = r(mean)
        qui gen double `bp_resid_norm' = `bp_resid_sq' / `sig2'
        qui regress `bp_resid_norm' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse'
        local bp_n = e(N)
        local bp_r2 = e(r2)
        local bp_chi2 = `bp_n' * `bp_r2' / 2
        local bp_df = e(rank) - 1
        if `bp_df' < 1 local bp_df = 1
        local bp_p = chi2tail(`bp_df', `bp_chi2')
        
        di as txt "  Breusch-Pagan:            chi2 = " as res %8.3f `bp_chi2' ///
            as txt "   p = " as res %6.4f `bp_p' _continue
        if `bp_p' > 0.05 {
            di as res "  [Homoskedastic]"
        }
        else {
            di as err "  [Heteroskedastic]"
        }
        
        * Ramsey RESET
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse'
        tempvar yhat yhat2 yhat3
        qui predict double `yhat'
        qui gen double `yhat2' = `yhat'^2
        qui gen double `yhat3' = `yhat'^3
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' `yhat2' `yhat3' if `touse'
        local reset_rss_u = e(rss)
        local reset_n = e(N)
        local reset_k_u = e(rank)
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse'
        local reset_rss_r = e(rss)
        local reset_k_r = e(rank)
        local reset_f = ((`reset_rss_r' - `reset_rss_u') / 2) / (`reset_rss_u' / (`reset_n' - `reset_k_u'))
        local reset_p = Ftail(2, `reset_n' - `reset_k_u', `reset_f')
        
        di as txt "  Ramsey RESET:             F =  " as res %8.3f `reset_f' ///
            as txt "   p = " as res %6.4f `reset_p' _continue
        if `reset_p' > 0.05 {
            di as res "  [No misspec.]"
        }
        else {
            di as err "  [Misspecification]"
        }
        
        * Jarque-Bera normality
        qui regress D.`depvar' `ecm_levels_full' `ecm_diffs_full' `trendvar' if `touse', `noconstant'
        tempvar resid_jb
        qui predict double `resid_jb', residuals
        qui sum `resid_jb', detail
        local jb_n = r(N)
        local jb_skew = r(skewness)
        local jb_kurt = r(kurtosis)
        local jb_stat = (`jb_n'/6) * (`jb_skew'^2 + ((`jb_kurt' - 3)^2)/4)
        local jb_p = chi2tail(2, `jb_stat')
        
        di as txt "  Jarque-Bera Normality:    JB =  " as res %8.3f `jb_stat' ///
            as txt "   p = " as res %6.4f `jb_p' _continue
        if `jb_p' > 0.05 {
            di as res "  [Normal]"
        }
        else {
            di as err "  [Non-normal]"
        }
        
        di as txt "  {hline 60}"
        di ""
    }
    
    * ================================================================
    *  GRAPHS
    * ================================================================
    if "`graph'" != "" {
        _lrmbounds_graph, ///
            depvar(`depvar') indepvars(`indepvars') nindep(`nindep') ///
            optlag(`optlag') `trend' `noconstant' ///
            graphdir("`graphdir'") ///
            fpss(`F_pss') flb(`f_lb_5') fub(`f_ub_5') ///
            ecrate(`ecr') nobs(`N')
    }
    
    * ================================================================
    *  SUMMARY BOX
    * ================================================================
    di as txt "{hline 90}"
    di as res _col(4) "{bf:SUMMARY}"
    di as txt "{hline 90}"
    di as txt "  PSS F-Bounds Test:     " _continue
    if "`f_dcode'" == "reject" di as res "{bf:Level relationship EXISTS} (F = `: display %6.3f `F_pss'')"
    else if "`f_dcode'" == "fail" di as err "{bf:No level relationship} (F = `: display %6.3f `F_pss'')"
    else di as res "{bf:Inconclusive} (F = `: display %6.3f `F_pss'')"
    
    di as txt "  ECR t-Bounds Test:     " _continue
    if "`t_dcode'" == "reject" di as res "{bf:Error correction confirmed} (ECR = `: display %6.4f `ecr'')"
    else if "`t_dcode'" == "fail" di as err "{bf:No error correction} (ECR = `: display %6.4f `ecr'')"
    else di as res "{bf:Inconclusive} (ECR = `: display %6.4f `ecr'')"
    
    di as txt "  Equilibrium Type:      " as res "`equil_type'"
    di ""
    di as txt "  LRM Bounds Decisions (5% Webb bounds):"
    forvalues j = 1/`nindep' {
        di as txt "    `xvar_`j'': " _continue
        if "`lrm_dcode_`j''" == "reject" {
            di as res "{bf:Significant LRR} (LRM = `: display %8.4f `dm_lrm_`j''', |t| = `: display %6.3f abs(`dm_t_`j'')')"
        }
        else if "`lrm_dcode_`j''" == "fail" {
            di as txt "No LRR (LRM = `: display %8.4f `dm_lrm_`j''', |t| = `: display %6.3f abs(`dm_t_`j'')')"
        }
        else {
            di as res "{bf:Inconclusive} (LRM = `: display %8.4f `dm_lrm_`j''', |t| = `: display %6.3f abs(`dm_t_`j'')')"
        }
    }
    di as txt "{hline 90}"
    di ""
    
    * ================================================================
    *  RETURN RESULTS
    * ================================================================
    * Estimation
    return scalar N = `N'
    return scalar k = `nindep'
    return scalar optlag = `optlag'
    return scalar r2 = `r2'
    return scalar r2_a = `r2_a'
    return scalar rmse = `rmse'
    return scalar ll = `ll'
    
    * ECR
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar ecr_t = `ecr_t'
    
    * F-bounds
    return scalar F_pss = `F_pss'
    return scalar f_lb_5 = `f_lb_5'
    return scalar f_ub_5 = `f_ub_5'
    return scalar f_lb_1 = `f_lb_1'
    return scalar f_ub_1 = `f_ub_1'
    return scalar f_lb_10 = `f_lb_10'
    return scalar f_ub_10 = `f_ub_10'
    
    * ECR t-bounds
    return scalar t_lb_5 = `t_lb_5'
    return scalar t_ub_5 = `t_ub_5'
    
    * Webb LRM bounds
    return scalar cv_lb_5 = `cv_lb_5'
    return scalar cv_ub_5 = `cv_ub_5'
    return scalar cv_lb_1 = `cv_lb_1'
    return scalar cv_ub_1 = `cv_ub_1'
    return scalar cv_lb_10 = `cv_lb_10'
    return scalar cv_ub_10 = `cv_ub_10'
    
    * LRMs
    forvalues j = 1/`nindep' {
        return scalar lrm_`j' = `dm_lrm_`j''
        return scalar lrm_se_`j' = `dm_se_`j''
        return scalar lrm_t_`j' = `dm_t_`j''
        return local xvar_`j' "`xvar_`j''"
        return local lrm_decision_`j' "`lrm_decision_`j''"
        return local lrm_dcode_`j' "`lrm_dcode_`j''"
    }
    
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
    return local f_decision "`f_decision'"
    return local f_dcode "`f_dcode'"
    return local t_decision "`t_decision'"
    return local t_dcode "`t_dcode'"
    return local equil_type "`equil_type'"
    return local equil_code "`equil_code'"
end
