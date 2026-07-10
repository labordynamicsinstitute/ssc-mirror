/*==============================================================================
  Regularization parameter grid construction and manipulation.

  The TROP estimator depends on a tuning parameter triplet
  (lambda_time, lambda_unit, lambda_nn) selected via leave-one-out
  cross-validation (LOOCV) over a discrete grid.  lambda_time and
  lambda_unit govern exponential decay weights for time and unit
  distances, respectively; lambda_nn controls the strength of the
  nuclear-norm penalty on the low-rank component L.

  This module provides predefined grids, grid validation, format
  conversion between column vectors and numlist strings, infinity
  handling, and Stata matrix storage/retrieval.
==============================================================================*/

version 17

mata:
mata set matastrict on

/*------------------------------------------------------------------------------
  trop_get_lambda_grid()

  Returns a predefined grid of candidate values for one regularization
  parameter.

  Arguments:
    grid_style  - "default" (baseline) or "extended" (finer resolution)
    param_name  - "time", "unit", or "nn"

  Returns:
    column vector of non-negative grid values

  The baseline grid yields 6 x 6 x 5 = 180 triplet combinations, using
  a five-point log-decade ladder for λ_nn that covers the empirically
  relevant range of the paper's Eq. 2 nuclear-norm penalty.
  The extended grid yields 14 x 16 x 19 = 4,256 triplet combinations
  and includes the DID/TWFE corner (λ_nn = ∞, encoded as Stata missing).
------------------------------------------------------------------------------*/
real colvector trop_get_lambda_grid(string scalar grid_style, string scalar param_name)
{
    real colvector grid

    grid = J(0, 1, .)

    // λ_time and λ_unit grids span [0, ∞): λ = 0 recovers uniform weights;
    // λ = ∞ would collapse weight onto the target period/unit only (not a
    // supported configuration, see Eq. 3 of the paper).
    //
    // λ_nn = +∞ (Stata missing .) is the paper's DID/TWFE corner (L ≡ 0,
    // Eq. 2 remark).  It is exposed only through `grid_style(extended)`,
    // keeping the `default` preset to a five-point log-decade ladder for
    // λ_nn; callers wanting LOOCV to evaluate the DID/TWFE corner should
    // opt in via `extended` or a custom grid.  The `fine` style is exposed
    // only through the ADO layer (module-level preset); Mata retains
    // `default` and `extended` for legacy entry points.
    if (grid_style == "default") {
        if (param_name == "time") {
            grid = (0 \ 0.1 \ 0.5 \ 1 \ 2 \ 5)
        }
        else if (param_name == "unit") {
            grid = (0 \ 0.1 \ 0.5 \ 1 \ 2 \ 5)
        }
        else if (param_name == "nn") {
            grid = (0 \ 0.01 \ 0.1 \ 1 \ 10)
        }
        else {
            errprintf("trop_get_lambda_grid: invalid param_name '%s'\n", param_name)
            errprintf("  Must be 'time', 'unit', or 'nn'\n")
        }
    }
    else if (grid_style == "extended") {
        if (param_name == "time") {
            grid = (0 \ 0.1 \ 0.2 \ 0.25 \ 0.3 \ 0.35 \ 0.4 \ 0.5 \ 0.75 \ 1 \ 1.5 \ 2 \ 3 \ 5)
        }
        else if (param_name == "unit") {
            grid = (0 \ 0.1 \ 0.2 \ 0.25 \ 0.3 \ 0.35 \ 0.4 \ 0.5 \ 0.75 \ 1 \ 1.2 \ 1.5 \ 1.6 \ 2 \ 3 \ 5)
        }
        else if (param_name == "nn") {
            grid = (0 \ 0.005 \ 0.006 \ 0.01 \ 0.011 \ 0.02 \ 0.05 \ 0.1 \ 0.15 \ 0.151 \ 0.2 \ 0.3 \ 0.5 \ 0.7 \ 0.9 \ 1 \ 5 \ 10 \ .)
        }
        else {
            errprintf("trop_get_lambda_grid: invalid param_name '%s'\n", param_name)
            errprintf("  Must be 'time', 'unit', or 'nn'\n")
        }
    }
    else {
        errprintf("trop_get_lambda_grid: invalid grid_style '%s'\n", grid_style)
        errprintf("  Must be 'default' or 'extended'\n")
    }

    return(grid)
}

