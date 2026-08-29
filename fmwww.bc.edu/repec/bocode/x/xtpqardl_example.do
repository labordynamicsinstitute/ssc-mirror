* =====================================================================
* XTPQARDL — Example Do-File
* Panel Quantile ARDL Estimation
* Version 1.0.4 | August 2026
* =====================================================================
* This do-file demonstrates the xtpqardl package using:
*   1. Simulated data (N=20, T=60) — full demo with all quantiles
*   2. Real data: Grunfeld panel (N=10, T=20) — classic investment eq.
* =====================================================================

clear all
set more off
discard

* =====================================================================
* EXAMPLE 1: Simulated Panel ARDL Data (Large Sample)
* =====================================================================
* True DGP: y_it = α_i + 2.5*x1 + 1.8*x2 + ECM dynamics

di _n(3) in ye "╔══════════════════════════════════════════════════════════╗"
di in ye       "║  EXAMPLE 1: Simulated Data — N=20, T=60                ║"
di in ye       "║  All 5 quantiles including extremes (0.10, 0.90)       ║"
di in ye       "╚══════════════════════════════════════════════════════════╝"

xtpqardl_makedata, n(20) t(60) seed(12345) clear

* Full estimation: 5 quantiles, PMG, with graphs
xtpqardl dy dx1 dx2, lr(ly x1 x2)  ///
	tau(0.10 0.25 0.50 0.75 0.90)  ///
	pmg halflife graph

* Post-estimation: access stored results
di _n in ye "--- Post-estimation results ---"
matrix list e(beta_mg), title("Long-run β(τ)")
matrix list e(rho_mg), title("ECT ρ(τ)")

* Export graphs
* graph export "xtpqardl_qprocess.png", name(xtpqardl_qprocess) replace width(2000)


* =====================================================================
* EXAMPLE 2: Grunfeld Investment Panel (Real Data)
* =====================================================================
* Classic panel dataset: 10 firms, 1935–1954 (T=20)
* Model: ΔInvest = f(L.Invest, MValue, KStock)
* Tests whether investment responds asymmetrically across quantiles

di _n(3) in ye "╔══════════════════════════════════════════════════════════╗"
di in ye       "║  EXAMPLE 2: Grunfeld Investment Data — Real Data       ║"
di in ye       "║  N=10 firms, T=20 years, 3 quantiles                   ║"
di in ye       "╚══════════════════════════════════════════════════════════╝"

webuse grunfeld, clear

* xtset is already set: company year
xtset company year

* Rename for clarity
rename invest Invest
rename mvalue MValue
rename kstock KStock

* Basic PQARDL estimation with 3 inner quantiles
* (T=20 is too small for extreme quantiles 0.10/0.90)
xtpqardl D.Invest D.MValue D.KStock, ///
	lr(L.Invest MValue KStock)        ///
	tau(0.25 0.50 0.75)                ///
	pmg halflife graph


* =====================================================================
* EXAMPLE 3: Grunfeld with MG estimator
* =====================================================================

di _n(3) in ye "╔══════════════════════════════════════════════════════════╗"
di in ye       "║  EXAMPLE 3: Grunfeld — Mean Group (MG) Estimator       ║"
di in ye       "╚══════════════════════════════════════════════════════════╝"

xtpqardl D.Invest D.MValue D.KStock, ///
	lr(L.Invest MValue KStock)        ///
	tau(0.25 0.50 0.75)                ///
	mg halflife


* =====================================================================
* EXAMPLE 4: Simulated Data with BIC Lag Selection
* =====================================================================

di _n(3) in ye "╔══════════════════════════════════════════════════════════╗"
di in ye       "║  EXAMPLE 4: BIC Lag Selection — Automatic PQARDL(p,q)  ║"
di in ye       "╚══════════════════════════════════════════════════════════╝"

xtpqardl_makedata, n(15) t(50) seed(54321) clear

xtpqardl dy dx1 dx2, lr(ly x1 x2)  ///
	tau(0.25 0.50 0.75)              ///
	lagsel(bic) pmg halflife


* =====================================================================
* EXAMPLE 5: Heterogeneous Lag Orders PQARDL(2, 2, 3)
* =====================================================================

di _n(3) in ye "╔══════════════════════════════════════════════════════════╗"
di in ye       "║  EXAMPLE 5: Heterogeneous Lags — PQARDL(2, 2, 3)      ║"
di in ye       "╚══════════════════════════════════════════════════════════╝"

xtpqardl_makedata, n(15) t(50) seed(99999) clear

xtpqardl dy dx1 dx2, lr(ly x1 x2)  ///
	tau(0.25 0.50 0.75)              ///
	p(2) q(2 3) pmg halflife

di _n(2) in ye "═══════════════════════════════════════════════"
di in ye "  All examples completed successfully."
di in ye "═══════════════════════════════════════════════"


* =====================================================================
* EXAMPLE 9 (v1.0.4): HAC standard errors and inference
* =====================================================================
di _n(3) in ye "=============================================================="
di in ye       "  EXAMPLE 9: HAC (Newey-West) standard errors"
di in ye       "=============================================================="

xtpqardl_makedata, n(15) t(60) seed(2026) clear

* Default: non-parametric mean-group standard errors
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg

* HAC per-panel standard errors, automatic Newey-West bandwidth
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg vce(hac)

* HAC with a Parzen kernel and a fixed bandwidth of 3
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg vce(hac) ///
	kernel(parzen) bw(3)

* Heteroskedasticity-robust Powell sandwich, no serial-correlation term
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg vce(robust)


* =====================================================================
* EXAMPLE 10 (v1.0.4): PMG versus MG and the Hausman test
* =====================================================================
di _n(3) in ye "=============================================================="
di in ye       "  EXAMPLE 10: is the pooled long run supported?"
di in ye       "=============================================================="

* pmg now imposes a common long run and reports a Hausman test against mg
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) pmg
di in ye "Hausman chi2 = " e(hausman) "  p = " e(hausman_p)

* mg leaves the long run panel specific
xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg


* =====================================================================
* EXAMPLE 11 (v1.0.4): post-estimation testing with e(b) / e(V)
* =====================================================================
di _n(3) in ye "=============================================================="
di in ye       "  EXAMPLE 11: test / lincom across quantiles"
di in ye       "=============================================================="

xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.50 0.75) mg notable
ereturn display

* is the long-run effect of x1 the same at the first and third quartile?
test [q0250]lr_x1 = [q0750]lr_x1

* how much faster is adjustment at the median than at the lower quartile?
lincom [q0500]ECT - [q0250]ECT

* is the contemporaneous short-run impact of dx1 constant across quantiles?
test [q0250]D_dx1 = [q0500]D_dx1 = [q0750]D_dx1
