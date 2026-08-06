*! causalimpact_p 1.0.0  05aug2026
*! predict after causalimpact
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! GitHub: https://github.com/merwanroudane

program define causalimpact_p
    version 14.0

    if ("`e(cmd)'" != "causalimpact") {
        di as err "predict after causalimpact requires causalimpact results"
        error 301
    }

    syntax newvarname [if] [in] ,                                       ///
        [ COUNTerfactual LOWer UPPer                                    ///
          CUMCounterfactual CUMLower CUMUpper                           ///
          EFFect EFFLower EFFUpper                                      ///
          CUMEffect CUMEFFLower CUMEFFUpper                             ///
          RESPonse CUMResponse AVGEffect                                ///
          XB ]

    local nopt = 0
    foreach o in counterfactual lower upper cumcounterfactual cumlower  ///
                 cumupper effect efflower effupper cumeffect            ///
                 cumefflower cumeffupper response cumresponse           ///
                 avgeffect xb {
        if ("``o''" != "") local nopt = `nopt' + 1
    }
    if (`nopt' > 1) {
        di as err "only one statistic may be requested at a time"
        exit 198
    }
    if (`nopt' == 0) local counterfactual "counterfactual"

    marksample touse, novarlist

    * --- xb: the regression (synthetic-control) component only --------------
    if ("`xb'" != "") {
        if (e(k_covariates) == 0) {
            di as err "the fitted model has no regression component; xb is not available"
            exit 198
        }
        _predict `typlist' `varlist' if `touse', xb
        label variable `varlist' "Regression (synthetic control) component"
        exit
    }

    * --- stored counterfactual series ---------------------------------------
    local col = 1
    local lbl "Counterfactual (posterior mean)"

    if ("`lower'" != "")             local col = 2
    if ("`lower'" != "")             local lbl "Counterfactual lower bound"
    if ("`upper'" != "")             local col = 3
    if ("`upper'" != "")             local lbl "Counterfactual upper bound"
    if ("`cumcounterfactual'" != "") local col = 4
    if ("`cumcounterfactual'" != "") local lbl "Cumulative counterfactual"
    if ("`cumlower'" != "")          local col = 5
    if ("`cumlower'" != "")          local lbl "Cumulative counterfactual lower"
    if ("`cumupper'" != "")          local col = 6
    if ("`cumupper'" != "")          local lbl "Cumulative counterfactual upper"
    if ("`effect'" != "")            local col = 7
    if ("`effect'" != "")            local lbl "Pointwise causal effect"
    if ("`efflower'" != "")          local col = 8
    if ("`efflower'" != "")          local lbl "Pointwise effect lower bound"
    if ("`effupper'" != "")          local col = 9
    if ("`effupper'" != "")          local lbl "Pointwise effect upper bound"
    if ("`cumeffect'" != "")         local col = 10
    if ("`cumeffect'" != "")         local lbl "Cumulative causal effect"
    if ("`cumefflower'" != "")       local col = 11
    if ("`cumefflower'" != "")       local lbl "Cumulative effect lower bound"
    if ("`cumeffupper'" != "")       local col = 12
    if ("`cumeffupper'" != "")       local lbl "Cumulative effect upper bound"
    if ("`response'" != "")          local col = 13
    if ("`response'" != "")          local lbl "Observed response"
    if ("`cumresponse'" != "")       local col = 14
    if ("`cumresponse'" != "")       local lbl "Cumulative observed response"
    if ("`avgeffect'" != "")         local col = 15
    if ("`avgeffect'" != "")         local lbl "Running-average causal effect"

    capture mata: _causalimpact_check()
    if (_rc | "`_ci_have'" == "0") {
        di as err "the fitted series are no longer in memory (Mata was cleared,"
        di as err "or causalimpact was re-loaded). Re-run causalimpact, or use"
        di as err "its generate() option to keep the series permanently."
        exit 498
    }

    qui gen `typlist' `varlist' = .
    mata: _causalimpact_put(`col', "`varlist'", "`touse'")
    label variable `varlist' "`lbl'"
end


version 14.0
mata:

void _causalimpact_check()
{
    external real matrix _causalimpact_series
    if (rows(_causalimpact_series) < 1) {
        st_local("_ci_have", "0")
        return
    }
    st_local("_ci_have", "1")
}

void _causalimpact_put(real scalar col, string scalar nm, string scalar tousev)
{
    external real matrix    _causalimpact_series
    external real colvector _causalimpact_rows

    real colvector rw, vals, tu, keepi

    rw   = _causalimpact_rows
    vals = _causalimpact_series[., col]

    tu    = st_data(rw, tousev)
    keepi = selectindex(tu :!= 0)
    if (length(keepi) == 0) {
        return
    }
    st_store(rw[keepi], nm, vals[keepi])
}

end