/*------------------------------------------------------------------------------
  trop_validate_grid()

  Checks whether a candidate grid vector satisfies the requirements for
  use in LOOCV grid search.

  Arguments:
    grid        - column vector of candidate values
    param_name  - parameter label (for diagnostic messages)

  Returns:
    1 if valid, 0 otherwise

  A valid grid is non-empty and contains only non-negative values.
  Missing values (.) are permitted and interpreted as infinity.
------------------------------------------------------------------------------*/
real scalar trop_validate_grid(real colvector grid, string scalar param_name)
{
    real scalar i, n, val

    n = rows(grid)
    if (n == 0) {
        errprintf("lambda_%s_grid cannot be empty\n", param_name)
        return(0)
    }

    for (i = 1; i <= n; i++) {
        val = grid[i]

        if (val == .) {
            continue
        }

        if (val < 0) {
            errprintf("lambda_%s_grid values must be non-negative\n", param_name)
            errprintf("  Found negative value %g at position %g\n", val, i)
            return(0)
        }
    }

    return(1)
}

/*------------------------------------------------------------------------------
  trop_grid_combination_count()

  Returns the total number of (lambda_time, lambda_unit, lambda_nn)
  triplet combinations given the sizes of the three marginal grids.

  Arguments:
    n_time  - number of lambda_time grid points
    n_unit  - number of lambda_unit grid points
    n_nn    - number of lambda_nn grid points

  Returns:
    n_time * n_unit * n_nn
------------------------------------------------------------------------------*/
real scalar trop_grid_combination_count(real scalar n_time, real scalar n_unit, real scalar n_nn)
{
    return(n_time * n_unit * n_nn)
}

/*------------------------------------------------------------------------------
  trop_get_grid_combination_count()

  Returns the total triplet combination count for a predefined grid style.

  Arguments:
    grid_style  - "default" or "extended"

  Returns:
    product of the three marginal grid sizes
------------------------------------------------------------------------------*/
real scalar trop_get_grid_combination_count(string scalar grid_style)
{
    real scalar n_time, n_unit, n_nn

    n_time = rows(trop_get_lambda_grid(grid_style, "time"))
    n_unit = rows(trop_get_lambda_grid(grid_style, "unit"))
    n_nn = rows(trop_get_lambda_grid(grid_style, "nn"))

    return(trop_grid_combination_count(n_time, n_unit, n_nn))
}

/*------------------------------------------------------------------------------
  trop_grid_to_numlist()

  Converts a grid column vector to a space-delimited numlist string
  suitable for Stata macro storage.

  Arguments:
    grid  - column vector of grid values

  Returns:
    string of space-separated numeric literals; missing values are
    represented as "."
------------------------------------------------------------------------------*/
string scalar trop_grid_to_numlist(real colvector grid)
{
    string scalar result
    real scalar i, n

    result = ""
    n = rows(grid)

    for (i = 1; i <= n; i++) {
        if (i > 1) {
            result = result + " "
        }
        if (grid[i] == .) {
            result = result + "."
        }
        else {
            result = result + strofreal(grid[i])
        }
    }

    return(result)
}

/*------------------------------------------------------------------------------
  trop_numlist_to_grid()

  Parses a space-delimited numlist string into a grid column vector.

  Arguments:
    numlist_str  - space-separated numeric string

  Returns:
    column vector of parsed values; "." tokens become Stata missing
------------------------------------------------------------------------------*/
real colvector trop_numlist_to_grid(string scalar numlist_str)
{
    string rowvector tokens
    real colvector grid
    real scalar i, n, val

    tokens = tokens(numlist_str)
    n = cols(tokens)

    if (n == 0) {
        return(J(0, 1, .))
    }

    grid = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        if (tokens[i] == ".") {
            grid[i] = .
        }
        else {
            val = strtoreal(tokens[i])
            grid[i] = val
        }
    }

    return(grid)
}

