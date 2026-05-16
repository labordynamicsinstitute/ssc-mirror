*! rdstagger_sim v1.0.0 Subir Hait 2026
*! Simulate staggered RD panel data with network interference
*! Stata 14 compatible

program define rdstagger_sim
    version 14
    syntax ,                        ///
        n(integer)                  ///  number of units
        periods(integer)            ///  number of time periods
        cohorts(integer)            ///  number of treatment cohorts
        [                           ///
        cutoff(real 0)              ///  RD cutoff
        bw(real 1)                  ///  bandwidth
        density(real 0.1)           ///  network density
        direct(real 0.3)            ///  true direct ATT
        spill(real 0.1)             ///  true spillover effect
        outcome(string)             ///  continuous/binary/count
        seed(integer 42)            ///  random seed
        ]

    * --- Input validation ---
    if `n' < 10 {
        di as error "n() must be at least 10"
        exit 198
    }
    if `periods' < 3 {
        di as error "periods() must be at least 3"
        exit 198
    }
    if `cohorts' < 1 {
        di as error "cohorts() must be at least 1"
        exit 198
    }
    if `density' <= 0 | `density' >= 1 {
        di as error "density() must be strictly between 0 and 1"
        exit 198
    }
    if "`outcome'" == "" local outcome "continuous"
    if !inlist("`outcome'", "continuous", "binary", "count") {
        di as error "outcome() must be continuous, binary, or count"
        exit 198
    }

    set seed `seed'

    * --- 1. Unit-level dataset ---
    qui {
        clear
        set obs `n'
        gen long id = _n

        * Running variable
        gen double x = rnormal(0, 1.5)

        * Cohort assignment: below cutoff = eligible
        local first_period = max(2, floor(`periods' / 3))
        gen double g = .
        gen double alpha_i = rnormal(0, 0.5)

        forvalues k = 1/`cohorts' {
            local lo  = `cutoff' - `bw' * (`k'  / `cohorts')
            local hi  = `cutoff' - `bw' * ((`k'-1) / `cohorts')
            local gval = `first_period' + floor((`k'-1) * ///
                         (`periods' - 1 - `first_period') / `cohorts')
            replace g = `gval' if x < `cutoff' & x >= `lo' & ///
                                   x < `hi'    & g == .
        }
        * g = . means never treated

        * Time fixed effects (one per period)
        tempfile units
        save `units'
    }

    * --- 2. Expand to panel ---
    qui {
        expand `periods'
        bysort id: gen int period = _n

        * Merge unit-level vars
        * (already in memory after expand)

        * Treatment indicator
        gen byte treated = (g != . & g <= period)

        * Time FE
        gen double lambda_t = rnormal(0, 0.3)
        * Make lambda_t period-specific
        tempvar tfe
        bysort period: gen `tfe' = runiform()
        bysort period (`tfe'): replace lambda_t = lambda_t[1]
        drop `tfe'

        * Network exposure (simplified: random neighbor exposure)
        * Full adjacency matrix not feasible in Stata for large n
        * Instead: each unit has Poisson(density*n) neighbors
        * and neighbor_treated = share of neighbors treated
        gen double spill_share   = 0
        gen byte   neighbor_treated = 0

        * Approximate network: each unit i is exposed to
        * a random draw of other units as neighbors
        local avg_deg = round(`density' * `n')
        if `avg_deg' < 1 local avg_deg = 1

        * For each unit-period, compute spillover share
        * (approximation suitable for Stata)
        tempvar deg_draw
        gen `deg_draw' = rpoisson(`avg_deg')

        * treated units by period
        bysort period (id): gen double n_treated_t = sum(treated)
        bysort period: replace n_treated_t = n_treated_t[_N]

        replace spill_share = min((`deg_draw' / `n') * ///
                              (n_treated_t / max(`n',1)), 1)
        replace neighbor_treated = (spill_share > 0)
        drop `deg_draw' n_treated_t

        * Error term
        gen double eps = rnormal(0, 0.5)

        * Latent outcome
        gen double y_latent = alpha_i + lambda_t + 0.2*x + eps + ///
                              `direct' * treated  + ///
                              `spill'  * spill_share

        * Outcome transformation
        if "`outcome'" == "binary" {
            gen byte y = (invlogit(y_latent) > runiform())
        }
        else if "`outcome'" == "count" {
            gen double y_mu = exp(max(min(y_latent, 5), -5))
            gen long   y    = rpoisson(y_mu)
            drop y_mu
        }
        else {
            gen double y = y_latent
        }

        * Clean up
        drop alpha_i lambda_t eps y_latent
        order id period y x g treated neighbor_treated spill_share
        label var id               "Unit identifier"
        label var period           "Time period"
        label var y                "Outcome variable"
        label var x                "Running variable"
        label var g                "Cohort (first treated period; . = never)"
        label var treated          "Treatment indicator"
        label var neighbor_treated "Any neighbor treated"
        label var spill_share      "Share of neighbors treated"
    }

    di as txt _newline "rdstagger_sim: Simulated panel data"
    di as txt "  Units:        `n'"
    di as txt "  Periods:      `periods'"
    di as txt "  Cohorts:      `cohorts'"
    di as txt "  Outcome:      `outcome'"
    di as txt "  True direct:  `direct'"
    di as txt "  True spill:   `spill'"
    di as txt "  Seed:         `seed'"
    di as txt "  Obs:          " _N
    qui count if g == .
    di as txt "  Never-treated units: " r(N)

end
