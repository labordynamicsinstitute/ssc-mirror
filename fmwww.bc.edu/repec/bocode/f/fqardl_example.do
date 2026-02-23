* ============================================================================
* FQARDL Complete Example — All Features
* ============================================================================
clear all
set more off

* --- Load data ---
webuse lutkepohl2, clear
tsset qtr

* ============================================================================
* Example 1: Basic FQARDL (auto lag selection, Fourier, graph)
* ============================================================================
di _n as res "=== Example 1: Basic FQARDL ==="
fqardl inv inc, tau(0.10 0.25 0.50 0.75 0.90) graph

* Verify stored results
di _n as txt "== Stored results =="
mat list e(beta), title("Long-run beta")
mat list e(gamma), title("Short-run gamma")
mat list e(rho_vec), title("Speed of adjustment rho")
mat list e(lags), title("Optimal lags")
di "k* = " e(kstar) "  p = " e(p) "  q = " e(q) "  k = " e(k)

* ============================================================================
* Example 2: FQARDL with fixed lags
* ============================================================================
di _n(3) as res "=== Example 2: Fixed lags p=2, q=2 ==="
fqardl inv inc, tau(0.25 0.50 0.75) p(2) q(2)

* ============================================================================
* Example 3: FQARDL without Fourier
* ============================================================================
di _n(3) as res "=== Example 3: No Fourier ==="
fqardl inv inc, tau(0.25 0.50 0.75) nofourier

* ============================================================================
* Example 4: FQARDL with ECM representation
* ============================================================================
di _n(3) as res "=== Example 4: ECM form ==="
fqardl inv inc, tau(0.25 0.50 0.75) ecm graph

* ============================================================================
* Example 5: FBQARDL — Full bootstrap (both methods) with graph
* ============================================================================
di _n(3) as res "=== Example 5: FBQARDL with bootstrap ==="
fqardl inv inc, tau(0.25 0.50 0.75) type(fbqardl) reps(199) graph

* ============================================================================
* Example 6: Multiple independent variables
* ============================================================================
di _n(3) as res "=== Example 6: Two independent variables ==="
fqardl inv inc consump, tau(0.25 0.50 0.75) graph

* ============================================================================
* Manual verification of results
* ============================================================================
di _n(3) as res "=== Manual Verification ==="
di "Verify: beta = gamma / (1 - sum(phi)) = gamma / (-rho)"
di "        IRF(h=0) = gamma (short-run impact)"
di "        IRF(h->inf) = beta (long-run equilibrium)"
di "        rho = sum(phi) - 1 (speed of adjustment, should be negative)"
di ""
di "All checks passed if:"
di "  1. rho < 0 for all quantiles (convergent system)"
di "  2. IRF starts at gamma and converges to beta"
di "  3. Half-life = ln(2)/|rho| is finite"
