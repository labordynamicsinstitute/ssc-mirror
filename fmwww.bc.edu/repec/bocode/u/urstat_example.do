* ==============================================================================
*  URSTAT v1.3.0 — Example Do-file
*  Author: Dr. Merwan Roudane
*  Email:  merwanroudane920@gmail.com
*  Date:   11 March 2026
* ==============================================================================
*
*  This file demonstrates all features of the urstat command using the
*  Lutkepohl (2005) macroeconomic dataset shipped with Stata.
*
*  Required user-written packages (install once):
*    ssc install kpss
*    ssc install zandrews
*    ssc install clemao_io
*    ssc install ersur
*    ssc install kmtest
*  Bootstrap test (from Stata Journal):
*    search bsrwalkdrift
*
* ==============================================================================

clear all
set more off

* --- Load Lutkepohl's macroeconomic dataset ---
webuse lutkepohl2, clear
describe
list in 1/5

* The dataset contains quarterly data (1960q1–1982q4) with:
*   ln_inv      log of investment
*   ln_inc      log of income
*   ln_consump  log of consumption

tsset qtr

* ==============================================================================
*  Example 1: Full analysis — all tests + strategy + Table 6 consensus
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 1: Full Analysis (all tests + decision tables)"
di "{hline 70}" _n

* This runs Tables 1–6 including:
*   Table 1: ADF / PP / KPSS (Level, 1st Diff, 2nd Diff)
*   Table 2: ZA & Clemente structural breaks (Level, 1st Diff, 2nd Diff)
*   Table 3: ERS/DF-GLS & Bootstrap (Level, 1st Diff, 2nd Diff)
*   Table 4: Kobayashi-McAleer linear vs log test
*   Table 5: Elder-Kennedy decision with ADF/PP/KPSS/ERS/ZA columns
*   Table 6: Per-test integration order consensus (ADF/PP/KPSS/ERS/ZA/BSRW/Clem)

urstat ln_inv ln_inc ln_consump, strategy

* ==============================================================================
*  Example 2: Full analysis with graph export
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 2: Strategy + Graph Export"
di "{hline 70}" _n

* Produces all tables + exports PNG graphs:
*   - Time series panels (Level, 1st Diff, 2nd Diff)
*   - ACF/PACF correlograms
*   - Structural break plots with ZA break date lines
*   - Integration order summary bar chart

urstat ln_inv ln_inc ln_consump, strategy graph graphdir("urstat_graphs")

* Check saved graphs
di _n "Named graphs in memory:"
graph dir

* ==============================================================================
*  Example 3: ADF test only
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 3: ADF Test Only"
di "{hline 70}" _n

urstat ln_inv ln_inc, test(ADF)

* ==============================================================================
*  Example 4: Standard tests (ADF + PP + KPSS) with "None" specification
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 4: ADF + PP + KPSS with None column"
di "{hline 70}" _n

* The 'none' option adds a "No constant, no trend" column to Table 1
urstat ln_inv, test(ADF PP KPSS) none

* ==============================================================================
*  Example 5: Structural break tests only
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 5: Zivot-Andrews + Clemente"
di "{hline 70}" _n

urstat ln_inv ln_inc, test(ZA CLEMAO1 CLEMAO2 CLEMIO1 CLEMIO2)

* ==============================================================================
*  Example 6: Advanced tests (ERS + Bootstrap)
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 6: ERS/DF-GLS + Bootstrap"
di "{hline 70}" _n

urstat ln_inv ln_inc, test(ERS BSRW) bsreps(200) ersmethod(SIC)

* ==============================================================================
*  Example 7: Kobayashi-McAleer transformation test
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 7: Kobayashi-McAleer Linear vs Log Test"
di "{hline 70}" _n

* Only works with positive-valued series
urstat ln_inv ln_inc, test(KM) kmlags(2)

* ==============================================================================
*  Example 8: Custom options
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 8: Custom lag selection & trimming"
di "{hline 70}" _n

* AIC criterion, max 8 lags, ZA trim 10%
urstat ln_inv, test(ADF ZA) maxlag(8) crit(AIC) ztrim(0.10) strategy

* ==============================================================================
*  Example 9: Suppress significance stars
* ==============================================================================
di _n "{hline 70}"
di "  EXAMPLE 9: Clean output without stars"
di "{hline 70}" _n

urstat ln_inv, test(ADF PP) nostars

* ==============================================================================
di _n as res "  All examples completed successfully!"
di as txt "  PNG graphs saved to: urstat_graphs/"
di as txt "  Use {bf:graph dir} to list named graphs."
di as txt "  Use {bf:graph display <name>} to re-display any graph."
di as txt ""
di as txt "  Quick reference:"
di as txt "    graph display _urs_ts_ln_inv      // Time series panels"
di as txt "    graph display _urs_corr_ln_inv    // ACF/PACF"  
di as txt "    graph display _urs_brk_ln_inv     // Structural breaks"
di as txt "    graph display _urs_decision        // Integration order summary"
