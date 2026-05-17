*! rals 1.0.1  16may2026
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Residual Augmented Least Squares (RALS) unit root and cointegration tests
*------------------------------------------------------------------------------
* Master / information command.  Invokes nothing by itself; provides a
* one-stop banner and a routing table for the eight commands in the package.
*------------------------------------------------------------------------------

program define rals
    version 14.0
    capture mata: __rals_loaded()
    if _rc qui _rals_mata
    syntax [anything] [, Version About Help ]

    * no argument at all -> show banner
    if "`anything'"=="" & "`version'"=="" & "`about'"=="" & "`help'"=="" {
        _rals_banner
        exit 0
    }

    * recognise about/help/version as either positional or option
    local first : word 1 of `anything'
    local first = lower("`first'")

    if "`first'"=="version" | "`version'" != "" {
        di as result "rals " as text "1.0.1  (16 May 2026)"
        di as text   "  Author: Dr Merwan Roudane <merwanroudane920@gmail.com>"
        exit 0
    }
    if "`first'"=="about" | "`first'"=="help" | "`about'" != "" | "`help'" != "" {
        _rals_banner
        exit 0
    }

    * otherwise treat the first word as a rals subcommand name
    local valid "ralsadf ralslm ralslmb ralsfadf ralsfkss ralsbattery ralscoint ralsfadl ralsdiag"
    if !`: list first in valid' {
        di as error "{bf:`first'} is not a {bf:rals} subcommand."
        di as text  "Available: " as result "`valid'"
        di as text  "Type " as result "rals about" as text " for the full menu."
        exit 199
    }
    local rest : list anything - first
    `first' `rest'
end

program define _rals_banner
    di as text ""
    di as text "{hline 78}"
    di as text "  {bf:RALS}  -- Residual Augmented Least Squares unit-root & cointegration"
    di as text "{hline 78}"
    di as text "  Stata implementation of every test in the RALS family."
    di as text ""
    di as text "  {bf:Unit-root tests}"
    di as text "    {stata ralsadf:ralsadf}    RALS-ADF                Im, Lee & Tieslau (2014)"
    di as text "    {stata ralslm:ralslm}      RALS-LM                 Meng, Im, Lee & Tieslau (2014)"
    di as text "    {stata ralslmb:ralslmb}    RALS-LM with breaks    Meng, Lee & Payne (2017)"
    di as text "    {stata ralsfadf:ralsfadf}  RALS-Fourier ADF       Yilanci, Aydin & Aydin (2019)"
    di as text "    {stata ralsfkss:ralsfkss}  RALS-Fourier KSS       Yilanci & Ozgur (2025)"
    di as text "    {stata ralsbattery:ralsbattery}  Run ALL unit-root tests at once on a single series"
    di as text ""
    di as text "  {bf:Cointegration tests}"
    di as text "    {stata ralscoint:ralscoint}  RALS-ECM/ADL/EG/EG2  Lee, Lee & Im (2015, SNDE)"
    di as text "    {stata ralsfadl:ralsfadl}    RALS-Fourier ADL     Yilanci, Ulucak, Zhang & Andreoni (2022)"
    di as text ""
    di as text "  {bf:Diagnostics}"
    di as text "    {stata ralsdiag:ralsdiag}    Normality, linearity & RALS rho^2 diagnostics"
    di as text ""
    di as text "{hline 78}"
    di as text "  Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>"
    di as text "  Version: 1.0.1  --  16 May 2026"
    di as text "  Help   : {help rals}    --    Quick start: type {bf:doc rals_demo.do}"
    di as text "{hline 78}"
    di as text ""
end
