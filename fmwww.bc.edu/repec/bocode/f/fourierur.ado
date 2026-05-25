*! fourierur v1.0 - Main entry point for Fourier unit root / stationarity tests
*! Dispatches to one of six tests, or runs all of them.
*! Compatible with Stata 14+
*! Package: fourierur v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 21 May 2026

program define fourierur, rclass
    version 14
    syntax varname(ts) [if] [in] [,           ///
        TEST(string)                          ///
        Model(integer 2)                      ///
        Kmax(real 5)                          ///
        K(real 0)                             ///
        Pmax(integer 8)                       ///
        IC(integer 3)                         ///
        NOTrend                               ///
        GRAPH                                 ///
        KFmin(real 0.1)                       ///
        KFmax(real 2.0)                       ///
        KFstep(real 0.1)                      ///
        KFr(real 0)                           ///
        noFtest                               ///
        DK(real 1)                            ///
        BOOTstrap                             ///
        BREPS(integer 500)                    ///
    ]

    if "`notrend'" != "" {
        local model = 1
    }

    if "`test'" == "" local test "all"
    local test = strlower("`test'")

    local valid "lm df gls kpss fffff dfdf all"
    local ok 0
    foreach t of local valid {
        if "`test'" == "`t'" local ok 1
    }
    if `ok' == 0 {
        di as error "test(`test') is not valid."
        di as error "Choose one of: lm | df | gls | kpss | fffff | dfdf | all"
        exit 198
    }

    * Cast kmax/k to integers where the underlying command expects integers
    local kmax_i = int(`kmax')
    local k_i    = int(`k')

    * Option bundles for each underlying command
    local opts_lm    "kmax(`kmax_i') k(`k_i') pmax(`pmax') ic(`ic') `graph'"
    local opts_df    "model(`model') kmax(`kmax_i') k(`k_i') pmax(`pmax') ic(`ic') `graph'"
    local opts_gls   "model(`model') kmax(`kmax_i') k(`k_i') pmax(`pmax') ic(`ic') `graph'"
    local opts_kpss  "model(`model') kmax(`kmax_i') k(`k_i') `graph'"
    local opts_fff   "model(`model') kfmin(`kfmin') kfmax(`kfmax') kfstep(`kfstep') kfr(`kfr') pmax(`pmax') ic(`ic') `ftest' `graph'"
    local opts_dfdf  "model(`model') kmax(`kmax') dk(`dk') pmax(`pmax') ic(`ic') `graph'"
    if "`bootstrap'" != "" {
        local opts_dfdf "`opts_dfdf' bootstrap breps(`breps')"
    }

    if "`test'" == "all" {
        di as text ""
        di as text "{hline 70}"
        di as text "  fourierur: running all Fourier unit root / stationarity tests"
        di as text "  Variable: " as result "`varlist'"
        di as text "{hline 70}"
        di as text ""

        di as text "1. FOURIER LM TEST (Enders & Lee, 2012a)"
        di as text "{hline 50}"
        fourierlm `varlist' `if' `in', `opts_lm'
        di ""

        di as text "2. FOURIER ADF TEST (Enders & Lee, 2012b)"
        di as text "{hline 50}"
        fourierdf `varlist' `if' `in', `opts_df'
        di ""

        di as text "3. FOURIER GLS TEST (Rodrigues & Taylor, 2012)"
        di as text "{hline 50}"
        fouriergls `varlist' `if' `in', `opts_gls'
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
        return local test "all"
        exit
    }

    * Single-test dispatch
    if "`test'" == "lm" {
        fourierlm `varlist' `if' `in', `opts_lm'
    }
    else if "`test'" == "df" {
        fourierdf `varlist' `if' `in', `opts_df'
    }
    else if "`test'" == "gls" {
        fouriergls `varlist' `if' `in', `opts_gls'
    }
    else if "`test'" == "kpss" {
        fourierkpss `varlist' `if' `in', `opts_kpss'
    }
    else if "`test'" == "fffff" {
        fourierfffff `varlist' `if' `in', `opts_fff'
    }
    else if "`test'" == "dfdf" {
        fourierdfdf `varlist' `if' `in', `opts_dfdf'
    }

    return add
    return local test "`test'"
end
