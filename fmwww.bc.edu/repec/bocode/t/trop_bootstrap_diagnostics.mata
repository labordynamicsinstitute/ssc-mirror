/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_diagnostics.mata

  Diagnostic utilities for the bootstrap distribution of treatment effect
  estimates.  Computes descriptive statistics (skewness, kurtosis),
  quantiles, the Shapiro-Wilk normality test, and flags distributional
  anomalies that may affect the reliability of bootstrap inference.

  The bootstrap resamples units with replacement and re-estimates the
  treatment effect for each replicate, yielding an empirical distribution
  from which standard errors and percentile confidence intervals are
  derived.  These diagnostics help assess whether the normal approximation
  underlying the parametric CI is adequate.

  Contents
    _compute_skewness()                     sample skewness
    _compute_kurtosis()                     sample kurtosis
    _shapiro_wilk_test()                    Shapiro-Wilk normality test
    _compute_quantiles()                    quantile computation
    _diagnose_bootstrap_distribution()      detailed diagnostic messages
    trop_bootstrap_diagnostics_brief()      compact summary
    trop_bootstrap_diagnostics_full()       full diagnostic report
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:

/* ═══════════════════════════════════════════════════════════════════════════
   Descriptive statistics
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _compute_skewness()

  Sample skewness (third standardised central moment).
  Returns 0 when the sample standard deviation is zero.

  Arguments
    x   n x 1 real vector of observations

  Returns
    real scalar   skewness coefficient
──────────────────────────────────────────────────────────────────────────────*/

real scalar _compute_skewness(real colvector x)
{
    real scalar n, mu, sigma
    real colvector z

    n     = rows(x)
    mu    = mean(x)
    sigma = sqrt(variance(x))

    if (sigma == 0) return(0)

    z = (x :- mu) / sigma
    return(mean(z :^ 3))
}

/*──────────────────────────────────────────────────────────────────────────────
  _compute_kurtosis()

  Sample kurtosis (fourth standardised central moment).
  Returns 3 (the normal reference value) when the sample standard
  deviation is zero.

  Arguments
    x   n x 1 real vector of observations

  Returns
    real scalar   kurtosis coefficient
──────────────────────────────────────────────────────────────────────────────*/

real scalar _compute_kurtosis(real colvector x)
{
    real scalar n, mu, sigma
    real colvector z

    n     = rows(x)
    mu    = mean(x)
    sigma = sqrt(variance(x))

    if (sigma == 0) return(3)

    z = (x :- mu) / sigma
    return(mean(z :^ 4))
}

/* ═══════════════════════════════════════════════════════════════════════════
   Normality testing
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _shapiro_wilk_test()

  Wrapper around Stata's -swilk- command.  Returns the p-value for the
  null hypothesis of normality, or missing (.) when n is outside [4, 2000]
  or the variance is zero.

  Arguments
    x   n x 1 real vector of observations

  Returns
    real scalar   p-value, or missing
──────────────────────────────────────────────────────────────────────────────*/

real scalar _shapiro_wilk_test(real colvector x)
{
    real scalar n, p_value, idx

    n = rows(x)

    if (n < 4 | n > 2000) return(.)
    if (variance(x) == 0)  return(.)

    stata("preserve")
    stata("quietly clear")
    stata("quietly set obs " + strofreal(n))
    idx = st_addvar("double", "__swilk_tmp")
    st_store(., idx, x)
    stata("capture quietly swilk __swilk_tmp")
    p_value = st_numscalar("r(p)")
    stata("restore")

    if (missing(p_value)) return(.)
    return(p_value)
}

/* ═══════════════════════════════════════════════════════════════════════════
   Quantile computation
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _compute_quantiles()

  Computes quantiles at probability levels
      {0.025, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.975}
  using linear interpolation with the (n-1)*p index method.

  Arguments
    x   n x 1 real vector of observations

  Returns
    9 x 1 real colvector of quantiles
──────────────────────────────────────────────────────────────────────────────*/

