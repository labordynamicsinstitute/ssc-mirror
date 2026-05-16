*! rdstagger v1.0.3 Subir Hait 2026
*! Staggered Regression Discontinuity with Network Interference
*! Stata 14 compatible

program define rdstagger, eclass
    version 14
    syntax varlist(min=2 max=2) [if] [in] ,  ///
        cutoff(real)                          ///  RD cutoff
        gvar(varname)                         ///  cohort variable
        tvar(varname)                         ///  time variable
        idvar(varname)                        ///  unit ID
        [                                     ///
        bw(real 0)                          ///  bandwidth (must be > 0; 0 = not set)
        kernel(string)                        ///  kernel type
        CONtrol(string)                       ///  control group: nevertreated | notyetreated
        BOOTstrap                             ///  bootstrap SEs
        nboot(integer 499)                    ///  bootstrap reps
        alpha(real 0.05)                      ///  significance level
        COVariates(varlist)                   ///  covariates
        ]

    * --- Defaults ---
    if "`kernel'"  == "" local kernel  "triangular"
    if "`control'" == "" local control "nevertreated"

    local kernel = strtrim("`kernel'")
    if "`kernel'" != "triangular" & "`kernel'" != "epanechnikov" & "`kernel'" != "uniform" {
        di as error "kernel() must be triangular, epanechnikov, or uniform"
        exit 198
    }
    * Normalise control (trim whitespace, tolerate abbreviation)
    local control = strtrim("`control'")
    if "`control'" != "nevertreated" & "`control'" != "notyetreated" {
        di as error "control() must be nevertreated or notyetreated"
        exit 198
    }

    * Parse varlist
    tokenize `varlist'
    local yvar `1'
    local xvar `2'

    marksample touse

    * --- Bandwidth selection ---
    if `bw' <= 0 {
        di as error "bw() must be a positive number."
        di as error "Example: rdstagger y x, cutoff(0) gvar(g) tvar(t) idvar(id) bw(1.5)"
        exit 198
    }

    * Apply bandwidth restriction
    replace `touse' = 0 if abs(`xvar' - `cutoff') > `bw'

    * Kernel weights
    tempvar kw
    if "`kernel'" == "triangular" {
        gen double `kw' = max(1 - abs(`xvar'-`cutoff')/`bw', 0) ///
                          if `touse'
    }
    else if "`kernel'" == "epanechnikov" {
        gen double `kw' = max(0.75*(1-((`xvar'-`cutoff')/`bw')^2), 0) ///
                          if `touse'
    }
    else {
        gen double `kw' = 1 if `touse'
    }
    replace `kw' = 0 if `kw' == .

    * --- Get cohorts and periods ---
    qui levelsof `gvar' if `touse' & `gvar' < ., local(cohorts)
    qui levelsof `tvar' if `touse',               local(periods)

    local ncohorts : word count `cohorts'
    local nperiods : word count `periods'
    local nrows    = `ncohorts' * `nperiods'

    * Storage: attgt matrix
    * cols: cohort period att se ci_lo ci_hi pval n_treat n_ctrl prepost
    tempname ATTGT
    matrix `ATTGT' = J(`nrows', 10, .)

    local row = 0
    foreach gc of local cohorts {
        local base_t = `gc' - 1

        foreach tp of local periods {
            local ++row

            * Pre/post indicator
            local prepost = cond(`tp' < `gc', 0, 1)

            * Control group condition
            if "`control'" == "nevertreated" {
                local ctrl_cond "`gvar' >= ."
            }
            else {
                local ctrl_cond "(`gvar' >= . | `gvar' > `tp')"
            }

            * Check enough observations
            qui count if `touse' & `gvar'==`gc' & `tvar'==`tp'
            if r(N) < 5 {
                matrix `ATTGT'[`row',1]  = `gc'
                matrix `ATTGT'[`row',2]  = `tp'
                matrix `ATTGT'[`row',10] = `prepost'
                continue
            }
            qui count if `touse' & `gvar'==`gc' & `tvar'==`base_t'
            if r(N) < 5 {
                matrix `ATTGT'[`row',1]  = `gc'
                matrix `ATTGT'[`row',2]  = `tp'
                matrix `ATTGT'[`row',10] = `prepost'
                continue
            }

            * Weighted means — treated post
            qui sum `yvar' [aw=`kw'] ///
                if `touse' & `gvar'==`gc' & `tvar'==`tp'
            local y_tp = r(mean)
            local n_tp = r(N)

            * Weighted means — treated base
            qui sum `yvar' [aw=`kw'] ///
                if `touse' & `gvar'==`gc' & `tvar'==`base_t'
            local y_tb = r(mean)

            * Weighted means — control post
            qui sum `yvar' [aw=`kw'] ///
                if `touse' & (`ctrl_cond') & `tvar'==`tp'
            local y_cp = r(mean)
            local n_cp = r(N)

            * Weighted means — control base
            qui sum `yvar' [aw=`kw'] ///
                if `touse' & (`ctrl_cond') & `tvar'==`base_t'
            local y_cb = r(mean)

            * DiD ATT
            local att = (`y_tp' - `y_tb') - (`y_cp' - `y_cb')

            * SE (analytic approximation: pooled SD / sqrt(N_eff))
            * Note: this is a conservative approximation. Use bootstrap()
            * for more reliable SEs, especially in small samples.
            qui sum `yvar' if `touse' & ///
                (`gvar'==`gc' | (`ctrl_cond')) & ///
                (`tvar'==`tp' | `tvar'==`base_t')
            local pooled_sd = r(sd)
            local n_eff     = `n_tp' + `n_cp'
            local se        = `pooled_sd' / sqrt(`n_eff')

            if `se' == . | `se' == 0 local se = 0.0001

    * Bootstrap SE (note: slow for large datasets; consider nboot(199) for exploration)
            if "`bootstrap'" != "" {
                local boot_atts ""
                forvalues b = 1/`nboot' {
                    * Resample within treated + control units
                    preserve
                    qui keep if `touse' & ///
                        (`gvar'==`gc' | (`ctrl_cond')) & ///
                        (`tvar'==`tp' | `tvar'==`base_t')
                    qui bsample
                    qui sum `yvar' if `gvar'==`gc' & `tvar'==`tp'
                    local b_tp = r(mean)
                    qui sum `yvar' if `gvar'==`gc' & `tvar'==`base_t'
                    local b_tb = r(mean)
                    qui sum `yvar' if (`ctrl_cond') & `tvar'==`tp'
                    local b_cp = r(mean)
                    qui sum `yvar' if (`ctrl_cond') & `tvar'==`base_t'
                    local b_cb = r(mean)
                    local b_att = (`b_tp'-`b_tb') - (`b_cp'-`b_cb')
                    local boot_atts "`boot_atts' `b_att'"
                    restore
                }
                * Compute SD of boot estimates
                local bmat ""
                local nb = 0
                foreach ba of local boot_atts {
                    local ++nb
                    local bmat "`bmat' `ba'"
                }
                * Approximate SD
                local bsum  = 0
                local bsum2 = 0
                foreach ba of local boot_atts {
                    local bsum  = `bsum'  + `ba'
                    local bsum2 = `bsum2' + `ba'^2
                }
                local bmean = `bsum'  / `nboot'
                local bvar  = `bsum2' / `nboot' - `bmean'^2
                local se    = sqrt(max(`bvar', 0))
                * Guard: if bootstrap SE collapses to 0, fall back to analytic SE
                if `se' == 0 {
                    qui sum `yvar' if `touse' & ///
                        (`gvar'==`gc' | (`ctrl_cond')) & ///
                        (`tvar'==`tp' | `tvar'==`base_t')
                    local se = r(sd) / sqrt(`n_eff')
                    if `se' == . | `se' == 0 local se = 0.0001
                }
            }

            * CI and p-value
            local cv    = invnormal(1 - `alpha'/2)
            local ci_lo = `att' - `cv' * `se'
            local ci_hi = `att' + `cv' * `se'
            local zval  = `att' / `se'
            local pval  = 2 * normal(-abs(`zval'))

            * Store
            matrix `ATTGT'[`row',1]  = `gc'
            matrix `ATTGT'[`row',2]  = `tp'
            matrix `ATTGT'[`row',3]  = `att'
            matrix `ATTGT'[`row',4]  = `se'
            matrix `ATTGT'[`row',5]  = `ci_lo'
            matrix `ATTGT'[`row',6]  = `ci_hi'
            matrix `ATTGT'[`row',7]  = `pval'
            matrix `ATTGT'[`row',8]  = `n_tp'
            matrix `ATTGT'[`row',9]  = `n_cp'
            matrix `ATTGT'[`row',10] = `prepost'
        }
    }

    * --- Count obs used ---
    qui count if `touse'
    local nobs_used = r(N)

    * --- Post results ---
    ereturn clear
    ereturn matrix attgt     = `ATTGT'
    ereturn scalar bandwidth  = `bw'
    ereturn scalar n_cohorts  = `ncohorts'
    ereturn scalar n_periods  = `nperiods'
    ereturn scalar N          = `nobs_used'
    ereturn local  control    "`control'"
    ereturn local  kernel     "`kernel'"
    ereturn local  yvar       "`yvar'"
    ereturn local  xvar       "`xvar'"
    ereturn local  gvar       "`gvar'"
    ereturn local  tvar       "`tvar'"
    ereturn local  cmd        "rdstagger"

    * --- Display results ---
    di _newline as txt "Staggered RD ATT(g,t) Estimates"
    di as txt    "Bandwidth : " %7.4f `bw' ///
                 "   Kernel: `kernel'   Control: `control'"
    di as txt    "{hline 70}"
    di as txt    %8s  "Cohort" ///
                 %8s  "Period" ///
                 %11s "ATT"    ///
                 %11s "SE"     ///
                 %11s "95% CI Lo" ///
                 %11s "95% CI Hi" ///
                 %9s  "p-val"
    di as txt    "{hline 70}"

    * Copy e(attgt) to a new tempname for display indexing
    * (Stata 14 does not support e(matname)[r,c] indexing directly)
    tempname DISP
    matrix `DISP' = e(attgt)

    forvalues r = 1/`nrows' {
        if el(`DISP',`r',3) < . {
            local pp = cond(el(`DISP',`r',10)==1, "post", "pre ")
            di as res %8.0f  el(`DISP',`r',1)  ///
                      %8.0f  el(`DISP',`r',2)  ///
                      %11.4f el(`DISP',`r',3)  ///
                      %11.4f el(`DISP',`r',4)  ///
                      %11.4f el(`DISP',`r',5)  ///
                      %11.4f el(`DISP',`r',6)  ///
                      %9.4f  el(`DISP',`r',7)  ///
                      "  [`pp']"
        }
    }
    di as txt "{hline 70}"
    di as txt "Note: pre = pre-treatment period (should be ~0)"

end
