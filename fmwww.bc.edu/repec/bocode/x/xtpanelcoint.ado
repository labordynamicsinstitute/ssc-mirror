*! xtpanelcoint v1.1.0
*! Panel Cointegration & Multiple Long-Run Relations Estimation
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! References:
*!   [1] Chudik, Pesaran & Smith (2023) "Revisiting the Great Ratios"
*!   [2] Choi & Chudik (2024) "Mean Group Distributed Lag Estimation"
*!   [3] Chudik, Pesaran & Smith (2025) "Multiple Long-Run Relations"

program define xtpanelcoint, eclass
    version 14.0

    if replay() {
        if "`e(cmd)'" != "xtpanelcoint" {
            error 301
        }
        _xtpc_display
        exit
    }

    gettoken estimator 0 : 0, parse(" ,")
    local estimator = lower("`estimator'")

    if "`estimator'" == "plot" {
        _xtpc_plot `0'
        exit
    }

    if !inlist("`estimator'", "spmg", "breitung", "pdols", "mgmw") ///
     & !inlist("`estimator'", "mgdl", "pme") {
        di as error "{bf:xtpanelcoint}: unknown estimator '{it:`estimator'}'"
        di as error "Available: {bf:spmg breitung pdols mgmw mgdl pme plot}"
        exit 198
    }

    _xtpc_`estimator' `0'
end
