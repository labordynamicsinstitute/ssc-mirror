// ══════════════════════════════════════════════════════════════════════════════
// qvar_example.do — Complete Demonstration of the QVAR Stata Package
// ══════════════════════════════════════════════════════════════════════════════
//
// This do-file demonstrates all features of the qvar Stata package:
//   1. QVAR Estimation (core.py → _qvar_estimate.ado)
//   2. Quantile Granger Causality (granger.py → _qvar_granger.ado)
//   3. VAR-QR Growth-at-Risk (varqr.py → _qvar_varqr.ado)
//   4. Quantile Forecasting (forecasting.py → _qvar_forecast.ado)
//   5. Quantile IRF (irf.py → _qvar_irf.ado)
//   6. Forecast Evaluation (evaluation.py → _qvar_evaluate.ado)
//
// Author: Dr. Merwan Roudane
// Version: 0.1.0
// ══════════════════════════════════════════════════════════════════════════════

clear all
set more off
set matsize 5000

// ─── Load sample data ───
webuse lutkepohl2, clear
tsset qtr

describe
summarize dln_inv dln_inc dln_consump

// ══════════════════════════════════════════════════════════════════════════════
// 1. QVAR ESTIMATION
//    Python equivalent: QuantileVAR(lags=2).fit(data, taus=[0.05,0.5,0.95])
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 1: QVAR Estimation"
di "{hline 78}"

qvar estimate dln_inv dln_inc dln_consump, lags(2) ///
    taus(0.05 0.50 0.95) recursive

// View stored results
ereturn list

// Access coefficient matrices
matrix list _qvar_b_0_50_eq1
matrix list _qvar_b_0_50_eq2

// ══════════════════════════════════════════════════════════════════════════════
// 2. QUANTILE GRANGER CAUSALITY
//    Python equivalent: QuantileGrangerCausality(lags=1).test(y, z)
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 2: Quantile Granger Causality"
di "{hline 78}"

// Does income Granger-cause investment in quantiles?
qvar granger dln_inv dln_inc, lags(1) bootstrap(199) ///
    regimes alpha(0.10)

// View test statistics
di "supLM = " e(sup_lm) ", p-value = " e(sup_lm_pval)
di "expLM = " e(exp_lm) ", p-value = " e(exp_lm_pval)

// Check supWald
if e(sup_wald) < . {
    di "supWald = " e(sup_wald) ", p-value = " e(sup_wald_pval)
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. VAR-QR MODEL (Growth-at-Risk)
//    Python equivalent: VARQR(var_lags=2).fit(data)
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 3: VAR-QR Growth-at-Risk"
di "{hline 78}"

// Clean up previous variables
capture drop _varqr_*

qvar varqr dln_inv dln_inc dln_consump, varlags(2) ///
    qrlags(1) taus(0.10 0.90)

// Plot time-varying volatility
tsline _varqr_sigma_dln_inv _varqr_sigma_dln_inc, ///
    title("Time-Varying Conditional Volatility") ///
    legend(label(1 "Investment") label(2 "Income"))

// ══════════════════════════════════════════════════════════════════════════════
// 4. QUANTILE FORECASTING
//    Python equivalent: QVARForecaster().forecast(results, horizon=12)
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 4: Quantile Forecasting"
di "{hline 78}"

// Re-estimate for forecasting
qvar estimate dln_inv dln_inc, lags(1) taus(0.05 0.25 0.50 0.75 0.95)

// Generate forecasts
qvar forecast, horizon(12) nsims(5000) seed(42)

// ══════════════════════════════════════════════════════════════════════════════
// 5. QUANTILE IMPULSE RESPONSES
//    Python equivalent: QuantileIRF(results).compute(shock_var="dln_inc")
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 5: Quantile IRFs"
di "{hline 78}"

// Compute IRF: shock to income → response in all variables
qvar irf, shockvar(dln_inc) shocksize(1) horizon(20) ///
    taupath(0.50) nboot(200) seed(42)

// Plot IRF
tsline _qvar_irf_dln_inc_dln_inv _qvar_irf_lo_dln_inc_dln_inv ///
    _qvar_irf_hi_dln_inc_dln_inv in 1/20, ///
    title("QIRF: Income → Investment (tau=0.50)") ///
    legend(label(1 "IRF") label(2 "68% CI lower") label(3 "68% CI upper"))

// ══════════════════════════════════════════════════════════════════════════════
// 6. FORECAST EVALUATION
//    Python equivalent: qw_crps(), diebold_mariano_test(), coverage_test()
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  DEMO 6: Forecast Evaluation"
di "{hline 78}"

// Create synthetic forecasts for demonstration
qui gen fc_q05 = dln_inv + invnormal(0.05) * 0.02
qui gen fc_q50 = dln_inv + rnormal() * 0.005
qui gen fc_q95 = dln_inv + invnormal(0.95) * 0.02

qvar evaluate fc_q05 fc_q50 fc_q95, actual(dln_inv) ///
    taus(0.05 0.50 0.95) weight(tails) nominal(0.90)

// ══════════════════════════════════════════════════════════════════════════════
// STATIONARITY CHECK (utility)
// ══════════════════════════════════════════════════════════════════════════════

di _n "{hline 78}"
di "  BONUS: Stationarity Check"
di "{hline 78}"

_qvar_stationarity_check dln_inv dln_inc dln_consump

// ══════════════════════════════════════════════════════════════════════════════
di _n "  All demos completed successfully!"
di "══════════════════════════════════════════════════════════════════════════════"
