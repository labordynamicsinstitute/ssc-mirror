*! cobreakcoint_example.do — Replication of the empirical application
*! US Government Budget Sustainability (1947:Q1 – 2010:Q2)
*!
*! This example replicates Table 3 from the paper:
*!   "Quasi-likelihood ratio tests for cointegration, cobreaking,
*!    and cotrending" — Econometric Reviews (2019).

clear all
set more off

// ─────────────────────────────────────────────────────────────────────────
//  Step 1: Load and prepare the US budget data
// ─────────────────────────────────────────────────────────────────────────

// Load bundled dataset
capture use "USbudget.dta", clear
if _rc {
    // If .dta not found, create from the bundled text file
    di as text "  Creating USbudget.dta from raw text file..."

    capture insheet using "USbudget.txt", tab clear
    if _rc {
        // Try alternate path
        local mypath : sysdir PLUS
        insheet using `"`mypath'c/cobreakcoint/USbudget.txt"', tab clear
    }

    rename v1 rev_gdp
    rename v2 exp_gdp
    capture rename v3 bal_gdp

    // Convert to percentages (*100) as in MATLAB code
    gen R = rev_gdp * 100
    gen E = exp_gdp * 100
    gen B = R - E

    // Create quarterly time variable: 1947:Q1 to 2010:Q2
    gen t = _n
    gen year = 1947 + floor((t-1)/4)
    gen quarter = mod(t-1, 4) + 1
    gen qdate = yq(year, quarter)
    format qdate %tq

    tsset qdate
    label var R "Government Revenues (% of GDP)"
    label var E "Government Expenditures (% of GDP)"
    label var B "Budget Balance (% of GDP)"
    label var qdate "Quarter"

    save "USbudget.dta", replace
}

// ─────────────────────────────────────────────────────────────────────────
//  Step 2: Describe the data
// ─────────────────────────────────────────────────────────────────────────
di ""
di as text "  ══════════════════════════════════════════════════════════════"
di as text "  {bf:US Government Budget Sustainability — Data Summary}"
di as text "  ══════════════════════════════════════════════════════════════"
summarize R E B, detail

// ─────────────────────────────────────────────────────────────────────────
//  Step 3: Time series plot (replicating Figure 1 from the paper)
// ─────────────────────────────────────────────────────────────────────────
di ""
di as text "  Plotting time series (Figure 1 from paper)..."

twoway (line R qdate, lcolor("68 114 196") lwidth(medthick)) ///
       (line E qdate, lcolor("192 0 0") lwidth(medthick)) ///
       (line B qdate, lcolor("112 173 71") lwidth(medium) lpattern(dash)), ///
    title("{bf:US Government Revenues, Expenditures & Balance}", ///
          size(medium) color(black)) ///
    subtitle("As percentage of GDP, 1947:Q1 – 2010:Q2", ///
             size(small) color(gs5)) ///
    ytitle("% of GDP", size(small)) ///
    xtitle("Quarter", size(small)) ///
    ylabel(-15(5)40, angle(0) labsize(small)) ///
    legend(order(1 "Revenues" 2 "Expenditures" 3 "Balance") ///
           rows(1) size(small) position(6)) ///
    graphregion(color(white) margin(small)) ///
    plotregion(margin(medium)) ///
    scheme(s2color) ///
    name(fig_usbudget, replace)

// ─────────────────────────────────────────────────────────────────────────
//  Step 4: Run cobreakcoint — Model II (main results, Table 3)
// ─────────────────────────────────────────────────────────────────────────
di ""
di as text "  ══════════════════════════════════════════════════════════════"
di as text "  {bf:Replication of Table 3 — Model II}"
di as text "  y = Expenditures (E), x = Revenues (R)"
di as text "  ══════════════════════════════════════════════════════════════"
di ""

cobreakcoint E R, model(2) maxbreaks(2) klags(1 3 5 7 9) plot

// ─────────────────────────────────────────────────────────────────────────
//  Step 5: Display stored results
// ─────────────────────────────────────────────────────────────────────────
di ""
di as text "  ══════════════════════════════════════════════════════════════"
di as text "  {bf:Stored Results}"
di as text "  ══════════════════════════════════════════════════════════════"
ereturn list

// ─────────────────────────────────────────────────────────────────────────
//  Step 6: Run Model I for comparison
// ─────────────────────────────────────────────────────────────────────────
di ""
di as text "  ══════════════════════════════════════════════════════════════"
di as text "  {bf:Model I (mean shifts only)}"
di as text "  ══════════════════════════════════════════════════════════════"
di ""

cobreakcoint E R, model(1) maxbreaks(2) klags(1 3 5 7)

di ""
di as text "  ══════════════════════════════════════════════════════════════"
di as text "  {bf:Example complete.}"
di as text "  ══════════════════════════════════════════════════════════════"
