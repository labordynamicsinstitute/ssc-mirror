*! fourierall v2.0 - Run all Fourier unit root tests
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierall, rclass
    version 14
    syntax varname(ts) [if] [in] [, Model(integer 2) Kmax(integer 5) K(integer 0) Pmax(integer 8) IC(integer 3) NOTrend GRAPH]

    if "`notrend'" != "" {
        local model = 1
    }
    local opts_all  "model(`model') kmax(`kmax') k(`k') pmax(`pmax') ic(`ic') `graph'"
    local opts_lm   "kmax(`kmax') k(`k') pmax(`pmax') ic(`ic') `graph'"
    local opts_kpss "model(`model') kmax(`kmax') k(`k') `graph'"
    local opts_fff  "model(`model') pmax(`pmax') ic(`ic') `graph'"
    local opts_dfdf "model(`model') pmax(`pmax') ic(`ic') `graph'"

    di as text ""
    di as text "{hline 70}"
    di as text "  Running all Fourier Unit Root Tests for: " as result "`varlist'"
    di as text "{hline 70}"
    di as text ""

    di as text "1. FOURIER LM TEST (Enders & Lee, 2012a)"
    di as text "{hline 50}"
    fourierlm `varlist' `if' `in', `opts_lm'
    local lm_k = r(k)
    local lm_p = r(p)
    di ""

    di as text "2. FOURIER ADF TEST (Enders & Lee, 2012b)"
    di as text "{hline 50}"
    fourierdf `varlist' `if' `in', `opts_all'
    local df_k = r(k)
    local df_p = r(p)
    di ""

    di as text "3. FOURIER GLS TEST (Rodrigues & Taylor, 2012)"
    di as text "{hline 50}"
    fouriergls `varlist' `if' `in', `opts_all'
    di ""

    di as text "4. FOURIER KPSS TEST (Becker, Enders & Lee, 2006)"
    di as text "{hline 50}"
    fourierkpss `varlist' `if' `in', `opts_kpss'
    di ""

    di as text "5. FFFFF-DF TEST (Omay, 2015)"
    di as text "{hline 50}"
    fourierfffff `varlist' `if' `in', `opts_fff'
    di ""

    di as text "6. DOUBLE FREQUENCY FOURIER DF TEST (Cai & Omay, 2021)"
    di as text "{hline 50}"
    fourierdfdf `varlist' `if' `in', `opts_dfdf'
    di ""

    di as text "{hline 70}"
    di as text "  All Fourier unit root tests completed."
    di as text "{hline 70}"
end
