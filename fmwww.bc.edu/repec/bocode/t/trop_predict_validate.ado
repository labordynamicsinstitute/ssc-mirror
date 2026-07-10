*! trop_predict_validate -- data consistency checks for postestimation

/*
    Verify that the dataset in memory is consistent with the estimation
    sample before computing postestimation predictions.

    Three validation levels are applied in sequence:

      1  (fast)        e(cmd)=="trop" and e(N_obs)==_N
      2  (structural)  panel dimensions (N, T) match e(N_units), e(N_periods)
      3  (strict)      datasignature hash comparison; requires -robust_check-

    Exit codes:
      301  no trop estimation results in memory
      459  sample size or panel structure mismatch
*/


program define trop_predict_validate
    version 17
    syntax, [RObust_check]

    // ---- level 1: estimation results and observation count ---------------

    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }

    local n_obs = e(N_obs)
    if `n_obs' != . & `n_obs' != _N {
        di as error "{hline}"
        di as error "sample size changed"
        di as error "  estimation sample: e(N_obs) = `n_obs'"
        di as error "  current dataset:   _N = " _N
        di as error ""
        di as error "restore the estimation sample or rerun {bf:trop}"
        di as error "{hline}"
        exit 459
    }

    // ---- level 2: panel dimensions (N units, T periods) -----------------

    local N_stored = e(N_units)
    local T_stored = e(N_periods)

    if `N_stored' != . & `T_stored' != . {
        local panelvar "`e(panelvar)'"
        local timevar  "`e(timevar)'"

        if "`panelvar'" != "" & "`timevar'" != "" {
            qui {
                // count distinct units and periods within e(sample)
                tempvar panel_id time_id
                egen `panel_id' = group(`panelvar') if e(sample)
                egen `time_id'  = group(`timevar')  if e(sample)

                sum `panel_id' if e(sample), meanonly
                local N_current = r(max)

                sum `time_id' if e(sample), meanonly
                local T_current = r(max)
            }

            if `N_current' != `N_stored' | `T_current' != `T_stored' {
                di as error "{hline}"
                di as error "panel structure changed"
                di as error "  estimation: N = `N_stored', T = `T_stored'"
                di as error "  current:    N = `N_current', T = `T_current'"
                di as error ""
                di as error "rerun {bf:trop} on the current dataset"
                di as error "{hline}"
                exit 459
            }
        }
    }

    // ---- level 3: datasignature hash (robust_check only) ----------------

    if "`robust_check'" != "" {
        local stored_sig "`e(data_signature)'"

        if "`stored_sig'" != "" {
            qui datasignature
            local current_sig "`r(datasignature)'"

            // datasignature format: N:k(bytes):hash1:hash2
            // compare hash fields only; the byte-count field may change
            // after -compress- or -recast- without altering values
            tokenize "`stored_sig'", parse(":")
            local stored_hash "`5':`7'"
            tokenize "`current_sig'", parse(":")
            local current_hash "`5':`7'"

            if "`stored_hash'" != "`current_hash'" {
                di as error "{hline}"
                di as error "data signature mismatch (robust_check)"
                di as error "  stored:  `stored_sig'"
                di as error "  current: `current_sig'"
                di as error ""
                di as error "omit {bf:robust_check} to skip hash verification"
                di as error "{hline}"
                exit 459
            }
        }
    }
end
