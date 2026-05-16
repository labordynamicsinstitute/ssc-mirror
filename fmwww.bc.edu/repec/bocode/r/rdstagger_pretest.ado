*! rdstagger_pretest v1.0.0 Subir Hait 2026
*! Pre-treatment parallel trends falsification tests for rdstagger
*! Stata 14 compatible

program define rdstagger_pretest, eclass
    version 14
    syntax [,                   ///
        method(string)          ///  joint/individual/both
        ]

    if "`e(cmd)'" != "rdstagger" {
        di as error "Must run rdstagger before rdstagger_pretest"
        exit 198
    }
    if "`method'" == "" local method "both"
    if !inlist("`method'", "joint", "individual", "both") {
        di as error "method() must be joint, individual, or both"
        exit 198
    }

    tempname ATTGT
    matrix `ATTGT' = e(attgt)
    local nrows = rowsof(`ATTGT')

    * Collect pre-treatment cells (prepost == 0)
    local pre_atts   ""
    local pre_ses    ""
    local pre_cohort ""
    local pre_period ""
    local npre = 0

    forvalues r = 1/`nrows' {
        if `ATTGT'[`r',3] < . & `ATTGT'[`r',10] == 0 {
            local ++npre
            local pre_atts   "`pre_atts'   `=`ATTGT'[`r',3]'"
            local pre_ses    "`pre_ses'    `=`ATTGT'[`r',4]'"
            local pre_cohort "`pre_cohort' `=`ATTGT'[`r',1]'"
            local pre_period "`pre_period' `=`ATTGT'[`r',2]'"
        }
    }

    if `npre' == 0 {
        di as txt "No pre-treatment ATT(g,t) cells found."
        di as txt "Ensure your data has periods before treatment adoption."
        exit
    }

    di _newline as txt "rdstagger Pre-Treatment Falsification Test"
    di as txt    "{hline 60}"
    di as txt    "Pre-treatment ATT(g,t) cells: `npre'"
    di as txt    "{hline 60}"

    * --- Joint Wald test ---
    if inlist("`method'", "joint", "both") {
        local chi2 = 0
        local k    = 0

        forvalues i = 1/`npre' {
            local att_i : word `i' of `pre_atts'
            local se_i  : word `i' of `pre_ses'
            if `se_i' > 0 {
                local chi2 = `chi2' + (`att_i'/`se_i')^2
                local ++k
            }
        }

        local pval_joint = chi2tail(`k', `chi2')

        di _newline as txt "Joint Wald Test (H0: all pre-treatment ATT = 0)"
        di as txt "  Chi-squared(`k') = " %8.4f `chi2'
        di as txt "  p-value          = " %8.4f `pval_joint'

        if `pval_joint' > 0.05 {
            di as txt "  Result: " as res "PASS" as txt ///
               " -- no evidence of pre-treatment trends (p > 0.05)"
        }
        else {
            di as txt "  Result: " as error "FAIL" as txt ///
               " -- evidence of pre-treatment trends (p <= 0.05)"
        }

        ereturn scalar pretest_chi2 = `chi2'
        ereturn scalar pretest_df   = `k'
        ereturn scalar pretest_pval = `pval_joint'
    }

    * --- Individual cell tests ---
    if inlist("`method'", "individual", "both") {
        di _newline as txt "Individual Cell Tests:"
        di as txt "{hline 65}"
        di as txt %8s "Cohort" %8s "Period" %11s "ATT" ///
                  %11s "SE" %10s "t-stat" %10s "p-val" %8s "Sig?"
        di as txt "{hline 65}"

        local nsig = 0
        forvalues i = 1/`npre' {
            local att_i    : word `i' of `pre_atts'
            local se_i     : word `i' of `pre_ses'
            local cohort_i : word `i' of `pre_cohort'
            local period_i : word `i' of `pre_period'

            local tstat = `att_i' / max(`se_i', 1e-10)
            local pval  = 2 * normal(-abs(`tstat'))
            local sig   = cond(abs(`tstat') > invnormal(0.975), "*", " ")
            if "`sig'" == "*" local ++nsig

            di as res %8.0f `cohort_i' ///
                      %8.0f `period_i' ///
                      %11.4f `att_i'   ///
                      %11.4f `se_i'    ///
                      %10.4f `tstat'   ///
                      %10.4f `pval'    ///
                      %8s    "`sig'"
        }
        di as txt "{hline 65}"
        di as txt "* significant at 5% level"
        di as txt "`nsig' of `npre' pre-treatment cells significant at 5%"
    }

end
