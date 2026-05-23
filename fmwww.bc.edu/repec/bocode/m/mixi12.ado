*! mixi12 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Main entry for the mixi12 library.  Two usage modes:
*
*  (1) End-to-end analysis (no sub-command):
*         mixi12 varlist [if] [in] , [ LAGS(integer) TREND(string)
*                                       ALL  UNIT  HALDrup  JOhansen
*                                       SAVing(string) ]
*      Runs the unit-root battery, then the Haldrup single-equation
*      cointegration test (with the first variable as dependent and
*      the rest classified by the integration table), then the joint
*      Paruolo Q test for the I(2) VAR rank.
*
*  (2) Forward to a sub-command:
*         mixi12 SUB ...
*         where SUB ∈ { unit | haldrup | johansen | trans | sw |
*                       sim | graph | cv }.

program define mixi12
    version 14
    if `"`0'"' == "" {
        di as text "{p 2 4 2}{cmd:mixi12} - mixed I(1) and I(2) cointegration analysis."
        di as text "{p 2 4 2}Type {help mixi12:help mixi12} for a full overview."
        exit 0
    }
    gettoken first rest : 0, parse(" ,")
    local lc = strlower("`first'")
    if inlist("`lc'", "unit","haldrup","johansen","trans","sw","sim","graph","cv","mco") | ///
       inlist("`lc'", "mco_compare","gl","egh") {
        mixi12_`lc' `rest'
        exit
    }
    // otherwise treat as end-to-end varlist syntax
    _mixi12_main `0'
end

program define _mixi12_main, rclass
    version 14
    syntax varlist(ts numeric) [if] [in],   ///
        [                                    ///
        LAGS(integer 2)                      ///
        TREND(string)                        ///
        ALL                                  ///
        UNIT                                 ///
        HALDrup                              ///
        JOhansen                             ///
        SAVing(string)                       ///
        ]

    if "`trend'" == "" local trend "c"
    if "`all'`unit'`haldrup'`johansen'" == "" {
        local all "all"
    }
    if "`all'" != "" {
        local unit "unit"
        local haldrup "haldrup"
        local johansen "johansen"
    }

    di as text "{hline 78}"
    di as text "{bf:mixi12 — end-to-end mixed I(1)/I(2) cointegration analysis}"
    di as text "{hline 78}"
    di as text _col(2) "Variables :" _col(20) "`varlist'"
    di as text _col(2) "Trend     :" _col(20) "`trend'"
    di as text _col(2) "Lags      :" _col(20) "`lags'"
    di as text _col(2) "Sample    :" _col(20) "`if' `in'"
    di as text "{hline 78}"

    // map mixi12 trend codes ('none'/'c'/'ct') to dptest det codes
    local det = cond("`trend'"=="none","none", ///
                cond("`trend'"=="c","const", ///
                cond("`trend'"=="ct","trend","const")))

    // (1) integration-order battery (delegated to dptest)
    tempname IO
    if "`unit'" != "" {
        mixi12_unit `varlist' `if' `in', det(`det')
        matrix `IO' = r(order)
    }

    // build I1/I2 lists from the battery
    local i1list ""
    local i2list ""
    local i 0
    foreach v of varlist `varlist' {
        local ++i
        local ord = `IO'[`i',1]
        if `ord' == 2  local i2list `i2list' `v'
        else if `ord' == 1 local i1list `i1list' `v'
    }

    // (2) Haldrup single-equation I(2) cointegration test
    if "`haldrup'" != "" {
        local depvar : word 1 of `varlist'
        local rest : list varlist - depvar
        local i1u : list rest - i2list
        local i2u : list i2list - depvar
        // require at least one I(2) regressor besides the dep
        if "`i2u'" == "" {
            di as text "{p 2 4 2}Note: no I(2) regressors detected — skipping Haldrup test." ///
                       "  Re-run with explicit i1()/i2() if needed.{p_end}"
        }
        else {
            local i1u_show "`i1u'"
            if "`i1u_show'" == "" local i1u_show "(none)"
            di as text
            di as text _col(2) "Running Haldrup with dep = `depvar', "  ///
                "I(1) = `i1u_show', I(2) = `i2u'"
            mixi12_haldrup `depvar' `if' `in', i1(`i1u') i2(`i2u') ///
                det(`det') crit(bic)
        }
    }

    // (3) Joint Paruolo Q test
    if "`johansen'" != "" {
        mixi12_johansen `varlist' `if' `in', lags(`lags') trend("`trend'") joint
    }

    di as text "{hline 78}"
    di as text "{bf:mixi12 analysis complete.}"
    di as text "{hline 78}"
end
