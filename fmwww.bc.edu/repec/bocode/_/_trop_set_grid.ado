*! _trop_set_grid: configure regularization parameter grids

/*
    _trop_set_grid

    Construct candidate grids for the regularization parameter triplet
    lambda = (lambda_time, lambda_unit, lambda_nn) used in leave-one-out
    cross-validation (LOOCV).

    The LOOCV criterion Q(lambda) is minimized over a Cartesian product
    of candidate values for each component:

      lambda_time   exponential decay rate for time weights
                    theta_s = exp(-lambda_time * dist_time(s,t))

      lambda_unit   exponential decay rate for unit weights
                    omega_j = exp(-lambda_unit * dist_unit(j,i))

      lambda_nn     nuclear-norm penalty on the low-rank component L

    Three preset grid resolutions are available:

      default    6 x  6 x  5 =   180 combinations
      fine       7 x  7 x  7 =   343 combinations
      extended  14 x 16 x 19 = 4,256 combinations

    The `default` λ_nn grid (0, 0.01, 0.1, 1, 10) is a five-point log-
    decade ladder covering the empirically relevant range for paper
    Eq. 2 without evaluating the DID/TWFE corner (λ_nn = +∞), keeping
    LOOCV cost predictable.

    `fine` adds half-decade λ_nn points (0.0316 and 0.316) in the critical
    0.01–1 band, filling the single-decade gap in the `default` λ_nn grid.
    On small panels (e.g. Basque, Germany) this substantially reduces the
    BLAS-dependent jitter in the selected λ_nn.

    `extended` additionally includes λ_nn = . (= +∞, the DID/TWFE
    corner per Eq. 2 remark).  Users who want LOOCV to consider the
    DID/TWFE special case should opt in via `grid_style(extended)` or
    pass a custom `lambda_nn_grid()`.

    User-supplied grids override the corresponding preset dimension.
    When any custom grid is active the style label is set to "custom".

    Returns via c_local:
      _lambda_time_grid   candidate values for lambda_time
      _lambda_unit_grid   candidate values for lambda_unit
      _lambda_nn_grid     candidate values for lambda_nn
      _grid_style         "default", "fine", "extended", or "custom"
      _n_time             number of lambda_time candidates
      _n_unit             number of lambda_unit candidates
      _n_nn               number of lambda_nn candidates
      _n_combinations     total grid size (product of the three)
      _n_per_cycle        evaluations per coordinate-descent cycle
*/


