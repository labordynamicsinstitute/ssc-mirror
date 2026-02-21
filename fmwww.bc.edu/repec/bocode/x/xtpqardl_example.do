* =====================================================================
* XTPQARDL — Example Do-File
* Panel Quantile ARDL Estimation
* Version 1.0.1 | February 2026
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
