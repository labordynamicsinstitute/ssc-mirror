*! qvar — Quantile Vector Autoregression for Stata
*! Version 1.1.0 — 2026-05-07
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*!
*! Implements methods from:
*!   Chavleishvili & Manganelli (2019) — QVAR estimation & forecasting
*!   Mayer, Wied & Troster (2025) — Quantile Granger causality
*!   Carboni et al. (2024) — VAR-QR Growth-at-Risk
*!   Surprenant (2025) — QVAR forecast evaluation
*!   White, Kim & Manganelli (2015) — QIRF foundations

program define qvar, eclass
    version 16.0

    // ─── Parse subcommand ───
    gettoken subcmd 0 : 0, parse(" ,")

    if "`subcmd'" == "" {
        di as error "Subcommand required."
        di as text ""
        di as text "  {bf:Usage:}"
        di as text "    {cmd:qvar estimate}  {it:varlist}, lags(#) [taus(numlist)]"
        di as text "    {cmd:qvar granger}   {it:depvar gcvar}, lags(#) [bootstrap(#)]"
        di as text "    {cmd:qvar varqr}     {it:varlist}, varlags(#) [taus(numlist)]"
        di as text "    {cmd:qvar forecast}, horizon(#) [nsims(#)]"
        di as text "    {cmd:qvar irf},      shockvar(name) [horizon(#)]"
        di as text "    {cmd:qvar evaluate}  {it:varlist}, actual(varname)"
        di as text "    {cmd:qvar plot}      {it:plottype} [, options]"
        di as text "    {cmd:qvar table}     {it:tabletype} [, options]"
        exit 198
    }

    local subcmd = lower("`subcmd'")

    if "`subcmd'" == "estimate" {
        _qvar_estimate `0'
    }
    else if "`subcmd'" == "granger" {
        _qvar_granger `0'
    }
    else if "`subcmd'" == "varqr" {
        _qvar_varqr `0'
    }
    else if "`subcmd'" == "forecast" {
        _qvar_forecast `0'
    }
    else if "`subcmd'" == "irf" {
        _qvar_irf `0'
    }
    else if "`subcmd'" == "evaluate" {
        _qvar_evaluate `0'
    }
    else if "`subcmd'" == "plot" {
        _qvar_plot `0'
    }
    else if "`subcmd'" == "table" {
        _qvar_table `0'
    }
    else {
        di as error "Unknown subcommand: `subcmd'"
        di as error "Available: estimate, granger, varqr, forecast, irf, evaluate, plot, table"
        exit 198
    }
end
