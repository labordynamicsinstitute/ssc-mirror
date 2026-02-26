// =========================================================================
// mtnardl_example.do — Test and Example Script for MTNARDL Package
// Bootstrap Multiple Threshold Nonlinear ARDL
// Pal & Mitra (2016, Economic Modelling)
// =========================================================================

clear all
discard
set more off
set seed 12345

// =========================================================================
// GENERATE SAMPLE DATA (Oil price transmission simulation)
// =========================================================================
qui {
    set obs 250
    gen t = _n
    tsset t

    // Crude oil price (random walk with drift)
    gen double crude = 50 + sum(rnormal(0.05, 3))

    // Petrol price with asymmetric transmission
    // - Large increases pass through quickly (high coef)
    // - Large decreases pass through slowly (small coef)
    gen double d_crude = D.crude
    replace d_crude = 0 if t == 1

    // Create asymmetric transmission
    gen double petrol = 30 if t == 1
    replace petrol = L.petrol + ///
        0.8 * d_crude * (d_crude > 2) + ///
        0.5 * d_crude * (d_crude > 0 & d_crude <= 2) + ///
        0.3 * d_crude * (d_crude <= 0 & d_crude > -2) + ///
        0.15 * d_crude * (d_crude <= -2) + ///
        rnormal(0, 0.8) if t > 1

    // Second product: ATF (aviation fuel) — stronger asymmetry
    gen double atf = 25 if t == 1
    replace atf = L.atf + ///
        0.9 * d_crude * (d_crude > 2) + ///
        0.6 * d_crude * (d_crude > 0 & d_crude <= 2) + ///
        0.2 * d_crude * (d_crude <= 0 & d_crude > -2) + ///
        0.05 * d_crude * (d_crude <= -2) + ///
        rnormal(0, 0.5) if t > 1

    // Take logs (as in the paper)
    gen double lcrude = ln(crude) if crude > 0
    gen double lpetrol = ln(petrol) if petrol > 0
    gen double latf = ln(atf) if atf > 0
}

di as txt ""
di as txt "{hline 78}"
di as res "  MTNARDL Package — Example Script"
di as res "  Pal & Mitra (2016) Asymmetric Price Transmission"
di as txt "{hline 78}"
di as txt ""

// =========================================================================
// EXAMPLE 1: QUINTILE DECOMPOSITION (default)
// Basic MTNARDL with PSS bounds test
// =========================================================================
di as txt ""
di as res "=================================================================="
di as res "  EXAMPLE 1: Quintile Decomposition (5 regimes) — PSS Bounds Test"
di as res "=================================================================="
di as txt ""

mtnardl lpetrol lcrude, decompose(lcrude) partition(quintile) ///
    maxlag(4) ic(aic) case(3) horizon(20)

// =========================================================================
// EXAMPLE 2: QUARTILE DECOMPOSITION with Bootstrap
// McNown et al. (2018) bootstrap cointegration test
// =========================================================================
di as txt ""
di as res "=================================================================="
di as res "  EXAMPLE 2: Quartile Decomposition (4 regimes) — Bootstrap"
di as res "=================================================================="
di as txt ""

mtnardl lpetrol lcrude, decompose(lcrude) partition(quartile) ///
    maxlag(4) ic(aic) case(3) type(mtnardl_mcnown) reps(299) ///
    horizon(20)

// =========================================================================
// EXAMPLE 3: DECILE DECOMPOSITION
// 10 regimes — captures fine-grained magnitude effects
// =========================================================================
di as txt ""
di as res "=================================================================="
di as res "  EXAMPLE 3: Decile Decomposition (10 regimes)"
di as res "=================================================================="
di as txt ""

mtnardl lpetrol lcrude, decompose(lcrude) partition(decile) ///
    maxlag(3) ic(bic) case(3) horizon(20) nograph

// =========================================================================
// EXAMPLE 4: CUSTOM CUTPOINTS
// User-defined thresholds based on domain knowledge
// =========================================================================
di as txt ""
di as res "=================================================================="
di as res "  EXAMPLE 4: Custom Cutpoints (5 regimes)"
di as res "=================================================================="
di as txt ""

// Cutpoints: large decrease | small decrease | neutral | small increase | large increase
mtnardl lpetrol lcrude, decompose(lcrude) partition(custom) ///
    cutpoints(-0.03 -0.01 0.01 0.03) maxlag(4) ic(aic) case(3) ///
    horizon(20)

// =========================================================================
// EXAMPLE 5: MULTIPLE INDEPENDENT VARIABLES
// =========================================================================
di as txt ""
di as res "=================================================================="
di as res "  EXAMPLE 5: Multiple Variables (ATF & Crude)"
di as res "=================================================================="
di as txt ""

mtnardl latf lcrude, decompose(lcrude) partition(quintile) ///
    maxlag(4) ic(aic) case(3) type(mtnardl_bvz) reps(299) ///
    horizon(15)

// =========================================================================
di as txt ""
di as txt "{hline 78}"
di as res "  All examples completed successfully!"
di as txt "{hline 78}"