real colvector _compute_quantiles(real colvector x)
{
    real colvector quantiles, probs, x_sorted
    real scalar n, i
    real scalar idx_f, idx_low, idx_high, frac

    n = rows(x)
    probs = (0.025 \ 0.05 \ 0.10 \ 0.25 \ 0.50 \ 0.75 \ 0.90 \ 0.95 \ 0.975)
    quantiles = J(9, 1, .)

    x_sorted = sort(x, 1)

    for (i = 1; i <= 9; i++) {
        idx_f    = (n - 1) * probs[i]
        idx_low  = floor(idx_f)
        idx_high = ceil(idx_f)

        if (idx_low < 0)      idx_low  = 0
        if (idx_high > n - 1) idx_high = n - 1

        if (idx_low == idx_high) {
            quantiles[i] = x_sorted[idx_low + 1]
        }
        else {
            frac = idx_f - idx_low
            quantiles[i] = x_sorted[idx_low + 1] * (1 - frac) ///
                         + x_sorted[idx_high + 1] * frac
        }
    }

    return(quantiles)
}

/* ═══════════════════════════════════════════════════════════════════════════
   Diagnostic reporting
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _diagnose_bootstrap_distribution()

  Displays detailed diagnostic messages for the bootstrap replicate
  distribution.  Warning flags are raised when any of the following hold:

      |skewness|          > 2     severe asymmetry
      |kurtosis - 3|      > 7     heavy tails
      Shapiro-Wilk p      < 0.01  normality rejected at 1%
      |mean* - tau| / SE  > 0.3   large bootstrap mean bias

  Arguments
    tau_boot         B x 1 bootstrap replicate estimates
    tau_original     point estimate from the original sample
    se               bootstrap standard error
    skewness         sample skewness of tau_boot
    kurtosis         sample kurtosis of tau_boot
    shapiro_wilk_p   p-value from the Shapiro-Wilk test
    mean_boot        mean of tau_boot
──────────────────────────────────────────────────────────────────────────────*/

