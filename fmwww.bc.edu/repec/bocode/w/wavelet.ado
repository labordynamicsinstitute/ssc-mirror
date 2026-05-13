*! wavelet — Main dispatcher for the lwavelet package
*! Version 1.1.0  2026-05-11
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*!
*! Usage:
*!   wavelet modwt  varname, [options]    — MODWT decomposition (calls lmodwt)
*!   wavelet wt     varname, [options]    — Continuous wavelet transform
*!   wavelet xwt    var1 var2, [options]  — Cross-wavelet transform
*!   wavelet wtc    var1 var2, [options]  — Wavelet coherence
*!   wavelet wmcorr varlist, [options]    — Wavelet multiple correlation
*!   wavelet wmreg  varlist, [options]    — Wavelet multiple regression
*!   wavelet wmxcorr varlist, [options]   — Wavelet cross-correlation
*!   wavelet about                        — Package information

program define wavelet
    version 11

    gettoken subcmd 0 : 0

    if ("`subcmd'" == "") {
        _wavelet_about
        exit
    }

    local subcmd = lower(trim("`subcmd'"))

    * Dispatch to subcommand
    if ("`subcmd'" == "modwt" | "`subcmd'" == "lmodwt") {
        lmodwt `0'
    }
    else if ("`subcmd'" == "wt" | "`subcmd'" == "cwt") {
        wt `0'
    }
    else if ("`subcmd'" == "xwt") {
        xwt `0'
    }
    else if ("`subcmd'" == "wtc") {
        wtc `0'
    }
    else if ("`subcmd'" == "wmcorr") {
        wmcorr `0'
    }
    else if ("`subcmd'" == "wmreg") {
        wmreg `0'
    }
    else if ("`subcmd'" == "wmxcorr") {
        wmxcorr `0'
    }
    else if ("`subcmd'" == "about" | "`subcmd'" == "version") {
        _wavelet_about
    }
    else if ("`subcmd'" == "filters") {
        _wavelet_filters
    }
    else {
        di as error `"Unknown subcommand: `subcmd'"'
        di as error "Available: lmodwt (or modwt), wt, xwt, wtc, wmcorr, wmreg, wmxcorr, about, filters"
        exit 198
    }
end

* ═════════════════════════════════════════════════════════════
* About / version information
* ═════════════════════════════════════════════════════════════
program define _wavelet_about
    di as text ""
    di as text "  {hline 65}"
    di as result "  {bf:lwavelet} — Wavelet Analysis for Time Series"
    di as text "  {hline 65}"
    di as text ""
    di as text "  Version:     {res}1.1.0"
    di as text "  Date:        {res}2026-05-11"
    di as text "  Author:      {res}Dr. Merwan Roudane"
    di as text "  Email:       {res}merwanroudane920@gmail.com"
    di as text "  Requires:    {res}Stata 17+"
    di as text ""
    di as text "  {bf:Available Commands:}"
    di as text "  {hline 65}"
    di as text "  {bf:Discrete Wavelet Transforms}"
    di as result "    lmodwt   {txt}Maximal Overlap Discrete Wavelet Transform"
    di as text ""
    di as text "  {bf:Continuous Wavelet Transforms}"
    di as result "    wt       {txt}Continuous Wavelet Transform (CWT)"
    di as result "    xwt      {txt}Cross-Wavelet Transform"
    di as result "    wtc      {txt}Wavelet Coherence (Monte Carlo significance)"
    di as text ""
    di as text "  {bf:Multivariate Wavelet Analysis}"
    di as result "    wmcorr   {txt}Wavelet Multiple Correlation"
    di as result "    wmreg    {txt}Wavelet Multiple Regression"
    di as result "    wmxcorr  {txt}Wavelet Multiple Cross-Correlation"
    di as text ""
    di as text "  {bf:Utilities}"
    di as result "    wavelet filters  {txt}List available wavelet filters"
    di as result "    wavelet about    {txt}This information screen"
    di as text "  {hline 65}"
    di as text ""
    di as text "  {bf:Methodology References:}"
    di as text "    Torrence & Compo (1998) — CWT"
    di as text "    Grinsted et al. (2004) — XWT/WTC"
    di as text "    Fernandez-Macho (2012) — Wavelet multiple correlation"
    di as text "    Percival & Walden (2000) — DWT/MODWT theory"
    di as text ""
    di as text "  Type {res}help wavelet{txt} for detailed documentation."
    di as text ""
end

* ═════════════════════════════════════════════════════════════
* List available filters
* ═════════════════════════════════════════════════════════════
program define _wavelet_filters
    di as text ""
    di as text "  {hline 60}"
    di as text "  {bf:Available Wavelet Filters (25 total)}"
    di as text "  {hline 60}"
    di as text ""
    di as text "  {bf:Daubechies Family}"
    di as result "    haar (d2)  d4  d6  d8  d10  d12  d14  d16  d18  d20"
    di as text ""
    di as text "  {bf:Least Asymmetric Family}"
    di as result "    la8  la10  la12  la14  la16  la18  la20"
    di as text ""
    di as text "  {bf:Best Localized Family}"
    di as result "    bl14  bl18  bl20"
    di as text ""
    di as text "  {bf:Coiflet Family}"
    di as result "    c6  c12  c18  c24  c30"
    di as text ""
    di as text "  Default: {res}la8{txt} (Least Asymmetric, length 8)"
    di as text "  {hline 60}"
    di as text ""
end
