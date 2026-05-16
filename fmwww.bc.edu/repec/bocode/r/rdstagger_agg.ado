*! rdstagger_agg v1.0.0 Subir Hait 2026
*! Aggregate ATT(g,t) from rdstagger into event-study or overall ATT
*! Stata 14 compatible

program define rdstagger_agg, eclass
    version 14
    syntax [,                     ///
        type(string)              ///  dynamic/group/calendar/overall
        ]

    * Check rdstagger has been run
    if "`e(cmd)'" != "rdstagger" {
        di as error "Must run rdstagger before rdstagger_agg"
        exit 198
    }
    if "`type'" == "" local type "dynamic"
    if !inlist("`type'", "dynamic", "group", "calendar", "overall") {
        di as error "type() must be dynamic, group, calendar, or overall"
        exit 198
    }

    * Preserve key scalars/locals before any ereturn writes
    local prev_N         = e(N)
    local prev_bandwidth = e(bandwidth)
    local prev_n_cohorts = e(n_cohorts)
    local prev_n_periods = e(n_periods)
    local prev_control   "`e(control)'"
    local prev_kernel    "`e(kernel)'"
    local prev_yvar      "`e(yvar)'"
    local prev_xvar      "`e(xvar)'"
    local prev_gvar      "`e(gvar)'"
    local prev_tvar      "`e(tvar)'"
    tempname prev_ATTGT
    matrix `prev_ATTGT' = e(attgt)

    * Pull attgt matrix from ereturn
    tempname ATTGT
    matrix `ATTGT' = `prev_ATTGT'
    local nrows = rowsof(`ATTGT')

    * cols: 1=cohort 2=period 3=att 4=se 5=ci_lo 6=ci_hi
    *       7=pval 8=n_treat 9=n_ctrl 10=prepost(1=post,0=pre)

    if "`type'" == "dynamic" {
        * Event time = period - cohort
        * Find unique event times
        local etimes ""
        forvalues r = 1/`nrows' {
            if el(`ATTGT',`r',3) < . {
                local et = el(`ATTGT',`r',2) - el(`ATTGT',`r',1)
                local etimes "`etimes' `et'"
            }
        }
        local etimes : list uniq etimes
        local etimes : list sort etimes

        local nout : word count `etimes'
        tempname AGG
        matrix `AGG' = J(`nout', 7, .)
        * cols: event_time att se ci_lo ci_hi pval prepost

        local row = 0
        foreach et of local etimes {
            local ++row
            local att_sum = 0
            local var_sum = 0
            local ncells  = 0

            forvalues r = 1/`nrows' {
                if el(`ATTGT',`r',3) < . {
                    local et_r = el(`ATTGT',`r',2) - el(`ATTGT',`r',1)
                    if `et_r' == `et' {
                        local att_sum = `att_sum' + el(`ATTGT',`r',3)
                        local var_sum = `var_sum' + el(`ATTGT',`r',4)^2
                        local ++ncells
                    }
                }
            }

            if `ncells' > 0 {
                local att  = `att_sum' / `ncells'
                local se   = sqrt(`var_sum') / `ncells'
                local cv   = invnormal(0.975)
                local pval = 2 * normal(-abs(`att'/max(`se',1e-10)))
                local pp   = cond(`et' < 0, 0, 1)

                matrix `AGG'[`row',1] = `et'
                matrix `AGG'[`row',2] = `att'
                matrix `AGG'[`row',3] = `se'
                matrix `AGG'[`row',4] = `att' - `cv'*`se'
                matrix `AGG'[`row',5] = `att' + `cv'*`se'
                matrix `AGG'[`row',6] = `pval'
                matrix `AGG'[`row',7] = `pp'
            }
        }

        * Display
        di _newline as txt "Event-Study Aggregation (type: dynamic)"
        di as txt "{hline 65}"
        di as txt %10s "Event Time" %10s "ATT" %10s "SE" ///
                  %10s "CI Lo" %10s "CI Hi" %8s "p-val"
        di as txt "{hline 65}"
        forvalues r = 1/`nout' {
            if el(`AGG',`r',2) < . {
                local pp = cond(el(`AGG',`r',7)==1,"post","pre ")
                di as res %10.0f el(`AGG',`r',1) ///
                          %10.4f el(`AGG',`r',2) ///
                          %10.4f el(`AGG',`r',3) ///
                          %10.4f el(`AGG',`r',4) ///
                          %10.4f el(`AGG',`r',5) ///
                          %8.4f  el(`AGG',`r',6) ///
                          "  [`pp']"
            }
        }
        di as txt "{hline 65}"

        ereturn matrix agg     = `AGG'
        ereturn matrix attgt   = `prev_ATTGT'
        ereturn scalar N           = `prev_N'
        ereturn scalar bandwidth   = `prev_bandwidth'
        ereturn scalar n_cohorts   = `prev_n_cohorts'
        ereturn scalar n_periods   = `prev_n_periods'
        ereturn local  agg_type    "dynamic"
        ereturn local  control     "`prev_control'"
        ereturn local  kernel      "`prev_kernel'"
        ereturn local  yvar        "`prev_yvar'"
        ereturn local  xvar        "`prev_xvar'"
        ereturn local  gvar        "`prev_gvar'"
        ereturn local  tvar        "`prev_tvar'"
        ereturn local  cmd         "rdstagger"
    }

    else if "`type'" == "group" {
        * Aggregate by cohort (post-treatment only)
        local gcohorts ""
        forvalues r = 1/`nrows' {
            if el(`ATTGT',`r',3) < . & el(`ATTGT',`r',10) == 1 {
                local gc = el(`ATTGT',`r',1)
                local gcohorts "`gcohorts' `gc'"
            }
        }
        local gcohorts : list uniq gcohorts
        local gcohorts : list sort gcohorts
        local nout : word count `gcohorts'

        tempname AGG
        matrix `AGG' = J(`nout', 6, .)

        local row = 0
        foreach gc of local gcohorts {
            local ++row
            local att_sum = 0
            local var_sum = 0
            local ncells  = 0

            forvalues r = 1/`nrows' {
                if el(`ATTGT',`r',1) == `gc' & el(`ATTGT',`r',3) < . & ///
                   el(`ATTGT',`r',10) == 1 {
                    local att_sum = `att_sum' + el(`ATTGT',`r',3)
                    local var_sum = `var_sum' + el(`ATTGT',`r',4)^2
                    local ++ncells
                }
            }

            if `ncells' > 0 {
                local att  = `att_sum' / `ncells'
                local se   = sqrt(`var_sum') / `ncells'
                local cv   = invnormal(0.975)
                local pval = 2 * normal(-abs(`att'/max(`se',1e-10)))
                matrix `AGG'[`row',1] = `gc'
                matrix `AGG'[`row',2] = `att'
                matrix `AGG'[`row',3] = `se'
                matrix `AGG'[`row',4] = `att' - `cv'*`se'
                matrix `AGG'[`row',5] = `att' + `cv'*`se'
                matrix `AGG'[`row',6] = `pval'
            }
        }

        di _newline as txt "Group (Cohort) Aggregation"
        di as txt "{hline 60}"
        di as txt %10s "Cohort" %10s "ATT" %10s "SE" ///
                  %10s "CI Lo" %10s "CI Hi" %8s "p-val"
        di as txt "{hline 60}"
        forvalues r = 1/`nout' {
            if el(`AGG',`r',2) < . {
                di as res %10.0f el(`AGG',`r',1) ///
                          %10.4f el(`AGG',`r',2) ///
                          %10.4f el(`AGG',`r',3) ///
                          %10.4f el(`AGG',`r',4) ///
                          %10.4f el(`AGG',`r',5) ///
                          %8.4f  el(`AGG',`r',6)
            }
        }
        di as txt "{hline 60}"

        ereturn matrix agg     = `AGG'
        ereturn matrix attgt   = `prev_ATTGT'
        ereturn scalar N           = `prev_N'
        ereturn scalar bandwidth   = `prev_bandwidth'
        ereturn scalar n_cohorts   = `prev_n_cohorts'
        ereturn scalar n_periods   = `prev_n_periods'
        ereturn local  agg_type    "group"
        ereturn local  control     "`prev_control'"
        ereturn local  kernel      "`prev_kernel'"
        ereturn local  yvar        "`prev_yvar'"
        ereturn local  xvar        "`prev_xvar'"
        ereturn local  gvar        "`prev_gvar'"
        ereturn local  tvar        "`prev_tvar'"
        ereturn local  cmd         "rdstagger"
    }

    else if "`type'" == "calendar" {
        * Aggregate by calendar period (post-treatment only)
        local tperiods ""
        forvalues r = 1/`nrows' {
            if el(`ATTGT',`r',3) < . & el(`ATTGT',`r',10) == 1 {
                local tp = el(`ATTGT',`r',2)
                local tperiods "`tperiods' `tp'"
            }
        }
        local tperiods : list uniq tperiods
        local tperiods : list sort tperiods
        local nout : word count `tperiods'

        tempname AGG
        matrix `AGG' = J(`nout', 6, .)

        local row = 0
        foreach tp of local tperiods {
            local ++row
            local att_sum = 0
            local var_sum = 0
            local ncells  = 0

            forvalues r = 1/`nrows' {
                if el(`ATTGT',`r',2) == `tp' & el(`ATTGT',`r',3) < . & ///
                   el(`ATTGT',`r',10) == 1 {
                    local att_sum = `att_sum' + el(`ATTGT',`r',3)
                    local var_sum = `var_sum' + el(`ATTGT',`r',4)^2
                    local ++ncells
                }
            }

            if `ncells' > 0 {
                local att  = `att_sum' / `ncells'
                local se   = sqrt(`var_sum') / `ncells'
                local cv   = invnormal(0.975)
                local pval = 2 * normal(-abs(`att'/max(`se',1e-10)))
                matrix `AGG'[`row',1] = `tp'
                matrix `AGG'[`row',2] = `att'
                matrix `AGG'[`row',3] = `se'
                matrix `AGG'[`row',4] = `att' - `cv'*`se'
                matrix `AGG'[`row',5] = `att' + `cv'*`se'
                matrix `AGG'[`row',6] = `pval'
            }
        }

        di _newline as txt "Calendar-Time Aggregation"
        di as txt "{hline 60}"
        di as txt %10s "Period" %10s "ATT" %10s "SE" ///
                  %10s "CI Lo" %10s "CI Hi" %8s "p-val"
        di as txt "{hline 60}"
        forvalues r = 1/`nout' {
            if el(`AGG',`r',2) < . {
                di as res %10.0f el(`AGG',`r',1) ///
                          %10.4f el(`AGG',`r',2) ///
                          %10.4f el(`AGG',`r',3) ///
                          %10.4f el(`AGG',`r',4) ///
                          %10.4f el(`AGG',`r',5) ///
                          %8.4f  el(`AGG',`r',6)
            }
        }
        di as txt "{hline 60}"

        ereturn matrix agg     = `AGG'
        ereturn matrix attgt   = `prev_ATTGT'
        ereturn scalar N           = `prev_N'
        ereturn scalar bandwidth   = `prev_bandwidth'
        ereturn scalar n_cohorts   = `prev_n_cohorts'
        ereturn scalar n_periods   = `prev_n_periods'
        ereturn local  agg_type    "calendar"
        ereturn local  control     "`prev_control'"
        ereturn local  kernel      "`prev_kernel'"
        ereturn local  yvar        "`prev_yvar'"
        ereturn local  xvar        "`prev_xvar'"
        ereturn local  gvar        "`prev_gvar'"
        ereturn local  tvar        "`prev_tvar'"
        ereturn local  cmd         "rdstagger"
    }

    else if "`type'" == "overall" {
        * Simple average of all post-treatment ATT(g,t)
        local att_sum = 0
        local var_sum = 0
        local ncells  = 0

        forvalues r = 1/`nrows' {
            if el(`ATTGT',`r',3) < . & el(`ATTGT',`r',10) == 1 {
                local att_sum = `att_sum' + el(`ATTGT',`r',3)
                local var_sum = `var_sum' + el(`ATTGT',`r',4)^2
                local ++ncells
            }
        }

        if `ncells' > 0 {
            local att  = `att_sum' / `ncells'
            local se   = sqrt(`var_sum') / `ncells'
            local cv   = invnormal(0.975)
            local pval = 2 * normal(-abs(`att'/max(`se',1e-10)))
            local ci_lo = `att' - `cv'*`se'
            local ci_hi = `att' + `cv'*`se'
        }

        di _newline as txt "Overall ATT (average of post-treatment cells)"
        di as txt "{hline 50}"
        di as txt %10s "ATT" %10s "SE" ///
                  %10s "CI Lo" %10s "CI Hi" %8s "p-val"
        di as txt "{hline 50}"
        di as res %10.4f `att' %10.4f `se' ///
                  %10.4f `ci_lo' %10.4f `ci_hi' %8.4f `pval'
        di as txt "{hline 50}"
        di as txt "Based on `ncells' post-treatment ATT(g,t) cells"

        ereturn scalar overall_att = `att'
        ereturn scalar overall_se  = `se'
        ereturn matrix attgt       = `prev_ATTGT'
        ereturn scalar N           = `prev_N'
        ereturn scalar bandwidth   = `prev_bandwidth'
        ereturn scalar n_cohorts   = `prev_n_cohorts'
        ereturn scalar n_periods   = `prev_n_periods'
        ereturn local  agg_type    "overall"
        ereturn local  control     "`prev_control'"
        ereturn local  kernel      "`prev_kernel'"
        ereturn local  yvar        "`prev_yvar'"
        ereturn local  xvar        "`prev_xvar'"
        ereturn local  gvar        "`prev_gvar'"
        ereturn local  tvar        "`prev_tvar'"
        ereturn local  cmd         "rdstagger"
    }

end