void _diagnose_bootstrap_distribution(
    real colvector tau_boot,
    real scalar tau_original,
    real scalar se,
    real scalar skewness,
    real scalar kurtosis,
    real scalar shapiro_wilk_p,
    real scalar mean_boot
)
{
    real scalar abs_bias, rel_bias

    printf("\n")
    printf("========================================================================\n")
    printf("{txt}Bootstrap distribution diagnostics\n")
    printf("========================================================================\n")

    printf("{txt}Descriptive statistics:\n")
    printf("  Point estimate:    %9.6f\n", tau_original)
    printf("  Bootstrap mean:    %9.6f\n", mean_boot)
    printf("  Std. dev. (SE):    %9.6f\n", se)

    printf("  Skewness:          %9.6f", skewness)
    if (abs(skewness) < 0.5) {
        printf("  {txt}[approx. symmetric]\n")
    }
    else if (skewness > 0) {
        printf("  {txt}[right-skewed]\n")
    }
    else {
        printf("  {txt}[left-skewed]\n")
    }

    printf("  Kurtosis:          %9.6f", kurtosis)
    if (abs(kurtosis - 3) < 1) {
        printf("  {txt}[mesokurtic]\n")
    }
    else if (kurtosis > 3) {
        printf("  {txt}[leptokurtic]\n")
    }
    else {
        printf("  {txt}[platykurtic]\n")
    }

    abs_bias = abs(mean_boot - tau_original)
    rel_bias = abs_bias / se

    printf("\n{txt}Bias diagnostics:\n")
    printf("  |mean* - tau|:     %9.6f\n", abs_bias)
    printf("  Relative bias:     %9.6f", rel_bias)
    if (rel_bias < 0.3) {
        printf("  {txt}[acceptable]\n")
    }
    else {
        printf("  {err}[large]\n")
    }

    if (abs(skewness) > 2) {
        printf("\n")
        printf("====================================================================\n")
        printf("{err}Warning: bootstrap distribution is severely skewed\n")
        printf("====================================================================\n")
        printf("{txt}Skewness: %9.6f (threshold: +/-2)\n", skewness)
        printf("Suggestions:\n")
        printf("  1. Check data for outliers\n")
        printf("  2. Increase B to at least 2000\n")
        printf("  3. Use percentile CI instead of normal-approximation CI\n")
        printf("  4. Consider a log or Box-Cox transformation of Y\n")
        printf("====================================================================\n")
    }

    if (abs(kurtosis - 3) > 7) {
        printf("\n")
        printf("====================================================================\n")
        printf("{err}Warning: bootstrap distribution has heavy tails\n")
        printf("====================================================================\n")
        printf("{txt}Kurtosis: %9.6f (normal = 3; threshold: |kurt - 3| > 7)\n",
               kurtosis)
        printf("Suggestions:\n")
        printf("  1. Heavy tails may arise from extreme values or heterogeneity\n")
        printf("  2. Percentile CI is more robust to tail behavior\n")
        printf("  3. Consider wild bootstrap as an alternative\n")
        printf("====================================================================\n")
    }

    if (!missing(shapiro_wilk_p) & shapiro_wilk_p < 0.01) {
        printf("\n")
        printf("====================================================================\n")
        printf("{err}Warning: bootstrap distribution departs from normality\n")
        printf("====================================================================\n")
        printf("{txt}Shapiro-Wilk p-value: %9.6f < 0.01\n", shapiro_wilk_p)
        printf("Note:\n")
        printf("  - The null hypothesis of normality is rejected at 1%%\n")
        printf("  - Percentile CI remains valid without a normality assumption\n")
        printf("====================================================================\n")
    }

    if (rel_bias > 0.3) {
        printf("\n")
        printf("====================================================================\n")
        printf("{err}Warning: bootstrap mean bias is large\n")
        printf("====================================================================\n")
        printf("{txt}Relative bias: %9.6f (threshold: 0.3)\n", rel_bias)
        printf("  |mean* - tau| / SE = %9.6f / %9.6f = %9.6f\n",
               abs_bias, se, rel_bias)
        printf("Possible causes:\n")
        printf("  1. Finite-sample bias (small treated group)\n")
        printf("  2. Insufficient number of bootstrap replications\n")
        printf("  3. Complex data-generating process\n")
        printf("Suggestions:\n")
        printf("  - Increase B to at least 2000\n")
        printf("  - Verify that the treated group has >= 5 observations\n")
        printf("====================================================================\n")
    }

    printf("========================================================================\n")
    printf("\n")
}

/* ═══════════════════════════════════════════════════════════════════════════
   Brief summary
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_diagnostics_brief()

  Prints a compact summary: SE, percentile 95% CI, skewness, kurtosis,
  and optional warnings for bias or tail behavior.

  Arguments
    tau_boot       B x 1 bootstrap replicate estimates
    tau_original   point estimate from the original sample
    se             bootstrap standard error
    vcetype        label for the variance estimation method
──────────────────────────────────────────────────────────────────────────────*/

void trop_bootstrap_diagnostics_brief(
    real colvector tau_boot,
    real scalar tau_original,
    real scalar se,
    string scalar vcetype
)
{
    real scalar mean_boot, skewness, kurtosis
    real scalar abs_bias, rel_bias
    real colvector quantiles

    mean_boot = mean(tau_boot)
    skewness  = _compute_skewness(tau_boot)
    kurtosis  = _compute_kurtosis(tau_boot)
    quantiles = _compute_quantiles(tau_boot)

    printf("\n{txt}Bootstrap diagnostic summary:\n")
    printf("  SE = %9.6f, 95%% CI = [%9.6f, %9.6f]\n",
           se, quantiles[1], quantiles[9])
    printf("  Skewness = %6.3f, Kurtosis = %6.3f\n", skewness, kurtosis)

    abs_bias = abs(mean_boot - tau_original)
    if (se > 0) {
        rel_bias = abs_bias / se
        if (rel_bias > 0.3) {
            printf("  {err}Note: large bootstrap mean bias " +
                   "(|bias|/SE = %5.3f > 0.3){txt}\n", rel_bias)
        }
    }

    if (abs(skewness) > 2) {
        printf("  {err}Note: severely skewed " +
               "(|skew| = %5.2f > 2); percentile CI recommended{txt}\n",
               abs(skewness))
    }
    if (abs(kurtosis - 3) > 7) {
        printf("  {err}Note: heavy tails " +
               "(|kurt - 3| = %5.2f > 7); percentile CI recommended{txt}\n",
               abs(kurtosis - 3))
    }
}