program define _trop_set_grid
    version 17.0
    syntax , [Grid_style(string) LAMbda_time_grid(string) ///
              LAMbda_unit_grid(string) LAMbda_nn_grid(string)]
    
    // --- detect user-supplied custom grids ---
    local has_custom_time = ("`lambda_time_grid'" != "")
    local has_custom_unit = ("`lambda_unit_grid'" != "")
    local has_custom_nn = ("`lambda_nn_grid'" != "")
    
    // --- resolve grid style ---
    if "`grid_style'" == "" {
        local grid_style "default"
    }
    
    if !inlist("`grid_style'", "default", "fine", "extended") {
        di as error "grid_style() must be 'default', 'fine', or 'extended'"
        di as error "  default:    180 combinations (6 x 6 x 5)"
        di as error "  fine:       343 combinations (7 x 7 x 7)"
        di as error "  extended: 4,256 combinations (14 x 16 x 19; includes DID/TWFE corner)"
        exit 198
    }
    
    // --- construct preset grids ---
    //
    // Grid values span from 0 (uniform weights / no penalty) to large
    // values (strong decay / heavy regularization).  lambda = 0 recovers
    // equal weighting; large lambda concentrates weight on nearby
    // units or periods and imposes stronger nuclear-norm shrinkage.
    
    // Per paper Eq 3 the weights θ, ω are exp(−λ · dist), defined for
    // λ ∈ [0, ∞); λ_time = λ_unit = 0 gives uniform weights.  λ_time =
    // λ_unit = ∞ is not a valid estimator configuration (it collapses
    // weight to the target period/unit only), so it is excluded from
    // every default and custom grid and rejected downstream.
    //
    // λ_nn = ∞ is the paper's DID/TWFE special case (Eq 2 remark: for
    // λ_nn = ∞, ω = θ = 1, we recover DID/TWFE).  It is included only in
    // the `extended` preset (via the Stata missing literal "."), so the
    // `default` preset keeps a five-point log-decade ladder for λ_nn
    // without the DID/TWFE corner; users who want LOOCV to evaluate it
    // should opt in explicitly via `extended` or a custom `lambda_nn_grid()`.
    if "`grid_style'" == "default" {
        // 6 x 6 x 5 = 180 combinations
        local default_time_grid "0 0.1 0.5 1 2 5"
        local default_unit_grid "0 0.1 0.5 1 2 5"
        local default_nn_grid "0 0.01 0.1 1 10"
    }
    else if "`grid_style'" == "fine" {
        // 7 x 7 x 7 = 343 combinations.  Adds 0.3 to λ_time/λ_unit and
        // 0.0316 / 0.316 to λ_nn (half-decade steps), filling gaps that
        // are critical on small panels where the LOOCV objective
        // Q(λ) surface exhibits non-convex plateaus.  DID/TWFE corner
        // (λ_nn = ∞) is still reserved for `extended`.
        local default_time_grid "0 0.1 0.3 0.5 1 2 5"
        local default_unit_grid "0 0.1 0.3 0.5 1 2 5"
        local default_nn_grid "0 0.01 0.0316 0.1 0.316 1 10"
    }
    else {
        // 14 x 16 x 19 = 4256 combinations; includes λ_nn = 10 and ∞.
        local default_time_grid "0 0.1 0.2 0.25 0.3 0.35 0.4 0.5 0.75 1 1.5 2 3 5"
        local default_unit_grid "0 0.1 0.2 0.25 0.3 0.35 0.4 0.5 0.75 1 1.2 1.5 1.6 2 3 5"
        local default_nn_grid "0 0.005 0.006 0.01 0.011 0.02 0.05 0.1 0.15 0.151 0.2 0.3 0.5 0.7 0.9 1 5 10 ."
    }
    
    // --- apply custom overrides ---
    // user-supplied grids take priority over preset values

    // Reject "." (Stata missing / inf) in lambda_time_grid and
    // lambda_unit_grid per paper Eq 3, which defines λ on [0, ∞) only.
    // λ_nn may legitimately be ∞ (DID/TWFE special case, Eq 2 remark).
    if `has_custom_time' {
        foreach _v of local lambda_time_grid {
            if "`_v'" == "." {
                di as error "lambda_time_grid() does not accept `.' (missing / inf)."
                di as error "  Paper Eq 3: θ_s = exp(−λ_time · |t − s|) is defined for"
                di as error "  λ_time ∈ [0, ∞); λ_time = 0 recovers uniform time weights."
                di as error "  λ_time = ∞ collapses all weight onto the target period,"
                di as error "  which is degenerate and not a supported configuration."
                exit 198
            }
        }
        local final_time_grid "`lambda_time_grid'"
    }
    else {
        local final_time_grid "`default_time_grid'"
    }

    if `has_custom_unit' {
        foreach _v of local lambda_unit_grid {
            if "`_v'" == "." {
                di as error "lambda_unit_grid() does not accept `.' (missing / inf)."
                di as error "  Paper Eq 3: ω_j = exp(−λ_unit · dist(j, i)) is defined for"
                di as error "  λ_unit ∈ [0, ∞); λ_unit = 0 recovers uniform unit weights."
                di as error "  λ_unit = ∞ collapses all weight onto the target unit,"
                di as error "  which is degenerate and not a supported configuration."
                exit 198
            }
        }
        local final_unit_grid "`lambda_unit_grid'"
    }
    else {
        local final_unit_grid "`default_unit_grid'"
    }

    if `has_custom_nn' {
        local final_nn_grid "`lambda_nn_grid'"
    }
    else {
        local final_nn_grid "`default_nn_grid'"
    }
    
    // --- count grid dimensions ---
    local n_time : word count `final_time_grid'
    local n_unit : word count `final_unit_grid'
    local n_nn : word count `final_nn_grid'
    local n_total = `n_time' * `n_unit' * `n_nn'

    // coordinate-descent cycling updates one parameter at a time while
    // holding the other two fixed, so each cycle requires
    // n_time + n_unit + n_nn LOOCV evaluations
    local n_per_cycle = `n_time' + `n_unit' + `n_nn'
    
    // --- relabel when any dimension is overridden ---
    local final_grid_style "`grid_style'"
    if `has_custom_time' | `has_custom_unit' | `has_custom_nn' {
        local final_grid_style "custom"
    }
    
    // --- return results to caller via c_local ---
    c_local _lambda_time_grid "`final_time_grid'"
    c_local _lambda_unit_grid "`final_unit_grid'"
    c_local _lambda_nn_grid "`final_nn_grid'"
    c_local _grid_style "`final_grid_style'"
    c_local _n_time `n_time'
    c_local _n_unit `n_unit'
    c_local _n_nn `n_nn'
    c_local _n_combinations `n_total'
    c_local _n_per_cycle `n_per_cycle'
end
