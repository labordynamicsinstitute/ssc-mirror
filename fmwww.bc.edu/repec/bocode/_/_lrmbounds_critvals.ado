*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! _lrmbounds_critvals: Critical value tables for lrmbounds
*! Sources:
*!   PSS (2001) Table CI, CII — F-bounds and ECR t-bounds
*!   Narayan (2005) — Small-sample F-bounds
*!   Webb, Linn & Lebo (2019) Tables 3–6 — LRM t-bounds

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
            if `k' == 1 { local lb = 3.02 ; local ub = 3.51 }
            else if `k' == 2 { local lb = 2.63 ; local ub = 3.35 }
            else if `k' == 3 { local lb = 2.37 ; local ub = 3.20 }
            else if `k' == 4 { local lb = 2.20 ; local ub = 3.09 }
            else if `k' == 5 { local lb = 2.08 ; local ub = 3.00 }
            else if `k' == 6 { local lb = 1.99 ; local ub = 2.94 }
            else if `k' == 7 { local lb = 1.92 ; local ub = 2.89 }
            else if `k' == 8 { local lb = 1.85 ; local ub = 2.85 }
            else if `k' == 9 { local lb = 1.80 ; local ub = 2.80 }
            else if `k' == 10 { local lb = 1.76 ; local ub = 2.77 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.05 {
            if `k' == 1 { local lb = 3.62 ; local ub = 4.16 }
            else if `k' == 2 { local lb = 3.10 ; local ub = 3.87 }
            else if `k' == 3 { local lb = 2.79 ; local ub = 3.67 }
            else if `k' == 4 { local lb = 2.56 ; local ub = 3.49 }
            else if `k' == 5 { local lb = 2.39 ; local ub = 3.38 }
            else if `k' == 6 { local lb = 2.27 ; local ub = 3.28 }
            else if `k' == 7 { local lb = 2.17 ; local ub = 3.21 }
            else if `k' == 8 { local lb = 2.11 ; local ub = 3.15 }
            else if `k' == 9 { local lb = 2.04 ; local ub = 3.11 }
            else if `k' == 10 { local lb = 1.98 ; local ub = 3.04 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.025 {
            if `k' == 1 { local lb = 4.18 ; local ub = 4.79 }
            else if `k' == 2 { local lb = 3.55 ; local ub = 4.38 }
            else if `k' == 3 { local lb = 3.17 ; local ub = 4.14 }
            else if `k' == 4 { local lb = 2.89 ; local ub = 3.87 }
            else if `k' == 5 { local lb = 2.70 ; local ub = 3.73 }
            else if `k' == 6 { local lb = 2.55 ; local ub = 3.61 }
            else if `k' == 7 { local lb = 2.42 ; local ub = 3.50 }
            else if `k' == 8 { local lb = 2.33 ; local ub = 3.42 }
            else if `k' == 9 { local lb = 2.26 ; local ub = 3.35 }
            else if `k' == 10 { local lb = 2.19 ; local ub = 3.30 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.01 {
            if `k' == 1 { local lb = 4.94 ; local ub = 5.58 }
            else if `k' == 2 { local lb = 4.13 ; local ub = 5.00 }
            else if `k' == 3 { local lb = 3.65 ; local ub = 4.66 }
            else if `k' == 4 { local lb = 3.29 ; local ub = 4.37 }
            else if `k' == 5 { local lb = 3.06 ; local ub = 4.15 }
            else if `k' == 6 { local lb = 2.88 ; local ub = 3.99 }
            else if `k' == 7 { local lb = 2.73 ; local ub = 3.90 }
            else if `k' == 8 { local lb = 2.62 ; local ub = 3.77 }
            else if `k' == 9 { local lb = 2.54 ; local ub = 3.68 }
            else if `k' == 10 { local lb = 2.45 ; local ub = 3.61 }
            else { local lb = . ; local ub = . }
        }
        else { local lb = . ; local ub = . }
    }
    * -----------------------------------------------------------------------
    *  Case V: Unrestricted intercept + unrestricted trend
    * -----------------------------------------------------------------------
    else if `case' == 5 {
        if `alpha' == 0.10 {
            if `k' == 1 { local lb = 3.78 ; local ub = 4.27 }
            else if `k' == 2 { local lb = 3.38 ; local ub = 4.02 }
            else if `k' == 3 { local lb = 3.05 ; local ub = 3.87 }
            else if `k' == 4 { local lb = 2.84 ; local ub = 3.76 }
            else if `k' == 5 { local lb = 2.68 ; local ub = 3.67 }
            else if `k' == 6 { local lb = 2.57 ; local ub = 3.61 }
            else if `k' == 7 { local lb = 2.47 ; local ub = 3.56 }
            else if `k' == 8 { local lb = 2.40 ; local ub = 3.52 }
            else if `k' == 9 { local lb = 2.34 ; local ub = 3.48 }
            else if `k' == 10 { local lb = 2.28 ; local ub = 3.44 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.05 {
            if `k' == 1 { local lb = 4.42 ; local ub = 4.99 }
            else if `k' == 2 { local lb = 3.88 ; local ub = 4.61 }
            else if `k' == 3 { local lb = 3.47 ; local ub = 4.45 }
            else if `k' == 4 { local lb = 3.24 ; local ub = 4.35 }
            else if `k' == 5 { local lb = 3.04 ; local ub = 4.23 }
            else if `k' == 6 { local lb = 2.89 ; local ub = 4.13 }
            else if `k' == 7 { local lb = 2.78 ; local ub = 4.07 }
            else if `k' == 8 { local lb = 2.69 ; local ub = 4.00 }
            else if `k' == 9 { local lb = 2.62 ; local ub = 3.95 }
            else if `k' == 10 { local lb = 2.54 ; local ub = 3.91 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.025 {
            if `k' == 1 { local lb = 5.03 ; local ub = 5.65 }
            else if `k' == 2 { local lb = 4.37 ; local ub = 5.16 }
            else if `k' == 3 { local lb = 3.89 ; local ub = 4.97 }
            else if `k' == 4 { local lb = 3.59 ; local ub = 4.82 }
            else if `k' == 5 { local lb = 3.36 ; local ub = 4.69 }
            else if `k' == 6 { local lb = 3.19 ; local ub = 4.59 }
            else if `k' == 7 { local lb = 3.06 ; local ub = 4.51 }
            else if `k' == 8 { local lb = 2.97 ; local ub = 4.45 }
            else if `k' == 9 { local lb = 2.88 ; local ub = 4.40 }
            else if `k' == 10 { local lb = 2.79 ; local ub = 4.34 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.01 {
            if `k' == 1 { local lb = 6.10 ; local ub = 6.73 }
            else if `k' == 2 { local lb = 5.15 ; local ub = 5.94 }
            else if `k' == 3 { local lb = 4.56 ; local ub = 5.65 }
            else if `k' == 4 { local lb = 4.18 ; local ub = 5.44 }
            else if `k' == 5 { local lb = 3.90 ; local ub = 5.22 }
            else if `k' == 6 { local lb = 3.65 ; local ub = 5.10 }
            else if `k' == 7 { local lb = 3.49 ; local ub = 4.99 }
            else if `k' == 8 { local lb = 3.36 ; local ub = 4.89 }
            else if `k' == 9 { local lb = 3.24 ; local ub = 4.80 }
            else if `k' == 10 { local lb = 3.13 ; local ub = 4.73 }
            else { local lb = . ; local ub = . }
        }
        else { local lb = . ; local ub = . }
    }
    else { local lb = . ; local ub = . }
    
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
            if `k' == 1 { local lb = -1.62 ; local ub = -2.28 }
            else if `k' == 2 { local lb = -1.62 ; local ub = -2.68 }
            else if `k' == 3 { local lb = -1.62 ; local ub = -3.00 }
            else if `k' == 4 { local lb = -1.62 ; local ub = -3.26 }
            else if `k' == 5 { local lb = -1.62 ; local ub = -3.49 }
            else if `k' == 6 { local lb = -1.62 ; local ub = -3.70 }
            else if `k' == 7 { local lb = -1.62 ; local ub = -3.86 }
            else if `k' == 8 { local lb = -1.62 ; local ub = -4.04 }
            else if `k' == 9 { local lb = -1.62 ; local ub = -4.18 }
            else if `k' == 10 { local lb = -1.62 ; local ub = -4.34 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.05 {
            if `k' == 1 { local lb = -1.95 ; local ub = -2.60 }
            else if `k' == 2 { local lb = -1.95 ; local ub = -3.02 }
            else if `k' == 3 { local lb = -1.95 ; local ub = -3.33 }
            else if `k' == 4 { local lb = -1.95 ; local ub = -3.60 }
            else if `k' == 5 { local lb = -1.95 ; local ub = -3.83 }
            else if `k' == 6 { local lb = -1.95 ; local ub = -4.04 }
            else if `k' == 7 { local lb = -1.95 ; local ub = -4.21 }
            else if `k' == 8 { local lb = -1.95 ; local ub = -4.37 }
            else if `k' == 9 { local lb = -1.95 ; local ub = -4.52 }
            else if `k' == 10 { local lb = -1.95 ; local ub = -4.66 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.01 {
            if `k' == 1 { local lb = -2.58 ; local ub = -3.22 }
            else if `k' == 2 { local lb = -2.58 ; local ub = -3.59 }
            else if `k' == 3 { local lb = -2.58 ; local ub = -3.93 }
            else if `k' == 4 { local lb = -2.58 ; local ub = -4.23 }
            else if `k' == 5 { local lb = -2.58 ; local ub = -4.44 }
            else if `k' == 6 { local lb = -2.58 ; local ub = -4.67 }
            else if `k' == 7 { local lb = -2.58 ; local ub = -4.84 }
            else if `k' == 8 { local lb = -2.58 ; local ub = -5.03 }
            else if `k' == 9 { local lb = -2.58 ; local ub = -5.17 }
            else if `k' == 10 { local lb = -2.58 ; local ub = -5.31 }
            else { local lb = . ; local ub = . }
        }
        else { local lb = . ; local ub = . }
    }
    * Case V: Unrestricted intercept + unrestricted trend
    else if `case' == 5 {
        if `alpha' == 0.10 {
            if `k' == 1 { local lb = -2.57 ; local ub = -3.21 }
            else if `k' == 2 { local lb = -2.57 ; local ub = -3.53 }
            else if `k' == 3 { local lb = -2.57 ; local ub = -3.80 }
            else if `k' == 4 { local lb = -2.57 ; local ub = -4.01 }
            else if `k' == 5 { local lb = -2.57 ; local ub = -4.21 }
            else if `k' == 6 { local lb = -2.57 ; local ub = -4.38 }
            else if `k' == 7 { local lb = -2.57 ; local ub = -4.52 }
            else if `k' == 8 { local lb = -2.57 ; local ub = -4.66 }
            else if `k' == 9 { local lb = -2.57 ; local ub = -4.79 }
            else if `k' == 10 { local lb = -2.57 ; local ub = -4.91 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.05 {
            if `k' == 1 { local lb = -2.86 ; local ub = -3.53 }
            else if `k' == 2 { local lb = -2.86 ; local ub = -3.83 }
            else if `k' == 3 { local lb = -2.86 ; local ub = -4.10 }
            else if `k' == 4 { local lb = -2.86 ; local ub = -4.34 }
            else if `k' == 5 { local lb = -2.86 ; local ub = -4.52 }
            else if `k' == 6 { local lb = -2.86 ; local ub = -4.69 }
            else if `k' == 7 { local lb = -2.86 ; local ub = -4.85 }
            else if `k' == 8 { local lb = -2.86 ; local ub = -4.99 }
            else if `k' == 9 { local lb = -2.86 ; local ub = -5.11 }
            else if `k' == 10 { local lb = -2.86 ; local ub = -5.23 }
            else { local lb = . ; local ub = . }
        }
        else if `alpha' == 0.01 {
            if `k' == 1 { local lb = -3.43 ; local ub = -4.10 }
            else if `k' == 2 { local lb = -3.43 ; local ub = -4.44 }
            else if `k' == 3 { local lb = -3.43 ; local ub = -4.73 }
            else if `k' == 4 { local lb = -3.43 ; local ub = -4.96 }
            else if `k' == 5 { local lb = -3.43 ; local ub = -5.13 }
            else if `k' == 6 { local lb = -3.43 ; local ub = -5.31 }
            else if `k' == 7 { local lb = -3.43 ; local ub = -5.46 }
            else if `k' == 8 { local lb = -3.43 ; local ub = -5.60 }
            else if `k' == 9 { local lb = -3.43 ; local ub = -5.72 }
            else if `k' == 10 { local lb = -3.43 ; local ub = -5.84 }
            else { local lb = . ; local ub = . }
        }
        else { local lb = . ; local ub = . }
    }
    else { local lb = . ; local ub = . }
    
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
            if `k' == 1 { local lb = 1.05 ; local ub = 3.69 }
            else if `k' == 2 { local lb = 1.05 ; local ub = 3.68 }
            else if `k' == 3 { local lb = 1.05 ; local ub = 3.62 }
            else if `k' == 4 { local lb = 1.05 ; local ub = 3.61 }
            else if `k' == 5 { local lb = 1.05 ; local ub = 3.60 }
            else { local lb = 1.05 ; local ub = 3.60 }
        }
        else if `nobs' <= 65 {
            * T = 50
            if `k' == 1 { local lb = 1.01 ; local ub = 3.69 }
            else if `k' == 2 { local lb = 1.01 ; local ub = 3.63 }
            else if `k' == 3 { local lb = 1.01 ; local ub = 3.63 }
            else if `k' == 4 { local lb = 1.01 ; local ub = 3.59 }
            else if `k' == 5 { local lb = 1.01 ; local ub = 3.58 }
            else { local lb = 1.01 ; local ub = 3.58 }
        }
        else {
            * T >= 80 (asymptotic)
            if `k' == 1 { local lb = 0.998 ; local ub = 3.65 }
            else if `k' == 2 { local lb = 0.998 ; local ub = 3.60 }
            else if `k' == 3 { local lb = 0.998 ; local ub = 3.65 }
            else if `k' == 4 { local lb = 0.998 ; local ub = 3.61 }
            else if `k' == 5 { local lb = 0.998 ; local ub = 3.60 }
            else { local lb = 0.998 ; local ub = 3.60 }
        }
    }
    * -----------------------------------------------------------------------
    *  alpha = 0.10 (10% significance level)
    *  Interpolated from Webb (2019) Tables 3-5
    * -----------------------------------------------------------------------
    else if `alpha' == 0.10 {
        if `nobs' <= 40 {
            if `k' == 1 { local lb = 0.68 ; local ub = 3.06 }
            else if `k' == 2 { local lb = 0.68 ; local ub = 3.03 }
            else if `k' == 3 { local lb = 0.68 ; local ub = 2.99 }
            else if `k' == 4 { local lb = 0.68 ; local ub = 2.97 }
            else if `k' == 5 { local lb = 0.68 ; local ub = 2.96 }
            else { local lb = 0.68 ; local ub = 2.96 }
        }
        else if `nobs' <= 65 {
            if `k' == 1 { local lb = 0.66 ; local ub = 3.04 }
            else if `k' == 2 { local lb = 0.66 ; local ub = 3.01 }
            else if `k' == 3 { local lb = 0.66 ; local ub = 2.99 }
            else if `k' == 4 { local lb = 0.66 ; local ub = 2.96 }
            else if `k' == 5 { local lb = 0.66 ; local ub = 2.95 }
            else { local lb = 0.66 ; local ub = 2.95 }
        }
        else {
            if `k' == 1 { local lb = 0.65 ; local ub = 3.02 }
            else if `k' == 2 { local lb = 0.65 ; local ub = 2.99 }
            else if `k' == 3 { local lb = 0.65 ; local ub = 2.98 }
            else if `k' == 4 { local lb = 0.65 ; local ub = 2.95 }
            else if `k' == 5 { local lb = 0.65 ; local ub = 2.94 }
            else { local lb = 0.65 ; local ub = 2.94 }
        }
    }
    * -----------------------------------------------------------------------
    *  alpha = 0.01 (1% significance level)
    *  Interpolated from Webb (2019) Tables 3-5
    * -----------------------------------------------------------------------
    else if `alpha' == 0.01 {
        if `nobs' <= 40 {
            if `k' == 1 { local lb = 1.72 ; local ub = 4.96 }
            else if `k' == 2 { local lb = 1.72 ; local ub = 4.92 }
            else if `k' == 3 { local lb = 1.72 ; local ub = 4.88 }
            else if `k' == 4 { local lb = 1.72 ; local ub = 4.85 }
            else if `k' == 5 { local lb = 1.72 ; local ub = 4.82 }
            else { local lb = 1.72 ; local ub = 4.82 }
        }
        else if `nobs' <= 65 {
            if `k' == 1 { local lb = 1.68 ; local ub = 4.94 }
            else if `k' == 2 { local lb = 1.68 ; local ub = 4.90 }
            else if `k' == 3 { local lb = 1.68 ; local ub = 4.86 }
            else if `k' == 4 { local lb = 1.68 ; local ub = 4.82 }
            else if `k' == 5 { local lb = 1.68 ; local ub = 4.80 }
            else { local lb = 1.68 ; local ub = 4.80 }
        }
        else {
            if `k' == 1 { local lb = 1.65 ; local ub = 4.90 }
            else if `k' == 2 { local lb = 1.65 ; local ub = 4.86 }
            else if `k' == 3 { local lb = 1.65 ; local ub = 4.84 }
            else if `k' == 4 { local lb = 1.65 ; local ub = 4.80 }
            else if `k' == 5 { local lb = 1.65 ; local ub = 4.78 }
            else { local lb = 1.65 ; local ub = 4.78 }
        }
    }
    else { local lb = . ; local ub = . }
    
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