/* ═══════════════════════════════════════════════════════════════════════════
   Full diagnostic report
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_diagnostics_full()

  Entry point for bootstrap diagnostics.  When verbose_level == 0 (the
  default), only a brief summary is printed.  When verbose_level == 1,
  quantile tables, percentile confidence intervals, the Shapiro-Wilk
  normality test, and detailed warning flags are displayed.

  Arguments
    tau_boot        B x 1 bootstrap replicate estimates
    tau_original    point estimate from the original sample
    se              bootstrap standard error
    vcetype         label for the variance estimation method
    verbose_level   optional; 0 = brief (default), 1 = full
──────────────────────────────────────────────────────────────────────────────*/

void trop_bootstrap_diagnostics_full(
    real colvector tau_boot,
    real scalar tau_original,
    real scalar se,
    string scalar vcetype,
    | real scalar verbose_level
)
{
    real scalar mean_boot, median_boot
    real scalar skewness, kurtosis
    real scalar shapiro_wilk_p
    real colvector quantiles
    real scalar vlevel

    if (args() < 5) vlevel = 0
    else            vlevel = verbose_level

    if (vlevel == 0) {
        trop_bootstrap_diagnostics_brief(tau_boot, tau_original, se, vcetype)
        return
    }

    mean_boot   = mean(tau_boot)
    median_boot = median(tau_boot)
    skewness    = _compute_skewness(tau_boot)
    kurtosis    = _compute_kurtosis(tau_boot)

    shapiro_wilk_p = _shapiro_wilk_test(tau_boot)

    quantiles = _compute_quantiles(tau_boot)

    printf("\n{txt}Quantiles:\n")
    printf("  2.5%%:  %9.6f\n", quantiles[1])
    printf("  5%%:    %9.6f\n", quantiles[2])
    printf("  10%%:   %9.6f\n", quantiles[3])
    printf("  25%%:   %9.6f\n", quantiles[4])
    printf("  50%%:   %9.6f  (median)\n", quantiles[5])
    printf("  75%%:   %9.6f\n", quantiles[6])
    printf("  90%%:   %9.6f\n", quantiles[7])
    printf("  95%%:   %9.6f\n", quantiles[8])
    printf("  97.5%%: %9.6f\n", quantiles[9])

    printf("\n{txt}Percentile confidence intervals:\n")
    printf("  95%% CI: [%9.6f, %9.6f]\n", quantiles[1], quantiles[9])
    printf("  90%% CI: [%9.6f, %9.6f]\n", quantiles[2], quantiles[8])
    printf("  80%% CI: [%9.6f, %9.6f]\n", quantiles[3], quantiles[7])

    if (!missing(shapiro_wilk_p)) {
        printf("\n{txt}Normality test:\n")
        printf("  Shapiro-Wilk p-value: %9.6f", shapiro_wilk_p)
        if (shapiro_wilk_p >= 0.10) {
            printf("  {txt}[fail to reject normality]\n")
        }
        else if (shapiro_wilk_p >= 0.01) {
            printf("  {txt}[weak rejection of normality]\n")
        }
        else {
            printf("  {err}[normality rejected]\n")
        }
    }

    _diagnose_bootstrap_distribution(tau_boot, tau_original, se,
                                     skewness, kurtosis,
                                     shapiro_wilk_p, mean_boot)
}

end