/*------------------------------------------------------------------------------
  trop_convert_infinity()

  Replaces infinity-coded values in a grid with finite substitutes
  appropriate for numerical computation.

  Arguments:
    grid        - column vector of grid values
    param_name  - "time", "unit", or "nn"

  Returns:
    column vector with infinity values replaced

  A value is treated as infinity when it is missing (.) or exceeds
  _TROP_LAMBDA_INF_THRESHOLD().

  Replacement semantics:
    lambda_time = infinity  =>  0   (uniform time weights)
    lambda_unit = infinity  =>  0   (uniform unit weights)
    lambda_nn   = infinity  =>  _TROP_LAMBDA_NN_INF_VALUE()
                                (suppresses the low-rank factor model)

  Setting lambda_nn = infinity recovers the DID/TWFE estimator when
  combined with uniform weights, or the SC/SDID estimator for specific
  weight choices.
------------------------------------------------------------------------------*/
real colvector trop_convert_infinity(real colvector grid, string scalar param_name)
{
    real colvector result
    real scalar i, n, val, inf_replacement

    n = rows(grid)
    result = J(n, 1, .)

    if (param_name == "nn") {
        inf_replacement = _TROP_LAMBDA_NN_INF_VALUE()
    }
    else {
        inf_replacement = 0
    }

    for (i = 1; i <= n; i++) {
        val = grid[i]

        if (val == . || val >= _TROP_LAMBDA_INF_THRESHOLD()) {
            result[i] = inf_replacement
        }
        else {
            result[i] = val
        }
    }

    return(result)
}

