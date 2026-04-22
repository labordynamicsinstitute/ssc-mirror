/*===========================================================================
  chse_example.do
  CHSE Stata Package — Complete Worked Example
  Version 1.0.2   April 2025
  Author: Nityahapani

  Runs all six commands end-to-end using realistic data that matches
  the paper's empirical examples exactly.

  Required: ssc install chse

  Run time: < 5 seconds
===========================================================================*/

clear all
set more off
version 14.0

* ssc install chse

di as text _newline(2) "=== CHSE Package Worked Example ==="


// ==========================================================================
// PART 1. Regime classification (chse_regime)
// ==========================================================================
di as text _newline "--- Part 1: Regime classification ---"

// 1a. Scalar calls — all-scalar path, no dataset required
foreach hsi_pi in "2.1 0.0" "1.0 0.0" "0.4 0.0" "0.5 0.7" "1.5 0.3" {
    local hsi_v : word 1 of `hsi_pi'
    local pi_v  : word 2 of `hsi_pi'
    quietly chse_regime, hsi(`hsi_v') pi(`pi_v')
    di as text "  HSI=" as result `hsi_v' ///
        as text "  PI=" as result `pi_v' ///
        as text "  Z=" as result %6.4f r(Z) ///
        as text "  Regime: " as result "`r(regime)'"
}

// 1b. Variable call
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
tabulate chse_regime


// ==========================================================================
// PART 2. Fiscal Dominance Index (chse_fdi)
// ==========================================================================
di as text _newline(2) "--- Part 2: Fiscal Dominance Index ---"

// 2a. Replicate Figure 5
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

// 2b. Single scalar — no dataset required
di as text _newline "Single-country check (Turkey 2021-23):"
chse_fdi, vt(0.82) kcb(0.45)


// ==========================================================================
// PART 3. Flip time (chse_fliptime)
// ==========================================================================
di as text _newline(2) "--- Part 3: Leadership flip time ---"

// 3a. Scalar calls — no dataset required
di as text "Oscillatory (HSI=1.0):"
chse_fliptime, mu(0.6) eta(0.4) kappa(0.4) h0(0.75)

di as text _newline "Stable (HSI=2.1):"
chse_fliptime, mu(2.0) eta(0.8) kappa(0.2) h0(0.75)

di as text _newline "Cascade (HSI=0.4):"
chse_fliptime, mu(0.3) eta(0.4) kappa(0.4) h0(0.75)

// 3b. Variable call — sweep over mu
clear
set obs 20
gen mu_val    = 0.3 + (_n-1)*0.15
gen eta_val   = 0.4
gen kappa_val = 0.4

chse_fliptime, mu(mu_val) eta(eta_val) kappa(kappa_val) ///
               h0(0.75) gen(ft) replace

di as text _newline "Flip time vs mu (eta=0.4, kappa=0.4):"
list mu_val ft_disc ft_oscillates ft_tstar, noobs sep(0)


// ==========================================================================
// PART 4. HOE statistics (chse_hoe)
// ==========================================================================
di as text _newline(2) "--- Part 4: HOE statistics ---"

// 4a. Stable HOE
clear
set obs 300
set seed 42
gen h = 0.65
replace h = h[_n-1] - 0.15*(h[_n-1]-0.80) + rnormal(0, 0.03) if _n > 1
replace h = min(1, max(0, h))

chse_hoe h, burnin(60) windows(4)

// 4b. Oscillatory HOE
clear
set obs 500
set seed 123
gen h = 0.5
replace h = h[_n-1] - 0.10*(h[_n-1]-0.5) + rnormal(0, 0.09) if _n > 1
replace h = min(1, max(0, h))

chse_hoe h, burnin(80) windows(5)

// 4c. Contested vs monetary sub-periods
clear
set obs 400
set seed 7
gen year      = 2000 + _n
gen contested = (year >= 2020)
gen h = 0.75
replace h = h[_n-1] - 0.08*(h[_n-1]-0.7) + rnormal(0, 0.04) ///
    if _n > 1 & !contested
replace h = h[_n-1] - 0.06*(h[_n-1]-0.5) + rnormal(0, 0.12) ///
    if _n > 1 & contested
replace h = min(1, max(0, h))

di as text _newline "Pre-2020 (monetary dominance):"
chse_hoe h if !contested, burnin(5)
di as text _newline "Post-2020 (contested period):"
chse_hoe h if contested, burnin(5)


// ==========================================================================
// PART 5. Welfare distortions (chse_welfare)
// ==========================================================================
di as text _newline(2) "--- Part 5: Welfare distortions ---"

// 5a. Scalar call — no dataset required
// Note: option names have no underscores (Stata syntax requirement)
//   betar    = beta_R   (reframing spillover)
//   zetaii   = zeta_II  (ambiguity spillover)
//   cmu      = c_mu     (cost of reframing)
//   ckappa   = c_kappa  (cost of credibility)
//   ambiguity = avg_ambiguity
//   degree   = avg_degree
chse_welfare, eta(0.5) kappa(0.6) gamma(0.4)  ///
              betar(0.15) zetaii(0.3)           ///
              cmu(0.3) ckappa(0.3)              ///
              ambiguity(0.35) degree(2)         ///
              nedges(3)

di as text _newline "r(welfare_loss) = " as result r(welfare_loss)

// 5b. Sweep over gamma — extract local before passing to command
clear
local nobs 20
set obs `nobs'
gen gamma_val    = 0.02 + (_n-1)*0.04
gen welfare_loss = .

forvalues i = 1/`nobs' {
    local g_i = gamma_val[`i']
    quietly chse_welfare, eta(0.5) kappa(0.6) gamma(`g_i') ///
        betar(0.15) zetaii(0.3) cmu(0.3) ckappa(0.3) ///
        ambiguity(0.35) degree(2) nedges(3)
    quietly replace welfare_loss = r(welfare_loss) in `i'
}

di as text _newline "Welfare loss vs gamma:"
list gamma_val welfare_loss, noobs sep(0)

// 5c. From edge-level h data
clear
input float h_edge
    0.52
    0.85
    0.48
end
chse_welfare h_edge, eta(0.5) kappa(0.6) gamma(0.4) ///
             betar(0.15) zetaii(0.3) cmu(0.3) ckappa(0.3)


// ==========================================================================
// PART 6. Hierarchy Persistence Paradox (chse_paradox)
// ==========================================================================
di as text _newline(2) "--- Part 6: Hierarchy Persistence Paradox ---"

// 6a. Using HSI directly
// Note: option names have no underscores:
//   alphar   = alpha_R   (belief drop per reframe)
//   accfloor = acc_floor
//   accceiling = acc_ceiling
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

// 6b. Using FDI as input
clear
input float disruption float fdi str8 country
    0.10  1.82  "Turkey"
    0.12  1.40  "Zambia"
    0.38  0.91  "Brazil"
    0.59  0.54  "US_2020"
    1.38  0.22  "Chile"
    1.61  0.18  "US_2000"
end

di as text _newline "Using FDI as input:"
chse_paradox disruption fdi, fdi

// 6c. Generate predicted columns
clear
input float disruption float hsi str8 country
    0.10  0.55  "Turkey"
    0.12  0.71  "Zambia"
    0.38  1.10  "Brazil"
    0.59  1.84  "US_2020"
    1.38  4.52  "Chile"
    1.61  5.53  "US_2000"
end

chse_paradox disruption hsi, gen(pred) replace alphar(0.5) trust(0.65) phi(0.60)

di as text _newline "Predicted cascade sizes:"
list country hsi pred_acc pred_rhoK pred_cascade, noobs sep(0)


// ==========================================================================
di as text _newline(2) "=== All parts completed successfully ==="
