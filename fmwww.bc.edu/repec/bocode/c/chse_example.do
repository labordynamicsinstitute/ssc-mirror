/*===========================================================================
  chse_example.do
  CHSE Stata Plugin — Complete Worked Example
  Version 1.0.0   April 2025
  Author: Nityahapani
  
  Runs all five commands end-to-end using realistic data that matches
  the paper's empirical examples exactly.
  
  Required: chse_regime.ado  chse_fdi.ado  chse_fliptime.ado
            chse_hoe.ado     chse_welfare.ado  chse_paradox.ado
  
  Run time: < 5 seconds
===========================================================================*/

clear all
set more off
version 14.0

// --------------------------------------------------------------------------
// --------------------------------------------------------------------------



// PART 1. Regime classification (chse_regime)
// ==========================================================================
di as text _newline "--- Part 1: Regime classification ---"

// 1a. Scalar calls — key examples from the paper
foreach hsi_pi in "2.1 0.0" "1.0 0.0" "0.4 0.0" "0.5 0.7" "1.5 0.3" {
    local hsi_v : word 1 of `hsi_pi'
    local pi_v  : word 2 of `hsi_pi'
    quietly chse_regime, hsi(`hsi_v') pi(`pi_v')
    di as text "  HSI=" as result `hsi_v' as text "  PI=" as result `pi_v' ///
        as text "  Z=" as result %6.4f r(Z) ///
        as text "  Regime: " as result "`r(regime)'"
}

// 1b. Dataset of (HSI, PI) pairs — classify and tabulate
clear
input double hsi double pi str20 label
    2.1  0.0  "Stable CB (paper)"
    1.0  0.0  "Oscillatory boundary"
    0.4  0.0  "Cascade (Figure 2)"
    1.5  0.4  "Moderate cascade risk"
    0.5  0.7  "High PI cascade"
    2.5  0.8  "High HSI + high PI"
    0.8  0.2  "Low HSI, moderate PI"
    1.2  0.1  "Near-oscillatory"
end

chse_regime, hsi(hsi) pi(pi) gen(chse) replace

di as text _newline "Regime classification results:"
list label hsi pi chse_Z chse_regime, noobs sep(0)

di as text _newline "Regime counts:"
tabulate chse_regime


// ==========================================================================
// PART 2. Fiscal Dominance Index (chse_fdi)
// ==========================================================================
di as text _newline(2) "--- Part 2: Fiscal Dominance Index ---"

// 2a. Replicate Figure 5 exactly
clear
input str8 country str8 period float vt float kcb
    "Chile"  "2000-22"  0.21  0.95
    "US"     "2000-07"  0.17  0.94
    "US"     "2020-23"  0.51  0.94
    "Brazil" "2015-18"  0.77  0.85
    "Zambia" "2020-23"  0.94  0.67
    "Turkey" "2021-23"  0.82  0.45
end

chse_fdi, vt(vt) kcb(kcb) gen(chse) replace

di as text _newline "Figure 5 — Fiscal Dominance Index:"
list country period chse_fdi chse_hsi chse_fdi_regime, noobs sep(0)

// 2b. Cross-check against phase diagram: use regime from FDI
chse_regime, hsi(chse_hsi) pi(0) gen(phase) replace

di as text _newline "Phase diagram consistency check:"
gen consistent = (chse_fdi_regime == "monetary"  & phase_regime == "stable") | ///
                 (chse_fdi_regime == "contested"  & phase_regime == "oscillatory") | ///
                 (chse_fdi_regime == "fiscal"     & (phase_regime == "cascade" | ///
                                                     phase_regime == "oscillatory"))
// Note: FDI=0.54 (contested) maps to Z=0.54 (stable) by Z formula;
// FDI taxonomy and Z taxonomy use different thresholds.
// The FDI directly identifies regimes; chse_regime identifies Z-based regimes.
list country chse_fdi_regime phase_regime chse_hsi phase_Z, noobs sep(0)

// 2c. Single-country scalar
di as text _newline "Single-country check (Turkey 2021-23):"
chse_fdi, vt(0.82) kcb(0.45)   // expect FDI=1.82, fiscal


// ==========================================================================
// PART 3. Flip time (chse_fliptime)
// ==========================================================================
di as text _newline(2) "--- Part 3: Leadership flip time ---"

// 3a. Three benchmark regimes
di as text "Oscillatory (HSI=1.0): mu=0.6, eta=0.4, kappa=0.4"
chse_fliptime, mu(0.6) eta(0.4) kappa(0.4) h0(0.75)
// expect: t* = 10.73, oscillates=1, period=23.75

di as text _newline "Stable (HSI=2.1): mu=2.0, eta=0.8, kappa=0.2"
chse_fliptime, mu(2.0) eta(0.8) kappa(0.2) h0(0.75)
// expect: t* = ., regime = stable

di as text _newline "Cascade (HSI=0.4): mu=0.3, eta=0.4, kappa=0.4"
chse_fliptime, mu(0.3) eta(0.4) kappa(0.4) h0(0.75)
// expect: t* small, oscillates=1

// 3b. Sweep over mu values
clear
set obs 20
gen mu_val = 0.3 + (_n-1) * 0.15    // mu from 0.3 to 3.15
gen eta_val = 0.4
gen kappa_val = 0.4

chse_fliptime, mu(mu_val) eta(eta_val) kappa(kappa_val) ///
               h0(0.75) gen(ft) replace

di as text _newline "Flip time vs mu (eta=0.4, kappa=0.4):"
list mu_val ft_disc ft_oscillates ft_tstar, noobs sep(0)


// ==========================================================================
// PART 4. HOE statistics (chse_hoe)
// ==========================================================================
di as text _newline(2) "--- Part 4: HOE statistics ---"

// 4a. Simulate a stable HOE: Ornstein-Uhlenbeck around h*=0.80
// h(t+1) = h(t) - 0.15*(h(t)-0.80) + N(0, 0.03)
clear
set obs 300
set seed 42
gen h = 0.65
replace h = h[_n-1] - 0.15*(h[_n-1]-0.80) + rnormal(0, 0.03) if _n > 1
replace h = min(1, max(0, h))

chse_hoe h, burnin(60) windows(4)
// expect: tau_hat≈0, mean_h≈0.80, converged=1

// 4b. Simulate an oscillatory HOE
clear
set obs 500
set seed 123
gen h = 0.5
// Oscillatory: crosses 0.5 frequently
replace h = h[_n-1] - 0.10*(h[_n-1]-0.5) + rnormal(0, 0.09) if _n > 1
replace h = min(1, max(0, h))

chse_hoe h, burnin(80) windows(5)
// expect: tau_hat>0.1, mean_h≈0.5, var_h>0.005

// 4c. Using if to restrict to a contested period
clear
set obs 400
set seed 7
gen year = 2000 + _n
gen contested = (year >= 2020)
gen h = 0.75
replace h = h[_n-1] - 0.08*(h[_n-1]-0.7) + rnormal(0, 0.04) if _n>1 & !contested[_n]
replace h = h[_n-1] - 0.06*(h[_n-1]-0.5) + rnormal(0, 0.12) if _n>1 & contested[_n]
replace h = min(1, max(0, h))

di as text _newline "Pre-2020 (monetary dominance):"
chse_hoe h if !contested, burnin(5)
di as text _newline "Post-2020 (contested period):"
chse_hoe h if contested, burnin(5)


// ==========================================================================
// PART 5. Welfare distortions (chse_welfare)
// ==========================================================================
di as text _newline(2) "--- Part 5: Welfare distortions ---"

// 5a. Scalar call — 3-player complete network, calibrated parameters
chse_welfare, eta(0.5) kappa(0.6) gamma(0.4)   ///
              beta_r(0.15) zeta_ii(0.3)          ///
              c_mu(0.3) c_kappa2(0.3)            ///
              avg_ambiguity(0.35) avg_degree(2)  ///
              n_edges(3)
// expect: welfare_loss = 1.4043

di as text _newline "Stored results: r(welfare_loss) = " as result r(welfare_loss)

// 5b. Sweep over Gamma
clear
set obs 20
gen gamma_val = 0.02 + (_n-1)*0.04   // Gamma from 0.02 to 0.78

local results ""
forvalues i = 1/20 {
    local g = 0.02 + (`i'-1)*0.04
    quietly chse_welfare, eta(0.5) kappa(0.6) gamma(`g') ///
                          beta_r(0.15) zeta_ii(0.3) c_mu(0.3) c_kappa2(0.3) ///
                          avg_ambiguity(0.35) avg_degree(2) n_edges(3)
    quietly replace gamma_val = `g' in `i'
    if `i' == 1 quietly gen welfare_loss = r(welfare_loss) in `i'
    else         quietly replace welfare_loss = r(welfare_loss) in `i'
}

// (Re-generate welfare_loss correctly)
drop welfare_loss
gen welfare_loss = .
forvalues i = 1/20 {
    quietly chse_welfare, eta(0.5) kappa(0.6) gamma(gamma_val[`i']) ///
        beta_r(0.15) zeta_ii(0.3) c_mu(0.3) c_kappa2(0.3) ///
        avg_ambiguity(0.35) avg_degree(2) n_edges(3)
    quietly replace welfare_loss = r(welfare_loss) in `i'
}
di as text _newline "Welfare loss vs Gamma:"
list gamma_val welfare_loss, noobs sep(0)

// 5c. From edge-level h data
clear
input float h_edge
    0.52  // fragile edge
    0.85  // stable edge
    0.48  // very fragile
end
chse_welfare h_edge, eta(0.5) kappa(0.6) gamma(0.4) ///
             beta_r(0.15) zeta_ii(0.3) c_mu(0.3) c_kappa2(0.3)


// ==========================================================================
// PART 6. Hierarchy Persistence Paradox (chse_paradox)
// ==========================================================================
di as text _newline(2) "--- Part 6: Hierarchy Persistence Paradox ---"

// 6a. Replicate the paper's paradox test
// Post-collapse yield volatility proxied by simulated values
// proportional to HSI (consistent with paradox prediction)
clear
input float disruption float hsi str8 country
    0.10  0.55  "Turkey"
    0.12  0.71  "Zambia"
    0.38  1.10  "Brazil"
    0.59  1.84  "US_2020"
    1.38  4.52  "Chile"
    1.61  5.53  "US_2000"
end

chse_paradox disruption hsi
// expect: slope>0, r≈0.996, paradox confirmed

// 6b. Using FDI instead of HSI
clear
input float disruption float fdi str8 country
    0.10  1.82  "Turkey"
    0.12  1.40  "Zambia"
    0.38  0.91  "Brazil"
    0.59  0.54  "US_2020"
    1.38  0.22  "Chile"
    1.61  0.18  "US_2000"
end

di as text _newline "Using FDI as input (converts to HSI internally):"
chse_paradox disruption fdi, fdi

// 6c. Generate predicted cascade sizes for scatter plot
clear
input float disruption float hsi str8 country
    0.10  0.55  "Turkey"
    0.12  0.71  "Zambia"
    0.38  1.10  "Brazil"
    0.59  1.84  "US_2020"
    1.38  4.52  "Chile"
    1.61  5.53  "US_2000"
end

chse_paradox disruption hsi, gen(pred) replace alpha_r(0.5) trust(0.65) phi(0.60)
di as text _newline "Predicted cascade sizes:"
list country hsi pred_acc pred_rhoK pred_cascade_pred, noobs sep(0)


// ==========================================================================
// Summary
// ==========================================================================
di as text _newline(2) "=== All examples completed successfully ==="
di as text _newline "Commands used:"
di as text "  chse_regime   — regime classification from HSI and PI"
di as text "  chse_fdi      — Fiscal Dominance Index (Figure 5)"
di as text "  chse_fliptime — leadership flip time t* (Definition 3.2)"
di as text "  chse_hoe      — HOE statistics from observed h(t)"
di as text "  chse_welfare  — three welfare distortions (Bottleneck 6)"
di as text "  chse_paradox  — Hierarchy Persistence Paradox test (Bottleneck 8)"