/*------------------------------------------------------------------------------
  trop_store_grid_matrix()

  Stores a grid vector as a Stata matrix named __trop_lambda_{param}_grid.
  The vector is transposed to a row vector for Stata matrix conventions.

  Arguments:
    grid        - column vector of grid values
    param_name  - "time", "unit", or "nn"
------------------------------------------------------------------------------*/
void trop_store_grid_matrix(real colvector grid, string scalar param_name)
{
    string scalar matname

    matname = "__trop_lambda_" + param_name + "_grid"
    st_matrix(matname, grid')
}

/*------------------------------------------------------------------------------
  trop_load_grid_matrix()

  Retrieves a grid vector from the Stata matrix __trop_lambda_{param}_grid.

  Arguments:
    param_name  - "time", "unit", or "nn"

  Returns:
    column vector of grid values, or an empty vector if the matrix
    does not exist
------------------------------------------------------------------------------*/
real colvector trop_load_grid_matrix(string scalar param_name)
{
    string scalar matname
    real matrix mat

    matname = "__trop_lambda_" + param_name + "_grid"
    mat = st_matrix(matname)

    if (rows(mat) == 0 && cols(mat) == 0) {
        return(J(0, 1, .))
    }

    return(mat')
}

/*------------------------------------------------------------------------------
  trop_validate_table2_coverage()

  Verifies that a grid style contains all cross-validated optimal values
  reported in the simulation study (Table 2).  The seven benchmark
  applications are: CPS log-wage, CPS unemployment rate, PWT log-GDP,
  Germany, Basque, Smoking, and Boatlift.

  Arguments:
    grid_style  - "default" or "extended"

  Returns:
    1 if every reported optimal value appears in the grid, 0 otherwise

  Optimal triplets (lambda_unit, lambda_time, lambda_nn):
    CPS log-wage  :  (0,    0.1,  0.9  )
    CPS urate     :  (1.6,  0.35, 0.011)
    PWT           :  (0.3,  0.4,  0.006)
    Germany       :  (1.2,  0.2,  0.011)
    Basque        :  (0,    0.35, 0.006)
    Smoking       :  (0.25, 0.4,  0.011)
    Boatlift      :  (0.2,  0.2,  0.151)
------------------------------------------------------------------------------*/
real scalar trop_validate_table2_coverage(string scalar grid_style)
{
    real colvector time_grid, unit_grid, nn_grid
    real rowvector table2_time, table2_unit, table2_nn
    real scalar i, found

    time_grid = trop_get_lambda_grid(grid_style, "time")
    unit_grid = trop_get_lambda_grid(grid_style, "unit")
    nn_grid = trop_get_lambda_grid(grid_style, "nn")

    table2_time = (0.1, 0.35, 0.4, 0.2, 0.35, 0.4, 0.2)
    table2_unit = (0, 1.6, 0.3, 1.2, 0, 0.25, 0.2)
    table2_nn = (0.9, 0.011, 0.006, 0.011, 0.006, 0.011, 0.151)

    for (i = 1; i <= cols(table2_time); i++) {
        found = sum(abs(time_grid :- table2_time[i]) :< 1e-10)
        if (found == 0) {
            errprintf("lambda_time value %g not covered by %s grid\n",
                      table2_time[i], grid_style)
            return(0)
        }
    }

    for (i = 1; i <= cols(table2_unit); i++) {
        found = sum(abs(unit_grid :- table2_unit[i]) :< 1e-10)
        if (found == 0) {
            errprintf("lambda_unit value %g not covered by %s grid\n",
                      table2_unit[i], grid_style)
            return(0)
        }
    }

    for (i = 1; i <= cols(table2_nn); i++) {
        found = sum(abs(nn_grid :- table2_nn[i]) :< 1e-10)
        if (found == 0) {
            errprintf("lambda_nn value %g not covered by %s grid\n",
                      table2_nn[i], grid_style)
            return(0)
        }
    }

    return(1)
}

/*------------------------------------------------------------------------------
  trop_report_table2_coverage()

  User-facing per-dataset coverage diagnostic for the seven Table 2
  benchmark applications.  Prints one row per dataset indicating whether
  each of (lambda_unit, lambda_time, lambda_nn) is present in the supplied
  grids, and returns the number of fully-covered datasets.

  Arguments:
    time_grid, unit_grid, nn_grid  - column vectors of the grid actually
                                     in use (typically from
                                     e(lambda_time_grid) etc.)

  Returns:
    Number of fully-covered datasets (0..7).  Seven means every
    Table 2 optimal triplet is enumerated by the current grid.
------------------------------------------------------------------------------*/
real scalar trop_report_table2_coverage(
    real colvector time_grid,
    real colvector unit_grid,
    real colvector nn_grid)
{
    string rowvector dataset_names
    real rowvector table2_time, table2_unit, table2_nn
    real scalar i, hit_t, hit_u, hit_n, all_hit, n_full
    string scalar mark_t, mark_u, mark_n

    dataset_names = ("CPS logwage",
                     "CPS urate",
                     "PWT",
                     "Germany",
                     "Basque",
                     "Smoking",
                     "Boatlift")
    table2_time = (0.1, 0.35, 0.4, 0.2, 0.35, 0.4, 0.2)
    table2_unit = (0,   1.6,  0.3, 1.2, 0,    0.25, 0.2)
    table2_nn   = (0.9, 0.011, 0.006, 0.011, 0.006, 0.011, 0.151)

    printf("\n{txt}Table 2 coverage report{col 36}{txt}grid contains optimum?\n")
    printf("{txt}{hline 12} {hline 14} {hline 13} {hline 11} {hline 10}\n")
    printf("{txt}%-12s {txt}%-14s {txt}%-13s {txt}%-11s {txt}%-10s\n",
           "Dataset", "lambda_unit", "lambda_time", "lambda_nn", "Status")
    printf("{txt}{hline 12} {hline 14} {hline 13} {hline 11} {hline 10}\n")

    n_full = 0
    for (i = 1; i <= cols(table2_time); i++) {
        hit_u = sum(abs(unit_grid :- table2_unit[i]) :< 1e-10) > 0
        hit_t = sum(abs(time_grid :- table2_time[i]) :< 1e-10) > 0
        hit_n = sum(abs(nn_grid   :- table2_nn[i]  ) :< 1e-10) > 0
        all_hit = hit_u & hit_t & hit_n
        if (all_hit) n_full = n_full + 1

        mark_u = hit_u ? "yes" : "no"
        mark_t = hit_t ? "yes" : "no"
        mark_n = hit_n ? "yes" : "no"

        printf("{txt}%-12s {res}%4.2f [%-3s]{txt} {res}%4.2f [%-3s]{txt} {res}%5.3f [%-3s]{txt} %s\n",
               dataset_names[i],
               table2_unit[i], mark_u,
               table2_time[i], mark_t,
               table2_nn[i],   mark_n,
               all_hit ? "{text:OK}" : "{err}partial{txt}")
    }
    printf("{txt}{hline 12} {hline 14} {hline 13} {hline 11} {hline 10}\n")
    printf("{txt}Fully covered: {res}%g{txt} of 7 benchmarks.\n", n_full)
    if (n_full < 7) {
        printf("{txt}Suggestion: use {cmd:grid_style(extended)} or add the missing\n")
        printf("{txt}values to {cmd:lambda_*_grid()} so every Table 2 optimum is\n")
        printf("{txt}reachable by the LOOCV search.\n")
    }
    return(n_full)
}

end
