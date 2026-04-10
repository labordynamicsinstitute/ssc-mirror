*! sim_longmeta v1.0.0  metaLong for Stata 14.1
*! Simulate a longitudinal meta-analytic dataset
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*! Stata translation of sim_longitudinal_meta() from R package metaLong

program define sim_longmeta
    version 14.1

    syntax , [                  ///
        K(integer 20)           ///  number of studies
        TIMES(numlist >=0 ascending) ///  follow-up time points
        MU(real 0.4)            ///  true mean effect (common across waves)
        TAU(real 0.2)           ///  between-study SD
        VLow(real 0.02)         ///  lower bound of sampling variance
        VHigh(real 0.12)        ///  upper bound of sampling variance
        MISSing(real 0)         ///  proportion of missing study x time cells
        noCOVariates            ///  suppress pub_year / quality / n covariates
        SEED(integer -1)        ///  random seed (-1 = no seed set)
        SAVing(string asis)     ///  save dataset to this file
        REPLACE                 ///  allow overwrite of saving() file
        CLEAR                   ///  clear data in memory first
    ]

    /* ------------------------------------------------------------------ */
    /*  0. Validate options                                                 */
    /* ------------------------------------------------------------------ */
    if `k' < 2 {
        di as error "K() must be >= 2"
        exit 198
    }
    if `vlow' <= 0 | `vhigh' <= `vlow' {
        di as error "Require 0 < vlow() < vhigh()"
        exit 198
    }
    if `missing' < 0 | `missing' >= 1 {
        di as error "missing() must be in [0, 1)"
        exit 198
    }

    /* Default time vector */
    if "`times'" == "" local times 0 6 12 24

    /* Parse times into indexed locals */
    local n_times 0
    foreach t of numlist `times' {
        local n_times = `n_times' + 1
        local time`n_times' `t'
    }
    if `n_times' < 2 {
        di as error "At least 2 time points required"
        exit 198
    }

    /* ------------------------------------------------------------------ */
    /*  1. Set seed and preserve original data                             */
    /* ------------------------------------------------------------------ */
    if `seed' >= 0 set seed `seed'

    if "`clear'" != "" {
        quietly clear
    }
    else {
        preserve
    }

    /* ------------------------------------------------------------------ */
    /*  2. Build grid: k studies x n_times time points                     */
    /* ------------------------------------------------------------------ */
    local n_obs = `k' * `n_times'

    quietly {
        clear
        set obs `n_obs'

        /* Study index and study ID string */
        gen int   _study_num = ceil(_n / `n_times')
        gen str10 study      = "s" + string(_study_num, "%02.0f")

        /* Time index within study */
        gen int _time_idx = mod(_n - 1, `n_times') + 1

        /* Assign time values */
        gen double time = .
        forvalues j = 1/`n_times' {
            replace time = `time`j'' if _time_idx == `j'
        }
        drop _time_idx

        /* Study-level random effect u_i ~ N(0, tau^2) */
        /* Generate one u_i per study and broadcast */
        gen double _u_i = .
        forvalues i = 1/`k' {
            local ui_val = rnormal(0, `tau')
            replace _u_i = `ui_val' if _study_num == `i'
        }

        /* Sampling variances: uniform(vlow, vhigh) */
        gen double vi = runiform() * (`vhigh' - `vlow') + `vlow'

        /* Observed effect size: mu + u_i + eps_it, eps ~ N(0, vi) */
        gen double yi = `mu' + _u_i + rnormal(0, sqrt(vi))

        /* Study-level covariates */
        if "`covariates'" == "" {
            /* pub_year: uniform integer in [2000, 2022] */
            gen int pub_year = .
            /* quality: std normal */
            gen double quality = .
            /* n: uniform integer in [30, 500] */
            gen int n = .

            forvalues i = 1/`k' {
                local py_val  = int(runiform() * 23) + 2000
                local qu_val  = round(rnormal(), 0.01)
                local n_val   = int(runiform() * 471) + 30
                replace pub_year = `py_val'  if _study_num == `i'
                replace quality  = `qu_val'  if _study_num == `i'
                replace n        = `n_val'   if _study_num == `i'
            }
        }

        drop _study_num _u_i

        /* Introduce missing observations */
        if `missing' > 0 {
            gen byte _drop = (runiform() < `missing')
            drop if _drop
            drop _drop
        }

        sort study time

        /* Label variables */
        label var study  "Study identifier"
        label var time   "Follow-up time"
        label var yi     "Observed effect size"
        label var vi     "Sampling variance"
        if "`covariates'" == "" {
            label var pub_year "Publication year"
            label var quality  "Study quality (std normal)"
            label var n        "Sample size"
        }
    }

    /* ------------------------------------------------------------------ */
    /*  3. Summary message                                                  */
    /* ------------------------------------------------------------------ */
    quietly count
    local n_final = r(N)
    di as txt _newline "  {hline 55}"
    di as txt "  sim_longmeta: Longitudinal Meta-Analytic Dataset"
    di as txt "  {hline 55}"
    di as txt "  Studies (k)    : `k'"
    di as txt "  Time points    : `n_times' ( `times' )"
    di as txt "  True effect mu : `mu'"
    di as txt "  Between-study SD (tau): `tau'"
    di as txt "  Observations   : `n_final'"
    if `missing' > 0 di as txt "  Missing prop   : `missing'"
    di as txt "  {hline 55}"

    /* ------------------------------------------------------------------ */
    /*  4. Save if requested                                                */
    /* ------------------------------------------------------------------ */
    if `"`saving'"' != "" {
        if "`replace'" != "" quietly save `saving', replace
        else                  quietly save `saving'
        di as txt "  Dataset saved to: " as res `"`saving'"'
    }

    if "`clear'" != "" {
        /* data already permanent */
    }
    else {
        restore, not
    }
end
