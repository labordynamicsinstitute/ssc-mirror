* rdstagger_montecarlo.do
* Monte Carlo validation for rdstagger and rdstagger_spillover
* For use in Stata Journal article
* Subir Hait 2026

version 14
clear all
set more off
set seed 20260515

* -------------------------------------------------------
* Parameters
* -------------------------------------------------------
local REPS    200       // replications (use 500+ for publication)
local N       400
local PERIODS 8
local COHORTS 3
local BW      1.5

* Scenarios: varying direct and spillover effects
local n_scen  4
local directs  "0.3  0.3  0.5  0.5"
local spills   "0.0  0.1  0.0  0.2"

* -------------------------------------------------------
* Storage matrix: rows=scenarios, cols=metrics
* direct_true, direct_mean, direct_bias, direct_rmse,
* spill_true,  spill_mean,  spill_bias,  spill_rmse
* -------------------------------------------------------
matrix RESULTS = J(`n_scen', 8, .)

local scen = 0
foreach d of local directs {
    foreach s of local spills {
        * Skip combinations not in our list
    }
}

* Manual loop over 4 scenarios
forvalues sc = 1/`n_scen' {

    local d = word("`directs'", `sc')
    local s = word("`spills'",  `sc')

    local sum_att    = 0
    local sum_att2   = 0
    local sum_spill  = 0
    local sum_spill2 = 0
    local ok = 0

    forvalues rep = 1/`REPS' {

        cap {
            qui rdstagger_sim, n(`N') periods(`PERIODS') cohorts(`COHORTS') ///
                direct(`d') spill(`s') seed(`rep') outcome(continuous)

            qui rdstagger y x, cutoff(0) gvar(g) tvar(period) ///
                idvar(id) bw(`BW') kernel(triangular) control(nevertreated)

            qui rdstagger_agg, type(overall)
            local att_est = e(overall_att)

            qui rdstagger_spillover
            tempname SP
            matrix `SP' = e(spillover)
            local nsp = rowsof(`SP')

            * Average spillover ATT over post-treatment cells
            local spill_sum = 0
            local spill_n   = 0
            forvalues r = 1/`nsp' {
                if `SP'[`r',4] < . & `SP'[`r',4] != 0 {
                    local spill_sum = `spill_sum' + `SP'[`r',4]
                    local ++spill_n
                }
            }
            if `spill_n' > 0 {
                local spill_est = `spill_sum' / `spill_n'
            }
            else {
                local spill_est = 0
            }

            local sum_att   = `sum_att'   + `att_est'
            local sum_att2  = `sum_att2'  + `att_est'^2
            local sum_spill = `sum_spill' + `spill_est'
            local sum_spill2= `sum_spill2'+ `spill_est'^2
            local ++ok
        }

        if `rep' == round(`REPS'/4) {
            noi di as txt "  Scenario `sc', rep `rep'/`REPS' ..."
        }
    }

    if `ok' > 0 {
        local att_mean  = `sum_att'   / `ok'
        local att_bias  = `att_mean'  - `d'
        local att_rmse  = sqrt(`sum_att2'/`ok' - `att_mean'^2 + `att_bias'^2)

        local sp_mean   = `sum_spill'  / `ok'
        local sp_bias   = `sp_mean'    - `s'
        local sp_rmse   = sqrt(`sum_spill2'/`ok' - `sp_mean'^2 + `sp_bias'^2)
    }
    else {
        local att_mean  = .
        local att_bias  = .
        local att_rmse  = .
        local sp_mean   = .
        local sp_bias   = .
        local sp_rmse   = .
    }

    matrix RESULTS[`sc',1] = `d'
    matrix RESULTS[`sc',2] = `att_mean'
    matrix RESULTS[`sc',3] = `att_bias'
    matrix RESULTS[`sc',4] = `att_rmse'
    matrix RESULTS[`sc',5] = `s'
    matrix RESULTS[`sc',6] = `sp_mean'
    matrix RESULTS[`sc',7] = `sp_bias'
    matrix RESULTS[`sc',8] = `sp_rmse'
}

* -------------------------------------------------------
* Display Monte Carlo table
* -------------------------------------------------------
di _newline as txt "Monte Carlo Validation (N=`N', T=`PERIODS', reps=`REPS')"
di as txt "{hline 80}"
di as txt %6s "True" %10s "ATT est." %10s "Bias" %10s "RMSE" ///
          %6s "True" %10s "Spill." %10s "Bias" %10s "RMSE"
di as txt %6s "ATT"  %10s ""        %10s ""     %10s ""     ///
          %6s "spill" %10s "est."   %10s ""     %10s ""
di as txt "{hline 80}"

forvalues sc = 1/`n_scen' {
    di as res %6.2f RESULTS[`sc',1] %10.4f RESULTS[`sc',2] ///
              %10.4f RESULTS[`sc',3] %10.4f RESULTS[`sc',4]  ///
              %6.2f RESULTS[`sc',5] %10.4f RESULTS[`sc',6]  ///
              %10.4f RESULTS[`sc',7] %10.4f RESULTS[`sc',8]
}
di as txt "{hline 80}"
di as txt "ATT = overall average treatment effect; Spill. = average spillover ATT(g,t)"
